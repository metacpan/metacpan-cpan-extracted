#!/usr/bin/env perl

use common::sense;
use GD::Graph::Hooks;
use GD::Graph::lines;

my @data;
for( 0 .. 100 ) { push @{$data[0]}, $_; push @{$data[1]}, $_ + 3*(rand 5); }

# compute a naive biased moving average
my (@mv_avg, @last);
for my $i ( 0 .. $#{ $data[1] }) {
    push @last, $data[1][$i];
    if( @last > 4 ) {
        shift @last while @last > 5;
        my $sum = 0;
           $sum += $_ for @last;
        $mv_avg[$i] = ($sum / @last);
    }
}

my $graph = GD::Graph::lines->new(1500,500);

$graph->add_hook( 'GD::Graph::Hooks::PRE_DATA' => sub {
    my ($gobj, $gd, $left, $right, $top, $bottom, $gdta_x_axis) = @_;
    my $clr = $gobj->set_clr(0xaa, 0xaa, 0xaa);

    my $x = 10;
    while ( $x < $#{ $data[1] }-10 ) {
        # compute line endpoints from a datapoint
        my @lhs = $gobj->val_to_pixel($x+1,  $data[1][$x]);

        # to a predicted endpoint, based on the moving average
        my @rhs = $gobj->val_to_pixel($x+11, $data[1][$x] + 10*($mv_avg[$x] - $mv_avg[$x-1]));

        print "adding line from data point (@lhs) to value predicted by mv_avg (@rhs)\n";

        $gd->line(@lhs,@rhs,$clr);

        $x += 10;
    }
});

my $gd = $graph->plot(\@data);

my $fname = "/tmp/example.png";
open my $img, '>', $fname or die $!;
binmode $img;
print $img $gd->png;
close $img;

print "example written to $fname\n";
