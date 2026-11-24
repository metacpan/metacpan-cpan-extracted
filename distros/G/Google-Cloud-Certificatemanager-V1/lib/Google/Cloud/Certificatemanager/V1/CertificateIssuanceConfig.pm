package Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvY2VydGlmaWNhdGVtYW5hZ2VyL3YxL2NlcnRpZmljYXRlX2lzc3Vh
bmNlX2NvbmZpZy5wcm90bxIiZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MRof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYv
ZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLtAQol
TGlzdENlcnRpZmljYXRlSXNzdWFuY2VDb25maWdzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlC
KeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSIAoJ
cGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BB
AVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkY
BSABKAlCA+BBAVIHb3JkZXJCeSLzAQomTGlzdENlcnRpZmljYXRlSXNzdWFuY2VDb25maWdz
UmVzcG9uc2USfwocY2VydGlmaWNhdGVfaXNzdWFuY2VfY29uZmlncxgBIAMoCzI9Lmdvb2ds
ZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEuQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZp
Z1IaY2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJ+CiNH
ZXRDZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnUmVxdWVzdBJXCgRuYW1lGAEgASgJQkPgQQL6
QT0KO2NlcnRpZmljYXRlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9DZXJ0aWZpY2F0ZUlzc3Vh
bmNlQ29uZmlnUgRuYW1lIroCCiZDcmVhdGVDZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnUmVx
dWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29t
L0xvY2F0aW9uUgZwYXJlbnQSSAoeY2VydGlmaWNhdGVfaXNzdWFuY2VfY29uZmlnX2lkGAIg
ASgJQgPgQQJSG2NlcnRpZmljYXRlSXNzdWFuY2VDb25maWdJZBKCAQobY2VydGlmaWNhdGVf
aXNzdWFuY2VfY29uZmlnGAMgASgLMj0uZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdl
ci52MS5DZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnQgPgQQJSGWNlcnRpZmljYXRlSXNzdWFu
Y2VDb25maWci7wEKJlVwZGF0ZUNlcnRpZmljYXRlSXNzdWFuY2VDb25maWdSZXF1ZXN0EoIB
ChtjZXJ0aWZpY2F0ZV9pc3N1YW5jZV9jb25maWcYASABKAsyPS5nb29nbGUuY2xvdWQuY2Vy
dGlmaWNhdGVtYW5hZ2VyLnYxLkNlcnRpZmljYXRlSXNzdWFuY2VDb25maWdCA+BBAlIZY2Vy
dGlmaWNhdGVJc3N1YW5jZUNvbmZpZxJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzayKBAQomRGVsZXRlQ2VydGlmaWNh
dGVJc3N1YW5jZUNvbmZpZ1JlcXVlc3QSVwoEbmFtZRgBIAEoCUJD4EEC+kE9CjtjZXJ0aWZp
Y2F0ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ1IE
bmFtZSLCDAoZQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQhS
BG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSZgoGbGFiZWxzGAQgAygLMkkuZ29vZ2xl
LmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MS5DZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmln
LkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxIlCgtkZXNjcmlwdGlvbhgFIAEoCUID4EEBUgtk
ZXNjcmlwdGlvbhKfAQocY2VydGlmaWNhdGVfYXV0aG9yaXR5X2NvbmZpZxgGIAEoCzJYLmdv
b2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEuQ2VydGlmaWNhdGVJc3N1YW5jZUNv
bmZpZy5DZXJ0aWZpY2F0ZUF1dGhvcml0eUNvbmZpZ0ID4EECUhpjZXJ0aWZpY2F0ZUF1dGhv
cml0eUNvbmZpZxI6CghsaWZldGltZRgHIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
bkID4EECUghsaWZldGltZRJBChpyb3RhdGlvbl93aW5kb3dfcGVyY2VudGFnZRgIIAEoBUID
4EECUhhyb3RhdGlvbldpbmRvd1BlcmNlbnRhZ2USdAoNa2V5X2FsZ29yaXRobRgJIAEoDjJK
Lmdvb2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEuQ2VydGlmaWNhdGVJc3N1YW5j
ZUNvbmZpZy5LZXlBbGdvcml0aG1CA+BBAlIMa2V5QWxnb3JpdGhtEmYKBHRhZ3MYCiADKAsy
Ry5nb29nbGUuY2xvdWQuY2VydGlmaWNhdGVtYW5hZ2VyLnYxLkNlcnRpZmljYXRlSXNzdWFu
Y2VDb25maWcuVGFnc0VudHJ5QgngQQTgQQXgQQFSBHRhZ3Ma2wIKGkNlcnRpZmljYXRlQXV0
aG9yaXR5Q29uZmlnEs0BCiRjZXJ0aWZpY2F0ZV9hdXRob3JpdHlfc2VydmljZV9jb25maWcY
ASABKAsyei5nb29nbGUuY2xvdWQuY2VydGlmaWNhdGVtYW5hZ2VyLnYxLkNlcnRpZmljYXRl
SXNzdWFuY2VDb25maWcuQ2VydGlmaWNhdGVBdXRob3JpdHlDb25maWcuQ2VydGlmaWNhdGVB
dXRob3JpdHlTZXJ2aWNlQ29uZmlnSABSIWNlcnRpZmljYXRlQXV0aG9yaXR5U2VydmljZUNv
bmZpZxplCiFDZXJ0aWZpY2F0ZUF1dGhvcml0eVNlcnZpY2VDb25maWcSQAoHY2FfcG9vbBgB
IAEoCUIn4EEC+kEhCh9wcml2YXRlY2EuZ29vZ2xlYXBpcy5jb20vQ2FQb29sUgZjYVBvb2xC
BgoEa2luZBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEo
CVIFdmFsdWU6AjgBGjcKCVRhZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBIksKDEtleUFsZ29yaXRobRIdChlLRVlfQUxHT1JJVEhNX1VOU1BF
Q0lGSUVEEAASDAoIUlNBXzIwNDgQARIOCgpFQ0RTQV9QMjU2EAQ62gHqQdYBCjtjZXJ0aWZp
Y2F0ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZxJg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NlcnRpZmljYXRlSXNz
dWFuY2VDb25maWdzL3tjZXJ0aWZpY2F0ZV9pc3N1YW5jZV9jb25maWd9KhpjZXJ0aWZpY2F0
ZUlzc3VhbmNlQ29uZmlnczIZY2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ0LzAgomY29tLmdv
b2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjFCHkNlcnRpZmljYXRlSXNzdWFuY2VD
b25maWdQcm90b1ABWlZjbG91ZC5nb29nbGUuY29tL2dvL2NlcnRpZmljYXRlbWFuYWdlci9h
cGl2MS9jZXJ0aWZpY2F0ZW1hbmFnZXJwYjtjZXJ0aWZpY2F0ZW1hbmFnZXJwYqoCIkdvb2ds
ZS5DbG91ZC5DZXJ0aWZpY2F0ZU1hbmFnZXIuVjHKAiJHb29nbGVcQ2xvdWRcQ2VydGlmaWNh
dGVNYW5hZ2VyXFYx6gIlR29vZ2xlOjpDbG91ZDo6Q2VydGlmaWNhdGVNYW5hZ2VyOjpWMepB
XAofcHJpdmF0ZWNhLmdvb2dsZWFwaXMuY29tL0NhUG9vbBI5cHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NhUG9vbHMve2NhX3Bvb2x9Suc8CgcSBQ4A4wEBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAAoCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYAD8K
CQoCCCUSAxgAPwoICgEIEgMZAG0KCQoCCAsSAxkAbQoICgEIEgMaACIKCQoCCAoSAxoAIgoI
CgEIEgMbAD8KCQoCCAgSAxsAPwoICgEIEgMcAD8KCQoCCAESAxwAPwoICgEIEgMdAD8KCQoC
CCkSAx0APwoICgEIEgMeAD4KCQoCCC0SAx4APgoJCgEIEgQfACICCgwKBAidCAASBB8AIgIK
RgoCBAASBCUAPwEaOiBSZXF1ZXN0IGZvciB0aGUgYExpc3RDZXJ0aWZpY2F0ZUlzc3VhbmNl
Q29uZmlnc2AgbWV0aG9kLgoKCgoDBAABEgMlCC0KkwEKBAQAAgASBCgCLQQahAEgUmVxdWly
ZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBmcm9tIHdoaWNoIHRoZSBjZXJ0aWZpY2F0
ZSBzaG91bGQgYmUKIGxpc3RlZCwgc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3Rz
LyovbG9jYXRpb25zLypgLgoKDAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkPCgwKBQQAAgAD
EgMoEhMKDQoFBAACAAgSBCgULQMKDwoIBAACAAicCAASAykEKgoPCgcEAAIACJ8IEgQqBCwF
ClIKBAQAAgESAzACPxpFIE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBjZXJ0aWZpY2F0
ZSBjb25maWdzIHRvIHJldHVybiBwZXIgY2FsbC4KCgwKBQQAAgEFEgMwAgcKDAoFBAACAQES
AzAIEQoMCgUEAAIBAxIDMBQVCgwKBQQAAgEIEgMwFj4KDwoIBAACAQicCAASAzAXPQr2AQoE
BAACAhIDNgJBGugBIE9wdGlvbmFsLiBUaGUgdmFsdWUgcmV0dXJuZWQgYnkgdGhlIGxhc3QK
IGBMaXN0Q2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ3NSZXNwb25zZWAuIEluZGljYXRlcyB0
aGF0IHRoaXMgaXMgYQogY29udGludWF0aW9uIG9mIGEgcHJpb3IgYExpc3RDZXJ0aWZpY2F0
ZUlzc3VhbmNlQ29uZmlnc2AgY2FsbCwgYW5kIHRoYXQgdGhlCiBzeXN0ZW0gc2hvdWxkIHJl
dHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoMCgUEAAICBRIDNgIICgwKBQQAAgIBEgM2
CRMKDAoFBAACAgMSAzYWFwoMCgUEAAICCBIDNhhACg8KCAQAAgIInAgAEgM2GT8KWQoEBAAC
AxIDOQI9GkwgT3B0aW9uYWwuIEZpbHRlciBleHByZXNzaW9uIHRvIHJlc3RyaWN0IHRoZSBD
ZXJ0aWZpY2F0ZXMgQ29uZmlncyByZXR1cm5lZC4KCgwKBQQAAgMFEgM5AggKDAoFBAACAwES
AzkJDwoMCgUEAAIDAxIDORITCgwKBQQAAgMIEgM5FDwKDwoIBAACAwicCAASAzkVOwrgAQoE
BAACBBIDPgI/GtIBIE9wdGlvbmFsLiBBIGxpc3Qgb2YgQ2VydGlmaWNhdGUgQ29uZmlnIGZp
ZWxkIG5hbWVzIHVzZWQgdG8gc3BlY2lmeSB0aGUKIG9yZGVyIG9mIHRoZSByZXR1cm5lZCBy
ZXN1bHRzLiBUaGUgZGVmYXVsdCBzb3J0aW5nIG9yZGVyIGlzIGFzY2VuZGluZy4gVG8KIHNw
ZWNpZnkgZGVzY2VuZGluZyBvcmRlciBmb3IgYSBmaWVsZCwgYWRkIGEgc3VmZml4IGAiIGRl
c2MiYC4KCgwKBQQAAgQFEgM+AggKDAoFBAACBAESAz4JEQoMCgUEAAIEAxIDPhQVCgwKBQQA
AgQIEgM+Fj4KDwoIBAACBAicCAASAz4XPQpHCgIEARIEQgBNARo7IFJlc3BvbnNlIGZvciB0
aGUgYExpc3RDZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnc2AgbWV0aG9kLgoKCgoDBAEBEgNC
CC4KRQoEBAECABIDRAJGGjggQSBsaXN0IG9mIGNlcnRpZmljYXRlIGNvbmZpZ3MgZm9yIHRo
ZSBwYXJlbnQgcmVzb3VyY2UuCgoMCgUEAQIABBIDRAIKCgwKBQQBAgAGEgNECyQKDAoFBAEC
AAESA0QlQQoMCgUEAQIAAxIDRERFCugBCgQEAQIBEgNJAh0a2gEgSWYgdGhlcmUgbWlnaHQg
YmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2Us
IHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQg
c2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1
ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tlbmAuCgoMCgUEAQIBBRIDSQII
CgwKBQQBAgEBEgNJCRgKDAoFBAECAQMSA0kbHAozCgQEAQICEgNMAiIaJiBMb2NhdGlvbnMg
dGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCgwKBQQBAgIEEgNMAgoKDAoFBAECAgUSA0wL
EQoMCgUEAQICARIDTBIdCgwKBQQBAgIDEgNMICEKRAoCBAISBFAAWQEaOCBSZXF1ZXN0IGZv
ciB0aGUgYEdldENlcnRpZmljYXRlSXNzdWFuY2VDb25maWdgIG1ldGhvZC4KCgoKAwQCARID
UAgrCp8BCgQEAgIAEgRTAlgEGpABIFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIGNlcnRpZmlj
YXRlIGlzc3VhbmNlIGNvbmZpZyB0byBkZXNjcmliZS4gTXVzdCBiZSBpbgogdGhlIGZvcm1h
dCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlncy8q
YC4KCgwKBQQCAgAFEgNTAggKDAoFBAICAAESA1MJDQoMCgUEAgIAAxIDUxARCg0KBQQCAgAI
EgRTElgDCg8KCAQCAgAInAgAEgNUBCoKDwoHBAICAAifCBIEVQRXBQpHCgIEAxIEXABtARo7
IFJlcXVlc3QgZm9yIHRoZSBgQ3JlYXRlQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ2AgbWV0
aG9kLgoKCgoDBAMBEgNcCC4KggEKBAQDAgASBF8CZAQadCBSZXF1aXJlZC4gVGhlIHBhcmVu
dCByZXNvdXJjZSBvZiB0aGUgY2VydGlmaWNhdGUgaXNzdWFuY2UgY29uZmlnLiBNdXN0IGJl
CiBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qYC4KCgwKBQQDAgAFEgNf
AggKDAoFBAMCAAESA18JDwoMCgUEAwIAAxIDXxITCg0KBQQDAgAIEgRfFGQDCg8KCAQDAgAI
nAgAEgNgBCoKDwoHBAMCAAifCBIEYQRjBQpJCgQEAwIBEgRnAmgvGjsgUmVxdWlyZWQuIEEg
dXNlci1wcm92aWRlZCBuYW1lIG9mIHRoZSBjZXJ0aWZpY2F0ZSBjb25maWcuCgoMCgUEAwIB
BRIDZwIICgwKBQQDAgEBEgNnCScKDAoFBAMCAQMSA2cqKwoMCgUEAwIBCBIDaAYuCg8KCAQD
AgEInAgAEgNoBy0KVAoEBAMCAhIEawJsLxpGIFJlcXVpcmVkLiBBIGRlZmluaXRpb24gb2Yg
dGhlIGNlcnRpZmljYXRlIGlzc3VhbmNlIGNvbmZpZyB0byBjcmVhdGUuCgoMCgUEAwICBhID
awIbCgwKBQQDAgIBEgNrHDcKDAoFBAMCAgMSA2s6OwoMCgUEAwICCBIDbAYuCg8KCAQDAgII
nAgAEgNsBy0KRwoCBAQSBHAAegEaOyBSZXF1ZXN0IGZvciB0aGUgYFVwZGF0ZUNlcnRpZmlj
YXRlSXNzdWFuY2VDb25maWdgIG1ldGhvZC4KCgoKAwQEARIDcAguClQKBAQEAgASBHICcy8a
RiBSZXF1aXJlZC4gQSBkZWZpbml0aW9uIG9mIHRoZSBjZXJ0aWZpY2F0ZSBpc3N1YW5jZSBj
b25maWcgdG8gdXBkYXRlLgoKDAoFBAQCAAYSA3ICGwoMCgUEBAIAARIDchw3CgwKBQQEAgAD
EgNyOjsKDAoFBAQCAAgSA3MGLgoPCggEBAIACJwIABIDcwctCsIBCgQEBAIBEgR4AnkvGrMB
IFJlcXVpcmVkLiBUaGUgdXBkYXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVzb3VyY2UuIEZv
ciB0aGUgYEZpZWxkTWFza2AKIGRlZmluaXRpb24sIHNlZQogaHR0cHM6Ly9kZXZlbG9wZXJz
Lmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJv
dG9idWYjZmllbGRtYXNrLgoKDAoFBAQCAQYSA3gCGwoMCgUEBAIBARIDeBwnCgwKBQQEAgED
EgN4KisKDAoFBAQCAQgSA3kGLgoPCggEBAIBCJwIABIDeQctCkgKAgQFEgV9AIYBARo7IFJl
cXVlc3QgZm9yIHRoZSBgRGVsZXRlQ2VydGlmaWNhdGVJc3N1YW5jZUNvbmZpZ2AgbWV0aG9k
LgoKCgoDBAUBEgN9CC4KnwEKBAQFAgASBoABAoUBBBqOASBSZXF1aXJlZC4gQSBuYW1lIG9m
IHRoZSBjZXJ0aWZpY2F0ZSBpc3N1YW5jZSBjb25maWcgdG8gZGVsZXRlLiBNdXN0IGJlIGlu
CiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NlcnRpZmljYXRlSXNzdWFu
Y2VDb25maWdzLypgLgoKDQoFBAUCAAUSBIABAggKDQoFBAUCAAESBIABCQ0KDQoFBAUCAAMS
BIABEBEKDwoFBAUCAAgSBoABEoUBAwoQCggEBQIACJwIABIEgQEEKgoRCgcEBQIACJ8IEgaC
AQSEAQUKWgoCBAYSBokBAOMBARpMIENlcnRpZmljYXRlSXNzdWFuY2VDb25maWcgc3BlY2lm
aWVzIGhvdyB0byBpc3N1ZSBhbmQgbWFuYWdlIGEgY2VydGlmaWNhdGUuCgoLCgMEBgESBIkB
CCEKDQoDBAYHEgaKAQKPAQQKDwoFBAYHnQgSBooBAo8BBAqAAQoEBAYDABIGkwECpwEDGnAg
VGhlIENBIHRoYXQgaXNzdWVzIHRoZSB3b3JrbG9hZCBjZXJ0aWZpY2F0ZS4gSXQgaW5jbHVk
ZXMgQ0EgYWRkcmVzcywgdHlwZSwKIGF1dGhlbnRpY2F0aW9uIHRvIENBIHNlcnZpY2UsIGV0
Yy4KCg0KBQQGAwABEgSTAQokCkgKBgQGAwADABIGlQEEnwEFGjYgQ29udGFpbnMgaW5mb3Jt
YXRpb24gcmVxdWlyZWQgdG8gY29udGFjdCBDQSBzZXJ2aWNlLgoKDwoHBAYDAAMAARIElQEM
LQrSAQoIBAYDAAMAAgASBpkBBp4BCBq9ASBSZXF1aXJlZC4gQSBDQSBwb29sIHJlc291cmNl
IHVzZWQgdG8gaXNzdWUgYSBjZXJ0aWZpY2F0ZS4KIFRoZSBDQSBwb29sIHN0cmluZyBoYXMg
YSByZWxhdGl2ZSByZXNvdXJjZSBwYXRoIGZvbGxvd2luZyB0aGUgZm9ybQogInByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jYVBvb2xzL3tjYV9wb29sfSIuCgoR
CgkEBgMAAwACAAUSBJkBBgwKEQoJBAYDAAMAAgABEgSZAQ0UChEKCQQGAwADAAIAAxIEmQEX
GAoTCgkEBgMAAwACAAgSBpkBGZ4BBwoUCgwEBgMAAwACAAicCAASBJoBCC4KFQoLBAYDAAMA
AgAInwgSBpsBCJ0BCQoqCgYEBgMACAASBqIBBKYBBRoYIFRoZSBraW5kIG9mIENBIGNvbmZp
Zy4KCg8KBwQGAwAIAAESBKIBCg4KQAoGBAYDAAIAEgakAQalAQwaLiBEZWZpbmVzIGEgQ2Vy
dGlmaWNhdGVBdXRob3JpdHlTZXJ2aWNlQ29uZmlnLgoKDwoHBAYDAAIABhIEpAEGJwoPCgcE
BgMAAgABEgSkAShMCg8KBwQGAwACAAMSBKUBCgsKMgoEBAYEABIGqgECswEDGiIgVGhlIHR5
cGUgb2Yga2V5cGFpciB0byBnZW5lcmF0ZS4KCg0KBQQGBAABEgSqAQcTCiwKBgQGBAACABIE
rAEEIhocIFVuc3BlY2lmaWVkIGtleSBhbGdvcml0aG0uCgoPCgcEBgQAAgABEgSsAQQdCg8K
BwQGBAACAAISBKwBICEKOAoGBAYEAAIBEgSvAQQRGiggU3BlY2lmaWVzIFJTQSB3aXRoIGEg
MjA0OC1iaXQgbW9kdWx1cy4KCg8KBwQGBAACAQESBK8BBAwKDwoHBAYEAAIBAhIErwEPEAoy
CgYEBgQAAgISBLIBBBMaIiBTcGVjaWZpZXMgRUNEU0Egd2l0aCBjdXJ2ZSBQMjU2LgoKDwoH
BAYEAAICARIEsgEEDgoPCgcEBgQAAgICEgSyARESCtcBCgQEBgIAEgS4AQI9GsgBIElkZW50
aWZpZXIuIEEgdXNlci1kZWZpbmVkIG5hbWUgb2YgdGhlIGNlcnRpZmljYXRlIGlzc3VhbmNl
IGNvbmZpZy4KIENlcnRpZmljYXRlSXNzdWFuY2VDb25maWcgbmFtZXMgbXVzdCBiZSB1bmlx
dWUgZ2xvYmFsbHkgYW5kIG1hdGNoIHBhdHRlcm4KIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NlcnRpZmljYXRlSXNzdWFuY2VDb25maWdzLypgLgoKDQoFBAYCAAUSBLgBAggKDQoFBAYC
AAESBLgBCQ0KDQoFBAYCAAMSBLgBEBEKDQoFBAYCAAgSBLgBEjwKEAoIBAYCAAicCAASBLgB
EzsKVQoEBAYCARIGuwECvAEyGkUgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lc3Rh
bXAgb2YgYSBDZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnLgoKDQoFBAYCAQYSBLsBAhsKDQoF
BAYCAQESBLsBHCcKDQoFBAYCAQMSBLsBKisKDQoFBAYCAQgSBLwBBjEKEAoIBAYCAQicCAAS
BLwBBzAKWAoEBAYCAhIGvwECwAEyGkggT3V0cHV0IG9ubHkuIFRoZSBsYXN0IHVwZGF0ZSB0
aW1lc3RhbXAgb2YgYSBDZXJ0aWZpY2F0ZUlzc3VhbmNlQ29uZmlnLgoKDQoFBAYCAgYSBL8B
AhsKDQoFBAYCAgESBL8BHCcKDQoFBAYCAgMSBL8BKisKDQoFBAYCAggSBMABBjEKEAoIBAYC
AgicCAASBMABBzAKVAoEBAYCAxIEwwECShpGIE9wdGlvbmFsLiBTZXQgb2YgbGFiZWxzIGFz
c29jaWF0ZWQgd2l0aCBhIENlcnRpZmljYXRlSXNzdWFuY2VDb25maWcuCgoNCgUEBgIDBhIE
wwECFQoNCgUEBgIDARIEwwEWHAoNCgUEBgIDAxIEwwEfIAoNCgUEBgIDCBIEwwEhSQoQCggE
BgIDCJwIABIEwwEiSAplCgQEBgIEEgTHAQJCGlcgT3B0aW9uYWwuIE9uZSBvciBtb3JlIHBh
cmFncmFwaHMgb2YgdGV4dCBkZXNjcmlwdGlvbiBvZiBhCiBDZXJ0aWZpY2F0ZUlzc3VhbmNl
Q29uZmlnLgoKDQoFBAYCBAUSBMcBAggKDQoFBAYCBAESBMcBCRQKDQoFBAYCBAMSBMcBFxgK
DQoFBAYCBAgSBMcBGUEKEAoIBAYCBAicCAASBMcBGkAKjgEKBAQGAgUSBssBAswBLxp+IFJl
cXVpcmVkLiBUaGUgQ0EgdGhhdCBpc3N1ZXMgdGhlIHdvcmtsb2FkIGNlcnRpZmljYXRlLiBJ
dCBpbmNsdWRlcyB0aGUgQ0EKIGFkZHJlc3MsIHR5cGUsIGF1dGhlbnRpY2F0aW9uIHRvIENB
IHNlcnZpY2UsIGV0Yy4KCg0KBQQGAgUGEgTLAQIcCg0KBQQGAgUBEgTLAR05Cg0KBQQGAgUD
EgTLATw9Cg0KBQQGAgUIEgTMAQYuChAKCAQGAgUInAgAEgTMAQctCkQKBAQGAgYSBs8BAtAB
Lxo0IFJlcXVpcmVkLiBXb3JrbG9hZCBjZXJ0aWZpY2F0ZSBsaWZldGltZSByZXF1ZXN0ZWQu
CgoNCgUEBgIGBhIEzwECGgoNCgUEBgIGARIEzwEbIwoNCgUEBgIGAxIEzwEmJwoNCgUEBgIG
CBIE0AEGLgoQCggEBgIGCJwIABIE0AEHLQq0AQoEBAYCBxIE1QECUBqlASBSZXF1aXJlZC4g
U3BlY2lmaWVzIHRoZSBwZXJjZW50YWdlIG9mIGVsYXBzZWQgdGltZSBvZiB0aGUgY2VydGlm
aWNhdGUKIGxpZmV0aW1lIHRvIHdhaXQgYmVmb3JlIHJlbmV3aW5nIHRoZSBjZXJ0aWZpY2F0
ZS4gTXVzdCBiZSBhIG51bWJlciBiZXR3ZWVuCiAxLTk5LCBpbmNsdXNpdmUuCgoNCgUEBgIH
BRIE1QECBwoNCgUEBgIHARIE1QEIIgoNCgUEBgIHAxIE1QElJgoNCgUEBgIHCBIE1QEnTwoQ
CggEBgIHCJwIABIE1QEoTgpTCgQEBgIIEgTYAQJKGkUgUmVxdWlyZWQuIFRoZSBrZXkgYWxn
b3JpdGhtIHRvIHVzZSB3aGVuIGdlbmVyYXRpbmcgdGhlIHByaXZhdGUga2V5LgoKDQoFBAYC
CAYSBNgBAg4KDQoFBAYCCAESBNgBDxwKDQoFBAYCCAMSBNgBHyAKDQoFBAYCCAgSBNgBIUkK
EAoIBAYCCAicCAASBNgBIkgKtwEKBAQGAgkSBt4BAuIBBBqmASBPcHRpb25hbC4gSW5wdXQg
b25seS4gSW1tdXRhYmxlLiBUYWcga2V5cy92YWx1ZXMgZGlyZWN0bHkgYm91bmQgdG8gdGhp
cwogcmVzb3VyY2UuIEZvciBleGFtcGxlOgogICAiMTIzL2Vudmlyb25tZW50IjogInByb2R1
Y3Rpb24iLAogICAiMTIzL2Nvc3RDZW50ZXIiOiAibWFya2V0aW5nIgoKDQoFBAYCCQYSBN4B
AhUKDQoFBAYCCQESBN4BFhoKDQoFBAYCCQMSBN4BHR8KDwoFBAYCCQgSBt4BIOIBAwoQCggE
BgIJCJwIABIE3wEELAoQCggEBgIJCJwIARIE4AEEKwoQCggEBgIJCJwIAhIE4QEEKmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest ===
    # Fields for ListCertificateIssuanceConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsResponse ===
    # Fields for ListCertificateIssuanceConfigsResponse
    # Field: certificate_issuance_configs Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::GetCertificateIssuanceConfigRequest ===
    # Fields for GetCertificateIssuanceConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CreateCertificateIssuanceConfigRequest ===
    # Fields for CreateCertificateIssuanceConfigRequest
    # Field: parent Type: 9 ()
    # Field: certificate_issuance_config_id Type: 9 ()
    # Field: certificate_issuance_config Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig)

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::UpdateCertificateIssuanceConfigRequest ===
    # Fields for UpdateCertificateIssuanceConfigRequest
    # Field: certificate_issuance_config Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::DeleteCertificateIssuanceConfigRequest ===
    # Fields for DeleteCertificateIssuanceConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig ===
    # Fields for CertificateIssuanceConfig
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: certificate_authority_config Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig.CertificateAuthorityConfig)
    # Field: lifetime Type: 11 (.google.protobuf.Duration)
    # Field: rotation_window_percentage Type: 5 ()
    # Field: key_algorithm Type: 14 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig.KeyAlgorithm)
    # Field: tags Type: 11 (.google.cloud.certificatemanager.v1.CertificateIssuanceConfig.TagsEntry)

# Enum: CertificateIssuanceConfig::KeyAlgorithm
our $CertificateIssuanceConfig_KEY_ALGORITHM_UNSPECIFIED = 0;
our $CertificateIssuanceConfig_RSA_2048 = 1;
our $CertificateIssuanceConfig_ECDSA_P256 = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig - Compiled Protocol Buffers messages for google/cloud/certificatemanager/v1/certificate_issuance_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig;

    my $msg = Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/certificatemanager/v1/certificate_issuance_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest

Request for the `ListCertificateIssuanceConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the certificate should be
listed, specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of certificate configs to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value returned by the last
`ListCertificateIssuanceConfigsResponse`. Indicates that this is a
continuation of a prior `ListCertificateIssuanceConfigs` call, and that the
system should return the next page of data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression to restrict the Certificates Configs returned.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A list of Certificate Config field names used to specify the
order of the returned results. The default sorting order is ascending. To
specify descending order for a field, add a suffix `" desc"`.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsResponse

Response for the `ListCertificateIssuanceConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->certificate_issuance_configs() >> / C<< $msg->certificate_issuance_configs($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig>)

A list of certificate configs for the parent resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::GetCertificateIssuanceConfigRequest

Request for the `GetCertificateIssuanceConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the certificate issuance config to describe. Must be in
the format `projects/*/locations/*/certificateIssuanceConfigs/*`.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CreateCertificateIssuanceConfigRequest

Request for the `CreateCertificateIssuanceConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the certificate issuance config. Must be
in the format `projects/*/locations/*`.

=item * C<< $msg->certificate_issuance_config_id() >> / C<< $msg->certificate_issuance_config_id($value) >>

Type: C<String>

Required. A user-provided name of the certificate config.

=item * C<< $msg->certificate_issuance_config() >> / C<< $msg->certificate_issuance_config($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig>)

Required. A definition of the certificate issuance config to create.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::UpdateCertificateIssuanceConfigRequest

Request for the `UpdateCertificateIssuanceConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->certificate_issuance_config() >> / C<< $msg->certificate_issuance_config($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig>)

Required. A definition of the certificate issuance config to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::DeleteCertificateIssuanceConfigRequest

Request for the `DeleteCertificateIssuanceConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the certificate issuance config to delete. Must be in
the format `projects/*/locations/*/certificateIssuanceConfigs/*`.

=back

=head2 Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig

CertificateIssuanceConfig specifies how to issue and manage a certificate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. A user-defined name of the certificate issuance config.
CertificateIssuanceConfig names must be unique globally and match pattern
`projects/*/locations/*/certificateIssuanceConfigs/*`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation timestamp of a CertificateIssuanceConfig.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update timestamp of a CertificateIssuanceConfig.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::LabelsEntry>)

Optional. Set of labels associated with a CertificateIssuanceConfig.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. One or more paragraphs of text description of a
CertificateIssuanceConfig.

=item * C<< $msg->certificate_authority_config() >> / C<< $msg->certificate_authority_config($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig>)

Required. The CA that issues the workload certificate. It includes the CA
address, type, authentication to CA service, etc.

=item * C<< $msg->lifetime() >> / C<< $msg->lifetime($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. Workload certificate lifetime requested.

=item * C<< $msg->rotation_window_percentage() >> / C<< $msg->rotation_window_percentage($value) >>

Type: C<Int32>

Required. Specifies the percentage of elapsed time of the certificate
lifetime to wait before renewing the certificate. Must be a number between
1-99, inclusive.

=item * C<< $msg->key_algorithm() >> / C<< $msg->key_algorithm($value) >>

Type: C<Enum> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::KeyAlgorithm>)

Required. The key algorithm to use when generating the private key.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::TagsEntry>)

Optional. Input only. Immutable. Tag keys/values directly bound to this
resource. For example:
  "123/environment": "production",
  "123/costCenter": "marketing"

=back

=head3 Enum: CertificateIssuanceConfig::KeyAlgorithm

=over 4

=item * C<KEY_ALGORITHM_UNSPECIFIED> => C<0>

=item * C<RSA_2048> => C<1>

=item * C<ECDSA_P256> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
