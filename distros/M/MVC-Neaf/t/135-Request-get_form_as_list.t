#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my @warn;
$SIG{__WARN__} = sub {
    diag "WARN: ", $_[0];
    push @warn, $_[0];
};

my $req = MVC::Neaf::Request->new(
    cached_params => { foo => 42, bar => 137 },
);

is_deeply [$req->get_form_as_list( '\d\d', qw(foo bar baz) )]
    , [42, undef, undef], "form w/o default";

is_deeply [$req->get_form_as_list( ['\d\d', 0], qw(foo bar baz) )]
    , [42, 0, 0], "form with default";

is scalar @warn, 0, "No warnings issued";

done_testing;
