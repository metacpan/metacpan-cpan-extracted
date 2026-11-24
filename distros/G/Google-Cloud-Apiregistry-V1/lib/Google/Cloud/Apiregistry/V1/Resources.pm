package Google::Cloud::Apiregistry::V1::Resources;

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
    eval { require Google::Cloud::Apiregistry::V1::Common };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjEvcmVzb3VyY2VzLnByb3RvEhtnb29nbGUu
Y2xvdWQuYXBpcmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9hcGlyZWdpc3RyeS92
MS9jb21tb24ucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8i7AMKCU1jcFNl
cnZlchIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPg
QQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2NyaXB0aW9u
EhIKBHVybHMYBCADKAlSBHVybHMSOwoMY2FwYWJpbGl0aWVzGAYgASgLMhcuZ29vZ2xlLnBy
b3RvYnVmLlN0cnVjdFIMY2FwYWJpbGl0aWVzEj0KBXN0YXRlGAcgASgOMiIuZ29vZ2xlLmNs
b3VkLmFwaXJlZ2lzdHJ5LnYxLlN0YXRlQgPgQQNSBXN0YXRlOuYB6kHiAQopY2xvdWRhcGly
ZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9NY3BTZXJ2ZXISXXByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9hcGlOYW1lc3BhY2VzL3thcGlfbmFtZXNwYWNlfS9tY3BT
ZXJ2ZXJzL3ttY3Bfc2VydmVyfRI/cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L21jcFNlcnZlcnMve21jcF9zZXJ2ZXJ9KgptY3BTZXJ2ZXJzMgltY3BTZXJ2ZXIi
1AQKB01jcFRvb2wSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgC
IAEoCUID4EEBUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRp
b24SJgoPbWNwX3NlcnZlcl91cmxzGAQgAygJUg1tY3BTZXJ2ZXJVcmxzEjoKDGlucHV0X3Nj
aGVtYRgFIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSC2lucHV0U2NoZW1hEjwKDW91
dHB1dF9zY2hlbWEYBiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgxvdXRwdXRTY2hl
bWESOQoLYW5ub3RhdGlvbnMYByABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ugthbm5v
dGF0aW9uczqIAupBhAIKJ2Nsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTWNwVG9v
bBJxcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwaU5hbWVzcGFj
ZXMve2FwaV9uYW1lc3BhY2V9L21jcFNlcnZlcnMve21jcF9zZXJ2ZXJ9L21jcFRvb2xzL3tt
Y3BfdG9vbH0SU3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tY3BT
ZXJ2ZXJzL3ttY3Bfc2VydmVyfS9tY3BUb29scy97bWNwX3Rvb2x9KghtY3BUb29sczIHbWNw
VG9vbELTAQofY29tLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MUIOUmVzb3VyY2VzUHJv
dG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlyZWdpc3RyeS9hcGl2MS9hcGlyZWdpc3Ry
eXBiO2FwaXJlZ2lzdHJ5cGKqAhtHb29nbGUuQ2xvdWQuQXBpUmVnaXN0cnkuVjHKAhtHb29n
bGVcQ2xvdWRcQXBpUmVnaXN0cnlcVjHqAh5Hb29nbGU6OkNsb3VkOjpBcGlSZWdpc3RyeTo6
VjFKlCMKBhIEDgB9AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAMgoJCgIDAxIDFQAmCggKAQgS
AxcAOAoJCgIIJRIDFwA4CggKAQgSAxgAWAoJCgIICxIDGABYCggKAQgSAxkAIgoJCgIIChID
GQAiCggKAQgSAxoALwoJCgIICBIDGgAvCggKAQgSAxsAOAoJCgIIARIDGwA4CggKAQgSAxwA
OAoJCgIIKRIDHAA4CggKAQgSAx0ANwoJCgIILRIDHQA3CoYBCgIEABIEIQBEARp6IFJlcHJl
c2VudHMgYW4gTUNQIFNlcnZlci4gTUNQIFNlcnZlcnMgYWN0IGFzIGVuZHBvaW50cyB0aGF0
IGV4cG9zZSBhCiBjb2xsZWN0aW9uIG9mIHRvb2xzIHRoYXQgY2FuIGJlIGludm9rZWQgYnkg
YWdlbnRzLgoKCgoDBAABEgMhCBEKCwoDBAAHEgQiAigECg0KBQQAB50IEgQiAigECr0CCgQE
AAIAEgMyAj0arwIgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIE1DUCBT
ZXJ2ZXIuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L21jcFNlcnZlcnMve21jcF9zZXJ2ZXJ9YC4KIEV4YW1wbGU6CiBwcm9qZWN0cy8xMjM0
NS9sb2NhdGlvbnMvdXMtY2VudHJhbDEvbWNwU2VydmVycy9nb29nbGU6YmlncXVlcnkuZ29v
Z2xlYXBpcy5jb206bWNwCiBmb3IgMXAKIHByb2plY3RzLzEyMzQ1L2xvY2F0aW9ucy91cy1j
ZW50cmFsMS9tY3BTZXJ2ZXJzL2FwcGh1YjpzdGFyYnVja3MgZm9yCiAycAoKDAoFBAACAAUS
AzICCAoMCgUEAAIAARIDMgkNCgwKBQQAAgADEgMyEBEKDAoFBAACAAgSAzISPAoPCggEAAIA
CJwIABIDMhM7CkIKBAQAAgESAzUCQxo1IE9wdGlvbmFsLiBBIGh1bWFuIHJlYWRhYmxlIG5h
bWUgZm9yIHRoZSBNQ1Agc2VydmVyLgoKDAoFBAACAQUSAzUCCAoMCgUEAAIBARIDNQkVCgwK
BQQAAgEDEgM1GBkKDAoFBAACAQgSAzUaQgoPCggEAAIBCJwIABIDNRtBClgKBAQAAgISAzgC
QhpLIE9wdGlvbmFsLiBBIGh1bWFuLXJlYWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoZSBNQ1Ag
U2VydmVyJ3MgZnVuY3Rpb25hbGl0eS4KCgwKBQQAAgIFEgM4AggKDAoFBAACAgESAzgJFAoM
CgUEAAICAxIDOBcYCgwKBQQAAgIIEgM4GUEKDwoIBAACAgicCAASAzgaQApZCgQEAAIDEgM7
AhsaTCBUaGUgYmFzZSBVUkwgb2YgdGhlIE1DUCBzZXJ2ZXIuIEV4YW1wbGU6IFtnZW9sb2Nh
dGlvbi5nb29nbGVhcGlzLmNvbS9tY3BdLgoKDAoFBAACAwQSAzsCCgoMCgUEAAIDBRIDOwsR
CgwKBQQAAgMBEgM7EhYKDAoFBAACAwMSAzsZGgriAQoEBAACBBIDQAIqGtQBIFRoZSBjYXBh
YmlsaXRpZXMgdGhhdCBhIHNlcnZlciBtYXkgc3VwcG9ydC4gS25vd24gY2FwYWJpbGl0aWVz
IGRlZmluZWQgaW4KIGh0dHBzOi8vbW9kZWxjb250ZXh0cHJvdG9jb2wuaW8vc3BlY2lmaWNh
dGlvbi8yMDI1LTA2LTE4L3NjaGVtYSNzZXJ2ZXJjYXBhYmlsaXRpZXMKIGFuZCBhZGRpdGlv
bmFsIGNhcGFiaWxpdGllcyBkZWZpbmVkIGJ5IHRoZSBzZXJ2ZXJzLgoKDAoFBAACBAYSA0AC
GAoMCgUEAAIEARIDQBklCgwKBQQAAgQDEgNAKCkKOAoEBAACBRIDQwI+GisgT3V0cHV0IG9u
bHkuIFRoZSBzdGF0ZSBvZiB0aGUgTUNQIFNlcnZlci4KCgwKBQQAAgUGEgNDAgcKDAoFBAAC
BQESA0MIDQoMCgUEAAIFAxIDQxARCgwKBQQAAgUIEgNDEj0KDwoIBAACBQicCAASA0MTPAov
CgIEARIERwB9ARojIE1lc3NhZ2UgZGVzY3JpYmluZyBNY3BUb29sIG9iamVjdAoKCgoDBAEB
EgNHCA8KCwoDBAEHEgRIAk4ECg0KBQQBB50IEgRIAk4ECvcCCgQEAQIAEgNYAj0a6QIgSWRl
bnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIE1jcFRvb2wuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21jcFNlcnZlcnMve21j
cF9zZXJ2ZXJ9L21jcFRvb2xzL3ttY3BfdG9vbH1gLgogRXhhbXBsZToKIHByb2plY3RzLzEy
MzQ1L2xvY2F0aW9ucy91cy1jZW50cmFsMS9tY3BTZXJ2ZXJzL2dvb2dsZTpiaWdxdWVyeS5n
b29nbGVhcGlzLmNvbTptY3AvbWNwVG9vbHMvaW5zZXJ0X2pvYgogZm9yIDFwCiBwcm9qZWN0
cy8xMjM0NS9sb2NhdGlvbnMvdXMtY2VudHJhbDEvbWNwU2VydmVycy9hcHBodWI6c3RhcmJ1
Y2tzL21jcFRvb2xzL29yZGVyX3BpenphCiBmb3IgMnAKCgwKBQQBAgAFEgNYAggKDAoFBAEC
AAESA1gJDQoMCgUEAQIAAxIDWBARCgwKBQQBAgAIEgNYEjwKDwoIBAECAAicCAASA1gTOwpS
CgQEAQIBEgNbAkMaRSBPcHRpb25hbC4gQSBodW1hbi1yZWFkYWJsZSBuYW1lIGZvciB0aGUg
dG9vbCwgc3VpdGFibGUgZm9yIGRpc3BsYXkuCgoMCgUEAQIBBRIDWwIICgwKBQQBAgEBEgNb
CRUKDAoFBAECAQMSA1sYGQoMCgUEAQIBCBIDWxpCCg8KCAQBAgEInAgAEgNbG0EKSAoEBAEC
AhIDXgIZGjsgQSBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgdG9vbCdzIGZ1
bmN0aW9uYWxpdHkuCgoMCgUEAQICBRIDXgIICgwKBQQBAgIBEgNeCRQKDAoFBAECAgMSA14X
GAqIAQoEBAECAxIDYgImGnsgQXV0b21hdGljYWxseSBwb3B1bGF0ZWQgcmVmZXJlbmNlIHRv
IE1DUCBTZXJ2ZXIuIEhlbHBmdWwgd2hlbiBtdWx0aXBsZQogdG9vbHMgYXJlIHJlcXVlc3Rl
ZCBhY3Jvc3MgZGlmZmVyZW50IE1DUCBTZXJ2ZXJzLgoKDAoFBAECAwQSA2ICCgoMCgUEAQID
BRIDYgsRCgwKBQQBAgMBEgNiEiEKDAoFBAECAwMSA2IkJQpcCgQEAQIEEgNmAioaTyBBIEpT
T04gU2NoZW1hIG9iamVjdCBkZWZpbmluZyB0aGUgZXhwZWN0ZWQgcGFyYW1ldGVycyBmb3Ig
aW52b2tpbmcgdGhlCiB0b29sLgoKDAoFBAECBAYSA2YCGAoMCgUEAQIEARIDZhklCgwKBQQB
AgQDEgNmKCkKZAoEBAECBRIDagIrGlcgT3B0aW9uYWwuIEEgSlNPTiBTY2hlbWEgb2JqZWN0
IGRlZmluaW5nIHRoZSBleHBlY3RlZCBzdHJ1Y3R1cmUgb2YgdGhlCiB0b29sJ3Mgb3V0cHV0
LgoKDAoFBAECBQYSA2oCGAoMCgUEAQIFARIDahkmCgwKBQQBAgUDEgNqKSoKwAcKBAQBAgYS
A3wCKRqyByBPcHRpb25hbCBrZXktdmFsdWUgb2JqZWN0IHRoYXQgYWxsb3dzIGRldmVsb3Bl
cnMgdG8gcHJvdmlkZSBhZGRpdGlvbmFsCiBpbmZvcm1hdGlvbiByZWdhcmRpbmcgdG9vbCBw
cm9wZXJ0aWVzLCBiZWhhdmlvciwgYW5kIHVzYWdlIGJlc3QgcHJhY3RpY2VzLgogQW5ub3Rh
dGlvbnMgb3IgdGFncyB0byBmYWNpbGl0YXRlIHNlbWFudGljIHNlYXJjaCBhY3Jvc3MgdG9v
bHMgKCJzZW1hbnRpYwogdGFncyIpIGFyZSBub3QgaW4gdGhlIE1WUCBzY29wZS4gV2hlbiBp
bXBsZW1lbnRlZCwgdGhlIGZpcnN0IHNldCBvZgogc3VwcG9ydGVkIGFubm90YXRpb25zIHdp
bGwgbGlrZWx5IGJlIHRoZSBzdGFuZGFyZCwgcHJlZGVmaW5lZCBhbm5vdGF0aW9ucwogZnJv
bSB0aGUgb3Blbi1zb3VyY2UgTUNQIHNwZWMuIFRoZXNlIGluY2x1ZGU6CiAgIC0gdGl0bGU6
IEEgaHVtYW4tcmVhZGFibGUgdGl0bGUgZm9yIHRoZSB0b29sLCB1c2VmdWwgZm9yIFVJIGRp
c3BsYXkuCiAgIC0gcmVhZE9ubHlIaW50OiBJZiB0cnVlLCBpbmRpY2F0ZXMgdGhlIHRvb2wg
ZG9lcyBub3QgbW9kaWZ5IGl0cwogICBlbnZpcm9ubWVudC4KICAgLSBkZXN0cnVjdGl2ZUhp
bnQ6IElmIHRydWUsIHRoZSB0b29sIG1heSBwZXJmb3JtIGRlc3RydWN0aXZlIHVwZGF0ZXMK
ICAgKG9ubHkgbWVhbmluZ2Z1bCB3aGVuIHJlYWRPbmx5SGludCBpcyBmYWxzZSkuCiAgIC0g
aWRlbXBvdGVudEhpbnQ6IElmIHRydWUsIGNhbGxpbmcgdGhlIHRvb2wgcmVwZWF0ZWRseSB3
aXRoIHRoZSBzYW1lCiAgIGFyZ3VtZW50cyBoYXMgbm8gYWRkaXRpb25hbCBlZmZlY3QgKG9u
bHkgbWVhbmluZ2Z1bCB3aGVuIHJlYWRPbmx5SGludCBpcwogICBmYWxzZSkuCiAgIC0gb3Bl
bldvcmxkSGludDogSWYgdHJ1ZSwgdGhlIHRvb2wgbWF5IGludGVyYWN0IHdpdGggYW4gIm9w
ZW4gd29ybGQiIG9mCiAgIGV4dGVybmFsIGVudGl0aWVzLgoKDAoFBAECBgYSA3wCGAoMCgUE
AQIGARIDfBkkCgwKBQQBAgYDEgN8JyhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apiregistry::V1::Resources::McpServer ===
    # Fields for McpServer
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: urls Type: 9 ()
    # Field: capabilities Type: 11 (.google.protobuf.Struct)
    # Field: state Type: 14 (.google.cloud.apiregistry.v1.State)

