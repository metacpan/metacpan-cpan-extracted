#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;
use Imager::ExtUtils;

my @imagerRequirement = (Imager => '1.013');

WriteMakefile(
	NAME             => 'Imager::File::SIXEL',
	VERSION_FROM     => 'lib/Imager/File/SIXEL.pm',
	ABSTRACT_FROM    => 'lib/Imager/File/SIXEL.pm',
	AUTHOR           => 'davenonymous <dave@davenonymous.com>',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.024',
	OBJECT           => 'SIXEL$(OBJ_EXT) sixel_read$(OBJ_EXT) sixel_write$(OBJ_EXT) sixel_quant$(OBJ_EXT)',
	INC              => Imager::ExtUtils->includes,
	TYPEMAPS         => [Imager::ExtUtils->typemap],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
		@imagerRequirement,
	},
	PREREQ_PM => {
		@imagerRequirement,
		'Scalar::Util' => 0,
		XSLoader       => 0,
	},
	TEST_REQUIRES => {
		'Test2::V0' => '0.000060',
	},
	test       => { TESTS => 't/*.t' },
	clean      => { FILES => 'testout Imager-File-SIXEL-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		prereqs     => {
			develop => {
				requires => {
					'Test::Pod'      => '1.00',
					'CPAN::Uploader' => '0',
					'Pod::Markdown'  => '0',
				},
			},
		},
		# tools/make-images renders the pictures in images/ that the
		# documentation shows; both are shipped but not installed.
		no_index  => { directory => [qw(examples tools images)] },
		resources => {
			homepage   => 'https://github.com/davenonymous/perl-imager-sixel',
			bugtracker => { web => 'https://github.com/davenonymous/perl-imager-sixel/issues' },
			repository => {
				type => 'git',
				url  => 'https://github.com/davenonymous/perl-imager-sixel.git',
				web  => 'https://github.com/davenonymous/perl-imager-sixel',
			},
		},
	},
);

sub MY::postamble {
	return <<'MAKE_FRAG';

# --- Documentation --------------------------------------------------
# Usage: make docs         (after changing the pod or the encoder)
#        make docs-check   (fails when the documentation is out of date)
#
# README.md, docs/Examples.md and docs/Format.md are the pod of
# lib/Imager/File/SIXEL.pm and lib/Imager/File/SIXEL/*.pod converted
# with tools/pod2markdown, a Pod::Markdown subclass that links the pages
# to each other's Markdown files, removes the shared indentation of code
# blocks, fences them with the language set by '=for highlighter' and
# turns tables in 'text' blocks into Markdown tables. tools/make-images
# renders the pictures in images/ with the encoder in blib/, so this
# distribution is built first, and points the image URLs in the pod to
# the tag of the current $VERSION on GitHub. It fails when the pod shows
# a picture that it does not render, or does not show one that it
# renders; with --check it also fails when an image or an image URL is
# out of date.

.PHONY: readme images docs docs-check

POD_MARKDOWN_CHECK = $(PERLRUN) -MPod::Markdown -e1 2>/dev/null || { \
	    echo "ERROR: Pod::Markdown is not installed; cpanm Pod::Markdown"; \
	    exit 1; \
	}

readme :
	@$(POD_MARKDOWN_CHECK)
	$(PERLRUN) tools/pod2markdown

images : pure_all
	$(FULLPERLRUN) -Mblib tools/make-images

docs : images readme

docs-check : pure_all
	$(FULLPERLRUN) -Mblib tools/make-images --check
	@$(POD_MARKDOWN_CHECK)
	@$(PERLRUN) tools/pod2markdown --check || { \
	    echo "ERROR: the Markdown files are out of date; run 'make readme' (or 'make docs')."; \
	    exit 1; \
	}

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if a module's
# $VERSION differs from the one in lib/Imager/File/SIXEL.pm, if a tag
# for the current $(VERSION) already exists, or if the documentation
# is out of date (docs-check). See RELEASING.md.
#
# disttest and dist run as separate sub-makes on purpose: as
# prerequisites of one target they would share a single distdir
# build, and the tarball would pack the blib/ that disttest left
# behind. PAUSE refuses to index such a tarball.

.PHONY: release release-check version-check

version-check :
	@perl -ne 'if (/^\s*our \$$VERSION\s*=\s*\x27([^\x27]*)\x27/ && $$1 ne "$(VERSION)") { print "ERROR: $$ARGV has \$$VERSION $$1, expected $(VERSION)\n"; $$failed = 1 } END { exit($$failed ? 1 : 0) }' $$(find lib -name '*.pm')

release-check : version-check docs-check
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Imager/File/SIXEL.pm."; \
	    exit 1; \
	fi
	@command -v cpan-upload >/dev/null 2>&1 || { \
	    echo "ERROR: cpan-upload not found in PATH; cpanm CPAN::Uploader"; \
	    exit 1; \
	}
	@test -r $(HOME)/.pause || { \
	    echo "ERROR: ~/.pause not found; see RELEASING.md for the format."; \
	    exit 1; \
	}

release :: release-check
	$(MAKE) disttest
	$(MAKE) dist
	@test -f $(DISTVNAME).tar.gz || { \
	    echo "ERROR: $(DISTVNAME).tar.gz was not built; refusing to upload."; \
	    exit 1; \
	}
	@if tar tzf $(DISTVNAME).tar.gz | grep -qE '/(blib/|Makefile$$|MYMETA\.|pm_to_blib|SIXEL\.c$$|[^/]*\.(o|so|bs)$$)'; then \
	    echo "ERROR: $(DISTVNAME).tar.gz contains build artefacts; refusing to upload."; \
	    exit 1; \
	fi
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git tag -a v$(VERSION) -m 'Release v$(VERSION)'"
	@echo "  git push --follow-tags"
MAKE_FRAG
}
