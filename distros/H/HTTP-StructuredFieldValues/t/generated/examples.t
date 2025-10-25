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

# Generated from examples.json
# Total tests: 21

plan tests => 21;

# Test 1: Foo-Example
subtest "Foo-Example" => sub {
    my $test_name = "Foo-Example";
    my $input = "2; foourl=\"https://foo.example.com/\"";
    my $expected = { _type => 'integer', value => 2, params => _h( "foourl" => { _type => 'string', value => "https://foo.example.com/" } ) };
    my $canonical = "2;foourl=\"https://foo.example.com/\"";
    
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

# Test 2: Example-StrListHeader
subtest "Example-StrListHeader" => sub {
    my $test_name = "Example-StrListHeader";
    my $input = "\"foo\", \"bar\", \"It was the best of times.\"";
    my $expected = [
        { _type => 'string', value => "foo" },
        { _type => 'string', value => "bar" },
        { _type => 'string', value => "It was the best of times." }
    ];
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

# Test 3: Example-Hdr (list on one line)
subtest "Example-Hdr (list on one line)" => sub {
    my $test_name = "Example-Hdr (list on one line)";
    my $input = "foo, bar";
    my $expected = [
        { _type => 'token', value => "foo" },
        { _type => 'token', value => "bar" }
    ];
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

# Test 4: Example-Hdr (list on two lines)
subtest "Example-Hdr (list on two lines)" => sub {
    my $test_name = "Example-Hdr (list on two lines)";
    my $input = "foo,bar";
    my $expected = [
        { _type => 'token', value => "foo" },
        { _type => 'token', value => "bar" }
    ];
    my $canonical = "foo, bar";
    
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

# Test 5: Example-StrListListHeader
subtest "Example-StrListListHeader" => sub {
    my $test_name = "Example-StrListListHeader";
    my $input = "(\"foo\" \"bar\"), (\"baz\"), (\"bat\" \"one\"), ()";
    my $expected = [
        { _type => 'inner_list', value => [
        { _type => 'string', value => "foo" },
        { _type => 'string', value => "bar" }
    ] },
        { _type => 'inner_list', value => [ { _type => 'string', value => "baz" } ] },
        { _type => 'inner_list', value => [
        { _type => 'string', value => "bat" },
        { _type => 'string', value => "one" }
    ] },
        { _type => 'inner_list', value => [] }
    ];
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

# Test 6: Example-ListListParam
subtest "Example-ListListParam" => sub {
    my $test_name = "Example-ListListParam";
    my $input = "(\"foo\"; a=1;b=2);lvl=5, (\"bar\" \"baz\");lvl=1";
    my $expected = [
        { _type => 'inner_list', value => [ { _type => 'string', value => "foo", params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 } ) } ], params => _h( "lvl" => { _type => 'integer', value => 5 } ) },
        { _type => 'inner_list', value => [
        { _type => 'string', value => "bar" },
        { _type => 'string', value => "baz" }
    ], params => _h( "lvl" => { _type => 'integer', value => 1 } ) }
    ];
    my $canonical = "(\"foo\";a=1;b=2);lvl=5, (\"bar\" \"baz\");lvl=1";
    
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

# Test 7: Example-ParamListHeader
subtest "Example-ParamListHeader" => sub {
    my $test_name = "Example-ParamListHeader";
    my $input = "abc;a=1;b=2; cde_456, (ghi;jk=4 l);q=\"9\";r=w";
    my $expected = [
        { _type => 'token', value => "abc", params => _h( "a" => { _type => 'integer', value => 1 }, "b" => { _type => 'integer', value => 2 }, "cde_456" => { _type => 'boolean', value => 1 } ) },
        { _type => 'inner_list', value => [
        { _type => 'token', value => "ghi", params => _h( "jk" => { _type => 'integer', value => 4 } ) },
        { _type => 'token', value => "l" }
    ], params => _h( "q" => { _type => 'string', value => "9" }, "r" => { _type => 'token', value => "w" } ) }
    ];
    my $canonical = "abc;a=1;b=2;cde_456, (ghi;jk=4 l);q=\"9\";r=w";
    
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

# Test 8: Example-IntHeader
subtest "Example-IntHeader" => sub {
    my $test_name = "Example-IntHeader";
    my $input = "1; a; b=?0";
    my $expected = { _type => 'integer', value => 1, params => _h( "a" => { _type => 'boolean', value => 1 }, "b" => { _type => 'boolean', value => 0 } ) };
    my $canonical = "1;a;b=?0";
    
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

# Test 9: Example-DictHeader
subtest "Example-DictHeader" => sub {
    my $test_name = "Example-DictHeader";
    my $input = "en=\"Applepie\", da=:w4ZibGV0w6ZydGU=:";
    my $expected = _h(
        "en" => { _type => 'string', value => "Applepie" },
        "da" => { _type => 'binary', value => decode_base32('YODGE3DFOTB2M4TUMU') }
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

# Test 10: Example-DictHeader (boolean values)
subtest "Example-DictHeader (boolean values)" => sub {
    my $test_name = "Example-DictHeader (boolean values)";
    my $input = "a=?0, b, c; foo=bar";
    my $expected = _h(
        "a" => { _type => 'boolean', value => 0 },
        "b" => { _type => 'boolean', value => 1 },
        "c" => { _type => 'boolean', value => 1, params => _h( "foo" => { _type => 'token', value => "bar" } ) }
    );
    my $canonical = "a=?0, b, c;foo=bar";
    
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

# Test 11: Example-DictListHeader
subtest "Example-DictListHeader" => sub {
    my $test_name = "Example-DictListHeader";
    my $input = "rating=1.5, feelings=(joy sadness)";
    my $expected = _h(
        "rating" => { _type => 'decimal', value => 1.5 },
        "feelings" => { _type => 'inner_list', value => [
        { _type => 'token', value => "joy" },
        { _type => 'token', value => "sadness" }
    ] }
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

# Test 12: Example-MixDict
subtest "Example-MixDict" => sub {
    my $test_name = "Example-MixDict";
    my $input = "a=(1 2), b=3, c=4;aa=bb, d=(5 6);valid";
    my $expected = _h(
        "a" => { _type => 'inner_list', value => [
        { _type => 'integer', value => 1 },
        { _type => 'integer', value => 2 }
    ] },
        "b" => { _type => 'integer', value => 3 },
        "c" => { _type => 'integer', value => 4, params => _h( "aa" => { _type => 'token', value => "bb" } ) },
        "d" => { _type => 'inner_list', value => [
        { _type => 'integer', value => 5 },
        { _type => 'integer', value => 6 }
    ], params => _h( "valid" => { _type => 'boolean', value => 1 } ) }
    );
    my $canonical = "a=(1 2), b=3, c=4;aa=bb, d=(5 6);valid";
    
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

# Test 13: Example-Hdr (dictionary on one line)
subtest "Example-Hdr (dictionary on one line)" => sub {
    my $test_name = "Example-Hdr (dictionary on one line)";
    my $input = "foo=1, bar=2";
    my $expected = _h(
        "foo" => { _type => 'integer', value => 1 },
        "bar" => { _type => 'integer', value => 2 }
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

# Test 14: Example-Hdr (dictionary on two lines)
subtest "Example-Hdr (dictionary on two lines)" => sub {
    my $test_name = "Example-Hdr (dictionary on two lines)";
    my $input = "foo=1,bar=2";
    my $expected = _h(
        "foo" => { _type => 'integer', value => 1 },
        "bar" => { _type => 'integer', value => 2 }
    );
    my $canonical = "foo=1, bar=2";
    
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

# Test 15: Example-IntItemHeader
subtest "Example-IntItemHeader" => sub {
    my $test_name = "Example-IntItemHeader";
    my $input = "5";
    my $expected = { _type => 'integer', value => 5 };
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

# Test 16: Example-IntItemHeader (params)
subtest "Example-IntItemHeader (params)" => sub {
    my $test_name = "Example-IntItemHeader (params)";
    my $input = "5; foo=bar";
    my $expected = { _type => 'integer', value => 5, params => _h( "foo" => { _type => 'token', value => "bar" } ) };
    my $canonical = "5;foo=bar";
    
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

# Test 17: Example-IntegerHeader
subtest "Example-IntegerHeader" => sub {
    my $test_name = "Example-IntegerHeader";
    my $input = "42";
    my $expected = { _type => 'integer', value => 42 };
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

# Test 18: Example-FloatHeader
subtest "Example-FloatHeader" => sub {
    my $test_name = "Example-FloatHeader";
    my $input = "4.5";
    my $expected = { _type => 'decimal', value => 4.5 };
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

# Test 19: Example-StringHeader
subtest "Example-StringHeader" => sub {
    my $test_name = "Example-StringHeader";
    my $input = "\"hello world\"";
    my $expected = { _type => 'string', value => "hello world" };
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

# Test 20: Example-BinaryHdr
subtest "Example-BinaryHdr" => sub {
    my $test_name = "Example-BinaryHdr";
    my $input = ":cHJldGVuZCB0aGlzIGlzIGJpbmFyeSBjb250ZW50Lg==:";
    my $expected = { _type => 'binary', value => decode_base32('OBZGK5DFNZSCA5DINFZSA2LTEBRGS3TBOJ4SAY3PNZ2GK3TUFY') };
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

# Test 21: Example-BoolHdr
subtest "Example-BoolHdr" => sub {
    my $test_name = "Example-BoolHdr";
    my $input = "?1";
    my $expected = { _type => 'boolean', value => 1 };
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

