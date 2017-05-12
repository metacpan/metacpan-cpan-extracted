#
# Makefile for making a iptables.o file...
#

ifndef KERNEL_DIR
# KERNEL_DIR=/usr/src/linux
# Point to /lib/modules/`uname -r`/build
# KERNEL_DIR = /lib/modules/$(shell uname -r)/build
endif

ifndef IPTABLES_VERSION
IPTABLES_VERSION:=1.4.4
endif

ifndef IPTABLES_VERSION_CODE
IPTABLES_VERSION_CODE:=66564
endif


ifndef PREFIX
PREFIX:=/usr/local/
endif

LIBDIR:=$(PREFIX)/lib
INCDIR:=$(PREFIX)/include
SBINDIR:=$(PREFIX)/sbin

ifndef IPT_LIBDIR
IPT_LIBDIR:=$(LIBDIR)/iptables
endif

ifndef XTABLES_LIBDIR
XTABLES_LIBDIR:=/lib/xtables/
endif


ifndef LDFLAGS
LDFLAGS = -L$(LIBDIR)
endif
LDFLAGS+=-rdynamic

# When generating the perl Makefile.PL, the system will detect if libip4tc
# is available, this variable parsed along from the ../Makefile call
ifndef EXTRALIBS
EXTRALIBS := -lnsl -liptc -lip4tc -lxtables
endif
LDLIBS=-ldl $(EXTRALIBS)

COPT_FLAGS:=-O2
CFLAGS:=$(COPT_FLAGS) -Wall -Wunused -I$(KERNEL_DIR)/include -I$(INCDIR) -I../include/ -fPIC -DXTABLES_INTERNAL -g
#-g -DDEBUG #-pg # -DIPTC_DEBUG

DEFINES:=-DIPTABLES_VERSION=\"$(IPTABLES_VERSION)\" -DXTABLES_LIBDIR=\"$(XTABLES_LIBDIR)\" -DIPTABLES_VERSION_CODE=\$(IPTABLES_VERSION_CODE)
default: all

all: iptables.o iptables-standalone iptables-blocking xshared.o

iptables.o: iptables-detect-version.c Makefile
	$(CC) $(CFLAGS) $(DEFINES) -c -o $@ $<

xshared.o: xshared.c
	$(CC) $(CFLAGS) $(DEFINES) -c -o $@ $<

iptables-standalone: iptables-standalone.c iptables.o xshared.o
	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -o $@ $^ $(LDLIBS)

iptables-blocking: iptables-blocking.c iptables.o xshared.o
	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -o $@ $^ $(LDLIBS)


## Try to make static version
#iptables-static: iptables-standalone.c iptables.o xtables.o
#	echo  Static-ver: $@ $^
#	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -o $@ $^ ../library_iptc/libiptc.a -ldl -lnsl

install:
	install -m 0755 -d $(DESTDIR)/$(SBINDIR)
	install -m 0755 iptables-blocking $(DESTDIR)/$(SBINDIR)

clean:
	rm iptables-standalone iptables-blocking *.o
