package Google::Cloud::Backupdr::V1beta::ProtectionSummary;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL3Byb3RlY3Rpb25fc3VtbWFyeS5wcm90
bxIcZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLoAQogTGlz
dFJlc291cmNlQmFja3VwQ29uZmlnc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMK
IWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6
ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VU
b2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPg
QQFSB29yZGVyQnkitwEKIUxpc3RSZXNvdXJjZUJhY2t1cENvbmZpZ3NSZXNwb25zZRJqChdy
ZXNvdXJjZV9iYWNrdXBfY29uZmlncxgBIAMoCzIyLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MWJldGEuUmVzb3VyY2VCYWNrdXBDb25maWdSFXJlc291cmNlQmFja3VwQ29uZmlncxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ilggKFFJlc291cmNlQmFja3Vw
Q29uZmlnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIdCgN1aWQYAiABKAlCC+KMz9cIAggB
4EEDUgN1aWQSLAoPdGFyZ2V0X3Jlc291cmNlGAMgASgJQgPgQQNSDnRhcmdldFJlc291cmNl
EkQKHHRhcmdldF9yZXNvdXJjZV9kaXNwbGF5X25hbWUYBCABKAlCA+BBA1IZdGFyZ2V0UmVz
b3VyY2VEaXNwbGF5TmFtZRJ2ChR0YXJnZXRfcmVzb3VyY2VfdHlwZRgFIAEoDjI/Lmdvb2ds
ZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzb3VyY2VCYWNrdXBDb25maWcuUmVzb3VyY2VU
eXBlQgPgQQNSEnRhcmdldFJlc291cmNlVHlwZRKCAQoWdGFyZ2V0X3Jlc291cmNlX2xhYmVs
cxgGIAMoCzJMLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzb3VyY2VCYWNrdXBD
b25maWcuVGFyZ2V0UmVzb3VyY2VMYWJlbHNFbnRyeVIUdGFyZ2V0UmVzb3VyY2VMYWJlbHMS
ZwoWYmFja3VwX2NvbmZpZ3NfZGV0YWlscxgHIAMoCzIxLmdvb2dsZS5jbG91ZC5iYWNrdXBk
ci52MWJldGEuQmFja3VwQ29uZmlnRGV0YWlsc1IUYmFja3VwQ29uZmlnc0RldGFpbHMSMAoR
YmFja3VwX2NvbmZpZ3VyZWQYCCABKAhCA+BBA1IQYmFja3VwQ29uZmlndXJlZBIdCgd2YXVs
dGVkGAkgASgIQgPgQQNSB3ZhdWx0ZWQaRwoZVGFyZ2V0UmVzb3VyY2VMYWJlbHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIpcBCgxSZXNvdXJj
ZVR5cGUSHQoZUkVTT1VSQ0VfVFlQRV9VTlNQRUNJRklFRBAAEhYKEkNMT1VEX1NRTF9JTlNU
QU5DRRABEhUKEUNPTVBVVEVfRU5HSU5FX1ZNEAISFwoTQ09NUFVURV9FTkdJTkVfRElTSxAD
EiAKHENPTVBVVEVfRU5HSU5FX1JFR0lPTkFMX0RJU0sQBDq3AepBswEKLGJhY2t1cGRyLmdv
b2dsZWFwaXMuY29tL1Jlc291cmNlQmFja3VwQ29uZmlnElZwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzb3VyY2VCYWNrdXBDb25maWdzL3tyZXNvdXJjZV9i
YWNrdXBfY29uZmlnfSoVcmVzb3VyY2VCYWNrdXBDb25maWdzMhRyZXNvdXJjZUJhY2t1cENv
bmZpZyKCCQoTQmFja3VwQ29uZmlnRGV0YWlscxJlChViYWNrdXBfZHJfcGxhbl9jb25maWcY
CiABKAsyMC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkJhY2t1cERyUGxhbkNvbmZp
Z0gAUhJiYWNrdXBEclBsYW5Db25maWcScQoZYmFja3VwX2RyX3RlbXBsYXRlX2NvbmZpZxgL
IAEoCzI0Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuQmFja3VwRHJUZW1wbGF0ZUNv
bmZpZ0gAUhZiYWNrdXBEclRlbXBsYXRlQ29uZmlnEjUKFGJhY2t1cF9jb25maWdfc291cmNl
GAEgASgJQgPgQQNSEmJhY2t1cENvbmZpZ1NvdXJjZRJNCiFiYWNrdXBfY29uZmlnX3NvdXJj
ZV9kaXNwbGF5X25hbWUYAiABKAlCA+BBA1IdYmFja3VwQ29uZmlnU291cmNlRGlzcGxheU5h
bWUSTwoEdHlwZRgDIAEoDjI2Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuQmFja3Vw
Q29uZmlnRGV0YWlscy5UeXBlQgPgQQNSBHR5cGUSUgoFc3RhdGUYBCABKA4yNy5nb29nbGUu
Y2xvdWQuYmFja3VwZHIudjFiZXRhLkJhY2t1cENvbmZpZ0RldGFpbHMuU3RhdGVCA+BBA1IF
c3RhdGUSVAoNcGl0cl9zZXR0aW5ncxgFIAEoCzIqLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MWJldGEuUGl0clNldHRpbmdzQgPgQQNSDHBpdHJTZXR0aW5ncxJiCh1sYXRlc3Rfc3VjY2Vz
c2Z1bF9iYWNrdXBfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IabGF0ZXN0U3VjY2Vzc2Z1bEJhY2t1cFRpbWUSNAoTYXBwbGljYWJsZV9yZXNvdXJjZRgH
IAEoCUID4EEDUhJhcHBsaWNhYmxlUmVzb3VyY2USJgoMYmFja3VwX3ZhdWx0GAggASgJQgPg
QQNSC2JhY2t1cFZhdWx0ElcKEGJhY2t1cF9sb2NhdGlvbnMYDCADKAsyLC5nb29nbGUuY2xv
dWQuYmFja3VwZHIudjFiZXRhLkJhY2t1cExvY2F0aW9uUg9iYWNrdXBMb2NhdGlvbnMilwEK
BFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEiQKIENMT1VEX1NRTF9JTlNUQU5DRV9CQUNL
VVBfQ09ORklHEAESIgoeQ09NUFVURV9FTkdJTkVfUkVTT1VSQ0VfUE9MSUNZEAISGAoUQkFD
S1VQRFJfQkFDS1VQX1BMQU4QAxIVChFCQUNLVVBEUl9URU1QTEFURRAEIkMKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESDAoISU5BQ1RJVkUQAhIJCgVFUlJP
UhADQhYKFHBsYW5fc3BlY2lmaWNfY29uZmlnIjoKDFBpdHJTZXR0aW5ncxIqCg5yZXRlbnRp
b25fZGF5cxgBIAEoBUID4EEDUg1yZXRlbnRpb25EYXlzIpwBChZCYWNrdXBEclRlbXBsYXRl
Q29uZmlnEkAKGmZpcnN0X3BhcnR5X21hbmFnZW1lbnRfdXJpGAEgASgJQgPgQQNSF2ZpcnN0
UGFydHlNYW5hZ2VtZW50VXJpEkAKGnRoaXJkX3BhcnR5X21hbmFnZW1lbnRfdXJpGAIgASgJ
QgPgQQNSF3RoaXJkUGFydHlNYW5hZ2VtZW50VXJpInUKEkJhY2t1cERyUGxhbkNvbmZpZxJf
ChRiYWNrdXBfZHJfcGxhbl9ydWxlcxgBIAMoCzIuLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MWJldGEuQmFja3VwRHJQbGFuUnVsZVIRYmFja3VwRHJQbGFuUnVsZXMikAEKEEJhY2t1cERy
UGxhblJ1bGUSHAoHcnVsZV9pZBgBIAEoCUID4EEDUgZydWxlSWQSXgobbGFzdF9zdWNjZXNz
ZnVsX2JhY2t1cF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UhhsYXN0U3VjY2Vzc2Z1bEJhY2t1cFRpbWUizQEKDkJhY2t1cExvY2F0aW9uEkoKBHR5cGUY
ASABKA4yMS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkJhY2t1cExvY2F0aW9uLlR5
cGVCA+BBA1IEdHlwZRIkCgtsb2NhdGlvbl9pZBgCIAEoCUID4EEDUgpsb2NhdGlvbklkIkkK
BFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEgkKBVpPTkFMEAESDAoIUkVHSU9OQUwQAhIS
Cg5NVUxUSV9SRUdJT05BTBADMoYDChlCYWNrdXBEclByb3RlY3Rpb25TdW1tYXJ5EuwBChlM
aXN0UmVzb3VyY2VCYWNrdXBDb25maWdzEj4uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0
YS5MaXN0UmVzb3VyY2VCYWNrdXBDb25maWdzUmVxdWVzdBo/Lmdvb2dsZS5jbG91ZC5iYWNr
dXBkci52MWJldGEuTGlzdFJlc291cmNlQmFja3VwQ29uZmlnc1Jlc3BvbnNlIk6C0+STAj8S
PS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9yZXNvdXJjZUJhY2t1
cENvbmZpZ3PaQQZwYXJlbnQaespBF2JhY2t1cGRyLmdvb2dsZWFwaXMuY29t0kFdaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1iYWNrdXBkcixodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtoBCiBjb20uZ29vZ2xlLmNsb3Vk
LmJhY2t1cGRyLnYxYmV0YUIWUHJvdGVjdGlvblN1bW1hcnlQcm90b1ABWjxjbG91ZC5nb29n
bGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxYmV0YS9iYWNrdXBkcnBiO2JhY2t1cGRycGKqAhxH
b29nbGUuQ2xvdWQuQmFja3VwRFIuVjFCZXRhygIcR29vZ2xlXENsb3VkXEJhY2t1cERSXFYx
YmV0YeoCH0dvb2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMWJldGFKul0KBxIFDgDDAgEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAJQoJCgIDBBIDFgAjCgkKAgMFEgMXACkK
CAoBCBIDGQA5CgkKAgglEgMZADkKCAoBCBIDGgBTCgkKAggLEgMaAFMKCAoBCBIDGwAiCgkK
AggKEgMbACIKCAoBCBIDHAA3CgkKAggIEgMcADcKCAoBCBIDHQA5CgkKAggBEgMdADkKCAoB
CBIDHgA5CgkKAggpEgMeADkKCAoBCBIDHwA4CgkKAggtEgMfADgKLQoCBgASBCIAMQEaISBU
aGUgUHJvdGVjdGlvbiBTdW1tYXJ5IHNlcnZpY2UuCgoKCgMGAAESAyIIIQoKCgMGAAMSAyMC
PwoMCgUGAAOZCBIDIwI/CgsKAwYAAxIEJAImNwoNCgUGAAOaCBIEJAImNwosCgQGAAIAEgQp
Ai8DGh4gTGlzdHMgUmVzb3VyY2VCYWNrdXBDb25maWdzLgoKDAoFBgACAAESAykGHwoMCgUG
AAIAAhIDKSBACgwKBQYAAgADEgMqDzAKDQoFBgACAAQSBCsELQYKEQoJBgACAASwyrwiEgQr
BC0GCgwKBQYAAgAEEgMuBDQKDwoIBgACAASbCAASAy4ENAo0CgIEABIENABNARooIFJlcXVl
c3QgZm9yIExpc3RSZXNvdXJjZUJhY2t1cENvbmZpZ3MuCgoKCgMEAAESAzQIKAr+AQoEBAAC
ABIEOQI+BBrvASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZvciB3aGlj
aCB0byByZXRyaWV2ZSByZXNvdXJjZSBiYWNrdXAKIGNvbmZpZ3MuIEZvcm1hdDogJ3Byb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufScuIEluIEdvb2dsZQogQ2xv
dWQgQmFja3VwIGFuZCBEUiwgbG9jYXRpb25zIG1hcCB0byBHb29nbGUgQ2xvdWQgcmVnaW9u
cywgZm9yIGV4YW1wbGUKICoqdXMtY2VudHJhbDEqKi4KCgwKBQQAAgAFEgM5AggKDAoFBAAC
AAESAzkJDwoMCgUEAAIAAxIDORITCg0KBQQAAgAIEgQ5FD4DCg8KCAQAAgAInAgAEgM6BCoK
DwoHBAACAAifCBIEOwQ9BQrQAQoEBAACARIDQwI/GsIBIE9wdGlvbmFsLiBSZXF1ZXN0ZWQg
cGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0
ZWQuIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCB1c2UgMTAwIGFzIGRlZmF1bHQuIE1h
eGltdW0gdmFsdWUgaXMKIDUwMCBhbmQgdmFsdWVzIGFib3ZlIDUwMCB3aWxsIGJlIGNvZXJj
ZWQgdG8gNTAwLgoKDAoFBAACAQUSA0MCBwoMCgUEAAIBARIDQwgRCgwKBQQAAgEDEgNDFBUK
DAoFBAACAQgSA0MWPgoPCggEAAIBCJwIABIDQxc9ClgKBAQAAgISA0YCQRpLIE9wdGlvbmFs
LiBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hv
dWxkIHJldHVybi4KCgwKBQQAAgIFEgNGAggKDAoFBAACAgESA0YJEwoMCgUEAAICAxIDRhYX
CgwKBQQAAgIIEgNGGEAKDwoIBAACAgicCAASA0YZPworCgQEAAIDEgNJAj0aHiBPcHRpb25h
bC4gRmlsdGVyaW5nIHJlc3VsdHMuCgoMCgUEAAIDBRIDSQIICgwKBQQAAgMBEgNJCQ8KDAoF
BAACAwMSA0kSEwoMCgUEAAIDCBIDSRQ8Cg8KCAQAAgMInAgAEgNJFTsKOwoEBAACBBIDTAI/
Gi4gT3B0aW9uYWwuIEhpbnQgZm9yIGhvdyB0byBvcmRlciB0aGUgcmVzdWx0cy4KCgwKBQQA
AgQFEgNMAggKDAoFBAACBAESA0wJEQoMCgUEAAIEAxIDTBQVCgwKBQQAAgQIEgNMFj4KDwoI
BAACBAicCAASA0wXPQo1CgIEARIEUABWARopIFJlc3BvbnNlIGZvciBMaXN0UmVzb3VyY2VC
YWNrdXBDb25maWdzLgoKCgoDBAEBEgNQCCkKSQoEBAECABIDUgI8GjwgVGhlIGxpc3Qgb2Yg
UmVzb3VyY2VCYWNrdXBDb25maWdzIGZvciB0aGUgc3BlY2lmaWVkIHNjb3BlLgoKDAoFBAEC
AAQSA1ICCgoMCgUEAQIABhIDUgsfCgwKBQQBAgABEgNSIDcKDAoFBAECAAMSA1I6OwpOCgQE
AQIBEgNVAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBz
ZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQBAgEFEgNVAggKDAoFBAECAQESA1UJGAoMCgUE
AQIBAxIDVRscCmAKAgQCEgVaAKIBARpTIFJlc291cmNlQmFja3VwQ29uZmlnIHJlcHJlc2Vu
dHMgYSByZXNvdXJjZSBhbG9uZyB3aXRoIGl0cyBiYWNrdXAKIGNvbmZpZ3VyYXRpb25zLgoK
CgoDBAIBEgNaCBwKCwoDBAIHEgRbAmAECg0KBQQCB50IEgRbAmAECi8KBAQCBAASBGMCcgMa
ISBUaGUgdHlwZSBvZiB0aGUgY2xvdWQgcmVzb3VyY2UuCgoMCgUEAgQAARIDYwcTCicKBgQC
BAACABIDZQQiGhggUmVzb3VyY2UgdHlwZSBub3Qgc2V0LgoKDgoHBAIEAAIAARIDZQQdCg4K
BwQCBAACAAISA2UgIQokCgYEAgQAAgESA2gEGxoVIENsb3VkIFNRTCBpbnN0YW5jZS4KCg4K
BwQCBAACAQESA2gEFgoOCgcEAgQAAgECEgNoGRoKIwoGBAIEAAICEgNrBBoaFCBDb21wdXRl
IEVuZ2luZSBWTS4KCg4KBwQCBAACAgESA2sEFQoOCgcEAgQAAgICEgNrGBkKJQoGBAIEAAID
EgNuBBwaFiBDb21wdXRlIEVuZ2luZSBEaXNrLgoKDgoHBAIEAAIDARIDbgQXCg4KBwQCBAAC
AwISA24aGwouCgYEAgQAAgQSA3EEJRofIENvbXB1dGUgRW5naW5lIFJlZ2lvbmFsIERpc2su
CgoOCgcEAgQAAgQBEgNxBCAKDgoHBAIEAAIEAhIDcSMkCpgBCgQEAgIAEgN3Aj0aigEgSWRl
bnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFJlc291cmNlQmFja3VwQ29uZmln
LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
c291cmNlQmFja3VwQ29uZmlncy97dWlkfQoKDAoFBAICAAUSA3cCCAoMCgUEAgIAARIDdwkN
CgwKBQQCAgADEgN3EBEKDAoFBAICAAgSA3cSPAoPCggEAgIACJwIABIDdxM7ClEKBAQCAgES
BHoCfQQaQyBPdXRwdXQgb25seS4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSByZXNv
dXJjZSBiYWNrdXAgY29uZmlnLgoKDAoFBAICAQUSA3oCCAoMCgUEAgIBARIDegkMCgwKBQQC
AgEDEgN6DxAKDQoFBAICAQgSBHoRfQMKEgoLBAICAQjM8fmKAQESA3sEKgoPCggEAgIBCJwI
ABIDfAQtCroCCgQEAgICEgSEAQJJGqsCIE91dHB1dCBvbmx5LiBUaGUgW2Z1bGwgcmVzb3Vy
Y2UKIG5hbWVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hc3NldC1pbnZlbnRvcnkvZG9j
cy9yZXNvdXJjZS1uYW1lLWZvcm1hdCkKIG9mIHRoZSBjbG91ZCByZXNvdXJjZSB0aGF0IHRo
aXMgY29uZmlndXJhdGlvbiBhcHBsaWVzIHRvLiBTdXBwb3J0ZWQKIHJlc291cmNlIHR5cGVz
IGFyZQogW1Jlc291cmNlQmFja3VwQ29uZmlnLlJlc291cmNlVHlwZV1bZ29vZ2xlLmNsb3Vk
LmJhY2t1cGRyLnYxYmV0YS5SZXNvdXJjZUJhY2t1cENvbmZpZy5SZXNvdXJjZVR5cGVdLgoK
DQoFBAICAgUSBIQBAggKDQoFBAICAgESBIQBCRgKDQoFBAICAgMSBIQBGxwKDQoFBAICAggS
BIQBHUgKEAoIBAICAgicCAASBIQBHkcKTgoEBAICAxIGhwECiAEyGj4gT3V0cHV0IG9ubHku
IFRoZSBodW1hbiBmcmllbmRseSBuYW1lIG9mIHRoZSB0YXJnZXQgcmVzb3VyY2UuCgoNCgUE
AgIDBRIEhwECCAoNCgUEAgIDARIEhwEJJQoNCgUEAgIDAxIEhwEoKQoNCgUEAgIDCBIEiAEG
MQoQCggEAgIDCJwIABIEiAEHMAo/CgQEAgIEEgaLAQKMATIaLyBPdXRwdXQgb25seS4gVGhl
IHR5cGUgb2YgdGhlIHRhcmdldCByZXNvdXJjZS4KCg0KBQQCAgQGEgSLAQIOCg0KBQQCAgQB
EgSLAQ8jCg0KBQQCAgQDEgSLASYnCg0KBQQCAgQIEgSMAQYxChAKCAQCAgQInAgAEgSMAQcw
CjsKBAQCAgUSBI8BAjEaLSBMYWJlbHMgYXNzb2NpYXRlZCB3aXRoIHRoZSB0YXJnZXQgcmVz
b3VyY2UuCgoNCgUEAgIFBhIEjwECFQoNCgUEAgIFARIEjwEWLAoNCgUEAgIFAxIEjwEvMAqd
AgoEBAICBhIElQECOhqOAiBCYWNrdXAgY29uZmlndXJhdGlvbnMgYXBwbHlpbmcgdG8gdGhl
IHRhcmdldCByZXNvdXJjZSwgaW5jbHVkaW5nIHRob3NlCiB0YXJnZXRpbmcgaXRzIHJlbGF0
ZWQvY2hpbGQgcmVzb3VyY2VzLiBGb3IgZXhhbXBsZSwgYmFja3VwIGNvbmZpZ3VyYXRpb24K
IGFwcGxpY2FibGUgdG8gQ29tcHV0ZSBFbmdpbmUgZGlza3Mgd2lsbCBiZSBwb3B1bGF0ZWQg
aW4gdGhpcyBmaWVsZCBmb3IgYQogQ29tcHV0ZSBFbmdpbmUgVk0gd2hpY2ggaGFzIHRoZSBk
aXNrIGFzc29jaWF0ZWQuCgoNCgUEAgIGBBIElQECCgoNCgUEAgIGBhIElQELHgoNCgUEAgIG
ARIElQEfNQoNCgUEAgIGAxIElQE4OQqMAQoEBAICBxIEmQECSRp+IE91dHB1dCBvbmx5LiBX
aGV0aGVyIHRoZSB0YXJnZXQgcmVzb3VyY2UgaXMgY29uZmlndXJlZCBmb3IgYmFja3VwLiBU
aGlzIGlzCiB0cnVlIGlmIHRoZSBiYWNrdXBfY29uZmlnc19kZXRhaWxzIGlzIG5vdCBlbXB0
eS4KCg0KBQQCAgcFEgSZAQIGCg0KBQQCAgcBEgSZAQcYCg0KBQQCAgcDEgSZARscCg0KBQQC
AgcIEgSZAR1IChAKCAQCAgcInAgAEgSZAR5HCqQDCgQEAgIIEgShAQI/GpUDIE91dHB1dCBv
bmx5LiBXaGV0aGVyIHRoZSB0YXJnZXQgcmVzb3VyY2UgaXMgcHJvdGVjdGVkIGJ5IGEgYmFj
a3VwIHZhdWx0LgogVGhpcyBpcyB0cnVlIGlmIHRoZSBiYWNrdXBfY29uZmlnc19kZXRhaWxz
IGlzIG5vdCBlbXB0eSBhbmQgYW55IG9mIHRoZQogW1Jlc291cmNlQmFja3VwQ29uZmlnLmJh
Y2t1cF9jb25maWdzX2RldGFpbHNdW2dvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVz
b3VyY2VCYWNrdXBDb25maWcuYmFja3VwX2NvbmZpZ3NfZGV0YWlsc10KIGhhcyBhIGJhY2t1
cCBjb25maWd1cmF0aW9uIHdpdGgKIFtCYWNrdXBDb25maWdEZXRhaWxzLmJhY2t1cF92YXVs
dF1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5CYWNrdXBDb25maWdEZXRhaWxzLmJh
Y2t1cF92YXVsdF0KIHNldC4KCg0KBQQCAggFEgShAQIGCg0KBQQCAggBEgShAQcOCg0KBQQC
AggDEgShARESCg0KBQQCAggIEgShARM+ChAKCAQCAggInAgAEgShARQ9CqUBCgIEAxIGpgEA
hQIBGpYBIEJhY2t1cENvbmZpZ0RldGFpbHMgaGFzIGluZm9ybWF0aW9uIGFib3V0IGhvdyB0
aGUgcmVzb3VyY2UgaXMgY29uZmlndXJlZAogZm9yIGJhY2t1cHMgYW5kIGFib3V0IHRoZSBt
b3N0IHJlY2VudCBiYWNrdXAgdGFrZW4gZm9yIHRoaXMgY29uZmlndXJhdGlvbi4KCgsKAwQD
ARIEpgEIGwpkCgQEAwQAEgapAQK4AQMaVCBUeXBlIG9mIHRoZSBiYWNrdXAgY29uZmlndXJh
dGlvbi4KIFRoaXMgZW51bSBtYXkgcmVjZWl2ZSBuZXcgdmFsdWVzIGluIHRoZSBmdXR1cmUu
CgoNCgUEAwQAARIEqQEHCwo0CgYEAwQAAgASBKsBBBkaJCBCYWNrdXAgY29uZmlnIHR5cGUg
aXMgdW5zcGVjaWZpZWQuCgoPCgcEAwQAAgABEgSrAQQUCg8KBwQDBAACAAISBKsBFxgKUAoG
BAMEAAIBEgSuAQQpGkAgQmFja3VwIGNvbmZpZyBpcyBDbG91ZCBTUUwgaW5zdGFuY2UncyBh
dXRvbWF0ZWQgYmFja3VwIGNvbmZpZy4KCg8KBwQDBAACAQESBK4BBCQKDwoHBAMEAAIBAhIE
rgEnKApCCgYEAwQAAgISBLEBBCcaMiBCYWNrdXAgY29uZmlnIGlzIENvbXB1dGUgRW5naW5l
IFJlc291cmNlIFBvbGljeS4KCg8KBwQDBAACAgESBLEBBCIKDwoHBAMEAAICAhIEsQElJgpM
CgYEAwQAAgMSBLQBBB0aPCBCYWNrdXAgY29uZmlnIGlzIEdvb2dsZSBDbG91ZCBCYWNrdXAg
YW5kIERSJ3MgQmFja3VwIFBsYW4uCgoPCgcEAwQAAgMBEgS0AQQYCg8KBwQDBAACAwISBLQB
GxwKSQoGBAMEAAIEEgS3AQQaGjkgQmFja3VwIGNvbmZpZyBpcyBHb29nbGUgQ2xvdWQgQmFj
a3VwIGFuZCBEUidzIFRlbXBsYXRlLgoKDwoHBAMEAAIEARIEtwEEFQoPCgcEAwQAAgQCEgS3
ARgZCk0KBAQDBAESBrsBAssBAxo9IFRoZSBzdGF0ZSB0ZWxscyB3aGV0aGVyIHRoZSBiYWNr
dXAgY29uZmlnIGlzIGFjdGl2ZSBvciBub3QuCgoNCgUEAwQBARIEuwEHDAouCgYEAwQBAgAS
BL0BBBoaHiBCYWNrdXAgY29uZmlnIHN0YXRlIG5vdCBzZXQuCgoPCgcEAwQBAgABEgS9AQQV
Cg8KBwQDBAECAAISBL0BGBkKSgoGBAMEAQIBEgTAAQQPGjogVGhlIGNvbmZpZyBpcyBpbiBh
biBhY3RpdmUgc3RhdGUgcHJvdGVjdGluZyB0aGUgcmVzb3VyY2UKCg8KBwQDBAECAQESBMAB
BAoKDwoHBAMEAQIBAhIEwAENDgq2AQoGBAMEAQICEgTFAQQRGqUBIFRoZSBjb25maWcgaXMg
Y3VycmVudGx5IG5vdCBwcm90ZWN0aW5nIHRoZSByZXNvdXJjZS4gRWl0aGVyIGJlY2F1c2Ug
aXQgaXMKIGRpc2FibGVkIG9yIHRoZSBvd25pbmcgcHJvamVjdCBoYXMgYmVlbiBkZWxldGVk
IHdpdGhvdXQgY2xlYW51cCBvZiB0aGUKIGFjdHVhbCByZXNvdXJjZS4KCg8KBwQDBAECAgES
BMUBBAwKDwoHBAMEAQICAhIExQEPEArDAQoGBAMEAQIDEgTKAQQOGrIBIFRoZSBjb25maWcg
c3RpbGwgZXhpc3RzIGJ1dCBiZWNhdXNlIG9mIHNvbWUgZXJyb3Igc3RhdGUgaXQgaXMgbm90
CiBwcm90ZWN0aW5nIHRoZSByZXNvdXJjZS4gTGlrZSB0aGUgc291cmNlIHByb2plY3QgaXMg
ZGVsZXRlZC4gRm9yIGVnLgogUGxhbkFzc29jaWF0aW9uLCBCYWNrdXBQbGFuIGlzIGRlbGV0
ZWQuCgoPCgcEAwQBAgMBEgTKAQQJCg8KBwQDBAECAwISBMoBDA0K0QMKBAQDCAASBtQBAtoB
AxrAAyBUaGUgcGxhbiBzcGVjaWZpYyBjb25maWcuIFRoaXMgZGVwZW5kcyBvbiB0aGUgdmFs
dWUgb2YKIFtCYWNrdXBDb25maWdEZXRhaWxzLnR5cGVdW2dvb2dsZS5jbG91ZC5iYWNrdXBk
ci52MWJldGEuQmFja3VwQ29uZmlnRGV0YWlscy50eXBlXS4KIEZvciB0eXBlPUJBQ0tVUERS
X0JBQ0tVUF9QTEFOLCBiYWNrdXBfZHJfcGxhbl9jb25maWcgd291bGQgYmUgcG9wdWxhdGVk
IHRvCiBjYXB0dXJlIGluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gR29vZ2xlIENsb3VkIEJhY2t1
cCBhbmQgRFIncyBCYWNrdXAgUGxhbnMuCiBGb3IgdHlwZT1CQUNLVVBEUl9URU1QTEFURSwg
YmFja3VwX2RyX3RlbXBsYXRlX2NvbmZpZyB3b3VsZCBiZSBwb3B1bGF0ZWQgdG8KIGNhcHR1
cmUgaW5mb3JtYXRpb24gcmVsYXRlZCB0byBHb29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUidz
IFRlbXBsYXRlCiBkZXRhaWxzLgoKDQoFBAMIAAESBNQBCBwKRwoEBAMCABIE1gEEMho5IEdv
b2dsZSBDbG91ZCBCYWNrdXAgYW5kIERSJ3MgQmFja3VwIFBsYW4gc3BlY2lmaWMgZGF0YS4K
Cg0KBQQDAgAGEgTWAQQWCg0KBQQDAgABEgTWARcsCg0KBQQDAgADEgTWAS8xCkQKBAQDAgES
BNkBBDoaNiBHb29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUidzIFRlbXBsYXRlIHNwZWNpZmlj
IGRhdGEuCgoNCgUEAwIBBhIE2QEEGgoNCgUEAwIBARIE2QEbNAoNCgUEAwIBAxIE2QE3OQq0
AgoEBAMCAhIE4QECThqlAiBPdXRwdXQgb25seS4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgYmFja3VwIGNvbmZpZyBzb3VyY2UgcmVzb3VyY2UuCiBGb3IgZXhhbXBsZSwKICIv
L2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL3YxL3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve3JlZ2lvbn0vYmFja3VwUGxhbnMve2JhY2t1cHBsYW5JZH0iCiBvcgogIi8vY29tcHV0
ZS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259
L3Jlc291cmNlUG9saWNpZXMve3Jlc291cmNlUG9saWN5SWR9Ii4KCg0KBQQDAgIFEgThAQII
Cg0KBQQDAgIBEgThAQkdCg0KBQQDAgIDEgThASAhCg0KBQQDAgIIEgThASJNChAKCAQDAgII
nAgAEgThASNMClUKBAQDAgMSBuQBAuUBMhpFIE91dHB1dCBvbmx5LiBUaGUgZGlzcGxheSBu
YW1lIG9mIHRoZSBiYWNrdXAgY29uZmlnIHNvdXJjZSByZXNvdXJjZS4KCg0KBQQDAgMFEgTk
AQIICg0KBQQDAgMBEgTkAQkqCg0KBQQDAgMDEgTkAS0uCg0KBQQDAgMIEgTlAQYxChAKCAQD
AgMInAgAEgTlAQcwCkQKBAQDAgQSBOgBAjwaNiBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2Yg
dGhlIGJhY2t1cCBjb25maWcgcmVzb3VyY2UuCgoNCgUEAwIEBhIE6AECBgoNCgUEAwIEARIE
6AEHCwoNCgUEAwIEAxIE6AEODwoNCgUEAwIECBIE6AEQOwoQCggEAwIECJwIABIE6AEROgpF
CgQEAwIFEgTrAQI+GjcgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgYmFja3VwIGNv
bmZpZyByZXNvdXJjZS4KCg0KBQQDAgUGEgTrAQIHCg0KBQQDAgUBEgTrAQgNCg0KBQQDAgUD
EgTrARARCg0KBQQDAgUIEgTrARI9ChAKCAQDAgUInAgAEgTrARM8CmMKBAQDAgYSBO8BAk0a
VSBPdXRwdXQgb25seS4gUG9pbnQgaW4gdGltZSByZWNvdmVyeSBzZXR0aW5ncyBvZiB0aGUg
YmFja3VwIGNvbmZpZ3VyYXRpb24KIHJlc291cmNlLgoKDQoFBAMCBgYSBO8BAg4KDQoFBAMC
BgESBO8BDxwKDQoFBAMCBgMSBO8BHyAKDQoFBAMCBggSBO8BIUwKEAoIBAMCBgicCAASBO8B
IksKcAoEBAMCBxIG8wEC9AEyGmAgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCBvZiB0aGUgbGF0
ZXN0IHN1Y2Nlc3NmdWwgYmFja3VwIGNyZWF0ZWQgdmlhIHRoaXMKIGJhY2t1cCBjb25maWd1
cmF0aW9uLgoKDQoFBAMCBwYSBPMBAhsKDQoFBAMCBwESBPMBHDkKDQoFBAMCBwMSBPMBPD0K
DQoFBAMCBwgSBPQBBjEKEAoIBAMCBwicCAASBPQBBzAKlwIKBAQDAggSBPoBAk0aiAIgT3V0
cHV0IG9ubHkuIFRoZSBbZnVsbCByZXNvdXJjZQogbmFtZV0oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2Fzc2V0LWludmVudG9yeS9kb2NzL3Jlc291cmNlLW5hbWUtZm9ybWF0KQogb2Yg
dGhlIHJlc291cmNlIHRoYXQgaXMgYXBwbGljYWJsZSBmb3IgdGhlIGJhY2t1cCBjb25maWd1
cmF0aW9uLiBFeGFtcGxlOgogIi8vY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy97
cHJvamVjdH0vem9uZXMve3pvbmV9L2luc3RhbmNlcy97aW5zdGFuY2V9IgoKDQoFBAMCCAUS
BPoBAggKDQoFBAMCCAESBPoBCRwKDQoFBAMCCAMSBPoBHyAKDQoFBAMCCAgSBPoBIUwKEAoI
BAMCCAicCAASBPoBIksKxgIKBAQDAgkSBIECAkYatwIgT3V0cHV0IG9ubHkuIFRoZSBbZnVs
bCByZXNvdXJjZQogbmFtZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2Fzc2V0LWludmVu
dG9yeS9kb2NzL3Jlc291cmNlLW5hbWUtZm9ybWF0KQogb2YgdGhlIGJhY2t1cCB2YXVsdCB0
aGF0IHdpbGwgc3RvcmUgdGhlIGJhY2t1cHMgZ2VuZXJhdGVkIHRocm91Z2ggdGhpcwogYmFj
a3VwIGNvbmZpZ3VyYXRpb24uIEV4YW1wbGU6CiAiLy9iYWNrdXBkci5nb29nbGVhcGlzLmNv
bS92MS9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259L2JhY2t1cFZhdWx0
cy97YmFja3VwdmF1bHRJZH0iCgoNCgUEAwIJBRIEgQICCAoNCgUEAwIJARIEgQIJFQoNCgUE
AwIJAxIEgQIYGQoNCgUEAwIJCBIEgQIaRQoQCggEAwIJCJwIABIEgQIbRApBCgQEAwIKEgSE
AgIwGjMgVGhlIGxvY2F0aW9ucyB3aGVyZSB0aGUgYmFja3VwcyBhcmUgdG8gYmUgc3RvcmVk
LgoKDQoFBAMCCgQSBIQCAgoKDQoFBAMCCgYSBIQCCxkKDQoFBAMCCgESBIQCGioKDQoFBAMC
CgMSBIQCLS8KVQoCBAQSBogCAIsCARpHIFBvaW50IGluIHRpbWUgcmVjb3Zlcnkgc2V0dGlu
Z3Mgb2YgdGhlIGJhY2t1cCBjb25maWd1cmF0aW9uIHJlc291cmNlLgoKCwoDBAQBEgSIAggU
CkEKBAQEAgASBIoCAkcaMyBPdXRwdXQgb25seS4gTnVtYmVyIG9mIGRheXMgdG8gcmV0YWlu
IHRoZSBiYWNrdXAuCgoNCgUEBAIABRIEigICBwoNCgUEBAIAARIEigIIFgoNCgUEBAIAAxIE
igIZGgoNCgUEBAIACBIEigIbRgoQCggEBAIACJwIABIEigIcRQpyCgIEBRIGjwIAmQIBGmQg
UHJvdmlkZXMgYWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCBHb29nbGUgQ2xvdWQgQmFj
a3VwIGFuZCBEUidzIFRlbXBsYXRlCiBiYWNrdXAgY29uZmlndXJhdGlvbi4KCgsKAwQFARIE
jwIIHgptCgQEBQIAEgaSAgKTAjIaXSBPdXRwdXQgb25seS4gVGhlIFVSSSBvZiB0aGUgQmFj
a3VwRHIgdGVtcGxhdGUgcmVzb3VyY2UgZm9yIHRoZSBmaXJzdCBwYXJ0eQogaWRlbnRpdHkg
dXNlcnMuCgoNCgUEBQIABRIEkgICCAoNCgUEBQIAARIEkgIJIwoNCgUEBQIAAxIEkgImJwoN
CgUEBQIACBIEkwIGMQoQCggEBQIACJwIABIEkwIHMAptCgQEBQIBEgaXAgKYAjIaXSBPdXRw
dXQgb25seS4gVGhlIFVSSSBvZiB0aGUgQmFja3VwRHIgdGVtcGxhdGUgcmVzb3VyY2UgZm9y
IHRoZSB0aGlyZCBwYXJ0eQogaWRlbnRpdHkgdXNlcnMuCgoNCgUEBQIBBRIElwICCAoNCgUE
BQIBARIElwIJIwoNCgUEBQIBAxIElwImJwoNCgUEBQIBCBIEmAIGMQoQCggEBQIBCJwIABIE
mAIHMAp8CgIEBhIGnQIAoAIBGm4gQmFja3VwRHJQbGFuQ29uZmlnIGhhcyBhZGRpdGlvbmFs
IGluZm9ybWF0aW9uIGFib3V0IEdvb2dsZSBDbG91ZCBCYWNrdXAgYW5kCiBEUidzIFBsYW4g
YmFja3VwIGNvbmZpZ3VyYXRpb24uCgoLCgMEBgESBJ0CCBoKOQoEBAYCABIEnwICNRorIEJh
Y2t1cCBydWxlcyBvZiB0aGUgYmFja3VwIHBsYW4gcmVzb3VyY2UuCgoNCgUEBgIABBIEnwIC
CgoNCgUEBgIABhIEnwILGwoNCgUEBgIAARIEnwIcMAoNCgUEBgIAAxIEnwIzNApbCgIEBxIG
owIAqwIBGk0gQmFja3VwRHJQbGFuUnVsZSBoYXMgcnVsZSBzcGVjaWZpYyBpbmZvcm1hdGlv
biBvZiB0aGUgYmFja3VwIHBsYW4gcmVzb3VyY2UuCgoLCgMEBwESBKMCCBgKOgoEBAcCABIE
pQICQRosIE91dHB1dCBvbmx5LiBVbmlxdWUgSWQgb2YgdGhlIGJhY2t1cCBydWxlLgoKDQoF
BAcCAAUSBKUCAggKDQoFBAcCAAESBKUCCRAKDQoFBAcCAAMSBKUCExQKDQoFBAcCAAgSBKUC
FUAKEAoIBAcCAAicCAASBKUCFj8KZwoEBAcCARIGqQICqgIyGlcgT3V0cHV0IG9ubHkuIFRp
bWVzdGFtcCBvZiB0aGUgbGF0ZXN0IHN1Y2Nlc3NmdWwgYmFja3VwIGNyZWF0ZWQgdmlhIHRo
aXMKIGJhY2t1cCBydWxlLgoKDQoFBAcCAQYSBKkCAhsKDQoFBAcCAQESBKkCHDcKDQoFBAcC
AQMSBKkCOjsKDQoFBAcCAQgSBKoCBjEKEAoIBAcCAQicCAASBKoCBzAKWAoCBAgSBq4CAMMC
ARpKIEJhY2t1cExvY2F0aW9uIHJlcHJlc2VudHMgYSBjbG91ZCBsb2NhdGlvbiB3aGVyZSBh
IGJhY2t1cCBjYW4gYmUgc3RvcmVkLgoKCwoDBAgBEgSuAggWCisKBAQIBAASBrACArwCAxob
IFRoZSB0eXBlIG9mIHRoZSBsb2NhdGlvbi4KCg0KBQQIBAABEgSwAgcLCi8KBgQIBAACABIE
sgIEGRofIExvY2F0aW9uIHR5cGUgaXMgdW5zcGVjaWZpZWQuCgoPCgcECAQAAgABEgSyAgQU
Cg8KBwQIBAACAAISBLICFxgKKQoGBAgEAAIBEgS1AgQOGhkgTG9jYXRpb24gdHlwZSBpcyB6
b25hbC4KCg8KBwQIBAACAQESBLUCBAkKDwoHBAgEAAIBAhIEtQIMDQosCgYECAQAAgISBLgC
BBEaHCBMb2NhdGlvbiB0eXBlIGlzIHJlZ2lvbmFsLgoKDwoHBAgEAAICARIEuAIEDAoPCgcE
CAQAAgICEgS4Ag8QCjIKBgQIBAACAxIEuwIEFxoiIExvY2F0aW9uIHR5cGUgaXMgbXVsdGkg
cmVnaW9uYWwuCgoPCgcECAQAAgMBEgS7AgQSCg8KBwQIBAACAwISBLsCFRYKNgoEBAgCABIE
vwICPBooIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgbG9jYXRpb24uCgoNCgUECAIA
BhIEvwICBgoNCgUECAIAARIEvwIHCwoNCgUECAIAAxIEvwIODwoNCgUECAIACBIEvwIQOwoQ
CggECAIACJwIABIEvwIROgpRCgQECAIBEgTCAgJFGkMgT3V0cHV0IG9ubHkuIFRoZSBpZCBv
ZiB0aGUgY2xvdWQgbG9jYXRpb24uIEV4YW1wbGU6ICJ1cy1jZW50cmFsMSIKCg0KBQQIAgEF
EgTCAgIICg0KBQQIAgEBEgTCAgkUCg0KBQQIAgEDEgTCAhcYCg0KBQQIAgEIEgTCAhlEChAK
CAQIAgEInAgAEgTCAhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest ===
    # Fields for ListResourceBackupConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsResponse ===
    # Fields for ListResourceBackupConfigsResponse
    # Field: resource_backup_configs Type: 11 (.google.cloud.backupdr.v1beta.ResourceBackupConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::ResourceBackupConfig ===
    # Fields for ResourceBackupConfig
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: target_resource Type: 9 ()
    # Field: target_resource_display_name Type: 9 ()
    # Field: target_resource_type Type: 14 (.google.cloud.backupdr.v1beta.ResourceBackupConfig.ResourceType)
    # Field: target_resource_labels Type: 11 (.google.cloud.backupdr.v1beta.ResourceBackupConfig.TargetResourceLabelsEntry)
    # Field: backup_configs_details Type: 11 (.google.cloud.backupdr.v1beta.BackupConfigDetails)
    # Field: backup_configured Type: 8 ()
    # Field: vaulted Type: 8 ()

