package Google::Cloud::Oracledatabase::V1::DbVersion;

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
Ci9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfdmVyc2lvbi5wcm90bxIeZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIoYCCglEYlZlcnNpb24SFwoEbmFt
ZRgBIAEoCUID4EEDUgRuYW1lElgKCnByb3BlcnRpZXMYAiABKAsyMy5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuRGJWZXJzaW9uUHJvcGVydGllc0ID4EEDUgpwcm9wZXJ0aWVz
OoUB6kGBAQonb3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRGJWZXJzaW9uEj9wcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGJWZXJzaW9ucy97ZGJfdmVy
c2lvbn0qCmRiVmVyc2lvbnMyCWRiVmVyc2lvbiKOAgoTRGJWZXJzaW9uUHJvcGVydGllcxId
Cgd2ZXJzaW9uGAEgASgJQgPgQQNSB3ZlcnNpb24SQQobaXNfbGF0ZXN0X2Zvcl9tYWpvcl92
ZXJzaW9uGAIgASgIQgPgQQNSF2lzTGF0ZXN0Rm9yTWFqb3JWZXJzaW9uEiYKDHN1cHBvcnRz
X3BkYhgDIAEoCEID4EEDUgtzdXBwb3J0c1BkYhI2ChVpc19wcmV2aWV3X2RiX3ZlcnNpb24Y
BCABKAhCA+BBA1ISaXNQcmV2aWV3RGJWZXJzaW9uEjUKFGlzX3VwZ3JhZGVfc3VwcG9ydGVk
GAUgASgIQgPgQQNSEmlzVXBncmFkZVN1cHBvcnRlZCLDAQoVTGlzdERiVmVyc2lvbnNSZXF1
ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC+kEpEidvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlz
LmNvbS9EYlZlcnNpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNp
emUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJ
QgPgQQFSBmZpbHRlciKMAQoWTGlzdERiVmVyc2lvbnNSZXNwb25zZRJKCgtkYl92ZXJzaW9u
cxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYlZlcnNpb25SCmRi
VmVyc2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuQugBCiJj
b20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxQg5EYlZlcnNpb25Qcm90b1ABWkpj
bG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNl
cGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoC
Hkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNs
ZURhdGFiYXNlOjpWMUqYHAoGEgQOAGkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUS
AxUAOwoICgEIEgMWAGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMY
AC8KCQoCCAgSAxgALwoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoA
OwoICgEIEgMbADoKCQoCCC0SAxsAOgouCgIEABIEHgAtARoiIEEgdmFsaWQgT3JhY2xlIERh
dGFiYXNlIHZlcnNpb24uCgoKCgMEAAESAx4IEQoLCgMEAAcSBB8CJAQKDQoFBAAHnQgSBB8C
JAQKlwEKBAQAAgASAygCPhqJASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIERiVmVy
c2lvbiByZXNvdXJjZSBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0vZGJWZXJzaW9ucy97ZGJfdmVyc2lvbn0KCgwKBQQA
AgAFEgMoAggKDAoFBAACAAESAygJDQoMCgUEAAIAAxIDKBARCgwKBQQAAgAIEgMoEj0KDwoI
BAACAAicCAASAygTPAo9CgQEAAIBEgQrAiwyGi8gT3V0cHV0IG9ubHkuIFRoZSBwcm9wZXJ0
aWVzIG9mIHRoZSBEYlZlcnNpb24uCgoMCgUEAAIBBhIDKwIVCgwKBQQAAgEBEgMrFiAKDAoF
BAACAQMSAysjJAoMCgUEAAIBCBIDLAYxCg8KCAQAAgEInAgAEgMsBzAKLAoCBAESBDAARAEa
ICBUaGUgcHJvcGVydGllcyBvZiBhIERiVmVyc2lvbi4KCgoKAwQBARIDMAgbCjwKBAQBAgAS
AzICQRovIE91dHB1dCBvbmx5LiBBIHZhbGlkIE9yYWNsZSBEYXRhYmFzZSB2ZXJzaW9uLgoK
DAoFBAECAAUSAzICCAoMCgUEAQIAARIDMgkQCgwKBQQBAgADEgMyExQKDAoFBAECAAgSAzIV
QAoPCggEAQIACJwIABIDMhY/CncKBAQBAgESBDYCNzIaaSBPdXRwdXQgb25seS4gVHJ1ZSBp
ZiB0aGlzIHZlcnNpb24gb2YgdGhlIE9yYWNsZSBEYXRhYmFzZSBzb2Z0d2FyZSBpcyB0aGUK
IGxhdGVzdCB2ZXJzaW9uIGZvciBhIHJlbGVhc2UuCgoMCgUEAQIBBRIDNgIGCgwKBQQBAgEB
EgM2ByIKDAoFBAECAQMSAzYlJgoMCgUEAQIBCBIDNwYxCg8KCAQBAgEInAgAEgM3BzAKbwoE
BAECAhIDOwJEGmIgT3V0cHV0IG9ubHkuIFRydWUgaWYgdGhpcyB2ZXJzaW9uIG9mIHRoZSBP
cmFjbGUgRGF0YWJhc2Ugc29mdHdhcmUgc3VwcG9ydHMKIHBsdWdnYWJsZSBkYXRhYmFzZXMu
CgoMCgUEAQICBRIDOwIGCgwKBQQBAgIBEgM7BxMKDAoFBAECAgMSAzsWFwoMCgUEAQICCBID
OxhDCg8KCAQBAgIInAgAEgM7GUIKaQoEBAECAxIDPwJNGlwgT3V0cHV0IG9ubHkuIFRydWUg
aWYgdGhpcyB2ZXJzaW9uIG9mIHRoZSBPcmFjbGUgRGF0YWJhc2Ugc29mdHdhcmUgaXMgdGhl
CiBwcmV2aWV3IHZlcnNpb24uCgoMCgUEAQIDBRIDPwIGCgwKBQQBAgMBEgM/BxwKDAoFBAEC
AwMSAz8fIAoMCgUEAQIDCBIDPyFMCg8KCAQBAgMInAgAEgM/IksKawoEBAECBBIDQwJMGl4g
T3V0cHV0IG9ubHkuIFRydWUgaWYgdGhpcyB2ZXJzaW9uIG9mIHRoZSBPcmFjbGUgRGF0YWJh
c2Ugc29mdHdhcmUgaXMKIHN1cHBvcnRlZCBmb3IgVXBncmFkZS4KCgwKBQQBAgQFEgNDAgYK
DAoFBAECBAESA0MHGwoMCgUEAQIEAxIDQx4fCgwKBQQBAgQIEgNDIEsKDwoIBAECBAicCAAS
A0MhSgowCgIEAhIERwBgARokIFRoZSByZXF1ZXN0IGZvciBgRGJWZXJzaW9ucy5MaXN0YC4K
CgoKAwQCARIDRwgdCn8KBAQCAgASBEoCTwQacSBSZXF1aXJlZC4gVGhlIHBhcmVudCB2YWx1
ZSBmb3IgdGhlIERiVmVyc2lvbiByZXNvdXJjZSB3aXRoIHRoZQogZm9ybWF0OiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQCAgAFEgNKAggKDAoFBAIC
AAESA0oJDwoMCgUEAgIAAxIDShITCg0KBQQCAgAIEgRKFE8DCg8KCAQCAgAInAgAEgNLBCoK
DwoHBAICAAifCBIETAROBQrDAQoEBAICARIDVAI/GrUBIE9wdGlvbmFsLiBUaGUgbWF4aW11
bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgogSWYgdW5zcGVjaWZpZWQsIGEgbWF4aW11
bSBvZiA1MCBEYlZlcnNpb25zIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1
ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIHJlc2V0IHRvIDEwMDAuCgoM
CgUEAgIBBRIDVAIHCgwKBQQCAgEBEgNUCBEKDAoFBAICAQMSA1QUFQoMCgUEAgIBCBIDVBY+
Cg8KCAQCAgEInAgAEgNUFz0KvQEKBAQCAgISA1kCQRqvASBPcHRpb25hbC4gQSB0b2tlbiBp
ZGVudGlmeWluZyB0aGUgcmVxdWVzdGVkIHBhZ2Ugb2YgcmVzdWx0cyB0byByZXR1cm4uIEFs
bAogZmllbGRzIGV4Y2VwdCB0aGUgZmlsdGVyIHNob3VsZCByZW1haW4gdGhlIHNhbWUgYXMg
aW4gdGhlIHJlcXVlc3QgdGhhdAogcHJvdmlkZWQgdGhpcyBwYWdlIHRva2VuLgoKDAoFBAIC
AgUSA1kCCAoMCgUEAgICARIDWQkTCgwKBQQCAgIDEgNZFhcKDAoFBAICAggSA1kYQAoPCggE
AgICCJwIABIDWRk/Cp0CCgQEAgIDEgNfAj0ajwIgT3B0aW9uYWwuIEZpbHRlciBleHByZXNz
aW9uIHRoYXQgbWF0Y2hlcyBhIHN1YnNldCBvZiB0aGUgRGJWZXJzaW9ucyB0bwogc2hvdy4g
VGhlIHN1cHBvcnRlZCBmaWx0ZXIgZm9yIGRiU3lzdGVtIGNyZWF0aW9uIGlzIGBkYl9zeXN0
ZW1fc2hhcGUgPQoge2RiX3N5c3RlbV9zaGFwZX0gQU5EIHN0b3JhZ2VfbWFuYWdlbWVudCA9
IHtzdG9yYWdlX21hbmFnZW1lbnR9YC4gSWYgbm8KIGZpbHRlciBpcyBwcm92aWRlZCwgYWxs
IERiVmVyc2lvbnMgd2lsbCBiZSByZXR1cm5lZC4KCgwKBQQCAgMFEgNfAggKDAoFBAICAwES
A18JDwoMCgUEAgIDAxIDXxITCgwKBQQCAgMIEgNfFDwKDwoIBAICAwicCAASA18VOwoxCgIE
AxIEYwBpARolIFRoZSByZXNwb25zZSBmb3IgYERiVmVyc2lvbnMuTGlzdGAuCgoKCgMEAwES
A2MIHgomCgQEAwIAEgNlAiUaGSBUaGUgbGlzdCBvZiBEYlZlcnNpb25zLgoKDAoFBAMCAAQS
A2UCCgoMCgUEAwIABhIDZQsUCgwKBQQDAgABEgNlFSAKDAoFBAMCAAMSA2UjJApOCgQEAwIB
EgNoAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2
ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQDAgEFEgNoAggKDAoFBAMCAQESA2gJGAoMCgUEAwIB
AxIDaBscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion ===
    # Fields for DbVersion
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.DbVersionProperties)

