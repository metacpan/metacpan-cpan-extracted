package Google::Cloud::Video::Stitcher::V1::FetchOptions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvZmV0Y2hfb3B0aW9ucy5wcm90bxIe
Z29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxIp8BCgxGZXRjaE9wdGlvbnMSUwoHaGVh
ZGVycxgBIAMoCzI5Lmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5GZXRjaE9wdGlv
bnMuSGVhZGVyc0VudHJ5UgdoZWFkZXJzGjoKDEhlYWRlcnNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQnkKImNvbS5nb29nbGUuY2xvdWQudmlk
ZW8uc3RpdGNoZXIudjFCEUZldGNoT3B0aW9uc1Byb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20v
Z28vdmlkZW8vc3RpdGNoZXIvYXBpdjEvc3RpdGNoZXJwYjtzdGl0Y2hlcnBiSuMHCgYSBA4A
HgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBID
EgBVCgkKAggLEgMSAFUKCAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAAyCgkKAggIEgMU
ADIKCAoBCBIDFQA7CgkKAggBEgMVADsKNAoCBAASBBgAHgEaKCBPcHRpb25zIG9uIGhvdyBm
ZXRjaGVzIHNob3VsZCBiZSBtYWRlLgoKCgoDBAABEgMYCBQKzwEKBAQAAgASAx0CIhrBASBD
dXN0b20gaGVhZGVycyB0byBwYXNzIGludG8gZmV0Y2ggcmVxdWVzdC4KIEhlYWRlcnMgbXVz
dCBoYXZlIGEgbWF4aW11bSBvZiAzIGtleSB2YWx1ZSBwYWlycy4KIEVhY2gga2V5IHZhbHVl
IHBhaXIgbXVzdCBoYXZlIGEgbWF4aW11bSBvZiAyNTYgY2hhcmFjdGVycyBwZXIga2V5IGFu
ZCAyNTYKIGNoYXJhY3RlcnMgcGVyIHZhbHVlLgoKDAoFBAACAAYSAx0CFQoMCgUEAAIAARID
HRYdCgwKBQQAAgADEgMdICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions ===
    # Fields for FetchOptions
    # Field: headers Type: 11 (.google.cloud.video.stitcher.v1.FetchOptions.HeadersEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::FetchOptions - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/fetch_options.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::FetchOptions;

    my $msg = Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions->new({
        headers => $headers,
    });

    # Read or update a field
    my $val = $msg->headers();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/fetch_options.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions

Options on how fetches should be made.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions::HeadersEntry>)

Custom headers to pass into fetch request.
Headers must have a maximum of 3 key value pairs.
Each key value pair must have a maximum of 256 characters per key and 256
characters per value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::FetchOptions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
