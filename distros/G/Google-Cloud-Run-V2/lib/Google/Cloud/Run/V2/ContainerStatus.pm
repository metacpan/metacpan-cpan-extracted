package Google::Cloud::Run::V2::ContainerStatus;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcnVuL3YyL2NvbnRhaW5lcl9zdGF0dXMucHJvdG8SE2dvb2dsZS5j
bG91ZC5ydW4udjIiSAoPQ29udGFpbmVyU3RhdHVzEhIKBG5hbWUYASABKAlSBG5hbWUSIQoM
aW1hZ2VfZGlnZXN0GAIgASgJUgtpbWFnZURpZ2VzdEJcChdjb20uZ29vZ2xlLmNsb3VkLnJ1
bi52MkIUQ29udGFpbmVyU3RhdHVzUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9ydW4v
YXBpdjIvcnVucGI7cnVucGJKmQkKBhIEDgAiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAHAoICgEIEgMSAEAKCQoCCAsSAxIAQAoICgEIEgMTACIKCQoC
CAoSAxMAIgoICgEIEgMUADUKCQoCCAgSAxQANQoICgEIEgMVADAKCQoCCAESAxUAMApeCgIE
ABIEGQAiARpSIENvbnRhaW5lclN0YXR1cyBob2xkcyB0aGUgaW5mb3JtYXRpb24gb2YgY29u
dGFpbmVyIG5hbWUgYW5kIGltYWdlIGRpZ2VzdAogdmFsdWUuCgoKCgMEAAESAxkIFwo3CgQE
AAIAEgMbAhIaKiBUaGUgbmFtZSBvZiB0aGUgY29udGFpbmVyLCBpZiBzcGVjaWZpZWQuCgoM
CgUEAAIABRIDGwIICgwKBQQAAgABEgMbCQ0KDAoFBAACAAMSAxsQEQr4AQoEBAACARIDIQIa
GuoBIEltYWdlRGlnZXN0IGhvbGRzIHRoZSByZXNvbHZlZCBkaWdlc3QgZm9yIHRoZSBpbWFn
ZSBzcGVjaWZpZWQgYW5kIHJlc29sdmVkCiBkdXJpbmcgdGhlIGNyZWF0aW9uIG9mIFJldmlz
aW9uLiBUaGlzIGZpZWxkIGhvbGRzIHRoZSBkaWdlc3QgdmFsdWUKIHJlZ2FyZGxlc3Mgb2Yg
d2hldGhlciBhIHRhZyBvciBkaWdlc3Qgd2FzIG9yaWdpbmFsbHkgc3BlY2lmaWVkIGluIHRo
ZQogQ29udGFpbmVyIG9iamVjdC4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJFQoMCgUE
AAIBAxIDIRgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::ContainerStatus::ContainerStatus ===
    # Fields for ContainerStatus
    # Field: name Type: 9 ()
    # Field: image_digest Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::ContainerStatus - Compiled Protocol Buffers messages for google/cloud/run/v2/container_status.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::ContainerStatus;

    my $msg = Google::Cloud::Run::V2::ContainerStatus::ContainerStatus->new({
        name => $name,
        image_digest => $image_digest,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::ContainerStatus::ContainerStatus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/container_status.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::ContainerStatus::ContainerStatus

ContainerStatus holds the information of container name and image digest
value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the container, if specified.

=item * C<< $msg->image_digest() >> / C<< $msg->image_digest($value) >>

Type: C<String>

ImageDigest holds the resolved digest for the image specified and resolved
during the creation of Revision. This field holds the digest value
regardless of whether a tag or digest was originally specified in the
Container object.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::ContainerStatus::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
