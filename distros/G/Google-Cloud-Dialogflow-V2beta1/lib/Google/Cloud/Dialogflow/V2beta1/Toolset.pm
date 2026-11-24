package Google::Cloud::Dialogflow::V2beta1::Toolset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::V2beta1::Tool };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3Rvb2xzZXQucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9kaWFsb2dm
bG93L3YyYmV0YTEvdG9vbC5wcm90byLyAQoLVG9vbHNldFRvb2wSPAoHdG9vbHNldBgBIAEo
CUIi4EEC+kEcChpjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbHNldFIHdG9vbHNldBImCgxvcGVy
YXRpb25faWQYAiABKAlCA+BBAVILb3BlcmF0aW9uSWQSfQoYY29uZmlybWF0aW9uX3JlcXVp
cmVtZW50GAMgASgOMj0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Ub29sLkNv
bmZpcm1hdGlvblJlcXVpcmVtZW50QgPgQQFSF2NvbmZpcm1hdGlvblJlcXVpcmVtZW50QocC
CiNjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMUIMVG9vbHNldFByb3RvUAFa
Q2Nsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxvZ2Zsb3dw
YjtkaWFsb2dmbG93cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYyQmV0YTHq
QWMKGmNlcy5nb29nbGVhcGlzLmNvbS9Ub29sc2V0EkVwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1KtQsKBhIE
DgAyAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANAoICgEIEgMWADwKCQoCCCUSAxYAPAoICgEI
EgMXAFoKCQoCCAsSAxcAWgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoCCAgS
AxkALQoICgEIEgMaADwKCQoCCAESAxoAPAoICgEIEgMbACAKCQoCCCQSAxsAIAoJCgEIEgQc
AB8CCgwKBAidCAASBBwAHwIKNAoCBAASBCIAMgEaKCBBIHRvb2wgdGhhdCBpcyBjcmVhdGVk
IGZyb20gYSB0b29sc2V0LgoKCgoDBAABEgMiCBMKoAEKBAQAAgASBCYCKQQakQEgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSB0b29sc2V0IHRvIHJldHJpZXZlIHRoZSBzY2hlbWEgZm9y
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9h
cHBzL3thcHB9L3Rvb2xzZXRzL3t0b29sc2V0fWAKCgwKBQQAAgAFEgMmAggKDAoFBAACAAES
AyYJEAoMCgUEAAIAAxIDJhMUCg0KBQQAAgAIEgQmFSkDCg8KCAQAAgAInAgAEgMnBCoKDgoH
BAACAAifCBIDKARMCoUBCgQEAAIBEgMtAkMaeCBPcHRpb25hbC4gVGhlIG9wZXJhdGlvbklk
IGZpZWxkIG9mIHRoZSBPcGVuQVBJIGVuZHBvaW50LiBUaGUgb3BlcmF0aW9uSWQKIG11c3Qg
YmUgcHJlc2VudCBpbiB0aGUgdG9vbHNldCdzIGRlZmluaXRpb24uCgoMCgUEAAIBBRIDLQII
CgwKBQQAAgEBEgMtCRUKDAoFBAACAQMSAy0YGQoMCgUEAAIBCBIDLRpCCg8KCAQAAgEInAgA
EgMtG0EKUQoEBAACAhIEMAIxLxpDIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0aGUg
dG9vbCByZXF1aXJlcyBodW1hbiBjb25maXJtYXRpb24uCgoMCgUEAAICBhIDMAIeCgwKBQQA
AgIBEgMwHzcKDAoFBAACAgMSAzA6OwoMCgUEAAICCBIDMQYuCg8KCAQAAgIInAgAEgMxBy1i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Toolset::ToolsetTool ===
    # Fields for ToolsetTool
    # Field: toolset Type: 9 ()
    # Field: operation_id Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2beta1.Tool.ConfirmationRequirement)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Toolset - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Toolset;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Toolset::ToolsetTool->new({
        toolset => $toolset,
        operation_id => $operation_id,
        confirmation_requirement => $confirmation_requirement,
    });

    # Read or update a field
    my $val = $msg->toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Toolset::ToolsetTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Toolset::ToolsetTool

A tool that is created from a toolset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<String>

Required. The name of the toolset to retrieve the schema for.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->operation_id() >> / C<< $msg->operation_id($value) >>

Type: C<String>

Optional. The operationId field of the OpenAPI endpoint. The operationId
must be present in the toolset's definition.

=item * C<< $msg->confirmation_requirement() >> / C<< $msg->confirmation_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Tool::ConfirmationRequirement>)

Optional. Indicates whether the tool requires human confirmation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Toolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
