package Google::Cloud::Support::V2beta::AttachmentService;

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
    eval { require Google::Cloud::Support::V2beta::Attachment };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvYXR0YWNobWVudF9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGixnb29nbGUvY2xvdWQvc3Vw
cG9ydC92MmJldGEvYXR0YWNobWVudC5wcm90byKWAQoWTGlzdEF0dGFjaG1lbnRzUmVxdWVz
dBJACgZwYXJlbnQYASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29t
L0Nhc2VSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9r
ZW4YAyABKAlSCXBhZ2VUb2tlbiJaChRHZXRBdHRhY2htZW50UmVxdWVzdBJCCgRuYW1lGAEg
ASgJQi7gQQL6QSgKJmNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9BdHRhY2htZW50UgRu
YW1lIowBChdMaXN0QXR0YWNobWVudHNSZXNwb25zZRJJCgthdHRhY2htZW50cxgBIAMoCzIn
Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5BdHRhY2htZW50UgthdHRhY2htZW50cxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4yiAQKFUNhc2VBdHRhY2ht
ZW50U2VydmljZRL2AQoPTGlzdEF0dGFjaG1lbnRzEjMuZ29vZ2xlLmNsb3VkLnN1cHBvcnQu
djJiZXRhLkxpc3RBdHRhY2htZW50c1JlcXVlc3QaNC5nb29nbGUuY2xvdWQuc3VwcG9ydC52
MmJldGEuTGlzdEF0dGFjaG1lbnRzUmVzcG9uc2UieILT5JMCaRIvL3YyYmV0YS97cGFyZW50
PXByb2plY3RzLyovY2FzZXMvKn0vYXR0YWNobWVudHNaNhI0L3YyYmV0YS97cGFyZW50PW9y
Z2FuaXphdGlvbnMvKi9jYXNlcy8qfS9hdHRhY2htZW50c9pBBnBhcmVudBKkAQoNR2V0QXR0
YWNobWVudBIxLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5HZXRBdHRhY2htZW50UmVx
dWVzdBonLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5BdHRhY2htZW50IjeC0+STAioS
KC92MmJldGEve25hbWU9Ki8qL2Nhc2VzLyovYXR0YWNobWVudHMvKn3aQQRuYW1lGk/KQRtj
bG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtMBCh9jb20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJi
ZXRhQhZBdHRhY2htZW50U2VydmljZVByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28vc3Vw
cG9ydC9hcGl2MmJldGEvc3VwcG9ydHBiO3N1cHBvcnRwYqoCG0dvb2dsZS5DbG91ZC5TdXBw
b3J0LlYyQmV0YcoCG0dvb2dsZVxDbG91ZFxTdXBwb3J0XFYyYmV0YeoCHkdvb2dsZTo6Q2xv
dWQ6OlN1cHBvcnQ6OlYyYmV0YUrPFQoGEgQOAGgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYANgoICgEIEgMYADgKCQoCCCUSAxgAOAoICgEIEgMZAFAK
CQoCCAsSAxkAUAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADcKCQoCCAgSAxsANwoI
CgEIEgMcADgKCQoCCAESAxwAOAoICgEIEgMdADgKCQoCCCkSAx0AOAoICgEIEgMeADcKCQoC
CC0SAx4ANwpSCgIGABIEIQA5ARpGIEEgc2VydmljZSB0byBtYW5hZ2UgZmlsZSBhdHRhY2ht
ZW50cyBmb3IgR29vZ2xlIENsb3VkIHN1cHBvcnQgY2FzZXMuCgoKCgMGAAESAyEIHQoKCgMG
AAMSAyICQwoMCgUGAAOZCBIDIgJDCgsKAwYAAxIEIwIkNwoNCgUGAAOaCBIEIwIkNwpICgQG
AAIAEgQnAjADGjogTGlzdCBhbGwgdGhlIGF0dGFjaG1lbnRzIGFzc29jaWF0ZWQgd2l0aCBh
IHN1cHBvcnQgY2FzZS4KCgwKBQYAAgABEgMnBhUKDAoFBgACAAISAycWLAoMCgUGAAIAAxID
KA8mCg0KBQYAAgAEEgQpBC4GChEKCQYAAgAEsMq8IhIEKQQuBgoMCgUGAAIABBIDLwQ0Cg8K
CAYAAgAEmwgAEgMvBDQKJwoEBgACARIEMwI4AxoZIFJldHJpZXZlIGFuIGF0dGFjaG1lbnQu
CgoMCgUGAAIBARIDMwYTCgwKBQYAAgECEgMzFCgKDAoFBgACAQMSAzMzPQoNCgUGAAIBBBIE
NAQ2BgoRCgkGAAIBBLDKvCISBDQENgYKDAoFBgACAQQSAzcEMgoPCggGAAIBBJsIABIDNwQy
CkMKAgQAEgQ8AFIBGjcgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIExpc3RBdHRhY2ht
ZW50cyBlbmRwb2ludC4KCgoKAwQAARIDPAgeClYKBAQAAgASBD4CQwQaSCBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIGNhc2UgZm9yIHdoaWNoIGF0dGFjaG1lbnRzIHNob3VsZCBiZSBs
aXN0ZWQuCgoMCgUEAAIABRIDPgIICgwKBQQAAgABEgM+CQ8KDAoFBAACAAMSAz4SEwoNCgUE
AAIACBIEPhRDAwoPCggEAAIACJwIABIDPwQqCg8KBwQAAgAInwgSBEAEQgUK8QIKBAQAAgES
A00CFhrjAiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYXR0YWNobWVudHMgZmV0Y2hlZCB3aXRo
IGVhY2ggcmVxdWVzdC4KCiBJZiBub3QgcHJvdmlkZWQsIHRoZSBkZWZhdWx0IGlzIDEwLiBU
aGUgbWF4aW11bSBwYWdlIHNpemUgdGhhdCB3aWxsIGJlCiByZXR1cm5lZCBpcyAxMDAuCgog
VGhlIHNpemUgb2YgZWFjaCBwYWdlIGNhbiBiZSBzbWFsbGVyIHRoYW4gdGhlIHJlcXVlc3Rl
ZCBwYWdlIHNpemUgYW5kIGNhbgogaW5jbHVkZSB6ZXJvLiBGb3IgZXhhbXBsZSwgeW91IGNv
dWxkIHJlcXVlc3QgMTAwIGF0dGFjaG1lbnRzIG9uIG9uZSBwYWdlLAogcmVjZWl2ZSAwLCBh
bmQgdGhlbiBvbiB0aGUgbmV4dCBwYWdlLCByZWNlaXZlIDkwLgoKDAoFBAACAQUSA00CBwoM
CgUEAAIBARIDTQgRCgwKBQQAAgEDEgNNFBUKbwoEBAACAhIDUQIYGmIgQSB0b2tlbiBpZGVu
dGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQs
IHRoZQogZmlyc3QgcGFnZSBpcyByZXRyaWV2ZWQuCgoMCgUEAAICBRIDUQIICgwKBQQAAgIB
EgNRCRMKDAoFBAACAgMSA1EWFwowCgIEARIEVQBdARokIFJlcXVlc3QgZm9yIGdldHRpbmcg
YW4gYXR0YWNobWVudC4KCgoKAwQBARIDVQgcCjwKBAQBAgASBFcCXAQaLiBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIGF0dGFjaG1lbnQgdG8gZ2V0LgoKDAoFBAECAAUSA1cCCAoMCgUE
AQIAARIDVwkNCgwKBQQBAgADEgNXEBEKDQoFBAECAAgSBFcSXAMKDwoIBAECAAicCAASA1gE
KgoPCgcEAQIACJ8IEgRZBFsFCkQKAgQCEgRgAGgBGjggVGhlIHJlc3BvbnNlIG1lc3NhZ2Ug
Zm9yIHRoZSBMaXN0QXR0YWNobWVudHMgZW5kcG9pbnQuCgoKCgMEAgESA2AIHwo+CgQEAgIA
EgNiAiYaMSBUaGUgbGlzdCBvZiBhdHRhY2htZW50cyBhc3NvY2lhdGVkIHdpdGggYSBjYXNl
LgoKDAoFBAICAAQSA2ICCgoMCgUEAgIABhIDYgsVCgwKBQQCAgABEgNiFiEKDAoFBAICAAMS
A2IkJQrKAQoEBAICARIDZwIdGrwBIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZSBvZiByZXN1bHRzLiBTZXQgdGhpcyBpbiB0aGUgYHBhZ2VfdG9rZW5gCiBmaWVsZCBvZiBz
dWJzZXF1ZW50IGBjYXNlcy5hdHRhY2htZW50cy5saXN0YCByZXF1ZXN0cy4gSWYgdW5zcGVj
aWZpZWQsCiB0aGVyZSBhcmUgbm8gbW9yZSByZXN1bHRzIHRvIHJldHJpZXZlLgoKDAoFBAIC
AQUSA2cCCAoMCgUEAgIBARIDZwkYCgwKBQQCAgEDEgNnGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest ===
    # Fields for ListAttachmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest ===
    # Fields for GetAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse ===
    # Fields for ListAttachmentsResponse
    # Field: attachments Type: 11 (.google.cloud.support.v2beta.Attachment)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Support::V2beta::AttachmentService::CaseAttachmentServiceClient ===
package Google::Cloud::Support::V2beta::AttachmentService::CaseAttachmentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2beta::AttachmentService::CaseAttachmentServiceClient

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
        ? Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseAttachmentService',
        method         => 'ListAttachments',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse',
    });
}

sub get_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseAttachmentService',
        method         => 'GetAttachment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Attachment::Attachment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::AttachmentService - Compiled Protocol Buffers messages for google/cloud/support/v2beta/attachment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::AttachmentService;

    my $msg = Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/attachment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest

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

=head2 Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest

Request for getting an attachment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the attachment to get.

=back

=head2 Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse

The response message for the ListAttachments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attachments() >> / C<< $msg->attachments($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Attachment::Attachment>)

The list of attachments associated with a case.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.attachments.list` requests. If unspecified,
there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::AttachmentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
