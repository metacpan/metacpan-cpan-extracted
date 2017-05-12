ifeq ($(wildcard Makefile),)
$(sort $(MAKECMDGOALS) all): Makefile
	make $(MAKECMDGOALS)

Makefile: Makefile.PL lib/Gentoo/Probe.pm
	rm -f Makefile
	-perl Makefile.PL
	test -e Makefile
else
include Makefile
endif


distcheck skipcheck create_distdir ci distmeta distsignature: MANIFEST

MANIFEST: manifest
