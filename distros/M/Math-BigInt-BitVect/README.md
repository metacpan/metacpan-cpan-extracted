# NAME

Math::BigInt::BitVect - a math backend library based on Bit::Vector

# SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'BitVect';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'BitVect';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'BitVect';

## DESCRIPTION

Provides support for big integer calculations via Bit::Vector, a fast C library
by Steffen Beier.

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint-bitvect at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-BitVect](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-BitVect)
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

# SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc Math::BigInt::BitVect

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt-BitVect](https://github.com/pjacklam/p5-Math-BigInt-BitVect)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-BitVect](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-BitVect)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt-BitVect](https://metacpan.org/release/Math-BigInt-BitVect)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-BitVect](http://matrix.cpantesters.org/?dist=Math-BigInt-BitVect)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt-BitVect](https://cpanratings.perl.org/dist/Math-BigInt-BitVect)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHORS

(c) 2001, 2002, 2003, 2004 by Tels http://bloodgate.com

Maintained by Peter John Acklam <pjacklam@gmail.com>, 2016-2021

The module Bit::Vector is (c) by Steffen Beyer. Thanx!

# SEE ALSO

[Math::BigInt::Lib](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ALib) for a description of the API.

Alternative backend libraries [Math::BigInt::Calc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ACalc), [Math::BigInt::FastCalc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AFastCalc),
[Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP), and [Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari).

The modules that use these libraries [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt), [Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat), and
[Math::BigRat](https://metacpan.org/pod/Math%3A%3ABigRat).
