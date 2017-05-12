#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

use IPC::Cache;

$loaded = 1;
print "ok 1\n";


######################### End of black magic.


my $sTEST_CACHE_KEY = "TSTC";
my $sTEST_NAMESPACE = "TestCache";

# Test creation of a cache object

my $test = 2;

my $cache1 = new IPC::Cache( { cache_key => $sTEST_CACHE_KEY,
			       namespace => $sTEST_NAMESPACE } );
if ($cache1) {
    print "ok $test\n";
} else {
    print "not ok $test\n";
}

# Test the setting of a scalar in the cache

$test = 3;

my $seed_value = "Hello World";

my $key = 'key1';

my $status = $cache1->set($key, $seed_value);

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}

# Test the getting of a scalar from the cache

$test = 4;

my $val1_retrieved = $cache1->get($key);

if ($val1_retrieved eq $seed_value) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}

# Test the getting of the scalar from a subprocess

$test = 5;

if (system("perl", "-Iblib/lib", "./test/test_get.pl", $sTEST_CACHE_KEY, $sTEST_NAMESPACE, $key, $seed_value) == 0) {
    print "ok $test\n";
} else {
    print "not okay $test\n";
}


# Test checking the memory consumption of the cache

$test = 6;

my $size = IPC::Cache::SIZE($sTEST_CACHE_KEY);

if ($size) {
   print "ok $test\n";
} else {
    print "not okay $test\n";
}


# Test clearing the cache's namespace

$test = 7;

$status = $cache1->clear();

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}


# Test the getting of a scalar after the clearing of a cache

$test = 8;

my $val2_retrieved = $cache1->get($key);

if ($val2_retrieved) {
    print "not ok $test\n";
} else {
   print "ok $test\n";
}


# Test the setting of a scalar in the cache with a immediate timeout

$test = 9;

$status = $cache1->set($key, $seed_value, 0);

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}


# Test the getting of a scalar from the cache that should have timed out immediately

$test = 10;

my $val3_retrieved = $cache1->get($key);

if ($val3_retrieved) {
    print "not ok $test\n";
} else {
   print "ok $test\n";
}


# Test the setting of a scalar in the cache with a timeout in the near future

$test = 11;

$status = $cache1->set($key, $seed_value, 2);

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}


# Test the getting of a scalar from the cache that should not have timed out yet (unless the system is *really* slow)

$test = 12;

my $val4_retrieved = $cache1->get($key);

if ($val4_retrieved eq $seed_value) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}


# Test the getting of a scalar from the cache that should have timed out

$test = 13;

sleep(3);

my $val5_retrieved = $cache1->get($key);

if ($val5_retrieved) {
    print "not ok $test\n";
} else {
   print "ok $test\n";
}


# Test purging the cache's namespace

$test = 14;

$status = $cache1->purge();

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}



# Test PURGING of a cache object

$test = 15;

$status = IPC::Cache::PURGE($sTEST_CACHE_KEY);

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}


# Test CLEARING of a cache object

$test = 16;

$status = IPC::Cache::CLEAR($sTEST_CACHE_KEY);

if ($status) {
    print "ok $test\n";
} else {
   print "not ok $test\n";
}

1;


