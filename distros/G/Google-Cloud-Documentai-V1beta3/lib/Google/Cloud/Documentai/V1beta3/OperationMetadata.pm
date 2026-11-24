package Google::Cloud::Documentai::V1beta3::OperationMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL29wZXJhdGlvbl9tZXRhZGF0YS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byKRAwoXQ29tbW9uT3BlcmF0aW9uTWV0YWRhdGESVAoFc3RhdGUY
ASABKA4yPi5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLkNvbW1vbk9wZXJhdGlv
bk1ldGFkYXRhLlN0YXRlUgVzdGF0ZRIjCg1zdGF0ZV9tZXNzYWdlGAIgASgJUgxzdGF0ZU1l
c3NhZ2USGgoIcmVzb3VyY2UYBSABKAlSCHJlc291cmNlEjsKC2NyZWF0ZV90aW1lGAMgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGlt
ZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUiZQoFU3Rh
dGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdSVU5OSU5HEAESDgoKQ0FOQ0VMTElORxAC
Eg0KCVNVQ0NFRURFRBADEgoKBkZBSUxFRBAEEg0KCUNBTkNFTExFRBAFQu0BCiNjb20uZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhM0IWT3BlcmF0aW9uTWV0YWRhdGFQcm90b1AB
WkNjbG91ZC5nb29nbGUuY29tL2dvL2RvY3VtZW50YWkvYXBpdjFiZXRhMy9kb2N1bWVudGFp
cGI7ZG9jdW1lbnRhaXBiqgIfR29vZ2xlLkNsb3VkLkRvY3VtZW50QUkuVjFCZXRhM8oCH0dv
b2dsZVxDbG91ZFxEb2N1bWVudEFJXFYxYmV0YTPqAiJHb29nbGU6OkNsb3VkOjpEb2N1bWVu
dEFJOjpWMWJldGEzSq0OCgYSBA4AQQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMV
AFoKCQoCCAsSAxUAWgoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADcKCQoCCAgSAxcA
NwoICgEIEgMYADwKCQoCCAESAxgAPAoICgEIEgMZADwKCQoCCCkSAxkAPAoICgEIEgMaADsK
CQoCCC0SAxoAOwo+CgIEABIEHQBBARoyIFRoZSBjb21tb24gbWV0YWRhdGEgZm9yIGxvbmcg
cnVubmluZyBvcGVyYXRpb25zLgoKCgoDBAABEgMdCB8KMwoEBAAEABIEHwIxAxolIFN0YXRl
IG9mIHRoZSBsb25ncnVubmluZyBvcGVyYXRpb24uCgoMCgUEAAQAARIDHwcMCiMKBgQABAAC
ABIDIQQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgMhBBUKDgoHBAAEAAIA
AhIDIRgZCiwKBgQABAACARIDJAQQGh0gT3BlcmF0aW9uIGlzIHN0aWxsIHJ1bm5pbmcuCgoO
CgcEAAQAAgEBEgMkBAsKDgoHBAAEAAIBAhIDJA4PCi4KBgQABAACAhIDJwQTGh8gT3BlcmF0
aW9uIGlzIGJlaW5nIGNhbmNlbGxlZC4KCg4KBwQABAACAgESAycEDgoOCgcEAAQAAgICEgMn
ERIKJQoGBAAEAAIDEgMqBBIaFiBPcGVyYXRpb24gc3VjY2VlZGVkLgoKDgoHBAAEAAIDARID
KgQNCg4KBwQABAACAwISAyoQEQoiCgYEAAQAAgQSAy0EDxoTIE9wZXJhdGlvbiBmYWlsZWQu
CgoOCgcEAAQAAgQBEgMtBAoKDgoHBAAEAAIEAhIDLQ0OCigKBgQABAACBRIDMAQSGhkgT3Bl
cmF0aW9uIGlzIGNhbmNlbGxlZC4KCg4KBwQABAACBQESAzAEDQoOCgcEAAQAAgUCEgMwEBEK
KgoEBAACABIDNAISGh0gVGhlIHN0YXRlIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAAIABhID
NAIHCgwKBQQAAgABEgM0CA0KDAoFBAACAAMSAzQQEQpWCgQEAAIBEgM3AhsaSSBBIG1lc3Nh
Z2UgcHJvdmlkaW5nIG1vcmUgZGV0YWlscyBhYm91dCB0aGUgY3VycmVudCBzdGF0ZSBvZiBw
cm9jZXNzaW5nLgoKDAoFBAACAQUSAzcCCAoMCgUEAAIBARIDNwkWCgwKBQQAAgEDEgM3GRoK
NAoEBAACAhIDOgIWGicgQSByZWxhdGVkIHJlc291cmNlIHRvIHRoaXMgb3BlcmF0aW9uLgoK
DAoFBAACAgUSAzoCCAoMCgUEAAICARIDOgkRCgwKBQQAAgIDEgM6FBUKMgoEBAACAxIDPQIs
GiUgVGhlIGNyZWF0aW9uIHRpbWUgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgMGEgM9AhsK
DAoFBAACAwESAz0cJwoMCgUEAAIDAxIDPSorCjUKBAQAAgQSA0ACLBooIFRoZSBsYXN0IHVw
ZGF0ZSB0aW1lIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAAIEBhIDQAIbCgwKBQQAAgQBEgNA
HCcKDAoFBAACBAMSA0AqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::OperationMetadata::CommonOperationMetadata ===
    # Fields for CommonOperationMetadata
    # Field: state Type: 14 (.google.cloud.documentai.v1beta3.CommonOperationMetadata.State)
    # Field: state_message Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: CommonOperationMetadata::State
our $CommonOperationMetadata_STATE_UNSPECIFIED = 0;
our $CommonOperationMetadata_RUNNING = 1;
our $CommonOperationMetadata_CANCELLING = 2;
our $CommonOperationMetadata_SUCCEEDED = 3;
our $CommonOperationMetadata_FAILED = 4;
our $CommonOperationMetadata_CANCELLED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::OperationMetadata;

    my $msg = Google::Cloud::Documentai::V1beta3::OperationMetadata::CommonOperationMetadata->new({
        state => $state,
        state_message => $state_message,
        resource => $resource,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->state();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::OperationMetadata::CommonOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::OperationMetadata::CommonOperationMetadata

The common metadata for long running operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::CommonOperationMetadata::State>)

The state of the operation.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

A message providing more details about the current state of processing.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

A related resource to this operation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The creation time of the operation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last update time of the operation.

=back

=head3 Enum: CommonOperationMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<CANCELLING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<CANCELLED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
