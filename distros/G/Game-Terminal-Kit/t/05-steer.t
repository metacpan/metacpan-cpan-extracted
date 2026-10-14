#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Steer;

sub ring { return Game::Terminal::Kit::Steer::ring(@_) }
sub clamp { return Game::Terminal::Kit::Steer::clamp(@_) }
sub nearest { return Game::Terminal::Kit::Steer::nearest(@_) }
sub axis { return Game::Terminal::Kit::Steer::axis(@_) }
sub rest { return Game::Terminal::Kit::Steer::rest(@_) }

subtest 'an arrow key is a direction' => sub {
	plan tests => 6;
	is_deeply [Game::Terminal::Kit::Steer::way('up')], [0, -1], 'up is a smaller row';
	is_deeply [Game::Terminal::Kit::Steer::way('down')], [0, 1], 'down is a greater row';
	is_deeply [Game::Terminal::Kit::Steer::way('left')], [-1, 0], 'left';
	is_deeply [Game::Terminal::Kit::Steer::way('right')], [1, 0], 'right';
	is_deeply [Game::Terminal::Kit::Steer::way('enter')], [], 'another key is no direction';
	is_deeply [Game::Terminal::Kit::Steer::way(undef)], [], 'nor is no key';
};

subtest 'round a ring' => sub {
	plan tests => 13;
	is ring(5, 0, +1), 1, 'on from the first';
	is ring(5, 4, +1), 0, 'round from the last';
	is ring(5, 0, -1), 4, 'round from the first';
	is ring(5, 4, -1), 3, 'back from the last';
	is ring(5, 2, 0), 2, 'no step stays';
	is ring(0, 0, +1), 0, 'nothing to walk stays';
	is ring(1, 0, +1), 0, 'one thing stays';

	my $skip = sub { $_[0] == 0 || $_[0] == 4 };
	is ring(5, 3, +1, $skip), 1, 'forward over a skipped last and first';
	is ring(5, 1, -1, $skip), 3, 'backward over a skipped first and last';
	is ring(5, 2, +1, sub { 1 }), 2, 'all skipped stays';
	is ring(5, 2, +1, sub { $_[0] != 2 }), 2, 'the only one open is where it is';

	my @seen = (0);
	push @seen, ring(4, $seen[-1], +1) for 1 .. 4;
	is_deeply \@seen, [0, 1, 2, 3, 0], 'a whole turn forward visits each in order';
	@seen = (0);
	push @seen, ring(4, $seen[-1], -1) for 1 .. 4;
	is_deeply \@seen, [0, 3, 2, 1, 0], 'and backward';
};

subtest 'stopping at the ends' => sub {
	plan tests => 10;
	is clamp(5, 0, +1), 1, 'on from the first';
	is clamp(5, 4, +1), 4, 'stops at the last';
	is clamp(5, 0, -1), 0, 'stops at the first';
	is clamp(5, 1, +10), 4, 'a long step stops at the last';
	is clamp(5, 3, -10), 0, 'and at the first';
	is clamp(0, 0, +1), 0, 'nothing to walk stays';

	my $skip = sub { $_[0] == 0 || $_[0] == 4 };
	is clamp(5, 3, +1, $skip), 3, 'a skipped last is not rested on';
	is clamp(5, 1, -1, $skip), 1, 'nor a skipped first';
	is clamp(5, 1, +1, sub { $_[0] == 2 }), 3, 'a skipped middle is stepped over';
	is clamp(5, 2, -10, $skip), 2, 'a long step to a skipped end stays';
};

my @grid = map { my $y = $_; map { [ $_, $y ] } 0 .. 2 } 0 .. 2;

