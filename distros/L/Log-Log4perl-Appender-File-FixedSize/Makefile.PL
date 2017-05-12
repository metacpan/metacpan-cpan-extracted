use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Log4perl::Appender::File::FixedSize',
    AUTHOR              => q{Gligan Calin Horea <gliganh@gmail.com>},
    VERSION_FROM        => 'lib/Log/Log4perl/Appender/File/FixedSize.pm',
    ABSTRACT_FROM       => 'lib/Log/Log4perl/Appender/File/FixedSize.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Log::Log4perl' => 0,
		'File::RoundRobin' => 0.03,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Log4perl-Appender-File-FixedSize-*' },
);
