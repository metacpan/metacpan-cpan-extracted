# Math::MatrixLUP

Math::MatrixLUP - Matrix operations and LUP decomposition.

## DESCRIPTION

[Math::MatrixLUP](https://metacpan.org/pod/Math::MatrixLUP) provides generic support for matrix operations and LUP decomposition, allowing any type of numbers inside the matrix, including native Perl numbers and numerical objects provided by other mathematical libraries, such as [Math::AnyNum](https://metacpan.org/pod/Math::AnyNum).

The supported matrix operations are:

* matrix multiplication
* matrix exponentiation
* matrix-scalar arithmetical operations
* determinant of a square-matrix
* inversion of a square-matrix
* solving a system of linear equations

## SYNOPSIS

```perl
use Math::MatrixLUP;

my $A = Math::MatrixLUP->new([
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
]);

my $det = $A->determinant;
my $sol = $A->solve([-3, -32, -47, 49]);
my $inv = $A->invert;
my $exp = $A->pow(3);
```

# INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

# METACPAN

https://metacpan.org/pod/Math::MatrixLUP

# LICENSE AND COPYRIGHT

Copyright (C) 2019 Daniel "Trizen" Șuteu

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
