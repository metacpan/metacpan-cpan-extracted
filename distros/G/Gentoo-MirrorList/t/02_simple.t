use strict;
use warnings;
binmode *STDOUT, ':utf8';
binmode *STDERR, ':utf8';

use Test::More;
use FindBin;
use lib "$FindBin::Bin/02_files/lib";

use App::Cache::Test;
use Gentoo::MirrorList;

my ($cache);

BEGIN {
  $cache = App::Cache::Test->new( mirror_file => "$FindBin::Bin/02_files/data/mirrors3.xml" );
}

sub ml {
  return Gentoo::MirrorList->new( _cache => $cache );
}

my $t;

my @countries    = @{ ml->country_list };
my @countrynames = @{ ml->countryname_list };
my @regions      = @{ ml->region_list };
my @mirrornames  = @{ ml->mirrorname_list };
my @uris         = @{ ml->uri_list };
my @protos       = @{ ml->proto_list };

$t++;
cmp_ok( scalar @countries, '==', 43, '43 Countries' );
$t += scalar @countries;
$t++;
cmp_ok( scalar @countrynames, '==', 43, '43 CountryNames' );
$t += scalar @countrynames;
$t++;
cmp_ok( scalar @regions, '==', 6, '6 Regions' );
$t += scalar @regions;
$t++;
cmp_ok( scalar @mirrornames, '==', 135, '135 Mirror Names' );
$t += scalar @mirrornames;
$t++;
cmp_ok( scalar @uris, '==', 284, '284 URI Names' );
$t += scalar @uris;
$t++;
cmp_ok( scalar @protos, '==', 3, '3 Protos' );
$t += scalar @protos;

for (@countries) {
  my $nmirrors = scalar ml->country($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Country $_ has mirrors" );
}
for (@countrynames) {
  my $nmirrors = scalar ml->countryname($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Country Named $_ has mirrors" );
}
for (@regions) {
  my $nmirrors = scalar ml->region($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Region Named $_ has mirrors" );
}

for (@mirrornames) {
  my $nmirrors = scalar ml->mirrorname($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Mirror Named $_ has mirrors" );
}

for (@uris) {
  my $nmirrors = scalar ml->uri($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Uri $_ has mirrors" );
}

for (@protos) {
  my $nmirrors = scalar ml->proto($_)->all;
  cmp_ok( $nmirrors, '>', 0, "Proto $_ has mirrors" );
}

$t += 31;
for ( 0 ... 30 ) {
  cmp_ok( scalar @{ [ ml->country('AU')->random($_) ] }, '==', $_, "Random list of $_ " );
}
done_testing($t);

