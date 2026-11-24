package Google::Cloud::Bigquery::V2::RowAccessPolicy;

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
    eval { require Google::Cloud::Bigquery::V2::RowAccessPolicyReference };
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
L2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYkrJUwoHEgUOALMC
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
ADUKCQoCCAgSAxsANQoICgEIEgMcADUKCQoCCAESAxwANQo/CgIGABIEHwB9ARozIFNlcnZp
Y2UgZm9yIGludGVyYWN0aW5nIHdpdGggcm93IGFjY2VzcyBwb2xpY2llcy4KCgoKAwYAARID
HwgeCgoKAwYAAxIDIAI/CgwKBQYAA5kIEgMgAj8KCwoDBgADEgQhAiRBCg0KBQYAA5oIEgQh
AiRBCqQBCgQGAAIAEgQrAjADGpUBIExpc3RzIGFsbCByb3cgYWNjZXNzIHBvbGljaWVzIG9u
IHRoZSBzcGVjaWZpZWQgdGFibGUuCgogIyBJQU0gUGVybWlzc2lvbnMKCiBSZXF1aXJlcyB0
aGUgYGJpZ3F1ZXJ5LnJvd0FjY2Vzc1BvbGljaWVzLmxpc3RgIHBlcm1pc3Npb24gb24gdGhl
IHRhYmxlLgoKDAoFBgACAAESAysGGwoMCgUGAAIAAhIDKxw4CgwKBQYAAgADEgMsDywKDQoF
BgACAAQSBC0ELwYKEQoJBgACAASwyrwiEgQtBC8GCqABCgQGAAIBEgQ3AjsDGpEBIEdldHMg
dGhlIHNwZWNpZmllZCByb3cgYWNjZXNzIHBvbGljeSBieSBwb2xpY3kgSUQuCgogIyBJQU0g
UGVybWlzc2lvbnMKCiBSZXF1aXJlcyB0aGUgYGJpZ3F1ZXJ5LnJvd0FjY2Vzc1BvbGljaWVz
LmdldGAgcGVybWlzc2lvbiBvbiB0aGUgdGFibGUuCgoMCgUGAAIBARIDNwYYCgwKBQYAAgEC
EgM3GTIKDAoFBgACAQMSAzc9TAoNCgUGAAIBBBIEOAQ6BgoRCgkGAAIBBLDKvCISBDgEOgYK
7wEKBAYAAgISBEYCTAMa4AEgQ3JlYXRlcyBhIHJvdyBhY2Nlc3MgcG9saWN5LgoKICMgSUFN
IFBlcm1pc3Npb25zCgogUmVxdWlyZXMgdGhlIGZvbGxvd2luZyBJQU0gcGVybWlzc2lvbihz
KSBvbiB0aGUgdGFibGU6CgogIC0gYGJpZ3F1ZXJ5LnJvd0FjY2Vzc1BvbGljaWVzLmNyZWF0
ZWAKICAtIGBiaWdxdWVyeS5yb3dBY2Nlc3NQb2xpY2llcy5zZXRJYW1Qb2xpY3lgCiAgLSBg
YmlncXVlcnkudGFibGVzLmdldERhdGFgCgoMCgUGAAICARIDRgYbCgwKBQYAAgICEgNGHDgK
DAoFBgACAgMSA0cPHgoNCgUGAAICBBIESARLBgoRCgkGAAICBLDKvCISBEgESwYK7wEKBAYA
AgMSBFcCXQMa4AEgVXBkYXRlcyBhIHJvdyBhY2Nlc3MgcG9saWN5LgoKICMgSUFNIFBlcm1p
c3Npb25zCgogUmVxdWlyZXMgdGhlIGZvbGxvd2luZyBJQU0gcGVybWlzc2lvbihzKSBvbiB0
aGUgdGFibGU6CgogIC0gYGJpZ3F1ZXJ5LnJvd0FjY2Vzc1BvbGljaWVzLnVwZGF0ZWAKICAt
IGBiaWdxdWVyeS5yb3dBY2Nlc3NQb2xpY2llcy5zZXRJYW1Qb2xpY3lgCiAgLSBgYmlncXVl
cnkudGFibGVzLmdldERhdGFgCgoMCgUGAAIDARIDVwYbCgwKBQYAAgMCEgNXHDgKDAoFBgAC
AwMSA1gPHgoNCgUGAAIDBBIEWQRcBgoRCgkGAAIDBLDKvCISBFkEXAYK0QEKBAYAAgQSBGcC
bAMawgEgRGVsZXRlcyBhIHJvdyBhY2Nlc3MgcG9saWN5LgoKICMgSUFNIFBlcm1pc3Npb25z
CgogUmVxdWlyZXMgdGhlIGZvbGxvd2luZyBJQU0gcGVybWlzc2lvbihzKSBvbiB0aGUgdGFi
bGU6CgogIC0gYGJpZ3F1ZXJ5LnJvd0FjY2Vzc1BvbGljaWVzLmRlbGV0ZWAKICAtIGBiaWdx
dWVyeS5yb3dBY2Nlc3NQb2xpY2llcy5zZXRJYW1Qb2xpY3lgCgoMCgUGAAIEARIDZwYbCgwK
BQYAAgQCEgNnHDgKDAoFBgACBAMSA2gPJAoNCgUGAAIEBBIEaQRrBgoRCgkGAAIEBLDKvCIS
BGkEawYK2gEKBAYAAgUSBHYCfAMaywEgRGVsZXRlcyBwcm92aWRlZCByb3cgYWNjZXNzIHBv
bGljaWVzLgoKICMgSUFNIFBlcm1pc3Npb25zCgogUmVxdWlyZXMgdGhlIGZvbGxvd2luZyBJ
QU0gcGVybWlzc2lvbihzKSBvbiB0aGUgdGFibGU6CgogIC0gYGJpZ3F1ZXJ5LnJvd0FjY2Vz
c1BvbGljaWVzLmRlbGV0ZWAKICAtIGBiaWdxdWVyeS5yb3dBY2Nlc3NQb2xpY2llcy5zZXRJ
YW1Qb2xpY3lgCgoMCgUGAAIFARIDdgYiCgwKBQYAAgUCEgN2I0YKDAoFBgACBQMSA3cPJAoN
CgUGAAIFBBIEeAR7BgoRCgkGAAIFBLDKvCISBHgEewYKRQoCBAASBoABAJEBARo3IFJlcXVl
c3QgbWVzc2FnZSBmb3IgdGhlIExpc3RSb3dBY2Nlc3NQb2xpY2llcyBtZXRob2QuCgoLCgME
AAESBIABCCQKSAoEBAACABIEggECQRo6IFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBy
b3cgYWNjZXNzIHBvbGljaWVzIHRvIGxpc3QuCgoNCgUEAAIABRIEggECCAoNCgUEAAIAARIE
ggEJEwoNCgUEAAIAAxIEggEWFwoNCgUEAAIACBIEggEYQAoQCggEAAIACJwIABIEggEZPwpE
CgQEAAIBEgSFAQJBGjYgUmVxdWlyZWQuIERhdGFzZXQgSUQgb2Ygcm93IGFjY2VzcyBwb2xp
Y2llcyB0byBsaXN0LgoKDQoFBAACAQUSBIUBAggKDQoFBAACAQESBIUBCRMKDQoFBAACAQMS
BIUBFhcKDQoFBAACAQgSBIUBGEAKEAoIBAACAQicCAASBIUBGT8KTAoEBAACAhIEiAECPxo+
IFJlcXVpcmVkLiBUYWJsZSBJRCBvZiB0aGUgdGFibGUgdG8gbGlzdCByb3cgYWNjZXNzIHBv
bGljaWVzLgoKDQoFBAACAgUSBIgBAggKDQoFBAACAgESBIgBCREKDQoFBAACAgMSBIgBFBUK
DQoFBAACAggSBIgBFj4KEAoIBAACAgicCAASBIgBFz0KXgoEBAACAxIEjAECGBpQIFBhZ2Ug
dG9rZW4sIHJldHVybmVkIGJ5IGEgcHJldmlvdXMgY2FsbCwgdG8gcmVxdWVzdCB0aGUgbmV4
dCBwYWdlIG9mCiByZXN1bHRzLgoKDQoFBAACAwUSBIwBAggKDQoFBAACAwESBIwBCRMKDQoF
BAACAwMSBIwBFhcKlwEKBAQAAgQSBJABAhYaiAEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJl
c3VsdHMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHJlc3BvbnNlIHBhZ2UuIExldmVyYWdlCiB0
aGUgcGFnZSB0b2tlbnMgdG8gaXRlcmF0ZSB0aHJvdWdoIHRoZSBlbnRpcmUgY29sbGVjdGlv
bi4KCg0KBQQAAgQFEgSQAQIHCg0KBQQAAgQBEgSQAQgRCg0KBQQAAgQDEgSQARQVCkYKAgQB
EgaUAQCaAQEaOCBSZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgTGlzdFJvd0FjY2Vzc1BvbGlj
aWVzIG1ldGhvZC4KCgsKAwQBARIElAEIJQo7CgQEAQIAEgSWAQIzGi0gUm93IGFjY2VzcyBw
b2xpY2llcyBvbiB0aGUgcmVxdWVzdGVkIHRhYmxlLgoKDQoFBAECAAQSBJYBAgoKDQoFBAEC
AAYSBJYBCxoKDQoFBAECAAESBJYBGy4KDQoFBAECAAMSBJYBMTIKPAoEBAECARIEmQECHRou
IEEgdG9rZW4gdG8gcmVxdWVzdCB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuCgoNCgUEAQIB
BRIEmQECCAoNCgUEAQIBARIEmQEJGAoNCgUEAQIBAxIEmQEbHApCCgIEAhIGnQEAqQEBGjQg
UmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgR2V0Um93QWNjZXNzUG9saWN5IG1ldGhvZC4KCgsK
AwQCARIEnQEIIQpPCgQEAgIAEgSfAQJBGkEgUmVxdWlyZWQuIFByb2plY3QgSUQgb2YgdGhl
IHRhYmxlIHRvIGdldCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEAgIABRIEnwECCAoN
CgUEAgIAARIEnwEJEwoNCgUEAgIAAxIEnwEWFwoNCgUEAgIACBIEnwEYQAoQCggEAgIACJwI
ABIEnwEZPwpPCgQEAgIBEgSiAQJBGkEgUmVxdWlyZWQuIERhdGFzZXQgSUQgb2YgdGhlIHRh
YmxlIHRvIGdldCB0aGUgcm93IGFjY2VzcyBwb2xpY3kuCgoNCgUEAgIBBRIEogECCAoNCgUE
AgIBARIEogEJEwoNCgUEAgIBAxIEogEWFwoNCgUEAgIBCBIEogEYQAoQCggEAgIBCJwIABIE
ogEZPwpNCgQEAgICEgSlAQI/Gj8gUmVxdWlyZWQuIFRhYmxlIElEIG9mIHRoZSB0YWJsZSB0
byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAICAgUSBKUBAggKDQoFBAICAgES
BKUBCREKDQoFBAICAgMSBKUBFBUKDQoFBAICAggSBKUBFj4KEAoIBAICAgicCAASBKUBFz0K
PQoEBAICAxIEqAECQBovIFJlcXVpcmVkLiBQb2xpY3kgSUQgb2YgdGhlIHJvdyBhY2Nlc3Mg
cG9saWN5LgoKDQoFBAICAwUSBKgBAggKDQoFBAICAwESBKgBCRIKDQoFBAICAwMSBKgBFRYK
DQoFBAICAwgSBKgBFz8KEAoIBAICAwicCAASBKgBGD4KRQoCBAMSBqwBALkBARo3IFJlcXVl
c3QgbWVzc2FnZSBmb3IgdGhlIENyZWF0ZVJvd0FjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgME
AwESBKwBCCQKTwoEBAMCABIErgECQRpBIFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSB0
YWJsZSB0byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAMCAAUSBK4BAggKDQoF
BAMCAAESBK4BCRMKDQoFBAMCAAMSBK4BFhcKDQoFBAMCAAgSBK4BGEAKEAoIBAMCAAicCAAS
BK4BGT8KTwoEBAMCARIEsQECQRpBIFJlcXVpcmVkLiBEYXRhc2V0IElEIG9mIHRoZSB0YWJs
ZSB0byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAMCAQUSBLEBAggKDQoFBAMC
AQESBLEBCRMKDQoFBAMCAQMSBLEBFhcKDQoFBAMCAQgSBLEBGEAKEAoIBAMCAQicCAASBLEB
GT8KTQoEBAMCAhIEtAECPxo/IFJlcXVpcmVkLiBUYWJsZSBJRCBvZiB0aGUgdGFibGUgdG8g
Z2V0IHRoZSByb3cgYWNjZXNzIHBvbGljeS4KCg0KBQQDAgIFEgS0AQIICg0KBQQDAgIBEgS0
AQkRCg0KBQQDAgIDEgS0ARQVCg0KBQQDAgIIEgS0ARY+ChAKCAQDAgIInAgAEgS0ARc9CjwK
BAQDAgMSBrcBArgBLxosIFJlcXVpcmVkLiBUaGUgcm93IGFjY2VzcyBwb2xpY3kgdG8gY3Jl
YXRlLgoKDQoFBAMCAwYSBLcBAhEKDQoFBAMCAwESBLcBEiMKDQoFBAMCAwMSBLcBJicKDQoF
BAMCAwgSBLgBBi4KEAoIBAMCAwicCAASBLgBBy0KRQoCBAQSBrwBAMwBARo3IFJlcXVlc3Qg
bWVzc2FnZSBmb3IgdGhlIFVwZGF0ZVJvd0FjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgMEBAES
BLwBCCQKTwoEBAQCABIEvgECQRpBIFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSB0YWJs
ZSB0byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAQCAAUSBL4BAggKDQoFBAQC
AAESBL4BCRMKDQoFBAQCAAMSBL4BFhcKDQoFBAQCAAgSBL4BGEAKEAoIBAQCAAicCAASBL4B
GT8KTwoEBAQCARIEwQECQRpBIFJlcXVpcmVkLiBEYXRhc2V0IElEIG9mIHRoZSB0YWJsZSB0
byBnZXQgdGhlIHJvdyBhY2Nlc3MgcG9saWN5LgoKDQoFBAQCAQUSBMEBAggKDQoFBAQCAQES
BMEBCRMKDQoFBAQCAQMSBMEBFhcKDQoFBAQCAQgSBMEBGEAKEAoIBAQCAQicCAASBMEBGT8K
TQoEBAQCAhIExAECPxo/IFJlcXVpcmVkLiBUYWJsZSBJRCBvZiB0aGUgdGFibGUgdG8gZ2V0
IHRoZSByb3cgYWNjZXNzIHBvbGljeS4KCg0KBQQEAgIFEgTEAQIICg0KBQQEAgIBEgTEAQkR
Cg0KBQQEAgIDEgTEARQVCg0KBQQEAgIIEgTEARY+ChAKCAQEAgIInAgAEgTEARc9Cj0KBAQE
AgMSBMcBAkAaLyBSZXF1aXJlZC4gUG9saWN5IElEIG9mIHRoZSByb3cgYWNjZXNzIHBvbGlj
eS4KCg0KBQQEAgMFEgTHAQIICg0KBQQEAgMBEgTHAQkSCg0KBQQEAgMDEgTHARUWCg0KBQQE
AgMIEgTHARc/ChAKCAQEAgMInAgAEgTHARg+CjwKBAQEAgQSBsoBAssBLxosIFJlcXVpcmVk
LiBUaGUgcm93IGFjY2VzcyBwb2xpY3kgdG8gdXBkYXRlLgoKDQoFBAQCBAYSBMoBAhEKDQoF
BAQCBAESBMoBEiMKDQoFBAQCBAMSBMoBJicKDQoFBAQCBAgSBMsBBi4KEAoIBAQCBAicCAAS
BMsBBy0KRQoCBAUSBs8BAOABARo3IFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIERlbGV0ZVJv
d0FjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgMEBQESBM8BCCQKUgoEBAUCABIE0QECQRpEIFJl
cXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSB0YWJsZSB0byBkZWxldGUgdGhlIHJvdyBhY2Nl
c3MgcG9saWN5LgoKDQoFBAUCAAUSBNEBAggKDQoFBAUCAAESBNEBCRMKDQoFBAUCAAMSBNEB
FhcKDQoFBAUCAAgSBNEBGEAKEAoIBAUCAAicCAASBNEBGT8KUgoEBAUCARIE1AECQRpEIFJl
cXVpcmVkLiBEYXRhc2V0IElEIG9mIHRoZSB0YWJsZSB0byBkZWxldGUgdGhlIHJvdyBhY2Nl
c3MgcG9saWN5LgoKDQoFBAUCAQUSBNQBAggKDQoFBAUCAQESBNQBCRMKDQoFBAUCAQMSBNQB
FhcKDQoFBAUCAQgSBNQBGEAKEAoIBAUCAQicCAASBNQBGT8KUAoEBAUCAhIE1wECPxpCIFJl
cXVpcmVkLiBUYWJsZSBJRCBvZiB0aGUgdGFibGUgdG8gZGVsZXRlIHRoZSByb3cgYWNjZXNz
IHBvbGljeS4KCg0KBQQFAgIFEgTXAQIICg0KBQQFAgIBEgTXAQkRCg0KBQQFAgIDEgTXARQV
Cg0KBQQFAgIIEgTXARY+ChAKCAQFAgIInAgAEgTXARc9Cj0KBAQFAgMSBNoBAkAaLyBSZXF1
aXJlZC4gUG9saWN5IElEIG9mIHRoZSByb3cgYWNjZXNzIHBvbGljeS4KCg0KBQQFAgMFEgTa
AQIICg0KBQQFAgMBEgTaAQkSCg0KBQQFAgMDEgTaARUWCg0KBQQFAgMIEgTaARc/ChAKCAQF
AgMInAgAEgTaARg+CrQBCgQEBQIEEgTfAQIaGqUBIElmIHNldCB0byB0cnVlLCBpdCBkZWxl
dGVzIHRoZSByb3cgYWNjZXNzIHBvbGljeSBldmVuIGlmIGl0J3MgdGhlIGxhc3Qgcm93CiBh
Y2Nlc3MgcG9saWN5IG9uIHRoZSB0YWJsZSBhbmQgdGhlIGRlbGV0aW9uIHdpbGwgd2lkZW4g
dGhlIGFjY2VzcyByYXRoZXIKIG5hcnJvd2luZyBpdC4KCg0KBQQFAgQEEgTfAQIKCg0KBQQF
AgQFEgTfAQsPCg0KBQQFAgQBEgTfARAVCg0KBQQFAgQDEgTfARgZClMKAgQGEgbjAQD0AQEa
RSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBCYXRjaERlbGV0ZVJvd0FjY2Vzc1BvbGljaWVz
UmVxdWVzdCBtZXRob2QuCgoLCgMEBgESBOMBCCsKVAoEBAYCABIE5QECQRpGIFJlcXVpcmVk
LiBQcm9qZWN0IElEIG9mIHRoZSB0YWJsZSB0byBkZWxldGUgdGhlIHJvdyBhY2Nlc3MgcG9s
aWNpZXMuCgoNCgUEBgIABRIE5QECCAoNCgUEBgIAARIE5QEJEwoNCgUEBgIAAxIE5QEWFwoN
CgUEBgIACBIE5QEYQAoQCggEBgIACJwIABIE5QEZPwpUCgQEBgIBEgToAQJBGkYgUmVxdWly
ZWQuIERhdGFzZXQgSUQgb2YgdGhlIHRhYmxlIHRvIGRlbGV0ZSB0aGUgcm93IGFjY2VzcyBw
b2xpY2llcy4KCg0KBQQGAgEFEgToAQIICg0KBQQGAgEBEgToAQkTCg0KBQQGAgEDEgToARYX
Cg0KBQQGAgEIEgToARhAChAKCAQGAgEInAgAEgToARk/ClIKBAQGAgISBOsBAj8aRCBSZXF1
aXJlZC4gVGFibGUgSUQgb2YgdGhlIHRhYmxlIHRvIGRlbGV0ZSB0aGUgcm93IGFjY2VzcyBw
b2xpY2llcy4KCg0KBQQGAgIFEgTrAQIICg0KBQQGAgIBEgTrAQkRCg0KBQQGAgIDEgTrARQV
Cg0KBQQGAgIIEgTrARY+ChAKCAQGAgIInAgAEgTrARc9CkAKBAQGAgMSBO4BAkoaMiBSZXF1
aXJlZC4gUG9saWN5IElEcyBvZiB0aGUgcm93IGFjY2VzcyBwb2xpY2llcy4KCg0KBQQGAgME
EgTuAQIKCg0KBQQGAgMFEgTuAQsRCg0KBQQGAgMBEgTuARIcCg0KBQQGAgMDEgTuAR8gCg0K
BQQGAgMIEgTuASFJChAKCAQGAgMInAgAEgTuASJICrQBCgQEBgIEEgTzAQIaGqUBIElmIHNl
dCB0byB0cnVlLCBpdCBkZWxldGVzIHRoZSByb3cgYWNjZXNzIHBvbGljeSBldmVuIGlmIGl0
J3MgdGhlIGxhc3Qgcm93CiBhY2Nlc3MgcG9saWN5IG9uIHRoZSB0YWJsZSBhbmQgdGhlIGRl
bGV0aW9uIHdpbGwgd2lkZW4gdGhlIGFjY2VzcyByYXRoZXIKIG5hcnJvd2luZyBpdC4KCg0K
BQQGAgQEEgTzAQIKCg0KBQQGAgQFEgTzAQsPCg0KBQQGAgQBEgTzARAVCg0KBQQGAgQDEgTz
ARgZCq8BCgIEBxIG+QEAswIBGqABIFJlcHJlc2VudHMgYWNjZXNzIG9uIGEgc3Vic2V0IG9m
IHJvd3Mgb24gdGhlIHNwZWNpZmllZCB0YWJsZSwgZGVmaW5lZCBieSBpdHMKIGZpbHRlciBw
cmVkaWNhdGUuIEFjY2VzcyB0byB0aGUgc3Vic2V0IG9mIHJvd3MgaXMgY29udHJvbGxlZCBi
eSBpdHMgSUFNCiBwb2xpY3kuCgoLCgMEBwESBPkBCBcKNQoEBAcCABIE+wECPhonIE91dHB1
dCBvbmx5LiBBIGhhc2ggb2YgdGhpcyByZXNvdXJjZS4KCg0KBQQHAgAFEgT7AQIICg0KBQQH
AgABEgT7AQkNCg0KBQQHAgADEgT7ARARCg0KBQQHAgAIEgT7ARI9ChAKCAQHAgAInAgAEgT7
ARM8ClIKBAQHAgESBv4BAv8BLxpCIFJlcXVpcmVkLiBSZWZlcmVuY2UgZGVzY3JpYmluZyB0
aGUgSUQgb2YgdGhpcyByb3cgYWNjZXNzIHBvbGljeS4KCg0KBQQHAgEGEgT+AQIaCg0KBQQH
AgEBEgT+ARs2Cg0KBQQHAgEDEgT+ATk6Cg0KBQQHAgEIEgT/AQYuChAKCAQHAgEInAgAEgT/
AQctCrMDCgQEBwICEgSLAgJHGqQDIFJlcXVpcmVkLiBBIFNRTCBib29sZWFuIGV4cHJlc3Np
b24gdGhhdCByZXByZXNlbnRzIHRoZSByb3dzIGRlZmluZWQgYnkgdGhpcwogcm93IGFjY2Vz
cyBwb2xpY3ksIHNpbWlsYXIgdG8gdGhlIGJvb2xlYW4gZXhwcmVzc2lvbiBpbiBhIFdIRVJF
IGNsYXVzZSBvZiBhCiBTRUxFQ1QgcXVlcnkgb24gYSB0YWJsZS4KIFJlZmVyZW5jZXMgdG8g
b3RoZXIgdGFibGVzLCByb3V0aW5lcywgYW5kIHRlbXBvcmFyeSBmdW5jdGlvbnMgYXJlIG5v
dAogc3VwcG9ydGVkLgoKIEV4YW1wbGVzOiByZWdpb249IkVVIgogICAgICAgICAgIGRhdGVf
ZmllbGQgPSBDQVNUKCcyMDE5LTktMjcnIGFzIERBVEUpCiAgICAgICAgICAgbnVsbGFibGVf
ZmllbGQgaXMgbm90IE5VTEwKICAgICAgICAgICBudW1lcmljX2ZpZWxkIEJFVFdFRU4gMS4w
IEFORCA1LjAKCg0KBQQHAgIFEgSLAgIICg0KBQQHAgIBEgSLAgkZCg0KBQQHAgIDEgSLAhwd
Cg0KBQQHAgIIEgSLAh5GChAKCAQHAgIInAgAEgSLAh9FCnIKBAQHAgMSBo8CApACMhpiIE91
dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoaXMgcm93IGFjY2VzcyBwb2xpY3kgd2FzIGNy
ZWF0ZWQsIGluCiBtaWxsaXNlY29uZHMgc2luY2UgdGhlIGVwb2NoLgoKDQoFBAcCAwYSBI8C
AhsKDQoFBAcCAwESBI8CHCkKDQoFBAcCAwMSBI8CLC0KDQoFBAcCAwgSBJACBjEKEAoIBAcC
AwicCAASBJACBzAKeAoEBAcCBBIGlAIClQIyGmggT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdo
ZW4gdGhpcyByb3cgYWNjZXNzIHBvbGljeSB3YXMgbGFzdCBtb2RpZmllZCwgaW4KIG1pbGxp
c2Vjb25kcyBzaW5jZSB0aGUgZXBvY2guCgoNCgUEBwIEBhIElAICGwoNCgUEBwIEARIElAIc
LgoNCgUEBwIEAxIElAIxMgoNCgUEBwIECBIElQIGMQoQCggEBwIECJwIABIElQIHMArUCQoE
BAcCBRIGrwICsgIEGsMJIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBUaGUgb3B0aW9uYWwgbGlz
dCBvZiBpYW1fbWVtYmVyIHVzZXJzIG9yIGdyb3VwcyB0aGF0CiBzcGVjaWZpZXMgdGhlIGlu
aXRpYWwgbWVtYmVycyB0aGF0IHRoZSByb3ctbGV2ZWwgYWNjZXNzIHBvbGljeSBzaG91bGQg
YmUKIGNyZWF0ZWQgd2l0aC4KCiBncmFudGVlcyB0eXBlczoKCiAtICJ1c2VyOmFsaWNlQGV4
YW1wbGUuY29tIjogQW4gZW1haWwgYWRkcmVzcyB0aGF0IHJlcHJlc2VudHMgYSBzcGVjaWZp
YwogR29vZ2xlIGFjY291bnQuCiAtICJzZXJ2aWNlQWNjb3VudDpteS1vdGhlci1hcHBAYXBw
c3BvdC5nc2VydmljZWFjY291bnQuY29tIjogQW4gZW1haWwKIGFkZHJlc3MgdGhhdCByZXBy
ZXNlbnRzIGEgc2VydmljZSBhY2NvdW50LgogLSAiZ3JvdXA6YWRtaW5zQGV4YW1wbGUuY29t
IjogQW4gZW1haWwgYWRkcmVzcyB0aGF0IHJlcHJlc2VudHMgYSBHb29nbGUKIGdyb3VwLgog
LSAiZG9tYWluOmV4YW1wbGUuY29tIjpUaGUgR29vZ2xlIFdvcmtzcGFjZSBkb21haW4gKHBy
aW1hcnkpIHRoYXQKIHJlcHJlc2VudHMgYWxsIHRoZSB1c2VycyBvZiB0aGF0IGRvbWFpbi4K
IC0gImFsbEF1dGhlbnRpY2F0ZWRVc2VycyI6IEEgc3BlY2lhbCBpZGVudGlmaWVyIHRoYXQg
cmVwcmVzZW50cyBhbGwgc2VydmljZQogYWNjb3VudHMgYW5kIGFsbCB1c2VycyBvbiB0aGUg
aW50ZXJuZXQgd2hvIGhhdmUgYXV0aGVudGljYXRlZCB3aXRoIGEgR29vZ2xlCiBBY2NvdW50
LiBUaGlzIGlkZW50aWZpZXIgaW5jbHVkZXMgYWNjb3VudHMgdGhhdCBhcmVuJ3QgY29ubmVj
dGVkIHRvIGEKIEdvb2dsZSBXb3Jrc3BhY2Ugb3IgQ2xvdWQgSWRlbnRpdHkgZG9tYWluLCBz
dWNoIGFzIHBlcnNvbmFsIEdtYWlsIGFjY291bnRzLgogVXNlcnMgd2hvIGFyZW4ndCBhdXRo
ZW50aWNhdGVkLCBzdWNoIGFzIGFub255bW91cyB2aXNpdG9ycywgYXJlbid0CiBpbmNsdWRl
ZC4KIC0gImFsbFVzZXJzIjpBIHNwZWNpYWwgaWRlbnRpZmllciB0aGF0IHJlcHJlc2VudHMg
YW55b25lIHdobyBpcyBvbgogdGhlIGludGVybmV0LCBpbmNsdWRpbmcgYXV0aGVudGljYXRl
ZCBhbmQgdW5hdXRoZW50aWNhdGVkIHVzZXJzLiBCZWNhdXNlCiBCaWdRdWVyeSByZXF1aXJl
cyBhdXRoZW50aWNhdGlvbiBiZWZvcmUgYSB1c2VyIGNhbiBhY2Nlc3MgdGhlIHNlcnZpY2Us
CiBhbGxVc2VycyBpbmNsdWRlcyBvbmx5IGF1dGhlbnRpY2F0ZWQgdXNlcnMuCgoNCgUEBwIF
BBIErwICCgoNCgUEBwIFBRIErwILEQoNCgUEBwIFARIErwISGgoNCgUEBwIFAxIErwIdHgoP
CgUEBwIFCBIGrwIfsgIDChAKCAQHAgUInAgAEgSwAgQsChAKCAQHAgUInAgBEgSxAgQqYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest ===
    # Fields for ListRowAccessPoliciesRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse ===
    # Fields for ListRowAccessPoliciesResponse
    # Field: row_access_policies Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest ===
    # Fields for GetRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest ===
    # Fields for CreateRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: row_access_policy Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest ===
    # Fields for UpdateRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: row_access_policy Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicy)

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest ===
    # Fields for DeleteRowAccessPolicyRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest ===
    # Fields for BatchDeleteRowAccessPoliciesRequest
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_ids Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy ===
    # Fields for RowAccessPolicy
    # Field: etag Type: 9 ()
    # Field: row_access_policy_reference Type: 11 (.google.cloud.bigquery.v2.RowAccessPolicyReference)
    # Field: filter_predicate Type: 9 ()
    # Field: creation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_modified_time Type: 11 (.google.protobuf.Timestamp)
    # Field: grantees Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicyServiceClient ===
package Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicyServiceClient

Client stub representing the remote C<RowAccessPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_row_access_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'ListRowAccessPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse',
    });
}

sub get_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'GetRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub create_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'CreateRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub update_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'UpdateRowAccessPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy',
    });
}

sub delete_row_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest->new($args)
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
        ? Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'BatchDeleteRowAccessPolicies',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::RowAccessPolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/row_access_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::RowAccessPolicy;

    my $msg = Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id => $table_id,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/row_access_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest

Request message for the ListRowAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the row access policies to list.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of row access policies to list.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to list row access policies.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token, returned by a previous call, to request the next page of
results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results to return in a single response page. Leverage
the page tokens to iterate through the entire collection.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse

Response message for the ListRowAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->row_access_policies() >> / C<< $msg->row_access_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>)

Row access policies on the requested table.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to request the next page of results.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest

Request message for the GetRowAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the table to get the row access policy.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of the table to get the row access policy.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to get the row access policy.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Required. Policy ID of the row access policy.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest

Request message for the CreateRowAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the table to get the row access policy.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of the table to get the row access policy.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to get the row access policy.

=item * C<< $msg->row_access_policy() >> / C<< $msg->row_access_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>)

Required. The row access policy to create.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest

Request message for the UpdateRowAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the table to get the row access policy.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of the table to get the row access policy.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to get the row access policy.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Required. Policy ID of the row access policy.

