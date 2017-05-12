BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..11\n";
}

use strict;
use Carp;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my($av, $hv);
my $pid = fork;
defined $pid or die "Cannot fork : $!";
if ($pid == 0) {
    # --- Child
    sleep unless $awake;
    tie($hv, 'IPC::Shareable', 'hash', { destroy => 0 })
	or undef $ok;
    tie($av, 'IPC::Shareable', 'arry', { destroy => 0 })
	or undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($hv eq 'baz');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($av eq 'bong');
    print $ok ? "ok $t\n" : "not ok $t\n";

    $hv = { };
    $av = [ ];

    $hv->{blip}->{blarp} = 'blurp';
    $hv->{flip}->{flop}  = 'flurp';
    $av->[1]->[2] = 'beep';
    $av->[2]->[3] = 'bang';

    ++$t;
    $ok = ($hv->{blip}->{blarp} eq 'blurp');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($hv->{flip}->{flop}  eq 'flurp');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($av->[1]->[2] eq 'beep');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($av->[2]->[3] eq 'bang');
    print $ok ? "ok $t\n" : "not ok $t\n";

    exit;
} else {
    # --- Parent
    tie($hv, 'IPC::Shareable', 'hash', { create => 'yes', destroy => 'yes' })
	or undef $ok;
    tie($av, 'IPC::Shareable', 'arry', { create => 'yes', destroy => 'yes' })
	or undef $ok;
    $hv = 'baz';
    $av = 'bong';
    kill ALRM => $pid;
    waitpid($pid, 0);

    $t += 7; # - Child performed 7 tests
    $ok = ($hv->{blip}->{blarp} eq 'blurp');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($hv->{flip}->{flop} eq 'flurp');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($av->[1]->[2] eq 'beep');
    print $ok ? "ok $t\n" : "not ok $t\n";

    ++$t;
    $ok = ($av->[2]->[3] eq 'bang');
    print $ok ? "ok $t\n" : "not ok $t\n";

    IPC::Shareable->clean_up_all;
}

# --- Done!
exit;
