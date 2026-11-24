package Google::Devtools::Resultstore::V2::CoverageSummary;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Devtools::Resultstore::V2::Common };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY292ZXJhZ2Vfc3VtbWFyeS5wcm90
bxIeZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyGitnb29nbGUvZGV2dG9vbHMvcmVz
dWx0c3RvcmUvdjIvY29tbW9uLnByb3RvIn0KE0xpbmVDb3ZlcmFnZVN1bW1hcnkSNgoXaW5z
dHJ1bWVudGVkX2xpbmVfY291bnQYASABKAVSFWluc3RydW1lbnRlZExpbmVDb3VudBIuChNl
eGVjdXRlZF9saW5lX2NvdW50GAIgASgFUhFleGVjdXRlZExpbmVDb3VudCKnAQoVQnJhbmNo
Q292ZXJhZ2VTdW1tYXJ5EiwKEnRvdGFsX2JyYW5jaF9jb3VudBgBIAEoBVIQdG90YWxCcmFu
Y2hDb3VudBIyChVleGVjdXRlZF9icmFuY2hfY291bnQYAiABKAVSE2V4ZWN1dGVkQnJhbmNo
Q291bnQSLAoSdGFrZW5fYnJhbmNoX2NvdW50GAMgASgFUhB0YWtlbkJyYW5jaENvdW50IpUC
ChdMYW5ndWFnZUNvdmVyYWdlU3VtbWFyeRJECghsYW5ndWFnZRgBIAEoDjIoLmdvb2dsZS5k
ZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5MYW5ndWFnZVIIbGFuZ3VhZ2USVgoMbGluZV9zdW1t
YXJ5GAIgASgLMjMuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkxpbmVDb3ZlcmFn
ZVN1bW1hcnlSC2xpbmVTdW1tYXJ5ElwKDmJyYW5jaF9zdW1tYXJ5GAMgASgLMjUuZ29vZ2xl
LmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkJyYW5jaENvdmVyYWdlU3VtbWFyeVINYnJhbmNo
U3VtbWFyeUKHAQoiY29tLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MkIUQ292ZXJh
Z2VTdW1tYXJ5UHJvdG9QAVpJZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBp
cy9kZXZ0b29scy9yZXN1bHRzdG9yZS92MjtyZXN1bHRzdG9yZUr2EAoGEgQOAEABCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSADUKCAoB
CBIDFABgCgkKAggLEgMUAGAKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA1CgkKAggI
EgMWADUKCAoBCBIDFwA7CgkKAggBEgMXADsKJgoCBAASBBoAIAEaGiBTdW1tYXJ5IG9mIGxp
bmUgY292ZXJhZ2UKCgoKAwQAARIDGggbCjkKBAQAAgASAxwCJBosIE51bWJlciBvZiBsaW5l
cyBpbnN0cnVtZW50ZWQgZm9yIGNvdmVyYWdlLgoKDAoFBAACAAUSAxwCBwoMCgUEAAIAARID
HAgfCgwKBQQAAgADEgMcIiMKSwoEBAACARIDHwIgGj4gTnVtYmVyIG9mIGluc3RydW1lbnRl
ZCBsaW5lcyB0aGF0IHdlcmUgZXhlY3V0ZWQgYnkgdGhlIHRlc3QuCgoMCgUEAAIBBRIDHwIH
CgwKBQQAAgEBEgMfCBsKDAoFBAACAQMSAx8eHwrXAQoCBAESBCcANAEaygEgU3VtbWFyeSBv
ZiBicmFuY2ggY292ZXJhZ2UKIEEgYnJhbmNoIG1heSBiZToKICAqIG5vdCBleGVjdXRlZC4g
IENvdW50ZWQgb25seSBpbiB0b3RhbC4KICAqIGV4ZWN1dGVkIGJ1dCBub3QgdGFrZW4uICBB
cHBlYXJzIGluIHRvdGFsIGFuZCBleGVjdXRlZC4KICAqIGV4ZWN1dGVkIGFuZCB0YWtlbi4g
IEFwcGVhcnMgaW4gYWxsIHRocmVlIGZpZWxkcy4KCgoKAwQBARIDJwgdCjoKBAQBAgASAykC
HxotIFRoZSBudW1iZXIgb2YgYnJhbmNoZXMgcHJlc2VudCBpbiB0aGUgZmlsZS4KCgwKBQQB
AgAFEgMpAgcKDAoFBAECAAESAykIGgoMCgUEAQIAAxIDKR0eCsoBCgQEAQIBEgMuAiIavAEg
VGhlIG51bWJlciBvZiBicmFuY2hlcyBleGVjdXRlZCBvdXQgb2YgdGhlIHRvdGFsIGJyYW5j
aGVzIHByZXNlbnQuCiBBIGJyYW5jaCBpcyBleGVjdXRlZCB3aGVuIGl0cyBjb25kaXRpb24g
aXMgZXZhbHVhdGVkLgogVGhpcyBpcyA8PSB0b3RhbF9icmFuY2hfY291bnQgYXMgbm90IGFs
bCBicmFuY2hlcyBhcmUgZXhlY3V0ZWQuCgoMCgUEAQIBBRIDLgIHCgwKBQQBAgEBEgMuCB0K
DAoFBAECAQMSAy4gIQrOAQoEBAECAhIDMwIfGsABIFRoZSBudW1iZXIgb2YgYnJhbmNoZXMg
dGFrZW4gb3V0IG9mIHRoZSB0b3RhbCBicmFuY2hlcyBleGVjdXRlZC4KIEEgYnJhbmNoIGlz
IHRha2VuIHdoZW4gaXRzIGNvbmRpdGlvbiBpcyBzYXRpc2ZpZWQuCiBUaGlzIGlzIDw9IGV4
ZWN1dGVkX2JyYW5jaF9jb3VudCBhcyBub3QgYWxsIGV4ZWN1dGVkIGJyYW5jaGVzIGFyZSB0
YWtlbi4KCgwKBQQBAgIFEgMzAgcKDAoFBAECAgESAzMIGgoMCgUEAQICAxIDMx0eCjIKAgQC
EgQ3AEABGiYgU3VtbWFyeSBvZiBjb3ZlcmFnZSBpbiBlYWNoIGxhbmd1YWdlCgoKCgMEAgES
AzcIHwpSCgQEAgIAEgM5AhgaRSBUaGlzIHN1bW1hcnkgaXMgZm9yIGFsbCBmaWxlcyB3cml0
dGVuIGluIHRoaXMgcHJvZ3JhbW1pbmcgbGFuZ3VhZ2UuCgoMCgUEAgIABhIDOQIKCgwKBQQC
AgABEgM5CxMKDAoFBAICAAMSAzkWFwo4CgQEAgIBEgM8AicaKyBTdW1tYXJ5IG9mIGxpbmVz
IGNvdmVyZWQgdnMgaW5zdHJ1bWVudGVkLgoKDAoFBAICAQYSAzwCFQoMCgUEAgIBARIDPBYi
CgwKBQQCAgEDEgM8JSYKKgoEBAICAhIDPwIrGh0gU3VtbWFyeSBvZiBicmFuY2ggY292ZXJh
Z2UuCgoMCgUEAgICBhIDPwIXCgwKBQQCAgIBEgM/GCYKDAoFBAICAgMSAz8pKmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary ===
    # Fields for LineCoverageSummary
    # Field: instrumented_line_count Type: 5 ()
    # Field: executed_line_count Type: 5 ()

