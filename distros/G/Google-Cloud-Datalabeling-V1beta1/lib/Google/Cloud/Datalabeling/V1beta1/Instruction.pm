package Google::Cloud::Datalabeling::V1beta1::Instruction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Datalabeling::V1beta1::Dataset };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvaW5zdHJ1Y3Rpb24ucHJvdG8S
IWdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMRoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxovZ29vZ2xlL2Nsb3VkL2RhdGFsYWJlbGluZy92MWJldGExL2RhdGFzZXQucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i8gQKC0luc3RydWN0aW9uEhIK
BG5hbWUYASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIg
CgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SOwoLY3JlYXRlX3RpbWUYBCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1l
GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZRJICglkYXRh
X3R5cGUYBiABKA4yKy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRGF0YVR5
cGVSCGRhdGFUeXBlEl4KD2Nzdl9pbnN0cnVjdGlvbhgHIAEoCzIxLmdvb2dsZS5jbG91ZC5k
YXRhbGFiZWxpbmcudjFiZXRhMS5Dc3ZJbnN0cnVjdGlvbkICGAFSDmNzdkluc3RydWN0aW9u
EloKD3BkZl9pbnN0cnVjdGlvbhgJIAEoCzIxLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcu
djFiZXRhMS5QZGZJbnN0cnVjdGlvblIOcGRmSW5zdHJ1Y3Rpb24SLQoSYmxvY2tpbmdfcmVz
b3VyY2VzGAogAygJUhFibG9ja2luZ1Jlc291cmNlczpb6kFYCidkYXRhbGFiZWxpbmcuZ29v
Z2xlYXBpcy5jb20vSW5zdHJ1Y3Rpb24SLXByb2plY3RzL3twcm9qZWN0fS9pbnN0cnVjdGlv
bnMve2luc3RydWN0aW9ufSIyCg5Dc3ZJbnN0cnVjdGlvbhIgCgxnY3NfZmlsZV91cmkYASAB
KAlSCmdjc0ZpbGVVcmkiMgoOUGRmSW5zdHJ1Y3Rpb24SIAoMZ2NzX2ZpbGVfdXJpGAEgASgJ
UgpnY3NGaWxlVXJpQuMBCiVjb20uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGEx
UAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWxhYmVsaW5nL2FwaXYxYmV0YTEvZGF0YWxh
YmVsaW5ncGI7ZGF0YWxhYmVsaW5ncGKqAiFHb29nbGUuQ2xvdWQuRGF0YUxhYmVsaW5nLlYx
QmV0YTHKAiFHb29nbGVcQ2xvdWRcRGF0YUxhYmVsaW5nXFYxYmV0YTHqAiRHb29nbGU6OkNs
b3VkOjpEYXRhTGFiZWxpbmc6OlYxYmV0YTFKhxYKBhIEDwBWAQq9BAoBDBIDDwASMrIEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCgoICgECEgMRACoKCQoCAwASAxMAIwoJCgIDARIDFAA5CgkK
AgMCEgMVACkKCAoBCBIDFwA+CgkKAgglEgMXAD4KCAoBCBIDGABgCgkKAggLEgMYAGAKCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA+CgkKAggBEgMaAD4KCAoBCBIDGwA+CgkKAggp
EgMbAD4KCAoBCBIDHAA9CgkKAggtEgMcAD0KgAEKAgQAEgQgAEkBGnQgSW5zdHJ1Y3Rpb24g
b2YgaG93IHRvIHBlcmZvcm0gdGhlIGxhYmVsaW5nIHRhc2sgZm9yIGh1bWFuIG9wZXJhdG9y
cy4KIEN1cnJlbnRseSBvbmx5IFBERiBpbnN0cnVjdGlvbiBpcyBzdXBwb3J0ZWQuCgoKCgME
AAESAyAIEwoLCgMEAAcSBCECJAQKDQoFBAAHnQgSBCECJAQKcwoEBAACABIDKAISGmYgT3V0
cHV0IG9ubHkuIEluc3RydWN0aW9uIHJlc291cmNlIG5hbWUsIGZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0X2lkfS9pbnN0cnVjdGlvbnMve2luc3RydWN0aW9uX2lkfQoKDAoFBAACAAUS
AygCCAoMCgUEAAIAARIDKAkNCgwKBQQAAgADEgMoEBEKVwoEBAACARIDKwIaGkogUmVxdWly
ZWQuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGluc3RydWN0aW9uLiBNYXhpbXVtIG9mIDY0
IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDKwIICgwKBQQAAgEBEgMrCRUKDAoFBAACAQMSAysY
GQp7CgQEAAICEgMvAhkabiBPcHRpb25hbC4gVXNlci1wcm92aWRlZCBkZXNjcmlwdGlvbiBv
ZiB0aGUgaW5zdHJ1Y3Rpb24uCiBUaGUgZGVzY3JpcHRpb24gY2FuIGJlIHVwIHRvIDEwMDAw
IGNoYXJhY3RlcnMgbG9uZy4KCgwKBQQAAgIFEgMvAggKDAoFBAACAgESAy8JFAoMCgUEAAIC
AxIDLxcYCjkKBAQAAgMSAzICLBosIE91dHB1dCBvbmx5LiBDcmVhdGlvbiB0aW1lIG9mIGlu
c3RydWN0aW9uLgoKDAoFBAACAwYSAzICGwoMCgUEAAIDARIDMhwnCgwKBQQAAgMDEgMyKisK
PAoEBAACBBIDNQIsGi8gT3V0cHV0IG9ubHkuIExhc3QgdXBkYXRlIHRpbWUgb2YgaW5zdHJ1
Y3Rpb24uCgoMCgUEAAIEBhIDNQIbCgwKBQQAAgQBEgM1HCcKDAoFBAACBAMSAzUqKwo7CgQE
AAIFEgM4AhkaLiBSZXF1aXJlZC4gVGhlIGRhdGEgdHlwZSBvZiB0aGlzIGluc3RydWN0aW9u
LgoKDAoFBAACBQYSAzgCCgoMCgUEAAIFARIDOAsUCgwKBQQAAgUDEgM4FxgK4AIKBAQAAgYS
A0ACORrSAiBEZXByZWNhdGVkOiB0aGlzIGluc3RydWN0aW9uIGZvcm1hdCBpcyBub3Qgc3Vw
cG9ydGVkIGFueSBtb3JlLgogSW5zdHJ1Y3Rpb24gZnJvbSBhIENTViBmaWxlLCBzdWNoIGFz
IGZvciBjbGFzc2lmaWNhdGlvbiB0YXNrLgogVGhlIENTViBmaWxlIHNob3VsZCBoYXZlIGV4
YWN0IHR3byBjb2x1bW5zLCBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKCiAqIFRoZSBmaXJz
dCBjb2x1bW4gaXMgbGFiZWxlZCBkYXRhLCBzdWNoIGFzIGFuIGltYWdlIHJlZmVyZW5jZSwg
dGV4dC4KICogVGhlIHNlY29uZCBjb2x1bW4gaXMgY29tbWEgc2VwYXJhdGVkIGxhYmVscyBh
c3NvY2lhdGVkIHdpdGggZGF0YS4KCgwKBQQAAgYGEgNAAhAKDAoFBAACBgESA0ARIAoMCgUE
AAIGAxIDQCMkCgwKBQQAAgYIEgNAJTgKDQoGBAACBggDEgNAJjcKXQoEBAACBxIDRAIlGlAg
SW5zdHJ1Y3Rpb24gZnJvbSBhIFBERiBkb2N1bWVudC4gVGhlIFBERiBzaG91bGQgYmUgaW4g
YSBDbG91ZCBTdG9yYWdlCiBidWNrZXQuCgoMCgUEAAIHBhIDRAIQCgwKBQQAAgcBEgNEESAK
DAoFBAACBwMSA0QjJAptCgQEAAIIEgNIAioaYCBPdXRwdXQgb25seS4gVGhlIG5hbWVzIG9m
IGFueSByZWxhdGVkIHJlc291cmNlcyB0aGF0IGFyZSBibG9ja2luZyBjaGFuZ2VzCiB0byB0
aGUgaW5zdHJ1Y3Rpb24uCgoMCgUEAAIIBBIDSAIKCgwKBQQAAggFEgNICxEKDAoFBAACCAES
A0gSJAoMCgUEAAIIAxIDSCcpCmoKAgQBEgRNAFABGl4gRGVwcmVjYXRlZDogdGhpcyBpbnN0
cnVjdGlvbiBmb3JtYXQgaXMgbm90IHN1cHBvcnRlZCBhbnkgbW9yZS4KIEluc3RydWN0aW9u
IGZyb20gYSBDU1YgZmlsZS4KCgoKAwQBARIDTQgWCkYKBAQBAgASA08CGho5IENTViBmaWxl
IGZvciB0aGUgaW5zdHJ1Y3Rpb24uIE9ubHkgZ2NzIHBhdGggaXMgYWxsb3dlZC4KCgwKBQQB
AgAFEgNPAggKDAoFBAECAAESA08JFQoMCgUEAQIAAxIDTxgZCioKAgQCEgRTAFYBGh4gSW5z
dHJ1Y3Rpb24gZnJvbSBhIFBERiBmaWxlLgoKCgoDBAIBEgNTCBYKRgoEBAICABIDVQIaGjkg
UERGIGZpbGUgZm9yIHRoZSBpbnN0cnVjdGlvbi4gT25seSBnY3MgcGF0aCBpcyBhbGxvd2Vk
LgoKDAoFBAICAAUSA1UCCAoMCgUEAgIAARIDVQkVCgwKBQQCAgADEgNVGBliBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction ===
    # Fields for Instruction
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_type Type: 14 (.google.cloud.datalabeling.v1beta1.DataType)
    # Field: csv_instruction Type: 11 (.google.cloud.datalabeling.v1beta1.CsvInstruction)
    # Field: pdf_instruction Type: 11 (.google.cloud.datalabeling.v1beta1.PdfInstruction)
    # Field: blocking_resources Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction ===
    # Fields for CsvInstruction
    # Field: gcs_file_uri Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction ===
    # Fields for PdfInstruction
    # Field: gcs_file_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Instruction - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/instruction.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::Instruction;

    my $msg = Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/instruction.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::Instruction::Instruction