subtest 'the nearest thing that way, on a square board' => sub {
	plan tests => 17;
	is nearest(\@grid, 4, 0, -1), 1, 'up from the centre';
	is nearest(\@grid, 4, 0, 1), 7, 'down';
	is nearest(\@grid, 4, -1, 0), 3, 'left';
	is nearest(\@grid, 4, 1, 0), 5, 'right';
	is nearest(\@grid, 4, -1, -1), 0, 'up and left';
	is nearest(\@grid, 4, 1, -1), 2, 'up and right';
	is nearest(\@grid, 4, -1, 1), 6, 'down and left';
	is nearest(\@grid, 4, 1, 1), 8, 'down and right';

	is nearest(\@grid, 0, 0, -1), undef, 'nothing above the top left';
	is nearest(\@grid, 0, -1, 0), undef, 'nor to its left';
	is nearest(\@grid, 0, 1, 0), 1, 'but there is to its right';
	is nearest(\@grid, 8, 0, 1), undef, 'nothing below the bottom right';
	is nearest(\@grid, 8, 1, 0), undef, 'nor to its right';
	is nearest(\@grid, 8, -1, 0), 7, 'but there is to its left';

	is nearest(\@grid, 4, 0, 0), undef, 'no direction goes nowhere';
	is nearest(\@grid, 9, 1, 0), undef, 'a cursor that is nowhere goes nowhere';
	is nearest([[0, 0]], 0, 1, 0), undef, 'one thing has no neighbour';
};

subtest 'straight ahead before close by' => sub {
	plan tests => 9;
	my @points = ([0, 0], [3, 0], [1, 1]);
	is nearest(\@points, 0, 1, 0), 1, 'three along beats one along and one across';
	is nearest(\@points, 0, 0, 1), 2, 'down finds the one below';

	my @tie = ([0, 0], [2, 1], [4, 0]);
	is nearest(\@tie, 0, 1, 0), 2, 'at the same cost the one less far across wins';
	is nearest([[0, 0], [4, 0], [2, 1]], 0, 1, 0), 1, 'whatever order they were drawn in';
	is nearest([[0, 0], [2, 1], [2, -1]], 0, 1, 0), 1, 'and the first drawn wins a dead heat';

	my @side = ([0, 0], [1, 3]);
	is nearest(\@side, 0, 1, 0), 1, 'without a cone, a thing mostly below is still to the right';
	is nearest(\@side, 0, 1, 0, cone => 1), undef, 'with a cone it is not';
	is nearest([[0, 0], [2, 2]], 0, 1, 0, cone => 1), 1, 'the edge of the cone is inside it';

	is nearest(\@grid, 4, 1, 0, skip => sub { $_[0] == 5 }), 2, 'a skipped point is passed over';
};

subtest 'along a track' => sub {
	plan tests => 10;
	my @track = ([4, 0], [0, 0], [2, 1], [2, 0]);
	is axis(\@track, 1, 1, 0), 3, 'right, to the next column, upper first';
	is axis(\@track, 3, 1, 0), 2, 'then the lower in the same column';
	is axis(\@track, 2, 1, 0), 0, 'then the next column';
	is axis(\@track, 0, 1, 0), 0, 'and stops at the right end';
	is axis(\@track, 1, -1, 0), 1, 'and at the left end';
	is axis(\@track, 0, -1, 0), 2, 'left is the same walk backwards';

	is axis(\@track, 1, 0, 1), 3, 'down, along the top row first';
	is axis(\@track, 0, 0, 1), 2, 'from the end of the top row to the next row';
	is axis(\@track, 2, 0, 1), 2, 'and stops at the bottom';
	is axis(\@track, 2, 0, 0), 2, 'no direction stays';
};

subtest 'where to start' => sub {
	plan tests => 8;
	my @hand = ({ card => 'KH', meld => 1 }, { card => 'KS', meld => 1 }, { card => '4D' }, { card => '9C' });
	is rest(\@hand), 0, 'the first, with nothing preferred';
	is rest(\@hand, sub { !$_[0]{meld} }), 2, 'the first that is preferred';
	is rest(\@hand, sub { $_[0]{card} eq 'ZZ' }), 0, 'the first when none is';
	is rest(\@hand, sub { $_[1] == 3 }), 3, 'the index is passed too, and the last can be chosen';

	my @drawn = ({ card => 'taken', skip => 1 }, { card => '4D' }, { card => '9C', skip => 1 });
	is rest(\@drawn), 1, 'a skipped first is passed over';
	is rest(\@drawn, sub { $_[0]{card} eq '9C' }), 1, 'a skipped item is not chosen though preferred';
	is rest([{ skip => 1 }, { skip => 1 }]), 0, 'all skipped is 0';
	is rest([]), 0, 'and so is nothing';
};

done_testing;
