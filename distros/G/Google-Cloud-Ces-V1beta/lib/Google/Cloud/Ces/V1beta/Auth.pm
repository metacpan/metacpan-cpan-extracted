package Google::Cloud::Ces::V1beta::Auth;

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
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hdXRoLnByb3RvEhdnb29nbGUuY2xvdWQuY2Vz
LnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90byLRAgoMQXBpS2V5Q29uZmlnEh4KCGtleV9uYW1lGAEgASgJQgPgQQJS
B2tleU5hbWUSZwoWYXBpX2tleV9zZWNyZXRfdmVyc2lvbhgCIAEoCUIy4EEC+kEsCipzZWNy
ZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1NlY3JldFZlcnNpb25SE2FwaUtleVNlY3JldFZl
cnNpb24SZQoQcmVxdWVzdF9sb2NhdGlvbhgDIAEoDjI1Lmdvb2dsZS5jbG91ZC5jZXMudjFi
ZXRhLkFwaUtleUNvbmZpZy5SZXF1ZXN0TG9jYXRpb25CA+BBAlIPcmVxdWVzdExvY2F0aW9u
IlEKD1JlcXVlc3RMb2NhdGlvbhIgChxSRVFVRVNUX0xPQ0FUSU9OX1VOU1BFQ0lGSUVEEAAS
CgoGSEVBREVSEAESEAoMUVVFUllfU1RSSU5HEAIijwMKC09BdXRoQ29uZmlnEmIKEG9hdXRo
X2dyYW50X3R5cGUYASABKA4yMy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5PQXV0aENvbmZp
Zy5PYXV0aEdyYW50VHlwZUID4EECUg5vYXV0aEdyYW50VHlwZRIgCgljbGllbnRfaWQYAiAB
KAlCA+BBAlIIY2xpZW50SWQSZgoVY2xpZW50X3NlY3JldF92ZXJzaW9uGAMgASgJQjLgQQL6
QSwKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvblITY2xpZW50
U2VjcmV0VmVyc2lvbhIqCg50b2tlbl9lbmRwb2ludBgEIAEoCUID4EECUg10b2tlbkVuZHBv
aW50EhsKBnNjb3BlcxgFIAMoCUID4EEBUgZzY29wZXMiSQoOT2F1dGhHcmFudFR5cGUSIAoc
T0FVVEhfR1JBTlRfVFlQRV9VTlNQRUNJRklFRBAAEhUKEUNMSUVOVF9DUkVERU5USUFMEAEi
HwodU2VydmljZUFnZW50SWRUb2tlbkF1dGhDb25maWciZQoYU2VydmljZUFjY291bnRBdXRo
Q29uZmlnEiwKD3NlcnZpY2VfYWNjb3VudBgBIAEoCUID4EECUg5zZXJ2aWNlQWNjb3VudBIb
CgZzY29wZXMYAiADKAlCA+BBAVIGc2NvcGVzIi4KEUJlYXJlclRva2VuQ29uZmlnEhkKBXRv
a2VuGAEgASgJQgPgQQJSBXRva2VuItADChFFbmRVc2VyQXV0aENvbmZpZxJ4ChdvYXV0aDJf
YXV0aF9jb2RlX2NvbmZpZxgCIAEoCzI/Lmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkVuZFVz
ZXJBdXRoQ29uZmlnLk9hdXRoMkF1dGhDb2RlQ29uZmlnSABSFG9hdXRoMkF1dGhDb2RlQ29u
ZmlnEnsKGG9hdXRoMl9qd3RfYmVhcmVyX2NvbmZpZxgDIAEoCzJALmdvb2dsZS5jbG91ZC5j
ZXMudjFiZXRhLkVuZFVzZXJBdXRoQ29uZmlnLk9hdXRoMkp3dEJlYXJlckNvbmZpZ0gAUhVv
YXV0aDJKd3RCZWFyZXJDb25maWcaPAoUT2F1dGgyQXV0aENvZGVDb25maWcSJAoLb2F1dGhf
dG9rZW4YASABKAlCA+BBAlIKb2F1dGhUb2tlbhp3ChVPYXV0aDJKd3RCZWFyZXJDb25maWcS
GwoGaXNzdWVyGAEgASgJQgPgQQJSBmlzc3VlchIdCgdzdWJqZWN0GAIgASgJQgPgQQJSB3N1
YmplY3QSIgoKY2xpZW50X2tleRgDIAEoCUID4EECUgljbGllbnRLZXlCDQoLYXV0aF9jb25m
aWcirQQKEUFwaUF1dGhlbnRpY2F0aW9uElIKDmFwaV9rZXlfY29uZmlnGAEgASgLMiUuZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEuQXBpS2V5Q29uZmlnQgPgQQFIAFIMYXBpS2V5Q29uZmln
Ek4KDG9hdXRoX2NvbmZpZxgCIAEoCzIkLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLk9BdXRo
Q29uZmlnQgPgQQFIAFILb2F1dGhDb25maWcSiAEKInNlcnZpY2VfYWdlbnRfaWRfdG9rZW5f
YXV0aF9jb25maWcYAyABKAsyNi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TZXJ2aWNlQWdl
bnRJZFRva2VuQXV0aENvbmZpZ0ID4EEBSABSHXNlcnZpY2VBZ2VudElkVG9rZW5BdXRoQ29u
ZmlnEncKG3NlcnZpY2VfYWNjb3VudF9hdXRoX2NvbmZpZxgEIAEoCzIxLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLlNlcnZpY2VBY2NvdW50QXV0aENvbmZpZ0ID4EEBSABSGHNlcnZpY2VB
Y2NvdW50QXV0aENvbmZpZxJhChNiZWFyZXJfdG9rZW5fY29uZmlnGAUgASgLMiouZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEuQmVhcmVyVG9rZW5Db25maWdCA+BBAUgAUhFiZWFyZXJUb2tl
bkNvbmZpZ0INCgthdXRoX2NvbmZpZ0LHAQobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
QglBdXRoUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3Bi
O2Nlc3Bi6kFrCipzZWNyZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1NlY3JldFZlcnNpb24S
PXByb2plY3RzL3twcm9qZWN0fS9zZWNyZXRzL3tzZWNyZXR9L3ZlcnNpb25zL3tzZWNyZXRf
dmVyc2lvbn1KvjcKBxIFDgDCAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUARAoJCgIICxIDFQBE
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAKgoJCgIICBIDFwAqCggKAQgSAxgANAoJ
CgIIARIDGAA0CgkKAQgSBBkAHAIKDAoECJ0IABIEGQAcAgo9CgIEABIEHwBAARoxIENvbmZp
Z3VyYXRpb25zIGZvciBhdXRoZW50aWNhdGlvbiB3aXRoIEFQSSBrZXkuCgoKCgMEAAESAx8I
FAo7CgQEAAQAEgQhAioDGi0gVGhlIGxvY2F0aW9uIG9mIHRoZSBBUEkga2V5IGluIHRoZSBy
ZXF1ZXN0LgoKDAoFBAAEAAESAyEHFgo8CgYEAAQAAgASAyMEJRotIFVuc3BlY2lmaWVkLiBU
aGlzIHZhbHVlIHNob3VsZCBub3QgYmUgdXNlZC4KCg4KBwQABAACAAESAyMEIAoOCgcEAAQA
AgACEgMjIyQKMwoGBAAEAAIBEgMmBA8aJCBSZXByZXNlbnRzIHRoZSBrZXkgaW4gaHR0cCBo
ZWFkZXIuCgoOCgcEAAQAAgEBEgMmBAoKDgoHBAAEAAIBAhIDJg0OCjQKBgQABAACAhIDKQQV
GiUgUmVwcmVzZW50cyB0aGUga2V5IGluIHF1ZXJ5IHN0cmluZy4KCg4KBwQABAACAgESAykE
EAoOCgcEAAQAAgICEgMpExQKxQEKBAQAAgASAy8CPxq3ASBSZXF1aXJlZC4gVGhlIHBhcmFt
ZXRlciBuYW1lIG9yIHRoZSBoZWFkZXIgbmFtZSBvZiB0aGUgQVBJIGtleS4KIEUuZy4sIElm
IHRoZSBBUEkgcmVxdWVzdCBpcyAiaHR0cHM6Ly9leGFtcGxlLmNvbS9hY3Q/WC1BcGktS2V5
PTxBUEkKIEtFWT4iLCAiWC1BcGktS2V5IiB3b3VsZCBiZSB0aGUgcGFyYW1ldGVyIG5hbWUu
CgoMCgUEAAIABRIDLwIICgwKBQQAAgABEgMvCREKDAoFBAACAAMSAy8UFQoMCgUEAAIACBID
LxY+Cg8KCAQAAgAInAgAEgMvFz0KxAIKBAQAAgESBDcCPAQatQIgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBTZWNyZXRNYW5hZ2VyIHNlY3JldCB2ZXJzaW9uIHJlc291cmNlIHN0b3Jp
bmcgdGhlCiBBUEkga2V5LiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vc2VjcmV0cy97
c2VjcmV0fS92ZXJzaW9ucy97dmVyc2lvbn1gCgogTm90ZTogWW91IHNob3VsZCBncmFudCBg
cm9sZXMvc2VjcmV0bWFuYWdlci5zZWNyZXRBY2Nlc3NvcmAgcm9sZSB0byB0aGUgQ0VTCiBz
ZXJ2aWNlIGFnZW50CiBgc2VydmljZS08UFJPSkVDVC1OVU1CRVI+QGdjcC1zYS1jZXMuaWFt
LmdzZXJ2aWNlYWNjb3VudC5jb21gLgoKDAoFBAACAQUSAzcCCAoMCgUEAAIBARIDNwkfCgwK
BQQAAgEDEgM3IiMKDQoFBAACAQgSBDckPAMKDwoIBAACAQicCAASAzgEKgoPCgcEAAIBCJ8I
EgQ5BDsFCjUKBAQAAgISAz8CUBooIFJlcXVpcmVkLiBLZXkgbG9jYXRpb24gaW4gdGhlIHJl
cXVlc3QuCgoMCgUEAAICBhIDPwIRCgwKBQQAAgIBEgM/EiIKDAoFBAACAgMSAz8lJgoMCgUE
AAICCBIDPydPCg8KCAQAAgIInAgAEgM/KE4KOwoCBAESBEMAaQEaLyBDb25maWd1cmF0aW9u
cyBmb3IgYXV0aGVudGljYXRpb24gd2l0aCBPQXV0aC4KCgoKAwQBARIDQwgTCoQBCgQEAQQA
EgRGAk0DGnYgT0F1dGggZ3JhbnQgdHlwZXMuIE9ubHkgW2NsaWVudCBjcmVkZW50aWFsCiBn
cmFudF0oaHR0cHM6Ly9vYXV0aC5uZXQvMi9ncmFudC10eXBlcy9jbGllbnQtY3JlZGVudGlh
bHMpIGlzIHN1cHBvcnRlZC4KCgwKBQQBBAABEgNGBxUKPAoGBAEEAAIAEgNIBCUaLSBVbnNw
ZWNpZmllZC4gRGVmYXVsdHMgdG8gQ0xJRU5UX0NSRURFTlRJQUwuCgoOCgcEAQQAAgABEgNI
BCAKDgoHBAEEAAIAAhIDSCMkCm4KBgQBBAACARIDTAQaGl8gUmVwcmVzZW50cyB0aGUgW2Ns
aWVudCBjcmVkZW50aWFsCiBmbG93XShodHRwczovL29hdXRoLm5ldC8yL2dyYW50LXR5cGVz
L2NsaWVudC1jcmVkZW50aWFscykuCgoOCgcEAQQAAgEBEgNMBBUKDgoHBAEEAAIBAhIDTBgZ
CisKBAQBAgASA1ACTxoeIFJlcXVpcmVkLiBPQXV0aCBncmFudCB0eXBlcy4KCgwKBQQBAgAG
EgNQAhAKDAoFBAECAAESA1ARIQoMCgUEAQIAAxIDUCQlCgwKBQQBAgAIEgNQJk4KDwoIBAEC
AAicCAASA1AnTQo/CgQEAQIBEgNTAkAaMiBSZXF1aXJlZC4gVGhlIGNsaWVudCBJRCBmcm9t
IHRoZSBPQXV0aCBwcm92aWRlci4KCgwKBQQBAgEFEgNTAggKDAoFBAECAQESA1MJEgoMCgUE
AQIBAxIDUxUWCgwKBQQBAgEIEgNTFz8KDwoIBAECAQicCAASA1MYPgrLAgoEBAECAhIEXAJh
BBq8AiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFNlY3JldE1hbmFnZXIgc2VjcmV0IHZl
cnNpb24gcmVzb3VyY2Ugc3RvcmluZyB0aGUKIGNsaWVudCBzZWNyZXQuCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vc2VjcmV0cy97c2VjcmV0fS92ZXJzaW9ucy97dmVyc2lvbn1g
CgogTm90ZTogWW91IHNob3VsZCBncmFudCBgcm9sZXMvc2VjcmV0bWFuYWdlci5zZWNyZXRB
Y2Nlc3NvcmAgcm9sZSB0byB0aGUgQ0VTCiBzZXJ2aWNlIGFnZW50CiBgc2VydmljZS08UFJP
SkVDVC1OVU1CRVI+QGdjcC1zYS1jZXMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gLgoKDAoF
BAECAgUSA1wCCAoMCgUEAQICARIDXAkeCgwKBQQBAgIDEgNcISIKDQoFBAECAggSBFwjYQMK
DwoIBAECAgicCAASA10EKgoPCgcEAQICCJ8IEgReBGAFCmMKBAQBAgMSA2UCRRpWIFJlcXVp
cmVkLiBUaGUgdG9rZW4gZW5kcG9pbnQgaW4gdGhlIE9BdXRoIHByb3ZpZGVyIHRvIGV4Y2hh
bmdlIGZvciBhbgogYWNjZXNzIHRva2VuLgoKDAoFBAECAwUSA2UCCAoMCgUEAQIDARIDZQkX
CgwKBQQBAgMDEgNlGhsKDAoFBAECAwgSA2UcRAoPCggEAQIDCJwIABIDZR1DCjMKBAQBAgQS
A2gCRhomIE9wdGlvbmFsLiBUaGUgT0F1dGggc2NvcGVzIHRvIGdyYW50LgoKDAoFBAECBAQS
A2gCCgoMCgUEAQIEBRIDaAsRCgwKBQQBAgQBEgNoEhgKDAoFBAECBAMSA2gbHAoMCgUEAQIE
CBIDaB1FCg8KCAQBAgQInAgAEgNoHkQKnAEKAgQCEgNuACgakAEgQ29uZmlndXJhdGlvbnMg
Zm9yIGF1dGhlbnRpY2F0aW9uIHdpdGggW0lECiB0b2tlbl0oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2RvY3MvYXV0aGVudGljYXRpb24vdG9rZW4tdHlwZXMjaWQpIGdlbmVyYXRlZAog
ZnJvbSBzZXJ2aWNlIGFnZW50LgoKCgoDBAIBEgNuCCUKTwoCBAMSBHEAfwEaQyBDb25maWd1
cmF0aW9ucyBmb3IgYXV0aGVudGljYXRpb24gdXNpbmcgYSBjdXN0b20gc2VydmljZSBhY2Nv
dW50LgoKCgoDBAMBEgNxCCAKmgMKBAQDAgASA3oCRhqMAyBSZXF1aXJlZC4gVGhlIGVtYWls
IGFkZHJlc3Mgb2YgdGhlIHNlcnZpY2UgYWNjb3VudCB1c2VkIGZvciBhdXRoZW50aWNhdGlv
bi4KIENFUyB1c2VzIHRoaXMgc2VydmljZSBhY2NvdW50IHRvIGV4Y2hhbmdlIGFuIGFjY2Vz
cyB0b2tlbiBhbmQgdGhlIGFjY2VzcwogdG9rZW4gaXMgdGhlbiBzZW50IGluIHRoZSBgQXV0
aG9yaXphdGlvbmAgaGVhZGVyIG9mIHRoZSByZXF1ZXN0LgoKIFRoZSBzZXJ2aWNlIGFjY291
bnQgbXVzdCBoYXZlIHRoZQogYHJvbGVzL2lhbS5zZXJ2aWNlQWNjb3VudFRva2VuQ3JlYXRv
cmAgcm9sZSBncmFudGVkIHRvIHRoZQogQ0VTIHNlcnZpY2UgYWdlbnQKIGBzZXJ2aWNlLTxQ
Uk9KRUNULU5VTUJFUj5AZ2NwLXNhLWNlcy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgoM
CgUEAwIABRIDegIICgwKBQQDAgABEgN6CRgKDAoFBAMCAAMSA3obHAoMCgUEAwIACBIDeh1F
Cg8KCAQDAgAInAgAEgN6HkQKkwEKBAQDAgESA34CRhqFASBPcHRpb25hbC4gVGhlIE9BdXRo
IHNjb3BlcyB0byBncmFudC4gSWYgbm90IHNwZWNpZmllZCwgdGhlIGRlZmF1bHQgc2NvcGUK
IGBodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtYCBpcyB1
c2VkLgoKDAoFBAMCAQQSA34CCgoMCgUEAwIBBRIDfgsRCgwKBQQDAgEBEgN+EhgKDAoFBAMC
AQMSA34bHAoMCgUEAwIBCBIDfh1FCg8KCAQDAgEInAgAEgN+HkQKRgoCBAQSBoIBAIYBARo4
IENvbmZpZ3VyYXRpb25zIGZvciBhdXRoZW50aWNhdGlvbiB3aXRoIGEgYmVhcmVyIHRva2Vu
LgoKCwoDBAQBEgSCAQgZCmsKBAQEAgASBIUBAjwaXSBSZXF1aXJlZC4gVGhlIGJlYXJlciB0
b2tlbi4KIE11c3QgYmUgaW4gdGhlIGZvcm1hdCBgJGNvbnRleHQudmFyaWFibGVzLjxuYW1l
X29mX3ZhcmlhYmxlPmAuCgoNCgUEBAIABRIEhQECCAoNCgUEBAIAARIEhQEJDgoNCgUEBAIA
AxIEhQEREgoNCgUEBAIACBIEhQETOwoQCggEBAIACJwIABIEhQEUOgrCAQoCBAUSBosBAKoB
ARqzASBFbmQtdXNlciBhdXRoZW50aWNhdGlvbiBjb25maWd1cmF0aW9uIHVzZWQgZm9yIENv
bm5lY3Rpb24gY2FsbHMuCiBUaGUgZmllbGQgdmFsdWVzIG11c3QgYmUgdGhlIG5hbWVzIG9m
IGNvbnRleHQgdmFyaWFibGVzIGluIHRoZSBmb3JtYXQKIGAkY29udGV4dC52YXJpYWJsZXMu
PG5hbWVfb2ZfdmFyaWFibGU+YC4KCgsKAwQFARIEiwEIGQpMCgQEBQMAEgaNAQKRAQMaPCBP
YXV0aCAyLjAgQXV0aG9yaXphdGlvbiBDb2RlIGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRp
b24uCgoNCgUEBQMAARIEjQEKHgqHAQoGBAUDAAIAEgSQAQREGncgUmVxdWlyZWQuIE9hdXRo
IHRva2VuIHBhcmFtZXRlciBuYW1lIHRvIHBhc3MgdGhyb3VnaC4KIE11c3QgYmUgaW4gdGhl
IGZvcm1hdCBgJGNvbnRleHQudmFyaWFibGVzLjxuYW1lX29mX3ZhcmlhYmxlPmAuCgoPCgcE
BQMAAgAFEgSQAQQKCg8KBwQFAwACAAESBJABCxYKDwoHBAUDAAIAAxIEkAEZGgoPCgcEBQMA
AgAIEgSQARtDChIKCgQFAwACAAicCAASBJABHEIKWQoEBAUDARIGlAECoAEDGkkgSldUIFBy
b2ZpbGUgT2F1dGggMi4wIEF1dGhvcml6YXRpb24gR3JhbnQgYXV0aGVudGljYXRpb24gY29u
ZmlndXJhdGlvbi4KCg0KBQQFAwEBEgSUAQofCoIBCgYEBQMBAgASBJcBBD8aciBSZXF1aXJl
ZC4gSXNzdWVyIHBhcmFtZXRlciBuYW1lIHRvIHBhc3MgdGhyb3VnaC4KIE11c3QgYmUgaW4g
dGhlIGZvcm1hdCBgJGNvbnRleHQudmFyaWFibGVzLjxuYW1lX29mX3ZhcmlhYmxlPmAuCgoP
CgcEBQMBAgAFEgSXAQQKCg8KBwQFAwECAAESBJcBCxEKDwoHBAUDAQIAAxIElwEUFQoPCgcE
BQMBAgAIEgSXARY+ChIKCgQFAwECAAicCAASBJcBFz0KgwEKBgQFAwECARIEmwEEQBpzIFJl
cXVpcmVkLiBTdWJqZWN0IHBhcmFtZXRlciBuYW1lIHRvIHBhc3MgdGhyb3VnaC4KIE11c3Qg
YmUgaW4gdGhlIGZvcm1hdCBgJGNvbnRleHQudmFyaWFibGVzLjxuYW1lX29mX3ZhcmlhYmxl
PmAuCgoPCgcEBQMBAgEFEgSbAQQKCg8KBwQFAwECAQESBJsBCxIKDwoHBAUDAQIBAxIEmwEV
FgoPCgcEBQMBAgEIEgSbARc/ChIKCgQFAwECAQicCAASBJsBGD4KggEKBgQFAwECAhIEnwEE
QxpyIFJlcXVpcmVkLiBDbGllbnQgcGFyYW1ldGVyIG5hbWUgdG8gcGFzcyB0aHJvdWdoLgog
TXVzdCBiZSBpbiB0aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5hbWVfb2ZfdmFy
aWFibGU+YC4KCg8KBwQFAwECAgUSBJ8BBAoKDwoHBAUDAQICARIEnwELFQoPCgcEBQMBAgID
EgSfARgZCg8KBwQFAwECAggSBJ8BGkIKEgoKBAUDAQICCJwIABIEnwEbQQopCgQEBQgAEgaj
AQKpAQMaGSBUaGUgYXV0aCBjb25maWd1cmF0aW9uLgoKDQoFBAUIAAESBKMBCBMKPAoEBAUC
ABIEpQEENRouIE9hdXRoIDIuMCBBdXRob3JpemF0aW9uIENvZGUgYXV0aGVudGljYXRpb24u
CgoNCgUEBQIABhIEpQEEGAoNCgUEBQIAARIEpQEZMAoNCgUEBQIAAxIEpQEzNApJCgQEBQIB
EgSoAQQ3GjsgSldUIFByb2ZpbGUgT2F1dGggMi4wIEF1dGhvcml6YXRpb24gR3JhbnQgYXV0
aGVudGljYXRpb24uCgoNCgUEBQIBBhIEqAEEGQoNCgUEBQIBARIEqAEaMgoNCgUEBQIBAxIE
qAE1NgpCCgIEBhIGrQEAwgEBGjQgQXV0aGVudGljYXRpb24gaW5mb3JtYXRpb24gcmVxdWly
ZWQgZm9yIEFQSSBjYWxscy4KCgsKAwQGARIErQEIGQopCgQEBggAEgavAQLBAQMaGSBUaGUg
YXV0aCBjb25maWd1cmF0aW9uLgoKDQoFBAYIAAESBK8BCBMKMgoEBAYCABIEsQEETRokIE9w
dGlvbmFsLiBDb25maWcgZm9yIEFQSSBrZXkgYXV0aC4KCg0KBQQGAgAGEgSxAQQQCg0KBQQG
AgABEgSxAREfCg0KBQQGAgADEgSxASIjCg0KBQQGAgAIEgSxASRMChAKCAQGAgAInAgAEgSx
ASVLCisKBAQGAgESBLQBBEoaHSBPcHRpb25hbC4gQ29uZmlnIGZvciBPQXV0aC4KCg0KBQQG
AgEGEgS0AQQPCg0KBQQGAgEBEgS0ARAcCg0KBQQGAgEDEgS0AR8gCg0KBQQGAgEIEgS0ASFJ
ChAKCAQGAgEInAgAEgS0ASJIClYKBAQGAgISBrcBBLgBMRpGIE9wdGlvbmFsLiBDb25maWcg
Zm9yIElEIHRva2VuIGF1dGggZ2VuZXJhdGVkIGZyb20gQ0VTIHNlcnZpY2UgYWdlbnQuCgoN
CgUEBgICBhIEtwEEIQoNCgUEBgICARIEtwEiRAoNCgUEBgICAxIEtwFHSAoNCgUEBgICCBIE
uAEIMAoQCggEBgICCJwIABIEuAEJLwpGCgQEBgIDEga7AQS8ATEaNiBPcHRpb25hbC4gQ29u
ZmlnIGZvciBzZXJ2aWNlIGFjY291bnQgYXV0aGVudGljYXRpb24uCgoNCgUEBgIDBhIEuwEE
HAoNCgUEBgIDARIEuwEdOAoNCgUEBgIDAxIEuwE7PAoNCgUEBgIDCBIEvAEIMAoQCggEBgID
CJwIABIEvAEJLwo5CgQEBgIEEga/AQTAATEaKSBPcHRpb25hbC4gQ29uZmlnIGZvciBiZWFy
ZXIgdG9rZW4gYXV0aC4KCg0KBQQGAgQGEgS/AQQVCg0KBQQGAgQBEgS/ARYpCg0KBQQGAgQD
EgS/ASwtCg0KBQQGAgQIEgTAAQgwChAKCAQGAgQInAgAEgTAAQkvYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Auth::ApiKeyConfig ===
    # Fields for ApiKeyConfig
    # Field: key_name Type: 9 ()
    # Field: api_key_secret_version Type: 9 ()
    # Field: request_location Type: 14 (.google.cloud.ces.v1beta.ApiKeyConfig.RequestLocation)

