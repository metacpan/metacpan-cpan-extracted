package Google::Cloud::Metastore::Logging::V1::LogStreams;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvbWV0YXN0b3JlL2xvZ2dpbmcvdjEvbG9nX3N0cmVhbXMucHJvdG8S
IWdvb2dsZS5jbG91ZC5tZXRhc3RvcmUubG9nZ2luZy52MSIsChBSZXF1ZXN0c0xvZ0VudHJ5
EhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2UiMgoWU3lzdGVtQWN0aXZpdHlMb2dFbnRyeRIY
CgdtZXNzYWdlGAEgASgJUgdtZXNzYWdlQncKIWdvb2dsZS5jbG91ZC5tZXRhc3RvcmUubG9n
Z2luZy52MUIPTG9nU3RyZWFtc1Byb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20vZ28vbWV0YXN0
b3JlL2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYkreCAoGEgQOACMBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCggKAQgSAxIAVgoJCgII
CxIDEgBWCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQAMAoJCgIICBIDFAAwCggKAQgS
AxUAOgoJCgIIARIDFQA6CmQKAgQAEgQZABwBGlggU3RhY2tkcml2ZXIgc3RydWN0dXJlZC1w
YXlsb2FkIGZvciBldmVudHMgZ2VuZXJhdGVkIGZyb20gSGl2ZSBNZXRhc3RvcmUKIEFQSSBy
ZXF1ZXN0cy4KCgoKAwQAARIDGQgYCjkKBAQAAgASAxsCFRosIEEgZnJlZS10ZXh0IHN0cmlu
ZyBkZXNjcmliaW5nIHRoZSByZXF1ZXN0LgoKDAoFBAACAAUSAxsCCAoMCgUEAAIAARIDGwkQ
CgwKBQQAAgADEgMbExQKZwoCBAESBCAAIwEaWyBTdGFja2RyaXZlciBzdHJ1Y3R1cmVkLXBh
eWxvYWQgZm9yIGV2ZW50cyBnZW5lcmF0ZWQgZnJvbSBIaXZlIE1ldGFzdG9yZQogc3lzdGVt
IGFjdGl2aXR5LgoKCgoDBAEBEgMgCB4KQQoEBAECABIDIgIVGjQgQSBmcmVlLXRleHQgc3Ry
aW5nIGRlc2NyaWJpbmcgdGhlIHN5c3RlbSBhY3Rpdml0eS4KCgwKBQQBAgAFEgMiAggKDAoF
BAECAAESAyIJEAoMCgUEAQIAAxIDIhMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry ===
    # Fields for RequestsLogEntry
    # Field: message Type: 9 ()

# === Message: Google::Cloud::Metastore::Logging::V1::LogStreams::SystemActivityLogEntry ===
    # Fields for SystemActivityLogEntry
    # Field: message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Metastore::Logging::V1::LogStreams - Compiled Protocol Buffers messages for google/cloud/metastore/logging/v1/log_streams.proto

=head1 SYNOPSIS

    use Google::Cloud::Metastore::Logging::V1::LogStreams;

    my $msg = Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry->new({
        message => $message,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/metastore/logging/v1/log_streams.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Metastore::Logging::V1::LogStreams::RequestsLogEntry

Stackdriver structured-payload for events generated from Hive Metastore
API requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

A free-text string describing the request.

=back

=head2 Google::Cloud::Metastore::Logging::V1::LogStreams::SystemActivityLogEntry

Stackdriver structured-payload for events generated from Hive Metastore
system activity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

A free-text string describing the system activity.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Metastore::Logging::V1::LogStreams::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
