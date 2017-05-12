# most of this is automatic
use File::Spec::Functions;
use strict;
use vars qw(%ARGS);
do(catfile(updir(), 'common.pl'));

if ($^O eq 'darwin') {
	$ARGS{'LD'}		= 'c++';
	$ARGS{'OBJECT'}		= 'AppleEvents.o PerlAEUtils.o';

	# i'm sure there's a way to tell MakeMaker to use .cp,
	# but this is easier
	require File::Copy;
	File::Copy::copy('PerlAEUtils.cp', 'PerlAEUtils.cpp');
	$ARGS{'clean'}{FILES}   .= ' PerlAEUtils.cpp';
}

if ($^O eq 'MacOS') {
	$ARGS{'INC'}		= '-i $(PERL_SRC):AEGizmos:include:';
	$ARGS{'OBJECT'}		= 'AppleEvents.c.o PerlAEUtils.cp.o';
	$ARGS{'MACLIBS_SHARED'}	= '"::::::AEGizmos:AEGizmos4Perl.shlb.PPC" ';
}

domakefile();
