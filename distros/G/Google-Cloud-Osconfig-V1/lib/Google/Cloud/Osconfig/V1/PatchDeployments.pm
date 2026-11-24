package Google::Cloud::Osconfig::V1::PatchDeployments;

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
    eval { require Google::Cloud::Osconfig::V1::PatchJobs };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    eval { require Google::Type::Dayofweek };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvb3Njb25maWcvdjEvcGF0Y2hfZGVwbG95bWVudHMucHJvdG8SGGdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxopZ29vZ2xlL2Nsb3VkL29zY29uZmlnL3Yx
L3BhdGNoX2pvYnMucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxogZ29v
Z2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8aGmdvb2dsZS90eXBlL2RhdGV0aW1lLnByb3RvGhtnb29nbGUvdHlwZS9kYXlv
ZndlZWsucHJvdG8aG2dvb2dsZS90eXBlL3RpbWVvZmRheS5wcm90byKDCAoPUGF0Y2hEZXBs
b3ltZW50EhIKBG5hbWUYASABKAlSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SWwoPaW5zdGFuY2VfZmlsdGVyGAMgASgLMi0uZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLnYxLlBhdGNoSW5zdGFuY2VGaWx0ZXJCA+BBAlIOaW5zdGFuY2VGaWx0ZXISTQoM
cGF0Y2hfY29uZmlnGAQgASgLMiUuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLlBhdGNoQ29u
ZmlnQgPgQQFSC3BhdGNoQ29uZmlnEjoKCGR1cmF0aW9uGAUgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uQgPgQQFSCGR1cmF0aW9uElwKEW9uZV90aW1lX3NjaGVkdWxlGAYgASgL
MikuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLk9uZVRpbWVTY2hlZHVsZUID4EECSABSD29u
ZVRpbWVTY2hlZHVsZRJhChJyZWN1cnJpbmdfc2NoZWR1bGUYByABKAsyKy5nb29nbGUuY2xv
dWQub3Njb25maWcudjEuUmVjdXJyaW5nU2NoZWR1bGVCA+BBAkgAUhFyZWN1cnJpbmdTY2hl
ZHVsZRJACgtjcmVhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJLChFsYXN0X2V4ZWN1dGVfdGltZRgKIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IPbGFzdEV4ZWN1dGVUaW1lEkUK
B3JvbGxvdXQYCyABKAsyJi5nb29nbGUuY2xvdWQub3Njb25maWcudjEuUGF0Y2hSb2xsb3V0
QgPgQQFSB3JvbGxvdXQSSgoFc3RhdGUYDCABKA4yLy5nb29nbGUuY2xvdWQub3Njb25maWcu
djEuUGF0Y2hEZXBsb3ltZW50LlN0YXRlQgPgQQNSBXN0YXRlIjYKBVN0YXRlEhUKEVNUQVRF
X1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESCgoGUEFVU0VEEAI6ZOpBYQonb3Njb25maWcu
Z29vZ2xlYXBpcy5jb20vUGF0Y2hEZXBsb3ltZW50EjZwcm9qZWN0cy97cHJvamVjdH0vcGF0
Y2hEZXBsb3ltZW50cy97cGF0Y2hfZGVwbG95bWVudH1CCgoIc2NoZWR1bGUiVQoPT25lVGlt
ZVNjaGVkdWxlEkIKDGV4ZWN1dGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBAlILZXhlY3V0ZVRpbWUi7QUKEVJlY3VycmluZ1NjaGVkdWxlEjcKCXRpbWVf
em9uZRgBIAEoCzIVLmdvb2dsZS50eXBlLlRpbWVab25lQgPgQQJSCHRpbWVab25lEj4KCnN0
YXJ0X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFSCXN0YXJ0
VGltZRI6CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
AVIHZW5kVGltZRI7Cgt0aW1lX29mX2RheRgEIAEoCzIWLmdvb2dsZS50eXBlLlRpbWVPZkRh
eUID4EECUgl0aW1lT2ZEYXkSWAoJZnJlcXVlbmN5GAUgASgOMjUuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLnYxLlJlY3VycmluZ1NjaGVkdWxlLkZyZXF1ZW5jeUID4EECUglmcmVxdWVuY3kS
RwoGd2Vla2x5GAYgASgLMiguZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLldlZWtseVNjaGVk
dWxlQgPgQQJIAFIGd2Vla2x5EkoKB21vbnRobHkYByABKAsyKS5nb29nbGUuY2xvdWQub3Nj
b25maWcudjEuTW9udGhseVNjaGVkdWxlQgPgQQJIAFIHbW9udGhseRJLChFsYXN0X2V4ZWN1
dGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IPbGFzdEV4
ZWN1dGVUaW1lEksKEW5leHRfZXhlY3V0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUg9uZXh0RXhlY3V0ZVRpbWUiSgoJRnJlcXVlbmN5EhkKFUZSRVFV
RU5DWV9VTlNQRUNJRklFRBAAEgoKBldFRUtMWRABEgsKB01PTlRITFkQAhIJCgVEQUlMWRAD
QhEKD3NjaGVkdWxlX2NvbmZpZyJNCg5XZWVrbHlTY2hlZHVsZRI7CgtkYXlfb2Zfd2VlaxgB
IAEoDjIWLmdvb2dsZS50eXBlLkRheU9mV2Vla0ID4EECUglkYXlPZldlZWsioQEKD01vbnRo
bHlTY2hlZHVsZRJaChF3ZWVrX2RheV9vZl9tb250aBgBIAEoCzIoLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy52MS5XZWVrRGF5T2ZNb250aEID4EECSABSDndlZWtEYXlPZk1vbnRoEiIKCW1v
bnRoX2RheRgCIAEoBUID4EECSABSCG1vbnRoRGF5Qg4KDGRheV9vZl9tb250aCKZAQoOV2Vl
a0RheU9mTW9udGgSJgoMd2Vla19vcmRpbmFsGAEgASgFQgPgQQJSC3dlZWtPcmRpbmFsEjsK
C2RheV9vZl93ZWVrGAIgASgOMhYuZ29vZ2xlLnR5cGUuRGF5T2ZXZWVrQgPgQQJSCWRheU9m
V2VlaxIiCgpkYXlfb2Zmc2V0GAMgASgFQgPgQQFSCWRheU9mZnNldCL7AQocQ3JlYXRlUGF0
Y2hEZXBsb3ltZW50UmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIGcGFyZW50EjMKE3BhdGNoX2Rl
cGxveW1lbnRfaWQYAiABKAlCA+BBAlIRcGF0Y2hEZXBsb3ltZW50SWQSWQoQcGF0Y2hfZGVw
bG95bWVudBgDIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5QYXRjaERlcGxveW1l
bnRCA+BBAlIPcGF0Y2hEZXBsb3ltZW50ImAKGUdldFBhdGNoRGVwbG95bWVudFJlcXVlc3QS
QwoEbmFtZRgBIAEoCUIv4EEC+kEpCidvc2NvbmZpZy5nb29nbGVhcGlzLmNvbS9QYXRjaERl
cGxveW1lbnRSBG5hbWUisAEKG0xpc3RQYXRjaERlcGxveW1lbnRzUmVxdWVzdBJLCgZwYXJl
bnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20v
UHJvamVjdFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKeAQocTGlzdFBhdGNoRGVwbG95bWVu
dHNSZXNwb25zZRJWChFwYXRjaF9kZXBsb3ltZW50cxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy52MS5QYXRjaERlcGxveW1lbnRSEHBhdGNoRGVwbG95bWVudHMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuImMKHERlbGV0ZVBhdGNoRGVwbG95bWVu
dFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidvc2NvbmZpZy5nb29nbGVhcGlzLmNv
bS9QYXRjaERlcGxveW1lbnRSBG5hbWUiuwEKHFVwZGF0ZVBhdGNoRGVwbG95bWVudFJlcXVl
c3QSWQoQcGF0Y2hfZGVwbG95bWVudBgBIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52
MS5QYXRjaERlcGxveW1lbnRCA+BBAlIPcGF0Y2hEZXBsb3ltZW50EkAKC3VwZGF0ZV9tYXNr
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrImIK
G1BhdXNlUGF0Y2hEZXBsb3ltZW50UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ29z
Y29uZmlnLmdvb2dsZWFwaXMuY29tL1BhdGNoRGVwbG95bWVudFIEbmFtZSJjChxSZXN1bWVQ
YXRjaERlcGxveW1lbnRSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonb3Njb25maWcu
Z29vZ2xlYXBpcy5jb20vUGF0Y2hEZXBsb3ltZW50UgRuYW1lQr4BChxjb20uZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxQhBQYXRjaERlcGxveW1lbnRzWjhjbG91ZC5nb29nbGUuY29tL2dv
L29zY29uZmlnL2FwaXYxL29zY29uZmlncGI7b3Njb25maWdwYqoCGEdvb2dsZS5DbG91ZC5P
c0NvbmZpZy5WMcoCGEdvb2dsZVxDbG91ZFxPc0NvbmZpZ1xWMeoCG0dvb2dsZTo6Q2xvdWQ6
Ok9zQ29uZmlnOjpWMUqIXQoHEgUOANICAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAMwoJCgID
AxIDFQAoCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoJCgIDBhIDGAAkCgkKAgMHEgMZACUKCQoC
AwgSAxoAJQoICgEIEgMcADUKCQoCCCUSAxwANQoICgEIEgMdAE8KCQoCCAsSAx0ATwoICgEI
EgMeADEKCQoCCAgSAx4AMQoICgEIEgMfADUKCQoCCAESAx8ANQoICgEIEgMgADUKCQoCCCkS
AyAANQoICgEIEgMhADQKCQoCCC0SAyEANAr2AgoCBAASBCgAcQEa6QIgUGF0Y2ggZGVwbG95
bWVudHMgYXJlIGNvbmZpZ3VyYXRpb25zIHRoYXQgaW5kaXZpZHVhbCBwYXRjaCBqb2JzIHVz
ZSB0bwogY29tcGxldGUgYSBwYXRjaC4gVGhlc2UgY29uZmlndXJhdGlvbnMgaW5jbHVkZSBp
bnN0YW5jZSBmaWx0ZXIsIHBhY2thZ2UKIHJlcG9zaXRvcnkgc2V0dGluZ3MsIGFuZCBhIHNj
aGVkdWxlLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBhYm91dCBjcmVhdGluZyBhbmQKIG1hbmFn
aW5nIHBhdGNoIGRlcGxveW1lbnRzLCBzZWUgW1NjaGVkdWxpbmcgcGF0Y2gKIGpvYnNdKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3Mvb3MtcGF0Y2gtbWFuYWdlbWVu
dC9zY2hlZHVsZS1wYXRjaC1qb2JzKS4KCgoKAwQAARIDKAgXCgsKAwQABxIEKQIsBAoNCgUE
AAedCBIEKQIsBAo1CgQEAAQAEgQvAjkDGicgUmVwcmVzZW50cyBzdGF0ZSBvZiBwYXRjaCBw
ZXBsb3ltZW50LgoKDAoFBAAEAAESAy8HDApPCgYEAAQAAgASAzEEGhpAIFRoZSBkZWZhdWx0
IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVzZWQgaWYgdGhlIHN0YXRlIGlzIG9taXR0ZWQuCgoO
CgcEAAQAAgABEgMxBBUKDgoHBAAEAAIAAhIDMRgZCk8KBgQABAACARIDNAQPGkAgQWN0aXZl
IHZhbHVlIG1lYW5zIHRoYXQgcGF0Y2ggZGVwbG95bWVudCBnZW5lcmF0ZXMgUGF0Y2ggSm9i
cy4KCg4KBwQABAACAQESAzQECgoOCgcEAAQAAgECEgM0DQ4KkgEKBgQABAACAhIDOAQPGoIB
IFBhdXNlZCB2YWx1ZSBtZWFucyB0aGF0IHBhdGNoIGRlcGxveW1lbnQgZG9lcyBub3QgZ2Vu
ZXJhdGUKIFBhdGNoIGpvYnMuIFJlcXVpcmVzIHVzZXIgYWN0aW9uIHRvIG1vdmUgaW4gYW5k
IG91dCBmcm9tIHRoaXMgc3RhdGUuCgoOCgcEAAQAAgIBEgM4BAoKDgoHBAAEAAICAhIDOA0O
CvYBCgQEAAIAEgM/AhIa6AEgVW5pcXVlIG5hbWUgZm9yIHRoZSBwYXRjaCBkZXBsb3ltZW50
IHJlc291cmNlIGluIGEgcHJvamVjdC4gVGhlIHBhdGNoCiBkZXBsb3ltZW50IG5hbWUgaXMg
aW4gdGhlIGZvcm06CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L3BhdGNoRGVwbG95bWVudHMv
e3BhdGNoX2RlcGxveW1lbnRfaWR9YC4KIFRoaXMgZmllbGQgaXMgaWdub3JlZCB3aGVuIHlv
dSBjcmVhdGUgYSBuZXcgcGF0Y2ggZGVwbG95bWVudC4KCgwKBQQAAgAFEgM/AggKDAoFBAAC
AAESAz8JDQoMCgUEAAIAAxIDPxARCncKBAQAAgESA0MCQhpqIE9wdGlvbmFsLiBEZXNjcmlw
dGlvbiBvZiB0aGUgcGF0Y2ggZGVwbG95bWVudC4gTGVuZ3RoIG9mIHRoZSBkZXNjcmlwdGlv
biBpcwogbGltaXRlZCB0byAxMDI0IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDQwIICgwKBQQA
AgEBEgNDCRQKDAoFBAACAQMSA0MXGAoMCgUEAAIBCBIDQxlBCg8KCAQAAgEInAgAEgNDGkAK
MAoEBAACAhIERgJHLxoiIFJlcXVpcmVkLiBWTSBpbnN0YW5jZXMgdG8gcGF0Y2guCgoMCgUE
AAICBhIDRgIVCgwKBQQAAgIBEgNGFiUKDAoFBAACAgMSA0YoKQoMCgUEAAICCBIDRwYuCg8K
CAQAAgIInAgAEgNHBy0KPQoEBAACAxIDSgJIGjAgT3B0aW9uYWwuIFBhdGNoIGNvbmZpZ3Vy
YXRpb24gdGhhdCBpcyBhcHBsaWVkLgoKDAoFBAACAwYSA0oCDQoMCgUEAAIDARIDSg4aCgwK
BQQAAgMDEgNKHR4KDAoFBAACAwgSA0ofRwoPCggEAAIDCJwIABIDSiBGCl8KBAQAAgQSBE4C
Ty8aUSBPcHRpb25hbC4gRHVyYXRpb24gb2YgdGhlIHBhdGNoLiBBZnRlciB0aGUgZHVyYXRp
b24gZW5kcywgdGhlIHBhdGNoIHRpbWVzCiBvdXQuCgoMCgUEAAIEBhIDTgIaCgwKBQQAAgQB
EgNOGyMKDAoFBAACBAMSA04mJwoMCgUEAAIECBIDTwYuCg8KCAQAAgQInAgAEgNPBy0KJwoE
BAAIABIEUgJaAxoZIFNjaGVkdWxlIGZvciB0aGUgcGF0Y2guCgoMCgUEAAgAARIDUggQCjgK
BAQAAgUSBFQEVTEaKiBSZXF1aXJlZC4gU2NoZWR1bGUgYSBvbmUtdGltZSBleGVjdXRpb24u
CgoMCgUEAAIFBhIDVAQTCgwKBQQAAgUBEgNUFCUKDAoFBAACBQMSA1QoKQoMCgUEAAIFCBID
VQgwCg8KCAQAAgUInAgAEgNVCS8KOAoEBAACBhIEWARZMRoqIFJlcXVpcmVkLiBTY2hlZHVs
ZSByZWN1cnJpbmcgZXhlY3V0aW9ucy4KCgwKBQQAAgYGEgNYBBUKDAoFBAACBgESA1gWKAoM
CgUEAAIGAxIDWCssCgwKBQQAAgYIEgNZCDAKDwoIBAACBgicCAASA1kJLwqSAQoEBAACBxIE
XgJfMhqDASBPdXRwdXQgb25seS4gVGltZSB0aGUgcGF0Y2ggZGVwbG95bWVudCB3YXMgY3Jl
YXRlZC4gVGltZXN0YW1wIGlzIGluCiBbUkZDMzMzOV0oaHR0cHM6Ly93d3cuaWV0Zi5vcmcv
cmZjL3JmYzMzMzkudHh0KSB0ZXh0IGZvcm1hdC4KCgwKBQQAAgcGEgNeAhsKDAoFBAACBwES
A14cJwoMCgUEAAIHAxIDXiorCgwKBQQAAgcIEgNfBjEKDwoIBAACBwicCAASA18HMAqXAQoE
BAACCBIEYwJkMhqIASBPdXRwdXQgb25seS4gVGltZSB0aGUgcGF0Y2ggZGVwbG95bWVudCB3
YXMgbGFzdCB1cGRhdGVkLiBUaW1lc3RhbXAgaXMgaW4KIFtSRkMzMzM5XShodHRwczovL3d3
dy5pZXRmLm9yZy9yZmMvcmZjMzMzOS50eHQpIHRleHQgZm9ybWF0LgoKDAoFBAACCAYSA2MC
GwoMCgUEAAIIARIDYxwnCgwKBQQAAggDEgNjKisKDAoFBAACCAgSA2QGMQoPCggEAAIICJwI
ABIDZAcwCqYBCgQEAAIJEgRpAmoyGpcBIE91dHB1dCBvbmx5LiBUaGUgbGFzdCB0aW1lIGEg
cGF0Y2ggam9iIHdhcyBzdGFydGVkIGJ5IHRoaXMgZGVwbG95bWVudC4KIFRpbWVzdGFtcCBp
cyBpbiBbUkZDMzMzOV0oaHR0cHM6Ly93d3cuaWV0Zi5vcmcvcmZjL3JmYzMzMzkudHh0KSB0
ZXh0CiBmb3JtYXQuCgoMCgUEAAIJBhIDaQIbCgwKBQQAAgkBEgNpHC0KDAoFBAACCQMSA2kw
MgoMCgUEAAIJCBIDagYxCg8KCAQAAgkInAgAEgNqBzAKOwoEBAACChIDbQJFGi4gT3B0aW9u
YWwuIFJvbGxvdXQgc3RyYXRlZ3kgb2YgdGhlIHBhdGNoIGpvYi4KCgwKBQQAAgoGEgNtAg4K
DAoFBAACCgESA20PFgoMCgUEAAIKAxIDbRkbCgwKBQQAAgoIEgNtHEQKDwoIBAACCgicCAAS
A20dQwpCCgQEAAILEgNwAj8aNSBPdXRwdXQgb25seS4gQ3VycmVudCBzdGF0ZSBvZiB0aGUg
cGF0Y2ggZGVwbG95bWVudC4KCgwKBQQAAgsGEgNwAgcKDAoFBAACCwESA3AIDQoMCgUEAAIL
AxIDcBASCgwKBQQAAgsIEgNwEz4KDwoIBAACCwicCAASA3AUPQqKAQoCBAESBHUAeQEafiBT
ZXRzIHRoZSB0aW1lIGZvciBhIG9uZSB0aW1lIHBhdGNoIGRlcGxveW1lbnQuIFRpbWVzdGFt
cCBpcyBpbgogW1JGQzMzMzldKGh0dHBzOi8vd3d3LmlldGYub3JnL3JmYy9yZmMzMzM5LnR4
dCkgdGV4dCBmb3JtYXQuCgoKCgMEAQESA3UIFwo/CgQEAQIAEgR3AngvGjEgUmVxdWlyZWQu
IFRoZSBkZXNpcmVkIHBhdGNoIGpvYiBleGVjdXRpb24gdGltZS4KCgwKBQQBAgAGEgN3AhsK
DAoFBAECAAESA3ccKAoMCgUEAQIAAxIDdyssCgwKBQQBAgAIEgN4Bi4KDwoIBAECAAicCAAS
A3gHLQo9CgIEAhIFfAC1AQEaMCBTZXRzIHRoZSB0aW1lIGZvciByZWN1cnJpbmcgcGF0Y2gg
ZGVwbG95bWVudHMuCgoKCgMEAgESA3wIGQpMCgQEAgQAEgV+Ao0BAxo9IFNwZWNpZmllcyB0
aGUgZnJlcXVlbmN5IG9mIHRoZSByZWN1cnJpbmcgcGF0Y2ggZGVwbG95bWVudHMuCgoMCgUE
AgQAARIDfgcQCjkKBgQCBAACABIEgAEEHhopIEludmFsaWQuIEEgZnJlcXVlbmN5IG11c3Qg
YmUgc3BlY2lmaWVkLgoKDwoHBAIEAAIAARIEgAEEGQoPCgcEAgQAAgACEgSAARwdCmQKBgQC
BAACARIEhAEEDxpUIEluZGljYXRlcyB0aGF0IHRoZSBmcmVxdWVuY3kgb2YgcmVjdXJyZW5j
ZSBzaG91bGQgYmUgZXhwcmVzc2VkIGluIHRlcm1zCiBvZiB3ZWVrcy4KCg8KBwQCBAACAQES
BIQBBAoKDwoHBAIEAAIBAhIEhAENDgplCgYEAgQAAgISBIgBBBAaVSBJbmRpY2F0ZXMgdGhh
dCB0aGUgZnJlcXVlbmN5IG9mIHJlY3VycmVuY2Ugc2hvdWxkIGJlIGV4cHJlc3NlZCBpbiB0
ZXJtcwogb2YgbW9udGhzLgoKDwoHBAIEAAICARIEiAEECwoPCgcEAgQAAgICEgSIAQ4PCmMK
BgQCBAACAxIEjAEEDhpTIEluZGljYXRlcyB0aGF0IHRoZSBmcmVxdWVuY3kgb2YgcmVjdXJy
ZW5jZSBzaG91bGQgYmUgZXhwcmVzc2VkIGluIHRlcm1zCiBvZiBkYXlzLgoKDwoHBAIEAAID
ARIEjAEECQoPCgcEAgQAAgMCEgSMAQwNCp8BCgQEAgIAEgSRAQJOGpABIFJlcXVpcmVkLiBE
ZWZpbmVzIHRoZSB0aW1lIHpvbmUgdGhhdCBgdGltZV9vZl9kYXlgIGlzIHJlbGF0aXZlIHRv
LgogVGhlIHJ1bGVzIGZvciBkYXlsaWdodCBzYXZpbmcgdGltZSBhcmUgZGV0ZXJtaW5lZCBi
eSB0aGUgY2hvc2VuIHRpbWUgem9uZS4KCg0KBQQCAgAGEgSRAQIWCg0KBQQCAgABEgSRARcg
Cg0KBQQCAgADEgSRASMkCg0KBQQCAgAIEgSRASVNChAKCAQCAgAInAgAEgSRASZMCocBCgQE
AgIBEgaVAQKWAS8adyBPcHRpb25hbC4gVGhlIHRpbWUgdGhhdCB0aGUgcmVjdXJyaW5nIHNj
aGVkdWxlIGJlY29tZXMgZWZmZWN0aXZlLgogRGVmYXVsdHMgdG8gYGNyZWF0ZV90aW1lYCBv
ZiB0aGUgcGF0Y2ggZGVwbG95bWVudC4KCg0KBQQCAgEGEgSVAQIbCg0KBQQCAgEBEgSVARwm
Cg0KBQQCAgEDEgSVASkqCg0KBQQCAgEIEgSWAQYuChAKCAQCAgEInAgAEgSWAQctCm0KBAQC
AgISBpoBApsBLxpdIE9wdGlvbmFsLiBUaGUgZW5kIHRpbWUgYXQgd2hpY2ggYSByZWN1cnJp
bmcgcGF0Y2ggZGVwbG95bWVudCBzY2hlZHVsZSBpcyBubwogbG9uZ2VyIGFjdGl2ZS4KCg0K
BQQCAgIGEgSaAQIbCg0KBQQCAgIBEgSaARwkCg0KBQQCAgIDEgSaAScoCg0KBQQCAgIIEgSb
AQYuChAKCAQCAgIInAgAEgSbAQctCkoKBAQCAgMSBp4BAp8BLxo6IFJlcXVpcmVkLiBUaW1l
IG9mIHRoZSBkYXkgdG8gcnVuIGEgcmVjdXJyaW5nIGRlcGxveW1lbnQuCgoNCgUEAgIDBhIE
ngECFwoNCgUEAgIDARIEngEYIwoNCgUEAgIDAxIEngEmJwoNCgUEAgIDCBIEnwEGLgoQCggE
AgIDCJwIABIEnwEHLQpICgQEAgIEEgSiAQJDGjogUmVxdWlyZWQuIFRoZSBmcmVxdWVuY3kg
dW5pdCBvZiB0aGlzIHJlY3VycmluZyBzY2hlZHVsZS4KCg0KBQQCAgQGEgSiAQILCg0KBQQC
AgQBEgSiAQwVCg0KBQQCAgQDEgSiARgZCg0KBQQCAgQIEgSiARpCChAKCAQCAgQInAgAEgSi
ARtBCmMKBAQCCAASBqYBAqwBAxpTIENvbmZpZ3VyYXRpb25zIGZvciB0aGlzIHJlY3Vycmlu
ZyBzY2hlZHVsZS4KIENvbmZpZ3VyYXRpb25zIG11c3QgbWF0Y2ggZnJlcXVlbmN5LgoKDQoF
BAIIAAESBKYBCBcKOgoEBAICBRIEqAEERxosIFJlcXVpcmVkLiBTY2hlZHVsZSB3aXRoIHdl
ZWtseSBleGVjdXRpb25zLgoKDQoFBAICBQYSBKgBBBIKDQoFBAICBQESBKgBExkKDQoFBAIC
BQMSBKgBHB0KDQoFBAICBQgSBKgBHkYKEAoIBAICBQicCAASBKgBH0UKOwoEBAICBhIEqwEE
SRotIFJlcXVpcmVkLiBTY2hlZHVsZSB3aXRoIG1vbnRobHkgZXhlY3V0aW9ucy4KCg0KBQQC
AgYGEgSrAQQTCg0KBQQCAgYBEgSrARQbCg0KBQQCAgYDEgSrAR4fCg0KBQQCAgYIEgSrASBI
ChAKCAQCAgYInAgAEgSrASFHCkwKBAQCAgcSBq8BArABMho8IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB0aGUgbGFzdCBwYXRjaCBqb2IgcmFuIHN1Y2Nlc3NmdWxseS4KCg0KBQQCAgcGEgSv
AQIbCg0KBQQCAgcBEgSvARwtCg0KBQQCAgcDEgSvATAxCg0KBQQCAgcIEgSwAQYxChAKCAQC
AgcInAgAEgSwAQcwCk8KBAQCAggSBrMBArQBMho/IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0
aGUgbmV4dCBwYXRjaCBqb2IgaXMgc2NoZWR1bGVkIHRvIHJ1bi4KCg0KBQQCAggGEgSzAQIb
Cg0KBQQCAggBEgSzARwtCg0KBQQCAggDEgSzATAyCg0KBQQCAggIEgS0AQYxChAKCAQCAggI
nAgAEgS0AQcwCi0KAgQDEga4AQC8AQEaHyBSZXByZXNlbnRzIGEgd2Vla2x5IHNjaGVkdWxl
LgoKCwoDBAMBEgS4AQgWCiwKBAQDAgASBroBArsBLxocIFJlcXVpcmVkLiBEYXkgb2YgdGhl
IHdlZWsuCgoNCgUEAwIABhIEugECFwoNCgUEAwIAARIEugEYIwoNCgUEAwIAAxIEugEmJwoN
CgUEAwIACBIEuwEGLgoQCggEAwIACJwIABIEuwEHLQqdAQoCBAQSBsABAM0BARqOASBSZXBy
ZXNlbnRzIGEgbW9udGhseSBzY2hlZHVsZS4gQW4gZXhhbXBsZSBvZiBhIHZhbGlkIG1vbnRo
bHkgc2NoZWR1bGUgaXMKICJvbiB0aGUgdGhpcmQgVHVlc2RheSBvZiB0aGUgbW9udGgiIG9y
ICJvbiB0aGUgMTV0aCBvZiB0aGUgbW9udGgiLgoKCwoDBAQBEgTAAQgXCiUKBAQECAASBsIB
AswBAxoVIE9uZSBkYXkgaW4gYSBtb250aC4KCg0KBQQECAABEgTCAQgUCjAKBAQEAgASBsQB
BMUBMRogIFJlcXVpcmVkLiBXZWVrIGRheSBpbiBhIG1vbnRoLgoKDQoFBAQCAAYSBMQBBBIK
DQoFBAQCAAESBMQBEyQKDQoFBAQCAAMSBMQBJygKDQoFBAQCAAgSBMUBCDAKEAoIBAQCAAic
CAASBMUBCS8KlwIKBAQEAgESBMsBBEEaiAIgUmVxdWlyZWQuIE9uZSBkYXkgb2YgdGhlIG1v
bnRoLiAxLTMxIGluZGljYXRlcyB0aGUgMXN0IHRvIHRoZSAzMXN0IGRheS4KIC0xIGluZGlj
YXRlcyB0aGUgbGFzdCBkYXkgb2YgdGhlIG1vbnRoLiBNb250aHMgd2l0aG91dCB0aGUgdGFy
Z2V0IGRheQogd2lsbCBiZSBza2lwcGVkLiBGb3IgZXhhbXBsZSwgYSBzY2hlZHVsZSB0byBy
dW4gImV2ZXJ5IG1vbnRoIG9uIHRoZSAzMXN0Igogd2lsbCBub3QgcnVuIGluIEZlYnJ1YXJ5
LCBBcHJpbCwgSnVuZSwgZXRjLgoKDQoFBAQCAQUSBMsBBAkKDQoFBAQCAQESBMsBChMKDQoF
BAQCAQMSBMsBFhcKDQoFBAQCAQgSBMsBGEAKEAoIBAQCAQicCAASBMsBGT8KUwoCBAUSBtAB
AOEBARpFIFJlcHJlc2VudHMgb25lIHdlZWsgZGF5IGluIGEgbW9udGguIEFuIGV4YW1wbGUg
aXMgInRoZSA0dGggU3VuZGF5Ii4KCgsKAwQFARIE0AEIFgqLAQoEBAUCABIE0wECQhp9IFJl
cXVpcmVkLiBXZWVrIG51bWJlciBpbiBhIG1vbnRoLiAxLTQgaW5kaWNhdGVzIHRoZSAxc3Qg
dG8gNHRoIHdlZWsgb2YgdGhlCiBtb250aC4gLTEgaW5kaWNhdGVzIHRoZSBsYXN0IHdlZWsg
b2YgdGhlIG1vbnRoLgoKDQoFBAUCAAUSBNMBAgcKDQoFBAUCAAESBNMBCBQKDQoFBAUCAAMS
BNMBFxgKDQoFBAUCAAgSBNMBGUEKEAoIBAUCAAicCAASBNMBGkAKLgoEBAUCARIG1gEC1wEv
Gh4gUmVxdWlyZWQuIEEgZGF5IG9mIHRoZSB3ZWVrLgoKDQoFBAUCAQYSBNYBAhcKDQoFBAUC
AQESBNYBGCMKDQoFBAUCAQMSBNYBJicKDQoFBAUCAQgSBNcBBi4KEAoIBAUCAQicCAASBNcB
By0KlAQKBAQFAgISBOABAkAahQQgT3B0aW9uYWwuIFJlcHJlc2VudHMgdGhlIG51bWJlciBv
ZiBkYXlzIGJlZm9yZSBvciBhZnRlciB0aGUgZ2l2ZW4gd2VlayBkYXkKIG9mIG1vbnRoIHRo
YXQgdGhlIHBhdGNoIGRlcGxveW1lbnQgaXMgc2NoZWR1bGVkIGZvci4gRm9yIGV4YW1wbGUg
aWYKIGB3ZWVrX29yZGluYWxgIGFuZCBgZGF5X29mX3dlZWtgIHZhbHVlcyBwb2ludCB0byB0
aGUgc2Vjb25kIGRheSBvZiB0aGUKIG1vbnRoIGFuZCB0aGlzIGBkYXlfb2Zmc2V0YCB2YWx1
ZSBpcyBzZXQgdG8gYDNgLCB0aGUgcGF0Y2ggZGVwbG95bWVudCB0YWtlcwogcGxhY2UgdGhy
ZWUgZGF5cyBhZnRlciB0aGUgc2Vjb25kIFR1ZXNkYXkgb2YgdGhlIG1vbnRoLiBJZiB0aGlz
IHZhbHVlIGlzCiBuZWdhdGl2ZSwgZm9yIGV4YW1wbGUgLTUsIHRoZSBwYXRjaGVzIGFyZSBk
ZXBsb3llZCBmaXZlIGRheXMgYmVmb3JlIGJlZm9yZQogdGhlIHNlY29uZCBUdWVzZGF5IG9m
IHRoZSBtb250aC4gQWxsb3dlZCB2YWx1ZXMgYXJlIGluIHJhbmdlIFstMzAsIDMwXS4KCg0K
BQQFAgIFEgTgAQIHCg0KBQQFAgIBEgTgAQgSCg0KBQQFAgIDEgTgARUWCg0KBQQFAgIIEgTg
ARc/ChAKCAQFAgIInAgAEgTgARg+CkIKAgQGEgbkAQD5AQEaNCBBIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgY3JlYXRpbmcgYSBwYXRjaCBkZXBsb3ltZW50LgoKCwoDBAYBEgTkAQgkCmQKBAQG
AgASBucBAuwBBBpUIFJlcXVpcmVkLiBUaGUgcHJvamVjdCB0byBhcHBseSB0aGlzIHBhdGNo
IGRlcGxveW1lbnQgdG8gaW4gdGhlIGZvcm0KIGBwcm9qZWN0cy8qYC4KCg0KBQQGAgAFEgTn
AQIICg0KBQQGAgABEgTnAQkPCg0KBQQGAgADEgTnARITCg8KBQQGAgAIEgbnARTsAQMKEAoI
BAYCAAicCAASBOgBBCoKEQoHBAYCAAifCBIG6QEE6wEFCscCCgQEBgIBEgT1AQJKGrgCIFJl
cXVpcmVkLiBBIG5hbWUgZm9yIHRoZSBwYXRjaCBkZXBsb3ltZW50IGluIHRoZSBwcm9qZWN0
LiBXaGVuIGNyZWF0aW5nIGEKIG5hbWUgdGhlIGZvbGxvd2luZyBydWxlcyBhcHBseToKICog
TXVzdCBjb250YWluIG9ubHkgbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMsIGFuZCBoeXBo
ZW5zLgogKiBNdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAqIE11c3QgYmUgYmV0d2VlbiAx
LTYzIGNoYXJhY3RlcnMuCiAqIE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3IgYSBsZXR0ZXIu
CiAqIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcHJvamVjdC4KCg0KBQQGAgEFEgT1AQII
Cg0KBQQGAgEBEgT1AQkcCg0KBQQGAgEDEgT1AR8gCg0KBQQGAgEIEgT1ASFJChAKCAQGAgEI
nAgAEgT1ASJICjkKBAQGAgISBPgBAlAaKyBSZXF1aXJlZC4gVGhlIHBhdGNoIGRlcGxveW1l
bnQgdG8gY3JlYXRlLgoKDQoFBAYCAgYSBPgBAhEKDQoFBAYCAgESBPgBEiIKDQoFBAYCAgMS
BPgBJSYKDQoFBAYCAggSBPgBJ08KEAoIBAYCAgicCAASBPgBKE4KRAoCBAcSBvwBAIUCARo2
IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXRyaWV2aW5nIGEgcGF0Y2ggZGVwbG95bWVudC4K
CgsKAwQHARIE/AEIIQpzCgQEBwIAEgb/AQKEAgQaYyBSZXF1aXJlZC4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIHBhdGNoIGRlcGxveW1lbnQgaW4gdGhlIGZvcm0KIGBwcm9qZWN0cy8q
L3BhdGNoRGVwbG95bWVudHMvKmAuCgoNCgUEBwIABRIE/wECCAoNCgUEBwIAARIE/wEJDQoN
CgUEBwIAAxIE/wEQEQoPCgUEBwIACBIG/wEShAIDChAKCAQHAgAInAgAEgSAAgQqChEKBwQH
AgAInwgSBoECBIMCBQpACgIECBIGiAIAmQIBGjIgQSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGxp
c3RpbmcgcGF0Y2ggZGVwbG95bWVudHMuCgoLCgMECAESBIgCCCMKVQoEBAgCABIGigICjwIE
GkUgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJlbnQgaW4gdGhlIGZv
cm0gYHByb2plY3RzLypgLgoKDQoFBAgCAAUSBIoCAggKDQoFBAgCAAESBIoCCQ8KDQoFBAgC
AAMSBIoCEhMKDwoFBAgCAAgSBooCFI8CAwoQCggECAIACJwIABIEiwIEKgoRCgcECAIACJ8I
EgaMAgSOAgUKXQoEBAgCARIEkwICPxpPIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIg
b2YgcGF0Y2ggZGVwbG95bWVudHMgdG8gcmV0dXJuLiBEZWZhdWx0IGlzCiAxMDAuCgoNCgUE
CAIBBRIEkwICBwoNCgUECAIBARIEkwIIEQoNCgUECAIBAxIEkwIUFQoNCgUECAIBCBIEkwIW
PgoQCggECAIBCJwIABIEkwIXPQqdAQoEBAgCAhIEmAICQRqOASBPcHRpb25hbC4gQSBwYWdp
bmF0aW9uIHRva2VuIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRvCiBMaXN0UGF0
Y2hEZXBsb3ltZW50cyB0aGF0IGluZGljYXRlcyB3aGVyZSB0aGlzIGxpc3Rpbmcgc2hvdWxk
IGNvbnRpbnVlCiBmcm9tLgoKDQoFBAgCAgUSBJgCAggKDQoFBAgCAgESBJgCCRMKDQoFBAgC
AgMSBJgCFhcKDQoFBAgCAggSBJgCGEAKEAoIBAgCAgicCAASBJgCGT8KQQoCBAkSBpwCAKMC
ARozIEEgcmVzcG9uc2UgbWVzc2FnZSBmb3IgbGlzdGluZyBwYXRjaCBkZXBsb3ltZW50cy4K
CgsKAwQJARIEnAIIJAouCgQECQIAEgSeAgIxGiAgVGhlIGxpc3Qgb2YgcGF0Y2ggZGVwbG95
bWVudHMuCgoNCgUECQIABBIEngICCgoNCgUECQIABhIEngILGgoNCgUECQIAARIEngIbLAoN
CgUECQIAAxIEngIvMApfCgQECQIBEgSiAgIdGlEgQSBwYWdpbmF0aW9uIHRva2VuIHRoYXQg
Y2FuIGJlIHVzZWQgdG8gZ2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcGF0Y2gKIGRlcGxveW1lbnRz
LgoKDQoFBAkCAQUSBKICAggKDQoFBAkCAQESBKICCRgKDQoFBAkCAQMSBKICGxwKQgoCBAoS
BqYCAK8CARo0IEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIHBhdGNoIGRlcGxv
eW1lbnQuCgoLCgMECgESBKYCCCQKcwoEBAoCABIGqQICrgIEGmMgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXRjaCBkZXBsb3ltZW50IGluIHRoZSBmb3JtCiBgcHJv
amVjdHMvKi9wYXRjaERlcGxveW1lbnRzLypgLgoKDQoFBAoCAAUSBKkCAggKDQoFBAoCAAES
BKkCCQ0KDQoFBAoCAAMSBKkCEBEKDwoFBAoCAAgSBqkCEq4CAwoQCggECgIACJwIABIEqgIE
KgoRCgcECgIACJ8IEgarAgStAgUKQgoCBAsSBrICALoCARo0IEEgcmVxdWVzdCBtZXNzYWdl
IGZvciB1cGRhdGluZyBhIHBhdGNoIGRlcGxveW1lbnQuCgoLCgMECwESBLICCCQKOQoEBAsC
ABIEtAICUBorIFJlcXVpcmVkLiBUaGUgcGF0Y2ggZGVwbG95bWVudCB0byBVcGRhdGUuCgoN
CgUECwIABhIEtAICEQoNCgUECwIAARIEtAISIgoNCgUECwIAAxIEtAIlJgoNCgUECwIACBIE
tAInTwoQCggECwIACJwIABIEtAIoTgptCgQECwIBEga4AgK5Ai8aXSBPcHRpb25hbC4gRmll
bGQgbWFzayB0aGF0IGNvbnRyb2xzIHdoaWNoIGZpZWxkcyBvZiB0aGUgcGF0Y2ggZGVwbG95
bWVudAogc2hvdWxkIGJlIHVwZGF0ZWQuCgoNCgUECwIBBhIEuAICGwoNCgUECwIBARIEuAIc
JwoNCgUECwIBAxIEuAIqKwoNCgUECwIBCBIEuQIGLgoQCggECwIBCJwIABIEuQIHLQpBCgIE
DBIGvQIAxgIBGjMgQSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHBhdXNpbmcgYSBwYXRjaCBkZXBs
b3ltZW50LgoKCwoDBAwBEgS9AggjCnMKBAQMAgASBsACAsUCBBpjIFJlcXVpcmVkLiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgcGF0Y2ggZGVwbG95bWVudCBpbiB0aGUgZm9ybQogYHBy
b2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qYC4KCg0KBQQMAgAFEgTAAgIICg0KBQQMAgAB
EgTAAgkNCg0KBQQMAgADEgTAAhARCg8KBQQMAgAIEgbAAhLFAgMKEAoIBAwCAAicCAASBMEC
BCoKEQoHBAwCAAifCBIGwgIExAIFCkIKAgQNEgbJAgDSAgEaNCBBIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgcmVzdW1pbmcgYSBwYXRjaCBkZXBsb3ltZW50LgoKCwoDBA0BEgTJAggkCnMKBAQN
AgASBswCAtECBBpjIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcGF0Y2gg
ZGVwbG95bWVudCBpbiB0aGUgZm9ybQogYHByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8q
YC4KCg0KBQQNAgAFEgTMAgIICg0KBQQNAgABEgTMAgkNCg0KBQQNAgADEgTMAhARCg8KBQQN
AgAIEgbMAhLRAgMKEAoIBA0CAAicCAASBM0CBCoKEQoHBA0CAAifCBIGzgIE0AIFYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment ===
    # Fields for PatchDeployment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: instance_filter Type: 11 (.google.cloud.osconfig.v1.PatchInstanceFilter)
    # Field: patch_config Type: 11 (.google.cloud.osconfig.v1.PatchConfig)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: one_time_schedule Type: 11 (.google.cloud.osconfig.v1.OneTimeSchedule)
    # Field: recurring_schedule Type: 11 (.google.cloud.osconfig.v1.RecurringSchedule)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_execute_time Type: 11 (.google.protobuf.Timestamp)
    # Field: rollout Type: 11 (.google.cloud.osconfig.v1.PatchRollout)
    # Field: state Type: 14 (.google.cloud.osconfig.v1.PatchDeployment.State)

