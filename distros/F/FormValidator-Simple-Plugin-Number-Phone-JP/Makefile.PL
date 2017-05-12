use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::Number::Phone::JP',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/Number/Phone/JP.pm', # finds $VERSION
    PREREQ_PM         => {
	FormValidator::Simple => '0.03',
	Number::Phone::JP => '0.03',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FormValidator/Simple/Plugin/Number/Phone/JP.pm', # retrieve abstract from module
       AUTHOR         => 'Gosuke Miyashita <gosukenator@gmail.com>') : ()),
);
