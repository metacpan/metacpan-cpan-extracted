# $Id: Makefile.am,v 1.3.2.1 2011/06/20 03:43:39 ak Exp $
# Copyright (C) 2013 azumakuniyuki
SUBDIRS = Haineko
modules = Haineko.pm
distdir = $(BUILDROOT)/dist/lib
instdir = @prefix@/lib

.PHONY: clean
all-am: distlib
distlib:
	test -d $(distdir) || mkdir -p $(distdir)
	cp $(modules) $(distdir)/$(modules)

install-am: distlib
	test -d $(instdir) || mkdir -p $(instdir)
	$(INSTALL) -c -m 0644 $(distdir)/$(modules) $(instdir)/

uninstall-am:
	rm -f $(instdir)/$(modules)

clean-am:
	:


