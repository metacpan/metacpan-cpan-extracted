#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';

BEGIN {
    eval { 
      require HTTP::StructuredFieldValues; 
      HTTP::StructuredFieldValues->import(qw(encode decode_dictionary decode_list decode_item));
       1; 
    } or do {
        plan skip_all => "HTTP::StructuredFieldValues module not available";
    };
}

use MIME::Base32;
use Tie::IxHash;

sub _h {
  tie my %hash, 'Tie::IxHash', @_;
  return \%hash;
}

# Generated from boolean.json
# Total tests: 11

plan tests => 11;

# Test 1: basic true boolean
subtest "basic true boolean" => sub {
    my $test_name = "basic true boolean";
    my $input = "?1";
    my $expected = { _type => 'boolean', value => 1 };
    my $canonical = $input;
    
    my $result = eval { decode_item($input); };
    
    if ($@) {
        fail($test_name);
        diag("Decode error: $@");
        diag("Input was: $input");
    } else {
        is_deeply($result, $expected, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($expected));
            diag("Input was: ", $input);
        };
    }
    $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Encode error:", $@);
        diag("Input was: ", explain($expected));
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
};

# Test 2: basic false boolean
subtest "basic false boolean" => sub {
    my $test_name = "basic false boolean";
    my $input = "?0";
    my $expected = { _type => 'boolean', value => 0 };
    my $canonical = $input;
    
    my $result = eval { decode_item($input); };
    
    if ($@) {
        fail($test_name);
        diag("Decode error: $@");
        diag("Input was: $input");
    } else {
        is_deeply($result, $expected, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($expected));
            diag("Input was: ", $input);
        };
    }
    $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Encode error:", $@);
        diag("Input was: ", explain($expected));
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
};

# Test 3: unknown boolean
{
    my $test_name = 'unknown boolean - must fail';
    my $input = "?Q";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 4: whitespace boolean
{
    my $test_name = 'whitespace boolean - must fail';
    my $input = "? 1";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 5: negative zero boolean
{
    my $test_name = 'negative zero boolean - must fail';
    my $input = "?-0";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 6: T boolean
{
    my $test_name = 'T boolean - must fail';
    my $input = "?T";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: F boolean
{
    my $test_name = 'F boolean - must fail';
    my $input = "?F";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: t boolean
{
    my $test_name = 't boolean - must fail';
    my $input = "?t";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: f boolean
{
    my $test_name = 'f boolean - must fail';
    my $input = "?f";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: spelled-out True boolean
{
    my $test_name = 'spelled-out True boolean - must fail';
    my $input = "?True";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: spelled-out False boolean
{
    my $test_name = 'spelled-out False boolean - must fail';
    my $input = "?False";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

