use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MediaWiki::EditFramework',
    VERSION_FROM      => 'lib/MediaWiki/EditFramework.pm', # finds $VERSION
    PREREQ_PM         => {'MediaWiki::API' => 0.17 }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => {'Test::MockModule' => 0, Storable => 0}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MediaWiki/EditFramework.pm', # retrieve abstract from module
       AUTHOR         => 'Steve Sanbeg <sanbeg@cpan.org>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	  (LICENSE		=> 'perl') : ()),


    ($ExtUtils::MakeMaker::VERSION >= 6.4600 ?
      (META_MERGE => { 
	resources => { 
	  repository => 'https://github.com/sanbeg/MediaWiki-EditFramework'
	 }
       }) : ()
   ),
);
