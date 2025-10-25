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

# Generated from number.json
# Total tests: 33

plan tests => 33;

# Test 1: basic integer
subtest "basic integer" => sub {
    my $test_name = "basic integer";
    my $input = "42";
    my $expected = { _type => 'integer', value => 42 };
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

# Test 2: zero integer
subtest "zero integer" => sub {
    my $test_name = "zero integer";
    my $input = "0";
    my $expected = { _type => 'integer', value => 0 };
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

# Test 3: negative zero
subtest "negative zero" => sub {
    my $test_name = "negative zero";
    my $input = "-0";
    my $expected = { _type => 'integer', value => 0 };
    my $canonical = "0";
    
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

# Test 4: double negative zero
{
    my $test_name = 'double negative zero - must fail';
    my $input = "--0";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 5: negative integer
subtest "negative integer" => sub {
    my $test_name = "negative integer";
    my $input = "-42";
    my $expected = { _type => 'integer', value => -42 };
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

# Test 6: leading 0 integer
subtest "leading 0 integer" => sub {
    my $test_name = "leading 0 integer";
    my $input = "042";
    my $expected = { _type => 'integer', value => 42 };
    my $canonical = "42";
    
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

# Test 7: leading 0 negative integer
subtest "leading 0 negative integer" => sub {
    my $test_name = "leading 0 negative integer";
    my $input = "-042";
    my $expected = { _type => 'integer', value => -42 };
    my $canonical = "-42";
    
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

# Test 8: leading 0 zero
subtest "leading 0 zero" => sub {
    my $test_name = "leading 0 zero";
    my $input = "00";
    my $expected = { _type => 'integer', value => 0 };
    my $canonical = "0";
    
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

# Test 9: comma
{
    my $test_name = 'comma - must fail';
    my $input = "2,3";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: negative non-DIGIT first character
{
    my $test_name = 'negative non-DIGIT first character - must fail';
    my $input = "-a23";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: sign out of place
{
    my $test_name = 'sign out of place - must fail';
    my $input = "4-2";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: whitespace after sign
{
    my $test_name = 'whitespace after sign - must fail';
    my $input = "- 42";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 13: long integer
subtest "long integer" => sub {
    my $test_name = "long integer";
    my $input = "123456789012345";
    my $expected = { _type => 'integer', value => 123456789012345 };
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

# Test 14: long negative integer
subtest "long negative integer" => sub {
    my $test_name = "long negative integer";
    my $input = "-123456789012345";
    my $expected = { _type => 'integer', value => -123456789012345 };
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

# Test 15: too long integer
{
    my $test_name = 'too long integer - must fail';
    my $input = "1234567890123456";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 16: negative too long integer
{
    my $test_name = 'negative too long integer - must fail';
    my $input = "-1234567890123456";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 17: simple decimal
subtest "simple decimal" => sub {
    my $test_name = "simple decimal";
    my $input = "1.23";
    my $expected = { _type => 'decimal', value => 1.23 };
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

# Test 18: negative decimal
subtest "negative decimal" => sub {
    my $test_name = "negative decimal";
    my $input = "-1.23";
    my $expected = { _type => 'decimal', value => -1.23 };
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

# Test 19: decimal, whitespace after decimal
{
    my $test_name = 'decimal, whitespace after decimal - must fail';
    my $input = "1. 23";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 20: decimal, whitespace before decimal
{
    my $test_name = 'decimal, whitespace before decimal - must fail';
    my $input = "1 .23";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 21: negative decimal, whitespace after sign
{
    my $test_name = 'negative decimal, whitespace after sign - must fail';
    my $input = "- 1.23";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 22: tricky precision decimal
subtest "tricky precision decimal" => sub {
    my $test_name = "tricky precision decimal";
    my $input = "123456789012.1";
    my $expected = { _type => 'decimal', value => 123456789012.1 };
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

# Test 23: double decimal decimal
{
    my $test_name = 'double decimal decimal - must fail';
    my $input = "1.5.4";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 24: adjacent double decimal decimal
{
    my $test_name = 'adjacent double decimal decimal - must fail';
    my $input = "1..4";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 25: decimal with three fractional digits
subtest "decimal with three fractional digits" => sub {
    my $test_name = "decimal with three fractional digits";
    my $input = "1.123";
    my $expected = { _type => 'decimal', value => 1.123 };
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

# Test 26: negative decimal with three fractional digits
subtest "negative decimal with three fractional digits" => sub {
    my $test_name = "negative decimal with three fractional digits";
    my $input = "-1.123";
    my $expected = { _type => 'decimal', value => -1.123 };
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

# Test 27: decimal with four fractional digits
{
    my $test_name = 'decimal with four fractional digits - must fail';
    my $input = "1.1234";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 28: negative decimal with four fractional digits
{
    my $test_name = 'negative decimal with four fractional digits - must fail';
    my $input = "-1.1234";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 29: decimal with thirteen integer digits
{
    my $test_name = 'decimal with thirteen integer digits - must fail';
    my $input = "1234567890123.0";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 30: negative decimal with thirteen integer digits
{
    my $test_name = 'negative decimal with thirteen integer digits - must fail';
    my $input = "-1234567890123.0";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 31: decimal with 1 significant digit and 1 insignificant digit
subtest "decimal with 1 significant digit and 1 insignificant digit" => sub {
    my $test_name = "decimal with 1 significant digit and 1 insignificant digit";
    my $input = "1.20";
    my $expected = { _type => 'decimal', value => 1.2 };
    my $canonical = "1.2";
    
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

# Test 32: decimal with 1 significant digit and 2 insignificant digits
subtest "decimal with 1 significant digit and 2 insignificant digits" => sub {
    my $test_name = "decimal with 1 significant digit and 2 insignificant digits";
    my $input = "1.200";
    my $expected = { _type => 'decimal', value => 1.2 };
    my $canonical = "1.2";
    
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

# Test 33: decimal with 2 significant digits and 1 insignificant digit
subtest "decimal with 2 significant digits and 1 insignificant digit" => sub {
    my $test_name = "decimal with 2 significant digits and 1 insignificant digit";
    my $input = "1.230";
    my $expected = { _type => 'decimal', value => 1.23 };
    my $canonical = "1.23";
    
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

