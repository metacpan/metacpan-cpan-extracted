use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Log::Log4perl::Appender::Elasticsearch',
    AUTHOR             => q{Alexei Pastuchov<palik@cpan.org>},
    VERSION_FROM       => 'lib/Log/Log4perl/Appender/Elasticsearch.pm',
    ABSTRACT_FROM      => 'lib/Log/Log4perl/Appender/Elasticsearch.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0.98, },
    PREREQ_PM          => {
        'HTTP::Headers'  => 6.05,
        'HTTP::Request'  => 6.00,
        'JSON'           => 2.61,
        'LWP::UserAgent' => 6.05,
        'Log::Log4perl'  => 1.41,
        'MIME::Base64'   => 3.13,
        'URI'            => 1.60,
        'version'        => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Log4perl-Appender-Elasticsearch-*' },
);
