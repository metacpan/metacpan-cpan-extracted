use ExtUtils::MakeMaker;

die "Unsupported OS!" unless $^O =~ m/Mac|darwin/;

require 5.010;

print <<'HERE';
=====================================================================
             This module is looking for a maintainer!

No one is maintaining this module, but you can take up its care
and feeding by requesting CPAN persmissions from modules@perl.org.

This version is assigned to the ADOPTME CPAN user and hosted in
GitHub:

	https://github.com/CPAN-Adopt-Me/Palm-Magellan-NavCompanion

=====================================================================
HERE

	
open IN,  "mp3/iTunes_Music_Library";
open OUT, "> mp3/iTunes Music Library";
print OUT do { local $/; <IN> };

	
WriteMakefile(
    'NAME'          => 'Mac::iTunes',
	'ABSTRACT'      => 'interact with and control iTunes',
    'VERSION_FROM'  => 'lib/Mac/iTunes.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM' => {
		'Mac::Path::Util'   => '0.07',
		'Mac::PropertyList' => '0',
		'MP3::Info'         => '0',
		'Test::Manifest'    => '0.9',
		'Test::More'        => '0',
		'Test::Manifest'    => '1.14',
		},
	    	
    clean  => { FILES      => q|Mac-iTunes-* mp3/iTunes\\ Music\\ Library t/test_manifest NO_MAC| },
	);
