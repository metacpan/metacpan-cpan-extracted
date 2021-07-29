# NAME

Math::BigInt::Lite - What Math::BigInts are before they become big

# SYNOPSIS

    use Math::BigInt::Lite;

    my $x = Math::BigInt::Lite->new(1);

    print $x->bstr(), "\n";                     # 1
    $x = Math::BigInt::Lite->new('1e1234');
    print $x->bsstr(), "\n";                    # 1e1234 (silently upgrades to
                                                # Math::BigInt)

# DESCRIPTION

Math::BigInt is not very good suited to work with small (read: typical
less than 10 digits) numbers, since it has a quite high per-operation overhead
and is thus much slower than normal Perl for operations like:

    my $x = 1 + 2;                          # fast and correct
    my $x = 2 ** 256;                       # fast, but wrong

    my $x = Math::BigInt->new(1) + 2;       # slow, but correct
    my $x = Math::BigInt->new(2) ** 256;    # slow, and still correct

But for some applications, you want fast speed for small numbers without
the risk of overflowing.

This is were `Math::BigInt::Lite` comes into play.

Math::BigInt::Lite objects should behave in every way like Math::BigInt
objects, that is apart from the different label, you should not be able
to tell the difference. Since Math::BigInt::Lite is designed with speed in
mind, there are certain limitations build-in. In praxis, however, you will
not feel them, because everytime something gets to big to pass as Lite
(literally), it will upgrade the objects and operation in question to
Math::BigInt.

## Math library

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

    use Math::BigInt::Lite lib => 'Calc';

You can change this by using:

    use Math::BigInt::Lite lib => 'GMP';

The following would first try to find Math::BigInt::Foo, then
Math::BigInt::Bar, and when this also fails, revert to Math::BigInt::Calc:

    use Math::BigInt::Lite lib => 'Foo,Math::BigInt::Bar';

See the respective low-level math library documentation for further
details.

Please note that Math::BigInt::Lite does **not** use the denoted library itself,
but it merely passes the lib argument to Math::BigInt. So, instead of the need
to do:

    use Math::BigInt lib => 'GMP';
    use Math::BigInt::Lite;

you can roll it all into one line:

    use Math::BigInt::Lite lib => 'GMP';

Use the lib, Luke!

## Using Lite as substitute for Math::BigInt

The pragmas [bigrat](https://metacpan.org/pod/bigrat), [bignum](https://metacpan.org/pod/bignum) and [bigint](https://metacpan.org/pod/bigint) will automatically use
Math::BigInt::Lite whenever possible.

# METHODS

## new

    $x = Math::BigInt::Lite->new('1');

Create a new Math::BigInt:Lite object. When the input is not of an suitable
simple and small form, an object of the class of `$upgrade` (typically
Math::BigInt) will be returned.

All other methods from BigInt and BigFloat should work as expected.

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Lite](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Lite)
(requires login).
We will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Lite

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt](https://github.com/pjacklam/p5-Math-BigInt)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt](https://metacpan.org/release/Math-BigInt)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt](http://matrix.cpantesters.org/?dist=Math-BigInt)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt](https://cpanratings.perl.org/dist/Math-BigInt)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

[Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat) and [Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt) as well as
[Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari) and [Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP).

The [bignum](https://metacpan.org/pod/bignum) module.

# AUTHORS

- Copyright 2002-2007 Tels, [http://bloodgate.com](http://bloodgate.com).
- Copyright 2010 Florian Ragwitz <flora@cpan.org>.
- Copyright 2016- Peter John Acklam <pjacklam@gmail.com>.
