package Google::Cloud::Retail::V2::UserEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Retail::V2::Common };
    eval { require Google::Cloud::Retail::V2::Product };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3VzZXJfZXZlbnQucHJvdG8SFmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aI2dvb2dsZS9j
bG91ZC9yZXRhaWwvdjIvY29tbW9uLnByb3RvGiRnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3By
b2R1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aHmdvb2dsZS9w
cm90b2J1Zi93cmFwcGVycy5wcm90byKhCAoJVXNlckV2ZW50EiIKCmV2ZW50X3R5cGUYASAB
KAlCA+BBAlIJZXZlbnRUeXBlEiIKCnZpc2l0b3JfaWQYAiABKAlCA+BBAlIJdmlzaXRvcklk
Eh0KCnNlc3Npb25faWQYFSABKAlSCXNlc3Npb25JZBI5CgpldmVudF90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXZlbnRUaW1lEiUKDmV4cGVyaW1lbnRfaWRz
GAQgAygJUg1leHBlcmltZW50SWRzEisKEWF0dHJpYnV0aW9uX3Rva2VuGAUgASgJUhBhdHRy
aWJ1dGlvblRva2VuEk4KD3Byb2R1Y3RfZGV0YWlscxgGIAMoCzIlLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuUHJvZHVjdERldGFpbFIOcHJvZHVjdERldGFpbHMSVQoRY29tcGxldGlvbl9k
ZXRhaWwYFiABKAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkNvbXBsZXRpb25EZXRhaWxS
EGNvbXBsZXRpb25EZXRhaWwSUQoKYXR0cmlidXRlcxgHIAMoCzIxLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuVXNlckV2ZW50LkF0dHJpYnV0ZXNFbnRyeVIKYXR0cmlidXRlcxIXCgdjYXJ0
X2lkGAggASgJUgZjYXJ0SWQSXgoUcHVyY2hhc2VfdHJhbnNhY3Rpb24YCSABKAsyKy5nb29n
bGUuY2xvdWQucmV0YWlsLnYyLlB1cmNoYXNlVHJhbnNhY3Rpb25SE3B1cmNoYXNlVHJhbnNh
Y3Rpb24SIQoMc2VhcmNoX3F1ZXJ5GAogASgJUgtzZWFyY2hRdWVyeRIWCgZmaWx0ZXIYECAB
KAlSBmZpbHRlchIZCghvcmRlcl9ieRgRIAEoCVIHb3JkZXJCeRIWCgZvZmZzZXQYEiABKAVS
Bm9mZnNldBInCg9wYWdlX2NhdGVnb3JpZXMYCyADKAlSDnBhZ2VDYXRlZ29yaWVzEj0KCXVz
ZXJfaW5mbxgMIAEoCzIgLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckluZm9SCHVzZXJJ
bmZvEhAKA3VyaRgNIAEoCVIDdXJpEiEKDHJlZmVycmVyX3VyaRgOIAEoCVILcmVmZXJyZXJV
cmkSIAoMcGFnZV92aWV3X2lkGA8gASgJUgpwYWdlVmlld0lkEhYKBmVudGl0eRgXIAEoCVIG
ZW50aXR5GmYKD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI9CgV2YWx1ZRgC
IAEoCzInLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ3VzdG9tQXR0cmlidXRlUgV2YWx1ZToC
OAEiiAEKDVByb2R1Y3REZXRhaWwSPgoHcHJvZHVjdBgBIAEoCzIfLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuUHJvZHVjdEID4EECUgdwcm9kdWN0EjcKCHF1YW50aXR5GAIgASgLMhsuZ29v
Z2xlLnByb3RvYnVmLkludDMyVmFsdWVSCHF1YW50aXR5IrIBChBDb21wbGV0aW9uRGV0YWls
EkAKHGNvbXBsZXRpb25fYXR0cmlidXRpb25fdG9rZW4YASABKAlSGmNvbXBsZXRpb25BdHRy
aWJ1dGlvblRva2VuEi8KE3NlbGVjdGVkX3N1Z2dlc3Rpb24YAiABKAlSEnNlbGVjdGVkU3Vn
Z2VzdGlvbhIrChFzZWxlY3RlZF9wb3NpdGlvbhgDIAEoBVIQc2VsZWN0ZWRQb3NpdGlvbiKU
AQoTUHVyY2hhc2VUcmFuc2FjdGlvbhIOCgJpZBgBIAEoCVICaWQSHQoHcmV2ZW51ZRgCIAEo
AkID4EECUgdyZXZlbnVlEhAKA3RheBgDIAEoAlIDdGF4EhIKBGNvc3QYBCABKAJSBGNvc3QS
KAoNY3VycmVuY3lfY29kZRgFIAEoCUID4EECUgxjdXJyZW5jeUNvZGVCuQEKGmNvbS5nb29n
bGUuY2xvdWQucmV0YWlsLnYyQg5Vc2VyRXZlbnRQcm90b1ABWjJjbG91ZC5nb29nbGUuY29t
L2dvL3JldGFpbC9hcGl2Mi9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5D
bG91ZC5SZXRhaWwuVjLKAhZHb29nbGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91
ZDo6UmV0YWlsOjpWMkqgcwoHEgUOANwCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTAC0KCQoCAwISAxQALgoJCgID
AxIDFQApCgkKAgMEEgMWACgKCAoBCBIDGAAzCgkKAgglEgMYADMKCAoBCBIDGQBJCgkKAggL
EgMZAEkKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAvCgkKAggIEgMbAC8KCAoBCBID
HAAzCgkKAggBEgMcADMKCAoBCBIDHQAkCgkKAggkEgMdACQKCAoBCBIDHgAzCgkKAggpEgMe
ADMKCAoBCBIDHwAyCgkKAggtEgMfADIKigEKAgQAEgUjAJMCARp9IFVzZXJFdmVudCBjYXB0
dXJlcyBhbGwgbWV0YWRhdGEgaW5mb3JtYXRpb24gUmV0YWlsIEFQSSBuZWVkcyB0byBrbm93
IGFib3V0CiBob3cgZW5kIHVzZXJzIGludGVyYWN0IHdpdGggY3VzdG9tZXJzJyB3ZWJzaXRl
LgoKCgoDBAABEgMjCBEK4AMKBAQAAgASAy8CQRrSAyBSZXF1aXJlZC4gVXNlciBldmVudCB0
eXBlLiBBbGxvd2VkIHZhbHVlcyBhcmU6CgogKiBgYWRkLXRvLWNhcnRgOiBQcm9kdWN0cyBi
ZWluZyBhZGRlZCB0byBjYXJ0LgogKiBgcmVtb3ZlLWZyb20tY2FydGA6IFByb2R1Y3RzIGJl
aW5nIHJlbW92ZWQgZnJvbSBjYXJ0LgogKiBgY2F0ZWdvcnktcGFnZS12aWV3YDogU3BlY2lh
bCBwYWdlcyBzdWNoIGFzIHNhbGUgb3IgcHJvbW90aW9uIHBhZ2VzCiAgIHZpZXdlZC4KICog
YGRldGFpbC1wYWdlLXZpZXdgOiBQcm9kdWN0cyBkZXRhaWwgcGFnZSB2aWV3ZWQuCiAqIGBo
b21lLXBhZ2Utdmlld2A6IEhvbWVwYWdlIHZpZXdlZC4KICogYHB1cmNoYXNlLWNvbXBsZXRl
YDogVXNlciBmaW5pc2hpbmcgYSBwdXJjaGFzZS4KICogYHNlYXJjaGA6IFByb2R1Y3Qgc2Vh
cmNoLgogKiBgc2hvcHBpbmctY2FydC1wYWdlLXZpZXdgOiBVc2VyIHZpZXdpbmcgYSBzaG9w
cGluZyBjYXJ0LgoKDAoFBAACAAUSAy8CCAoMCgUEAAIAARIDLwkTCgwKBQQAAgADEgMvFhcK
DAoFBAACAAgSAy8YQAoPCggEAAIACJwIABIDLxk/Cp0GCgQEAAIBEgNCAkEajwYgUmVxdWly
ZWQuIEEgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRyYWNraW5nIHZpc2l0b3JzLgoKIEZvciBl
eGFtcGxlLCB0aGlzIGNvdWxkIGJlIGltcGxlbWVudGVkIHdpdGggYW4gSFRUUCBjb29raWUs
IHdoaWNoIHNob3VsZCBiZQogYWJsZSB0byB1bmlxdWVseSBpZGVudGlmeSBhIHZpc2l0b3Ig
b24gYSBzaW5nbGUgZGV2aWNlLiBUaGlzIHVuaXF1ZQogaWRlbnRpZmllciBzaG91bGQgbm90
IGNoYW5nZSBpZiB0aGUgdmlzaXRvciBsb2cgaW4vb3V0IG9mIHRoZSB3ZWJzaXRlLgoKIERv
bid0IHNldCB0aGUgZmllbGQgdG8gdGhlIHNhbWUgZml4ZWQgSUQgZm9yIGRpZmZlcmVudCB1
c2Vycy4gVGhpcyBtaXhlcwogdGhlIGV2ZW50IGhpc3Rvcnkgb2YgdGhvc2UgdXNlcnMgdG9n
ZXRoZXIsIHdoaWNoIHJlc3VsdHMgaW4gZGVncmFkZWQgbW9kZWwKIHF1YWxpdHkuCgogVGhl
IGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxp
bWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5U
IGVycm9yIGlzIHJldHVybmVkLgoKIFRoZSBmaWVsZCBzaG91bGQgbm90IGNvbnRhaW4gUElJ
IG9yIHVzZXItZGF0YS4gV2UgcmVjb21tZW5kIHRvIHVzZSBHb29nbGUKIEFuYWx5dGljcyBb
Q2xpZW50CiBJRF0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYW5hbHl0aWNzL2Rl
dmd1aWRlcy9jb2xsZWN0aW9uL2FuYWx5dGljc2pzL2ZpZWxkLXJlZmVyZW5jZSNjbGllbnRJ
ZCkKIGZvciB0aGlzIGZpZWxkLgoKDAoFBAACAQUSA0ICCAoMCgUEAAIBARIDQgkTCgwKBQQA
AgEDEgNCFhcKDAoFBAACAQgSA0IYQAoPCggEAAIBCJwIABIDQhk/CooDCgQEAAICEgNMAhka
/AIgQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdHJhY2tpbmcgYSB2aXNpdG9yIHNlc3Npb24g
d2l0aCBhIGxlbmd0aCBsaW1pdCBvZgogMTI4IGJ5dGVzLiBBIHNlc3Npb24gaXMgYW4gYWdn
cmVnYXRpb24gb2YgYW4gZW5kIHVzZXIgYmVoYXZpb3IgaW4gYSB0aW1lCiBzcGFuLgoKIEEg
Z2VuZXJhbCBndWlkZWxpbmUgdG8gcG9wdWxhdGUgdGhlIHNlc3Npb25faWQ6CiAxLiBJZiB1
c2VyIGhhcyBubyBhY3Rpdml0eSBmb3IgMzAgbWluLCBhIG5ldyBzZXNzaW9uX2lkIHNob3Vs
ZCBiZSBhc3NpZ25lZC4KIDIuIFRoZSBzZXNzaW9uX2lkIHNob3VsZCBiZSB1bmlxdWUgYWNy
b3NzIHVzZXJzLCBzdWdnZXN0IHVzZSB1dWlkIG9yIGFkZAogdmlzaXRvcl9pZCBhcyBwcmVm
aXguCgoMCgUEAAICBRIDTAIICgwKBQQAAgIBEgNMCRMKDAoFBAACAgMSA0wWGAq0AQoEBAAC
AxIDUQIrGqYBIE9ubHkgcmVxdWlyZWQgZm9yCiBbVXNlckV2ZW50U2VydmljZS5JbXBvcnRV
c2VyRXZlbnRzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlVzZXJFdmVudFNlcnZpY2UuSW1w
b3J0VXNlckV2ZW50c10KIG1ldGhvZC4gVGltZXN0YW1wIG9mIHdoZW4gdGhlIHVzZXIgZXZl
bnQgaGFwcGVuZWQuCgoMCgUEAAIDBhIDUQIbCgwKBQQAAgMBEgNRHCYKDAoFBAACAwMSA1Ep
KgqGAgoEBAACBBIDVwIlGvgBIEEgbGlzdCBvZiBpZGVudGlmaWVycyBmb3IgdGhlIGluZGVw
ZW5kZW50IGV4cGVyaW1lbnQgZ3JvdXBzIHRoaXMgdXNlciBldmVudAogYmVsb25ncyB0by4g
VGhpcyBpcyB1c2VkIHRvIGRpc3Rpbmd1aXNoIGJldHdlZW4gdXNlciBldmVudHMgYXNzb2Np
YXRlZCB3aXRoCiBkaWZmZXJlbnQgZXhwZXJpbWVudCBzZXR1cHMgKGUuZy4gdXNpbmcgUmV0
YWlsIEFQSSwgdXNpbmcgZGlmZmVyZW50CiByZWNvbW1lbmRhdGlvbiBtb2RlbHMpLgoKDAoF
BAACBAQSA1cCCgoMCgUEAAIEBRIDVwsRCgwKBQQAAgQBEgNXEiAKDAoFBAACBAMSA1cjJArW
CQoEBAACBRIDcAIfGsgJIEhpZ2hseSByZWNvbW1lbmRlZCBmb3IgdXNlciBldmVudHMgdGhh
dCBhcmUgdGhlIHJlc3VsdCBvZgogW1ByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdW2dvb2ds
ZS5jbG91ZC5yZXRhaWwudjIuUHJlZGljdGlvblNlcnZpY2UuUHJlZGljdF0uCiBUaGlzIGZp
ZWxkIGVuYWJsZXMgYWNjdXJhdGUgYXR0cmlidXRpb24gb2YgcmVjb21tZW5kYXRpb24gbW9k
ZWwKIHBlcmZvcm1hbmNlLgoKIFRoZSB2YWx1ZSBtdXN0IGJlIGEgdmFsaWQKIFtQcmVkaWN0
UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuUHJl
ZGljdFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXQogZm9yIHVzZXIgZXZlbnRzIHRoYXQg
YXJlIHRoZSByZXN1bHQgb2YKIFtQcmVkaWN0aW9uU2VydmljZS5QcmVkaWN0XVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgogVGhlIHZhbHVl
IG11c3QgYmUgYSB2YWxpZAogW1NlYXJjaFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2Vu
XQogZm9yIHVzZXIgZXZlbnRzIHRoYXQgYXJlIHRoZSByZXN1bHQgb2YKIFtTZWFyY2hTZXJ2
aWNlLlNlYXJjaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hTZXJ2aWNlLlNlYXJj
aF0uCgogVGhpcyB0b2tlbiBlbmFibGVzIHVzIHRvIGFjY3VyYXRlbHkgYXR0cmlidXRlIHBh
Z2UgdmlldyBvciBwdXJjaGFzZSBiYWNrIHRvCiB0aGUgZXZlbnQgYW5kIHRoZSBwYXJ0aWN1
bGFyIHByZWRpY3QgcmVzcG9uc2UgY29udGFpbmluZyB0aGlzCiBjbGlja2VkL3B1cmNoYXNl
ZCBwcm9kdWN0LiBJZiB1c2VyIGNsaWNrcyBvbiBwcm9kdWN0IEsgaW4gdGhlCiByZWNvbW1l
bmRhdGlvbiByZXN1bHRzLCBwYXNzCiBbUHJlZGljdFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rv
a2VuXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByZWRpY3RSZXNwb25zZS5hdHRyaWJ1dGlv
bl90b2tlbl0KIGFzIGEgVVJMIHBhcmFtZXRlciB0byBwcm9kdWN0IEsncyBwYWdlLiBXaGVu
IHJlY29yZGluZyBldmVudHMgb24gcHJvZHVjdAogSydzIHBhZ2UsIGxvZyB0aGUKIFtQcmVk
aWN0UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIu
UHJlZGljdFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXQogdG8gdGhpcyBmaWVsZC4KCgwK
BQQAAgUFEgNwAggKDAoFBAACBQESA3AJGgoMCgUEAAIFAxIDcB0eCooFCgQEAAIGEgSBAQIt
GvsEIFRoZSBtYWluIHByb2R1Y3QgZGV0YWlscyByZWxhdGVkIHRvIHRoZSBldmVudC4KCiBU
aGlzIGZpZWxkIGlzIG9wdGlvbmFsIGV4Y2VwdCBmb3IgdGhlIGZvbGxvd2luZyBldmVudCB0
eXBlczoKCiAqIGBhZGQtdG8tY2FydGAKICogYGRldGFpbC1wYWdlLXZpZXdgCiAqIGBwdXJj
aGFzZS1jb21wbGV0ZWAKCiBJbiBhIGBzZWFyY2hgIGV2ZW50LCB0aGlzIGZpZWxkIHJlcHJl
c2VudHMgdGhlIHByb2R1Y3RzIHJldHVybmVkIHRvIHRoZSBlbmQKIHVzZXIgb24gdGhlIGN1
cnJlbnQgcGFnZSAodGhlIGVuZCB1c2VyIG1heSBoYXZlIG5vdCBmaW5pc2hlZCBicm93c2lu
ZyB0aGUKIHdob2xlIHBhZ2UgeWV0KS4gV2hlbiBhIG5ldyBwYWdlIGlzIHJldHVybmVkIHRv
IHRoZSBlbmQgdXNlciwgYWZ0ZXIKIHBhZ2luYXRpb24vZmlsdGVyaW5nL29yZGVyaW5nIGV2
ZW4gZm9yIHRoZSBzYW1lIHF1ZXJ5LCBhIG5ldyBgc2VhcmNoYCBldmVudAogd2l0aCBkaWZm
ZXJlbnQKIFtwcm9kdWN0X2RldGFpbHNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2
ZW50LnByb2R1Y3RfZGV0YWlsc10gaXMKIGRlc2lyZWQuIFRoZSBlbmQgdXNlciBtYXkgaGF2
ZSBub3QgZmluaXNoZWQgYnJvd3NpbmcgdGhlIHdob2xlIHBhZ2UgeWV0LgoKDQoFBAACBgQS
BIEBAgoKDQoFBAACBgYSBIEBCxgKDQoFBAACBgESBIEBGSgKDQoFBAACBgMSBIEBKywKyQEK
BAQAAgcSBIcBAioaugEgVGhlIG1haW4gYXV0by1jb21wbGV0aW9uIGRldGFpbHMgcmVsYXRl
ZCB0byB0aGUgZXZlbnQuCgogVGhpcyBmaWVsZCBzaG91bGQgYmUgc2V0IGZvciBgc2VhcmNo
YCBldmVudCB3aGVuIGF1dG9jb21wbGV0ZSBmdW5jdGlvbiBpcwogZW5hYmxlZCBhbmQgdGhl
IHVzZXIgY2xpY2tzIGEgc3VnZ2VzdGlvbiBmb3Igc2VhcmNoLgoKDQoFBAACBwYSBIcBAhIK
DQoFBAACBwESBIcBEyQKDQoFBAACBwMSBIcBJykK+ggKBAQAAggSBKABAi4a6wggRXh0cmEg
dXNlciBldmVudCBmZWF0dXJlcyB0byBpbmNsdWRlIGluIHRoZSByZWNvbW1lbmRhdGlvbiBt
b2RlbC4KCiBJZiB5b3UgcHJvdmlkZSBjdXN0b20gYXR0cmlidXRlcyBmb3IgaW5nZXN0ZWQg
dXNlciBldmVudHMsIGFsc28gaW5jbHVkZQogdGhlbSBpbiB0aGUgdXNlciBldmVudHMgdGhh
dCB5b3UgYXNzb2NpYXRlIHdpdGggcHJlZGljdGlvbiByZXF1ZXN0cy4gQ3VzdG9tCiBhdHRy
aWJ1dGUgZm9ybWF0dGluZyBtdXN0IGJlIGNvbnNpc3RlbnQgYmV0d2VlbiBpbXBvcnRlZCBl
dmVudHMgYW5kIGV2ZW50cwogcHJvdmlkZWQgd2l0aCBwcmVkaWN0aW9uIHJlcXVlc3RzLiBU
aGlzIGxldHMgdGhlIFJldGFpbCBBUEkgdXNlCiB0aG9zZSBjdXN0b20gYXR0cmlidXRlcyB3
aGVuIHRyYWluaW5nIG1vZGVscyBhbmQgc2VydmluZyBwcmVkaWN0aW9ucywgd2hpY2gKIGhl
bHBzIGltcHJvdmUgcmVjb21tZW5kYXRpb24gcXVhbGl0eS4KCiBUaGlzIGZpZWxkIG5lZWRz
IHRvIHBhc3MgYWxsIGJlbG93IGNyaXRlcmlhLCBvdGhlcndpc2UgYW4gSU5WQUxJRF9BUkdV
TUVOVAogZXJyb3IgaXMgcmV0dXJuZWQ6CgogKiBUaGUga2V5IG11c3QgYmUgYSBVVEYtOCBl
bmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDUsMDAwCiAgIGNoYXJhY3Rl
cnMuCiAqIEZvciB0ZXh0IGF0dHJpYnV0ZXMsIGF0IG1vc3QgNDAwIHZhbHVlcyBhcmUgYWxs
b3dlZC4gRW1wdHkgdmFsdWVzIGFyZSBub3QKICAgYWxsb3dlZC4gRWFjaCB2YWx1ZSBtdXN0
IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZgogICAy
NTYgY2hhcmFjdGVycy4KICogRm9yIG51bWJlciBhdHRyaWJ1dGVzLCBhdCBtb3N0IDQwMCB2
YWx1ZXMgYXJlIGFsbG93ZWQuCgogRm9yIHByb2R1Y3QgcmVjb21tZW5kYXRpb25zLCBhbiBl
eGFtcGxlIG9mIGV4dHJhIHVzZXIgaW5mb3JtYXRpb24gaXMKIHRyYWZmaWNfY2hhbm5lbCwg
d2hpY2ggaXMgaG93IGEgdXNlciBhcnJpdmVzIGF0IHRoZSBzaXRlLiBVc2VycyBjYW4gYXJy
aXZlCiBhdCB0aGUgc2l0ZSBieSBjb21pbmcgdG8gdGhlIHNpdGUgZGlyZWN0bHksIGNvbWlu
ZyB0aHJvdWdoIEdvb2dsZQogc2VhcmNoLCBvciBpbiBvdGhlciB3YXlzLgoKDQoFBAACCAYS
BKABAh4KDQoFBAACCAESBKABHykKDQoFBAACCAMSBKABLC0KgAIKBAQAAgkSBKcBAhUa8QEg
VGhlIElEIG9yIG5hbWUgb2YgdGhlIGFzc29jaWF0ZWQgc2hvcHBpbmcgY2FydC4gVGhpcyBJ
RCBpcyB1c2VkCiB0byBhc3NvY2lhdGUgbXVsdGlwbGUgaXRlbXMgYWRkZWQgb3IgcHJlc2Vu
dCBpbiB0aGUgY2FydCBiZWZvcmUgcHVyY2hhc2UuCgogVGhpcyBjYW4gb25seSBiZSBzZXQg
Zm9yIGBhZGQtdG8tY2FydGAsIGBwdXJjaGFzZS1jb21wbGV0ZWAsIG9yCiBgc2hvcHBpbmct
Y2FydC1wYWdlLXZpZXdgIGV2ZW50cy4KCg0KBQQAAgkFEgSnAQIICg0KBQQAAgkBEgSnAQkQ
Cg0KBQQAAgkDEgSnARMUCtUBCgQEAAIKEgStAQIvGsYBIEEgdHJhbnNhY3Rpb24gcmVwcmVz
ZW50cyB0aGUgZW50aXJlIHB1cmNoYXNlIHRyYW5zYWN0aW9uLgoKIFJlcXVpcmVkIGZvciBg
cHVyY2hhc2UtY29tcGxldGVgIGV2ZW50cy4gT3RoZXIgZXZlbnQgdHlwZXMgc2hvdWxkIG5v
dCBzZXQKIHRoaXMgZmllbGQuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQQAAgoGEgStAQIVCg0KBQQAAgoBEgStARYqCg0KBQQAAgoD
EgStAS0uCqQECgQEAAILEgS8AQIbGpUEIFRoZSB1c2VyJ3Mgc2VhcmNoIHF1ZXJ5LgoKIFNl
ZSBbU2VhcmNoUmVxdWVzdC5xdWVyeV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hS
ZXF1ZXN0LnF1ZXJ5XSBmb3IKIGRlZmluaXRpb24uCgogVGhlIHZhbHVlIG11c3QgYmUgYSBV
VEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDUsMDAwCiBjaGFy
YWN0ZXJzLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJu
ZWQuCgogQXQgbGVhc3Qgb25lIG9mCiBbc2VhcmNoX3F1ZXJ5XVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyLlVzZXJFdmVudC5zZWFyY2hfcXVlcnldIG9yCiBbcGFnZV9jYXRlZ29yaWVzXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyLlVzZXJFdmVudC5wYWdlX2NhdGVnb3JpZXNdIGlzCiBy
ZXF1aXJlZCBmb3IgYHNlYXJjaGAgZXZlbnRzLiBPdGhlciBldmVudCB0eXBlcyBzaG91bGQg
bm90IHNldCB0aGlzIGZpZWxkLgogT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVy
cm9yIGlzIHJldHVybmVkLgoKDQoFBAACCwUSBLwBAggKDQoFBAACCwESBLwBCRUKDQoFBAAC
CwMSBLwBGBoKiAMKBAQAAgwSBMYBAhUa+QIgVGhlIGZpbHRlciBzeW50YXggY29uc2lzdHMg
b2YgYW4gZXhwcmVzc2lvbiBsYW5ndWFnZSBmb3IgY29uc3RydWN0aW5nIGEKIHByZWRpY2F0
ZSBmcm9tIG9uZSBvciBtb3JlIGZpZWxkcyBvZiB0aGUgcHJvZHVjdHMgYmVpbmcgZmlsdGVy
ZWQuCgogU2VlIFtTZWFyY2hSZXF1ZXN0LmZpbHRlcl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5TZWFyY2hSZXF1ZXN0LmZpbHRlcl0gZm9yCiBkZWZpbml0aW9uIGFuZCBzeW50YXguCgog
VGhlIHZhbHVlIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3Ro
IGxpbWl0IG9mIDEsMDAwCiBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJH
VU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAIMBRIExgECCAoNCgUEAAIMARIExgEJ
DwoNCgUEAAIMAxIExgESFAq3AwoEBAACDRIE0gECFxqoAyBUaGUgb3JkZXIgaW4gd2hpY2gg
cHJvZHVjdHMgYXJlIHJldHVybmVkLgoKIFNlZSBbU2VhcmNoUmVxdWVzdC5vcmRlcl9ieV1b
Z29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hSZXF1ZXN0Lm9yZGVyX2J5XQogZm9yIGRl
ZmluaXRpb24gYW5kIHN5bnRheC4KCiBUaGUgdmFsdWUgbXVzdCBiZSBhIFVURi04IGVuY29k
ZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMSwwMDAKIGNoYXJhY3RlcnMuIE90
aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1cm5lZC4KCiBUaGlz
IGNhbiBvbmx5IGJlIHNldCBmb3IgYHNlYXJjaGAgZXZlbnRzLiBPdGhlciBldmVudCB0eXBl
cyBzaG91bGQgbm90IHNldAogdGhpcyBmaWVsZC4gT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FS
R1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACDQUSBNIBAggKDQoFBAACDQESBNIB
CREKDQoFBAACDQMSBNIBFBYKyQMKBAQAAg4SBN4BAhQaugMgQW4gaW50ZWdlciB0aGF0IHNw
ZWNpZmllcyB0aGUgY3VycmVudCBvZmZzZXQgZm9yIHBhZ2luYXRpb24gKHRoZSAwLWluZGV4
ZWQKIHN0YXJ0aW5nIGxvY2F0aW9uLCBhbW9uZ3N0IHRoZSBwcm9kdWN0cyBkZWVtZWQgYnkg
dGhlIEFQSSBhcyByZWxldmFudCkuCgogU2VlIFtTZWFyY2hSZXF1ZXN0Lm9mZnNldF1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hSZXF1ZXN0Lm9mZnNldF0gZm9yCiBkZWZpbml0
aW9uLgoKIElmIHRoaXMgZmllbGQgaXMgbmVnYXRpdmUsIGFuIElOVkFMSURfQVJHVU1FTlQg
aXMgcmV0dXJuZWQuCgogVGhpcyBjYW4gb25seSBiZSBzZXQgZm9yIGBzZWFyY2hgIGV2ZW50
cy4gT3RoZXIgZXZlbnQgdHlwZXMgc2hvdWxkIG5vdCBzZXQKIHRoaXMgZmllbGQuIE90aGVy
d2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQAAg4F
EgTeAQIHCg0KBQQAAg4BEgTeAQgOCg0KBQQAAg4DEgTeARETCucFCgQEAAIPEgTvAQInGtgF
IFRoZSBjYXRlZ29yaWVzIGFzc29jaWF0ZWQgd2l0aCBhIGNhdGVnb3J5IHBhZ2UuCgogVG8g
cmVwcmVzZW50IGZ1bGwgcGF0aCBvZiBjYXRlZ29yeSwgdXNlICc+JyBzaWduIHRvIHNlcGFy
YXRlIGRpZmZlcmVudAogaGllcmFyY2hpZXMuIElmICc+JyBpcyBwYXJ0IG9mIHRoZSBjYXRl
Z29yeSBuYW1lLCByZXBsYWNlIGl0IHdpdGgKIG90aGVyIGNoYXJhY3RlcihzKS4KCiBDYXRl
Z29yeSBwYWdlcyBpbmNsdWRlIHNwZWNpYWwgcGFnZXMgc3VjaCBhcyBzYWxlcyBvciBwcm9t
b3Rpb25zLiBGb3IKIGluc3RhbmNlLCBhIHNwZWNpYWwgc2FsZSBwYWdlIG1heSBoYXZlIHRo
ZSBjYXRlZ29yeSBoaWVyYXJjaHk6CiAicGFnZUNhdGVnb3JpZXMiIDogWyJTYWxlcyA+IDIw
MTcgQmxhY2sgRnJpZGF5IERlYWxzIl0uCgogUmVxdWlyZWQgZm9yIGBjYXRlZ29yeS1wYWdl
LXZpZXdgIGV2ZW50cy4gQXQgbGVhc3Qgb25lIG9mCiBbc2VhcmNoX3F1ZXJ5XVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlVzZXJFdmVudC5zZWFyY2hfcXVlcnldIG9yCiBbcGFnZV9jYXRl
Z29yaWVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlVzZXJFdmVudC5wYWdlX2NhdGVnb3Jp
ZXNdIGlzCiByZXF1aXJlZCBmb3IgYHNlYXJjaGAgZXZlbnRzLiBPdGhlciBldmVudCB0eXBl
cyBzaG91bGQgbm90IHNldCB0aGlzIGZpZWxkLgogT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FS
R1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACDwQSBO8BAgoKDQoFBAACDwUSBO8B
CxEKDQoFBAACDwESBO8BEiEKDQoFBAACDwMSBO8BJCYKIQoEBAACEBIE8gECGhoTIFVzZXIg
aW5mb3JtYXRpb24uCgoNCgUEAAIQBhIE8gECCgoNCgUEAAIQARIE8gELFAoNCgUEAAIQAxIE
8gEXGQr1AQoEBAACERIE+QECEhrmASBDb21wbGV0ZSBVUkwgKHdpbmRvdy5sb2NhdGlvbi5o
cmVmKSBvZiB0aGUgdXNlcidzIGN1cnJlbnQgcGFnZS4KCiBXaGVuIHVzaW5nIHRoZSBjbGll
bnQgc2lkZSBldmVudCByZXBvcnRpbmcgd2l0aCBKYXZhU2NyaXB0IHBpeGVsIGFuZCBHb29n
bGUKIFRhZyBNYW5hZ2VyLCB0aGlzIHZhbHVlIGlzIGZpbGxlZCBpbiBhdXRvbWF0aWNhbGx5
LiBNYXhpbXVtIGxlbmd0aCA1LDAwMAogY2hhcmFjdGVycy4KCg0KBQQAAhEFEgT5AQIICg0K
BQQAAhEBEgT5AQkMCg0KBQQAAhEDEgT5AQ8RCrkBCgQEAAISEgT/AQIbGqoBIFRoZSByZWZl
cnJlciBVUkwgb2YgdGhlIGN1cnJlbnQgcGFnZS4KCiBXaGVuIHVzaW5nIHRoZSBjbGllbnQg
c2lkZSBldmVudCByZXBvcnRpbmcgd2l0aCBKYXZhU2NyaXB0IHBpeGVsIGFuZCBHb29nbGUK
IFRhZyBNYW5hZ2VyLCB0aGlzIHZhbHVlIGlzIGZpbGxlZCBpbiBhdXRvbWF0aWNhbGx5LgoK
DQoFBAACEgUSBP8BAggKDQoFBAACEgESBP8BCRUKDQoFBAACEgMSBP8BGBoK6AMKBAQAAhMS
BIsCAhsa2QMgQSB1bmlxdWUgSUQgb2YgYSB3ZWIgcGFnZSB2aWV3LgoKIFRoaXMgc2hvdWxk
IGJlIGtlcHQgdGhlIHNhbWUgZm9yIGFsbCB1c2VyIGV2ZW50cyB0cmlnZ2VyZWQgZnJvbSB0
aGUgc2FtZQogcGFnZXZpZXcuIEZvciBleGFtcGxlLCBhbiBpdGVtIGRldGFpbCBwYWdlIHZp
ZXcgY291bGQgdHJpZ2dlciBtdWx0aXBsZQogZXZlbnRzIGFzIHRoZSB1c2VyIGlzIGJyb3dz
aW5nIHRoZSBwYWdlLiBUaGUgYHBhZ2VWaWV3SWRgIHByb3BlcnR5IHNob3VsZAogYmUga2Vw
dCB0aGUgc2FtZSBmb3IgYWxsIHRoZXNlIGV2ZW50cyBzbyB0aGF0IHRoZXkgY2FuIGJlIGdy
b3VwZWQgdG9nZXRoZXIKIHByb3Blcmx5LgoKIFdoZW4gdXNpbmcgdGhlIGNsaWVudCBzaWRl
IGV2ZW50IHJlcG9ydGluZyB3aXRoIEphdmFTY3JpcHQgcGl4ZWwgYW5kIEdvb2dsZQogVGFn
IE1hbmFnZXIsIHRoaXMgdmFsdWUgaXMgZmlsbGVkIGluIGF1dG9tYXRpY2FsbHkuCgoNCgUE
AAITBRIEiwICCAoNCgUEAAITARIEiwIJFQoNCgUEAAITAxIEiwIYGgqvAgoEBAACFBIEkgIC
FRqgAiBUaGUgZW50aXR5IGZvciBjdXN0b21lcnMgdGhhdCBtYXkgcnVuIG11bHRpcGxlIGRp
ZmZlcmVudCBlbnRpdGllcywgZG9tYWlucywKIHNpdGVzIG9yIHJlZ2lvbnMsIGZvciBleGFt
cGxlLCBgR29vZ2xlIFVTYCwgYEdvb2dsZSBBZHNgLCBgV2F5bW9gLAogYGdvb2dsZS5jb21g
LCBgeW91dHViZS5jb21gLCBldGMuCiBXZSByZWNvbW1lbmQgdGhhdCB5b3Ugc2V0IHRoaXMg
ZmllbGQgdG8gZ2V0IGJldHRlciBwZXItZW50aXR5IHNlYXJjaCwKIGNvbXBsZXRpb24sIGFu
ZCBwcmVkaWN0aW9uIHJlc3VsdHMuCgoNCgUEAAIUBRIEkgICCAoNCgUEAAIUARIEkgIJDwoN
CgUEAAIUAxIEkgISFApKCgIEARIGlgIAsAIBGjwgRGV0YWlsZWQgcHJvZHVjdCBpbmZvcm1h
dGlvbiBhc3NvY2lhdGVkIHdpdGggYSB1c2VyIGV2ZW50LgoKCwoDBAEBEgSWAggVCsoECgQE
AQIAEgSoAgI/GrsEIFJlcXVpcmVkLiBbUHJvZHVjdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5Qcm9kdWN0XSBpbmZvcm1hdGlvbi4KCiBSZXF1aXJlZCBmaWVsZChzKToKCiAqIFtQcm9k
dWN0LmlkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1Y3QuaWRdCgogT3B0aW9uYWwg
b3ZlcnJpZGUgZmllbGQocyk6CgogKiBbUHJvZHVjdC5wcmljZV9pbmZvXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyLlByb2R1Y3QucHJpY2VfaW5mb10KCiBJZiBhbnkgc3VwcG9ydGVkIG9w
dGlvbmFsIGZpZWxkcyBhcmUgcHJvdmlkZWQsIHdlIHdpbGwgdHJlYXQgdGhlbSBhcyBhIGZ1
bGwKIG92ZXJyaWRlIHdoZW4gbG9va2luZyB1cCBwcm9kdWN0IGluZm9ybWF0aW9uIGZyb20g
dGhlIGNhdGFsb2cuIFRodXMsIGl0IGlzCiBpbXBvcnRhbnQgdG8gZW5zdXJlIHRoYXQgdGhl
IG92ZXJyaWRpbmcgZmllbGRzIGFyZSBhY2N1cmF0ZSBhbmQKIGNvbXBsZXRlLgoKIEFsbCBv
dGhlciBwcm9kdWN0IGZpZWxkcyBhcmUgaWdub3JlZCBhbmQgaW5zdGVhZCBwb3B1bGF0ZWQg
dmlhIGNhdGFsb2cKIGxvb2t1cCBhZnRlciBldmVudCBpbmdlc3Rpb24uCgoNCgUEAQIABhIE
qAICCQoNCgUEAQIAARIEqAIKEQoNCgUEAQIAAxIEqAIUFQoNCgUEAQIACBIEqAIWPgoQCggE
AQIACJwIABIEqAIXPQr8AQoEBAECARIErwICKhrtASBRdWFudGl0eSBvZiB0aGUgcHJvZHVj
dCBhc3NvY2lhdGVkIHdpdGggdGhlIHVzZXIgZXZlbnQuCgogRm9yIGV4YW1wbGUsIHRoaXMg
ZmllbGQgd2lsbCBiZSAyIGlmIHR3byBwcm9kdWN0cyBhcmUgYWRkZWQgdG8gdGhlIHNob3Bw
aW5nCiBjYXJ0IGZvciBgcHVyY2hhc2UtY29tcGxldGVgIGV2ZW50LiBSZXF1aXJlZCBmb3Ig
YGFkZC10by1jYXJ0YCBhbmQKIGBwdXJjaGFzZS1jb21wbGV0ZWAgZXZlbnQgdHlwZXMuCgoN
CgUEAQIBBhIErwICHAoNCgUEAQIBARIErwIdJQoNCgUEAQIBAxIErwIoKQp0CgIEAhIGtAIA
wQIBGmYgRGV0YWlsZWQgY29tcGxldGlvbiBpbmZvcm1hdGlvbiBpbmNsdWRpbmcgY29tcGxl
dGlvbiBhdHRyaWJ1dGlvbiB0b2tlbiBhbmQKIGNsaWNrZWQgY29tcGxldGlvbiBpbmZvLgoK
CwoDBAIBEgS0AggYCpwBCgQEAgIAEgS3AgIqGo0BIENvbXBsZXRpb24gYXR0cmlidXRpb24g
dG9rZW4gaW4KIFtDb21wbGV0ZVF1ZXJ5UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjIuQ29tcGxldGVRdWVyeVJlc3BvbnNlLmF0dHJpYnV0aW9u
X3Rva2VuXS4KCg0KBQQCAgAFEgS3AgIICg0KBQQCAgABEgS3AgklCg0KBQQCAgADEgS3Aigp
CqIBCgQEAgIBEgS7AgIhGpMBIEVuZCB1c2VyIHNlbGVjdGVkCiBbQ29tcGxldGVRdWVyeVJl
c3BvbnNlLkNvbXBsZXRpb25SZXN1bHQuc3VnZ2VzdGlvbl1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5Db21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQ29tcGxldGlvblJlc3VsdC5zdWdnZXN0aW9u
XS4KCg0KBQQCAgEFEgS7AgIICg0KBQQCAgEBEgS7AgkcCg0KBQQCAgEDEgS7Ah8gCr0BCgQE
AgICEgTAAgIeGq4BIEVuZCB1c2VyIHNlbGVjdGVkCiBbQ29tcGxldGVRdWVyeVJlc3BvbnNl
LkNvbXBsZXRpb25SZXN1bHQuc3VnZ2VzdGlvbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5D
b21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQ29tcGxldGlvblJlc3VsdC5zdWdnZXN0aW9uXQogcG9z
aXRpb24sIHN0YXJ0aW5nIGZyb20gMC4KCg0KBQQCAgIFEgTAAgIHCg0KBQQCAgIBEgTAAggZ
Cg0KBQQCAgIDEgTAAhwdCkkKAgQDEgbEAgDcAgEaOyBBIHRyYW5zYWN0aW9uIHJlcHJlc2Vu
dHMgdGhlIGVudGlyZSBwdXJjaGFzZSB0cmFuc2FjdGlvbi4KCgsKAwQDARIExAIIGwpJCgQE
AwIAEgTGAgIQGjsgVGhlIHRyYW5zYWN0aW9uIElEIHdpdGggYSBsZW5ndGggbGltaXQgb2Yg
MTI4IGNoYXJhY3RlcnMuCgoNCgUEAwIABRIExgICCAoNCgUEAwIAARIExgIJCwoNCgUEAwIA
AxIExgIODwrrAQoEBAMCARIEzAICPRrcASBSZXF1aXJlZC4gVG90YWwgbm9uLXplcm8gcmV2
ZW51ZSBvciBncmFuZCB0b3RhbCBhc3NvY2lhdGVkIHdpdGggdGhlCiB0cmFuc2FjdGlvbi4g
VGhpcyB2YWx1ZSBpbmNsdWRlIHNoaXBwaW5nLCB0YXgsIG9yIG90aGVyIGFkanVzdG1lbnRz
IHRvCiB0b3RhbCByZXZlbnVlIHRoYXQgeW91IHdhbnQgdG8gaW5jbHVkZSBhcyBwYXJ0IG9m
IHlvdXIgcmV2ZW51ZQogY2FsY3VsYXRpb25zLgoKDQoFBAMCAQUSBMwCAgcKDQoFBAMCAQES
BMwCCA8KDQoFBAMCAQMSBMwCEhMKDQoFBAMCAQgSBMwCFDwKEAoIBAMCAQicCAASBMwCFTsK
PgoEBAMCAhIEzwICEBowIEFsbCB0aGUgdGF4ZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSB0cmFu
c2FjdGlvbi4KCg0KBQQDAgIFEgTPAgIHCg0KBQQDAgIBEgTPAggLCg0KBQQDAgIDEgTPAg4P
CusCCgQEAwIDEgTYAgIRGtwCIEFsbCB0aGUgY29zdHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBw
cm9kdWN0cy4gVGhlc2UgY2FuIGJlIG1hbnVmYWN0dXJpbmcKIGNvc3RzLCBzaGlwcGluZyBl
eHBlbnNlcyBub3QgYm9ybmUgYnkgdGhlIGVuZCB1c2VyLCBvciBhbnkgb3RoZXIgY29zdHMs
CiBzdWNoIHRoYXQ6CgogKiBQcm9maXQgPSBbcmV2ZW51ZV1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5QdXJjaGFzZVRyYW5zYWN0aW9uLnJldmVudWVdIC0KIFt0YXhdW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjIuUHVyY2hhc2VUcmFuc2FjdGlvbi50YXhdIC0KIFtjb3N0XVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlB1cmNoYXNlVHJhbnNhY3Rpb24uY29zdF0KCg0KBQQDAgMFEgTY
AgIHCg0KBQQDAgMBEgTYAggMCg0KBQQDAgMDEgTYAg8QCksKBAQDAgQSBNsCAkQaPSBSZXF1
aXJlZC4gQ3VycmVuY3kgY29kZS4gVXNlIHRocmVlLWNoYXJhY3RlciBJU08tNDIxNyBjb2Rl
LgoKDQoFBAMCBAUSBNsCAggKDQoFBAMCBAESBNsCCRYKDQoFBAMCBAMSBNsCGRoKDQoFBAMC
BAgSBNsCG0MKEAoIBAMCBAicCAASBNsCHEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::UserEvent::UserEvent ===
    # Fields for UserEvent
    # Field: event_type Type: 9 ()
    # Field: visitor_id Type: 9 ()
    # Field: session_id Type: 9 ()
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: experiment_ids Type: 9 ()
    # Field: attribution_token Type: 9 ()
    # Field: product_details Type: 11 (.google.cloud.retail.v2.ProductDetail)
    # Field: completion_detail Type: 11 (.google.cloud.retail.v2.CompletionDetail)
    # Field: attributes Type: 11 (.google.cloud.retail.v2.UserEvent.AttributesEntry)
    # Field: cart_id Type: 9 ()
    # Field: purchase_transaction Type: 11 (.google.cloud.retail.v2.PurchaseTransaction)
    # Field: search_query Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: offset Type: 5 ()
    # Field: page_categories Type: 9 ()
    # Field: user_info Type: 11 (.google.cloud.retail.v2.UserInfo)
    # Field: uri Type: 9 ()
    # Field: referrer_uri Type: 9 ()
    # Field: page_view_id Type: 9 ()
    # Field: entity Type: 9 ()

