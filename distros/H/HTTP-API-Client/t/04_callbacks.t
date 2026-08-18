=head1 NAME

04_callbacks.t - the event system computes header values (an API key and a
signature) from request data at build time, via CODE values inside the
raw %headers hash (resolved by _execute_callbacks before the request is
built) - not the before_headers event, which is covered separately in
t/21_before_events.t

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

my $capture_url;

my $request = $api->get("https://google.com", {
    api_key    => '[1234]',
    api_secret => sub {'[4567]'},
    foobar     => sub {
        my ($self, %o) = @_;
        $self->kvp2str(%o, skip_key => { foobar => 1 });
    },
}, {
    APIKEY => sub {
        my (undef, %o) = @_;
        return $o{data}{api_key};
    },
    Signature => sub {
        my (undef, %o) = @_;
        return "$o{data}{api_key}$o{data}{api_secret}";
    },
}, {
    test_request_object => 1,
    after_header_keys => sub {
        my ($self, %o) = @_;
        $capture_url = "${$o{url}}?${$o{content}}";
    },
});

like $request->as_string, qr/APIKEY: \[1234\]/, "Adding api key to the request header";
like $request->as_string, qr/Signature: \[1234\]\[4567\]/, "Adding signature to the request header";
is $request->content, '', 'Get Request has no content';
is $request->uri, $capture_url, "content on the url";

done_testing;
