use strict;
use warnings;
use Test::More tests => 3;
use CGI;
use HTTP::Session;
use HTTP::Session::State::GUID;
use HTTP::Session::Store::Test;
use Net::CIDR::MobileJP;

# -------------------------------------------------------------------------
# state::guid

local %ENV = (
    HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
    HTTP_X_DCMGUID  => 'fooobaa',
    REMOTE_ADDR     => '192.168.1.1',
);
my $ma = HTTP::MobileAttribute->new();
do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::GUID->new(
            mobile_attribute => $ma,
            check_ip => 0,
            cidr     => Net::CIDR::MobileJP->new('t/data/cidr.yaml'),
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    my $res = [302, ['Location' => 'http://gp.ath.cx/'], ['']];
    $session->response_filter($res);
    is scalar(@{$res->[1]}), 2, 'redirect';
    is $res->[1]->[1], 'http://gp.ath.cx/?guid=ON';
};

do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::GUID->new(
            mobile_attribute => $ma,
            check_ip => 0,
            cidr     => Net::CIDR::MobileJP->new('t/data/cidr.yaml'),
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    my $res = [200, ['Content-Type' => 'text/html'], ['<a href="/foo">ooo</a>']];
    $session->response_filter($res);
    like $res->[2]->[0], qr{^<a href="/foo\?guid=ON">ooo</a>$};
};
