package Google::Cloud::Contentwarehouse::V1::RuleEngine;

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
    eval { require Google::Iam::V1::Policy };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9ydWxlX2VuZ2luZS5wcm90bxIg
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aGmdvb2dsZS9pYW0vdjEv
cG9saWN5LnByb3RvIoACCgdSdWxlU2V0EhIKBG5hbWUYBiABKAlSBG5hbWUSIAoLZGVzY3Jp
cHRpb24YASABKAlSC2Rlc2NyaXB0aW9uEhYKBnNvdXJjZRgCIAEoCVIGc291cmNlEjwKBXJ1
bGVzGAMgAygLMiYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVsZVIFcnVs
ZXM6aepBZgonY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9SdWxlU2V0Ejtwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcnVsZVNldHMve3J1bGVfc2V0
fSLcAgoEUnVsZRIgCgtkZXNjcmlwdGlvbhgBIAEoCVILZGVzY3JpcHRpb24SFwoHcnVsZV9p
ZBgCIAEoCVIGcnVsZUlkElUKDHRyaWdnZXJfdHlwZRgDIAEoDjIyLmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLlJ1bGUuVHJpZ2dlclR5cGVSC3RyaWdnZXJUeXBlEhwKCWNv
bmRpdGlvbhgEIAEoCVIJY29uZGl0aW9uEkIKB2FjdGlvbnMYBSADKAsyKC5nb29nbGUuY2xv
dWQuY29udGVudHdhcmVob3VzZS52MS5BY3Rpb25SB2FjdGlvbnMiYAoLVHJpZ2dlclR5cGUS
CwoHVU5LTk9XThAAEg0KCU9OX0NSRUFURRABEg0KCU9OX1VQREFURRAEEhIKDk9OX0NSRUFU
RV9MSU5LEAcSEgoOT05fREVMRVRFX0xJTksQCCLrBQoGQWN0aW9uEhsKCWFjdGlvbl9pZBgB
IAEoCVIIYWN0aW9uSWQSXgoOYWNjZXNzX2NvbnRyb2wYAiABKAsyNS5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MS5BY2Nlc3NDb250cm9sQWN0aW9uSABSDWFjY2Vzc0NvbnRy
b2wSYQoPZGF0YV92YWxpZGF0aW9uGAMgASgLMjYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJl
aG91c2UudjEuRGF0YVZhbGlkYXRpb25BY3Rpb25IAFIOZGF0YVZhbGlkYXRpb24SVQoLZGF0
YV91cGRhdGUYBCABKAsyMi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5EYXRh
VXBkYXRlQWN0aW9uSABSCmRhdGFVcGRhdGUSWQoNYWRkX3RvX2ZvbGRlchgFIAEoCzIzLmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkFkZFRvRm9sZGVyQWN0aW9uSABSC2Fk
ZFRvRm9sZGVyEl4KEnB1Ymxpc2hfdG9fcHViX3N1YhgGIAEoCzIvLmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLlB1Ymxpc2hBY3Rpb25IAFIPcHVibGlzaFRvUHViU3ViEnUK
GXJlbW92ZV9mcm9tX2ZvbGRlcl9hY3Rpb24YCSABKAsyOC5nb29nbGUuY2xvdWQuY29udGVu
dHdhcmVob3VzZS52MS5SZW1vdmVGcm9tRm9sZGVyQWN0aW9uSABSFnJlbW92ZUZyb21Gb2xk
ZXJBY3Rpb24SbgoWZGVsZXRlX2RvY3VtZW50X2FjdGlvbhgKIAEoCzI2Lmdvb2dsZS5jbG91
ZC5jb250ZW50d2FyZWhvdXNlLnYxLkRlbGV0ZURvY3VtZW50QWN0aW9uSABSFGRlbGV0ZURv
Y3VtZW50QWN0aW9uQggKBmFjdGlvbiKdAgoTQWNjZXNzQ29udHJvbEFjdGlvbhJqCg5vcGVy
YXRpb25fdHlwZRgBIAEoDjJDLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkFj
Y2Vzc0NvbnRyb2xBY3Rpb24uT3BlcmF0aW9uVHlwZVINb3BlcmF0aW9uVHlwZRItCgZwb2xp
Y3kYAiABKAsyFS5nb29nbGUuaWFtLnYxLlBvbGljeVIGcG9saWN5ImsKDU9wZXJhdGlvblR5
cGUSCwoHVU5LTk9XThAAEhYKEkFERF9QT0xJQ1lfQklORElORxABEhkKFVJFTU9WRV9QT0xJ
Q1lfQklORElORxACEhoKFlJFUExBQ0VfUE9MSUNZX0JJTkRJTkcQAyK9AQoURGF0YVZhbGlk
YXRpb25BY3Rpb24SZgoKY29uZGl0aW9ucxgBIAMoCzJGLmdvb2dsZS5jbG91ZC5jb250ZW50
d2FyZWhvdXNlLnYxLkRhdGFWYWxpZGF0aW9uQWN0aW9uLkNvbmRpdGlvbnNFbnRyeVIKY29u
ZGl0aW9ucxo9Cg9Db25kaXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ASKpAQoQRGF0YVVwZGF0ZUFjdGlvbhJZCgdlbnRyaWVzGAEgAygL
Mj8uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRGF0YVVwZGF0ZUFjdGlvbi5F
bnRyaWVzRW50cnlSB2VudHJpZXMaOgoMRW50cmllc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiXAoRQWRkVG9Gb2xkZXJBY3Rpb24SRwoHZm9s
ZGVycxgBIAMoCUIt+kEqCihjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3Vt
ZW50Ugdmb2xkZXJzIn0KFlJlbW92ZUZyb21Gb2xkZXJBY3Rpb24SHAoJY29uZGl0aW9uGAEg
ASgJUgljb25kaXRpb24SRQoGZm9sZGVyGAIgASgJQi36QSoKKGNvbnRlbnR3YXJlaG91c2Uu
Z29vZ2xlYXBpcy5jb20vRG9jdW1lbnRSBmZvbGRlciJGCg1QdWJsaXNoQWN0aW9uEhkKCHRv
cGljX2lkGAEgASgJUgd0b3BpY0lkEhoKCG1lc3NhZ2VzGAIgAygJUghtZXNzYWdlcyJEChRE
ZWxldGVEb2N1bWVudEFjdGlvbhIsChJlbmFibGVfaGFyZF9kZWxldGUYASABKAhSEGVuYWJs
ZUhhcmREZWxldGUikAIKEFJ1bGVFbmdpbmVPdXRwdXQSIwoNZG9jdW1lbnRfbmFtZRgDIAEo
CVIMZG9jdW1lbnROYW1lEmkKFXJ1bGVfZXZhbHVhdG9yX291dHB1dBgBIAEoCzI1Lmdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJ1bGVFdmFsdWF0b3JPdXRwdXRSE3J1bGVF
dmFsdWF0b3JPdXRwdXQSbAoWYWN0aW9uX2V4ZWN1dG9yX291dHB1dBgCIAEoCzI2Lmdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkFjdGlvbkV4ZWN1dG9yT3V0cHV0UhRhY3Rp
b25FeGVjdXRvck91dHB1dCKHAgoTUnVsZUV2YWx1YXRvck91dHB1dBJPCg90cmlnZ2VyZWRf
cnVsZXMYASADKAsyJi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SdWxlUg50
cmlnZ2VyZWRSdWxlcxJLCg1tYXRjaGVkX3J1bGVzGAIgAygLMiYuZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjEuUnVsZVIMbWF0Y2hlZFJ1bGVzElIKDWludmFsaWRfcnVsZXMY
AyADKAsyLS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5JbnZhbGlkUnVsZVIM
aW52YWxpZFJ1bGVzIl8KC0ludmFsaWRSdWxlEjoKBHJ1bGUYASABKAsyJi5nb29nbGUuY2xv
dWQuY29udGVudHdhcmVob3VzZS52MS5SdWxlUgRydWxlEhQKBWVycm9yGAIgASgJUgVlcnJv
ciJ3ChRBY3Rpb25FeGVjdXRvck91dHB1dBJfChJydWxlX2FjdGlvbnNfcGFpcnMYASADKAsy
MS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SdWxlQWN0aW9uc1BhaXJSEHJ1
bGVBY3Rpb25zUGFpcnMipAEKD1J1bGVBY3Rpb25zUGFpchI6CgRydWxlGAEgASgLMiYuZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVsZVIEcnVsZRJVCg5hY3Rpb25fb3V0
cHV0cxgCIAMoCzIuLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkFjdGlvbk91
dHB1dFINYWN0aW9uT3V0cHV0cyKUAgoMQWN0aW9uT3V0cHV0EhsKCWFjdGlvbl9pZBgBIAEo
CVIIYWN0aW9uSWQSVwoMYWN0aW9uX3N0YXRlGAIgASgOMjQuZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjEuQWN0aW9uT3V0cHV0LlN0YXRlUgthY3Rpb25TdGF0ZRIlCg5vdXRw
dXRfbWVzc2FnZRgDIAEoCVINb3V0cHV0TWVzc2FnZSJnCgVTdGF0ZRILCgdVTktOT1dOEAAS
FAoQQUNUSU9OX1NVQ0NFRURFRBABEhEKDUFDVElPTl9GQUlMRUQQAhIUChBBQ1RJT05fVElN
RURfT1VUEAMSEgoOQUNUSU9OX1BFTkRJTkcQBEL3AQokY29tLmdvb2dsZS5jbG91ZC5jb250
ZW50d2FyZWhvdXNlLnYxQg9SdWxlRW5naW5lUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9n
by9jb250ZW50d2FyZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJlaG91c2VwYjtjb250ZW50d2Fy
ZWhvdXNlcGKqAiBHb29nbGUuQ2xvdWQuQ29udGVudFdhcmVob3VzZS5WMcoCIEdvb2dsZVxD
bG91ZFxDb250ZW50V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpDbG91ZDo6Q29udGVudFdhcmVo
b3VzZTo6VjFK5EoKBxIFDgCgAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACQKCAoBCBIDFgA9
CgkKAgglEgMWAD0KCAoBCBIDFwBnCgkKAggLEgMXAGcKCAoBCBIDGAAiCgkKAggKEgMYACIK
CAoBCBIDGQAwCgkKAggIEgMZADAKCAoBCBIDGgA9CgkKAggBEgMaAD0KCAoBCBIDGwA9CgkK
AggpEgMbAD0KCAoBCBIDHAA8CgkKAggtEgMcADwKPwoCBAASBB8ANAEaMyBSZXByZXNlbnRz
IGEgc2V0IG9mIHJ1bGVzIGZyb20gYSBzaW5nbGUgY3VzdG9tZXIuCgoKCgMEAAESAx8IDwoL
CgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKxgEKBAQAAgASAyoCEhq4ASBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgcnVsZSBzZXQuIE1hbmFnZWQgaW50ZXJuYWxseS4KIEZvcm1hdDoK
IHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcnVsZVNl
dC97cnVsZV9zZXRfaWR9LgoKIFRoZSBuYW1lIGlzIGlnbm9yZWQgd2hlbiBjcmVhdGluZyBh
IHJ1bGUgc2V0LgoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEK
MQoEBAACARIDLQIZGiQgU2hvcnQgZGVzY3JpcHRpb24gb2YgdGhlIHJ1bGUtc2V0LgoKDAoF
BAACAQUSAy0CCAoMCgUEAAIBARIDLQkUCgwKBQQAAgEDEgMtFxgKNwoEBAACAhIDMAIUGiog
U291cmNlIG9mIHRoZSBydWxlcyBpLmUuLCBjdXN0b21lciBuYW1lLgoKDAoFBAACAgUSAzAC
CAoMCgUEAAICARIDMAkPCgwKBQQAAgIDEgMwEhMKMwoEBAACAxIDMwIaGiYgTGlzdCBvZiBy
dWxlcyBnaXZlbiBieSB0aGUgY3VzdG9tZXIuCgoMCgUEAAIDBBIDMwIKCgwKBQQAAgMGEgMz
Cw8KDAoFBAACAwESAzMQFQoMCgUEAAIDAxIDMxgZCkIKAgQBEgQ3AFwBGjYgUmVwcmVzZW50
cyB0aGUgcnVsZSBmb3IgYSBjb250ZW50IHdhcmVob3VzZSB0cmlnZ2VyLgoKCgoDBAEBEgM3
CAwKLgoEBAEEABIEOQJIAxogIFRoZSB0cmlnZ2VyIHR5cGVzIGZvciBhY3Rpb25zLgoKDAoF
BAEEAAESAzkHEgosCgYEAQQAAgASAzsEEBodIFRyaWdnZXIgZm9yIHVua25vd24gYWN0aW9u
LgoKDgoHBAEEAAIAARIDOwQLCg4KBwQBBAACAAISAzsODwo0CgYEAQQAAgESAz4EEholIFRy
aWdnZXIgZm9yIGNyZWF0ZSBkb2N1bWVudCBhY3Rpb24uCgoOCgcEAQQAAgEBEgM+BA0KDgoH
BAEEAAIBAhIDPhARCjQKBgQBBAACAhIDQQQSGiUgVHJpZ2dlciBmb3IgdXBkYXRlIGRvY3Vt
ZW50IGFjdGlvbi4KCg4KBwQBBAACAgESA0EEDQoOCgcEAQQAAgICEgNBEBEKMAoGBAEEAAID
EgNEBBcaISBUcmlnZ2VyIGZvciBjcmVhdGUgbGluayBhY3Rpb24uCgoOCgcEAQQAAgMBEgNE
BBIKDgoHBAEEAAIDAhIDRBUWCjAKBgQBBAACBBIDRwQXGiEgVHJpZ2dlciBmb3IgZGVsZXRl
IGxpbmsgYWN0aW9uLgoKDgoHBAEEAAIEARIDRwQSCg4KBwQBBAACBAISA0cVFgo9CgQEAQIA
EgNLAhkaMCBTaG9ydCBkZXNjcmlwdGlvbiBvZiB0aGUgcnVsZSBhbmQgaXRzIGNvbnRleHQu
CgoMCgUEAQIABRIDSwIICgwKBQQBAgABEgNLCRQKDAoFBAECAAMSA0sXGApoCgQEAQIBEgNP
AhUaWyBJRCBvZiB0aGUgcnVsZS4gSXQgaGFzIHRvIGJlIHVuaXF1ZSBhY3Jvc3MgYWxsIHRo
ZSBleGFtcGxlcy4KIFRoaXMgaXMgbWFuYWdlZCBpbnRlcm5hbGx5LgoKDAoFBAECAQUSA08C
CAoMCgUEAQIBARIDTwkQCgwKBQQBAgEDEgNPExQKQgoEBAECAhIDUgIfGjUgSWRlbnRpZmll
cyB0aGUgdHJpZ2dlciB0eXBlIGZvciBydW5uaW5nIHRoZSBwb2xpY3kuCgoMCgUEAQICBhID
UgINCgwKBQQBAgIBEgNSDhoKDAoFBAECAgMSA1IdHgrkAQoEBAECAxIDWAIXGtYBIFJlcHJl
c2VudHMgdGhlIGNvbmRpdGlvbmFsIGV4cHJlc3Npb24gdG8gYmUgZXZhbHVhdGVkLgogRXhw
cmVzc2lvbiBzaG91bGQgZXZhbHVhdGUgdG8gYSBib29sZWFuIHJlc3VsdC4KIFdoZW4gdGhl
IGNvbmRpdGlvbiBpcyB0cnVlIGFjdGlvbnMgYXJlIGV4ZWN1dGVkLgogRXhhbXBsZTogdXNl
cl9yb2xlID0gImhzYmNfcm9sZV8xIiBBTkQgZG9jLnNhbGFyeSA+IDIwMDAwCgoMCgUEAQID
BRIDWAIICgwKBQQBAgMBEgNYCRIKDAoFBAECAwMSA1gVFgpMCgQEAQIEEgNbAh4aPyBMaXN0
IG9mIGFjdGlvbnMgdGhhdCBhcmUgZXhlY3V0ZWQgd2hlbiB0aGUgcnVsZSBpcyBzYXRpc2Zp
ZWQuCgoMCgUEAQIEBBIDWwIKCgwKBQQBAgQGEgNbCxEKDAoFBAECBAESA1sSGQoMCgUEAQIE
AxIDWxwdClMKAgQCEgRfAHkBGkcgUmVwcmVzZW50cyB0aGUgYWN0aW9uIHRyaWdnZXJlZCBi
eSBSdWxlIEVuZ2luZSB3aGVuIHRoZSBydWxlIGlzIHRydWUuCgoKCgMEAgESA18IDgo0CgQE
AgIAEgNhAhcaJyBJRCBvZiB0aGUgYWN0aW9uLiBNYW5hZ2VkIGludGVybmFsbHkuCgoMCgUE
AgIABRIDYQIICgwKBQQCAgABEgNhCRIKDAoFBAICAAMSA2EVFgoMCgQEAggAEgRjAngDCgwK
BQQCCAABEgNjCA4KOwoEBAICARIDZQQrGi4gQWN0aW9uIHRyaWdnZXJpbmcgYWNjZXNzIGNv
bnRyb2wgb3BlcmF0aW9ucy4KCgwKBQQCAgEGEgNlBBcKDAoFBAICAQESA2UYJgoMCgUEAgIB
AxIDZSkqCjwKBAQCAgISA2gELRovIEFjdGlvbiB0cmlnZ2VyaW5nIGRhdGEgdmFsaWRhdGlv
biBvcGVyYXRpb25zLgoKDAoFBAICAgYSA2gEGAoMCgUEAgICARIDaBkoCgwKBQQCAgIDEgNo
KywKOAoEBAICAxIDawQlGisgQWN0aW9uIHRyaWdnZXJpbmcgZGF0YSB1cGRhdGUgb3BlcmF0
aW9ucy4KCgwKBQQCAgMGEgNrBBQKDAoFBAICAwESA2sVIAoMCgUEAgIDAxIDayMkCkAKBAQC
AgQSA24EKBozIEFjdGlvbiB0cmlnZ2VyaW5nIGNyZWF0ZSBkb2N1bWVudCBsaW5rIG9wZXJh
dGlvbi4KCgwKBQQCAgQGEgNuBBUKDAoFBAICBAESA24WIwoMCgUEAgIEAxIDbiYnCjMKBAQC
AgUSA3EEKRomIEFjdGlvbiBwdWJsaXNoIHRvIFB1Yi9TdWIgb3BlcmF0aW9uLgoKDAoFBAIC
BQYSA3EEEQoMCgUEAgIFARIDcRIkCgwKBQQCAgUDEgNxJygKOAoEBAICBhIDdAQ5GisgQWN0
aW9uIHJlbW92aW5nIGEgZG9jdW1lbnQgZnJvbSBhIGZvbGRlci4KCgwKBQQCAgYGEgN0BBoK
DAoFBAICBgESA3QbNAoMCgUEAgIGAxIDdDc4CiwKBAQCAgcSA3cENRofIEFjdGlvbiBkZWxl
dGluZyB0aGUgZG9jdW1lbnQuCgoMCgUEAgIHBhIDdwQYCgwKBQQCAgcBEgN3GS8KDAoFBAIC
BwMSA3cyNApgCgIEAxIFfQCUAQEaUyBSZXByZXNlbnRzIHRoZSBhY3Rpb24gcmVzcG9uc2li
bGUgZm9yIGFjY2VzcyBjb250cm9sIGxpc3QgbWFuYWdlbWVudAogb3BlcmF0aW9ucy4KCgoK
AwQDARIDfQgbCjQKBAQDBAASBX8CiwEDGiUgVHlwZSBvZiBBQ0wgbW9kaWZpY2F0aW9uIG9w
ZXJhdGlvbi4KCgwKBQQDBAABEgN/BxQKLQoGBAMEAAIAEgSBAQQQGh0gVGhlIHVua25vd24g
b3BlcmF0aW9uIHR5cGUuCgoPCgcEAwQAAgABEgSBAQQLCg8KBwQDBAACAAISBIEBDg8KUQoG
BAMEAAIBEgSEAQQbGkEgQWRkcyBuZXdseSBnaXZlbiBwb2xpY3kgYmluZGluZ3MgaW4gdGhl
IGV4aXN0aW5nIGJpbmRpbmdzIGxpc3QuCgoPCgcEAwQAAgEBEgSEAQQWCg8KBwQDBAACAQIS
BIQBGRoKVgoGBAMEAAICEgSHAQQeGkYgUmVtb3ZlcyBuZXdseSBnaXZlbiBwb2xpY3kgYmlu
ZGluZ3MgZnJvbSB0aGUgZXhpc3RpbmcgYmluZGluZ3MgbGlzdC4KCg8KBwQDBAACAgESBIcB
BBkKDwoHBAMEAAICAhIEhwEcHQpWCgYEAwQAAgMSBIoBBB8aRiBSZXBsYWNlcyBleGlzdGlu
ZyBwb2xpY3kgYmluZGluZ3Mgd2l0aCB0aGUgZ2l2ZW4gcG9saWN5IGJpbmRpbmcgbGlzdAoK
DwoHBAMEAAIDARIEigEEGgoPCgcEAwQAAgMCEgSKAR0eCjEKBAQDAgASBI4BAiMaIyBJZGVu
dGlmaWVzIHRoZSB0eXBlIG9mIG9wZXJhdGlvbi4KCg0KBQQDAgAGEgSOAQIPCg0KBQQDAgAB
EgSOARAeCg0KBQQDAgADEgSOASEiCq0BCgQEAwIBEgSTAQIiGp4BIFJlcHJlc2VudHMgdGhl
IG5ldyBwb2xpY3kgZnJvbSB3aGljaCBiaW5kaW5ncyBhcmUgYWRkZWQsIHJlbW92ZWQgb3IK
IHJlcGxhY2VkIGJhc2VkIG9uIHRoZSB0eXBlIG9mIHRoZSBvcGVyYXRpb24uIHRoZSBwb2xp
Y3kgaXMgbGltaXRlZCB0byBhIGZldwogMTBzIG9mIEtCLgoKDQoFBAMCAQYSBJMBAhYKDQoF
BAMCAQESBJMBFx0KDQoFBAMCAQMSBJMBICEKUQoCBAQSBpcBAJwBARpDIFJlcHJlc2VudHMg
dGhlIGFjdGlvbiByZXNwb25zaWJsZSBmb3IgZGF0YSB2YWxpZGF0aW9uIG9wZXJhdGlvbnMu
CgoLCgMEBAESBJcBCBwK7wEKBAQEAgASBJsBAiUa4AEgTWFwIG9mIChLLCBWKSAtPiAoZmll
bGQsIHN0cmluZyBjb25kaXRpb24gdG8gYmUgZXZhbHVhdGVkIG9uIHRoZSBmaWVsZCkKIEUu
Zy4sICgiYWdlIiwgImFnZSA+IDE4ICAmJiBhZ2UgPCA2MCIpIGVudHJ5IHRyaWdnZXJzIHZh
bGlkYXRpb24gb2YgZmllbGQKIGFnZSB3aXRoIHRoZSBnaXZlbiBjb25kaXRpb24uIE1hcCBl
bnRyaWVzIHdpbGwgYmUgQU5EZWQgZHVyaW5nIHZhbGlkYXRpb24uCgoNCgUEBAIABhIEmwEC
FQoNCgUEBAIAARIEmwEWIAoNCgUEBAIAAxIEmwEjJApTCgIEBRIGnwEApgEBGkUgUmVwcmVz
ZW50cyB0aGUgYWN0aW9uIHJlc3BvbnNpYmxlIGZvciBwcm9wZXJ0aWVzIHVwZGF0ZSBvcGVy
YXRpb25zLgoKCwoDBAUBEgSfAQgYCqoCCgQEBQIAEgSlAQIiGpsCIE1hcCBvZiAoSywgVikg
LT4gKHZhbGlkIG5hbWUgb2YgdGhlIGZpZWxkLCBuZXcgdmFsdWUgb2YgdGhlIGZpZWxkKQog
RS5nLiwgKCJhZ2UiLCAiNjAiKSBlbnRyeSB0cmlnZ2VycyB1cGRhdGUgb2YgZmllbGQgYWdl
IHdpdGggYSB2YWx1ZSBvZiA2MC4KIElmIHRoZSBmaWVsZCBpcyBub3QgcHJlc2VudCB0aGVu
IG5ldyBlbnRyeSBpcyBhZGRlZC4KIER1cmluZyB1cGRhdGUgYWN0aW9uIGV4ZWN1dGlvbiwg
dmFsdWUgc3RyaW5ncyB3aWxsIGJlIGNhc3RlZCB0bwogYXBwcm9wcmlhdGUgdHlwZXMuCgoN
CgUEBQIABhIEpQECFQoNCgUEBQIAARIEpQEWHQoNCgUEBQIAAxIEpQEgIQpVCgIEBhIGqQEA
sAEBGkcgUmVwcmVzZW50cyB0aGUgYWN0aW9uIHJlc3BvbnNpYmxlIGZvciBhZGRpbmcgZG9j
dW1lbnQgdW5kZXIgYSBmb2xkZXIuCgoLCgMEBgESBKkBCBkKoQEKBAQGAgASBq0BAq8BBRqQ
ASBOYW1lcyBvZiB0aGUgZm9sZGVyIHVuZGVyIHdoaWNoIG5ldyBkb2N1bWVudCBpcyB0byBi
ZSBhZGRlZC4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tkb2N1bWVudF9pZH0uCgoNCgUEBgIABBIErQECCgoN
CgUEBgIABRIErQELEQoNCgUEBgIAARIErQESGQoNCgUEBgIAAxIErQEcHQoPCgUEBgIACBIG
rQEerwEEChEKBwQGAgAInwgSBq0BH68BAwpgCgIEBxIGtAEAvgEBGlIgUmVwcmVzZW50cyB0
aGUgYWN0aW9uIHJlc3BvbnNpYmxlIGZvciByZW1vdmUgYSBkb2N1bWVudCBmcm9tIGEgc3Bl
Y2lmaWMKIGZvbGRlci4KCgsKAwQHARIEtAEIHgo3CgQEBwIAEgS2AQIXGikgQ29uZGl0aW9u
IG9mIHRoZSBhY3Rpb24gdG8gYmUgZXhlY3V0ZWQuCgoNCgUEBwIABRIEtgECCAoNCgUEBwIA
ARIEtgEJEgoNCgUEBwIAAxIEtgEVFgqgAQoEBAcCARIGuwECvQEFGo8BIE5hbWUgb2YgdGhl
IGZvbGRlciB1bmRlciB3aGljaCBuZXcgZG9jdW1lbnQgaXMgdG8gYmUgYWRkZWQuCiBGb3Jt
YXQ6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2Rv
Y3VtZW50cy97ZG9jdW1lbnRfaWR9LgoKDQoFBAcCAQUSBLsBAggKDQoFBAcCAQESBLsBCQ8K
DQoFBAcCAQMSBLsBEhMKDwoFBAcCAQgSBrsBFL0BBAoRCgcEBwIBCJ8IEga7ARW9AQMKXQoC
BAgSBsEBAMgBARpPIFJlcHJlc2VudHMgdGhlIGFjdGlvbiByZXNwb25zaWJsZSBmb3IgcHVi
bGlzaGluZyBtZXNzYWdlcyB0byBhIFB1Yi9TdWIgdG9waWMuCgoLCgMECAESBMEBCBUKXQoE
BAgCABIExAECFhpPIFRoZSB0b3BpYyBpZCBpbiB0aGUgUHViL1N1YiBzZXJ2aWNlIGZvciB3
aGljaCBtZXNzYWdlcyB3aWxsIGJlIHB1Ymxpc2hlZAogdG8uCgoNCgUECAIABRIExAECCAoN
CgUECAIAARIExAEJEQoNCgUECAIAAxIExAEUFQopCgQECAIBEgTHAQIfGhsgTWVzc2FnZXMg
dG8gYmUgcHVibGlzaGVkLgoKDQoFBAgCAQQSBMcBAgoKDQoFBAgCAQUSBMcBCxEKDQoFBAgC
AQESBMcBEhoKDQoFBAgCAQMSBMcBHR4KTAoCBAkSBssBAM8BARo+IFJlcHJlc2VudHMgdGhl
IGFjdGlvbiByZXNwb25zaWJsZSBmb3IgZGVsZXRpbmcgdGhlIGRvY3VtZW50LgoKCwoDBAkB
EgTLAQgcCokBCgQECQIAEgTOAQIeGnsgQm9vbGVhbiBmaWVsZCB0byBzZWxlY3QgYmV0d2Vl
biBoYXJkIHZzIHNvZnQgZGVsZXRlIG9wdGlvbnMuCiBTZXQgJ3RydWUnIGZvciAnaGFyZCBk
ZWxldGUnIGFuZCAnZmFsc2UnIGZvciAnc29mdCBkZWxldGUnLgoKDQoFBAkCAAUSBM4BAgYK
DQoFBAkCAAESBM4BBxkKDQoFBAkCAAMSBM4BHB0KYAoCBAoSBtMBAN0BARpSIFJlY29yZHMg
dGhlIG91dHB1dCBvZiBSdWxlIEVuZ2luZSBpbmNsdWRpbmcgcnVsZSBldmFsdWF0aW9uIGFu
ZCBhY3Rpb25zCiByZXN1bHQuCgoLCgMECgESBNMBCBgKWAoEBAoCABIE1QECGxpKIE5hbWUg
b2YgdGhlIGRvY3VtZW50IGFnYWluc3Qgd2hpY2ggdGhlIHJ1bGVzIGFuZCBhY3Rpb25zIHdl
cmUgZXZhbHVhdGVkLgoKDQoFBAoCAAUSBNUBAggKDQoFBAoCAAESBNUBCRYKDQoFBAoCAAMS
BNUBGRoKWwoEBAoCARIE2AECMBpNIE91dHB1dCBmcm9tIFJ1bGUgRXZhbHVhdG9yIGNvbnRh
aW5pbmcgbWF0Y2hlZCwgdW5tYXRjaGVkIGFuZCBpbnZhbGlkIHJ1bGVzLgoKDQoFBAoCAQYS
BNgBAhUKDQoFBAoCAQESBNgBFisKDQoFBAoCAQMSBNgBLi8KaAoEBAoCAhIE3AECMhpaIE91
dHB1dCBmcm9tIEFjdGlvbiBFeGVjdXRvciBjb250YWluaW5nIHJ1bGUgYW5kIGNvcnJlc3Bv
bmRpbmcgYWN0aW9ucwogZXhlY3V0aW9uIHJlc3VsdC4KCg0KBQQKAgIGEgTcAQIWCg0KBQQK
AgIBEgTcARctCg0KBQQKAgIDEgTcATAxCjwKAgQLEgbgAQDqAQEaLiBSZXByZXNlbnRzIHRo
ZSBvdXRwdXQgb2YgdGhlIFJ1bGUgRXZhbHVhdG9yLgoKCwoDBAsBEgTgAQgbClcKBAQLAgAS
BOIBAiQaSSBMaXN0IG9mIHJ1bGVzIGZldGNoZWQgZnJvbSBkYXRhYmFzZSBmb3IgdGhlIGdp
dmVuIHJlcXVlc3QgdHJpZ2dlciB0eXBlLgoKDQoFBAsCAAQSBOIBAgoKDQoFBAsCAAYSBOIB
Cw8KDQoFBAsCAAESBOIBEB8KDQoFBAsCAAMSBOIBIiMKWAoEBAsCARIE5QECIhpKIEEgc3Vi
c2V0IG9mIHRyaWdnZXJlZCBydWxlcyB0aGF0IGFyZSBldmFsdWF0ZWQgdHJ1ZSBmb3IgYSBn
aXZlbiByZXF1ZXN0LgoKDQoFBAsCAQQSBOUBAgoKDQoFBAsCAQYSBOUBCw8KDQoFBAsCAQES
BOUBEB0KDQoFBAsCAQMSBOUBICEKXwoEBAsCAhIE6QECKRpRIEEgc3Vic2V0IG9mIHRyaWdn
ZXJlZCBydWxlcyB0aGF0IGZhaWxlZCB0aGUgdmFsaWRhdGlvbiBjaGVjayhzKSBhZnRlcgog
cGFyc2luZy4KCg0KBQQLAgIEEgTpAQIKCg0KBQQLAgIGEgTpAQsWCg0KBQQLAgIBEgTpARck
Cg0KBQQLAgIDEgTpAScoClMKAgQMEgbtAQDzAQEaRSBBIHRyaWdnZXJlZCBydWxlIHRoYXQg
ZmFpbGVkIHRoZSB2YWxpZGF0aW9uIGNoZWNrKHMpIGFmdGVyIHBhcnNpbmcuCgoLCgMEDAES
BO0BCBMKHwoEBAwCABIE7wECEBoRIFRyaWdnZXJlZCBydWxlLgoKDQoFBAwCAAYSBO8BAgYK
DQoFBAwCAAESBO8BBwsKDQoFBAwCAAMSBO8BDg8KOAoEBAwCARIE8gECExoqIFZhbGlkYXRp
b24gZXJyb3Igb24gYSBwYXJzZWQgZXhwcmVzc2lvbi4KCg0KBQQMAgEFEgTyAQIICg0KBQQM
AgEBEgTyAQkOCg0KBQQMAgEDEgTyARESCj0KAgQNEgb2AQD5AQEaLyBSZXByZXNlbnRzIHRo
ZSBvdXRwdXQgb2YgdGhlIEFjdGlvbiBFeGVjdXRvci4KCgsKAwQNARIE9gEIHAo+CgQEDQIA
EgT4AQIyGjAgTGlzdCBvZiBydWxlIGFuZCBjb3JyZXNwb25kaW5nIGFjdGlvbnMgcmVzdWx0
LgoKDQoFBA0CAAQSBPgBAgoKDQoFBA0CAAYSBPgBCxoKDQoFBA0CAAESBPgBGy0KDQoFBA0C
AAMSBPgBMDEKRAoCBA4SBvwBAIICARo2IFJlcHJlc2VudHMgYSBydWxlIGFuZCBvdXRwdXRz
IG9mIGFzc29jaWF0ZWQgYWN0aW9ucy4KCgsKAwQOARIE/AEIFwokCgQEDgIAEgT+AQIQGhYg
UmVwcmVzZW50cyB0aGUgcnVsZS4KCg0KBQQOAgAGEgT+AQIGCg0KBQQOAgABEgT+AQcLCg0K
BQQOAgADEgT+AQ4PClAKBAQOAgESBIECAisaQiBPdXRwdXRzIG9mIGV4ZWN1dGluZyB0aGUg
YWN0aW9ucyBhc3NvY2lhdGVkIHdpdGggdGhlIGFib3ZlIHJ1bGUuCgoNCgUEDgIBBBIEgQIC
CgoNCgUEDgIBBhIEgQILFwoNCgUEDgIBARIEgQIYJgoNCgUEDgIBAxIEgQIpKgo9CgIEDxIG
hQIAoAIBGi8gUmVwcmVzZW50cyB0aGUgcmVzdWx0IG9mIGV4ZWN1dGluZyBhbiBhY3Rpb24u
CgoLCgMEDwESBIUCCBQKOwoEBA8EABIGhwIClgIDGisgUmVwcmVzZW50cyBleGVjdXRpb24g
c3RhdGUgb2YgdGhlIGFjdGlvbi4KCg0KBQQPBAABEgSHAgcMCiQKBgQPBAACABIEiQIEEBoU
IFRoZSB1bmtub3duIHN0YXRlLgoKDwoHBA8EAAIAARIEiQIECwoPCgcEDwQAAgACEgSJAg4P
CkAKBgQPBAACARIEjAIEGRowIFN0YXRlIGluZGljYXRpbmcgYWN0aW9uIGV4ZWN1dGVkIHN1
Y2Nlc3NmdWxseS4KCg8KBwQPBAACAQESBIwCBBQKDwoHBA8EAAIBAhIEjAIXGAoxCgYEDwQA
AgISBI8CBBYaISBTdGF0ZSBpbmRpY2F0aW5nIGFjdGlvbiBmYWlsZWQuCgoPCgcEDwQAAgIB
EgSPAgQRCg8KBwQPBAACAgISBI8CFBUKNAoGBA8EAAIDEgSSAgQZGiQgU3RhdGUgaW5kaWNh
dGluZyBhY3Rpb24gdGltZWQgb3V0LgoKDwoHBA8EAAIDARIEkgIEFAoPCgcEDwQAAgMCEgSS
AhcYCjUKBgQPBAACBBIElQIEFxolIFN0YXRlIGluZGljYXRpbmcgYWN0aW9uIGlzIHBlbmRp
bmcuCgoPCgcEDwQAAgQBEgSVAgQSCg8KBwQPBAACBAISBJUCFRYKIQoEBA8CABIEmQICFxoT
IElEIG9mIHRoZSBhY3Rpb24uCgoNCgUEDwIABRIEmQICCAoNCgUEDwIAARIEmQIJEgoNCgUE
DwIAAxIEmQIVFgojCgQEDwIBEgScAgIZGhUgU3RhdGUgb2YgYW4gYWN0aW9uLgoKDQoFBA8C
AQYSBJwCAgcKDQoFBA8CAQESBJwCCBQKDQoFBA8CAQMSBJwCFxgKMAoEBA8CAhIEnwICHBoi
IEFjdGlvbiBleGVjdXRpb24gb3V0cHV0IG1lc3NhZ2UuCgoNCgUEDwICBRIEnwICCAoNCgUE
DwICARIEnwIJFwoNCgUEDwICAxIEnwIaG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet ===
    # Fields for RuleSet
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: source Type: 9 ()
    # Field: rules Type: 11 (.google.cloud.contentwarehouse.v1.Rule)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule ===
    # Fields for Rule
    # Field: description Type: 9 ()
    # Field: rule_id Type: 9 ()
    # Field: trigger_type Type: 14 (.google.cloud.contentwarehouse.v1.Rule.TriggerType)
    # Field: condition Type: 9 ()
    # Field: actions Type: 11 (.google.cloud.contentwarehouse.v1.Action)

