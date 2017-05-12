use 5.8.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
   NAME              => 'List::Filter',
   VERSION_FROM      => 'lib/List/Filter.pm', # finds $VERSION
   PREREQ_PM         => {
                         Class::Base              => 0.03,
                         Module::List             => 0.001,
                         Module::List::Pluggable  => 0.01,
                         Test::Trap               => 0,
                         Test::More               => 0,
                         DBI                      => 1.0,
                         Hash::Util               => 0,
                         Carp                     => 0,
                         Env                      => 0,
                         Exporter                 => 1.0,
                         File::Basename           => 0,
                         File::Copy               => 0,
                         File::Path               => 0,
                         YAML                     => 0,
                         Memoize                  => 0,
                         FindBin                  => 0,
                         lib                      => 0,
                         base                     => 0,
                         strict                   => 0,
                         warnings                 => 0,
                         },
   ($] >= 5.005 ? ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/List/Filter.pm', # retrieve abstract from module
     AUTHOR         => 'Joseph Brenner <doom@>') : ()),
  );
