use strict;
use warnings;
use Test::More tests => 1;
use t::Utils;
use HTTP::Engine::Compat;
use HTTP::Request;

run_engine {
    my $c = shift;
    can_ok $c->req, 'context';
} HTTP::Request->new( 'GET', '/', );

