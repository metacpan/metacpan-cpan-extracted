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

# Generated from binary.json
# Total tests: 14

plan tests => 14;

# Test 1: basic binary
subtest "basic binary" => sub {
    my $test_name = "basic binary";
    my $input = ":aGVsbG8=:";
    my $expected = { _type => 'binary', value => decode_base32('NBSWY3DP') };
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

# Test 2: empty binary
subtest "empty binary" => sub {
    my $test_name = "empty binary";
    my $input = "::";
    my $expected = { _type => 'binary', value => decode_base32('') };
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

# Test 3: padding at beginning
{
    my $test_name = 'padding at beginning - must fail';
    my $input = ":=aGVsbG8=:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 4: padding in middle
{
    my $test_name = 'padding in middle - must fail';
    my $input = ":a=GVsbG8=:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 5: bad padding
{
    my $test_name = 'bad padding - can fail';
    my $input = ":aGVsbG8:";
    
    eval { decode_item($input); };
    pass($test_name); # Can fail tests always pass
}

# Test 6: bad padding dot
{
    my $test_name = 'bad padding dot - must fail';
    my $input = ":aGVsbG8.:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: bad end delimiter
{
    my $test_name = 'bad end delimiter - must fail';
    my $input = ":aGVsbG8=";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: extra whitespace
{
    my $test_name = 'extra whitespace - must fail';
    my $input = ":aGVsb G8=:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: all whitespace
{
    my $test_name = 'all whitespace - must fail';
    my $input = ":    :";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: extra chars
{
    my $test_name = 'extra chars - must fail';
    my $input = ":aGVsbG!8=:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: suffix chars
{
    my $test_name = 'suffix chars - must fail';
    my $input = ":aGVsbG8=!:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: non-zero pad bits
{
    my $test_name = 'non-zero pad bits - can fail';
    my $input = ":iZ==:";
    
    eval { decode_item($input); };
    pass($test_name); # Can fail tests always pass
}

# Test 13: non-ASCII binary
subtest "non-ASCII binary" => sub {
    my $test_name = "non-ASCII binary";
    my $input = ":/+Ah:";
    my $expected = { _type => 'binary', value => decode_base32('77QCC') };
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

# Test 14: base64url binary
{
    my $test_name = 'base64url binary - must fail';
    my $input = ":_-Ah:";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