# Enum: Rule::TriggerType
our $Rule_UNKNOWN = 0;
our $Rule_ON_CREATE = 1;
our $Rule_ON_UPDATE = 4;
our $Rule_ON_CREATE_LINK = 7;
our $Rule_ON_DELETE_LINK = 8;

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::Action ===
    # Fields for Action
    # Field: action_id Type: 9 ()
    # Field: access_control Type: 11 (.google.cloud.contentwarehouse.v1.AccessControlAction)
    # Field: data_validation Type: 11 (.google.cloud.contentwarehouse.v1.DataValidationAction)
    # Field: data_update Type: 11 (.google.cloud.contentwarehouse.v1.DataUpdateAction)
    # Field: add_to_folder Type: 11 (.google.cloud.contentwarehouse.v1.AddToFolderAction)
    # Field: publish_to_pub_sub Type: 11 (.google.cloud.contentwarehouse.v1.PublishAction)
    # Field: remove_from_folder_action Type: 11 (.google.cloud.contentwarehouse.v1.RemoveFromFolderAction)
    # Field: delete_document_action Type: 11 (.google.cloud.contentwarehouse.v1.DeleteDocumentAction)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction ===
    # Fields for AccessControlAction
    # Field: operation_type Type: 14 (.google.cloud.contentwarehouse.v1.AccessControlAction.OperationType)
    # Field: policy Type: 11 (.google.iam.v1.Policy)

