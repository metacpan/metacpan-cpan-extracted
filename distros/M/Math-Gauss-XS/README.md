# NAME

Math::Gauss - Gaussian distribution function and its inverse, fast XS version

[![Build Status](https://travis-ci.org/binary-com/perl-Math-Gauss-XS.svg?branch=master)](https://travis-ci.org/binary-com/perl-Math-Gauss-XS)
[![codecov](https://codecov.io/gh/binary-com/perl-Math-Gauss-XS/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Math-Gauss-XS)

# VERSION

0.01

# STATUS

# SYNOPSIS

    use Math::Gauss::XS ':all';

    $p = pdf( $z );
    $p = pdf( $x, $m, $s );

    $c = cdf( $z );
    $c = cdf( $x, $m, $s );

    $z = inv_cdf( $z );

# DESCRIPTION

This module just rewrites the [Math::Gauss](https://metacpan.org/pod/Math::Gauss) module in XS. The precision and
exported function remain the same as in the original.

The benchmark results are

    Benchmark: timing 30000000 iterations of pp/pdf, xs/pdf...
       pp/pdf: 15 wallclock secs (14.99 usr +  0.00 sys = 14.99 CPU) @ 2001334.22/s (n=30000000)
       xs/pdf:  2 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 13888888.89/s (n=30000000)
    Benchmark: timing 30000000 iterations of pp/cdf, xs/cdf...
       pp/cdf: 40 wallclock secs (38.93 usr +  0.00 sys = 38.93 CPU) @ 770613.92/s (n=30000000)
       xs/cdf:  2 wallclock secs ( 2.22 usr +  0.00 sys =  2.22 CPU) @ 13513513.51/s (n=30000000)
    Benchmark: timing 30000000 iterations of pp/inv_cdf, xs/inv_cdf...
    pp/inv_cdf: 15 wallclock secs (16.02 usr +  0.00 sys = 16.02 CPU) @ 1872659.18/s (n=30000000)
    xs/inv_cdf:  2 wallclock secs ( 2.18 usr +  0.00 sys =  2.18 CPU) @ 13761467.89/s (n=30000000)

# SOURCE CODE

[GitHub](https://github.com/binary-com/perl-Math-Gauss-XS)

# AUTHOR

binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/binary-com/perl-Math-Gauss-XS/issues](https://github.com/binary-com/perl-Math-Gauss-XS/issues).

# LICENSE AND COPYRIGHT

Copyright (C) 2016 binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
