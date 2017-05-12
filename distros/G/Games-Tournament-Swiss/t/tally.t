#!usr/bin/perl

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::Dummy';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;

my $a = Games::Tournament::Contestant::Swiss->new( id => 1, name => 'Roy', title => 'Expert', rating => 100,  );
my $b = Games::Tournament::Contestant::Swiss->new( id => 2, name => 'Ron', title => 'Expert', rating => 80,  );
my $c = Games::Tournament::Contestant::Swiss->new( id => 3, name => 'Rog', score => 3, title => 'Expert', rating => '50', );
my $d = Games::Tournament::Contestant::Swiss->new( id => 4, name => 'Ray', title => 'Novice', rating => 25, );
my $e = Games::Tournament::Contestant::Swiss->new( id => 5, name => 'Rob', score => 3, title => 'Novice', rating => 1, );
my $f = Games::Tournament::Contestant::Swiss->new( id => 6, name => 'Ros', score => 3, title => 'Novice', rating => 0, );
my $g = Games::Tournament::Contestant::Swiss->new( id => 7, name => 'Reg', score => 3, title => 'Novice', );
my $h = Games::Tournament::Contestant::Swiss->new( id => 8, name => 'Red', score => 3, title => 'Novice', );

my $p = Games::Tournament::Swiss->new(
    rounds   => 3,
    entrants => [ $a, $b, $c, $d, $e, $f, $g, $h ]
);

$p->initializePreferences;

my $ah = Games::Tournament::Card->new( round => 1, contestants => {Black => $h, White => $a}, result => {Black => 'Loss'} );
my $ac = Games::Tournament::Card->new( round => 2, contestants => {Black => $a, White => $c}, result => {Black => 'Loss'} );
my $ae = Games::Tournament::Card->new( round => 3, contestants => {Black => $e, White => $a}, result => {Black => 'Loss'} );

my $bg = Games::Tournament::Card->new( round => 1, contestants => {Black => $g, White => $b}, result => {Black => 'Loss'} );
my $bh = Games::Tournament::Card->new( round => 2, contestants => {Black => $b, White => $h}, result => {Black => 'Loss'} );
my $bd = Games::Tournament::Card->new( round => 3, contestants => {Black => $d, White => $b}, result => {Black => 'Loss'} );

my $cf = Games::Tournament::Card->new( round => 1, contestants => {Black => $c, White => $f}, result => {Black => 'Loss'} );
my $ch = Games::Tournament::Card->new( round => 3, contestants => {Black => $c, White => $h}, result => {Black => 'Loss'} );

my $de = Games::Tournament::Card->new( round => 1, contestants => {Black => $e, White => $d}, result => {Black => 'Loss'} );
my $dg = Games::Tournament::Card->new( round => 2, contestants => {Black => $d, White => $g}, result => {Black => 'Loss'} );

my $ef = Games::Tournament::Card->new( round => 2, contestants => {Black => $f, White => $e}, result => {Black => 'Loss'} );

my $fg = Games::Tournament::Card->new( round => 3, contestants => {Black => $g, White => $f}, result => {Black => 'Loss'} );

$_->canonize for $ah, $ac, $ae, $bg, $bh, $bd, $cf, $ch, $de, $dg, $ef, $fg;

my $c2 = Games::Tournament::Contestant::Swiss->new( id => 3, name => 'Rog', score => 3, title => 'Expert', rating => '50', );
my $h2 = Games::Tournament::Contestant::Swiss->new( id => 8, name => 'Red', score => 3, title => 'Novice', );


$p->round(3);

$p->collectCards($ah,$bg,$cf,$de);
$p->collectCards($bh,$ac,$dg,$ef);
$p->collectCards($ch,$bd,$ae,$fg);

my @tests = (
[ [$p->met($a,$b,$c,$d,$e,$f,$g,$h)],	['',2,'',3,'','',1], '$a met'],
[ [$p->met($h,$a,$b,$c,$d,$e,$f,$g)],	[1,2,3,'','','',''], '$h met'],

[ $p->met($h,$c),	(3), '$c met $h'],
[ $p->met($h2,$c2),	(''), '$h no met $c'],
[ $p->whoPlayedWho->{1},	{8=>1, 3=>2, 5=>3}, 'whoPlayedWho1'],
[ $p->whoPlayedWho->{2},	{7,1, 8,2, 4,3}, 'whoPlayedWho2'],
[ $p->whoPlayedWho->{3},	{6,1, 1,2, 8,3}, 'whoPlayedWho3'],
[ $p->whoPlayedWho->{4},	{5,1, 7,2, 2,3}, 'whoPlayedWho4'],
[ $p->whoPlayedWho->{5},	{4,1, 6,2, 1,3}, 'whoPlayedWho5'],
[ $p->whoPlayedWho->{6},	{3,1, 5,2, 7,3}, 'whoPlayedWho6'],
[ $p->whoPlayedWho->{7},	{2,1, 4,2, 6,3}, 'whoPlayedWho7'],
[ $p->whoPlayedWho->{8},	{1,1, 2,2, 3,3}, 'whoPlayedWho8'],
);

plan tests => $#tests + 1;

map { is_deeply( $_->[0], $_->[ 1, ], $_->[2] ) } @tests;
