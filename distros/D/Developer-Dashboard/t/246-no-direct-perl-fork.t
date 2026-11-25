#!/usr/bin/env perl

use strict;
use warnings;

use File::Find qw(find);
use File::Spec;
use Test::More;

my @source_files;
find(
    {
        no_chdir => 1,
        wanted   => sub {
            return unless -f $_;
            return unless /\.(?:pm|pl|t)\z/;
            return if /(?:^|[\\\/])246-no-direct-perl-fork\.t\z/;
            push @source_files, $_;
        },
    },
    qw(lib t),
);

my @fork_calls;
for my $path ( sort @source_files ) {
    open my $source_fh, '<', $path
      or die "Unable to read Perl source '$path': $!";
    my $line_number = 0;
    my $in_pod = 0;
    while ( my $line = <$source_fh> ) {
        ++$line_number;
        last if $line =~ /^__END__\b/;
        if ( $line =~ /^=(?:pod|head\d|over|item|back|begin|for|encoding)\b/ ) {
            $in_pod = 1;
            next;
        }
        if ( $in_pod ) {
            $in_pod = 0 if $line =~ /^=cut\b/;
            next;
        }
        next if $line =~ /^\s*#/;
        $line =~ s/(?:'[^'\\]*(?:\\.[^'\\]*)*'|"[^"\\]*(?:\\.[^"\\]*)*")//g;
        $line =~ s/#.*\z//;
        push @fork_calls, "$path:$line_number"
          if $line =~ /(?<![\w:])(?:CORE::)?fork(?:\s*\(\s*\)|(?=\s*;))/;
    }
    close $source_fh or die "Unable to close Perl source '$path': $!";
}

is_deeply( \@fork_calls, [], 'no direct Perl fork calls remain in lib or tests' )
  or diag "Remaining call sites:\n  " . join( "\n  ", @fork_calls );

my %stale_fork_claims = (
    'lib/Developer/Dashboard/CollectorRunner.pm' => qr/
        newly\ forked\ collector\ pid
        |start_loop\ fork\ a\ duplicate
        |before\ any\ fork
        |fork-timing\ risk
        |parent\ records\ the\ forked\ pid
        |fork\ another\ loop
        |freshly\ forked\ child
    /ix,
    't/153-collector-loop-accumulation.t' => qr/start_loop\ is\ a\ plain\ fork/i,
    't/lib/Local/CollectorFixture.pm' => qr/
        forked\ fixture\ child
        |after\ the\ fork
        |fork\ the\ child
        |forks\ a\ stand-in
    /ix,
);

for my $path ( sort keys %stale_fork_claims ) {
    open my $source_fh, '<', $path
      or die "Unable to read Perl source '$path': $!";
    local $/;
    my $source = <$source_fh>;
    close $source_fh or die "Unable to close Perl source '$path': $!";
    unlike( $source, $stale_fork_claims{$path}, "$path does not describe migrated process launch as Perl fork" );
}

done_testing;

__END__

=head1 NAME

t/246-no-direct-perl-fork.t - enforce GoRoutine process migration

=head1 PURPOSE

Scans repository-owned Perl modules, scripts and tests for executable direct
C<fork()> calls. The migration target is GoRoutine's native routine or process
API, selected according to whether the behavior needs a thread or an OS
process.

=head1 WHY IT EXISTS

This project must not retain platform-specific direct Perl C<fork()> paths
after integrating GoRoutine. A source-level guard makes that requirement
visible in ordinary test runs rather than relying on a manual search.

=head1 WHEN TO USE

Run after changing asynchronous runtime code, subprocess helpers, test
fixtures, or GoRoutine integration. Any reported location must be migrated
without weakening the behavior assertions in its surrounding test.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/246-no-direct-perl-fork.t

The scanner visits Perl files under C<lib/> and C<t/>, ignores full-line
comments and POD/documentation after C<__END__>, and masks simple quoted
strings before checking for call syntax. It reports every source location in
one failing assertion. Separate assertions also reject obsolete fork-based
descriptions in the collector supervisor and its process-backed test fixture,
so comments and POD cannot continue documenting the removed launch path.

=head1 WHAT USES IT

The distribution's test harness runs this guard as part of its normal suite.
It complements lifecycle-specific parity tests; it does not prove process
semantics by itself.

=head1 EXAMPLES

Run the source guard in Docker:

  d2 docker compose exec dev prove -lv t/246-no-direct-perl-fork.t

Run it with the current process integration contracts:

  d2 docker compose exec dev prove -lv t/232-goroutine-process.t t/246-no-direct-perl-fork.t

=cut
