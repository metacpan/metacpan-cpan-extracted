#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 26;
BEGIN { use_ok( 'Geo::Spline' ); }

use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (($x-$y)/$y < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}

my $p0={time=>1160449100.67,
        lat=>39.197807,
        lon=>-77.263510,
        speed=>31.124,
        heading=>144.8300};
my $p1={time=>1160449225.66,
        lat=>39.167718,
        lon=>-77.242278,
        speed=>30.615,
        heading=>150.5300};
my $spline=Geo::Spline->new($p0, $p1);
isa_ok($spline, "Geo::Spline");

my $point=$spline->point(1160449150);
ok(near $point->{'lat'}, 39.1861322117117);
ok(near $point->{'lon'}, -77.2548824212532);
ok(near $point->{'speed'}, 33.6486345147946);
ok(near $point->{'heading'}, 142.982403679421);

my %point=$spline->point(1160449150);
ok(near $point{'lat'}, 39.1861322117117);
ok(near $point{'lon'}, -77.2548824212532);
ok(near $point{'speed'}, 33.6486345147946);
ok(near $point{'heading'}, 142.982403679421);

my @times=(1160449150,1160449180,1160449190,1160449225.66);
my @pointlist=$spline->pointlist(@times);
is(scalar(@pointlist), 4);
ok(near $pointlist[0]->{'lat'}, 39.1861322117117);
ok(near $pointlist[0]->{'lon'}, -77.2548824212532);
ok(near $pointlist[0]->{'speed'}, 33.6486345147946);
ok(near $pointlist[0]->{'heading'}, 142.982403679421);
ok(near $pointlist[-1]->{'lat'}, 39.167718);
ok(near $pointlist[-1]->{'lon'}, -77.242278);
ok(near $pointlist[-1]->{'speed'}, 30.615);
ok(near $pointlist[-1]->{'heading'}, 150.5300);

my $ptlist=$spline->pointlist();
is(scalar(@$ptlist), 126);

my @ptlist=$spline->pointlist();
is(scalar(@ptlist), 126);

my $time=$spline->timelist();
is(scalar(@$time), 126);

my @time=$spline->timelist();
is(scalar(@time), 126);

@time=$spline->timelist(1);
is(scalar(@time), 2);

@time=$spline->timelist(999);
is(scalar(@time), 1000);

@ptlist=$spline->pointlist(@time);
is(scalar(@ptlist), 1000);
