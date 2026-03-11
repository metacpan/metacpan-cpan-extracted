use 5.024000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'File::Path::Redirect',
    VERSION_FROM      => 'lib/File/Path/Redirect.pm', # finds $VERSION, requires EU::MM from perl >= 5.5

	  MIN_PERL_VERSION => '5.24.0',

    PREREQ_PM         => {
      "constant::more"  => 0,
      "Export::These"   => v0.3.0,

    }, 
    ABSTRACT_FROM     => 'lib/File/Path/Redirect.pm', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
      "meta-spec" => {
        version => 2
      },
      resources=> {
        repository =>{
          type => "git",
          url => "git://github.com/drclaw1394/perl-file-path-redirect.git",
          web => "https://github.com/drclaw1394/perl-file-path-redirect",
        }
      }
    }

);
