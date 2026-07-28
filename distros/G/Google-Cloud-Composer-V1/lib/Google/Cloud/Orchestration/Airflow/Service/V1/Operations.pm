package Google::Cloud::Orchestration::Airflow::Service::V1::Operations;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvb3JjaGVzdHJhdGlvbi9haXJmbG93L3NlcnZpY2UvdjEvb3BlcmF0
aW9ucy5wcm90bxItZ29vZ2xlLmNsb3VkLm9yY2hlc3RyYXRpb24uYWlyZmxvdy5zZXJ2aWNl
LnYxGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIogFChFPcGVyYXRpb25NZXRh
ZGF0YRJcCgVzdGF0ZRgBIAEoDjJGLmdvb2dsZS5jbG91ZC5vcmNoZXN0cmF0aW9uLmFpcmZs
b3cuc2VydmljZS52MS5PcGVyYXRpb25NZXRhZGF0YS5TdGF0ZVIFc3RhdGUSbAoOb3BlcmF0
aW9uX3R5cGUYAiABKA4yRS5nb29nbGUuY2xvdWQub3JjaGVzdHJhdGlvbi5haXJmbG93LnNl
cnZpY2UudjEuT3BlcmF0aW9uTWV0YWRhdGEuVHlwZVINb3BlcmF0aW9uVHlwZRIaCghyZXNv
dXJjZRgDIAEoCVIIcmVzb3VyY2USIwoNcmVzb3VyY2VfdXVpZBgEIAEoCVIMcmVzb3VyY2VV
dWlkEjsKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIK
Y3JlYXRlVGltZRI1CghlbmRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSB2VuZFRpbWUiZwoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdQRU5ESU5H
EAESCwoHUlVOTklORxACEg0KCVNVQ0NFRURFRBADEg4KClNVQ0NFU1NGVUwQAxIKCgZGQUlM
RUQQBBoCEAEiiAEKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEgoKBkNSRUFURRABEgoK
BkRFTEVURRACEgoKBlVQREFURRADEgkKBUNIRUNLEAQSEQoNU0FWRV9TTkFQU0hPVBAFEhEK
DUxPQURfU05BUFNIT1QQBhIVChFEQVRBQkFTRV9GQUlMT1ZFUhAHQpMBCjFjb20uZ29vZ2xl
LmNsb3VkLm9yY2hlc3RyYXRpb24uYWlyZmxvdy5zZXJ2aWNlLnYxQg9PcGVyYXRpb25zUHJv
dG9QAVpLY2xvdWQuZ29vZ2xlLmNvbS9nby9vcmNoZXN0cmF0aW9uL2FpcmZsb3cvc2Vydmlj
ZS9hcGl2MS9zZXJ2aWNlcGI7c2VydmljZXBiSoQXCgYSBA4AYAEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADYKCQoCAwASAxIAKQoICgEIEgMUAGIKCQoC
CAsSAxQAYgoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADAKCQoCCAgSAxYAMAoICgEI
EgMXAEoKCQoCCAESAxcASgovCgIEABIEGgBgARojIE1ldGFkYXRhIGRlc2NyaWJpbmcgYW4g
b3BlcmF0aW9uLgoKCgoDBAABEgMaCBkKRQoEBAAEABIEHAIvAxo3IEFuIGVudW0gZGVzY3Jp
YmluZyB0aGUgb3ZlcmFsbCBzdGF0ZSBvZiBhbiBvcGVyYXRpb24uCgoMCgUEAAQAARIDHAcM
CgwKBQQABAADEgMdBB4KDQoGBAAEAAMCEgMdBB4KGAoGBAAEAAIAEgMgBBoaCSBVbnVzZWQu
CgoOCgcEAAQAAgABEgMgBBUKDgoHBAAEAAIAAhIDIBgZCkcKBgQABAACARIDIwQQGjggVGhl
IG9wZXJhdGlvbiBoYXMgYmVlbiBjcmVhdGVkIGJ1dCBpcyBub3QgeWV0IHN0YXJ0ZWQuCgoO
CgcEAAQAAgEBEgMjBAsKDgoHBAAEAAIBAhIDIw4PCisKBgQABAACAhIDJgQQGhwgVGhlIG9w
ZXJhdGlvbiBpcyB1bmRlcndheS4KCg4KBwQABAACAgESAyYECwoOCgcEAAQAAgICEgMmDg8K
NgoGBAAEAAIDEgMpBBIaJyBUaGUgb3BlcmF0aW9uIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHku
CgoOCgcEAAQAAgMBEgMpBA0KDgoHBAAEAAIDAhIDKRARCg0KBgQABAACBBIDKwQTCg4KBwQA
BAACBAESAysEDgoOCgcEAAQAAgQCEgMrERIKSAoGBAAEAAIFEgMuBA8aOSBUaGUgb3BlcmF0
aW9uIGlzIG5vIGxvbmdlciBydW5uaW5nIGJ1dCBkaWQgbm90IHN1Y2NlZWQuCgoOCgcEAAQA
AgUBEgMuBAoKDgoHBAAEAAIFAhIDLg0OCi4KBAQABAESBDICSwMaICBUeXBlIG9mIGxvbmdy
dW5uaW5nIG9wZXJhdGlvbi4KCgwKBQQABAEBEgMyBwsKGAoGBAAEAQIAEgM0BBkaCSBVbnVz
ZWQuCgoOCgcEAAQBAgABEgM0BBQKDgoHBAAEAQIAAhIDNBcYCi8KBgQABAECARIDNwQPGiAg
QSByZXNvdXJjZSBjcmVhdGlvbiBvcGVyYXRpb24uCgoOCgcEAAQBAgEBEgM3BAoKDgoHBAAE
AQIBAhIDNw0OCi8KBgQABAECAhIDOgQPGiAgQSByZXNvdXJjZSBkZWxldGlvbiBvcGVyYXRp
b24uCgoOCgcEAAQBAgIBEgM6BAoKDgoHBAAEAQICAhIDOg0OCi0KBgQABAECAxIDPQQPGh4g
QSByZXNvdXJjZSB1cGRhdGUgb3BlcmF0aW9uLgoKDgoHBAAEAQIDARIDPQQKCg4KBwQABAEC
AwISAz0NDgosCgYEAAQBAgQSA0AEDhodIEEgcmVzb3VyY2UgY2hlY2sgb3BlcmF0aW9uLgoK
DgoHBAAEAQIEARIDQAQJCg4KBwQABAECBAISA0AMDQo6CgYEAAQBAgUSA0MEFhorIFNhdmVz
IHNuYXBzaG90IG9mIHRoZSByZXNvdXJjZSBvcGVyYXRpb24uCgoOCgcEAAQBAgUBEgNDBBEK
DgoHBAAEAQIFAhIDQxQVCjoKBgQABAECBhIDRgQWGisgTG9hZHMgc25hcHNob3Qgb2YgdGhl
IHJlc291cmNlIG9wZXJhdGlvbi4KCg4KBwQABAECBgESA0YEEQoOCgcEAAQBAgYCEgNGFBUK
cQoGBAAEAQIHEgNKBBoaYiBUcmlnZ2VycyBmYWlsb3ZlciBvZiBlbnZpcm9ubWVudCdzIENs
b3VkIFNRTCBpbnN0YW5jZSAob25seSBmb3IgaGlnaGx5CiByZXNpbGllbnQgZW52aXJvbm1l
bnRzKS4KCg4KBwQABAECBwESA0oEFQoOCgcEAAQBAgcCEgNKGBkKOAoEBAACABIDTgISGisg
T3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IG9wZXJhdGlvbiBzdGF0ZS4KCgwKBQQAAgAGEgNO
AgcKDAoFBAACAAESA04IDQoMCgUEAAIAAxIDThARCkIKBAQAAgESA1ECGho1IE91dHB1dCBv
bmx5LiBUaGUgdHlwZSBvZiBvcGVyYXRpb24gYmVpbmcgcGVyZm9ybWVkLgoKDAoFBAACAQYS
A1ECBgoMCgUEAAIBARIDUQcVCgwKBQQAAgEDEgNRGBkKkQEKBAQAAgISA1UCFhqDASBPdXRw
dXQgb25seS4gVGhlIHJlc291cmNlIGJlaW5nIG9wZXJhdGVkIG9uLCBhcyBhIFtyZWxhdGl2
ZSByZXNvdXJjZSBuYW1lXSgKIC9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNyZWxhdGl2
ZV9yZXNvdXJjZV9uYW1lKS4KCgwKBQQAAgIFEgNVAggKDAoFBAACAgESA1UJEQoMCgUEAAIC
AxIDVRQVCkcKBAQAAgMSA1gCGxo6IE91dHB1dCBvbmx5LiBUaGUgVVVJRCBvZiB0aGUgcmVz
b3VyY2UgYmVpbmcgb3BlcmF0ZWQgb24uCgoMCgUEAAIDBRIDWAIICgwKBQQAAgMBEgNYCRYK
DAoFBAACAwMSA1gZGgpPCgQEAAIEEgNbAiwaQiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhl
IG9wZXJhdGlvbiB3YXMgc3VibWl0dGVkIHRvIHRoZSBzZXJ2ZXIuCgoMCgUEAAIEBhIDWwIb
CgwKBQQAAgQBEgNbHCcKDAoFBAACBAMSA1sqKwqXAQoEBAACBRIDXwIpGokBIE91dHB1dCBv
bmx5LiBUaGUgdGltZSB3aGVuIHRoZSBvcGVyYXRpb24gdGVybWluYXRlZCwgcmVnYXJkbGVz
cyBvZiBpdHMKIHN1Y2Nlc3MuIFRoaXMgZmllbGQgaXMgdW5zZXQgaWYgdGhlIG9wZXJhdGlv
biBpcyBzdGlsbCBvbmdvaW5nLgoKDAoFBAACBQYSA18CGwoMCgUEAAIFARIDXxwkCgwKBQQA
AgUDEgNfJyhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: state Type: 14 (.google.cloud.orchestration.airflow.service.v1.OperationMetadata.State)
    # Field: operation_type Type: 14 (.google.cloud.orchestration.airflow.service.v1.OperationMetadata.Type)
    # Field: resource Type: 9 ()
    # Field: resource_uuid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Orchestration::Airflow::Service::V1::Operations;

    my $msg = Google::Cloud::Orchestration::Airflow::Service::V1::Operations::OperationMetadata->new(
        state => $value,
    );

