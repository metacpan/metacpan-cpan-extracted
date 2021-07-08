# NAME

Math::BigInt::GMPz - a math backend library based on Math::GMPz

# SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'GMPz';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'GMPz';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'GMPz';

# DESCRIPTION

Math::BigInt::GMPz is a backend library for Math::BigInt, Math::BigFloat,
Math::BigRat and related modules. It is not indended to be used directly.

Math::BigInt::GMPz uses Math::GMPz objects for the calculations. Math::GMPz is
an XS layer on top of the very fast gmplib library. See https://gmplib.org/

Math::BigInt::GMPz inherits from Math::BigInt::Lib.

# METHODS

The following methods are implemented.

- \_new()
- \_zero()
- \_one()
- \_two()
- \_ten()
- \_from\_bin()
- \_from\_oct()
- \_from\_hex()
- \_from\_bytes()
- \_from\_base()
- \_1ex()
- \_add()
- \_mul()
- \_div()
- \_sub()
- \_dec()
- \_inc()
- \_mod()
- \_sqrt()
- \_root()
- \_fac()
- \_dfac()
- \_pow()
- \_modinv()
- \_modpow()
- \_rsft()
- \_lsft()
- \_gcd()
- \_lcm()
- \_and()
- \_or()
- \_xor()
- \_is\_zero()
- \_is\_one()
- \_is\_two()
- \_is\_ten()
- \_is\_even()
- \_is\_odd()
- \_acmp()
- \_str()
- \_as\_bin()
- \_as\_oct()
- \_as\_hex()
- \_to\_bin()
- \_to\_oct()
- \_to\_hex()
- \_to\_bytes()
- \_to\_base()
- \_num()
- \_copy()
- \_len()
- \_zeros()
- \_digit()
- \_check()
- \_nok()
- \_fib()
- \_lucas()
- \_alen()
- \_set()

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint-gmpz at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMPz](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMPz)
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

# SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc Math::BigInt::GMPz

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt-GMPz](https://github.com/pjacklam/p5-Math-BigInt-GMPz)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-GMPz](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-GMPz)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt-GMPz](https://metacpan.org/release/Math-BigInt-GMPz)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-GMPz](http://matrix.cpantesters.org/?dist=Math-BigInt-GMPz)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt-GMPz](https://cpanratings.perl.org/dist/Math-BigInt-GMPz)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Peter John Acklam <pjacklam@gmail.com>

[Math::GMPz](https://metacpan.org/pod/Math%3A%3AGMPz) was written by Sisyphus Sisyphus
&lt;sisyphus at(@) cpan dot (.) org>

# SEE ALSO

End user libraries [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt), [Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat), [Math::BigRat](https://metacpan.org/pod/Math%3A%3ABigRat), as well
as [bigint](https://metacpan.org/pod/bigint), [bigrat](https://metacpan.org/pod/bigrat), and [bignum](https://metacpan.org/pod/bignum).

Other backend libraries, e.g., [Math::BigInt::Calc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ACalc),
[Math::BigInt::FastCalc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AFastCalc), [Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP), and [Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari).
