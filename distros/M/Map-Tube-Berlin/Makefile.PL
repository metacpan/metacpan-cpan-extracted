use strict;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";

my $build_requires = {
    BUILD_REQUIRES => {
        'Test::More' => 0
    },
};
my $prereq_pm = {
    PREREQ_PM => {
        'Moo'              => 0,
        'namespace::clean' => 0,
        'File::Share'      => 0,
        'Map::Tube'        => '3.62',
    }
};

eval { ExtUtils::MakeMaker->VERSION(6.64) } ?
 ($build_requires->{TEST_REQUIRES} = { 'Test::Map::Tube' => '0.35' })
 :
 ($prereq_pm->{PREREQ_PM}->{'Test::Map::Tube'} = '0.35');

WriteMakefile(
    NAME               => 'Map::Tube::Berlin',
    AUTHOR             => q{Slaven Rezic <srezic@cpan.org>},
    VERSION_FROM       => 'lib/Map/Tube/Berlin.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Berlin.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => 0,
    },
    %$build_requires,
    %$prereq_pm,
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/eserte/Map-Tube-Berlin.git',
                web  => 'https://github.com/eserte/Map-Tube-Berlin',
            },
        }})
     : ()
    ),
);

sub MY::postamble {
    my $self = shift;
    my @ret = <<'EOF';

# NOTE: for rebuilding the map it's necessary to checkout the bbbike
# source code:
#
#    git clone https://github.com/eserte/bbbike.git ~/src/bbbike
#
# You can do the checkout also to another local directory, but in this
# case it's necessary to set the make variable BBBIKE_DIR, e.g.
#
#    make build-map BBBIKE_DIR=/path/to/bbbike

BBBIKE_DIR=	$(HOME)/src/bbbike
BBBIKE_DATADIR= $(BBBIKE_DIR)/data

build-map: share/berlin-map.xml

share/berlin-map.xml: $(BBBIKE_DATADIR)/ubahn $(BBBIKE_DATADIR)/sbahn $(BBBIKE_DATADIR)/ubahnhof $(BBBIKE_DATADIR)/sbahnhof inc/berlin-map-lines.inc $(BBBIKE_DIR)/miscsrc/create_map_tube_xml.pl
	mkdir -p share
	$(BBBIKE_DIR)/miscsrc/create_map_tube_xml.pl --include-lines=inc/berlin-map-lines.inc --additional-comment "DO NOT EDIT, please follow instructions in Makefile.PL and re-run 'make build-map'" > share/berlin-map.xml~
	mv share/berlin-map.xml~ share/berlin-map.xml

EOF
    push @ret, File::ShareDir::Install::postamble($self);
    if ($is_devel_host) {
	push @ret, <<'EOF';

show-map-stations-diff:
	git show HEAD:share/berlin-map.xml | grep '<station ' | perl -pe 's/ link=".*?"//; s/ other_link=".*?"//; s/ id="S\d+"//;' | psort -e '/name="(.*?)"/; $$1' > /tmp/map-tube-berlin.old
	cat share/berlin-map.xml           | grep '<station ' | perl -pe 's/ link=".*?"//; s/ other_link=".*?"//; s/ id="S\d+"//;' | psort -e '/name="(.*?)"/; $$1' > /tmp/map-tube-berlin.new
	diff -u /tmp/map-tube-berlin.old /tmp/map-tube-berlin.new

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    join "\n", @ret;
}
