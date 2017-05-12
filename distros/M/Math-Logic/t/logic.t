#!/usr/bin/perl -w

# $Id$

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.

# Tests all truth-value logic for 2 and 3-value logic and representative
# samples for multi-value logic; tests most obvious overloading, but there're
# probably a lot more tests that ought to be added -- you write 'em & I'll add
# 'em!

require 5.004 ;

use strict ;

use vars qw( $Loaded $Count $DEBUG $TRIMWIDTH $FIXEDPERL ) ;

BEGIN { 
    $| = 1 ; 
    $FIXEDPERL = $] > 5.005 ? 1 : 0 ; 
    if( $FIXEDPERL ) {
        print "1..332\n" ; 
    }
    else {
        print "1..330\n" ; 
    }
}
END   { print "not ok 1\n" unless $Loaded ; }

use Math::Logic ':NUM' ;
$Loaded = 1 ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 60 ;

report( "loaded module ", 0, '', __LINE__ ) ;

my( $a, $b, $c, $d, $x, $y, $z ) ;

my( $true, $false, $undef ) ;

# new() should not fail -- it `corrects' if need be.
eval {
    $a = Math::Logic->new( -value => 'pickle', -degree => 'x3', -propagate => 'xx' ) ; 
    die "unexpected " . $a->as_string(1) 
    unless $a->as_string(1) eq '(FALSE,3,-propagate)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $a = Math::Logic->new( -value => $UNDEF, -degree => 3, -propagate => 1 ) ; 
    die "unexpected " . $a->as_string(1) 
    unless $a->as_string(1) eq '(UNDEF,3,-propagate)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $a = Math::Logic->new( -value => $TRUE, -degree => 3, -propagate => 0 ) ; 
    die "unexpected " . $a->as_string(1) 
    unless $a->as_string(1) eq '(TRUE,3)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $b = $a->new( -value => $FALSE, -propagate => $TRUE ) ; 
    die "unexpected " . $b->as_string(1) 
    unless $b->as_string(1) eq '(FALSE,3,-propagate)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $c = $a->new( -propagate => $TRUE ) ; 
    die "unexpected " . $c->as_string(1) 
    unless $c->as_string(1) eq '(TRUE,3,-propagate)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $d = Math::Logic->new ;
    die "unexpected " . $d->as_string(1) 
    unless $d->as_string(1) eq '(FALSE,3)' ;
} ;
report( "new", 0, $@, __LINE__ ) ;

