package Google::Monitoring::V3::GroupService;

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
    eval { require Google::Api::MonitoredResource };
    eval { require Google::Api::Resource };
    eval { require Google::Monitoring::V3::Common };
    eval { require Google::Monitoring::V3::Group };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvbW9uaXRvcmluZy92My9ncm91cF9zZXJ2aWNlLnByb3RvEhRnb29nbGUubW9u
aXRvcmluZy52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aI2dvb2dsZS9h
cGkvbW9uaXRvcmVkX3Jlc291cmNlLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GiFnb29nbGUvbW9uaXRvcmluZy92My9jb21tb24ucHJvdG8aIGdvb2dsZS9tb25pdG9yaW5n
L3YzL2dyb3VwLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8imgMKEUxpc3RH
cm91cHNSZXF1ZXN0EjsKBG5hbWUYByABKAlCJ+BBAvpBIRIfbW9uaXRvcmluZy5nb29nbGVh
cGlzLmNvbS9Hcm91cFIEbmFtZRJSChFjaGlsZHJlbl9vZl9ncm91cBgCIAEoCUIk+kEhCh9t
b25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL0dyb3VwSABSD2NoaWxkcmVuT2ZHcm91cBJUChJh
bmNlc3RvcnNfb2ZfZ3JvdXAYAyABKAlCJPpBIQofbW9uaXRvcmluZy5nb29nbGVhcGlzLmNv
bS9Hcm91cEgAUhBhbmNlc3RvcnNPZkdyb3VwElgKFGRlc2NlbmRhbnRzX29mX2dyb3VwGAQg
ASgJQiT6QSEKH21vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vR3JvdXBIAFISZGVzY2VuZGFu
dHNPZkdyb3VwEhsKCXBhZ2Vfc2l6ZRgFIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgG
IAEoCVIJcGFnZVRva2VuQggKBmZpbHRlciJvChJMaXN0R3JvdXBzUmVzcG9uc2USMQoFZ3Jv
dXAYASADKAsyGy5nb29nbGUubW9uaXRvcmluZy52My5Hcm91cFIFZ3JvdXASJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIk4KD0dldEdyb3VwUmVxdWVzdBI7CgRu
YW1lGAMgASgJQifgQQL6QSEKH21vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vR3JvdXBSBG5h
bWUirgEKEkNyZWF0ZUdyb3VwUmVxdWVzdBI7CgRuYW1lGAQgASgJQifgQQL6QSESH21vbml0
b3JpbmcuZ29vZ2xlYXBpcy5jb20vR3JvdXBSBG5hbWUSNgoFZ3JvdXAYAiABKAsyGy5nb29n
bGUubW9uaXRvcmluZy52My5Hcm91cEID4EECUgVncm91cBIjCg12YWxpZGF0ZV9vbmx5GAMg
ASgIUgx2YWxpZGF0ZU9ubHkicQoSVXBkYXRlR3JvdXBSZXF1ZXN0EjYKBWdyb3VwGAIgASgL
MhsuZ29vZ2xlLm1vbml0b3JpbmcudjMuR3JvdXBCA+BBAlIFZ3JvdXASIwoNdmFsaWRhdGVf
b25seRgDIAEoCFIMdmFsaWRhdGVPbmx5Im8KEkRlbGV0ZUdyb3VwUmVxdWVzdBI7CgRuYW1l
GAMgASgJQifgQQL6QSEKH21vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vR3JvdXBSBG5hbWUS
HAoJcmVjdXJzaXZlGAQgASgIUglyZWN1cnNpdmUi6gEKF0xpc3RHcm91cE1lbWJlcnNSZXF1
ZXN0EjsKBG5hbWUYByABKAlCJ+BBAvpBIQofbW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9H
cm91cFIEbmFtZRIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
BCABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBSABKAlSBmZpbHRlchI+CghpbnRlcnZhbBgG
IAEoCzIiLmdvb2dsZS5tb25pdG9yaW5nLnYzLlRpbWVJbnRlcnZhbFIIaW50ZXJ2YWwimgEK
GExpc3RHcm91cE1lbWJlcnNSZXNwb25zZRI3CgdtZW1iZXJzGAEgAygLMh0uZ29vZ2xlLmFw
aS5Nb25pdG9yZWRSZXNvdXJjZVIHbWVtYmVycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4SHQoKdG90YWxfc2l6ZRgDIAEoBVIJdG90YWxTaXplMpgICgxHcm91
cFNlcnZpY2USjAEKCkxpc3RHcm91cHMSJy5nb29nbGUubW9uaXRvcmluZy52My5MaXN0R3Jv
dXBzUmVxdWVzdBooLmdvb2dsZS5tb25pdG9yaW5nLnYzLkxpc3RHcm91cHNSZXNwb25zZSIr
gtPkkwIeEhwvdjMve25hbWU9cHJvamVjdHMvKn0vZ3JvdXBz2kEEbmFtZRJ9CghHZXRHcm91
cBIlLmdvb2dsZS5tb25pdG9yaW5nLnYzLkdldEdyb3VwUmVxdWVzdBobLmdvb2dsZS5tb25p
dG9yaW5nLnYzLkdyb3VwIi2C0+STAiASHi92My97bmFtZT1wcm9qZWN0cy8qL2dyb3Vwcy8q
fdpBBG5hbWUSjgEKC0NyZWF0ZUdyb3VwEiguZ29vZ2xlLm1vbml0b3JpbmcudjMuQ3JlYXRl
R3JvdXBSZXF1ZXN0GhsuZ29vZ2xlLm1vbml0b3JpbmcudjMuR3JvdXAiOILT5JMCJSIcL3Yz
L3tuYW1lPXByb2plY3RzLyp9L2dyb3VwczoFZ3JvdXDaQQpuYW1lLGdyb3VwEpEBCgtVcGRh
dGVHcm91cBIoLmdvb2dsZS5tb25pdG9yaW5nLnYzLlVwZGF0ZUdyb3VwUmVxdWVzdBobLmdv
b2dsZS5tb25pdG9yaW5nLnYzLkdyb3VwIjuC0+STAi0aJC92My97Z3JvdXAubmFtZT1wcm9q
ZWN0cy8qL2dyb3Vwcy8qfToFZ3JvdXDaQQVncm91cBJ+CgtEZWxldGVHcm91cBIoLmdvb2ds
ZS5tb25pdG9yaW5nLnYzLkRlbGV0ZUdyb3VwUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5F
bXB0eSItgtPkkwIgKh4vdjMve25hbWU9cHJvamVjdHMvKi9ncm91cHMvKn3aQQRuYW1lEqgB
ChBMaXN0R3JvdXBNZW1iZXJzEi0uZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdEdyb3VwTWVt
YmVyc1JlcXVlc3QaLi5nb29nbGUubW9uaXRvcmluZy52My5MaXN0R3JvdXBNZW1iZXJzUmVz
cG9uc2UiNYLT5JMCKBImL3YzL3tuYW1lPXByb2plY3RzLyovZ3JvdXBzLyp9L21lbWJlcnPa
QQRuYW1lGqkBykEZbW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbdJBiQFodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvbW9uaXRvcmluZyxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L21vbml0b3JpbmcucmVhZELMAQoYY29tLmdvb2dsZS5tb25pdG9yaW5nLnYzQhFHcm91cFNl
cnZpY2VQcm90b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIv
bW9uaXRvcmluZ3BiO21vbml0b3JpbmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYz
ygIaR29vZ2xlXENsb3VkXE1vbml0b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9y
aW5nOjpWM0qGRwoHEgUOAKUCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAHQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAt
CgkKAgMEEgMWACMKCQoCAwUSAxcAKwoJCgIDBhIDGAAqCgkKAgMHEgMZACUKCAoBCBIDGwA3
CgkKAgglEgMbADcKCAoBCBIDHABYCgkKAggLEgMcAFgKCAoBCBIDHQAiCgkKAggKEgMdACIK
CAoBCBIDHgAyCgkKAggIEgMeADIKCAoBCBIDHwAxCgkKAggBEgMfADEKCAoBCBIDIAA3CgkK
AggpEgMgADcKCAoBCBIDIQA2CgkKAggtEgMhADYKhAUKAgYAEgQvAGkBGvcEIFRoZSBHcm91
cCBBUEkgbGV0cyB5b3UgaW5zcGVjdCBhbmQgbWFuYWdlIHlvdXIKIFtncm91cHNdKCNnb29n
bGUubW9uaXRvcmluZy52My5Hcm91cCkuCgogQSBncm91cCBpcyBhIG5hbWVkIGZpbHRlciB0
aGF0IGlzIHVzZWQgdG8gaWRlbnRpZnkKIGEgY29sbGVjdGlvbiBvZiBtb25pdG9yZWQgcmVz
b3VyY2VzLiBHcm91cHMgYXJlIHR5cGljYWxseSB1c2VkIHRvCiBtaXJyb3IgdGhlIHBoeXNp
Y2FsIGFuZC9vciBsb2dpY2FsIHRvcG9sb2d5IG9mIHRoZSBlbnZpcm9ubWVudC4KIEJlY2F1
c2UgZ3JvdXAgbWVtYmVyc2hpcCBpcyBjb21wdXRlZCBkeW5hbWljYWxseSwgbW9uaXRvcmVk
CiByZXNvdXJjZXMgdGhhdCBhcmUgc3RhcnRlZCBpbiB0aGUgZnV0dXJlIGFyZSBhdXRvbWF0
aWNhbGx5IHBsYWNlZAogaW4gbWF0Y2hpbmcgZ3JvdXBzLiBCeSB1c2luZyBhIGdyb3VwIHRv
IG5hbWUgbW9uaXRvcmVkIHJlc291cmNlcyBpbiwKIGZvciBleGFtcGxlLCBhbiBhbGVydCBw
b2xpY3ksIHRoZSB0YXJnZXQgb2YgdGhhdCBhbGVydCBwb2xpY3kgaXMKIHVwZGF0ZWQgYXV0
b21hdGljYWxseSBhcyBtb25pdG9yZWQgcmVzb3VyY2VzIGFyZSBhZGRlZCBhbmQgcmVtb3Zl
ZAogZnJvbSB0aGUgaW5mcmFzdHJ1Y3R1cmUuCgoKCgMGAAESAy8IFAoKCgMGAAMSAzACQQoM
CgUGAAOZCBIDMAJBCgsKAwYAAxIEMQI0OAoNCgUGAAOaCBIEMQI0OAoqCgQGAAIAEgQ3AjwD
GhwgTGlzdHMgdGhlIGV4aXN0aW5nIGdyb3Vwcy4KCgwKBQYAAgABEgM3BhAKDAoFBgACAAIS
AzcRIgoMCgUGAAIAAxIDNy0/Cg0KBQYAAgAEEgQ4BDoGChEKCQYAAgAEsMq8IhIEOAQ6BgoM
CgUGAAIABBIDOwQyCg8KCAYAAgAEmwgAEgM7BDIKJAoEBgACARIEPwJEAxoWIEdldHMgYSBz
aW5nbGUgZ3JvdXAuCgoMCgUGAAIBARIDPwYOCgwKBQYAAgECEgM/Dx4KDAoFBgACAQMSAz8p
LgoNCgUGAAIBBBIEQARCBgoRCgkGAAIBBLDKvCISBEAEQgYKDAoFBgACAQQSA0MEMgoPCggG
AAIBBJsIABIDQwQyCiQKBAYAAgISBEcCTQMaFiBDcmVhdGVzIGEgbmV3IGdyb3VwLgoKDAoF
BgACAgESA0cGEQoMCgUGAAICAhIDRxIkCgwKBQYAAgIDEgNHLzQKDQoFBgACAgQSBEgESwYK
EQoJBgACAgSwyrwiEgRIBEsGCgwKBQYAAgIEEgNMBDgKDwoIBgACAgSbCAASA0wEOApeCgQG
AAIDEgRRAlcDGlAgVXBkYXRlcyBhbiBleGlzdGluZyBncm91cC4KIFlvdSBjYW4gY2hhbmdl
IGFueSBncm91cCBhdHRyaWJ1dGVzIGV4Y2VwdCBgbmFtZWAuCgoMCgUGAAIDARIDUQYRCgwK
BQYAAgMCEgNREiQKDAoFBgACAwMSA1EvNAoNCgUGAAIDBBIEUgRVBgoRCgkGAAIDBLDKvCIS
BFIEVQYKDAoFBgACAwQSA1YEMwoPCggGAAIDBJsIABIDVgQzCioKBAYAAgQSBFoCXwMaHCBE
ZWxldGVzIGFuIGV4aXN0aW5nIGdyb3VwLgoKDAoFBgACBAESA1oGEQoMCgUGAAIEAhIDWhIk
CgwKBQYAAgQDEgNaL0QKDQoFBgACBAQSBFsEXQYKEQoJBgACBASwyrwiEgRbBF0GCgwKBQYA
AgQEEgNeBDIKDwoIBgACBASbCAASA14EMgpKCgQGAAIFEgRiAmgDGjwgTGlzdHMgdGhlIG1v
bml0b3JlZCByZXNvdXJjZXMgdGhhdCBhcmUgbWVtYmVycyBvZiBhIGdyb3VwLgoKDAoFBgAC
BQESA2IGFgoMCgUGAAIFAhIDYhcuCgwKBQYAAgUDEgNjDycKDQoFBgACBQQSBGQEZgYKEQoJ
BgACBQSwyrwiEgRkBGYGCgwKBQYAAgUEEgNnBDIKDwoIBgACBQSbCAASA2cEMgonCgIEABIF
bACmAQEaGiBUaGUgYExpc3RHcm91cGAgcmVxdWVzdC4KCgoKAwQAARIDbAgZCrcBCgQEAAIA
EgRyAncEGqgBIFJlcXVpcmVkLiBUaGUKIFtwcm9qZWN0XShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vbW9uaXRvcmluZy9hcGkvdjMjcHJvamVjdF9uYW1lKSB3aG9zZQogZ3JvdXBzIGFy
ZSB0byBiZSBsaXN0ZWQuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNU
X0lEX09SX05VTUJFUl0KCgwKBQQAAgAFEgNyAggKDAoFBAACAAESA3IJDQoMCgUEAAIAAxID
chARCg0KBQQAAgAIEgRyEncDCg8KCAQAAgAInAgAEgNzBCoKDwoHBAACAAifCBIEdAR2BQrn
AQoEBAAIABIFfAKdAQMa1wEgQW4gb3B0aW9uYWwgZmlsdGVyIGNvbnNpc3Rpbmcgb2YgYSBz
aW5nbGUgZ3JvdXAgbmFtZS4gIFRoZSBmaWx0ZXJzIGxpbWl0CiB0aGUgZ3JvdXBzIHJldHVy
bmVkIGJhc2VkIG9uIHRoZWlyIHBhcmVudC1jaGlsZCByZWxhdGlvbnNoaXAgd2l0aCB0aGUK
IHNwZWNpZmllZCBncm91cC4gSWYgbm8gZmlsdGVyIGlzIHNwZWNpZmllZCwgYWxsIGdyb3Vw
cyBhcmUgcmV0dXJuZWQuCgoMCgUEAAgAARIDfAgOCuMBCgQEAAIBEgaDAQSFAQca0gEgQSBn
cm91cCBuYW1lLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9P
Ul9OVU1CRVJdL2dyb3Vwcy9bR1JPVVBfSURdCgogUmV0dXJucyBncm91cHMgd2hvc2UgYHBh
cmVudF9uYW1lYCBmaWVsZCBjb250YWlucyB0aGUgZ3JvdXAKIG5hbWUuICBJZiBubyBncm91
cHMgaGF2ZSB0aGlzIHBhcmVudCwgdGhlIHJlc3VsdHMgYXJlIGVtcHR5LgoKDQoFBAACAQUS
BIMBBAoKDQoFBAACAQESBIMBCxwKDQoFBAACAQMSBIMBHyAKDwoFBAACAQgSBoMBIYUBBgoR
CgcEAAIBCJ8IEgaDASKFAQUK3gIKBAQAAgISBo8BBJEBBxrNAiBBIGdyb3VwIG5hbWUuIFRo
ZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lEX09SX05VTUJFUl0vZ3Jv
dXBzL1tHUk9VUF9JRF0KCiBSZXR1cm5zIGdyb3VwcyB0aGF0IGFyZSBhbmNlc3RvcnMgb2Yg
dGhlIHNwZWNpZmllZCBncm91cC4KIFRoZSBncm91cHMgYXJlIHJldHVybmVkIGluIG9yZGVy
LCBzdGFydGluZyB3aXRoIHRoZSBpbW1lZGlhdGUgcGFyZW50IGFuZAogZW5kaW5nIHdpdGgg
dGhlIG1vc3QgZGlzdGFudCBhbmNlc3Rvci4gIElmIHRoZSBzcGVjaWZpZWQgZ3JvdXAgaGFz
IG5vCiBpbW1lZGlhdGUgcGFyZW50LCB0aGUgcmVzdWx0cyBhcmUgZW1wdHkuCgoNCgUEAAIC
BRIEjwEECgoNCgUEAAICARIEjwELHQoNCgUEAAICAxIEjwEgIQoPCgUEAAICCBIGjwEikQEG
ChEKBwQAAgIInwgSBo8BI5EBBQqbAgoEBAACAxIGmgEEnAEHGooCIEEgZ3JvdXAgbmFtZS4g
VGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9n
cm91cHMvW0dST1VQX0lEXQoKIFJldHVybnMgdGhlIGRlc2NlbmRhbnRzIG9mIHRoZSBzcGVj
aWZpZWQgZ3JvdXAuICBUaGlzIGlzIGEgc3VwZXJzZXQgb2YKIHRoZSByZXN1bHRzIHJldHVy
bmVkIGJ5IHRoZSBgY2hpbGRyZW5fb2ZfZ3JvdXBgIGZpbHRlciwgYW5kIGluY2x1ZGVzCiBj
aGlsZHJlbi1vZi1jaGlsZHJlbiwgYW5kIHNvIGZvcnRoLgoKDQoFBAACAwUSBJoBBAoKDQoF
BAACAwESBJoBCx8KDQoFBAACAwMSBJoBIiMKDwoFBAACAwgSBpoBJJwBBgoRCgcEAAIDCJ8I
EgaaASWcAQUKUgoEBAACBBIEoAECFhpEIEEgcG9zaXRpdmUgbnVtYmVyIHRoYXQgaXMgdGhl
IG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLgoKDQoFBAACBAUSBKABAgcK
DQoFBAACBAESBKABCBEKDQoFBAACBAMSBKABFBUK6gEKBAQAAgUSBKUBAhga2wEgSWYgdGhp
cyBmaWVsZCBpcyBub3QgZW1wdHkgdGhlbiBpdCBtdXN0IGNvbnRhaW4gdGhlIGBuZXh0X3Bh
Z2VfdG9rZW5gIHZhbHVlCiByZXR1cm5lZCBieSBhIHByZXZpb3VzIGNhbGwgdG8gdGhpcyBt
ZXRob2QuICBVc2luZyB0aGlzIGZpZWxkIGNhdXNlcyB0aGUKIG1ldGhvZCB0byByZXR1cm4g
YWRkaXRpb25hbCByZXN1bHRzIGZyb20gdGhlIHByZXZpb3VzIG1ldGhvZCBjYWxsLgoKDQoF
BAACBQUSBKUBAggKDQoFBAACBQESBKUBCRMKDQoFBAACBQMSBKUBFhcKKgoCBAESBqkBALEB
ARocIFRoZSBgTGlzdEdyb3Vwc2AgcmVzcG9uc2UuCgoLCgMEAQESBKkBCBoKPAoEBAECABIE
qwECGxouIFRoZSBncm91cHMgdGhhdCBtYXRjaCB0aGUgc3BlY2lmaWVkIGZpbHRlcnMuCgoN
CgUEAQIABBIEqwECCgoNCgUEAQIABhIEqwELEAoNCgUEAQIAARIEqwERFgoNCgUEAQIAAxIE
qwEZGgrSAQoEBAECARIEsAECHRrDASBJZiB0aGVyZSBhcmUgbW9yZSByZXN1bHRzIHRoYW4g
aGF2ZSBiZWVuIHJldHVybmVkLCB0aGVuIHRoaXMgZmllbGQgaXMgc2V0CiB0byBhIG5vbi1l
bXB0eSB2YWx1ZS4gIFRvIHNlZSB0aGUgYWRkaXRpb25hbCByZXN1bHRzLAogdXNlIHRoYXQg
dmFsdWUgYXMgYHBhZ2VfdG9rZW5gIGluIHRoZSBuZXh0IGNhbGwgdG8gdGhpcyBtZXRob2Qu
CgoNCgUEAQIBBRIEsAECCAoNCgUEAQIBARIEsAEJGAoNCgUEAQIBAxIEsAEbHAonCgIEAhIG
tAEAvgEBGhkgVGhlIGBHZXRHcm91cGAgcmVxdWVzdC4KCgsKAwQCARIEtAEIFwp5CgQEAgIA
Ega4AQK9AQQaaSBSZXF1aXJlZC4gVGhlIGdyb3VwIHRvIHJldHJpZXZlLiBUaGUgZm9ybWF0
IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL2dyb3Vwcy9bR1JP
VVBfSURdCgoNCgUEAgIABRIEuAECCAoNCgUEAgIAARIEuAEJDQoNCgUEAgIAAxIEuAEQEQoP
CgUEAgIACBIGuAESvQEDChAKCAQCAgAInAgAEgS5AQQqChEKBwQCAgAInwgSBroBBLwBBQoq
CgIEAxIGwQEA1AEBGhwgVGhlIGBDcmVhdGVHcm91cGAgcmVxdWVzdC4KCgsKAwQDARIEwQEI
Ggq4AQoEBAMCABIGxwECzAEEGqcBIFJlcXVpcmVkLiBUaGUKIFtwcm9qZWN0XShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9hcGkvdjMjcHJvamVjdF9uYW1lKSBpbiB3
aGljaAogdG8gY3JlYXRlIHRoZSBncm91cC4gVGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVj
dHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXQoKDQoFBAMCAAUSBMcBAggKDQoFBAMCAAESBMcB
CQ0KDQoFBAMCAAMSBMcBEBEKDwoFBAMCAAgSBscBEswBAwoQCggEAwIACJwIABIEyAEEKgoR
CgcEAwIACJ8IEgbJAQTLAQUKfQoEBAMCARIE0AECOxpvIFJlcXVpcmVkLiBBIGdyb3VwIGRl
ZmluaXRpb24uIEl0IGlzIGFuIGVycm9yIHRvIGRlZmluZSB0aGUgYG5hbWVgIGZpZWxkCiBi
ZWNhdXNlIHRoZSBzeXN0ZW0gYXNzaWducyB0aGUgbmFtZS4KCg0KBQQDAgEGEgTQAQIHCg0K
BQQDAgEBEgTQAQgNCg0KBQQDAgEDEgTQARARCg0KBQQDAgEIEgTQARI6ChAKCAQDAgEInAgA
EgTQARM5CksKBAQDAgISBNMBAhkaPSBJZiB0cnVlLCB2YWxpZGF0ZSB0aGlzIHJlcXVlc3Qg
YnV0IGRvIG5vdCBjcmVhdGUgdGhlIGdyb3VwLgoKDQoFBAMCAgUSBNMBAgYKDQoFBAMCAgES
BNMBBxQKDQoFBAMCAgMSBNMBFxgKKgoCBAQSBtcBAN8BARocIFRoZSBgVXBkYXRlR3JvdXBg
IHJlcXVlc3QuCgoLCgMEBAESBNcBCBoKrAEKBAQEAgASBNsBAjsanQEgUmVxdWlyZWQuIFRo
ZSBuZXcgZGVmaW5pdGlvbiBvZiB0aGUgZ3JvdXAuICBBbGwgZmllbGRzIG9mIHRoZSBleGlz
dGluZwogZ3JvdXAsIGV4Y2VwdGluZyBgbmFtZWAsIGFyZSByZXBsYWNlZCB3aXRoIHRoZSBj
b3JyZXNwb25kaW5nIGZpZWxkcyBvZiB0aGlzCiBncm91cC4KCg0KBQQEAgAGEgTbAQIHCg0K
BQQEAgABEgTbAQgNCg0KBQQEAgADEgTbARARCg0KBQQEAgAIEgTbARI6ChAKCAQEAgAInAgA
EgTbARM5ClQKBAQEAgESBN4BAhkaRiBJZiB0cnVlLCB2YWxpZGF0ZSB0aGlzIHJlcXVlc3Qg
YnV0IGRvIG5vdCB1cGRhdGUgdGhlIGV4aXN0aW5nIGdyb3VwLgoKDQoFBAQCAQUSBN4BAgYK
DQoFBAQCAQESBN4BBxQKDQoFBAQCAQMSBN4BFxgKgAEKAgQFEgbjAQDyAQEaciBUaGUgYERl
bGV0ZUdyb3VwYCByZXF1ZXN0LiBUaGUgZGVmYXVsdCBiZWhhdmlvciBpcyB0byBiZSBhYmxl
IHRvIGRlbGV0ZSBhCiBzaW5nbGUgZ3JvdXAgd2l0aG91dCBhbnkgZGVzY2VuZGFudHMuCgoL
CgMEBQESBOMBCBoKdwoEBAUCABIG5wEC7AEEGmcgUmVxdWlyZWQuIFRoZSBncm91cCB0byBk
ZWxldGUuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lEX09SX05V
TUJFUl0vZ3JvdXBzL1tHUk9VUF9JRF0KCg0KBQQFAgAFEgTnAQIICg0KBQQFAgABEgTnAQkN
Cg0KBQQFAgADEgTnARARCg8KBQQFAgAIEgbnARLsAQMKEAoIBAUCAAicCAASBOgBBCoKEQoH
BAUCAAifCBIG6QEE6wEFCtgBCgQEBQIBEgTxAQIVGskBIElmIHRoaXMgZmllbGQgaXMgdHJ1
ZSwgdGhlbiB0aGUgcmVxdWVzdCBtZWFucyB0byBkZWxldGUgYSBncm91cCB3aXRoIGFsbAog
aXRzIGRlc2NlbmRhbnRzLiBPdGhlcndpc2UsIHRoZSByZXF1ZXN0IG1lYW5zIHRvIGRlbGV0
ZSBhIGdyb3VwIG9ubHkgd2hlbgogaXQgaGFzIG5vIGRlc2NlbmRhbnRzLiBUaGUgZGVmYXVs
dCB2YWx1ZSBpcyBmYWxzZS4KCg0KBQQFAgEFEgTxAQIGCg0KBQQFAgEBEgTxAQcQCg0KBQQF
AgEDEgTxARMUCi8KAgQGEgb1AQCXAgEaISBUaGUgYExpc3RHcm91cE1lbWJlcnNgIHJlcXVl
c3QuCgoLCgMEBgESBPUBCB8KhgEKBAQGAgASBvkBAv4BBBp2IFJlcXVpcmVkLiBUaGUgZ3Jv
dXAgd2hvc2UgbWVtYmVycyBhcmUgbGlzdGVkLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9q
ZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL2dyb3Vwcy9bR1JPVVBfSURdCgoNCgUEBgIA
BRIE+QECCAoNCgUEBgIAARIE+QEJDQoNCgUEBgIAAxIE+QEQEQoPCgUEBgIACBIG+QES/gED
ChAKCAQGAgAInAgAEgT6AQQqChEKBwQGAgAInwgSBvsBBP0BBQpSCgQEBgIBEgSBAgIWGkQg
QSBwb3NpdGl2ZSBudW1iZXIgdGhhdCBpcyB0aGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0
cyB0byByZXR1cm4uCgoNCgUEBgIBBRIEgQICBwoNCgUEBgIBARIEgQIIEQoNCgUEBgIBAxIE
gQIUFQrqAQoEBAYCAhIEhgICGBrbASBJZiB0aGlzIGZpZWxkIGlzIG5vdCBlbXB0eSB0aGVu
IGl0IG11c3QgY29udGFpbiB0aGUgYG5leHRfcGFnZV90b2tlbmAgdmFsdWUKIHJldHVybmVk
IGJ5IGEgcHJldmlvdXMgY2FsbCB0byB0aGlzIG1ldGhvZC4gIFVzaW5nIHRoaXMgZmllbGQg
Y2F1c2VzIHRoZQogbWV0aG9kIHRvIHJldHVybiBhZGRpdGlvbmFsIHJlc3VsdHMgZnJvbSB0
aGUgcHJldmlvdXMgbWV0aG9kIGNhbGwuCgoNCgUEBgICBRIEhgICCAoNCgUEBgICARIEhgIJ
EwoNCgUEBgICAxIEhgIWFwqFAwoEBAYCAxIEkAICFBr2AiBBbiBvcHRpb25hbCBbbGlzdAog
ZmlsdGVyXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9hcGkvbGVhcm5f
bW9yZSNmaWx0ZXJpbmcpCiBkZXNjcmliaW5nIHRoZSBtZW1iZXJzIHRvIGJlIHJldHVybmVk
LiAgVGhlIGZpbHRlciBtYXkgcmVmZXJlbmNlIHRoZSB0eXBlLAogbGFiZWxzLCBhbmQgbWV0
YWRhdGEgb2YgbW9uaXRvcmVkIHJlc291cmNlcyB0aGF0IGNvbXByaXNlIHRoZSBncm91cC4g
Rm9yCiBleGFtcGxlLCB0byByZXR1cm4gb25seSByZXNvdXJjZXMgcmVwcmVzZW50aW5nIENv
bXB1dGUgRW5naW5lIFZNIGluc3RhbmNlcywKIHVzZSB0aGlzIGZpbHRlcjoKCiAgICAgYHJl
c291cmNlLnR5cGUgPSAiZ2NlX2luc3RhbmNlImAKCg0KBQQGAgMFEgSQAgIICg0KBQQGAgMB
EgSQAgkPCg0KBQQGAgMDEgSQAhITCpACCgQEBgIEEgSWAgIcGoECIEFuIG9wdGlvbmFsIHRp
bWUgaW50ZXJ2YWwgZm9yIHdoaWNoIHJlc3VsdHMgc2hvdWxkIGJlIHJldHVybmVkLiBPbmx5
CiBtZW1iZXJzIHRoYXQgd2VyZSBwYXJ0IG9mIHRoZSBncm91cCBkdXJpbmcgdGhlIHNwZWNp
ZmllZCBpbnRlcnZhbCBhcmUKIGluY2x1ZGVkIGluIHRoZSByZXNwb25zZS4gIElmIG5vIGlu
dGVydmFsIGlzIHByb3ZpZGVkIHRoZW4gdGhlIGdyb3VwCiBtZW1iZXJzaGlwIG92ZXIgdGhl
IGxhc3QgbWludXRlIGlzIHJldHVybmVkLgoKDQoFBAYCBAYSBJYCAg4KDQoFBAYCBAESBJYC
DxcKDQoFBAYCBAMSBJYCGhsKMAoCBAcSBpoCAKUCARoiIFRoZSBgTGlzdEdyb3VwTWVtYmVy
c2AgcmVzcG9uc2UuCgoLCgMEBwESBJoCCCAKOgoEBAcCABIEnAICNBosIEEgc2V0IG9mIG1v
bml0b3JlZCByZXNvdXJjZXMgaW4gdGhlIGdyb3VwLgoKDQoFBAcCAAQSBJwCAgoKDQoFBAcC
AAYSBJwCCycKDQoFBAcCAAESBJwCKC8KDQoFBAcCAAMSBJwCMjMK0gEKBAQHAgESBKECAh0a
wwEgSWYgdGhlcmUgYXJlIG1vcmUgcmVzdWx0cyB0aGFuIGhhdmUgYmVlbiByZXR1cm5lZCwg
dGhlbiB0aGlzIGZpZWxkIGlzCiBzZXQgdG8gYSBub24tZW1wdHkgdmFsdWUuICBUbyBzZWUg
dGhlIGFkZGl0aW9uYWwgcmVzdWx0cywgdXNlIHRoYXQgdmFsdWUgYXMKIGBwYWdlX3Rva2Vu
YCBpbiB0aGUgbmV4dCBjYWxsIHRvIHRoaXMgbWV0aG9kLgoKDQoFBAcCAQUSBKECAggKDQoF
BAcCAQESBKECCRgKDQoFBAcCAQMSBKECGxwKQwoEBAcCAhIEpAICFxo1IFRoZSB0b3RhbCBu
dW1iZXIgb2YgZWxlbWVudHMgbWF0Y2hpbmcgdGhpcyByZXF1ZXN0LgoKDQoFBAcCAgUSBKQC
AgcKDQoFBAcCAgESBKQCCBIKDQoFBAcCAgMSBKQCFRZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::GroupService::ListGroupsRequest ===
    # Fields for ListGroupsRequest
    # Field: name Type: 9 ()
    # Field: children_of_group Type: 9 ()
    # Field: ancestors_of_group Type: 9 ()
    # Field: descendants_of_group Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::GroupService::ListGroupsResponse ===
    # Fields for ListGroupsResponse
    # Field: group Type: 11 (.google.monitoring.v3.Group)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::V3::GroupService::GetGroupRequest ===
    # Fields for GetGroupRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::GroupService::CreateGroupRequest ===
    # Fields for CreateGroupRequest
    # Field: name Type: 9 ()
    # Field: group Type: 11 (.google.monitoring.v3.Group)
    # Field: validate_only Type: 8 ()

