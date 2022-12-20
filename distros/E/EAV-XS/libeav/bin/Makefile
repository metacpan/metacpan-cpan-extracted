CFLAGS ?= -O2 -Wall -Wextra -std=c99 -pedantic
DESTDIR ?= ${_destdir}
INSTALL ?= ${_install}

CPPFLAGS = -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=700 -D_SVID_SOURCE -D__EXTENSIONS__
CPPFLAGS += -I../include
CPPFLAGS += ${_defs} $(INCLUDES)

TARGETS = eav eav.static
SOURCES = $(wildcard *.c)
OBJECTS = $(patsubst %.c, %.o, $(SOURCES))

LIBS = ${_libs}
LIBS_STATIC = ${_libs_static}

#----------------------------------------------------------#

all: shared

debug: DEFS += -g -D_DEBUG
debug: all

static: eav.static
shared: eav

eav: $(OBJECTS)
	# bin -> shared linkage
	$(CC) -o $@ $(OBJECTS) -L.. -leav $(LIBS) $(LDFLAGS)

eav.static: LDFLAGS = -static
eav.static: $(OBJECTS)
	# bin -> static linkage
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) -L.. -leav $(LIBS_STATIC)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEFS) -o $@ -c $<


strip: shared
	# bin -> strip shared
	strip --strip-unneeded -R .comment -R .note -R .note.ABI-tag eav

strip-static: static
	# bin -> strip static
	strip --strip-unneeded -R .comment -R .note -R .note.ABI-tag eav.static

#----------------------------------------------------------#

clean:
	# bin -> cleanup
	$(RM) $(TARGETS) $(OBJECTS)

#----------------------------------------------------------#

install: shared
	$(INSTALL) -d $(DESTDIR)/bin
	$(INSTALL) -m 0755 eav $(DESTDIR)/bin

install-static: static
	$(INSTALL) -d $(DESTDIR)/sbin
	$(INSTALL) -m 0755 eav.static $(DESTDIR)/sbin/eav-static

uninstall:
	# === bin -> uninstalling ...
	$(RM) $(DESTDIR)/bin/eav
	$(RM) $(DESTDIR)/sbin/eav-static

#----------------------------------------------------------#

.PHONY: all clean debug install strip static shared install-static strip-static eav eav.static uninstall
