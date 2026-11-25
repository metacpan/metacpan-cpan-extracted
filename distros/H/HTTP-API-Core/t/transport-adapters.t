use strict;
use warnings;
use Test::More;

use lib 'examples';
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

{
    package Local::Tiny;
    sub new { bless { calls => [] }, shift }
    sub request {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, \@args;
        return {
            status => 201,
            reason => 'Created',
            headers => { 'content-type' => 'text/plain' },
            content => 'tiny',
        };
    }
    sub calls { $_[0]->{calls} }
}

{
    my $http = Local::Tiny->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => HTTP::API::Core::Example::TransportAdapters::http_tiny($http),
    );
    my $response = $api->post('/items', content => '');
    is $response->status, 201, 'HTTP::Tiny response is passed through';
    is $response->content, 'tiny', 'HTTP::Tiny content is preserved';
    is $http->calls->[0][0], 'POST', 'HTTP::Tiny receives method';
    ok exists $http->calls->[0][2]{content}, 'HTTP::Tiny adapter preserves explicit empty body';
}

{
    package Local::LWPHeaders;
    sub new { bless {}, shift }
    sub flatten { ('Content-Type' => 'application/json', 'X-Test' => 'yes') }

    package Local::LWPResponse;
    sub new { bless {}, shift }
    sub code { 202 }
    sub message { 'Accepted' }
    sub headers { Local::LWPHeaders->new }
    sub content { '{"adapter":"lwp"}' }

    package Local::LWP;
    sub new { bless { request => undef }, shift }
    sub request {
        my ($self, $request) = @_;
        $self->{request} = $request;
        return Local::LWPResponse->new;
    }
    sub seen { $_[0]->{request} }
}

SKIP: {
    eval { require HTTP::Request; 1 }
        or skip 'HTTP::Request is not installed', 6;

    my $ua = Local::LWP->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => HTTP::API::Core::Example::TransportAdapters::lwp_user_agent($ua),
    );
    my $response = $api->post('/items', headers => { 'X-In' => 'yes' }, content => '');
    is $response->status, 202, 'LWP response status is mapped';
    is $response->reason, 'Accepted', 'LWP response reason is mapped';
    is $response->content, '{"adapter":"lwp"}', 'LWP raw content is mapped';
    is $ua->seen->method, 'POST', 'LWP request receives method';
    is $ua->seen->header('X-In'), 'yes', 'LWP request receives headers';
    is $ua->seen->content, '', 'LWP adapter preserves explicit empty body';
}


# Exercise the reference adapters without installing optional HTTP clients.
# The fakes expose only the documented methods used by each adapter.
{
    package Local::AdapterHeaders;
    sub new { bless { 'Content-Type' => 'text/plain', 'X-Test' => 'yes' }, shift }
    sub names { [sort keys %{ $_[0] }] }
    sub header_field_names { sort keys %{ $_[0] } }
    sub header { $_[0]->{$_[1]} }

    package Local::AdapterResponse;
    sub new { bless {}, shift }
    sub code { 202 }
    sub message { 'Accepted' }
    sub headers { Local::AdapterHeaders->new }
    sub body { 'adapter body' }
    sub content { 'adapter body' }

    package Local::MojoRequest;
    sub new { bless {}, shift }
    sub body {
        my ($self, @args) = @_;
        $self->{body} = $args[0] if @args;
        return $self->{body};
    }

    package Local::MojoTransaction;
    sub new { bless { req => Local::MojoRequest->new }, shift }
    sub req { $_[0]->{req} }
    sub result { Local::AdapterResponse->new }

    package Local::Mojo;
    sub new { bless { calls => [], started => [] }, shift }
    sub build_tx {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, \@args;
        return Local::MojoTransaction->new;
    }
    sub start {
        my ($self, $tx) = @_;
        push @{ $self->{started} }, $tx;
        return $tx;
    }

    package Local::Furl;
    sub new { bless { calls => [] }, shift }
    sub request {
        my ($self, %args) = @_;
        push @{ $self->{calls} }, \%args;
        return Local::AdapterResponse->new;
    }

    package Local::BuildOnly;
    sub new { bless {}, shift }
    sub build_tx { die 'must not be called' }

    package Local::NoMethods;
    sub new { bless {}, shift }
}