# === Message: Google::Monitoring::V3::GroupService::UpdateGroupRequest ===
    # Fields for UpdateGroupRequest
    # Field: group Type: 11 (.google.monitoring.v3.Group)
    # Field: validate_only Type: 8 ()

# === Message: Google::Monitoring::V3::GroupService::DeleteGroupRequest ===
    # Fields for DeleteGroupRequest
    # Field: name Type: 9 ()
    # Field: recursive Type: 8 ()

# === Message: Google::Monitoring::V3::GroupService::ListGroupMembersRequest ===
    # Fields for ListGroupMembersRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: interval Type: 11 (.google.monitoring.v3.TimeInterval)

# === Message: Google::Monitoring::V3::GroupService::ListGroupMembersResponse ===
    # Fields for ListGroupMembersResponse
    # Field: members Type: 11 (.google.api.MonitoredResource)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Service Client: Google::Monitoring::V3::GroupService::GroupServiceClient ===
package Google::Monitoring::V3::GroupService::GroupServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::GroupService::GroupServiceClient

Client stub representing the remote C<GroupService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub list_groups {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::ListGroupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'ListGroups',
        request        => $req,
        response_class => 'Google::Monitoring::V3::GroupService::ListGroupsResponse',
    });
}

sub get_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::GetGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'GetGroup',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Group::Group',
    });
}

