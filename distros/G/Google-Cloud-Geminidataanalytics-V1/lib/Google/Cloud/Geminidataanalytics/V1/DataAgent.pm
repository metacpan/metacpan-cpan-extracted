package Google::Cloud::Geminidataanalytics::V1::DataAgent;

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
    eval { require Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent };
    eval { require Google::Cloud::Geminidataanalytics::V1::Datasource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MS9kYXRhX2FnZW50LnByb3Rv
EiNnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo+Z29vZ2xlL2Ns
b3VkL2dlbWluaWRhdGFhbmFseXRpY3MvdjEvZGF0YV9hbmFseXRpY3NfYWdlbnQucHJvdG8a
NGdvb2dsZS9jbG91ZC9nZW1pbmlkYXRhYW5hbHl0aWNzL3YxL2RhdGFzb3VyY2UucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i5wgKCURhdGFBZ2VudBJrChRkYXRh
X2FuYWx5dGljc19hZ2VudBhlIAEoCzI3Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0
aWNzLnYxLkRhdGFBbmFseXRpY3NBZ2VudEgAUhJkYXRhQW5hbHl0aWNzQWdlbnQSGgoEbmFt
ZRgBIAEoCUIG4EEB4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgDIAEoCUID4EEBUgtkaXNw
bGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgEIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJXCgZsYWJl
bHMYBSADKAsyOi5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5EYXRhQWdl
bnQuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1l
GAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkAK
C2RlbGV0ZV90aW1lGAwgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpk
ZWxldGVUaW1lEj4KCnB1cmdlX3RpbWUYDSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCXB1cmdlVGltZRJHCgdrbXNfa2V5GA4gASgJQingQQH6QSMKIWNsb3Vka21z
Lmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleUgBUgZrbXNLZXmIAQESUQogYmlncXVlcnlfYWdl
bnRfYW5hbHl0aWNzX2VuYWJsZWQYEiABKAhCA+BBAUgCUh1iaWdxdWVyeUFnZW50QW5hbHl0
aWNzRW5hYmxlZIgBARKFAQoeYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxlGBMgASgL
MjsuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuQmlnUXVlcnlUYWJsZVJl
ZmVyZW5jZUID4EEBUhtiaWdxdWVyeUFnZW50QW5hbHl0aWNzVGFibGUaOQoLTGFiZWxzRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATqKAepBhgEK
LGdlbWluaWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vRGF0YUFnZW50Ej9wcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YUFnZW50cy97ZGF0YV9hZ2Vu
dH0qCmRhdGFBZ2VudHMyCWRhdGFBZ2VudEIGCgR0eXBlQgoKCF9rbXNfa2V5QiMKIV9iaWdx
dWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZEKLAgonY29tLmdvb2dsZS5jbG91ZC5nZW1p
bmlkYXRhYW5hbHl0aWNzLnYxQg5EYXRhQWdlbnRQcm90b1ABWlljbG91ZC5nb29nbGUuY29t
L2dvL2dlbWluaWRhdGFhbmFseXRpY3MvYXBpdjEvZ2VtaW5pZGF0YWFuYWx5dGljc3BiO2dl
bWluaWRhdGFhbmFseXRpY3NwYqoCI0dvb2dsZS5DbG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNz
LlYxygIjR29vZ2xlXENsb3VkXEdlbWluaURhdGFBbmFseXRpY3NcVjHqAiZHb29nbGU6OkNs
b3VkOjpHZW1pbmlEYXRhQW5hbHl0aWNzOjpWMUrNPQoHEgUOAMIBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQASAoJCgIDAxIDFQA+CgkKAgMEEgMWACkKCAoBCBIDGABACgkKAgglEgMYAEAK
CAoBCBIDGQBwCgkKAggLEgMZAHAKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAvCgkK
AggIEgMbAC8KCAoBCBIDHABACgkKAggBEgMcAEAKCAoBCBIDHQBACgkKAggpEgMdAEAKCAoB
CBIDHgA/CgkKAggtEgMeAD8KNQoCBAASBSEAwgEBGiggTWVzc2FnZSBkZXNjcmliaW5nIGEg
RGF0YUFnZW50IG9iamVjdC4KCgoKAwQAARIDIQgRCgsKAwQABxIEIgInBAoNCgUEAAedCBIE
IgInBAp2CgQEAAgAEgQsAi8DGmggVGhlIHR5cGUgb2YgdGhlIGFnZW50LiBDYW4gYmUgb25l
IG9mIHRoZSBmb2xsb3dpbmc6CiAqIERhdGEgYW5hbHl0aWNzIGFnZW50LgogKiBEYXRhIGVu
Z2luZWVyaW5nIGFnZW50CgoMCgUEAAgAARIDLAgMCiQKBAQAAgASAy4EMhoXIERhdGEgYW5h
bHl0aWNzIGFnZW50LgoKDAoFBAACAAYSAy4EFgoMCgUEAAIAARIDLhcrCgwKBQQAAgADEgMu
LjEKrwQKBAQAAgESBD0CQAQaoAQgT3B0aW9uYWwuIElkZW50aWZpZXIuIFRoZSB1bmlxdWUg
cmVzb3VyY2UgbmFtZSBvZiBhIERhdGFBZ2VudC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YUFnZW50cy97ZGF0YV9hZ2VudF9pZH1g
CiBge2RhdGFfYWdlbnR9YCBpcyB0aGUgcmVzb3VyY2UgaWQgYW5kIHNob3VsZCBiZSA2MyBj
aGFyYWN0ZXJzIG9yIGxlc3MgYW5kCiBtdXN0IG1hdGNoIHRoZSBmb3JtYXQgZGVzY3JpYmVk
IGluCiBodHRwczovL2dvb2dsZS5haXAuZGV2LzEyMiNyZXNvdXJjZS1pZC1zZWdtZW50cwoK
IEV4YW1wbGU6IGBwcm9qZWN0cy8xMjM0NTY3ODkwL2xvY2F0aW9ucy9nbG9iYWwvZGF0YUFn
ZW50cy9teS1hZ2VudGAuCgogSXQgaXMgcmVjb21tZW5kZWQgdG8gc2tpcCBzZXR0aW5nIHRo
aXMgZmllbGQgZHVyaW5nIGFnZW50IGNyZWF0aW9uIGFzIGl0CiB3aWxsIGJlIGluZmVycmVk
IGF1dG9tYXRpY2FsbHkgYW5kIG92ZXJ3cml0dGVuIHdpdGggdGhlCiB7cGFyZW50fS9kYXRh
QWdlbnRzL3tkYXRhX2FnZW50X2lkfS4KCgwKBQQAAgEFEgM9AggKDAoFBAACAQESAz0JDQoM
CgUEAAIBAxIDPRARCg0KBQQAAgEIEgQ9EkADCg8KCAQAAgEInAgAEgM+BCoKDwoIBAACAQic
CAESAz8ELApaCgQEAAICEgNFAkMaTSBPcHRpb25hbC4gVXNlciBmcmllbmRseSBkaXNwbGF5
IG5hbWUuCgogKiBNdXN0IGJlIGJldHdlZW4gMS0yNTYgY2hhcmFjdGVycy4KCgwKBQQAAgIF
EgNFAggKDAoFBAACAgESA0UJFQoMCgUEAAICAxIDRRgZCgwKBQQAAgIIEgNFGkIKDwoIBAAC
AgicCAASA0UbQQpZCgQEAAIDEgNKAkIaTCBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2YgdGhl
IGFnZW50LgoKICogTXVzdCBiZSBiZXR3ZWVuIDEtMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAAC
AwUSA0oCCAoMCgUEAAIDARIDSgkUCgwKBQQAAgMDEgNKFxgKDAoFBAACAwgSA0oZQQoPCggE
AAIDCJwIABIDShpACrwCCgQEAAIEEgNSAkoargIgT3B0aW9uYWwuIExhYmVscyB0byBoZWxw
IHVzZXJzIGZpbHRlciByZWxhdGVkIGFnZW50cy4KIEZvciBleGFtcGxlLCAic2FsZXMiLCAi
YnVzaW5lc3MiLCAiZXRsIiwgYW5kIHNvIG9uLgogTm90ZSBsYWJlbHMgYXJlIHVzZWQgb25s
eSBmb3IgZmlsdGVyaW5nIGFuZCBub3QgZm9yIHBvbGljaWVzLgogU2VlIHRoZSBbbGFiZWxz
CiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3VyY2UtbWFu
YWdlci9kb2NzL2xhYmVscy1vdmVydmlldykKIGZvciBtb3JlIGRldGFpbHMgb24gbGFiZWwg
dXNhZ2UuCgoMCgUEAAIEBhIDUgIVCgwKBQQAAgQBEgNSFhwKDAoFBAACBAMSA1IfIAoMCgUE
AAIECBIDUiFJCg8KCAQAAgQInAgAEgNSIkgKRgoEBAACBRIEVQJWMho4IE91dHB1dCBvbmx5
LiBUaGUgdGltZSB3aGVuIHRoZSBkYXRhIGFnZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACBQYS
A1UCGwoMCgUEAAIFARIDVRwnCgwKBQQAAgUDEgNVKisKDAoFBAACBQgSA1YGMQoPCggEAAIF
CJwIABIDVgcwCksKBAQAAgYSBFkCWjIaPSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0
aGUgZGF0YSBhZ2VudCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBgYSA1kCGwoMCgUEAAIG
ARIDWRwnCgwKBQQAAgYDEgNZKisKDAoFBAACBggSA1oGMQoPCggEAAIGCJwIABIDWgcwClQK
BAQAAgcSBF0CXjIaRiBPdXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBUaGUgdGltZSB0aGUg
ZGF0YSBhZ2VudCB3YXMgc29mdCBkZWxldGVkLgoKDAoFBAACBwYSA10CGwoMCgUEAAIHARID
XRwnCgwKBQQAAgcDEgNdKiwKDAoFBAACBwgSA14GMQoPCggEAAIHCJwIABIDXgcwCqoBCgQE
AAIIEgRjAmQyGpsBIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgaW4gVVRDIG9mIHdoZW4gdGhp
cyBkYXRhIGFnZW50IGlzIGNvbnNpZGVyZWQKIGV4cGlyZWQuIFRoaXMgaXMgKmFsd2F5cyog
cHJvdmlkZWQgb24gb3V0cHV0LCByZWdhcmRsZXNzIG9mIHdoYXQgd2FzIHNlbnQKIG9uIGlu
cHV0LgoKDAoFBAACCAYSA2MCGwoMCgUEAAIIARIDYxwmCgwKBQQAAggDEgNjKSsKDAoFBAAC
CAgSA2QGMQoPCggEAAIICJwIABIDZAcwCoQCCgQEAAIJEgRqAm8EGvUBIE9wdGlvbmFsLiBD
dXN0b21lciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChDTUVLKSB0byB1c2UgZm9yIGVuY3J5
cHRpbmcgdGhlCiBEYXRhQWdlbnQgcmVzb3VyY2VzLiBDbG91ZCBLTVMgQ3J5cHRvS2V5cyBt
dXN0IHJlc2lkZSBpbiB0aGUgc2FtZSBsb2NhdGlvbgogYXMgdGhlIERhdGFBZ2VudC4gVGhl
IGV4cGVjdGVkIGZvcm1hdCBpcwogYHByb2plY3RzLyovbG9jYXRpb25zLyova2V5UmluZ3Mv
Ki9jcnlwdG9LZXlzLypgLgoKDAoFBAACCQQSA2oCCgoMCgUEAAIJBRIDagsRCgwKBQQAAgkB
EgNqEhkKDAoFBAACCQMSA2ocHgoNCgUEAAIJCBIEah9vAwoPCggEAAIJCJwIABIDawQqCg8K
BwQAAgkInwgSBGwEbgUKxgsKBAQAAgoSBo0BAo4BLxq1CyBPcHRpb25hbC4gQ29udHJvbHMg
d2hldGhlciBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MgdHJhY2UgbG9nZ2luZyBpcwogZW5h
YmxlZCBmb3IgdGhlIGFnZW50LgoKIFRyYWNlIGxvZ2dpbmcgaXMgc3VwcHJlc3NlZCBmb3Ig
dGhlIGVudGlyZSB0dXJuLCB3aXRob3V0IGVycm9yLCB3aGVuIGFueQogdGFibGUgaW4gdGhl
IGFnZW50J3MgZGF0YSBzb3VyY2UgY2FycmllcyByb3ctbGV2ZWwgc2VjdXJpdHksIGNvbHVt
bi1sZXZlbAogc2VjdXJpdHksIHBvbGljeSB0YWdzLCBvciBkYXRhIG1hc2tpbmcuIEl0IGlz
IGFsc28gc3VwcHJlc3NlZCB3aGVuIHRoYXQKIGRldGVybWluYXRpb24gY2Fubm90IGJlIG1h
ZGUsIGZvciBleGFtcGxlIHdoZW4gdGhlIGNhbGxlciBsYWNrcyBwZXJtaXNzaW9uCiB0byBp
bnNwZWN0IGEgdGFibGUncyBzZWN1cml0eSBwb2xpY2llcy4KCiBUcmFjZSByb3dzIGFyZSB3
cml0dGVuIG9ubHkgd2hlbiB0aGlzIGlzIGB0cnVlYCBhbmQKIGBiaWdxdWVyeV9hZ2VudF9h
bmFseXRpY3NfdGFibGVgIGlzIHNldC4gT24gYSBCaWdRdWVyeSBhZ2VudCwgZW5hYmxpbmcK
IHRoaXMgd2l0aG91dCBhIHRhYmxlIGhhcyBubyBlZmZlY3Q6IG5vIHRhYmxlIGlzIGNyZWF0
ZWQgZm9yIHRoZSBhZ2VudAogYW5kIG5vIHJvd3MgYXJlIHdyaXR0ZW4uIE9uIGFuIGFnZW50
IHdob3NlIGRhdGEgc291cmNlIGlzIG5vdCBCaWdRdWVyeSwKIGBDcmVhdGVEYXRhQWdlbnRg
IGFuZCBgVXBkYXRlRGF0YUFnZW50YCByZWplY3Qgc2V0dGluZyB0aGlzIGZpZWxkIHRvCiBg
dHJ1ZWAgb3Igc2V0dGluZyBgYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxlYCB3aXRo
CiBgSU5WQUxJRF9BUkdVTUVOVGAuIFNlZSBgYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3Rh
YmxlYCBmb3Igd2hlbiB0aGlzCiBpcyBjaGVja2VkLgoKIFRoaXMgc2V0dGluZyBpcyBpbmRl
cGVuZGVudCBvZiB0aGUgcHJvamVjdC1sZXZlbCBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MK
IHNldHRpbmcgY29uZmlndXJlZCB0aHJvdWdoIGBzZXRBZ2VudE9wc09ic2VydmFiaWxpdHlg
LiBBbiBhZ2VudCBkb2VzIG5vdAogaW5oZXJpdCB0aGF0IHNldHRpbmcuCgogT24gcmVhZCwg
dGhpcyBmaWVsZCByZWZsZWN0cyB0aGUgc2V0dGluZyB0aGF0IGFwcGxpZXMgdG8gY29udmVy
c2F0aW9ucwogc2VydmVkIGZyb20gYHB1Ymxpc2hlZF9jb250ZXh0YCwgb3IgZnJvbSBgc3Rh
Z2luZ19jb250ZXh0YCB3aGlsZSB0aGUgYWdlbnQKIGlzIHVucHVibGlzaGVkLiBBbiB1cGRh
dGUgdGhhdCBjaGFuZ2VzIHRoaXMgZmllbGQgb3IKIGBiaWdxdWVyeV9hZ2VudF9hbmFseXRp
Y3NfdGFibGVgIGFwcGxpZXMgYm90aCBmaWVsZHMgdG8gY29udmVyc2F0aW9ucwogc2VydmVk
IGZyb20gYHN0YWdpbmdfY29udGV4dGAgYW5kLCBvbmNlIHRoZSBhZ2VudCBoYXMgYmVlbiBw
dWJsaXNoZWQsIGZyb20KIGBwdWJsaXNoZWRfY29udGV4dGAuCgoNCgUEAAIKBBIEjQECCgoN
CgUEAAIKBRIEjQELDwoNCgUEAAIKARIEjQEQMAoNCgUEAAIKAxIEjQEzNQoNCgUEAAIKCBIE
jgEGLgoQCggEAAIKCJwIABIEjgEHLQr7FAoEBAACCxIGwAECwQEvGuoUIE9wdGlvbmFsLiBU
aGUgQmlnUXVlcnkgdGFibGUgdGhhdCBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MgdHJhY2Ug
cm93cyBhcmUKIHdyaXR0ZW4gdG8uIEhhcyBubyBlZmZlY3QgdW5sZXNzIGBiaWdxdWVyeV9h
Z2VudF9hbmFseXRpY3NfZW5hYmxlZGAgaXMKIGB0cnVlYC4KCiBUaGUgdHJhY2UgdGFibGUg
aXMgdmFsaWRhdGVkIHdoZW4gaXQgaXMgc2V0IG9uIGBDcmVhdGVEYXRhQWdlbnRgLCBhbmQg
b24KIGBVcGRhdGVEYXRhQWdlbnRgIGFzIGRlc2NyaWJlZCBiZWxvdy4gQSBjYWxsIHRvIGBV
cGRhdGVEYXRhQWdlbnRgIHdyaXRlcyBhCiBmaWVsZCBpZiB0aGUgZmllbGQgaXMgaW4gYHVw
ZGF0ZV9tYXNrYCBvciwgd2hlbiBgdXBkYXRlX21hc2tgIGlzIG9taXR0ZWQsCiBpZiB0aGUg
ZmllbGQgaXMgcHJlc2VudCBpbiB0aGUgcmVxdWVzdCwgZXZlbiBpZiBpdHMgdmFsdWUgaXMg
dW5jaGFuZ2VkLgogVGhlIGZvbGxvd2luZyBhcmUgcmVqZWN0ZWQgd2l0aCBgSU5WQUxJRF9B
UkdVTUVOVGA6CgogKiBUaGUgdGFibGUgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUgcHJvamVj
dCBhcyB0aGUgYWdlbnQuCiAqIFRoZSBhZ2VudCdzIGRhdGEgc291cmNlIG11c3QgYmUgQmln
UXVlcnkuIEJpZ1F1ZXJ5IEFnZW50IEFuYWx5dGljcyBpcyBub3QKIHN1cHBvcnRlZCBmb3Ig
TG9va2VyLCBMb29rZXIgU3R1ZGlvIG9yIEFsbG95REIgYWdlbnRzLgoKIE9uIGBVcGRhdGVE
YXRhQWdlbnRgLCB0aGUgdGFibGUncyBwcm9qZWN0IGlzIGNoZWNrZWQgd2hlbmV2ZXIgdGhl
IGNhbGwKIHdyaXRlcyBhIHRhYmxlIHRvIHRoaXMgZmllbGQsIG9yIHR1cm5zIGBiaWdxdWVy
eV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAKIG9uIG92ZXIgYSBzdG9yZWQgdGFibGUuIEFu
IHVwZGF0ZSB0aGF0IG9ubHkgY2xlYXJzIHRoaXMgZmllbGQgaXMgbm90CiBjaGVja2VkLgoK
IE9uIGBDcmVhdGVEYXRhQWdlbnRgLCB0aGUgZGF0YSBzb3VyY2UgaXMgdmFsaWRhdGVkIGFn
YWluc3QgdGhlIGFnZW50IGluCiB0aGUgcmVxdWVzdC4gT24gYFVwZGF0ZURhdGFBZ2VudGAs
IGl0IGlzIHZhbGlkYXRlZCBhZ2FpbnN0IHRoZSBzdG9yZWQKIGFnZW50IGFmdGVyIGFwcGx5
aW5nIHRoZSB1cGRhdGUgd2hlbmV2ZXIgdGhlIHVwZGF0ZSBjaGFuZ2VzIHRoZQogZGF0YSBz
b3VyY2Ugb2YgYHN0YWdpbmdfY29udGV4dGAgb3IgYHB1Ymxpc2hlZF9jb250ZXh0YCwgdHVy
bnMKIGBiaWdxdWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAgb24sIG9yIHNldHMgYSBk
aWZmZXJlbnQgdGFibGUgaW4gdGhpcwogZmllbGQuIEZvciBleGFtcGxlLCBzd2l0Y2hpbmcg
YW4gYWdlbnQgdGhhdCB0dXJucyBsb2dnaW5nIG9uIG9yIG5hbWVzIGEKIHRyYWNlIHRhYmxl
IHRvIGEgbm9uLUJpZ1F1ZXJ5IGRhdGEgc291cmNlIGlzIHJlamVjdGVkLCB1bmxlc3MgdGhl
IHNhbWUKIHVwZGF0ZSB0dXJucyBsb2dnaW5nIG9mZiBhbmQgY2xlYXJzIHRoaXMgZmllbGQu
IEFuIHVucmVsYXRlZCBlZGl0LAogaW5jbHVkaW5nIGEgY2FsbCB0byBgVXBkYXRlRGF0YUFn
ZW50YCB3aXRob3V0IGB1cGRhdGVfbWFza2AgdGhhdCBjYXJyaWVzIGFuCiB1bmNoYW5nZWQg
YGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkID0gdHJ1ZWAgb3IgdGhlIHN0b3Jl
ZCB0YWJsZSwKIGlzIG5vdCByZWplY3RlZCwgYW5kIG5laXRoZXIgaXMgYW4gdXBkYXRlIHRo
YXQgb25seSB0dXJucwogYGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkYCBvZmYg
b3IgY2xlYXJzIHRoaXMgZmllbGQuIEEgY29udGV4dAogdGhhdCBjYXJyaWVzIG5vIGRhdGEg
c291cmNlIGlzIG5vdCB2YWxpZGF0ZWQuCgogVGhlIGRlc3RpbmF0aW9uIGRhdGFzZXQgbXVz
dCBhbHJlYWR5IGV4aXN0IGFuZCBtdXN0IGdyYW50IHdyaXRlIGFjY2VzcyB0bwogdGhlIHBy
b2plY3QncyBHZW1pbmkgRGF0YSBBbmFseXRpY3Mgc2VydmljZSBhZ2VudCwgd2hvc2UgYWRk
cmVzcyBpcwogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJAZ2NwLXNhLWdlbWluaWRhdGFhbmFs
eXRpY3MuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gCiAodGhhdCBncmFudCBpcyBub3QgcGVy
Zm9ybWVkIG9uIHlvdXIgYmVoYWxmKS4gV2l0aG91dCBpdCB0aGUgYWdlbnQgYW5zd2Vycwog
bm9ybWFsbHkgYW5kIG5vIHRyYWNlIHJvd3MgYXJlIHdyaXR0ZW4uCgogQ2hhbmdpbmcgdGhl
IHRhYmxlIG9uIGFuIGV4aXN0aW5nIGFnZW50IGFmZmVjdHMgc3Vic2VxdWVudCB0dXJucyBv
bmx5LiBSb3dzCiBhbHJlYWR5IHdyaXR0ZW4gdG8gdGhlIHByZXZpb3VzIHRhYmxlIGFyZSBs
ZWZ0IGluIHBsYWNlLgoKIE9uIHJlYWQsIHRoaXMgZmllbGQgcmVmbGVjdHMgdGhlIHRhYmxl
IHRoYXQgYXBwbGllcyB0byBjb252ZXJzYXRpb25zCiBzZXJ2ZWQgZnJvbSBgcHVibGlzaGVk
X2NvbnRleHRgLCBvciBmcm9tIGBzdGFnaW5nX2NvbnRleHRgIHdoaWxlIHRoZSBhZ2VudAog
aXMgdW5wdWJsaXNoZWQuIEFuIHVwZGF0ZSB0aGF0IGNoYW5nZXMgdGhpcyBmaWVsZCBvcgog
YGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkYCBhcHBsaWVzIGJvdGggZmllbGRz
IHRvIGNvbnZlcnNhdGlvbnMKIHNlcnZlZCBmcm9tIGBzdGFnaW5nX2NvbnRleHRgIGFuZCwg
b25jZSB0aGUgYWdlbnQgaGFzIGJlZW4gcHVibGlzaGVkLCBmcm9tCiBgcHVibGlzaGVkX2Nv
bnRleHRgLgoKDQoFBAACCwYSBMABAhgKDQoFBAACCwESBMABGTcKDQoFBAACCwMSBMABOjwK
DQoFBAACCwgSBMEBBi4KEAoIBAACCwicCAASBMEBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1::DataAgent::DataAgent ===
    # Fields for DataAgent
    # Field: data_analytics_agent Type: 11 (.google.cloud.geminidataanalytics.v1.DataAnalyticsAgent)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1.DataAgent.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)
    # Field: kms_key Type: 9 ()
    # Field: bigquery_agent_analytics_enabled Type: 8 ()
    # Field: bigquery_agent_analytics_table Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryTableReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::DataAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1/data_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1::DataAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1::DataAgent::DataAgent->new({
        data_analytics_agent => $data_analytics_agent,
        name => $name,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->data_analytics_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1::DataAgent::DataAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1/data_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1::DataAgent::DataAgent

Message describing a DataAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_analytics_agent() >> / C<< $msg->data_analytics_agent($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::DataAnalyticsAgent>)

Data analytics agent.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Identifier. The unique resource name of a DataAgent.
Format:
`projects/{project}/locations/{location}/dataAgents/{data_agent_id}`
`{data_agent}` is the resource id and should be 63 characters or less and
must match the format described in
https://google.aip.dev/122#resource-id-segments

Example: `projects/1234567890/locations/global/dataAgents/my-agent`.

It is recommended to skip setting this field during agent creation as it
will be inferred automatically and overwritten with the
{parent}/dataAgents/{data_agent_id}.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User friendly display name.

* Must be between 1-256 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the agent.

* Must be between 1-1024 characters.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::DataAgent::DataAgent::LabelsEntry>)

