use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::ES::PhT',
    VERSION_FROM      => 'lib/Lingua/ES/PhT.pm', # finds $VERSION
    PREREQ_PM         => {Lingua::ES::Syllabify => 0.9, String::Multibyte => 0.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/ES/PhT.pm', # retrieve abstract from module
       AUTHOR         => 'Alberto Montero <alberto@>') : ()),
);
