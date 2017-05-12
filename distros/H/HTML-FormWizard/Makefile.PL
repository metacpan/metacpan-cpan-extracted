use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=>	'HTML::FormWizard',
	'VERSION_FROM'	=>  'FormWizard.pm',
	'PREREQ_PM'		=> {},
	($] >= 5.005?
		(AUTHOR			=> 'Merlin, The Mage <merlin@camelot.co.pt>'):()),
);
