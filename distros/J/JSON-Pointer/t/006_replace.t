use strict;
use warnings;

use Test::More;
use JSON;
use JSON::Pointer;

my $json = JSON->new->allow_nonref;

sub test_replace {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $pointer, $value) = @$input{qw/document pointer value/};
        my ($patched_document, $replaced) = JSON::Pointer->replace($document, $pointer, $value);

        is_deeply(
            $patched_document,
            $expect->{document},
            sprintf(
                "replaced document (actual: %s. expect: %s)",
                $json->encode($patched_document),
                $json->encode($expect->{document}),
            )
        );
        is_deeply(
            $replaced,
            $expect->{replaced},
            sprintf(
                "replaced element (actual: %s. expect: %s)",
                $json->encode($replaced),
                $json->encode($expect->{replaced}),
            )
        );
    };
}

# https://github.com/json-patch/json-patch-tests

subtest "JSON Patch Appendix A. Example" => sub {
    test_replace "A.5 Replacing a Value" => (
        input => +{
            document => +{
                baz => "qux",
                foo => "bar",
            },
            pointer => "/baz",
            value => "boo",
        },
        expect => +{
            replaced => "qux",
            document => +{
                baz => "boo",
                foo => "bar"
            }
        },
    );
};

subtest "https://github.com/json-patch/json-patch-tests/blob/master/tests.json" => sub {
    test_replace "Toplevel scalar values OK?" => (
        input => +{
            document => "foo",
            pointer => "",
            value => "bar",
        },
        expect => +{
            replaced => "foo",
            document => "bar",
        },
    );

    test_replace "top level object field" => (
        input => +{
            document => +{ foo => 1, baz => [ +{qux => "hello" } ] },
            pointer => "/foo",
            value => [1, 2, 3, 4],
        },
        expect => +{
            replaced => 1,
            document => +{ foo => [1, 2, 3, 4], baz => [ +{qux => "hello" } ] },
        },
    );

    test_replace "nested" => (
        input => +{
            document => +{ foo => [1, 2, 3, 4], baz => [ +{qux => "hello" } ] },
            pointer => "/baz/0/qux",
            value => "world",
        },
        expect => +{
            replaced => "hello",
            document => +{ foo => [1, 2, 3, 4], baz => [ +{qux => "world" } ] },
        },
    );

    test_replace "toplevel array element (string to string)" => (
        input => +{
            document => [ "foo" ],
            pointer => "/0",
            value => "bar",
        },
        expect => +{
            replaced => "foo",
            document => ["bar"],
        },
    );

    test_replace "toplevel array element (string to integer)" => (
        input => +{
            document => [ "" ],
            pointer => "/0",
            value => 0,
        },
        expect => +{
            replaced => "",
            document => [0],
        },
    );

    test_replace "toplevel array element (string to true)" => (
        input => +{
            document => [ "" ],
            pointer => "/0",
            value => JSON::true,
        },
        expect => +{
            replaced => "",
            document => [ JSON::true ],
        },
    );

    test_replace "toplevel array element (string to false)" => (
        input => +{
            document => [ "" ],
            pointer => "/0",
            value => JSON::false,
        },
        expect => +{
            replaced => "",
            document => [ JSON::false ],
        },
    );

    test_replace "toplevel array element (string to null)" => (
        input => +{
            document => [ "" ],
            pointer => "/0",
            value => undef,
        },
        expect => +{
            replaced => "",
            document => [ undef ],
        },
    );

    test_replace "value in array replace not flattened" => (
        input => +{
            document => [ "foo", "sil" ],
            pointer => "/1",
            value => ["bar", "baz"],
        },
        expect => +{
            replaced => "sil",
            document => [ "foo", ["bar", "baz"] ],
        },
    );
};

subtest "misc" => sub {
    test_replace "Whole document (array to object)" => (
        input => +{
            document => [],
            pointer => "",
            value => +{ foo => 1 },
        },
        expect => +{
            replaced => [],
            document => +{ foo => 1, },
        },
    );

    test_replace "Whole document (object to array)" => (
        input => +{
            document => +{ foo => 1 },
            pointer => "",
            value => [ 1, 2 ],
        },
        expect => +{
            replaced => +{ foo => 1, },
            document => [1, 2],
        },
    );
};

done_testing;
