File-Replace-Inplace
====================

This is the distribution of the Perl module
[`File::Replace::Inplace`](https://metacpan.org/pod/File::Replace::Inplace).

It is a Perl extension that provides a replacement for Perl's inplace editing
of files (`-i`) using `File::Replace`.

Please see the module's documentation (POD) for details (try the command
`perldoc lib/File/Replace/Inplace.pm`) and the file `Changes` for version
information.

[![Kwalitee Score](https://cpants.cpanauthors.org/dist/File-Replace-Inplace.svg)](https://cpants.cpanauthors.org/dist/File-Replace-Inplace)
[![CPAN Testers](https://badges.zero-g.net/cpantesters/File-Replace-Inplace.svg)](http://matrix.cpantesters.org/?dist=File-Replace-Inplace)

Installation
------------

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`, or `gmake`
instead of `make`.

Dependencies
------------

Requirements: Perl v5.8.1 or higher (a more current version is *strongly*
recommended) and several of its core modules; users of older Perls may need
to upgrade some core modules.

Since this is an extension to `File::Replace`, that module is required.

The full list of required modules can be found in the file `Makefile.PL`.
This module should work on any platform supported by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2017-2023 Hauke Daempfling <haukex@zero-g.net>
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

