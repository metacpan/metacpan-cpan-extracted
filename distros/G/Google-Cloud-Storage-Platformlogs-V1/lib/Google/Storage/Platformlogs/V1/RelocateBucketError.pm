package Google::Storage::Platformlogs::V1::RelocateBucketError;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvc3RvcmFnZS9wbGF0Zm9ybWxvZ3MvdjEvcmVsb2NhdGVfYnVja2V0X2Vycm9y
LnByb3RvEh5nb29nbGUuc3RvcmFnZS5wbGF0Zm9ybWxvZ3MudjEaF2dvb2dsZS9ycGMvc3Rh
dHVzLnByb3RvItEFChNSZWxvY2F0ZUJ1Y2tldEVycm9yEhoKCHJlc291cmNlGAEgASgJUghy
ZXNvdXJjZRIbCglvYmplY3RfaWQYAiABKAlSCG9iamVjdElkEicKD3NvdXJjZV9sb2NhdGlv
bhgDIAEoCVIOc291cmNlTG9jYXRpb24SMQoUZGVzdGluYXRpb25fbG9jYXRpb24YBCABKAlS
E2Rlc3RpbmF0aW9uTG9jYXRpb24SkwEKHnNvdXJjZV9jdXN0b21fcGxhY2VtZW50X2NvbmZp
ZxgFIAEoCzJJLmdvb2dsZS5zdG9yYWdlLnBsYXRmb3JtbG9ncy52MS5SZWxvY2F0ZUJ1Y2tl
dEVycm9yLkN1c3RvbVBsYWNlbWVudENvbmZpZ0gAUhtzb3VyY2VDdXN0b21QbGFjZW1lbnRD
b25maWeIAQESnQEKI2Rlc3RpbmF0aW9uX2N1c3RvbV9wbGFjZW1lbnRfY29uZmlnGAYgASgL
MkkuZ29vZ2xlLnN0b3JhZ2UucGxhdGZvcm1sb2dzLnYxLlJlbG9jYXRlQnVja2V0RXJyb3Iu
Q3VzdG9tUGxhY2VtZW50Q29uZmlnSAFSIGRlc3RpbmF0aW9uQ3VzdG9tUGxhY2VtZW50Q29u
ZmlniAEBEj8KEXJlbG9jYXRpb25fZXJyb3JzGAcgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNS
EHJlbG9jYXRpb25FcnJvcnMSIwoNdmFsaWRhdGVfb25seRgIIAEoCFIMdmFsaWRhdGVPbmx5
Gj4KFUN1c3RvbVBsYWNlbWVudENvbmZpZxIlCg5kYXRhX2xvY2F0aW9ucxgBIAMoCVINZGF0
YUxvY2F0aW9uc0IhCh9fc291cmNlX2N1c3RvbV9wbGFjZW1lbnRfY29uZmlnQiYKJF9kZXN0
aW5hdGlvbl9jdXN0b21fcGxhY2VtZW50X2NvbmZpZ0KHAgoiY29tLmdvb2dsZS5zdG9yYWdl
LnBsYXRmb3JtbG9ncy52MUIYUmVsb2NhdGVCdWNrZXRFcnJvclByb3RvUAFaTGNsb3VkLmdv
b2dsZS5jb20vZ28vc3RvcmFnZS9wbGF0Zm9ybWxvZ3MvYXBpdjEvcGxhdGZvcm1sb2dzcGI7
cGxhdGZvcm1sb2dzcGKqAiRHb29nbGUuQ2xvdWQuU3RvcmFnZS5QbGF0Zm9ybUxvZ3MuVjHK
AiRHb29nbGVcQ2xvdWRcU3RvcmFnZVxQbGF0Zm9ybUxvZ3NcVjHqAihHb29nbGU6OkNsb3Vk
OjpTdG9yYWdlOjpQbGF0Zm9ybUxvZ3M6OlYxStESCgYSBA4AQgEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIQoICgEIEgMUAEEKCQoC
CCUSAxQAQQoICgEIEgMVAGMKCQoCCAsSAxUAYwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADkKCQoCCAgSAxcAOQoICgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZAEIKCQoCCCkS
AxkAQgoICgEIEgMaAEEKCQoCCC0SAxoAQQqXAQoCBAASBB4AQgEaigEgVGhlIHByb3RvIHBh
eWxvYWQgZm9yIFJlbG9jYXRlIEJ1Y2tldCBDbG91ZCBMb2dnaW5nLiBPbmx5IG9iamVjdHMg
dGhhdAogZXhwZXJpZW5jZSBlcnJvcnMgKHVzdWFsbHkgdW5zdXBwb3J0ZWQgZmVhdHVyZXMp
IHdpbGwgYmUgbG9nZ2VkLgoKCgoDBAABEgMeCBsKcgoEBAADABIEIQIkAxpkIENvbmZpZ3Vy
YXRpb24gZm9yIEN1c3RvbSBEdWFsIFJlZ2lvbnMuIEl0IHNwZWNpZmllcyBlbGlnaWJsZSBy
ZWdpb25zIHdpdGhpbgogdGhlIHNhbWUgTXVsdGlyZWdpb24uCgoMCgUEAAMAARIDIQofCj0K
BgQAAwACABIDIwQnGi4gTGlzdCBvZiBsb2NhdGlvbnMgdG8gdXNlIGZvciBkYXRhIHBsYWNl
bWVudC4KCg4KBwQAAwACAAQSAyMEDAoOCgcEAAMAAgAFEgMjDRMKDgoHBAADAAIAARIDIxQi
Cg4KBwQAAwACAAMSAyMlJgpfCgQEAAIAEgMoAhYaUiBUaGUgZnVsbCByZXNvdXJjZSBuYW1l
LCBmb2xsb3dpbmcgdGhlIGZvcm1hdDoKICdwcm9qZWN0cy9fL2J1Y2tldHMve2J1Y2tldF9p
ZH0nLgoKDAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkRCgwKBQQAAgADEgMoFBUKTwoEBAAC
ARIDKwIXGkIgVGhlIG9iamVjdCBpZCBvZiBhbiBvYmplY3QgdGhhdCBpcyBub3Qgc3VwcG9y
dGVkIGZvciByZWxvY2F0aW9uLgoKDAoFBAACAQUSAysCCAoMCgUEAAIBARIDKwkSCgwKBQQA
AgEDEgMrFRYKhAEKBAQAAgISAy8CHRp3IFRoZSBvcmlnaW5hbCBsb2NhdGlvbiBvZiB0aGUg
YnVja2V0LiBUaGUgbG9jYXRpb24gaXMgYSByZWdpb24vbXV0bGlyZWdpb24sCiBzdWNoIGFz
ICd1cycsICd1cy1jZW50cmFsMScsICdhc2lhJywgZXRjLgoKDAoFBAACAgUSAy8CCAoMCgUE
AAICARIDLwkYCgwKBQQAAgIDEgMvGxwKhwEKBAQAAgMSAzMCIhp6IFRoZSBkZXN0aW5hdGlv
biBsb2NhdGlvbiBvZiB0aGUgYnVja2V0LiBUaGUgbG9jYXRpb24gaXMgYQogcmVnaW9uL211
dGxpcmVnaW9uLCBzdWNoIGFzICd1cycsICd1cy1jZW50cmFsMScsICdhc2lhJywgZXRjLgoK
DAoFBAACAwUSAzMCCAoMCgUEAAIDARIDMwkdCgwKBQQAAgMDEgMzICEKOgoEBAACBBIDNgJE
Gi0gSWYgc2V0LCB0aGUgc291cmNlIGlzIGEgY3VzdG9tIGR1YWwgcmVnaW9uLgoKDAoFBAAC
BAQSAzYCCgoMCgUEAAIEBhIDNgsgCgwKBQQAAgQBEgM2IT8KDAoFBAACBAMSAzZCQwo/CgQE
AAIFEgM5AkkaMiBJZiBzZXQsIHRoZSBkZXN0aW5hdGlvbiBpcyBhIGN1c3RvbSBkdWFsIHJl
Z2lvbi4KCgwKBQQAAgUEEgM5AgoKDAoFBAACBQYSAzkLIAoMCgUEAAIFARIDOSFECgwKBQQA
AgUDEgM5R0gKoQEKBAQAAgYSAz0CMxqTASBUaGUgbGlzdCBvZiBlcnJvcnMgKG9yaWdpbmFs
bHkgZW51bXMpIHRoYXQgd2VyZSBlbmNvdW50ZXJlZCBkdXJpbmcgdGhlCiByZWxvY2F0aW9u
LCBzdHJpbmdpZmllZCBhbmQgd3JhcHBlZCBpbiBnb29nbGUucnBjLlN0YXR1cyBkZXRhaWxz
IHNlY3Rpb24uCgoMCgUEAAIGBBIDPQIKCgwKBQQAAgYGEgM9CxwKDAoFBAACBgESAz0dLgoM
CgUEAAIGAxIDPTEyClsKBAQAAgcSA0ECGRpOIFdoZW4gdHJ1ZSwgdmFsaWRhdGUgdGhlIG9w
ZXJhdGlvbiwgYnV0IGRvIG5vdCBhY3R1YWxseSByZWxvY2F0ZSB0aGUKIGJ1Y2tldC4KCgwK
BQQAAgcFEgNBAgYKDAoFBAACBwESA0EHFAoMCgUEAAIHAxIDQRcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError ===
    # Fields for RelocateBucketError
    # Field: resource Type: 9 ()
    # Field: object_id Type: 9 ()
    # Field: source_location Type: 9 ()
    # Field: destination_location Type: 9 ()
    # Field: source_custom_placement_config Type: 11 (.google.storage.platformlogs.v1.RelocateBucketError.CustomPlacementConfig)
    # Field: destination_custom_placement_config Type: 11 (.google.storage.platformlogs.v1.RelocateBucketError.CustomPlacementConfig)
    # Field: relocation_errors Type: 11 (.google.rpc.Status)
    # Field: validate_only Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Storage::Platformlogs::V1::RelocateBucketError - Compiled Protocol Buffers messages for google/storage/platformlogs/v1/relocate_bucket_error.proto

