package Google::Cloud::Financialservices::V1::EngineConfig;

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
    eval { require Google::Cloud::Financialservices::V1::BigqueryDestination };
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvZW5naW5lX2NvbmZpZy5wcm90
bxIhZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjxnb29nbGUvY2xv
dWQvZmluYW5jaWFsc2VydmljZXMvdjEvYmlncXVlcnlfZGVzdGluYXRpb24ucHJvdG8aOGdv
b2dsZS9jbG91ZC9maW5hbmNpYWxzZXJ2aWNlcy92MS9saW5lX29mX2J1c2luZXNzLnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byKMDgoMRW5naW5lQ29uZmlnEhcKBG5hbWUYASABKAlCA+BBA1IEbmFt
ZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJTCgZsYWJlbHMYBCADKAsyOy5nb29nbGUuY2xv
dWQuZmluYW5jaWFsc2VydmljZXMudjEuRW5naW5lQ29uZmlnLkxhYmVsc0VudHJ5UgZsYWJl
bHMSUAoFc3RhdGUYBSABKA4yNS5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEu
RW5naW5lQ29uZmlnLlN0YXRlQgPgQQNSBXN0YXRlEl0KDmVuZ2luZV92ZXJzaW9uGAYgASgJ
QjbgQQL6QTAKLmZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0VuZ2luZVZlcnNp
b25SDWVuZ2luZVZlcnNpb24SUwoGdHVuaW5nGAcgASgLMjYuZ29vZ2xlLmNsb3VkLmZpbmFu
Y2lhbHNlcnZpY2VzLnYxLkVuZ2luZUNvbmZpZy5UdW5pbmdCA+BBAVIGdHVuaW5nEnUKEnBl
cmZvcm1hbmNlX3RhcmdldBgLIAEoCzJBLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNl
cy52MS5FbmdpbmVDb25maWcuUGVyZm9ybWFuY2VUYXJnZXRCA+BBAVIRcGVyZm9ybWFuY2VU
YXJnZXQSYAoQbGluZV9vZl9idXNpbmVzcxgMIAEoDjIxLmdvb2dsZS5jbG91ZC5maW5hbmNp
YWxzZXJ2aWNlcy52MS5MaW5lT2ZCdXNpbmVzc0ID4EEDUg5saW5lT2ZCdXNpbmVzcxKLAQoa
aHlwZXJwYXJhbWV0ZXJfc291cmNlX3R5cGUYDyABKA4ySC5nb29nbGUuY2xvdWQuZmluYW5j
aWFsc2VydmljZXMudjEuRW5naW5lQ29uZmlnLkh5cGVycGFyYW1ldGVyU291cmNlVHlwZUID
4EEBUhhoeXBlcnBhcmFtZXRlclNvdXJjZVR5cGUSfgoVaHlwZXJwYXJhbWV0ZXJfc291cmNl
GBAgASgLMkQuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkVuZ2luZUNvbmZp
Zy5IeXBlcnBhcmFtZXRlclNvdXJjZUID4EEBUhRoeXBlcnBhcmFtZXRlclNvdXJjZRqfAQoG
VHVuaW5nElkKD3ByaW1hcnlfZGF0YXNldBgBIAEoCUIw4EEC+kEqCihmaW5hbmNpYWxzZXJ2
aWNlcy5nb29nbGVhcGlzLmNvbS9EYXRhc2V0Ug5wcmltYXJ5RGF0YXNldBI6CghlbmRfdGlt
ZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIHZW5kVGltZRpoChFQ
ZXJmb3JtYW5jZVRhcmdldBJTCiRwYXJ0eV9pbnZlc3RpZ2F0aW9uc19wZXJfcGVyaW9kX2hp
bnQYASABKANCA+BBAlIgcGFydHlJbnZlc3RpZ2F0aW9uc1BlclBlcmlvZEhpbnQahgEKFEh5
cGVycGFyYW1ldGVyU291cmNlEjUKFHNvdXJjZV9lbmdpbmVfY29uZmlnGAEgASgJQgPgQQJS
EnNvdXJjZUVuZ2luZUNvbmZpZxI3ChVzb3VyY2VfZW5naW5lX3ZlcnNpb24YAiABKAlCA+BB
A1ITc291cmNlRW5naW5lVmVyc2lvbho5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlQKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lG
SUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIMCghVUERBVElORxADEgwKCERFTEVU
SU5HEAQiYQoYSHlwZXJwYXJhbWV0ZXJTb3VyY2VUeXBlEioKJkhZUEVSUEFSQU1FVEVSX1NP
VVJDRV9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGVFVOSU5HEAESDQoJSU5IRVJJVEVEEAI6kwHq
QY8BCi1maW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmdpbmVDb25maWcSXnBy
b2plY3RzL3twcm9qZWN0X251bX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tp
bnN0YW5jZX0vZW5naW5lQ29uZmlncy97ZW5naW5lX2NvbmZpZ30i1AEKGExpc3RFbmdpbmVD
b25maWdzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKwopZmluYW5jaWFsc2Vydmlj
ZXMuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCAB
KAlSBmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSK9AQoZTGlzdEVuZ2luZUNv
bmZpZ3NSZXNwb25zZRJWCg5lbmdpbmVfY29uZmlncxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5m
aW5hbmNpYWxzZXJ2aWNlcy52MS5FbmdpbmVDb25maWdSDWVuZ2luZUNvbmZpZ3MSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJ
Ugt1bnJlYWNoYWJsZSJjChZHZXRFbmdpbmVDb25maWdSZXF1ZXN0EkkKBG5hbWUYASABKAlC
NeBBAvpBLwotZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5naW5lQ29uZmln
UgRuYW1lIpQCChlDcmVhdGVFbmdpbmVDb25maWdSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx
4EEC+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIGcGFy
ZW50Ei0KEGVuZ2luZV9jb25maWdfaWQYAiABKAlCA+BBAlIOZW5naW5lQ29uZmlnSWQSWQoN
ZW5naW5lX2NvbmZpZxgDIAEoCzIvLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52
MS5FbmdpbmVDb25maWdCA+BBAlIMZW5naW5lQ29uZmlnEiIKCnJlcXVlc3RfaWQYBCABKAlC
A+BBAVIJcmVxdWVzdElkItwBChlVcGRhdGVFbmdpbmVDb25maWdSZXF1ZXN0EkAKC3VwZGF0
ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVN
YXNrElkKDWVuZ2luZV9jb25maWcYAiABKAsyLy5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vy
dmljZXMudjEuRW5naW5lQ29uZmlnQgPgQQJSDGVuZ2luZUNvbmZpZxIiCgpyZXF1ZXN0X2lk
GAMgASgJQgPgQQFSCXJlcXVlc3RJZCKKAQoZRGVsZXRlRW5naW5lQ29uZmlnUmVxdWVzdBJJ
CgRuYW1lGAEgASgJQjXgQQL6QS8KLWZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29t
L0VuZ2luZUNvbmZpZ1IEbmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJ
ZCKFAgohRXhwb3J0RW5naW5lQ29uZmlnTWV0YWRhdGFSZXF1ZXN0EloKDWVuZ2luZV9jb25m
aWcYASABKAlCNeBBAvpBLwotZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5n
aW5lQ29uZmlnUgxlbmdpbmVDb25maWcSgwEKH3N0cnVjdHVyZWRfbWV0YWRhdGFfZGVzdGlu
YXRpb24YAiABKAsyNi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuQmlnUXVl
cnlEZXN0aW5hdGlvbkID4EECUh1zdHJ1Y3R1cmVkTWV0YWRhdGFEZXN0aW5hdGlvbiIkCiJF
eHBvcnRFbmdpbmVDb25maWdNZXRhZGF0YVJlc3BvbnNlQoACCiVjb20uZ29vZ2xlLmNsb3Vk
LmZpbmFuY2lhbHNlcnZpY2VzLnYxQhFFbmdpbmVDb25maWdQcm90b1ABWlNjbG91ZC5nb29n
bGUuY29tL2dvL2ZpbmFuY2lhbHNlcnZpY2VzL2FwaXYxL2ZpbmFuY2lhbHNlcnZpY2VzcGI7
ZmluYW5jaWFsc2VydmljZXNwYqoCIUdvb2dsZS5DbG91ZC5GaW5hbmNpYWxTZXJ2aWNlcy5W
McoCIUdvb2dsZVxDbG91ZFxGaW5hbmNpYWxTZXJ2aWNlc1xWMeoCJEdvb2dsZTo6Q2xvdWQ6
OkZpbmFuY2lhbFNlcnZpY2VzOjpWMUqKZAoHEgUOAM8CLQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQARgoJCgIDAxIDFQBCCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEIEgMZAD4KCQoCCCUS
AxkAPgoICgEIEgMaAGoKCQoCCAsSAxoAagoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMc
ADIKCQoCCAgSAxwAMgoICgEIEgMdAD4KCQoCCAESAx0APgoICgEIEgMeAD4KCQoCCCkSAx4A
PgoICgEIEgMfAD0KCQoCCC0SAx8APQpYCgIEABIFIgCvAQEaSyBUaGUgRW5naW5lQ29uZmln
IHJlc291cmNlIGNyZWF0ZXMgdGhlIGNvbmZpZ3VyYXRpb24gZm9yIHRyYWluaW5nIGEgbW9k
ZWwuCgoKCgMEAAESAyIIFAoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKfQoEBAADABIE
KgI7AxpvIFRoZSBwYXJhbWV0ZXJzIG5lZWRlZCBmb3IgdGhlIHR1bmluZyBvcGVyYXRpb24s
IHRoZXNlIGFyZSB1c2VkIG9ubHkgaW4KIHR1bmluZyBhbmQgbm90IHBhc3NlZCBvbiB0byB0
cmFpbmluZy4KCgwKBQQAAwABEgMqChAKswIKBgQAAwACABIELwQ0BhqiAiBSZXF1aXJlZC4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFByaW1hcnkgRGF0YXNldCB1c2VkIGluIHRoaXMg
bW9kZWwKIHR1bmluZy4gRm9yIGluZm9ybWF0aW9uIGFib3V0IGhvdyBwcmltYXJ5IGFuZCBh
dXhpbGlhcnkgZGF0YXNldHMgYXJlCiB1c2VkLCByZWZlciB0byB0aGUgZW5naW5lIHZlcnNp
b24ncyBkb2N1bWVudGF0aW9uLiAgRm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVjdF9udW19
L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2RhdGFzZXRzL3tk
YXRhc2V0fWAKCg4KBwQAAwACAAUSAy8ECgoOCgcEAAMAAgABEgMvCxoKDgoHBAADAAIAAxID
Lx0eCg8KBwQAAwACAAgSBC8fNAUKEQoKBAADAAIACJwIABIDMAYsChEKCQQAAwACAAifCBIE
MQYzBwrlAQoGBAADAAIBEgQ5BDoxGtQBIFJlcXVpcmVkLiBFbmRfdGltZSBzcGVjaWZpZXMg
dGhlIGxhdGVzdCB0aW1lIGZyb20gd2hpY2ggbGFiZWxzIGFyZSB1c2VkCiBhbmQgZnJvbSB3
aGljaCBkYXRhIGlzIHVzZWQgdG8gZ2VuZXJhdGUgZmVhdHVyZXMgZm9yIHR1bmluZy4gIEVu
ZF90aW1lCiBzaG91bGQgYmUgbm8gbGF0ZXIgdGhhbiB0aGUgZW5kIG9mIHRoZSBkYXRlX3Jh
bmdlIG9mIHRoZSBkYXRhc2V0LgoKDgoHBAADAAIBBhIDOQQdCg4KBwQAAwACAQESAzkeJgoO
CgcEAAMAAgEDEgM5KSsKDgoHBAADAAIBCBIDOggwChEKCgQAAwACAQicCAASAzoJLwpdCgQE
AAMBEgQ/AkgDGk8gUGVyZm9ybWFuY2VUYXJnZXQgZ2l2ZXMgaGludHMgb24gaG93IHRvIGV2
YWx1YXRlIHRoZSBwZXJmb3JtYW5jZSBvZiBhCiBtb2RlbC4KCgwKBQQAAwEBEgM/ChsKmQMK
BgQAAwECABIERgRHMRqIAyBSZXF1aXJlZC4gQSBudW1iZXIgdGhhdCBnaXZlcyB0aGUgdHVu
ZXIgYSBoaW50IG9uIHRoZSBudW1iZXIgb2YgcGFydGllcwogZnJvbSB0aGlzIGRhdGEgdGhh
dCB3aWxsIGJlIGludmVzdGlnYXRlZCBwZXIgcGVyaW9kIChtb250aGx5KS4gVGhpcyBpcwog
dXNlZCB0byBjb250cm9sIGhvdyB0aGUgbW9kZWwgaXMgZXZhbHVhdGVkLiBGb3IgZXhhbXBs
ZSwgd2hlbiB0cnlpbmcgQU1MCiBBSSBmb3IgdGhlIGZpcnN0IHRpbWUsIHdlIHJlY29tbWVu
ZCBzZXR0aW5nIHRoaXMgdG8gdGhlIG51bWJlciBvZiBwYXJ0aWVzCiBpbnZlc3RpZ2F0ZWQg
aW4gYW4gYXZlcmFnZSBtb250aCwgYmFzZWQgb24gYWxlcnRzIGZyb20geW91ciBleGlzdGlu
ZwogYXV0b21hdGVkIGFsZXJ0aW5nIHN5c3RlbS4KCg4KBwQAAwECAAUSA0YECQoOCgcEAAMB
AgABEgNGCi4KDgoHBAADAQIAAxIDRjEyCg4KBwQAAwECAAgSA0cIMAoRCgoEAAMBAgAInAgA
EgNHCS8KXwoEBAADAhIETAJXAxpRIFBhcmFtZXRlcnMgZm9yIGJvb3RzdHJhcHBpbmcgYW4g
RW5naW5lIENvbmZpZyB3aXRoIHRoZSByZXN1bHRzIG9mIGFub3RoZXIKIG9uZS4KCgwKBQQA
AwIBEgNMCh4KzAEKBgQAAwICABIDUARNGrwBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgc291cmNlIEVuZ2luZUNvbmZpZyB3aG9zZSBvdXRwdXRzIGFyZQogdXNlZC4g
Rm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc3RhbmNlcy97aW5zdGFuY2V9L2VuZ2luZUNvbmZpZ3Mve2VuZ2luZV9jb25maWd9YAoK
DgoHBAADAgIABRIDUAQKCg4KBwQAAwICAAESA1ALHwoOCgcEAAMCAgADEgNQIiMKDgoHBAAD
AgIACBIDUCRMChEKCgQAAwICAAicCAASA1AlSwrVAQoGBAADAgIBEgRVBFY0GsQBIE91dHB1
dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRW5naW5lVmVyc2lvbiB0aGF0IHdh
cyB1c2VkIGluIHRoZQogdHVuaW5nIHJ1bi4gRm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVj
dF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2VuZ2lu
ZVZlcnNpb25zL3tlbmdpbmVfdmVyc2lvbn1gCgoOCgcEAAMCAgEFEgNVBAoKDgoHBAADAgIB
ARIDVQsgCg4KBwQAAwICAQMSA1UjJAoOCgcEAAMCAgEIEgNWCDMKEQoKBAADAgIBCJwIABID
VgkyCjIKBAQABAASBFoCaQMaJCBUaGUgcG9zc2libGUgc3RhdGVzIG9mIGEgcmVzb3VyY2Uu
CgoMCgUEAAQAARIDWgcMCjgKBgQABAACABIDXAQaGikgU3RhdGUgaXMgdW5zcGVjaWZpZWQs
IHNob3VsZCBub3Qgb2NjdXIuCgoOCgcEAAQAAgABEgNcBBUKDgoHBAAEAAIAAhIDXBgZCj0K
BgQABAACARIDXwQRGi4gVGhlIHJlc291cmNlIGhhcyBub3QgZmluaXNoZWQgYmVpbmcgY3Jl
YXRlZC4KCg4KBwQABAACAQESA18EDAoOCgcEAAQAAgECEgNfDxAKOQoGBAAEAAICEgNiBA8a
KiBUaGUgcmVzb3VyY2UgaXMgYWN0aXZlL3JlYWR5IHRvIGJlIHVzZWQuCgoOCgcEAAQAAgIB
EgNiBAoKDgoHBAAEAAICAhIDYg0OCkEKBgQABAACAxIDZQQRGjIgVGhlIHJlc291cmNlIGlz
IGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgNlBAwKDgoH
BAAEAAIDAhIDZQ8QCkEKBgQABAACBBIDaAQRGjIgVGhlIHJlc291cmNlIGlzIGluIHRoZSBw
cm9jZXNzIG9mIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgQBEgNoBAwKDgoHBAAEAAIEAhID
aA8QCjYKBAQABAESBGwCdgMaKCBUaGUgdHlwZSBvZiB0aGUgaHlwZXJwYXJhbWV0ZXIgc291
cmNlLgoKDAoFBAAEAQESA2wHHwpPCgYEAAQBAgASA24ELxpAIEh5cGVycGFyYW1ldGVyIHNv
dXJjZSB0eXBlIGlzIHVuc3BlY2lmaWVkLCBkZWZhdWx0cyB0byBUVU5JTkcuCgoOCgcEAAQB
AgABEgNuBCoKDgoHBAAEAQIAAhIDbi0uCmcKBgQABAECARIDcgQPGlggVGhlIEVuZ2luZUNv
bmZpZyBjcmVhdGlvbiBzdGFydHMgYSB0dW5pbmcgam9iIHdoaWNoIHNlbGVjdHMgdGhlIGJl
c3QKIGh5cGVycGFyYW1ldGVycy4KCg4KBwQABAECAQESA3IECgoOCgcEAAQBAgECEgNyDQ4K
TQoGBAAEAQICEgN1BBIaPiBUaGUgaHlwZXJwYXJhbWV0ZXJzIGFyZSBpbmhlcml0ZWQgZnJv
bSBhbm90aGVyIEVuZ2luZUNvbmZpZy4KCg4KBwQABAECAgESA3UEDQoOCgcEAAQBAgICEgN1
EBEKrwEKBAQAAgASA3sCPhqhASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIEVuZ2luZUNvbmZpZy4KIGZvcm1hdDoKIGAvcHJvamVjdHMve3Byb2plY3RfbnVtfS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9lbmdpbmVDb25maWdz
L3tlbmdpbmVfY29uZmlnfWAKCgwKBQQAAgAFEgN7AggKDAoFBAACAAESA3sJDQoMCgUEAAIA
AxIDexARCgwKBQQAAgAIEgN7Ej0KDwoIBAACAAicCAASA3sTPApICgQEAAIBEgR+An8yGjog
T3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgY3JlYXRpb24gb2YgdGhpcyByZXNvdXJj
ZS4KCgwKBQQAAgEGEgN+AhsKDAoFBAACAQESA34cJwoMCgUEAAIBAxIDfiorCgwKBQQAAgEI
EgN/BjEKDwoIBAACAQicCAASA38HMApYCgQEAAICEgaCAQKDATIaSCBPdXRwdXQgb25seS4g
VGhlIHRpbWVzdGFtcCBvZiB0aGUgbW9zdCByZWNlbnQgdXBkYXRlIG9mIHRoaXMgcmVzb3Vy
Y2UuCgoNCgUEAAICBhIEggECGwoNCgUEAAICARIEggEcJwoNCgUEAAICAxIEggEqKwoNCgUE
AAICCBIEgwEGMQoQCggEAAICCJwIABIEgwEHMAoWCgQEAAIDEgSGAQIhGgggTGFiZWxzCgoN
CgUEAAIDBhIEhgECFQoNCgUEAAIDARIEhgEWHAoNCgUEAAIDAxIEhgEfIApZCgQEAAIEEgSJ
AQI+GksgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBFbmdpbmVDb25maWcgKGNyZWF0aW5n
LCBhY3RpdmUsIGRlbGV0aW5nLCBldGMuKQoKDQoFBAACBAYSBIkBAgcKDQoFBAACBAESBIkB
CA0KDQoFBAACBAMSBIkBEBEKDQoFBAACBAgSBIkBEj0KEAoIBAACBAicCAASBIkBEzwKzAEK
BAQAAgUSBo4BApMBBBq7ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEVu
Z2luZVZlcnNpb24gdXNlZCBpbiB0aGlzIG1vZGVsIHR1bmluZy4KIGZvcm1hdDoKIGAvcHJv
amVjdHMve3Byb2plY3RfbnVtfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2lu
c3RhbmNlfS9lbmdpbmVWZXJzaW9ucy97ZW5naW5lX3ZlcnNpb259YAoKDQoFBAACBQUSBI4B
AggKDQoFBAACBQESBI4BCRcKDQoFBAACBQMSBI4BGhsKDwoFBAACBQgSBo4BHJMBAwoQCggE
AAIFCJwIABIEjwEEKgoRCgcEAAIFCJ8IEgaQAQSSAQUKvAEKBAQAAgYSBJgBAj0arQEgT3B0
aW9uYWwuIENvbmZpZ3VyYXRpb24gZm9yIHR1bmluZyBpbiBjcmVhdGlvbiBvZiB0aGUgRW5n
aW5lQ29uZmlnLgogVGhpcyBmaWVsZCBpcyByZXF1aXJlZCBpZiBgaHlwZXJwYXJhbWV0ZXJf
c291cmNlLnR5cGVgIGlzIG5vdCBgSU5IRVJJVEVEYCwKIGFuZCBvdXRwdXQtb25seSBvdGhl
cndpc2UuCgoNCgUEAAIGBhIEmAECCAoNCgUEAAIGARIEmAEJDwoNCgUEAAIGAxIEmAESEwoN
CgUEAAIGCBIEmAEUPAoQCggEAAIGCJwIABIEmAEVOwraAQoEBAACBxIGnQECngEvGskBIE9w
dGlvbmFsLiBQZXJmb3JtYW5jZVRhcmdldCBnaXZlcyBpbmZvcm1hdGlvbiBvbiBob3cgdGhl
IHR1bmluZyBhbmQKIHRyYWluaW5nIHdpbGwgYmUgZXZhbHVhdGVkLiBUaGlzIGZpZWxkIGlz
IHJlcXVpcmVkIGlmCiBgaHlwZXJwYXJhbWV0ZXJfc291cmNlLnR5cGVgIGlzIG5vdCBgSU5I
RVJJVEVEYCwgYW5kIG91dHB1dC1vbmx5IG90aGVyd2lzZS4KCg0KBQQAAgcGEgSdAQITCg0K
BQQAAgcBEgSdARQmCg0KBQQAAgcDEgSdASkrCg0KBQQAAgcIEgSeAQYuChAKCAQAAgcInAgA
EgSeAQctCp0BCgQEAAIIEgaiAQKjATIajAEgT3V0cHV0IG9ubHkuIFRoZSBsaW5lIG9mIGJ1
c2luZXNzIChSZXRhaWwvQ29tbWVyY2lhbCkgdGhpcyBlbmdpbmUgY29uZmlnIGlzCiB1c2Vk
IGZvci4gRGV0ZXJtaW5lZCBieSBFbmdpbmVWZXJzaW9uLCBjYW5ub3QgYmUgc2V0IGJ5IHVz
ZXIuCgoNCgUEAAIIBhIEogECEAoNCgUEAAIIARIEogERIQoNCgUEAAIIAxIEogEkJgoNCgUE
AAIICBIEowEGMQoQCggEAAIICJwIABIEowEHMArBAQoEBAACCRIGqQECqgEvGrABIE9wdGlv
bmFsLiBUaGUgb3JpZ2luIG9mIGh5cGVycGFyYW1ldGVycyBmb3IgdGhlIGNyZWF0ZWQgRW5n
aW5lQ29uZmlnLiBUaGUKIGRlZmF1bHQgaXMgYFRVTklOR2AuIEluIHRoaXMgY2FzZSwgdGhl
IGh5cGVycGFyYW1ldGVycyBhcmUgc2VsZWN0ZWQgYXMgYQogcmVzdWx0IG9mIGEKICB0dW5p
bmcgcnVuLgoKDQoFBAACCQYSBKkBAhoKDQoFBAACCQESBKkBGzUKDQoFBAACCQMSBKkBODoK
DQoFBAACCQgSBKoBBi4KEAoIBAACCQicCAASBKoBBy0KUQoEBAACChIGrQECrgEvGkEgT3B0
aW9uYWwuIENvbmZpZ3VyYXRpb24gb2YgaHlwZXJwYXJhbWV0ZXJzIHNvdXJjZSBFbmdpbmVD
b25maWcuCgoNCgUEAAIKBhIErQECFgoNCgUEAAIKARIErQEXLAoNCgUEAAIKAxIErQEvMQoN
CgUEAAIKCBIErgEGLgoQCggEAAIKCJwIABIErgEHLQp0CgIEARIGswEAzQEBGmYgUmVxdWVz
dCBmb3IgcmV0cmlldmluZyBhIHBhZ2luYXRlZCBsaXN0IG9mIEVuZ2luZUNvbmZpZyByZXNv
dXJjZXMgdGhhdAogbWVldCB0aGUgc3BlY2lmaWVkIGNyaXRlcmlhLgoKCwoDBAEBEgSzAQgg
CksKBAQBAgASBrUBAroBBBo7IFJlcXVpcmVkLiBUaGUgcGFyZW50IG9mIHRoZSBFbmdpbmVD
b25maWcgaXMgdGhlIEluc3RhbmNlLgoKDQoFBAECAAUSBLUBAggKDQoFBAECAAESBLUBCQ8K
DQoFBAECAAMSBLUBEhMKDwoFBAECAAgSBrUBFLoBAwoQCggEAQIACJwIABIEtgEEKgoRCgcE
AQIACJ8IEga3AQS5AQUKrQEKBAQBAgESBL8BAhYangEgVGhlIG51bWJlciBvZiByZXNvdXJj
ZXMgdG8gYmUgaW5jbHVkZWQgaW4gdGhlIHJlc3BvbnNlLiBUaGUgcmVzcG9uc2UKIGNvbnRh
aW5zIGEgbmV4dF9wYWdlX3Rva2VuLCB3aGljaCBjYW4gYmUgdXNlZCB0byByZXRyaWV2ZSB0
aGUgbmV4dCBwYWdlIG9mCiByZXNvdXJjZXMuCgoNCgUEAQIBBRIEvwECBwoNCgUEAQIBARIE
vwEIEQoNCgUEAQIBAxIEvwEUFQqxAgoEBAECAhIExgECGBqiAiBJbiBjYXNlIG9mIHBhZ2lu
YXRlZCByZXN1bHRzLCB0aGlzIGlzIHRoZSB0b2tlbiB0aGF0IHdhcyByZXR1cm5lZCBpbiB0
aGUKIHByZXZpb3VzIExpc3RFbmdpbmVDb25maWdzUmVzcG9uc2UuIEl0IHNob3VsZCBiZSBj
b3BpZWQgaGVyZSB0byByZXRyaWV2ZQogdGhlIG5leHQgcGFnZSBvZiByZXNvdXJjZXMuIEVt
cHR5IHdpbGwgZ2l2ZSB0aGUgZmlyc3QgcGFnZSBvZgogTGlzdEVuZ2luZUNvbmZpZ3NSZXF1
ZXN0LCBhbmQgdGhlIGxhc3QgcGFnZSB3aWxsIHJldHVybiBhbiBlbXB0eQogcGFnZV90b2tl
bi4KCg0KBQQBAgIFEgTGAQIICg0KBQQBAgIBEgTGAQkTCg0KBQQBAgIDEgTGARYXCjoKBAQB
AgMSBMkBAhQaLCBTcGVjaWZ5IGEgZmlsdGVyIHRvIG5hcnJvdyBzZWFyY2ggcmVzdWx0cy4K
Cg0KBQQBAgMFEgTJAQIICg0KBQQBAgMBEgTJAQkPCg0KBQQBAgMDEgTJARITCjQKBAQBAgQS
BMwBAhYaJiBTcGVjaWZ5IGEgZmllbGQgdG8gdXNlIGZvciBvcmRlcmluZy4KCg0KBQQBAgQF
EgTMAQIICg0KBQQBAgQBEgTMAQkRCg0KBQQBAgQDEgTMARQVCj8KAgQCEgbQAQDaAQEaMSBS
ZXNwb25zZSBmb3IgcmV0cmlldmluZyBhIGxpc3Qgb2YgRW5naW5lQ29uZmlncwoKCwoDBAIB
EgTQAQghCi4KBAQCAgASBNIBAisaICBMaXN0IG9mIEVuZ2luZUNvbmZpZyByZXNvdXJjZXMK
Cg0KBQQCAgAEEgTSAQIKCg0KBQQCAgAGEgTSAQsXCg0KBQQCAgABEgTSARgmCg0KBQQCAgAD
EgTSASkqCpwBCgQEAgIBEgTWAQIdGo0BIFRoaXMgdG9rZW4gc2hvdWxkIGJlIHBhc3NlZCB0
byB0aGUgbmV4dCBMaXN0RW5naW5lQ29uZmlnc1JlcXVlc3QgdG8KIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2Ugb2YgRW5naW5lQ29uZmlncyAoZW1wdHkgaW5kaWNhdGVzIHdlIGFyZSBkb25l
KS4KCg0KBQQCAgEFEgTWAQIICg0KBQQCAgEBEgTWAQkYCg0KBQQCAgEDEgTWARscCjQKBAQC
AgISBNkBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQC
AgIEEgTZAQIKCg0KBQQCAgIFEgTZAQsRCg0KBQQCAgIBEgTZARIdCg0KBQQCAgIDEgTZASAh
CkgKAgQDEgbdAQDlAQEaOiBSZXF1ZXN0IGZvciByZXRyaWV2aW5nIGEgc3BlY2lmaWMgRW5n
aW5lQ29uZmlnIHJlc291cmNlLgoKCwoDBAMBEgTdAQgeCkEKBAQDAgASBt8BAuQBBBoxIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRW5naW5lQ29uZmlnCgoNCgUEAwIA
BRIE3wECCAoNCgUEAwIAARIE3wEJDQoNCgUEAwIAAxIE3wEQEQoPCgUEAwIACBIG3wES5AED
ChAKCAQDAgAInAgAEgTgAQQqChEKBwQDAgAInwgSBuEBBOMBBQo+CgIEBBIG6AEAhQIBGjAg
UmVxdWVzdCBmb3IgY3JlYXRpbmcgYW4gRW5naW5lQ29uZmlnIHJlc291cmNlLgoKCwoDBAQB
EgToAQghCksKBAQEAgASBuoBAu8BBBo7IFJlcXVpcmVkLiBUaGUgcGFyZW50IG9mIHRoZSBF
bmdpbmVDb25maWcgaXMgdGhlIEluc3RhbmNlLgoKDQoFBAQCAAUSBOoBAggKDQoFBAQCAAES
BOoBCQ8KDQoFBAQCAAMSBOoBEhMKDwoFBAQCAAgSBuoBFO8BAwoQCggEBAIACJwIABIE6wEE
KgoRCgcEBAIACJ8IEgbsAQTuAQUKPQoEBAQCARIE8gECRxovIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgaWQgb2YgdGhlIEVuZ2luZUNvbmZpZwoKDQoFBAQCAQUSBPIBAggKDQoFBAQCAQES
BPIBCRkKDQoFBAQCAQMSBPIBHB0KDQoFBAQCAQgSBPIBHkYKEAoIBAQCAQicCAASBPIBH0UK
QAoEBAQCAhIE9QECShoyIFJlcXVpcmVkLiBUaGUgRW5naW5lQ29uZmlnIHRoYXQgd2lsbCBi
ZSBjcmVhdGVkLgoKDQoFBAQCAgYSBPUBAg4KDQoFBAQCAgESBPUBDxwKDQoFBAQCAgMSBPUB
HyAKDQoFBAQCAggSBPUBIUkKEAoIBAQCAgicCAASBPUBIkgKjwYKBAQEAgMSBIQCAkEagAYg
T3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMu
IFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRy
eSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJl
cXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2ls
bAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZp
cnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJl
IHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91
dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0
CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGgg
dGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdu
b3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFj
Y2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVl
c3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVy
byBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAw
MDAwMDAwMDApLgoKDQoFBAQCAwUSBIQCAggKDQoFBAQCAwESBIQCCRMKDQoFBAQCAwMSBIQC
FhcKDQoFBAQCAwgSBIQCGEAKEAoIBAQCAwicCAASBIQCGT8KNAoCBAUSBogCAKMCARomIFJl
cXVlc3QgZm9yIHVwZGF0aW5nIGFuIEVuZ2luZUNvbmZpZwoKCwoDBAUBEgSIAgghCt4CCgQE
BQIAEgaOAgKPAi8azQIgT3B0aW9uYWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5
IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBFbmdpbmVDb25maWcgcmVz
b3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRh
dGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJl
cXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFz
ay4gSWYgdGhlCiB1c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxk
cyB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBI4CAhsKDQoFBAUCAAESBI4CHCcK
DQoFBAUCAAMSBI4CKisKDQoFBAUCAAgSBI8CBi4KEAoIBAUCAAicCAASBI8CBy0KdgoEBAUC
ARIEkwICShpoIFJlcXVpcmVkLiBUaGUgbmV3IHZhbHVlIG9mIHRoZSBFbmdpbmVDb25maWcg
ZmllbGRzIHRoYXQgd2lsbCBiZSB1cGRhdGVkCiBhY2NvcmRpbmcgdG8gdGhlIHVwZGF0ZV9t
YXNrLgoKDQoFBAUCAQYSBJMCAg4KDQoFBAUCAQESBJMCDxwKDQoFBAUCAQMSBJMCHyAKDQoF
BAUCAQgSBJMCIUkKEAoIBAUCAQicCAASBJMCIkgKjwYKBAQFAgISBKICAkEagAYgT3B0aW9u
YWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNp
ZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3Vy
IHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3Qg
aWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3Vh
cmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJl
cXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBt
YWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYg
eW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwg
dGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNh
bWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRo
ZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50
YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQg
bXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlE
IGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAw
MDApLgoKDQoFBAUCAgUSBKICAggKDQoFBAUCAgESBKICCRMKDQoFBAUCAgMSBKICFhcKDQoF
BAUCAggSBKICGEAKEAoIBAUCAgicCAASBKICGT8KNQoCBAYSBqYCAL0CARonIFJlcXVlc3Qg
Zm9yIGRlbGV0aW5nIGFuIEVuZ2luZUNvbmZpZy4KCgsKAwQGARIEpgIIIQpCCgQEBgIAEgao
AgKtAgQaMiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEVuZ2luZUNvbmZp
Zy4KCg0KBQQGAgAFEgSoAgIICg0KBQQGAgABEgSoAgkNCg0KBQQGAgADEgSoAhARCg8KBQQG
AgAIEgaoAhKtAgMKEAoIBAYCAAicCAASBKkCBCoKEQoHBAYCAAifCBIGqgIErAIFCo8GCgQE
BgIBEgS8AgJBGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYg
eW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwog
aWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBU
aGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVz
IGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNp
dHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVx
dWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhl
IHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9w
ZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlm
IHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNs
aWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRz
LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2Vw
dGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0w
MDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQGAgEFEgS8AgIICg0KBQQGAgEBEgS8AgkT
Cg0KBQQGAgEDEgS8AhYXCg0KBQQGAgEIEgS8AhhAChAKCAQGAgEInAgAEgS8Ahk/CjwKAgQH
EgbAAgDMAgEaLiBSZXF1ZXN0IGZvciBleHBvcnRpbmcgRW5naW5lQ29uZmlnIG1ldGFkYXRh
LgoKCwoDBAcBEgTAAggpCkIKBAQHAgASBsICAscCBBoyIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgRW5naW5lQ29uZmlnLgoKDQoFBAcCAAUSBMICAggKDQoFBAcCAAES
BMICCRYKDQoFBAcCAAMSBMICGRoKDwoFBAcCAAgSBsICG8cCAwoQCggEBwIACJwIABIEwwIE
KgoRCgcEBwIACJ8IEgbEAgTGAgUKTwoEBAcCARIGygICywIvGj8gUmVxdWlyZWQuIEJpZ1F1
ZXJ5IG91dHB1dCB3aGVyZSB0aGUgbWV0YWRhdGEgd2lsbCBiZSB3cml0dGVuLgoKDQoFBAcC
AQYSBMoCAhUKDQoFBAcCAQESBMoCFjUKDQoFBAcCAQMSBMoCODkKDQoFBAcCAQgSBMsCBi4K
EAoIBAcCAQicCAASBMsCBy0KOwoCBAgSBM8CAC0aLyBSZXNwb25zZSBmb3IgZXhwb3J0aW5n
IEVuZ2luZUNvbmZpZyBtZXRhZGF0YS4KCgsKAwQIARIEzwIIKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig ===
    # Fields for EngineConfig
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.EngineConfig.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.EngineConfig.State)
    # Field: engine_version Type: 9 ()
    # Field: tuning Type: 11 (.google.cloud.financialservices.v1.EngineConfig.Tuning)
    # Field: performance_target Type: 11 (.google.cloud.financialservices.v1.EngineConfig.PerformanceTarget)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)
    # Field: hyperparameter_source_type Type: 14 (.google.cloud.financialservices.v1.EngineConfig.HyperparameterSourceType)
    # Field: hyperparameter_source Type: 11 (.google.cloud.financialservices.v1.EngineConfig.HyperparameterSource)

