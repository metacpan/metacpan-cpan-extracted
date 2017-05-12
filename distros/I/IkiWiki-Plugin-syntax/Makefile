#
#	Global values
MODULE=IkiWiki::Plugin::syntax
DEBIAN_PACKAGE=ikiwiki-plugin-syntax
DESTDIR ?= /tmp
LIBS=-Ilib -It/lib

#
#	Source modules (all .pm files under the lib directory)
MODULES=$(shell find lib -name "*.pm")
BINARIES=$(wildcard bin/*.pl)
EXAMPLES=$(wildcard examples/*.p[lm])
TESTS=$(wildcard t/*.t)
CHECK_SOURCES=$(MODULES) $(BINARIES) $(EXAMPLES) $(TESTS)

#
#	Test program
DEBUG=
ARGS=

#
#	External tools
PERL ?= perl $(LIBS)
PERL_CHECK ?= $(PERL) -cw
PERL_DEBUG ?= $(PERL) -d:ptkdb
PROVE=$(shell which prove)
INSTALL=$(shell which install)
DEBUILD=debuild -uc -us 

#
#	Do nothing for default
all:

#
#	Check syntax
.PHONY: check $(CHECK_SOURCES)

check:	$(CHECK_SOURCES)

$(CHECK_SOURCES):
	$(PERL_CHECK) $@

#
#	Test programs
test:	
	$(PROVE) $(LIBS) -v t/

#
#	Debug program
debug:		check $(DEBUG)
	$(PERL_DEBUG) $(DEBUG) $(ARGS)

#
#	Build the perl package
build:		Build

Build:		Build.PL
	$(PERL) Build.PL installdirs=vendor

binary:		build
	$(PERL) Build 

#
#	Install the perl package
install:	test binary
	$(PERL) Build install destdir=$(DESTDIR)

#
#	Debian package
deb:	install
	cd $(DESTDIR); $(DEBUILD) 
