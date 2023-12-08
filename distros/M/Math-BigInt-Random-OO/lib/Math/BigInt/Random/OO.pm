# -*- mode: perl; coding: utf-8-unix; -*-

package Math::BigInt::Random::OO;

###############################################################################
## Modules and general package variables.
###############################################################################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

# Modules from the Standard Perl Library.

use Config;
use Carp;
use Math::BigInt;
#use Data::Dumper;

###############################################################################
# Package variables.
###############################################################################

our $VERSION = '0.05';

=pod

=encoding utf8

=head1 NAME

Math::BigInt::Random::OO - generate uniformly distributed Math::BigInt objects

=head1 SYNOPSIS

=for test_synopsis
no strict 'vars'

  use Math::BigInt::Random::OO;

  # Random numbers between 1e20 and 2e30:

  $gen = Math::BigInt::Random::OO -> new(min => "1e20",
                                         min => "2e30");
  $x = $gen -> generate();      # one number
  $x = $gen -> generate(1);     # ditto
  @x = $gen -> generate(100);   # 100 numbers

  # Random numbers with size fitting 20 hexadecimal digits:

  $gen = Math::BigInt::Random::OO -> new(length => 20,
                                         base => 16);
  @x = $gen -> generate(100);

=head1 ABSTRACT

Math::BigInt::Random::OO is a module for generating arbitrarily large random
integers from a discrete, uniform distribution. The numbers are returned as
Math::BigInt objects.

=head1 DESCRIPTION

Math::BigInt::Random::OO is a module for generating arbitrarily large random
integers from a discrete, uniform distribution. The numbers are returned as
Math::BigInt objects.

=head1 CONSTRUCTORS

=over 4

=item CLASS -E<gt> new ( ... )

Returns a new C<Math::BigInt::Random::OO> random number generator object. The
arguments are given in the "hash style", as shown in the following example
which constructs a generator for random numbers in the range from -2 to 3,
inclusive.

  my $gen = Math::BigInt::Random::OO -> new(min => -2,
                                            max =>  3);

The following parameters are recognized.

=over 4

=item min =E<gt> NUM

Specifies the minimum possible output value, i.e., the lower bound. If `max' is
given, but `min' is not, then `min' is set to zero.

=item max =E<gt> NUM

Specifies the maximum possible output value, i.e., the upper bound. If `max' is
given, but `min' is not, then `max' must be non-negative.

=item length =E<gt> NUM

Specifies the length of the output value, i.e., the number of digits. This
parameter, possibly used together with `base', is more convenient than `min'
and `max' when you want all random numbers have the same number of digits. If
the base is not given explicitly with the `base' option, then a base of 10 is
used. The following two constructors are equivalent

  $gen1 = Math::BigInt::Random::OO -> new(length => $n, base => $b);

  $min  = Math::BigInt -> new($b) -> bpow($n - 1);
  $max  = Math::BigInt -> new($b) -> bpow($n) -> bsub(1));
  $gen2 = Math::BigInt::Random::OO -> new(min => $min, max => $max);

For instance, if the length is 4 and the base is 10, the random numbers will be
in the range from 1000 to 9999, inclusive. If the length is 3 and the base is
16, the random numbers will be in the range from 256 to 4095, which is 100 to
fff hexadecimal.

