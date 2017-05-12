use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics;
use Data::Float qw/have_signed_zero have_infinite have_nan/;
use Math::BigFloat;
use Scalar::Util qw/blessed/;
use Scalar::Util::Numeric qw/isinf isnan/;

our $POS_ZERO = have_signed_zero() ? Data::Float::pos_zero()     : 0;
our $NEG_ZERO = have_signed_zero() ? Data::Float::neg_zero()     : 0;
our $POS_INF  = have_infinite()    ? Data::Float::pos_infinity() : Math::BigFloat->binf();
our $NEG_INF  = have_infinite()    ? Data::Float::neg_infinity() : Math::BigFloat->binf('-');
our $POS_ONE  = +1;
our $NEG_ONE  = -1;
our $NAN      = have_nan()         ? Data::Float::nan()          : Math::BigFloat->bnan();
our $UNDEF    = undef;

# ABSTRACT: ECMAScript 262, Edition 5, lexical string numeric grammar default semantics package, using native perl representations

our $VERSION = '0.020'; # VERSION



sub new {
  my ($class, %opts) = @_;
  my $self = {_number => $opts{number}    // 0,
              _length => $opts{length}    // 0,
              _decimal => $opts{decimal } // 0};
  bless($self, $class);
  return $self;
}


sub clone_init {
  my ($self) = @_;
  return (ref $self)->new();
}


sub clone {
  my ($self) = @_;
  return (ref $self)->new(number => $self->{_number}, length => $self->{_length}, decimal => $self->{_decimal});
}


sub decimalOn {
    $_[0]->{_decimal} = 1;
    return $_[0];
}


sub mul {
    $_[0]->{_number} *= $_[1]->{_number};
    return $_[0];
}


sub div {
    $_[0]->{_number} /= $_[1]->{_number};
    return $_[0];
}


sub mod {
    $_[0]->{_number} %= $_[1]->{_number};
    return $_[0];
}


sub nan {
    $_[0]->{_number} = $NAN;
    return $_[0];
}


sub pos_one {
    $_[0]->{_number} = $POS_ONE;
    return $_[0];
}


sub neg_one {
    $_[0]->{_number} = $NEG_ONE;
    return $_[0];
}


sub pos_zero {
    $_[0]->{_number} = $POS_ZERO;
    return $_[0];
}


sub neg_zero {
    $_[0]->{_number} = $NEG_ZERO;
    return $_[0];
}


sub pos_inf {
    $_[0]->{_number} = $POS_INF;
    return $_[0];
}


sub neg_inf {
    $_[0]->{_number} = $NEG_INF;
    return $_[0];
}


sub pow {
    $_[0]->{_number} **= $_[1]->{_number};
    return $_[0];
}


sub and {
    $_[0]->{_number} &= $_[1]->{_number};
    return $_[0];
}


sub or {
    $_[0]->{_number} |= $_[1]->{_number};
    return $_[0];
}


sub xor {
    $_[0]->{_number} ^= $_[1]->{_number};
    return $_[0];
}


sub not {
    $_[0]->{_number} = ~$_[0]->{_number};
    return $_[0];
}


sub sqrt {
    my $x = eval {sqrt($_[0]->{_number})};
    if ($@) {
      return $_[0]->nan();
    }
    return $_[0];
}


sub left_shift {
    $_[0]->{_number} <<= $_[1]->{_number};
    return $_[0];
}


sub right_shift {
    $_[0]->{_number} >>= $_[1]->{_number};
    return $_[0];
}


sub inc {
    $_[0]->{_number} += 1;
    return $_[0];
}


sub dec {
    $_[0]->{_number} -= 1;
    return $_[0];
}


sub int {
    $_[0]->{_number} = CORE::int("$_[1]");
    $_[0]->{_length} = length("$_[1]");
    return $_[0];
}


sub hex {
    $_[0]->{_number} = CORE::hex("$_[1]");
    return $_[0];
}


sub neg {
    $_[0]->{_number} *= -1;
    return $_[0];
}


sub abs {
    $_[0]->{_number} = CORE::abs($_[0]->{_number});
    return $_[0];
}


sub new_from_sign {
  if ($_[0]->is_nan) {
    return $_[0]->clone_init->nan;
  }
  elsif ($_[0]->is_pos) {
    return $_[0]->clone_init->pos_one;
  }
  else {
    return $_[0]->clone_init->neg_one;
  }
}


sub new_from_cmp {
  if ($_[0]->is_nan || $_[1]->is_nan) {
    return $_[0]->clone_init->nan;
  }
  else {
    my $tmp = $_[0]->clone->sub($_[1]);
    if ($tmp->is_zero) {
      return $_[0]->clone_init->pos_zero;
    }
    elsif ($tmp->is_neg) {
      return $_[0]->clone_init->neg_one;
    }
    else {
      return $_[0]->clone_init->pos_one;
    }
  }
}


sub add {
    $_[0]->{_number} += $_[1]->{_number};
    return $_[0];
}


sub sub {
    $_[0]->{_number} -= $_[1]->{_number};
    return $_[0];
}


sub inc_length {
    ++$_[0]->{_length};
    return $_[0];
}


sub new_from_length {
    return $_[0]->clone_init->int("$_[0]->{_length}");
}


sub sign {
  if ($_[0]->is_zero) {
    return 0;
  }
  elsif ($_[0]->is_pos) {
    return 1;
  }
  elsif ($_[0]->is_neg) {
    return -1;
  }
  else {
    return undef;
  }
}


sub cmp {
    return $_[0]->new_from_cmp($_[1])->sign;
}


sub host_number {
  return $_[0]->{_number};
}


sub host_value {
  #
  # This is native implementation, i.e. we assume that the Math and/or CPUs under the hood
  # are already IEEE-754 compliant, including rounding.
  #
  # This mean that we return internal number as is.
  #
  return $_[0]->{_number};
}


sub is_zero {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
	#
	# float_is_zero never fails
	#
	return Data::Float::float_is_zero($_[0]->{_number});
    } elsif ($_[0]->{_number}->can('is_zero')) {
	return $_[0]->{_number}->is_zero();
    } else {
	return $UNDEF;
    }
}


