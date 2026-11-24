package Google::Cloud::Gkehub::Metering::V1beta::Metering;

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
CjJnb29nbGUvY2xvdWQvZ2tlaHViL3YxYmV0YS9tZXRlcmluZy9tZXRlcmluZy5wcm90bxIj
Z29vZ2xlLmNsb3VkLmdrZWh1Yi5tZXRlcmluZy52MWJldGEaH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8ivgEKD01lbWJlcnNoaXBTdGF0ZRJOChVsYXN0X21lYXN1cmVtZW50
X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhNsYXN0TWVhc3VyZW1l
bnRUaW1lElsKK3ByZWNpc2VfbGFzdF9tZWFzdXJlZF9jbHVzdGVyX3ZjcHVfY2FwYWNpdHkY
AyABKAJSJnByZWNpc2VMYXN0TWVhc3VyZWRDbHVzdGVyVmNwdUNhcGFjaXR5QvUBCidjb20u
Z29vZ2xlLmNsb3VkLmdrZWh1Yi5tZXRlcmluZy52MWJldGFCDU1ldGVyaW5nUHJvdG9QAVpD
Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2VodWIvbWV0ZXJpbmcvYXBpdjFiZXRhL21ldGVyaW5n
cGI7bWV0ZXJpbmdwYqoCI0dvb2dsZS5DbG91ZC5Ha2VIdWIuTWV0ZXJpbmcuVjFCZXRhygIj
R29vZ2xlXENsb3VkXEdrZUh1YlxNZXRlcmluZ1xWMWJldGHqAidHb29nbGU6OkNsb3VkOjpH
a2VIdWI6Ok1ldGVyaW5nOjpWMWJldGFK4AgKBhIEDgAlAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCggKAQgSAxQAQAoJCgIIJRID
FABACggKAQgSAxUAWgoJCgIICxIDFQBaCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcA
LgoJCgIICBIDFwAuCggKAQgSAxgAQAoJCgIIARIDGABACggKAQgSAxkAQQoJCgIIKRIDGQBB
CggKAQgSAxoAQAoJCgIILRIDGgBACjkKAgQAEgQdACUBGi0gKipNZXRlcmluZyoqOiBQZXIt
TWVtYmVyc2hpcCBGZWF0dXJlIFN0YXRlLgoKCgoDBAABEgMdCBcKZAoEBAACABIDIAI2Glcg
VGhlIHRpbWUgc3RhbXAgb2YgdGhlIG1vc3QgcmVjZW50IG1lYXN1cmVtZW50IG9mIHRoZSBu
dW1iZXIgb2YgdkNQVXMKIGluIHRoZSBjbHVzdGVyLgoKDAoFBAACAAYSAyACGwoMCgUEAAIA
ARIDIBwxCgwKBQQAAgADEgMgNDUKbgoEBAACARIDJAI4GmEgVGhlIHZDUFVzIGNhcGFjaXR5
IGluIHRoZSBjbHVzdGVyIGFjY29yZGluZyB0byB0aGUgbW9zdCByZWNlbnQKIG1lYXN1cmVt
ZW50ICgxLzEwMDAgcHJlY2lzaW9uKS4KCgwKBQQAAgEFEgMkAgcKDAoFBAACAQESAyQIMwoM
CgUEAAIBAxIDJDY3YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState ===
    # Fields for MembershipState
    # Field: last_measurement_time Type: 11 (.google.protobuf.Timestamp)
    # Field: precise_last_measured_cluster_vcpu_capacity Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Metering::V1beta::Metering - Compiled Protocol Buffers messages for google/cloud/gkehub/v1beta/metering/metering.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Metering::V1beta::Metering;

    my $msg = Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState->new({
        last_measurement_time => $last_measurement_time,
        precise_last_measured_cluster_vcpu_capacity => $precise_last_measured_cluster_vcpu_capacity,
    });

    # Read or update a field
    my $val = $msg->last_measurement_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1beta/metering/metering.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState

B<Metering>: Per-Membership Feature State.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_measurement_time() >> / C<< $msg->last_measurement_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time stamp of the most recent measurement of the number of vCPUs
in the cluster.

=item * C<< $msg->precise_last_measured_cluster_vcpu_capacity() >> / C<< $msg->precise_last_measured_cluster_vcpu_capacity($value) >>

Type: C<Float>

The vCPUs capacity in the cluster according to the most recent
measurement (1/1000 precision).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Metering::V1beta::Metering::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
