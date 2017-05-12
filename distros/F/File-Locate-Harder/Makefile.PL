use 5.8.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::Locate::Harder',
    VERSION_FROM      => 'lib/File/Locate/Harder.pm', # finds $VERSION
    PREREQ_PM         => {
                          File::Locate    => 0.62,
                          Test::Trap      => 'v0.0.22',
                          Class::Base     => 0.03,
                          Carp            => 0,
                          Data::Dumper    => 0,
                          Hash::Util      => 0,
                          FindBin         => 0,
                          Symbol          => 0,
                         },
    ($] >= 5.005 ?     ## new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Locate/Harder.pm', # get from module
       AUTHOR         => 'Joseph Brenner <doom@>') : ()),
);

