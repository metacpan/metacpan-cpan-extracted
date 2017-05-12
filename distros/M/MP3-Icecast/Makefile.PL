use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Icecast',
    'VERSION_FROM'	=> 'Icecast.pm',
    'PREREQ_PM'		=> {
                            MP3::Info      => 1.02,
                            File::Spec     => 0.86,
                            File::Basename => 2.71,
                            URI::Escape    => 0,
                            IO::File       => 1.09,
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Icecast.pm',
       AUTHOR     => 'Allen Day <allenday@ucla.edu>') : ()),
);
