#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/function_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'call', '-m', 'main::sub_break'], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'call', '-m', 'bar::sub_break'], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_set', '-t', 'return', '-m', 'main::return_break'], {
    state       => 'enabled',
    id          => 2,
});

command_is(['breakpoint_set', '-t', 'call', '-m', 'moo'], {
    apperr      => 4,
    code        => 205,
    message     => "Currently can\'t find sub moo in any loaded file.",
    command     => 'breakpoint_set',
});

breakpoint_list_is([
    {
        id          => 0,
        type        => 'call',
        state       => 'enabled',
        function    => 'main::sub_break',
    },
    {
        id          => 1,
        type        => 'call',
        state       => 'enabled',
        function    => 'bar::sub_break',
    },
    {
        id          => 2,
        type        => 'return',
        state       => 'enabled',
        function    => 'main::return_break',
    },
]);

command_is(['breakpoint_get', '-d', 1], {
    breakpoint => {
        id          => 1,
        type        => 'call',
        state       => 'enabled',
        function    => 'bar::sub_break',
    },
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/function_breakpoint.pl'),
            where       => 'main::sub_break',
            lineno      => '10',
        },
    ],
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/function_breakpoint.pl'),
            where       => 'main',
            lineno      => '26',
        },
    ],
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            where       => 'bar::sub_break',
            lineno      => '2',
        },
    ],
});

# not an error
isa_ok(send_command('breakpoint_remove', '-d', 1), 'DBGp::Client::Response::BreakpointGetUpdateRemove');

breakpoint_list_is([
    {
        id          => 0,
        type        => 'call',
        state       => 'enabled',
        function    => 'main::sub_break',
    },
    {
        id          => 2,
        type        => 'return',
        state       => 'enabled',
        function    => 'main::return_break',
    },
]);

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            where       => 'main::sub_break',
            lineno      => '10',
        },
    ],
});

done_testing();
