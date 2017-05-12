#!usr/bin/perl

# preference testing at a glance

use lib qw/t lib/;

use strict;
use warnings;
use Test::Base;

use Games::Tournament::Contestant::Swiss::Preference;

filters { input => [ qw/chomp prefseries/ ], expected => [ qw/lines chomp array / ] };

plan tests => 1 * blocks;

use Games::Tournament::Swiss::Config;
my %unabbr = Games::Tournament::Swiss::Config->abbreviation;
$unabbr{'-'} = 'Unpaired';
my %abbr = reverse %unabbr;
$abbr{Unpaired} = 'U';

sub prefseries {
	my $play = shift;
	$play =~ s/^played: (.*)$/$1/;
	my @play = split /\s/, $play;
	my @roles = map { $unabbr{$_} || $_ } @play;
	my $pref = Games::Tournament::Contestant::Swiss::Preference->new;
	my $wants = 'prefer:';
	my $degree = 'degree:';
	for my $round ( 1 .. @roles )
	{
		my @oldRoles;
		if ($round > 1)
		{
			$oldRoles[1] = $roles[$round-1];
			$oldRoles[0] = $roles[$round-2];
		}
		else {
			$oldRoles[0] = $roles[$round-1];
		}
		$pref->update( \@oldRoles );
		my $role = $pref->role || 'Unpaired';
		my $strength = $pref->strength;
		$wants .= ' ' . $abbr{$role};
		$degree .= ' ' . $abbr{$strength};
	}
	return [ $wants, $degree ];
}

run_is_deeply input => 'expected';

__DATA__

=== good White
--- input
played: W B W B W B
--- expected
prefer: B W B W B W
degree: S M S M S M

=== good Black
--- input
played: B W B W B W
--- expected
prefer: W B W B W B
degree: S M S M S M

=== 2-color runs
--- input
played: B B W W B B
--- expected
prefer: W W W B W W
degree: S A S A S A

=== 2,2,1,1
--- input
played: B B W W B W
--- expected
prefer: W W W B W B
degree: S A S A S M

=== 2,1,1,2
--- input
played: B B W B W W
--- expected
prefer: W W W W W B
degree: S A S A S A

=== 2,1,1,1 preference streak
--- input
played: B B W B W B
--- expected
prefer: W W W W W W
degree: S A S A S A

=== bye preference streak
--- input
played: B B W B W -
--- expected
prefer: W W W W W W
degree: S A S A S S

=== post-bye preference end
--- input
played: B B W B W - W
--- expected
prefer: W W W W W W B
degree: S A S A S S M

=== post-bye pref streak not ended
--- input
played: B B W B W - B
--- expected
prefer: W W W W W W W
degree: S A S A S S A

=== n-round run
--- input
played: B B B B B B
--- expected
prefer: W W W W W W
degree: S A A A A A

=== no game, no role
--- input
played: - - - - - - - - -
--- expected
prefer: U U U U U U U U U
degree: M M M M M M M M M

=== absent after 1st round
--- input
played: W - - - - - - - -
--- expected
prefer: B B B B B B B B B
degree: S S S S S S S S S
