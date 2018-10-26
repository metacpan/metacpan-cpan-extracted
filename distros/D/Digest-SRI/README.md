Digest-SRI
==========

This is the distribution of the Perl module `Digest::SRI`.

It is a Perl extension for calculating and verifying Subresource
Integrity hashes. See <https://www.w3.org/TR/SRI/> for background.

Please see the module's documentation (POD) for details (try the
command `perldoc lib/Digest/SRI.pm`) and the file `Changes` for
version information.

Installation
------------

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`, 
or `gmake` instead of `make`.

Dependencies
------------

Requirements: Perl v5.6 or higher (a more current version is
*strongly* recommended) and several of its core modules; users of
older Perls may need to upgrade some core modules.

The full list of required modules can be found in the file
`Makefile.PL`. This module should work on any platform supported 
by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2018 Hauke Daempfling <haukex@zero-g.net>
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