=item * C<< $msg->row_access_policy() >> / C<< $msg->row_access_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>)

Required. The row access policy to update.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest

Request message for the DeleteRowAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the table to delete the row access policy.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of the table to delete the row access policy.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to delete the row access policy.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Required. Policy ID of the row access policy.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, it deletes the row access policy even if it's the last row
access policy on the table and the deletion will widen the access rather
narrowing it.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest

Request message for the BatchDeleteRowAccessPoliciesRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. Project ID of the table to delete the row access policies.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. Dataset ID of the table to delete the row access policies.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. Table ID of the table to delete the row access policies.

=item * C<< $msg->policy_ids() >> / C<< $msg->policy_ids($value) >>

Type: C<String>

Required. Policy IDs of the row access policies.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, it deletes the row access policy even if it's the last row
access policy on the table and the deletion will widen the access rather
narrowing it.

=back

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy

Represents access on a subset of rows on the specified table, defined by its
filter predicate. Access to the subset of rows is controlled by its IAM
policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. A hash of this resource.

=item * C<< $msg->row_access_policy_reference() >> / C<< $msg->row_access_policy_reference($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference>)

Required. Reference describing the ID of this row access policy.

=item * C<< $msg->filter_predicate() >> / C<< $msg->filter_predicate($value) >>