# === Message: Google::Cloud::Retail::V2::UserEvent::ProductDetail ===
    # Fields for ProductDetail
    # Field: product Type: 11 (.google.cloud.retail.v2.Product)
    # Field: quantity Type: 11 (.google.protobuf.Int32Value)

# === Message: Google::Cloud::Retail::V2::UserEvent::CompletionDetail ===
    # Fields for CompletionDetail
    # Field: completion_attribution_token Type: 9 ()
    # Field: selected_suggestion Type: 9 ()
    # Field: selected_position Type: 5 ()

# === Message: Google::Cloud::Retail::V2::UserEvent::PurchaseTransaction ===
    # Fields for PurchaseTransaction
    # Field: id Type: 9 ()
    # Field: revenue Type: 2 ()
    # Field: tax Type: 2 ()
    # Field: cost Type: 2 ()
    # Field: currency_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::UserEvent - Compiled Protocol Buffers messages for google/cloud/retail/v2/user_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::UserEvent;

    my $msg = Google::Cloud::Retail::V2::UserEvent::UserEvent->new({
        event_type => $event_type,
        visitor_id => $visitor_id,
        session_id => $session_id,
        event_time => $event_time,
    });

    # Read or update a field
    my $val = $msg->event_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::UserEvent::UserEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/user_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::UserEvent::UserEvent

