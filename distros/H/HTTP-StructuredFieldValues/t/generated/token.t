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

# Generated from token.json
# Total tests: 6

plan tests => 6;

# Test 1: basic token - item
subtest "basic token - item" => sub {
    my $test_name = "basic token - item";
    my $input = "a_b-c.d3:f%00/*";
    my $expected = { _type => 'token', value => "a_b-c.d3:f%00/*" };
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

# Test 2: token with capitals - item
subtest "token with capitals - item" => sub {
    my $test_name = "token with capitals - item";
    my $input = "fooBar";
    my $expected = { _type => 'token', value => "fooBar" };
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

# Test 3: token starting with capitals - item
subtest "token starting with capitals - item" => sub {
    my $test_name = "token starting with capitals - item";
    my $input = "FooBar";
    my $expected = { _type => 'token', value => "FooBar" };
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

# Test 4: basic token - list
subtest "basic token - list" => sub {
    my $test_name = "basic token - list";
    my $input = "a_b-c3/*";
    my $expected = [ { _type => 'token', value => "a_b-c3/*" } ];
    my $canonical = $input;
    
    my $result = eval { decode_list($input); };
    
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

# Test 5: token with capitals - list
subtest "token with capitals - list" => sub {
    my $test_name = "token with capitals - list";
    my $input = "fooBar";
    my $expected = [ { _type => 'token', value => "fooBar" } ];
    my $canonical = $input;
    
    my $result = eval { decode_list($input); };
    
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

# Test 6: token starting with capitals - list
subtest "token starting with capitals - list" => sub {
    my $test_name = "token starting with capitals - list";
    my $input = "FooBar";
    my $expected = [ { _type => 'token', value => "FooBar" } ];
    my $canonical = $input;
    
    my $result = eval { decode_list($input); };
    
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

