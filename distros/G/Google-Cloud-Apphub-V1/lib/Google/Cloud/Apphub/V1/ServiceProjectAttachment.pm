package Google::Cloud::Apphub::V1::ServiceProjectAttachment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYXBwaHViL3YxL3NlcnZpY2VfcHJvamVjdF9hdHRhY2htZW50LnBy
b3RvEhZnb29nbGUuY2xvdWQuYXBwaHViLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3AQKGFNlcnZpY2VQ
cm9qZWN0QXR0YWNobWVudBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSXwoPc2VydmljZV9w
cm9qZWN0GAIgASgJQjbgQQLgQQX6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFw
aXMuY29tL1Byb2plY3RSDnNlcnZpY2VQcm9qZWN0EkAKC2NyZWF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEh0KA3VpZBgEIAEo
CUIL4ozP1wgCCAHgQQNSA3VpZBJRCgVzdGF0ZRgFIAEoDjI2Lmdvb2dsZS5jbG91ZC5hcHBo
dWIudjEuU2VydmljZVByb2plY3RBdHRhY2htZW50LlN0YXRlQgPgQQNSBXN0YXRlIkYKBVN0
YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIM
CghERUxFVElORxADOskB6kHFAQouYXBwaHViLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VQcm9q
ZWN0QXR0YWNobWVudBJecHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3NlcnZpY2VQcm9qZWN0QXR0YWNobWVudHMve3NlcnZpY2VfcHJvamVjdF9hdHRhY2htZW50
fSoZc2VydmljZVByb2plY3RBdHRhY2htZW50czIYc2VydmljZVByb2plY3RBdHRhY2htZW50
Qr8BChpjb20uZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MUIdU2VydmljZVByb2plY3RBdHRhY2ht
ZW50UHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBodWIvYXBpdjEvYXBwaHVicGI7
YXBwaHVicGKqAhZHb29nbGUuQ2xvdWQuQXBwSHViLlYxygIWR29vZ2xlXENsb3VkXEFwcEh1
YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6OkFwcEh1Yjo6VjFK6RUKBhIEDgBZAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMT
ACUKCQoCAwISAxQAIwoJCgIDAxIDFQApCggKAQgSAxcAMwoJCgIIJRIDFwAzCggKAQgSAxgA
SQoJCgIICxIDGABJCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAPgoJCgIICBIDGgA+
CggKAQgSAxsAMwoJCgIIARIDGwAzCggKAQgSAxwAMwoJCgIIKRIDHAAzCggKAQgSAx0AMgoJ
CgIILRIDHQAyCvkCCgIEABIEJABZARrsAiBTZXJ2aWNlUHJvamVjdEF0dGFjaG1lbnQgcmVw
cmVzZW50cyBhbiBhdHRhY2htZW50IGZyb20gYSBzZXJ2aWNlIHByb2plY3QgdG8gYQogaG9z
dCBwcm9qZWN0LiBTZXJ2aWNlIHByb2plY3RzIGNvbnRhaW4gdGhlIHVuZGVybHlpbmcgY2xv
dWQKIGluZnJhc3RydWN0dXJlIHJlc291cmNlcywgYW5kIGV4cG9zZSB0aGVzZSByZXNvdXJj
ZXMgdG8gdGhlIGhvc3QgcHJvamVjdAogdGhyb3VnaCBhIFNlcnZpY2VQcm9qZWN0QXR0YWNo
bWVudC4gV2l0aCB0aGUgYXR0YWNobWVudHMsIHRoZSBob3N0IHByb2plY3QKIGNhbiBwcm92
aWRlIGFuIGFnZ3JlZ2F0ZWQgdmlldyBvZiByZXNvdXJjZXMgYWNyb3NzIGFsbCBzZXJ2aWNl
IHByb2plY3RzLgoKCgoDBAABEgMkCCAKCwoDBAAHEgQlAioECg0KBQQAB50IEgQlAioECi8K
BAQABAASBC0COwMaISBTZXJ2aWNlUHJvamVjdEF0dGFjaG1lbnQgc3RhdGUuCgoMCgUEAAQA
ARIDLQcMCiMKBgQABAACABIDLwQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgAB
EgMvBBUKDgoHBAAEAAIAAhIDLxgZCj8KBgQABAACARIDMgQRGjAgVGhlIFNlcnZpY2VQcm9q
ZWN0QXR0YWNobWVudCBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMgQMCg4KBwQA
BAACAQISAzIPEAqoAQoGBAAEAAICEgM3BA8amAEgVGhlIFNlcnZpY2VQcm9qZWN0QXR0YWNo
bWVudCBpcyByZWFkeS4KIFRoaXMgbWVhbnMgU2VydmljZXMgYW5kIFdvcmtsb2FkcyB1bmRl
ciB0aGUgY29ycmVzcG9uZGluZwogU2VydmljZVByb2plY3RBdHRhY2htZW50IGlzIHJlYWR5
IGZvciByZWdpc3RyYXRpb24uCgoOCgcEAAQAAgIBEgM3BAoKDgoHBAAEAAICAhIDNw0OCj8K
BgQABAACAxIDOgQRGjAgVGhlIFNlcnZpY2VQcm9qZWN0QXR0YWNobWVudCBpcyBiZWluZyBk
ZWxldGVkLgoKDgoHBAAEAAIDARIDOgQMCg4KBwQABAACAwISAzoPEAq1AQoEBAACABIDPwI9
GqcBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIGEgU2VydmljZVByb2plY3RB
dHRhY2htZW50LiBGb3JtYXQ6CiBgInByb2plY3RzL3tob3N0LXByb2plY3QtaWR9L2xvY2F0
aW9ucy9nbG9iYWwvc2VydmljZVByb2plY3RBdHRhY2htZW50cy97c2VydmljZS1wcm9qZWN0
LWlkfS4iYAoKDAoFBAACAAUSAz8CCAoMCgUEAAIAARIDPwkNCgwKBQQAAgADEgM/EBEKDAoF
BAACAAgSAz8SPAoPCggEAAIACJwIABIDPxM7CuoBCgQEAAIBEgREAkoEGtsBIFJlcXVpcmVk
LiBJbW11dGFibGUuIFNlcnZpY2UgcHJvamVjdCBuYW1lIGluIHRoZSBmb3JtYXQ6IGAicHJv
amVjdHMvYWJjImAKIG9yIGAicHJvamVjdHMvMTIzImAuIEFzIGlucHV0LCBwcm9qZWN0IG5h
bWUgd2l0aCBlaXRoZXIgcHJvamVjdCBpZCBvcgogbnVtYmVyIGFyZSBhY2NlcHRlZC4gQXMg
b3V0cHV0LCB0aGlzIGZpZWxkIHdpbGwgY29udGFpbiBwcm9qZWN0IG51bWJlci4KCgwKBQQA
AgEFEgNEAggKDAoFBAACAQESA0QJGAoMCgUEAAIBAxIDRBscCg0KBQQAAgEIEgREHUoDCg8K
CAQAAgEInAgAEgNFBCoKDwoIBAACAQicCAESA0YEKwoPCgcEAAIBCJ8IEgRHBEkFCikKBAQA
AgISBE0CTjIaGyBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWUuCgoMCgUEAAICBhIDTQIbCgwK
BQQAAgIBEgNNHCcKDAoFBAACAgMSA00qKwoMCgUEAAICCBIDTgYxCg8KCAQAAgIInAgAEgNO
BzAKcAoEBAACAxIEUgJVBBpiIE91dHB1dCBvbmx5LiBBIGdsb2JhbGx5IHVuaXF1ZSBpZGVu
dGlmaWVyIChpbiBVVUlENCBmb3JtYXQpIGZvciB0aGUKIGBTZXJ2aWNlUHJvamVjdEF0dGFj
aG1lbnRgLgoKDAoFBAACAwUSA1ICCAoMCgUEAAIDARIDUgkMCgwKBQQAAgMDEgNSDxAKDQoF
BAACAwgSBFIRVQMKEgoLBAACAwjM8fmKAQESA1MEKgoPCggEAAIDCJwIABIDVAQtCjsKBAQA
AgQSA1gCPhouIE91dHB1dCBvbmx5LiBTZXJ2aWNlUHJvamVjdEF0dGFjaG1lbnQgc3RhdGUu
CgoMCgUEAAIEBhIDWAIHCgwKBQQAAgQBEgNYCA0KDAoFBAACBAMSA1gQEQoMCgUEAAIECBID
WBI9Cg8KCAQAAgQInAgAEgNYEzxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment ===
    # Fields for ServiceProjectAttachment
    # Field: name Type: 9 ()
    # Field: service_project Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.apphub.v1.ServiceProjectAttachment.State)