# Enum: ResourceBackupConfig::ResourceType
our $ResourceBackupConfig_RESOURCE_TYPE_UNSPECIFIED = 0;
our $ResourceBackupConfig_CLOUD_SQL_INSTANCE = 1;
our $ResourceBackupConfig_COMPUTE_ENGINE_VM = 2;
our $ResourceBackupConfig_COMPUTE_ENGINE_DISK = 3;
our $ResourceBackupConfig_COMPUTE_ENGINE_REGIONAL_DISK = 4;

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupConfigDetails ===
    # Fields for BackupConfigDetails
    # Field: backup_dr_plan_config Type: 11 (.google.cloud.backupdr.v1beta.BackupDrPlanConfig)
    # Field: backup_dr_template_config Type: 11 (.google.cloud.backupdr.v1beta.BackupDrTemplateConfig)
    # Field: backup_config_source Type: 9 ()
    # Field: backup_config_source_display_name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.backupdr.v1beta.BackupConfigDetails.Type)
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.BackupConfigDetails.State)
    # Field: pitr_settings Type: 11 (.google.cloud.backupdr.v1beta.PitrSettings)
    # Field: latest_successful_backup_time Type: 11 (.google.protobuf.Timestamp)
    # Field: applicable_resource Type: 9 ()
    # Field: backup_vault Type: 9 ()
    # Field: backup_locations Type: 11 (.google.cloud.backupdr.v1beta.BackupLocation)

