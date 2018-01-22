#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(neaf_err);
use MVC::Neaf::Exception;

my $res = eval {
    neaf_err("Failed here at /foo/bar line 123");
    1;
};
is ($@, '', "Plain text = no die");
is ($res, 1, "Plain text = no die (2)");

my $line = __LINE__;
$res = eval {
    neaf_err(MVC::Neaf::Exception->new());
    1;
};
my $err = $@;
is ($res, undef, "Neaf error => die");
is (ref $err, 'MVC::Neaf::Exception', "Type holds");
is ($err->{-status}, 500, "Unknown error = status 500");
ok $err->is_sudden, "Unknown error = is_sudden";

is_deeply( $err->TO_JSON, {
    -status  => 500,
    -sudden  => 1,
    -file    => __FILE__,
    -line    => $line + 2,
    -reason  => 'unknown error',
}, "json works");

my $err404 = MVC::Neaf::Exception->new(404);
ok !$err404->is_sudden, "Not sudden error";
is  $err404->status, 404, "status preserved";

done_testing;
