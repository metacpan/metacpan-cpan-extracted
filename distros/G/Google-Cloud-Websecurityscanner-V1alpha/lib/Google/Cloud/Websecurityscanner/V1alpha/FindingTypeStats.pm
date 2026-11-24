package Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Websecurityscanner::V1alpha::Finding };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvZmluZGluZ190eXBl
X3N0YXRzLnByb3RvEidnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEa
NWdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFhbHBoYS9maW5kaW5nLnByb3Rv
IpgBChBGaW5kaW5nVHlwZVN0YXRzEl8KDGZpbmRpbmdfdHlwZRgBIAEoDjI8Lmdvb2dsZS5j
bG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5GaW5kaW5nLkZpbmRpbmdUeXBlUgtm
aW5kaW5nVHlwZRIjCg1maW5kaW5nX2NvdW50GAIgASgFUgxmaW5kaW5nQ291bnRCowEKK2Nv
bS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGFCFUZpbmRpbmdUeXBl
U3RhdHNQcm90b1ABWltjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9h
cGl2MWFscGhhL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiSpQI
CgYSBA8AIgEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAw
CgkKAgMAEgMTAD8KCAoBCBIDFQByCgkKAggLEgMVAHIKCAoBCBIDFgAiCgkKAggKEgMWACIK
CAoBCBIDFwA2CgkKAggIEgMXADYKCAoBCBIDGABECgkKAggBEgMYAEQKfwoCBAASBBwAIgEa
cyBBIEZpbmRpbmdUeXBlU3RhdHMgcmVzb3VyY2UgcmVwcmVzZW50cyBzdGF0cyByZWdhcmRp
bmcgYSBzcGVjaWZpYyBGaW5kaW5nVHlwZQogb2YgRmluZGluZ3MgdW5kZXIgYSBnaXZlbiBT
Y2FuUnVuLgoKCgoDBAABEgMcCBgKOgoEBAACABIDHgInGi0gVGhlIGZpbmRpbmcgdHlwZSBh
c3NvY2lhdGVkIHdpdGggdGhlIHN0YXRzLgoKDAoFBAACAAYSAx4CFQoMCgUEAAIAARIDHhYi
CgwKBQQAAgADEgMeJSYKRAoEBAACARIDIQIaGjcgVGhlIGNvdW50IG9mIGZpbmRpbmdzIGJl
bG9uZ2luZyB0byB0aGlzIGZpbmRpbmcgdHlwZS4KCgwKBQQAAgEFEgMhAgcKDAoFBAACAQES
AyEIFQoMCgUEAAIBAxIDIRgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::FindingTypeStats ===
    # Fields for FindingTypeStats
    # Field: finding_type Type: 14 (.google.cloud.websecurityscanner.v1alpha.Finding.FindingType)
    # Field: finding_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/finding_type_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::FindingTypeStats->new({
        finding_type => $finding_type,
        finding_count => $finding_count,
    });

    # Read or update a field
    my $val = $msg->finding_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::FindingTypeStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/finding_type_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::FindingTypeStats

A FindingTypeStats resource represents stats regarding a specific FindingType
of Findings under a given ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::Finding::FindingType>)

The finding type associated with the stats.

=item * C<< $msg->finding_count() >> / C<< $msg->finding_count($value) >>

Type: C<Int32>

The count of findings belonging to this finding type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