# Enum: ApiKeyConfig::RequestLocation
our $ApiKeyConfig_REQUEST_LOCATION_UNSPECIFIED = 0;
our $ApiKeyConfig_HEADER = 1;
our $ApiKeyConfig_QUERY_STRING = 2;

# === Message: Google::Cloud::Ces::V1beta::Auth::OAuthConfig ===
    # Fields for OAuthConfig
    # Field: oauth_grant_type Type: 14 (.google.cloud.ces.v1beta.OAuthConfig.OauthGrantType)
    # Field: client_id Type: 9 ()
    # Field: client_secret_version Type: 9 ()
    # Field: token_endpoint Type: 9 ()
    # Field: scopes Type: 9 ()

# Enum: OAuthConfig::OauthGrantType
our $OAuthConfig_OAUTH_GRANT_TYPE_UNSPECIFIED = 0;
our $OAuthConfig_CLIENT_CREDENTIAL = 1;

# === Message: Google::Cloud::Ces::V1beta::Auth::ServiceAgentIdTokenAuthConfig ===
    # Fields for ServiceAgentIdTokenAuthConfig

# === Message: Google::Cloud::Ces::V1beta::Auth::ServiceAccountAuthConfig ===
    # Fields for ServiceAccountAuthConfig
    # Field: service_account Type: 9 ()
    # Field: scopes Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Auth::BearerTokenConfig ===
    # Fields for BearerTokenConfig
    # Field: token Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig ===
    # Fields for EndUserAuthConfig
    # Field: oauth2_auth_code_config Type: 11 (.google.cloud.ces.v1beta.EndUserAuthConfig.Oauth2AuthCodeConfig)
    # Field: oauth2_jwt_bearer_config Type: 11 (.google.cloud.ces.v1beta.EndUserAuthConfig.Oauth2JwtBearerConfig)

