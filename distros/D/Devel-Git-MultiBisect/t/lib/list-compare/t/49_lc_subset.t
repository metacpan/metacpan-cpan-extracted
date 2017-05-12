# perl
#$Id$
# 50_lcf_subset.t
use strict;
use Test::More tests => 52;
use List::Compare;

my @a0 = ( qw| alpha | );
my @a1 = ( qw| alpha beta | );
my @a2 = ( qw| alpha beta gamma | );
my @a3 = ( qw|            gamma | );

my ($lc, $LR, $RL);

$lc = List::Compare->new( [], [] );
$LR = $lc->is_LsubsetR();
ok($LR, "simple: empty array is subset of itself");

$lc = List::Compare->new( [], [] );
$RL = $lc->is_RsubsetL();
ok($RL, "simple: empty array is subset of itself");

$lc = List::Compare->new( \@a0, \@a0 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple: array is subset of itself");

$lc = List::Compare->new( \@a0, \@a0 );
$RL = $lc->is_RsubsetL();
ok($RL, "simple: array is subset of itself");

$lc = List::Compare->new( \@a0, \@a3 );
$LR = $lc->is_LsubsetR();
ok(! $LR, "simple: disjoint are not subsets");

$lc = List::Compare->new( \@a0, \@a3 );
$RL = $lc->is_RsubsetL();
ok(! $RL, "simple: disjoint are not subsets");

$lc = List::Compare->new( \@a0, \@a1 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "simple: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "simple: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "simple: right is not subset of left");


$lc = List::Compare->new( '-u', \@a0, \@a1 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple unsorted: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "simple unsorted: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "simple unsorted: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "simple unsorted: right is not subset of left");


$lc = List::Compare->new( '--unsorted', \@a0, \@a1 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple unsorted long: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "simple unsorted long: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "simple unsorted long: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "simple unsorted long: right is not subset of left");


$lc = List::Compare->new( { lists => [ [], [] ] } );
$LR = $lc->is_LsubsetR();
ok($LR, "lists: empty array is subset of itself");

$lc = List::Compare->new( { lists => [ [], [] ] } );
$RL = $lc->is_RsubsetL();
ok($LR, "lists: empty array is subset of itself");

$lc = List::Compare->new( { lists => [ \@a0, \@a0 ] } );
$LR = $lc->is_LsubsetR();
ok($LR, "lists: array is subset of itself");

$lc = List::Compare->new( { lists => [ \@a0, \@a0 ] } );
$RL = $lc->is_RsubsetL();
ok($RL, "lists: array is subset of itself");

$lc = List::Compare->new( { lists => [ \@a0, \@a3 ] } );
$LR = $lc->is_LsubsetR();
ok(! $LR, "lists: disjoint are not subsets");

$lc = List::Compare->new( { lists => [ \@a0, \@a3 ] } );
$RL = $lc->is_RsubsetL();
ok(! $RL, "lists: disjoint are not subsets");

$lc = List::Compare->new( { lists => [ \@a0, \@a1 ] } );
$LR = $lc->is_LsubsetR();
ok($LR, "lists: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "lists: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "lists: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "lists: right is not subset of left");


$lc = List::Compare->new( { lists => [ \@a0, \@a1 ], unsorted => 1 } );
$LR = $lc->is_LsubsetR();
ok($LR, "lists: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "lists: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "lists: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "lists: right is not subset of left");


$lc = List::Compare->new( '-a', \@a0, \@a1 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple accelerated: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "simple accelerated: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "simple accelerated: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "simple accelerated: right is not subset of left");


$lc = List::Compare->new( '--accelerated', \@a0, \@a1 );
$LR = $lc->is_LsubsetR();
ok($LR, "simple accelerated long: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "simple accelerated long: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "simple accelerated long: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "simple accelerated long: right is not subset of left");


$lc = List::Compare->new( { lists => [ \@a0, \@a1 ], accelerated => 1 } );
$LR = $lc->is_LsubsetR();
ok($LR, "lists: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "lists: left is subset of right");

$RL = $lc->is_RsubsetL();
ok(! $RL, "lists: right is not subset of left");

$RL = $lc->is_BsubsetA();
ok(! $RL, "lists: right is not subset of left");


$lc = List::Compare->new( \@a0, \@a1, \@a2 );
$LR = $lc->is_LsubsetR();
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_LsubsetR(0,1);
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_LsubsetR(1,2);
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_LsubsetR(0,2);
ok($LR, "multiple: left is subset of right");

$LR = $lc->is_AsubsetB();
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_AsubsetB(0,1);
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_AsubsetB(1,2);
ok($LR, "multiple: left is subset of right");
$LR = $lc->is_AsubsetB(0,2);
ok($LR, "multiple: left is subset of right");