# Constructors are functions, not methods; each receives only the client.
for my $case (
    [ \&HTTP::API::Core::Example::TransportAdapters::http_tiny, 'HTTP::Tiny' ],
    [ \&HTTP::API::Core::Example::TransportAdapters::lwp_user_agent, 'LWP::UserAgent' ],
    [ \&HTTP::API::Core::Example::TransportAdapters::mojo_user_agent, 'Mojo::UserAgent' ],
    [ \&HTTP::API::Core::Example::TransportAdapters::furl, 'Furl' ],
) {
    my ($factory, $name) = @$case;
    for my $object (undef, Local::NoMethods->new) {
        my $error;
        eval { $factory->($object); 1 } or $error = $@;
        like $error, qr/\Q$name\E-compatible object is required/,
            "$name rejects missing or incompatible object";
    }
}
{
    my $error;
    eval {
        HTTP::API::Core::Example::TransportAdapters::mojo_user_agent(Local::BuildOnly->new);
        1;
    } or $error = $@;
    like $error, qr/Mojo::UserAgent-compatible object is required/,
        'Mojo adapter also requires start';
}

my $url = 'https://api.example.test/items';
my $expected = {
    status => 202, reason => 'Accepted', content => 'adapter body',
    headers => { 'Content-Type' => 'text/plain', 'X-Test' => 'yes' },
};
{
    my $ua = Local::Mojo->new;
    my $transport = HTTP::API::Core::Example::TransportAdapters::mojo_user_agent($ua);
    is_deeply $transport->('POST', $url, { headers => { 'X-In' => 'yes' }, content => '' }),
        $expected, 'Mojo maps response fields into core response shape';
    is_deeply $ua->{calls}[0], ['POST', $url, { 'X-In' => 'yes' }],
        'Mojo receives method, URL and request headers';
    is $ua->{started}[0]->req->body, '', 'Mojo preserves explicit empty body';

    is_deeply $transport->('GET', $url, {}), $expected, 'Mojo supports bodyless request';
    is_deeply $ua->{calls}[1], ['GET', $url, {}], 'Mojo defaults absent headers to empty map';
    ok !exists($ua->{started}[1]->req->{body}), 'Mojo omits absent request body';
}
{
    my $ua = Local::Furl->new;
    my $transport = HTTP::API::Core::Example::TransportAdapters::furl($ua);
    is_deeply $transport->('POST', $url, { headers => { 'X-In' => 'yes' }, content => '' }),
        $expected, 'Furl maps status, reason, response headers and content';
    is_deeply $ua->{calls}[0],
        { method => 'POST', url => $url, headers => ['X-In', 'yes'], content => '' },
        'Furl receives method, URL, header pairs and explicit empty body';
    is_deeply $transport->('GET', $url, {}), $expected, 'Furl supports bodyless request';
    is_deeply $ua->{calls}[1], { method => 'GET', url => $url, headers => [] },
        'Furl omits absent body and defaults headers to empty list';
}
{
    my $http = Local::Tiny->new;
    my $transport = HTTP::API::Core::Example::TransportAdapters::http_tiny($http);
    is $transport->('GET', $url, {})->{status}, 201, 'Tiny supports bodyless request';
    is_deeply $http->calls->[0], ['GET', $url, { headers => {} }],
        'Tiny defaults headers and omits absent body';
}
SKIP: {
    eval { require HTTP::Request; 1 } or skip 'HTTP::Request is not installed', 4;
    my $ua = Local::LWP->new;
    my $transport = HTTP::API::Core::Example::TransportAdapters::lwp_user_agent($ua);
    is $transport->('GET', $url, {})->{status}, 202, 'LWP supports bodyless request';
    is $ua->seen->uri->as_string, $url, 'LWP receives URL';
    is $ua->seen->content, '', 'LWP bodyless request has empty content';
    ok !defined($ua->seen->header('X-In')), 'LWP has no unexpected request header';
}

done_testing;
