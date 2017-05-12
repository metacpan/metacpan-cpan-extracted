
require 5.6.0;  # for use of "our" variables.   Otherwise nothing fancy

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'File::RdistByRsync',
	'DISTNAME' => 'File-RdistByRsync',
	'VERSION_FROM' => 'RdistByRsync.pm',
	'EXE_FILES' => [ 'rdist2rsync' ],
	'PREREQ_PM' => {
		'Parse::RecDescent' => 1.80,
		'Getopt::Declare' => 1.09,
		'File::Slurp' => 96.042202,
	},
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Read rdist distfiles, emulate rdist using rsync',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);


package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: RdistByRsync.pod
\tpod2text RdistByRsync.pod >README

END_OF_POSTAMBLE
}
