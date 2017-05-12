#!/usr/bin/perl
#
# Test Email::Fingerprint::Cache.

use lib 'build_lib';

use strict;
use English;
use warnings;
use Email::Fingerprint;

use POSIX;
use FindBin;
use Test::More;
use Test::Exception;
use Test::Warn;

# Helper class for testing output
{
    package Test::Stdout;

    sub TIEHANDLE
    {
        my $class = shift;
        my $self = {};
        $self->{string} = shift;
        ${ $self->{string} } ||= '';

        return bless $self, $class;
    }

    sub PRINT
    {
        my $self = shift;
        ${ $self->{string} } .= join '', @_;
    }

    sub PRINTF
    {
        my $self = shift;
        my $format = shift;
        ${ $self->{string} } .= sprintf($format, @_);
    }
}

# Sentinel object to delete data files
package Sentinel;

sub DESTROY {
    my $self = shift;
    unlink $_ for glob $self->{file} . "*";
}

# Back to our show...
package main;

eval "use Email::Fingerprint::Cache";
if ($@)
{
    plan ( skip_all => "Failed to load Email::Fingerprint::Cache" );
}
else
{
    plan ( tests => 43 );
}

############################################################################
# First, run through the general cache functionality, without stressing
# anything or doing anything extra.
############################################################################

my $cache;
my %fingerprints;
my $file     = "t/data/tmp_cache";

lives_ok {
    $cache     =  new Email::Fingerprint::Cache({
        backend   => "AnyDBM",
        hash      => \%fingerprints,
        file      => $file,         # Created if doesn't exist
        ttl       => 60,            # Purge records after one minute
    });
} "Constructing a cache with reasonable values should succeed";

# Look up the TTL
ok $cache->can('get_ttl'), "The cache should support a get_ttl() method";
ok $cache->get_ttl == 60, "... and the TTL value should be 60 seconds";

# Arrange for cleanup on exit
my $sentinel = bless { file => $file }, "Sentinel";

# Create the file
ok $cache->can('open'), "The cache should support an open() method";
ok $cache->open, "... and opening the cache should succeed";

# Add a bunch of "fingerprints", all older than one minute
for my $n ( 1..100 ) {
    my $timestamp = time - 60 - int(rand(100_000_000));
    $fingerprints{$n} = $timestamp;
}

# Now confirm that they're there
ok scalar(keys %fingerprints) == 100, "(Successfully added 100 fingerprints to cache)";

# Double-check using the value returned by get_hash()
ok $cache->can('get_hash'), "The cache should support a get_hash() method";
ok $cache->get_hash, "... and getting the hash of fingerprints should succeed";
ok scalar(keys %{ $cache->get_hash }) == 100, "... and the hash should contain 100 fingerprints";

# ...and purge them.
$cache->purge;
ok scalar(keys %fingerprints) == 0, "Purged cache successfully";

# Verify that the hash is tied
ok tied %fingerprints ? 1 : 0, "Fingerprints tied";
lives_ok { $cache->close } "Closed cache without incident";
ok tied %fingerprints ? 0 : 1, "Fingerprints untied";
warning_is { undef $cache } undef, "Destroyed without warnings";


############################################################################
# Now, exercise the constructor more thoroughly
############################################################################

