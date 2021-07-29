#! /bin/make -f
# GNUmakefile for Linux + CitrusPerl
# Based on CitrusPerl 5.24 with wxWidgets 3.0.

.PHONY : ebshell ebwxshell

ROOT   := ../..
COMMON := ../common
SCRIPT := ..

# Perlbrew for CitrusPerl.
PP := perl -Ilib/perl5 -Mlocal::lib=lib/perl5 bin/pp
WXLIBS := /bulk/perlbrew/perls/citrus-5.24.1-wx-3.0/vendor/lib/Alien/wxWidgets/gtk_3_0_2_uni/lib

ebshell : ebshell.pp ${COMMON}/ebshell.pp
	${PP} --output=ebshell @ebshell.pp ${SCRIPT}/ebshell.pl

ebwxshell : ebshell.pp ${COMMON}/ebshell.pp ${COMMON}/ebwxshell.pp
	env LD_LIBRARY_PATH=${WXLIBS} \
	${PP} --output=ebwxshell @ebwxshell.pp ${SCRIPT}/ebwxshell.pl

clean ::
	rm -f *.pp.deps *~ ebshell ebwxshell
