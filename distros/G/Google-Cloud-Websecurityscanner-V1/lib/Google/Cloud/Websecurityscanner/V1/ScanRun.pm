package Google::Cloud::Websecurityscanner::V1::ScanRun;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace };
    eval { require Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuLnByb3RvEiJn
b29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxGj1nb29nbGUvY2xvdWQvd2Vic2Vj
dXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuX2Vycm9yX3RyYWNlLnByb3RvGj9nb29nbGUvY2xv
dWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuX3dhcm5pbmdfdHJhY2UucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i6gYKB1NjYW5SdW4SEgoEbmFtZRgB
IAEoCVIEbmFtZRJjCg9leGVjdXRpb25fc3RhdGUYAiABKA4yOi5nb29nbGUuY2xvdWQud2Vi
c2VjdXJpdHlzY2FubmVyLnYxLlNjYW5SdW4uRXhlY3V0aW9uU3RhdGVSDmV4ZWN1dGlvblN0
YXRlEloKDHJlc3VsdF9zdGF0ZRgDIAEoDjI3Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNj
YW5uZXIudjEuU2NhblJ1bi5SZXN1bHRTdGF0ZVILcmVzdWx0U3RhdGUSOQoKc3RhcnRfdGlt
ZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRf
dGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSLAoSdXJs
c19jcmF3bGVkX2NvdW50GAYgASgDUhB1cmxzQ3Jhd2xlZENvdW50EioKEXVybHNfdGVzdGVk
X2NvdW50GAcgASgDUg91cmxzVGVzdGVkQ291bnQSLwoTaGFzX3Z1bG5lcmFiaWxpdGllcxgI
IAEoCFISaGFzVnVsbmVyYWJpbGl0aWVzEikKEHByb2dyZXNzX3BlcmNlbnQYCSABKAVSD3By
b2dyZXNzUGVyY2VudBJWCgtlcnJvcl90cmFjZRgKIAEoCzI1Lmdvb2dsZS5jbG91ZC53ZWJz
ZWN1cml0eXNjYW5uZXIudjEuU2NhblJ1bkVycm9yVHJhY2VSCmVycm9yVHJhY2USXgoOd2Fy
bmluZ190cmFjZXMYCyADKAsyNy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYx
LlNjYW5SdW5XYXJuaW5nVHJhY2VSDXdhcm5pbmdUcmFjZXMiWQoORXhlY3V0aW9uU3RhdGUS
HwobRVhFQ1VUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASCgoGUVVFVUVEEAESDAoIU0NBTk5J
TkcQAhIMCghGSU5JU0hFRBADIk8KC1Jlc3VsdFN0YXRlEhwKGFJFU1VMVF9TVEFURV9VTlNQ
RUNJRklFRBAAEgsKB1NVQ0NFU1MQARIJCgVFUlJPUhACEgoKBktJTExFRBADQoICCiZjb20u
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MUIMU2NhblJ1blByb3RvUAFaVmNs
b3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2FwaXYxL3dlYnNlY3VyaXR5
c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgIiR29vZ2xlLkNsb3VkLldlYlNlY3Vy
aXR5U2Nhbm5lci5WMcoCIkdvb2dsZVxDbG91ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjHqAiVH
b29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNjYW5uZXI6OlYxSvQeCgYSBA4AbQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIARwoJCgID
ARIDEwBJCgkKAgMCEgMUACkKCAoBCBIDFgA/CgkKAgglEgMWAD8KCAoBCBIDFwBtCgkKAggL
EgMXAG0KCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAtCgkKAggIEgMZAC0KCAoBCBID
GgA/CgkKAggBEgMaAD8KCAoBCBIDGwA/CgkKAggpEgMbAD8KCAoBCBIDHAA+CgkKAggtEgMc
AD4KZgoCBAASBCAAbQEaWiBBIFNjYW5SdW4gaXMgYSBvdXRwdXQtb25seSByZXNvdXJjZSBy
ZXByZXNlbnRpbmcgYW4gYWN0dWFsIHJ1biBvZiB0aGUgc2Nhbi4KIE5leHQgaWQ6IDEyCgoK
CgMEAAESAyAIDwoxCgQEAAQAEgQiAi8DGiMgVHlwZXMgb2YgU2NhblJ1biBleGVjdXRpb24g
c3RhdGUuCgoMCgUEAAQAARIDIgcVCnMKBgQABAACABIDJQQkGmQgUmVwcmVzZW50cyBhbiBp
bnZhbGlkIHN0YXRlIGNhdXNlZCBieSBpbnRlcm5hbCBzZXJ2ZXIgZXJyb3IuIFRoaXMgdmFs
dWUKIHNob3VsZCBuZXZlciBiZSByZXR1cm5lZC4KCg4KBwQABAACAAESAyUEHwoOCgcEAAQA
AgACEgMlIiMKMgoGBAAEAAIBEgMoBA8aIyBUaGUgc2NhbiBpcyB3YWl0aW5nIGluIHRoZSBx
dWV1ZS4KCg4KBwQABAACAQESAygECgoOCgcEAAQAAgECEgMoDQ4KKQoGBAAEAAICEgMrBBEa
GiBUaGUgc2NhbiBpcyBpbiBwcm9ncmVzcy4KCg4KBwQABAACAgESAysEDAoOCgcEAAQAAgIC
EgMrDxAKQAoGBAAEAAIDEgMuBBEaMSBUaGUgc2NhbiBpcyBlaXRoZXIgZmluaXNoZWQgb3Ig
c3RvcHBlZCBieSB1c2VyLgoKDgoHBAAEAAIDARIDLgQMCg4KBwQABAACAwISAy4PEAouCgQE
AAQBEgQyAj8DGiAgVHlwZXMgb2YgU2NhblJ1biByZXN1bHQgc3RhdGUuCgoMCgUEAAQBARID
MgcSCl0KBgQABAECABIDNQQhGk4gRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyByZXR1
cm5lZCB3aGVuIHRoZSBTY2FuUnVuIGlzIG5vdCB5ZXQKIGZpbmlzaGVkLgoKDgoHBAAEAQIA
ARIDNQQcCg4KBwQABAECAAISAzUfIAoyCgYEAAQBAgESAzgEEBojIFRoZSBzY2FuIGZpbmlz
aGVkIHdpdGhvdXQgZXJyb3JzLgoKDgoHBAAEAQIBARIDOAQLCg4KBwQABAECAQISAzgODwov
CgYEAAQBAgISAzsEDhogIFRoZSBzY2FuIGZpbmlzaGVkIHdpdGggZXJyb3JzLgoKDgoHBAAE
AQICARIDOwQJCg4KBwQABAECAgISAzsMDQoxCgYEAAQBAgMSAz4EDxoiIFRoZSBzY2FuIHdh
cyB0ZXJtaW5hdGVkIGJ5IHVzZXIuCgoOCgcEAAQBAgMBEgM+BAoKDgoHBAAEAQIDAhIDPg0O
CtQBCgQEAAIAEgNEAhIaxgEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZSBTY2FuUnVuLiBUaGUgbmFtZSBmb2xsb3dzIHRoZSBmb3JtYXQgb2YKICdwcm9qZWN0cy97
cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfS9zY2FuUnVucy97c2NhblJ1
bklkfScuCiBUaGUgU2NhblJ1biBJRHMgYXJlIGdlbmVyYXRlZCBieSB0aGUgc3lzdGVtLgoK
DAoFBAACAAUSA0QCCAoMCgUEAAIAARIDRAkNCgwKBQQAAgADEgNEEBEKPwoEBAACARIDRwIl
GjIgT3V0cHV0IG9ubHkuIFRoZSBleGVjdXRpb24gc3RhdGUgb2YgdGhlIFNjYW5SdW4uCgoM
CgUEAAIBBhIDRwIQCgwKBQQAAgEBEgNHESAKDAoFBAACAQMSA0cjJAqIAQoEBAACAhIDSwIf
GnsgT3V0cHV0IG9ubHkuIFRoZSByZXN1bHQgc3RhdGUgb2YgdGhlIFNjYW5SdW4uIFRoaXMg
ZmllbGQgaXMgb25seSBhdmFpbGFibGUgYWZ0ZXIgdGhlCiBleGVjdXRpb24gc3RhdGUgcmVh
Y2hlcyAiRklOSVNIRUQiLgoKDAoFBAACAgYSA0sCDQoMCgUEAAICARIDSw4aCgwKBQQAAgID
EgNLHR4KQgoEBAACAxIDTgIrGjUgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRo
ZSBTY2FuUnVuIHN0YXJ0ZWQuCgoMCgUEAAIDBhIDTgIbCgwKBQQAAgMBEgNOHCYKDAoFBAAC
AwMSA04pKgqPAQoEBAACBBIDUgIpGoEBIE91dHB1dCBvbmx5LiBUaGUgdGltZSBhdCB3aGlj
aCB0aGUgU2NhblJ1biByZWFjaGVkIHRlcm1pbmF0aW9uIHN0YXRlIC0gdGhhdCB0aGUgU2Nh
blJ1bgogaXMgZWl0aGVyIGZpbmlzaGVkIG9yIHN0b3BwZWQgYnkgdXNlci4KCgwKBQQAAgQG
EgNSAhsKDAoFBAACBAESA1IcJAoMCgUEAAIEAxIDUicoCqQBCgQEAAIFEgNWAh8algEgT3V0
cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgVVJMcyBjcmF3bGVkIGR1cmluZyB0aGlzIFNjYW5S
dW4uIElmIHRoZSBzY2FuIGlzIGluIHByb2dyZXNzLAogdGhlIHZhbHVlIHJlcHJlc2VudHMg
dGhlIG51bWJlciBvZiBVUkxzIGNyYXdsZWQgdXAgdG8gbm93LgoKDAoFBAACBQUSA1YCBwoM
CgUEAAIFARIDVggaCgwKBQQAAgUDEgNWHR4KtAIKBAQAAgYSA1wCHhqmAiBPdXRwdXQgb25s
eS4gVGhlIG51bWJlciBvZiBVUkxzIHRlc3RlZCBkdXJpbmcgdGhpcyBTY2FuUnVuLiBJZiB0
aGUgc2NhbiBpcyBpbiBwcm9ncmVzcywKIHRoZSB2YWx1ZSByZXByZXNlbnRzIHRoZSBudW1i
ZXIgb2YgVVJMcyB0ZXN0ZWQgdXAgdG8gbm93LiBUaGUgbnVtYmVyIG9mCiBVUkxzIHRlc3Rl
ZCBpcyB1c3VhbGx5IGxhcmdlciB0aGFuIHRoZSBudW1iZXIgVVJMUyBjcmF3bGVkIGJlY2F1
c2UKIHR5cGljYWxseSBhIGNyYXdsZWQgVVJMIGlzIHRlc3RlZCB3aXRoIG11bHRpcGxlIHRl
c3QgcGF5bG9hZHMuCgoMCgUEAAIGBRIDXAIHCgwKBQQAAgYBEgNcCBkKDAoFBAACBgMSA1wc
HQpPCgQEAAIHEgNfAh8aQiBPdXRwdXQgb25seS4gV2hldGhlciB0aGUgc2NhbiBydW4gaGFz
IGZvdW5kIGFueSB2dWxuZXJhYmlsaXRpZXMuCgoMCgUEAAIHBRIDXwIGCgwKBQQAAgcBEgNf
BxoKDAoFBAACBwMSA18dHgrlAQoEBAACCBIDZQIdGtcBIE91dHB1dCBvbmx5LiBUaGUgcGVy
Y2VudGFnZSBvZiB0b3RhbCBjb21wbGV0aW9uIHJhbmdpbmcgZnJvbSAwIHRvIDEwMC4KIElm
IHRoZSBzY2FuIGlzIGluIHF1ZXVlLCB0aGUgdmFsdWUgaXMgMC4KIElmIHRoZSBzY2FuIGlz
IHJ1bm5pbmcsIHRoZSB2YWx1ZSByYW5nZXMgZnJvbSAwIHRvIDEwMC4KIElmIHRoZSBzY2Fu
IGlzIGZpbmlzaGVkLCB0aGUgdmFsdWUgaXMgMTAwLgoKDAoFBAACCAUSA2UCBwoMCgUEAAII
ARIDZQgYCgwKBQQAAggDEgNlGxwKoQEKBAQAAgkSA2kCJRqTASBPdXRwdXQgb25seS4gSWYg
cmVzdWx0X3N0YXRlIGlzIGFuIEVSUk9SLCB0aGlzIGZpZWxkIHByb3ZpZGVzIHRoZSBwcmlt
YXJ5IHJlYXNvbiBmb3IKIHNjYW4ncyB0ZXJtaW5hdGlvbiBhbmQgbW9yZSBkZXRhaWxzLCBp
ZiBzdWNoIGFyZSBhdmFpbGFibGUuCgoMCgUEAAIJBhIDaQITCgwKBQQAAgkBEgNpFB8KDAoF
BAACCQMSA2kiJApdCgQEAAIKEgNsAjMaUCBPdXRwdXQgb25seS4gQSBsaXN0IG9mIHdhcm5p
bmdzLCBpZiBzdWNoIGFyZSBlbmNvdW50ZXJlZCBkdXJpbmcgdGhpcyBzY2FuIHJ1bi4KCgwK
BQQAAgoEEgNsAgoKDAoFBAACCgYSA2wLHgoMCgUEAAIKARIDbB8tCgwKBQQAAgoDEgNsMDJi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun ===
    # Fields for ScanRun
    # Field: name Type: 9 ()
    # Field: execution_state Type: 14 (.google.cloud.websecurityscanner.v1.ScanRun.ExecutionState)
    # Field: result_state Type: 14 (.google.cloud.websecurityscanner.v1.ScanRun.ResultState)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: urls_crawled_count Type: 3 ()
    # Field: urls_tested_count Type: 3 ()
    # Field: has_vulnerabilities Type: 8 ()
    # Field: progress_percent Type: 5 ()
    # Field: error_trace Type: 11 (.google.cloud.websecurityscanner.v1.ScanRunErrorTrace)
    # Field: warning_traces Type: 11 (.google.cloud.websecurityscanner.v1.ScanRunWarningTrace)

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

Google::Cloud::Websecurityscanner::V1::ScanRun - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/scan_run.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::ScanRun;

    my $msg = Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun->new({
        name => $name,
        execution_state => $execution_state,
        result_state => $result_state,
        start_time => $start_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/scan_run.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun

A ScanRun is a output-only resource representing an actual run of the scan.
Next id: 12

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the ScanRun. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.
The ScanRun IDs are generated by the system.

=item * C<< $msg->execution_state() >> / C<< $msg->execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRun::ExecutionState>)

Output only. The execution state of the ScanRun.

=item * C<< $msg->result_state() >> / C<< $msg->result_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRun::ResultState>)

Output only. The result state of the ScanRun. This field is only available after the
execution state reaches "FINISHED".

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the ScanRun started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the ScanRun reached termination state - that the ScanRun
is either finished or stopped by user.

=item * C<< $msg->urls_crawled_count() >> / C<< $msg->urls_crawled_count($value) >>

Type: C<Int64>

Output only. The number of URLs crawled during this ScanRun. If the scan is in progress,
the value represents the number of URLs crawled up to now.

=item * C<< $msg->urls_tested_count() >> / C<< $msg->urls_tested_count($value) >>

Type: C<Int64>

Output only. The number of URLs tested during this ScanRun. If the scan is in progress,
the value represents the number of URLs tested up to now. The number of
URLs tested is usually larger than the number URLS crawled because
typically a crawled URL is tested with multiple test payloads.

=item * C<< $msg->has_vulnerabilities() >> / C<< $msg->has_vulnerabilities($value) >>

Type: C<Bool>

Output only. Whether the scan run has found any vulnerabilities.

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Output only. The percentage of total completion ranging from 0 to 100.
If the scan is in queue, the value is 0.
If the scan is running, the value ranges from 0 to 100.
If the scan is finished, the value is 100.

=item * C<< $msg->error_trace() >> / C<< $msg->error_trace($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace>)

Output only. If result_state is an ERROR, this field provides the primary reason for
scan's termination and more details, if such are available.

=item * C<< $msg->warning_traces() >> / C<< $msg->warning_traces($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::ScanRunWarningTrace>)

Output only. A list of warnings, if such are encountered during this scan run.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::ScanRun::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
