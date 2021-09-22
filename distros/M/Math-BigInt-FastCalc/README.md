# NAME

Math::BigInt::FastCalc - Math::BigInt::Calc with some XS for more speed

# SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'FastCalc';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'FastCalc';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'FastCalc';

# DESCRIPTION

Math::BigInt::FastCalc inherits from Math::BigInt::Calc.

Provides support for big integer calculations. Not intended to be used by
other modules. Other modules which sport the same functions can also be used
to support Math::BigInt, like [Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP) or [Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari).

In order to allow for multiple big integer libraries, Math::BigInt was
rewritten to use library modules for core math routines. Any module which
follows the same API as this can be used instead by using the following:

    use Math::BigInt lib => 'libname';

'libname' is either the long name ('Math::BigInt::Pari'), or only the short
version like 'Pari'. To use this library:

    use Math::BigInt lib => 'FastCalc';

The default behaviour is to chose the best internal representation of big
integers, but the base length used in the internal representation can be
specified explicitly. Note that this must be done before Math::BigInt is loaded.
For example,

    use Math::BigInt::FastCalc base_len => 3;
    use Math::BigInt lib => 'FastCalc';

# STORAGE

Math::BigInt::FastCalc works exactly like Math::BigInt::Calc. Numbers are
stored in decimal form chopped into parts.

# METHODS

The following functions are now implemented in FastCalc.xs:

    _is_odd         _is_even        _is_one         _is_zero
    _is_two         _is_ten
    _zero           _one            _two            _ten
    _acmp           _len
    _inc            _dec
    __strip_zeros   _copy

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint-fastcalc at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-FastCalc](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-FastCalc)
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

# SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc Math::BigInt::FastCalc

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt-FastCalc](https://github.com/pjacklam/p5-Math-BigInt-FastCalc)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-FastCalc](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-FastCalc)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt-FastCalc](https://metacpan.org/release/Math-BigInt-FastCalc)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-FastCalc](http://matrix.cpantesters.org/?dist=Math-BigInt-FastCalc)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt-FastCalc](https://cpanratings.perl.org/dist/Math-BigInt-FastCalc)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHORS

Original math code by Mark Biggar, rewritten by Tels [http://bloodgate.com/](http://bloodgate.com/)
in late 2000.

Separated from Math::BigInt and shaped API with the help of John Peacock.

Fixed, sped-up and enhanced by Tels http://bloodgate.com 2001-2003.
Further streamlining (api\_version 1 etc.) by Tels 2004-2007.

Maintained by Peter John Acklam <pjacklam@gmail.com> 2010-2021.

# SEE ALSO

[Math::BigInt::Lib](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ALib) for a description of the API.

Alternative libraries [Math::BigInt::Calc](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3ACalc), [Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP), and
[Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari).

Some of the modules that use these libraries [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt),
[Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat), and [Math::BigRat](https://metacpan.org/pod/Math%3A%3ABigRat).
