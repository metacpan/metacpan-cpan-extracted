use strict;
use warnings;
use Test::More;
use t::Utils;
use HTTP::Engine::Compat;
use HTTP::Engine::Response;
use HTTP::Request;
use IO::Scalar;

my @tests = (
    sub {},
    sub { '' },
    sub { 'A' },
    sub { 1 },
    sub { +{} },
    sub { +[] },
    sub { sub{} },
    sub { shift },
    sub { HTTP::Request->new( GET => 'http://localhost/')},
    [ sub { HTTP::Engine::Response->new( body => 'new style' ) }, 'new style' ],
);

plan tests => 2*scalar(@tests);

run_engines(@tests);


sub run_engines {
    for my $code (@_) {
        my $content =  'OK';
        if (ref($code) eq 'ARRAY') {
            $content = $code->[1];
            $code    = $code->[0];
        }
        my $res = run_engine { 
            my $c = shift;
            $c->res->body('OK');
            $code->();
        } HTTP::Request->new( GET => 'http://localhost/');
        is $res->status, 200;
        is $res->body, $content, $content;
    }
}
