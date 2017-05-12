use strict;
use warnings;

use Test::More;
use JSON;
use JSON::Pointer;

my $json = JSON->new->allow_nonref;

sub test_copy {
    my ($desc, %specs) = @_;
    my ($input, $expect) = @specs{qw/input expect/};

    subtest $desc => sub {
        my ($document, $from_pointer, $to_pointer) = @$input{qw/document from path/};
        my $patched_document = JSON::Pointer->copy($document, $from_pointer, $to_pointer);
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

subtest "https://github.com/json-patch/json-patch-tests/blob/master/tests.json" => sub {
    test_copy "copy to new object field" => (
        input => +{
            document => +{
                baz => [ +{ qux => "hello" } ],
                bar => 1,
            },
            from => "/baz/0",
            path => "/boo",
        },
        expect => +{
            patched => +{
                baz => [ +{ qux => "hello" } ],
                bar => 1,
                boo => +{ qux => "hello" },
            },
        },
    );
};

done_testing;
