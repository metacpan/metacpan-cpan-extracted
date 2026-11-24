package Google::Devtools::Resultstore::V2::Coverage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY292ZXJhZ2UucHJvdG8SHmdvb2ds
ZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MiJkCgxMaW5lQ292ZXJhZ2USLQoSaW5zdHJ1bWVu
dGVkX2xpbmVzGAEgASgMUhFpbnN0cnVtZW50ZWRMaW5lcxIlCg5leGVjdXRlZF9saW5lcxgC
IAEoDFINZXhlY3V0ZWRMaW5lcyKTAQoOQnJhbmNoQ292ZXJhZ2USJQoOYnJhbmNoX3ByZXNl
bnQYASABKAxSDWJyYW5jaFByZXNlbnQSKAoQYnJhbmNoZXNfaW5fbGluZRgCIAMoBVIOYnJh
bmNoZXNJbkxpbmUSGgoIZXhlY3V0ZWQYAyABKAxSCGV4ZWN1dGVkEhQKBXRha2VuGAQgASgM
UgV0YWtlbiLOAQoMRmlsZUNvdmVyYWdlEhIKBHBhdGgYASABKAlSBHBhdGgSUQoNbGluZV9j
b3ZlcmFnZRgCIAEoCzIsLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5MaW5lQ292
ZXJhZ2VSDGxpbmVDb3ZlcmFnZRJXCg9icmFuY2hfY292ZXJhZ2UYAyABKAsyLi5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuQnJhbmNoQ292ZXJhZ2VSDmJyYW5jaENvdmVyYWdl
ImUKDkFjdGlvbkNvdmVyYWdlElMKDmZpbGVfY292ZXJhZ2VzGAIgAygLMiwuZ29vZ2xlLmRl
dnRvb2xzLnJlc3VsdHN0b3JlLnYyLkZpbGVDb3ZlcmFnZVINZmlsZUNvdmVyYWdlcyJoChFB
Z2dyZWdhdGVDb3ZlcmFnZRJTCg5maWxlX2NvdmVyYWdlcxgBIAMoCzIsLmdvb2dsZS5kZXZ0
b29scy5yZXN1bHRzdG9yZS52Mi5GaWxlQ292ZXJhZ2VSDWZpbGVDb3ZlcmFnZXNCgAEKImNv
bS5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjJCDUNvdmVyYWdlUHJvdG9QAVpJZ29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9yZXN1bHRzdG9y
ZS92MjtyZXN1bHRzdG9yZUqJIQoGEgQOAG0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAYAoJCgIICxIDEgBgCggKAQgSAxMAIgoJCgII
ChIDEwAiCggKAQgSAxQALgoJCgIICBIDFAAuCggKAQgSAxUAOwoJCgIIARIDFQA7CjAKAgQA
EgQYAC4BGiQgRGVzY3JpYmVzIGxpbmUgY292ZXJhZ2UgZm9yIGEgZmlsZQoKCgoDBAABEgMY
CBQKoQMKBAQAAgASAyICHxqTAyBXaGljaCBzb3VyY2UgbGluZXMgaW4gdGhlIGZpbGUgcmVw
cmVzZW50IHRoZSBzdGFydCBvZiBhIHN0YXRlbWVudCB0aGF0IHdhcwogaW5zdHJ1bWVudGVk
IHRvIGRldGVjdCB3aGV0aGVyIGl0IHdhcyBleGVjdXRlZCBieSB0aGUgdGVzdC4KCiBUaGlz
IGlzIGEgYml0ZmllbGQgd2hlcmUgaS10aCBiaXQgY29ycmVzcG9uZHMgdG8gdGhlIGktdGgg
bGluZS4gRGl2aWRlIGxpbmUKIG51bWJlciBieSA4IHRvIGdldCBpbmRleCBpbnRvIGJ5dGUg
YXJyYXkuIE1vZCBsaW5lIG51bWJlciBieSA4IHRvIGdldCBiaXQKIG51bWJlciAoMCA9IExT
QiwgNyA9IE1TQikuCgogQSAxIGRlbm90ZXMgdGhlIGxpbmUgd2FzIGluc3RydW1lbnRlZC4K
IEEgMCBkZW5vdGVzIHRoZSBsaW5lIHdhcyBub3QgaW5zdHJ1bWVudGVkLgoKDAoFBAACAAUS
AyICBwoMCgUEAAIAARIDIggaCgwKBQQAAgADEgMiHR4KhQMKBAQAAgESAy0CGxr3AiBXaGlj
aCBvZiB0aGUgaW5zdHJ1bWVudGVkIHNvdXJjZSBsaW5lcyB3ZXJlIGV4ZWN1dGVkIGJ5IHRo
ZSB0ZXN0LiBTaG91bGQKIGluY2x1ZGUgbGluZXMgdGhhdCB3ZXJlIG5vdCBpbnN0cnVtZW50
ZWQuCgogVGhpcyBpcyBhIGJpdGZpZWxkIHdoZXJlIGktdGggYml0IGNvcnJlc3BvbmRzIHRv
IHRoZSBpLXRoIGxpbmUuIERpdmlkZSBsaW5lCiBudW1iZXIgYnkgOCB0byBnZXQgaW5kZXgg
aW50byBieXRlIGFycmF5LiBNb2QgbGluZSBudW1iZXIgYnkgOCB0byBnZXQgYml0CiBudW1i
ZXIgKDAgPSBMU0IsIDcgPSBNU0IpLgoKIEEgMSBkZW5vdGVzIHRoZSBsaW5lIHdhcyBleGVj
dXRlZC4KIEEgMCBkZW5vdGVzIHRoZSBsaW5lIHdhcyBub3QgZXhlY3V0ZWQuCgoMCgUEAAIB
BRIDLQIHCgwKBQQAAgEBEgMtCBYKDAoFBAACAQMSAy0ZGgoyCgIEARIEMQBSARomIERlc2Ny
aWJlcyBicmFuY2ggY292ZXJhZ2UgZm9yIGEgZmlsZQoKCgoDBAEBEgMxCBYK8AIKBAQBAgAS
AzoCGxriAiBUaGUgZmllbGQgYnJhbmNoX3ByZXNlbnQgZGVub3RlcyB0aGUgbGluZXMgY29u
dGFpbmluZyBhdCBsZWFzdCBvbmUgYnJhbmNoLgoKIFRoaXMgaXMgYSBiaXRmaWVsZCB3aGVy
ZSBpLXRoIGJpdCBjb3JyZXNwb25kcyB0byB0aGUgaS10aCBsaW5lLiBEaXZpZGUgbGluZQog
bnVtYmVyIGJ5IDggdG8gZ2V0IGluZGV4IGludG8gYnl0ZSBhcnJheS4gTW9kIGxpbmUgbnVt
YmVyIGJ5IDggdG8gZ2V0IGJpdAogbnVtYmVyICgwID0gTFNCLCA3ID0gTVNCKS4KCiBBIDEg
ZGVub3RlcyB0aGUgbGluZSBjb250YWlucyBhdCBsZWFzdCBvbmUgYnJhbmNoLgogQSAwIGRl
bm90ZXMgdGhlIGxpbmUgY29udGFpbnMgbm8gYnJhbmNoZXMuCgoMCgUEAQIABRIDOgIHCgwK
BQQBAgABEgM6CBYKDAoFBAECAAMSAzoZGgrIAQoEBAECARIDPwImGroBIENvbnRhaW5zIHRo
ZSBudW1iZXIgb2YgYnJhbmNoZXMgcHJlc2VudCwgb25seSBmb3IgdGhlIGxpbmVzIHdoaWNo
IGhhdmUgdGhlCiBjb3JyZXNwb25kaW5nIGJpdCBzZXQgaW4gYnJhbmNoX3ByZXNlbnQsIGlu
IGEgcmVsYXRpdmUgb3JkZXIgaWdub3JpbmcKIGxpbmVzIHdoaWNoIGRvIG5vdCBoYXZlIGFu
eSBicmFuY2hlcy4KCgwKBQQBAgEEEgM/AgoKDAoFBAECAQUSAz8LEAoMCgUEAQIBARIDPxEh
CgwKBQQBAgEDEgM/JCUK+gQKBAQBAgISA04CFRrsBCBBcyBlYWNoIGJyYW5jaCBjYW4gaGF2
ZSBhbnkgb25lIG9mIHRoZSBmb2xsb3dpbmcgdGhyZWUgc3RhdGVzOiBub3QKIGV4ZWN1dGVk
LCBleGVjdXRlZCBidXQgbm90IHRha2VuLCBleGVjdXRlZCBhbmQgdGFrZW4uCgogVGhpcyBp
cyBhIGJpdGZpZWxkIHdoZXJlIGktdGggYml0IGNvcnJlc3BvbmRzIHRvIHRoZSBpLXRoIGJy
YW5jaC4gRGl2aWRlCiBicmFuY2ggbnVtYmVyIGJ5IDggdG8gZ2V0IGluZGV4IGludG8gYnl0
ZSBhcnJheS4gTW9kIGJyYW5jaCBudW1iZXIgYnkgOCB0bwogZ2V0IGJpdCBudW1iZXIgKDAg
PSBMU0IsIDcgPSBNU0IpLgoKIGktdGggYml0IG9mIHRoZSBmb2xsb3dpbmcgdHdvIGJ5dGUg
YXJyYXlzIGFyZSB1c2VkIHRvIGRlbm90ZSB0aGUgYWJvdmUKIG1lbnRpb25lZCBzdGF0ZXMu
Cgogbm90IGV4ZWN1dGVkOiBpLXRoIGJpdCBvZiBleGVjdXRlZCA9PSAwICYmIGktdGggYml0
IG9mIHRha2VuID09IDAKIGV4ZWN1dGVkIGJ1dCBub3QgdGFrZW46IGktdGggYml0IG9mIGV4
ZWN1dGVkID09IDEgJiYgaS10aCBiaXQgb2YgdGFrZW4gPT0gMAogZXhlY3V0ZWQgYW5kIHRh
a2VuOiBpLXRoIGJpdCBvZiBleGVjdXRlZCA9PSAxICYmIGktdGggYml0IG9mIHRha2VuID09
IDEKCgwKBQQBAgIFEgNOAgcKDAoFBAECAgESA04IEAoMCgUEAQICAxIDThMUCh8KBAQBAgMS
A1ECEhoSIERlc2NyaWJlZCBhYm92ZS4KCgwKBQQBAgMFEgNRAgcKDAoFBAECAwESA1EIDQoM
CgUEAQIDAxIDURARCkcKAgQCEgRVAF4BGjsgRGVzY3JpYmVzIGNvZGUgY292ZXJhZ2UgZm9y
IGEgcGFydGljdWxhciBmaWxlIHVuZGVyIHRlc3QuCgoKCgMEAgESA1UIFApPCgQEAgIAEgNX
AhIaQiBQYXRoIG9mIHNvdXJjZSBmaWxlIHdpdGhpbiB0aGUgU291cmNlQ29udGV4dCBvZiB0
aGlzIEludm9jYXRpb24uCgoMCgUEAgIABRIDVwIICgwKBQQCAgABEgNXCQ0KDAoFBAICAAMS
A1cQEQpICgQEAgIBEgNaAiEaOyBEZXRhaWxzIG9mIGxpbmVzIGluIGEgZmlsZSBmb3IgY2Fs
Y3VsYXRpbmcgbGluZSBjb3ZlcmFnZS4KCgwKBQQCAgEGEgNaAg4KDAoFBAICAQESA1oPHAoM
CgUEAgIBAxIDWh8gCk0KBAQCAgISA10CJRpAIERldGFpbHMgb2YgYnJhbmNoZXMgaW4gYSBm
aWxlIGZvciBjYWxjdWxhdGluZyBicmFuY2ggY292ZXJhZ2UuCgoMCgUEAgICBhIDXQIQCgwK
BQQCAgIBEgNdESAKDAoFBAICAgMSA10jJAqhAQoCBAMSBGIAZQEalAEgRGVzY3JpYmVzIGNv
ZGUgY292ZXJhZ2UgZm9yIGEgYnVpbGQgb3IgdGVzdCBBY3Rpb24uIFRoaXMgaXMgdXNlZCB0
byBzdG9yZQogYmFzZWxpbmUgY292ZXJhZ2UgZm9yIGJ1aWxkIEFjdGlvbnMgYW5kIHRlc3Qg
Y292ZXJhZ2UgZm9yIHRlc3QgQWN0aW9ucy4KCgoKAwQDARIDYggWClUKBAQDAgASA2QCKxpI
IExpc3Qgb2YgY292ZXJhZ2UgaW5mbyBmb3IgYWxsIHNvdXJjZSBmaWxlcyB0aGF0IHRoZSBU
ZXN0UmVzdWx0IGNvdmVycy4KCgwKBQQDAgAEEgNkAgoKDAoFBAMCAAYSA2QLFwoMCgUEAwIA
ARIDZBgmCgwKBQQDAgADEgNkKSoKuwEKAgQEEgRqAG0BGq4BIERlc2NyaWJlcyBhZ2dyZWdh
dGUgY29kZSBjb3ZlcmFnZSBmb3IgYSBjb2xsZWN0aW9uIG9mIGJ1aWxkIG9yIHRlc3QgQWN0
aW9ucy4KIEEgbGluZSBvciBicmFuY2ggaXMgY292ZXJlZCBpZiBhbmQgb25seSBpZiBpdCBp
cyBjb3ZlcmVkIGluIGFueSBvZiB0aGUgYnVpbGQKIG9yIHRlc3QgYWN0aW9ucy4KCgoKAwQE
ARIDaggZClQKBAQEAgASA2wCKxpHIEFnZ3JlZ2F0ZWQgY292ZXJhZ2UgaW5mbyBmb3IgYWxs
IHNvdXJjZSBmaWxlcyB0aGF0IHRoZSBhY3Rpb25zIGNvdmVyLgoKDAoFBAQCAAQSA2wCCgoM
CgUEBAIABhIDbAsXCgwKBQQEAgABEgNsGCYKDAoFBAQCAAMSA2wpKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Coverage::LineCoverage ===
    # Fields for LineCoverage
    # Field: instrumented_lines Type: 12 ()
    # Field: executed_lines Type: 12 ()

