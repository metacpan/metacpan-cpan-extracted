#!/usr/bin/env perl
# Langertha::Holmgang::Error. Claims: throw dies with the object (not a string),
# it reads "field: reason" as text, caught tells a refusal from any other error.
use strict;
use warnings;
use Test::More;
use Test::Fatal qw( exception );

use Langertha::Holmgang::Error;

my $E = 'Langertha::Holmgang::Error';

my $err = exception { $E->throw( 'cases/c1.yaml: rules[0].regex' => 'invalid regular expression' ) };
isa_ok( $err, $E, 'throw dies with the object' );
is( $err->field, 'cases/c1.yaml: rules[0].regex', 'field' );
is( $err->reason, 'invalid regular expression', 'reason' );
is( "$err", 'cases/c1.yaml: rules[0].regex: invalid regular expression', 'as text: field: reason' );
is( $E->caught($err), $err, 'caught: a refusal' );
is( $E->caught("plain death\n"), undef, 'caught: a string is no refusal' );
is( $E->caught( bless {}, 'Other::Error' ), undef, 'caught: another object is no refusal' );
is( $E->caught(undef), undef, 'caught: nothing' );
like( exception { $E->new( field => 'x' ) }, qr/reason/, 'reason is required' );
ok( $err eq 'cases/c1.yaml: rules[0].regex: invalid regular expression', 'compares as its text' );

done_testing;
