package Google::Cloud::Eventarc::V1::Discovery;

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
Cihnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvZGlzY292ZXJ5LnByb3RvEhhnb29nbGUuY2xv
dWQuZXZlbnRhcmMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8ikAIKCFByb3ZpZGVyEhcKBG5hbWUYASABKAlCA+BBA1IE
bmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBA1ILZGlzcGxheU5hbWUSSQoLZXZlbnRf
dHlwZXMYAyADKAsyIy5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuRXZlbnRUeXBlQgPgQQNS
CmV2ZW50VHlwZXM6eOpBdQogZXZlbnRhcmMuZ29vZ2xlYXBpcy5jb20vUHJvdmlkZXISPHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wcm92aWRlcnMve3Byb3Zp
ZGVyfSoJcHJvdmlkZXJzMghwcm92aWRlciLgAQoJRXZlbnRUeXBlEhcKBHR5cGUYASABKAlC
A+BBA1IEdHlwZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEDUgtkZXNjcmlwdGlvbhJkChRm
aWx0ZXJpbmdfYXR0cmlidXRlcxgDIAMoCzIsLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MS5G
aWx0ZXJpbmdBdHRyaWJ1dGVCA+BBA1ITZmlsdGVyaW5nQXR0cmlidXRlcxItChBldmVudF9z
Y2hlbWFfdXJpGAQgASgJQgPgQQNSDmV2ZW50U2NoZW1hVXJpIroBChJGaWx0ZXJpbmdBdHRy
aWJ1dGUSIQoJYXR0cmlidXRlGAEgASgJQgPgQQNSCWF0dHJpYnV0ZRIlCgtkZXNjcmlwdGlv
bhgCIAEoCUID4EEDUgtkZXNjcmlwdGlvbhIfCghyZXF1aXJlZBgDIAEoCEID4EEDUghyZXF1
aXJlZBI5ChZwYXRoX3BhdHRlcm5fc3VwcG9ydGVkGAQgASgIQgPgQQNSFHBhdGhQYXR0ZXJu
U3VwcG9ydGVkQmoKHGNvbS5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjFCDkRpc2NvdmVyeVBy
b3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28vZXZlbnRhcmMvYXBpdjEvZXZlbnRhcmNwYjtl
dmVudGFyY3BiStIZCgYSBA4AWAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUATwoJCgIICxIDFQBP
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgANQoJ
CgIIARIDGAA1CjgKAgQAEgQbAC4BGiwgQSByZXByZXNlbnRhdGlvbiBvZiB0aGUgUHJvdmlk
ZXIgcmVzb3VyY2UuCgoKCgMEAAESAxsIEAoLCgMEAAcSBBwCIQQKDQoFBAAHnQgSBBwCIQQK
aQoEBAACABIDJQI+GlwgT3V0cHV0IG9ubHkuIEluCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3Byb3ZpZGVycy97cHJvdmlkZXJfaWR9YCBmb3JtYXQuCgoM
CgUEAAIABRIDJQIICgwKBQQAAgABEgMlCQ0KDAoFBAACAAMSAyUQEQoMCgUEAAIACBIDJRI9
Cg8KCAQAAgAInAgAEgMlEzwKXwoEBAACARIDKQJGGlIgT3V0cHV0IG9ubHkuIEh1bWFuIGZy
aWVuZGx5IG5hbWUgZm9yIHRoZSBQcm92aWRlci4gRm9yIGV4YW1wbGUgIkNsb3VkCiBTdG9y
YWdlIi4KCgwKBQQAAgEFEgMpAggKDAoFBAACAQESAykJFQoMCgUEAAIBAxIDKRgZCgwKBQQA
AgEIEgMpGkUKDwoIBAACAQicCAASAykbRAo7CgQEAAICEgQsAi0yGi0gT3V0cHV0IG9ubHku
IEV2ZW50IHR5cGVzIGZvciB0aGlzIHByb3ZpZGVyLgoKDAoFBAACAgQSAywCCgoMCgUEAAIC
BhIDLAsUCgwKBQQAAgIBEgMsFSAKDAoFBAACAgMSAywjJAoMCgUEAAICCBIDLQYxCg8KCAQA
AgIInAgAEgMtBzAKOgoCBAESBDEARgEaLiBBIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBldmVu
dCB0eXBlIHJlc291cmNlLgoKCgoDBAEBEgMxCBEK8wIKBAQBAgASAzgCPhrlAiBPdXRwdXQg
b25seS4gVGhlIGZ1bGwgbmFtZSBvZiB0aGUgZXZlbnQgdHlwZSAoZm9yIGV4YW1wbGUsCiAi
Z29vZ2xlLmNsb3VkLnN0b3JhZ2Uub2JqZWN0LnYxLmZpbmFsaXplZCIpLiBJbiB0aGUgZm9y
bSBvZgoge3Byb3ZpZGVyLXNwZWNpZmljLXByZWZpeH0ue3Jlc291cmNlfS57dmVyc2lvbn0u
e3ZlcmJ9LiBUeXBlcyBNVVNUIGJlCiB2ZXJzaW9uZWQgYW5kIGV2ZW50IHNjaGVtYXMgYXJl
IGd1YXJhbnRlZWQgdG8gcmVtYWluIGJhY2t3YXJkIGNvbXBhdGlibGUKIHdpdGhpbiBvbmUg
dmVyc2lvbi4gTm90ZSB0aGF0IGV2ZW50IHR5cGUgdmVyc2lvbnMgYW5kIEFQSSB2ZXJzaW9u
cyBkbyBub3QKIG5lZWQgdG8gbWF0Y2guCgoMCgUEAQIABRIDOAIICgwKBQQBAgABEgM4CQ0K
DAoFBAECAAMSAzgQEQoMCgUEAQIACBIDOBI9Cg8KCAQBAgAInAgAEgM4EzwKhwEKBAQBAgES
AzwCRRp6IE91dHB1dCBvbmx5LiBIdW1hbiBmcmllbmRseSBkZXNjcmlwdGlvbiBvZiB3aGF0
IHRoZSBldmVudCB0eXBlIGlzIGFib3V0LgogRm9yIGV4YW1wbGUgIkJ1Y2tldCBjcmVhdGVk
IGluIENsb3VkIFN0b3JhZ2UiLgoKDAoFBAECAQUSAzwCCAoMCgUEAQIBARIDPAkUCgwKBQQB
AgEDEgM8FxgKDAoFBAECAQgSAzwZRAoPCggEAQIBCJwIABIDPBpDCkUKBAQBAgISBD8CQDIa
NyBPdXRwdXQgb25seS4gRmlsdGVyaW5nIGF0dHJpYnV0ZXMgZm9yIHRoZSBldmVudCB0eXBl
LgoKDAoFBAECAgQSAz8CCgoMCgUEAQICBhIDPwsdCgwKBQQBAgIBEgM/HjIKDAoFBAECAgMS
Az81NgoMCgUEAQICCBIDQAYxCg8KCAQBAgIInAgAEgNABzAKtQEKBAQBAgMSA0UCShqnASBP
dXRwdXQgb25seS4gVVJJIGZvciB0aGUgZXZlbnQgc2NoZW1hLgogRm9yIGV4YW1wbGUKICJo
dHRwczovL2dpdGh1Yi5jb20vZ29vZ2xlYXBpcy9nb29nbGUtY2xvdWRldmVudHMvYmxvYi9t
YXN0ZXIvcHJvdG8vZ29vZ2xlL2V2ZW50cy9jbG91ZC9zdG9yYWdlL3YxL2V2ZW50cy5wcm90
byIKCgwKBQQBAgMFEgNFAggKDAoFBAECAwESA0UJGQoMCgUEAQIDAxIDRRwdCgwKBQQBAgMI
EgNFHkkKDwoIBAECAwicCAASA0UfSApsCgIEAhIESgBYARpgIEEgcmVwcmVzZW50YXRpb24g
b2YgdGhlIEZpbHRlcmluZ0F0dHJpYnV0ZSByZXNvdXJjZS4KIEZpbHRlcmluZyBhdHRyaWJ1
dGVzIGFyZSBwZXIgZXZlbnQgdHlwZS4KCgoKAwQCARIDSggaCkgKBAQCAgASA0wCQxo7IE91
dHB1dCBvbmx5LiBBdHRyaWJ1dGUgdXNlZCBmb3IgZmlsdGVyaW5nIHRoZSBldmVudCB0eXBl
LgoKDAoFBAICAAUSA0wCCAoMCgUEAgIAARIDTAkSCgwKBQQCAgADEgNMFRYKDAoFBAICAAgS
A0wXQgoPCggEAgIACJwIABIDTBhBCkgKBAQCAgESA08CRRo7IE91dHB1dCBvbmx5LiBEZXNj
cmlwdGlvbiBvZiB0aGUgcHVycG9zZSBvZiB0aGUgYXR0cmlidXRlLgoKDAoFBAICAQUSA08C
CAoMCgUEAgIBARIDTwkUCgwKBQQCAgEDEgNPFxgKDAoFBAICAQgSA08ZRAoPCggEAgIBCJwI
ABIDTxpDCp8BCgQEAgICEgNTAkAakQEgT3V0cHV0IG9ubHkuIElmIHRydWUsIHRoZSB0cmln
Z2VycyBmb3IgdGhpcyBwcm92aWRlciBzaG91bGQgYWx3YXlzIHNwZWNpZnkKIGEgZmlsdGVy
IG9uIHRoZXNlIGF0dHJpYnV0ZXMuIFRyaWdnZXIgY3JlYXRpb24gd2lsbCBmYWlsIG90aGVy
d2lzZS4KCgwKBQQCAgIFEgNTAgYKDAoFBAICAgESA1MHDwoMCgUEAgICAxIDUxITCgwKBQQC
AgIIEgNTFD8KDwoIBAICAgicCAASA1MVPgp0CgQEAgIDEgNXAk4aZyBPdXRwdXQgb25seS4g
SWYgdHJ1ZSwgdGhlIGF0dHJpYnV0ZSBhY2NlcHRzIG1hdGNoaW5nIGV4cHJlc3Npb25zIGlu
IHRoZQogRXZlbnRhcmMgUGF0aFBhdHRlcm4gZm9ybWF0LgoKDAoFBAICAwUSA1cCBgoMCgUE
AgIDARIDVwcdCgwKBQQCAgMDEgNXICEKDAoFBAICAwgSA1ciTQoPCggEAgIDCJwIABIDVyNM
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::Discovery::Provider ===
    # Fields for Provider
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: event_types Type: 11 (.google.cloud.eventarc.v1.EventType)

