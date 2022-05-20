package Math::BigInt::Pari;

use 5.006002;
use strict;
use warnings;

use Math::BigInt::Lib 1.999801;

our @ISA = qw< Math::BigInt::Lib >;

our $VERSION = '1.3009';

use Math::Pari qw(PARI pari2pv gdivent bittest
                  gcmp gcmp0 gcmp1 gcd ifact gpui gmul
                  binomial lcm
                );

# MBI will call this, so catch it and throw it away
sub import { }
sub api_version() { 2; }        # we are compatible with MBI v1.83 and up

my $zero = PARI(0);             # for _copy
my $one  = PARI(1);             # for _inc and _dec
my $two  = PARI(2);             # for _is_two
my $ten  = PARI(10);            # for _digit

sub _new {
    # the . '' is because new($2) will give a magical scalar to us, and PARI
    # does not like this at all :/
    # use Devel::Peek; print Dump($_[1]);
    PARI($_[1] . '')
}

sub _from_hex {
    my $hex = $_[1];
    $hex = '0x' . $hex unless substr($hex, 0, 2) eq '0x';
    Math::Pari::_hex_cvt($hex);
}

sub _from_oct {
    Math::Pari::_hex_cvt('0' . $_[1]);
}

sub _from_bin {
    my $bin = $_[1];
    $bin = '0b' . $bin unless substr($bin, 0, 2) eq '0b';
    Math::Pari::_hex_cvt($bin);
}

sub _as_bin {
    my $v = unpack('B*', _mp2os($_[1]));
    return "0b0" if $v eq '';
    $v =~ s/^0*/0b/;
    $v;
}

sub _as_oct {
    my $v = _mp2oct($_[1]);
    return "00" if $v eq '';
    $v =~ s/^0*/0/;
    $v;
}

sub _as_hex {
    my $v = unpack('H*', _mp2os($_[1]));
    return "0x0" if $v eq '';
    $v =~ s/^0*/0x/;
    $v;
}

sub _to_bin {
    my $v = unpack('B*', _mp2os($_[1]));
    $v =~ s/^0+//;
    return "0" if $v eq '';
    $v;
}

sub _to_oct {
    my $v = _mp2oct($_[1]);
    $v =~ s/^0+//;
    return "0" if $v eq '';
    $v;
}

sub _to_hex {
    my $v = unpack('H*', _mp2os($_[1]));
    $v =~ s/^0+//;
    return "0" if $v eq '';
    $v;
}

sub _to_bytes {
    my $bytes = _mp2os($_[1]);
    return $bytes eq '' ? "\x00" : $bytes;
}

sub _mp2os {
    my($p) = @_;
    $p = PARI($p);
    my $base = PARI(1) << PARI(4*8);
    my $res = '';
    while ($p != 0) {
        my $r = $p % $base;
        $p = ($p - $r) / $base;
        my $buf = pack 'V', $r;
        if ($p == 0) {
            $buf = $r >= 16777216 ? $buf
                 : $r >= 65536    ? substr($buf, 0, 3)
                 : $r >= 256      ? substr($buf, 0, 2)
                 :                  substr($buf, 0, 1);
        }
        $res .= $buf;
    }
    scalar reverse $res;
}

sub _mp2oct {
    my($p) = @_;
    $p = PARI($p);
    my $base = PARI(8);
    my $res = '';
    while ($p != 0) {
        my $r = $p % $base;
        $p = ($p - $r) / $base;
        $res .= $r;
    }
    scalar reverse $res;
}

sub _zero { PARI(0) }
sub _one  { PARI(1) }
sub _two  { PARI(2) }
sub _ten  { PARI(10) }

sub _1ex  { gpui(PARI(10), $_[1]) }

sub _copy { $_[1] + $zero; }

sub _str { pari2pv($_[1]) }

sub _num { 0 + pari2pv($_[1]) }

sub _add { $_[1] += $_[2] }

sub _sub {
    if ($_[3]) {
        $_[2] = $_[1] - $_[2];
        return $_[2];
    }
    $_[1] -= $_[2];
}

sub _mul { $_[1] = gmul($_[1], $_[2]) }

sub _div {
    if (wantarray) {
        my $r = $_[1] % $_[2];
        $_[1] = gdivent($_[1], $_[2]);
        return ($_[1], $r);
    }
    $_[1] = gdivent($_[1], $_[2]);
}

sub _mod { $_[1] %= $_[2]; }

sub _nok {
    my ($class, $n, $k) = @_;

    # Math::Pari doesn't seem to be able to handle the case when n is large and
    # k is almost as big as n. For instance, the following returns zero (at
    # least for certain versions and configurations):
    #
    # $n = PARI("10000000000000000000");
    # $k = PARI("9999999999999999999");
    # print Math::Pari::binomial($n, $k);'

    # If k > n/2, or, equivalently, 2*k > n, compute nok(n, k) as nok(n, n-k).

    {
        my $twok = $class -> _mul($class -> _two(), $class -> _copy($k));
        if ($class -> _acmp($twok, $n) > 0) {
            $k = $class -> _sub($class -> _copy($n), $k);
        }
    }

    binomial($n, $k);
}

sub _inc { ++$_[1]; }
sub _dec { --$_[1]; }

sub _and { $_[1] &= $_[2] }

sub _xor { $_[1] ^= $_[2] }

sub _or { $_[1] |= $_[2] }

