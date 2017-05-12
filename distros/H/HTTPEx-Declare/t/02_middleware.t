use strict;
use warnings;
use lib '.';
use Test::More;

eval "use HTTP::Engine::Compat;";
plan skip_all => 'this test requires HTTP::Engine::Compat' if $@;
plan tests => 2;

eval <<'...';
use HTTPEx::Declare -Compat;

middlewares '+t::DummyMiddlewareWrap';

interface Test => {};
my $response = run {
    my $c = shift;
    $c->res->body('OK!');
} HTTP::Request->new( GET => 'http://localhost/' );

our $wrap;
is $main::wrap, 'ok';
is $response->content, 'OK!';
...
die $@ if $@;

