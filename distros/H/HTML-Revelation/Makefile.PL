use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Reveal HTML document structure in a myriad of colors',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST HTML-Revelation-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'HTML-Revelation',
 NAME      => 'HTML::Revelation',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 accessors::classic          => 0,
	 File::Spec                  => 0,
	 HTML::Entities::Interpolate => 0,
	 HTML::Tagset                => 0,
	 HTML::TreeBuilder           => 0,
	 List::Cycle                 => 0,
 },
 VERSION_FROM	=> 'lib/HTML/Revelation.pm',
);
