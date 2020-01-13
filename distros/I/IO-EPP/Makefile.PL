use ExtUtils::MakeMaker;

use warnings;
use strict;

WriteMakefile(
    NAME               => 'IO::EPP',
    AUTHOR             => 'Vadim Likhota <vadiml@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/IO/EPP.pm',
    PREREQ_PM          => {
	'IO::Socket'         => 0,
	'IO::Socket::SSL'    => 0,
	'LWP::UserAgent'     => 0,
	'HTTP::Request'      => 0,
	'HTTP::Cookies'      => 0,
	'Digest::MD5'        => 0,
	'Time::HiRes'        => 0,
    },
    BUILD_REQUIRES     => {
	'Test::Spec' => 0,
	'Test::More' => 0,
    },
    test => { TESTS => 't/*.t' },
);
