use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GCT::XSP::ActionTaglib',
    'VERSION_FROM'	=> 'ActionTaglib.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ActionTaglib.pm', # retrieve abstract from module
       AUTHOR     => 'Adam Griffiths, <adam@goldcrosstechnical.co.uk>') : ()),
        PREREQ_PM   => {
	'Apache::AxKit::Language::XSP'	=> '0', # or a minimum workable version
        }
);
