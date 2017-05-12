use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Pngslimmer',
    VERSION_FROM      => 'lib/Image/Pngslimmer.pm', # finds $VERSION
    PREREQ_PM         => {POSIX => 1.08, Compress::Zlib => 2.003, Compress::Raw::Zlib => 2.003}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/Pngslimmer.pm', # retrieve abstract from module
       AUTHOR         => 'Adrian McMenamin <adrian@mcmen.demon.co.uk>',
       LICENSE	      => 'perl') : ()),
);
