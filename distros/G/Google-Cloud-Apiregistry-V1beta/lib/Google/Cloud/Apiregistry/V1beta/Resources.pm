package Google::Cloud::Apiregistry::V1beta::Resources;

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
    eval { require Google::Cloud::Apiregistry::V1beta::Common };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjFiZXRhL3Jlc291cmNlcy5wcm90bxIfZ29v
Z2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3VkL2FwaXJl
Z2lzdHJ5L3YxYmV0YS9jb21tb24ucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJv
dG8i8AMKCU1jcFNlcnZlchIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9u
YW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFS
C2Rlc2NyaXB0aW9uEhIKBHVybHMYBCADKAlSBHVybHMSOwoMY2FwYWJpbGl0aWVzGAYgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIMY2FwYWJpbGl0aWVzEkEKBXN0YXRlGAcgASgO
MiYuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YS5TdGF0ZUID4EEDUgVzdGF0ZTrm
AepB4gEKKWNsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTWNwU2VydmVyEl1wcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBpTmFtZXNwYWNlcy97YXBp
X25hbWVzcGFjZX0vbWNwU2VydmVycy97bWNwX3NlcnZlcn0SP3Byb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tY3BTZXJ2ZXJzL3ttY3Bfc2VydmVyfSoKbWNwU2Vy
dmVyczIJbWNwU2VydmVyItQECgdNY3BUb29sEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIm
CgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24Y
AyABKAlSC2Rlc2NyaXB0aW9uEiYKD21jcF9zZXJ2ZXJfdXJscxgEIAMoCVINbWNwU2VydmVy
VXJscxI6CgxpbnB1dF9zY2hlbWEYBSABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ugtp
bnB1dFNjaGVtYRI8Cg1vdXRwdXRfc2NoZW1hGAYgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0
cnVjdFIMb3V0cHV0U2NoZW1hEjkKC2Fubm90YXRpb25zGAcgASgLMhcuZ29vZ2xlLnByb3Rv
YnVmLlN0cnVjdFILYW5ub3RhdGlvbnM6iALqQYQCCidjbG91ZGFwaXJlZ2lzdHJ5Lmdvb2ds
ZWFwaXMuY29tL01jcFRvb2wScXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hcGlOYW1lc3BhY2VzL3thcGlfbmFtZXNwYWNlfS9tY3BTZXJ2ZXJzL3ttY3Bfc2Vy
dmVyfS9tY3BUb29scy97bWNwX3Rvb2x9ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vbWNwU2VydmVycy97bWNwX3NlcnZlcn0vbWNwVG9vbHMve21jcF90b29s
fSoIbWNwVG9vbHMyB21jcFRvb2xC5wEKI2NvbS5nb29nbGUuY2xvdWQuYXBpcmVnaXN0cnku
djFiZXRhQg5SZXNvdXJjZXNQcm90b1ABWkVjbG91ZC5nb29nbGUuY29tL2dvL2FwaXJlZ2lz
dHJ5L2FwaXYxYmV0YS9hcGlyZWdpc3RyeXBiO2FwaXJlZ2lzdHJ5cGKqAh9Hb29nbGUuQ2xv
dWQuQXBpUmVnaXN0cnkuVjFCZXRhygIfR29vZ2xlXENsb3VkXEFwaVJlZ2lzdHJ5XFYxYmV0
YeoCIkdvb2dsZTo6Q2xvdWQ6OkFwaVJlZ2lzdHJ5OjpWMWJldGFKlCMKBhIEDgB9AQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQANgoJCgIDAxIDFQAmCggKAQgSAxcAPAoJCgIIJRIDFwA8CggK
AQgSAxgAXAoJCgIICxIDGABcCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoALwoJCgII
CBIDGgAvCggKAQgSAxsAPAoJCgIIARIDGwA8CggKAQgSAxwAPAoJCgIIKRIDHAA8CggKAQgS
Ax0AOwoJCgIILRIDHQA7CoYBCgIEABIEIQBEARp6IFJlcHJlc2VudHMgYW4gTUNQIFNlcnZl
ci4gTUNQIFNlcnZlcnMgYWN0IGFzIGVuZHBvaW50cyB0aGF0IGV4cG9zZSBhCiBjb2xsZWN0
aW9uIG9mIHRvb2xzIHRoYXQgY2FuIGJlIGludm9rZWQgYnkgYWdlbnRzLgoKCgoDBAABEgMh
CBEKCwoDBAAHEgQiAigECg0KBQQAB50IEgQiAigECr0CCgQEAAIAEgMyAj0arwIgSWRlbnRp
Zmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIE1DUCBTZXJ2ZXIuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21jcFNlcnZlcnMve21j
cF9zZXJ2ZXJ9YC4KIEV4YW1wbGU6CiBwcm9qZWN0cy8xMjM0NS9sb2NhdGlvbnMvdXMtY2Vu
dHJhbDEvbWNwU2VydmVycy9nb29nbGU6YmlncXVlcnkuZ29vZ2xlYXBpcy5jb206bWNwCiBm
b3IgMXAKIHByb2plY3RzLzEyMzQ1L2xvY2F0aW9ucy91cy1jZW50cmFsMS9tY3BTZXJ2ZXJz
L2FwcGh1YjpzdGFyYnVja3MgZm9yCiAycAoKDAoFBAACAAUSAzICCAoMCgUEAAIAARIDMgkN
CgwKBQQAAgADEgMyEBEKDAoFBAACAAgSAzISPAoPCggEAAIACJwIABIDMhM7CkIKBAQAAgES
AzUCQxo1IE9wdGlvbmFsLiBBIGh1bWFuIHJlYWRhYmxlIG5hbWUgZm9yIHRoZSBNQ1Agc2Vy
dmVyLgoKDAoFBAACAQUSAzUCCAoMCgUEAAIBARIDNQkVCgwKBQQAAgEDEgM1GBkKDAoFBAAC
AQgSAzUaQgoPCggEAAIBCJwIABIDNRtBClgKBAQAAgISAzgCQhpLIE9wdGlvbmFsLiBBIGh1
bWFuLXJlYWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoZSBNQ1AgU2VydmVyJ3MgZnVuY3Rpb25h
bGl0eS4KCgwKBQQAAgIFEgM4AggKDAoFBAACAgESAzgJFAoMCgUEAAICAxIDOBcYCgwKBQQA
AgIIEgM4GUEKDwoIBAACAgicCAASAzgaQApZCgQEAAIDEgM7AhsaTCBUaGUgYmFzZSBVUkwg
b2YgdGhlIE1DUCBzZXJ2ZXIuIEV4YW1wbGU6IFtnZW9sb2NhdGlvbi5nb29nbGVhcGlzLmNv
bS9tY3BdLgoKDAoFBAACAwQSAzsCCgoMCgUEAAIDBRIDOwsRCgwKBQQAAgMBEgM7EhYKDAoF
BAACAwMSAzsZGgriAQoEBAACBBIDQAIqGtQBIFRoZSBjYXBhYmlsaXRpZXMgdGhhdCBhIHNl
cnZlciBtYXkgc3VwcG9ydC4gS25vd24gY2FwYWJpbGl0aWVzIGRlZmluZWQgaW4KIGh0dHBz
Oi8vbW9kZWxjb250ZXh0cHJvdG9jb2wuaW8vc3BlY2lmaWNhdGlvbi8yMDI1LTA2LTE4L3Nj
aGVtYSNzZXJ2ZXJjYXBhYmlsaXRpZXMKIGFuZCBhZGRpdGlvbmFsIGNhcGFiaWxpdGllcyBk
ZWZpbmVkIGJ5IHRoZSBzZXJ2ZXJzLgoKDAoFBAACBAYSA0ACGAoMCgUEAAIEARIDQBklCgwK
BQQAAgQDEgNAKCkKOAoEBAACBRIDQwI+GisgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0
aGUgTUNQIFNlcnZlci4KCgwKBQQAAgUGEgNDAgcKDAoFBAACBQESA0MIDQoMCgUEAAIFAxID
QxARCgwKBQQAAgUIEgNDEj0KDwoIBAACBQicCAASA0MTPAovCgIEARIERwB9ARojIE1lc3Nh
Z2UgZGVzY3JpYmluZyBNY3BUb29sIG9iamVjdAoKCgoDBAEBEgNHCA8KCwoDBAEHEgRIAk4E
Cg0KBQQBB50IEgRIAk4ECvcCCgQEAQIAEgNYAj0a6QIgSWRlbnRpZmllci4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIE1jcFRvb2wuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L21jcFNlcnZlcnMve21jcF9zZXJ2ZXJ9L21jcFRvb2xz
L3ttY3BfdG9vbH1gLgogRXhhbXBsZToKIHByb2plY3RzLzEyMzQ1L2xvY2F0aW9ucy91cy1j
ZW50cmFsMS9tY3BTZXJ2ZXJzL2dvb2dsZTpiaWdxdWVyeS5nb29nbGVhcGlzLmNvbTptY3Av
bWNwVG9vbHMvaW5zZXJ0X2pvYgogZm9yIDFwCiBwcm9qZWN0cy8xMjM0NS9sb2NhdGlvbnMv
dXMtY2VudHJhbDEvbWNwU2VydmVycy9hcHBodWI6c3RhcmJ1Y2tzL21jcFRvb2xzL29yZGVy
X3BpenphCiBmb3IgMnAKCgwKBQQBAgAFEgNYAggKDAoFBAECAAESA1gJDQoMCgUEAQIAAxID
WBARCgwKBQQBAgAIEgNYEjwKDwoIBAECAAicCAASA1gTOwpSCgQEAQIBEgNbAkMaRSBPcHRp
b25hbC4gQSBodW1hbi1yZWFkYWJsZSBuYW1lIGZvciB0aGUgdG9vbCwgc3VpdGFibGUgZm9y
IGRpc3BsYXkuCgoMCgUEAQIBBRIDWwIICgwKBQQBAgEBEgNbCRUKDAoFBAECAQMSA1sYGQoM
CgUEAQIBCBIDWxpCCg8KCAQBAgEInAgAEgNbG0EKSAoEBAECAhIDXgIZGjsgQSBodW1hbi1y
ZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgdG9vbCdzIGZ1bmN0aW9uYWxpdHkuCgoMCgUE
AQICBRIDXgIICgwKBQQBAgIBEgNeCRQKDAoFBAECAgMSA14XGAqIAQoEBAECAxIDYgImGnsg
QXV0b21hdGljYWxseSBwb3B1bGF0ZWQgcmVmZXJlbmNlIHRvIE1DUCBTZXJ2ZXIuIEhlbHBm
dWwgd2hlbiBtdWx0aXBsZQogdG9vbHMgYXJlIHJlcXVlc3RlZCBhY3Jvc3MgZGlmZmVyZW50
IE1DUCBTZXJ2ZXJzLgoKDAoFBAECAwQSA2ICCgoMCgUEAQIDBRIDYgsRCgwKBQQBAgMBEgNi
EiEKDAoFBAECAwMSA2IkJQpcCgQEAQIEEgNmAioaTyBBIEpTT04gU2NoZW1hIG9iamVjdCBk
ZWZpbmluZyB0aGUgZXhwZWN0ZWQgcGFyYW1ldGVycyBmb3IgaW52b2tpbmcgdGhlCiB0b29s
LgoKDAoFBAECBAYSA2YCGAoMCgUEAQIEARIDZhklCgwKBQQBAgQDEgNmKCkKZAoEBAECBRID
agIrGlcgT3B0aW9uYWwuIEEgSlNPTiBTY2hlbWEgb2JqZWN0IGRlZmluaW5nIHRoZSBleHBl
Y3RlZCBzdHJ1Y3R1cmUgb2YgdGhlCiB0b29sJ3Mgb3V0cHV0LgoKDAoFBAECBQYSA2oCGAoM
CgUEAQIFARIDahkmCgwKBQQBAgUDEgNqKSoKwAcKBAQBAgYSA3wCKRqyByBPcHRpb25hbCBr
ZXktdmFsdWUgb2JqZWN0IHRoYXQgYWxsb3dzIGRldmVsb3BlcnMgdG8gcHJvdmlkZSBhZGRp
dGlvbmFsCiBpbmZvcm1hdGlvbiByZWdhcmRpbmcgdG9vbCBwcm9wZXJ0aWVzLCBiZWhhdmlv
ciwgYW5kIHVzYWdlIGJlc3QgcHJhY3RpY2VzLgogQW5ub3RhdGlvbnMgb3IgdGFncyB0byBm
YWNpbGl0YXRlIHNlbWFudGljIHNlYXJjaCBhY3Jvc3MgdG9vbHMgKCJzZW1hbnRpYwogdGFn
cyIpIGFyZSBub3QgaW4gdGhlIE1WUCBzY29wZS4gV2hlbiBpbXBsZW1lbnRlZCwgdGhlIGZp
cnN0IHNldCBvZgogc3VwcG9ydGVkIGFubm90YXRpb25zIHdpbGwgbGlrZWx5IGJlIHRoZSBz
dGFuZGFyZCwgcHJlZGVmaW5lZCBhbm5vdGF0aW9ucwogZnJvbSB0aGUgb3Blbi1zb3VyY2Ug
TUNQIHNwZWMuIFRoZXNlIGluY2x1ZGU6CiAgIC0gdGl0bGU6IEEgaHVtYW4tcmVhZGFibGUg
dGl0bGUgZm9yIHRoZSB0b29sLCB1c2VmdWwgZm9yIFVJIGRpc3BsYXkuCiAgIC0gcmVhZE9u
bHlIaW50OiBJZiB0cnVlLCBpbmRpY2F0ZXMgdGhlIHRvb2wgZG9lcyBub3QgbW9kaWZ5IGl0
cwogICBlbnZpcm9ubWVudC4KICAgLSBkZXN0cnVjdGl2ZUhpbnQ6IElmIHRydWUsIHRoZSB0
b29sIG1heSBwZXJmb3JtIGRlc3RydWN0aXZlIHVwZGF0ZXMKICAgKG9ubHkgbWVhbmluZ2Z1
bCB3aGVuIHJlYWRPbmx5SGludCBpcyBmYWxzZSkuCiAgIC0gaWRlbXBvdGVudEhpbnQ6IElm
IHRydWUsIGNhbGxpbmcgdGhlIHRvb2wgcmVwZWF0ZWRseSB3aXRoIHRoZSBzYW1lCiAgIGFy
Z3VtZW50cyBoYXMgbm8gYWRkaXRpb25hbCBlZmZlY3QgKG9ubHkgbWVhbmluZ2Z1bCB3aGVu
IHJlYWRPbmx5SGludCBpcwogICBmYWxzZSkuCiAgIC0gb3BlbldvcmxkSGludDogSWYgdHJ1
ZSwgdGhlIHRvb2wgbWF5IGludGVyYWN0IHdpdGggYW4gIm9wZW4gd29ybGQiIG9mCiAgIGV4
dGVybmFsIGVudGl0aWVzLgoKDAoFBAECBgYSA3wCGAoMCgUEAQIGARIDfBkkCgwKBQQBAgYD
EgN8JyhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apiregistry::V1beta::Resources::McpServer ===
    # Fields for McpServer
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: urls Type: 9 ()
    # Field: capabilities Type: 11 (.google.protobuf.Struct)
    # Field: state Type: 14 (.google.cloud.apiregistry.v1beta.State)

# === Message: Google::Cloud::Apiregistry::V1beta::Resources::McpTool ===
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

Google::Cloud::Apiregistry::V1beta::Resources - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1beta/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Apiregistry::V1beta::Resources;

    my $msg = Google::Cloud::Apiregistry::V1beta::Resources::McpServer->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        urls => $urls,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apiregistry::V1beta::Resources::McpServer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1beta/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apiregistry::V1beta::Resources::McpServer

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

Type: C<Enum> (L<Google::Cloud::Apiregistry::V1beta::State>)

Output only. The state of the MCP Server.

=back

=head2 Google::Cloud::Apiregistry::V1beta::Resources::McpTool

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1beta::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
