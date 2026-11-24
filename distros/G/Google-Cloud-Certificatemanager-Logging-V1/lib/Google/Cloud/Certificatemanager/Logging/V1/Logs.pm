package Google::Cloud::Certificatemanager::Logging::V1::Logs;

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
CjVnb29nbGUvY2xvdWQvY2VydGlmaWNhdGVtYW5hZ2VyL2xvZ2dpbmcvdjEvbG9ncy5wcm90
bxIqZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci5sb2dnaW5nLnYxGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqkCChJDZXJ0aWZpY2F0ZXNFeHBpcnkSFAoFY291
bnQYASABKANSBWNvdW50EiIKDGNlcnRpZmljYXRlcxgCIAMoCVIMY2VydGlmaWNhdGVzEloK
BXN0YXRlGAMgASgOMkQuZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci5sb2dnaW5n
LnYxLkNlcnRpZmljYXRlc0V4cGlyeS5TdGF0ZVIFc3RhdGUSOwoLZXhwaXJlX3RpbWUYBCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpleHBpcmVUaW1lIkAKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASEwoPQ0xPU0VfVE9fRVhQSVJZEAESCwoHRVhQSVJFRBAC
QpICCi5jb20uZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci5sb2dnaW5nLnYxQglM
b2dzUHJvdG9QAVpIY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXJ0aWZpY2F0ZW1hbmFnZXIvbG9n
Z2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgIqR29vZ2xlLkNsb3VkLkNlcnRpZmlj
YXRlTWFuYWdlci5Mb2dnaW5nLlYxygIqR29vZ2xlXENsb3VkXENlcnRpZmljYXRlTWFuYWdl
clxMb2dnaW5nXFYx6gIuR29vZ2xlOjpDbG91ZDo6Q2VydGlmaWNhdGVNYW5hZ2VyOjpMb2dn
aW5nOjpWMUrADQoGEgQOADgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAzCgkKAgMAEgMSACkKCAoBCBIDFABHCgkKAgglEgMUAEcKCAoBCBIDFQBfCgkK
AggLEgMVAF8KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAqCgkKAggIEgMXACoKCAoB
CBIDGABHCgkKAggBEgMYAEcKCAoBCBIDGQBICgkKAggpEgMZAEgKCAoBCBIDGgBHCgkKAggt
EgMaAEcKWAoCBAASBB4AOAEaTCBMb2cgbWVzc2FnZSB3aGljaCBub3RpZmllcyBhYm91dCBl
eHBpcmVkIG9yIGNsb3NlIHRvCiBleHBpcnkgY2VydGlmaWNhdGVzLgoKCgoDBAABEgMeCBoK
NAoEBAAEABIEIAIpAxomIEV4cGlyYXRpb24gc3RhdGUgb2YgdGhlIGNlcnRpZmljYXRlLgoK
DAoFBAAEAAESAyAHDAo9CgYEAAQAAgASAyIEGhouIFVuc3BlY2lmaWVkIHN0YXRlLCBzaG91
bGQgbmV2ZXIgYmUgcmVwb3J0ZWQuCgoOCgcEAAQAAgABEgMiBBUKDgoHBAAEAAIAAhIDIhgZ
Ci4KBgQABAACARIDJQQYGh8gQ2VydGlmaWNhdGUgd2lsbCBleHBpcmUgc29vbi4KCg4KBwQA
BAACAQESAyUEEwoOCgcEAAQAAgECEgMlFhcKKAoGBAAEAAICEgMoBBAaGSBDZXJ0aWZpY2F0
ZSBpcyBleHBpcmVkLgoKDgoHBAAEAAICARIDKAQLCg4KBwQABAACAgISAygODwovCgQEAAIA
EgMsAhIaIiBOdW1iZXIgb2YgcmVwb3J0ZWQgY2VydGlmaWNhdGVzLgoKDAoFBAACAAUSAywC
BwoMCgUEAAIAARIDLAgNCgwKBQQAAgADEgMsEBEKWgoEBAACARIDLwIjGk0gTmFtZXMgb2Yg
cmVwb3J0ZWQgY2VydGlmaWNhdGVzLiBJZiB0aGVyZSBhcmUgdG9vIG1hbnksIHRoZSBsaXN0
IGlzIHNhbXBsZWQuCgoMCgUEAAIBBBIDLwIKCgwKBQQAAgEFEgMvCxEKDAoFBAACAQESAy8S
HgoMCgUEAAIBAxIDLyEiCi4KBAQAAgISAzICEhohIFN0YXRlIG9mIHJlcG9ydGVkIGNlcnRp
ZmljYXRlcy4KCgwKBQQAAgIGEgMyAgcKDAoFBAACAgESAzIIDQoMCgUEAAICAxIDMhARCrgB
CgQEAAIDEgM3AiwaqgEgQXBwcm94aW1hdGVkIGV4cGlyZSB0aW1lIG9mIHJlcG9ydGVkIGNl
cnRpZmljYXRlcy4KIE11bHRpcGxlIGNlcnRpZmljYXRlcyB3aXRoIGNsb3NlIGV4cGlyZSB0
aW1lIGFyZSBiYXRjaGVkIHRvZ2V0aGVyIGluIGEKIHNpbmdsZSBsb2csIHNvIHRoZSB0aW1l
c3RhbXAgaXMgbm90IHByZWNpc2UuCgoMCgUEAAIDBhIDNwIbCgwKBQQAAgMBEgM3HCcKDAoF
BAACAwMSAzcqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry ===
    # Fields for CertificatesExpiry
    # Field: count Type: 3 ()
    # Field: certificates Type: 9 ()
    # Field: state Type: 14 (.google.cloud.certificatemanager.logging.v1.CertificatesExpiry.State)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# Enum: CertificatesExpiry::State
our $CertificatesExpiry_STATE_UNSPECIFIED = 0;
our $CertificatesExpiry_CLOSE_TO_EXPIRY = 1;
our $CertificatesExpiry_EXPIRED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Certificatemanager::Logging::V1::Logs - Compiled Protocol Buffers messages for google/cloud/certificatemanager/logging/v1/logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Certificatemanager::Logging::V1::Logs;

    my $msg = Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry->new({
        count => $count,
        certificates => $certificates,
        state => $state,
        expire_time => $expire_time,
    });

    # Read or update a field
    my $val = $msg->count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/certificatemanager/logging/v1/logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry

Log message which notifies about expired or close to
expiry certificates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int64>

Number of reported certificates.

=item * C<< $msg->certificates() >> / C<< $msg->certificates($value) >>

Type: C<String>

Names of reported certificates. If there are too many, the list is sampled.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Certificatemanager::Logging::V1::CertificatesExpiry::State>)

State of reported certificates.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Approximated expire time of reported certificates.
Multiple certificates with close expire time are batched together in a
single log, so the timestamp is not precise.

=back

=head3 Enum: CertificatesExpiry::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CLOSE_TO_EXPIRY> => C<1>

=item * C<EXPIRED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Certificatemanager::Logging::V1::Logs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
