#!perl -w

use Test;
use IPC::Run3::ProfPP;
use strict;

my $p = IPC::Run3::ProfPP->new;

my @tests = (
sub {
    local $SIG{__WARN__} = sub { };

    $p->app_call( [ "parent_prog" ], 1.0 );
    $p->run_exit( [ "child_prog" ], 1.1, 1.2, 1.3, 1.4 );
    $p->app_exit( 1.5 );
    ok 1;
},
);

plan tests => 0+@tests;

$_->() for @tests;
