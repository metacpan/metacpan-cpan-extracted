use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MasonX::Request::HTMLTemplate',
    'VERSION_FROM'	=> 'HTMLTemplate.pm', 
    'PREREQ_PM'		=> {	
							'HTML::Mason' => 1.16,
   							'HTML::Template::Extension' => 0.23,
   							'Params::Validate' => 0,
   							'File::Spec' => 0,
												}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HTMLTemplate.pod', # retrieve abstract from module
       AUTHOR     => 'Emiliano Bruni <info@ebruni.it>') : ()),
);
