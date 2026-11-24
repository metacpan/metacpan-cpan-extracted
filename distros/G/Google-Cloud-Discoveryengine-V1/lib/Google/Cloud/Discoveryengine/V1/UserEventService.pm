package Google::Cloud::Discoveryengine::V1::UserEventService;

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
    eval { require Google::Api::Httpbody };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Discoveryengine::V1::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1::PurgeConfig };
    eval { require Google::Cloud::Discoveryengine::V1::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfZXZlbnRfc2VydmljZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvaHR0cGJvZHkucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aM2dvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvaW1w
b3J0X2NvbmZpZy5wcm90bxoyZ29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MS9wdXJn
ZV9jb25maWcucHJvdG8aMGdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvdXNlcl9l
dmVudC5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8i5gEKFVdy
aXRlVXNlckV2ZW50UmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50ElMKCnVzZXJfZXZlbnQY
AiABKAsyKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJFdmVudEID4EEC
SABSCXVzZXJFdmVudIgBARIfCgt3cml0ZV9hc3luYxgDIAEoCFIKd3JpdGVBc3luY0INCgtf
dXNlcl9ldmVudCLFAQoXQ29sbGVjdFVzZXJFdmVudFJlcXVlc3QSSAoGcGFyZW50GAEgASgJ
QjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSBnBh
cmVudBIiCgp1c2VyX2V2ZW50GAIgASgJQgPgQQJSCXVzZXJFdmVudBIVCgN1cmkYAyABKAlI
AFIDdXJpiAEBEhUKA2V0cxgEIAEoA0gBUgNldHOIAQFCBgoEX3VyaUIGCgRfZXRzMqsOChBV
c2VyRXZlbnRTZXJ2aWNlEvACCg5Xcml0ZVVzZXJFdmVudBI2Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuV3JpdGVVc2VyRXZlbnRSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5Vc2VyRXZlbnQi+QGC0+STAvIBIkEvdjEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50czp3cml0ZToKdXNl
cl9ldmVudFpdIk8vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyovZGF0YVN0b3Jlcy8qfS91c2VyRXZlbnRzOndyaXRlOgp1c2VyX2V2ZW50WkIiNC92
MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3VzZXJFdmVudHM6d3JpdGU6CnVz
ZXJfZXZlbnQSwAIKEENvbGxlY3RVc2VyRXZlbnQSOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkNvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0GhQuZ29vZ2xlLmFwaS5IdHRwQm9k
eSLbAYLT5JMC1AESQy92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0
b3Jlcy8qfS91c2VyRXZlbnRzOmNvbGxlY3RaUxJRL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50czpjb2xs
ZWN0WjgSNi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3VzZXJFdmVudHM6
Y29sbGVjdBKEAwoPUHVyZ2VVc2VyRXZlbnRzEjcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5QdXJnZVVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiKYAoLT5JMCnAEiQS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVN0b3Jlcy8qfS91c2VyRXZlbnRzOnB1cmdlOgEqWlQiTy92MS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVu
dHM6cHVyZ2U6ASrKQXIKN2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUHVyZ2VV
c2VyRXZlbnRzUmVzcG9uc2USN2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUHVy
Z2VVc2VyRXZlbnRzTWV0YWRhdGESxgMKEEltcG9ydFVzZXJFdmVudHMSOC5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkltcG9ydFVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiLYAoLT5JMC2gEiQi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfS91c2VyRXZlbnRzOmltcG9ydDoBKlpVIlAv
djEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0
b3Jlcy8qfS91c2VyRXZlbnRzOmltcG9ydDoBKlo6IjUvdjEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qfS91c2VyRXZlbnRzOmltcG9ydDoBKspBdAo4Z29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5JbXBvcnRVc2VyRXZlbnRzUmVzcG9uc2USOGdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuSW1wb3J0VXNlckV2ZW50c01ldGFkYXRhGpACykEeZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kHrAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9kaXNjb3ZlcnllbmdpbmUuYXNzaXN0LnJlYWR3cml0ZSxodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCiAIK
I2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxQhVVc2VyRXZlbnRTZXJ2aWNl
UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9H
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVy
eUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFKtSYKBxIF
DgC7AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAjCgkK
AgMFEgMXAD0KCQoCAwYSAxgAPAoJCgIDBxIDGQA6CgkKAgMIEgMaAC0KCAoBCBIDHAA8CgkK
AgglEgMcADwKCAoBCBIDHQBkCgkKAggLEgMdAGQKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoB
CBIDHwA2CgkKAggIEgMfADYKCAoBCBIDIAA8CgkKAggBEgMgADwKCAoBCBIDIQAtCgkKAggk
EgMhAC0KCAoBCBIDIgA8CgkKAggpEgMiADwKCAoBCBIDIwA7CgkKAggtEgMjADsKWgoCBgAS
BCYAfQEaTiBTZXJ2aWNlIGZvciBpbmdlc3RpbmcgZW5kIHVzZXIgYWN0aW9ucyBvbiBhIHdl
YnNpdGUgdG8gRGlzY292ZXJ5IEVuZ2luZSBBUEkuCgoKCgMGAAESAyYIGAoKCgMGAAMSAycC
RgoMCgUGAAOZCBIDJwJGCgsKAwYAAxIEKAIsSgoNCgUGAAOaCBIEKAIsSgorCgQGAAIAEgQv
AjwDGh0gV3JpdGVzIGEgc2luZ2xlIHVzZXIgZXZlbnQuCgoMCgUGAAIAARIDLwYUCgwKBQYA
AgACEgMvFSoKDAoFBgACAAMSAy81PgoNCgUGAAIABBIEMAQ7BgoRCgkGAAIABLDKvCISBDAE
OwYKpgIKBAYAAgESBEMCTQMalwIgV3JpdGVzIGEgc2luZ2xlIHVzZXIgZXZlbnQgZnJvbSB0
aGUgYnJvd3Nlci4gVGhpcyB1c2VzIGEgR0VUIHJlcXVlc3QgdG8KIGR1ZSB0byBicm93c2Vy
IHJlc3RyaWN0aW9uIG9mIFBPU1QtaW5nIHRvIGEgdGhpcmQtcGFydHkgZG9tYWluLgoKIFRo
aXMgbWV0aG9kIGlzIHVzZWQgb25seSBieSB0aGUgRGlzY292ZXJ5IEVuZ2luZSBBUEkgSmF2
YVNjcmlwdCBwaXhlbCBhbmQKIEdvb2dsZSBUYWcgTWFuYWdlci4gVXNlcnMgc2hvdWxkIG5v
dCBjYWxsIHRoaXMgbWV0aG9kIGRpcmVjdGx5LgoKDAoFBgACAQESA0MGFgoMCgUGAAIBAhID
QxcuCgwKBQYAAgEDEgNDOUwKDQoFBgACAQQSBEQETAYKEQoJBgACAQSwyrwiEgREBEwGCvcB
CgQGAAICEgRTAmEDGugBIERlbGV0ZXMgcGVybWFuZW50bHkgYWxsIHVzZXIgZXZlbnRzIHNw
ZWNpZmllZCBieSB0aGUgZmlsdGVyIHByb3ZpZGVkLgogRGVwZW5kaW5nIG9uIHRoZSBudW1i
ZXIgb2YgZXZlbnRzIHNwZWNpZmllZCBieSB0aGUgZmlsdGVyLCB0aGlzIG9wZXJhdGlvbgog
Y291bGQgdGFrZSBob3VycyBvciBkYXlzIHRvIGNvbXBsZXRlLiBUbyB0ZXN0IGEgZmlsdGVy
LCB1c2UgdGhlIGxpc3QKIGNvbW1hbmQgZmlyc3QuCgoMCgUGAAICARIDUwYVCgwKBQYAAgIC
EgNTFiwKDAoFBgACAgMSA1QPKwoNCgUGAAICBBIEVQRcBgoRCgkGAAICBLDKvCISBFUEXAYK
DQoFBgACAgQSBF0EYAYKDwoHBgACAgSZCBIEXQRgBgrmAgoEBgACAxIEagJ8AxrXAiBCdWxr
IGltcG9ydCBvZiB1c2VyIGV2ZW50cy4gUmVxdWVzdCBwcm9jZXNzaW5nIG1pZ2h0IGJlCiBz
eW5jaHJvbm91cy4gRXZlbnRzIHRoYXQgYWxyZWFkeSBleGlzdCBhcmUgc2tpcHBlZC4KIFVz
ZSB0aGlzIG1ldGhvZCBmb3IgYmFja2ZpbGxpbmcgaGlzdG9yaWNhbCB1c2VyIGV2ZW50cy4K
CiBPcGVyYXRpb24ucmVzcG9uc2UgaXMgb2YgdHlwZSBJbXBvcnRSZXNwb25zZS4gTm90ZSB0
aGF0IGl0IGlzCiBwb3NzaWJsZSBmb3IgYSBzdWJzZXQgb2YgdGhlIGl0ZW1zIHRvIGJlIHN1
Y2Nlc3NmdWxseSBpbnNlcnRlZC4KIE9wZXJhdGlvbi5tZXRhZGF0YSBpcyBvZiB0eXBlIElt
cG9ydE1ldGFkYXRhLgoKDAoFBgACAwESA2oGFgoMCgUGAAIDAhIDahcuCgwKBQYAAgMDEgNr
DysKDQoFBgACAwQSBGwEdwYKEQoJBgACAwSwyrwiEgRsBHcGCg0KBQYAAgMEEgR4BHsGCg8K
BwYAAgMEmQgSBHgEewYKOgoCBAASBoABAJgBARosIFJlcXVlc3QgbWVzc2FnZSBmb3IgV3Jp
dGVVc2VyRXZlbnQgbWV0aG9kLgoKCwoDBAABEgSAAQgdCscECgQEAAIAEgaLAQKQAQQatgQg
UmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZS4KIElmIHRoZSB3cml0ZSB1c2Vy
IGV2ZW50IGFjdGlvbiBpcyBhcHBsaWVkIGluCiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0gbGV2ZWwsIHRoZSBmb3JtYXQKIGlzOgog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97
Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX1gLgogSWYgdGhlIHdyaXRlIHVz
ZXIgZXZlbnQgYWN0aW9uIGlzIGFwcGxpZWQgaW4KIFtMb2NhdGlvbl1bZ29vZ2xlLmNsb3Vk
LmxvY2F0aW9uLkxvY2F0aW9uXSBsZXZlbCwgZm9yIGV4YW1wbGUsIHRoZSBldmVudAogd2l0
aCBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRd
IGFjcm9zcyBtdWx0aXBsZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5EYXRhU3RvcmVdLCB0aGUgZm9ybWF0IGlzOgogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoNCgUEAAIABRIEiwECCAoNCgUEAAIAARIEiwEJ
DwoNCgUEAAIAAxIEiwESEwoPCgUEAAIACBIGiwEUkAEDChAKCAQAAgAInAgAEgSMAQQqChEK
BwQAAgAInwgSBo0BBI8BBQouCgQEAAIBEgSTAQJNGiAgUmVxdWlyZWQuIFVzZXIgZXZlbnQg
dG8gd3JpdGUuCgoNCgUEAAIBBBIEkwECCgoNCgUEAAIBBhIEkwELFAoNCgUEAAIBARIEkwEV
HwoNCgUEAAIBAxIEkwEiIwoNCgUEAAIBCBIEkwEkTAoQCggEAAIBCJwIABIEkwElSwqQAQoE
BAACAhIElwECFxqBASBJZiBzZXQgdG8gdHJ1ZSwgdGhlIHVzZXIgZXZlbnQgaXMgd3JpdHRl
biBhc3luY2hyb25vdXNseSBhZnRlcgogdmFsaWRhdGlvbiwgYW5kIHRoZSBBUEkgcmVzcG9u
ZHMgd2l0aG91dCB3YWl0aW5nIGZvciB0aGUgd3JpdGUuCgoNCgUEAAICBRIElwECBgoNCgUE
AAICARIElwEHEgoNCgUEAAICAxIElwEVFgo8CgIEARIGmwEAuwEBGi4gUmVxdWVzdCBtZXNz
YWdlIGZvciBDb2xsZWN0VXNlckV2ZW50IG1ldGhvZC4KCgsKAwQBARIEmwEIHwrLBAoEBAEC
ABIGpgECqwEEGroEIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUuCiBJZiB0
aGUgY29sbGVjdCB1c2VyIGV2ZW50IGFjdGlvbiBpcyBhcHBsaWVkIGluCiBbRGF0YVN0b3Jl
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0gbGV2ZWwsIHRo
ZSBmb3JtYXQKIGlzOgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX1gLgog
SWYgdGhlIGNvbGxlY3QgdXNlciBldmVudCBhY3Rpb24gaXMgYXBwbGllZCBpbgogW0xvY2F0
aW9uXVtnb29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25dIGxldmVsLCBmb3IgZXhhbXBs
ZSwgdGhlIGV2ZW50CiB3aXRoIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5Eb2N1bWVudF0gYWNyb3NzIG11bHRpcGxlCiBbRGF0YVN0b3JlXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0sIHRoZSBmb3JtYXQgaXM6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQBAgAFEgSm
AQIICg0KBQQBAgABEgSmAQkPCg0KBQQBAgADEgSmARITCg8KBQQBAgAIEgamARSrAQMKEAoI
BAECAAicCAASBKcBBCoKEQoHBAECAAifCBIGqAEEqgEFCmMKBAQBAgESBK8BAkEaVSBSZXF1
aXJlZC4gVVJMIGVuY29kZWQgVXNlckV2ZW50IHByb3RvIHdpdGggYSBsZW5ndGggbGltaXQg
b2YgMiwwMDAsMDAwCiBjaGFyYWN0ZXJzLgoKDQoFBAECAQUSBK8BAggKDQoFBAECAQESBK8B
CRMKDQoFBAECAQMSBK8BFhcKDQoFBAECAQgSBK8BGEAKEAoIBAECAQicCAASBK8BGT8K8gEK
BAQBAgISBLUBAhoa4wEgVGhlIFVSTCBpbmNsdWRpbmcgY2dpLXBhcmFtZXRlcnMgYnV0IGV4
Y2x1ZGluZyB0aGUgaGFzaCBmcmFnbWVudCB3aXRoIGEKIGxlbmd0aCBsaW1pdCBvZiA1LDAw
MCBjaGFyYWN0ZXJzLiBUaGlzIGlzIG9mdGVuIG1vcmUgdXNlZnVsIHRoYW4gdGhlCiByZWZl
cmVyIFVSTCwgYmVjYXVzZSBtYW55IGJyb3dzZXJzIG9ubHkgc2VuZCB0aGUgZG9tYWluIGZv
ciB0aGlyZC1wYXJ0eQogcmVxdWVzdHMuCgoNCgUEAQICBBIEtQECCgoNCgUEAQICBRIEtQEL
EQoNCgUEAQICARIEtQESFQoNCgUEAQICAxIEtQEYGQqvAQoEBAECAxIEugECGRqgASBUaGUg
ZXZlbnQgdGltZXN0YW1wIGluIG1pbGxpc2Vjb25kcy4gVGhpcyBwcmV2ZW50cyBicm93c2Vy
IGNhY2hpbmcgb2YKIG90aGVyd2lzZSBpZGVudGljYWwgZ2V0IHJlcXVlc3RzLiBUaGUgbmFt
ZSBpcyBhYmJyZXZpYXRlZCB0byByZWR1Y2UgdGhlCiBwYXlsb2FkIGJ5dGVzLgoKDQoFBAEC
AwQSBLoBAgoKDQoFBAECAwUSBLoBCxAKDQoFBAECAwESBLoBERQKDQoFBAECAwMSBLoBFxhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()

# === Service Client: Google::Cloud::Discoveryengine::V1::UserEventService::UserEventServiceClient ===
package Google::Cloud::Discoveryengine::V1::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::UserEventService::UserEventServiceClient

Client stub representing the remote C<UserEventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub write_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserEventService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::UserEventService;

    my $msg = Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
If the write user event action is applied in
[DataStore][google.cloud.discoveryengine.v1.DataStore] level, the format
is:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.
If the write user event action is applied in
[Location][google.cloud.location.Location] level, for example, the event
with [Document][google.cloud.discoveryengine.v1.Document] across multiple
[DataStore][google.cloud.discoveryengine.v1.DataStore], the format is:
`projects/{project}/locations/{location}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event is written asynchronously after
validation, and the API responds without waiting for the write.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest

Request message for CollectUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
If the collect user event action is applied in
[DataStore][google.cloud.discoveryengine.v1.DataStore] level, the format
is:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.
If the collect user event action is applied in
[Location][google.cloud.location.Location] level, for example, the event
with [Document][google.cloud.discoveryengine.v1.Document] across multiple
[DataStore][google.cloud.discoveryengine.v1.DataStore], the format is:
`projects/{project}/locations/{location}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<String>

Required. URL encoded UserEvent proto with a length limit of 2,000,000
characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URL including cgi-parameters but excluding the hash fragment with a
length limit of 5,000 characters. This is often more useful than the
referer URL, because many browsers only send the domain for third-party
requests.

=item * C<< $msg->ets() >> / C<< $msg->ets($value) >>

Type: C<Int64>

The event timestamp in milliseconds. This prevents browser caching of
otherwise identical get requests. The name is abbreviated to reduce the
payload bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
