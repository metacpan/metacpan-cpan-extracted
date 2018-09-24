#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'test.example.com;one=two three=four (comment) five=six' );

my $Found;

$Found = $Parsed->search({ 'isa' => 'entry', 'key' => 'one', 'has' => [ { 'isa' => 'subentry', 'key' => 'three' } ] });
is( $Found->as_string(), 'one=two three=four (comment) five=six', 'Found subentry' );

$Found = $Parsed->search({ 'isa' => 'entry', 'key' => 'one', 'has' => [ { 'isa' => 'subentry', 'key' => 'twenty' } ] });
is( scalar @{$Found->children() }, 0, 'Did not find missing subentry' );

$Found = $Parsed->search({ 'isa' => 'entry', 'key' => 'one', 'has' => [ { 'isa' => 'subentry', 'key' => 'twenty' }, { 'isa' => 'subentry', 'key' => 'three' } ] });
is( scalar @{$Found->children() }, 0, 'Did not find missing subentry in multi search' );

$Found = $Parsed->search({ 'isa' => 'entry', 'key' => 'one', 'has' => [ { 'isa' => 'subentry', 'key' => 'three', 'has' => [ { 'value' => 'four' } ] } ] });
is( $Found->as_string(), 'one=two three=four (comment) five=six', 'Found subentry with recursive search' );

done_testing();

