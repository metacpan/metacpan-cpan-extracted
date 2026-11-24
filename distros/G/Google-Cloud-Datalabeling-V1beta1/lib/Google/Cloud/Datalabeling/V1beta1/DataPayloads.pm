package Google::Cloud::Datalabeling::V1beta1::DataPayloads;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvZGF0YV9wYXlsb2Fkcy5wcm90
bxIhZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGh5nb29nbGUvcHJvdG9idWYv
ZHVyYXRpb24ucHJvdG8ikAEKDEltYWdlUGF5bG9hZBIbCgltaW1lX3R5cGUYASABKAlSCG1p
bWVUeXBlEicKD2ltYWdlX3RodW1ibmFpbBgCIAEoDFIOaW1hZ2VUaHVtYm5haWwSGwoJaW1h
Z2VfdXJpGAMgASgJUghpbWFnZVVyaRIdCgpzaWduZWRfdXJpGAQgASgJUglzaWduZWRVcmki
MAoLVGV4dFBheWxvYWQSIQoMdGV4dF9jb250ZW50GAEgASgJUgt0ZXh0Q29udGVudCJqCg5W
aWRlb1RodW1ibmFpbBIcCgl0aHVtYm5haWwYASABKAxSCXRodW1ibmFpbBI6Cgt0aW1lX29m
ZnNldBgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIKdGltZU9mZnNldCLkAQoM
VmlkZW9QYXlsb2FkEhsKCW1pbWVfdHlwZRgBIAEoCVIIbWltZVR5cGUSGwoJdmlkZW9fdXJp
GAIgASgJUgh2aWRlb1VyaRJcChB2aWRlb190aHVtYm5haWxzGAMgAygLMjEuZ29vZ2xlLmNs
b3VkLmRhdGFsYWJlbGluZy52MWJldGExLlZpZGVvVGh1bWJuYWlsUg92aWRlb1RodW1ibmFp
bHMSHQoKZnJhbWVfcmF0ZRgEIAEoAlIJZnJhbWVSYXRlEh0KCnNpZ25lZF91cmkYBSABKAlS
CXNpZ25lZFVyaULjAQolY29tLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMVAB
WkljbG91ZC5nb29nbGUuY29tL2dvL2RhdGFsYWJlbGluZy9hcGl2MWJldGExL2RhdGFsYWJl
bGluZ3BiO2RhdGFsYWJlbGluZ3BiqgIhR29vZ2xlLkNsb3VkLkRhdGFMYWJlbGluZy5WMUJl
dGExygIhR29vZ2xlXENsb3VkXERhdGFMYWJlbGluZ1xWMWJldGEx6gIkR29vZ2xlOjpDbG91
ZDo6RGF0YUxhYmVsaW5nOjpWMWJldGExSocRCgYSBA8ASwEKvQQKAQwSAw8AEjKyBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAqCgkKAgMAEgMTACgKCAoBCBIDFQA+CgkKAggl
EgMVAD4KCAoBCBIDFgBgCgkKAggLEgMWAGAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBID
GAA+CgkKAggBEgMYAD4KCAoBCBIDGQA+CgkKAggpEgMZAD4KCAoBCBIDGgA9CgkKAggtEgMa
AD0KNgoCBAASBB0AKQEaKiBDb250YWluZXIgb2YgaW5mb3JtYXRpb24gYWJvdXQgYW4gaW1h
Z2UuCgoKCgMEAAESAx0IFAocCgQEAAIAEgMfAhcaDyBJbWFnZSBmb3JtYXQuCgoMCgUEAAIA
BRIDHwIICgwKBQQAAgABEgMfCRIKDAoFBAACAAMSAx8VFgoyCgQEAAIBEgMiAhwaJSBBIGJ5
dGUgc3RyaW5nIG9mIGEgdGh1bWJuYWlsIGltYWdlLgoKDAoFBAACAQUSAyICBwoMCgUEAAIB
ARIDIggXCgwKBQQAAgEDEgMiGhsKLgoEBAACAhIDJQIXGiEgSW1hZ2UgdXJpIGZyb20gdGhl
IHVzZXIgYnVja2V0LgoKDAoFBAACAgUSAyUCCAoMCgUEAAICARIDJQkSCgwKBQQAAgIDEgMl
FRYKQgoEBAACAxIDKAIYGjUgU2lnbmVkIHVyaSBvZiB0aGUgaW1hZ2UgZmlsZSBpbiB0aGUg
c2VydmljZSBidWNrZXQuCgoMCgUEAAIDBRIDKAIICgwKBQQAAgMBEgMoCRMKDAoFBAACAwMS
AygWFwo9CgIEARIELAAvARoxIENvbnRhaW5lciBvZiBpbmZvcm1hdGlvbiBhYm91dCBhIHBp
ZWNlIG9mIHRleHQuCgoKCgMEAQESAywIEwocCgQEAQIAEgMuAhoaDyBUZXh0IGNvbnRlbnQu
CgoMCgUEAQIABRIDLgIICgwKBQQBAgABEgMuCRUKDAoFBAECAAMSAy4YGQo8CgIEAhIEMgA5
ARowIENvbnRhaW5lciBvZiBpbmZvcm1hdGlvbiBvZiBhIHZpZGVvIHRodW1ibmFpbC4KCgoK
AwQCARIDMggWCjAKBAQCAgASAzQCFhojIEEgYnl0ZSBzdHJpbmcgb2YgdGhlIHZpZGVvIGZy
YW1lLgoKDAoFBAICAAUSAzQCBwoMCgUEAgIAARIDNAgRCgwKBQQCAgADEgM0FBUKkgEKBAQC
AgESAzgCKxqEASBUaW1lIG9mZnNldCByZWxhdGl2ZSB0byB0aGUgYmVnaW5uaW5nIG9mIHRo
ZSB2aWRlbywgY29ycmVzcG9uZGluZyB0byB0aGUKIHZpZGVvIGZyYW1lIHdoZXJlIHRoZSB0
aHVtYm5haWwgaGFzIGJlZW4gZXh0cmFjdGVkIGZyb20uCgoMCgUEAgIBBhIDOAIaCgwKBQQC
AgEBEgM4GyYKDAoFBAICAQMSAzgpKgoyCgIEAxIEPABLARomIENvbnRhaW5lciBvZiBpbmZv
cm1hdGlvbiBvZiBhIHZpZGVvLgoKCgoDBAMBEgM8CBQKHAoEBAMCABIDPgIXGg8gVmlkZW8g
Zm9ybWF0LgoKDAoFBAMCAAUSAz4CCAoMCgUEAwIAARIDPgkSCgwKBQQDAgADEgM+FRYKLgoE
BAMCARIDQQIXGiEgVmlkZW8gdXJpIGZyb20gdGhlIHVzZXIgYnVja2V0LgoKDAoFBAMCAQUS
A0ECCAoMCgUEAwIBARIDQQkSCgwKBQQDAgEDEgNBFRYKLAoEBAMCAhIDRAIvGh8gVGhlIGxp
c3Qgb2YgdmlkZW8gdGh1bWJuYWlscy4KCgwKBQQDAgIEEgNEAgoKDAoFBAMCAgYSA0QLGQoM
CgUEAwICARIDRBoqCgwKBQQDAgIDEgNELS4KIAoEBAMCAxIDRwIXGhMgRlBTIG9mIHRoZSB2
aWRlby4KCgwKBQQDAgMFEgNHAgcKDAoFBAMCAwESA0cIEgoMCgUEAwIDAxIDRxUWCkIKBAQD
AgQSA0oCGBo1IFNpZ25lZCB1cmkgb2YgdGhlIHZpZGVvIGZpbGUgaW4gdGhlIHNlcnZpY2Ug
YnVja2V0LgoKDAoFBAMCBAUSA0oCCAoMCgUEAwIEARIDSgkTCgwKBQQDAgQDEgNKFhdiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload ===
    # Fields for ImagePayload
    # Field: mime_type Type: 9 ()
    # Field: image_thumbnail Type: 12 ()
    # Field: image_uri Type: 9 ()
    # Field: signed_uri Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload ===
    # Fields for TextPayload
    # Field: text_content Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail ===
    # Fields for VideoThumbnail
    # Field: thumbnail Type: 12 ()
    # Field: time_offset Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload ===
    # Fields for VideoPayload
    # Field: mime_type Type: 9 ()
    # Field: video_uri Type: 9 ()
    # Field: video_thumbnails Type: 11 (.google.cloud.datalabeling.v1beta1.VideoThumbnail)
    # Field: frame_rate Type: 2 ()
    # Field: signed_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::DataPayloads - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/data_payloads.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::DataPayloads;

    my $msg = Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload->new({
        mime_type => $mime_type,
        image_thumbnail => $image_thumbnail,
        image_uri => $image_uri,
        signed_uri => $signed_uri,
    });

    # Read or update a field
    my $val = $msg->mime_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/data_payloads.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload

