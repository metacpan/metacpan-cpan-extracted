# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

require 5.005;
use ExtUtils::MakeMaker;
use Carp;
use Config;

sub MY::postamble {
    q{
INSTALLLIB = $(PERLPREFIX)/lib

install::
	cp project_dir.mk $(INSTALLLIB)

DIST_DEFAULT += manifest

README: Project.pm
	-$(RM_RF) $@
	pod2text --loose $< > $@

dist: distcheck README

## Maintainer use:
preexist:
	svnorcvs nexists $(DISTNAME)_$(VERSION_SYM)
	test -s README

tag:
	svnorcvs tag  $(DISTNAME)_$(VERSION_SYM)

maintainer-diff:
	svnorcvs diff $(DISTNAME)_$(VERSION_SYM)

maintainer-dist: preexist dist tag
	svnorcvs release $(DISTVNAME).tar.gz

maintainer-clean: distclean
	-$(RM_RF) README

maintainer-copy: README

clean::
	-$(RM_RF) test_dir
};
}

if ($Config{osname} =~ /MSWin/) {
    die "%Error: The Module::LocalBuild package does not yet support MSWindows.  Use Cygwin instead.\n";
}

WriteMakefile(
	      DISTNAME  => 'Dir-Project',
	      NAME      => 'Dir::Project',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'Determine utility paths relative to version controlled directories',
	      VERSION_FROM => 'Project.pm',
	      EXE_FILES => ['project_dir', 'project_bin',],
	      PREREQ_PM => {'Pod::Usage' => 0,
			},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz',
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

