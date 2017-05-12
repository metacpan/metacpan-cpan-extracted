use ExtUtils::MakeMaker;
WriteMakefile(
	NAME			=> 'HTML::Detoxifier',
	VERSION_FROM	=> 'lib/HTML/Detoxifier.pm',
	PREREQ_PM		=> {
		'HTML::TokeParser'	=> 0,
		'HTML::Entities'	=> 0
	}
);	
