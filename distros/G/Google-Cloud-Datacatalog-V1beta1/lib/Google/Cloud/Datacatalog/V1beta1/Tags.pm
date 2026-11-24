package Google::Cloud::Datacatalog::V1beta1::Tags;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS90YWdzLnByb3RvEiBnb29nbGUu
Y2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byLWAwoDVGFnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIfCgh0ZW1wbGF0
ZRgCIAEoCUID4EECUgh0ZW1wbGF0ZRI3ChV0ZW1wbGF0ZV9kaXNwbGF5X25hbWUYBSABKAlC
A+BBA1ITdGVtcGxhdGVEaXNwbGF5TmFtZRIYCgZjb2x1bW4YBCABKAlIAFIGY29sdW1uEk4K
BmZpZWxkcxgDIAMoCzIxLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlRhZy5G
aWVsZHNFbnRyeUID4EECUgZmaWVsZHMaZQoLRmllbGRzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSQAoFdmFsdWUYAiABKAsyKi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5U
YWdGaWVsZFIFdmFsdWU6AjgBOoEB6kF+Ch5kYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9U
YWcSXHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbnRyeUdyb3Vw
cy97ZW50cnlfZ3JvdXB9L2VudHJpZXMve2VudHJ5fS90YWdzL3t0YWd9QgcKBXNjb3BlIo4D
CghUYWdGaWVsZBImCgxkaXNwbGF5X25hbWUYASABKAlCA+BBA1ILZGlzcGxheU5hbWUSIwoM
ZG91YmxlX3ZhbHVlGAIgASgBSABSC2RvdWJsZVZhbHVlEiMKDHN0cmluZ192YWx1ZRgDIAEo
CUgAUgtzdHJpbmdWYWx1ZRIfCgpib29sX3ZhbHVlGAQgASgISABSCWJvb2xWYWx1ZRJFCg90
aW1lc3RhbXBfdmFsdWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSDnRp
bWVzdGFtcFZhbHVlElUKCmVudW1fdmFsdWUYBiABKAsyNC5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFiZXRhMS5UYWdGaWVsZC5FbnVtVmFsdWVIAFIJZW51bVZhbHVlEhkKBW9yZGVy
GAcgASgFQgPgQQNSBW9yZGVyGi4KCUVudW1WYWx1ZRIhCgxkaXNwbGF5X25hbWUYASABKAlS
C2Rpc3BsYXlOYW1lQgYKBGtpbmQi3gQKC1RhZ1RlbXBsYXRlEhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lElYKBmZpZWxkcxgD
IAMoCzI5Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlRhZ1RlbXBsYXRlLkZp
ZWxkc0VudHJ5QgPgQQJSBmZpZWxkcxKDAQoYZGF0YXBsZXhfdHJhbnNmZXJfc3RhdHVzGAcg
ASgOMkQuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuVGFnVGVtcGxhdGUuRGF0
YXBsZXhUcmFuc2ZlclN0YXR1c0ID4EEDUhZkYXRhcGxleFRyYW5zZmVyU3RhdHVzGm0KC0Zp
ZWxkc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkgKBXZhbHVlGAIgASgLMjIuZ29vZ2xlLmNs
b3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuVGFnVGVtcGxhdGVGaWVsZFIFdmFsdWU6AjgBIlQK
FkRhdGFwbGV4VHJhbnNmZXJTdGF0dXMSKAokREFUQVBMRVhfVFJBTlNGRVJfU1RBVFVTX1VO
U1BFQ0lGSUVEEAASEAoITUlHUkFURUQQARoCCAE6cOpBbQomZGF0YWNhdGFsb2cuZ29vZ2xl
YXBpcy5jb20vVGFnVGVtcGxhdGUSQ3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS90YWdUZW1wbGF0ZXMve3RhZ190ZW1wbGF0ZX0i+AIKEFRhZ1RlbXBsYXRlRmll
bGQSGgoEbmFtZRgGIAEoCUIG4EEI4EEDUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgBIAEoCVIL
ZGlzcGxheU5hbWUSRAoEdHlwZRgCIAEoCzIrLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52
MWJldGExLkZpZWxkVHlwZUID4EECUgR0eXBlEh8KC2lzX3JlcXVpcmVkGAMgASgIUgppc1Jl
cXVpcmVkEiAKC2Rlc2NyaXB0aW9uGAQgASgJUgtkZXNjcmlwdGlvbhIUCgVvcmRlchgFIAEo
BVIFb3JkZXI6hQHqQYEBCitkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9UYWdUZW1wbGF0
ZUZpZWxkElJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdGFnVGVt
cGxhdGVzL3t0YWdfdGVtcGxhdGV9L2ZpZWxkcy97ZmllbGR9ItwDCglGaWVsZFR5cGUSYgoO
cHJpbWl0aXZlX3R5cGUYASABKA4yOS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRh
MS5GaWVsZFR5cGUuUHJpbWl0aXZlVHlwZUgAUg1wcmltaXRpdmVUeXBlElMKCWVudW1fdHlw
ZRgCIAEoCzI0Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLkZpZWxkVHlwZS5F
bnVtVHlwZUgAUghlbnVtVHlwZRqmAQoIRW51bVR5cGUSZQoOYWxsb3dlZF92YWx1ZXMYASAD
KAsyPi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5GaWVsZFR5cGUuRW51bVR5
cGUuRW51bVZhbHVlUg1hbGxvd2VkVmFsdWVzGjMKCUVudW1WYWx1ZRImCgxkaXNwbGF5X25h
bWUYASABKAlCA+BBAlILZGlzcGxheU5hbWUiYAoNUHJpbWl0aXZlVHlwZRIeChpQUklNSVRJ
VkVfVFlQRV9VTlNQRUNJRklFRBAAEgoKBkRPVUJMRRABEgoKBlNUUklORxACEggKBEJPT0wQ
AxINCglUSU1FU1RBTVAQBEILCgl0eXBlX2RlY2xC3AEKJGNvbS5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjFiZXRhMVABWkZjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRhbG9nL2Fw
aXYxYmV0YTEvZGF0YWNhdGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIgR29vZ2xlLkNsb3VkLkRh
dGFDYXRhbG9nLlYxQmV0YTHKAiBHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjFiZXRhMeoC
I0dvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMWJldGExSsJHCgcSBQ4A+QEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCQoC
AwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAPQoJCgIIJRIDFgA9CggKAQgSAxcAXQoJCgII
CxIDFwBdCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAPQoJCgIIARIDGQA9CggKAQgS
AxoAPQoJCgIIKRIDGgA9CggKAQgSAxsAPAoJCgIILRIDGwA8CqYCCgIEABIEIwBPARqZAiBU
YWdzIGFyZSB1c2VkIHRvIGF0dGFjaCBjdXN0b20gbWV0YWRhdGEgdG8gRGF0YSBDYXRhbG9n
IHJlc291cmNlcy4gVGFncwogY29uZm9ybSB0byB0aGUgc3BlY2lmaWNhdGlvbnMgd2l0aGlu
IHRoZWlyIHRhZyB0ZW1wbGF0ZS4KCiBTZWUgW0RhdGEgQ2F0YWxvZwogSUFNXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vZGF0YS1jYXRhbG9nL2RvY3MvY29uY2VwdHMvaWFtKSBmb3Ig
aW5mb3JtYXRpb24KIG9uIHRoZSBwZXJtaXNzaW9ucyBuZWVkZWQgdG8gY3JlYXRlIG9yIHZp
ZXcgdGFncy4KCgoKAwQAARIDIwgLCgsKAwQABxIEJAInBAoNCgUEAAedCBIEJAInBAq9AgoE
BAACABIDLwI9Gq8CIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSB0YWcg
aW4gVVJMIGZvcm1hdC4gRXhhbXBsZToKCiAqIHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9lbnRyeWdyb3Vwcy97ZW50cnlfZ3JvdXBfaWR9L2VudHJpZXMv
e2VudHJ5X2lkfS90YWdzL3t0YWdfaWR9Cgogd2hlcmUgYHRhZ19pZGAgaXMgYSBzeXN0ZW0t
Z2VuZXJhdGVkIGlkZW50aWZpZXIuCiBOb3RlIHRoYXQgdGhpcyBUYWcgbWF5IG5vdCBhY3R1
YWxseSBiZSBzdG9yZWQgaW4gdGhlIGxvY2F0aW9uIGluIHRoaXMgbmFtZS4KCgwKBQQAAgAF
EgMvAggKDAoFBAACAAESAy8JDQoMCgUEAAIAAxIDLxARCgwKBQQAAgAIEgMvEjwKDwoIBAAC
AAicCAASAy8TOwrbAQoEBAACARIDNwI/Gs0BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgdGFnIHRlbXBsYXRlIHRoYXQgdGhpcyB0YWcgdXNlcy4KIEV4YW1wbGU6Cgog
KiBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdGFnVGVtcGxh
dGVzL3t0YWdfdGVtcGxhdGVfaWR9CgogVGhpcyBmaWVsZCBjYW5ub3QgYmUgbW9kaWZpZWQg
YWZ0ZXIgY3JlYXRpb24uCgoMCgUEAAIBBRIDNwIICgwKBQQAAgEBEgM3CREKDAoFBAACAQMS
AzcUFQoMCgUEAAIBCBIDNxY+Cg8KCAQAAgEInAgAEgM3Fz0KQQoEBAACAhIDOgJPGjQgT3V0
cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHRhZyB0ZW1wbGF0ZS4KCgwKBQQA
AgIFEgM6AggKDAoFBAACAgESAzoJHgoMCgUEAAICAxIDOiEiCgwKBQQAAgIIEgM6I04KDwoI
BAACAgicCAASAzokTQqiAgoEBAAIABIEQAJJAxqTAiBUaGUgc2NvcGUgd2l0aGluIHRoZSBw
YXJlbnQgcmVzb3VyY2UgdGhhdCB0aGlzIHRhZyBpcyBhdHRhY2hlZCB0by4gSWYgbm90CiBw
cm92aWRlZCwgdGhlIHRhZyBpcyBhdHRhY2hlZCB0byB0aGUgcGFyZW50IHJlc291cmNlIGl0
c2VsZi4KIERlbGV0aW5nIHRoZSBzY29wZSBmcm9tIHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2ls
bCBkZWxldGUgYWxsIHRhZ3MgYXR0YWNoZWQKIHRvIHRoYXQgc2NvcGUuIFRoZXNlIGZpZWxk
cyBjYW5ub3QgYmUgdXBkYXRlZCBhZnRlciBjcmVhdGlvbi4KCgwKBQQACAABEgNACA0KmwIK
BAQAAgMSA0gEFhqNAiBSZXNvdXJjZXMgbGlrZSBFbnRyeSBjYW4gaGF2ZSBzY2hlbWFzIGFz
c29jaWF0ZWQgd2l0aCB0aGVtLiBUaGlzIHNjb3BlCiBhbGxvd3MgdXNlcnMgdG8gYXR0YWNo
IHRhZ3MgdG8gYW4gaW5kaXZpZHVhbCBjb2x1bW4gYmFzZWQgb24gdGhhdCBzY2hlbWEuCgog
Rm9yIGF0dGFjaGluZyBhIHRhZyB0byBhIG5lc3RlZCBjb2x1bW4sIHVzZSBgLmAgdG8gc2Vw
YXJhdGUgdGhlIGNvbHVtbgogbmFtZXMuIEV4YW1wbGU6CgogKiBgb3V0ZXJfY29sdW1uLmlu
bmVyX2NvbHVtbmAKCgwKBQQAAgMFEgNIBAoKDAoFBAACAwESA0gLEQoMCgUEAAIDAxIDSBQV
CuQBCgQEAAIEEgNOAkwa1gEgUmVxdWlyZWQuIFRoaXMgbWFwcyB0aGUgSUQgb2YgYSB0YWcg
ZmllbGQgdG8gdGhlIHZhbHVlIG9mIGFuZCBhZGRpdGlvbmFsCiBpbmZvcm1hdGlvbiBhYm91
dCB0aGF0IGZpZWxkLiBWYWxpZCBmaWVsZCBJRHMgYXJlIGRlZmluZWQgYnkgdGhlIHRhZydz
CiB0ZW1wbGF0ZS4gQSB0YWcgbXVzdCBoYXZlIGF0IGxlYXN0IDEgZmllbGQgYW5kIGF0IG1v
c3QgNTAwIGZpZWxkcy4KCgwKBQQAAgQGEgNOAhcKDAoFBAACBAESA04YHgoMCgUEAAIEAxID
TiEiCgwKBQQAAgQIEgNOI0sKDwoIBAACBAicCAASA04kSgp+CgIEARIEUwB3ARpyIENvbnRh
aW5zIHRoZSB2YWx1ZSBhbmQgc3VwcG9ydGluZyBpbmZvcm1hdGlvbiBmb3IgYSBmaWVsZCB3
aXRoaW4KIGEgW1RhZ11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuVGFnXS4K
CgoKAwQBARIDUwgQCiQKBAQBAwASBFUCWAMaFiBIb2xkcyBhbiBlbnVtIHZhbHVlLgoKDAoF
BAEDAAESA1UKEwo0CgYEAQMAAgASA1cEHBolIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGVu
dW0gdmFsdWUuCgoOCgcEAQMAAgAFEgNXBAoKDgoHBAEDAAIAARIDVwsXCg4KBwQBAwACAAMS
A1caGwo7CgQEAQIAEgNbAkYaLiBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0
aGlzIGZpZWxkLgoKDAoFBAECAAUSA1sCCAoMCgUEAQIAARIDWwkVCgwKBQQBAgADEgNbGBkK
DAoFBAECAAgSA1saRQoPCggEAQIACJwIABIDWxtECjIKBAQBCAASBF4CbgMaJCBSZXF1aXJl
ZC4gVGhlIHZhbHVlIG9mIHRoaXMgZmllbGQuCgoMCgUEAQgAARIDXggMCkAKBAQBAgESA2AE
HBozIEhvbGRzIHRoZSB2YWx1ZSBmb3IgYSB0YWcgZmllbGQgd2l0aCBkb3VibGUgdHlwZS4K
CgwKBQQBAgEFEgNgBAoKDAoFBAECAQESA2ALFwoMCgUEAQIBAxIDYBobCkAKBAQBAgISA2ME
HBozIEhvbGRzIHRoZSB2YWx1ZSBmb3IgYSB0YWcgZmllbGQgd2l0aCBzdHJpbmcgdHlwZS4K
CgwKBQQBAgIFEgNjBAoKDAoFBAECAgESA2MLFwoMCgUEAQICAxIDYxobCkEKBAQBAgMSA2YE
GBo0IEhvbGRzIHRoZSB2YWx1ZSBmb3IgYSB0YWcgZmllbGQgd2l0aCBib29sZWFuIHR5cGUu
CgoMCgUEAQIDBRIDZgQICgwKBQQBAgMBEgNmCRMKDAoFBAECAwMSA2YWFwpDCgQEAQIEEgNp
BDIaNiBIb2xkcyB0aGUgdmFsdWUgZm9yIGEgdGFnIGZpZWxkIHdpdGggdGltZXN0YW1wIHR5
cGUuCgoMCgUEAQIEBhIDaQQdCgwKBQQBAgQBEgNpHi0KDAoFBAECBAMSA2kwMQqMAQoEBAEC
BRIDbQQdGn8gSG9sZHMgdGhlIHZhbHVlIGZvciBhIHRhZyBmaWVsZCB3aXRoIGVudW0gdHlw
ZS4gVGhpcyB2YWx1ZSBtdXN0IGJlCiBvbmUgb2YgdGhlIGFsbG93ZWQgdmFsdWVzIGluIHRo
ZSBkZWZpbml0aW9uIG9mIHRoaXMgZW51bS4KCgwKBQQBAgUGEgNtBA0KDAoFBAECBQESA20O
GAoMCgUEAQIFAxIDbRscCvUCCgQEAQIGEgN2Aj4a5wIgT3V0cHV0IG9ubHkuIFRoZSBvcmRl
ciBvZiB0aGlzIGZpZWxkIHdpdGggcmVzcGVjdCB0byBvdGhlciBmaWVsZHMgaW4gdGhpcwog
dGFnLiBJdCBjYW4gYmUgc2V0IGluCiBbVGFnXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cu
djFiZXRhMS5UYWdUZW1wbGF0ZUZpZWxkLm9yZGVyXS4gRm9yCiBleGFtcGxlLCBhIGhpZ2hl
ciB2YWx1ZSBjYW4gaW5kaWNhdGUgYSBtb3JlIGltcG9ydGFudCBmaWVsZC4gVGhlIHZhbHVl
IGNhbgogYmUgbmVnYXRpdmUuIE11bHRpcGxlIGZpZWxkcyBjYW4gaGF2ZSB0aGUgc2FtZSBv
cmRlciwgYW5kIGZpZWxkIG9yZGVycwogd2l0aGluIGEgdGFnIGRvIG5vdCBoYXZlIHRvIGJl
IHNlcXVlbnRpYWwuCgoMCgUEAQIGBRIDdgIHCgwKBQQBAgYBEgN2CA0KDAoFBAECBgMSA3YQ
EQoMCgUEAQIGCBIDdhI9Cg8KCAQBAgYInAgAEgN2EzwK+QMKAgQCEgaBAQCtAQEa6gMgQSB0
YWcgdGVtcGxhdGUgZGVmaW5lcyBhIHRhZywgd2hpY2ggY2FuIGhhdmUgb25lIG9yIG1vcmUg
dHlwZWQgZmllbGRzLgogVGhlIHRlbXBsYXRlIGlzIHVzZWQgdG8gY3JlYXRlIGFuZCBhdHRh
Y2ggdGhlIHRhZyB0byBHb29nbGUgQ2xvdWQgcmVzb3VyY2VzLgogW1RhZyB0ZW1wbGF0ZQog
cm9sZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vZG9jcy91bmRlcnN0YW5kaW5n
LXJvbGVzI2RhdGEtY2F0YWxvZy1yb2xlcykKIHByb3ZpZGUgcGVybWlzc2lvbnMgdG8gY3Jl
YXRlLCBlZGl0LCBhbmQgdXNlIHRoZSB0ZW1wbGF0ZS4gU2VlLCBmb3IgZXhhbXBsZSwKIHRo
ZSBbVGFnVGVtcGxhdGUKIFVzZXJdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhLWNh
dGFsb2cvZG9jcy9ob3ctdG8vdGVtcGxhdGUtdXNlcikgcm9sZSwKIHdoaWNoIGluY2x1ZGVz
IHBlcm1pc3Npb24gdG8gdXNlIHRoZSB0YWcgdGVtcGxhdGUgdG8gdGFnIHJlc291cmNlcy4K
CgsKAwQCARIEgQEIEwoNCgMEAgcSBoIBAoUBBAoPCgUEAgedCBIGggEChQEEClYKBAQCBAAS
BogBApIBAxpGIFRoaXMgZW51bSBkZXNjcmliZXMgVGFnVGVtcGxhdGUgdHJhbnNmZXIgc3Rh
dHVzIHRvIERhdGFwbGV4IHNlcnZpY2UuCgoNCgUEAgQAARIEiAEHHQpoCgYEAgQAAgASBIsB
BC0aWCBEZWZhdWx0IHZhbHVlLiBUYWdUZW1wbGF0ZSBhbmQgaXRzIHRhZ3MgYXJlIG9ubHkg
dmlzaWJsZSBhbmQgZWRpdGFibGUgaW4KIERhdGFDYXRhbG9nLgoKDwoHBAIEAAIAARIEiwEE
KAoPCgcEAgQAAgACEgSLASssCp8CCgYEAgQAAgESBJEBBCUajgIgVGFnVGVtcGxhdGUgYW5k
IGl0cyB0YWdzIGFyZSBhdXRvLWNvcGllZCB0byBEYXRhcGxleCBzZXJ2aWNlLgogVmlzaWJs
ZSBpbiBib3RoIHNlcnZpY2VzLiBFZGl0YWJsZSBpbiBEYXRhQ2F0YWxvZywgcmVhZC1vbmx5
IGluIERhdGFwbGV4LgogRGVwcmVjYXRlZDogSW5kaXZpZHVhbCBUYWdUZW1wbGF0ZSBtaWdy
YXRpb24gaXMgZGVwcmVjYXRlZCBpbiBmYXZvciBvZgogb3JnYW5pemF0aW9uIG9yIHByb2pl
Y3Qgd2lkZSBUYWdUZW1wbGF0ZSBtaWdyYXRpb24gb3B0LWluLgoKDwoHBAIEAAIBARIEkQEE
DAoPCgcEAgQAAgECEgSRAQ8QCg8KBwQCBAACAQMSBJEBESQKEAoIBAIEAAIBAwESBJEBEiMK
lwIKBAQCAgASBJoBAj0aiAIgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IHRhZyB0ZW1wbGF0ZSBpbiBVUkwgZm9ybWF0LiBFeGFtcGxlOgoKICogcHJvamVjdHMve3By
b2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3RhZ1RlbXBsYXRlcy97dGFnX3RlbXBs
YXRlX2lkfQoKIE5vdGUgdGhhdCB0aGlzIFRhZ1RlbXBsYXRlIGFuZCBpdHMgY2hpbGQgcmVz
b3VyY2VzIG1heSBub3QgYWN0dWFsbHkgYmUKIHN0b3JlZCBpbiB0aGUgbG9jYXRpb24gaW4g
dGhpcyBuYW1lLgoKDQoFBAICAAUSBJoBAggKDQoFBAICAAESBJoBCQ0KDQoFBAICAAMSBJoB
EBEKDQoFBAICAAgSBJoBEjwKEAoIBAICAAicCAASBJoBEzsKUAoEBAICARIEnQECGhpCIFRo
ZSBkaXNwbGF5IG5hbWUgZm9yIHRoaXMgdGVtcGxhdGUuIERlZmF1bHRzIHRvIGFuIGVtcHR5
IHN0cmluZy4KCg0KBQQCAgEFEgSdAQIICg0KBQQCAgEBEgSdAQkVCg0KBQQCAgEDEgSdARgZ
CucDCgQEAgICEganAQKoAS8a1gMgUmVxdWlyZWQuIE1hcCBvZiB0YWcgdGVtcGxhdGUgZmll
bGQgSURzIHRvIHRoZSBzZXR0aW5ncyBmb3IgdGhlIGZpZWxkLgogVGhpcyBtYXAgaXMgYW4g
ZXhoYXVzdGl2ZSBsaXN0IG9mIHRoZSBhbGxvd2VkIGZpZWxkcy4gVGhpcyBtYXAgbXVzdCBj
b250YWluCiBhdCBsZWFzdCBvbmUgZmllbGQgYW5kIGF0IG1vc3QgNTAwIGZpZWxkcy4KCiBU
aGUga2V5cyB0byB0aGlzIG1hcCBhcmUgdGFnIHRlbXBsYXRlIGZpZWxkIElEcy4gRmllbGQg
SURzIGNhbiBjb250YWluCiBsZXR0ZXJzIChib3RoIHVwcGVyY2FzZSBhbmQgbG93ZXJjYXNl
KSwgbnVtYmVycyAoMC05KSBhbmQgdW5kZXJzY29yZXMgKF8pLgogRmllbGQgSURzIG11c3Qg
YmUgYXQgbGVhc3QgMSBjaGFyYWN0ZXIgbG9uZyBhbmQgYXQgbW9zdAogNjQgY2hhcmFjdGVy
cyBsb25nLiBGaWVsZCBJRHMgbXVzdCBzdGFydCB3aXRoIGEgbGV0dGVyIG9yIHVuZGVyc2Nv
cmUuCgoNCgUEAgICBhIEpwECHwoNCgUEAgICARIEpwEgJgoNCgUEAgICAxIEpwEpKgoNCgUE
AgICCBIEqAEGLgoQCggEAgICCJwIABIEqAEHLQpBCgQEAgIDEgarAQKsATIaMSBPdXRwdXQg
b25seS4gVHJhbnNmZXIgc3RhdHVzIG9mIHRoZSBUYWdUZW1wbGF0ZQoKDQoFBAICAwYSBKsB
AhgKDQoFBAICAwESBKsBGTEKDQoFBAICAwMSBKsBNDUKDQoFBAICAwgSBKwBBjEKEAoIBAIC
AwicCAASBKwBBzAKSwoCBAMSBrABANMBARo9IFRoZSB0ZW1wbGF0ZSBmb3IgYW4gaW5kaXZp
ZHVhbCBmaWVsZCB3aXRoaW4gYSB0YWcgdGVtcGxhdGUuCgoLCgMEAwESBLABCBgKDQoDBAMH
EgaxAQK0AQQKDwoFBAMHnQgSBrEBArQBBAqmAgoEBAMCABIGvQECwAEEGpUCIE91dHB1dCBv
bmx5LiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgdGFnIHRlbXBsYXRl
IGZpZWxkIGluIFVSTAogZm9ybWF0LiBFeGFtcGxlOgoKICogcHJvamVjdHMve3Byb2plY3Rf
aWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3RhZ1RlbXBsYXRlcy97dGFnX3RlbXBsYXRlfS9m
aWVsZHMve2ZpZWxkfQoKIE5vdGUgdGhhdCB0aGlzIFRhZ1RlbXBsYXRlRmllbGQgbWF5IG5v
dCBhY3R1YWxseSBiZSBzdG9yZWQgaW4gdGhlIGxvY2F0aW9uCiBpbiB0aGlzIG5hbWUuCgoN
CgUEAwIABRIEvQECCAoNCgUEAwIAARIEvQEJDQoNCgUEAwIAAxIEvQEQEQoPCgUEAwIACBIG
vQESwAEDChAKCAQDAgAInAgAEgS+AQQsChAKCAQDAgAInAgBEgS/AQQtCk0KBAQDAgESBMMB
AhoaPyBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGlzIGZpZWxkLiBEZWZhdWx0cyB0byBhbiBl
bXB0eSBzdHJpbmcuCgoNCgUEAwIBBRIEwwECCAoNCgUEAwIBARIEwwEJFQoNCgUEAwIBAxIE
wwEYGQpHCgQEAwICEgTGAQI+GjkgUmVxdWlyZWQuIFRoZSB0eXBlIG9mIHZhbHVlIHRoaXMg
dGFnIGZpZWxkIGNhbiBjb250YWluLgoKDQoFBAMCAgYSBMYBAgsKDQoFBAMCAgESBMYBDBAK
DQoFBAMCAgMSBMYBExQKDQoFBAMCAggSBMYBFT0KEAoIBAMCAgicCAASBMYBFjwKRAoEBAMC
AxIEyQECFxo2IFdoZXRoZXIgdGhpcyBpcyBhIHJlcXVpcmVkIGZpZWxkLiBEZWZhdWx0cyB0
byBmYWxzZS4KCg0KBQQDAgMFEgTJAQIGCg0KBQQDAgMBEgTJAQcSCg0KBQQDAgMDEgTJARUW
CkwKBAQDAgQSBMwBAhkaPiBUaGUgZGVzY3JpcHRpb24gZm9yIHRoaXMgZmllbGQuIERlZmF1
bHRzIHRvIGFuIGVtcHR5IHN0cmluZy4KCg0KBQQDAgQFEgTMAQIICg0KBQQDAgQBEgTMAQkU
Cg0KBQQDAgQDEgTMARcYCpACCgQEAwIFEgTSAQISGoECIFRoZSBvcmRlciBvZiB0aGlzIGZp
ZWxkIHdpdGggcmVzcGVjdCB0byBvdGhlciBmaWVsZHMgaW4gdGhpcyB0YWcKIHRlbXBsYXRl
LiAgQSBoaWdoZXIgdmFsdWUgaW5kaWNhdGVzIGEgbW9yZSBpbXBvcnRhbnQgZmllbGQuIFRo
ZSB2YWx1ZSBjYW4KIGJlIG5lZ2F0aXZlLiBNdWx0aXBsZSBmaWVsZHMgY2FuIGhhdmUgdGhl
IHNhbWUgb3JkZXIsIGFuZCBmaWVsZCBvcmRlcnMKIHdpdGhpbiBhIHRhZyBkbyBub3QgaGF2
ZSB0byBiZSBzZXF1ZW50aWFsLgoKDQoFBAMCBQUSBNIBAgcKDQoFBAMCBQESBNIBCA0KDQoF
BAMCBQMSBNIBEBEKDAoCBAQSBtUBAPkBAQoLCgMEBAESBNUBCBEKDgoEBAQEABIG1gEC5QED
Cg0KBQQEBAABEgTWAQcUCj8KBgQEBAACABIE2AEEIxovIFRoaXMgaXMgdGhlIGRlZmF1bHQg
aW52YWxpZCB2YWx1ZSBmb3IgYSB0eXBlLgoKDwoHBAQEAAIAARIE2AEEHgoPCgcEBAQAAgAC
EgTYASEiCiwKBgQEBAACARIE2wEEDxocIEEgZG91YmxlIHByZWNpc2lvbiBudW1iZXIuCgoP
CgcEBAQAAgEBEgTbAQQKCg8KBwQEBAACAQISBNsBDQ4KIgoGBAQEAAICEgTeAQQPGhIgQW4g
VVRGLTggc3RyaW5nLgoKDwoHBAQEAAICARIE3gEECgoPCgcEBAQAAgICEgTeAQ0OCiIKBgQE
BAACAxIE4QEEDRoSIEEgYm9vbGVhbiB2YWx1ZS4KCg8KBwQEBAACAwESBOEBBAgKDwoHBAQE
AAIDAhIE4QELDAoeCgYEBAQAAgQSBOQBBBIaDiBBIHRpbWVzdGFtcC4KCg8KBwQEBAACBAES
BOQBBA0KDwoHBAQEAAIEAhIE5AEQEQoOCgQEBAMAEgbnAQLvAQMKDQoFBAQDAAESBOcBChIK
EAoGBAQDAAMAEgboAQTsAQUKDwoHBAQDAAMAARIE6AEMFQpfCggEBAMAAwACABIE6wEGRxpN
IFJlcXVpcmVkLiBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBlbnVtIHZhbHVlLiBNdXN0IG5v
dCBiZSBhbiBlbXB0eQogc3RyaW5nLgoKEQoJBAQDAAMAAgAFEgTrAQYMChEKCQQEAwADAAIA
ARIE6wENGQoRCgkEBAMAAwACAAMSBOsBHB0KEQoJBAQDAAMAAgAIEgTrAR5GChQKDAQEAwAD
AAIACJwIABIE6wEfRQoOCgYEBAMAAgASBO4BBCoKDwoHBAQDAAIABBIE7gEEDAoPCgcEBAMA
AgAGEgTuAQ0WCg8KBwQEAwACAAESBO4BFyUKDwoHBAQDAAIAAxIE7gEoKQobCgQEBAgAEgby
AQL4AQMaCyBSZXF1aXJlZC4KCg0KBQQECAABEgTyAQgRCj4KBAQEAgASBPQBBCUaMCBSZXBy
ZXNlbnRzIHByaW1pdGl2ZSB0eXBlcyAtIHN0cmluZywgYm9vbCBldGMuCgoNCgUEBAIABhIE
9AEEEQoNCgUEBAIAARIE9AESIAoNCgUEBAIAAxIE9AEjJAooCgQEBAIBEgT3AQQbGhogUmVw
cmVzZW50cyBhbiBlbnVtIHR5cGUuCgoNCgUEBAIBBhIE9wEEDAoNCgUEBAIBARIE9wENFgoN
CgUEBAIBAxIE9wEZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Tags::Tag ===
    # Fields for Tag
    # Field: name Type: 9 ()
    # Field: template Type: 9 ()
    # Field: template_display_name Type: 9 ()
    # Field: column Type: 9 ()
    # Field: fields Type: 11 (.google.cloud.datacatalog.v1beta1.Tag.FieldsEntry)

