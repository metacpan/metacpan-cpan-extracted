package Google::Cloud::Geminidataanalytics::V1beta::DataAgent;

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
    eval { require Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent };
    eval { require Google::Cloud::Geminidataanalytics::V1beta::Datasource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvZGF0YV9hZ2VudC5w
cm90bxInZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGkJn
b29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvZGF0YV9hbmFseXRpY3Nf
YWdlbnQucHJvdG8aOGdvb2dsZS9jbG91ZC9nZW1pbmlkYXRhYW5hbHl0aWNzL3YxYmV0YS9k
YXRhc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvMICglE
YXRhQWdlbnQSbwoUZGF0YV9hbmFseXRpY3NfYWdlbnQYZSABKAsyOy5nb29nbGUuY2xvdWQu
Z2VtaW5pZGF0YWFuYWx5dGljcy52MWJldGEuRGF0YUFuYWx5dGljc0FnZW50SABSEmRhdGFB
bmFseXRpY3NBZ2VudBIaCgRuYW1lGAEgASgJQgbgQQHgQQhSBG5hbWUSJgoMZGlzcGxheV9u
YW1lGAMgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAQgASgJQgPgQQFS
C2Rlc2NyaXB0aW9uElsKBmxhYmVscxgFIAMoCzI+Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRh
YW5hbHl0aWNzLnYxYmV0YS5EYXRhQWdlbnQuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEkAK
C2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgp1cGRhdGVUaW1lEkAKC2RlbGV0ZV90aW1lGAwgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpkZWxldGVUaW1lEj4KCnB1cmdlX3RpbWUYDSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXB1cmdlVGltZRJHCgdrbXNfa2V5
GA4gASgJQingQQH6QSMKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleUgBUgZr
bXNLZXmIAQESUQogYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX2VuYWJsZWQYEiABKAhCA+BB
AUgCUh1iaWdxdWVyeUFnZW50QW5hbHl0aWNzRW5hYmxlZIgBARKJAQoeYmlncXVlcnlfYWdl
bnRfYW5hbHl0aWNzX3RhYmxlGBMgASgLMj8uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFs
eXRpY3MudjFiZXRhLkJpZ1F1ZXJ5VGFibGVSZWZlcmVuY2VCA+BBAVIbYmlncXVlcnlBZ2Vu
dEFuYWx5dGljc1RhYmxlGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZh
bHVlGAIgASgJUgV2YWx1ZToCOAE6igHqQYYBCixnZW1pbmlkYXRhYW5hbHl0aWNzLmdvb2ds
ZWFwaXMuY29tL0RhdGFBZ2VudBI/cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2RhdGFBZ2VudHMve2RhdGFfYWdlbnR9KgpkYXRhQWdlbnRzMglkYXRhQWdlbnRC
BgoEdHlwZUIKCghfa21zX2tleUIjCiFfYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX2VuYWJs
ZWRCnwIKK2NvbS5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWJldGFCDkRh
dGFBZ2VudFByb3RvUAFaXWNsb3VkLmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGlj
cy9hcGl2MWJldGEvZ2VtaW5pZGF0YWFuYWx5dGljc3BiO2dlbWluaWRhdGFhbmFseXRpY3Nw
YqoCJ0dvb2dsZS5DbG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNzLlYxQmV0YcoCJ0dvb2dsZVxD
bG91ZFxHZW1pbmlEYXRhQW5hbHl0aWNzXFYxYmV0YeoCKkdvb2dsZTo6Q2xvdWQ6OkdlbWlu
aURhdGFBbmFseXRpY3M6OlYxYmV0YUrNPQoHEgUOAMIBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAMAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQATAoJCgIDAxIDFQBCCgkKAgMEEgMWACkKCAoBCBIDGABECgkKAgglEgMYAEQKCAoBCBID
GQB0CgkKAggLEgMZAHQKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAvCgkKAggIEgMb
AC8KCAoBCBIDHABECgkKAggBEgMcAEQKCAoBCBIDHQBECgkKAggpEgMdAEQKCAoBCBIDHgBD
CgkKAggtEgMeAEMKNQoCBAASBSEAwgEBGiggTWVzc2FnZSBkZXNjcmliaW5nIGEgRGF0YUFn
ZW50IG9iamVjdC4KCgoKAwQAARIDIQgRCgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBAp2
CgQEAAgAEgQsAi8DGmggVGhlIHR5cGUgb2YgdGhlIGFnZW50LiBDYW4gYmUgb25lIG9mIHRo
ZSBmb2xsb3dpbmc6CiAqIERhdGEgYW5hbHl0aWNzIGFnZW50LgogKiBEYXRhIGVuZ2luZWVy
aW5nIGFnZW50CgoMCgUEAAgAARIDLAgMCiQKBAQAAgASAy4EMhoXIERhdGEgYW5hbHl0aWNz
IGFnZW50LgoKDAoFBAACAAYSAy4EFgoMCgUEAAIAARIDLhcrCgwKBQQAAgADEgMuLjEKrwQK
BAQAAgESBD0CQAQaoAQgT3B0aW9uYWwuIElkZW50aWZpZXIuIFRoZSB1bmlxdWUgcmVzb3Vy
Y2UgbmFtZSBvZiBhIERhdGFBZ2VudC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YUFnZW50cy97ZGF0YV9hZ2VudF9pZH1gCiBge2Rh
dGFfYWdlbnR9YCBpcyB0aGUgcmVzb3VyY2UgaWQgYW5kIHNob3VsZCBiZSA2MyBjaGFyYWN0
ZXJzIG9yIGxlc3MgYW5kCiBtdXN0IG1hdGNoIHRoZSBmb3JtYXQgZGVzY3JpYmVkIGluCiBo
dHRwczovL2dvb2dsZS5haXAuZGV2LzEyMiNyZXNvdXJjZS1pZC1zZWdtZW50cwoKIEV4YW1w
bGU6IGBwcm9qZWN0cy8xMjM0NTY3ODkwL2xvY2F0aW9ucy9nbG9iYWwvZGF0YUFnZW50cy9t
eS1hZ2VudGAuCgogSXQgaXMgcmVjb21tZW5kZWQgdG8gc2tpcCBzZXR0aW5nIHRoaXMgZmll
bGQgZHVyaW5nIGFnZW50IGNyZWF0aW9uIGFzIGl0CiB3aWxsIGJlIGluZmVycmVkIGF1dG9t
YXRpY2FsbHkgYW5kIG92ZXJ3cml0dGVuIHdpdGggdGhlCiB7cGFyZW50fS9kYXRhQWdlbnRz
L3tkYXRhX2FnZW50X2lkfS4KCgwKBQQAAgEFEgM9AggKDAoFBAACAQESAz0JDQoMCgUEAAIB
AxIDPRARCg0KBQQAAgEIEgQ9EkADCg8KCAQAAgEInAgAEgM+BCoKDwoIBAACAQicCAESAz8E
LApaCgQEAAICEgNFAkMaTSBPcHRpb25hbC4gVXNlciBmcmllbmRseSBkaXNwbGF5IG5hbWUu
CgogKiBNdXN0IGJlIGJldHdlZW4gMS0yNTYgY2hhcmFjdGVycy4KCgwKBQQAAgIFEgNFAggK
DAoFBAACAgESA0UJFQoMCgUEAAICAxIDRRgZCgwKBQQAAgIIEgNFGkIKDwoIBAACAgicCAAS
A0UbQQpZCgQEAAIDEgNKAkIaTCBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2YgdGhlIGFnZW50
LgoKICogTXVzdCBiZSBiZXR3ZWVuIDEtMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAwUSA0oC
CAoMCgUEAAIDARIDSgkUCgwKBQQAAgMDEgNKFxgKDAoFBAACAwgSA0oZQQoPCggEAAIDCJwI
ABIDShpACrwCCgQEAAIEEgNSAkoargIgT3B0aW9uYWwuIExhYmVscyB0byBoZWxwIHVzZXJz
IGZpbHRlciByZWxhdGVkIGFnZW50cy4KIEZvciBleGFtcGxlLCAic2FsZXMiLCAiYnVzaW5l
c3MiLCAiZXRsIiwgYW5kIHNvIG9uLgogTm90ZSBsYWJlbHMgYXJlIHVzZWQgb25seSBmb3Ig
ZmlsdGVyaW5nIGFuZCBub3QgZm9yIHBvbGljaWVzLgogU2VlIHRoZSBbbGFiZWxzCiBkb2N1
bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3VyY2UtbWFuYWdlci9k
b2NzL2xhYmVscy1vdmVydmlldykKIGZvciBtb3JlIGRldGFpbHMgb24gbGFiZWwgdXNhZ2Uu
CgoMCgUEAAIEBhIDUgIVCgwKBQQAAgQBEgNSFhwKDAoFBAACBAMSA1IfIAoMCgUEAAIECBID
UiFJCg8KCAQAAgQInAgAEgNSIkgKRgoEBAACBRIEVQJWMho4IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB3aGVuIHRoZSBkYXRhIGFnZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACBQYSA1UCGwoM
CgUEAAIFARIDVRwnCgwKBQQAAgUDEgNVKisKDAoFBAACBQgSA1YGMQoPCggEAAIFCJwIABID
VgcwCksKBAQAAgYSBFkCWjIaPSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgZGF0
YSBhZ2VudCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBgYSA1kCGwoMCgUEAAIGARIDWRwn
CgwKBQQAAgYDEgNZKisKDAoFBAACBggSA1oGMQoPCggEAAIGCJwIABIDWgcwClQKBAQAAgcS
BF0CXjIaRiBPdXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBUaGUgdGltZSB0aGUgZGF0YSBh
Z2VudCB3YXMgc29mdCBkZWxldGVkLgoKDAoFBAACBwYSA10CGwoMCgUEAAIHARIDXRwnCgwK
BQQAAgcDEgNdKiwKDAoFBAACBwgSA14GMQoPCggEAAIHCJwIABIDXgcwCqoBCgQEAAIIEgRj
AmQyGpsBIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgaW4gVVRDIG9mIHdoZW4gdGhpcyBkYXRh
IGFnZW50IGlzIGNvbnNpZGVyZWQKIGV4cGlyZWQuIFRoaXMgaXMgKmFsd2F5cyogcHJvdmlk
ZWQgb24gb3V0cHV0LCByZWdhcmRsZXNzIG9mIHdoYXQgd2FzIHNlbnQKIG9uIGlucHV0LgoK
DAoFBAACCAYSA2MCGwoMCgUEAAIIARIDYxwmCgwKBQQAAggDEgNjKSsKDAoFBAACCAgSA2QG
MQoPCggEAAIICJwIABIDZAcwCoQCCgQEAAIJEgRqAm8EGvUBIE9wdGlvbmFsLiBDdXN0b21l
ciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChDTUVLKSB0byB1c2UgZm9yIGVuY3J5cHRpbmcg
dGhlCiBEYXRhQWdlbnQgcmVzb3VyY2VzLiBDbG91ZCBLTVMgQ3J5cHRvS2V5cyBtdXN0IHJl
c2lkZSBpbiB0aGUgc2FtZSBsb2NhdGlvbgogYXMgdGhlIERhdGFBZ2VudC4gVGhlIGV4cGVj
dGVkIGZvcm1hdCBpcwogYHByb2plY3RzLyovbG9jYXRpb25zLyova2V5UmluZ3MvKi9jcnlw
dG9LZXlzLypgLgoKDAoFBAACCQQSA2oCCgoMCgUEAAIJBRIDagsRCgwKBQQAAgkBEgNqEhkK
DAoFBAACCQMSA2ocHgoNCgUEAAIJCBIEah9vAwoPCggEAAIJCJwIABIDawQqCg8KBwQAAgkI
nwgSBGwEbgUKxgsKBAQAAgoSBo0BAo4BLxq1CyBPcHRpb25hbC4gQ29udHJvbHMgd2hldGhl
ciBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MgdHJhY2UgbG9nZ2luZyBpcwogZW5hYmxlZCBm
b3IgdGhlIGFnZW50LgoKIFRyYWNlIGxvZ2dpbmcgaXMgc3VwcHJlc3NlZCBmb3IgdGhlIGVu
dGlyZSB0dXJuLCB3aXRob3V0IGVycm9yLCB3aGVuIGFueQogdGFibGUgaW4gdGhlIGFnZW50
J3MgZGF0YSBzb3VyY2UgY2FycmllcyByb3ctbGV2ZWwgc2VjdXJpdHksIGNvbHVtbi1sZXZl
bAogc2VjdXJpdHksIHBvbGljeSB0YWdzLCBvciBkYXRhIG1hc2tpbmcuIEl0IGlzIGFsc28g
c3VwcHJlc3NlZCB3aGVuIHRoYXQKIGRldGVybWluYXRpb24gY2Fubm90IGJlIG1hZGUsIGZv
ciBleGFtcGxlIHdoZW4gdGhlIGNhbGxlciBsYWNrcyBwZXJtaXNzaW9uCiB0byBpbnNwZWN0
IGEgdGFibGUncyBzZWN1cml0eSBwb2xpY2llcy4KCiBUcmFjZSByb3dzIGFyZSB3cml0dGVu
IG9ubHkgd2hlbiB0aGlzIGlzIGB0cnVlYCBhbmQKIGBiaWdxdWVyeV9hZ2VudF9hbmFseXRp
Y3NfdGFibGVgIGlzIHNldC4gT24gYSBCaWdRdWVyeSBhZ2VudCwgZW5hYmxpbmcKIHRoaXMg
d2l0aG91dCBhIHRhYmxlIGhhcyBubyBlZmZlY3Q6IG5vIHRhYmxlIGlzIGNyZWF0ZWQgZm9y
IHRoZSBhZ2VudAogYW5kIG5vIHJvd3MgYXJlIHdyaXR0ZW4uIE9uIGFuIGFnZW50IHdob3Nl
IGRhdGEgc291cmNlIGlzIG5vdCBCaWdRdWVyeSwKIGBDcmVhdGVEYXRhQWdlbnRgIGFuZCBg
VXBkYXRlRGF0YUFnZW50YCByZWplY3Qgc2V0dGluZyB0aGlzIGZpZWxkIHRvCiBgdHJ1ZWAg
b3Igc2V0dGluZyBgYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxlYCB3aXRoCiBgSU5W
QUxJRF9BUkdVTUVOVGAuIFNlZSBgYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxlYCBm
b3Igd2hlbiB0aGlzCiBpcyBjaGVja2VkLgoKIFRoaXMgc2V0dGluZyBpcyBpbmRlcGVuZGVu
dCBvZiB0aGUgcHJvamVjdC1sZXZlbCBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MKIHNldHRp
bmcgY29uZmlndXJlZCB0aHJvdWdoIGBzZXRBZ2VudE9wc09ic2VydmFiaWxpdHlgLiBBbiBh
Z2VudCBkb2VzIG5vdAogaW5oZXJpdCB0aGF0IHNldHRpbmcuCgogT24gcmVhZCwgdGhpcyBm
aWVsZCByZWZsZWN0cyB0aGUgc2V0dGluZyB0aGF0IGFwcGxpZXMgdG8gY29udmVyc2F0aW9u
cwogc2VydmVkIGZyb20gYHB1Ymxpc2hlZF9jb250ZXh0YCwgb3IgZnJvbSBgc3RhZ2luZ19j
b250ZXh0YCB3aGlsZSB0aGUgYWdlbnQKIGlzIHVucHVibGlzaGVkLiBBbiB1cGRhdGUgdGhh
dCBjaGFuZ2VzIHRoaXMgZmllbGQgb3IKIGBiaWdxdWVyeV9hZ2VudF9hbmFseXRpY3NfdGFi
bGVgIGFwcGxpZXMgYm90aCBmaWVsZHMgdG8gY29udmVyc2F0aW9ucwogc2VydmVkIGZyb20g
YHN0YWdpbmdfY29udGV4dGAgYW5kLCBvbmNlIHRoZSBhZ2VudCBoYXMgYmVlbiBwdWJsaXNo
ZWQsIGZyb20KIGBwdWJsaXNoZWRfY29udGV4dGAuCgoNCgUEAAIKBBIEjQECCgoNCgUEAAIK
BRIEjQELDwoNCgUEAAIKARIEjQEQMAoNCgUEAAIKAxIEjQEzNQoNCgUEAAIKCBIEjgEGLgoQ
CggEAAIKCJwIABIEjgEHLQr7FAoEBAACCxIGwAECwQEvGuoUIE9wdGlvbmFsLiBUaGUgQmln
UXVlcnkgdGFibGUgdGhhdCBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MgdHJhY2Ugcm93cyBh
cmUKIHdyaXR0ZW4gdG8uIEhhcyBubyBlZmZlY3QgdW5sZXNzIGBiaWdxdWVyeV9hZ2VudF9h
bmFseXRpY3NfZW5hYmxlZGAgaXMKIGB0cnVlYC4KCiBUaGUgdHJhY2UgdGFibGUgaXMgdmFs
aWRhdGVkIHdoZW4gaXQgaXMgc2V0IG9uIGBDcmVhdGVEYXRhQWdlbnRgLCBhbmQgb24KIGBV
cGRhdGVEYXRhQWdlbnRgIGFzIGRlc2NyaWJlZCBiZWxvdy4gQSBjYWxsIHRvIGBVcGRhdGVE
YXRhQWdlbnRgIHdyaXRlcyBhCiBmaWVsZCBpZiB0aGUgZmllbGQgaXMgaW4gYHVwZGF0ZV9t
YXNrYCBvciwgd2hlbiBgdXBkYXRlX21hc2tgIGlzIG9taXR0ZWQsCiBpZiB0aGUgZmllbGQg
aXMgcHJlc2VudCBpbiB0aGUgcmVxdWVzdCwgZXZlbiBpZiBpdHMgdmFsdWUgaXMgdW5jaGFu
Z2VkLgogVGhlIGZvbGxvd2luZyBhcmUgcmVqZWN0ZWQgd2l0aCBgSU5WQUxJRF9BUkdVTUVO
VGA6CgogKiBUaGUgdGFibGUgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUgcHJvamVjdCBhcyB0
aGUgYWdlbnQuCiAqIFRoZSBhZ2VudCdzIGRhdGEgc291cmNlIG11c3QgYmUgQmlnUXVlcnku
IEJpZ1F1ZXJ5IEFnZW50IEFuYWx5dGljcyBpcyBub3QKIHN1cHBvcnRlZCBmb3IgTG9va2Vy
LCBMb29rZXIgU3R1ZGlvIG9yIEFsbG95REIgYWdlbnRzLgoKIE9uIGBVcGRhdGVEYXRhQWdl
bnRgLCB0aGUgdGFibGUncyBwcm9qZWN0IGlzIGNoZWNrZWQgd2hlbmV2ZXIgdGhlIGNhbGwK
IHdyaXRlcyBhIHRhYmxlIHRvIHRoaXMgZmllbGQsIG9yIHR1cm5zIGBiaWdxdWVyeV9hZ2Vu
dF9hbmFseXRpY3NfZW5hYmxlZGAKIG9uIG92ZXIgYSBzdG9yZWQgdGFibGUuIEFuIHVwZGF0
ZSB0aGF0IG9ubHkgY2xlYXJzIHRoaXMgZmllbGQgaXMgbm90CiBjaGVja2VkLgoKIE9uIGBD
cmVhdGVEYXRhQWdlbnRgLCB0aGUgZGF0YSBzb3VyY2UgaXMgdmFsaWRhdGVkIGFnYWluc3Qg
dGhlIGFnZW50IGluCiB0aGUgcmVxdWVzdC4gT24gYFVwZGF0ZURhdGFBZ2VudGAsIGl0IGlz
IHZhbGlkYXRlZCBhZ2FpbnN0IHRoZSBzdG9yZWQKIGFnZW50IGFmdGVyIGFwcGx5aW5nIHRo
ZSB1cGRhdGUgd2hlbmV2ZXIgdGhlIHVwZGF0ZSBjaGFuZ2VzIHRoZQogZGF0YSBzb3VyY2Ug
b2YgYHN0YWdpbmdfY29udGV4dGAgb3IgYHB1Ymxpc2hlZF9jb250ZXh0YCwgdHVybnMKIGBi
aWdxdWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAgb24sIG9yIHNldHMgYSBkaWZmZXJl
bnQgdGFibGUgaW4gdGhpcwogZmllbGQuIEZvciBleGFtcGxlLCBzd2l0Y2hpbmcgYW4gYWdl
bnQgdGhhdCB0dXJucyBsb2dnaW5nIG9uIG9yIG5hbWVzIGEKIHRyYWNlIHRhYmxlIHRvIGEg
bm9uLUJpZ1F1ZXJ5IGRhdGEgc291cmNlIGlzIHJlamVjdGVkLCB1bmxlc3MgdGhlIHNhbWUK
IHVwZGF0ZSB0dXJucyBsb2dnaW5nIG9mZiBhbmQgY2xlYXJzIHRoaXMgZmllbGQuIEFuIHVu
cmVsYXRlZCBlZGl0LAogaW5jbHVkaW5nIGEgY2FsbCB0byBgVXBkYXRlRGF0YUFnZW50YCB3
aXRob3V0IGB1cGRhdGVfbWFza2AgdGhhdCBjYXJyaWVzIGFuCiB1bmNoYW5nZWQgYGJpZ3F1
ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkID0gdHJ1ZWAgb3IgdGhlIHN0b3JlZCB0YWJs
ZSwKIGlzIG5vdCByZWplY3RlZCwgYW5kIG5laXRoZXIgaXMgYW4gdXBkYXRlIHRoYXQgb25s
eSB0dXJucwogYGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkYCBvZmYgb3IgY2xl
YXJzIHRoaXMgZmllbGQuIEEgY29udGV4dAogdGhhdCBjYXJyaWVzIG5vIGRhdGEgc291cmNl
IGlzIG5vdCB2YWxpZGF0ZWQuCgogVGhlIGRlc3RpbmF0aW9uIGRhdGFzZXQgbXVzdCBhbHJl
YWR5IGV4aXN0IGFuZCBtdXN0IGdyYW50IHdyaXRlIGFjY2VzcyB0bwogdGhlIHByb2plY3Qn
cyBHZW1pbmkgRGF0YSBBbmFseXRpY3Mgc2VydmljZSBhZ2VudCwgd2hvc2UgYWRkcmVzcyBp
cwogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJAZ2NwLXNhLWdlbWluaWRhdGFhbmFseXRpY3Mu
aWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gCiAodGhhdCBncmFudCBpcyBub3QgcGVyZm9ybWVk
IG9uIHlvdXIgYmVoYWxmKS4gV2l0aG91dCBpdCB0aGUgYWdlbnQgYW5zd2Vycwogbm9ybWFs
bHkgYW5kIG5vIHRyYWNlIHJvd3MgYXJlIHdyaXR0ZW4uCgogQ2hhbmdpbmcgdGhlIHRhYmxl
IG9uIGFuIGV4aXN0aW5nIGFnZW50IGFmZmVjdHMgc3Vic2VxdWVudCB0dXJucyBvbmx5LiBS
b3dzCiBhbHJlYWR5IHdyaXR0ZW4gdG8gdGhlIHByZXZpb3VzIHRhYmxlIGFyZSBsZWZ0IGlu
IHBsYWNlLgoKIE9uIHJlYWQsIHRoaXMgZmllbGQgcmVmbGVjdHMgdGhlIHRhYmxlIHRoYXQg
YXBwbGllcyB0byBjb252ZXJzYXRpb25zCiBzZXJ2ZWQgZnJvbSBgcHVibGlzaGVkX2NvbnRl
eHRgLCBvciBmcm9tIGBzdGFnaW5nX2NvbnRleHRgIHdoaWxlIHRoZSBhZ2VudAogaXMgdW5w
dWJsaXNoZWQuIEFuIHVwZGF0ZSB0aGF0IGNoYW5nZXMgdGhpcyBmaWVsZCBvcgogYGJpZ3F1
ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkYCBhcHBsaWVzIGJvdGggZmllbGRzIHRvIGNv
bnZlcnNhdGlvbnMKIHNlcnZlZCBmcm9tIGBzdGFnaW5nX2NvbnRleHRgIGFuZCwgb25jZSB0
aGUgYWdlbnQgaGFzIGJlZW4gcHVibGlzaGVkLCBmcm9tCiBgcHVibGlzaGVkX2NvbnRleHRg
LgoKDQoFBAACCwYSBMABAhgKDQoFBAACCwESBMABGTcKDQoFBAACCwMSBMABOjwKDQoFBAAC
CwgSBMEBBi4KEAoIBAACCwicCAASBMEBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent ===
    # Fields for DataAgent
    # Field: data_analytics_agent Type: 11 (.google.cloud.geminidataanalytics.v1beta.DataAnalyticsAgent)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1beta.DataAgent.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)
    # Field: kms_key Type: 9 ()
    # Field: bigquery_agent_analytics_enabled Type: 8 ()
    # Field: bigquery_agent_analytics_table Type: 11 (.google.cloud.geminidataanalytics.v1beta.BigQueryTableReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::DataAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/data_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::DataAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent->new({
        data_analytics_agent => $data_analytics_agent,
        name => $name,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->data_analytics_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/data_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent

Message describing a DataAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_analytics_agent() >> / C<< $msg->data_analytics_agent($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::DataAnalyticsAgent>)

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

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent::LabelsEntry>)

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

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReference>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::DataAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
