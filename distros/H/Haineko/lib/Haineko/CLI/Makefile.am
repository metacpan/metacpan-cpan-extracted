# $Id: Makefile.am,v 1.20.2.1 2011/06/20 03:43:39 ak Exp $
# Copyright (C) 2013 azumakuniyuki
SUBDIRS = Setup
distdir = $(BUILDROOT)/dist/lib/Haineko/CLI
instdir = @libdir@/Haineko/CLI
pkgdatadir = @libdir@/Haineko/CLI
pkgdata_DATA = Daemon.pm Setup.pm Help.pm Password.pm

.PHONY: clean
all-am:
	test -d $(distdir) || mkdir -p $(distdir)
	cp -Rp $(pkgdata_DATA) $(distdir)/

install-am:
	test -d $(instdir) || mkdir -p $(instdir)
	test -d $(pkgdatadir) || mkdir -p $(pkgdatadir)
	for P in $(pkgdata_DATA) ; do \
		$(INSTALL) -c -m 0644 $(distdir)/$$P $(pkgdatadir)/ ;\
	done

uninstall-am:
	rm -f $(pkgdatadir)/*.pm 2> /dev/null

clean-am:
	:


