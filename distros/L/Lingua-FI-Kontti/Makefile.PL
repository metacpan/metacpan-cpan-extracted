require 5.004_04;

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Lingua::FI::Kontti',
	      'VERSION_FROM' => 'lib/Lingua/FI/Kontti.pm',
	      'PREREQ_PM'    => { 'Lingua::FI::Hyphenate' => 0 },
	      'dist'         => { 'COMPRESS' => 'gzip' },
	      );
