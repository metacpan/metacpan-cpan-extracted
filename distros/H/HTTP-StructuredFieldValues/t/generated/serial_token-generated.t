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

# Generated from serial_token-generated.json
# Total tests: 124

plan tests => 124;

# Test 1: 0x00 in token - serialise only
{
    my $test_name = '0x00 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\000a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 2: 0x01 in token - serialise only
{
    my $test_name = '0x01 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\001a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 3: 0x02 in token - serialise only
{
    my $test_name = '0x02 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\002a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 4: 0x03 in token - serialise only
{
    my $test_name = '0x03 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\003a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 5: 0x04 in token - serialise only
{
    my $test_name = '0x04 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\004a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 6: 0x05 in token - serialise only
{
    my $test_name = '0x05 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\005a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 7: 0x06 in token - serialise only
{
    my $test_name = '0x06 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\006a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 8: 0x07 in token - serialise only
{
    my $test_name = '0x07 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\aa" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 9: 0x08 in token - serialise only
{
    my $test_name = '0x08 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\ba" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 10: 0x09 in token - serialise only
{
    my $test_name = '0x09 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\ta" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 11: 0x0a in token - serialise only
{
    my $test_name = '0x0a in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\na" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 12: 0x0b in token - serialise only
{
    my $test_name = '0x0b in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\013a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 13: 0x0c in token - serialise only
{
    my $test_name = '0x0c in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\fa" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 14: 0x0d in token - serialise only
{
    my $test_name = '0x0d in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\ra" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 15: 0x0e in token - serialise only
{
    my $test_name = '0x0e in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\016a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 16: 0x0f in token - serialise only
{
    my $test_name = '0x0f in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\017a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 17: 0x10 in token - serialise only
{
    my $test_name = '0x10 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\020a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 18: 0x11 in token - serialise only
{
    my $test_name = '0x11 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\021a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 19: 0x12 in token - serialise only
{
    my $test_name = '0x12 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\022a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 20: 0x13 in token - serialise only
{
    my $test_name = '0x13 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\023a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 21: 0x14 in token - serialise only
{
    my $test_name = '0x14 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\024a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 22: 0x15 in token - serialise only
{
    my $test_name = '0x15 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\025a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 23: 0x16 in token - serialise only
{
    my $test_name = '0x16 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\026a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 24: 0x17 in token - serialise only
{
    my $test_name = '0x17 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\027a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 25: 0x18 in token - serialise only
{
    my $test_name = '0x18 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\030a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 26: 0x19 in token - serialise only
{
    my $test_name = '0x19 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\031a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 27: 0x1a in token - serialise only
{
    my $test_name = '0x1a in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\032a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 28: 0x1b in token - serialise only
{
    my $test_name = '0x1b in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\033a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 29: 0x1c in token - serialise only
{
    my $test_name = '0x1c in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\034a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 30: 0x1d in token - serialise only
{
    my $test_name = '0x1d in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\035a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 31: 0x1e in token - serialise only
{
    my $test_name = '0x1e in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\036a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 32: 0x1f in token - serialise only
{
    my $test_name = '0x1f in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\037a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 33: 0x20 in token - serialise only
{
    my $test_name = '0x20 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 34: 0x22 in token - serialise only
{
    my $test_name = '0x22 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\"a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 35: 0x28 in token - serialise only
{
    my $test_name = '0x28 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a(a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 36: 0x29 in token - serialise only
{
    my $test_name = '0x29 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a)a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 37: 0x2c in token - serialise only
{
    my $test_name = '0x2c in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a,a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 38: 0x3b in token - serialise only
{
    my $test_name = '0x3b in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a;a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 39: 0x3c in token - serialise only
{
    my $test_name = '0x3c in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a<a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 40: 0x3d in token - serialise only
{
    my $test_name = '0x3d in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a=a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 41: 0x3e in token - serialise only
{
    my $test_name = '0x3e in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a>a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 42: 0x3f in token - serialise only
{
    my $test_name = '0x3f in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a?a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 43: 0x40 in token - serialise only
{
    my $test_name = '0x40 in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\@a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 44: 0x5b in token - serialise only
{
    my $test_name = '0x5b in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a[a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 45: 0x5c in token - serialise only
{
    my $test_name = '0x5c in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\\a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 46: 0x5d in token - serialise only
{
    my $test_name = '0x5d in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a]a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 47: 0x7b in token - serialise only
{
    my $test_name = '0x7b in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a{a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 48: 0x7d in token - serialise only
{
    my $test_name = '0x7d in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a}a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 49: 0x7f in token - serialise only
{
    my $test_name = '0x7f in token - serialise only - must fail';
    my $expected = { _type => 'token', value => "a\177a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 50: 0x00 starting a token - serialise only
{
    my $test_name = '0x00 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\000a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 51: 0x01 starting a token - serialise only
{
    my $test_name = '0x01 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\001a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 52: 0x02 starting a token - serialise only
{
    my $test_name = '0x02 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\002a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 53: 0x03 starting a token - serialise only
{
    my $test_name = '0x03 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\003a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 54: 0x04 starting a token - serialise only
{
    my $test_name = '0x04 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\004a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 55: 0x05 starting a token - serialise only
{
    my $test_name = '0x05 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\005a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 56: 0x06 starting a token - serialise only
{
    my $test_name = '0x06 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\006a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 57: 0x07 starting a token - serialise only
{
    my $test_name = '0x07 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\aa" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 58: 0x08 starting a token - serialise only
{
    my $test_name = '0x08 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\ba" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 59: 0x09 starting a token - serialise only
{
    my $test_name = '0x09 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\ta" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 60: 0x0a starting a token - serialise only
{
    my $test_name = '0x0a starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\na" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 61: 0x0b starting a token - serialise only
{
    my $test_name = '0x0b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\013a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 62: 0x0c starting a token - serialise only
{
    my $test_name = '0x0c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\fa" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 63: 0x0d starting a token - serialise only
{
    my $test_name = '0x0d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\ra" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 64: 0x0e starting a token - serialise only
{
    my $test_name = '0x0e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\016a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 65: 0x0f starting a token - serialise only
{
    my $test_name = '0x0f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\017a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 66: 0x10 starting a token - serialise only
{
    my $test_name = '0x10 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\020a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 67: 0x11 starting a token - serialise only
{
    my $test_name = '0x11 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\021a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 68: 0x12 starting a token - serialise only
{
    my $test_name = '0x12 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\022a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 69: 0x13 starting a token - serialise only
{
    my $test_name = '0x13 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\023a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 70: 0x14 starting a token - serialise only
{
    my $test_name = '0x14 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\024a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 71: 0x15 starting a token - serialise only
{
    my $test_name = '0x15 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\025a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 72: 0x16 starting a token - serialise only
{
    my $test_name = '0x16 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\026a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 73: 0x17 starting a token - serialise only
{
    my $test_name = '0x17 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\027a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 74: 0x18 starting a token - serialise only
{
    my $test_name = '0x18 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\030a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 75: 0x19 starting a token - serialise only
{
    my $test_name = '0x19 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\031a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 76: 0x1a starting a token - serialise only
{
    my $test_name = '0x1a starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\032a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 77: 0x1b starting a token - serialise only
{
    my $test_name = '0x1b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\033a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 78: 0x1c starting a token - serialise only
{
    my $test_name = '0x1c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\034a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 79: 0x1d starting a token - serialise only
{
    my $test_name = '0x1d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\035a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 80: 0x1e starting a token - serialise only
{
    my $test_name = '0x1e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\036a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 81: 0x1f starting a token - serialise only
{
    my $test_name = '0x1f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\037a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 82: 0x20 starting a token - serialise only
{
    my $test_name = '0x20 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => " a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 83: 0x21 starting a token - serialise only
{
    my $test_name = '0x21 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "!a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 84: 0x22 starting a token - serialise only
{
    my $test_name = '0x22 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\"a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 85: 0x23 starting a token - serialise only
{
    my $test_name = '0x23 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "#a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 86: 0x24 starting a token - serialise only
{
    my $test_name = '0x24 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\$a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 87: 0x25 starting a token - serialise only
{
    my $test_name = '0x25 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "%a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 88: 0x26 starting a token - serialise only
{
    my $test_name = '0x26 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "&a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 89: 0x27 starting a token - serialise only
{
    my $test_name = '0x27 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "'a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 90: 0x28 starting a token - serialise only
{
    my $test_name = '0x28 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "(a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 91: 0x29 starting a token - serialise only
{
    my $test_name = '0x29 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ")a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 92: 0x2b starting a token - serialise only
{
    my $test_name = '0x2b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "+a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 93: 0x2c starting a token - serialise only
{
    my $test_name = '0x2c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ",a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 94: 0x2d starting a token - serialise only
{
    my $test_name = '0x2d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "-a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 95: 0x2e starting a token - serialise only
{
    my $test_name = '0x2e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ".a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 96: 0x2f starting a token - serialise only
{
    my $test_name = '0x2f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "/a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 97: 0x30 starting a token - serialise only
{
    my $test_name = '0x30 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "0a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 98: 0x31 starting a token - serialise only
{
    my $test_name = '0x31 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "1a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 99: 0x32 starting a token - serialise only
{
    my $test_name = '0x32 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "2a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 100: 0x33 starting a token - serialise only
{
    my $test_name = '0x33 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "3a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 101: 0x34 starting a token - serialise only
{
    my $test_name = '0x34 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "4a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 102: 0x35 starting a token - serialise only
{
    my $test_name = '0x35 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "5a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 103: 0x36 starting a token - serialise only
{
    my $test_name = '0x36 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "6a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 104: 0x37 starting a token - serialise only
{
    my $test_name = '0x37 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "7a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 105: 0x38 starting a token - serialise only
{
    my $test_name = '0x38 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "8a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 106: 0x39 starting a token - serialise only
{
    my $test_name = '0x39 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "9a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 107: 0x3a starting a token - serialise only
{
    my $test_name = '0x3a starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ":a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 108: 0x3b starting a token - serialise only
{
    my $test_name = '0x3b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ";a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 109: 0x3c starting a token - serialise only
{
    my $test_name = '0x3c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "<a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 110: 0x3d starting a token - serialise only
{
    my $test_name = '0x3d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "=a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 111: 0x3e starting a token - serialise only
{
    my $test_name = '0x3e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => ">a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 112: 0x3f starting a token - serialise only
{
    my $test_name = '0x3f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "?a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 113: 0x40 starting a token - serialise only
{
    my $test_name = '0x40 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\@a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 114: 0x5b starting a token - serialise only
{
    my $test_name = '0x5b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "[a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 115: 0x5c starting a token - serialise only
{
    my $test_name = '0x5c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\\a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 116: 0x5d starting a token - serialise only
{
    my $test_name = '0x5d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "]a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 117: 0x5e starting a token - serialise only
{
    my $test_name = '0x5e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "^a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 118: 0x5f starting a token - serialise only
{
    my $test_name = '0x5f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "_a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 119: 0x60 starting a token - serialise only
{
    my $test_name = '0x60 starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "`a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 120: 0x7b starting a token - serialise only
{
    my $test_name = '0x7b starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "{a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 121: 0x7c starting a token - serialise only
{
    my $test_name = '0x7c starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "|a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 122: 0x7d starting a token - serialise only
{
    my $test_name = '0x7d starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "}a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 123: 0x7e starting a token - serialise only
{
    my $test_name = '0x7e starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "~a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 124: 0x7f starting a token - serialise only
{
    my $test_name = '0x7f starting a token - serialise only - must fail';
    my $expected = { _type => 'token', value => "\177a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

