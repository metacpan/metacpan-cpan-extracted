#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;

use IPC::Shm;
my ( $obj );

# CLEAN UP SCALARS

our $pkgvar : Shm;

ok( $obj = tied( $pkgvar ), 		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

# CLEAN UP ARRAYS

our @pkgvar : Shm;

ok( $obj = tied( @pkgvar ),		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

# CLEAN UP HASHES

our %pkgvar : Shm;

ok( $obj = tied( %pkgvar ),		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

