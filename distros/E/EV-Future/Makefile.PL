use 5.010000;
use ExtUtils::MakeMaker;
use EV::MakeMaker qw(ev_args);

WriteMakefile(ev_args(
    NAME              => 'EV::Future',
    VERSION_FROM      => 'lib/EV/Future.pm',
    PREREQ_PM         => { 'EV' => '4.37' },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'EV'                  => '4.37',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    ABSTRACT_FROM     => 'lib/EV/Future.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.010000',
    PM                => { 'lib/EV/Future.pm' => '$(INST_LIB)/EV/Future.pm' },
    OBJECT            => '$(O_FILES)',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-future.git',
                web  => 'https://github.com/vividsnow/perl5-ev-future',
            },
        },
    },
));