# === Message: Google::Cloud::Ces::V1beta::Auth::ApiAuthentication ===
    # Fields for ApiAuthentication
    # Field: api_key_config Type: 11 (.google.cloud.ces.v1beta.ApiKeyConfig)
    # Field: oauth_config Type: 11 (.google.cloud.ces.v1beta.OAuthConfig)
    # Field: service_agent_id_token_auth_config Type: 11 (.google.cloud.ces.v1beta.ServiceAgentIdTokenAuthConfig)
    # Field: service_account_auth_config Type: 11 (.google.cloud.ces.v1beta.ServiceAccountAuthConfig)
    # Field: bearer_token_config Type: 11 (.google.cloud.ces.v1beta.BearerTokenConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Auth - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/auth.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Auth;

    my $msg = Google::Cloud::Ces::V1beta::Auth::ApiKeyConfig->new({
        key_name => $key_name,
        api_key_secret_version => $api_key_secret_version,
        request_location => $request_location,
    });

    # Read or update a field
    my $val = $msg->key_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Auth::ApiKeyConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/auth.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Auth::ApiKeyConfig

Configurations for authentication with API key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key_name() >> / C<< $msg->key_name($value) >>

Type: C<String>

Required. The parameter name or the header name of the API key.
E.g., If the API request is "https://example.com/act?X-Api-Key=<API
KEY>", "X-Api-Key" would be the parameter name.

