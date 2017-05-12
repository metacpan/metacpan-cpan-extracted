use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::DxExtractor',
    VERSION_FROM      => 'lib/Lingua/DxExtractor.pm', # finds $VERSION
    PREREQ_PM         => {
	'Text::Sentence' => 0.006,
	'Class::MakeMethods' => 1,
	'Lingua::NegEx' => 0.05,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/DxExtractor.pm', # retrieve abstract from module
       AUTHOR         => 'Eduardo Iturrate <ed@iturrate.com>') : ()),
);
