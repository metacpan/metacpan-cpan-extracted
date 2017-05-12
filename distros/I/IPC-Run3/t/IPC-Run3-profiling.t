#!perl -w

BEGIN {
    $ENV{IPCRUN3PROFILE} = "IPC::Run3::ProfArrayBuffer=";
}

use strict;
use IPC::Run3;
use Test;

my @tests = (
sub {
    run3 [$^X, '-e1' ];
    ## no app_exit call is expected because the app (ie this script)
    ## has not not exited quite yet.
    ok scalar IPC::Run3::_profiler()->get_events, 2;
},

);

plan tests => 0+@tests;

$_->() for @tests;
