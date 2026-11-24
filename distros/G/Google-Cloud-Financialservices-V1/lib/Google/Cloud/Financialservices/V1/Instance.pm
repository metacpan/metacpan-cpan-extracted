package Google::Cloud::Financialservices::V1::Instance;

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
    eval { require Google::Cloud::Financialservices::V1::BigqueryDestination };
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvaW5zdGFuY2UucHJvdG8SIWdv
b2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo8Z29vZ2xlL2Nsb3VkL2Zp
bmFuY2lhbHNlcnZpY2VzL3YxL2JpZ3F1ZXJ5X2Rlc3RpbmF0aW9uLnByb3RvGjhnb29nbGUv
Y2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvbGluZV9vZl9idXNpbmVzcy5wcm90bxogZ29v
Z2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8i4wQKCEluc3RhbmNlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJACgtjcmVh
dGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZRJMCgVzdGF0ZRgEIAEoDjIxLmdvb2dsZS5jbG91ZC5maW5hbmNp
YWxzZXJ2aWNlcy52MS5JbnN0YW5jZS5TdGF0ZUID4EEDUgVzdGF0ZRJPCgZsYWJlbHMYBSAD
KAsyNy5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuSW5zdGFuY2UuTGFiZWxz
RW50cnlSBmxhYmVscxIcCgdrbXNfa2V5GAYgASgJQgPgQQJSBmttc0tleRo5CgtMYWJlbHNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlQKBVN0
YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIM
CghVUERBVElORxADEgwKCERFTEVUSU5HEAQ6bOpBaQopZmluYW5jaWFsc2VydmljZXMuZ29v
Z2xlYXBpcy5jb20vSW5zdGFuY2USPHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfSLIAQoUTGlzdEluc3RhbmNlc1JlcXVlc3QS
QQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2Nh
dGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tl
bhgDIAEoCVIJcGFnZVRva2VuEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEhkKCG9yZGVyX2J5
GAUgASgJUgdvcmRlckJ5IqwBChVMaXN0SW5zdGFuY2VzUmVzcG9uc2USSQoJaW5zdGFuY2Vz
GAEgAygLMisuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkluc3RhbmNlUglp
bnN0YW5jZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3Vu
cmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJbChJHZXRJbnN0YW5jZVJlcXVlc3QSRQoE
bmFtZRgBIAEoCUIx4EEC+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9J
bnN0YW5jZVIEbmFtZSLyAQoVQ3JlYXRlSW5zdGFuY2VSZXF1ZXN0EkEKBnBhcmVudBgBIAEo
CUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIk
CgtpbnN0YW5jZV9pZBgCIAEoCUID4EECUgppbnN0YW5jZUlkEkwKCGluc3RhbmNlGAMgASgL
MisuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkluc3RhbmNlQgPgQQJSCGlu
c3RhbmNlEiIKCnJlcXVlc3RfaWQYBCABKAlCA+BBAVIJcmVxdWVzdElkIssBChVVcGRhdGVJ
bnN0YW5jZVJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYu
RmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSTAoIaW5zdGFuY2UYAiABKAsyKy5nb29nbGUu
Y2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuSW5zdGFuY2VCA+BBAlIIaW5zdGFuY2USIgoK
cmVxdWVzdF9pZBgDIAEoCUID4EEBUglyZXF1ZXN0SWQiggEKFURlbGV0ZUluc3RhbmNlUmVx
dWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKWZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFw
aXMuY29tL0luc3RhbmNlUgRuYW1lEiIKCnJlcXVlc3RfaWQYAiABKAlCA+BBAVIJcmVxdWVz
dElkIsYDCh5JbXBvcnRSZWdpc3RlcmVkUGFydGllc1JlcXVlc3QSRQoEbmFtZRgBIAEoCUIx
4EEC+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIEbmFt
ZRImCgxwYXJ0eV90YWJsZXMYAiADKAlCA+BBAVILcGFydHlUYWJsZXMSZQoEbW9kZRgDIAEo
DjJMLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5JbXBvcnRSZWdpc3RlcmVk
UGFydGllc1JlcXVlc3QuVXBkYXRlTW9kZUID4EECUgRtb2RlEigKDXZhbGlkYXRlX29ubHkY
BCABKAhCA+BBAVIMdmFsaWRhdGVPbmx5EmAKEGxpbmVfb2ZfYnVzaW5lc3MYBSABKA4yMS5n
b29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuTGluZU9mQnVzaW5lc3NCA+BBAlIO
bGluZU9mQnVzaW5lc3MiQgoKVXBkYXRlTW9kZRIbChdVUERBVEVfTU9ERV9VTlNQRUNJRklF
RBAAEgsKB1JFUExBQ0UQARIKCgZBUFBFTkQQAiLkAgofSW1wb3J0UmVnaXN0ZXJlZFBhcnRp
ZXNSZXNwb25zZRIjCg1wYXJ0aWVzX2FkZGVkGAEgASgDUgxwYXJ0aWVzQWRkZWQSJwoPcGFy
dGllc19yZW1vdmVkGAIgASgDUg5wYXJ0aWVzUmVtb3ZlZBIjCg1wYXJ0aWVzX3RvdGFsGAMg
ASgDUgxwYXJ0aWVzVG90YWwSNwoYcGFydGllc19mYWlsZWRfdG9fcmVtb3ZlGAQgASgDUhVw
YXJ0aWVzRmFpbGVkVG9SZW1vdmUSKQoQcGFydGllc191cHRpZXJlZBgFIAEoA1IPcGFydGll
c1VwdGllcmVkEi0KEnBhcnRpZXNfZG93bnRpZXJlZBgGIAEoA1IRcGFydGllc0Rvd250aWVy
ZWQSOwoacGFydGllc19mYWlsZWRfdG9fZG93bnRpZXIYByABKANSF3BhcnRpZXNGYWlsZWRU
b0Rvd250aWVyIqACCh5FeHBvcnRSZWdpc3RlcmVkUGFydGllc1JlcXVlc3QSRQoEbmFtZRgB
IAEoCUIx4EEC+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9JbnN0YW5j
ZVIEbmFtZRJVCgdkYXRhc2V0GAIgASgLMjYuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZp
Y2VzLnYxLkJpZ1F1ZXJ5RGVzdGluYXRpb25CA+BBAlIHZGF0YXNldBJgChBsaW5lX29mX2J1
c2luZXNzGAMgASgOMjEuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpbmVP
ZkJ1c2luZXNzQgPgQQJSDmxpbmVPZkJ1c2luZXNzIiEKH0V4cG9ydFJlZ2lzdGVyZWRQYXJ0
aWVzUmVzcG9uc2VC/AEKJWNvbS5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjFC
DUluc3RhbmNlUHJvdG9QAVpTY2xvdWQuZ29vZ2xlLmNvbS9nby9maW5hbmNpYWxzZXJ2aWNl
cy9hcGl2MS9maW5hbmNpYWxzZXJ2aWNlc3BiO2ZpbmFuY2lhbHNlcnZpY2VzcGKqAiFHb29n
bGUuQ2xvdWQuRmluYW5jaWFsU2VydmljZXMuVjHKAiFHb29nbGVcQ2xvdWRcRmluYW5jaWFs
U2VydmljZXNcVjHqAiRHb29nbGU6OkNsb3VkOjpGaW5hbmNpYWxTZXJ2aWNlczo6VjFK61wK
BxIFDgC/AioKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAEYKCQoCAwMSAxUAQgoJCgIDBBIDFgAq
CgkKAgMFEgMXACkKCAoBCBIDGQA+CgkKAgglEgMZAD4KCAoBCBIDGgBqCgkKAggLEgMaAGoK
CAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAuCgkKAggIEgMcAC4KCAoBCBIDHQA+CgkK
AggBEgMdAD4KCAoBCBIDHgA+CgkKAggpEgMeAD4KCAoBCBIDHwA9CgkKAggtEgMfAD0KuwIK
AgQAEgQmAFgBGq4CIEluc3RhbmNlIGlzIGEgY29udGFpbmVyIGZvciB0aGUgcmVzdCBvZiBB
UEkgcmVzb3VyY2VzLgogT25seSByZXNvdXJjZXMgaW4gdGhlIHNhbWUgaW5zdGFuY2UgY2Fu
IGludGVyYWN0IHdpdGggZWFjaCBvdGhlci4KIENoaWxkIHJlc291cmNlcyBpbmhlcml0IHRo
ZSBsb2NhdGlvbiAoZGF0YSByZXNpZGVuY3kpIGFuZCBlbmNyeXB0aW9uIChDTUVLKS4KIFRo
ZSBsb2NhdGlvbiBvZiB0aGUgcHJvdmlkZWQgaW5wdXQgYW5kIG91dHB1dCBpbiByZXF1ZXN0
cyBtdXN0IG1hdGNoIHRoZQogbG9jYXRpb24gb2YgdGhlIGluc3RhbmNlLgoKCgoDBAABEgMm
CBAKCwoDBAAHEgQnAioECg0KBQQAB50IEgQnAioECiIKBAQABAASBC0CPAMaFCBUaGUgUmVz
b3VyY2UgU3RhdGUKCgwKBQQABAABEgMtBwwKOAoGBAAEAAIAEgMvBBoaKSBTdGF0ZSBpcyB1
bnNwZWNpZmllZCwgc2hvdWxkIG5vdCBvY2N1ci4KCg4KBwQABAACAAESAy8EFQoOCgcEAAQA
AgACEgMvGBkKPQoGBAAEAAIBEgMyBBEaLiBUaGUgcmVzb3VyY2UgaGFzIG5vdCBmaW5pc2hl
ZCBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMgQMCg4KBwQABAACAQISAzIPEAo5CgYE
AAQAAgISAzUEDxoqIFRoZSByZXNvdXJjZSBpcyBhY3RpdmUvcmVhZHkgdG8gYmUgdXNlZC4K
Cg4KBwQABAACAgESAzUECgoOCgcEAAQAAgICEgM1DQ4KQQoGBAAEAAIDEgM4BBEaMiBUaGUg
cmVzb3VyY2UgaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAAC
AwESAzgEDAoOCgcEAAQAAgMCEgM4DxAKQQoGBAAEAAIEEgM7BBEaMiBUaGUgcmVzb3VyY2Ug
aXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcgZGVsZXRlZC4KCg4KBwQABAACBAESAzsEDAoO
CgcEAAQAAgQCEgM7DxAKmAEKBAQAAgASA0ACPhqKASBPdXRwdXQgb25seS4gVGhlIGZ1bGwg
cGF0aCB0byB0aGUgSW5zdGFuY2UgcmVzb3VyY2UgaW4gdGhpcyBBUEkuCiBmb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0
YW5jZX1gCgoMCgUEAAIABRIDQAIICgwKBQQAAgABEgNACQ0KDAoFBAACAAMSA0AQEQoMCgUE
AAIACBIDQBI9Cg8KCAQAAgAInAgAEgNAEzwKXgoEBAACARIERAJFMhpQIE91dHB1dCBvbmx5
LiBUaW1lc3RhbXAgd2hlbiB0aGUgSW5zdGFuY2Ugd2FzIGNyZWF0ZWQuCiBBc3NpZ25lZCBi
eSB0aGUgc2VydmVyLgoKDAoFBAACAQYSA0QCGwoMCgUEAAIBARIDRBwnCgwKBQQAAgEDEgNE
KisKDAoFBAACAQgSA0UGMQoPCggEAAIBCJwIABIDRQcwCmMKBAQAAgISBEkCSjIaVSBPdXRw
dXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIEluc3RhbmNlIHdhcyBsYXN0IHVwZGF0ZWQu
CiBBc3NpZ25lZCBieSB0aGUgc2VydmVyLgoKDAoFBAACAgYSA0kCGwoMCgUEAAICARIDSRwn
CgwKBQQAAgIDEgNJKisKDAoFBAACAggSA0oGMQoPCggEAAICCJwIABIDSgcwCksKBAQAAgMS
A04CPho+IE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgaW5zdGFuY2UuCiBBc3NpZ25lZCBi
eSB0aGUgc2VydmVyLgoKDAoFBAACAwYSA04CBwoMCgUEAAIDARIDTggNCgwKBQQAAgMDEgNO
EBEKDAoFBAACAwgSA04SPQoPCggEAAIDCJwIABIDThM8ChUKBAQAAgQSA1ECIRoIIExhYmVs
cwoKDAoFBAACBAYSA1ECFQoMCgUEAAIEARIDURYcCgwKBQQAAgQDEgNRHyAKyAEKBAQAAgUS
A1cCPhq6ASBSZXF1aXJlZC4gVGhlIEtNUyBrZXkgbmFtZSB1c2VkIGZvciBDTUVLIChlbmNy
eXB0aW9uLWF0LXJlc3QpLgogZm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5UmluZ30vY3J5cHRvS2V5cy97Y3J5cHRvS2V5
fWAKIFZQQy1TQyByZXN0cmljdGlvbnMgYXBwbHkuCgoMCgUEAAIFBRIDVwIICgwKBQQAAgUB
EgNXCRAKDAoFBAACBQMSA1cTFAoMCgUEAAIFCBIDVxU9Cg8KCAQAAgUInAgAEgNXFjwKbgoC
BAESBFwAdgEaYiBSZXF1ZXN0IGZvciByZXRyaWV2aW5nIGEgcGFnaW5hdGVkIGxpc3Qgb2Yg
SW5zdGFuY2UgcmVzb3VyY2VzIHRoYXQgbWVldCB0aGUKIHNwZWNpZmllZCBjcml0ZXJpYS4K
CgoKAwQBARIDXAgcCoEBCgQEAQIAEgRfAmQEGnMgUmVxdWlyZWQuIFRoZSBwYXJlbnQgb2Yg
dGhlIEluc3RhbmNlIGlzIHRoZSBsb2NhdGlvbiBmb3IgdGhhdCBJbnN0YW5jZS4KIEV2ZXJ5
IGxvY2F0aW9uIGhhcyBleGFjdGx5IG9uZSBpbnN0YW5jZS4KCgwKBQQBAgAFEgNfAggKDAoF
BAECAAESA18JDwoMCgUEAQIAAxIDXxITCg0KBQQBAgAIEgRfFGQDCg8KCAQBAgAInAgAEgNg
BCoKDwoHBAECAAifCBIEYQRjBQqsAQoEBAECARIDaQIWGp4BIFRoZSBudW1iZXIgb2YgcmVz
b3VyY2VzIHRvIGJlIGluY2x1ZGVkIGluIHRoZSByZXNwb25zZS4gVGhlIHJlc3BvbnNlCiBj
b250YWlucyBhIG5leHRfcGFnZV90b2tlbiwgd2hpY2ggY2FuIGJlIHVzZWQgdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZSBvZgogcmVzb3VyY2VzLgoKDAoFBAECAQUSA2kCBwoMCgUEAQIB
ARIDaQgRCgwKBQQBAgEDEgNpFBUK/wEKBAQBAgISA28CGBrxASBJbiBjYXNlIG9mIHBhZ2lu
YXRlZCByZXN1bHRzLCB0aGlzIGlzIHRoZSB0b2tlbiB0aGF0IHdhcyByZXR1cm5lZCBpbiB0
aGUKIHByZXZpb3VzIExpc3RJbnN0YW5jZXNSZXNwb25zZS4gSXQgc2hvdWxkIGJlIGNvcGll
ZCBoZXJlIHRvIHJldHJpZXZlIHRoZQogbmV4dCBwYWdlIG9mIHJlc291cmNlcy4gVGhpcyB3
aWxsIGJlIGVtcHR5IGZvciB0aGUgZmlyc3QgaW5zdGFuY2Ugb2YKIExpc3RJbnN0YW5jZXNS
ZXF1ZXN0LgoKDAoFBAECAgUSA28CCAoMCgUEAQICARIDbwkTCgwKBQQBAgIDEgNvFhcKOQoE
BAECAxIDcgIUGiwgU3BlY2lmeSBhIGZpbHRlciB0byBuYXJyb3cgc2VhcmNoIHJlc3VsdHMu
CgoMCgUEAQIDBRIDcgIICgwKBQQBAgMBEgNyCQ8KDAoFBAECAwMSA3ISEwozCgQEAQIEEgN1
AhYaJiBTcGVjaWZ5IGEgZmllbGQgdG8gdXNlIGZvciBvcmRlcmluZy4KCgwKBQQBAgQFEgN1
AggKDAoFBAECBAESA3UJEQoMCgUEAQIEAxIDdRQVCjoKAgQCEgV5AIMBARotIFJlc3BvbnNl
IGZvciByZXRyaWV2aW5nIGEgbGlzdCBvZiBJbnN0YW5jZXMKCgoKAwQCARIDeQgdCikKBAQC
AgASA3sCIhocIExpc3Qgb2YgSW5zdGFuY2UgcmVzb3VyY2VzCgoMCgUEAgIABBIDewIKCgwK
BQQCAgAGEgN7CxMKDAoFBAICAAESA3sUHQoMCgUEAgIAAxIDeyAhCnQKBAQCAgESA38CHRpn
IFRoaXMgdG9rZW4gc2hvdWxkIGJlIHBhc3NlZCB0byB0aGUgbmV4dCBMaXN0SW5zdGFuY2Vz
UmVxdWVzdCB0byByZXRyaWV2ZQogdGhlIG5leHQgcGFnZSBvZiBJbnN0YW5jZXMuCgoMCgUE
AgIBBRIDfwIICgwKBQQCAgEBEgN/CRgKDAoFBAICAQMSA38bHAo0CgQEAgICEgSCAQIiGiYg
TG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgICBBIEggECCgoN
CgUEAgICBRIEggELEQoNCgUEAgICARIEggESHQoNCgUEAgICAxIEggEgIQpECgIEAxIGhgEA
jgEBGjYgUmVxdWVzdCBmb3IgcmV0cmlldmluZyBhIHNwZWNpZmljIEluc3RhbmNlIHJlc291
cmNlLgoKCwoDBAMBEgSGAQgaCj4KBAQDAgASBogBAo0BBBouIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgSW5zdGFuY2UuCgoNCgUEAwIABRIEiAECCAoNCgUEAwIAARIE
iAEJDQoNCgUEAwIAAxIEiAEQEQoPCgUEAwIACBIGiAESjQEDChAKCAQDAgAInAgAEgSJAQQq
ChEKBwQDAgAInwgSBooBBIwBBQo5CgIEBBIGkQEArwEBGisgUmVxdWVzdCBmb3IgY3JlYXRp
bmcgYSBJbnN0YW5jZSByZXNvdXJjZS4KCgsKAwQEARIEkQEIHQqDAQoEBAQCABIGlAECmQEE
GnMgUmVxdWlyZWQuIFRoZSBwYXJlbnQgb2YgdGhlIEluc3RhbmNlIGlzIHRoZSBsb2NhdGlv
biBmb3IgdGhhdCBJbnN0YW5jZS4KIEV2ZXJ5IGxvY2F0aW9uIGhhcyBleGFjdGx5IG9uZSBp
bnN0YW5jZS4KCg0KBQQEAgAFEgSUAQIICg0KBQQEAgABEgSUAQkPCg0KBQQEAgADEgSUARIT
Cg8KBQQEAgAIEgaUARSZAQMKEAoIBAQCAAicCAASBJUBBCoKEQoHBAQCAAifCBIGlgEEmAEF
CjoKBAQEAgESBJwBAkIaLCBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGlkIG9mIHRoZSBpbnN0
YW5jZS4KCg0KBQQEAgEFEgScAQIICg0KBQQEAgEBEgScAQkUCg0KBQQEAgEDEgScARcYCg0K
BQQEAgEIEgScARlBChAKCAQEAgEInAgAEgScARpACjwKBAQEAgISBJ8BAkEaLiBSZXF1aXJl
ZC4gVGhlIGluc3RhbmNlIHRoYXQgd2lsbCBiZSBjcmVhdGVkLgoKDQoFBAQCAgYSBJ8BAgoK
DQoFBAQCAgESBJ8BCxMKDQoFBAQCAgMSBJ8BFhcKDQoFBAQCAggSBJ8BGEAKEAoIBAQCAgic
CAASBJ8BGT8KjwYKBAQEAgMSBK4BAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVl
c3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3Qg
SUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIg
d2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVl
biBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxl
YXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUs
IGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVz
dCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3Qg
YWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sg
aWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJl
Y2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhp
cyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNh
dGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQg
d2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgw
MDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAQCAwUSBK4BAggK
DQoFBAQCAwESBK4BCRMKDQoFBAQCAwMSBK4BFhcKDQoFBAQCAwgSBK4BGEAKEAoIBAQCAwic
CAASBK4BGT8KLwoCBAUSBrIBAM0BARohIFJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgSW5zdGFu
Y2UKCgsKAwQFARIEsgEIHQraAgoEBAUCABIGuAECuQEvGskCIE9wdGlvbmFsLiBGaWVsZCBt
YXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGlu
IHRoZQogSW5zdGFuY2UgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3Bl
Y2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNl
LCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBp
ZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhlCiB1c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBt
YXNrIHRoZW4gYWxsIGZpZWxkcyB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBLgB
AhsKDQoFBAUCAAESBLgBHCcKDQoFBAUCAAMSBLgBKisKDQoFBAUCAAgSBLkBBi4KEAoIBAUC
AAicCAASBLkBBy0KcQoEBAUCARIEvQECQRpjIFJlcXVpcmVkLiBUaGUgbmV3IHZhbHVlIG9m
IHRoZSBpbnN0YW5jZSBmaWVsZHMgdGhhdCB3aWxsIGJlIHVwZGF0ZWQKIGFjY29yZGluZyB0
byB0aGUgdXBkYXRlX21hc2sKCg0KBQQFAgEGEgS9AQIKCg0KBQQFAgEBEgS9AQsTCg0KBQQF
AgEDEgS9ARYXCg0KBQQFAgEIEgS9ARhAChAKCAQFAgEInAgAEgS9ARk/Co8GCgQEBQICEgTM
AQJBGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJl
cXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11
c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3Jl
IHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2Vy
dmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNl
IHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlv
biB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0
aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUg
cmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlv
biB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3
aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMg
ZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRo
ZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0
aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAw
MDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgIFEgTMAQIICg0KBQQFAgIBEgTMAQkTCg0KBQQF
AgIDEgTMARYXCg0KBQQFAgIIEgTMARhAChAKCAQFAgIInAgAEgTMARk/CjAKAgQGEgbQAQDn
AQEaIiBSZXF1ZXN0IGZvciBkZWxldGluZyBhIEluc3RhbmNlLgoKCwoDBAYBEgTQAQgdCj4K
BAQGAgASBtIBAtcBBBouIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgSW5z
dGFuY2UuCgoNCgUEBgIABRIE0gECCAoNCgUEBgIAARIE0gEJDQoNCgUEBgIAAxIE0gEQEQoP
CgUEBgIACBIG0gES1wEDChAKCAQGAgAInAgAEgTTAQQqChEKBwQGAgAInwgSBtQBBNYBBQqP
BgoEBAYCARIE5gECQRqABiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBp
ZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0
IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cg
dG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRl
ZC4gVGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWlu
dXRlcyBhZnRlciB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIg
YSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZCB0aGUK
IHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRo
IHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5h
bCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFu
ZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRz
CiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRt
ZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBl
eGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAw
MDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgIBBRIE5gECCAoNCgUEBgIBARIE
5gEJEwoNCgUEBgIBAxIE5gEWFwoNCgUEBgIBCBIE5gEYQAoQCggEBgIBCJwIABIE5gEZPwpv
CgIEBxIG6wEAkgIBGmEgUmVxdWVzdCBmb3IgYWRkaW5nL3JlbW92aW5nIHJlZ2lzdGVyZWQg
cGFydGllcyBmcm9tIEJpZ1F1ZXJ5IHRhYmxlcwogc3BlY2lmaWVkIGJ5IHRoZSBjdXN0b21l
ci4KCgsKAwQHARIE6wEIJgpPCgQEBwQAEgbtAQL2AQMaPyBVcGRhdGVNb2RlIGNvbnRyb2xz
IHRoZSBiZWhhdmlvciBmb3IgSW1wb3J0UmVnaXN0ZXJlZFBhcnRpZXMuCgoNCgUEBwQAARIE
7QEHEQofCgYEBwQAAgASBO8BBCAaDyBEZWZhdWx0IG1vZGUuCgoPCgcEBwQAAgABEgTvAQQb
Cg8KBwQHBAACAAISBO8BHh8KVwoGBAcEAAIBEgTyAQQQGkcgUmVwbGFjZSBwYXJ0aWVzIHRo
YXQgYXJlIHJlbW92YWJsZSBpbiBQYXJ0aWVzIFRhYmxlIHdpdGggbmV3IHBhcnRpZXMuCgoP
CgcEBwQAAgEBEgTyAQQLCg8KBwQHBAACAQISBPIBDg8KMwoGBAcEAAICEgT1AQQPGiMgQWRk
IG5ldyBwYXJ0aWVzIHRvIFBhcnRpZXMgVGFibGUuCgoPCgcEBwQAAgIBEgT1AQQKCg8KBwQH
BAACAgISBPUBDQ4KmAEKBAQHAgASBvoBAv8BBBqHASBSZXF1aXJlZC4gVGhlIGZ1bGwgcGF0
aCB0byB0aGUgSW5zdGFuY2UgcmVzb3VyY2UgaW4gdGhpcyBBUEkuCiBmb3JtYXQ6IGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5j
ZX1gCgoNCgUEBwIABRIE+gECCAoNCgUEBwIAARIE+gEJDQoNCgUEBwIAAxIE+gEQEQoPCgUE
BwIACBIG+gES/wEDChAKCAQHAgAInAgAEgT7AQQqChEKBwQHAgAInwgSBvwBBP4BBQrtAgoE
BAcCARIEhwICTBreAiBPcHRpb25hbC4gTGlzdCBvZiBCaWdRdWVyeSB0YWJsZXMuIFVuaW9u
IG9mIHRhYmxlcyB3aWxsIGJlIHRha2VuIGlmIHRoZXJlCiBpcyBtb3JlIHRoYW4gb25lIHRh
YmxlLiBWUEMtU0MgcmVzdHJpY3Rpb25zIGFwcGx5LiBmb3JtYXQ6CiBgYnE6Ly97cHJvamVj
dH0ue2JxRGF0YXNldElEfS57YnFUYWJsZUlEfWAgVXNlIG9mIGBkYXRhc2V0c2AgaXMgcHJl
ZmVycmVkCiBvdmVyIHRoZSBsYXR0ZXIgZHVlIHRvIGl0cyBzaW1wbGljaXR5IGFuZCB0aGUg
cmVkdWNlZCByaXNrIG9mIGVycm9ycwogYHBhcnR5X3RhYmxlc2AgYW5kIGBkYXRhc2V0c2Ag
bXVzdCBub3QgYmUgcHJvdmlkZWQgYXQgdGhlCiBzYW1lIHRpbWUKCg0KBQQHAgEEEgSHAgIK
Cg0KBQQHAgEFEgSHAgsRCg0KBQQHAgEBEgSHAhIeCg0KBQQHAgEDEgSHAiEiCg0KBQQHAgEI
EgSHAiNLChAKCAQHAgEInAgAEgSHAiRKCi4KBAQHAgISBIoCAj8aICBSZXF1aXJlZC4gTW9k
ZSBvZiB0aGUgcmVxdWVzdC4KCg0KBQQHAgIGEgSKAgIMCg0KBQQHAgIBEgSKAg0RCg0KBQQH
AgIDEgSKAhQVCg0KBQQHAgIIEgSKAhY+ChAKCAQHAgIInAgAEgSKAhc9CmoKBAQHAgMSBI4C
AkIaXCBPcHRpb25hbC4gSWYgdGhlIHJlcXVlc3Qgd2lsbCBub3QgcmVnaXN0ZXIgdGhlIHBh
cnRpZXMsIGp1c3QgZGV0ZXJtaW5lIHdoYXQKIHdvdWxkIGhhcHBlbi4KCg0KBQQHAgMFEgSO
AgIGCg0KBQQHAgMBEgSOAgcUCg0KBQQHAgMDEgSOAhcYCg0KBQQHAgMIEgSOAhlBChAKCAQH
AgMInAgAEgSOAhpACk4KBAQHAgQSBJECAk8aQCBSZXF1aXJlZC4gTGluZU9mQnVzaW5lc3Mg
Zm9yIHRoZSBzcGVjaWZpZWQgcmVnaXN0ZXJlZCBwYXJ0aWVzLgoKDQoFBAcCBAYSBJECAhAK
DQoFBAcCBAESBJECESEKDQoFBAcCBAMSBJECJCUKDQoFBAcCBAgSBJECJk4KEAoIBAcCBAic
CAASBJECJ00KVQoCBAgSBpUCAKoCARpHIFJlc3BvbnNlIGZvciBhZGRpbmcvcmVtb3Zpbmcg
cmVnaXN0ZXJlZCBwYXJ0aWVzIGZyb20gQmlnUXVlcnkgdGFibGVzLgoKCwoDBAgBEgSVAggn
CjoKBAQIAgASBJcCAhoaLCBOdW1iZXIgb2YgcGFydGllcyBhZGRlZCBieSB0aGlzIG9wZXJh
dGlvbi4KCg0KBQQIAgAFEgSXAgIHCg0KBQQIAgABEgSXAggVCg0KBQQIAgADEgSXAhgZCjwK
BAQIAgESBJoCAhwaLiBOdW1iZXIgb2YgcGFydGllcyByZW1vdmVkIGJ5IHRoaXMgb3BlcmF0
aW9uLgoKDQoFBAgCAQUSBJoCAgcKDQoFBAgCAQESBJoCCBcKDQoFBAgCAQMSBJoCGhsKeAoE
BAgCAhIEngICGhpqIFRvdGFsIG51bWJlciBvZiBwYXJ0aWVzIHRoYXQgYXJlIHJlZ2lzdGVy
ZWQgaW4gdGhpcyBpbnN0YW5jZSwgYWZ0ZXIgdGhlCiB1cGRhdGUgb3BlcmF0aW9uIHdhcyBj
b21wbGV0ZWQuCgoNCgUECAICBRIEngICBwoNCgUECAICARIEngIIFQoNCgUECAICAxIEngIY
GQpOCgQECAIDEgShAgIlGkAgTnVtYmVyIG9mIHBhcnRpZXMgdGhhdCBmYWlsZWQgdG8gYmUg
cmVtb3ZlZCBieSB0aGlzIG9wZXJhdGlvbi4KCg0KBQQIAgMFEgShAgIHCg0KBQQIAgMBEgSh
AgggCg0KBQQIAgMDEgShAiMkCgwKBAQIAgQSBKMCAh0KDQoFBAgCBAUSBKMCAgcKDQoFBAgC
BAESBKMCCBgKDQoFBAgCBAMSBKMCGxwKTAoEBAgCBRIEpgICHxo+IFRvdGFsIG51bWJlciBv
ZiBwYXJ0aWVzIHRoYXQgYXJlIGRvd250aWVyZWQgaW4gdGhpcyBpbnN0YW5jZQoKDQoFBAgC
BQUSBKYCAgcKDQoFBAgCBQESBKYCCBoKDQoFBAgCBQMSBKYCHR4KPgoEBAgCBhIEqQICJxow
IE51bWJlciBvZiBwYXJ0aWVzIHRoYXQgZmFpbGVkIHRvIGJlIGRvd250aWVyZWQKCg0KBQQI
AgYFEgSpAgIHCg0KBQQIAgYBEgSpAggiCg0KBQQIAgYDEgSpAiUmCkkKAgQJEgatAgC8AgEa
OyBSZXF1ZXN0IHRvIGV4cG9ydCBhIGxpc3Qgb2YgY3VycmVudGx5IHJlZ2lzdGVyZWQgcGFy
dGllcy4KCgsKAwQJARIErQIIJgqYAQoEBAkCABIGsAICtQIEGocBIFJlcXVpcmVkLiBUaGUg
ZnVsbCBwYXRoIHRvIHRoZSBJbnN0YW5jZSByZXNvdXJjZSBpbiB0aGlzIEFQSS4KIGZvcm1h
dDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMv
e2luc3RhbmNlfWAKCg0KBQQJAgAFEgSwAgIICg0KBQQJAgABEgSwAgkNCg0KBQQJAgADEgSw
AhARCg8KBQQJAgAIEgawAhK1AgMKEAoIBAkCAAicCAASBLECBCoKEQoHBAkCAAifCBIGsgIE
tAIFCkcKBAQJAgESBLgCAksaOSBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIHRvIG91dHB1dCB0
aGUgUmVnaXN0ZXJlZFBhcnRpZXMuCgoNCgUECQIBBhIEuAICFQoNCgUECQIBARIEuAIWHQoN
CgUECQIBAxIEuAIgIQoNCgUECQIBCBIEuAIiSgoQCggECQIBCJwIABIEuAIjSQpHCgQECQIC
EgS7AgJPGjkgUmVxdWlyZWQuIExpbmVPZkJ1c2luZXNzIHRvIGdldCBSZWdpc3RlcmVkUGFy
dGllcyBmcm9tLgoKDQoFBAkCAgYSBLsCAhAKDQoFBAkCAgESBLsCESEKDQoFBAkCAgMSBLsC
JCUKDQoFBAkCAggSBLsCJk4KEAoIBAkCAgicCAASBLsCJ00KPAoCBAoSBL8CACoaMCBSZXNw
b25zZSB0byBleHBvcnQgcmVnaXN0ZXJlZCBwYXJ0aWVzIHJlcXVlc3QuCgoLCgMECgESBL8C
CCdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.Instance.State)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.Instance.LabelsEntry)
    # Field: kms_key Type: 9 ()