# Enum: EngineConfig::State
our $EngineConfig_STATE_UNSPECIFIED = 0;
our $EngineConfig_CREATING = 1;
our $EngineConfig_ACTIVE = 2;
our $EngineConfig_UPDATING = 3;
our $EngineConfig_DELETING = 4;

# Enum: EngineConfig::HyperparameterSourceType
our $EngineConfig_HYPERPARAMETER_SOURCE_TYPE_UNSPECIFIED = 0;
our $EngineConfig_TUNING = 1;
our $EngineConfig_INHERITED = 2;

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest ===
    # Fields for ListEngineConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse ===
    # Fields for ListEngineConfigsResponse
    # Field: engine_configs Type: 11 (.google.cloud.financialservices.v1.EngineConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest ===
    # Fields for GetEngineConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest ===
    # Fields for CreateEngineConfigRequest
    # Field: parent Type: 9 ()
    # Field: engine_config_id Type: 9 ()
    # Field: engine_config Type: 11 (.google.cloud.financialservices.v1.EngineConfig)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest ===
    # Fields for UpdateEngineConfigRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: engine_config Type: 11 (.google.cloud.financialservices.v1.EngineConfig)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest ===
    # Fields for DeleteEngineConfigRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest ===
    # Fields for ExportEngineConfigMetadataRequest
    # Field: engine_config Type: 9 ()
    # Field: structured_metadata_destination Type: 11 (.google.cloud.financialservices.v1.BigQueryDestination)

