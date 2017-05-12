# Math-BigNum

Transparent interface to Math::GMPq, Math::GMPz and Math::MPFR.

# DESCRIPTION

Math::BigNum provides a correct, intuitive and transparent interface to the GMP and MPFR numerical libraries.

# SYNOPSIS

```perl
use 5.014;
use Math::BigNum qw(:constant);

# Big numbers
say ((100->fac + 1) / 2);
  # => 466631077219720763408496194281333502453579841321908107 \
  #    342964819476087999966149578044707319880782591431268489 \
  #    60413611879125592605458432000000000000000000000000.5

# Small numbers
say sqrt(1 / 100->fac);     # => 1.035137811175626471320494591657[...]e-79

# Rational numbers
my $x = 2/3;
say $x*3;                   # => 2
say 2/$x;                   # => 3
say $x->as_frac;            # => "2/3"

# Floating-point numbers
say "equal" if (1.1 + 2.2 == 3.3);     # => "equal"
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

    perldoc Math::BigNum

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-BigNum

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Math-BigNum

    CPAN Ratings
        http://cpanratings.perl.org/d/Math-BigNum

    Search CPAN
        http://search.cpan.org/dist/Math-BigNum/


# LICENSE AND COPYRIGHT

Copyright (C) 2016-2017 Daniel Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

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
