use strict;
use warnings;

use Test::More;
use Test::Exception;

use Carp;
use JSON;
use JSON::Pointer;
use JSON::Pointer::Exception qw(:all);

my $document = decode_json(<< 'JSON');
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

sub test_get {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my $actual = JSON::Pointer->get($document, $input);
        is_deeply($actual, $expect, "target");
    };
}

sub test_get_exception {
    my ($desc, %specs) = @_;

    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        throws_ok {
            eval {
                JSON::Pointer->get($document, $input, +{ strict => 1 });
            };
            if (my $e = $@) {
                is($e->context->last_token, $expect->{last_token}, "last_token");
                is($e->context->last_error, $expect->{last_error}, "last_error");
                croak $e;
            }
        } "JSON::Pointer::Exception" => "throws_ok";
    };
}

subtest "JSON Pointer Section 5 examples" => sub {
    test_get "the whole document" => (
        input => "",
        expect => $document,
    );

    test_get "/foo" => (
        input => "/foo",
        expect => $document->{foo},
    );

    test_get "/foo/0" => (
        input => "/foo/0",
        expect => $document->{foo}[0],
    );

    test_get "/" => (
        input => "/",
        expect => $document->{""},
    );

    test_get "/a~1b" => (
        input => "/a~1b",
        expect => $document->{"a/b"},
    );

    test_get "/a~1b" => (
        input => "/a~1b",
        expect => $document->{"a/b"},
    );

    test_get "/c\%d" => (
        input => "/c\%d",
        expect => $document->{"c\%d"},
    );

    test_get "/e^f" => (
        input => "/e^f",
        expect => $document->{"e^f"},
    );

    test_get "/g|h" => (
        input => "/g|h",
        expect => $document->{"g|h"},
    );

    test_get "/i\\j" => (
        input => "/i\\j",
        expect => $document->{"i\\j"},
    );

    test_get "/ " => (
        input => "/ ",
        expect => $document->{" "},
    );

    test_get "/m~0n" => (
        input => "/m~0n",
        expect => $document->{"m~n"},
    );
};

subtest "Exceptions" => sub {
    test_get_exception "" => (
        input => "/foo/bar",
        expect => +{
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );

    test_get_exception "/foo/bar" => (
        input => "/foo/bar",
        expect => +{
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );

    test_get_exception "/bar/3/baz" => (
        input => "/bar/3/baz",
        expect => +{
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );
};

done_testing;
