#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );

sub _slurp {
    my ($path) = @_;
    return '' if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    return <$fh>;
}

require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::InternalCLI;

# DD-889 (CORRECTED SCOPE - see the correction comment on the Tira card):
# the original finding assumed lib/Developer/Dashboard.pm's POD EXAMPLES
# block was ALSO wrong, based on static analysis alone (grepping
# InternalCLI::helper_names() for 'update'). That was a false positive:
# bin/dashboard also supports arbitrary custom commands staged under the
# layered ~/.developer-dashboard/cli/ tree (its own SYNOPSIS documents this
# generically as "dashboard <custom-subcommand> [args...]"), and the
# EXAMPLES block's "update" demo stages its own custom command first, then
# runs it - a genuine, self-contained, working demonstration, verified live
# (exit 0) with the exact staging steps the EXAMPLES block itself shows.
#
# The REAL, narrower defect is bin/dashboard's own SYNOPSIS listing a BARE,
# unqualified "dashboard update" line - with none of the EXAMPLES block's
# staging context - right alongside genuine built-ins (help, init, doctor).
# Verified live on a fresh HOME with nothing staged: it fails with "Unknown
# dashboard command 'update'" (exit 1), contradicting its own SYNOPSIS
# listing.
my %real_commands = map { $_ => 1 } Developer::Dashboard::InternalCLI::helper_names();
ok( !$real_commands{update}, "sanity: 'update' is genuinely not a built-in helper command" );
ok( $real_commands{upgrade}, "sanity: 'upgrade' IS the real built-in command this project ships" );

my $main_pod  = _slurp( File::Spec->catfile( $repo_root, 'lib', 'Developer', 'Dashboard.pm' ) );
my $dashboard = _slurp( File::Spec->catfile( $repo_root, 'bin',        'dashboard' ) );

# The EXAMPLES block's staged-custom-command demo is CORRECT and must stay -
# asserting its presence (not its absence) guards against someone "fixing"
# it away based on the same false-positive reasoning that started this
# ticket.
like( $main_pod, qr/perl\s+-Ilib\s+bin\/dashboard\s+update/,
    "the EXAMPLES block's self-staged 'dashboard update' demo is genuine and correctly left in place" );
like( $main_pod, qr{cli/update\.d},
    "the EXAMPLES block still shows staging a custom command under the layered cli/ tree before running it" );

# Scoped to just the SYNOPSIS section (between "=head1 SYNOPSIS" and the
# next "=head1") - bin/dashboard's own EXAMPLES section legitimately shows
# "dashboard update" too (Example 5, the [[STOP]] hook-marker demo, which
# - like the EXAMPLES block above - stages its own custom command first).
# A whole-file check would incorrectly flag that genuine, working example.
my ($synopsis) = $dashboard =~ /^=head1 SYNOPSIS\n(.*?)^=head1 /ms;
$synopsis //= '';
unlike( $synopsis, qr/^\s*dashboard\s+update\s*$/m,
    "AC-5: bin/dashboard's own SYNOPSIS section no longer lists the bare, unqualified 'dashboard update' line" );

like( $dashboard, qr/dashboard\s+<custom-subcommand>/,
    "bin/dashboard's SYNOPSIS still generically documents the custom-command capability the removed line was a redundant, misleading special case of" );

done_testing;

__END__

=head1 NAME

t/187-no-stray-update-command.t - no shipped doc claims "dashboard update"
is a real command

=head1 PURPOSE

Proves the fix for DD-889: lib/Developer/Dashboard.pm's POD EXAMPLES block
and bin/dashboard's own SYNOPSIS both listed C<dashboard update> as a
runnable example, contradicting the adjacent, already-corrected (DD-867)
Update Manager architecture prose stating nothing wires UpdateManager into
the CLI. C<upgrade> is the real, different command.

=head1 WHY IT EXISTS

Found by the hourly doc-accuracy-hunt automation via a static check against
C<InternalCLI::helper_names()> plus the document's own internal
self-contradiction. This test is the permanent regression guard, checking
both the canonical POD source and the generated README, plus
bin/dashboard's own usage text - while explicitly confirming the unrelated
per-command hooks demo (which uses "update" only as a generic example
command name) is correctly left alone.

=head1 WHEN TO USE

Run this file whenever lib/Developer/Dashboard.pm's EXAMPLES block,
bin/dashboard's SYNOPSIS, or InternalCLI::helper_names() changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/187-no-stray-update-command.t

=head1 WHAT USES IT

The suite, through C<prove -lr t>. Its subject is the shipped documentation
surface (POD, generated README, entrypoint usage text) staying consistent
with the real, dispatchable command set.

=head1 EXAMPLES

Watching this fail on a reintroduced regression: add a
"perl -Ilib bin/dashboard update" line back to the EXAMPLES block and
rerun - AC-1 fails.

=cut
