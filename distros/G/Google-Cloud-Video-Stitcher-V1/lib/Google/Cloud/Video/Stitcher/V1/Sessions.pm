package Google::Cloud::Video::Stitcher::V1::Sessions;

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
    eval { require Google::Cloud::Video::Stitcher::V1::Companions };
    eval { require Google::Cloud::Video::Stitcher::V1::Events };
    eval { require Google::Cloud::Video::Stitcher::V1::LiveConfigs };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvc2Vzc2lvbnMucHJvdG8SHmdvb2ds
ZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxovZ29vZ2xlL2Nsb3VkL3ZpZGVvL3N0
aXRjaGVyL3YxL2NvbXBhbmlvbnMucHJvdG8aK2dvb2dsZS9jbG91ZC92aWRlby9zdGl0Y2hl
ci92MS9ldmVudHMucHJvdG8aMWdvb2dsZS9jbG91ZC92aWRlby9zdGl0Y2hlci92MS9saXZl
X2NvbmZpZ3MucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byLFBwoKVm9k
U2Vzc2lvbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSWAoNaW50ZXJzdGl0aWFscxgCIAEo
CzItLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5JbnRlcnN0aXRpYWxzQgPgQQNS
DWludGVyc3RpdGlhbHMSHgoIcGxheV91cmkYBCABKAlCA+BBA1IHcGxheVVyaRIdCgpzb3Vy
Y2VfdXJpGAUgASgJUglzb3VyY2VVcmkSHAoKYWRfdGFnX3VyaRgGIAEoCVIIYWRUYWdVcmkS
ZgoQYWRfdGFnX21hY3JvX21hcBgHIAMoCzI9Lmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hl
ci52MS5Wb2RTZXNzaW9uLkFkVGFnTWFjcm9NYXBFbnRyeVINYWRUYWdNYWNyb01hcBJaChBt
YW5pZmVzdF9vcHRpb25zGAkgASgLMi8uZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYx
Lk1hbmlmZXN0T3B0aW9uc1IPbWFuaWZlc3RPcHRpb25zEh4KCGFzc2V0X2lkGAogASgJQgPg
QQNSB2Fzc2V0SWQSUAoLYWRfdHJhY2tpbmcYCyABKA4yKi5nb29nbGUuY2xvdWQudmlkZW8u
c3RpdGNoZXIudjEuQWRUcmFja2luZ0ID4EECUgphZFRyYWNraW5nElkKDGdhbV9zZXR0aW5n
cxgNIAEoCzI2Lmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5Wb2RTZXNzaW9uLkdh
bVNldHRpbmdzUgtnYW1TZXR0aW5ncxJKCgp2b2RfY29uZmlnGA4gASgJQiv6QSgKJnZpZGVv
c3RpdGNoZXIuZ29vZ2xlYXBpcy5jb20vVm9kQ29uZmlnUgl2b2RDb25maWcaVwoLR2FtU2V0
dGluZ3MSJgoMbmV0d29ya19jb2RlGAEgASgJQgPgQQJSC25ldHdvcmtDb2RlEiAKCXN0cmVh
bV9pZBgCIAEoCUID4EECUghzdHJlYW1JZBpAChJBZFRhZ01hY3JvTWFwRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATpv6kFsCid2aWRlb3N0aXRj
aGVyLmdvb2dsZWFwaXMuY29tL1ZvZFNlc3Npb24SQXByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS92b2RTZXNzaW9ucy97dm9kX3Nlc3Npb259IrsBCg1JbnRlcnN0
aXRpYWxzEk4KCWFkX2JyZWFrcxgBIAMoCzIxLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hl
ci52MS5Wb2RTZXNzaW9uQWRCcmVha1IIYWRCcmVha3MSWgoPc2Vzc2lvbl9jb250ZW50GAIg
ASgLMjEuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLlZvZFNlc3Npb25Db250ZW50
Ug5zZXNzaW9uQ29udGVudCLoAQoMVm9kU2Vzc2lvbkFkEjUKCGR1cmF0aW9uGAEgASgLMhku
Z29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbhJRCg1jb21wYW5pb25fYWRzGAIg
ASgLMiwuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLkNvbXBhbmlvbkFkc1IMY29t
cGFuaW9uQWRzEk4KD2FjdGl2aXR5X2V2ZW50cxgDIAMoCzIlLmdvb2dsZS5jbG91ZC52aWRl
by5zdGl0Y2hlci52MS5FdmVudFIOYWN0aXZpdHlFdmVudHMiSgoRVm9kU2Vzc2lvbkNvbnRl
bnQSNQoIZHVyYXRpb24YASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCGR1cmF0
aW9uIrUCChFWb2RTZXNzaW9uQWRCcmVhaxJWCg9wcm9ncmVzc19ldmVudHMYASADKAsyLS5n
b29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuUHJvZ3Jlc3NFdmVudFIOcHJvZ3Jlc3NF
dmVudHMSPgoDYWRzGAIgAygLMiwuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLlZv
ZFNlc3Npb25BZFIDYWRzEkEKD2VuZF90aW1lX29mZnNldBgDIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblINZW5kVGltZU9mZnNldBJFChFzdGFydF90aW1lX29mZnNldBgEIAEo
CzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIPc3RhcnRUaW1lT2Zmc2V0IrMHCgtMaXZl
U2Vzc2lvbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSHgoIcGxheV91cmkYAiABKAlCA+BB
A1IHcGxheVVyaRJgCg1hZF90YWdfbWFjcm9zGAYgAygLMjwuZ29vZ2xlLmNsb3VkLnZpZGVv
LnN0aXRjaGVyLnYxLkxpdmVTZXNzaW9uLkFkVGFnTWFjcm9zRW50cnlSC2FkVGFnTWFjcm9z
EloKEG1hbmlmZXN0X29wdGlvbnMYCiABKAsyLy5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNo
ZXIudjEuTWFuaWZlc3RPcHRpb25zUg9tYW5pZmVzdE9wdGlvbnMSWgoMZ2FtX3NldHRpbmdz
GA8gASgLMjcuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLkxpdmVTZXNzaW9uLkdh
bVNldHRpbmdzUgtnYW1TZXR0aW5ncxJQCgtsaXZlX2NvbmZpZxgQIAEoCUIv4EEC+kEpCid2
aWRlb3N0aXRjaGVyLmdvb2dsZWFwaXMuY29tL0xpdmVDb25maWdSCmxpdmVDb25maWcSSwoL
YWRfdHJhY2tpbmcYESABKA4yKi5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuQWRU
cmFja2luZ1IKYWRUcmFja2luZxr9AQoLR2FtU2V0dGluZ3MSIAoJc3RyZWFtX2lkGAEgASgJ
QgPgQQJSCHN0cmVhbUlkEoMBChR0YXJnZXRpbmdfcGFyYW1ldGVycxgEIAMoCzJQLmdvb2ds
ZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5MaXZlU2Vzc2lvbi5HYW1TZXR0aW5ncy5UYXJn
ZXRpbmdQYXJhbWV0ZXJzRW50cnlSE3RhcmdldGluZ1BhcmFtZXRlcnMaRgoYVGFyZ2V0aW5n
UGFyYW1ldGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1
ZToCOAEaPgoQQWRUYWdNYWNyb3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBOnLqQW8KKHZpZGVvc3RpdGNoZXIuZ29vZ2xlYXBpcy5jb20vTGl2
ZVNlc3Npb24SQ3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9saXZl
U2Vzc2lvbnMve2xpdmVfc2Vzc2lvbn0inwIKD01hbmlmZXN0T3B0aW9ucxJeChJpbmNsdWRl
X3JlbmRpdGlvbnMYASADKAsyLy5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuUmVu
ZGl0aW9uRmlsdGVyUhFpbmNsdWRlUmVuZGl0aW9ucxJgCg1iaXRyYXRlX29yZGVyGAIgASgO
MjsuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLk1hbmlmZXN0T3B0aW9ucy5PcmRl
clBvbGljeVIMYml0cmF0ZU9yZGVyIkoKC09yZGVyUG9saWN5EhwKGE9SREVSX1BPTElDWV9V
TlNQRUNJRklFRBAAEg0KCUFTQ0VORElORxABEg4KCkRFU0NFTkRJTkcQAiJKCg9SZW5kaXRp
b25GaWx0ZXISHwoLYml0cmF0ZV9icHMYASABKAVSCmJpdHJhdGVCcHMSFgoGY29kZWNzGAIg
ASgJUgZjb2RlY3NCdQoiY29tLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MUINU2Vz
c2lvbnNQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL3ZpZGVvL3N0aXRjaGVyL2FwaXYx
L3N0aXRjaGVycGI7c3RpdGNoZXJwYkr7RQoHEgUOAPUBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAOQoJCgIDAxIDFQA1CgkKAgMEEgMWADsKCQoCAwUSAxcAKAoICgEIEgMZAFUKCQoCCAsS
AxkAVQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC4KCQoCCAgSAxsALgoICgEIEgMc
ADsKCQoCCAESAxwAOwpZCgIEABIEHwBkARpNIE1ldGFkYXRhIGZvciBhIFZPRCBzZXNzaW9u
LiBUaGUgc2Vzc2lvbiBleHBpcmVzIDQgaG91cnMgYWZ0ZXIgaXRzIGNyZWF0aW9uLgoKCgoD
BAABEgMfCBIKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECnQKBAQAAwASBCcCLQMaZiBE
ZWZpbmVzIGZpZWxkcyByZWxhdGVkIHRvIEdvb2dsZSBBZCBNYW5hZ2VyIChHQU0pLiBUaGlz
IHNob3VsZCBiZSBzZXQgaWYKIEdBTSBpcyBiZWluZyB1c2VkIGZvciBhZHMuCgoMCgUEAAMA
ARIDJwoVCjMKBgQAAwACABIDKQRFGiQgUmVxdWlyZWQuIEFkIE1hbmFnZXIgbmV0d29yayBj
b2RlLgoKDgoHBAADAAIABRIDKQQKCg4KBwQAAwACAAESAykLFwoOCgcEAAMAAgADEgMpGhsK
DgoHBAADAAIACBIDKRxEChEKCgQAAwACAAicCAASAykdQwpBCgYEAAMAAgESAywEQhoyIFJl
cXVpcmVkLiBUaGUgc3RyZWFtIElEIGdlbmVyYXRlZCBieSBBZCBNYW5hZ2VyLgoKDgoHBAAD
AAIBBRIDLAQKCg4KBwQAAwACAQESAywLFAoOCgcEAAMAAgEDEgMsFxgKDgoHBAADAAIBCBID
LBlBChEKCgQAAwACAQicCAASAywaQAqLAQoEBAACABIDMQI+Gn4gT3V0cHV0IG9ubHkuIFRo
ZSBuYW1lIG9mIHRoZSBWT0Qgc2Vzc2lvbiwgaW4gdGhlIGZvcm0gb2YKIGBwcm9qZWN0cy97
cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3ZvZFNlc3Npb25zL3tpZH1g
LgoKDAoFBAACAAUSAzECCAoMCgUEAAIAARIDMQkNCgwKBQQAAgADEgMxEBEKDAoFBAACAAgS
AzESPQoPCggEAAIACJwIABIDMRM8CksKBAQAAgESAzQCTho+IE91dHB1dCBvbmx5LiBNZXRh
ZGF0YSBvZiB3aGF0IHdhcyBzdGl0Y2hlZCBpbnRvIHRoZSBjb250ZW50LgoKDAoFBAACAQYS
AzQCDwoMCgUEAAIBARIDNBAdCgwKBQQAAgEDEgM0ICEKDAoFBAACAQgSAzQiTQoPCggEAAIB
CJwIABIDNCNMCkUKBAQAAgISAzcCQho4IE91dHB1dCBvbmx5LiBUaGUgcGxheWJhY2sgVVJJ
IG9mIHRoZSBzdGl0Y2hlZCBjb250ZW50LgoKDAoFBAACAgUSAzcCCAoMCgUEAAICARIDNwkR
CgwKBQQAAgIDEgM3FBUKDAoFBAACAggSAzcWQQoPCggEAAICCJwIABIDNxdACsoBCgQEAAID
EgM8AhgavAEgVVJJIG9mIHRoZSBtZWRpYSB0byBzdGl0Y2guIEZvciBtb3N0IHVzZSBjYXNl
cywgeW91IHNob3VsZCBjcmVhdGUgYQogW1ZvZENvbmZpZ11bZ29vZ2xlLmNsb3VkLnZpZGVv
LnN0aXRjaGVyLnYxLlZvZENvbmZpZ10gd2l0aCB0aGlzIGluZm9ybWF0aW9uCiByYXRoZXIg
dGhhbiBzZXR0aW5nIHRoaXMgZmllbGQgZGlyZWN0bHkuCgoMCgUEAAIDBRIDPAIICgwKBQQA
AgMBEgM8CRMKDAoFBAACAwMSAzwWFwq6AQoEBAACBBIDQQIYGqwBIEFkIHRhZyBVUkkuIEZv
ciBtb3N0IHVzZSBjYXNlcywgeW91IHNob3VsZCBjcmVhdGUgYQogW1ZvZENvbmZpZ11bZ29v
Z2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLlZvZENvbmZpZ10gd2l0aCB0aGlzIGluZm9y
bWF0aW9uCiByYXRoZXIgdGhhbiBzZXR0aW5nIHRoaXMgZmllbGQgZGlyZWN0bHkuCgoMCgUE
AAIEBRIDQQIICgwKBQQAAgQBEgNBCRMKDAoFBAACBAMSA0EWFwqVBAoEBAACBRIDUAIrGocE
IEtleSB2YWx1ZSBwYWlycyBmb3IgYWQgdGFnIG1hY3JvIHJlcGxhY2VtZW50LCBvbmx5IGF2
YWlsYWJsZSBmb3IgVk9ECiBzZXNzaW9ucyB0aGF0IGRvIG5vdCBpbXBsZW1lbnQgR29vZ2xl
IEFkIG1hbmFnZXIgYWQgaW5zZXJ0aW9uLiBJZiB0aGUKIHNwZWNpZmllZCBhZCB0YWcgVVJJ
IGhhcyBtYWNyb3MsIHRoaXMgZmllbGQgcHJvdmlkZXMgdGhlIG1hcHBpbmcgdG8gdGhlCiB2
YWx1ZSB0aGF0IHdpbGwgcmVwbGFjZSB0aGUgbWFjcm8gaW4gdGhlIGFkIHRhZyBVUkkuCgog
TWFjcm9zIGFyZSBkZXNpZ25hdGVkIGJ5IHNxdWFyZSBicmFja2V0cywgZm9yIGV4YW1wbGU6
CgogICBBZCB0YWcgVVJJOiBgImh0dHBzOi8vZG91YmxlY2xpY2suZ29vZ2xlLmNvbS9hZC8x
P2dlb19pZD1bZ2VvSWRdImAKCiAgIEFkIHRhZyBtYWNybyBtYXA6IGB7Imdlb0lkIjogIjEy
MyJ9YAoKICAgRnVsbHkgcXVhbGlmaWVkIGFkIHRhZzoKICAgYCJodHRwczovL2RvdWJsZWNs
aWNrLmdvb2dsZS5jb20vYWQvMT9nZW9faWQ9MTIzImAKCgwKBQQAAgUGEgNQAhUKDAoFBAAC
BQESA1AWJgoMCgUEAAIFAxIDUCkqCkkKBAQAAgYSA1MCJxo8IEFkZGl0aW9uYWwgb3B0aW9u
cyB0aGF0IGFmZmVjdCB0aGUgb3V0cHV0IG9mIHRoZSBtYW5pZmVzdC4KCgwKBQQAAgYGEgNT
AhEKDAoFBAACBgESA1MSIgoMCgUEAAIGAxIDUyUmCk4KBAQAAgcSA1YCQxpBIE91dHB1dCBv
bmx5LiBUaGUgZ2VuZXJhdGVkIElEIG9mIHRoZSBWb2RTZXNzaW9uJ3Mgc291cmNlIG1lZGlh
LgoKDAoFBAACBwUSA1YCCAoMCgUEAAIHARIDVgkRCgwKBQQAAgcDEgNWFBYKDAoFBAACBwgS
A1YXQgoPCggEAAIHCJwIABIDVhhBCkEKBAQAAggSA1kCRxo0IFJlcXVpcmVkLiBEZXRlcm1p
bmVzIGhvdyB0aGUgYWQgc2hvdWxkIGJlIHRyYWNrZWQuCgoMCgUEAAIIBhIDWQIMCgwKBQQA
AggBEgNZDRgKDAoFBAACCAMSA1kbHQoMCgUEAAIICBIDWR5GCg8KCAQAAggInAgAEgNZH0UK
XgoEBAACCRIDXQIgGlEgVGhpcyBmaWVsZCBzaG91bGQgYmUgc2V0IHdpdGggYXBwcm9wcmlh
dGUgdmFsdWVzIGlmIEdBTSBpcyBiZWluZyB1c2VkIGZvcgogYWRzLgoKDAoFBAACCQYSA10C
DQoMCgUEAAIJARIDXQ4aCgwKBQQAAgkDEgNdHR8KkQEKBAQAAgoSBGECYwUaggEgVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIFZPRCBjb25maWcgZm9yIHRoaXMgc2Vzc2lvbiwgaW4gdGhl
IGZvcm0gb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdm9k
Q29uZmlncy97aWR9YC4KCgwKBQQAAgoFEgNhAggKDAoFBAACCgESA2EJEwoMCgUEAAIKAxID
YRYYCg0KBQQAAgoIEgRhGWMECg8KBwQAAgoInwgSBGEaYwMKSAoCBAESBGcAbQEaPCBEZXNj
cmliZXMgd2hhdCB3YXMgc3RpdGNoZWQgaW50byBhIFZPRCBzZXNzaW9uJ3MgbWFuaWZlc3Qu
CgoKCgMEAQESA2cIFQoxCgQEAQIAEgNpAisaJCBMaXN0IG9mIGFkIGJyZWFrcyBvcmRlcmVk
IGJ5IHRpbWUuCgoMCgUEAQIABBIDaQIKCgwKBQQBAgAGEgNpCxwKDAoFBAECAAESA2kdJgoM
CgUEAQIAAxIDaSkqCkUKBAQBAgESA2wCKBo4IEluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gdGhl
IGNvbnRlbnQgb2YgdGhlIFZPRCBzZXNzaW9uLgoKDAoFBAECAQYSA2wCEwoMCgUEAQIBARID
bBQjCgwKBQQBAgEDEgNsJicKOwoCBAISBHAAfQEaLyBNZXRhZGF0YSBmb3IgYW4gaW5zZXJ0
ZWQgYWQgaW4gYSBWT0Qgc2Vzc2lvbi4KCgoKAwQCARIDcAgUCi0KBAQCAgASA3ICKBogIER1
cmF0aW9uIGluIHNlY29uZHMgb2YgdGhlIGFkLgoKDAoFBAICAAYSA3ICGgoMCgUEAgIAARID
chsjCgwKBQQCAgADEgNyJicKQAoEBAICARIDdQIhGjMgTWV0YWRhdGEgb2YgY29tcGFuaW9u
IGFkcyBhc3NvY2lhdGVkIHdpdGggdGhlIGFkLgoKDAoFBAICAQYSA3UCDgoMCgUEAgIBARID
dQ8cCgwKBQQCAgEDEgN1HyAKsAIKBAQCAgISA3wCJRqiAiBUaGUgbGlzdCBvZiBwcm9ncmVz
cyB0cmFja2luZyBldmVudHMgZm9yIHRoZSBhZCBicmVhay4gVGhlc2UgY2FuIGJlIG9mCiB0
aGUgZm9sbG93aW5nIElBQiB0eXBlczogYE1VVEVgLCBgVU5NVVRFYCwgYFBBVVNFYCwgYENM
SUNLYCwKIGBDTElDS19USFJPVUdIYCwgYFJFV0lORGAsIGBSRVNVTUVgLCBgRVJST1JgLCBg
RlVMTFNDUkVFTmAsCiBgRVhJVF9GVUxMU0NSRUVOYCwgYEVYUEFORGAsIGBDT0xMQVBTRWAs
IGBBQ0NFUFRfSU5WSVRBVElPTl9MSU5FQVJgLAogYENMT1NFX0xJTkVBUmAsIGBTS0lQYC4K
CgwKBQQCAgIEEgN8AgoKDAoFBAICAgYSA3wLEAoMCgUEAgICARIDfBEgCgwKBQQCAgIDEgN8
IyQKSgoCBAMSBoABAIQBARo8IE1ldGFkYXRhIGZvciB0aGUgZW50aXJlIHN0aXRjaGVkIGNv
bnRlbnQgaW4gYSBWT0Qgc2Vzc2lvbi4KCgsKAwQDARIEgAEIGQpcCgQEAwIAEgSDAQIoGk4g
VGhlIHRvdGFsIGR1cmF0aW9uIGluIHNlY29uZHMgb2YgdGhlIGNvbnRlbnQgaW5jbHVkaW5n
IHRoZSBhZHMgc3RpdGNoZWQKIGluLgoKDQoFBAMCAAYSBIMBAhoKDQoFBAMCAAESBIMBGyMK
DQoFBAMCAAMSBIMBJicKMgoCBAQSBocBAJMBARokIE1ldGFkYXRhIGZvciBhbiBpbnNlcnRl
ZCBhZCBicmVhay4KCgsKAwQEARIEhwEIGQpSCgQEBAIAEgSJAQItGkQgTGlzdCBvZiBldmVu
dHMgdGhhdCBhcmUgZXhwZWN0ZWQgdG8gYmUgdHJpZ2dlcmVkLCBvcmRlcmVkIGJ5IHRpbWUu
CgoNCgUEBAIABBIEiQECCgoNCgUEBAIABhIEiQELGAoNCgUEBAIAARIEiQEZKAoNCgUEBAIA
AxIEiQErLAo/CgQEBAIBEgSMAQIgGjEgT3JkZXJlZCBsaXN0IG9mIGFkcyBzdGl0Y2hlZCBp
bnRvIHRoZSBhZCBicmVhay4KCg0KBQQEAgEEEgSMAQIKCg0KBQQEAgEGEgSMAQsXCg0KBQQE
AgEBEgSMARgbCg0KBQQEAgEDEgSMAR4fClQKBAQEAgISBI8BAi8aRiBBZCBicmVhayBlbmQg
dGltZSBpbiBzZWNvbmRzIHJlbGF0aXZlIHRvIHRoZSBzdGFydCBvZiB0aGUgVk9EIGFzc2V0
LgoKDQoFBAQCAgYSBI8BAhoKDQoFBAQCAgESBI8BGyoKDQoFBAQCAgMSBI8BLS4KVgoEBAQC
AxIEkgECMRpIIEFkIGJyZWFrIHN0YXJ0IHRpbWUgaW4gc2Vjb25kcyByZWxhdGl2ZSB0byB0
aGUgc3RhcnQgb2YgdGhlIFZPRCBhc3NldC4KCg0KBQQEAgMGEgSSAQIaCg0KBQQEAgMBEgSS
ARssCg0KBQQEAgMDEgSSAS8wCoQBCgIEBRIGlwEA0wEBGnYgTWV0YWRhdGEgZm9yIGEgbGl2
ZSBzZXNzaW9uLiBUaGUgc2Vzc2lvbiBleHBpcmVzIDUgbWludXRlcyBhZnRlciB0aGUgY2xp
ZW50CiBzdG9wcyBmZXRjaGluZyB0aGUgc2Vzc2lvbidzIHBsYXlsaXN0cy4KCgsKAwQFARIE
lwEIEwoNCgMEBQcSBpgBApsBBAoPCgUEBQedCBIGmAECmwEECkQKBAQFAwASBp4BAqgBAxo0
IERlZmluZXMgZmllbGRzIHJlbGF0ZWQgdG8gR29vZ2xlIEFkIE1hbmFnZXIgKEdBTSkuCgoN
CgUEBQMAARIEngEKFQqgAQoGBAUDAAIAEgShAQRCGo8BIFJlcXVpcmVkLiBUaGUgc3RyZWFt
IElEIGdlbmVyYXRlZCBieSBBZCBNYW5hZ2VyLiBUaGlzIG11c3QgYmUgc2V0IGlmIEdBTQog
aXMgYmVpbmcgdXNlZCBmb3IgYWRzIGFuZCB0aGUgc2Vzc2lvbiB1c2VzIGNsaWVudC1zaWRl
IGFkIHRyYWNraW5nLgoKDwoHBAUDAAIABRIEoQEECgoPCgcEBQMAAgABEgShAQsUCg8KBwQF
AwACAAMSBKEBFxgKDwoHBAUDAAIACBIEoQEZQQoSCgoEBQMAAgAInAgAEgShARpACtUBCgYE
BQMAAgESBKcBBDEaxAEgW1RhcmdldGluZwogcGFyYW1ldGVyc10oaHR0cHM6Ly9zdXBwb3J0
Lmdvb2dsZS5jb20vYWRtYW5hZ2VyL2Fuc3dlci83MzIwODk5KSB0byBzZW5kCiB0byBBZCBN
YW5hZ2VyIHRvIGdlbmVyYXRlIGEgc3RyZWFtIElELiBUaGlzIHNob3VsZCBvbmx5IGJlIHNl
dCBpZiB0aGUKIHNlc3Npb24gdXNlcyBzZXJ2ZXItc2lkZSBhZCB0cmFja2luZy4KCg8KBwQF
AwACAQYSBKcBBBcKDwoHBAUDAAIBARIEpwEYLAoPCgcEBQMAAgEDEgSnAS8wCocBCgQEBQIA
EgSsAQI+GnkgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBsaXZlIHNlc3Npb24sIGlu
IHRoZSBmb3JtIG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2xpdmVTZXNzaW9ucy97aWR9YC4KCg0KBQQFAgAFEgSsAQIICg0KBQQFAgABEgSsAQkNCg0K
BQQFAgADEgSsARARCg0KBQQFAgAIEgSsARI9ChAKCAQFAgAInAgAEgSsARM8ClMKBAQFAgES
BK8BAkIaRSBPdXRwdXQgb25seS4gVGhlIFVSSSB0byBwbGF5IHRoZSBsaXZlIHNlc3Npb24n
cyBhZC1zdGl0Y2hlZCBzdHJlYW0uCgoNCgUEBQIBBRIErwECCAoNCgUEBQIBARIErwEJEQoN
CgUEBQIBAxIErwEUFQoNCgUEBQIBCBIErwEWQQoQCggEBQIBCJwIABIErwEXQAqSBAoEBAUC
AhIEvgECKBqDBCBLZXkgdmFsdWUgcGFpcnMgZm9yIGFkIHRhZyBtYWNybyByZXBsYWNlbWVu
dCwgb25seSBhdmFpbGFibGUgZm9yIGxpdmUKIHNlc3Npb25zIHRoYXQgZG8gbm90IGltcGxl
bWVudCBHb29nbGUgQWQgbWFuYWdlciBhZCBpbnNlcnRpb24uIElmIHRoZQogc3BlY2lmaWVk
IGFkIHRhZyBVUkkgaGFzIG1hY3JvcywgdGhpcyBmaWVsZCBwcm92aWRlcyB0aGUgbWFwcGlu
ZyB0byB0aGUKIHZhbHVlIHRoYXQgd2lsbCByZXBsYWNlIHRoZSBtYWNybyBpbiB0aGUgYWQg
dGFnIFVSSS4KCiBNYWNyb3MgYXJlIGRlc2lnbmF0ZWQgYnkgc3F1YXJlIGJyYWNrZXRzLCBm
b3IgZXhhbXBsZToKCiAgIEFkIHRhZyBVUkk6ICJodHRwczovL2RvdWJsZWNsaWNrLmdvb2ds
ZS5jb20vYWQvMT9nZW9faWQ9W2dlb0lkXSIKCiAgIEFkIHRhZyBtYWNyb3M6IGB7Imdlb0lk
IjogIjEyMyJ9YAoKICAgRnVsbHkgcXVhbGlmaWVkIGFkIHRhZzoKICAgYCJodHRwczovL2Rv
dWJsZWNsaWNrLmdvb2dsZS5jb20vYWQvMT9nZW9faWQ9MTIzImAKCg0KBQQFAgIGEgS+AQIV
Cg0KBQQFAgIBEgS+ARYjCg0KBQQFAgIDEgS+ASYnCkoKBAQFAgMSBMEBAigaPCBBZGRpdGlv
bmFsIG9wdGlvbnMgdGhhdCBhZmZlY3QgdGhlIG91dHB1dCBvZiB0aGUgbWFuaWZlc3QuCgoN
CgUEBQIDBhIEwQECEQoNCgUEBQIDARIEwQESIgoNCgUEBQIDAxIEwQElJwpfCgQEBQIEEgTF
AQIgGlEgVGhpcyBmaWVsZCBzaG91bGQgYmUgc2V0IHdpdGggYXBwcm9wcmlhdGUgdmFsdWVz
IGlmIEdBTSBpcyBiZWluZyB1c2VkIGZvcgogYWRzLgoKDQoFBAUCBAYSBMUBAg0KDQoFBAUC
BAESBMUBDhoKDQoFBAUCBAMSBMUBHR8KnwEKBAQFAgUSBskBAs4BBBqOASBSZXF1aXJlZC4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGxpdmUgY29uZmlnIGZvciB0aGlzIHNlc3Npb24s
IGluIHRoZQogZm9ybSBvZiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2xpdmVDb25maWdzL3tpZH1gLgoKDQoFBAUCBQUSBMkBAggKDQoFBAUCBQESBMkBCRQK
DQoFBAUCBQMSBMkBFxkKDwoFBAUCBQgSBskBGs4BAwoQCggEBQIFCJwIABIEygEEKgoRCgcE
BQIFCJ8IEgbLAQTNAQUKewoEBAUCBhIE0gECHhptIERldGVybWluZXMgaG93IHRoZSBhZCBz
aG91bGQgYmUgdHJhY2tlZC4gVGhpcyBvdmVycmlkZXMgdGhlIHZhbHVlIHNldCBpbgogdGhl
IGxpdmUgY29uZmlnIGZvciB0aGlzIHNlc3Npb24uCgoNCgUEBQIGBhIE0gECDAoNCgUEBQIG
ARIE0gENGAoNCgUEBQIGAxIE0gEbHQowCgIEBhIG1gEA6gEBGiIgT3B0aW9ucyBmb3IgbWFu
aWZlc3QgZ2VuZXJhdGlvbi4KCgsKAwQGARIE1gEIFwpJCgQEBgQAEgbYAQLhAQMaOSBEZWZp
bmVzIHRoZSBvcmRlcmluZyBwb2xpY3kgZHVyaW5nIG1hbmlmZXN0IGdlbmVyYXRpb24uCgoN
CgUEBgQAARIE2AEHEgozCgYEBgQAAgASBNoBBCEaIyBPcmRlcmluZyBwb2xpY3kgaXMgbm90
IHNwZWNpZmllZC4KCg8KBwQGBAACAAESBNoBBBwKDwoHBAYEAAIAAhIE2gEfIAolCgYEBgQA
AgESBN0BBBIaFSBPcmRlciBieSBhc2NlbmRpbmcuCgoPCgcEBgQAAgEBEgTdAQQNCg8KBwQG
BAACAQISBN0BEBEKJgoGBAYEAAICEgTgAQQTGhYgT3JkZXIgYnkgZGVzY2VuZGluZy4KCg8K
BwQGBAACAgESBOABBA4KDwoHBAYEAAICAhIE4AEREgpuCgQEBgIAEgTlAQIyGmAgSWYgc3Bl
Y2lmaWVkLCB0aGUgb3V0cHV0IG1hbmlmZXN0IHdpbGwgb25seSByZXR1cm4gcmVuZGl0aW9u
cyBtYXRjaGluZyB0aGUKIHNwZWNpZmllZCBmaWx0ZXJzLgoKDQoFBAYCAAQSBOUBAgoKDQoF
BAYCAAYSBOUBCxoKDQoFBAYCAAESBOUBGy0KDQoFBAYCAAMSBOUBMDEKigEKBAQGAgESBOkB
AiAafCBJZiBzcGVjaWZpZWQsIHRoZSBvdXRwdXQgbWFuaWZlc3Qgd2lsbCBvcmRlcnMgdGhl
IHZpZGVvIGFuZCBtdXhlZAogcmVuZGl0aW9ucyBieSBiaXRyYXRlIGFjY29yZGluZyB0byB0
aGUgb3JkZXJpbmcgcG9saWN5LgoKDQoFBAYCAQYSBOkBAg0KDQoFBAYCAQESBOkBDhsKDQoF
BAYCAQMSBOkBHh8KNgoCBAcSBu0BAPUBARooIEZpbHRlcnMgZm9yIGEgdmlkZW8gb3IgbXV4
ZWQgcmVkaXRpb24uCgoLCgMEBwESBO0BCBcKeQoEBAcCABIE8AECGBprIEJpdHJhdGUgaW4g
Yml0cyBwZXIgc2Vjb25kIGZvciB0aGUgcmVuZGl0aW9uLiBJZiBzZXQsIG9ubHkgcmVuZGl0
aW9ucyB3aXRoCiB0aGUgZXhhY3QgYml0cmF0ZSB3aWxsIG1hdGNoLgoKDQoFBAcCAAUSBPAB
AgcKDQoFBAcCAAESBPABCBMKDQoFBAcCAAMSBPABFhcKYwoEBAcCARIE9AECFBpVIENvZGVj
cyBmb3IgdGhlIHJlbmRpdGlvbi4gSWYgc2V0LCBvbmx5IHJlbmRpdGlvbnMgd2l0aCB0aGUg
ZXhhY3QgdmFsdWUKIHdpbGwgbWF0Y2guCgoNCgUEBwIBBRIE9AECCAoNCgUEBwIBARIE9AEJ
DwoNCgUEBwIBAxIE9AESE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::VodSession ===
    # Fields for VodSession
    # Field: name Type: 9 ()
    # Field: interstitials Type: 11 (.google.cloud.video.stitcher.v1.Interstitials)
    # Field: play_uri Type: 9 ()
    # Field: source_uri Type: 9 ()
    # Field: ad_tag_uri Type: 9 ()
    # Field: ad_tag_macro_map Type: 11 (.google.cloud.video.stitcher.v1.VodSession.AdTagMacroMapEntry)
    # Field: manifest_options Type: 11 (.google.cloud.video.stitcher.v1.ManifestOptions)
    # Field: asset_id Type: 9 ()
    # Field: ad_tracking Type: 14 (.google.cloud.video.stitcher.v1.AdTracking)
    # Field: gam_settings Type: 11 (.google.cloud.video.stitcher.v1.VodSession.GamSettings)
    # Field: vod_config Type: 9 ()

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials ===
    # Fields for Interstitials
    # Field: ad_breaks Type: 11 (.google.cloud.video.stitcher.v1.VodSessionAdBreak)
    # Field: session_content Type: 11 (.google.cloud.video.stitcher.v1.VodSessionContent)

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd ===
    # Fields for VodSessionAd
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: companion_ads Type: 11 (.google.cloud.video.stitcher.v1.CompanionAds)
    # Field: activity_events Type: 11 (.google.cloud.video.stitcher.v1.Event)

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent ===
    # Fields for VodSessionContent
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak ===
    # Fields for VodSessionAdBreak
    # Field: progress_events Type: 11 (.google.cloud.video.stitcher.v1.ProgressEvent)
    # Field: ads Type: 11 (.google.cloud.video.stitcher.v1.VodSessionAd)
    # Field: end_time_offset Type: 11 (.google.protobuf.Duration)
    # Field: start_time_offset Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession ===
    # Fields for LiveSession
    # Field: name Type: 9 ()
    # Field: play_uri Type: 9 ()
    # Field: ad_tag_macros Type: 11 (.google.cloud.video.stitcher.v1.LiveSession.AdTagMacrosEntry)
    # Field: manifest_options Type: 11 (.google.cloud.video.stitcher.v1.ManifestOptions)
    # Field: gam_settings Type: 11 (.google.cloud.video.stitcher.v1.LiveSession.GamSettings)
    # Field: live_config Type: 9 ()
    # Field: ad_tracking Type: 14 (.google.cloud.video.stitcher.v1.AdTracking)

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions ===
    # Fields for ManifestOptions
    # Field: include_renditions Type: 11 (.google.cloud.video.stitcher.v1.RenditionFilter)
    # Field: bitrate_order Type: 14 (.google.cloud.video.stitcher.v1.ManifestOptions.OrderPolicy)

