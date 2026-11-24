package Google::Cloud::Bigquery::Migration::V2::TranslationConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL3RyYW5zbGF0aW9uX2NvbmZp
Zy5wcm90bxIiZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MhofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90byLUBAoYVHJhbnNsYXRpb25Db25maWdEZXRhaWxzEigK
D2djc19zb3VyY2VfcGF0aBgBIAEoCUgAUg1nY3NTb3VyY2VQYXRoEigKD2djc190YXJnZXRf
cGF0aBgCIAEoCUgBUg1nY3NUYXJnZXRQYXRoEmcKEW5hbWVfbWFwcGluZ19saXN0GAUgASgL
MjkuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5PYmplY3ROYW1lTWFwcGlu
Z0xpc3RIAlIPbmFtZU1hcHBpbmdMaXN0ElIKDnNvdXJjZV9kaWFsZWN0GAMgASgLMisuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5EaWFsZWN0Ug1zb3VyY2VEaWFsZWN0
ElIKDnRhcmdldF9kaWFsZWN0GAQgASgLMisuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3Jh
dGlvbi52Mi5EaWFsZWN0Ug10YXJnZXREaWFsZWN0EkwKCnNvdXJjZV9lbnYYBiABKAsyLS5n
b29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLlNvdXJjZUVudlIJc291cmNlRW52
EiUKDnJlcXVlc3Rfc291cmNlGAggASgJUg1yZXF1ZXN0U291cmNlEiEKDHRhcmdldF90eXBl
cxgJIAMoCVILdGFyZ2V0VHlwZXNCEQoPc291cmNlX2xvY2F0aW9uQhEKD3RhcmdldF9sb2Nh
dGlvbkIVChNvdXRwdXRfbmFtZV9tYXBwaW5nIoMNCgdEaWFsZWN0EmAKEGJpZ3F1ZXJ5X2Rp
YWxlY3QYASABKAsyMy5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLkJpZ1F1
ZXJ5RGlhbGVjdEgAUg9iaWdxdWVyeURpYWxlY3QSWgoOaGl2ZXFsX2RpYWxlY3QYAiABKAsy
MS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLkhpdmVRTERpYWxlY3RIAFIN
aGl2ZXFsRGlhbGVjdBJgChByZWRzaGlmdF9kaWFsZWN0GAMgASgLMjMuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5SZWRzaGlmdERpYWxlY3RIAFIPcmVkc2hpZnREaWFs
ZWN0EmAKEHRlcmFkYXRhX2RpYWxlY3QYBCABKAsyMy5nb29nbGUuY2xvdWQuYmlncXVlcnku
bWlncmF0aW9uLnYyLlRlcmFkYXRhRGlhbGVjdEgAUg90ZXJhZGF0YURpYWxlY3QSWgoOb3Jh
Y2xlX2RpYWxlY3QYBSABKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
Lk9yYWNsZURpYWxlY3RIAFINb3JhY2xlRGlhbGVjdBJgChBzcGFya3NxbF9kaWFsZWN0GAYg
ASgLMjMuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5TcGFya1NRTERpYWxl
Y3RIAFIPc3BhcmtzcWxEaWFsZWN0EmMKEXNub3dmbGFrZV9kaWFsZWN0GAcgASgLMjQuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5Tbm93Zmxha2VEaWFsZWN0SABSEHNu
b3dmbGFrZURpYWxlY3QSXQoPbmV0ZXp6YV9kaWFsZWN0GAggASgLMjIuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5OZXRlenphRGlhbGVjdEgAUg5uZXRlenphRGlhbGVj
dBJtChVhenVyZV9zeW5hcHNlX2RpYWxlY3QYCSABKAsyNy5nb29nbGUuY2xvdWQuYmlncXVl
cnkubWlncmF0aW9uLnYyLkF6dXJlU3luYXBzZURpYWxlY3RIAFITYXp1cmVTeW5hcHNlRGlh
bGVjdBJdCg92ZXJ0aWNhX2RpYWxlY3QYCiABKAsyMi5nb29nbGUuY2xvdWQuYmlncXVlcnku
bWlncmF0aW9uLnYyLlZlcnRpY2FEaWFsZWN0SABSDnZlcnRpY2FEaWFsZWN0EmQKEnNxbF9z
ZXJ2ZXJfZGlhbGVjdBgLIAEoCzI0Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24u
djIuU1FMU2VydmVyRGlhbGVjdEgAUhBzcWxTZXJ2ZXJEaWFsZWN0EmYKEnBvc3RncmVzcWxf
ZGlhbGVjdBgMIAEoCzI1Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuUG9z
dGdyZXNxbERpYWxlY3RIAFIRcG9zdGdyZXNxbERpYWxlY3QSWgoOcHJlc3RvX2RpYWxlY3QY
DSABKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLlByZXN0b0RpYWxl
Y3RIAFINcHJlc3RvRGlhbGVjdBJXCg1teXNxbF9kaWFsZWN0GA4gASgLMjAuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5NeVNRTERpYWxlY3RIAFIMbXlzcWxEaWFsZWN0
ElEKC2RiMl9kaWFsZWN0GA8gASgLMi4uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlv
bi52Mi5EQjJEaWFsZWN0SABSCmRiMkRpYWxlY3QSWgoOc3FsaXRlX2RpYWxlY3QYECABKAsy
MS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLlNRTGl0ZURpYWxlY3RIAFIN
c3FsaXRlRGlhbGVjdBJjChFncmVlbnBsdW1fZGlhbGVjdBgRIAEoCzI0Lmdvb2dsZS5jbG91
ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuR3JlZW5wbHVtRGlhbGVjdEgAUhBncmVlbnBsdW1E
aWFsZWN0Qg8KDWRpYWxlY3RfdmFsdWUiEQoPQmlnUXVlcnlEaWFsZWN0Ig8KDUhpdmVRTERp
YWxlY3QiEQoPUmVkc2hpZnREaWFsZWN0IpABCg9UZXJhZGF0YURpYWxlY3QSTAoEbW9kZRgB
IAEoDjI4Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuVGVyYWRhdGFEaWFs
ZWN0Lk1vZGVSBG1vZGUiLwoETW9kZRIUChBNT0RFX1VOU1BFQ0lGSUVEEAASBwoDU1FMEAES
CAoEQlRFURACIg8KDU9yYWNsZURpYWxlY3QiEQoPU3BhcmtTUUxEaWFsZWN0IhIKEFNub3dm
bGFrZURpYWxlY3QiEAoOTmV0ZXp6YURpYWxlY3QiFQoTQXp1cmVTeW5hcHNlRGlhbGVjdCIQ
Cg5WZXJ0aWNhRGlhbGVjdCISChBTUUxTZXJ2ZXJEaWFsZWN0IhMKEVBvc3RncmVzcWxEaWFs
ZWN0Ig8KDVByZXN0b0RpYWxlY3QiDgoMTXlTUUxEaWFsZWN0IgwKCkRCMkRpYWxlY3QiDwoN
U1FMaXRlRGlhbGVjdCISChBHcmVlbnBsdW1EaWFsZWN0ImkKFU9iamVjdE5hbWVNYXBwaW5n
TGlzdBJQCghuYW1lX21hcBgBIAMoCzI1Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRp
b24udjIuT2JqZWN0TmFtZU1hcHBpbmdSB25hbWVNYXAirQEKEU9iamVjdE5hbWVNYXBwaW5n
EkoKBnNvdXJjZRgBIAEoCzIyLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIu
TmFtZU1hcHBpbmdLZXlSBnNvdXJjZRJMCgZ0YXJnZXQYAiABKAsyNC5nb29nbGUuY2xvdWQu
YmlncXVlcnkubWlncmF0aW9uLnYyLk5hbWVNYXBwaW5nVmFsdWVSBnRhcmdldCLYAgoOTmFt
ZU1hcHBpbmdLZXkSSwoEdHlwZRgBIAEoDjI3Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdy
YXRpb24udjIuTmFtZU1hcHBpbmdLZXkuVHlwZVIEdHlwZRIaCghkYXRhYmFzZRgCIAEoCVII
ZGF0YWJhc2USFgoGc2NoZW1hGAMgASgJUgZzY2hlbWESGgoIcmVsYXRpb24YBCABKAlSCHJl
bGF0aW9uEhwKCWF0dHJpYnV0ZRgFIAEoCVIJYXR0cmlidXRlIooBCgRUeXBlEhQKEFRZUEVf
VU5TUEVDSUZJRUQQABIMCghEQVRBQkFTRRABEgoKBlNDSEVNQRACEgwKCFJFTEFUSU9OEAMS
DQoJQVRUUklCVVRFEAQSEgoOUkVMQVRJT05fQUxJQVMQBRITCg9BVFRSSUJVVEVfQUxJQVMQ
BhIMCghGVU5DVElPThAHIoABChBOYW1lTWFwcGluZ1ZhbHVlEhoKCGRhdGFiYXNlGAEgASgJ
UghkYXRhYmFzZRIWCgZzY2hlbWEYAiABKAlSBnNjaGVtYRIaCghyZWxhdGlvbhgDIAEoCVII
cmVsYXRpb24SHAoJYXR0cmlidXRlGAQgASgJUglhdHRyaWJ1dGUinwEKCVNvdXJjZUVudhIp
ChBkZWZhdWx0X2RhdGFiYXNlGAEgASgJUg9kZWZhdWx0RGF0YWJhc2USLAoSc2NoZW1hX3Nl
YXJjaF9wYXRoGAIgAygJUhBzY2hlbWFTZWFyY2hQYXRoEjkKFm1ldGFkYXRhX3N0b3JlX2Rh
dGFzZXQYAyABKAlCA+BBAVIUbWV0YWRhdGFTdG9yZURhdGFzZXRC0gEKJmNvbS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyQhZUcmFuc2xhdGlvbkNvbmZpZ1Byb3RvUAFa
RGNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0aW9uL2FwaXYyL21pZ3JhdGlv
bnBiO21pZ3JhdGlvbnBiqgIiR29vZ2xlLkNsb3VkLkJpZ1F1ZXJ5Lk1pZ3JhdGlvbi5WMsoC
Ikdvb2dsZVxDbG91ZFxCaWdRdWVyeVxNaWdyYXRpb25cVjJKzEgKBxIFDgClAgEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAKQoICgEI
EgMUAD8KCQoCCCUSAxQAPwoICgEIEgMVAFsKCQoCCAsSAxUAWwoICgEIEgMWACIKCQoCCAoS
AxYAIgoICgEIEgMXADcKCQoCCAgSAxcANwoICgEIEgMYAD8KCQoCCAESAxgAPwoICgEIEgMZ
AEAKCQoCCCkSAxkAQApnCgIEABIEHQBCARpbIFRoZSB0cmFuc2xhdGlvbiBjb25maWcgdG8g
Y2FwdHVyZSBuZWNlc3Nhcnkgc2V0dGluZ3MgZm9yIGEgdHJhbnNsYXRpb24gdGFzawogYW5k
IHN1YnRhc2suCgoKCgMEAAESAx0IIApPCgQEAAgAEgQfAiIDGkEgVGhlIGNob3NlbiBwYXRo
IHdoZXJlIHRoZSBzb3VyY2UgZm9yIGlucHV0IGZpbGVzIHdpbGwgYmUgZm91bmQuCgoMCgUE
AAgAARIDHwgXClYKBAQAAgASAyEEHxpJIFRoZSBDbG91ZCBTdG9yYWdlIHBhdGggZm9yIGEg
ZGlyZWN0b3J5IG9mIGZpbGVzIHRvIHRyYW5zbGF0ZSBpbiBhIHRhc2suCgoMCgUEAAIABRID
IQQKCgwKBQQAAgABEgMhCxoKDAoFBAACAAMSAyEdHgpVCgQEAAgBEgQlAigDGkcgVGhlIGNo
b3NlbiBwYXRoIHdoZXJlIHRoZSBkZXN0aW5hdGlvbiBmb3Igb3V0cHV0IGZpbGVzIHdpbGwg
YmUgZm91bmQuCgoMCgUEAAgBARIDJQgXClUKBAQAAgESAycEHxpIIFRoZSBDbG91ZCBTdG9y
YWdlIHBhdGggdG8gd3JpdGUgYmFjayB0aGUgY29ycmVzcG9uZGluZyBpbnB1dCBmaWxlcyB0
by4KCgwKBQQAAgEFEgMnBAoKDAoFBAACAQESAycLGgoMCgUEAAIBAxIDJx0eCmUKBAQACAIS
BCwCLwMaVyBUaGUgbWFwcGluZyBvZiBmdWxsIFNRTCBvYmplY3QgbmFtZXMgZnJvbSB0aGVp
ciBjdXJyZW50IHN0YXRlIHRvIHRoZQogZGVzaXJlZCBvdXRwdXQuCgoMCgUEAAgCARIDLAgb
ClEKBAQAAgISAy4EMBpEIFRoZSBtYXBwaW5nIG9mIG9iamVjdHMgdG8gdGhlaXIgZGVzaXJl
ZCBvdXRwdXQgbmFtZXMgaW4gbGlzdCBmb3JtLgoKDAoFBAACAgYSAy4EGQoMCgUEAAICARID
LhorCgwKBQQAAgIDEgMuLi8KLgoEBAACAxIDMgIdGiEgVGhlIGRpYWxlY3Qgb2YgdGhlIGlu
cHV0IGZpbGVzLgoKDAoFBAACAwYSAzICCQoMCgUEAAIDARIDMgoYCgwKBQQAAgMDEgMyGxwK
SwoEBAACBBIDNQIdGj4gVGhlIHRhcmdldCBkaWFsZWN0IGZvciB0aGUgZW5naW5lIHRvIHRy
YW5zbGF0ZSB0aGUgaW5wdXQgdG8uCgoMCgUEAAIEBhIDNQIJCgwKBQQAAgQBEgM1ChgKDAoF
BAACBAMSAzUbHApJCgQEAAIFEgM4AhsaPCBUaGUgZGVmYXVsdCBzb3VyY2UgZW52aXJvbm1l
bnQgdmFsdWVzIGZvciB0aGUgdHJhbnNsYXRpb24uCgoMCgUEAAIFBhIDOAILCgwKBQQAAgUB
EgM4DBYKDAoFBAACBQMSAzgZGgpDCgQEAAIGEgM7AhwaNiBUaGUgaW5kaWNhdG9yIHRvIHNo
b3cgdHJhbnNsYXRpb24gcmVxdWVzdCBpbml0aWF0b3IuCgoMCgUEAAIGBRIDOwIICgwKBQQA
AgYBEgM7CRcKDAoFBAACBgMSAzsaGwr+AQoEBAACBxIDQQIjGvABIFRoZSB0eXBlcyBvZiBv
dXRwdXQgdG8gZ2VuZXJhdGUsIGUuZy4gc3FsLCBtZXRhZGF0YSBldGMuIElmIG5vdCBzcGVj
aWZpZWQsCiBhIGRlZmF1bHQgc2V0IG9mIHRhcmdldHMgd2lsbCBiZSBnZW5lcmF0ZWQuIFNv
bWUgYWRkaXRpb25hbCB0YXJnZXQgdHlwZXMKIG1heSBiZSBzbG93ZXIgdG8gZ2VuZXJhdGUu
IFNlZSB0aGUgZG9jdW1lbnRhdGlvbiBmb3IgdGhlIHNldCBvZiBhdmFpbGFibGUKIHRhcmdl
dCB0eXBlcy4KCgwKBQQAAgcEEgNBAgoKDAoFBAACBwUSA0ELEQoMCgUEAAIHARIDQRIeCgwK
BQQAAgcDEgNBISIKOwoCBAESBEUAewEaLyBUaGUgcG9zc2libGUgZGlhbGVjdCBvcHRpb25z
IGZvciB0cmFuc2xhdGlvbi4KCgoKAwQBARIDRQgPCkoKBAQBCAASBEcCegMaPCBUaGUgcG9z
c2libGUgZGlhbGVjdCBvcHRpb25zIHRoYXQgdGhpcyBtZXNzYWdlIHJlcHJlc2VudHMuCgoM
CgUEAQgAARIDRwgVCiMKBAQBAgASA0kEKRoWIFRoZSBCaWdRdWVyeSBkaWFsZWN0CgoMCgUE
AQIABhIDSQQTCgwKBQQBAgABEgNJFCQKDAoFBAECAAMSA0knKAohCgQEAQIBEgNMBCUaFCBU
aGUgSGl2ZVFMIGRpYWxlY3QKCgwKBQQBAgEGEgNMBBEKDAoFBAECAQESA0wSIAoMCgUEAQIB
AxIDTCMkCiMKBAQBAgISA08EKRoWIFRoZSBSZWRzaGlmdCBkaWFsZWN0CgoMCgUEAQICBhID
TwQTCgwKBQQBAgIBEgNPFCQKDAoFBAECAgMSA08nKAojCgQEAQIDEgNSBCkaFiBUaGUgVGVy
YWRhdGEgZGlhbGVjdAoKDAoFBAECAwYSA1IEEwoMCgUEAQIDARIDUhQkCgwKBQQBAgMDEgNS
JygKIQoEBAECBBIDVQQlGhQgVGhlIE9yYWNsZSBkaWFsZWN0CgoMCgUEAQIEBhIDVQQRCgwK
BQQBAgQBEgNVEiAKDAoFBAECBAMSA1UjJAojCgQEAQIFEgNYBCkaFiBUaGUgU3BhcmtTUUwg
ZGlhbGVjdAoKDAoFBAECBQYSA1gEEwoMCgUEAQIFARIDWBQkCgwKBQQBAgUDEgNYJygKJAoE
BAECBhIDWwQrGhcgVGhlIFNub3dmbGFrZSBkaWFsZWN0CgoMCgUEAQIGBhIDWwQUCgwKBQQB
AgYBEgNbFSYKDAoFBAECBgMSA1spKgoiCgQEAQIHEgNeBCcaFSBUaGUgTmV0ZXp6YSBkaWFs
ZWN0CgoMCgUEAQIHBhIDXgQSCgwKBQQBAgcBEgNeEyIKDAoFBAECBwMSA14lJgooCgQEAQII
EgNhBDIaGyBUaGUgQXp1cmUgU3luYXBzZSBkaWFsZWN0CgoMCgUEAQIIBhIDYQQXCgwKBQQB
AggBEgNhGC0KDAoFBAECCAMSA2EwMQoiCgQEAQIJEgNkBCgaFSBUaGUgVmVydGljYSBkaWFs
ZWN0CgoMCgUEAQIJBhIDZAQSCgwKBQQBAgkBEgNkEyIKDAoFBAECCQMSA2QlJwolCgQEAQIK
EgNnBC0aGCBUaGUgU1FMIFNlcnZlciBkaWFsZWN0CgoMCgUEAQIKBhIDZwQUCgwKBQQBAgoB
EgNnFScKDAoFBAECCgMSA2cqLAolCgQEAQILEgNqBC4aGCBUaGUgUG9zdGdyZXNxbCBkaWFs
ZWN0CgoMCgUEAQILBhIDagQVCgwKBQQBAgsBEgNqFigKDAoFBAECCwMSA2orLQohCgQEAQIM
EgNtBCYaFCBUaGUgUHJlc3RvIGRpYWxlY3QKCgwKBQQBAgwGEgNtBBEKDAoFBAECDAESA20S
IAoMCgUEAQIMAxIDbSMlCiAKBAQBAg0SA3AEJBoTIFRoZSBNeVNRTCBkaWFsZWN0CgoMCgUE
AQINBhIDcAQQCgwKBQQBAg0BEgNwER4KDAoFBAECDQMSA3AhIwoaCgQEAQIOEgNzBCAaDSBE
QjIgZGlhbGVjdAoKDAoFBAECDgYSA3MEDgoMCgUEAQIOARIDcw8aCgwKBQQBAg4DEgNzHR8K
HQoEBAECDxIDdgQmGhAgU1FMaXRlIGRpYWxlY3QKCgwKBQQBAg8GEgN2BBEKDAoFBAECDwES
A3YSIAoMCgUEAQIPAxIDdiMlCiAKBAQBAhASA3kELBoTIEdyZWVucGx1bSBkaWFsZWN0CgoM
CgUEAQIQBhIDeQQUCgwKBQQBAhABEgN5FSYKDAoFBAECEAMSA3kpKwoxCgIEAhIDfgAaGiYg
VGhlIGRpYWxlY3QgZGVmaW5pdGlvbiBmb3IgQmlnUXVlcnkuCgoKCgMEAgESA34IFwowCgIE
AxIEgQEAGBokIFRoZSBkaWFsZWN0IGRlZmluaXRpb24gZm9yIEhpdmVRTC4KCgsKAwQDARIE
gQEIFQoyCgIEBBIEhAEAGhomIFRoZSBkaWFsZWN0IGRlZmluaXRpb24gZm9yIFJlZHNoaWZ0
LgoKCwoDBAQBEgSEAQgXCjQKAgQFEgaHAQCWAQEaJiBUaGUgZGlhbGVjdCBkZWZpbml0aW9u
IGZvciBUZXJhZGF0YS4KCgsKAwQFARIEhwEIFwo3CgQEBQQAEgaJAQKSAQMaJyBUaGUgc3Vi
LWRpYWxlY3Qgb3B0aW9ucyBmb3IgVGVyYWRhdGEuCgoNCgUEBQQAARIEiQEHCwojCgYEBQQA
AgASBIsBBBkaEyBVbnNwZWNpZmllZCBtb2RlLgoKDwoHBAUEAAIAARIEiwEEFAoPCgcEBQQA
AgACEgSLARcYCiQKBgQFBAACARIEjgEEDBoUIFRlcmFkYXRhIFNRTCBtb2RlLgoKDwoHBAUE
AAIBARIEjgEEBwoPCgcEBQQAAgECEgSOAQoLCjEKBgQFBAACAhIEkQEEDRohIEJURVEgbW9k
ZSAod2hpY2ggaW5jbHVkZXMgU1FMKS4KCg8KBwQFBAACAgESBJEBBAgKDwoHBAUEAAICAhIE
kQELDApDCgQEBQIAEgSVAQIQGjUgV2hpY2ggVGVyYWRhdGEgc3ViLWRpYWxlY3QgbW9kZSB0
aGUgdXNlciBzcGVjaWZpZXMuCgoNCgUEBQIABhIElQECBgoNCgUEBQIAARIElQEHCwoNCgUE
BQIAAxIElQEODwowCgIEBhIEmQEAGBokIFRoZSBkaWFsZWN0IGRlZmluaXRpb24gZm9yIE9y
YWNsZS4KCgsKAwQGARIEmQEIFQoyCgIEBxIEnAEAGhomIFRoZSBkaWFsZWN0IGRlZmluaXRp
b24gZm9yIFNwYXJrU1FMLgoKCwoDBAcBEgScAQgXCjMKAgQIEgSfAQAbGicgVGhlIGRpYWxl
Y3QgZGVmaW5pdGlvbiBmb3IgU25vd2ZsYWtlLgoKCwoDBAgBEgSfAQgYCjEKAgQJEgSiAQAZ
GiUgVGhlIGRpYWxlY3QgZGVmaW5pdGlvbiBmb3IgTmV0ZXp6YS4KCgsKAwQJARIEogEIFgo3
CgIEChIEpQEAHhorIFRoZSBkaWFsZWN0IGRlZmluaXRpb24gZm9yIEF6dXJlIFN5bmFwc2Uu
CgoLCgMECgESBKUBCBsKMQoCBAsSBKgBABkaJSBUaGUgZGlhbGVjdCBkZWZpbml0aW9uIGZv
ciBWZXJ0aWNhLgoKCwoDBAsBEgSoAQgWCjQKAgQMEgSrAQAbGiggVGhlIGRpYWxlY3QgZGVm
aW5pdGlvbiBmb3IgU1FMIFNlcnZlci4KCgsKAwQMARIEqwEIGAo0CgIEDRIErgEAHBooIFRo
ZSBkaWFsZWN0IGRlZmluaXRpb24gZm9yIFBvc3RncmVzcWwuCgoLCgMEDQESBK4BCBkKMAoC
BA4SBLEBABgaJCBUaGUgZGlhbGVjdCBkZWZpbml0aW9uIGZvciBQcmVzdG8uCgoLCgMEDgES
BLEBCBUKLwoCBA8SBLQBABcaIyBUaGUgZGlhbGVjdCBkZWZpbml0aW9uIGZvciBNeVNRTC4K
CgsKAwQPARIEtAEIFAotCgIEEBIEtwEAFRohIFRoZSBkaWFsZWN0IGRlZmluaXRpb24gZm9y
IERCMi4KCgsKAwQQARIEtwEIEgowCgIEERIEugEAGBokIFRoZSBkaWFsZWN0IGRlZmluaXRp
b24gZm9yIFNRTGl0ZS4KCgsKAwQRARIEugEIFQozCgIEEhIEvQEAGxonIFRoZSBkaWFsZWN0
IGRlZmluaXRpb24gZm9yIEdyZWVucGx1bS4KCgsKAwQSARIEvQEIGAqEAQoCBBMSBsEBAMQB
ARp2IFJlcHJlc2VudHMgYSBtYXAgb2YgbmFtZSBtYXBwaW5ncyB1c2luZyBhIGxpc3Qgb2Yg
a2V5OnZhbHVlIHByb3RvIG1lc3NhZ2VzIG9mCiBleGlzdGluZyBuYW1lIHRvIGRlc2lyZWQg
b3V0cHV0IG5hbWUuCgoLCgMEEwESBMEBCB0KNAoEBBMCABIEwwECKhomIFRoZSBlbGVtZW50
cyBvZiB0aGUgb2JqZWN0IG5hbWUgbWFwLgoKDQoFBBMCAAQSBMMBAgoKDQoFBBMCAAYSBMMB
CxwKDQoFBBMCAAESBMMBHSUKDQoFBBMCAAMSBMMBKCkKoQEKAgQUEgbIAQDOAQEakgEgUmVw
cmVzZW50cyBhIGtleS12YWx1ZSBwYWlyIG9mIE5hbWVNYXBwaW5nS2V5IHRvIE5hbWVNYXBw
aW5nVmFsdWUgdG8KIHJlcHJlc2VudCB0aGUgbWFwcGluZyBvZiBTUUwgbmFtZXMgZnJvbSB0
aGUgaW5wdXQgdmFsdWUgdG8gZGVzaXJlZCBvdXRwdXQuCgoLCgMEFAESBMgBCBkKRgoEBBQC
ABIEygECHBo4IFRoZSBuYW1lIG9mIHRoZSBvYmplY3QgaW4gc291cmNlIHRoYXQgaXMgYmVp
bmcgbWFwcGVkLgoKDQoFBBQCAAYSBMoBAhAKDQoFBBQCAAESBMoBERcKDQoFBBQCAAMSBMoB
GhsKSwoEBBQCARIEzQECHho9IFRoZSBkZXNpcmVkIHRhcmdldCBuYW1lIG9mIHRoZSBvYmpl
Y3QgdGhhdCBpcyBiZWluZyBtYXBwZWQuCgoNCgUEFAIBBhIEzQECEgoNCgUEFAIBARIEzQET
GQoNCgUEFAIBAxIEzQEcHQqFAQoCBBUSBtIBAP8BARp3IFRoZSBwb3RlbnRpYWwgY29tcG9u
ZW50cyBvZiBhIGZ1bGwgbmFtZSBtYXBwaW5nIHRoYXQgd2lsbCBiZSBtYXBwZWQKIGR1cmlu
ZyB0cmFuc2xhdGlvbiBpbiB0aGUgc291cmNlIGRhdGEgd2FyZWhvdXNlLgoKCwoDBBUBEgTS
AQgWCj4KBAQVBAASBtQBAuwBAxouIFRoZSB0eXBlIG9mIHRoZSBvYmplY3QgdGhhdCBpcyBi
ZWluZyBtYXBwZWQuCgoNCgUEFQQAARIE1AEHCwowCgYEFQQAAgASBNYBBBkaICBVbnNwZWNp
ZmllZCBuYW1lIG1hcHBpbmcgdHlwZS4KCg8KBwQVBAACAAESBNYBBBQKDwoHBBUEAAIAAhIE
1gEXGAo4CgYEFQQAAgESBNkBBBEaKCBUaGUgb2JqZWN0IGJlaW5nIG1hcHBlZCBpcyBhIGRh
dGFiYXNlLgoKDwoHBBUEAAIBARIE2QEEDAoPCgcEFQQAAgECEgTZAQ8QCjYKBgQVBAACAhIE
3AEEDxomIFRoZSBvYmplY3QgYmVpbmcgbWFwcGVkIGlzIGEgc2NoZW1hLgoKDwoHBBUEAAIC
ARIE3AEECgoPCgcEFQQAAgICEgTcAQ0OCjgKBgQVBAACAxIE3wEEERooIFRoZSBvYmplY3Qg
YmVpbmcgbWFwcGVkIGlzIGEgcmVsYXRpb24uCgoPCgcEFQQAAgMBEgTfAQQMCg8KBwQVBAAC
AwISBN8BDxAKOgoGBBUEAAIEEgTiAQQSGiogVGhlIG9iamVjdCBiZWluZyBtYXBwZWQgaXMg
YW4gYXR0cmlidXRlLgoKDwoHBBUEAAIEARIE4gEEDQoPCgcEFQQAAgQCEgTiARARCj4KBgQV
BAACBRIE5QEEFxouIFRoZSBvYmplY3QgYmVpbmcgbWFwcGVkIGlzIGEgcmVsYXRpb24gYWxp
YXMuCgoPCgcEFQQAAgUBEgTlAQQSCg8KBwQVBAACBQISBOUBFRYKQgoGBBUEAAIGEgToAQQY
GjIgVGhlIG9iamVjdCBiZWluZyBtYXBwZWQgaXMgYSBhbiBhdHRyaWJ1dGUgYWxpYXMuCgoP
CgcEFQQAAgYBEgToAQQTCg8KBwQVBAACBgISBOgBFhcKOAoGBBUEAAIHEgTrAQQRGiggVGhl
IG9iamVjdCBiZWluZyBtYXBwZWQgaXMgYSBmdW5jdGlvbi4KCg8KBwQVBAACBwESBOsBBAwK
DwoHBBUEAAIHAhIE6wEPEAo4CgQEFQIAEgTvAQIQGiogVGhlIHR5cGUgb2Ygb2JqZWN0IHRo
YXQgaXMgYmVpbmcgbWFwcGVkLgoKDQoFBBUCAAYSBO8BAgYKDQoFBBUCAAESBO8BBwsKDQoF
BBUCAAMSBO8BDg8KYQoEBBUCARIE8wECFhpTIFRoZSBkYXRhYmFzZSBuYW1lIChCaWdRdWVy
eSBwcm9qZWN0IElEIGVxdWl2YWxlbnQgaW4gdGhlIHNvdXJjZSBkYXRhCiB3YXJlaG91c2Up
LgoKDQoFBBUCAQUSBPMBAggKDQoFBBUCAQESBPMBCREKDQoFBBUCAQMSBPMBFBUKWwoEBBUC
AhIE9gECFBpNIFRoZSBzY2hlbWEgbmFtZSAoQmlnUXVlcnkgZGF0YXNldCBlcXVpdmFsZW50
IGluIHRoZSBzb3VyY2UgZGF0YSB3YXJlaG91c2UpLgoKDQoFBBUCAgUSBPYBAggKDQoFBBUC
AgESBPYBCQ8KDQoFBBUCAgMSBPYBEhMKZAoEBBUCAxIE+gECFhpWIFRoZSByZWxhdGlvbiBu
YW1lIChCaWdRdWVyeSB0YWJsZSBvciB2aWV3IGVxdWl2YWxlbnQgaW4gdGhlIHNvdXJjZSBk
YXRhCiB3YXJlaG91c2UpLgoKDQoFBBUCAwUSBPoBAggKDQoFBBUCAwESBPoBCREKDQoFBBUC
AwMSBPoBFBUKXgoEBBUCBBIE/gECFxpQIFRoZSBhdHRyaWJ1dGUgbmFtZSAoQmlnUXVlcnkg
Y29sdW1uIGVxdWl2YWxlbnQgaW4gdGhlIHNvdXJjZSBkYXRhCiB3YXJlaG91c2UpLgoKDQoF
BBUCBAUSBP4BAggKDQoFBBUCBAESBP4BCRIKDQoFBBUCBAMSBP4BFRYKhQEKAgQWEgaDAgCS
AgEadyBUaGUgcG90ZW50aWFsIGNvbXBvbmVudHMgb2YgYSBmdWxsIG5hbWUgbWFwcGluZyB0
aGF0IHdpbGwgYmUgbWFwcGVkCiBkdXJpbmcgdHJhbnNsYXRpb24gaW4gdGhlIHRhcmdldCBk
YXRhIHdhcmVob3VzZS4KCgsKAwQWARIEgwIIGAphCgQEFgIAEgSGAgIWGlMgVGhlIGRhdGFi
YXNlIG5hbWUgKEJpZ1F1ZXJ5IHByb2plY3QgSUQgZXF1aXZhbGVudCBpbiB0aGUgdGFyZ2V0
IGRhdGEKIHdhcmVob3VzZSkuCgoNCgUEFgIABRIEhgICCAoNCgUEFgIAARIEhgIJEQoNCgUE
FgIAAxIEhgIUFQpbCgQEFgIBEgSJAgIUGk0gVGhlIHNjaGVtYSBuYW1lIChCaWdRdWVyeSBk
YXRhc2V0IGVxdWl2YWxlbnQgaW4gdGhlIHRhcmdldCBkYXRhIHdhcmVob3VzZSkuCgoNCgUE
FgIBBRIEiQICCAoNCgUEFgIBARIEiQIJDwoNCgUEFgIBAxIEiQISEwpkCgQEFgICEgSNAgIW
GlYgVGhlIHJlbGF0aW9uIG5hbWUgKEJpZ1F1ZXJ5IHRhYmxlIG9yIHZpZXcgZXF1aXZhbGVu
dCBpbiB0aGUgdGFyZ2V0IGRhdGEKIHdhcmVob3VzZSkuCgoNCgUEFgICBRIEjQICCAoNCgUE
FgICARIEjQIJEQoNCgUEFgICAxIEjQIUFQpeCgQEFgIDEgSRAgIXGlAgVGhlIGF0dHJpYnV0
ZSBuYW1lIChCaWdRdWVyeSBjb2x1bW4gZXF1aXZhbGVudCBpbiB0aGUgdGFyZ2V0IGRhdGEK
IHdhcmVob3VzZSkuCgoNCgUEFgIDBRIEkQICCAoNCgUEFgIDARIEkQIJEgoNCgUEFgIDAxIE
kQIVFgpVCgIEFxIGlQIApQIBGkcgUmVwcmVzZW50cyB0aGUgZGVmYXVsdCBzb3VyY2UgZW52
aXJvbm1lbnQgdmFsdWVzIGZvciB0aGUgdHJhbnNsYXRpb24uCgoLCgMEFwESBJUCCBEKbAoE
BBcCABIEmAICHhpeIFRoZSBkZWZhdWx0IGRhdGFiYXNlIG5hbWUgdG8gZnVsbHkgcXVhbGlm
eSBTUUwgb2JqZWN0cyB3aGVuIHRoZWlyIGRhdGFiYXNlCiBuYW1lIGlzIG1pc3NpbmcuCgoN
CgUEFwIABRIEmAICCAoNCgUEFwIAARIEmAIJGQoNCgUEFwIAAxIEmAIcHQqXAQoEBBcCARIE
nAICKRqIASBUaGUgc2NoZW1hIHNlYXJjaCBwYXRoLiBXaGVuIFNRTCBvYmplY3RzIGFyZSBt
aXNzaW5nIHNjaGVtYSBuYW1lLAogdHJhbnNsYXRpb24gZW5naW5lIHdpbGwgc2VhcmNoIHRo
cm91Z2ggdGhpcyBsaXN0IHRvIGZpbmQgdGhlIHZhbHVlLgoKDQoFBBcCAQQSBJwCAgoKDQoF
BBcCAQUSBJwCCxEKDQoFBBcCAQESBJwCEiQKDQoFBBcCAQMSBJwCJygKlgMKBAQXAgISBKQC
Ak0ahwMgT3B0aW9uYWwuIEV4cGVjdHMgYSB2YWxpZCBCaWdRdWVyeSBkYXRhc2V0IElEIHRo
YXQgZXhpc3RzLCBlLmcuLAogcHJvamVjdC0xMjMubWV0YWRhdGFfc3RvcmVfMTIzLiAgSWYg
c3BlY2lmaWVkLCB0cmFuc2xhdGlvbiB3aWxsIHNlYXJjaCBhbmQKIHJlYWQgdGhlIHJlcXVp
cmVkIHNjaGVtYSBpbmZvcm1hdGlvbiBmcm9tIGEgbWV0YWRhdGEgc3RvcmUgaW4gdGhpcyBk
YXRhc2V0LgogSWYgbWV0YWRhdGEgc3RvcmUgZG9lc24ndCBleGlzdCwgdHJhbnNsYXRpb24g
d2lsbCBwYXJzZSB0aGUgbWV0YWRhdGEgZmlsZQogYW5kIHVwbG9hZCB0aGUgc2NoZW1hIGlu
Zm8gdG8gYSB0ZW1wIHRhYmxlIGluIHRoZSBkYXRhc2V0IHRvIHNwZWVkIHVwCiBmdXR1cmUg
dHJhbnNsYXRpb24gam9icy4KCg0KBQQXAgIFEgSkAgIICg0KBQQXAgIBEgSkAgkfCg0KBQQX
AgIDEgSkAiIjCg0KBQQXAgIIEgSkAiRMChAKCAQXAgIInAgAEgSkAiVLYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails ===
    # Fields for TranslationConfigDetails
    # Field: gcs_source_path Type: 9 ()
    # Field: gcs_target_path Type: 9 ()
    # Field: name_mapping_list Type: 11 (.google.cloud.bigquery.migration.v2.ObjectNameMappingList)
    # Field: source_dialect Type: 11 (.google.cloud.bigquery.migration.v2.Dialect)
    # Field: target_dialect Type: 11 (.google.cloud.bigquery.migration.v2.Dialect)
    # Field: source_env Type: 11 (.google.cloud.bigquery.migration.v2.SourceEnv)
    # Field: request_source Type: 9 ()
    # Field: target_types Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect ===
    # Fields for Dialect
    # Field: bigquery_dialect Type: 11 (.google.cloud.bigquery.migration.v2.BigQueryDialect)
    # Field: hiveql_dialect Type: 11 (.google.cloud.bigquery.migration.v2.HiveQLDialect)
    # Field: redshift_dialect Type: 11 (.google.cloud.bigquery.migration.v2.RedshiftDialect)
    # Field: teradata_dialect Type: 11 (.google.cloud.bigquery.migration.v2.TeradataDialect)
    # Field: oracle_dialect Type: 11 (.google.cloud.bigquery.migration.v2.OracleDialect)
    # Field: sparksql_dialect Type: 11 (.google.cloud.bigquery.migration.v2.SparkSQLDialect)
    # Field: snowflake_dialect Type: 11 (.google.cloud.bigquery.migration.v2.SnowflakeDialect)
    # Field: netezza_dialect Type: 11 (.google.cloud.bigquery.migration.v2.NetezzaDialect)
    # Field: azure_synapse_dialect Type: 11 (.google.cloud.bigquery.migration.v2.AzureSynapseDialect)
    # Field: vertica_dialect Type: 11 (.google.cloud.bigquery.migration.v2.VerticaDialect)
    # Field: sql_server_dialect Type: 11 (.google.cloud.bigquery.migration.v2.SQLServerDialect)
    # Field: postgresql_dialect Type: 11 (.google.cloud.bigquery.migration.v2.PostgresqlDialect)
    # Field: presto_dialect Type: 11 (.google.cloud.bigquery.migration.v2.PrestoDialect)
    # Field: mysql_dialect Type: 11 (.google.cloud.bigquery.migration.v2.MySQLDialect)
    # Field: db2_dialect Type: 11 (.google.cloud.bigquery.migration.v2.DB2Dialect)
    # Field: sqlite_dialect Type: 11 (.google.cloud.bigquery.migration.v2.SQLiteDialect)
    # Field: greenplum_dialect Type: 11 (.google.cloud.bigquery.migration.v2.GreenplumDialect)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect ===
    # Fields for BigQueryDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect ===
    # Fields for HiveQLDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect ===
    # Fields for RedshiftDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect ===
    # Fields for TeradataDialect
    # Field: mode Type: 14 (.google.cloud.bigquery.migration.v2.TeradataDialect.Mode)

