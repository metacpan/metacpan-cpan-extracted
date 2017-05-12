use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Language::XSB::Register',
    'VERSION_FROM'	=> 'Register.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'Register.pm', # retrieve abstract from module
    'AUTHOR'     => 'Salvador Fandiño <sfandino@yahoo.com>',
);
