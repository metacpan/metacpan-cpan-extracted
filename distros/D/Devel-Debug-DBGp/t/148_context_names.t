#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl');

command_is(['context_names'], {
    contexts => [
        { id => 0, name => 'Locals' },
        { id => 1, name => 'Globals' },
        { id => 2, name => 'Arguments' },
        { id => 3, name => 'Special' },
    ],
});

done_testing();
