use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use lib 't/lib';
use TestDiscordREST qw(client response error);
use Discord::Client::Model;

# Each public helper must preserve its endpoint, request shape and unknown response fields.
my @endpoints = (
    {
        name => 'current user discovery',
        method => 'get_current_user',
        args => [],
        verb => 'GET',
        path => '/users/@me',
        response => { id => '1', username => 'bot', future_field => 1 }
    },
    {
        name => 'user lookup',
        method => 'get_user',
        args => ['1'],
        verb => 'GET',
        path => '/users/1',
        response => { id => '1', future_field => 1 }
    },
    {
        name => 'channel lookup',
        method => 'get_channel',
        args => ['2'],
        verb => 'GET',
        path => '/channels/2',
        response => { id => '2', future_field => 1 }
    },
    {
        name => 'guild lookup with counts',
        method => 'get_guild',
        args => [ '3', with_counts => 'true' ],
        verb => 'GET',
        path => '/guilds/3',
        query => { with_counts => 'true' },
        response => { id => '3', future_field => 1 }
    },
    {
        name => 'guild channel listing',
        method => 'get_guild_channels',
        args => ['3'],
        verb => 'GET',
        path => '/guilds/3/channels',
        response => [ { id => '2', future_field => 1 } ]
    },
    {
        name => 'guild member lookup',
        method => 'get_guild_member',
        args => [ '3', '1' ],
        verb => 'GET',
        path => '/guilds/3/members/1',
        response => { user => { id => '1' }, future_field => 1 }
    },
    {
        name => 'message lookup',
        method => 'get_message',
        args => [ '2', '4' ],
        verb => 'GET',
        path => '/channels/2/messages/4',
        response => { id => '4', channel_id => '2', future_field => 1 }
    },
    {
        name => 'message pagination',
        method => 'get_messages',
        args => [ '2', before => '4', limit => 2 ],
        verb => 'GET',
        path => '/channels/2/messages',
        query => { before => '4', limit => 2 },
        response => [ { id => '3', future_field => 1 } ]
    },
    {
        name => 'text message creation',
        method => 'create_message',
        args => [ '2', 'hello' ],
        verb => 'POST',
        path => '/channels/2/messages',
        body => { content => 'hello' },
        response => { id => '4', channel_id => '2', content => 'hello' }
    },
    {
        name => 'message editing',
        method => 'edit_message',
        args => [ '2', '4', { content => 'edited' } ],
        verb => 'PATCH',
        path => '/channels/2/messages/4',
        body => { content => 'edited' },
        response => { id => '4', content => 'edited' }
    },
    {
        name => 'message deletion',
        method => 'delete_message',
        args => [ '2', '4' ],
        verb => 'DELETE',
        path => '/channels/2/messages/4',
        status => 204
    },
    {
        name => 'direct-message channel creation',
        method => 'create_dm',
        args => ['1'],
        verb => 'POST',
        path => '/users/@me/channels',
        body => { recipient_id => '1' },
        response => { id => '2' }
    },
    {
        name => 'typing indication',
        method => 'trigger_typing',
        args => ['2'],
        verb => 'POST',
        path => '/channels/2/typing',
        status => 204
    },
);

