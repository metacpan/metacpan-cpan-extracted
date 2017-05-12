#!usr/bin/perl

use lib qw/t lib/;

use strict;
use warnings;

# use Games::Tournament::Swiss::Test;
use Test::Base -base;

BEGIN {
	@Games::Tournament::Swiss::Config::roles = (qw/A B/);
	$Games::Tournament::Swiss::Config::firstround = 1;
	$Games::Tournament::Swiss::Config::algorithm = 'Games::Tournament::Swiss::Procedure::Dummy';
}

my @roles = @Games::Tournament::Swiss::Config::roles;


plan tests => 1*blocks;

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;
use Games::Tournament::Swiss::Procedure;

my @p;
$p[0] = Games::Tournament::Contestant::Swiss->new( id => 9430101, name => 'Roy', score => 0, title => 'Expert', rating => 100,  );
$p[1] = Games::Tournament::Contestant::Swiss->new( id => 9430102, name => 'Ron', score => 0, title => 'Expert', rating => 80,  );
$p[2] = Games::Tournament::Contestant::Swiss->new( id => 9430103, name => 'Rog', score => 0, title => 'Expert', rating => '50', );
$p[3] = Games::Tournament::Contestant::Swiss->new( id => 9430104, name => 'Ray', score => 0, title => 'Novice', rating => 25, );
$p[4] = Games::Tournament::Contestant::Swiss->new( id => 9430105, name => 'Rob', score => 0, title => 'Novice', rating => 1, );
$p[5] = Games::Tournament::Contestant::Swiss->new( id => 9430108, name => 'Red', score => 0, title => 'Novice', rating => 0, );
$p[6] = Games::Tournament::Contestant::Swiss->new( id => 9430107, name => 'Reg', score => 0, title => 'Novice', rating => 0, );
$p[7] = Games::Tournament::Contestant::Swiss->new( id => 9430109, name => 'Rex', score => 0, title => 'Novice', rating => 0, );
$p[8] = Games::Tournament::Contestant::Swiss->new( id => 9430110, name => 'Rod', score => 0, title => 'Novice', rating => 0, );
$p[9] = Games::Tournament::Contestant::Swiss->new( id => 9430106, name => 'Ros', score => 0, title => 'Novice', rating => 0, );

my $t = Games::Tournament::Swiss->new( rounds => 'many', entrants => \@p);
my %g;

my $round = 0;
$t->round($round);
$t->assignPairingNumbers( @p );
$t->initializePreferences;
$t->initializePreferences until $p[0]->preference->role eq
	$Games::Tournament::Swiss::Config::roles[0];

sub runRound {
	my $round = shift;
	my %b = $t->formBrackets;
	my $p  = $t->pairing( \%b );
	$g{$round}        = $p->matchPlayers;
	my @games;
	for my $bracket ( keys %{ $g{$round} } )
	{
		my $tables = $g{$round}->{$bracket};
		$_->result({A => 'Win', B => 'Loss'}) for @$tables;
		push @games, @$tables;
	}
	$t->collectCards( @games );
	$t->round($round);
};

runRound(1);
runRound(2);
runRound(3);
runRound(4);
runRound(5);
runRound(6);
runRound(7);
runRound(8);
runRound(9);
runRound(10);

sub round
{
	my $round = shift;
	my $brackets = $g{$round};
	my %tables;
	for my $key ( sort keys %$brackets )
	{
		my $bracket = $brackets->{$key};
		for my $game ( @$bracket )
		{
			my $players = $game->contestants;
			my @ids = map { $players->{$_}->pairingNumber } @roles;
			push @{$tables{$key}}, \@ids;
		}
	}
	return \%tables;
}

run_is_deeply input => 'expected';

__DATA__

=== Round 1
--- input chomp round
1
--- expected yaml
0:
 -
  - 1
  - 2
 -
  - 3
  - 4
 -
  - 5
  - 6
 -
  - 7
  - 8
 -
  - 9
  - 10

=== Round 2
--- input chomp round
2
--- expected yaml
1:
 -
  - 1
  - 3
 -
  - 5
  - 7
0:
 -
  - 9
  - 2
 -
  - 4
  - 6
 -
  - 8
  - 10

=== Round 3
--- input chomp round
3
--- expected yaml
2:
 -
  - 1
  - 5
1:
 -
  - 9
  - 3
 -
  - 4
  - 7
0:
 -
  - 8
  - 2
 -
  - 6
  - 10

=== Round 4
--- input chomp round
4
--- expected yaml
3:
 -
  - 1
  - 9
2:
 -
  - 4
  - 5
1:
 -
  - 8
  - 3
 -
  - 6
  - 7
0:
 -
  - 2
  - 10

=== Round 5
--- input chomp round
5
--- expected yaml
3:
 -
  - 1
  - 4
 -
  - 8
  - 9
2:
 -
  - 5
  - 6
1:
 -
  - 2
  - 3
0:
 -
  - 7
  - 10

=== Round 6
--- input chomp round
6
--- expected yaml
4:
 -
  - 1
  - 8
3:
 -
  - 4
  - 5
2:
 -
  - 9
  - 2
 -
  - 6
  - 7
0:
 -
  - 3
  - 10

=== Round 7
--- input chomp round
7
--- expected yaml
4:
 -
  - 1
  - 4
 -
  - 8
  - 9
3:
 -
  - 5
  - 6
2:
 -
  - 2
  - 3
0:
 -
  - 7
  - 10

=== Round 8
--- input chomp round
8
--- expected yaml
5:
 -
  - 1
  - 8
4:
 -
  - 4
  - 5
3:
 -
  - 9
  - 2
 -
  - 6
  - 7
0:
 -
  - 3
  - 10

=== Round 9
--- input chomp round
9
--- expected yaml
5:
 -
  - 1
  - 4
 -
  - 8
  - 9
4:
 -
  - 5
  - 6
3:
 -
  - 2
  - 3
0:
 -
  - 7
  - 10

=== Round 10
--- input chomp round
10
--- expected yaml
6:
 -
  - 1
  - 8
5:
 -
  - 4
  - 5
4:
 -
  - 9
  - 2
 -
  - 6
  - 7
0:
 -
  - 3
  - 10

