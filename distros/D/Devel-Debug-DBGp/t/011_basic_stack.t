#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/base.pl'),
            where       => 'main',
            lineno      => '1',
        },
    ],
});

send_command('step_into'); # because of fakeFirstStepInto
send_command('step_into');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/base.pl'),
            where       => 'main',
            lineno      => '3',
        },
    ],
});

done_testing();
