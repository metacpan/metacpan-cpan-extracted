use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Exception::Sink',
    VERSION_FROM      => 'lib/Exception/Sink.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Exception/Sink.pm', # retrieve abstract from module
    AUTHOR            => 'Vladi Belperchinov-Shabanski <cade@cpan.org>',
    LICENSE           => 'gpl_2',
    MIN_PERL_VERSION  => '5.008008',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    TEST_REQUIRES     => { 'Test::More' => 0 },
    test              => { TESTS => 't/*.t t/*.pl' },
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/cade-vs/perl-exception-sink.git',
                web  => 'https://github.com/cade-vs/perl-exception-sink',
            },
        },
    },
);
