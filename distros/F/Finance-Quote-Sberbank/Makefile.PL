use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Quote::Sberbank',
    VERSION_FROM      => 'lib/Finance/Quote/Sberbank.pm', # finds $VERSION
    PREREQ_PM         => { Finance::Quote => 0, Spreadsheet::ParseExcel => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Quote/Sberbank.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Korolyoff <kilork@yandex.ru>') : ()),
);
