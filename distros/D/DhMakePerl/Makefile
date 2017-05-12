#!/usr/bin/make -f

PERL ?= /usr/bin/perl

all: build

Build: Build.PL
	$(PERL) $<

build install test manifest distmeta: Build
	./Build $@

orig:
	[ ! -e debian/rules ] || $(MAKE) -f debian/rules clean
	$(MAKE) Build
	./Build $@

dist: manifest
	./Build $@

clean realclean distclean:
	[ ! -e Build ] || ./Build $@

.PHONY: all build install test orig dist manifest clean realclean distclean
# vim: noet
