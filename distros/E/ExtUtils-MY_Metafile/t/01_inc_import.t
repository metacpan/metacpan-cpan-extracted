#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01_inc_import.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
BEGIN{ $^W=1; } #use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN{ use_ok('ExtUtils::MY_Metafile'); }
require ExtUtils::MakeMaker;

&setup;
&test_01_import;

# -----------------------------------------------------------------------------
# setup.
#
sub setup
{
	$INC{"inc/ExtUtils/MY_Metafile.pm"} = $INC{"ExtUtils/MY_Metafile"};
}

# -----------------------------------------------------------------------------
# test_01_import.
#
sub test_01_import
{
	my $pkg = "TEST1";
	eval "package $pkg; use inc::ExtUtils::MY_Metafile;";
	$@ and return fail("[default] eval: $@");
	ok($pkg->can("my_metafile"), "[default] my_metafile via inc::EU::MY_Metafile");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
