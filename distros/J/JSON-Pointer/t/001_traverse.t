use strict;
use warnings;

use Test::More;

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

sub test_traverse {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my $context = JSON::Pointer->traverse($document, $input, +{ strict => 0 });

        is($context->result, $expect->{result}, "result");
        is($context->last_token, $expect->{last_token}, "last_token");
        is($context->last_error, $expect->{last_error}, "last_error");
        is_deeply($context->parent, $expect->{parent}, "parent");
        is_deeply($context->target, $expect->{target}, "target");
    };
}

subtest "JSON Pointer Section 5 examples" => sub {
    test_traverse "the whole document" => (
        input => "",
        expect => +{
            result => 1,
            parent => $document,
            target => $document,
            last_token => undef,
            last_error => undef,
        }
    );

    test_traverse "/foo" => (
        input => "/foo",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{foo},
            last_token => "foo",
            last_error => undef,
        }
    );

    test_traverse "/foo/0" => (
        input => "/foo/0",
        expect => +{
            result => 1,
            parent => $document->{foo},
            target => $document->{foo}[0],
            last_token => "0",
            last_error => undef,
        }
    );

    test_traverse "/" => (
        input => "/",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{""},
            last_token => "",
            last_error => undef,
        }
    );

    test_traverse "/a~1b" => (
        input => "/a~1b",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"a/b"},
            last_token => "a/b",
            last_error => undef,
        }
    );

    test_traverse "/a~1b" => (
        input => "/a~1b",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"a/b"},
            last_token => "a/b",
            last_error => undef,
        }
    );

    test_traverse "/c\%d" => (
        input => "/c\%d",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"c\%d"},
            last_token => "c\%d",
            last_error => undef,
        }
    );

    test_traverse "/e^f" => (
        input => "/e^f",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"e^f"},
            last_token => "e^f",
            last_error => undef,
        }
    );

    test_traverse "/g|h" => (
        input => "/g|h",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"g|h"},
            last_token => "g|h",
            last_error => undef,
        }
    );

    test_traverse "/i\\j" => (
        input => "/i\\j",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"i\\j"},
            last_token => "i\\j",
            last_error => undef,
        }
    );

    test_traverse "/ " => (
        input => "/ ",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{" "},
            last_token => " ",
            last_error => undef,
        }
    );

    test_traverse "/m~0n" => (
        input => "/m~0n",
        expect => +{
            result => 1,
            parent => $document,
            target => $document->{"m~n"},
            last_token => "m~n",
            last_error => undef,
        }
    );
};

subtest "Exceptions" => sub {
    test_traverse "" => (
        input => "/foo/bar",
        expect => +{
            result => 0,
            parent => $document->{foo},
            target => $document->{foo},
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );

    test_traverse "/foo/bar" => (
        input => "/foo/bar",
        expect => +{
            result => 0,
            parent => $document->{foo},
            target => $document->{foo},
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );

    test_traverse "/bar/3/baz" => (
        input => "/bar/3/baz",
        expect => +{
            result => 0,
            parent => $document,
            target => $document,
            last_token => "bar",
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        }
    );
};

done_testing;
