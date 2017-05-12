use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Form::Processor::Model::CDBI',
    VERSION_FROM      => 'lib/Form/Processor/Model/CDBI.pm', # finds $VERSION
    PREREQ_PM         => {
        'Form::Processor'   => '0.11',
        'Class::DBI',       => '3.0.0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Form/Processor/Model/CDBI.pm', # retrieve abstract from module
       AUTHOR         => 'Bill Moseley') : ()),
);
