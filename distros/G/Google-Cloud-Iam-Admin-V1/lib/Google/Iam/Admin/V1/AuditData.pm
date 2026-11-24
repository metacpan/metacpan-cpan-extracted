package Google::Iam::Admin::V1::AuditData;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvaWFtL2FkbWluL3YxL2F1ZGl0X2RhdGEucHJvdG8SE2dvb2dsZS5pYW0uYWRt
aW4udjEi1wEKCUF1ZGl0RGF0YRJZChBwZXJtaXNzaW9uX2RlbHRhGAEgASgLMi4uZ29vZ2xl
LmlhbS5hZG1pbi52MS5BdWRpdERhdGEuUGVybWlzc2lvbkRlbHRhUg9wZXJtaXNzaW9uRGVs
dGEabwoPUGVybWlzc2lvbkRlbHRhEisKEWFkZGVkX3Blcm1pc3Npb25zGAEgAygJUhBhZGRl
ZFBlcm1pc3Npb25zEi8KE3JlbW92ZWRfcGVybWlzc2lvbnMYAiADKAlSEnJlbW92ZWRQZXJt
aXNzaW9uc0KYAQoXY29tLmdvb2dsZS5pYW0uYWRtaW4udjFCDkF1ZGl0RGF0YVByb3RvUAFa
M2Nsb3VkLmdvb2dsZS5jb20vZ28vaWFtL2FkbWluL2FwaXYxL2FkbWlucGI7YWRtaW5wYqoC
GUdvb2dsZS5DbG91ZC5JYW0uQWRtaW4uVjHKAhlHb29nbGVcQ2xvdWRcSWFtXEFkbWluXFYx
SswKCgYSBA4AKQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ABwKCAoBCBIDEgA2CgkKAgglEgMSADYKCAoBCBIDEwBKCgkKAggLEgMTAEoKCAoBCBIDFAAi
CgkKAggKEgMUACIKCAoBCBIDFQAvCgkKAggIEgMVAC8KCAoBCBIDFgAwCgkKAggBEgMWADAK
CAoBCBIDFwA3CgkKAggpEgMXADcKqwEKAgQAEgQcACkBGp4BIEF1ZGl0IGxvZyBpbmZvcm1h
dGlvbiBzcGVjaWZpYyB0byBDbG91ZCBJQU0gYWRtaW4gQVBJcy4gVGhpcyBtZXNzYWdlIGlz
CiBzZXJpYWxpemVkIGFzIGFuIGBBbnlgIHR5cGUgaW4gdGhlIGBTZXJ2aWNlRGF0YWAgbWVz
c2FnZSBvZiBhbgogYEF1ZGl0TG9nYCBtZXNzYWdlLgoKCgoDBAABEgMcCBEKcQoEBAADABIE
HwIlAxpjIEEgUGVybWlzc2lvbkRlbHRhIG1lc3NhZ2UgdG8gcmVjb3JkIHRoZSBhZGRlZF9w
ZXJtaXNzaW9ucyBhbmQKIHJlbW92ZWRfcGVybWlzc2lvbnMgaW5zaWRlIGEgcm9sZS4KCgwK
BQQAAwABEgMfChkKIwoGBAADAAIAEgMhBCoaFCBBZGRlZCBwZXJtaXNzaW9ucy4KCg4KBwQA
AwACAAQSAyEEDAoOCgcEAAMAAgAFEgMhDRMKDgoHBAADAAIAARIDIRQlCg4KBwQAAwACAAMS
AyEoKQolCgYEAAMAAgESAyQELBoWIFJlbW92ZWQgcGVybWlzc2lvbnMuCgoOCgcEAAMAAgEE
EgMkBAwKDgoHBAADAAIBBRIDJA0TCg4KBwQAAwACAQESAyQUJwoOCgcEAAMAAgEDEgMkKisK
SgoEBAACABIDKAInGj0gVGhlIHBlcm1pc3Npb25fZGVsdGEgd2hlbiB3aGVuIGNyZWF0aW5n
IG9yIHVwZGF0aW5nIGEgUm9sZS4KCgwKBQQAAgAGEgMoAhEKDAoFBAACAAESAygSIgoMCgUE
AAIAAxIDKCUmYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::Admin::V1::AuditData::AuditData ===
    # Fields for AuditData
    # Field: permission_delta Type: 11 (.google.iam.admin.v1.AuditData.PermissionDelta)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::Admin::V1::AuditData - Compiled Protocol Buffers messages for google/iam/admin/v1/audit_data.proto

=head1 SYNOPSIS

    use Google::Iam::Admin::V1::AuditData;

    my $msg = Google::Iam::Admin::V1::AuditData::AuditData->new({
        permission_delta => $permission_delta,
    });

    # Read or update a field
    my $val = $msg->permission_delta();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::Admin::V1::AuditData::AuditData->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/admin/v1/audit_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::Admin::V1::AuditData::AuditData

Audit log information specific to Cloud IAM admin APIs. This message is
serialized as an `Any` type in the `ServiceData` message of an
`AuditLog` message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permission_delta() >> / C<< $msg->permission_delta($value) >>

Type: C<Message> (L<Google::Iam::Admin::V1::AuditData::AuditData::PermissionDelta>)

The permission_delta when when creating or updating a Role.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::Admin::V1::AuditData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
