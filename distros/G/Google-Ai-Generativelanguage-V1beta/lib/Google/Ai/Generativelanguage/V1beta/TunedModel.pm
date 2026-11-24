package Google::Ai::Generativelanguage::V1beta::TunedModel;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS90dW5lZF9tb2RlbC5wcm90
bxIjZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8i5QcKClR1bmVkTW9kZWwSagoSdHVuZWRfbW9kZWxf
c291cmNlGAMgASgLMjUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuVHVu
ZWRNb2RlbFNvdXJjZUID4EEBSABSEHR1bmVkTW9kZWxTb3VyY2USUAoKYmFzZV9tb2RlbBgE
IAEoCUIv4EEF+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9kZWxI
AFIJYmFzZU1vZGVsEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRImCgxkaXNwbGF5X25hbWUY
BSABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YBiABKAlCA+BBAVILZGVz
Y3JpcHRpb24SKgoLdGVtcGVyYXR1cmUYCyABKAJCA+BBAUgBUgt0ZW1wZXJhdHVyZYgBARId
CgV0b3BfcBgMIAEoAkID4EEBSAJSBHRvcFCIAQESHQoFdG9wX2sYDSABKAVCA+BBAUgDUgR0
b3BLiAEBElAKBXN0YXRlGAcgASgOMjUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52
MWJldGEuVHVuZWRNb2RlbC5TdGF0ZUID4EEDUgVzdGF0ZRJACgtjcmVhdGVfdGltZRgIIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJVCgt0dW5pbmdfdGFzaxgKIAEoCzIvLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFiZXRhLlR1bmluZ1Rhc2tCA+BBAlIKdHVuaW5nVGFzaxI5ChZyZWFkZXJfcHJvamVj
dF9udW1iZXJzGA4gAygDQgPgQQFSFHJlYWRlclByb2plY3ROdW1iZXJzIkQKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIKCgZGQUlM
RUQQAzpl6kFiCixnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2Rl
bBIZdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfSoLdHVuZWRNb2RlbHMyCnR1bmVkTW9kZWxC
DgoMc291cmNlX21vZGVsQg4KDF90ZW1wZXJhdHVyZUIICgZfdG9wX3BCCAoGX3RvcF9rIrkB
ChBUdW5lZE1vZGVsU291cmNlElUKC3R1bmVkX21vZGVsGAEgASgJQjTgQQX6QS4KLGdlbmVy
YXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9UdW5lZE1vZGVsUgp0dW5lZE1vZGVsEk4K
CmJhc2VfbW9kZWwYAiABKAlCL+BBA/pBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFw
aXMuY29tL01vZGVsUgliYXNlTW9kZWwirQMKClR1bmluZ1Rhc2sSPgoKc3RhcnRfdGltZRgB
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEkQKDWNv
bXBsZXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDGNv
bXBsZXRlVGltZRJWCglzbmFwc2hvdHMYAyADKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYmV0YS5UdW5pbmdTbmFwc2hvdEID4EEDUglzbmFwc2hvdHMSXAoNdHJhaW5p
bmdfZGF0YRgEIAEoCzIsLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkRh
dGFzZXRCCeBBBOBBAuBBBVIMdHJhaW5pbmdEYXRhEmMKD2h5cGVycGFyYW1ldGVycxgFIAEo
CzI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkh5cGVycGFyYW1ldGVy
c0ID4EEFUg9oeXBlcnBhcmFtZXRlcnMijwIKD0h5cGVycGFyYW1ldGVycxItCg1sZWFybmlu
Z19yYXRlGBAgASgCQgbgQQXgQQFIAFIMbGVhcm5pbmdSYXRlEkIKGGxlYXJuaW5nX3JhdGVf
bXVsdGlwbGllchgRIAEoAkIG4EEF4EEBSABSFmxlYXJuaW5nUmF0ZU11bHRpcGxpZXISKQoL
ZXBvY2hfY291bnQYDiABKAVCA+BBBUgBUgplcG9jaENvdW50iAEBEicKCmJhdGNoX3NpemUY
DyABKAVCA+BBBUgCUgliYXRjaFNpemWIAQFCFgoUbGVhcm5pbmdfcmF0ZV9vcHRpb25CDgoM
X2Vwb2NoX2NvdW50Qg0KC19iYXRjaF9zaXplImwKB0RhdGFzZXQSVgoIZXhhbXBsZXMYASAB
KAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5UdW5pbmdFeGFtcGxl
c0ID4EEBSABSCGV4YW1wbGVzQgkKB2RhdGFzZXQiYAoOVHVuaW5nRXhhbXBsZXMSTgoIZXhh
bXBsZXMYASADKAsyMi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5UdW5p
bmdFeGFtcGxlUghleGFtcGxlcyJhCg1UdW5pbmdFeGFtcGxlEiQKCnRleHRfaW5wdXQYASAB
KAlCA+BBAUgAUgl0ZXh0SW5wdXQSGwoGb3V0cHV0GAMgASgJQgPgQQJSBm91dHB1dEINCgtt
b2RlbF9pbnB1dCKqAQoOVHVuaW5nU25hcHNob3QSFwoEc3RlcBgBIAEoBUID4EEDUgRzdGVw
EhkKBWVwb2NoGAIgASgFQgPgQQNSBWVwb2NoEiAKCW1lYW5fbG9zcxgDIAEoAkID4EEDUght
ZWFuTG9zcxJCCgxjb21wdXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSC2NvbXB1dGVUaW1lQpsBCidjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWJldGFCD1R1bmVkTW9kZWxQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2Fp
L2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWJldGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2Vu
ZXJhdGl2ZWxhbmd1YWdlcGJKw0YKBxIFDgCDAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkK
CAoBCBIDFgB0CgkKAggLEgMWAHQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAwCgkK
AggIEgMYADAKCAoBCBIDGQBACgkKAggBEgMZAEAKTgoCBAASBRwAhQEBGkEgQSBmaW5lLXR1
bmVkIG1vZGVsIGNyZWF0ZWQgdXNpbmcgTW9kZWxTZXJ2aWNlLkNyZWF0ZVR1bmVkTW9kZWwu
CgoKCgMEAAESAxwIEgoLCgMEAAcSBB0CIgQKDQoFBAAHnQgSBB0CIgQKLQoEBAAEABIEJQIx
AxofIFRoZSBzdGF0ZSBvZiB0aGUgdHVuZWQgbW9kZWwuCgoMCgUEAAQAARIDJQcMCjkKBgQA
BAACABIDJwQaGiogVGhlIGRlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoK
DgoHBAAEAAIAARIDJwQVCg4KBwQABAACAAISAycYGQosCgYEAAQAAgESAyoEERodIFRoZSBt
b2RlbCBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDKgQMCg4KBwQABAACAQISAyoP
EAovCgYEAAQAAgISAy0EDxogIFRoZSBtb2RlbCBpcyByZWFkeSB0byBiZSB1c2VkLgoKDgoH
BAAEAAICARIDLQQKCg4KBwQABAACAgISAy0NDgowCgYEAAQAAgMSAzAEDxohIFRoZSBtb2Rl
bCBmYWlsZWQgdG8gYmUgY3JlYXRlZC4KCg4KBwQABAACAwESAzAECgoOCgcEAAQAAgMCEgMw
DQ4KQAoEBAAIABIENAJCAxoyIFRoZSBtb2RlbCB1c2VkIGFzIHRoZSBzdGFydGluZyBwb2lu
dCBmb3IgdHVuaW5nLgoKDAoFBAAIAAESAzQIFApeCgQEAAIAEgQ3BDgxGlAgT3B0aW9uYWwu
IFR1bmVkTW9kZWwgdG8gdXNlIGFzIHRoZSBzdGFydGluZyBwb2ludCBmb3IgdHJhaW5pbmcg
dGhlIG5ldwogbW9kZWwuCgoMCgUEAAIABhIDNwQUCgwKBQQAAgABEgM3FScKDAoFBAACAAMS
AzcqKwoMCgUEAAIACBIDOAgwCg8KCAQAAgAInAgAEgM4CS8KYwoEBAACARIEPARBBhpVIElt
bXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIGBNb2RlbGAgdG8gdHVuZS4KIEV4YW1wbGU6IGBt
b2RlbHMvZ2VtaW5pLTEuNS1mbGFzaC0wMDFgCgoMCgUEAAIBBRIDPAQKCgwKBQQAAgEBEgM8
CxUKDAoFBAACAQMSAzwYGQoNCgUEAAIBCBIEPBpBBQoPCggEAAIBCJwIABIDPQYtCg8KBwQA
AgEInwgSBD4GQAcKnQMKBAQAAgISA04CPhqPAyBPdXRwdXQgb25seS4gVGhlIHR1bmVkIG1v
ZGVsIG5hbWUuIEEgdW5pcXVlIG5hbWUgd2lsbCBiZSBnZW5lcmF0ZWQgb24KIGNyZWF0ZS4g
RXhhbXBsZTogYHR1bmVkTW9kZWxzL2F6Mm1iMGJwdzZpYCBJZiBkaXNwbGF5X25hbWUgaXMg
c2V0IG9uCiBjcmVhdGUsIHRoZSBpZCBwb3J0aW9uIG9mIHRoZSBuYW1lIHdpbGwgYmUgc2V0
IGJ5IGNvbmNhdGVuYXRpbmcgdGhlIHdvcmRzCiBvZiB0aGUgZGlzcGxheV9uYW1lIHdpdGgg
aHlwaGVucyBhbmQgYWRkaW5nIGEgcmFuZG9tIHBvcnRpb24gZm9yCiB1bmlxdWVuZXNzLgoK
IEV4YW1wbGU6CgogICogZGlzcGxheV9uYW1lID0gYFNlbnRlbmNlIFRyYW5zbGF0b3JgCiAg
KiBuYW1lID0gYHR1bmVkTW9kZWxzL3NlbnRlbmNlLXRyYW5zbGF0b3ItdTNiN21gCgoMCgUE
AAICBRIDTgIICgwKBQQAAgIBEgNOCQ0KDAoFBAACAgMSA04QEQoMCgUEAAICCBIDThI9Cg8K
CAQAAgIInAgAEgNOEzwKkAEKBAQAAgMSA1ICQxqCASBPcHRpb25hbC4gVGhlIG5hbWUgdG8g
ZGlzcGxheSBmb3IgdGhpcyBtb2RlbCBpbiB1c2VyIGludGVyZmFjZXMuCiBUaGUgZGlzcGxh
eSBuYW1lIG11c3QgYmUgdXAgdG8gNDAgY2hhcmFjdGVycyBpbmNsdWRpbmcgc3BhY2VzLgoK
DAoFBAACAwUSA1ICCAoMCgUEAAIDARIDUgkVCgwKBQQAAgMDEgNSGBkKDAoFBAACAwgSA1Ia
QgoPCggEAAIDCJwIABIDUhtBCjsKBAQAAgQSA1UCQhouIE9wdGlvbmFsLiBBIHNob3J0IGRl
c2NyaXB0aW9uIG9mIHRoaXMgbW9kZWwuCgoMCgUEAAIEBRIDVQIICgwKBQQAAgQBEgNVCRQK
DAoFBAACBAMSA1UXGAoMCgUEAAIECBIDVRlBCg8KCAQAAgQInAgAEgNVGkAK9wIKBAQAAgUS
A18CSxrpAiBPcHRpb25hbC4gQ29udHJvbHMgdGhlIHJhbmRvbW5lc3Mgb2YgdGhlIG91dHB1
dC4KCiBWYWx1ZXMgY2FuIHJhbmdlIG92ZXIgYFswLjAsMS4wXWAsIGluY2x1c2l2ZS4gQSB2
YWx1ZSBjbG9zZXIgdG8gYDEuMGAgd2lsbAogcHJvZHVjZSByZXNwb25zZXMgdGhhdCBhcmUg
bW9yZSB2YXJpZWQsIHdoaWxlIGEgdmFsdWUgY2xvc2VyIHRvIGAwLjBgIHdpbGwKIHR5cGlj
YWxseSByZXN1bHQgaW4gbGVzcyBzdXJwcmlzaW5nIHJlc3BvbnNlcyBmcm9tIHRoZSBtb2Rl
bC4KCiBUaGlzIHZhbHVlIHNwZWNpZmllcyBkZWZhdWx0IHRvIGJlIHRoZSBvbmUgdXNlZCBi
eSB0aGUgYmFzZSBtb2RlbCB3aGlsZQogY3JlYXRpbmcgdGhlIG1vZGVsLgoKDAoFBAACBQQS
A18CCgoMCgUEAAIFBRIDXwsQCgwKBQQAAgUBEgNfERwKDAoFBAACBQMSA18fIQoMCgUEAAIF
CBIDXyJKCg8KCAQAAgUInAgAEgNfI0kK8gEKBAQAAgYSA2gCRRrkASBPcHRpb25hbC4gRm9y
IE51Y2xldXMgc2FtcGxpbmcuCgogTnVjbGV1cyBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNt
YWxsZXN0IHNldCBvZiB0b2tlbnMgd2hvc2UgcHJvYmFiaWxpdHkKIHN1bSBpcyBhdCBsZWFz
dCBgdG9wX3BgLgoKIFRoaXMgdmFsdWUgc3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdGhlIG9u
ZSB1c2VkIGJ5IHRoZSBiYXNlIG1vZGVsIHdoaWxlCiBjcmVhdGluZyB0aGUgbW9kZWwuCgoM
CgUEAAIGBBIDaAIKCgwKBQQAAgYFEgNoCxAKDAoFBAACBgESA2gRFgoMCgUEAAIGAxIDaBkb
CgwKBQQAAgYIEgNoHEQKDwoIBAACBgicCAASA2gdQwqtAgoEBAACBxIDcgJFGp8CIE9wdGlv
bmFsLiBGb3IgVG9wLWsgc2FtcGxpbmcuCgogVG9wLWsgc2FtcGxpbmcgY29uc2lkZXJzIHRo
ZSBzZXQgb2YgYHRvcF9rYCBtb3N0IHByb2JhYmxlIHRva2Vucy4KIFRoaXMgdmFsdWUgc3Bl
Y2lmaWVzIGRlZmF1bHQgdG8gYmUgdXNlZCBieSB0aGUgYmFja2VuZCB3aGlsZSBtYWtpbmcg
dGhlCiBjYWxsIHRvIHRoZSBtb2RlbC4KCiBUaGlzIHZhbHVlIHNwZWNpZmllcyBkZWZhdWx0
IHRvIGJlIHRoZSBvbmUgdXNlZCBieSB0aGUgYmFzZSBtb2RlbCB3aGlsZQogY3JlYXRpbmcg
dGhlIG1vZGVsLgoKDAoFBAACBwQSA3ICCgoMCgUEAAIHBRIDcgsQCgwKBQQAAgcBEgNyERYK
DAoFBAACBwMSA3IZGwoMCgUEAAIHCBIDchxECg8KCAQAAgcInAgAEgNyHUMKOQoEBAACCBID
dQI+GiwgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgdHVuZWQgbW9kZWwuCgoMCgUE
AAIIBhIDdQIHCgwKBQQAAggBEgN1CA0KDAoFBAACCAMSA3UQEQoMCgUEAAIICBIDdRI9Cg8K
CAQAAggInAgAEgN1EzwKRwoEBAACCRIEeAJ5Mho5IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0
YW1wIHdoZW4gdGhpcyBtb2RlbCB3YXMgY3JlYXRlZC4KCgwKBQQAAgkGEgN4AhsKDAoFBAAC
CQESA3gcJwoMCgUEAAIJAxIDeCorCgwKBQQAAgkIEgN5BjEKDwoIBAACCQicCAASA3kHMApH
CgQEAAIKEgR8An0yGjkgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIG1v
ZGVsIHdhcyB1cGRhdGVkLgoKDAoFBAACCgYSA3wCGwoMCgUEAAIKARIDfBwnCgwKBQQAAgoD
EgN8KisKDAoFBAACCggSA30GMQoPCggEAAIKCJwIABIDfQcwCkcKBAQAAgsSBIABAkcaOSBS
ZXF1aXJlZC4gVGhlIHR1bmluZyB0YXNrIHRoYXQgY3JlYXRlcyB0aGUgdHVuZWQgbW9kZWwu
CgoNCgUEAAILBhIEgAECDAoNCgUEAAILARIEgAENGAoNCgUEAAILAxIEgAEbHQoNCgUEAAIL
CBIEgAEeRgoQCggEAAILCJwIABIEgAEfRQpdCgQEAAIMEgaDAQKEAS8aTSBPcHRpb25hbC4g
TGlzdCBvZiBwcm9qZWN0IG51bWJlcnMgdGhhdCBoYXZlIHJlYWQgYWNjZXNzIHRvIHRoZSB0
dW5lZCBtb2RlbC4KCg0KBQQAAgwEEgSDAQIKCg0KBQQAAgwFEgSDAQsQCg0KBQQAAgwBEgSD
AREnCg0KBQQAAgwDEgSDASosCg0KBQQAAgwIEgSEAQYuChAKCAQAAgwInAgAEgSEAQctCkEK
AgQBEgaIAQCbAQEaMyBUdW5lZCBtb2RlbCBhcyBhIHNvdXJjZSBmb3IgdHJhaW5pbmcgYSBu
ZXcgbW9kZWwuCgoLCgMEAQESBIgBCBgKmwEKBAQBAgASBowBApEBBBqKASBJbW11dGFibGUu
IFRoZSBuYW1lIG9mIHRoZSBgVHVuZWRNb2RlbGAgdG8gdXNlIGFzIHRoZSBzdGFydGluZyBw
b2ludCBmb3IKIHRyYWluaW5nIHRoZSBuZXcgbW9kZWwuCiBFeGFtcGxlOiBgdHVuZWRNb2Rl
bHMvbXktdHVuZWQtbW9kZWxgCgoNCgUEAQIABRIEjAECCAoNCgUEAQIAARIEjAEJFAoNCgUE
AQIAAxIEjAEXGAoPCgUEAQIACBIGjAEZkQEDChAKCAQBAgAInAgAEgSNAQQrChEKBwQBAgAI
nwgSBo4BBJABBQqFAQoEBAECARIGlQECmgEEGnUgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9m
IHRoZSBiYXNlIGBNb2RlbGAgdGhpcyBgVHVuZWRNb2RlbGAgd2FzIHR1bmVkIGZyb20uCiBF
eGFtcGxlOiBgbW9kZWxzL2dlbWluaS0xLjUtZmxhc2gtMDAxYAoKDQoFBAECAQUSBJUBAggK
DQoFBAECAQESBJUBCRMKDQoFBAECAQMSBJUBFhcKDwoFBAECAQgSBpUBGJoBAwoQCggEAQIB
CJwIABIElgEELQoRCgcEAQIBCJ8IEgaXAQSZAQUKNgoCBAISBp4BALUBARooIFR1bmluZyB0
YXNrcyB0aGF0IGNyZWF0ZSB0dW5lZCBtb2RlbHMuCgoLCgMEAgESBJ4BCBIKTAoEBAICABIG
oAECoQEyGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0dW5pbmcgdGhpcyBt
b2RlbCBzdGFydGVkLgoKDQoFBAICAAYSBKABAhsKDQoFBAICAAESBKABHCYKDQoFBAICAAMS
BKABKSoKDQoFBAICAAgSBKEBBjEKEAoIBAICAAicCAASBKEBBzAKTgoEBAICARIGpAECpQEy
Gj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0dW5pbmcgdGhpcyBtb2RlbCBj
b21wbGV0ZWQuCgoNCgUEAgIBBhIEpAECGwoNCgUEAgIBARIEpAEcKQoNCgUEAgIBAxIEpAEs
LQoNCgUEAgIBCBIEpQEGMQoQCggEAgIBCJwIABIEpQEHMAo/CgQEAgICEgaoAQKpATIaLyBP
dXRwdXQgb25seS4gTWV0cmljcyBjb2xsZWN0ZWQgZHVyaW5nIHR1bmluZy4KCg0KBQQCAgIE
EgSoAQIKCg0KBQQCAgIGEgSoAQsZCg0KBQQCAgIBEgSoARojCg0KBQQCAgIDEgSoASYnCg0K
BQQCAgIIEgSpAQYxChAKCAQCAgIInAgAEgSpAQcwCksKBAQCAgMSBqwBArABBBo7IFJlcXVp
cmVkLiBJbnB1dCBvbmx5LiBJbW11dGFibGUuIFRoZSBtb2RlbCB0cmFpbmluZyBkYXRhLgoK
DQoFBAICAwYSBKwBAgkKDQoFBAICAwESBKwBChcKDQoFBAICAwMSBKwBGhsKDwoFBAICAwgS
BqwBHLABAwoQCggEAgIDCJwIABIErQEELAoQCggEAgIDCJwIARIErgEEKgoQCggEAgIDCJwI
AhIErwEEKwp5CgQEAgIEEgS0AQJQGmsgSW1tdXRhYmxlLiBIeXBlcnBhcmFtZXRlcnMgY29u
dHJvbGxpbmcgdGhlIHR1bmluZyBwcm9jZXNzLiBJZiBub3QgcHJvdmlkZWQsCiBkZWZhdWx0
IHZhbHVlcyB3aWxsIGJlIHVzZWQuCgoNCgUEAgIEBhIEtAECEQoNCgUEAgIEARIEtAESIQoN
CgUEAgIEAxIEtAEkJQoNCgUEAgIECBIEtAEmTwoQCggEAgIECJwIABIEtAEnTgp+CgIEAxIG
uQEA1wEBGnAgSHlwZXJwYXJhbWV0ZXJzIGNvbnRyb2xsaW5nIHRoZSB0dW5pbmcgcHJvY2Vz
cy4gUmVhZCBtb3JlIGF0CiBodHRwczovL2FpLmdvb2dsZS5kZXYvZG9jcy9tb2RlbF90dW5p
bmdfZ3VpZGFuY2UKCgsKAwQDARIEuQEIFwpFCgQEAwgAEga7AQLNAQMaNSBPcHRpb25zIGZv
ciBzcGVjaWZ5aW5nIGxlYXJuaW5nIHJhdGUgZHVyaW5nIHR1bmluZy4KCg0KBQQDCAABEgS7
AQgcCrwBCgQEAwIAEga/AQTCAQYaqwEgT3B0aW9uYWwuIEltbXV0YWJsZS4gVGhlIGxlYXJu
aW5nIHJhdGUgaHlwZXJwYXJhbWV0ZXIgZm9yIHR1bmluZy4KIElmIG5vdCBzZXQsIGEgZGVm
YXVsdCBvZiAwLjAwMSBvciAwLjAwMDIgd2lsbCBiZSBjYWxjdWxhdGVkIGJhc2VkIG9uIHRo
ZQogbnVtYmVyIG9mIHRyYWluaW5nIGV4YW1wbGVzLgoKDQoFBAMCAAUSBL8BBAkKDQoFBAMC
AAESBL8BChcKDQoFBAMCAAMSBL8BGhwKDwoFBAMCAAgSBr8BHcIBBQoQCggEAwIACJwIABIE
wAEGLQoQCggEAwIACJwIARIEwQEGLArUAgoEBAMCARIGyQEEzAEGGsMCIE9wdGlvbmFsLiBJ
bW11dGFibGUuIFRoZSBsZWFybmluZyByYXRlIG11bHRpcGxpZXIgaXMgdXNlZCB0byBjYWxj
dWxhdGUgYQogZmluYWwgbGVhcm5pbmdfcmF0ZSBiYXNlZCBvbiB0aGUgZGVmYXVsdCAocmVj
b21tZW5kZWQpIHZhbHVlLiBBY3R1YWwKIGxlYXJuaW5nIHJhdGUgOj0gbGVhcm5pbmdfcmF0
ZV9tdWx0aXBsaWVyICogZGVmYXVsdCBsZWFybmluZyByYXRlIERlZmF1bHQKIGxlYXJuaW5n
IHJhdGUgaXMgZGVwZW5kZW50IG9uIGJhc2UgbW9kZWwgYW5kIGRhdGFzZXQgc2l6ZS4gSWYg
bm90IHNldCwgYQogZGVmYXVsdCBvZiAxLjAgd2lsbCBiZSB1c2VkLgoKDQoFBAMCAQUSBMkB
BAkKDQoFBAMCAQESBMkBCiIKDQoFBAMCAQMSBMkBJScKDwoFBAMCAQgSBskBKMwBBQoQCggE
AwIBCJwIABIEygEGLQoQCggEAwIBCJwIARIEywEGLAqUAQoEBAMCAhIE0QECTBqFASBJbW11
dGFibGUuIFRoZSBudW1iZXIgb2YgdHJhaW5pbmcgZXBvY2hzLiBBbiBlcG9jaCBpcyBvbmUg
cGFzcyB0aHJvdWdoIHRoZQogdHJhaW5pbmcgZGF0YS4gSWYgbm90IHNldCwgYSBkZWZhdWx0
IG9mIDUgd2lsbCBiZSB1c2VkLgoKDQoFBAMCAgQSBNEBAgoKDQoFBAMCAgUSBNEBCxAKDQoF
BAMCAgESBNEBERwKDQoFBAMCAgMSBNEBHyEKDQoFBAMCAggSBNEBIksKEAoIBAMCAgicCAAS
BNEBI0oKnwEKBAQDAgMSBNYBAksakAEgSW1tdXRhYmxlLiBUaGUgYmF0Y2ggc2l6ZSBoeXBl
cnBhcmFtZXRlciBmb3IgdHVuaW5nLgogSWYgbm90IHNldCwgYSBkZWZhdWx0IG9mIDQgb3Ig
MTYgd2lsbCBiZSB1c2VkIGJhc2VkIG9uIHRoZSBudW1iZXIgb2YKIHRyYWluaW5nIGV4YW1w
bGVzLgoKDQoFBAMCAwQSBNYBAgoKDQoFBAMCAwUSBNYBCxAKDQoFBAMCAwESBNYBERsKDQoF
BAMCAwMSBNYBHiAKDQoFBAMCAwgSBNYBIUoKEAoIBAMCAwicCAASBNYBIkkKMwoCBAQSBtoB
AOABARolIERhdGFzZXQgZm9yIHRyYWluaW5nIG9yIHZhbGlkYXRpb24uCgoLCgMEBAESBNoB
CA8KOQoEBAQIABIG3AEC3wEDGikgSW5saW5lIGRhdGEgb3IgYSByZWZlcmVuY2UgdG8gdGhl
IGRhdGEuCgoNCgUEBAgAARIE3AEIDwpICgQEBAIAEgTeAQRJGjogT3B0aW9uYWwuIElubGlu
ZSBleGFtcGxlcyB3aXRoIHNpbXBsZSBpbnB1dC9vdXRwdXQgdGV4dC4KCg0KBQQEAgAGEgTe
AQQSCg0KBQQEAgABEgTeARMbCg0KBQQEAgADEgTeAR4fCg0KBQQEAgAIEgTeASBIChAKCAQE
AgAInAgAEgTeASFHCk0KAgQFEgbjAQDnAQEaPyBBIHNldCBvZiB0dW5pbmcgZXhhbXBsZXMu
IENhbiBiZSB0cmFpbmluZyBvciB2YWxpZGF0aW9uIGRhdGEuCgoLCgMEBQESBOMBCBYKfAoE
BAUCABIE5gECJhpuIFRoZSBleGFtcGxlcy4gRXhhbXBsZSBpbnB1dCBjYW4gYmUgZm9yIHRl
eHQgb3IgZGlzY3VzcywgYnV0IGFsbCBleGFtcGxlcwogaW4gYSBzZXQgbXVzdCBiZSBvZiB0
aGUgc2FtZSB0eXBlLgoKDQoFBAUCAAQSBOYBAgoKDQoFBAUCAAYSBOYBCxgKDQoFBAUCAAES
BOYBGSEKDQoFBAUCAAMSBOYBJCUKLAoCBAYSBuoBAPMBARoeIEEgc2luZ2xlIGV4YW1wbGUg
Zm9yIHR1bmluZy4KCgsKAwQGARIE6gEIFQo6CgQEBggAEgbsAQLvAQMaKiBUaGUgaW5wdXQg
dG8gdGhlIG1vZGVsIGZvciB0aGlzIGV4YW1wbGUuCgoNCgUEBggAARIE7AEIEworCgQEBgIA
EgTuAQRDGh0gT3B0aW9uYWwuIFRleHQgbW9kZWwgaW5wdXQuCgoNCgUEBgIABRIE7gEECgoN
CgUEBgIAARIE7gELFQoNCgUEBgIAAxIE7gEYGQoNCgUEBgIACBIE7gEaQgoQCggEBgIACJwI
ABIE7gEbQQo0CgQEBgIBEgTyAQI9GiYgUmVxdWlyZWQuIFRoZSBleHBlY3RlZCBtb2RlbCBv
dXRwdXQuCgoNCgUEBgIBBRIE8gECCAoNCgUEBgIBARIE8gEJDwoNCgUEBgIBAxIE8gESEwoN
CgUEBgIBCBIE8gEUPAoQCggEBgIBCJwIABIE8gEVOwowCgIEBxIG9gEAgwIBGiIgUmVjb3Jk
IGZvciBhIHNpbmdsZSB0dW5pbmcgc3RlcC4KCgsKAwQHARIE9gEIFgotCgQEBwIAEgT4AQI9
Gh8gT3V0cHV0IG9ubHkuIFRoZSB0dW5pbmcgc3RlcC4KCg0KBQQHAgAFEgT4AQIHCg0KBQQH
AgABEgT4AQgMCg0KBQQHAgADEgT4AQ8QCg0KBQQHAgAIEgT4ARE8ChAKCAQHAgAInAgAEgT4
ARI7Cj0KBAQHAgESBPsBAj4aLyBPdXRwdXQgb25seS4gVGhlIGVwb2NoIHRoaXMgc3RlcCB3
YXMgcGFydCBvZi4KCg0KBQQHAgEFEgT7AQIHCg0KBQQHAgEBEgT7AQgNCg0KBQQHAgEDEgT7
ARARCg0KBQQHAgEIEgT7ARI9ChAKCAQHAgEInAgAEgT7ARM8ClIKBAQHAgISBP4BAkIaRCBP
dXRwdXQgb25seS4gVGhlIG1lYW4gbG9zcyBvZiB0aGUgdHJhaW5pbmcgZXhhbXBsZXMgZm9y
IHRoaXMgc3RlcC4KCg0KBQQHAgIFEgT+AQIHCg0KBQQHAgIBEgT+AQgRCg0KBQQHAgIDEgT+
ARQVCg0KBQQHAgIIEgT+ARZBChAKCAQHAgIInAgAEgT+ARdACksKBAQHAgMSBoECAoICMho7
IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBtZXRyaWMgd2FzIGNvbXB1
dGVkLgoKDQoFBAcCAwYSBIECAhsKDQoFBAcCAwESBIECHCgKDQoFBAcCAwMSBIECKywKDQoF
BAcCAwgSBIICBjEKEAoIBAcCAwicCAASBIICBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel ===
    # Fields for TunedModel
    # Field: tuned_model_source Type: 11 (.google.ai.generativelanguage.v1beta.TunedModelSource)
    # Field: base_model Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: temperature Type: 2 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: state Type: 14 (.google.ai.generativelanguage.v1beta.TunedModel.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: tuning_task Type: 11 (.google.ai.generativelanguage.v1beta.TuningTask)
    # Field: reader_project_numbers Type: 3 ()