sub create_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::CreateGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'CreateGroup',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Group::Group',
    });
}

sub update_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::UpdateGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'UpdateGroup',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Group::Group',
    });
}

sub delete_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::DeleteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'DeleteGroup',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_group_members {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::GroupService::ListGroupMembersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'ListGroupMembers',
        request        => $req,
        response_class => 'Google::Monitoring::V3::GroupService::ListGroupMembersResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::GroupService - Compiled Protocol Buffers messages for google/monitoring/v3/group_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::GroupService;

    my $msg = Google::Monitoring::V3::GroupService::ListGroupsRequest->new({
        name => $name,
        children_of_group => $children_of_group,
        ancestors_of_group => $ancestors_of_group,
        descendants_of_group => $descendants_of_group,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::GroupService::ListGroupsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/group_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::GroupService::ListGroupsRequest

The `ListGroup` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) whose
groups are to be listed. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->children_of_group() >> / C<< $msg->children_of_group($value) >>

Type: C<String>

A group name. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

Returns groups whose `parent_name` field contains the group
name.  If no groups have this parent, the results are empty.

=item * C<< $msg->ancestors_of_group() >> / C<< $msg->ancestors_of_group($value) >>

Type: C<String>

A group name. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

Returns groups that are ancestors of the specified group.
The groups are returned in order, starting with the immediate parent and
ending with the most distant ancestor.  If the specified group has no
immediate parent, the results are empty.

=item * C<< $msg->descendants_of_group() >> / C<< $msg->descendants_of_group($value) >>

Type: C<String>

A group name. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

Returns the descendants of the specified group.  This is a superset of
the results returned by the `children_of_group` filter, and includes
children-of-children, and so forth.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A positive number that is the maximum number of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `next_page_token` value
returned by a previous call to this method.  Using this field causes the
method to return additional results from the previous method call.

=back

=head2 Google::Monitoring::V3::GroupService::ListGroupsResponse

The `ListGroups` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->group() >> / C<< $msg->group($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Group::Group>)

The groups that match the specified filters.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than have been returned, then this field is set
to a non-empty value.  To see the additional results,
use that value as `page_token` in the next call to this method.

=back

=head2 Google::Monitoring::V3::GroupService::GetGroupRequest

The `GetGroup` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The group to retrieve. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

=back

=head2 Google::Monitoring::V3::GroupService::CreateGroupRequest

The `CreateGroup` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) in which
to create the group. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->group() >> / C<< $msg->group($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Group::Group>)

Required. A group definition. It is an error to define the `name` field
because the system assigns the name.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If true, validate this request but do not create the group.

=back

=head2 Google::Monitoring::V3::GroupService::UpdateGroupRequest

The `UpdateGroup` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->group() >> / C<< $msg->group($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Group::Group>)

Required. The new definition of the group.  All fields of the existing
group, excepting `name`, are replaced with the corresponding fields of this
group.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If true, validate this request but do not update the existing group.

=back

=head2 Google::Monitoring::V3::GroupService::DeleteGroupRequest

The `DeleteGroup` request. The default behavior is to be able to delete a
single group without any descendants.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The group to delete. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

=item * C<< $msg->recursive() >> / C<< $msg->recursive($value) >>

Type: C<Bool>

If this field is true, then the request means to delete a group with all
its descendants. Otherwise, the request means to delete a group only when
it has no descendants. The default value is false.

=back

=head2 Google::Monitoring::V3::GroupService::ListGroupMembersRequest

The `ListGroupMembers` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The group whose members are listed. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A positive number that is the maximum number of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `next_page_token` value
returned by a previous call to this method.  Using this field causes the
method to return additional results from the previous method call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An optional [list
filter](https://cloud.google.com/monitoring/api/learn_more#filtering)
describing the members to be returned.  The filter may reference the type,
labels, and metadata of monitored resources that comprise the group. For
example, to return only resources representing Compute Engine VM instances,
use this filter:

    `resource.type = "gce_instance"`

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Common::TimeInterval>)

An optional time interval for which results should be returned. Only
members that were part of the group during the specified interval are
included in the response.  If no interval is provided then the group
membership over the last minute is returned.

=back

=head2 Google::Monitoring::V3::GroupService::ListGroupMembersResponse

The `ListGroupMembers` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->members() >> / C<< $msg->members($value) >>

Type: C<Message> (L<Google::Api::MonitoredResource::MonitoredResource>)

A set of monitored resources in the group.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than have been returned, then this field is
set to a non-empty value.  To see the additional results, use that value as
`page_token` in the next call to this method.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of elements matching this request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::GroupService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
