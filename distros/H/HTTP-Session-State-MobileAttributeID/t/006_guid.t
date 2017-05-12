use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
plan tests => 10;
require HTTP::Session::State::GUID;
use HTTP::Response;
require HTTP::MobileAttribute;
use CGI;

my $state = HTTP::Session::State::GUID->new(
    mobile_attribute => HTTP::MobileAttribute->new('DoCoMo/1.0/D504i/c10/TJ'),
);
ok $state->isa('HTTP::Session::State::MobileAttributeID');

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa'
    );
    my $session = HTTP::Session->new(
        store   => HTTP::Session::Store::Test->new(
            data => {
                fooobaa =>  { }
            },
        ),
        state   => HTTP::Session::State::GUID->new(
            mobile_attribute => HTTP::MobileAttribute->new(),
            check_ip => 0,
        ),
        request => CGI->new(),
    );
    is $session->session_id(), 'fooobaa';

    sub {
        my $res = HTTP::Response->new(200, 'ok', HTTP::Headers->new(), '<a href="/">foo</a>');
        $session->response_filter($res);
        is $res->content, '<a href="/?guid=ON">foo</a>';
    }->();

    sub {
        my $res = HTTP::Response->new(200, 'ok', HTTP::Headers->new(), '<form action="/"></form>');
        $session->response_filter($res);
        is $res->content, qq{<form action="/"><input type="hidden" name="guid" value="ON" /></form>};
    }->();

    sub {
        is $session->html_filter('<form action="/"></form>'), qq{<form action="/"><input type="hidden" name="guid" value="ON" /></form>};
    }->();

    sub {
        my $res = HTTP::Response->new(302, 'ok', HTTP::Headers->new(Location => 'http://example.com/'));
        $session->response_filter($res);
        is $res->header('Location'), q{http://example.com/?guid=ON};
    }->();

    sub {
        is $session->redirect_filter('http://example.com/'), 'http://example.com/?guid=ON';
    }->();

    sub {
        my $res = HTTP::Response->new(404, 'not found');
        $session->response_filter($res);
        ok "not found";
    }->();

    sub {
        my $res = HTTP::Response->new(302, 'no location');
        $session->response_filter($res);
        is $res->code, 302, 'no locaiton';
    }->();

    throws_ok { $session->state->response_filter } qr/missing session_id/;
}->();

