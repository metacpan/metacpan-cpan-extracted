#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

# portable carp pointers
my @line = map { file_line( __LINE__ + $_ ) } 0..4;
get      '/my'  => sub { +{-content => "OLD"} };
post+put '/my'  => sub { +{-content => "OLD"} };
patch    '/my'  => sub { +{-content => "OLD"} };
get      '/our' => sub { +{-content => "OLD"} }, tentative => 1;
put+post '/our' => sub { +{-content => "OLD"} }, tentative => 1;

note "default override =  no go";
warnings_like{
    eval {
        any['get', 'post'], '/my' => sub { +{-content => 'NEW'} };
    };
    note $@;
    like $@, qr#duplicate#, "Dupe handler = no go";
    like $@, qr#/my.*at $line[1] *.?.?GET#, "Correct source attr (get)";
    like $@, qr#/my.*at $line[2] *.?.?POST#, "Correct source attr (post)";
} [], "... and no warnings";

warnings_like{
    eval {
        patch+put '/my' => sub { +{-content => 'NEW' } }, override => 1;
    };
    ok !$@, "No exception for override"
        or diag "override dies: $@";
    # NOTE `put` is executed before `patch`, therefore warnings in that order
} [qr(Overriding.*/my.*at $line[2]), qr(Overriding.*/my.*at $line[3])],
     "override still with a warning";

warnings_like {
    eval {
        push @line, file_line( __LINE__+1 );
        put '/our' => sub { +{-content => 'NEW' } };
    };
    ok !$@, "No exception for tentative"
        or diag "tentative override dies: $@";
} [], "... and no warnings";

warnings_like {
    eval {
        get '/my' => sub { +{-content => 'MORE NEW' } }, tentative => 1;
    };
    ok !$@, "Already defined + tentative = nothing happens"
        or diag "tentative override dies: $@";
} [], "... and no warnings";

warnings_like {
    eval {
        put '/our' => sub { +{-content => 'MORE NEW' } };
    };
    like $@, qr#duplicate#, "Dupe handler = no go";
    like $@, qr#/our.*at $line[5] *.?.?PUT#, "Correct source attr (second over)";
} [], "... and no warnings";

note "TEST RESULTING ROUTES";

warnings_like {
    is neaf->run_test( '/my', method => 'GET' ),   "OLD", "my  get  = old";
    is neaf->run_test( '/my', method => 'POST' ),  "OLD", "my  post = old";
    is neaf->run_test( '/my', method => 'PUT' ),   "NEW", "my  put  = new";
    is neaf->run_test( '/my', method => 'PATCH' ), "NEW", "my  patch = new";

    is neaf->run_test( '/our', method => 'GET' ),  "OLD", "our get  = old";
    is neaf->run_test( '/our', method => 'POST' ), "OLD", "our post = old";
    is neaf->run_test( '/our', method => 'PUT' ),  "NEW", "our put  = new";
} [], "...and still no warnings";

done_testing;

sub file_line {
    my $line = shift;
    my $str = __FILE__." line ".$line;
    return qr/\Q$str\E/;
};
