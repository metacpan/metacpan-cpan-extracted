package Google::Monitoring::V3::MutationRecord;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvbW9uaXRvcmluZy92My9tdXRhdGlvbl9yZWNvcmQucHJvdG8SFGdvb2dsZS5t
b25pdG9yaW5nLnYzGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvImwKDk11dGF0
aW9uUmVjb3JkEjsKC211dGF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKbXV0YXRlVGltZRIdCgptdXRhdGVkX2J5GAIgASgJUgltdXRhdGVkQnlCzgEKGGNv
bS5nb29nbGUubW9uaXRvcmluZy52M0ITTXV0YXRpb25SZWNvcmRQcm90b1ABWkFjbG91ZC5n
b29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmluZ3BiO21vbml0b3Jp
bmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xlXENsb3VkXE1vbml0
b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0r1BwoGEgQOACMBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAdCgkKAgMAEgMSACkK
CAoBCBIDFAA3CgkKAgglEgMUADcKCAoBCBIDFQBYCgkKAggLEgMVAFgKCAoBCBIDFgAiCgkK
AggKEgMWACIKCAoBCBIDFwA0CgkKAggIEgMXADQKCAoBCBIDGAAxCgkKAggBEgMYADEKCAoB
CBIDGQA3CgkKAggpEgMZADcKCAoBCBIDGgA2CgkKAggtEgMaADYKOQoCBAASBB0AIwEaLSBE
ZXNjcmliZXMgYSBjaGFuZ2UgbWFkZSB0byBhIGNvbmZpZ3VyYXRpb24uCgoKCgMEAAESAx0I
FgooCgQEAAIAEgMfAiwaGyBXaGVuIHRoZSBjaGFuZ2Ugb2NjdXJyZWQuCgoMCgUEAAIABhID
HwIbCgwKBQQAAgABEgMfHCcKDAoFBAACAAMSAx8qKwo/CgQEAAIBEgMiAhgaMiBUaGUgZW1h
aWwgYWRkcmVzcyBvZiB0aGUgdXNlciBtYWtpbmcgdGhlIGNoYW5nZS4KCgwKBQQAAgEFEgMi
AggKDAoFBAACAQESAyIJEwoMCgUEAAIBAxIDIhYXYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::MutationRecord::MutationRecord ===
    # Fields for MutationRecord
    # Field: mutate_time Type: 11 (.google.protobuf.Timestamp)
    # Field: mutated_by Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::MutationRecord - Compiled Protocol Buffers messages for google/monitoring/v3/mutation_record.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::MutationRecord;

    my $msg = Google::Monitoring::V3::MutationRecord::MutationRecord->new({
        mutate_time => $mutate_time,
        mutated_by => $mutated_by,
    });

    # Read or update a field
    my $val = $msg->mutate_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::MutationRecord::MutationRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/mutation_record.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::MutationRecord::MutationRecord

Describes a change made to a configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mutate_time() >> / C<< $msg->mutate_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

When the change occurred.

=item * C<< $msg->mutated_by() >> / C<< $msg->mutated_by($value) >>

Type: C<String>

The email address of the user making the change.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::MutationRecord::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
