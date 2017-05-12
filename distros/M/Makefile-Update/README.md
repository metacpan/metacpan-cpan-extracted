Upmake
======

[![Build Status](https://travis-ci.org/vadz/upmake.png?branch=master)](https://travis-ci.org/vadz/upmake) [![Coverage Status](https://coveralls.io/repos/vadz/upmake/badge.png?branch=master)](https://coveralls.io/r/vadz/upmake?branch=master)

Pragmatic way to manage build system for cross-platform applications: update
the lists of source and header files in all the make and project files at
once.


Installation
------------

Upmake is a Perl module with no non-core dependencies and can be installed by
running the following commands:

	perl Makefile.PL
	make install

It can also be installed from [CPAN](https://metacpan.org/) in the usual way.

Alternatively, you can [download a single file](http://www.tt-solutions.com/downloads/upmake)
containing the latest version of the command line script with all its
dependencies, but this won't allow you to use its functionality
programmatically which is usually required for non-trivial projects.
Notice that you still need to have Perl (5.10+) to run this file.


Usage
-----

For the simplest possible case, e.g. if starting a new project, create the
master files list `files` with the following contents:

	# Comments are allowed, everything else should consist of variable
	# definitions in the very simple format below:
	sources =
		first_source_file.cpp
		another_source_file.cpp
		and_so_on.cpp

	headers =
		first_header.hpp
		last_header.hpp

If you use a makefile for building your project under Unix systems, define the
variable called either `sources` or `objects` in it, e.g.

	# GNUmakefile
	objects := \
			first_source_file.o

Running

	upmake GNUmakefile

will now update `GNUmakefile` to contain all the files from the master list
(with the correct `.o` extension).

Of course, this is not any better than just maintaining the list of files in
the makefile directly, but the advantage of `upmake` is that you can also
update MSVC project files from the same master list, just do

	upmake my.vcxproj # or .vcproj for older versions

If you don't have committed or backed up versions of the files, it is
*strongly* recommended to use `--dry-run --verbose` options to check that the
modifications conform to your expectations before actually making them.

Generally speaking, any variables or targets defined in the makefile will be
updated with the values of the variables with the corresponding names from the
master file (and if there is no corresponding variable, nothing is done). As
for project files, variables `proj_sources`, `proj` and `sources` where `proj`
is the base name of the project are used by default in this order, i.e. the
first one found is used (for the headers, only `proj_headers` and `headers`
are checked).

A common situation is that an existing makefile uses several variables, e.g.
`sources_foo` and `sources_bar`, while a single variable containing all the
sources is needed for the project file. This can be resolved by defining such
variable in terms of other existing ones:

	proj_sources =
		$sources_foo
		$sources_bar

For yet more complicated cases you may use the module programmatically, see
e.g. [this example](https://github.com/wxWidgets/wxWidgets/blob/master/build/upmake).


Licence
-------

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

- the GNU General Public License as published by the Free Software Foundation;
  either version 1, or (at your option) any later version, or
- the "Artistic License"