# === Message: Google::Devtools::Resultstore::V2::Coverage::BranchCoverage ===
    # Fields for BranchCoverage
    # Field: branch_present Type: 12 ()
    # Field: branches_in_line Type: 5 ()
    # Field: executed Type: 12 ()
    # Field: taken Type: 12 ()

# === Message: Google::Devtools::Resultstore::V2::Coverage::FileCoverage ===
    # Fields for FileCoverage
    # Field: path Type: 9 ()
    # Field: line_coverage Type: 11 (.google.devtools.resultstore.v2.LineCoverage)
    # Field: branch_coverage Type: 11 (.google.devtools.resultstore.v2.BranchCoverage)

# === Message: Google::Devtools::Resultstore::V2::Coverage::ActionCoverage ===
    # Fields for ActionCoverage
    # Field: file_coverages Type: 11 (.google.devtools.resultstore.v2.FileCoverage)

# === Message: Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage ===
    # Fields for AggregateCoverage
    # Field: file_coverages Type: 11 (.google.devtools.resultstore.v2.FileCoverage)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Coverage - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/coverage.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Coverage;

    my $msg = Google::Devtools::Resultstore::V2::Coverage::LineCoverage->new({
        instrumented_lines => $instrumented_lines,
        executed_lines => $executed_lines,
    });

    # Read or update a field
    my $val = $msg->instrumented_lines();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Coverage::LineCoverage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/coverage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Coverage::LineCoverage

