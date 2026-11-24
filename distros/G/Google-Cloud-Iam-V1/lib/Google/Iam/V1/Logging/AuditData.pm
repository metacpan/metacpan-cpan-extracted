package Google::Iam::V1::Logging::AuditData;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Iam::V1::Policy };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvaWFtL3YxL2xvZ2dpbmcvYXVkaXRfZGF0YS5wcm90bxIVZ29vZ2xlLmlhbS52
MS5sb2dnaW5nGhpnb29nbGUvaWFtL3YxL3BvbGljeS5wcm90byJKCglBdWRpdERhdGESPQoM
cG9saWN5X2RlbHRhGAIgASgLMhouZ29vZ2xlLmlhbS52MS5Qb2xpY3lEZWx0YVILcG9saWN5
RGVsdGFChgEKGWNvbS5nb29nbGUuaWFtLnYxLmxvZ2dpbmdCDkF1ZGl0RGF0YVByb3RvUAFa
OWNsb3VkLmdvb2dsZS5jb20vZ28vaWFtL2FwaXYxL2xvZ2dpbmcvbG9nZ2luZ3BiO2xvZ2dp
bmdwYqoCG0dvb2dsZS5DbG91ZC5JYW0uVjEuTG9nZ2luZ0rxBwoGEgQOACABCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAeCgkKAgMAEgMSACQKCAoBCBID
FAA4CgkKAgglEgMUADgKCAoBCBIDFQBQCgkKAggLEgMVAFAKCAoBCBIDFgAiCgkKAggKEgMW
ACIKCAoBCBIDFwAvCgkKAggIEgMXAC8KCAoBCBIDGAAyCgkKAggBEgMYADIKoAEKAgQAEgQd
ACABGpMBIEF1ZGl0IGxvZyBpbmZvcm1hdGlvbiBzcGVjaWZpYyB0byBDbG91ZCBJQU0uIFRo
aXMgbWVzc2FnZSBpcyBzZXJpYWxpemVkCiBhcyBhbiBgQW55YCB0eXBlIGluIHRoZSBgU2Vy
dmljZURhdGFgIG1lc3NhZ2Ugb2YgYW4KIGBBdWRpdExvZ2AgbWVzc2FnZS4KCgoKAwQAARID
HQgRClEKBAQAAgASAx8CLRpEIFBvbGljeSBkZWx0YSBiZXR3ZWVuIHRoZSBvcmlnaW5hbCBw
b2xpY3kgYW5kIHRoZSBuZXdseSBzZXQgcG9saWN5LgoKDAoFBAACAAYSAx8CGwoMCgUEAAIA
ARIDHxwoCgwKBQQAAgADEgMfKyxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V1::Logging::AuditData::AuditData ===
    # Fields for AuditData
    # Field: policy_delta Type: 11 (.google.iam.v1.PolicyDelta)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V1::Logging::AuditData - Compiled Protocol Buffers messages for google/iam/v1/logging/audit_data.proto

=head1 SYNOPSIS

    use Google::Iam::V1::Logging::AuditData;

    my $msg = Google::Iam::V1::Logging::AuditData::AuditData->new({
        policy_delta => $policy_delta,
    });

    # Read or update a field
    my $val = $msg->policy_delta();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V1::Logging::AuditData::AuditData->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v1/logging/audit_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V1::Logging::AuditData::AuditData

Audit log information specific to Cloud IAM. This message is serialized
as an `Any` type in the `ServiceData` message of an
`AuditLog` message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_delta() >> / C<< $msg->policy_delta($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::PolicyDelta>)

Policy delta between the original policy and the newly set policy.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V1::Logging::AuditData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
