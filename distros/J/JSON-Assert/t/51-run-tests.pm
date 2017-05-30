#!/usr/bin/perl

use strict;
use warnings;

use Test::JSON::Assert qw(no_plan);
use FindBin qw($Bin);
use lib "$Bin";
use JSON;

require 'data.pl';

my $json = decode_json( json() );

my $tests_pass = [
   {
       jpath => '$..Error',
       count => 0,
       name  => 'No error in response',
   },
   {
       jpath => '$..price',
       count => 3,
       name  => 'Three prices found',
   },
];

foreach my $t ( @$tests_pass ) {
    is_jpath_count($json, $t->{jpath}, $t->{count}, $t->{name} );
}