{
    # We define a package to suppress warnings we don't care about.
    package BOGUS;
    sub is_open {}
    sub unlock {}

    package main;

    # Simple constructor call, all defaults
    lives_ok { $cache = new Email::Fingerprint::Cache } "Default constructor";

    # Construction with an invalid backend should fail
    throws_ok { $cache = new Email::Fingerprint::Cache({ backend => 'BOGUS' }) }
        qr{Can't load},
        "Constructing an object with an invalid backend";
}

############################################################################
# Now exercise the file() method, which supports several cases for a
# generality of backends.
############################################################################

# Default backend, default filename
$cache = new Email::Fingerprint::Cache({ backend => undef });

# Backend with file() method
{
    package Backend1;
    sub new { my $scalar; return bless \$scalar, "Backend1"; }
    sub unlock {}
    sub is_open {0}

    package main;
    $cache = new Email::Fingerprint::Cache({ backend => "Backend1" });

    ok $cache, "Cache using locally defined class as backend";
}

# Backend with AUTOLOAD method supplying a filename
{
    package Backend2;
    sub new { my $scalar; return bless \$scalar, "Backend2"; }
    sub AUTOLOAD { return "foo" }
    sub unlock {}
    sub is_open {0}

    package main;
    $cache = new Email::Fingerprint::Cache({ backend => "Backend2" });

    ok $cache, "Another cache using locally defined class as backend";
}

# Constructor returns undef
{
    package Backend8;
    sub new  {}
    sub unlock {}
    sub is_open {0}

    package main;

    # Construction should fail
    throws_ok
        { $cache = new Email::Fingerprint::Cache({ backend => 'Backend8' }) }
        qr{Can't load},
        "Dies when constructor returns undef";
}

# Clean up a little
undef $cache;


############################################################################
# Exercise the lock() and unlock() methods
############################################################################
SKIP: {
    my $perl = $EXECUTABLE_NAME;
    my $lib  = "$FindBin::Bin/../lib";

    # We make a massive effort to make this test work on Windows,
    # even though fork() is completely broken there. We do skip this
    # part of the test if we simply can't launch Perl, though.
    my $status = system (
        $perl, '-I', $lib, qw/ -MPOSIX -MEmail::Fingerprint::Cache -e 0 /
    );
    if ($status != 0)
    {
        diag "Perl: $perl";
        diag "Lib: $lib";
        diag "\$0: $0";

        skip "can't run perl; your system looks broken", 3 unless $status == 0;
    }

    # Clean up the lockfile from any crashed test runs
    unlink "$file.lock";

    # Open two caches and make 'em fight.
    my $cache1 = new Email::Fingerprint::Cache({ file => $file });
    skip "failed to create cache for lock test", 3 unless $cache1;

    # Locking cache 1 should prevent locking the same cache in another process.
    # NOTE: It prevents locking cache2 in the *same* process on most UNIX
    # variants, except Solaris.
    ok $cache1->lock   ? 1 : 0,
        "Locking a cache should succeed when nobody else has a lock";

    # Now attempt a second lock, in a separate process, without forking.
    # Good luck with that!
    $status = system(
        $perl, '-I', $lib, qw/ -MPOSIX -MEmail::Fingerprint::Cache -e /,
        qq{
            \$cache = Email::Fingerprint::Cache->new({ file => '$file' });
            POSIX::_exit(0) if \$cache->lock;
            POSIX::_exit(1);
        },
    );

    ok +($status >> 8 == 1), "... and other processes should be unable to lock the locked cache";
    skip "failed to unlock test cache", 1 unless $cache1->unlock;

    $status = system(
        $perl, '-I', $lib, qw/ -MPOSIX -MEmail::Fingerprint::Cache -e /,
        qq{
            \$cache = Email::Fingerprint::Cache->new({ file => '$file' });
            POSIX::_exit(0) unless \$cache->lock;
            POSIX::_exit(0) unless \$cache->unlock;
            POSIX::_exit(1);
        },
    );

    ok +($status >> 8 == 1), "... until after the original process releases its lock";

    # Destroy the caches
    undef $cache1;
}

############################################################################
# Test the ugly failsafe in the DESTROY() method
############################################################################

$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# Open and lock the cache.
if (not $cache or not $cache->open or not $cache->lock)
{
    # Suppress spurious warnings
    $cache->close;
    $cache->unlock;
    undef $cache;

    ok 0, "Create an open, locked cache for warning test";
}
else
{
    warning_like
        { undef $cache }
        { carped => qr/before it was close/ },
        "Destroying an open, locked cache should generate a warning";
}

# Create another one
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# This time, we open but don't lock the cache.
if (not $cache or not $cache->open)
{
    $cache->close;
    undef $cache;

    ok 0, "Create an open, unlocked cache for warning test";
}
else
{
    warning_like
        { undef $cache }
        { carped => qr/before it was close/},
        "Destroying an open, unlocked cache should generate a warning";
}

# Create another one
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# This time, we lock but don't open the cache.
if (not $cache or not $cache->lock)
{
    $cache->close;
    undef $cache;

    ok 0, "Create a locked but unopened cache for warning test";
}
else
{
    warning_is { undef $cache } undef,
        "Destroying a locked but unopened cache should not generate warnings";
}



############################################################################
# Exercise purge() more thoroughly
############################################################################

SKIP: {
    %fingerprints = ();

    $cache = new Email::Fingerprint::Cache({
        file => $file,
        hash => \%fingerprints,
        ttl  => 60,
    });

    # Open the cache.
    ok $cache,       "New cache for TTL test";
    ok $cache->open, "Opened cache";
    ok scalar(keys %fingerprints) == 0, "Cache initially empty";

    # Populate the cache with 500 items each: less than 60 seconds old;
    # between 60 and 119 seconds old; older than 120 seconds.
    for my $n ( 1..500 ) {
        my $timestamp = time;
        my $key       = sprintf "%03i", $n;

        $fingerprints{"a$key"} = $timestamp - int(rand(58)) -   1;  # Less than 1 minute
        $fingerprints{"b$key"} = $timestamp - int(rand(58)) -  61;  # Less than 2 minutes
        $fingerprints{"c$key"} = $timestamp - int(rand(59)) - 121;  # More than 2 minutes
    }

    # Add a fingerprint with no defined timestamp, or a timestamp
    # that evaluates to false.
    $fingerprints{101} = undef;
    $fingerprints{102} = 0;
    $fingerprints{103} = '';

    # And finally, add one entry that WON'T be purged.
    $fingerprints{104} = 60 + time; # Just in case the test runs slow...

    # Now confirm that they're there
    my $count = scalar(keys %fingerprints);
    ok $count == 1504, "The cache should contain 1,504 fingerprints, and contains: $count";

    # First, purge the invalid timestamps
    $cache->purge( ttl => 200 );
    $count = scalar(keys %fingerprints);
    ok $count == 1501, "...   3 with invalid timestamps, which should now be purged ($count remaining)";

    # Next, purge items older than 2 minutes, and check. The "false"
    # fingerprints should also be gone.
    $cache->purge( ttl => 120 );
    $count = scalar(keys %fingerprints);
    ok $count == 1001, "... 500 older than two minutes, which should now be purged ($count remaining)";

    # Then purge using the default TTL, which we set earlier to 60.
    # Confirm that the default TTL is used and not, e.g., 120.
    $cache->purge;
    $count = scalar(keys %fingerprints);
    ok $count == 501, "... 500 older than one minute, which should now be purged ($count remaining)";

    # Purge all entries older than this second
    $cache->purge( ttl => 0 );
    $count = scalar(keys %fingerprints);
    ok scalar(keys %fingerprints) == 1, "... 500 older than one second, which should now be purged ($count remaining)";

    # Purge using a TTL of -1, which should remove everything
    $cache->purge( ttl => -1 );
    $count = scalar(keys %fingerprints);
    ok $count == 0, "...   1 younger than one second, which should now be purged ($count remaining)";

    # Clean up
    $cache->close;
    undef $cache;
}


############################################################################
# Test the dump() method, which prints to STDOUT
############################################################################

$file = 't/data/cache';
my %hash;
our $data;

# Read the data, stored in Perl format: loads hashref $data
require "$file.pl";

$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => \%hash,
});

