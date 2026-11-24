package Google::Cloud::Connectors::V1::Provider;

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
    eval { require Google::Cloud::Connectors::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9wcm92aWRlci5wcm90bxIaZ29vZ2xlLmNs
b3VkLmNvbm5lY3RvcnMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9jb25uZWN0b3JzL3YxL2Nv
bW1vbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLHBQoIUHJvdmlk
ZXISFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1l
GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEk0K
BmxhYmVscxgEIAMoCzIwLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLlByb3ZpZGVyLkxh
YmVsc0VudHJ5QgPgQQNSBmxhYmVscxIwChFkb2N1bWVudGF0aW9uX3VyaRgGIAEoCUID4EED
UhBkb2N1bWVudGF0aW9uVXJpEiYKDGV4dGVybmFsX3VyaRgHIAEoCUID4EEDUgtleHRlcm5h
bFVyaRIlCgtkZXNjcmlwdGlvbhgIIAEoCUID4EEDUgtkZXNjcmlwdGlvbhIzChN3ZWJfYXNz
ZXRzX2xvY2F0aW9uGAkgASgJQgPgQQNSEXdlYkFzc2V0c0xvY2F0aW9uEiYKDGRpc3BsYXlf
bmFtZRgKIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJPCgxsYXVuY2hfc3RhZ2UYCyABKA4yJy5n
b29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5MYXVuY2hTdGFnZUID4EEDUgtsYXVuY2hTdGFn
ZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBOmXqQWIKImNvbm5lY3RvcnMuZ29vZ2xlYXBpcy5jb20vUHJvdmlkZXISPHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wcm92aWRlcnMve3Byb3ZpZGVy
fSJUChJHZXRQcm92aWRlclJlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC+kEkCiJjb25uZWN0
b3JzLmdvb2dsZWFwaXMuY29tL1Byb3ZpZGVyUgRuYW1lIpYBChRMaXN0UHJvdmlkZXJzUmVx
dWVzdBJCCgZwYXJlbnQYASABKAlCKuBBAvpBJBIiY29ubmVjdG9ycy5nb29nbGVhcGlzLmNv
bS9Qcm92aWRlclIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFn
ZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIqUBChVMaXN0UHJvdmlkZXJzUmVzcG9uc2USQgoJ
cHJvdmlkZXJzGAEgAygLMiQuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUHJvdmlkZXJS
CXByb3ZpZGVycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoL
dW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlQnEKHmNvbS5nb29nbGUuY2xvdWQuY29u
bmVjdG9ycy52MUINUHJvdmlkZXJQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2Nvbm5l
Y3RvcnMvYXBpdjEvY29ubmVjdG9yc3BiO2Nvbm5lY3RvcnNwYkrSGwoGEgQOAHIBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACkKCQoC
AwESAxMAIwoJCgIDAhIDFAAxCgkKAgMDEgMVACkKCAoBCBIDFwBVCgkKAggLEgMXAFUKCAoB
CBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAuCgkKAggIEgMZAC4KCAoBCBIDGgA3CgkKAggB
EgMaADcKRwoCBAASBB0ARgEaOyBQcm92aWRlciBpbmRpY2F0ZXMgdGhlIG93bmVyIHdobyBw
cm92aWRlcyB0aGUgY29ubmVjdG9ycy4KCgoKAwQAARIDHQgQCgsKAwQABxIEHgIhBAoNCgUE
AAedCBIEHgIhBAq7AQoEBAACABIDJgI+Gq0BIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1l
IG9mIHRoZSBQcm92aWRlci4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L3Byb3ZpZGVycy97cHJvdmlkZXJ9CiBPbmx5IGdsb2JhbCBsb2NhdGlv
biBpcyBzdXBwb3J0ZWQgZm9yIFByb3ZpZGVyIHJlc291cmNlLgoKDAoFBAACAAUSAyYCCAoM
CgUEAAIAARIDJgkNCgwKBQQAAgADEgMmEBEKDAoFBAACAAgSAyYSPQoPCggEAAIACJwIABID
JhM8CioKBAQAAgESBCkCKjIaHCBPdXRwdXQgb25seS4gQ3JlYXRlZCB0aW1lLgoKDAoFBAAC
AQYSAykCGwoMCgUEAAIBARIDKRwnCgwKBQQAAgEDEgMpKisKDAoFBAACAQgSAyoGMQoPCggE
AAIBCJwIABIDKgcwCioKBAQAAgISBC0CLjIaHCBPdXRwdXQgb25seS4gVXBkYXRlZCB0aW1l
LgoKDAoFBAACAgYSAy0CGwoMCgUEAAICARIDLRwnCgwKBQQAAgIDEgMtKisKDAoFBAACAggS
Ay4GMQoPCggEAAICCJwIABIDLgcwCsUBCgQEAAIDEgMzAk0atwEgT3V0cHV0IG9ubHkuIFJl
c291cmNlIGxhYmVscyB0byByZXByZXNlbnQgdXNlci1wcm92aWRlZCBtZXRhZGF0YS4KIFJl
ZmVyIHRvIGNsb3VkIGRvY3VtZW50YXRpb24gb24gbGFiZWxzIGZvciBtb3JlIGRldGFpbHMu
CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2xhYmVsaW5nLXJlc291
cmNlcwoKDAoFBAACAwYSAzMCFQoMCgUEAAIDARIDMxYcCgwKBQQAAgMDEgMzHyAKDAoFBAAC
AwgSAzMhTAoPCggEAAIDCJwIABIDMyJLCjcKBAQAAgQSAzYCSxoqIE91dHB1dCBvbmx5LiBM
aW5rIHRvIGRvY3VtZW50YXRpb24gcGFnZS4KCgwKBQQAAgQFEgM2AggKDAoFBAACBAESAzYJ
GgoMCgUEAAIEAxIDNh0eCgwKBQQAAgQIEgM2H0oKDwoIBAACBAicCAASAzYgSQoyCgQEAAIF
EgM5AkYaJSBPdXRwdXQgb25seS4gTGluayB0byBleHRlcm5hbCBwYWdlLgoKDAoFBAACBQUS
AzkCCAoMCgUEAAIFARIDOQkVCgwKBQQAAgUDEgM5GBkKDAoFBAACBQgSAzkaRQoPCggEAAIF
CJwIABIDORtECjgKBAQAAgYSAzwCRRorIE91dHB1dCBvbmx5LiBEZXNjcmlwdGlvbiBvZiB0
aGUgcmVzb3VyY2UuCgoMCgUEAAIGBRIDPAIICgwKBQQAAgYBEgM8CRQKDAoFBAACBgMSAzwX
GAoMCgUEAAIGCBIDPBlECg8KCAQAAgYInAgAEgM8GkMKTwoEBAACBxIDPwJNGkIgT3V0cHV0
IG9ubHkuIENsb3VkIHN0b3JhZ2UgbG9jYXRpb24gb2YgaWNvbnMgZXRjIGNvbnN1bWVkIGJ5
IFVJLgoKDAoFBAACBwUSAz8CCAoMCgUEAAIHARIDPwkcCgwKBQQAAgcDEgM/HyAKDAoFBAAC
BwgSAz8hTAoPCggEAAIHCJwIABIDPyJLCikKBAQAAggSA0ICRxocIE91dHB1dCBvbmx5LiBE
aXNwbGF5IG5hbWUuCgoMCgUEAAIIBRIDQgIICgwKBQQAAggBEgNCCRUKDAoFBAACCAMSA0IY
GgoMCgUEAAIICBIDQhtGCg8KCAQAAggInAgAEgNCHEUKUQoEBAACCRIDRQJMGkQgT3V0cHV0
IG9ubHkuIEZsYWcgdG8gbWFyayB0aGUgdmVyc2lvbiBpbmRpY2F0aW5nIHRoZSBsYXVuY2gg
c3RhZ2UuCgoMCgUEAAIJBhIDRQINCgwKBQQAAgkBEgNFDhoKDAoFBAACCQMSA0UdHwoMCgUE
AAIJCBIDRSBLCg8KCAQAAgkInAgAEgNFIUoKOQoCBAESBEkAUwEaLSBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIENvbm5lY3RvcnMuR2V0UHJvdmlkZXIuCgoKCgMEAQESA0kIGgqVAQoEBAECABIE
TQJSBBqGASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgZm9ybToKIGBwcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3Byb3ZpZGVycy8qYAogT25seSBnbG9iYWwgbG9jYXRpb24gaXMg
c3VwcG9ydGVkIGZvciBQcm92aWRlciByZXNvdXJjZS4KCgwKBQQBAgAFEgNNAggKDAoFBAEC
AAESA00JDQoMCgUEAQIAAxIDTRARCg0KBQQBAgAIEgRNElIDCg8KCAQBAgAInAgAEgNOBCoK
DwoHBAECAAifCBIETwRRBQo7CgIEAhIEVgBmARovIFJlcXVlc3QgbWVzc2FnZSBmb3IgQ29u
bmVjdG9ycy5MaXN0UHJvdmlkZXJzLgoKCgoDBAIBEgNWCBwKlwEKBAQCAgASBFoCXwQaiAEg
UmVxdWlyZWQuIFBhcmVudCByZXNvdXJjZSBvZiB0aGUgQVBJLCBvZiB0aGUgZm9ybToKIGBw
cm9qZWN0cy8qL2xvY2F0aW9ucy8qYAogT25seSBnbG9iYWwgbG9jYXRpb24gaXMgc3VwcG9y
dGVkIGZvciBQcm92aWRlciByZXNvdXJjZS4KCgwKBQQCAgAFEgNaAggKDAoFBAICAAESA1oJ
DwoMCgUEAgIAAxIDWhITCg0KBQQCAgAIEgRaFF8DCg8KCAQCAgAInAgAEgNbBCoKDwoHBAIC
AAifCBIEXAReBQoZCgQEAgIBEgNiAhYaDCBQYWdlIHNpemUuCgoMCgUEAgIBBRIDYgIHCgwK
BQQCAgEBEgNiCBEKDAoFBAICAQMSA2IUFQoaCgQEAgICEgNlAhgaDSBQYWdlIHRva2VuLgoK
DAoFBAICAgUSA2UCCAoMCgUEAgICARIDZQkTCgwKBQQCAgIDEgNlFhcKPAoCBAMSBGkAcgEa
MCBSZXNwb25zZSBtZXNzYWdlIGZvciBDb25uZWN0b3JzLkxpc3RQcm92aWRlcnMuCgoKCgME
AwESA2kIHQojCgQEAwIAEgNrAiIaFiBBIGxpc3Qgb2YgcHJvdmlkZXJzLgoKDAoFBAMCAAQS
A2sCCgoMCgUEAwIABhIDawsTCgwKBQQDAgABEgNrFB0KDAoFBAMCAAMSA2sgIQofCgQEAwIB
EgNuAh0aEiBOZXh0IHBhZ2UgdG9rZW4uCgoMCgUEAwIBBRIDbgIICgwKBQQDAgEBEgNuCRgK
DAoFBAMCAQMSA24bHAozCgQEAwICEgNxAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3Qg
YmUgcmVhY2hlZC4KCgwKBQQDAgIEEgNxAgoKDAoFBAMCAgUSA3ELEQoMCgUEAwICARIDcRId
CgwKBQQDAgIDEgNxICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Provider::Provider ===
    # Fields for Provider
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.connectors.v1.Provider.LabelsEntry)
    # Field: documentation_uri Type: 9 ()
    # Field: external_uri Type: 9 ()
    # Field: description Type: 9 ()
    # Field: web_assets_location Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: launch_stage Type: 14 (.google.cloud.connectors.v1.LaunchStage)

