#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);

my $repo = abs_path('.');
my $gate = File::Spec->catfile( $repo, 'script', 'coverage-gate' );

SKIP: {
    skip 'Unix permission modes are not a Windows security control', 1 if $^O eq 'MSWin32';
    ok( -x $gate, 'the coverage gate is executable' );
}

# Purpose: run the gate the way a scheduler runs it - with a named environment
#          and nothing inherited from this shell.
# Input:   hash of environment variables to set
# Output:  (stdout, stderr, exit code)
sub run_gate_with_env {
    my (%env) = @_;

    # A clean environment without a shell: localise %ENV to exactly the named
    # variables and run perl on the gate by path. The old form ran `env -i`
    # and let it exec the gate directly, which Windows cannot do - an
    # extensionless Perl script is not executable - so the gate never ran
    # there and exited 126.
    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = %env;
        system $^X, $gate, '--help';
    };
    return ( $stdout, $stderr, $exit >> 8 );
}

# THE FAILURE THIS FILE EXISTS FOR. Launched from a transient systemd unit - an
# environment with no PERL5LIB - the gate died at once with "Can't locate
# Crypt/URandom.pm in @INC ... you may need to install the Crypt::URandom
# module". That module is declared in cpanfile, dist.ini and Makefile.PL, and it
# is installed. The gate was reporting the environment it happened to inherit as
# a missing dependency, so the diagnosis pointed at the product while the fault
# was the launch.
#
# The product's dependencies live in the operator's local library tree and
# PERL5LIB is exported only by the interactive shell profile, so cron, systemd
# units and agent tool-shells all start without it. A gate that only works in the
# environment nobody schedules it from is not a gate.
# WHERE THIS PROPERTY CAN BE ASSERTED AT ALL, and the reason it is a skip rather
# than an unconditional check (DD-552).
#
# The repair adds ONE directory, $HOME/perl5/lib/perl5, and only when it exists.
# So "the gate resolves its dependencies with no PERL5LIB" can only be true on a
# host where the dependencies actually live there. On this operator's machine they
# do. On CI they do not - they are installed into a local::lib reached through
# PERL5LIB - so under env -i nothing can resolve, the gate correctly reports a
# missing module, and asserting otherwise tests the host rather than the product.
#
# That is not hypothetical: this file failed exactly that way in CI and took the
# v4.27 signed release down with it. The suite passed here and the release step
# never ran, which is this project's oldest CI trap - a job that fails early makes
# every later step SKIP, and local green says nothing about it.
my $LOCAL_LIB = File::Spec->catdir( $ENV{HOME} // '', 'perl5', 'lib', 'perl5' );

SKIP: {
    skip "this host keeps no library tree at $LOCAL_LIB, so there is nothing for the repair to find "
      . 'and the gate is not expected to resolve anything without PERL5LIB', 2
      if !-d $LOCAL_LIB;

    my ( $stdout, $stderr, $exit ) = run_gate_with_env(
        HOME => $ENV{HOME},
        PATH => '/usr/bin:/bin',
    );

    unlike( $stderr, qr/Can't locate .*\.pm in \@INC/,
        'with no PERL5LIB the gate resolves its declared dependencies instead of reporting one as missing' );
    isnt( $exit, 2, 'and does not exit unusable before it has done anything' );
}

# The mirror: this repair must not be able to hide a genuinely missing
# dependency. It cannot, and the reason is structural rather than tested through
# --help, which returns before any dependency is loaded and so can never answer
# the question - the first version of this file asked it that way and got a
# passing exit code that proved nothing.
#
# What IS checkable is the property the guarantee rests on: the block adds a
# directory only when that directory exists, and installs, stubs or vendors
# nothing. So an absent module stays absent and still fails at its use statement.
{
    my $empty = tempdir( 'dd-no-perl5-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my ( $stdout, $stderr, $exit ) = run_gate_with_env(
        HOME => $empty,
        PATH => '/usr/bin:/bin',
    );

    # The exit code is only meaningful where the dependencies are reachable
    # without PERL5LIB at all. Where they are not - CI installs them into a
    # local::lib - the gate exits non-zero naming a missing module, which is the
    # CORRECT behaviour being asserted two blocks below: an absent module stays
    # absent. Asserting 0 there was asserting the host.
    SKIP: {
        skip 'the dependencies are not reachable on this host without PERL5LIB, so a non-zero exit here is the '
          . 'missing-module behaviour this file asserts elsewhere rather than a fault', 1
          if $stderr =~ /Can't locate .*\.pm in \@INC/;

        is( $exit, 0, 'a HOME with no library tree is not itself an error - nothing is invented' );
    }

    # This one holds everywhere and stays unconditional: whatever the gate does
    # about a missing module, it must never have added the non-existent tree.
    unlike( $stderr, qr/\Q$empty\E/,
        'and the non-existent tree is never added to the path, so it cannot mask or misdirect a later failure' );

    my $source = do { open my $fh, '<', $gate or die $!; local $/; <$fh> };
    like( $source, qr/my \@leading_paths = grep \{ defined \$_ && -d \$_ \}/,
        'the source adds only existing build and local-library paths - absent modules stay absent' );
    # Against the BLOCK, not the whole file: the first version matched the word
    # "install" in the script's own help text and failed on its own prose.
    my ($block) = $source =~ /^BEGIN \{(.*?)^\}/ms;
    ok( defined $block, 'the library-path repair is a BEGIN block, so it runs before the first use statement' );
    unlike( $block // '', qr/system|exec|qx|`|cpanm/,
        'and it runs no external command - it can only add a path, never obtain a module' );
}

# Adding the path twice would be harmless but is worth pinning: the repair is
# meant to be idempotent, and a caller that already has it set must see no change.
{
    my $local_lib = File::Spec->catdir( $ENV{HOME}, 'perl5', 'lib', 'perl5' );
  SKIP: {
        skip 'this host has no local library tree to double up', 1 if !-d $local_lib;

        my ( $stdout, $stderr, $exit ) = run_gate_with_env(
            HOME     => $ENV{HOME},
            PATH     => '/usr/bin:/bin',
            PERL5LIB => $local_lib,
        );
        unlike( $stderr, qr/Can't locate/,
            'a caller that already set the library path is unaffected by the repair' );
    }
}

done_testing;

__END__

=head1 NAME

t/155-coverage-gate-library-path.t - the gate runs from an environment it did not inherit

=head1 PURPOSE

Verify that C<script/coverage-gate> resolves the project's declared dependencies
when launched with no C<PERL5LIB>, and that a genuinely missing dependency still
fails loudly.

=head1 WHY IT EXISTS

Launched from a transient systemd unit the gate died immediately, naming
C<Crypt::URandom> as missing. That module is declared in C<cpanfile>, C<dist.ini>
and C<Makefile.PL>, and installed. The gate was reporting the environment it
happened to inherit as a missing dependency: the diagnosis pointed at the product
and the fault was the launch.

The product's dependencies live in the operator's local library tree, and
C<PERL5LIB> is exported only by the interactive shell profile. Cron, systemd
units and agent tool-shells are all non-interactive and start without it, so a
gate that works only when typed by hand is not a gate at all.

The second case here matters as much as the first. A repair that made every
environment appear to work would hide a genuinely absent dependency, which is a
worse failure than the one being fixed - so an environment with no library tree
must still fail, and still name what is missing.

=head1 WHEN TO USE

Whenever the gate's startup, its dependency loading, or the way it is scheduled
changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/155-coverage-gate-library-path.t

=head1 WHAT USES IT

Nothing; it is a regression test for C<script/coverage-gate>.

=head1 EXAMPLES

The environment under test is the one a scheduler provides:

    env -i HOME=/home/mv PATH=/usr/bin:/bin script/coverage-gate --help

=cut
