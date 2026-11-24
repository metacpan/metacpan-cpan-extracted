package Google::Ai::Generativelanguage::V1beta::PermissionService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::Permission };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9wZXJtaXNzaW9uX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGjRnb29nbGUv
YWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9wZXJtaXNzaW9uLnByb3RvGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxob
Z29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90byK9AQoXQ3JlYXRlUGVybWlzc2lvblJlcXVlc3QSTAoGcGFyZW50GAEgASgJQjTg
QQL6QS4SLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9uUgZw
YXJlbnQSVAoKcGVybWlzc2lvbhgCIAEoCzIvLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFiZXRhLlBlcm1pc3Npb25CA+BBAlIKcGVybWlzc2lvbiJgChRHZXRQZXJtaXNzaW9u
UmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29n
bGVhcGlzLmNvbS9QZXJtaXNzaW9uUgRuYW1lIoEBChZMaXN0UGVybWlzc2lvbnNSZXF1ZXN0
EiEKBnBhcmVudBgBIAEoCUIJ4EEC+kEDCgEqUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgF
QgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpQB
ChdMaXN0UGVybWlzc2lvbnNSZXNwb25zZRJRCgtwZXJtaXNzaW9ucxgBIAMoCzIvLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlBlcm1pc3Npb25SC3Blcm1pc3Npb25z
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKxAQoXVXBkYXRlUGVy
bWlzc2lvblJlcXVlc3QSVAoKcGVybWlzc2lvbhgBIAEoCzIvLmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFiZXRhLlBlcm1pc3Npb25CA+BBAlIKcGVybWlzc2lvbhJACgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRl
TWFzayJjChdEZWxldGVQZXJtaXNzaW9uUmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4K
LGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9uUgRuYW1lIo4B
ChhUcmFuc2Zlck93bmVyc2hpcFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuEixnZW5l
cmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vUGVybWlzc2lvblIEbmFtZRIoCg1lbWFp
bF9hZGRyZXNzGAIgASgJQgPgQQJSDGVtYWlsQWRkcmVzcyIbChlUcmFuc2Zlck93bmVyc2hp
cFJlc3BvbnNlMuwLChFQZXJtaXNzaW9uU2VydmljZRKMAgoQQ3JlYXRlUGVybWlzc2lvbhI8
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNyZWF0ZVBlcm1pc3Npb25S
ZXF1ZXN0Gi8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuUGVybWlzc2lv
biKIAYLT5JMCbiIqL3YxYmV0YS97cGFyZW50PXR1bmVkTW9kZWxzLyp9L3Blcm1pc3Npb25z
OgpwZXJtaXNzaW9uWjQiJi92MWJldGEve3BhcmVudD1jb3Jwb3JhLyp9L3Blcm1pc3Npb25z
OgpwZXJtaXNzaW9u2kERcGFyZW50LHBlcm1pc3Npb24S4AEKDUdldFBlcm1pc3Npb24SOS5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5HZXRQZXJtaXNzaW9uUmVxdWVz
dBovLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlBlcm1pc3Npb24iY4LT
5JMCVhIqL3YxYmV0YS97bmFtZT10dW5lZE1vZGVscy8qL3Blcm1pc3Npb25zLyp9WigSJi92
MWJldGEve25hbWU9Y29ycG9yYS8qL3Blcm1pc3Npb25zLyp92kEEbmFtZRLzAQoPTGlzdFBl
cm1pc3Npb25zEjsuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuTGlzdFBl
cm1pc3Npb25zUmVxdWVzdBo8Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRh
Lkxpc3RQZXJtaXNzaW9uc1Jlc3BvbnNlImWC0+STAlYSKi92MWJldGEve3BhcmVudD10dW5l
ZE1vZGVscy8qfS9wZXJtaXNzaW9uc1ooEiYvdjFiZXRhL3twYXJlbnQ9Y29ycG9yYS8qfS9w
ZXJtaXNzaW9uc9pBBnBhcmVudBKoAgoQVXBkYXRlUGVybWlzc2lvbhI8Lmdvb2dsZS5haS5n
ZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlVwZGF0ZVBlcm1pc3Npb25SZXF1ZXN0Gi8uZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuUGVybWlzc2lvbiKkAYLT5JMChAEy
NS92MWJldGEve3Blcm1pc3Npb24ubmFtZT10dW5lZE1vZGVscy8qL3Blcm1pc3Npb25zLyp9
OgpwZXJtaXNzaW9uWj8yMS92MWJldGEve3Blcm1pc3Npb24ubmFtZT1jb3Jwb3JhLyovcGVy
bWlzc2lvbnMvKn06CnBlcm1pc3Npb27aQRZwZXJtaXNzaW9uLHVwZGF0ZV9tYXNrEs0BChBE
ZWxldGVQZXJtaXNzaW9uEjwuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEu
RGVsZXRlUGVybWlzc2lvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiY4LT5JMC
VioqL3YxYmV0YS97bmFtZT10dW5lZE1vZGVscy8qL3Blcm1pc3Npb25zLyp9WigqJi92MWJl
dGEve25hbWU9Y29ycG9yYS8qL3Blcm1pc3Npb25zLyp92kEEbmFtZRLNAQoRVHJhbnNmZXJP
d25lcnNoaXASPS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5UcmFuc2Zl
ck93bmVyc2hpcFJlcXVlc3QaPi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0
YS5UcmFuc2Zlck93bmVyc2hpcFJlc3BvbnNlIjmC0+STAjMiLi92MWJldGEve25hbWU9dHVu
ZWRNb2RlbHMvKn06dHJhbnNmZXJPd25lcnNoaXA6ASoaJMpBIWdlbmVyYXRpdmVsYW5ndWFn
ZS5nb29nbGVhcGlzLmNvbUKiAQonY29tLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFiZXRhQhZQZXJtaXNzaW9uU2VydmljZVByb3RvUAFaXWNsb3VkLmdvb2dsZS5jb20vZ28v
YWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYmV0YS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtn
ZW5lcmF0aXZlbGFuZ3VhZ2VwYkqUKwoHEgUOANwBJAq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgA+CgkKAgMBEgMTACYKCQoCAwISAxQA
IQoJCgIDAxIDFQApCgkKAgMEEgMWACMKCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoA
dAoJCgIICxIDGgB0CggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANwoJCgIICBIDHAA3
CggKAQgSAx0AQAoJCgIIARIDHQBACk4KAgYAEgQgAGQBGkIgUHJvdmlkZXMgbWV0aG9kcyBm
b3IgbWFuYWdpbmcgcGVybWlzc2lvbnMgdG8gUGFMTSBBUEkgcmVzb3VyY2VzLgoKCgoDBgAB
EgMgCBkKCgoDBgADEgMhAkkKDAoFBgADmQgSAyECSQo7CgQGAAIAEgQkAi4DGi0gQ3JlYXRl
IGEgcGVybWlzc2lvbiB0byBhIHNwZWNpZmljIHJlc291cmNlLgoKDAoFBgACAAESAyQGFgoM
CgUGAAIAAhIDJBcuCgwKBQYAAgADEgMkOUMKDQoFBgACAAQSBCUELAYKEQoJBgACAASwyrwi
EgQlBCwGCgwKBQYAAgAEEgMtBD8KDwoIBgACAASbCAASAy0EPwo9CgQGAAIBEgQxAjcDGi8g
R2V0cyBpbmZvcm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIFBlcm1pc3Npb24uCgoMCgUGAAIB
ARIDMQYTCgwKBQYAAgECEgMxFCgKDAoFBgACAQMSAzEzPQoNCgUGAAIBBBIEMgQ1BgoRCgkG
AAIBBLDKvCISBDIENQYKDAoFBgACAQQSAzYEMgoPCggGAAIBBJsIABIDNgQyCjwKBAYAAgIS
BDoCQQMaLiBMaXN0cyBwZXJtaXNzaW9ucyBmb3IgdGhlIHNwZWNpZmljIHJlc291cmNlLgoK
DAoFBgACAgESAzoGFQoMCgUGAAICAhIDOhYsCgwKBQYAAgIDEgM7DyYKDQoFBgACAgQSBDwE
PwYKEQoJBgACAgSwyrwiEgQ8BD8GCgwKBQYAAgIEEgNABDQKDwoIBgACAgSbCAASA0AENAon
CgQGAAIDEgREAk4DGhkgVXBkYXRlcyB0aGUgcGVybWlzc2lvbi4KCgwKBQYAAgMBEgNEBhYK
DAoFBgACAwISA0QXLgoMCgUGAAIDAxIDRDlDCg0KBQYAAgMEEgRFBEwGChEKCQYAAgMEsMq8
IhIERQRMBgoMCgUGAAIDBBIDTQRECg8KCAYAAgMEmwgAEgNNBEQKJwoEBgACBBIEUQJYAxoZ
IERlbGV0ZXMgdGhlIHBlcm1pc3Npb24uCgoMCgUGAAIEARIDUQYWCgwKBQYAAgQCEgNRFy4K
DAoFBgACBAMSA1IPJAoNCgUGAAIEBBIEUwRWBgoRCgkGAAIEBLDKvCISBFMEVgYKDAoFBgAC
BAQSA1cEMgoPCggGAAIEBJsIABIDVwQyCqwBCgQGAAIFEgRdAmMDGp0BIFRyYW5zZmVycyBv
d25lcnNoaXAgb2YgdGhlIHR1bmVkIG1vZGVsLgogVGhpcyBpcyB0aGUgb25seSB3YXkgdG8g
Y2hhbmdlIG93bmVyc2hpcCBvZiB0aGUgdHVuZWQgbW9kZWwuCiBUaGUgY3VycmVudCBvd25l
ciB3aWxsIGJlIGRvd25ncmFkZWQgdG8gd3JpdGVyIHJvbGUuCgoMCgUGAAIFARIDXQYXCgwK
BQYAAgUCEgNdGDAKDAoFBgACBQMSA14PKAoNCgUGAAIFBBIEXwRiBgoRCgkGAAIFBLDKvCIS
BF8EYgYKLwoCBAASBGcAdQEaIyBSZXF1ZXN0IHRvIGNyZWF0ZSBhIGBQZXJtaXNzaW9uYC4K
CgoKAwQAARIDZwgfCoMBCgQEAAIAEgRsAnEEGnUgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVz
b3VyY2Ugb2YgdGhlIGBQZXJtaXNzaW9uYC4KIEZvcm1hdHM6CiAgICBgdHVuZWRNb2RlbHMv
e3R1bmVkX21vZGVsfWAKICAgIGBjb3Jwb3JhL3tjb3JwdXN9YAoKDAoFBAACAAUSA2wCCAoM
CgUEAAIAARIDbAkPCgwKBQQAAgADEgNsEhMKDQoFBAACAAgSBGwUcQMKDwoIBAACAAicCAAS
A20EKgoPCgcEAAIACJ8IEgRuBHAFCjIKBAQAAgESA3QCRRolIFJlcXVpcmVkLiBUaGUgcGVy
bWlzc2lvbiB0byBjcmVhdGUuCgoMCgUEAAIBBhIDdAIMCgwKBQQAAgEBEgN0DRcKDAoFBAAC
AQMSA3QaGwoMCgUEAAIBCBIDdBxECg8KCAQAAgEInAgAEgN0HUMKTQoCBAESBXgAhAEBGkAg
UmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIGBQZXJt
aXNzaW9uYC4KCgoKAwQBARIDeAgcCrQBCgQEAQIAEgV+AoMBBBqkASBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIHBlcm1pc3Npb24uCgogRm9ybWF0czoKICAgIGB0dW5l
ZE1vZGVscy97dHVuZWRfbW9kZWx9L3Blcm1pc3Npb25zL3twZXJtaXNzaW9ufWAKICAgIGBj
b3Jwb3JhL3tjb3JwdXN9L3Blcm1pc3Npb25zL3twZXJtaXNzaW9ufWAKCgwKBQQBAgAFEgN+
AggKDAoFBAECAAESA34JDQoMCgUEAQIAAxIDfhARCg4KBQQBAgAIEgV+EoMBAwoPCggEAQIA
CJwIABIDfwQqChEKBwQBAgAInwgSBoABBIIBBQowCgIEAhIGhwEAoQEBGiIgUmVxdWVzdCBm
b3IgbGlzdGluZyBwZXJtaXNzaW9ucy4KCgsKAwQCARIEhwEIHgqEAQoEBAICABIGjAECjwEE
GnQgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIHBlcm1pc3Npb25zLgog
Rm9ybWF0czoKICAgIGB0dW5lZE1vZGVscy97dHVuZWRfbW9kZWx9YAogICAgYGNvcnBvcmEv
e2NvcnB1c31gCgoNCgUEAgIABRIEjAECCAoNCgUEAgIAARIEjAEJDwoNCgUEAgIAAxIEjAES
EwoPCgUEAgIACBIGjAEUjwEDChAKCAQCAgAInAgAEgSNAQQqCg8KBwQCAgAInwgSBI4BBDMK
lgIKBAQCAgESBJcBAj8ahwIgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBgUGVy
bWlzc2lvbmBzIHRvIHJldHVybiAocGVyIHBhZ2UpLgogVGhlIHNlcnZpY2UgbWF5IHJldHVy
biBmZXdlciBwZXJtaXNzaW9ucy4KCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMCBwZXJt
aXNzaW9ucyB3aWxsIGJlIHJldHVybmVkLgogVGhpcyBtZXRob2QgcmV0dXJucyBhdCBtb3N0
IDEwMDAgcGVybWlzc2lvbnMgcGVyIHBhZ2UsIGV2ZW4gaWYgeW91IHBhc3MKIGxhcmdlciBw
YWdlX3NpemUuCgoNCgUEAgIBBRIElwECBwoNCgUEAgIBARIElwEIEQoNCgUEAgIBAxIElwEU
FQoNCgUEAgIBCBIElwEWPgoQCggEAgIBCJwIABIElwEXPQrEAgoEBAICAhIEoAECQRq1AiBP
cHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RQ
ZXJtaXNzaW9uc2AgY2FsbC4KCiBQcm92aWRlIHRoZSBgcGFnZV90b2tlbmAgcmV0dXJuZWQg
Ynkgb25lIHJlcXVlc3QgYXMgYW4gYXJndW1lbnQgdG8gdGhlCiBuZXh0IHJlcXVlc3QgdG8g
cmV0cmlldmUgdGhlIG5leHQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBw
YXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0UGVybWlzc2lvbnNgCiBtdXN0IG1hdGNoIHRo
ZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEAgICBRIEoAECCAoN
CgUEAgICARIEoAEJEwoNCgUEAgICAxIEoAEWFwoNCgUEAgICCBIEoAEYQAoQCggEAgICCJwI
ABIEoAEZPwpcCgIEAxIGpQEArQEBGk4gUmVzcG9uc2UgZnJvbSBgTGlzdFBlcm1pc3Npb25z
YCBjb250YWluaW5nIGEgcGFnaW5hdGVkIGxpc3Qgb2YKIHBlcm1pc3Npb25zLgoKCwoDBAMB
EgSlAQgfCiUKBAQDAgASBKcBAiYaFyBSZXR1cm5lZCBwZXJtaXNzaW9ucy4KCg0KBQQDAgAE
EgSnAQIKCg0KBQQDAgAGEgSnAQsVCg0KBQQDAgABEgSnARYhCg0KBQQDAgADEgSnASQlCooB
CgQEAwIBEgSsAQIdGnwgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9r
ZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0
dGVkLCB0aGVyZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0KBQQDAgEFEgSsAQIICg0KBQQDAgEB
EgSsAQkYCg0KBQQDAgEDEgSsARscCjMKAgQEEgawAQC6AQEaJSBSZXF1ZXN0IHRvIHVwZGF0
ZSB0aGUgYFBlcm1pc3Npb25gLgoKCwoDBAQBEgSwAQgfCoEBCgQEBAIAEgS0AQJFGnMgUmVx
dWlyZWQuIFRoZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZS4KCiBUaGUgcGVybWlzc2lvbidzIGBu
YW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZSBwZXJtaXNzaW9uIHRvIHVwZGF0
ZS4KCg0KBQQEAgAGEgS0AQIMCg0KBQQEAgABEgS0AQ0XCg0KBQQEAgADEgS0ARobCg0KBQQE
AgAIEgS0ARxEChAKCAQEAgAInAgAEgS0AR1DCmsKBAQEAgESBrgBArkBLxpbIFJlcXVpcmVk
LiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLiBBY2NlcHRlZCBvbmVzOgogIC0gcm9s
ZSAoYFBlcm1pc3Npb24ucm9sZWAgZmllbGQpCgoNCgUEBAIBBhIEuAECGwoNCgUEBAIBARIE
uAEcJwoNCgUEBAIBAxIEuAEqKwoNCgUEBAIBCBIEuQEGLgoQCggEBAIBCJwIABIEuQEHLQoz
CgIEBRIGvQEAyAEBGiUgUmVxdWVzdCB0byBkZWxldGUgdGhlIGBQZXJtaXNzaW9uYC4KCgsK
AwQFARIEvQEIHwq0AQoEBAUCABIGwgECxwEEGqMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgcGVybWlzc2lvbi4KIEZvcm1hdHM6CiAgICBgdHVuZWRNb2RlbHMve3R1
bmVkX21vZGVsfS9wZXJtaXNzaW9ucy97cGVybWlzc2lvbn1gCiAgICBgY29ycG9yYS97Y29y
cHVzfS9wZXJtaXNzaW9ucy97cGVybWlzc2lvbn1gCgoNCgUEBQIABRIEwgECCAoNCgUEBQIA
ARIEwgEJDQoNCgUEBQIAAxIEwgEQEQoPCgUEBQIACBIGwgESxwEDChAKCAQFAgAInAgAEgTD
AQQqChEKBwQFAgAInwgSBsQBBMYBBQpFCgIEBhIGywEA2QEBGjcgUmVxdWVzdCB0byB0cmFu
c2ZlciB0aGUgb3duZXJzaGlwIG9mIHRoZSB0dW5lZCBtb2RlbC4KCgsKAwQGARIEywEIIAp7
CgQEBgIAEgbPAQLUAQQaayBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHR1
bmVkIG1vZGVsIHRvIHRyYW5zZmVyIG93bmVyc2hpcC4KCiBGb3JtYXQ6IGB0dW5lZE1vZGVs
cy9teS1tb2RlbC1pZGAKCg0KBQQGAgAFEgTPAQIICg0KBQQGAgABEgTPAQkNCg0KBQQGAgAD
EgTPARARCg8KBQQGAgAIEgbPARLUAQMKEAoIBAYCAAicCAASBNABBCoKEQoHBAYCAAifCBIG
0QEE0wEFCmkKBAQGAgESBNgBAkQaWyBSZXF1aXJlZC4gVGhlIGVtYWlsIGFkZHJlc3Mgb2Yg
dGhlIHVzZXIgdG8gd2hvbSB0aGUgdHVuZWQgbW9kZWwgaXMgYmVpbmcKIHRyYW5zZmVycmVk
IHRvLgoKDQoFBAYCAQUSBNgBAggKDQoFBAYCAQESBNgBCRYKDQoFBAYCAQMSBNgBGRoKDQoF
BAYCAQgSBNgBG0MKEAoIBAYCAQicCAASBNgBHEIKMAoCBAcSBNwBACQaJCBSZXNwb25zZSBm
cm9tIGBUcmFuc2Zlck93bmVyc2hpcGAuCgoLCgMEBwESBNwBCCFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest ===
    # Fields for CreatePermissionRequest
    # Field: parent Type: 9 ()
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1beta.Permission)

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest ===
    # Fields for GetPermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest ===
    # Fields for ListPermissionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse ===
    # Fields for ListPermissionsResponse
    # Field: permissions Type: 11 (.google.ai.generativelanguage.v1beta.Permission)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest ===
    # Fields for UpdatePermissionRequest
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1beta.Permission)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest ===
    # Fields for DeletePermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest ===
    # Fields for TransferOwnershipRequest
    # Field: name Type: 9 ()
    # Field: email_address Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse ===
    # Fields for TransferOwnershipResponse

