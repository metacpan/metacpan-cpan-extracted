use 5.005;

use ExtUtils::MakeMaker;

# ugly trick to work around a bug in these tools, see discussion in
# https://github.com/Perl-Toolchain-Gang/ExtUtils-Manifest/issues/5
require ExtUtils::Manifest;
sub my_find {
	if (ref($_[0]) eq 'HASH') {
		delete $_[0]->{follow};
		delete $_[0]->{follow_fast};
	}
	File::Find::find(@_);
}
*ExtUtils::Manifest::find = \&main::my_find;

WriteMakefile(
	NAME => 'Games::Checkers',
	DISTNAME => 'Games-Checkers',
	dist => {
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
		TO_UNIX => 'ln -s russian $(DISTVNAME)/data/games/default && ln -s test.pdn $(DISTVNAME)/data/games/default/default.pdn',
	},
	EXE_FILES => [ glob("bin/pcheckers*") ],
	VERSION_FROM => 'lib/Games/Checkers.pm',
	ABSTRACT_FROM => 'lib/Games/Checkers.pm',
	AUTHOR => 'Mikhael Goikhman <migo@freeshell.org>',
);

sub MY::postamble {
	return <<'MAKE_FRAG';

install :: pure_install doc_install share_install
	$(NOECHO) $(NOOP)

sharedir = $(PREFIX)/share
DATADIR = $(sharedir)/pcheckers

INSTALL = install -c
LN_SFN = ln -sfn
FIND = find
CUT = cut

share_install:
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)/doc
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)/examples
	$(INSTALL) -d -m 755 $(DESTDIR)$(DATADIR)/games

	@for file in CHANGES COPYING INSTALL README TODO doc/* examples/*; do \
		echo install: $(DESTDIR)$(DATADIR)/$$file; \
		$(INSTALL) -m 644 $$file $(DESTDIR)$(DATADIR)/$$file; \
	done

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
