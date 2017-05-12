package Math::BigInt::BitVect;

use 5.006;
use strict;
use warnings;

use Math::BigInt::Lib 1.999801;

our @ISA = qw< Math::BigInt::Lib >;

our $VERSION = '1.13';

use Carp;
use Bit::Vector;

##############################################################################
# global constants, flags and accessory

my $bits  = 32;                 # make new numbers this wide
my $chunk = 32;                 # keep size a multiple of this

# for is_* functions
my $zero = Bit::Vector->new_Dec($bits, 0);
my $one  = Bit::Vector->new_Dec($bits, 1);
my $two  = Bit::Vector->new_Dec($bits, 2);
my $ten  = Bit::Vector->new_Dec($bits, 10);

sub api_version { 2; }

sub import { }

sub __dump {
    my ($class, $x) = @_;
    my $str = $class -> _as_bin($x);

    # number of bits allocated

    my $nbits_alloc = $x -> Size();
    my $imax        = $x -> Max();

    # minimum number of bits needed

    my $nbits_min = $imax < 0 ? 1 : $imax + 2;

    # expected number of bits

    my $nbits_exp = $chunk * __ceil($nbits_min / $chunk);

    return "$str ($nbits_min/$nbits_exp/$nbits_alloc)";
}

##############################################################################
# create objects from various representations

sub _new {
    my ($class, $str) = @_;

    # $nbin is the maximum number of bits required to represent any $ndec digit
    # number in base two. log(10)/log(2) = 3.32192809488736

    my $ndec = length($str);
    my $nbin = 1 + __ceil(3.32192809488736 * $ndec);

    $nbin = $chunk * __ceil($nbin / $chunk); # chunked

    my $u = Bit::Vector->new_Dec($nbin, $str);
    $class->__reduce($u) if $nbin > $bits;
    $u;
}

sub _from_hex {
    my ($class, $str) = @_;

    $str =~ s/^0[xX]//;
    my $bits = 1 + 4 * length($str);
    $bits = $chunk * __ceil($bits / $chunk);
    my $x = Bit::Vector->new_Hex($bits, $str);
    $class->__reduce($x);
}

sub _from_bin {
    my $str = $_[1];

    $str =~ s/^0[bB]//;
    my $bits = 1 + length($str);
    $bits = $chunk * __ceil($bits / $chunk);
    Bit::Vector->new_Bin($bits, $str);
}

sub _zero {
    Bit::Vector->new_Dec($bits, 0);
}

sub _one {
    Bit::Vector->new_Dec($bits, 1);
}

sub _two {
    Bit::Vector->new_Dec($bits, 2);
}

sub _ten {
    Bit::Vector->new_Dec($bits, 10);
}

sub _copy {
    $_[1]->Clone();
}

##############################################################################
# convert back to string and number

sub _str {
    # make string
    my $x = $_[1]->to_Dec();
    $x;
}

sub _num {
    # make a number
    0 + $_[1]->to_Dec();
}

sub _as_hex {
    my $x = lc $_[1]->to_Hex();
    $x =~ s/^0*([\da-f])/0x$1/;
    $x;
}

sub _as_bin {
    my $x = $_[1]->to_Bin();
    $x =~ s/^0*(\d)/0b$1/;
    $x;
}

##############################################################################
# actual math code

sub _add {
    my ($class, $x, $y) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys) + 2;         # 2 extra bits, to avoid overflow
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;
    $x->add($x, $y, 0);

    # then reduce again
    $class->__reduce($x) if $ns != $xs;
    $class->__reduce($y) if $ns != $ys;

    $x;
}

sub _sub {
    # $x is always larger than $y! So overflow/underflow can not happen here
    my ($class, $x, $y, $z) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys);     # no reserve, since no overflow
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;

    if ($z) {
        $y->subtract($x, $y, 0);
        $class->__reduce($y);
        $class->__reduce($x) if $ns != $xs;
    } else {
        $x->subtract($x, $y, 0);
        $class->__reduce($y) if $ns != $ys;
        $class->__reduce($x);
    }

    return $x unless $z;
    $y;
}

sub _mul {
    my ($class, $x, $y) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    # reserve some bits (and +2), so we never overflow
    my $ns = $xs + $ys + 2;     # 2^12 * 2^8 = 2^20 (so we take 22)
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;

    # then mul
    $x->Multiply($x, $y);
    # then reduce again
    $class->__reduce($y) if $ns != $ys;
    $class->__reduce($x) if $ns != $xs;
    $x;
}

sub _div {
    my ($class, $x, $y) = @_;

    # sizes must match!

    my $xs = $x->Max();
    my $ys = $y->Max();

    # if $ys > $xs, quotient is zero

    if ($xs < 0 || $xs < $ys) {
        my $r = $x->Clone();
        $x = Bit::Vector->new_Hex($chunk, 0);
        return wantarray ? ($x, $r) : $x;
    } else {
        my $ns = $x->Size();    # common size
        my $ys = $y->Size();
        $y->Resize($ns) if $ys < $ns;
        my $r = Bit::Vector->new_Hex($ns, 0);
        $x->Divide($x, $y, $r);
        $class->__reduce($y) if $ys < $ns;
        $class->__reduce($x);
        return wantarray ? ($x, $class->__reduce($r)) : $x;
    }
}

