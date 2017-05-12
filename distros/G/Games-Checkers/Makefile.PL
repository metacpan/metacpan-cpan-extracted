use 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Games::Checkers',
	DISTNAME => 'Games-Checkers',
	dist => {
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
		TO_UNIX => 'ln -s russian $(DISTVNAME)/data/games/default && ln -s test.pdn $(DISTVNAME)/data/games/default/default.pdn',
	},
	EXE_FILES => [ glob("bin/*") ],
	VERSION_FROM => 'lib/Games/Checkers.pm',
	ABSTRACT_FROM => 'lib/Games/Checkers.pm',
	AUTHOR => 'Mikhael Goikhman <migo@freeshell.org>',
);

sub MY::postamble {
	return <<'MAKE_FRAG';

install :: pure_install doc_install share_install
	$(NOECHO) $(NOOP)

prefix = /usr/local
sharedir = $(prefix)/share
DATADIR = $(sharedir)/pcheckers

INSTALL = install -c
LN_SFN = ln -sfn
FIND = find
CUT = cut

share_install:
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)/games

	@for dir in images games/british games/internt games/italian games/russian spec; do \
		$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)/$$dir; \
		for file in `$(FIND) data/$$dir -type f -print | $(CUT) -d/ -f2-`; do \
			echo install: $(DESTDIR)$(DATADIR)/$$file; \
			$(INSTALL) -m 644 data/$$file $(DESTDIR)$(DATADIR)/$$file; \
		done; \
	done

	$(LN_SFN) russian $(DESTDIR)$(DATADIR)/games/default
	$(LN_SFN) test.pdn $(DESTDIR)$(DATADIR)/games/default/default.pdn

MAKE_FRAG
}