# === Message: Google::Cloud::Datacatalog::V1beta1::Tags::TagField ===
    # Fields for TagField
    # Field: display_name Type: 9 ()
    # Field: double_value Type: 1 ()
    # Field: string_value Type: 9 ()
    # Field: bool_value Type: 8 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: enum_value Type: 11 (.google.cloud.datacatalog.v1beta1.TagField.EnumValue)
    # Field: order Type: 5 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate ===
    # Fields for TagTemplate
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: fields Type: 11 (.google.cloud.datacatalog.v1beta1.TagTemplate.FieldsEntry)
    # Field: dataplex_transfer_status Type: 14 (.google.cloud.datacatalog.v1beta1.TagTemplate.DataplexTransferStatus)

# Enum: TagTemplate::DataplexTransferStatus
our $TagTemplate_DATAPLEX_TRANSFER_STATUS_UNSPECIFIED = 0;
our $TagTemplate_MIGRATED = 1;

# === Message: Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplateField ===
    # Fields for TagTemplateField
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: type Type: 11 (.google.cloud.datacatalog.v1beta1.FieldType)
    # Field: is_required Type: 8 ()
    # Field: description Type: 9 ()
    # Field: order Type: 5 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Tags::FieldType ===
    # Fields for FieldType
    # Field: primitive_type Type: 14 (.google.cloud.datacatalog.v1beta1.FieldType.PrimitiveType)
    # Field: enum_type Type: 11 (.google.cloud.datacatalog.v1beta1.FieldType.EnumType)

