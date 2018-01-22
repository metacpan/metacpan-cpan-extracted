#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

warnings_like {

note "TESTING error_template()";
my $n = MVC::Neaf->new;
$n->load_view( TT => 'TT' );
$n->set_error_handler( 404, { -template => \'NotFounded [% status %]', -view => 'TT' } );
is_deeply ( $n->run->({})->[0], 404, "Status preserved" );
is_deeply ( $n->run->({})->[2], [ "NotFounded 404" ], "Template worked" );

note "TESTING on_error()";
my @log;
$n->on_error( sub { push @log, $_[1] } );
$n->route( '/' => sub { die "Fubar" } );
warnings_like {
    $n->run->({});
} [ qr/req_id=.*Fubar/ ], "Warn despite on_error handler";
is (scalar @log, 1, "1 error issued");
like ($log[0], qr/^Fubar\s/s, "Error correct" );
note "ERROR: $_" for @log;

note "TESTING set_default()";
my @warn;
$SIG{__WARN__} = sub {push @warn, shift};
$n = MVC::Neaf->new;
$n->load_view( TT => 'TT' );
$n->set_default( -template => \'NotFounded2', -view => 'TT' );
$n->route( '/' => sub { +{} } );
is ( $n->run_test({}), "NotFounded2", "Template worked" );
is (scalar @warn, 1, "1 warning issues" );
like ($warn[0], qr/DEPRECATED/, "deprecated" );
note "WARN: $_" for @warn;
delete $SIG{__WARN__};

note "TESTING duplicate route protection";
eval {
    $n->route( '/' => sub { +{ try => 2 } } );
};
like( $@, qr/^MVC::Neaf->route.*duplicat/, "Error starts with Neaf");
note $@;

} [], "And no warnings overall";

done_testing;

