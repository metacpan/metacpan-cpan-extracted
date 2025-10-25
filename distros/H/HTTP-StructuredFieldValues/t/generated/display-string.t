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

# Generated from display-string.json
# Total tests: 20

plan tests => 20;

# Test 1: basic display string (ascii content)
subtest "basic display string (ascii content)" => sub {
    my $test_name = "basic display string (ascii content)";
    my $input = "%\"foo bar\"";
    my $expected = { _type => 'displaystring', value => 'foo bar' };
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

# Test 2: all printable ascii
subtest "all printable ascii" => sub {
    my $test_name = "all printable ascii";
    my $input = "%\" !%22#\$%25&'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\"";
    my $expected = { _type => 'displaystring', value => ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~' };
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

# Test 3: non-ascii display string (uppercase escaping)
{
    my $test_name = 'non-ascii display string (uppercase escaping) - must fail';
    my $input = "%\"f%C3%BC%C3%BC\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 4: non-ascii display string (lowercase escaping)
subtest "non-ascii display string (lowercase escaping)" => sub {
    my $test_name = "non-ascii display string (lowercase escaping)";
    my $input = "%\"f%c3%bc%c3%bc\"";
    my $expected = { _type => 'displaystring', value => 'füü' };
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

# Test 5: non-ascii display string (unescaped)
{
    my $test_name = 'non-ascii display string (unescaped) - must fail';
    my $input = "%\"f\x{fc}\x{fc}\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 6: tab in display string
{
    my $test_name = 'tab in display string - must fail';
    my $input = "%\"\t\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: newline in display string
{
    my $test_name = 'newline in display string - must fail';
    my $input = "%\"\n\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: single quoted display string
{
    my $test_name = 'single quoted display string - must fail';
    my $input = "%'foo'";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: unquoted display string
{
    my $test_name = 'unquoted display string - must fail';
    my $input = "%foo";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: display string missing initial quote
{
    my $test_name = 'display string missing initial quote - must fail';
    my $input = "%foo\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: unbalanced display string
{
    my $test_name = 'unbalanced display string - must fail';
    my $input = "%\"foo";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: display string quoting
subtest "display string quoting" => sub {
    my $test_name = "display string quoting";
    my $input = "%\"foo %22bar%22 \\ baz\"";
    my $expected = { _type => 'displaystring', value => 'foo "bar" \ baz' };
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

# Test 13: bad display string escaping
{
    my $test_name = 'bad display string escaping - must fail';
    my $input = "%\"foo %a";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 14: bad display string utf-8 (invalid 2-byte seq)
{
    my $test_name = 'bad display string utf-8 (invalid 2-byte seq) - must fail';
    my $input = "%\"%c3%28\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 15: bad display string utf-8 (invalid sequence id)
{
    my $test_name = 'bad display string utf-8 (invalid sequence id) - must fail';
    my $input = "%\"%a0%a1\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 16: bad display string utf-8 (invalid hex)
{
    my $test_name = 'bad display string utf-8 (invalid hex) - must fail';
    my $input = "%\"%g0%1w\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 17: bad display string utf-8 (invalid 3-byte seq)
{
    my $test_name = 'bad display string utf-8 (invalid 3-byte seq) - must fail';
    my $input = "%\"%e2%28%a1\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 18: bad display string utf-8 (invalid 4-byte seq)
{
    my $test_name = 'bad display string utf-8 (invalid 4-byte seq) - must fail';
    my $input = "%\"%f0%28%8c%28\"";
    
    eval { decode_item($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 19: BOM in display string
subtest "BOM in display string" => sub {
    my $test_name = "BOM in display string";
    my $input = "%\"BOM: %ef%bb%bf\"";
    my $expected = { _type => 'displaystring', value => 'BOM: ﻿' };
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

# Test 20: two lines display string
{
    my $test_name = 'two lines display string - can fail';
    my $input = "%\"foo,bar\"";
    
    eval { decode_item($input); };
    pass($test_name); # Can fail tests always pass
}