=head1 FIELDS

=over 4

=item * B<state>

Type: Enum (.google.cloud.orchestration.airflow.service.v1.OperationMetadata.State)

=item * B<operation_type>

Type: Enum (.google.cloud.orchestration.airflow.service.v1.OperationMetadata.Type)

=item * B<resource>

Type: String

=item * B<resource_uuid>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<end_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# Enum: OperationMetadata::State
our $OperationMetadata_STATE_UNSPECIFIED = 0;
our $OperationMetadata_PENDING = 1;
our $OperationMetadata_RUNNING = 2;
our $OperationMetadata_SUCCEEDED = 3;
our $OperationMetadata_SUCCESSFUL = 3;
our $OperationMetadata_FAILED = 4;

=pod

=head2 Enum: OperationMetadata::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<PENDING> => 1

=item * C<RUNNING> => 2

=item * C<SUCCEEDED> => 3

=item * C<SUCCESSFUL> => 3

=item * C<FAILED> => 4

=back

=cut

# Enum: OperationMetadata::Type
our $OperationMetadata_TYPE_UNSPECIFIED = 0;
our $OperationMetadata_CREATE = 1;
our $OperationMetadata_DELETE = 2;
our $OperationMetadata_UPDATE = 3;
our $OperationMetadata_CHECK = 4;
our $OperationMetadata_SAVE_SNAPSHOT = 5;
our $OperationMetadata_LOAD_SNAPSHOT = 6;
our $OperationMetadata_DATABASE_FAILOVER = 7;

=pod

=head2 Enum: OperationMetadata::Type

Values:

=over 4

=item * C<TYPE_UNSPECIFIED> => 0

=item * C<CREATE> => 1

=item * C<DELETE> => 2

=item * C<UPDATE> => 3

=item * C<CHECK> => 4

=item * C<SAVE_SNAPSHOT> => 5

=item * C<LOAD_SNAPSHOT> => 6

=item * C<DATABASE_FAILOVER> => 7

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::Operations - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
