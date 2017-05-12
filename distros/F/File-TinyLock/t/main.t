#!/usr/local/bin/perl

# File::TinyLock main.t
# Copyright (c) 2014 Jeremy Kister.
# Released under Perl's Artistic License.

use strict;
use Test::Simple tests => 8;

use File::TinyLock;

my $version = File::TinyLock::_version();
ok( $version =~ /^\d+\.\d+$/, "version check okay: $version" );

my $LOCK    = "/tmp/ftl-1.$$.lock";
my $MYLOCK1 = "/tmp/ftl-2.$$.lock";
my $MYLOCK2 = "/tmp/ftl-3.$$.lock";

my $lock = File::TinyLock->new(lock    => $LOCK,
                               mylock  => $MYLOCK1,
                               retries => 0,
                               debug   => 0,
                              );

ok( $lock->{class} eq 'File::TinyLock', "created File::TinyLock object" );

ok( $lock->lock(), "created lock #1" );

open(my $lk, $LOCK) || die "could not open $LOCK: $!\n";
chomp(my $line = <$lk>);
close $lk;
my($pid,$mylock) = split /:/, $line, 2;

ok( $pid && $pid eq int($pid), "pid found in lockfile: $pid" );

my $locka = File::TinyLock->new(lock    => $LOCK,
                                mylock  => $MYLOCK2,
                                retries => 0,
                                debug   => 0,
                               );

ok( ! $locka->lock(), "second lock failed (good)" );

$lock->unlock();

ok( ! -f $LOCK, "$LOCK is removed" );
ok( ! -f $MYLOCK1, "$MYLOCK1 is removed" );
ok( ! -f $MYLOCK2, "$MYLOCK2 is removed" );
