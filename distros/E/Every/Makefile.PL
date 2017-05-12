use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Every',
	VERSION_FROM  => 'lib/Every.pm',
	ABSTRACT_FROM => 'lib/Every.pm',
	AUTHOR        => 'Ted Zlatanov <tzz@lifelogs.com>',
	PREREQ_PM     => { 
                          'Devel::Callsite' => 0.04, 
                         },
);
