#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::OpTwin;

sub note_it { push @EO::OpTwin::LOG, join ',', @_; 'noted' }

twin_all( 'a side effect',               'my ($x) = @_; note_it($x); $x', 'a' );
twin_all( 'side effects in every statement', 'my ($x, $y) = @_; note_it($x); my $t = $x . $y; note_it($t); $t', 'p', 'q' );
twin_all( 'a tail that takes its context', 'my ($x) = @_; note_it($x)', 'z' );
twin_all( 'a list in the tail',          'my ($x) = @_; note_it($x); ($x, $x)', 'l' );

{
    my $c = EO::OpTwin::twin('my ($x) = @_; note_it($x); [$x]');
    local @EO::OpTwin::LOG;
    $c->{op}{void}->($_) for 1 .. 100;
    is( scalar @EO::OpTwin::LOG, 100, '100 calls in void context, every side effect once' );
}

done_testing;
