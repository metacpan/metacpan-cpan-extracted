

TEST_VERBOSE?=1
TEST_FILE?=test.pl
GOALS:=$(if $(MAKECMDGOALS),$(MAKECMDGOALS),all)

SUDO:=
$(GOALS): Makefile
	$(SUDO) make -f Makefile $(MAKECMDGOALS) TEST_VERBOSE:=$(TEST_VERBOSE)
install: ROOT:=$(if $(filter 0,$(shell id -u)),1,)
install: SUDO:=$(if $(ROOT),,sudo)

Makefile: Makefile.PL
	perl $<

