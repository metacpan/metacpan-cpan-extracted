package Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CkVnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9hc3luY19kb2N1bWVudF9zZXJ2
aWNlX3JlcXVlc3QucHJvdG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvIhgKFkNyZWF0ZURvY3VtZW50TWV0YWRhdGEiGAoWVXBkYXRlRG9jdW1lbnRNZXRhZGF0
YUKIAgokY29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxQiBBc3luY0RvY3Vt
ZW50U2VydmljZVJlcXVlc3RQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2NvbnRlbnR3
YXJlaG91c2UvYXBpdjEvY29udGVudHdhcmVob3VzZXBiO2NvbnRlbnR3YXJlaG91c2VwYqoC
IEdvb2dsZS5DbG91ZC5Db250ZW50V2FyZWhvdXNlLlYxygIgR29vZ2xlXENsb3VkXENvbnRl
bnRXYXJlaG91c2VcVjHqAiNHb29nbGU6OkNsb3VkOjpDb250ZW50V2FyZWhvdXNlOjpWMUqq
BwoGEgQOACEhCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAp
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAD0KCQoCCCUSAxUAPQoICgEIEgMWAGcK
CQoCCAsSAxYAZwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAEEKCQoCCAgSAxgAQQoI
CgEIEgMZAD0KCQoCCAESAxkAPQoICgEIEgMaAD0KCQoCCCkSAxoAPQoICgEIEgMbADwKCQoC
CC0SAxsAPApKCgIEABIDHgAhGj8gTWV0YWRhdGEgb2JqZWN0IGZvciBDcmVhdGVEb2N1bWVu
dCByZXF1ZXN0IChjdXJyZW50bHkgZW1wdHkpLgoKCgoDBAABEgMeCB4KSgoCBAESAyEAIRo/
IE1ldGFkYXRhIG9iamVjdCBmb3IgVXBkYXRlRG9jdW1lbnQgcmVxdWVzdCAoY3VycmVudGx5
IGVtcHR5KS4KCgoKAwQBARIDIQgeYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata ===
    # Fields for CreateDocumentMetadata

# === Message: Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::UpdateDocumentMetadata ===
    # Fields for UpdateDocumentMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/async_document_service_request.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest;

    my $msg = Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/async_document_service_request.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::CreateDocumentMetadata

Metadata object for CreateDocument request (currently empty).

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::UpdateDocumentMetadata

Metadata object for UpdateDocument request (currently empty).

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::AsyncDocumentServiceRequest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
