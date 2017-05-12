use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Microarray::ExprSet',
	VERSION_FROM  => 'lib/Microarray/ExprSet.pm',
	PREREQ_PM     => {
		'List::Vectorize' => "1.00",
		'Test::More' => 0,
		'Carp' => 0,
	},
	AUTHOR        => 'Zuguang Gu <jokergoo@gmail.com>',
	ABSTRACT      => 'Simple description of microarray data',
	LICENSE       => 'perl',
);
