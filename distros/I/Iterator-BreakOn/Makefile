#
#	Global values
MODULE=Iterator::BreakOn
DEBIAN_PACKAGE=libiterator-breakon-perl
DESTDIR ?= /tmp

#
#	Source modules (all .pm files under the lib directory)
MODULES=$(shell find lib -name "*.pm")
OTHERS=$(wildcard examples/*.p[ml])
CHECK_SOURCES=$(MODULES) $(BINARIES) $(OTHERS)
DATA=$(wildcard examples/*.csv)

#
#	Test program
DEBUG=examples/example.pl
ARGS=

#
#	External tools
PERL ?= perl -Ilib
PERL_CHECK ?= $(PERL) -cw
PERL_DEBUG ?= $(PERL) -d:ptkdb
PROVE=$(shell which prove) -Ilib
INSTALL=$(shell which install)
DEBUILD=debuild -uc -us -sa

#
#	Do nothing by default
all:

#
#	Check syntax
.PHONY:	check $(CHECK_SOURCES)

check:	$(CHECK_SOURCES)

$(CHECK_SOURCES):
	$(PERL_CHECK) $@

#
#	Test programs
test:	
	$(PROVE) -v t/

#
#	Debug program
debug:		check $(DEBUG)
	$(PERL_DEBUG) $(DEBUG) $(ARGS)

#
#	Run program
run:	check $(DEBUG)
	$(PERL) $(DEBUG) $(ARGS)

#
#	Build the perl package
build:		Build data

Build:		Build.PL
	$(PERL) Build.PL installdirs=vendor

binary:		build
	$(PERL) Build 

data:	$(DATA)

examples/datasource.csv:
	$(PERL) examples/make_csv_file.pl

#
#	Documents and manual pages
doc:	build
	$(PERL) Build docs

#
#	Install the perl package
install:	test binary
	$(PERL) Build install destdir=$(DESTDIR)

#
#	Make the distribution file
dist:	build
	$(PERL) Build dist

.PHONY: clean

clean:
	-$(PERL) Build clean
	rm -f *.gz *.orig *.bak
	rm -f $(DATA)

distclean:
	-$(PERL) Build distclean

#
#	Debian package
deb:
	$(DEBUILD) 
