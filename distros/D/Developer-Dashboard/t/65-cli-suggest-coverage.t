#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Suggest;

# Hermetic runtime rooted in a throwaway home. Layer discovery keys off the
# current working directory, so we chdir into the temp home before building any
# registry so the deepest .developer-dashboard layer resolves inside the sandbox.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [],
    project_roots   => [],
);
my $suggest = Developer::Dashboard::CLI::Suggest->new( paths => $paths );

# The default constructor path: with no explicit paths/manager the || guards
# fall to their right operands and build a fresh registry and skill manager.
{
    my $defaulted = Developer::Dashboard::CLI::Suggest->new;
    isa_ok(
        $defaulted,
        'Developer::Dashboard::CLI::Suggest',
        'Suggest->new builds its own path registry and skill manager when none are supplied',
    );
}

# _logical_command_name maps a defined-but-empty entry to an empty logical name
# (right side of the "not defined or eq ''" guard).
is(
    Developer::Dashboard::CLI::Suggest::_logical_command_name(''),
    '',
    '_logical_command_name maps a defined empty entry to an empty logical name',
);

# _rank_candidates tolerates an undefined candidate list via its empty-list guard.
is_deeply(
    [ $suggest->_rank_candidates( 'anything', undef ) ],
    [],
    '_rank_candidates tolerates an undefined candidate list via the empty-list guard',
);

# Equal-score candidates force the ranking sort past the score comparator into
# the length and string tiebreakers.
is_deeply(
    [ map { $_->{value} } $suggest->_rank_candidates( 'de', [ 'delete', 'deploy' ] ) ],
    [ 'delete', 'deploy' ],
    '_rank_candidates breaks equal-score equal-length ties by string comparison',
);
is_deeply(
    [ map { $_->{value} } $suggest->_rank_candidates( 'de', [ 'deletion', 'deploy' ] ) ],
    [ 'deploy', 'deletion' ],
    '_rank_candidates breaks equal-score ties by candidate length',
);

# An enabled skill that exposes no commands yields an empty suggestion set, so
# the did-you-mean block is omitted from the guidance message.
{
    my $skills_root = $paths->skills_root;
    make_path( File::Spec->catdir( $skills_root, 'emptyskill' ) );
    is(
        $suggest->unknown_skill_command_message( 'emptyskill', 'whatever' ),
        "Command 'whatever' not found in skill 'emptyskill'.\n\n",
        'unknown_skill_command_message omits the did-you-mean block when an enabled skill exposes no commands',
    );
}

# A duplicated built-in helper name is collapsed by the seen-name guard.
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::InternalCLI::helper_names = sub {
        return ( 'dupcmd', 'dupcmd', 'othercmd' );
    };
    my @candidates = $suggest->top_level_candidates;
    is(
        scalar( grep { $_ eq 'dupcmd' } @candidates ),
        1,
        '_top_level_candidates de-duplicates repeated built-in helper names',
    );
}

# A cli entry whose logical name is falsy ("0") is skipped, and an entry whose
# logical name duplicates a built-in helper is skipped by the seen guard.
{
    my $cli = $paths->cli_root;
    open my $zero, '>', File::Spec->catfile( $cli, '0' ) or die "Unable to seed cli entry: $!";
    close $zero;
    open my $dup, '>', File::Spec->catfile( $cli, 'config.sh' ) or die "Unable to seed cli entry: $!";
    close $dup;

    my @candidates = $suggest->top_level_candidates;
    ok(
        !( grep { $_ eq '0' } @candidates ),
        '_top_level_candidates skips cli entries whose logical name is falsy',
    );
    is(
        scalar( grep { $_ eq 'config' } @candidates ),
        1,
        '_top_level_candidates skips a cli entry whose logical name duplicates a built-in helper',
    );
}

# An unreadable cli root dies explicitly rather than silently yielding nothing.
{
    my $cli = $paths->cli_root;
    chmod 0000, $cli or die "Unable to chmod $cli: $!";
    my $err = eval { $suggest->top_level_candidates; 1 } ? '' : $@;
    chmod 0755, $cli or die "Unable to restore $cli: $!";
    like(
        $err,
        qr/Unable to read/,
        '_top_level_candidates dies when a cli root cannot be opened',
    );
}

