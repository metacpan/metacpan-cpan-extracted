use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Error;

{
    package Local::ContractTransport;
    sub new { bless { calls => [] }, shift }
    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{ $self->{calls} }, [$method, $url, $opts];
        return { status => 200 };
    }
    sub calls { $_[0]->{calls} }
}

{
    my $transport = Local::ContractTransport->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        headers => { 'X-Default' => 'yes' },
        hooks => {
            before_request => sub {
                my ($ctx) = @_;
                $ctx->{headers}{'X-Hook'} = 'seen';
            },
        },
        transport => $transport,
    );

    my $response = $api->get('/items');
    isa_ok $response, 'HTTP::API::Core::Response';
    is $response->status, 200, 'minimal transport response is normalized';
    is $response->content, '', 'missing transport content defaults to empty string';
    is_deeply $response->headers, {}, 'missing transport headers default to empty hash';
    ok !defined($response->reason), 'missing transport reason remains undefined';

    my ($method, $url, $opts) = @{ $transport->calls->[0] };
    is $method, 'GET', 'object transport receives normalized method';
    is $url, 'https://api.example.test/items', 'object transport receives final URL';
    is $opts->{headers}{'X-Default'}, 'yes', 'object transport receives default headers';
    is $opts->{headers}{'X-Hook'}, 'seen', 'object transport receives hook-mutated headers';
    ok !exists($opts->{content}), 'content key is omitted when request has no body';
}

{
    my @calls;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => sub {
            push @calls, [@_];
            return { status => 204, headers => {}, content => '' };
        },
    );

    $api->post('/empty', content => '');
    ok exists($calls[0][2]{content}), 'content key is present for an explicit empty body';
    is $calls[0][2]{content}, '', 'explicit empty body is preserved';
}

{
    my @forms = (
        sub { return 'not-a-hash' },
        sub { return {} },
    );

    for my $transport (@forms) {
        my $api = HTTP::API::Core->new(
            base_url => 'https://api.example.test',
            retry => { attempts => 1 },
            transport => $transport,
        );

        my $error;
        eval { $api->get('/invalid'); 1 } or $error = $@;
        isa_ok $error, 'HTTP::API::Core::Error';
        is $error->category, 'transport', 'invalid return shape uses transport category';
        ok $error->retryable, 'invalid transport response is retryable';
        like "$error", qr/invalid response/, 'invalid transport response has stable message';
    }
}

{
    my $original = HTTP::API::Core::Error->new(
        category => 'transport',
        method => 'GET',
        url => 'https://api.example.test/preserved',
        retryable => 0,
        message => 'adapter-specific transport error',
    );

    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub { die $original },
    );

    my $caught;
    eval { $api->get('/preserved'); 1 } or $caught = $@;
    is $caught, $original, 'structured transport errors are preserved without re-wrapping';
}

{
    my $ok = eval {
        HTTP::API::Core->new(
            base_url => 'https://api.example.test',
            transport => [],
        );
        1;
    };
    ok !$ok, 'unsupported transport reference is rejected';
    like $@, qr/transport must be a code reference or object with request\(\)/,
        'constructor error states accepted transport forms';
}

done_testing;