# === Message: Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary ===
    # Fields for BranchCoverageSummary
    # Field: total_branch_count Type: 5 ()
    # Field: executed_branch_count Type: 5 ()
    # Field: taken_branch_count Type: 5 ()

# === Message: Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary ===
    # Fields for LanguageCoverageSummary
    # Field: language Type: 14 (.google.devtools.resultstore.v2.Language)
    # Field: line_summary Type: 11 (.google.devtools.resultstore.v2.LineCoverageSummary)
    # Field: branch_summary Type: 11 (.google.devtools.resultstore.v2.BranchCoverageSummary)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::CoverageSummary - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/coverage_summary.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::CoverageSummary;

    my $msg = Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary->new({
        instrumented_line_count => $instrumented_line_count,
        executed_line_count => $executed_line_count,
    });

    # Read or update a field
    my $val = $msg->instrumented_line_count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/coverage_summary.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary

Summary of line coverage

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instrumented_line_count() >> / C<< $msg->instrumented_line_count($value) >>

Type: C<Int32>

Number of lines instrumented for coverage.

=item * C<< $msg->executed_line_count() >> / C<< $msg->executed_line_count($value) >>

Type: C<Int32>

Number of instrumented lines that were executed by the test.

=back

=head2 Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary

Summary of branch coverage
A branch may be:
 * not executed.  Counted only in total.
 * executed but not taken.  Appears in total and executed.
 * executed and taken.  Appears in all three fields.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_branch_count() >> / C<< $msg->total_branch_count($value) >>

Type: C<Int32>

The number of branches present in the file.

=item * C<< $msg->executed_branch_count() >> / C<< $msg->executed_branch_count($value) >>

Type: C<Int32>

The number of branches executed out of the total branches present.
A branch is executed when its condition is evaluated.
This is <= total_branch_count as not all branches are executed.

=item * C<< $msg->taken_branch_count() >> / C<< $msg->taken_branch_count($value) >>

Type: C<Int32>

The number of branches taken out of the total branches executed.
A branch is taken when its condition is satisfied.
This is <= executed_branch_count as not all executed branches are taken.

=back

=head2 Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary

Summary of coverage in each language

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->language() >> / C<< $msg->language($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::Language>)

This summary is for all files written in this programming language.

=item * C<< $msg->line_summary() >> / C<< $msg->line_summary($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::CoverageSummary::LineCoverageSummary>)

Summary of lines covered vs instrumented.

=item * C<< $msg->branch_summary() >> / C<< $msg->branch_summary($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::CoverageSummary::BranchCoverageSummary>)

Summary of branch coverage.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::CoverageSummary::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
