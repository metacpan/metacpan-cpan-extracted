use strict;
use utf8;

use Test::More;

use Event::RPC::Server;
use Event::RPC::Message::Negotiate;

my $depend_modules = 0;
eval { require EV };
eval { require AnyEvent } && ++$depend_modules;
eval { require Event    } && ++$depend_modules;
eval { require Glib     } && ++$depend_modules;

if ( not $depend_modules ) {
    plan skip_all => "Neither AnyEvent, Event nor Glib installed";
}

require "t/Event_RPC_Test_Server.pm";
my $PORT = Event_RPC_Test_Server->port;

# determine available message formats (including the insecure)
my $formats = Event::RPC::Server->probe_message_formats(
    Event::RPC::Message::Negotiate->message_format_order, 1
);

my $modules_by_name = Event::RPC::Message::Negotiate->known_message_formats;

my $tests = 1 + @{$formats} * 14 + 9 * 3;

plan tests => $tests;

# load client class
use_ok('Event::RPC::Client');

foreach my $format ( @{$formats} ) {
    # start server in background, without logging
    my $server_pid = Event_RPC_Test_Server->start_server (
        p => $PORT,
        S => 1,
        L => $ENV{EVENT_RPC_LOOP},
        f => [ $format ]
    );

    ok($server_pid, "Started server at $server_pid with format '$format'");

    # create client instance
    my $client = Event::RPC::Client->new (
        host    => "localhost",
        port    => $PORT,
    );

    # connect to server
    $client->connect;
    ok(1, "connected");

    # check message format
    ok($client->get_message_format eq $modules_by_name->{$format}, "$format format chosen");

    # create instance of test class over RPC
    my $data = "Some test data with utf8: 你好世界. " x 6;
    my $object = Event_RPC_Test->new (
        data => $data
    );

    # check object
    ok($object->isa("Event_RPC_Test"), "object is Event_RPC_Test");

    # check data
    ok($object->get_data eq $data, "object data matches");

    # set binary data
    my $bin_data = join("", map { chr($_) } 0..255);
    $bin_data = $bin_data x 100;

    ok($object->set_data($bin_data) eq $bin_data, "object bin data set");
    ok($object->get_data eq $bin_data, "object bin data get");

    # get another object from this object
    my $object2 = $object->get_object2;
    ok($object2->isa("Event_RPC_Test2"), "object is Event_RPC_Test2");

    # check data of object2
    ok($object2->get_data eq 'foo', "object data is 'foo'");

    # create another object from this object
    $object2 = $object->new_object2($$);
    ok($object2->isa("Event_RPC_Test2"), "object is Event_RPC_Test2");

    # check data of object2
    ok($object2->get_data == $$, "object data is $$");
    $object2->set_data($data);

    # check if copying the complete object hash works
    my $ref = $object2->get_object_copy;
    ok($ref->{data} eq $data, "object copy data matches");

    if ( $ENV{EVENT_RPC_BENCHMARK} ) {
        require Benchmark;

        my @objects;
        my @payload = map { $_ => ("Huge payload $_" x 100) } 1..100; 

        diag "Performing benchmark for '$format'";

        my $cnt = 20;
        my $t = Benchmark::timeit($cnt, sub {               
            for ( 1..1000 ) {
                push @objects, $object->new_object2(\@payload);
            }
            $_->set_data(42) for @objects;
            @objects = ();
        });

        diag "$cnt loops of '$format' took ".Benchmark::timestr($t);
    }

    # disconnect client
    ok ($client->disconnect, "client disconnected");

    # wait on server to quit
    wait;
    ok (1, "server stopped");
}

SKIP: {
    my ($other_format) = grep { $_ ne "STOR" } @{$formats};
    my ($has_storable) = grep { $_ eq "STOR" } @{$formats};

    plan skip "Negotations tests skipped due to missing formats", 9*3
        unless $other_format and $has_storable;

    foreach my $client_style (qw/ old insecure secure /) {
        foreach my $server_style (qw/ old insecure secure /) {
            if ( $client_style eq 'old' ) {
                $Event::RPC::Client::DEFAULT_MESSAGE_FORMAT = "Event::RPC::Message::Storable";
            }
            else {
                $Event::RPC::Client::DEFAULT_MESSAGE_FORMAT = "Event::RPC::Message::Negotiate";
            }

            if ( $server_style eq 'old' ) {
                $Event::RPC::Server::DEFAULT_MESSAGE_FORMAT = "Event::RPC::Message::Storable";
            }
            else {
                $Event::RPC::Server::DEFAULT_MESSAGE_FORMAT = "Event::RPC::Message::Negotiate";
            }

            my $client_insecure_ok = $client_style eq 'secure' ? 0 : 1;
            my $server_insecure_ok = $server_style eq 'secure' ? 0 : 1;

            my $server_formats =
                $server_style eq 'old'      ? ["STOR"] :
                $server_style eq 'insecure' ? ["STOR"] : [ $other_format ];

            # start server in background, without logging
            Event_RPC_Test_Server->start_server (
                p => $PORT,
                S => 1,
                L => $ENV{EVENT_RPC_LOOP},
                f => $server_formats,
                i => $server_insecure_ok,
                l => 0, 
            );

            # create client instance
            my $client = Event::RPC::Client->new (
                host    => "localhost",
                port    => $PORT,
                insecure_msg_fmt_ok => $client_insecure_ok,
            );

            # connect to server
            eval { $client->connect };

            if ( $server_style eq 'secure' and $client_style eq 'old' or
                 $client_style eq 'secure' and $server_style eq 'old')
            {
                ok($@, "connection failed, server($server_style) | client($client_style) | si=$server_insecure_ok ci=$client_insecure_ok");
            }
            else {
                ok(!$@, "connection succeeded, server($server_style) | client($client_style) | si=$server_insecure_ok ci=$client_insecure_ok");
            }

            if ( $client->get_connected ) {
                ok(
                    ($server_style."|".$client_style =~ /\bsecure\b/ &&
                     $client->get_message_format !~ /Storable/) ||
                    ($server_style."|".$client_style !~ /\bsecure\b/ &&
                     $client->get_message_format =~ /Storable/),
                    "Correct message format chosen"
                );
                $client->disconnect;
            }
            else {
                ok(1, "No security check on connection failure");
            }

            # wait on server to quit
            wait;
            ok (1, "server stopped");
        }
    }
}
