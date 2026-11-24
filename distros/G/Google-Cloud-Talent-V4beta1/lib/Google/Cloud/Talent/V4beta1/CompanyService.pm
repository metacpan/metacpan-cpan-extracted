package Google::Cloud::Talent::V4beta1::CompanyService;

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
    eval { require Google::Cloud::Talent::V4beta1::Company };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvY29tcGFueV9zZXJ2aWNlLnByb3RvEhtn
b29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvdGFsZW50
L3Y0YmV0YTEvY29tbW9uLnByb3RvGilnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvY29t
cGFueS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9i
dWYvZmllbGRfbWFzay5wcm90byKYAQoUQ3JlYXRlQ29tcGFueVJlcXVlc3QSOwoGcGFyZW50
GAEgASgJQiPgQQL6QR0SG2pvYnMuZ29vZ2xlYXBpcy5jb20vQ29tcGFueVIGcGFyZW50EkMK
B2NvbXBhbnkYAiABKAsyJC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGFueUID
4EECUgdjb21wYW55IkwKEUdldENvbXBhbnlSZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpB
HQobam9icy5nb29nbGVhcGlzLmNvbS9Db21wYW55UgRuYW1lIpgBChRVcGRhdGVDb21wYW55
UmVxdWVzdBJDCgdjb21wYW55GAEgASgLMiQuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGEx
LkNvbXBhbnlCA+BBAlIHY29tcGFueRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siTwoURGVsZXRlQ29tcGFueVJlcXVlc3QS
NwoEbmFtZRgBIAEoCUIj4EEC+kEdChtqb2JzLmdvb2dsZWFwaXMuY29tL0NvbXBhbnlSBG5h
bWUiuwEKFExpc3RDb21wYW5pZXNSZXF1ZXN0EjsKBnBhcmVudBgBIAEoCUIj4EEC+kEdEhtq
b2JzLmdvb2dsZWFwaXMuY29tL0NvbXBhbnlSBnBhcmVudBIdCgpwYWdlX3Rva2VuGAIgASgJ
UglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIqChFyZXF1aXJlX29w
ZW5fam9icxgEIAEoCFIPcmVxdWlyZU9wZW5Kb2JzIs4BChVMaXN0Q29tcGFuaWVzUmVzcG9u
c2USQgoJY29tcGFuaWVzGAEgAygLMiQuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNv
bXBhbnlSCWNvbXBhbmllcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4SSQoIbWV0YWRhdGEYAyABKAsyLS5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuUmVz
cG9uc2VNZXRhZGF0YVIIbWV0YWRhdGEy0gkKDkNvbXBhbnlTZXJ2aWNlEuMBCg1DcmVhdGVD
b21wYW55EjEuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNyZWF0ZUNvbXBhbnlSZXF1
ZXN0GiQuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBhbnkieYLT5JMCYiIwL3Y0
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL3RlbmFudHMvKn0vY29tcGFuaWVzOgEqWisiJi92
NGJldGExL3twYXJlbnQ9cHJvamVjdHMvKn0vY29tcGFuaWVzOgEq2kEOcGFyZW50LGNvbXBh
bnkSzQEKCkdldENvbXBhbnkSLi5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuR2V0Q29t
cGFueVJlcXVlc3QaJC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGFueSJpgtPk
kwJcEjAvdjRiZXRhMS97bmFtZT1wcm9qZWN0cy8qL3RlbmFudHMvKi9jb21wYW5pZXMvKn1a
KBImL3Y0YmV0YTEve25hbWU9cHJvamVjdHMvKi9jb21wYW5pZXMvKn3aQQRuYW1lEu0BCg1V
cGRhdGVDb21wYW55EjEuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLlVwZGF0ZUNvbXBh
bnlSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBhbnkiggGC0+ST
AnIyOC92NGJldGExL3tjb21wYW55Lm5hbWU9cHJvamVjdHMvKi90ZW5hbnRzLyovY29tcGFu
aWVzLyp9OgEqWjMyLi92NGJldGExL3tjb21wYW55Lm5hbWU9cHJvamVjdHMvKi9jb21wYW5p
ZXMvKn06ASraQQdjb21wYW55EsUBCg1EZWxldGVDb21wYW55EjEuZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkRlbGV0ZUNvbXBhbnlSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5ImmC0+STAlwqMC92NGJldGExL3tuYW1lPXByb2plY3RzLyovdGVuYW50cy8qL2NvbXBh
bmllcy8qfVooKiYvdjRiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2NvbXBhbmllcy8qfdpBBG5h
bWUS4wEKDUxpc3RDb21wYW5pZXMSMS5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTGlz
dENvbXBhbmllc1JlcXVlc3QaMi5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTGlzdENv
bXBhbmllc1Jlc3BvbnNlImuC0+STAlwSMC92NGJldGExL3twYXJlbnQ9cHJvamVjdHMvKi90
ZW5hbnRzLyp9L2NvbXBhbmllc1ooEiYvdjRiZXRhMS97cGFyZW50PXByb2plY3RzLyp9L2Nv
bXBhbmllc9pBBnBhcmVudBpsykETam9icy5nb29nbGVhcGlzLmNvbdJBU2h0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9qb2JzQncKH2NvbS5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTFC
E0NvbXBhbnlTZXJ2aWNlUHJvdG9QAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBp
djRiZXRhMS90YWxlbnRwYjt0YWxlbnRwYqICA0NUU0roKwoHEgUOANEBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADIKCQoCAwUSAxcAMwoJCgIDBhID
GAAlCgkKAgMHEgMZACoKCAoBCBIDGwBOCgkKAggLEgMbAE4KCAoBCBIDHAAiCgkKAggKEgMc
ACIKCAoBCBIDHQA0CgkKAggIEgMdADQKCAoBCBIDHgA4CgkKAggBEgMeADgKCAoBCBIDHwAh
CgkKAggkEgMfACEKWAoCBgASBCIAXQEaTCBBIHNlcnZpY2UgdGhhdCBoYW5kbGVzIGNvbXBh
bnkgbWFuYWdlbWVudCwgaW5jbHVkaW5nIENSVUQgYW5kIGVudW1lcmF0aW9uLgoKCgoDBgAB
EgMiCBYKCgoDBgADEgMjAjsKDAoFBgADmQgSAyMCOwoLCgMGAAMSBCQCJi0KDQoFBgADmggS
BCQCJi0KLQoEBgACABIEKQIzAxofIENyZWF0ZXMgYSBuZXcgY29tcGFueSBlbnRpdHkuCgoM
CgUGAAIAARIDKQYTCgwKBQYAAgACEgMpFCgKDAoFBgACAAMSAykzOgoNCgUGAAIABBIEKgQx
BgoRCgkGAAIABLDKvCISBCoEMQYKDAoFBgACAAQSAzIEPAoPCggGAAIABJsIABIDMgQ8CiwK
BAYAAgESBDYCPAMaHiBSZXRyaWV2ZXMgc3BlY2lmaWVkIGNvbXBhbnkuCgoMCgUGAAIBARID
NgYQCgwKBQYAAgECEgM2ESIKDAoFBgACAQMSAzYtNAoNCgUGAAIBBBIENwQ6BgoRCgkGAAIB
BLDKvCISBDcEOgYKDAoFBgACAQQSAzsEMgoPCggGAAIBBJsIABIDOwQyCioKBAYAAgISBD8C
SQMaHCBVcGRhdGVzIHNwZWNpZmllZCBjb21wYW55LgoKDAoFBgACAgESAz8GEwoMCgUGAAIC
AhIDPxQoCgwKBQYAAgIDEgM/MzoKDQoFBgACAgQSBEAERwYKEQoJBgACAgSwyrwiEgRABEcG
CgwKBQYAAgIEEgNIBDUKDwoIBgACAgSbCAASA0gENQplCgQGAAIDEgRNAlMDGlcgRGVsZXRl
cyBzcGVjaWZpZWQgY29tcGFueS4KIFByZXJlcXVpc2l0ZTogVGhlIGNvbXBhbnkgaGFzIG5v
IGpvYnMgYXNzb2NpYXRlZCB3aXRoIGl0LgoKDAoFBgACAwESA00GEwoMCgUGAAIDAhIDTRQo
CgwKBQYAAgMDEgNNM0gKDQoFBgACAwQSBE4EUQYKEQoJBgACAwSwyrwiEgROBFEGCgwKBQYA
AgMEEgNSBDIKDwoIBgACAwSbCAASA1IEMgpACgQGAAIEEgRWAlwDGjIgTGlzdHMgYWxsIGNv
bXBhbmllcyBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoMCgUGAAIEARIDVgYTCgwK
BQYAAgQCEgNWFCgKDAoFBgACBAMSA1YzSAoNCgUGAAIEBBIEVwRaBgoRCgkGAAIEBLDKvCIS
BFcEWgYKDAoFBgACBAQSA1sENAoPCggGAAIEBJsIABIDWwQ0CjYKAgQAEgRgAG8BGiogVGhl
IFJlcXVlc3Qgb2YgdGhlIENyZWF0ZUNvbXBhbnkgbWV0aG9kLgoKCgoDBAABEgNgCBwKmAIK
BAQAAgASBGYCawQaiQIgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHRlbmFudCB1
bmRlciB3aGljaCB0aGUgY29tcGFueSBpcyBjcmVhdGVkLgoKIFRoZSBmb3JtYXQgaXMgInBy
b2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9IiwgZm9yIGV4YW1wbGUs
CiAicHJvamVjdHMvZm9vL3RlbmFudC9iYXIiLiBJZiB0ZW5hbnQgaWQgaXMgdW5zcGVjaWZp
ZWQsIGEgZGVmYXVsdCB0ZW5hbnQKIGlzIGNyZWF0ZWQsIGZvciBleGFtcGxlLCAicHJvamVj
dHMvZm9vIi4KCgwKBQQAAgAFEgNmAggKDAoFBAACAAESA2YJDwoMCgUEAAIAAxIDZhITCg0K
BQQAAgAIEgRmFGsDCg8KCAQAAgAInAgAEgNnBCoKDwoHBAACAAifCBIEaARqBQozCgQEAAIB
EgNuAj8aJiBSZXF1aXJlZC4gVGhlIGNvbXBhbnkgdG8gYmUgY3JlYXRlZC4KCgwKBQQAAgEG
EgNuAgkKDAoFBAACAQESA24KEQoMCgUEAAIBAxIDbhQVCgwKBQQAAgEIEgNuFj4KDwoIBAAC
AQicCAASA24XPQo0CgIEARIEcgB/ARooIFJlcXVlc3QgZm9yIGdldHRpbmcgYSBjb21wYW55
IGJ5IG5hbWUuCgoKCgMEAQESA3IIGQraAgoEBAECABIEewJ+BBrLAiBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIGNvbXBhbnkgdG8gYmUgcmV0cmlldmVkLgoKIFRoZSBm
b3JtYXQgaXMKICJwcm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97dGVuYW50X2lkfS9j
b21wYW5pZXMve2NvbXBhbnlfaWR9IiwgZm9yCiBleGFtcGxlLCAicHJvamVjdHMvYXBpLXRl
c3QtcHJvamVjdC90ZW5hbnRzL2Zvby9jb21wYW5pZXMvYmFyIi4KCiBJZiB0ZW5hbnQgaWQg
aXMgdW5zcGVjaWZpZWQsIHRoZSBkZWZhdWx0IHRlbmFudCBpcyB1c2VkLCBmb3IKIGV4YW1w
bGUsICJwcm9qZWN0cy9hcGktdGVzdC1wcm9qZWN0L2NvbXBhbmllcy9iYXIiLgoKDAoFBAEC
AAUSA3sCCAoMCgUEAQIAARIDewkNCgwKBQQBAgADEgN7EBEKDQoFBAECAAgSBHsSfgMKDwoI
BAECAAicCAASA3wEKgoOCgcEAQIACJ8IEgN9BE0KOQoCBAISBoIBAJMBARorIFJlcXVlc3Qg
Zm9yIHVwZGF0aW5nIGEgc3BlY2lmaWVkIGNvbXBhbnkuCgoLCgMEAgESBIIBCBwKXgoEBAIC
ABIEhQECPxpQIFJlcXVpcmVkLiBUaGUgY29tcGFueSByZXNvdXJjZSB0byByZXBsYWNlIHRo
ZSBjdXJyZW50IHJlc291cmNlIGluIHRoZQogc3lzdGVtLgoKDQoFBAICAAYSBIUBAgkKDQoF
BAICAAESBIUBChEKDQoFBAICAAMSBIUBFBUKDQoFBAICAAgSBIUBFj4KEAoIBAICAAicCAAS
BIUBFz0K0QMKBAQCAgESBJIBAiwawgMgU3Ryb25nbHkgcmVjb21tZW5kZWQgZm9yIHRoZSBi
ZXN0IHNlcnZpY2UgZXhwZXJpZW5jZS4KCiBJZgogW3VwZGF0ZV9tYXNrXVtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEuVXBkYXRlQ29tcGFueVJlcXVlc3QudXBkYXRlX21hc2tdCiBp
cyBwcm92aWRlZCwgb25seSB0aGUgc3BlY2lmaWVkIGZpZWxkcyBpbgogW2NvbXBhbnldW2dv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5VcGRhdGVDb21wYW55UmVxdWVzdC5jb21wYW55
XSBhcmUKIHVwZGF0ZWQuIE90aGVyd2lzZSBhbGwgdGhlIGZpZWxkcyBhcmUgdXBkYXRlZC4K
CiBBIGZpZWxkIG1hc2sgdG8gc3BlY2lmeSB0aGUgY29tcGFueSBmaWVsZHMgdG8gYmUgdXBk
YXRlZC4gT25seQogdG9wIGxldmVsIGZpZWxkcyBvZiBbQ29tcGFueV1bZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NGJldGExLkNvbXBhbnldIGFyZQogc3VwcG9ydGVkLgoKDQoFBAICAQYSBJIB
AhsKDQoFBAICAQESBJIBHCcKDQoFBAICAQMSBJIBKisKLAoCBAMSBpYBAKMBARoeIFJlcXVl
c3QgdG8gZGVsZXRlIGEgY29tcGFueS4KCgsKAwQDARIElgEIHArAAgoEBAMCABIGnwECogEE
Gq8CIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY29tcGFueSB0byBiZSBk
ZWxldGVkLgoKIFRoZSBmb3JtYXQgaXMKICJwcm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50
cy97dGVuYW50X2lkfS9jb21wYW5pZXMve2NvbXBhbnlfaWR9IiwgZm9yCiBleGFtcGxlLCAi
cHJvamVjdHMvZm9vL3RlbmFudHMvYmFyL2NvbXBhbmllcy9iYXoiLgoKIElmIHRlbmFudCBp
ZCBpcyB1bnNwZWNpZmllZCwgdGhlIGRlZmF1bHQgdGVuYW50IGlzIHVzZWQsIGZvcgogZXhh
bXBsZSwgInByb2plY3RzL2Zvby9jb21wYW5pZXMvYmFyIi4KCg0KBQQDAgAFEgSfAQIICg0K
BQQDAgABEgSfAQkNCg0KBQQDAgADEgSfARARCg8KBQQDAgAIEgafARKiAQMKEAoIBAMCAAic
CAASBKABBCoKDwoHBAMCAAifCBIEoQEETQpHCgIEBBIGpgEAxAEBGjkgTGlzdCBjb21wYW5p
ZXMgZm9yIHdoaWNoIHRoZSBjbGllbnQgaGFzIEFDTCB2aXNpYmlsaXR5LgoKCwoDBAQBEgSm
AQgcCqACCgQEBAIAEgauAQKzAQQajwIgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhl
IHRlbmFudCB1bmRlciB3aGljaCB0aGUgY29tcGFueSBpcyBjcmVhdGVkLgoKIFRoZSBmb3Jt
YXQgaXMgInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9IiwgZm9y
IGV4YW1wbGUsCiAicHJvamVjdHMvZm9vL3RlbmFudC9iYXIiLgoKIElmIHRlbmFudCBpZCBp
cyB1bnNwZWNpZmllZCwgdGhlIGRlZmF1bHQgdGVuYW50IHdpbGwgYmUgdXNlZCwgZm9yCiBl
eGFtcGxlLCAicHJvamVjdHMvZm9vIi4KCg0KBQQEAgAFEgSuAQIICg0KBQQEAgABEgSuAQkP
Cg0KBQQEAgADEgSuARITCg8KBQQEAgAIEgauARSzAQMKEAoIBAQCAAicCAASBK8BBCoKEQoH
BAQCAAifCBIGsAEEsgEFCkQKBAQEAgESBLYBAhgaNiBUaGUgc3RhcnRpbmcgaW5kaWNhdG9y
IGZyb20gd2hpY2ggdG8gcmV0dXJuIHJlc3VsdHMuCgoNCgUEBAIBBRIEtgECCAoNCgUEBAIB
ARIEtgEJEwoNCgUEBAIBAxIEtgEWFwqCAQoEBAQCAhIEugECFhp0IFRoZSBtYXhpbXVtIG51
bWJlciBvZiBjb21wYW5pZXMgdG8gYmUgcmV0dXJuZWQsIGF0IG1vc3QgMTAwLgogRGVmYXVs
dCBpcyAxMDAgaWYgYSBub24tcG9zaXRpdmUgbnVtYmVyIGlzIHByb3ZpZGVkLgoKDQoFBAQC
AgUSBLoBAgcKDQoFBAQCAgESBLoBCBEKDQoFBAQCAgMSBLoBFBUKjAIKBAQEAgMSBMMBAh0a
/QEgU2V0IHRvIHRydWUgaWYgdGhlIGNvbXBhbmllcyByZXF1ZXN0ZWQgbXVzdCBoYXZlIG9w
ZW4gam9icy4KCiBEZWZhdWx0cyB0byBmYWxzZS4KCiBJZiB0cnVlLCBhdCBtb3N0CiBbcGFn
ZV9zaXplXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTGlzdENvbXBhbmllc1JlcXVl
c3QucGFnZV9zaXplXSBvZgogY29tcGFuaWVzIGFyZSBmZXRjaGVkLCBhbW9uZyB3aGljaCBv
bmx5IHRob3NlIHdpdGggb3BlbiBqb2JzIGFyZSByZXR1cm5lZC4KCg0KBQQEAgMFEgTDAQIG
Cg0KBQQEAgMBEgTDAQcYCg0KBQQEAgMDEgTDARscCjMKAgQFEgbHAQDRAQEaJSBUaGUgTGlz
dCBjb21wYW5pZXMgcmVzcG9uc2Ugb2JqZWN0LgoKCwoDBAUBEgTHAQgdCjEKBAQFAgASBMkB
AiEaIyBDb21wYW5pZXMgZm9yIHRoZSBjdXJyZW50IGNsaWVudC4KCg0KBQQFAgAEEgTJAQIK
Cg0KBQQFAgAGEgTJAQsSCg0KBQQFAgABEgTJARMcCg0KBQQFAgADEgTJAR8gCj0KBAQFAgES
BMwBAh0aLyBBIHRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4K
Cg0KBQQFAgEFEgTMAQIICg0KBQQFAgEBEgTMAQkYCg0KBQQFAgEDEgTMARscCmAKBAQFAgIS
BNABAiAaUiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGZvciB0aGUgQVBJIGludm9jYXRpb24s
IHN1Y2ggYXMgdGhlIHJlcXVlc3QKIHRyYWNraW5nIGlkLgoKDQoFBAUCAgYSBNABAhIKDQoF
BAUCAgESBNABExsKDQoFBAUCAgMSBNABHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest ===
    # Fields for CreateCompanyRequest
    # Field: parent Type: 9 ()
    # Field: company Type: 11 (.google.cloud.talent.v4beta1.Company)

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest ===
    # Fields for GetCompanyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest ===
    # Fields for UpdateCompanyRequest
    # Field: company Type: 11 (.google.cloud.talent.v4beta1.Company)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest ===
    # Fields for DeleteCompanyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest ===
    # Fields for ListCompaniesRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: require_open_jobs Type: 8 ()

