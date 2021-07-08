# NAME

Math::BigInt::GMP - backend library for Math::BigInt etc. based on GMP

# SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'GMP';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'GMP';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'GMP';

# DESCRIPTION

Math::BigInt::GMP is a backend library for Math::BigInt, Math::BigFloat,
Math::BigRat and related modules.

Math::BigInt::GMP provides support for big integer calculations by means of the
GMP C library. See [https://gmplib.org/](https://gmplib.org/) for more information about the GMP
library.

Math::BigInt::GMP no longer uses Math::GMP, but provides its own XS layer to
access the GMP C library. This cuts out another (Perl subroutine) layer and
also reduces the memory footprint.

Math::BigInt::GMP inherits from Math::BigInt::Lib.

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint-gmp at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMP](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-GMP)
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

# SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc Math::BigInt::GMP

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt-GMP](https://github.com/pjacklam/p5-Math-BigInt-GMP)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-GMP](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-GMP)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt-GMP](https://metacpan.org/release/Math-BigInt-GMP)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-GMP](http://matrix.cpantesters.org/?dist=Math-BigInt-GMP)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt-GMP](https://cpanratings.perl.org/dist/Math-BigInt-GMP)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Tels &lt;http://bloodgate.com/> in 2001-2007.

Thanks to Chip Turner (CHIPT on CPAN) for providing Math::GMP, which was
inspiring my work.

Maintained by Peter John Acklam <pjacklam@gmail.com> 2010-2021.

# SEE ALSO

[Math::BigInt::Lib](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ALib) for a description of the API.

Alternative libraries [Math::BigInt::Calc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ACalc), [Math::BigInt::FastCalc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AFastCalc), and
[Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari).

Some of the modules that use these libraries [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt),
[Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat), and [Math::BigRat](https://metacpan.org/pod/Math%3A%3ABigRat).
