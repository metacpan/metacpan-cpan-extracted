use strict;
use warnings;
use Test::More tests => 7;
use CGI;
use Test::Requires 'HTML::StickyQuery';
use HTTP::Session;
use HTTP::Session::State::Cookie;
use HTTP::Session::State::URI;
use HTTP::Session::Store::Test;

# -------------------------------------------------------------------------
# state::cookie

do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::Cookie->new(),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    my $res = [200, ['Content-Type' => 'text/plain'], ['ok']];
    $session->response_filter($res);
    is scalar(@{$res->[1]}), 4;
    is $res->[1]->[2], 'Set-Cookie';
    like $res->[1]->[3], qr{http_session_sid=[^;]+; path=/};
};

# -------------------------------------------------------------------------
# state::uri

do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::URI->new(),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    my $res = [302, ['Location' => 'http://gp.ath.cx/'], ['']];
    $session->response_filter($res);
    is scalar(@{$res->[1]}), 2, 'redirect';
    like $res->[1]->[1], qr{^http://gp\.ath\.cx/\?sid=.+$};
    like $res->[1]->[1], qr{^http://gp\.ath\.cx/\?sid=.+$};
};

do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::URI->new(),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    my $res = [200, ['Content-Type' => 'text/html'], ['<a href="/foo">ooo</a>']];
    $session->response_filter($res);
    like $res->[2]->[0], qr{^<a href="/foo\?sid=.+">ooo</a>$};
};

