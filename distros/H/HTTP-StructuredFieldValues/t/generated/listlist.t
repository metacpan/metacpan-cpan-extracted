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

# Generated from listlist.json
# Total tests: 10

plan tests => 10;

# Test 1: basic list of lists
subtest "basic list of lists" => sub {
    my $test_name = "basic list of lists";
    my $input = "(1 2), (42 43)";
    my $expected = [
        { _type => 'inner_list', value => [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 2 }
    ] },
        { _type => 'inner_list', value => [
        { _type => 'integer', value => 42 },
        { _type => 'integer', value => 43 }
    ] }
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

# Test 2: single item list of lists
subtest "single item list of lists" => sub {
    my $test_name = "single item list of lists";
    my $input = "(42)";
    my $expected = [ { _type => 'inner_list', value => [ { _type => 'integer', value => 42 } ] } ];
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

# Test 3: empty item list of lists
subtest "empty item list of lists" => sub {
    my $test_name = "empty item list of lists";
    my $input = "()";
    my $expected = [ { _type => 'inner_list', value => [] } ];
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

# Test 4: empty middle item list of lists
subtest "empty middle item list of lists" => sub {
    my $test_name = "empty middle item list of lists";
    my $input = "(1),(),(42)";
    my $expected = [
        { _type => 'inner_list', value => [ { _type => 'integer', value => 1 } ] },
        { _type => 'inner_list', value => [] },
        { _type => 'inner_list', value => [ { _type => 'integer', value => 42 } ] }
    ];
    my $canonical = "(1), (), (42)";
    
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

# Test 5: extra whitespace list of lists
subtest "extra whitespace list of lists" => sub {
    my $test_name = "extra whitespace list of lists";
    my $input = "(  1  42  )";
    my $expected = [ { _type => 'inner_list', value => [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
    ] } ];
    my $canonical = "(1 42)";
    
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

# Test 6: wrong whitespace list of lists
{
    my $test_name = 'wrong whitespace list of lists - must fail';
    my $input = "(1\t 42)";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: no trailing parenthesis list of lists
{
    my $test_name = 'no trailing parenthesis list of lists - must fail';
    my $input = "(1 42";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: no trailing parenthesis middle list of lists
{
    my $test_name = 'no trailing parenthesis middle list of lists - must fail';
    my $input = "(1 2, (42 43)";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: no spaces in inner-list
{
    my $test_name = 'no spaces in inner-list - must fail';
    my $input = "(abc\"def\"?0123*dXZ3*xyz)";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: no closing parenthesis
{
    my $test_name = 'no closing parenthesis - must fail';
    my $input = "(";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

