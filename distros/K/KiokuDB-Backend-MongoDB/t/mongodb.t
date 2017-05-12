#!/usr/bin/perl

use Test::More;
use Scope::Guard;

BEGIN {
    plan skip_all => 'Please set KIOKU_MONGODB_HOST to a MONGODB_HOST' unless $ENV{KIOKU_MONGODB_HOST};
    plan 'no_plan';
}

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::MongoDB';
use ok 'MongoDB';

use KiokuDB::Test;

my $port    = $ENV{KIOKU_MONGODB_PORT} || 27017;
my $db_name = $ENV{KIOKU_MONGODB_DB}   || "kioku-test-$$";
my $conn = MongoDB::Connection->new(host => $ENV{KIOKU_MONGODB_HOST}, port => $port);
my $db   = $conn->get_database($db_name);

my $collection = $db->get_collection("test");

my $keep =
    exists $ENV{KIOKU_MONGODB_KEEP}
       ? $ENV{KIOKU_MONGODB_KEEP}
       : $ENV{KIOKU_MONGODB_DB}          
         ? 1
         : 0;


eval { $collection->drop };
my $sg = $keep || Scope::Guard->new(sub { $db->drop });

my $mongo = KiokuDB::Backend::MongoDB->new('collection' => $collection);
$mongo->clear;

run_all_fixtures(KiokuDB->new(backend => $mongo));


