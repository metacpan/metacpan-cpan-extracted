#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Complete;

# Hermetic runtime: private HOME, isolated state root, and a chdir into the temp
# tree so the DD-OOP-LAYERS config root resolves from this fixture only and never
# from the developer's real ~/.developer-dashboard layers.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

make_path( File::Spec->catdir( $home, 'projects' ) );

my $paths     = Developer::Dashboard::PathRegistry->new( home => $home );
my $files     = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config    = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );

# --- Why the configured-collector duplicate guard needs an injected config ---
#
# Developer::Dashboard::Config collapses the merged collectors array by name, so
# a layered config that lists the same collector twice can never reach
# _collector_names as two entries. Pin that invariant first: it is the reason the
# duplicate-name arm below is driven through an injected config object instead of
# a config file.
$config->save_global(
    {
        collectors => [
            { name => 'dupe', command => 'echo first' },
            { name => 'dupe', command => 'echo second' },
        ],
    }
);

my @configured_dupe = grep { ref($_) eq 'HASH' && defined $_->{name} && $_->{name} eq 'dupe' } @{ $config->collectors };
is( scalar @configured_dupe, 1, 'layered config collapses a repeated collector name before completion ever sees it' );
is( $configured_dupe[0]{command}, 'echo second', 'the deepest duplicate wins the collapsed collector entry' );

# --- Persisted collector status fixtures ----------------------------------
#
# One persisted name shared with a configured collector, one deliberately blank
# name, and one unique name, so the persisted loop skips a blank, skips an
# already-seen name, and appends a fresh one.
for my $spec ( [ 'dir_shared', 'alpha' ], [ 'dir_blank', '' ], [ 'dir_fresh', 'gamma' ] ) {
    my ( $dir_name, $status_name ) = @{$spec};
    my $status_file = $collector->collector_paths($dir_name)->{status};
    open my $fh, '>:raw', $status_file or die "Unable to write $status_file: $!";
    print {$fh} qq({"name":"$status_name"});
    close $fh or die "Unable to close $status_file: $!";
}

# An injected config whose collectors list carries every shape the configured
# loop has to survive: a non-hash entry (undefined name), an explicitly blank
# name, a repeated name, and two ordinary names.
{
    package Local::CompleteDuplicateConfig;

    sub new { return bless {}, shift }

    sub collectors {
        return [
            'not-a-hash-entry',
            { name => '',      command => 'echo blank' },
            { name => 'alpha', command => 'echo alpha' },
            { name => 'alpha', command => 'echo alpha-again' },
            { name => 'beta',  command => 'echo beta' },
        ];
    }
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Config::new = sub { return Local::CompleteDuplicateConfig->new };

    my @names = Developer::Dashboard::CLI::Complete::_collector_names();
    is_deeply(
        \@names,
        [ 'alpha', 'beta', 'gamma' ],
        'a repeated configured collector name is recorded once and never emitted twice',
    );

    my @completions = Developer::Dashboard::CLI::Complete::complete(
        words => [ 'dashboard', 'restart', 'collector', 'alp' ],
        index => 3,
    );
    is_deeply(
        \@completions,
        ['alpha'],
        'restart collector completion prefix-filters the de-duplicated collector names',
    );
}

# The injected config is scoped to the block above: the real config object is
# back in charge afterwards, which proves the redefine did not leak.
my @real_names = Developer::Dashboard::CLI::Complete::_collector_names();
ok( ( grep { $_ eq 'dupe' } @real_names ),
    'the real layered config is restored after the injected-config block' );
ok( ( grep { $_ eq 'gamma' } @real_names ),
    'persisted collector names still reach completion through the real config path' );
is( scalar( grep { $_ eq 'dupe' } @real_names ), 1, 'the restored real path emits each collector name once' );

done_testing;

__END__

=pod

=head1 NAME

t/120-cli-complete-coverage-2.t - duplicate-name coverage for collector completion candidates

=head1 PURPOSE

This test closes the last uncovered condition arm in
C<Developer::Dashboard::CLI::Complete::_collector_names>: the C<$seen{$name}++>
short circuit that fires when the configured-collector loop meets a name it has
already recorded. It drives all three outcomes of that guard in one pass - an
undefined name from a non-hash config entry, an explicitly blank name, and a
repeated name - and then checks the persisted-status loop skips a blank name,
skips a name the configured loop already emitted, and appends a fresh one.

=head1 WHY IT EXISTS

It exists because C<Developer::Dashboard::Config> collapses the merged
collectors array by name, so no config file on disk can hand the completion
helper the same collector name twice. The duplicate guard is still real - the
helper is a plain function that any caller can point at another config object -
so the only honest way to exercise it is to inject a config whose collectors
list keeps the repeat. Pinning that here means the guard stays tested instead of
being written off as unreachable, and a future edit that drops it fails a test
rather than silently emitting duplicate completion candidates.

=head1 WHEN TO USE

Use this file when changing how completion collects collector names, when
changing the by-name collapsing inside the layered config merge, or when
changing how persisted collector status records are read for completion. Also
revisit it if the completion helper starts accepting an injected config object
directly, because the redefine used here would then be replaced by a plain
argument.

=head1 HOW TO USE

Run C<prove -lv t/120-cli-complete-coverage-2.t> from the repository root while
iterating, and keep it green under C<prove -lr t> plus the Devel::Cover gate
before release. The fixture sets a private C<HOME>, an isolated state root, and
chdirs into the temp tree first, so config and collector lookups only ever touch
the temporary layer. The injected config is installed with a C<local> glob
assignment inside a block, and the assertions after that block confirm the real
config path is back in charge once the block exits.

=head1 WHAT USES IT

The full repository suite runs it as a regression, the branch and condition
coverage gate relies on it for the configured-collector duplicate arm, and
developers changing collector completion use it as the fast feedback loop
alongside the wider completion coverage test.

=head1 EXAMPLES

Example 1:

  prove -lv t/120-cli-complete-coverage-2.t

Run this focused duplicate-name completion test on its own.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -l t/120-cli-complete-coverage-2.t

Collect coverage while exercising the configured-collector duplicate guard.

Example 3:

  prove -lr t

Recheck completion behavior across the whole repository suite before release.

=cut
