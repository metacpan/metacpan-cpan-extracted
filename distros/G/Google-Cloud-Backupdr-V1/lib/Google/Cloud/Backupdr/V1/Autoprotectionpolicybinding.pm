package Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYXV0b3Byb3RlY3Rpb25wb2xpY3liaW5kaW5n
LnByb3RvEhhnb29nbGUuY2xvdWQuYmFja3VwZHIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKgBgobQXV0
b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nEhoKBG5hbWUYASABKAlCBuBBA+BBCFIEbmFtZRIl
CgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJWCgVzdGF0ZRgDIAEoDjI7
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcu
U3RhdGVCA+BBA1IFc3RhdGUSIgoFc2NvcGUYBCABKAlCDOBBAuBBBfpBAwoBKlIFc2NvcGUS
dQoaYmluZGluZ19ldmFsdWF0aW9uX3N1bW1hcnkYBSABKAsyMi5nb29nbGUuY2xvdWQuYmFj
a3VwZHIudjEuQmluZGluZ0V2YWx1YXRpb25TdW1tYXJ5QgPgQQNSGGJpbmRpbmdFdmFsdWF0
aW9uU3VtbWFyeRJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRISCgRldGFnGAggASgJUgRldGFn
IlAKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJ
VkUQAhIWChJERUxFVElPTl9JTklUSUFURUQQAzrgAepB3AEKM2JhY2t1cGRyLmdvb2dsZWFw
aXMuY29tL0F1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZxJqcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1dG9fcHJv
dGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfSocYXV0b1Byb3RlY3Rpb25Qb2xp
Y3lCaW5kaW5nczIbYXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nIs8BChhCaW5kaW5nRXZh
bHVhdGlvblN1bW1hcnkSOwoXbWF0Y2hpbmdfcmVzb3VyY2VfY291bnQYASABKANCA+BBA1IV
bWF0Y2hpbmdSZXNvdXJjZUNvdW50Ej0KGHByb3RlY3RlZF9yZXNvdXJjZV9jb3VudBgCIAEo
A0ID4EEDUhZwcm90ZWN0ZWRSZXNvdXJjZUNvdW50EjcKFWZhaWxlZF9yZXNvdXJjZV9jb3Vu
dBgDIAEoA0ID4EEDUhNmYWlsZWRSZXNvdXJjZUNvdW50IvQCCihDcmVhdGVBdXRvUHJvdGVj
dGlvblBvbGljeUJpbmRpbmdSZXF1ZXN0EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuCixiYWNr
dXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeVIGcGFyZW50Ek0KIWF1
dG9fcHJvdGVjdGlvbl9wb2xpY3lfYmluZGluZ19pZBgCIAEoCUID4EECUh1hdXRvUHJvdGVj
dGlvblBvbGljeUJpbmRpbmdJZBJ/Ch5hdXRvX3Byb3RlY3Rpb25fcG9saWN5X2JpbmRpbmcY
AyABKAsyNS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuQXV0b1Byb3RlY3Rpb25Qb2xpY3lC
aW5kaW5nQgPgQQJSG2F1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZxIqCgpyZXF1ZXN0X2lk
GAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIngKJUdldEF1dG9Qcm90ZWN0aW9uUG9s
aWN5QmluZGluZ1JlcXVlc3QSTwoEbmFtZRgBIAEoCUI74EEC+kE1CjNiYWNrdXBkci5nb29n
bGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdSBG5hbWUi+gEKJ0xpc3RB
dXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdzUmVxdWVzdBJMCgZwYXJlbnQYASABKAlCNOBB
AvpBLgosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0b1Byb3RlY3Rpb25Qb2xpY3lSBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghv
cmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IvcBCihMaXN0QXV0b1Byb3RlY3Rpb25Qb2xp
Y3lCaW5kaW5nc1Jlc3BvbnNlEnwKH2F1dG9fcHJvdGVjdGlvbl9wb2xpY3lfYmluZGluZ3MY
ASADKAsyNS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuQXV0b1Byb3RlY3Rpb25Qb2xpY3lC
aW5kaW5nUhxhdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIlCgt1bnJlYWNoYWJsZRgDIAMoCUID4EEGUgt1bnJl
YWNoYWJsZSLIAQowSW5pdGlhdGVEZWxldGVBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdS
ZXF1ZXN0Ek8KBG5hbWUYASABKAlCO+BBAvpBNQozYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20v
QXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nUgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIE
ZXRhZxIqCgpyZXF1ZXN0X2lkGAMgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkQtABChxj
b20uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxQiBBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRp
bmdQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxL2JhY2t1cGRy
cGI7YmFja3VwZHJwYqoCGEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMcoCGEdvb2dsZVxDbG91
ZFxCYWNrdXBEUlxWMeoCG0dvb2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMUr0QQoHEgUOAOwB
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
EgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQApCggKAQgSAxcANQoJCgIIJRID
FwA1CggKAQgSAxgATwoJCgIICxIDGABPCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoA
QQoJCgIICBIDGgBBCggKAQgSAxsANQoJCgIIARIDGwA1CggKAQgSAxwANQoJCgIIKRIDHAA1
CggKAQgSAx0ANAoJCgIILRIDHQA0CqUBCgIEABIEIgBgARqYASBBbiBBdXRvUHJvdGVjdGlv
blBvbGljeUJpbmRpbmcgKEFQUEEpIGFjdHMgYXMgdGhlIGJyaWRnZSBiZXR3ZWVuIGFuCiBB
dXRvUHJvdGVjdGlvblBvbGljeSBhbmQgdGhlIHNjb3BlIChQcm9qZWN0KSB3aGVyZQogdGhl
IHBvbGljeSBzaG91bGQgYmUgYXBwbGllZC4KCgoKAwQAARIDIggjCgsKAwQABxIEIwIoBAoN
CgUEAAedCBIEIwIoBAo8CgQEAAQAEgQrAjcDGi4gVGhlIHN0YXRlIG9mIGFuIEF1dG9Qcm90
ZWN0aW9uUG9saWN5QmluZGluZy4KCgwKBQQABAABEgMrBwwKOQoGBAAEAAIAEgMtBBoaKiBU
aGUgc3RhdGUgb2YgdGhlIGJpbmRpbmcgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMt
BBUKDgoHBAAEAAIAAhIDLRgZCi4KBgQABAACARIDMAQRGh8gVGhlIGJpbmRpbmcgaXMgYmVp
bmcgY3JlYXRlZC4KCg4KBwQABAACAQESAzAEDAoOCgcEAAQAAgECEgMwDxAKJwoGBAAEAAIC
EgMzBA8aGCBUaGUgYmluZGluZyBpcyBhY3RpdmUuCgoOCgcEAAQAAgIBEgMzBAoKDgoHBAAE
AAICAhIDMw0OCjMKBgQABAACAxIDNgQbGiQgVGhlIGJpbmRpbmcgZGVsZXRpb24gaXMgaW5p
dGlhdGVkLgoKDgoHBAAEAAIDARIDNgQWCg4KBwQABAACAwISAzYZGgrWAQoEBAACABIEPAI/
BBrHASBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
CiBBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97YXV0
b19wcm90ZWN0aW9uX3BvbGljeX0vYmluZGluZ3Mve2JpbmRpbmd9YAoKDAoFBAACAAUSAzwC
CAoMCgUEAAIAARIDPAkNCgwKBQQAAgADEgM8EBEKDQoFBAACAAgSBDwSPwMKDwoIBAACAAic
CAASAz0ELQoPCggEAAIACJwIARIDPgQsCmgKBAQAAgESA0MCQhpbIE9wdGlvbmFsLiBBIGRl
c2NyaXB0aW9uIG9mIHRoZSBiaW5kaW5nLiBUaGUgZGVzY3JpcHRpb24gbXVzdCBiZSBhdCBt
b3N0CiAyMDQ4IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDQwIICgwKBQQAAgEBEgNDCRQKDAoF
BAACAQMSA0MXGAoMCgUEAAIBCBIDQxlBCg8KCAQAAgEInAgAEgNDGkAKUQoEBAACAhIDRgI+
GkQgT3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBBdXRvUHJvdGVjdGlv
blBvbGljeUJpbmRpbmcuCgoMCgUEAAICBhIDRgIHCgwKBQQAAgIBEgNGCA0KDAoFBAACAgMS
A0YQEQoMCgUEAAICCBIDRhI9Cg8KCAQAAgIInAgAEgNGEzwKhAEKBAQAAgMSBEoCTgQadiBS
ZXF1aXJlZC4gSW1tdXRhYmxlLiBSZXNvdXJjZSBJZCBvZiB0YXJnZXQgY29udGFpbmVyIG9u
IHdoaWNoIHBvbGljeSB3aWxsCiBiZSBhcHBsaWVkLiBGb3JtYXQ6IHByb2plY3RzL3twcm9q
ZWN0X2lkfQoKDAoFBAACAwUSA0oCCAoMCgUEAAIDARIDSgkOCgwKBQQAAgMDEgNKERIKDQoF
BAACAwgSBEoTTgMKDwoIBAACAwicCAASA0sEKgoPCggEAAIDCJwIARIDTAQrCg4KBwQAAgMI
nwgSA00EMwqlAQoEBAACBBIEUgJTMhqWASBPdXRwdXQgb25seS4gU3VtbWFyaWVzIG9mIHRo
ZSBsYXN0IHBvbGljeSBhcHBsaWNhdGlvbiB3aGVuIHRoZSBqb2IgaGFzIHJ1biwKIHdpdGgg
b25lIGVudHJ5IHBlciByZXNvdXJjZSB0eXBlIHNwZWNpZmllZCBpbiB0aGUgQXV0b1Byb3Rl
Y3Rpb25Qb2xpY3kuCgoMCgUEAAIEBhIDUgIaCgwKBQQAAgQBEgNSGzUKDAoFBAACBAMSA1I4
OQoMCgUEAAIECBIDUwYxCg8KCAQAAgQInAgAEgNTBzAKSAoEBAACBRIEVgJXMho6IE91dHB1
dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIGJpbmRpbmcgd2FzIGNyZWF0ZWQuCgoM
CgUEAAIFBhIDVgIbCgwKBQQAAgUBEgNWHCcKDAoFBAACBQMSA1YqKwoMCgUEAAIFCBIDVwYx
Cg8KCAQAAgUInAgAEgNXBzAKTQoEBAACBhIEWgJbMho/IE91dHB1dCBvbmx5LiBUaGUgdGlt
ZXN0YW1wIHdoZW4gdGhlIGJpbmRpbmcgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgYGEgNa
AhsKDAoFBAACBgESA1ocJwoMCgUEAAIGAxIDWiorCgwKBQQAAgYIEgNbBjEKDwoIBAACBgic
CAASA1sHMAp2CgQEAAIHEgNfAhIaaSBPdXRwdXQgb25seS4gVGhlIGV0YWcgZm9yIHRoZSBi
aW5kaW5nLgogSWYgdGhpcyBpcyBwcm92aWRlZCBvbiB1cGRhdGUsIGl0IG11c3QgbWF0Y2gg
dGhlIHNlcnZlcidzIGV0YWcuCgoMCgUEAAIHBRIDXwIICgwKBQQAAgcBEgNfCQ0KDAoFBAAC
BwMSA18QEQqTAQoCBAESBGQAcQEahgEgQmluZGluZ0V2YWx1YXRpb25TdW1tYXJ5IGNvbnRh
aW5zIHRoZSBzdW1tYXJ5IG9mIHRoZSBsYXN0IHJ1biBvZiBqb2IKIHRoYXQgYXBwbGllcyBw
b2xpY3kgdG8gbWF0Y2hpbmcgcmVzb3VyY2VzIGZvciBhIGdpdmVuIGJpbmRpbmcuCgoKCgME
AQESA2QIIApgCgQEAQIAEgNnAlAaUyBPdXRwdXQgb25seS4gVGhlIG51bWJlciBvZiByZXNv
dXJjZXMgdGhhdCBjdXJyZW50bHkgbWF0Y2ggdGhlIHBvbGljeSdzCiBjcml0ZXJpYS4KCgwK
BQQBAgAFEgNnAgcKDAoFBAECAAESA2cIHwoMCgUEAQIAAxIDZyIjCgwKBQQBAgAIEgNnJE8K
DwoIBAECAAicCAASA2clTgpfCgQEAQIBEgRrAmwyGlEgT3V0cHV0IG9ubHkuIFRoZSBudW1i
ZXIgb2YgbWF0Y2hpbmcgcmVzb3VyY2VzIHRoYXQgYXJlIHN1Y2Nlc3NmdWxseQogcHJvdGVj
dGVkLgoKDAoFBAECAQUSA2sCBwoMCgUEAQIBARIDawggCgwKBQQBAgEDEgNrIyQKDAoFBAEC
AQgSA2wGMQoPCggEAQIBCJwIABIDbAcwCmUKBAQBAgISA3ACThpYIE91dHB1dCBvbmx5LiBU
aGUgbnVtYmVyIG9mIG1hdGNoaW5nIHJlc291cmNlcyB3aG9zZSBwcm90ZWN0aW9uIGZhaWxl
ZAogZHVyaW5nIGpvYiBydW4uCgoMCgUEAQICBRIDcAIHCgwKBQQBAgIBEgNwCB0KDAoFBAEC
AgMSA3AgIQoMCgUEAQICCBIDcCJNCg8KCAQBAgIInAgAEgNwI0wKSwoCBAISBXQAlgEBGj4g
UmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGluZyBhbiBBdXRvUHJvdGVjdGlvblBvbGljeUJp
bmRpbmcuCgoKCgMEAgESA3QIMAq0AQoEBAICABIEeAJ9BBqlASBSZXF1aXJlZC4gVGhlIHBh
cmVudCByZXNvdXJjZSB3aGVyZSB0aGlzIGJpbmRpbmcgd2lsbCBiZSBjcmVhdGVkLgogRm9y
bWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90
ZWN0aW9uUG9saWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9CgoMCgUEAgIABRIDeAII
CgwKBQQCAgABEgN4CQ8KDAoFBAICAAMSA3gSEwoNCgUEAgIACBIEeBR9AwoPCggEAgIACJwI
ABIDeQQqCg8KBwQCAgAInwgSBHoEfAUKjQIKBAQCAgESBoQBAoUBLxr8ASBSZXF1aXJlZC4g
VGhlIElEIHRvIHVzZSBmb3IgdGhlIGJpbmRpbmcuCiBUaGlzIHdpbGwgYmVjb21lIHRoZSBm
aW5hbCBjb21wb25lbnQgb2YgdGhlIGJpbmRpbmcncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMg
dmFsdWUgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBmb2xsb3dlZCBieSB1
cCB0byA2MgogbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMsIG9yIGh5cGhlbnMsIGFuZCBj
YW5ub3QgZW5kIHdpdGggYSBoeXBoZW4uCgoNCgUEAgIBBRIEhAECCAoNCgUEAgIBARIEhAEJ
KgoNCgUEAgIBAxIEhAEtLgoNCgUEAgIBCBIEhQEGLgoQCggEAgIBCJwIABIEhQEHLQpPCgQE
AgICEgaIAQKJAS8aPyBSZXF1aXJlZC4gVGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGlu
ZyByZXNvdXJjZSB0byBjcmVhdGUuCgoNCgUEAgICBhIEiAECHQoNCgUEAgICARIEiAEePAoN
CgUEAgICAxIEiAE/QAoNCgUEAgICCBIEiQEGLgoQCggEAgICCJwIABIEiQEHLQqvAwoEBAIC
AxIGkgEClQEEGp4DIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYg
eW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwog
aWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBU
aGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVz
IHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2
YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1
cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQC
AgMFEgSSAQIICg0KBQQCAgMBEgSSAQkTCg0KBQQCAgMDEgSSARYXCg8KBQQCAgMIEgaSARiV
AQMKEwoLBAICAwjM8fmKAQESBJMBBCoKEAoIBAICAwicCAASBJQBBCoKSwoCBAMSBpkBAKMB
ARo9IFJlcXVlc3QgbWVzc2FnZSBmb3IgZ2V0dGluZyBhbiBBdXRvUHJvdGVjdGlvblBvbGlj
eUJpbmRpbmcuCgoLCgMEAwESBJkBCC0KtgEKBAQDAgASBp0BAqIBBBqlASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIGJpbmRpbmcgdG8gcmV0cmlldmUuCiBGb3JtYXQ6CiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2ll
cy97YXV0b19wcm90ZWN0aW9uX3BvbGljeX0vYmluZGluZ3Mve2JpbmRpbmd9CgoNCgUEAwIA
BRIEnQECCAoNCgUEAwIAARIEnQEJDQoNCgUEAwIAAxIEnQEQEQoPCgUEAwIACBIGnQESogED
ChAKCAQDAgAInAgAEgSeAQQqChEKBwQDAgAInwgSBp8BBKEBBQpFCgIEBBIGpgEAwAEBGjcg
UmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0QXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5ncy4K
CgsKAwQEARIEpgEILwqSAQoEBAQCABIGqQECrgEEGoEBIFJlcXVpcmVkLiBUaGUgcHJvamVj
dCBhbmQgbG9jYXRpb24gZm9yIHdoaWNoIHRvIHJldHJpZXZlIHRoZSBsaXN0IG9mCiBwb2xp
Y2llcy4gRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0K
Cg0KBQQEAgAFEgSpAQIICg0KBQQEAgABEgSpAQkPCg0KBQQEAgADEgSpARITCg8KBQQEAgAI
EgapARSuAQMKEAoIBAQCAAicCAASBKoBBCoKEQoHBAQCAAifCBIGqwEErQEFCpIBCgQEBAIB
EgSyAQI/GoMBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcG9saWNpZXMgdG8g
cmV0dXJuIGluIGEgc2luZ2xlIHBhZ2UgaXMgNTAwLgogSWYgdW5zcGVjaWZpZWQsIGEgc2Vy
dmVyLWRlZmF1bHQgdmFsdWUgd2lsbCBiZSB1c2VkLgoKDQoFBAQCAQUSBLIBAgcKDQoFBAQC
AQESBLIBCBEKDQoFBAQCAQMSBLIBFBUKDQoFBAQCAQgSBLIBFj4KEAoIBAQCAQicCAASBLIB
Fz0KlAEKBAQEAgISBLcBAkEahQEgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQg
ZnJvbSBhIHByZXZpb3VzCiBgTGlzdEF1dG9Qcm90ZWN0aW9uUG9saWNpZXNgIGNhbGwuIFBy
b3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudAogcGFnZS4KCg0KBQQEAgIF
EgS3AQIICg0KBQQEAgIBEgS3AQkTCg0KBQQEAgIDEgS3ARYXCg0KBQQEAgIIEgS3ARhAChAK
CAQEAgIInAgAEgS3ARk/CoIBCgQEBAIDEgS7AQI9GnQgT3B0aW9uYWwuIEEgZmlsdGVyIGV4
cHJlc3Npb24gdGhhdCBmaWx0ZXJzIHJlc291cmNlcyBsaXN0ZWQgaW4gdGhlCiByZXNwb25z
ZS4gVGhlIGZvbGxvd2luZyBmaWVsZHMgYXJlIGZpbHRlcmFibGU6CgoNCgUEBAIDBRIEuwEC
CAoNCgUEBAIDARIEuwEJDwoNCgUEBAIDAxIEuwESEwoNCgUEBAIDCBIEuwEUPAoQCggEBAID
CJwIABIEuwEVOwpzCgQEBAIEEgS/AQI/GmUgT3B0aW9uYWwuIEFuIGV4cHJlc3Npb24gdGhh
dCBzb3J0cyB0aGUgcmVzdWx0cyBpbiB0aGUgcmVzcG9uc2UuIFRoZQogZm9sbG93aW5nIGZp
ZWxkcyBhcmUgc29ydGFibGU6CgoNCgUEBAIEBRIEvwECCAoNCgUEBAIEARIEvwEJEQoNCgUE
BAIEAxIEvwEUFQoNCgUEBAIECBIEvwEWPgoQCggEBAIECJwIABIEvwEXPQpGCgIEBRIGwwEA
zgEBGjggUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdEF1dG9Qcm90ZWN0aW9uUG9saWN5Qmlu
ZGluZ3MuCgoLCgMEBQESBMMBCDAKSwoEBAUCABIExQECSxo9IEEgbGlzdCBvZiB0aGUgQXV0
b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5ncyByZXNvdXJjZXMgZm91bmQuCgoNCgUEBQIABBIE
xQECCgoNCgUEBQIABhIExQELJgoNCgUEBQIAARIExQEnRgoNCgUEBQIAAxIExQFJSgqNAQoE
BAUCARIEyQECHRp/IEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAg
dG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwg
dGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIEyQECCAoNCgUEBQIB
ARIEyQEJGAoNCgUEBQIBAxIEyQEbHApGCgQEBQICEgbMAQLNATUaNiBVbm9yZGVyZWQgbGlz
dC4gTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBQICBBIEzAEC
CgoNCgUEBQICBRIEzAELEQoNCgUEBQICARIEzAESHQoNCgUEBQICAxIEzAEgIQoNCgUEBQIC
CBIEzQEGNAoQCggEBQICCJwIABIEzQEHMwpYCgIEBhIG0QEA7AEBGkogUmVxdWVzdCBtZXNz
YWdlIGZvciBpbml0aWF0aW5nIGRlbGV0ZSBvZiBhbiBBdXRvUHJvdGVjdGlvblBvbGljeUJp
bmRpbmcuCgoLCgMEBgESBNEBCDgKtAEKBAQGAgASBtUBAtoBBBqjASBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIGJpbmRpbmcgdG8gZGVsZXRlLgogRm9ybWF0OgogcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1
dG9fcHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfQoKDQoFBAYCAAUSBNUB
AggKDQoFBAYCAAESBNUBCQ0KDQoFBAYCAAMSBNUBEBEKDwoFBAYCAAgSBtUBEtoBAwoQCggE
BgIACJwIABIE1gEEKgoRCgcEBgIACJ8IEgbXAQTZAQUK3AEKBAQGAgESBN8BAjsazQEgT3B0
aW9uYWwuIFRoZSBjdXJyZW50IGV0YWcgb2YgdGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5Qmlu
ZGluZy4KIElmIGFuIGV0YWcgaXMgcHJvdmlkZWQgYW5kIGRvZXMgbm90IG1hdGNoIHRoZSBj
dXJyZW50IGV0YWcgb2YgdGhlCiBiaW5kaW5nLCBkZWxldGlvbiB3aWxsIGJlIGJsb2NrZWQg
YW5kIGFuIEFCT1JURUQgZXJyb3Igd2lsbCBiZSByZXR1cm5lZC4KCg0KBQQGAgEFEgTfAQII
Cg0KBQQGAgEBEgTfAQkNCg0KBQQGAgEDEgTfARARCg0KBQQGAgEIEgTfARI6ChAKCAQGAgEI
nAgAEgTfARM5Cq8DCgQEBgICEgboAQLrAQQangMgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJl
cXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVl
c3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2
ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkg
YmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0
IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogVGhlIHJlcXVl
c3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVy
byBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAw
MDAwMDAwMDApLgoKDQoFBAYCAgUSBOgBAggKDQoFBAYCAgESBOgBCRMKDQoFBAYCAgMSBOgB
FhcKDwoFBAYCAggSBugBGOsBAwoTCgsEBgICCMzx+YoBARIE6QEEKgoQCggEBgICCJwIABIE
6gEEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding ===
    # Fields for AutoProtectionPolicyBinding
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.backupdr.v1.AutoProtectionPolicyBinding.State)
    # Field: scope Type: 9 ()
    # Field: binding_evaluation_summary Type: 11 (.google.cloud.backupdr.v1.BindingEvaluationSummary)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# Enum: AutoProtectionPolicyBinding::State
our $AutoProtectionPolicyBinding_STATE_UNSPECIFIED = 0;
our $AutoProtectionPolicyBinding_CREATING = 1;
our $AutoProtectionPolicyBinding_ACTIVE = 2;
our $AutoProtectionPolicyBinding_DELETION_INITIATED = 3;

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::BindingEvaluationSummary ===
    # Fields for BindingEvaluationSummary
    # Field: matching_resource_count Type: 3 ()
    # Field: protected_resource_count Type: 3 ()
    # Field: failed_resource_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest ===
    # Fields for CreateAutoProtectionPolicyBindingRequest
    # Field: parent Type: 9 ()
    # Field: auto_protection_policy_binding_id Type: 9 ()
    # Field: auto_protection_policy_binding Type: 11 (.google.cloud.backupdr.v1.AutoProtectionPolicyBinding)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest ===
    # Fields for GetAutoProtectionPolicyBindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest ===
    # Fields for ListAutoProtectionPolicyBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse ===
    # Fields for ListAutoProtectionPolicyBindingsResponse
    # Field: auto_protection_policy_bindings Type: 11 (.google.cloud.backupdr.v1.AutoProtectionPolicyBinding)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest ===
    # Fields for InitiateDeleteAutoProtectionPolicyBindingRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/autoprotectionpolicybinding.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding;

    my $msg = Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding->new({
        name => $name,
        description => $description,
        state => $state,
        scope => $scope,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/autoprotectionpolicybinding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding

An AutoProtectionPolicyBinding (APPA) acts as the bridge between an
AutoProtectionPolicy and the scope (Project) where
the policy should be applied.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
AutoProtectionPolicyBinding. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A description of the binding. The description must be at most
2048 characters.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::AutoProtectionPolicyBinding::State>)

Output only. The current state of the AutoProtectionPolicyBinding.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Required. Immutable. Resource Id of target container on which policy will
be applied. Format: projects/{project_id}

=item * C<< $msg->binding_evaluation_summary() >> / C<< $msg->binding_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::BindingEvaluationSummary>)

