#!/usr/bin/perl

use JSPL;

my $rt = JSPL::Runtime->new();
my $cx = $rt->create_context();
$cx->{RaiseExceptions} = 0;
$cx->eval( "foo } bar {" );
warn $@;