sub is_pos_one {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
	return ($_[0]->{_number} == $POS_ONE) ? 1 : 0;
    } elsif ($_[0]->{_number}->can('is_one')) {
	return $_[0]->{_number}->is_one();
    } else {
	return $UNDEF;
    }
}


sub is_neg_one {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
	return ($_[0]->{_number} == $NEG_ONE) ? 1 : 0;
    } elsif ($_[0]->{_number}->can('is_one')) {
	return $_[0]->{_number}->is_one('-');
    } else {
	return $UNDEF;
    }
}


sub is_pos {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
      if ($_[0]->is_nan) {
        return 0;
      } else {
        return (Data::Float::signbit($_[0]->{_number}) == 0) ? 1 : 0;
      }
    } elsif ($_[0]->{_number}->can('is_pos')) {
	return $_[0]->{_number}->is_pos();
    } else {
	return $UNDEF;
    }
}


sub is_neg {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
      if ($_[0]->is_nan) {
        return 0;
      } else {
        return (Data::Float::signbit($_[0]->{_number}) == 0) ? 0 : 1;
      }
    } elsif ($_[0]->{_number}->can('is_neg')) {
	return $_[0]->{_number}->is_neg();
    } else {
	return $UNDEF;
    }
}


sub is_inf {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
	#
	# isinf() never fails
	#
	return isinf($_[0]->{_number});
    } elsif ($_[0]->{_number}->can('is_inf')) {
	return $_[0]->{_number}->is_inf();
    } else {
	return $UNDEF;
    }
}


