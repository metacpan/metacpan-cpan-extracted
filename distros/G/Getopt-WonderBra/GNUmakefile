all::

ifeq ($(wildcard Makefile),)
all:: Makefile

Makefile: Makefile.PL
	perl Makefile.PL
	test -e Makefile

else
include Makefile
endif

dist: manifest
