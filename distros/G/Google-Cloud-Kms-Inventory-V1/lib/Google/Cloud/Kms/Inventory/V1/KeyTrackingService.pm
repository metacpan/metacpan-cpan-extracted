package Google::Cloud::Kms::Inventory::V1::KeyTrackingService;

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
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQva21zL2ludmVudG9yeS92MS9rZXlfdHJhY2tpbmdfc2VydmljZS5w
cm90bxIdZ29vZ2xlLmNsb3VkLmttcy5pbnZlbnRvcnkudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvItIBCiNHZXRQcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5
UmVxdWVzdBJRCgRuYW1lGAEgASgJQj3gQQL6QTcKNWttc2ludmVudG9yeS5nb29nbGVhcGlz
LmNvbS9Qcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5UgRuYW1lElgKDmZhbGxiYWNrX3Njb3Bl
GAIgASgOMiwuZ29vZ2xlLmNsb3VkLmttcy5pbnZlbnRvcnkudjEuRmFsbGJhY2tTY29wZUID
4EEBUg1mYWxsYmFja1Njb3BlIpQIChlQcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5EhIKBG5h
bWUYBSABKAlSBG5hbWUSJQoOcmVzb3VyY2VfY291bnQYASABKANSDXJlc291cmNlQ291bnQS
IwoNcHJvamVjdF9jb3VudBgCIAEoBVIMcHJvamVjdENvdW50EnIKDnJlc291cmNlX3R5cGVz
GAMgAygLMksuZ29vZ2xlLmNsb3VkLmttcy5pbnZlbnRvcnkudjEuUHJvdGVjdGVkUmVzb3Vy
Y2VzU3VtbWFyeS5SZXNvdXJjZVR5cGVzRW50cnlSDXJlc291cmNlVHlwZXMScgoOY2xvdWRf
cHJvZHVjdHMYBiADKAsySy5nb29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5Qcm90ZWN0
ZWRSZXNvdXJjZXNTdW1tYXJ5LkNsb3VkUHJvZHVjdHNFbnRyeVINY2xvdWRQcm9kdWN0cxJl
Cglsb2NhdGlvbnMYBCADKAsyRy5nb29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5Qcm90
ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5LkxvY2F0aW9uc0VudHJ5Uglsb2NhdGlvbnMSQgoId2Fy
bmluZ3MYByADKAsyJi5nb29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5XYXJuaW5nUgh3
YXJuaW5ncxpAChJSZXNvdXJjZVR5cGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFs
dWUYAiABKANSBXZhbHVlOgI4ARpAChJDbG91ZFByb2R1Y3RzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKANSBXZhbHVlOgI4ARo8Cg5Mb2NhdGlvbnNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgBOsEC6kG9Ago1a21zaW52
ZW50b3J5Lmdvb2dsZWFwaXMuY29tL1Byb3RlY3RlZFJlc291cmNlc1N1bW1hcnkSbXByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9
L2NyeXB0b0tleXMve2NyeXB0b19rZXl9L3Byb3RlY3RlZFJlc291cmNlc1N1bW1hcnkSlAFw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9y
aW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fS9jcnlwdG9LZXlWZXJzaW9ucy97Y3J5cHRv
X2tleV92ZXJzaW9ufS9wcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5IoUCCh9TZWFyY2hQcm90
ZWN0ZWRSZXNvdXJjZXNSZXF1ZXN0ElAKBXNjb3BlGAIgASgJQjrgQQL6QTQSMmttc2ludmVu
dG9yeS5nb29nbGVhcGlzLmNvbS9Qcm90ZWN0ZWRSZXNvdXJjZVNjb3BlUgVzY29wZRIoCgpj
cnlwdG9fa2V5GAEgASgJQgngQQL6QQMKASpSCWNyeXB0b0tleRIbCglwYWdlX3NpemUYAyAB
KAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBCABKAlSCXBhZ2VUb2tlbhIqCg5yZXNvdXJj
ZV90eXBlcxgFIAMoCUID4EEBUg1yZXNvdXJjZVR5cGVzIq0BCiBTZWFyY2hQcm90ZWN0ZWRS
ZXNvdXJjZXNSZXNwb25zZRJhChNwcm90ZWN0ZWRfcmVzb3VyY2VzGAEgAygLMjAuZ29vZ2xl
LmNsb3VkLmttcy5pbnZlbnRvcnkudjEuUHJvdGVjdGVkUmVzb3VyY2VSEnByb3RlY3RlZFJl
c291cmNlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i/gQKEVBy
b3RlY3RlZFJlc291cmNlEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHcHJvamVjdBgCIAEoCVIH
cHJvamVjdBIdCgpwcm9qZWN0X2lkGAkgASgJUglwcm9qZWN0SWQSIwoNY2xvdWRfcHJvZHVj
dBgIIAEoCVIMY2xvdWRQcm9kdWN0EiMKDXJlc291cmNlX3R5cGUYAyABKAlSDHJlc291cmNl
VHlwZRIaCghsb2NhdGlvbhgEIAEoCVIIbG9jYXRpb24SVAoGbGFiZWxzGAUgAygLMjwuZ29v
Z2xlLmNsb3VkLmttcy5pbnZlbnRvcnkudjEuUHJvdGVjdGVkUmVzb3VyY2UuTGFiZWxzRW50
cnlSBmxhYmVscxJbChJjcnlwdG9fa2V5X3ZlcnNpb24YBiABKAlCLfpBKgooY2xvdWRrbXMu
Z29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5VmVyc2lvblIQY3J5cHRvS2V5VmVyc2lvbhJdChNj
cnlwdG9fa2V5X3ZlcnNpb25zGAogAygJQi36QSoKKGNsb3Vka21zLmdvb2dsZWFwaXMuY29t
L0NyeXB0b0tleVZlcnNpb25SEWNyeXB0b0tleVZlcnNpb25zEkAKC2NyZWF0ZV90aW1lGAcg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lGjkKC0xh
YmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6
J+pBJAofY2xvdWRhc3NldC5nb29nbGVhcGlzLmNvbS9Bc3NldBIBKiKvAgoHV2FybmluZxJV
Cgx3YXJuaW5nX2NvZGUYASABKA4yMi5nb29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5X
YXJuaW5nLldhcm5pbmdDb2RlUgt3YXJuaW5nQ29kZRInCg9kaXNwbGF5X21lc3NhZ2UYAiAB
KAlSDmRpc3BsYXlNZXNzYWdlIqMBCgtXYXJuaW5nQ29kZRIcChhXQVJOSU5HX0NPREVfVU5T
UEVDSUZJRUQQABIpCiVJTlNVRkZJQ0lFTlRfUEVSTUlTU0lPTlNfUEFSVElBTF9EQVRBEAES
KAokUkVTT1VSQ0VfTElNSVRfRVhDRUVERURfUEFSVElBTF9EQVRBEAISIQodT1JHX0xFU1Nf
UFJPSkVDVF9QQVJUSUFMX0RBVEEQAypLCg1GYWxsYmFja1Njb3BlEh4KGkZBTExCQUNLX1ND
T1BFX1VOU1BFQ0lGSUVEEAASGgoWRkFMTEJBQ0tfU0NPUEVfUFJPSkVDVBABMo8FChJLZXlU
cmFja2luZ1NlcnZpY2USgQIKHEdldFByb3RlY3RlZFJlc291cmNlc1N1bW1hcnkSQi5nb29n
bGUuY2xvdWQua21zLmludmVudG9yeS52MS5HZXRQcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5
UmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYxLlByb3RlY3RlZFJlc291
cmNlc1N1bW1hcnkiY4LT5JMCVhJUL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
a2V5UmluZ3MvKi9jcnlwdG9LZXlzLyoqfS9wcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ52kEE
bmFtZRKjAgoYU2VhcmNoUHJvdGVjdGVkUmVzb3VyY2VzEj4uZ29vZ2xlLmNsb3VkLmttcy5p
bnZlbnRvcnkudjEuU2VhcmNoUHJvdGVjdGVkUmVzb3VyY2VzUmVxdWVzdBo/Lmdvb2dsZS5j
bG91ZC5rbXMuaW52ZW50b3J5LnYxLlNlYXJjaFByb3RlY3RlZFJlc291cmNlc1Jlc3BvbnNl
IoUBgtPkkwJrEjUvdjEve3Njb3BlPW9yZ2FuaXphdGlvbnMvKn0vcHJvdGVjdGVkUmVzb3Vy
Y2VzOnNlYXJjaFoyEjAvdjEve3Njb3BlPXByb2plY3RzLyp9L3Byb3RlY3RlZFJlc291cmNl
czpzZWFyY2jaQRFzY29wZSwgY3J5cHRvX2tleRpPykEba21zaW52ZW50b3J5Lmdvb2dsZWFw
aXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bULXAgohY29tLmdvb2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYxQhdLZXlUcmFja2luZ1Nl
cnZpY2VQcm90b1ABWj9jbG91ZC5nb29nbGUuY29tL2dvL2ttcy9pbnZlbnRvcnkvYXBpdjEv
aW52ZW50b3J5cGI7aW52ZW50b3J5cGKqAh1Hb29nbGUuQ2xvdWQuS21zLkludmVudG9yeS5W
McoCHUdvb2dsZVxDbG91ZFxLbXNcSW52ZW50b3J5XFYx6kGUAQoya21zaW52ZW50b3J5Lmdv
b2dsZWFwaXMuY29tL1Byb3RlY3RlZFJlc291cmNlU2NvcGUSM29yZ2FuaXphdGlvbnMve29y
Z2FuaXphdGlvbn0vcHJvdGVjdGVkUmVzb3VyY2VTY29wZRIpcHJvamVjdHMve3Byb2plY3R9
L3Byb3RlY3RlZFJlc291cmNlU2NvcGVK7VYKBxIFDgCwAgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgApCggKAQgSAxgAOgoJCgIIJRIDGAA6CggKAQgS
AxkAVgoJCgIICxIDGQBWCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAOAoJCgIICBID
GwA4CggKAQgSAxwAOgoJCgIIARIDHAA6CggKAQgSAx0AOwoJCgIIKRIDHQA7CgkKAQgSBB4A
IgIKDAoECJ0IABIEHgAiAgp2CgIGABIEJgBLARpqIFJldHVybnMgaW5mb3JtYXRpb24gYWJv
dXQgdGhlIHJlc291cmNlcyBpbiBhbiBvcmcgdGhhdCBhcmUgcHJvdGVjdGVkIGJ5IGEKIGdp
dmVuIENsb3VkIEtNUyBrZXkgdmlhIENNRUsuCgoKCgMGAAESAyYIGgoKCgMGAAMSAycCQwoM
CgUGAAOZCBIDJwJDCgsKAwYAAxIEKAIpNwoNCgUGAAOaCBIEKAIpNwrBBQoEBgACABIENgI8
AxqyBSBSZXR1cm5zIGFnZ3JlZ2F0ZSBpbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVzb3VyY2Vz
IHByb3RlY3RlZCBieSB0aGUgZ2l2ZW4KIENsb3VkIEtNUyBbQ3J5cHRvS2V5XVtnb29nbGUu
Y2xvdWQua21zLnYxLkNyeXB0b0tleV0uIEJ5IGRlZmF1bHQsCiBzdW1tYXJ5IG9mIHJlc291
cmNlcyB3aXRoaW4gdGhlIHNhbWUgQ2xvdWQgb3JnYW5pemF0aW9uIGFzIHRoZSBrZXkgd2ls
bCBiZQogcmV0dXJuZWQsIHdoaWNoIHJlcXVpcmVzIHRoZSBLTVMgb3JnYW5pemF0aW9uIHNl
cnZpY2UgYWNjb3VudCB0byBiZQogY29uZmlndXJlZChyZWZlcgogaHR0cHM6Ly9kb2NzLmNs
b3VkLmdvb2dsZS5jb20va21zL2RvY3Mvdmlldy1rZXktdXNhZ2UjcmVxdWlyZWQtcm9sZXMp
LgogSWYgdGhlIEtNUyBvcmdhbml6YXRpb24gc2VydmljZSBhY2NvdW50IGlzIG5vdCBjb25m
aWd1cmVkIG9yIGtleSdzIHByb2plY3QKIGlzIG5vdCBwYXJ0IG9mIGFuIG9yZ2FuaXphdGlv
biwgc2V0CiBbZmFsbGJhY2tfc2NvcGVdW2dvb2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYx
LkdldFByb3RlY3RlZFJlc291cmNlc1N1bW1hcnlSZXF1ZXN0LmZhbGxiYWNrX3Njb3BlXQog
dG8gYEZBTExCQUNLX1NDT1BFX1BST0pFQ1RgIHRvIHJldHJpZXZlIGEgc3VtbWFyeSBvZiBw
cm90ZWN0ZWQgcmVzb3VyY2VzCiB3aXRoaW4gdGhlIGtleSdzIHByb2plY3QuCgoMCgUGAAIA
ARIDNgYiCgwKBQYAAgACEgM2I0YKDAoFBgACAAMSAzcPKAoNCgUGAAIABBIEOAQ6BgoRCgkG
AAIABLDKvCISBDgEOgYKDAoFBgACAAQSAzsEMgoPCggGAAIABJsIABIDOwQyCqwBCgQGAAIB
EgRBAkoDGp0BIFJldHVybnMgbWV0YWRhdGEgYWJvdXQgdGhlIHJlc291cmNlcyBwcm90ZWN0
ZWQgYnkgdGhlIGdpdmVuIENsb3VkIEtNUwogW0NyeXB0b0tleV1bZ29vZ2xlLmNsb3VkLmtt
cy52MS5DcnlwdG9LZXldIGluIHRoZSBnaXZlbiBDbG91ZAogb3JnYW5pemF0aW9uL3Byb2pl
Y3QuCgoMCgUGAAIBARIDQQYeCgwKBQYAAgECEgNBHz4KDAoFBgACAQMSA0IPLwoNCgUGAAIB
BBIEQwRIBgoRCgkGAAIBBLDKvCISBEMESAYKDAoFBgACAQQSA0kEPwoPCggGAAIBBJsIABID
SQQ/CqUBCgIEABIETwBcARqYASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbS2V5VHJhY2tpbmdT
ZXJ2aWNlLkdldFByb3RlY3RlZFJlc291cmNlc1N1bW1hcnldW2dvb2dsZS5jbG91ZC5rbXMu
aW52ZW50b3J5LnYxLktleVRyYWNraW5nU2VydmljZS5HZXRQcm90ZWN0ZWRSZXNvdXJjZXNT
dW1tYXJ5XS4KCgoKAwQAARIDTwgrCl8KBAQAAgASBFICVwQaUSBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlCiBbQ3J5cHRvS2V5XVtnb29nbGUuY2xvdWQua21zLnYxLkNy
eXB0b0tleV0uCgoMCgUEAAIABRIDUgIICgwKBQQAAgABEgNSCQ0KDAoFBAACAAMSA1IQEQoN
CgUEAAIACBIEUhJXAwoPCggEAAIACJwIABIDUwQqCg8KBwQAAgAInwgSBFQEVgUKZQoEBAAC
ARIDWwJMGlggT3B0aW9uYWwuIFRoZSBzY29wZSB0byB1c2UgaWYgdGhlIGttcyBvcmdhbml6
YXRpb24gc2VydmljZSBhY2NvdW50IGlzIG5vdAogY29uZmlndXJlZC4KCgwKBQQAAgEGEgNb
Ag8KDAoFBAACAQESA1sQHgoMCgUEAAIBAxIDWyEiCgwKBQQAAgEIEgNbI0sKDwoIBAACAQic
CAASA1skSgqJAQoCBAESBWAAggEBGnwgQWdncmVnYXRlIGluZm9ybWF0aW9uIGFib3V0IHRo
ZSByZXNvdXJjZXMgcHJvdGVjdGVkIGJ5IGEgQ2xvdWQgS01TIGtleSBpbiB0aGUKIHNhbWUg
Q2xvdWQgb3JnYW5pemF0aW9uL3Byb2plY3QgYXMgdGhlIGtleS4KCgoKAwQBARIDYAghCgsK
AwQBBxIEYQJlBAoNCgUEAQedCBIEYQJlBAq6AQoEBAECABIDagISGqwBIFRoZSBmdWxsIG5h
bWUgb2YgdGhlIFByb3RlY3RlZFJlc291cmNlc1N1bW1hcnkgcmVzb3VyY2UuCiBFeGFtcGxl
OgogcHJvamVjdHMvdGVzdC1wcm9qZWN0L2xvY2F0aW9ucy91cy9rZXlSaW5ncy90ZXN0LWtl
eXJpbmcvY3J5cHRvS2V5cy90ZXN0LWtleS9wcm90ZWN0ZWRSZXNvdXJjZXNTdW1tYXJ5CgoM
CgUEAQIABRIDagIICgwKBQQBAgABEgNqCQ0KDAoFBAECAAMSA2oQEQpiCgQEAQIBEgNuAhsa
VSBUaGUgdG90YWwgbnVtYmVyIG9mIHByb3RlY3RlZCByZXNvdXJjZXMgaW4gdGhlIHNhbWUg
Q2xvdWQgb3JnYW5pemF0aW9uIGFzCiB0aGUga2V5LgoKDAoFBAECAQUSA24CBwoMCgUEAQIB
ARIDbggWCgwKBQQBAgEDEgNuGRoKiQEKBAQBAgISA3ICGhp8IFRoZSBudW1iZXIgb2YgZGlz
dGluY3QgQ2xvdWQgcHJvamVjdHMgaW4gdGhlIHNhbWUgQ2xvdWQgb3JnYW5pemF0aW9uIGFz
IHRoZQoga2V5IHRoYXQgaGF2ZSByZXNvdXJjZXMgcHJvdGVjdGVkIGJ5IHRoZSBrZXkuCgoM
CgUEAQICBRIDcgIHCgwKBQQBAgIBEgNyCBUKDAoFBAECAgMSA3IYGQpVCgQEAQIDEgN1Aiga
SCBUaGUgbnVtYmVyIG9mIHJlc291cmNlcyBwcm90ZWN0ZWQgYnkgdGhlIGtleSBncm91cGVk
IGJ5IHJlc291cmNlIHR5cGUuCgoMCgUEAQIDBhIDdQIUCgwKBQQBAgMBEgN1FSMKDAoFBAEC
AwMSA3UmJwpVCgQEAQIEEgN4AigaSCBUaGUgbnVtYmVyIG9mIHJlc291cmNlcyBwcm90ZWN0
ZWQgYnkgdGhlIGtleSBncm91cGVkIGJ5IENsb3VkIHByb2R1Y3QuCgoMCgUEAQIEBhIDeAIU
CgwKBQQBAgQBEgN4FSMKDAoFBAECBAMSA3gmJwpOCgQEAQIFEgN7AiMaQSBUaGUgbnVtYmVy
IG9mIHJlc291cmNlcyBwcm90ZWN0ZWQgYnkgdGhlIGtleSBncm91cGVkIGJ5IHJlZ2lvbi4K
CgwKBQQBAgUGEgN7AhQKDAoFBAECBQESA3sVHgoMCgUEAQIFAxIDeyEiCpcCCgQEAQIGEgSB
AQIgGogCIFdhcm5pbmcgbWVzc2FnZXMgZm9yIHRoZSBzdGF0ZSBvZiByZXNwb25zZQogW1By
b3RlY3RlZFJlc291cmNlc1N1bW1hcnldW2dvb2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYx
LlByb3RlY3RlZFJlc291cmNlc1N1bW1hcnldCiBGb3IgZXhhbXBsZSwgaWYgdGhlIG9yZ2Fu
aXphdGlvbiBzZXJ2aWNlIGFjY291bnQgaXMgbm90IGNvbmZpZ3VyZWQsCiBJTlNVRkZJQ0lF
TlRfUEVSTUlTU0lPTlNfUEFSVElBTF9EQVRBIHdhcm5pbmcgd2lsbCBiZSByZXR1cm5lZC4K
Cg0KBQQBAgYEEgSBAQIKCg0KBQQBAgYGEgSBAQsSCg0KBQQBAgYBEgSBARMbCg0KBQQBAgYD
EgSBAR4fCp8BCgIEAhIGhgEAuwEBGpABIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtLZXlUcmFj
a2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVkUmVzb3VyY2VzXVtnb29nbGUuY2xvdWQua21z
LmludmVudG9yeS52MS5LZXlUcmFja2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVkUmVzb3Vy
Y2VzXS4KCgsKAwQCARIEhgEIJwruAgoEBAICABIGjwEClAEEGt0CIFJlcXVpcmVkLiBBIHNj
b3BlIGNhbiBiZSBhbiBvcmdhbml6YXRpb24gb3IgYSBwcm9qZWN0LiBSZXNvdXJjZXMgcHJv
dGVjdGVkCiBieSB0aGUgY3J5cHRvIGtleSBpbiBwcm92aWRlZCBzY29wZSB3aWxsIGJlIHJl
dHVybmVkLgoKIFRoZSBmb2xsb3dpbmcgdmFsdWVzIGFyZSBhbGxvd2VkOgoKICogb3JnYW5p
emF0aW9ucy97T1JHQU5JWkFUSU9OX05VTUJFUn0gKGUuZy4sICJvcmdhbml6YXRpb25zLzEy
MzQ1Njc4IikKICogcHJvamVjdHMve1BST0pFQ1RfSUR9IChlLmcuLCAicHJvamVjdHMvZm9v
LWJhciIpCiAqIHByb2plY3RzL3tQUk9KRUNUX05VTUJFUn0gKGUuZy4sICJwcm9qZWN0cy8x
MjM0NTY3OCIpCgoNCgUEAgIABRIEjwECCAoNCgUEAgIAARIEjwEJDgoNCgUEAgIAAxIEjwER
EgoPCgUEAgIACBIGjwETlAEDChAKCAQCAgAInAgAEgSQAQQqChEKBwQCAgAInwgSBpEBBJMB
BQphCgQEAgIBEgaYAQKbAQQaUSBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
CiBbQ3J5cHRvS2V5XVtnb29nbGUuY2xvdWQua21zLnYxLkNyeXB0b0tleV0uCgoNCgUEAgIB
BRIEmAECCAoNCgUEAgIBARIEmAEJEwoNCgUEAgIBAxIEmAEWFwoPCgUEAgIBCBIGmAEYmwED
ChAKCAQCAgEInAgAEgSZAQQqCg8KBwQCAgEInwgSBJoBBDMK5wEKBAQCAgISBKEBAhYa2AEg
VGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc291cmNlcyB0byByZXR1cm4uIFRoZSBzZXJ2aWNl
IG1heSByZXR1cm4gZmV3ZXIKIHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVuc3BlY2lmaWVkLCBh
dCBtb3N0IDUwMCByZXNvdXJjZXMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZh
bHVlIGlzIDUwMDsgdmFsdWVzIGFib3ZlIDUwMCB3aWxsIGJlIGNvZXJjZWQgdG8gNTAwLgoK
DQoFBAICAgUSBKEBAgcKDQoFBAICAgESBKEBCBEKDQoFBAICAgMSBKEBFBUKxwMKBAQCAgMS
BKoBAhgauAMgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIFtLZXlU
cmFja2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVkUmVzb3VyY2VzXVtnb29nbGUuY2xvdWQu
a21zLmludmVudG9yeS52MS5LZXlUcmFja2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVkUmVz
b3VyY2VzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50
IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRl
ZCB0bwogW0tleVRyYWNraW5nU2VydmljZS5TZWFyY2hQcm90ZWN0ZWRSZXNvdXJjZXNdW2dv
b2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYxLktleVRyYWNraW5nU2VydmljZS5TZWFyY2hQ
cm90ZWN0ZWRSZXNvdXJjZXNdCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlIHBhZ2UgdG9rZW4uCgoNCgUEAgIDBRIEqgECCAoNCgUEAgIDARIEqgEJEwoNCgUEAgID
AxIEqgEWFwrOBQoEBAICBBIEugECThq/BSBPcHRpb25hbC4gQSBsaXN0IG9mIHJlc291cmNl
IHR5cGVzIHRoYXQgdGhpcyByZXF1ZXN0IHNlYXJjaGVzIGZvci4gSWYKIGVtcHR5LCBpdCB3
aWxsIHNlYXJjaCBhbGwgdGhlIFt0cmFja2FibGUgcmVzb3VyY2UKIHR5cGVzXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20va21zL2RvY3Mvdmlldy1rZXktdXNhZ2UjdHJhY2tlZC1yZXNv
dXJjZS10eXBlcykuCgogUmVndWxhciBleHByZXNzaW9ucyBhcmUgYWxzbyBzdXBwb3J0ZWQu
IEZvciBleGFtcGxlOgoKICogYGNvbXB1dGUuZ29vZ2xlYXBpcy5jb20uKmAgc25hcHNob3Rz
IHJlc291cmNlcyB3aG9zZSB0eXBlIHN0YXJ0cwogd2l0aCBgY29tcHV0ZS5nb29nbGVhcGlz
LmNvbWAuCiAqIGAuKkltYWdlYCBzbmFwc2hvdHMgcmVzb3VyY2VzIHdob3NlIHR5cGUgZW5k
cyB3aXRoIGBJbWFnZWAuCiAqIGAuKkltYWdlLipgIHNuYXBzaG90cyByZXNvdXJjZXMgd2hv
c2UgdHlwZSBjb250YWlucyBgSW1hZ2VgLgoKIFNlZSBbUkUyXShodHRwczovL2dpdGh1Yi5j
b20vZ29vZ2xlL3JlMi93aWtpL1N5bnRheCkgZm9yIGFsbCBzdXBwb3J0ZWQKIHJlZ3VsYXIg
ZXhwcmVzc2lvbiBzeW50YXguIElmIHRoZSByZWd1bGFyIGV4cHJlc3Npb24gZG9lcyBub3Qg
bWF0Y2ggYW55CiBzdXBwb3J0ZWQgcmVzb3VyY2UgdHlwZSwgYW4gSU5WQUxJRF9BUkdVTUVO
VCBlcnJvciB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAICBAQSBLoBAgoKDQoFBAICBAUSBLoB
CxEKDQoFBAICBAESBLoBEiAKDQoFBAICBAMSBLoBIyQKDQoFBAICBAgSBLoBJU0KEAoIBAIC
BAicCAASBLoBJkwKoAEKAgQDEga/AQDGAQEakQEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtL
ZXlUcmFja2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVkUmVzb3VyY2VzXVtnb29nbGUuY2xv
dWQua21zLmludmVudG9yeS52MS5LZXlUcmFja2luZ1NlcnZpY2UuU2VhcmNoUHJvdGVjdGVk
UmVzb3VyY2VzXS4KCgsKAwQDARIEvwEIKAoyCgQEAwIAEgTBAQI1GiQgUHJvdGVjdGVkIHJl
c291cmNlcyBmb3IgdGhpcyBwYWdlLgoKDQoFBAMCAAQSBMEBAgoKDQoFBAMCAAYSBMEBCxwK
DQoFBAMCAAESBMEBHTAKDQoFBAMCAAMSBMEBMzQKjQEKBAQDAgESBMUBAh0afyBBIHRva2Vu
IHRoYXQgY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1
ZW50IHBhZ2VzLgoKDQoFBAMCAQUSBMUBAggKDQoFBAMCAQESBMUBCRgKDQoFBAMCAQMSBMUB
GxwKRwoCBAQSBskBAIECARo5IE1ldGFkYXRhIGFib3V0IGEgcmVzb3VyY2UgcHJvdGVjdGVk
IGJ5IGEgQ2xvdWQgS01TIGtleS4KCgsKAwQEARIEyQEIGQoNCgMEBAcSBsoBAs0BBAoPCgUE
BAedCBIGygECzQEECpcBCgQEBAIAEgTSAQISGogBIFRoZSBmdWxsIHJlc291cmNlIG5hbWUg
b2YgdGhlIHJlc291cmNlLgogRXhhbXBsZToKIGAvL2NvbXB1dGUuZ29vZ2xlYXBpcy5jb20v
cHJvamVjdHMvbXlfcHJvamVjdF8xMjMvem9uZXMvem9uZTEvaW5zdGFuY2VzL2luc3RhbmNl
MWAuCgoNCgUEBAIABRIE0gECCAoNCgUEBAIAARIE0gEJDQoNCgUEBAIAAxIE0gEQEQo0CgQE
BAIBEgTVAQIVGiYgRm9ybWF0OiBgcHJvamVjdHMve1BST0pFQ1RfTlVNQkVSfWAuCgoNCgUE
BAIBBRIE1QECCAoNCgUEBAIBARIE1QEJEAoNCgUEBAIBAxIE1QETFAo9CgQEBAICEgTYAQIY
Gi8gVGhlIElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgb3ducyB0aGUgcmVzb3VyY2UuCgoNCgUE
BAICBRIE2AECCAoNCgUEBAICARIE2AEJEwoNCgUEBAICAxIE2AEWFwpNCgQEBAIDEgTcAQIb
Gj8gVGhlIENsb3VkIHByb2R1Y3QgdGhhdCBvd25zIHRoZSByZXNvdXJjZS4KIEV4YW1wbGU6
IGBjb21wdXRlYAoKDQoFBAQCAwUSBNwBAggKDQoFBAQCAwESBNwBCRYKDQoFBAQCAwMSBNwB
GRoKNgoEBAQCBBIE3wECGxooIEV4YW1wbGU6IGBjb21wdXRlLmdvb2dsZWFwaXMuY29tL0Rp
c2tgCgoNCgUEBAIEBRIE3wECCAoNCgUEBAIEARIE3wEJFgoNCgUEBAIEAxIE3wEZGgpgCgQE
BAIFEgTjAQIWGlIgTG9jYXRpb24gY2FuIGJlIGBnbG9iYWxgLCByZWdpb25hbCBsaWtlIGB1
cy1lYXN0MWAsIG9yIHpvbmFsIGxpa2UKIGB1cy13ZXN0MS1iYC4KCg0KBQQEAgUFEgTjAQII
Cg0KBQQEAgUBEgTjAQkRCg0KBQQEAgUDEgTjARQVCk8KBAQEAgYSBOYBAiEaQSBBIGtleS12
YWx1ZSBwYWlyIG9mIHRoZSByZXNvdXJjZSdzIGxhYmVscyAodjEpIHRvIHRoZWlyIHZhbHVl
cy4KCg0KBQQEAgYGEgTmAQIVCg0KBQQEAgYBEgTmARYcCg0KBQQEAgYDEgTmAR8gCtwDCgQE
BAIHEgbvAQLxAQUaywMgVGhlIG5hbWUgb2YgdGhlIENsb3VkIEtNUwogW0NyeXB0b0tleVZl
cnNpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9rbXMvZG9jcy9yZWZlcmVuY2UvcmVz
dC92MS9wcm9qZWN0cy5sb2NhdGlvbnMua2V5UmluZ3MuY3J5cHRvS2V5cy5jcnlwdG9LZXlW
ZXJzaW9ucz9obD1lbikKIHVzZWQgdG8gcHJvdGVjdCB0aGlzIHJlc291cmNlIHZpYSBDTUVL
LiBUaGlzIGZpZWxkIGlzIGVtcHR5IGlmIHRoZQogR29vZ2xlIENsb3VkIHByb2R1Y3Qgb3du
aW5nIHRoZSByZXNvdXJjZSBkb2VzIG5vdCBwcm92aWRlIGtleSB2ZXJzaW9uIGRhdGEKIHRv
IEFzc2V0IEludmVudG9yeS4gSWYgdGhlcmUgYXJlIG11bHRpcGxlIGtleSB2ZXJzaW9ucyBw
cm90ZWN0aW5nIHRoZQogcmVzb3VyY2UsIHRoZW4gdGhpcyBpcyBzYW1lIHZhbHVlIGFzIHRo
ZSBmaXJzdCBlbGVtZW50IG9mCiBjcnlwdG9fa2V5X3ZlcnNpb25zLgoKDQoFBAQCBwUSBO8B
AggKDQoFBAQCBwESBO8BCRsKDQoFBAQCBwMSBO8BHh8KDwoFBAQCBwgSBu8BIPEBBAoRCgcE
BAIHCJ8IEgbvASHxAQMKnQMKBAQEAggSBvkBAvsBBRqMAyBUaGUgbmFtZXMgb2YgdGhlIENs
b3VkIEtNUwogW0NyeXB0b0tleVZlcnNpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9r
bXMvZG9jcy9yZWZlcmVuY2UvcmVzdC92MS9wcm9qZWN0cy5sb2NhdGlvbnMua2V5UmluZ3Mu
Y3J5cHRvS2V5cy5jcnlwdG9LZXlWZXJzaW9ucz9obD1lbikKIHVzZWQgdG8gcHJvdGVjdCB0
aGlzIHJlc291cmNlIHZpYSBDTUVLLiBUaGlzIGZpZWxkIGlzIGVtcHR5IGlmIHRoZQogR29v
Z2xlIENsb3VkIHByb2R1Y3Qgb3duaW5nIHRoZSByZXNvdXJjZSBkb2VzIG5vdCBwcm92aWRl
IGtleSB2ZXJzaW9ucyBkYXRhCiB0byBBc3NldCBJbnZlbnRvcnkuIFRoZSBmaXJzdCBlbGVt
ZW50IG9mIHRoaXMgZmllbGQgaXMgc3RvcmVkIGluCiBjcnlwdG9fa2V5X3ZlcnNpb24uCgoN
CgUEBAIIBBIE+QECCgoNCgUEBAIIBRIE+QELEQoNCgUEBAIIARIE+QESJQoNCgUEBAIIAxIE
+QEoKgoPCgUEBAIICBIG+QEr+wEEChEKBwQEAggInwgSBvkBLPsBAwqNAQoEBAQCCRIG/wEC
gAIyGn0gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoaXMgcmVzb3VyY2Ugd2Fz
IGNyZWF0ZWQuIFRoZSBncmFudWxhcml0eQogaXMgaW4gc2Vjb25kcy4gVGltZXN0YW1wLm5h
bm9zIHdpbGwgYWx3YXlzIGJlIDAuCgoNCgUEBAIJBhIE/wECGwoNCgUEBAIJARIE/wEcJwoN
CgUEBAIJAxIE/wEqKwoNCgUEBAIJCBIEgAIGMQoQCggEBAIJCJwIABIEgAIHMApbCgIEBRIG
hAIApAIBGk0gQSB3YXJuaW5nIG1lc3NhZ2UgdGhhdCBpbmRpY2F0ZXMgcG90ZW50aWFsIHBy
b2JsZW1zIHdpdGggdGhlIHJlc3BvbnNlIGRhdGEuCgoLCgMEBQESBIQCCA8KoAEKBAQFBAAS
BogCAp0CAxqPASBEaWZmZXJlbnQgdHlwZXMgb2Ygd2FybmluZ3MgdGhhdCBjYW4gYmUgcmV0
dXJuZWQgdG8gdGhlIHVzZXIuCiBUaGUgZGlzcGxheV9tZXNzYWdlIGNvbnRhaW5zIGRldGFp
bGVkIGluZm9ybWF0aW9uIHJlZ2FyZGluZyB0aGUKIHdhcm5pbmdfY29kZS4KCg0KBQQFBAAB
EgSIAgcSCjYKBgQFBAACABIEigIEIRomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMg
dW51c2VkLgoKDwoHBAUEAAIAARIEigIEHAoPCgcEBQQAAgACEgSKAh8gCqkCCgYEBQQAAgES
BJECBC4amAIgSW5kaWNhdGVzIHRoYXQgdGhlIGNhbGxlciBvciBzZXJ2aWNlIGFnZW50IGxh
Y2tzIG5lY2Vzc2FyeSBwZXJtaXNzaW9ucwogdG8gdmlldyBzb21lIG9mIHRoZSByZXF1ZXN0
ZWQgZGF0YS4gVGhlIHJlc3BvbnNlIG1heSBiZSBwYXJ0aWFsLgogRXhhbXBsZToKIC0gS01T
IG9yZ2FuaXphdGlvbiBzZXJ2aWNlIGFnZW50IHtzZXJ2aWNlX2FnZW50X25hbWV9IGxhY2tz
IHRoZQogICBgY2xvdWRhc3NldC5hc3NldHMuc2VhcmNoQWxsUmVzb3VyY2VzYCBwZXJtaXNz
aW9uIG9uIHRoZSBzY29wZS4KCg8KBwQFBAACAQESBJECBCkKDwoHBAUEAAIBAhIEkQIsLQrS
AQoGBAUEAAICEgSXAgQtGsEBIEluZGljYXRlcyB0aGF0IGEgcmVzb3VyY2UgbGltaXQgaGFz
IGJlZW4gZXhjZWVkZWQsIHJlc3VsdGluZyBpbiBwYXJ0aWFsCiBkYXRhLiBFeGFtcGxlOgog
LSBUaGUgcHJvamVjdCBoYXMgbW9yZSB0aGFuIDEwLDAwMCBhc3NldHMgKHJlc291cmNlcywK
ICAgY3J5cHRvIGtleXMsIGtleSBoYW5kbGVzLCBJQU0gcG9saWNpZXMsIGV0YykuCgoPCgcE
BQQAAgIBEgSXAgQoCg8KBwQFBAACAgISBJcCKywKswEKBgQFBAACAxIEnAIEJhqiASBJbmRp
Y2F0ZXMgdGhhdCB0aGUgcHJvamVjdCBleGlzdHMgb3V0c2lkZSBvZiBhbiBvcmdhbml6YXRp
b24gcmVzb3VyY2UuCiBUaHVzIHRoZSBhbmFseXNpcyBpcyBvbmx5IGRvbmUgZm9yIHRoZSBw
cm9qZWN0IGxldmVsIGRhdGEgYW5kIHJlc3VsdHMKIG1pZ2h0IGJlIHBhcnRpYWwuCgoPCgcE
BQQAAgMBEgScAgQhCg8KBwQFBAACAwISBJwCJCUKRAoEBAUCABIEoAICHxo2IFRoZSBzcGVj
aWZpYyB3YXJuaW5nIGNvZGUgZm9yIHRoZSBkaXNwbGF5ZWQgbWVzc2FnZS4KCg0KBQQFAgAG
EgSgAgINCg0KBQQFAgABEgSgAg4aCg0KBQQFAgADEgSgAh0eClUKBAQFAgESBKMCAh0aRyBU
aGUgbGl0ZXJhbCBtZXNzYWdlIHByb3ZpZGluZyBjb250ZXh0IGFuZCBkZXRhaWxzIGFib3V0
IHRoZSB3YXJuaW5ncy4KCg0KBQQFAgEFEgSjAgIICg0KBQQFAgEBEgSjAgkYCg0KBQQFAgED
EgSjAhscCmAKAgUAEgaoAgCwAgEaUiBTcGVjaWZpZXMgdGhlIHNjb3BlIHRvIHVzZSBpZiB0
aGUgb3JnYW5pemF0aW9uIHNlcnZpY2UgYWdlbnQgaXMgbm90CiBjb25maWd1cmVkLgoKCwoD
BQABEgSoAgUSCicKBAUAAgASBKoCAiEaGSBVbnNwZWNpZmllZCBzY29wZSB0eXBlLgoKDQoF
BQACAAESBKoCAhwKDQoFBQACAAISBKoCHyAKsAEKBAUAAgESBK8CAh0aoQEgSWYgc2V0IHRv
IGBGQUxMQkFDS19TQ09QRV9QUk9KRUNUYCwgdGhlIEFQSSB3aWxsIGZhbGwgYmFjayB0byB1
c2luZyBrZXkncwogcHJvamVjdCBhcyByZXF1ZXN0IHNjb3BlIGlmIHRoZSBrbXMgb3JnYW5p
emF0aW9uIHNlcnZpY2UgYWNjb3VudCBpcyBub3QKIGNvbmZpZ3VyZWQuCgoNCgUFAAIBARIE
rwICGAoNCgUFAAIBAhIErwIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest ===
    # Fields for GetProtectedResourcesSummaryRequest
    # Field: name Type: 9 ()
    # Field: fallback_scope Type: 14 (.google.cloud.kms.inventory.v1.FallbackScope)

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary ===
    # Fields for ProtectedResourcesSummary
    # Field: name Type: 9 ()
    # Field: resource_count Type: 3 ()
    # Field: project_count Type: 5 ()
    # Field: resource_types Type: 11 (.google.cloud.kms.inventory.v1.ProtectedResourcesSummary.ResourceTypesEntry)
    # Field: cloud_products Type: 11 (.google.cloud.kms.inventory.v1.ProtectedResourcesSummary.CloudProductsEntry)
    # Field: locations Type: 11 (.google.cloud.kms.inventory.v1.ProtectedResourcesSummary.LocationsEntry)
    # Field: warnings Type: 11 (.google.cloud.kms.inventory.v1.Warning)

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest ===
    # Fields for SearchProtectedResourcesRequest
    # Field: scope Type: 9 ()
    # Field: crypto_key Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: resource_types Type: 9 ()

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse ===
    # Fields for SearchProtectedResourcesResponse
    # Field: protected_resources Type: 11 (.google.cloud.kms.inventory.v1.ProtectedResource)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource ===
    # Fields for ProtectedResource
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: cloud_product Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: location Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.kms.inventory.v1.ProtectedResource.LabelsEntry)
    # Field: crypto_key_version Type: 9 ()
    # Field: crypto_key_versions Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning ===
    # Fields for Warning
    # Field: warning_code Type: 14 (.google.cloud.kms.inventory.v1.Warning.WarningCode)
    # Field: display_message Type: 9 ()

