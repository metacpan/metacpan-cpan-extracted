package Google::Cloud::Geminidataanalytics::V1alpha::DataAgent;

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
    eval { require Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent };
    eval { require Google::Cloud::Geminidataanalytics::V1alpha::Datasource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2RhdGFfYWdlbnQu
cHJvdG8SKGdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
Q2dvb2dsZS9jbG91ZC9nZW1pbmlkYXRhYW5hbHl0aWNzL3YxYWxwaGEvZGF0YV9hbmFseXRp
Y3NfYWdlbnQucHJvdG8aOWdvb2dsZS9jbG91ZC9nZW1pbmlkYXRhYW5hbHl0aWNzL3YxYWxw
aGEvZGF0YXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL2
CAoJRGF0YUFnZW50EnAKFGRhdGFfYW5hbHl0aWNzX2FnZW50GGUgASgLMjwuZ29vZ2xlLmNs
b3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYS5EYXRhQW5hbHl0aWNzQWdlbnRIAFIS
ZGF0YUFuYWx5dGljc0FnZW50EhoKBG5hbWUYASABKAlCBuBBAeBBCFIEbmFtZRImCgxkaXNw
bGF5X25hbWUYAyABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YBCABKAlC
A+BBAVILZGVzY3JpcHRpb24SXAoGbGFiZWxzGAUgAygLMj8uZ29vZ2xlLmNsb3VkLmdlbWlu
aWRhdGFhbmFseXRpY3MudjFhbHBoYS5EYXRhQWdlbnQuTGFiZWxzRW50cnlCA+BBAVIGbGFi
ZWxzEkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkAKC2RlbGV0ZV90aW1lGAwgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpkZWxldGVUaW1lEj4KCnB1cmdlX3RpbWUY
DSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXB1cmdlVGltZRJHCgdr
bXNfa2V5GA4gASgJQingQQH6QSMKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tl
eUgBUgZrbXNLZXmIAQESUQogYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX2VuYWJsZWQYEiAB
KAhCA+BBAUgCUh1iaWdxdWVyeUFnZW50QW5hbHl0aWNzRW5hYmxlZIgBARKKAQoeYmlncXVl
cnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxlGBMgASgLMkAuZ29vZ2xlLmNsb3VkLmdlbWluaWRh
dGFhbmFseXRpY3MudjFhbHBoYS5CaWdRdWVyeVRhYmxlUmVmZXJlbmNlQgPgQQFSG2JpZ3F1
ZXJ5QWdlbnRBbmFseXRpY3NUYWJsZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOooB6kGGAQosZ2VtaW5pZGF0YWFuYWx5dGlj
cy5nb29nbGVhcGlzLmNvbS9EYXRhQWdlbnQSP3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9kYXRhQWdlbnRzL3tkYXRhX2FnZW50fSoKZGF0YUFnZW50czIJZGF0
YUFnZW50QgYKBHR5cGVCCgoIX2ttc19rZXlCIwohX2JpZ3F1ZXJ5X2FnZW50X2FuYWx5dGlj
c19lbmFibGVkQqQCCixjb20uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFh
bHBoYUIORGF0YUFnZW50UHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9nZW1pbmlkYXRh
YW5hbHl0aWNzL2FwaXYxYWxwaGEvZ2VtaW5pZGF0YWFuYWx5dGljc3BiO2dlbWluaWRhdGFh
bmFseXRpY3NwYqoCKEdvb2dsZS5DbG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNzLlYxQWxwaGHK
AihHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMWFscGhh6gIrR29vZ2xlOjpD
bG91ZDo6R2VtaW5pRGF0YUFuYWx5dGljczo6VjFhbHBoYUrNPQoHEgUOAMIBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQATQoJCgIDAxIDFQBDCgkKAgMEEgMWACkKCAoBCBIDGABFCgkKAggl
EgMYAEUKCAoBCBIDGQB1CgkKAggLEgMZAHUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBID
GwAvCgkKAggIEgMbAC8KCAoBCBIDHABFCgkKAggBEgMcAEUKCAoBCBIDHQBFCgkKAggpEgMd
AEUKCAoBCBIDHgBECgkKAggtEgMeAEQKNQoCBAASBSEAwgEBGiggTWVzc2FnZSBkZXNjcmli
aW5nIGEgRGF0YUFnZW50IG9iamVjdC4KCgoKAwQAARIDIQgRCgsKAwQABxIEIgInBAoNCgUE
AAedCBIEIgInBAp2CgQEAAgAEgQsAi8DGmggVGhlIHR5cGUgb2YgdGhlIGFnZW50LiBDYW4g
YmUgb25lIG9mIHRoZSBmb2xsb3dpbmc6CiAqIERhdGEgYW5hbHl0aWNzIGFnZW50LgogKiBE
YXRhIGVuZ2luZWVyaW5nIGFnZW50CgoMCgUEAAgAARIDLAgMCiQKBAQAAgASAy4EMhoXIERh
dGEgYW5hbHl0aWNzIGFnZW50LgoKDAoFBAACAAYSAy4EFgoMCgUEAAIAARIDLhcrCgwKBQQA
AgADEgMuLjEKrwQKBAQAAgESBD0CQAQaoAQgT3B0aW9uYWwuIElkZW50aWZpZXIuIFRoZSB1
bmlxdWUgcmVzb3VyY2UgbmFtZSBvZiBhIERhdGFBZ2VudC4KIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YUFnZW50cy97ZGF0YV9hZ2Vu
dF9pZH1gCiBge2RhdGFfYWdlbnR9YCBpcyB0aGUgcmVzb3VyY2UgaWQgYW5kIHNob3VsZCBi
ZSA2MyBjaGFyYWN0ZXJzIG9yIGxlc3MgYW5kCiBtdXN0IG1hdGNoIHRoZSBmb3JtYXQgZGVz
Y3JpYmVkIGluCiBodHRwczovL2dvb2dsZS5haXAuZGV2LzEyMiNyZXNvdXJjZS1pZC1zZWdt
ZW50cwoKIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjM0NTY3ODkwL2xvY2F0aW9ucy9nbG9iYWwv
ZGF0YUFnZW50cy9teS1hZ2VudGAuCgogSXQgaXMgcmVjb21tZW5kZWQgdG8gc2tpcCBzZXR0
aW5nIHRoaXMgZmllbGQgZHVyaW5nIGFnZW50IGNyZWF0aW9uIGFzIGl0CiB3aWxsIGJlIGlu
ZmVycmVkIGF1dG9tYXRpY2FsbHkgYW5kIG92ZXJ3cml0dGVuIHdpdGggdGhlCiB7cGFyZW50
fS9kYXRhQWdlbnRzL3tkYXRhX2FnZW50X2lkfS4KCgwKBQQAAgEFEgM9AggKDAoFBAACAQES
Az0JDQoMCgUEAAIBAxIDPRARCg0KBQQAAgEIEgQ9EkADCg8KCAQAAgEInAgAEgM+BCoKDwoI
BAACAQicCAESAz8ELApaCgQEAAICEgNFAkMaTSBPcHRpb25hbC4gVXNlciBmcmllbmRseSBk
aXNwbGF5IG5hbWUuCgogKiBNdXN0IGJlIGJldHdlZW4gMS0yNTYgY2hhcmFjdGVycy4KCgwK
BQQAAgIFEgNFAggKDAoFBAACAgESA0UJFQoMCgUEAAICAxIDRRgZCgwKBQQAAgIIEgNFGkIK
DwoIBAACAgicCAASA0UbQQpZCgQEAAIDEgNKAkIaTCBPcHRpb25hbC4gRGVzY3JpcHRpb24g
b2YgdGhlIGFnZW50LgoKICogTXVzdCBiZSBiZXR3ZWVuIDEtMTAyNCBjaGFyYWN0ZXJzLgoK
DAoFBAACAwUSA0oCCAoMCgUEAAIDARIDSgkUCgwKBQQAAgMDEgNKFxgKDAoFBAACAwgSA0oZ
QQoPCggEAAIDCJwIABIDShpACrwCCgQEAAIEEgNSAkoargIgT3B0aW9uYWwuIExhYmVscyB0
byBoZWxwIHVzZXJzIGZpbHRlciByZWxhdGVkIGFnZW50cy4KIEZvciBleGFtcGxlLCAic2Fs
ZXMiLCAiYnVzaW5lc3MiLCAiZXRsIiwgYW5kIHNvIG9uLgogTm90ZSBsYWJlbHMgYXJlIHVz
ZWQgb25seSBmb3IgZmlsdGVyaW5nIGFuZCBub3QgZm9yIHBvbGljaWVzLgogU2VlIHRoZSBb
bGFiZWxzCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3Vy
Y2UtbWFuYWdlci9kb2NzL2xhYmVscy1vdmVydmlldykKIGZvciBtb3JlIGRldGFpbHMgb24g
bGFiZWwgdXNhZ2UuCgoMCgUEAAIEBhIDUgIVCgwKBQQAAgQBEgNSFhwKDAoFBAACBAMSA1If
IAoMCgUEAAIECBIDUiFJCg8KCAQAAgQInAgAEgNSIkgKRgoEBAACBRIEVQJWMho4IE91dHB1
dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBkYXRhIGFnZW50IHdhcyBjcmVhdGVkLgoKDAoF
BAACBQYSA1UCGwoMCgUEAAIFARIDVRwnCgwKBQQAAgUDEgNVKisKDAoFBAACBQgSA1YGMQoP
CggEAAIFCJwIABIDVgcwCksKBAQAAgYSBFkCWjIaPSBPdXRwdXQgb25seS4gVGhlIHRpbWUg
d2hlbiB0aGUgZGF0YSBhZ2VudCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBgYSA1kCGwoM
CgUEAAIGARIDWRwnCgwKBQQAAgYDEgNZKisKDAoFBAACBggSA1oGMQoPCggEAAIGCJwIABID
WgcwClQKBAQAAgcSBF0CXjIaRiBPdXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBUaGUgdGlt
ZSB0aGUgZGF0YSBhZ2VudCB3YXMgc29mdCBkZWxldGVkLgoKDAoFBAACBwYSA10CGwoMCgUE
AAIHARIDXRwnCgwKBQQAAgcDEgNdKiwKDAoFBAACBwgSA14GMQoPCggEAAIHCJwIABIDXgcw
CqoBCgQEAAIIEgRjAmQyGpsBIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgaW4gVVRDIG9mIHdo
ZW4gdGhpcyBkYXRhIGFnZW50IGlzIGNvbnNpZGVyZWQKIGV4cGlyZWQuIFRoaXMgaXMgKmFs
d2F5cyogcHJvdmlkZWQgb24gb3V0cHV0LCByZWdhcmRsZXNzIG9mIHdoYXQgd2FzIHNlbnQK
IG9uIGlucHV0LgoKDAoFBAACCAYSA2MCGwoMCgUEAAIIARIDYxwmCgwKBQQAAggDEgNjKSsK
DAoFBAACCAgSA2QGMQoPCggEAAIICJwIABIDZAcwCoQCCgQEAAIJEgRqAm8EGvUBIE9wdGlv
bmFsLiBDdXN0b21lciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChDTUVLKSB0byB1c2UgZm9y
IGVuY3J5cHRpbmcgdGhlCiBEYXRhQWdlbnQgcmVzb3VyY2VzLiBDbG91ZCBLTVMgQ3J5cHRv
S2V5cyBtdXN0IHJlc2lkZSBpbiB0aGUgc2FtZSBsb2NhdGlvbgogYXMgdGhlIERhdGFBZ2Vu
dC4gVGhlIGV4cGVjdGVkIGZvcm1hdCBpcwogYHByb2plY3RzLyovbG9jYXRpb25zLyova2V5
UmluZ3MvKi9jcnlwdG9LZXlzLypgLgoKDAoFBAACCQQSA2oCCgoMCgUEAAIJBRIDagsRCgwK
BQQAAgkBEgNqEhkKDAoFBAACCQMSA2ocHgoNCgUEAAIJCBIEah9vAwoPCggEAAIJCJwIABID
awQqCg8KBwQAAgkInwgSBGwEbgUKxgsKBAQAAgoSBo0BAo4BLxq1CyBPcHRpb25hbC4gQ29u
dHJvbHMgd2hldGhlciBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3MgdHJhY2UgbG9nZ2luZyBp
cwogZW5hYmxlZCBmb3IgdGhlIGFnZW50LgoKIFRyYWNlIGxvZ2dpbmcgaXMgc3VwcHJlc3Nl
ZCBmb3IgdGhlIGVudGlyZSB0dXJuLCB3aXRob3V0IGVycm9yLCB3aGVuIGFueQogdGFibGUg
aW4gdGhlIGFnZW50J3MgZGF0YSBzb3VyY2UgY2FycmllcyByb3ctbGV2ZWwgc2VjdXJpdHks
IGNvbHVtbi1sZXZlbAogc2VjdXJpdHksIHBvbGljeSB0YWdzLCBvciBkYXRhIG1hc2tpbmcu
IEl0IGlzIGFsc28gc3VwcHJlc3NlZCB3aGVuIHRoYXQKIGRldGVybWluYXRpb24gY2Fubm90
IGJlIG1hZGUsIGZvciBleGFtcGxlIHdoZW4gdGhlIGNhbGxlciBsYWNrcyBwZXJtaXNzaW9u
CiB0byBpbnNwZWN0IGEgdGFibGUncyBzZWN1cml0eSBwb2xpY2llcy4KCiBUcmFjZSByb3dz
IGFyZSB3cml0dGVuIG9ubHkgd2hlbiB0aGlzIGlzIGB0cnVlYCBhbmQKIGBiaWdxdWVyeV9h
Z2VudF9hbmFseXRpY3NfdGFibGVgIGlzIHNldC4gT24gYSBCaWdRdWVyeSBhZ2VudCwgZW5h
YmxpbmcKIHRoaXMgd2l0aG91dCBhIHRhYmxlIGhhcyBubyBlZmZlY3Q6IG5vIHRhYmxlIGlz
IGNyZWF0ZWQgZm9yIHRoZSBhZ2VudAogYW5kIG5vIHJvd3MgYXJlIHdyaXR0ZW4uIE9uIGFu
IGFnZW50IHdob3NlIGRhdGEgc291cmNlIGlzIG5vdCBCaWdRdWVyeSwKIGBDcmVhdGVEYXRh
QWdlbnRgIGFuZCBgVXBkYXRlRGF0YUFnZW50YCByZWplY3Qgc2V0dGluZyB0aGlzIGZpZWxk
IHRvCiBgdHJ1ZWAgb3Igc2V0dGluZyBgYmlncXVlcnlfYWdlbnRfYW5hbHl0aWNzX3RhYmxl
YCB3aXRoCiBgSU5WQUxJRF9BUkdVTUVOVGAuIFNlZSBgYmlncXVlcnlfYWdlbnRfYW5hbHl0
aWNzX3RhYmxlYCBmb3Igd2hlbiB0aGlzCiBpcyBjaGVja2VkLgoKIFRoaXMgc2V0dGluZyBp
cyBpbmRlcGVuZGVudCBvZiB0aGUgcHJvamVjdC1sZXZlbCBCaWdRdWVyeSBBZ2VudCBBbmFs
eXRpY3MKIHNldHRpbmcgY29uZmlndXJlZCB0aHJvdWdoIGBzZXRBZ2VudE9wc09ic2VydmFi
aWxpdHlgLiBBbiBhZ2VudCBkb2VzIG5vdAogaW5oZXJpdCB0aGF0IHNldHRpbmcuCgogT24g
cmVhZCwgdGhpcyBmaWVsZCByZWZsZWN0cyB0aGUgc2V0dGluZyB0aGF0IGFwcGxpZXMgdG8g
Y29udmVyc2F0aW9ucwogc2VydmVkIGZyb20gYHB1Ymxpc2hlZF9jb250ZXh0YCwgb3IgZnJv
bSBgc3RhZ2luZ19jb250ZXh0YCB3aGlsZSB0aGUgYWdlbnQKIGlzIHVucHVibGlzaGVkLiBB
biB1cGRhdGUgdGhhdCBjaGFuZ2VzIHRoaXMgZmllbGQgb3IKIGBiaWdxdWVyeV9hZ2VudF9h
bmFseXRpY3NfdGFibGVgIGFwcGxpZXMgYm90aCBmaWVsZHMgdG8gY29udmVyc2F0aW9ucwog
c2VydmVkIGZyb20gYHN0YWdpbmdfY29udGV4dGAgYW5kLCBvbmNlIHRoZSBhZ2VudCBoYXMg
YmVlbiBwdWJsaXNoZWQsIGZyb20KIGBwdWJsaXNoZWRfY29udGV4dGAuCgoNCgUEAAIKBBIE
jQECCgoNCgUEAAIKBRIEjQELDwoNCgUEAAIKARIEjQEQMAoNCgUEAAIKAxIEjQEzNQoNCgUE
AAIKCBIEjgEGLgoQCggEAAIKCJwIABIEjgEHLQr7FAoEBAACCxIGwAECwQEvGuoUIE9wdGlv
bmFsLiBUaGUgQmlnUXVlcnkgdGFibGUgdGhhdCBCaWdRdWVyeSBBZ2VudCBBbmFseXRpY3Mg
dHJhY2Ugcm93cyBhcmUKIHdyaXR0ZW4gdG8uIEhhcyBubyBlZmZlY3QgdW5sZXNzIGBiaWdx
dWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAgaXMKIGB0cnVlYC4KCiBUaGUgdHJhY2Ug
dGFibGUgaXMgdmFsaWRhdGVkIHdoZW4gaXQgaXMgc2V0IG9uIGBDcmVhdGVEYXRhQWdlbnRg
LCBhbmQgb24KIGBVcGRhdGVEYXRhQWdlbnRgIGFzIGRlc2NyaWJlZCBiZWxvdy4gQSBjYWxs
IHRvIGBVcGRhdGVEYXRhQWdlbnRgIHdyaXRlcyBhCiBmaWVsZCBpZiB0aGUgZmllbGQgaXMg
aW4gYHVwZGF0ZV9tYXNrYCBvciwgd2hlbiBgdXBkYXRlX21hc2tgIGlzIG9taXR0ZWQsCiBp
ZiB0aGUgZmllbGQgaXMgcHJlc2VudCBpbiB0aGUgcmVxdWVzdCwgZXZlbiBpZiBpdHMgdmFs
dWUgaXMgdW5jaGFuZ2VkLgogVGhlIGZvbGxvd2luZyBhcmUgcmVqZWN0ZWQgd2l0aCBgSU5W
QUxJRF9BUkdVTUVOVGA6CgogKiBUaGUgdGFibGUgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUg
cHJvamVjdCBhcyB0aGUgYWdlbnQuCiAqIFRoZSBhZ2VudCdzIGRhdGEgc291cmNlIG11c3Qg
YmUgQmlnUXVlcnkuIEJpZ1F1ZXJ5IEFnZW50IEFuYWx5dGljcyBpcyBub3QKIHN1cHBvcnRl
ZCBmb3IgTG9va2VyLCBMb29rZXIgU3R1ZGlvIG9yIEFsbG95REIgYWdlbnRzLgoKIE9uIGBV
cGRhdGVEYXRhQWdlbnRgLCB0aGUgdGFibGUncyBwcm9qZWN0IGlzIGNoZWNrZWQgd2hlbmV2
ZXIgdGhlIGNhbGwKIHdyaXRlcyBhIHRhYmxlIHRvIHRoaXMgZmllbGQsIG9yIHR1cm5zIGBi
aWdxdWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAKIG9uIG92ZXIgYSBzdG9yZWQgdGFi
bGUuIEFuIHVwZGF0ZSB0aGF0IG9ubHkgY2xlYXJzIHRoaXMgZmllbGQgaXMgbm90CiBjaGVj
a2VkLgoKIE9uIGBDcmVhdGVEYXRhQWdlbnRgLCB0aGUgZGF0YSBzb3VyY2UgaXMgdmFsaWRh
dGVkIGFnYWluc3QgdGhlIGFnZW50IGluCiB0aGUgcmVxdWVzdC4gT24gYFVwZGF0ZURhdGFB
Z2VudGAsIGl0IGlzIHZhbGlkYXRlZCBhZ2FpbnN0IHRoZSBzdG9yZWQKIGFnZW50IGFmdGVy
IGFwcGx5aW5nIHRoZSB1cGRhdGUgd2hlbmV2ZXIgdGhlIHVwZGF0ZSBjaGFuZ2VzIHRoZQog
ZGF0YSBzb3VyY2Ugb2YgYHN0YWdpbmdfY29udGV4dGAgb3IgYHB1Ymxpc2hlZF9jb250ZXh0
YCwgdHVybnMKIGBiaWdxdWVyeV9hZ2VudF9hbmFseXRpY3NfZW5hYmxlZGAgb24sIG9yIHNl
dHMgYSBkaWZmZXJlbnQgdGFibGUgaW4gdGhpcwogZmllbGQuIEZvciBleGFtcGxlLCBzd2l0
Y2hpbmcgYW4gYWdlbnQgdGhhdCB0dXJucyBsb2dnaW5nIG9uIG9yIG5hbWVzIGEKIHRyYWNl
IHRhYmxlIHRvIGEgbm9uLUJpZ1F1ZXJ5IGRhdGEgc291cmNlIGlzIHJlamVjdGVkLCB1bmxl
c3MgdGhlIHNhbWUKIHVwZGF0ZSB0dXJucyBsb2dnaW5nIG9mZiBhbmQgY2xlYXJzIHRoaXMg
ZmllbGQuIEFuIHVucmVsYXRlZCBlZGl0LAogaW5jbHVkaW5nIGEgY2FsbCB0byBgVXBkYXRl
RGF0YUFnZW50YCB3aXRob3V0IGB1cGRhdGVfbWFza2AgdGhhdCBjYXJyaWVzIGFuCiB1bmNo
YW5nZWQgYGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkID0gdHJ1ZWAgb3IgdGhl
IHN0b3JlZCB0YWJsZSwKIGlzIG5vdCByZWplY3RlZCwgYW5kIG5laXRoZXIgaXMgYW4gdXBk
YXRlIHRoYXQgb25seSB0dXJucwogYGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVk
YCBvZmYgb3IgY2xlYXJzIHRoaXMgZmllbGQuIEEgY29udGV4dAogdGhhdCBjYXJyaWVzIG5v
IGRhdGEgc291cmNlIGlzIG5vdCB2YWxpZGF0ZWQuCgogVGhlIGRlc3RpbmF0aW9uIGRhdGFz
ZXQgbXVzdCBhbHJlYWR5IGV4aXN0IGFuZCBtdXN0IGdyYW50IHdyaXRlIGFjY2VzcyB0bwog
dGhlIHByb2plY3QncyBHZW1pbmkgRGF0YSBBbmFseXRpY3Mgc2VydmljZSBhZ2VudCwgd2hv
c2UgYWRkcmVzcyBpcwogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJAZ2NwLXNhLWdlbWluaWRh
dGFhbmFseXRpY3MuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gCiAodGhhdCBncmFudCBpcyBu
b3QgcGVyZm9ybWVkIG9uIHlvdXIgYmVoYWxmKS4gV2l0aG91dCBpdCB0aGUgYWdlbnQgYW5z
d2Vycwogbm9ybWFsbHkgYW5kIG5vIHRyYWNlIHJvd3MgYXJlIHdyaXR0ZW4uCgogQ2hhbmdp
bmcgdGhlIHRhYmxlIG9uIGFuIGV4aXN0aW5nIGFnZW50IGFmZmVjdHMgc3Vic2VxdWVudCB0
dXJucyBvbmx5LiBSb3dzCiBhbHJlYWR5IHdyaXR0ZW4gdG8gdGhlIHByZXZpb3VzIHRhYmxl
IGFyZSBsZWZ0IGluIHBsYWNlLgoKIE9uIHJlYWQsIHRoaXMgZmllbGQgcmVmbGVjdHMgdGhl
IHRhYmxlIHRoYXQgYXBwbGllcyB0byBjb252ZXJzYXRpb25zCiBzZXJ2ZWQgZnJvbSBgcHVi
bGlzaGVkX2NvbnRleHRgLCBvciBmcm9tIGBzdGFnaW5nX2NvbnRleHRgIHdoaWxlIHRoZSBh
Z2VudAogaXMgdW5wdWJsaXNoZWQuIEFuIHVwZGF0ZSB0aGF0IGNoYW5nZXMgdGhpcyBmaWVs
ZCBvcgogYGJpZ3F1ZXJ5X2FnZW50X2FuYWx5dGljc19lbmFibGVkYCBhcHBsaWVzIGJvdGgg
ZmllbGRzIHRvIGNvbnZlcnNhdGlvbnMKIHNlcnZlZCBmcm9tIGBzdGFnaW5nX2NvbnRleHRg
IGFuZCwgb25jZSB0aGUgYWdlbnQgaGFzIGJlZW4gcHVibGlzaGVkLCBmcm9tCiBgcHVibGlz
aGVkX2NvbnRleHRgLgoKDQoFBAACCwYSBMABAhgKDQoFBAACCwESBMABGTcKDQoFBAACCwMS
BMABOjwKDQoFBAACCwgSBMEBBi4KEAoIBAACCwicCAASBMEBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::DataAgent ===
    # Fields for DataAgent
    # Field: data_analytics_agent Type: 11 (.google.cloud.geminidataanalytics.v1alpha.DataAnalyticsAgent)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1alpha.DataAgent.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)
    # Field: kms_key Type: 9 ()
    # Field: bigquery_agent_analytics_enabled Type: 8 ()
    # Field: bigquery_agent_analytics_table Type: 11 (.google.cloud.geminidataanalytics.v1alpha.BigQueryTableReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::DataAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/data_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::DataAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::DataAgent->new({
        data_analytics_agent => $data_analytics_agent,
        name => $name,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->data_analytics_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::DataAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/data_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::DataAgent

Message describing a DataAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_analytics_agent() >> / C<< $msg->data_analytics_agent($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent>)

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

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::DataAgent::LabelsEntry>)

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

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Datasource::BigQueryTableReference>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::DataAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
