#!usr/bin/perl

# drawing 7 players over 3 (4?) rounds

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::FIDE';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;

my @members = Load(<<'...');
---
id: 1
name: One
rating: 12
title: Unknown
---
id: 2
name: Two
rating: 8
title: Unknown
---
id: 3
name: Three
rating: 4
title: Unknown
---
id: 4
name: Four
rating: 3
title: Unknown
---
id: 5
name: Five
rating: 2
title: Unknown
---
id: 6
name: Six
rating: 1
title: Unknown
---
id: 7
name: Seven
rating: 0
title: Unknown
...

my ($one, $two, $three, $four, $five, $six, $seven)
	= map { Games::Tournament::Contestant::Swiss->new(%$_) } @members;

my $t = Games::Tournament::Swiss->new(
    rounds   => 3,
    entrants => [$one, $two, $three, $four, $five, $six, $seven]
);

$t->round(0);
$t->assignPairingNumbers;
$t->initializePreferences;
$t->initializePreferences until $one->preference->role eq 'White';

my %b = $t->formBrackets;
my $pairing  = $t->pairing( \%b );
my $paired        = $pairing->matchPlayers;
my %m = %{ $paired->{matches} };
$t->round(1);

my @tests = (
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
[ $m{0}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0}->[2]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{'0Bye'}->[0]->isa('Games::Tournament::Card'), '$mbye isa'],
[ $one == $m{0}->[0]->contestants->{White},	'$m0 White'],
[ $four == $m{0}->[0]->contestants->{Black},	'$m0 Black'],
[ $two == $m{0}->[1]->contestants->{Black},	'$m1 Black'],
[ $five == $m{0}->[1]->contestants->{White},	'$m1 White'],
[ $three == $m{0}->[2]->contestants->{White},	'$m2 White'],
[ $six == $m{0}->[2]->contestants->{Black},	'$m2 Black'],
[ $seven == $m{'0Bye'}->[0]->contestants->{Bye},	'$m Bye'],
);

my @matches = map { @$_ } values %m;
for my $match ( @matches )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
	}
	else {
		$match->result({Black => 'Draw', White => 'Draw' }) 
				unless $match->result;
	}
}
$t->collectCards( @matches );
my %b2 = $t->formBrackets;
my $p2  = $t->pairing( \%b2 );
my $paired2        = $p2->matchPlayers;
my %m2 = %{ $paired2->{matches} };
$t->round(2);

push @tests, (
[ $m2{0.5}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{'0.5Remainder'}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{'0.5Remainder'}->[1]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{'0.5RemainderBye'}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $seven == $m2{0.5}->[0]->contestants->{White},	'@m2 White0'],
[ $one == $m2{0.5}->[0]->contestants->{Black},	'@m2 Black0'],
[ $two == $m2{'0.5Remainder'}->[0]->contestants->{White},	'@m2 White1'],
[ $three == $m2{'0.5Remainder'}->[0]->contestants->{Black},	'@m2 Black1'],
[ $four == $m2{'0.5Remainder'}->[1]->contestants->{White},	'@m2 White2'],
[ $five == $m2{'0.5Remainder'}->[1]->contestants->{Black},	'@m2 Black2'],
[ $six == $m2{'0.5RemainderBye'}->[0]->contestants->{Bye},	'@m2 Bye'],
);

my @matches2;
for my $bracket ( values %m2 )
{
	for my $match ( @$bracket )
	{
		push @matches2, $match if
				$match->isa('Games::Tournament::Card');
	}
}
for my $match ( @matches2 )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
	}
	else {
		$match->result({Black => 'Draw', White => 'Draw' })
				unless $match->result;
	}
}
$t->collectCards( @matches2 );
my %b3 = $t->formBrackets;
my $p3 = $t->pairing( \%b3 );
my $paired3 = $p3->matchPlayers;
my %m3 = %{ $paired3->{matches} };
$t->round(3);

push @tests, (
[ $m3{1.5}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{1}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{1}->[1]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{'1Bye'}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $six == $m3{1.5}->[0]->contestants->{White},	'@m3 White0'],
[ $seven == $m3{1.5}->[0]->contestants->{Black},	'@m3 Black0'],
[ $one == $m3{1}->[0]->contestants->{White},	'@m3 White1'],
[ $two == $m3{1}->[0]->contestants->{Black},	'@m3 Black1'],
[ $three == $m3{1}->[1]->contestants->{White},	'@m3 White2'],
[ $four == $m3{1}->[1]->contestants->{Black},	'@m3 Black2'],
[ $five == $m3{'1Bye'}->[0]->contestants->{Bye},	'@m3 Bye'],
);

my @teststoo;

# =begin comment text

my @matches3;
for my $bracket ( values %m3 )
{
	for my $match ( @$bracket )
	{
		push @matches3, $match if
				$match->isa('Games::Tournament::Card');
	}
}
for my $match ( @matches3 )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
	}
	else {
		$match->result({Black => 'Draw', White => 'Draw' })
				unless $match->result;
	}
}
$t->collectCards( @matches3 );
my %b4 = $t->formBrackets;
my $p4 = $t->pairing( \%b4 );
my $paired4 = $p4->matchPlayers;
my %m4 = %{ $paired4->{matches} };
$t->round(4);

# Round 4:  5 6 7 (2), 1 2 3 4 (1.5),

TODO: {
	my $problem = "Overvigourous exercise.";
	local $TODO = $problem;
	# skip $problem, 12 if 1;
	@teststoo = (
	[ $m4{2}->[0]->isa('Games::Tournament::Card'),	'42 isa'],
	[ $m4{'1.5'}->[0]->isa('Games::Tournament::Card'), '415R isa'],
	[ $m4{'1.5Remainder'}->[0]->isa('Games::Tournament::Card'), '415R isa'],
 	[ $m4{'1.5RemainderBye'}->[0]->isa('Games::Tournament::Card'), '415RB isa'],
	[ $five == $m4{2}->[0]->contestants->{White},	'4 White0'],
	[ $six == $m4{2}->[0]->contestants->{Black},	'4 Black0'],
	[ $seven == $m4{'1.5'}->[0]->contestants->{White}, '4R White'],
	[ $three == $m4{'1.5'}->[0]->contestants->{Black}, '4R Black'],
	[ $two == $m4{'1.5Remainder'}->[0]->contestants->{White}, '4R White'],
	[ $four == $m4{'1.5Remainder'}->[0]->contestants->{Black}, '4R Black'],
	[ $one == $m4{'1.5RemainderBye'}->[0]->contestants->{Bye}, '4RB Bye'],
	);
}

# =end comment text

# =cut

plan tests => $#tests + $#teststoo + 2;
# plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests;
ok( $_->[0], $_->[ 1, ], ) for @teststoo;