sub is_nan {
    my $blessed = blessed($_[0]->{_number}) || '';
    if (! $blessed) {
	#
	# isnan() never fails
	#
	return isnan($_[0]->{_number});
    } elsif ($_[0]->{_number}->can('is_nan')) {
	return $_[0]->{_number}->is_nan();
    } else {
	return $UNDEF;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics - ECMAScript 262, Edition 5, lexical string numeric grammar default semantics package, using native perl representations

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules provide a default semantics package for the actions associated to ECMAScript_262_5 lexical string numeric grammar, using native number representation, with the possible exceptions of positive zero and positive infinity: if one of them is not available natively, then the Math::BigFloat representation is used.

This module exports more methods, intended to provide a complete set of functions necessary for ECMAScript runtime.

The new() method returns an object hiding number implementation.

All method names starting with host_ return a value understandable only by the host.

All method names starting with is_ return a value understandable by perl, as well as the sign() and cmp() methods.

For every method, this module says if it should be overwriten in case of an alternate implementation. If there is no such mention this mean that the method in the package is only calling other methods. Therefore it is safe to use this module as a parent, provided that all methods marked as "should be overwriten", are as such.

=head2 new($class, %opts)

Instantiate a new object that has three members:

=over

=item number

Initialized to $opts{number} or host's positive zero

=item length

Initialized to $opts{length} or host's positive zero

=item decimal

Initialized to a $opts{decimal} or a host's false value

=back

These three members are independant values. "length" is used when evaluating a number with a dot character '.'. "decimal" is a flag setted by the grammar when the Mathematical value is done on a decimal literal. Unless stated, all methods are manipulating only the "number" component.

Should be overwriten in case of alternate implementation.

=head2 clone_init($self)

New instance that is a initialized clone of $self, like new() with no option.

=head2 clone($self)

Cloning of $self (i.e. copy of all $self's members). Returns a new instance.

Should be overwriten in case of alternate implementation, if internal member are not named _number, _length and _decimal and if simple assignment is not enough.

=head2 decimalOn($self)

Host implementation of $self's decimal setted to a true value. Returns $self.

Should be overwriten in case of alternate implementation, if internal member is not _decimal.

=head2 mul($self, $objmul)

Host implementation of $self's number multiplied by $objmul's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 div($self, $objdiv)

Host implementation of $self's number divided by $objdiv's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 mod($self, $objmod)

Host implementation of $self's number modulus $objmod's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 nan($self)

Host implementation of $self's number setted to nan, defaulting to Data::Float::nan if your host have it, Math::BigFloat's implementation otherwise. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 pos_one($self)

Host implementation of $self's number setted to positive one, defaulting to +1. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 neg_one($self)

Host implementation of $self's number setted to negative one, defaulting to -1. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 pos_zero($self)

Host implementation of $self's number setted to positive zero, defaulting to Data::Float::pos_zero if your host have signed zeroes, 0 otherwise. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 neg_zero($self)

Host implementation of $self's number setted to negative zero, defaulting to Data::Float::neg_zero if your host have signed zeroes, 0 otherwise. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 pos_inf($self)

Host implementation of $self's number setted to positive infinity, defaulting to Data::Float::pos_infinity if your host have infinity, Math::BigFloat->binf() otherwise. Return $self.

Should be overwriten in case of alternate implementation.

=head2 neg_inf($self)

Host implementation of $self's number setted to negative infinity, defaulting to Data::Float::neg_infinity if your host have infinity, Math::BigFloat->binf('-') otherwise. Return $self.

Should be overwriten in case of alternate implementation.

=head2 pow($self, $powobj)

Host implementation of $self's number powered by $powobj's number (i.e. $self ** $powobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 and($self, $andobj)

Host implementation of $self's number bit-wise and with $andobj's number (i.e. $self & $andobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 or($self, $orobj)

Host implementation of $self's number bit-wise inclusive or with $orobj's number (i.e. $self | $powobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 xor($self, $xorobj)

Host implementation of $self's number bit-wise exclusive or with $xorobj's number (i.e. $self ^ $xorobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 not($self)

Host implementation of $self's number bit-wise not (i.e. ~$self). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 sqrt($self)

Host implementation of $self's number square root. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 left_shift($self, $shiftobj)

Host implementation of $self's number left-shifted by $shiftobj's number in base 2 (i.e. $self <<= $shiftobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 right_shift($self, $shiftobj)

Host implementation of $self's number right-shifted by $shiftobj's number in base 2 (i.e. $self <<= $shiftobj). Returns $self.

Should be overwriten in case of alternate implementation.

=head2 inc($self)

Host implementation of $self's number incremented by one. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 dec($self)

Host implementation of $self's number decremented by one. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 int($self, $string)

Host implementation of $self's number setted to positive integer represented in $string, length being initialized to the number of characters in $string. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 hex($self, $string)

Host implementation of $self's number setted to positive hexadecimal integer represented in $string. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 neg($self)

Host implementation of $self's number sign change. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 abs($self)

Host implementation of absolute value applied to $self's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 new_from_sign($self)

Host implementation of sign applied to $self. Returns a new instance initialized with neg_one() if $self's value is negative, pos_one() if $self's value is positive, nan() if $self's value is not a number.

=head2 new_from_cmp($self, $cmpobj)

Host implementation of comparison between $self and $cmpobj. Returns a new instance initialized with neg_one() if $self's value < $cmpobj's value, pos_one() if $self's value > $cmpobj's value, pos_zero() if $self's value == $cmpobj's value, nan() otherwise.

=head2 add($self, $addobj)

Host implementation of $addobj's number added to $self's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 sub($self, $subobj)

Host implementation of $subobj's number substracted from $self's number. Returns $self.

Should be overwriten in case of alternate implementation.

=head2 inc_length($self)

Increase by one the length internal member of $self. This will be the host representation of a number of characters, used to evaluate internal number. Returns $self.

Should be overwriten in case of alternate implementation, if internal member is not named _length.

=head2 new_from_length($self)

Returns a new instance derived from the length internal member, initialized using $self->int(). Returns the new object instance.

Should be overwriten in case of alternate implementation, if internal member is not named _length.

=head2 sign($self)

Returns a perl's positive number if $self->host_value is a positive number, a perl's negative number if $self->host_value is a negative number, a perl's zero if $self->host_value is a zero, a perl's undef otherwise.

=head2 cmp($self, $cmpobj)

Alias for $self->new_from_cmp($cmpobj)->sign;

=head2 host_number($self)

Returns the internal $self's number hosted in $self.

Should be overwriten in case of alternate implementation, if internal member is not named _number.

=head2 host_value($self)

Returns the rounded internal $self's number hosted in $self.

Should be overwriten in case of alternate implementation.

=head2 is_zero($self)

Returns a perl's true or false if $self->host_value is zero. In case $self->host_value would be a blessed object, $self->host_value->is_zero() is returned if $self->host_value can do this method, otherwise undef is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_zero() method.

=head2 is_pos_one($self)

Returns a perl's true or false if $self->host_value is a +1. In case $self->host_value would be a blessed object, $self->host_value->is_one() is returned if $self->host_value can do this method, otherwise undef is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_one() method.

=head2 is_neg_one($self)

Returns a perl's true or false if $self->host_value is -1. In case $self->host_value would be a blessed object, $self->host_value->is_one('-') is returned if $self->host_value can do this method, otherwise undef is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_one('-') method.

=head2 is_pos($self)

Returns a perl's true or false if $self->host_value is a positive number. In case $self->host_value would be a blessed object, $self->host_value->is_pos() is returned if $self->host_value can do this method, otherwise undef is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_pos() method.

=head2 is_neg($self)

Returns a perl's true or false if $self->host_value is a negative number. In case $self->host_value would be a blessed object, $self->host_value->is_neg() is returned if $self->host_value can do this method, otherwise host's undefined value is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_neg() method.

=head2 is_inf($self)

Returns a perl's true or false if $self->host_value is infinite. In case $self->host_value would be a blessed object, $self->host_value->is_inf() is returned if $self->host_value can do this method, otherwise host's undefined value is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_inf() method.

=head2 is_nan($self)

Returns a perl's true or false if $self->host_value is not a number. In case $self->host_value would be a blessed object, $self->host_value->is_nan() is returned if $self->host_value can do this method, otherwise host's undefined is returned.

Should be overwriten in case of alternate implementation, if internal member is not named _number and is not an object supporting is_nan() method.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
