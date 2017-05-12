#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  t/01-rublock.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More tests => 4;
use Devel::RunBlock qw(runblock runblock_state);

&test01; # 4.

# -----------------------------------------------------------------------------
# test01.
#
sub test01
{
	is runblock_state sub{ "y"; }, 0, 'leave block results 0';
	is runblock_state sub{ return "x"; }, 1, 'return block results 1';
	
	my $loc;
	my $test = sub{ $loc = 1; runblock shift; $loc = 3; };
	$loc = 0; $test->( sub{ $loc = 2; } );
	is( $loc, 3, 'leave runblock');
	$loc = 0; $test->( sub{ $loc = 2; return; } );
	is( $loc, 2, 'return runblock');
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
