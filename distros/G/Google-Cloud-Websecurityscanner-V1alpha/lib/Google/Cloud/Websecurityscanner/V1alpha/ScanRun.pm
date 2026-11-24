package Google::Cloud::Websecurityscanner::V1alpha::ScanRun;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvc2Nhbl9ydW4ucHJv
dG8SJ2dvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYRoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKuBgoH
U2NhblJ1bhISCgRuYW1lGAEgASgJUgRuYW1lEmgKD2V4ZWN1dGlvbl9zdGF0ZRgCIAEoDjI/
Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5TY2FuUnVuLkV4ZWN1
dGlvblN0YXRlUg5leGVjdXRpb25TdGF0ZRJfCgxyZXN1bHRfc3RhdGUYAyABKA4yPC5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2NhblJ1bi5SZXN1bHRTdGF0
ZVILcmVzdWx0U3RhdGUSOQoKc3RhcnRfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSB2VuZFRpbWUSLAoSdXJsc19jcmF3bGVkX2NvdW50GAYgASgDUhB1cmxz
Q3Jhd2xlZENvdW50EioKEXVybHNfdGVzdGVkX2NvdW50GAcgASgDUg91cmxzVGVzdGVkQ291
bnQSLwoTaGFzX3Z1bG5lcmFiaWxpdGllcxgIIAEoCFISaGFzVnVsbmVyYWJpbGl0aWVzEikK
EHByb2dyZXNzX3BlcmNlbnQYCSABKAVSD3Byb2dyZXNzUGVyY2VudCJZCg5FeGVjdXRpb25T
dGF0ZRIfChtFWEVDVVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZRVUVVRUQQARIMCghT
Q0FOTklORxACEgwKCEZJTklTSEVEEAMiTwoLUmVzdWx0U3RhdGUSHAoYUkVTVUxUX1NUQVRF
X1VOU1BFQ0lGSUVEEAASCwoHU1VDQ0VTUxABEgkKBUVSUk9SEAISCgoGS0lMTEVEEAM6cOpB
bQopd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5SdW4SQHByb2plY3Rz
L3twcm9qZWN0fS9zY2FuQ29uZmlncy97c2Nhbl9jb25maWd9L3NjYW5SdW5zL3tzY2FuX3J1
bn1CmgEKK2NvbS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGFCDFNj
YW5SdW5Qcm90b1ABWltjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9h
cGl2MWFscGhhL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiSt4a
CgYSBA8AZwEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
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
CgkKAgMAEgMTACMKCQoCAwESAxQAKQoICgEIEgMWAHIKCQoCCAsSAxYAcgoICgEIEgMXACIK
CQoCCAoSAxcAIgoICgEIEgMYAC0KCQoCCAgSAxgALQoICgEIEgMZAEQKCQoCCAESAxkARApZ
CgIEABIEHABnARpNIEEgU2NhblJ1biBpcyBhIG91dHB1dC1vbmx5IHJlc291cmNlIHJlcHJl
c2VudGluZyBhbiBhY3R1YWwgcnVuIG9mIHRoZSBzY2FuLgoKCgoDBAABEgMcCA8KCwoDBAAH
EgQdAiAECg0KBQQAB50IEgQdAiAECjEKBAQABAASBCMCMAMaIyBUeXBlcyBvZiBTY2FuUnVu
IGV4ZWN1dGlvbiBzdGF0ZS4KCgwKBQQABAABEgMjBxUKcwoGBAAEAAIAEgMmBCQaZCBSZXBy
ZXNlbnRzIGFuIGludmFsaWQgc3RhdGUgY2F1c2VkIGJ5IGludGVybmFsIHNlcnZlciBlcnJv
ci4gVGhpcyB2YWx1ZQogc2hvdWxkIG5ldmVyIGJlIHJldHVybmVkLgoKDgoHBAAEAAIAARID
JgQfCg4KBwQABAACAAISAyYiIwoyCgYEAAQAAgESAykEDxojIFRoZSBzY2FuIGlzIHdhaXRp
bmcgaW4gdGhlIHF1ZXVlLgoKDgoHBAAEAAIBARIDKQQKCg4KBwQABAACAQISAykNDgopCgYE
AAQAAgISAywEERoaIFRoZSBzY2FuIGlzIGluIHByb2dyZXNzLgoKDgoHBAAEAAICARIDLAQM
Cg4KBwQABAACAgISAywPEApACgYEAAQAAgMSAy8EERoxIFRoZSBzY2FuIGlzIGVpdGhlciBm
aW5pc2hlZCBvciBzdG9wcGVkIGJ5IHVzZXIuCgoOCgcEAAQAAgMBEgMvBAwKDgoHBAAEAAID
AhIDLw8QCi4KBAQABAESBDMCQAMaICBUeXBlcyBvZiBTY2FuUnVuIHJlc3VsdCBzdGF0ZS4K
CgwKBQQABAEBEgMzBxIKXQoGBAAEAQIAEgM2BCEaTiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZh
bHVlIGlzIHJldHVybmVkIHdoZW4gdGhlIFNjYW5SdW4gaXMgbm90IHlldAogZmluaXNoZWQu
CgoOCgcEAAQBAgABEgM2BBwKDgoHBAAEAQIAAhIDNh8gCjIKBgQABAECARIDOQQQGiMgVGhl
IHNjYW4gZmluaXNoZWQgd2l0aG91dCBlcnJvcnMuCgoOCgcEAAQBAgEBEgM5BAsKDgoHBAAE
AQIBAhIDOQ4PCi8KBgQABAECAhIDPAQOGiAgVGhlIHNjYW4gZmluaXNoZWQgd2l0aCBlcnJv
cnMuCgoOCgcEAAQBAgIBEgM8BAkKDgoHBAAEAQICAhIDPAwNCjEKBgQABAECAxIDPwQPGiIg
VGhlIHNjYW4gd2FzIHRlcm1pbmF0ZWQgYnkgdXNlci4KCg4KBwQABAECAwESAz8ECgoOCgcE
AAQBAgMCEgM/DQ4KxwEKBAQAAgASA0UCEhq5ASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
U2NhblJ1bi4gVGhlIG5hbWUgZm9sbG93cyB0aGUgZm9ybWF0IG9mCiAncHJvamVjdHMve3By
b2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhblJ1bnMve3NjYW5SdW5J
ZH0nLgogVGhlIFNjYW5SdW4gSURzIGFyZSBnZW5lcmF0ZWQgYnkgdGhlIHN5c3RlbS4KCgwK
BQQAAgAFEgNFAggKDAoFBAACAAESA0UJDQoMCgUEAAIAAxIDRRARCjIKBAQAAgESA0gCJRol
IFRoZSBleGVjdXRpb24gc3RhdGUgb2YgdGhlIFNjYW5SdW4uCgoMCgUEAAIBBhIDSAIQCgwK
BQQAAgEBEgNIESAKDAoFBAACAQMSA0gjJAp7CgQEAAICEgNMAh8abiBUaGUgcmVzdWx0IHN0
YXRlIG9mIHRoZSBTY2FuUnVuLiBUaGlzIGZpZWxkIGlzIG9ubHkgYXZhaWxhYmxlIGFmdGVy
IHRoZQogZXhlY3V0aW9uIHN0YXRlIHJlYWNoZXMgIkZJTklTSEVEIi4KCgwKBQQAAgIGEgNM
Ag0KDAoFBAACAgESA0wOGgoMCgUEAAICAxIDTB0eCjUKBAQAAgMSA08CKxooIFRoZSB0aW1l
IGF0IHdoaWNoIHRoZSBTY2FuUnVuIHN0YXJ0ZWQuCgoMCgUEAAIDBhIDTwIbCgwKBQQAAgMB
EgNPHCYKDAoFBAACAwMSA08pKgqBAQoEBAACBBIDUwIpGnQgVGhlIHRpbWUgYXQgd2hpY2gg
dGhlIFNjYW5SdW4gcmVhY2hlZCB0ZXJtaW5hdGlvbiBzdGF0ZSAtIHRoYXQgdGhlIFNjYW5S
dW4KIGlzIGVpdGhlciBmaW5pc2hlZCBvciBzdG9wcGVkIGJ5IHVzZXIuCgoMCgUEAAIEBhID
UwIbCgwKBQQAAgQBEgNTHCQKDAoFBAACBAMSA1MnKAqXAQoEBAACBRIDVwIfGokBIFRoZSBu
dW1iZXIgb2YgVVJMcyBjcmF3bGVkIGR1cmluZyB0aGlzIFNjYW5SdW4uIElmIHRoZSBzY2Fu
IGlzIGluIHByb2dyZXNzLAogdGhlIHZhbHVlIHJlcHJlc2VudHMgdGhlIG51bWJlciBvZiBV
UkxzIGNyYXdsZWQgdXAgdG8gbm93LgoKDAoFBAACBQUSA1cCBwoMCgUEAAIFARIDVwgaCgwK
BQQAAgUDEgNXHR4KpwIKBAQAAgYSA10CHhqZAiBUaGUgbnVtYmVyIG9mIFVSTHMgdGVzdGVk
IGR1cmluZyB0aGlzIFNjYW5SdW4uIElmIHRoZSBzY2FuIGlzIGluIHByb2dyZXNzLAogdGhl
IHZhbHVlIHJlcHJlc2VudHMgdGhlIG51bWJlciBvZiBVUkxzIHRlc3RlZCB1cCB0byBub3cu
IFRoZSBudW1iZXIgb2YKIFVSTHMgdGVzdGVkIGlzIHVzdWFsbHkgbGFyZ2VyIHRoYW4gdGhl
IG51bWJlciBVUkxTIGNyYXdsZWQgYmVjYXVzZQogdHlwaWNhbGx5IGEgY3Jhd2xlZCBVUkwg
aXMgdGVzdGVkIHdpdGggbXVsdGlwbGUgdGVzdCBwYXlsb2Fkcy4KCgwKBQQAAgYFEgNdAgcK
DAoFBAACBgESA10IGQoMCgUEAAIGAxIDXRwdCkIKBAQAAgcSA2ACHxo1IFdoZXRoZXIgdGhl
IHNjYW4gcnVuIGhhcyBmb3VuZCBhbnkgdnVsbmVyYWJpbGl0aWVzLgoKDAoFBAACBwUSA2AC
BgoMCgUEAAIHARIDYAcaCgwKBQQAAgcDEgNgHR4K2AEKBAQAAggSA2YCHRrKASBUaGUgcGVy
Y2VudGFnZSBvZiB0b3RhbCBjb21wbGV0aW9uIHJhbmdpbmcgZnJvbSAwIHRvIDEwMC4KIElm
IHRoZSBzY2FuIGlzIGluIHF1ZXVlLCB0aGUgdmFsdWUgaXMgMC4KIElmIHRoZSBzY2FuIGlz
IHJ1bm5pbmcsIHRoZSB2YWx1ZSByYW5nZXMgZnJvbSAwIHRvIDEwMC4KIElmIHRoZSBzY2Fu
IGlzIGZpbmlzaGVkLCB0aGUgdmFsdWUgaXMgMTAwLgoKDAoFBAACCAUSA2YCBwoMCgUEAAII
ARIDZggYCgwKBQQAAggDEgNmGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun ===
    # Fields for ScanRun
    # Field: name Type: 9 ()
    # Field: execution_state Type: 14 (.google.cloud.websecurityscanner.v1alpha.ScanRun.ExecutionState)
    # Field: result_state Type: 14 (.google.cloud.websecurityscanner.v1alpha.ScanRun.ResultState)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: urls_crawled_count Type: 3 ()
    # Field: urls_tested_count Type: 3 ()
    # Field: has_vulnerabilities Type: 8 ()
    # Field: progress_percent Type: 5 ()

# Enum: ScanRun::ExecutionState
our $ScanRun_EXECUTION_STATE_UNSPECIFIED = 0;
our $ScanRun_QUEUED = 1;
our $ScanRun_SCANNING = 2;
our $ScanRun_FINISHED = 3;

# Enum: ScanRun::ResultState
our $ScanRun_RESULT_STATE_UNSPECIFIED = 0;
our $ScanRun_SUCCESS = 1;
our $ScanRun_ERROR = 2;
our $ScanRun_KILLED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::ScanRun - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/scan_run.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::ScanRun;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun->new({
        name => $name,
        execution_state => $execution_state,
        result_state => $result_state,
        start_time => $start_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/scan_run.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun

A ScanRun is a output-only resource representing an actual run of the scan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the ScanRun. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.
The ScanRun IDs are generated by the system.

=item * C<< $msg->execution_state() >> / C<< $msg->execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ExecutionState>)

The execution state of the ScanRun.

=item * C<< $msg->result_state() >> / C<< $msg->result_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ResultState>)

The result state of the ScanRun. This field is only available after the
execution state reaches "FINISHED".

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the ScanRun started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the ScanRun reached termination state - that the ScanRun
is either finished or stopped by user.

=item * C<< $msg->urls_crawled_count() >> / C<< $msg->urls_crawled_count($value) >>

Type: C<Int64>

The number of URLs crawled during this ScanRun. If the scan is in progress,
the value represents the number of URLs crawled up to now.

=item * C<< $msg->urls_tested_count() >> / C<< $msg->urls_tested_count($value) >>

Type: C<Int64>

The number of URLs tested during this ScanRun. If the scan is in progress,
the value represents the number of URLs tested up to now. The number of
URLs tested is usually larger than the number URLS crawled because
typically a crawled URL is tested with multiple test payloads.

=item * C<< $msg->has_vulnerabilities() >> / C<< $msg->has_vulnerabilities($value) >>

Type: C<Bool>

Whether the scan run has found any vulnerabilities.

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

The percentage of total completion ranging from 0 to 100.
If the scan is in queue, the value is 0.
If the scan is running, the value ranges from 0 to 100.
If the scan is finished, the value is 100.

=back

=head3 Enum: ScanRun::ExecutionState

=over 4

=item * C<EXECUTION_STATE_UNSPECIFIED> => C<0>

=item * C<QUEUED> => C<1>

=item * C<SCANNING> => C<2>

=item * C<FINISHED> => C<3>

=back

=head3 Enum: ScanRun::ResultState

=over 4

=item * C<RESULT_STATE_UNSPECIFIED> => C<0>

=item * C<SUCCESS> => C<1>

=item * C<ERROR> => C<2>

=item * C<KILLED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::ScanRun::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