# Enum: TeradataDialect::Mode
our $TeradataDialect_MODE_UNSPECIFIED = 0;
our $TeradataDialect_SQL = 1;
our $TeradataDialect_BTEQ = 2;

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect ===
    # Fields for OracleDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect ===
    # Fields for SparkSQLDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect ===
    # Fields for SnowflakeDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect ===
    # Fields for NetezzaDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect ===
    # Fields for AzureSynapseDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect ===
    # Fields for VerticaDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect ===
    # Fields for SQLServerDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect ===
    # Fields for PostgresqlDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect ===
    # Fields for PrestoDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect ===
    # Fields for MySQLDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect ===
    # Fields for DB2Dialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect ===
    # Fields for SQLiteDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect ===
    # Fields for GreenplumDialect

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList ===
    # Fields for ObjectNameMappingList
    # Field: name_map Type: 11 (.google.cloud.bigquery.migration.v2.ObjectNameMapping)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping ===
    # Fields for ObjectNameMapping
    # Field: source Type: 11 (.google.cloud.bigquery.migration.v2.NameMappingKey)
    # Field: target Type: 11 (.google.cloud.bigquery.migration.v2.NameMappingValue)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey ===
    # Fields for NameMappingKey
    # Field: type Type: 14 (.google.cloud.bigquery.migration.v2.NameMappingKey.Type)
    # Field: database Type: 9 ()
    # Field: schema Type: 9 ()
    # Field: relation Type: 9 ()
    # Field: attribute Type: 9 ()

