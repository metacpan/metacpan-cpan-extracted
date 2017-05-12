use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MasonX::Lexer::MSP',
    'VERSION_FROM'	=> 'MSP.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'HTML::Mason' => 1.1 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MSP.pm', # retrieve abstract from module
       AUTHOR     => 'John Williams <williams@tni.com>') : ()),
);
