use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "Finance::MICR::GOCR::Check",
	VERSION_FROM	=> 'lib/Finance/MICR/GOCR/Check.pm',
	PREREQ_PM 		=> {
		Cwd => 0,
		'File::Which' => 0,
		'File::PathInfo' => 0,
		'File::Path' => 0,
		'Smart::Comments' => 0,
		'Test::Simple' => 0,
		'Image::Magick' => 0,
		'Finance::MICR::LineParser' => '1.06',	
		'File::Copy' => 0,
		'Imager' => '0.54',
		'YAML' => '0.58',
		'File::Type' => 0,
		
	},

	EXE_FILES => ['bin/checkscan'],
	

);
