use ExtUtils::MakeMaker;

WriteMakefile(
	($] ge '5.006001') ?
	(
		AUTHOR => 'Luke Palmer (fibonaci@babylonia.flatirons.org)',
		ABSTRACT => 'Query a database in predicate calculus form',
	) : (),
	dist  => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	DISTNAME => 'Math-Logic-Predicate',
	NAME => 'Math::Logic::Predicate',
	PM => { 'Predicate.pm' => '$(INST_LIBDIR)/Predicate.pm',
		'Predicate.pod' => '$(INST_LIBDIR)/Predicate.pod' },
	PREREQ_PM => { 'Parse::RecDescent' => 0 },
	VERSION => '0.03'
); 
