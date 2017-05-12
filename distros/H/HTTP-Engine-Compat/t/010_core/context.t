use strict;
use warnings;
use HTTP::Engine::Compat;
use Scalar::Util qw/refaddr/;
use Test::More tests => 5;

HTTP::Engine->new(
    interface => {
        module => 'Test',
        args => { },
        request_handler => sub {
            my $c = shift;
            isa_ok $c, 'HTTP::Engine::Compat::Context';
            is $c->req->path, '/foo';
            is refaddr( $c->req ), refaddr( $c->request ),  'alias';
            is refaddr( $c->res ), refaddr( $c->response ), 'alias';
            is refaddr( $c->req->context ), refaddr($c), 'trigger';
        },
    },
)->run(HTTP::Request->new('GET', '/foo'));

