package Google::Cloud::Apphub::V1::Properties;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXBwaHViL3YxL3Byb3BlcnRpZXMucHJvdG8SFmdvb2dsZS5jbG91
ZC5hcHBodWIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8inQEKDkZ1
bmN0aW9uYWxUeXBlEkQKBHR5cGUYASABKA4yKy5nb29nbGUuY2xvdWQuYXBwaHViLnYxLkZ1
bmN0aW9uYWxUeXBlLlR5cGVCA+BBA1IEdHlwZSJFCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJ
RUQQABIJCgVBR0VOVBABEg4KCk1DUF9TRVJWRVIQAhIMCghFTkRQT0lOVBADIpMBChBSZWdp
c3RyYXRpb25UeXBlEkYKBHR5cGUYASABKA4yLS5nb29nbGUuY2xvdWQuYXBwaHViLnYxLlJl
Z2lzdHJhdGlvblR5cGUuVHlwZUID4EEDUgR0eXBlIjcKBFR5cGUSFAoQVFlQRV9VTlNQRUNJ
RklFRBAAEg0KCUVYQ0xVU0lWRRABEgoKBlNIQVJFRBACIlkKEEV4dGVuZGVkTWV0YWRhdGES
RQoPbWV0YWRhdGFfc3RydWN0GAEgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EED
Ug5tZXRhZGF0YVN0cnVjdCItCghJZGVudGl0eRIhCglwcmluY2lwYWwYASABKAlCA+BBA1IJ
cHJpbmNpcGFsQrEBChpjb20uZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MUIPUHJvcGVydGllc1By
b3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXBwaHViL2FwaXYxL2FwcGh1YnBiO2FwcGh1
YnBiqgIWR29vZ2xlLkNsb3VkLkFwcEh1Yi5WMcoCFkdvb2dsZVxDbG91ZFxBcHBIdWJcVjHq
AhlHb29nbGU6OkNsb3VkOjpBcHBIdWI6OlYxSoAUCgYSBA4AVQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkK
AgMCEgMUACYKCAoBCBIDFgAzCgkKAgglEgMWADMKCAoBCBIDFwBJCgkKAggLEgMXAEkKCAoB
CBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAwCgkKAggIEgMZADAKCAoBCBIDGgAzCgkKAggB
EgMaADMKCAoBCBIDGwAzCgkKAggpEgMbADMKCAoBCBIDHAAyCgkKAggtEgMcADIKOwoCBAAS
BB8AMQEaLyBUaGUgZnVuY3Rpb25hbCB0eXBlIG9mIGEgc2VydmljZSBvciB3b3JrbG9hZC4K
CgoKAwQAARIDHwgWCj0KBAQABAASBCECLQMaLyBUaGUgZnVuY3Rpb25hbCB0eXBlIG9mIGEg
c2VydmljZSBvciB3b3JrbG9hZC4KCgwKBQQABAABEgMhBwsKIgoGBAAEAAIAEgMjBBkaEyBV
bnNwZWNpZmllZCB0eXBlLgoKDgoHBAAEAAIAARIDIwQUCg4KBwQABAACAAISAyMXGAocCgYE
AAQAAgESAyYEDhoNIEFnZW50IHR5cGUuCgoOCgcEAAQAAgEBEgMmBAkKDgoHBAAEAAIBAhID
JgwNCiEKBgQABAACAhIDKQQTGhIgTUNQIFNlcnZlciB0eXBlLgoKDgoHBAAEAAICARIDKQQO
Cg4KBwQABAACAgISAykREgofCgYEAAQAAgMSAywEERoQIEVuZHBvaW50IHR5cGUuCgoOCgcE
AAQAAgMBEgMsBAwKDgoHBAAEAAIDAhIDLA8QCkkKBAQAAgASAzACPBo8IE91dHB1dCBvbmx5
LiBUaGUgZnVuY3Rpb25hbCB0eXBlIG9mIGEgc2VydmljZSBvciB3b3JrbG9hZC4KCgwKBQQA
AgAGEgMwAgYKDAoFBAACAAESAzAHCwoMCgUEAAIAAxIDMA4PCgwKBQQAAgAIEgMwEDsKDwoI
BAACAAicCAASAzAROgoxCgIEARIENABDARolIFRoZSByZWdpc3RyYXRpb24gdHlwZSBvZiBh
IHNlcnZpY2UuCgoKCgMEAQESAzQIGAozCgQEAQQAEgQ2Aj8DGiUgVGhlIHJlZ2lzdHJhdGlv
biB0eXBlIG9mIGEgc2VydmljZS4KCgwKBQQBBAABEgM2BwsKRgoGBAEEAAIAEgM4BBkaNyBV
bnNwZWNpZmllZCByZWdpc3RyYXRpb24gdHlwZS4gRGVmYXVsdHMgdG8gRVhDTFVTSVZFLgoK
DgoHBAEEAAIAARIDOAQUCg4KBwQBBAACAAISAzgXGApHCgYEAQQAAgESAzsEEho4IFRoZSBz
ZXJ2aWNlIGNhbiBvbmx5IGJlIHJlZ2lzdGVyZWQgdG8gb25lIGFwcGxpY2F0aW9uLgoKDgoH
BAEEAAIBARIDOwQNCg4KBwQBBAACAQISAzsQEQpICgYEAQQAAgISAz4EDxo5IFRoZSBzZXJ2
aWNlIGNhbiBiZSByZWdpc3RlcmVkIHRvIG11bHRpcGxlIGFwcGxpY2F0aW9ucy4KCg4KBwQB
BAACAgESAz4ECgoOCgcEAQQAAgICEgM+DQ4KPwoEBAECABIDQgI8GjIgT3V0cHV0IG9ubHku
IFRoZSByZWdpc3RyYXRpb24gdHlwZSBvZiBhIHNlcnZpY2UuCgoMCgUEAQIABhIDQgIGCgwK
BQQBAgABEgNCBwsKDAoFBAECAAMSA0IODwoMCgUEAQIACBIDQhA7Cg8KCAQBAgAInAgAEgNC
EToKPAoCBAISBEYASgEaMCBBZGRpdGlvbmFsIG1ldGFkYXRhIGZvciBhIFNlcnZpY2Ugb3Ig
V29ya2xvYWQuCgoKCgMEAgESA0YIGAozCgQEAgIAEgRIAkkyGiUgT3V0cHV0IG9ubHkuIFRo
ZSBtZXRhZGF0YSBjb250ZW50cy4KCgwKBQQCAgAGEgNIAhgKDAoFBAICAAESA0gZKAoMCgUE
AgIAAxIDSCssCgwKBQQCAgAIEgNJBjEKDwoIBAICAAicCAASA0kHMApBCgIEAxIETQBVARo1
IFRoZSBpZGVudGl0eSBhc3NvY2lhdGVkIHdpdGggYSBzZXJ2aWNlIG9yIHdvcmtsb2FkLgoK
CgoDBAMBEgNNCBAKoQIKBAQDAgASA1QCQxqTAiBPdXRwdXQgb25seS4gVGhlIHByaW5jaXBh
bCBvZiB0aGUgaWRlbnRpdHkuCgogU3VwcG9ydGVkIGZvcm1hdHM6CgogKiBgc2E6Ly9teS1z
YUBQUk9KRUNUX0lELmlhbS5nc2VydmljZWFjY291bnQuY29tYCBmb3IgR0NQIFNlcnZpY2Ug
QWNjb3VudAogKiBgcHJpbmNpcGFsOi8vUE9PTF9JRC5nbG9iYWwuUFJPSkVDVF9OVU1CRVIu
d29ya2xvYWQuaWQuZ29vZy9ucy9OQU1FU1BBQ0VfSUQvc2EvTUFOQUdFRF9JREVOVElUWV9J
RGAgZm9yIE1hbmFnZWQgV29ya2xvYWQgSWRlbnRpdHkKCgwKBQQDAgAFEgNUAggKDAoFBAMC
AAESA1QJEgoMCgUEAwIAAxIDVBUWCgwKBQQDAgAIEgNUF0IKDwoIBAMCAAicCAASA1QYQWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Properties::FunctionalType ===
    # Fields for FunctionalType
    # Field: type Type: 14 (.google.cloud.apphub.v1.FunctionalType.Type)

