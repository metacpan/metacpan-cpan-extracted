#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

TESTS= \
	t001 \
	t002 \

CC=	gcc
CFLAGS=	-Wall -g
PERL=	perl
all: $(TESTS)

t%: t%.c framework.o framework.h
	$(CC) $(CFLAGS) -o $@ $< framework.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

framework.o: framework.h

run: $(TESTS)
	$(RM) core*
	@ec=0; for test in $(TESTS) ; do \
	    echo "==== $$test" ;\
	    echo "The next command will dump core, don't worry it's supposed to" ;\
	    ( ulimit -c unlimited ; ./$$test ; exit 0) ;\
	    mv core* $$test.core ;\
	    ./decode-expected-blocks.pl > $$test.expected ;\
	    $(PERL) ../plumber --dump-blocks $$test $$test.core > $$test.actual ;\
	    res=PASS; \
	    diff -U0 $$test.expected $$test.actual || res=FAIL ;\
	    echo "$$res $$test" ;\
	    [ $$res = FAIL ] && ec=1; \
	done ; exit $$ec

clean:
	for test in $(TESTS) ; do \
	    $(RM) $$test $$test.expected $$test.actual $$test.core $$test.stderr ;\
	done
	$(RM) expected-blocks.dat *.o
