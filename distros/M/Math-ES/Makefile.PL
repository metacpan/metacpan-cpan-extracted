use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'            => 'Anselm H. C. Horn (Anselm.Horn@chemie.uni-erlangen.de)',      
    'NAME'		=> 'Math::ES',
    'VERSION_FROM'	=> 'ES.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             'Math::Random' => 0,
			     }, 
);
