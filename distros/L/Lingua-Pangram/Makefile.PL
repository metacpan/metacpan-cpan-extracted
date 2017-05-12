use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Lingua::Pangram',
    'VERSION_FROM' => 'lib/Lingua/Pangram.pm', # finds $VERSION
    'PREREQ_PM' => {
      'Test::More'    => 0.10, # need at least 0.10 for 'skip'
      'Test::Harness' => 1.02, # don't know the real minimum version needed
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Lingua/Pangram.pm', # retrieve abstract from module
       AUTHOR     =>
       'Russell Matbouli <lingua-pangram-makefile@russell.matbouli.org>') : ()),


);
