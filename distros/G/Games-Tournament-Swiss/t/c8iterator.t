#!usr/bin/perl

# 3-to-10-player bracket c8iterator testing

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
use Games::Tournament::Swiss::Bracket;

my $one = Games::Tournament::Contestant::Swiss->new(
    id => 1, name => 'Zero', title  => 'Expert', rating => 100,);
my $two = Games::Tournament::Contestant::Swiss->new(
    id => 2, name => 'One', title  => 'Expert', rating => 80,);
my $three = Games::Tournament::Contestant::Swiss->new(
    id => 3, name => 'Two', score  => 0, title  => 'Expert', rating => '50',);
my $four = Games::Tournament::Contestant::Swiss->new(
    id => 4, name   => 'Three', title  => 'Novice', rating => 25,);
my $five = Games::Tournament::Contestant::Swiss->new(
    id => 5, name => 'Four', score => 0, title => 'Novice', rating => 10,);
my $six = Games::Tournament::Contestant::Swiss->new(
    id => 6, name => 'Five', score => 0, title  => 'Novice', rating => 8,);
my $seven = Games::Tournament::Contestant::Swiss->new(
    id => 7, name  => 'Six', score => 0, title => 'Novice', rating => 6,);
my $eight = Games::Tournament::Contestant::Swiss->new(
    id => 8, name  => 'Seven', score => 0, title => 'Novice', rating => 4,);
my $nn = Games::Tournament::Contestant::Swiss->new(
    id    => 9, name  => 'Eight', score => 0, title => 'Novice', rating => 3);
my $tn = Games::Tournament::Contestant::Swiss->new(
    id    => 10, name  => 'Nine', score => 0, title => 'Novice', rating => 2);

my $b2 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, ]);

my $b3 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, ]);

my $b4 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four ]);

my $b5 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four, $five ]);

my $b6 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four, $five, $six ]);

my $b7 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven]);

my $b8 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight]);

my $b9 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight,$nn]);

my $b10 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight,$nn,$tn]);

my %next;
$next{2} = $b2->c8iterator;
$next{3} = $b3->c8iterator;
$next{4} = $b4->c8iterator;
$next{5} = $b5->c8iterator;
$next{6} = $b6->c8iterator;
$next{7} = $b7->c8iterator;
$next{8} = $b8->c8iterator;
$next{9} = $b9->c8iterator;
$next{10} = $b10->c8iterator;

