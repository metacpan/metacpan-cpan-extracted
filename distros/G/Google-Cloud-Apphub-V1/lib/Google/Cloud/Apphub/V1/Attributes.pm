package Google::Cloud::Apphub::V1::Attributes;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXBwaHViL3YxL2F0dHJpYnV0ZXMucHJvdG8SFmdvb2dsZS5jbG91
ZC5hcHBodWIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8inwMKCkF0dHJp
YnV0ZXMSSgoLY3JpdGljYWxpdHkYASABKAsyIy5nb29nbGUuY2xvdWQuYXBwaHViLnYxLkNy
aXRpY2FsaXR5QgPgQQFSC2NyaXRpY2FsaXR5EkoKC2Vudmlyb25tZW50GAIgASgLMiMuZ29v
Z2xlLmNsb3VkLmFwcGh1Yi52MS5FbnZpcm9ubWVudEID4EEBUgtlbnZpcm9ubWVudBJTChBk
ZXZlbG9wZXJfb3duZXJzGAMgAygLMiMuZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5Db250YWN0
SW5mb0ID4EEBUg9kZXZlbG9wZXJPd25lcnMSUQoPb3BlcmF0b3Jfb3duZXJzGAQgAygLMiMu
Z29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5Db250YWN0SW5mb0ID4EEBUg5vcGVyYXRvck93bmVy
cxJRCg9idXNpbmVzc19vd25lcnMYBSADKAsyIy5nb29nbGUuY2xvdWQuYXBwaHViLnYxLkNv
bnRhY3RJbmZvQgPgQQFSDmJ1c2luZXNzT3duZXJzIqMBCgtDcml0aWNhbGl0eRJBCgR0eXBl
GAMgASgOMiguZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5Dcml0aWNhbGl0eS5UeXBlQgPgQQJS
BHR5cGUiUQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASFAoQTUlTU0lPTl9DUklUSUNB
TBABEggKBEhJR0gQAhIKCgZNRURJVU0QAxIHCgNMT1cQBCKmAQoLRW52aXJvbm1lbnQSQQoE
dHlwZRgCIAEoDjIoLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuRW52aXJvbm1lbnQuVHlwZUID
4EECUgR0eXBlIlQKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEg4KClBST0RVQ1RJT04Q
ARILCgdTVEFHSU5HEAISCAoEVEVTVBADEg8KC0RFVkVMT1BNRU5UEAQiUAoLQ29udGFjdElu
Zm8SJgoMZGlzcGxheV9uYW1lGAEgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEhkKBWVtYWlsGAIg
ASgJQgPgQQJSBWVtYWlsQrEBChpjb20uZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MUIPQXR0cmli
dXRlc1Byb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXBwaHViL2FwaXYxL2FwcGh1YnBi
O2FwcGh1YnBiqgIWR29vZ2xlLkNsb3VkLkFwcEh1Yi5WMcoCFkdvb2dsZVxDbG91ZFxBcHBI
dWJcVjHqAhlHb29nbGU6OkNsb3VkOjpBcHBIdWI6OlYxStMYCgYSBA4AagEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoICgEIEgMU
ADMKCQoCCCUSAxQAMwoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYA
IgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADMKCQoCCAESAxgAMwoICgEIEgMZADMK
CQoCCCkSAxkAMwoICgEIEgMaADIKCQoCCC0SAxoAMgorCgIEABIEHQAwARofIENvbnN1bWVy
IHByb3ZpZGVkIGF0dHJpYnV0ZXMuCgoKCgMEAAESAx0IEgo+CgQEAAIAEgMfAkcaMSBPcHRp
b25hbC4gVXNlci1kZWZpbmVkIGNyaXRpY2FsaXR5IGluZm9ybWF0aW9uLgoKDAoFBAACAAYS
Ax8CDQoMCgUEAAIAARIDHw4ZCgwKBQQAAgADEgMfHB0KDAoFBAACAAgSAx8eRgoPCggEAAIA
CJwIABIDHx9FCj4KBAQAAgESAyICRxoxIE9wdGlvbmFsLiBVc2VyLWRlZmluZWQgZW52aXJv
bm1lbnQgaW5mb3JtYXRpb24uCgoMCgUEAAIBBhIDIgINCgwKBQQAAgEBEgMiDhkKDAoFBAAC
AQMSAyIcHQoMCgUEAAIBCBIDIh5GCg8KCAQAAgEInAgAEgMiH0UKSgoEBAACAhIEJQImLxo8
IE9wdGlvbmFsLiBEZXZlbG9wZXIgdGVhbSB0aGF0IG93bnMgZGV2ZWxvcG1lbnQgYW5kIGNv
ZGluZy4KCgwKBQQAAgIEEgMlAgoKDAoFBAACAgYSAyULFgoMCgUEAAICARIDJRcnCgwKBQQA
AgIDEgMlKisKDAoFBAACAggSAyYGLgoPCggEAAICCJwIABIDJgctCkwKBAQAAgMSBCkCKi8a
PiBPcHRpb25hbC4gT3BlcmF0b3IgdGVhbSB0aGF0IGVuc3VyZXMgcnVudGltZSBhbmQgb3Bl
cmF0aW9ucy4KCgwKBQQAAgMEEgMpAgoKDAoFBAACAwYSAykLFgoMCgUEAAIDARIDKRcmCgwK
BQQAAgMDEgMpKSoKDAoFBAACAwgSAyoGLgoPCggEAAIDCJwIABIDKgctCl8KBAQAAgQSBC4C
Ly8aUSBPcHRpb25hbC4gQnVzaW5lc3MgdGVhbSB0aGF0IGVuc3VyZXMgdXNlciBuZWVkcyBh
cmUgbWV0IGFuZCB2YWx1ZSBpcwogZGVsaXZlcmVkCgoMCgUEAAIEBBIDLgIKCgwKBQQAAgQG
EgMuCxYKDAoFBAACBAESAy4XJgoMCgUEAAIEAxIDLikqCgwKBQQAAgQIEgMvBi4KDwoIBAAC
BAicCAASAy8HLQpCCgIEARIEMwBIARo2IENyaXRpY2FsaXR5IG9mIHRoZSBBcHBsaWNhdGlv
biwgU2VydmljZSwgb3IgV29ya2xvYWQKCgoKAwQBARIDMwgTCiEKBAQBBAASBDUCRAMaEyBD
cml0aWNhbGl0eSBUeXBlLgoKDAoFBAEEAAESAzUHCwoiCgYEAQQAAgASAzcEGRoTIFVuc3Bl
Y2lmaWVkIHR5cGUuCgoOCgcEAQQAAgABEgM3BBQKDgoHBAEEAAIAAhIDNxcYCkMKBgQBBAAC
ARIDOgQZGjQgTWlzc2lvbiBjcml0aWNhbCBzZXJ2aWNlLCBhcHBsaWNhdGlvbiBvciB3b3Jr
bG9hZC4KCg4KBwQBBAACAQESAzoEFAoOCgcEAQQAAgECEgM6FxgKHQoGBAEEAAICEgM9BA0a
DiBIaWdoIGltcGFjdC4KCg4KBwQBBAACAgESAz0ECAoOCgcEAQQAAgICEgM9CwwKHwoGBAEE
AAIDEgNABA8aECBNZWRpdW0gaW1wYWN0LgoKDgoHBAEEAAIDARIDQAQKCg4KBwQBBAACAwIS
A0ANDgocCgYEAQQAAgQSA0MEDBoNIExvdyBpbXBhY3QuCgoOCgcEAQQAAgQBEgNDBAcKDgoH
BAEEAAIEAhIDQwoLCioKBAQBAgASA0cCORodIFJlcXVpcmVkLiBDcml0aWNhbGl0eSBUeXBl
LgoKDAoFBAECAAYSA0cCBgoMCgUEAQIAARIDRwcLCgwKBQQBAgADEgNHDg8KDAoFBAECAAgS
A0cQOAoPCggEAQIACJwIABIDRxE3CkIKAgQCEgRLAGABGjYgRW52aXJvbm1lbnQgb2YgdGhl
IEFwcGxpY2F0aW9uLCBTZXJ2aWNlLCBvciBXb3JrbG9hZAoKCgoDBAIBEgNLCBMKIQoEBAIE
ABIETQJcAxoTIEVudmlyb25tZW50IFR5cGUuCgoMCgUEAgQAARIDTQcLCiIKBgQCBAACABID
TwQZGhMgVW5zcGVjaWZpZWQgdHlwZS4KCg4KBwQCBAACAAESA08EFAoOCgcEAgQAAgACEgNP
FxgKKAoGBAIEAAIBEgNSBBMaGSBQcm9kdWN0aW9uIGVudmlyb25tZW50LgoKDgoHBAIEAAIB
ARIDUgQOCg4KBwQCBAACAQISA1IREgolCgYEAgQAAgISA1UEEBoWIFN0YWdpbmcgZW52aXJv
bm1lbnQuCgoOCgcEAgQAAgIBEgNVBAsKDgoHBAIEAAICAhIDVQ4PCiIKBgQCBAACAxIDWAQN
GhMgVGVzdCBlbnZpcm9ubWVudC4KCg4KBwQCBAACAwESA1gECAoOCgcEAgQAAgMCEgNYCwwK
KQoGBAIEAAIEEgNbBBQaGiBEZXZlbG9wbWVudCBlbnZpcm9ubWVudC4KCg4KBwQCBAACBAES
A1sEDwoOCgcEAgQAAgQCEgNbEhMKKgoEBAICABIDXwI5Gh0gUmVxdWlyZWQuIEVudmlyb25t
ZW50IFR5cGUuCgoMCgUEAgIABhIDXwIGCgwKBQQCAgABEgNfBwsKDAoFBAICAAMSA18ODwoM
CgUEAgIACBIDXxA4Cg8KCAQCAgAInAgAEgNfETcKMgoCBAMSBGMAagEaJiBDb250YWN0IGlu
Zm9ybWF0aW9uIG9mIHN0YWtlaG9sZGVycy4KCgoKAwQDARIDYwgTClUKBAQDAgASA2YCQxpI
IE9wdGlvbmFsLiBDb250YWN0J3MgbmFtZS4KIENhbiBoYXZlIGEgbWF4aW11bSBsZW5ndGgg
b2YgNjMgY2hhcmFjdGVycy4KCgwKBQQDAgAFEgNmAggKDAoFBAMCAAESA2YJFQoMCgUEAwIA
AxIDZhgZCgwKBQQDAgAIEgNmGkIKDwoIBAMCAAicCAASA2YbQQo3CgQEAwIBEgNpAjwaKiBS
ZXF1aXJlZC4gRW1haWwgYWRkcmVzcyBvZiB0aGUgY29udGFjdHMuCgoMCgUEAwIBBRIDaQII
CgwKBQQDAgEBEgNpCQ4KDAoFBAMCAQMSA2kREgoMCgUEAwIBCBIDaRM7Cg8KCAQDAgEInAgA
EgNpFDpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Attributes::Attributes ===
    # Fields for Attributes
    # Field: criticality Type: 11 (.google.cloud.apphub.v1.Criticality)
    # Field: environment Type: 11 (.google.cloud.apphub.v1.Environment)
    # Field: developer_owners Type: 11 (.google.cloud.apphub.v1.ContactInfo)
    # Field: operator_owners Type: 11 (.google.cloud.apphub.v1.ContactInfo)
    # Field: business_owners Type: 11 (.google.cloud.apphub.v1.ContactInfo)

