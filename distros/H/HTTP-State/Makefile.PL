use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTTP::State',
    VERSION_FROM      => 'lib/HTTP/State.pm', 
    MIN_PERL_VERSION  => "5.36.0",
    PREREQ_PM         => {
      "Log::ger"=>0,
      "Log::OK"=>0,
      "Object::Pad"=>0,
      "List::Insertion"=>0,
      "Mozilla::PublicSuffix"=>0,
      "Export::These"=>0
    },

    ABSTRACT_FROM     => 'lib/HTTP/State.pod', 
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',


    META_ADD => {
      "meta-spec" => {
        version => 2
      },
      resources=> {
        repository =>{
          type => "git",
          url => "git://github.com/drclaw1394/perl-http-state.git",
          web => "http://github.com/drclaw1394/perl-http-state",
        }
      }
    }
);
