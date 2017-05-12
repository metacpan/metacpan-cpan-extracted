use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
use CGI;
use HTTP::Session::State::MobileAgentID;
use HTTP::Response;
use HTTP::Request;

plan tests => 6;

my $cidr = Net::CIDR::MobileJP->new('t/data/cidr.yaml');

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa'
    );
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::MobileAgentID->new(
            mobile_agent => HTTP::MobileAgent->new(),
            check_ip => 0,
            cidr     => $cidr,
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    is $session->session_id(), 'fooobaa', 'permissive';
    my $res = HTTP::Response->new();
    $session->response_filter($res); # nop.
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa',
    );
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::MobileAgentID->new(
            mobile_agent => HTTP::MobileAgent->new(),
            check_ip => 0,
            cidr     => $cidr,
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    is $session->session_id(), 'fooobaa', 'permissive';
    my $res = HTTP::Response->new();
    $session->response_filter($res); # nop.
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa',
        REMOTE_ADDR     => '192.168.1.1',
    );
    throws_ok {
        HTTP::Session->new(
            state => HTTP::Session::State::MobileAgentID->new(
                mobile_agent => HTTP::MobileAgent->new(),
                cidr     => $cidr,
            ),
            store   => HTTP::Session::Store::Test->new(),
            request => CGI->new(),
        )
    } qr/invalid ip\(192\.168\.1\.1, HTTP::MobileAgent::DoCoMo=HASH\(0x[a-z0-9]+\), fooobaa\)/;
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
    );
    my $state = HTTP::Session::State::MobileAgentID->new(
        mobile_agent => HTTP::MobileAgent->new(),
        check_ip     => 0,
        cidr     => $cidr,
    );
    throws_ok { $state->get_session_id() } qr/cannot detect mobile id/;
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'MOZILLA',
    );
    my $state = HTTP::Session::State::MobileAgentID->new(
        mobile_agent => HTTP::MobileAgent->new(),
        check_ip     => 0,
        cidr     => $cidr,
    );
    throws_ok { $state->get_session_id() } qr{this module only supports docomo/softbank/ezweb};
}->();

sub {
    my $state = HTTP::Session::State::MobileAgentID->new(
        check_ip => 0,
    );
    my $h = HTTP::Headers->new;
    $h->header( 'User-Agent' => 'DoCoMo/1.0/D504i/c10/TJ' );
    $h->header( 'X-DCMGUID' => 'fooobar' );
    my $r = HTTP::Request->new( 'GET', '/', $h );
    is $state->get_session_id( $r ), 'fooobar';
}->();
