# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw($XS %ARGS);
$XS = 'MF.xs';
do(catfile(updir(), 'common.pl'));

if ($^O eq 'darwin') {
	my $src = 'MoreFilesSrc';
	# we only compile these separately for Mac OS X right now, so
	# we keep them in a separate directory and copy them in when needed
	require File::Copy;
	opendir my $dh, $src or die $!;
	File::Copy::copy($_, '.') for map { "$src/$_" } grep { /\.c$/ } readdir($dh);

	# all our C_FILES are generated or copied into place
	$ARGS{'clean'}{FILES}   = $ARGS{'clean'}{FILES} . ' $(C_FILES)';
	$ARGS{'INC'}		= $ARGS{'INC'} . " -I./$src";
	$ARGS{'OBJECT'}		= '$(O_FILES)';

	# this causes failures in the Carbon headers for some reason ...
	$ARGS{'CCFLAGS'}	=~ s/-mpowerpc64\b//;
}

if ($^O eq 'MacOS') {
	$ARGS{'INC'}		= '-i "$(PERL_SRC):MoreFiles:CHeaders:"';
	$ARGS{'OBJECT'}		= 'MF.c';
}

domakefile();