# === Message: Google::Cloud::Apiregistry::V1::Resources::McpTool ===
    # Fields for McpTool
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: mcp_server_urls Type: 9 ()
    # Field: input_schema Type: 11 (.google.protobuf.Struct)
    # Field: output_schema Type: 11 (.google.protobuf.Struct)
    # Field: annotations Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apiregistry::V1::Resources - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Apiregistry::V1::Resources;

    my $msg = Google::Cloud::Apiregistry::V1::Resources::McpServer->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        urls => $urls,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apiregistry::V1::Resources::McpServer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apiregistry::V1::Resources::McpServer

Represents an MCP Server. MCP Servers act as endpoints that expose a
collection of tools that can be invoked by agents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the MCP Server.
Format:
`projects/{project}/locations/{location}/mcpServers/{mcp_server}`.
Example:
projects/12345/locations/us-central1/mcpServers/google:bigquery.googleapis.com:mcp
for 1p
projects/12345/locations/us-central1/mcpServers/apphub:starbucks for
2p

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. A human readable name for the MCP server.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A human-readable description of the MCP Server's functionality.

=item * C<< $msg->urls() >> / C<< $msg->urls($value) >>

Type: C<String>

The base URL of the MCP server. Example: [geolocation.googleapis.com/mcp].

=item * C<< $msg->capabilities() >> / C<< $msg->capabilities($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The capabilities that a server may support. Known capabilities defined in
https://modelcontextprotocol.io/specification/2025-06-18/schema#servercapabilities
and additional capabilities defined by the servers.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Apiregistry::V1::State>)

