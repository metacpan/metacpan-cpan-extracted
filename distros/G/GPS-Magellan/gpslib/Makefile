CC = gcc
AR = ar
RANLIB = ranlib

CFLAGS = -Wall -DLINUX -g
CXXFLAGS = -Wall -DLINUX -g

OBJECTS = serial.o magellan.o test.o
LIBGPS = libgps.a
TEST = test.o

test: gpslib
	$(CC) -g -o test $(TEST) $(LIBGPS)

gpslib: $(OBJECTS)
	$(AR) cr $(LIBGPS) $(OBJECTS)
	$(RANLIB) $(LIBGPS)

all: clean test gpslib

%.o: %.cxx %.h
	$(CC) -c $(CXXFLAGS) -o $@ $<
%.o: %.c %.h
	$(CC) -c $(CFLAGS) -o $@ $<
%.o: %.cpp %.h
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	-rm -f *.o test core $(LIBGPS)

install:
	cp test /usr/local/bin/.
