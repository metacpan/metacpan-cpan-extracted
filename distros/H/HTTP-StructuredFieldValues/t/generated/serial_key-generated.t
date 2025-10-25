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

# Generated from serial_key-generated.json
# Total tests: 378

plan tests => 378;

# Test 1: 0x00 in dictionary key - serialise only
{
    my $test_name = '0x00 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\000a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 2: 0x01 in dictionary key - serialise only
{
    my $test_name = '0x01 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\001a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 3: 0x02 in dictionary key - serialise only
{
    my $test_name = '0x02 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\002a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 4: 0x03 in dictionary key - serialise only
{
    my $test_name = '0x03 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\003a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 5: 0x04 in dictionary key - serialise only
{
    my $test_name = '0x04 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\004a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 6: 0x05 in dictionary key - serialise only
{
    my $test_name = '0x05 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\005a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 7: 0x06 in dictionary key - serialise only
{
    my $test_name = '0x06 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\006a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 8: 0x07 in dictionary key - serialise only
{
    my $test_name = '0x07 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\aa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 9: 0x08 in dictionary key - serialise only
{
    my $test_name = '0x08 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\ba" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 10: 0x09 in dictionary key - serialise only
{
    my $test_name = '0x09 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\ta" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 11: 0x0a in dictionary key - serialise only
{
    my $test_name = '0x0a in dictionary key - serialise only - must fail';
    my $expected = _h( "a\na" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 12: 0x0b in dictionary key - serialise only
{
    my $test_name = '0x0b in dictionary key - serialise only - must fail';
    my $expected = _h( "a\013a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 13: 0x0c in dictionary key - serialise only
{
    my $test_name = '0x0c in dictionary key - serialise only - must fail';
    my $expected = _h( "a\fa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 14: 0x0d in dictionary key - serialise only
{
    my $test_name = '0x0d in dictionary key - serialise only - must fail';
    my $expected = _h( "a\ra" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 15: 0x0e in dictionary key - serialise only
{
    my $test_name = '0x0e in dictionary key - serialise only - must fail';
    my $expected = _h( "a\016a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 16: 0x0f in dictionary key - serialise only
{
    my $test_name = '0x0f in dictionary key - serialise only - must fail';
    my $expected = _h( "a\017a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 17: 0x10 in dictionary key - serialise only
{
    my $test_name = '0x10 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\020a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 18: 0x11 in dictionary key - serialise only
{
    my $test_name = '0x11 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\021a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 19: 0x12 in dictionary key - serialise only
{
    my $test_name = '0x12 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\022a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 20: 0x13 in dictionary key - serialise only
{
    my $test_name = '0x13 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\023a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 21: 0x14 in dictionary key - serialise only
{
    my $test_name = '0x14 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\024a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 22: 0x15 in dictionary key - serialise only
{
    my $test_name = '0x15 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\025a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 23: 0x16 in dictionary key - serialise only
{
    my $test_name = '0x16 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\026a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 24: 0x17 in dictionary key - serialise only
{
    my $test_name = '0x17 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\027a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 25: 0x18 in dictionary key - serialise only
{
    my $test_name = '0x18 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\030a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 26: 0x19 in dictionary key - serialise only
{
    my $test_name = '0x19 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\031a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 27: 0x1a in dictionary key - serialise only
{
    my $test_name = '0x1a in dictionary key - serialise only - must fail';
    my $expected = _h( "a\032a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 28: 0x1b in dictionary key - serialise only
{
    my $test_name = '0x1b in dictionary key - serialise only - must fail';
    my $expected = _h( "a\033a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 29: 0x1c in dictionary key - serialise only
{
    my $test_name = '0x1c in dictionary key - serialise only - must fail';
    my $expected = _h( "a\034a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 30: 0x1d in dictionary key - serialise only
{
    my $test_name = '0x1d in dictionary key - serialise only - must fail';
    my $expected = _h( "a\035a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 31: 0x1e in dictionary key - serialise only
{
    my $test_name = '0x1e in dictionary key - serialise only - must fail';
    my $expected = _h( "a\036a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 32: 0x1f in dictionary key - serialise only
{
    my $test_name = '0x1f in dictionary key - serialise only - must fail';
    my $expected = _h( "a\037a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 33: 0x20 in dictionary key - serialise only
{
    my $test_name = '0x20 in dictionary key - serialise only - must fail';
    my $expected = _h( "a a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 34: 0x21 in dictionary key - serialise only
{
    my $test_name = '0x21 in dictionary key - serialise only - must fail';
    my $expected = _h( "a!a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 35: 0x22 in dictionary key - serialise only
{
    my $test_name = '0x22 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\"a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 36: 0x23 in dictionary key - serialise only
{
    my $test_name = '0x23 in dictionary key - serialise only - must fail';
    my $expected = _h( "a#a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 37: 0x24 in dictionary key - serialise only
{
    my $test_name = '0x24 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\$a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 38: 0x25 in dictionary key - serialise only
{
    my $test_name = '0x25 in dictionary key - serialise only - must fail';
    my $expected = _h( "a%a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 39: 0x26 in dictionary key - serialise only
{
    my $test_name = '0x26 in dictionary key - serialise only - must fail';
    my $expected = _h( "a&a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 40: 0x27 in dictionary key - serialise only
{
    my $test_name = '0x27 in dictionary key - serialise only - must fail';
    my $expected = _h( "a'a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 41: 0x28 in dictionary key - serialise only
{
    my $test_name = '0x28 in dictionary key - serialise only - must fail';
    my $expected = _h( "a(a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 42: 0x29 in dictionary key - serialise only
{
    my $test_name = '0x29 in dictionary key - serialise only - must fail';
    my $expected = _h( "a)a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 43: 0x2b in dictionary key - serialise only
{
    my $test_name = '0x2b in dictionary key - serialise only - must fail';
    my $expected = _h( "a+a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 44: 0x2c in dictionary key - serialise only
{
    my $test_name = '0x2c in dictionary key - serialise only - must fail';
    my $expected = _h( "a,a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 45: 0x2f in dictionary key - serialise only
{
    my $test_name = '0x2f in dictionary key - serialise only - must fail';
    my $expected = _h( "a/a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 46: 0x3a in dictionary key - serialise only
{
    my $test_name = '0x3a in dictionary key - serialise only - must fail';
    my $expected = _h( "a:a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 47: 0x3b in dictionary key - serialise only
{
    my $test_name = '0x3b in dictionary key - serialise only - must fail';
    my $expected = _h( "a;a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 48: 0x3c in dictionary key - serialise only
{
    my $test_name = '0x3c in dictionary key - serialise only - must fail';
    my $expected = _h( "a<a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 49: 0x3d in dictionary key - serialise only
{
    my $test_name = '0x3d in dictionary key - serialise only - must fail';
    my $expected = _h( "a=a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 50: 0x3e in dictionary key - serialise only
{
    my $test_name = '0x3e in dictionary key - serialise only - must fail';
    my $expected = _h( "a>a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 51: 0x3f in dictionary key - serialise only
{
    my $test_name = '0x3f in dictionary key - serialise only - must fail';
    my $expected = _h( "a?a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 52: 0x40 in dictionary key - serialise only
{
    my $test_name = '0x40 in dictionary key - serialise only - must fail';
    my $expected = _h( "a\@a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 53: 0x41 in dictionary key - serialise only
{
    my $test_name = '0x41 in dictionary key - serialise only - must fail';
    my $expected = _h( "aAa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 54: 0x42 in dictionary key - serialise only
{
    my $test_name = '0x42 in dictionary key - serialise only - must fail';
    my $expected = _h( "aBa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 55: 0x43 in dictionary key - serialise only
{
    my $test_name = '0x43 in dictionary key - serialise only - must fail';
    my $expected = _h( "aCa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 56: 0x44 in dictionary key - serialise only
{
    my $test_name = '0x44 in dictionary key - serialise only - must fail';
    my $expected = _h( "aDa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 57: 0x45 in dictionary key - serialise only
{
    my $test_name = '0x45 in dictionary key - serialise only - must fail';
    my $expected = _h( "aEa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 58: 0x46 in dictionary key - serialise only
{
    my $test_name = '0x46 in dictionary key - serialise only - must fail';
    my $expected = _h( "aFa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 59: 0x47 in dictionary key - serialise only
{
    my $test_name = '0x47 in dictionary key - serialise only - must fail';
    my $expected = _h( "aGa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 60: 0x48 in dictionary key - serialise only
{
    my $test_name = '0x48 in dictionary key - serialise only - must fail';
    my $expected = _h( "aHa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 61: 0x49 in dictionary key - serialise only
{
    my $test_name = '0x49 in dictionary key - serialise only - must fail';
    my $expected = _h( "aIa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 62: 0x4a in dictionary key - serialise only
{
    my $test_name = '0x4a in dictionary key - serialise only - must fail';
    my $expected = _h( "aJa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 63: 0x4b in dictionary key - serialise only
{
    my $test_name = '0x4b in dictionary key - serialise only - must fail';
    my $expected = _h( "aKa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 64: 0x4c in dictionary key - serialise only
{
    my $test_name = '0x4c in dictionary key - serialise only - must fail';
    my $expected = _h( "aLa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 65: 0x4d in dictionary key - serialise only
{
    my $test_name = '0x4d in dictionary key - serialise only - must fail';
    my $expected = _h( "aMa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 66: 0x4e in dictionary key - serialise only
{
    my $test_name = '0x4e in dictionary key - serialise only - must fail';
    my $expected = _h( "aNa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 67: 0x4f in dictionary key - serialise only
{
    my $test_name = '0x4f in dictionary key - serialise only - must fail';
    my $expected = _h( "aOa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 68: 0x50 in dictionary key - serialise only
{
    my $test_name = '0x50 in dictionary key - serialise only - must fail';
    my $expected = _h( "aPa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 69: 0x51 in dictionary key - serialise only
{
    my $test_name = '0x51 in dictionary key - serialise only - must fail';
    my $expected = _h( "aQa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 70: 0x52 in dictionary key - serialise only
{
    my $test_name = '0x52 in dictionary key - serialise only - must fail';
    my $expected = _h( "aRa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 71: 0x53 in dictionary key - serialise only
{
    my $test_name = '0x53 in dictionary key - serialise only - must fail';
    my $expected = _h( "aSa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 72: 0x54 in dictionary key - serialise only
{
    my $test_name = '0x54 in dictionary key - serialise only - must fail';
    my $expected = _h( "aTa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 73: 0x55 in dictionary key - serialise only
{
    my $test_name = '0x55 in dictionary key - serialise only - must fail';
    my $expected = _h( "aUa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 74: 0x56 in dictionary key - serialise only
{
    my $test_name = '0x56 in dictionary key - serialise only - must fail';
    my $expected = _h( "aVa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 75: 0x57 in dictionary key - serialise only
{
    my $test_name = '0x57 in dictionary key - serialise only - must fail';
    my $expected = _h( "aWa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 76: 0x58 in dictionary key - serialise only
{
    my $test_name = '0x58 in dictionary key - serialise only - must fail';
    my $expected = _h( "aXa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 77: 0x59 in dictionary key - serialise only
{
    my $test_name = '0x59 in dictionary key - serialise only - must fail';
    my $expected = _h( "aYa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 78: 0x5a in dictionary key - serialise only
{
    my $test_name = '0x5a in dictionary key - serialise only - must fail';
    my $expected = _h( "aZa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 79: 0x5b in dictionary key - serialise only
{
    my $test_name = '0x5b in dictionary key - serialise only - must fail';
    my $expected = _h( "a[a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 80: 0x5c in dictionary key - serialise only
{
    my $test_name = '0x5c in dictionary key - serialise only - must fail';
    my $expected = _h( "a\\a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 81: 0x5d in dictionary key - serialise only
{
    my $test_name = '0x5d in dictionary key - serialise only - must fail';
    my $expected = _h( "a]a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 82: 0x5e in dictionary key - serialise only
{
    my $test_name = '0x5e in dictionary key - serialise only - must fail';
    my $expected = _h( "a^a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 83: 0x60 in dictionary key - serialise only
{
    my $test_name = '0x60 in dictionary key - serialise only - must fail';
    my $expected = _h( "a`a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 84: 0x7b in dictionary key - serialise only
{
    my $test_name = '0x7b in dictionary key - serialise only - must fail';
    my $expected = _h( "a{a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 85: 0x7c in dictionary key - serialise only
{
    my $test_name = '0x7c in dictionary key - serialise only - must fail';
    my $expected = _h( "a|a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 86: 0x7d in dictionary key - serialise only
{
    my $test_name = '0x7d in dictionary key - serialise only - must fail';
    my $expected = _h( "a}a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 87: 0x7e in dictionary key - serialise only
{
    my $test_name = '0x7e in dictionary key - serialise only - must fail';
    my $expected = _h( "a~a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 88: 0x7f in dictionary key - serialise only
{
    my $test_name = '0x7f in dictionary key - serialise only - must fail';
    my $expected = _h( "a\177a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 89: 0x00 starting a dictionary key - serialise only
{
    my $test_name = '0x00 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\000a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 90: 0x01 starting a dictionary key - serialise only
{
    my $test_name = '0x01 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\001a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 91: 0x02 starting a dictionary key - serialise only
{
    my $test_name = '0x02 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\002a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 92: 0x03 starting a dictionary key - serialise only
{
    my $test_name = '0x03 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\003a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 93: 0x04 starting a dictionary key - serialise only
{
    my $test_name = '0x04 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\004a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 94: 0x05 starting a dictionary key - serialise only
{
    my $test_name = '0x05 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\005a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 95: 0x06 starting a dictionary key - serialise only
{
    my $test_name = '0x06 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\006a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 96: 0x07 starting a dictionary key - serialise only
{
    my $test_name = '0x07 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\aa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 97: 0x08 starting a dictionary key - serialise only
{
    my $test_name = '0x08 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\ba" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 98: 0x09 starting a dictionary key - serialise only
{
    my $test_name = '0x09 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\ta" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 99: 0x0a starting a dictionary key - serialise only
{
    my $test_name = '0x0a starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\na" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 100: 0x0b starting a dictionary key - serialise only
{
    my $test_name = '0x0b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\013a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 101: 0x0c starting a dictionary key - serialise only
{
    my $test_name = '0x0c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\fa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 102: 0x0d starting a dictionary key - serialise only
{
    my $test_name = '0x0d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\ra" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 103: 0x0e starting a dictionary key - serialise only
{
    my $test_name = '0x0e starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\016a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 104: 0x0f starting a dictionary key - serialise only
{
    my $test_name = '0x0f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\017a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 105: 0x10 starting a dictionary key - serialise only
{
    my $test_name = '0x10 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\020a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 106: 0x11 starting a dictionary key - serialise only
{
    my $test_name = '0x11 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\021a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 107: 0x12 starting a dictionary key - serialise only
{
    my $test_name = '0x12 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\022a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 108: 0x13 starting a dictionary key - serialise only
{
    my $test_name = '0x13 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\023a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 109: 0x14 starting a dictionary key - serialise only
{
    my $test_name = '0x14 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\024a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 110: 0x15 starting a dictionary key - serialise only
{
    my $test_name = '0x15 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\025a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 111: 0x16 starting a dictionary key - serialise only
{
    my $test_name = '0x16 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\026a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 112: 0x17 starting a dictionary key - serialise only
{
    my $test_name = '0x17 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\027a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 113: 0x18 starting a dictionary key - serialise only
{
    my $test_name = '0x18 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\030a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 114: 0x19 starting a dictionary key - serialise only
{
    my $test_name = '0x19 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\031a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 115: 0x1a starting a dictionary key - serialise only
{
    my $test_name = '0x1a starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\032a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 116: 0x1b starting a dictionary key - serialise only
{
    my $test_name = '0x1b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\033a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 117: 0x1c starting a dictionary key - serialise only
{
    my $test_name = '0x1c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\034a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 118: 0x1d starting a dictionary key - serialise only
{
    my $test_name = '0x1d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\035a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 119: 0x1e starting a dictionary key - serialise only
{
    my $test_name = '0x1e starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\036a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 120: 0x1f starting a dictionary key - serialise only
{
    my $test_name = '0x1f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\037a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 121: 0x20 starting a dictionary key - serialise only
{
    my $test_name = '0x20 starting a dictionary key - serialise only - must fail';
    my $expected = _h( " a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 122: 0x21 starting a dictionary key - serialise only
{
    my $test_name = '0x21 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "!a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 123: 0x22 starting a dictionary key - serialise only
{
    my $test_name = '0x22 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\"a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 124: 0x23 starting a dictionary key - serialise only
{
    my $test_name = '0x23 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "#a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 125: 0x24 starting a dictionary key - serialise only
{
    my $test_name = '0x24 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\$a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 126: 0x25 starting a dictionary key - serialise only
{
    my $test_name = '0x25 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "%a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 127: 0x26 starting a dictionary key - serialise only
{
    my $test_name = '0x26 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "&a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 128: 0x27 starting a dictionary key - serialise only
{
    my $test_name = '0x27 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "'a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 129: 0x28 starting a dictionary key - serialise only
{
    my $test_name = '0x28 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "(a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 130: 0x29 starting a dictionary key - serialise only
{
    my $test_name = '0x29 starting a dictionary key - serialise only - must fail';
    my $expected = _h( ")a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 131: 0x2b starting a dictionary key - serialise only
{
    my $test_name = '0x2b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "+a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 132: 0x2c starting a dictionary key - serialise only
{
    my $test_name = '0x2c starting a dictionary key - serialise only - must fail';
    my $expected = _h( ",a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 133: 0x2d starting a dictionary key - serialise only
{
    my $test_name = '0x2d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "-a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 134: 0x2e starting a dictionary key - serialise only
{
    my $test_name = '0x2e starting a dictionary key - serialise only - must fail';
    my $expected = _h( ".a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 135: 0x2f starting a dictionary key - serialise only
{
    my $test_name = '0x2f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "/a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 136: 0x30 starting a dictionary key - serialise only
{
    my $test_name = '0x30 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "0a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 137: 0x31 starting a dictionary key - serialise only
{
    my $test_name = '0x31 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "1a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 138: 0x32 starting a dictionary key - serialise only
{
    my $test_name = '0x32 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "2a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 139: 0x33 starting a dictionary key - serialise only
{
    my $test_name = '0x33 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "3a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 140: 0x34 starting a dictionary key - serialise only
{
    my $test_name = '0x34 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "4a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 141: 0x35 starting a dictionary key - serialise only
{
    my $test_name = '0x35 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "5a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 142: 0x36 starting a dictionary key - serialise only
{
    my $test_name = '0x36 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "6a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 143: 0x37 starting a dictionary key - serialise only
{
    my $test_name = '0x37 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "7a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 144: 0x38 starting a dictionary key - serialise only
{
    my $test_name = '0x38 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "8a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 145: 0x39 starting a dictionary key - serialise only
{
    my $test_name = '0x39 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "9a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 146: 0x3a starting a dictionary key - serialise only
{
    my $test_name = '0x3a starting a dictionary key - serialise only - must fail';
    my $expected = _h( ":a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 147: 0x3b starting a dictionary key - serialise only
{
    my $test_name = '0x3b starting a dictionary key - serialise only - must fail';
    my $expected = _h( ";a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 148: 0x3c starting a dictionary key - serialise only
{
    my $test_name = '0x3c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "<a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 149: 0x3d starting a dictionary key - serialise only
{
    my $test_name = '0x3d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "=a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 150: 0x3e starting a dictionary key - serialise only
{
    my $test_name = '0x3e starting a dictionary key - serialise only - must fail';
    my $expected = _h( ">a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 151: 0x3f starting a dictionary key - serialise only
{
    my $test_name = '0x3f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "?a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 152: 0x40 starting a dictionary key - serialise only
{
    my $test_name = '0x40 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\@a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 153: 0x41 starting a dictionary key - serialise only
{
    my $test_name = '0x41 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Aa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 154: 0x42 starting a dictionary key - serialise only
{
    my $test_name = '0x42 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ba" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 155: 0x43 starting a dictionary key - serialise only
{
    my $test_name = '0x43 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ca" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 156: 0x44 starting a dictionary key - serialise only
{
    my $test_name = '0x44 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Da" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 157: 0x45 starting a dictionary key - serialise only
{
    my $test_name = '0x45 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ea" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 158: 0x46 starting a dictionary key - serialise only
{
    my $test_name = '0x46 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Fa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 159: 0x47 starting a dictionary key - serialise only
{
    my $test_name = '0x47 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ga" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 160: 0x48 starting a dictionary key - serialise only
{
    my $test_name = '0x48 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ha" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 161: 0x49 starting a dictionary key - serialise only
{
    my $test_name = '0x49 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ia" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 162: 0x4a starting a dictionary key - serialise only
{
    my $test_name = '0x4a starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ja" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 163: 0x4b starting a dictionary key - serialise only
{
    my $test_name = '0x4b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ka" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 164: 0x4c starting a dictionary key - serialise only
{
    my $test_name = '0x4c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "La" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 165: 0x4d starting a dictionary key - serialise only
{
    my $test_name = '0x4d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ma" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 166: 0x4e starting a dictionary key - serialise only
{
    my $test_name = '0x4e starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Na" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 167: 0x4f starting a dictionary key - serialise only
{
    my $test_name = '0x4f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Oa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 168: 0x50 starting a dictionary key - serialise only
{
    my $test_name = '0x50 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Pa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 169: 0x51 starting a dictionary key - serialise only
{
    my $test_name = '0x51 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Qa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 170: 0x52 starting a dictionary key - serialise only
{
    my $test_name = '0x52 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ra" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 171: 0x53 starting a dictionary key - serialise only
{
    my $test_name = '0x53 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Sa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 172: 0x54 starting a dictionary key - serialise only
{
    my $test_name = '0x54 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ta" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 173: 0x55 starting a dictionary key - serialise only
{
    my $test_name = '0x55 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ua" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 174: 0x56 starting a dictionary key - serialise only
{
    my $test_name = '0x56 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Va" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 175: 0x57 starting a dictionary key - serialise only
{
    my $test_name = '0x57 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Wa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 176: 0x58 starting a dictionary key - serialise only
{
    my $test_name = '0x58 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Xa" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 177: 0x59 starting a dictionary key - serialise only
{
    my $test_name = '0x59 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Ya" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 178: 0x5a starting a dictionary key - serialise only
{
    my $test_name = '0x5a starting a dictionary key - serialise only - must fail';
    my $expected = _h( "Za" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 179: 0x5b starting a dictionary key - serialise only
{
    my $test_name = '0x5b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "[a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 180: 0x5c starting a dictionary key - serialise only
{
    my $test_name = '0x5c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\\a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 181: 0x5d starting a dictionary key - serialise only
{
    my $test_name = '0x5d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "]a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 182: 0x5e starting a dictionary key - serialise only
{
    my $test_name = '0x5e starting a dictionary key - serialise only - must fail';
    my $expected = _h( "^a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 183: 0x5f starting a dictionary key - serialise only
{
    my $test_name = '0x5f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "_a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 184: 0x60 starting a dictionary key - serialise only
{
    my $test_name = '0x60 starting a dictionary key - serialise only - must fail';
    my $expected = _h( "`a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 185: 0x7b starting a dictionary key - serialise only
{
    my $test_name = '0x7b starting a dictionary key - serialise only - must fail';
    my $expected = _h( "{a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 186: 0x7c starting a dictionary key - serialise only
{
    my $test_name = '0x7c starting a dictionary key - serialise only - must fail';
    my $expected = _h( "|a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 187: 0x7d starting a dictionary key - serialise only
{
    my $test_name = '0x7d starting a dictionary key - serialise only - must fail';
    my $expected = _h( "}a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 188: 0x7e starting a dictionary key - serialise only
{
    my $test_name = '0x7e starting a dictionary key - serialise only - must fail';
    my $expected = _h( "~a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 189: 0x7f starting a dictionary key - serialise only
{
    my $test_name = '0x7f starting a dictionary key - serialise only - must fail';
    my $expected = _h( "\177a" => { _type => 'integer', value => 1 } );
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 190: 0x00 in parameterised list key - serialise only
{
    my $test_name = '0x00 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\000a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 191: 0x01 in parameterised list key - serialise only
{
    my $test_name = '0x01 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\001a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 192: 0x02 in parameterised list key - serialise only
{
    my $test_name = '0x02 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\002a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 193: 0x03 in parameterised list key - serialise only
{
    my $test_name = '0x03 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\003a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 194: 0x04 in parameterised list key - serialise only
{
    my $test_name = '0x04 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\004a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 195: 0x05 in parameterised list key - serialise only
{
    my $test_name = '0x05 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\005a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 196: 0x06 in parameterised list key - serialise only
{
    my $test_name = '0x06 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\006a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 197: 0x07 in parameterised list key - serialise only
{
    my $test_name = '0x07 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\aa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 198: 0x08 in parameterised list key - serialise only
{
    my $test_name = '0x08 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\ba" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 199: 0x09 in parameterised list key - serialise only
{
    my $test_name = '0x09 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\ta" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 200: 0x0a in parameterised list key - serialise only
{
    my $test_name = '0x0a in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\na" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 201: 0x0b in parameterised list key - serialise only
{
    my $test_name = '0x0b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\013a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 202: 0x0c in parameterised list key - serialise only
{
    my $test_name = '0x0c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\fa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 203: 0x0d in parameterised list key - serialise only
{
    my $test_name = '0x0d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\ra" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 204: 0x0e in parameterised list key - serialise only
{
    my $test_name = '0x0e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\016a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 205: 0x0f in parameterised list key - serialise only
{
    my $test_name = '0x0f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\017a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 206: 0x10 in parameterised list key - serialise only
{
    my $test_name = '0x10 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\020a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 207: 0x11 in parameterised list key - serialise only
{
    my $test_name = '0x11 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\021a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 208: 0x12 in parameterised list key - serialise only
{
    my $test_name = '0x12 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\022a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 209: 0x13 in parameterised list key - serialise only
{
    my $test_name = '0x13 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\023a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 210: 0x14 in parameterised list key - serialise only
{
    my $test_name = '0x14 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\024a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 211: 0x15 in parameterised list key - serialise only
{
    my $test_name = '0x15 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\025a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 212: 0x16 in parameterised list key - serialise only
{
    my $test_name = '0x16 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\026a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 213: 0x17 in parameterised list key - serialise only
{
    my $test_name = '0x17 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\027a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 214: 0x18 in parameterised list key - serialise only
{
    my $test_name = '0x18 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\030a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 215: 0x19 in parameterised list key - serialise only
{
    my $test_name = '0x19 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\031a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 216: 0x1a in parameterised list key - serialise only
{
    my $test_name = '0x1a in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\032a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 217: 0x1b in parameterised list key - serialise only
{
    my $test_name = '0x1b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\033a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 218: 0x1c in parameterised list key - serialise only
{
    my $test_name = '0x1c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\034a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 219: 0x1d in parameterised list key - serialise only
{
    my $test_name = '0x1d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\035a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 220: 0x1e in parameterised list key - serialise only
{
    my $test_name = '0x1e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\036a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 221: 0x1f in parameterised list key - serialise only
{
    my $test_name = '0x1f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\037a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 222: 0x20 in parameterised list key - serialise only
{
    my $test_name = '0x20 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 223: 0x21 in parameterised list key - serialise only
{
    my $test_name = '0x21 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a!a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 224: 0x22 in parameterised list key - serialise only
{
    my $test_name = '0x22 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\"a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 225: 0x23 in parameterised list key - serialise only
{
    my $test_name = '0x23 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a#a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 226: 0x24 in parameterised list key - serialise only
{
    my $test_name = '0x24 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\$a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 227: 0x25 in parameterised list key - serialise only
{
    my $test_name = '0x25 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a%a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 228: 0x26 in parameterised list key - serialise only
{
    my $test_name = '0x26 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a&a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 229: 0x27 in parameterised list key - serialise only
{
    my $test_name = '0x27 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a'a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 230: 0x28 in parameterised list key - serialise only
{
    my $test_name = '0x28 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a(a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 231: 0x29 in parameterised list key - serialise only
{
    my $test_name = '0x29 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a)a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 232: 0x2b in parameterised list key - serialise only
{
    my $test_name = '0x2b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a+a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 233: 0x2c in parameterised list key - serialise only
{
    my $test_name = '0x2c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a,a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 234: 0x2f in parameterised list key - serialise only
{
    my $test_name = '0x2f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a/a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 235: 0x3a in parameterised list key - serialise only
{
    my $test_name = '0x3a in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a:a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 236: 0x3b in parameterised list key - serialise only
{
    my $test_name = '0x3b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a;a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 237: 0x3c in parameterised list key - serialise only
{
    my $test_name = '0x3c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a<a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 238: 0x3d in parameterised list key - serialise only
{
    my $test_name = '0x3d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a=a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 239: 0x3e in parameterised list key - serialise only
{
    my $test_name = '0x3e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a>a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 240: 0x3f in parameterised list key - serialise only
{
    my $test_name = '0x3f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a?a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 241: 0x40 in parameterised list key - serialise only
{
    my $test_name = '0x40 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\@a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 242: 0x41 in parameterised list key - serialise only
{
    my $test_name = '0x41 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aAa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 243: 0x42 in parameterised list key - serialise only
{
    my $test_name = '0x42 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aBa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 244: 0x43 in parameterised list key - serialise only
{
    my $test_name = '0x43 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aCa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 245: 0x44 in parameterised list key - serialise only
{
    my $test_name = '0x44 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aDa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 246: 0x45 in parameterised list key - serialise only
{
    my $test_name = '0x45 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aEa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 247: 0x46 in parameterised list key - serialise only
{
    my $test_name = '0x46 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aFa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 248: 0x47 in parameterised list key - serialise only
{
    my $test_name = '0x47 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aGa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 249: 0x48 in parameterised list key - serialise only
{
    my $test_name = '0x48 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aHa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 250: 0x49 in parameterised list key - serialise only
{
    my $test_name = '0x49 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aIa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 251: 0x4a in parameterised list key - serialise only
{
    my $test_name = '0x4a in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aJa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 252: 0x4b in parameterised list key - serialise only
{
    my $test_name = '0x4b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aKa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 253: 0x4c in parameterised list key - serialise only
{
    my $test_name = '0x4c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aLa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 254: 0x4d in parameterised list key - serialise only
{
    my $test_name = '0x4d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aMa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 255: 0x4e in parameterised list key - serialise only
{
    my $test_name = '0x4e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aNa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 256: 0x4f in parameterised list key - serialise only
{
    my $test_name = '0x4f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aOa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 257: 0x50 in parameterised list key - serialise only
{
    my $test_name = '0x50 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aPa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 258: 0x51 in parameterised list key - serialise only
{
    my $test_name = '0x51 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aQa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 259: 0x52 in parameterised list key - serialise only
{
    my $test_name = '0x52 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aRa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 260: 0x53 in parameterised list key - serialise only
{
    my $test_name = '0x53 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aSa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 261: 0x54 in parameterised list key - serialise only
{
    my $test_name = '0x54 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aTa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 262: 0x55 in parameterised list key - serialise only
{
    my $test_name = '0x55 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aUa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 263: 0x56 in parameterised list key - serialise only
{
    my $test_name = '0x56 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aVa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 264: 0x57 in parameterised list key - serialise only
{
    my $test_name = '0x57 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aWa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 265: 0x58 in parameterised list key - serialise only
{
    my $test_name = '0x58 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aXa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 266: 0x59 in parameterised list key - serialise only
{
    my $test_name = '0x59 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aYa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 267: 0x5a in parameterised list key - serialise only
{
    my $test_name = '0x5a in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "aZa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 268: 0x5b in parameterised list key - serialise only
{
    my $test_name = '0x5b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a[a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 269: 0x5c in parameterised list key - serialise only
{
    my $test_name = '0x5c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\\a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 270: 0x5d in parameterised list key - serialise only
{
    my $test_name = '0x5d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a]a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 271: 0x5e in parameterised list key - serialise only
{
    my $test_name = '0x5e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a^a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 272: 0x60 in parameterised list key - serialise only
{
    my $test_name = '0x60 in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a`a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 273: 0x7b in parameterised list key - serialise only
{
    my $test_name = '0x7b in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a{a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 274: 0x7c in parameterised list key - serialise only
{
    my $test_name = '0x7c in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a|a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 275: 0x7d in parameterised list key - serialise only
{
    my $test_name = '0x7d in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a}a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 276: 0x7e in parameterised list key - serialise only
{
    my $test_name = '0x7e in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a~a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 277: 0x7f in parameterised list key - serialise only
{
    my $test_name = '0x7f in parameterised list key - serialise only - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "a\177a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 278: 0x00 starting a parameterised list key
{
    my $test_name = '0x00 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\000a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 279: 0x01 starting a parameterised list key
{
    my $test_name = '0x01 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\001a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 280: 0x02 starting a parameterised list key
{
    my $test_name = '0x02 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\002a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 281: 0x03 starting a parameterised list key
{
    my $test_name = '0x03 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\003a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 282: 0x04 starting a parameterised list key
{
    my $test_name = '0x04 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\004a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 283: 0x05 starting a parameterised list key
{
    my $test_name = '0x05 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\005a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 284: 0x06 starting a parameterised list key
{
    my $test_name = '0x06 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\006a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 285: 0x07 starting a parameterised list key
{
    my $test_name = '0x07 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\aa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 286: 0x08 starting a parameterised list key
{
    my $test_name = '0x08 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\ba" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 287: 0x09 starting a parameterised list key
{
    my $test_name = '0x09 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\ta" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 288: 0x0a starting a parameterised list key
{
    my $test_name = '0x0a starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\na" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 289: 0x0b starting a parameterised list key
{
    my $test_name = '0x0b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\013a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 290: 0x0c starting a parameterised list key
{
    my $test_name = '0x0c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\fa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 291: 0x0d starting a parameterised list key
{
    my $test_name = '0x0d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\ra" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 292: 0x0e starting a parameterised list key
{
    my $test_name = '0x0e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\016a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 293: 0x0f starting a parameterised list key
{
    my $test_name = '0x0f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\017a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 294: 0x10 starting a parameterised list key
{
    my $test_name = '0x10 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\020a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 295: 0x11 starting a parameterised list key
{
    my $test_name = '0x11 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\021a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 296: 0x12 starting a parameterised list key
{
    my $test_name = '0x12 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\022a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 297: 0x13 starting a parameterised list key
{
    my $test_name = '0x13 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\023a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 298: 0x14 starting a parameterised list key
{
    my $test_name = '0x14 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\024a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 299: 0x15 starting a parameterised list key
{
    my $test_name = '0x15 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\025a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 300: 0x16 starting a parameterised list key
{
    my $test_name = '0x16 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\026a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 301: 0x17 starting a parameterised list key
{
    my $test_name = '0x17 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\027a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 302: 0x18 starting a parameterised list key
{
    my $test_name = '0x18 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\030a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 303: 0x19 starting a parameterised list key
{
    my $test_name = '0x19 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\031a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 304: 0x1a starting a parameterised list key
{
    my $test_name = '0x1a starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\032a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 305: 0x1b starting a parameterised list key
{
    my $test_name = '0x1b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\033a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 306: 0x1c starting a parameterised list key
{
    my $test_name = '0x1c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\034a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 307: 0x1d starting a parameterised list key
{
    my $test_name = '0x1d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\035a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 308: 0x1e starting a parameterised list key
{
    my $test_name = '0x1e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\036a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 309: 0x1f starting a parameterised list key
{
    my $test_name = '0x1f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\037a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 310: 0x20 starting a parameterised list key
{
    my $test_name = '0x20 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( " a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 311: 0x21 starting a parameterised list key
{
    my $test_name = '0x21 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "!a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 312: 0x22 starting a parameterised list key
{
    my $test_name = '0x22 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\"a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 313: 0x23 starting a parameterised list key
{
    my $test_name = '0x23 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "#a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 314: 0x24 starting a parameterised list key
{
    my $test_name = '0x24 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\$a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 315: 0x25 starting a parameterised list key
{
    my $test_name = '0x25 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "%a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 316: 0x26 starting a parameterised list key
{
    my $test_name = '0x26 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "&a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 317: 0x27 starting a parameterised list key
{
    my $test_name = '0x27 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "'a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 318: 0x28 starting a parameterised list key
{
    my $test_name = '0x28 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "(a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 319: 0x29 starting a parameterised list key
{
    my $test_name = '0x29 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ")a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 320: 0x2b starting a parameterised list key
{
    my $test_name = '0x2b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "+a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 321: 0x2c starting a parameterised list key
{
    my $test_name = '0x2c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ",a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 322: 0x2d starting a parameterised list key
{
    my $test_name = '0x2d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "-a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 323: 0x2e starting a parameterised list key
{
    my $test_name = '0x2e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ".a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 324: 0x2f starting a parameterised list key
{
    my $test_name = '0x2f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "/a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 325: 0x30 starting a parameterised list key
{
    my $test_name = '0x30 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "0a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 326: 0x31 starting a parameterised list key
{
    my $test_name = '0x31 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "1a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 327: 0x32 starting a parameterised list key
{
    my $test_name = '0x32 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "2a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 328: 0x33 starting a parameterised list key
{
    my $test_name = '0x33 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "3a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 329: 0x34 starting a parameterised list key
{
    my $test_name = '0x34 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "4a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 330: 0x35 starting a parameterised list key
{
    my $test_name = '0x35 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "5a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 331: 0x36 starting a parameterised list key
{
    my $test_name = '0x36 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "6a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 332: 0x37 starting a parameterised list key
{
    my $test_name = '0x37 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "7a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 333: 0x38 starting a parameterised list key
{
    my $test_name = '0x38 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "8a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 334: 0x39 starting a parameterised list key
{
    my $test_name = '0x39 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "9a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 335: 0x3a starting a parameterised list key
{
    my $test_name = '0x3a starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ":a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 336: 0x3b starting a parameterised list key
{
    my $test_name = '0x3b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ";a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 337: 0x3c starting a parameterised list key
{
    my $test_name = '0x3c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "<a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 338: 0x3d starting a parameterised list key
{
    my $test_name = '0x3d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "=a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 339: 0x3e starting a parameterised list key
{
    my $test_name = '0x3e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( ">a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 340: 0x3f starting a parameterised list key
{
    my $test_name = '0x3f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "?a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 341: 0x40 starting a parameterised list key
{
    my $test_name = '0x40 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\@a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 342: 0x41 starting a parameterised list key
{
    my $test_name = '0x41 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Aa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 343: 0x42 starting a parameterised list key
{
    my $test_name = '0x42 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ba" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 344: 0x43 starting a parameterised list key
{
    my $test_name = '0x43 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ca" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 345: 0x44 starting a parameterised list key
{
    my $test_name = '0x44 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Da" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 346: 0x45 starting a parameterised list key
{
    my $test_name = '0x45 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ea" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 347: 0x46 starting a parameterised list key
{
    my $test_name = '0x46 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Fa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 348: 0x47 starting a parameterised list key
{
    my $test_name = '0x47 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ga" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 349: 0x48 starting a parameterised list key
{
    my $test_name = '0x48 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ha" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 350: 0x49 starting a parameterised list key
{
    my $test_name = '0x49 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ia" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 351: 0x4a starting a parameterised list key
{
    my $test_name = '0x4a starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ja" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 352: 0x4b starting a parameterised list key
{
    my $test_name = '0x4b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ka" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 353: 0x4c starting a parameterised list key
{
    my $test_name = '0x4c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "La" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 354: 0x4d starting a parameterised list key
{
    my $test_name = '0x4d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ma" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 355: 0x4e starting a parameterised list key
{
    my $test_name = '0x4e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Na" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 356: 0x4f starting a parameterised list key
{
    my $test_name = '0x4f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Oa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 357: 0x50 starting a parameterised list key
{
    my $test_name = '0x50 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Pa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 358: 0x51 starting a parameterised list key
{
    my $test_name = '0x51 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Qa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 359: 0x52 starting a parameterised list key
{
    my $test_name = '0x52 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ra" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 360: 0x53 starting a parameterised list key
{
    my $test_name = '0x53 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Sa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 361: 0x54 starting a parameterised list key
{
    my $test_name = '0x54 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ta" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 362: 0x55 starting a parameterised list key
{
    my $test_name = '0x55 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ua" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 363: 0x56 starting a parameterised list key
{
    my $test_name = '0x56 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Va" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 364: 0x57 starting a parameterised list key
{
    my $test_name = '0x57 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Wa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 365: 0x58 starting a parameterised list key
{
    my $test_name = '0x58 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Xa" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 366: 0x59 starting a parameterised list key
{
    my $test_name = '0x59 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Ya" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 367: 0x5a starting a parameterised list key
{
    my $test_name = '0x5a starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "Za" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 368: 0x5b starting a parameterised list key
{
    my $test_name = '0x5b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "[a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 369: 0x5c starting a parameterised list key
{
    my $test_name = '0x5c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\\a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 370: 0x5d starting a parameterised list key
{
    my $test_name = '0x5d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "]a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 371: 0x5e starting a parameterised list key
{
    my $test_name = '0x5e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "^a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 372: 0x5f starting a parameterised list key
{
    my $test_name = '0x5f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "_a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 373: 0x60 starting a parameterised list key
{
    my $test_name = '0x60 starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "`a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 374: 0x7b starting a parameterised list key
{
    my $test_name = '0x7b starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "{a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 375: 0x7c starting a parameterised list key
{
    my $test_name = '0x7c starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "|a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 376: 0x7d starting a parameterised list key
{
    my $test_name = '0x7d starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "}a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 377: 0x7e starting a parameterised list key
{
    my $test_name = '0x7e starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "~a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 378: 0x7f starting a parameterised list key
{
    my $test_name = '0x7f starting a parameterised list key - must fail';
    my $expected = [ { _type => 'token', value => "foo", params => _h( "\177a" => { _type => 'integer', value => 1 } ) } ];
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

