use ExtUtils::MakeMaker;
WriteMakefile(
	ABSTRACT	=> 'Graph layouting and rendering.',
	AUTHOR		=> 'Petr Baudis <pasky\@ucw.cz>',
	DISTNAME	=> 'Graph-Layderer',
	INSTALLDIRS	=> 'site',
	NAME		=> 'Graph::Layouter',
	PL_FILES	=> {},
	PREREQ_PM	=>
		{
			Graph	=> 0,
			Imager	=> 0
		},
	VERSION_FROM	=> 'lib/Graph/Layouter.pm'
);
