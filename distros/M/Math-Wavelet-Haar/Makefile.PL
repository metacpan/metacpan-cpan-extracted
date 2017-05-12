use 5.005005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Wavelet::Haar',
    VERSION_FROM      => 'lib/Math/Wavelet/Haar.pm', # finds $VERSION
    PREREQ_PM         => {Storable => 2.15}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Wavelet/Haar.pm', # retrieve abstract from module
       AUTHOR         => 'Ryan Voots <simcop2387@yahoo.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
