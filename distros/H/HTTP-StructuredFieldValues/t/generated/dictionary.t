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

# Generated from dictionary.json
# Total tests: 25

plan tests => 25;

# Test 1: basic dictionary
subtest "basic dictionary" => sub {
    my $test_name = "basic dictionary";
    my $input = "en=\"Applepie\", da=:w4ZibGV0w6ZydGUK:";
    my $expected = _h(
        "en" => { _type => 'string', value => "Applepie" },
        "da" => { _type => 'binary', value => decode_base32('YODGE3DFOTB2M4TUMUFA') }
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

# Test 2: empty dictionary
subtest "empty dictionary" => sub {
    my $test_name = "empty dictionary";
    my $input = "";
    my $expected = _h();
    my $canonical = "";
    
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

# Test 3: single item dictionary
subtest "single item dictionary" => sub {
    my $test_name = "single item dictionary";
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

# Test 4: list item dictionary
subtest "list item dictionary" => sub {
    my $test_name = "list item dictionary";
    my $input = "a=(1 2)";
    my $expected = _h( "a" => { _type => 'inner_list', value => [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 2 }
    ] } );
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

# Test 5: single list item dictionary
subtest "single list item dictionary" => sub {
    my $test_name = "single list item dictionary";
    my $input = "a=(1)";
    my $expected = _h( "a" => { _type => 'inner_list', value => [ { _type => 'integer', value => 1 } ] } );
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

# Test 6: empty list item dictionary
subtest "empty list item dictionary" => sub {
    my $test_name = "empty list item dictionary";
    my $input = "a=()";
    my $expected = _h( "a" => { _type => 'inner_list', value => [] } );
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

# Test 7: no whitespace dictionary
subtest "no whitespace dictionary" => sub {
    my $test_name = "no whitespace dictionary";
    my $input = "a=1,b=2";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=1, b=2";
    
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

# Test 8: extra whitespace dictionary
subtest "extra whitespace dictionary" => sub {
    my $test_name = "extra whitespace dictionary";
    my $input = "a=1 ,  b=2";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=1, b=2";
    
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

# Test 9: tab separated dictionary
subtest "tab separated dictionary" => sub {
    my $test_name = "tab separated dictionary";
    my $input = "a=1\t,\tb=2";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=1, b=2";
    
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

# Test 10: leading whitespace dictionary
subtest "leading whitespace dictionary" => sub {
    my $test_name = "leading whitespace dictionary";
    my $input = "     a=1 ,  b=2";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=1, b=2";
    
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

# Test 11: whitespace before = dictionary
{
    my $test_name = 'whitespace before = dictionary - must fail';
    my $input = "a =1, b=2";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 12: whitespace after = dictionary
{
    my $test_name = 'whitespace after = dictionary - must fail';
    my $input = "a=1, b= 2";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 13: two lines dictionary
subtest "two lines dictionary" => sub {
    my $test_name = "two lines dictionary";
    my $input = "a=1,b=2";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=1, b=2";
    
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

# Test 14: missing value dictionary
subtest "missing value dictionary" => sub {
    my $test_name = "missing value dictionary";
    my $input = "a=1, b, c=3";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'boolean', value => 1 },
        "c" => { _type => 'integer', value => 3 }
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

# Test 15: all missing value dictionary
subtest "all missing value dictionary" => sub {
    my $test_name = "all missing value dictionary";
    my $input = "a, b, c";
    my $expected = _h(
        "a" => { _type => 'boolean', value => 1 },
        "b" => { _type => 'boolean', value => 1 },
        "c" => { _type => 'boolean', value => 1 }
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

# Test 16: start missing value dictionary
subtest "start missing value dictionary" => sub {
    my $test_name = "start missing value dictionary";
    my $input = "a, b=2";
    my $expected = _h(
        "a" => { _type => 'boolean', value => 1 },
        "b" => { _type => 'integer', value => 2 }
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

# Test 17: end missing value dictionary
subtest "end missing value dictionary" => sub {
    my $test_name = "end missing value dictionary";
    my $input = "a=1, b";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'boolean', value => 1 }
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

# Test 18: missing value with params dictionary
subtest "missing value with params dictionary" => sub {
    my $test_name = "missing value with params dictionary";
    my $input = "a=1, b;foo=9, c=3";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'boolean', value => 1, params => _h( "foo" => { _type => 'integer', value => 9 } ) },
        "c" => { _type => 'integer', value => 3 }
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

# Test 19: explicit true value with params dictionary
subtest "explicit true value with params dictionary" => sub {
    my $test_name = "explicit true value with params dictionary";
    my $input = "a=1, b=?1;foo=9, c=3";
    my $expected = _h(
        "a" => { _type => 'integer', value => 1 },
        "b" => { _type => 'boolean', value => 1, params => _h( "foo" => { _type => 'integer', value => 9 } ) },
        "c" => { _type => 'integer', value => 3 }
    );
    my $canonical = "a=1, b;foo=9, c=3";
    
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

# Test 20: trailing comma dictionary
{
    my $test_name = 'trailing comma dictionary - must fail';
    my $input = "a=1, b=2,";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 21: empty item dictionary
{
    my $test_name = 'empty item dictionary - must fail';
    my $input = "a=1,,b=2,";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 22: duplicate key dictionary
subtest "duplicate key dictionary" => sub {
    my $test_name = "duplicate key dictionary";
    my $input = "a=1,b=2,a=3";
    my $expected = _h(
        "a" => { _type => 'integer', value => 3 },
        "b" => { _type => 'integer', value => 2 }
    );
    my $canonical = "a=3, b=2";
    
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

# Test 23: numeric key dictionary
{
    my $test_name = 'numeric key dictionary - must fail';
    my $input = "a=1,1b=2,a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 24: uppercase key dictionary
{
    my $test_name = 'uppercase key dictionary - must fail';
    my $input = "a=1,B=2,a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

# Test 25: bad key dictionary
{
    my $test_name = 'bad key dictionary - must fail';
    my $input = "a=1,b!=2,a=1";
    
    eval { decode_dictionary($input); };
    ok($@, $test_name) or diag("Expected failure but got success");
}