# Enum: TunedModel::State
our $TunedModel_STATE_UNSPECIFIED = 0;
our $TunedModel_CREATING = 1;
our $TunedModel_ACTIVE = 2;
our $TunedModel_FAILED = 3;

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModelSource ===
    # Fields for TunedModelSource
    # Field: tuned_model Type: 9 ()
    # Field: base_model Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TuningTask ===
    # Fields for TuningTask
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1beta.TuningSnapshot)
    # Field: training_data Type: 11 (.google.ai.generativelanguage.v1beta.Dataset)
    # Field: hyperparameters Type: 11 (.google.ai.generativelanguage.v1beta.Hyperparameters)

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::Hyperparameters ===
    # Fields for Hyperparameters
    # Field: learning_rate Type: 2 ()
    # Field: learning_rate_multiplier Type: 2 ()
    # Field: epoch_count Type: 5 ()
    # Field: batch_size Type: 5 ()

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::Dataset ===
    # Fields for Dataset
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1beta.TuningExamples)

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExamples ===
    # Fields for TuningExamples
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1beta.TuningExample)

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExample ===
    # Fields for TuningExample
    # Field: text_input Type: 9 ()
    # Field: output Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::TunedModel::TuningSnapshot ===
    # Fields for TuningSnapshot
    # Field: step Type: 5 ()
    # Field: epoch Type: 5 ()
    # Field: mean_loss Type: 2 ()
    # Field: compute_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TunedModel - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/tuned_model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TunedModel;

    my $msg = Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel->new({
        tuned_model_source => $tuned_model_source,
        base_model => $base_model,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->tuned_model_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/tuned_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel

A fine-tuned model created using ModelService.CreateTunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model_source() >> / C<< $msg->tuned_model_source($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModelSource>)

Optional. TunedModel to use as the starting point for training the new
model.

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Immutable. The name of the `Model` to tune.
Example: `models/gemini-1.5-flash-001`

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The tuned model name. A unique name will be generated on
create. Example: `tunedModels/az2mb0bpw6i` If display_name is set on
create, the id portion of the name will be set by concatenating the words
of the display_name with hyphens and adding a random portion for
uniqueness.

Example:

 * display_name = `Sentence Translator`
 * name = `tunedModels/sentence-translator-u3b7m`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The name to display for this model in user interfaces.
The display name must be up to 40 characters including spaces.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A short description of this model.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.

Values can range over `[0.0,1.0]`, inclusive. A value closer to `1.0` will
produce responses that are more varied, while a value closer to `0.0` will
typically result in less surprising responses from the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. For Nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. For Top-k sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
This value specifies default to be used by the backend while making the
call to the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::State>)

Output only. The state of the tuned model.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was updated.

=item * C<< $msg->tuning_task() >> / C<< $msg->tuning_task($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::TuningTask>)

Required. The tuning task that creates the tuned model.

=item * C<< $msg->reader_project_numbers() >> / C<< $msg->reader_project_numbers($value) >>

Type: C<Int64>

Optional. List of project numbers that have read access to the tuned model.

=back

=head3 Enum: TunedModel::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModelSource

Tuned model as a source for training a new model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<String>

Immutable. The name of the `TunedModel` to use as the starting point for
training the new model.
Example: `tunedModels/my-tuned-model`

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Output only. The name of the base `Model` this `TunedModel` was tuned from.
Example: `models/gemini-1.5-flash-001`

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TuningTask

Tuning tasks that create tuned models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model started.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model completed.

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::TuningSnapshot>)

