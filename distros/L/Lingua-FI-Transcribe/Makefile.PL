require 5.004_04;

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Lingua::FI::Transcribe',
	      'VERSION_FROM' => 'lib/Lingua/FI/Transcribe.pm',
	      'PREREQ_PM'    => { 'Lingua::FI::Hyphenate' => 0 },
	      'dist'         => { 'COMPRESS' => 'gzip' },
	      );
