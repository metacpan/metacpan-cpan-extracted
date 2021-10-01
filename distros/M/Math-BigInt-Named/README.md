# NAME

Math::BigInt::Named - Math::BigInt objects that know their name in some languages

# SYNOPSIS

    use Math::BigInt::Named;

    $x = Math::BigInt::Named->new("123");

    print $x->name(),"\n";                      # default is english
    print $x->name( language => 'de' ),"\n";    # but German is possible
    print $x->name( language => 'German' ),"\n";        # like this
    print $x->name( { language => 'en' } ),"\n";        # this works, too

    print Math::BigInt::Named->from_name("einhundert dreiundzwanzig"),"\n";

# DESCRIPTION

This is a subclass of Math::BigInt and adds support for named numbers.

# METHODS

## name()

    print Math::BigInt::Named->name( 123 );

Convert a Math::BigInt to a name.

## from\_name()

    my $bigint = Math::BigInt::Named->from_name('hundertzwanzig');

Create a Math::BigInt::Named from a name string. **Not yet implemented!**

# BUGS

Please report any bugs or feature requests to
`bug-math-bigint-named at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Named](https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Named)
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Named

You can also look for information at:

- GitHub

    [https://github.com/pjacklam/p5-Math-BigInt-Named](https://github.com/pjacklam/p5-Math-BigInt-Named)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-Named](https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-Named)

- MetaCPAN

    [https://metacpan.org/release/Math-BigInt-Named](https://metacpan.org/release/Math-BigInt-Named)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-BigInt-Named](http://matrix.cpantesters.org/?dist=Math-BigInt-Named)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-BigInt-Named](https://cpanratings.perl.org/dist/Math-BigInt-Named)

# LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

[Math::BigInt](https://metacpan.org/pod/Math%3A%3ABigInt) and [Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat).

# AUTHORS

- (C) by Tels http://bloodgate.com in late 2001, early 2002, 2007.
- Maintainted by Peter John Acklam <pjacklam@gmail.com>, 2016-.
- Based on work by Chris London Noll.
