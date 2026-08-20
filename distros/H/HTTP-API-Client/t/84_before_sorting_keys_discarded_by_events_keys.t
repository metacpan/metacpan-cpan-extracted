=head1 NAME

84_before_sorting_keys_discarded_by_events_keys.t - HAC-112: this module's
own POD documents that a before_sorting_keys mutation is discarded when
events->{keys} also overrides the key list ("$events->{keys} isn't also
set (which replaces @keys outright, discarding before_sorting_keys'
mutation)"), but no test combined the two to verify it -
t/33_before_sorting_keys_mutation.t exercises before_sorting_keys alone,
and events->{keys} is exercised alone elsewhere. Verified live before this
test existed: the documented discard behavior was already correct.

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
            push @{ $o{keys} }, "injected";
        },
        keys => sub { return ( "a", "b" ) },
    } );

    is $req->uri, "http://example.com?a=1&b=2",
        "a before_sorting_keys mutation is discarded once events->{keys} independently overrides the list";
}

done_testing;
