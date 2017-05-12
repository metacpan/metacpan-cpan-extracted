# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw($NAME %ARGS);
$NAME = 'MacPerl';
do(catfile(updir(), 'common.pl'));

$ARGS{'PM'}   = { 'MacPerl.pm' => '$(INST_LIBDIR)/MacPerl.pm' };

if ($^O eq 'darwin') {
	$ARGS{'LINKTYPE'}	= 'dynamic';
	$ARGS{'OBJECT'}		= 'MacPerl.o OSA.o';
}

if ($^O eq 'MacOS') {
	$ARGS{'LINKTYPE'}	= 'static';
	$ARGS{'SKIP'}		= [qw(dynamic dynamic_lib dynamic_bs)];
	$ARGS{'OBJECT'}		= 'MacPerl.c XL.c OSA.c';
	$ARGS{'INC'}	 	= "-i :::::XL:";
}

domakefile();