# Enum: AccessControlAction::OperationType
our $AccessControlAction_UNKNOWN = 0;
our $AccessControlAction_ADD_POLICY_BINDING = 1;
our $AccessControlAction_REMOVE_POLICY_BINDING = 2;
our $AccessControlAction_REPLACE_POLICY_BINDING = 3;

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction ===
    # Fields for DataValidationAction
    # Field: conditions Type: 11 (.google.cloud.contentwarehouse.v1.DataValidationAction.ConditionsEntry)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction ===
    # Fields for DataUpdateAction
    # Field: entries Type: 11 (.google.cloud.contentwarehouse.v1.DataUpdateAction.EntriesEntry)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction ===
    # Fields for AddToFolderAction
    # Field: folders Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction ===
    # Fields for RemoveFromFolderAction
    # Field: condition Type: 9 ()
    # Field: folder Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction ===
    # Fields for PublishAction
    # Field: topic_id Type: 9 ()
    # Field: messages Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction ===
    # Fields for DeleteDocumentAction
    # Field: enable_hard_delete Type: 8 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput ===
    # Fields for RuleEngineOutput
    # Field: document_name Type: 9 ()
    # Field: rule_evaluator_output Type: 11 (.google.cloud.contentwarehouse.v1.RuleEvaluatorOutput)
    # Field: action_executor_output Type: 11 (.google.cloud.contentwarehouse.v1.ActionExecutorOutput)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput ===
    # Fields for RuleEvaluatorOutput
    # Field: triggered_rules Type: 11 (.google.cloud.contentwarehouse.v1.Rule)
    # Field: matched_rules Type: 11 (.google.cloud.contentwarehouse.v1.Rule)
    # Field: invalid_rules Type: 11 (.google.cloud.contentwarehouse.v1.InvalidRule)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule ===
    # Fields for InvalidRule
    # Field: rule Type: 11 (.google.cloud.contentwarehouse.v1.Rule)
    # Field: error Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput ===
    # Fields for ActionExecutorOutput
    # Field: rule_actions_pairs Type: 11 (.google.cloud.contentwarehouse.v1.RuleActionsPair)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair ===
    # Fields for RuleActionsPair
    # Field: rule Type: 11 (.google.cloud.contentwarehouse.v1.Rule)
    # Field: action_outputs Type: 11 (.google.cloud.contentwarehouse.v1.ActionOutput)

