#!/usr/bin/perl -w

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Media::Convert",
	ABSTRACT_FROM => "lib/Media/Convert.pm",
	VERSION_FROM => "lib/Media/Convert.pm",
	AUTHOR => [
		'Wouter Verhelst <w@uter.be>',
	],
	PREREQ_PM => {
		'Alien::ffmpeg' => 0,
		'JSON::MaybeXS' => 0,
		'Moose' => 0,
		'MooseX::Singleton' => 0,
		'SemVer' => 0,
		'IPC::System::Simple' => 0,
	},
	EXE_FILES => [
		'scripts/mc-encode',
	],
	TEST_REQUIRES => {
		'Test::More' => 0,
	},
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources => {
			repository => {
				type => "git",
				url => "https://salsa.debian.org/wouter/media-convert.git",
				web => "https://salsa.debian.org/wouter/media-convert",
			},
		}
	},
);
