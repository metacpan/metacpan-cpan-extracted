package Google::Cloud::Agentregistry::V1::McpServer;

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
    eval { require Google::Cloud::Agentregistry::V1::Properties };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9tY3Bfc2VydmVyLnByb3RvEh1nb29n
bGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxouZ29vZ2xlL2Nsb3VkL2FnZW50cmVn
aXN0cnkvdjEvcHJvcGVydGllcy5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKXCgoJTWNwU2VydmVyEhcKBG5h
bWUYASABKAlCA+BBCFIEbmFtZRInCg1tY3Bfc2VydmVyX2lkGAkgASgJQgPgQQNSC21jcFNl
cnZlcklkEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EEDUgtkaXNwbGF5TmFtZRIlCgtkZXNj
cmlwdGlvbhgDIAEoCUID4EEDUgtkZXNjcmlwdGlvbhJNCgppbnRlcmZhY2VzGAQgAygLMigu
Z29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuSW50ZXJmYWNlQgPgQQNSCmludGVyZmFj
ZXMSSAoFdG9vbHMYBSADKAsyLS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5NY3BT
ZXJ2ZXIuVG9vbEID4EEDUgV0b29scxJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJdCgphdHRy
aWJ1dGVzGAggAygLMjguZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuTWNwU2VydmVy
LkF0dHJpYnV0ZXNFbnRyeUID4EEDUgphdHRyaWJ1dGVzGrwDCgRUb29sEhcKBG5hbWUYASAB
KAlCA+BBA1IEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEDUgtkZXNjcmlwdGlvbhJg
Cgthbm5vdGF0aW9ucxgDIAEoCzI5Lmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLk1j
cFNlcnZlci5Ub29sLkFubm90YXRpb25zQgPgQQNSC2Fubm90YXRpb25zEjEKBG1ldGEYBCAB
KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQNSBV9tZXRhGt4BCgtBbm5vdGF0aW9u
cxIZCgV0aXRsZRgBIAEoCUID4EEDUgV0aXRsZRIuChBkZXN0cnVjdGl2ZV9oaW50GAIgASgI
QgPgQQNSD2Rlc3RydWN0aXZlSGludBIsCg9pZGVtcG90ZW50X2hpbnQYAyABKAhCA+BBA1IO
aWRlbXBvdGVudEhpbnQSKwoPb3Blbl93b3JsZF9oaW50GAQgASgIQgPgQQNSDW9wZW5Xb3Js
ZEhpbnQSKQoOcmVhZF9vbmx5X2hpbnQYBSABKAhCA+BBA1IMcmVhZE9ubHlIaW50GlYKD0F0
dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRItCgV2YWx1ZRgCIAEoCzIXLmdvb2ds
ZS5wcm90b2J1Zi5TdHJ1Y3RSBXZhbHVlOgI4ATrlAepB4QEKJmFnZW50cmVnaXN0cnkuZ29v
Z2xlYXBpcy5jb20vTWNwU2VydmVyEj9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vbWNwU2VydmVycy97bWNwX3NlcnZlcn0SX3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9haUFwcGxpY2F0aW9ucy97YWlfYXBwbGljYXRpb259L21j
cFNlcnZlcnMve21jcF9zZXJ2ZXJ9KgptY3BTZXJ2ZXJzMgltY3BTZXJ2ZXJC4QEKIWNvbS5n
b29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MUIOTWNwU2VydmVyUHJvdG9QAVpHY2xvdWQu
Z29vZ2xlLmNvbS9nby9hZ2VudHJlZ2lzdHJ5L2FwaXYxL2FnZW50cmVnaXN0cnlwYjthZ2Vu
dHJlZ2lzdHJ5cGKqAh1Hb29nbGUuQ2xvdWQuQWdlbnRSZWdpc3RyeS5WMcoCHUdvb2dsZVxD
bG91ZFxBZ2VudFJlZ2lzdHJ5XFYx6gIgR29vZ2xlOjpDbG91ZDo6QWdlbnRSZWdpc3RyeTo6
VjFK2CUKBhIEDgB9AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
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
AxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJCgIDAxIDFQAmCgkKAgME
EgMWACkKCAoBCBIDGAA6CgkKAgglEgMYADoKCAoBCBIDGQBeCgkKAggLEgMZAF4KCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwAvCgkKAggIEgMbAC8KCAoBCBIDHAA6CgkKAggBEgMc
ADoKCAoBCBIDHQA6CgkKAggpEgMdADoKCAoBCBIDHgA5CgkKAggtEgMeADkKQAoCBAASBCEA
fQEaNCBSZXByZXNlbnRzIGFuIE1DUCAoTW9kZWwgQ29udGV4dCBQcm90b2NvbCkgU2VydmVy
LgoKCgoDBAABEgMhCBEKCwoDBAAHEgQiAigECg0KBQQAB50IEgQiAigECkMKBAQAAwASBCsC
VgMaNSBSZXByZXNlbnRzIGEgc2luZ2xlIHRvb2wgcHJvdmlkZWQgYnkgYW4gTUNQIFNlcnZl
ci4KCgwKBQQAAwABEgMrCg4KYgoGBAADAAMAEgQuBEcFGlIgQW5ub3RhdGlvbnMgZGVzY3Jp
YmluZyB0aGUgY2hhcmFjdGVyaXN0aWNzIGFuZCBiZWhhdmlvciBvZiBhIHRvb2wgb3IKIG9w
ZXJhdGlvbi4KCg4KBwQAAwADAAESAy4MFwpECggEAAMAAwACABIDMAZDGjMgT3V0cHV0IG9u
bHkuIEEgaHVtYW4tcmVhZGFibGUgdGl0bGUgZm9yIHRoZSB0b29sLgoKEAoJBAADAAMAAgAF
EgMwBgwKEAoJBAADAAMAAgABEgMwDRIKEAoJBAADAAMAAgADEgMwFRYKEAoJBAADAAMAAgAI
EgMwF0IKEwoMBAADAAMAAgAInAgAEgMwGEEK8AEKCAQAAwADAAIBEgM2Bkwa3gEgT3V0cHV0
IG9ubHkuIElmIHRydWUsIHRoZSB0b29sIG1heSBwZXJmb3JtIGRlc3RydWN0aXZlIHVwZGF0
ZXMgdG8gaXRzCiBlbnZpcm9ubWVudC4gSWYgZmFsc2UsIHRoZSB0b29sIHBlcmZvcm1zIG9u
bHkgYWRkaXRpdmUgdXBkYXRlcy4gTk9URToKIFRoaXMgcHJvcGVydHkgaXMgbWVhbmluZ2Z1
bCBvbmx5IHdoZW4gYHJlYWRfb25seV9oaW50ID09IGZhbHNlYAogRGVmYXVsdDogdHJ1ZQoK
EAoJBAADAAMAAgEFEgM2BgoKEAoJBAADAAMAAgEBEgM2CxsKEAoJBAADAAMAAgEDEgM2Hh8K
EAoJBAADAAMAAgEIEgM2IEsKEwoMBAADAAMAAgEInAgAEgM2IUoK6AEKCAQAAwADAAICEgM8
Bksa1gEgT3V0cHV0IG9ubHkuIElmIHRydWUsIGNhbGxpbmcgdGhlIHRvb2wgcmVwZWF0ZWRs
eSB3aXRoIHRoZSBzYW1lCiBhcmd1bWVudHMgd2lsbCBoYXZlIG5vIGFkZGl0aW9uYWwgZWZm
ZWN0IG9uIGl0cyBlbnZpcm9ubWVudC4gTk9URTogVGhpcwogcHJvcGVydHkgaXMgbWVhbmlu
Z2Z1bCBvbmx5IHdoZW4gYHJlYWRfb25seV9oaW50ID09IGZhbHNlYCBEZWZhdWx0OgogZmFs
c2UKChAKCQQAAwADAAICBRIDPAYKChAKCQQAAwADAAICARIDPAsaChAKCQQAAwADAAICAxID
PB0eChAKCQQAAwADAAICCBIDPB9KChMKDAQAAwADAAICCJwIABIDPCBJCo0CCggEAAMAAwAC
AxIDQgZLGvsBIE91dHB1dCBvbmx5LiBJZiB0cnVlLCB0aGlzIHRvb2wgbWF5IGludGVyYWN0
IHdpdGggYW4gIm9wZW4gd29ybGQiIG9mCiBleHRlcm5hbCBlbnRpdGllcy4gSWYgZmFsc2Us
IHRoZSB0b29sJ3MgZG9tYWluIG9mIGludGVyYWN0aW9uIGlzCiBjbG9zZWQuIEZvciBleGFt
cGxlLCB0aGUgd29ybGQgb2YgYSB3ZWIgc2VhcmNoIHRvb2wgaXMgb3Blbiwgd2hlcmVhcwog
dGhhdCBvZiBhIG1lbW9yeSB0b29sIGlzIG5vdC4gRGVmYXVsdDogdHJ1ZQoKEAoJBAADAAMA
AgMFEgNCBgoKEAoJBAADAAMAAgMBEgNCCxoKEAoJBAADAAMAAgMDEgNCHR4KEAoJBAADAAMA
AgMIEgNCH0oKEwoMBAADAAMAAgMInAgAEgNCIEkKYgoIBAADAAMAAgQSA0YGShpRIE91dHB1
dCBvbmx5LiBJZiB0cnVlLCB0aGUgdG9vbCBkb2VzIG5vdCBtb2RpZnkgaXRzIGVudmlyb25t
ZW50LgogRGVmYXVsdDogZmFsc2UKChAKCQQAAwADAAIEBRIDRgYKChAKCQQAAwADAAIEARID
RgsZChAKCQQAAwADAAIEAxIDRhwdChAKCQQAAwADAAIECBIDRh5JChMKDAQAAwADAAIECJwI
ABIDRh9ICj4KBgQAAwACABIDSgRAGi8gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIG5h
bWUgb2YgdGhlIHRvb2wuCgoOCgcEAAMAAgAFEgNKBAoKDgoHBAADAAIAARIDSgsPCg4KBwQA
AwACAAMSA0oSEwoOCgcEAAMAAgAIEgNKFD8KEQoKBAADAAIACJwIABIDShU+CkAKBgQAAwAC
ARIDTQRHGjEgT3V0cHV0IG9ubHkuIERlc2NyaXB0aW9uIG9mIHdoYXQgdGhlIHRvb2wgZG9l
cy4KCg4KBwQAAwACAQUSA00ECgoOCgcEAAMAAgEBEgNNCxYKDgoHBAADAAIBAxIDTRkaCg4K
BwQAAwACAQgSA00bRgoRCgoEAAMAAgEInAgAEgNNHEUKQwoGBAADAAICEgNQBEwaNCBPdXRw
dXQgb25seS4gQW5ub3RhdGlvbnMgYXNzb2NpYXRlZCB3aXRoIHRoZSB0b29sLgoKDgoHBAAD
AAICBhIDUAQPCg4KBwQAAwACAgESA1AQGwoOCgcEAAMAAgIDEgNQHh8KDgoHBAADAAICCBID
UCBLChEKCgQAAwACAgicCAASA1AhSgpwCgYEAAMAAgMSBFQEVUkaYCBPdXRwdXQgb25seS4g
UHJvdG9jb2wtbGV2ZWwgdG9vbCBtZXRhZGF0YSBjb25mb3JtaW5nIHRvIE1DUCBfbWV0YQog
c3BlY2lmaWNhdGlvbi4gT3V0cHV0IG9ubHkuCgoOCgcEAAMAAgMGEgNUBBoKDgoHBAADAAID
ARIDVBsfCg4KBwQAAwACAwMSA1QiIwoOCgcEAAMAAgMIEgNVCEgKDgoHBAADAAIDChIDVQkc
Cg4KBwQAAwACAwoSA1UVHAoRCgoEAAMAAgMInAgAEgNVHkcKiwEKBAQAAgASA1oCPRp+IElk
ZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBNQ1AgU2VydmVyLgogRm9ybWF0
OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21jcFNlcnZlcnMv
e21jcF9zZXJ2ZXJ9YC4KCgwKBQQAAgAFEgNaAggKDAoFBAACAAESA1oJDQoMCgUEAAIAAxID
WhARCgwKBQQAAgAIEgNaEjwKDwoIBAACAAicCAASA1oTOwpRCgQEAAIBEgNdAkcaRCBPdXRw
dXQgb25seS4gQSBzdGFibGUsIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIGZvciBNQ1Ag
U2VydmVycy4KCgwKBQQAAgEFEgNdAggKDAoFBAACAQESA10JFgoMCgUEAAIBAxIDXRkaCgwK
BQQAAgEIEgNdG0YKDwoIBAACAQicCAASA10cRQo/CgQEAAICEgNgAkYaMiBPdXRwdXQgb25s
eS4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgTUNQIFNlcnZlci4KCgwKBQQAAgIFEgNgAggK
DAoFBAACAgESA2AJFQoMCgUEAAICAxIDYBgZCgwKBQQAAgIIEgNgGkUKDwoIBAACAgicCAAS
A2AbRAo+CgQEAAIDEgNjAkUaMSBPdXRwdXQgb25seS4gVGhlIGRlc2NyaXB0aW9uIG9mIHRo
ZSBNQ1AgU2VydmVyLgoKDAoFBAACAwUSA2MCCAoMCgUEAAIDARIDYwkUCgwKBQQAAgMDEgNj
FxgKDAoFBAACAwgSA2MZRAoPCggEAAIDCJwIABIDYxpDCkYKBAQAAgQSA2YCUBo5IE91dHB1
dCBvbmx5LiBUaGUgY29ubmVjdGlvbiBkZXRhaWxzIGZvciB0aGUgTUNQIFNlcnZlci4KCgwK
BQQAAgQEEgNmAgoKDAoFBAACBAYSA2YLFAoMCgUEAAIEARIDZhUfCgwKBQQAAgQDEgNmIiMK
DAoFBAACBAgSA2YkTwoPCggEAAIECJwIABIDZiVOCj0KBAQAAgUSA2kCRhowIE91dHB1dCBv
bmx5LiBUb29scyBwcm92aWRlZCBieSB0aGUgTUNQIFNlcnZlci4KCgwKBQQAAgUEEgNpAgoK
DAoFBAACBQYSA2kLDwoMCgUEAAIFARIDaRAVCgwKBQQAAgUDEgNpGBkKDAoFBAACBQgSA2ka
RQoPCggEAAIFCJwIABIDaRtECikKBAQAAgYSBGwCbTIaGyBPdXRwdXQgb25seS4gQ3JlYXRl
IHRpbWUuCgoMCgUEAAIGBhIDbAIbCgwKBQQAAgYBEgNsHCcKDAoFBAACBgMSA2wqKwoMCgUE
AAIGCBIDbQYxCg8KCAQAAgYInAgAEgNtBzAKKQoEBAACBxIEcAJxMhobIE91dHB1dCBvbmx5
LiBVcGRhdGUgdGltZS4KCgwKBQQAAgcGEgNwAhsKDAoFBAACBwESA3AcJwoMCgUEAAIHAxID
cCorCgwKBQQAAgcIEgNxBjEKDwoIBAACBwicCAASA3EHMAqPAwoEBAACCBIEewJ8MhqAAyBP
dXRwdXQgb25seS4gQXR0cmlidXRlcyBvZiB0aGUgTUNQIFNlcnZlci4KIFZhbGlkIHZhbHVl
czoKCiAgKiBgYWdlbnRyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9zeXN0ZW0vUnVudGltZUlk
ZW50aXR5YDogeyJwcmluY2lwYWwiOgogICJwcmluY2lwYWw6Ly8uLi4ifSAtIHRoZSBydW50
aW1lIGlkZW50aXR5IGFzc29jaWF0ZWQgd2l0aCB0aGUgTUNQIFNlcnZlci4KICAqIGBhZ2Vu
dHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL3N5c3RlbS9SdW50aW1lUmVmZXJlbmNlYDogeyJ1
cmkiOiAiLy8uLi4ifQogIC0gdGhlIFVSSSBvZiB0aGUgdW5kZXJseWluZyByZXNvdXJjZSBo
b3N0aW5nIHRoZSBNQ1AgU2VydmVyLCBmb3IKICBleGFtcGxlLCB0aGUgR0tFIERlcGxveW1l
bnQuCgoMCgUEAAIIBhIDewIlCgwKBQQAAggBEgN7JjAKDAoFBAACCAMSA3szNAoMCgUEAAII
CBIDfAYxCg8KCAQAAggInAgAEgN8BzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::McpServer::McpServer ===
    # Fields for McpServer
    # Field: name Type: 9 ()
    # Field: mcp_server_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: interfaces Type: 11 (.google.cloud.agentregistry.v1.Interface)
    # Field: tools Type: 11 (.google.cloud.agentregistry.v1.McpServer.Tool)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attributes Type: 11 (.google.cloud.agentregistry.v1.McpServer.AttributesEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::McpServer - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/mcp_server.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::McpServer;

    my $msg = Google::Cloud::Agentregistry::V1::McpServer::McpServer->new({
        name => $name,
        mcp_server_id => $mcp_server_id,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::McpServer::McpServer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/mcp_server.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::McpServer::McpServer

Represents an MCP (Model Context Protocol) Server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the MCP Server.
Format: `projects/{project}/locations/{location}/mcpServers/{mcp_server}`.

=item * C<< $msg->mcp_server_id() >> / C<< $msg->mcp_server_id($value) >>

Type: C<String>

Output only. A stable, globally unique identifier for MCP Servers.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the MCP Server.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the MCP Server.

=item * C<< $msg->interfaces() >> / C<< $msg->interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Properties::Interface>)

Output only. The connection details for the MCP Server.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool>)

Output only. Tools provided by the MCP Server.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::McpServer::McpServer::AttributesEntry>)

Output only. Attributes of the MCP Server.
Valid values:

 * `agentregistry.googleapis.com/system/RuntimeIdentity`: {"principal":
 "principal://..."} - the runtime identity associated with the MCP Server.
 * `agentregistry.googleapis.com/system/RuntimeReference`: {"uri": "//..."}
 - the URI of the underlying resource hosting the MCP Server, for
 example, the GKE Deployment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::McpServer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
