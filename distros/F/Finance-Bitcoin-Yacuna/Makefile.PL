use strict;
use warnings;

use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
	'NAME' => 'Finance::Bitcoin::Yacuna',
	'AUTHOR' => 'Andrei Martchouk <andrei@yacuna.com>',
	'LICENSE' => 'LGPL',
	'VERSION_FROM' => 'lib/Finance/Bitcoin/Yacuna.pm',
	'ABSTRACT' => 'Yacuna Bitcoin exchange trading api connector, s. http://docs.yacuna.com/api',
	'PM' => {
		'lib/Finance/Bitcoin/Yacuna.pm' => '$(INST_LIB)/Finance/Bitcoin/Yacuna.pm'
	},
	'PREREQ_PM' => {
		'WWW::Mechanize' => 0,
		'HTTP::Request' => 0,
		'MIME::Base64' => 0,
		'Digest::SHA' => 0
	},
	'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
	'clean' => {'FILES' => 'bogus'}
);
