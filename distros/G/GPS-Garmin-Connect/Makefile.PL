use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GPS::Garmin::Connect',
    AUTHOR              => 'Herbert Poul <hpoul@cpan.org>',
    VERSION_FROM        => 'lib/GPS/Garmin/Connect.pm',
    ABSTRACT_FROM       => 'lib/GPS/Garmin/Connect.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Simple' => 0,
	'JSON' => '2.00',
	'LWP::UserAgent' => 0,
	'HTML::Form' => 0,
        'Error' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GPS-Garmin-Connect-*' },
);
