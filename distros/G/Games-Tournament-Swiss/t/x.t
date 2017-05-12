#!usr/bin/perl

# x = b-q or w-q

use lib qw/t lib/;

use strict;
use warnings;
use Test::Base;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::FIDE';
}

use Games::Tournament::Swiss::Bracket;
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Contestant::Swiss::Preference;

filters { input => [ qw/chomp players/ ], expected => [ qw/chomp / ] };

plan tests => 1 * blocks;

sub Test::Base::Filter::players {
	my $self = shift;
	my $players = shift;
	$players =~ s/^players: (.*)$/$1/;
	my $white = $players =~ tr/W//;
	my $black = $players =~ tr/B//;
	my $none = $players =~ tr/-//;
	my @whites = map { Games::Tournament::Contestant::Swiss->new(
	id => $_+1, name => chr($_+65), rating => 2000-2*$_ ) } 0..$white-1;
	my @blacks = map { Games::Tournament::Contestant::Swiss->new(
	id => $_+1, name => chr($_+65), rating => 2000-2*$_ ) }
							$white..$white+$black-1;
	my @nones = map { Games::Tournament::Contestant::Swiss->new(
	id => $_+1, name => chr($_+65), rating => 2000-2*$_ ) }
				$white+$black .. $white+$black+$none-1;
	$_->preference->sign('Black') for @whites;
	$_->preference->sign('White') for @blacks;
	$_->preference->sign('') for @nones;
	my @members = ( @whites, @blacks, @nones );
	my $bracket = Games::Tournament::Swiss::Bracket->new(
		score => 1, members => \@members );
	return $bracket->x;
}

run_is input => 'expected';

__DATA__

=== t330
--- input
players: W B W B W B
--- expected
0

=== t330
--- input
players: B W B W B W
--- expected
0

=== t240
--- input
players: B B W W B B
--- expected
1

=== t330
--- input
players: B B W W B W
--- expected
0

=== t330
--- input
players: B B W B W W
--- expected
0

=== t240
--- input
players: B B W B W B
--- expected
1

=== t231
--- input
players: B B W B W -
--- expected
0

=== t331
--- input
players: B B W B W - W
--- expected
0

=== t241
--- input
players: B B W B W - B
--- expected
0

=== t060
--- input
players: B B B B B B
--- expected
3

=== t009
--- input
players: - - - - - - - - -
--- expected
0

=== t108
--- input
players: W - - - - - - - -
--- expected
0
