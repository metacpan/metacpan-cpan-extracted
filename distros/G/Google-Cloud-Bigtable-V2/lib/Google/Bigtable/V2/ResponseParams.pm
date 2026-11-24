package Google::Bigtable::V2::ResponseParams;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvYmlndGFibGUvdjIvcmVzcG9uc2VfcGFyYW1zLnByb3RvEhJnb29nbGUuYmln
dGFibGUudjIilAEKDlJlc3BvbnNlUGFyYW1zEhwKB3pvbmVfaWQYASABKAlIAFIGem9uZUlk
iAEBEiIKCmNsdXN0ZXJfaWQYAiABKAlIAVIJY2x1c3RlcklkiAEBEhoKBmFmZV9pZBgDIAEo
A0gCUgVhZmVJZIgBAUIKCghfem9uZV9pZEINCgtfY2x1c3Rlcl9pZEIJCgdfYWZlX2lkQr0B
ChZjb20uZ29vZ2xlLmJpZ3RhYmxlLnYyQhNSZXNwb25zZVBhcmFtc1Byb3RvUAFaOGNsb3Vk
Lmdvb2dsZS5jb20vZ28vYmlndGFibGUvYXBpdjIvYmlndGFibGVwYjtiaWd0YWJsZXBiqgIY
R29vZ2xlLkNsb3VkLkJpZ3RhYmxlLlYyygIYR29vZ2xlXENsb3VkXEJpZ3RhYmxlXFYy6gIb
R29vZ2xlOjpDbG91ZDo6QmlndGFibGU6OlYySp0JCgYSBA4AJQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABsKCAoBCBIDEgA1CgkKAgglEgMSADUKCAoB
CBIDEwBPCgkKAggLEgMTAE8KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA0CgkKAggI
EgMVADQKCAoBCBIDFgAvCgkKAggBEgMWAC8KCAoBCBIDFwA1CgkKAggpEgMXADUKCAoBCBID
GAA0CgkKAggtEgMYADQKJQoCBAASBBsAJQEaGSBSZXNwb25zZSBtZXRhZGF0YSBwcm90bwoK
CgoDBAABEgMbCBYKQwoEBAACABIDHQIeGjYgVGhlIGNsb3VkIGJpZ3RhYmxlIHpvbmUgYXNz
b2NpYXRlZCB3aXRoIHRoZSBjbHVzdGVyLgoKDAoFBAACAAQSAx0CCgoMCgUEAAIABRIDHQsR
CgwKBQQAAgABEgMdEhkKDAoFBAACAAMSAx0cHQpTCgQEAAIBEgMhAiEaRiBJZGVudGlmaWVy
IGZvciBhIGNsdXN0ZXIgdGhhdCByZXByZXNlbnRzIHNldCBvZgogYmlndGFibGUgcmVzb3Vy
Y2VzLgoKDAoFBAACAQQSAyECCgoMCgUEAAIBBRIDIQsRCgwKBQQAAgEBEgMhEhwKDAoFBAAC
AQMSAyEfIApCCgQEAAICEgMkAhwaNSBUaGUgQUZFIElEIGZvciB0aGUgQUZFIHRoYXQgaXMg
c2VydmVkIHRoaXMgcmVxdWVzdC4KCgwKBQQAAgIEEgMkAgoKDAoFBAACAgUSAyQLEAoMCgUE
AAICARIDJBEXCgwKBQQAAgIDEgMkGhtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Bigtable::V2::ResponseParams::ResponseParams ===
    # Fields for ResponseParams
    # Field: zone_id Type: 9 ()
    # Field: cluster_id Type: 9 ()
    # Field: afe_id Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Bigtable::V2::ResponseParams - Compiled Protocol Buffers messages for google/bigtable/v2/response_params.proto

=head1 SYNOPSIS

    use Google::Bigtable::V2::ResponseParams;

    my $msg = Google::Bigtable::V2::ResponseParams::ResponseParams->new({
        zone_id => $zone_id,
        cluster_id => $cluster_id,
        afe_id => $afe_id,
    });

    # Read or update a field
    my $val = $msg->zone_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Bigtable::V2::ResponseParams::ResponseParams->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/bigtable/v2/response_params.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Bigtable::V2::ResponseParams::ResponseParams

Response metadata proto

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->zone_id() >> / C<< $msg->zone_id($value) >>

Type: C<String>

The cloud bigtable zone associated with the cluster.

=item * C<< $msg->cluster_id() >> / C<< $msg->cluster_id($value) >>

Type: C<String>

Identifier for a cluster that represents set of
bigtable resources.

=item * C<< $msg->afe_id() >> / C<< $msg->afe_id($value) >>

Type: C<Int64>

The AFE ID for the AFE that is served this request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Bigtable::V2::ResponseParams::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