# Enum: PatchDeployment::State
our $PatchDeployment_STATE_UNSPECIFIED = 0;
our $PatchDeployment_ACTIVE = 1;
our $PatchDeployment_PAUSED = 2;

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule ===
    # Fields for OneTimeSchedule
    # Field: execute_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule ===
    # Fields for RecurringSchedule
    # Field: time_zone Type: 11 (.google.type.TimeZone)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: time_of_day Type: 11 (.google.type.TimeOfDay)
    # Field: frequency Type: 14 (.google.cloud.osconfig.v1.RecurringSchedule.Frequency)
    # Field: weekly Type: 11 (.google.cloud.osconfig.v1.WeeklySchedule)
    # Field: monthly Type: 11 (.google.cloud.osconfig.v1.MonthlySchedule)
    # Field: last_execute_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_execute_time Type: 11 (.google.protobuf.Timestamp)

# Enum: RecurringSchedule::Frequency
our $RecurringSchedule_FREQUENCY_UNSPECIFIED = 0;
our $RecurringSchedule_WEEKLY = 1;
our $RecurringSchedule_MONTHLY = 2;
our $RecurringSchedule_DAILY = 3;

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule ===
    # Fields for WeeklySchedule
    # Field: day_of_week Type: 14 (.google.type.DayOfWeek)

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule ===
    # Fields for MonthlySchedule
    # Field: week_day_of_month Type: 11 (.google.cloud.osconfig.v1.WeekDayOfMonth)
    # Field: month_day Type: 5 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth ===
    # Fields for WeekDayOfMonth
    # Field: week_ordinal Type: 5 ()
    # Field: day_of_week Type: 14 (.google.type.DayOfWeek)
    # Field: day_offset Type: 5 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest ===
    # Fields for CreatePatchDeploymentRequest
    # Field: parent Type: 9 ()
    # Field: patch_deployment_id Type: 9 ()
    # Field: patch_deployment Type: 11 (.google.cloud.osconfig.v1.PatchDeployment)

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest ===
    # Fields for GetPatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest ===
    # Fields for ListPatchDeploymentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse ===
    # Fields for ListPatchDeploymentsResponse
    # Field: patch_deployments Type: 11 (.google.cloud.osconfig.v1.PatchDeployment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest ===
    # Fields for DeletePatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest ===
    # Fields for UpdatePatchDeploymentRequest
    # Field: patch_deployment Type: 11 (.google.cloud.osconfig.v1.PatchDeployment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest ===
    # Fields for PausePatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest ===
    # Fields for ResumePatchDeploymentRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1::PatchDeployments - Compiled Protocol Buffers messages for google/cloud/osconfig/v1/patch_deployments.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1::PatchDeployments;

    my $msg = Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment->new({
        name => $name,
        description => $description,
        instance_filter => $instance_filter,
        patch_config => $patch_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1/patch_deployments.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment

Patch deployments are configurations that individual patch jobs use to
complete a patch. These configurations include instance filter, package
repository settings, and a schedule. For more information about creating and
managing patch deployments, see [Scheduling patch
jobs](https://cloud.google.com/compute/docs/os-patch-management/schedule-patch-jobs).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Unique name for the patch deployment resource in a project. The patch
deployment name is in the form:
`projects/{project_id}/patchDeployments/{patch_deployment_id}`.
This field is ignored when you create a new patch deployment.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the patch deployment. Length of the description is
limited to 1024 characters.

=item * C<< $msg->instance_filter() >> / C<< $msg->instance_filter($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchJobs::PatchInstanceFilter>)

Required. VM instances to patch.

=item * C<< $msg->patch_config() >> / C<< $msg->patch_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchJobs::PatchConfig>)

Optional. Patch configuration that is applied.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Duration of the patch. After the duration ends, the patch times
out.

=item * C<< $msg->one_time_schedule() >> / C<< $msg->one_time_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule>)

Required. Schedule a one-time execution.

=item * C<< $msg->recurring_schedule() >> / C<< $msg->recurring_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule>)

