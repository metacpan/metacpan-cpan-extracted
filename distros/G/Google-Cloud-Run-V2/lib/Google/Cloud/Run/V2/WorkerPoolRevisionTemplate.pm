package Google::Cloud::Run::V2::WorkerPoolRevisionTemplate;

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
    eval { require Google::Cloud::Run::V2::K8sMin };
    eval { require Google::Cloud::Run::V2::Sandbox };
    eval { require Google::Cloud::Run::V2::VendorSettings };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvcnVuL3YyL3dvcmtlcl9wb29sX3JldmlzaW9uX3RlbXBsYXRlLnBy
b3RvEhNnb29nbGUuY2xvdWQucnVuLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiFnb29nbGUvY2xvdWQvcnVuL3YyL2s4
cy5taW4ucHJvdG8aIWdvb2dsZS9jbG91ZC9ydW4vdjIvc2FuZGJveC5wcm90bxopZ29vZ2xl
L2Nsb3VkL3J1bi92Mi92ZW5kb3Jfc2V0dGluZ3MucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9k
dXJhdGlvbi5wcm90byLhCgoaV29ya2VyUG9vbFJldmlzaW9uVGVtcGxhdGUSPwoIcmV2aXNp
b24YASABKAlCI+BBAfpBHQobcnVuLmdvb2dsZWFwaXMuY29tL1JldmlzaW9uUghyZXZpc2lv
bhJYCgZsYWJlbHMYAiADKAsyOy5nb29nbGUuY2xvdWQucnVuLnYyLldvcmtlclBvb2xSZXZp
c2lvblRlbXBsYXRlLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJnCgthbm5vdGF0aW9ucxgD
IAMoCzJALmdvb2dsZS5jbG91ZC5ydW4udjIuV29ya2VyUG9vbFJldmlzaW9uVGVtcGxhdGUu
QW5ub3RhdGlvbnNFbnRyeUID4EEBUgthbm5vdGF0aW9ucxJCCgp2cGNfYWNjZXNzGAQgASgL
Mh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5WcGNBY2Nlc3NCA+BBAVIJdnBjQWNjZXNzEiwKD3Nl
cnZpY2VfYWNjb3VudBgFIAEoCUID4EEBUg5zZXJ2aWNlQWNjb3VudBI+Cgpjb250YWluZXJz
GAYgAygLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5Db250YWluZXJSCmNvbnRhaW5lcnMSTAoJ
c2FuZGJveGVzGBMgASgLMikuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5TYW5kYm94Q29uZmlndXJh
dGlvbkID4EEBUglzYW5kYm94ZXMSOgoHdm9sdW1lcxgHIAMoCzIbLmdvb2dsZS5jbG91ZC5y
dW4udjIuVm9sdW1lQgPgQQFSB3ZvbHVtZXMSTQoOZW5jcnlwdGlvbl9rZXkYCCABKAlCJvpB
IwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5Ug1lbmNyeXB0aW9uS2V5EkgK
DHNlcnZpY2VfbWVzaBgJIAEoCzIgLmdvb2dsZS5jbG91ZC5ydW4udjIuU2VydmljZU1lc2hC
A+BBAVILc2VydmljZU1lc2gSgAEKIGVuY3J5cHRpb25fa2V5X3Jldm9jYXRpb25fYWN0aW9u
GAogASgOMjIuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5FbmNyeXB0aW9uS2V5UmV2b2NhdGlvbkFj
dGlvbkID4EEBUh1lbmNyeXB0aW9uS2V5UmV2b2NhdGlvbkFjdGlvbhJnCiBlbmNyeXB0aW9u
X2tleV9zaHV0ZG93bl9kdXJhdGlvbhgLIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
bkID4EEBUh1lbmNyeXB0aW9uS2V5U2h1dGRvd25EdXJhdGlvbhJLCg1ub2RlX3NlbGVjdG9y
GA0gASgLMiEuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5Ob2RlU2VsZWN0b3JCA+BBAVIMbm9kZVNl
bGVjdG9yEksKHWdwdV96b25hbF9yZWR1bmRhbmN5X2Rpc2FibGVkGBAgASgIQgPgQQFIAFIa
Z3B1Wm9uYWxSZWR1bmRhbmN5RGlzYWJsZWSIAQESGwoGY2xpZW50GBEgASgJQgPgQQFSBmNs
aWVudBIqCg5jbGllbnRfdmVyc2lvbhgSIAEoCUID4EEBUg1jbGllbnRWZXJzaW9uGjkKC0xh
YmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEa
PgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBQiAKHl9ncHVfem9uYWxfcmVkdW5kYW5jeV9kaXNhYmxlZEJnChdjb20uZ29v
Z2xlLmNsb3VkLnJ1bi52MkIfV29ya2VyUG9vbFJldmlzaW9uVGVtcGxhdGVQcm90b1ABWilj
bG91ZC5nb29nbGUuY29tL2dvL3J1bi9hcGl2Mi9ydW5wYjtydW5wYkqlJwoGEgQOAHYBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAArCgkKAgMDEgMVACsKCQoCAwQSAxYAMwoJCgIDBRIDFwAo
CggKAQgSAxkAQAoJCgIICxIDGQBACggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAQAoJ
CgIICBIDGwBACggKAQgSAxwAMAoJCgIIARIDHAAwCn0KAgQAEgQgAHYBGnEgV29ya2VyUG9v
bFJldmlzaW9uVGVtcGxhdGUgZGVzY3JpYmVzIHRoZSBkYXRhIGEgd29ya2VyIHBvb2wgcmV2
aXNpb24gc2hvdWxkCiBoYXZlIHdoZW4gY3JlYXRlZCBmcm9tIGEgdGVtcGxhdGUuCgoKCgME
AAESAyAIIgqYAQoEBAACABIEIwImBBqJASBPcHRpb25hbC4gVGhlIHVuaXF1ZSBuYW1lIGZv
ciB0aGUgcmV2aXNpb24uIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgaXQKIHdpbGwgYmUg
YXV0b21hdGljYWxseSBnZW5lcmF0ZWQgYmFzZWQgb24gdGhlIFdvcmtlclBvb2wgbmFtZS4K
CgwKBQQAAgAFEgMjAggKDAoFBAACAAESAyMJEQoMCgUEAAIAAxIDIxQVCg0KBQQAAgAIEgQj
FiYDCg8KCAQAAgAInAgAEgMkBCoKDgoHBAACAAifCBIDJQRNCsgFCgQEAAIBEgMzAkoaugUg
T3B0aW9uYWwuIFVuc3RydWN0dXJlZCBrZXkgdmFsdWUgbWFwIHRoYXQgY2FuIGJlIHVzZWQg
dG8gb3JnYW5pemUgYW5kCiBjYXRlZ29yaXplIG9iamVjdHMuIFVzZXItcHJvdmlkZWQgbGFi
ZWxzIGFyZSBzaGFyZWQgd2l0aCBHb29nbGUncyBiaWxsaW5nCiBzeXN0ZW0sIHNvIHRoZXkg
Y2FuIGJlIHVzZWQgdG8gZmlsdGVyLCBvciBicmVhayBkb3duIGJpbGxpbmcgY2hhcmdlcyBi
eQogdGVhbSwgY29tcG9uZW50LCBlbnZpcm9ubWVudCwgc3RhdGUsIGV0Yy4gRm9yIG1vcmUg
aW5mb3JtYXRpb24sIHZpc2l0CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3VyY2Ut
bWFuYWdlci9kb2NzL2NyZWF0aW5nLW1hbmFnaW5nLWxhYmVscyBvcgogaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL3J1bi9kb2NzL2NvbmZpZ3VyaW5nL2xhYmVscy4KCiBDbG91ZCBSdW4g
QVBJIHYyIGRvZXMgbm90IHN1cHBvcnQgbGFiZWxzIHdpdGggYHJ1bi5nb29nbGVhcGlzLmNv
bWAsCiBgY2xvdWQuZ29vZ2xlYXBpcy5jb21gLCBgc2VydmluZy5rbmF0aXZlLmRldmAsIG9y
IGBhdXRvc2NhbGluZy5rbmF0aXZlLmRldmAKIG5hbWVzcGFjZXMsIGFuZCB0aGV5IHdpbGwg
YmUgcmVqZWN0ZWQuIEFsbCBzeXN0ZW0gbGFiZWxzIGluIHYxIG5vdyBoYXZlIGEKIGNvcnJl
c3BvbmRpbmcgZmllbGQgaW4gdjIgV29ya2VyUG9vbFJldmlzaW9uVGVtcGxhdGUuCgoMCgUE
AAIBBhIDMwIVCgwKBQQAAgEBEgMzFhwKDAoFBAACAQMSAzMfIAoMCgUEAAIBCBIDMyFJCg8K
CAQAAgEInAgAEgMzIkgKrQQKBAQAAgISA0ACTxqfBCBPcHRpb25hbC4gVW5zdHJ1Y3R1cmVk
IGtleSB2YWx1ZSBtYXAgdGhhdCBtYXkgYmUgc2V0IGJ5IGV4dGVybmFsIHRvb2xzIHRvCiBz
dG9yZSBhbmQgYXJiaXRyYXJ5IG1ldGFkYXRhLiBUaGV5IGFyZSBub3QgcXVlcnlhYmxlIGFu
ZCBzaG91bGQgYmUKIHByZXNlcnZlZCB3aGVuIG1vZGlmeWluZyBvYmplY3RzLgoKIENsb3Vk
IFJ1biBBUEkgdjIgZG9lcyBub3Qgc3VwcG9ydCBhbm5vdGF0aW9ucyB3aXRoIGBydW4uZ29v
Z2xlYXBpcy5jb21gLAogYGNsb3VkLmdvb2dsZWFwaXMuY29tYCwgYHNlcnZpbmcua25hdGl2
ZS5kZXZgLCBvciBgYXV0b3NjYWxpbmcua25hdGl2ZS5kZXZgCiBuYW1lc3BhY2VzLCBhbmQg
dGhleSB3aWxsIGJlIHJlamVjdGVkLiBBbGwgc3lzdGVtIGFubm90YXRpb25zIGluIHYxIG5v
dwogaGF2ZSBhIGNvcnJlc3BvbmRpbmcgZmllbGQgaW4gdjIgV29ya2VyUG9vbFJldmlzaW9u
VGVtcGxhdGUuCgogVGhpcyBmaWVsZCBmb2xsb3dzIEt1YmVybmV0ZXMgYW5ub3RhdGlvbnMn
IG5hbWVzcGFjaW5nLCBsaW1pdHMsIGFuZAogcnVsZXMuCgoMCgUEAAICBhIDQAIVCgwKBQQA
AgIBEgNAFiEKDAoFBAACAgMSA0AkJQoMCgUEAAICCBIDQCZOCg8KCAQAAgIInAgAEgNAJ00K
qAEKBAQAAgMSA0UCRBqaASBPcHRpb25hbC4gVlBDIEFjY2VzcyBjb25maWd1cmF0aW9uIHRv
IHVzZSBmb3IgdGhpcyBSZXZpc2lvbi4gRm9yIG1vcmUKIGluZm9ybWF0aW9uLCB2aXNpdAog
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3J1bi9kb2NzL2NvbmZpZ3VyaW5nL2Nvbm5lY3Rp
bmctdnBjLgoKDAoFBAACAwYSA0UCCwoMCgUEAAIDARIDRQwWCgwKBQQAAgMDEgNFGRoKDAoF
BAACAwgSA0UbQwoPCggEAAIDCJwIABIDRRxCCrcCCgQEAAIEEgNLAkYaqQIgT3B0aW9uYWwu
IEVtYWlsIGFkZHJlc3Mgb2YgdGhlIElBTSBzZXJ2aWNlIGFjY291bnQgYXNzb2NpYXRlZCB3
aXRoIHRoZQogcmV2aXNpb24gb2YgdGhlIHNlcnZpY2UuIFRoZSBzZXJ2aWNlIGFjY291bnQg
cmVwcmVzZW50cyB0aGUgaWRlbnRpdHkgb2YgdGhlCiBydW5uaW5nIHJldmlzaW9uLCBhbmQg
ZGV0ZXJtaW5lcyB3aGF0IHBlcm1pc3Npb25zIHRoZSByZXZpc2lvbiBoYXMuIElmIG5vdAog
cHJvdmlkZWQsIHRoZSByZXZpc2lvbiB3aWxsIHVzZSB0aGUgcHJvamVjdCdzIGRlZmF1bHQg
c2VydmljZSBhY2NvdW50LgoKDAoFBAACBAUSA0sCCAoMCgUEAAIEARIDSwkYCgwKBQQAAgQD
EgNLGxwKDAoFBAACBAgSA0sdRQoPCggEAAIECJwIABIDSx5ECmIKBAQAAgUSA08CJBpVIEhv
bGRzIGxpc3Qgb2YgdGhlIGNvbnRhaW5lcnMgdGhhdCBkZWZpbmVzIHRoZSB1bml0IG9mIGV4
ZWN1dGlvbiBmb3IgdGhpcwogUmV2aXNpb24uCgoMCgUEAAIFBBIDTwIKCgwKBQQAAgUGEgNP
CxQKDAoFBAACBQESA08VHwoMCgUEAAIFAxIDTyIjCjUKBAQAAgYSA1ICTxooIE9wdGlvbmFs
LiBDb25maWd1cmF0aW9uIGZvciBzYW5kYm94ZXMuCgoMCgUEAAIGBhIDUgIWCgwKBQQAAgYB
EgNSFyAKDAoFBAACBgMSA1IjJQoMCgUEAAIGCBIDUiZOCg8KCAQAAgYInAgAEgNSJ00KSwoE
BAACBxIDVQJHGj4gT3B0aW9uYWwuIEEgbGlzdCBvZiBWb2x1bWVzIHRvIG1ha2UgYXZhaWxh
YmxlIHRvIGNvbnRhaW5lcnMuCgoMCgUEAAIHBBIDVQIKCgwKBQQAAgcGEgNVCxEKDAoFBAAC
BwESA1USGQoMCgUEAAIHAxIDVRwdCgwKBQQAAgcIEgNVHkYKDwoIBAACBwicCAASA1UfRQrE
AQoEBAACCBIEWgJcBRq1ASBBIHJlZmVyZW5jZSB0byBhIGN1c3RvbWVyIG1hbmFnZWQgZW5j
cnlwdGlvbiBrZXkgKENNRUspIHRvIHVzZSB0byBlbmNyeXB0CiB0aGlzIGNvbnRhaW5lciBp
bWFnZS4gRm9yIG1vcmUgaW5mb3JtYXRpb24sIGdvIHRvCiBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vcnVuL2RvY3Mvc2VjdXJpbmcvdXNpbmctY21lawoKDAoFBAACCAUSA1oCCAoMCgUE
AAIIARIDWgkXCgwKBQQAAggDEgNaGhsKDQoFBAACCAgSBFocXAQKDwoHBAACCAifCBIEWh1c
Awo7CgQEAAIJEgNfAkgaLiBPcHRpb25hbC4gRW5hYmxlcyBzZXJ2aWNlIG1lc2ggY29ubmVj
dGl2aXR5LgoKDAoFBAACCQYSA18CDQoMCgUEAAIJARIDXw4aCgwKBQQAAgkDEgNfHR4KDAoF
BAACCQgSA18fRwoPCggEAAIJCJwIABIDXyBGCk4KBAQAAgoSBGICYy8aQCBPcHRpb25hbC4g
VGhlIGFjdGlvbiB0byB0YWtlIGlmIHRoZSBlbmNyeXB0aW9uIGtleSBpcyByZXZva2VkLgoK
DAoFBAACCgYSA2ICHwoMCgUEAAIKARIDYiBACgwKBQQAAgoDEgNiQ0UKDAoFBAACCggSA2MG
LgoPCggEAAIKCJwIABIDYwctCp4BCgQEAAILEgRnAmgvGo8BIE9wdGlvbmFsLiBJZiBlbmNy
eXB0aW9uX2tleV9yZXZvY2F0aW9uX2FjdGlvbiBpcyBTSFVURE9XTiwgdGhlIGR1cmF0aW9u
CiBiZWZvcmUgc2h1dHRpbmcgZG93biBhbGwgaW5zdGFuY2VzLiBUaGUgbWluaW11bSBpbmNy
ZW1lbnQgaXMgMSBob3VyLgoKDAoFBAACCwYSA2cCGgoMCgUEAAILARIDZxs7CgwKBQQAAgsD
EgNnPkAKDAoFBAACCwgSA2gGLgoPCggEAAILCJwIABIDaActCkUKBAQAAgwSA2sCSxo4IE9w
dGlvbmFsLiBUaGUgbm9kZSBzZWxlY3RvciBmb3IgdGhlIHJldmlzaW9uIHRlbXBsYXRlLgoK
DAoFBAACDAYSA2sCDgoMCgUEAAIMARIDaw8cCgwKBQQAAgwDEgNrHyEKDAoFBAACDAgSA2si
SgoPCggEAAIMCJwIABIDayNJClcKBAQAAg0SBG4Cby8aSSBPcHRpb25hbC4gVHJ1ZSBpZiBH
UFUgem9uYWwgcmVkdW5kYW5jeSBpcyBkaXNhYmxlZCBvbiB0aGlzIHdvcmtlciBwb29sLgoK
DAoFBAACDQQSA24CCgoMCgUEAAINBRIDbgsPCgwKBQQAAg0BEgNuEC0KDAoFBAACDQMSA24w
MgoMCgUEAAINCBIDbwYuCg8KCAQAAg0InAgAEgNvBy0KQQoEBAACDhIDcgI+GjQgT3B0aW9u
YWwuIEFyYml0cmFyeSBpZGVudGlmaWVyIGZvciB0aGUgQVBJIGNsaWVudC4KCgwKBQQAAg4F
EgNyAggKDAoFBAACDgESA3IJDwoMCgUEAAIOAxIDchIUCgwKBQQAAg4IEgNyFT0KDwoIBAAC
DgicCAASA3IWPApJCgQEAAIPEgN1AkYaPCBPcHRpb25hbC4gQXJiaXRyYXJ5IHZlcnNpb24g
aWRlbnRpZmllciBmb3IgdGhlIEFQSSBjbGllbnQuCgoMCgUEAAIPBRIDdQIICgwKBQQAAg8B
EgN1CRcKDAoFBAACDwMSA3UaHAoMCgUEAAIPCBIDdR1FCg8KCAQAAg8InAgAEgN1HkRiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate ===
    # Fields for WorkerPoolRevisionTemplate
    # Field: revision Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.run.v2.WorkerPoolRevisionTemplate.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.WorkerPoolRevisionTemplate.AnnotationsEntry)
    # Field: vpc_access Type: 11 (.google.cloud.run.v2.VpcAccess)
    # Field: service_account Type: 9 ()
    # Field: containers Type: 11 (.google.cloud.run.v2.Container)
    # Field: sandboxes Type: 11 (.google.cloud.run.v2.SandboxConfiguration)
    # Field: volumes Type: 11 (.google.cloud.run.v2.Volume)
    # Field: encryption_key Type: 9 ()
    # Field: service_mesh Type: 11 (.google.cloud.run.v2.ServiceMesh)
    # Field: encryption_key_revocation_action Type: 14 (.google.cloud.run.v2.EncryptionKeyRevocationAction)
    # Field: encryption_key_shutdown_duration Type: 11 (.google.protobuf.Duration)
    # Field: node_selector Type: 11 (.google.cloud.run.v2.NodeSelector)
    # Field: gpu_zonal_redundancy_disabled Type: 8 ()
    # Field: client Type: 9 ()
    # Field: client_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::WorkerPoolRevisionTemplate - Compiled Protocol Buffers messages for google/cloud/run/v2/worker_pool_revision_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::WorkerPoolRevisionTemplate;

    my $msg = Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate->new({
        revision => $revision,
        labels => $labels,
        annotations => $annotations,
        vpc_access => $vpc_access,
    });

    # Read or update a field
    my $val = $msg->revision();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/worker_pool_revision_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate

WorkerPoolRevisionTemplate describes the data a worker pool revision should
have when created from a template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Optional. The unique name for the revision. If this field is omitted, it
will be automatically generated based on the WorkerPool name.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate::LabelsEntry>)

Optional. Unstructured key value map that can be used to organize and
categorize objects. User-provided labels are shared with Google's billing
system, so they can be used to filter, or break down billing charges by
team, component, environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels.

Cloud Run API v2 does not support labels with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system labels in v1 now have a
corresponding field in v2 WorkerPoolRevisionTemplate.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::WorkerPoolRevisionTemplate::AnnotationsEntry>)

Optional. Unstructured key value map that may be set by external tools to
store and arbitrary metadata. They are not queryable and should be
preserved when modifying objects.

Cloud Run API v2 does not support annotations with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system annotations in v1 now
have a corresponding field in v2 WorkerPoolRevisionTemplate.

This field follows Kubernetes annotations' namespacing, limits, and
rules.

=item * C<< $msg->vpc_access() >> / C<< $msg->vpc_access($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess>)

Optional. VPC Access configuration to use for this Revision. For more
information, visit
https://cloud.google.com/run/docs/configuring/connecting-vpc.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Email address of the IAM service account associated with the
revision of the service. The service account represents the identity of the
running revision, and determines what permissions the revision has. If not
provided, the revision will use the project's default service account.

=item * C<< $msg->containers() >> / C<< $msg->containers($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Container>)

Holds list of the containers that defines the unit of execution for this
Revision.

=item * C<< $msg->sandboxes() >> / C<< $msg->sandboxes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxConfiguration>)

Optional. Configuration for sandboxes.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Volume>)

Optional. A list of Volumes to make available to containers.

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<String>

A reference to a customer managed encryption key (CMEK) to use to encrypt
this container image. For more information, go to
https://cloud.google.com/run/docs/securing/using-cmek

=item * C<< $msg->service_mesh() >> / C<< $msg->service_mesh($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::ServiceMesh>)

Optional. Enables service mesh connectivity.

=item * C<< $msg->encryption_key_revocation_action() >> / C<< $msg->encryption_key_revocation_action($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::EncryptionKeyRevocationAction>)

Optional. The action to take if the encryption key is revoked.

=item * C<< $msg->encryption_key_shutdown_duration() >> / C<< $msg->encryption_key_shutdown_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. If encryption_key_revocation_action is SHUTDOWN, the duration
before shutting down all instances. The minimum increment is 1 hour.

=item * C<< $msg->node_selector() >> / C<< $msg->node_selector($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::NodeSelector>)

Optional. The node selector for the revision template.

=item * C<< $msg->gpu_zonal_redundancy_disabled() >> / C<< $msg->gpu_zonal_redundancy_disabled($value) >>

Type: C<Bool>

Optional. True if GPU zonal redundancy is disabled on this worker pool.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Optional. Arbitrary identifier for the API client.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Optional. Arbitrary version identifier for the API client.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::WorkerPoolRevisionTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
