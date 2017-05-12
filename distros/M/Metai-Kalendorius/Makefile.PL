use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Metai::Kalendorius',
	VERSION_FROM	=> 'lib/Metai/Kalendorius.pm',
	PREREQ_PM	=> {},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/Metai/Kalendorius.pm',
	 AUTHOR         => 'Algirdas R. <algirdas@perl.lt>') : ()),
);

