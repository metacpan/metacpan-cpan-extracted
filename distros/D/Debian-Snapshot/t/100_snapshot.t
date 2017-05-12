#! /usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

BEGIN { use_ok("Debian::Snapshot"); }

my $snapshot = Debian::Snapshot->new;
ok(defined $snapshot, "Debian::Snapshot->new");

ok($snapshot->user_agent->isa("LWP::UserAgent"), '$snapshot->user_agent is a LWP::UserAgent');
ok($snapshot->url =~ m{^https?://}, '$snapshot->url looks like a URL');

my $package = $snapshot->package("package", "1.0-1");
ok($package->isa("Debian::Snapshot::Package"), '$snapshot->package(...) returns a package');
ok($package->package eq "package", 'package has correct name');
ok($package->version eq "1.0-1", 'package has correct version');

done_testing();
