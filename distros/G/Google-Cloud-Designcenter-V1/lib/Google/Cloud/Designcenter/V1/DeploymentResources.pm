package Google::Cloud::Designcenter::V1::DeploymentResources;

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
    eval { require Google::Cloud::Apphub::V1::Application };
    eval { require Google::Cloud::Apphub::V1::Attributes };
    eval { require Google::Cloud::Designcenter::V1::Authoring };
    eval { require Google::Cloud::Designcenter::V1::Deployment };
    eval { require Google::Cloud::Designcenter::V1::Enums };
    eval { require Google::Cloud::Designcenter::V1::Export };
    eval { require Google::Cloud::Designcenter::V1::Metadata };
    eval { require Google::Cloud::Designcenter::V1::Parameters };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2RlcGxveW1lbnRfcmVzb3VyY2VzLnBy
b3RvEhxnb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQv
YXBwaHViL3YxL2FwcGxpY2F0aW9uLnByb3RvGidnb29nbGUvY2xvdWQvYXBwaHViL3YxL2F0
dHJpYnV0ZXMucHJvdG8aLGdvb2dsZS9jbG91ZC9kZXNpZ25jZW50ZXIvdjEvYXV0aG9yaW5n
LnByb3RvGi1nb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2RlcGxveW1lbnQucHJvdG8a
KGdvb2dsZS9jbG91ZC9kZXNpZ25jZW50ZXIvdjEvZW51bXMucHJvdG8aKWdvb2dsZS9jbG91
ZC9kZXNpZ25jZW50ZXIvdjEvZXhwb3J0LnByb3RvGitnb29nbGUvY2xvdWQvZGVzaWduY2Vu
dGVyL3YxL21ldGFkYXRhLnByb3RvGi1nb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3Bh
cmFtZXRlcnMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8igBgKC0Fw
cGxpY2F0aW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJLCgZzb3VyY2UYBCABKAsyLi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkRl
cGxveW1lbnRTb3VyY2VCA+BBAlIGc291cmNlElMKDmFwcF9wYXJhbWV0ZXJzGAUgAygLMicu
Z29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5QYXJhbWV0ZXJCA+BBAVINYXBwUGFyYW1l
dGVycxJpChRjb21wb25lbnRfcGFyYW1ldGVycxgKIAMoCzIxLmdvb2dsZS5jbG91ZC5kZXNp
Z25jZW50ZXIudjEuQ29tcG9uZW50UGFyYW1ldGVyc0ID4EEBUhNjb21wb25lbnRQYXJhbWV0
ZXJzEiwKD3NlcnZpY2VfYWNjb3VudBgLIAEoCUID4EEBUg5zZXJ2aWNlQWNjb3VudBImCgxk
aXNwbGF5X25hbWUYDCABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YDSAB
KAlCA+BBAVILZGVzY3JpcHRpb24SRwoKYXR0cmlidXRlcxgOIAEoCzIiLmdvb2dsZS5jbG91
ZC5hcHBodWIudjEuQXR0cmlidXRlc0ID4EEBUgphdHRyaWJ1dGVzEjgKBXNjb3BlGA8gASgL
Mh0uZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5TY29wZUID4EECUgVzY29wZRI/ChlpbXBvcnRf
ZXhpc3RpbmdfcmVzb3VyY2VzGBAgASgIQgPgQQFSF2ltcG9ydEV4aXN0aW5nUmVzb3VyY2Vz
EjAKEXByZXZpZXdfcmVmZXJlbmNlGBEgASgJQgPgQQNSEHByZXZpZXdSZWZlcmVuY2USNAoT
ZGVwbG95bWVudF9yZXZpc2lvbhgSIAEoCUID4EEDUhJkZXBsb3ltZW50UmV2aXNpb24SMgoS
YXBwaHViX2FwcGxpY2F0aW9uGBMgASgJQgPgQQNSEWFwcGh1YkFwcGxpY2F0aW9uEogBCh9z
ZXJpYWxpemVkX2FwcGxpY2F0aW9uX3RlbXBsYXRlGBQgASgLMjsuZ29vZ2xlLmNsb3VkLmRl
c2lnbmNlbnRlci52MS5TZXJpYWxpemVkQXBwbGljYXRpb25UZW1wbGF0ZUID4EEDUh1zZXJp
YWxpemVkQXBwbGljYXRpb25UZW1wbGF0ZRJKCgVzdGF0ZRgVIAEoDjIvLmdvb2dsZS5jbG91
ZC5kZXNpZ25jZW50ZXIudjEuQXBwbGljYXRpb24uU3RhdGVCA+BBA1IFc3RhdGUSZgoTZGVw
bG95bWVudF9tZXRhZGF0YRgWIAEoCzIwLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEu
RGVwbG95bWVudE1ldGFkYXRhQgPgQQNSEmRlcGxveW1lbnRNZXRhZGF0YRJjChJwcm9qZWN0
X3BhcmFtZXRlcnMYFyADKAsyLy5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlByb2pl
Y3RQYXJhbWV0ZXJzQgPgQQNSEXByb2plY3RQYXJhbWV0ZXJzEjAKEWRlcGxveW1lbnRfcmVn
aW9uGBggASgJQgPgQQFSEGRlcGxveW1lbnRSZWdpb24SdgoZdXBkYXRlZF90ZW1wbGF0ZV9y
ZXZpc2lvbhgaIAEoCzI1Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVXBkYXRlZFRl
bXBsYXRlUmV2aXNpb25CA+BBA1IXdXBkYXRlZFRlbXBsYXRlUmV2aXNpb24SMgoSZGVwbG95
bWVudF9wcm9qZWN0GBsgASgJQgPgQQFSEWRlcGxveW1lbnRQcm9qZWN0EmIKEmNvbm5lY3Rp
b25fY29uZmlncxgcIAMoCzIuLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQ29ubmVj
dGlvbkNvbmZpZ0ID4EEBUhFjb25uZWN0aW9uQ29uZmlncxJgChFhcnRpZmFjdF9sb2NhdGlv
bhgdIAEoCzIuLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQXJ0aWZhY3RMb2NhdGlv
bkID4EEDUhBhcnRpZmFjdExvY2F0aW9uEkYKBHR5cGUYHiABKA4yLS5nb29nbGUuY2xvdWQu
ZGVzaWduY2VudGVyLnYxLkFwcGxpY2F0aW9uVHlwZUID4EEBUgR0eXBlEmAKEWRlcGxveW1l
bnRfdGFyZ2V0GB8gASgLMi4uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5EZXBsb3lt
ZW50VGFyZ2V0QgPgQQFSEGRlcGxveW1lbnRUYXJnZXQSaAoQY29tcG9zaXRpb25fdHlwZRgg
IAEoDjI4Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQXBwbGljYXRpb25Db21wb3Np
dGlvblR5cGVCA+BBA1IPY29tcG9zaXRpb25UeXBlEosBCiBjb21wb3NpdGVfYXBwbGljYXRp
b25fcGFyYW1ldGVycxghIAEoCzI8Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQ29t
cG9zaXRlQXBwbGljYXRpb25QYXJhbWV0ZXJzQgPgQQFSHmNvbXBvc2l0ZUFwcGxpY2F0aW9u
UGFyYW1ldGVycxJ2ChlkZXBsb3ltZW50X2dyb3VwX21ldGFkYXRhGCIgASgLMjUuZ29vZ2xl
LmNsb3VkLmRlc2lnbmNlbnRlci52MS5EZXBsb3ltZW50R3JvdXBNZXRhZGF0YUID4EEDUhdk
ZXBsb3ltZW50R3JvdXBNZXRhZGF0YRJzChZwYXJhbXNfdXBkYXRlX3N0cmF0ZWd5GCMgASgO
MjguZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5BcHBsaWNhdGlvbi5VcGRhdGVTdHJh
dGVneUID4EEBUhRwYXJhbXNVcGRhdGVTdHJhdGVneRJhChFyb2xlc19hcGlzX2NvbmZpZxgk
IAMoCzIwLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuUm9sZXNBbmRBcGlzQ29uZmln
QgPgQQFSD3JvbGVzQXBpc0NvbmZpZxJjChF0ZW1wbGF0ZV9tZXRhZGF0YRglIAEoCzIxLmdv
b2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVEZCbHVlcHJpbnRNZXRhZGF0YUID4EEDUhB0
ZW1wbGF0ZU1ldGFkYXRhEksKCmlhY19zb3VyY2UYJiABKA4yJy5nb29nbGUuY2xvdWQuZGVz
aWduY2VudGVyLnYxLklBQ1NvdXJjZUID4EEDUglpYWNTb3VyY2UinwEKBVN0YXRlEhUKEVNU
QVRFX1VOU1BFQ0lGSUVEEAASCQoFRFJBRlQQARIXChNDUkVBVElOR19ERVBMT1lNRU5UEAIS
FwoTVVBEQVRJTkdfREVQTE9ZTUVOVBADEgwKCERFTEVUSU5HEAQSDAoIREVQTE9ZRUQQBRIL
CgdERUxFVEVEEAYSCgoGRkFJTEVEEAcSDQoJREVQTE9ZSU5HEAgiPgoOVXBkYXRlU3RyYXRl
Z3kSHwobVVBEQVRFX1NUUkFURUdZX1VOU1BFQ0lGSUVEEAASCwoHUkVQTEFDRRACOpsB6kGX
AQonZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL0FwcGxpY2F0aW9uElFwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3BhY2VzL3tzcGFjZX0vYXBwbGljYXRp
b25zL3thcHBsaWNhdGlvbn0qDGFwcGxpY2F0aW9uczILYXBwbGljYXRpb25C5AEKIGNvbS5n
b29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxQhhEZXBsb3ltZW50UmVzb3VyY2VzUHJvdG9Q
AVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9kZXNpZ25jZW50ZXIvYXBpdjEvZGVzaWduY2VudGVy
cGI7ZGVzaWduY2VudGVycGKqAhxHb29nbGUuQ2xvdWQuRGVzaWduQ2VudGVyLlYxygIcR29v
Z2xlXENsb3VkXERlc2lnbkNlbnRlclxWMeoCH0dvb2dsZTo6Q2xvdWQ6OkRlc2lnbkNlbnRl
cjo6VjFKujsKBxIFDgDXAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACUKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADIKCQoCAwMSAxUAMQoJ
CgIDBBIDFgA2CgkKAgMFEgMXADcKCQoCAwYSAxgAMgoJCgIDBxIDGQAzCgkKAgMIEgMaADUK
CQoCAwkSAxsANwoJCgIDChIDHAApCggKAQgSAx4AOQoJCgIIJRIDHgA5CggKAQgSAx8AWwoJ
CgIICxIDHwBbCggKAQgSAyAAIgoJCgIIChIDIAAiCggKAQgSAyEAOQoJCgIICBIDIQA5CggK
AQgSAyIAOQoJCgIIARIDIgA5CggKAQgSAyMAOQoJCgIIKRIDIwA5CggKAQgSAyQAOAoJCgII
LRIDJAA4CjMKAgQAEgUnANcBARomIFJlcHJlc2VudHMgdGhlIGFwcGxpY2F0aW9uIHJlc291
cmNlLgoKCgoDBAABEgMnCBMKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQoAi0ECkUKBAQABAAS
BDACSwMaNyBQb3NzaWJsZSB2YWx1ZXMgZm9yIHRoZSBhcHBsaWNhdGlvbiBkZXBsb3ltZW50
IHN0YXRlLgoKDAoFBAAEAAESAzAHDAo6CgYEAAQAAgASAzIEGhorIFVuc3BlY2lmaWVkIGFw
cGxpY2F0aW9uIGRlcGxveW1lbnQgc3RhdGUuCgoOCgcEAAQAAgABEgMyBBUKDgoHBAAEAAIA
AhIDMhgZCikKBgQABAACARIDNQQOGhogQXBwbGljYXRpb24gaXMgaW4gZHJhZnQuCgoOCgcE
AAQAAgEBEgM1BAkKDgoHBAAEAAIBAhIDNQwNCjsKBgQABAACAhIDOAQcGiwgTmV3IGFwcGxp
Y2F0aW9uIGRlcGxveW1lbnQgaXMgaW4gcHJvZ3Jlc3MuCgoOCgcEAAQAAgIBEgM4BBcKDgoH
BAAEAAICAhIDOBobCj4KBgQABAACAxIDOwQcGi8gVXBkYXRlIGFwcGxpY2F0aW9uIGRlcGxv
eW1lbnQgaXMgaW4gcHJvZ3Jlc3MuCgoOCgcEAAQAAgMBEgM7BBcKDgoHBAAEAAIDAhIDOxob
Cj4KBgQABAACBBIDPgQRGi8gRGVsZXRlIGFwcGxpY2F0aW9uIGRlcGxveW1lbnQgaXMgaW4g
cHJvZ3Jlc3MuCgoOCgcEAAQAAgQBEgM+BAwKDgoHBAAEAAIEAhIDPg8QCjUKBgQABAACBRID
QQQRGiYgQXBwbGljYXRpb24gZGVwbG95bWVudCBpcyBjb21wbGV0ZWQuCgoOCgcEAAQAAgUB
EgNBBAwKDgoHBAAEAAIFAhIDQQ8QCjMKBgQABAACBhIDRAQQGiQgQXBwbGljYXRpb24gZGVw
bG95bWVudCBpcyBkZWxldGVkLgoKDgoHBAAEAAIGARIDRAQLCg4KBwQABAACBgISA0QODwoy
CgYEAAQAAgcSA0cEDxojIEFwcGxpY2F0aW9uIGRlcGxveW1lbnQgaXMgZmFpbGVkLgoKDgoH
BAAEAAIHARIDRwQKCg4KBwQABAACBwISA0cNDgo3CgYEAAQAAggSA0oEEhooIEFwcGxpY2F0
aW9uIGRlcGxveW1lbnQgaXMgaW4gcHJvZ3Jlc3MuCgoOCgcEAAQAAggBEgNKBA0KDgoHBAAE
AAIIAhIDShARCksKBAQABAESBE4CVAMaPSBTcGVjaWZpZXMgdGhlIHN0cmF0ZWd5IHRvIHVz
ZSB3aGVuIHVwZGF0aW5nIGFuIGFwcGxpY2F0aW9uLgoKDAoFBAAEAQESA04HFQo6CgYEAAQB
AgASA1AEJBorIFJldGFpbnMgdGhlIGV4aXN0aW5nIHZhbHVlIGZvciB0aGUgZmllbGQuCgoO
CgcEAAQBAgABEgNQBB8KDgoHBAAEAQIAAhIDUCIjCksKBgQABAECARIDUwQQGjwgUmVwbGFj
ZXMgdGhlIGV4aXN0aW5nIGZpZWxkIHZhbHVlcyB3aXRoIHRoZSBwcm92aWRlZCBvbmVzLgoK
DgoHBAAEAQIBARIDUwQLCg4KBwQABAECAQISA1MODwqUAQoEBAACABIDWQI9GoYBIElkZW50
aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBhcHBsaWNhdGlvbi4KIEZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zcGFjZXMve3NwYWNlfS9hcHBsaWNh
dGlvbnMve2FwcGxpY2F0aW9ufQoKDAoFBAACAAUSA1kCCAoMCgUEAAIAARIDWQkNCgwKBQQA
AgADEgNZEBEKDAoFBAACAAgSA1kSPAoPCggEAAIACJwIABIDWRM7Ci4KBAQAAgESBFwCXTIa
ICBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWVzdGFtcC4KCgwKBQQAAgEGEgNcAhsKDAoFBAAC
AQESA1wcJwoMCgUEAAIBAxIDXCorCgwKBQQAAgEIEgNdBjEKDwoIBAACAQicCAASA10HMAou
CgQEAAICEgRgAmEyGiAgT3V0cHV0IG9ubHkuIFVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAAIC
BhIDYAIbCgwKBQQAAgIBEgNgHCcKDAoFBAACAgMSA2AqKwoMCgUEAAICCBIDYQYxCg8KCAQA
AgIInAgAEgNhBzAKOwoEBAACAxIDZAJHGi4gUmVxdWlyZWQuIFRoZSBhcHBsaWNhdGlvbiBk
ZXBsb3ltZW50IHNvdXJjZS4KCgwKBQQAAgMGEgNkAhIKDAoFBAACAwESA2QTGQoMCgUEAAID
AxIDZBwdCgwKBQQAAgMIEgNkHkYKDwoIBAACAwicCAASA2QfRQqWAQoEBAACBBIEaAJpLxqH
ASBPcHRpb25hbC4gQSBsaXN0IG9mIHBhcmFtZXRlcnMgdG8gYXR0YWNoIHRvIHRoZSBkZXBs
b3ltZW50IHNvdXJjZSBvYmplY3QsCiB3aGljaCBpcyBhIGNhdGFsb2cgZW50cnkgb3IgYXBw
bGljYXRpb24gdGVtcGxhdGUgc25hcHNob3QuCgoMCgUEAAIEBBIDaAIKCgwKBQQAAgQGEgNo
CxQKDAoFBAACBAESA2gVIwoMCgUEAAIEAxIDaCYnCgwKBQQAAgQIEgNpBi4KDwoIBAACBAic
CAASA2kHLQpbCgQEAAIFEgRsAm0vGk0gT3B0aW9uYWwuIEEgbGlzdCBvZiBjb21wb25lbnQg
cGFyYW1ldGVycyB0byBhc3NvY2lhdGUgd2l0aCB0aGUgYXBwbGljYXRpb24uCgoMCgUEAAIF
BBIDbAIKCgwKBQQAAgUGEgNsCx4KDAoFBAACBQESA2wfMwoMCgUEAAIFAxIDbDY4CgwKBQQA
AgUIEgNtBi4KDwoIBAACBQicCAASA20HLQpYCgQEAAIGEgNwAkcaSyBPcHRpb25hbC4gWW91
ciBvd24gc2VydmljZSBhY2NvdW50IHRoYXQgeW91IHVzZSB0byBkZXBsb3kgYW4gYXBwbGlj
YXRpb24uCgoMCgUEAAIGBRIDcAIICgwKBQQAAgYBEgNwCRgKDAoFBAACBgMSA3AbHQoMCgUE
AAIGCBIDcB5GCg8KCAQAAgYInAgAEgNwH0UKOQoEBAACBxIDcwJEGiwgT3B0aW9uYWwuIERp
c3BsYXkgbmFtZSBvZiB0aGUgYXBwbGljYXRpb24uCgoMCgUEAAIHBRIDcwIICgwKBQQAAgcB
EgNzCRUKDAoFBAACBwMSA3MYGgoMCgUEAAIHCBIDcxtDCg8KCAQAAgcInAgAEgNzHEIKOAoE
BAACCBIDdgJDGisgT3B0aW9uYWwuIERlc2NyaXB0aW9uIG9mIHRoZSBhcHBsaWNhdGlvbi4K
CgwKBQQAAggFEgN2AggKDAoFBAACCAESA3YJFAoMCgUEAAIIAxIDdhcZCgwKBQQAAggIEgN2
GkIKDwoIBAACCAicCAASA3YbQQo4CgQEAAIJEgR5AnovGiogT3B0aW9uYWwuIEF0dHJpYnV0
ZXMgb2YgdGhlIGFwcGxpY2F0aW9uLgoKDAoFBAACCQYSA3kCIwoMCgUEAAIJARIDeSQuCgwK
BQQAAgkDEgN5MTMKDAoFBAACCQgSA3oGLgoPCggEAAIJCJwIABIDegctCjMKBAQAAgoSBH0C
fi8aJSBSZXF1aXJlZC4gU2NvcGUgb2YgdGhlIGFwcGxpY2F0aW9uLgoKDAoFBAACCgYSA30C
HgoMCgUEAAIKARIDfR8kCgwKBQQAAgoDEgN9JykKDAoFBAACCggSA34GLgoPCggEAAIKCJwI
ABIDfgctCkkKBAQAAgsSBIEBAk8aOyBPcHRpb25hbC4gSW1wb3J0IGV4aXN0aW5nIHJlc291
cmNlcyBpbnRvIHRoZSBhcHBsaWNhdGlvbi4KCg0KBQQAAgsFEgSBAQIGCg0KBQQAAgsBEgSB
AQcgCg0KBQQAAgsDEgSBASMlCg0KBQQAAgsIEgSBASZOChAKCAQAAgsInAgAEgSBASdNCkMK
BAQAAgwSBIQBAkwaNSBPdXRwdXQgb25seS4gUHJldmlldyByZWZlcmVuY2UgZm9yIHRoZSBh
cHBsaWNhdGlvbi4KCg0KBQQAAgwFEgSEAQIICg0KBQQAAgwBEgSEAQkaCg0KBQQAAgwDEgSE
AR0fCg0KBQQAAgwIEgSEASBLChAKCAQAAgwInAgAEgSEASFKCl4KBAQAAg0SBIgBAk4aUCBP
dXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBPcHRpb25hbCBJbmZyYSBNYW5hZ2VyIGRlcGxv
eW1lbnQgSWQgd2l0aAogcmV2aXNpb24KCg0KBQQAAg0FEgSIAQIICg0KBQQAAg0BEgSIAQkc
Cg0KBQQAAg0DEgSIAR8hCg0KBQQAAg0IEgSIASJNChAKCAQAAg0InAgAEgSIASNMCk0KBAQA
Ag4SBIsBAk0aPyBPdXRwdXQgb25seS4gVGhlIEFwcCBIdWIgQXBwIGFzc29jaWF0ZWQgd2l0
aCB0aGUgYXBwbGljYXRpb24uCgoNCgUEAAIOBRIEiwECCAoNCgUEAAIOARIEiwEJGwoNCgUE
AAIOAxIEiwEeIAoNCgUEAAIOCBIEiwEhTAoQCggEAAIOCJwIABIEiwEiSwpNCgQEAAIPEgaO
AQKPATIaPSBPdXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBTZXJpYWxpemVkIGFwcGxpY2F0
aW9uIHRlbXBsYXRlLgoKDQoFBAACDwYSBI4BAh8KDQoFBAACDwESBI4BID8KDQoFBAACDwMS
BI4BQkQKDQoFBAACDwgSBI8BBjEKEAoIBAACDwicCAASBI8BBzAKQQoEBAACEBIEkgECPxoz
IE91dHB1dCBvbmx5LiBEZXBsb3ltZW50IHN0YXRlIG9mIHRoZSBhcHBsaWNhdGlvbi4KCg0K
BQQAAhAGEgSSAQIHCg0KBQQAAhABEgSSAQgNCg0KBQQAAhADEgSSARASCg0KBQQAAhAIEgSS
ARM+ChAKCAQAAhAInAgAEgSSARQ9CkYKBAQAAhESBpUBApYBMho2IE91dHB1dCBvbmx5LiBE
ZXBsb3ltZW50IG1ldGFkYXRhIG9mIHRoZSBhcHBsaWNhdGlvbi4KCg0KBQQAAhEGEgSVAQIU
Cg0KBQQAAhEBEgSVARUoCg0KBQQAAhEDEgSVASstCg0KBQQAAhEIEgSWAQYxChAKCAQAAhEI
nAgAEgSWAQcwCk4KBAQAAhISBpkBApoBMho+IE91dHB1dCBvbmx5LiBMaXN0IG9mIHByb2pl
Y3QgcGFyYW1ldGVycyBmb3IgdGhlIGFwcGxpY2F0aW9uLgoKDQoFBAACEgQSBJkBAgoKDQoF
BAACEgYSBJkBCxwKDQoFBAACEgESBJkBHS8KDQoFBAACEgMSBJkBMjQKDQoFBAACEggSBJoB
BjEKEAoIBAACEgicCAASBJoBBzAKRwoEBAACExIEnQECSRo5IE9wdGlvbmFsLiBUaGUgcmVn
aW9uIHdoZXJlIHRoZSBhcHBsaWNhdGlvbiBpcyBkZXBsb3llZC4KCg0KBQQAAhMFEgSdAQII
Cg0KBQQAAhMBEgSdAQkaCg0KBQQAAhMDEgSdAR0fCg0KBQQAAhMIEgSdASBIChAKCAQAAhMI
nAgAEgSdASFHCmsKBAQAAhQSBqEBAqIBMhpbIE91dHB1dCBvbmx5LiBUaGUgdXBkYXRlZCB0
ZW1wbGF0ZSByZXZpc2lvbiBiZWNhdXNlIG9mIHdoaWNoIHRoZSBhcHBsaWNhdGlvbgogaXMg
b3V0ZGF0ZWQuCgoNCgUEAAIUBhIEoQECGQoNCgUEAAIUARIEoQEaMwoNCgUEAAIUAxIEoQE2
OAoNCgUEAAIUCBIEogEGMQoQCggEAAIUCJwIABIEogEHMApACgQEAAIVEgSlAQJKGjIgT3B0
aW9uYWwuIERlcGxveW1lbnQgcHJvamVjdCBvZiB0aGUgYXBwbGljYXRpb24uCgoNCgUEAAIV
BRIEpQECCAoNCgUEAAIVARIEpQEJGwoNCgUEAAIVAxIEpQEeIAoNCgUEAAIVCBIEpQEhSQoQ
CggEAAIVCJwIABIEpQEiSApJCgQEAAIWEgaoAQKpAS8aOSBPcHRpb25hbC4gQ29ubmVjdGlv
biBjb25maWd1cmF0aW9uIGZvciB0aGUgYXBwbGljYXRpb24uCgoNCgUEAAIWBBIEqAECCgoN
CgUEAAIWBhIEqAELGwoNCgUEAAIWARIEqAEcLgoNCgUEAAIWAxIEqAExMwoNCgUEAAIWCBIE
qQEGLgoQCggEAAIWCJwIABIEqQEHLQp6CgQEAAIXEgatAQKuATIaaiBPdXRwdXQgb25seS4g
RGV0YWlscyBvZiB0aGUgbG9jYXRpb24gd2hlcmUgdGhlIElhQyBmb3IgdGhpcyBhcHBsaWNh
dGlvbiB3YXMKIGxhc3Qgc3VjY2Vzc2Z1bGx5IGV4cG9ydGVkLgoKDQoFBAACFwYSBK0BAhIK
DQoFBAACFwESBK0BEyQKDQoFBAACFwMSBK0BJykKDQoFBAACFwgSBK4BBjEKEAoIBAACFwic
CAASBK4BBzAKNgoEBAACGBIEsQECRRooIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiB0aGUgYXBw
bGljYXRpb24uCgoNCgUEAAIYBhIEsQECEQoNCgUEAAIYARIEsQESFgoNCgUEAAIYAxIEsQEZ
GwoNCgUEAAIYCBIEsQEcRAoQCggEAAIYCJwIABIEsQEdQwpFCgQEAAIZEga0AQK1AS8aNSBP
cHRpb25hbC4gVGhlIGRlcGxveW1lbnQgdGFyZ2V0IG9mIHRoZSBhcHBsaWNhdGlvbi4KCg0K
BQQAAhkGEgS0AQISCg0KBQQAAhkBEgS0ARMkCg0KBQQAAhkDEgS0AScpCg0KBQQAAhkIEgS1
AQYuChAKCAQAAhkInAgAEgS1AQctCl8KBAQAAhoSBrkBAroBMhpPIE91dHB1dCBvbmx5LiBU
aGUgY29tcG9zaXRpb24gdHlwZSBvZiB0aGUgYXBwbGljYXRpb246IFNUQU5EQVJEIE9SCiBD
T01QT1NJVEUuCgoNCgUEAAIaBhIEuQECHAoNCgUEAAIaARIEuQEdLQoNCgUEAAIaAxIEuQEw
MgoNCgUEAAIaCBIEugEGMQoQCggEAAIaCJwIABIEugEHMApUCgQEAAIbEga9AQK+AS8aRCBP
cHRpb25hbC4gUGFyYW1ldGVycyB0aGF0IGFyZSByZXF1aXJlZCBmb3IgY29tcG9zaXRlIGFw
cGxpY2F0aW9ucy4KCg0KBQQAAhsGEgS9AQIgCg0KBQQAAhsBEgS9ASFBCg0KBQQAAhsDEgS9
AURGCg0KBQQAAhsIEgS+AQYuChAKCAQAAhsInAgAEgS+AQctCoUBCgQEAAIcEgbCAQLDATIa
dSBPdXRwdXQgb25seS4gVGhlIGRlcGxveW1lbnQgZ3JvdXAgbWV0YWRhdGEgb2YgdGhlIGFw
cGxpY2F0aW9uLiBUaGlzIGlzCiBhcHBsaWNhYmxlIG9ubHkgZm9yIGNvbXBvc2l0ZSBhcHBs
aWNhdGlvbnMuCgoNCgUEAAIcBhIEwgECGQoNCgUEAAIcARIEwgEaMwoNCgUEAAIcAxIEwgE2
OAoNCgUEAAIcCBIEwwEGMQoQCggEAAIcCJwIABIEwwEHMAqWAQoEBAACHRIGxwECyAEvGoUB
IE9wdGlvbmFsLiBTcGVjaWZpZXMgdGhlIHN0cmF0ZWd5IHRvIHVzZSB3aGVuIHVwZGF0aW5n
IHRoZSBhcHBsaWNhdGlvbgogcGFyYW1ldGVycyB3aGlsZSB1cGRhdGluZyB0aGUgYXBwbGlj
YXRpb24gdGVtcGxhdGUgcmV2aXNpb24uCgoNCgUEAAIdBhIExwECEAoNCgUEAAIdARIExwER
JwoNCgUEAAIdAxIExwEqLAoNCgUEAAIdCBIEyAEGLgoQCggEAAIdCJwIABIEyAEHLQqnAQoE
BAACHhIGzQECzgEvGpYBIE9wdGlvbmFsLiBQcm9qZWN0LXNwZWNpZmljIGNvbmZpZ3VyYXRp
b25zIHJlcXVpcmVkIGZvciBhcHBsaWNhdGlvbgogZGVwbG95bWVudCwgaW5jbHVkaW5nIElB
TSByb2xlcyBhbmQgQVBJcy4gVGhlIGxpc3QgY2FuIGNvbnRhaW4gdXAgdG8gMTAwCiBpdGVt
cy4KCg0KBQQAAh4EEgTNAQIKCg0KBQQAAh4GEgTNAQsdCg0KBQQAAh4BEgTNAR4vCg0KBQQA
Ah4DEgTNATI0Cg0KBQQAAh4IEgTOAQYuChAKCAQAAh4InAgAEgTOAQctCmMKBAQAAh8SBtIB
AtMBMhpTIE91dHB1dCBvbmx5LiBUaGUgaW5wdXQgb3V0cHV0IHZhcmlhYmxlcyBwYXJzZWQg
ZnJvbSB0aGUgaW1wb3J0ZWQgdGVycmFmb3JtCiBjb2RlLgoKDQoFBAACHwYSBNIBAhUKDQoF
BAACHwESBNIBFicKDQoFBAACHwMSBNIBKiwKDQoFBAACHwgSBNMBBjEKEAoIBAACHwicCAAS
BNMBBzAKUQoEBAACIBIE1gECSBpDIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgdGhlIElhQyBz
b3VyY2UgZm9ybWF0IG9mIHRoaXMgYXBwbGljYXRpb24uCgoNCgUEAAIgBhIE1gECCwoNCgUE
AAIgARIE1gEMFgoNCgUEAAIgAxIE1gEZGwoNCgUEAAIgCBIE1gEcRwoQCggEAAIgCJwIABIE
1gEdRmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::DeploymentResources::Application ===
    # Fields for Application
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: source Type: 11 (.google.cloud.designcenter.v1.DeploymentSource)
    # Field: app_parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)
    # Field: component_parameters Type: 11 (.google.cloud.designcenter.v1.ComponentParameters)
    # Field: service_account Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.apphub.v1.Attributes)
    # Field: scope Type: 11 (.google.cloud.apphub.v1.Scope)
    # Field: import_existing_resources Type: 8 ()
    # Field: preview_reference Type: 9 ()
    # Field: deployment_revision Type: 9 ()
    # Field: apphub_application Type: 9 ()
    # Field: serialized_application_template Type: 11 (.google.cloud.designcenter.v1.SerializedApplicationTemplate)
    # Field: state Type: 14 (.google.cloud.designcenter.v1.Application.State)
    # Field: deployment_metadata Type: 11 (.google.cloud.designcenter.v1.DeploymentMetadata)
    # Field: project_parameters Type: 11 (.google.cloud.designcenter.v1.ProjectParameters)
    # Field: deployment_region Type: 9 ()
    # Field: updated_template_revision Type: 11 (.google.cloud.designcenter.v1.UpdatedTemplateRevision)
    # Field: deployment_project Type: 9 ()
    # Field: connection_configs Type: 11 (.google.cloud.designcenter.v1.ConnectionConfig)
    # Field: artifact_location Type: 11 (.google.cloud.designcenter.v1.ArtifactLocation)
    # Field: type Type: 14 (.google.cloud.designcenter.v1.ApplicationType)
    # Field: deployment_target Type: 11 (.google.cloud.designcenter.v1.DeploymentTarget)
    # Field: composition_type Type: 14 (.google.cloud.designcenter.v1.ApplicationCompositionType)
    # Field: composite_application_parameters Type: 11 (.google.cloud.designcenter.v1.CompositeApplicationParameters)
    # Field: deployment_group_metadata Type: 11 (.google.cloud.designcenter.v1.DeploymentGroupMetadata)
    # Field: params_update_strategy Type: 14 (.google.cloud.designcenter.v1.Application.UpdateStrategy)
    # Field: roles_apis_config Type: 11 (.google.cloud.designcenter.v1.RolesAndApisConfig)
    # Field: template_metadata Type: 11 (.google.cloud.designcenter.v1.TFBlueprintMetadata)
    # Field: iac_source Type: 14 (.google.cloud.designcenter.v1.IACSource)

