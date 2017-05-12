#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Directory::Deploy;

my ($scratch, $deploy, $manifest);

$scratch = Directory::Scratch->new;
$deploy = Directory::Deploy->new( base => $scratch->base );
$manifest = $deploy->manifest;

$manifest->add( 'apple' => content => \<<_END_ );
Hello, World.
_END_
$manifest->add( 'banana/' );
$deploy->add( '/cherry/grape', \<<_END_ );
Mmm, fruity.
_END_
$deploy->add( 'lime//' );


$deploy->deploy;

ok( -f $scratch->file( 'apple' ) );
ok( -s _ );
is( $scratch->read( 'apple' )."\n", <<_END_ );
Hello, World.
_END_

ok( -d $scratch->dir( 'banana' ) );

ok( -f $scratch->file( 'cherry/grape' ) );
ok( -s _ );
is( $scratch->read( 'cherry/grape' )."\n", <<_END_ );
Mmm, fruity.
_END_

ok( -d $scratch->dir( 'lime' ) );

1;
