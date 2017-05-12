DESCRIPTION

This is Exporter::VA - Improved Exporter featuring Versioning and Aliasing.

It provides for better exporting capabilities than the traditional Exporter module, including
	- Potential to have no globals.
	- Versioning, or different exports for different versions supported in the same file,
	- especially the ability to eliminate default exports and still maintain backward compatibility.
	- Export hard links or differently-named functions (or variables).
	- Pragmatic exports, with arguments.
	- Special features in import() argument list such as non-scalars.
	- Fully extensible framework for "exotic" import() needs.

The documentation is in the module's POD. 
More information about the module, whitepapers, etc. can be found on its home page, < http://jmd.perlmonk.org/Exporter-VA >.
The latest version can be found there, or on CPAN under < http://www.cpan.org/authors/id/D/DL/DLUGOSZ/ >.

The author hangs out on < http://www.perlmonks.org >, and entertains discussion or questions about the module
there.

Included is the utility Exporter::VA::Convert.perl which will generate Exporter::VA statements from the
equivilent classic Exporter usage.  See it's own POD for details.

COPYRIGHT

Copyright 2003 by John M. Dlugosz. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

PREREQUISITES

None.  This module is intentionaly designed to have no dependancies other than core modules that come
with Perl (e.g. strict, warnings, Carp).

BUILDING

N/A.  This is pure Perl, contained entirely in a .pm file.

INSTALLING

Installing is trivial -- just copy the .pm file to the Perl library tree.  
The ---> install.perl <--- program does this, and runs the unit/regression tests.

The program test1.perl runs a comprehensive unit test and regression test on the module.

You may verify that the module is genuine by checking the digital signatures in the *.sig files.  My master
PGP key has been on my page on www.perlmonks.org for years, and will be archived in various places.

HISTORY

October 2002 - preliminary documentation and design reviews

December 3, 2002 - Basic export works (see test1.perl).  Made available for peer review of code.

v1.0 on December 10, 2002 -
Stable and fairly clean, with unit tests.  Supports everything except version lists.

December 19, 2002 - v1.1 - redid the way VERSION works.
Bug fix: the tag list definition was being eaten.  Exporting the same module again would see it empty!
version-list in export def (but not in tag list) works.

December 22, 2002 - work on VERSION function and docs, version checking, version support routines.
Implement version-list in tag list.

December 23, 2002 - review docs, produce 'issues' list, make install.perl.

v1.2 released.  Supports everything except non-imported alias suite of features.

January 6, 2003 - Exporter-VA-Convert.perl utility, release procedure.

January 9, 2003 - 
	if .default_VERSION left out, assumes current $VERSION.
	installer runs unit tests, rolls back on failure.
	test1.perl has --quiet mode.
	put in more unit testing code.

v1.2.2 released.

January 11, 2003 -
	Installer updates ActivePerl's documentation tree and TOC.
	use utf8;
	implement normalize_vstring, allow it as an export (but not yet in the POD)
	
January 12, 2003 -
	Get standard Makefile.PL to work for test and install, rename files and move test code to t subdir.

v1.2.3 released.

January 13, 2003 -
	implement .allowed_VERSIONS.
	implement one-shot behavior of verbose importing.
	implement warning on importing a symbol beginning with an underscore

January 14, 2003 -
	fix and change to VERSION
	eliminate (set_)client_desired_version

January xx -
	eliminate other items from TODO list
	update POD documentation
	implement "warnings"

January 22, 2003 -
	complete implementation if AUTOLOAD and autoload_symbol features

v1.3 released.

v1.3.0.1 : validated on Perl 5.8, removed stray debug print.


