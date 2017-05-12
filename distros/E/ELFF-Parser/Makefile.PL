use 5.0;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'ELFF::Parser',
	VERSION_FROM	=> 'lib/ELFF/Parser.pm',
	PREREQ_PM	=> {
		'Carp' => 1.0,
	},
	($] >= 5.005 ? ( ## Add these new keywords supported since 5.005
		ABSTRACT_FROM	=> 'lib/ELFF/Parser.pm',
		AUTHOR		=> 'Mark Warren <mwarren42@gmail.com>'
	) : ()),
	LIBS		=> [''],
	DEFINE		=> '',
	INC		=> '-I.',

	# Un-comment this if you add C files to link with later:
	# OBJECT	=> '$(O_FILES)', # link all the C files too
);
