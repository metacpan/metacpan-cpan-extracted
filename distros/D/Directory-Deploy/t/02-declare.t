#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Directory::Deploy;

package t::Deploy;

use Directory::Deploy::Declare;

add 'apple', \<<_END_;
Hello, World.
_END_

add 'banana/';

add '/cherry/grape', \<<_END_;
Mmm, fruity.
_END_

add 'lime//';

include <<_END_;
a/
a/b
c/d/e/
_END_

include 
    'f' => { mode => 0666 },
    'g:666' => {},
    'h/i:600' => \<<_END_;
This is h/i
_END_
;
    
    

no Directory::Deploy::Declare;

1;

package main;

my ($scratch, $deploy, $manifest);

sub test {

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

    ok( -d $scratch->dir( 'a' ) );
    ok( -f $scratch->file( 'a/b' ) );
    ok( -d $scratch->dir( 'c/d/e' ) );
    ok( -f $scratch->file( 'f' ) );
    is( (stat _)[2] & 07777, 0666 );
    ok( -f $scratch->file( 'g' ) );
    is( (stat _)[2] & 07777, 0666 );
    ok( -f $scratch->file( 'h/i' ) );
    is( (stat _)[2] & 07777, 0600 );
    is( $scratch->read( 'h/i' )."\n", <<_END_ );
This is h/i
_END_
}

{
    $scratch = Directory::Scratch->new;
    $deploy = t::Deploy->new( base => $scratch->base );

    $deploy->deploy;

    ok( $deploy->manifest->entry( 'apple' ) );

    test;
}

{
    $scratch = Directory::Scratch->new;
    t::Deploy->deploy( { base => $scratch->base } );

    test;
}

1;
