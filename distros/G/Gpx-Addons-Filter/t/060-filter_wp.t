#!/usr/bin/perl -T

# $Id: --- $
# Created by Ingo Lantschner on 2009-06-24.
# Copyright (c) 2009 Ingo Lantschner. All rights reserved.
# ingo@boxbe.com, http://ingo@lantschner.name

use warnings;
use strict;

# Debugging
#use Data::Dumper;
our $DEBUG = 0;

use Test::More tests => 8;
use Gpx::Addons::Filter qw( filter_wp );
use Geo::Gpx;

my $gpx = Geo::Gpx->new();
my $wps;
$wps->[0]{lat} = -1;
$wps->[0]{lon} = -1;
$wps->[0]{pos} = 'line';

$wps->[1]{lat} =  2;
$wps->[1]{lon} =  2;
$wps->[1]{pos} = 'in';

$wps->[2]{lat} =  3;
$wps->[2]{lon} =  4;
$wps->[2]{pos} = 'out';

$wps->[3]{lat} =  1;
$wps->[3]{lon} = -2;
$wps->[3]{pos} = 'out';

$wps->[4]{lat} =  1;
$wps->[4]{lon} = -2;
$wps->[4]{pos} = 'out';

$wps->[5]{lat} =  6;
$wps->[5]{lon} =  0;
$wps->[5]{pos} = 'out';

$wps->[6]{lat} =  6;
$wps->[6]{lon} = -1;
$wps->[6]{pos} = 'out';

$wps->[7]{lat} = -3;
$wps->[7]{lon} =  5;
$wps->[7]{pos} = 'out';

$wps->[8]{lat} =  3;
$wps->[8]{lon} =  4;
$wps->[8]{pos} = 'out';

$wps->[9]{lat} =  5;
$wps->[9]{lon} = -5;
$wps->[9]{pos} = 'out';

$wps->[10]{lat} = -4;
$wps->[10]{lon} =  1;
$wps->[10]{pos} = 'out';

$wps->[11]{lat} = -2;
$wps->[11]{lon} =  3;
$wps->[11]{pos} = 'corner';

$wps->[12]{lat} = -2;
$wps->[12]{lon} = -1;
$wps->[12]{pos} = 'corner';

$wps->[13]{lat} =  5;
$wps->[13]{lon} =  3;
$wps->[13]{pos} = 'corner';

$wps->[14]{lat} =  5;
$wps->[14]{lon} = -1;
$wps->[14]{pos} = 'corner';

$wps->[15]{lat} =  2;
$wps->[15]{lon} =  3;
$wps->[15]{pos} = 'line';

$wps->[16]{lat} =  200;
$wps->[16]{lon} =  333;
$wps->[16]{pos} = 'out';

$wps->[17]{lat} =  20;
$wps->[17]{lon} =  33;
$wps->[17]{pos} = 'out';

foreach (@{$wps}) {
    my $wpt = {
      lat         => $_->{lat},
      lon         => $_->{lon},
      name        => 'Some silly placeholder-text',
      cmt         => $_->{pos},
      src         => 'Testing',
    };
    $gpx->add_waypoint( $wpt );
}

print {*STDERR} "Dump of \$gpx:\n" . Dumper($gpx) . "\n" if $DEBUG > 1;

my $wp = $gpx->waypoints();
# To include waypoints into the export an additional function filter_wp is provided
my $bounds = {
  minlat => -2 ,
  minlon => -1 ,
  maxlat =>  5 ,
  maxlon =>  3 ,
};

my $sel_wp = filter_wp($wp, $bounds);   # export all waypoints within this box

print {*STDERR} "Dump of \$sel_wp:\n" . Dumper($sel_wp) . "\n" if $DEBUG > 1;
say("Testing if all selected points are inside the box");
foreach (@{$sel_wp}) {
    like($_->{cmt}, qr/in|line|corner/, "WP($_->{lat}|$_->{lon}) is inside of box")
}

say("\nTesting if no inside-points are excluded");

my $number_of_points_selected = @{$sel_wp};
my $number_of_points_inside = 0;
foreach (@{$wps}) {
    if ($_->{pos} =~ /in|line|corner/) {
        $number_of_points_inside++;
    }
}

ok($number_of_points_selected == $number_of_points_inside, 'The numbers of selected and inside points match');


sub say { print @_, "\n" };