# Enum: NameMappingKey::Type
our $NameMappingKey_TYPE_UNSPECIFIED = 0;
our $NameMappingKey_DATABASE = 1;
our $NameMappingKey_SCHEMA = 2;
our $NameMappingKey_RELATION = 3;
our $NameMappingKey_ATTRIBUTE = 4;
our $NameMappingKey_RELATION_ALIAS = 5;
our $NameMappingKey_ATTRIBUTE_ALIAS = 6;
our $NameMappingKey_FUNCTION = 7;

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue ===
    # Fields for NameMappingValue
    # Field: database Type: 9 ()
    # Field: schema Type: 9 ()
    # Field: relation Type: 9 ()
    # Field: attribute Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv ===
    # Fields for SourceEnv
    # Field: default_database Type: 9 ()
    # Field: schema_search_path Type: 9 ()
    # Field: metadata_store_dataset Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationConfig - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/translation_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::TranslationConfig;

    my $msg = Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails->new({
        gcs_source_path => $gcs_source_path,
        gcs_target_path => $gcs_target_path,
        name_mapping_list => $name_mapping_list,
        source_dialect => $source_dialect,
    });

    # Read or update a field
    my $val = $msg->gcs_source_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/translation_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails

The translation config to capture necessary settings for a translation task
and subtask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source_path() >> / C<< $msg->gcs_source_path($value) >>

