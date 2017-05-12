use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Ham::APRS::FAP',
    'VERSION_FROM'	=> 'FAP.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Date::Calc' => '5.00',
        'Math::Trig' => '1.00',
        'Test::More' => '0.1'
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM   => 'FAP.pm', # retrieve abstract from module
       AUTHOR          => 'Tapio Sokura <tapio.sokura@iki.fi>, Heikki Hannikainen',
       LICENSE        => 'perl',
      ) : ()
    ),
);
