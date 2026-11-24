package Google::Cloud::Discoveryengine::V1::IdentityMappingStore;

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
    eval { require Google::Cloud::Discoveryengine::V1::CmekConfigService };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2lkZW50aXR5X21hcHBpbmdfc3Rv
cmUucHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOWdvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvY21la19jb25maWdfc2VydmljZS5wcm90byK9
AgoUSWRlbnRpdHlNYXBwaW5nU3RvcmUSFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEiUKDGtt
c19rZXlfbmFtZRgDIAEoCUID4EEEUgprbXNLZXlOYW1lElEKC2NtZWtfY29uZmlnGAQgASgL
MisuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DbWVrQ29uZmlnQgPgQQNSCmNt
ZWtDb25maWc6kQHqQY0BCjNkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vSWRlbnRp
dHlNYXBwaW5nU3RvcmUSVnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9pZGVudGl0eU1hcHBpbmdTdG9yZXMve2lkZW50aXR5X21hcHBpbmdfc3RvcmV9ItMBChRJ
ZGVudGl0eU1hcHBpbmdFbnRyeRIZCgd1c2VyX2lkGAIgASgJSABSBnVzZXJJZBIbCghncm91
cF9pZBgDIAEoCUgAUgdncm91cElkEjAKEWV4dGVybmFsX2lkZW50aXR5GAEgASgJQgPgQQJS
EGV4dGVybmFsSWRlbnRpdHkSOQoWZXh0ZXJuYWxfaWRlbnRpdHlfbmFtZRgEIAEoCUID4EEB
UhRleHRlcm5hbElkZW50aXR5TmFtZUIWChRpZGVudGl0eV9wcm92aWRlcl9pZEKMAgojY29t
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCGUlkZW50aXR5TWFwcGluZ1N0b3Jl
UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9H
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVy
eUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFKmhcKBhIE
DgBWAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAQwoICgEIEgMWADwKCQoCCCUSAxYAPAoICgEI
EgMXAGQKCQoCCAsSAxcAZAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADoKCQoCCAgS
AxkAOgoICgEIEgMaADwKCQoCCAESAxoAPAoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMc
ADwKCQoCCCkSAxwAPAoICgEIEgMdADsKCQoCCC0SAx0AOwpNCgIEABIEIAA5ARpBIElkZW50
aXR5IE1hcHBpbmcgU3RvcmUgd2hpY2ggY29udGFpbnMgSWRlbnRpdHkgTWFwcGluZyBFbnRy
aWVzLgoKCgoDBAABEgMgCBwKCwoDBAAHEgQhAiQECg0KBQQAB50IEgQhAiQECogCCgQEAAIA
EgMrAjwa+gEgSW1tdXRhYmxlLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBpZGVu
dGl0eSBtYXBwaW5nIHN0b3JlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9pZGVudGl0eU1hcHBpbmdTdG9yZXMve2lkZW50aXR5X21hcHBp
bmdfc3RvcmV9YC4KIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5n
IHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTAyNAogY2hhcmFjdGVycy4KCgwKBQQAAgAFEgMr
AggKDAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCgwKBQQAAgAIEgMrEjsKDwoIBAACAAic
CAASAysTOgrWAgoEBAACARIDNQJFGsgCIElucHV0IG9ubHkuIFRoZSBLTVMga2V5IHRvIGJl
IHVzZWQgdG8gcHJvdGVjdCB0aGlzIElkZW50aXR5IE1hcHBpbmcgU3RvcmUKIGF0IGNyZWF0
aW9uIHRpbWUuCgogTXVzdCBiZSBzZXQgZm9yIHJlcXVlc3RzIHRoYXQgbmVlZCB0byBjb21w
bHkgd2l0aCBDTUVLIE9yZyBQb2xpY3kKIHByb3RlY3Rpb25zLgoKIElmIHRoaXMgZmllbGQg
aXMgc2V0IGFuZCBwcm9jZXNzZWQgc3VjY2Vzc2Z1bGx5LCB0aGUgSWRlbnRpdHkgTWFwcGlu
ZyBTdG9yZQogd2lsbCBiZSBwcm90ZWN0ZWQgYnkgdGhlIEtNUyBrZXksIGFzIGluZGljYXRl
ZCBpbiB0aGUgY21la19jb25maWcgZmllbGQuCgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1
CRUKDAoFBAACAQMSAzUYGQoMCgUEAAIBCBIDNRpECg8KCAQAAgEInAgAEgM1G0MKVAoEBAAC
AhIDOAJJGkcgT3V0cHV0IG9ubHkuIENNRUstcmVsYXRlZCBpbmZvcm1hdGlvbiBmb3IgdGhl
IElkZW50aXR5IE1hcHBpbmcgU3RvcmUuCgoMCgUEAAICBhIDOAIMCgwKBQQAAgIBEgM4DRgK
DAoFBAACAgMSAzgbHAoMCgUEAAICCBIDOB1ICg8KCAQAAgIInAgAEgM4HkcKXQoCBAESBD0A
VgEaUSBJZGVudGl0eSBNYXBwaW5nIEVudHJ5IHRoYXQgbWFwcyBhbiBleHRlcm5hbCBpZGVu
dGl0eSB0byBhbiBpbnRlcm5hbAogaWRlbnRpdHkuCgoKCgMEAQESAz0IHAphCgQEAQgAEgRA
Ak4DGlMgVW5pb24gZmllbGQgaWRlbnRpdHlfcHJvdmlkZXJfaWQuIElkZW50aXR5IFByb3Zp
ZGVyIGlkIGNhbiBiZSBhIHVzZXIgb3IgYQogZ3JvdXAuCgoMCgUEAQgAARIDQAgcCu4BCgQE
AQIAEgNGBBca4AEgVXNlciBpZGVudGlmaWVyLgogRm9yIEdvb2dsZSBXb3Jrc3BhY2UgdXNl
ciBhY2NvdW50LCB1c2VyX2lkIHNob3VsZCBiZSB0aGUgZ29vZ2xlIHdvcmtzcGFjZQogdXNl
ciBlbWFpbC4KIEZvciBub24tZ29vZ2xlIGlkZW50aXR5IHByb3ZpZGVyLCB1c2VyX2lkIGlz
IHRoZSBtYXBwZWQgdXNlciBpZGVudGlmaWVyCiBjb25maWd1cmVkIGR1cmluZyB0aGUgd29y
a2ZvcmNlcG9vbCBjb25maWcuCgoMCgUEAQIABRIDRgQKCgwKBQQBAgABEgNGCxIKDAoFBAEC
AAMSA0YVFgrzAQoEBAECARIDTQQYGuUBIEdyb3VwIGlkZW50aWZpZXIuCiBGb3IgR29vZ2xl
IFdvcmtzcGFjZSB1c2VyIGFjY291bnQsIGdyb3VwX2lkIHNob3VsZCBiZSB0aGUgZ29vZ2xl
CiB3b3Jrc3BhY2UgZ3JvdXAgZW1haWwuCiBGb3Igbm9uLWdvb2dsZSBpZGVudGl0eSBwcm92
aWRlciwgZ3JvdXBfaWQgaXMgdGhlIG1hcHBlZCBncm91cCBpZGVudGlmaWVyCiBjb25maWd1
cmVkIGR1cmluZyB0aGUgd29ya2ZvcmNlcG9vbCBjb25maWcuCgoMCgUEAQIBBRIDTQQKCgwK
BQQBAgEBEgNNCxMKDAoFBAECAQMSA00WFwqLAQoEBAECAhIDUgJIGn4gUmVxdWlyZWQuIElk
ZW50aXR5IG91dHNpZGUgdGhlIGN1c3RvbWVyIGlkZW50aXR5IHByb3ZpZGVyLgogVGhlIGxl
bmd0aCBsaW1pdCBvZiBleHRlcm5hbCBpZGVudGl0eSB3aWxsIGJlIG9mIDEwMCBjaGFyYWN0
ZXJzLgoKDAoFBAECAgUSA1ICCAoMCgUEAQICARIDUgkaCgwKBQQBAgIDEgNSHR4KDAoFBAEC
AggSA1IfRwoPCggEAQICCJwIABIDUiBGCjsKBAQBAgMSA1UCTRouIE9wdGlvbmFsLiBUaGUg
bmFtZSBvZiB0aGUgZXh0ZXJuYWwgaWRlbnRpdHkuCgoMCgUEAQIDBRIDVQIICgwKBQQBAgMB
EgNVCR8KDAoFBAECAwMSA1UiIwoMCgUEAQIDCBIDVSRMCg8KCAQBAgMInAgAEgNVJUtiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore ===
    # Fields for IdentityMappingStore
    # Field: name Type: 9 ()
    # Field: kms_key_name Type: 9 ()
    # Field: cmek_config Type: 11 (.google.cloud.discoveryengine.v1.CmekConfig)

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry ===
    # Fields for IdentityMappingEntry
    # Field: user_id Type: 9 ()
    # Field: group_id Type: 9 ()
    # Field: external_identity Type: 9 ()
    # Field: external_identity_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::IdentityMappingStore - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/identity_mapping_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::IdentityMappingStore;

    my $msg = Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore->new({
        name => $name,
        kms_key_name => $kms_key_name,
        cmek_config => $cmek_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/identity_mapping_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore

Identity Mapping Store which contains Identity Mapping Entries.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the identity mapping store.
Format:
`projects/{project}/locations/{location}/identityMappingStores/{identity_mapping_store}`.
This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

Input only. The KMS key to be used to protect this Identity Mapping Store
at creation time.

Must be set for requests that need to comply with CMEK Org Policy
protections.

If this field is set and processed successfully, the Identity Mapping Store
will be protected by the KMS key, as indicated in the cmek_config field.

=item * C<< $msg->cmek_config() >> / C<< $msg->cmek_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig>)

Output only. CMEK-related information for the Identity Mapping Store.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry

Identity Mapping Entry that maps an external identity to an internal
identity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_id() >> / C<< $msg->user_id($value) >>

Type: C<String>

User identifier.
For Google Workspace user account, user_id should be the google workspace
user email.
For non-google identity provider, user_id is the mapped user identifier
configured during the workforcepool config.

=item * C<< $msg->group_id() >> / C<< $msg->group_id($value) >>

Type: C<String>

Group identifier.
For Google Workspace user account, group_id should be the google
workspace group email.
For non-google identity provider, group_id is the mapped group identifier
configured during the workforcepool config.

=item * C<< $msg->external_identity() >> / C<< $msg->external_identity($value) >>

Type: C<String>

Required. Identity outside the customer identity provider.
The length limit of external identity will be of 100 characters.

=item * C<< $msg->external_identity_name() >> / C<< $msg->external_identity_name($value) >>

Type: C<String>

Optional. The name of the external identity.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
