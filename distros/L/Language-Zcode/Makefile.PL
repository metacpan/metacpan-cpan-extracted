use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Language::Zcode',
    'EXE_FILES'		=> [qw (scripts/plotz.pl)],
    'VERSION_FROM'	=> 'lib/Language/Zcode.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Language/Zcode.pm', # retrieve abstract from module
       AUTHOR     => 'Amir Karger <akarger@cpan.org>') : ()),
);
