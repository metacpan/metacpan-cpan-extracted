package Google::Cloud::Ces::V1beta::Toolset;

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
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Cloud::Ces::V1beta::ConnectorToolset };
    eval { require Google::Cloud::Ces::V1beta::Fakes };
    eval { require Google::Cloud::Ces::V1beta::McpToolset };
    eval { require Google::Cloud::Ces::V1beta::OpenApiToolset };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS90b29sc2V0LnByb3RvEhdnb29nbGUuY2xvdWQu
Y2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvY29tbW9uLnByb3Rv
Gi9nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb25uZWN0b3JfdG9vbHNldC5wcm90bxojZ29v
Z2xlL2Nsb3VkL2Nlcy92MWJldGEvZmFrZXMucHJvdG8aKWdvb2dsZS9jbG91ZC9jZXMvdjFi
ZXRhL21jcF90b29sc2V0LnByb3RvGi5nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vcGVuX2Fw
aV90b29sc2V0LnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8igAcKB1Rvb2xzZXQSSwoLbWNwX3Rvb2xzZXQY
BiABKAsyIy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5NY3BUb29sc2V0QgPgQQFIAFIKbWNw
VG9vbHNldBJYChBvcGVuX2FwaV90b29sc2V0GAcgASgLMicuZ29vZ2xlLmNsb3VkLmNlcy52
MWJldGEuT3BlbkFwaVRvb2xzZXRCA+BBAUgAUg5vcGVuQXBpVG9vbHNldBJdChFjb25uZWN0
b3JfdG9vbHNldBgIIAEoCzIpLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkNvbm5lY3RvclRv
b2xzZXRCA+BBAUgAUhBjb25uZWN0b3JUb29sc2V0EhcKBG5hbWUYASABKAlCA+BBCFIEbmFt
ZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRp
b24YCiABKAlCA+BBAVILZGVzY3JpcHRpb24SOAoHdGltZW91dBgMIAEoCzIZLmdvb2dsZS5w
cm90b2J1Zi5EdXJhdGlvbkID4EEBUgd0aW1lb3V0EkAKC2NyZWF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90
aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1l
EhIKBGV0YWcYBSABKAlSBGV0YWcSUgoOZXhlY3V0aW9uX3R5cGUYCSABKA4yJi5nb29nbGUu
Y2xvdWQuY2VzLnYxYmV0YS5FeGVjdXRpb25UeXBlQgPgQQFSDWV4ZWN1dGlvblR5cGUSVgoQ
dG9vbF9mYWtlX2NvbmZpZxgLIAEoCzInLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRvb2xG
YWtlQ29uZmlnQgPgQQFSDnRvb2xGYWtlQ29uZmlnOnnqQXYKGmNlcy5nb29nbGVhcGlzLmNv
bS9Ub29sc2V0EkVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBw
cy97YXBwfS90b29sc2V0cy97dG9vbHNldH0qCHRvb2xzZXRzMgd0b29sc2V0Qg4KDHRvb2xz
ZXRfdHlwZUJcChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCDFRvb2xzZXRQcm90b1AB
Wi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKlRgKBhIE
DgBgAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQALgoJCgIDAxIDFQA5CgkKAgMEEgMWAC0KCQoC
AwUSAxcAMwoJCgIDBhIDGAA4CgkKAgMHEgMZACgKCQoCAwgSAxoAKQoICgEIEgMcAEQKCQoC
CAsSAxwARAoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeAC0KCQoCCAgSAx4ALQoICgEI
EgMfADQKCQoCCAESAx8ANApnCgIEABIEIwBgARpbIEEgdG9vbHNldCByZXByZXNlbnRzIGEg
Z3JvdXAgb2YgZHluYW1pY2FsbHkgbWFuYWdlZCB0b29scyB0aGF0IGNhbiBiZSB1c2VkCiBi
eSB0aGUgYWdlbnQuCgoKCgMEAAESAyMIDwoLCgMEAAcSBCQCKQQKDQoFBAAHnQgSBCQCKQQK
KAoEBAAIABIELAI6AxoaIFRoZSB0eXBlIG9mIHRoZSB0b29sc2V0LgoKDAoFBAAIAAESAywI
FAplCgQEAAIAEgMvBEgaWCBPcHRpb25hbC4gQSB0b29sc2V0IHRoYXQgY29udGFpbnMgYSBs
aXN0IG9mIHRvb2xzIHRoYXQgYXJlIG9mZmVyZWQgYnkgdGhlCiBNQ1Agc2VydmVyLgoKDAoF
BAACAAYSAy8EDgoMCgUEAAIAARIDLw8aCgwKBQQAAgADEgMvHR4KDAoFBAACAAgSAy8fRwoP
CggEAAIACJwIABIDLyBGCmkKBAQAAgESBDMENDEaWyBPcHRpb25hbC4gQSB0b29sc2V0IHRo
YXQgY29udGFpbnMgYSBsaXN0IG9mIHRvb2xzIHRoYXQgYXJlIGRlZmluZWQgYnkgYW4KIE9w
ZW5BUEkgc2NoZW1hLgoKDAoFBAACAQYSAzMEEgoMCgUEAAIBARIDMxMjCgwKBQQAAgEDEgMz
JicKDAoFBAACAQgSAzQIMAoPCggEAAIBCJwIABIDNAkvCmQKBAQAAgISBDgEOTEaViBPcHRp
b25hbC4gQSB0b29sc2V0IHRoYXQgZ2VuZXJhdGVzIHRvb2xzIGZyb20gYW4gSW50ZWdyYXRp
b24gQ29ubmVjdG9ycwogQ29ubmVjdGlvbi4KCgwKBQQAAgIGEgM4BBQKDAoFBAACAgESAzgV
JgoMCgUEAAICAxIDOCkqCgwKBQQAAgIIEgM5CDAKDwoIBAACAgicCAASAzkJLwqTAQoEBAAC
AxIDPwI9GoUBIElkZW50aWZpZXIuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgdG9v
bHNldC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1gCgoMCgUEAAIDBRIDPwIICgwKBQQA
AgMBEgM/CQ0KDAoFBAACAwMSAz8QEQoMCgUEAAIDCBIDPxI8Cg8KCAQAAgMInAgAEgM/EzsK
XgoEBAACBBIDQwJDGlEgT3B0aW9uYWwuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHRvb2xz
ZXQuIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgc2FtZQogYXBwLgoKDAoFBAACBAUSA0MC
CAoMCgUEAAIEARIDQwkVCgwKBQQAAgQDEgNDGBkKDAoFBAACBAgSA0MaQgoPCggEAAIECJwI
ABIDQxtBCjgKBAQAAgUSA0YCQxorIE9wdGlvbmFsLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhl
IHRvb2xzZXQuCgoMCgUEAAIFBRIDRgIICgwKBQQAAgUBEgNGCRQKDAoFBAACBQMSA0YXGQoM
CgUEAAIFCBIDRhpCCg8KCAQAAgUInAgAEgNGG0EKuAEKBAQAAgYSBEsCTC8aqQEgT3B0aW9u
YWwuIFRoZSB0aW1lb3V0IGZvciB0aGUgdG9vbHNldCBleGVjdXRpb24uIElmIG5vdCBzZXQs
IHRoZSBkZWZhdWx0CiB0aW1lb3V0IGlzIDMwIHNlY29uZHMgZm9yIGBTWU5DSFJPTk9VU2Ag
dG9vbHNldHMgYW5kIDYwIHNlY29uZHMgZm9yCiBgQVNZTkNIUk9OT1VTYCB0b29sc2V0cy4K
CgwKBQQAAgYGEgNLAhoKDAoFBAACBgESA0sbIgoMCgUEAAIGAxIDSyUnCgwKBQQAAgYIEgNM
Bi4KDwoIBAACBgicCAASA0wHLQpECgQEAAIHEgRPAlAyGjYgT3V0cHV0IG9ubHkuIFRpbWVz
dGFtcCB3aGVuIHRoZSB0b29sc2V0IHdhcyBjcmVhdGVkLgoKDAoFBAACBwYSA08CGwoMCgUE
AAIHARIDTxwnCgwKBQQAAgcDEgNPKisKDAoFBAACBwgSA1AGMQoPCggEAAIHCJwIABIDUAcw
CkkKBAQAAggSBFMCVDIaOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIHRvb2xz
ZXQgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAggGEgNTAhsKDAoFBAACCAESA1McJwoMCgUE
AAIIAxIDUyorCgwKBQQAAggIEgNUBjEKDwoIBAACCAicCAASA1QHMAqtAQoEBAACCRIDWQIS
Gp8BIEVUYWcgdXNlZCB0byBlbnN1cmUgdGhlIG9iamVjdCBoYXNuJ3QgY2hhbmdlZCBkdXJp
bmcgYSByZWFkLW1vZGlmeS13cml0ZQogb3BlcmF0aW9uLiBJZiB0aGUgZXRhZyBpcyBlbXB0
eSwgdGhlIHVwZGF0ZSB3aWxsIG92ZXJ3cml0ZSBhbnkgY29uY3VycmVudAogY2hhbmdlcy4K
CgwKBQQAAgkFEgNZAggKDAoFBAACCQESA1kJDQoMCgUEAAIJAxIDWRARCkgKBAQAAgoSA1wC
TBo7IE9wdGlvbmFsLiBUaGUgZXhlY3V0aW9uIHR5cGUgb2YgdGhlIHRvb2xzIGluIHRoZSB0
b29sc2V0LgoKDAoFBAACCgYSA1wCDwoMCgUEAAIKARIDXBAeCgwKBQQAAgoDEgNcISIKDAoF
BAACCggSA1wjSwoPCggEAAIKCJwIABIDXCRKCkcKBAQAAgsSA18CUBo6IE9wdGlvbmFsLiBD
b25maWd1cmF0aW9uIGZvciB0b29scyBiZWhhdmlvciBpbiBmYWtlIG1vZGUuCgoMCgUEAAIL
BhIDXwIQCgwKBQQAAgsBEgNfESEKDAoFBAACCwMSA18kJgoMCgUEAAILCBIDXydPCg8KCAQA
AgsInAgAEgNfKE5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Toolset::Toolset ===
    # Fields for Toolset
    # Field: mcp_toolset Type: 11 (.google.cloud.ces.v1beta.McpToolset)
    # Field: open_api_toolset Type: 11 (.google.cloud.ces.v1beta.OpenApiToolset)
    # Field: connector_toolset Type: 11 (.google.cloud.ces.v1beta.ConnectorToolset)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: execution_type Type: 14 (.google.cloud.ces.v1beta.ExecutionType)
    # Field: tool_fake_config Type: 11 (.google.cloud.ces.v1beta.ToolFakeConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Toolset - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Toolset;

    my $msg = Google::Cloud::Ces::V1beta::Toolset::Toolset->new({
        mcp_toolset => $mcp_toolset,
        open_api_toolset => $open_api_toolset,
        connector_toolset => $connector_toolset,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->mcp_toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Toolset::Toolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Toolset::Toolset

A toolset represents a group of dynamically managed tools that can be used
by the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_toolset() >> / C<< $msg->mcp_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpToolset::McpToolset>)

Optional. A toolset that contains a list of tools that are offered by the
MCP server.

=item * C<< $msg->open_api_toolset() >> / C<< $msg->open_api_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset>)

Optional. A toolset that contains a list of tools that are defined by an
OpenAPI schema.

=item * C<< $msg->connector_toolset() >> / C<< $msg->connector_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ConnectorToolset::ConnectorToolset>)

Optional. A toolset that generates tools from an Integration Connectors
Connection.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the toolset.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the toolset. Must be unique within the same
app.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the toolset.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for the toolset execution. If not set, the default
timeout is 30 seconds for `SYNCHRONOUS` toolsets and 60 seconds for
`ASYNCHRONOUS` toolsets.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the toolset was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the toolset was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

ETag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=item * C<< $msg->execution_type() >> / C<< $msg->execution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::ExecutionType>)

Optional. The execution type of the tools in the toolset.

=item * C<< $msg->tool_fake_config() >> / C<< $msg->tool_fake_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Fakes::ToolFakeConfig>)

Optional. Configuration for tools behavior in fake mode.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Toolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
