use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Calendar::Simple',
    'VERSION_FROM'	=> 'HTML/Calendar/Simple.pm', # finds $VERSION
    'PREREQ_PM'		=> { Date::Simple => '1.03',
                             CGI          => '2.752',
                             Test::More   => '0.40', },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HTML/Calendar/Simple.pm', # retrieve abstract from module
       AUTHOR     => 'Stray Toaster <coder@straytoaster.co.uk>') : ()),
);
