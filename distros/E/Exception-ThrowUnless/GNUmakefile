ifeq ($(wildcard Makefile),)

Makefile: Makefile.PL MANIFEST
	perl Makefile.PL
	test -e Makefile

MANIFEST:
	cvsfiles -p | xargs lsfiles | sort > $@.new
	mv $@.new $@

%: Makefile
	make $@

else
include Makefile
Makefile: $(shell find lib -name '*.pm')

COMPRESS+= -f

endif

tags: $(MODS)
	ctags  $(MODS)

