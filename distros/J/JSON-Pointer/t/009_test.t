use strict;
use warnings;

use Test::More;
use JSON;
use JSON::Pointer;

my $json = JSON->new->allow_nonref;

sub test_test {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $pointer, $value) = @$input{qw/document pointer value/};
        my $actual = JSON::Pointer->test($document, $pointer, $value);
        is(
            $actual, $expect, 
            sprintf(
                "test (document: %s. pointer: %s. value: %s)", 
                $json->encode($document), 
                $pointer, 
                $json->encode($value)
            )
        );
    };
}

subtest "JSON Patch Appendix A. Example" => sub {
    test_test "A.8. Testing a Value: Success (/0)" => (
        input => +{
            document => +{
                baz => "qux",
                foo => ["a", 2, "c"]
            },
            pointer => "/baz",
            value => "qux"
        },
        expect => 1,
    );

    test_test "A.8. Testing a Value: Success (/1)" => (
        input => +{
            document => +{
                baz => "qux",
                foo => ["a", 2, "c"]
            },
            pointer => "/foo/1",
            value   => 2,
        },
        expect => 1,
    );

    test_test "A.8. Testing a Value: Error" => (
        input => +{
            document => +{
                baz => "qux",
            },
            pointer => "/baz",
            value   => "bar",
        },
        expect => 0,
    );

    test_test "A.14. ~ Escape Ordering" => (
        input => +{
            document => +{
                "/" => 9,
                "~1" => 10,
            },
            pointer => "/~01",
            value   => 10,
        },
        expect => 1,
    );

    test_test "A.15. Comparing Strings and Numbers" => (
        input => +{
            document => +{
                "/" => 9,
                "~1" => 10,
            },
            pointer => "/~01",
            value   => "10",
        },
        expect => 0,
    );
};

subtest "https://github.com/json-patch/json-patch-tests/blob/master/tests.json" => sub {
    test_test "test against implementation-specific numeric parsing" => (
        input => +{
            document => +{ le0 => "foo", },
            pointer => "/le0",
            value => "foo",
        },
        expect => 1,
    );

    test_test "test with bad number should fail" => (
        input => +{
            document => [ "foo", "bar", ],
            pointer => "/le0",
            value => "bar",
        },
        expect => 0,
    );

    test_test "null value should still be valid obj property" => (
        input => +{
            document => +{ foo => undef },
            pointer => "/foo",
            value => undef,
        },
        expect => 1,
    );

    test_test "test should pass - no error" => (
        input => +{
            document => +{ foo => +{ bar => [ 1, 2, 5, 4 ] }, },
            pointer => "/foo",
            value => +{
                bar => [ 1, 2, 5, 4 ]
            },
        },
        expect => 1,
    );

    test_test "test op should fail" => (
        input => +{
            document => +{ foo => +{ bar => [ 1, 2, 5, 4 ] }, },
            pointer => "/foo",
            value => +{
                bar => [ 1, 2 ]
            },
        },
        expect => 0,
    );

    test_test "Whole document" => (
        input => +{
            document => +{ foo => 1, },
            pointer => "",
            value => +{
                foo => 1,
            },
        },
        expect => 1,
    );

    test_test "Empty-string element" => (
        input => +{
            document => +{ "" => 1, },
            pointer => "/",
            value => 1,
        },
        expect => 1,
    );

    my $spec_document = decode_json(<< 'JSON');
{
    "foo": ["bar", "baz"],
    "": 0,
    "a/b": 1,
    "c%d": 2,
    "e^f": 3,
    "g|h": 4,
    "i\\j": 5,
    "k\"l": 6,
    " ": 7,
    "m~n": 8
}
JSON

    my @spec_cases = (
        +{ pointer => "/foo", value => [ "bar", "baz", ] },
        +{ pointer => "/foo/0", value => "bar" },
        +{ pointer => "/", value => 0, },
        +{ pointer => "/a~1b", value => 1, },
        +{ pointer => "/c\%d", value => 2, },
        +{ pointer => "/e^f", value => 3, },
        +{ pointer => "/g|h", value => 4, },
        +{ pointer => "/i\\j", value => 5, },
        +{ pointer => "/k\"l", value => 6, },
        +{ pointer => "/ ", value => 7, },
        +{ pointer => "/m~0n", value => 8, },
    );

    for my $spec_case (@spec_cases) {
        test_test sprintf("The value at %s equals %s", $spec_case->{pointer}, $json->encode($spec_case->{value})) => (
            input => +{
                document => $spec_document,
                pointer => $spec_case->{pointer},
                value => $spec_case->{value},
            },
            expect => 1,
        );
    }
};

done_testing;
