package Google::Cloud::Runtimeconfig::V1beta1::Resources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvcnVudGltZWNvbmZpZy92MWJldGExL3Jlc291cmNlcy5wcm90bxIi
Z29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byJFCg1SdW50
aW1lQ29uZmlnEhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rl
c2NyaXB0aW9uIt4BCghWYXJpYWJsZRISCgRuYW1lGAEgASgJUgRuYW1lEhYKBXZhbHVlGAIg
ASgMSABSBXZhbHVlEhQKBHRleHQYBSABKAlIAFIEdGV4dBI7Cgt1cGRhdGVfdGltZRgDIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSRwoFc3RhdGUYBCAB
KA4yMS5nb29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGExLlZhcmlhYmxlU3RhdGVS
BXN0YXRlQgoKCGNvbnRlbnRzIrgBCgxFbmRDb25kaXRpb24SYAoLY2FyZGluYWxpdHkYASAB
KAsyPC5nb29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGExLkVuZENvbmRpdGlvbi5D
YXJkaW5hbGl0eUgAUgtjYXJkaW5hbGl0eRo5CgtDYXJkaW5hbGl0eRISCgRwYXRoGAEgASgJ
UgRwYXRoEhYKBm51bWJlchgCIAEoBVIGbnVtYmVyQgsKCWNvbmRpdGlvbiLkAgoGV2FpdGVy
EhIKBG5hbWUYASABKAlSBG5hbWUSMwoHdGltZW91dBgCIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblIHdGltZW91dBJKCgdmYWlsdXJlGAMgASgLMjAuZ29vZ2xlLmNsb3VkLnJ1
bnRpbWVjb25maWcudjFiZXRhMS5FbmRDb25kaXRpb25SB2ZhaWx1cmUSSgoHc3VjY2VzcxgE
IAEoCzIwLmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuRW5kQ29uZGl0aW9u
UgdzdWNjZXNzEjsKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKY3JlYXRlVGltZRISCgRkb25lGAYgASgIUgRkb25lEigKBWVycm9yGAcgASgLMhIu
Z29vZ2xlLnJwYy5TdGF0dXNSBWVycm9yKkkKDVZhcmlhYmxlU3RhdGUSHgoaVkFSSUFCTEVf
U1RBVEVfVU5TUEVDSUZJRUQQABILCgdVUERBVEVEEAESCwoHREVMRVRFRBACQsIBCiZjb20u
Z29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMVABWkxjbG91ZC5nb29nbGUuY29t
L2dvL3J1bnRpbWVjb25maWcvYXBpdjFiZXRhMS9ydW50aW1lY29uZmlncGI7cnVudGltZWNv
bmZpZ3BiqgIiR29vZ2xlLkNsb3VkLlJ1bnRpbWVDb25maWcuVjFCZXRhMcoCIkdvb2dsZVxD
bG91ZFxSdW50aW1lQ29uZmlnXFYxYmV0YTFKvUQKBxIFDgDQAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAoCgkK
AgMCEgMUACkKCQoCAwMSAxUAIQoICgEIEgMXAD8KCQoCCCUSAxcAPwoICgEIEgMYAGMKCQoC
CAsSAxgAYwoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAD8KCQoCCAESAxoAPwoICgEI
EgMbAD8KCQoCCCkSAxsAPwqxAQoCBAASBCAAMAEapAEgQSBSdW50aW1lQ29uZmlnIHJlc291
cmNlIGlzIHRoZSBwcmltYXJ5IHJlc291cmNlIGluIHRoZSBDbG91ZCBSdW50aW1lQ29uZmln
CiBzZXJ2aWNlLiBBIFJ1bnRpbWVDb25maWcgcmVzb3VyY2UgY29uc2lzdHMgb2YgbWV0YWRh
dGEgYW5kIGEgaGllcmFyY2h5IG9mCiB2YXJpYWJsZXMuCgoKCgMEAAESAyAIFQqBBAoEBAAC
ABIDLAISGvMDIFRoZSByZXNvdXJjZSBuYW1lIG9mIGEgcnVudGltZSBjb25maWcuIFRoZSBu
YW1lIG11c3QgaGF2ZSB0aGUgZm9ybWF0OgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF0v
Y29uZmlncy9bQ09ORklHX05BTUVdCgogVGhlIGBbUFJPSkVDVF9JRF1gIG11c3QgYmUgYSB2
YWxpZCBwcm9qZWN0IElELCBhbmQgYFtDT05GSUdfTkFNRV1gIGlzIGFuCiBhcmJpdHJhcnkg
bmFtZSB0aGF0IG1hdGNoZXMgUkZDIDEwMzUgc2VnbWVudCBzcGVjaWZpY2F0aW9uLiBUaGUg
bGVuZ3RoIG9mCiBgW0NPTkZJR19OQU1FXWAgbXVzdCBiZSBsZXNzIHRoYW4gNjQgYnl0ZXMu
CgogWW91IHBpY2sgdGhlIFJ1bnRpbWVDb25maWcgcmVzb3VyY2UgbmFtZSwgYnV0IHRoZSBz
ZXJ2ZXIgd2lsbCB2YWxpZGF0ZSB0aGF0CiB0aGUgbmFtZSBhZGhlcmVzIHRvIHRoaXMgZm9y
bWF0LiBBZnRlciB5b3UgY3JlYXRlIHRoZSByZXNvdXJjZSwgeW91IGNhbm5vdAogY2hhbmdl
IHRoZSByZXNvdXJjZSdzIG5hbWUuCgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCQ0KDAoF
BAACAAMSAywQEQpDCgQEAAIBEgMvAhkaNiBBbiBvcHRpb25hbCBkZXNjcmlwdGlvbiBvZiB0
aGUgUnVudGltZUNvbmZpZyBvYmplY3QuCgoMCgUEAAIBBRIDLwIICgwKBQQAAgEBEgMvCRQK
DAoFBAACAQMSAy8XGArGAgoCBAESBDcAYAEauQIgRGVzY3JpYmVzIGEgc2luZ2xlIHZhcmlh
YmxlIHdpdGhpbiBhIFJ1bnRpbWVDb25maWcgcmVzb3VyY2UuCiBUaGUgbmFtZSBkZW5vdGVz
IHRoZSBoaWVyYXJjaGljYWwgdmFyaWFibGUgbmFtZS4gRm9yIGV4YW1wbGUsCiBgcG9ydHMv
c2VydmluZ19wb3J0YCBpcyBhIHZhbGlkIHZhcmlhYmxlIG5hbWUuIFRoZSB2YXJpYWJsZSB2
YWx1ZSBpcyBhbgogb3BhcXVlIHN0cmluZyBhbmQgb25seSBsZWFmIHZhcmlhYmxlcyBjYW4g
aGF2ZSB2YWx1ZXMgKHRoYXQgaXMsIHZhcmlhYmxlcwogdGhhdCBkbyBub3QgaGF2ZSBhbnkg
Y2hpbGQgdmFyaWFibGVzKS4KCgoKAwQBARIDNwgQCqwGCgQEAQIAEgNIAhIangYgVGhlIG5h
bWUgb2YgdGhlIHZhcmlhYmxlIHJlc291cmNlLCBpbiB0aGUgZm9ybWF0OgoKICAgICBwcm9q
ZWN0cy9bUFJPSkVDVF9JRF0vY29uZmlncy9bQ09ORklHX05BTUVdL3ZhcmlhYmxlcy9bVkFS
SUFCTEVfTkFNRV0KCiBUaGUgYFtQUk9KRUNUX0lEXWAgbXVzdCBiZSBhIHZhbGlkIHByb2pl
Y3QgSUQsIGBbQ09ORklHX05BTUVdYCBtdXN0IGJlIGEKIHZhbGlkIFJ1bnRpbWVDb25maWcg
cmVvdXJjZSBhbmQgYFtWQVJJQUJMRV9OQU1FXWAgZm9sbG93cyBVbml4IGZpbGUgc3lzdGVt
CiBmaWxlIHBhdGggbmFtaW5nLgoKIFRoZSBgW1ZBUklBQkxFX05BTUVdYCBjYW4gY29udGFp
biBBU0NJSSBsZXR0ZXJzLCBudW1iZXJzLCBzbGFzaGVzIGFuZAogZGFzaGVzLiBTbGFzaGVz
IGFyZSB1c2VkIGFzIHBhdGggZWxlbWVudCBzZXBhcmF0b3JzIGFuZCBhcmUgbm90IHBhcnQg
b2YgdGhlCiBgW1ZBUklBQkxFX05BTUVdYCBpdHNlbGYsIHNvIGBbVkFSSUFCTEVfTkFNRV1g
IG11c3QgY29udGFpbiBhdCBsZWFzdCBvbmUKIG5vbi1zbGFzaCBjaGFyYWN0ZXIuIE11bHRp
cGxlIHNsYXNoZXMgYXJlIGNvYWxlc2NlZCBpbnRvIHNpbmdsZSBzbGFzaAogY2hhcmFjdGVy
LiBFYWNoIHBhdGggc2VnbWVudCBzaG91bGQgZm9sbG93IFJGQyAxMDM1IHNlZ21lbnQgc3Bl
Y2lmaWNhdGlvbi4KIFRoZSBsZW5ndGggb2YgYSBgW1ZBUklBQkxFX05BTUVdYCBtdXN0IGJl
IGxlc3MgdGhhbiAyNTYgYnl0ZXMuCgogT25jZSB5b3UgY3JlYXRlIGEgdmFyaWFibGUsIHlv
dSBjYW5ub3QgY2hhbmdlIHRoZSB2YXJpYWJsZSBuYW1lLgoKDAoFBAECAAUSA0gCCAoMCgUE
AQIAARIDSAkNCgwKBQQBAgADEgNIEBEKxgEKBAQBCAASBE0CVwMatwEgVGhlIHZhbHVlIG9m
IHRoZSB2YXJpYWJsZS4gSXQgY2FuIGJlIGVpdGhlciBhIGJpbmFyeSBvciBhIHN0cmluZwog
dmFsdWUuIFlvdSBtdXN0IHNwZWNpZnkgb25lIG9mIGVpdGhlciBgdmFsdWVgIG9yIGB0ZXh0
YC4gU3BlY2lmeWluZyBib3RoCiB3aWxsIGNhdXNlIHRoZSBzZXJ2ZXIgdG8gcmV0dXJuIGFu
IGVycm9yLgoKDAoFBAEIAAESA00IEArVAQoEBAECARIDUQQUGscBIFRoZSBiaW5hcnkgdmFs
dWUgb2YgdGhlIHZhcmlhYmxlLiBUaGUgbGVuZ3RoIG9mIHRoZSB2YWx1ZSBtdXN0IGJlIGxl
c3MKIHRoYW4gNDA5NiBieXRlcy4gRW1wdHkgdmFsdWVzIGFyZSBhbHNvIGFjY2VwdGVkLiBU
aGUgdmFsdWUgbXVzdCBiZQogYmFzZTY0IGVuY29kZWQuIE9ubHkgb25lIG9mIGB2YWx1ZWAg
b3IgYHRleHRgIGNhbiBiZSBzZXQuCgoMCgUEAQIBBRIDUQQJCgwKBQQBAgEBEgNRCg8KDAoF
BAECAQMSA1ESEwrPAQoEBAECAhIDVgQUGsEBIFRoZSBzdHJpbmcgdmFsdWUgb2YgdGhlIHZh
cmlhYmxlLiBUaGUgbGVuZ3RoIG9mIHRoZSB2YWx1ZSBtdXN0IGJlIGxlc3MKIHRoYW4gNDA5
NiBieXRlcy4gRW1wdHkgdmFsdWVzIGFyZSBhbHNvIGFjY2VwdGVkLiBGb3IgZXhhbXBsZSwK
IGB0ZXh0OiAibXkgdGV4dCB2YWx1ZSJgLiBUaGUgc3RyaW5nIG11c3QgYmUgdmFsaWQgVVRG
LTguCgoMCgUEAQICBRIDVgQKCgwKBQQBAgIBEgNWCw8KDAoFBAECAgMSA1YSEwpCCgQEAQID
EgNaAiwaNSBbT3V0cHV0IE9ubHldIFRoZSB0aW1lIG9mIHRoZSBsYXN0IHZhcmlhYmxlIHVw
ZGF0ZS4KCgwKBQQBAgMGEgNaAhsKDAoFBAECAwESA1ocJwoMCgUEAQIDAxIDWiorCr0BCgQE
AQIEEgNfAhoarwEgW091cHV0IG9ubHldIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSB2YXJp
YWJsZS4gVGhlIHZhcmlhYmxlIHN0YXRlCiBpbmRpY2F0ZXMgdGhlIG91dGNvbWUgb2YgdGhl
IGB2YXJpYWJsZXMoKS53YXRjaGAgY2FsbCBhbmQgaXMgdmlzaWJsZQogdGhyb3VnaCB0aGUg
YGdldGAgYW5kIGBsaXN0YCBjYWxscy4KCgwKBQQBAgQGEgNfAg8KDAoFBAECBAESA18QFQoM
CgUEAQIEAxIDXxgZCkMKAgQCEgVjAIEBARo2IFRoZSBjb25kaXRpb24gdGhhdCBhIFdhaXRl
ciByZXNvdXJjZSBpcyB3YWl0aW5nIGZvci4KCgoKAwQCARIDYwgUCtEFCgQEAgMAEgRyAnkD
GsIFIEEgQ2FyZGluYWxpdHkgY29uZGl0aW9uIGZvciB0aGUgV2FpdGVyIHJlc291cmNlLiBB
IGNhcmRpbmFsaXR5IGNvbmRpdGlvbiBpcwogbWV0IHdoZW4gdGhlIG51bWJlciBvZiB2YXJp
YWJsZXMgdW5kZXIgYSBzcGVjaWZpZWQgcGF0aCBwcmVmaXggcmVhY2hlcyBhCiBwcmVkZWZp
bmVkIG51bWJlci4gRm9yIGV4YW1wbGUsIGlmIHlvdSBzZXQgYSBDYXJkaW5hbGl0eSBjb25k
aXRpb24gd2hlcmUKIHRoZSBgcGF0aGAgaXMgc2V0IHRvIGAvZm9vYCBhbmQgdGhlIG51bWJl
ciBvZiBwYXRocyBpcyBzZXQgdG8gMiwgdGhlCiBmb2xsb3dpbmcgdmFyaWFibGVzIHdvdWxk
IG1lZXQgdGhlIGNvbmRpdGlvbiBpbiBhIFJ1bnRpbWVDb25maWcgcmVzb3VyY2U6CgogKyBg
L2Zvby92YXJpYWJsZTEgPSAidmFsdWUxImAKICsgYC9mb28vdmFyaWFibGUyID0gInZhbHVl
MiJgCiArIGAvYmFyL3ZhcmlhYmxlMyA9ICJ2YWx1ZTMiYAoKIEl0IHdvdWxkIG5vdCB3b3Vs
ZCBub3Qgc2F0aXNpZnkgdGhlIHNhbWUgY29uZGl0aW9uIHdpdGggdGhlIGBudW1iZXJgIHNl
dCB0bwogMywgaG93ZXZlciwgYmVjYXVzZSB0aGVyZSBpcyBvbmx5IDIgcGF0aHMgdGhhdCBz
dGFydCB3aXRoIGAvZm9vYC4KIENhcmRpbmFsaXR5IGNvbmRpdGlvbnMgYXJlIHJlY3Vyc2l2
ZTsgYWxsIHN1YnRyZWVzIHVuZGVyIHRoZSBzcGVjaWZpYwogcGF0aCBwcmVmaXggYXJlIGNv
dW50ZWQuCgoMCgUEAgMAARIDcgoVClIKBgQCAwACABIDdAQUGkMgVGhlIHJvb3Qgb2YgdGhl
IHZhcmlhYmxlIHN1YnRyZWUgdG8gbW9uaXRvci4gRm9yIGV4YW1wbGUsIGAvZm9vYC4KCg4K
BwQCAwACAAUSA3QECgoOCgcEAgMAAgABEgN0Cw8KDgoHBAIDAAIAAxIDdBITCn8KBgQCAwAC
ARIDeAQVGnAgVGhlIG51bWJlciB2YXJpYWJsZXMgdW5kZXIgdGhlIGBwYXRoYCB0aGF0IG11
c3QgZXhpc3QgdG8gbWVldCB0aGlzCiBjb25kaXRpb24uIERlZmF1bHRzIHRvIDEgaWYgbm90
IHNwZWNpZmllZC4KCg4KBwQCAwACAQUSA3gECQoOCgcEAgMAAgEBEgN4ChAKDgoHBAIDAAIB
AxIDeBMUCpQBCgQEAggAEgV9AoABAxqEASBUaGUgY29uZGl0aW9uIG9uZW9mIGhvbGRzIHRo
ZSBhdmFpbGFibGUgY29uZGl0aW9uIHR5cGVzIGZvciB0aGlzCiBFbmRDb25kaXRpb24uIEN1
cnJlbnRseSwgdGhlIG9ubHkgYXZhaWxhYmxlIHR5cGUgaXMgQ2FyZGluYWxpdHkuCgoMCgUE
AggAARIDfQgRCjUKBAQCAgASA38EIBooIFRoZSBjYXJkaW5hbGl0eSBvZiB0aGUgYEVuZENv
bmRpdGlvbmAuCgoMCgUEAgIABhIDfwQPCgwKBQQCAgABEgN/EBsKDAoFBAICAAMSA38eHwra
BQoCBAMSBpMBAMIBARrLBSBBIFdhaXRlciByZXNvdXJjZSB3YWl0cyBmb3Igc29tZSBlbmQg
Y29uZGl0aW9uIHdpdGhpbiBhIFJ1bnRpbWVDb25maWcKIHJlc291cmNlIHRvIGJlIG1ldCBi
ZWZvcmUgaXQgcmV0dXJucy4gRm9yIGV4YW1wbGUsIGFzc3VtZSB5b3UgaGF2ZSBhCiBkaXN0
cmlidXRlZCBzeXN0ZW0gd2hlcmUgZWFjaCBub2RlIHdyaXRlcyB0byBhIFZhcmlhYmxlIHJl
c291cmNlIGluZGlkaWNhdGluZwogdGhlIG5vZGUncyByZWFkaW5lc3MgYXMgcGFydCBvZiB0
aGUgc3RhcnR1cCBwcm9jZXNzLgoKIFlvdSB0aGVuIGNvbmZpZ3VyZSBhIFdhaXRlciByZXNv
dXJjZSB3aXRoIHRoZSBzdWNjZXNzIGNvbmRpdGlvbiBzZXQgdG8gd2FpdAogdW50aWwgc29t
ZSBudW1iZXIgb2Ygbm9kZXMgaGF2ZSBjaGVja2VkIGluLiBBZnRlcndhcmRzLCB5b3VyIGFw
cGxpY2F0aW9uCiBydW5zIHNvbWUgYXJiaXRyYXJ5IGNvZGUgYWZ0ZXIgdGhlIGNvbmRpdGlv
biBoYXMgYmVlbiBtZXQgYW5kIHRoZSB3YWl0ZXIKIHJldHVybnMgc3VjY2Vzc2Z1bGx5LgoK
IE9uY2UgY3JlYXRlZCwgYSBXYWl0ZXIgcmVzb3VyY2UgaXMgaW1tdXRhYmxlLgoKIFRvIGxl
YXJuIG1vcmUgYWJvdXQgdXNpbmcgd2FpdGVycywgcmVhZCB0aGUKIFtDcmVhdGluZyBhCiBX
YWl0ZXJdKC9kZXBsb3ltZW50LW1hbmFnZXIvcnVudGltZS1jb25maWd1cmF0b3IvY3JlYXRp
bmctYS13YWl0ZXIpCiBkb2N1bWVudGF0aW9uLgoKCwoDBAMBEgSTAQgOCs0DCgQEAwIAEgSe
AQISGr4DIFRoZSBuYW1lIG9mIHRoZSBXYWl0ZXIgcmVzb3VyY2UsIGluIHRoZSBmb3JtYXQ6
CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lEXS9jb25maWdzL1tDT05GSUdfTkFNRV0vd2Fp
dGVycy9bV0FJVEVSX05BTUVdCgogVGhlIGBbUFJPSkVDVF9JRF1gIG11c3QgYmUgYSB2YWxp
ZCBHb29nbGUgQ2xvdWQgcHJvamVjdCBJRCwKIHRoZSBgW0NPTkZJR19OQU1FXWAgbXVzdCBi
ZSBhIHZhbGlkIFJ1bnRpbWVDb25maWcgcmVzb3VyY2UsIHRoZQogYFtXQUlURVJfTkFNRV1g
IG11c3QgbWF0Y2ggUkZDIDEwMzUgc2VnbWVudCBzcGVjaWZpY2F0aW9uLCBhbmQgdGhlIGxl
bmd0aAogb2YgYFtXQUlURVJfTkFNRV1gIG11c3QgYmUgbGVzcyB0aGFuIDY0IGJ5dGVzLgoK
IEFmdGVyIHlvdSBjcmVhdGUgYSBXYWl0ZXIgcmVzb3VyY2UsIHlvdSBjYW5ub3QgY2hhbmdl
IHRoZSByZXNvdXJjZSBuYW1lLgoKDQoFBAMCAAUSBJ4BAggKDQoFBAMCAAESBJ4BCQ0KDQoF
BAMCAAMSBJ4BEBEKnQIKBAQDAgESBKQBAicajgIgW1JlcXVpcmVkXSBTcGVjaWZpZXMgdGhl
IHRpbWVvdXQgb2YgdGhlIHdhaXRlciBpbiBzZWNvbmRzLCBiZWdpbm5pbmcgZnJvbQogdGhl
IGluc3RhbnQgdGhhdCBgd2FpdGVycygpLmNyZWF0ZWAgbWV0aG9kIGlzIGNhbGxlZC4gSWYg
dGhpcyB0aW1lIGVsYXBzZXMKIGJlZm9yZSB0aGUgc3VjY2VzcyBvciBmYWlsdXJlIGNvbmRp
dGlvbnMgYXJlIG1ldCwgdGhlIHdhaXRlciBmYWlscyBhbmQgc2V0cwogdGhlIGBlcnJvcmAg
Y29kZSB0byBgREVBRExJTkVfRVhDRUVERURgLgoKDQoFBAMCAQYSBKQBAhoKDQoFBAMCAQES
BKQBGyIKDQoFBAMCAQMSBKQBJSYKjAMKBAQDAgISBKsBAhsa/QIgW09wdGlvbmFsXSBUaGUg
ZmFpbHVyZSBjb25kaXRpb24gb2YgdGhpcyB3YWl0ZXIuIElmIHRoaXMgY29uZGl0aW9uIGlz
IG1ldCwKIGBkb25lYCB3aWxsIGJlIHNldCB0byBgdHJ1ZWAgYW5kIHRoZSBgZXJyb3JgIGNv
ZGUgd2lsbCBiZSBzZXQgdG8gYEFCT1JURURgLgogVGhlIGZhaWx1cmUgY29uZGl0aW9uIHRh
a2VzIHByZWNlZGVuY2Ugb3ZlciB0aGUgc3VjY2VzcyBjb25kaXRpb24uIElmIGJvdGgKIGNv
bmRpdGlvbnMgYXJlIG1ldCwgYSBmYWlsdXJlIHdpbGwgYmUgaW5kaWNhdGVkLiBUaGlzIHZh
bHVlIGlzIG9wdGlvbmFsOyBpZgogbm8gZmFpbHVyZSBjb25kaXRpb24gaXMgc2V0LCB0aGUg
b25seSBmYWlsdXJlIHNjZW5hcmlvIHdpbGwgYmUgYSB0aW1lb3V0LgoKDQoFBAMCAgYSBKsB
Ag4KDQoFBAMCAgESBKsBDxYKDQoFBAMCAgMSBKsBGRoKkQIKBAQDAgMSBLEBAhsaggIgW1Jl
cXVpcmVkXSBUaGUgc3VjY2VzcyBjb25kaXRpb24uIElmIHRoaXMgY29uZGl0aW9uIGlzIG1l
dCwgYGRvbmVgIHdpbGwgYmUKIHNldCB0byBgdHJ1ZWAgYW5kIHRoZSBgZXJyb3JgIHZhbHVl
IHdpbGwgcmVtYWluIHVuc2V0LiBUaGUgZmFpbHVyZQogY29uZGl0aW9uIHRha2VzIHByZWNl
ZGVuY2Ugb3ZlciB0aGUgc3VjY2VzcyBjb25kaXRpb24uIElmIGJvdGggY29uZGl0aW9ucwog
YXJlIG1ldCwgYSBmYWlsdXJlIHdpbGwgYmUgaW5kaWNhdGVkLgoKDQoFBAMCAwYSBLEBAg4K
DQoFBAMCAwESBLEBDxYKDQoFBAMCAwMSBLEBGRoKsQEKBAQDAgQSBLYBAiwaogEgW091dHB1
dCBPbmx5XSBUaGUgaW5zdGFudCBhdCB3aGljaCB0aGlzIFdhaXRlciByZXNvdXJjZSB3YXMg
Y3JlYXRlZC4gQWRkaW5nCiB0aGUgdmFsdWUgb2YgYHRpbWVvdXRgIHRvIHRoaXMgaW5zdGFu
dCB5aWVsZHMgdGhlIHRpbWVvdXQgZGVhZGxpbmUgZm9yIHRoZQogd2FpdGVyLgoKDQoFBAMC
BAYSBLYBAhsKDQoFBAMCBAESBLYBHCcKDQoFBAMCBAMSBLYBKisK8AEKBAQDAgUSBL0BAhAa
4QEgW091dHB1dCBPbmx5XSBJZiB0aGUgdmFsdWUgaXMgYGZhbHNlYCwgaXQgbWVhbnMgdGhl
IHdhaXRlciBpcyBzdGlsbCB3YWl0aW5nCiBmb3Igb25lIG9mIGl0cyBjb25kaXRpb25zIHRv
IGJlIG1ldC4KCiBJZiB0cnVlLCB0aGUgd2FpdGVyIGhhcyBmaW5pc2hlZC4gSWYgdGhlIHdh
aXRlciBmaW5pc2hlZCBkdWUgdG8gYSB0aW1lb3V0CiBvciBmYWlsdXJlLCBgZXJyb3JgIHdp
bGwgYmUgc2V0LgoKDQoFBAMCBQUSBL0BAgYKDQoFBAMCBQESBL0BBwsKDQoFBAMCBQMSBL0B
Dg8KZwoEBAMCBhIEwQECHhpZIFtPdXRwdXQgT25seV0gSWYgdGhlIHdhaXRlciBlbmRlZCBk
dWUgdG8gYSBmYWlsdXJlIG9yIHRpbWVvdXQsIHRoaXMgdmFsdWUKIHdpbGwgYmUgc2V0LgoK
DQoFBAMCBgYSBMEBAhMKDQoFBAMCBgESBMEBFBkKDQoFBAMCBgMSBMEBHB0KrQEKAgUAEgbH
AQDQAQEangEgVGhlIGBWYXJpYWJsZVN0YXRlYCBkZXNjcmliZXMgdGhlIGxhc3Qga25vd24g
c3RhdGUgb2YgdGhlIHZhcmlhYmxlIGFuZCBpcwogdXNlZCBkdXJpbmcgYSBgdmFyaWFibGVz
KCkud2F0Y2hgIGNhbGwgdG8gZGlzdGluZ3Vpc2ggdGhlIHN0YXRlIG9mIHRoZQogdmFyaWFi
bGUuCgoLCgMFAAESBMcBBRIKJwoEBQACABIEyQECIRoZIERlZmF1bHQgdmFyaWFibGUgc3Rh
dGUuCgoNCgUFAAIAARIEyQECHAoNCgUFAAIAAhIEyQEfIApSCgQFAAIBEgTMAQIOGkQgVGhl
IHZhcmlhYmxlIHdhcyB1cGRhdGVkLCB3aGlsZSBgdmFyaWFibGVzKCkud2F0Y2hgIHdhcyBl
eGVjdXRpbmcuCgoNCgUFAAIBARIEzAECCQoNCgUFAAIBAhIEzAEMDQpSCgQFAAICEgTPAQIO
GkQgVGhlIHZhcmlhYmxlIHdhcyBkZWxldGVkLCB3aGlsZSBgdmFyaWFibGVzKCkud2F0Y2hg
IHdhcyBleGVjdXRpbmcuCgoNCgUFAAICARIEzwECCQoNCgUFAAICAhIEzwEMDWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig ===
    # Fields for RuntimeConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable ===
    # Fields for Variable
    # Field: name Type: 9 ()
    # Field: value Type: 12 ()
    # Field: text Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.runtimeconfig.v1beta1.VariableState)

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition ===
    # Fields for EndCondition
    # Field: cardinality Type: 11 (.google.cloud.runtimeconfig.v1beta1.EndCondition.Cardinality)

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter ===
    # Fields for Waiter
    # Field: name Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: failure Type: 11 (.google.cloud.runtimeconfig.v1beta1.EndCondition)
    # Field: success Type: 11 (.google.cloud.runtimeconfig.v1beta1.EndCondition)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: done Type: 8 ()
    # Field: error Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Runtimeconfig::V1beta1::Resources - Compiled Protocol Buffers messages for google/cloud/runtimeconfig/v1beta1/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Runtimeconfig::V1beta1::Resources;

    my $msg = Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig->new({
        name => $name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/runtimeconfig/v1beta1/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig

A RuntimeConfig resource is the primary resource in the Cloud RuntimeConfig
service. A RuntimeConfig resource consists of metadata and a hierarchy of
variables.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of a runtime config. The name must have the format:

    projects/[PROJECT_ID]/configs/[CONFIG_NAME]

The `[PROJECT_ID]` must be a valid project ID, and `[CONFIG_NAME]` is an
arbitrary name that matches RFC 1035 segment specification. The length of
`[CONFIG_NAME]` must be less than 64 bytes.

You pick the RuntimeConfig resource name, but the server will validate that
the name adheres to this format. After you create the resource, you cannot
change the resource's name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

An optional description of the RuntimeConfig object.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable

Describes a single variable within a RuntimeConfig resource.
The name denotes the hierarchical variable name. For example,
`ports/serving_port` is a valid variable name. The variable value is an
opaque string and only leaf variables can have values (that is, variables
that do not have any child variables).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the variable resource, in the format:

    projects/[PROJECT_ID]/configs/[CONFIG_NAME]/variables/[VARIABLE_NAME]

The `[PROJECT_ID]` must be a valid project ID, `[CONFIG_NAME]` must be a
valid RuntimeConfig reource and `[VARIABLE_NAME]` follows Unix file system
file path naming.

The `[VARIABLE_NAME]` can contain ASCII letters, numbers, slashes and
dashes. Slashes are used as path element separators and are not part of the
`[VARIABLE_NAME]` itself, so `[VARIABLE_NAME]` must contain at least one
non-slash character. Multiple slashes are coalesced into single slash
character. Each path segment should follow RFC 1035 segment specification.
The length of a `[VARIABLE_NAME]` must be less than 256 bytes.

Once you create a variable, you cannot change the variable name.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bytes>

The binary value of the variable. The length of the value must be less
than 4096 bytes. Empty values are also accepted. The value must be
base64 encoded. Only one of `value` or `text` can be set.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

The string value of the variable. The length of the value must be less
than 4096 bytes. Empty values are also accepted. For example,
`text: "my text value"`. The string must be valid UTF-8.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

[Output Only] The time of the last variable update.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Runtimeconfig::V1beta1::VariableState>)

[Ouput only] The current state of the variable. The variable state
indicates the outcome of the `variables().watch` call and is visible
through the `get` and `list` calls.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition

The condition that a Waiter resource is waiting for.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cardinality() >> / C<< $msg->cardinality($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition::Cardinality>)

The cardinality of the `EndCondition`.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter

A Waiter resource waits for some end condition within a RuntimeConfig
resource to be met before it returns. For example, assume you have a
distributed system where each node writes to a Variable resource indidicating
the node's readiness as part of the startup process.

You then configure a Waiter resource with the success condition set to wait
until some number of nodes have checked in. Afterwards, your application
runs some arbitrary code after the condition has been met and the waiter
returns successfully.

Once created, a Waiter resource is immutable.

To learn more about using waiters, read the
[Creating a
Waiter](/deployment-manager/runtime-configurator/creating-a-waiter)
documentation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the Waiter resource, in the format:

    projects/[PROJECT_ID]/configs/[CONFIG_NAME]/waiters/[WAITER_NAME]

The `[PROJECT_ID]` must be a valid Google Cloud project ID,
the `[CONFIG_NAME]` must be a valid RuntimeConfig resource, the
`[WAITER_NAME]` must match RFC 1035 segment specification, and the length
of `[WAITER_NAME]` must be less than 64 bytes.

After you create a Waiter resource, you cannot change the resource name.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

[Required] Specifies the timeout of the waiter in seconds, beginning from
the instant that `waiters().create` method is called. If this time elapses
before the success or failure conditions are met, the waiter fails and sets
the `error` code to `DEADLINE_EXCEEDED`.

=item * C<< $msg->failure() >> / C<< $msg->failure($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition>)

[Optional] The failure condition of this waiter. If this condition is met,
`done` will be set to `true` and the `error` code will be set to `ABORTED`.
The failure condition takes precedence over the success condition. If both
conditions are met, a failure will be indicated. This value is optional; if
no failure condition is set, the only failure scenario will be a timeout.

=item * C<< $msg->success() >> / C<< $msg->success($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::EndCondition>)

[Required] The success condition. If this condition is met, `done` will be
set to `true` and the `error` value will remain unset. The failure
condition takes precedence over the success condition. If both conditions
are met, a failure will be indicated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

[Output Only] The instant at which this Waiter resource was created. Adding
the value of `timeout` to this instant yields the timeout deadline for the
waiter.

=item * C<< $msg->done() >> / C<< $msg->done($value) >>

Type: C<Bool>

[Output Only] If the value is `false`, it means the waiter is still waiting
for one of its conditions to be met.

If true, the waiter has finished. If the waiter finished due to a timeout
or failure, `error` will be set.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

[Output Only] If the waiter ended due to a failure or timeout, this value
will be set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
