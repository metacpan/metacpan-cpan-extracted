use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Mail::RBL',
    'VERSION_FROM'	=> 'RBL.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Test::More'	=> 0,
	'Net::DNS'	=> 0,
	'NetAddr::IP'	=> 3.26,
    }, # e.g., Module::Name => 1.1

	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'RBL.pm',
		AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),

);
