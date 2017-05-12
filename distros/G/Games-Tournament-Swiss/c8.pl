#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw/min max/;

# my @players = @{shift()};
my @exchanges = map {
        my $i = $_;
        map { [ $_, $_-$i ] } 5..8-$i } 1..3;
        print @exchanges;


@exchanges = (1,2,3,map{ $_ } 4..5,6);
@exchanges = (1,2,3,(map {my $x =$_; map{  $x.$_ } 0..1} 4..5),6);
@exchanges = ([4,5],[4,6],[3,5],[4,7],[3,6],[2,5],[3,7],[2,6],[2,7]);
@exchanges = map {my $x =$_; map{  $x.','.$_ } 0..1} 1..3;
@exchanges = map {my $x =$_; map{  $x.','.$_ } 0..$x-1} 1..3;
@exchanges = map {my $x =$_; map{  [5-$_-$x,5-$_] } -1..$x-2} 1..3;
@exchanges = map {my $x =$_; map{  [7-$_-$x,7-$_] } 1..$x} 1..3;
@exchanges = map {my $x =$_; map{  [5-$_-$x,5-$_] } 0..$x-1} 1..3;
@exchanges = map {my $x =$_; map{  [5-$_-2*$x,5-$_+$x] } 1..$x} 1..3;
@exchanges = ( (map {[$_,$_+1]} reverse 4..4), (map {[$_,$_+2]} reverse 3..4), (map {[$_,$_+3]} reverse 2..4), (map {[$_,$_+4]} reverse 2..3), (map {[$_,$_+5]} reverse 2..2) );
@exchanges = ( (map {[$_,$_+1]} reverse 5..5), (map {[$_,$_+2]} reverse 4..5), (map {[$_,$_+3]} reverse 3..5), (map {[$_,$_+4]} reverse 2..5), (map {[$_,$_+5]} reverse 2..4), (map {[$_,$_+6]} reverse 2..3), (map {[$_,$_+7]} reverse 2..2) );
@exchanges = ();
for my $i ( 1 .. 4 )
{
	push @exchanges, map {[$_,$_+$i]} reverse 6-$i..5;
}
for my $i ( 5 .. 7 )
{
	push @exchanges, map {[$_,$_+$i]} reverse 2..9-$i;
};
@exchanges = ();
for my $i ( 1 .. 7 )
{
	push @exchanges, map {[$_,$_+$i]} reverse (max 2,6-$i)..(min 5,9-$i);
}
@exchanges = ();
my $p = 5;
for my $i ( 1 .. 2*$p-3 )
{
	push @exchanges, map {[$_,$_+$i]} reverse (max 2,$p+1-$i)..(min $p,2*$p-1-$i);
}
@exchanges = ();
$p = 4;
for my $i ( 1 .. 2*($p-1)-1 )
{
	push @exchanges, map {[$_,$_+$i]} reverse (max 1,$p-$i)..(min $p-1,2*($p-1)-$i);
}
# my @exchange = @{ $exchanges[0] };
my @people = map { @{ $_ } } @exchanges;
my @s1 = 'A' .. 'D';
my @s2 = 'W' .. 'Z';
my @members = (@s1, @s2);
#( $s1[ $exchanges[$n][0] ], $s2[ $exchanges[$n][1] ] ) =
#    ( $s2[ $exchanges[$n][1] ], $s1[ $exchanges[$n][0] ] );
my $n = 3;
my ( $temp1, $temp2 ) =
    ( $members[ $exchanges[$n][1] ], $members[ $exchanges[$n][0] ] );
( $members[ $exchanges[$n][0] ], $members[ $exchanges[$n][1] ] ) =
    ( $temp1, $temp2 );
for my $i ( 1 .. 2*($p-1)-1 )
{
        push @exchanges, map {[[$_,$_+$i]]} reverse (max 1,$p-$i)..(min $p-1,2*($p-1)-$i);
}
@exchanges = ();
for my $i ( 1 .. 2*($p-1)-1 )
{
        push @exchanges, map { my $j = $_; map {[$j,$j+$_]} reverse 1..$p-$j } reverse $p..2*($p-1)-$i;
}
my @s1pair = map { my $i = $_; map { [ $i, $i+$_ ] } reverse 1..$p-$i } 1 .. $p-1;
@s1pair = map { my $i = $_; map { [ $i, $i+$_ ] } reverse 1..$p-$i } reverse 2 .. $p-1;
my @s2pair = map { my $i = $_; map { [ $i, $i+$_ ] } reverse 1..2*$p-$i } reverse $p .. 2*$p-2;
@s2pair = map { my $i = $_; map { [ $i, $i+$_ ] } 1..2*$p-$i } reverse $p+1 .. 2*$p-1;
@s2pair = map { my $i = $_; map { [ $i, $i+$_ ] } 1..2*($p-1)-$i } $p .. 2*($p-1)-1;
@s1pair = map { my $i = $_; map { [ $i-$_, $i ] } 1..$i-1 } reverse 2 .. $p-1;
@exchanges = ();
for my $i ( 1 .. 2*($p-1)-1 )
{
        push @exchanges, map {[[$_,$_+$i]]} (max 1,$p-$i)..(min $p-1,2*($p-1)-$i);
}
@exchanges = map { my $i=$_; map { [ $_, $i ] } reverse 1..$i } 1..3;
@exchanges = map { my $i=$_; map { [ $_, $i ] } reverse ((max 1,3-$i)..(min 2, $i)) } 1..3;
@exchanges = map { my $i = $_; map {[[$_,$_+$i]]} reverse ( (max 1,$p-$i)..(min $p-1,2*($p-1)-$i) )} ( 1 .. 2*($p-1)-1 );
$p = 4;
@s1pair = map { my $i = $_; map { [ $i-$_, $i ] } 1..$i-1 } reverse 2 .. $p-1;
@s2pair = map { my $i = $_; map { [ $i, $i+$_ ] } 1..2*($p-1)-$i } $p .. 2*($p-1)-1;
my @exchanges2 = map { my $i = $_; map { [[$s1pair[$_][0],$s2pair[$i-$_][0]],[$s1pair[$_][1],$s2pair[$i-$_][1]]] } (max 0,$i-($p-1)*($p-2)/2+1)..(min (($p-1)*($p-2)/2-1,$i)) } 0 .. ($p-1)*($p-2)-2;
print @exchanges;