UserEvent captures all metadata information Retail API needs to know about
how end users interact with customers' website.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<String>

Required. User event type. Allowed values are:

* `add-to-cart`: Products being added to cart.
* `remove-from-cart`: Products being removed from cart.
* `category-page-view`: Special pages such as sale or promotion pages
  viewed.
* `detail-page-view`: Products detail page viewed.
* `home-page-view`: Homepage viewed.
* `purchase-complete`: User finishing a purchase.
* `search`: Product search.
* `shopping-cart-page-view`: User viewing a shopping cart.

=item * C<< $msg->visitor_id() >> / C<< $msg->visitor_id($value) >>

Type: C<String>

Required. A unique identifier for tracking visitors.

For example, this could be implemented with an HTTP cookie, which should be
able to uniquely identify a visitor on a single device. This unique
identifier should not change if the visitor log in/out of the website.

Don't set the field to the same fixed ID for different users. This mixes
the event history of those users together, which results in degraded model
quality.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

The field should not contain PII or user-data. We recommend to use Google
Analytics [Client
ID](https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#clientId)
for this field.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

A unique identifier for tracking a visitor session with a length limit of
128 bytes. A session is an aggregation of an end user behavior in a time
span.

A general guideline to populate the session_id:
1. If user has no activity for 30 min, a new session_id should be assigned.
2. The session_id should be unique across users, suggest use uuid or add
visitor_id as prefix.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Only required for
[UserEventService.ImportUserEvents][google.cloud.retail.v2.UserEventService.ImportUserEvents]
method. Timestamp of when the user event happened.

=item * C<< $msg->experiment_ids() >> / C<< $msg->experiment_ids($value) >>

Type: C<String>

A list of identifiers for the independent experiment groups this user event
belongs to. This is used to distinguish between user events associated with
different experiment setups (e.g. using Retail API, using different
recommendation models).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

Highly recommended for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2.PredictionService.Predict].
This field enables accurate attribution of recommendation model
performance.

