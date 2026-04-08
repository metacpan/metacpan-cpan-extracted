use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LLM::SimpleClient',
    VERSION_FROM      => 'lib/LLM/SimpleClient.pm',
    ABSTRACT          => 'Simple LLM client with multiple provider support',
    AUTHOR            => 'Konstantin Pristine <kpristine\@cpan.org>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.028',
    PREREQ_PM         => {
        'Mojo::UserAgent' => 0,
        'Log::Log4perl'   => 0,
        'JSON'            => 0,
    },
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
    clean             => { FILES => 'LLM-SimpleClient-*' },
);