# === Message: Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput ===
    # Fields for ActionOutput
    # Field: action_id Type: 9 ()
    # Field: action_state Type: 14 (.google.cloud.contentwarehouse.v1.ActionOutput.State)
    # Field: output_message Type: 9 ()

# Enum: ActionOutput::State
our $ActionOutput_UNKNOWN = 0;
our $ActionOutput_ACTION_SUCCEEDED = 1;
our $ActionOutput_ACTION_FAILED = 2;
our $ActionOutput_ACTION_TIMED_OUT = 3;
our $ActionOutput_ACTION_PENDING = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::RuleEngine - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/rule_engine.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::RuleEngine;

    my $msg = Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet->new({
        name => $name,
        description => $description,
        source => $source,
        rules => $rules,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/rule_engine.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet

Represents a set of rules from a single customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the rule set. Managed internally.
Format:
projects/{project_number}/locations/{location}/ruleSet/{rule_set_id}.

The name is ignored when creating a rule set.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Short description of the rule-set.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Source of the rules i.e., customer name.

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule>)

List of rules given by the customer.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule

Represents the rule for a content warehouse trigger.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Short description of the rule and its context.

=item * C<< $msg->rule_id() >> / C<< $msg->rule_id($value) >>

Type: C<String>

ID of the rule. It has to be unique across all the examples.
This is managed internally.

=item * C<< $msg->trigger_type() >> / C<< $msg->trigger_type($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::Rule::TriggerType>)

Identifies the trigger type for running the policy.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Represents the conditional expression to be evaluated.
Expression should evaluate to a boolean result.
When the condition is true actions are executed.
Example: user_role = "hsbc_role_1" AND doc.salary > 20000

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Action>)