Type: C<String>

The Cloud Storage path for a directory of files to translate in a task.

=item * C<< $msg->gcs_target_path() >> / C<< $msg->gcs_target_path($value) >>

Type: C<String>

The Cloud Storage path to write back the corresponding input files to.

=item * C<< $msg->name_mapping_list() >> / C<< $msg->name_mapping_list($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList>)

The mapping of objects to their desired output names in list form.

=item * C<< $msg->source_dialect() >> / C<< $msg->source_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect>)

The dialect of the input files.

=item * C<< $msg->target_dialect() >> / C<< $msg->target_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect>)

The target dialect for the engine to translate the input to.

=item * C<< $msg->source_env() >> / C<< $msg->source_env($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv>)

The default source environment values for the translation.

=item * C<< $msg->request_source() >> / C<< $msg->request_source($value) >>

Type: C<String>

The indicator to show translation request initiator.

=item * C<< $msg->target_types() >> / C<< $msg->target_types($value) >>

Type: C<String>

The types of output to generate, e.g. sql, metadata etc. If not specified,
a default set of targets will be generated. Some additional target types
may be slower to generate. See the documentation for the set of available
target types.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect

The possible dialect options for translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bigquery_dialect() >> / C<< $msg->bigquery_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect>)

The BigQuery dialect