Describes line coverage for a file

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instrumented_lines() >> / C<< $msg->instrumented_lines($value) >>

Type: C<Bytes>

Which source lines in the file represent the start of a statement that was
instrumented to detect whether it was executed by the test.

This is a bitfield where i-th bit corresponds to the i-th line. Divide line
number by 8 to get index into byte array. Mod line number by 8 to get bit
number (0 = LSB, 7 = MSB).

A 1 denotes the line was instrumented.
A 0 denotes the line was not instrumented.

=item * C<< $msg->executed_lines() >> / C<< $msg->executed_lines($value) >>

Type: C<Bytes>

Which of the instrumented source lines were executed by the test. Should
include lines that were not instrumented.

This is a bitfield where i-th bit corresponds to the i-th line. Divide line
number by 8 to get index into byte array. Mod line number by 8 to get bit
number (0 = LSB, 7 = MSB).

A 1 denotes the line was executed.
A 0 denotes the line was not executed.

=back

=head2 Google::Devtools::Resultstore::V2::Coverage::BranchCoverage

Describes branch coverage for a file

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->branch_present() >> / C<< $msg->branch_present($value) >>

Type: C<Bytes>

The field branch_present denotes the lines containing at least one branch.

This is a bitfield where i-th bit corresponds to the i-th line. Divide line
number by 8 to get index into byte array. Mod line number by 8 to get bit
number (0 = LSB, 7 = MSB).

