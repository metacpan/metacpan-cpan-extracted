use strict;
use warnings;

use Test::More;

use Devel::Probe;

my $config = {
    actions => [
        { action => 'define', file => "foo", lines => [qw(4 5 6)] },
        { action => 'define', file => "bar", lines => [qw(7 8 9)], type => Devel::Probe::PERMANENT },
        { action => 'define', file => "baz", lines => [10], args => { frobnicate => 'doubletime' }},
    ],
};
Devel::Probe::config($config);
is_deeply(Devel::Probe::dump(), 
    { 
        foo => {
            4 => [Devel::Probe::ONCE],
            5 => [Devel::Probe::ONCE],
            6 => [Devel::Probe::ONCE],
        },
        bar => {
            7 => [Devel::Probe::PERMANENT],
            8 => [Devel::Probe::PERMANENT],
            9 => [Devel::Probe::PERMANENT],
        },
        baz => {
            10 => [Devel::Probe::ONCE, {frobnicate => "doubletime"}],
        },

    },
"dump returned a hash representing the probes in the correct state");

done_testing;
