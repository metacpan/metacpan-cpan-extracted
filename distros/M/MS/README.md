MS - Core libraries for mass spectrometry
====

[![Build Status](https://travis-ci.org/jvolkening/p5-MS.svg?branch=master)](https://travis-ci.org/jvolkening/p5-MS)
[![Coverage Status](https://coveralls.io/repos/github/jvolkening/p5-MS/badge.svg?branch=master)](https://coveralls.io/github/jvolkening/p5-MS?branch=master)
[![CPAN version](https://badge.fury.io/pl/MS.svg)](https://badge.fury.io/pl/MS)

DESCRIPTION
-----------

The `MS::` namespace is intended as a hub for mass spectrometry-related
development in Perl. This core package includes a number of parsers for HUPO
PSI standards and other common file formats, as well as core functionality for
mass spectrometry and proteomics work. Developers are encouraged to put their
work under the `MS::` namespace. The following namespace hierarchy is
suggested:

- `MS::Reader::` — format-specific file readers/parsers 
- `MS::Writer::` — format-specific file writers/formatters
- `MS::Search::` — search-related modules (front-ends, etc)
- `MS::Algo::` — algorithm implementations (prototyping, etc)

# AUTHOR

Jeremy Volkening

# COPYRIGHT AND LICENSE

Copyright 2015-2022 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see &lt;http://www.gnu.org/licenses/>.