my @tests = (
2,
[ ['last S1,S2 exchange'],	'swap 2 last'],
3,
[ ['exchange a', $two,$one,$three],	'swap 3a'],
[ ['last S1,S2 exchange'],	'swap 3 last'],
4,
[ ['exchange a', $one,$three,$two,$four],	'swap 4a'],
[ ['last S1,S2 exchange'],	'swap 4 last'],
5,
[ ['exchange a', $one,$three,$two,$four,$five],	'swap 5a'],
[ ['exchange b', $one,$four,$three,$two,$five],	'swap 5b'],
[ ['exchange c', $three,$two,$one,$four,$five],	'swap 5c'],
[ ['exchange d', $four,$two,$three,$one,$five],	'swap 5d'],
[ ['last S1,S2 exchange'],	'swap 5 last'],
6,
[ ['exchange a', $one,$two,$four,$three,$five,$six],	'swap 6a'],
[ ['exchange b', $one,$two,$five,$four,$three,$six],	'swap 6b'],
[ ['exchange c', $one,$four,$three,$two,$five,$six],	'swap 6c'],
[ ['exchange d', $one,$five,$three,$four,$two,$six],	'swap 6d'],
[ ['exchange e', $one,$four,$five,$two,$three,$six],	'swap 6e'],
[ ['last S1,S2 exchange'],	'swap 6 last'],
7,
[ ['exchange a', $one,$two,$four,$three,$five,$six,$seven], 'swap 7a'],
[ ['exchange b', $one,$two,$five,$four,$three,$six,$seven], 'swap 7b'],
[ ['exchange c', $one,$four,$three,$two,$five,$six,$seven], 'swap 7c'],
[ ['exchange d', $one,$two,$six,$four,$five,$three,$seven], 'swap 7d'],
[ ['exchange e', $one,$five,$three,$four,$two,$six,$seven], 'swap 7e'],
[ ['exchange f', $four,$two,$three,$one,$five,$six,$seven], 'swap 7f'],
[ ['exchange g', $one,$six,$three,$four,$five,$two,$seven], 'swap 7g'],
[ ['exchange h', $five,$two,$three,$four,$one,$six,$seven], 'swap 7h'],
[ ['exchange i', $six,$two,$three,$four,$five,$one,$seven], 'swap 7i'],
[ ['exchange j', $one,$four,$five,$two,$three,$six,$seven], 'swap 7j'],
[ ['exchange k', $one,$four,$six,$two,$five,$three,$seven], 'swap 7k'],
[ ['exchange l', $four,$two,$five,$one,$three,$six,$seven], 'swap 7l'],
[ ['exchange m', $one,$five,$six,$four,$two,$three,$seven], 'swap 7m'],
[ ['exchange n', $four,$two,$six,$one,$five,$three,$seven], 'swap 7n'],
[ ['exchange o', $five,$two,$six,$four,$one,$three,$seven], 'swap 7o'],
[ ['last S1,S2 exchange'], 'swap 7 last'],
8,
[ ['exchange a', $one,$two,$three,$five,$four,$six,$seven,$eight], 'swap 8a'],
[ ['exchange b', $one,$two,$three,$six,$five,$four,$seven,$eight], 'swap 8b'],
[ ['exchange c', $one,$two,$five,$four,$three,$six,$seven,$eight], 'swap 8c'],
[ ['exchange d', $one,$two,$three,$seven,$five,$six,$four,$eight], 'swap 8d'],
[ ['exchange e', $one,$two,$six,$four,$five,$three,$seven,$eight], 'swap 8e'],
[ ['exchange f', $one,$five,$three,$four,$two,$six,$seven,$eight], 'swap 8f'],
[ ['exchange g', $one,$two,$seven,$four,$five,$six,$three,$eight], 'swap 8g'],
[ ['exchange h', $one,$six,$three,$four,$five,$two,$seven,$eight], 'swap 8h'],
[ ['exchange i', $one,$seven,$three,$four,$five,$six,$two,$eight], 'swap 8i'],
[ ['exchange j', $one,$two,$five,$six,$three,$four,$seven,$eight], 'swap 8j'],
[ ['exchange k', $one,$two,$five,$seven,$three,$six,$four,$eight], 'swap 8k'],
[ ['exchange l', $one,$five,$three,$six,$two,$four,$seven,$eight], 'swap 8l'],
[ ['exchange m', $one,$two,$six,$seven,$five,$three,$four,$eight], 'swap 8m'],
[ ['exchange n', $one,$five,$three,$seven,$two,$six,$four,$eight], 'swap 8n'],
[ ['exchange o', $one,$five,$six,$four,$two,$three,$seven,$eight], 'swap 8o'],
[ ['exchange p', $one,$six,$three,$seven,$five,$two,$four,$eight], 'swap 8p'],
[ ['exchange q', $one,$five,$seven,$four,$two,$six,$three,$eight], 'swap 8q'],
[ ['exchange r', $one,$six,$seven,$four,$five,$two,$three,$eight], 'swap 8r'],
[ ['last S1,S2 exchange'], 'swap 8 last'],
9,
[['exchange a',$one,$two,$three,$five,$four,$six,$seven,$eight,$nn], 'swap9a'],
[['exchange b',$one,$two,$three,$six,$five,$four,$seven,$eight,$nn], 'swap9b'],
[['exchange c',$one,$two,$five,$four,$three,$six,$seven,$eight,$nn], 'swap9c'],
[['exchange d',$one,$two,$three,$seven,$five,$six,$four,$eight,$nn], 'swap9d'],
[['exchange e',$one,$two,$six,$four,$five,$three,$seven,$eight,$nn], 'swap9e'],
[['exchange f',$one,$five,$three,$four,$two,$six,$seven,$eight,$nn], 'swap9f'],
[['exchange g',$one,$two,$three,$eight,$five,$six,$seven,$four,$nn], 'swap9g'],
[['exchange h',$one,$two,$seven,$four,$five,$six,$three,$eight,$nn], 'swap9h'],
[['exchange i',$one,$six,$three,$four,$five,$two,$seven,$eight,$nn], 'swap9i'],
[['exchange j',$five,$two,$three,$four,$one,$six,$seven,$eight,$nn], 'swap9j'],
[['exchange k',$one,$two,$eight,$four,$five,$six,$seven,$three,$nn], 'swap9k'],
[['exchange l',$one,$seven,$three,$four,$five,$six,$two,$eight,$nn], 'swap9l'],
[['exchange m',$six,$two,$three,$four,$five,$one,$seven,$eight,$nn], 'swap9m'],
[['exchange n',$one,$eight,$three,$four,$five,$six,$seven,$two,$nn], 'swap9n'],
[['exchange o',$seven,$two,$three,$four,$five,$six,$one,$eight,$nn], 'swap9o'],
[['exchange p',$eight,$two,$three,$four,$five,$six,$seven,$one,$nn], 'swap9p'],
[['exchange q',$one,$two,$five,$six,$three,$four,$seven,$eight,$nn], 'swap9q'],
[['exchange r',$one,$two,$five,$seven,$three,$six,$four,$eight,$nn], 'swap9r'],
[['exchange s',$one,$five,$three,$six,$two,$four,$seven,$eight,$nn], 'swap9s'],
[['exchange t',$one,$two,$five,$eight,$three,$six,$seven,$four,$nn], 'swap9t'],
[['exchange u',$one,$five,$three,$seven,$two,$six,$four,$eight,$nn], 'swap9u'],
[['exchange v',$five,$two,$three,$six,$one,$four,$seven,$eight,$nn], 'swap9v'],
[['exchange w',$one,$two,$six,$seven,$five,$three,$four,$eight,$nn], 'swap9w'],
[['exchange x',$one,$five,$three,$eight,$two,$six,$seven,$four,$nn], 'swap9x'],
[['exchange y',$five,$two,$three,$seven,$one,$six,$four,$eight,$nn], 'swap9y'],
[['exchange z',$one,$five,$six,$four,$two,$three,$seven,$eight,$nn], 'swap9z'],
[['exchange aa',$one,$two,$six,$eight,$five,$three,$seven,$four,$nn],'swap9aa'],
[['exchange ab',$one,$six,$three,$seven,$five,$two,$four,$eight,$nn],'swap9ab'],
[['exchange ac',$five,$two,$three,$eight,$one,$six,$seven,$four,$nn],'swap9ac'],
[['exchange ad',$one,$five,$seven,$four,$two,$six,$three,$eight,$nn],'swap9ad'],
[['exchange ae',$five,$two,$six,$four,$one,$three,$seven,$eight,$nn],'swap9ae'],
[['exchange af',$one,$two,$seven,$eight,$five,$six,$three,$four,$nn],'swap9af'],
[['exchange ag',$one,$six,$three,$eight,$five,$two,$seven,$four,$nn],'swap9ag'],
[['exchange ah',$six,$two,$three,$seven,$five,$one,$four,$eight,$nn],'swap9ah'],
[['exchange ai',$one,$five,$eight,$four,$two,$six,$seven,$three,$nn],'swap9ai'],
[['exchange aj',$five,$two,$seven,$four,$one,$six,$three,$eight,$nn],'swap9aj'],
[['exchange ak',$one,$seven,$three,$eight,$five,$six,$two,$four,$nn],'swap9ak'],
[['exchange al',$six,$two,$three,$eight,$five,$one,$seven,$four,$nn],'swap9al'],
[['exchange am',$one,$six,$seven,$four,$five,$two,$three,$eight,$nn],'swap9am'],
[['exchange an',$five,$two,$eight,$four,$one,$six,$seven,$three,$nn],'swap9an'],
[['exchange ao',$seven,$two,$three,$eight,$five,$six,$one,$four,$nn],'swap9ao'],
[['exchange ap',$one,$six,$eight,$four,$five,$two,$seven,$three,$nn],'swap9ap'],
[['exchange aq',$six,$two,$seven,$four,$five,$one,$three,$eight,$nn],'swap9aq'],
[['exchange ar',$one,$seven,$eight,$four,$five,$six,$two,$three,$nn],'swap9ar'],
[['exchange as',$six,$two,$eight,$four,$five,$one,$seven,$three,$nn],'swap9as'],
[['exchange at',$seven,$two,$eight,$four,$five,$six,$one,$three,$nn],'swap9at'],
[['last S1,S2 exchange'], 'swap9 last'],
10, 
[['exchange a',$one,$two,$three,$four,$six,$five,$seven,$eight,$nn,$tn],'sw0a'],
[['exchange b',$one,$two,$three,$four,$seven,$six,$five,$eight,$nn,$tn],'sw0b'],
[['exchange c',$one,$two,$three,$six,$five,$four,$seven,$eight,$nn,$tn],'sw0c'],
[['exchange d',$one,$two,$three,$four,$eight,$six,$seven,$five,$nn,$tn],'sw0d'],
[['exchange e',$one,$two,$three,$seven,$five,$six,$four,$eight,$nn,$tn],'sw0e'],
[['exchange f',$one,$two,$six,$four,$five,$three,$seven,$eight,$nn,$tn],'sw0f'],
[['exchange g',$one,$two,$three,$four,$nn,$six,$seven,$eight,$five,$tn],'sw0g'],
[['exchange h',$one,$two,$three,$eight,$five,$six,$seven,$four,$nn,$tn],'sw0h'],
[['exchange i',$one,$two,$seven,$four,$five,$six,$three,$eight,$nn,$tn],'sw0i'],
[['exchange j',$one,$six,$three,$four,$five,$two,$seven,$eight,$nn,$tn],'sw0j'],
[['exchange k',$one,$two,$three,$nn,$five,$six,$seven,$eight,$four,$tn],'sw0k'],
[['exchange l',$one,$two,$eight,$four,$five,$six,$seven,$three,$nn,$tn],'sw0l'],
[['exchange m',$one,$seven,$three,$four,$five,$six,$two,$eight,$nn,$tn],'sw0m'],
[['exchange n',$one,$two,$nn,$four,$five,$six,$seven,$eight,$three,$tn],'sw0n'],
[['exchange o',$one,$eight,$three,$four,$five,$six,$seven,$two,$nn,$tn],'sw0o'],
[['exchange p',$one,$nn,$three,$four,$five,$six,$seven,$eight,$two,$tn],'sw0p'],
[['exchange q',$one,$two,$three,$six,$seven,$four,$five,$eight,$nn,$tn],'sw0q'],
[['exchange r',$one,$two,$three,$six,$eight,$four,$seven,$five,$nn,$tn],'sw0r'],
[['exchange s',$one,$two,$six,$four,$seven,$three,$five,$eight,$nn,$tn],'sw0s'],
[['exchange t',$one,$two,$three,$six,$nn,$four,$seven,$eight,$five,$tn],'sw0t'],
[['exchange u',$one,$two,$six,$four,$eight,$three,$seven,$five,$nn,$tn],'sw0u'],
[['exchange v',$one,$six,$three,$four,$seven,$two,$five,$eight,$nn,$tn],'sw0v'],
[['exchange w',$one,$two,$three,$seven,$eight,$six,$four,$five,$nn,$tn],'sw0w'],
[['exchange x',$one,$two,$six,$four,$nn,$three,$seven,$eight,$five,$tn],'sw0x'],
[['exchange y',$one,$six,$three,$four,$eight,$two,$seven,$five,$nn,$tn],'sw0y'],
[['exchange z',$one,$two,$six,$seven,$five,$three,$four,$eight,$nn,$tn],'sw0z'],
[['exchange aa',$one,$two,$three,$seven,$nn,$six,$four,$eight,$five,$tn],'saa'],
[['exchange ab',$one,$two,$seven,$four,$eight,$six,$three,$five,$nn,$tn],'sab'],
[['exchange ac',$one,$six,$three,$four,$nn,$two,$seven,$eight,$five,$tn],'sac'],
[['exchange ad',$one,$two,$six,$eight,$five,$three,$seven,$four,$nn,$tn],'sad'],
[['exchange ae',$one,$six,$three,$seven,$five,$two,$four,$eight,$nn,$tn],'sae'],
[['exchange af',$one,$two,$three,$eight,$nn,$six,$seven,$four,$five,$tn],'saf'],
[['exchange ag',$one,$two,$seven,$four,$nn,$six,$three,$eight,$five,$tn],'sag'],
[['exchange ah',$one,$seven,$three,$four,$eight,$six,$two,$five,$nn,$tn],'sah'],
[['exchange ai',$one,$two,$six,$nn,$five,$three,$seven,$eight,$four,$tn],'sai'],
[['exchange aj',$one,$six,$three,$eight,$five,$two,$seven,$four,$nn,$tn],'saj'],
[['exchange ak',$one,$six,$seven,$four,$five,$two,$three,$eight,$nn,$tn],'sak'],
[['exchange al',$one,$two,$eight,$four,$nn,$six,$seven,$three,$five,$tn],'sal'],
[['exchange am',$one,$seven,$three,$four,$nn,$six,$two,$eight,$five,$tn],'sam'],
[['exchange an',$one,$two,$seven,$eight,$five,$six,$three,$four,$nn,$tn],'san'],
[['exchange ao',$one,$six,$three,$nn,$five,$two,$seven,$eight,$four,$tn],'sao'],
[['exchange ap',$one,$six,$eight,$four,$five,$two,$seven,$three,$nn,$tn],'sap'],
[['exchange aq',$one,$eight,$three,$four,$nn,$six,$seven,$two,$five,$tn],'saq'],
[['exchange ar',$one,$two,$seven,$nn,$five,$six,$three,$eight,$four,$tn],'sar'],
[['exchange as',$one,$seven,$three,$eight,$five,$six,$two,$four,$nn,$tn],'sas'],
[['exchange at',$one,$six,$nn,$four,$five,$two,$seven,$eight,$three,$tn],'sat'],
[['exchange au',$one,$two,$eight,$nn,$five,$six,$seven,$three,$four,$tn],'sau'],
[['exchange av',$one,$seven,$three,$nn,$five,$six,$two,$eight,$four,$tn],'sav'],
[['exchange aw',$one,$seven,$eight,$four,$five,$six,$two,$three,$nn,$tn],'saw'],
[['exchange ax',$one,$eight,$three,$nn,$five,$six,$seven,$two,$four,$tn],'sax'],
[['exchange ay',$one,$seven,$nn,$four,$five,$six,$two,$eight,$three,$tn],'say'],
[['exchange az',$one,$eight,$nn,$four,$five,$six,$seven,$two,$three,$tn],'saz'],
[['last S1,S2 exchange'],'swp0 last'],

);

plan tests => 1 + 1+1 + 1+1 + 4+1 + 5+1 + 15+1 + 18+1 + 46+1 + 52+1;

my ($letter, $next);
for my $test (@tests)
{
	if ( $test =~ m/^\d+$/)
	{
		$next = $next{$test};
		$letter = 'a';
		next;
	}
	my $name = $test->[-1];
	my @got = $next->();
	my $expected = $test->[0];
	is_deeply( \@got, $expected, $name );

}
