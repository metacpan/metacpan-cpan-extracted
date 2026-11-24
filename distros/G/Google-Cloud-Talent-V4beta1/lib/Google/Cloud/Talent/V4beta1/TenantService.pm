package Google::Cloud::Talent::V4beta1::TenantService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Talent::V4beta1::Common };
    eval { require Google::Cloud::Talent::V4beta1::Tenant };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvdGVuYW50X3NlcnZpY2UucHJvdG8SG2dv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC90YWxlbnQv
djRiZXRhMS9jb21tb24ucHJvdG8aKGdvb2dsZS9jbG91ZC90YWxlbnQvdjRiZXRhMS90ZW5h
bnQucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8ipAEKE0NyZWF0ZVRlbmFudFJlcXVlc3QSSwoGcGFyZW50GAEg
ASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2pl
Y3RSBnBhcmVudBJACgZ0ZW5hbnQYAiABKAsyIy5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuVGVuYW50QgPgQQJSBnRlbmFudCJKChBHZXRUZW5hbnRSZXF1ZXN0EjYKBG5hbWUYASAB
KAlCIuBBAvpBHAoaam9icy5nb29nbGVhcGlzLmNvbS9UZW5hbnRSBG5hbWUilAEKE1VwZGF0
ZVRlbmFudFJlcXVlc3QSQAoGdGVuYW50GAEgASgLMiMuZ29vZ2xlLmNsb3VkLnRhbGVudC52
NGJldGExLlRlbmFudEID4EECUgZ0ZW5hbnQSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29n
bGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIk0KE0RlbGV0ZVRlbmFudFJlcXVl
c3QSNgoEbmFtZRgBIAEoCUIi4EEC+kEcChpqb2JzLmdvb2dsZWFwaXMuY29tL1RlbmFudFIE
bmFtZSKdAQoSTGlzdFRlbmFudHNSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitj
bG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSHQoK
cGFnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNp
emUixwEKE0xpc3RUZW5hbnRzUmVzcG9uc2USPQoHdGVuYW50cxgBIAMoCzIjLmdvb2dsZS5j
bG91ZC50YWxlbnQudjRiZXRhMS5UZW5hbnRSB3RlbmFudHMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuEkkKCG1ldGFkYXRhGAMgASgLMi0uZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NGJldGExLlJlc3BvbnNlTWV0YWRhdGFSCG1ldGFkYXRhMqAHCg1UZW5hbnRT
ZXJ2aWNlEqYBCgxDcmVhdGVUZW5hbnQSMC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEu
Q3JlYXRlVGVuYW50UmVxdWVzdBojLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5UZW5h
bnQiP4LT5JMCKSIkL3Y0YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qfS90ZW5hbnRzOgEq2kEN
cGFyZW50LHRlbmFudBKUAQoJR2V0VGVuYW50Ei0uZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJl
dGExLkdldFRlbmFudFJlcXVlc3QaIy5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuVGVu
YW50IjOC0+STAiYSJC92NGJldGExL3tuYW1lPXByb2plY3RzLyovdGVuYW50cy8qfdpBBG5h
bWUSpgEKDFVwZGF0ZVRlbmFudBIwLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5VcGRh
dGVUZW5hbnRSZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLlRlbmFudCI/
gtPkkwIwMisvdjRiZXRhMS97dGVuYW50Lm5hbWU9cHJvamVjdHMvKi90ZW5hbnRzLyp9OgEq
2kEGdGVuYW50Eo0BCgxEZWxldGVUZW5hbnQSMC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuRGVsZXRlVGVuYW50UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSIzgtPkkwIm
KiQvdjRiZXRhMS97bmFtZT1wcm9qZWN0cy8qL3RlbmFudHMvKn3aQQRuYW1lEqcBCgtMaXN0
VGVuYW50cxIvLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5MaXN0VGVuYW50c1JlcXVl
c3QaMC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTGlzdFRlbmFudHNSZXNwb25zZSI1
gtPkkwImEiQvdjRiZXRhMS97cGFyZW50PXByb2plY3RzLyp9L3RlbmFudHPaQQZwYXJlbnQa
bMpBE2pvYnMuZ29vZ2xlYXBpcy5jb23SQVNodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvam9i
c0J2Ch9jb20uZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExQhJUZW5hbnRTZXJ2aWNlUHJv
dG9QAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjRiZXRhMS90YWxlbnRwYjt0
YWxlbnRwYqICA0NUU0qjJAoHEgUOALABAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgID
AxIDFQAjCgkKAgMEEgMWADIKCQoCAwUSAxcAMgoJCgIDBhIDGAAlCgkKAgMHEgMZACoKCAoB
CBIDGwBOCgkKAggLEgMbAE4KCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAzCgkKAggI
EgMdADMKCAoBCBIDHgA4CgkKAggBEgMeADgKCAoBCBIDHwAhCgkKAggkEgMfACEKVwoCBgAS
BCIAUQEaSyBBIHNlcnZpY2UgdGhhdCBoYW5kbGVzIHRlbmFudCBtYW5hZ2VtZW50LCBpbmNs
dWRpbmcgQ1JVRCBhbmQgZW51bWVyYXRpb24uCgoKCgMGAAESAyIIFQoKCgMGAAMSAyMCOwoM
CgUGAAOZCBIDIwI7CgsKAwYAAxIEJAImLQoNCgUGAAOaCBIEJAImLQosCgQGAAIAEgQpAi8D
Gh4gQ3JlYXRlcyBhIG5ldyB0ZW5hbnQgZW50aXR5LgoKDAoFBgACAAESAykGEgoMCgUGAAIA
AhIDKRMmCgwKBQYAAgADEgMpMTcKDQoFBgACAAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0G
CgwKBQYAAgAEEgMuBDsKDwoIBgACAASbCAASAy4EOworCgQGAAIBEgQyAjcDGh0gUmV0cmll
dmVzIHNwZWNpZmllZCB0ZW5hbnQuCgoMCgUGAAIBARIDMgYPCgwKBQYAAgECEgMyECAKDAoF
BgACAQMSAzIrMQoNCgUGAAIBBBIEMwQ1BgoRCgkGAAIBBLDKvCISBDMENQYKDAoFBgACAQQS
AzYEMgoPCggGAAIBBJsIABIDNgQyCikKBAYAAgISBDoCQAMaGyBVcGRhdGVzIHNwZWNpZmll
ZCB0ZW5hbnQuCgoMCgUGAAICARIDOgYSCgwKBQYAAgICEgM6EyYKDAoFBgACAgMSAzoxNwoN
CgUGAAICBBIEOwQ+BgoRCgkGAAICBLDKvCISBDsEPgYKDAoFBgACAgQSAz8ENAoPCggGAAIC
BJsIABIDPwQ0CikKBAYAAgMSBEMCSAMaGyBEZWxldGVzIHNwZWNpZmllZCB0ZW5hbnQuCgoM
CgUGAAIDARIDQwYSCgwKBQYAAgMCEgNDEyYKDAoFBgACAwMSA0MxRgoNCgUGAAIDBBIERARG
BgoRCgkGAAIDBLDKvCISBEQERgYKDAoFBgACAwQSA0cEMgoPCggGAAIDBJsIABIDRwQyCj4K
BAYAAgQSBEsCUAMaMCBMaXN0cyBhbGwgdGVuYW50cyBhc3NvY2lhdGVkIHdpdGggdGhlIHBy
b2plY3QuCgoMCgUGAAIEARIDSwYRCgwKBQYAAgQCEgNLEiQKDAoFBgACBAMSA0svQgoNCgUG
AAIEBBIETAROBgoRCgkGAAIEBLDKvCISBEwETgYKDAoFBgACBAQSA08ENAoPCggGAAIEBJsI
ABIDTwQ0CjUKAgQAEgRUAGIBGikgVGhlIFJlcXVlc3Qgb2YgdGhlIENyZWF0ZVRlbmFudCBt
ZXRob2QuCgoKCgMEAAESA1QIGwqhAQoEBAACABIEWQJeBBqSASBSZXF1aXJlZC4gUmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgcHJvamVjdCB1bmRlciB3aGljaCB0aGUgdGVuYW50IGlzIGNyZWF0
ZWQuCgogVGhlIGZvcm1hdCBpcyAicHJvamVjdHMve3Byb2plY3RfaWR9IiwgZm9yIGV4YW1w
bGUsCiAicHJvamVjdHMvZm9vIi4KCgwKBQQAAgAFEgNZAggKDAoFBAACAAESA1kJDwoMCgUE
AAIAAxIDWRITCg0KBQQAAgAIEgRZFF4DCg8KCAQAAgAInAgAEgNaBCoKDwoHBAACAAifCBIE
WwRdBQoyCgQEAAIBEgNhAj0aJSBSZXF1aXJlZC4gVGhlIHRlbmFudCB0byBiZSBjcmVhdGVk
LgoKDAoFBAACAQYSA2ECCAoMCgUEAAIBARIDYQkPCgwKBQQAAgEDEgNhEhMKDAoFBAACAQgS
A2EUPAoPCggEAAIBCJwIABIDYRU7CjMKAgQBEgRlAG4BGicgUmVxdWVzdCBmb3IgZ2V0dGlu
ZyBhIHRlbmFudCBieSBuYW1lLgoKCgoDBAEBEgNlCBgKsgEKBAQBAgASBGoCbQQaowEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSB0ZW5hbnQgdG8gYmUgcmV0cmlldmVk
LgoKIFRoZSBmb3JtYXQgaXMgInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5h
bnRfaWR9IiwgZm9yIGV4YW1wbGUsCiAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyIi4KCgwK
BQQBAgAFEgNqAggKDAoFBAECAAESA2oJDQoMCgUEAQIAAxIDahARCg0KBQQBAgAIEgRqEm0D
Cg8KCAQBAgAInAgAEgNrBCoKDgoHBAECAAifCBIDbARMCjcKAgQCEgVxAIIBARoqIFJlcXVl
c3QgZm9yIHVwZGF0aW5nIGEgc3BlY2lmaWVkIHRlbmFudC4KCgoKAwQCARIDcQgbClwKBAQC
AgASA3QCPRpPIFJlcXVpcmVkLiBUaGUgdGVuYW50IHJlc291cmNlIHRvIHJlcGxhY2UgdGhl
IGN1cnJlbnQgcmVzb3VyY2UgaW4gdGhlCiBzeXN0ZW0uCgoMCgUEAgIABhIDdAIICgwKBQQC
AgABEgN0CQ8KDAoFBAICAAMSA3QSEwoMCgUEAgIACBIDdBQ8Cg8KCAQCAgAInAgAEgN0FTsK
ygMKBAQCAgESBIEBAiwauwMgU3Ryb25nbHkgcmVjb21tZW5kZWQgZm9yIHRoZSBiZXN0IHNl
cnZpY2UgZXhwZXJpZW5jZS4KCiBJZgogW3VwZGF0ZV9tYXNrXVtnb29nbGUuY2xvdWQudGFs
ZW50LnY0YmV0YTEuVXBkYXRlVGVuYW50UmVxdWVzdC51cGRhdGVfbWFza10KIGlzIHByb3Zp
ZGVkLCBvbmx5IHRoZSBzcGVjaWZpZWQgZmllbGRzIGluCiBbdGVuYW50XVtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEuVXBkYXRlVGVuYW50UmVxdWVzdC50ZW5hbnRdIGFyZQogdXBk
YXRlZC4gT3RoZXJ3aXNlIGFsbCB0aGUgZmllbGRzIGFyZSB1cGRhdGVkLgoKIEEgZmllbGQg
bWFzayB0byBzcGVjaWZ5IHRoZSB0ZW5hbnQgZmllbGRzIHRvIGJlIHVwZGF0ZWQuIE9ubHkK
IHRvcCBsZXZlbCBmaWVsZHMgb2YgW1RlbmFudF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJl
dGExLlRlbmFudF0gYXJlCiBzdXBwb3J0ZWQuCgoNCgUEAgIBBhIEgQECGwoNCgUEAgIBARIE
gQEcJwoNCgUEAgIBAxIEgQEqKworCgIEAxIGhQEAjgEBGh0gUmVxdWVzdCB0byBkZWxldGUg
YSB0ZW5hbnQuCgoLCgMEAwESBIUBCBsKsgEKBAQDAgASBooBAo0BBBqhASBSZXF1aXJlZC4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHRlbmFudCB0byBiZSBkZWxldGVkLgoKIFRoZSBm
b3JtYXQgaXMgInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9Iiwg
Zm9yIGV4YW1wbGUsCiAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyIi4KCg0KBQQDAgAFEgSK
AQIICg0KBQQDAgABEgSKAQkNCg0KBQQDAgADEgSKARARCg8KBQQDAgAIEgaKARKNAQMKEAoI
BAMCAAicCAASBIsBBCoKDwoHBAMCAAifCBIEjAEETApFCgIEBBIGkQEAowEBGjcgTGlzdCB0
ZW5hbnRzIGZvciB3aGljaCB0aGUgY2xpZW50IGhhcyBBQ0wgdmlzaWJpbGl0eS4KCgsKAwQE
ARIEkQEIGgqjAQoEBAQCABIGlgECmwEEGpIBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9m
IHRoZSBwcm9qZWN0IHVuZGVyIHdoaWNoIHRoZSB0ZW5hbnQgaXMgY3JlYXRlZC4KCiBUaGUg
Zm9ybWF0IGlzICJwcm9qZWN0cy97cHJvamVjdF9pZH0iLCBmb3IgZXhhbXBsZSwKICJwcm9q
ZWN0cy9mb28iLgoKDQoFBAQCAAUSBJYBAggKDQoFBAQCAAESBJYBCQ8KDQoFBAQCAAMSBJYB
EhMKDwoFBAQCAAgSBpYBFJsBAwoQCggEBAIACJwIABIElwEEKgoRCgcEBAIACJ8IEgaYAQSa
AQUKRAoEBAQCARIEngECGBo2IFRoZSBzdGFydGluZyBpbmRpY2F0b3IgZnJvbSB3aGljaCB0
byByZXR1cm4gcmVzdWx0cy4KCg0KBQQEAgEFEgSeAQIICg0KBQQEAgEBEgSeAQkTCg0KBQQE
AgEDEgSeARYXCoABCgQEBAICEgSiAQIWGnIgVGhlIG1heGltdW0gbnVtYmVyIG9mIHRlbmFu
dHMgdG8gYmUgcmV0dXJuZWQsIGF0IG1vc3QgMTAwLgogRGVmYXVsdCBpcyAxMDAgaWYgYSBu
b24tcG9zaXRpdmUgbnVtYmVyIGlzIHByb3ZpZGVkLgoKDQoFBAQCAgUSBKIBAgcKDQoFBAQC
AgESBKIBCBEKDQoFBAQCAgMSBKIBFBUKMQoCBAUSBqYBALABARojIFRoZSBMaXN0IHRlbmFu
dHMgcmVzcG9uc2Ugb2JqZWN0LgoKCwoDBAUBEgSmAQgbCi8KBAQFAgASBKgBAh4aISBUZW5h
bnRzIGZvciB0aGUgY3VycmVudCBjbGllbnQuCgoNCgUEBQIABBIEqAECCgoNCgUEBQIABhIE
qAELEQoNCgUEBQIAARIEqAESGQoNCgUEBQIAAxIEqAEcHQo9CgQEBQIBEgSrAQIdGi8gQSB0
b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuCgoNCgUEBQIBBRIE
qwECCAoNCgUEBQIBARIEqwEJGAoNCgUEBQIBAxIEqwEbHApgCgQEBQICEgSvAQIgGlIgQWRk
aXRpb25hbCBpbmZvcm1hdGlvbiBmb3IgdGhlIEFQSSBpbnZvY2F0aW9uLCBzdWNoIGFzIHRo
ZSByZXF1ZXN0CiB0cmFja2luZyBpZC4KCg0KBQQFAgIGEgSvAQISCg0KBQQFAgIBEgSvARMb
Cg0KBQQFAgIDEgSvAR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest ===
    # Fields for CreateTenantRequest
    # Field: parent Type: 9 ()
    # Field: tenant Type: 11 (.google.cloud.talent.v4beta1.Tenant)

