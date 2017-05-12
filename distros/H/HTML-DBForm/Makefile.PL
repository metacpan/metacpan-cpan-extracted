use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'HTML::DBForm',
    'VERSION_FROM'	=> 'lib/HTML/DBForm.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
					HTML::SuperForm => 1.04,
    				Class::Factory => 0,		
    				HTML::Template => 0,		
					DBI => 0,
			},
    'LIBS'              => [''], # e.g., '-lm'

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( AUTHOR     => 'Ken Railey <ken_railey@yahoo.com>') : ()),
);
