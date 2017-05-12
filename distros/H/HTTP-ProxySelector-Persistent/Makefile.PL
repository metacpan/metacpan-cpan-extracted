use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::ProxySelector::Persistent',
    AUTHOR              => 'Michael Trowbridge <michael.a.trowbridge@gmail.com>',
    VERSION_FROM        => 'lib/HTTP/ProxySelector/Persistent.pm',
    ABSTRACT_FROM       => 'lib/HTTP/ProxySelector/Persistent.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	  => 0,
	'BerkeleyDB'	  => 0,
	'LWP::UserAgent'  => 0,
	'Date::Manip'	  => 0,
	'Cwd'		  => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-ProxySelector-Persistent-*' },
);
