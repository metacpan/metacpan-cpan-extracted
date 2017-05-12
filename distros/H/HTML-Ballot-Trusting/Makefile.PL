use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Ballot::Trusting',
    'VERSION_FROM'	=> 'Trusting.pm',
    'PREREQ_PM'		=> {
		HTML::EasyTemplate => 0.985,
    	CGI => 1,
    	HTML::Entities => 1,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Trusting.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.com>') : ()),
);
