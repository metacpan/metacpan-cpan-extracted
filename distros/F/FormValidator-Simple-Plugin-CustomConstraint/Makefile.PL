use 5.012004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::CustomConstraint',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/CustomConstraint.pm',
    PREREQ_PM         => { 'FormValidator::Simple' => 0.29 },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/FormValidator/Simple/Plugin/CustomConstraint.pm',
       AUTHOR         => 'Alex Pavlovic <alex.pavlovic@taskforce-1.com>') : ()),
);