Output only. Summaries of the last policy application when the job has run,
with one entry per resource type specified in the AutoProtectionPolicy.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the binding was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the binding was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. The etag for the binding.
If this is provided on update, it must match the server's etag.

=back

=head3 Enum: AutoProtectionPolicyBinding::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETION_INITIATED> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::BindingEvaluationSummary

BindingEvaluationSummary contains the summary of the last run of job
that applies policy to matching resources for a given binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resource_count() >> / C<< $msg->matching_resource_count($value) >>

Type: C<Int64>

Output only. The number of resources that currently match the policy's
criteria.

=item * C<< $msg->protected_resource_count() >> / C<< $msg->protected_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources that are successfully
protected.

=item * C<< $msg->failed_resource_count() >> / C<< $msg->failed_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources whose protection failed
during job run.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest

Request message for creating an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this binding will be created.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=item * C<< $msg->auto_protection_policy_binding_id() >> / C<< $msg->auto_protection_policy_binding_id($value) >>

Type: C<String>

Required. The ID to use for the binding.
This will become the final component of the binding's resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, or hyphens, and cannot end with a hyphen.

=item * C<< $msg->auto_protection_policy_binding() >> / C<< $msg->auto_protection_policy_binding($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding>)

Required. The AutoProtectionPolicyBinding resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest

Request message for getting an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the binding to retrieve.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest

Request message for ListAutoProtectionPolicyBindings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policies to return in a single page is 500.
If unspecified, a server-default value will be used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAutoProtectionPolicies` call. Provide this to retrieve the subsequent
page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response. The following fields are filterable:

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response. The
following fields are sortable:

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse

Response message for ListAutoProtectionPolicyBindings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policy_bindings() >> / C<< $msg->auto_protection_policy_bindings($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::AutoProtectionPolicyBinding>)

A list of the AutoProtectionPolicyBindings resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest

Request message for initiating delete of an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the binding to delete.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the AutoProtectionPolicyBinding.
If an etag is provided and does not match the current etag of the
binding, deletion will be blocked and an ABORTED error will be returned.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
