# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

if ($^O eq 'MacOS') {
	$ARGS{'LIBS'}	= ['"{{MW68KLibraries}}MathLibCFM68K (4i_8d).Lib" "{{MWPPCLibraries}}"MathLib'];
}

domakefile();
