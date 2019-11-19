#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

require Log::ger::App;

subtest "check for known arguments" => sub {
    dies_ok { Log::ger::App->import("foo"=>1) };
};

done_testing;
