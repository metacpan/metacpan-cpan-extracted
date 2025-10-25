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

# Generated from token-generated.json
# Total tests: 256

plan tests => 256;

# Test 1: 0x00 in token
{
    my $test_name = '0x00 in token - must fail';
    my $input = "a\000a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 2: 0x01 in token
{
    my $test_name = '0x01 in token - must fail';
    my $input = "a\001a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 3: 0x02 in token
{
    my $test_name = '0x02 in token - must fail';
    my $input = "a\002a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 4: 0x03 in token
{
    my $test_name = '0x03 in token - must fail';
    my $input = "a\003a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 5: 0x04 in token
{
    my $test_name = '0x04 in token - must fail';
    my $input = "a\004a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 6: 0x05 in token
{
    my $test_name = '0x05 in token - must fail';
    my $input = "a\005a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: 0x06 in token
{
    my $test_name = '0x06 in token - must fail';
    my $input = "a\006a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: 0x07 in token
{
    my $test_name = '0x07 in token - must fail';
    my $input = "a\aa";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: 0x08 in token
{
    my $test_name = '0x08 in token - must fail';
    my $input = "a\ba";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: 0x09 in token
{
    my $test_name = '0x09 in token - must fail';
    my $input = "a\ta";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: 0x0a in token
{
    my $test_name = '0x0a in token - must fail';
    my $input = "a\na";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: 0x0b in token
{
    my $test_name = '0x0b in token - must fail';
    my $input = "a\013a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 13: 0x0c in token
{
    my $test_name = '0x0c in token - must fail';
    my $input = "a\fa";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 14: 0x0d in token
{
    my $test_name = '0x0d in token - must fail';
    my $input = "a\ra";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 15: 0x0e in token
{
    my $test_name = '0x0e in token - must fail';
    my $input = "a\016a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 16: 0x0f in token
{
    my $test_name = '0x0f in token - must fail';
    my $input = "a\017a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 17: 0x10 in token
{
    my $test_name = '0x10 in token - must fail';
    my $input = "a\020a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 18: 0x11 in token
{
    my $test_name = '0x11 in token - must fail';
    my $input = "a\021a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 19: 0x12 in token
{
    my $test_name = '0x12 in token - must fail';
    my $input = "a\022a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 20: 0x13 in token
{
    my $test_name = '0x13 in token - must fail';
    my $input = "a\023a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 21: 0x14 in token
{
    my $test_name = '0x14 in token - must fail';
    my $input = "a\024a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 22: 0x15 in token
{
    my $test_name = '0x15 in token - must fail';
    my $input = "a\025a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 23: 0x16 in token
{
    my $test_name = '0x16 in token - must fail';
    my $input = "a\026a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 24: 0x17 in token
{
    my $test_name = '0x17 in token - must fail';
    my $input = "a\027a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 25: 0x18 in token
{
    my $test_name = '0x18 in token - must fail';
    my $input = "a\030a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 26: 0x19 in token
{
    my $test_name = '0x19 in token - must fail';
    my $input = "a\031a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 27: 0x1a in token
{
    my $test_name = '0x1a in token - must fail';
    my $input = "a\032a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 28: 0x1b in token
{
    my $test_name = '0x1b in token - must fail';
    my $input = "a\033a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 29: 0x1c in token
{
    my $test_name = '0x1c in token - must fail';
    my $input = "a\034a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 30: 0x1d in token
{
    my $test_name = '0x1d in token - must fail';
    my $input = "a\035a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 31: 0x1e in token
{
    my $test_name = '0x1e in token - must fail';
    my $input = "a\036a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 32: 0x1f in token
{
    my $test_name = '0x1f in token - must fail';
    my $input = "a\037a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 33: 0x20 in token
{
    my $test_name = '0x20 in token - must fail';
    my $input = "a a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 34: 0x21 in token
subtest "0x21 in token" => sub {
    my $test_name = "0x21 in token";
    my $input = "a!a";
    my $expected = { _type => 'token', value => "a!a" };
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

# Test 35: 0x22 in token
{
    my $test_name = '0x22 in token - must fail';
    my $input = "a\"a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 36: 0x23 in token
subtest "0x23 in token" => sub {
    my $test_name = "0x23 in token";
    my $input = "a#a";
    my $expected = { _type => 'token', value => "a#a" };
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

# Test 37: 0x24 in token
subtest "0x24 in token" => sub {
    my $test_name = "0x24 in token";
    my $input = "a\$a";
    my $expected = { _type => 'token', value => "a\$a" };
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

# Test 38: 0x25 in token
subtest "0x25 in token" => sub {
    my $test_name = "0x25 in token";
    my $input = "a%a";
    my $expected = { _type => 'token', value => "a%a" };
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

# Test 39: 0x26 in token
subtest "0x26 in token" => sub {
    my $test_name = "0x26 in token";
    my $input = "a&a";
    my $expected = { _type => 'token', value => "a&a" };
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

# Test 40: 0x27 in token
subtest "0x27 in token" => sub {
    my $test_name = "0x27 in token";
    my $input = "a'a";
    my $expected = { _type => 'token', value => "a'a" };
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

# Test 41: 0x28 in token
{
    my $test_name = '0x28 in token - must fail';
    my $input = "a(a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 42: 0x29 in token
{
    my $test_name = '0x29 in token - must fail';
    my $input = "a)a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 43: 0x2a in token
subtest "0x2a in token" => sub {
    my $test_name = "0x2a in token";
    my $input = "a*a";
    my $expected = { _type => 'token', value => "a*a" };
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

# Test 44: 0x2b in token
subtest "0x2b in token" => sub {
    my $test_name = "0x2b in token";
    my $input = "a+a";
    my $expected = { _type => 'token', value => "a+a" };
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

# Test 45: 0x2c in token
{
    my $test_name = '0x2c in token - must fail';
    my $input = "a,a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 46: 0x2d in token
subtest "0x2d in token" => sub {
    my $test_name = "0x2d in token";
    my $input = "a-a";
    my $expected = { _type => 'token', value => "a-a" };
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

# Test 47: 0x2e in token
subtest "0x2e in token" => sub {
    my $test_name = "0x2e in token";
    my $input = "a.a";
    my $expected = { _type => 'token', value => "a.a" };
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

# Test 48: 0x2f in token
subtest "0x2f in token" => sub {
    my $test_name = "0x2f in token";
    my $input = "a/a";
    my $expected = { _type => 'token', value => "a/a" };
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

# Test 49: 0x30 in token
subtest "0x30 in token" => sub {
    my $test_name = "0x30 in token";
    my $input = "a0a";
    my $expected = { _type => 'token', value => "a0a" };
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

# Test 50: 0x31 in token
subtest "0x31 in token" => sub {
    my $test_name = "0x31 in token";
    my $input = "a1a";
    my $expected = { _type => 'token', value => "a1a" };
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

# Test 51: 0x32 in token
subtest "0x32 in token" => sub {
    my $test_name = "0x32 in token";
    my $input = "a2a";
    my $expected = { _type => 'token', value => "a2a" };
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

# Test 52: 0x33 in token
subtest "0x33 in token" => sub {
    my $test_name = "0x33 in token";
    my $input = "a3a";
    my $expected = { _type => 'token', value => "a3a" };
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

# Test 53: 0x34 in token
subtest "0x34 in token" => sub {
    my $test_name = "0x34 in token";
    my $input = "a4a";
    my $expected = { _type => 'token', value => "a4a" };
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

# Test 54: 0x35 in token
subtest "0x35 in token" => sub {
    my $test_name = "0x35 in token";
    my $input = "a5a";
    my $expected = { _type => 'token', value => "a5a" };
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

# Test 55: 0x36 in token
subtest "0x36 in token" => sub {
    my $test_name = "0x36 in token";
    my $input = "a6a";
    my $expected = { _type => 'token', value => "a6a" };
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

# Test 56: 0x37 in token
subtest "0x37 in token" => sub {
    my $test_name = "0x37 in token";
    my $input = "a7a";
    my $expected = { _type => 'token', value => "a7a" };
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

# Test 57: 0x38 in token
subtest "0x38 in token" => sub {
    my $test_name = "0x38 in token";
    my $input = "a8a";
    my $expected = { _type => 'token', value => "a8a" };
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

# Test 58: 0x39 in token
subtest "0x39 in token" => sub {
    my $test_name = "0x39 in token";
    my $input = "a9a";
    my $expected = { _type => 'token', value => "a9a" };
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

# Test 59: 0x3a in token
subtest "0x3a in token" => sub {
    my $test_name = "0x3a in token";
    my $input = "a:a";
    my $expected = { _type => 'token', value => "a:a" };
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

# Test 60: 0x3b in token
subtest "0x3b in token" => sub {
    my $test_name = "0x3b in token";
    my $input = "a;a";
    my $expected = { _type => 'token', value => "a", params => _h( "a" => { _type => 'boolean', value => 1 } ) };
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

# Test 61: 0x3c in token
{
    my $test_name = '0x3c in token - must fail';
    my $input = "a<a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 62: 0x3d in token
{
    my $test_name = '0x3d in token - must fail';
    my $input = "a=a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 63: 0x3e in token
{
    my $test_name = '0x3e in token - must fail';
    my $input = "a>a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 64: 0x3f in token
{
    my $test_name = '0x3f in token - must fail';
    my $input = "a?a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 65: 0x40 in token
{
    my $test_name = '0x40 in token - must fail';
    my $input = "a\@a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 66: 0x41 in token
subtest "0x41 in token" => sub {
    my $test_name = "0x41 in token";
    my $input = "aAa";
    my $expected = { _type => 'token', value => "aAa" };
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

# Test 67: 0x42 in token
subtest "0x42 in token" => sub {
    my $test_name = "0x42 in token";
    my $input = "aBa";
    my $expected = { _type => 'token', value => "aBa" };
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

# Test 68: 0x43 in token
subtest "0x43 in token" => sub {
    my $test_name = "0x43 in token";
    my $input = "aCa";
    my $expected = { _type => 'token', value => "aCa" };
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

# Test 69: 0x44 in token
subtest "0x44 in token" => sub {
    my $test_name = "0x44 in token";
    my $input = "aDa";
    my $expected = { _type => 'token', value => "aDa" };
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

# Test 70: 0x45 in token
subtest "0x45 in token" => sub {
    my $test_name = "0x45 in token";
    my $input = "aEa";
    my $expected = { _type => 'token', value => "aEa" };
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

# Test 71: 0x46 in token
subtest "0x46 in token" => sub {
    my $test_name = "0x46 in token";
    my $input = "aFa";
    my $expected = { _type => 'token', value => "aFa" };
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

# Test 72: 0x47 in token
subtest "0x47 in token" => sub {
    my $test_name = "0x47 in token";
    my $input = "aGa";
    my $expected = { _type => 'token', value => "aGa" };
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

# Test 73: 0x48 in token
subtest "0x48 in token" => sub {
    my $test_name = "0x48 in token";
    my $input = "aHa";
    my $expected = { _type => 'token', value => "aHa" };
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

# Test 74: 0x49 in token
subtest "0x49 in token" => sub {
    my $test_name = "0x49 in token";
    my $input = "aIa";
    my $expected = { _type => 'token', value => "aIa" };
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

# Test 75: 0x4a in token
subtest "0x4a in token" => sub {
    my $test_name = "0x4a in token";
    my $input = "aJa";
    my $expected = { _type => 'token', value => "aJa" };
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

# Test 76: 0x4b in token
subtest "0x4b in token" => sub {
    my $test_name = "0x4b in token";
    my $input = "aKa";
    my $expected = { _type => 'token', value => "aKa" };
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

# Test 77: 0x4c in token
subtest "0x4c in token" => sub {
    my $test_name = "0x4c in token";
    my $input = "aLa";
    my $expected = { _type => 'token', value => "aLa" };
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

# Test 78: 0x4d in token
subtest "0x4d in token" => sub {
    my $test_name = "0x4d in token";
    my $input = "aMa";
    my $expected = { _type => 'token', value => "aMa" };
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

# Test 79: 0x4e in token
subtest "0x4e in token" => sub {
    my $test_name = "0x4e in token";
    my $input = "aNa";
    my $expected = { _type => 'token', value => "aNa" };
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

# Test 80: 0x4f in token
subtest "0x4f in token" => sub {
    my $test_name = "0x4f in token";
    my $input = "aOa";
    my $expected = { _type => 'token', value => "aOa" };
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

# Test 81: 0x50 in token
subtest "0x50 in token" => sub {
    my $test_name = "0x50 in token";
    my $input = "aPa";
    my $expected = { _type => 'token', value => "aPa" };
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

# Test 82: 0x51 in token
subtest "0x51 in token" => sub {
    my $test_name = "0x51 in token";
    my $input = "aQa";
    my $expected = { _type => 'token', value => "aQa" };
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

# Test 83: 0x52 in token
subtest "0x52 in token" => sub {
    my $test_name = "0x52 in token";
    my $input = "aRa";
    my $expected = { _type => 'token', value => "aRa" };
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

# Test 84: 0x53 in token
subtest "0x53 in token" => sub {
    my $test_name = "0x53 in token";
    my $input = "aSa";
    my $expected = { _type => 'token', value => "aSa" };
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

# Test 85: 0x54 in token
subtest "0x54 in token" => sub {
    my $test_name = "0x54 in token";
    my $input = "aTa";
    my $expected = { _type => 'token', value => "aTa" };
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

# Test 86: 0x55 in token
subtest "0x55 in token" => sub {
    my $test_name = "0x55 in token";
    my $input = "aUa";
    my $expected = { _type => 'token', value => "aUa" };
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

# Test 87: 0x56 in token
subtest "0x56 in token" => sub {
    my $test_name = "0x56 in token";
    my $input = "aVa";
    my $expected = { _type => 'token', value => "aVa" };
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

# Test 88: 0x57 in token
subtest "0x57 in token" => sub {
    my $test_name = "0x57 in token";
    my $input = "aWa";
    my $expected = { _type => 'token', value => "aWa" };
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

# Test 89: 0x58 in token
subtest "0x58 in token" => sub {
    my $test_name = "0x58 in token";
    my $input = "aXa";
    my $expected = { _type => 'token', value => "aXa" };
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

# Test 90: 0x59 in token
subtest "0x59 in token" => sub {
    my $test_name = "0x59 in token";
    my $input = "aYa";
    my $expected = { _type => 'token', value => "aYa" };
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

# Test 91: 0x5a in token
subtest "0x5a in token" => sub {
    my $test_name = "0x5a in token";
    my $input = "aZa";
    my $expected = { _type => 'token', value => "aZa" };
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

# Test 92: 0x5b in token
{
    my $test_name = '0x5b in token - must fail';
    my $input = "a[a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 93: 0x5c in token
{
    my $test_name = '0x5c in token - must fail';
    my $input = "a\\a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 94: 0x5d in token
{
    my $test_name = '0x5d in token - must fail';
    my $input = "a]a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 95: 0x5e in token
subtest "0x5e in token" => sub {
    my $test_name = "0x5e in token";
    my $input = "a^a";
    my $expected = { _type => 'token', value => "a^a" };
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

# Test 96: 0x5f in token
subtest "0x5f in token" => sub {
    my $test_name = "0x5f in token";
    my $input = "a_a";
    my $expected = { _type => 'token', value => "a_a" };
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

# Test 97: 0x60 in token
subtest "0x60 in token" => sub {
    my $test_name = "0x60 in token";
    my $input = "a`a";
    my $expected = { _type => 'token', value => "a`a" };
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

# Test 98: 0x61 in token
subtest "0x61 in token" => sub {
    my $test_name = "0x61 in token";
    my $input = "aaa";
    my $expected = { _type => 'token', value => "aaa" };
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

# Test 99: 0x62 in token
subtest "0x62 in token" => sub {
    my $test_name = "0x62 in token";
    my $input = "aba";
    my $expected = { _type => 'token', value => "aba" };
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

# Test 100: 0x63 in token
subtest "0x63 in token" => sub {
    my $test_name = "0x63 in token";
    my $input = "aca";
    my $expected = { _type => 'token', value => "aca" };
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

# Test 101: 0x64 in token
subtest "0x64 in token" => sub {
    my $test_name = "0x64 in token";
    my $input = "ada";
    my $expected = { _type => 'token', value => "ada" };
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

# Test 102: 0x65 in token
subtest "0x65 in token" => sub {
    my $test_name = "0x65 in token";
    my $input = "aea";
    my $expected = { _type => 'token', value => "aea" };
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

# Test 103: 0x66 in token
subtest "0x66 in token" => sub {
    my $test_name = "0x66 in token";
    my $input = "afa";
    my $expected = { _type => 'token', value => "afa" };
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

# Test 104: 0x67 in token
subtest "0x67 in token" => sub {
    my $test_name = "0x67 in token";
    my $input = "aga";
    my $expected = { _type => 'token', value => "aga" };
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

# Test 105: 0x68 in token
subtest "0x68 in token" => sub {
    my $test_name = "0x68 in token";
    my $input = "aha";
    my $expected = { _type => 'token', value => "aha" };
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

# Test 106: 0x69 in token
subtest "0x69 in token" => sub {
    my $test_name = "0x69 in token";
    my $input = "aia";
    my $expected = { _type => 'token', value => "aia" };
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

# Test 107: 0x6a in token
subtest "0x6a in token" => sub {
    my $test_name = "0x6a in token";
    my $input = "aja";
    my $expected = { _type => 'token', value => "aja" };
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

# Test 108: 0x6b in token
subtest "0x6b in token" => sub {
    my $test_name = "0x6b in token";
    my $input = "aka";
    my $expected = { _type => 'token', value => "aka" };
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

# Test 109: 0x6c in token
subtest "0x6c in token" => sub {
    my $test_name = "0x6c in token";
    my $input = "ala";
    my $expected = { _type => 'token', value => "ala" };
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

# Test 110: 0x6d in token
subtest "0x6d in token" => sub {
    my $test_name = "0x6d in token";
    my $input = "ama";
    my $expected = { _type => 'token', value => "ama" };
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

# Test 111: 0x6e in token
subtest "0x6e in token" => sub {
    my $test_name = "0x6e in token";
    my $input = "ana";
    my $expected = { _type => 'token', value => "ana" };
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

# Test 112: 0x6f in token
subtest "0x6f in token" => sub {
    my $test_name = "0x6f in token";
    my $input = "aoa";
    my $expected = { _type => 'token', value => "aoa" };
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

# Test 113: 0x70 in token
subtest "0x70 in token" => sub {
    my $test_name = "0x70 in token";
    my $input = "apa";
    my $expected = { _type => 'token', value => "apa" };
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

# Test 114: 0x71 in token
subtest "0x71 in token" => sub {
    my $test_name = "0x71 in token";
    my $input = "aqa";
    my $expected = { _type => 'token', value => "aqa" };
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

# Test 115: 0x72 in token
subtest "0x72 in token" => sub {
    my $test_name = "0x72 in token";
    my $input = "ara";
    my $expected = { _type => 'token', value => "ara" };
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

# Test 116: 0x73 in token
subtest "0x73 in token" => sub {
    my $test_name = "0x73 in token";
    my $input = "asa";
    my $expected = { _type => 'token', value => "asa" };
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

# Test 117: 0x74 in token
subtest "0x74 in token" => sub {
    my $test_name = "0x74 in token";
    my $input = "ata";
    my $expected = { _type => 'token', value => "ata" };
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

# Test 118: 0x75 in token
subtest "0x75 in token" => sub {
    my $test_name = "0x75 in token";
    my $input = "aua";
    my $expected = { _type => 'token', value => "aua" };
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

# Test 119: 0x76 in token
subtest "0x76 in token" => sub {
    my $test_name = "0x76 in token";
    my $input = "ava";
    my $expected = { _type => 'token', value => "ava" };
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

# Test 120: 0x77 in token
subtest "0x77 in token" => sub {
    my $test_name = "0x77 in token";
    my $input = "awa";
    my $expected = { _type => 'token', value => "awa" };
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

# Test 121: 0x78 in token
subtest "0x78 in token" => sub {
    my $test_name = "0x78 in token";
    my $input = "axa";
    my $expected = { _type => 'token', value => "axa" };
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

# Test 122: 0x79 in token
subtest "0x79 in token" => sub {
    my $test_name = "0x79 in token";
    my $input = "aya";
    my $expected = { _type => 'token', value => "aya" };
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

# Test 123: 0x7a in token
subtest "0x7a in token" => sub {
    my $test_name = "0x7a in token";
    my $input = "aza";
    my $expected = { _type => 'token', value => "aza" };
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

# Test 124: 0x7b in token
{
    my $test_name = '0x7b in token - must fail';
    my $input = "a{a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 125: 0x7c in token
subtest "0x7c in token" => sub {
    my $test_name = "0x7c in token";
    my $input = "a|a";
    my $expected = { _type => 'token', value => "a|a" };
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

# Test 126: 0x7d in token
{
    my $test_name = '0x7d in token - must fail';
    my $input = "a}a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 127: 0x7e in token
subtest "0x7e in token" => sub {
    my $test_name = "0x7e in token";
    my $input = "a~a";
    my $expected = { _type => 'token', value => "a~a" };
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

# Test 128: 0x7f in token
{
    my $test_name = '0x7f in token - must fail';
    my $input = "a\177a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 129: 0x00 starting a token
{
    my $test_name = '0x00 starting a token - must fail';
    my $input = "\000a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 130: 0x01 starting a token
{
    my $test_name = '0x01 starting a token - must fail';
    my $input = "\001a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 131: 0x02 starting a token
{
    my $test_name = '0x02 starting a token - must fail';
    my $input = "\002a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 132: 0x03 starting a token
{
    my $test_name = '0x03 starting a token - must fail';
    my $input = "\003a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 133: 0x04 starting a token
{
    my $test_name = '0x04 starting a token - must fail';
    my $input = "\004a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 134: 0x05 starting a token
{
    my $test_name = '0x05 starting a token - must fail';
    my $input = "\005a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 135: 0x06 starting a token
{
    my $test_name = '0x06 starting a token - must fail';
    my $input = "\006a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 136: 0x07 starting a token
{
    my $test_name = '0x07 starting a token - must fail';
    my $input = "\aa";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 137: 0x08 starting a token
{
    my $test_name = '0x08 starting a token - must fail';
    my $input = "\ba";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 138: 0x09 starting a token
{
    my $test_name = '0x09 starting a token - must fail';
    my $input = "\ta";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 139: 0x0a starting a token
{
    my $test_name = '0x0a starting a token - must fail';
    my $input = "\na";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 140: 0x0b starting a token
{
    my $test_name = '0x0b starting a token - must fail';
    my $input = "\013a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 141: 0x0c starting a token
{
    my $test_name = '0x0c starting a token - must fail';
    my $input = "\fa";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 142: 0x0d starting a token
{
    my $test_name = '0x0d starting a token - must fail';
    my $input = "\ra";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 143: 0x0e starting a token
{
    my $test_name = '0x0e starting a token - must fail';
    my $input = "\016a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 144: 0x0f starting a token
{
    my $test_name = '0x0f starting a token - must fail';
    my $input = "\017a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 145: 0x10 starting a token
{
    my $test_name = '0x10 starting a token - must fail';
    my $input = "\020a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 146: 0x11 starting a token
{
    my $test_name = '0x11 starting a token - must fail';
    my $input = "\021a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 147: 0x12 starting a token
{
    my $test_name = '0x12 starting a token - must fail';
    my $input = "\022a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 148: 0x13 starting a token
{
    my $test_name = '0x13 starting a token - must fail';
    my $input = "\023a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 149: 0x14 starting a token
{
    my $test_name = '0x14 starting a token - must fail';
    my $input = "\024a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 150: 0x15 starting a token
{
    my $test_name = '0x15 starting a token - must fail';
    my $input = "\025a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 151: 0x16 starting a token
{
    my $test_name = '0x16 starting a token - must fail';
    my $input = "\026a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 152: 0x17 starting a token
{
    my $test_name = '0x17 starting a token - must fail';
    my $input = "\027a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 153: 0x18 starting a token
{
    my $test_name = '0x18 starting a token - must fail';
    my $input = "\030a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 154: 0x19 starting a token
{
    my $test_name = '0x19 starting a token - must fail';
    my $input = "\031a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 155: 0x1a starting a token
{
    my $test_name = '0x1a starting a token - must fail';
    my $input = "\032a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 156: 0x1b starting a token
{
    my $test_name = '0x1b starting a token - must fail';
    my $input = "\033a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 157: 0x1c starting a token
{
    my $test_name = '0x1c starting a token - must fail';
    my $input = "\034a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 158: 0x1d starting a token
{
    my $test_name = '0x1d starting a token - must fail';
    my $input = "\035a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 159: 0x1e starting a token
{
    my $test_name = '0x1e starting a token - must fail';
    my $input = "\036a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 160: 0x1f starting a token
{
    my $test_name = '0x1f starting a token - must fail';
    my $input = "\037a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 161: 0x20 starting a token
subtest "0x20 starting a token" => sub {
    my $test_name = "0x20 starting a token";
    my $input = " a";
    my $expected = { _type => 'token', value => "a" };
    my $canonical = "a";
    
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

# Test 162: 0x21 starting a token
{
    my $test_name = '0x21 starting a token - must fail';
    my $input = "!a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 163: 0x22 starting a token
{
    my $test_name = '0x22 starting a token - must fail';
    my $input = "\"a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 164: 0x23 starting a token
{
    my $test_name = '0x23 starting a token - must fail';
    my $input = "#a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 165: 0x24 starting a token
{
    my $test_name = '0x24 starting a token - must fail';
    my $input = "\$a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 166: 0x25 starting a token
{
    my $test_name = '0x25 starting a token - must fail';
    my $input = "%a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 167: 0x26 starting a token
{
    my $test_name = '0x26 starting a token - must fail';
    my $input = "&a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 168: 0x27 starting a token
{
    my $test_name = '0x27 starting a token - must fail';
    my $input = "'a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 169: 0x28 starting a token
{
    my $test_name = '0x28 starting a token - must fail';
    my $input = "(a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 170: 0x29 starting a token
{
    my $test_name = '0x29 starting a token - must fail';
    my $input = ")a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 171: 0x2a starting a token
subtest "0x2a starting a token" => sub {
    my $test_name = "0x2a starting a token";
    my $input = "*a";
    my $expected = { _type => 'token', value => "*a" };
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

# Test 172: 0x2b starting a token
{
    my $test_name = '0x2b starting a token - must fail';
    my $input = "+a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 173: 0x2c starting a token
{
    my $test_name = '0x2c starting a token - must fail';
    my $input = ",a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 174: 0x2d starting a token
{
    my $test_name = '0x2d starting a token - must fail';
    my $input = "-a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 175: 0x2e starting a token
{
    my $test_name = '0x2e starting a token - must fail';
    my $input = ".a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 176: 0x2f starting a token
{
    my $test_name = '0x2f starting a token - must fail';
    my $input = "/a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 177: 0x30 starting a token
{
    my $test_name = '0x30 starting a token - must fail';
    my $input = "0a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 178: 0x31 starting a token
{
    my $test_name = '0x31 starting a token - must fail';
    my $input = "1a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 179: 0x32 starting a token
{
    my $test_name = '0x32 starting a token - must fail';
    my $input = "2a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 180: 0x33 starting a token
{
    my $test_name = '0x33 starting a token - must fail';
    my $input = "3a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 181: 0x34 starting a token
{
    my $test_name = '0x34 starting a token - must fail';
    my $input = "4a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 182: 0x35 starting a token
{
    my $test_name = '0x35 starting a token - must fail';
    my $input = "5a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 183: 0x36 starting a token
{
    my $test_name = '0x36 starting a token - must fail';
    my $input = "6a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 184: 0x37 starting a token
{
    my $test_name = '0x37 starting a token - must fail';
    my $input = "7a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 185: 0x38 starting a token
{
    my $test_name = '0x38 starting a token - must fail';
    my $input = "8a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 186: 0x39 starting a token
{
    my $test_name = '0x39 starting a token - must fail';
    my $input = "9a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 187: 0x3a starting a token
{
    my $test_name = '0x3a starting a token - must fail';
    my $input = ":a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 188: 0x3b starting a token
{
    my $test_name = '0x3b starting a token - must fail';
    my $input = ";a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 189: 0x3c starting a token
{
    my $test_name = '0x3c starting a token - must fail';
    my $input = "<a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 190: 0x3d starting a token
{
    my $test_name = '0x3d starting a token - must fail';
    my $input = "=a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 191: 0x3e starting a token
{
    my $test_name = '0x3e starting a token - must fail';
    my $input = ">a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 192: 0x3f starting a token
{
    my $test_name = '0x3f starting a token - must fail';
    my $input = "?a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 193: 0x40 starting a token
{
    my $test_name = '0x40 starting a token - must fail';
    my $input = "\@a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 194: 0x41 starting a token
subtest "0x41 starting a token" => sub {
    my $test_name = "0x41 starting a token";
    my $input = "Aa";
    my $expected = { _type => 'token', value => "Aa" };
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

# Test 195: 0x42 starting a token
subtest "0x42 starting a token" => sub {
    my $test_name = "0x42 starting a token";
    my $input = "Ba";
    my $expected = { _type => 'token', value => "Ba" };
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

# Test 196: 0x43 starting a token
subtest "0x43 starting a token" => sub {
    my $test_name = "0x43 starting a token";
    my $input = "Ca";
    my $expected = { _type => 'token', value => "Ca" };
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

# Test 197: 0x44 starting a token
subtest "0x44 starting a token" => sub {
    my $test_name = "0x44 starting a token";
    my $input = "Da";
    my $expected = { _type => 'token', value => "Da" };
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

# Test 198: 0x45 starting a token
subtest "0x45 starting a token" => sub {
    my $test_name = "0x45 starting a token";
    my $input = "Ea";
    my $expected = { _type => 'token', value => "Ea" };
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

# Test 199: 0x46 starting a token
subtest "0x46 starting a token" => sub {
    my $test_name = "0x46 starting a token";
    my $input = "Fa";
    my $expected = { _type => 'token', value => "Fa" };
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

# Test 200: 0x47 starting a token
subtest "0x47 starting a token" => sub {
    my $test_name = "0x47 starting a token";
    my $input = "Ga";
    my $expected = { _type => 'token', value => "Ga" };
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

# Test 201: 0x48 starting a token
subtest "0x48 starting a token" => sub {
    my $test_name = "0x48 starting a token";
    my $input = "Ha";
    my $expected = { _type => 'token', value => "Ha" };
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

# Test 202: 0x49 starting a token
subtest "0x49 starting a token" => sub {
    my $test_name = "0x49 starting a token";
    my $input = "Ia";
    my $expected = { _type => 'token', value => "Ia" };
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

# Test 203: 0x4a starting a token
subtest "0x4a starting a token" => sub {
    my $test_name = "0x4a starting a token";
    my $input = "Ja";
    my $expected = { _type => 'token', value => "Ja" };
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

# Test 204: 0x4b starting a token
subtest "0x4b starting a token" => sub {
    my $test_name = "0x4b starting a token";
    my $input = "Ka";
    my $expected = { _type => 'token', value => "Ka" };
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

# Test 205: 0x4c starting a token
subtest "0x4c starting a token" => sub {
    my $test_name = "0x4c starting a token";
    my $input = "La";
    my $expected = { _type => 'token', value => "La" };
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

# Test 206: 0x4d starting a token
subtest "0x4d starting a token" => sub {
    my $test_name = "0x4d starting a token";
    my $input = "Ma";
    my $expected = { _type => 'token', value => "Ma" };
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

# Test 207: 0x4e starting a token
subtest "0x4e starting a token" => sub {
    my $test_name = "0x4e starting a token";
    my $input = "Na";
    my $expected = { _type => 'token', value => "Na" };
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

# Test 208: 0x4f starting a token
subtest "0x4f starting a token" => sub {
    my $test_name = "0x4f starting a token";
    my $input = "Oa";
    my $expected = { _type => 'token', value => "Oa" };
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

# Test 209: 0x50 starting a token
subtest "0x50 starting a token" => sub {
    my $test_name = "0x50 starting a token";
    my $input = "Pa";
    my $expected = { _type => 'token', value => "Pa" };
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

# Test 210: 0x51 starting a token
subtest "0x51 starting a token" => sub {
    my $test_name = "0x51 starting a token";
    my $input = "Qa";
    my $expected = { _type => 'token', value => "Qa" };
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

# Test 211: 0x52 starting a token
subtest "0x52 starting a token" => sub {
    my $test_name = "0x52 starting a token";
    my $input = "Ra";
    my $expected = { _type => 'token', value => "Ra" };
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

# Test 212: 0x53 starting a token
subtest "0x53 starting a token" => sub {
    my $test_name = "0x53 starting a token";
    my $input = "Sa";
    my $expected = { _type => 'token', value => "Sa" };
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

# Test 213: 0x54 starting a token
subtest "0x54 starting a token" => sub {
    my $test_name = "0x54 starting a token";
    my $input = "Ta";
    my $expected = { _type => 'token', value => "Ta" };
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

# Test 214: 0x55 starting a token
subtest "0x55 starting a token" => sub {
    my $test_name = "0x55 starting a token";
    my $input = "Ua";
    my $expected = { _type => 'token', value => "Ua" };
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

# Test 215: 0x56 starting a token
subtest "0x56 starting a token" => sub {
    my $test_name = "0x56 starting a token";
    my $input = "Va";
    my $expected = { _type => 'token', value => "Va" };
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

# Test 216: 0x57 starting a token
subtest "0x57 starting a token" => sub {
    my $test_name = "0x57 starting a token";
    my $input = "Wa";
    my $expected = { _type => 'token', value => "Wa" };
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

# Test 217: 0x58 starting a token
subtest "0x58 starting a token" => sub {
    my $test_name = "0x58 starting a token";
    my $input = "Xa";
    my $expected = { _type => 'token', value => "Xa" };
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

# Test 218: 0x59 starting a token
subtest "0x59 starting a token" => sub {
    my $test_name = "0x59 starting a token";
    my $input = "Ya";
    my $expected = { _type => 'token', value => "Ya" };
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

# Test 219: 0x5a starting a token
subtest "0x5a starting a token" => sub {
    my $test_name = "0x5a starting a token";
    my $input = "Za";
    my $expected = { _type => 'token', value => "Za" };
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

# Test 220: 0x5b starting a token
{
    my $test_name = '0x5b starting a token - must fail';
    my $input = "[a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 221: 0x5c starting a token
{
    my $test_name = '0x5c starting a token - must fail';
    my $input = "\\a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 222: 0x5d starting a token
{
    my $test_name = '0x5d starting a token - must fail';
    my $input = "]a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 223: 0x5e starting a token
{
    my $test_name = '0x5e starting a token - must fail';
    my $input = "^a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 224: 0x5f starting a token
{
    my $test_name = '0x5f starting a token - must fail';
    my $input = "_a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 225: 0x60 starting a token
{
    my $test_name = '0x60 starting a token - must fail';
    my $input = "`a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 226: 0x61 starting a token
subtest "0x61 starting a token" => sub {
    my $test_name = "0x61 starting a token";
    my $input = "aa";
    my $expected = { _type => 'token', value => "aa" };
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

# Test 227: 0x62 starting a token
subtest "0x62 starting a token" => sub {
    my $test_name = "0x62 starting a token";
    my $input = "ba";
    my $expected = { _type => 'token', value => "ba" };
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

# Test 228: 0x63 starting a token
subtest "0x63 starting a token" => sub {
    my $test_name = "0x63 starting a token";
    my $input = "ca";
    my $expected = { _type => 'token', value => "ca" };
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

# Test 229: 0x64 starting a token
subtest "0x64 starting a token" => sub {
    my $test_name = "0x64 starting a token";
    my $input = "da";
    my $expected = { _type => 'token', value => "da" };
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

# Test 230: 0x65 starting a token
subtest "0x65 starting a token" => sub {
    my $test_name = "0x65 starting a token";
    my $input = "ea";
    my $expected = { _type => 'token', value => "ea" };
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

# Test 231: 0x66 starting a token
subtest "0x66 starting a token" => sub {
    my $test_name = "0x66 starting a token";
    my $input = "fa";
    my $expected = { _type => 'token', value => "fa" };
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

# Test 232: 0x67 starting a token
subtest "0x67 starting a token" => sub {
    my $test_name = "0x67 starting a token";
    my $input = "ga";
    my $expected = { _type => 'token', value => "ga" };
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

# Test 233: 0x68 starting a token
subtest "0x68 starting a token" => sub {
    my $test_name = "0x68 starting a token";
    my $input = "ha";
    my $expected = { _type => 'token', value => "ha" };
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

# Test 234: 0x69 starting a token
subtest "0x69 starting a token" => sub {
    my $test_name = "0x69 starting a token";
    my $input = "ia";
    my $expected = { _type => 'token', value => "ia" };
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

# Test 235: 0x6a starting a token
subtest "0x6a starting a token" => sub {
    my $test_name = "0x6a starting a token";
    my $input = "ja";
    my $expected = { _type => 'token', value => "ja" };
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

# Test 236: 0x6b starting a token
subtest "0x6b starting a token" => sub {
    my $test_name = "0x6b starting a token";
    my $input = "ka";
    my $expected = { _type => 'token', value => "ka" };
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

# Test 237: 0x6c starting a token
subtest "0x6c starting a token" => sub {
    my $test_name = "0x6c starting a token";
    my $input = "la";
    my $expected = { _type => 'token', value => "la" };
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

# Test 238: 0x6d starting a token
subtest "0x6d starting a token" => sub {
    my $test_name = "0x6d starting a token";
    my $input = "ma";
    my $expected = { _type => 'token', value => "ma" };
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

# Test 239: 0x6e starting a token
subtest "0x6e starting a token" => sub {
    my $test_name = "0x6e starting a token";
    my $input = "na";
    my $expected = { _type => 'token', value => "na" };
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

# Test 240: 0x6f starting a token
subtest "0x6f starting a token" => sub {
    my $test_name = "0x6f starting a token";
    my $input = "oa";
    my $expected = { _type => 'token', value => "oa" };
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

# Test 241: 0x70 starting a token
subtest "0x70 starting a token" => sub {
    my $test_name = "0x70 starting a token";
    my $input = "pa";
    my $expected = { _type => 'token', value => "pa" };
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

# Test 242: 0x71 starting a token
subtest "0x71 starting a token" => sub {
    my $test_name = "0x71 starting a token";
    my $input = "qa";
    my $expected = { _type => 'token', value => "qa" };
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

# Test 243: 0x72 starting a token
subtest "0x72 starting a token" => sub {
    my $test_name = "0x72 starting a token";
    my $input = "ra";
    my $expected = { _type => 'token', value => "ra" };
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

# Test 244: 0x73 starting a token
subtest "0x73 starting a token" => sub {
    my $test_name = "0x73 starting a token";
    my $input = "sa";
    my $expected = { _type => 'token', value => "sa" };
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

# Test 245: 0x74 starting a token
subtest "0x74 starting a token" => sub {
    my $test_name = "0x74 starting a token";
    my $input = "ta";
    my $expected = { _type => 'token', value => "ta" };
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

# Test 246: 0x75 starting a token
subtest "0x75 starting a token" => sub {
    my $test_name = "0x75 starting a token";
    my $input = "ua";
    my $expected = { _type => 'token', value => "ua" };
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

# Test 247: 0x76 starting a token
subtest "0x76 starting a token" => sub {
    my $test_name = "0x76 starting a token";
    my $input = "va";
    my $expected = { _type => 'token', value => "va" };
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

# Test 248: 0x77 starting a token
subtest "0x77 starting a token" => sub {
    my $test_name = "0x77 starting a token";
    my $input = "wa";
    my $expected = { _type => 'token', value => "wa" };
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

# Test 249: 0x78 starting a token
subtest "0x78 starting a token" => sub {
    my $test_name = "0x78 starting a token";
    my $input = "xa";
    my $expected = { _type => 'token', value => "xa" };
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

# Test 250: 0x79 starting a token
subtest "0x79 starting a token" => sub {
    my $test_name = "0x79 starting a token";
    my $input = "ya";
    my $expected = { _type => 'token', value => "ya" };
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

# Test 251: 0x7a starting a token
subtest "0x7a starting a token" => sub {
    my $test_name = "0x7a starting a token";
    my $input = "za";
    my $expected = { _type => 'token', value => "za" };
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

# Test 252: 0x7b starting a token
{
    my $test_name = '0x7b starting a token - must fail';
    my $input = "{a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 253: 0x7c starting a token
{
    my $test_name = '0x7c starting a token - must fail';
    my $input = "|a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 254: 0x7d starting a token
{
    my $test_name = '0x7d starting a token - must fail';
    my $input = "}a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 255: 0x7e starting a token
{
    my $test_name = '0x7e starting a token - must fail';
    my $input = "~a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 256: 0x7f starting a token
{
    my $test_name = '0x7f starting a token - must fail';
    my $input = "\177a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

