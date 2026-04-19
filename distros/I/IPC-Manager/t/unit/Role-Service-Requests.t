use Test2::V0;

{
    package TestRequests::Obj;
    use Role::Tiny::With;

    my @SENT;

    sub new { bless {}, shift }

    sub client {
        return bless {}, 'TestRequests::FakeClient';
    }

    sub sent { @SENT }
    sub clear_sent { @SENT = () }

    with 'IPC::Manager::Role::Service::Requests';

    package TestRequests::FakeClient;

    sub send_message {
        my ($self, $peer, $content) = @_;
        push @SENT, {peer => $peer, content => $content};
    }

    sub peer_pid { 12345 }
}

subtest 'clear_servicerequests_fields' => sub {
    my $obj = TestRequests::Obj->new;
    $obj->{_RESPONSES} = {foo => 'bar'};
    $obj->{_RESPONSE_HANDLER} = {baz => sub {}};
    $obj->clear_servicerequests_fields;
    ok(!exists $obj->{_RESPONSES}, "responses cleared");
    ok(!exists $obj->{_RESPONSE_HANDLER}, "handlers cleared");
};

subtest 'have_pending_responses - no pending' => sub {
    my $obj = TestRequests::Obj->new;
    ok(!$obj->have_pending_responses, "no pending initially");
};

subtest 'send_request without callback' => sub {
    my $obj = TestRequests::Obj->new;
    TestRequests::Obj->clear_sent;

    my $id = $obj->send_request('peer1', 'hello');
    ok($id, "got a request id");

    my @sent = TestRequests::Obj->sent;
    is(scalar @sent, 1, "one message sent");
    is($sent[0]->{peer}, 'peer1', "sent to correct peer");
    is($sent[0]->{content}->{request}, 'hello', "request content");
    is($sent[0]->{content}->{ipcm_request_id}, $id, "request id in message");

    ok($obj->have_pending_responses, "has pending response");
};

subtest 'send_request with callback' => sub {
    my $obj = TestRequests::Obj->new;
    TestRequests::Obj->clear_sent;

    my $called = 0;
    my $id = $obj->send_request('peer2', 'world', sub { $called++ });
    ok($id, "got a request id");

    ok($obj->have_pending_responses, "has pending response with callback");

    # Simulate response
    my $resp = {ipcm_response_id => $id, response => 'reply'};
    my $msg = bless {content => $resp}, 'FakeMsg';
    $obj->handle_response($resp, $msg);

    is($called, 1, "callback was called");
    ok(!$obj->have_pending_responses, "no more pending after callback");
};

subtest 'get_response' => sub {
    my $obj = TestRequests::Obj->new;
    TestRequests::Obj->clear_sent;

    my $id = $obj->send_request('peer3', 'query');

    # No response yet
    my @res = $obj->get_response($id);
    is(scalar @res, 0, "no response yet");

    # Simulate response arriving
    my $resp = {ipcm_response_id => $id, response => 'answer'};
    my $msg = bless {content => $resp}, 'FakeMsg';
    $obj->handle_response($resp, $msg);

    my $got = $obj->get_response($id);
    is($got->{response}, 'answer', "got the response");
};

subtest 'get_response - unknown id' => sub {
    my $obj = TestRequests::Obj->new;
    like(
        dies { $obj->get_response('nonexistent-id') },
        qr/Not expecting a response/,
        "dies on unknown response id",
    );
};

subtest 'get_response - callback conflict' => sub {
    my $obj = TestRequests::Obj->new;
    TestRequests::Obj->clear_sent;

    my $id = $obj->send_request('peer4', 'x', sub {});
    like(
        dies { $obj->get_response($id) },
        qr/callback assigned/,
        "dies when trying get_response on callback-based request",
    );
};

subtest 'handle_response - unexpected response' => sub {
    my $obj = TestRequests::Obj->new;
    my $resp = {ipcm_response_id => 'bogus', response => 'x'};
    my $msg = bless {content => $resp}, 'FakeMsg';
    like(
        dies { $obj->handle_response($resp, $msg) },
        qr/unexpected response/,
        "dies on unexpected response",
    );
};

subtest 'handle_response - duplicate response' => sub {
    my $obj = TestRequests::Obj->new;
    TestRequests::Obj->clear_sent;

    my $id = $obj->send_request('peer5', 'dup');

    my $resp = {ipcm_response_id => $id, response => 'first'};
    my $msg = bless {content => $resp}, 'FakeMsg';
    $obj->handle_response($resp, $msg);

    my $resp2 = {ipcm_response_id => $id, response => 'second'};
    # Response was already fetched/set, try again
    # First get it to clear
    $obj->get_response($id);

    # Now it's gone, so handle_response should croak about unexpected
    like(
        dies { $obj->handle_response($resp2, $msg) },
        qr/unexpected response/,
        "dies on response after fetch",
    );
};

done_testing;
