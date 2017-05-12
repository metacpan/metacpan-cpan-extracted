use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Coordinates::ETRSTM35FIN',
    VERSION_FROM      => 'lib/Geo/Coordinates/ETRSTM35FIN.pm', # finds $VERSION
    BUILD_REQUIRES         => { Test::Exception => 0.27 }, # e.g., Module::Name => 1.1
    MIN_PERL_VERSION  => 5.008006,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Coordinates/ETRSTM35FIN.pm', # retrieve abstract from module
       AUTHOR         => 'Matti Lattu <matti@lattu.biz>') : ()),
);
