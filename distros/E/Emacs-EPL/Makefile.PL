# Makefile generator for EPL.
# Usage: perl Makefile.PL

# Copyright (C) 2001 by John Tobey,
# jtobey@john-edwin-tobey.org.  All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to the
#   Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#   MA 02111-1307  USA

use ExtUtils::MakeMaker;

my $version = get_version_from_el ();
my $doc_edition = 0.2;

if ($ARGV[0] eq 'print_package_version') {
    print $version;
    exit;
}

if ($ARGV[0] eq 'write_version_texi') {
    open (VERSION, ">doc/version.texi")
	|| die ("Can't write doc/version.texi: $!");
    print VERSION "\@c !!! THIS IS A GENERATED FILE !!!\n";
    print VERSION "\@c !!! DO NOT UPDATE THIS FILE !!!\n";
    print VERSION "\@c !!! UPDATE $0 INSTEAD !!!\n";
    my ($day, $mon, $year) = ((localtime ((stat "doc/epl.texi")[9]))[3, 4, 5]);
    printf VERSION "\@set UPDATED %d %s %d\n", $day,
	(qw(January February March April May June July
	   August September October November December))[$month], $year + 1900;
    print VERSION "\@set EDITION $doc_edition\n";
    print VERSION "\@set VERSION $version\n";
    close (VERSION);
    exit;
}

WriteMakefile (
	       'NAME'  => 'Emacs::EPL',
	       'VERSION' => $version,
	      );

warn ("Note: You need GNU Emacs 20 to run the test suite.\n");
exit;


sub get_version_from_el {
    open (EL, "lisp/epl.el") || die ("Can't read lisp/epl.el: $!");
    while (<EL>) {
	return $1 if /^\(defconst epl-version "(.*?)"/;
    }
    die ("epl-version not defined in lisp/epl.el");
}

sub MY::postamble {
    return q(
TEXI_FILES = doc/epl.texi doc/fdl.texi doc/version.texi

doc/epl.info: $(TEXI_FILES)
	makeinfo -I doc -o $@ doc/epl.texi

doc/epl.html: $(TEXI_FILES)
	makeinfo -I doc --html -o $@ doc/epl.texi

# For this job, any perl will do.
doc/version.texi: Makefile.PL lisp/epl.el
	perl Makefile.PL write_version_texi

all:: doc/epl.info doc/epl.html

clean::
	cd doc; rm -f *.aux *.cp *.dvi *.fn *.ky *.log *.pg *.toc *.tp *.vr

maintainer-clean:: realclean
	rm -f doc/version.texi
	rm -f doc/*.html doc/*.info*

# Building XEmacs packages.  This has to happen in the xemacs-packages
# CVS tree.  See xemacs/Makefile.

IN_XEMACS_TREE = test -f ../../XEmacs.rules

srckit: dist

binkit:
	$(IN_XEMACS_TREE)
	$(MAKE) -f xemacs/Makefile $@

clean::
	if $(IN_XEMACS_TREE); then $(MAKE) -f xemacs/Makefile $@; fi

realclean::
	if $(IN_XEMACS_TREE); then $(MAKE) -f xemacs/Makefile distclean; fi
)
}
