package Google::Cloud::Websecurityscanner::V1alpha::Finding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Websecurityscanner::V1alpha::FindingAddon };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvZmluZGluZy5wcm90
bxInZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGjtnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxw
aGEvZmluZGluZ19hZGRvbi5wcm90byKpCgoHRmluZGluZxISCgRuYW1lGAEgASgJUgRuYW1l
El8KDGZpbmRpbmdfdHlwZRgCIAEoDjI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5u
ZXIudjFhbHBoYS5GaW5kaW5nLkZpbmRpbmdUeXBlUgtmaW5kaW5nVHlwZRIfCgtodHRwX21l
dGhvZBgDIAEoCVIKaHR0cE1ldGhvZBIdCgpmdXp6ZWRfdXJsGAQgASgJUglmdXp6ZWRVcmwS
EgoEYm9keRgFIAEoCVIEYm9keRIgCgtkZXNjcmlwdGlvbhgGIAEoCVILZGVzY3JpcHRpb24S
KQoQcmVwcm9kdWN0aW9uX3VybBgHIAEoCVIPcmVwcm9kdWN0aW9uVXJsEhsKCWZyYW1lX3Vy
bBgIIAEoCVIIZnJhbWVVcmwSGwoJZmluYWxfdXJsGAkgASgJUghmaW5hbFVybBIfCgt0cmFj
a2luZ19pZBgKIAEoCVIKdHJhY2tpbmdJZBJjChBvdXRkYXRlZF9saWJyYXJ5GAsgASgLMjgu
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLk91dGRhdGVkTGlicmFy
eVIPb3V0ZGF0ZWRMaWJyYXJ5EmkKEnZpb2xhdGluZ19yZXNvdXJjZRgMIAEoCzI6Lmdvb2ds
ZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5WaW9sYXRpbmdSZXNvdXJjZVIR
dmlvbGF0aW5nUmVzb3VyY2USaQoSdnVsbmVyYWJsZV9oZWFkZXJzGA8gASgLMjouZ29vZ2xl
LmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLlZ1bG5lcmFibGVIZWFkZXJzUhF2
dWxuZXJhYmxlSGVhZGVycxJyChV2dWxuZXJhYmxlX3BhcmFtZXRlcnMYDSABKAsyPS5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuVnVsbmVyYWJsZVBhcmFtZXRl
cnNSFHZ1bG5lcmFibGVQYXJhbWV0ZXJzEj4KA3hzcxgOIAEoCzIsLmdvb2dsZS5jbG91ZC53
ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5Yc3NSA3hzcyK2AgoLRmluZGluZ1R5cGUSHAoY
RklORElOR19UWVBFX1VOU1BFQ0lGSUVEEAASEQoNTUlYRURfQ09OVEVOVBABEhQKEE9VVERB
VEVEX0xJQlJBUlkQAhIRCg1ST1NFVFRBX0ZMQVNIEAUSEAoMWFNTX0NBTExCQUNLEAMSDQoJ
WFNTX0VSUk9SEAQSFwoTQ0xFQVJfVEVYVF9QQVNTV09SRBAGEhgKFElOVkFMSURfQ09OVEVO
VF9UWVBFEAcSGAoUWFNTX0FOR1VMQVJfQ0FMTEJBQ0sQCBISCg5JTlZBTElEX0hFQURFUhAJ
EiMKH01JU1NQRUxMRURfU0VDVVJJVFlfSEVBREVSX05BTUUQChImCiJNSVNNQVRDSElOR19T
RUNVUklUWV9IRUFERVJfVkFMVUVTEAs6hAHqQYABCil3ZWJzZWN1cml0eXNjYW5uZXIuZ29v
Z2xlYXBpcy5jb20vRmluZGluZxJTcHJvamVjdHMve3Byb2plY3R9L3NjYW5Db25maWdzL3tz
Y2FuX2NvbmZpZ30vc2NhblJ1bnMve3NjYW5fcnVufS9maW5kaW5ncy97ZmluZGluZ31CmgEK
K2NvbS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGFCDEZpbmRpbmdQ
cm90b1ABWltjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MWFs
cGhhL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiSqwuCgcSBQ8A
lwEBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEAMAoJCgID
ABIDEwAjCgkKAgMBEgMUAEUKCAoBCBIDFgByCgkKAggLEgMWAHIKCAoBCBIDFwAiCgkKAggK
EgMXACIKCAoBCBIDGAAtCgkKAggIEgMYAC0KCAoBCBIDGQBECgkKAggBEgMZAEQKYwoCBAAS
BR0AlwEBGlYgQSBGaW5kaW5nIHJlc291cmNlIHJlcHJlc2VudHMgYSB2dWxuZXJhYmlsaXR5
IGluc3RhbmNlIGlkZW50aWZpZWQgZHVyaW5nIGEKIFNjYW5SdW4uCgoKCgMEAAESAx0IDwoL
CgMEAAcSBB4CIQQKDQoFBAAHnQgSBB4CIQQKIgoEBAAEABIEJAJgAxoUIFR5cGVzIG9mIEZp
bmRpbmdzLgoKDAoFBAAEAAESAyQHEgoqCgYEAAQAAgASAyYEIRobIFRoZSBpbnZhbGlkIGZp
bmRpbmcgdHlwZS4KCg4KBwQABAACAAESAyYEHAoOCgcEAAQAAgACEgMmHyAK+gEKBgQABAAC
ARIDLAQWGuoBIEEgcGFnZSB0aGF0IHdhcyBzZXJ2ZWQgb3ZlciBIVFRQUyBhbHNvIHJlc291
cmNlcyBvdmVyIEhUVFAuIEEKIG1hbi1pbi10aGUtbWlkZGxlIGF0dGFja2VyIGNvdWxkIHRh
bXBlciB3aXRoIHRoZSBIVFRQIHJlc291cmNlIGFuZCBnYWluCiBmdWxsIGFjY2VzcyB0byB0
aGUgd2Vic2l0ZSB0aGF0IGxvYWRzIHRoZSByZXNvdXJjZSBvciB0byBtb25pdG9yIHRoZQog
YWN0aW9ucyB0YWtlbiBieSB0aGUgdXNlci4KCg4KBwQABAACAQESAywEEQoOCgcEAAQAAgEC
EgMsFBUKpQIKBgQABAACAhIDMgQZGpUCIFRoZSB2ZXJzaW9uIG9mIGFuIGluY2x1ZGVkIGxp
YnJhcnkgaXMga25vd24gdG8gY29udGFpbiBhIHNlY3VyaXR5IGlzc3VlLgogVGhlIHNjYW5u
ZXIgY2hlY2tzIHRoZSB2ZXJzaW9uIG9mIGxpYnJhcnkgaW4gdXNlIGFnYWluc3QgYSBrbm93
biBsaXN0IG9mCiB2dWxuZXJhYmxlIGxpYnJhcmllcy4gRmFsc2UgcG9zaXRpdmVzIGFyZSBw
b3NzaWJsZSBpZiB0aGUgdmVyc2lvbgogZGV0ZWN0aW9uIGZhaWxzIG9yIGlmIHRoZSBsaWJy
YXJ5IGhhcyBiZWVuIG1hbnVhbGx5IHBhdGNoZWQuCgoOCgcEAAQAAgIBEgMyBBQKDgoHBAAE
AAICAhIDMhcYCooDCgYEAAQAAgMSAzoEFhr6AiBUaGlzIHR5cGUgb2YgdnVsbmVyYWJpbGl0
eSBvY2N1cnMgd2hlbiB0aGUgdmFsdWUgb2YgYSByZXF1ZXN0IHBhcmFtZXRlcgogaXMgcmVm
bGVjdGVkIGF0IHRoZSBiZWdpbm5pbmcgb2YgdGhlIHJlc3BvbnNlLCBmb3IgZXhhbXBsZSwg
aW4gcmVxdWVzdHMKIHVzaW5nIEpTT05QLiBVbmRlciBjZXJ0YWluIGNpcmN1bXN0YW5jZXMs
IGFuIGF0dGFja2VyIG1heSBiZSBhYmxlIHRvCiBzdXBwbHkgYW4gYWxwaGFudW1lcmljLW9u
bHkgRmxhc2ggZmlsZSBpbiB0aGUgdnVsbmVyYWJsZSBwYXJhbWV0ZXIKIGNhdXNpbmcgdGhl
IGJyb3dzZXIgdG8gZXhlY3V0ZSB0aGUgRmxhc2ggZmlsZSBhcyBpZiBpdCBvcmlnaW5hdGVk
IG9uIHRoZQogdnVsbmVyYWJsZSBzZXJ2ZXIuCgoOCgcEAAQAAgMBEgM6BBEKDgoHBAAEAAID
AhIDOhQVCrQBCgYEAAQAAgQSAz8EFRqkASBBIGNyb3NzLXNpdGUgc2NyaXB0aW5nIChYU1Mp
IGJ1ZyBpcyBmb3VuZCB2aWEgSmF2YVNjcmlwdCBjYWxsYmFjay4gRm9yCiBkZXRhaWxlZCBl
eHBsYW5hdGlvbnMgb24gWFNTLCBzZWUKIGh0dHBzOi8vd3d3Lmdvb2dsZS5jb20vYWJvdXQv
YXBwc2VjdXJpdHkvbGVhcm5pbmcveHNzLy4KCg4KBwQABAACBAESAz8EEAoOCgcEAAQAAgQC
EgM/ExQKhQUKBgQABAACBRIDSgQSGvUEIEEgcG90ZW50aWFsIGNyb3NzLXNpdGUgc2NyaXB0
aW5nIChYU1MpIGJ1ZyBkdWUgdG8gSmF2YVNjcmlwdCBicmVha2FnZS4KIEluIHNvbWUgY2ly
Y3Vtc3RhbmNlcywgdGhlIGFwcGxpY2F0aW9uIHVuZGVyIHRlc3QgbWlnaHQgbW9kaWZ5IHRo
ZSB0ZXN0CiBzdHJpbmcgYmVmb3JlIGl0IGlzIHBhcnNlZCBieSB0aGUgYnJvd3Nlci4gV2hl
biB0aGUgYnJvd3NlciBhdHRlbXB0cyB0bwogcnVucyB0aGlzIG1vZGlmaWVkIHRlc3Qgc3Ry
aW5nLCBpdCB3aWxsIGxpa2VseSBicmVhayBhbmQgdGhyb3cgYQogSmF2YVNjcmlwdCBleGVj
dXRpb24gZXJyb3IsIHRodXMgYW4gaW5qZWN0aW9uIGlzc3VlIGlzIG9jY3VycmluZy4KIEhv
d2V2ZXIsIGl0IG1heSBub3QgYmUgZXhwbG9pdGFibGUuIE1hbnVhbCB2ZXJpZmljYXRpb24g
aXMgbmVlZGVkIHRvIHNlZQogaWYgdGhlIHRlc3Qgc3RyaW5nIG1vZGlmaWNhdGlvbnMgY2Fu
IGJlIGV2YWRlZCBhbmQgY29uZmlybSB0aGF0IHRoZSBpc3N1ZQogaXMgaW4gZmFjdCBhbiBY
U1MgdnVsbmVyYWJpbGl0eS4gRm9yIGRldGFpbGVkIGV4cGxhbmF0aW9ucyBvbiBYU1MsIHNl
ZQogaHR0cHM6Ly93d3cuZ29vZ2xlLmNvbS9hYm91dC9hcHBzZWN1cml0eS9sZWFybmluZy94
c3MvLgoKDgoHBAAEAAIFARIDSgQNCg4KBwQABAACBQISA0oQEQqkAQoGBAAEAAIGEgNOBBwa
lAEgQW4gYXBwbGljYXRpb24gYXBwZWFycyB0byBiZSB0cmFuc21pdHRpbmcgYSBwYXNzd29y
ZCBmaWVsZCBpbiBjbGVhciB0ZXh0LgogQW4gYXR0YWNrZXIgY2FuIGVhdmVzZHJvcCBuZXR3
b3JrIHRyYWZmaWMgYW5kIHNuaWZmIHRoZSBwYXNzd29yZCBmaWVsZC4KCg4KBwQABAACBgES
A04EFwoOCgcEAAQAAgYCEgNOGhsKkQEKBgQABAACBxIDUgQdGoEBIEFuIGFwcGxpY2F0aW9u
IHJldHVybnMgc2Vuc2l0aXZlIGNvbnRlbnQgd2l0aCBhbiBpbnZhbGlkIGNvbnRlbnQgdHlw
ZSwKIG9yIHdpdGhvdXQgYW4gJ1gtQ29udGVudC1UeXBlLU9wdGlvbnM6IG5vc25pZmYnIGhl
YWRlci4KCg4KBwQABAACBwESA1IEGAoOCgcEAAQAAgcCEgNSGxwKlQEKBgQABAACCBIDVgQd
GoUBIEEgY3Jvc3Mtc2l0ZSBzY3JpcHRpbmcgKFhTUykgdnVsbmVyYWJpbGl0eSBpbiBBbmd1
bGFySlMgbW9kdWxlIHRoYXQKIG9jY3VycyB3aGVuIGEgdXNlci1wcm92aWRlZCBzdHJpbmcg
aXMgaW50ZXJwb2xhdGVkIGJ5IEFuZ3VsYXIuCgoOCgcEAAQAAggBEgNWBBgKDgoHBAAEAAII
AhIDVhscCjYKBgQABAACCRIDWQQXGicgQSBtYWxmb3JtZWQgb3IgaW52YWxpZCB2YWx1ZWQg
aGVhZGVyLgoKDgoHBAAEAAIJARIDWQQSCg4KBwQABAACCQISA1kVFgoxCgYEAAQAAgoSA1wE
KRoiIE1pc3NwZWxsZWQgc2VjdXJpdHkgaGVhZGVyIG5hbWUuCgoOCgcEAAQAAgoBEgNcBCMK
DgoHBAAEAAIKAhIDXCYoCkMKBgQABAACCxIDXwQsGjQgTWlzbWF0Y2hpbmcgdmFsdWVzIGlu
IGEgZHVwbGljYXRlIHNlY3VyaXR5IGhlYWRlci4KCg4KBwQABAACCwESA18EJgoOCgcEAAQA
AgsCEgNfKSsK3AEKBAQAAgASA2UCEhrOASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRmlu
ZGluZy4gVGhlIG5hbWUgZm9sbG93cyB0aGUgZm9ybWF0IG9mCiAncHJvamVjdHMve3Byb2pl
Y3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhbnJ1bnMve3NjYW5SdW5JZH0v
ZmluZGluZ3Mve2ZpbmRpbmdJZH0nLgogVGhlIGZpbmRpbmcgSURzIGFyZSBnZW5lcmF0ZWQg
YnkgdGhlIHN5c3RlbS4KCgwKBQQAAgAFEgNlAggKDAoFBAACAAESA2UJDQoMCgUEAAIAAxID
ZRARCicKBAQAAgESA2gCHxoaIFRoZSB0eXBlIG9mIHRoZSBGaW5kaW5nLgoKDAoFBAACAQYS
A2gCDQoMCgUEAAIBARIDaA4aCgwKBQQAAgEDEgNoHR4KXgoEBAACAhIDbAIZGlEgVGhlIGh0
dHAgbWV0aG9kIG9mIHRoZSByZXF1ZXN0IHRoYXQgdHJpZ2dlcmVkIHRoZSB2dWxuZXJhYmls
aXR5LCBpbgogdXBwZXJjYXNlLgoKDAoFBAACAgUSA2wCCAoMCgUEAAICARIDbAkUCgwKBQQA
AgIDEgNsFxgKdAoEBAACAxIDcAIYGmcgVGhlIFVSTCBwcm9kdWNlZCBieSB0aGUgc2VydmVy
LXNpZGUgZnV6emVyIGFuZCB1c2VkIGluIHRoZSByZXF1ZXN0IHRoYXQKIHRyaWdnZXJlZCB0
aGUgdnVsbmVyYWJpbGl0eS4KCgwKBQQAAgMFEgNwAggKDAoFBAACAwESA3AJEwoMCgUEAAID
AxIDcBYXCkgKBAQAAgQSA3MCEho7IFRoZSBib2R5IG9mIHRoZSByZXF1ZXN0IHRoYXQgdHJp
Z2dlcmVkIHRoZSB2dWxuZXJhYmlsaXR5LgoKDAoFBAACBAUSA3MCCAoMCgUEAAIEARIDcwkN
CgwKBQQAAgQDEgNzEBEKNAoEBAACBRIDdgIZGicgVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB2
dWxuZXJhYmlsaXR5LgoKDAoFBAACBQUSA3YCCAoMCgUEAAIFARIDdgkUCgwKBQQAAgUDEgN2
FxgKcAoEBAACBhIDegIeGmMgVGhlIFVSTCBjb250YWluaW5nIGh1bWFuLXJlYWRhYmxlIHBh
eWxvYWQgdGhhdCB1c2VyIGNhbiBsZXZlcmFnZSB0bwogcmVwcm9kdWNlIHRoZSB2dWxuZXJh
YmlsaXR5LgoKDAoFBAACBgUSA3oCCAoMCgUEAAIGARIDegkZCgwKBQQAAgYDEgN6HB0KcAoE
BAACBxIDfgIXGmMgSWYgdGhlIHZ1bG5lcmFiaWxpdHkgd2FzIG9yaWdpbmF0ZWQgZnJvbSBu
ZXN0ZWQgSUZyYW1lLCB0aGUgaW1tZWRpYXRlCiBwYXJlbnQgSUZyYW1lIGlzIHJlcG9ydGVk
LgoKDAoFBAACBwUSA34CCAoMCgUEAAIHARIDfgkSCgwKBQQAAgcDEgN+FRYKUwoEBAACCBIE
gQECFxpFIFRoZSBVUkwgd2hlcmUgdGhlIGJyb3dzZXIgbGFuZHMgd2hlbiB0aGUgdnVsbmVy
YWJpbGl0eSBpcyBkZXRlY3RlZC4KCg0KBQQAAggFEgSBAQIICg0KBQQAAggBEgSBAQkSCg0K
BQQAAggDEgSBARUWCmcKBAQAAgkSBIUBAhoaWSBUaGUgdHJhY2tpbmcgSUQgdW5pcXVlbHkg
aWRlbnRpZmllcyBhIHZ1bG5lcmFiaWxpdHkgaW5zdGFuY2UgYWNyb3NzCiBtdWx0aXBsZSBT
Y2FuUnVucy4KCg0KBQQAAgkFEgSFAQIICg0KBQQAAgkBEgSFAQkUCg0KBQQAAgkDEgSFARcZ
CkkKBAQAAgoSBIgBAigaOyBBbiBhZGRvbiBjb250YWluaW5nIGluZm9ybWF0aW9uIGFib3V0
IG91dGRhdGVkIGxpYnJhcmllcy4KCg0KBQQAAgoGEgSIAQIRCg0KBQQAAgoBEgSIARIiCg0K
BQQAAgoDEgSIASUnCqABCgQEAAILEgSMAQIsGpEBIEFuIGFkZG9uIGNvbnRhaW5pbmcgZGV0
YWlsZWQgaW5mb3JtYXRpb24gcmVnYXJkaW5nIGFueSByZXNvdXJjZSBjYXVzaW5nIHRoZQog
dnVsbmVyYWJpbGl0eSBzdWNoIGFzIEphdmFTY3JpcHQgc291cmNlcywgaW1hZ2UsIGF1ZGlv
IGZpbGVzLCBldGMuCgoNCgUEAAILBhIEjAECEwoNCgUEAAILARIEjAEUJgoNCgUEAAILAxIE
jAEpKwpZCgQEAAIMEgSPAQIsGksgQW4gYWRkb24gY29udGFpbmluZyBpbmZvcm1hdGlvbiBh
Ym91dCB2dWxuZXJhYmxlIG9yIG1pc3NpbmcgSFRUUCBoZWFkZXJzLgoKDQoFBAACDAYSBI8B
AhMKDQoFBAACDAESBI8BFCYKDQoFBAACDAMSBI8BKSsKbAoEBAACDRIEkwECMhpeIEFuIGFk
ZG9uIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgcmVxdWVzdCBwYXJhbWV0ZXJzIHdo
aWNoIHdlcmUgZm91bmQKIHRvIGJlIHZ1bG5lcmFibGUuCgoNCgUEAAINBhIEkwECFgoNCgUE
AAINARIEkwEXLAoNCgUEAAINAxIEkwEvMQpMCgQEAAIOEgSWAQIPGj4gQW4gYWRkb24gY29u
dGFpbmluZyBpbmZvcm1hdGlvbiByZXBvcnRlZCBmb3IgYW4gWFNTLCBpZiBhbnkuCgoNCgUE
AAIOBhIElgECBQoNCgUEAAIOARIElgEGCQoNCgUEAAIOAxIElgEMDmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding ===
    # Fields for Finding
    # Field: name Type: 9 ()
    # Field: finding_type Type: 14 (.google.cloud.websecurityscanner.v1alpha.Finding.FindingType)
    # Field: http_method Type: 9 ()
    # Field: fuzzed_url Type: 9 ()
    # Field: body Type: 9 ()
    # Field: description Type: 9 ()
    # Field: reproduction_url Type: 9 ()
    # Field: frame_url Type: 9 ()
    # Field: final_url Type: 9 ()
    # Field: tracking_id Type: 9 ()
    # Field: outdated_library Type: 11 (.google.cloud.websecurityscanner.v1alpha.OutdatedLibrary)
    # Field: violating_resource Type: 11 (.google.cloud.websecurityscanner.v1alpha.ViolatingResource)
    # Field: vulnerable_headers Type: 11 (.google.cloud.websecurityscanner.v1alpha.VulnerableHeaders)
    # Field: vulnerable_parameters Type: 11 (.google.cloud.websecurityscanner.v1alpha.VulnerableParameters)
    # Field: xss Type: 11 (.google.cloud.websecurityscanner.v1alpha.Xss)

