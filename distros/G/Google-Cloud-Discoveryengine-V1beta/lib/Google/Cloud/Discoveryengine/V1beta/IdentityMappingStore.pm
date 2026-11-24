package Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::CmekConfigService };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9pZGVudGl0eV9tYXBwaW5n
X3N0b3JlLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxo9Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY21la19jb25maWdfc2Vy
dmljZS5wcm90byLBAgoUSWRlbnRpdHlNYXBwaW5nU3RvcmUSFwoEbmFtZRgBIAEoCUID4EEF
UgRuYW1lEiUKDGttc19rZXlfbmFtZRgDIAEoCUID4EEEUgprbXNLZXlOYW1lElUKC2NtZWtf
Y29uZmlnGAQgASgLMi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ21l
a0NvbmZpZ0ID4EEDUgpjbWVrQ29uZmlnOpEB6kGNAQozZGlzY292ZXJ5ZW5naW5lLmdvb2ds
ZWFwaXMuY29tL0lkZW50aXR5TWFwcGluZ1N0b3JlElZwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vaWRlbnRpdHlNYXBwaW5nU3RvcmVzL3tpZGVudGl0eV9tYXBw
aW5nX3N0b3JlfSLTAQoUSWRlbnRpdHlNYXBwaW5nRW50cnkSGQoHdXNlcl9pZBgCIAEoCUgA
UgZ1c2VySWQSGwoIZ3JvdXBfaWQYAyABKAlIAFIHZ3JvdXBJZBIwChFleHRlcm5hbF9pZGVu
dGl0eRgBIAEoCUID4EECUhBleHRlcm5hbElkZW50aXR5EjkKFmV4dGVybmFsX2lkZW50aXR5
X25hbWUYBCABKAlCA+BBAVIUZXh0ZXJuYWxJZGVudGl0eU5hbWVCFgoUaWRlbnRpdHlfcHJv
dmlkZXJfaWRCoAIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIZ
SWRlbnRpdHlNYXBwaW5nU3RvcmVQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2Nv
dmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
QmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpD
bG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKmhcKBhIEDgBWAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQARwoICgEIEgMWAEAKCQoCCCUSAxYAQAoICgEIEgMXAGgKCQoCCAsSAxcAaAoI
CgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADoKCQoCCAgSAxkAOgoICgEIEgMaAEAKCQoC
CAESAxoAQAoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMcAEAKCQoCCCkSAxwAQAoICgEI
EgMdAD8KCQoCCC0SAx0APwpNCgIEABIEIAA5ARpBIElkZW50aXR5IE1hcHBpbmcgU3RvcmUg
d2hpY2ggY29udGFpbnMgSWRlbnRpdHkgTWFwcGluZyBFbnRyaWVzLgoKCgoDBAABEgMgCBwK
CwoDBAAHEgQhAiQECg0KBQQAB50IEgQhAiQECogCCgQEAAIAEgMrAjwa+gEgSW1tdXRhYmxl
LiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBpZGVudGl0eSBtYXBwaW5nIHN0b3Jl
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9p
ZGVudGl0eU1hcHBpbmdTdG9yZXMve2lkZW50aXR5X21hcHBpbmdfc3RvcmV9YC4KIFRoaXMg
ZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGlt
aXQgb2YgMTAyNAogY2hhcmFjdGVycy4KCgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJDQoM
CgUEAAIAAxIDKxARCgwKBQQAAgAIEgMrEjsKDwoIBAACAAicCAASAysTOgrWAgoEBAACARID
NQJFGsgCIElucHV0IG9ubHkuIFRoZSBLTVMga2V5IHRvIGJlIHVzZWQgdG8gcHJvdGVjdCB0
aGlzIElkZW50aXR5IE1hcHBpbmcgU3RvcmUKIGF0IGNyZWF0aW9uIHRpbWUuCgogTXVzdCBi
ZSBzZXQgZm9yIHJlcXVlc3RzIHRoYXQgbmVlZCB0byBjb21wbHkgd2l0aCBDTUVLIE9yZyBQ
b2xpY3kKIHByb3RlY3Rpb25zLgoKIElmIHRoaXMgZmllbGQgaXMgc2V0IGFuZCBwcm9jZXNz
ZWQgc3VjY2Vzc2Z1bGx5LCB0aGUgSWRlbnRpdHkgTWFwcGluZyBTdG9yZQogd2lsbCBiZSBw
cm90ZWN0ZWQgYnkgdGhlIEtNUyBrZXksIGFzIGluZGljYXRlZCBpbiB0aGUgY21la19jb25m
aWcgZmllbGQuCgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1CRUKDAoFBAACAQMSAzUYGQoM
CgUEAAIBCBIDNRpECg8KCAQAAgEInAgAEgM1G0MKVAoEBAACAhIDOAJJGkcgT3V0cHV0IG9u
bHkuIENNRUstcmVsYXRlZCBpbmZvcm1hdGlvbiBmb3IgdGhlIElkZW50aXR5IE1hcHBpbmcg
U3RvcmUuCgoMCgUEAAICBhIDOAIMCgwKBQQAAgIBEgM4DRgKDAoFBAACAgMSAzgbHAoMCgUE
AAICCBIDOB1ICg8KCAQAAgIInAgAEgM4HkcKXQoCBAESBD0AVgEaUSBJZGVudGl0eSBNYXBw
aW5nIEVudHJ5IHRoYXQgbWFwcyBhbiBleHRlcm5hbCBpZGVudGl0eSB0byBhbiBpbnRlcm5h
bAogaWRlbnRpdHkuCgoKCgMEAQESAz0IHAphCgQEAQgAEgRAAk4DGlMgVW5pb24gZmllbGQg
aWRlbnRpdHlfcHJvdmlkZXJfaWQuIElkZW50aXR5IFByb3ZpZGVyIGlkIGNhbiBiZSBhIHVz
ZXIgb3IgYQogZ3JvdXAuCgoMCgUEAQgAARIDQAgcCu4BCgQEAQIAEgNGBBca4AEgVXNlciBp
ZGVudGlmaWVyLgogRm9yIEdvb2dsZSBXb3Jrc3BhY2UgdXNlciBhY2NvdW50LCB1c2VyX2lk
IHNob3VsZCBiZSB0aGUgZ29vZ2xlIHdvcmtzcGFjZQogdXNlciBlbWFpbC4KIEZvciBub24t
Z29vZ2xlIGlkZW50aXR5IHByb3ZpZGVyLCB1c2VyX2lkIGlzIHRoZSBtYXBwZWQgdXNlciBp
ZGVudGlmaWVyCiBjb25maWd1cmVkIGR1cmluZyB0aGUgd29ya2ZvcmNlcG9vbCBjb25maWcu
CgoMCgUEAQIABRIDRgQKCgwKBQQBAgABEgNGCxIKDAoFBAECAAMSA0YVFgrzAQoEBAECARID
TQQYGuUBIEdyb3VwIGlkZW50aWZpZXIuCiBGb3IgR29vZ2xlIFdvcmtzcGFjZSB1c2VyIGFj
Y291bnQsIGdyb3VwX2lkIHNob3VsZCBiZSB0aGUgZ29vZ2xlCiB3b3Jrc3BhY2UgZ3JvdXAg
ZW1haWwuCiBGb3Igbm9uLWdvb2dsZSBpZGVudGl0eSBwcm92aWRlciwgZ3JvdXBfaWQgaXMg
dGhlIG1hcHBlZCBncm91cCBpZGVudGlmaWVyCiBjb25maWd1cmVkIGR1cmluZyB0aGUgd29y
a2ZvcmNlcG9vbCBjb25maWcuCgoMCgUEAQIBBRIDTQQKCgwKBQQBAgEBEgNNCxMKDAoFBAEC
AQMSA00WFwqLAQoEBAECAhIDUgJIGn4gUmVxdWlyZWQuIElkZW50aXR5IG91dHNpZGUgdGhl
IGN1c3RvbWVyIGlkZW50aXR5IHByb3ZpZGVyLgogVGhlIGxlbmd0aCBsaW1pdCBvZiBleHRl
cm5hbCBpZGVudGl0eSB3aWxsIGJlIG9mIDEwMCBjaGFyYWN0ZXJzLgoKDAoFBAECAgUSA1IC
CAoMCgUEAQICARIDUgkaCgwKBQQBAgIDEgNSHR4KDAoFBAECAggSA1IfRwoPCggEAQICCJwI
ABIDUiBGCjsKBAQBAgMSA1UCTRouIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgZXh0ZXJu
YWwgaWRlbnRpdHkuCgoMCgUEAQIDBRIDVQIICgwKBQQBAgMBEgNVCR8KDAoFBAECAwMSA1Ui
IwoMCgUEAQIDCBIDVSRMCg8KCAQBAgMInAgAEgNVJUtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore ===
    # Fields for IdentityMappingStore
    # Field: name Type: 9 ()
    # Field: kms_key_name Type: 9 ()
    # Field: cmek_config Type: 11 (.google.cloud.discoveryengine.v1beta.CmekConfig)

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingEntry ===
    # Fields for IdentityMappingEntry
    # Field: user_id Type: 9 ()
    # Field: group_id Type: 9 ()
    # Field: external_identity Type: 9 ()
    # Field: external_identity_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/identity_mapping_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore;

    my $msg = Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore->new({
        name => $name,
        kms_key_name => $kms_key_name,
        cmek_config => $cmek_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/identity_mapping_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig>)

Output only. CMEK-related information for the Identity Mapping Store.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingEntry

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
