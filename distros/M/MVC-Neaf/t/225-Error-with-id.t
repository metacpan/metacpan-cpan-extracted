#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

use MVC::Neaf;
my $capture;

get '/foo' => sub {
    $capture = shift;

    die "Foobared";
};

get '/tpl' => sub {
    $capture = shift;

    return {};
}, -view => 'TT', -template => \'[% IF deliberately_broken %]';

{
    undef $capture;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };

    my ($st, $head, $content) = neaf->run_test( "/foo" );
    my $id = $capture->id;

    is $st, 500, "Status 500 if died";
    like $head->header("content-type"), qr(^text/html\b), "HTML in reply";

    like $content, qr(<span>500</span>), "Status preserved";
    like $content, qr(<b>\Q$id\E</b>), "Id sent to user";

    is scalar @warn, 1, "1 warning issued";
    like $warn[0], qr/\Q$id\E/, "req_id in log";

    note "WARN: $_" for @warn;
}

{
    undef $capture;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };

    my ($st, $head, $content) = neaf->run_test( "/tpl" );
    my $id = $capture->id;

    is $st, 500, "Status 500 if died";
    like $head->header("content-type"), qr(^text/html\b), "HTML in reply";

    like $content, qr(<span>500</span>), "Status preserved";
    like $content, qr(<b>\Q$id\E</b>), "Id sent to user";
    # TODO 0.25 must also explain reason via Exception
    # like $ref->{reason}, qr/render/i, "Rendering error or smth";

    is scalar @warn, 1, "1 warning issued";
    like $warn[0], qr/\Q$id\E/, "req_id in log";

    note $content;
    note "WARN: $_" for @warn;
}

done_testing;