The value must be a valid
[PredictResponse.attribution_token][google.cloud.retail.v2.PredictResponse.attribution_token]
for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2.PredictionService.Predict].
The value must be a valid
[SearchResponse.attribution_token][google.cloud.retail.v2.SearchResponse.attribution_token]
for user events that are the result of
[SearchService.Search][google.cloud.retail.v2.SearchService.Search].

This token enables us to accurately attribute page view or purchase back to
the event and the particular predict response containing this
clicked/purchased product. If user clicks on product K in the
recommendation results, pass
[PredictResponse.attribution_token][google.cloud.retail.v2.PredictResponse.attribution_token]
as a URL parameter to product K's page. When recording events on product
K's page, log the
[PredictResponse.attribution_token][google.cloud.retail.v2.PredictResponse.attribution_token]
to this field.

=item * C<< $msg->product_details() >> / C<< $msg->product_details($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::ProductDetail>)

The main product details related to the event.

This field is optional except for the following event types:

* `add-to-cart`
* `detail-page-view`
* `purchase-complete`

In a `search` event, this field represents the products returned to the end
user on the current page (the end user may have not finished browsing the
whole page yet). When a new page is returned to the end user, after
pagination/filtering/ordering even for the same query, a new `search` event
with different
[product_details][google.cloud.retail.v2.UserEvent.product_details] is
desired. The end user may have not finished browsing the whole page yet.

