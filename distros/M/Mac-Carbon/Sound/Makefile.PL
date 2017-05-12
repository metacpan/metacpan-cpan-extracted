# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

$ARGS{'TYPEMAPS'} = [
	catfile(updir(), 'QuickDraw', 'typemap'),
];

$ARGS{'clean'}{'FILES'} .= ' t/Sound.rsrc';

if ($^O eq 'MacOS') {
	$ARGS{'MACLIBS_SHARED'}	= '"{{SharedLibraries}}"SoundLib';
}

domakefile();