# Enum: Instance::State
our $Instance_STATE_UNSPECIFIED = 0;
our $Instance_CREATING = 1;
our $Instance_ACTIVE = 2;
our $Instance_UPDATING = 3;
our $Instance_DELETING = 4;

# === Message: Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest ===
    # Fields for ListInstancesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse ===
    # Fields for ListInstancesResponse
    # Field: instances Type: 11 (.google.cloud.financialservices.v1.Instance)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest ===
    # Fields for GetInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest ===
    # Fields for CreateInstanceRequest
    # Field: parent Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: instance Type: 11 (.google.cloud.financialservices.v1.Instance)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest ===
    # Fields for UpdateInstanceRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: instance Type: 11 (.google.cloud.financialservices.v1.Instance)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest ===
    # Fields for DeleteInstanceRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest ===
    # Fields for ImportRegisteredPartiesRequest
    # Field: name Type: 9 ()
    # Field: party_tables Type: 9 ()
    # Field: mode Type: 14 (.google.cloud.financialservices.v1.ImportRegisteredPartiesRequest.UpdateMode)
    # Field: validate_only Type: 8 ()
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# Enum: ImportRegisteredPartiesRequest::UpdateMode
our $ImportRegisteredPartiesRequest_UPDATE_MODE_UNSPECIFIED = 0;
our $ImportRegisteredPartiesRequest_REPLACE = 1;
our $ImportRegisteredPartiesRequest_APPEND = 2;

