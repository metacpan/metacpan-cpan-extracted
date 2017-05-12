# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    MIN_PERL_VERSION   => '5.6.0',
    NAME               => 'Games::Dukedom',
    AUTHOR             => 'Jim Bacon <jim@nortx.com>',
    VERSION_FROM       => 'lib/Games/Dukedom.pm',
    ABSTRACT_FROM      => 'lib/Games/Dukedom.pm',
    LICENSE            => 'Perl',
    PL_FILES           => {},
    EXE_FILES          => ['bin/dukedom'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {

        # NOTE the use of quotes around non-numeric strings!
        #'Foo::Bar::Module' => 0,
        #'Foo::Bar::Module' => 5.004001,
        #'Foo::Bar::Module' => '5.4.1',
        #'Foo::Bar::Module' => 'v5.4.1',
        'Moo'                     => 1.004003,
        'MooX::StrictConstructor' => 0,
        'MooX::ClassAttribute'    => 0,
        'MooX::Struct'            => 0,
        'Throwable'               => 0,
        'Try::Tiny'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Games-Dukedom-*' },
    META_MERGE => { no_index => { directory => [qw( xt )] } },
);