sub _inc {
    my ($class, $x) = @_;

    # an overflow can occur if the leftmost bit and the rightmost bit are
    # both 1 (we don't bother to look at the other bits)

    my $xs = $x->Size();
    if ($x->bit_test($xs-2) & $x->bit_test(0)) {
        $x->Resize($xs + $chunk); # make one bigger
        $x->increment();
        $class->__reduce($x);           # in case no overflow occured
    } else {
        $x->increment();        # can't overflow, so no resize/reduce necc.
    }
    $x;
}

sub _dec {
    # input is >= 1
    my ($class, $x) = @_;

    $x->decrement();            # will only get smaller, so reduce afterwards
    $class->__reduce($x);
}

sub _and {
    # bit-wise AND of two numbers
    my ($class, $x, $y) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys);     # highest bits in $x, $y are zero
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;

    $x->And($x, $y);
    $class->__reduce($y) if $ns != $xs;
    $class->__reduce($x);
    $x;
}

sub _xor {
    # bit-wise XOR of two numbers
    my ($class, $x, $y) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys);     # highest bits in $x, $y are zero
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;

    $x->Xor($x, $y);
    $class->__reduce($y) if $ns != $xs;
    $class->__reduce($x);
    $x;
}

sub _or {
    # bit-wise OR of two numbers
    my ($class, $x, $y) = @_;

    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys);     # highest bits in $x, $y are zero
    $ns = $chunk * __ceil($ns / $chunk);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;

    $x->Or($x, $y);
    $class->__reduce($y) if $ns != $xs;
    $class->__reduce($x) if $ns != $xs;
    $x;
}

sub _gcd {
    # Greatest Common Divisor
    my ($class, $x, $y) = @_;

    # Original, Bit::Vectors Euklid algorithmn
    # sizes must match!
    my $xs = $x->Size();
    my $ys = $y->Size();
    my $ns = __max($xs, $ys);
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;
    $x->GCD($x, $y);
    $class->__reduce($y) if $ys != $ns;
    $class->__reduce($x);
    $x;
}

##############################################################################
# testing

sub _acmp {
    my ($class, $x, $y) = @_;

    my $xm = $x->Size();
    my $ym = $y->Size();
    my $diff = ($xm - $ym);

    return $diff <=> 0 if $diff != 0;

    # used sizes are the same, so no need for Resizing/reducing
    $x->Lexicompare($y);
}

sub _len {
    # return length, aka digits in decmial, costly!!
    length($_[1]->to_Dec());
}

sub _alen {
    my $nb = $_[1] -> Max();    # index (zero-based)
    return 1 if $nb < 0;        # $nb is negative if $_[1] is zero
    int(0.5 + 3.32192809488736 * ($nb + 1));
}

sub _digit {
    # return the nth digit, negative values count backward; this is costly!
    my ($class, $x, $n) = @_;

    substr($x->to_Dec(), -($n+1), 1);
}

sub _fac {
    # factorial of $x
    my ($class, $x) = @_;

    if ($class->_is_zero($x)) {
        $x = $class->_one();        # not $one since we need a copy/or new object!
        return $x;
    }
    my $n = $class->_copy($x);
    $x = $class->_one();            # not $one since we need a copy/or new object!
    while (!$class->_is_one($n)) {
        $class->_mul($x, $n);
        $class->_dec($n);
    }
    $x;                         # no __reduce() since only getting bigger
}

sub _pow {
    # return power
    my ($class, $x, $y) = @_;

    # x**0 = 1

    return $class -> _one() if $class -> _is_zero($y);

    # 0**y = 0 if $y != 0 (y = 0 is taken care of above).

    return $class -> _zero() if $class -> _is_zero($x);

    my $ns = 1 + ($x -> Max() + 1) * $y -> to_Dec();
    $ns = $chunk * __ceil($ns / $chunk);

    my $z = Bit::Vector -> new($ns);

    $z -> Power($x, $y);
    return $class->__reduce($z);
}

###############################################################################
# shifting

sub _rsft {
    my ($class, $x, $n, $b) = @_;

    if ($b == 2) {
        $x->Move_Right($class->_num($n)); # must be scalar - ugh
    } else {
        $b = $class->_new($b) unless ref($b);
        $x = $class->_div($x, $class->_pow($b, $n));
    }
    $class->__reduce($x);
}

sub _lsft {
    my ($class, $x, $n, $b) = @_;

    if ($b == 2) {
        $n = $class->_num($n);              # need scalar for Resize/Move_Left - ugh
        my $size = $x->Size() + 1 + $n; # y and one more
        my $ns = (int($size / $chunk)+1)*$chunk;
        $x->Resize($ns);
        $x->Move_Left($n);
        $class->__reduce($x);               # to minimum size
    } else {
        $b = $class->_new($b);
        $class->_mul($x, $class->_pow($b, $n));
    }
    return $x;
}

##############################################################################
# _is_* routines