List of actions that are executed when the rule is satisfied.

=back

=head3 Enum: Rule::TriggerType

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<ON_CREATE> => C<1>

=item * C<ON_UPDATE> => C<4>

=item * C<ON_CREATE_LINK> => C<7>

=item * C<ON_DELETE_LINK> => C<8>

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::Action

Represents the action triggered by Rule Engine when the rule is true.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_id() >> / C<< $msg->action_id($value) >>

Type: C<String>

ID of the action. Managed internally.

=item * C<< $msg->access_control() >> / C<< $msg->access_control($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction>)

Action triggering access control operations.

=item * C<< $msg->data_validation() >> / C<< $msg->data_validation($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction>)

Action triggering data validation operations.

=item * C<< $msg->data_update() >> / C<< $msg->data_update($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction>)

Action triggering data update operations.

=item * C<< $msg->add_to_folder() >> / C<< $msg->add_to_folder($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction>)

Action triggering create document link operation.

=item * C<< $msg->publish_to_pub_sub() >> / C<< $msg->publish_to_pub_sub($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction>)

Action publish to Pub/Sub operation.

=item * C<< $msg->remove_from_folder_action() >> / C<< $msg->remove_from_folder_action($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction>)

Action removing a document from a folder.

=item * C<< $msg->delete_document_action() >> / C<< $msg->delete_document_action($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction>)

