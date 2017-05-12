#!/usr/bin/perl -w

use strict;
use IPC::Cache;

my $sUSAGE = "Usage: test_get.pl cache_key namespace key expected_value";

my $cache_key = $ARGV[0] or
    die("$sUSAGE\n");

my $namespace = $ARGV[1] or
    die("$sUSAGE\n");

my $key = $ARGV[2] or
    die("sUSAGE\n");

my $expected_value = $ARGV[3] or
    die("sUSAGE\n");

my $cache = new IPC::Cache( { cache_key => $cache_key, namespace => $namespace } ) or
    die("Couldn't create cache");

my $value = $cache->get($key) or
    die("Couldn't get object at $key");

$value eq $expected_value or
    die("value $value not equal to $expected_value");

exit(0);