This option is ignored if the `max' option is present.

=item base =E<gt> NUM

Sets the base to be used with the `length' option. See also the description for
the `length' option.

=item length_bin =E<gt> NUM

This option is only for compatibility with Math::BigInt::Random. The following
two cases are equivalent

  $class -> new(length_bin => $n);
  $class -> new(length => $n, base => 2);

=item length_hex =E<gt> NUM

This option is only for compatibility with Math::BigInt::Random. The following
two cases are equivalent

  $class -> new(length_hex => $n);
  $class -> new(length => $n, base => 16);

=back

=cut

sub new {
    my $proto    = shift;
    my $protoref = ref $proto;
    my $class    = $protoref || $proto;
    my $name     = 'new';

    # Check how the method is called.

    croak "$name() is a class method, not an instance/object method"
      if $protoref;

    # Check the number of input arguments.

    croak "$name(): not enough input arguments"      if @_ < 1;
    croak "$name(): odd number of input arguments"   if @_ % 2;

    # Check the context.

    carp "$name(): useless use of method in void context"
      unless defined wantarray;

    # Initialize the new object.

    my $self = {
                min       => undef,
                max       => undef,
                length    => undef,
                base      => 10,
               };

    # Get the input arguments.

    while (@_) {
        my $key = shift;
        my $val = shift;

        croak "$name(): parameter can't be undefined"
          unless defined $key;

        # The minimum value, i.e., lower bound.

        if ($key eq 'min') {
            croak "$name(): minimum value can't be undefined"
              unless defined $val;
            $val = Math::BigInt -> new($val)
              unless ref($val) && $val -> isa('Math::BigInt');
            croak "$name(): minimum is not a valid number"
              if $val -> is_nan();
            $self -> {min} = $val -> as_int();
            next;
        }

        # The maximum value, i.e., upper bound.

        if ($key eq 'max') {
            croak "$name(): maximum value can't be undefined"
              unless defined $val;
            $val = Math::BigInt -> new($val)
              unless ref($val) && $val -> isa('Math::BigInt');
            croak "$name(): maximum is not a valid number"
              if $val -> is_nan();
            $self -> {max} = $val -> as_int();
            next;
        }

        # The length for the given base.

        if ($key eq 'length') {
            croak "$name(): length value can't be undefined"
              unless defined $val;
            croak "$name(): length value must be positive"
              unless $val > 0;
            $self -> {length} = $val;
            $self -> {base}   = 10;
            next;
        }

        # The base used when computing the length.

        if ($key eq 'base') {
            croak "$name(): base value can't be undefined"
              unless defined $val;
            croak "$name(): base value must be positive"
              unless $val > 0;
            $self -> {base} = $val;
            next;
        }

        # The length with an implicit base 16.

        if ($key eq 'length_hex') {
            croak "$name(): length_hex value can't be undefined"
              unless defined $val;
            croak "$name(): length_hex value must be positive"
              unless $val > 0;
            $self -> {length} = $val;
            $self -> {base}   = 16;
            next;
        }

        # The length with an implicit base 2.

        if ($key eq 'length_bin') {
            croak "$name(): length_bin value can't be undefined"
              unless defined $val;
            croak "$name(): length_bin value must be positive"
              unless $val > 0;
            $self -> {length} = $val;
            $self -> {base}   = 2;
            next;
        }

        croak "$name(): unknown parameter -- $key\n";
    }

    # If the maximum value is given, use that. If the length is given, compute
    # the minimum and maximum values for the given length and base. For
    # instance, if the base is 10 and the length is 3, the minimum value is
    # 100, and the maximum is 999. If the base is 2 and the length is 5, the
    # minimum value is 10000 binary (= 16 decimal) and the maximum is 11111
    # binary (= 31 decimal).

    if (defined $self->{max}) {

        if (defined $self->{length}) {
            carp "$name(): 'max' is given, so 'length' is ignored";
        }
        if (! defined $self->{min}) {
            $self->{min} = 0,
        }

        croak "$name(): maximum can't be smaller than minimum"
          if $self->{max} < $self->{min};

    } else {

        if (defined $self->{length}) {
            my $base = $self -> {base};
            my $len  = $self -> {length};
            $self->{min} = Math::BigInt -> new($base) -> bpow($len - 1);
            $self->{max} = $self->{min} -> copy() -> bmul($base) -> bsub(1);
        } else {
            croak "$name(): either 'max' or 'length' must be given\n";
        }

    }

    $self -> {_range} = $self->{max} - $self->{min} + 1;

    # The task is to generate a uniformly distributed random integer X,
    # satisfying 0 <= X < N. We do this by generating uniformly distributed
    # random numbers X, where 0 <= X <= 2^E for some integer E, until X < N.

    # Now find the power of 2 that is no larger than $max, i.e.,
    #
    #   $exp2 = ceil(log($max) / log(2));
    #   $pow2 = 2 ** $exp2;

    # We subtract one from the length to avoid overshooting too much. If we
    # undershoot, it will be corrected below.

    my ($mlen, $elen)  = $self -> {_range} -> length();
    my $len = $mlen + $elen - 1;

    my $exp2 = int($len * log(10) / log(2));
    my $pow2 = Math::BigInt -> new("1") -> blsft($exp2);

    if (0) {
        printf "\n";
        printf "  range = %s\n", $self->{_range};
        printf "\n";
        printf "    len = %s\n", $len;
        printf "   exp2 = %s\n", $exp2;
        printf "   pow2 = %s\n", $pow2;
    }

    # Final adjustment of the estimate above. If we overshoot, like if $max is
    # 15 and we use $exp2 = 5 and $pow2 = 32 rather than $exp2 = 4 and $pow2 =
    # 16, it only makes the algorithm slower. If we undershoot, however, the
    # algorithm fails, so this must be avoided.

    my $two  = Math::BigInt -> new("2");
    while ($pow2 < $self -> {_range}) {
        $pow2 -> bmul($two);
        $exp2++;
    }

    if (0) {
        printf "\n";
        printf "   exp2 : %s\n", $exp2;
        printf "   pow2 : %s\n", $pow2;
    }

    my $whole_bytes = int($exp2 / 8);
    my $extra_bits  = $exp2 % 8;

    # Save these, since they are needed to generate the random numbers.

    $self->{_whole_bytes} = $whole_bytes;
    $self->{_extra_bits}  = $extra_bits;

    # Bless the reference into an object and return it.

    bless $self, $class;
}

=pod

=item OBJECT -E<gt> generate ( COUNT )

=item OBJECT -E<gt> generate ( )

Generates the given number of random numbers, or one number, if no input
argument is given.

  # Generate ten random numbers:

  my @num = $gen -> generate(10);

=cut

sub generate {
    my $self    = shift;
    my $selfref = ref $self;
    my $name    = 'generate';

    # Check how the method is called.

    croak "$name() is an object instance method, not a class method"
      unless $selfref;

    # Check number of input arguments.

    #croak "$name(): not enough input arguments" if @_ < 1;
    croak "$name(): too many input arguments"   if @_ > 1;

    # Get the count.

    my $count = 1;
    if (@_) {
        $count = shift;
        croak "$name(): input argument must be defined"
          unless defined $count;
        croak "$name(): input argument must be an integer"
          unless $count = int $count;
    }

    # Generate the random numbers.

    my @num;

    if ($self->{_range} -> is_one()) {

        for (1 .. $count) {
            push @num, $self->{min} -> copy();
        }

    } else {

        for (1 .. $count) {
            my $num;
            do {
                my $str = "";
                $str .= sprintf "%02x", int(rand(1 << $self->{_extra_bits}))
                  if $self->{_extra_bits};
                $str .= sprintf "%02x", int(rand(256))
                  for 1 .. $self->{_whole_bytes};
                $num = Math::BigInt -> from_hex($str);
            } until $num < $self->{_range};
            $num += $self->{min};
            push @num, $num;
        }
    }

    return @num if wantarray;
    return $num[0];
}

=pod

=back

=head1 TODO

=over 4

=item *

Add a way to change the core uniform random number generator. Currently,
CORE::rand() is used, but it would be nice to be able to switch to, e.g.,
Math::Random::random_uniform_integer().

=item *

Add functionality similar to the C<use_internet> parameter argument in
Math::BigInt::Random::random_bigint(). This could be implemented using, e.g.,
Net::Random.

=item *

Add more tests.

=back

=head1 NOTES

The task is to generate a random integer X satisfying X_min E<lt>= X E<lt>=
X_max. This is equivalent to generating a random integer U satisfying 0 E<lt>=
U E<lt> U_max, where U_max = X_max - X_min + 1, and then returning X, where X =
U + X_min.

=over

=item *

Find the smallest integer N so that U_max E<lt>= 2**N.

=item *

Generate uniformly distributed random integers U in the range 0 E<lt>= U E<lt>
2**N until we have the first U E<lt> U_max. Then return X, where X = U + X_min.

=back

The random integer U, where 0 E<lt>= U E<lt> 2**N is generated as a sequence of
random bytes, except for the N % 8 most significant bits, if any. For example,
if N = 21 = 5 + 8 + 8, then the 5 most significand bits are generated first,
followed by two 8 bit bytes.

    |    top bits   |    first whole byte    |    second whole byte   |
      0  0  0  0  0   1  1  1  1  1  1  1  1   2  2  2  2  2  2  2  2
  int(rand(1 << 5))     int(rand(1 << 8))         int(rand(1 << 8))

=head2 Problems with Math::BigInt::Random

I wrote this module partly since Math::BigInt::Random v0.04 is buggy, and in
many cases slower, and partly because I prefer an object-oriented interface.
The bugs in Math::BigInt::Random v0.04 are

=over 4

=item *

When the range (the maximum value minus the minimum value) is smaller than
1048575 (fffff hexadecimal), the maximum value will never be returned.

=item *

When the range is not a power of two, certain values are more likely to occur
than others.

=back

The core of this last problem is the use of int(rand(X)), which only returns
uniformly distributed numbers when X is a power of two no larger than
I<RANDBITS>.

In addition, the function Math::BigInt::Random::random_bigint() generates only
one random integer at a time, and in doing so, there is some overhead. In
Math::BigInt::Random::OO, this overhead is placed in the new() constructor, so
it is done only once, independently of how many random numbers are generated by
the generator() method.

=head1 CAVEATS

=over 4

=item *

Some versions of CORE::rand() behave poorly, so the quality of the random
numbers generated depend on the quality of the random number returned
by int(rand(256)).

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-bigint-random-oo at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Math-BigInt-Random-OO> I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Random::OO

You can also look for information at:

=over 4

=item * GitHub Source Repository

L<https://github.com/pjacklam/p5-Math-BigInt-Random-OO>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-Random-OO>

=item * MetaCPAN

L<https://metacpan.org/dist/Math-BigInt-Random-OO>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Random-OO>

=back

=head1 SEE ALSO

Math::BigInt::Random(3), Math::Random(3), Net::Random(3).

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam (at) gmail.comE<gt>.

=head1 COPYRIGHT & LICENSE

Copyright 2010,2020,2023 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;                      # modules must return true
