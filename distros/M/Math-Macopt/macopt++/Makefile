# MAKEFILE FOR ansi library.

CXXFLAGS = $(INCDIRS) -ansi -pedantic -O2 -Wall -fPIC 
OBJS = macopt.o nrutil.o r.o
CC = g++ 

all: default

default: macopt

macopt: $(OBJS)
	$(CC) -shared $(LDFLAGS) $(OBJS) -o libmacopt.so $(LDLIBS) 
	ar -rc libmacopt.a $(OBJS)

realclean: clean

distclean: clean

clean:
	rm -f *.o
	rm -f *~
	rm -f libmacopt.so
	rm -f libmacopt.a

test:
	# Do nothing

depend:
	makedepend $(MDINCLUDES) *.cc *.c

# DO NOT DELETE THIS LINE -- make depend depends on it.
