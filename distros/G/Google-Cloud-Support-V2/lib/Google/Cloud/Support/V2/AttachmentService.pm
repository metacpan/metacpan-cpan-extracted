package Google::Cloud::Support::V2::AttachmentService;

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
    eval { require Google::Cloud::Support::V2::Attachment };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9hdHRhY2htZW50X3NlcnZpY2UucHJvdG8SF2dv
b2dsZS5jbG91ZC5zdXBwb3J0LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdn
b29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIv
YXR0YWNobWVudC5wcm90byKWAQoWTGlzdEF0dGFjaG1lbnRzUmVxdWVzdBJACgZwYXJlbnQY
ASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL0Nhc2VSBnBhcmVu
dBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBh
Z2VUb2tlbiJaChRHZXRBdHRhY2htZW50UmVxdWVzdBJCCgRuYW1lGAEgASgJQi7gQQL6QSgK
JmNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9BdHRhY2htZW50UgRuYW1lIogBChdMaXN0
QXR0YWNobWVudHNSZXNwb25zZRJFCgthdHRhY2htZW50cxgBIAMoCzIjLmdvb2dsZS5jbG91
ZC5zdXBwb3J0LnYyLkF0dGFjaG1lbnRSC2F0dGFjaG1lbnRzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbjLsAwoVQ2FzZUF0dGFjaG1lbnRTZXJ2aWNlEuYBCg9M
aXN0QXR0YWNobWVudHMSLy5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5MaXN0QXR0YWNobWVu
dHNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuTGlzdEF0dGFjaG1lbnRzUmVz
cG9uc2UicILT5JMCYRIrL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9jYXNlcy8qfS9hdHRhY2ht
ZW50c1oyEjAvdjIve3BhcmVudD1vcmdhbml6YXRpb25zLyovY2FzZXMvKn0vYXR0YWNobWVu
dHPaQQZwYXJlbnQSmAEKDUdldEF0dGFjaG1lbnQSLS5nb29nbGUuY2xvdWQuc3VwcG9ydC52
Mi5HZXRBdHRhY2htZW50UmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkF0dGFj
aG1lbnQiM4LT5JMCJhIkL3YyL3tuYW1lPSovKi9jYXNlcy8qL2F0dGFjaG1lbnRzLyp92kEE
bmFtZRpPykEbY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK/AQobY29tLmdvb2dsZS5jbG91ZC5z
dXBwb3J0LnYyQhZBdHRhY2htZW50U2VydmljZVByb3RvUAFaNWNsb3VkLmdvb2dsZS5jb20v
Z28vc3VwcG9ydC9hcGl2Mi9zdXBwb3J0cGI7c3VwcG9ydHBiqgIXR29vZ2xlLkNsb3VkLlN1
cHBvcnQuVjLKAhdHb29nbGVcQ2xvdWRcU3VwcG9ydFxWMuoCGkdvb2dsZTo6Q2xvdWQ6OlN1
cHBvcnQ6OlYyStkbCgcSBQ4AhgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAgCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYAMgoICgEIEgMYADQKCQoCCCUSAxgANAoICgEIEgMZAEwKCQoCCAsSAxkA
TAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADcKCQoCCAgSAxsANwoICgEIEgMcADQK
CQoCCAESAxwANAoICgEIEgMdADQKCQoCCCkSAx0ANAoICgEIEgMeADMKCQoCCC0SAx4AMwpS
CgIGABIEIQBXARpGIEEgc2VydmljZSB0byBtYW5hZ2UgZmlsZSBhdHRhY2htZW50cyBmb3Ig
R29vZ2xlIENsb3VkIHN1cHBvcnQgY2FzZXMuCgoKCgMGAAESAyEIHQoKCgMGAAMSAyICQwoM
CgUGAAOZCBIDIgJDCgsKAwYAAxIEIwIkNwoNCgUGAAOaCBIEIwIkNwpICgQGAAIAEgQnAjAD
GjogTGlzdCBhbGwgdGhlIGF0dGFjaG1lbnRzIGFzc29jaWF0ZWQgd2l0aCBhIHN1cHBvcnQg
Y2FzZS4KCgwKBQYAAgABEgMnBhUKDAoFBgACAAISAycWLAoMCgUGAAIAAxIDKA8mCg0KBQYA
AgAEEgQpBC4GChEKCQYAAgAEsMq8IhIEKQQuBgoMCgUGAAIABBIDLwQ0Cg8KCAYAAgAEmwgA
EgMvBDQKpQYKBAYAAgESBFECVgMalgYgUmV0cmlldmUgYW4gYXR0YWNobWVudCBhc3NvY2lh
dGVkIHdpdGggYSBzdXBwb3J0IGNhc2UuCgogRVhBTVBMRVM6CgogY1VSTDoKCiBgYGBzaGVs
bAogYXR0YWNobWVudD0icHJvamVjdHMvc29tZS1wcm9qZWN0L2Nhc2VzLzIzNTk4MzE0L2F0
dGFjaG1lbnRzLzA2ODRNMDAwMDBQM2gxZlFBQiIKIGN1cmwgXAogICAtLWhlYWRlciAiQXV0
aG9yaXphdGlvbjogQmVhcmVyICQoZ2Nsb3VkIGF1dGggcHJpbnQtYWNjZXNzLXRva2VuKSIg
XAogICAiaHR0cHM6Ly9jbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vdjIvJGF0dGFjaG1l
bnQiCiBgYGAKCiBQeXRob246CgogYGBgcHl0aG9uCiBpbXBvcnQgZ29vZ2xlYXBpY2xpZW50
LmRpc2NvdmVyeQoKIGFwaV92ZXJzaW9uID0gInYyIgogc3VwcG9ydEFwaVNlcnZpY2UgPSBn
b29nbGVhcGljbGllbnQuZGlzY292ZXJ5LmJ1aWxkKAogICAgIHNlcnZpY2VOYW1lPSJjbG91
ZHN1cHBvcnQiLAogICAgIHZlcnNpb249YXBpX3ZlcnNpb24sCiAgICAgZGlzY292ZXJ5U2Vy
dmljZVVybD1mImh0dHBzOi8vY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tLyRkaXNjb3Zl
cnkvcmVzdD92ZXJzaW9uPXthcGlfdmVyc2lvbn0iLAogKQogcmVxdWVzdCA9ICgKICAgICBz
dXBwb3J0QXBpU2VydmljZS5jYXNlcygpCiAgICAgLmF0dGFjaG1lbnRzKCkKICAgICAuZ2V0
KG5hbWU9InByb2plY3RzL3NvbWUtcHJvamVjdC9jYXNlcy80MzU5NTM0NC9hdHRhY2htZW50
cy8wNjg0TTAwMDAwUDNoMWZRQUIiKQogKQogcHJpbnQocmVxdWVzdC5leGVjdXRlKCkpCiBg
YGAKCgwKBQYAAgEBEgNRBhMKDAoFBgACAQISA1EUKAoMCgUGAAIBAxIDUTM9Cg0KBQYAAgEE
EgRSBFQGChEKCQYAAgEEsMq8IhIEUgRUBgoMCgUGAAIBBBIDVQQyCg8KCAYAAgEEmwgAEgNV
BDIKQwoCBAASBFoAcAEaNyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgTGlzdEF0dGFj
aG1lbnRzIGVuZHBvaW50LgoKCgoDBAABEgNaCB4KVgoEBAACABIEXAJhBBpIIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgY2FzZSBmb3Igd2hpY2ggYXR0YWNobWVudHMgc2hvdWxkIGJl
IGxpc3RlZC4KCgwKBQQAAgAFEgNcAggKDAoFBAACAAESA1wJDwoMCgUEAAIAAxIDXBITCg0K
BQQAAgAIEgRcFGEDCg8KCAQAAgAInAgAEgNdBCoKDwoHBAACAAifCBIEXgRgBQrxAgoEBAAC
ARIDawIWGuMCIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhdHRhY2htZW50cyBmZXRjaGVkIHdp
dGggZWFjaCByZXF1ZXN0LgoKIElmIG5vdCBwcm92aWRlZCwgdGhlIGRlZmF1bHQgaXMgMTAu
IFRoZSBtYXhpbXVtIHBhZ2Ugc2l6ZSB0aGF0IHdpbGwgYmUKIHJldHVybmVkIGlzIDEwMC4K
CiBUaGUgc2l6ZSBvZiBlYWNoIHBhZ2UgY2FuIGJlIHNtYWxsZXIgdGhhbiB0aGUgcmVxdWVz
dGVkIHBhZ2Ugc2l6ZSBhbmQgY2FuCiBpbmNsdWRlIHplcm8uIEZvciBleGFtcGxlLCB5b3Ug
Y291bGQgcmVxdWVzdCAxMDAgYXR0YWNobWVudHMgb24gb25lIHBhZ2UsCiByZWNlaXZlIDAs
IGFuZCB0aGVuIG9uIHRoZSBuZXh0IHBhZ2UsIHJlY2VpdmUgOTAuCgoMCgUEAAIBBRIDawIH
CgwKBQQAAgEBEgNrCBEKDAoFBAACAQMSA2sUFQpvCgQEAAICEgNvAhgaYiBBIHRva2VuIGlk
ZW50aWZ5aW5nIHRoZSBwYWdlIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmll
ZCwgdGhlCiBmaXJzdCBwYWdlIGlzIHJldHJpZXZlZC4KCgwKBQQAAgIFEgNvAggKDAoFBAAC
AgESA28JEwoMCgUEAAICAxIDbxYXCjAKAgQBEgRzAHsBGiQgUmVxdWVzdCBmb3IgZ2V0dGlu
ZyBhbiBhdHRhY2htZW50LgoKCgoDBAEBEgNzCBwKPAoEBAECABIEdQJ6BBouIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgYXR0YWNobWVudCB0byBnZXQuCgoMCgUEAQIABRIDdQIICgwK
BQQBAgABEgN1CQ0KDAoFBAECAAMSA3UQEQoNCgUEAQIACBIEdRJ6AwoPCggEAQIACJwIABID
dgQqCg8KBwQBAgAInwgSBHcEeQUKRQoCBAISBX4AhgEBGjggVGhlIHJlc3BvbnNlIG1lc3Nh
Z2UgZm9yIHRoZSBMaXN0QXR0YWNobWVudHMgZW5kcG9pbnQuCgoKCgMEAgESA34IHwo/CgQE
AgIAEgSAAQImGjEgVGhlIGxpc3Qgb2YgYXR0YWNobWVudHMgYXNzb2NpYXRlZCB3aXRoIGEg
Y2FzZS4KCg0KBQQCAgAEEgSAAQIKCg0KBQQCAgAGEgSAAQsVCg0KBQQCAgABEgSAARYhCg0K
BQQCAgADEgSAASQlCssBCgQEAgIBEgSFAQIdGrwBIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhl
IG5leHQgcGFnZSBvZiByZXN1bHRzLiBTZXQgdGhpcyBpbiB0aGUgYHBhZ2VfdG9rZW5gCiBm
aWVsZCBvZiBzdWJzZXF1ZW50IGBjYXNlcy5hdHRhY2htZW50cy5saXN0YCByZXF1ZXN0cy4g
SWYgdW5zcGVjaWZpZWQsCiB0aGVyZSBhcmUgbm8gbW9yZSByZXN1bHRzIHRvIHJldHJpZXZl
LgoKDQoFBAICAQUSBIUBAggKDQoFBAICAQESBIUBCRgKDQoFBAICAQMSBIUBGxxiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest ===
    # Fields for ListAttachmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::AttachmentService::GetAttachmentRequest ===
    # Fields for GetAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::AttachmentService::ListAttachmentsResponse ===
    # Fields for ListAttachmentsResponse
    # Field: attachments Type: 11 (.google.cloud.support.v2.Attachment)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Support::V2::AttachmentService::CaseAttachmentServiceClient ===
