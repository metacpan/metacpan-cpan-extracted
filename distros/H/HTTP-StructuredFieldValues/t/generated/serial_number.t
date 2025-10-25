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

# Generated from serial_number.json
# Total tests: 9

plan tests => 9;

# Test 1: too big positive integer - serialize
{
    my $test_name = 'too big positive integer - serialize - must fail';
    my $expected = { _type => 'integer', value => 1000000000000000 };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 2: too big negative integer - serialize
{
    my $test_name = 'too big negative integer - serialize - must fail';
    my $expected = { _type => 'integer', value => -1000000000000000 };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 3: too big positive decimal - serialize
{
    my $test_name = 'too big positive decimal - serialize - must fail';
    my $expected = { _type => 'decimal', value => 1000000000000.1 };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 4: too big negative decimal - serialize
{
    my $test_name = 'too big negative decimal - serialize - must fail';
    my $expected = { _type => 'decimal', value => -1000000000000.1 };
    
    eval { encode($expected); };
    if ($@) {
        note($@);
        pass($test_name);
    } else {
        diag("Expected failure but got success");
        fail($test_name);
    }
}

# Test 5: round positive odd decimal - serialize
{
    my $test_name = 'round positive odd decimal - serialize - encode only';
    my $expected = { _type => 'decimal', value => 0.0015 };
    my $canonical = "0.002";
    
    my $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Eecode error:", $@);
        diag("Input was: ", $expected);
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
}

# Test 6: round positive even decimal - serialize
{
    my $test_name = 'round positive even decimal - serialize - encode only';
    my $expected = { _type => 'decimal', value => 0.0025 };
    my $canonical = "0.002";
    
    my $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Eecode error:", $@);
        diag("Input was: ", $expected);
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
}

# Test 7: round negative odd decimal - serialize
{
    my $test_name = 'round negative odd decimal - serialize - encode only';
    my $expected = { _type => 'decimal', value => -0.0015 };
    my $canonical = "-0.002";
    
    my $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Eecode error:", $@);
        diag("Input was: ", $expected);
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
}

# Test 8: round negative even decimal - serialize
{
    my $test_name = 'round negative even decimal - serialize - encode only';
    my $expected = { _type => 'decimal', value => -0.0025 };
    my $canonical = "-0.002";
    
    my $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Eecode error:", $@);
        diag("Input was: ", $expected);
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
}

# Test 9: decimal round up to integer part - serialize
{
    my $test_name = 'decimal round up to integer part - serialize - encode only';
    my $expected = { _type => 'decimal', value => 9.9995 };
    my $canonical = "10.0";
    
    my $result = eval { encode($expected); };
    if ($@) {
        fail($test_name);
        diag("Eecode error:", $@);
        diag("Input was: ", $expected);
    } else {
        is($result, $canonical, $test_name) or do {
            diag("Got: ", explain($result));
            diag("Expected: ", explain($canonical));
            diag("Input was: ", explain($expected));
        };
    }
}

