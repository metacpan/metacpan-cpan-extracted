use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

{
    package Local::ObjectTransport;

    sub new { bless { seen => [] }, shift }

    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{ $self->{seen} }, [$method, $url, $opts];
        return {
            status => 200,
            reason => 'OK',
            headers => { 'Content-Type' => 'application/json' },
            content => '{"transport":"object"}',
        };
    }

    sub seen { $_[0]->{seen} }
}

{
    my $transport = Local::ObjectTransport->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => $transport,
    );

    my $response = $api->post('/items', content => 'hello', headers => { 'X-Test' => 'yes' });
    is $response->json->{transport}, 'object', 'object transport response is normalized';
    is $transport->seen->[0][0], 'POST', 'object transport receives method';
    is $transport->seen->[0][1], 'https://api.example.test/items', 'object transport receives URL';
    is $transport->seen->[0][2]{content}, 'hello', 'object transport receives content';
    is $transport->seen->[0][2]{headers}{'X-Test'}, 'yes', 'object transport receives headers';
}

{
    my @seen;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => sub {
            push @seen, [@_];
            return { status => 204, reason => 'No Content', headers => {}, content => '' };
        },
    );

    my $response = $api->get('/items');
    is $response->status, 204, 'existing coderef transport remains supported';
    is $seen[0][0], 'GET', 'coderef transport contract is unchanged';
}

{
    my $ok = eval {
        HTTP::API::Core->new(
            base_url => 'https://api.example.test',
            transport => bless({}, 'Local::NoRequest'),
        );
        1;
    };
    ok !$ok, 'object without request method is rejected';
    like $@, qr/code reference or object with request/, 'invalid transport error describes contract';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => bless({}, 'Local::ThrowingTransport'),
    );

    my $error;
    eval { $api->get('/items'); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport', 'object transport exceptions are normalized';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => bless({}, 'Local::InvalidTransport'),
    );

    my $error;
    eval { $api->get('/items'); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport', 'invalid object transport responses are normalized';
}

{
    package Local::ThrowingTransport;
    sub request { die "socket failed\n" }

    package Local::InvalidTransport;
    sub request { return { reason => 'missing status' } }
}

done_testing;
