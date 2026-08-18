=head1 NAME

33_before_sorting_keys_mutation.t - HAC-037: before_sorting_keys' keys
arrayref was always empty on entry, and any mutation a callback made to
it was silently discarded a moment later when @keys got unconditionally
reassigned from keys %$data. Unlike after_sorting_keys, whose keys
mutations are genuinely live, before_sorting_keys was functionally
inert for this purpose.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { a => 1, b => 2 }, {}, {
        test_request_object => 1,
        before_sorting_keys => sub {
            my ( $self, %o ) = @_;
            @{ $o{keys} } = grep { $_ ne "b" } @{ $o{keys} };
        },
    } );

    is $req->uri, "http://example.com?a=1",
        "removing a key from before_sorting_keys' keys arrayref excludes it from the output";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { a => 1, b => 2 }, {}, {
        test_request_object => 1,
        before_sorting_keys => sub {
            my ( $self, %o ) = @_;
            is_deeply [ sort @{ $o{keys} } ], [ "a", "b" ],
                "before_sorting_keys sees the actual (unsorted) keys of %data, not an empty list";
        },
    } );

    is $req->uri, "http://example.com?a=1&b=2", "unmutated keys still produce normal sorted output";
}

done_testing;