=item * C<< $msg->hiveql_dialect() >> / C<< $msg->hiveql_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect>)

The HiveQL dialect

=item * C<< $msg->redshift_dialect() >> / C<< $msg->redshift_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect>)

The Redshift dialect

=item * C<< $msg->teradata_dialect() >> / C<< $msg->teradata_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect>)

The Teradata dialect

=item * C<< $msg->oracle_dialect() >> / C<< $msg->oracle_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect>)

The Oracle dialect

=item * C<< $msg->sparksql_dialect() >> / C<< $msg->sparksql_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect>)

The SparkSQL dialect

=item * C<< $msg->snowflake_dialect() >> / C<< $msg->snowflake_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect>)

The Snowflake dialect

=item * C<< $msg->netezza_dialect() >> / C<< $msg->netezza_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect>)

The Netezza dialect

=item * C<< $msg->azure_synapse_dialect() >> / C<< $msg->azure_synapse_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect>)

The Azure Synapse dialect

=item * C<< $msg->vertica_dialect() >> / C<< $msg->vertica_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect>)

The Vertica dialect

=item * C<< $msg->sql_server_dialect() >> / C<< $msg->sql_server_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect>)

The SQL Server dialect

=item * C<< $msg->postgresql_dialect() >> / C<< $msg->postgresql_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect>)

