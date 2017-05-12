#!/usr/bin/perl

# Tests for bug #7510
package MyStem;
use base qw( Lingua::Stem::Snowball );

package main;
use strict;
use Test::More tests => 3;

my $s = MyStem->new( lang => 'fr' );
ok( 'MyStem', ref($s) );

my $lemm = $s->stem('été');
is( $lemm, 'été', "stem works" );

$lemm = $s->stem('aimant');
is( $lemm, 'aim', "stem works" );
