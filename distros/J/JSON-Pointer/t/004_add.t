use strict;
use warnings;

use Test::More;
use Test::Exception;

use Carp;
use JSON;
use JSON::Pointer;
use JSON::Pointer::Exception qw(:all);

sub test_add {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $pointer, $value) = @$input{qw/document pointer value/};
        my $patched_document = JSON::Pointer->add($document, $pointer, $value);
        is_deeply(
            $patched_document,
            $expect->{patched},
            sprintf(
                "added document (actual: %s. expected: %s)",
                encode_json($patched_document),
                encode_json($expect->{patched})
            )
        );
    };
}

sub test_add_exception {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $pointer, $value) = @$input{qw/document pointer value/};
        throws_ok {
            eval {
                my $patched_document = JSON::Pointer->add($document, $pointer, $value);
            };
            if (my $e = $@) {
                is($e->code, ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE, "code");
                croak $e;
            }
        } "JSON::Pointer::Exception" => "throws_ok";
    };
}

# https://github.com/json-patch/json-patch-tests

subtest "JSON Patch Section 4.1" => sub {
    test_add "add with existing object field" => (
        input => +{
            document => +{ a => +{ foo => 1 } }, 
            pointer  => "/a/b", 
            value    => "qux"
        },
        expect => +{
            patched => +{ 
                a => +{ foo => 1, b => "qux" }
            }
        }
    );

    test_add_exception "add with missing object" => (
        input => +{
            document => +{ q => +{ bar => 2 } },
            pointer  => "/a/b",
            value    => "qux",
        },
        expect => +{
            code => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE
        },
    );
};

