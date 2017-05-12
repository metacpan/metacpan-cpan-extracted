use 5.014;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ham::Resources::Propagation',
    VERSION_FROM      => 'lib/Ham/Resources/Propagation.pm', # finds $VERSION
    LICENSE				 => 'perl',
    MIN_PERL_VERSION  => 5.014,
    PREREQ_PM         => {
    		'LWP::UserAgent'	=> 6,
    		'XML::Reader::PP'		=> 0,
    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ham/Resources/Propagation.pm', # retrieve abstract from module
       AUTHOR         => 'Carlos Juan <ea3hmbn@gmail.com>') : ()),
);
