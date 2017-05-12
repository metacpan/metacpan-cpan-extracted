use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Finance::Bank::ABSA',
    'VERSION_FROM'	=> 'ABSA.pm', # finds $VERSION
    'AUTHOR'        => 'Leon Cowle <leon@leolizma.com>', 
    'PREREQ_PM'		=> { WWW::Mechanize => 0, HTML::TokeParser => 0 }
);
