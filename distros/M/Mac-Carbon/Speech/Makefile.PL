# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

if ($^O eq 'MacOS') {
	$ARGS{'MACLIBS_SHARED'}	= '"{{SharedLibraries}}"SpeechLib';
}

domakefile();
