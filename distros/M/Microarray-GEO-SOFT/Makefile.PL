use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Microarray::GEO::SOFT',
	VERSION_FROM  => 'lib/Microarray/GEO/SOFT.pm',
	PREREQ_PM     => {
		'List::Vectorize' => '1.00',
		'Microarray::ExprSet' => '0.11',
		'File::Basename' => 0,
		'LWP::UserAgent' => 0,
		'Time::HiRes' => 0,
		'Test::More' => 0,
		'Cwd' => 0,
		'Carp' => 0,
		'Getopt::Long' => 0,
	},
	EXE_FILES     => ["bin/getgeo"], 
	AUTHOR        => 'Zuguang Gu <jokergoo@gmail.com>',
	ABSTRACT      => 'Reading microarray data in SOFT format from GEO database',
	LICENSE       => 'perl',
);
