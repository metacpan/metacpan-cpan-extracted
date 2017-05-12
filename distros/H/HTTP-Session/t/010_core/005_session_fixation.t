use strict;
use warnings;
use Test::More;
plan skip_all => 'this test requires HTML::StickyQuery' unless eval "use HTML::StickyQuery; 1;";
plan tests => 3;
use t::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
require HTTP::Session::State::URI;
use HTTP::Response;
use CGI;

my $store = HTTP::Session::Store::Test->new(
    data => {
        bar =>  { }
    },
);

sub {
    my $session = HTTP::Session->new(
        store   => $store,
        state   => HTTP::Session::State::URI->new(),
        request => CGI->new({ sid => 'bar' }),
    );
    is $session->session_id(), 'bar';
}->();

sub {
    my $session = HTTP::Session->new(
        store   => $store,
        state   => HTTP::Session::State::URI->new(),
        request => CGI->new({ sid => 'baz' }),
    );
    ok $session->session_id() ne 'baz', 'no session fixation';
    like $session->session_id(), qr/^[a-z0-9]{32}$/, 'regen session id';
}->();

