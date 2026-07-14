package Google::Api::Consumer;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Chlnb29nbGUvYXBpL2NvbnN1bWVyLnByb3RvEgpnb29nbGUuYXBpIkkKEVByb2plY3RQcm9w
ZXJ0aWVzEjQKCnByb3BlcnRpZXMYASADKAsyFC5nb29nbGUuYXBpLlByb3BlcnR5Ugpwcm9w
ZXJ0aWVzIsUBCghQcm9wZXJ0eRISCgRuYW1lGAEgASgJUgRuYW1lEjUKBHR5cGUYAiABKA4y
IS5nb29nbGUuYXBpLlByb3BlcnR5LlByb3BlcnR5VHlwZVIEdHlwZRIgCgtkZXNjcmlwdGlv
bhgDIAEoCVILZGVzY3JpcHRpb24iTAoMUHJvcGVydHlUeXBlEg8KC1VOU1BFQ0lGSUVEEAAS
CQoFSU5UNjQQARIICgRCT09MEAISCgoGU1RSSU5HEAMSCgoGRE9VQkxFEARCaAoOY29tLmdv
b2dsZS5hcGlCDUNvbnN1bWVyUHJvdG9QAVpFZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8v
Z29vZ2xlYXBpcy9hcGkvc2VydmljZWNvbmZpZztzZXJ2aWNlY29uZmlnSrsVCgYSBA4AUQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABMKCAoBCBIDEgBc
CgkKAggLEgMSAFwKCAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAAuCgkKAggIEgMUAC4K
CAoBCBIDFQAnCgkKAggBEgMVACcKvwUKAgQAEgQnACoBGrIFIEEgZGVzY3JpcHRvciBmb3Ig
ZGVmaW5pbmcgcHJvamVjdCBwcm9wZXJ0aWVzIGZvciBhIHNlcnZpY2UuIE9uZSBzZXJ2aWNl
IG1heQogaGF2ZSBtYW55IGNvbnN1bWVyIHByb2plY3RzLCBhbmQgdGhlIHNlcnZpY2UgbWF5
IHdhbnQgdG8gYmVoYXZlIGRpZmZlcmVudGx5CiBkZXBlbmRpbmcgb24gc29tZSBwcm9wZXJ0
aWVzIG9uIHRoZSBwcm9qZWN0LiBGb3IgZXhhbXBsZSwgYSBwcm9qZWN0IG1heSBiZQogYXNz
b2NpYXRlZCB3aXRoIGEgc2Nob29sLCBvciBhIGJ1c2luZXNzLCBvciBhIGdvdmVybm1lbnQg
YWdlbmN5LCBhIGJ1c2luZXNzCiB0eXBlIHByb3BlcnR5IG9uIHRoZSBwcm9qZWN0IG1heSBh
ZmZlY3QgaG93IGEgc2VydmljZSByZXNwb25kcyB0byB0aGUgY2xpZW50LgogVGhpcyBkZXNj
cmlwdG9yIGRlZmluZXMgd2hpY2ggcHJvcGVydGllcyBhcmUgYWxsb3dlZCB0byBiZSBzZXQg
b24gYSBwcm9qZWN0LgoKIEV4YW1wbGU6CgogICAgcHJvamVjdF9wcm9wZXJ0aWVzOgogICAg
ICBwcm9wZXJ0aWVzOgogICAgICAtIG5hbWU6IE5PX1dBVEVSTUFSSwogICAgICAgIHR5cGU6
IEJPT0wKICAgICAgICBkZXNjcmlwdGlvbjogQWxsb3dzIHVzYWdlIG9mIHRoZSBBUEkgd2l0
aG91dCB3YXRlcm1hcmtzLgogICAgICAtIG5hbWU6IEVYVEVOREVEX1RJTEVfQ0FDSEVfUEVS
SU9ECiAgICAgICAgdHlwZTogSU5UNjQKCgoKAwQAARIDJwgZCkAKBAQAAgASAykCIxozIExp
c3Qgb2YgcGVyIGNvbnN1bWVyIHByb2plY3Qtc3BlY2lmaWMgcHJvcGVydGllcy4KCgwKBQQA
AgAEEgMpAgoKDAoFBAACAAYSAykLEwoMCgUEAAIAARIDKRQeCgwKBQQAAgADEgMpISIK4QMK
AgQBEgQ2AFEBGtQDIERlZmluZXMgcHJvamVjdCBwcm9wZXJ0aWVzLgoKIEFQSSBzZXJ2aWNl
cyBjYW4gZGVmaW5lIHByb3BlcnRpZXMgdGhhdCBjYW4gYmUgYXNzaWduZWQgdG8gY29uc3Vt
ZXIgcHJvamVjdHMKIHNvIHRoYXQgYmFja2VuZHMgY2FuIHBlcmZvcm0gcmVzcG9uc2UgY3Vz
dG9taXphdGlvbiB3aXRob3V0IGhhdmluZyB0byBtYWtlCiBhZGRpdGlvbmFsIGNhbGxzIG9y
IG1haW50YWluIGFkZGl0aW9uYWwgc3RvcmFnZS4gRm9yIGV4YW1wbGUsIE1hcHMgQVBJCiBk
ZWZpbmVzIHByb3BlcnRpZXMgdGhhdCBjb250cm9scyBtYXAgdGlsZSBjYWNoZSBwZXJpb2Qs
IG9yIHdoZXRoZXIgdG8gZW1iZWQgYQogd2F0ZXJtYXJrIGluIGEgcmVzdWx0LgoKIFRoZXNl
IHZhbHVlcyBjYW4gYmUgc2V0IHZpYSBBUEkgcHJvZHVjZXIgY29uc29sZS4gT25seSBBUEkg
cHJvdmlkZXJzIGNhbgogZGVmaW5lIGFuZCBzZXQgdGhlc2UgcHJvcGVydGllcy4KCgoKAwQB
ARIDNggQCjoKBAQBBAASBDgCRwMaLCBTdXBwb3J0ZWQgZGF0YSB0eXBlIG9mIHRoZSBwcm9w
ZXJ0eSB2YWx1ZXMKCgwKBQQBBAABEgM4BxMKRgoGBAEEAAIAEgM6BBQaNyBUaGUgdHlwZSBp
cyB1bnNwZWNpZmllZCwgYW5kIHdpbGwgcmVzdWx0IGluIGFuIGVycm9yLgoKDgoHBAEEAAIA
ARIDOgQPCg4KBwQBBAACAAISAzoSEwolCgYEAQQAAgESAz0EDhoWIFRoZSB0eXBlIGlzIGBp
bnQ2NGAuCgoOCgcEAQQAAgEBEgM9BAkKDgoHBAEEAAIBAhIDPQwNCiQKBgQBBAACAhIDQAQN
GhUgVGhlIHR5cGUgaXMgYGJvb2xgLgoKDgoHBAEEAAICARIDQAQICg4KBwQBBAACAgISA0AL
DAomCgYEAQQAAgMSA0MEDxoXIFRoZSB0eXBlIGlzIGBzdHJpbmdgLgoKDgoHBAEEAAIDARID
QwQKCg4KBwQBBAACAwISA0MNDgomCgYEAQQAAgQSA0YEDxoXIFRoZSB0eXBlIGlzICdkb3Vi
bGUnLgoKDgoHBAEEAAIEARIDRgQKCg4KBwQBBAACBAISA0YNDgo0CgQEAQIAEgNKAhIaJyBU
aGUgbmFtZSBvZiB0aGUgcHJvcGVydHkgKGEuay5hIGtleSkuCgoMCgUEAQIABRIDSgIICgwK
BQQBAgABEgNKCQ0KDAoFBAECAAMSA0oQEQopCgQEAQIBEgNNAhgaHCBUaGUgdHlwZSBvZiB0
aGlzIHByb3BlcnR5LgoKDAoFBAECAQYSA00CDgoMCgUEAQIBARIDTQ8TCgwKBQQBAgEDEgNN
FhcKLgoEBAECAhIDUAIZGiEgVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBwcm9wZXJ0eQoKDAoF
BAECAgUSA1ACCAoMCgUEAQICARIDUAkUCgwKBQQBAgIDEgNQFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Api::Consumer::ProjectProperties ===
    # Fields for ProjectProperties
    # Field: properties Type: 11 (.google.api.Property)

=pod

=head1 NAME

Google::Api::Consumer::ProjectProperties - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Api::Consumer;

    my $msg = Google::Api::Consumer::ProjectProperties->new(
        properties => $value,
    );

=head1 FIELDS

=over 4

=item * B<properties>

Type: Message (.google.api.Property)

=back

=cut

# === Message: Google::Api::Consumer::Property ===
    # Fields for Property
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.api.Property.PropertyType)
    # Field: description Type: 9 ()

=pod

=head1 NAME

Google::Api::Consumer::Property - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Api::Consumer;

    my $msg = Google::Api::Consumer::Property->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<type>

Type: Enum (.google.api.Property.PropertyType)

=item * B<description>

Type: String

=back

=cut

# Enum: Property::PropertyType
our $Property_UNSPECIFIED = 0;
our $Property_INT64 = 1;
our $Property_BOOL = 2;
our $Property_STRING = 3;
our $Property_DOUBLE = 4;

=pod

=head2 Enum: Property::PropertyType

Values:

=over 4

=item * C<UNSPECIFIED> => 0

=item * C<INT64> => 1

=item * C<BOOL> => 2

=item * C<STRING> => 3

=item * C<DOUBLE> => 4

=back

=cut

1;
