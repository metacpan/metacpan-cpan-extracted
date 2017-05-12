#/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 15;
use lib ('lib');

BEGIN { use_ok( 'Math::PercentChange', qw(percent_change f_percent_change) ); }

my %subs = ( percent_change => \&percent_change, f_percent_change => \&f_percent_change ); 

for (qw/percent_change f_percent_change/) {
  is( ($subs{$_}(10, 15)) + 0, 50, "$_ positive");
  is( ($subs{$_}(10, 5)) + 0, -50, "$_ negative");
  is( (sprintf("%.2f", $subs{$_}(7, 5))) + 0, -28.57, "$_ less");
  is( ($subs{$_}(5, 7)) + 0, 40, "$_ greater");
  is( ($subs{$_}(-10, 0)) + 0, 100, "$_ negative from");
  is( $subs{$_}(0, 10), undef, "$_ zero from");
  is( $subs{$_}(0, 0), undef, "$_ both zero");
}
