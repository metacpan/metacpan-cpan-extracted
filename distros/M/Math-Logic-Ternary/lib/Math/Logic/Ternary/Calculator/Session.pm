# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Session;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Math::Logic::Ternary::Calculator::Parser;
use Math::Logic::Ternary::Calculator::Command;
use Math::Logic::Ternary::Calculator::State;
use Math::Logic::Ternary::Calculator::Mode;
use Math::Logic::Ternary::Calculator::Operator;

our $VERSION = '0.004';

use constant _STATE   => 0;
use constant PARSER   => Math::Logic::Ternary::Calculator::Parser::;
use constant CMD      => Math::Logic::Ternary::Calculator::Command::;
use constant MODE     => Math::Logic::Ternary::Calculator::Mode::;
use constant OPERATOR => Math::Logic::Ternary::Calculator::Operator::;

use constant MAX_COLUMNS => 70;

sub new {
    my ($class, $state) = @_;
    return bless [$state], $class;
}

sub state     { $_[0]->[_STATE] }
sub word_size { $_[0]->[_STATE]->word_size }

sub fetch_value {
    my ($this, $index) = @_;
    my $state = $this->state;
    my $value = $state->fetch($index);
    return $value if defined $value;
    my $min = $state->min_index;
    my $max = $state->max_index;
    croak "no numbered values stored so far" if $max < $min;
    croak "index $index out of range $min..$max";
}

sub recall_value {
    my ($this, $name) = @_;
    my $state = $this->state;
    my $value = $state->recall($name);
    return $value if defined $value;
    croak "variable $name not yet defined";
}

sub _display_this {
    my ($state, $name, $value) = @_;
    my $str = $state->format_value($name, $value);
    print $str, "\n";
    return 1;
}

sub storage_append {
    my ($this, @values) = @_;
    my $state = $this->state;
    foreach my $value (@values) {
        my ($new_i) = $state->append($value);
        _display_this($state, "#$new_i", $value);
    }
    return 1;
}

sub storage_store {
    my ($this, $name, $value) = @_;
    my $state = $this->state;
    $state->store($name, $value);
    return _display_this($state, $name, $value);
}

CMD->def_tool_command('?#', 0, 0, \&list_numbered_cmd, <<'EOT');
?#
list numbered values of this session
EOT
sub list_numbered_cmd {
    my ($this) = @_;
    my $state = $this->state;
    my $max = $state->max_index;
    if ($max < 0) {
        print "no numbered values stored so far\n";
    }
    else {
        foreach my $index (0 .. $max) {
            my $value = $state->fetch($index);
            _display_this($state, "#$index", $value);
        }
    }
    return 1;
}

CMD->def_tool_command('?=', 0, 0, \&list_named_cmd, <<'EOT');
?=
list variables of this session
EOT
sub list_named_cmd {
    my ($this) = @_;
    my $state = $this->state;
    my @names = $state->all_names;
    if (!@names) {
        print "no variables defined so far\n";
    }
    else {
        foreach my $name (@names) {
            my $value = $state->recall($name);
            _display_this($state, $name, $value);
        }
    }
    return 1;
}

CMD->def_initial_command(10,         \&size_cmd);
CMD->def_tool_command('/size', 0, 0, \&size_cmd, <<'EOT');
/size
display word size of this session
EOT
sub size_cmd {
    my ($this) = @_;
    my $state = $this->state;
    my $size  = $state->word_size;
    print "word size is $size trits\n";
    return 1;
}

CMD->def_initial_command(20,         \&mode_cmd, undef);
CMD->def_tool_command('/mode', 0, 1, \&mode_cmd, <<'EOT');
/mode [new_mode]
show current arithmetic mode or set new arithmetic mode
EOT
sub mode_cmd {
    my ($this, @modes) = @_;
    my $state = $this->state;
    my $help  = !@modes;
    foreach my $new_mode (@modes) {
        next if !defined $new_mode;
        my $mode = MODE->from_string($new_mode);
        if (defined $mode) {
            $state->set_mode($mode);
        }
        else {
            ++$help;
        }
    }
    print "arithmetic mode is ", $state->mode->name, "\n";
    if ($help) {
        my @all_modes = MODE->modes;
        my $i = 0;
        print
            q{valid modes are },
            join(q[, ], map { $i++ . q[ = ] . $_->name } @all_modes), "\n";
    }
    return 1;
}

CMD->def_tool_command('/range', 0, 0, \&range_cmd, <<'EOT');
/range
return two words: smallest and largest possible integer
(dependent on word size and current arithmetic mode)
EOT
sub range_cmd {
    my ($this) = @_;
    my $state = $this->state;
    foreach my $value ($state->range) {
        my ($new_i) = $state->append($value);
        _display_this($state, "#$new_i", $value);
    }
    return 1;
}

