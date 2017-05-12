use strict;
use warnings;
use Test::More tests => 3;
use HTTP::Session;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Null;
use CGI;

sub {
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::Null->new,
        store => HTTP::Session::Store::Null->new,
        request => CGI->new(),
    );
    like $session->_generate_session_id, qr/^[a-z0-9]{32}$/;
}->();

sub {
    my $session = HTTP::Session->new(
        state      => HTTP::Session::State::Null->new,
        store      => HTTP::Session::Store::Null->new,
        request    => CGI->new(),
        sid_length => 10,
    );
    like $session->_generate_session_id, qr/^[a-z0-9]{10}$/;
}->();

sub {
    local $ENV{UNIQUE_ID} = 'hogehogeoe';
    my $session = HTTP::Session->new(
        state      => HTTP::Session::State::Null->new,
        store      => HTTP::Session::Store::Null->new,
        request    => CGI->new(),
        sid_length => 10,
    );
    like $session->_generate_session_id, qr/^[a-z0-9]{10}$/;
}->();
