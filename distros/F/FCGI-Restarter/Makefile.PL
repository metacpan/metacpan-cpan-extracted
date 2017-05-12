use 5.008001;
use ExtUtils::MakeMaker;
use constant { MIN_PERL_VERSION => 5.008001 };
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FCGI::Restarter',
    VERSION_FROM      => 'lib/FCGI/Restarter.pm', # finds $VERSION
    PREREQ_PM         => { 'Class::Accessor::Tiny' => '0.10', FCGI=> 0.67}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FCGI/Restarter.pm', # retrieve abstract from module
       AUTHOR         => 'Grishaev Anatoliy  <grian@cpan.org>') : ()),
    $ExtUtils::MakeMaker::VERSION >= 6.48 ? ( MIN_PERL_VERSION => MIN_PERL_VERSION ) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE => 'perl' ) : (),
);
