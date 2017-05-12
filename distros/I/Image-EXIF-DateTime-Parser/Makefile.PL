# Image::EXIF::DateTime::Parser - parser for EXIF date/time strings
# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'Image::EXIF::DateTime::Parser',
	'VERSION_FROM'	=> 'lib/Image/EXIF/DateTime/Parser.pm',
	PREREQ_PM => {
		'Test::Exception' => 0,
		'Test::use::ok' => 0,
	}
);