# Enum: Application::State
our $Application_STATE_UNSPECIFIED = 0;
our $Application_DRAFT = 1;
our $Application_CREATING_DEPLOYMENT = 2;
our $Application_UPDATING_DEPLOYMENT = 3;
our $Application_DELETING = 4;
our $Application_DEPLOYED = 5;
our $Application_DELETED = 6;
our $Application_FAILED = 7;
our $Application_DEPLOYING = 8;

# Enum: Application::UpdateStrategy
our $Application_UPDATE_STRATEGY_UNSPECIFIED = 0;
our $Application_REPLACE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::DeploymentResources - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/deployment_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::DeploymentResources;

    my $msg = Google::Cloud::Designcenter::V1::DeploymentResources::Application->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        source => $source,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::DeploymentResources::Application->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/deployment_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::DeploymentResources::Application

Represents the application resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the application.
Format:
projects/{project}/locations/{location}/spaces/{space}/applications/{application}

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update timestamp.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::DeploymentSource>)

Required. The application deployment source.

=item * C<< $msg->app_parameters() >> / C<< $msg->app_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Optional. A list of parameters to attach to the deployment source object,
which is a catalog entry or application template snapshot.

=item * C<< $msg->component_parameters() >> / C<< $msg->component_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::ComponentParameters>)

