#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::_unimplemented{CODE}, 
	"_unimplemented is defined" );
	
my $rc = eval { File::Find::Closures::_unimplemented() };
my $at = $@;
ok( ! defined $rc, "eval returns undef for _unimplemented" );
like( $at, qr/Unimplemented/, "Croak message is in $@" );


