#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

use MVC::Neaf;

my @warn;
$SIG{__WARN__} = sub { push @warn, shift };

neaf pre_route => sub {
    my $req = shift;
    $req->param( pre => 1 )
        and die "preamble";
};
get '/kaboom' => sub {
    my $req = shift;

    die "foobared!"
        unless $req->param( tpl => 1 );

    return { -view => 'TT', -template => \'[% IF kaboom %]' };
};

my @ret;
my $body;

note "EXPECTION IN HANDLER";
@ret = neaf->run_test('/kaboom');
is $ret[0], 500, "tpl error = status 500";
note $ret[2];
$body = eval { decode_json( $ret[2] ) };
is ref $body, 'HASH', "jsoned hash returned";
is $body->{error}, 500, "Error 500 inside";
ok $body->{req_id}, "req_id present";
is $body->{reason}, undef, "no reason in reply";

is scalar @warn, 1, "1 warning reported";
like $warn[0], qr/ERROR.*\Q$body->{req_id}\E.*foobared/
    , "req_id and original error retained";

note "WARN: $_" for @warn;
undef $body;
@warn = ();

note "EXPECTION IN TEMPLATE";
@ret = neaf->run_test('/kaboom?tpl=1');
is $ret[0], 500, "tpl error = status 500";
note $ret[2];
$body = eval { decode_json( $ret[2] ) };
is ref $body, 'HASH', "jsoned hash returned";
is $body->{error}, 500, "Error 500 inside";
ok $body->{req_id}, "req_id present";
# TODO 0.25 Also show reason via Exception
# like $body->{reason}, qr/render/, "reason present";

is scalar @warn, 1, "1 warning reported";
like $warn[0], qr/ERROR.*\Q$body->{req_id}\E/, "req_id retained";

note "WARN: $_" for @warn;
undef $body;
@warn = ();

done_testing;
