use strict;
use Test::More;
use Test::Exception;

use Plack::Test;
use HTTP::Request::Common;

use AnyEvent;
use JSON;
use JSON::RPC2::AnyEvent::Server::PSGI;

my $app = JSON::RPC2::AnyEvent::Server->new(
    echo => sub {
        my ($cv, $args) = @_;
        my $w; $w = AE::timer 0.5, 0, sub{ undef $w; $cv->send($args); };
    },
    croak => sub{
        my ($cv, $args) = @_;
        $cv->croak($args);
    },
)->to_psgi_app;


$Plack::Test::Impl = 'AnyEvent';

test_psgi $app, sub{
    my $cb = shift;
    my $json = JSON->new;

    my $res = $cb->(POST '/',
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            method  => 'echo',
            params => {hoge => 1, fuga => 2},
        })
    );
    #$res->on_content_received(sub{
        is $res->code, 200;
        is $res->content, '';  # Notification will just get empty response.
    #});
    #$res->recv;  # For non-bloking response, Plack::Test::AnyEvent dies here...

    # For URL-query, though it does not have "id", it is not regarded as notification and response is returned.
    $res = $cb->(POST '/echo',
        'Content-Type' => 'application/x-www-form-urlencoded',
        Content => 'foo=1&bar=2',
    );
    $res->on_content_received(sub{
        is $res->code, 200;
        is $res->header('Content-type'), 'application/json';
        lives_ok{ $res = $json->decode($res->content) };
        is $res->{id}, undef;
        ok(not exists $res->{error});
        is_deeply $res->{result}, {foo => 1, bar => 2};
    });
    $res->recv;
    
    # When server method croaks, it returns error response
    $res = $cb->(POST '/',
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 3,
            method  => 'croak',
            params => ["Died!!"],
        }),
    );
    $res->on_content_received(sub{
        is $res->code, 200;
        is $res->header('Content-type'), 'application/json';
        lives_ok{ $res = $json->decode($res->content) };
        is $res->{id}, 3;
        ok(not exists $res->{result});
        isa_ok $res->{error}, 'HASH';
        is $res->{error}{code}, -32000;
        is $res->{error}{message}, 'Server error';
        is_deeply $res->{error}{data}, ["Died!!"];
    });
    $res->recv;
    
    # But, notification will not know the server croaks
    $res = $cb->(POST '/',
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            method  => 'croak',
            params => ["Died!!"],
        }),
    );
    #$res->on_content_received(sub{
        is $res->code, 200;
        is $res->content, '';
    #});
    #$res->recv;

    done_testing;
};
