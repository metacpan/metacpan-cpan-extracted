use strict;
use warnings;
use Test::More tests => 8;
use HTTP::Engine::Compat;
use HTTP::Engine::Compat::Context;
use t::Utils;

do {
    my $res = run_engine {
        my $c = shift;
        $c->res->redirect('/TKSK/');
    } HTTP::Request->new('POST', 'http://d.hatena.ne.jp/');
    is $res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';
    is $res->status, 302;
    is $res->redirect, '/TKSK/';
    is $res->body, '302: Redirect';
};

do {
    my $res = run_engine {
        my $c = shift;
        $c->res->body('OK');
        $c->res->redirect('/TKSK/' => 303);
    } HTTP::Request->new('GET', 'http://d.hatena.ne.jp');
    is $res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';
    is $res->status, 303;
    is $res->redirect, '/TKSK/';
    is $res->body, 'OK';
};
