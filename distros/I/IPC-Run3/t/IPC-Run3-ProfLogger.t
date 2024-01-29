#!perl
use strict;
use warnings;

use Test;
use IPC::Run3::ProfLogger;

my @tests = (
sub {
    ok 1;
},
);

plan tests => 0+@tests;

$_->() for @tests;
