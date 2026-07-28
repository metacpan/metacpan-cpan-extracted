package Google::Iam::V1::Logging::AuditData;

use strict;
use warnings;

our $VERSION = '0.11';

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

=pod

=head1 NAME

Google::Iam::V1::Logging::AuditData::AuditData - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Iam::V1::Logging::AuditData;

    my $msg = Google::Iam::V1::Logging::AuditData::AuditData->new(
        policy_delta => $value,
    );

=head1 FIELDS

=over 4

=item * B<policy_delta>

Type: Message (.google.iam.v1.PolicyDelta)

=back

=cut

1;

__END__

=head1 NAME

Google::Iam::V1::Logging::AuditData - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