# === Message: Google::Cloud::Apphub::V1::Attributes::Criticality ===
    # Fields for Criticality
    # Field: type Type: 14 (.google.cloud.apphub.v1.Criticality.Type)

# Enum: Criticality::Type
our $Criticality_TYPE_UNSPECIFIED = 0;
our $Criticality_MISSION_CRITICAL = 1;
our $Criticality_HIGH = 2;
our $Criticality_MEDIUM = 3;
our $Criticality_LOW = 4;

# === Message: Google::Cloud::Apphub::V1::Attributes::Environment ===
    # Fields for Environment
    # Field: type Type: 14 (.google.cloud.apphub.v1.Environment.Type)

# Enum: Environment::Type
our $Environment_TYPE_UNSPECIFIED = 0;
our $Environment_PRODUCTION = 1;
our $Environment_STAGING = 2;
our $Environment_TEST = 3;
our $Environment_DEVELOPMENT = 4;

# === Message: Google::Cloud::Apphub::V1::Attributes::ContactInfo ===
    # Fields for ContactInfo
    # Field: display_name Type: 9 ()
    # Field: email Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Attributes - Compiled Protocol Buffers messages for google/cloud/apphub/v1/attributes.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Attributes;

    my $msg = Google::Cloud::Apphub::V1::Attributes::Attributes->new({
        criticality => $criticality,
        environment => $environment,
        developer_owners => $developer_owners,
        operator_owners => $operator_owners,
    });

    # Read or update a field
    my $val = $msg->criticality();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Attributes::Attributes->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/attributes.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Attributes::Attributes

