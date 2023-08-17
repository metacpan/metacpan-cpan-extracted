use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Export::These',
    VERSION_FROM      => 'lib/Export/These.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Export/These.pm', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
    "meta-spec" => {
      version => 2
    },
    resources=> {
      repository =>{
        type => "git",
        url => "git://github.com/drclaw1394/perl-export-these.git",
        web => "http://github.com/drclaw1394/perl-export-these",
      }
    },
    bugtracker => {
      web => 'https://github.com/drclaw1394/perl-export-these/issues'
    },
  }



);