# === Message: Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesResponse ===
    # Fields for ImportRegisteredPartiesResponse
    # Field: parties_added Type: 3 ()
    # Field: parties_removed Type: 3 ()
    # Field: parties_total Type: 3 ()
    # Field: parties_failed_to_remove Type: 3 ()
    # Field: parties_uptiered Type: 3 ()
    # Field: parties_downtiered Type: 3 ()
    # Field: parties_failed_to_downtier Type: 3 ()

# === Message: Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest ===
    # Fields for ExportRegisteredPartiesRequest
    # Field: name Type: 9 ()
    # Field: dataset Type: 11 (.google.cloud.financialservices.v1.BigQueryDestination)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# === Message: Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesResponse ===
    # Fields for ExportRegisteredPartiesResponse

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::Instance - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/instance.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::Instance;

    my $msg = Google::Cloud::Financialservices::V1::Instance::Instance->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::Instance::Instance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::Instance::Instance

Instance is a container for the rest of API resources.
Only resources in the same instance can interact with each other.
Child resources inherit the location (data residency) and encryption (CMEK).
The location of the provided input and output in requests must match the
location of the instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full path to the Instance resource in this API.
format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Instance was created.
Assigned by the server.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Instance was last updated.
Assigned by the server.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::Instance::State>)

Output only. State of the instance.
Assigned by the server.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Instance::Instance::LabelsEntry>)

