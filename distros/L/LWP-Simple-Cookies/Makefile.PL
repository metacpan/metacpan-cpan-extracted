use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'LWP::Simple::Cookies',
    'VERSION_FROM'	=> 'lib/LWP/Simple/Cookies.pm',
    'PREREQ_PM'		=> { LWP::Simple => 0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/LWP/Simple/Cookies.pm', # retrieve abstract from module
       AUTHOR     => 'Josh Jore <jjore@cpan.org>') : ()),
);
