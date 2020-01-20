# Grep::Query 1.010

This module implements a limited query language for logical expressions
(AND, OR, NOT, parenthesized, ...etc) and apply it to lists of data for
selecting a subset, similar to using "grep" with a block/regexp in the code.

A reason for not using grep with a regular code block directly is that the
original impetus for its existence was to allow a user running a command-line
tool to submit an arbitrary query for a list the tool had somehow generated
(e.g. a list of file names).

The initial approach of having the user pass individual regexes for doing
"include/exclude" operations proved to be too limiting if the selection
criteria became more complex. Hence the notion of a query language that
makes it possible to express more complex combinations of regexes was born.  

Matching can be most readily done on plain lists of scalar strings/values,
but by providing a 'field accessor', matching can be done against lists of
arbitrary objects/hashes using all possible data they contain, including
doing both string (regexes, eq/ne/gt/ge/lt/le) as well as numerical
(==/!=/>/>=/</<=) comparisons.

Arguably, it may be seen as a 'grep' on steroids :-).

### INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Grep::Query

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Grep-Query

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Grep-Query

    CPAN Ratings
        http://cpanratings.perl.org/d/Grep-Query

    Search CPAN
        http://metacpan.org/dist/Grep-Query/

##### LICENSE AND COPYRIGHT

Copyright (C) 2016 Kenneth Olwing

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