CMD->def_tool_command('/rand', 0, 0, \&rand_cmd, <<'EOT');
/rand
return a word with random trits
EOT
sub rand_cmd {
    my ($this) = @_;
    my $state = $this->state;
    my $value = $state->rand;
    my ($new_i) = $state->append($value);
    _display_this($state, "#$new_i", $value);
    return 1;
}

CMD->def_tool_command('/abc', 0, 1, \&abc_cmd, <<'EOT');
/abc [n]
return n (default 3) words covering all different trit combinations
(trits ordered according to current arithmetic mode)
EOT
sub abc_cmd {
    my ($this, $dim) = @_;
    $dim = 3 if !defined $dim;
    my $state = $this->state;
    my $max_abc = $state->max_abc;
    if ($dim !~ /^\d+\z/ || 0 == $dim || $max_abc < $dim) {
        print "usage: /abc [n] (where n is in 1 .. $max_abc)\n";
        return 1;
    }
    my @abc = $state->abc($dim);
    foreach my $value (@abc) {
        my ($new_i) = $state->append($value);
        _display_this($state, "#$new_i", $value);
    }
    return 1;
}

CMD->def_tool_command('/reset', 0, 1, \&reset_cmd, <<'EOT');
/reset [1|2]
discard all stored values, or all numbered values (1) or all variables (2)
EOT
sub reset_cmd {
    my ($this, $what) = @_;
    my $state = $this->state;
    my $count = join '+', eval { $state->reset($what) };
    if (q[] eq $count) {
        print "bad argument: 1 or 2 expected\n";
    }
    else {
        print "discarded $count value(s)\n";
    }
    return 1;
}

sub _headline {
    my ($title) = @_;
    my $len = 2 + length $title;
    return "$title\n" if $len > MAX_COLUMNS;
    my $lpad = q[-] x ((MAX_COLUMNS     - $len) >> 1);
    my $rpad = q[-] x ((MAX_COLUMNS + 1 - $len) >> 1);
    return "$lpad $title $rpad\n";
}

sub _with_line_breaks {
    my @words = @_;
    my $str = q[];
    my $cols = 0;
    foreach my $word (@words) {
        my $len  = length $word;
        if ($cols && $cols + $len >= MAX_COLUMNS) {
            $str .= "\n";
            $cols = 0;
        }
        if ($cols) {
            $str .= q[ ];
            ++$cols;
        }
        $str .= $word;
        $cols += $len;
    }
    if ($cols) {
        $str .= "\n";
    }
    return $str;
}

CMD->def_tool_command('/ops', 0, -1, \&list_operators_cmd, <<'EOT');
/ops [n]...
list all operators, or operators of kind n (n = 0, 1, 2, 3...)
EOT
sub list_operators_cmd {
    my ($this, @kinds) = @_;
    my $mode = $this->state->mode;
    my @op_kinds = OPERATOR->operator_kinds;
    if (grep { !/^\d+\z/ || $_ >= @op_kinds } @kinds) {
        print "usage: /ops [n]... (where n is in 0..$#op_kinds)\n";
        return 1;
    }
    if (!@kinds) {
        @kinds = 0 .. $#op_kinds;
    }
    my $spacer = q[];
    foreach my $kind (@kinds) {
        print
            $spacer,
            _headline($op_kinds[$kind]),
            _with_line_breaks(OPERATOR->operator_list($mode, $kind));
        $spacer = "\n";
    }
    return 1;
}

sub operand_from_integer {
    my ($this, $int) = @_;
    return $this->state->convert_int($int);
}

sub operand_from_string {
    my ($this, $string) = @_;
    return $this->state->convert_string($string);
}

sub execute_operator {
    my ($this, $raw_name, @operands) = @_;
    my $state = $this->state;
    my $op    = OPERATOR->find($raw_name, $state->mode);
    if (!ref $op) {
        return CMD->unknown_operator($raw_name, $op)->execute($this);
    }
    my ($minc, $varc, $retv) = $op->signature;
    if (my $error = CMD->check_argc($raw_name, $minc, $varc, 0+@operands)) {
        return CMD->wrong_usage($error)->execute($this);
    }
    my (@results) = $op->execute($state->normalize_operands(@operands));
    if (!@results) {
        print "operation produced no output\n";
        return 1;
    }
    if ($retv) {
        return $this->storage_append(@results);
    }
    foreach my $value (@results) {
        print $value, "\n";
    }
    return 1;
}

sub run {
    my ($this, $input) = (@_, '-');
    $| = 1;                     # turn on auto-flush mode for STDOUT
    my $parser = PARSER->open($input);
    while (my $command = $parser->read_command) {
        last if !$command->execute($this);
    }
    $parser->close;
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::Session - ternary calculator session driver

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Session.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::State;
  use Math::Logic::Ternary::Calculator::Session;

  $size    = 27;
  $mode    = 0;
  $file    = '-';
  $state   = Math::Logic::Ternary::Calculator::State->new($size, $mode);
  $session = Math::Logic::Ternary::Calculator::Session->new($state);
  $session->run($file);

=head1 DESCRIPTION

TODO

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary::Calculator>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
