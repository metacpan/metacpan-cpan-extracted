#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Output ();

package My::P1;
use Log::ger::Heavy;
{
    local $Log::ger::Default_Hooks{create_formatter} = [];
    Log::ger->import;
}

sub x {
    log_warn({a=>1, b=>2});
}

package My::P2;
use Log::ger;

sub x {
    log_warn({a=>3, b=>4}, "");
}

package main;

subtest "basics" => sub {
    my $ary = [];
    Log::ger::Output->set('Array', array => $ary);
    My::P1::x();
    is_deeply($ary, [{a=>1, b=>2}]);

    splice @$ary;
    My::P2::x();
    ok(!ref($ary->[0])) or diag explain $ary;
    like($ary->[0], qr/^HASH/);
};

done_testing;
