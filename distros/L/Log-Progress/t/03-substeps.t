#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Log::Progress' ) or BAIL_OUT;

my $out= '';
sub append_out { $out .= (shift) . "\n" }

my $p= Log::Progress->new(squelch => .2, to => \&append_out);
my $p1= $p->substep("foo", .3, "Substep 1");
my $p2= $p->substep("bar", .7, "Substep 2");
$p1->at($_/10) for (0..10);
$p2->at($_/100) for (0..100);

is( $out, <<'END', 'output' );
progress: foo (0.3) Substep 1
progress: bar (0.7) Substep 2
progress: foo 0.0
progress: foo 0.2
progress: foo 0.4
progress: foo 0.6
progress: foo 0.8
progress: foo 1.0
progress: bar 0.0
progress: bar 0.2
progress: bar 0.4
progress: bar 0.6
progress: bar 0.8
progress: bar 1.0
END

done_testing;
