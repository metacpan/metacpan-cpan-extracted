use strict;
use warnings;

use Test::More;
use JSON;
use JSON::Pointer;

my $json = JSON->new->allow_nonref;

sub test_move {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $from_pointer, $to_pointer) = @$input{qw/document from path/};
        my $patched_document = JSON::Pointer->move($document, $from_pointer, $to_pointer);
        is_deeply(
            $patched_document,
            $expect->{patched},
            sprintf(
                "copied document (actual: %s. expected: %s)",
                $json->encode($patched_document),
                $json->encode($expect->{patched}),
            )
        );
    };
}

subtest "JSON Patch Appendix A. Example" => sub {
    test_move "A.6.  Moving a Value" => (
        input => +{
            document => +{
                "foo" => +{
                    "bar" => "baz",
                    "waldo" => "fred",
                },
                "qux" => +{
                    "corge" => "grault"
                }
            },
            from => "/foo/waldo",
            path => "/qux/thud",
        },
        expect => +{
            patched => +{
                "foo" => +{
                    "bar" => "baz",
                },
                "qux" => +{
                    "corge" => "grault",
                    "thud" => "fred",
                }
            },
        },
    );

    test_move "A.6.  Moving a Value" => (
        input => +{
            document => +{
                "foo" => [
                    "all", "grass", "cows", "eat"
                ],
            },
            from => "/foo/1",
            path => "/foo/3",
        },
        expect => +{
            patched => +{
                "foo" => ["all", "cows", "eat", "grass"],
            },
        },
    );
};

subtest "https://github.com/json-patch/json-patch-tests/blob/master/tests.json" => sub {
    test_move "Move to same location has no effect" => (
        input => +{
            document => +{
                foo => 1,
            },
            from => "/foo",
            path => "/foo",
        },
        expect => +{
            patched => +{
                foo => 1,
            },
        },
    );

    test_move "Move to new object field" => (
        input => +{
            document => +{
                foo => 1,
                baz => [ +{ qux => "hello", } ],
            },
            from => "/foo",
            path => "/bar",
        },
        expect => +{
            patched => +{
                bar => 1,
                baz => [ +{ qux => "hello", } ],
            },
        },
    );

    test_move "Move to new array element" => (
        input => +{
            document => +{
                bar => 1,
                baz => [ +{ qux => "hello", } ],
            },
            from => "/baz/0/qux",
            path => "/baz/1",
        },
        expect => +{
            patched => +{
                bar => 1,
                baz => [ +{}, "hello", ],
            },
        },
    );
};

done_testing;
