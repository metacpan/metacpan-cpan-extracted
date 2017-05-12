use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $VCACHE = 0.91;

WriteMakefile(
	      NAME                => 'FrameNet::WordNet::Detour',
	      AUTHOR              => 'Nils Reiter <reiter@cpan.org>',
	      VERSION_FROM        => 'lib/FrameNet/WordNet/Detour.pm',
	      ABSTRACT_FROM       => 'lib/FrameNet/WordNet/Detour.pm',
	      PREREQ_PM => 
	      { 'Test::More' => 0,
		'WordNet::QueryData' => 1.37,
		'WordNet::Similarity::path' => 0.10,
		'XML::TreeBuilder' => 3.09,
		'Getopt::Long' => 2.20,
		'Pod::Usage' => 1.00,
		'File::Spec' => 0.86 },
	      EXE_FILES => [ 'script/detour' ],

	      dist => 
	      { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },

	      clean => 
	      { FILES => 'FrameNet-WordNet-Detour-*' },

	      realclean =>
	      { FILES => '*~ blib' }
	     );
