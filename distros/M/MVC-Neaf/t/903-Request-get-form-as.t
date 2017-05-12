#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new(
    cached_params => { x => 42 },
);

my @warn;
local $SIG{__WARN__} = sub {
    $_[0] =~ /DEPRECATED/ or die $_[0];
    push @warn, shift;
};

my $form_h = eval {
    $req->get_form_as_hash( x => '\d+', y => '\d+' );
};
is $form_h, undef, "No way";
like $@, qr/use MVC::Neaf::X::Form/, 'Work around suggested';
note $@;

is scalar @warn, 0, "no warns issued";
note "WARN: $_" for @warn;

done_testing;
