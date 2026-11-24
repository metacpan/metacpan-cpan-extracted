package Google::Chromeos::Moblab::V1beta1::TestService;

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
    eval { require Google::Chromeos::Moblab::V1beta1::Resources };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2hyb21lb3MvbW9ibGFiL3YxYmV0YTEvdGVzdF9zZXJ2aWNlLnByb3RvEh5n
b29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2hyb21lb3Mv
bW9ibGFiL3YxYmV0YTEvcmVzb3VyY2VzLnByb3RvIoIBChRDcmVhdGVTZXNzaW9uUmVxdWVz
dBJGCgdzZXNzaW9uGAEgASgLMicuZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExLlNl
c3Npb25CA+BBAlIHc2Vzc2lvbhIiCgpzZXNzaW9uX2lkGAIgASgJQgPgQQFSCXNlc3Npb25J
ZCJOChFHZXRTZXNzaW9uUmVxdWVzdBI5CgRuYW1lGAEgASgJQiXgQQL6QR8KHW1vYmxhYi5n
b29nbGVhcGlzLmNvbS9TZXNzaW9uUgRuYW1lInsKFkxpc3RUZXN0RWZmb3J0c1JlcXVlc3QS
IAoJcGFnZV9zaXplGAEgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlC
A+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgDIAEoCUID4EEBUgZmaWx0ZXIirwEKF0xpc3RU
ZXN0RWZmb3J0c1Jlc3BvbnNlEk0KDHRlc3RfZWZmb3J0cxgBIAMoCzIqLmdvb2dsZS5jaHJv
bWVvcy5tb2JsYWIudjFiZXRhMS5UZXN0RWZmb3J0Ugt0ZXN0RWZmb3J0cxImCg9uZXh0X3Bh
Z2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SHQoKdG90YWxfc2l6ZRgDIAEoBVIJdG90
YWxTaXplIl8KF0NhbmNlbFRlc3RFZmZvcnRSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpB
KgooY2hyb21lb3Ntb2JsYWIuZ29vZ2xlYXBpcy5jb20vVGVzdEVmZm9ydFIEbmFtZSJnChhD
YW5jZWxUZXN0RWZmb3J0UmVzcG9uc2USSwoLdGVzdF9lZmZvcnQYASABKAsyKi5nb29nbGUu
Y2hyb21lb3MubW9ibGFiLnYxYmV0YTEuVGVzdEVmZm9ydFIKdGVzdEVmZm9ydCKWAQoXQ3Jl
YXRlVGVzdEVmZm9ydFJlcXVlc3QSUAoLdGVzdF9lZmZvcnQYASABKAsyKi5nb29nbGUuY2hy
b21lb3MubW9ibGFiLnYxYmV0YTEuVGVzdEVmZm9ydEID4EECUgp0ZXN0RWZmb3J0EikKDnRl
c3RfZWZmb3J0X2lkGAIgASgJQgPgQQFSDHRlc3RFZmZvcnRJZCJ4ChNMaXN0U2Vzc2lvbnNS
ZXF1ZXN0EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2Vu
GAIgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYAyABKAlCA+BBAVIGZmlsdGVyIqIB
ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRJDCghzZXNzaW9ucxgBIAMoCzInLmdvb2dsZS5jaHJv
bWVvcy5tb2JsYWIudjFiZXRhMS5TZXNzaW9uUghzZXNzaW9ucxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SHQoKdG90YWxfc2l6ZRgDIAEoBVIJdG90YWxTaXpl
MqsICgtUZXN0U2VydmljZRKnAQoNQ3JlYXRlU2Vzc2lvbhI0Lmdvb2dsZS5jaHJvbWVvcy5t
b2JsYWIudjFiZXRhMS5DcmVhdGVTZXNzaW9uUmVxdWVzdBonLmdvb2dsZS5jaHJvbWVvcy5t
b2JsYWIudjFiZXRhMS5TZXNzaW9uIjeC0+STAhwiES92MWJldGExL3Nlc3Npb25zOgdzZXNz
aW9u2kESc2Vzc2lvbixzZXNzaW9uX2lkEpMBCgpHZXRTZXNzaW9uEjEuZ29vZ2xlLmNocm9t
ZW9zLm1vYmxhYi52MWJldGExLkdldFNlc3Npb25SZXF1ZXN0GicuZ29vZ2xlLmNocm9tZW9z
Lm1vYmxhYi52MWJldGExLlNlc3Npb24iKYLT5JMCHBIaL3YxYmV0YTEve25hbWU9c2Vzc2lv
bnMvKn3aQQRuYW1lEpQBCgxMaXN0U2Vzc2lvbnMSMy5nb29nbGUuY2hyb21lb3MubW9ibGFi
LnYxYmV0YTEuTGlzdFNlc3Npb25zUmVxdWVzdBo0Lmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIu
djFiZXRhMS5MaXN0U2Vzc2lvbnNSZXNwb25zZSIZgtPkkwITEhEvdjFiZXRhMS9zZXNzaW9u
cxKgAQoPTGlzdFRlc3RFZmZvcnRzEjYuZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGEx
Lkxpc3RUZXN0RWZmb3J0c1JlcXVlc3QaNy5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0
YTEuTGlzdFRlc3RFZmZvcnRzUmVzcG9uc2UiHILT5JMCFhIUL3YxYmV0YTEvdGVzdEVmZm9y
dHMSvQEKEENhbmNlbFRlc3RFZmZvcnQSNy5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0
YTEuQ2FuY2VsVGVzdEVmZm9ydFJlcXVlc3QaOC5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYx
YmV0YTEuQ2FuY2VsVGVzdEVmZm9ydFJlc3BvbnNlIjaC0+STAikiJC92MWJldGExL3tuYW1l
PXRlc3RFZmZvcnRzLyp9OmNhbmNlbDoBKtpBBG5hbWUSvwEKEENyZWF0ZVRlc3RFZmZvcnQS
Ny5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuQ3JlYXRlVGVzdEVmZm9ydFJlcXVl
c3QaKi5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuVGVzdEVmZm9ydCJGgtPkkwIj
IhQvdjFiZXRhMS90ZXN0RWZmb3J0czoLdGVzdF9lZmZvcnTaQRp0ZXN0X2VmZm9ydCx0ZXN0
X2VmZm9ydF9pZBogykEdY2hyb21lb3Ntb2JsYWIuZ29vZ2xlYXBpcy5jb21CgAEKImNvbS5n
b29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTFCEFRlc3RTZXJ2aWNlUHJvdG9IAVABWkRn
b29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2Nocm9tZW9zL21vYmxhYi92
MWJldGExO21vYmxhYkqKLQoHEgUOAMUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
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
ZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgID
AxIDFQAjCgkKAgMEEgMWADgKCAoBCBIDGABbCgkKAggLEgMYAFsKCAoBCBIDGQAiCgkKAggK
EgMZACIKCAoBCBIDGgAxCgkKAggIEgMaADEKCAoBCBIDGwA7CgkKAggBEgMbADsKCAoBCBID
HAAcCgkKAggJEgMcABwKNgoCBgASBB8AVAEaKiBNYW5hZ2VzIHRlc3Qgc2VydmljZXMgZm9y
IFNhdGxhYi9Nb2JsYWIuCgoKCgMGAAESAx8IEwoKCgMGAAMSAyACRQoMCgUGAAOZCBIDIAJF
CjkKBAYAAgASBCMCKQMaKyBDcmVhdGVzIGEgc2Vzc2lvbiB0byBydW4gb24tZGVtYW5kIHRl
c3RzLgoKDAoFBgACAAESAyMGEwoMCgUGAAIAAhIDIxQoCgwKBQYAAgADEgMjMzoKDQoFBgAC
AAQSBCQEJwYKEQoJBgACAASwyrwiEgQkBCcGCgwKBQYAAgAEEgMoBEAKDwoIBgACAASbCAAS
AygEQAofCgQGAAIBEgQsAjEDGhEgR2V0cyBhIHNlc3Npb24uCgoMCgUGAAIBARIDLAYQCgwK
BQYAAgECEgMsESIKDAoFBgACAQMSAywtNAoNCgUGAAIBBBIELQQvBgoRCgkGAAIBBLDKvCIS
BC0ELwYKDAoFBgACAQQSAzAEMgoPCggGAAIBBJsIABIDMAQyCh8KBAYAAgISBDQCOAMaESBM
aXN0cyBzZXNzaW9ucy4KCgwKBQYAAgIBEgM0BhIKDAoFBgACAgISAzQTJgoMCgUGAAICAxID
NDFFCg0KBQYAAgIEEgQ1BDcGChEKCQYAAgIEsMq8IhIENQQ3BgojCgQGAAIDEgQ7AkADGhUg
TGlzdHMgdGVzdCBlZmZvcnRzLgoKDAoFBgACAwESAzsGFQoMCgUGAAIDAhIDOxYsCgwKBQYA
AgMDEgM8DyYKDQoFBgACAwQSBD0EPwYKEQoJBgACAwSwyrwiEgQ9BD8GCiYKBAYAAgQSBEMC
SgMaGCBDYW5jZWxzIGEgdGVzdCBlZmZvcnQuCgoMCgUGAAIEARIDQwYWCgwKBQYAAgQCEgND
Fy4KDAoFBgACBAMSA0QPJwoNCgUGAAIEBBIERQRIBgoRCgkGAAIEBLDKvCISBEUESAYKDAoF
BgACBAQSA0kEMgoPCggGAAIEBJsIABIDSQQyCiYKBAYAAgUSBE0CUwMaGCBDcmVhdGVzIGEg
dGVzdCBlZmZvcnQuCgoMCgUGAAIFARIDTQYWCgwKBQYAAgUCEgNNFy4KDAoFBgACBQMSA005
QwoNCgUGAAIFBBIETgRRBgoRCgkGAAIFBLDKvCISBE4EUQYKDAoFBgACBQQSA1IESAoPCggG
AAIFBJsIABIDUgRICjUKAgQAEgRXAF4BGikgUmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGlu
ZyBhIHNlc3Npb24uCgoKCgMEAAESA1cIHAovCgQEAAIAEgNZAj8aIiBSZXF1aXJlZC4gVGhl
IHNlc3Npb24gdG8gY3JlYXRlLgoKDAoFBAACAAYSA1kCCQoMCgUEAAIAARIDWQoRCgwKBQQA
AgADEgNZFBUKDAoFBAACAAgSA1kWPgoPCggEAAIACJwIABIDWRc9Cn4KBAQAAgESA10CQRpx
IE9wdGlvbmFsLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgc2Vzc2lvbiwgd2hpY2ggd2lsbCBi
ZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIHNlc3Npb24ncyByZXNvdXJjZSBu
YW1lLgoKDAoFBAACAQUSA10CCAoMCgUEAAIBARIDXQkTCgwKBQQAAgEDEgNdFhcKDAoFBAAC
AQgSA10YQAoPCggEAAIBCJwIABIDXRk/CjQKAgQBEgRhAGgBGiggUmVxdWVzdCBtZXNzYWdl
IGZvciBnZXR0aW5nIGEgc2Vzc2lvbi4KCgoKAwQBARIDYQgZCmMKBAQBAgASBGQCZwQaVSBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHNlc3Npb24gdG8gcmV0cmlldmUu
CiBGb3JtYXQ6IHNlc3Npb25zL3tzZXNzaW9ufQoKDAoFBAECAAUSA2QCCAoMCgUEAQIAARID
ZAkNCgwKBQQBAgADEgNkEBEKDQoFBAECAAgSBGQSZwMKDwoIBAECAAicCAASA2UEKgoOCgcE
AQIACJ8IEgNmBE8KcQoCBAISBGwAfAEaZSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGxpc3Rpbmcg
dGVzdCBlZmZvcnRzLgogVGVzdCBlZmZvcnRzIGFyZSBxdWVyaWVkIGluIHJldmVyc2UgY2hy
b25vbG9naWNhbCBvcmRlci4KCgoKAwQCARIDbAgeCvgBCgQEAgIAEgNxAj8a6gEgT3B0aW9u
YWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiB0ZXN0IGVmZm9ydHMgdG8gcmV0dXJuLiBUaGUg
c2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCiBJZiB1bnNwZWNp
ZmllZCwgYXQgbW9zdCA1MCB0ZXN0IGVmZm9ydHMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBt
YXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNl
ZCB0byAxMDAwLgoKDAoFBAICAAUSA3ECBwoMCgUEAgIAARIDcQgRCgwKBQQCAgADEgNxFBUK
DAoFBAICAAgSA3EWPgoPCggEAgIACJwIABIDcRc9CoYBCgQEAgIBEgN1AkEaeSBPcHRpb25h
bC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RUZXN0RWZm
b3J0c2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBw
YWdlLgoKDAoFBAICAQUSA3UCCAoMCgUEAgIBARIDdQkTCgwKBQQCAgEDEgN1FhcKDAoFBAIC
AQgSA3UYQAoPCggEAgIBCJwIABIDdRk/CpYBCgQEAgICEgN7Aj0aiAEgT3B0aW9uYWwuIEEg
ZmlsdGVyIHN0cmluZyB0byByZXN0cmljdCB0aGUgcmVzdWx0cy4KIFRoZSBmb2xsb3dpbmcg
ZmllbGRzIGFyZSBzdXBwb3J0ZWQ6CiAgIC0gc2F0bGFiX2lkCiBGb3IgZXhhbXBsZTogInNh
dGxhYl9pZD0xMjM0NSIKCgwKBQQCAgIFEgN7AggKDAoFBAICAgESA3sJDwoMCgUEAgICAxID
exITCgwKBQQCAgIIEgN7FDwKDwoIBAICAgicCAASA3sVOwo5CgIEAxIFfwCJAQEaLCBSZXNw
b25zZSBtZXNzYWdlIGZvciBsaXN0aW5nIHRlc3QgZWZmb3J0cy4KCgoKAwQDARIDfwgfCikK
BAQDAgASBIEBAicaGyBUaGUgbGlzdCBvZiB0ZXN0IGVmZm9ydHMuCgoNCgUEAwIABBIEgQEC
CgoNCgUEAwIABhIEgQELFQoNCgUEAwIAARIEgQEWIgoNCgUEAwIAAxIEgQElJgp6CgQEAwIB
EgSFAQIdGmwgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiB0ZXN0IGVmZm9y
dHMuIElmIHRoaXMgZmllbGQKIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50
IHBhZ2VzLgoKDQoFBAMCAQUSBIUBAggKDQoFBAMCAQESBIUBCRgKDQoFBAMCAQMSBIUBGxwK
LQoEBAMCAhIEiAECFxofIFRvdGFsIG51bWJlciBvZiB0ZXN0IGVmZm9ydHMuCgoNCgUEAwIC
BRIEiAECBwoNCgUEAwICARIEiAEIEgoNCgUEAwICAxIEiAEVFgo9CgIEBBIGjAEAlQEBGi8g
UmVxdWVzdCBtZXNzYWdlIGZvciBjYW5jZWxsaW5nIGEgdGVzdCBlZmZvcnQuCgoLCgMEBAES
BIwBCB8KbgoEBAQCABIGjwEClAEEGl4gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSB0ZXN0IGVmZm9ydCB0byBjYW5jZWwuCiBGb3JtYXQ6IHRlc3RFZmZvcnRzL3t0ZXN0
X2VmZm9ydH0KCg0KBQQEAgAFEgSPAQIICg0KBQQEAgABEgSPAQkNCg0KBQQEAgADEgSPARAR
Cg8KBQQEAgAIEgaPARKUAQMKEAoIBAQCAAicCAASBJABBCoKEQoHBAQCAAifCBIGkQEEkwEF
Cj4KAgQFEgaYAQCbAQEaMCBSZXNwb25zZSBtZXNzYWdlIGZvciBjYW5jZWxsaW5nIGEgdGVz
dCBlZmZvcnQuCgoLCgMEBQESBJgBCCAKKgoEBAUCABIEmgECHRocIFRoZSBjYW5jZWxsZWQg
dGVzdCBlZmZvcnQuCgoNCgUEBQIABhIEmgECDAoNCgUEBQIAARIEmgENGAoNCgUEBQIAAxIE
mgEbHAo7CgIEBhIGngEApQEBGi0gUmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGluZyBhIHRl
c3QgZWZmb3J0LgoKCwoDBAYBEgSeAQgfCjQKBAQGAgASBKABAkYaJiBSZXF1aXJlZC4gVGhl
IHRlc3QgZWZmb3J0IHRvIGNyZWF0ZS4KCg0KBQQGAgAGEgSgAQIMCg0KBQQGAgABEgSgAQ0Y
Cg0KBQQGAgADEgSgARscCg0KBQQGAgAIEgSgAR1FChAKCAQGAgAInAgAEgSgAR5ECocBCgQE
BgIBEgSkAQJFGnkgT3B0aW9uYWwuIFRoZSBJRCB0byB1c2UgZm9yIHRoZSB0ZXN0IGVmZm9y
dCwgd2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIHRlc3Qg
ZWZmb3J0J3MgcmVzb3VyY2UgbmFtZS4KCg0KBQQGAgEFEgSkAQIICg0KBQQGAgEBEgSkAQkX
Cg0KBQQGAgEDEgSkARobCg0KBQQGAgEIEgSkARxEChAKCAQGAgEInAgAEgSkAR1DCjUKAgQH
EgaoAQC4AQEaJyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGxpc3Rpbmcgc2Vzc2lvbnMuCgoLCgME
BwESBKgBCBsK8QEKBAQHAgASBK0BAj8a4gEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJl
ciBvZiBzZXNzaW9ucyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heQogcmV0dXJuIGZld2Vy
IHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIHNlc3Npb25z
IHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMg
YWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0KBQQHAgAFEgStAQIHCg0K
BQQHAgABEgStAQgRCg0KBQQHAgADEgStARQVCg0KBQQHAgAIEgStARY+ChAKCAQHAgAInAgA
EgStARc9CoQBCgQEBwIBEgSxAQJBGnYgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2
ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0U2Vzc2lvbnNgIGNhbGwuCiBQcm92aWRlIHRoaXMg
dG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQHAgEFEgSxAQIICg0KBQQH
AgEBEgSxAQkTCg0KBQQHAgEDEgSxARYXCg0KBQQHAgEIEgSxARhAChAKCAQHAgEInAgAEgSx
ARk/CpcBCgQEBwICEgS3AQI9GogBIE9wdGlvbmFsLiBBIGZpbHRlciBzdHJpbmcgdG8gcmVz
dHJpY3QgdGhlIHJlc3VsdHMuCiBUaGUgZm9sbG93aW5nIGZpZWxkcyBhcmUgc3VwcG9ydGVk
OgogICAtIHNhdGxhYl9pZAogRm9yIGV4YW1wbGU6ICJzYXRsYWJfaWQ9MTIzNDUiCgoNCgUE
BwICBRIEtwECCAoNCgUEBwICARIEtwEJDwoNCgUEBwICAxIEtwESEwoNCgUEBwICCBIEtwEU
PAoQCggEBwICCJwIABIEtwEVOwo2CgIECBIGuwEAxQEBGiggUmVzcG9uc2UgbWVzc2FnZSBm
b3IgbGlzdGluZyBzZXNzaW9ucy4KCgsKAwQIARIEuwEIHAolCgQECAIAEgS9AQIgGhcgVGhl
IGxpc3Qgb2Ygc2Vzc2lvbnMuCgoNCgUECAIABBIEvQECCgoNCgUECAIABhIEvQELEgoNCgUE
CAIAARIEvQETGwoNCgUECAIAAxIEvQEeHwp2CgQECAIBEgTBAQIdGmggVG9rZW4gdG8gcmV0
cmlldmUgdGhlIG5leHQgcGFnZSBvZiBzZXNzaW9ucy4gSWYgdGhpcyBmaWVsZAogaXMgb21p
dHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUECAIBBRIEwQECCAoN
CgUECAIBARIEwQEJGAoNCgUECAIBAxIEwQEbHAopCgQECAICEgTEAQIXGhsgVG90YWwgbnVt
YmVyIG9mIHNlc3Npb25zLgoKDQoFBAgCAgUSBMQBAgcKDQoFBAgCAgESBMQBCBIKDQoFBAgC
AgMSBMQBFRZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest ===
    # Fields for CreateSessionRequest
    # Field: session Type: 11 (.google.chromeos.moblab.v1beta1.Session)
    # Field: session_id Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest ===
    # Fields for GetSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest ===
    # Fields for ListTestEffortsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse ===
    # Fields for ListTestEffortsResponse
    # Field: test_efforts Type: 11 (.google.chromeos.moblab.v1beta1.TestEffort)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest ===
    # Fields for CancelTestEffortRequest
    # Field: name Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse ===
    # Fields for CancelTestEffortResponse
    # Field: test_effort Type: 11 (.google.chromeos.moblab.v1beta1.TestEffort)

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest ===
    # Fields for CreateTestEffortRequest
    # Field: test_effort Type: 11 (.google.chromeos.moblab.v1beta1.TestEffort)
    # Field: test_effort_id Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest ===
    # Fields for ListSessionsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse ===
    # Fields for ListSessionsResponse
    # Field: sessions Type: 11 (.google.chromeos.moblab.v1beta1.Session)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Service Client: Google::Chromeos::Moblab::V1beta1::TestService::TestServiceClient ===
