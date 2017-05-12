#!perl

use 5.006000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereq_pm = {
    Time::HiRes         =>  0,
    Carp                =>  0,
    Params::Validate    =>  0,
    Params::Classify    =>  0,
    Class::Accessor     =>  0,
    Test::More          =>  0,
    Test::Exception     =>  0,
    Test::Fork          =>  0,
    File::Temp          =>  0,
    Fcntl               =>  0,
}; # e.g., Module::Name => 1.1

if($^O eq 'linux' && !grep { /DIST/ } @ARGV) {
  $prereq_pm->{Linux::Fuser} = 1.5;
}

WriteMakefile(
  NAME              => 'File::Lock::Multi',
  VERSION_FROM      => 'lib/File/Lock/Multi.pm', # finds $VERSION
  LICENSE           => 'perl',
  PREREQ_PM         => $prereq_pm,
  (
    $] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (
      ABSTRACT_FROM  => 'lib/File/Lock/Multi.pm', # retrieve abstract from module
      AUTHOR         => 'Tyler MacDonald <japh@crackerjack.net>'
    ) : ()
  ),
);