eval {
    $x = Math::Logic->new_from_string( '( 57, 100, FALSE )' ) ; 
    die "unexpected " . $x->as_string(1) 
    unless $x->as_string(1) eq '(57%,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;
    
eval {
    $x = Math::Logic->new_from_string( '( 84%, 100, -propagate )' ) ; 
    die "unexpected " . $x->as_string(1) 
    unless $x->as_string(1) eq '(84%,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;
    
eval {
    $y = Math::Logic->new_from_string( '0,100' ) ; 
    die "unexpected " . $y->as_string(1) 
    unless $y->as_string(1) eq '(FALSE,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;
    
eval {
    $z = Math::Logic->new_from_string( '100,100' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(TRUE,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;

eval {
    $z = Math::Logic->new_from_string( 'TRUE,100' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(1%,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;

eval {
    $z = Math::Logic->new_from_string( '48,100' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(48%,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;

eval {
    $z = Math::Logic->new_from_string( 'F,100' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(FALSE,100)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;

eval {
    $z = Math::Logic->new_from_string( 'U,3' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(UNDEF,3)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;

eval {
    # UNDEF is silently converted to FALSE except for 3-value logic.
    $z = Math::Logic->new_from_string( 'U,30' ) ; 
    die "unexpected " . $z->as_string(1) 
    unless $z->as_string(1) eq '(FALSE,30)' ;
} ;
report( "new_from_string", 0, $@, __LINE__ ) ;


# 2-value logic tests

# and

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 2 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 2 ) ;
    $x = $true->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $true ) ;
    die "and failed " . $x
    unless $x == $TRUE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $true ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

# or

eval {
    $x = $true->or( $false ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $true->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $false->or( $false ) ;
    die "or failed " . $x
    unless $x == $FALSE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

# xor

eval {
    $x = $true->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $true->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $false->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

# not

eval {
    $x = $true->not ;
    die "not failed " . $x
    unless $x == $FALSE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $false->not ;
    die "not failed " . $x
    unless $x == $TRUE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

# 3-value non-propagating logic tests

# and

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 3 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 3 ) ;
    $undef = Math::Logic->new( -value => $UNDEF, -degree => 3 ) ;
    $x = $true->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $true ) ;
    die "and failed " . $x
    unless $x == $TRUE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $true ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $undef ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $undef ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $true ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $undef ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

# or

eval {
    $x = $true->or( $false ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $true->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $false->or( $false ) ;
    die "or failed " . $x
    unless $x == $FALSE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $undef ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $false ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $true->or( $undef ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $undef ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;


# xor

eval {
    $x = $true->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $true->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $false->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $true->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


# not

eval {
    $x = $true->not ;
    die "not failed " . $x
    unless $x == $FALSE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $false->not ;
    die "not failed " . $x
    unless $x == $TRUE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->not ;
    die "not failed " . $x
    unless $x == $UNDEF ;
} ;
report( "not", 0, $@, __LINE__ ) ;


# 3-value propagating logic tests

# and

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 3, -propagate => 1 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 3, -propagate => 1 ) ;
    $undef = Math::Logic->new( -value => $UNDEF, -degree => 3, -propagate => 1 ) ;
    $x = $true->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $true ) ;
    die "and failed " . $x
    unless $x == $TRUE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $true ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $undef ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $false ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $undef ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $true ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->and( $undef ) ;
    die "and failed " . $x
    unless $x == $UNDEF ;
} ;
report( "and", 0, $@, __LINE__ ) ;

# or

eval {
    $x = $true->or( $false ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $true->or( $true ) ;
    die "or failed " . $x
    unless $x == $TRUE ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $false->or( $false ) ;
    die "or failed " . $x
    unless $x == $FALSE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $undef ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $false ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $true->or( $undef ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $true ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->or( $undef ) ;
    die "or failed " . $x
    unless $x == $UNDEF ;
} ;
report( "or", 0, $@, __LINE__ ) ;


# xor

eval {
    $x = $true->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $TRUE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $true->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $false->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $true->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->xor( $undef ) ;
    die "xor failed " . $x
    unless $x == $UNDEF ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


# not

eval {
    $x = $true->not ;
    die "not failed " . $x
    unless $x == $FALSE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $false->not ;
    die "not failed " . $x
    unless $x == $TRUE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $undef->not ;
    die "not failed " . $x
    unless $x == $UNDEF ;
} ;
report( "not", 0, $@, __LINE__ ) ;


# multi-value logic tests

my( $fairly, $very ) ;
my $True  = 100 ;

# and

eval {
    $true   = Math::Logic->new( -value => $True,  -degree => $True ) ;
    $very   = Math::Logic->new( -value => 67,     -degree => $True ) ;
    $fairly = Math::Logic->new( -value => 33,     -degree => $True ) ;
    $false  = Math::Logic->new( -value => $FALSE, -degree => $True ) ;
    $x = $true->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $true->and( $true ) ;
    die "and failed " . $x
    unless $x == $True ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $true ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $false->and( $false ) ;
    die "and failed " . $x
    unless $x == $FALSE ;
} ;
report( "and", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly->and( $very ) ;
    die "and failed " . $x
    unless $x == $fairly ;
} ;
report( "and", 0, $@, __LINE__ ) ;


# or

eval {
    $x = $true->or( $false ) ;
    die "or failed " . $x
    unless $x == $True ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $false->or( $true ) ;
    die "or failed " . $x
    unless $x == $True ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $true->or( $true ) ;
    die "or failed " . $x
    unless $x == $True ;
} ;
report( "or", 0, $@, __LINE__ ) ;


eval {
    $x = $false->or( $false ) ;
    die "or failed " . $x
    unless $x == $FALSE ;
} ;
report( "or", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly->or( $very ) ;
    die "or failed " . $x
    unless $x == $very ;
} ;
report( "or", 0, $@, __LINE__ ) ;


# xor

eval {
    $x = $true->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $True ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $false->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $True ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $true->xor( $true ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


eval {
    $x = $false->xor( $false ) ;
    die "xor failed " . $x
    unless $x == $FALSE ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly->xor( $very ) ;
    die "xor failed " . $x
    unless $x == $very ;
} ;
report( "xor", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly->xor( $fairly ) ;
    die "xor failed " . $x
    unless $x == $fairly ;
} ;
report( "xor", 0, $@, __LINE__ ) ;


# not

eval {
    $x = $true->not ;
    die "not failed " . $x
    unless $x == $FALSE ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $false->not ;
    die "not failed " . $x
    unless $x == $x->degree ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly->not ;
    die "not failed " . $x
    unless $x == $x->degree - $fairly->value ;
} ;
report( "not", 0, $@, __LINE__ ) ;

eval {
    $x = $very->not ;
    die "not failed " . $x
    unless $x == $x->degree - $very->value ;
} ;
report( "not", 0, $@, __LINE__ ) ;

# overloading
my $trueM   = Math::Logic->new( -value => $True,  -degree => $True ) ;
my $veryM   = Math::Logic->new( -value => 67,     -degree => $True ) ;
my $fairlyM = Math::Logic->new( -value => 33,     -degree => $True ) ;
my $falseM  = Math::Logic->new( -value => $FALSE, -degree => $True ) ;
my $true2   = Math::Logic->new( -value => $TRUE,   -degree => 2 ) ;
my $false2  = Math::Logic->new( -value => $FALSE,  -degree => 2 ) ;
my $true3   = Math::Logic->new( -value => $TRUE,   -degree => 3 ) ;
my $false3  = Math::Logic->new( -value => $FALSE,  -degree => 3 ) ;
my $undef3  = Math::Logic->new( -value => $UNDEF,  -degree => 3 ) ;

# string

eval {
    die q{"" failed } . $trueM . " $trueM"
    unless $trueM->as_string eq "$trueM" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $veryM . " $veryM"
    unless $veryM->as_string eq "$veryM" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $fairlyM . " $fairlyM"
    unless $fairlyM->as_string eq "$fairlyM" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $falseM . " $falseM"
    unless $falseM->as_string eq "$falseM" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $true2 . " $true2"
    unless $true2->as_string eq "$true2" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $false2 . " $false2"
    unless $false2->as_string eq "$false2" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $true3 . " $true3"
    unless $true3->as_string eq "$true3" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $false3 . " $false3"
    unless $false3->as_string eq "$false3" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

eval {
    die q{"" failed } . $undef3 . " $undef3"
    unless $undef3->as_string eq "$undef3" ;
} ;
report( q{""}, 0, $@, __LINE__ ) ;

# number

eval {
    die q{0+ failed } . $trueM . " $trueM"
    unless $trueM == $trueM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $veryM . " $veryM"
    unless $veryM == $veryM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $fairlyM . " $fairlyM"
    unless $fairlyM == $fairlyM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $falseM . " $falseM"
    unless $falseM == $falseM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $true2 . " $true2"
    unless $true2 == $true2 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $false2 . " $false2"
    unless $false2 == $false2 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $true3 . " $true3"
    unless $true3 == $true3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $false3 . " $false3"
    unless $false3 == $false3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $undef3 . " $undef3"
    unless $undef3 == $undef3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $undef3 . " $false3"
    unless $undef3 != $false3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

# number

eval {
    die q{0+ failed } . $trueM . " $trueM"
    unless 100 == $trueM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $veryM . " $veryM"
    unless $veryM == 67 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $fairlyM . " $fairlyM"
    unless 33 == $fairlyM ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $falseM . " $falseM"
    unless $falseM == 0 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $true2 . " $true2"
    unless 1 == $true2 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $false2 . " $false2"
    unless $false2 == 0 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $true3 . " $true3"
    unless 1 == $true3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $false3 . " $false3"
    unless $false3 == 0 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $undef3 . " $undef3"
    unless -1 == $undef3 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;

eval {
    die q{0+ failed } . $undef3 . " $false3"
    unless $undef3 != 0 ;
} ;
report( q{0+}, 0, $@, __LINE__ ) ;


# bool

eval {
    die q{bool failed } . $trueM . " $trueM"
    unless $trueM ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $veryM . " $veryM"
    unless $veryM ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $fairlyM . " $fairlyM"
    unless $fairlyM ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $falseM . " $falseM"
    unless not $falseM ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $true2 . " $true2"
    unless $true2 ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $false2 . " $false2"
    unless not $false2 ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $true3 . " $true3"
    unless $true3 ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $false3 . " $false3"
    unless not $false3 ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $undef3 . " $undef3"
    unless $undef3 == $UNDEF ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

eval {
    die q{bool failed } . $false3 . " $false3"
    unless not $false3 ;
} ;
report( q{bool}, 0, $@, __LINE__ ) ;

# ==

eval {
    die q{== failed } . $trueM . " $trueM"
    unless $trueM == $trueM ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;

eval {
    die q{== failed } . " $veryM"
    unless $veryM == $veryM ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $fairlyM"
    unless $fairlyM == $fairlyM ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $falseM"
    unless $falseM == $falseM ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $true2"
    unless $true2 == $true2 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $false2"
    unless $false2 == $false2 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $true3"
    unless $true3 == $true3 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $false3"
    unless $false3 == $false3 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $undef3"
    unless $undef3 == $undef3 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;

eval {
    die q{== failed } . " $trueM"
    unless $trueM == $True ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;

eval {
    die q{== failed } . " $veryM"
    unless $veryM == 67 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $fairlyM"
    unless $fairlyM == 33 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $falseM"
    unless $falseM == $FALSE ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $true2"
    unless $true2 == $TRUE ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $false2"
    unless $false2 == $FALSE ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $true3"
    unless $true3 == $TRUE ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $false3"
    unless $false3 == $false3 ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


eval {
    die q{== failed } . " $undef3"
    unless $undef3 == $UNDEF ;
} ;
report( q{==}, 0, $@, __LINE__ ) ;


# !=

eval {
    die q{!= failed } . " $trueM"
    if $trueM != $trueM ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;

eval {
    die q{!= failed } . " $veryM"
    if $veryM != $veryM ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $fairlyM"
    if $fairlyM != $fairlyM ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $falseM"
    if $falseM != $falseM ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $true2"
    if $true2 != $true2 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $false2"
    if $false2 != $false2 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $true3"
    if $true3 != $true3 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $false3"
    if $false3 != $false3 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $undef3"
    if $undef3 != $undef3 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;

eval {
    die q{!= failed } . " $trueM"
    if $trueM != $True ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;

eval {
    die q{!= failed } . " $veryM"
    if $veryM != 67 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $fairlyM"
    if $fairlyM != 33 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $falseM"
    if $falseM != $FALSE ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $true2"
    if $true2 != $TRUE ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $false2"
    if $false2 != $FALSE ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $true3"
    if $true3 != $TRUE ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $false3"
    if $false3 != $false3 ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;


eval {
    die q{!= failed } . " $undef3"
    if $undef3 != $UNDEF ;
} ;
report( q{!=}, 0, $@, __LINE__ ) ;

# assignment

eval {
    my $q = $true3 ;
    die q{= failed } 
    unless $q == $TRUE and $q->degree == $true3->degree ;
} ;
report( q{=}, 0, $@, __LINE__ ) ;


# 2-value logic tests

# &

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 2 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 2 ) ;
    $x = $true & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $true ;
    die "& failed " . $x
    unless $x == $TRUE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $true ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

# |

eval {
    $x = $true | $false ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $true | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $false | $false ;
    die "| failed " . $x
    unless $x == $FALSE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

# ^

eval {
    $x = $true ^ $false ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $true ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $true ^ $true ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $false ^ $false ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

# !

eval {
    $x = ! $true ;
    die "! failed " . $x
    unless $x == $FALSE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $false ;
    die "! failed " . $x
    unless $x == $TRUE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

# 3-value non-propagating logic tests

# &

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 3 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 3 ) ;
    $undef = Math::Logic->new( -value => $UNDEF, -degree => 3 ) ;
    $x = $true & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $true ;
    die "& failed " . $x
    unless $x == $TRUE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $true ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $undef ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $undef ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $true ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $undef ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

# |

eval {
    $x = $true | $false ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $true | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $false | $false ;
    die "| failed " . $x
    unless $x == $FALSE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $undef ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $false ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $true | $undef ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $undef ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;


# ^

eval {
    $x = $true ^ $false ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $true ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $true ^ $true ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $false ^ $false ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $false ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $true ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $true ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;


# !

eval {
    $x = ! $true ;
    die "! failed " . $x
    unless $x == $FALSE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $false ;
    die "! failed " . $x
    unless $x == $TRUE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $undef ;
    die "! failed " . $x
    unless $x == $UNDEF ;
} ;
report( "!", 0, $@, __LINE__ ) ;


# 3-value propagating logic tests

# &

eval {
    $true  = Math::Logic->new( -value => $TRUE,  -degree => 3, -propagate => 1 ) ;
    $false = Math::Logic->new( -value => $FALSE, -degree => 3, -propagate => 1 ) ;
    $undef = Math::Logic->new( -value => $UNDEF, -degree => 3, -propagate => 1 ) ;
    $x = $true & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $true ;
    die "& failed " . $x
    unless $x == $TRUE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $true ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $undef ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $false ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $undef ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $true ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $undef & $undef ;
    die "& failed " . $x
    unless $x == $UNDEF ;
} ;
report( "&", 0, $@, __LINE__ ) ;

# |

eval {
    $x = $true | $false ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $true | $true ;
    die "| failed " . $x
    unless $x == $TRUE ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $false | $false ;
    die "| failed " . $x
    unless $x == $FALSE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $undef ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $false ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $true | $undef ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $true ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $undef | $undef ;
    die "| failed " . $x
    unless $x == $UNDEF ;
} ;
report( "|", 0, $@, __LINE__ ) ;


# ^

eval {
    $x = $true ^ $false ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $true ;
    die "^ failed " . $x
    unless $x == $TRUE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $true ^ $true ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $false ^ $false ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $false ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $true ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $true ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $undef ^ $undef ;
    die "^ failed " . $x
    unless $x == $UNDEF ;
} ;
report( "^", 0, $@, __LINE__ ) ;


# !

eval {
    $x = ! $true ;
    die "! failed " . $x
    unless $x == $FALSE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $false ;
    die "! failed " . $x
    unless $x == $TRUE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $undef ;
    die "! failed " . $x
    unless $x == $UNDEF ;
} ;
report( "!", 0, $@, __LINE__ ) ;


# multi-value logic tests

# &

eval {
    $true   = Math::Logic->new( -value => $True,  -degree => $True ) ;
    $very   = Math::Logic->new( -value => 67,     -degree => $True ) ;
    $fairly = Math::Logic->new( -value => 33,     -degree => $True ) ;
    $false  = Math::Logic->new( -value => $FALSE, -degree => $True ) ;
    $x = $true & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $true & $true ;
    die "& failed " . $x
    unless $x == $True ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $true ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $false & $false ;
    die "& failed " . $x
    unless $x == $FALSE ;
} ;
report( "&", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly & $very ;
    die "& failed " . $x
    unless $x == $fairly ;
} ;
report( "&", 0, $@, __LINE__ ) ;


# |

eval {
    $x = $true | $false ;
    die "| failed " . $x
    unless $x == $True ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $false | $true ;
    die "| failed " . $x
    unless $x == $True ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $true | $true ;
    die "| failed " . $x
    unless $x == $True ;
} ;
report( "|", 0, $@, __LINE__ ) ;


eval {
    $x = $false | $false ;
    die "| failed " . $x
    unless $x == $FALSE ;
} ;
report( "|", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly | $very ;
    die "| failed " . $x
    unless $x == $very ;
} ;
report( "|", 0, $@, __LINE__ ) ;


# ^

eval {
    $x = $true ^ $false ;
    die "$false ^ $true failed " . $x
    unless $x == $True ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $false ^ $true ;
    die "$false ^ $true failed " . $x
    unless $x == $True ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $true ^ $true ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;


eval {
    $x = $false ^ $false ;
    die "^ failed " . $x
    unless $x == $FALSE ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly ^ $very ;
    die "^ failed " . $x
    unless $x == $very ;
} ;
report( "^", 0, $@, __LINE__ ) ;

eval {
    $x = $fairly ^ $fairly ;
    die "^ failed " . $x
    unless $x == $fairly ;
} ;
report( "^", 0, $@, __LINE__ ) ;


# !

eval {
    $x = ! $true ;
    die "! failed " . $x
    unless $x == $FALSE ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $false ;
    die "! failed " . $x
    unless $x == $x->degree ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $fairly ;
    die "! failed " . $x
    unless $x == $x->degree - $fairly->value ;
} ;
report( "!", 0, $@, __LINE__ ) ;

eval {
    $x = ! $very ;
    die "! failed " . $x
    unless $x == $x->degree - $very->value ;
} ;
report( "!", 0, $@, __LINE__ ) ;

# compatible

eval {
    $x = Math::Logic->new_from_string('1,2') ;
    $y = Math::Logic->new_from_string('0,3') ;
    $z = $x->and( $y ) ;
} ;
report( "incompatible", 1, $@, __LINE__ ) ;

eval {
    die $x->incompatible( $y ) if $x->incompatible( $y ) ;
} ;
report( "incompatible", 1, $@, __LINE__ ) ;

if( $FIXEDPERL ) {
    eval {
        $x = Math::Logic->new_from_string('1,2') ;
        $y = Math::Logic->new_from_string('0,3') ;
        $z = $x & $y ; # Causes a segmentation fault under 5.004
    } ;
    report( "compatible", 1, $@ ) ;
}

# methods

eval {
    die $x unless $x == 1 ;
} ;
report( "value", 0, $@, __LINE__ ) ;

eval {
    $y->value(-1) ;
    die $y unless $y == -1 ;
} ;
report( "value", 0, $@, __LINE__ ) ;

eval {
    die $x unless $x->degree == 2 ;
} ;
report( "degree", 0, $@, __LINE__ ) ;

eval {
    die $y unless $y->degree == 3 ;
} ;
report( "degree", 0, $@, __LINE__ ) ;

eval {
    die $x unless $x->propagate == 0 ;
} ;
report( "propagate", 0, $@, __LINE__ ) ;

eval {
    die $y unless $y->propagate == 0 ;
} ;
report( "propagate", 0, $@, __LINE__ ) ;

eval {
    $y = $y->new( -propagate => 1 ) ;
    die $y unless $y->propagate == 1 ;
} ;
report( "propagate", 0, $@, __LINE__ ) ;

eval {
    $y = 'Fred' ;
    $y = 'Wilma' unless $x->incompatible( $y ) ;
} ;
report( "incompatible", 1, $@, __LINE__ ) ;

# error messages

eval {
    $x->incompatible( 5 ) ;
} ;
report( "incompatible", 1, $@, __LINE__ ) ;




$x = Math::Logic->new_from_string('1,2') ;
$y = Math::Logic->new_from_string('0,3') ;
$z = $x->and( 0 ) ;

eval {
    Math::Logic->_set ;
} ;
report( "_set", 1, $@, __LINE__ ) ;

eval {
    Math::Logic->_get ;
} ;
report( "_get", 1, $@, __LINE__ ) ;


eval {
    Math::Logic->_cmp ;
} ;
report( "_cmp", 1, $@, __LINE__ ) ;


eval {
    $x->_cmp( $y ) ;
} ;
report( "_cmp", 1, $@, __LINE__ ) ;


eval {
    $x = $y + 1 ;
} ;
report( "+", 1, $@, __LINE__ ) ;

eval {
    $x = $y - 1 ;
} ;
report( "-", 1, $@, __LINE__ ) ;

eval {
    $x = $y * 1 ;
} ;
report( "*", 1, $@, __LINE__ ) ;


eval {
    $x = $y / 1 ;
} ;
report( "/", 1, $@, __LINE__ ) ;


eval {
    $x = $y % 1 ;
} ;
report( "%%", 1, $@, __LINE__ ) ;


eval {
    $x = $y x 1 ;
} ;
report( "x", 1, $@, __LINE__ ) ;


eval {
    $x = $y ** 1 ;
} ;
report( "**", 1, $@, __LINE__ ) ;


eval {
    $x = $y << 1 ;
} ;
report( "<<", 1, $@, __LINE__ ) ;


eval {
    $x = $y >> 1 ;
} ;
report( ">>", 1, $@, __LINE__ ) ;


eval {
    $x = $y += 1 ;
} ;
report( "+=", 1, $@, __LINE__ ) ;


eval {
    $x = $y -= 1 ;
} ;
report( "-=", 1, $@, __LINE__ ) ;


eval {
    $x = $y *= 1 ;
} ;
report( "*=", 1, $@, __LINE__ ) ;


eval {
    $x = $y /= 1 ;
} ;
report( "/=", 1, $@, __LINE__ ) ;


eval {
    $x = $y %= 1 ;
} ;
report( "%%=", 1, $@, __LINE__ ) ;


eval {
    $x = $y x= 1 ;
} ;
report( "x=", 1, $@, __LINE__ ) ;

eval {
    $x = $y++ ;
} ;
report( "postfix++", 1, $@, __LINE__ ) ;

eval {
    $x = ++$y ;
} ;
report( "++prefix", 1, $@, __LINE__ ) ;

eval {
    $x = --$y ;
} ;
report( "--prefix", 1, $@, __LINE__ ) ;


if( $FIXEDPERL ) {
    eval {
        $x = $y-- ;
    } ;
    report( "postfix--", 1, $@ ) ;
    # Causes a segmentation fault under 5.004
}


eval {
    $x = $y lt 1 ;
} ;
report( "lt", 1, $@, __LINE__ ) ;


eval {
    $x = $y gt 1 ;
} ;
report( "gt", 1, $@, __LINE__ ) ;


eval {
    $x = $y ge 1 ;
} ;
report( "ge", 1, $@, __LINE__ ) ;


eval {
    $x = $y le 1 ;
} ;
report( "le", 1, $@, __LINE__ ) ;


eval {
    $x = $y eq 1 ;
} ;
report( "eq", 1, $@, __LINE__ ) ;


eval {
    $x = $y ne 1 ;
} ;
report( "ne", 1, $@, __LINE__ ) ;


eval {
    $x = $y **= 1 ;
} ;
report( "**=", 1, $@, __LINE__ ) ;


eval {
    $x = $y <<= 1 ;
} ;
report( "<<=", 1, $@, __LINE__ ) ;

eval {
    $x = $y >>= 1 ;
} ;
report( ">>=", 1, $@, __LINE__ ) ;


eval {
    $x = $y cmp 1 ;
} ;
report( "cmp", 1, $@, __LINE__ ) ;


eval {
    $x = -$y ;
} ;
report( "negate-", 1, $@, __LINE__ ) ;


eval {
    $x->and( $y ) ;
} ;
report( "and", 1, $@, __LINE__ ) ;

eval {
    Math::Logic->or( $y ) ;
} ;
report( "or", 1, $@, __LINE__ ) ;

eval {
    $x->or( $y ) ;
} ;
report( "or", 1, $@, __LINE__ ) ;

eval {
    Math::Logic->xor( $y ) ;
} ;
report( "xor", 1, $@, __LINE__ ) ;

eval {
    $x->xor( $y ) ;
} ;
report( "xor", 1, $@, __LINE__ ) ;

eval {
    Math::Logic->not ;
} ;
report( "not", 1, $@, __LINE__ ) ;




sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}


