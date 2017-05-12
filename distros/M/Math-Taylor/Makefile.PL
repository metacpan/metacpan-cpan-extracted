use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Taylor',
    VERSION_FROM      => 'lib/Math/Taylor.pm', # finds $VERSION
    PREREQ_PM         => {
    'Math::Symbolic' => '0.128',
    'Test::Pod::Coverage' => '0',
    'Test::More' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Taylor.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>') : ()),
);
