package Google::Cloud::Networkservices::V1::Gateway;

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
    eval { require Google::Cloud::Networkservices::V1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL2dhdGV3YXkucHJvdG8SH2dvb2ds
ZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9uZXR3b3Jr
c2VydmljZXMvdjEvY29tbW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK3DQoHR2F0ZXdheRIXCgRu
YW1lGAEgASgJQgPgQQhSBG5hbWUSIAoJc2VsZl9saW5rGA0gASgJQgPgQQNSCHNlbGZMaW5r
EkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lElEKBmxhYmVscxgEIAMoCzI0Lmdvb2dsZS5jbG91
ZC5uZXR3b3Jrc2VydmljZXMudjEuR2F0ZXdheS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMS
JQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAVILZGVzY3JpcHRpb24SRgoEdHlwZRgGIAEoDjIt
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuR2F0ZXdheS5UeXBlQgPgQQVSBHR5
cGUSRAoJYWRkcmVzc2VzGAcgAygJQibgQQH6QSAKHmNvbXB1dGUuZ29vZ2xlYXBpcy5jb20v
QWRkcmVzc1IJYWRkcmVzc2VzEhkKBXBvcnRzGAsgAygFQgPgQQJSBXBvcnRzEiAKCWFsbF9w
b3J0cxgiIAEoCEID4EEBUghhbGxQb3J0cxIZCgVzY29wZRgIIAEoCUID4EEBUgVzY29wZRJi
ChFzZXJ2ZXJfdGxzX3BvbGljeRgJIAEoCUI24EEB+kEwCi5uZXR3b3Jrc2VjdXJpdHkuZ29v
Z2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5Ug9zZXJ2ZXJUbHNQb2xpY3kSYAoQY2VydGlm
aWNhdGVfdXJscxgOIAMoCUI14EEB+kEvCi1jZXJ0aWZpY2F0ZW1hbmFnZXIuZ29vZ2xlYXBp
cy5jb20vQ2VydGlmaWNhdGVSD2NlcnRpZmljYXRlVXJscxJ0ChdnYXRld2F5X3NlY3VyaXR5
X3BvbGljeRgSIAEoCUI84EEB+kE2CjRuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20v
R2F0ZXdheVNlY3VyaXR5UG9saWN5UhVnYXRld2F5U2VjdXJpdHlQb2xpY3kSQAoHbmV0d29y
axgQIAEoCUIm4EEB+kEgCh5jb21wdXRlLmdvb2dsZWFwaXMuY29tL05ldHdvcmtSB25ldHdv
cmsSSQoKc3VibmV0d29yaxgRIAEoCUIp4EEB+kEjCiFjb21wdXRlLmdvb2dsZWFwaXMuY29t
L1N1Ym5ldHdvcmtSCnN1Ym5ldHdvcmsSVgoKaXBfdmVyc2lvbhgVIAEoDjIyLmdvb2dsZS5j
bG91ZC5uZXR3b3Jrc2VydmljZXMudjEuR2F0ZXdheS5JcFZlcnNpb25CA+BBAVIJaXBWZXJz
aW9uElwKDWVudm95X2hlYWRlcnMYHCABKA4yLS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxLkVudm95SGVhZGVyc0ID4EEBSABSDGVudm95SGVhZGVyc4gBARJcCgxyb3V0aW5n
X21vZGUYICABKA4yNC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLkdhdGV3YXku
Um91dGluZ01vZGVCA+BBAVILcm91dGluZ01vZGUSMwoTYWxsb3dfZ2xvYmFsX2FjY2Vzcxgh
IAEoCEID4EEBUhFhbGxvd0dsb2JhbEFjY2Vzcxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIkMKBFR5cGUSFAoQVFlQRV9VTlNQ
RUNJRklFRBAAEg0KCU9QRU5fTUVTSBABEhYKElNFQ1VSRV9XRUJfR0FURVdBWRACIjsKCUlw
VmVyc2lvbhIaChZJUF9WRVJTSU9OX1VOU1BFQ0lGSUVEEAASCAoESVBWNBABEggKBElQVjYQ
AiJDCgtSb3V0aW5nTW9kZRIZChVFWFBMSUNJVF9ST1VUSU5HX01PREUQABIZChVORVhUX0hP
UF9ST1VUSU5HX01PREUQATpn6kFkCiZuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20v
R2F0ZXdheRI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2dhdGV3
YXlzL3tnYXRld2F5fUIQCg5fZW52b3lfaGVhZGVycyKZAQoTTGlzdEdhdGV3YXlzUmVxdWVz
dBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKBImbmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMu
Y29tL0dhdGV3YXlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBh
Z2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKmAQoUTGlzdEdhdGV3YXlzUmVzcG9uc2USRAoI
Z2F0ZXdheXMYASADKAsyKC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLkdhdGV3
YXlSCGdhdGV3YXlzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIg
Cgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiVwoRR2V0R2F0ZXdheVJlcXVlc3QS
QgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20v
R2F0ZXdheVIEbmFtZSLLAQoUQ3JlYXRlR2F0ZXdheVJlcXVlc3QSRgoGcGFyZW50GAEgASgJ
Qi7gQQL6QSgSJm5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9HYXRld2F5UgZwYXJl
bnQSIgoKZ2F0ZXdheV9pZBgCIAEoCUID4EECUglnYXRld2F5SWQSRwoHZ2F0ZXdheRgDIAEo
CzIoLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuR2F0ZXdheUID4EECUgdnYXRl
d2F5IqEBChRVcGRhdGVHYXRld2F5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJHCgdnYXRld2F5GAIg
ASgLMiguZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5HYXRld2F5QgPgQQJSB2dh
dGV3YXkiWgoURGVsZXRlR2F0ZXdheVJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZu
ZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vR2F0ZXdheVIEbmFtZUKJBgojY29tLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFCDEdhdGV3YXlQcm90b1ABWk1jbG91ZC5n
b29nbGUuY29tL2dvL25ldHdvcmtzZXJ2aWNlcy9hcGl2MS9uZXR3b3Jrc2VydmljZXNwYjtu
ZXR3b3Jrc2VydmljZXNwYqoCH0dvb2dsZS5DbG91ZC5OZXR3b3JrU2VydmljZXMuVjHKAh9H
b29nbGVcQ2xvdWRcTmV0d29ya1NlcnZpY2VzXFYx6gIiR29vZ2xlOjpDbG91ZDo6TmV0d29y
a1NlcnZpY2VzOjpWMepBkQEKNG5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9HYXRl
d2F5U2VjdXJpdHlQb2xpY3kSWXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9nYXRld2F5U2VjdXJpdHlQb2xpY2llcy97Z2F0ZXdheV9zZWN1cml0eV9wb2xpY3l9
6kFhCiFjb21wdXRlLmdvb2dsZWFwaXMuY29tL1N1Ym5ldHdvcmsSPHByb2plY3RzL3twcm9q
ZWN0fS9yZWdpb25zL3tyZWdpb259L3N1Ym5ldHdvcmtzL3tzdWJuZXR3b3JrfepBTgoeY29t
cHV0ZS5nb29nbGVhcGlzLmNvbS9OZXR3b3JrEixwcm9qZWN0cy97cHJvamVjdH0vZ2xvYmFs
L25ldHdvcmtzL3tuZXR3b3JrfepBWQoeY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9BZGRyZXNz
Ejdwcm9qZWN0cy97cHJvamVjdH0vcmVnaW9ucy97cmVnaW9ufS9hZGRyZXNzZXMve2FkZHJl
c3N96kFzCi1jZXJ0aWZpY2F0ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vQ2VydGlmaWNhdGUS
QnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jZXJ0aWZpY2F0ZXMv
e2NlcnRpZmljYXRlfUq2WQoHEgUOAM4CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
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
ZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANgoJCgID
AxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA8CgkKAgglEgMYADwKCAoBCBIDGQBkCgkKAggL
EgMZAGQKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAtCgkKAggIEgMbAC0KCAoBCBID
HAA8CgkKAggBEgMcADwKCAoBCBIDHQA8CgkKAggpEgMdADwKCAoBCBIDHgA7CgkKAggtEgMe
ADsKCQoBCBIEHwAiAgoMCgQInQgAEgQfACICCgkKAQgSBCMAJgIKDAoECJ0IARIEIwAmAgoJ
CgEIEgQnACoCCgwKBAidCAISBCcAKgIKCQoBCBIEKwAuAgoMCgQInQgDEgQrAC4CCgkKAQgS
BC8AMgIKDAoECJ0IBBIELwAyAgquAgoCBAASBTgA9AEBGqACIEdhdGV3YXkgcmVwcmVzZW50
cyB0aGUgY29uZmlndXJhdGlvbiBmb3IgYSBwcm94eSwgdHlwaWNhbGx5IGEgbG9hZCBiYWxh
bmNlci4KIEl0IGNhcHR1cmVzIHRoZSBpcDpwb3J0IG92ZXIgd2hpY2ggdGhlIHNlcnZpY2Vz
IGFyZSBleHBvc2VkIGJ5IHRoZSBwcm94eSwKIGFsb25nIHdpdGggYW55IHBvbGljeSBjb25m
aWd1cmF0aW9ucy4gUm91dGVzIGhhdmUgcmVmZXJlbmNlIHRvIHRvIEdhdGV3YXlzIHRvCiBk
aWN0YXRlIGhvdyByZXF1ZXN0cyBzaG91bGQgYmUgcm91dGVkIGJ5IHRoaXMgR2F0ZXdheS4K
CgoKAwQAARIDOAgPCgsKAwQABxIEOQI8BAoNCgUEAAedCBIEOQI8BApyCgQEAAQAEgRCAkwD
GmQgVGhlIHR5cGUgb2YgdGhlIGN1c3RvbWVyLW1hbmFnZWQgZ2F0ZXdheS4KIFBvc3NpYmxl
IHZhbHVlcyBhcmU6CiAqIE9QRU5fTUVTSAogKiBTRUNVUkVfV0VCX0dBVEVXQVkKCgwKBQQA
BAABEgNCBwsKSQoGBAAEAAIAEgNEBBkaOiBUaGUgdHlwZSBvZiB0aGUgY3VzdG9tZXIgbWFu
YWdlZCBnYXRld2F5IGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDRAQUCg4KBwQABAAC
AAISA0QXGApYCgYEAAQAAgESA0gEEhpJIFRoZSB0eXBlIG9mIHRoZSBjdXN0b21lciBtYW5h
Z2VkIGdhdGV3YXkgaXMgVHJhZmZpY0RpcmVjdG9yIE9wZW4KIE1lc2guCgoOCgcEAAQAAgEB
EgNIBA0KDgoHBAAEAAIBAhIDSBARClQKBgQABAACAhIDSwQbGkUgVGhlIHR5cGUgb2YgdGhl
IGN1c3RvbWVyIG1hbmFnZWQgZ2F0ZXdheSBpcyBTZWN1cmVXZWJHYXRld2F5IChTV0cpLgoK
DgoHBAAEAAICARIDSwQWCg4KBwQABAACAgISA0sZGgpeCgQEAAQBEgRSAlsDGlAgVGhlIHR5
cGVzIG9mIElQIHZlcnNpb24gZm9yIHRoZSBnYXRld2F5LgogUG9zc2libGUgdmFsdWVzIGFy
ZToKICogSVBWNAogKiBJUFY2CgoMCgUEAAQBARIDUgcQCk0KBgQABAECABIDVAQfGj4gVGhl
IHR5cGUgd2hlbiBJUCB2ZXJzaW9uIGlzIG5vdCBzcGVjaWZpZWQuIERlZmF1bHRzIHRvIElQ
VjQuCgoOCgcEAAQBAgABEgNUBBoKDgoHBAAEAQIAAhIDVB0eCisKBgQABAECARIDVwQNGhwg
VGhlIHR5cGUgZm9yIElQIHZlcnNpb24gNC4KCg4KBwQABAECAQESA1cECAoOCgcEAAQBAgEC
EgNXCwwKKwoGBAAEAQICEgNaBA0aHCBUaGUgdHlwZSBmb3IgSVAgdmVyc2lvbiA2LgoKDgoH
BAAEAQICARIDWgQICg4KBwQABAECAgISA1oLDAruAQoEBAAEAhIEYgJsAxrfASBUaGUgcm91
dGluZyBtb2RlIG9mIHRoZSBHYXRld2F5LCB0byBkZXRlcm1pbmUgaG93IHRoZSBHYXRld2F5
IHJvdXRlcwogdHJhZmZpYy4gVG9kYXksIHRoaXMgZmllbGQgb25seSBhcHBsaWVzIHRvIEdh
dGV3YXlzIG9mIHR5cGUKIFNFQ1VSRV9XRUJfR0FURVdBWS4gUG9zc2libGUgdmFsdWVzIGFy
ZToKICogRVhQTElDSVRfUk9VVElOR19NT0RFCiAqIE5FWFRfSE9QX1JPVVRJTkdfTU9ERQoK
DAoFBAAEAgESA2IHEgqNAQoGBAAEAgIAEgNlBB4afiBUaGUgcm91dGluZyBtb2RlIGlzIGV4
cGxpY2l0OyBjbGllbnRzIGFyZSBjb25maWd1cmVkIHRvIHNlbmQKIHRyYWZmaWMgdGhyb3Vn
aCB0aGUgZ2F0ZXdheS4gVGhpcyBpcyB0aGUgZGVmYXVsdCByb3V0aW5nIG1vZGUuCgoOCgcE
AAQCAgABEgNlBBkKDgoHBAAEAgIAAhIDZRwdCvsBCgYEAAQCAgESA2sEHhrrASBUaGUgcm91
dGluZyBtb2RlIGlzIG5leHQtaG9wLiBDbGllbnRzIGFyZSB1bmF3YXJlIG9mIHRoZSBnYXRl
d2F5LAogYW5kIGEgcm91dGUgKGFkdmFuY2VkIHJvdXRlIG9yIG90aGVyIHJvdXRlIHR5cGUp
CiBjYW4gYmUgY29uZmlndXJlZCB0byBkaXJlY3QgdHJhZmZpYyBmcm9tIGNsaWVudCB0byBn
YXRld2F5LgogVGhlIGdhdGV3YXkgdGhlbiBhY3RzIGFzIGEgbmV4dC1ob3AgdG8gdGhlIGRl
c3RpbmF0aW9uLgoKDgoHBAAEAgIBARIDawQZCg4KBwQABAICAQISA2scHQp+CgQEAAIAEgNw
Aj0acSBJZGVudGlmaWVyLiBOYW1lIG9mIHRoZSBHYXRld2F5IHJlc291cmNlLiBJdCBtYXRj
aGVzIHBhdHRlcm4KIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2dhdGV3YXlzLzxnYXRld2F5
X25hbWU+YC4KCgwKBQQAAgAFEgNwAggKDAoFBAACAAESA3AJDQoMCgUEAAIAAxIDcBARCgwK
BQQAAgAIEgNwEjwKDwoIBAACAAicCAASA3ATOwo/CgQEAAIBEgNzAkQaMiBPdXRwdXQgb25s
eS4gU2VydmVyLWRlZmluZWQgVVJMIG9mIHRoaXMgcmVzb3VyY2UKCgwKBQQAAgEFEgNzAggK
DAoFBAACAQESA3MJEgoMCgUEAAIBAxIDcxUXCgwKBQQAAgEIEgNzGEMKDwoIBAACAQicCAAS
A3MZQgpJCgQEAAICEgR2AncyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0
aGUgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoMCgUEAAICBhIDdgIbCgwKBQQAAgIBEgN2HCcK
DAoFBAACAgMSA3YqKwoMCgUEAAICCBIDdwYxCg8KCAQAAgIInAgAEgN3BzAKSQoEBAACAxIE
egJ7Mho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdh
cyB1cGRhdGVkLgoKDAoFBAACAwYSA3oCGwoMCgUEAAIDARIDehwnCgwKBQQAAgMDEgN6KisK
DAoFBAACAwgSA3sGMQoPCggEAAIDCJwIABIDewcwClAKBAQAAgQSA34CShpDIE9wdGlvbmFs
LiBTZXQgb2YgbGFiZWwgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIEdhdGV3YXkgcmVzb3Vy
Y2UuCgoMCgUEAAIEBhIDfgIVCgwKBQQAAgQBEgN+FhwKDAoFBAACBAMSA34fIAoMCgUEAAIE
CBIDfiFJCg8KCAQAAgQInAgAEgN+IkgKXwoEBAACBRIEggECQhpRIE9wdGlvbmFsLiBBIGZy
ZWUtdGV4dCBkZXNjcmlwdGlvbiBvZiB0aGUgcmVzb3VyY2UuIE1heCBsZW5ndGggMTAyNAog
Y2hhcmFjdGVycy4KCg0KBQQAAgUFEgSCAQIICg0KBQQAAgUBEgSCAQkUCg0KBQQAAgUDEgSC
ARcYCg0KBQQAAgUIEgSCARlBChAKCAQAAgUInAgAEgSCARpACoMBCgQEAAIGEgSGAQI6GnUg
SW1tdXRhYmxlLiBUaGUgdHlwZSBvZiB0aGUgY3VzdG9tZXIgbWFuYWdlZCBnYXRld2F5Lgog
VGhpcyBmaWVsZCBpcyByZXF1aXJlZC4gSWYgdW5zcGVjaWZpZWQsIGFuIGVycm9yIGlzIHJl
dHVybmVkLgoKDQoFBAACBgYSBIYBAgYKDQoFBAACBgESBIYBBwsKDQoFBAACBgMSBIYBDg8K
DQoFBAACBggSBIYBEDkKEAoIBAACBgicCAASBIYBETgKwAIKBAQAAgcSBo4BApEBBBqvAiBP
cHRpb25hbC4gWmVybyBvciBvbmUgSVB2NCBvciBJUHY2IGFkZHJlc3Mgb24gd2hpY2ggdGhl
IEdhdGV3YXkgd2lsbAogcmVjZWl2ZSB0aGUgdHJhZmZpYy4gV2hlbiBubyBhZGRyZXNzIGlz
IHByb3ZpZGVkLCBhbiBJUCBmcm9tIHRoZSBzdWJuZXR3b3JrCiBpcyBhbGxvY2F0ZWQKCiBU
aGlzIGZpZWxkIG9ubHkgYXBwbGllcyB0byBnYXRld2F5cyBvZiB0eXBlICdTRUNVUkVfV0VC
X0dBVEVXQVknLgogR2F0ZXdheXMgb2YgdHlwZSAnT1BFTl9NRVNIJyBsaXN0ZW4gb24gMC4w
LjAuMCBmb3IgSVB2NCBhbmQgOjogZm9yIElQdjYuCgoNCgUEAAIHBBIEjgECCgoNCgUEAAIH
BRIEjgELEQoNCgUEAAIHARIEjgESGwoNCgUEAAIHAxIEjgEeHwoPCgUEAAIHCBIGjgEgkQED
ChAKCAQAAgcInAgAEgSPAQQqCg8KBwQAAgcInwgSBJABBFAKtwIKBAQAAggSBJgBAkUaqAIg
UmVxdWlyZWQuIE9uZSBvciBtb3JlIHBvcnQgbnVtYmVycyAoMS02NTUzNSksIG9uIHdoaWNo
IHRoZSBHYXRld2F5IHdpbGwKIHJlY2VpdmUgdHJhZmZpYy4gVGhlIHByb3h5IGJpbmRzIHRv
IHRoZSBzcGVjaWZpZWQgcG9ydHMuCiBHYXRld2F5cyBvZiB0eXBlICdTRUNVUkVfV0VCX0dB
VEVXQVknIGFyZSBsaW1pdGVkIHRvIDUgcG9ydHMuCiBHYXRld2F5cyBvZiB0eXBlICdPUEVO
X01FU0gnIGxpc3RlbiBvbiAwLjAuMC4wIGZvciBJUHY0IGFuZCA6OiBmb3IgSVB2NiBhbmQK
IHN1cHBvcnQgbXVsdGlwbGUgcG9ydHMuCgoNCgUEAAIIBBIEmAECCgoNCgUEAAIIBRIEmAEL
EAoNCgUEAAIIARIEmAERFgoNCgUEAAIIAxIEmAEZGwoNCgUEAAIICBIEmAEcRAoQCggEAAII
CJwIABIEmAEdQwrAAQoEBAACCRIEnQECPxqxASBPcHRpb25hbC4gSWYgdHJ1ZSwgdGhlIEdh
dGV3YXkgd2lsbCBsaXN0ZW4gb24gYWxsIHBvcnRzLiBUaGlzIGlzIG11dHVhbGx5CiBleGNs
dXNpdmUgd2l0aCB0aGUgYHBvcnRzYCBmaWVsZC4gVGhpcyBmaWVsZCBvbmx5IGFwcGxpZXMg
dG8gZ2F0ZXdheXMgb2YKIHR5cGUgJ1NFQ1VSRV9XRUJfR0FURVdBWScuCgoNCgUEAAIJBRIE
nQECBgoNCgUEAAIJARIEnQEHEAoNCgUEAAIJAxIEnQETFQoNCgUEAAIJCBIEnQEWPgoQCggE
AAIJCJwIABIEnQEXPQrxAgoEBAACChIEpwECPBriAiBPcHRpb25hbC4gU2NvcGUgZGV0ZXJt
aW5lcyBob3cgY29uZmlndXJhdGlvbiBhY3Jvc3MgbXVsdGlwbGUgR2F0ZXdheQogaW5zdGFu
Y2VzIGFyZSBtZXJnZWQuIFRoZSBjb25maWd1cmF0aW9uIGZvciBtdWx0aXBsZSBHYXRld2F5
IGluc3RhbmNlcyB3aXRoCiB0aGUgc2FtZSBzY29wZSB3aWxsIGJlIG1lcmdlZCBhcyBwcmVz
ZW50ZWQgYXMgYSBzaW5nbGUgY29uZmlndXJhdGlvbiB0byB0aGUKIHByb3h5L2xvYWQgYmFs
YW5jZXIuCgogTWF4IGxlbmd0aCA2NCBjaGFyYWN0ZXJzLgogU2NvcGUgc2hvdWxkIHN0YXJ0
IHdpdGggYSBsZXR0ZXIgYW5kIGNhbiBvbmx5IGhhdmUgbGV0dGVycywgbnVtYmVycywKIGh5
cGhlbnMuCgoNCgUEAAIKBRIEpwECCAoNCgUEAAIKARIEpwEJDgoNCgUEAAIKAxIEpwEREgoN
CgUEAAIKCBIEpwETOwoQCggEAAIKCJwIABIEpwEUOgqeAQoEBAACCxIGqwECsAEEGo0BIE9w
dGlvbmFsLiBBIGZ1bGx5LXF1YWxpZmllZCBTZXJ2ZXJUTFNQb2xpY3kgVVJMIHJlZmVyZW5j
ZS4gU3BlY2lmaWVzIGhvdwogVExTIHRyYWZmaWMgaXMgdGVybWluYXRlZC4gSWYgZW1wdHks
IFRMUyB0ZXJtaW5hdGlvbiBpcyBkaXNhYmxlZC4KCg0KBQQAAgsFEgSrAQIICg0KBQQAAgsB
EgSrAQkaCg0KBQQAAgsDEgSrAR0eCg8KBQQAAgsIEgarAR+wAQMKEAoIBAACCwicCAASBKwB
BCoKEQoHBAACCwifCBIGrQEErwEFCu0BCgQEAAIMEga1AQK6AQQa3AEgT3B0aW9uYWwuIEEg
ZnVsbHktcXVhbGlmaWVkIENlcnRpZmljYXRlcyBVUkwgcmVmZXJlbmNlLiBUaGUgcHJveHkg
cHJlc2VudHMKIGEgQ2VydGlmaWNhdGUgKHNlbGVjdGVkIGJhc2VkIG9uIFNOSSkgd2hlbiBl
c3RhYmxpc2hpbmcgYSBUTFMgY29ubmVjdGlvbi4KIFRoaXMgZmVhdHVyZSBvbmx5IGFwcGxp
ZXMgdG8gZ2F0ZXdheXMgb2YgdHlwZSAnU0VDVVJFX1dFQl9HQVRFV0FZJy4KCg0KBQQAAgwE
EgS1AQIKCg0KBQQAAgwFEgS1AQsRCg0KBQQAAgwBEgS1ARIiCg0KBQQAAgwDEgS1ASUnCg8K
BQQAAgwIEga1ASi6AQMKEAoIBAACDAicCAASBLYBBCoKEQoHBAACDAifCBIGtwEEuQEFCsgC
CgQEAAINEgbEAQLJAQQatwIgT3B0aW9uYWwuIEEgZnVsbHktcXVhbGlmaWVkIEdhdGV3YXlT
ZWN1cml0eVBvbGljeSBVUkwgcmVmZXJlbmNlLgogRGVmaW5lcyBob3cgYSBzZXJ2ZXIgc2hv
dWxkIGFwcGx5IHNlY3VyaXR5IHBvbGljeSB0byBpbmJvdW5kCiAoVk0gdG8gUHJveHkpIGlu
aXRpYXRlZCBjb25uZWN0aW9ucy4KCiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2dhdGV3YXlTZWN1cml0eVBvbGljaWVzL3N3Zy1wb2xpY3lgLgoKIFRoaXMgcG9s
aWN5IGlzIHNwZWNpZmljIHRvIGdhdGV3YXlzIG9mIHR5cGUgJ1NFQ1VSRV9XRUJfR0FURVdB
WScuCgoNCgUEAAINBRIExAECCAoNCgUEAAINARIExAEJIAoNCgUEAAINAxIExAEjJQoPCgUE
AAINCBIGxAEmyQEDChAKCAQAAg0InAgAEgTFAQQqChEKBwQAAg0InwgSBsYBBMgBBQr6AQoE
BAACDhIG0AEC0wEEGukBIE9wdGlvbmFsLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBp
ZGVudGlmeWluZyB0aGUgVlBDIG5ldHdvcmsgdGhhdCBpcwogdXNpbmcgdGhpcyBjb25maWd1
cmF0aW9uLiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy8qL2dsb2JhbC9uZXR3b3Jrcy9uZXR3
b3JrLTFgLgoKIEN1cnJlbnRseSwgdGhpcyBmaWVsZCBpcyBzcGVjaWZpYyB0byBnYXRld2F5
cyBvZiB0eXBlICdTRUNVUkVfV0VCX0dBVEVXQVknLgoKDQoFBAACDgUSBNABAggKDQoFBAAC
DgESBNABCRAKDQoFBAACDgMSBNABExUKDwoFBAACDggSBtABFtMBAwoQCggEAAIOCJwIABIE
0QEEKgoPCgcEAAIOCJ8IEgTSAQRQCocCCgQEAAIPEgbaAQLfAQQa9gEgT3B0aW9uYWwuIFRo
ZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIGlkZW50aWZ5aW5nICB0aGUgc3VibmV0d29yayBp
biB3aGljaAogdGhpcyBTV0cgaXMgYWxsb2NhdGVkLiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0
cy8qL3JlZ2lvbnMvdXMtY2VudHJhbDEvc3VibmV0d29ya3MvbmV0d29yay0xYAoKIEN1cnJl
bnRseSwgdGhpcyBmaWVsZCBpcyBzcGVjaWZpYyB0byBnYXRld2F5cyBvZiB0eXBlICdTRUNV
UkVfV0VCX0dBVEVXQVkiLgoKDQoFBAACDwUSBNoBAggKDQoFBAACDwESBNoBCRMKDQoFBAAC
DwMSBNoBFhgKDwoFBAACDwgSBtoBGd8BAwoQCggEAAIPCJwIABIE2wEEKgoRCgcEAAIPCJ8I
EgbcAQTeAQUKfQoEBAACEBIE4wECRRpvIE9wdGlvbmFsLiBUaGUgSVAgVmVyc2lvbiB0aGF0
IHdpbGwgYmUgdXNlZCBieSB0aGlzIGdhdGV3YXkuIFZhbGlkIG9wdGlvbnMKIGFyZSBJUFY0
IG9yIElQVjYuIERlZmF1bHQgaXMgSVBWNC4KCg0KBQQAAhAGEgTjAQILCg0KBQQAAhABEgTj
AQwWCg0KBQQAAhADEgTjARkbCg0KBQQAAhAIEgTjARxEChAKCAQAAhAInAgAEgTjAR1DCs0B
CgQEAAIREgboAQLpAS8avAEgT3B0aW9uYWwuIERldGVybWluZXMgaWYgZW52b3kgd2lsbCBp
bnNlcnQgaW50ZXJuYWwgZGVidWcgaGVhZGVycyBpbnRvCiB1cHN0cmVhbSByZXF1ZXN0cy4g
T3RoZXIgRW52b3kgaGVhZGVycyBtYXkgc3RpbGwgYmUgaW5qZWN0ZWQuIEJ5IGRlZmF1bHQs
CiBlbnZveSB3aWxsIG5vdCBpbnNlcnQgYW55IGRlYnVnIGhlYWRlcnMuCgoNCgUEAAIRBBIE
6AECCgoNCgUEAAIRBhIE6AELFwoNCgUEAAIRARIE6AEYJQoNCgUEAAIRAxIE6AEoKgoNCgUE
AAIRCBIE6QEGLgoQCggEAAIRCJwIABIE6QEHLQrGAQoEBAACEhIE7gECSRq3ASBPcHRpb25h
bC4gVGhlIHJvdXRpbmcgbW9kZSBvZiB0aGUgR2F0ZXdheS4KIFRoaXMgZmllbGQgaXMgY29u
ZmlndXJhYmxlIG9ubHkgZm9yIGdhdGV3YXlzIG9mIHR5cGUgU0VDVVJFX1dFQl9HQVRFV0FZ
LgogVGhpcyBmaWVsZCBpcyByZXF1aXJlZCBmb3IgZ2F0ZXdheXMgb2YgdHlwZSBTRUNVUkVf
V0VCX0dBVEVXQVkuCgoNCgUEAAISBhIE7gECDQoNCgUEAAISARIE7gEOGgoNCgUEAAISAxIE
7gEdHwoNCgUEAAISCBIE7gEgSAoQCggEAAISCJwIABIE7gEhRwrOAQoEBAACExIE8wECSRq/
ASBPcHRpb25hbC4gSWYgdHJ1ZSwgdGhlIGdhdGV3YXkgd2lsbCBhbGxvdyB0cmFmZmljIGZy
b20gY2xpZW50cyBvdXRzaWRlIG9mCiB0aGUgcmVnaW9uIHdoZXJlIHRoZSBnYXRld2F5IGlz
IGxvY2F0ZWQuCiBUaGlzIGZpZWxkIGlzIGNvbmZpZ3VyYWJsZSBvbmx5IGZvciBnYXRld2F5
cyBvZiB0eXBlIFNFQ1VSRV9XRUJfR0FURVdBWS4KCg0KBQQAAhMFEgTzAQIGCg0KBQQAAhMB
EgTzAQcaCg0KBQQAAhMDEgTzAR0fCg0KBQQAAhMIEgTzASBIChAKCAQAAhMInAgAEgTzASFH
CjoKAgQBEgb3AQCIAgEaLCBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgTGlzdEdhdGV3YXlzIG1l
dGhvZC4KCgsKAwQBARIE9wEIGwqSAQoEBAECABIG+gEC/wEEGoEBIFJlcXVpcmVkLiBUaGUg
cHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3aGljaCB0aGUgR2F0ZXdheXMgc2hvdWxkIGJl
CiBsaXN0ZWQsIHNwZWNpZmllZCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9u
cy8qYC4KCg0KBQQBAgAFEgT6AQIICg0KBQQBAgABEgT6AQkPCg0KBQQBAgADEgT6ARITCg8K
BQQBAgAIEgb6ART/AQMKEAoIBAECAAicCAASBPsBBCoKEQoHBAECAAifCBIG/AEE/gEFCj4K
BAQBAgESBIICAhYaMCBNYXhpbXVtIG51bWJlciBvZiBHYXRld2F5cyB0byByZXR1cm4gcGVy
IGNhbGwuCgoNCgUEAQIBBRIEggICBwoNCgUEAQIBARIEggIIEQoNCgUEAQIBAxIEggIUFQrH
AQoEBAECAhIEhwICGBq4ASBUaGUgdmFsdWUgcmV0dXJuZWQgYnkgdGhlIGxhc3QgYExpc3RH
YXRld2F5c1Jlc3BvbnNlYAogSW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRpbnVhdGlv
biBvZiBhIHByaW9yIGBMaXN0R2F0ZXdheXNgIGNhbGwsCiBhbmQgdGhhdCB0aGUgc3lzdGVt
IHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDQoFBAECAgUSBIcCAggK
DQoFBAECAgESBIcCCRMKDQoFBAECAgMSBIcCFhcKPQoCBAISBosCAJYCARovIFJlc3BvbnNl
IHJldHVybmVkIGJ5IHRoZSBMaXN0R2F0ZXdheXMgbWV0aG9kLgoKCwoDBAIBEgSLAggcCioK
BAQCAgASBI0CAiAaHCBMaXN0IG9mIEdhdGV3YXkgcmVzb3VyY2VzLgoKDQoFBAICAAQSBI0C
AgoKDQoFBAICAAYSBI0CCxIKDQoFBAICAAESBI0CExsKDQoFBAICAAMSBI0CHh8K6QEKBAQC
AgESBJICAh0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2Ug
YXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlz
IGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwog
bWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBg
cGFnZV90b2tlbmAuCgoNCgUEAgIBBRIEkgICCAoNCgUEAgIBARIEkgIJGAoNCgUEAgIBAxIE
kgIbHAo0CgQEAgICEgSVAgIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNo
ZWQuCgoNCgUEAgICBBIElQICCgoNCgUEAgICBRIElQILEQoNCgUEAgICARIElQISHQoNCgUE
AgICAxIElQIgIQo2CgIEAxIGmQIAogIBGiggUmVxdWVzdCB1c2VkIGJ5IHRoZSBHZXRHYXRl
d2F5IG1ldGhvZC4KCgsKAwQDARIEmQIIGQp1CgQEAwIAEgacAgKhAgQaZSBSZXF1aXJlZC4g
QSBuYW1lIG9mIHRoZSBHYXRld2F5IHRvIGdldC4gTXVzdCBiZSBpbiB0aGUgZm9ybWF0CiBg
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9nYXRld2F5cy8qYC4KCg0KBQQDAgAFEgScAgIICg0K
BQQDAgABEgScAgkNCg0KBQQDAgADEgScAhARCg8KBQQDAgAIEgacAhKhAgMKEAoIBAMCAAic
CAASBJ0CBCoKEQoHBAMCAAifCBIGngIEoAIFCjkKAgQEEgalAgC0AgEaKyBSZXF1ZXN0IHVz
ZWQgYnkgdGhlIENyZWF0ZUdhdGV3YXkgbWV0aG9kLgoKCwoDBAQBEgSlAggcCnAKBAQEAgAS
BqgCAq0CBBpgIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBHYXRld2F5
LiBNdXN0IGJlIGluIHRoZQogZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qYC4KCg0K
BQQEAgAFEgSoAgIICg0KBQQEAgABEgSoAgkPCg0KBQQEAgADEgSoAhITCg8KBQQEAgAIEgao
AhStAgMKEAoIBAQCAAicCAASBKkCBCoKEQoHBAQCAAifCBIGqgIErAIFCksKBAQEAgESBLAC
AkEaPSBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUgR2F0ZXdheSByZXNvdXJjZSB0byBi
ZSBjcmVhdGVkLgoKDQoFBAQCAQUSBLACAggKDQoFBAQCAQESBLACCRMKDQoFBAQCAQMSBLAC
FhcKDQoFBAQCAQgSBLACGEAKEAoIBAQCAQicCAASBLACGT8KOQoEBAQCAhIEswICPxorIFJl
cXVpcmVkLiBHYXRld2F5IHJlc291cmNlIHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAICBhIEswIC
CQoNCgUEBAICARIEswIKEQoNCgUEBAICAxIEswIUFQoNCgUEBAICCBIEswIWPgoQCggEBAIC
CJwIABIEswIXPQo5CgIEBRIGtwIAwgIBGisgUmVxdWVzdCB1c2VkIGJ5IHRoZSBVcGRhdGVH
YXRld2F5IG1ldGhvZC4KCgsKAwQFARIEtwIIHArZAgoEBAUCABIGvQICvgIvGsgCIE9wdGlv
bmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92
ZXJ3cml0dGVuIGluIHRoZQogR2F0ZXdheSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhl
IGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0
aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92
ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3Qg
cHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoN
CgUEBQIABhIEvQICGwoNCgUEBQIAARIEvQIcJwoNCgUEBQIAAxIEvQIqKwoNCgUEBQIACBIE
vgIGLgoQCggEBQIACJwIABIEvgIHLQozCgQEBQIBEgTBAgI/GiUgUmVxdWlyZWQuIFVwZGF0
ZWQgR2F0ZXdheSByZXNvdXJjZS4KCg0KBQQFAgEGEgTBAgIJCg0KBQQFAgEBEgTBAgoRCg0K
BQQFAgEDEgTBAhQVCg0KBQQFAgEIEgTBAhY+ChAKCAQFAgEInAgAEgTBAhc9CjkKAgQGEgbF
AgDOAgEaKyBSZXF1ZXN0IHVzZWQgYnkgdGhlIERlbGV0ZUdhdGV3YXkgbWV0aG9kLgoKCwoD
BAYBEgTFAggcCngKBAQGAgASBsgCAs0CBBpoIFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIEdh
dGV3YXkgdG8gZGVsZXRlLiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2dhdGV3YXlzLypgLgoKDQoFBAYCAAUSBMgCAggKDQoFBAYCAAESBMgCCQ0K
DQoFBAYCAAMSBMgCEBEKDwoFBAYCAAgSBsgCEs0CAwoQCggEBgIACJwIABIEyQIEKgoRCgcE
BgIACJ8IEgbKAgTMAgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::Gateway::Gateway ===
    # Fields for Gateway
    # Field: name Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.Gateway.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: type Type: 14 (.google.cloud.networkservices.v1.Gateway.Type)
    # Field: addresses Type: 9 ()
    # Field: ports Type: 5 ()
    # Field: all_ports Type: 8 ()
    # Field: scope Type: 9 ()
    # Field: server_tls_policy Type: 9 ()
    # Field: certificate_urls Type: 9 ()
    # Field: gateway_security_policy Type: 9 ()
    # Field: network Type: 9 ()
    # Field: subnetwork Type: 9 ()
    # Field: ip_version Type: 14 (.google.cloud.networkservices.v1.Gateway.IpVersion)
    # Field: envoy_headers Type: 14 (.google.cloud.networkservices.v1.EnvoyHeaders)
    # Field: routing_mode Type: 14 (.google.cloud.networkservices.v1.Gateway.RoutingMode)
    # Field: allow_global_access Type: 8 ()

# Enum: Gateway::Type
our $Gateway_TYPE_UNSPECIFIED = 0;
our $Gateway_OPEN_MESH = 1;
our $Gateway_SECURE_WEB_GATEWAY = 2;

# Enum: Gateway::IpVersion
our $Gateway_IP_VERSION_UNSPECIFIED = 0;
our $Gateway_IPV4 = 1;
our $Gateway_IPV6 = 2;

# Enum: Gateway::RoutingMode
our $Gateway_EXPLICIT_ROUTING_MODE = 0;
our $Gateway_NEXT_HOP_ROUTING_MODE = 1;

# === Message: Google::Cloud::Networkservices::V1::Gateway::ListGatewaysRequest ===
    # Fields for ListGatewaysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::Gateway::ListGatewaysResponse ===
    # Fields for ListGatewaysResponse
    # Field: gateways Type: 11 (.google.cloud.networkservices.v1.Gateway)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::Gateway::GetGatewayRequest ===
    # Fields for GetGatewayRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::Gateway::CreateGatewayRequest ===
    # Fields for CreateGatewayRequest
    # Field: parent Type: 9 ()
    # Field: gateway_id Type: 9 ()
    # Field: gateway Type: 11 (.google.cloud.networkservices.v1.Gateway)

# === Message: Google::Cloud::Networkservices::V1::Gateway::UpdateGatewayRequest ===
    # Fields for UpdateGatewayRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: gateway Type: 11 (.google.cloud.networkservices.v1.Gateway)

# === Message: Google::Cloud::Networkservices::V1::Gateway::DeleteGatewayRequest ===
    # Fields for DeleteGatewayRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1::Gateway - Compiled Protocol Buffers messages for google/cloud/networkservices/v1/gateway.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Gateway;

    my $msg = Google::Cloud::Networkservices::V1::Gateway::Gateway->new({
        name => $name,
        self_link => $self_link,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1::Gateway::Gateway->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1/gateway.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1::Gateway::Gateway

Gateway represents the configuration for a proxy, typically a load balancer.
It captures the ip:port over which the services are exposed by the proxy,
along with any policy configurations. Routes have reference to to Gateways to
dictate how requests should be routed by this Gateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the Gateway resource. It matches pattern
`projects/*/locations/*/gateways/<gateway_name>`.

=item * C<< $msg->self_link() >> / C<< $msg->self_link($value) >>

Type: C<String>

Output only. Server-defined URL of this resource

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::Gateway::Gateway::LabelsEntry>)

Optional. Set of label tags associated with the Gateway resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A free-text description of the resource. Max length 1024
characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1::Gateway::Type>)

Immutable. The type of the customer managed gateway.
This field is required. If unspecified, an error is returned.

=item * C<< $msg->addresses() >> / C<< $msg->addresses($value) >>

Type: C<String>

Optional. Zero or one IPv4 or IPv6 address on which the Gateway will
receive the traffic. When no address is provided, an IP from the subnetwork
is allocated

This field only applies to gateways of type 'SECURE_WEB_GATEWAY'.
Gateways of type 'OPEN_MESH' listen on 0.0.0.0 for IPv4 and :: for IPv6.

=item * C<< $msg->ports() >> / C<< $msg->ports($value) >>

Type: C<Int32>

Required. One or more port numbers (1-65535), on which the Gateway will
receive traffic. The proxy binds to the specified ports.
Gateways of type 'SECURE_WEB_GATEWAY' are limited to 5 ports.
Gateways of type 'OPEN_MESH' listen on 0.0.0.0 for IPv4 and :: for IPv6 and
support multiple ports.

=item * C<< $msg->all_ports() >> / C<< $msg->all_ports($value) >>

Type: C<Bool>

Optional. If true, the Gateway will listen on all ports. This is mutually
exclusive with the `ports` field. This field only applies to gateways of
type 'SECURE_WEB_GATEWAY'.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Optional. Scope determines how configuration across multiple Gateway
instances are merged. The configuration for multiple Gateway instances with
the same scope will be merged as presented as a single configuration to the
proxy/load balancer.

Max length 64 characters.
Scope should start with a letter and can only have letters, numbers,
hyphens.

=item * C<< $msg->server_tls_policy() >> / C<< $msg->server_tls_policy($value) >>

Type: C<String>

Optional. A fully-qualified ServerTLSPolicy URL reference. Specifies how
TLS traffic is terminated. If empty, TLS termination is disabled.

=item * C<< $msg->certificate_urls() >> / C<< $msg->certificate_urls($value) >>

Type: C<String>

Optional. A fully-qualified Certificates URL reference. The proxy presents
a Certificate (selected based on SNI) when establishing a TLS connection.
This feature only applies to gateways of type 'SECURE_WEB_GATEWAY'.

=item * C<< $msg->gateway_security_policy() >> / C<< $msg->gateway_security_policy($value) >>

Type: C<String>

Optional. A fully-qualified GatewaySecurityPolicy URL reference.
Defines how a server should apply security policy to inbound
(VM to Proxy) initiated connections.

For example:
`projects/*/locations/*/gatewaySecurityPolicies/swg-policy`.

This policy is specific to gateways of type 'SECURE_WEB_GATEWAY'.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Optional. The relative resource name identifying the VPC network that is
using this configuration. For example:
`projects/*/global/networks/network-1`.

Currently, this field is specific to gateways of type 'SECURE_WEB_GATEWAY'.

=item * C<< $msg->subnetwork() >> / C<< $msg->subnetwork($value) >>

Type: C<String>

Optional. The relative resource name identifying  the subnetwork in which
this SWG is allocated. For example:
`projects/*/regions/us-central1/subnetworks/network-1`

Currently, this field is specific to gateways of type 'SECURE_WEB_GATEWAY".

=item * C<< $msg->ip_version() >> / C<< $msg->ip_version($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1::Gateway::IpVersion>)

Optional. The IP Version that will be used by this gateway. Valid options
are IPV4 or IPV6. Default is IPV4.

=item * C<< $msg->envoy_headers() >> / C<< $msg->envoy_headers($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1::EnvoyHeaders>)

Optional. Determines if envoy will insert internal debug headers into
upstream requests. Other Envoy headers may still be injected. By default,
envoy will not insert any debug headers.

=item * C<< $msg->routing_mode() >> / C<< $msg->routing_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1::Gateway::RoutingMode>)