# Enum: BackupConfigDetails::Type
our $BackupConfigDetails_TYPE_UNSPECIFIED = 0;
our $BackupConfigDetails_CLOUD_SQL_INSTANCE_BACKUP_CONFIG = 1;
our $BackupConfigDetails_COMPUTE_ENGINE_RESOURCE_POLICY = 2;
our $BackupConfigDetails_BACKUPDR_BACKUP_PLAN = 3;
our $BackupConfigDetails_BACKUPDR_TEMPLATE = 4;

# Enum: BackupConfigDetails::State
our $BackupConfigDetails_STATE_UNSPECIFIED = 0;
our $BackupConfigDetails_ACTIVE = 1;
our $BackupConfigDetails_INACTIVE = 2;
our $BackupConfigDetails_ERROR = 3;

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::PitrSettings ===
    # Fields for PitrSettings
    # Field: retention_days Type: 5 ()

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrTemplateConfig ===
    # Fields for BackupDrTemplateConfig
    # Field: first_party_management_uri Type: 9 ()
    # Field: third_party_management_uri Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanConfig ===
    # Fields for BackupDrPlanConfig
    # Field: backup_dr_plan_rules Type: 11 (.google.cloud.backupdr.v1beta.BackupDrPlanRule)

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanRule ===
    # Fields for BackupDrPlanRule
    # Field: rule_id Type: 9 ()
    # Field: last_successful_backup_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupLocation ===
    # Fields for BackupLocation
    # Field: type Type: 14 (.google.cloud.backupdr.v1beta.BackupLocation.Type)
    # Field: location_id Type: 9 ()

