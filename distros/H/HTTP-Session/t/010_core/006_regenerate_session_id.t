use strict;
use warnings;
use Test::More tests => 15;
use HTTP::Session;
use HTTP::Session::State::Test;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Test;
use CGI;

my $store = HTTP::Session::Store::Test->new(
    data => {
        FOOBAR => {
            foo => 'bar',
        }
    }
);

sub gen_session ($) {
    my $sid = shift;
    HTTP::Session->new(
        state => HTTP::Session::State::Test->new(session_id => $sid),
        store => $store,
        request => CGI->new(),
    );
}

sub {
    my $session;
    
    $session= gen_session('FOOBAR');
    is $session->get('foo'), 'bar';
    is $session->session_id, 'FOOBAR';
    $session->regenerate_session_id();
    $session->set('hoge', 'fuga');
    like $session->session_id, qr/^[a-z0-9]{32}$/;
    my $newsessid = $session->session_id;
    undef $session;

    $session = gen_session('FOOBAR');
    is $session->get('foo'), 'bar';
    is $session->get('hoge'), undef, 'do not pass to old session';
    undef $session;

    $session = gen_session($newsessid);
    is $session->get('foo'), 'bar', 'new session contains old session data';
    is $session->get('hoge'), 'fuga', 'new session contains new session data';
    undef $session;
}->();


sub {
    my $session;
    
    $session= gen_session('FOOBAR');
    is $session->get('foo'), 'bar';
    is $session->session_id, 'FOOBAR';
    $session->regenerate_session_id(1);
    $session->set('hoge', 'fuga');
    like $session->session_id, qr/^[a-z0-9]{32}$/;
    my $newsessid = $session->session_id;
    undef $session;

    $session = gen_session('FOOBAR');
    is $session->get('foo'), undef;
    is $session->get('hoge'), undef, 'do not pass to old session';
    like $session->session_id, qr/^[a-z0-9]{32}$/;
    undef $session;

    $session = gen_session($newsessid);
    is $session->get('foo'), 'bar', 'new session contains old session data';
    is $session->get('hoge'), 'fuga', 'new session contains new session data';
    undef $session;
}->();

