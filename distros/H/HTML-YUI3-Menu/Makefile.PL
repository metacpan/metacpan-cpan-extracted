use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Convert a Tree::DAG_Node object into the HTML and JS for a YUI3 menu',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST HTML-YUI3-Menu-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'HTML-YUI3-Menu',
 NAME      => 'HTML::YUI3::Menu',
# Next line runs copy.config.pl when user runs 'make'.
# Warning: '...' => 0 is OK but => '' or undef are ignored.
 PL_FILES  => {'scripts/copy.config.pl' => 'Copying...'},
 PREREQ_PM =>
 {
	 Config::Tiny    => 2.13,
	 File::Copy      => 2.18,
	 File::HomeDir   => 0.97,
	 Hash::FieldHash => 0.10,
	 Path::Class     => 0.23,
	 Text::Xslate    => 1.0007,
 },
 VERSION_FROM => 'lib/HTML/YUI3/Menu.pm',
);
