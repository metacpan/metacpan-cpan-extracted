#
# Finance::InteractiveBrokers::SWIG - Makefile for SWIG build
#
# Copyright (c) 2010-2014 Jason McManus
# Version: 0.08
#
# This is usually invoked by 'perl Makefile.PL && make', but if you need to
# run it separately, you can run it by:
#
#   make -fMakefile.swig [ OPTIONS ]
#
# OPTIONS:
#   IB_BUILD_PATH=/path/to/IBJts        # wherever your un-jar'ed API is
#   SWIG=/path/to/swig                  # path to SWIG binary program
#   IB_API_VERSION=X.XX                 # version of the IB API [def: 9.64]
#
# Pre-existing files:
#   Makefile.swig
#   IBAPI.i
#   IBAPI.cxx
#   IBAPI.h
#   ezembed.h
#   $IB_BUILD_PATH/cpp/PosixSocketClient/EClientSocketBase.cpp
#   $IB_BUILD_PATH/cpp/PosixSocketClient/EPosixClientSocket.cpp
# Intermediate files:
#   EClientSocketBase.o
#   EPosixClientSocket.o
#   IBAPI_wrap.cxx
#   IBAPI_wrap.o
#   IBAPI.o
# Final targets:
#   IBAPI.pm
#   IBAPI.so
#

###
### Options
###

CC=gcc
CXX=g++
LD=ld
CXXEXT=cxx

SWIGEXT=i
PMEXT=pm
OBJEXT=o

# May be different on OS-X, etc.
DLEXT = $(shell perl -MConfig -e'print $$Config{dlext}')
ifeq "$(DLEXT)" ""
DLEXT = so
endif

# These should be overridden on the command-line
SWIG=swig
IB_BUILD_PATH=$(PROJDIR)/lib/tws_api/IBJts
IB_API_VERSION=9.66
BUILD_TIME=0
IB_API_INTVER=$(subst .,,$(IB_API_VERSION))

ifdef DEBUG
DDEBUG=-DDEBUG
else
DDEBUG=
endif

OSNAME = $(shell perl -MConfig -le'print $$Config{osname}')

SOCKDIR = $(IB_BUILD_PATH)/cpp/PosixSocketClient
INCLUDES = -I$(IB_BUILD_PATH)/cpp/Shared -I$(SOCKDIR)

MODBASE = Finance::InteractiveBrokers::SWIG
MODNAME = IBAPI
MODFULL = $(MODBASE)::$(MODNAME)
LIBNAME = $(MODNAME).$(DLEXT)

# Get the perl C opts from perl itself, and clean them up for C++
RAWPOPTS := $(shell perl -MExtUtils::Embed -e ccopts)
PERLOPTS := $(subst -Wdeclaration-after-statement,,$(RAWPOPTS))
PERLOPTS := $(subst -fstack-protector,,$(PERLOPTS))
PERLOPTS := $(subst -D_LARGEFILE_SOURCE,,$(PERLOPTS))
PERLOPTS := $(subst -D_FILE_OFFSET_BITS=64,,$(PERLOPTS))

SWIGOPTS = -c++ -perl -Wall \
		   -DIB_API_VERSION=$(IB_API_VERSION) \
		   -DIB_API_INTVER=$(IB_API_INTVER) \
		   -DBUILD_TIME=$(BUILD_TIME)
#SWIG_INCL=
CFLAGS += -fPIC \
		  -DIB_API_VERSION=$(IB_API_VERSION) \
		  -DIB_API_INTVER=$(IB_API_INTVER) \
		  -DBUILD_TIME=$(BUILD_TIME)
CFLAGS += $(findstring -D_LARGEFILE_SOURCE,$(RAWPOPTS))
CFLAGS += $(findstring -D_FILE_OFFSET_BITS=64,$(RAWPOPTS))

LDFLAGS += $(shell perl -MConfig -le'print $$Config{lddlflags}')
LDFLAGS += $(shell perl -MExtUtils::Embed -e ldopts)
LDFLAGS := $(subst -fstack-protector,,$(LDFLAGS))

# Workaround for ExtUtils::Embed being made of lies
LIBPERL := $(shell perl -MConfig -le'print $$Config{libperl}')
DYNEXT := $(shell perl -MConfig -le'print $$Config{so}')
ifneq "$(LIBPERL)" "libperl.$(DYNEXT)"
LDFLAGS := $(subst -lperl,,$(LDFLAGS))
endif

ifeq "$(OSNAME)" "darwin"
LDFLAGS += -Wl,-no_arch_warnings
endif

# Hacky patch for RT#94880: gcc >4.7 stopped including <unistd.h>
CFLAGS += -include unistd.h

IBSTRING=-DIB_USE_STD_STRING

###
### Build rules
###

.PHONY: all
all: lib

.PHONY: lib
lib: $(MODNAME).$(DLEXT)

.PHONY: swig
swig: $(MODNAME).$(PMEXT)

$(MODNAME).$(DLEXT): $(MODNAME).$(PMEXT)
	@echo --------------------------
	@echo Building module library...
	@echo --------------------------
	$(CXX) $(CFLAGS) $(DDEBUG) $(INCLUDES) $(IBSTRING) $(PERLOPTS) -c $(MODNAME).$(CXXEXT) -o $(MODNAME).$(OBJEXT)
	$(CXX) $(CFLAGS) $(DDEBUG) $(INCLUDES) $(IBSTRING) $(PERLOPTS) -c $(MODNAME)_wrap.cxx -o $(MODNAME)_wrap.$(OBJEXT)
	$(CXX) $(CFLAGS) $(DDEBUG) $(INCLUDES) $(IBSTRING) -c $(SOCKDIR)/EClientSocketBase.cpp -o EClientSocketBase.$(OBJEXT)
	$(CXX) $(CFLAGS) $(DDEBUG) $(INCLUDES) $(IBSTRING) -c $(SOCKDIR)/EPosixClientSocket.cpp -o EPosixClientSocket.$(OBJEXT)
	$(CXX) $(LDFLAGS) $(DDEBUG) -o $@ $(MODNAME).$(OBJEXT) $(MODNAME)_wrap.$(OBJEXT) EClientSocketBase.$(OBJEXT) EPosixClientSocket.$(OBJEXT)

$(MODNAME).$(PMEXT): $(MODNAME).$(SWIGEXT) $(MODNAME).$(CXXEXT) $(MODNAME).h
	@echo --------------------------------------------
	@echo Building SWIG interface for ${MODNAME}...
	@echo --------------------------------------------
	$(SWIG) $(SWIGOPTS) $(SWIG_INCL) $(INCLUDES) -o $(MODNAME)_wrap.$(CXXEXT) $<

.PHONY: clean
clean:
	rm -f $(MODNAME)_wrap.* $(MODNAME).$(PMEXT) *.$(OBJEXT) *.$(DLEXT)

# END
