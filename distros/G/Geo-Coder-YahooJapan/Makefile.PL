use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	DISTNAME		=> 'Geo-Coder-YahooJapan',
	VERSION_FROM 	=> 'lib/Xango.pm',
    NAME              => 'Geo::Coder::YahooJapan',
    VERSION_FROM      => 'lib/Geo/Coder/YahooJapan.pm', # finds $VERSION
    PREREQ_PM         => {
		'LWP::Simple' => 0
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Coder/YahooJapan.pm', # retrieve abstract from module
		AUTHOR         => 'KUMAGAI Kentaro <ku0522a+cpan@gmail.com>') : ()),
);