Labels

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. The KMS key name used for CMEK (encryption-at-rest).
format:
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}`
VPC-SC restrictions apply.

=back

=head3 Enum: Instance::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest

Request for retrieving a paginated list of Instance resources that meet the
specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Instance is the location for that Instance.
Every location has exactly one instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListInstancesResponse. It should be copied here to retrieve the
next page of resources. This will be empty for the first instance of
ListInstancesRequest.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse

Response for retrieving a list of Instances

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Instance::Instance>)

List of Instance resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListInstancesRequest to retrieve
the next page of Instances.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest

Request for retrieving a specific Instance resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Instance.

=back

=head2 Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest

Request for creating a Instance resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Instance is the location for that Instance.
Every location has exactly one instance.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Required. The resource id of the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Instance::Instance>)

Required. The instance that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest

Request for updating a Instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Instance resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Instance::Instance>)

Required. The new value of the instance fields that will be updated
according to the update_mask

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest

Request for deleting a Instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Instance.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest

Request for adding/removing registered parties from BigQuery tables
specified by the customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full path to the Instance resource in this API.
format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->party_tables() >> / C<< $msg->party_tables($value) >>

Type: C<String>

Optional. List of BigQuery tables. Union of tables will be taken if there
is more than one table. VPC-SC restrictions apply. format:
`bq://{project}.{bqDatasetID}.{bqTableID}` Use of `datasets` is preferred
over the latter due to its simplicity and the reduced risk of errors
`party_tables` and `datasets` must not be provided at the
same time

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::ImportRegisteredPartiesRequest::UpdateMode>)

