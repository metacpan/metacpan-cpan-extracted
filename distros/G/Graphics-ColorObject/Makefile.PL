use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Graphics::ColorObject',
    'VERSION_FROM'	=> 'ColorObject.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Graphics::ColorNames' => '0.32' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ColorObject.pm', # retrieve abstract from module
       AUTHOR     => 'Alex Izvorski <izv@dslextreme.com>') : ()),
);