=item * C<< $msg->completion_detail() >> / C<< $msg->completion_detail($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::CompletionDetail>)

The main auto-completion details related to the event.

This field should be set for `search` event when autocomplete function is
enabled and the user clicks a suggestion for search.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::UserEvent::AttributesEntry>)

Extra user event features to include in the recommendation model.

If you provide custom attributes for ingested user events, also include
them in the user events that you associate with prediction requests. Custom
attribute formatting must be consistent between imported events and events
provided with prediction requests. This lets the Retail API use
those custom attributes when training models and serving predictions, which
helps improve recommendation quality.

This field needs to pass all below criteria, otherwise an INVALID_ARGUMENT
error is returned:

* The key must be a UTF-8 encoded string with a length limit of 5,000
  characters.
* For text attributes, at most 400 values are allowed. Empty values are not
  allowed. Each value must be a UTF-8 encoded string with a length limit of
  256 characters.
* For number attributes, at most 400 values are allowed.

For product recommendations, an example of extra user information is
traffic_channel, which is how a user arrives at the site. Users can arrive
at the site by coming to the site directly, coming through Google
search, or in other ways.

=item * C<< $msg->cart_id() >> / C<< $msg->cart_id($value) >>

Type: C<String>

The ID or name of the associated shopping cart. This ID is used
to associate multiple items added or present in the cart before purchase.

