LIBDIR=/usr/local/lib
PERL ?= perl

all: liblufs-perlfs.so.2.0.0
liblufs-perlfs.so.2.0.0: perlfs.c perlfs.h
	gcc -fPIC $(shell $(PERL) -MExtUtils::Embed -e ccopts) -DUSE_MUTEX -c -o perlfs.o perlfs.c
	gcc -fPIC -shared -Wl,-soname,liblufs-perlfs.so.2 perlfs.o -lpthread $(shell $(PERL) -MExtUtils::Embed -e ldopts) -o liblufs-perlfs.so.2.0.0
clean:
	rm -f perlfs.lo liblufs-perlfs.so.2.0.0 
install: all install_all
install_all:
	install -m 644 liblufs-perlfs.so.2.0.0 $(LIBDIR)
	[[ -e $(LIBDIR)/liblufs-perlfs.so ]] || ln -s $(LIBDIR)/liblufs-perlfs.so.2.0.0 $(LIBDIR)/liblufs-perlfs.so
	ldconfig -n $(LIBDIR)