# === Message: Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse ===
    # Fields for ListCompaniesResponse
    # Field: companies Type: 11 (.google.cloud.talent.v4beta1.Company)
    # Field: next_page_token Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.talent.v4beta1.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4beta1::CompanyService::CompanyServiceClient ===
package Google::Cloud::Talent::V4beta1::CompanyService::CompanyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4beta1::CompanyService::CompanyServiceClient

Client stub representing the remote C<CompanyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.CompanyService',
        method         => 'CreateCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Company::Company',
    });
}

sub get_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.CompanyService',
        method         => 'GetCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Company::Company',
    });
}

sub update_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.CompanyService',
        method         => 'UpdateCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Company::Company',
    });
}

sub delete_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.CompanyService',
        method         => 'DeleteCompany',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_companies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.CompanyService',
        method         => 'ListCompanies',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::CompanyService - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/company_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::CompanyService;

    my $msg = Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest->new({
        parent => $parent,
        company => $company,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/company_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest

The Request of the CreateCompany method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the company is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenant/bar". If tenant id is unspecified, a default tenant
is created, for example, "projects/foo".

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Company::Company>)

Required. The company to be created.

=back

=head2 Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest

Request for getting a company by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the company to be retrieved.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/api-test-project/tenants/foo/companies/bar".

If tenant id is unspecified, the default tenant is used, for
example, "projects/api-test-project/companies/bar".

=back

=head2 Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest

Request for updating a specified company.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Company::Company>)

