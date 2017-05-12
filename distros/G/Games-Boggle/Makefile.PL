use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Games::Boggle',
	AUTHOR     => 'Tony Bowden <kasei@tmtm.com>',
	VERSION_FROM => 'lib/Games/Boggle.pm', 
	ABSTRACT_FROM => 'lib/Games/Boggle.pm', 
	PREREQ_PM => { 
		'Test::More' => 0.45,
	}, 
);
