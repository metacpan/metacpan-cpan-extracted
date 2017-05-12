#
# $Header: /cvsroot/WWW::Fido/Makefile.PL,v 1.5 2002/10/31 01:07:27 mina Exp $
#

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'WWW::Fido',
    'VERSION_FROM' => 'Fido.pm', # finds $VERSION
    'DISTNAME' => 'Fido',
    'PREREQ_PM' => {
	'LWP::UserAgent'	=>	0,
	'HTTP::Cookies'		=>	0,
	},
    'dist' => { COMPRESS => "gzip -9", SUFFIX => "gz" },
);
