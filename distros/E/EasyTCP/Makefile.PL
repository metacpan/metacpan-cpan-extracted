#
# $Header: /cvsroot/Net::EasyTCP/Makefile.PL,v 1.4 2002/11/03 09:06:18 mina Exp $
#
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'	=> 'Net::EasyTCP',
	'VERSION_FROM' => 'EasyTCP.pm', # finds $VERSION
	'DISTNAME' => 'EasyTCP',
	'PREREQ_PM' => {
		'IO::Socket'	=>	0,
		'IO::Select'	=>	0,
		'Storable'		=>	0,
		},
	'dist' => { COMPRESS => "gzip -9", SUFFIX => "gz" },
);