for my $case (@endpoints) {
    T2->subtest(
        "$case->{name} uses its Discord endpoint and preserves the response",
        sub {
            my ( $rest, $http ) = client();
            my $method = $case->{method};
            my $future = $rest->$method( @{ $case->{args} } );

            my $request = $http->call->{request};
            T2->is( $request->method, $case->{verb}, 'HTTP method' );
            T2->is( $request->uri->path, '/api/v10' . $case->{path}, 'API v10 route' );
            T2->is( { $request->uri->query_form }, $case->{query} // {}, 'query parameters' );
            if ( exists $case->{body} ) {
                T2->is( JSON::PP->new->utf8->decode( $request->content ), $case->{body}, 'JSON payload' );
            }
            $http->respond( response( $case->{status} // 200, $case->{response} ) );
            T2->is( scalar( $future->get ),
                $case->{response}, 'response data is unchanged, including unknown fields' );
            $rest->close;
        }
    );
}

# Invalid identifiers and incompatible query parameters must fail before transport I/O.
my @invalid_requests = (
    {
        name => 'conflicting pagination cursors',
        method => 'get_messages',
        args => [ '2', before => '1', after => '2' ]
    },
    { name => 'message limit above 100', method => 'get_messages', args => [ '2', limit => 101 ] },
    {
        name => 'invalid pagination cursor',
        method => 'get_messages',
        args => [ '2', around => '../bad' ]
    },
    { name => 'invalid message ID', method => 'get_message', args => [ '2', '../4' ] },
    { name => 'non-scalar DM recipient', method => 'create_dm', args => [ { id => '1' } ] },
);
for my $case (@invalid_requests) {
    T2->subtest(
        "$case->{name} fails before transport I/O",
        sub {
            my ( $rest, $http ) = client();
            my $method = $case->{method};
            my $future = $rest->$method( @{ $case->{args} } );

            T2->is( error($future)->category, 'request', 'the failure is an invalid request' );
            T2->is( $http->count, 0, 'no HTTP request was sent' );
            $rest->close;
        }
    );
}

T2->subtest(
    'model snapshots preserve large IDs and isolate nested data',
    sub {

        # Mutate both the source data and returned copies to check snapshot isolation.
        my $data = { id => '9007199254740993', name => 'general', extra => { future_field => 1 } };
        my $channel = Discord::Client::Model->wrap( channel => $data );
        $data->{extra}{future_field} = 2;
        my $snapshot = $channel->raw;
        $snapshot->{name} = 'changed';
        $snapshot->{extra}{future_field} = 3;

        T2->is( $channel->id, '9007199254740993', 'snowflake precision is retained' );
        T2->is( $channel->mention, '<#9007199254740993>', 'mention uses the complete ID' );
        T2->is( $channel->name, 'general', 'editing a returned snapshot cannot rename the model' );
        T2->is(
            $channel->get('extra'),
            { future_field => 1 },
            'input and output mutations cannot change nested fields'
        );
        my $field = $channel->get('extra');
        $field->{future_field} = 4;
        T2->is(
            $channel->get('extra'),
            { future_field => 1 },
            'editing a get() result cannot change the stored field'
        );
        T2->is( $channel->get('absent'), undef, 'unknown missing fields return undef' );
    }
);

T2->subtest(
    'channel send returns a message snapshot',
    sub {
        my ( $rest, $http ) = client();
        my $channel = Discord::Client::Model->wrap( channel => { id => '2' }, rest => $rest );
        my $future = $channel->send('hello');
        $http->respond( response( 200, { id => '4', channel_id => '2', content => 'hello' } ) );

        my $message = $future->get;
        T2->isa_ok( $message, 'Discord::Client::Model::Message' );
        T2->is( $message->channel_id, '2', 'the message belongs to the requested channel' );
        T2->is( $message->content, 'hello', 'the server content is returned' );
        $rest->close;
    }
);

T2->subtest(
    'reply references its source without changing caller data',
    sub {
        my ( $rest, $http ) = client();
        my $message = Discord::Client::Model->wrap(
            message => { id => '4', channel_id => '2' },
            rest => $rest
        );
        my $body = { content => 'reply' };
        my $future = $message->reply($body);

        my $sent = JSON::PP->new->utf8->decode( $http->call->{request}->content );
        T2->is(
            $sent,
            { content => 'reply', message_reference => { message_id => '4', channel_id => '2' } },
            'the outgoing reply references the source message and channel'
        );
        T2->is( $body, { content => 'reply' }, 'the caller payload remains unchanged' );
        $http->respond( response( 200, { id => '5', channel_id => '2', content => 'reply' } ) );
        T2->is( $future->get->id, '5', 'the new message has the server-assigned ID' );
        $rest->close;
    }
);

T2->subtest(
    'editing a message creates a new snapshot and deletion accepts HTTP 204',
    sub {
        my ( $rest, $http ) = client();
        my $message = Discord::Client::Model->wrap(
            message => { id => '4', channel_id => '2', content => 'original' },
            rest => $rest,
        );
        my $edit = $message->edit('changed');
        $http->respond( response( 200, { id => '4', channel_id => '2', content => 'changed' } ) );

        T2->is( $edit->get->content, 'changed', 'edit returns the updated snapshot' );
        T2->is( $message->content, 'original', 'the original snapshot is unchanged' );

        # Deletion succeeds with an empty HTTP 204 response rather than requiring JSON.
        my $deletion = $message->delete;
        $http->respond( response( 204, undef ) );
        T2->is( scalar( $deletion->get ), undef, 'successful deletion has no JSON body' );
        $rest->close;
    }
);

T2->subtest(
    'detached user models fail asynchronous operations clearly',
    sub {
        my $user = Discord::Client::Model->wrap( user => { id => '1' } );
        T2->is( $user->mention, '<@1>', 'user mention is available without REST' );
        T2->is( error( $user->create_dm )->category, 'state', 'network operations require a REST client' );
    }
);

T2->subtest(
    'guild channel lists contain channel models',
    sub {
        my ( $rest, $http ) = client();
        my $guild = Discord::Client::Model->wrap( guild => { id => '3' }, rest => $rest );
        my $future = $guild->channels;
        $http->respond( response( 200, [ { id => '2', name => 'general' }, { id => '6', name => 'help' } ] ) );

        my $channels = $future->get;
        T2->isa_ok( $channels->[0], 'Discord::Client::Model::Channel' );
        T2->is( [ map { $_->id } @$channels ], [ '2', '6' ], 'all server channel IDs are preserved' );
        T2->is( $channels->[1]->name, 'help', 'channel data remains accessible' );
        $rest->close;
    }
);

T2->subtest(
    'malformed model responses fail with a protocol error',
    sub {
        my ( $rest, $http ) = client();
        my $channel = Discord::Client::Model->wrap( channel => { id => '2' }, rest => $rest );
        my $future = $channel->refresh;
        $http->respond( response( 200, { bad => 'data without an ID' } ) );

        T2->is( error($future)->category, 'protocol', 'a successful HTTP response still needs valid model data' );
        $rest->close;
    }
);

T2->subtest(
    'model Future cancellation reaches the transport',
    sub {
        my ( $rest, $http ) = client();
        my $channel = Discord::Client::Model->wrap( channel => { id => '2' }, rest => $rest );
        my $future = $channel->send('hello');

        # Cancelling the model operation must release its underlying HTTP request.
        $future->cancel;

        T2->ok( $http->call->{future}->is_cancelled, 'the pending HTTP request is cancelled' );
        $rest->close;
    }
);

T2->done_testing;
