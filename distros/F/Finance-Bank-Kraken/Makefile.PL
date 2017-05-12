# $Id: Makefile.PL 1 2014-01-22 15:03:22Z phil $

use strict;
use warnings;

use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
	'NAME' => 'Finance::Bank::Kraken',
	'AUTHOR' => 'Philippe Kueck <projects@unixadm.org>',
	'LICENSE' => 'LGPL',
	'VERSION_FROM' => 'lib/Finance/Bank/Kraken.pm',
	'ABSTRACT' => 'api.kraken.com connector',
	'PM' => {
		'lib/Finance/Bank/Kraken.pm' => '$(INST_LIB)/Finance/Bank/Kraken.pm'
	},
	'PREREQ_PM' => {
		'HTTP::Request' => 0,
		'LWP::UserAgent' => 0,
		'MIME::Base64' => 0,
		'Digest::SHA' => 0
	},
	'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
	'clean' => {'FILES' => 'bogus'}
);
