#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Log::Progress' ) or BAIL_OUT;

my $out= '';
sub append_out { $out.= (shift) . "\n"; }

for (
	[ 1 => 0 ],
	[ .1 => 1 ],
	[ .5 => 1 ],
	[ .05 => 2 ],
	[ .01 => 2 ],
	[ 1/350 => 3 ],
	[ 1/60 => 2 ],
) {
	my $p= Log::Progress->new(squelch => $_->[0]);
	is( $p->precision, $_->[1], 'precision for squelch '.$_->[0] );
}
for (
	[ 0 => 1 ],
	[ 1 => .1 ],
	[ 2 => .01 ],
) {
	my $p= Log::Progress->new(precision => $_->[0]);
	is( $p->squelch, $_->[1], 'squelch for precision '.$_->[0] );
}

my $p= Log::Progress->new(squelch => 1, to => \&append_out);
$p->at($_/1000) for 0..1000;
is( $out, "progress: 0\nprogress: 1\n", 'output' );

$out= '';
$p= Log::Progress->new(squelch => .1, to => \&append_out);
$p->at($_) for (.01, .02, .03, .04, .05, .06, .07, .08, .09, .09999);
$p->at($_) for (.89999, .949999, .95, .9999);
is( $out, "progress: 0.0\nprogress: 0.8\nprogress: 0.9\n", 'output' );

$out= '';
$p= Log::Progress->new(squelch => .05, to => \&append_out);
$p->at($_) for (.01, .02, .03, .04);
is( $out, "progress: 0.00\n", 'output' );
$out= '';
$p->at(.05);
is( $out, "progress: 0.05\n", 'output' );
$p->at($_) for (.05, .06, .07, .08, .09, .0999);
is( $out, "progress: 0.05\n", 'output' );

$out= '';
$p= Log::Progress->new(precision => 0, to => \&append_out);
$p->at(.05);
is( $out, "progress: 0\n", 'output' );
$p->at(.9);
is( $out, "progress: 0\n", 'output' );
$p->at(.9999999);
is( $out, "progress: 0\n", 'output' );
$p->at(1);
is( $out, "progress: 0\nprogress: 1\n", 'output' );

done_testing;