# Enum: ManifestOptions::OrderPolicy
our $ManifestOptions_ORDER_POLICY_UNSPECIFIED = 0;
our $ManifestOptions_ASCENDING = 1;
our $ManifestOptions_DESCENDING = 2;

# === Message: Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter ===
    # Fields for RenditionFilter
    # Field: bitrate_bps Type: 5 ()
    # Field: codecs Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Sessions - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/sessions.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::Sessions;

    my $msg = Google::Cloud::Video::Stitcher::V1::Sessions::VodSession->new({
        name => $name,
        interstitials => $interstitials,
        play_uri => $play_uri,
        source_uri => $source_uri,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::Sessions::VodSession->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/sessions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::VodSession

Metadata for a VOD session. The session expires 4 hours after its creation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the VOD session, in the form of
`projects/{project_number}/locations/{location}/vodSessions/{id}`.

=item * C<< $msg->interstitials() >> / C<< $msg->interstitials($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials>)

Output only. Metadata of what was stitched into the content.

=item * C<< $msg->play_uri() >> / C<< $msg->play_uri($value) >>

Type: C<String>

Output only. The playback URI of the stitched content.

=item * C<< $msg->source_uri() >> / C<< $msg->source_uri($value) >>

Type: C<String>

URI of the media to stitch. For most use cases, you should create a
[VodConfig][google.cloud.video.stitcher.v1.VodConfig] with this information
rather than setting this field directly.

=item * C<< $msg->ad_tag_uri() >> / C<< $msg->ad_tag_uri($value) >>

Type: C<String>

Ad tag URI. For most use cases, you should create a
[VodConfig][google.cloud.video.stitcher.v1.VodConfig] with this information
rather than setting this field directly.

=item * C<< $msg->ad_tag_macro_map() >> / C<< $msg->ad_tag_macro_map($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::AdTagMacroMapEntry>)

Key value pairs for ad tag macro replacement, only available for VOD
sessions that do not implement Google Ad manager ad insertion. If the
specified ad tag URI has macros, this field provides the mapping to the
value that will replace the macro in the ad tag URI.

Macros are designated by square brackets, for example:

  Ad tag URI: `"https://doubleclick.google.com/ad/1?geo_id=[geoId]"`

  Ad tag macro map: `{"geoId": "123"}`

  Fully qualified ad tag:
  `"https://doubleclick.google.com/ad/1?geo_id=123"`

=item * C<< $msg->manifest_options() >> / C<< $msg->manifest_options($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions>)

Additional options that affect the output of the manifest.

=item * C<< $msg->asset_id() >> / C<< $msg->asset_id($value) >>

Type: C<String>

Output only. The generated ID of the VodSession's source media.

=item * C<< $msg->ad_tracking() >> / C<< $msg->ad_tracking($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::AdTracking>)

Required. Determines how the ad should be tracked.

=item * C<< $msg->gam_settings() >> / C<< $msg->gam_settings($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::GamSettings>)

This field should be set with appropriate values if GAM is being used for
ads.

=item * C<< $msg->vod_config() >> / C<< $msg->vod_config($value) >>

Type: C<String>

The resource name of the VOD config for this session, in the form of
`projects/{project}/locations/{location}/vodConfigs/{id}`.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials

Describes what was stitched into a VOD session's manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ad_breaks() >> / C<< $msg->ad_breaks($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak>)

List of ad breaks ordered by time.

=item * C<< $msg->session_content() >> / C<< $msg->session_content($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent>)

Information related to the content of the VOD session.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd

Metadata for an inserted ad in a VOD session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration in seconds of the ad.

=item * C<< $msg->companion_ads() >> / C<< $msg->companion_ads($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds>)

Metadata of companion ads associated with the ad.

=item * C<< $msg->activity_events() >> / C<< $msg->activity_events($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Events::Event>)

The list of progress tracking events for the ad break. These can be of
the following IAB types: `MUTE`, `UNMUTE`, `PAUSE`, `CLICK`,
`CLICK_THROUGH`, `REWIND`, `RESUME`, `ERROR`, `FULLSCREEN`,
`EXIT_FULLSCREEN`, `EXPAND`, `COLLAPSE`, `ACCEPT_INVITATION_LINEAR`,
`CLOSE_LINEAR`, `SKIP`.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent

Metadata for the entire stitched content in a VOD session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The total duration in seconds of the content including the ads stitched
in.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak

Metadata for an inserted ad break.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->progress_events() >> / C<< $msg->progress_events($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent>)

List of events that are expected to be triggered, ordered by time.

=item * C<< $msg->ads() >> / C<< $msg->ads($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd>)

Ordered list of ads stitched into the ad break.

=item * C<< $msg->end_time_offset() >> / C<< $msg->end_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Ad break end time in seconds relative to the start of the VOD asset.

=item * C<< $msg->start_time_offset() >> / C<< $msg->start_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Ad break start time in seconds relative to the start of the VOD asset.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession

Metadata for a live session. The session expires 5 minutes after the client
stops fetching the session's playlists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the live session, in the form of
`projects/{project}/locations/{location}/liveSessions/{id}`.

=item * C<< $msg->play_uri() >> / C<< $msg->play_uri($value) >>

Type: C<String>

Output only. The URI to play the live session's ad-stitched stream.

=item * C<< $msg->ad_tag_macros() >> / C<< $msg->ad_tag_macros($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::AdTagMacrosEntry>)

Key value pairs for ad tag macro replacement, only available for live
sessions that do not implement Google Ad manager ad insertion. If the
specified ad tag URI has macros, this field provides the mapping to the
value that will replace the macro in the ad tag URI.

Macros are designated by square brackets, for example:

  Ad tag URI: "https://doubleclick.google.com/ad/1?geo_id=[geoId]"

  Ad tag macros: `{"geoId": "123"}`

  Fully qualified ad tag:
  `"https://doubleclick.google.com/ad/1?geo_id=123"`

=item * C<< $msg->manifest_options() >> / C<< $msg->manifest_options($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions>)

Additional options that affect the output of the manifest.

=item * C<< $msg->gam_settings() >> / C<< $msg->gam_settings($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings>)

This field should be set with appropriate values if GAM is being used for
ads.

=item * C<< $msg->live_config() >> / C<< $msg->live_config($value) >>

Type: C<String>

Required. The resource name of the live config for this session, in the
form of `projects/{project}/locations/{location}/liveConfigs/{id}`.

=item * C<< $msg->ad_tracking() >> / C<< $msg->ad_tracking($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::AdTracking>)

Determines how the ad should be tracked. This overrides the value set in
the live config for this session.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions

Options for manifest generation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->include_renditions() >> / C<< $msg->include_renditions($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter>)

If specified, the output manifest will only return renditions matching the
specified filters.

=item * C<< $msg->bitrate_order() >> / C<< $msg->bitrate_order($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::ManifestOptions::OrderPolicy>)

If specified, the output manifest will orders the video and muxed
renditions by bitrate according to the ordering policy.

=back

=head3 Enum: ManifestOptions::OrderPolicy

=over 4

=item * C<ORDER_POLICY_UNSPECIFIED> => C<0>

=item * C<ASCENDING> => C<1>

=item * C<DESCENDING> => C<2>

=back

=head2 Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter

Filters for a video or muxed redition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bitrate_bps() >> / C<< $msg->bitrate_bps($value) >>

Type: C<Int32>

Bitrate in bits per second for the rendition. If set, only renditions with
the exact bitrate will match.

=item * C<< $msg->codecs() >> / C<< $msg->codecs($value) >>

Type: C<String>

Codecs for the rendition. If set, only renditions with the exact value
will match.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::Sessions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
