#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use DateTime;

use_ok( "HTML::FormHandler::Field::Date::Infinite" );

note( "Testing a normal DT" );

my $field = new_ok( "HTML::FormHandler::Field::Date::Infinite",
                    [ name => "datetest"] );

lives_ok sub { $field->build_result },
    "build_result succeeds";

lives_ok sub { $field->_set_input( "2013-01-01" ) },
    "input can be set";

ok( $field->validate_field, "default date format passes" );
isa_ok( $field->value, "DateTime", "value is a DateTime" );
is( $field->fif, $field->value->strftime('%Y-%m-%d'), "fif ok" );



## with -?inf input


## future

note( "Testing future DT" );

my $dt_fut_ref = DateTime::Infinite::Future->new;

my $field2 = new_ok( "HTML::FormHandler::Field::Date::Infinite",
                    [ name => "datetest"] );

lives_ok sub { $field2->build_result },
    "build_result succeeds";

note( "Future DT from inf input" );

lives_ok sub { $field2->_set_input( "inf" ) }, "input can be set";
lives_ok sub { $field2->validate_field }, "field2 can run validated";
ok( $field2->validated, "field2 is valid" );
is( $field2->value, "".$dt_fut_ref, "future datetime deflation" );
isa_ok( $field2->value, "DateTime", "value from inf input" );

$field2->reset_result;

note( "Future DT from Infinite input" );

$field2->_set_input( "Infinite" );
lives_ok sub { $field2->validate_field },
    "field2 can run validated on Infinite input";
ok( $field2->validated, "field2 is also now valid" );
is( $field2->value, "".$dt_fut_ref, "future datetime deflation again" );
is( $field2->fif, "Infinite", "fif for Infinite" );
isa_ok( $field2->value, "DateTime", "value from Infinite input" );

$field2->reset_result;

note( "Future DT from inf input again" );

$field2->_set_input( "inf" );
lives_ok sub { $field2->validate_field },
    "field2 can run validated on inf input";
ok( $field2->validated, "field2 is also now valid" );
is( $field2->value, "".$dt_fut_ref, "future datetime deflation again" );
is( $field2->fif, "inf", "fif for inf" );
isa_ok( $field2->value, "DateTime", "value from inf input" );

## past

my $dt_past_ref = DateTime::Infinite::Past->new;

note( "Testing past DT" );

my $field3 = new_ok( "HTML::FormHandler::Field::Date::Infinite",
                    [ name => "datetest"] );

lives_ok sub { $field3->build_result },
    "build_result succeeds";

note( "Past DT from -inf input" );

lives_ok sub { $field3->_set_input( "-inf" ) }, "input can be set";
lives_ok sub { $field3->validate_field }, "field3 can run validated";
ok( $field3->validated, "field3 is valid" );
is( $field3->value, "$dt_past_ref", "past datetime deflation" );
isa_ok( $field3->value, "DateTime", "value from -inf input" );

$field3->reset_result;

lives_ok sub { $field3->_set_input( "-Infinite" ) }, "input can be set";
lives_ok sub { $field3->validate_field }, "field3 can run validated";
ok( $field3->validated, "field3 is valid" );
is( $field3->value, "$dt_past_ref", "past datetime deflation" );
is( $field3->fif, "-Infinite", "fif for -Infinite" );
isa_ok( $field3->value, "DateTime", "value from -Infinite input" );




done_testing;
