#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01_import.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
BEGIN{ $^W=1; } #use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN{ use_ok('ExtUtils::MY_Metafile'); }
require ExtUtils::MakeMaker;

&test_01_default;
&test_02_none;
&test_03_all;
&test_04_select;
&test_05_unknown;

# -----------------------------------------------------------------------------
# test_01_default.
#
sub test_01_default
{
	my $pkg = "TEST1";
	eval "package $pkg; use ExtUtils::MY_Metafile;";
	$@ and return fail("[default] eval: $@");
	ok($pkg->can("my_metafile"), "[default] default export: my_metafile");
}

# -----------------------------------------------------------------------------
# test_02_none.
#
sub test_02_none
{
	my $pkg = "TEST2";
	eval "package $pkg; use ExtUtils::MY_Metafile ();";
	$@ and return fail("[none] eval: $@");
	ok(!$pkg->can("my_metafile"), "[none] no export: my_metafile");
}

# -----------------------------------------------------------------------------
# test_03_all.
#
sub test_03_all
{
	my $pkg = "TEST3";
	eval "package $pkg; use ExtUtils::MY_Metafile qw(:all);";
	$@ and return fail("[all] eval: $@");
	ok($pkg->can("my_metafile"), "[all] export all: my_metafile");
}


# -----------------------------------------------------------------------------
# test_04_select.
#
sub test_04_select
{
	my $pkg = "TEST4";
	eval "package $pkg; use ExtUtils::MY_Metafile qw(my_metafile);";
	$@ and return fail("[select] eval: $@");
	ok($pkg->can("my_metafile"), "[select] selective export: my_metafile");
}

# -----------------------------------------------------------------------------
# test_05_unknown.
#
sub test_05_unknown
{
	my $pkg = "TEST5";
	eval "package $pkg; use ExtUtils::MY_Metafile qw(mymy_metafile);";
	$@ and return fail("[select] eval: $@");
	ok(!$pkg->can("mymy_metafile"), "[unknown] selective export: mymy_metafile but none");
	ok(!$pkg->can("my_metafile"), "[unknown] selective export: no my_metafile");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