Optional. Labels to help users filter related agents.
For example, "sales", "business", "etl", and so on.
Note labels are used only for filtering and not for policies.
See the [labels
documentation](https://cloud.google.com/resource-manager/docs/labels-overview)
for more details on label usage.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the data agent was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the data agent was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] The time the data agent was soft deleted.

=item * C<< $msg->purge_time() >> / C<< $msg->purge_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp in UTC of when this data agent is considered
expired. This is *always* provided on output, regardless of what was sent
on input.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Customer managed encryption key (CMEK) to use for encrypting the
DataAgent resources. Cloud KMS CryptoKeys must reside in the same location
as the DataAgent. The expected format is
`projects/*/locations/*/keyRings/*/cryptoKeys/*`.

=item * C<< $msg->bigquery_agent_analytics_enabled() >> / C<< $msg->bigquery_agent_analytics_enabled($value) >>

Type: C<Bool>

Optional. Controls whether BigQuery Agent Analytics trace logging is
enabled for the agent.

Trace logging is suppressed for the entire turn, without error, when any
table in the agent's data source carries row-level security, column-level
security, policy tags, or data masking. It is also suppressed when that
determination cannot be made, for example when the caller lacks permission
to inspect a table's security policies.

Trace rows are written only when this is `true` and
`bigquery_agent_analytics_table` is set. On a BigQuery agent, enabling
this without a table has no effect: no table is created for the agent
and no rows are written. On an agent whose data source is not BigQuery,
`CreateDataAgent` and `UpdateDataAgent` reject setting this field to
`true` or setting `bigquery_agent_analytics_table` with
`INVALID_ARGUMENT`. See `bigquery_agent_analytics_table` for when this
is checked.

