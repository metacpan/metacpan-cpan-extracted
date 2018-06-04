**Memoize-HashKey-Ignore**

Memoize-HashKey-Ignore helps you to ignore certain keys to store in Memoize.

Sometimes you don't want to store certain keys. You know what the values looks likes, but you can't easily write memoize function which culls them itself.

Memoize::HashKey::Ignore allows you to supply a code reference which describes, which keys should not be stored in Memoization Cache.

This module will allow you to memoize the entire function with splitting it into cached and uncached pieces.

[![Build Status](https://travis-ci.org/binary-com/perl-Memoize-HashKey-Ignore.svg?branch=master)](https://travis-ci.org/binary-com/perl-Memoize-HashKey-Ignore)
[![codecov](https://codecov.io/gh/binary-com/perl-Memoize-HashKey-Ignore/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Memoize-HashKey-Ignore)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-Memoize-HashKey-Ignore.png)](https://gitter.im/binary-com/perl-Memoize-HashKey-Ignore)

SYNOPSIS

    use Memoize;

    tie my %scalar_cache = 'Memoize::HashKey::Ignore', IGNORE => sub { my $key = shift, return ($key eq 'BROKENKEY') ? 1 : 0; };
    tie my %list_cache   = 'Memoize::HashKey::Ignore', IGNORE => sub { my $key = shift, return ($key eq 'BROKENKEY') ? 1 : 0; };

    memoize('function', SCALAR_CACHE => [ HASH => \%scalar_cache ], LIST_CACHE => [ HASH => \%list_cache ]);


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Memoize::HashKey::Ignore

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memoize-HashKey-Ignore

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Memoize-HashKey-Ignore

    CPAN Ratings
        http://cpanratings.perl.org/d/Memoize-HashKey-Ignore

    Search CPAN
        http://search.cpan.org/dist/Memoize-HashKey-Ignore/


LICENSE AND COPYRIGHT

Copyright (C) 2014 binary.com

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