package Google::Cloud::Support::V2::AttachmentService::CaseAttachmentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2::AttachmentService::CaseAttachmentServiceClient

Client stub representing the remote C<CaseAttachmentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_attachments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseAttachmentService',
        method         => 'ListAttachments',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::AttachmentService::ListAttachmentsResponse',
    });
}

sub get_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::AttachmentService::GetAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseAttachmentService',
        method         => 'GetAttachment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Attachment::Attachment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::AttachmentService - Compiled Protocol Buffers messages for google/cloud/support/v2/attachment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::AttachmentService;

    my $msg = Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/attachment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest

The request message for the ListAttachments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the case for which attachments should be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of attachments fetched with each request.

If not provided, the default is 10. The maximum page size that will be
returned is 100.

The size of each page can be smaller than the requested page size and can
include zero. For example, you could request 100 attachments on one page,
receive 0, and then on the next page, receive 90.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=back

=head2 Google::Cloud::Support::V2::AttachmentService::GetAttachmentRequest

Request for getting an attachment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the attachment to get.

=back

=head2 Google::Cloud::Support::V2::AttachmentService::ListAttachmentsResponse

The response message for the ListAttachments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attachments() >> / C<< $msg->attachments($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Attachment::Attachment>)

The list of attachments associated with a case.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.attachments.list` requests. If unspecified,
there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::AttachmentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