Action deleting the document.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction

Represents the action responsible for access control list management
operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::AccessControlAction::OperationType>)

Identifies the type of operation.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

Represents the new policy from which bindings are added, removed or
replaced based on the type of the operation. the policy is limited to a few
10s of KB.

=back

=head3 Enum: AccessControlAction::OperationType

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<ADD_POLICY_BINDING> => C<1>

=item * C<REMOVE_POLICY_BINDING> => C<2>

=item * C<REPLACE_POLICY_BINDING> => C<3>

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction

Represents the action responsible for data validation operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction::ConditionsEntry>)

Map of (K, V) -> (field, string condition to be evaluated on the field)
E.g., ("age", "age > 18  && age < 60") entry triggers validation of field
age with the given condition. Map entries will be ANDed during validation.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction

Represents the action responsible for properties update operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction::EntriesEntry>)

Map of (K, V) -> (valid name of the field, new value of the field)
E.g., ("age", "60") entry triggers update of field age with a value of 60.
If the field is not present then new entry is added.
During update action execution, value strings will be casted to
appropriate types.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction

Represents the action responsible for adding document under a folder.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->folders() >> / C<< $msg->folders($value) >>

Type: C<String>

Names of the folder under which new document is to be added.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction

Represents the action responsible for remove a document from a specific
folder.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Condition of the action to be executed.

