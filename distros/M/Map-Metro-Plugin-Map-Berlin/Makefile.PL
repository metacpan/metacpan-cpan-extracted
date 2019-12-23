use strict;
use 5.016000; # because Map::Metro requires this version
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";

WriteMakefile(
    NAME               => 'Map::Metro::Plugin::Map::Berlin',
    AUTHOR             => q{Slaven Rezic <srezic@cpan.org>},
    VERSION_FROM       => 'lib/Map/Metro/Plugin/Map/Berlin.pm',
    ABSTRACT_FROM      => 'lib/Map/Metro/Plugin/Map/Berlin.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose::Role'             => 0,
        'Path::Tiny'              => 0,
        'Types::Path::Tiny'       => 0,
        'File::ShareDir'          => 0,
        'Map::Metro'              => 0.2403, # versions before 0.2200 are too slow; really depends on Map::Metro::Plugin::Map, but version not defined here; 0.2401 and 0.2402 had dependency bugs
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/eserte/Map-Metro-Plugin-Map-Berlin.git',
                web  => 'https://github.com/eserte/Map-Metro-Plugin-Map-Berlin',
            },
        }})
     : ()
    ),
);

sub MY::postamble {
    my $self = shift;
    my @ret = <<'EOF';

BBBIKE_DIR=	$(HOME)/src/bbbike
BBBIKE_DATADIR= $(BBBIKE_DIR)/data

build-map: share/map-berlin.metro

share/map-berlin.metro: $(BBBIKE_DATADIR)/ubahn $(BBBIKE_DATADIR)/sbahn $(BBBIKE_DATADIR)/ubahnhof $(BBBIKE_DATADIR)/sbahnhof \
			$(BBBIKE_DIR)/miscsrc/create_map_tube_xml.pl Makefile
	mkdir -p share
	$(BBBIKE_DIR)/miscsrc/create_map_tube_xml.pl --ubahn --sbahn --output-format=Map::Metro > share/map-berlin.metro~
	mv share/map-berlin.metro~ share/map-berlin.metro

EOF
    push @ret, File::ShareDir::Install::postamble($self);
    if ($is_devel_host) {
	push @ret, <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    join "\n", @ret;
}
