use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'File::Meta::Cache',
  VERSION_FROM      => 'lib/File/Meta/Cache.pm', 
  PREREQ_PM         => {
    enum=>0,
    "Object::Pad"=>"0.78",
    "Log::OK"=>0,
    "Log::ger"=>0
  }, 
  ABSTRACT_FROM     => 'lib/File/Meta/Cache.pod', 
  AUTHOR            => 'Ruben Westerberg <drclaw@local>',
  LICENSE           => 'mit',
  META_ADD => {
    "meta-spec" => {
      version => 2
    },
    resources=> {
      repository =>{
        type => "git",
        url => "git://github.com/drclaw1394/perl-file-meta-cache.git",
        web => "http://github.com/drclaw1394/perl-file-meta-cache",
      }
    }
  }

);
