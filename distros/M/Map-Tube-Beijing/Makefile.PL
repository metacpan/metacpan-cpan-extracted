use strict;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Map::Tube::Beijing',
    AUTHOR             => q{Gisbert W. Selke <gws@cpan.org>},
    VERSION_FROM       => 'lib/Map/Tube/Beijing.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Beijing.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => { },
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
                           'ExtUtils::MakeMaker' => 6.64,
                           'File::ShareDir::Install' => 0,
                          },
    TEST_REQUIRES     => {
                           'Test::More' => 0.82,
                          },
    PREREQ_PM          => {
                           'Moo'              => 0,
                           'namespace::clean' => 0,
                           'File::Share'      => 0,
                           'Map::Tube'        => '2.85',
                          },
    dist               => {
                            COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                          },
    clean              => {
                            FILES => 'Map-Tube-Beijing-*',
                          },
    META_MERGE         => {
                            'meta-spec' => { version => 2 },
                            'provides'  => {
                                             'Map::Tube::Beijing' => {
                                                                       file => 'lib/Map/Tube/Beijing.pm',
                                                                       version => '0.01',
                                                                     },
                                           },
                          },
);

package MY;
use File::ShareDir::Install 'postamble';
