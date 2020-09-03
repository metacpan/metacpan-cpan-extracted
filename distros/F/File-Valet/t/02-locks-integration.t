#!/bin/env perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use File::Valet;

my $SHORT_EXPIRATION = $ENV{'PERL_FORCE_SHORT_EXPIRATION_TEST'} || 0;  # set to induce hijacks (for stress-testing)

# This is an integration test, and not appropriate for all environments.
my $tmpdir  = find_temp();
my $dfbin   = find_bin('df');
my $space   = defined($dfbin) ? (`$dfbin -P $tmpdir` =~ /\n[^\s]+\s+\d+\s+\d+\s+(\d+)\s+\d+\%/ ? int($1) : 0) : 0;
my $spc_req = 102400;
$dfbin //= '<undef>';
print STDERR "# tmpdir = $tmpdir\n";
print STDERR "# dfbin  = $dfbin\n";
print STDERR "# space  = $space KB\n";
print STDERR "# env    = $^O\n";
unless ($ENV{'PERL_FORCE_INTEGRATION_TEST'} || ($^O eq 'linux' && $space > $spc_req)) {
    ok 1, "skipping integration tests";
    done_testing();
    exit(0);
}       

my $FILENAME = "$tmpdir/lockee$$";
unlink($FILENAME);
ok !-e $FILENAME, 'clean slate';

# tests for lockafile and unlockafile, unfortunately dependent:
# TODO - test re-entrant locking! putting it off because I want to re-implement re-entrant locking to be less lame.
my $parent_pid = $$;
my @kids;
my $stuff = 'X' x 8192;  # enough blargh to run over the POSIX atomicity guarantee, and off the edge of a cliff
for my $i (1..16) {
    my $kid_pid = fork();
    last unless(defined($kid_pid));  # will make do with what we've got - TODO, be more clever about failed forks
    last unless($kid_pid);  # children don't fork off more children, that's just wrong
    push @kids, $kid_pid if ($kid_pid);
}

if ($parent_pid == $$) {
    # we're the parent, so wait for chilluns to die, eat their corpses, and test the results
    my $n_kids = scalar(@kids);
    ok $n_kids > 1, 'got at least two subprocesses';
    unless($n_kids > 0) { done_testing(); exit(0); }
    print STDERR "# spawned $n_kids child processes\n";
    $| = 1;
    my %child_hash; # keys on child pid to {last_ix, con, rac, hij, wtf, app, mis}
    my $i = 1;
    foreach my $kid_pid (@kids) {
        print STDERR "# waiting on child pid $i/$n_kids ($kid_pid) ...";
        waitpid($kid_pid, 0);
        print STDERR "\n";
        $child_hash{$kid_pid} = {last_ix => -1, mis => 0};
        $i++;
    }
    my $fh;
    unless(open($fh, "<", $FILENAME)) { ok 0, "failed to open $FILENAME: $!"; done_testing(); exit(0); }
    my $success         = 1;
    my $n_records       = 0;
    my $n_contentions   = 0;
    my $n_races         = 0;
    my $n_hijacks       = 0;
    my $n_wtf_errors    = 0;
    my $n_append_errors = 0;
    my $n_malformed     = 0;
    my $n_missed        = 0;
    while(defined(my $buf = <$fh>)) {
        $n_records++;
        chomp($buf);
        my($kid, $tix, $con, $rac, $hij, $wtf, $dur, $app, $st, $ex) = split(/\t/, $buf);
        if (defined($ex) || !defined($st) || $st ne $stuff) {
            $success = 0;
            $n_malformed++;
        } else {
            if ($child_hash{$kid}->{last_ix} != $tix - 1) {
                $child_hash{$kid}->{mis}++;
                $n_missed++;
            }
            $child_hash{$kid}->{last_ix} = $tix;
            $child_hash{$kid}->{con} = $n_contentions;
            $child_hash{$kid}->{rac} = $n_races;
            $child_hash{$kid}->{hij} = $n_hijacks;
            $child_hash{$kid}->{wtf} = $n_wtf_errors;
            $child_hash{$kid}->{app} = $n_append_errors;
        }
    }
    print STDERR "# n_records       = $n_records\n";
    print STDERR "# n_contentions   = $n_contentions\n";
    print STDERR "# n_races         = $n_races\n";
    print STDERR "# n_hijacks       = $n_hijacks\n";
    print STDERR "# n_wtf_errors    = $n_wtf_errors\n";
    print STDERR "# n_append_errors = $n_append_errors\n";
    print STDERR "# n_malformed     = $n_malformed\n";
    print STDERR "# n_missed        = $n_missed\n";
    foreach my $kid (sort {$a <=> $b} keys %child_hash) {
        my $show = 0;
        foreach my $f (qw(con rac hij wtf mis)) { $show = 1 if $child_hash{$kid}->{$f}; }
        next unless($show);
        print STDERR "# child $kid:\n";
        print STDERR "#     contentions   = $child_hash{$kid}->{con}\n";
        print STDERR "#     races         = $child_hash{$kid}->{rac}\n";
        print STDERR "#     hijacks       = $child_hash{$kid}->{hij}\n";
        print STDERR "#     wtf errors    = $child_hash{$kid}->{wtf}\n";
        print STDERR "#     sequence gaps = $child_hash{$kid}->{mis}\n";
    }
    ok $success, "test for overt interleaving of data on contested resource";
    is $n_wtf_errors,    0, "test for IO errors";
    is $n_append_errors, 0, "test for append errors";
    if ($success && !$ENV{'PERL_TEST_SAVE_TEMPS'}) {
        unlink($FILENAME);
    } else {
        print STDERR "# leaving data file for forensics: $FILENAME\n";
    }
}
else {
    # we're a child, so beat up a lockfile like a brat with a mallet
    my $n_contentions   = 0;  # How many times failed to acquire the lock because our siblings kept grabbing it first
    my $n_races         = 0;  # How many times failed to acquire the lock due to exists-then-read race condition
    my $n_hijacks       = 0;  # How many times failed to unlock the lock because a sibling grabbed it out from under us
    my $n_wtf_errors    = 0;
    my $n_append_errors = 0;
    my $lock_duration   = $SHORT_EXPIRATION ? 0.001 : 3;
    my $sleep_duration  = $SHORT_EXPIRATION ? 0.03  : 0.01;
    for my $i (0..99) {
        select(undef, undef, undef, $sleep_duration) if ($i);
        $sleep_duration = 0.01;
        my $success = lockafile($FILENAME, $lock_duration, "test", 1, 0.01);
        if (!$success && $File::Valet::OK    eq 'OK'                         ) { $n_contentions++; next; }
        if (!$success && $File::Valet::ERROR eq 'lockfile racy or unreadable') { $n_races++;       next; }
        if (!$success) { $n_wtf_errors++; next; }
        $success = ap_f($FILENAME, "$$\t$i\t$n_contentions\t$n_races\t$n_hijacks\t$n_wtf_errors\t$lock_duration\t$n_append_errors\t$stuff\n");
        $n_append_errors++ unless ($success);
        $lock_duration  = 3;
        select(undef, undef, undef, $sleep_duration) if ($SHORT_EXPIRATION);
        $SHORT_EXPIRATION = 0;
        $success = unlockafile($FILENAME);
        next if ($success);
        if ($File::Valet::ERROR eq 'lost lock') {
            $n_hijacks++;
        } else {
            $n_wtf_errors++;
        }
    }
    exit(0);
}

done_testing();
exit(0);
