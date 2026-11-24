package Google::Cloud::Gkehub::Metering::V1alpha::Metering;

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
CjNnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvbWV0ZXJpbmcvbWV0ZXJpbmcucHJvdG8S
JGdvb2dsZS5jbG91ZC5na2VodWIubWV0ZXJpbmcudjFhbHBoYRofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byK+AQoPTWVtYmVyc2hpcFN0YXRlEk4KFWxhc3RfbWVhc3VyZW1l
bnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSE2xhc3RNZWFzdXJl
bWVudFRpbWUSWworcHJlY2lzZV9sYXN0X21lYXN1cmVkX2NsdXN0ZXJfdmNwdV9jYXBhY2l0
eRgDIAEoAlImcHJlY2lzZUxhc3RNZWFzdXJlZENsdXN0ZXJWY3B1Q2FwYWNpdHlC+gEKKGNv
bS5nb29nbGUuY2xvdWQuZ2tlaHViLm1ldGVyaW5nLnYxYWxwaGFCDU1ldGVyaW5nUHJvdG9Q
AVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9na2VodWIvbWV0ZXJpbmcvYXBpdjFhbHBoYS9tZXRl
cmluZ3BiO21ldGVyaW5ncGKqAiRHb29nbGUuQ2xvdWQuR2tlSHViLk1ldGVyaW5nLlYxQWxw
aGHKAiRHb29nbGVcQ2xvdWRcR2tlSHViXE1ldGVyaW5nXFYxYWxwaGHqAihHb29nbGU6OkNs
b3VkOjpHa2VIdWI6Ok1ldGVyaW5nOjpWMWFscGhhSuAICgYSBA4AJQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoICgEIEgMUAEEK
CQoCCCUSAxQAQQoICgEIEgMVAFsKCQoCCAsSAxUAWwoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXAC4KCQoCCAgSAxcALgoICgEIEgMYAEEKCQoCCAESAxgAQQoICgEIEgMZAEIKCQoC
CCkSAxkAQgoICgEIEgMaAEEKCQoCCC0SAxoAQQo5CgIEABIEHQAlARotICoqTWV0ZXJpbmcq
KjogUGVyLU1lbWJlcnNoaXAgRmVhdHVyZSBTdGF0ZS4KCgoKAwQAARIDHQgXCmQKBAQAAgAS
AyACNhpXIFRoZSB0aW1lIHN0YW1wIG9mIHRoZSBtb3N0IHJlY2VudCBtZWFzdXJlbWVudCBv
ZiB0aGUgbnVtYmVyIG9mIHZDUFVzCiBpbiB0aGUgY2x1c3Rlci4KCgwKBQQAAgAGEgMgAhsK
DAoFBAACAAESAyAcMQoMCgUEAAIAAxIDIDQ1Cm4KBAQAAgESAyQCOBphIFRoZSB2Q1BVcyBj
YXBhY2l0eSBpbiB0aGUgY2x1c3RlciBhY2NvcmRpbmcgdG8gdGhlIG1vc3QgcmVjZW50CiBt
ZWFzdXJlbWVudCAoMS8xMDAwIHByZWNpc2lvbikuCgoMCgUEAAIBBRIDJAIHCgwKBQQAAgEB
EgMkCDMKDAoFBAACAQMSAyQ2N2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Metering::V1alpha::Metering::MembershipState ===
    # Fields for MembershipState
    # Field: last_measurement_time Type: 11 (.google.protobuf.Timestamp)
    # Field: precise_last_measured_cluster_vcpu_capacity Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Metering::V1alpha::Metering - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/metering/metering.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Metering::V1alpha::Metering;

    my $msg = Google::Cloud::Gkehub::Metering::V1alpha::Metering::MembershipState->new({
        last_measurement_time => $last_measurement_time,
        precise_last_measured_cluster_vcpu_capacity => $precise_last_measured_cluster_vcpu_capacity,
    });

    # Read or update a field
    my $val = $msg->last_measurement_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Metering::V1alpha::Metering::MembershipState->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/metering/metering.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Metering::V1alpha::Metering::MembershipState

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Metering::V1alpha::Metering::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
