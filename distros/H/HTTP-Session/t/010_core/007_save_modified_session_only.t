use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Session;
use HTTP::Session::Store::OnMemory;
use HTTP::Session::Store::Test;
use HTTP::Session::State::Test;
use HTTP::Session::State::Null;

my $store = HTTP::Session::Store::OnMemory->new();
my $state = HTTP::Session::State::Null->new();

subtest 'no insert since save_modified_session_only is 1 and no modified' => sub {
    my $session = HTTP::Session->new(
        store => $store,
        state => $state,
        request => {},
        save_modified_session_only => 1,
    );
    my $session_id = $session->session_id;
    $session->finalize();
    ok(!$store->data->{$session_id});
};

subtest 'save_modified_session_only=1 and modified' => sub {
    my $session = HTTP::Session->new(
        store => $store,
        state => $state,
        request => {},
        save_modified_session_only => 1,
    );
    my $session_id = $session->session_id;
    $session->set('foo' => 'bar');
    $session->finalize();
    ok($store->data->{$session_id});
};

subtest 'save_modified_session_only=0 and no modified' => sub {
    my $session = HTTP::Session->new(
        store => $store,
        state => $state,
        request => {},
    );
    my $session_id = $session->session_id;
    $session->finalize();
    ok($store->data->{$session_id});
};

subtest 'save_modified_session_only=0 and modified' => sub {
    my $session = HTTP::Session->new(
        store => $store,
        state => $state,
        request => {},
    );
    my $session_id = $session->session_id;
    $session->set('foo' => 'bar');
    $session->finalize();
    ok($store->data->{$session_id});
};

done_testing;

