use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'HTML::LinkAdd',
    'VERSION_FROM'	=> 'LinkAdd.pm',
    'PREREQ_PM'		=> {
	'HTML::TokeParser' => 0,
	},
);
