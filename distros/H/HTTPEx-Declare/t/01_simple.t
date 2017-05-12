use strict;
use warnings;
use lib '.';
use HTTP::Request;
use Test::More;

eval "use HTTP::Engine::Compat;";
plan skip_all => 'this test requires HTTP::Engine::Compat' if $@;

plan tests => 1;

eval <<'...';
use HTTPEx::Declare -Compat;

interface Test => {};
my $response = run {
    my $c = shift;
    $c->res->body('OK!');
} HTTP::Request->new( GET => 'http://localhost/' );

is $response->content, 'OK!';
...

die $@ if $@;

