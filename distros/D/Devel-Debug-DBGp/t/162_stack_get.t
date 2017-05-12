#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/stack.pl');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 7,
        },
    ],
});

command_is(['stack_get', '-d', 1], {
    apperr  => 4,
    code    => 301,
    message => 'Invalid stack depth arg of \'1\'',
    command => 'stack_get',
});

send_command('run')
    for 1 .. 6;

command_is(['stack_get'], {
    frames => [
        (map +{
            level       => $_,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main::fact',
            lineno      => 4,
        }, 0 .. 4),
        {
            level       => 5,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 9,
        },
    ],
});

command_is(['stack_get', '-d', 2], {
    frames => [
        {
            level       => 2,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main::fact',
            lineno      => 4,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'eval {...}',
            lineno      => 16,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

send_command('run');

my $eval_frames = send_command('stack_get');
my $eval_file = $eval_frames->frames->[0]->filename;

like($eval_file, qr{^dbgp://perl/[^/]+/\d+/1/%28eval%20\d+%29});

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'eval',
            filename    => $eval_file,
            where       => "eval '...'",
            lineno      => 3,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'eval {...}',
            lineno      => 16,
        },
        {
            level       => 2,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

command_is(['stack_get', '-d', 0], {
    frames => [
        {
            level       => 0,
            type        => 'eval',
            filename    => $eval_file,
            where       => "eval '...'",
            lineno      => 3,
        },
    ],
});

command_is(['stack_get', '-d', 1], {
    frames => [
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'eval {...}',
            lineno      => 16,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/break.pm'),
            where       => "require 't/scripts/break.pm'",
            lineno      => 5,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 25,
        },
    ],
});

command_is(['stack_get', '-d', 0], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/break.pm'),
            where       => "require 't/scripts/break.pm'",
            lineno      => 5,
        },
    ],
});

command_is(['stack_get', '-d', 1], {
    frames => [
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 25,
        },
    ],
});


command_is(['stack_get', '-d', 2], {
    apperr  => 4,
    code    => 301,
    message => 'Invalid stack depth arg of \'2\'',
    command => 'stack_get',
});

done_testing();
