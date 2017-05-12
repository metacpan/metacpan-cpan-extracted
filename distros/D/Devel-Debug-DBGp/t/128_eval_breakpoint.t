#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/eval_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'call', '-m', 'main::foo'], {
    state       => 'enabled',
    id          => 0,
});

send_command('run');

my $eval_frames = send_command('stack_get', '-d', 0);
my $eval_url = $eval_frames->frames->[0]->filename;

# sanity check
like($eval_url, qr{^dbgp://perl/[^/]+/\d+/1/%28eval%20\d+%29});

command_is(['breakpoint_remove', '-d', 0], {
});

command_is(['breakpoint_set', '-t', 'line', '-f', $eval_url, '-n', 4], {
    state       => 'enabled',
    id          => 1,
});

breakpoint_list_is([
    {
        id              => 1,
        type            => 'line',
        state           => 'enabled',
        filename        => $eval_url,
        lineno          => '4',
    },
]);

send_command('run');
send_command('run');

command_is(['stack_get'], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => $eval_url,
            where       => 'main::foo',
            lineno      => '4',
        },
        {
            level       => '1',
            type        => 'file',
            filename    => abs_uri('t/scripts/eval_breakpoint.pl'),
            where       => 'main',
            lineno      => '10',
        },
    ],
});

done_testing();