The Postgresql dialect

=item * C<< $msg->presto_dialect() >> / C<< $msg->presto_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect>)

The Presto dialect

=item * C<< $msg->mysql_dialect() >> / C<< $msg->mysql_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect>)

The MySQL dialect

=item * C<< $msg->db2_dialect() >> / C<< $msg->db2_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect>)

DB2 dialect

=item * C<< $msg->sqlite_dialect() >> / C<< $msg->sqlite_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect>)

SQLite dialect

=item * C<< $msg->greenplum_dialect() >> / C<< $msg->greenplum_dialect($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect>)

Greenplum dialect

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect

The dialect definition for BigQuery.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect

The dialect definition for HiveQL.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect

The dialect definition for Redshift.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect

The dialect definition for Teradata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2::TeradataDialect::Mode>)

Which Teradata sub-dialect mode the user specifies.

=back

=head3 Enum: TeradataDialect::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<SQL> => C<1>

=item * C<BTEQ> => C<2>

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect

The dialect definition for Oracle.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect

The dialect definition for SparkSQL.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect

The dialect definition for Snowflake.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect

The dialect definition for Netezza.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect

The dialect definition for Azure Synapse.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect

The dialect definition for Vertica.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect

The dialect definition for SQL Server.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect

The dialect definition for Postgresql.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect

The dialect definition for Presto.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect

The dialect definition for MySQL.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect

The dialect definition for DB2.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect

The dialect definition for SQLite.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect

The dialect definition for Greenplum.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList

Represents a map of name mappings using a list of key:value proto messages of
existing name to desired output name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name_map() >> / C<< $msg->name_map($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping>)

The elements of the object name map.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping

Represents a key-value pair of NameMappingKey to NameMappingValue to
represent the mapping of SQL names from the input value to desired output.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey>)

The name of the object in source that is being mapped.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue>)

The desired target name of the object that is being mapped.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey

The potential components of a full name mapping that will be mapped
during translation in the source data warehouse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2::NameMappingKey::Type>)

The type of object that is being mapped.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

The database name (BigQuery project ID equivalent in the source data
warehouse).

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<String>

The schema name (BigQuery dataset equivalent in the source data warehouse).

=item * C<< $msg->relation() >> / C<< $msg->relation($value) >>

Type: C<String>

The relation name (BigQuery table or view equivalent in the source data
warehouse).

=item * C<< $msg->attribute() >> / C<< $msg->attribute($value) >>

Type: C<String>

The attribute name (BigQuery column equivalent in the source data
warehouse).

=back

=head3 Enum: NameMappingKey::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<DATABASE> => C<1>

