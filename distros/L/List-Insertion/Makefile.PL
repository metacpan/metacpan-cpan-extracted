use 5.024000;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'List::Insertion',
  VERSION_FROM      => 'lib/List/Insertion.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
  PREREQ_PM         => {
    "Template::Plex"=>"v0.5.0",
    "Data::Combination"=>0
  }, 
  MIN_PERL_VERSION => "5.24.0",
  ABSTRACT_FROM     => 'lib/List/Insertion.pod', # retrieve abstract from module
  AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
  LICENSE           => 'mit',

  META_ADD => {
    "meta-spec" => {
      version => 2
    },
    resources=> {
      repository =>{
        type => "git",
        url => "git://github.com/drclaw1394/perl5-list-insertion.git",
        web => "http://github.com/drclaw1394/perl5-list-insertion",
      }
    }
  }

);
