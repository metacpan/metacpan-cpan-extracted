use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FWS::Lite',
    AUTHOR              => q{Nate Lewis <nlewis@gnetworks.com>},
    VERSION_FROM        => 'lib/FWS/Lite.pm',
    ABSTRACT_FROM       => 'lib/FWS/Lite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 	=> 0,
	'DBI'		=> 0,
	'Digest::SHA1'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FWS-Lite-*' },
);
