#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  t/02-long-wantarray.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More tests => 12+6;
use Devel::RunBlock qw(long_wantarray);

our ($wa, $up);

&test01; # 12.
&test02; # 6.

# -----------------------------------------------------------------------------
# test01.
#
sub test01
{
	#sub ri{ my$r=shift;$r?'ARRAY':defined$r?'SCALAR':'VOID'}
	(sub{
		# void context.
		is(wantarray,          undef, '[01] void context, builtin-wantarray');
		is(long_wantarray,     undef, '[01] void context, long_wantarray');
		is((long_wantarray 0), undef, '[01] void context, long_wantarray 0');
		#print "#2   ".ri(wantarray)."\n";
		#print "#2-x ".ri(long_wantarray)."\n";
		#print "#2-0 ".ri(long_wantarray 0)."\n";
		my$s=(sub{
			# scalar context.
			is(wantarray,             '', '[01] scalar context, builtin-wantarray');
			is(long_wantarray,        '', '[01] scalar context, long_wantarray');
			is((long_wantarray 0),    '', '[01] scalar context, long_wantarray 0');
			is((long_wantarray 1), undef, '[01] scalar context, long_wantarray 1 is void');
			#print "#1   ".ri(wantarray)."\n";
			#print "#1-x ".ri(long_wantarray)."\n";
			#print "#1-0 ".ri(long_wantarray 0)."\n";
			#print "#1-1 ".ri(long_wantarray 1)."\n";
			my@s=(sub{
				# array context.
				is(wantarray,              1, '[01] array context, builtin-wantarray');
				is(long_wantarray,         1, '[01] array context, long_wantarray');
				is((long_wantarray 0),     1, '[01] array context, long_wantarray 0');
				is((long_wantarray 1),    '', '[01] array context, long_wantarray 1 is scalar');
				is((long_wantarray 2), undef, '[01] array context, long_wantarray 2 is void');
				#print "#0   ".ri(wantarray)."\n";
				#print "#0-x ".ri(long_wantarray)."\n";
				#print "#0-0 ".ri(long_wantarray 0)."\n";
				#print "#0-1 ".ri(long_wantarray 1)."\n";
				#print "#0-2 ".ri(long_wantarray 2)."\n";
			})->();
		})->();
	})->();
	1; # make void context.
}

# -----------------------------------------------------------------------------
# test01.
#
sub test02
{
	_call_4(0);
	is $wa, 1, '[02] array context';
	_call_4(1);
	is $wa, '', '[02] scalar context';
	_call_4(2);
	is $wa, undef, '[02] void context';
	_call_4(3);
	is $wa, undef, '[02] caller:void context';
	my $s = _call_4(3);
	is $wa, '', '[02] caller:scalar context';
	my @s = _call_4(3);
	is $wa, 1, '[02] caller:array context';
}

sub _call_0 { ($wa) = long_wantarray($up=shift); 1; }
sub _call_1 { my @s = _call_0(shift); 1; } # array.
sub _call_2 { my $s = _call_1(shift); 1; } # scalar.
sub _call_3 { _call_2(shift); 1; }         # void.
sub _call_4 { _call_3(shift); }            # caller.

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
