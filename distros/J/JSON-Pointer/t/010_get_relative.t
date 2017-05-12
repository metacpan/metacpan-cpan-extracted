use strict;
use warnings;

use Test::More;
use Test::Exception;

use Carp;
use JSON;
use JSON::Pointer;
use JSON::Pointer::Exception qw(:all);

my $document = decode_json(<< "JSON");
{
    "foo": ["bar", "baz"],
    "highly": {
        "nested": {
            "objects": true
        }
    }
}
JSON

sub test_get_relative {
    my ($desc, %specs) = @_;

    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my $actual = JSON::Pointer->get_relative($document, @$input);
        is_deeply($actual, $expect, "target");
    };
}

sub test_get_relative_exception {
    my ($desc, %specs) = @_;

    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        throws_ok {
            eval {
                JSON::Pointer->get_relative($document, @$input, +{ strict => 1 });
            };
            if (my $e = $@) {
                is($e->context->last_token, $expect->{last_token}, "last_token");
                is($e->context->last_error, $expect->{last_error}, "last_error");
                croak $e;
            }
        } "JSON::Pointer::Exception" => "throws_ok";
    };
}

subtest "Reletive JSON Pointer examples in 5.1" => sub {
    subtest "current pointer is /foo/1" => sub {
        my $current_pointer = "/foo/1";
        
        test_get_relative "0" => (
            input => [ $current_pointer, "0" ],
            expect => "baz",
        );

        test_get_relative "1/0" => (
            input => [ $current_pointer, "1/0" ],
            expect => "bar",
        );

        test_get_relative "2/highly/nested/objects" => (
            input => [ $current_pointer, "2/highly/nested/objects" ],
            expect => JSON::true,
        );

        test_get_relative "0#" => (
            input => [ $current_pointer, "0#" ],
            expect => 1,
        );

        test_get_relative "1#" => (
            input => [ $current_pointer, "1#" ],
            expect => "foo",
        );
    };

    subtest "current pointer is /highly/nested" => sub {
        my $current_pointer = "/highly/nested";
        
        test_get_relative "0/objects" => (
            input => [ $current_pointer, "0/objects" ],
            expect => JSON::true,
        );

        test_get_relative "1/nested/objects" => (
            input => [ $current_pointer, "1/nested/objects" ],
            expect => JSON::true,
        );

        test_get_relative "2/foo/0" => (
            input => [ $current_pointer, "2/foo/0" ],
            expect => "bar",
        );

        test_get_relative "0#" => (
            input => [ $current_pointer, "0#" ],
            expect => "nested",
        );

        test_get_relative "1#" => (
            input => [ $current_pointer, "1#" ],
            expect => "highly",
        );
    };
};

subtest "Exceptions" => sub {
    test_get_relative_exception "Invalid relative json pointer" => (
        input => ["/foo/1", "/invalid"],
        expect => +{
            last_token => undef,
            last_error => ERROR_INVALID_POINTER_SYNTAX,
        },
    );

    test_get_relative_exception "Relative json pointer specified non reference value" => (
        input => ["/foo/1", "3"],
        expect => +{
            last_token => undef,
            last_error => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
        },
    );
};

done_testing;