package Google::Chromeos::Moblab::V1beta1::TestService::TestServiceClient;

=pod

=head2 Service Client: Google::Chromeos::Moblab::V1beta1::TestService::TestServiceClient

Client stub representing the remote C<TestService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chromeos.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chromeos.googleapis.com:443' );

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

sub create_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::Resources::Session',
    });
}

sub get_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'GetSession',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::Resources::Session',
    });
}

sub list_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'ListSessions',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse',
    });
}

sub list_test_efforts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'ListTestEfforts',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse',
    });
}

sub cancel_test_effort {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CancelTestEffort',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse',
    });
}

sub create_test_effort {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CreateTestEffort',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Chromeos::Moblab::V1beta1::TestService - Compiled Protocol Buffers messages for google/chromeos/moblab/v1beta1/test_service.proto

=head1 SYNOPSIS

    use Google::Chromeos::Moblab::V1beta1::TestService;

    my $msg = Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest->new({
        session => $session,
        session_id => $session_id,
    });

    # Read or update a field
    my $val = $msg->session();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/chromeos/moblab/v1beta1/test_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest

Request message for creating a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::Session>)

Required. The session to create.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

Optional. The ID to use for the session, which will become the final
component of the session's resource name.

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest

Request message for getting a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the session to retrieve.
Format: sessions/{session}

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest

Request message for listing test efforts.
Test efforts are queried in reverse chronological order.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of test efforts to return. The service may
return fewer than this value.
If unspecified, at most 50 test efforts will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListTestEfforts` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter string to restrict the results.
The following fields are supported:
  - satlab_id
For example: "satlab_id=12345"

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse

Response message for listing test efforts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_efforts() >> / C<< $msg->test_efforts($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::TestEffort>)

The list of test efforts.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of test efforts. If this field
is omitted, there are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Total number of test efforts.

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest

Request message for cancelling a test effort.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the test effort to cancel.
Format: testEfforts/{test_effort}

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse

Response message for cancelling a test effort.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_effort() >> / C<< $msg->test_effort($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::TestEffort>)

The cancelled test effort.

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest

Request message for creating a test effort.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_effort() >> / C<< $msg->test_effort($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::TestEffort>)

Required. The test effort to create.

=item * C<< $msg->test_effort_id() >> / C<< $msg->test_effort_id($value) >>

Type: C<String>

Optional. The ID to use for the test effort, which will become the final
component of the test effort's resource name.

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest

Request message for listing sessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of sessions to return. The service may
return fewer than this value.
If unspecified, at most 50 sessions will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListSessions` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter string to restrict the results.
The following fields are supported:
  - satlab_id
For example: "satlab_id=12345"

=back

=head2 Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse

Response message for listing sessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sessions() >> / C<< $msg->sessions($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::Session>)

The list of sessions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of sessions. If this field
is omitted, there are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Total number of sessions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Chromeos::Moblab::V1beta1::TestService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
