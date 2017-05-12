#!/usr/bin/perl -w
use strict;
use Test::More tests => 5;

use DhMakePerl::Command::make;
use DhMakePerl::Config;

my $maker
    = DhMakePerl::Command::make->new( { cfg => DhMakePerl::Config->new } );

$maker->meta( { name => 'Foo::Bar', version => 'v1.002003' } );

eval { $maker->extract_name_ver; };

is($@, "", "Calling extract_name_ver should not die");

is($maker->perlname, "Foo-Bar", "Dist name should be Foo-Bar");
is($maker->version,  "1.002003",   "Dist version should be 1.002003");

$maker->meta( { name => 'Foo::Bar', version => '1.02.00' } );

eval { $maker->extract_name_ver; };

is($@, "", "Calling extract_name_ver should not die");

is($maker->version,  "1.02.00",   "1.02.00 stays as 1.02.00");