=item * C<< $msg->folder() >> / C<< $msg->folder($value) >>

Type: C<String>

Name of the folder under which new document is to be added.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction

Represents the action responsible for publishing messages to a Pub/Sub topic.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic_id() >> / C<< $msg->topic_id($value) >>

Type: C<String>

The topic id in the Pub/Sub service for which messages will be published
to.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<String>

Messages to be published.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction

Represents the action responsible for deleting the document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_hard_delete() >> / C<< $msg->enable_hard_delete($value) >>

Type: C<Bool>

Boolean field to select between hard vs soft delete options.
Set 'true' for 'hard delete' and 'false' for 'soft delete'.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput

Records the output of Rule Engine including rule evaluation and actions
result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_name() >> / C<< $msg->document_name($value) >>

Type: C<String>

Name of the document against which the rules and actions were evaluated.

=item * C<< $msg->rule_evaluator_output() >> / C<< $msg->rule_evaluator_output($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput>)

Output from Rule Evaluator containing matched, unmatched and invalid rules.

=item * C<< $msg->action_executor_output() >> / C<< $msg->action_executor_output($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput>)

Output from Action Executor containing rule and corresponding actions
execution result.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput

Represents the output of the Rule Evaluator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->triggered_rules() >> / C<< $msg->triggered_rules($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule>)

