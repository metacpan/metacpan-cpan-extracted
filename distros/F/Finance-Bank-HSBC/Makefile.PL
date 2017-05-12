use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Finance::Bank::HSBC',
    'VERSION_FROM'	=> 'HSBC.pm', # finds $VERSION
    'AUTHOR'        => 'Chris Ball <chris@cpan.org>', 
    'PREREQ_PM'		=> { WWW::Mechanize => 0, HTML::TokeParser => 0 }
);
