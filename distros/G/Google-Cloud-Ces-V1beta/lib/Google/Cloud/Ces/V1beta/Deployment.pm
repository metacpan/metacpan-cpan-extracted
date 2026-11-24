package Google::Cloud::Ces::V1beta::Deployment;

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
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9kZXBsb3ltZW50LnByb3RvEhdnb29nbGUuY2xv
dWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvY29tbW9uLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItQEChBFeHBlcmltZW50Q29u
ZmlnEmYKD3ZlcnNpb25fcmVsZWFzZRgBIAEoCzI4Lmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LkV4cGVyaW1lbnRDb25maWcuVmVyc2lvblJlbGVhc2VCA+BBAVIOdmVyc2lvblJlbGVhc2Ua
hgMKDlZlcnNpb25SZWxlYXNlEkoKBXN0YXRlGAEgASgOMi8uZ29vZ2xlLmNsb3VkLmNlcy52
MWJldGEuRXhwZXJpbWVudENvbmZpZy5TdGF0ZUID4EEBUgVzdGF0ZRKAAQoTdHJhZmZpY19h
bGxvY2F0aW9ucxgCIAMoCzJKLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4cGVyaW1lbnRD
b25maWcuVmVyc2lvblJlbGVhc2UuVHJhZmZpY0FsbG9jYXRpb25CA+BBAVISdHJhZmZpY0Fs
bG9jYXRpb25zGqQBChFUcmFmZmljQWxsb2NhdGlvbhITCgJpZBgBIAEoCUID4EEBUgJpZBIy
ChJ0cmFmZmljX3BlcmNlbnRhZ2UYAiABKAVCA+BBAVIRdHJhZmZpY1BlcmNlbnRhZ2USRgoL
YXBwX3ZlcnNpb24YAyABKAlCJeBBAfpBHwodY2VzLmdvb2dsZWFwaXMuY29tL0FwcFZlcnNp
b25SCmFwcFZlcnNpb24iTwoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdQRU5E
SU5HEAESCwoHUlVOTklORxACEggKBERPTkUQAxILCgdFWFBJUkVEEAQivgkKCkRlcGxveW1l
bnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgIIAEoCUID4EEC
UgtkaXNwbGF5TmFtZRJGCgthcHBfdmVyc2lvbhgCIAEoCUIl4EEB+kEfCh1jZXMuZ29vZ2xl
YXBpcy5jb20vQXBwVmVyc2lvblIKYXBwVmVyc2lvbhJVCg9jaGFubmVsX3Byb2ZpbGUYAyAB
KAsyJy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5DaGFubmVsUHJvZmlsZUID4EECUg5jaGFu
bmVsUHJvZmlsZRJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIXCgRldGFnGAcgASgJQgPgQQNS
BGV0YWcSWwoRZXhwZXJpbWVudF9jb25maWcYCSABKAsyKS5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5FeHBlcmltZW50Q29uZmlnQgPgQQFSEGV4cGVyaW1lbnRDb25maWcSZwoUd2hhdHNh
cHBfY3JlZGVudGlhbHMYCiABKAsyLC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5XaGF0c0Fw
cENyZWRlbnRpYWxzQgbgQQHgQQRSE3doYXRzYXBwQ3JlZGVudGlhbHMSagoVaW5zdGFncmFt
X2NyZWRlbnRpYWxzGAsgASgLMi0uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuSW5zdGFncmFt
Q3JlZGVudGlhbHNCBuBBAeBBBFIUaW5zdGFncmFtQ3JlZGVudGlhbHMSUgoObW9kZWxfc2V0
dGluZ3MYDCABKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Nb2RlbFNldHRpbmdzQgPg
QQFSDW1vZGVsU2V0dGluZ3MSTQoIbW9kYWxpdHkYDSABKA4yLC5nb29nbGUuY2xvdWQuY2Vz
LnYxYmV0YS5EZXBsb3ltZW50Lk1vZGFsaXR5QgPgQQFSCG1vZGFsaXR5EnEKGWFnZW50X3Jl
Z2lzdHJ5X2RlcGxveW1lbnQYDiABKAsyMC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5BZ2Vu
dFJlZ2lzdHJ5RGVwbG95bWVudEID4EEBUhdhZ2VudFJlZ2lzdHJ5RGVwbG95bWVudCJfCghN
b2RhbGl0eRIYChRNT0RBTElUWV9VTlNQRUNJRklFRBAAEhEKDU1PREFMSVRZX1RFWFQQARIS
Cg5NT0RBTElUWV9WT0lDRRACEhIKDk1PREFMSVRZX1ZJREVPEAM6iQHqQYUBCh1jZXMuZ29v
Z2xlYXBpcy5jb20vRGVwbG95bWVudBJLcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2FwcHMve2FwcH0vZGVwbG95bWVudHMve2RlcGxveW1lbnR9KgtkZXBsb3lt
ZW50czIKZGVwbG95bWVudCKJAQoXQWdlbnRSZWdpc3RyeURlcGxveW1lbnQSbgobYWdlbnRf
cmVnaXN0cnlfc2VydmljZV9uYW1lGAEgASgJQi/gQQHgQQP6QSYKJGFnZW50cmVnaXN0cnku
Z29vZ2xlYXBpcy5jb20vU2VydmljZVIYYWdlbnRSZWdpc3RyeVNlcnZpY2VOYW1lIoYCChNX
aGF0c0FwcENyZWRlbnRpYWxzEiAKCWF1dGhfY29kZRgBIAEoCUID4EECUghhdXRoQ29kZRIV
CgNwaW4YAiABKAlCA+BBAlIDcGluEiYKDHBob25lX251bWJlchgDIAEoCUID4EECUgtwaG9u
ZU51bWJlchIzChNidXNpbmVzc19hY2NvdW50X2lkGAQgASgJQgPgQQJSEWJ1c2luZXNzQWNj
b3VudElkEhwKB3dhYmFfaWQYBSABKAlCA+BBAlIGd2FiYUlkEjsKF2NvbnZlcnNhdGlvbl9w
cm9maWxlX2lkGAYgASgJQgPgQQFSFWNvbnZlcnNhdGlvblByb2ZpbGVJZCJ1ChRJbnN0YWdy
YW1DcmVkZW50aWFscxIgCglhdXRoX2NvZGUYASABKAlCA+BBAlIIYXV0aENvZGUSOwoXY29u
dmVyc2F0aW9uX3Byb2ZpbGVfaWQYAiABKAlCA+BBAVIVY29udmVyc2F0aW9uUHJvZmlsZUlk
QsgBChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCE0NoYW5uZWxQcm9maWxlUHJvdG9Q
AVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3Bi6kFiCiRh
Z2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1NlcnZpY2USOnByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2VydmljZX1KzTwKBxIFDgDfAQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIA
KQoJCgIDARIDEwAjCgkKAgMCEgMUAC4KCQoCAwMSAxUAKQoICgEIEgMXAEQKCQoCCAsSAxcA
RAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoICgEIEgMaADQK
CQoCCAESAxoANAoJCgEIEgQbAB4CCgwKBAidCAASBBsAHgIKLAoCBAASBCEAVQEaICBFeHBl
cmltZW50IGZvciB0aGUgZGVwbG95bWVudC4KCgoKAwQAARIDIQgYCjMKBAQAAwASBCMCPwMa
JSBWZXJzaW9uIHJlbGVhc2UgZm9yIHRoZSBleHBlcmltZW50LgoKDAoFBAADAAESAyMKGAo9
CgYEAAMAAwASBCUENwUaLSBUcmFmZmljIGFsbG9jYXRpb24gZm9yIHRoZSB2ZXJzaW9uIHJl
bGVhc2UuCgoOCgcEAAMAAwABEgMlDB0KZQoIBAADAAMAAgASAygGPRpUIE9wdGlvbmFsLiBJ
ZCBvZiB0aGUgdHJhZmZpYyBhbGxvY2F0aW9uLgogRnJlZSBmb3JtYXQgc3RyaW5nLCB1cCB0
byAxMjggY2hhcmFjdGVycy4KChAKCQQAAwADAAIABRIDKAYMChAKCQQAAwADAAIAARIDKA0P
ChAKCQQAAwADAAIAAxIDKBITChAKCQQAAwADAAIACBIDKBQ8ChMKDAQAAwADAAIACJwIABID
KBU7CmYKCAQAAwADAAIBEgMsBkwaVSBPcHRpb25hbC4gVHJhZmZpYyBwZXJjZW50YWdlIG9m
IHRoZSB0cmFmZmljIGFsbG9jYXRpb24uCiBNdXN0IGJlIGJldHdlZW4gMCBhbmQgMTAwLgoK
EAoJBAADAAMAAgEFEgMsBgsKEAoJBAADAAMAAgEBEgMsDB4KEAoJBAADAAMAAgEDEgMsISIK
EAoJBAADAAMAAgEIEgMsI0sKEwoMBAADAAMAAgEInAgAEgMsJEoKlwEKCAQAAwADAAICEgQx
BjYIGoQBIE9wdGlvbmFsLiBBcHAgdmVyc2lvbiBvZiB0aGUgdHJhZmZpYyBhbGxvY2F0aW9u
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9h
cHBzL3thcHB9L3ZlcnNpb25zL3t2ZXJzaW9ufWAKChAKCQQAAwADAAICBRIDMQYMChAKCQQA
AwADAAICARIDMQ0YChAKCQQAAwADAAICAxIDMRscChEKCQQAAwADAAICCBIEMR02BwoTCgwE
AAMAAwACAgicCAASAzIILgoTCgsEAAMAAwACAgifCBIEMwg1CQo4CgYEAAMAAgASAzoEPRop
IE9wdGlvbmFsLiBTdGF0ZSBvZiB0aGUgdmVyc2lvbiByZWxlYXNlLgoKDgoHBAADAAIABhID
OgQJCg4KBwQAAwACAAESAzoKDwoOCgcEAAMAAgADEgM6EhMKDgoHBAADAAIACBIDOhQ8ChEK
CgQAAwACAAicCAASAzoVOwpICgYEAAMAAgESBD0EPjEaOCBPcHRpb25hbC4gVHJhZmZpYyBh
bGxvY2F0aW9ucyBmb3IgdGhlIHZlcnNpb24gcmVsZWFzZS4KCg4KBwQAAwACAQQSAz0EDAoO
CgcEAAMAAgEGEgM9DR4KDgoHBAADAAIBARIDPR8yCg4KBwQAAwACAQMSAz01NgoOCgcEAAMA
AgEIEgM+CDAKEQoKBAADAAIBCJwIABIDPgkvCigKBAQABAASBEICUQMaGiBTdGF0ZSBvZiB0
aGUgZXhwZXJpbWVudC4KCgwKBQQABAABEgNCBwwKIwoGBAAEAAIAEgNEBBoaFCBVbnNwZWNp
ZmllZCBzdGF0ZS4KCg4KBwQABAACAAESA0QEFQoOCgcEAAQAAgACEgNEGBkKOgoGBAAEAAIB
EgNHBBAaKyBEZXByZWNhdGVkOiBUaGlzIHN0YXRlIGlzIG5vIGxvbmdlciB1c2VkLgoKDgoH
BAAEAAIBARIDRwQLCg4KBwQABAACAQISA0cODwpACgYEAAQAAgISA0oEEBoxIFJ1bm5pbmcg
c3RhdGUuIEV4cGVyaW1lbnQgaXMgcnVubmluZyBhbmQgdmFsaWQuCgoOCgcEAAQAAgIBEgNK
BAsKDgoHBAAEAAICAhIDSg4PCjoKBgQABAACAxIDTQQNGisgRGVwcmVjYXRlZDogVGhpcyBz
dGF0ZSBpcyBubyBsb25nZXIgdXNlZC4KCg4KBwQABAACAwESA00ECAoOCgcEAAQAAgMCEgNN
CwwKOgoGBAAEAAIEEgNQBBAaKyBEZXByZWNhdGVkOiBUaGlzIHN0YXRlIGlzIG5vIGxvbmdl
ciB1c2VkLgoKDgoHBAAEAAIEARIDUAQLCg4KBwQABAACBAISA1AODwo8CgQEAAIAEgNUAk4a
LyBPcHRpb25hbC4gVmVyc2lvbiByZWxlYXNlIGZvciB0aGUgZXhwZXJpbWVudC4KCgwKBQQA
AgAGEgNUAhAKDAoFBAACAAESA1QRIAoMCgUEAAIAAxIDVCMkCgwKBQQAAgAIEgNUJU0KDwoI
BAACAAicCAASA1QmTAqZAQoCBAESBVkAswEBGosBIEEgZGVwbG95bWVudCByZXByZXNlbnRz
IGFuIGltbXV0YWJsZSwgcXVlcnlhYmxlIHZlcnNpb24gb2YgdGhlIGFwcC4KIEl0IGlzIHVz
ZWQgdG8gZGVwbG95IGFuIGFwcCB2ZXJzaW9uIHdpdGggYSBzcGVjaWZpYyBjaGFubmVsIHBy
b2ZpbGUuCgoKCgMEAQESA1kIEgoLCgMEAQcSBFoCXwQKDQoFBAEHnQgSBFoCXwQKLwoEBAEE
ABIEYgJuAxohIFRoZSBtb2RhbGl0eSBvZiB0aGUgZGVwbG95bWVudC4KCgwKBQQBBAABEgNi
Bw8KIgoGBAEEAAIAEgNkBB0aEyBVbmtub3duIG1vZGFsaXR5LgoKDgoHBAEEAAIAARIDZAQY
Cg4KBwQBBAACAAISA2QbHAofCgYEAQQAAgESA2cEFhoQIFRleHQgbW9kYWxpdHkuCgoOCgcE
AQQAAgEBEgNnBBEKDgoHBAEEAAIBAhIDZxQVCiAKBgQBBAACAhIDagQXGhEgVm9pY2UgbW9k
YWxpdHkuCgoOCgcEAQQAAgIBEgNqBBIKDgoHBAEEAAICAhIDahUWCiAKBgQBBAACAxIDbQQX
GhEgVmlkZW8gbW9kYWxpdHkuCgoOCgcEAQQAAgMBEgNtBBIKDgoHBAEEAAIDAhIDbRUWCpgB
CgQEAQIAEgNzAj0aigEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGRl
cGxveW1lbnQuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2FwcHMve2FwcH0vZGVwbG95bWVudHMve2RlcGxveW1lbnR9YAoKDAoFBAECAAUS
A3MCCAoMCgUEAQIAARIDcwkNCgwKBQQBAgADEgNzEBEKDAoFBAECAAgSA3MSPAoPCggEAQIA
CJwIABIDcxM7CjgKBAQBAgESA3YCQxorIFJlcXVpcmVkLiBEaXNwbGF5IG5hbWUgb2YgdGhl
IGRlcGxveW1lbnQuCgoMCgUEAQIBBRIDdgIICgwKBQQBAgEBEgN2CRUKDAoFBAECAQMSA3YY
GQoMCgUEAQIBCBIDdhpCCg8KCAQBAgEInAgAEgN2G0EK+QEKBAQBAgISBX0CgAEEGukBIE9w
dGlvbmFsLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYXBwIHZlcnNpb24gdG8gZGVwbG95
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9h
cHBzL3thcHB9L3ZlcnNpb25zL3t2ZXJzaW9ufWAKIFVzZSBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdmVyc2lvbnMvLWAgdG8gdXNlCiB0
aGUgZHJhZnQgYXBwLgoKDAoFBAECAgUSA30CCAoMCgUEAQICARIDfQkUCgwKBQQBAgIDEgN9
FxgKDgoFBAECAggSBX0ZgAEDCg8KCAQBAgIInAgAEgN+BCoKDgoHBAECAgifCBIDfwRPCkUK
BAQBAgMSBIMBAk4aNyBSZXF1aXJlZC4gVGhlIGNoYW5uZWwgcHJvZmlsZSB1c2VkIGluIHRo
ZSBkZXBsb3ltZW50LgoKDQoFBAECAwYSBIMBAhAKDQoFBAECAwESBIMBESAKDQoFBAECAwMS
BIMBIyQKDQoFBAECAwgSBIMBJU0KEAoIBAECAwicCAASBIMBJkwKSgoEBAECBBIGhgEChwEy
GjogT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoaXMgZGVwbG95bWVudCB3YXMgY3Jl
YXRlZC4KCg0KBQQBAgQGEgSGAQIbCg0KBQQBAgQBEgSGARwnCg0KBQQBAgQDEgSGASorCg0K
BQQBAgQIEgSHAQYxChAKCAQBAgQInAgAEgSHAQcwCk8KBAQBAgUSBooBAosBMho/IE91dHB1
dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGlzIGRlcGxveW1lbnQgd2FzIGxhc3QgdXBkYXRl
ZC4KCg0KBQQBAgUGEgSKAQIbCg0KBQQBAgUBEgSKARwnCg0KBQQBAgUDEgSKASorCg0KBQQB
AgUIEgSLAQYxChAKCAQBAgUInAgAEgSLAQcwCrsBCgQEAQIGEgSQAQI+GqwBIE91dHB1dCBv
bmx5LiBFdGFnIHVzZWQgdG8gZW5zdXJlIHRoZSBvYmplY3QgaGFzbid0IGNoYW5nZWQgZHVy
aW5nIGEKIHJlYWQtbW9kaWZ5LXdyaXRlIG9wZXJhdGlvbi4gSWYgdGhlIGV0YWcgaXMgZW1w
dHksIHRoZSB1cGRhdGUgd2lsbAogb3ZlcndyaXRlIGFueSBjb25jdXJyZW50IGNoYW5nZXMu
CgoNCgUEAQIGBRIEkAECCAoNCgUEAQIGARIEkAEJDQoNCgUEAQIGAxIEkAEQEQoNCgUEAQIG
CBIEkAESPQoQCggEAQIGCJwIABIEkAETPApICgQEAQIHEgaTAQKUAS8aOCBPcHRpb25hbC4g
RXhwZXJpbWVudCBjb25maWd1cmF0aW9uIGZvciB0aGUgZGVwbG95bWVudC4KCg0KBQQBAgcG
EgSTAQISCg0KBQQBAgcBEgSTARMkCg0KBQQBAgcDEgSTAScoCg0KBQQBAgcIEgSUAQYuChAK
CAQBAgcInAgAEgSUAQctCn0KBAQBAggSBpgBApsBBBptIE9wdGlvbmFsLiBJbnB1dCBvbmx5
LiBFcGhlbWVyYWwgV2hhdHNBcHAgY3JlZGVudGlhbHMgcmVxdWlyZWQgd2hlbgogY29uZmln
dXJpbmcgYSBXaGF0c0FwcCBjaGFubmVsIHByb2ZpbGUuCgoNCgUEAQIIBhIEmAECFQoNCgUE
AQIIARIEmAEWKgoNCgUEAQIIAxIEmAEtLwoPCgUEAQIICBIGmAEwmwEDChAKCAQBAggInAgA
EgSZAQQqChAKCAQBAggInAgBEgSaAQQsCn8KBAQBAgkSBp8BAqIBBBpvIE9wdGlvbmFsLiBJ
bnB1dCBvbmx5LiBFcGhlbWVyYWwgSW5zdGFncmFtIGNyZWRlbnRpYWxzIHJlcXVpcmVkIHdo
ZW4KIGNvbmZpZ3VyaW5nIGEgSW5zdGFncmFtIGNoYW5uZWwgcHJvZmlsZS4KCg0KBQQBAgkG
EgSfAQIWCg0KBQQBAgkBEgSfARcsCg0KBQQBAgkDEgSfAS8xCg8KBQQBAgkIEgafATKiAQMK
EAoIBAECCQicCAASBKABBCoKEAoIBAECCQicCAESBKEBBCwK9gEKBAQBAgoSBKgBAk0a5wEg
T3B0aW9uYWwuIE1vZGVsIHNldHRpbmdzIGZvciB0aGUgZGVwbG95bWVudC4KIE92ZXJyaWRl
cyBtb2RlbCBzZXR0aW5ncyBjb25maWd1cmVkIGF0IHRoZSBhcHAvYWdlbnQgbGV2ZWxzLgog
Tm90ZTogRGVwbG95bWVudC1sZXZlbCBtb2RlbCBzZXR0aW5ncyBvdmVycmlkZSBpcyBnYXRl
ZCBiZWhpbmQgYW4KIGFsbG93bGlzdC4gQ29udGFjdCB0aGUgQ1hBUyB0ZWFtIHRvIGVuYWJs
ZSB0aGlzIGZpZWxkLgoKDQoFBAECCgYSBKgBAg8KDQoFBAECCgESBKgBEB4KDQoFBAECCgMS
BKgBISMKDQoFBAECCggSBKgBJEwKEAoIBAECCgicCAASBKgBJUsKrwEKBAQBAgsSBK0BAkIa
oAEgT3B0aW9uYWwuIFRoZSBtb2RhbGl0eSBvZiB0aGUgZGVwbG95bWVudC4KIE5vdGU6IERl
cGxveW1lbnQtbGV2ZWwgbW9kYWxpdHkgb3ZlcnJpZGUgaXMgZ2F0ZWQgYmVoaW5kIGFuIGFs
bG93bGlzdC4KIENvbnRhY3QgdGhlIENYQVMgdGVhbSB0byBlbmFibGUgdGhpcyBmaWVsZC4K
Cg0KBQQBAgsGEgStAQIKCg0KBQQBAgsBEgStAQsTCg0KBQQBAgsDEgStARYYCg0KBQQBAgsI
EgStARlBChAKCAQBAgsInAgAEgStARpACp0BCgQEAQIMEgaxAQKyAS8ajAEgT3B0aW9uYWwu
IENvbmZpZ3VyYXRpb24gZm9yIGRlcGxveWluZyB0aGlzIGRlcGxveW1lbnQgdG8gQWdlbnQg
UmVnaXN0cnkuCiBJZiBwcmVzZW50LCB0aGlzIGRlcGxveW1lbnQgd2lsbCBiZSBwdWJsaXNo
ZWQgdG8gQWdlbnQgUmVnaXN0cnkuCgoNCgUEAQIMBhIEsQECGQoNCgUEAQIMARIEsQEaMwoN
CgUEAQIMAxIEsQE2OAoNCgUEAQIMCBIEsgEGLgoQCggEAQIMCJwIABIEsgEHLQpHCgIEAhIG
tgEAwQEBGjkgQ29uZmlndXJhdGlvbiBhbmQgc3RhdHVzIGZvciBBZ2VudCBSZWdpc3RyeSBk
ZXBsb3ltZW50LgoKCwoDBAIBEgS2AQgfCqoBCgQEAgIAEga6AQLAAQQamQEgT3B0aW9uYWwu
IE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZGVwbG95ZWQgQWdlbnQg
UmVnaXN0cnkKIHNlcnZpY2UuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vc2VydmljZXMve3NlcnZpY2V9YAoKDQoFBAICAAUSBLoBAggKDQoF
BAICAAESBLoBCSQKDQoFBAICAAMSBLoBJygKDwoFBAICAAgSBroBKcABAwoQCggEAgIACJwI
ABIEuwEEKgoQCggEAgIACJwIARIEvAEELQoRCgcEAgIACJ8IEga9AQS/AQUKSwoCBAMSBsQB
ANYBARo9IEVwaGVtZXJhbCBNZXRhIGNyZWRlbnRpYWxzIGZvciBXaGF0c0FwcCBuYXRpdmUg
aW50ZWdyYXRpb24uCgoLCgMEAwESBMQBCBsKUgoEBAMCABIExgECQBpEIFJlcXVpcmVkLiBU
aGUgTWV0YSBhdXRoIGNvZGUgcHJvdmlkZWQgYnkgdGhlIGVtYmVkZGVkIHNpZ251cCBmbG93
LgoKDQoFBAMCAAUSBMYBAggKDQoFBAMCAAESBMYBCRIKDQoFBAMCAAMSBMYBFRYKDQoFBAMC
AAgSBMYBFz8KEAoIBAMCAAicCAASBMYBGD4KWAoEBAMCARIEyQECOhpKIFJlcXVpcmVkLiBU
aGUgNi1kaWdpdCBQSU4gY3JlYXRlZCBieSB0aGUgdXNlciBmb3IgdHdvLXN0ZXAgdmVyaWZp
Y2F0aW9uLgoKDQoFBAMCAQUSBMkBAggKDQoFBAMCAQESBMkBCQwKDQoFBAMCAQMSBMkBDxAK
DQoFBAMCAQgSBMkBETkKEAoIBAMCAQicCAASBMkBEjgKRQoEBAMCAhIEzAECQxo3IFJlcXVp
cmVkLiBUaGUgcGhvbmUgbnVtYmVyIHRvIHJlZ2lzdGVyIHdpdGggV2hhdHNBcHAuCgoNCgUE
AwICBRIEzAECCAoNCgUEAwICARIEzAEJFQoNCgUEAwICAxIEzAEYGQoNCgUEAwICCBIEzAEa
QgoQCggEAwICCJwIABIEzAEbQQpOCgQEAwIDEgTPAQJKGkAgUmVxdWlyZWQuIFRoZSBCdXNp
bmVzcyBBY2NvdW50IElEIHRvIHVzZSBmb3IgdGhlIHBob25lIG51bWJlci4KCg0KBQQDAgMF
EgTPAQIICg0KBQQDAgMBEgTPAQkcCg0KBQQDAgMDEgTPAR8gCg0KBQQDAgMIEgTPASFJChAK
CAQDAgMInAgAEgTPASJICjsKBAQDAgQSBNIBAj4aLSBSZXF1aXJlZC4gVGhlIFdoYXRzQXBw
IEJ1c2luZXNzIEFjY291bnQgSUQuCgoNCgUEAwIEBRIE0gECCAoNCgUEAwIEARIE0gEJEAoN
CgUEAwIEAxIE0gETFAoNCgUEAwIECBIE0gEVPQoQCggEAwIECJwIABIE0gEWPApQCgQEAwIF
EgTVAQJOGkIgT3B0aW9uYWwuIFRoZSBDb252ZXJzYXRpb24gUHJvZmlsZSBJRCB0byB1c2Ug
Zm9yIHRoZSBkZXBsb3ltZW50LgoKDQoFBAMCBQUSBNUBAggKDQoFBAMCBQESBNUBCSAKDQoF
BAMCBQMSBNUBIyQKDQoFBAMCBQgSBNUBJU0KEAoIBAMCBQicCAASBNUBJkwKTAoCBAQSBtkB
AN8BARo+IEVwaGVtZXJhbCBNZXRhIGNyZWRlbnRpYWxzIGZvciBJbnN0YWdyYW0gbmF0aXZl
IGludGVncmF0aW9uLgoKCwoDBAQBEgTZAQgcClIKBAQEAgASBNsBAkAaRCBSZXF1aXJlZC4g
VGhlIE1ldGEgYXV0aCBjb2RlIHByb3ZpZGVkIGJ5IHRoZSBlbWJlZGRlZCBzaWdudXAgZmxv
dy4KCg0KBQQEAgAFEgTbAQIICg0KBQQEAgABEgTbAQkSCg0KBQQEAgADEgTbARUWCg0KBQQE
AgAIEgTbARc/ChAKCAQEAgAInAgAEgTbARg+ClAKBAQEAgESBN4BAk4aQiBPcHRpb25hbC4g
VGhlIENvbnZlcnNhdGlvbiBQcm9maWxlIElEIHRvIHVzZSBmb3IgdGhlIGRlcGxveW1lbnQu
CgoNCgUEBAIBBRIE3gECCAoNCgUEBAIBARIE3gEJIAoNCgUEBAIBAxIE3gEjJAoNCgUEBAIB
CBIE3gElTQoQCggEBAIBCJwIABIE3gEmTGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig ===
    # Fields for ExperimentConfig
    # Field: version_release Type: 11 (.google.cloud.ces.v1beta.ExperimentConfig.VersionRelease)