Container of information about an image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Image format.

=item * C<< $msg->image_thumbnail() >> / C<< $msg->image_thumbnail($value) >>

Type: C<Bytes>

A byte string of a thumbnail image.

=item * C<< $msg->image_uri() >> / C<< $msg->image_uri($value) >>

Type: C<String>

Image uri from the user bucket.

=item * C<< $msg->signed_uri() >> / C<< $msg->signed_uri($value) >>

Type: C<String>

Signed uri of the image file in the service bucket.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload

Container of information about a piece of text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_content() >> / C<< $msg->text_content($value) >>

Type: C<String>

Text content.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail

Container of information of a video thumbnail.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->thumbnail() >> / C<< $msg->thumbnail($value) >>

Type: C<Bytes>

A byte string of the video frame.

=item * C<< $msg->time_offset() >> / C<< $msg->time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time offset relative to the beginning of the video, corresponding to the
video frame where the thumbnail has been extracted from.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload

Container of information of a video.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Video format.

=item * C<< $msg->video_uri() >> / C<< $msg->video_uri($value) >>

Type: C<String>

Video uri from the user bucket.

=item * C<< $msg->video_thumbnails() >> / C<< $msg->video_thumbnails($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail>)

The list of video thumbnails.

=item * C<< $msg->frame_rate() >> / C<< $msg->frame_rate($value) >>

Type: C<Float>

FPS of the video.

=item * C<< $msg->signed_uri() >> / C<< $msg->signed_uri($value) >>

Type: C<String>

Signed uri of the video file in the service bucket.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
