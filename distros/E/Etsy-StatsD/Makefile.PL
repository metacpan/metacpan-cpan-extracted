use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Etsy::StatsD',
    VERSION_FROM      => 'lib/Etsy/StatsD.pm', # finds $VERSION
    #VERSION           => '1.000001', #none in module yet; add later
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => {Test::MockModule => 0},
    MIN_PERL_VERSION   => 5.006,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Etsy/StatsD.pm', # retrieve abstract from module
       AUTHOR         => 'Steve Sanbeg <sanbeg@cpan.org>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
      (LICENSE      => 'perl') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.4600 ?
      (META_MERGE => { 
	resources => { 
	  repository => 'https://github.com/sanbeg/Etsy-Statsd'
	 }
       }) : ()
   ),
);
