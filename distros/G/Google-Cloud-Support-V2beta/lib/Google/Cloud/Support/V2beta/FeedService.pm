package Google::Cloud::Support::V2beta::FeedService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Support::V2beta::FeedItem };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvZmVlZF9zZXJ2aWNlLnByb3RvEhtnb29n
bGUuY2xvdWQuc3VwcG9ydC52MmJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvY2xvdWQvc3VwcG9ydC92
MmJldGEvZmVlZF9pdGVtLnByb3RvIrkBCg9TaG93RmVlZFJlcXVlc3QSQAoGcGFyZW50GAEg
ASgJQijgQQL6QSIKIGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9DYXNlUgZwYXJlbnQS
HgoIb3JkZXJfYnkYAiABKAlCA+BBAVIHb3JkZXJCeRIgCglwYWdlX3NpemUYAyABKAVCA+BB
AVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgEIAEoCUID4EEBUglwYWdlVG9rZW4igAEKEFNo
b3dGZWVkUmVzcG9uc2USRAoKZmVlZF9pdGVtcxgBIAMoCzIlLmdvb2dsZS5jbG91ZC5zdXBw
b3J0LnYyYmV0YS5GZWVkSXRlbVIJZmVlZEl0ZW1zEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbjK8AgoLRmVlZFNlcnZpY2US2wEKCFNob3dGZWVkEiwuZ29vZ2xl
LmNsb3VkLnN1cHBvcnQudjJiZXRhLlNob3dGZWVkUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5z
dXBwb3J0LnYyYmV0YS5TaG93RmVlZFJlc3BvbnNlInKC0+STAmMSLC92MmJldGEve3BhcmVu
dD1wcm9qZWN0cy8qL2Nhc2VzLyp9OnNob3dGZWVkWjMSMS92MmJldGEve3BhcmVudD1vcmdh
bml6YXRpb25zLyovY2FzZXMvKn06c2hvd0ZlZWTaQQZwYXJlbnQaT8pBG2Nsb3Vkc3VwcG9y
dC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xv
dWQtcGxhdGZvcm1CzQEKH2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGFCEEZlZWRT
ZXJ2aWNlUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYyYmV0YS9z
dXBwb3J0cGI7c3VwcG9ydHBiqgIbR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjJCZXRhygIbR29v
Z2xlXENsb3VkXFN1cHBvcnRcVjJiZXRh6gIeR29vZ2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJi
ZXRhSvUTCgYSBA4AVwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgA1CggKAQgSAxgAOAoJCgIIJRIDGAA4CggKAQgSAxkAUAoJCgIICxIDGQBQCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMQoJCgIICBIDGwAxCggKAQgSAxwAOAoJCgIIARID
HAA4CggKAQgSAx0AOAoJCgIIKRIDHQA4CggKAQgSAx4ANwoJCgIILRIDHgA3CjAKAgYAEgQh
ADEBGiQgQSBzZXJ2aWNlIHRvIHZpZXcgY2FzZSBmZWVkIGl0ZW1zLgoKCgoDBgABEgMhCBMK
CgoDBgADEgMiAkMKDAoFBgADmQgSAyICQwoLCgMGAAMSBCMCJDcKDQoFBgADmggSBCMCJDcK
ZwoEBgACABIEKAIwAxpZIFNob3cgaXRlbXMgaW4gdGhlIGZlZWQgb2YgdGhpcyBjYXNlLCBp
bmNsdWRpbmcgY2FzZSBlbWFpbHMsCiBhdHRhY2htZW50cywgYW5kIGNvbW1lbnRzLgoKDAoF
BgACAAESAygGDgoMCgUGAAIAAhIDKA8eCgwKBQYAAgADEgMoKTkKDQoFBgACAAQSBCkELgYK
EQoJBgACAASwyrwiEgQpBC4GCgwKBQYAAgAEEgMvBDQKDwoIBgACAASbCAASAy8ENAo8CgIE
ABIENABMARowIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBTaG93RmVlZCBlbmRwb2lu
dC4KCgoKAwQAARIDNAgXCl8KBAQAAgASBDcCPAQaUSBSZXF1aXJlZC4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIGNhc2UgZm9yIHdoaWNoIGZlZWQgaXRlbXMgc2hvdWxkIGJlCiBsaXN0
ZWQuCgoMCgUEAAIABRIDNwIICgwKBQQAAgABEgM3CQ8KDAoFBAACAAMSAzcSEwoNCgUEAAIA
CBIENxQ8AwoPCggEAAIACJwIABIDOAQqCg8KBwQAAgAInwgSBDkEOwUKoQIKBAQAAgESA0QC
PxqTAiBPcHRpb25hbC4gRmllbGQgdG8gb3JkZXIgZmVlZCBpdGVtcyBieSwgZm9sbG93ZWQg
YnkgYGFzY2Agb3IgYGRlc2NgCiBwb3N0Zml4LiBUaGUgb25seSB2YWxpZCBmaWVsZCBpcwog
YGNyZWF0aW9uX3RpbWVgLiBUaGlzIGxpc3QgaXMgY2FzZS1pbnNlbnNpdGl2ZSwgZGVmYXVs
dCBzb3J0aW5nIG9yZGVyIGlzCiBhc2NlbmRpbmcsIGFuZCB0aGUgcmVkdW5kYW50IHNwYWNl
IGNoYXJhY3RlcnMgYXJlIGluc2lnbmlmaWNhbnQuCgogRXhhbXBsZTogYGNyZWF0aW9uX3Rp
bWUgZGVzY2AKCgwKBQQAAgEFEgNEAggKDAoFBAACAQESA0QJEQoMCgUEAAIBAxIDRBQVCgwK
BQQAAgEIEgNEFj4KDwoIBAACAQicCAASA0QXPQpUCgQEAAICEgNHAj8aRyBPcHRpb25hbC4g
VGhlIG1heGltdW0gbnVtYmVyIG9mIGZlZWQgaXRlbXMgZmV0Y2hlZCB3aXRoIGVhY2ggcmVx
dWVzdC4KCgwKBQQAAgIFEgNHAgcKDAoFBAACAgESA0cIEQoMCgUEAAICAxIDRxQVCgwKBQQA
AgIIEgNHFj4KDwoIBAACAgicCAASA0cXPQp5CgQEAAIDEgNLAkEabCBPcHRpb25hbC4gQSB0
b2tlbiBpZGVudGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYKIHVu
c3BlY2lmaWVkLCBpdCByZXRyaWV2ZXMgdGhlIGZpcnN0IHBhZ2UuCgoMCgUEAAIDBRIDSwII
CgwKBQQAAgMBEgNLCRMKDAoFBAACAwMSA0sWFwoMCgUEAAIDCBIDSxhACg8KCAQAAgMInAgA
EgNLGT8KPQoCBAESBE8AVwEaMSBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IgdGhlIFNob3dG
ZWVkIGVuZHBvaW50LgoKCgoDBAEBEgNPCBgKRQoEBAECABIDUQIjGjggVGhlIGxpc3Qgb2Yg
ZmVlZCBpdGVtcyBhc3NvY2lhdGVkIHdpdGggdGhlIGdpdmVuIENhc2UuCgoMCgUEAQIABBID
UQIKCgwKBQQBAgAGEgNRCxMKDAoFBAECAAESA1EUHgoMCgUEAQIAAxIDUSEiCsUBCgQEAQIB
EgNWAh0atwEgQSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMu
IFRoaXMgc2hvdWxkIGJlIHNldCBpbiB0aGUKIGBwYWdlX3Rva2VuYCBmaWVsZCBvZiBzdWJz
ZXF1ZW50IGBTaG93RmVlZFJlcXVlc3RzYC4KIElmIHVuc3BlY2lmaWVkLCB0aGVyZSBhcmUg
bm8gbW9yZSByZXN1bHRzIHRvIHJldHJpZXZlLgoKDAoFBAECAQUSA1YCCAoMCgUEAQIBARID
VgkYCgwKBQQBAgEDEgNWGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest ===
    # Fields for ShowFeedRequest
    # Field: parent Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse ===
    # Fields for ShowFeedResponse
    # Field: feed_items Type: 11 (.google.cloud.support.v2beta.FeedItem)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Support::V2beta::FeedService::FeedServiceClient ===
package Google::Cloud::Support::V2beta::FeedService::FeedServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2beta::FeedService::FeedServiceClient

Client stub representing the remote C<FeedService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub show_feed {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.FeedService',
        method         => 'ShowFeed',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::FeedService - Compiled Protocol Buffers messages for google/cloud/support/v2beta/feed_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::FeedService;

    my $msg = Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest->new({
        parent => $parent,
        order_by => $order_by,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/feed_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest

The request message for the ShowFeed endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the case for which feed items should be
listed.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field to order feed items by, followed by `asc` or `desc`
postfix. The only valid field is
`creation_time`. This list is case-insensitive, default sorting order is
ascending, and the redundant space characters are insignificant.

Example: `creation_time desc`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of feed items fetched with each request.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the page of results to return. If
unspecified, it retrieves the first page.

=back

=head2 Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse

The response message for the ShowFeed endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->feed_items() >> / C<< $msg->feed_items($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::FeedItem::FeedItem>)

The list of feed items associated with the given Case.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. This should be set in the
`page_token` field of subsequent `ShowFeedRequests`.
If unspecified, there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::FeedService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
