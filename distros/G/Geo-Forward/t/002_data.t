#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 17;
use Geo::Functions qw{deg_dms};

BEGIN { use_ok( 'Geo::Forward' ); }
my $gf = Geo::Forward->new;
isa_ok($gf, "Geo::Forward");

my @data=$gf->forward(34,-77,45,100);
ok(near($data[0],  34.000637478), "lat");
ok(near($data[1], -76.999234611), "lon");
ok(near($data[2], 225.000428   ), "baz");

#Examples from the Fortran Version
my @test=(
[qw{38 52 15.68000 N  77  3 21.15000 W 38 53 23.12000 N  77  0 32.52000 W  62 53 18.6255 242 55  4.4740  4565.6854  }],
[qw{34 34 34.34000 N   0  1  1.01000 W 34 35 35.35000 N   0  1  1.01000 E  58 50  5.7824 238 51 15.0439  3633.8334  }],
[qw{12 34 54.45450 N 179 45 56.34342 E 12 33 34.21323 N 179 50 34.34000 W  93 16 28.8588 273 21 35.5882  42612.4852 }],
[qw{ 1  1  1.01111 N  56 56 56.56000 W  1  1  1.01010 S  57 57 57.57000 W 206 43 15.8917  26 43 15.8916 251779.2461 }],
);

foreach (@test) {
  my $lat1=deg_dms(@$_[0..3]);
  my $lon1=deg_dms(@$_[4..7]);
  my $lat2=deg_dms(@$_[8..11]);
  my $lon2=deg_dms(@$_[12..15]);
  my $faz=deg_dms(@$_[16..18]);
  my $baz=deg_dms(@$_[19..21]);
  my $dist=$_->[22];
  my @data=$gf->forward($lat1,$lon1,$faz,$dist);
  ok(near($data[0], $lat2), "lat");
  ok(near($data[1], $lon2), "lon");
  ok(near($data[2], $baz ), "baz");
}

sub near {
  my $x=shift;
  my $y=shift;
  my $p=shift || 10e-7;
  if (($x-$y)/$y < $p) {
    return 1;
  } else {
    return 0;
  }
}
