# $Id: Makefile.am,v 1.12.2.2 2011/06/20 03:43:39 ak Exp $
# Copyright (C) 2013 azumakuniyuki
sysconf_DATA = authinfo-example haineko.cf-example \
			   mailertable-example recipients-example relayhosts-example \
			   sendermt-example
	
distdir = $(BUILDROOT)/dist/etc
instdir = @sysconfdir@

.PHONY: clean
all-am: distconf
distconf:
	test -d $(distdir) || mkdir -p $(distdir)
	for CF in $(sysconf_DATA); do \
		cp $$CF $(distdir)/$$CF; \
	done

install-am: distconf
	test -d $(instdir) || mkdir -p 0755 $(instdir)
	for CF in $(sysconf_DATA); do \
		test -f $(instdir)/$$CF || $(INSTALL) -m 0644 $(distdir)/$$CF $(instdir)/ ;\
	done

clean-am:
	:

