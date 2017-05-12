# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

$ARGS{'TYPEMAPS'} = [
	catfile(updir(), 'Components', 'typemap'),
];

if ($^O eq 'MacOS') {
	$ARGS{'MACLIBS_SHARED'}	= '"{{SharedLibraries}}"AppleScriptLib';
}

domakefile();