# Enum: Finding::FindingType
our $Finding_FINDING_TYPE_UNSPECIFIED = 0;
our $Finding_MIXED_CONTENT = 1;
our $Finding_OUTDATED_LIBRARY = 2;
our $Finding_ROSETTA_FLASH = 5;
our $Finding_XSS_CALLBACK = 3;
our $Finding_XSS_ERROR = 4;
our $Finding_CLEAR_TEXT_PASSWORD = 6;
our $Finding_INVALID_CONTENT_TYPE = 7;
our $Finding_XSS_ANGULAR_CALLBACK = 8;
our $Finding_INVALID_HEADER = 9;
our $Finding_MISSPELLED_SECURITY_HEADER_NAME = 10;
our $Finding_MISMATCHING_SECURITY_HEADER_VALUES = 11;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::Finding - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/finding.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::Finding;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding->new({
        name => $name,
        finding_type => $finding_type,
        http_method => $http_method,
        fuzzed_url => $fuzzed_url,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/finding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding

A Finding resource represents a vulnerability instance identified during a
ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the Finding. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanruns/{scanRunId}/findings/{findingId}'.
The finding IDs are generated by the system.

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::Finding::FindingType>)

The type of the Finding.

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<String>

The http method of the request that triggered the vulnerability, in
uppercase.

=item * C<< $msg->fuzzed_url() >> / C<< $msg->fuzzed_url($value) >>

Type: C<String>

The URL produced by the server-side fuzzer and used in the request that
triggered the vulnerability.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

The body of the request that triggered the vulnerability.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the vulnerability.

=item * C<< $msg->reproduction_url() >> / C<< $msg->reproduction_url($value) >>

Type: C<String>

The URL containing human-readable payload that user can leverage to
reproduce the vulnerability.

=item * C<< $msg->frame_url() >> / C<< $msg->frame_url($value) >>

Type: C<String>

If the vulnerability was originated from nested IFrame, the immediate
parent IFrame is reported.

=item * C<< $msg->final_url() >> / C<< $msg->final_url($value) >>

Type: C<String>

The URL where the browser lands when the vulnerability is detected.

=item * C<< $msg->tracking_id() >> / C<< $msg->tracking_id($value) >>

Type: C<String>

The tracking ID uniquely identifies a vulnerability instance across
multiple ScanRuns.

=item * C<< $msg->outdated_library() >> / C<< $msg->outdated_library($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::OutdatedLibrary>)

An addon containing information about outdated libraries.

=item * C<< $msg->violating_resource() >> / C<< $msg->violating_resource($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::ViolatingResource>)

An addon containing detailed information regarding any resource causing the
vulnerability such as JavaScript sources, image, audio files, etc.

=item * C<< $msg->vulnerable_headers() >> / C<< $msg->vulnerable_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableHeaders>)

An addon containing information about vulnerable or missing HTTP headers.

=item * C<< $msg->vulnerable_parameters() >> / C<< $msg->vulnerable_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableParameters>)

An addon containing information about request parameters which were found
to be vulnerable.

=item * C<< $msg->xss() >> / C<< $msg->xss($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::Xss>)

An addon containing information reported for an XSS, if any.

=back

=head3 Enum: Finding::FindingType

=over 4

=item * C<FINDING_TYPE_UNSPECIFIED> => C<0>

=item * C<MIXED_CONTENT> => C<1>

=item * C<OUTDATED_LIBRARY> => C<2>

=item * C<ROSETTA_FLASH> => C<5>

=item * C<XSS_CALLBACK> => C<3>

=item * C<XSS_ERROR> => C<4>

=item * C<CLEAR_TEXT_PASSWORD> => C<6>

=item * C<INVALID_CONTENT_TYPE> => C<7>

=item * C<XSS_ANGULAR_CALLBACK> => C<8>

=item * C<INVALID_HEADER> => C<9>

=item * C<MISSPELLED_SECURITY_HEADER_NAME> => C<10>

=item * C<MISMATCHING_SECURITY_HEADER_VALUES> => C<11>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::Finding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