List of rules fetched from database for the given request trigger type.

=item * C<< $msg->matched_rules() >> / C<< $msg->matched_rules($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule>)

A subset of triggered rules that are evaluated true for a given request.

=item * C<< $msg->invalid_rules() >> / C<< $msg->invalid_rules($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule>)

A subset of triggered rules that failed the validation check(s) after
parsing.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule

A triggered rule that failed the validation check(s) after parsing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule>)

Triggered rule.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<String>

Validation error on a parsed expression.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput

Represents the output of the Action Executor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_actions_pairs() >> / C<< $msg->rule_actions_pairs($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair>)

List of rule and corresponding actions result.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair

Represents a rule and outputs of associated actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule>)

Represents the rule.

=item * C<< $msg->action_outputs() >> / C<< $msg->action_outputs($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput>)

Outputs of executing the actions associated with the above rule.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput

Represents the result of executing an action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_id() >> / C<< $msg->action_id($value) >>

Type: C<String>

ID of the action.

=item * C<< $msg->action_state() >> / C<< $msg->action_state($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::ActionOutput::State>)

State of an action.

=item * C<< $msg->output_message() >> / C<< $msg->output_message($value) >>

Type: C<String>

Action execution output message.

=back

=head3 Enum: ActionOutput::State

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<ACTION_SUCCEEDED> => C<1>

=item * C<ACTION_FAILED> => C<2>

=item * C<ACTION_TIMED_OUT> => C<3>

=item * C<ACTION_PENDING> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::RuleEngine::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
