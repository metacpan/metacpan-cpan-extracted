# WARNING: This Makefile should update itself automatically
# if a new version of Dist::Zilla::PluginBundle::Author::GSG is installed.
# See the docmentation for that module for details.

DIST_NAME   ?= $(shell perl -ne '/^\s*name\s*=\s*(\S+)/ && print $$1' dist.ini )
MAIN_MODULE ?= $(shell perl -ne '/^\s*main_module\s*=\s*(\S+)/ && print $$1' dist.ini )

CARTON      ?= $(shell which carton 2>/dev/null || echo carton )
SHARE_DIR   ?= $(shell \
  $(CARTON) exec -- perl -Ilib -MFile::ShareDir=dist_dir -e \
    'print eval { dist_dir("Dist-Zilla-PluginBundle-Author-GSG") }' 2>/dev/null )

CPANFILE_SNAPSHOT ?= $(shell \
  carton exec perl -MFile::Spec -e \
	'($$_) = grep { -e } map{ "$$_/../../cpanfile.snapshot" } \
		grep { m(/lib/perl5$$) } @INC; \
		print File::Spec->abs2rel($$_) . "\n" if $$_' 2>/dev/null )

DZIL := $(shell $(CARTON) exec -- perl -e \
		'(my $$p = $$ENV{PATH}) =~ s,:.*,/dzil,; print $$p' )

ifeq ($(MAIN_MODULE),)
MAIN_MODULE := lib/$(subst -,/,$(DIST_NAME)).pm
endif
ifeq ($(CPANFILE_SNAPSHOT),)
CPANFILE_SNAPSHOT    := cpanfile.snapshot
endif
CARTON_INSTALL_FLAGS ?= --without develop
PERL_CARTON_PERL5LIB ?= $(PERL5LIB)
CONTRIB              ?= CONTRIBUTING.md
EXTRA_UPDATES        += $(CONTRIB)

# Without a sharedir we don't know where to get the Makefile
MAKEFILE_TARGET :=
MAKEFILE_SHARE  :=
ifneq ($(SHARE_DIR),)
	MAKEFILE_TARGET := $(lastword $(MAKEFILE_LIST))
	MAKEFILE_SHARE  := $(wildcard $(SHARE_DIR)/Makefile*)

# with a special case for when we're in the PluginBundle
# that checks whether any of the Makefiles in the sharedir
# are the target we want to update.
ifneq (,$(filter $(MAKEFILE_TARGET),$(MAKEFILE_SHARE)))
	MAKEFILE_TARGET :=
endif
endif

.PHONY : test disttest clean distclean realclean develop carton

RUN_TESTS=prove -lfr t

# If we have a Makefile.PL, we do some things differently.
ifneq (,$(wildcard Makefile.PL))
ifeq (Makefile,$(MAKEFILE_TARGET))
$(error This Makefile should be named something else when using Makefile.PL)
endif
RUN_TESTS=$(MAKE) test
EXTRA_CLEAN=Makefile Makefile.old

test: build

build: Makefile
	$(CARTON) exec -- $(MAKE) all

# If we have dzil available, we can make sure Makefile.PL is up-to-date
ifneq (,$(wildcard $(DZIL)))
EXTRA_UPDATES += Makefile.PL
# Make sure this version is sync'd in t/*
Makefile.PL: $(MAIN_MODULE) dist.ini $(DZIL) $(wildcard *.xs)
	V=0.0.1 $(CARTON) exec dzil run sh -c "cp Makefile.PL ${CURDIR}/$@"
endif

Makefile: Makefile.PL
	$(CARTON) exec -- perl Makefile.PL

endif # Makefile.PL exists

test : $(CPANFILE_SNAPSHOT)
	@nice $(CARTON) exec ${RUN_TESTS}

# This target requires that you add 'requires "Devel::Cover";'
# to the cpanfile and then run "carton" to install it.
testcoverage : $(CPANFILE_SNAPSHOT)
	$(CARTON) exec -- cover -test -ignore . -select ^lib

disttest: $(DZIL)
	$(CARTON) exec -- dzil test --verbose --all

$(MAKEFILE_TARGET): $(MAKEFILE_SHARE)
	install -m 644 $< $@
	@echo $(MAKEFILE_TARGET) updated>&2

clean: distclean
	rm -rf .build dzpbag-* blib $(EXTRA_CLEAN)

realclean: clean distclean
	rm -rf local

distclean:
	test ! -e "$(DZIL)" || $(CARTON) exec dzil clean

update: README.md LICENSE.txt $(EXTRA_UPDATES)
	@echo Everything is up to date

README.md: $(MAIN_MODULE) dist.ini $(DZIL)
	$(CARTON) exec dzil run sh -c "pod2markdown $< > ${CURDIR}/$@"

LICENSE.txt: dist.ini $(DZIL)
	$(CARTON) exec dzil run sh -c "install -m 644 LICENSE ${CURDIR}/$@"

.SECONDEXPANSION:
$(CONTRIB): $(SHARE_DIR)/$$(@F)
	install -m 644 $< $@

$(CPANFILE_SNAPSHOT): $(CARTON) cpanfile
	$(CARTON) install $(CARTON_INSTALL_FLAGS)

$(DZIL): $(CPANFILE_SNAPSHOT)
	$(CARTON) install # with develop
	@test -e $@ && touch $@ # update timestamp

carton:
	@echo You must install carton: https://metacpan.org/pod/Carton >&2;
	@false;
