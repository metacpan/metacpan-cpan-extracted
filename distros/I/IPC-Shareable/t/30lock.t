BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..1\n";
}

use strict;
use Carp;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;
my $sv;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

# --- Test locking
my $pid = fork;
defined $pid or die "Cannot fork: $!\n";
if ($pid == 0) {
    # --- Child
    sleep unless $awake;
    tie($sv, 'IPC::Shareable', data => { destroy => 0 })
        or die "child process can't tie \$sv";
    for (0 .. 99) {
        (tied $sv)->shlock;
        ++$sv;
        (tied $sv)->shunlock;
    }
    exit;
} else {
    # --- Parent
    tie($sv, 'IPC::Shareable', data => { create => 'yes', destroy => 'yes' })
        or die "parent process can't tie \$sv";
    $sv = 0;
    kill ALRM => $pid;
    for (0 .. 99) {
        (tied $sv)->shlock;
        ++$sv;
        (tied $sv)->shunlock;
    }
    waitpid($pid, 0);
    $sv == 200 or undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";
}

# --- Done!
exit;