sub _is_zero {
    # return true if arg is zero
    my $x = $_[1];

    return $x -> is_empty() ? 1 : 0;
}

sub _is_one {
    # return true if arg is one
    my $x = $_[1];

    return 0 if $x->Size() != $bits; # if size mismatch
    $x->equal($one);
}

sub _is_two {
    # return true if arg is two
    my $x = $_[1];

    return 0 if $x->Size() != $bits; # if size mismatch
    $x->equal($two);
}

sub _is_ten {
    # return true if arg is ten
    my $x = $_[1];

    return 0 if $x->Size() != $bits; # if size mismatch
    $_[1]->equal($ten);
}

sub _is_even {
    # return true if arg is even

    $_[1]->bit_test(0) ? 0 : 1;
}

sub _is_odd {
    # return true if arg is odd

    $_[1]->bit_test(0) ? 1 : 0;
}

###############################################################################
# check routine to test internal state of corruptions

sub _check {
    # no checks yet, pull it out from the test suite
    my $x = $_[1];
    return "Undefined" unless defined $x;
    return "$x is not a reference to Bit::Vector" if ref($x) ne 'Bit::Vector';

    return "$x is negative" if $x->Sign() < 0;

    # Get the size.

    my $xs = $x -> Size();

    # The size must be a multiple of the chunk size.

    my $ns = $chunk * int($xs / $chunk);
    if ($xs != $ns) {
        return "Size($x) is $x bits, expected a multiple of $chunk.";
    }

    # The size must not be larger than necessary.

    my $imax = $x -> Max();                 # index of highest non-zero bit
    my $nmin = $imax < 0 ? 1 : $imax + 2;   # minimum number of bits required
    $ns = $chunk * __ceil($nmin / $chunk);    # minimum size in whole chunks
    if ($xs != $ns) {
        return "Size($x) is $xs bits, but only $ns bits are needed.";
    }

    0;
}

sub _mod {
    my ($class, $x, $y) = @_;

    # Get current sizes.

    my $xs = $x -> Size();
    my $ys = $y -> Size();

    # Resize to a common size.

    my $ns = __max($xs, $ys);
    $x -> Resize($ns) if $xs < $ns;
    $y -> Resize($ns) if $ys < $ns;
    my $quo = Bit::Vector -> new($ns);
    my $rem = Bit::Vector -> new($ns);

    # Get the quotient.

    $quo -> Divide($x, $y, $rem);

    # Resize $y back to its original size, if necessary.

    $y -> Resize($ys) if $ys < $ns;

    $class -> __reduce($rem);
}

# The following methods are not implemented (yet):

#sub _1ex { }

#sub _as_bytes { }

#sub _as_oct { }

#sub _from_bytes { }

#sub _from_oct { }

#sub _lcm { }

#sub _log_int { }

#sub _modinv { }

#sub _modpow { }

#sub _nok { }

#sub _root { }

#sub _sqrt { }

#sub _zeros { }

sub __reduce {
    # internal reduction to make minimum size
    my ($class, $x) = @_;

    my $bits_allocated = $x->Size();
    return $x if $bits_allocated <= $chunk;

    # The number of bits we use is always a positive multiple of $chunk. Add
    # two extra bits to $imax; one because $imax is zero-based, and one to
    # avoid that the highest bit is one, which signifies a negative number.

    my $imax = $x->Max();
    my $bits_needed = $imax < 0 ? 1 : 2 + $imax;
    $bits_needed = $chunk * __ceil($bits_needed / $chunk);

    if ($bits_allocated > $bits_needed) {
        $x->Resize($bits_needed);
    }

    $x;
}

###############################################################################
# helper/utility functions

# maximum of 2 values

sub __max {
    my ($m, $n) = @_;
    $m > $n ? $m : $n;
}

# ceiling function

sub __ceil {
    my $x  = shift;
    my $ix = int $x;
    ($ix >= $x) ? $ix : $ix + 1;
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::BitVect - a math backend library based on Bit::Vector

=head1 SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'BitVect';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'BitVect';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'BitVect';

=head2 DESCRIPTION

Provides support for big integer calculations via Bit::Vector, a fast C library
by Steffen Beier.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-parts at rt.cpan.org>, or through the web interface at

  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-BigInt-BitVect>

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Math::BigInt::BitVect

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-BitVect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-BitVect>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-BitVect>

=item * CPAN Testers PASS Matrix

L<http://pass.cpantesters.org/distro/M/Math-BigInt-BitVect.html>

=item * CPAN Testers Reports

L<http://www.cpantesters.org/distro/M/Math-BigInt-BitVect.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-BitVect>

=back

=head1 SEE ALSO

L<Math::BigInt::Lib> for a description of the API.

Alternative backend libraries L<Math::BigInt::Calc>, L<Math::BigInt::FastCalc>,
L<Math::BigInt::GMP>, and L<Math::BigInt::Pari>.

The modules that use these libraries L<Math::BigInt>, L<Math::BigFloat>, and
L<Math::BigRat>.

=head1 AUTHOR

(c) 2001, 2002, 2003, 2004 by Tels http://bloodgate.com

Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2016

The module Bit::Vector is (c) by Steffen Beyer. Thanx!

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
