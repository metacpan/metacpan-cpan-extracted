use v5.26;
use warnings;
use utf8;
use Test2::V1;
use JSON::PP;
use lib 't/lib';
use TestDiscordREST qw(client response error);
use Discord::Client::Commands;

sub registry {
    my (%options) = @_;

    # Share the controlled REST client with a registry that performs no startup I/O.
    my ( $rest, $http ) = client();
    my $commands = Discord::Client::Commands->new(
        rest => $rest,
        loop => $rest->loop,
        %options,
    );
    return ( $commands, $rest, $http );
}

T2->subtest(
    'declarations stay local and expose independent wire snapshots',
    sub {
        my ( $commands, $rest, $http ) = registry();
        $commands->define( ping => description => 'Ping', handler => sub { } );

        T2->is( $http->count, 0, 'declaring a command does not send a request' );
        T2->is(
            $commands->definitions,
            [ { name => 'ping', type => 1, description => 'Ping' } ],
            'the wire declaration contains data, not its callback'
        );

        # Mutating an exported definition must not change later deployment snapshots.
        my $snapshot = $commands->definitions;
        $snapshot->[0]{name} = 'modified';
        T2->is( $commands->definitions->[0]{name}, 'ping', 'editing a snapshot does not change the registry' );

        $commands->close;
        $rest->close;
    }
);

T2->subtest(
    'Unicode names and named option types become valid Discord JSON',
    sub {
        my ( $commands, $rest, $http ) = registry();
        $commands->define(
            '検索' => description => 'Search',
            handler => sub { },
            options => [
                {
                    name => 'query',
                    description => 'Query',
                    type => 'string',
                    required => 1,
                    autocomplete => sub { [] }
                },
                {
                    name => 'count',
                    description => 'Count',
                    type => 'integer',
                    min_value => 1,
                    max_value => 10
                },
            ]
        );
        $commands->define( 'Inspect User' => type => 'user', handler => sub { } );

        my $wire = $commands->definitions;
        T2->ok( JSON::PP::is_bool( $wire->[0]{options}[0]{autocomplete} ), 'autocomplete is a JSON boolean' );
        T2->is( $wire->[0]{options}[1]{type}, 4, 'integer options use the Discord type number' );
        T2->is(
            $wire->[1],
            { name => 'Inspect User', type => 2 },
            'context-menu commands omit descriptions/options'
        );
        my $json = JSON::PP->new->utf8;
        T2->like( $json->encode($wire), qr/"autocomplete":true/, 'autocomplete serializes as a JSON boolean' );
        T2->is( $json->decode( $json->encode($wire) )->[0]{name},
            '検索', 'the Unicode command name survives UTF-8 serialization' );
        T2->is( $http->count, 0, 'wire conversion does not deploy commands' );

        $commands->close;
        $rest->close;
    }
);

T2->subtest(
    'command and option apostrophes follow Discord Unicode naming rules',
    sub {
        my ( $commands, $rest, $http ) = registry();

        # Discord permits U+02BC rather than the ASCII apostrophe for slash names.
        $commands->define(
            "don\x{02BC}t" => description => 'Unicode apostrophe',
            handler => sub { },
            options => [ { name => "can\x{02BC}t", description => 'Option', type => 'string' } ]
        );
        T2->is( $commands->definitions->[0]{name}, "don\x{02BC}t", 'modifier letter apostrophe is accepted' );
        T2->like(
            T2->dies(
                sub {
                    $commands->define( "don't" => description => 'ASCII apostrophe', handler => sub { } );
                }
            ),
            qr/Invalid command name/,
            'ASCII apostrophe is rejected for slash commands'
        );
        T2->like(
            T2->dies(
                sub {
                    $commands->define(
                        test => description => 'Test',
                        handler => sub { },
                        options => [ { name => "can't", description => 'Option', type => 'string' } ]
                    );
                }
            ),
            qr/Invalid command option/,
            'ASCII apostrophe is rejected for slash options'
        );
        $commands->define( "Don't Ping" => type => 'user', handler => sub { } );
        T2->is( $commands->definitions->[1]{name}, "Don't Ping", 'context-menu names retain their separate rules' );
        $commands->close;
        $rest->close;
    }
);

my @invalid_declarations = (
    {
        name => 'uppercase slash name',
        args => [ 'Upper', description => 'Ping', handler => sub { } ],
        error => qr/Invalid command name/
    },
    {
        name => 'empty description',
        args => [ 'bad', description => '', handler => sub { } ],
        error => qr/Invalid command description/
    },
    {
        name => 'missing handler',
        args => [ 'bad', description => 'Ping' ],
        error => qr/requires a handler/
    },
    {
        name => 'required option after an optional option',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [
                { name => 'first', description => 'First', type => 'string' },
                { name => 'second', description => 'Second', type => 'string', required => 1 },
            ]
        ],
        error => qr/Required options must precede optional options/
    },
    {
        name => 'duplicate option names',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [
                { name => 'dup', description => 'First', type => 'string' },
                { name => 'dup', description => 'Second', type => 'string' },
            ]
        ],
        error => qr/Invalid command option/
    },
    {
        name => 'choices combined with autocomplete',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [
                {
                    name => 'query',
                    description => 'Query',
                    type => 'string',
                    choices => [],
                    autocomplete => sub { [] }
                },
            ]
        ],
        error => qr/Autocomplete and choices are mutually exclusive/
    },
    {
        name => 'fractional integer bound',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [
                { name => 'count', description => 'Count', type => 'integer', min_value => 1.5 },
            ]
        ],
        error => qr/Invalid numeric option bound/
    },
    {
        name => 'minimum string length above maximum',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [
                {
                    name => 'text',
                    description => 'Text',
                    type => 'string',
                    min_length => 10,
                    max_length => 2
                },
            ]
        ],
        error => qr/Minimum string length exceeds maximum/
    },
    {
        name => 'empty subcommand group',
        args => [
            'bad',
            description => 'Ping',
            handler => sub { },
            options => [ { name => 'group', description => 'Group', type => 'group', options => [] }, ]
        ],
        error => qr/Groups require at least one subcommand/
    },
);

