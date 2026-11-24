package Google::Cloud::Websecurityscanner::V1::FindingTypeStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL2ZpbmRpbmdfdHlwZV9zdGF0
cy5wcm90bxIiZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MSJaChBGaW5kaW5n
VHlwZVN0YXRzEiEKDGZpbmRpbmdfdHlwZRgBIAEoCVILZmluZGluZ1R5cGUSIwoNZmluZGlu
Z19jb3VudBgCIAEoBVIMZmluZGluZ0NvdW50QosCCiZjb20uZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MUIVRmluZGluZ1R5cGVTdGF0c1Byb3RvUAFaVmNsb3VkLmdvb2ds
ZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2FwaXYxL3dlYnNlY3VyaXR5c2Nhbm5lcnBi
O3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgIiR29vZ2xlLkNsb3VkLldlYlNlY3VyaXR5U2Nhbm5l
ci5WMcoCIkdvb2dsZVxDbG91ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjHqAiVHb29nbGU6OkNs
b3VkOjpXZWJTZWN1cml0eVNjYW5uZXI6OlYxSuEICgYSBA4AIgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCAoBCBIDEgA/CgkKAgglEgMSAD8KCAoB
CBIDEwBtCgkKAggLEgMTAG0KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA2CgkKAggI
EgMVADYKCAoBCBIDFgA/CgkKAggBEgMWAD8KCAoBCBIDFwA/CgkKAggpEgMXAD8KCAoBCBID
GAA+CgkKAggtEgMYAD4KfwoCBAASBBwAIgEacyBBIEZpbmRpbmdUeXBlU3RhdHMgcmVzb3Vy
Y2UgcmVwcmVzZW50cyBzdGF0cyByZWdhcmRpbmcgYSBzcGVjaWZpYyBGaW5kaW5nVHlwZQog
b2YgRmluZGluZ3MgdW5kZXIgYSBnaXZlbiBTY2FuUnVuLgoKCgoDBAABEgMcCBgKRwoEBAAC
ABIDHgIaGjogT3V0cHV0IG9ubHkuIFRoZSBmaW5kaW5nIHR5cGUgYXNzb2NpYXRlZCB3aXRo
IHRoZSBzdGF0cy4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JFQoMCgUEAAIAAxIDHhgZ
ClEKBAQAAgESAyECGhpEIE91dHB1dCBvbmx5LiBUaGUgY291bnQgb2YgZmluZGluZ3MgYmVs
b25naW5nIHRvIHRoaXMgZmluZGluZyB0eXBlLgoKDAoFBAACAQUSAyECBwoMCgUEAAIBARID
IQgVCgwKBQQAAgEDEgMhGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats ===
    # Fields for FindingTypeStats
    # Field: finding_type Type: 9 ()
    # Field: finding_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::FindingTypeStats - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/finding_type_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::FindingTypeStats;

    my $msg = Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats->new({
        finding_type => $finding_type,
        finding_count => $finding_count,
    });

    # Read or update a field
    my $val = $msg->finding_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/finding_type_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats

A FindingTypeStats resource represents stats regarding a specific FindingType
of Findings under a given ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<String>

Output only. The finding type associated with the stats.

=item * C<< $msg->finding_count() >> / C<< $msg->finding_count($value) >>

Type: C<Int32>

Output only. The count of findings belonging to this finding type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::FindingTypeStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
