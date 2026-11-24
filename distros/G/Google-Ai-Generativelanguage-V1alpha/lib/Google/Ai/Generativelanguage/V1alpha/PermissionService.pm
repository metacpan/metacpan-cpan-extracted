package Google::Ai::Generativelanguage::V1alpha::PermissionService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::Permission };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvcGVybWlzc2lvbl9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaNWdvb2ds
ZS9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvdjFhbHBoYS9wZXJtaXNzaW9uLnByb3RvGhxnb29n
bGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90byK+AQoXQ3JlYXRlUGVybWlzc2lvblJlcXVlc3QSTAoGcGFyZW50GAEgASgJ
QjTgQQL6QS4SLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9u
UgZwYXJlbnQSVQoKcGVybWlzc2lvbhgCIAEoCzIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFhbHBoYS5QZXJtaXNzaW9uQgPgQQJSCnBlcm1pc3Npb24iYAoUR2V0UGVybWlz
c2lvblJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixnZW5lcmF0aXZlbGFuZ3VhZ2Uu
Z29vZ2xlYXBpcy5jb20vUGVybWlzc2lvblIEbmFtZSKBAQoWTGlzdFBlcm1pc3Npb25zUmVx
dWVzdBIhCgZwYXJlbnQYASABKAlCCeBBAvpBAwoBKlIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
biKVAQoXTGlzdFBlcm1pc3Npb25zUmVzcG9uc2USUgoLcGVybWlzc2lvbnMYASADKAsyMC5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuUGVybWlzc2lvblILcGVybWlz
c2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrIBChdVcGRh
dGVQZXJtaXNzaW9uUmVxdWVzdBJVCgpwZXJtaXNzaW9uGAEgASgLMjAuZ29vZ2xlLmFpLmdl
bmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlBlcm1pc3Npb25CA+BBAlIKcGVybWlzc2lvbhJA
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIK
dXBkYXRlTWFzayJjChdEZWxldGVQZXJtaXNzaW9uUmVxdWVzdBJICgRuYW1lGAEgASgJQjTg
QQL6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9uUgRu
YW1lIo4BChhUcmFuc2Zlck93bmVyc2hpcFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEu
EixnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vUGVybWlzc2lvblIEbmFtZRIo
Cg1lbWFpbF9hZGRyZXNzGAIgASgJQgPgQQJSDGVtYWlsQWRkcmVzcyIbChlUcmFuc2Zlck93
bmVyc2hpcFJlc3BvbnNlMoIMChFQZXJtaXNzaW9uU2VydmljZRKQAgoQQ3JlYXRlUGVybWlz
c2lvbhI9Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5DcmVhdGVQZXJt
aXNzaW9uUmVxdWVzdBowLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5Q
ZXJtaXNzaW9uIooBgtPkkwJwIisvdjFhbHBoYS97cGFyZW50PXR1bmVkTW9kZWxzLyp9L3Bl
cm1pc3Npb25zOgpwZXJtaXNzaW9uWjUiJy92MWFscGhhL3twYXJlbnQ9Y29ycG9yYS8qfS9w
ZXJtaXNzaW9uczoKcGVybWlzc2lvbtpBEXBhcmVudCxwZXJtaXNzaW9uEuQBCg1HZXRQZXJt
aXNzaW9uEjouZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkdldFBlcm1p
c3Npb25SZXF1ZXN0GjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlBl
cm1pc3Npb24iZYLT5JMCWBIrL3YxYWxwaGEve25hbWU9dHVuZWRNb2RlbHMvKi9wZXJtaXNz
aW9ucy8qfVopEicvdjFhbHBoYS97bmFtZT1jb3Jwb3JhLyovcGVybWlzc2lvbnMvKn3aQQRu
YW1lEvcBCg9MaXN0UGVybWlzc2lvbnMSPC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdl
LnYxYWxwaGEuTGlzdFBlcm1pc3Npb25zUmVxdWVzdBo9Lmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFhbHBoYS5MaXN0UGVybWlzc2lvbnNSZXNwb25zZSJngtPkkwJYEisvdjFh
bHBoYS97cGFyZW50PXR1bmVkTW9kZWxzLyp9L3Blcm1pc3Npb25zWikSJy92MWFscGhhL3tw
YXJlbnQ9Y29ycG9yYS8qfS9wZXJtaXNzaW9uc9pBBnBhcmVudBKsAgoQVXBkYXRlUGVybWlz
c2lvbhI9Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5VcGRhdGVQZXJt
aXNzaW9uUmVxdWVzdBowLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5Q
ZXJtaXNzaW9uIqYBgtPkkwKGATI2L3YxYWxwaGEve3Blcm1pc3Npb24ubmFtZT10dW5lZE1v
ZGVscy8qL3Blcm1pc3Npb25zLyp9OgpwZXJtaXNzaW9uWkAyMi92MWFscGhhL3twZXJtaXNz
aW9uLm5hbWU9Y29ycG9yYS8qL3Blcm1pc3Npb25zLyp9OgpwZXJtaXNzaW9u2kEWcGVybWlz
c2lvbix1cGRhdGVfbWFzaxLQAQoQRGVsZXRlUGVybWlzc2lvbhI9Lmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5EZWxldGVQZXJtaXNzaW9uUmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSJlgtPkkwJYKisvdjFhbHBoYS97bmFtZT10dW5lZE1vZGVscy8q
L3Blcm1pc3Npb25zLyp9WikqJy92MWFscGhhL3tuYW1lPWNvcnBvcmEvKi9wZXJtaXNzaW9u
cy8qfdpBBG5hbWUS0AEKEVRyYW5zZmVyT3duZXJzaGlwEj4uZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWFscGhhLlRyYW5zZmVyT3duZXJzaGlwUmVxdWVzdBo/Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5UcmFuc2Zlck93bmVyc2hpcFJlc3BvbnNl
IjqC0+STAjQiLy92MWFscGhhL3tuYW1lPXR1bmVkTW9kZWxzLyp9OnRyYW5zZmVyT3duZXJz
aGlwOgEqGiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb21CpAEKKGNvbS5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGFCFlBlcm1pc3Npb25TZXJ2aWNl
UHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBp
djFhbHBoYS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqUKwoH
EgUOANwBJAq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJ
CgIDABIDEgA/CgkKAgMBEgMTACYKCQoCAwISAxQAIQoJCgIDAxIDFQApCgkKAgMEEgMWACMK
CQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAdQoJCgIICxIDGgB1CggKAQgSAxsAIgoJ
CgIIChIDGwAiCggKAQgSAxwANwoJCgIICBIDHAA3CggKAQgSAx0AQQoJCgIIARIDHQBBCk4K
AgYAEgQgAGQBGkIgUHJvdmlkZXMgbWV0aG9kcyBmb3IgbWFuYWdpbmcgcGVybWlzc2lvbnMg
dG8gUGFMTSBBUEkgcmVzb3VyY2VzLgoKCgoDBgABEgMgCBkKCgoDBgADEgMhAkkKDAoFBgAD
mQgSAyECSQo7CgQGAAIAEgQkAi4DGi0gQ3JlYXRlIGEgcGVybWlzc2lvbiB0byBhIHNwZWNp
ZmljIHJlc291cmNlLgoKDAoFBgACAAESAyQGFgoMCgUGAAIAAhIDJBcuCgwKBQYAAgADEgMk
OUMKDQoFBgACAAQSBCUELAYKEQoJBgACAASwyrwiEgQlBCwGCgwKBQYAAgAEEgMtBD8KDwoI
BgACAASbCAASAy0EPwo9CgQGAAIBEgQxAjcDGi8gR2V0cyBpbmZvcm1hdGlvbiBhYm91dCBh
IHNwZWNpZmljIFBlcm1pc3Npb24uCgoMCgUGAAIBARIDMQYTCgwKBQYAAgECEgMxFCgKDAoF
BgACAQMSAzEzPQoNCgUGAAIBBBIEMgQ1BgoRCgkGAAIBBLDKvCISBDIENQYKDAoFBgACAQQS
AzYEMgoPCggGAAIBBJsIABIDNgQyCjwKBAYAAgISBDoCQQMaLiBMaXN0cyBwZXJtaXNzaW9u
cyBmb3IgdGhlIHNwZWNpZmljIHJlc291cmNlLgoKDAoFBgACAgESAzoGFQoMCgUGAAICAhID
OhYsCgwKBQYAAgIDEgM7DyYKDQoFBgACAgQSBDwEPwYKEQoJBgACAgSwyrwiEgQ8BD8GCgwK
BQYAAgIEEgNABDQKDwoIBgACAgSbCAASA0AENAonCgQGAAIDEgREAk4DGhkgVXBkYXRlcyB0
aGUgcGVybWlzc2lvbi4KCgwKBQYAAgMBEgNEBhYKDAoFBgACAwISA0QXLgoMCgUGAAIDAxID
RDlDCg0KBQYAAgMEEgRFBEwGChEKCQYAAgMEsMq8IhIERQRMBgoMCgUGAAIDBBIDTQRECg8K
CAYAAgMEmwgAEgNNBEQKJwoEBgACBBIEUQJYAxoZIERlbGV0ZXMgdGhlIHBlcm1pc3Npb24u
CgoMCgUGAAIEARIDUQYWCgwKBQYAAgQCEgNRFy4KDAoFBgACBAMSA1IPJAoNCgUGAAIEBBIE
UwRWBgoRCgkGAAIEBLDKvCISBFMEVgYKDAoFBgACBAQSA1cEMgoPCggGAAIEBJsIABIDVwQy
CqwBCgQGAAIFEgRdAmMDGp0BIFRyYW5zZmVycyBvd25lcnNoaXAgb2YgdGhlIHR1bmVkIG1v
ZGVsLgogVGhpcyBpcyB0aGUgb25seSB3YXkgdG8gY2hhbmdlIG93bmVyc2hpcCBvZiB0aGUg
dHVuZWQgbW9kZWwuCiBUaGUgY3VycmVudCBvd25lciB3aWxsIGJlIGRvd25ncmFkZWQgdG8g
d3JpdGVyIHJvbGUuCgoMCgUGAAIFARIDXQYXCgwKBQYAAgUCEgNdGDAKDAoFBgACBQMSA14P
KAoNCgUGAAIFBBIEXwRiBgoRCgkGAAIFBLDKvCISBF8EYgYKLwoCBAASBGcAdQEaIyBSZXF1
ZXN0IHRvIGNyZWF0ZSBhIGBQZXJtaXNzaW9uYC4KCgoKAwQAARIDZwgfCoMBCgQEAAIAEgRs
AnEEGnUgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIGBQZXJtaXNzaW9u
YC4KIEZvcm1hdHM6CiAgICBgdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfWAKICAgIGBjb3Jw
b3JhL3tjb3JwdXN9YAoKDAoFBAACAAUSA2wCCAoMCgUEAAIAARIDbAkPCgwKBQQAAgADEgNs
EhMKDQoFBAACAAgSBGwUcQMKDwoIBAACAAicCAASA20EKgoPCgcEAAIACJ8IEgRuBHAFCjIK
BAQAAgESA3QCRRolIFJlcXVpcmVkLiBUaGUgcGVybWlzc2lvbiB0byBjcmVhdGUuCgoMCgUE
AAIBBhIDdAIMCgwKBQQAAgEBEgN0DRcKDAoFBAACAQMSA3QaGwoMCgUEAAIBCBIDdBxECg8K
CAQAAgEInAgAEgN0HUMKTQoCBAESBXgAhAEBGkAgUmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZv
cm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIGBQZXJtaXNzaW9uYC4KCgoKAwQBARIDeAgcCrQB
CgQEAQIAEgV+AoMBBBqkASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHBl
cm1pc3Npb24uCgogRm9ybWF0czoKICAgIGB0dW5lZE1vZGVscy97dHVuZWRfbW9kZWx9L3Bl
cm1pc3Npb25zL3twZXJtaXNzaW9ufWAKICAgIGBjb3Jwb3JhL3tjb3JwdXN9L3Blcm1pc3Np
b25zL3twZXJtaXNzaW9ufWAKCgwKBQQBAgAFEgN+AggKDAoFBAECAAESA34JDQoMCgUEAQIA
AxIDfhARCg4KBQQBAgAIEgV+EoMBAwoPCggEAQIACJwIABIDfwQqChEKBwQBAgAInwgSBoAB
BIIBBQowCgIEAhIGhwEAoQEBGiIgUmVxdWVzdCBmb3IgbGlzdGluZyBwZXJtaXNzaW9ucy4K
CgsKAwQCARIEhwEIHgqEAQoEBAICABIGjAECjwEEGnQgUmVxdWlyZWQuIFRoZSBwYXJlbnQg
cmVzb3VyY2Ugb2YgdGhlIHBlcm1pc3Npb25zLgogRm9ybWF0czoKICAgIGB0dW5lZE1vZGVs
cy97dHVuZWRfbW9kZWx9YAogICAgYGNvcnBvcmEve2NvcnB1c31gCgoNCgUEAgIABRIEjAEC
CAoNCgUEAgIAARIEjAEJDwoNCgUEAgIAAxIEjAESEwoPCgUEAgIACBIGjAEUjwEDChAKCAQC
AgAInAgAEgSNAQQqCg8KBwQCAgAInwgSBI4BBDMKlgIKBAQCAgESBJcBAj8ahwIgT3B0aW9u
YWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBgUGVybWlzc2lvbmBzIHRvIHJldHVybiAocGVy
IHBhZ2UpLgogVGhlIHNlcnZpY2UgbWF5IHJldHVybiBmZXdlciBwZXJtaXNzaW9ucy4KCiBJ
ZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMCBwZXJtaXNzaW9ucyB3aWxsIGJlIHJldHVybmVk
LgogVGhpcyBtZXRob2QgcmV0dXJucyBhdCBtb3N0IDEwMDAgcGVybWlzc2lvbnMgcGVyIHBh
Z2UsIGV2ZW4gaWYgeW91IHBhc3MKIGxhcmdlciBwYWdlX3NpemUuCgoNCgUEAgIBBRIElwEC
BwoNCgUEAgIBARIElwEIEQoNCgUEAgIBAxIElwEUFQoNCgUEAgIBCBIElwEWPgoQCggEAgIB
CJwIABIElwEXPQrEAgoEBAICAhIEoAECQRq1AiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCBy
ZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RQZXJtaXNzaW9uc2AgY2FsbC4KCiBQcm92
aWRlIHRoZSBgcGFnZV90b2tlbmAgcmV0dXJuZWQgYnkgb25lIHJlcXVlc3QgYXMgYW4gYXJn
dW1lbnQgdG8gdGhlCiBuZXh0IHJlcXVlc3QgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4K
CiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBM
aXN0UGVybWlzc2lvbnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhl
IHBhZ2UgdG9rZW4uCgoNCgUEAgICBRIEoAECCAoNCgUEAgICARIEoAEJEwoNCgUEAgICAxIE
oAEWFwoNCgUEAgICCBIEoAEYQAoQCggEAgICCJwIABIEoAEZPwpcCgIEAxIGpQEArQEBGk4g
UmVzcG9uc2UgZnJvbSBgTGlzdFBlcm1pc3Npb25zYCBjb250YWluaW5nIGEgcGFnaW5hdGVk
IGxpc3Qgb2YKIHBlcm1pc3Npb25zLgoKCwoDBAMBEgSlAQgfCiUKBAQDAgASBKcBAiYaFyBS
ZXR1cm5lZCBwZXJtaXNzaW9ucy4KCg0KBQQDAgAEEgSnAQIKCg0KBQQDAgAGEgSnAQsVCg0K
BQQDAgABEgSnARYhCg0KBQQDAgADEgSnASQlCooBCgQEAwIBEgSsAQIdGnwgQSB0b2tlbiwg
d2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2UuCgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gbW9yZSBw
YWdlcy4KCg0KBQQDAgEFEgSsAQIICg0KBQQDAgEBEgSsAQkYCg0KBQQDAgEDEgSsARscCjMK
AgQEEgawAQC6AQEaJSBSZXF1ZXN0IHRvIHVwZGF0ZSB0aGUgYFBlcm1pc3Npb25gLgoKCwoD
BAQBEgSwAQgfCoEBCgQEBAIAEgS0AQJFGnMgUmVxdWlyZWQuIFRoZSBwZXJtaXNzaW9uIHRv
IHVwZGF0ZS4KCiBUaGUgcGVybWlzc2lvbidzIGBuYW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlk
ZW50aWZ5IHRoZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZS4KCg0KBQQEAgAGEgS0AQIMCg0KBQQE
AgABEgS0AQ0XCg0KBQQEAgADEgS0ARobCg0KBQQEAgAIEgS0ARxEChAKCAQEAgAInAgAEgS0
AR1DCmsKBAQEAgESBrgBArkBLxpbIFJlcXVpcmVkLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8g
dXBkYXRlLiBBY2NlcHRlZCBvbmVzOgogIC0gcm9sZSAoYFBlcm1pc3Npb24ucm9sZWAgZmll
bGQpCgoNCgUEBAIBBhIEuAECGwoNCgUEBAIBARIEuAEcJwoNCgUEBAIBAxIEuAEqKwoNCgUE
BAIBCBIEuQEGLgoQCggEBAIBCJwIABIEuQEHLQozCgIEBRIGvQEAyAEBGiUgUmVxdWVzdCB0
byBkZWxldGUgdGhlIGBQZXJtaXNzaW9uYC4KCgsKAwQFARIEvQEIHwq0AQoEBAUCABIGwgEC
xwEEGqMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcGVybWlzc2lvbi4K
IEZvcm1hdHM6CiAgICBgdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfS9wZXJtaXNzaW9ucy97
cGVybWlzc2lvbn1gCiAgICBgY29ycG9yYS97Y29ycHVzfS9wZXJtaXNzaW9ucy97cGVybWlz
c2lvbn1gCgoNCgUEBQIABRIEwgECCAoNCgUEBQIAARIEwgEJDQoNCgUEBQIAAxIEwgEQEQoP
CgUEBQIACBIGwgESxwEDChAKCAQFAgAInAgAEgTDAQQqChEKBwQFAgAInwgSBsQBBMYBBQpF
CgIEBhIGywEA2QEBGjcgUmVxdWVzdCB0byB0cmFuc2ZlciB0aGUgb3duZXJzaGlwIG9mIHRo
ZSB0dW5lZCBtb2RlbC4KCgsKAwQGARIEywEIIAp7CgQEBgIAEgbPAQLUAQQaayBSZXF1aXJl
ZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHR1bmVkIG1vZGVsIHRvIHRyYW5zZmVyIG93
bmVyc2hpcC4KCiBGb3JtYXQ6IGB0dW5lZE1vZGVscy9teS1tb2RlbC1pZGAKCg0KBQQGAgAF
EgTPAQIICg0KBQQGAgABEgTPAQkNCg0KBQQGAgADEgTPARARCg8KBQQGAgAIEgbPARLUAQMK
EAoIBAYCAAicCAASBNABBCoKEQoHBAYCAAifCBIG0QEE0wEFCmkKBAQGAgESBNgBAkQaWyBS
ZXF1aXJlZC4gVGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVzZXIgdG8gd2hvbSB0aGUgdHVu
ZWQgbW9kZWwgaXMgYmVpbmcKIHRyYW5zZmVycmVkIHRvLgoKDQoFBAYCAQUSBNgBAggKDQoF
BAYCAQESBNgBCRYKDQoFBAYCAQMSBNgBGRoKDQoFBAYCAQgSBNgBG0MKEAoIBAYCAQicCAAS
BNgBHEIKMAoCBAcSBNwBACQaJCBSZXNwb25zZSBmcm9tIGBUcmFuc2Zlck93bmVyc2hpcGAu
CgoLCgMEBwESBNwBCCFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest ===
    # Fields for CreatePermissionRequest
    # Field: parent Type: 9 ()
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1alpha.Permission)

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::GetPermissionRequest ===
    # Fields for GetPermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsRequest ===
    # Fields for ListPermissionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsResponse ===
    # Fields for ListPermissionsResponse
    # Field: permissions Type: 11 (.google.ai.generativelanguage.v1alpha.Permission)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::UpdatePermissionRequest ===
    # Fields for UpdatePermissionRequest
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1alpha.Permission)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::DeletePermissionRequest ===
    # Fields for DeletePermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipRequest ===
    # Fields for TransferOwnershipRequest
    # Field: name Type: 9 ()
    # Field: email_address Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipResponse ===
    # Fields for TransferOwnershipResponse

