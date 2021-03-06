use strict;
use warnings;
use Test::More;

if (Any::Moose::moose_is_preferred() && $Class::MOP::VERSION < 0.79) {
    plan skip_all => 'This test case does not worked by Class::MOP under 0.79 (Class::MOP::is_class_loaded method problem by XS code)';
}

plan tests => 19;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

{
    package TestProfile;
    use Any::Moose;
    with 'HTTP::Engine::Middleware::Profile::Role';

    my $i = 1;
    sub start {
        my($self, $c, $profile, $req) = @_;
        ::isa_ok $self, 'TestProfile';
        ::isa_ok $c, 'HTTP::Engine::Middleware';
        ::isa_ok $profile, 'HTTP::Engine::Middleware::Profile';
        ::isa_ok $req, 'HTTP::Engine::Request';
        $profile->log( 'log:'.$i++);
    }

    sub end {
        my($self, $c, $profile, $req, $res) = @_;
        ::isa_ok $self, 'TestProfile';
        ::isa_ok $c, 'HTTP::Engine::Middleware';
        ::isa_ok $profile, 'HTTP::Engine::Middleware::Profile';
        ::isa_ok $req, 'HTTP::Engine::Request';
        ::isa_ok $res, 'HTTP::Engine::Response';
        $profile->log( 'log:'.$i++);
    }

    sub report {
        my($self, $c, $profile, $req, $res) = @_;
        ::isa_ok $self, 'TestProfile';
        ::isa_ok $c, 'HTTP::Engine::Middleware';
        ::isa_ok $profile, 'HTTP::Engine::Middleware::Profile';
        ::isa_ok $req, 'HTTP::Engine::Request';
        ::isa_ok $res, 'HTTP::Engine::Response';
        $profile->log( 'log:'.$i++);
    }
}

{
    my $i = 1;
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::Profile',{
        profiler_class => '+TestProfile',
        logger         => sub { ::is $_[0], 'log:'.$i++ },
    });
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { HTTP::Engine::Response->new( body => 'ok' ) }
            ),
        },
    )->run( HTTP::Request->new( GET => 'http://localhost/') );
    my $out = $res->content;

    is $res->code, '200', 'response code';
    is $out, 'ok', 'response content';
}
