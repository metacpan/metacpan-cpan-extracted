use 5.8.6;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::Monitor::Lite',
    VERSION_FROM      => 'lib/File/Monitor/Lite.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Monitor/Lite.pm', # retrieve abstract from module
       AUTHOR         => 'dryman <dryman@apple.com>') : ()),
    PREREQ_PM         => {
      "File::Monitor" => 0,
      "File::Find::Rule" => 0,
      "File::Touch" => 0,
      "File::Spec::Functions" => 0,
      "Class::Accessor::Fast" => 0,
    }
);
