CFLAGS ?= -O2 -Wall -Wextra -std=c99 -pedantic -fPIC
CPPFLAGS = -Iinclude -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=700 -D_SVID_SOURCE
PKG_CONFIG ?= pkg-config
DESTDIR ?= /usr/local
INSTALL ?= install
PERL ?= perl
SED ?= sed


ifndef RFC6531_FOLLOW_RFC5322
export RFC6531_FOLLOW_RFC5322 = OFF
endif

ifndef RFC6531_FOLLOW_RFC20
export RFC6531_FOLLOW_RFC20 = OFF
endif


BINDIR ?= $(DESTDIR)/bin
LIBDIR ?= $(DESTDIR)/lib
INCLUDEDIR ?= $(DESTDIR)/include
DATAROOTDIR ?= $(DESTDIR)/share
MANDIR ?= $(DATAROOTDIR)/man

MAJOR_VERSION = 0
MINOR_VERSION = 2
PATCH_VERSION = 2
VERSION = $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)

DLL_EXT ?= so
LIB_EXT ?= a
DLL_TARGET = libeav.$(DLL_EXT)
LIB_TARGET = libeav.$(LIB_EXT)
BIN_TARGET = eav
BIN_TARGET_STATIC = eav.static

TARGETS = $(BIN_TARGET) $(DLL_TARGET) $(LIB_TARGET)
bin_SOURCES = $(wildcard bin/*.c)
bin_OBJECTS = $(patsubst bin/%.c, bin/%.o, $(bin_SOURCES))
SOURCES = $(wildcard src/*.c)
OBJECTS = $(patsubst src/%.c, src/%.o, $(SOURCES))

#----------------------------------------------------------#

ifdef FORCE_IDN
ifeq ($(FORCE_IDN),idnkit)
$(info > Force using idnkit)
WITH_IDN = idnkit
IDNKIT_DIR ?= /usr/local
DEFS ?= -DHAVE_IDNKIT -I$(IDNKIT_DIR)/include
LIBS ?= -L$(IDNKIT_DIR)/lib -lidnkit
LIBS_STATIC ?= -L$(IDNKIT_DIR)/lib -lidnkit
PARTIAL = $(wildcard partial/idnkit/*.c)
OBJECTS += $(patsubst  partial/idnkit/%.c,  partial/idnkit/%.o, $(PARTIAL))
else ifeq ($(FORCE_IDN),idn2)
$(info > Force using libidn2)
WITH_IDN = idn2
DEFS ?= -DHAVE_LIBIDN2 $(shell $(PKG_CONFIG) --cflags libidn2)
LIBS ?= $(shell $(PKG_CONFIG) --libs libidn2)
LIBS_STATIC ?= $(shell $(PKG_CONFIG) --static --libs libidn2)
PARTIAL = $(wildcard partial/idn2/*.c)
OBJECTS += $(patsubst  partial/idn2/%.c,  partial/idn2/%.o, $(PARTIAL))
else ifeq ($(FORCE_IDN),idn)
$(info > Force using libidn)
WITH_IDN = idn
DEFS ?= -DHAVE_LIBIDN $(shell $(PKG_CONFIG) --cflags libidn)
LIBS ?= $(shell $(PKG_CONFIG) --libs libidn)
LIBS_STATIC ?= $(shell $(PKG_CONFIG) --static --libs libidn)
PARTIAL = $(wildcard partial/idn/*.c)
OBJECTS += $(patsubst  partial/idn/%.c,  partial/idn/%.o, $(PARTIAL))
else
$(error !!! Unknown IDN library type)
endif
else
$(info > Looking for idn library ...)
ifeq ($(shell $(PKG_CONFIG) --exists 'libidn2 >= 2.0.3' || echo NO),)
$(info > Found libidn2)
WITH_IDN = idn2
DEFS = -DHAVE_LIBIDN2 $(shell $(PKG_CONFIG) --cflags libidn2)
LIBS = $(shell $(PKG_CONFIG) --libs libidn2)
LIBS_STATIC = $(shell $(PKG_CONFIG) --static --libs libidn2)
PARTIAL = $(wildcard partial/idn2/*.c)
OBJECTS += $(patsubst  partial/idn2/%.c,  partial/idn2/%.o, $(PARTIAL))
else ifeq ($(shell $(PKG_CONFIG) --exists 'libidn' || echo NO),)
$(info > Found libidn)
WITH_IDN = idn
DEFS = -DHAVE_LIBIDN $(shell $(PKG_CONFIG) --cflags libidn)
LIBS = $(shell $(PKG_CONFIG) --libs libidn)
LIBS_STATIC = $(shell $(PKG_CONFIG) --static --libs libidn)
PARTIAL = $(wildcard partial/idn/*.c)
OBJECTS += $(patsubst  partial/idn/%.c,  partial/idn/%.o, $(PARTIAL))
else
$(info > Using idnkit by default)
WITH_IDN = idnkit
IDNKIT_DIR ?= /usr/local
DEFS = -DHAVE_IDNKIT -I$(IDNKIT_DIR)/include
LIBS = -L$(IDNKIT_DIR)/lib -lidnkit
LIBS_STATIC = -L$(IDNKIT_DIR)/lib -lidnkit
PARTIAL = $(wildcard partial/idnkit/*.c)
OBJECTS += $(patsubst  partial/idnkit/%.c,  partial/idnkit/%.o, $(PARTIAL))
endif
endif

ifeq ($(RFC6531_FOLLOW_RFC5322),ON)
CPPFLAGS += -DRFC6531_FOLLOW_RFC5322
export RFC6531_FOLLOW_RFC5322
endif

ifeq ($(RFC6531_FOLLOW_RFC20),ON)
CPPFLAGS += -DRFC6531_FOLLOW_RFC20
export RFC6531_FOLLOW_RFC20
endif

#----------------------------------------------------------#


CPPFLAGS += $(DEFS) $(INCLUDES)

LIB_PATH = $(shell realpath .)

export _defs = $(DEFS)
export _libs = $(LIBS)
export _libs_static = $(LIBS_STATIC)
export _pkg_config = $(PKG_CONFIG)
export _install = $(INSTALL)
export _idnkit_dir = $(IDNKIT_DIR)
export _destdir = $(DESTDIR)
export _objects = $(OBJECTS)
export _libpath = $(LIB_PATH)
export _withidn = $(WITH_IDN)

#----------------------------------------------------------#

all: libs app

debug: CFLAGS += -g -D_DEBUG
debug: all

libs: shared static
shared: $(DLL_TARGET)
static: $(LIB_TARGET)

app: $(BIN_TARGET)
app-static: $(BIN_TARGET_STATIC)

$(BIN_TARGET): $(DLL_TARGET)
	$(MAKE) -C bin

$(BIN_TARGET_STATIC): $(LIB_TARGET)
	$(MAKE) -C bin static

$(DLL_TARGET): $(OBJECTS)
	# library -> shared linkage
	$(CC) -shared $(LDFLAGS) -Iinclude -Wl,-soname,$(DLL_TARGET) \
		-o $(DLL_TARGET) $(OBJECTS) $(LIBS)

$(LIB_TARGET): $(OBJECTS)
	# library -> static linkage
	$(AR) rcs $@ $(OBJECTS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -I. -o $@ -c $<

check: $(DLL_TARGET)
	$(MAKE) -C tests check

man:
	$(MAKE) -C docs VERSION=$(VERSION)

auto:
	$(PERL) util/gentld.pl include/eav/auto_tld.h src/auto_tld.c \
		data/punycode.csv

tld-domains:
	$(PERL) util/gen_utf8_pass_test.pl data/tld-domains.txt data/raw.csv

#----------------------------------------------------------#

ifeq ($(WITH_IDN),idnkit)
pc_cflags = -I$${includedir} -DIDN_KIT
pc_requires_private = 
pc_libs_private = -L$(IDNKIT_DIR)/lib -lidnkit
else
pc_cflags = -I$${includedir}
pc_requires_private = lib$(WITH_IDN)
pc_libs_private = 
endif

libeav.pc: libeav.pc.in
	$(SED) \
	-e 's,@version\@,$(VERSION),' \
	-e 's,@prefix\@,$(DESTDIR),g' \
	-e 's,@exec_prefix\@,$(DESTDIR),g' \
	-e 's,@includedir\@,$(INCLUDEDIR),g' \
	-e 's,@libdir\@,$(LIBDIR),g' \
	-e 's,@cflags\@,$(pc_cflags),g' \
	-e 's,@requires_private\@,$(pc_requires_private),g' \
	-e 's,@libs_private\@,$(pc_libs_private),g' \
	$< > $@

#----------------------------------------------------------#

clean: clean-tests clean-bin
	# cleanup
	$(RM) $(DLL_TARGET) $(LIB_TARGET) $(OBJECTS) libeav.pc

clean-tests:
	$(MAKE) -C tests clean
	
clean-bin:
	$(MAKE) -C bin clean

strip: app
	$(MAKE) -C bin strip

strip-static: app-static
	$(MAKE) -C bin strip-static

#----------------------------------------------------------#

install: install-bin install-libs install-man

install-bin: $(BIN_TARGET)
	$(MAKE) -C bin install DESTDIR=$(DESTDIR)

install-libs: install-shared install-static libeav.pc
	$(INSTALL) -d $(DATAROOTDIR)/pkgconfig
	$(INSTALL) -m 0644 libeav.pc $(DATAROOTDIR)/pkgconfig

install-shared: $(DLL_TARGET)
	# installing shared library
	$(INSTALL) -d $(LIBDIR)
	$(INSTALL) -d $(INCLUDEDIR)
	$(INSTALL) -m 0644 include/eav.h $(INCLUDEDIR)
	$(INSTALL) -m 0755 $(DLL_TARGET) $(LIBDIR)/$(DLL_TARGET).$(VERSION)
	cd $(LIBDIR) && \
	ln -snf $(DLL_TARGET).$(VERSION) $(DLL_TARGET).$(MAJOR_VERSION) && \
	ln -snf $(DLL_TARGET).$(VERSION) $(DLL_TARGET)

install-static: $(LIB_TARGET)
	# installing static library
	$(INSTALL) -d $(LIBDIR)
	$(INSTALL) -d $(INCLUDEDIR)
	$(INSTALL) -m 0644 include/eav.h $(INCLUDEDIR)
	$(INSTALL) -m 0644 $(LIB_TARGET) $(LIBDIR)

install-man:
	$(INSTALL) -d $(MANDIR)/man3
	$(INSTALL) -m 0644 docs/libeav.3.gz $(MANDIR)/man3

#----------------------------------------------------------#

.PHONY: all debug check clean docs install libs libeav.pc
