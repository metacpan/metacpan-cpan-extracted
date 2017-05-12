use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mediawiki::Spider',
    VERSION_FROM      => 'lib/Mediawiki/Spider.pm', # finds $VERSION
    PREREQ_PM         => {	LWP::UserAgent => 2.0, HTML::Extract => 0.1, Data::Dumper=> 1 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mediawiki/Spider.pm', # retrieve abstract from module
       AUTHOR         => 'Emma Tonkin <et207@slackware.lan>') : ()),
);
