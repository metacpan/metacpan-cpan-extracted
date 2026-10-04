#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Cwd qw(getcwd);

BEGIN { use_ok('Developer::Dashboard::CommandRunner') or BAIL_OUT('CommandRunner module failed to load'); }

my $M = 'Developer::Dashboard::CommandRunner';

# DD-947: every one of the 10 functions extracted from CollectorRunner.pm's
# command-execution cluster must exist as a real, plain (no $self) callable
# sub on this new module - the mechanical proof the extraction actually
# happened, distinct from CollectorRunner's own forwarders still passing
# (verified separately by the full existing suite, per this ticket's AC-2).
for my $name (
    qw(
    run_command
    await_windows_command
    spawn_windows_command
    record_command_pid
    command_launcher_argv
    command_pid_from_file
    await_command_pid
    forward_command_signal
    terminate_command_process
    exit_code_from_status
    )
  )
{
    ok( $M->can($name), "$M defines $name" );
}

subtest 'exit_code_from_status: pure function, no $self, real behaviour' => sub {
    is( Developer::Dashboard::CommandRunner::exit_code_from_status(0),    0,   'clean exit 0' );
    is( Developer::Dashboard::CommandRunner::exit_code_from_status(256),  1,   'exit 1 (256 >> 8)' );
    is( Developer::Dashboard::CommandRunner::exit_code_from_status(9),    137, 'killed by signal 9 -> 128+9' );
    is( Developer::Dashboard::CommandRunner::exit_code_from_status(undef), 0,  'undef status treated as 0' );
};

subtest 'command_pid_from_file: real file I/O, no $self' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $missing = File::Spec->catfile( $dir, 'none.pid' );
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($missing), undef, 'missing file yields undef' );

    my $valid = File::Spec->catfile( $dir, 'valid.pid' );
    open my $fh, '>', $valid or die $!;
    print {$fh} '4242';
    close $fh;
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($valid), 4242, 'valid pid file parses' );

    my $garbage = File::Spec->catfile( $dir, 'garbage.pid' );
    open my $gfh, '>', $garbage or die $!;
    print {$gfh} 'not-a-pid';
    close $gfh;
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($garbage), undef, 'non-numeric content yields undef' );

    my $unreadable = File::Spec->catfile( $dir, 'unreadable.pid' );
    open my $ufh, '>', $unreadable or die "Unable to write $unreadable: $!";
    print {$ufh} '4242';
    close $ufh or die "Unable to close $unreadable: $!";
    SKIP: {
        chmod 0000, $unreadable or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $unreadable ) {
            close $probe or die "Unable to close permission probe for $unreadable: $!";
            chmod 0600, $unreadable or die "Unable to restore $unreadable: $!";
            skip 'this process can read a mode-0000 pid file, so the open failure cannot occur', 1;
        }
        ok( !defined Developer::Dashboard::CommandRunner::command_pid_from_file($unreadable), 'unreadable pid files yield no command pid' );
        chmod 0600, $unreadable or die "Unable to restore $unreadable: $!";
    }
};

subtest 'record_command_pid then command_pid_from_file round-trip' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $pidfile = File::Spec->catfile( $dir, 'roundtrip.pid' );
    Developer::Dashboard::CommandRunner::record_command_pid( $pidfile, 9999 );
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($pidfile), 9999, 'round-trips through the real pid-file contract' );
};

subtest 'command_launcher_argv: builds a real launcher argv' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $pidfile = File::Spec->catfile( $dir, 'launcher.pid' );
    my @argv = Developer::Dashboard::CommandRunner::command_launcher_argv( $pidfile, $^X, '-e', 'print "hi"' );
    is( $argv[0], $^X, 'launcher argv starts with the current perl' );
    ok( ( grep { $_ eq '-e' } @argv ), 'launcher argv carries -e' );
    ok( ( grep { $_ eq $pidfile } @argv ), 'launcher argv carries the pidfile path' );
};

subtest 'run_command: a real, short, successful command' => sub {
    my $cwd = getcwd();
    my ( $stdout, $stderr, $exit, $timed_out ) = Developer::Dashboard::CommandRunner::run_command(
        source     => qq{$^X -e "print 'DD947-OK'"},
        cwd        => $cwd,
        env        => {},
        timeout_ms => 5000,
    );
    like( $stdout, qr/DD947-OK/, 'run_command captures real stdout from a real spawned process' );
    is( $exit, 0, 'clean exit code' );
    is( $timed_out, 0, 'not marked timed out' );
};

subtest 'run_command: a non-empty env hash is exported into the spawned process' => sub {
    my $cwd = getcwd();
    my ( $stdout, $stderr, $exit, $timed_out ) = Developer::Dashboard::CommandRunner::run_command(
        source     => qq{$^X -e 'print \$ENV{DD947_ENV_PROBE}'},
        cwd        => $cwd,
        env        => { DD947_ENV_PROBE => 'dd947-env-value' },
        timeout_ms => 5000,
    );
    like( $stdout, qr/dd947-env-value/, 'a real, non-empty env hash reaches the spawned command' );
    is( $exit, 0, 'clean exit code' );
};

done_testing();

__END__

=head1 NAME

t/199-commandrunner-coverage.t

=head1 PURPOSE

Proves lib/Developer/Dashboard/CommandRunner.pm - the command-execution
cluster extracted from CollectorRunner.pm by DD-947 - exists, is callable
as plain functions with no $self, and behaves identically to the original
methods it replaced.

=head1 WHY IT EXISTS

DD-947 moved run_command/await_windows_command/spawn_windows_command/
record_command_pid/command_launcher_argv/command_pid_from_file/
await_command_pid/forward_command_signal/terminate_command_process/
exit_code_from_status out of CollectorRunner.pm into their own module,
confirmed to have zero instance-state ($self->{...}) dependency. This test
proves the new module itself works correctly in isolation; the full
existing suite (t/103, t/115, t/122, t/53, etc, unchanged) proves
CollectorRunner's own one-line forwarders still delegate correctly.

=head1 WHEN TO USE

Run as part of the full suite, or directly when changing anything in
CommandRunner.pm.

=head1 HOW TO USE

C<PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/199-commandrunner-coverage.t>

=head1 WHAT USES IT

Verifies lib/Developer/Dashboard/CommandRunner.pm.

=head1 EXAMPLES

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/199-commandrunner-coverage.t

=cut
