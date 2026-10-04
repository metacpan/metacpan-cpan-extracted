#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use IO::Select;

use lib 'lib';

use Developer::Dashboard::CLI::OpenFileChooser;

my $PKG = 'Developer::Dashboard::CLI::OpenFileChooser';
my $dir = tempdir( CLEANUP => 1 );

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::OpenFileChooser::_stdin_is_tty = sub { 1 };
    is( Developer::Dashboard::CLI::OpenFileChooser::_stdin_has_pending_input(1), 1, 'a tty STDIN is always treated as ready' );
}

ok( defined Developer::Dashboard::CLI::OpenFileChooser::_stdin_is_tty() || 1, '_stdin_is_tty answers without dying' );

# A real file descriptor whose IO::Select probe blows up falls back to a blocking read.
{
    my $file = File::Spec->catfile( $dir, 'stdin.txt' );
    open my $out, '>', $file or die "Unable to write $file: $!";
    print {$out} "1\n";
    close $out or die "Unable to close $file: $!";

    open my $saved, '<&', \*STDIN or die "Unable to dup STDIN: $!";
    open STDIN, '<', $file or die "Unable to reopen STDIN: $!";

    no warnings 'redefine';
    local *Developer::Dashboard::CLI::OpenFileChooser::_stdin_is_tty = sub { 0 };
    local *IO::Select::can_read = sub { die "select exploded\n" };
    my $got = Developer::Dashboard::CLI::OpenFileChooser::_stdin_has_pending_input(1);

    open STDIN, '<&', $saved or die "Unable to restore STDIN: $!";
    is( $got, 1, 'an IO::Select failure falls back to the ordinary blocking read' );
}

done_testing;

__END__

=pod

=head1 NAME

t/771-cli-openfilechooser-stdin-coverage.t - covers the tty and IO::Select failure paths of the open-file chooser

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It reaches the tty shortcut and the IO::Select failure fallback of the STDIN readiness probe.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/771-cli-openfilechooser-stdin-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/771-cli-openfilechooser-stdin-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/771-cli-openfilechooser-stdin-coverage.t

Confirm the targeted lines are reported as covered.

=cut