# Enum: BackupLocation::Type
our $BackupLocation_TYPE_UNSPECIFIED = 0;
our $BackupLocation_ZONAL = 1;
our $BackupLocation_REGIONAL = 2;
our $BackupLocation_MULTI_REGIONAL = 3;

# === Service Client: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrProtectionSummaryClient ===
package Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrProtectionSummaryClient;

=pod

=head2 Service Client: Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrProtectionSummaryClient

Client stub representing the remote C<BackupDrProtectionSummary> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<backupdr.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'backupdr.googleapis.com:443' );

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

sub list_resource_backup_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.backupdr.v1beta.BackupDrProtectionSummary',
        method         => 'ListResourceBackupConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::ProtectionSummary - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/protection_summary.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::ProtectionSummary;

    my $msg = Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/protection_summary.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsRequest

Request for ListResourceBackupConfigs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve resource backup
configs. Format: 'projects/{project_id}/locations/{location}'. In Google
Cloud Backup and DR, locations map to Google Cloud regions, for example
B<us-central1>.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will use 100 as default. Maximum value is
500 and values above 500 will be coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::ListResourceBackupConfigsResponse

Response for ListResourceBackupConfigs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_backup_configs() >> / C<< $msg->resource_backup_configs($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::ResourceBackupConfig>)

