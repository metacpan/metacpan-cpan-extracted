use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FWS::V2',
    AUTHOR              => q{Nate Lewis <nlewis@gnetworks.com>},
    VERSION_FROM        => 'lib/FWS/V2.pm',
    ABSTRACT_FROM       => 'lib/FWS/V2.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 		=> 0,
        'DBI' 			=> 0,
        'CGI' 			=> 0,
        'Time::Local'		=> 0,
        'Storable'		=> 0,
        'Crypt::Blowfish'	=> 0,
        'GD'			=> 0,
	'Digest::SHA1'  	=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FWS-V2-*' },
);
