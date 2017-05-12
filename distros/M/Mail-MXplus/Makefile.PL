use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::MXplus',
    'VERSION_FROM'	=> 'MXplus.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Net::DNS' => 0.34 }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MXplus.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Nelson <scottn@he.net>') : ()),
);