=head1 SYNOPSIS

    use Google::Storage::Platformlogs::V1::RelocateBucketError;

    my $msg = Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError->new({
        resource => $resource,
        object_id => $object_id,
        source_location => $source_location,
        destination_location => $destination_location,
    });

    # Read or update a field
    my $val = $msg->resource();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/storage/platformlogs/v1/relocate_bucket_error.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError

The proto payload for Relocate Bucket Cloud Logging. Only objects that
experience errors (usually unsupported features) will be logged.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

The full resource name, following the format:
'projects/_/buckets/{bucket_id}'.

=item * C<< $msg->object_id() >> / C<< $msg->object_id($value) >>

Type: C<String>

The object id of an object that is not supported for relocation.

=item * C<< $msg->source_location() >> / C<< $msg->source_location($value) >>

Type: C<String>

The original location of the bucket. The location is a region/mutliregion,
such as 'us', 'us-central1', 'asia', etc.

=item * C<< $msg->destination_location() >> / C<< $msg->destination_location($value) >>

Type: C<String>

The destination location of the bucket. The location is a
region/mutliregion, such as 'us', 'us-central1', 'asia', etc.

=item * C<< $msg->source_custom_placement_config() >> / C<< $msg->source_custom_placement_config($value) >>

Type: C<Message> (L<Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError::CustomPlacementConfig>)

If set, the source is a custom dual region.

=item * C<< $msg->destination_custom_placement_config() >> / C<< $msg->destination_custom_placement_config($value) >>

Type: C<Message> (L<Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError::CustomPlacementConfig>)

If set, the destination is a custom dual region.

=item * C<< $msg->relocation_errors() >> / C<< $msg->relocation_errors($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The list of errors (originally enums) that were encountered during the
relocation, stringified and wrapped in google.rpc.Status details section.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

When true, validate the operation, but do not actually relocate the
bucket.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Storage::Platformlogs::V1::RelocateBucketError::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
