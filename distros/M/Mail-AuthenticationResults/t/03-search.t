#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed = Mail::AuthenticationResults::Parser->new()->parse( 'test.example.com;one=two three=four (comment) five=six' );

my $Key = $Parsed->search({ 'key' => 'three' });
is( $Key->as_string(), 'three=four (comment)', 'Found key' );

my $Value = $Parsed->search({ 'value' => 'six' });
is ( $Value->as_string, 'five=six', 'Found value' );

my $NoKey = $Parsed->search({ 'key' => 'four' });
is( $NoKey->as_string(), '', 'Not found key' );

my $NoValue = $Parsed->search({ 'value' => 'five' });
is ( $NoValue->as_string, '', 'Not found value' );

my $Entry = $Parsed->search({ 'isa' => 'entry' });
is ( $Entry->as_string(), 'one=two three=four (comment) five=six', 'Entry search' );
is ( scalar @{$Entry->children()}, 1, 'One found' );

my $SubEntry = $Parsed->search({ 'isa' => 'subentry' });
is ( $SubEntry->as_string(), "three=four (comment);\nfive=six", 'SubEntry search' );
is ( scalar @{$SubEntry->children()}, 2, 'Two found' );

is( scalar @{ $SubEntry->search({ 'isa' => 'entry' })->children() }, 0, 'Entry not found under SubEntry' );

my $Comment = $Parsed->search({ 'isa' => 'comment' });
is ( $Comment->as_string(), '(comment)', 'Comment search' );
is ( scalar @{$Comment->children()}, 1, 'One found' );

is( scalar @{ $Comment->search({ 'isa' => 'entry' })->children() }, 0, 'Entry not found under Comment' );
is( scalar @{ $Comment->search({ 'isa' => 'subentry' })->children() }, 0, 'SubEntry not found under Comment' );

done_testing();

