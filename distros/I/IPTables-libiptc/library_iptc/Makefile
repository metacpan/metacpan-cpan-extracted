CFLAGS := -I../include -I/usr/src/linux/include -O2 -Wall
CC := gcc
AR := ar
RM := rm

ifndef IPTABLES_VERSION
IPTABLES_VERSION:=1.4.1
endif

DEFINES:=-DIPTABLES_VERSION=\"$(IPTABLES_VERSION)\"

default: all

all: libiptc.a

libiptc.a: libip4tc.o libip6tc.o
	$(AR) r $@ $^

libip4tc.o: libiptc.c

libip6tc.o: libiptc.c

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS) $(DEFINES) -fPIC

clean:
	-$(RM) *.a *.o