Optional. A list of component parameters to associate with the application.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Your own service account that you use to deploy an application.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name of the application.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the application.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Attributes>)

Optional. Attributes of the application.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::Scope>)

Required. Scope of the application.

=item * C<< $msg->import_existing_resources() >> / C<< $msg->import_existing_resources($value) >>

Type: C<Bool>

Optional. Import existing resources into the application.

=item * C<< $msg->preview_reference() >> / C<< $msg->preview_reference($value) >>

Type: C<String>

Output only. Preview reference for the application.

=item * C<< $msg->deployment_revision() >> / C<< $msg->deployment_revision($value) >>

Type: C<String>

Output only. [Output only] Optional Infra Manager deployment Id with
revision

=item * C<< $msg->apphub_application() >> / C<< $msg->apphub_application($value) >>

Type: C<String>

Output only. The App Hub App associated with the application.

=item * C<< $msg->serialized_application_template() >> / C<< $msg->serialized_application_template($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate>)

Output only. [Output only] Serialized application template.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::Application::State>)

Output only. Deployment state of the application.

=item * C<< $msg->deployment_metadata() >> / C<< $msg->deployment_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::DeploymentMetadata>)

Output only. Deployment metadata of the application.

=item * C<< $msg->project_parameters() >> / C<< $msg->project_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::ProjectParameters>)

