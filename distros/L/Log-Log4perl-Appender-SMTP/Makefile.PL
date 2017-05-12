use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Log4perl::Appender::SMTP',
    AUTHOR           => 'Olivier Duclos <odc@cpan.org>',
    VERSION_FROM     => 'lib/Log/Log4perl/Appender/SMTP.pm',
    ABSTRACT_FROM    => 'lib/Log/Log4perl/Appender/SMTP.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'        => 0,
        'Net::Domain' => 0,
        'Net::SMTP'   => 0,
    },
    META_MERGE       => {
        requires     => { perl => '5.008' },
        resources    => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository => 'http://github.com/oliwer/Log-Log4perl-Appender-SMTP',
            bugtracker => 'http://github.com/oliwer/Log-Log4perl-Appender-SMTP/issues'
        },
        no_index     => { directory => ['t'] }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Log4perl-Appender-SMTP-*' },
);
