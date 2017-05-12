#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  t/03-long-return.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More tests => 14;
use Devel::RunBlock qw(long_return);

&test01; # 14.

# -----------------------------------------------------------------------------
# test01.
#
our (@c, $up);
sub test01
{
	@c = (0)x4; _call_1(0);
	is_deeply([$up,@c],[0,2,0,0,0], 'long return 0 of 1 call');
	
	@c = (0)x4; _call_1(1);
	is_deeply([$up,@c],[1,1,0,0,0], 'long return 1 of 1 call');
	
	@c = (0)x4; _call_2(0);
	is_deeply([$up,@c],[0,2,2,0,0], 'long return 0 of 2 call');
	
	@c = (0)x4; _call_2(1);
	is_deeply([$up,@c],[1,1,2,0,0], 'long return 1 of 2 call');
	
	@c = (0)x4; _call_2(2);
	is_deeply([$up,@c],[2,1,1,0,0], 'long return 2 of 2 call');
	
	@c = (0)x4; _call_3(0);
	is_deeply([$up,@c],[0,2,2,2,0], 'long return 0 of 3 call');
	
	@c = (0)x4; _call_3(1);
	is_deeply([$up,@c],[1,1,2,2,0], 'long return 1 of 3 call');
	
	@c = (0)x4; _call_3(2);
	is_deeply([$up,@c],[2,1,1,2,0], 'long return 2 of 3 call');
	
	@c = (0)x4; _call_3(3);
	is_deeply([$up,@c],[3,1,1,1,0], 'long return 3 of 3 call');
	
	@c = (0)x4; _call_4(0);
	is_deeply([$up,@c],[0,2,2,2,2], 'long return 0 of 4 call');
	
	@c = (0)x4; _call_4(1);
	is_deeply([$up,@c],[1,1,2,2,2], 'long return 1 of 4 call');
	
	@c = (0)x4; _call_4(2);
	is_deeply([$up,@c],[2,1,1,2,2], 'long return 2 of 4 call');
	
	@c = (0)x4; _call_4(3);
	is_deeply([$up,@c],[3,1,1,1,2], 'long return 3 of 4 call');
	
	@c = (0)x4; _call_4(4);
	is_deeply([$up,@c],[4,1,1,1,1], 'long return 4 of 4 call');
}
sub _call_1 { $c[0]=1; long_return($up=shift); $c[0]=2; }
sub _call_2 { $c[1]=1; _call_1(shift); $c[1] = 2; }
sub _call_3 { $c[2]=1; _call_2(shift); $c[2] = 2; }
sub _call_4 { $c[3]=1; _call_3(shift); $c[3] = 2; }

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
