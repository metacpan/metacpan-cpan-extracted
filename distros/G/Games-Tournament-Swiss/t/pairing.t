#!usr/bin/perl

# 9-player, 3-round, consistent strong player winning pairing by Dummy

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::Dummy';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;

my $a = Games::Tournament::Contestant::Swiss->new(
    id => 1, name => 'Ros', title  => 'Expert', rating => 100,);
my $b = Games::Tournament::Contestant::Swiss->new(
    id => 2, name => 'Ron', title  => 'Expert', rating => 80,);
my $c = Games::Tournament::Contestant::Swiss->new(
    id => 3, name => 'Rog', score  => 0, title  => 'Expert', rating => '50',);
my $d = Games::Tournament::Contestant::Swiss->new(
    id => 4, name   => 'Ray', title  => 'Novice', rating => 25,);
my $e = Games::Tournament::Contestant::Swiss->new(
    id => 5, name => 'Rob', score => 0, title => 'Novice', rating => 3,);
my $f = Games::Tournament::Contestant::Swiss->new(
    id => 6, name => 'Rod', score => 0, title  => 'Novice', rating => 2,);
my $g = Games::Tournament::Contestant::Swiss->new(
    id => 7, name  => 'Reg', score => 0, title => 'Novice', rating => 1,);
my $h = Games::Tournament::Contestant::Swiss->new(
    id => 8, name  => 'Red', score => 0, title => 'Novice',);
my $i = Games::Tournament::Contestant::Swiss->new(
    id    => 9, name  => 'Roy', score => 0, title => 'Novice',);

my $t = Games::Tournament::Swiss->new(
    rounds   => 3, entrants => [ $a, $b, $c, $d, $e, $f, $g, $h, $i ]);

$t->round(0);

$t->assignPairingNumbers;
$t->initializePreferences;

my %b = $t->formBrackets;
my $pairing  = $t->pairing( \%b );
$pairing->matchPlayers;
my %m = %{ $pairing->matches };
$t->round(1);

my @tests = (
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
[ $m{0}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0}->[2]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{0}->[3]->isa('Games::Tournament::Card'),	'$m3 isa'],
[ $m{0}->[4]->isa('Games::Tournament::Card'),	'$m4 isa'],
[ $a == $m{0}->[0]->contestants->{White},	'$m0 participant1'],
[ $b == $m{0}->[0]->contestants->{Black},	'$m0 participant2'],
[ $c == $m{0}->[1]->contestants->{White},	'$m1 participant1'],
[ $d == $m{0}->[1]->contestants->{Black},	'$m1 participant2'],
[ $e == $m{0}->[2]->contestants->{White},	'$m2 participant1'],
[ $f == $m{0}->[2]->contestants->{Black},	'$m2 participant2'],
[ $g == $m{0}->[3]->contestants->{White},	'$m3 participant1'],
[ $h == $m{0}->[3]->contestants->{Black},	'$m3 participant2'],
[ $i == $m{0}->[4]->contestants->{Bye},	'$m4 byer'],
);

my @matches = map { @$_ } values %m;
for my $match ( @matches )
{
	my @partners = $match->myPlayers;
	if (@partners == 2)
	{
		my ($stronger, $weaker) =
			$partners[0]->rating >= $partners[1]->rating ?
			($partners[0], $partners[1]) :
			($partners[1], $partners[0]);
		$match->result({ $match->myRole($stronger) => 'Win' });
	}
	$match->canonize;
}
$t->collectCards( @matches );
my %b2 = $t->formBrackets;
my $p2  = $t->pairing( \%b2 );
$p2->matchPlayers;
my %m2 = %{ $p2->matches };
$t->round(2);

push @tests, (
[ $m2{1}->[0]->isa('Games::Tournament::Card'),	'210 isa'],
[ $m2{1}->[1]->isa('Games::Tournament::Card'),	'211 isa'],
[ $m2{0}->[0]->isa('Games::Tournament::Card'),	'200 isa'],
[ $m2{0}->[1]->isa('Games::Tournament::Card'),	'201 isa'],
[ $m2{0}->[2]->isa('Games::Tournament::Card'),	'202 isa'],
[ $a == $m2{1}->[0]->contestants->{White},	'210 participant1'],
[ $c == $m2{1}->[0]->contestants->{Black},	'210 participant2'],
[ $e == $m2{1}->[1]->contestants->{White},	'211 participant1'],
[ $g == $m2{1}->[1]->contestants->{Black},	'211 participant2'],
[ $i == $m2{0}->[0]->contestants->{White},	'200 participant1'],
[ $b == $m2{0}->[0]->contestants->{Black},	'200 participant2'],
[ $d == $m2{0}->[1]->contestants->{White},	'201 participant1'],
[ $f == $m2{0}->[1]->contestants->{Black},	'201 participant2'],
[ $h == $m2{0}->[2]->contestants->{Bye},	'202 byer'],
);

my @matches2 = map { @$_ } values %m2;
for my $match ( @matches2 )
{
	my @pair = $match->myPlayers;
	if (@pair == 2)
	{
		my ($strong, $weak) = $pair[0]->rating >= $pair[1]->rating ?
			($pair[0], $pair[1]) : ($pair[1], $pair[0]);
		$match->result({ $match->myRole($strong) => 'Win' });
	}
	$match->canonize;
}
$t->collectCards( @matches2 );
my %b3 = $t->formBrackets;
my $p3  = $t->pairing( \%b3 );
$p3->matchPlayers;
my %m3 = %{ $p3->matches };
$t->round(3);

push @tests, (
[ $m3{2}->[0]->isa('Games::Tournament::Card'),	'320 isa'],
[ $m3{1}->[0]->isa('Games::Tournament::Card'),	'310 isa'],
[ $m3{1}->[1]->isa('Games::Tournament::Card'),	'311 isa'],
[ $m3{1}->[2]->isa('Games::Tournament::Card'),	'312 isa'],
[ $m3{0}->[0]->isa('Games::Tournament::Card'),	'300 isa'],
[ $a == $m3{2}->[0]->contestants->{White},	'320 participant1'],
[ $e == $m3{2}->[0]->contestants->{Black},	'320 participant2'],
[ $b == $m3{1}->[0]->contestants->{White},	'310 participant1'],
[ $c == $m3{1}->[0]->contestants->{Black},	'310 participant2'],
[ $d == $m3{1}->[1]->contestants->{White},	'311 participant1'],
[ $g == $m3{1}->[1]->contestants->{Black},	'311 participant2'],
[ $h == $m3{1}->[2]->contestants->{White},	'312 participant1'],
[ $i == $m3{1}->[2]->contestants->{Black},	'312 participant2'],
[ $f == $m3{0}->[0]->contestants->{Bye},	'300 byer'],
);

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests;
