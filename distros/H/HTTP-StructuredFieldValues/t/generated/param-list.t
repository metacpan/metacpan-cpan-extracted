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

# Generated from param-list.json
# Total tests: 13

plan tests => 13;

# Test 1: basic parameterised list
subtest "basic parameterised list" => sub {
    my $test_name = "basic parameterised list";
    my $input = "abc_123;a=1;b=2; cdef_456, ghi;q=9;r=\"+w\"";
    my $expected = [
        { _type => 'token', value => "abc_123", params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 }, "cdef_456" => { _type => 'boolean', value => 1 } ) },
        { _type => 'token', value => "ghi", params => _h( "q" => { _type => 'integer', value => 9 }, "r" => { _type => 'string', value => "+w" } ) }
    ];
    my $canonical = "abc_123;a=1;b=2;cdef_456, ghi;q=9;r=\"+w\"";
    
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

# Test 2: single item parameterised list
subtest "single item parameterised list" => sub {
    my $test_name = "single item parameterised list";
    my $input = "text/html;q=1.0";
    my $expected = [ { _type => 'token', value => "text/html", params => _h( "q" => { _type => 'decimal', value => 1 } ) } ];
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

# Test 3: missing parameter value parameterised list
subtest "missing parameter value parameterised list" => sub {
    my $test_name = "missing parameter value parameterised list";
    my $input = "text/html;a;q=1.0";
    my $expected = [ { _type => 'token', value => "text/html", params => _h( "a" => { _type => 'boolean', value => 1 }, "q" => { _type => 'decimal', value => 1 } ) } ];
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

# Test 4: missing terminal parameter value parameterised list
subtest "missing terminal parameter value parameterised list" => sub {
    my $test_name = "missing terminal parameter value parameterised list";
    my $input = "text/html;q=1.0;a";
    my $expected = [ { _type => 'token', value => "text/html", params => _h( "q" => { _type => 'decimal', value => 1 }, "a" => { _type => 'boolean', value => 1 } ) } ];
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

# Test 5: no whitespace parameterised list
subtest "no whitespace parameterised list" => sub {
    my $test_name = "no whitespace parameterised list";
    my $input = "text/html,text/plain;q=0.5";
    my $expected = [
        { _type => 'token', value => "text/html" },
        { _type => 'token', value => "text/plain", params => _h( "q" => { _type => 'decimal', value => 0.5 } ) }
    ];
    my $canonical = "text/html, text/plain;q=0.5";
    
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

# Test 6: whitespace before = parameterised list
{
    my $test_name = 'whitespace before = parameterised list - must fail';
    my $input = "text/html, text/plain;q =0.5";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 7: whitespace after = parameterised list
{
    my $test_name = 'whitespace after = parameterised list - must fail';
    my $input = "text/html, text/plain;q= 0.5";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: whitespace before ; parameterised list
{
    my $test_name = 'whitespace before ; parameterised list - must fail';
    my $input = "text/html, text/plain ;q=0.5";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: whitespace after ; parameterised list
subtest "whitespace after ; parameterised list" => sub {
    my $test_name = "whitespace after ; parameterised list";
    my $input = "text/html, text/plain; q=0.5";
    my $expected = [
        { _type => 'token', value => "text/html" },
        { _type => 'token', value => "text/plain", params => _h( "q" => { _type => 'decimal', value => 0.5 } ) }
    ];
    my $canonical = "text/html, text/plain;q=0.5";
    
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

# Test 10: extra whitespace parameterised list
subtest "extra whitespace parameterised list" => sub {
    my $test_name = "extra whitespace parameterised list";
    my $input = "text/html  ,  text/plain;  q=0.5;  charset=utf-8";
    my $expected = [
        { _type => 'token', value => "text/html" },
        { _type => 'token', value => "text/plain", params => _h( "q" => { _type => 'decimal', value => 0.5 }, "charset" => { _type => 'token', value => "utf-8" } ) }
    ];
    my $canonical = "text/html, text/plain;q=0.5;charset=utf-8";
    
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

# Test 11: two lines parameterised list
subtest "two lines parameterised list" => sub {
    my $test_name = "two lines parameterised list";
    my $input = "text/html,text/plain;q=0.5";
    my $expected = [
        { _type => 'token', value => "text/html" },
        { _type => 'token', value => "text/plain", params => _h( "q" => { _type => 'decimal', value => 0.5 } ) }
    ];
    my $canonical = "text/html, text/plain;q=0.5";
    
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

# Test 12: trailing comma parameterised list
{
    my $test_name = 'trailing comma parameterised list - must fail';
    my $input = "text/html,text/plain;q=0.5,";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 13: empty item parameterised list
{
    my $test_name = 'empty item parameterised list - must fail';
    my $input = "text/html,,text/plain;q=0.5,";
    
    eval { decode_list($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

