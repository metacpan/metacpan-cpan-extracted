package Google::Cloud::Websecurityscanner::V1beta::ScanRun;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace };
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9zY2FuX3J1bi5wcm90
bxImZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEaGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aQWdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFiZXRh
L3NjYW5fcnVuX2Vycm9yX3RyYWNlLnByb3RvGkNnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlz
Y2FubmVyL3YxYmV0YS9zY2FuX3J1bl93YXJuaW5nX3RyYWNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIuwHCgdTY2FuUnVuEhIKBG5hbWUYASABKAlSBG5hbWUS
ZwoPZXhlY3V0aW9uX3N0YXRlGAIgASgOMj4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nh
bm5lci52MWJldGEuU2NhblJ1bi5FeGVjdXRpb25TdGF0ZVIOZXhlY3V0aW9uU3RhdGUSXgoM
cmVzdWx0X3N0YXRlGAMgASgOMjsuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52
MWJldGEuU2NhblJ1bi5SZXN1bHRTdGF0ZVILcmVzdWx0U3RhdGUSOQoKc3RhcnRfdGltZRgE
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGlt
ZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSLAoSdXJsc19j
cmF3bGVkX2NvdW50GAYgASgDUhB1cmxzQ3Jhd2xlZENvdW50EioKEXVybHNfdGVzdGVkX2Nv
dW50GAcgASgDUg91cmxzVGVzdGVkQ291bnQSLwoTaGFzX3Z1bG5lcmFiaWxpdGllcxgIIAEo
CFISaGFzVnVsbmVyYWJpbGl0aWVzEikKEHByb2dyZXNzX3BlcmNlbnQYCSABKAVSD3Byb2dy
ZXNzUGVyY2VudBJaCgtlcnJvcl90cmFjZRgKIAEoCzI5Lmdvb2dsZS5jbG91ZC53ZWJzZWN1
cml0eXNjYW5uZXIudjFiZXRhLlNjYW5SdW5FcnJvclRyYWNlUgplcnJvclRyYWNlEmIKDndh
cm5pbmdfdHJhY2VzGAsgAygLMjsuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52
MWJldGEuU2NhblJ1bldhcm5pbmdUcmFjZVINd2FybmluZ1RyYWNlcyJZCg5FeGVjdXRpb25T
dGF0ZRIfChtFWEVDVVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZRVUVVRUQQARIMCghT
Q0FOTklORxACEgwKCEZJTklTSEVEEAMiTwoLUmVzdWx0U3RhdGUSHAoYUkVTVUxUX1NUQVRF
X1VOU1BFQ0lGSUVEEAASCwoHU1VDQ0VTUxABEgkKBUVSUk9SEAISCgoGS0lMTEVEEAM6cOpB
bQopd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5SdW4SQHByb2plY3Rz
L3twcm9qZWN0fS9zY2FuQ29uZmlncy97c2Nhbl9jb25maWd9L3NjYW5SdW5zL3tzY2FuX3J1
bn1ClgIKKmNvbS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YUIMU2Nh
blJ1blByb3RvUAFaWmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2Fw
aXYxYmV0YS93ZWJzZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJwYqoCJkdv
b2dsZS5DbG91ZC5XZWJTZWN1cml0eVNjYW5uZXIuVjFCZXRhygImR29vZ2xlXENsb3VkXFdl
YlNlY3VyaXR5U2Nhbm5lclxWMWJldGHqAilHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNj
YW5uZXI6OlYxYmV0YUqLHgoGEgQPAHQBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCggKAQISAxEALwoJCgIDABIDEwAjCgkKAgMBEgMUAEsKCQoCAwISAxUATQoJCgID
AxIDFgApCggKAQgSAxgAQwoJCgIIJRIDGABDCggKAQgSAxkAcQoJCgIICxIDGQBxCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAQwoJCgIIARID
HABDCggKAQgSAx0AQwoJCgIIKRIDHQBDCggKAQgSAx4AQgoJCgIILRIDHgBCCmYKAgQAEgQi
AHQBGlogQSBTY2FuUnVuIGlzIGEgb3V0cHV0LW9ubHkgcmVzb3VyY2UgcmVwcmVzZW50aW5n
IGFuIGFjdHVhbCBydW4gb2YgdGhlIHNjYW4uCiBOZXh0IGlkOiAxMgoKCgoDBAABEgMiCA8K
CwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECjEKBAQABAASBCkCNgMaIyBUeXBlcyBvZiBT
Y2FuUnVuIGV4ZWN1dGlvbiBzdGF0ZS4KCgwKBQQABAABEgMpBxUKcwoGBAAEAAIAEgMsBCQa
ZCBSZXByZXNlbnRzIGFuIGludmFsaWQgc3RhdGUgY2F1c2VkIGJ5IGludGVybmFsIHNlcnZl
ciBlcnJvci4gVGhpcyB2YWx1ZQogc2hvdWxkIG5ldmVyIGJlIHJldHVybmVkLgoKDgoHBAAE
AAIAARIDLAQfCg4KBwQABAACAAISAywiIwoyCgYEAAQAAgESAy8EDxojIFRoZSBzY2FuIGlz
IHdhaXRpbmcgaW4gdGhlIHF1ZXVlLgoKDgoHBAAEAAIBARIDLwQKCg4KBwQABAACAQISAy8N
DgopCgYEAAQAAgISAzIEERoaIFRoZSBzY2FuIGlzIGluIHByb2dyZXNzLgoKDgoHBAAEAAIC
ARIDMgQMCg4KBwQABAACAgISAzIPEApACgYEAAQAAgMSAzUEERoxIFRoZSBzY2FuIGlzIGVp
dGhlciBmaW5pc2hlZCBvciBzdG9wcGVkIGJ5IHVzZXIuCgoOCgcEAAQAAgMBEgM1BAwKDgoH
BAAEAAIDAhIDNQ8QCi4KBAQABAESBDkCRgMaICBUeXBlcyBvZiBTY2FuUnVuIHJlc3VsdCBz
dGF0ZS4KCgwKBQQABAEBEgM5BxIKXQoGBAAEAQIAEgM8BCEaTiBEZWZhdWx0IHZhbHVlLiBU
aGlzIHZhbHVlIGlzIHJldHVybmVkIHdoZW4gdGhlIFNjYW5SdW4gaXMgbm90IHlldAogZmlu
aXNoZWQuCgoOCgcEAAQBAgABEgM8BBwKDgoHBAAEAQIAAhIDPB8gCjIKBgQABAECARIDPwQQ
GiMgVGhlIHNjYW4gZmluaXNoZWQgd2l0aG91dCBlcnJvcnMuCgoOCgcEAAQBAgEBEgM/BAsK
DgoHBAAEAQIBAhIDPw4PCi8KBgQABAECAhIDQgQOGiAgVGhlIHNjYW4gZmluaXNoZWQgd2l0
aCBlcnJvcnMuCgoOCgcEAAQBAgIBEgNCBAkKDgoHBAAEAQICAhIDQgwNCjEKBgQABAECAxID
RQQPGiIgVGhlIHNjYW4gd2FzIHRlcm1pbmF0ZWQgYnkgdXNlci4KCg4KBwQABAECAwESA0UE
CgoOCgcEAAQBAgMCEgNFDQ4KxwEKBAQAAgASA0sCEhq5ASBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgU2NhblJ1bi4gVGhlIG5hbWUgZm9sbG93cyB0aGUgZm9ybWF0IG9mCiAncHJvamVj
dHMve3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhblJ1bnMve3Nj
YW5SdW5JZH0nLgogVGhlIFNjYW5SdW4gSURzIGFyZSBnZW5lcmF0ZWQgYnkgdGhlIHN5c3Rl
bS4KCgwKBQQAAgAFEgNLAggKDAoFBAACAAESA0sJDQoMCgUEAAIAAxIDSxARCjIKBAQAAgES
A04CJRolIFRoZSBleGVjdXRpb24gc3RhdGUgb2YgdGhlIFNjYW5SdW4uCgoMCgUEAAIBBhID
TgIQCgwKBQQAAgEBEgNOESAKDAoFBAACAQMSA04jJAp7CgQEAAICEgNSAh8abiBUaGUgcmVz
dWx0IHN0YXRlIG9mIHRoZSBTY2FuUnVuLiBUaGlzIGZpZWxkIGlzIG9ubHkgYXZhaWxhYmxl
IGFmdGVyIHRoZQogZXhlY3V0aW9uIHN0YXRlIHJlYWNoZXMgIkZJTklTSEVEIi4KCgwKBQQA
AgIGEgNSAg0KDAoFBAACAgESA1IOGgoMCgUEAAICAxIDUh0eCjUKBAQAAgMSA1UCKxooIFRo
ZSB0aW1lIGF0IHdoaWNoIHRoZSBTY2FuUnVuIHN0YXJ0ZWQuCgoMCgUEAAIDBhIDVQIbCgwK
BQQAAgMBEgNVHCYKDAoFBAACAwMSA1UpKgqBAQoEBAACBBIDWQIpGnQgVGhlIHRpbWUgYXQg
d2hpY2ggdGhlIFNjYW5SdW4gcmVhY2hlZCB0ZXJtaW5hdGlvbiBzdGF0ZSAtIHRoYXQgdGhl
IFNjYW5SdW4KIGlzIGVpdGhlciBmaW5pc2hlZCBvciBzdG9wcGVkIGJ5IHVzZXIuCgoMCgUE
AAIEBhIDWQIbCgwKBQQAAgQBEgNZHCQKDAoFBAACBAMSA1knKAqXAQoEBAACBRIDXQIfGokB
IFRoZSBudW1iZXIgb2YgVVJMcyBjcmF3bGVkIGR1cmluZyB0aGlzIFNjYW5SdW4uIElmIHRo
ZSBzY2FuIGlzIGluIHByb2dyZXNzLAogdGhlIHZhbHVlIHJlcHJlc2VudHMgdGhlIG51bWJl
ciBvZiBVUkxzIGNyYXdsZWQgdXAgdG8gbm93LgoKDAoFBAACBQUSA10CBwoMCgUEAAIFARID
XQgaCgwKBQQAAgUDEgNdHR4KpwIKBAQAAgYSA2MCHhqZAiBUaGUgbnVtYmVyIG9mIFVSTHMg
dGVzdGVkIGR1cmluZyB0aGlzIFNjYW5SdW4uIElmIHRoZSBzY2FuIGlzIGluIHByb2dyZXNz
LAogdGhlIHZhbHVlIHJlcHJlc2VudHMgdGhlIG51bWJlciBvZiBVUkxzIHRlc3RlZCB1cCB0
byBub3cuIFRoZSBudW1iZXIgb2YKIFVSTHMgdGVzdGVkIGlzIHVzdWFsbHkgbGFyZ2VyIHRo
YW4gdGhlIG51bWJlciBVUkxTIGNyYXdsZWQgYmVjYXVzZQogdHlwaWNhbGx5IGEgY3Jhd2xl
ZCBVUkwgaXMgdGVzdGVkIHdpdGggbXVsdGlwbGUgdGVzdCBwYXlsb2Fkcy4KCgwKBQQAAgYF
EgNjAgcKDAoFBAACBgESA2MIGQoMCgUEAAIGAxIDYxwdCkIKBAQAAgcSA2YCHxo1IFdoZXRo
ZXIgdGhlIHNjYW4gcnVuIGhhcyBmb3VuZCBhbnkgdnVsbmVyYWJpbGl0aWVzLgoKDAoFBAAC
BwUSA2YCBgoMCgUEAAIHARIDZgcaCgwKBQQAAgcDEgNmHR4K2AEKBAQAAggSA2wCHRrKASBU
aGUgcGVyY2VudGFnZSBvZiB0b3RhbCBjb21wbGV0aW9uIHJhbmdpbmcgZnJvbSAwIHRvIDEw
MC4KIElmIHRoZSBzY2FuIGlzIGluIHF1ZXVlLCB0aGUgdmFsdWUgaXMgMC4KIElmIHRoZSBz
Y2FuIGlzIHJ1bm5pbmcsIHRoZSB2YWx1ZSByYW5nZXMgZnJvbSAwIHRvIDEwMC4KIElmIHRo
ZSBzY2FuIGlzIGZpbmlzaGVkLCB0aGUgdmFsdWUgaXMgMTAwLgoKDAoFBAACCAUSA2wCBwoM
CgUEAAIIARIDbAgYCgwKBQQAAggDEgNsGxwKlAEKBAQAAgkSA3ACJRqGASBJZiByZXN1bHRf
c3RhdGUgaXMgYW4gRVJST1IsIHRoaXMgZmllbGQgcHJvdmlkZXMgdGhlIHByaW1hcnkgcmVh
c29uIGZvcgogc2NhbidzIHRlcm1pbmF0aW9uIGFuZCBtb3JlIGRldGFpbHMsIGlmIHN1Y2gg
YXJlIGF2YWlsYWJsZS4KCgwKBQQAAgkGEgNwAhMKDAoFBAACCQESA3AUHwoMCgUEAAIJAxID
cCIkClAKBAQAAgoSA3MCMxpDIEEgbGlzdCBvZiB3YXJuaW5ncywgaWYgc3VjaCBhcmUgZW5j
b3VudGVyZWQgZHVyaW5nIHRoaXMgc2NhbiBydW4uCgoMCgUEAAIKBBIDcwIKCgwKBQQAAgoG
EgNzCx4KDAoFBAACCgESA3MfLQoMCgUEAAIKAxIDczAyYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun ===
    # Fields for ScanRun
    # Field: name Type: 9 ()
    # Field: execution_state Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanRun.ExecutionState)
    # Field: result_state Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanRun.ResultState)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: urls_crawled_count Type: 3 ()
    # Field: urls_tested_count Type: 3 ()
    # Field: has_vulnerabilities Type: 8 ()
    # Field: progress_percent Type: 5 ()
    # Field: error_trace Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanRunErrorTrace)
    # Field: warning_traces Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanRunWarningTrace)

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

Google::Cloud::Websecurityscanner::V1beta::ScanRun - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/scan_run.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::ScanRun;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun->new({
        name => $name,
        execution_state => $execution_state,
        result_state => $result_state,
        start_time => $start_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/scan_run.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun

A ScanRun is a output-only resource representing an actual run of the scan.
Next id: 12

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the ScanRun. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.
The ScanRun IDs are generated by the system.

=item * C<< $msg->execution_state() >> / C<< $msg->execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRun::ExecutionState>)

The execution state of the ScanRun.

=item * C<< $msg->result_state() >> / C<< $msg->result_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRun::ResultState>)

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

=item * C<< $msg->error_trace() >> / C<< $msg->error_trace($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::ScanRunErrorTrace>)

If result_state is an ERROR, this field provides the primary reason for
scan's termination and more details, if such are available.

=item * C<< $msg->warning_traces() >> / C<< $msg->warning_traces($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::ScanRunWarningTrace>)

A list of warnings, if such are encountered during this scan run.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::ScanRun::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
