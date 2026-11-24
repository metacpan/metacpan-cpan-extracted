package Google::Cloud::Datacatalog::V1beta1::Timestamps;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS90aW1lc3RhbXBzLnByb3RvEiBn
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLOAQoQU3lzdGVt
VGltZXN0YW1wcxI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEkAKC2V4cGlyZV90aW1lGAMgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpleHBpcmVUaW1lQtwBCiRjb20uZ29vZ2xlLmNs
b3VkLmRhdGFjYXRhbG9nLnYxYmV0YTFQAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0
YWxvZy9hcGl2MWJldGExL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCIEdvb2dsZS5D
bG91ZC5EYXRhQ2F0YWxvZy5WMUJldGExygIgR29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYx
YmV0YTHqAiNHb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFiZXRhMUqHCgoGEgQOACgB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMS
ACkKCQoCAwESAxMAKQoICgEIEgMVAD0KCQoCCCUSAxUAPQoICgEIEgMWAF0KCQoCCAsSAxYA
XQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAD0KCQoCCAESAxgAPQoICgEIEgMZAD0K
CQoCCCkSAxkAPQoICgEIEgMaADwKCQoCCC0SAxoAPApOCgIEABIEHQAoARpCIFRpbWVzdGFt
cHMgYWJvdXQgdGhpcyByZXNvdXJjZSBhY2NvcmRpbmcgdG8gYSBwYXJ0aWN1bGFyIHN5c3Rl
bS4KCgoKAwQAARIDHQgYCkkKBAQAAgASAx8CLBo8IFRoZSBjcmVhdGlvbiB0aW1lIG9mIHRo
ZSByZXNvdXJjZSB3aXRoaW4gdGhlIGdpdmVuIHN5c3RlbS4KCgwKBQQAAgAGEgMfAhsKDAoF
BAACAAESAx8cJwoMCgUEAAIAAxIDHyorCk4KBAQAAgESAyICLBpBIFRoZSBsYXN0LW1vZGlm
aWVkIHRpbWUgb2YgdGhlIHJlc291cmNlIHdpdGhpbiB0aGUgZ2l2ZW4gc3lzdGVtLgoKDAoF
BAACAQYSAyICGwoMCgUEAAIBARIDIhwnCgwKBQQAAgEDEgMiKisKiwEKBAQAAgISBCYCJzIa
fSBPdXRwdXQgb25seS4gVGhlIGV4cGlyYXRpb24gdGltZSBvZiB0aGUgcmVzb3VyY2Ugd2l0
aGluIHRoZSBnaXZlbiBzeXN0ZW0uCiBDdXJyZW50bHkgb25seSBhcGxsaWNhYmxlIHRvIEJp
Z1F1ZXJ5IHJlc291cmNlcy4KCgwKBQQAAgIGEgMmAhsKDAoFBAACAgESAyYcJwoMCgUEAAIC
AxIDJiorCgwKBQQAAgIIEgMnBjEKDwoIBAACAgicCAASAycHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps ===
    # Fields for SystemTimestamps
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Timestamps - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/timestamps.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Timestamps;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps->new({
        create_time => $create_time,
        update_time => $update_time,
        expire_time => $expire_time,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/timestamps.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps

Timestamps about this resource according to a particular system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The creation time of the resource within the given system.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last-modified time of the resource within the given system.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The expiration time of the resource within the given system.
Currently only apllicable to BigQuery resources.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Timestamps::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
