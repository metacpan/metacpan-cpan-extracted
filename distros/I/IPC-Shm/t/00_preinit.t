#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;

use IPC::Shm;


our $pkgvar : Shm = undef;

is( $pkgvar, undef,			"\$pkgvar == undef" );

#our @pkgvar : Shm = ();

#is( scalar( @pkgvar ), 0, 		"\@pkgvar == ()" );

#our %pkgvar : Shm = ();

#is( scalar( %pkgvar ), 0, 		"\%pkgvar == ()" );

