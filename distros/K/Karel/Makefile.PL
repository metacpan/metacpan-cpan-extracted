use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Karel',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/Karel.pm',
    ABSTRACT_FROM    => 'lib/Karel.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',  # TEST_REQUIRES
    },
    TEST_REQUIRES => {
        'Test::Spec' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        Cwd                 => 0,
        'Syntax::Construct' => 0,
        Moo                 => 0,
        'namespace::clean'  => 0,
        Clone               => 0,
        constant            => 0,
        'List::Util'        => '1.33',  # any, none
        'Marpa::R2'         => '2.084', # latm
        'Module::Load'      => 0,
        Carp                => 0,
        Exporter            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    macro => { TARFLAGS => '--format=ustar -cvf' },
    clean => { FILES => 'Karel-*' },
);

