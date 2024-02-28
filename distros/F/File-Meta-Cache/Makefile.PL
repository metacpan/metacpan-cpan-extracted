use 5.024000;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'File::Meta::Cache',
  VERSION_FROM      => 'lib/File/Meta/Cache.pm', 
  PREREQ_PM         => {
    "Object::Pad"=>"0.808",
    "Log::OK"=>"v0.2.1",
    "Log::ger"=>0,
    "constant::more"=>"v0.3.0",

  }, 
  ABSTRACT_FROM     => 'lib/File/Meta/Cache.pod', 
  AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
  LICENSE           => 'mit',
  META_ADD => {
    "meta-spec" => {
      version => 2
    },
    resources=> {
      repository =>{
        type => "git",
        url => "git://github.com/drclaw1394/perl-file-meta-cache.git",
        web => "https://github.com/drclaw1394/perl-file-meta-cache",
      }
    }
  }

);
