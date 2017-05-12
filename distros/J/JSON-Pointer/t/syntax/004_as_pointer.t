#!perl -w
use strict;
use Test::More;
use JSON::Pointer::Syntax;

sub test_as_pointer {
    my ($tokens, $expect, $desc) = @_;
    subtest $desc => sub {
        my $actual = JSON::Pointer::Syntax->as_pointer($tokens);
        is($actual, $expect, "arrayref");
        $actual = JSON::Pointer::Syntax->as_pointer(@$tokens);
        is($actual, $expect, "array");
    }
}

subtest "JSON Pointer Section 5 examples" => sub {
    test_as_pointer([], '', q{""});
    test_as_pointer(['foo'], '/foo', q{"/foo"});
    test_as_pointer(['foo', 0], '/foo/0', q{"/foo/0"});
    test_as_pointer([''], '/', q{"/"});
    test_as_pointer(['a/b'], '/a~1b', q{"/a~1b"});
    test_as_pointer(['c%d'], '/c%d', q{"/c%d"});
    test_as_pointer(['e^f'], '/e^f', q{"/e^f"});
    test_as_pointer(['g|h'], '/g|h', q{"/g|h"});
    test_as_pointer(['i\\j'], '/i\\j', q{"/i\\j"});
    test_as_pointer(['k"l'], '/k"l', q{"/k\"l"});
    test_as_pointer([' '], '/ ', q{"/ "});
    test_as_pointer(['m~n'], '/m~0n', q{"/m~0n"});
};

done_testing;
