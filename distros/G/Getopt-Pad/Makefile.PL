use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Find qw(find);

# Build the META "provides" map by hand. Module::Metadata does not
# recognise Object::Pad's "class NAME" declarations, so the generated
# map would list those files as package "main"; an explicit map lets
# PAUSE index the dist from META alone.
sub collectProvides {
	my %provides;
	find(
		{
			no_chdir => 1,
			wanted   => sub {
				return unless /\.pm\z/;
				my ($package, $version) = readPackageAndVersion($_);
				$provides{$package} = {file => $_, version => $version};
			},
		},
		'lib'
	);
	return \%provides;
}

sub readPackageAndVersion {
	my ($file) = @_;
	open(my $fh, '<', $file) or die sprintf("Cannot read %s: %s\n", $file, $!);
	my ($package, $version);
	while (my $line = <$fh>) {
		$package //= $1 if $line =~ /^\s*(?:package|class)\s+([\w:]+)/;
		$version //= $1 if $line =~ /^\s*our\s+\$VERSION\s*=\s*'([^']*)'/;
		last if defined $package && defined $version;
	}
	close($fh);
	die sprintf("No package or class declaration found in %s\n", $file) unless defined $package;
	die sprintf("No \$VERSION found in %s\n", $file) unless defined $version;
	return ($package, $version);
}

WriteMakefile(
	DISTNAME           => 'Getopt-Pad',
	NAME               => 'Getopt::Pad',
	AUTHOR             => 'davenonymous <perl@davenonymous.com>',
	VERSION_FROM       => 'lib/Getopt/Pad.pm',
	ABSTRACT_FROM      => 'lib/Getopt/Pad.pm',
	LICENSE            => 'perl_5',
	MIN_PERL_VERSION   => '5.026',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
	},
	TEST_REQUIRES => {
		'Test2::V0' => '0',
	},
	PREREQ_PM => {
		'Object::Pad'          => '0.800',
		'Getopt::Long'         => '2.50',
		'Feature::Compat::Try' => '0',
		'JSON::PP'             => '0',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		prereqs     => {
			runtime => {
				recommends => {
					'YAML::XS'      => '0',
					'Term::ReadKey' => '0',
				},
			},
		},
		resources => {
			homepage   => 'https://github.com/davenonymous/perl-getopt-pad',
			bugtracker => { web => 'https://github.com/davenonymous/perl-getopt-pad/issues' },
			repository => {
				type => 'git',
				url  => 'https://github.com/davenonymous/perl-getopt-pad.git',
				web  => 'https://github.com/davenonymous/perl-getopt-pad',
			},
		},
		dynamic_config => 0,
		provides       => collectProvides(),
	},
	test  => { TESTS => 't/*.t' },
	clean => { FILES => 'Getopt-Pad-*' },
);

sub MY::postamble {
	return <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if any module's
# $VERSION differs from the one in lib/Getopt/Pad.pm, or if a tag for
# the current $(VERSION) already exists. See RELEASING.md.
#
# disttest and dist run as separate sub-makes on purpose: as
# prerequisites of one target they would share a single distdir
# build, and the tarball would pack the blib/ that disttest left
# behind. PAUSE refuses to index such a tarball.

.PHONY: release release-check version-check

version-check :
	@perl -ne 'if (/^\s*our \$$VERSION\s*=\s*\x27([^\x27]*)\x27/ && $$1 ne "$(VERSION)") { print "ERROR: $$ARGV has \$$VERSION $$1, expected $(VERSION)\n"; $$failed = 1 } END { exit($$failed ? 1 : 0) }' $$(find lib -name '*.pm')

release-check : version-check
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Getopt/Pad.pm and the other modules."; \
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
	@if tar tzf $(DISTVNAME).tar.gz | grep -qE '/(blib/|Makefile$$|MYMETA\.|pm_to_blib)'; then \
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