# === Service Client: Google::Ai::Generativelanguage::V1alpha::PermissionService::PermissionServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::PermissionService::PermissionServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::PermissionService::PermissionServiceClient

Client stub representing the remote C<PermissionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub create_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'CreatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::Permission::Permission',
    });
}

sub get_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::GetPermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'GetPermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::Permission::Permission',
    });
}

sub list_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'ListPermissions',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsResponse',
    });
}

sub update_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::UpdatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'UpdatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::Permission::Permission',
    });
}

sub delete_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::DeletePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'DeletePermission',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub transfer_ownership {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'TransferOwnership',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::PermissionService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/permission_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::PermissionService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest->new({
        parent => $parent,
        permission => $permission,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/permission_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest

Request to create a `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the `Permission`.
Formats:
   `tunedModels/{tuned_model}`
   `corpora/{corpus}`

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Permission::Permission>)

Required. The permission to create.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::GetPermissionRequest

Request for getting information about a specific `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the permission.

Formats:
   `tunedModels/{tuned_model}/permissions/{permission}`
   `corpora/{corpus}/permissions/{permission}`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsRequest

Request for listing permissions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the permissions.
Formats:
   `tunedModels/{tuned_model}`
   `corpora/{corpus}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `Permission`s to return (per page).
The service may return fewer permissions.

If unspecified, at most 10 permissions will be returned.
This method returns at most 1000 permissions per page, even if you pass
larger page_size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListPermissions` call.

Provide the `page_token` returned by one request as an argument to the
next request to retrieve the next page.

When paginating, all other parameters provided to `ListPermissions`
must match the call that provided the page token.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::ListPermissionsResponse

Response from `ListPermissions` containing a paginated list of
permissions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permissions() >> / C<< $msg->permissions($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Permission::Permission>)

Returned permissions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::UpdatePermissionRequest

Request to update the `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Permission::Permission>)

Required. The permission to update.

The permission's `name` field is used to identify the permission to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The list of fields to update. Accepted ones:
 - role (`Permission.role` field)

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::DeletePermissionRequest

Request to delete the `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the permission.
Formats:
   `tunedModels/{tuned_model}/permissions/{permission}`
   `corpora/{corpus}/permissions/{permission}`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipRequest

Request to transfer the ownership of the tuned model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tuned model to transfer ownership.

Format: `tunedModels/my-model-id`

=item * C<< $msg->email_address() >> / C<< $msg->email_address($value) >>

Type: C<String>

Required. The email address of the user to whom the tuned model is being
transferred to.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipResponse

Response from `TransferOwnership`.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::PermissionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