The list of ResourceBackupConfigs for the specified scope.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::ResourceBackupConfig

ResourceBackupConfig represents a resource along with its backup
configurations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the ResourceBackupConfig.
Format:
projects/{project}/locations/{location}/resourceBackupConfigs/{uid}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The unique identifier of the resource backup config.

=item * C<< $msg->target_resource() >> / C<< $msg->target_resource($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the cloud resource that this configuration applies to. Supported
resource types are
[ResourceBackupConfig.ResourceType][google.cloud.backupdr.v1beta.ResourceBackupConfig.ResourceType].

=item * C<< $msg->target_resource_display_name() >> / C<< $msg->target_resource_display_name($value) >>

Type: C<String>

Output only. The human friendly name of the target resource.

=item * C<< $msg->target_resource_type() >> / C<< $msg->target_resource_type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::ResourceBackupConfig::ResourceType>)

Output only. The type of the target resource.

=item * C<< $msg->target_resource_labels() >> / C<< $msg->target_resource_labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::ResourceBackupConfig::TargetResourceLabelsEntry>)

Labels associated with the target resource.

=item * C<< $msg->backup_configs_details() >> / C<< $msg->backup_configs_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupConfigDetails>)

Backup configurations applying to the target resource, including those
targeting its related/child resources. For example, backup configuration
applicable to Compute Engine disks will be populated in this field for a
Compute Engine VM which has the disk associated.