# === Message: Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest ===
    # Fields for GetTenantRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest ===
    # Fields for UpdateTenantRequest
    # Field: tenant Type: 11 (.google.cloud.talent.v4beta1.Tenant)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest ===
    # Fields for DeleteTenantRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest ===
    # Fields for ListTenantsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse ===
    # Fields for ListTenantsResponse
    # Field: tenants Type: 11 (.google.cloud.talent.v4beta1.Tenant)
    # Field: next_page_token Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.talent.v4beta1.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4beta1::TenantService::TenantServiceClient ===
package Google::Cloud::Talent::V4beta1::TenantService::TenantServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4beta1::TenantService::TenantServiceClient

Client stub representing the remote C<TenantService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<talent.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'talent.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub create_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.TenantService',
        method         => 'CreateTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Tenant::Tenant',
    });
}

sub get_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.TenantService',
        method         => 'GetTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Tenant::Tenant',
    });
}

sub update_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.TenantService',
        method         => 'UpdateTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Tenant::Tenant',
    });
}

sub delete_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.TenantService',
        method         => 'DeleteTenant',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_tenants {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.TenantService',
        method         => 'ListTenants',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::TenantService - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/tenant_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::TenantService;

    my $msg = Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest->new({
        parent => $parent,
        tenant => $tenant,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/tenant_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest

The Request of the CreateTenant method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project under which the tenant is created.

The format is "projects/{project_id}", for example,
"projects/foo".

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Tenant::Tenant>)

Required. The tenant to be created.

=back

=head2 Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest

Request for getting a tenant by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tenant to be retrieved.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=back

=head2 Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest

Request for updating a specified tenant.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Tenant::Tenant>)

Required. The tenant resource to replace the current resource in the
system.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Strongly recommended for the best service experience.

If
[update_mask][google.cloud.talent.v4beta1.UpdateTenantRequest.update_mask]
is provided, only the specified fields in
[tenant][google.cloud.talent.v4beta1.UpdateTenantRequest.tenant] are
updated. Otherwise all the fields are updated.

A field mask to specify the tenant fields to be updated. Only
top level fields of [Tenant][google.cloud.talent.v4beta1.Tenant] are
supported.

=back

=head2 Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest

Request to delete a tenant.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tenant to be deleted.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=back

=head2 Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest

List tenants for which the client has ACL visibility.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project under which the tenant is created.

The format is "projects/{project_id}", for example,
"projects/foo".

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The starting indicator from which to return results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of tenants to be returned, at most 100.
Default is 100 if a non-positive number is provided.

=back

=head2 Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse

The List tenants response object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tenants() >> / C<< $msg->tenants($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Tenant::Tenant>)

Tenants for the current client.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::TenantService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
