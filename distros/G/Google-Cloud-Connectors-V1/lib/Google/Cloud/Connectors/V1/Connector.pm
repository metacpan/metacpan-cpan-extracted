package Google::Cloud::Connectors::V1::Connector;

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
Cipnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb25uZWN0b3IucHJvdG8SGmdvb2dsZS5j
bG91ZC5jb25uZWN0b3JzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9j
b21tb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i4QUKCUNvbm5l
Y3RvchIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
TgoGbGFiZWxzGAQgAygLMjEuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQ29ubmVjdG9y
LkxhYmVsc0VudHJ5QgPgQQNSBmxhYmVscxIwChFkb2N1bWVudGF0aW9uX3VyaRgGIAEoCUID
4EEDUhBkb2N1bWVudGF0aW9uVXJpEiYKDGV4dGVybmFsX3VyaRgHIAEoCUID4EEDUgtleHRl
cm5hbFVyaRIlCgtkZXNjcmlwdGlvbhgIIAEoCUID4EEDUgtkZXNjcmlwdGlvbhIzChN3ZWJf
YXNzZXRzX2xvY2F0aW9uGAkgASgJQgPgQQNSEXdlYkFzc2V0c0xvY2F0aW9uEiYKDGRpc3Bs
YXlfbmFtZRgKIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJPCgxsYXVuY2hfc3RhZ2UYCyABKA4y
Jy5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5MYXVuY2hTdGFnZUID4EEDUgtsYXVuY2hT
dGFnZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBOn3qQXoKI2Nvbm5lY3RvcnMuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdG9yElNw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJvdmlkZXJzL3twcm92
aWRlcn0vY29ubmVjdG9ycy97Y29ubmVjdG9yfSJWChNHZXRDb25uZWN0b3JSZXF1ZXN0Ej8K
BG5hbWUYASABKAlCK+BBAvpBJQojY29ubmVjdG9ycy5nb29nbGVhcGlzLmNvbS9Db25uZWN0
b3JSBG5hbWUilwEKFUxpc3RDb25uZWN0b3JzUmVxdWVzdBJCCgZwYXJlbnQYASABKAlCKuBB
AvpBJAoiY29ubmVjdG9ycy5nb29nbGVhcGlzLmNvbS9Qcm92aWRlclIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
IqkBChZMaXN0Q29ubmVjdG9yc1Jlc3BvbnNlEkUKCmNvbm5lY3RvcnMYASADKAsyJS5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5Db25uZWN0b3JSCmNvbm5lY3RvcnMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1
bnJlYWNoYWJsZUJyCh5jb20uZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjFCDkNvbm5lY3Rv
clByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vY29ubmVjdG9ycy9hcGl2MS9jb25uZWN0
b3JzcGI7Y29ubmVjdG9yc3BiSqIcCgYSBA4AcwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADEK
CQoCAwMSAxUAKQoICgEIEgMXAFUKCQoCCAsSAxcAVQoICgEIEgMYACIKCQoCCAoSAxgAIgoI
CgEIEgMZAC8KCQoCCAgSAxkALwoICgEIEgMaADcKCQoCCAESAxoANwpXCgIEABIEHQBHARpL
IENvbm5lY3RvcnMgaW5kaWNhdGVzIGEgc3BlY2lmaWMgY29ubmVjdG9yIHR5cGUsIGUueC4g
U2FsZXNmb3JjZSwgU0FQIGV0Yy4KCgoKAwQAARIDHQgRCgsKAwQABxIEHgIhBAoNCgUEAAed
CBIEHgIhBArVAQoEBAACABIDJwI+GscBIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9m
IHRoZSBDb25uZWN0b3IuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcHJvdmlkZXJzL3twcm92aWRlcn0vY29ubmVjdG9ycy97Y29ubmVjdG9y
fQogT25seSBnbG9iYWwgbG9jYXRpb24gaXMgc3VwcG9ydGVkIGZvciBDb25uZWN0b3IgcmVz
b3VyY2UuCgoMCgUEAAIABRIDJwIICgwKBQQAAgABEgMnCQ0KDAoFBAACAAMSAycQEQoMCgUE
AAIACBIDJxI9Cg8KCAQAAgAInAgAEgMnEzwKKgoEBAACARIEKgIrMhocIE91dHB1dCBvbmx5
LiBDcmVhdGVkIHRpbWUuCgoMCgUEAAIBBhIDKgIbCgwKBQQAAgEBEgMqHCcKDAoFBAACAQMS
AyoqKwoMCgUEAAIBCBIDKwYxCg8KCAQAAgEInAgAEgMrBzAKKgoEBAACAhIELgIvMhocIE91
dHB1dCBvbmx5LiBVcGRhdGVkIHRpbWUuCgoMCgUEAAICBhIDLgIbCgwKBQQAAgIBEgMuHCcK
DAoFBAACAgMSAy4qKwoMCgUEAAICCBIDLwYxCg8KCAQAAgIInAgAEgMvBzAKxQEKBAQAAgMS
AzQCTRq3ASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbGFiZWxzIHRvIHJlcHJlc2VudCB1c2Vy
LXByb3ZpZGVkIG1ldGFkYXRhLgogUmVmZXIgdG8gY2xvdWQgZG9jdW1lbnRhdGlvbiBvbiBs
YWJlbHMgZm9yIG1vcmUgZGV0YWlscy4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21w
dXRlL2RvY3MvbGFiZWxpbmctcmVzb3VyY2VzCgoMCgUEAAIDBhIDNAIVCgwKBQQAAgMBEgM0
FhwKDAoFBAACAwMSAzQfIAoMCgUEAAIDCBIDNCFMCg8KCAQAAgMInAgAEgM0IksKNwoEBAAC
BBIDNwJLGiogT3V0cHV0IG9ubHkuIExpbmsgdG8gZG9jdW1lbnRhdGlvbiBwYWdlLgoKDAoF
BAACBAUSAzcCCAoMCgUEAAIEARIDNwkaCgwKBQQAAgQDEgM3HR4KDAoFBAACBAgSAzcfSgoP
CggEAAIECJwIABIDNyBJCjIKBAQAAgUSAzoCRholIE91dHB1dCBvbmx5LiBMaW5rIHRvIGV4
dGVybmFsIHBhZ2UuCgoMCgUEAAIFBRIDOgIICgwKBQQAAgUBEgM6CRUKDAoFBAACBQMSAzoY
GQoMCgUEAAIFCBIDOhpFCg8KCAQAAgUInAgAEgM6G0QKOAoEBAACBhIDPQJFGisgT3V0cHV0
IG9ubHkuIERlc2NyaXB0aW9uIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQAAgYFEgM9AggKDAoF
BAACBgESAz0JFAoMCgUEAAIGAxIDPRcYCgwKBQQAAgYIEgM9GUQKDwoIBAACBgicCAASAz0a
QwpPCgQEAAIHEgNAAk0aQiBPdXRwdXQgb25seS4gQ2xvdWQgc3RvcmFnZSBsb2NhdGlvbiBv
ZiBpY29ucyBldGMgY29uc3VtZWQgYnkgVUkuCgoMCgUEAAIHBRIDQAIICgwKBQQAAgcBEgNA
CRwKDAoFBAACBwMSA0AfIAoMCgUEAAIHCBIDQCFMCg8KCAQAAgcInAgAEgNAIksKKQoEBAAC
CBIDQwJHGhwgT3V0cHV0IG9ubHkuIERpc3BsYXkgbmFtZS4KCgwKBQQAAggFEgNDAggKDAoF
BAACCAESA0MJFQoMCgUEAAIIAxIDQxgaCgwKBQQAAggIEgNDG0YKDwoIBAACCAicCAASA0Mc
RQpRCgQEAAIJEgNGAkwaRCBPdXRwdXQgb25seS4gRmxhZyB0byBtYXJrIHRoZSB2ZXJzaW9u
IGluZGljYXRpbmcgdGhlIGxhdW5jaCBzdGFnZS4KCgwKBQQAAgkGEgNGAg0KDAoFBAACCQES
A0YOGgoMCgUEAAIJAxIDRh0fCgwKBQQAAgkIEgNGIEsKDwoIBAACCQicCAASA0YhSgo6CgIE
ARIESgBUARouIFJlcXVlc3QgbWVzc2FnZSBmb3IgQ29ubmVjdG9ycy5HZXRDb25uZWN0b3Iu
CgoKCgMEAQESA0oIGwqjAQoEBAECABIETgJTBBqUASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFt
ZSBvZiB0aGUgZm9ybToKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Byb3ZpZGVycy8qL2Nv
bm5lY3RvcnMvKmAKIE9ubHkgZ2xvYmFsIGxvY2F0aW9uIGlzIHN1cHBvcnRlZCBmb3IgQ29u
bmVjdG9yIHJlc291cmNlLgoKDAoFBAECAAUSA04CCAoMCgUEAQIAARIDTgkNCgwKBQQBAgAD
EgNOEBEKDQoFBAECAAgSBE4SUwMKDwoIBAECAAicCAASA08EKgoPCgcEAQIACJ8IEgRQBFIF
CjwKAgQCEgRXAGcBGjAgUmVxdWVzdCBtZXNzYWdlIGZvciBDb25uZWN0b3JzLkxpc3RDb25u
ZWN0b3JzLgoKCgoDBAIBEgNXCB0KqwEKBAQCAgASBFsCYAQanAEgUmVxdWlyZWQuIFBhcmVu
dCByZXNvdXJjZSBvZiB0aGUgY29ubmVjdG9ycywgb2YgdGhlIGZvcm06CiBgcHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9wcm92aWRlcnMvKmAKIE9ubHkgZ2xvYmFsIGxvY2F0aW9uIGlzIHN1
cHBvcnRlZCBmb3IgQ29ubmVjdG9yIHJlc291cmNlLgoKDAoFBAICAAUSA1sCCAoMCgUEAgIA
ARIDWwkPCgwKBQQCAgADEgNbEhMKDQoFBAICAAgSBFsUYAMKDwoIBAICAAicCAASA1wEKgoP
CgcEAgIACJ8IEgRdBF8FChkKBAQCAgESA2MCFhoMIFBhZ2Ugc2l6ZS4KCgwKBQQCAgEFEgNj
AgcKDAoFBAICAQESA2MIEQoMCgUEAgIBAxIDYxQVChoKBAQCAgISA2YCGBoNIFBhZ2UgdG9r
ZW4uCgoMCgUEAgICBRIDZgIICgwKBQQCAgIBEgNmCRMKDAoFBAICAgMSA2YWFwo9CgIEAxIE
agBzARoxIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIENvbm5lY3RvcnMuTGlzdENvbm5lY3RvcnMu
CgoKCgMEAwESA2oIHgokCgQEAwIAEgNsAiQaFyBBIGxpc3Qgb2YgY29ubmVjdG9ycy4KCgwK
BQQDAgAEEgNsAgoKDAoFBAMCAAYSA2wLFAoMCgUEAwIAARIDbBUfCgwKBQQDAgADEgNsIiMK
HwoEBAMCARIDbwIdGhIgTmV4dCBwYWdlIHRva2VuLgoKDAoFBAMCAQUSA28CCAoMCgUEAwIB
ARIDbwkYCgwKBQQDAgEDEgNvGxwKMwoEBAMCAhIDcgIiGiYgTG9jYXRpb25zIHRoYXQgY291
bGQgbm90IGJlIHJlYWNoZWQuCgoMCgUEAwICBBIDcgIKCgwKBQQDAgIFEgNyCxEKDAoFBAMC
AgESA3ISHQoMCgUEAwICAxIDciAhYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Connector::Connector ===
    # Fields for Connector
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.connectors.v1.Connector.LabelsEntry)
    # Field: documentation_uri Type: 9 ()
    # Field: external_uri Type: 9 ()
    # Field: description Type: 9 ()
    # Field: web_assets_location Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: launch_stage Type: 14 (.google.cloud.connectors.v1.LaunchStage)