=item * C<< $msg->backup_configured() >> / C<< $msg->backup_configured($value) >>

Type: C<Bool>

Output only. Whether the target resource is configured for backup. This is
true if the backup_configs_details is not empty.

=item * C<< $msg->vaulted() >> / C<< $msg->vaulted($value) >>

Type: C<Bool>

Output only. Whether the target resource is protected by a backup vault.
This is true if the backup_configs_details is not empty and any of the
[ResourceBackupConfig.backup_configs_details][google.cloud.backupdr.v1beta.ResourceBackupConfig.backup_configs_details]
has a backup configuration with
[BackupConfigDetails.backup_vault][google.cloud.backupdr.v1beta.BackupConfigDetails.backup_vault]
set.

=back

=head3 Enum: ResourceBackupConfig::ResourceType

=over 4

=item * C<RESOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_SQL_INSTANCE> => C<1>

=item * C<COMPUTE_ENGINE_VM> => C<2>

=item * C<COMPUTE_ENGINE_DISK> => C<3>

=item * C<COMPUTE_ENGINE_REGIONAL_DISK> => C<4>

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupConfigDetails

BackupConfigDetails has information about how the resource is configured
for backups and about the most recent backup taken for this configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_dr_plan_config() >> / C<< $msg->backup_dr_plan_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanConfig>)

