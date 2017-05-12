use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LJ::GetCookieSession',
    AUTHOR              => q{Anastasiya Deeva <nastya@creograf.ru>},
    VERSION_FROM        => 'lib/LJ/GetCookieSession.pm',
    ABSTRACT_FROM       => 'lib/LJ/GetCookieSession.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::Exception'=>0,
	'WWW::Mechanize'=>0,
	'Digest::MD5'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LJ-GetCookieSession-*' },
);
