# Test of asynchronous hash access courtesy of Tim Fries <timf@dicecorp.com>

BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..5\n";
}

use strict;
use Carp;
use IPC::Shareable;

my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $ppid = $$;
my $pid = fork;
defined $pid or die "Cannot fork : $!";
if ($pid == 0) {
    # --- Child
    sleep unless $awake;
    $awake = 0;

    ++$t;
    my %thash = ();
    tie(%thash, 'IPC::Shareable', 'hobj', { destroy => 0 })
       or undef $ok;    
    print $ok ? "ok $t\n" : "not ok $t\n";

    $thash{'foo'} = "marlinspike";
    $thash{'bar'} = "ballyhoo";
    $thash{'quux'} = "calvinball";

    kill ALRM => $ppid;
    sleep unless $awake;
    ++$t;

    $ok = (defined $thash{'foo'} && $thash{'foo'} eq "marlinspike");
    print $ok ? "ok $t\n" : "not ok $t\n";
    ++$t;

    $ok = (defined $thash{'bar'} && $thash{'bar'} eq "ballyhoo");
    print $ok ? "ok $t\n" : "not ok $t\n";
    ++$t;

    $ok = (defined $thash{'quux'} && $thash{'quux'} eq "calvinball");
    print $ok ? "ok $t\n" : "not ok $t\n";
    ++$t;

    exit;

} else {
    # --- Parent
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };
    my %thash = ();
    tie(%thash, 'IPC::Shareable', 'hobj', { create => 'yes' })
       or undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";
    ++$t;

    kill ALRM => $pid;
    sleep unless $awake;
 
    ++$t;
    $thash{'intel'} = "expensive";
    $thash{'amd'} = "volthungry";
    $thash{'cyrix'} = "mia";
   
    kill ALRM => $pid;
    waitpid($pid, 0);
  
    IPC::Shareable->clean_up_all;
}

# --- Done!
exit;