Google Cloud Backup and DR's Backup Plan specific data.

=item * C<< $msg->backup_dr_template_config() >> / C<< $msg->backup_dr_template_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrTemplateConfig>)

Google Cloud Backup and DR's Template specific data.

=item * C<< $msg->backup_config_source() >> / C<< $msg->backup_config_source($value) >>

Type: C<String>

Output only. The full resource name of the backup config source resource.
For example,
"//backupdr.googleapis.com/v1/projects/{project}/locations/{region}/backupPlans/{backupplanId}"
or
"//compute.googleapis.com/projects/{project}/locations/{region}/resourcePolicies/{resourcePolicyId}".

=item * C<< $msg->backup_config_source_display_name() >> / C<< $msg->backup_config_source_display_name($value) >>

Type: C<String>

Output only. The display name of the backup config source resource.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::BackupConfigDetails::Type>)

Output only. The type of the backup config resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::BackupConfigDetails::State>)

Output only. The state of the backup config resource.

=item * C<< $msg->pitr_settings() >> / C<< $msg->pitr_settings($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::PitrSettings>)

Output only. Point in time recovery settings of the backup configuration
resource.

=item * C<< $msg->latest_successful_backup_time() >> / C<< $msg->latest_successful_backup_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the latest successful backup created via this
backup configuration.

