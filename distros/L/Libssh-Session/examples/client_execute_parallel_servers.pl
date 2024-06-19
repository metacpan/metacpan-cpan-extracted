#!/usr/bin/perl

#
# This script simulates parallel execution of commands
# on several session to potentially different servers
#

use strict;
use warnings;
use Libssh::Session qw(:all);
use Time::HiRes qw (usleep);

my $ssh_host = "127.0.0.1";
my $ssh_port = 22;
my $ssh_user = "libssh";
my $ssh_pass = "centreon";

my $NUM_PARALLEL_CONNECTIONS = 3;

sub print_output_callback {
    my (%options) = @_;

    if ($options{exit} == SSH_ERROR) {
        my $error_msg = $options{error_msg};
        print "== execution failed: $error_msg\n";
        return 0;
    }

    my $rc = $options{exit_code};
    my $stdout = $options{stdout};
    my $stderr = $options{stderr};
    print "=> rc = $rc\n";
    print "=> stdout:\n$stdout";
    print "=> stderr:\n$stderr" if (defined($stderr) && $stderr);
    print '+'x8 . "\n";
    return 1;
}

sub init_session {
    my $session = Libssh::Session->new();
    if ($session->options(host => $ssh_host, port => $ssh_port, user => $ssh_user) != SSH_OK) {
        print $session->error() . "\n";
        exit(1);
    }

    if ($session->connect() != SSH_OK) {
        print $session->error() . "\n";
        exit(1);
    }

    if ($session->auth_publickey_auto() != SSH_AUTH_SUCCESS) {
        if ($session->auth_password(password => $ssh_pass) != SSH_AUTH_SUCCESS) {
            printf("auth issue: %s\n", $session->error(GetErrorSession => 1));
            exit(1);
        }
    }

    return $session;
}

sub init_nsessions {
    my ($num) = @_;
    die "You can't init less than one session." if ($num < 1);

    my @all_sessions = ();
    for (0 .. $num - 1) {
        my $session = init_session();
        push(@all_sessions, $session);
    }
    return @all_sessions;
}

my @all_sessions = init_nsessions($NUM_PARALLEL_CONNECTIONS);
my @all_channels = ();
my %has_returned = ();

my $sleep_seconds = 1;
for my $i (0 .. $#all_sessions) {
    my $session = $all_sessions[$i];
    my $cmd = "sleep $sleep_seconds && ls ~";
    print "== calling non-blocking '$cmd' for session[$i]\n";
    my $channel_id = $session->add_command_internal(
        command => {cmd => $cmd, callback => \&print_output_callback}
    );
    if (!defined($channel_id)) {
        print "== failed to start execution via session[$i]\n";
    }
    my $channel = $session->get_channel(channel_id => $channel_id);
    push(@all_channels, [$channel, $channel_id]);
    $session->set_blocking(blocking => 0);

    $sleep_seconds += 1; # each command will sleep a second longer before calling ls
}

my $max_exec_time_seconds      = $sleep_seconds + 2;
my $max_exec_time_microseconds = $max_exec_time_seconds * 1000000;
my $poll_interval_microseconds = 200000; # 0.2s
my $max_polls = $max_exec_time_microseconds / $poll_interval_microseconds;

my $poll_count = 0;
while(1) {
    # check if timeout exceeded
    if ($poll_count > $max_polls) {
        die sprintf("Parallel calls failed to finish in %s seconds", $max_exec_time_seconds);
    }
    print "== polling channels...\n";
    # check if every channel has already returned
    last if (scalar(keys(%has_returned)) == scalar(@all_sessions));

    # poll all channels again and check if there are any finished executions
    for my $i (0 .. $#all_sessions) {
        next if (exists $has_returned{$i});

        my ($channel, $channel_id) = @{$all_channels[$i]};
        my $session = $all_sessions[$i];
        my $rc = $session->channel_get_exit_status(channel => $channel);
        if ($rc != -1) {
            $has_returned{$i}++;
            print "== session[$i] has finished.\n";
            $session->execute_read_channel(channel_id => $channel_id);
        }
    }
    usleep ($poll_interval_microseconds);
    $poll_count++;
}

print "== all sessions have finished execution\n";
exit(0);