# Enum: Warning::WarningCode
our $Warning_WARNING_CODE_UNSPECIFIED = 0;
our $Warning_INSUFFICIENT_PERMISSIONS_PARTIAL_DATA = 1;
our $Warning_RESOURCE_LIMIT_EXCEEDED_PARTIAL_DATA = 2;
our $Warning_ORG_LESS_PROJECT_PARTIAL_DATA = 3;

# === Service Client: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::KeyTrackingServiceClient ===
package Google::Cloud::Kms::Inventory::V1::KeyTrackingService::KeyTrackingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Kms::Inventory::V1::KeyTrackingService::KeyTrackingServiceClient

Client stub representing the remote C<KeyTrackingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<kms.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'kms.googleapis.com:443' );

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

sub get_protected_resources_summary {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.inventory.v1.KeyTrackingService',
        method         => 'GetProtectedResourcesSummary',
        request        => $req,
        response_class => 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary',
    });
}

sub search_protected_resources {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.inventory.v1.KeyTrackingService',
        method         => 'SearchProtectedResources',
        request        => $req,
        response_class => 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Kms::Inventory::V1::KeyTrackingService - Compiled Protocol Buffers messages for google/cloud/kms/inventory/v1/key_tracking_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Kms::Inventory::V1::KeyTrackingService;

    my $msg = Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest->new({
        name => $name,
        fallback_scope => $fallback_scope,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/kms/inventory/v1/key_tracking_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest

Request message for
[KeyTrackingService.GetProtectedResourcesSummary][google.cloud.kms.inventory.v1.KeyTrackingService.GetProtectedResourcesSummary].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[CryptoKey][google.cloud.kms.v1.CryptoKey].

=item * C<< $msg->fallback_scope() >> / C<< $msg->fallback_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Kms::Inventory::V1::FallbackScope>)

Optional. The scope to use if the kms organization service account is not
configured.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary

Aggregate information about the resources protected by a Cloud KMS key in the
same Cloud organization/project as the key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full name of the ProtectedResourcesSummary resource.
Example:
projects/test-project/locations/us/keyRings/test-keyring/cryptoKeys/test-key/protectedResourcesSummary

=item * C<< $msg->resource_count() >> / C<< $msg->resource_count($value) >>

Type: C<Int64>

The total number of protected resources in the same Cloud organization as
the key.

=item * C<< $msg->project_count() >> / C<< $msg->project_count($value) >>

Type: C<Int32>

The number of distinct Cloud projects in the same Cloud organization as the
key that have resources protected by the key.

=item * C<< $msg->resource_types() >> / C<< $msg->resource_types($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::ResourceTypesEntry>)

The number of resources protected by the key grouped by resource type.

=item * C<< $msg->cloud_products() >> / C<< $msg->cloud_products($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::CloudProductsEntry>)

The number of resources protected by the key grouped by Cloud product.

=item * C<< $msg->locations() >> / C<< $msg->locations($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::LocationsEntry>)

The number of resources protected by the key grouped by region.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning>)

Warning messages for the state of response
[ProtectedResourcesSummary][google.cloud.kms.inventory.v1.ProtectedResourcesSummary]
For example, if the organization service account is not configured,
INSUFFICIENT_PERMISSIONS_PARTIAL_DATA warning will be returned.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest

Request message for
[KeyTrackingService.SearchProtectedResources][google.cloud.kms.inventory.v1.KeyTrackingService.SearchProtectedResources].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Required. A scope can be an organization or a project. Resources protected
by the crypto key in provided scope will be returned.

The following values are allowed:

* organizations/{ORGANIZATION_NUMBER} (e.g., "organizations/12345678")
* projects/{PROJECT_ID} (e.g., "projects/foo-bar")
* projects/{PROJECT_NUMBER} (e.g., "projects/12345678")

=item * C<< $msg->crypto_key() >> / C<< $msg->crypto_key($value) >>

Type: C<String>

Required. The resource name of the
[CryptoKey][google.cloud.kms.v1.CryptoKey].

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of resources to return. The service may return fewer
than this value.
If unspecified, at most 500 resources will be returned.
The maximum value is 500; values above 500 will be coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous
[KeyTrackingService.SearchProtectedResources][google.cloud.kms.inventory.v1.KeyTrackingService.SearchProtectedResources]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[KeyTrackingService.SearchProtectedResources][google.cloud.kms.inventory.v1.KeyTrackingService.SearchProtectedResources]
must match the call that provided the page token.

=item * C<< $msg->resource_types() >> / C<< $msg->resource_types($value) >>

Type: C<String>

Optional. A list of resource types that this request searches for. If
empty, it will search all the [trackable resource
types](https://cloud.google.com/kms/docs/view-key-usage#tracked-resource-types).

Regular expressions are also supported. For example:

* `compute.googleapis.com.*` snapshots resources whose type starts
with `compute.googleapis.com`.
* `.*Image` snapshots resources whose type ends with `Image`.
* `.*Image.*` snapshots resources whose type contains `Image`.

See [RE2](https://github.com/google/re2/wiki/Syntax) for all supported
regular expression syntax. If the regular expression does not match any
supported resource type, an INVALID_ARGUMENT error will be returned.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse

Response message for
[KeyTrackingService.SearchProtectedResources][google.cloud.kms.inventory.v1.KeyTrackingService.SearchProtectedResources].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->protected_resources() >> / C<< $msg->protected_resources($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource>)

Protected resources for this page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource

Metadata about a resource protected by a Cloud KMS key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full resource name of the resource.
Example:
`//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Format: `projects/{PROJECT_NUMBER}`.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project that owns the resource.

=item * C<< $msg->cloud_product() >> / C<< $msg->cloud_product($value) >>

Type: C<String>

The Cloud product that owns the resource.
Example: `compute`

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Example: `compute.googleapis.com/Disk`

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Location can be `global`, regional like `us-east1`, or zonal like
`us-west1-b`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource::LabelsEntry>)

A key-value pair of the resource's labels (v1) to their values.

=item * C<< $msg->crypto_key_version() >> / C<< $msg->crypto_key_version($value) >>

Type: C<String>

The name of the Cloud KMS
[CryptoKeyVersion](https://cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys.cryptoKeyVersions?hl=en)
used to protect this resource via CMEK. This field is empty if the
Google Cloud product owning the resource does not provide key version data
to Asset Inventory. If there are multiple key versions protecting the
resource, then this is same value as the first element of
crypto_key_versions.

=item * C<< $msg->crypto_key_versions() >> / C<< $msg->crypto_key_versions($value) >>

Type: C<String>

The names of the Cloud KMS
[CryptoKeyVersion](https://cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys.cryptoKeyVersions?hl=en)
used to protect this resource via CMEK. This field is empty if the
Google Cloud product owning the resource does not provide key versions data
to Asset Inventory. The first element of this field is stored in
crypto_key_version.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this resource was created. The granularity
is in seconds. Timestamp.nanos will always be 0.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning

A warning message that indicates potential problems with the response data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->warning_code() >> / C<< $msg->warning_code($value) >>

Type: C<Enum> (L<Google::Cloud::Kms::Inventory::V1::Warning::WarningCode>)

The specific warning code for the displayed message.

=item * C<< $msg->display_message() >> / C<< $msg->display_message($value) >>

Type: C<String>

The literal message providing context and details about the warnings.

=back

=head3 Enum: Warning::WarningCode

=over 4

=item * C<WARNING_CODE_UNSPECIFIED> => C<0>

=item * C<INSUFFICIENT_PERMISSIONS_PARTIAL_DATA> => C<1>

=item * C<RESOURCE_LIMIT_EXCEEDED_PARTIAL_DATA> => C<2>

=item * C<ORG_LESS_PROJECT_PARTIAL_DATA> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
