# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::State;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Math::Logic::Ternary::Calculator::Mode;
use Math::Logic::Ternary::Word;
use Math::Logic::Ternary qw(nil true false);

use constant MODE => Math::Logic::Ternary::Calculator::Mode::;

our $VERSION       = '0.004';
our $DEFAULT_MODE  = MODE->balanced;
our $MAX_WORD_SIZE = (Math::Logic::Ternary::Word::MAX_SIZE - 1) >> 1;

use constant _WORD_SIZE => 0;
use constant _MODE      => 1;
use constant _ZERO      => 2;
use constant _BY_INDEX  => 3;
use constant _BY_NAME   => 4;
use constant _FORMAT    => 5;
use constant _MAX_ABC   => 6;

sub _check_size {
    my ($size) = @_;
    if (!defined $size) {
        croak "size parameter expected";
    }
    if ($size < 1 || $MAX_WORD_SIZE < $size) {
        croak "illegal size, choose from 1..$MAX_WORD_SIZE";
    }
}

sub _check_mode {
    my ($mode) = @_;
    if (!defined $mode) {
        return $DEFAULT_MODE;
    }
    if (eval { $mode->isa(MODE) }) {
        return $mode;
    }
    my @all_modes = MODE->modes;
    if (0 <= $mode && $mode < @all_modes) {
        return $all_modes[$mode];
    }
    croak "illegal mode, choose from 0..$#all_modes";
}

sub _as_base27 {
    my ($obj) = @_;
    return $obj->can('as_base27')? $obj->as_base27: $obj->as_string;
}

sub _make_format {
    my ($size) = @_;
    my $b27len = int( ($size + 5) / 3 );
    if ($size > 81) {
        return sub {
            my ($this, $name, $obj) = @_;
            my $bval = _as_base27($obj);
            my $npad = q[ ] x (      9 - length $name);
            my $bpad = q[ ] x ($b27len - length $bval);
            return "$name$npad $bpad$bval";
        };
    }
    my $declen = int( log(3) * $size / log(10) + 2 );
    if ($size > 36) {
        return sub {
            my ($this, $name, $obj) = @_;
            my $as_int = $this->mode->apply('as_int');
            my $bval = _as_base27($obj);
            my $int  = $obj->$as_int;
            my $sign = $int < 0? q[]: q[+];
            my $dval = $sign . $int;
            my $npad = q[ ] x (      9 - length $name);
            my $bpad = q[ ] x ($b27len - length $bval);
            my $dpad = q[ ] x ($declen - length $dval);
            return "$name$npad $bpad$bval $dpad$dval";
        };
    }
    my $strlen = $size + 1;
    if ($strlen < 6) {
        $strlen = 6;
    }
    if ($b27len < 6) {
        $b27len = 6;
    }
    if ($declen < 6) {
        $declen = 6;
    }
    return sub {
        my ($this, $name, $obj) = @_;
        my $as_int = $this->mode->apply('as_int');
        my $bval = _as_base27($obj);
        my $int  = $obj->$as_int;
        my $sign = $int < 0? q[]: q[+];
        my $dval = $sign . $int;
        my $sval = $obj->as_string;
        my $npad = q[ ] x (      9 - length $name);
        my $bpad = q[ ] x ($b27len - length $bval);
        my $dpad = q[ ] x ($declen - length $dval);
        my $spad = q[ ] x ($strlen - length $sval);
        return "$name$npad $bpad$bval $spad$sval $dpad$dval";
    };
}

sub _max_abc {
    my ($size) = @_;
    my $result = 0;
    my $npower = 3;
    while ($npower <= $size) {
        ++$result;
        $npower *= 3;
    }
    return $result;
}

sub new {
    my ($class, $size, $mode) = @_;
    _check_size($size);
    $mode = _check_mode($mode);
    my $format = _make_format($size);
    my $zero   = Math::Logic::Ternary::Word->from_trits($size);
    my $max_abc = _max_abc($size);
    return bless [$size, $mode, $zero, [], {}, $format, $max_abc], $class;
}

