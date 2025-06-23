# Math::AnyNum

Arbitrary size precision for integers, rationals, floating-points and complex numbers.

# DESCRIPTION

[Math::AnyNum](https://metacpan.org/pod/Math::AnyNum) provides a correct, intuitive and transparent interface to the [GMP](https://gmplib.org/), [MPFR](http://www.mpfr.org/) and [MPC](http://www.multiprecision.org/) libraries, using [Math::GMPq](https://metacpan.org/release/Math-GMPq), [Math::GMPz](https://metacpan.org/release/Math-GMPz), [Math::MPFR](https://metacpan.org/release/Math-MPFR) and [Math::MPC](https://metacpan.org/release/Math-MPC).

# SYNOPSIS

```perl
use 5.014;
use Math::AnyNum qw(:overload factorial);

# Integers
say factorial(30);                            #=> 265252859812191058636308480000000

# Floating-point numbers
say sqrt(1 / factorial(100));                 #=> 1.0351378111756264713204945[...]e-79

# Rational numbers
my $x = 2/3;
say ($x * 3);                                 #=> 2
say (2 / $x);                                 #=> 3
say $x;                                       #=> 2/3

# Complex numbers
say 3 + 4*i;                                  #=> 3+4i
say sqrt(-4);                                 #=> 2i
say log(-1);                                  #=> 3.1415926535897932384626433832[...]i
```

# INSTALLATION

To install this module, run the following commands:

```console
perl Build.PL
./Build
./Build test
./Build install
```

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```console
perldoc Math::AnyNum
```

# LICENSE AND COPYRIGHT

Copyright (C) 2017-2025 by Daniel "Trizen" Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

https://www.perlfoundation.org/artistic-license-20.html

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