=item * C<< $msg->applicable_resource() >> / C<< $msg->applicable_resource($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the resource that is applicable for the backup configuration. Example:
"//compute.googleapis.com/projects/{project}/zones/{zone}/instances/{instance}"

=item * C<< $msg->backup_vault() >> / C<< $msg->backup_vault($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the backup vault that will store the backups generated through this
backup configuration. Example:
"//backupdr.googleapis.com/v1/projects/{project}/locations/{region}/backupVaults/{backupvaultId}"

=item * C<< $msg->backup_locations() >> / C<< $msg->backup_locations($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupLocation>)

The locations where the backups are to be stored.

=back

=head3 Enum: BackupConfigDetails::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_SQL_INSTANCE_BACKUP_CONFIG> => C<1>

=item * C<COMPUTE_ENGINE_RESOURCE_POLICY> => C<2>

=item * C<BACKUPDR_BACKUP_PLAN> => C<3>

=item * C<BACKUPDR_TEMPLATE> => C<4>

=back

=head3 Enum: BackupConfigDetails::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<INACTIVE> => C<2>

=item * C<ERROR> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::PitrSettings

Point in time recovery settings of the backup configuration resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Output only. Number of days to retain the backup.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrTemplateConfig

Provides additional information about Google Cloud Backup and DR's Template
backup configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_party_management_uri() >> / C<< $msg->first_party_management_uri($value) >>

Type: C<String>

Output only. The URI of the BackupDr template resource for the first party
identity users.

=item * C<< $msg->third_party_management_uri() >> / C<< $msg->third_party_management_uri($value) >>

Type: C<String>

Output only. The URI of the BackupDr template resource for the third party
identity users.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanConfig

BackupDrPlanConfig has additional information about Google Cloud Backup and
DR's Plan backup configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_dr_plan_rules() >> / C<< $msg->backup_dr_plan_rules($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanRule>)

Backup rules of the backup plan resource.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupDrPlanRule

BackupDrPlanRule has rule specific information of the backup plan resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_id() >> / C<< $msg->rule_id($value) >>

Type: C<String>

Output only. Unique Id of the backup rule.

=item * C<< $msg->last_successful_backup_time() >> / C<< $msg->last_successful_backup_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the latest successful backup created via this
backup rule.

=back

=head2 Google::Cloud::Backupdr::V1beta::ProtectionSummary::BackupLocation

BackupLocation represents a cloud location where a backup can be stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::BackupLocation::Type>)

Output only. The type of the location.

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Output only. The id of the cloud location. Example: "us-central1"

=back

=head3 Enum: BackupLocation::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<ZONAL> => C<1>

=item * C<REGIONAL> => C<2>

=item * C<MULTI_REGIONAL> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::ProtectionSummary::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