# === Message: Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataResponse ===
    # Fields for ExportEngineConfigMetadataResponse

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::EngineConfig - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/engine_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::EngineConfig;

    my $msg = Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/engine_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig

The EngineConfig resource creates the configuration for training a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the EngineConfig.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/engineConfigs/{engine_config}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of creation of this resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of the most recent update of this resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::LabelsEntry>)

Labels

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::EngineConfig::State>)

Output only. State of the EngineConfig (creating, active, deleting, etc.)

=item * C<< $msg->engine_version() >> / C<< $msg->engine_version($value) >>

Type: C<String>

Required. The resource name of the EngineVersion used in this model tuning.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/engineVersions/{engine_version}`

=item * C<< $msg->tuning() >> / C<< $msg->tuning($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::Tuning>)

Optional. Configuration for tuning in creation of the EngineConfig.
This field is required if `hyperparameter_source.type` is not `INHERITED`,
and output-only otherwise.

=item * C<< $msg->performance_target() >> / C<< $msg->performance_target($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::PerformanceTarget>)

Optional. PerformanceTarget gives information on how the tuning and
training will be evaluated. This field is required if
`hyperparameter_source.type` is not `INHERITED`, and output-only otherwise.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Output only. The line of business (Retail/Commercial) this engine config is
used for. Determined by EngineVersion, cannot be set by user.

=item * C<< $msg->hyperparameter_source_type() >> / C<< $msg->hyperparameter_source_type($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::EngineConfig::HyperparameterSourceType>)

Optional. The origin of hyperparameters for the created EngineConfig. The
default is `TUNING`. In this case, the hyperparameters are selected as a
result of a
 tuning run.

=item * C<< $msg->hyperparameter_source() >> / C<< $msg->hyperparameter_source($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::HyperparameterSource>)

Optional. Configuration of hyperparameters source EngineConfig.

=back

=head3 Enum: EngineConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head3 Enum: EngineConfig::HyperparameterSourceType

=over 4

=item * C<HYPERPARAMETER_SOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<TUNING> => C<1>

=item * C<INHERITED> => C<2>

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest

Request for retrieving a paginated list of EngineConfig resources that
meet the specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the EngineConfig is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListEngineConfigsResponse. It should be copied here to retrieve
the next page of resources. Empty will give the first page of
ListEngineConfigsRequest, and the last page will return an empty
page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse

Response for retrieving a list of EngineConfigs

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine_configs() >> / C<< $msg->engine_configs($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig>)

List of EngineConfig resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListEngineConfigsRequest to
retrieve the next page of EngineConfigs (empty indicates we are done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest

Request for retrieving a specific EngineConfig resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the EngineConfig

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest

Request for creating an EngineConfig resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the EngineConfig is the Instance.

=item * C<< $msg->engine_config_id() >> / C<< $msg->engine_config_id($value) >>

Type: C<String>

Required. The resource id of the EngineConfig

=item * C<< $msg->engine_config() >> / C<< $msg->engine_config($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig>)

Required. The EngineConfig that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest

Request for updating an EngineConfig

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
EngineConfig resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->engine_config() >> / C<< $msg->engine_config($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig>)

Required. The new value of the EngineConfig fields that will be updated
according to the update_mask.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest

Request for deleting an EngineConfig.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the EngineConfig.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest

Request for exporting EngineConfig metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine_config() >> / C<< $msg->engine_config($value) >>

Type: C<String>

Required. The resource name of the EngineConfig.

=item * C<< $msg->structured_metadata_destination() >> / C<< $msg->structured_metadata_destination($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination>)

Required. BigQuery output where the metadata will be written.

=back

=head2 Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataResponse

Response for exporting EngineConfig metadata.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::EngineConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
