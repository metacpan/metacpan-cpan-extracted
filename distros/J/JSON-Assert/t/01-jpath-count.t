#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use JSON::Assert;
use JSON;
use FindBin qw($Bin);
use lib "$Bin";

$JSON::Assert::VERBOSE = 1;

require 'data.pl';

my $json = decode_json( json() );

my $tests_ok = [
   {
       jpath => '$..Error',
       count => 0,
       name  => 'Error in response',
   },
   {
       jpath => '$.catalog.cd',
       count => 3,
       name  => 'Three CDs available',
   },
   {
       jpath => '$..cd',
       count => 3,
       name  => 'Three CDs available everywhere',
   },
   {
       jpath => '$..title',
       count => 3,
       name  => 'Three titles found',
   },
   {
       jpath => '$..rating',
       count => 2,
       name  => 'Only two ratings',
   },
   {
       jpath => '$..genre',
       count => 2,
       name  => 'Two genres found',
   },
];

my $tests_fail = [
   {
       jpath => '$..price',
       count => 2,
       name  => 'Three prices, not two',
   },
];

my $json_assert = JSON::Assert->new();

foreach my $t ( @$tests_ok ) {
    ok( $json_assert->is_jpath_count($json, $t->{jpath}, $t->{count}), $t->{name} )
	    or diag($json_assert->error);
}

foreach my $t ( @$tests_fail ) {
    ok( !$json_assert->is_jpath_count($json, $t->{jpath}, $t->{count}), $t->{name} );
}
