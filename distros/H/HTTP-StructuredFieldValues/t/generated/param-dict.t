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

# Generated from param-dict.json
# Total tests: 14

plan tests => 14;

# Test 1: basic parameterised dict
subtest "basic parameterised dict" => sub {
    my $test_name = "basic parameterised dict";
    my $input = "abc=123;a=1;b=2, def=456, ghi=789;q=9;r=\"+w\"";
    my $expected = _h(
        "abc" => { _type => 'integer', value => 123, params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 } ) },
        "def" => { _type => 'integer', value => 456 },
        "ghi" => { _type => 'integer', value => 789, params => _h( "q" => { _type => 'integer', value => 9 }, "r" => { _type => 'string', value => "+w" } ) }
    );
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

# Test 2: single item parameterised dict
subtest "single item parameterised dict" => sub {
    my $test_name = "single item parameterised dict";
    my $input = "a=b; q=1.0";
    my $expected = _h( "a" => { _type => 'token', value => "b", params => _h( "q" => { _type => 'decimal', value => 1 } ) } );
    my $canonical = "a=b;q=1.0";
    
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

# Test 3: list item parameterised dictionary
subtest "list item parameterised dictionary" => sub {
    my $test_name = "list item parameterised dictionary";
    my $input = "a=(1 2); q=1.0";
    my $expected = _h( "a" => { _type => 'inner_list', value => [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 2 }
    ], params => _h( "q" => { _type => 'decimal', value => 1 } ) } );
    my $canonical = "a=(1 2);q=1.0";
    
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

# Test 4: missing parameter value parameterised dict
subtest "missing parameter value parameterised dict" => sub {
    my $test_name = "missing parameter value parameterised dict";
    my $input = "a=3;c;d=5";
    my $expected = _h( "a" => { _type => 'integer', value => 3, params => _h( "c" => { _type => 'boolean', value => 1 }, "d" => { _type => 'integer', value => 5 } ) } );
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

# Test 5: terminal missing parameter value parameterised dict
subtest "terminal missing parameter value parameterised dict" => sub {
    my $test_name = "terminal missing parameter value parameterised dict";
    my $input = "a=3;c=5;d";
    my $expected = _h( "a" => { _type => 'integer', value => 3, params => _h( "c" => { _type => 'integer', value => 5 }, "d" => { _type => 'boolean', value => 1 } ) } );
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

# Test 6: no whitespace parameterised dict
subtest "no whitespace parameterised dict" => sub {
    my $test_name = "no whitespace parameterised dict";
    my $input = "a=b;c=1,d=e;f=2";
    my $expected = _h(
        "a" => { _type => 'token', value => "b", params => _h( "c" => { _type => 'integer', value => 1 } ) },
        "d" => { _type => 'token', value => "e", params => _h( "f" => { _type => 'integer', value => 2 } ) }
    );
    my $canonical = "a=b;c=1, d=e;f=2";
    
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

# Test 7: whitespace before = parameterised dict
{
    my $test_name = 'whitespace before = parameterised dict - must fail';
    my $input = "a=b;q =0.5";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 8: whitespace after = parameterised dict
{
    my $test_name = 'whitespace after = parameterised dict - must fail';
    my $input = "a=b;q= 0.5";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 9: whitespace before ; parameterised dict
{
    my $test_name = 'whitespace before ; parameterised dict - must fail';
    my $input = "a=b ;q=0.5";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 10: whitespace after ; parameterised dict
subtest "whitespace after ; parameterised dict" => sub {
    my $test_name = "whitespace after ; parameterised dict";
    my $input = "a=b; q=0.5";
    my $expected = _h( "a" => { _type => 'token', value => "b", params => _h( "q" => { _type => 'decimal', value => 0.5 } ) } );
    my $canonical = "a=b;q=0.5";
    
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

# Test 11: extra whitespace parameterised dict
subtest "extra whitespace parameterised dict" => sub {
    my $test_name = "extra whitespace parameterised dict";
    my $input = "a=b;  c=1  ,  d=e; f=2; g=3";
    my $expected = _h(
        "a" => { _type => 'token', value => "b", params => _h( "c" => { _type => 'integer', value => 1 } ) },
        "d" => { _type => 'token', value => "e", params => _h( "f" => { _type => 'integer', value => 2 }, "g" => { _type => 'integer', value => 3 } ) }
    );
    my $canonical = "a=b;c=1, d=e;f=2;g=3";
    
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

# Test 12: two lines parameterised list
subtest "two lines parameterised list" => sub {
    my $test_name = "two lines parameterised list";
    my $input = "a=b;c=1,d=e;f=2";
    my $expected = _h(
        "a" => { _type => 'token', value => "b", params => _h( "c" => { _type => 'integer', value => 1 } ) },
        "d" => { _type => 'token', value => "e", params => _h( "f" => { _type => 'integer', value => 2 } ) }
    );
    my $canonical = "a=b;c=1, d=e;f=2";
    
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

# Test 13: trailing comma parameterised list
{
    my $test_name = 'trailing comma parameterised list - must fail';
    my $input = "a=b; q=1.0,";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 14: empty item parameterised list
{
    my $test_name = 'empty item parameterised list - must fail';
    my $input = "a=b; q=1.0,,c=d";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