# === Message: Google::Cloud::Connectors::V1::Connector::GetConnectorRequest ===
    # Fields for GetConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest ===
    # Fields for ListConnectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse ===
    # Fields for ListConnectorsResponse
    # Field: connectors Type: 11 (.google.cloud.connectors.v1.Connector)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Connector - Compiled Protocol Buffers messages for google/cloud/connectors/v1/connector.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Connector;

    my $msg = Google::Cloud::Connectors::V1::Connector::Connector->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Connector::Connector->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/connector.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Connector::Connector

Connectors indicates a specific connector type, e.x. Salesforce, SAP etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the Connector.
Format:
projects/{project}/locations/{location}/providers/{provider}/connectors/{connector}
Only global location is supported for Connector resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Created time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Updated time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Connector::Connector::LabelsEntry>)

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

=head2 Google::Cloud::Connectors::V1::Connector::GetConnectorRequest

Request message for Connectors.GetConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the form:
`projects/*/locations/*/providers/*/connectors/*`
Only global location is supported for Connector resource.

=back

=head2 Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest

Request message for Connectors.ListConnectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource of the connectors, of the form:
`projects/*/locations/*/providers/*`
Only global location is supported for Connector resource.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=back

=head2 Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse

Response message for Connectors.ListConnectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connectors() >> / C<< $msg->connectors($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Connector::Connector>)

A list of connectors.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Connector::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
