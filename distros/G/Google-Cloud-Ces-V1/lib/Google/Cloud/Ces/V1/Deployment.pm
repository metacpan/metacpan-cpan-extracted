package Google::Cloud::Ces::V1::Deployment;

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
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvY2VzL3YxL2RlcGxveW1lbnQucHJvdG8SE2dvb2dsZS5jbG91ZC5j
ZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8aIGdvb2dsZS9jbG91ZC9jZXMvdjEvY29tbW9uLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIscEChBFeHBlcmltZW50Q29uZmlnEmIKD3ZlcnNp
b25fcmVsZWFzZRgBIAEoCzI0Lmdvb2dsZS5jbG91ZC5jZXMudjEuRXhwZXJpbWVudENvbmZp
Zy5WZXJzaW9uUmVsZWFzZUID4EEBUg52ZXJzaW9uUmVsZWFzZRr9AgoOVmVyc2lvblJlbGVh
c2USRgoFc3RhdGUYASABKA4yKy5nb29nbGUuY2xvdWQuY2VzLnYxLkV4cGVyaW1lbnRDb25m
aWcuU3RhdGVCA+BBAVIFc3RhdGUSfAoTdHJhZmZpY19hbGxvY2F0aW9ucxgCIAMoCzJGLmdv
b2dsZS5jbG91ZC5jZXMudjEuRXhwZXJpbWVudENvbmZpZy5WZXJzaW9uUmVsZWFzZS5UcmFm
ZmljQWxsb2NhdGlvbkID4EEBUhJ0cmFmZmljQWxsb2NhdGlvbnMapAEKEVRyYWZmaWNBbGxv
Y2F0aW9uEhMKAmlkGAEgASgJQgPgQQFSAmlkEjIKEnRyYWZmaWNfcGVyY2VudGFnZRgCIAEo
BUID4EEBUhF0cmFmZmljUGVyY2VudGFnZRJGCgthcHBfdmVyc2lvbhgDIAEoCUIl4EEB+kEf
Ch1jZXMuZ29vZ2xlYXBpcy5jb20vQXBwVmVyc2lvblIKYXBwVmVyc2lvbiJPCgVTdGF0ZRIV
ChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB1BFTkRJTkcQARILCgdSVU5OSU5HEAISCAoERE9O
RRADEgsKB0VYUElSRUQQBCK3BgoKRGVwbG95bWVudBIXCgRuYW1lGAEgASgJQgPgQQhSBG5h
bWUSJgoMZGlzcGxheV9uYW1lGAggASgJQgPgQQJSC2Rpc3BsYXlOYW1lEkYKC2FwcF92ZXJz
aW9uGAIgASgJQiXgQQH6QR8KHWNlcy5nb29nbGVhcGlzLmNvbS9BcHBWZXJzaW9uUgphcHBW
ZXJzaW9uElEKD2NoYW5uZWxfcHJvZmlsZRgDIAEoCzIjLmdvb2dsZS5jbG91ZC5jZXMudjEu
Q2hhbm5lbFByb2ZpbGVCA+BBAlIOY2hhbm5lbFByb2ZpbGUSQAoLY3JlYXRlX3RpbWUYBCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBk
YXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0
ZVRpbWUSFwoEZXRhZxgHIAEoCUID4EEDUgRldGFnElcKEWV4cGVyaW1lbnRfY29uZmlnGAkg
ASgLMiUuZ29vZ2xlLmNsb3VkLmNlcy52MS5FeHBlcmltZW50Q29uZmlnQgPgQQFSEGV4cGVy
aW1lbnRDb25maWcSYwoUd2hhdHNhcHBfY3JlZGVudGlhbHMYCiABKAsyKC5nb29nbGUuY2xv
dWQuY2VzLnYxLldoYXRzQXBwQ3JlZGVudGlhbHNCBuBBAeBBBFITd2hhdHNhcHBDcmVkZW50
aWFscxJmChVpbnN0YWdyYW1fY3JlZGVudGlhbHMYCyABKAsyKS5nb29nbGUuY2xvdWQuY2Vz
LnYxLkluc3RhZ3JhbUNyZWRlbnRpYWxzQgbgQQHgQQRSFGluc3RhZ3JhbUNyZWRlbnRpYWxz
OokB6kGFAQodY2VzLmdvb2dsZWFwaXMuY29tL0RlcGxveW1lbnQSS3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2RlcGxveW1lbnRzL3tkZXBs
b3ltZW50fSoLZGVwbG95bWVudHMyCmRlcGxveW1lbnQihgIKE1doYXRzQXBwQ3JlZGVudGlh
bHMSIAoJYXV0aF9jb2RlGAEgASgJQgPgQQJSCGF1dGhDb2RlEhUKA3BpbhgCIAEoCUID4EEC
UgNwaW4SJgoMcGhvbmVfbnVtYmVyGAMgASgJQgPgQQJSC3Bob25lTnVtYmVyEjMKE2J1c2lu
ZXNzX2FjY291bnRfaWQYBCABKAlCA+BBAlIRYnVzaW5lc3NBY2NvdW50SWQSHAoHd2FiYV9p
ZBgFIAEoCUID4EECUgZ3YWJhSWQSOwoXY29udmVyc2F0aW9uX3Byb2ZpbGVfaWQYBiABKAlC
A+BBAlIVY29udmVyc2F0aW9uUHJvZmlsZUlkInUKFEluc3RhZ3JhbUNyZWRlbnRpYWxzEiAK
CWF1dGhfY29kZRgBIAEoCUID4EECUghhdXRoQ29kZRI7Chdjb252ZXJzYXRpb25fcHJvZmls
ZV9pZBgCIAEoCUID4EECUhVjb252ZXJzYXRpb25Qcm9maWxlSWRCWwoXY29tLmdvb2dsZS5j
bG91ZC5jZXMudjFCE0NoYW5uZWxQcm9maWxlUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9n
by9jZXMvYXBpdjEvY2VzcGI7Y2VzcGJKozAKBxIFDgCuAQEKvAQKAQwSAw4AEjKxBCBDb3B5
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
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUACoKCQoCAwMSAxUAKQoICgEIEgMXAEAKCQoCCAsSAxcAQAoICgEIEgMYACIKCQoCCAoS
AxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoICgEIEgMaADAKCQoCCAESAxoAMAosCgIEABIE
HQBRARogIEV4cGVyaW1lbnQgZm9yIHRoZSBkZXBsb3ltZW50LgoKCgoDBAABEgMdCBgKMwoE
BAADABIEHwI7AxolIFZlcnNpb24gcmVsZWFzZSBmb3IgdGhlIGV4cGVyaW1lbnQuCgoMCgUE
AAMAARIDHwoYCj0KBgQAAwADABIEIQQzBRotIFRyYWZmaWMgYWxsb2NhdGlvbiBmb3IgdGhl
IHZlcnNpb24gcmVsZWFzZS4KCg4KBwQAAwADAAESAyEMHQplCggEAAMAAwACABIDJAY9GlQg
T3B0aW9uYWwuIElkIG9mIHRoZSB0cmFmZmljIGFsbG9jYXRpb24uCiBGcmVlIGZvcm1hdCBz
dHJpbmcsIHVwIHRvIDEyOCBjaGFyYWN0ZXJzLgoKEAoJBAADAAMAAgAFEgMkBgwKEAoJBAAD
AAMAAgABEgMkDQ8KEAoJBAADAAMAAgADEgMkEhMKEAoJBAADAAMAAgAIEgMkFDwKEwoMBAAD
AAMAAgAInAgAEgMkFTsKZgoIBAADAAMAAgESAygGTBpVIE9wdGlvbmFsLiBUcmFmZmljIHBl
cmNlbnRhZ2Ugb2YgdGhlIHRyYWZmaWMgYWxsb2NhdGlvbi4KIE11c3QgYmUgYmV0d2VlbiAw
IGFuZCAxMDAuCgoQCgkEAAMAAwACAQUSAygGCwoQCgkEAAMAAwACAQESAygMHgoQCgkEAAMA
AwACAQMSAyghIgoQCgkEAAMAAwACAQgSAygjSwoTCgwEAAMAAwACAQicCAASAygkSgqXAQoI
BAADAAMAAgISBC0GMggahAEgT3B0aW9uYWwuIEFwcCB2ZXJzaW9uIG9mIHRoZSB0cmFmZmlj
IGFsbG9jYXRpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2FwcHMve2FwcH0vdmVyc2lvbnMve3ZlcnNpb259YAoKEAoJBAADAAMAAgIF
EgMtBgwKEAoJBAADAAMAAgIBEgMtDRgKEAoJBAADAAMAAgIDEgMtGxwKEQoJBAADAAMAAgII
EgQtHTIHChMKDAQAAwADAAICCJwIABIDLgguChMKCwQAAwADAAICCJ8IEgQvCDEJCjgKBgQA
AwACABIDNgQ9GikgT3B0aW9uYWwuIFN0YXRlIG9mIHRoZSB2ZXJzaW9uIHJlbGVhc2UuCgoO
CgcEAAMAAgAGEgM2BAkKDgoHBAADAAIAARIDNgoPCg4KBwQAAwACAAMSAzYSEwoOCgcEAAMA
AgAIEgM2FDwKEQoKBAADAAIACJwIABIDNhU7CkgKBgQAAwACARIEOQQ6MRo4IE9wdGlvbmFs
LiBUcmFmZmljIGFsbG9jYXRpb25zIGZvciB0aGUgdmVyc2lvbiByZWxlYXNlLgoKDgoHBAAD
AAIBBBIDOQQMCg4KBwQAAwACAQYSAzkNHgoOCgcEAAMAAgEBEgM5HzIKDgoHBAADAAIBAxID
OTU2Cg4KBwQAAwACAQgSAzoIMAoRCgoEAAMAAgEInAgAEgM6CS8KKAoEBAAEABIEPgJNAxoa
IFN0YXRlIG9mIHRoZSBleHBlcmltZW50LgoKDAoFBAAEAAESAz4HDAojCgYEAAQAAgASA0AE
GhoUIFVuc3BlY2lmaWVkIHN0YXRlLgoKDgoHBAAEAAIAARIDQAQVCg4KBwQABAACAAISA0AY
GQo6CgYEAAQAAgESA0MEEBorIERlcHJlY2F0ZWQ6IFRoaXMgc3RhdGUgaXMgbm8gbG9uZ2Vy
IHVzZWQuCgoOCgcEAAQAAgEBEgNDBAsKDgoHBAAEAAIBAhIDQw4PCkAKBgQABAACAhIDRgQQ
GjEgUnVubmluZyBzdGF0ZS4gRXhwZXJpbWVudCBpcyBydW5uaW5nIGFuZCB2YWxpZC4KCg4K
BwQABAACAgESA0YECwoOCgcEAAQAAgICEgNGDg8KOgoGBAAEAAIDEgNJBA0aKyBEZXByZWNh
dGVkOiBUaGlzIHN0YXRlIGlzIG5vIGxvbmdlciB1c2VkLgoKDgoHBAAEAAIDARIDSQQICg4K
BwQABAACAwISA0kLDAo6CgYEAAQAAgQSA0wEEBorIERlcHJlY2F0ZWQ6IFRoaXMgc3RhdGUg
aXMgbm8gbG9uZ2VyIHVzZWQuCgoOCgcEAAQAAgQBEgNMBAsKDgoHBAAEAAIEAhIDTA4PCjwK
BAQAAgASA1ACThovIE9wdGlvbmFsLiBWZXJzaW9uIHJlbGVhc2UgZm9yIHRoZSBleHBlcmlt
ZW50LgoKDAoFBAACAAYSA1ACEAoMCgUEAAIAARIDUBEgCgwKBQQAAgADEgNQIyQKDAoFBAAC
AAgSA1AlTQoPCggEAAIACJwIABIDUCZMCpkBCgIEARIFVQCQAQEaiwEgQSBkZXBsb3ltZW50
IHJlcHJlc2VudHMgYW4gaW1tdXRhYmxlLCBxdWVyeWFibGUgdmVyc2lvbiBvZiB0aGUgYXBw
LgogSXQgaXMgdXNlZCB0byBkZXBsb3kgYW4gYXBwIHZlcnNpb24gd2l0aCBhIHNwZWNpZmlj
IGNoYW5uZWwgcHJvZmlsZS4KCgoKAwQBARIDVQgSCgsKAwQBBxIEVgJbBAoNCgUEAQedCBIE
VgJbBAqYAQoEBAECABIDYAI9GooBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBkZXBsb3ltZW50LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2RlcGxveW1lbnRzL3tkZXBsb3ltZW50fWAKCgwK
BQQBAgAFEgNgAggKDAoFBAECAAESA2AJDQoMCgUEAQIAAxIDYBARCgwKBQQBAgAIEgNgEjwK
DwoIBAECAAicCAASA2ATOwo4CgQEAQIBEgNjAkMaKyBSZXF1aXJlZC4gRGlzcGxheSBuYW1l
IG9mIHRoZSBkZXBsb3ltZW50LgoKDAoFBAECAQUSA2MCCAoMCgUEAQIBARIDYwkVCgwKBQQB
AgEDEgNjGBkKDAoFBAECAQgSA2MaQgoPCggEAQIBCJwIABIDYxtBCvgBCgQEAQICEgRqAm0E
GukBIE9wdGlvbmFsLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYXBwIHZlcnNpb24gdG8g
ZGVwbG95LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hcHBzL3thcHB9L3ZlcnNpb25zL3t2ZXJzaW9ufWAKIFVzZSBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdmVyc2lvbnMvLWAgdG8g
dXNlCiB0aGUgZHJhZnQgYXBwLgoKDAoFBAECAgUSA2oCCAoMCgUEAQICARIDagkUCgwKBQQB
AgIDEgNqFxgKDQoFBAECAggSBGoZbQMKDwoIBAECAgicCAASA2sEKgoOCgcEAQICCJ8IEgNs
BE8KRAoEBAECAxIDcAJOGjcgUmVxdWlyZWQuIFRoZSBjaGFubmVsIHByb2ZpbGUgdXNlZCBp
biB0aGUgZGVwbG95bWVudC4KCgwKBQQBAgMGEgNwAhAKDAoFBAECAwESA3ARIAoMCgUEAQID
AxIDcCMkCgwKBQQBAgMIEgNwJU0KDwoIBAECAwicCAASA3AmTApICgQEAQIEEgRzAnQyGjog
T3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoaXMgZGVwbG95bWVudCB3YXMgY3JlYXRl
ZC4KCgwKBQQBAgQGEgNzAhsKDAoFBAECBAESA3McJwoMCgUEAQIEAxIDcyorCgwKBQQBAgQI
EgN0BjEKDwoIBAECBAicCAASA3QHMApNCgQEAQIFEgR3AngyGj8gT3V0cHV0IG9ubHkuIFRp
bWVzdGFtcCB3aGVuIHRoaXMgZGVwbG95bWVudCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAEC
BQYSA3cCGwoMCgUEAQIFARIDdxwnCgwKBQQBAgUDEgN3KisKDAoFBAECBQgSA3gGMQoPCggE
AQIFCJwIABIDeAcwCroBCgQEAQIGEgN9Aj4arAEgT3V0cHV0IG9ubHkuIEV0YWcgdXNlZCB0
byBlbnN1cmUgdGhlIG9iamVjdCBoYXNuJ3QgY2hhbmdlZCBkdXJpbmcgYQogcmVhZC1tb2Rp
Znktd3JpdGUgb3BlcmF0aW9uLiBJZiB0aGUgZXRhZyBpcyBlbXB0eSwgdGhlIHVwZGF0ZSB3
aWxsCiBvdmVyd3JpdGUgYW55IGNvbmN1cnJlbnQgY2hhbmdlcy4KCgwKBQQBAgYFEgN9AggK
DAoFBAECBgESA30JDQoMCgUEAQIGAxIDfRARCgwKBQQBAgYIEgN9Ej0KDwoIBAECBgicCAAS
A30TPApICgQEAQIHEgaAAQKBAS8aOCBPcHRpb25hbC4gRXhwZXJpbWVudCBjb25maWd1cmF0
aW9uIGZvciB0aGUgZGVwbG95bWVudC4KCg0KBQQBAgcGEgSAAQISCg0KBQQBAgcBEgSAARMk
Cg0KBQQBAgcDEgSAAScoCg0KBQQBAgcIEgSBAQYuChAKCAQBAgcInAgAEgSBAQctCn0KBAQB
AggSBoUBAogBBBptIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBFcGhlbWVyYWwgV2hhdHNBcHAg
Y3JlZGVudGlhbHMgcmVxdWlyZWQgd2hlbgogY29uZmlndXJpbmcgYSBXaGF0c0FwcCBjaGFu
bmVsIHByb2ZpbGUuCgoNCgUEAQIIBhIEhQECFQoNCgUEAQIIARIEhQEWKgoNCgUEAQIIAxIE
hQEtLwoPCgUEAQIICBIGhQEwiAEDChAKCAQBAggInAgAEgSGAQQqChAKCAQBAggInAgBEgSH
AQQsCn8KBAQBAgkSBowBAo8BBBpvIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBFcGhlbWVyYWwg
SW5zdGFncmFtIGNyZWRlbnRpYWxzIHJlcXVpcmVkIHdoZW4KIGNvbmZpZ3VyaW5nIGEgSW5z
dGFncmFtIGNoYW5uZWwgcHJvZmlsZS4KCg0KBQQBAgkGEgSMAQIWCg0KBQQBAgkBEgSMARcs
Cg0KBQQBAgkDEgSMAS8xCg8KBQQBAgkIEgaMATKPAQMKEAoIBAECCQicCAASBI0BBCoKEAoI
BAECCQicCAESBI4BBCwKSwoCBAISBpMBAKUBARo9IEVwaGVtZXJhbCBNZXRhIGNyZWRlbnRp
YWxzIGZvciBXaGF0c0FwcCBuYXRpdmUgaW50ZWdyYXRpb24uCgoLCgMEAgESBJMBCBsKUgoE
BAICABIElQECQBpEIFJlcXVpcmVkLiBUaGUgTWV0YSBhdXRoIGNvZGUgcHJvdmlkZWQgYnkg
dGhlIGVtYmVkZGVkIHNpZ251cCBmbG93LgoKDQoFBAICAAUSBJUBAggKDQoFBAICAAESBJUB
CRIKDQoFBAICAAMSBJUBFRYKDQoFBAICAAgSBJUBFz8KEAoIBAICAAicCAASBJUBGD4KWAoE
BAICARIEmAECOhpKIFJlcXVpcmVkLiBUaGUgNi1kaWdpdCBQSU4gY3JlYXRlZCBieSB0aGUg
dXNlciBmb3IgdHdvLXN0ZXAgdmVyaWZpY2F0aW9uLgoKDQoFBAICAQUSBJgBAggKDQoFBAIC
AQESBJgBCQwKDQoFBAICAQMSBJgBDxAKDQoFBAICAQgSBJgBETkKEAoIBAICAQicCAASBJgB
EjgKRQoEBAICAhIEmwECQxo3IFJlcXVpcmVkLiBUaGUgcGhvbmUgbnVtYmVyIHRvIHJlZ2lz
dGVyIHdpdGggV2hhdHNBcHAuCgoNCgUEAgICBRIEmwECCAoNCgUEAgICARIEmwEJFQoNCgUE
AgICAxIEmwEYGQoNCgUEAgICCBIEmwEaQgoQCggEAgICCJwIABIEmwEbQQpOCgQEAgIDEgSe
AQJKGkAgUmVxdWlyZWQuIFRoZSBCdXNpbmVzcyBBY2NvdW50IElEIHRvIHVzZSBmb3IgdGhl
IHBob25lIG51bWJlci4KCg0KBQQCAgMFEgSeAQIICg0KBQQCAgMBEgSeAQkcCg0KBQQCAgMD
EgSeAR8gCg0KBQQCAgMIEgSeASFJChAKCAQCAgMInAgAEgSeASJICjsKBAQCAgQSBKEBAj4a
LSBSZXF1aXJlZC4gVGhlIFdoYXRzQXBwIEJ1c2luZXNzIEFjY291bnQgSUQuCgoNCgUEAgIE
BRIEoQECCAoNCgUEAgIEARIEoQEJEAoNCgUEAgIEAxIEoQETFAoNCgUEAgIECBIEoQEVPQoQ
CggEAgIECJwIABIEoQEWPApQCgQEAgIFEgSkAQJOGkIgUmVxdWlyZWQuIFRoZSBDb252ZXJz
YXRpb24gUHJvZmlsZSBJRCB0byB1c2UgZm9yIHRoZSBkZXBsb3ltZW50LgoKDQoFBAICBQUS
BKQBAggKDQoFBAICBQESBKQBCSAKDQoFBAICBQMSBKQBIyQKDQoFBAICBQgSBKQBJU0KEAoI
BAICBQicCAASBKQBJkwKTAoCBAMSBqgBAK4BARo+IEVwaGVtZXJhbCBNZXRhIGNyZWRlbnRp
YWxzIGZvciBJbnN0YWdyYW0gbmF0aXZlIGludGVncmF0aW9uLgoKCwoDBAMBEgSoAQgcClIK
BAQDAgASBKoBAkAaRCBSZXF1aXJlZC4gVGhlIE1ldGEgYXV0aCBjb2RlIHByb3ZpZGVkIGJ5
IHRoZSBlbWJlZGRlZCBzaWdudXAgZmxvdy4KCg0KBQQDAgAFEgSqAQIICg0KBQQDAgABEgSq
AQkSCg0KBQQDAgADEgSqARUWCg0KBQQDAgAIEgSqARc/ChAKCAQDAgAInAgAEgSqARg+ClAK
BAQDAgESBK0BAk4aQiBSZXF1aXJlZC4gVGhlIENvbnZlcnNhdGlvbiBQcm9maWxlIElEIHRv
IHVzZSBmb3IgdGhlIGRlcGxveW1lbnQuCgoNCgUEAwIBBRIErQECCAoNCgUEAwIBARIErQEJ
IAoNCgUEAwIBAxIErQEjJAoNCgUEAwIBCBIErQElTQoQCggEAwIBCJwIABIErQEmTGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Deployment::ExperimentConfig ===
    # Fields for ExperimentConfig
    # Field: version_release Type: 11 (.google.cloud.ces.v1.ExperimentConfig.VersionRelease)