# Enum: ExperimentConfig::State
our $ExperimentConfig_STATE_UNSPECIFIED = 0;
our $ExperimentConfig_PENDING = 1;
our $ExperimentConfig_RUNNING = 2;
our $ExperimentConfig_DONE = 3;
our $ExperimentConfig_EXPIRED = 4;

# === Message: Google::Cloud::Ces::V1beta::Deployment::Deployment ===
    # Fields for Deployment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: app_version Type: 9 ()
    # Field: channel_profile Type: 11 (.google.cloud.ces.v1beta.ChannelProfile)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: experiment_config Type: 11 (.google.cloud.ces.v1beta.ExperimentConfig)
    # Field: whatsapp_credentials Type: 11 (.google.cloud.ces.v1beta.WhatsAppCredentials)
    # Field: instagram_credentials Type: 11 (.google.cloud.ces.v1beta.InstagramCredentials)
    # Field: model_settings Type: 11 (.google.cloud.ces.v1beta.ModelSettings)
    # Field: modality Type: 14 (.google.cloud.ces.v1beta.Deployment.Modality)
    # Field: agent_registry_deployment Type: 11 (.google.cloud.ces.v1beta.AgentRegistryDeployment)

# Enum: Deployment::Modality
our $Deployment_MODALITY_UNSPECIFIED = 0;
our $Deployment_MODALITY_TEXT = 1;
our $Deployment_MODALITY_VOICE = 2;
our $Deployment_MODALITY_VIDEO = 3;

