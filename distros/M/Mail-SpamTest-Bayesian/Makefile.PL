use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::SpamTest::Bayesian',
    'VERSION_FROM'	=> 'Bayesian.pm', # finds $VERSION
    'PREREQ_PM'		=> {BerkeleyDB => 0.17,
                            MIME::Parser => 5.406}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Bayesian.pm', # retrieve abstract from module
       AUTHOR     => 'Roger Burton West <roger@firedrake.org>') : ()),
);
