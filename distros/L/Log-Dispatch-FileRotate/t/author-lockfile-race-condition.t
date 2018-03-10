#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


# test case for regression where the .LCK file was unlinked in DESTROY(),
# allowing multiple processes to enter the critical section at the same time.

use strict;
use warnings;
use Path::Tiny;
use IO::Handle;
use Test::More;

my $pid = fork;
if (!defined $pid) {
    plan skip_all => 'fork() does not work on this platform';
}
elsif ($pid == 0) {
    # child
    exit;
}
else {
    # parent
    waitpid $pid, 0;
}

plan tests => 1;

use Log::Dispatch::FileRotate;

shim_logit_delay();

my $tempdir = Path::Tiny->tempdir;
my $warnings_file = $tempdir->child('warnings.txt')->stringify;

$pid = fork;
if (!defined $pid) {
    die "fork failed: $!\n";
}
if ($pid == 0) {
    run_processes();
    exit;
}
else {
    waitpid($pid, 0);
}

my $output = read_warnings($warnings_file);

is $output, 'got lock:releasing lock:got lock:releasing lock:got lock:releasing lock';

# shim a delay in before logit() so that it will wait for the child process
# to enter the critical section
sub shim_logit_delay {
    no warnings 'redefine';

    my $orig_logit = \&Log::Dispatch::FileRotate::logit;
    *Log::Dispatch::FileRotate::logit = sub {
        sleep 3;
        &$orig_logit(@_);
    };
}

sub run_processes {
    open my $warnfh, '+>', $warnings_file
        or die "Failed to open warnings file: $!";

    $warnfh->autoflush(1);

    $SIG{__WARN__} = sub {
        my $msg = shift;

        # we only want the "got lock" and "exiting" lines
        if ($msg =~ /got lock/ or $msg =~ /releasing/) {
            # strip off dates and pid numbers from front of message
            $msg = substr($msg, 25);
            $msg =~ s/^-?[0-9]+ //;

            # save in the warnings file
            print $warnfh $msg;
        }
    };

    my $file = Log::Dispatch::FileRotate->new(
        filename  => $tempdir->child('test.log')->stringify,
        min_level => 'info',
        DEBUG     => 1);

    my $child1_pid = fork;
    if ($child1_pid == 0) {
        $file->log(level => 'info', message => "first_child\n");
    }
    else {
        sleep 1;
        my $child2_pid = fork;
        if ($child2_pid == 0) {
            $file->log(level => 'info', message => "second_child\n");
        }
        else {
            waitpid($child1_pid, 0);
            $file->log(level => 'info', message => "parent\n");
        }
    }

    delete $SIG{__WARN__};
    close $warnfh;
}

sub read_warnings {
    my $file = shift;

    local $/ = undef;

    open my $fh, '<', $file;

    my $content = <$fh>;

    $content =~ s/[\r\n]+$//s;
    $content =~ s/[\r\n]+/:/sg;

    return $content;
}
