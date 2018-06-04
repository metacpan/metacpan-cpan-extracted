#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf->route( '/' => sub { +{} }, -view => 'JS' );

my $trace;
neaf->add_hook( pre_reply => sub {
    my $req = shift;
    $trace = $req->reply->{-content};
} );

my @warn;
$SIG{__WARN__} = sub { push @warn, shift };
my ($status) = neaf->run_test( {} );

is ($status, 200, "Http ok" );
is ($trace, '{}', "Hook has seen rendered content" );
is (scalar @warn, 0, "No warnings" );
diag "WARN: $_" for @warn;

done_testing;
