use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::QuoteOptions',
    VERSION_FROM      => 'lib/Finance/QuoteOptions.pm', # finds $VERSION
    PREREQ_PM         => {'HTML::TokeParser' => 2.28, 'WWW::Mechanize' => 1.20,
			'Date::Calc' => 5.4 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/QuoteOptions.pm', # retrieve abstract from module
       AUTHOR         => 'Kirk Bocek <quoteoptions@kbocek.com>') : ()),
);