# === Service Client: Google::Ai::Generativelanguage::V1beta::PermissionService::PermissionServiceClient ===
package Google::Ai::Generativelanguage::V1beta::PermissionService::PermissionServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta::PermissionService::PermissionServiceClient

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
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'CreatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::Permission::Permission',
    });
}

sub get_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'GetPermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::Permission::Permission',
    });
}

sub list_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'ListPermissions',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse',
    });
}

sub update_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'UpdatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::Permission::Permission',
    });
}

sub delete_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'DeletePermission',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub transfer_ownership {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'TransferOwnership',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PermissionService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/permission_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PermissionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest->new({
        parent => $parent,
        permission => $permission,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/permission_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Permission::Permission>)

Required. The permission to create.

=back

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::GetPermissionRequest

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

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsRequest

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

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::ListPermissionsResponse

Response from `ListPermissions` containing a paginated list of
permissions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permissions() >> / C<< $msg->permissions($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Permission::Permission>)

Returned permissions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::UpdatePermissionRequest

Request to update the `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Permission::Permission>)

Required. The permission to update.

The permission's `name` field is used to identify the permission to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The list of fields to update. Accepted ones:
 - role (`Permission.role` field)

=back

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::DeletePermissionRequest

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

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest

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

=head2 Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse

Response from `TransferOwnership`.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::PermissionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
