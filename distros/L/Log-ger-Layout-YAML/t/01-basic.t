#!perl

use strict;
use warnings;
use Test::More 0.98;

use JSON::MaybeXS;
use Log::ger::Layout ();

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;

package My::P1;
use Log::ger;

sub x {
    log_warn("warnmsg");
}

package My::P2;
use Log::ger::Format;
Log::ger::Format->set_for_current_package('None');
use Log::ger;

sub x {
    log_warn({k1=>'v1', k2=>'v2', foo=>'bar'});
}

package main;

subtest "basics (with default formatter)" => sub {
    Log::ger::Layout->set(YAML => ());
    splice @$ary;
    My::P1::x();
    is_deeply($ary, [qq(---\nmessage: warnmsg\n)]);
};

subtest "basics (with None formatter)" => sub {
    Log::ger::Layout->set(YAML => ());
    splice @$ary;
    My::P2::x();
    is_deeply($ary, [qq(---\nfoo: bar\nk1: v1\nk2: v2\n)]);
};

# more tests on LGL:LTSV

done_testing;
