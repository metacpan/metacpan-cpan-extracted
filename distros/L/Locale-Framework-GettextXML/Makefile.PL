use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Locale::Framework::GettextXML',
    'VERSION_FROM'	=> 'lib/Locale/Framework/GettextXML.pm', # finds $VERSION
    'PREREQ_PM'		=> { XML::RAX => 0.01, Locale::Framework => 0.06 }, 
    'ABSTRACT_FROM'     => 'lib/Locale/Framework/GettextXML.pm', # retrieve abstract from module
    'AUTHOR'            => 'Jeff Buchbinder <freemed@gmail.com>',
);
