use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Inline::WSC',
    VERSION_FROM      => 'lib/Inline/WSC.pm', # finds $VERSION
    PREREQ_PM         => {
      Test::More      => 0.1,
      Test::Exception => 0.1,
      Win32::OLE      => 0.1,
      Digest::MD5     => 2.0,
      Sub::Uplevel    => 0.10,
      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Inline/WSC.pm', # retrieve abstract from module
       AUTHOR         => 'John Drago <jdrago_999@yahoo.com>') : ()),
);
