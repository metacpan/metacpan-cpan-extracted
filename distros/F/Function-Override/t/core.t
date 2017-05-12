#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use Function::Override;

BEGIN {
    override('open', 
         sub { 
             my $wantarray = (caller(1))[5];
             die "Void context\n" unless defined $wantarray 
         }
    );
}
eval { open(FILE, 'bogus'); };
is( $@, "Void context\n" );