# Open the cache file
ok $cache->open, "Opening the test cache should succeed";

# Purge the cache, in case there's leftover test data around
$cache->purge( ttl => -1 );

# Add our data to the hash
$hash{$_} = $data->{$_} for keys %$data;

# Close and reopen
ok $cache->close, "... and closing it should also be successful";
ok $cache->open, "... as should reopening it";

my $output;

# Dump the cache, catching the output
tie *STDOUT, 'Test::Stdout', \$output;
$cache->dump;
untie *STDOUT;

# Read the test data
open IN, '<', "$file.txt";
my $standard = join '', <IN>;
close IN;

# Compare
ok $output eq $standard, "... and the contents should match our test data";

# Clean up
lives_ok { $cache->close } "Closing the cache should not throw an exception";
warning_is { undef $cache } undef, "Destroying the closed cache should not generate warnings";

############################################################################
# Test the set_file method, which only works when no file is open.
############################################################################

# Get a fresh cache
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# Nothing should happen, either, if the file is locked
$cache->lock;
ok !defined $cache->set_file('foo'), "Setting a new cache file should fail when the cache is locked";
$cache->unlock;

# Nothing should happen, either, if the file is locked
$cache->open;
ok !defined $cache->set_file('foo'), "... or when the file is open";
$cache->close;

# Finally, the file is closed and unlocked, so it should work
ok $cache->set_file('foo'), "... but it should be successful if the cache is closed and unlocked";

# Clean up
unlink "t/data/cache.db";

# That's all, folks!
done_testing();
