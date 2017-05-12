#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::X::Session::Cookie;

my $sess = MVC::Neaf::X::Session::Cookie->new( key => 'my secret' );

my $hash = $sess->save_session( "137", { foo => 42 } );

is join( ",", sort keys %$hash ), "expire,id", "save: Keys as expected";

my $raw = $hash->{id};

like( $hash->{expire}, qr/^\d+$/, "Expiration was not set => some digits" );

note "Session saved as: $raw";

ok( !$sess->load_session( "137" ), "No session loaded for given id" );

my $data = $sess->load_session( $raw );
is_deeply( $data->{data}, { foo=>42 }, "Data round-trip" );

$raw =~ s/([A-Za-z])/$1^('A'^'a')/e; # Flip 1 bit in cookie

note "Session changed to: $raw";

ok( !$sess->load_session( $raw ), "No session loaded if tampered with" );

done_testing;
