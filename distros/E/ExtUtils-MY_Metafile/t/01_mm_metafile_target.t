#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01_mm_metafile_target.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
BEGIN{ $^W=1; } #use warnings FATAL => 'all';
use Test::More tests => 5;
use Test::Exception;

BEGIN{ use_ok('ExtUtils::MY_Metafile'); }
require ExtUtils::MakeMaker;
my $metafile_target = \&ExtUtils::MY_Metafile::_mm_metafile;
our $DUMMY_DATA = {
	DISTNAME => 'Dummy-Data',
	AUTHOR   => 'dummy person',
	VERSION  => 1,
	ABSTRACT => 'dummy data',
	LICENSE  => 'dummy license',
};

&test_01_basic;
&test_02_no_meta;

# -----------------------------------------------------------------------------
# test_01_basic.
#
sub test_01_basic
{
	#lives_and(sub{
		my_metafile(); # set MM::metafile_target.
		my $dummy_mm = _dummy_mm($DUMMY_DATA);
		my $maketext = $dummy_mm->$metafile_target();
		ok($maketext, '[basic] MM::metafile_target() returns something.');
		like($maketext, qr/name:\s+Dummy-Dat[a]/, "[basic] has name")
	#}, "[basic] (execution)");
}

# -----------------------------------------------------------------------------
# test_02_no_meta.
#
sub test_02_no_meta
{
	#lives_and(sub{
		my_metafile(); # set MM::metafile_target.
		my $dummy_mm = _dummy_mm({ NO_META => 1 });
		my $maketext = $dummy_mm->$metafile_target();
		ok($maketext, '[no_meta] MM::metafile_target() returns something.');
		unlike($maketext, qr/META.yml/, "[no_meta] no META.yml")
	#}, "[no_meta] (execution)");
}


# -----------------------------------------------------------------------------
# dummy stub for ExtUtils::MakeMaker.
#
sub _dummy_mm
{
	@MM::Dummy::ISA = qw(MM);
	bless shift, "MM::Dummy";
}
sub MM::Dummy::echo
{
	my $this = shift;
	my $text = shift;
	my $out  = shift;
	my @lines = map{ qq{\$(NOECHO) \$(ECHO) "$_"} } split(/\n/, $text);
	$lines[0] .= " > $out";
	foreach my $line (@lines[1..$#lines])
	{
		$line .= " >> $out";
	}
	@lines;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
