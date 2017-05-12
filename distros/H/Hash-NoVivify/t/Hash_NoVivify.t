#!/usr/local/bin/perl -w

use strict;
use vars qw($loaded %hash @array);

BEGIN {
	$| = 1;
	print "1..9\n";
	$loaded = 0;
}

END {print "not ok 1\n" unless $loaded;}

use Hash::NoVivify;
$loaded++;
print "ok $loaded\n";
$loaded++;

%hash  = (
	  'a' => 1,
	  'b' => 2,
	  'c' => {
		  'd' => {
			  'e' => {
				  'f' => undef,
				  'g' => 12,
				 }
			 }
		 }
	 );

@array  = qw(a b c d);

print Hash::NoVivify::Exists(\%hash, qw(c d e f)) ? '' : 'not ', "ok $loaded\n";
$loaded++;

print !Hash::NoVivify::Defined(\%hash, qw(c d e f)) ? '' : 'not ',"ok $loaded\n";
$loaded++;

print Hash::NoVivify::Defined(\%hash, qw(c d e g)) ? '' : 'not ',"ok $loaded\n";
$loaded++;

## The rest will fail 
print !Hash::NoVivify::Defined(\%hash, 'asdf', 'qwer', qw(a b c d), undef) ? '' : 'not ',"ok $loaded\n";
$loaded++;
 
print !Hash::NoVivify::Exists(\%hash, 'asdf', 'qwer', qw(a b c d), undef) ? '' : 'not ',"ok $loaded\n";
$loaded++;
 
print !Hash::NoVivify::Exists(\@array, 'asdf') ? '' : 'not ',"ok $loaded\n";
$loaded++;
 
print !Hash::NoVivify::Exists(%hash, 'asdf') ? '' : 'not ',"ok $loaded\n";
$loaded++;

print !Hash::NoVivify::Exists(12, 'asdf') ? '' : 'not ',"ok $loaded\n";
$loaded++;
