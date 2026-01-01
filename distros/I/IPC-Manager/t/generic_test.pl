use Test2::V1 -ipP;

use IPC::Manager::Serializer::JSON;

use IPC::Manager qw/ipcm_connect ipcm_spawn/;

note("Using $main::PROTOCOL");

my $guard = ipcm_spawn(protocol => $main::PROTOCOL);
my $info = "$guard";

isa_ok($guard, ['IPC::Manager::Spawn'], "Got a spawn object");
is($info, $guard->info, "Stringifies");
like(
    IPC::Manager::Serializer::JSON->deserialize($info),
    ["IPC::Manager::Client::$main::PROTOCOL", "IPC::Manager::Serializer::JSON", $guard->route],
    "Got a useful info string"
);
note("Info: $info");

my $con1 = ipcm_connect('con1' => $info);
my $con2 = ipcm_connect('con2' => $info);
note("Con: $con1");

isa_ok($con1, ['IPC::Manager::Client'], "Got a connection (con1)");
isa_ok($con2, ['IPC::Manager::Client'], "Got a connection (con2)");

like([$con1->get_messages], [], "No messages");
like([$con2->get_messages], [], "No messages");

$con1->send_message(con2 => {hi   => 'there'});
$con2->send_message(con1 => {ahoy => 'matey'});

like(
    [$con1->get_messages],
    [{
        id      => T(),
        stamp   => T(),
        from    => 'con2',
        to      => 'con1',
        content => {ahoy => 'matey'},
    }],
    "Got message sent from con2 to con1"
);

like(
    [$con2->get_messages],
    [{
        id      => T(),
        stamp   => T(),
        from    => 'con1',
        to      => 'con2',
        content => {hi => 'there'},
    }],
    "Got message sent from con1 to con2"
);

like([$con1->get_messages], [], "No messages");
like([$con2->get_messages], [], "No messages");

$con1->send_message(con2 => "string message!");
like(
    [$con2->get_messages],
    [{
        id      => T(),
        stamp   => T(),
        from    => 'con1',
        to      => 'con2',
        content => "string message!",
    }],
    "Got message sent from con1 to con2"
);



my $con3 = ipcm_connect('con3' => $info);

$con3->broadcast({mass => 'message'});

like(
    [$con1->get_messages],
    [{
        id      => T(),
        stamp   => T(),
        from    => 'con3',
        to      => 'con1',
        content => {mass => 'message'},
    }],
    "Got broadcast (3 -> 1)"
);

like(
    [$con2->get_messages],
    [{
        id      => T(),
        stamp   => T(),
        from    => 'con3',
        to      => 'con2',
        content => {mass => 'message'},
    }],
    "Got broadcast (3 -> 2)"
);

like(
    [$con3->get_messages],
    [],
    "No broadcast (3 -> 3)"
);

$con3->broadcast({mass => 'message2'});
$con3->broadcast({mass => 'message3'});
is([$con1->get_messages], [T(), T()], "Got 2 more");
is([$con2->get_messages], [T(), T()], "Got 2 more");

$con1->send_message(con2 => 'woosh, I am invisible');

my $stats = {};
for my $con ($con1, $con2, $con3) {
    $con->write_stats;
    $stats->{$con->id} = $con->read_stats;
}

is(
    $stats,
    {
        'con1' => {
            'read'  => {'con2' => 1, 'con3' => 3},
            'sent'  => {'con2' => 3},
        },
        'con2' => {
            'read'  => {'con1' => 2, 'con3' => 3},
            'sent'  => {'con1' => 1},
        },
        'con3' => {
            'read'  => {},
            'sent'  => {'con1' => 3, 'con2' => 3},
        }
    },
    "Got expected stats"
);

is(
    warnings { $guard = undef },
    [
        match qr/Messages waiting at disconnect for con2/,
        match qr/Messages sent vs received mismatch:.*1 con2 -> con1/s,
    ],
    "Got warnings"
);
ok(!-e $info, "Info does not exist on the filesystem");

done_testing;

1;