This setting is independent of the project-level BigQuery Agent Analytics
setting configured through `setAgentOpsObservability`. An agent does not
inherit that setting.

On read, this field reflects the setting that applies to conversations
served from `published_context`, or from `staging_context` while the agent
is unpublished. An update that changes this field or
`bigquery_agent_analytics_table` applies both fields to conversations
served from `staging_context` and, once the agent has been published, from
`published_context`.

=item * C<< $msg->bigquery_agent_analytics_table() >> / C<< $msg->bigquery_agent_analytics_table($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference>)

Optional. The BigQuery table that BigQuery Agent Analytics trace rows are
written to. Has no effect unless `bigquery_agent_analytics_enabled` is
`true`.

The trace table is validated when it is set on `CreateDataAgent`, and on
`UpdateDataAgent` as described below. A call to `UpdateDataAgent` writes a
field if the field is in `update_mask` or, when `update_mask` is omitted,
if the field is present in the request, even if its value is unchanged.
The following are rejected with `INVALID_ARGUMENT`:

* The table must belong to the same project as the agent.
* The agent's data source must be BigQuery. BigQuery Agent Analytics is not
supported for Looker, Looker Studio or AlloyDB agents.

On `UpdateDataAgent`, the table's project is checked whenever the call
writes a table to this field, or turns `bigquery_agent_analytics_enabled`
on over a stored table. An update that only clears this field is not
checked.

