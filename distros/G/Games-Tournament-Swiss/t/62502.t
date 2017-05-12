#!usr/bin/perl

# drawing 9 players over 4 rounds

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML;
use List::MoreUtils qw/any/;

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

my @rating = ( undef, 1518, 1508, 1500, 1496, 1489, 1480, 1453, 1336, 1300 );
my ($one, $two, $three, $four, $five, $six, $seven, $eight, $nine) = map { Games::Tournament::Contestant::Swiss->new ( name => "Player$_", id => 100 * $_, rating => $rating[$_] ) } 1..9;

my $t = Games::Tournament::Swiss->new(
    rounds   => 3,
    entrants => [$one, $two, $three, $four, $five, $six, $seven, $eight, $nine]
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
[ $m{0}->[3]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{'0Bye'}->[0]->isa('Games::Tournament::Card'), '$mbye isa'],
[ $one == $m{0}->[0]->contestants->{White},	'$m0 White'],
[ $five == $m{0}->[0]->contestants->{Black},	'$m0 Black'],
[ $six == $m{0}->[1]->contestants->{White},	'$m1 White'],
[ $two == $m{0}->[1]->contestants->{Black},	'$m1 Black'],
[ $three == $m{0}->[2]->contestants->{White},	'$m2 White'],
[ $seven == $m{0}->[2]->contestants->{Black},	'$m2 Black'],
[ $eight == $m{0}->[3]->contestants->{White},	'$m2 White'],
[ $four == $m{0}->[3]->contestants->{Black},	'$m2 Black'],
[ $nine == $m{'0Bye'}->[0]->contestants->{Bye},	'$m Bye'],
);

my @matches = map { @$_ } values %m;
for my $match ( @matches )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
	}
	elsif ( any { $four eq $_ } $match->myPlayers ) {
		my $role = $match->myRole( $four );
		my $opponentRole = $match->opponentRole( $role );
		$match->result({ $role => 'Win', $opponentRole => 'Loss' });
	}
	else {
		$match->result({Black => 'Win', White => 'Loss' }) 
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
[ $m2{1}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{1}->[1]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{'0Remainder'}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{0}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{'0RemainderBye'}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $two == $m2{1}->[0]->contestants->{White},	'@m2 White0'],
[ $five == $m2{1}->[0]->contestants->{Black},	'@m2 Black0'],
[ $four == $m2{1}->[1]->contestants->{White},	'@m2 White1'],
[ $nine == $m2{1}->[1]->contestants->{Black},	'@m2 Black1'],
[ $seven == $m2{0}->[0]->contestants->{White},	'@m2 White2'],
[ $one == $m2{0}->[0]->contestants->{Black},	'@m2 Black2'],
[ $six == $m2{'0Remainder'}->[0]->contestants->{White},	'@m2 White3'],
[ $three == $m2{'0Remainder'}->[0]->contestants->{Black},	'@m2 Black3'],
[ $eight == $m2{'0RemainderBye'}->[0]->contestants->{Bye},	'@m2 Bye'],
);

my @matches2 = map { @$_ } values %m2;
for my $match ( @matches2 )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
}
	elsif ( any { $four eq $_ } $match->myPlayers ) {
		my $role = $match->myRole( $four );
		my $opponentRole = $match->opponentRole( $role );
		$match->result({ $role => 'Win', $opponentRole => 'Loss' });
	}
	else {
		$match->result({Black => 'Win', White => 'Loss' })
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
[ $m3{2}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{1}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{1}->[1]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{1}->[2]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{'0Bye'}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $five == $m3{2}->[0]->contestants->{White},	'@m3 White0'],
[ $four == $m3{2}->[0]->contestants->{Black},	'@m3 Black0'],
[ $one == $m3{1}->[0]->contestants->{White},	'@m3 White1'],
[ $eight == $m3{1}->[0]->contestants->{Black},	'@m3 Black1'],
[ $three == $m3{1}->[1]->contestants->{White},	'@m3 White2'],
[ $two == $m3{1}->[1]->contestants->{Black},	'@m3 Black2'],
[ $nine == $m3{1}->[2]->contestants->{White},	'@m3 White2'],
[ $seven == $m3{1}->[2]->contestants->{Black},	'@m3 Black2'],
[ $six == $m3{'0Bye'}->[0]->contestants->{Bye},	'@m3 Bye'],
);

my @matches3 = map { @$_ } values %m3;
for my $match ( @matches3 )
{
	if ( $match->isBye ) {
		$match->result( { Bye => 'Bye' } );
	}
	elsif ( any { $four eq $_ } $match->myPlayers ) {
		my $role = $match->myRole( $four );
		my $opponentRole = $match->opponentRole( $role );
		$match->result({ $role => 'Win', $opponentRole => 'Loss' });
	}
	else {
		$match->result({Black => 'Win', White => 'Loss' })
				unless $match->result;
	}
}
$t->collectCards( @matches3 );
my %b4 = $t->formBrackets;
my $p4 = $t->pairing( \%b4 );
$p4->loggingAll;
my $paired4 = $p4->matchPlayers;
my %m4 = %{ $paired4->{matches} };
$t->round(4);

	push @tests, (
	[ $m4{2}->[0]->isa('Games::Tournament::Card'),	'42 isa'],
	[ $m4{'2Remainder'}->[0]->isa('Games::Tournament::Card'), '415R isa'],
	[ $m4{1}->[0]->isa('Games::Tournament::Card'), '415R isa'],
 	[ $m4{'1Remainder'}->[0]->isa('Games::Tournament::Card'), '415RB isa'],
 	[ $m4{'1RemainderBye'}->[0]->isa('Games::Tournament::Card'), '415RB isa'],
	[ $four == $m4{2}->[0]->contestants->{White},	'4 White0'],
	[ $two == $m4{2}->[0]->contestants->{Black},	'4 Black0'],
	[ $seven == $m4{'2Remainder'}->[0]->contestants->{White}, '4R White'],
	[ $eight == $m4{'2Remainder'}->[0]->contestants->{Black}, '4R Black'],
	[ $five == $m4{1}->[0]->contestants->{White}, '4R White'],
	[ $three == $m4{1}->[0]->contestants->{Black}, '4R Black'],
	[ $nine == $m4{'1Remainder'}->[0]->contestants->{White}, '4R White'],
	[ $six == $m4{'1Remainder'}->[0]->contestants->{Black}, '4R Black'],
	[ $one == $m4{'1RemainderBye'}->[0]->contestants->{Bye}, '4RB Bye'],
	);

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests;
