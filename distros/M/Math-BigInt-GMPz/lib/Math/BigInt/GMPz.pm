package Math::BigInt::GMPz;

use 5.006002;
use strict;
use warnings;

use Math::BigInt::Lib 1.999801;

our @ISA = qw< Math::BigInt::Lib >;

our $VERSION = '0.0003';

use Math::GMPz qw< :mpz >;

sub import { }

my $zero = Rmpz_init();                     # for _is_zero
my $one  = Rmpz_init_set_str("1", 10);      # for _is_one, _inc, and _dec
my $two  = Rmpz_init_set_str("2", 10);      # for _is_two
my $ten  = Rmpz_init_set_str("10", 10);     # for _is_ten, _digit

sub api_version { 2; }

sub _new {
    Rmpz_init_set_str($_[1], 10);
}

sub _zero {
    Rmpz_init();
}

sub _one  {
    Rmpz_init_set_str("1", 10);
}

sub _two  {
    Rmpz_init_set_str("2", 10);
}

sub _ten  {
    Rmpz_init_set_str("10", 10);
}

sub _from_bin {
    my $str = $_[1];
    $str =~ s/^0[Bb]//;                 # remove leading '0b'
    Rmpz_init_set_str($str, 2);
}

sub _from_oct {
    Rmpz_init_set_str($_[1], 8);
}

#sub _from_dec {
#    Rmpz_init_set_str($_[1], 10);
#}

sub _from_hex {
    my $str = $_[1];
    $str =~ s/^0[Xx]//;                 # remove leading '0x'
    Rmpz_init_set_str($str, 16);
}

sub _from_bytes {
    my $rop  = Rmpz_init();
    my $bstr = $_[1];
    my $len  = length $bstr;
    my ($order, $size, $endian, $nails) = (1, 1, 0, 0);
    Rmpz_import($rop, $len, $order, $size, $endian, $nails, $bstr);
    return $rop;
}

sub _from_base {
    my $class = shift;

    # If a collation sequence is given, pass everything to parent.
    return $class -> SUPER::_from_base(@_) if @_ == 3;

    # If base > 36, pass everything to parent.
    my $str   = $_[0];
    my $base  = $_[1];
    $base = $class -> _new($base) unless ref($base);
    if ($class -> _acmp($base, $class -> _new("36")) > 0) {
        return $class -> SUPER::_from_base($str, $base);
    } else {
        return Rmpz_init_set_str($str, $base);
    }
}

sub _1ex  {
    Rmpz_init_set_str("1" . ("0" x $_[1]));
}

