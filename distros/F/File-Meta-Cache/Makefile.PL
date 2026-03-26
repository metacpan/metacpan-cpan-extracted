use 5.024000;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'File::Meta::Cache',
  VERSION_FROM      => 'lib/File/Meta/Cache.pm', 
	MIN_PERL_VERSION => '5.24.0',
  PREREQ_PM         => {
    "Object::Pad"=>"0.808",
    "constant::more"=>"v0.3.0",
    "File::Path::Redirect" => "v0.1.3"

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