sub _pow { gpui($_[1], $_[2]) }

sub _gcd { gcd($_[1], $_[2]) }

sub _lcm { lcm($_[1], $_[2]) }

sub _len { length(pari2pv($_[1])) } # costly!

# XXX TODO: calc len in base 2 then appr. in base 10
sub _alen { length(pari2pv($_[1])) }

sub _zeros {
    my ($class, $x) = @_;
    return 0 if gcmp0($x);      # 0 has no trailing zeros

    my $u = $class -> _str($x);
    $u =~ /(0*)\z/;
    return length($1);

    #my $s = pari2pv($_[1]);
    #my $i = length($s);
    #my $zeros = 0;
    #while (--$i >= 0) {
    #    substr($s, $i, 1) eq '0' ? $zeros ++ : last;
    #}
    #$zeros;
}

sub _digit {
    # if $n < 0, we need to count from left and thus can't use the other method:
    if ($_[2] < 0) {
        return substr(pari2pv($_[1]), -1 - $_[2], 1);
    }
    # else this is faster (except for very short numbers)
    # shift the number right by $n digits, then extract last digit via % 10
    pari2pv(gdivent($_[1], $ten ** $_[2]) % $ten);
}

sub _is_zero { gcmp0($_[1]) }

sub _is_one { gcmp1($_[1]) }

sub _is_two { gcmp($_[1], $two) ? 0 : 1 }

sub _is_ten { gcmp($_[1], $ten) ? 0 : 1 }

sub _is_even { bittest($_[1], 0) ? 0 : 1 }

sub _is_odd { bittest($_[1], 0) ? 1 : 0 }

sub _acmp {
    my $i = gcmp($_[1], $_[2]) || 0;
    # work around bug in Pari (on 64bit systems?)
    $i = -1 if $i == 4294967295;
    $i;
}

sub _check {
    my ($class, $x) = @_;
    return "Undefined" unless defined $x;
    return "$x is not a reference to Math::Pari"
      unless ref($x) eq 'Math::Pari';
    return 0;
}

sub _sqrt {
    # square root of $x
    my ($class, $x) = @_;
    my $y = Math::Pari::sqrtint($x);
    return $y * $y > $x ? $y - $one : $y;       # bug in sqrtint()?
}

sub _root {
    # n'th root

    # Native version:
    return $_[1] = int(Math::Pari::sqrtn($_[1] + 0.5, $_[2]));
}

sub _modpow {
    # modulus of power ($x ** $y) % $z
    my ($c, $num, $exp, $mod) = @_;

    # in the trivial case,
    if (gcmp1($mod)) {
        $num = PARI(0);
        return $num;
    }

    if (gcmp1($num)) {
        $num = PARI(1);
        return $num;
    }

    if (gcmp0($num)) {
        if (gcmp0($exp)) {
            return PARI(1);
        } else {
            return PARI(0);
        }
    }

    my $acc = $c -> _copy($num);
    my $t = $c -> _one();

    my $expbin = $c -> _to_bin($exp);
    my $len = length($expbin);
    while (--$len >= 0) {
        if (substr($expbin, $len, 1) eq '1') {  # is_odd
            $c -> _mul($t, $acc);
            $t = $c -> _mod($t, $mod);
        }
        $c -> _mul($acc, $acc);
        $acc = $c -> _mod($acc, $mod);
    }
    $num = $t;
    $num;
}

sub _rsft {
    # (X, Y, N) = @_; means X >> Y in base N

    if ($_[3] != 2) {
        return $_[1] = gdivent($_[1], PARI($_[3]) ** $_[2]);
    }
    $_[1] >>= $_[2];
}

sub _lsft {
    # (X, Y, N) = @_; means X >> Y in base N

    if ($_[3] != 2) {
        return $_[1] *= PARI($_[3]) ** $_[2];
    }
    $_[1] <<= $_[2];
}

sub _fac {
    # factorial of argument
    $_[1] = ifact($_[1]);
}

# _set() - set an already existing object to the given scalar value

sub _set {
    my ($c, $x, $y) = @_;
    *x = \PARI($y . '');
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::Pari - a math backend library based on Math::Pari

=head1 SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'Pari';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'Pari';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'Pari';

=head1 DESCRIPTION

Math::BigInt::Pari inherits from Math::BigInt::Lib.

Provides support for big integer in Math::BigInt et al. calculations via means
of Math::Pari, an XS layer on top of the very fast PARI library.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-pari at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Pari>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc Math::BigInt::Pari

You can also look for information at:

=over 4

=item GitHub

L<https://github.com/pjacklam/p5-Math-BigInt-Pari>

=item RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-Pari>

=item MetaCPAN

L<https://metacpan.org/release/Math-BigInt-Pari>

=item CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Pari>

=item CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-BigInt-Pari>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Original Math::BigInt::Pari written by Benjamin Trott 2001,
E<lt>ben@rhumba.pair.comE<gt>.

Extended and maintained by Tels 2001-2007 L<http://bloodgate.com>

Maintained by Peter John Acklam E<lt>pjacklam@gmail.comE<gt> 2010-2021.

L<Math::Pari> was written by Ilya Zakharevich.

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigFloat>, L<Math::Pari>, and the other backends
L<Math::BigInt::Calc>, L<Math::BigInt::GMP>, and L<Math::BigInt::Pari>.

=cut