Output only. List of project parameters for the application.

=item * C<< $msg->deployment_region() >> / C<< $msg->deployment_region($value) >>

Type: C<String>

Optional. The region where the application is deployed.

=item * C<< $msg->updated_template_revision() >> / C<< $msg->updated_template_revision($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::UpdatedTemplateRevision>)

Output only. The updated template revision because of which the application
is outdated.

=item * C<< $msg->deployment_project() >> / C<< $msg->deployment_project($value) >>

Type: C<String>

Optional. Deployment project of the application.

=item * C<< $msg->connection_configs() >> / C<< $msg->connection_configs($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::ConnectionConfig>)

Optional. Connection configuration for the application.

=item * C<< $msg->artifact_location() >> / C<< $msg->artifact_location($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Export::ArtifactLocation>)

Output only. Details of the location where the IaC for this application was
last successfully exported.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::ApplicationType>)

Optional. The type of the application.

=item * C<< $msg->deployment_target() >> / C<< $msg->deployment_target($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::DeploymentTarget>)

Optional. The deployment target of the application.

=item * C<< $msg->composition_type() >> / C<< $msg->composition_type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::ApplicationCompositionType>)

Output only. The composition type of the application: STANDARD OR
COMPOSITE.

=item * C<< $msg->composite_application_parameters() >> / C<< $msg->composite_application_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters>)

