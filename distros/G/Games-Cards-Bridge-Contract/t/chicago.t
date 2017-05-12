#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
$|=1;

use Games::Cards::Bridge::Chicago;

my $chi = Games::Cards::Bridge::Chicago->new;
sub check_score {
  my $chi = shift;
  my $s = shift;
  my ($ns, $ew) = @_;
  is_deeply([$chi->NS_score, $chi->EW_score], [$ns, $ew], $s);
}
sub check_state {
  my $chi = shift;
  my @state = @_;
  is_deeply([$chi->dealer, $chi->NS_vul, $chi->EW_vul, $chi->complete], \@state, "game state ok");
}

check_score( $chi, "start", 0, 0 );

check_state( $chi, 'N', 0, 0, 0 );
$chi->contract( declarer => 'N', trump => 'H', bid => '4', made => '4' );
check_score( $chi, "4HN", 420, 0 );

check_state( $chi, 'E', 1, 0, 0 );
$chi->contract( declarer => 'S', trump => 'C', bid => '3', down => '2', dbl => 1 );
check_score( $chi, "3CNX-2", 420, 500 );

check_state( $chi, 'S', 0, 1, 0 );
$chi->contract( declarer => 'E', trump => 'N', bid => '3', made => '3' );
check_score( $chi, "3NE", 420, 1100 );

check_state( $chi, 'W', 1, 1, 0 );
$chi->contract( declarer => 'W', trump => 'D', bid => '5', down => '3' );
check_score( $chi, "5DW-3", 720, 1100 );

check_state( $chi, 'W', 1, 1, 1 );

1;

