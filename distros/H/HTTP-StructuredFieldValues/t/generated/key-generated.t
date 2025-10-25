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

# Generated from key-generated.json
# Total tests: 640

plan tests => 640;

# Test 1: 0x00 as a single-character dictionary key
{
    my $test_name = '0x00 as a single-character dictionary key - must fail';
    my $input = "\000=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 2: 0x01 as a single-character dictionary key
{
    my $test_name = '0x01 as a single-character dictionary key - must fail';
    my $input = "\001=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 3: 0x02 as a single-character dictionary key
{
    my $test_name = '0x02 as a single-character dictionary key - must fail';
    my $input = "\002=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 4: 0x03 as a single-character dictionary key
{
    my $test_name = '0x03 as a single-character dictionary key - must fail';
    my $input = "\003=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 5: 0x04 as a single-character dictionary key
{
    my $test_name = '0x04 as a single-character dictionary key - must fail';
    my $input = "\004=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 6: 0x05 as a single-character dictionary key
{
    my $test_name = '0x05 as a single-character dictionary key - must fail';
    my $input = "\005=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: 0x06 as a single-character dictionary key
{
    my $test_name = '0x06 as a single-character dictionary key - must fail';
    my $input = "\006=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: 0x07 as a single-character dictionary key
{
    my $test_name = '0x07 as a single-character dictionary key - must fail';
    my $input = "\a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: 0x08 as a single-character dictionary key
{
    my $test_name = '0x08 as a single-character dictionary key - must fail';
    my $input = "\b=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: 0x09 as a single-character dictionary key
{
    my $test_name = '0x09 as a single-character dictionary key - must fail';
    my $input = "\t=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 11: 0x0a as a single-character dictionary key
{
    my $test_name = '0x0a as a single-character dictionary key - must fail';
    my $input = "\n=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: 0x0b as a single-character dictionary key
{
    my $test_name = '0x0b as a single-character dictionary key - must fail';
    my $input = "\013=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 13: 0x0c as a single-character dictionary key
{
    my $test_name = '0x0c as a single-character dictionary key - must fail';
    my $input = "\f=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 14: 0x0d as a single-character dictionary key
{
    my $test_name = '0x0d as a single-character dictionary key - must fail';
    my $input = "\r=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 15: 0x0e as a single-character dictionary key
{
    my $test_name = '0x0e as a single-character dictionary key - must fail';
    my $input = "\016=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 16: 0x0f as a single-character dictionary key
{
    my $test_name = '0x0f as a single-character dictionary key - must fail';
    my $input = "\017=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 17: 0x10 as a single-character dictionary key
{
    my $test_name = '0x10 as a single-character dictionary key - must fail';
    my $input = "\020=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 18: 0x11 as a single-character dictionary key
{
    my $test_name = '0x11 as a single-character dictionary key - must fail';
    my $input = "\021=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 19: 0x12 as a single-character dictionary key
{
    my $test_name = '0x12 as a single-character dictionary key - must fail';
    my $input = "\022=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 20: 0x13 as a single-character dictionary key
{
    my $test_name = '0x13 as a single-character dictionary key - must fail';
    my $input = "\023=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 21: 0x14 as a single-character dictionary key
{
    my $test_name = '0x14 as a single-character dictionary key - must fail';
    my $input = "\024=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 22: 0x15 as a single-character dictionary key
{
    my $test_name = '0x15 as a single-character dictionary key - must fail';
    my $input = "\025=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 23: 0x16 as a single-character dictionary key
{
    my $test_name = '0x16 as a single-character dictionary key - must fail';
    my $input = "\026=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 24: 0x17 as a single-character dictionary key
{
    my $test_name = '0x17 as a single-character dictionary key - must fail';
    my $input = "\027=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 25: 0x18 as a single-character dictionary key
{
    my $test_name = '0x18 as a single-character dictionary key - must fail';
    my $input = "\030=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 26: 0x19 as a single-character dictionary key
{
    my $test_name = '0x19 as a single-character dictionary key - must fail';
    my $input = "\031=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 27: 0x1a as a single-character dictionary key
{
    my $test_name = '0x1a as a single-character dictionary key - must fail';
    my $input = "\032=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 28: 0x1b as a single-character dictionary key
{
    my $test_name = '0x1b as a single-character dictionary key - must fail';
    my $input = "\033=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 29: 0x1c as a single-character dictionary key
{
    my $test_name = '0x1c as a single-character dictionary key - must fail';
    my $input = "\034=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 30: 0x1d as a single-character dictionary key
{
    my $test_name = '0x1d as a single-character dictionary key - must fail';
    my $input = "\035=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 31: 0x1e as a single-character dictionary key
{
    my $test_name = '0x1e as a single-character dictionary key - must fail';
    my $input = "\036=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 32: 0x1f as a single-character dictionary key
{
    my $test_name = '0x1f as a single-character dictionary key - must fail';
    my $input = "\037=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 33: 0x20 as a single-character dictionary key
{
    my $test_name = '0x20 as a single-character dictionary key - must fail';
    my $input = "=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 34: 0x21 as a single-character dictionary key
{
    my $test_name = '0x21 as a single-character dictionary key - must fail';
    my $input = "!=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 35: 0x22 as a single-character dictionary key
{
    my $test_name = '0x22 as a single-character dictionary key - must fail';
    my $input = "\"=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 36: 0x23 as a single-character dictionary key
{
    my $test_name = '0x23 as a single-character dictionary key - must fail';
    my $input = "#=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 37: 0x24 as a single-character dictionary key
{
    my $test_name = '0x24 as a single-character dictionary key - must fail';
    my $input = "\$=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 38: 0x25 as a single-character dictionary key
{
    my $test_name = '0x25 as a single-character dictionary key - must fail';
    my $input = "%=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 39: 0x26 as a single-character dictionary key
{
    my $test_name = '0x26 as a single-character dictionary key - must fail';
    my $input = "&=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 40: 0x27 as a single-character dictionary key
{
    my $test_name = '0x27 as a single-character dictionary key - must fail';
    my $input = "'=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 41: 0x28 as a single-character dictionary key
{
    my $test_name = '0x28 as a single-character dictionary key - must fail';
    my $input = "(=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 42: 0x29 as a single-character dictionary key
{
    my $test_name = '0x29 as a single-character dictionary key - must fail';
    my $input = ")=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 43: 0x2a as a single-character dictionary key
subtest "0x2a as a single-character dictionary key" => sub {
    my $test_name = "0x2a as a single-character dictionary key";
    my $input = "*=1";
    my $expected = _h( "*" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 44: 0x2b as a single-character dictionary key
{
    my $test_name = '0x2b as a single-character dictionary key - must fail';
    my $input = "+=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 45: 0x2c as a single-character dictionary key
{
    my $test_name = '0x2c as a single-character dictionary key - must fail';
    my $input = ",=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 46: 0x2d as a single-character dictionary key
{
    my $test_name = '0x2d as a single-character dictionary key - must fail';
    my $input = "-=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 47: 0x2e as a single-character dictionary key
{
    my $test_name = '0x2e as a single-character dictionary key - must fail';
    my $input = ".=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 48: 0x2f as a single-character dictionary key
{
    my $test_name = '0x2f as a single-character dictionary key - must fail';
    my $input = "/=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 49: 0x30 as a single-character dictionary key
{
    my $test_name = '0x30 as a single-character dictionary key - must fail';
    my $input = "0=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 50: 0x31 as a single-character dictionary key
{
    my $test_name = '0x31 as a single-character dictionary key - must fail';
    my $input = "1=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 51: 0x32 as a single-character dictionary key
{
    my $test_name = '0x32 as a single-character dictionary key - must fail';
    my $input = "2=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 52: 0x33 as a single-character dictionary key
{
    my $test_name = '0x33 as a single-character dictionary key - must fail';
    my $input = "3=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 53: 0x34 as a single-character dictionary key
{
    my $test_name = '0x34 as a single-character dictionary key - must fail';
    my $input = "4=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 54: 0x35 as a single-character dictionary key
{
    my $test_name = '0x35 as a single-character dictionary key - must fail';
    my $input = "5=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 55: 0x36 as a single-character dictionary key
{
    my $test_name = '0x36 as a single-character dictionary key - must fail';
    my $input = "6=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 56: 0x37 as a single-character dictionary key
{
    my $test_name = '0x37 as a single-character dictionary key - must fail';
    my $input = "7=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 57: 0x38 as a single-character dictionary key
{
    my $test_name = '0x38 as a single-character dictionary key - must fail';
    my $input = "8=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 58: 0x39 as a single-character dictionary key
{
    my $test_name = '0x39 as a single-character dictionary key - must fail';
    my $input = "9=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 59: 0x3a as a single-character dictionary key
{
    my $test_name = '0x3a as a single-character dictionary key - must fail';
    my $input = ":=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 60: 0x3b as a single-character dictionary key
{
    my $test_name = '0x3b as a single-character dictionary key - must fail';
    my $input = ";=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 61: 0x3c as a single-character dictionary key
{
    my $test_name = '0x3c as a single-character dictionary key - must fail';
    my $input = "<=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 62: 0x3d as a single-character dictionary key
{
    my $test_name = '0x3d as a single-character dictionary key - must fail';
    my $input = "==1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 63: 0x3e as a single-character dictionary key
{
    my $test_name = '0x3e as a single-character dictionary key - must fail';
    my $input = ">=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 64: 0x3f as a single-character dictionary key
{
    my $test_name = '0x3f as a single-character dictionary key - must fail';
    my $input = "?=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 65: 0x40 as a single-character dictionary key
{
    my $test_name = '0x40 as a single-character dictionary key - must fail';
    my $input = "\@=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 66: 0x41 as a single-character dictionary key
{
    my $test_name = '0x41 as a single-character dictionary key - must fail';
    my $input = "A=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 67: 0x42 as a single-character dictionary key
{
    my $test_name = '0x42 as a single-character dictionary key - must fail';
    my $input = "B=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 68: 0x43 as a single-character dictionary key
{
    my $test_name = '0x43 as a single-character dictionary key - must fail';
    my $input = "C=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 69: 0x44 as a single-character dictionary key
{
    my $test_name = '0x44 as a single-character dictionary key - must fail';
    my $input = "D=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 70: 0x45 as a single-character dictionary key
{
    my $test_name = '0x45 as a single-character dictionary key - must fail';
    my $input = "E=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 71: 0x46 as a single-character dictionary key
{
    my $test_name = '0x46 as a single-character dictionary key - must fail';
    my $input = "F=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 72: 0x47 as a single-character dictionary key
{
    my $test_name = '0x47 as a single-character dictionary key - must fail';
    my $input = "G=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 73: 0x48 as a single-character dictionary key
{
    my $test_name = '0x48 as a single-character dictionary key - must fail';
    my $input = "H=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 74: 0x49 as a single-character dictionary key
{
    my $test_name = '0x49 as a single-character dictionary key - must fail';
    my $input = "I=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 75: 0x4a as a single-character dictionary key
{
    my $test_name = '0x4a as a single-character dictionary key - must fail';
    my $input = "J=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 76: 0x4b as a single-character dictionary key
{
    my $test_name = '0x4b as a single-character dictionary key - must fail';
    my $input = "K=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 77: 0x4c as a single-character dictionary key
{
    my $test_name = '0x4c as a single-character dictionary key - must fail';
    my $input = "L=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 78: 0x4d as a single-character dictionary key
{
    my $test_name = '0x4d as a single-character dictionary key - must fail';
    my $input = "M=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 79: 0x4e as a single-character dictionary key
{
    my $test_name = '0x4e as a single-character dictionary key - must fail';
    my $input = "N=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 80: 0x4f as a single-character dictionary key
{
    my $test_name = '0x4f as a single-character dictionary key - must fail';
    my $input = "O=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 81: 0x50 as a single-character dictionary key
{
    my $test_name = '0x50 as a single-character dictionary key - must fail';
    my $input = "P=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 82: 0x51 as a single-character dictionary key
{
    my $test_name = '0x51 as a single-character dictionary key - must fail';
    my $input = "Q=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 83: 0x52 as a single-character dictionary key
{
    my $test_name = '0x52 as a single-character dictionary key - must fail';
    my $input = "R=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 84: 0x53 as a single-character dictionary key
{
    my $test_name = '0x53 as a single-character dictionary key - must fail';
    my $input = "S=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 85: 0x54 as a single-character dictionary key
{
    my $test_name = '0x54 as a single-character dictionary key - must fail';
    my $input = "T=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 86: 0x55 as a single-character dictionary key
{
    my $test_name = '0x55 as a single-character dictionary key - must fail';
    my $input = "U=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 87: 0x56 as a single-character dictionary key
{
    my $test_name = '0x56 as a single-character dictionary key - must fail';
    my $input = "V=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 88: 0x57 as a single-character dictionary key
{
    my $test_name = '0x57 as a single-character dictionary key - must fail';
    my $input = "W=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 89: 0x58 as a single-character dictionary key
{
    my $test_name = '0x58 as a single-character dictionary key - must fail';
    my $input = "X=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 90: 0x59 as a single-character dictionary key
{
    my $test_name = '0x59 as a single-character dictionary key - must fail';
    my $input = "Y=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 91: 0x5a as a single-character dictionary key
{
    my $test_name = '0x5a as a single-character dictionary key - must fail';
    my $input = "Z=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 92: 0x5b as a single-character dictionary key
{
    my $test_name = '0x5b as a single-character dictionary key - must fail';
    my $input = "[=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 93: 0x5c as a single-character dictionary key
{
    my $test_name = '0x5c as a single-character dictionary key - must fail';
    my $input = "\\=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 94: 0x5d as a single-character dictionary key
{
    my $test_name = '0x5d as a single-character dictionary key - must fail';
    my $input = "]=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 95: 0x5e as a single-character dictionary key
{
    my $test_name = '0x5e as a single-character dictionary key - must fail';
    my $input = "^=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 96: 0x5f as a single-character dictionary key
{
    my $test_name = '0x5f as a single-character dictionary key - must fail';
    my $input = "_=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 97: 0x60 as a single-character dictionary key
{
    my $test_name = '0x60 as a single-character dictionary key - must fail';
    my $input = "`=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 98: 0x61 as a single-character dictionary key
subtest "0x61 as a single-character dictionary key" => sub {
    my $test_name = "0x61 as a single-character dictionary key";
    my $input = "a=1";
    my $expected = _h( "a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 99: 0x62 as a single-character dictionary key
subtest "0x62 as a single-character dictionary key" => sub {
    my $test_name = "0x62 as a single-character dictionary key";
    my $input = "b=1";
    my $expected = _h( "b" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 100: 0x63 as a single-character dictionary key
subtest "0x63 as a single-character dictionary key" => sub {
    my $test_name = "0x63 as a single-character dictionary key";
    my $input = "c=1";
    my $expected = _h( "c" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 101: 0x64 as a single-character dictionary key
subtest "0x64 as a single-character dictionary key" => sub {
    my $test_name = "0x64 as a single-character dictionary key";
    my $input = "d=1";
    my $expected = _h( "d" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 102: 0x65 as a single-character dictionary key
subtest "0x65 as a single-character dictionary key" => sub {
    my $test_name = "0x65 as a single-character dictionary key";
    my $input = "e=1";
    my $expected = _h( "e" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 103: 0x66 as a single-character dictionary key
subtest "0x66 as a single-character dictionary key" => sub {
    my $test_name = "0x66 as a single-character dictionary key";
    my $input = "f=1";
    my $expected = _h( "f" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 104: 0x67 as a single-character dictionary key
subtest "0x67 as a single-character dictionary key" => sub {
    my $test_name = "0x67 as a single-character dictionary key";
    my $input = "g=1";
    my $expected = _h( "g" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 105: 0x68 as a single-character dictionary key
subtest "0x68 as a single-character dictionary key" => sub {
    my $test_name = "0x68 as a single-character dictionary key";
    my $input = "h=1";
    my $expected = _h( "h" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 106: 0x69 as a single-character dictionary key
subtest "0x69 as a single-character dictionary key" => sub {
    my $test_name = "0x69 as a single-character dictionary key";
    my $input = "i=1";
    my $expected = _h( "i" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 107: 0x6a as a single-character dictionary key
subtest "0x6a as a single-character dictionary key" => sub {
    my $test_name = "0x6a as a single-character dictionary key";
    my $input = "j=1";
    my $expected = _h( "j" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 108: 0x6b as a single-character dictionary key
subtest "0x6b as a single-character dictionary key" => sub {
    my $test_name = "0x6b as a single-character dictionary key";
    my $input = "k=1";
    my $expected = _h( "k" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 109: 0x6c as a single-character dictionary key
subtest "0x6c as a single-character dictionary key" => sub {
    my $test_name = "0x6c as a single-character dictionary key";
    my $input = "l=1";
    my $expected = _h( "l" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 110: 0x6d as a single-character dictionary key
subtest "0x6d as a single-character dictionary key" => sub {
    my $test_name = "0x6d as a single-character dictionary key";
    my $input = "m=1";
    my $expected = _h( "m" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 111: 0x6e as a single-character dictionary key
subtest "0x6e as a single-character dictionary key" => sub {
    my $test_name = "0x6e as a single-character dictionary key";
    my $input = "n=1";
    my $expected = _h( "n" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 112: 0x6f as a single-character dictionary key
subtest "0x6f as a single-character dictionary key" => sub {
    my $test_name = "0x6f as a single-character dictionary key";
    my $input = "o=1";
    my $expected = _h( "o" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 113: 0x70 as a single-character dictionary key
subtest "0x70 as a single-character dictionary key" => sub {
    my $test_name = "0x70 as a single-character dictionary key";
    my $input = "p=1";
    my $expected = _h( "p" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 114: 0x71 as a single-character dictionary key
subtest "0x71 as a single-character dictionary key" => sub {
    my $test_name = "0x71 as a single-character dictionary key";
    my $input = "q=1";
    my $expected = _h( "q" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 115: 0x72 as a single-character dictionary key
subtest "0x72 as a single-character dictionary key" => sub {
    my $test_name = "0x72 as a single-character dictionary key";
    my $input = "r=1";
    my $expected = _h( "r" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 116: 0x73 as a single-character dictionary key
subtest "0x73 as a single-character dictionary key" => sub {
    my $test_name = "0x73 as a single-character dictionary key";
    my $input = "s=1";
    my $expected = _h( "s" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 117: 0x74 as a single-character dictionary key
subtest "0x74 as a single-character dictionary key" => sub {
    my $test_name = "0x74 as a single-character dictionary key";
    my $input = "t=1";
    my $expected = _h( "t" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 118: 0x75 as a single-character dictionary key
subtest "0x75 as a single-character dictionary key" => sub {
    my $test_name = "0x75 as a single-character dictionary key";
    my $input = "u=1";
    my $expected = _h( "u" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 119: 0x76 as a single-character dictionary key
subtest "0x76 as a single-character dictionary key" => sub {
    my $test_name = "0x76 as a single-character dictionary key";
    my $input = "v=1";
    my $expected = _h( "v" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 120: 0x77 as a single-character dictionary key
subtest "0x77 as a single-character dictionary key" => sub {
    my $test_name = "0x77 as a single-character dictionary key";
    my $input = "w=1";
    my $expected = _h( "w" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 121: 0x78 as a single-character dictionary key
subtest "0x78 as a single-character dictionary key" => sub {
    my $test_name = "0x78 as a single-character dictionary key";
    my $input = "x=1";
    my $expected = _h( "x" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 122: 0x79 as a single-character dictionary key
subtest "0x79 as a single-character dictionary key" => sub {
    my $test_name = "0x79 as a single-character dictionary key";
    my $input = "y=1";
    my $expected = _h( "y" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 123: 0x7a as a single-character dictionary key
subtest "0x7a as a single-character dictionary key" => sub {
    my $test_name = "0x7a as a single-character dictionary key";
    my $input = "z=1";
    my $expected = _h( "z" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 124: 0x7b as a single-character dictionary key
{
    my $test_name = '0x7b as a single-character dictionary key - must fail';
    my $input = "{=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 125: 0x7c as a single-character dictionary key
{
    my $test_name = '0x7c as a single-character dictionary key - must fail';
    my $input = "|=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 126: 0x7d as a single-character dictionary key
{
    my $test_name = '0x7d as a single-character dictionary key - must fail';
    my $input = "}=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 127: 0x7e as a single-character dictionary key
{
    my $test_name = '0x7e as a single-character dictionary key - must fail';
    my $input = "~=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 128: 0x7f as a single-character dictionary key
{
    my $test_name = '0x7f as a single-character dictionary key - must fail';
    my $input = "\177=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 129: 0x00 in dictionary key
{
    my $test_name = '0x00 in dictionary key - must fail';
    my $input = "a\000a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 130: 0x01 in dictionary key
{
    my $test_name = '0x01 in dictionary key - must fail';
    my $input = "a\001a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 131: 0x02 in dictionary key
{
    my $test_name = '0x02 in dictionary key - must fail';
    my $input = "a\002a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 132: 0x03 in dictionary key
{
    my $test_name = '0x03 in dictionary key - must fail';
    my $input = "a\003a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 133: 0x04 in dictionary key
{
    my $test_name = '0x04 in dictionary key - must fail';
    my $input = "a\004a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 134: 0x05 in dictionary key
{
    my $test_name = '0x05 in dictionary key - must fail';
    my $input = "a\005a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 135: 0x06 in dictionary key
{
    my $test_name = '0x06 in dictionary key - must fail';
    my $input = "a\006a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 136: 0x07 in dictionary key
{
    my $test_name = '0x07 in dictionary key - must fail';
    my $input = "a\aa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 137: 0x08 in dictionary key
{
    my $test_name = '0x08 in dictionary key - must fail';
    my $input = "a\ba=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 138: 0x09 in dictionary key
{
    my $test_name = '0x09 in dictionary key - must fail';
    my $input = "a\ta=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 139: 0x0a in dictionary key
{
    my $test_name = '0x0a in dictionary key - must fail';
    my $input = "a\na=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 140: 0x0b in dictionary key
{
    my $test_name = '0x0b in dictionary key - must fail';
    my $input = "a\013a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 141: 0x0c in dictionary key
{
    my $test_name = '0x0c in dictionary key - must fail';
    my $input = "a\fa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 142: 0x0d in dictionary key
{
    my $test_name = '0x0d in dictionary key - must fail';
    my $input = "a\ra=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 143: 0x0e in dictionary key
{
    my $test_name = '0x0e in dictionary key - must fail';
    my $input = "a\016a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 144: 0x0f in dictionary key
{
    my $test_name = '0x0f in dictionary key - must fail';
    my $input = "a\017a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 145: 0x10 in dictionary key
{
    my $test_name = '0x10 in dictionary key - must fail';
    my $input = "a\020a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 146: 0x11 in dictionary key
{
    my $test_name = '0x11 in dictionary key - must fail';
    my $input = "a\021a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 147: 0x12 in dictionary key
{
    my $test_name = '0x12 in dictionary key - must fail';
    my $input = "a\022a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 148: 0x13 in dictionary key
{
    my $test_name = '0x13 in dictionary key - must fail';
    my $input = "a\023a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 149: 0x14 in dictionary key
{
    my $test_name = '0x14 in dictionary key - must fail';
    my $input = "a\024a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 150: 0x15 in dictionary key
{
    my $test_name = '0x15 in dictionary key - must fail';
    my $input = "a\025a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 151: 0x16 in dictionary key
{
    my $test_name = '0x16 in dictionary key - must fail';
    my $input = "a\026a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 152: 0x17 in dictionary key
{
    my $test_name = '0x17 in dictionary key - must fail';
    my $input = "a\027a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 153: 0x18 in dictionary key
{
    my $test_name = '0x18 in dictionary key - must fail';
    my $input = "a\030a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 154: 0x19 in dictionary key
{
    my $test_name = '0x19 in dictionary key - must fail';
    my $input = "a\031a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 155: 0x1a in dictionary key
{
    my $test_name = '0x1a in dictionary key - must fail';
    my $input = "a\032a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 156: 0x1b in dictionary key
{
    my $test_name = '0x1b in dictionary key - must fail';
    my $input = "a\033a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 157: 0x1c in dictionary key
{
    my $test_name = '0x1c in dictionary key - must fail';
    my $input = "a\034a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 158: 0x1d in dictionary key
{
    my $test_name = '0x1d in dictionary key - must fail';
    my $input = "a\035a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 159: 0x1e in dictionary key
{
    my $test_name = '0x1e in dictionary key - must fail';
    my $input = "a\036a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 160: 0x1f in dictionary key
{
    my $test_name = '0x1f in dictionary key - must fail';
    my $input = "a\037a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 161: 0x20 in dictionary key
{
    my $test_name = '0x20 in dictionary key - must fail';
    my $input = "a a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 162: 0x21 in dictionary key
{
    my $test_name = '0x21 in dictionary key - must fail';
    my $input = "a!a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 163: 0x22 in dictionary key
{
    my $test_name = '0x22 in dictionary key - must fail';
    my $input = "a\"a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 164: 0x23 in dictionary key
{
    my $test_name = '0x23 in dictionary key - must fail';
    my $input = "a#a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 165: 0x24 in dictionary key
{
    my $test_name = '0x24 in dictionary key - must fail';
    my $input = "a\$a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 166: 0x25 in dictionary key
{
    my $test_name = '0x25 in dictionary key - must fail';
    my $input = "a%a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 167: 0x26 in dictionary key
{
    my $test_name = '0x26 in dictionary key - must fail';
    my $input = "a&a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 168: 0x27 in dictionary key
{
    my $test_name = '0x27 in dictionary key - must fail';
    my $input = "a'a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 169: 0x28 in dictionary key
{
    my $test_name = '0x28 in dictionary key - must fail';
    my $input = "a(a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 170: 0x29 in dictionary key
{
    my $test_name = '0x29 in dictionary key - must fail';
    my $input = "a)a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 171: 0x2a in dictionary key
subtest "0x2a in dictionary key" => sub {
    my $test_name = "0x2a in dictionary key";
    my $input = "a*a=1";
    my $expected = _h( "a*a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 172: 0x2b in dictionary key
{
    my $test_name = '0x2b in dictionary key - must fail';
    my $input = "a+a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 173: 0x2c in dictionary key
subtest "0x2c in dictionary key" => sub {
    my $test_name = "0x2c in dictionary key";
    my $input = "a,a=1";
    my $expected = _h( "a" => { _type => 'integer', value => 1 } );
    my $canonical = "a=1";
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 174: 0x2d in dictionary key
subtest "0x2d in dictionary key" => sub {
    my $test_name = "0x2d in dictionary key";
    my $input = "a-a=1";
    my $expected = _h( "a-a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 175: 0x2e in dictionary key
subtest "0x2e in dictionary key" => sub {
    my $test_name = "0x2e in dictionary key";
    my $input = "a.a=1";
    my $expected = _h( "a.a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 176: 0x2f in dictionary key
{
    my $test_name = '0x2f in dictionary key - must fail';
    my $input = "a/a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 177: 0x30 in dictionary key
subtest "0x30 in dictionary key" => sub {
    my $test_name = "0x30 in dictionary key";
    my $input = "a0a=1";
    my $expected = _h( "a0a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 178: 0x31 in dictionary key
subtest "0x31 in dictionary key" => sub {
    my $test_name = "0x31 in dictionary key";
    my $input = "a1a=1";
    my $expected = _h( "a1a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 179: 0x32 in dictionary key
subtest "0x32 in dictionary key" => sub {
    my $test_name = "0x32 in dictionary key";
    my $input = "a2a=1";
    my $expected = _h( "a2a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 180: 0x33 in dictionary key
subtest "0x33 in dictionary key" => sub {
    my $test_name = "0x33 in dictionary key";
    my $input = "a3a=1";
    my $expected = _h( "a3a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 181: 0x34 in dictionary key
subtest "0x34 in dictionary key" => sub {
    my $test_name = "0x34 in dictionary key";
    my $input = "a4a=1";
    my $expected = _h( "a4a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 182: 0x35 in dictionary key
subtest "0x35 in dictionary key" => sub {
    my $test_name = "0x35 in dictionary key";
    my $input = "a5a=1";
    my $expected = _h( "a5a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 183: 0x36 in dictionary key
subtest "0x36 in dictionary key" => sub {
    my $test_name = "0x36 in dictionary key";
    my $input = "a6a=1";
    my $expected = _h( "a6a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 184: 0x37 in dictionary key
subtest "0x37 in dictionary key" => sub {
    my $test_name = "0x37 in dictionary key";
    my $input = "a7a=1";
    my $expected = _h( "a7a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 185: 0x38 in dictionary key
subtest "0x38 in dictionary key" => sub {
    my $test_name = "0x38 in dictionary key";
    my $input = "a8a=1";
    my $expected = _h( "a8a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 186: 0x39 in dictionary key
subtest "0x39 in dictionary key" => sub {
    my $test_name = "0x39 in dictionary key";
    my $input = "a9a=1";
    my $expected = _h( "a9a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 187: 0x3a in dictionary key
{
    my $test_name = '0x3a in dictionary key - must fail';
    my $input = "a:a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 188: 0x3b in dictionary key
subtest "0x3b in dictionary key" => sub {
    my $test_name = "0x3b in dictionary key";
    my $input = "a;a=1";
    my $expected = _h( "a" => { _type => 'boolean', value => 1, params => _h( "a" => { _type => 'integer', value => 1 } ) } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 189: 0x3c in dictionary key
{
    my $test_name = '0x3c in dictionary key - must fail';
    my $input = "a<a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 190: 0x3d in dictionary key
{
    my $test_name = '0x3d in dictionary key - must fail';
    my $input = "a=a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 191: 0x3e in dictionary key
{
    my $test_name = '0x3e in dictionary key - must fail';
    my $input = "a>a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 192: 0x3f in dictionary key
{
    my $test_name = '0x3f in dictionary key - must fail';
    my $input = "a?a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 193: 0x40 in dictionary key
{
    my $test_name = '0x40 in dictionary key - must fail';
    my $input = "a\@a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 194: 0x41 in dictionary key
{
    my $test_name = '0x41 in dictionary key - must fail';
    my $input = "aAa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 195: 0x42 in dictionary key
{
    my $test_name = '0x42 in dictionary key - must fail';
    my $input = "aBa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 196: 0x43 in dictionary key
{
    my $test_name = '0x43 in dictionary key - must fail';
    my $input = "aCa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 197: 0x44 in dictionary key
{
    my $test_name = '0x44 in dictionary key - must fail';
    my $input = "aDa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 198: 0x45 in dictionary key
{
    my $test_name = '0x45 in dictionary key - must fail';
    my $input = "aEa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 199: 0x46 in dictionary key
{
    my $test_name = '0x46 in dictionary key - must fail';
    my $input = "aFa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 200: 0x47 in dictionary key
{
    my $test_name = '0x47 in dictionary key - must fail';
    my $input = "aGa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 201: 0x48 in dictionary key
{
    my $test_name = '0x48 in dictionary key - must fail';
    my $input = "aHa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 202: 0x49 in dictionary key
{
    my $test_name = '0x49 in dictionary key - must fail';
    my $input = "aIa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 203: 0x4a in dictionary key
{
    my $test_name = '0x4a in dictionary key - must fail';
    my $input = "aJa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 204: 0x4b in dictionary key
{
    my $test_name = '0x4b in dictionary key - must fail';
    my $input = "aKa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 205: 0x4c in dictionary key
{
    my $test_name = '0x4c in dictionary key - must fail';
    my $input = "aLa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 206: 0x4d in dictionary key
{
    my $test_name = '0x4d in dictionary key - must fail';
    my $input = "aMa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 207: 0x4e in dictionary key
{
    my $test_name = '0x4e in dictionary key - must fail';
    my $input = "aNa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 208: 0x4f in dictionary key
{
    my $test_name = '0x4f in dictionary key - must fail';
    my $input = "aOa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 209: 0x50 in dictionary key
{
    my $test_name = '0x50 in dictionary key - must fail';
    my $input = "aPa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 210: 0x51 in dictionary key
{
    my $test_name = '0x51 in dictionary key - must fail';
    my $input = "aQa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 211: 0x52 in dictionary key
{
    my $test_name = '0x52 in dictionary key - must fail';
    my $input = "aRa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 212: 0x53 in dictionary key
{
    my $test_name = '0x53 in dictionary key - must fail';
    my $input = "aSa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 213: 0x54 in dictionary key
{
    my $test_name = '0x54 in dictionary key - must fail';
    my $input = "aTa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 214: 0x55 in dictionary key
{
    my $test_name = '0x55 in dictionary key - must fail';
    my $input = "aUa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 215: 0x56 in dictionary key
{
    my $test_name = '0x56 in dictionary key - must fail';
    my $input = "aVa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 216: 0x57 in dictionary key
{
    my $test_name = '0x57 in dictionary key - must fail';
    my $input = "aWa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 217: 0x58 in dictionary key
{
    my $test_name = '0x58 in dictionary key - must fail';
    my $input = "aXa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 218: 0x59 in dictionary key
{
    my $test_name = '0x59 in dictionary key - must fail';
    my $input = "aYa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 219: 0x5a in dictionary key
{
    my $test_name = '0x5a in dictionary key - must fail';
    my $input = "aZa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 220: 0x5b in dictionary key
{
    my $test_name = '0x5b in dictionary key - must fail';
    my $input = "a[a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 221: 0x5c in dictionary key
{
    my $test_name = '0x5c in dictionary key - must fail';
    my $input = "a\\a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 222: 0x5d in dictionary key
{
    my $test_name = '0x5d in dictionary key - must fail';
    my $input = "a]a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 223: 0x5e in dictionary key
{
    my $test_name = '0x5e in dictionary key - must fail';
    my $input = "a^a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 224: 0x5f in dictionary key
subtest "0x5f in dictionary key" => sub {
    my $test_name = "0x5f in dictionary key";
    my $input = "a_a=1";
    my $expected = _h( "a_a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 225: 0x60 in dictionary key
{
    my $test_name = '0x60 in dictionary key - must fail';
    my $input = "a`a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 226: 0x61 in dictionary key
subtest "0x61 in dictionary key" => sub {
    my $test_name = "0x61 in dictionary key";
    my $input = "aaa=1";
    my $expected = _h( "aaa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 227: 0x62 in dictionary key
subtest "0x62 in dictionary key" => sub {
    my $test_name = "0x62 in dictionary key";
    my $input = "aba=1";
    my $expected = _h( "aba" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 228: 0x63 in dictionary key
subtest "0x63 in dictionary key" => sub {
    my $test_name = "0x63 in dictionary key";
    my $input = "aca=1";
    my $expected = _h( "aca" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 229: 0x64 in dictionary key
subtest "0x64 in dictionary key" => sub {
    my $test_name = "0x64 in dictionary key";
    my $input = "ada=1";
    my $expected = _h( "ada" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 230: 0x65 in dictionary key
subtest "0x65 in dictionary key" => sub {
    my $test_name = "0x65 in dictionary key";
    my $input = "aea=1";
    my $expected = _h( "aea" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 231: 0x66 in dictionary key
subtest "0x66 in dictionary key" => sub {
    my $test_name = "0x66 in dictionary key";
    my $input = "afa=1";
    my $expected = _h( "afa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 232: 0x67 in dictionary key
subtest "0x67 in dictionary key" => sub {
    my $test_name = "0x67 in dictionary key";
    my $input = "aga=1";
    my $expected = _h( "aga" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 233: 0x68 in dictionary key
subtest "0x68 in dictionary key" => sub {
    my $test_name = "0x68 in dictionary key";
    my $input = "aha=1";
    my $expected = _h( "aha" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 234: 0x69 in dictionary key
subtest "0x69 in dictionary key" => sub {
    my $test_name = "0x69 in dictionary key";
    my $input = "aia=1";
    my $expected = _h( "aia" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 235: 0x6a in dictionary key
subtest "0x6a in dictionary key" => sub {
    my $test_name = "0x6a in dictionary key";
    my $input = "aja=1";
    my $expected = _h( "aja" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 236: 0x6b in dictionary key
subtest "0x6b in dictionary key" => sub {
    my $test_name = "0x6b in dictionary key";
    my $input = "aka=1";
    my $expected = _h( "aka" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 237: 0x6c in dictionary key
subtest "0x6c in dictionary key" => sub {
    my $test_name = "0x6c in dictionary key";
    my $input = "ala=1";
    my $expected = _h( "ala" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 238: 0x6d in dictionary key
subtest "0x6d in dictionary key" => sub {
    my $test_name = "0x6d in dictionary key";
    my $input = "ama=1";
    my $expected = _h( "ama" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 239: 0x6e in dictionary key
subtest "0x6e in dictionary key" => sub {
    my $test_name = "0x6e in dictionary key";
    my $input = "ana=1";
    my $expected = _h( "ana" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 240: 0x6f in dictionary key
subtest "0x6f in dictionary key" => sub {
    my $test_name = "0x6f in dictionary key";
    my $input = "aoa=1";
    my $expected = _h( "aoa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 241: 0x70 in dictionary key
subtest "0x70 in dictionary key" => sub {
    my $test_name = "0x70 in dictionary key";
    my $input = "apa=1";
    my $expected = _h( "apa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 242: 0x71 in dictionary key
subtest "0x71 in dictionary key" => sub {
    my $test_name = "0x71 in dictionary key";
    my $input = "aqa=1";
    my $expected = _h( "aqa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 243: 0x72 in dictionary key
subtest "0x72 in dictionary key" => sub {
    my $test_name = "0x72 in dictionary key";
    my $input = "ara=1";
    my $expected = _h( "ara" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 244: 0x73 in dictionary key
subtest "0x73 in dictionary key" => sub {
    my $test_name = "0x73 in dictionary key";
    my $input = "asa=1";
    my $expected = _h( "asa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 245: 0x74 in dictionary key
subtest "0x74 in dictionary key" => sub {
    my $test_name = "0x74 in dictionary key";
    my $input = "ata=1";
    my $expected = _h( "ata" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 246: 0x75 in dictionary key
subtest "0x75 in dictionary key" => sub {
    my $test_name = "0x75 in dictionary key";
    my $input = "aua=1";
    my $expected = _h( "aua" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 247: 0x76 in dictionary key
subtest "0x76 in dictionary key" => sub {
    my $test_name = "0x76 in dictionary key";
    my $input = "ava=1";
    my $expected = _h( "ava" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 248: 0x77 in dictionary key
subtest "0x77 in dictionary key" => sub {
    my $test_name = "0x77 in dictionary key";
    my $input = "awa=1";
    my $expected = _h( "awa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 249: 0x78 in dictionary key
subtest "0x78 in dictionary key" => sub {
    my $test_name = "0x78 in dictionary key";
    my $input = "axa=1";
    my $expected = _h( "axa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 250: 0x79 in dictionary key
subtest "0x79 in dictionary key" => sub {
    my $test_name = "0x79 in dictionary key";
    my $input = "aya=1";
    my $expected = _h( "aya" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 251: 0x7a in dictionary key
subtest "0x7a in dictionary key" => sub {
    my $test_name = "0x7a in dictionary key";
    my $input = "aza=1";
    my $expected = _h( "aza" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 252: 0x7b in dictionary key
{
    my $test_name = '0x7b in dictionary key - must fail';
    my $input = "a{a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 253: 0x7c in dictionary key
{
    my $test_name = '0x7c in dictionary key - must fail';
    my $input = "a|a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 254: 0x7d in dictionary key
{
    my $test_name = '0x7d in dictionary key - must fail';
    my $input = "a}a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 255: 0x7e in dictionary key
{
    my $test_name = '0x7e in dictionary key - must fail';
    my $input = "a~a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 256: 0x7f in dictionary key
{
    my $test_name = '0x7f in dictionary key - must fail';
    my $input = "a\177a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 257: 0x00 starting a dictionary key
{
    my $test_name = '0x00 starting a dictionary key - must fail';
    my $input = "\000a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 258: 0x01 starting a dictionary key
{
    my $test_name = '0x01 starting a dictionary key - must fail';
    my $input = "\001a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 259: 0x02 starting a dictionary key
{
    my $test_name = '0x02 starting a dictionary key - must fail';
    my $input = "\002a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 260: 0x03 starting a dictionary key
{
    my $test_name = '0x03 starting a dictionary key - must fail';
    my $input = "\003a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 261: 0x04 starting a dictionary key
{
    my $test_name = '0x04 starting a dictionary key - must fail';
    my $input = "\004a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 262: 0x05 starting a dictionary key
{
    my $test_name = '0x05 starting a dictionary key - must fail';
    my $input = "\005a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 263: 0x06 starting a dictionary key
{
    my $test_name = '0x06 starting a dictionary key - must fail';
    my $input = "\006a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 264: 0x07 starting a dictionary key
{
    my $test_name = '0x07 starting a dictionary key - must fail';
    my $input = "\aa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 265: 0x08 starting a dictionary key
{
    my $test_name = '0x08 starting a dictionary key - must fail';
    my $input = "\ba=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 266: 0x09 starting a dictionary key
{
    my $test_name = '0x09 starting a dictionary key - must fail';
    my $input = "\ta=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 267: 0x0a starting a dictionary key
{
    my $test_name = '0x0a starting a dictionary key - must fail';
    my $input = "\na=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 268: 0x0b starting a dictionary key
{
    my $test_name = '0x0b starting a dictionary key - must fail';
    my $input = "\013a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 269: 0x0c starting a dictionary key
{
    my $test_name = '0x0c starting a dictionary key - must fail';
    my $input = "\fa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 270: 0x0d starting a dictionary key
{
    my $test_name = '0x0d starting a dictionary key - must fail';
    my $input = "\ra=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 271: 0x0e starting a dictionary key
{
    my $test_name = '0x0e starting a dictionary key - must fail';
    my $input = "\016a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 272: 0x0f starting a dictionary key
{
    my $test_name = '0x0f starting a dictionary key - must fail';
    my $input = "\017a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 273: 0x10 starting a dictionary key
{
    my $test_name = '0x10 starting a dictionary key - must fail';
    my $input = "\020a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 274: 0x11 starting a dictionary key
{
    my $test_name = '0x11 starting a dictionary key - must fail';
    my $input = "\021a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 275: 0x12 starting a dictionary key
{
    my $test_name = '0x12 starting a dictionary key - must fail';
    my $input = "\022a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 276: 0x13 starting a dictionary key
{
    my $test_name = '0x13 starting a dictionary key - must fail';
    my $input = "\023a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 277: 0x14 starting a dictionary key
{
    my $test_name = '0x14 starting a dictionary key - must fail';
    my $input = "\024a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 278: 0x15 starting a dictionary key
{
    my $test_name = '0x15 starting a dictionary key - must fail';
    my $input = "\025a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 279: 0x16 starting a dictionary key
{
    my $test_name = '0x16 starting a dictionary key - must fail';
    my $input = "\026a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 280: 0x17 starting a dictionary key
{
    my $test_name = '0x17 starting a dictionary key - must fail';
    my $input = "\027a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 281: 0x18 starting a dictionary key
{
    my $test_name = '0x18 starting a dictionary key - must fail';
    my $input = "\030a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 282: 0x19 starting a dictionary key
{
    my $test_name = '0x19 starting a dictionary key - must fail';
    my $input = "\031a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 283: 0x1a starting a dictionary key
{
    my $test_name = '0x1a starting a dictionary key - must fail';
    my $input = "\032a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 284: 0x1b starting a dictionary key
{
    my $test_name = '0x1b starting a dictionary key - must fail';
    my $input = "\033a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 285: 0x1c starting a dictionary key
{
    my $test_name = '0x1c starting a dictionary key - must fail';
    my $input = "\034a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 286: 0x1d starting a dictionary key
{
    my $test_name = '0x1d starting a dictionary key - must fail';
    my $input = "\035a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 287: 0x1e starting a dictionary key
{
    my $test_name = '0x1e starting a dictionary key - must fail';
    my $input = "\036a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 288: 0x1f starting a dictionary key
{
    my $test_name = '0x1f starting a dictionary key - must fail';
    my $input = "\037a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 289: 0x20 starting a dictionary key
subtest "0x20 starting a dictionary key" => sub {
    my $test_name = "0x20 starting a dictionary key";
    my $input = " a=1";
    my $expected = _h( "a" => { _type => 'integer', value => 1 } );
    my $canonical = "a=1";
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 290: 0x21 starting a dictionary key
{
    my $test_name = '0x21 starting a dictionary key - must fail';
    my $input = "!a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 291: 0x22 starting a dictionary key
{
    my $test_name = '0x22 starting a dictionary key - must fail';
    my $input = "\"a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 292: 0x23 starting a dictionary key
{
    my $test_name = '0x23 starting a dictionary key - must fail';
    my $input = "#a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 293: 0x24 starting a dictionary key
{
    my $test_name = '0x24 starting a dictionary key - must fail';
    my $input = "\$a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 294: 0x25 starting a dictionary key
{
    my $test_name = '0x25 starting a dictionary key - must fail';
    my $input = "%a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 295: 0x26 starting a dictionary key
{
    my $test_name = '0x26 starting a dictionary key - must fail';
    my $input = "&a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 296: 0x27 starting a dictionary key
{
    my $test_name = '0x27 starting a dictionary key - must fail';
    my $input = "'a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 297: 0x28 starting a dictionary key
{
    my $test_name = '0x28 starting a dictionary key - must fail';
    my $input = "(a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 298: 0x29 starting a dictionary key
{
    my $test_name = '0x29 starting a dictionary key - must fail';
    my $input = ")a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 299: 0x2a starting a dictionary key
subtest "0x2a starting a dictionary key" => sub {
    my $test_name = "0x2a starting a dictionary key";
    my $input = "*a=1";
    my $expected = _h( "*a" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 300: 0x2b starting a dictionary key
{
    my $test_name = '0x2b starting a dictionary key - must fail';
    my $input = "+a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 301: 0x2c starting a dictionary key
{
    my $test_name = '0x2c starting a dictionary key - must fail';
    my $input = ",a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 302: 0x2d starting a dictionary key
{
    my $test_name = '0x2d starting a dictionary key - must fail';
    my $input = "-a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 303: 0x2e starting a dictionary key
{
    my $test_name = '0x2e starting a dictionary key - must fail';
    my $input = ".a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 304: 0x2f starting a dictionary key
{
    my $test_name = '0x2f starting a dictionary key - must fail';
    my $input = "/a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 305: 0x30 starting a dictionary key
{
    my $test_name = '0x30 starting a dictionary key - must fail';
    my $input = "0a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 306: 0x31 starting a dictionary key
{
    my $test_name = '0x31 starting a dictionary key - must fail';
    my $input = "1a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 307: 0x32 starting a dictionary key
{
    my $test_name = '0x32 starting a dictionary key - must fail';
    my $input = "2a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 308: 0x33 starting a dictionary key
{
    my $test_name = '0x33 starting a dictionary key - must fail';
    my $input = "3a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 309: 0x34 starting a dictionary key
{
    my $test_name = '0x34 starting a dictionary key - must fail';
    my $input = "4a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 310: 0x35 starting a dictionary key
{
    my $test_name = '0x35 starting a dictionary key - must fail';
    my $input = "5a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 311: 0x36 starting a dictionary key
{
    my $test_name = '0x36 starting a dictionary key - must fail';
    my $input = "6a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 312: 0x37 starting a dictionary key
{
    my $test_name = '0x37 starting a dictionary key - must fail';
    my $input = "7a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 313: 0x38 starting a dictionary key
{
    my $test_name = '0x38 starting a dictionary key - must fail';
    my $input = "8a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 314: 0x39 starting a dictionary key
{
    my $test_name = '0x39 starting a dictionary key - must fail';
    my $input = "9a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 315: 0x3a starting a dictionary key
{
    my $test_name = '0x3a starting a dictionary key - must fail';
    my $input = ":a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 316: 0x3b starting a dictionary key
{
    my $test_name = '0x3b starting a dictionary key - must fail';
    my $input = ";a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 317: 0x3c starting a dictionary key
{
    my $test_name = '0x3c starting a dictionary key - must fail';
    my $input = "<a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 318: 0x3d starting a dictionary key
{
    my $test_name = '0x3d starting a dictionary key - must fail';
    my $input = "=a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 319: 0x3e starting a dictionary key
{
    my $test_name = '0x3e starting a dictionary key - must fail';
    my $input = ">a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 320: 0x3f starting a dictionary key
{
    my $test_name = '0x3f starting a dictionary key - must fail';
    my $input = "?a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 321: 0x40 starting a dictionary key
{
    my $test_name = '0x40 starting a dictionary key - must fail';
    my $input = "\@a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 322: 0x41 starting a dictionary key
{
    my $test_name = '0x41 starting a dictionary key - must fail';
    my $input = "Aa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 323: 0x42 starting a dictionary key
{
    my $test_name = '0x42 starting a dictionary key - must fail';
    my $input = "Ba=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 324: 0x43 starting a dictionary key
{
    my $test_name = '0x43 starting a dictionary key - must fail';
    my $input = "Ca=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 325: 0x44 starting a dictionary key
{
    my $test_name = '0x44 starting a dictionary key - must fail';
    my $input = "Da=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 326: 0x45 starting a dictionary key
{
    my $test_name = '0x45 starting a dictionary key - must fail';
    my $input = "Ea=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 327: 0x46 starting a dictionary key
{
    my $test_name = '0x46 starting a dictionary key - must fail';
    my $input = "Fa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 328: 0x47 starting a dictionary key
{
    my $test_name = '0x47 starting a dictionary key - must fail';
    my $input = "Ga=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 329: 0x48 starting a dictionary key
{
    my $test_name = '0x48 starting a dictionary key - must fail';
    my $input = "Ha=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 330: 0x49 starting a dictionary key
{
    my $test_name = '0x49 starting a dictionary key - must fail';
    my $input = "Ia=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 331: 0x4a starting a dictionary key
{
    my $test_name = '0x4a starting a dictionary key - must fail';
    my $input = "Ja=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 332: 0x4b starting a dictionary key
{
    my $test_name = '0x4b starting a dictionary key - must fail';
    my $input = "Ka=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 333: 0x4c starting a dictionary key
{
    my $test_name = '0x4c starting a dictionary key - must fail';
    my $input = "La=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 334: 0x4d starting a dictionary key
{
    my $test_name = '0x4d starting a dictionary key - must fail';
    my $input = "Ma=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 335: 0x4e starting a dictionary key
{
    my $test_name = '0x4e starting a dictionary key - must fail';
    my $input = "Na=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 336: 0x4f starting a dictionary key
{
    my $test_name = '0x4f starting a dictionary key - must fail';
    my $input = "Oa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 337: 0x50 starting a dictionary key
{
    my $test_name = '0x50 starting a dictionary key - must fail';
    my $input = "Pa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 338: 0x51 starting a dictionary key
{
    my $test_name = '0x51 starting a dictionary key - must fail';
    my $input = "Qa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 339: 0x52 starting a dictionary key
{
    my $test_name = '0x52 starting a dictionary key - must fail';
    my $input = "Ra=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 340: 0x53 starting a dictionary key
{
    my $test_name = '0x53 starting a dictionary key - must fail';
    my $input = "Sa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 341: 0x54 starting a dictionary key
{
    my $test_name = '0x54 starting a dictionary key - must fail';
    my $input = "Ta=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 342: 0x55 starting a dictionary key
{
    my $test_name = '0x55 starting a dictionary key - must fail';
    my $input = "Ua=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 343: 0x56 starting a dictionary key
{
    my $test_name = '0x56 starting a dictionary key - must fail';
    my $input = "Va=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 344: 0x57 starting a dictionary key
{
    my $test_name = '0x57 starting a dictionary key - must fail';
    my $input = "Wa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 345: 0x58 starting a dictionary key
{
    my $test_name = '0x58 starting a dictionary key - must fail';
    my $input = "Xa=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 346: 0x59 starting a dictionary key
{
    my $test_name = '0x59 starting a dictionary key - must fail';
    my $input = "Ya=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 347: 0x5a starting a dictionary key
{
    my $test_name = '0x5a starting a dictionary key - must fail';
    my $input = "Za=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 348: 0x5b starting a dictionary key
{
    my $test_name = '0x5b starting a dictionary key - must fail';
    my $input = "[a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 349: 0x5c starting a dictionary key
{
    my $test_name = '0x5c starting a dictionary key - must fail';
    my $input = "\\a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 350: 0x5d starting a dictionary key
{
    my $test_name = '0x5d starting a dictionary key - must fail';
    my $input = "]a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 351: 0x5e starting a dictionary key
{
    my $test_name = '0x5e starting a dictionary key - must fail';
    my $input = "^a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 352: 0x5f starting a dictionary key
{
    my $test_name = '0x5f starting a dictionary key - must fail';
    my $input = "_a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 353: 0x60 starting a dictionary key
{
    my $test_name = '0x60 starting a dictionary key - must fail';
    my $input = "`a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 354: 0x61 starting a dictionary key
subtest "0x61 starting a dictionary key" => sub {
    my $test_name = "0x61 starting a dictionary key";
    my $input = "aa=1";
    my $expected = _h( "aa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 355: 0x62 starting a dictionary key
subtest "0x62 starting a dictionary key" => sub {
    my $test_name = "0x62 starting a dictionary key";
    my $input = "ba=1";
    my $expected = _h( "ba" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 356: 0x63 starting a dictionary key
subtest "0x63 starting a dictionary key" => sub {
    my $test_name = "0x63 starting a dictionary key";
    my $input = "ca=1";
    my $expected = _h( "ca" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 357: 0x64 starting a dictionary key
subtest "0x64 starting a dictionary key" => sub {
    my $test_name = "0x64 starting a dictionary key";
    my $input = "da=1";
    my $expected = _h( "da" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 358: 0x65 starting a dictionary key
subtest "0x65 starting a dictionary key" => sub {
    my $test_name = "0x65 starting a dictionary key";
    my $input = "ea=1";
    my $expected = _h( "ea" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 359: 0x66 starting a dictionary key
subtest "0x66 starting a dictionary key" => sub {
    my $test_name = "0x66 starting a dictionary key";
    my $input = "fa=1";
    my $expected = _h( "fa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 360: 0x67 starting a dictionary key
subtest "0x67 starting a dictionary key" => sub {
    my $test_name = "0x67 starting a dictionary key";
    my $input = "ga=1";
    my $expected = _h( "ga" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 361: 0x68 starting a dictionary key
subtest "0x68 starting a dictionary key" => sub {
    my $test_name = "0x68 starting a dictionary key";
    my $input = "ha=1";
    my $expected = _h( "ha" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 362: 0x69 starting a dictionary key
subtest "0x69 starting a dictionary key" => sub {
    my $test_name = "0x69 starting a dictionary key";
    my $input = "ia=1";
    my $expected = _h( "ia" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 363: 0x6a starting a dictionary key
subtest "0x6a starting a dictionary key" => sub {
    my $test_name = "0x6a starting a dictionary key";
    my $input = "ja=1";
    my $expected = _h( "ja" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 364: 0x6b starting a dictionary key
subtest "0x6b starting a dictionary key" => sub {
    my $test_name = "0x6b starting a dictionary key";
    my $input = "ka=1";
    my $expected = _h( "ka" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 365: 0x6c starting a dictionary key
subtest "0x6c starting a dictionary key" => sub {
    my $test_name = "0x6c starting a dictionary key";
    my $input = "la=1";
    my $expected = _h( "la" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 366: 0x6d starting a dictionary key
subtest "0x6d starting a dictionary key" => sub {
    my $test_name = "0x6d starting a dictionary key";
    my $input = "ma=1";
    my $expected = _h( "ma" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 367: 0x6e starting a dictionary key
subtest "0x6e starting a dictionary key" => sub {
    my $test_name = "0x6e starting a dictionary key";
    my $input = "na=1";
    my $expected = _h( "na" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 368: 0x6f starting a dictionary key
subtest "0x6f starting a dictionary key" => sub {
    my $test_name = "0x6f starting a dictionary key";
    my $input = "oa=1";
    my $expected = _h( "oa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 369: 0x70 starting a dictionary key
subtest "0x70 starting a dictionary key" => sub {
    my $test_name = "0x70 starting a dictionary key";
    my $input = "pa=1";
    my $expected = _h( "pa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 370: 0x71 starting a dictionary key
subtest "0x71 starting a dictionary key" => sub {
    my $test_name = "0x71 starting a dictionary key";
    my $input = "qa=1";
    my $expected = _h( "qa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 371: 0x72 starting a dictionary key
subtest "0x72 starting a dictionary key" => sub {
    my $test_name = "0x72 starting a dictionary key";
    my $input = "ra=1";
    my $expected = _h( "ra" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 372: 0x73 starting a dictionary key
subtest "0x73 starting a dictionary key" => sub {
    my $test_name = "0x73 starting a dictionary key";
    my $input = "sa=1";
    my $expected = _h( "sa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 373: 0x74 starting a dictionary key
subtest "0x74 starting a dictionary key" => sub {
    my $test_name = "0x74 starting a dictionary key";
    my $input = "ta=1";
    my $expected = _h( "ta" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 374: 0x75 starting a dictionary key
subtest "0x75 starting a dictionary key" => sub {
    my $test_name = "0x75 starting a dictionary key";
    my $input = "ua=1";
    my $expected = _h( "ua" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 375: 0x76 starting a dictionary key
subtest "0x76 starting a dictionary key" => sub {
    my $test_name = "0x76 starting a dictionary key";
    my $input = "va=1";
    my $expected = _h( "va" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 376: 0x77 starting a dictionary key
subtest "0x77 starting a dictionary key" => sub {
    my $test_name = "0x77 starting a dictionary key";
    my $input = "wa=1";
    my $expected = _h( "wa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 377: 0x78 starting a dictionary key
subtest "0x78 starting a dictionary key" => sub {
    my $test_name = "0x78 starting a dictionary key";
    my $input = "xa=1";
    my $expected = _h( "xa" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 378: 0x79 starting a dictionary key
subtest "0x79 starting a dictionary key" => sub {
    my $test_name = "0x79 starting a dictionary key";
    my $input = "ya=1";
    my $expected = _h( "ya" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 379: 0x7a starting a dictionary key
subtest "0x7a starting a dictionary key" => sub {
    my $test_name = "0x7a starting a dictionary key";
    my $input = "za=1";
    my $expected = _h( "za" => { _type => 'integer', value => 1 } );
    my $canonical = $input;
    
    my $result = eval { decode_dictionary($input); };
    
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

# Test 380: 0x7b starting a dictionary key
{
    my $test_name = '0x7b starting a dictionary key - must fail';
    my $input = "{a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 381: 0x7c starting a dictionary key
{
    my $test_name = '0x7c starting a dictionary key - must fail';
    my $input = "|a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 382: 0x7d starting a dictionary key
{
    my $test_name = '0x7d starting a dictionary key - must fail';
    my $input = "}a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 383: 0x7e starting a dictionary key
{
    my $test_name = '0x7e starting a dictionary key - must fail';
    my $input = "~a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 384: 0x7f starting a dictionary key
{
    my $test_name = '0x7f starting a dictionary key - must fail';
    my $input = "\177a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 385: 0x00 in parameterised list key
{
    my $test_name = '0x00 in parameterised list key - must fail';
    my $input = "foo; a\000a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 386: 0x01 in parameterised list key
{
    my $test_name = '0x01 in parameterised list key - must fail';
    my $input = "foo; a\001a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 387: 0x02 in parameterised list key
{
    my $test_name = '0x02 in parameterised list key - must fail';
    my $input = "foo; a\002a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 388: 0x03 in parameterised list key
{
    my $test_name = '0x03 in parameterised list key - must fail';
    my $input = "foo; a\003a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 389: 0x04 in parameterised list key
{
    my $test_name = '0x04 in parameterised list key - must fail';
    my $input = "foo; a\004a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 390: 0x05 in parameterised list key
{
    my $test_name = '0x05 in parameterised list key - must fail';
    my $input = "foo; a\005a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 391: 0x06 in parameterised list key
{
    my $test_name = '0x06 in parameterised list key - must fail';
    my $input = "foo; a\006a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 392: 0x07 in parameterised list key
{
    my $test_name = '0x07 in parameterised list key - must fail';
    my $input = "foo; a\aa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 393: 0x08 in parameterised list key
{
    my $test_name = '0x08 in parameterised list key - must fail';
    my $input = "foo; a\ba=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 394: 0x09 in parameterised list key
{
    my $test_name = '0x09 in parameterised list key - must fail';
    my $input = "foo; a\ta=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 395: 0x0a in parameterised list key
{
    my $test_name = '0x0a in parameterised list key - must fail';
    my $input = "foo; a\na=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 396: 0x0b in parameterised list key
{
    my $test_name = '0x0b in parameterised list key - must fail';
    my $input = "foo; a\013a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 397: 0x0c in parameterised list key
{
    my $test_name = '0x0c in parameterised list key - must fail';
    my $input = "foo; a\fa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 398: 0x0d in parameterised list key
{
    my $test_name = '0x0d in parameterised list key - must fail';
    my $input = "foo; a\ra=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 399: 0x0e in parameterised list key
{
    my $test_name = '0x0e in parameterised list key - must fail';
    my $input = "foo; a\016a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 400: 0x0f in parameterised list key
{
    my $test_name = '0x0f in parameterised list key - must fail';
    my $input = "foo; a\017a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 401: 0x10 in parameterised list key
{
    my $test_name = '0x10 in parameterised list key - must fail';
    my $input = "foo; a\020a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 402: 0x11 in parameterised list key
{
    my $test_name = '0x11 in parameterised list key - must fail';
    my $input = "foo; a\021a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 403: 0x12 in parameterised list key
{
    my $test_name = '0x12 in parameterised list key - must fail';
    my $input = "foo; a\022a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 404: 0x13 in parameterised list key
{
    my $test_name = '0x13 in parameterised list key - must fail';
    my $input = "foo; a\023a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 405: 0x14 in parameterised list key
{
    my $test_name = '0x14 in parameterised list key - must fail';
    my $input = "foo; a\024a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 406: 0x15 in parameterised list key
{
    my $test_name = '0x15 in parameterised list key - must fail';
    my $input = "foo; a\025a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 407: 0x16 in parameterised list key
{
    my $test_name = '0x16 in parameterised list key - must fail';
    my $input = "foo; a\026a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 408: 0x17 in parameterised list key
{
    my $test_name = '0x17 in parameterised list key - must fail';
    my $input = "foo; a\027a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 409: 0x18 in parameterised list key
{
    my $test_name = '0x18 in parameterised list key - must fail';
    my $input = "foo; a\030a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 410: 0x19 in parameterised list key
{
    my $test_name = '0x19 in parameterised list key - must fail';
    my $input = "foo; a\031a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 411: 0x1a in parameterised list key
{
    my $test_name = '0x1a in parameterised list key - must fail';
    my $input = "foo; a\032a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 412: 0x1b in parameterised list key
{
    my $test_name = '0x1b in parameterised list key - must fail';
    my $input = "foo; a\033a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 413: 0x1c in parameterised list key
{
    my $test_name = '0x1c in parameterised list key - must fail';
    my $input = "foo; a\034a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 414: 0x1d in parameterised list key
{
    my $test_name = '0x1d in parameterised list key - must fail';
    my $input = "foo; a\035a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 415: 0x1e in parameterised list key
{
    my $test_name = '0x1e in parameterised list key - must fail';
    my $input = "foo; a\036a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 416: 0x1f in parameterised list key
{
    my $test_name = '0x1f in parameterised list key - must fail';
    my $input = "foo; a\037a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 417: 0x20 in parameterised list key
{
    my $test_name = '0x20 in parameterised list key - must fail';
    my $input = "foo; a a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 418: 0x21 in parameterised list key
{
    my $test_name = '0x21 in parameterised list key - must fail';
    my $input = "foo; a!a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 419: 0x22 in parameterised list key
{
    my $test_name = '0x22 in parameterised list key - must fail';
    my $input = "foo; a\"a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 420: 0x23 in parameterised list key
{
    my $test_name = '0x23 in parameterised list key - must fail';
    my $input = "foo; a#a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 421: 0x24 in parameterised list key
{
    my $test_name = '0x24 in parameterised list key - must fail';
    my $input = "foo; a\$a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 422: 0x25 in parameterised list key
{
    my $test_name = '0x25 in parameterised list key - must fail';
    my $input = "foo; a%a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 423: 0x26 in parameterised list key
{
    my $test_name = '0x26 in parameterised list key - must fail';
    my $input = "foo; a&a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 424: 0x27 in parameterised list key
{
    my $test_name = '0x27 in parameterised list key - must fail';
    my $input = "foo; a'a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 425: 0x28 in parameterised list key
{
    my $test_name = '0x28 in parameterised list key - must fail';
    my $input = "foo; a(a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 426: 0x29 in parameterised list key
{
    my $test_name = '0x29 in parameterised list key - must fail';
    my $input = "foo; a)a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 427: 0x2a in parameterised list key
subtest "0x2a in parameterised list key" => sub {
    my $test_name = "0x2a in parameterised list key";
    my $input = "foo; a*a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a*a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a*a=1";
    
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

# Test 428: 0x2b in parameterised list key
{
    my $test_name = '0x2b in parameterised list key - must fail';
    my $input = "foo; a+a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 429: 0x2c in parameterised list key
{
    my $test_name = '0x2c in parameterised list key - must fail';
    my $input = "foo; a,a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 430: 0x2d in parameterised list key
subtest "0x2d in parameterised list key" => sub {
    my $test_name = "0x2d in parameterised list key";
    my $input = "foo; a-a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a-a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a-a=1";
    
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

# Test 431: 0x2e in parameterised list key
subtest "0x2e in parameterised list key" => sub {
    my $test_name = "0x2e in parameterised list key";
    my $input = "foo; a.a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a.a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a.a=1";
    
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

# Test 432: 0x2f in parameterised list key
{
    my $test_name = '0x2f in parameterised list key - must fail';
    my $input = "foo; a/a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 433: 0x30 in parameterised list key
subtest "0x30 in parameterised list key" => sub {
    my $test_name = "0x30 in parameterised list key";
    my $input = "foo; a0a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a0a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a0a=1";
    
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

# Test 434: 0x31 in parameterised list key
subtest "0x31 in parameterised list key" => sub {
    my $test_name = "0x31 in parameterised list key";
    my $input = "foo; a1a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a1a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a1a=1";
    
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

# Test 435: 0x32 in parameterised list key
subtest "0x32 in parameterised list key" => sub {
    my $test_name = "0x32 in parameterised list key";
    my $input = "foo; a2a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a2a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a2a=1";
    
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

# Test 436: 0x33 in parameterised list key
subtest "0x33 in parameterised list key" => sub {
    my $test_name = "0x33 in parameterised list key";
    my $input = "foo; a3a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a3a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a3a=1";
    
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

# Test 437: 0x34 in parameterised list key
subtest "0x34 in parameterised list key" => sub {
    my $test_name = "0x34 in parameterised list key";
    my $input = "foo; a4a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a4a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a4a=1";
    
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

# Test 438: 0x35 in parameterised list key
subtest "0x35 in parameterised list key" => sub {
    my $test_name = "0x35 in parameterised list key";
    my $input = "foo; a5a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a5a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a5a=1";
    
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

# Test 439: 0x36 in parameterised list key
subtest "0x36 in parameterised list key" => sub {
    my $test_name = "0x36 in parameterised list key";
    my $input = "foo; a6a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a6a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a6a=1";
    
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

# Test 440: 0x37 in parameterised list key
subtest "0x37 in parameterised list key" => sub {
    my $test_name = "0x37 in parameterised list key";
    my $input = "foo; a7a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a7a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a7a=1";
    
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

# Test 441: 0x38 in parameterised list key
subtest "0x38 in parameterised list key" => sub {
    my $test_name = "0x38 in parameterised list key";
    my $input = "foo; a8a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a8a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a8a=1";
    
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

# Test 442: 0x39 in parameterised list key
subtest "0x39 in parameterised list key" => sub {
    my $test_name = "0x39 in parameterised list key";
    my $input = "foo; a9a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a9a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a9a=1";
    
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

# Test 443: 0x3a in parameterised list key
{
    my $test_name = '0x3a in parameterised list key - must fail';
    my $input = "foo; a:a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 444: 0x3b in parameterised list key
subtest "0x3b in parameterised list key" => sub {
    my $test_name = "0x3b in parameterised list key";
    my $input = "foo; a;a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a=1";
    
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

# Test 445: 0x3c in parameterised list key
{
    my $test_name = '0x3c in parameterised list key - must fail';
    my $input = "foo; a<a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 446: 0x3d in parameterised list key
{
    my $test_name = '0x3d in parameterised list key - must fail';
    my $input = "foo; a=a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 447: 0x3e in parameterised list key
{
    my $test_name = '0x3e in parameterised list key - must fail';
    my $input = "foo; a>a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 448: 0x3f in parameterised list key
{
    my $test_name = '0x3f in parameterised list key - must fail';
    my $input = "foo; a?a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 449: 0x40 in parameterised list key
{
    my $test_name = '0x40 in parameterised list key - must fail';
    my $input = "foo; a\@a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 450: 0x41 in parameterised list key
{
    my $test_name = '0x41 in parameterised list key - must fail';
    my $input = "foo; aAa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 451: 0x42 in parameterised list key
{
    my $test_name = '0x42 in parameterised list key - must fail';
    my $input = "foo; aBa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 452: 0x43 in parameterised list key
{
    my $test_name = '0x43 in parameterised list key - must fail';
    my $input = "foo; aCa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 453: 0x44 in parameterised list key
{
    my $test_name = '0x44 in parameterised list key - must fail';
    my $input = "foo; aDa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 454: 0x45 in parameterised list key
{
    my $test_name = '0x45 in parameterised list key - must fail';
    my $input = "foo; aEa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 455: 0x46 in parameterised list key
{
    my $test_name = '0x46 in parameterised list key - must fail';
    my $input = "foo; aFa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 456: 0x47 in parameterised list key
{
    my $test_name = '0x47 in parameterised list key - must fail';
    my $input = "foo; aGa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 457: 0x48 in parameterised list key
{
    my $test_name = '0x48 in parameterised list key - must fail';
    my $input = "foo; aHa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 458: 0x49 in parameterised list key
{
    my $test_name = '0x49 in parameterised list key - must fail';
    my $input = "foo; aIa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 459: 0x4a in parameterised list key
{
    my $test_name = '0x4a in parameterised list key - must fail';
    my $input = "foo; aJa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 460: 0x4b in parameterised list key
{
    my $test_name = '0x4b in parameterised list key - must fail';
    my $input = "foo; aKa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 461: 0x4c in parameterised list key
{
    my $test_name = '0x4c in parameterised list key - must fail';
    my $input = "foo; aLa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 462: 0x4d in parameterised list key
{
    my $test_name = '0x4d in parameterised list key - must fail';
    my $input = "foo; aMa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 463: 0x4e in parameterised list key
{
    my $test_name = '0x4e in parameterised list key - must fail';
    my $input = "foo; aNa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 464: 0x4f in parameterised list key
{
    my $test_name = '0x4f in parameterised list key - must fail';
    my $input = "foo; aOa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 465: 0x50 in parameterised list key
{
    my $test_name = '0x50 in parameterised list key - must fail';
    my $input = "foo; aPa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 466: 0x51 in parameterised list key
{
    my $test_name = '0x51 in parameterised list key - must fail';
    my $input = "foo; aQa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 467: 0x52 in parameterised list key
{
    my $test_name = '0x52 in parameterised list key - must fail';
    my $input = "foo; aRa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 468: 0x53 in parameterised list key
{
    my $test_name = '0x53 in parameterised list key - must fail';
    my $input = "foo; aSa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 469: 0x54 in parameterised list key
{
    my $test_name = '0x54 in parameterised list key - must fail';
    my $input = "foo; aTa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 470: 0x55 in parameterised list key
{
    my $test_name = '0x55 in parameterised list key - must fail';
    my $input = "foo; aUa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 471: 0x56 in parameterised list key
{
    my $test_name = '0x56 in parameterised list key - must fail';
    my $input = "foo; aVa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 472: 0x57 in parameterised list key
{
    my $test_name = '0x57 in parameterised list key - must fail';
    my $input = "foo; aWa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 473: 0x58 in parameterised list key
{
    my $test_name = '0x58 in parameterised list key - must fail';
    my $input = "foo; aXa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 474: 0x59 in parameterised list key
{
    my $test_name = '0x59 in parameterised list key - must fail';
    my $input = "foo; aYa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 475: 0x5a in parameterised list key
{
    my $test_name = '0x5a in parameterised list key - must fail';
    my $input = "foo; aZa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 476: 0x5b in parameterised list key
{
    my $test_name = '0x5b in parameterised list key - must fail';
    my $input = "foo; a[a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 477: 0x5c in parameterised list key
{
    my $test_name = '0x5c in parameterised list key - must fail';
    my $input = "foo; a\\a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 478: 0x5d in parameterised list key
{
    my $test_name = '0x5d in parameterised list key - must fail';
    my $input = "foo; a]a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 479: 0x5e in parameterised list key
{
    my $test_name = '0x5e in parameterised list key - must fail';
    my $input = "foo; a^a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 480: 0x5f in parameterised list key
subtest "0x5f in parameterised list key" => sub {
    my $test_name = "0x5f in parameterised list key";
    my $input = "foo; a_a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a_a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a_a=1";
    
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

# Test 481: 0x60 in parameterised list key
{
    my $test_name = '0x60 in parameterised list key - must fail';
    my $input = "foo; a`a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 482: 0x61 in parameterised list key
subtest "0x61 in parameterised list key" => sub {
    my $test_name = "0x61 in parameterised list key";
    my $input = "foo; aaa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aaa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aaa=1";
    
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

# Test 483: 0x62 in parameterised list key
subtest "0x62 in parameterised list key" => sub {
    my $test_name = "0x62 in parameterised list key";
    my $input = "foo; aba=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aba" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aba=1";
    
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

# Test 484: 0x63 in parameterised list key
subtest "0x63 in parameterised list key" => sub {
    my $test_name = "0x63 in parameterised list key";
    my $input = "foo; aca=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aca" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aca=1";
    
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

# Test 485: 0x64 in parameterised list key
subtest "0x64 in parameterised list key" => sub {
    my $test_name = "0x64 in parameterised list key";
    my $input = "foo; ada=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ada" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ada=1";
    
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

# Test 486: 0x65 in parameterised list key
subtest "0x65 in parameterised list key" => sub {
    my $test_name = "0x65 in parameterised list key";
    my $input = "foo; aea=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aea" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aea=1";
    
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

# Test 487: 0x66 in parameterised list key
subtest "0x66 in parameterised list key" => sub {
    my $test_name = "0x66 in parameterised list key";
    my $input = "foo; afa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "afa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;afa=1";
    
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

# Test 488: 0x67 in parameterised list key
subtest "0x67 in parameterised list key" => sub {
    my $test_name = "0x67 in parameterised list key";
    my $input = "foo; aga=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aga" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aga=1";
    
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

# Test 489: 0x68 in parameterised list key
subtest "0x68 in parameterised list key" => sub {
    my $test_name = "0x68 in parameterised list key";
    my $input = "foo; aha=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aha" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aha=1";
    
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

# Test 490: 0x69 in parameterised list key
subtest "0x69 in parameterised list key" => sub {
    my $test_name = "0x69 in parameterised list key";
    my $input = "foo; aia=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aia" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aia=1";
    
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

# Test 491: 0x6a in parameterised list key
subtest "0x6a in parameterised list key" => sub {
    my $test_name = "0x6a in parameterised list key";
    my $input = "foo; aja=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aja" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aja=1";
    
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

# Test 492: 0x6b in parameterised list key
subtest "0x6b in parameterised list key" => sub {
    my $test_name = "0x6b in parameterised list key";
    my $input = "foo; aka=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aka" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aka=1";
    
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

# Test 493: 0x6c in parameterised list key
subtest "0x6c in parameterised list key" => sub {
    my $test_name = "0x6c in parameterised list key";
    my $input = "foo; ala=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ala" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ala=1";
    
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

# Test 494: 0x6d in parameterised list key
subtest "0x6d in parameterised list key" => sub {
    my $test_name = "0x6d in parameterised list key";
    my $input = "foo; ama=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ama" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ama=1";
    
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

# Test 495: 0x6e in parameterised list key
subtest "0x6e in parameterised list key" => sub {
    my $test_name = "0x6e in parameterised list key";
    my $input = "foo; ana=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ana" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ana=1";
    
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

# Test 496: 0x6f in parameterised list key
subtest "0x6f in parameterised list key" => sub {
    my $test_name = "0x6f in parameterised list key";
    my $input = "foo; aoa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aoa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aoa=1";
    
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

# Test 497: 0x70 in parameterised list key
subtest "0x70 in parameterised list key" => sub {
    my $test_name = "0x70 in parameterised list key";
    my $input = "foo; apa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "apa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;apa=1";
    
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

# Test 498: 0x71 in parameterised list key
subtest "0x71 in parameterised list key" => sub {
    my $test_name = "0x71 in parameterised list key";
    my $input = "foo; aqa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aqa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aqa=1";
    
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

# Test 499: 0x72 in parameterised list key
subtest "0x72 in parameterised list key" => sub {
    my $test_name = "0x72 in parameterised list key";
    my $input = "foo; ara=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ara" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ara=1";
    
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

# Test 500: 0x73 in parameterised list key
subtest "0x73 in parameterised list key" => sub {
    my $test_name = "0x73 in parameterised list key";
    my $input = "foo; asa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "asa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;asa=1";
    
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

# Test 501: 0x74 in parameterised list key
subtest "0x74 in parameterised list key" => sub {
    my $test_name = "0x74 in parameterised list key";
    my $input = "foo; ata=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ata" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ata=1";
    
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

# Test 502: 0x75 in parameterised list key
subtest "0x75 in parameterised list key" => sub {
    my $test_name = "0x75 in parameterised list key";
    my $input = "foo; aua=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aua" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aua=1";
    
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

# Test 503: 0x76 in parameterised list key
subtest "0x76 in parameterised list key" => sub {
    my $test_name = "0x76 in parameterised list key";
    my $input = "foo; ava=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ava" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ava=1";
    
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

# Test 504: 0x77 in parameterised list key
subtest "0x77 in parameterised list key" => sub {
    my $test_name = "0x77 in parameterised list key";
    my $input = "foo; awa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "awa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;awa=1";
    
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

# Test 505: 0x78 in parameterised list key
subtest "0x78 in parameterised list key" => sub {
    my $test_name = "0x78 in parameterised list key";
    my $input = "foo; axa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "axa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;axa=1";
    
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

# Test 506: 0x79 in parameterised list key
subtest "0x79 in parameterised list key" => sub {
    my $test_name = "0x79 in parameterised list key";
    my $input = "foo; aya=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aya" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aya=1";
    
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

# Test 507: 0x7a in parameterised list key
subtest "0x7a in parameterised list key" => sub {
    my $test_name = "0x7a in parameterised list key";
    my $input = "foo; aza=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aza" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aza=1";
    
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

# Test 508: 0x7b in parameterised list key
{
    my $test_name = '0x7b in parameterised list key - must fail';
    my $input = "foo; a{a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 509: 0x7c in parameterised list key
{
    my $test_name = '0x7c in parameterised list key - must fail';
    my $input = "foo; a|a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 510: 0x7d in parameterised list key
{
    my $test_name = '0x7d in parameterised list key - must fail';
    my $input = "foo; a}a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 511: 0x7e in parameterised list key
{
    my $test_name = '0x7e in parameterised list key - must fail';
    my $input = "foo; a~a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 512: 0x7f in parameterised list key
{
    my $test_name = '0x7f in parameterised list key - must fail';
    my $input = "foo; a\177a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 513: 0x00 starting a parameterised list key
{
    my $test_name = '0x00 starting a parameterised list key - must fail';
    my $input = "foo; \000a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 514: 0x01 starting a parameterised list key
{
    my $test_name = '0x01 starting a parameterised list key - must fail';
    my $input = "foo; \001a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 515: 0x02 starting a parameterised list key
{
    my $test_name = '0x02 starting a parameterised list key - must fail';
    my $input = "foo; \002a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 516: 0x03 starting a parameterised list key
{
    my $test_name = '0x03 starting a parameterised list key - must fail';
    my $input = "foo; \003a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 517: 0x04 starting a parameterised list key
{
    my $test_name = '0x04 starting a parameterised list key - must fail';
    my $input = "foo; \004a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 518: 0x05 starting a parameterised list key
{
    my $test_name = '0x05 starting a parameterised list key - must fail';
    my $input = "foo; \005a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 519: 0x06 starting a parameterised list key
{
    my $test_name = '0x06 starting a parameterised list key - must fail';
    my $input = "foo; \006a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 520: 0x07 starting a parameterised list key
{
    my $test_name = '0x07 starting a parameterised list key - must fail';
    my $input = "foo; \aa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 521: 0x08 starting a parameterised list key
{
    my $test_name = '0x08 starting a parameterised list key - must fail';
    my $input = "foo; \ba=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 522: 0x09 starting a parameterised list key
{
    my $test_name = '0x09 starting a parameterised list key - must fail';
    my $input = "foo; \ta=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 523: 0x0a starting a parameterised list key
{
    my $test_name = '0x0a starting a parameterised list key - must fail';
    my $input = "foo; \na=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 524: 0x0b starting a parameterised list key
{
    my $test_name = '0x0b starting a parameterised list key - must fail';
    my $input = "foo; \013a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 525: 0x0c starting a parameterised list key
{
    my $test_name = '0x0c starting a parameterised list key - must fail';
    my $input = "foo; \fa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 526: 0x0d starting a parameterised list key
{
    my $test_name = '0x0d starting a parameterised list key - must fail';
    my $input = "foo; \ra=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 527: 0x0e starting a parameterised list key
{
    my $test_name = '0x0e starting a parameterised list key - must fail';
    my $input = "foo; \016a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 528: 0x0f starting a parameterised list key
{
    my $test_name = '0x0f starting a parameterised list key - must fail';
    my $input = "foo; \017a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 529: 0x10 starting a parameterised list key
{
    my $test_name = '0x10 starting a parameterised list key - must fail';
    my $input = "foo; \020a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 530: 0x11 starting a parameterised list key
{
    my $test_name = '0x11 starting a parameterised list key - must fail';
    my $input = "foo; \021a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 531: 0x12 starting a parameterised list key
{
    my $test_name = '0x12 starting a parameterised list key - must fail';
    my $input = "foo; \022a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 532: 0x13 starting a parameterised list key
{
    my $test_name = '0x13 starting a parameterised list key - must fail';
    my $input = "foo; \023a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 533: 0x14 starting a parameterised list key
{
    my $test_name = '0x14 starting a parameterised list key - must fail';
    my $input = "foo; \024a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 534: 0x15 starting a parameterised list key
{
    my $test_name = '0x15 starting a parameterised list key - must fail';
    my $input = "foo; \025a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 535: 0x16 starting a parameterised list key
{
    my $test_name = '0x16 starting a parameterised list key - must fail';
    my $input = "foo; \026a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 536: 0x17 starting a parameterised list key
{
    my $test_name = '0x17 starting a parameterised list key - must fail';
    my $input = "foo; \027a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 537: 0x18 starting a parameterised list key
{
    my $test_name = '0x18 starting a parameterised list key - must fail';
    my $input = "foo; \030a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 538: 0x19 starting a parameterised list key
{
    my $test_name = '0x19 starting a parameterised list key - must fail';
    my $input = "foo; \031a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 539: 0x1a starting a parameterised list key
{
    my $test_name = '0x1a starting a parameterised list key - must fail';
    my $input = "foo; \032a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 540: 0x1b starting a parameterised list key
{
    my $test_name = '0x1b starting a parameterised list key - must fail';
    my $input = "foo; \033a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 541: 0x1c starting a parameterised list key
{
    my $test_name = '0x1c starting a parameterised list key - must fail';
    my $input = "foo; \034a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 542: 0x1d starting a parameterised list key
{
    my $test_name = '0x1d starting a parameterised list key - must fail';
    my $input = "foo; \035a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 543: 0x1e starting a parameterised list key
{
    my $test_name = '0x1e starting a parameterised list key - must fail';
    my $input = "foo; \036a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 544: 0x1f starting a parameterised list key
{
    my $test_name = '0x1f starting a parameterised list key - must fail';
    my $input = "foo; \037a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 545: 0x20 starting a parameterised list key
subtest "0x20 starting a parameterised list key" => sub {
    my $test_name = "0x20 starting a parameterised list key";
    my $input = "foo;  a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;a=1";
    
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

# Test 546: 0x21 starting a parameterised list key
{
    my $test_name = '0x21 starting a parameterised list key - must fail';
    my $input = "foo; !a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 547: 0x22 starting a parameterised list key
{
    my $test_name = '0x22 starting a parameterised list key - must fail';
    my $input = "foo; \"a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 548: 0x23 starting a parameterised list key
{
    my $test_name = '0x23 starting a parameterised list key - must fail';
    my $input = "foo; #a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 549: 0x24 starting a parameterised list key
{
    my $test_name = '0x24 starting a parameterised list key - must fail';
    my $input = "foo; \$a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 550: 0x25 starting a parameterised list key
{
    my $test_name = '0x25 starting a parameterised list key - must fail';
    my $input = "foo; %a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 551: 0x26 starting a parameterised list key
{
    my $test_name = '0x26 starting a parameterised list key - must fail';
    my $input = "foo; &a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 552: 0x27 starting a parameterised list key
{
    my $test_name = '0x27 starting a parameterised list key - must fail';
    my $input = "foo; 'a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 553: 0x28 starting a parameterised list key
{
    my $test_name = '0x28 starting a parameterised list key - must fail';
    my $input = "foo; (a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 554: 0x29 starting a parameterised list key
{
    my $test_name = '0x29 starting a parameterised list key - must fail';
    my $input = "foo; )a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 555: 0x2a starting a parameterised list key
subtest "0x2a starting a parameterised list key" => sub {
    my $test_name = "0x2a starting a parameterised list key";
    my $input = "foo; *a=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "*a" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;*a=1";
    
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

# Test 556: 0x2b starting a parameterised list key
{
    my $test_name = '0x2b starting a parameterised list key - must fail';
    my $input = "foo; +a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 557: 0x2c starting a parameterised list key
{
    my $test_name = '0x2c starting a parameterised list key - must fail';
    my $input = "foo; ,a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 558: 0x2d starting a parameterised list key
{
    my $test_name = '0x2d starting a parameterised list key - must fail';
    my $input = "foo; -a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 559: 0x2e starting a parameterised list key
{
    my $test_name = '0x2e starting a parameterised list key - must fail';
    my $input = "foo; .a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 560: 0x2f starting a parameterised list key
{
    my $test_name = '0x2f starting a parameterised list key - must fail';
    my $input = "foo; /a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 561: 0x30 starting a parameterised list key
{
    my $test_name = '0x30 starting a parameterised list key - must fail';
    my $input = "foo; 0a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 562: 0x31 starting a parameterised list key
{
    my $test_name = '0x31 starting a parameterised list key - must fail';
    my $input = "foo; 1a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 563: 0x32 starting a parameterised list key
{
    my $test_name = '0x32 starting a parameterised list key - must fail';
    my $input = "foo; 2a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 564: 0x33 starting a parameterised list key
{
    my $test_name = '0x33 starting a parameterised list key - must fail';
    my $input = "foo; 3a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 565: 0x34 starting a parameterised list key
{
    my $test_name = '0x34 starting a parameterised list key - must fail';
    my $input = "foo; 4a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 566: 0x35 starting a parameterised list key
{
    my $test_name = '0x35 starting a parameterised list key - must fail';
    my $input = "foo; 5a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 567: 0x36 starting a parameterised list key
{
    my $test_name = '0x36 starting a parameterised list key - must fail';
    my $input = "foo; 6a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 568: 0x37 starting a parameterised list key
{
    my $test_name = '0x37 starting a parameterised list key - must fail';
    my $input = "foo; 7a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 569: 0x38 starting a parameterised list key
{
    my $test_name = '0x38 starting a parameterised list key - must fail';
    my $input = "foo; 8a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 570: 0x39 starting a parameterised list key
{
    my $test_name = '0x39 starting a parameterised list key - must fail';
    my $input = "foo; 9a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 571: 0x3a starting a parameterised list key
{
    my $test_name = '0x3a starting a parameterised list key - must fail';
    my $input = "foo; :a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 572: 0x3b starting a parameterised list key
{
    my $test_name = '0x3b starting a parameterised list key - must fail';
    my $input = "foo; ;a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 573: 0x3c starting a parameterised list key
{
    my $test_name = '0x3c starting a parameterised list key - must fail';
    my $input = "foo; <a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 574: 0x3d starting a parameterised list key
{
    my $test_name = '0x3d starting a parameterised list key - must fail';
    my $input = "foo; =a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 575: 0x3e starting a parameterised list key
{
    my $test_name = '0x3e starting a parameterised list key - must fail';
    my $input = "foo; >a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 576: 0x3f starting a parameterised list key
{
    my $test_name = '0x3f starting a parameterised list key - must fail';
    my $input = "foo; ?a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 577: 0x40 starting a parameterised list key
{
    my $test_name = '0x40 starting a parameterised list key - must fail';
    my $input = "foo; \@a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 578: 0x41 starting a parameterised list key
{
    my $test_name = '0x41 starting a parameterised list key - must fail';
    my $input = "foo; Aa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 579: 0x42 starting a parameterised list key
{
    my $test_name = '0x42 starting a parameterised list key - must fail';
    my $input = "foo; Ba=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 580: 0x43 starting a parameterised list key
{
    my $test_name = '0x43 starting a parameterised list key - must fail';
    my $input = "foo; Ca=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 581: 0x44 starting a parameterised list key
{
    my $test_name = '0x44 starting a parameterised list key - must fail';
    my $input = "foo; Da=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 582: 0x45 starting a parameterised list key
{
    my $test_name = '0x45 starting a parameterised list key - must fail';
    my $input = "foo; Ea=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 583: 0x46 starting a parameterised list key
{
    my $test_name = '0x46 starting a parameterised list key - must fail';
    my $input = "foo; Fa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 584: 0x47 starting a parameterised list key
{
    my $test_name = '0x47 starting a parameterised list key - must fail';
    my $input = "foo; Ga=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 585: 0x48 starting a parameterised list key
{
    my $test_name = '0x48 starting a parameterised list key - must fail';
    my $input = "foo; Ha=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 586: 0x49 starting a parameterised list key
{
    my $test_name = '0x49 starting a parameterised list key - must fail';
    my $input = "foo; Ia=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 587: 0x4a starting a parameterised list key
{
    my $test_name = '0x4a starting a parameterised list key - must fail';
    my $input = "foo; Ja=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 588: 0x4b starting a parameterised list key
{
    my $test_name = '0x4b starting a parameterised list key - must fail';
    my $input = "foo; Ka=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 589: 0x4c starting a parameterised list key
{
    my $test_name = '0x4c starting a parameterised list key - must fail';
    my $input = "foo; La=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 590: 0x4d starting a parameterised list key
{
    my $test_name = '0x4d starting a parameterised list key - must fail';
    my $input = "foo; Ma=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 591: 0x4e starting a parameterised list key
{
    my $test_name = '0x4e starting a parameterised list key - must fail';
    my $input = "foo; Na=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 592: 0x4f starting a parameterised list key
{
    my $test_name = '0x4f starting a parameterised list key - must fail';
    my $input = "foo; Oa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 593: 0x50 starting a parameterised list key
{
    my $test_name = '0x50 starting a parameterised list key - must fail';
    my $input = "foo; Pa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 594: 0x51 starting a parameterised list key
{
    my $test_name = '0x51 starting a parameterised list key - must fail';
    my $input = "foo; Qa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 595: 0x52 starting a parameterised list key
{
    my $test_name = '0x52 starting a parameterised list key - must fail';
    my $input = "foo; Ra=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 596: 0x53 starting a parameterised list key
{
    my $test_name = '0x53 starting a parameterised list key - must fail';
    my $input = "foo; Sa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 597: 0x54 starting a parameterised list key
{
    my $test_name = '0x54 starting a parameterised list key - must fail';
    my $input = "foo; Ta=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 598: 0x55 starting a parameterised list key
{
    my $test_name = '0x55 starting a parameterised list key - must fail';
    my $input = "foo; Ua=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 599: 0x56 starting a parameterised list key
{
    my $test_name = '0x56 starting a parameterised list key - must fail';
    my $input = "foo; Va=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 600: 0x57 starting a parameterised list key
{
    my $test_name = '0x57 starting a parameterised list key - must fail';
    my $input = "foo; Wa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 601: 0x58 starting a parameterised list key
{
    my $test_name = '0x58 starting a parameterised list key - must fail';
    my $input = "foo; Xa=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 602: 0x59 starting a parameterised list key
{
    my $test_name = '0x59 starting a parameterised list key - must fail';
    my $input = "foo; Ya=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 603: 0x5a starting a parameterised list key
{
    my $test_name = '0x5a starting a parameterised list key - must fail';
    my $input = "foo; Za=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 604: 0x5b starting a parameterised list key
{
    my $test_name = '0x5b starting a parameterised list key - must fail';
    my $input = "foo; [a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 605: 0x5c starting a parameterised list key
{
    my $test_name = '0x5c starting a parameterised list key - must fail';
    my $input = "foo; \\a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 606: 0x5d starting a parameterised list key
{
    my $test_name = '0x5d starting a parameterised list key - must fail';
    my $input = "foo; ]a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 607: 0x5e starting a parameterised list key
{
    my $test_name = '0x5e starting a parameterised list key - must fail';
    my $input = "foo; ^a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 608: 0x5f starting a parameterised list key
{
    my $test_name = '0x5f starting a parameterised list key - must fail';
    my $input = "foo; _a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 609: 0x60 starting a parameterised list key
{
    my $test_name = '0x60 starting a parameterised list key - must fail';
    my $input = "foo; `a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 610: 0x61 starting a parameterised list key
subtest "0x61 starting a parameterised list key" => sub {
    my $test_name = "0x61 starting a parameterised list key";
    my $input = "foo; aa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;aa=1";
    
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

# Test 611: 0x62 starting a parameterised list key
subtest "0x62 starting a parameterised list key" => sub {
    my $test_name = "0x62 starting a parameterised list key";
    my $input = "foo; ba=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ba" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ba=1";
    
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

# Test 612: 0x63 starting a parameterised list key
subtest "0x63 starting a parameterised list key" => sub {
    my $test_name = "0x63 starting a parameterised list key";
    my $input = "foo; ca=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ca" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ca=1";
    
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

# Test 613: 0x64 starting a parameterised list key
subtest "0x64 starting a parameterised list key" => sub {
    my $test_name = "0x64 starting a parameterised list key";
    my $input = "foo; da=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "da" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;da=1";
    
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

# Test 614: 0x65 starting a parameterised list key
subtest "0x65 starting a parameterised list key" => sub {
    my $test_name = "0x65 starting a parameterised list key";
    my $input = "foo; ea=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ea" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ea=1";
    
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

# Test 615: 0x66 starting a parameterised list key
subtest "0x66 starting a parameterised list key" => sub {
    my $test_name = "0x66 starting a parameterised list key";
    my $input = "foo; fa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "fa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;fa=1";
    
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

# Test 616: 0x67 starting a parameterised list key
subtest "0x67 starting a parameterised list key" => sub {
    my $test_name = "0x67 starting a parameterised list key";
    my $input = "foo; ga=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ga" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ga=1";
    
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

# Test 617: 0x68 starting a parameterised list key
subtest "0x68 starting a parameterised list key" => sub {
    my $test_name = "0x68 starting a parameterised list key";
    my $input = "foo; ha=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ha" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ha=1";
    
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

# Test 618: 0x69 starting a parameterised list key
subtest "0x69 starting a parameterised list key" => sub {
    my $test_name = "0x69 starting a parameterised list key";
    my $input = "foo; ia=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ia" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ia=1";
    
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

# Test 619: 0x6a starting a parameterised list key
subtest "0x6a starting a parameterised list key" => sub {
    my $test_name = "0x6a starting a parameterised list key";
    my $input = "foo; ja=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ja" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ja=1";
    
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

# Test 620: 0x6b starting a parameterised list key
subtest "0x6b starting a parameterised list key" => sub {
    my $test_name = "0x6b starting a parameterised list key";
    my $input = "foo; ka=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ka" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ka=1";
    
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

# Test 621: 0x6c starting a parameterised list key
subtest "0x6c starting a parameterised list key" => sub {
    my $test_name = "0x6c starting a parameterised list key";
    my $input = "foo; la=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "la" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;la=1";
    
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

# Test 622: 0x6d starting a parameterised list key
subtest "0x6d starting a parameterised list key" => sub {
    my $test_name = "0x6d starting a parameterised list key";
    my $input = "foo; ma=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ma" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ma=1";
    
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

# Test 623: 0x6e starting a parameterised list key
subtest "0x6e starting a parameterised list key" => sub {
    my $test_name = "0x6e starting a parameterised list key";
    my $input = "foo; na=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "na" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;na=1";
    
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

# Test 624: 0x6f starting a parameterised list key
subtest "0x6f starting a parameterised list key" => sub {
    my $test_name = "0x6f starting a parameterised list key";
    my $input = "foo; oa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "oa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;oa=1";
    
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

# Test 625: 0x70 starting a parameterised list key
subtest "0x70 starting a parameterised list key" => sub {
    my $test_name = "0x70 starting a parameterised list key";
    my $input = "foo; pa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "pa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;pa=1";
    
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

# Test 626: 0x71 starting a parameterised list key
subtest "0x71 starting a parameterised list key" => sub {
    my $test_name = "0x71 starting a parameterised list key";
    my $input = "foo; qa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "qa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;qa=1";
    
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

# Test 627: 0x72 starting a parameterised list key
subtest "0x72 starting a parameterised list key" => sub {
    my $test_name = "0x72 starting a parameterised list key";
    my $input = "foo; ra=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ra" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ra=1";
    
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

# Test 628: 0x73 starting a parameterised list key
subtest "0x73 starting a parameterised list key" => sub {
    my $test_name = "0x73 starting a parameterised list key";
    my $input = "foo; sa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "sa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;sa=1";
    
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

# Test 629: 0x74 starting a parameterised list key
subtest "0x74 starting a parameterised list key" => sub {
    my $test_name = "0x74 starting a parameterised list key";
    my $input = "foo; ta=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ta" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ta=1";
    
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

# Test 630: 0x75 starting a parameterised list key
subtest "0x75 starting a parameterised list key" => sub {
    my $test_name = "0x75 starting a parameterised list key";
    my $input = "foo; ua=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ua" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ua=1";
    
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

# Test 631: 0x76 starting a parameterised list key
subtest "0x76 starting a parameterised list key" => sub {
    my $test_name = "0x76 starting a parameterised list key";
    my $input = "foo; va=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "va" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;va=1";
    
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

# Test 632: 0x77 starting a parameterised list key
subtest "0x77 starting a parameterised list key" => sub {
    my $test_name = "0x77 starting a parameterised list key";
    my $input = "foo; wa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "wa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;wa=1";
    
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

# Test 633: 0x78 starting a parameterised list key
subtest "0x78 starting a parameterised list key" => sub {
    my $test_name = "0x78 starting a parameterised list key";
    my $input = "foo; xa=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "xa" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;xa=1";
    
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

# Test 634: 0x79 starting a parameterised list key
subtest "0x79 starting a parameterised list key" => sub {
    my $test_name = "0x79 starting a parameterised list key";
    my $input = "foo; ya=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "ya" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;ya=1";
    
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

# Test 635: 0x7a starting a parameterised list key
subtest "0x7a starting a parameterised list key" => sub {
    my $test_name = "0x7a starting a parameterised list key";
    my $input = "foo; za=1";
    my $expected = [ { _type => 'token', value => "foo", params => _h( "za" => { _type => 'integer', value => 1 } ) } ];
    my $canonical = "foo;za=1";
    
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

# Test 636: 0x7b starting a parameterised list key
{
    my $test_name = '0x7b starting a parameterised list key - must fail';
    my $input = "foo; {a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 637: 0x7c starting a parameterised list key
{
    my $test_name = '0x7c starting a parameterised list key - must fail';
    my $input = "foo; |a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 638: 0x7d starting a parameterised list key
{
    my $test_name = '0x7d starting a parameterised list key - must fail';
    my $input = "foo; }a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 639: 0x7e starting a parameterised list key
{
    my $test_name = '0x7e starting a parameterised list key - must fail';
    my $input = "foo; ~a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 640: 0x7f starting a parameterised list key
{
    my $test_name = '0x7f starting a parameterised list key - must fail';
    my $input = "foo; \177a=1";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

