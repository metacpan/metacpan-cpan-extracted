#!/usr/local/bin/perl

# test lock features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 11;
use Time::HiRes qw(usleep);

use constant TIMEOUT => 1000000;
use constant DELTA_T =>    4000;

my ($var, $myvar);    # the shared variable, local copy

# for child processes in test 11 to insist on their error code
sub err {
    my $errval = shift;
    while (1) {
        $var = $errval;
        usleep(int(DELTA_T/5));
}   }

# test 1 is use_ok
BEGIN {use_ok ('IPC::MMA', qw(:basic :scalar))}

# test 2: create acts OK
my $mm = mm_create (1, '/tmp/test_lockfile');
if (!defined $mm || !$mm) {BAIL_OUT "can't create shared memory"}
ok (1, "create shared mem");

# test 3: create a scalar to talk to each other with
my $scalar = mm_make_scalar($mm);
if (!defined $scalar || !$scalar) {BAIL_OUT "can't create shared scalar"}
ok (1, "make scalar");

# test 4, tie it and initialize it
#  because this says 'MMA', tied operations do not themselves lock
 
if (!tie ($var, 'IPC::MMA::Scalar', $scalar)) {BAIL_OUT "Can't tie scalar"}
ok (1, "tie scalar");
$var = '00';

my ($id, $timer, $w84);
my @pid = ($$, $$, $$, $$);

# test 5: fork into 4 processes in parent, $id = 0, child pids in $pid[1:3]
#                             in children, $id = 1:3
if (!defined ($pid[1] = fork)) {BAIL_OUT("can't fork into 2 processes")}
if ($pid[1]) {
    ok (1, "fork into 2 processes");
    if (!defined ($pid[2] = fork)) {BAIL_OUT("can't fork into 3 processes")}
    if ($pid[2]) {
        # test 6
        ok (1, "fork into 3 processes");
        if (!defined ($pid[3] = fork)) {BAIL_OUT("can't fork into 4 processes")}
        if ($pid[3]) {
            # test 7
            ok (1, "fork into 4 processes");
            $id = 0;
        } else {$id = 3}
    } else {$id = 2}
} else {$id = 1}

# test 8: process 0 sets a RD lock, sets var 1 or 2, others acknowledge 2 by setting 3, 4, 5
if (!$id) {
    $var = mm_lock($mm, MM_LOCK_RD) ? '02' : '01';
    $timer = 0;
    while (($myvar = $var) < 5 && $timer < TIMEOUT) {
        $timer += DELTA_T;
        usleep(DELTA_T);
    }
    cmp_ok ($myvar, '==', 5, "id 0 read lock");
    $var = '05';
} else {
    $w84 = $id+1;
    while (($myvar = $var) < $w84) {usleep(DELTA_T)}
    if ($myvar == $w84) {$var = sprintf ("%02d", $w84+1)}
    while ($var < 5) {usleep(DELTA_T)}
}

# test 9: process 1 sets a RD lock, sets var 7 or 8, others acknowledge 8 by setting 9, 10, 11
if ($id==1) {
    while (($myvar = $var) < 6) {usleep(DELTA_T)}
    if ($myvar == 6) {$var = mm_lock($mm, MM_LOCK_RD) ? '08' : '07'}
    while ($var < 11) {usleep(DELTA_T)}
} elsif (!$id) {
    $var = '06';
    $timer = 0;
    while (($myvar = $var) < 11 && $timer < TIMEOUT) {
        if ($myvar == 8) {$var = '09'}
        $timer += DELTA_T;
        usleep(DELTA_T);
    }
    is ($myvar, 11, "id 1 read lock");
    $var = 11;
} else {
    $w84 = $id+7;
    while (($myvar = $var) < $w84) {usleep(DELTA_T)}
    if ($myvar == $w84) {$var = $w84+1}
    while ($var < 11) {usleep(DELTA_T)}
}

# test 10: process 2 sets a RD lock, sets var 13-14, others ack 14 by setting 15, 16, 17
if ($id == 2) {
    while (($myvar = $var) < 12) {usleep(DELTA_T)}
    if ($myvar == 12) {$var = mm_lock($mm, MM_LOCK_RD) ? 14 : 13}
    while ($var < 17) {usleep(DELTA_T)}
} elsif (!$id) {
    $var = 12;
    $timer = 0;
    while (($myvar = $var) < 17 && $timer < TIMEOUT) {
        if ($myvar == 14) {$var = 15}
        $timer += DELTA_T;
        usleep(DELTA_T);
    }
    is ($myvar, 17, "id 2 read lock");
    $var = 17;
} else {
    $w84 = $id==1 ? 15 : 16;
    while (($myvar = $var) < $w84) {usleep(DELTA_T)}
    if ($myvar == $w84) {$var = $w84+1}
    while ($var < 17) {usleep(DELTA_T)}
}

