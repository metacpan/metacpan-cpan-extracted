# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Parser;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Math::Logic::Ternary::Calculator::Command;
use Math::Logic::Ternary::Calculator::Version;

our $VERSION            = '0.004';
our $INTERACTIVE_PROMPT = q[.: ];

use constant _INPUT_FILENAME  => 0;
use constant _INPUT_HANDLE    => 1;
use constant _INPUT_OPENED    => 2;
use constant _PROMPT          => 3;
use constant _TERMINAL        => 4;
use constant _INITIAL_CMDS    => 5;

use constant CMD => Math::Logic::Ternary::Calculator::Command::;

sub _get_varname {
    my ($session, $raw_name) = @_;
    if ($raw_name =~ /^=?([^\W\d]\w*)\z/) {
        return "=$1";
    }
    my $msg = qq{"$raw_name" is not a variable name};
    CMD->wrong_usage($msg)->execute($session);
    return undef;
}

sub _strip_error {
    my ($error) = @_;
    $error =~ s/^(.*) at .* line \d+\.\n/$1/;
    return $error;
}

sub _get_value {
    my ($session, $raw_value) = @_;
    my $prefix = substr $raw_value, 0, 1;
    if ($prefix =~ /^[\%\@\$]/) {
        my $value = eval { $session->operand_from_string($raw_value) };
        return $value if defined $value;
    }
    elsif ($prefix =~ /^[\-\+\d]/) {
        my $value = eval { $session->operand_from_integer($raw_value) };
        return $value if defined $value;
    }
    elsif ('=' eq $prefix) {
        my $value = eval { $session->recall_value($raw_value) };
        return $value if defined $value;
    }
    elsif ($raw_value =~ /^#(-?\d+)\z/) {
        my $value = eval { $session->fetch_value($1) };
        return $value if defined $value;
    }
    elsif ($raw_value =~ /^\^+\z/) {
        my $value = eval { $session->fetch_value(-length $raw_value) };
        return $value if defined $value;
    }
    else {
        CMD->wrong_usage(qq{"$raw_value": not an operand})->execute($session);
        return undef;
    }
    my $error = _strip_error($@);
    CMD->bad_value(qq{"$raw_value": $error})->execute($session);
    return undef;
}

# will be used as quasi-initial command
sub _readline_status {
    my ($session, $parser) = @_;
    if (defined $parser->_terminal) {
        print "readline support is enabled\n";
    }
    return 1;
}

# check variable name and value, do the storage operation
CMD->def_tool_command('/def', 2, 0, \&_store_this, <<'EOT');
/def variable value
store a value under a name
EOT
sub _store_this {
    my ($session, $raw_name, $raw_value) = @_;
    my $name = _get_varname($session, $raw_name);
    my $value = _get_value($session, $raw_value);
    if (defined $name and defined $value) {
        $session->storage_store($name, $value);
    }
    return 1;
}

sub _execute_operator {
    my ($session, $name, @raw_operands) = @_;
    my $errors = 0;
    my @operands = map {
        my $value = _get_value($session, $_);
        defined($value)? $value: ++$errors
    } @raw_operands;
    if (!$errors) {
        $session->execute_operator($name, @operands);
    }
    return 1;
}

sub _append_values {
    my ($session, @raw_operands) = @_;
    my $errors = 0;
    my @operands = map {
        my $value = _get_value($session, $_);
        defined($value)? $value: ++$errors
    } @raw_operands;
    if (!$errors) {
        $session->storage_append(@operands);
    }
    return 1;
}

sub _operator {
    my ($this, $name, @operands) = @_;
    if ($name !~ /^[^\W\d]\w*\z/) {
        return CMD->wrong_usage(qq{"$name" is not a valid operator name});
    }
    return CMD->custom_command(\&_execute_operator, $name, @operands);
}

sub _values {
    my ($this, @operands) = @_;
    return CMD->custom_command(\&_append_values, @operands);
}

sub _read_line {
    my ($this) = @_;
    my $terminal = $this->_terminal;
    if (defined $terminal) {
        return $terminal->readline($this->prompt);
    }
    $this->do_prompt;
    my $handle = $this->_input_handle;
    return scalar <$handle>;
}