# Enum: ExperimentConfig::State
our $ExperimentConfig_STATE_UNSPECIFIED = 0;
our $ExperimentConfig_PENDING = 1;
our $ExperimentConfig_RUNNING = 2;
our $ExperimentConfig_DONE = 3;
our $ExperimentConfig_EXPIRED = 4;

# === Message: Google::Cloud::Ces::V1::Deployment::Deployment ===
    # Fields for Deployment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: app_version Type: 9 ()
    # Field: channel_profile Type: 11 (.google.cloud.ces.v1.ChannelProfile)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: experiment_config Type: 11 (.google.cloud.ces.v1.ExperimentConfig)
    # Field: whatsapp_credentials Type: 11 (.google.cloud.ces.v1.WhatsAppCredentials)
    # Field: instagram_credentials Type: 11 (.google.cloud.ces.v1.InstagramCredentials)

# === Message: Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials ===
    # Fields for WhatsAppCredentials
    # Field: auth_code Type: 9 ()
    # Field: pin Type: 9 ()
    # Field: phone_number Type: 9 ()
    # Field: business_account_id Type: 9 ()
    # Field: waba_id Type: 9 ()
    # Field: conversation_profile_id Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Deployment::InstagramCredentials ===
    # Fields for InstagramCredentials
    # Field: auth_code Type: 9 ()
    # Field: conversation_profile_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Deployment - Compiled Protocol Buffers messages for google/cloud/ces/v1/deployment.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Deployment;

    my $msg = Google::Cloud::Ces::V1::Deployment::ExperimentConfig->new({
        version_release => $version_release,
    });

    # Read or update a field
    my $val = $msg->version_release();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Deployment::ExperimentConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Deployment::ExperimentConfig

Experiment for the deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version_release() >> / C<< $msg->version_release($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease>)

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

=head2 Google::Cloud::Ces::V1::Deployment::Deployment

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ChannelProfile>)

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Deployment::ExperimentConfig>)

Optional. Experiment configuration for the deployment.

=item * C<< $msg->whatsapp_credentials() >> / C<< $msg->whatsapp_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials>)

Optional. Input only. Ephemeral WhatsApp credentials required when
configuring a WhatsApp channel profile.

=item * C<< $msg->instagram_credentials() >> / C<< $msg->instagram_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Deployment::InstagramCredentials>)

Optional. Input only. Ephemeral Instagram credentials required when
configuring a Instagram channel profile.

=back

=head2 Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials

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

Required. The Conversation Profile ID to use for the deployment.

=back

=head2 Google::Cloud::Ces::V1::Deployment::InstagramCredentials

Ephemeral Meta credentials for Instagram native integration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_code() >> / C<< $msg->auth_code($value) >>

Type: C<String>

Required. The Meta auth code provided by the embedded signup flow.

=item * C<< $msg->conversation_profile_id() >> / C<< $msg->conversation_profile_id($value) >>

Type: C<String>

Required. The Conversation Profile ID to use for the deployment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Deployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
