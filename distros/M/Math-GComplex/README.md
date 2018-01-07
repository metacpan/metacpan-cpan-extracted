# Math::GComplex

A generic complex number library for Perl 5.

# DESCRIPTION

Math::GComplex provides a generic interface to complex number operations, accepting any type of number as a component of a complex number, including native Perl numbers and numerical objects provided by other mathematical libraries, such as [Math::AnyNum](https://metacpan.org/release/Math-AnyNum).

# SYNOPSIS

```perl
use 5.010;
use Math::GComplex;
use Math::AnyNum qw(:overload);

my $x = Math::GComplex->new(3, 4);
my $y = Math::GComplex->new(7, 5);

say $x + $y;        #=> (10 9)
say $x - $y;        #=> (-4 -1)
say $x * $y;        #=> (1 43)
say $x / $y;        #=> (41/74 13/74)
```

# INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Math::GComplex

You can also look for information at:

* Github
    - https://github.com/trizen/Math-GComplex

* AnnoCPAN, Annotated CPAN documentation
    - http://annocpan.org/dist/Math-GComplex

* CPAN Ratings
    - http://cpanratings.perl.org/d/Math-GComplex

* Search CPAN
    - http://search.cpan.org/dist/Math-GComplex/

# LICENSE AND COPYRIGHT

Copyright (C) 2018 Daniel "Trizen" Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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
