use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Log4perl::Layout::GELF',
    AUTHOR              => q{Jason Pope <cowholio4@gmail.com>},
    VERSION_FROM        => 'lib/Log/Log4perl/Layout/GELF.pm',
    ABSTRACT_FROM       => 'lib/Log/Log4perl/Layout/GELF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => '0',
	    'JSON::XS'   => '2.30',
        'IO::Compress::Gzip' => '2.00',
	    'Log::Log4perl' => '1.33'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Log4perl-Layout-GELF-*' },
);
