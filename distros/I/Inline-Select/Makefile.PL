use ExtUtils::MakeMaker ;

WriteMakefile(
    'NAME'		=> 'Inline::Select',
    'VERSION_FROM'	=> 'Select.pm',
	clean => {
		FILES => "_Inline"
	}
);