# Enum: ServiceProjectAttachment::State
our $ServiceProjectAttachment_STATE_UNSPECIFIED = 0;
our $ServiceProjectAttachment_CREATING = 1;
our $ServiceProjectAttachment_ACTIVE = 2;
our $ServiceProjectAttachment_DELETING = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::ServiceProjectAttachment - Compiled Protocol Buffers messages for google/cloud/apphub/v1/service_project_attachment.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::ServiceProjectAttachment;

    my $msg = Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment->new({
        name => $name,
        service_project => $service_project,
        create_time => $create_time,
        uid => $uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/service_project_attachment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment

ServiceProjectAttachment represents an attachment from a service project to a
host project. Service projects contain the underlying cloud
infrastructure resources, and expose these resources to the host project
through a ServiceProjectAttachment. With the attachments, the host project
can provide an aggregated view of resources across all service projects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of a ServiceProjectAttachment. Format:
`"projects/{host-project-id}/locations/global/serviceProjectAttachments/{service-project-id}."`

=item * C<< $msg->service_project() >> / C<< $msg->service_project($value) >>

Type: C<String>

Required. Immutable. Service project name in the format: `"projects/abc"`
or `"projects/123"`. As input, project name with either project id or
number are accepted. As output, this field will contain project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A globally unique identifier (in UUID4 format) for the
`ServiceProjectAttachment`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::ServiceProjectAttachment::State>)

Output only. ServiceProjectAttachment state.

=back

=head3 Enum: ServiceProjectAttachment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::ServiceProjectAttachment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