Required. The company resource to replace the current resource in the
system.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Strongly recommended for the best service experience.

If
[update_mask][google.cloud.talent.v4beta1.UpdateCompanyRequest.update_mask]
is provided, only the specified fields in
[company][google.cloud.talent.v4beta1.UpdateCompanyRequest.company] are
updated. Otherwise all the fields are updated.

A field mask to specify the company fields to be updated. Only
top level fields of [Company][google.cloud.talent.v4beta1.Company] are
supported.

=back

=head2 Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest

Request to delete a company.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the company to be deleted.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/foo/tenants/bar/companies/baz".

If tenant id is unspecified, the default tenant is used, for
example, "projects/foo/companies/bar".

=back

=head2 Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest

List companies for which the client has ACL visibility.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the company is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenant/bar".

If tenant id is unspecified, the default tenant will be used, for
example, "projects/foo".

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The starting indicator from which to return results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of companies to be returned, at most 100.
Default is 100 if a non-positive number is provided.

=item * C<< $msg->require_open_jobs() >> / C<< $msg->require_open_jobs($value) >>

Type: C<Bool>

Set to true if the companies requested must have open jobs.

Defaults to false.

If true, at most
[page_size][google.cloud.talent.v4beta1.ListCompaniesRequest.page_size] of
companies are fetched, among which only those with open jobs are returned.

=back

=head2 Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse

The List companies response object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companies() >> / C<< $msg->companies($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Company::Company>)

Companies for the current client.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::CompanyService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