Consumer provided attributes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->criticality() >> / C<< $msg->criticality($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Criticality>)

Optional. User-defined criticality information.

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Environment>)

Optional. User-defined environment information.

=item * C<< $msg->developer_owners() >> / C<< $msg->developer_owners($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::ContactInfo>)

Optional. Developer team that owns development and coding.

=item * C<< $msg->operator_owners() >> / C<< $msg->operator_owners($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::ContactInfo>)

Optional. Operator team that ensures runtime and operations.

=item * C<< $msg->business_owners() >> / C<< $msg->business_owners($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::ContactInfo>)

Optional. Business team that ensures user needs are met and value is
delivered

=back

=head2 Google::Cloud::Apphub::V1::Attributes::Criticality

Criticality of the Application, Service, or Workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Criticality::Type>)

Required. Criticality Type.

=back

=head3 Enum: Criticality::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<MISSION_CRITICAL> => C<1>

=item * C<HIGH> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<LOW> => C<4>

=back

=head2 Google::Cloud::Apphub::V1::Attributes::Environment

Environment of the Application, Service, or Workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Environment::Type>)

Required. Environment Type.

=back

=head3 Enum: Environment::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<PRODUCTION> => C<1>

=item * C<STAGING> => C<2>

=item * C<TEST> => C<3>

=item * C<DEVELOPMENT> => C<4>

=back

=head2 Google::Cloud::Apphub::V1::Attributes::ContactInfo

Contact information of stakeholders.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Contact's name.
Can have a maximum length of 63 characters.

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Required. Email address of the contacts.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Attributes::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
