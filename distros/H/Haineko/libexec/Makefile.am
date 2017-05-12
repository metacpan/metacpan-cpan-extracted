# $Id: Makefile.am,v 1.6.2.3 2011/06/20 03:43:39 ak Exp $
# Copyright (C) 2013 azumakuniyuki
libexec_SCRIPTS = haineko.psgi
distdir = $(BUILDROOT)/dist/libexec
instdir = @libexecdir@

.PHONY: clean
all-am:
	test -d $(distdir) || mkdir -p $(distdir)
	cp $(libexec_SCRIPTS) $(distdir)/

install-am:
	test -d $(instdir) || mkdir -p $(instdir)
	for P in $(libexec_SCRIPTS) ; do \
		$(INSTALL) -m 0755 $(distdir)/$$P $(instdir)/ ;\
	done

uninstall-am:
	for P in $(libexec_SCRIPTS) ; do \
		rm -f $(instdir)/$$P 2> /dev/null
	done

clean-am:
	:

