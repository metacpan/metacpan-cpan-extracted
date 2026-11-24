package Google::Cloud::Geminidataanalytics::V1::Datasource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MS9kYXRhc291cmNlLnByb3Rv
EiNnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byKnAgoURGF0
YXNvdXJjZVJlZmVyZW5jZXMSTgoCYnEYASABKAsyPC5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0
YWFuYWx5dGljcy52MS5CaWdRdWVyeVRhYmxlUmVmZXJlbmNlc0gAUgJicRJZCgZzdHVkaW8Y
AiABKAsyPy5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5TdHVkaW9EYXRh
c291cmNlUmVmZXJlbmNlc0gAUgZzdHVkaW8SVgoGbG9va2VyGAMgASgLMjwuZ29vZ2xlLmNs
b3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuTG9va2VyRXhwbG9yZVJlZmVyZW5jZXNIAFIG
bG9va2VyQgwKCnJlZmVyZW5jZXMi5wIKF0JpZ1F1ZXJ5VGFibGVSZWZlcmVuY2VzEmsKEHRh
YmxlX3JlZmVyZW5jZXMYASADKAsyOy5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGlj
cy52MS5CaWdRdWVyeVRhYmxlUmVmZXJlbmNlQgPgQQFSD3RhYmxlUmVmZXJlbmNlcxKEAQoZ
cHJvcGVydHlfZ3JhcGhfcmVmZXJlbmNlcxgCIAMoCzJDLmdvb2dsZS5jbG91ZC5nZW1pbmlk
YXRhYW5hbHl0aWNzLnYxLkJpZ1F1ZXJ5UHJvcGVydHlHcmFwaFJlZmVyZW5jZUID4EEBUhdw
cm9wZXJ0eUdyYXBoUmVmZXJlbmNlcxJYCgxzZWFyY2hfc2NvcGUYAyABKAsyMC5nb29nbGUu
Y2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5TZWFyY2hTY29wZUID4EEBUgtzZWFyY2hT
Y29wZSLKAQoWQmlnUXVlcnlUYWJsZVJlZmVyZW5jZRIiCgpwcm9qZWN0X2lkGAEgASgJQgPg
QQJSCXByb2plY3RJZBIiCgpkYXRhc2V0X2lkGAMgASgJQgPgQQJSCWRhdGFzZXRJZBIeCgh0
YWJsZV9pZBgEIAEoCUID4EECUgd0YWJsZUlkEkgKBnNjaGVtYRgGIAEoCzIrLmdvb2dsZS5j
bG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxLlNjaGVtYUID4EEBUgZzY2hlbWEiYgoYQmln
UXVlcnlEYXRhc2V0UmVmZXJlbmNlEiIKCnByb2plY3RfaWQYASABKAlCA+BBAlIJcHJvamVj
dElkEiIKCmRhdGFzZXRfaWQYAiABKAlCA+BBAlIJZGF0YXNldElkIsUBCgtTZWFyY2hTY29w
ZRIzChNpbmNsdWRlX3Byb2plY3RfaWRzGAEgAygJQgPgQQFSEWluY2x1ZGVQcm9qZWN0SWRz
EoABChppbmNsdWRlX2RhdGFzZXRfcmVmZXJlbmNlcxgCIAMoCzI9Lmdvb2dsZS5jbG91ZC5n
ZW1pbmlkYXRhYW5hbHl0aWNzLnYxLkJpZ1F1ZXJ5RGF0YXNldFJlZmVyZW5jZUID4EEBUhhp
bmNsdWRlRGF0YXNldFJlZmVyZW5jZXMijgEKGlN0dWRpb0RhdGFzb3VyY2VSZWZlcmVuY2Vz
EnAKEXN0dWRpb19yZWZlcmVuY2VzGAIgAygLMj4uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFh
bmFseXRpY3MudjEuU3R1ZGlvRGF0YXNvdXJjZVJlZmVyZW5jZUID4EEBUhBzdHVkaW9SZWZl
cmVuY2VzIkUKGVN0dWRpb0RhdGFzb3VyY2VSZWZlcmVuY2USKAoNZGF0YXNvdXJjZV9pZBgB
IAEoCUID4EECUgxkYXRhc291cmNlSWQiigEKF0xvb2tlckV4cGxvcmVSZWZlcmVuY2VzEm8K
EmV4cGxvcmVfcmVmZXJlbmNlcxgBIAMoCzI7Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5h
bHl0aWNzLnYxLkxvb2tlckV4cGxvcmVSZWZlcmVuY2VCA+BBAlIRZXhwbG9yZVJlZmVyZW5j
ZXMi6wIKFkxvb2tlckV4cGxvcmVSZWZlcmVuY2USMAoTbG9va2VyX2luc3RhbmNlX3VyaRgJ
IAEoCUgAUhFsb29rZXJJbnN0YW5jZVVyaRKBAQoccHJpdmF0ZV9sb29rZXJfaW5zdGFuY2Vf
aW5mbxgKIAEoCzI+Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxLlByaXZh
dGVMb29rZXJJbnN0YW5jZUluZm9IAFIZcHJpdmF0ZUxvb2tlckluc3RhbmNlSW5mbxImCgxs
b29rbWxfbW9kZWwYBCABKAlCA+BBAlILbG9va21sTW9kZWwSHQoHZXhwbG9yZRgFIAEoCUID
4EECUgdleHBsb3JlEkgKBnNjaGVtYRgIIAEoCzIrLmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRh
YW5hbHl0aWNzLnYxLlNjaGVtYUID4EEBUgZzY2hlbWFCCgoIaW5zdGFuY2UimQEKHkJpZ1F1
ZXJ5UHJvcGVydHlHcmFwaFJlZmVyZW5jZRIiCgpwcm9qZWN0X2lkGAEgASgJQgPgQQJSCXBy
b2plY3RJZBIiCgpkYXRhc2V0X2lkGAIgASgJQgPgQQJSCWRhdGFzZXRJZBIvChFwcm9wZXJ0
eV9ncmFwaF9pZBgDIAEoCUID4EECUg9wcm9wZXJ0eUdyYXBoSWQifwoZUHJpdmF0ZUxvb2tl
ckluc3RhbmNlSW5mbxIsChJsb29rZXJfaW5zdGFuY2VfaWQYASABKAlSEGxvb2tlckluc3Rh
bmNlSWQSNAoWc2VydmljZV9kaXJlY3RvcnlfbmFtZRgCIAEoCVIUc2VydmljZURpcmVjdG9y
eU5hbWUi3wQKCkRhdGFzb3VyY2USdwoYYmlncXVlcnlfdGFibGVfcmVmZXJlbmNlGAEgASgL
MjsuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuQmlnUXVlcnlUYWJsZVJl
ZmVyZW5jZUgAUhZiaWdxdWVyeVRhYmxlUmVmZXJlbmNlEjIKFHN0dWRpb19kYXRhc291cmNl
X2lkGAIgASgJSABSEnN0dWRpb0RhdGFzb3VyY2VJZBJ3Chhsb29rZXJfZXhwbG9yZV9yZWZl
cmVuY2UYBCABKAsyOy5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5Mb29r
ZXJFeHBsb3JlUmVmZXJlbmNlSABSFmxvb2tlckV4cGxvcmVSZWZlcmVuY2USkAEKIWJpZ3F1
ZXJ5X3Byb3BlcnR5X2dyYXBoX3JlZmVyZW5jZRgQIAEoCzJDLmdvb2dsZS5jbG91ZC5nZW1p
bmlkYXRhYW5hbHl0aWNzLnYxLkJpZ1F1ZXJ5UHJvcGVydHlHcmFwaFJlZmVyZW5jZUgAUh5i
aWdxdWVyeVByb3BlcnR5R3JhcGhSZWZlcmVuY2USSAoGc2NoZW1hGAcgASgLMisuZ29vZ2xl
LmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuU2NoZW1hQgPgQQFSBnNjaGVtYRJBCg1z
dHJ1Y3Rfc2NoZW1hGAogASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBUgxzdHJ1
Y3RTY2hlbWFCCwoJcmVmZXJlbmNlIqoCCgZTY2hlbWESRwoGZmllbGRzGAEgAygLMiouZ29v
Z2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuRmllbGRCA+BBAVIGZmllbGRzEiUK
C2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEh8KCHN5bm9ueW1zGAMgAygJ
QgPgQQFSCHN5bm9ueW1zEhcKBHRhZ3MYBCADKAlCA+BBAVIEdGFncxImCgxkaXNwbGF5X25h
bWUYBSABKAlCA+BBAVILZGlzcGxheU5hbWUSTgoHZmlsdGVycxgGIAMoCzIvLmdvb2dsZS5j
bG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxLkRhdGFGaWx0ZXJCA+BBAVIHZmlsdGVycyLz
AgoFRmllbGQSFwoEbmFtZRgBIAEoCUID4EEBUgRuYW1lEhcKBHR5cGUYAiABKAlCA+BBAVIE
dHlwZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID4EEBUgtkZXNjcmlwdGlvbhIXCgRtb2RlGAQg
ASgJQgPgQQFSBG1vZGUSHwoIc3lub255bXMYBiADKAlCA+BBAVIIc3lub255bXMSFwoEdGFn
cxgHIAMoCUID4EEBUgR0YWdzEiYKDGRpc3BsYXlfbmFtZRgIIAEoCUID4EEBUgtkaXNwbGF5
TmFtZRJNCglzdWJmaWVsZHMYCSADKAsyKi5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5
dGljcy52MS5GaWVsZEID4EEBUglzdWJmaWVsZHMSHwoIY2F0ZWdvcnkYCiABKAlCA+BBAVII
Y2F0ZWdvcnkSJgoMdmFsdWVfZm9ybWF0GAsgASgJQgPgQQFSC3ZhbHVlRm9ybWF0IpABCgpE
YXRhRmlsdGVyEhkKBWZpZWxkGAEgASgJQgPgQQFSBWZpZWxkEhkKBXZhbHVlGAIgASgJQgPg
QQFSBXZhbHVlEkwKBHR5cGUYAyABKA4yMy5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5
dGljcy52MS5EYXRhRmlsdGVyVHlwZUID4EEBUgR0eXBlKkUKDkRhdGFGaWx0ZXJUeXBlEiAK
HERBVEFfRklMVEVSX1RZUEVfVU5TUEVDSUZJRUQQABIRCg1BTFdBWVNfRklMVEVSEAFCjAIK
J2NvbS5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MUIPRGF0YXNvdXJjZVBy
b3RvUAFaWWNsb3VkLmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MS9n
ZW1pbmlkYXRhYW5hbHl0aWNzcGI7Z2VtaW5pZGF0YWFuYWx5dGljc3BiqgIjR29vZ2xlLkNs
b3VkLkdlbWluaURhdGFBbmFseXRpY3MuVjHKAiNHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFu
YWx5dGljc1xWMeoCJkdvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFBbmFseXRpY3M6OlYxSp9j
CgcSBQ4AtwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAs
CgkKAgMAEgMSACkKCQoCAwESAxMAJgoICgEIEgMVAEAKCQoCCCUSAxUAQAoICgEIEgMWAHAK
CQoCCAsSAxYAcAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoI
CgEIEgMZAEAKCQoCCAESAxkAQAoICgEIEgMaAEAKCQoCCCkSAxoAQAoICgEIEgMbAD8KCQoC
CC0SAxsAPwpQCgIFABIEHgAmARpEIFRoZSB0eXBlIG9mIGZpbHRlciBwcmVzZW50IG9uIGEg
ZGF0YXNvdXJjZSwgc3VjaCBhcyBBTFdBWVNfRklMVEVSLgoKCgoDBQABEgMeBRMKMQoEBQAC
ABIDIAIjGiQgVGhlIGZpbHRlciB0eXBlIHdhcyBub3Qgc3BlY2lmaWVkLgoKDAoFBQACAAES
AyACHgoMCgUFAAIAAhIDICEiCqoBCgQFAAIBEgMlAhQanAEgQSBmaWx0ZXIgdGhhdCB0aGUg
dXNlciBjb25maWd1cmVzLCBhbmQgYW55IHF1ZXJpZXMgdG8gdGhlIEV4cGxvcmUgd2lsbAog
YWx3YXlzIGFwcGx5IHRoaXMgZmlsdGVyIGJ5IGRlZmF1bHQuIEN1cnJlbnRseSBvbmx5IHVz
ZWQgZm9yIExvb2tlciBkYXRhCiBzb3VyY2VzLgoKDAoFBQACAQESAyUCDwoMCgUFAAIBAhID
JRITCjgKAgQAEgQpADUBGiwgQSBjb2xsZWN0aW9uIG9mIHJlZmVyZW5jZXMgdG8gZGF0YXNv
dXJjZXMuCgoKCgMEAAESAykIHAonCgQEAAgAEgQrAjQDGhkgVGhlIGRhdGFzb3VyY2VzIHRv
IHVzZS4KCgwKBQQACAABEgMrCBIKLQoEBAACABIDLQQjGiAgUmVmZXJlbmNlcyB0byBCaWdR
dWVyeSB0YWJsZXMuCgoMCgUEAAIABhIDLQQbCgwKBQQAAgABEgMtHB4KDAoFBAACAAMSAy0h
Igo3CgQEAAIBEgMwBCoaKiBSZWZlcmVuY2VzIHRvIExvb2tlciBTdHVkaW8gZGF0YXNvdXJj
ZXMuCgoMCgUEAAIBBhIDMAQeCgwKBQQAAgEBEgMwHyUKDAoFBAACAQMSAzAoKQotCgQEAAIC
EgMzBCcaICBSZWZlcmVuY2VzIHRvIExvb2tlciBFeHBsb3Jlcy4KCgwKBQQAAgIGEgMzBBsK
DAoFBAACAgESAzMcIgoMCgUEAAICAxIDMyUmCr4BCgIEARIEOgBTARqxASBNZXNzYWdlIHJl
cHJlc2VudGluZyByZWZlcmVuY2VzIHRvIEJpZ1F1ZXJ5IHRhYmxlcyBhbmQgcHJvcGVydHkg
Z3JhcGhzLgogQXQgbGVhc3Qgb25lIG9mIGB0YWJsZV9yZWZlcmVuY2VzYCwgYHByb3BlcnR5
X2dyYXBoX3JlZmVyZW5jZXNgLCBvcgogYHNlYXJjaF9zY29wZWAgbXVzdCBiZSBwb3B1bGF0
ZWQuCgoKCgMEAQESAzoIHwo4CgQEAQIAEgQ8Aj0vGiogT3B0aW9uYWwuIFJlZmVyZW5jZXMg
dG8gQmlnUXVlcnkgdGFibGVzLgoKDAoFBAECAAQSAzwCCgoMCgUEAQIABhIDPAshCgwKBQQB
AgABEgM8IjIKDAoFBAECAAMSAzw1NgoMCgUEAQIACBIDPQYuCg8KCAQBAgAInAgAEgM9By0K
7QEKBAQBAgESBEQCRS8a3gEgT3B0aW9uYWwuIFJlZmVyZW5jZXMgdG8gQmlnUXVlcnkgZ3Jh
cGhzLgoKIE5vdGU6ICJwcm9wZXJ0eSBncmFwaCIgaXMgdGhlIGZvcm1lciBuYW1lIGZvciBC
aWdRdWVyeSBHcmFwaC4gVGhlIGZpZWxkIGFuZAogbWVzc2FnZSBuYW1lcyByZXRhaW4gdGhl
IG9yaWdpbmFsIHRlcm0gZm9yIGJhY2t3YXJkIGNvbXBhdGliaWxpdHk7IGJvdGgKIHJlZmVy
IHRvIHRoZSBzYW1lIHJlc291cmNlLgoKDAoFBAECAQQSA0QCCgoMCgUEAQIBBhIDRAspCgwK
BQQBAgEBEgNEKkMKDAoFBAECAQMSA0RGRwoMCgUEAQIBCBIDRQYuCg8KCAQBAgEInAgAEgNF
By0KiAQKBAQBAgISA1ICSBr6AyBPcHRpb25hbC4gU2VhcmNoIG92ZXIgQmlnUXVlcnkgcmVz
b3VyY2VzIHRvIGRpc2NvdmVyIG1vc3QgcmVsZXZhbnQgdGFibGVzCiB0byB0aGUgcXVlcnku
CgogV2hlbiBzZXQsIGF0IGxlYXN0IG9uZSBvZiBgaW5jbHVkZV9wcm9qZWN0X2lkc2Agb3IK
IGBpbmNsdWRlX2RhdGFzZXRfcmVmZXJlbmNlc2AgbXVzdCBiZSBwb3B1bGF0ZWQgd2l0aCBu
b24tYmxhbmsgaWRlbnRpZmllcnMuCiBNYXRjaGVzIGZyb20gdGhlIHR3byBmaWVsZHMgYXJl
IHVuaW9uZWQgKE9SLWVkKS4KCiBOb3RlOiBgc2VhcmNoX3Njb3BlYCBpcyBvbmx5IHN1cHBv
cnRlZCBmb3Igc3RhbmRhbG9uZSBjb252ZXJzYXRpb25zCiAoYENoYXRSZXF1ZXN0LmlubGlu
ZV9jb250ZXh0YCBvcgogYENsaWVudE1hbmFnZWRSZXNvdXJjZUNvbnRleHQuaW5saW5lX2Nv
bnRleHRgKSBhbmQgaXMgbm90IHN1cHBvcnRlZCBpbgogW0RhdGFBZ2VudF1bZ29vZ2xlLmNs
b3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuRGF0YUFnZW50XS4KCgwKBQQBAgIGEgNSAg0K
DAoFBAECAgESA1IOGgoMCgUEAQICAxIDUh0eCgwKBQQBAgIIEgNSH0cKDwoIBAECAgicCAAS
A1IgRgpKCgIEAhIEVgBiARo+IE1lc3NhZ2UgcmVwcmVzZW50aW5nIGEgcmVmZXJlbmNlIHRv
IGEgc2luZ2xlIEJpZ1F1ZXJ5IHRhYmxlLgoKCgoDBAIBEgNWCB4KPwoEBAICABIDWAJBGjIg
UmVxdWlyZWQuIFRoZSBwcm9qZWN0IHRoYXQgdGhlIHRhYmxlIGJlbG9uZ3MgdG8uCgoMCgUE
AgIABRIDWAIICgwKBQQCAgABEgNYCRMKDAoFBAICAAMSA1gWFwoMCgUEAgIACBIDWBhACg8K
CAQCAgAInAgAEgNYGT8KPwoEBAICARIDWwJBGjIgUmVxdWlyZWQuIFRoZSBkYXRhc2V0IHRo
YXQgdGhlIHRhYmxlIGJlbG9uZ3MgdG8uCgoMCgUEAgIBBRIDWwIICgwKBQQCAgEBEgNbCRMK
DAoFBAICAQMSA1sWFwoMCgUEAgIBCBIDWxhACg8KCAQCAgEInAgAEgNbGT8KJgoEBAICAhID
XgI/GhkgUmVxdWlyZWQuIFRoZSB0YWJsZSBpZC4KCgwKBQQCAgIFEgNeAggKDAoFBAICAgES
A14JEQoMCgUEAgICAxIDXhQVCgwKBQQCAgIIEgNeFj4KDwoIBAICAgicCAASA14XPQo2CgQE
AgIDEgNhAj0aKSBPcHRpb25hbC4gVGhlIHNjaGVtYSBvZiB0aGUgZGF0YXNvdXJjZS4KCgwK
BQQCAgMGEgNhAggKDAoFBAICAwESA2EJDwoMCgUEAgIDAxIDYRITCgwKBQQCAgMIEgNhFDwK
DwoIBAICAwicCAASA2EVOwpMCgIEAxIEZQBrARpAIE1lc3NhZ2UgcmVwcmVzZW50aW5nIGEg
cmVmZXJlbmNlIHRvIGEgc2luZ2xlIEJpZ1F1ZXJ5IGRhdGFzZXQuCgoKCgMEAwESA2UIIApE
CgQEAwIAEgNnAkEaNyBSZXF1aXJlZC4gVGhlIHByb2plY3QgSUQgdGhhdCB0aGUgZGF0YXNl
dCBiZWxvbmdzIHRvLgoKDAoFBAMCAAUSA2cCCAoMCgUEAwIAARIDZwkTCgwKBQQDAgADEgNn
FhcKDAoFBAMCAAgSA2cYQAoPCggEAwIACJwIABIDZxk/CigKBAQDAgESA2oCQRobIFJlcXVp
cmVkLiBUaGUgZGF0YXNldCBJRC4KCgwKBQQDAgEFEgNqAggKDAoFBAMCAQESA2oJEwoMCgUE
AwIBAxIDahYXCgwKBQQDAgEIEgNqGEAKDwoIBAMCAQicCAASA2oZPwqiBAoCBAQSBHcAfwEa
lQQgTWVzc2FnZSByZXByZXNlbnRpbmcgZmlsdGVycyB0byBhcHBseSB0byBzZWFyY2ggb3Zl
ciBCaWdRdWVyeSB0YWJsZXMuCgogQXQgbGVhc3Qgb25lIG9mIGBpbmNsdWRlX3Byb2plY3Rf
aWRzYCBvciBgaW5jbHVkZV9kYXRhc2V0X3JlZmVyZW5jZXNgIG11c3QgYmUKIHBvcHVsYXRl
ZCB3aXRoIG5vbi1ibGFuayBpZGVudGlmaWVycy4gVGFibGVzIG1hdGNoaW5nIGVpdGhlciBm
aWVsZCBhcmUKIGluY2x1ZGVkLCBzbyB0aGUgdHdvIGZpZWxkcyBhcmUgdW5pb25lZCAoT1It
ZWQpIHJhdGhlciB0aGFuIGludGVyc2VjdGVkLgoKIE5vdGU6IGBTZWFyY2hTY29wZWAgaXMg
b25seSBzdXBwb3J0ZWQgZm9yIHN0YW5kYWxvbmUgY29udmVyc2F0aW9ucwogKGBDaGF0UmVx
dWVzdC5pbmxpbmVfY29udGV4dGAgb3IKIGBDbGllbnRNYW5hZ2VkUmVzb3VyY2VDb250ZXh0
LmlubGluZV9jb250ZXh0YCkgYW5kIGlzIG5vdCBzdXBwb3J0ZWQgaW4KIFtEYXRhQWdlbnRd
W2dvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxLkRhdGFBZ2VudF0uCgoKCgME
BAESA3cIEwpCCgQEBAIAEgR5AnovGjQgT3B0aW9uYWwuIFRoZSBCaWdRdWVyeSBwcm9qZWN0
IGlkcyB0byBzZWFyY2ggb3Zlci4KCgwKBQQEAgAEEgN5AgoKDAoFBAQCAAUSA3kLEQoMCgUE
BAIAARIDeRIlCgwKBQQEAgADEgN5KCkKDAoFBAQCAAgSA3oGLgoPCggEBAIACJwIABIDegct
CkkKBAQEAgESBH0Cfi8aOyBPcHRpb25hbC4gVGhlIEJpZ1F1ZXJ5IGRhdGFzZXQgcmVmZXJl
bmNlcyB0byBzZWFyY2ggb3Zlci4KCgwKBQQEAgEEEgN9AgoKDAoFBAQCAQYSA30LIwoMCgUE
BAIBARIDfSQ+CgwKBQQEAgEDEgN9QUIKDAoFBAQCAQgSA34GLgoPCggEBAIBCJwIABIDfgct
Ck0KAgQFEgaCAQCGAQEaPyBNZXNzYWdlIHJlcHJlc2VudGluZyByZWZlcmVuY2VzIHRvIExv
b2tlciBTdHVkaW8gZGF0YXNvdXJjZXMuCgoLCgMEBQESBIIBCCIKRQoEBAUCABIGhAEChQEv
GjUgT3B0aW9uYWwuIFRoZSByZWZlcmVuY2VzIHRvIHRoZSBzdHVkaW8gZGF0YXNvdXJjZXMu
CgoNCgUEBQIABBIEhAECCgoNCgUEBQIABhIEhAELJAoNCgUEBQIAARIEhAElNgoNCgUEBQIA
AxIEhAE5OgoNCgUEBQIACBIEhQEGLgoQCggEBQIACJwIABIEhQEHLQpWCgIEBhIGiQEAjAEB
GkggTWVzc2FnZSByZXByZXNlbnRpbmcgYSByZWZlcmVuY2UgdG8gYSBzaW5nbGUgTG9va2Vy
IFN0dWRpbyBkYXRhc291cmNlLgoKCwoDBAYBEgSJAQghCjMKBAQGAgASBIsBAkQaJSBSZXF1
aXJlZC4gVGhlIGlkIG9mIHRoZSBkYXRhc291cmNlLgoKDQoFBAYCAAUSBIsBAggKDQoFBAYC
AAESBIsBCRYKDQoFBAYCAAMSBIsBGRoKDQoFBAYCAAgSBIsBG0MKEAoIBAYCAAicCAASBIsB
HEIKQwoCBAcSBo8BAJMBARo1IE1lc3NhZ2UgcmVwcmVzZW50aW5nIHJlZmVyZW5jZXMgdG8g
TG9va2VyIGV4cGxvcmVzLgoKCwoDBAcBEgSPAQgfCjoKBAQHAgASBpEBApIBLxoqIFJlcXVp
cmVkLiBSZWZlcmVuY2VzIHRvIExvb2tlciBleHBsb3Jlcy4KCg0KBQQHAgAEEgSRAQIKCg0K
BQQHAgAGEgSRAQshCg0KBQQHAgABEgSRASI0Cg0KBQQHAgADEgSRATc4Cg0KBQQHAgAIEgSS
AQYuChAKCAQHAgAInAgAEgSSAQctCkwKAgQIEgaWAQCuAQEaPiBNZXNzYWdlIHJlcHJlc2Vu
dGluZyBhIHJlZmVyZW5jZSB0byBhIHNpbmdsZSBMb29rZXIgZXhwbG9yZS4KCgsKAwQIARIE
lgEIHgo1CgQECAgAEgaYAQKeAQMaJSBUaGUgaW5zdGFuY2Ugb2YgdGhlIExvb2tlciBleHBs
b3JlLgoKDQoFBAgIAAESBJgBCBAKPgoEBAgCABIEmgEEIxowIFJlcXVpcmVkLiBUaGUgYmFz
ZSB1cmwgb2YgdGhlIExvb2tlciBpbnN0YW5jZS4KCg0KBQQIAgAFEgSaAQQKCg0KBQQIAgAB
EgSaAQseCg0KBQQIAgADEgSaASEiCi0KBAQIAgESBJ0BBEAaHyBQcml2YXRlIExvb2tlciBp
bnN0YW5jZSBpbmZvLgoKDQoFBAgCAQYSBJ0BBB0KDQoFBAgCAQESBJ0BHjoKDQoFBAgCAQMS
BJ0BPT8KxwEKBAQIAgISBKQBAkMauAEgUmVxdWlyZWQuIExvb2tlciBtb2RlbCwgYXMgb3V0
bGluZWQgaW4KIFtNYWpvciBMb29rTUwKIHN0cnVjdHVyZXNdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9sb29rZXIvZG9jcy9sb29rbWwtdGVybXMtYW5kLWNvbmNlcHRzI21ham9yX2xv
b2ttbF9zdHJ1Y3R1cmVzKS4KIE5hbWUgb2YgdGhlIExvb2tNTCBtb2RlbC4KCg0KBQQIAgIF
EgSkAQIICg0KBQQIAgIBEgSkAQkVCg0KBQQIAgIDEgSkARgZCg0KBQQIAgIIEgSkARpCChAK
CAQIAgIInAgAEgSkARtBCssBCgQECAIDEgSqAQI+GrwBIFJlcXVpcmVkLiBMb29rZXIgRXhw
bG9yZSwgYXMgb3V0bGluZWQgaW4KIFtNYWpvciBMb29rTUwKIHN0cnVjdHVyZXNdKGh0dHBz
Oi8vY2xvdWQuZ29vZ2xlLmNvbS9sb29rZXIvZG9jcy9sb29rbWwtdGVybXMtYW5kLWNvbmNl
cHRzI21ham9yX2xvb2ttbF9zdHJ1Y3R1cmVzKS4KIE5hbWUgb2YgdGhlIExvb2tNTCBFeHBs
b3JlLgoKDQoFBAgCAwUSBKoBAggKDQoFBAgCAwESBKoBCRAKDQoFBAgCAwMSBKoBExQKDQoF
BAgCAwgSBKoBFT0KEAoIBAgCAwicCAASBKoBFjwKNwoEBAgCBBIErQECPRopIE9wdGlvbmFs
LiBUaGUgc2NoZW1hIG9mIHRoZSBkYXRhc291cmNlLgoKDQoFBAgCBAYSBK0BAggKDQoFBAgC
BAESBK0BCQ8KDQoFBAgCBAMSBK0BEhMKDQoFBAgCBAgSBK0BFDwKEAoIBAgCBAicCAASBK0B
FTsKVQoCBAkSBrEBALoBARpHIE1lc3NhZ2UgcmVwcmVzZW50aW5nIGEgcmVmZXJlbmNlIHRv
IGEgc2luZ2xlIEJpZ1F1ZXJ5IHByb3BlcnR5IGdyYXBoLgoKCwoDBAkBEgSxAQgmCkkKBAQJ
AgASBLMBAkEaOyBSZXF1aXJlZC4gVGhlIHByb2plY3QgdGhhdCB0aGUgcHJvcGVydHkgZ3Jh
cGggYmVsb25ncyB0by4KCg0KBQQJAgAFEgSzAQIICg0KBQQJAgABEgSzAQkTCg0KBQQJAgAD
EgSzARYXCg0KBQQJAgAIEgSzARhAChAKCAQJAgAInAgAEgSzARk/CkkKBAQJAgESBLYBAkEa
OyBSZXF1aXJlZC4gVGhlIGRhdGFzZXQgdGhhdCB0aGUgcHJvcGVydHkgZ3JhcGggYmVsb25n
cyB0by4KCg0KBQQJAgEFEgS2AQIICg0KBQQJAgEBEgS2AQkTCg0KBQQJAgEDEgS2ARYXCg0K
BQQJAgEIEgS2ARhAChAKCAQJAgEInAgAEgS2ARk/CjAKBAQJAgISBLkBAkgaIiBSZXF1aXJl
ZC4gVGhlIHByb3BlcnR5IGdyYXBoIGlkLgoKDQoFBAkCAgUSBLkBAggKDQoFBAkCAgESBLkB
CRoKDQoFBAkCAgMSBLkBHR4KDQoFBAkCAggSBLkBH0cKEAoIBAkCAgicCAASBLkBIEYKgQEK
AgQKEga+AQDEAQEacyBNZXNzYWdlIHJlcHJlc2VudGluZyBhIHByaXZhdGUgTG9va2VyIGlu
c3RhbmNlIGluZm8gcmVxdWlyZWQgaWYgdGhlIExvb2tlcgogaW5zdGFuY2UgaXMgYmVoaW5k
IGEgcHJpdmF0ZSBuZXR3b3JrLgoKCwoDBAoBEgS+AQghCicKBAQKAgASBMABAiAaGSBUaGUg
TG9va2VyIGluc3RhbmNlIGlkLgoKDQoFBAoCAAUSBMABAggKDQoFBAoCAAESBMABCRsKDQoF
BAoCAAMSBMABHh8KQgoEBAoCARIEwwECJBo0IFRoZSBzZXJ2aWNlIGRpcmVjdG9yeSBuYW1l
IG9mIHRoZSBMb29rZXIgaW5zdGFuY2UuCgoNCgUECgIBBRIEwwECCAoNCgUECgIBARIEwwEJ
HwoNCgUECgIBAxIEwwEiIwpCCgIECxIGxwEA4gEBGjQgQSBkYXRhc291cmNlIHRoYXQgY2Fu
IGJlIHVzZWQgdG8gYW5zd2VyIHF1ZXN0aW9ucy4KCgsKAwQLARIExwEIEgoyCgQECwgAEgbJ
AQLVAQMaIiBUaGUgcmVmZXJlbmNlIHRvIHRoZSBkYXRhc291cmNlLgoKDQoFBAsIAAESBMkB
CBEKMAoEBAsCABIEywEEOBoiIEEgcmVmZXJlbmNlIHRvIGEgQmlnUXVlcnkgdGFibGUuCgoN
CgUECwIABhIEywEEGgoNCgUECwIAARIEywEbMwoNCgUECwIAAxIEywE2Nwo6CgQECwIBEgTO
AQQkGiwgQSByZWZlcmVuY2UgdG8gYSBMb29rZXIgU3R1ZGlvIGRhdGFzb3VyY2UuCgoNCgUE
CwIBBRIEzgEECgoNCgUECwIBARIEzgELHwoNCgUECwIBAxIEzgEiIwowCgQECwICEgTRAQQ4
GiIgQSByZWZlcmVuY2UgdG8gYSBMb29rZXIgZXhwbG9yZS4KCg0KBQQLAgIGEgTRAQQaCg0K
BQQLAgIBEgTRARszCg0KBQQLAgIDEgTRATY3CjkKBAQLAgMSBNQBBEoaKyBBIHJlZmVyZW5j
ZSB0byBhIEJpZ1F1ZXJ5IHByb3BlcnR5IGdyYXBoLgoKDQoFBAsCAwYSBNQBBCIKDQoFBAsC
AwESBNQBI0QKDQoFBAsCAwMSBNQBR0kKNwoEBAsCBBIE2AECPRopIE9wdGlvbmFsLiBUaGUg
c2NoZW1hIG9mIHRoZSBkYXRhc291cmNlLgoKDQoFBAsCBAYSBNgBAggKDQoFBAsCBAESBNgB
CQ8KDQoFBAsCBAMSBNgBEhMKDQoFBAsCBAgSBNgBFDwKEAoIBAsCBAicCAASBNgBFTsK2gIK
BAQLAgUSBuABAuEBLxrJAiBPcHRpb25hbC4gQSBzdHJ1Y3QgcmVwcmVzZW50YXRpb24gb2Yg
dGhlIHNjaGVtYS4KIFRoaXMgaXMgcG9wdWxhdGVkIGZvciBkYXRhc291cmNlcyB3aXRoIHNj
aGVtYXMgdGhhdCBjYW5ub3QgYmUKIGZ1bGx5IHJlcHJlc2VudGVkIGJ5IHRoZSBzdHJvbmds
eS10eXBlZCBgc2NoZW1hYCBmaWVsZC4KCiBGb3IgTG9va2VyIGRhdGFzb3VyY2VzLCB0aGlz
IG1hcHMgdG8gdGhlIExvb2ttbE1vZGVsRXhwbG9yZSB0eXBlOgogaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2xvb2tlci9kb2NzL3JlZmVyZW5jZS9sb29rZXItYXBpL2xhdGVzdC90eXBl
cy9Mb29rbWxNb2RlbEV4cGxvcmUKCg0KBQQLAgUGEgTgAQIYCg0KBQQLAgUBEgTgARkmCg0K
BQQLAgUDEgTgASkrCg0KBQQLAgUIEgThAQYuChAKCAQLAgUInAgAEgThAQctCkMKAgQMEgbl
AQCAAgEaNSBUaGUgc2NoZW1hIG9mIGEgRGF0YXNvdXJjZSBvciBRdWVyeVJlc3VsdCBpbnN0
YW5jZS4KCgsKAwQMARIE5QEIDgozCgQEDAIAEgTnAQJFGiUgT3B0aW9uYWwuIFRoZSBmaWVs
ZHMgaW4gdGhlIHNjaGVtYS4KCg0KBQQMAgAEEgTnAQIKCg0KBQQMAgAGEgTnAQsQCg0KBQQM
AgABEgTnAREXCg0KBQQMAgADEgTnARobCg0KBQQMAgAIEgTnARxEChAKCAQMAgAInAgAEgTn
AR1DCtgBCgQEDAIBEgTsAQJCGskBIE9wdGlvbmFsLiBBIHRleHR1YWwgZGVzY3JpcHRpb24g
b2YgdGhlIHRhYmxlJ3MgY29udGVudCBhbmQgcHVycG9zZS4KIEZvciBleGFtcGxlOiAiQ29u
dGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgY3VzdG9tZXIgb3JkZXJzIGluIG91ciBlLWNvbW1l
cmNlCiBzdG9yZS4iIEN1cnJlbnRseSBvbmx5IHVzZWQgZm9yIEJpZ1F1ZXJ5IGRhdGEgc291
cmNlcy4KCg0KBQQMAgEFEgTsAQIICg0KBQQMAgEBEgTsAQkUCg0KBQQMAgEDEgTsARcYCg0K
BQQMAgEIEgTsARlBChAKCAQMAgEInAgAEgTsARpACsoBCgQEDAICEgTxAQJIGrsBIE9wdGlv
bmFsLiBBIGxpc3Qgb2YgYWx0ZXJuYXRpdmUgbmFtZXMgb3Igc3lub255bXMgdGhhdCBjYW4g
YmUgdXNlZCB0byByZWZlcgogdG8gdGhlIHRhYmxlLiBGb3IgZXhhbXBsZTogWyJzYWxlcyIs
ICJvcmRlcnMiLCAicHVyY2hhc2VzIl0uIEN1cnJlbnRseSBvbmx5CiB1c2VkIGZvciBCaWdR
dWVyeSBkYXRhIHNvdXJjZXMuCgoNCgUEDAICBBIE8QECCgoNCgUEDAICBRIE8QELEQoNCgUE
DAICARIE8QESGgoNCgUEDAICAxIE8QEdHgoNCgUEDAICCBIE8QEfRwoQCggEDAICCJwIABIE
8QEgRgrUAQoEBAwCAxIE9gECRBrFASBPcHRpb25hbC4gQSBsaXN0IG9mIHRhZ3Mgb3Iga2V5
d29yZHMgYXNzb2NpYXRlZCB3aXRoIHRoZSB0YWJsZSwgdXNlZCBmb3IKIGNhdGVnb3JpemF0
aW9uLiBGb3IgZXhhbXBsZTogWyJ0cmFuc2FjdGlvbiIsICJyZXZlbnVlIiwgImN1c3RvbWVy
X2RhdGEiXS4KIEN1cnJlbnRseSBvbmx5IHVzZWQgZm9yIEJpZ1F1ZXJ5IGRhdGEgc291cmNl
cy4KCg0KBQQMAgMEEgT2AQIKCg0KBQQMAgMFEgT2AQsRCg0KBQQMAgMBEgT2ARIWCg0KBQQM
AgMDEgT2ARkaCg0KBQQMAgMIEgT2ARtDChAKCAQMAgMInAgAEgT2ARxCCroBCgQEDAIEEgT7
AQJDGqsBIE9wdGlvbmFsLiBUYWJsZSBkaXNwbGF5X25hbWUgKHNhbWUgYXMgbGFiZWwgaW4K
IGNsb3VkL2RhdGFfYW5hbHl0aWNzL2FuYXJyZXMvZGF0YS9sb29rZXIvcHJvdG8vbW9kZWxf
ZXhwbG9yZS5wcm90byksIG5vdAogcmVxdWlyZWQsIGN1cnJlbnRseSBvbmx5IExvb2tlciBo
YXMgdGhpcyBmaWVsZC4KCg0KBQQMAgQFEgT7AQIICg0KBQQMAgQBEgT7AQkVCg0KBQQMAgQD
EgT7ARgZCg0KBQQMAgQIEgT7ARpCChAKCAQMAgQInAgAEgT7ARtBCngKBAQMAgUSBP8BAksa
aiBPcHRpb25hbC4gVGhlIGZpbHRlcnMgb24gdGhlIGRhdGFzb3VyY2UncyB1bmRlcmx5aW5n
IGRhdGEuIEN1cnJlbnRseSBvbmx5CiB1c2VkIGZvciBMb29rZXIgZGF0YSBzb3VyY2VzLgoK
DQoFBAwCBQQSBP8BAgoKDQoFBAwCBQYSBP8BCxUKDQoFBAwCBQESBP8BFh0KDQoFBAwCBQMS
BP8BICEKDQoFBAwCBQgSBP8BIkoKEAoIBAwCBQicCAASBP8BI0kKJAoCBA0SBoMCAKcCARoW
IEEgZmllbGQgaW4gYSBzY2hlbWEuCgoLCgMEDQESBIMCCA0KMAoEBA0CABIEhQICOxoiIE9w
dGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgZmllbGQuCgoNCgUEDQIABRIEhQICCAoNCgUEDQIA
ARIEhQIJDQoNCgUEDQIAAxIEhQIQEQoNCgUEDQIACBIEhQISOgoQCggEDQIACJwIABIEhQIT
OQowCgQEDQIBEgSIAgI7GiIgT3B0aW9uYWwuIFRoZSB0eXBlIG9mIHRoZSBmaWVsZC4KCg0K
BQQNAgEFEgSIAgIICg0KBQQNAgEBEgSIAgkNCg0KBQQNAgEDEgSIAhARCg0KBQQNAgEIEgSI
AhI6ChAKCAQNAgEInAgAEgSIAhM5CjsKBAQNAgISBIsCAkIaLSBPcHRpb25hbC4gQSBicmll
ZiBkZXNjcmlwdGlvbiBvZiB0aGUgZmllbGQuCgoNCgUEDQICBRIEiwICCAoNCgUEDQICARIE
iwIJFAoNCgUEDQICAxIEiwIXGAoNCgUEDQICCBIEiwIZQQoQCggEDQICCJwIABIEiwIaQApL
CgQEDQIDEgSOAgI7Gj0gT3B0aW9uYWwuIFRoZSBtb2RlIG9mIHRoZSBmaWVsZCAoZS5nLiwg
TlVMTEFCTEUsIFJFUEVBVEVEKS4KCg0KBQQNAgMFEgSOAgIICg0KBQQNAgMBEgSOAgkNCg0K
BQQNAgMDEgSOAhARCg0KBQQNAgMIEgSOAhI6ChAKCAQNAgMInAgAEgSOAhM5CsoBCgQEDQIE
EgSTAgJIGrsBIE9wdGlvbmFsLiBBIGxpc3Qgb2YgYWx0ZXJuYXRpdmUgbmFtZXMgb3Igc3lu
b255bXMgdGhhdCBjYW4gYmUgdXNlZCB0byByZWZlcgogdG8gdGhpcyBmaWVsZC4gRm9yIGV4
YW1wbGU6IFsiaWQiLCAiY3VzdG9tZXJpZCIsICJjdXN0X2lkIl0uIEN1cnJlbnRseSBvbmx5
CiB1c2VkIGZvciBCaWdRdWVyeSBkYXRhIHNvdXJjZXMuCgoNCgUEDQIEBBIEkwICCgoNCgUE
DQIEBRIEkwILEQoNCgUEDQIEARIEkwISGgoNCgUEDQIEAxIEkwIdHgoNCgUEDQIECBIEkwIf
RwoQCggEDQIECJwIABIEkwIgRgrKAQoEBA0CBRIEmAICRBq7ASBPcHRpb25hbC4gQSBsaXN0
IG9mIHRhZ3Mgb3Iga2V5d29yZHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaWVsZCwgdXNlZCBm
b3IKIGNhdGVnb3JpemF0aW9uLiBGb3IgZXhhbXBsZTogWyJpZGVudGlmaWVyIiwgImN1c3Rv
bWVyIiwgInBpaSJdLiBDdXJyZW50bHkKIG9ubHkgdXNlZCBmb3IgQmlnUXVlcnkgZGF0YSBz
b3VyY2VzLgoKDQoFBA0CBQQSBJgCAgoKDQoFBA0CBQUSBJgCCxEKDQoFBA0CBQESBJgCEhYK
DQoFBA0CBQMSBJgCGRoKDQoFBA0CBQgSBJgCG0MKEAoIBA0CBQicCAASBJgCHEIKPgoEBA0C
BhIEmwICQxowIE9wdGlvbmFsLiBGaWVsZCBkaXNwbGF5X25hbWUgKHNhbWUgYXMgbGFiZWwg
aW4KCg0KBQQNAgYFEgSbAgIICg0KBQQNAgYBEgSbAgkVCg0KBQQNAgYDEgSbAhgZCg0KBQQN
AgYIEgSbAhpCChAKCAQNAgYInAgAEgSbAhtBCkoKBAQNAgcSBJ4CAkgaPCBPcHRpb25hbC4g
UmVjdXJzaXZlIHByb3BlcnR5IGZvciBuZXN0ZWQgc2NoZW1hIHN0cnVjdHVyZXMuCgoNCgUE
DQIHBBIEngICCgoNCgUEDQIHBhIEngILEAoNCgUEDQIHARIEngIRGgoNCgUEDQIHAxIEngId
HgoNCgUEDQIHCBIEngIfRwoQCggEDQIHCJwIABIEngIgRgpZCgQEDQIIEgShAgJAGksgT3B0
aW9uYWwuIEZpZWxkIGNhdGVnb3J5LCBub3QgcmVxdWlyZWQsIGN1cnJlbnRseSBvbmx5IHVz
ZWZ1bCBmb3IgTG9va2VyLgoKDQoFBA0CCAUSBKECAggKDQoFBA0CCAESBKECCREKDQoFBA0C
CAMSBKECFBYKDQoFBA0CCAgSBKECFz8KEAoIBA0CCAicCAASBKECGD4KkQEKBAQNAgkSBKYC
AkQaggEgT3B0aW9uYWwuIExvb2tlciBvbmx5LiBWYWx1ZSBmb3JtYXQgb2YgdGhlIGZpZWxk
LgogUmVmOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2xvb2tlci9kb2NzL3JlZmVyZW5j
ZS9wYXJhbS1maWVsZC12YWx1ZS1mb3JtYXQKCg0KBQQNAgkFEgSmAgIICg0KBQQNAgkBEgSm
AgkVCg0KBQQNAgkDEgSmAhgaCg0KBQQNAgkIEgSmAhtDChAKCAQNAgkInAgAEgSmAhxCCpIB
CgIEDhIGqwIAtwIBGoMBIEEgZmlsdGVyIG9uIGEgZGF0YXNvdXJjZSdzIHVuZGVybHlpbmcg
ZGF0YS4gRmlsdGVyIHN5bnRheCBkb2N1bWVudGF0aW9uOgogaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2xvb2tlci9kb2NzL2ZpbHRlci1leHByZXNzaW9ucwoKCwoDBA4BEgSrAggSCnEK
BAQOAgASBK4CAjwaYyBPcHRpb25hbC4gVGhlIGZpZWxkIHRvIGZpbHRlciBvbi4gRm9yIGV4
YW1wbGU6IFsiZXZlbnRfZGF0ZSIsCiAiY3VzdG9tZXJfaWQiLCAicHJvZHVjdF9jYXRlZ29y
eSJdCgoNCgUEDgIABRIErgICCAoNCgUEDgIAARIErgIJDgoNCgUEDgIAAxIErgIREgoNCgUE
DgIACBIErgITOwoQCggEDgIACJwIABIErgIUOgqjAQoEBA4CARIEsgICPBqUASBPcHRpb25h
bC4gVGhlIGRlZmF1bHQgdmFsdWUgdXNlZCBmb3IgdGhpcyBmaWx0ZXIgaWYgdGhlIGZpbHRl
ciBpcyBub3QKIG92ZXJyaWRkZW4gaW4gYSBxdWVyeS4gRm9yIGV4YW1wbGU6IFsiYWZ0ZXIg
MjAyNC0wMS0wMSIsICIxMjMiLCAiLWZhc2hpb24iXQoKDQoFBA4CAQUSBLICAggKDQoFBA4C
AQESBLICCQ4KDQoFBA4CAQMSBLICERIKDQoFBA4CAQgSBLICEzsKEAoIBA4CAQicCAASBLIC
FDoKXQoEBA4CAhIEtgICQxpPIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiBmaWx0ZXIgcHJlc2Vu
dCBvbiBhIGRhdGFzb3VyY2UsIHN1Y2ggYXMKIEFMV0FZU19GSUxURVIuCgoNCgUEDgICBhIE
tgICEAoNCgUEDgICARIEtgIRFQoNCgUEDgICAxIEtgIYGQoNCgUEDgICCBIEtgIaQgoQCggE
DgICCJwIABIEtgIbQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences ===
    # Fields for DatasourceReferences
    # Field: bq Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryTableReferences)
    # Field: studio Type: 11 (.google.cloud.geminidataanalytics.v1.StudioDatasourceReferences)
    # Field: looker Type: 11 (.google.cloud.geminidataanalytics.v1.LookerExploreReferences)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences ===
    # Fields for BigQueryTableReferences
    # Field: table_references Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryTableReference)
    # Field: property_graph_references Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryPropertyGraphReference)
    # Field: search_scope Type: 11 (.google.cloud.geminidataanalytics.v1.SearchScope)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference ===
    # Fields for BigQueryTableReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: schema Type: 11 (.google.cloud.geminidataanalytics.v1.Schema)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference ===
    # Fields for BigQueryDatasetReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope ===
    # Fields for SearchScope
    # Field: include_project_ids Type: 9 ()
    # Field: include_dataset_references Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryDatasetReference)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences ===
    # Fields for StudioDatasourceReferences
    # Field: studio_references Type: 11 (.google.cloud.geminidataanalytics.v1.StudioDatasourceReference)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference ===
    # Fields for StudioDatasourceReference
    # Field: datasource_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences ===
    # Fields for LookerExploreReferences
    # Field: explore_references Type: 11 (.google.cloud.geminidataanalytics.v1.LookerExploreReference)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference ===
    # Fields for LookerExploreReference
    # Field: looker_instance_uri Type: 9 ()
    # Field: private_looker_instance_info Type: 11 (.google.cloud.geminidataanalytics.v1.PrivateLookerInstanceInfo)
    # Field: lookml_model Type: 9 ()
    # Field: explore Type: 9 ()
    # Field: schema Type: 11 (.google.cloud.geminidataanalytics.v1.Schema)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference ===
    # Fields for BigQueryPropertyGraphReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: property_graph_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo ===
    # Fields for PrivateLookerInstanceInfo
    # Field: looker_instance_id Type: 9 ()
    # Field: service_directory_name Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::Datasource ===
    # Fields for Datasource
    # Field: bigquery_table_reference Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryTableReference)
    # Field: studio_datasource_id Type: 9 ()
    # Field: looker_explore_reference Type: 11 (.google.cloud.geminidataanalytics.v1.LookerExploreReference)
    # Field: bigquery_property_graph_reference Type: 11 (.google.cloud.geminidataanalytics.v1.BigQueryPropertyGraphReference)
    # Field: schema Type: 11 (.google.cloud.geminidataanalytics.v1.Schema)
    # Field: struct_schema Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::Schema ===
    # Fields for Schema
    # Field: fields Type: 11 (.google.cloud.geminidataanalytics.v1.Field)
    # Field: description Type: 9 ()
    # Field: synonyms Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: filters Type: 11 (.google.cloud.geminidataanalytics.v1.DataFilter)

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::Field ===
    # Fields for Field
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: description Type: 9 ()
    # Field: mode Type: 9 ()
    # Field: synonyms Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: subfields Type: 11 (.google.cloud.geminidataanalytics.v1.Field)
    # Field: category Type: 9 ()
    # Field: value_format Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter ===
    # Fields for DataFilter
    # Field: field Type: 9 ()
    # Field: value Type: 9 ()
    # Field: type Type: 14 (.google.cloud.geminidataanalytics.v1.DataFilterType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::Datasource - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1/datasource.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1::Datasource;

    my $msg = Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences->new({
        bq => $bq,
        studio => $studio,
        looker => $looker,
    });

    # Read or update a field
    my $val = $msg->bq();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1/datasource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences

A collection of references to datasources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bq() >> / C<< $msg->bq($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences>)

References to BigQuery tables.

=item * C<< $msg->studio() >> / C<< $msg->studio($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences>)

References to Looker Studio datasources.

=item * C<< $msg->looker() >> / C<< $msg->looker($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences>)

References to Looker Explores.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences

Message representing references to BigQuery tables and property graphs.
At least one of `table_references`, `property_graph_references`, or
`search_scope` must be populated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->table_references() >> / C<< $msg->table_references($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference>)

Optional. References to BigQuery tables.

=item * C<< $msg->property_graph_references() >> / C<< $msg->property_graph_references($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference>)

Optional. References to BigQuery graphs.

Note: "property graph" is the former name for BigQuery Graph. The field and
message names retain the original term for backward compatibility; both
refer to the same resource.

=item * C<< $msg->search_scope() >> / C<< $msg->search_scope($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope>)

Optional. Search over BigQuery resources to discover most relevant tables
to the query.

When set, at least one of `include_project_ids` or
`include_dataset_references` must be populated with non-blank identifiers.
Matches from the two fields are unioned (OR-ed).

Note: `search_scope` is only supported for standalone conversations
(`ChatRequest.inline_context` or
`ClientManagedResourceContext.inline_context`) and is not supported in
[DataAgent][google.cloud.geminidataanalytics.v1.DataAgent].

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference

Message representing a reference to a single BigQuery table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The project that the table belongs to.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The dataset that the table belongs to.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. The table id.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::Schema>)

Optional. The schema of the datasource.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference

Message representing a reference to a single BigQuery dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The project ID that the dataset belongs to.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The dataset ID.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope

Message representing filters to apply to search over BigQuery tables.

At least one of `include_project_ids` or `include_dataset_references` must be
populated with non-blank identifiers. Tables matching either field are
included, so the two fields are unioned (OR-ed) rather than intersected.

Note: `SearchScope` is only supported for standalone conversations
(`ChatRequest.inline_context` or
`ClientManagedResourceContext.inline_context`) and is not supported in
[DataAgent][google.cloud.geminidataanalytics.v1.DataAgent].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->include_project_ids() >> / C<< $msg->include_project_ids($value) >>

Type: C<String>

Optional. The BigQuery project ids to search over.

=item * C<< $msg->include_dataset_references() >> / C<< $msg->include_dataset_references($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference>)

Optional. The BigQuery dataset references to search over.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences

Message representing references to Looker Studio datasources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->studio_references() >> / C<< $msg->studio_references($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference>)

Optional. The references to the studio datasources.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference

Message representing a reference to a single Looker Studio datasource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->datasource_id() >> / C<< $msg->datasource_id($value) >>

Type: C<String>

Required. The id of the datasource.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences

Message representing references to Looker explores.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->explore_references() >> / C<< $msg->explore_references($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference>)

Required. References to Looker explores.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference

Message representing a reference to a single Looker explore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->looker_instance_uri() >> / C<< $msg->looker_instance_uri($value) >>

Type: C<String>

Required. The base url of the Looker instance.

=item * C<< $msg->private_looker_instance_info() >> / C<< $msg->private_looker_instance_info($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo>)

Private Looker instance info.

=item * C<< $msg->lookml_model() >> / C<< $msg->lookml_model($value) >>

Type: C<String>

Required. Looker model, as outlined in
[Major LookML
structures](https://cloud.google.com/looker/docs/lookml-terms-and-concepts#major_lookml_structures).
Name of the LookML model.

=item * C<< $msg->explore() >> / C<< $msg->explore($value) >>

Type: C<String>

Required. Looker Explore, as outlined in
[Major LookML
structures](https://cloud.google.com/looker/docs/lookml-terms-and-concepts#major_lookml_structures).
Name of the LookML Explore.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::Schema>)

Optional. The schema of the datasource.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference

Message representing a reference to a single BigQuery property graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The project that the property graph belongs to.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The dataset that the property graph belongs to.

=item * C<< $msg->property_graph_id() >> / C<< $msg->property_graph_id($value) >>

Type: C<String>

Required. The property graph id.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo

Message representing a private Looker instance info required if the Looker
instance is behind a private network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->looker_instance_id() >> / C<< $msg->looker_instance_id($value) >>

Type: C<String>

The Looker instance id.

=item * C<< $msg->service_directory_name() >> / C<< $msg->service_directory_name($value) >>

Type: C<String>

The service directory name of the Looker instance.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::Datasource

A datasource that can be used to answer questions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bigquery_table_reference() >> / C<< $msg->bigquery_table_reference($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference>)

A reference to a BigQuery table.

=item * C<< $msg->studio_datasource_id() >> / C<< $msg->studio_datasource_id($value) >>

Type: C<String>

A reference to a Looker Studio datasource.

=item * C<< $msg->looker_explore_reference() >> / C<< $msg->looker_explore_reference($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference>)

A reference to a Looker explore.

=item * C<< $msg->bigquery_property_graph_reference() >> / C<< $msg->bigquery_property_graph_reference($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference>)

A reference to a BigQuery property graph.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::Schema>)

Optional. The schema of the datasource.

=item * C<< $msg->struct_schema() >> / C<< $msg->struct_schema($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A struct representation of the schema.
This is populated for datasources with schemas that cannot be
fully represented by the strongly-typed `schema` field.

For Looker datasources, this maps to the LookmlModelExplore type:
https://cloud.google.com/looker/docs/reference/looker-api/latest/types/LookmlModelExplore

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::Schema

The schema of a Datasource or QueryResult instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::Field>)

Optional. The fields in the schema.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A textual description of the table's content and purpose.
For example: "Contains information about customer orders in our e-commerce
store." Currently only used for BigQuery data sources.

=item * C<< $msg->synonyms() >> / C<< $msg->synonyms($value) >>

Type: C<String>

Optional. A list of alternative names or synonyms that can be used to refer
to the table. For example: ["sales", "orders", "purchases"]. Currently only
used for BigQuery data sources.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Optional. A list of tags or keywords associated with the table, used for
categorization. For example: ["transaction", "revenue", "customer_data"].
Currently only used for BigQuery data sources.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Table display_name (same as label in
cloud/data_analytics/anarres/data/looker/proto/model_explore.proto), not
required, currently only Looker has this field.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter>)

Optional. The filters on the datasource's underlying data. Currently only
used for Looker data sources.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::Field

A field in a schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the field.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Optional. The type of the field.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A brief description of the field.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

Optional. The mode of the field (e.g., NULLABLE, REPEATED).

=item * C<< $msg->synonyms() >> / C<< $msg->synonyms($value) >>

Type: C<String>

Optional. A list of alternative names or synonyms that can be used to refer
to this field. For example: ["id", "customerid", "cust_id"]. Currently only
used for BigQuery data sources.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Optional. A list of tags or keywords associated with the field, used for
categorization. For example: ["identifier", "customer", "pii"]. Currently
only used for BigQuery data sources.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Field display_name (same as label in

=item * C<< $msg->subfields() >> / C<< $msg->subfields($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Datasource::Field>)

Optional. Recursive property for nested schema structures.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

Optional. Field category, not required, currently only useful for Looker.

=item * C<< $msg->value_format() >> / C<< $msg->value_format($value) >>

Type: C<String>

Optional. Looker only. Value format of the field.
Ref:
https://cloud.google.com/looker/docs/reference/param-field-value-format

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter

A filter on a datasource's underlying data. Filter syntax documentation:
https://cloud.google.com/looker/docs/filter-expressions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<String>

Optional. The field to filter on. For example: ["event_date",
"customer_id", "product_category"]

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Optional. The default value used for this filter if the filter is not
overridden in a query. For example: ["after 2024-01-01", "123", "-fashion"]

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Geminidataanalytics::V1::DataFilterType>)

Optional. The type of filter present on a datasource, such as
ALWAYS_FILTER.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1::Datasource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