# test 11: upgrading a RD lock to RW
# at the start, processes 0, 1, 2 have read locks

if ($id==1) {
    # when process 1 sees process 0 set var to 18,
    #  it sets var to 19 then requests
    #  an upgrade of its RD lock to RW
    while (($myvar = $var) < 18) {usleep(DELTA_T)}
    if ($myvar == 18) {
        $var = 19;
        if (!mm_lock ($mm, MM_LOCK_RW)) {err 97}
        # when 1 gets its write lock, 3 has gotten its read lock and then
        #  released it, but there's the theoretical possibility that 3 is
        #  still waiting for its read lock
        while (($myvar = $var) < 22) {usleep(DELTA_T)}
        if ($myvar == 22) {
            $var = 24;
            if(!mm_unlock($mm)) {err 91}
        } elsif ($myvar == 23) {
            $var = 26;
            if(!mm_unlock($mm)) {err 91}
    }   }

} elsif ($id==2) {
    # process 2: when it sees 21 it releases its read lock and
    # advances to 22
    while (($myvar = $var) < 21) {usleep(DELTA_T)}
    if ($myvar == 21) {
        $var = mm_unlock($mm) ? 22 : 92;
    }
    
} elsif ($id==3) {
    # a short while after process 3 (which has no lock at all) sees 19,
    #  sets 20 and requests a read lock (1 will have gotten its write
    #  lock by then)
    while (($myvar = $var) < 19) {usleep(DELTA_T)}
    if ($myvar == 19) {
        usleep(DELTA_T<<2);  # make sure #1 has requested its lock and is waiting
        $var = 20;
        if (!mm_lock($mm, MM_LOCK_RD)) {err 98}
        # when 3 gets its read lock, 1 is still waiting for its write lock,
        #   though there's the theoretical possibility that 1 has gotten
        #   its write lock and then released it
        while (($myvar = $var) < 22) {usleep(DELTA_T)}
        if ($myvar == 22) {
            $var = 23;
            if (!mm_unlock($mm)) {err 93}
        } elsif ($myvar == 24) {
            $var = 25;
            if (!mm_unlock($mm)) {err 93}
    }   }

} else {
    # when process 0 sees 20, it releases its read lock and
    #  advances to 21
    # then it continues to wait until a timeout, or it sees one of
    #  the terminating values
    $var = 18;
    $timer = 0;
    while (($myvar = $var) < 25 && $timer < TIMEOUT) {
        if ($myvar == 20) {
            if (mm_unlock($mm)) {$var = 21}
            else {
                $var = 90;
                usleep(DELTA_T<<4);  # let other activity settle
                $var = $myvar = 90;
                last;
        }   }
        # the while and if comparisons above take a significant number of uS
        #  so if TIMEOUT is to approximate real time, this delay has to be mS
        $timer += DELTA_T;
        usleep(DELTA_T);
    }
    # if timeout, test for other processes still around
    my $st='';
    if ($timer >= TIMEOUT
     && $myvar < 90) {
        for (my $i=1; $i<=3; $i++) {
            if (kill 0, $pid[$i]) {
                $st .= $st ? ", $i" : $i;
    }   }   }

    # create final result message
    my $mes = $myvar==97 ? "id 1 couldn't upgrade read to write lock"
            : $myvar==98 ? "id 3 couldn't get read lock"
            : $myvar>=90 ? "id ".($myvar-90)." couldn't unlock"
            : $myvar< 25 ? "state got stuck at $myvar"
            : "id 1 write lock "
            . ($myvar == 25 ? "was granted before a later id 3 read lock"
                            : "had to wait for a later id 3 read lock");

    # report the test result (2 results are OK)
    ok ($myvar == 25 || $myvar == 26, "$mes: " . ($st ? "process $st still alive" 
                                                      : "timer=$timer of ".TIMEOUT));

    kill 9, $pid[1], $pid[2], $pid[3];
    mm_destroy ($mm);
}
# success on test 11 means that a process can upgrade a read lock
#   to a write lock without first releasing the read lock
#   but online words say this upgrade is subject to an interloper
#   (which is indicated by a 'had to wait for a later' message)