A 1 denotes the line contains at least one branch.
A 0 denotes the line contains no branches.

=item * C<< $msg->branches_in_line() >> / C<< $msg->branches_in_line($value) >>

Type: C<Int32>

Contains the number of branches present, only for the lines which have the
corresponding bit set in branch_present, in a relative order ignoring
lines which do not have any branches.

=item * C<< $msg->executed() >> / C<< $msg->executed($value) >>

Type: C<Bytes>

As each branch can have any one of the following three states: not
executed, executed but not taken, executed and taken.

This is a bitfield where i-th bit corresponds to the i-th branch. Divide
branch number by 8 to get index into byte array. Mod branch number by 8 to
get bit number (0 = LSB, 7 = MSB).

i-th bit of the following two byte arrays are used to denote the above
mentioned states.

not executed: i-th bit of executed == 0 && i-th bit of taken == 0
executed but not taken: i-th bit of executed == 1 && i-th bit of taken == 0
executed and taken: i-th bit of executed == 1 && i-th bit of taken == 1

=item * C<< $msg->taken() >> / C<< $msg->taken($value) >>

Type: C<Bytes>

Described above.

=back

=head2 Google::Devtools::Resultstore::V2::Coverage::FileCoverage

Describes code coverage for a particular file under test.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path of source file within the SourceContext of this Invocation.

=item * C<< $msg->line_coverage() >> / C<< $msg->line_coverage($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::LineCoverage>)

Details of lines in a file for calculating line coverage.

=item * C<< $msg->branch_coverage() >> / C<< $msg->branch_coverage($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::BranchCoverage>)

Details of branches in a file for calculating branch coverage.

=back

=head2 Google::Devtools::Resultstore::V2::Coverage::ActionCoverage

Describes code coverage for a build or test Action. This is used to store
baseline coverage for build Actions and test coverage for test Actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_coverages() >> / C<< $msg->file_coverages($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::FileCoverage>)

List of coverage info for all source files that the TestResult covers.

=back

=head2 Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage

Describes aggregate code coverage for a collection of build or test Actions.
A line or branch is covered if and only if it is covered in any of the build
or test actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_coverages() >> / C<< $msg->file_coverages($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::FileCoverage>)

Aggregated coverage info for all source files that the actions cover.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Coverage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
