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

# Generated from param-listlist.json
# Total tests: 3

plan tests => 3;

# Test 1: parameterised inner list
subtest "parameterised inner list" => sub {
    my $test_name = "parameterised inner list";
    my $input = "(abc_123);a=1;b=2, cdef_456";
    my $expected = [
        { _type => 'inner_list', value => [ { _type => 'token', value => "abc_123" } ], params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 } ) },
        { _type => 'token', value => "cdef_456" }
    ];
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

# Test 2: parameterised inner list item
subtest "parameterised inner list item" => sub {
    my $test_name = "parameterised inner list item";
    my $input = "(abc_123;a=1;b=2;cdef_456)";
    my $expected = [ { _type => 'inner_list', value => [ { _type => 'token', value => "abc_123", params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 }, "cdef_456" => { _type => 'boolean', value => 1 } ) } ] } ];
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

# Test 3: parameterised inner list with parameterised item
subtest "parameterised inner list with parameterised item" => sub {
    my $test_name = "parameterised inner list with parameterised item";
    my $input = "(abc_123;a=1;b=2);cdef_456";
    my $expected = [ { _type => 'inner_list', value => [ { _type => 'token', value => "abc_123", params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 } ) } ], params => _h( "cdef_456" => { _type => 'boolean', value => 1 } ) } ];
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

