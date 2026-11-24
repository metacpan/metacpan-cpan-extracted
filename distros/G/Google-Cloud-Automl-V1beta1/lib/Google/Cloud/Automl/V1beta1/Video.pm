package Google::Cloud::Automl::V1beta1::Video;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdmlkZW8ucHJvdG8SG2dvb2dsZS5jbG91
ZC5hdXRvbWwudjFiZXRhMRowZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2NsYXNzaWZp
Y2F0aW9uLnByb3RvIiQKIlZpZGVvQ2xhc3NpZmljYXRpb25EYXRhc2V0TWV0YWRhdGEiJAoi
VmlkZW9PYmplY3RUcmFja2luZ0RhdGFzZXRNZXRhZGF0YSIiCiBWaWRlb0NsYXNzaWZpY2F0
aW9uTW9kZWxNZXRhZGF0YSIiCiBWaWRlb09iamVjdFRyYWNraW5nTW9kZWxNZXRhZGF0YUKn
AQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMUIKVmlkZW9Qcm90b1ABWjdjbG91
ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIb
R29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpW
MWJldGExSs8ICgYSBA4ALgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACQKCQoCAwASAxIAOgoICgEIEgMUAE4KCQoCCAsSAxQATgoICgEIEgMVACIKCQoC
CAoSAxUAIgoICgEIEgMWACsKCQoCCAgSAxYAKwoICgEIEgMXADgKCQoCCAESAxcAOAoICgEI
EgMYADgKCQoCCCkSAxgAOAoICgEIEgMZADcKCQoCCC0SAxkANwp/CgIEABIEHQAfARpzIERh
dGFzZXQgbWV0YWRhdGEgc3BlY2lmaWMgdG8gdmlkZW8gY2xhc3NpZmljYXRpb24uCiBBbGwg
VmlkZW8gQ2xhc3NpZmljYXRpb24gZGF0YXNldHMgYXJlIHRyZWF0ZWQgYXMgbXVsdGkgbGFi
ZWwuCgoKCgMEAAESAx0IKgpBCgIEARIEIgAkARo1IERhdGFzZXQgbWV0YWRhdGEgc3BlY2lm
aWMgdG8gdmlkZW8gb2JqZWN0IHRyYWNraW5nLgoKCgoDBAEBEgMiCCoKPgoCBAISBCcAKQEa
MiBNb2RlbCBtZXRhZGF0YSBzcGVjaWZpYyB0byB2aWRlbyBjbGFzc2lmaWNhdGlvbi4KCgoK
AwQCARIDJwgoCj8KAgQDEgQsAC4BGjMgTW9kZWwgbWV0YWRhdGEgc3BlY2lmaWMgdG8gdmlk
ZW8gb2JqZWN0IHRyYWNraW5nLgoKCgoDBAMBEgMsCChiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata ===
    # Fields for VideoClassificationDatasetMetadata

# === Message: Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata ===
    # Fields for VideoObjectTrackingDatasetMetadata

# === Message: Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata ===
    # Fields for VideoClassificationModelMetadata

# === Message: Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata ===
    # Fields for VideoObjectTrackingModelMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Video - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/video.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Video;

    my $msg = Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/video.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata

Dataset metadata specific to video classification.
All Video Classification datasets are treated as multi label.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata

Dataset metadata specific to video object tracking.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata

Model metadata specific to video classification.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata

Model metadata specific to video object tracking.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Video::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
