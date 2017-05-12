CFLAGS := -I../include -I/usr/src/linux/include -DIPTABLES_VERSION=\"1.2.8\" -O2 -Wall
CC := gcc
AR := ar
RM := rm

default: all

all: libiptc.a

libiptc.a: libip4tc.o libip6tc.o
	$(AR) r $@ $^

libip4tc.o: libiptc.c

libip6tc.o: libiptc.c

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	-$(RM) *.a *.o
