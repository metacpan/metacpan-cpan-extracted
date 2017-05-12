use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'INSPEC', 
    'VERSION_FROM' => 'lib/INSPEC/Retriever.pm', # finds $VERSION
);
