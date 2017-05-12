#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(neaf_err);
use MVC::Neaf::Exception;

my $res = eval {
    neaf_err(500);
    1;
};
is ($@, '', "Plain text = no die");
is ($res, 1, "Plain text = no die (2)");

$res = eval {
    neaf_err(MVC::Neaf::Exception->new());
    1;
};
my $err = $@;
is ($res, undef, "Neaf error => die");
is (ref $err, 'MVC::Neaf::Exception', "Type holds");
is ($err->{-status}, 500, "Unknown error = status 500");

is_deeply( $err->TO_JSON, {-status=>500}, "json works");

done_testing;
