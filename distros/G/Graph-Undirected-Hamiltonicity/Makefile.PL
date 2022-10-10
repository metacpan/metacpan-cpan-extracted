use 5.18.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Graph::Undirected::Hamiltonicity',
    AUTHOR           => q{Ashwin Dixit <ashwin@cpan.org>},
    VERSION_FROM     => 'lib/Graph/Undirected/Hamiltonicity.pm',
    ABSTRACT_FROM    => 'lib/Graph/Undirected/Hamiltonicity.pod',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => v5.18.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Graph'               => '0.9',   # '0.9704',
        'Exporter'            => '5',     # '5.68',
        'LWP::UserAgent'      => '6',     # '6.15'
        'Config::INI::Reader' => '0.025',
        'Carp'                => '1.29',
        'Test::More'          => '0.98',
        'Test::Exception'     => '0',     # '0.43',
        'CGI::Minimal'        => '1.29',
        'Modern::Perl'        => '1',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Graph-Undirected-Hamiltonicity-*' },
    test => { TESTS => join ' ', map { glob } qw( t/*.t t/*/*.t ) },
);