for my $case (@invalid_declarations) {
    T2->subtest(
        "reject $case->{name} without changing the registry",
        sub {
            my ( $commands, $rest, $http ) = registry();
            $commands->define( ping => description => 'Ping', handler => sub { } );
            my $before = $commands->definitions;

            T2->like( T2->dies( sub { $commands->define( @{ $case->{args} } ) } ),
                $case->{error}, 'the error identifies the invalid condition' );
            T2->is( $commands->definitions, $before, 'the existing command remains unchanged' );
            T2->is( $http->count, 0, 'invalid declarations do not reach Discord' );
            $commands->close;
            $rest->close;
        }
    );
}

T2->subtest(
    'guild synchronization discovers the application and sends the starting snapshot',
    sub {
        my ( $commands, $rest, $http ) = registry();
        $commands->define( ping => description => 'Ping', handler => sub { } );
        my $declarations = $commands->definitions;

        # Freeze the deployment contents before application discovery can complete.
        my $synchronization = $commands->sync( scope => { guild_id => '789' } );
        T2->is(
            $http->call->{request}->uri->path,
            '/api/v10/oauth2/applications/@me',
            'application discovery happens on explicit sync'
        );
        $commands->define( later => description => 'Added during discovery', handler => sub { } );
        $http->respond( response( 200, { id => '456' } ) );

        # Only the frozen declarations may reach the requested guild.
        my $request = $http->call->{request};
        T2->is( $request->method, 'PUT', 'synchronization bulk-overwrites commands' );
        T2->is(
            $request->uri->path,
            '/api/v10/applications/456/guilds/789/commands',
            'the requested guild is targeted'
        );
        T2->is( JSON::PP->new->utf8->decode( $request->content ),
            $declarations, 'commands added after sync began wait for the next deployment' );
        T2->is( error( $commands->sync )->category, 'state', 'a second sync cannot overlap the first' );

        $http->respond( response( 200, [ { id => '10', name => 'ping' } ] ) );
        T2->is( $synchronization->get->[0]{id}, '10', 'Discord registration IDs are returned' );
        $commands->close;
        $rest->close;
    }
);

T2->subtest(
    'global synchronization uses the known application and propagates cancellation',
    sub {
        my ( $commands, $rest, $http ) = registry( application_id => '456' );
        $commands->define( ping => description => 'Ping', handler => sub { } );

        my $synchronization = $commands->sync;
        T2->is( $http->count, 1, 'a known application needs no discovery request' );
        T2->is(
            $http->call->{request}->uri->path,
            '/api/v10/applications/456/commands',
            'the default scope is global'
        );

        # Cancelling deployment must reach the single outstanding transport request.
        $synchronization->cancel;
        T2->ok( $http->call->{future}->is_cancelled, 'cancellation reaches the HTTP transport' );

        $commands->close;
        $rest->close;
    }
);

T2->subtest(
    'invalid synchronization scopes fail before HTTP I/O',
    sub {
        my ( $commands, $rest, $http ) = registry( application_id => '456' );

        my $synchronization = $commands->sync( scope => { guild_id => '../bad' } );
        T2->is( error($synchronization)->category, 'request', 'invalid scope returns a request failure' );
        T2->is( $http->count, 0, 'no request is sent for the invalid scope' );

        $commands->close;
        $rest->close;
    }
);

T2->subtest(
    'choice JSON follows its declared option type during deployment',
    sub {
        # Perl scalar flags must not decide the JSON type of a Discord choice.
        my ( $commands, $rest, $http ) = registry( application_id => '456' );
        $commands->define(
            choose => description => 'Choose a code',
            handler => sub { },
            options => [
                {
                    name => 'text',
                    description => 'Text',
                    type => 'string',
                    choices => [ { name => 'One', value => 1 } ]
                },
                {
                    name => 'integer',
                    description => 'Integer',
                    type => 'integer',
                    choices => [ { name => 'Two', value => '2' } ]
                },
                {
                    name => 'number',
                    description => 'Number',
                    type => 'number',
                    choices => [ { name => 'Half', value => '0.5' } ]
                },
            ]
        );

        # Inspect the actual request bytes; Perl value equality hides type errors.
        my $synced = $commands->sync;
        my $body = $http->call->{request}->content;
        T2->like( $body, qr/"value":"1"/, 'string choice is encoded as a string' );
        T2->like( $body, qr/"value":2\b/, 'integer choice is encoded as a number' );
        T2->like( $body, qr/"value":0\.5\b/, 'number choice retains its fraction' );
        $http->respond( response( 200, [] ) );
        T2->ok( $synced->is_done, 'deployment completes' );
        $commands->close;
        $rest->close;
    }
);

T2->done_testing;