sub _read_items {
    my ($this) = @_;
    my @items = ();
    while (!@items) {
        my $line = $this->_read_line;
        if (!defined $line) {
            $this->do_unprompt;
            return ();
        }
        @items = split q[ ], $line;
    }
    return @items;
}

sub input_filename   {         $_[0]->[_INPUT_FILENAME]  }
sub _input_handle    {         $_[0]->[_INPUT_HANDLE  ]  }
sub _input_opened    {         $_[0]->[_INPUT_OPENED  ]  }
sub prompt           {         $_[0]->[_PROMPT        ]  }
sub _terminal        {         $_[0]->[_TERMINAL      ]  }
sub _pending_initial { shift @{$_[0]->[_INITIAL_CMDS  ]} }

sub do_prompt {
    my ($this) = @_;
    my $prompt = $this->prompt;
    print $prompt if q[] ne $prompt;
    return;
}

sub do_unprompt {
    my ($this) = @_;
    my $prompt = $this->prompt;
    print "\n" if q[] ne $prompt;
    return;
}

sub _drop_input {
    undef $_[0]->[_INPUT_HANDLE];
    undef $_[0]->[_INPUT_OPENED];
}

sub open {
    my ($class, $in_filename, $prompt, $enable_readline) = @_;
    my $this = bless [], $class;
    my $in_handle = undef;
    my $terminal  = undef;
    my $from_file = '-' ne $in_filename;
    if ($from_file) {
        open $in_handle, '<', $in_filename
            or croak "$in_filename: cannot open: $!";
        $enable_readline = 0;
    }
    else {
        $in_handle = \*STDIN;
    }
    if (!defined $prompt) {
        $prompt = -t $in_handle? $INTERACTIVE_PROMPT: q[];
    }
    if (!defined $enable_readline) {
        $enable_readline = -t $in_handle;
    }
    if ($enable_readline) {
        my $app_name   = Math::Logic::Ternary::Calculator::Version->long_name;
        my $out_handle = \*STDOUT;
        $terminal = eval {
            require Term::ReadLine;
            Term::ReadLine->new($app_name, $in_handle, $out_handle)
        };
    }
    $this->[_INPUT_FILENAME] = $in_filename;
    $this->[_INPUT_OPENED  ] = $from_file;
    $this->[_INPUT_HANDLE  ] = $in_handle;
    $this->[_PROMPT        ] = $prompt;
    $this->[_TERMINAL      ] = $terminal;
    $this->[_INITIAL_CMDS  ] = [
        CMD->get_initial_commands,
        CMD->custom_command(\&_readline_status, $this),
    ];
    return $this;
}

sub close {
    my ($this) = @_;
    if ($this->_input_opened && !close $this->_input_handle) {
        my $filename = $this->input_filename;
        croak "$filename: cannot close: $!";
    }
    $this->_drop_input;
    return $this;
}

sub read_command {
    my ($this) = @_;
    if (my $initial_cmd = $this->_pending_initial) {
        return $initial_cmd;
    }
    my @items = $this->_read_items;
    return undef if !@items;
    my $prefix = substr $items[0], 0, 1;
    if ($prefix =~ m{^[/?]}) {
        my $name = shift @items;
        return CMD->tool_command($name, @items);
    }
    if ($prefix =~ m{^[^\W\d]}) {
        return $this->_operator(@items);
    }
    return $this->_values(@items);
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::Parser - ternary calculator command parser

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Parser.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::Parser;
  use Math::Logic::Ternary::Calculator::Session;

  $session = Math::Logic::Ternary::Calculator::Session->new(...);
  $parser  = Math::Logic::Ternary::Calculator::Parser->open('-');
  while ($command = $parser->read_command) {
      last if !$command->execute($session);
  }
  $parser->close;

=head1 DESCRIPTION

TODO

=head2 Exports

None.

=head1 BUGS AND LIMITATIONS

M::L::T::C::Session, M::L::T::C::Parser, and M::L::T::C::Command should
perhaps be refactored into more independent components.  We might have
to reorder the import hierarchy when we do this.

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
