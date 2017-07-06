#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Output ();

package My::P1;
use Log::ger::Format 'None';
use Log::ger;

sub x {
    log_warn({a=>1, b=>2});
}

package main;

subtest "basics" => sub {
    my $ary = [];
    Log::ger::Output->set('Array', array => $ary);
    My::P1::x();
    is_deeply($ary, [{a=>1, b=>2}]);
};

done_testing;
