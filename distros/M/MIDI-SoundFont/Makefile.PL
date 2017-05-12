use ExtUtils::MakeMaker;
use 5.006_001;  # 1.16

WriteMakefile(
	NAME      => 'MIDI::SoundFont',
	VERSION_FROM => 'SoundFont.pm',
	EXE_FILES => [ glob "bin/*" ],
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Handles .sf2 SoundFont and .pat and .zip Gravis files',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
	PREREQ_PM => {   # 1.07
		'Archive::Zip' => 0,
		'File::Basename' => 0,
		'File::Format::RIFF' => 0,
		'File::Temp' => 0,
		'LWP::Simple' => 0,
		'MIDI' => 0,
		'String::Approx' => 0,
	},
);
