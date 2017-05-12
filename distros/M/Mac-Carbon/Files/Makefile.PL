# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

$ARGS{'TYPEMAPS'} = [
	catfile(updir(), 'QuickDraw', 'typemap'),
];

domakefile();