Required. Mode of the request.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If the request will not register the parties, just determine what
would happen.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Required. LineOfBusiness for the specified registered parties.

=back

=head3 Enum: ImportRegisteredPartiesRequest::UpdateMode

=over 4

=item * C<UPDATE_MODE_UNSPECIFIED> => C<0>

=item * C<REPLACE> => C<1>

=item * C<APPEND> => C<2>

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesResponse

Response for adding/removing registered parties from BigQuery tables.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parties_added() >> / C<< $msg->parties_added($value) >>

Type: C<Int64>

Number of parties added by this operation.

=item * C<< $msg->parties_removed() >> / C<< $msg->parties_removed($value) >>

Type: C<Int64>

Number of parties removed by this operation.

=item * C<< $msg->parties_total() >> / C<< $msg->parties_total($value) >>

Type: C<Int64>

Total number of parties that are registered in this instance, after the
update operation was completed.

=item * C<< $msg->parties_failed_to_remove() >> / C<< $msg->parties_failed_to_remove($value) >>

Type: C<Int64>

Number of parties that failed to be removed by this operation.

=item * C<< $msg->parties_uptiered() >> / C<< $msg->parties_uptiered($value) >>

Type: C<Int64>

=item * C<< $msg->parties_downtiered() >> / C<< $msg->parties_downtiered($value) >>

Type: C<Int64>

Total number of parties that are downtiered in this instance

=item * C<< $msg->parties_failed_to_downtier() >> / C<< $msg->parties_failed_to_downtier($value) >>

Type: C<Int64>

Number of parties that failed to be downtiered

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest

Request to export a list of currently registered parties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full path to the Instance resource in this API.
format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination>)

Required. The location to output the RegisteredParties.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Required. LineOfBusiness to get RegisteredParties from.

=back

=head2 Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesResponse

Response to export registered parties request.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
