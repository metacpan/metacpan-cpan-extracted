#
# Makefile to generate dua library
#

MYFUNC = dua
MYLIB= lib$(MYFUNC).a
OBJS = $(MYFUNC).o

.PRECIOUS: $(MYLIB)

PERLINCL= -I/bham/pd/packages/perl-5.004/lib/sun4-solaris/5.00404/CORE
INCLUDES= -I/bham/pd/packages/ldap-3.1/include $(PERLINCL)
DEFINES= -O -Kpic -DSVR4
CFLAGS= $(DEFINES) $(INCLUDES)

all: $(MYLIB)

$(MYLIB): $(OBJS)
	ar cr $@ $(OBJS)

$(MYFUNC).o: $(MYFUNC).c $(MYFUNC).h

tidy:
	rm -f core *.o *~

clean: tidy
	rm -f $(MYLIB)
