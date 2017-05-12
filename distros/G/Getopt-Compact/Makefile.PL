use ExtUtils::MakeMaker;

WriteMakefile
    ('NAME'		=> 'Getopt::Compact',
     'VERSION_FROM'	=> 'lib/Getopt/Compact.pm',
     'PREREQ_PM'	=> {
                        Carp => 0,
                        Getopt::Long => 0,
                        Text::Table => 0,
			File::Spec => 0,
			File::Basename => 0,
			Pod::Parser => 0,
			Pod::Simple::Text::Termcap => 0,
			Env::Path => 0,
                       },
     ABSTRACT_FROM => 'lib/Getopt/Compact.pm',
     AUTHOR     => 'Andrew Stewart Williams',
);