sub _add {
    Rmpz_add($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _mul {
    Rmpz_mul($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _div {
    if (wantarray) {
        my $r = Rmpz_init();
        Rmpz_fdiv_qr($_[1], $r, $_[1], $_[2]);
        return ($_[1], $r);
    }
    Rmpz_fdiv_q($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _sub {
    if ($_[3]) {
        $_[2] = $_[1] - $_[2];
        return $_[2];
    }
    Rmpz_sub($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _dec {
    Rmpz_sub_ui($_[1], $_[1], 1);
    return $_[1];
}

sub _inc {
    Rmpz_add_ui($_[1], $_[1], 1);
    return $_[1];
}

sub _mod {
    Rmpz_fdiv_r($_[1], $_[1], $_[2]);
    return $_[1];
};

sub _sqrt {
    Rmpz_sqrt($_[1], $_[1]);
    return $_[1];
}

sub _root {
    Rmpz_root($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _fac {
    Rmpz_fac_ui($_[1], $_[1]);
    return $_[1];
}

sub _dfac {
    Rmpz_2fac_ui($_[1], $_[1]);
    return $_[1];
}

sub _pow {
    Rmpz_pow_ui($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _modinv {
    my $bool = Rmpz_invert($_[1], $_[1], $_[2]);
    return $bool ? ($_[1], '+') : (undef, undef);
}

sub _modpow {
    Rmpz_powm($_[1], $_[1], $_[2], $_[3]);
    return $_[1];
}

sub _rsft {
    # (X, Y, N) = @_; means X >> Y in base N
    if ($_[3] == 2) {
        Rmpz_div_2exp($_[1], $_[1], $_[2]);
    } else {
        # N must be an unsigned integer
        my $n = Rmpz_init_set_ui($_[3]);
        # Y must be a Math::GMPz
        my $y = Rmpz_get_ui($_[2]);
        Rmpz_pow_ui($n, $n, $y);
        Rmpz_div($_[1], $_[1], $n);
    }
    return $_[1];
}

sub _lsft {
    # (X, Y, N) = @_; means X << Y in base N (= X * N^Y)
    if ($_[3] == 2) {
        Rmpz_mul_2exp($_[1], $_[1], $_[2]);
    } else {
        # N must be an unsigned integer
        my $n = Rmpz_init_set_ui($_[3]);
        # Y must be a Math::GMPz
        my $y = Rmpz_get_ui($_[2]);
        #$_[1] = $_[1] * $n ** $y;
        Rmpz_pow_ui($n, $n, $y);
        Rmpz_mul($_[1], $_[1], $n);
    }
    return $_[1];
}

#sub _log_int { }

sub _gcd {
    Rmpz_gcd($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _lcm {
    Rmpz_lcm($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _and {
    Rmpz_and($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _or {
    Rmpz_ior($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _xor {
    Rmpz_xor($_[1], $_[1], $_[2]);
    return $_[1];
}

sub _is_zero {
    !Rmpz_cmp($_[1], $zero);
}

sub _is_one {
    !Rmpz_cmp($_[1], $one);
}

sub _is_two {
    !Rmpz_cmp($_[1], $two);
}

sub _is_ten {
    !Rmpz_cmp($_[1], $ten);
}

sub _is_even {
    Rmpz_even_p($_[1]);
}

sub _is_odd {
    Rmpz_odd_p($_[1]);
}

sub _acmp {
    Rmpz_cmp($_[1], $_[2]);
}

sub _str {
    Rmpz_get_str($_[1], 10);
}

sub _as_bin {
    '0b' . Rmpz_get_str($_[1], 2);
}

sub _as_oct {
    '0' . Rmpz_get_str($_[1], 8);
}

sub _as_hex {
    '0x' . Rmpz_get_str($_[1], 16);
}

sub _to_bin {
    Rmpz_get_str($_[1], 2);
}

sub _to_oct {
    Rmpz_get_str($_[1], 8);
}

#sub _to_dec {
#    Rmpz_get_str($_[1], 10);
#}

sub _to_hex {
    Rmpz_get_str($_[1], 16);
}

sub _to_bytes {
    my ($class, $x) = @_;
    return "\x00" if $class -> _is_zero($x);
    my ($order, $size, $endian, $nails) = (1, 1, 0, 0);
    Rmpz_export($order, $size, $endian, $nails, $x);
}

*_as_bytes = \&_to_bytes;

sub _to_base {
    my $class = shift;

    # If a collation sequence is given, pass everything to parent.
    return $class -> SUPER::_to_base(@_) if @_ == 3;

    # If base > 36, pass everything to parent.
    my $str   = $_[0];
    my $base  = $_[1];
    $base = $class -> _new($base) unless ref($base);
    if ($class -> _acmp($base, $class -> _new("36")) > 0) {
        return $class -> SUPER::_to_base($str, $base);
    } else {
        return uc Rmpz_get_str($str, $base);
    }
}

sub _num {
    0 + Rmpz_get_str($_[1], 10);
}

sub _copy { Rmpz_init_set($_[1]); }

sub _len {
    length Rmpz_get_str($_[1], 10);
}

sub _zeros {
    return 0 unless Rmpz_cmp($_[1], $zero);     # 0 has no trailing zeros
    my $str = Rmpz_get_str($_[1], 10);
    $str =~ /(0*)\z/;
    return length($1);
}

sub _digit {
    substr(Rmpz_get_str($_[1], 10), -($_[2]+1), 1);
    #if ($_[2] >= 0) {
    #    return( ($_[1] / (10 ** $_[2])) % 10);
    #} else {
    #    substr(Rmpz_get_str($_[1], 10), -($_[2]+1), 1);
    #}
}

sub _check {
    my ($class, $x) = @_;
    return "Undefined" unless defined $x;
    return "$x is not a reference to Math::GMPz"
      unless ref($x) eq 'Math::GMPz';
    return 0;
}

sub _nok {
    my ($class, $n, $k) = @_;

    # If k > n/2, use the fact that binomial(n, k) = binomial(n, n-k). To avoid
    # division, don't test k > n/2, but rather 2*k > n.

    {
        my $twok = Rmpz_init();         #
        Rmpz_mul_2exp($twok, $k, 1);    # $twok  = 2 * $k
        if (Rmpz_cmp($twok, $n) > 0) {  # if 2*k > n
            $k = Rmpz_init_set($k);     #    copy k
            Rmpz_sub($k, $n, $k);       #    k = n - k
        }
    }

    Rmpz_bin_ui($n, $n, $k);
    return $n;
}

# XXX TODO: calc len in base 2 then appr. in base 10
sub _alen {
    Rmpz_sizeinbase($_[1], 10);
}

# _set() - set an already existing object to the given scalar value

sub _set {
    Rmpz_set($_[1], $_[2]);
    return $_[1];
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::GMPz - Use Math::GMPz for Math::BigInt routines

=head1 SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'GMPz';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'GMPz';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'GMPz';

=head1 DESCRIPTION

Math::BigInt::GMPz is a backend library for Math::BigInt, Math::BigFloat,
Math::BigRat and related modules. It is not indended to be used directly.

Math::BigInt::GMPz uses Math::GMPz objects for the calculations. Math::GMPz is
an XS layer on top of the very fast gmplib library. See https://gmplib.org/

Math::BigInt::GMPz inherits from Math::BigInt::Lib.

=head1 METHODS

The following methods are implemented.

=over

=item _new()

=item _zero()

=item _one()

=item _two()

=item _ten()

=item _from_bin()

=item _from_oct()

=item _from_hex()

=item _from_bytes()

=item _from_base()

=item _1ex()

=item _add()

=item _mul()

=item _div()

=item _sub()

=item _dec()

=item _inc()

=item _mod()

=item _sqrt()

=item _root()

=item _fac()

=item _dfac()

=item _pow()

=item _modinv()

=item _modpow()

=item _rsft()

=item _lsft()

=item _gcd()

=item _lcm()

=item _and()

=item _or()

=item _xor()

=item _is_zero()

=item _is_one()

=item _is_two()

=item _is_ten()

=item _is_even()

=item _is_odd()

=item _acmp()

=item _str()

=item _as_bin()

=item _as_oct()

=item _as_hex()

=item _to_bin()

=item _to_oct()

=item _to_hex()

=item _to_bytes()

=item _to_base()

=item _num()

=item _copy()

=item _len()

=item _zeros()

=item _digit()

=item _check()

=item _nok()

=item _alen()

=item _set()

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-gmpz at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMPz>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::GMPz

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-GMPz>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigInt-GMPz>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-GMPz>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-GMPz/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-GMPz>

=item * The Bignum mailing list

=over 4

=item * Post to mailing list

C<bignum at lists.scsys.co.uk>

=item * View mailing list

L<http://lists.scsys.co.uk/pipermail/bignum/>

=item * Subscribe/Unsubscribe

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/bignum>

=back

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam@gmail.comE<gt>

L<Math::GMPz> was written by Sisyphus Sisyphus
E<lt>sisyphus at(@) cpan dot (.) orgE<gt>

=head1 SEE ALSO

End user libraries L<Math::BigInt>, L<Math::BigFloat>, L<Math::BigRat>, as well
as L<bigint>, L<bigrat>, and L<bignum>.

Other backend libraries, e.g., L<Math::BigInt::Calc>,
L<Math::BigInt::FastCalc>, L<Math::BigInt::GMP>, and L<Math::BigInt::Pari>.

=cut
