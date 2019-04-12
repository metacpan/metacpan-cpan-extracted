# Math-ContinuedFraction

## Version 0.14

## 10 April 2019

Create and manipulate continued fractions in perl.

This module is in an alpha state. Method names and parameters
may change in the next release, aside from the methods "new()",
"from_ratio()", "from_root()". Fortunately, there aren't many
other methods beyond that.

Although the module uses Math::BigInt and Math::BigRat modules,
the internal calculations to create the continued fraction are
handled with perl's regular scalars. So far this hasn't been
a problem for the creation, and the convergent method does use
BigInts, so we're okay.

## INSTALLATION

If you are not using the cpan or cpanm commands, nor using Activestate's PPM,
install this module by running the following commands:

```sh
perl Build.PL
./Build
./Build test
./Build install
```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc or man command, depending upon your system.

You can also look for information at:

[The module's Github repository](https://github.com/jgamble/Math-ContinuedFraction)

[MetaCPAN](https://metacpan.org/release/Math-ContinuedFraction)

[RT, CPAN's request tracker (report bugs here)](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-ContinuedFraction)


## COPYRIGHT AND LICENSE

Copyright (C) 2019 John M. Gamble. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

See [the list of licencses](http://dev.perl.org/licenses) for more information.

