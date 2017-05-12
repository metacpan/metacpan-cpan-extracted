require 5.004_04;

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Lingua::FI::Hyphenate',
	      'VERSION_FROM' => 'lib/Lingua/FI/Hyphenate.pm',
	      'dist'         => { 'COMPRESS' => 'gzip' },
	      );