On `CreateDataAgent`, the data source is validated against the agent in
the request. On `UpdateDataAgent`, it is validated against the stored
agent after applying the update whenever the update changes the
data source of `staging_context` or `published_context`, turns
`bigquery_agent_analytics_enabled` on, or sets a different table in this
field. For example, switching an agent that turns logging on or names a
trace table to a non-BigQuery data source is rejected, unless the same
update turns logging off and clears this field. An unrelated edit,
including a call to `UpdateDataAgent` without `update_mask` that carries an
unchanged `bigquery_agent_analytics_enabled = true` or the stored table,
is not rejected, and neither is an update that only turns
`bigquery_agent_analytics_enabled` off or clears this field. A context
that carries no data source is not validated.

The destination dataset must already exist and must grant write access to
the project's Gemini Data Analytics service agent, whose address is
`service-PROJECT_NUMBER@gcp-sa-geminidataanalytics.iam.gserviceaccount.com`
(that grant is not performed on your behalf). Without it the agent answers
normally and no trace rows are written.

Changing the table on an existing agent affects subsequent turns only. Rows
already written to the previous table are left in place.

On read, this field reflects the table that applies to conversations
served from `published_context`, or from `staging_context` while the agent
is unpublished. An update that changes this field or
`bigquery_agent_analytics_enabled` applies both fields to conversations
served from `staging_context` and, once the agent has been published, from
`published_context`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1::DataAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