Output only. Metrics collected during tuning.

=item * C<< $msg->training_data() >> / C<< $msg->training_data($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::Dataset>)

Required. Input only. Immutable. The model training data.

=item * C<< $msg->hyperparameters() >> / C<< $msg->hyperparameters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::Hyperparameters>)

Immutable. Hyperparameters controlling the tuning process. If not provided,
default values will be used.

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::Hyperparameters

Hyperparameters controlling the tuning process. Read more at
https://ai.google.dev/docs/model_tuning_guidance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->learning_rate() >> / C<< $msg->learning_rate($value) >>

Type: C<Float>

Optional. Immutable. The learning rate hyperparameter for tuning.
If not set, a default of 0.001 or 0.0002 will be calculated based on the
number of training examples.

=item * C<< $msg->learning_rate_multiplier() >> / C<< $msg->learning_rate_multiplier($value) >>

Type: C<Float>

Optional. Immutable. The learning rate multiplier is used to calculate a
final learning_rate based on the default (recommended) value. Actual
learning rate := learning_rate_multiplier * default learning rate Default
learning rate is dependent on base model and dataset size. If not set, a
default of 1.0 will be used.

=item * C<< $msg->epoch_count() >> / C<< $msg->epoch_count($value) >>

Type: C<Int32>

Immutable. The number of training epochs. An epoch is one pass through the
training data. If not set, a default of 5 will be used.

=item * C<< $msg->batch_size() >> / C<< $msg->batch_size($value) >>

Type: C<Int32>

Immutable. The batch size hyperparameter for tuning.
If not set, a default of 4 or 16 will be used based on the number of
training examples.

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::Dataset

Dataset for training or validation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExamples>)

Optional. Inline examples with simple input/output text.

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExamples

A set of tuning examples. Can be training or validation data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExample>)

The examples. Example input can be for text or discuss, but all examples
in a set must be of the same type.

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TuningExample

A single example for tuning.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_input() >> / C<< $msg->text_input($value) >>

Type: C<String>

Optional. Text model input.

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<String>

Required. The expected model output.

=back

=head2 Google::Ai::Generativelanguage::V1beta::TunedModel::TuningSnapshot

Record for a single tuning step.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Int32>

Output only. The tuning step.

=item * C<< $msg->epoch() >> / C<< $msg->epoch($value) >>

Type: C<Int32>

Output only. The epoch this step was part of.

=item * C<< $msg->mean_loss() >> / C<< $msg->mean_loss($value) >>

Type: C<Float>

Output only. The mean loss of the training examples for this step.

=item * C<< $msg->compute_time() >> / C<< $msg->compute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this metric was computed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::TunedModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
