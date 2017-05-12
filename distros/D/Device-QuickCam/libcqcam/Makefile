# Generated automatically from Makefile.in by configure.
CXX = c++ -pipe
CXXFLAGS = -Wall  -O3 -DLINUX -DJPEG -DLOCKING 
RANLIB = ranlib

PROGRAMS = libcqcam.a
OBJS = camera.o cqcsrv.o imager.o port.o rcfile.o 

all: $(PROGRAMS)

clean:
	rm -f *.o core $(PROGRAMS)

libcqcam.a: $(OBJS)
	$(AR) r $@ $(OBJS)
	$(RANLIB) $@
