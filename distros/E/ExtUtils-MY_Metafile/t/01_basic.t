#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01_basic.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
BEGIN{ $^W=1; } #use warnings FATAL => 'all';
use Test::More tests => 3;
use Test::Exception;

BEGIN{ use_ok('ExtUtils::MY_Metafile'); }
require ExtUtils::MakeMaker;
our $DUMMY_DATA = {
	DISTNAME => 'Dummy-Data',
	AUTHOR   => 'dummy person',
	VERSION  => 1,
	ABSTRACT => 'dummy data',
	LICENSE  => 'dummy license',
};

&test_01_basic;

# -----------------------------------------------------------------------------
# test_01_basic.
#
sub test_01_basic
{
	lives_and(sub{
		my_metafile( {} );
		my $dummy_mm = _dummy_mm($DUMMY_DATA);
		my $meta = ExtUtils::MY_Metafile::_gen_meta_yml($dummy_mm);
		ok($meta, '[basic] _gen_meta_yml returns something.');
		my $re_name = qr/^name:\s+Dummy-Dat[a]$/m;
		like($meta, $re_name, "[basic] has name")
	}, "[basic] (execution)");
	1;
}


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