=item * C<< $msg->api_key_secret_version() >> / C<< $msg->api_key_secret_version($value) >>

Type: C<String>

Required. The name of the SecretManager secret version resource storing the
API key. Format: `projects/{project}/secrets/{secret}/versions/{version}`

Note: You should grant `roles/secretmanager.secretAccessor` role to the CES
service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->request_location() >> / C<< $msg->request_location($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::ApiKeyConfig::RequestLocation>)

Required. Key location in the request.

=back

=head3 Enum: ApiKeyConfig::RequestLocation

=over 4

=item * C<REQUEST_LOCATION_UNSPECIFIED> => C<0>

=item * C<HEADER> => C<1>

=item * C<QUERY_STRING> => C<2>

=back

=head2 Google::Cloud::Ces::V1beta::Auth::OAuthConfig

Configurations for authentication with OAuth.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth_grant_type() >> / C<< $msg->oauth_grant_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::OAuthConfig::OauthGrantType>)

Required. OAuth grant types.

=item * C<< $msg->client_id() >> / C<< $msg->client_id($value) >>

Type: C<String>

Required. The client ID from the OAuth provider.

=item * C<< $msg->client_secret_version() >> / C<< $msg->client_secret_version($value) >>

Type: C<String>

Required. The name of the SecretManager secret version resource storing the
client secret.
Format: `projects/{project}/secrets/{secret}/versions/{version}`

