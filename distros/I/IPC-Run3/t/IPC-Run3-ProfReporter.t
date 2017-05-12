#!perl -w

use Test;
use IPC::Run3::ProfReporter;
use strict;

my $p;

my @tests = (
sub {
    $p = IPC::Run3::ProfReporter->new;;
    ok UNIVERSAL::isa( $p, "IPC::Run3::ProfReporter" );
},

sub {
    $p->app_call( [], 0.1 );
    ok $p->get_app_call_time, 0.1;
},

sub {
    $p->app_exit( 1.2 );
    ok $p->get_app_exit_time, 1.2;
},

sub {
    ok $p->get_app_time > 1.09;
},

sub {
    ok $p->get_app_cumulative_time > 1.09;
},

sub {
    $p->run_exit( [], 0.1, 0.2, 0.3, 0.4 );
    ok $p->get_run_call_time, 0.1;
},

sub {
    ok $p->get_sys_call_time, 0.2;
},

);

plan tests => 0+@tests;

$_->() for @tests;
