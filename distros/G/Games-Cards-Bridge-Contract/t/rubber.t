#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 19;
$|=1;

use Games::Cards::Bridge::Rubber;

my $rubber = Games::Cards::Bridge::Rubber->new;
sub check_score {
  my $rubber = shift;
  my $s = shift;
  my @scores = @_;
  is_deeply([$rubber->we_above, $rubber->we_below, $rubber->they_above, $rubber->they_below], \@scores, $s);
}

check_score( $rubber, "start", 0, 0, 0, 0 );

$rubber->contract( direction => 'we', trump => 'H', bid => '2', made => '4' );
check_score( $rubber, "2H", 60, 60, 0, 0 );
is( $rubber->we_leg, 60, "we_leg=60" );

$rubber->contract( direction => 'they', trump => 'S', bid => '4', down => '2', dbl => 1 );
check_score( $rubber, "4S", 360, 60, 0, 0 );

$rubber->contract( direction => 'they', trump => 'N', bid => '3', made => '4' );
check_score( $rubber, "3N", 360, 60, 30, 100 );
is( $rubber->they_vul, 1, "they_vul=1" );
is( $rubber->we_leg, 0, "we_leg=0" );
is( $rubber->they_leg, 0, "they_leg=0" );

$rubber->contract( direction => 'they', trump => 'S', bid => '3', made => '3' );
check_score( $rubber, "3S", 360, 60, 30, 190 );

$rubber->contract( direction => 'they', trump => 'D', bid => '2', down => '2' );
check_score( $rubber, "2D", 560, 60, 30, 190 );

$rubber->contract( direction => 'we', trump => 'H', bid => '6', made => '7', dbl => 1 );
check_score( $rubber, "6H", 1210, 420, 30, 190 );
is( $rubber->we_vul, 1, "we_vul=1" );
is( $rubber->we_leg, 0, "we_leg=0" );
is( $rubber->they_leg, 0, "they_leg=0" );

$rubber->contract( direction => 'they', trump => 'N', bid => '1', made => '2' );
check_score( $rubber, "1N", 1210, 420, 60, 230 );
is( $rubber->they_leg, 40, "they_leg=40" );

$rubber->contract( direction => 'we', trump => 'C', bid => '3', made => '3' );
check_score( $rubber, "3C", 1210, 480, 60, 230 );

$rubber->contract( direction => 'they', trump => 'H', bid => '3', made => '3' );
check_score( $rubber, "3C", 1210, 480, 560, 320 );
is( $rubber->complete, 1, "complete" );

1;