# === Message: Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties ===
    # Fields for DbVersionProperties
    # Field: version Type: 9 ()
    # Field: is_latest_for_major_version Type: 8 ()
    # Field: supports_pdb Type: 8 ()
    # Field: is_preview_db_version Type: 8 ()
    # Field: is_upgrade_supported Type: 8 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsRequest ===
    # Fields for ListDbVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsResponse ===
    # Fields for ListDbVersionsResponse
    # Field: db_versions Type: 11 (.google.cloud.oracledatabase.v1.DbVersion)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbVersion - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbVersion;

    my $msg = Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion->new({
        name => $name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion

A valid Oracle Database version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the DbVersion resource in the following format:
projects/{project}/locations/{region}/dbVersions/{db_version}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties>)

Output only. The properties of the DbVersion.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties

The properties of a DbVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Output only. A valid Oracle Database version.

=item * C<< $msg->is_latest_for_major_version() >> / C<< $msg->is_latest_for_major_version($value) >>

Type: C<Bool>

Output only. True if this version of the Oracle Database software is the
latest version for a release.

=item * C<< $msg->supports_pdb() >> / C<< $msg->supports_pdb($value) >>

Type: C<Bool>

Output only. True if this version of the Oracle Database software supports
pluggable databases.

=item * C<< $msg->is_preview_db_version() >> / C<< $msg->is_preview_db_version($value) >>

Type: C<Bool>

Output only. True if this version of the Oracle Database software is the
preview version.

=item * C<< $msg->is_upgrade_supported() >> / C<< $msg->is_upgrade_supported($value) >>

Type: C<Bool>

Output only. True if this version of the Oracle Database software is
supported for Upgrade.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsRequest

The request for `DbVersions.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the DbVersion resource with the
format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, a maximum of 50 DbVersions will be returned.
The maximum value is 1000; values above 1000 will be reset to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the requested page of results to return. All
fields except the filter should remain the same as in the request that
provided this page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression that matches a subset of the DbVersions to
show. The supported filter for dbSystem creation is `db_system_shape =
{db_system_shape} AND storage_management = {storage_management}`. If no
filter is provided, all DbVersions will be returned.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsResponse

The response for `DbVersions.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->db_versions() >> / C<< $msg->db_versions($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion>)

The list of DbVersions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
