CFLAGS ?= -O2 -Wall -Wextra -std=c99 -pedantic
DESTDIR ?= ${_destdir}
INSTALL ?= ${_install}

DEFS = -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=500 -D_SVID_SOURCE
DEFS += -I../include
DEFS += ${_defs}

TARGETS = eav eav.static
SOURCES = $(wildcard *.c)
OBJECTS = $(patsubst %.c, %.o, $(SOURCES))

LIBS = ${_libs}
LIBS += -L.. -leav

#----------------------------------------------------------#

CPPFLAGS += $(DEFS) $(INCLUDES)

all: depend shared

debug: DEFS += -g -D_DEBUG
debug: all

static: eav.static
shared: eav

eav: $(OBJECTS)
	# bin -> shared linkage
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBS)

eav.static: LDFLAGS = -static
eav.static: $(OBJECTS)
	# bin -> static linkage
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $<


strip: shared
	# bin -> strip
	strip --strip-unneeded -R .comment -R .note -R .note.ABI-tag $(TARGETS)

#----------------------------------------------------------#

clean:
	# bin -> cleanup
	$(RM) $(TARGETS) $(OBJECTS) Makefile.depend

#----------------------------------------------------------#

install: shared
	$(INSTALL) -d $(DESTDIR)/bin
	$(INSTALL) -m 0755 eav $(DESTDIR)/bin

#----------------------------------------------------------#

.PHONY: all clean debug

depend: Makefile.depend
Makefile.depend:
	$(CC) $(CPPFLAGS) $(CFLAGS) -MM -MG $(SOURCES) > $@

-include Makefile.depend

.DELETE_ON_ERROR:
