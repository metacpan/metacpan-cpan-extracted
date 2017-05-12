#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

get '/' => sub {
    my $req = shift;

    return { foo => 42 };
}, -view => 'JS';

neaf pre_route => sub {
    my $req = shift;
    $req->set_default( -status => 418 );
};

my @warn;
local $SIG{__WARN__} = sub { push @warn, shift };
my ($status, $head, $content) = neaf->run_test('/');

is ($status, 418, "Default applied");
is ($content, '{"foo":42}', "Content as expected");

is (scalar @warn, 1, "1 warning issued");
like ($warn[0], qr/set_default.*DEPRECATED/, "Deprecated");

note "WARN: $_" for @warn;

done_testing;