# === Message: Google::Cloud::Connectors::V1::Provider::GetProviderRequest ===
    # Fields for GetProviderRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Provider::ListProvidersRequest ===
    # Fields for ListProvidersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Provider::ListProvidersResponse ===
    # Fields for ListProvidersResponse
    # Field: providers Type: 11 (.google.cloud.connectors.v1.Provider)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Provider - Compiled Protocol Buffers messages for google/cloud/connectors/v1/provider.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Provider;

    my $msg = Google::Cloud::Connectors::V1::Provider::Provider->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Provider::Provider->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/provider.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Provider::Provider

Provider indicates the owner who provides the connectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the Provider.
Format: projects/{project}/locations/{location}/providers/{provider}
Only global location is supported for Provider resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Created time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Updated time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Provider::Provider::LabelsEntry>)

Output only. Resource labels to represent user-provided metadata.
Refer to cloud documentation on labels for more details.
https://cloud.google.com/compute/docs/labeling-resources

=item * C<< $msg->documentation_uri() >> / C<< $msg->documentation_uri($value) >>

Type: C<String>

Output only. Link to documentation page.

=item * C<< $msg->external_uri() >> / C<< $msg->external_uri($value) >>

Type: C<String>

Output only. Link to external page.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description of the resource.

=item * C<< $msg->web_assets_location() >> / C<< $msg->web_assets_location($value) >>

Type: C<String>

Output only. Cloud storage location of icons etc consumed by UI.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name.

=item * C<< $msg->launch_stage() >> / C<< $msg->launch_stage($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::LaunchStage>)

Output only. Flag to mark the version indicating the launch stage.

=back

=head2 Google::Cloud::Connectors::V1::Provider::GetProviderRequest

Request message for Connectors.GetProvider.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the form:
`projects/*/locations/*/providers/*`
Only global location is supported for Provider resource.

=back

=head2 Google::Cloud::Connectors::V1::Provider::ListProvidersRequest

Request message for Connectors.ListProviders.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource of the API, of the form:
`projects/*/locations/*`
Only global location is supported for Provider resource.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=back

=head2 Google::Cloud::Connectors::V1::Provider::ListProvidersResponse

Response message for Connectors.ListProviders.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->providers() >> / C<< $msg->providers($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Provider::Provider>)

A list of providers.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Provider::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