# === Message: Google::Cloud::Ces::V1beta::Deployment::AgentRegistryDeployment ===
    # Fields for AgentRegistryDeployment
    # Field: agent_registry_service_name Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Deployment::WhatsAppCredentials ===
    # Fields for WhatsAppCredentials
    # Field: auth_code Type: 9 ()
    # Field: pin Type: 9 ()
    # Field: phone_number Type: 9 ()
    # Field: business_account_id Type: 9 ()
    # Field: waba_id Type: 9 ()
    # Field: conversation_profile_id Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Deployment::InstagramCredentials ===
    # Fields for InstagramCredentials
    # Field: auth_code Type: 9 ()
    # Field: conversation_profile_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Deployment - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/deployment.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Deployment;

    my $msg = Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig->new({
        version_release => $version_release,
    });

    # Read or update a field
    my $val = $msg->version_release();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig

Experiment for the deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version_release() >> / C<< $msg->version_release($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig::VersionRelease>)

Optional. Version release for the experiment.

=back

=head3 Enum: ExperimentConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<DONE> => C<3>

=item * C<EXPIRED> => C<4>

=back

=head2 Google::Cloud::Ces::V1beta::Deployment::Deployment

A deployment represents an immutable, queryable version of the app.
It is used to deploy an app version with a specific channel profile.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the deployment.
Format:
`projects/{project}/locations/{location}/apps/{app}/deployments/{deployment}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the deployment.

=item * C<< $msg->app_version() >> / C<< $msg->app_version($value) >>

Type: C<String>

Optional. The resource name of the app version to deploy.
Format:
`projects/{project}/locations/{location}/apps/{app}/versions/{version}`
Use `projects/{project}/locations/{location}/apps/{app}/versions/-` to use
the draft app.

=item * C<< $msg->channel_profile() >> / C<< $msg->channel_profile($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ChannelProfile>)

Required. The channel profile used in the deployment.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this deployment was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this deployment was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag used to ensure the object hasn't changed during a
read-modify-write operation. If the etag is empty, the update will
overwrite any concurrent changes.

=item * C<< $msg->experiment_config() >> / C<< $msg->experiment_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Deployment::ExperimentConfig>)

Optional. Experiment configuration for the deployment.

=item * C<< $msg->whatsapp_credentials() >> / C<< $msg->whatsapp_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Deployment::WhatsAppCredentials>)

Optional. Input only. Ephemeral WhatsApp credentials required when
configuring a WhatsApp channel profile.

=item * C<< $msg->instagram_credentials() >> / C<< $msg->instagram_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Deployment::InstagramCredentials>)

Optional. Input only. Ephemeral Instagram credentials required when
configuring a Instagram channel profile.

=item * C<< $msg->model_settings() >> / C<< $msg->model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ModelSettings>)

Optional. Model settings for the deployment.
Overrides model settings configured at the app/agent levels.
Note: Deployment-level model settings override is gated behind an
allowlist. Contact the CXAS team to enable this field.

=item * C<< $msg->modality() >> / C<< $msg->modality($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::Deployment::Modality>)

Optional. The modality of the deployment.
Note: Deployment-level modality override is gated behind an allowlist.
Contact the CXAS team to enable this field.

=item * C<< $msg->agent_registry_deployment() >> / C<< $msg->agent_registry_deployment($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Deployment::AgentRegistryDeployment>)

Optional. Configuration for deploying this deployment to Agent Registry.
If present, this deployment will be published to Agent Registry.

=back

=head3 Enum: Deployment::Modality

=over 4

=item * C<MODALITY_UNSPECIFIED> => C<0>

=item * C<MODALITY_TEXT> => C<1>

=item * C<MODALITY_VOICE> => C<2>

=item * C<MODALITY_VIDEO> => C<3>

=back

=head2 Google::Cloud::Ces::V1beta::Deployment::AgentRegistryDeployment

Configuration and status for Agent Registry deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->agent_registry_service_name() >> / C<< $msg->agent_registry_service_name($value) >>

Type: C<String>

Optional. Output only. The resource name of the deployed Agent Registry
service. Format:
`projects/{project}/locations/{location}/services/{service}`

=back

=head2 Google::Cloud::Ces::V1beta::Deployment::WhatsAppCredentials

Ephemeral Meta credentials for WhatsApp native integration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_code() >> / C<< $msg->auth_code($value) >>

Type: C<String>

Required. The Meta auth code provided by the embedded signup flow.

=item * C<< $msg->pin() >> / C<< $msg->pin($value) >>

Type: C<String>

Required. The 6-digit PIN created by the user for two-step verification.

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

Required. The phone number to register with WhatsApp.

=item * C<< $msg->business_account_id() >> / C<< $msg->business_account_id($value) >>

Type: C<String>

Required. The Business Account ID to use for the phone number.

=item * C<< $msg->waba_id() >> / C<< $msg->waba_id($value) >>

Type: C<String>

Required. The WhatsApp Business Account ID.

=item * C<< $msg->conversation_profile_id() >> / C<< $msg->conversation_profile_id($value) >>

Type: C<String>

Optional. The Conversation Profile ID to use for the deployment.

=back

=head2 Google::Cloud::Ces::V1beta::Deployment::InstagramCredentials

Ephemeral Meta credentials for Instagram native integration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_code() >> / C<< $msg->auth_code($value) >>

Type: C<String>

Required. The Meta auth code provided by the embedded signup flow.

=item * C<< $msg->conversation_profile_id() >> / C<< $msg->conversation_profile_id($value) >>

Type: C<String>

Optional. The Conversation Profile ID to use for the deployment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Deployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
