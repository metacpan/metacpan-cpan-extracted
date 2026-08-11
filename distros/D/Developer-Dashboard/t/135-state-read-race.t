#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Developer::Dashboard::Collector;
use Developer::Dashboard::JSON ();
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

# Hermetic runtime: the state root resolves from the deepest .developer-dashboard
# layer at or above the CWD, so the temp home must also be the working directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $store  = Developer::Dashboard::Collector->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $store,
    config     => $config,
    files      => $files,
    paths      => $paths,
);
my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { return 1 },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

# A reader that catches the state file mid-replace must not die. The replace
# window leaves the file momentarily zero-length, which json_decode treats as
# malformed input; every consumer (serve status, the web strip, prompt
# rendering) reads through this accessor, so an empty observation has to be
# reported as "no state yet" instead of taking the caller down.
my $state_file = $files->web_state;
$manager->_write_web_state( { status => 'running', pid => $$ } );
ok( -f $state_file, 'web state file exists after a normal write' );

open my $truncate_fh, '>:raw', $state_file or die "Unable to truncate $state_file: $!";
close $truncate_fh or die "Unable to close $state_file: $!";
is( -s $state_file, 0, 'state file is observable as zero-length mid-replace' );

my $empty_state = eval { $manager->web_state };
my $empty_error = $@;
is( $empty_error, '', 'web_state survives a zero-length state file instead of dying' );
ok( !defined $empty_state || ref $empty_state eq 'HASH', 'web_state reports no usable state rather than malformed data' );

# A partially written payload is the same class of transient observation.
open my $partial_fh, '>:raw', $state_file or die "Unable to write $state_file: $!";
print {$partial_fh} '{"status":"run';
close $partial_fh or die "Unable to close $state_file: $!";

my $partial_state = eval { $manager->web_state };
my $partial_error = $@;
is( $partial_error, '', 'web_state survives a truncated payload instead of dying' );
ok( !defined $partial_state || ref $partial_state eq 'HASH', 'web_state reports no usable state for a truncated payload' );

# A complete payload still decodes normally after the transient states.
$manager->_write_web_state( { status => 'stopped', pid => 4242 } );
my $good_state = $manager->web_state;
is( ref $good_state, 'HASH', 'web_state decodes a complete payload' );
is( $good_state->{status}, 'stopped', 'web_state returns the persisted status' );
is( $good_state->{pid},    4242,      'web_state returns the persisted pid' );

# The collector-status reader shares the accessor pattern and must be equally
# tolerant, because the same replace window applies to its state file.
$store->write_job( 'collector-race', command => 'true' );
my ($collector_job_file) = grep { -f $_ } $store->_collector_file_candidates( 'collector-race', 'job.json' );
ok( $collector_job_file, 'collector job file exists after a normal write' );
open my $collector_fh, '>:raw', $collector_job_file or die "Unable to truncate $collector_job_file: $!";
close $collector_fh or die "Unable to close $collector_job_file: $!";
my $collector_job = eval { $store->read_job('collector-race') };
is( $@, '', 'collector job reader survives a zero-length state file' );
ok( !defined $collector_job || ref $collector_job eq 'HASH', 'collector job reader reports no usable state for an empty file' );

# Direct contract for the shared helper: every outcome a concurrent reader can
# hand it, so the tolerant path is covered on all metrics rather than only
# through its callers.
is( Developer::Dashboard::JSON::json_decode_state(undef), undef, 'json_decode_state treats an unread file (undef) as no state' );
is( Developer::Dashboard::JSON::json_decode_state(''),    undef, 'json_decode_state treats an empty payload as no state' );
is( Developer::Dashboard::JSON::json_decode_state("\n \t"), undef, 'json_decode_state treats a whitespace-only payload as no state' );
is( Developer::Dashboard::JSON::json_decode_state('{"a":'), undef, 'json_decode_state treats a truncated payload as no state' );
is_deeply( Developer::Dashboard::JSON::json_decode_state('{"a":1}'), { a => 1 }, 'json_decode_state decodes a complete payload' );

done_testing;

__END__

=pod

=head1 NAME

t/135-state-read-race.t - transient-empty state file tolerance for runtime readers

=head1 PURPOSE

This test is the executable contract that runtime state readers survive
observing a state file while it is being replaced. It writes a real state
payload, then reproduces the two transient states a concurrent reader can
observe - zero-length and truncated - and asserts the accessor reports "no
usable state" instead of dying, while a complete payload still decodes.

=head1 WHY IT EXISTS

The full suite failed with t/09-runtime-manager.t exiting 255 while that file
passed standalone. A two-process reproduction showed the reader dying inside
json_decode with stat() reporting size zero at that instant and valid JSON
microseconds later: the atomic write-and-replace path leaves a window where the
state file is observably empty. Every consumer of the web state - serve status,
the web status strip, prompt rendering - reads through the same accessor, so
this test exists to keep a transient observation from taking callers down.

=head1 WHEN TO USE

Use this file when changing runtime state persistence, the write-and-replace
path, the state readers, or any consumer that decodes cached runtime state.

=head1 HOW TO USE

Run C<prove -lv t/135-state-read-race.t> while iterating on state persistence,
and keep it green under C<prove -lr t> and the coverage gate before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate use this
file to keep runtime state reads race-tolerant.

=head1 EXAMPLES

Example 1:

  prove -lv t/135-state-read-race.t

Run the state-read race contract by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