This can only be set for `add-to-cart`, `purchase-complete`, or
`shopping-cart-page-view` events.

=item * C<< $msg->purchase_transaction() >> / C<< $msg->purchase_transaction($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::PurchaseTransaction>)

A transaction represents the entire purchase transaction.

Required for `purchase-complete` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->search_query() >> / C<< $msg->search_query($value) >>

Type: C<String>

The user's search query.

See [SearchRequest.query][google.cloud.retail.v2.SearchRequest.query] for
definition.

The value must be a UTF-8 encoded string with a length limit of 5,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

At least one of
[search_query][google.cloud.retail.v2.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter syntax consists of an expression language for constructing a
predicate from one or more fields of the products being filtered.

See [SearchRequest.filter][google.cloud.retail.v2.SearchRequest.filter] for
definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The order in which products are returned.

See [SearchRequest.order_by][google.cloud.retail.v2.SearchRequest.order_by]
for definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int32>

An integer that specifies the current offset for pagination (the 0-indexed
starting location, amongst the products deemed by the API as relevant).

See [SearchRequest.offset][google.cloud.retail.v2.SearchRequest.offset] for
definition.

If this field is negative, an INVALID_ARGUMENT is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->page_categories() >> / C<< $msg->page_categories($value) >>

Type: C<String>

The categories associated with a category page.

To represent full path of category, use '>' sign to separate different
hierarchies. If '>' is part of the category name, replace it with
other character(s).

Category pages include special pages such as sales or promotions. For
instance, a special sale page may have the category hierarchy:
"pageCategories" : ["Sales > 2017 Black Friday Deals"].

Required for `category-page-view` events. At least one of
[search_query][google.cloud.retail.v2.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->user_info() >> / C<< $msg->user_info($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Common::UserInfo>)

User information.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Complete URL (window.location.href) of the user's current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically. Maximum length 5,000
characters.

=item * C<< $msg->referrer_uri() >> / C<< $msg->referrer_uri($value) >>

Type: C<String>

The referrer URL of the current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->page_view_id() >> / C<< $msg->page_view_id($value) >>

Type: C<String>

A unique ID of a web page view.

This should be kept the same for all user events triggered from the same
pageview. For example, an item detail page view could trigger multiple
events as the user is browsing the page. The `pageViewId` property should
be kept the same for all these events so that they can be grouped together
properly.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<String>

The entity for customers that may run multiple different entities, domains,
sites or regions, for example, `Google US`, `Google Ads`, `Waymo`,
`google.com`, `youtube.com`, etc.
We recommend that you set this field to get better per-entity search,
completion, and prediction results.

=back

=head2 Google::Cloud::Retail::V2::UserEvent::ProductDetail

Detailed product information associated with a user event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Product::Product>)

Required. [Product][google.cloud.retail.v2.Product] information.

Required field(s):

* [Product.id][google.cloud.retail.v2.Product.id]

Optional override field(s):

* [Product.price_info][google.cloud.retail.v2.Product.price_info]

If any supported optional fields are provided, we will treat them as a full
override when looking up product information from the catalog. Thus, it is
important to ensure that the overriding fields are accurate and
complete.

All other product fields are ignored and instead populated via catalog
lookup after event ingestion.

=item * C<< $msg->quantity() >> / C<< $msg->quantity($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

Quantity of the product associated with the user event.

For example, this field will be 2 if two products are added to the shopping
cart for `purchase-complete` event. Required for `add-to-cart` and
`purchase-complete` event types.

=back

=head2 Google::Cloud::Retail::V2::UserEvent::CompletionDetail

Detailed completion information including completion attribution token and
clicked completion info.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_attribution_token() >> / C<< $msg->completion_attribution_token($value) >>

Type: C<String>

Completion attribution token in
[CompleteQueryResponse.attribution_token][google.cloud.retail.v2.CompleteQueryResponse.attribution_token].

=item * C<< $msg->selected_suggestion() >> / C<< $msg->selected_suggestion($value) >>

Type: C<String>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2.CompleteQueryResponse.CompletionResult.suggestion].

=item * C<< $msg->selected_position() >> / C<< $msg->selected_position($value) >>

Type: C<Int32>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2.CompleteQueryResponse.CompletionResult.suggestion]
position, starting from 0.

=back

=head2 Google::Cloud::Retail::V2::UserEvent::PurchaseTransaction

A transaction represents the entire purchase transaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The transaction ID with a length limit of 128 characters.

=item * C<< $msg->revenue() >> / C<< $msg->revenue($value) >>

Type: C<Float>

Required. Total non-zero revenue or grand total associated with the
transaction. This value include shipping, tax, or other adjustments to
total revenue that you want to include as part of your revenue
calculations.

=item * C<< $msg->tax() >> / C<< $msg->tax($value) >>

Type: C<Float>

All the taxes associated with the transaction.

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Float>

All the costs associated with the products. These can be manufacturing
costs, shipping expenses not borne by the end user, or any other costs,
such that:

* Profit = [revenue][google.cloud.retail.v2.PurchaseTransaction.revenue] -
[tax][google.cloud.retail.v2.PurchaseTransaction.tax] -
[cost][google.cloud.retail.v2.PurchaseTransaction.cost]

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

Required. Currency code. Use three-character ISO-4217 code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::UserEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