sub word_size    {             $_[0]->[_WORD_SIZE]                  }
sub mode         {             $_[0]->[_MODE     ]                  }
sub zero         {             $_[0]->[_ZERO     ]                  }
sub fetch        {             $_[0]->[_BY_INDEX ]->[$_[1]]         }
sub recall       {             $_[0]->[_BY_NAME  ]->{$_[1]}         }
sub min_index    {          -@{$_[0]->[_BY_INDEX ]}                 }
sub max_index    {          $#{$_[0]->[_BY_INDEX ]}                 }
sub all_names    { sort keys %{$_[0]->[_BY_NAME  ]}                 }
sub store        {             $_[0]->[_BY_NAME  ]->{$_[1]} = $_[2] }
sub format_value {             $_[0]->[_FORMAT   ]->(@_)            }
sub max_abc      {             $_[0]->[_MAX_ABC  ]                  }

sub set_mode {
    my ($this, $mode) = @_;
    eval { $mode->isa('Math::Logic::Ternary::Calculator::Mode') }
        or croak "ternary calculator mode object expected";
    $this->[_MODE] = $mode;
}

# @indexes = $state->append(@values);
sub append {
    my $this = shift;
    my $by_i = $this->[_BY_INDEX];
    my $i = @{$by_i};
    push @{$by_i}, @_;
    return map { $i++ } @_;
}

# $value  = $state->convert_int($int);
sub convert_int {
    my ($this, $int) = @_;
    my $from_int = $this->mode->apply('from_int');
    return Math::Logic::Ternary::Word->$from_int($this->word_size, $int);
}

sub convert_string {
    my ($this, $str) = @_;
    return Math::Logic::Ternary::Word->from_string($this->word_size, $str);
}

sub normalize_operands {
    my ($this, @operands) = @_;
    my $zero = $this->zero;
    return @operands? (map { $zero->convert_words($_) } @operands): $zero;
}

sub range {
    my ($this) = @_;
    my $mode = $this->mode;
    my $size = $this->word_size;
    my $min_int = $mode->apply('min_int');
    my $max_int = $mode->apply('max_int');
    my $zero = Math::Logic::Ternary::Word->from_trits($size);
    return ($zero->$min_int, $zero->$max_int);
}

sub rand {
    my ($this) = @_;
    my $size = $this->word_size;
    my @trits = (nil, true, false);
    return
        Math::Logic::Ternary::Word->from_trits($size,
            @trits[map {rand 3} 1 .. $size]
        );
}

sub abc {
    my ($this, $dim) = @_;
    my $mode  = $this->mode;
    my @trits = $mode->is_balanced? (true, nil, false): (false, true, nil);
    my @abc   = ([@trits]);
    my $size  = 3;
    while (@abc < $dim) {
        foreach my $vec (@abc) {
            push @{$vec}, @{$vec}, @{$vec};
        }
        unshift @abc, [map {($_) x $size} @trits];
        $size *= 3;
    }
    return
        map { Math::Logic::Ternary::Word->from_trits($size, @{$_}) } @abc;
}

sub reset {
    my ($this, $what) = @_;
    my @discarded = ();
    if (!$what || 1 == $what) {
        push @discarded, 0 + @{$this->[_BY_INDEX]};
        @{$this->[_BY_INDEX]} = ();
    }
    if (!$what || 2 == $what) {
        push @discarded, 0 + keys %{$this->[_BY_NAME]};
        %{$this->[_BY_NAME]} = ();
    }
    return @discarded;
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::State - memory of the ternary calculator

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::State.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::State;
  use Math::Logic::Ternary::Calculator::Mode;

  $state = Math::Logic::Ternary::Calculator::State->new($word_size);
  $state = Math::Logic::Ternary::Calculator::State->new($word_size, $mode);

  $word_size = $state->word_size;
  $mode      = $state->mode;            # balanced / unbalanced / base(-3)

  $state->set_mode($mode);

  @indexes = $state->append(@values);
  $value   = $state->fetch($index);

  $state->store($name, $value);
  $value = $state->recall($name);

  $string = $state->format_value($name, $value);
  $value  = $state->convert_int($int);

  @words  = $state->normalize_operands(@words);

  ($min, $max) = $state->range;

  $state->reset($what);               # all / numbered / named

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