# Enum: FieldType::PrimitiveType
our $FieldType_PRIMITIVE_TYPE_UNSPECIFIED = 0;
our $FieldType_DOUBLE = 1;
our $FieldType_STRING = 2;
our $FieldType_BOOL = 3;
our $FieldType_TIMESTAMP = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Tags - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/tags.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Tags;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Tags::Tag->new({
        name => $name,
        template => $template,
        template_display_name => $template_display_name,
        column => $column,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Tags::Tag->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/tags.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Tags::Tag

Tags are used to attach custom metadata to Data Catalog resources. Tags
conform to the specifications within their tag template.

See [Data Catalog
IAM](https://cloud.google.com/data-catalog/docs/concepts/iam) for information
on the permissions needed to create or view tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tag in URL format. Example:

* projects/{project_id}/locations/{location}/entrygroups/{entry_group_id}/entries/{entry_id}/tags/{tag_id}

where `tag_id` is a system-generated identifier.
Note that this Tag may not actually be stored in the location in this name.

=item * C<< $msg->template() >> / C<< $msg->template($value) >>

Type: C<String>

Required. The resource name of the tag template that this tag uses.
Example:

* projects/{project_id}/locations/{location}/tagTemplates/{tag_template_id}

This field cannot be modified after creation.

=item * C<< $msg->template_display_name() >> / C<< $msg->template_display_name($value) >>

Type: C<String>

Output only. The display name of the tag template.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<String>

Resources like Entry can have schemas associated with them. This scope
allows users to attach tags to an individual column based on that schema.

For attaching a tag to a nested column, use `.` to separate the column
names. Example:

* `outer_column.inner_column`

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Tags::Tag::FieldsEntry>)

Required. This maps the ID of a tag field to the value of and additional
information about that field. Valid field IDs are defined by the tag's
template. A tag must have at least 1 field and at most 500 fields.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Tags::TagField

Contains the value and supporting information for a field within
a [Tag][google.cloud.datacatalog.v1beta1.Tag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of this field.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

Holds the value for a tag field with double type.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Holds the value for a tag field with string type.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

Holds the value for a tag field with boolean type.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Holds the value for a tag field with timestamp type.

=item * C<< $msg->enum_value() >> / C<< $msg->enum_value($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Tags::TagField::EnumValue>)

Holds the value for a tag field with enum type. This value must be
one of the allowed values in the definition of this enum.

=item * C<< $msg->order() >> / C<< $msg->order($value) >>

Type: C<Int32>

Output only. The order of this field with respect to other fields in this
tag. It can be set in
[Tag][google.cloud.datacatalog.v1beta1.TagTemplateField.order]. For
example, a higher value can indicate a more important field. The value can
be negative. Multiple fields can have the same order, and field orders
within a tag do not have to be sequential.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate

A tag template defines a tag, which can have one or more typed fields.
The template is used to create and attach the tag to Google Cloud resources.
[Tag template
roles](https://cloud.google.com/iam/docs/understanding-roles#data-catalog-roles)
provide permissions to create, edit, and use the template. See, for example,
the [TagTemplate
User](https://cloud.google.com/data-catalog/docs/how-to/template-user) role,
which includes permission to use the tag template to tag resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tag template in URL format. Example:

* projects/{project_id}/locations/{location}/tagTemplates/{tag_template_id}

Note that this TagTemplate and its child resources may not actually be
stored in the location in this name.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name for this template. Defaults to an empty string.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate::FieldsEntry>)

Required. Map of tag template field IDs to the settings for the field.
This map is an exhaustive list of the allowed fields. This map must contain
at least one field and at most 500 fields.

The keys to this map are tag template field IDs. Field IDs can contain
letters (both uppercase and lowercase), numbers (0-9) and underscores (_).
Field IDs must be at least 1 character long and at most
64 characters long. Field IDs must start with a letter or underscore.

=item * C<< $msg->dataplex_transfer_status() >> / C<< $msg->dataplex_transfer_status($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::TagTemplate::DataplexTransferStatus>)

Output only. Transfer status of the TagTemplate

=back

=head3 Enum: TagTemplate::DataplexTransferStatus

=over 4

=item * C<DATAPLEX_TRANSFER_STATUS_UNSPECIFIED> => C<0>

=item * C<MIGRATED> => C<1>

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplateField

The template for an individual field within a tag template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the tag template field in URL
format. Example:

* projects/{project_id}/locations/{location}/tagTemplates/{tag_template}/fields/{field}

Note that this TagTemplateField may not actually be stored in the location
in this name.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name for this field. Defaults to an empty string.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Tags::FieldType>)

Required. The type of value this tag field can contain.

=item * C<< $msg->is_required() >> / C<< $msg->is_required($value) >>

Type: C<Bool>

Whether this is a required field. Defaults to false.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description for this field. Defaults to an empty string.

=item * C<< $msg->order() >> / C<< $msg->order($value) >>

Type: C<Int32>

The order of this field with respect to other fields in this tag
template.  A higher value indicates a more important field. The value can
be negative. Multiple fields can have the same order, and field orders
within a tag do not have to be sequential.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Tags::FieldType

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primitive_type() >> / C<< $msg->primitive_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::FieldType::PrimitiveType>)

Represents primitive types - string, bool etc.

=item * C<< $msg->enum_type() >> / C<< $msg->enum_type($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType>)

Represents an enum type.

=back

=head3 Enum: FieldType::PrimitiveType

=over 4

=item * C<PRIMITIVE_TYPE_UNSPECIFIED> => C<0>

=item * C<DOUBLE> => C<1>

=item * C<STRING> => C<2>

=item * C<BOOL> => C<3>

=item * C<TIMESTAMP> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Tags::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