Output only. The state of the MCP Server.

=back

=head2 Google::Cloud::Apiregistry::V1::Resources::McpTool

Message describing McpTool object

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the McpTool.
Format:
`projects/{project}/locations/{location}/mcpServers/{mcp_server}/mcpTools/{mcp_tool}`.
Example:
projects/12345/locations/us-central1/mcpServers/google:bigquery.googleapis.com:mcp/mcpTools/insert_job
for 1p
projects/12345/locations/us-central1/mcpServers/apphub:starbucks/mcpTools/order_pizza
for 2p

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. A human-readable name for the tool, suitable for display.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the tool's functionality.

=item * C<< $msg->mcp_server_urls() >> / C<< $msg->mcp_server_urls($value) >>

Type: C<String>

Automatically populated reference to MCP Server. Helpful when multiple
tools are requested across different MCP Servers.

=item * C<< $msg->input_schema() >> / C<< $msg->input_schema($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

A JSON Schema object defining the expected parameters for invoking the
tool.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A JSON Schema object defining the expected structure of the
tool's output.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional key-value object that allows developers to provide additional
information regarding tool properties, behavior, and usage best practices.
Annotations or tags to facilitate semantic search across tools ("semantic
tags") are not in the MVP scope. When implemented, the first set of
supported annotations will likely be the standard, predefined annotations
from the open-source MCP spec. These include:
  - title: A human-readable title for the tool, useful for UI display.
  - readOnlyHint: If true, indicates the tool does not modify its
  environment.
  - destructiveHint: If true, the tool may perform destructive updates
  (only meaningful when readOnlyHint is false).
  - idempotentHint: If true, calling the tool repeatedly with the same
  arguments has no additional effect (only meaningful when readOnlyHint is
  false).
  - openWorldHint: If true, the tool may interact with an "open world" of
  external entities.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
