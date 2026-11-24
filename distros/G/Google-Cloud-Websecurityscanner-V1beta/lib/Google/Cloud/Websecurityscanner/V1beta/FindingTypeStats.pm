package Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9maW5kaW5nX3R5cGVf
c3RhdHMucHJvdG8SJmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhIloK
EEZpbmRpbmdUeXBlU3RhdHMSIQoMZmluZGluZ190eXBlGAEgASgJUgtmaW5kaW5nVHlwZRIj
Cg1maW5kaW5nX2NvdW50GAIgASgFUgxmaW5kaW5nQ291bnRCnwIKKmNvbS5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YUIVRmluZGluZ1R5cGVTdGF0c1Byb3RvUAFa
WmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2FwaXYxYmV0YS93ZWJz
ZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJwYqoCJkdvb2dsZS5DbG91ZC5X
ZWJTZWN1cml0eVNjYW5uZXIuVjFCZXRhygImR29vZ2xlXENsb3VkXFdlYlNlY3VyaXR5U2Nh
bm5lclxWMWJldGHqAilHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNjYW5uZXI6OlYxYmV0
YUrICAoGEgQPACMBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQIS
AxEALwoICgEIEgMTAEMKCQoCCCUSAxMAQwoICgEIEgMUAHEKCQoCCAsSAxQAcQoICgEIEgMV
ACIKCQoCCAoSAxUAIgoICgEIEgMWADYKCQoCCAgSAxYANgoICgEIEgMXAEMKCQoCCAESAxcA
QwoICgEIEgMYAEMKCQoCCCkSAxgAQwoICgEIEgMZAEIKCQoCCC0SAxkAQgp/CgIEABIEHQAj
ARpzIEEgRmluZGluZ1R5cGVTdGF0cyByZXNvdXJjZSByZXByZXNlbnRzIHN0YXRzIHJlZ2Fy
ZGluZyBhIHNwZWNpZmljIEZpbmRpbmdUeXBlCiBvZiBGaW5kaW5ncyB1bmRlciBhIGdpdmVu
IFNjYW5SdW4uCgoKCgMEAAESAx0IGAo6CgQEAAIAEgMfAhoaLSBUaGUgZmluZGluZyB0eXBl
IGFzc29jaWF0ZWQgd2l0aCB0aGUgc3RhdHMuCgoMCgUEAAIABRIDHwIICgwKBQQAAgABEgMf
CRUKDAoFBAACAAMSAx8YGQpECgQEAAIBEgMiAhoaNyBUaGUgY291bnQgb2YgZmluZGluZ3Mg
YmVsb25naW5nIHRvIHRoaXMgZmluZGluZyB0eXBlLgoKDAoFBAACAQUSAyICBwoMCgUEAAIB
ARIDIggVCgwKBQQAAgEDEgMiGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::FindingTypeStats ===
    # Fields for FindingTypeStats
    # Field: finding_type Type: 9 ()
    # Field: finding_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/finding_type_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::FindingTypeStats->new({
        finding_type => $finding_type,
        finding_count => $finding_count,
    });

    # Read or update a field
    my $val = $msg->finding_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::FindingTypeStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/finding_type_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::FindingTypeStats

A FindingTypeStats resource represents stats regarding a specific FindingType
of Findings under a given ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<String>

The finding type associated with the stats.

=item * C<< $msg->finding_count() >> / C<< $msg->finding_count($value) >>

Type: C<Int32>

The count of findings belonging to this finding type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
