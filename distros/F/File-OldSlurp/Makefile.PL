
use ExtUtils::MakeMaker;

WriteMakefile( 
	'NAME'	  => 'File::OldSlurp',
	'DISTNAME' => 'File-OldSlurp',
	'VERSION_FROM' => 'OldSlurp.pm',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Read and write files with a single command',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: OldSlurp.pod
\tpod2text OldSlurp.pod >README

END_OF_POSTAMBLE
}
