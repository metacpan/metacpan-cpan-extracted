#!/usr/bin/perl

use Test::More;
use Scope::Guard;

BEGIN {
    plan skip_all => 'Please set KIOKU_MONGODB_HOST to a MONGODB_HOST' unless $ENV{KIOKU_MONGODB_HOST};
    plan 'no_plan';
}

use ok 'KiokuDB';

my $port    = $ENV{KIOKU_MONGODB_PORT} || 27017;
my $db_name = $ENV{KIOKU_MONGODB_DB}   || "kioku-test-$$";
my $db_host = $ENV{KIOKU_MONGODB_HOST};

my $kioku = KiokuDB->connect("MongoDB:database_host=$db_host;database_name=$db_name;database_port=$port;collection_name=test");

ok($kioku);


