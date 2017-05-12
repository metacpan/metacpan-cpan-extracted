CC=gcc
CFLAGS=-c -Wall

all: all_shared

all_static: build_static static
all_shared: build_shared shared

build_static: libextractor.c
	$(CC) $(CFLAGS) libextractor.c -o libextractor.o

static: libextractor.o
	ar rcs libextractor.a libextractor.o


build_shared: libextractor.c
	$(CC) $(CFLAGS) -fPIC libextractor.c -o libextractor.o

shared: libextractor.o
	$(CC) -shared -Wl -o libextractor.so  libextractor.o