subtest "JSON Patch Appendix A. Example" => sub {
    test_add "A1. Adding an Object Member" => (
        input => +{
            document => { foo => "bar" }, 
            pointer  => "/baz", 
            value    => "qux"
        },
        expect => +{
            patched => +{ 
                foo => "bar", baz => "qux",
            }
        }
    );

    test_add "A2. Adding an Array Element" => (
        input => +{
            document => { foo => ["bar", "baz"] }, 
            pointer  => "/foo/1", 
            value    => "qux"
        },
        expect => +{
            patched => +{ 
                foo => ["bar", "qux", "baz"]
            }
        }
    );

    test_add "A.10. Adding a nested Member Object" => (
        input => +{
            document => +{ foo => "bar" }, 
            pointer  => "/child", 
            value    => +{ grandchild => +{} },
        },
        expect => +{
            patched => +{ 
                foo => "bar",
                child => +{
                    grandchild => +{}
                },
            }
        }
    );

    test_add_exception "A.11. Ignoring Unrecognized Elements" => (
        input => +{
            document => +{ foo => "bar" }, 
            pointer  => "/baz/bat", 
            value    => "qux",
        },
        expect => +{
            code => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );

    test_add "A.16. Adding an Array Value" => (
        input => +{
            document => +{ foo => ["bar"] }, 
            pointer  => "/foo/-", 
            value    => ["abc", "def"],
        },
        expect => +{
            patched => +{ 
                foo => [ "bar", ["abc", "def", ], ],
            }
        }
    );
};

subtest "https://github.com/json-patch/json-patch-tests/blob/master/tests.json" => sub {
    test_add "add replaces any existing field" => (
        input => +{
            document => { foo => undef }, 
            pointer  => "/foo", 
            value    => 1
        },
        expect => +{
            patched => +{ 
                foo => 1
            }
        }
    );

    test_add "toplevel array" => (
        input => +{
            document => [], 
            pointer  => "/0", 
            value    => "foo",
        },
        expect => +{
            rv      => 1,
            patched => ["foo"]
        }
    );

    test_add "toplevel object, numeric string" => (
        input => +{
            document => +{}, 
            pointer  => "/foo", 
            value    => "1",
        },
        expect => +{
            patched => +{ foo => "1" },
        }
    );

    test_add "toplevel object, numeric string" => (
        input => +{
            document => +{}, 
            pointer  => "/foo", 
            value    => 1,
        },
        expect => +{
            patched => +{ foo => 1 },
        }
    );

    test_add "Add, / target" => (
        input => +{
            document => +{}, 
            pointer  => "/", 
            value    => 1,
        },
        expect => +{
            patched => +{ "" => 1, },
        }
    );

    test_add "Add composite value at top level" => (
        input => +{
            document => +{ foo => 1, }, 
            pointer  => "/bar", 
            value    => [1, 2],
        },
        expect => +{
            patched => +{ foo => 1, bar => [1, 2], },
        }
    );

    test_add "Add into composite value" => (
        input => +{
            document => +{ 
                foo => 1, 
                baz => [ +{ qux => "hello", } ],
            },
            pointer  => "/baz/0/foo", 
            value    => "world",
        },
        expect => +{
            patched => +{ 
                foo => 1, 
                baz => [ +{ foo => "world", qux => "hello", }, ],
            },
        }
    );

    test_add_exception "Out of bounds (upper)" => (
        input => +{
            document => +{ 
                bar => [1, 2,],
            },
            pointer  => "/bar/8", 
            value    => "5",
        },
        expect => +{
            code => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        },
    );

    test_add_exception "Out of bounds (lower)" => (
        input => +{
            document => +{ 
                bar => [1, 2,],
            },
            pointer  => "/bar/-1", 
            value    => "5",
        },
        expect => +{
            code => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        },
    );

    test_add "Add boolean value (true) at toplevel object" => (
        input => +{
            document => +{ 
                foo => 1, 
            },
            pointer  => "/bar", 
            value    => JSON::true,
        },
        expect => +{
            patched => +{ 
                foo => 1, 
                bar => JSON::true,
            },
        }
    );

    test_add "Add boolean value (false) at toplevel object" => (
        input => +{
            document => +{ 
                foo => 1, 
            },
            pointer  => "/bar", 
            value    => JSON::false,
        },
        expect => +{
            patched => +{ 
                foo => 1, 
                bar => JSON::false,
            },
        }
    );

    test_add "Add null value at toplevel object" => (
        input => +{
            document => +{ 
                foo => 1, 
            },
            pointer  => "/bar", 
            value    => undef,
        },
        expect => +{
            patched => +{ 
                foo => 1, 
                bar => undef,
            },
        }
    );

    test_add "0 can be an array index or object element name" => (
        input => +{
            document => +{ 
                foo => 1, 
            },
            pointer  => "/0", 
            value    => "bar",
        },
        expect => +{
            patched => +{ 
                foo => 1, 
                0   => "bar",
            },
        }
    );

    test_add "Add string value into toplevel array" => (
        input => +{
            document => [ "foo", ],
            pointer  => "/1", 
            value    => "bar",
        },
        expect => +{
            patched => [ "foo", "bar", ],
        }
    );

    test_add "Add string value into existing element of toplevel array" => (
        input => +{
            document => [ "foo", "sil", ],
            pointer  => "/1", 
            value    => "bar",
        },
        expect => +{
            patched => [ "foo", "bar", "sil", ],
        }
    );

    test_add "Add string value into first element of toplevel array" => (
        input => +{
            document => [ "foo", "sil", ],
            pointer  => "/0", 
            value    => "bar",
        },
        expect => +{
            patched => [ "bar", "foo", "sil", ],
        }
    );

    test_add "Add string value into next last element of toplevel array" => (
        input => +{
            document => [ "foo", "sil", ],
            pointer  => "/2", 
            value    => "bar",
        },
        expect => +{
            patched => [ "foo", "sil", "bar", ],
        }
    );

    test_add_exception "Object operation on array target" => (
        input => +{
            document => ["foo", "sil", ],
            pointer  => "/bar", 
            value    => 42,
        },
        expect => +{
            code => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        },
    );

    test_add "value in array add not flattened" => (
        input => +{
            document => ["foo", "sil", ],
            pointer  => "/1", 
            value    => ["bar", "baz", ],
        },
        expect => +{
            patched => [ "foo", ["bar", "baz", ], "sil", ],
        },
    );

    test_add "replacing the root of the document is possible with add" => (
        input => +{
            document => +{ foo => "bar", },
            pointer  => "", 
            value    => +{ baz => "qux", },
        },
        expect => +{
            patched => +{ baz => "qux", },
        },
    );
};

done_testing;
