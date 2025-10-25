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

# Generated from list.json
# Total tests: 11

plan tests => 11;

# Test 1: basic list
subtest "basic list" => sub {
    my $test_name = "basic list";
    my $input = "1, 42";
    my $expected = [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
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

# Test 2: empty list
subtest "empty list" => sub {
    my $test_name = "empty list";
    my $input = "";
    my $expected = [];
    my $canonical = "";
    
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

# Test 3: leading SP list
subtest "leading SP list" => sub {
    my $test_name = "leading SP list";
    my $input = "  42, 43";
    my $expected = [
        { _type => 'integer', value => 42 },
        { _type => 'integer', value => 43 }
    ];
    my $canonical = "42, 43";
    
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

# Test 4: single item list
subtest "single item list" => sub {
    my $test_name = "single item list";
    my $input = "42";
    my $expected = [ { _type => 'integer', value => 42 } ];
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

# Test 5: no whitespace list
subtest "no whitespace list" => sub {
    my $test_name = "no whitespace list";
    my $input = "1,42";
    my $expected = [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
    ];
    my $canonical = "1, 42";
    
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

# Test 6: extra whitespace list
subtest "extra whitespace list" => sub {
    my $test_name = "extra whitespace list";
    my $input = "1 , 42";
    my $expected = [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
    ];
    my $canonical = "1, 42";
    
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

# Test 7: tab separated list
subtest "tab separated list" => sub {
    my $test_name = "tab separated list";
    my $input = "1\t,\t42";
    my $expected = [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
    ];
    my $canonical = "1, 42";
    
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

# Test 8: two line list
subtest "two line list" => sub {
    my $test_name = "two line list";
    my $input = "1,42";
    my $expected = [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 42 }
    ];
    my $canonical = "1, 42";
    
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

# Test 9: trailing comma list
{
    my $test_name = 'trailing comma list - must fail';
    my $input = "1, 42,";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: empty item list
{
    my $test_name = 'empty item list - must fail';
    my $input = "1,,42";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: empty item list (multiple field lines)
{
    my $test_name = 'empty item list (multiple field lines) - must fail';
    my $input = "1,,42";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

