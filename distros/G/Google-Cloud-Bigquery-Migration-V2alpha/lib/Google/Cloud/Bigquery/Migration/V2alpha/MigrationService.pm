package Google::Cloud::Bigquery::Migration::V2alpha::MigrationService;

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
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities };
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails };
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvbWlncmF0aW9uX3Nl
cnZpY2UucHJvdG8SJ2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYRoc
Z29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8a
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aQGdvb2dsZS9jbG91ZC9iaWdxdWVyeS9taWdyYXRpb24vdjJhbHBoYS9taWdyYXRp
b25fZW50aXRpZXMucHJvdG8aRWdvb2dsZS9jbG91ZC9iaWdxdWVyeS9taWdyYXRpb24vdjJh
bHBoYS9taWdyYXRpb25fZXJyb3JfZGV0YWlscy5wcm90bxo/Z29vZ2xlL2Nsb3VkL2JpZ3F1
ZXJ5L21pZ3JhdGlvbi92MmFscGhhL21pZ3JhdGlvbl9tZXRyaWNzLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
ItMBCh5DcmVhdGVNaWdyYXRpb25Xb3JrZmxvd1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQing
QQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50Em4KEm1p
Z3JhdGlvbl93b3JrZmxvdxgCIAEoCzI6Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRp
b24udjJhbHBoYS5NaWdyYXRpb25Xb3JrZmxvd0ID4EECUhFtaWdyYXRpb25Xb3JrZmxvdyKm
AQobR2V0TWlncmF0aW9uV29ya2Zsb3dSZXF1ZXN0Ek4KBG5hbWUYASABKAlCOuBBAvpBNAoy
YmlncXVlcnltaWdyYXRpb24uZ29vZ2xlYXBpcy5jb20vTWlncmF0aW9uV29ya2Zsb3dSBG5h
bWUSNwoJcmVhZF9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IIcmVh
ZE1hc2si1wEKHUxpc3RNaWdyYXRpb25Xb3JrZmxvd3NSZXF1ZXN0EkEKBnBhcmVudBgBIAEo
CUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBI3
CglyZWFkX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUghyZWFkTWFz
axIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBCABKAlSCXBh
Z2VUb2tlbiK1AQoeTGlzdE1pZ3JhdGlvbldvcmtmbG93c1Jlc3BvbnNlEmsKE21pZ3JhdGlv
bl93b3JrZmxvd3MYASADKAsyOi5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
YWxwaGEuTWlncmF0aW9uV29ya2Zsb3dSEm1pZ3JhdGlvbldvcmtmbG93cxImCg9uZXh0X3Bh
Z2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4icAoeRGVsZXRlTWlncmF0aW9uV29ya2Zs
b3dSZXF1ZXN0Ek4KBG5hbWUYASABKAlCOuBBAvpBNAoyYmlncXVlcnltaWdyYXRpb24uZ29v
Z2xlYXBpcy5jb20vTWlncmF0aW9uV29ya2Zsb3dSBG5hbWUibwodU3RhcnRNaWdyYXRpb25X
b3JrZmxvd1JlcXVlc3QSTgoEbmFtZRgBIAEoCUI64EEC+kE0CjJiaWdxdWVyeW1pZ3JhdGlv
bi5nb29nbGVhcGlzLmNvbS9NaWdyYXRpb25Xb3JrZmxvd1IEbmFtZSKpAQoaR2V0TWlncmF0
aW9uU3VidGFza1JlcXVlc3QSTQoEbmFtZRgBIAEoCUI54EEC+kEzCjFiaWdxdWVyeW1pZ3Jh
dGlvbi5nb29nbGVhcGlzLmNvbS9NaWdyYXRpb25TdWJ0YXNrUgRuYW1lEjwKCXJlYWRfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIIcmVhZE1hc2sikwIK
HExpc3RNaWdyYXRpb25TdWJ0YXNrc1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQK
MmJpZ3F1ZXJ5bWlncmF0aW9uLmdvb2dsZWFwaXMuY29tL01pZ3JhdGlvbldvcmtmbG93UgZw
YXJlbnQSPAoJcmVhZF9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID
4EEBUghyZWFkTWFzaxIgCglwYWdlX3NpemUYAyABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgEIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAUgASgJQgPgQQFSBmZp
bHRlciKxAQodTGlzdE1pZ3JhdGlvblN1YnRhc2tzUmVzcG9uc2USaAoSbWlncmF0aW9uX3N1
YnRhc2tzGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhh
Lk1pZ3JhdGlvblN1YnRhc2tSEW1pZ3JhdGlvblN1YnRhc2tzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbjKqDQoQTWlncmF0aW9uU2VydmljZRKKAgoXQ3JlYXRl
TWlncmF0aW9uV29ya2Zsb3cSRy5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
YWxwaGEuQ3JlYXRlTWlncmF0aW9uV29ya2Zsb3dSZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLk1pZ3JhdGlvbldvcmtmbG93ImqC0+STAkgiMi92
MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vd29ya2Zsb3dzOhJtaWdy
YXRpb25fd29ya2Zsb3faQRlwYXJlbnQsbWlncmF0aW9uX3dvcmtmbG93EtsBChRHZXRNaWdy
YXRpb25Xb3JrZmxvdxJELmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBo
YS5HZXRNaWdyYXRpb25Xb3JrZmxvd1JlcXVlc3QaOi5nb29nbGUuY2xvdWQuYmlncXVlcnku
bWlncmF0aW9uLnYyYWxwaGEuTWlncmF0aW9uV29ya2Zsb3ciQYLT5JMCNBIyL3YyYWxwaGEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi93b3JrZmxvd3MvKn3aQQRuYW1lEu4BChZM
aXN0TWlncmF0aW9uV29ya2Zsb3dzEkYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlv
bi52MmFscGhhLkxpc3RNaWdyYXRpb25Xb3JrZmxvd3NSZXF1ZXN0GkcuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLkxpc3RNaWdyYXRpb25Xb3JrZmxvd3NSZXNw
b25zZSJDgtPkkwI0EjIvdjJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L3dvcmtmbG93c9pBBnBhcmVudBK9AQoXRGVsZXRlTWlncmF0aW9uV29ya2Zsb3cSRy5nb29n
bGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuRGVsZXRlTWlncmF0aW9uV29y
a2Zsb3dSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkGC0+STAjQqMi92MmFscGhh
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovd29ya2Zsb3dzLyp92kEEbmFtZRLEAQoW
U3RhcnRNaWdyYXRpb25Xb3JrZmxvdxJGLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRp
b24udjJhbHBoYS5TdGFydE1pZ3JhdGlvbldvcmtmbG93UmVxdWVzdBoWLmdvb2dsZS5wcm90
b2J1Zi5FbXB0eSJKgtPkkwI9IjgvdjJhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3dvcmtmbG93cy8qfTpzdGFydDoBKtpBBG5hbWUS4wEKE0dldE1pZ3JhdGlvblN1YnRh
c2sSQy5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuR2V0TWlncmF0
aW9uU3VidGFza1JlcXVlc3QaOS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
YWxwaGEuTWlncmF0aW9uU3VidGFzayJMgtPkkwI/Ej0vdjJhbHBoYS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3dvcmtmbG93cy8qL3N1YnRhc2tzLyp92kEEbmFtZRL2AQoVTGlz
dE1pZ3JhdGlvblN1YnRhc2tzEkUuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52
MmFscGhhLkxpc3RNaWdyYXRpb25TdWJ0YXNrc1JlcXVlc3QaRi5nb29nbGUuY2xvdWQuYmln
cXVlcnkubWlncmF0aW9uLnYyYWxwaGEuTGlzdE1pZ3JhdGlvblN1YnRhc2tzUmVzcG9uc2Ui
ToLT5JMCPxI9L3YyYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtm
bG93cy8qfS9zdWJ0YXNrc9pBBnBhcmVudBpUykEgYmlncXVlcnltaWdyYXRpb24uZ29vZ2xl
YXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtQuUBCitjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhQhVN
aWdyYXRpb25TZXJ2aWNlUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS9t
aWdyYXRpb24vYXBpdjJhbHBoYS9taWdyYXRpb25wYjttaWdyYXRpb25wYqoCJ0dvb2dsZS5D
bG91ZC5CaWdRdWVyeS5NaWdyYXRpb24uVjJBbHBoYcoCJ0dvb2dsZVxDbG91ZFxCaWdRdWVy
eVxNaWdyYXRpb25cVjJhbHBoYUrDOAoHEgUOAPYBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
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
aGUgTGljZW5zZS4KCggKAQISAxAAMAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQAjCgkKAgMEEgMWAEoKCQoCAwUSAxcATwoJCgIDBhIDGABJCgkKAgMHEgMZ
ACUKCQoCAwgSAxoAKgoICgEIEgMcAEQKCQoCCCUSAxwARAoICgEIEgMdAGAKCQoCCAsSAx0A
YAoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADYKCQoCCAgSAx8ANgoICgEIEgMgAEQK
CQoCCAESAyAARAoICgEIEgMhAEUKCQoCCCkSAyEARQovCgIGABIEJABkARojIFNlcnZpY2Ug
dG8gaGFuZGxlIEVEVyBtaWdyYXRpb25zLgoKCgoDBgABEgMkCBgKCgoDBgADEgMlAkgKDAoF
BgADmQgSAyUCSAoKCgMGAAMSAyYCVgoMCgUGAAOaCBIDJgJWCi0KBAYAAgASBCkCLwMaHyBD
cmVhdGVzIGEgbWlncmF0aW9uIHdvcmtmbG93LgoKDAoFBgACAAESAykGHQoMCgUGAAIAAhID
KR48CgwKBQYAAgADEgMpR1gKDQoFBgACAAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCgwK
BQYAAgAEEgMuBEcKDwoIBgACAASbCAASAy4ERwo9CgQGAAIBEgQyAjcDGi8gR2V0cyBhIHBy
ZXZpb3VzbHkgY3JlYXRlZCBtaWdyYXRpb24gd29ya2Zsb3cuCgoMCgUGAAIBARIDMgYaCgwK
BQYAAgECEgMyGzYKDAoFBgACAQMSAzJBUgoNCgUGAAIBBBIEMwQ1BgoRCgkGAAIBBLDKvCIS
BDMENQYKDAoFBgACAQQSAzYEMgoPCggGAAIBBJsIABIDNgQyCjwKBAYAAgISBDoCPwMaLiBM
aXN0cyBwcmV2aW91c2x5IGNyZWF0ZWQgbWlncmF0aW9uIHdvcmtmbG93LgoKDAoFBgACAgES
AzoGHAoMCgUGAAICAhIDOh06CgwKBQYAAgIDEgM6RWMKDQoFBgACAgQSBDsEPQYKEQoJBgAC
AgSwyrwiEgQ7BD0GCgwKBQYAAgIEEgM+BDQKDwoIBgACAgSbCAASAz4ENAo1CgQGAAIDEgRC
AkcDGicgRGVsZXRlcyBhIG1pZ3JhdGlvbiB3b3JrZmxvdyBieSBuYW1lLgoKDAoFBgACAwES
A0IGHQoMCgUGAAIDAhIDQh48CgwKBQYAAgMDEgNCR1wKDQoFBgACAwQSBEMERQYKEQoJBgAC
AwSwyrwiEgRDBEUGCgwKBQYAAgMEEgNGBDIKDwoIBgACAwSbCAASA0YEMgr3AQoEBgACBBIE
TQJTAxroASBTdGFydHMgYSBwcmV2aW91c2x5IGNyZWF0ZWQgbWlncmF0aW9uIHdvcmtmbG93
LiBJLmUuLCB0aGUgc3RhdGUgdHJhbnNpdGlvbnMKIGZyb20gRFJBRlQgdG8gUlVOTklORy4g
VGhpcyBpcyBhIG5vLW9wIGlmIHRoZSBzdGF0ZSBpcyBhbHJlYWR5IFJVTk5JTkcuCiBBbiBl
cnJvciB3aWxsIGJlIHNpZ25hbGVkIGlmIHRoZSBzdGF0ZSBpcyBhbnl0aGluZyBvdGhlciB0
aGFuIERSQUZUIG9yCiBSVU5OSU5HLgoKDAoFBgACBAESA00GHAoMCgUGAAIEAhIDTR06CgwK
BQYAAgQDEgNNRVoKDQoFBgACBAQSBE4EUQYKEQoJBgACBASwyrwiEgROBFEGCgwKBQYAAgQE
EgNSBDIKDwoIBgACBASbCAASA1IEMgo8CgQGAAIFEgRWAlsDGi4gR2V0cyBhIHByZXZpb3Vz
bHkgY3JlYXRlZCBtaWdyYXRpb24gc3VidGFzay4KCgwKBQYAAgUBEgNWBhkKDAoFBgACBQIS
A1YaNAoMCgUGAAIFAxIDVj9PCg0KBQYAAgUEEgRXBFkGChEKCQYAAgUEsMq8IhIEVwRZBgoM
CgUGAAIFBBIDWgQyCg8KCAYAAgUEmwgAEgNaBDIKPAoEBgACBhIEXgJjAxouIExpc3RzIHBy
ZXZpb3VzbHkgY3JlYXRlZCBtaWdyYXRpb24gc3VidGFza3MuCgoMCgUGAAIGARIDXgYbCgwK
BQYAAgYCEgNeHDgKDAoFBgACBgMSA15DYAoNCgUGAAIGBBIEXwRhBgoRCgkGAAIGBLDKvCIS
BF8EYQYKDAoFBgACBgQSA2IENAoPCggGAAIGBJsIABIDYgQ0Cj4KAgQAEgRnAHMBGjIgUmVx
dWVzdCB0byBjcmVhdGUgYSBtaWdyYXRpb24gd29ya2Zsb3cgcmVzb3VyY2UuCgoKCgMEAAES
A2cIJgqCAQoEBAACABIEagJvBBp0IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcHJvamVj
dCB0byB3aGljaCB0aGlzIG1pZ3JhdGlvbiB3b3JrZmxvdyBiZWxvbmdzLgogRXhhbXBsZTog
YHByb2plY3RzL2Zvby9sb2NhdGlvbnMvYmFyYAoKDAoFBAACAAUSA2oCCAoMCgUEAAIAARID
agkPCgwKBQQAAgADEgNqEhMKDQoFBAACAAgSBGoUbwMKDwoIBAACAAicCAASA2sEKgoPCgcE
AAIACJ8IEgRsBG4FCjoKBAQAAgESA3ICVBotIFJlcXVpcmVkLiBUaGUgbWlncmF0aW9uIHdv
cmtmbG93IHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNyAhMKDAoFBAACAQESA3IUJgoMCgUEAAIB
AxIDcikqCgwKBQQAAgEIEgNyK1MKDwoIBAACAQicCAASA3IsUgpICgIEARIFdgCCAQEaOyBB
IHJlcXVlc3QgdG8gZ2V0IGEgcHJldmlvdXNseSBjcmVhdGVkIG1pZ3JhdGlvbiB3b3JrZmxv
dy4KCgoKAwQBARIDdggjCoABCgQEAQIAEgR5An4EGnIgUmVxdWlyZWQuIFRoZSB1bmlxdWUg
aWRlbnRpZmllciBmb3IgdGhlIG1pZ3JhdGlvbiB3b3JrZmxvdy4KIEV4YW1wbGU6IGBwcm9q
ZWN0cy8xMjMvbG9jYXRpb25zL3VzL3dvcmtmbG93cy8xMjM0YAoKDAoFBAECAAUSA3kCCAoM
CgUEAQIAARIDeQkNCgwKBQQBAgADEgN5EBEKDQoFBAECAAgSBHkSfgMKDwoIBAECAAicCAAS
A3oEKgoPCgcEAQIACJ8IEgR7BH0FCjMKBAQBAgESBIEBAioaJSBUaGUgbGlzdCBvZiBmaWVs
ZHMgdG8gYmUgcmV0cmlldmVkLgoKDQoFBAECAQYSBIEBAhsKDQoFBAECAQESBIEBHCUKDQoF
BAECAQMSBIEBKCkKSQoCBAISBoUBAJwBARo7IEEgcmVxdWVzdCB0byBsaXN0IHByZXZpb3Vz
bHkgY3JlYXRlZCBtaWdyYXRpb24gd29ya2Zsb3dzLgoKCwoDBAIBEgSFAQglCn4KBAQCAgAS
BogBAo0BBBpuIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gb2YgdGhlIG1p
Z3JhdGlvbiB3b3JrZmxvd3MgdG8gbGlzdC4KIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjMvbG9j
YXRpb25zL3VzYAoKDQoFBAICAAUSBIgBAggKDQoFBAICAAESBIgBCQ8KDQoFBAICAAMSBIgB
EhMKDwoFBAICAAgSBogBFI0BAwoQCggEAgIACJwIABIEiQEEKgoRCgcEAgIACJ8IEgaKAQSM
AQUKMwoEBAICARIEkAECKholIFRoZSBsaXN0IG9mIGZpZWxkcyB0byBiZSByZXRyaWV2ZWQu
CgoNCgUEAgIBBhIEkAECGwoNCgUEAgIBARIEkAEcJQoNCgUEAgIBAxIEkAEoKQp0CgQEAgIC
EgSUAQIWGmYgVGhlIG1heGltdW0gbnVtYmVyIG9mIG1pZ3JhdGlvbiB3b3JrZmxvd3MgdG8g
cmV0dXJuLiBUaGUgc2VydmljZSBtYXkgcmV0dXJuCiBmZXdlciB0aGFuIHRoaXMgbnVtYmVy
LgoKDQoFBAICAgUSBJQBAgcKDQoFBAICAgESBJQBCBEKDQoFBAICAgMSBJQBFBUKgwIKBAQC
AgMSBJsBAhga9AEgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIHByZXZpb3VzIGBMaXN0
TWlncmF0aW9uV29ya2Zsb3dzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRo
ZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1l
dGVycyBwcm92aWRlZCB0byBgTGlzdE1pZ3JhdGlvbldvcmtmbG93c2AKIG11c3QgbWF0Y2gg
dGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQCAgMFEgSbAQII
Cg0KBQQCAgMBEgSbAQkTCg0KBQQCAgMDEgSbARYXCkQKAgQDEgafAQCmAQEaNiBSZXNwb25z
ZSBvYmplY3QgZm9yIGEgYExpc3RNaWdyYXRpb25Xb3JrZmxvd3NgIGNhbGwuCgoLCgMEAwES
BJ8BCCYKTQoEBAMCABIEoQECNRo/IFRoZSBtaWdyYXRpb24gd29ya2Zsb3dzIGZvciB0aGUg
c3BlY2lmaWVkIHByb2plY3QgLyBsb2NhdGlvbi4KCg0KBQQDAgAEEgShAQIKCg0KBQQDAgAG
EgShAQscCg0KBQQDAgABEgShAR0wCg0KBQQDAgADEgShATM0CpABCgQEAwIBEgSlAQIdGoEB
IEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2
ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUg
bm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQDAgEFEgSlAQIICg0KBQQDAgEBEgSlAQkYCg0K
BQQDAgEDEgSlARscCkwKAgQEEgapAQCyAQEaPiBBIHJlcXVlc3QgdG8gZGVsZXRlIGEgcHJl
dmlvdXNseSBjcmVhdGVkIG1pZ3JhdGlvbiB3b3JrZmxvdy4KCgsKAwQEARIEqQEIJgqCAQoE
BAQCABIGrAECsQEEGnIgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhl
IG1pZ3JhdGlvbiB3b3JrZmxvdy4KIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjMvbG9jYXRpb25z
L3VzL3dvcmtmbG93cy8xMjM0YAoKDQoFBAQCAAUSBKwBAggKDQoFBAQCAAESBKwBCQ0KDQoF
BAQCAAMSBKwBEBEKDwoFBAQCAAgSBqwBErEBAwoQCggEBAIACJwIABIErQEEKgoRCgcEBAIA
CJ8IEgauAQSwAQUKSwoCBAUSBrUBAL4BARo9IEEgcmVxdWVzdCB0byBzdGFydCBhIHByZXZp
b3VzbHkgY3JlYXRlZCBtaWdyYXRpb24gd29ya2Zsb3cuCgoLCgMEBQESBLUBCCUKggEKBAQF
AgASBrgBAr0BBBpyIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBt
aWdyYXRpb24gd29ya2Zsb3cuCiBFeGFtcGxlOiBgcHJvamVjdHMvMTIzL2xvY2F0aW9ucy91
cy93b3JrZmxvd3MvMTIzNGAKCg0KBQQFAgAFEgS4AQIICg0KBQQFAgABEgS4AQkNCg0KBQQF
AgADEgS4ARARCg8KBQQFAgAIEga4ARK9AQMKEAoIBAUCAAicCAASBLkBBCoKEQoHBAUCAAif
CBIGugEEvAEFCkkKAgQGEgbBAQDNAQEaOyBBIHJlcXVlc3QgdG8gZ2V0IGEgcHJldmlvdXNs
eSBjcmVhdGVkIG1pZ3JhdGlvbiBzdWJ0YXNrcy4KCgsKAwQGARIEwQEIIgqOAQoEBAYCABIG
xAECyQEEGn4gUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIG1pZ3Jh
dGlvbiBzdWJ0YXNrLgogRXhhbXBsZTogYHByb2plY3RzLzEyMy9sb2NhdGlvbnMvdXMvd29y
a2Zsb3dzLzEyMzQvc3VidGFza3MvNTQzYAoKDQoFBAYCAAUSBMQBAggKDQoFBAYCAAESBMQB
CQ0KDQoFBAYCAAMSBMQBEBEKDwoFBAYCAAgSBsQBEskBAwoQCggEBgIACJwIABIExQEEKgoR
CgcEBgIACJ8IEgbGAQTIAQUKPQoEBAYCARIEzAECUxovIE9wdGlvbmFsLiBUaGUgbGlzdCBv
ZiBmaWVsZHMgdG8gYmUgcmV0cmlldmVkLgoKDQoFBAYCAQYSBMwBAhsKDQoFBAYCAQESBMwB
HCUKDQoFBAYCAQMSBMwBKCkKDQoFBAYCAQgSBMwBKlIKEAoIBAYCAQicCAASBMwBK1EKSAoC
BAcSBtABAOwBARo6IEEgcmVxdWVzdCB0byBsaXN0IHByZXZpb3VzbHkgY3JlYXRlZCBtaWdy
YXRpb24gc3VidGFza3MuCgoLCgMEBwESBNABCCQKfAoEBAcCABIG0wEC2AEEGmwgUmVxdWly
ZWQuIFRoZSBtaWdyYXRpb24gdGFzayBvZiB0aGUgc3VidGFza3MgdG8gbGlzdC4KIEV4YW1w
bGU6IGBwcm9qZWN0cy8xMjMvbG9jYXRpb25zL3VzL3dvcmtmbG93cy8xMjM0YAoKDQoFBAcC
AAUSBNMBAggKDQoFBAcCAAESBNMBCQ8KDQoFBAcCAAMSBNMBEhMKDwoFBAcCAAgSBtMBFNgB
AwoQCggEBwIACJwIABIE1AEEKgoRCgcEBwIACJ8IEgbVAQTXAQUKPQoEBAcCARIE2wECUxov
IE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gYmUgcmV0cmlldmVkLgoKDQoFBAcC
AQYSBNsBAhsKDQoFBAcCAQESBNsBHCUKDQoFBAcCAQMSBNsBKCkKDQoFBAcCAQgSBNsBKlIK
EAoIBAcCAQicCAASBNsBK1EKegoEBAcCAhIE3wECPxpsIE9wdGlvbmFsLiBUaGUgbWF4aW11
bSBudW1iZXIgb2YgbWlncmF0aW9uIHRhc2tzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5
IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIG51bWJlci4KCg0KBQQHAgIFEgTfAQIHCg0KBQQH
AgIBEgTfAQgRCg0KBQQHAgIDEgTfARQVCg0KBQQHAgIIEgTfARY+ChAKCAQHAgIInAgAEgTf
ARc9CosCCgQEBwIDEgTmAQJBGvwBIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVk
IGZyb20gcHJldmlvdXMgYExpc3RNaWdyYXRpb25TdWJ0YXNrc2AgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGlu
ZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RNaWdyYXRpb25TdWJ0
YXNrc2AKIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tl
bi4KCg0KBQQHAgMFEgTmAQIICg0KBQQHAgMBEgTmAQkTCg0KBQQHAgMDEgTmARYXCg0KBQQH
AgMIEgTmARhAChAKCAQHAgMInAgAEgTmARk/CtkBCgQEBwIEEgTrAQI9GsoBIE9wdGlvbmFs
LiBUaGUgZmlsdGVyIHRvIGFwcGx5LiBUaGlzIGNhbiBiZSB1c2VkIHRvIGdldCB0aGUgc3Vi
dGFza3Mgb2YgYSBzcGVjaWZpYwogdGFza3MgaW4gYSB3b3JrZmxvdywgZS5nLiBgbWlncmF0
aW9uX3Rhc2sgPSAiYWIwMTIiYCB3aGVyZSBgImFiMDEyImAgaXMgdGhlCiB0YXNrIElEIChu
b3QgdGhlIG5hbWUgaW4gdGhlIG5hbWVkIG1hcCkuCgoNCgUEBwIEBRIE6wECCAoNCgUEBwIE
ARIE6wEJDwoNCgUEBwIEAxIE6wESEwoNCgUEBwIECBIE6wEUPAoQCggEBwIECJwIABIE6wEV
OwpDCgIECBIG7wEA9gEBGjUgUmVzcG9uc2Ugb2JqZWN0IGZvciBhIGBMaXN0TWlncmF0aW9u
U3VidGFza3NgIGNhbGwuCgoLCgMECAESBO8BCCUKPgoEBAgCABIE8QECMxowIFRoZSBtaWdy
YXRpb24gc3VidGFza3MgZm9yIHRoZSBzcGVjaWZpZWQgdGFzay4KCg0KBQQIAgAEEgTxAQIK
Cg0KBQQIAgAGEgTxAQsbCg0KBQQIAgABEgTxARwuCg0KBQQIAgADEgTxATEyCpABCgQECAIB
EgT1AQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0
byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0
aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQIAgEFEgT1AQIICg0KBQQIAgEB
EgT1AQkYCg0KBQQIAgEDEgT1ARscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::CreateMigrationWorkflowRequest ===
    # Fields for CreateMigrationWorkflowRequest
    # Field: parent Type: 9 ()
    # Field: migration_workflow Type: 11 (.google.cloud.bigquery.migration.v2alpha.MigrationWorkflow)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationWorkflowRequest ===
    # Fields for GetMigrationWorkflowRequest
    # Field: name Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsRequest ===
    # Fields for ListMigrationWorkflowsRequest
    # Field: parent Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsResponse ===
    # Fields for ListMigrationWorkflowsResponse
    # Field: migration_workflows Type: 11 (.google.cloud.bigquery.migration.v2alpha.MigrationWorkflow)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::DeleteMigrationWorkflowRequest ===
    # Fields for DeleteMigrationWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::StartMigrationWorkflowRequest ===
    # Fields for StartMigrationWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationSubtaskRequest ===
    # Fields for GetMigrationSubtaskRequest
    # Field: name Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksRequest ===
    # Fields for ListMigrationSubtasksRequest
    # Field: parent Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksResponse ===
    # Fields for ListMigrationSubtasksResponse
    # Field: migration_subtasks Type: 11 (.google.cloud.bigquery.migration.v2alpha.MigrationSubtask)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::MigrationServiceClient ===
package Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::MigrationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::MigrationServiceClient

Client stub representing the remote C<MigrationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::CreateMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'CreateMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow',
    });
}

sub get_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'GetMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow',
    });
}

sub list_migration_workflows {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'ListMigrationWorkflows',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsResponse',
    });
}

sub delete_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::DeleteMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'DeleteMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub start_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::StartMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'StartMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_migration_subtask {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationSubtaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'GetMigrationSubtask',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask',
    });
}

sub list_migration_subtasks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.MigrationService',
        method         => 'ListMigrationSubtasks',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationService - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/migration_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::MigrationService;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::CreateMigrationWorkflowRequest->new({
        parent => $parent,
        migration_workflow => $migration_workflow,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::CreateMigrationWorkflowRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/migration_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::CreateMigrationWorkflowRequest

Request to create a migration workflow resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project to which this migration workflow belongs.
Example: `projects/foo/locations/bar`

=item * C<< $msg->migration_workflow() >> / C<< $msg->migration_workflow($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow>)

Required. The migration workflow to create.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationWorkflowRequest

A request to get a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be retrieved.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsRequest

A request to list previously created migration workflows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location of the migration workflows to list.
Example: `projects/123/locations/us`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be retrieved.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of migration workflows to return. The service may return
fewer than this number.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from previous `ListMigrationWorkflows` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListMigrationWorkflows`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationWorkflowsResponse

Response object for a `ListMigrationWorkflows` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->migration_workflows() >> / C<< $msg->migration_workflows($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow>)

The migration workflows for the specified project / location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::DeleteMigrationWorkflowRequest

A request to delete a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::StartMigrationWorkflowRequest

A request to start a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::GetMigrationSubtaskRequest

A request to get a previously created migration subtasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration subtask.
Example: `projects/123/locations/us/workflows/1234/subtasks/543`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to be retrieved.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksRequest

A request to list previously created migration subtasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The migration task of the subtasks to list.
Example: `projects/123/locations/us/workflows/1234`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to be retrieved.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of migration tasks to return. The service may return
fewer than this number.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from previous `ListMigrationSubtasks` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListMigrationSubtasks`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply. This can be used to get the subtasks of a specific
tasks in a workflow, e.g. `migration_task = "ab012"` where `"ab012"` is the
task ID (not the name in the named map).

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::ListMigrationSubtasksResponse

Response object for a `ListMigrationSubtasks` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->migration_subtasks() >> / C<< $msg->migration_subtasks($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask>)

The migration subtasks for the specified task.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