Note: You should grant `roles/secretmanager.secretAccessor` role to the CES
service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->token_endpoint() >> / C<< $msg->token_endpoint($value) >>

Type: C<String>

Required. The token endpoint in the OAuth provider to exchange for an
access token.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Optional. The OAuth scopes to grant.

=back

=head3 Enum: OAuthConfig::OauthGrantType

=over 4

=item * C<OAUTH_GRANT_TYPE_UNSPECIFIED> => C<0>

=item * C<CLIENT_CREDENTIAL> => C<1>

=back

=head2 Google::Cloud::Ces::V1beta::Auth::ServiceAgentIdTokenAuthConfig

Configurations for authentication with [ID
token](https://cloud.google.com/docs/authentication/token-types#id) generated
from service agent.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Ces::V1beta::Auth::ServiceAccountAuthConfig

Configurations for authentication using a custom service account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Required. The email address of the service account used for authentication.
CES uses this service account to exchange an access token and the access
token is then sent in the `Authorization` header of the request.

The service account must have the
`roles/iam.serviceAccountTokenCreator` role granted to the
CES service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Optional. The OAuth scopes to grant. If not specified, the default scope
`https://www.googleapis.com/auth/cloud-platform` is used.

=back

=head2 Google::Cloud::Ces::V1beta::Auth::BearerTokenConfig

Configurations for authentication with a bearer token.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<String>

Required. The bearer token.
Must be in the format `$context.variables.<name_of_variable>`.

=back

=head2 Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig

End-user authentication configuration used for Connection calls.
The field values must be the names of context variables in the format
`$context.variables.<name_of_variable>`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth2_auth_code_config() >> / C<< $msg->oauth2_auth_code_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig::Oauth2AuthCodeConfig>)

Oauth 2.0 Authorization Code authentication.

=item * C<< $msg->oauth2_jwt_bearer_config() >> / C<< $msg->oauth2_jwt_bearer_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig::Oauth2JwtBearerConfig>)

JWT Profile Oauth 2.0 Authorization Grant authentication.

=back

=head2 Google::Cloud::Ces::V1beta::Auth::ApiAuthentication

Authentication information required for API calls.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_key_config() >> / C<< $msg->api_key_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiKeyConfig>)

Optional. Config for API key auth.

=item * C<< $msg->oauth_config() >> / C<< $msg->oauth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::OAuthConfig>)

Optional. Config for OAuth.

=item * C<< $msg->service_agent_id_token_auth_config() >> / C<< $msg->service_agent_id_token_auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ServiceAgentIdTokenAuthConfig>)

Optional. Config for ID token auth generated from CES service agent.

=item * C<< $msg->service_account_auth_config() >> / C<< $msg->service_account_auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ServiceAccountAuthConfig>)

Optional. Config for service account authentication.

=item * C<< $msg->bearer_token_config() >> / C<< $msg->bearer_token_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::BearerTokenConfig>)

Optional. Config for bearer token auth.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Auth::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