Instruction of how to perform the labeling task for human operators.
Currently only PDF instruction is supported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Instruction resource name, format:
projects/{project_id}/instructions/{instruction_id}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the instruction. Maximum of 64 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description of the instruction.
The description can be up to 10000 characters long.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of instruction.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Last update time of instruction.

=item * C<< $msg->data_type() >> / C<< $msg->data_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::DataType>)

Required. The data type of this instruction.

=item * C<< $msg->csv_instruction() >> / C<< $msg->csv_instruction($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction>)

Deprecated: this instruction format is not supported any more.
Instruction from a CSV file, such as for classification task.
The CSV file should have exact two columns, in the following format:

* The first column is labeled data, such as an image reference, text.
* The second column is comma separated labels associated with data.

=item * C<< $msg->pdf_instruction() >> / C<< $msg->pdf_instruction($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction>)

Instruction from a PDF document. The PDF should be in a Cloud Storage
bucket.

=item * C<< $msg->blocking_resources() >> / C<< $msg->blocking_resources($value) >>

Type: C<String>

Output only. The names of any related resources that are blocking changes
to the instruction.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Instruction::CsvInstruction

Deprecated: this instruction format is not supported any more.
Instruction from a CSV file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_file_uri() >> / C<< $msg->gcs_file_uri($value) >>

Type: C<String>

CSV file for the instruction. Only gcs path is allowed.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Instruction::PdfInstruction

Instruction from a PDF file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_file_uri() >> / C<< $msg->gcs_file_uri($value) >>

Type: C<String>

PDF file for the instruction. Only gcs path is allowed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::Instruction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
