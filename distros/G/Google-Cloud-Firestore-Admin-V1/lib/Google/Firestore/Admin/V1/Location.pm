package Google::Firestore::Admin::V1::Location;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL2xvY2F0aW9uLnByb3RvEhlnb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxIhIKEExvY2F0aW9uTWV0YWRhdGFC3AEKHWNvbS5nb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxQg1Mb2NhdGlvblByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28v
ZmlyZXN0b3JlL2FwaXYxL2FkbWluL2FkbWlucGI7YWRtaW5wYqICBEdDRlOqAh9Hb29nbGUu
Q2xvdWQuRmlyZXN0b3JlLkFkbWluLlYxygIfR29vZ2xlXENsb3VkXEZpcmVzdG9yZVxBZG1p
blxWMeoCI0dvb2dsZTo6Q2xvdWQ6OkZpcmVzdG9yZTo6QWRtaW46OlYxSoEHCgYSBA4AHRsK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACIKCAoBCBIDEgA8
CgkKAgglEgMSADwKCAoBCBIDEwBQCgkKAggLEgMTAFAKCAoBCBIDFAAiCgkKAggKEgMUACIK
CAoBCBIDFQAuCgkKAggIEgMVAC4KCAoBCBIDFgA2CgkKAggBEgMWADYKCAoBCBIDFwAiCgkK
AggkEgMXACIKCAoBCBIDGAA9CgkKAggpEgMYAD0KCAoBCBIDGQA8CgkKAggtEgMZADwKegoC
BAASAx0AGxpvIFRoZSBtZXRhZGF0YSBtZXNzYWdlIGZvcgogW2dvb2dsZS5jbG91ZC5sb2Nh
dGlvbi5Mb2NhdGlvbi5tZXRhZGF0YV1bZ29vZ2xlLmNsb3VkLmxvY2F0aW9uLkxvY2F0aW9u
Lm1ldGFkYXRhXS4KCgoKAwQAARIDHQgYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Location::LocationMetadata ===
    # Fields for LocationMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Location - Compiled Protocol Buffers messages for google/firestore/admin/v1/location.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Location;

    my $msg = Google::Firestore::Admin::V1::Location::LocationMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Location::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Location::LocationMetadata

The metadata message for
[google.cloud.location.Location.metadata][google.cloud.location.Location.metadata].

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Location::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
