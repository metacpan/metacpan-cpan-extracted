#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
plan tests => 7;
# test for Jifty::DBI::Filter class only
# create new t/06filter_*.t files for specific filters

# DB independat tests
use_ok('Jifty::DBI::Filter');
my $filter = new Jifty::DBI::Filter;
isa_ok( $filter, 'Jifty::DBI::Filter' );
is( $filter->column, undef, "empty column value" );
is( $filter->value_ref, undef, "empty value reference" );
is( $filter->handle, undef, "empty handle" );

$filter->column( 'my column' );
is( $filter->column, 'my column', "successfuly set column" );
$filter->value_ref( 'my value_ref' );
is( $filter->value_ref, 'my value_ref', "successfuly set value_ref" );

# methods do nothing, but just in case
$filter->decode;
$filter->encode;

1;
