package Google::Firestore::Admin::V1beta1::Location;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Type::Latlng };
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTEvbG9jYXRpb24ucHJvdG8SHmdvb2ds
ZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMRoYZ29vZ2xlL3R5cGUvbGF0bG5nLnByb3RvGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvIhIKEExvY2F0aW9uTWV0YWRhdGFCowEKImNv
bS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTFCDUxvY2F0aW9uUHJvdG9QAVo+Y2xv
dWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYWRtaW4vYXBpdjFiZXRhMS9hZG1pbnBiO2Fk
bWlucGKiAgRHQ0ZTqgIkR29vZ2xlLkNsb3VkLkZpcmVzdG9yZS5BZG1pbi5WMUJldGExSu4G
CgYSBA8AIAEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAn
CgkKAgMAEgMTACIKCQoCAwESAxQAJgoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAFUK
CQoCCAsSAxcAVQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC4KCQoCCAgSAxkALgoI
CgEIEgMaADsKCQoCCAESAxoAOwoICgEIEgMbACIKCQoCCCQSAxsAIgp6CgIEABIEHgAgARpu
IFRoZSBtZXRhZGF0YSBtZXNzYWdlIGZvciBbZ29vZ2xlLmNsb3VkLmxvY2F0aW9uLkxvY2F0
aW9uLm1ldGFkYXRhXVtnb29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb24ubWV0YWRhdGFd
LgoKCgoDBAABEgMeCBhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta1::Location::LocationMetadata ===
    # Fields for LocationMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta1::Location - Compiled Protocol Buffers messages for google/firestore/admin/v1beta1/location.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta1::Location;

    my $msg = Google::Firestore::Admin::V1beta1::Location::LocationMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta1::Location::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta1/location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta1::Location::LocationMetadata

The metadata message for [google.cloud.location.Location.metadata][google.cloud.location.Location.metadata].

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta1::Location::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
