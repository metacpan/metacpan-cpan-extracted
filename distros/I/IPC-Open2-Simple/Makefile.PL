use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IPC::Open2::Simple',
    AUTHOR           => 'Olivier Duclos <odc@cpan.org>',
    VERSION_FROM     => 'lib/IPC/Open2/Simple.pm',
    ABSTRACT_FROM    => 'lib/IPC/Open2/Simple.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'       => 0,
        'Exporter'   => 0,
        'IO::Handle' => 0,
        'IPC::Open2' => 0,
    },
    META_MERGE       => {
        requires     => { perl => '5.006' },
        resources    => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository => 'http://github.com/oliwer/IPC-Open2-Simple',
            bugtracker => 'http://github.com/oliwer/IPC-Open2-Simple/issues'
        },
        no_index     => { directory => ['t'] }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IPC-Open2-Simple-*' },
);
