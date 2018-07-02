#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

{
    package My::Sess;
    use parent qw(MVC::Neaf::X::Session);

    sub save_session {
        my ($self, $id, $data) = @_;

        return { id => $id };
    };
    my %out = (
        broken  => [],
        empty   => '',
        normal  => { data => { foo => 42 } },
        refresh => { data => { foo => 42 }, id => "changed" },
        weird   => { weird => 'key present' },
    );
    sub load_session {
        my ($self, $id) = @_;

        return $out{$id};
    };
};

neaf session => My::Sess->new, cookie => 'sess';
get '/sess' => sub {
    my $req = shift;

    return { -content => $req->session->{foo} || '(undef)' };
};

subtest "Normal session" => sub {
    my ($status, $head, $content) = neaf->run_test(
        '/sess', cookie => { sess => 'normal' } );

    is $status, 200, "Normal session";
    is $head->header("Set-Cookie"), undef, "No set cookie needed";
    is $content, 42, "Data pass through";
};

subtest "Refresh session" => sub {
    my ($status, $head, $content) = neaf->run_test(
        '/sess', cookie => { sess => 'refresh' } );

    is $status, 200, "Normal session";
    like $head->header("Set-Cookie"), qr/sess=changed/, "Set cookie needed";
    is $content, 42, "Data pass through";
};

subtest "Garbage data" => sub {
    warnings_like {
        my ($status, $head, $content) = neaf->run_test(
            '/sess', cookie => { sess => 'broken' } );

        is $status, 500, "Getting session failed";
    } qr/My::Sess->load_session.*HASH.*ARRAY/, "Bad session logged";
};

subtest "Weird data" => sub {
    warnings_like {
        my ($status, $head, $content) = neaf->run_test(
            '/sess', cookie => { sess => 'weird' } );

        is $status, 200, "Getting session failed";
        is $content, "(undef)", "Nothing loaded";
    } qr/My::Sess->load_session.*keys.*weird/, "Bad session logged";
};


done_testing;
