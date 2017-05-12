#!usr/bin/perl

use lib qw/t lib/;

use strict;
use warnings;

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

my @g;
$g[0] = Games::Tournament::Card->new( round => 1, contestants => {A => $p[0], B => $p[7]}, result => {A => 'Loss', B => 'Win'} );
$g[1] = Games::Tournament::Card->new( round => 1, contestants => {A => $p[6], B => $p[1]}, result => {A => 'Loss', B => 'Win'} );
$g[2] = Games::Tournament::Card->new( round => 1, contestants => {A => $p[5], B => $p[2]}, result => {A => 'Loss', B => 'Win'} );
$g[3] = Games::Tournament::Card->new( round => 1, contestants => {A => $p[4], B => $p[3]}, result => {A => 'Loss', B => 'Win'} );

$g[4] = Games::Tournament::Card->new( round => 2, contestants => {A => $p[2], B => $p[0]}, result => {A => 'Loss', B => 'Win'} );
$g[5] = Games::Tournament::Card->new( round => 2, contestants => {A => $p[1], B => $p[7]}, result => {A => 'Loss', B => 'Win'} );
$g[6] = Games::Tournament::Card->new( round => 2, contestants => {A => $p[3], B => $p[6]}, result => {A => 'Loss', B => 'Win'} );
$g[7] = Games::Tournament::Card->new( round => 2, contestants => {A => $p[5], B => $p[4]}, result => {A => 'Loss', B => 'Win'} );

$g[8] = Games::Tournament::Card->new( round => 3, contestants => {A => $p[4], B => $p[0]}, result => {A => 'Loss', B => 'Win'} );
$g[9] = Games::Tournament::Card->new( round => 3, contestants => {A => $p[3], B => $p[1]}, result => {A => 'Loss', B => 'Win'} );
$g[10] = Games::Tournament::Card->new( round => 3, contestants => {A => $p[7], B => $p[2]}, result => {A => 'Loss', B => 'Win'} );
$g[11] = Games::Tournament::Card->new( round => 3, contestants => {A => $p[6], B => $p[5]}, result => {A => 'Loss', B => 'Win'} );

my $t = Games::Tournament::Swiss->new( rounds => 'many', entrants => \@p);
my %g;

$t->assignPairingNumbers( @p );
$t->initializePreferences;
$t->initializePreferences until $p[0]->preference->role eq
	$Games::Tournament::Swiss::Config::roles[0];

$t->round(3);

$t->collectCards(@g);

my $play = $t->play;

sub player {
	my $player = shift()-1;
	my @rounds = $t->met($p[$player], @p);
	my @opponents = map { $_->id } @p;
	my %rounds;
	@rounds{ @opponents } = @rounds;
	return \%rounds;
}
sub tourney { [ $t->met($p[shift()-1], @p) ] }
sub play { [ $t->met( $p[shift()-1], $p[shift()-1] ) ] };
sub game { my $game = shift; return [''] unless defined $game; [ $g[$game]->round ] };

filters { player => [qw/chomp player/],
		met => [qw/yaml/],
		tourney => [qw/tourney/],
		play => [qw/lines chomp play flatten head/],
		game => [qw/lines chomp game flatten head/],
};

run_is_deeply player => 'met';
run_is_deeply tourney => 'met';
run_is play => 'game';

__DATA__

=== p[0]
--- player
1
--- met
9430101: ''
9430102: ''
9430103: 2
9430104: ''
9430105: 3
9430108: ''
9430107: ''
9430109: 1
9430110: ''
9430106: ''

=== p[1]
--- player
2
--- met
9430101: ''
9430102: ''
9430103: ''
9430104: 3
9430105: ''
9430108: ''
9430107: 1
9430109: 2
9430110: ''
9430106: ''

=== p[2]
--- player
3
--- met
9430101: 2
9430102: ''
9430103: ''
9430104: ''
9430105: ''
9430108: 1
9430107: ''
9430109: 3
9430110: ''
9430106: ''

=== p[3]
--- player
4
--- met
9430101: ''
9430102: 3
9430103: ''
9430104: ''
9430105: 1
9430108: ''
9430107: 2
9430109: ''
9430110: ''
9430106: ''

=== p[4]
--- player
5
--- met
9430101: 3
9430102: ''
9430103: ''
9430104: 1
9430105: ''
9430108: 2
9430107: ''
9430109: ''
9430110: ''
9430106: ''

=== p[5]
--- player
6
--- met
9430101: ''
9430102: ''
9430103: 1
9430104: ''
9430105: 2
9430108: ''
9430107: 3
9430109: ''
9430110: ''
9430106: ''

=== p[6]
--- player
7
--- met
9430101: ''
9430102: 1
9430103: ''
9430104: 2
9430105: ''
9430108: 3
9430107: ''
9430109: ''
9430110: ''
9430106: ''

=== p[7]
--- player
8
--- met
9430101: 1
9430102: 2
9430103: 3
9430104: ''
9430105: ''
9430108: ''
9430107: ''
9430109: ''
9430110: ''
9430106: ''

=== p[8]
--- player
9
--- met
9430101: ''
9430102: ''
9430103: ''
9430104: ''
9430105: ''
9430108: ''
9430107: ''
9430109: ''
9430110: ''
9430106: ''

=== p[9]
--- player
10
--- met
9430101: ''
9430102: ''
9430103: ''
9430104: ''
9430105: ''
9430108: ''
9430107: ''
9430109: ''
9430110: ''
9430106: ''

=== p0
--- tourney
1
--- met
--- ['','',2,'',3,'','',1,'','']

=== p1
--- tourney
2
--- met
--- ['','','',3,'','',1,2,'','']

=== p2
--- tourney
3
--- met
--- [2,'','','','',1,'',3,'','']

=== p3
--- tourney
4
--- met
--- ['',3,'','',1,'',2,'','','']

=== p4
--- tourney
5
--- met
--- [3,'','',1,'',2,'','','','']

=== p5
--- tourney
6
--- met
--- ['','',1,'',2,'',3,'','','']

=== p6
--- tourney
7
--- met
--- ['',1,'',2,'',3,'','','','']

=== p7
--- tourney
8
--- met
--- [1,2,3,'','','','','','','']

=== p8
--- tourney
9
--- met
--- ['','','','','','','','','','']

=== p9
--- tourney
10
--- met
--- ['','','','','','','','','','']

=== p00
--- play
1
1
--- game

=== p01
--- play
0
1
--- game

=== p07
buggy. there are many-to-one games-to-round mappings.
--- play
1
8
--- game
0

=== p70
--- play
8
1
--- game
0

=== play16
--- play
2
7
--- game
1

=== play25
--- play
3
6
--- game
2

=== play43
--- play
4
5
--- game
3

=== play02
--- play
1
3
--- game
4

=== play71
--- play
8
2
--- game
5

=== play63
--- play
7
4
--- game
6

=== play54
--- play
6
5
--- game
7

=== play40
--- play
5
1
--- game
8

=== play31
--- play
2
4
--- game
9

=== play72
--- play
8
3
--- game
10

=== play56
--- play
6
7
--- game
11

=== play89
--- play
9
10
--- game

=== play09
--- play
1
10
--- game
