use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Hash::MultiKey',
    'VERSION_FROM'  => 'MultiKey.pm',
    'PREREQ_PM'		=> {'Test::More' => 0, 'Carp' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MultiKey.pm', # retrieve abstract from module
       AUTHOR        => 'Xavier Noria (FXN), Benjamin Goldberg (GOLDBB)') : ()),
);