# === Message: Google::Cloud::Eventarc::V1::Discovery::EventType ===
    # Fields for EventType
    # Field: type Type: 9 ()
    # Field: description Type: 9 ()
    # Field: filtering_attributes Type: 11 (.google.cloud.eventarc.v1.FilteringAttribute)
    # Field: event_schema_uri Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute ===
    # Fields for FilteringAttribute
    # Field: attribute Type: 9 ()
    # Field: description Type: 9 ()
    # Field: required Type: 8 ()
    # Field: path_pattern_supported Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::Discovery - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/discovery.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::Discovery;

    my $msg = Google::Cloud::Eventarc::V1::Discovery::Provider->new({
        name => $name,
        display_name => $display_name,
        event_types => $event_types,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::Discovery::Provider->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/discovery.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::Discovery::Provider

A representation of the Provider resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. In
`projects/{project}/locations/{location}/providers/{provider_id}` format.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Human friendly name for the Provider. For example "Cloud
Storage".

=item * C<< $msg->event_types() >> / C<< $msg->event_types($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Discovery::EventType>)

Output only. Event types for this provider.

=back

=head2 Google::Cloud::Eventarc::V1::Discovery::EventType

A representation of the event type resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Output only. The full name of the event type (for example,
"google.cloud.storage.object.v1.finalized"). In the form of
{provider-specific-prefix}.{resource}.{version}.{verb}. Types MUST be
versioned and event schemas are guaranteed to remain backward compatible
within one version. Note that event type versions and API versions do not
need to match.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Human friendly description of what the event type is about.
For example "Bucket created in Cloud Storage".

=item * C<< $msg->filtering_attributes() >> / C<< $msg->filtering_attributes($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute>)

Output only. Filtering attributes for the event type.

=item * C<< $msg->event_schema_uri() >> / C<< $msg->event_schema_uri($value) >>

Type: C<String>

Output only. URI for the event schema.
For example
"https://github.com/googleapis/google-cloudevents/blob/master/proto/google/events/cloud/storage/v1/events.proto"

=back

=head2 Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute

A representation of the FilteringAttribute resource.
Filtering attributes are per event type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attribute() >> / C<< $msg->attribute($value) >>

Type: C<String>

Output only. Attribute used for filtering the event type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description of the purpose of the attribute.

=item * C<< $msg->required() >> / C<< $msg->required($value) >>

Type: C<Bool>

Output only. If true, the triggers for this provider should always specify
a filter on these attributes. Trigger creation will fail otherwise.

=item * C<< $msg->path_pattern_supported() >> / C<< $msg->path_pattern_supported($value) >>

Type: C<Bool>

Output only. If true, the attribute accepts matching expressions in the
Eventarc PathPattern format.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::Discovery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
