#!perl -w

use Test;
use IPC::Run3::ProfLogReader;
use IPC::Run3::ProfArrayBuffer;
use strict;

my $h = IPC::Run3::ProfArrayBuffer->new;

my $r = IPC::Run3::ProfLogReader->new(
    Source  => \*DATA,
    Handler => $h,
);

my @tests = (
sub {
    ok $r->read;
},

sub {
    ok $r->read_all;
},

sub {
    ok 0+$h->get_events, 3, "events read";
},

sub {
    ok( ($h->get_events)[1]->[1]->[1], "there fella" );
},

);

plan tests => 0+@tests;

$_->() for @tests;

__DATA__
\app_call 1.0
hi there\_fella 1.1,1.2,1.3,1.4
\app_exit 1.5

