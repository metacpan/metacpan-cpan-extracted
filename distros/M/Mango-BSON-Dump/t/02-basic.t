
use Test::More;

use Mango::BSON ':bson';
use Mango::BSON::Dump;

use JSON::XS 3.0;

my $encoder = JSON::XS->new->convert_blessed(1)->canonical(1);

my @TESTS = (

    # First, one test for each data type
    {    # bin / generic
        doc => bson_doc( f => bson_bin("\N{U+A9}") ),
        extjson => '{"f":{"$binary":"qQ==","$type":"00"}}',
        test    => 'bson_bin("(c)")',
    },
    {    # code
        doc => bson_doc( f => bson_code("function () {}") ),
        extjson => '{"f":{"$code":"function () {}"}}',
        test    => 'bson_code("function () {}")',
    },
    {    # code with scope
        doc => bson_doc( f => bson_code("function () {}")->scope( {} ) ),
        extjson => '{"f":{"$code":"function () {}","$scope":{}}}',
        test    => 'bson_code("function () {}")->scope({})',
    },
    {    # double
        doc     => bson_doc( f => bson_double(3.14) ),
        extjson => '{"f":3.14}',
        test    => 'bson_double(3.14)',
    },
    {    # int32
        doc     => bson_doc( f => bson_int32(42) ),
        extjson => '{"f":42}',
        test    => 'bson_int32(42)',
    },
    {    # int64
        doc     => bson_doc( f => bson_int64(42) ),
        extjson => '{"f":{"$numberLong":"42"}}',
        test    => 'bson_int64(42)',
    },
    {    # maxkey
        doc     => bson_doc( f => bson_max() ),
        extjson => '{"f":{"$maxKey":1}}',
        test    => 'bson_max()',
    },
    {    # minkey
        doc     => bson_doc( f => bson_min() ),
        extjson => '{"f":{"$minKey":1}}',
        test    => 'bson_min()',
    },
    {    # oid
        doc => bson_doc( f => bson_oid('000000000000000000000000') ),
        extjson => '{"f":{"$oid":"000000000000000000000000"}}',
        test    => 'bson_oid("000000000000000000000000")',
    },
    {    # date
        doc     => bson_doc( f => bson_time(0) ),
        extjson => '{"f":{"$date":"1970-01-01T00:00:00Z"}}', # XXX .000Z
        test    => 'bson_time(0)',
    },
    {    # timestamp
        doc     => bson_doc( f => bson_ts( 0, 0 ) ),
        extjson => '{"f":{"$timestamp":{"i":0,"t":0}}}',
        test    => 'bson_ts(0, 0)',
    },
    {    # dbref
        doc => bson_doc(
            f => bson_dbref( 'test', bson_oid('000000000000000000000000') )
        ),
        extjson =>
          '{"f":{"$ref":"test","$id":{"$oid":"000000000000000000000000"}}}',
        test => 'bson_dbref("test",bson_oid("000000000000000000000000"))',
    },
    {    # true
        doc     => bson_doc( f => bson_true ),
        extjson => '{"f":true}',
        test    => 'bson_true()',
    },
    {    # false
        doc     => bson_doc( f => bson_false ),
        extjson => '{"f":false}',
        test    => 'bson_false()',
    },
    {    # regex
        doc     => bson_doc( f => qr/abc/ ),
        extjson => '{"f":{"$options":"","$regex":"abc"}}',
        test    => 'regex qr/abc/',
    },

    # regex

    # Second, more test cases for each type
);
plan tests => scalar @TESTS;

for my $t (@TESTS) {
    my $input    = $t->{doc};
    my $expected = $t->{extjson};
    my $test     = $t->{test};

    my $output = $encoder->encode($input);
    is( $output, $expected, $test );
}

done_testing;

