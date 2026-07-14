package Google::Cloud::BigQuery::V2::RowAccessPolicy;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::BigQuery::V2::RowAccessPolicyReference };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcm93X2FjY2Vzc19wb2xpY3kucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aOmdvb2dsZS9jbG91ZC9iaWdxdWVyeS92Mi9yb3dfYWNjZXNzX3BvbGljeV9yZWZlcmVu
Y2UucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byLCAQocTGlzdFJvd0FjY2Vzc1BvbGljaWVzUmVxdWVzdBIiCgpw
cm9qZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBIiCgpkYXRhc2V0X2lkGAIgASgJQgPg
QQJSCWRhdGFzZXRJZBIeCgh0YWJsZV9pZBgDIAEoCUID4EECUgd0YWJsZUlkEh0KCnBhZ2Vf
dG9rZW4YBCABKAlSCXBhZ2VUb2tlbhIbCglwYWdlX3NpemUYBSABKAVSCHBhZ2VTaXplIqIB
Ch1MaXN0Um93QWNjZXNzUG9saWNpZXNSZXNwb25zZRJZChNyb3dfYWNjZXNzX3BvbGljaWVz
GAEgAygLMikuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlJvd0FjY2Vzc1BvbGljeVIRcm93
QWNjZXNzUG9saWNpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
IqUBChlHZXRSb3dBY2Nlc3NQb2xpY3lSZXF1ZXN0EiIKCnByb2plY3RfaWQYASABKAlCA+BB
AlIJcHJvamVjdElkEiIKCmRhdGFzZXRfaWQYAiABKAlCA+BBAlIJZGF0YXNldElkEh4KCHRh
YmxlX2lkGAMgASgJQgPgQQJSB3RhYmxlSWQSIAoJcG9saWN5X2lkGAQgASgJQgPgQQJSCHBv
bGljeUlkIuIBChxDcmVhdGVSb3dBY2Nlc3NQb2xpY3lSZXF1ZXN0EiIKCnByb2plY3RfaWQY
ASABKAlCA+BBAlIJcHJvamVjdElkEiIKCmRhdGFzZXRfaWQYAiABKAlCA+BBAlIJZGF0YXNl
dElkEh4KCHRhYmxlX2lkGAMgASgJQgPgQQJSB3RhYmxlSWQSWgoRcm93X2FjY2Vzc19wb2xp
Y3kYBCABKAsyKS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuUm93QWNjZXNzUG9saWN5QgPg
QQJSD3Jvd0FjY2Vzc1BvbGljeSKEAgocVXBkYXRlUm93QWNjZXNzUG9saWN5UmVxdWVzdBIi
Cgpwcm9qZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBIiCgpkYXRhc2V0X2lkGAIgASgJ
QgPgQQJSCWRhdGFzZXRJZBIeCgh0YWJsZV9pZBgDIAEoCUID4EECUgd0YWJsZUlkEiAKCXBv
bGljeV9pZBgEIAEoCUID4EECUghwb2xpY3lJZBJaChFyb3dfYWNjZXNzX3BvbGljeRgFIAEo
CzIpLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5Sb3dBY2Nlc3NQb2xpY3lCA+BBAlIPcm93
QWNjZXNzUG9saWN5Is0BChxEZWxldGVSb3dBY2Nlc3NQb2xpY3lSZXF1ZXN0EiIKCnByb2pl
Y3RfaWQYASABKAlCA+BBAlIJcHJvamVjdElkEiIKCmRhdGFzZXRfaWQYAiABKAlCA+BBAlIJ
ZGF0YXNldElkEh4KCHRhYmxlX2lkGAMgASgJQgPgQQJSB3RhYmxlSWQSIAoJcG9saWN5X2lk
GAQgASgJQgPgQQJSCHBvbGljeUlkEhkKBWZvcmNlGAUgASgISABSBWZvcmNliAEBQggKBl9m
b3JjZSLWAQojQmF0Y2hEZWxldGVSb3dBY2Nlc3NQb2xpY2llc1JlcXVlc3QSIgoKcHJvamVj
dF9pZBgBIAEoCUID4EECUglwcm9qZWN0SWQSIgoKZGF0YXNldF9pZBgCIAEoCUID4EECUglk
YXRhc2V0SWQSHgoIdGFibGVfaWQYAyABKAlCA+BBAlIHdGFibGVJZBIiCgpwb2xpY3lfaWRz
GAQgAygJQgPgQQJSCXBvbGljeUlkcxIZCgVmb3JjZRgFIAEoCEgAUgVmb3JjZYgBAUIICgZf
Zm9yY2UiiwMKD1Jvd0FjY2Vzc1BvbGljeRIXCgRldGFnGAEgASgJQgPgQQNSBGV0YWcSdgob
cm93X2FjY2Vzc19wb2xpY3lfcmVmZXJlbmNlGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5LnYyLlJvd0FjY2Vzc1BvbGljeVJlZmVyZW5jZUID4EECUhhyb3dBY2Nlc3NQb2xpY3lS
ZWZlcmVuY2USLgoQZmlsdGVyX3ByZWRpY2F0ZRgDIAEoCUID4EECUg9maWx0ZXJQcmVkaWNh
dGUSRAoNY3JlYXRpb25fdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IMY3JlYXRpb25UaW1lEk0KEmxhc3RfbW9kaWZpZWRfdGltZRgFIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IQbGFzdE1vZGlmaWVkVGltZRIiCghncmFudGVl
cxgGIAMoCUIG4EEE4EEBUghncmFudGVlczKQDQoWUm93QWNjZXNzUG9saWN5U2VydmljZRL0
AQoVTGlzdFJvd0FjY2Vzc1BvbGljaWVzEjYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkxp
c3RSb3dBY2Nlc3NQb2xpY2llc1JlcXVlc3QaNy5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIu
TGlzdFJvd0FjY2Vzc1BvbGljaWVzUmVzcG9uc2UiaoLT5JMCZBJiL2JpZ3F1ZXJ5L3YyL3By
b2plY3RzL3twcm9qZWN0X2lkPSp9L2RhdGFzZXRzL3tkYXRhc2V0X2lkPSp9L3RhYmxlcy97
dGFibGVfaWQ9Kn0vcm93QWNjZXNzUG9saWNpZXMS7gEKEkdldFJvd0FjY2Vzc1BvbGljeRIz
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5HZXRSb3dBY2Nlc3NQb2xpY3lSZXF1ZXN0Giku
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlJvd0FjY2Vzc1BvbGljeSJ4gtPkkwJyEnAvYmln
cXVlcnkvdjIvcHJvamVjdHMve3Byb2plY3RfaWQ9Kn0vZGF0YXNldHMve2RhdGFzZXRfaWQ9
Kn0vdGFibGVzL3t0YWJsZV9pZD0qfS9yb3dBY2Nlc3NQb2xpY2llcy97cG9saWN5X2lkPSp9
EvkBChVDcmVhdGVSb3dBY2Nlc3NQb2xpY3kSNi5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIu
Q3JlYXRlUm93QWNjZXNzUG9saWN5UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52
Mi5Sb3dBY2Nlc3NQb2xpY3kifYLT5JMCdyJiL2JpZ3F1ZXJ5L3YyL3Byb2plY3RzL3twcm9q
ZWN0X2lkPSp9L2RhdGFzZXRzL3tkYXRhc2V0X2lkPSp9L3RhYmxlcy97dGFibGVfaWQ9Kn0v
cm93QWNjZXNzUG9saWNpZXM6EXJvd19hY2Nlc3NfcG9saWN5EokCChVVcGRhdGVSb3dBY2Nl
c3NQb2xpY3kSNi5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuVXBkYXRlUm93QWNjZXNzUG9s
aWN5UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5Sb3dBY2Nlc3NQb2xpY3ki
jAGC0+STAoUBGnAvYmlncXVlcnkvdjIvcHJvamVjdHMve3Byb2plY3RfaWQ9Kn0vZGF0YXNl
dHMve2RhdGFzZXRfaWQ9Kn0vdGFibGVzL3t0YWJsZV9pZD0qfS9yb3dBY2Nlc3NQb2xpY2ll
cy97cG9saWN5X2lkPSp9OhFyb3dfYWNjZXNzX3BvbGljeRLhAQoVRGVsZXRlUm93QWNjZXNz
UG9saWN5EjYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkRlbGV0ZVJvd0FjY2Vzc1BvbGlj
eVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkieILT5JMCcipwL2JpZ3F1ZXJ5L3Yy
L3Byb2plY3RzL3twcm9qZWN0X2lkPSp9L2RhdGFzZXRzL3tkYXRhc2V0X2lkPSp9L3RhYmxl
cy97dGFibGVfaWQ9Kn0vcm93QWNjZXNzUG9saWNpZXMve3BvbGljeV9pZD0qfRLwAQocQmF0
Y2hEZWxldGVSb3dBY2Nlc3NQb2xpY2llcxI9Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5C
YXRjaERlbGV0ZVJvd0FjY2Vzc1BvbGljaWVzUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5F
bXB0eSJ5gtPkkwJzIm4vYmlncXVlcnkvdjIvcHJvamVjdHMve3Byb2plY3RfaWQ9Kn0vZGF0
YXNldHMve2RhdGFzZXRfaWQ9Kn0vdGFibGVzL3t0YWJsZV9pZD0qfS9yb3dBY2Nlc3NQb2xp
Y2llczpiYXRjaERlbGV0ZToBKhquAcpBF2JpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29t0kGQAWh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvYmlncXVlcnksaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLnJlYWQtb25seUJzChxjb20uZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyQhRSb3dBY2Nlc3NQb2xpY3lQcm90b1ABWjtjbG91ZC5nb29nbGUuY29t
L2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYkr5SwoHEgUOAI0C
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQBECgkKAgMEEgMWACUKCQoCAwUS
AxcAKQoICgEIEgMZAFIKCQoCCAsSAxkAUgoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMb
ADUKCQoCCAgSAxsANQoICgEIEgMcADUKCQoCCAESAxwANQo/CgIGABIEHwBXARozIFNlcnZp
Y2UgZm9yIGludGVyYWN0aW5nIHdpdGggcm93IGFjY2VzcyBwb2xpY2llcy4KCgoKAwYAARID
HwgeCgoKAwYAAxIDIAI/CgwKBQYAA5kIEgMgAj8KCwoDBgADEgQhAiRBCg0KBQYAA5oIEgQh
AiRBCkUKBAYAAgASBCcCLAMaNyBMaXN0cyBhbGwgcm93IGFjY2VzcyBwb2xpY2llcyBvbiB0
aGUgc3BlY2lmaWVkIHRhYmxlLgoKDAoFBgACAAESAycGGwoMCgUGAAIAAhIDJxw4CgwKBQYA
AgADEgMoDywKDQoFBgACAAQSBCkEKwYKEQoJBgACAASwyrwiEgQpBCsGCkIKBAYAAgESBC8C
MwMaNCBHZXRzIHRoZSBzcGVjaWZpZWQgcm93IGFjY2VzcyBwb2xpY3kgYnkgcG9saWN5IElE
LgoKDAoFBgACAQESAy8GGAoMCgUGAAIBAhIDLxkyCgwKBQYAAgEDEgMvPUwKDQoFBgACAQQS
BDAEMgYKEQoJBgACAQSwyrwiEgQwBDIGCiwKBAYAAgISBDYCPAMaHiBDcmVhdGVzIGEgcm93
IGFjY2VzcyBwb2xpY3kuCgoMCgUGAAICARIDNgYbCgwKBQYAAgICEgM2HDgKDAoFBgACAgMS
AzcPHgoNCgUGAAICBBIEOAQ7BgoRCgkGAAICBLDKvCISBDgEOwYKLAoEBgACAxIEPwJFAxoe
IFVwZGF0ZXMgYSByb3cgYWNjZXNzIHBvbGljeS4KCgwKBQYAAgMBEgM/BhsKDAoFBgACAwIS
Az8cOAoMCgUGAAIDAxIDQA8eCg0KBQYAAgMEEgRBBEQGChEKCQYAAgMEsMq8IhIEQQREBgos
CgQGAAIEEgRIAk0DGh4gRGVsZXRlcyBhIHJvdyBhY2Nlc3MgcG9saWN5LgoKDAoFBgACBAES
A0gGGwoMCgUGAAIEAhIDSBw4CgwKBQYAAgQDEgNJDyQKDQoFBgACBAQSBEoETAYKEQoJBgAC
BASwyrwiEgRKBEwGCjUKBAYAAgUSBFACVgMaJyBEZWxldGVzIHByb3ZpZGVkIHJvdyBhY2Nl
c3MgcG9saWNpZXMuCgoMCgUGAAIFARIDUAYiCgwKBQYAAgUCEgNQI0YKDAoFBgACBQMSA1EP
JAoNCgUGAAIFBBIEUgRVBgoRCgkGAAIFBLDKvCISBFIEVQYKQwoCBAASBFoAawEaNyBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIHRoZSBMaXN0Um93QWNjZXNzUG9saWNpZXMgbWV0aG9kLgoKCgoD
BAABEgNaCCQKRwoEBAACABIDXAJBGjogUmVxdWlyZWQuIFByb2plY3QgSUQgb2YgdGhlIHJv
dyBhY2Nlc3MgcG9saWNpZXMgdG8gbGlzdC4KCgwKBQQAAgAFEgNcAggKDAoFBAACAAESA1wJ
EwoMCgUEAAIAAxIDXBYXCgwKBQQAAgAIEgNcGEAKDwoIBAACAAicCAASA1wZPwpDCgQEAAIB
EgNfAkEaNiBSZXF1aXJlZC4gRGF0YXNldCBJRCBvZiByb3cgYWNjZXNzIHBvbGljaWVzIHRv
IGxpc3QuCgoMCgUEAAIBBRIDXwIICgwKBQQAAgEBEgNfCRMKDAoFBAACAQMSA18WFwoMCgUE
AAIBCBIDXxhACg8KCAQAAgEInAgAEgNfGT8KSwoEBAACAhIDYgI/Gj4gUmVxdWlyZWQuIFRh
YmxlIElEIG9mIHRoZSB0YWJsZSB0byBsaXN0IHJvdyBhY2Nlc3MgcG9saWNpZXMuCgoMCgUE
AAICBRIDYgIICgwKBQQAAgIBEgNiCREKDAoFBAACAgMSA2IUFQoMCgUEAAICCBIDYhY+Cg8K
CAQAAgIInAgAEgNiFz0KXQoEBAACAxIDZgIYGlAgUGFnZSB0b2tlbiwgcmV0dXJuZWQgYnkg
YSBwcmV2aW91cyBjYWxsLCB0byByZXF1ZXN0IHRoZSBuZXh0IHBhZ2Ugb2YKIHJlc3VsdHMu
CgoMCgUEAAIDBRIDZgIICgwKBQQAAgMBEgNmCRMKDAoFBAACAwMSA2YWFwqWAQoEBAACBBID
agIWGogBIFRoZSBtYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBpbiBhIHNp
bmdsZSByZXNwb25zZSBwYWdlLiBMZXZlcmFnZQogdGhlIHBhZ2UgdG9rZW5zIHRvIGl0ZXJh
dGUgdGhyb3VnaCB0aGUgZW50aXJlIGNvbGxlY3Rpb24uCgoMCgUEAAIEBRIDagIHCgwKBQQA
AgQBEgNqCBEKDAoFBAACBAMSA2oUFQpECgIEARIEbgB0ARo4IFJlc3BvbnNlIG1lc3NhZ2Ug
Zm9yIHRoZSBMaXN0Um93QWNjZXNzUG9saWNpZXMgbWV0aG9kLgoKCgoDBAEBEgNuCCUKOgoE
BAECABIDcAIzGi0gUm93IGFjY2VzcyBwb2xpY2llcyBvbiB0aGUgcmVxdWVzdGVkIHRhYmxl
LgoKDAoFBAECAAQSA3ACCgoMCgUEAQIABhIDcAsaCgwKBQQBAgABEgNwGy4KDAoFBAECAAMS
A3AxMgo7CgQEAQIBEgNzAh0aLiBBIHRva2VuIHRvIHJlcXVlc3QgdGhlIG5leHQgcGFnZSBv
ZiByZXN1bHRzLgoKDAoFBAECAQUSA3MCCAoMCgUEAQIBARIDcwkYCgwKBQQBAgEDEgNzGxwK
QQoCBAISBXcAgwEBGjQgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgR2V0Um93QWNjZXNzUG9s
aWN5IG1ldGhvZC4KCgoKAwQCARIDdwghCk4KBAQCAgASA3kCQRpBIFJlcXVpcmVkLiBQcm9q
ZWN0IElEIG9mIHRoZSB0YWJsZSB0byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDAoF
BAICAAUSA3kCCAoMCgUEAgIAARIDeQkTCgwKBQQCAgADEgN5FhcKDAoFBAICAAgSA3kYQAoP
CggEAgIACJwIABIDeRk/Ck4KBAQCAgESA3wCQRpBIFJlcXVpcmVkLiBEYXRhc2V0IElEIG9m
IHRoZSB0YWJsZSB0byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDAoFBAICAQUSA3wC
CAoMCgUEAgIBARIDfAkTCgwKBQQCAgEDEgN8FhcKDAoFBAICAQgSA3wYQAoPCggEAgIBCJwI
ABIDfBk/CkwKBAQCAgISA38CPxo/IFJlcXVpcmVkLiBUYWJsZSBJRCBvZiB0aGUgdGFibGUg
dG8gZ2V0IHRoZSByb3cgYWNjZXNzIHBvbGljeS4KCgwKBQQCAgIFEgN/AggKDAoFBAICAgES
A38JEQoMCgUEAgICAxIDfxQVCgwKBQQCAgIIEgN/Fj4KDwoIBAICAgicCAASA38XPQo9CgQE
AgIDEgSCAQJAGi8gUmVxdWlyZWQuIFBvbGljeSBJRCBvZiB0aGUgcm93IGFjY2VzcyBwb2xp
Y3kuCgoNCgUEAgIDBRIEggECCAoNCgUEAgIDARIEggEJEgoNCgUEAgIDAxIEggEVFgoNCgUE
AgIDCBIEggEXPwoQCggEAgIDCJwIABIEggEYPgpFCgIEAxIGhgEAkwEBGjcgUmVxdWVzdCBt
ZXNzYWdlIGZvciB0aGUgQ3JlYXRlUm93QWNjZXNzUG9saWN5IG1ldGhvZC4KCgsKAwQDARIE
hgEIJApPCgQEAwIAEgSIAQJBGkEgUmVxdWlyZWQuIFByb2plY3QgSUQgb2YgdGhlIHRhYmxl
IHRvIGdldCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEAwIABRIEiAECCAoNCgUEAwIA
ARIEiAEJEwoNCgUEAwIAAxIEiAEWFwoNCgUEAwIACBIEiAEYQAoQCggEAwIACJwIABIEiAEZ
PwpPCgQEAwIBEgSLAQJBGkEgUmVxdWlyZWQuIERhdGFzZXQgSUQgb2YgdGhlIHRhYmxlIHRv
IGdldCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEAwIBBRIEiwECCAoNCgUEAwIBARIE
iwEJEwoNCgUEAwIBAxIEiwEWFwoNCgUEAwIBCBIEiwEYQAoQCggEAwIBCJwIABIEiwEZPwpN
CgQEAwICEgSOAQI/Gj8gUmVxdWlyZWQuIFRhYmxlIElEIG9mIHRoZSB0YWJsZSB0byBnZXQg
dGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAMCAgUSBI4BAggKDQoFBAMCAgESBI4BCREK
DQoFBAMCAgMSBI4BFBUKDQoFBAMCAggSBI4BFj4KEAoIBAMCAgicCAASBI4BFz0KPAoEBAMC
AxIGkQECkgEvGiwgUmVxdWlyZWQuIFRoZSByb3cgYWNjZXNzIHBvbGljeSB0byBjcmVhdGUu
CgoNCgUEAwIDBhIEkQECEQoNCgUEAwIDARIEkQESIwoNCgUEAwIDAxIEkQEmJwoNCgUEAwID
CBIEkgEGLgoQCggEAwIDCJwIABIEkgEHLQpFCgIEBBIGlgEApgEBGjcgUmVxdWVzdCBtZXNz
YWdlIGZvciB0aGUgVXBkYXRlUm93QWNjZXNzUG9saWN5IG1ldGhvZC4KCgsKAwQEARIElgEI
JApPCgQEBAIAEgSYAQJBGkEgUmVxdWlyZWQuIFByb2plY3QgSUQgb2YgdGhlIHRhYmxlIHRv
IGdldCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEBAIABRIEmAECCAoNCgUEBAIAARIE
mAEJEwoNCgUEBAIAAxIEmAEWFwoNCgUEBAIACBIEmAEYQAoQCggEBAIACJwIABIEmAEZPwpP
CgQEBAIBEgSbAQJBGkEgUmVxdWlyZWQuIERhdGFzZXQgSUQgb2YgdGhlIHRhYmxlIHRvIGdl
dCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEBAIBBRIEmwECCAoNCgUEBAIBARIEmwEJ
EwoNCgUEBAIBAxIEmwEWFwoNCgUEBAIBCBIEmwEYQAoQCggEBAIBCJwIABIEmwEZPwpNCgQE
BAICEgSeAQI/Gj8gUmVxdWlyZWQuIFRhYmxlIElEIG9mIHRoZSB0YWJsZSB0byBnZXQgdGhl
IHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAQCAgUSBJ4BAggKDQoFBAQCAgESBJ4BCREKDQoF
BAQCAgMSBJ4BFBUKDQoFBAQCAggSBJ4BFj4KEAoIBAQCAgicCAASBJ4BFz0KPQoEBAQCAxIE
oQECQBovIFJlcXVpcmVkLiBQb2xpY3kgSUQgb2YgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoK
DQoFBAQCAwUSBKEBAggKDQoFBAQCAwESBKEBCRIKDQoFBAQCAwMSBKEBFRYKDQoFBAQCAwgS
BKEBFz8KEAoIBAQCAwicCAASBKEBGD4KPAoEBAQCBBIGpAECpQEvGiwgUmVxdWlyZWQuIFRo
ZSByb3cgYWNjZXNzIHBvbGljeSB0byB1cGRhdGUuCgoNCgUEBAIEBhIEpAECEQoNCgUEBAIE
ARIEpAESIwoNCgUEBAIEAxIEpAEmJwoNCgUEBAIECBIEpQEGLgoQCggEBAIECJwIABIEpQEH
LQpFCgIEBRIGqQEAugEBGjcgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgRGVsZXRlUm93QWNj
ZXNzUG9saWN5IG1ldGhvZC4KCgsKAwQFARIEqQEIJApSCgQEBQIAEgSrAQJBGkQgUmVxdWly
ZWQuIFByb2plY3QgSUQgb2YgdGhlIHRhYmxlIHRvIGRlbGV0ZSB0aGUgcm93IGFjY2VzcyBw
b2xpY3kuCgoNCgUEBQIABRIEqwECCAoNCgUEBQIAARIEqwEJEwoNCgUEBQIAAxIEqwEWFwoN
CgUEBQIACBIEqwEYQAoQCggEBQIACJwIABIEqwEZPwpSCgQEBQIBEgSuAQJBGkQgUmVxdWly
ZWQuIERhdGFzZXQgSUQgb2YgdGhlIHRhYmxlIHRvIGRlbGV0ZSB0aGUgcm93IGFjY2VzcyBw
b2xpY3kuCgoNCgUEBQIBBRIErgECCAoNCgUEBQIBARIErgEJEwoNCgUEBQIBAxIErgEWFwoN
CgUEBQIBCBIErgEYQAoQCggEBQIBCJwIABIErgEZPwpQCgQEBQICEgSxAQI/GkIgUmVxdWly
ZWQuIFRhYmxlIElEIG9mIHRoZSB0YWJsZSB0byBkZWxldGUgdGhlIHJvdyBhY2Nlc3MgcG9s
aWN5LgoKDQoFBAUCAgUSBLEBAggKDQoFBAUCAgESBLEBCREKDQoFBAUCAgMSBLEBFBUKDQoF
BAUCAggSBLEBFj4KEAoIBAUCAgicCAASBLEBFz0KPQoEBAUCAxIEtAECQBovIFJlcXVpcmVk
LiBQb2xpY3kgSUQgb2YgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAUCAwUSBLQBAggK
DQoFBAUCAwESBLQBCRIKDQoFBAUCAwMSBLQBFRYKDQoFBAUCAwgSBLQBFz8KEAoIBAUCAwic
CAASBLQBGD4KtAEKBAQFAgQSBLkBAhoapQEgSWYgc2V0IHRvIHRydWUsIGl0IGRlbGV0ZXMg
dGhlIHJvdyBhY2Nlc3MgcG9saWN5IGV2ZW4gaWYgaXQncyB0aGUgbGFzdCByb3cKIGFjY2Vz
cyBwb2xpY3kgb24gdGhlIHRhYmxlIGFuZCB0aGUgZGVsZXRpb24gd2lsbCB3aWRlbiB0aGUg
YWNjZXNzIHJhdGhlcgogbmFycm93aW5nIGl0LgoKDQoFBAUCBAQSBLkBAgoKDQoFBAUCBAUS
BLkBCw8KDQoFBAUCBAESBLkBEBUKDQoFBAUCBAMSBLkBGBkKUwoCBAYSBr0BAM4BARpFIFJl
cXVlc3QgbWVzc2FnZSBmb3IgdGhlIEJhdGNoRGVsZXRlUm93QWNjZXNzUG9saWNpZXNSZXF1
ZXN0IG1ldGhvZC4KCgsKAwQGARIEvQEIKwpUCgQEBgIAEgS/AQJBGkYgUmVxdWlyZWQuIFBy
b2plY3QgSUQgb2YgdGhlIHRhYmxlIHRvIGRlbGV0ZSB0aGUgcm93IGFjY2VzcyBwb2xpY2ll
cy4KCg0KBQQGAgAFEgS/AQIICg0KBQQGAgABEgS/AQkTCg0KBQQGAgADEgS/ARYXCg0KBQQG
AgAIEgS/ARhAChAKCAQGAgAInAgAEgS/ARk/ClQKBAQGAgESBMIBAkEaRiBSZXF1aXJlZC4g
RGF0YXNldCBJRCBvZiB0aGUgdGFibGUgdG8gZGVsZXRlIHRoZSByb3cgYWNjZXNzIHBvbGlj
aWVzLgoKDQoFBAYCAQUSBMIBAggKDQoFBAYCAQESBMIBCRMKDQoFBAYCAQMSBMIBFhcKDQoF
BAYCAQgSBMIBGEAKEAoIBAYCAQicCAASBMIBGT8KUgoEBAYCAhIExQECPxpEIFJlcXVpcmVk
LiBUYWJsZSBJRCBvZiB0aGUgdGFibGUgdG8gZGVsZXRlIHRoZSByb3cgYWNjZXNzIHBvbGlj
aWVzLgoKDQoFBAYCAgUSBMUBAggKDQoFBAYCAgESBMUBCREKDQoFBAYCAgMSBMUBFBUKDQoF
BAYCAggSBMUBFj4KEAoIBAYCAgicCAASBMUBFz0KQAoEBAYCAxIEyAECShoyIFJlcXVpcmVk
LiBQb2xpY3kgSURzIG9mIHRoZSByb3cgYWNjZXNzIHBvbGljaWVzLgoKDQoFBAYCAwQSBMgB
AgoKDQoFBAYCAwUSBMgBCxEKDQoFBAYCAwESBMgBEhwKDQoFBAYCAwMSBMgBHyAKDQoFBAYC
AwgSBMgBIUkKEAoIBAYCAwicCAASBMgBIkgKtAEKBAQGAgQSBM0BAhoapQEgSWYgc2V0IHRv
IHRydWUsIGl0IGRlbGV0ZXMgdGhlIHJvdyBhY2Nlc3MgcG9saWN5IGV2ZW4gaWYgaXQncyB0
aGUgbGFzdCByb3cKIGFjY2VzcyBwb2xpY3kgb24gdGhlIHRhYmxlIGFuZCB0aGUgZGVsZXRp
b24gd2lsbCB3aWRlbiB0aGUgYWNjZXNzIHJhdGhlcgogbmFycm93aW5nIGl0LgoKDQoFBAYC
BAQSBM0BAgoKDQoFBAYCBAUSBM0BCw8KDQoFBAYCBAESBM0BEBUKDQoFBAYCBAMSBM0BGBkK
rwEKAgQHEgbTAQCNAgEaoAEgUmVwcmVzZW50cyBhY2Nlc3Mgb24gYSBzdWJzZXQgb2Ygcm93
cyBvbiB0aGUgc3BlY2lmaWVkIHRhYmxlLCBkZWZpbmVkIGJ5IGl0cwogZmlsdGVyIHByZWRp
Y2F0ZS4gQWNjZXNzIHRvIHRoZSBzdWJzZXQgb2Ygcm93cyBpcyBjb250cm9sbGVkIGJ5IGl0
cyBJQU0KIHBvbGljeS4KCgsKAwQHARIE0wEIFwo1CgQEBwIAEgTVAQI+GicgT3V0cHV0IG9u
bHkuIEEgaGFzaCBvZiB0aGlzIHJlc291cmNlLgoKDQoFBAcCAAUSBNUBAggKDQoFBAcCAAES
BNUBCQ0KDQoFBAcCAAMSBNUBEBEKDQoFBAcCAAgSBNUBEj0KEAoIBAcCAAicCAASBNUBEzwK
UgoEBAcCARIG2AEC2QEvGkIgUmVxdWlyZWQuIFJlZmVyZW5jZSBkZXNjcmliaW5nIHRoZSBJ
RCBvZiB0aGlzIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAcCAQYSBNgBAhoKDQoFBAcCAQES
BNgBGzYKDQoFBAcCAQMSBNgBOToKDQoFBAcCAQgSBNkBBi4KEAoIBAcCAQicCAASBNkBBy0K
swMKBAQHAgISBOUBAkcapAMgUmVxdWlyZWQuIEEgU1FMIGJvb2xlYW4gZXhwcmVzc2lvbiB0
aGF0IHJlcHJlc2VudHMgdGhlIHJvd3MgZGVmaW5lZCBieSB0aGlzCiByb3cgYWNjZXNzIHBv
bGljeSwgc2ltaWxhciB0byB0aGUgYm9vbGVhbiBleHByZXNzaW9uIGluIGEgV0hFUkUgY2xh
dXNlIG9mIGEKIFNFTEVDVCBxdWVyeSBvbiBhIHRhYmxlLgogUmVmZXJlbmNlcyB0byBvdGhl
ciB0YWJsZXMsIHJvdXRpbmVzLCBhbmQgdGVtcG9yYXJ5IGZ1bmN0aW9ucyBhcmUgbm90CiBz
dXBwb3J0ZWQuCgogRXhhbXBsZXM6IHJlZ2lvbj0iRVUiCiAgICAgICAgICAgZGF0ZV9maWVs
ZCA9IENBU1QoJzIwMTktOS0yNycgYXMgREFURSkKICAgICAgICAgICBudWxsYWJsZV9maWVs
ZCBpcyBub3QgTlVMTAogICAgICAgICAgIG51bWVyaWNfZmllbGQgQkVUV0VFTiAxLjAgQU5E
IDUuMAoKDQoFBAcCAgUSBOUBAggKDQoFBAcCAgESBOUBCRkKDQoFBAcCAgMSBOUBHB0KDQoF
BAcCAggSBOUBHkYKEAoIBAcCAgicCAASBOUBH0UKcgoEBAcCAxIG6QEC6gEyGmIgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhpcyByb3cgYWNjZXNzIHBvbGljeSB3YXMgY3JlYXRl
ZCwgaW4KIG1pbGxpc2Vjb25kcyBzaW5jZSB0aGUgZXBvY2guCgoNCgUEBwIDBhIE6QECGwoN
CgUEBwIDARIE6QEcKQoNCgUEBwIDAxIE6QEsLQoNCgUEBwIDCBIE6gEGMQoQCggEBwIDCJwI
ABIE6gEHMAp4CgQEBwIEEgbuAQLvATIaaCBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0
aGlzIHJvdyBhY2Nlc3MgcG9saWN5IHdhcyBsYXN0IG1vZGlmaWVkLCBpbgogbWlsbGlzZWNv
bmRzIHNpbmNlIHRoZSBlcG9jaC4KCg0KBQQHAgQGEgTuAQIbCg0KBQQHAgQBEgTuARwuCg0K
BQQHAgQDEgTuATEyCg0KBQQHAgQIEgTvAQYxChAKCAQHAgQInAgAEgTvAQcwCtQJCgQEBwIF
EgaJAgKMAgQawwkgT3B0aW9uYWwuIElucHV0IG9ubHkuIFRoZSBvcHRpb25hbCBsaXN0IG9m
IGlhbV9tZW1iZXIgdXNlcnMgb3IgZ3JvdXBzIHRoYXQKIHNwZWNpZmllcyB0aGUgaW5pdGlh
bCBtZW1iZXJzIHRoYXQgdGhlIHJvdy1sZXZlbCBhY2Nlc3MgcG9saWN5IHNob3VsZCBiZQog
Y3JlYXRlZCB3aXRoLgoKIGdyYW50ZWVzIHR5cGVzOgoKIC0gInVzZXI6YWxpY2VAZXhhbXBs
ZS5jb20iOiBBbiBlbWFpbCBhZGRyZXNzIHRoYXQgcmVwcmVzZW50cyBhIHNwZWNpZmljCiBH
b29nbGUgYWNjb3VudC4KIC0gInNlcnZpY2VBY2NvdW50Om15LW90aGVyLWFwcEBhcHBzcG90
LmdzZXJ2aWNlYWNjb3VudC5jb20iOiBBbiBlbWFpbAogYWRkcmVzcyB0aGF0IHJlcHJlc2Vu
dHMgYSBzZXJ2aWNlIGFjY291bnQuCiAtICJncm91cDphZG1pbnNAZXhhbXBsZS5jb20iOiBB
biBlbWFpbCBhZGRyZXNzIHRoYXQgcmVwcmVzZW50cyBhIEdvb2dsZQogZ3JvdXAuCiAtICJk
b21haW46ZXhhbXBsZS5jb20iOlRoZSBHb29nbGUgV29ya3NwYWNlIGRvbWFpbiAocHJpbWFy
eSkgdGhhdAogcmVwcmVzZW50cyBhbGwgdGhlIHVzZXJzIG9mIHRoYXQgZG9tYWluLgogLSAi
YWxsQXV0aGVudGljYXRlZFVzZXJzIjogQSBzcGVjaWFsIGlkZW50aWZpZXIgdGhhdCByZXBy
ZXNlbnRzIGFsbCBzZXJ2aWNlCiBhY2NvdW50cyBhbmQgYWxsIHVzZXJzIG9uIHRoZSBpbnRl
cm5ldCB3aG8gaGF2ZSBhdXRoZW50aWNhdGVkIHdpdGggYSBHb29nbGUKIEFjY291bnQuIFRo
aXMgaWRlbnRpZmllciBpbmNsdWRlcyBhY2NvdW50cyB0aGF0IGFyZW4ndCBjb25uZWN0ZWQg
dG8gYQogR29vZ2xlIFdvcmtzcGFjZSBvciBDbG91ZCBJZGVudGl0eSBkb21haW4sIHN1Y2gg
YXMgcGVyc29uYWwgR21haWwgYWNjb3VudHMuCiBVc2VycyB3aG8gYXJlbid0IGF1dGhlbnRp
Y2F0ZWQsIHN1Y2ggYXMgYW5vbnltb3VzIHZpc2l0b3JzLCBhcmVuJ3QKIGluY2x1ZGVkLgog
LSAiYWxsVXNlcnMiOkEgc3BlY2lhbCBpZGVudGlmaWVyIHRoYXQgcmVwcmVzZW50cyBhbnlv
bmUgd2hvIGlzIG9uCiB0aGUgaW50ZXJuZXQsIGluY2x1ZGluZyBhdXRoZW50aWNhdGVkIGFu
ZCB1bmF1dGhlbnRpY2F0ZWQgdXNlcnMuIEJlY2F1c2UKIEJpZ1F1ZXJ5IHJlcXVpcmVzIGF1
dGhlbnRpY2F0aW9uIGJlZm9yZSBhIHVzZXIgY2FuIGFjY2VzcyB0aGUgc2VydmljZSwKIGFs
bFVzZXJzIGluY2x1ZGVzIG9ubHkgYXV0aGVudGljYXRlZCB1c2Vycy4KCg0KBQQHAgUEEgSJ
AgIKCg0KBQQHAgUFEgSJAgsRCg0KBQQHAgUBEgSJAhIaCg0KBQQHAgUDEgSJAh0eCg8KBQQH
AgUIEgaJAh+MAgMKEAoIBAcCBQicCAASBIoCBCwKEAoIBAcCBQicCAESBIsCBCpiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest ===
    # Fields for ListRowAccessPoliciesRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse ===
    # Fields for ListRowAccessPoliciesResponse
    # Field: row_access_policies Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::GetRowAccessPolicyRequest ===
    # Fields for GetRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest ===
    # Fields for CreateRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: row_access_policy Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest ===
    # Fields for UpdateRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: row_access_policy Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest ===
    # Fields for DeleteRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest ===
    # Fields for BatchDeleteRowAccessPoliciesRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_ids Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicy ===
    # Fields for RowAccessPolicy
    # Field: etag Type: 9 ()
    # Field: row_access_policy_reference Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicyReference)
    # Field: filter_predicate Type: 9 ()
    # Field: creation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_modified_time Type: 11 (.google.protobuf.Timestamp)
    # Field: grantees Type: 9 ()

# === Service Client: Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicyServiceClient ===
package Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicyServiceClient;

=pod

=head1 NAME

Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicyServiceClient - Client stub representing the remote RowAccessPolicyService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head2 credentials

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

sub list_row_access_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'ListRowAccessPolicies',
        request        => $req,
        response_class => 'Google::Cloud::BigQuery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse',
    });
}

sub get_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::GetRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'GetRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub create_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'CreateRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub update_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'UpdateRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::BigQuery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub delete_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'DeleteRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub batch_delete_row_access_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::BigQuery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'BatchDeleteRowAccessPolicies',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;
