#!perl -w

use Test;
use IPC::Run3::ProfLogger;
use strict;

my @tests = (
sub {
    ok 1;
},
);

plan tests => 0+@tests;

$_->() for @tests;