# Enum: FunctionalType::Type
our $FunctionalType_TYPE_UNSPECIFIED = 0;
our $FunctionalType_AGENT = 1;
our $FunctionalType_MCP_SERVER = 2;
our $FunctionalType_ENDPOINT = 3;

# === Message: Google::Cloud::Apphub::V1::Properties::RegistrationType ===
    # Fields for RegistrationType
    # Field: type Type: 14 (.google.cloud.apphub.v1.RegistrationType.Type)

# Enum: RegistrationType::Type
our $RegistrationType_TYPE_UNSPECIFIED = 0;
our $RegistrationType_EXCLUSIVE = 1;
our $RegistrationType_SHARED = 2;

# === Message: Google::Cloud::Apphub::V1::Properties::ExtendedMetadata ===
    # Fields for ExtendedMetadata
    # Field: metadata_struct Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Apphub::V1::Properties::Identity ===
    # Fields for Identity
    # Field: principal Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Properties - Compiled Protocol Buffers messages for google/cloud/apphub/v1/properties.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Properties;

    my $msg = Google::Cloud::Apphub::V1::Properties::FunctionalType->new({
        type => $type,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Properties::FunctionalType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/properties.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Properties::FunctionalType

The functional type of a service or workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::FunctionalType::Type>)

Output only. The functional type of a service or workload.

=back

=head3 Enum: FunctionalType::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<AGENT> => C<1>

=item * C<MCP_SERVER> => C<2>

=item * C<ENDPOINT> => C<3>

=back

=head2 Google::Cloud::Apphub::V1::Properties::RegistrationType

The registration type of a service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::RegistrationType::Type>)

Output only. The registration type of a service.

=back

=head3 Enum: RegistrationType::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<EXCLUSIVE> => C<1>

=item * C<SHARED> => C<2>

=back

=head2 Google::Cloud::Apphub::V1::Properties::ExtendedMetadata

Additional metadata for a Service or Workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata_struct() >> / C<< $msg->metadata_struct($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. The metadata contents.

=back

=head2 Google::Cloud::Apphub::V1::Properties::Identity

The identity associated with a service or workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal() >> / C<< $msg->principal($value) >>

Type: C<String>

Output only. The principal of the identity.

Supported formats:

* `sa://my-sa@PROJECT_ID.iam.gserviceaccount.com` for GCP Service Account
* `principal://POOL_ID.global.PROJECT_NUMBER.workload.id.goog/ns/NAMESPACE_ID/sa/MANAGED_IDENTITY_ID` for Managed Workload Identity

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Properties::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
