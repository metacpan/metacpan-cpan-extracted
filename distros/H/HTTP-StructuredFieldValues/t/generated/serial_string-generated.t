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

# Generated from serial_string-generated.json
# Total tests: 33

plan tests => 33;

# Test 1: 0x00 in string - serialise only
{
    my $test_name = '0x00 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\000" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 2: 0x01 in string - serialise only
{
    my $test_name = '0x01 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\001" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 3: 0x02 in string - serialise only
{
    my $test_name = '0x02 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\002" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 4: 0x03 in string - serialise only
{
    my $test_name = '0x03 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\003" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 5: 0x04 in string - serialise only
{
    my $test_name = '0x04 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\004" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 6: 0x05 in string - serialise only
{
    my $test_name = '0x05 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\005" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 7: 0x06 in string - serialise only
{
    my $test_name = '0x06 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\006" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 8: 0x07 in string - serialise only
{
    my $test_name = '0x07 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\a" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 9: 0x08 in string - serialise only
{
    my $test_name = '0x08 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\b" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 10: 0x09 in string - serialise only
{
    my $test_name = '0x09 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\t" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 11: 0x0a in string - serialise only
{
    my $test_name = '0x0a in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\n" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 12: 0x0b in string - serialise only
{
    my $test_name = '0x0b in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\013" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 13: 0x0c in string - serialise only
{
    my $test_name = '0x0c in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\f" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 14: 0x0d in string - serialise only
{
    my $test_name = '0x0d in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\r" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 15: 0x0e in string - serialise only
{
    my $test_name = '0x0e in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\016" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 16: 0x0f in string - serialise only
{
    my $test_name = '0x0f in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\017" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 17: 0x10 in string - serialise only
{
    my $test_name = '0x10 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\020" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 18: 0x11 in string - serialise only
{
    my $test_name = '0x11 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\021" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 19: 0x12 in string - serialise only
{
    my $test_name = '0x12 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\022" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 20: 0x13 in string - serialise only
{
    my $test_name = '0x13 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\023" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 21: 0x14 in string - serialise only
{
    my $test_name = '0x14 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\024" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 22: 0x15 in string - serialise only
{
    my $test_name = '0x15 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\025" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 23: 0x16 in string - serialise only
{
    my $test_name = '0x16 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\026" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 24: 0x17 in string - serialise only
{
    my $test_name = '0x17 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\027" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 25: 0x18 in string - serialise only
{
    my $test_name = '0x18 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\030" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 26: 0x19 in string - serialise only
{
    my $test_name = '0x19 in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\031" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 27: 0x1a in string - serialise only
{
    my $test_name = '0x1a in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\032" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 28: 0x1b in string - serialise only
{
    my $test_name = '0x1b in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\033" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 29: 0x1c in string - serialise only
{
    my $test_name = '0x1c in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\034" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 30: 0x1d in string - serialise only
{
    my $test_name = '0x1d in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\035" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 31: 0x1e in string - serialise only
{
    my $test_name = '0x1e in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\036" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 32: 0x1f in string - serialise only
{
    my $test_name = '0x1f in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\037" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 33: 0x7f in string - serialise only
{
    my $test_name = '0x7f in string - serialise only - must fail';
    my $expected = { _type => 'string', value => "\177" };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