=item * C<SCHEMA> => C<2>

=item * C<RELATION> => C<3>

=item * C<ATTRIBUTE> => C<4>

=item * C<RELATION_ALIAS> => C<5>

=item * C<ATTRIBUTE_ALIAS> => C<6>

=item * C<FUNCTION> => C<7>

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue

The potential components of a full name mapping that will be mapped
during translation in the target data warehouse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

The database name (BigQuery project ID equivalent in the target data
warehouse).

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<String>

The schema name (BigQuery dataset equivalent in the target data warehouse).

=item * C<< $msg->relation() >> / C<< $msg->relation($value) >>

Type: C<String>

The relation name (BigQuery table or view equivalent in the target data
warehouse).

=item * C<< $msg->attribute() >> / C<< $msg->attribute($value) >>

Type: C<String>

The attribute name (BigQuery column equivalent in the target data
warehouse).

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv

Represents the default source environment values for the translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->default_database() >> / C<< $msg->default_database($value) >>

Type: C<String>

The default database name to fully qualify SQL objects when their database
name is missing.

=item * C<< $msg->schema_search_path() >> / C<< $msg->schema_search_path($value) >>

Type: C<String>

The schema search path. When SQL objects are missing schema name,
translation engine will search through this list to find the value.

=item * C<< $msg->metadata_store_dataset() >> / C<< $msg->metadata_store_dataset($value) >>

Type: C<String>

Optional. Expects a valid BigQuery dataset ID that exists, e.g.,
project-123.metadata_store_123.  If specified, translation will search and
read the required schema information from a metadata store in this dataset.
If metadata store doesn't exist, translation will parse the metadata file
and upload the schema info to a temp table in the dataset to speed up
future translation jobs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