Optional. The routing mode of the Gateway.
This field is configurable only for gateways of type SECURE_WEB_GATEWAY.
This field is required for gateways of type SECURE_WEB_GATEWAY.

=item * C<< $msg->allow_global_access() >> / C<< $msg->allow_global_access($value) >>

Type: C<Bool>

Optional. If true, the gateway will allow traffic from clients outside of
the region where the gateway is located.
This field is configurable only for gateways of type SECURE_WEB_GATEWAY.

=back

=head3 Enum: Gateway::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<OPEN_MESH> => C<1>

=item * C<SECURE_WEB_GATEWAY> => C<2>

=back

=head3 Enum: Gateway::IpVersion

=over 4

=item * C<IP_VERSION_UNSPECIFIED> => C<0>

=item * C<IPV4> => C<1>

=item * C<IPV6> => C<2>

=back

=head3 Enum: Gateway::RoutingMode

=over 4

=item * C<EXPLICIT_ROUTING_MODE> => C<0>

=item * C<NEXT_HOP_ROUTING_MODE> => C<1>

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::ListGatewaysRequest

Request used with the ListGateways method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the Gateways should be
listed, specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of Gateways to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListGatewaysResponse`
Indicates that this is a continuation of a prior `ListGateways` call,
and that the system should return the next page of data.

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::ListGatewaysResponse

Response returned by the ListGateways method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gateways() >> / C<< $msg->gateways($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::Gateway::Gateway>)

List of Gateway resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::GetGatewayRequest

Request used by the GetGateway method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the Gateway to get. Must be in the format
`projects/*/locations/*/gateways/*`.

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::CreateGatewayRequest

Request used by the CreateGateway method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the Gateway. Must be in the
format `projects/*/locations/*`.

=item * C<< $msg->gateway_id() >> / C<< $msg->gateway_id($value) >>

Type: C<String>

Required. Short name of the Gateway resource to be created.

=item * C<< $msg->gateway() >> / C<< $msg->gateway($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::Gateway::Gateway>)

Required. Gateway resource to be created.

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::UpdateGatewayRequest

Request used by the UpdateGateway method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Gateway resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->gateway() >> / C<< $msg->gateway($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::Gateway::Gateway>)

Required. Updated Gateway resource.

=back

=head2 Google::Cloud::Networkservices::V1::Gateway::DeleteGatewayRequest

Request used by the DeleteGateway method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the Gateway to delete. Must be in the format
`projects/*/locations/*/gateways/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1::Gateway::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