Optional. Parameters that are required for composite applications.

=item * C<< $msg->deployment_group_metadata() >> / C<< $msg->deployment_group_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata>)

Output only. The deployment group metadata of the application. This is
applicable only for composite applications.

=item * C<< $msg->params_update_strategy() >> / C<< $msg->params_update_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::Application::UpdateStrategy>)

Optional. Specifies the strategy to use when updating the application
parameters while updating the application template revision.

=item * C<< $msg->roles_apis_config() >> / C<< $msg->roles_apis_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Deployment::RolesAndApisConfig>)

Optional. Project-specific configurations required for application
deployment, including IAM roles and APIs. The list can contain up to 100
items.

=item * C<< $msg->template_metadata() >> / C<< $msg->template_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata>)

Output only. The input output variables parsed from the imported terraform
code.

=item * C<< $msg->iac_source() >> / C<< $msg->iac_source($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::IACSource>)

Output only. Indicates the IaC source format of this application.

=back

=head3 Enum: Application::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<DRAFT> => C<1>

=item * C<CREATING_DEPLOYMENT> => C<2>

=item * C<UPDATING_DEPLOYMENT> => C<3>

=item * C<DELETING> => C<4>

=item * C<DEPLOYED> => C<5>

=item * C<DELETED> => C<6>

=item * C<FAILED> => C<7>

=item * C<DEPLOYING> => C<8>

=back

=head3 Enum: Application::UpdateStrategy

=over 4

=item * C<UPDATE_STRATEGY_UNSPECIFIED> => C<0>

=item * C<REPLACE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::DeploymentResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