Required. Schedule recurring executions.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the patch deployment was created. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the patch deployment was last updated. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

=item * C<< $msg->last_execute_time() >> / C<< $msg->last_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time a patch job was started by this deployment.
Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text
format.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchJobs::PatchRollout>)

Optional. Rollout strategy of the patch job.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1::PatchDeployment::State>)

Output only. Current state of the patch deployment.

=back

=head3 Enum: PatchDeployment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<PAUSED> => C<2>

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule

Sets the time for a one time patch deployment. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execute_time() >> / C<< $msg->execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The desired patch job execution time.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule

Sets the time for recurring patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

Required. Defines the time zone that `time_of_day` is relative to.
The rules for daylight saving time are determined by the chosen time zone.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The time that the recurring schedule becomes effective.
Defaults to `create_time` of the patch deployment.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The end time at which a recurring patch deployment schedule is no
longer active.

=item * C<< $msg->time_of_day() >> / C<< $msg->time_of_day($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Required. Time of the day to run a recurring deployment.

=item * C<< $msg->frequency() >> / C<< $msg->frequency($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1::RecurringSchedule::Frequency>)

Required. The frequency unit of this recurring schedule.

=item * C<< $msg->weekly() >> / C<< $msg->weekly($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule>)

Required. Schedule with weekly executions.

=item * C<< $msg->monthly() >> / C<< $msg->monthly($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule>)

Required. Schedule with monthly executions.

=item * C<< $msg->last_execute_time() >> / C<< $msg->last_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the last patch job ran successfully.

=item * C<< $msg->next_execute_time() >> / C<< $msg->next_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the next patch job is scheduled to run.

=back

=head3 Enum: RecurringSchedule::Frequency

=over 4

=item * C<FREQUENCY_UNSPECIFIED> => C<0>

=item * C<WEEKLY> => C<1>

=item * C<MONTHLY> => C<2>

=item * C<DAILY> => C<3>

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule

Represents a weekly schedule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->day_of_week() >> / C<< $msg->day_of_week($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Required. Day of the week.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule

Represents a monthly schedule. An example of a valid monthly schedule is
"on the third Tuesday of the month" or "on the 15th of the month".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->week_day_of_month() >> / C<< $msg->week_day_of_month($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth>)

Required. Week day in a month.

=item * C<< $msg->month_day() >> / C<< $msg->month_day($value) >>

Type: C<Int32>

Required. One day of the month. 1-31 indicates the 1st to the 31st day.
-1 indicates the last day of the month. Months without the target day
will be skipped. For example, a schedule to run "every month on the 31st"
will not run in February, April, June, etc.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth

Represents one week day in a month. An example is "the 4th Sunday".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->week_ordinal() >> / C<< $msg->week_ordinal($value) >>

Type: C<Int32>

Required. Week number in a month. 1-4 indicates the 1st to 4th week of the
month. -1 indicates the last week of the month.

=item * C<< $msg->day_of_week() >> / C<< $msg->day_of_week($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Required. A day of the week.

=item * C<< $msg->day_offset() >> / C<< $msg->day_offset($value) >>

Type: C<Int32>

Optional. Represents the number of days before or after the given week day
of month that the patch deployment is scheduled for. For example if
`week_ordinal` and `day_of_week` values point to the second day of the
month and this `day_offset` value is set to `3`, the patch deployment takes
place three days after the second Tuesday of the month. If this value is
negative, for example -5, the patches are deployed five days before before
the second Tuesday of the month. Allowed values are in range [-30, 30].

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest

A request message for creating a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to apply this patch deployment to in the form
`projects/*`.

=item * C<< $msg->patch_deployment_id() >> / C<< $msg->patch_deployment_id($value) >>

Type: C<String>

Required. A name for the patch deployment in the project. When creating a
name the following rules apply:
* Must contain only lowercase letters, numbers, and hyphens.
* Must start with a letter.
* Must be between 1-63 characters.
* Must end with a number or a letter.
* Must be unique within the project.

=item * C<< $msg->patch_deployment() >> / C<< $msg->patch_deployment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment>)

Required. The patch deployment to create.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest

A request message for retrieving a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest

A request message for listing patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the parent in the form `projects/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of patch deployments to return. Default is
100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
ListPatchDeployments that indicates where this listing should continue
from.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse

A response message for listing patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_deployments() >> / C<< $msg->patch_deployments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment>)

The list of patch deployments.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token that can be used to get the next page of patch
deployments.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest

A request message for deleting a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest

A request message for updating a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_deployment() >> / C<< $msg->patch_deployment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment>)

Required. The patch deployment to Update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask that controls which fields of the patch deployment
should be updated.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest

A request message for pausing a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest

A request message for resuming a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1::PatchDeployments::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