Type: C<String>

Required. A SQL boolean expression that represents the rows defined by this
row access policy, similar to the boolean expression in a WHERE clause of a
SELECT query on a table.
References to other tables, routines, and temporary functions are not
supported.

Examples: region="EU"
          date_field = CAST('2019-9-27' as DATE)
          nullable_field is not NULL
          numeric_field BETWEEN 1.0 AND 5.0

=item * C<< $msg->creation_time() >> / C<< $msg->creation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this row access policy was created, in
milliseconds since the epoch.

=item * C<< $msg->last_modified_time() >> / C<< $msg->last_modified_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this row access policy was last modified, in
milliseconds since the epoch.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Optional. Input only. The optional list of iam_member users or groups that
specifies the initial members that the row-level access policy should be
created with.

grantees types:

- "user:alice@example.com": An email address that represents a specific
Google account.
- "serviceAccount:my-other-app@appspot.gserviceaccount.com": An email
address that represents a service account.
- "group:admins@example.com": An email address that represents a Google
group.
- "domain:example.com":The Google Workspace domain (primary) that
represents all the users of that domain.
- "allAuthenticatedUsers": A special identifier that represents all service
accounts and all users on the internet who have authenticated with a Google
Account. This identifier includes accounts that aren't connected to a
Google Workspace or Cloud Identity domain, such as personal Gmail accounts.
Users who aren't authenticated, such as anonymous visitors, aren't
included.
- "allUsers":A special identifier that represents anyone who is on
the internet, including authenticated and unauthenticated users. Because
BigQuery requires authentication before a user can access the service,
allUsers includes only authenticated users.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::RowAccessPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
