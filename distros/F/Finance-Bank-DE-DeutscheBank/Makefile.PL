use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Finance::Bank::DE::DeutscheBank',
    'VERSION_FROM'	=> 'DeutscheBank.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'WWW::Mechanize' => 1.52,
				'HTML::TreeBuilder' => 3.23,
				'HTML::LinkExtractor' => 0.13,
				'Text::CSV_XS' => 0.29,
				'Class::Accessor' => 0.31, 
			}, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DeutscheBank.pm', # retrieve abstract from module
       AUTHOR     => 'Wolfgang Schlueschen <wschl@cpan.org>') : ()),
);
