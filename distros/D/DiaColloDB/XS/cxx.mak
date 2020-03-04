##-*- Mode: GNUmakefile -*-

TARGETS ?= \
	cofgen

CC       = g++
LD       = $(CC)
OFLAGS ?= -O2
#OFLAGS ?= -ggdb -O0
CFLAGS ?= -Wall -D_FILE_OFFSET_BITS=64 $(OFLAGS) -fopenmp 
CXXFLAGS ?= $(CFLAGS)
LDFLAGS ?= $(CFLAGS)
LIBS ?=

all: $(TARGETS)

##-- dependencies
dcdb-cof-gen.o: dcdb-cof-gen.cc cof-gen.h utils.h
dcdb-cof-compile32.o: dcdb-cof-compile.cc cof-compile.h utils.h
dcdb-cof-compile64.o: dcdb-cof-compile.cc cof-compile.h utils.h

##-- patterns
.SUFFIXES: .cc .o

dcdb-cof-compile32.o:
	g++ $(CXXFLAGS) -DDIACOLLO_COF2BIN_BITS=32 -c $< -o $@

dcdb-cof-compile64.o:
	g++ $(CXXFLAGS) -DDIACOLLO_COF2BIN_BITS=64 -c $< -o $@

.cc.o:
	g++ $(CXXFLAGS) -c $< -o $@

##-- final targets
dcdb-cof-gen: dcdb-cof-gen.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

dcdb-cof-compile32: dcdb-cof-compile32.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

dcdb-cof-compile64: dcdb-cof-compile64.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

##-- clean
.PHONY: clean
clean:
	rm -f *.o $(TARGETS)

