package Google::Cloud::Websecurityscanner::V1::ScanRunLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Websecurityscanner::V1::ScanRun };
    eval { require Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuX2xvZy5wcm90
bxIiZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MRoxZ29vZ2xlL2Nsb3VkL3dl
YnNlY3VyaXR5c2Nhbm5lci92MS9zY2FuX3J1bi5wcm90bxo9Z29vZ2xlL2Nsb3VkL3dlYnNl
Y3VyaXR5c2Nhbm5lci92MS9zY2FuX3J1bl9lcnJvcl90cmFjZS5wcm90byLQAwoKU2NhblJ1
bkxvZxIYCgdzdW1tYXJ5GAEgASgJUgdzdW1tYXJ5EhIKBG5hbWUYAiABKAlSBG5hbWUSYwoP
ZXhlY3V0aW9uX3N0YXRlGAMgASgOMjouZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5l
ci52MS5TY2FuUnVuLkV4ZWN1dGlvblN0YXRlUg5leGVjdXRpb25TdGF0ZRJaCgxyZXN1bHRf
c3RhdGUYBCABKA4yNy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlNjYW5S
dW4uUmVzdWx0U3RhdGVSC3Jlc3VsdFN0YXRlEiwKEnVybHNfY3Jhd2xlZF9jb3VudBgFIAEo
A1IQdXJsc0NyYXdsZWRDb3VudBIqChF1cmxzX3Rlc3RlZF9jb3VudBgGIAEoA1IPdXJsc1Rl
c3RlZENvdW50EiEKDGhhc19maW5kaW5ncxgHIAEoCFILaGFzRmluZGluZ3MSVgoLZXJyb3Jf
dHJhY2UYCCABKAsyNS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlNjYW5S
dW5FcnJvclRyYWNlUgplcnJvclRyYWNlQoUCCiZjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3Vy
aXR5c2Nhbm5lci52MUIPU2NhblJ1bkxvZ1Byb3RvUAFaVmNsb3VkLmdvb2dsZS5jb20vZ28v
d2Vic2VjdXJpdHlzY2FubmVyL2FwaXYxL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3Vy
aXR5c2Nhbm5lcnBiqgIiR29vZ2xlLkNsb3VkLldlYlNlY3VyaXR5U2Nhbm5lci5WMcoCIkdv
b2dsZVxDbG91ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjHqAiVHb29nbGU6OkNsb3VkOjpXZWJT
ZWN1cml0eVNjYW5uZXI6OlYxSpkNCgYSBA4ANgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAOwoJCgIDARIDEwBHCggKAQgSAxUAPwoJ
CgIIJRIDFQA/CggKAQgSAxYAbQoJCgIICxIDFgBtCggKAQgSAxcAIgoJCgIIChIDFwAiCggK
AQgSAxgAMAoJCgIICBIDGAAwCggKAQgSAxkAPwoJCgIIARIDGQA/CggKAQgSAxoAPwoJCgII
KRIDGgA/CggKAQgSAxsAPgoJCgIILRIDGwA+CrACCgIEABIEIgA2ARqjAiBBIFNjYW5SdW5M
b2cgaXMgYW4gb3V0cHV0LW9ubHkgcHJvdG8gdXNlZCBmb3IgU3RhY2tkcml2ZXIgY3VzdG9t
ZXIgbG9nZ2luZy4KIEl0IGlzIHVzZWQgZm9yIGxvZ3MgY292ZXJpbmcgdGhlIHN0YXJ0IGFu
ZCBlbmQgb2Ygc2NhbiBwaXBlbGluZXMuCiBPdGhlciB0aGFuIGFuIGFkZGVkIHN1bW1hcnks
IHRoaXMgaXMgYSBzdWJzZXQgb2YgdGhlIFNjYW5SdW4uCiBSZXByZXNlbnRhdGlvbiBpbiBs
b2dzIGlzIGVpdGhlciBhIHByb3RvIFN0cnVjdCwgb3IgY29udmVydGVkIHRvIEpTT04uCiBO
ZXh0IGlkOiA5CgoKCgMEAAESAyIIEgo2CgQEAAIAEgMkAhUaKSBIdW1hbiBmcmllbmRseSBt
ZXNzYWdlIGFib3V0IHRoZSBldmVudC4KCgwKBQQAAgAFEgMkAggKDAoFBAACAAESAyQJEAoM
CgUEAAIAAxIDJBMUCj0KBAQAAgESAycCEhowIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBT
Y2FuUnVuIGJlaW5nIGxvZ2dlZC4KCgwKBQQAAgEFEgMnAggKDAoFBAACAQESAycJDQoMCgUE
AAIBAxIDJxARCjIKBAQAAgISAyoCUBolIFRoZSBleGVjdXRpb24gc3RhdGUgb2YgdGhlIFNj
YW5SdW4uCgoMCgUEAAICBhIDKgI7CgwKBQQAAgIBEgMqPEsKDAoFBAACAgMSAypOTwovCgQE
AAIDEgMtAkoaIiBUaGUgcmVzdWx0IHN0YXRlIG9mIHRoZSBTY2FuUnVuLgoKDAoFBAACAwYS
Ay0COAoMCgUEAAIDARIDLTlFCgwKBQQAAgMDEgMtSEkKCwoEBAACBBIDLwIfCgwKBQQAAgQF
EgMvAgcKDAoFBAACBAESAy8IGgoMCgUEAAIEAxIDLx0eCgsKBAQAAgUSAzECHgoMCgUEAAIF
BRIDMQIHCgwKBQQAAgUBEgMxCBkKDAoFBAACBQMSAzEcHQoLCgQEAAIGEgMzAhgKDAoFBAAC
BgUSAzMCBgoMCgUEAAIGARIDMwcTCgwKBQQAAgYDEgMzFhcKCwoEBAACBxIDNQJHCgwKBQQA
AgcGEgM1AjYKDAoFBAACBwESAzU3QgoMCgUEAAIHAxIDNUVGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::ScanRunLog::ScanRunLog ===
    # Fields for ScanRunLog
    # Field: summary Type: 9 ()
    # Field: name Type: 9 ()
    # Field: execution_state Type: 14 (.google.cloud.websecurityscanner.v1.ScanRun.ExecutionState)
    # Field: result_state Type: 14 (.google.cloud.websecurityscanner.v1.ScanRun.ResultState)
    # Field: urls_crawled_count Type: 3 ()
    # Field: urls_tested_count Type: 3 ()
    # Field: has_findings Type: 8 ()
    # Field: error_trace Type: 11 (.google.cloud.websecurityscanner.v1.ScanRunErrorTrace)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::ScanRunLog - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/scan_run_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::ScanRunLog;

    my $msg = Google::Cloud::Websecurityscanner::V1::ScanRunLog::ScanRunLog->new({
        summary => $summary,
        name => $name,
        execution_state => $execution_state,
        result_state => $result_state,
    });

    # Read or update a field
    my $val = $msg->summary();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::ScanRunLog::ScanRunLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/scan_run_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::ScanRunLog::ScanRunLog

A ScanRunLog is an output-only proto used for Stackdriver customer logging.
It is used for logs covering the start and end of scan pipelines.
Other than an added summary, this is a subset of the ScanRun.
Representation in logs is either a proto Struct, or converted to JSON.
Next id: 9

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->summary() >> / C<< $msg->summary($value) >>

Type: C<String>

Human friendly message about the event.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the ScanRun being logged.

=item * C<< $msg->execution_state() >> / C<< $msg->execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRun::ExecutionState>)

The execution state of the ScanRun.

=item * C<< $msg->result_state() >> / C<< $msg->result_state($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRun::ResultState>)

The result state of the ScanRun.

=item * C<< $msg->urls_crawled_count() >> / C<< $msg->urls_crawled_count($value) >>

Type: C<Int64>

=item * C<< $msg->urls_tested_count() >> / C<< $msg->urls_tested_count($value) >>

Type: C<Int64>

=item * C<< $msg->has_findings() >> / C<< $msg->has_findings($value) >>

Type: C<Bool>

=item * C<< $msg->error_trace() >> / C<< $msg->error_trace($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::ScanRunLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
