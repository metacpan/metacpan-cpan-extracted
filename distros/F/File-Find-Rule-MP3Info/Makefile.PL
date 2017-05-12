use ExtUtils::MakeMaker;
use strict;

WriteMakefile( NAME         => 'File::Find::Rule::MP3Info',
	       VERSION_FROM => 'MP3Info.pm',
	       PREREQ_PM    => { 'File::Find::Rule' => '0.07',
			         'MP3::Info' => 0,
				 'Number::Compare' => 0,
			       }
              );