# An unreadable skill cli directory dies explicitly while collecting commands.
{
    my $cli = File::Spec->catdir( $paths->skills_root, 'skillG', 'cli' );
    make_path($cli);
    chmod 0000, $cli or die "Unable to chmod $cli: $!";
    my $err = eval { $suggest->skill_commands('skillG'); 1 } ? '' : $@;
    chmod 0755, $cli or die "Unable to restore $cli: $!";
    like(
        $err,
        qr/Unable to read/,
        '_collect_skill_commands dies when a skill cli directory cannot be opened',
    );
}

# A falsy logical name ("0") inside a skill cli directory is skipped.
{
    my $cli = File::Spec->catdir( $paths->skills_root, 'skillH', 'cli' );
    make_path($cli);
    open my $zero, '>', File::Spec->catfile( $cli, '0' ) or die "Unable to seed skill cli entry: $!";
    close $zero;
    is_deeply(
        [ $suggest->skill_commands('skillH') ],
        [],
        '_collect_skill_commands skips skill cli entries whose logical name is falsy',
    );
}

# An unreadable nested skills directory dies explicitly during recursion.
{
    my $nested = File::Spec->catdir( $paths->skills_root, 'skillI', 'skills' );
    make_path($nested);
    chmod 0000, $nested or die "Unable to chmod $nested: $!";
    my $err = eval { $suggest->skill_commands('skillI'); 1 } ? '' : $@;
    chmod 0755, $nested or die "Unable to restore $nested: $!";
    like(
        $err,
        qr/Unable to read/,
        '_collect_skill_commands dies when a nested skills directory cannot be opened',
    );
}

# Line 240 score comparator, both branch sides: different scores make the
# `<=>` truthy so the `||` short-circuits, while equal scores make it 0 and
# fall through to the length (and string) tiebreakers.
{
    my @by_score = map { $_->{value} } $suggest->_rank_candidates( 'de', [ 'delete', 'xde' ] );
    is( $by_score[0], 'delete', '_rank_candidates orders the lower-score (closer) candidate first via the score comparator' );
    my @by_length = map { $_->{value} } $suggest->_rank_candidates( 'de', [ 'deletion', 'deploy' ] );
    is( $by_length[0], 'deploy', '_rank_candidates falls through equal scores to the length tiebreaker' );
}

done_testing;

__END__

=pod

=head1 NAME

t/65-cli-suggest-coverage.t - branch and condition closure for the CLI suggestion helper

=head1 PURPOSE

This test is the executable coverage contract for the harder-to-reach branches
and conditions in the dashboard command-suggestion helper. It drives the
de-duplication guards, the falsy-logical-name skips, the unreadable-directory
failure paths, and the ranking tiebreakers so the module keeps full branch and
condition coverage without loosening the gate.

=head1 WHY IT EXISTS

The suggestion helper scans built-in helpers, layered custom cli roots, and
installed skill trees, then fuzzy-ranks the closest matches. Several of its
guards - repeated helper names, command files whose logical name is C<0>,
directories that exist but cannot be opened, and score ties that fall through to
the length and string comparators - are never exercised by ordinary success-path
CLI tests. This file reproduces each of those situations directly so a
regression in the discovery or ranking logic surfaces as a failing assertion.

=head1 WHEN TO USE

Use this file when changing command discovery across layers, the dotted skill
command walk, the unknown-command or unknown-skill-command guidance strings, or
the fuzzy ranking and tiebreaking behavior.

=head1 HOW TO USE

Run C<prove -lv t/65-cli-suggest-coverage.t> while iterating on the helper, and
keep it green under C<prove -lr t> and the coverage gate before release. The test
builds a hermetic temp home, chdir's into it so layer discovery stays inside the
sandbox, and constructs the helper through the path registry.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the branch/condition
coverage gate all rely on this file to keep the command-suggestion helper's edge
behavior from regressing.

=head1 EXAMPLES

Example 1:

  prove -lv t/65-cli-suggest-coverage.t

Run the focused suggestion-helper coverage test by itself while changing it.

Example 2:

  prove -lr t

Run it inside the full repository suite before calling the work finished.

=cut
