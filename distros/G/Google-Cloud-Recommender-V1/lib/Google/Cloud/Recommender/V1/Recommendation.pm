package Google::Cloud::Recommender::V1::Recommendation;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Money };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjEvcmVjb21tZW5kYXRpb24ucHJvdG8SG2dv
b2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0
aW9uLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvdHlwZS9tb25leS5wcm90byL4CgoOUmVjb21t
ZW5kYXRpb24SFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJ
UgtkZXNjcmlwdGlvbhIvChNyZWNvbW1lbmRlcl9zdWJ0eXBlGAwgASgJUhJyZWNvbW1lbmRl
clN1YnR5cGUSRgoRbGFzdF9yZWZyZXNoX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUg9sYXN0UmVmcmVzaFRpbWUSSgoOcHJpbWFyeV9pbXBhY3QYBSABKAsyIy5n
b29nbGUuY2xvdWQucmVjb21tZW5kZXIudjEuSW1wYWN0Ug1wcmltYXJ5SW1wYWN0ElAKEWFk
ZGl0aW9uYWxfaW1wYWN0GAYgAygLMiMuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLklt
cGFjdFIQYWRkaXRpb25hbEltcGFjdBJQCghwcmlvcml0eRgRIAEoDjI0Lmdvb2dsZS5jbG91
ZC5yZWNvbW1lbmRlci52MS5SZWNvbW1lbmRhdGlvbi5Qcmlvcml0eVIIcHJpb3JpdHkSTAoH
Y29udGVudBgHIAEoCzIyLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5SZWNvbW1lbmRh
dGlvbkNvbnRlbnRSB2NvbnRlbnQSUwoKc3RhdGVfaW5mbxgKIAEoCzI0Lmdvb2dsZS5jbG91
ZC5yZWNvbW1lbmRlci52MS5SZWNvbW1lbmRhdGlvblN0YXRlSW5mb1IJc3RhdGVJbmZvEhIK
BGV0YWcYCyABKAlSBGV0YWcSbQoTYXNzb2NpYXRlZF9pbnNpZ2h0cxgOIAMoCzI8Lmdvb2ds
ZS5jbG91ZC5yZWNvbW1lbmRlci52MS5SZWNvbW1lbmRhdGlvbi5JbnNpZ2h0UmVmZXJlbmNl
UhJhc3NvY2lhdGVkSW5zaWdodHMSIAoMeG9yX2dyb3VwX2lkGBIgASgJUgp4b3JHcm91cElk
EikKEHRhcmdldF9yZXNvdXJjZXMYEyADKAlSD3RhcmdldFJlc291cmNlcxosChBJbnNpZ2h0
UmVmZXJlbmNlEhgKB2luc2lnaHQYASABKAlSB2luc2lnaHQiRAoIUHJpb3JpdHkSGAoUUFJJ
T1JJVFlfVU5TUEVDSUZJRUQQABIGCgJQNBABEgYKAlAzEAISBgoCUDIQAxIGCgJQMRAEOtoD
6kHWAwopcmVjb21tZW5kZXIuZ29vZ2xlYXBpcy5jb20vUmVjb21tZW5kYXRpb24SY3Byb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZWNvbW1lbmRlcnMve3JlY29t
bWVuZGVyfS9yZWNvbW1lbmRhdGlvbnMve3JlY29tbWVuZGF0aW9ufRJyYmlsbGluZ0FjY291
bnRzL3tiaWxsaW5nX2FjY291bnR9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVy
cy97cmVjb21tZW5kZXJ9L3JlY29tbWVuZGF0aW9ucy97cmVjb21tZW5kYXRpb259EmFmb2xk
ZXJzL3tmb2xkZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVycy97cmVjb21t
ZW5kZXJ9L3JlY29tbWVuZGF0aW9ucy97cmVjb21tZW5kYXRpb259Em1vcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVycy97cmVj
b21tZW5kZXJ9L3JlY29tbWVuZGF0aW9ucy97cmVjb21tZW5kYXRpb259IqQBChVSZWNvbW1l
bmRhdGlvbkNvbnRlbnQSVgoQb3BlcmF0aW9uX2dyb3VwcxgCIAMoCzIrLmdvb2dsZS5jbG91
ZC5yZWNvbW1lbmRlci52MS5PcGVyYXRpb25Hcm91cFIPb3BlcmF0aW9uR3JvdXBzEjMKCG92
ZXJ2aWV3GAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIIb3ZlcnZpZXciWAoOT3Bl
cmF0aW9uR3JvdXASRgoKb3BlcmF0aW9ucxgBIAMoCzImLmdvb2dsZS5jbG91ZC5yZWNvbW1l
bmRlci52MS5PcGVyYXRpb25SCm9wZXJhdGlvbnMi5gUKCU9wZXJhdGlvbhIWCgZhY3Rpb24Y
ASABKAlSBmFjdGlvbhIjCg1yZXNvdXJjZV90eXBlGAIgASgJUgxyZXNvdXJjZVR5cGUSGgoI
cmVzb3VyY2UYAyABKAlSCHJlc291cmNlEhIKBHBhdGgYBCABKAlSBHBhdGgSJwoPc291cmNl
X3Jlc291cmNlGAUgASgJUg5zb3VyY2VSZXNvdXJjZRIfCgtzb3VyY2VfcGF0aBgGIAEoCVIK
c291cmNlUGF0aBIuCgV2YWx1ZRgHIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZUgAUgV2
YWx1ZRJQCg12YWx1ZV9tYXRjaGVyGAogASgLMikuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVy
LnYxLlZhbHVlTWF0Y2hlckgAUgx2YWx1ZU1hdGNoZXISWgoMcGF0aF9maWx0ZXJzGAggAygL
MjcuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLk9wZXJhdGlvbi5QYXRoRmlsdGVyc0Vu
dHJ5UgtwYXRoRmlsdGVycxJtChNwYXRoX3ZhbHVlX21hdGNoZXJzGAsgAygLMj0uZ29vZ2xl
LmNsb3VkLnJlY29tbWVuZGVyLnYxLk9wZXJhdGlvbi5QYXRoVmFsdWVNYXRjaGVyc0VudHJ5
UhFwYXRoVmFsdWVNYXRjaGVycxpWChBQYXRoRmlsdGVyc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToCOAEa
bwoWUGF0aFZhbHVlTWF0Y2hlcnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI/CgV2YWx1ZRgC
IAEoCzIpLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5WYWx1ZU1hdGNoZXJSBXZhbHVl
OgI4AUIMCgpwYXRoX3ZhbHVlIkoKDFZhbHVlTWF0Y2hlchIpCg9tYXRjaGVzX3BhdHRlcm4Y
ASABKAlIAFIObWF0Y2hlc1BhdHRlcm5CDwoNbWF0Y2hfdmFyaWFudCK4AQoOQ29zdFByb2pl
Y3Rpb24SJgoEY29zdBgBIAEoCzISLmdvb2dsZS50eXBlLk1vbmV5UgRjb3N0EjUKCGR1cmF0
aW9uGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbhJHChZjb3N0
X2luX2xvY2FsX2N1cnJlbmN5GAMgASgLMhIuZ29vZ2xlLnR5cGUuTW9uZXlSE2Nvc3RJbkxv
Y2FsQ3VycmVuY3kiRwoSU2VjdXJpdHlQcm9qZWN0aW9uEjEKB2RldGFpbHMYAiABKAsyFy5n
b29nbGUucHJvdG9idWYuU3RydWN0UgdkZXRhaWxzImsKGFN1c3RhaW5hYmlsaXR5UHJvamVj
dGlvbhIYCghrZ19jX28yZRgBIAEoAVIGa2dDTzJlEjUKCGR1cmF0aW9uGAIgASgLMhkuZ29v
Z2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbiL8AQoVUmVsaWFiaWxpdHlQcm9qZWN0
aW9uElEKBXJpc2tzGAEgAygOMjsuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLlJlbGlh
YmlsaXR5UHJvamVjdGlvbi5SaXNrVHlwZVIFcmlza3MSMQoHZGV0YWlscxgCIAEoCzIXLmdv
b2dsZS5wcm90b2J1Zi5TdHJ1Y3RSB2RldGFpbHMiXQoIUmlza1R5cGUSGQoVUklTS19UWVBF
X1VOU1BFQ0lGSUVEEAASFgoSU0VSVklDRV9ESVNSVVBUSU9OEAESDQoJREFUQV9MT1NTEAIS
DwoLQUNDRVNTX0RFTlkQAyKhBQoGSW1wYWN0EkgKCGNhdGVnb3J5GAEgASgOMiwuZ29vZ2xl
LmNsb3VkLnJlY29tbWVuZGVyLnYxLkltcGFjdC5DYXRlZ29yeVIIY2F0ZWdvcnkSVgoPY29z
dF9wcm9qZWN0aW9uGGQgASgLMisuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLkNvc3RQ
cm9qZWN0aW9uSABSDmNvc3RQcm9qZWN0aW9uEmIKE3NlY3VyaXR5X3Byb2plY3Rpb24YZSAB
KAsyLy5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjEuU2VjdXJpdHlQcm9qZWN0aW9uSABS
EnNlY3VyaXR5UHJvamVjdGlvbhJ0ChlzdXN0YWluYWJpbGl0eV9wcm9qZWN0aW9uGGYgASgL
MjUuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLlN1c3RhaW5hYmlsaXR5UHJvamVjdGlv
bkgAUhhzdXN0YWluYWJpbGl0eVByb2plY3Rpb24SawoWcmVsaWFiaWxpdHlfcHJvamVjdGlv
bhhnIAEoCzIyLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5SZWxpYWJpbGl0eVByb2pl
Y3Rpb25IAFIVcmVsaWFiaWxpdHlQcm9qZWN0aW9uEhgKB3NlcnZpY2UYAyABKAlSB3NlcnZp
Y2UihQEKCENhdGVnb3J5EhgKFENBVEVHT1JZX1VOU1BFQ0lGSUVEEAASCAoEQ09TVBABEgwK
CFNFQ1VSSVRZEAISDwoLUEVSRk9STUFOQ0UQAxIRCg1NQU5BR0VBQklMSVRZEAQSEgoOU1VT
VEFJTkFCSUxJVFkQBRIPCgtSRUxJQUJJTElUWRAGQgwKCnByb2plY3Rpb24igAMKF1JlY29t
bWVuZGF0aW9uU3RhdGVJbmZvElAKBXN0YXRlGAEgASgOMjouZ29vZ2xlLmNsb3VkLnJlY29t
bWVuZGVyLnYxLlJlY29tbWVuZGF0aW9uU3RhdGVJbmZvLlN0YXRlUgVzdGF0ZRJuCg5zdGF0
ZV9tZXRhZGF0YRgCIAMoCzJHLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5SZWNvbW1l
bmRhdGlvblN0YXRlSW5mby5TdGF0ZU1ldGFkYXRhRW50cnlSDXN0YXRlTWV0YWRhdGEaQAoS
U3RhdGVNZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2
YWx1ZToCOAEiYQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZBQ1RJVkUQARIL
CgdDTEFJTUVEEAYSDQoJU1VDQ0VFREVEEAMSCgoGRkFJTEVEEAQSDQoJRElTTUlTU0VEEAVC
3gMKH2NvbS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFQAVpBY2xvdWQuZ29vZ2xlLmNv
bS9nby9yZWNvbW1lbmRlci9hcGl2MS9yZWNvbW1lbmRlcnBiO3JlY29tbWVuZGVycGKiAgRD
UkVDqgIbR29vZ2xlLkNsb3VkLlJlY29tbWVuZGVyLlYx6kHPAgomcmVjb21tZW5kZXIuZ29v
Z2xlYXBpcy5jb20vUmVjb21tZW5kZXISQnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9yZWNvbW1lbmRlcnMve3JlY29tbWVuZGVyfRJRYmlsbGluZ0FjY291bnRz
L3tiaWxsaW5nX2FjY291bnR9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVycy97
cmVjb21tZW5kZXJ9EkBmb2xkZXJzL3tmb2xkZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
Y29tbWVuZGVycy97cmVjb21tZW5kZXJ9Ekxvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259
L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVycy97cmVjb21tZW5kZXJ9SsVwCgcS
BQ4AkQMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAoCgkKAgMDEgMVACYKCQoCAwQSAxYAKQoJ
CgIDBRIDFwAhCggKAQgSAxkAOAoJCgIIJRIDGQA4CggKAQgSAxoAWAoJCgIICxIDGgBYCggK
AQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAOAoJCgIIARIDHAA4CggKAQgSAx0AIgoJCgII
JBIDHQAiCgkKAQgSBB4AJAIKDAoECJ0IABIEHgAkAgqaAQoCBAASBSgAgQEBGowBIEEgcmVj
b21tZW5kYXRpb24gYWxvbmcgd2l0aCBhIHN1Z2dlc3RlZCBhY3Rpb24uIEUuZy4sIGEgcmln
aHRzaXppbmcKIHJlY29tbWVuZGF0aW9uIGZvciBhbiB1bmRlcnV0aWxpemVkIFZNLCBJQU0g
cm9sZSByZWNvbW1lbmRhdGlvbnMsIGV0YwoKCgoDBAABEgMoCBYKCwoDBAAHEgQpAi8ECg0K
BQQAB50IEgQpAi8ECi8KBAQABAASBDICQQMaISBSZWNvbW1lbmRhdGlvbiBwcmlvcml0eSBs
ZXZlbHMuCgoMCgUEAAQAARIDMgcPCjkKBgQABAACABIDNAQdGiogUmVjb21tZW5kYXRpb24g
aGFzIHVuc3BlY2lmaWVkIHByaW9yaXR5LgoKDgoHBAAEAAIAARIDNAQYCg4KBwQABAACAAIS
AzQbHApCCgYEAAQAAgESAzcECxozIFJlY29tbWVuZGF0aW9uIGhhcyBQNCBwcmlvcml0eSAo
bG93ZXN0IHByaW9yaXR5KS4KCg4KBwQABAACAQESAzcEBgoOCgcEAAQAAgECEgM3CQoKSQoG
BAAEAAICEgM6BAsaOiBSZWNvbW1lbmRhdGlvbiBoYXMgUDMgcHJpb3JpdHkgKHNlY29uZCBs
b3dlc3QgcHJpb3JpdHkpLgoKDgoHBAAEAAICARIDOgQGCg4KBwQABAACAgISAzoJCgpKCgYE
AAQAAgMSAz0ECxo7IFJlY29tbWVuZGF0aW9uIGhhcyBQMiBwcmlvcml0eSAoc2Vjb25kIGhp
Z2hlc3QgcHJpb3JpdHkpLgoKDgoHBAAEAAIDARIDPQQGCg4KBwQABAACAwISAz0JCgpDCgYE
AAQAAgQSA0AECxo0IFJlY29tbWVuZGF0aW9uIGhhcyBQMSBwcmlvcml0eSAoaGlnaGVzdCBw
cmlvcml0eSkuCgoOCgcEAAQAAgQBEgNABAYKDgoHBAAEAAIEAhIDQAkKCjMKBAQAAwASBEQC
SAMaJSBSZWZlcmVuY2UgdG8gYW4gYXNzb2NpYXRlZCBpbnNpZ2h0LgoKDAoFBAADAAESA0QK
GgqSAQoGBAADAAIAEgNHBBcaggEgSW5zaWdodCByZXNvdXJjZSBuYW1lLCBlLmcuCiBwcm9q
ZWN0cy9bUFJPSkVDVF9OVU1CRVJdL2xvY2F0aW9ucy9bTE9DQVRJT05dL2luc2lnaHRUeXBl
cy9bSU5TSUdIVF9UWVBFX0lEXS9pbnNpZ2h0cy9bSU5TSUdIVF9JRF0KCg4KBwQAAwACAAUS
A0cECgoOCgcEAAMAAgABEgNHCxIKDgoHBAADAAIAAxIDRxUWCjIKBAQAAgASA0sCPRolIElk
ZW50aWZpZXIuIE5hbWUgb2YgcmVjb21tZW5kYXRpb24uCgoMCgUEAAIABRIDSwIICgwKBQQA
AgABEgNLCQ0KDAoFBAACAAMSA0sQEQoMCgUEAAIACBIDSxI8Cg8KCAQAAgAInAgAEgNLEzsK
YgoEBAACARIDTwIZGlUgRnJlZS1mb3JtIGh1bWFuIHJlYWRhYmxlIHN1bW1hcnkgaW4gRW5n
bGlzaC4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDUwMAogY2hhcmFjdGVycy4KCgwKBQQAAgEF
EgNPAggKDAoFBAACAQESA08JFAoMCgUEAAIBAxIDTxcYCucDCgQEAAICEgNaAiIa2QMgQ29u
dGFpbnMgYW4gaWRlbnRpZmllciBmb3IgYSBzdWJ0eXBlIG9mIHJlY29tbWVuZGF0aW9ucyBw
cm9kdWNlZCBmb3IgdGhlCiBzYW1lIHJlY29tbWVuZGVyLiBTdWJ0eXBlIGlzIGEgZnVuY3Rp
b24gb2YgY29udGVudCBhbmQgaW1wYWN0LCBtZWFuaW5nIGEKIG5ldyBzdWJ0eXBlIG1pZ2h0
IGJlIGFkZGVkIHdoZW4gc2lnbmlmaWNhbnQgY2hhbmdlcyB0byBgY29udGVudGAgb3IKIGBw
cmltYXJ5X2ltcGFjdC5jYXRlZ29yeWAgYXJlIGludHJvZHVjZWQuIFNlZSB0aGUgUmVjb21t
ZW5kZXJzIHNlY3Rpb24KIHRvIHNlZSBhIGxpc3Qgb2Ygc3VidHlwZXMgZm9yIGEgZ2l2ZW4g
UmVjb21tZW5kZXIuCgogRXhhbXBsZXM6CiAgIEZvciByZWNvbW1lbmRlciA9ICJnb29nbGUu
aWFtLnBvbGljeS5SZWNvbW1lbmRlciIsCiAgIHJlY29tbWVuZGVyX3N1YnR5cGUgY2FuIGJl
IG9uZSBvZiAiUkVNT1ZFX1JPTEUiLyJSRVBMQUNFX1JPTEUiCgoMCgUEAAICBRIDWgIICgwK
BQQAAgIBEgNaCRwKDAoFBAACAgMSA1ofIQptCgQEAAIDEgNeAjIaYCBMYXN0IHRpbWUgdGhp
cyByZWNvbW1lbmRhdGlvbiB3YXMgcmVmcmVzaGVkIGJ5IHRoZSBzeXN0ZW0gdGhhdCBjcmVh
dGVkIGl0CiBpbiB0aGUgZmlyc3QgcGxhY2UuCgoMCgUEAAIDBhIDXgIbCgwKBQQAAgMBEgNe
HC0KDAoFBAACAwMSA14wMQpvCgQEAAIEEgNiAhwaYiBUaGUgcHJpbWFyeSBpbXBhY3QgdGhh
dCB0aGlzIHJlY29tbWVuZGF0aW9uIGNhbiBoYXZlIHdoaWxlIHRyeWluZyB0bwogb3B0aW1p
emUgZm9yIG9uZSBjYXRlZ29yeS4KCgwKBQQAAgQGEgNiAggKDAoFBAACBAESA2IJFwoMCgUE
AAIEAxIDYhobCqoBCgQEAAIFEgNnAiganAEgT3B0aW9uYWwgc2V0IG9mIGFkZGl0aW9uYWwg
aW1wYWN0IHRoYXQgdGhpcyByZWNvbW1lbmRhdGlvbiBtYXkgaGF2ZSB3aGVuCiB0cnlpbmcg
dG8gb3B0aW1pemUgZm9yIHRoZSBwcmltYXJ5IGNhdGVnb3J5LiBUaGVzZSBtYXkgYmUgcG9z
aXRpdmUKIG9yIG5lZ2F0aXZlLgoKDAoFBAACBQQSA2cCCgoMCgUEAAIFBhIDZwsRCgwKBQQA
AgUBEgNnEiMKDAoFBAACBQMSA2cmJwopCgQEAAIGEgNqAhkaHCBSZWNvbW1lbmRhdGlvbidz
IHByaW9yaXR5LgoKDAoFBAACBgYSA2oCCgoMCgUEAAIGARIDagsTCgwKBQQAAgYDEgNqFhgK
WQoEBAACBxIDbQIkGkwgQ29udGVudCBvZiB0aGUgcmVjb21tZW5kYXRpb24gZGVzY3JpYmlu
ZyByZWNvbW1lbmRlZCBjaGFuZ2VzIHRvIHJlc291cmNlcy4KCgwKBQQAAgcGEgNtAhcKDAoF
BAACBwESA20YHwoMCgUEAAIHAxIDbSIjCkIKBAQAAggSA3ACKho1IEluZm9ybWF0aW9uIGZv
ciBzdGF0ZS4gQ29udGFpbnMgc3RhdGUgYW5kIG1ldGFkYXRhLgoKDAoFBAACCAYSA3ACGQoM
CgUEAAIIARIDcBokCgwKBQQAAggDEgNwJykKZAoEBAACCRIDdAITGlcgRmluZ2VycHJpbnQg
b2YgdGhlIFJlY29tbWVuZGF0aW9uLiBQcm92aWRlcyBvcHRpbWlzdGljIGxvY2tpbmcgd2hl
bgogdXBkYXRpbmcgc3RhdGVzLgoKDAoFBAACCQUSA3QCCAoMCgUEAAIJARIDdAkNCgwKBQQA
AgkDEgN0EBIKOAoEBAACChIDdwI1GisgSW5zaWdodHMgdGhhdCBsZWQgdG8gdGhpcyByZWNv
bW1lbmRhdGlvbi4KCgwKBQQAAgoEEgN3AgoKDAoFBAACCgYSA3cLGwoMCgUEAAIKARIDdxwv
CgwKBQQAAgoDEgN3MjQKggIKBAQAAgsSA30CGxr0ASBDb3JyZXNwb25kcyB0byBhIG11dHVh
bGx5IGV4Y2x1c2l2ZSBncm91cCBJRCB3aXRoaW4gYSByZWNvbW1lbmRlci4KIEEgbm9uLWVt
cHR5IElEIGluZGljYXRlcyB0aGF0IHRoZSByZWNvbW1lbmRhdGlvbiBiZWxvbmdzIHRvIGEg
bXV0dWFsbHkKIGV4Y2x1c2l2ZSBncm91cC4gVGhpcyBtZWFucyB0aGF0IG9ubHkgb25lIHJl
Y29tbWVuZGF0aW9uIHdpdGhpbiB0aGUgZ3JvdXAKIGlzIHN1Z2dlc3RlZCB0byBiZSBhcHBs
aWVkLgoKDAoFBAACCwUSA30CCAoMCgUEAAILARIDfQkVCgwKBQQAAgsDEgN9GBoKVQoEBAAC
DBIEgAECKBpHIEZ1bGx5IHF1YWxpZmllZCByZXNvdXJjZSBuYW1lcyB0aGF0IHRoaXMgcmVj
b21tZW5kYXRpb24gaXMgdGFyZ2V0aW5nLgoKDQoFBAACDAQSBIABAgoKDQoFBAACDAUSBIAB
CxEKDQoFBAACDAESBIABEiIKDQoFBAACDAMSBIABJScKTwoCBAESBoQBAIwBARpBIENvbnRh
aW5zIHdoYXQgcmVzb3VyY2VzIGFyZSBjaGFuZ2luZyBhbmQgaG93IHRoZXkgYXJlIGNoYW5n
aW5nLgoKCwoDBAEBEgSEAQgdCrgBCgQEAQIAEgSIAQIvGqkBIE9wZXJhdGlvbnMgdG8gb25l
IG9yIG1vcmUgR29vZ2xlIENsb3VkIHJlc291cmNlcyBncm91cGVkIGluIHN1Y2ggYSB3YXkK
IHRoYXQsIGFsbCBvcGVyYXRpb25zIHdpdGhpbiBvbmUgZ3JvdXAgYXJlIGV4cGVjdGVkIHRv
IGJlIHBlcmZvcm1lZAogYXRvbWljYWxseSBhbmQgaW4gYW4gb3JkZXIuCgoNCgUEAQIABBIE
iAECCgoNCgUEAQIABhIEiAELGQoNCgUEAQIAARIEiAEaKgoNCgUEAQIAAxIEiAEtLgpICgQE
AQIBEgSLAQImGjogQ29uZGVuc2VkIG92ZXJ2aWV3IGluZm9ybWF0aW9uIGFib3V0IHRoZSBy
ZWNvbW1lbmRhdGlvbi4KCg0KBQQBAgEGEgSLAQIYCg0KBQQBAgEBEgSLARkhCg0KBQQBAgED
EgSLASQlCkkKAgQCEgaPAQCTAQEaOyBHcm91cCBvZiBvcGVyYXRpb25zIHRoYXQgbmVlZCB0
byBiZSBwZXJmb3JtZWQgYXRvbWljYWxseS4KCgsKAwQCARIEjwEIFgqnAQoEBAICABIEkgEC
JBqYASBMaXN0IG9mIG9wZXJhdGlvbnMgYWNyb3NzIG9uZSBvciBtb3JlIHJlc291cmNlcyB0
aGF0IGJlbG9uZyB0byB0aGlzIGdyb3VwLgogTG9vc2VseSBiYXNlZCBvbiBSRkM2OTAyIGFu
ZCBzaG91bGQgYmUgcGVyZm9ybWVkIGluIHRoZSBvcmRlciB0aGV5IGFwcGVhci4KCg0KBQQC
AgAEEgSSAQIKCg0KBQQCAgAGEgSSAQsUCg0KBQQCAgABEgSSARUfCg0KBQQCAgADEgSSASIj
Cs4DCgIEAxIGngEA7gEBGr8DIENvbnRhaW5zIGFuIG9wZXJhdGlvbiBmb3IgYSByZXNvdXJj
ZSBsb29zZWx5IGJhc2VkIG9uIHRoZSBKU09OLVBBVENIIGZvcm1hdAogd2l0aCBzdXBwb3J0
IGZvcjoKCiAqIEN1c3RvbSBmaWx0ZXJzIGZvciBkZXNjcmliaW5nIHBhcnRpYWwgYXJyYXkg
cGF0Y2guCiAqIEV4dGVuZGVkIHBhdGggdmFsdWVzIGZvciBkZXNjcmliaW5nIG5lc3RlZCBh
cnJheXMuCiAqIEN1c3RvbSBmaWVsZHMgZm9yIGRlc2NyaWJpbmcgdGhlIHJlc291cmNlIGZv
ciB3aGljaCB0aGUgb3BlcmF0aW9uIGlzIGJlaW5nCiAgIGRlc2NyaWJlZC4KICogQWxsb3dz
IGV4dGVuc2lvbiB0byBjdXN0b20gb3BlcmF0aW9ucyBub3QgbmF0aXZlbHkgc3VwcG9ydGVk
IGJ5IFJGQzY5MDIuCiBTZWUgaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL3JmYzY5MDIg
Zm9yIGRldGFpbHMgb24gdGhlIG9yaWdpbmFsIFJGQy4KCgsKAwQDARIEngEIEQq5AQoEBAMC
ABIEogECFBqqASBUeXBlIG9mIHRoaXMgb3BlcmF0aW9uLiBDb250YWlucyBvbmUgb2YgJ2Fk
ZCcsICdyZW1vdmUnLCAncmVwbGFjZScsICdtb3ZlJywKICdjb3B5JywgJ3Rlc3QnIGFuZCBj
dXN0b20gb3BlcmF0aW9ucy4gVGhpcyBmaWVsZCBpcyBjYXNlLWluc2Vuc2l0aXZlIGFuZAog
YWx3YXlzIHBvcHVsYXRlZC4KCg0KBQQDAgAFEgSiAQIICg0KBQQDAgABEgSiAQkPCg0KBQQD
AgADEgSiARITCrQBCgQEAwIBEgSnAQIbGqUBIFR5cGUgb2YgR0NQIHJlc291cmNlIGJlaW5n
IG1vZGlmaWVkL3Rlc3RlZC4gVGhpcyBmaWVsZCBpcyBhbHdheXMgcG9wdWxhdGVkLgogRXhh
bXBsZTogY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdCwKIGNv
bXB1dGUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2UKCg0KBQQDAgEFEgSnAQIICg0KBQQDAgEB
EgSnAQkWCg0KBQQDAgEDEgSnARkaCpUBCgQEAwICEgSrAQIWGoYBIENvbnRhaW5zIHRoZSBm
dWxseSBxdWFsaWZpZWQgcmVzb3VyY2UgbmFtZS4gVGhpcyBmaWVsZCBpcyBhbHdheXMgcG9w
dWxhdGVkLgogZXg6IC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vcHJv
amVjdHMvZm9vLgoKDQoFBAMCAgUSBKsBAggKDQoFBAMCAgESBKsBCREKDQoFBAMCAgMSBKsB
FBUKoQEKBAQDAgMSBK8BAhIakgEgUGF0aCB0byB0aGUgdGFyZ2V0IGZpZWxkIGJlaW5nIG9w
ZXJhdGVkIG9uLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGF0IHRoZQogcmVzb3VyY2UgbGV2ZWws
IHRoZW4gcGF0aCBzaG91bGQgYmUgIi8iLiBUaGlzIGZpZWxkIGlzIGFsd2F5cyBwb3B1bGF0
ZWQuCgoNCgUEAwIDBRIErwECCAoNCgUEAwIDARIErwEJDQoNCgUEAwIDAxIErwEQEQrAAgoE
BAMCBBIEtgECHRqxAiBDYW4gYmUgc2V0IHdpdGggYWN0aW9uICdjb3B5JyB0byBjb3B5IHJl
c291cmNlIGNvbmZpZ3VyYXRpb24gYWNyb3NzCiBkaWZmZXJlbnQgcmVzb3VyY2VzIG9mIHRo
ZSBzYW1lIHR5cGUuIEV4YW1wbGU6IEEgcmVzb3VyY2UgY2xvbmUgY2FuIGJlCiBkb25lIHZp
YSBhY3Rpb24gPSAnY29weScsIHBhdGggPSAiLyIsIGZyb20gPSAiLyIsCiBzb3VyY2VfcmVz
b3VyY2UgPSA8c291cmNlPiBhbmQgcmVzb3VyY2VfbmFtZSA9IDx0YXJnZXQ+LgogVGhpcyBm
aWVsZCBpcyBlbXB0eSBmb3IgYWxsIG90aGVyIHZhbHVlcyBvZiBgYWN0aW9uYC4KCg0KBQQD
AgQFEgS2AQIICg0KBQQDAgQBEgS2AQkYCg0KBQQDAgQDEgS2ARscCqkBCgQEAwIFEgS6AQIZ
GpoBIENhbiBiZSBzZXQgd2l0aCBhY3Rpb24gJ2NvcHknIG9yICdtb3ZlJyB0byBpbmRpY2F0
ZSB0aGUgc291cmNlIGZpZWxkIHdpdGhpbgogcmVzb3VyY2Ugb3Igc291cmNlX3Jlc291cmNl
LCBpZ25vcmVkIGlmIHByb3ZpZGVkIGZvciBvdGhlciBvcGVyYXRpb24gdHlwZXMuCgoNCgUE
AwIFBRIEugECCAoNCgUEAwIFARIEugEJFAoNCgUEAwIFAxIEugEXGAp4CgQEAwgAEga+AQLH
AQMaaCBPbmUgb2YgdGhlIGZpZWxkcyBpbiB0aGUgZm9sbG93aW5nIGJsb2NrIHdpbGwgYmUg
c2V0IGFuZCBpbnRlbmQgdG8KIGRlc2NyaWJlIGEgdmFsdWUgZm9yICdwYXRoJyBmaWVsZC4K
Cg0KBQQDCAABEgS+AQgSCtgBCgQEAwIGEgTCAQQkGskBIFZhbHVlIGZvciB0aGUgYHBhdGhg
IGZpZWxkLiBXaWxsIGJlIHNldCBmb3IgYWN0aW9uczonYWRkJy8ncmVwbGFjZScuCiBNYXli
ZSBzZXQgZm9yIGFjdGlvbjogJ3Rlc3QnLiBFaXRoZXIgdGhpcyBvciBgdmFsdWVfbWF0Y2hl
cmAgd2lsbCBiZSBzZXQKIGZvciAndGVzdCcgb3BlcmF0aW9uLiBBbiBleGFjdCBtYXRjaCBt
dXN0IGJlIHBlcmZvcm1lZC4KCg0KBQQDAgYGEgTCAQQZCg0KBQQDAgYBEgTCARofCg0KBQQD
AgYDEgTCASIjCpwBCgQEAwIHEgTGAQQkGo0BIENhbiBiZSBzZXQgZm9yIGFjdGlvbiAndGVz
dCcgZm9yIGFkdmFuY2VkIG1hdGNoaW5nIGZvciB0aGUgdmFsdWUgb2YKICdwYXRoJyBmaWVs
ZC4gRWl0aGVyIHRoaXMgb3IgYHZhbHVlYCB3aWxsIGJlIHNldCBmb3IgJ3Rlc3QnIG9wZXJh
dGlvbi4KCg0KBQQDAgcGEgTGAQQQCg0KBQQDAgcBEgTGAREeCg0KBQQDAgcDEgTGASEjCsoF
CgQEAwIIEgTmAQI2GrsFIFNldCBvZiBmaWx0ZXJzIHRvIGFwcGx5IGlmIGBwYXRoYCByZWZl
cnMgdG8gYXJyYXkgZWxlbWVudHMgb3IgbmVzdGVkIGFycmF5CiBlbGVtZW50cyBpbiBvcmRl
ciB0byBuYXJyb3cgZG93biB0byBhIHNpbmdsZSB1bmlxdWUgZWxlbWVudCB0aGF0IGlzIGJl
aW5nCiB0ZXN0ZWQvbW9kaWZpZWQuCiBUaGlzIGlzIGludGVuZGVkIHRvIGJlIGFuIGV4YWN0
IG1hdGNoIHBlciBmaWx0ZXIuIFRvIHBlcmZvcm0gYWR2YW5jZWQKIG1hdGNoaW5nLCB1c2Ug
cGF0aF92YWx1ZV9tYXRjaGVycy4KCiAqIEV4YW1wbGU6CiBgYGAKIHsKICAgIi92ZXJzaW9u
cy8qL25hbWUiIDogIml0LTEyMyIKICAgIi92ZXJzaW9ucy8qL3RhcmdldFNpemUvcGVyY2Vu
dCI6IDIwCiB9CiBgYGAKICogRXhhbXBsZToKIGBgYAogewogICAiL2JpbmRpbmdzLyovcm9s
ZSI6ICJyb2xlcy9vd25lciIKICAgIi9iaW5kaW5ncy8qL2NvbmRpdGlvbiIgOiBudWxsCiB9
CiBgYGAKICogRXhhbXBsZToKIGBgYAogewogICAiL2JpbmRpbmdzLyovcm9sZSI6ICJyb2xl
cy9vd25lciIKICAgIi9iaW5kaW5ncy8qL21lbWJlcnMvKiIgOiBbInhAZXhhbXBsZS5jb20i
LCAieUBleGFtcGxlLmNvbSJdCiB9CiBgYGAKIFdoZW4gYm90aCBwYXRoX2ZpbHRlcnMgYW5k
IHBhdGhfdmFsdWVfbWF0Y2hlcnMgYXJlIHNldCwgYW4gaW1wbGljaXQgQU5ECiBtdXN0IGJl
IHBlcmZvcm1lZC4KCg0KBQQDAggGEgTmAQIkCg0KBQQDAggBEgTmASUxCg0KBQQDAggDEgTm
ATQ1Cr4CCgQEAwIJEgTtAQI1Gq8CIFNpbWlsYXIgdG8gcGF0aF9maWx0ZXJzLCB0aGlzIGNv
bnRhaW5zIHNldCBvZiBmaWx0ZXJzIHRvIGFwcGx5IGlmIGBwYXRoYAogZmllbGQgcmVmZXJz
IHRvIGFycmF5IGVsZW1lbnRzLiBUaGlzIGlzIG1lYW50IHRvIHN1cHBvcnQgdmFsdWUgbWF0
Y2hpbmcKIGJleW9uZCBleGFjdCBtYXRjaC4gVG8gcGVyZm9ybSBleGFjdCBtYXRjaCwgdXNl
IHBhdGhfZmlsdGVycy4KIFdoZW4gYm90aCBwYXRoX2ZpbHRlcnMgYW5kIHBhdGhfdmFsdWVf
bWF0Y2hlcnMgYXJlIHNldCwgYW4gaW1wbGljaXQgQU5ECiBtdXN0IGJlIHBlcmZvcm1lZC4K
Cg0KBQQDAgkGEgTtAQIbCg0KBQQDAgkBEgTtARwvCg0KBQQDAgkDEgTtATI0ClYKAgQEEgbx
AQD5AQEaSCBDb250YWlucyB2YXJpb3VzIG1hdGNoaW5nIG9wdGlvbnMgZm9yIHZhbHVlcyBm
b3IgYSBHQ1AgcmVzb3VyY2UgZmllbGQuCgoLCgMEBAESBPEBCBQKNQoEBAQIABIG8wEC+AED
GiUgVG8gYmUgdXNlZCBmb3IgZnVsbCByZWdleCBtYXRjaGluZy4KCg0KBQQECAABEgTzAQgV
CrsBCgQEBAIAEgT3AQQfGqwBIFRvIGJlIHVzZWQgZm9yIGZ1bGwgcmVnZXggbWF0Y2hpbmcu
IFRoZSByZWd1bGFyIGV4cHJlc3Npb24gaXMgdXNpbmcgdGhlCiBHb29nbGUgUkUyIHN5bnRh
eCAoaHR0cHM6Ly9naXRodWIuY29tL2dvb2dsZS9yZTIvd2lraS9TeW50YXgpLCBzbyB0byBi
ZQogdXNlZCB3aXRoIFJFMjo6RnVsbE1hdGNoCgoNCgUEBAIABRIE9wEECgoNCgUEBAIAARIE
9wELGgoNCgUEBAIAAxIE9wEdHgpaCgIEBRIG/AEAigIBGkwgQ29udGFpbnMgbWV0YWRhdGEg
YWJvdXQgaG93IG11Y2ggbW9uZXkgYSByZWNvbW1lbmRhdGlvbiBjYW4gc2F2ZSBvciBpbmN1
ci4KCgsKAwQFARIE/AEIFgrTAgoEBAUCABIEgwICHRrEAiBBbiBhcHByb3hpbWF0ZSBwcm9q
ZWN0aW9uIG9uIGFtb3VudCBzYXZlZCBvciBhbW91bnQgaW5jdXJyZWQuIE5lZ2F0aXZlIGNv
c3QKIHVuaXRzIGluZGljYXRlIGNvc3Qgc2F2aW5ncyBhbmQgcG9zaXRpdmUgY29zdCB1bml0
cyBpbmRpY2F0ZSBpbmNyZWFzZS4KIFNlZSBnb29nbGUudHlwZS5Nb25leSBkb2N1bWVudGF0
aW9uIGZvciBwb3NpdGl2ZS9uZWdhdGl2ZSB1bml0cy4KCiBBIHVzZXIncyBwZXJtaXNzaW9u
cyBtYXkgYWZmZWN0IHdoZXRoZXIgdGhlIGNvc3QgaXMgY29tcHV0ZWQgdXNpbmcgbGlzdAog
cHJpY2VzIG9yIGN1c3RvbSBjb250cmFjdCBwcmljZXMuCgoNCgUEBQIABhIEgwICEwoNCgUE
BQIAARIEgwIUGAoNCgUEBQIAAxIEgwIbHAo1CgQEBQIBEgSGAgIoGicgRHVyYXRpb24gZm9y
IHdoaWNoIHRoaXMgY29zdCBhcHBsaWVzLgoKDQoFBAUCAQYSBIYCAhoKDQoFBAUCAQESBIYC
GyMKDQoFBAUCAQMSBIYCJicKVQoEBAUCAhIEiQICLxpHIFRoZSBhcHByb3hpbWF0ZSBjb3N0
IHNhdmluZ3MgaW4gdGhlIGJpbGxpbmcgYWNjb3VudCdzIGxvY2FsIGN1cnJlbmN5LgoKDQoF
BAUCAgYSBIkCAhMKDQoFBAUCAgESBIkCFCoKDQoFBAUCAgMSBIkCLS4KSwoCBAYSBo0CAJAC
ARo9IENvbnRhaW5zIHZhcmlvdXMgd2F5cyBvZiBkZXNjcmliaW5nIHRoZSBpbXBhY3Qgb24g
U2VjdXJpdHkuCgoLCgMEBgESBI0CCBoKVwoEBAYCABIEjwICJRpJIEFkZGl0aW9uYWwgc2Vj
dXJpdHkgaW1wYWN0IGRldGFpbHMgdGhhdCBpcyBwcm92aWRlZCBieSB0aGUgcmVjb21tZW5k
ZXIuCgoNCgUEBgIABhIEjwICGAoNCgUEBgIAARIEjwIZIAoNCgUEBgIAAxIEjwIjJApkCgIE
BxIGlAIAmwIBGlYgQ29udGFpbnMgbWV0YWRhdGEgYWJvdXQgaG93IG11Y2ggc3VzdGFpbmFi
aWxpdHkgYSByZWNvbW1lbmRhdGlvbiBjYW4gc2F2ZSBvcgogaW5jdXIuCgoLCgMEBwESBJQC
CCAKjQEKBAQHAgASBJcCAhYafyBDYXJib24gRm9vdHByaW50IGdlbmVyYXRlZCBpbiBrZyBv
ZiBDTzIgZXF1aXZhbGVudC4KIENob3NlIGtnX2NfbzJlIHNvIHRoYXQgdGhlIG5hbWUgcmVu
ZGVycyBjb3JyZWN0bHkgaW4gY2FtZWxDYXNlIChrZ0NPMmUpLgoKDQoFBAcCAAUSBJcCAggK
DQoFBAcCAAESBJcCCREKDQoFBAcCAAMSBJcCFBUKPwoEBAcCARIEmgICKBoxIER1cmF0aW9u
IGZvciB3aGljaCB0aGlzIHN1c3RhaW5hYmlsaXR5IGFwcGxpZXMuCgoNCgUEBwIBBhIEmgIC
GgoNCgUEBwIBARIEmgIbIwoNCgUEBwIBAxIEmgImJwpTCgIECBIGngIAtAIBGkUgQ29udGFp
bnMgaW5mb3JtYXRpb24gb24gdGhlIGltcGFjdCBvZiBhIHJlbGlhYmlsaXR5IHJlY29tbWVu
ZGF0aW9uLgoKCwoDBAgBEgSeAggdCkEKBAQIBAASBqACAq0CAxoxIFRoZSByaXNrIGFzc29j
aWF0ZWQgd2l0aCB0aGUgcmVsaWFiaWxpdHkgaXNzdWUuCgoNCgUECAQAARIEoAIHDwo/CgYE
CAQAAgASBKICBB4aLyBEZWZhdWx0IHVuc3BlY2lmaWVkIHJpc2suIERvbid0IHVzZSBkaXJl
Y3RseS4KCg8KBwQIBAACAAESBKICBBkKDwoHBAgEAAIAAhIEogIcHQotCgYECAQAAgESBKUC
BBsaHSBQb3RlbnRpYWwgc2VydmljZSBkb3dudGltZS4KCg8KBwQIBAACAQESBKUCBBYKDwoH
BAgEAAIBAhIEpQIZGgomCgYECAQAAgISBKgCBBIaFiBQb3RlbnRpYWwgZGF0YSBsb3NzLgoK
DwoHBAgEAAICARIEqAIEDQoPCgcECAQAAgICEgSoAhARCmwKBgQIBAACAxIErAIEFBpcIFBv
dGVudGlhbCBhY2Nlc3MgZGVuaWFsLiBUaGUgc2VydmljZSBpcyBzdGlsbCB1cCBidXQgc29t
ZSBvciBhbGwgY2xpZW50cwogY2FuJ3QgYWNjZXNzIGl0LgoKDwoHBAgEAAIDARIErAIEDwoP
CgcECAQAAgMCEgSsAhITCkMKBAQIAgASBLACAh4aNSBSZWxpYWJpbGl0eSByaXNrcyBtaXRp
Z2F0ZWQgYnkgdGhpcyByZWNvbW1lbmRhdGlvbi4KCg0KBQQIAgAEEgSwAgIKCg0KBQQIAgAG
EgSwAgsTCg0KBQQIAgABEgSwAhQZCg0KBQQIAgADEgSwAhwdCisKBAQIAgESBLMCAiUaHSBQ
ZXItcmVjb21tZW5kZXIgcHJvamVjdGlvbi4KCg0KBQQIAgEGEgSzAgIYCg0KBQQIAgEBEgSz
AhkgCg0KBQQIAgEDEgSzAiMkClMKAgQJEga3AgDkAgEaRSBDb250YWlucyB0aGUgaW1wYWN0
IGEgcmVjb21tZW5kYXRpb24gY2FuIGhhdmUgZm9yIGEgZ2l2ZW4gY2F0ZWdvcnkuCgoLCgME
CQESBLcCCA4KLQoEBAkEABIGuQICzgIDGh0gVGhlIGNhdGVnb3J5IG9mIHRoZSBpbXBhY3Qu
CgoNCgUECQQAARIEuQIHDwpDCgYECQQAAgASBLsCBB0aMyBEZWZhdWx0IHVuc3BlY2lmaWVk
IGNhdGVnb3J5LiBEb24ndCB1c2UgZGlyZWN0bHkuCgoPCgcECQQAAgABEgS7AgQYCg8KBwQJ
BAACAAISBLsCGxwKRQoGBAkEAAIBEgS+AgQNGjUgSW5kaWNhdGVzIGEgcG90ZW50aWFsIGlu
Y3JlYXNlIG9yIGRlY3JlYXNlIGluIGNvc3QuCgoPCgcECQQAAgEBEgS+AgQICg8KBwQJBAAC
AQISBL4CCwwKSQoGBAkEAAICEgTBAgQRGjkgSW5kaWNhdGVzIGEgcG90ZW50aWFsIGluY3Jl
YXNlIG9yIGRlY3JlYXNlIGluIHNlY3VyaXR5LgoKDwoHBAkEAAICARIEwQIEDAoPCgcECQQA
AgICEgTBAg8QCkwKBgQJBAACAxIExAIEFBo8IEluZGljYXRlcyBhIHBvdGVudGlhbCBpbmNy
ZWFzZSBvciBkZWNyZWFzZSBpbiBwZXJmb3JtYW5jZS4KCg8KBwQJBAACAwESBMQCBA8KDwoH
BAkEAAIDAhIExAISEwpOCgYECQQAAgQSBMcCBBYaPiBJbmRpY2F0ZXMgYSBwb3RlbnRpYWwg
aW5jcmVhc2Ugb3IgZGVjcmVhc2UgaW4gbWFuYWdlYWJpbGl0eS4KCg8KBwQJBAACBAESBMcC
BBEKDwoHBAkEAAIEAhIExwIUFQpPCgYECQQAAgUSBMoCBBcaPyBJbmRpY2F0ZXMgYSBwb3Rl
bnRpYWwgaW5jcmVhc2Ugb3IgZGVjcmVhc2UgaW4gc3VzdGFpbmFiaWxpdHkuCgoPCgcECQQA
AgUBEgTKAgQSCg8KBwQJBAACBQISBMoCFRYKTAoGBAkEAAIGEgTNAgQUGjwgSW5kaWNhdGVz
IGEgcG90ZW50aWFsIGluY3JlYXNlIG9yIGRlY3JlYXNlIGluIHJlbGlhYmlsaXR5LgoKDwoH
BAkEAAIGARIEzQIEDwoPCgcECQQAAgYCEgTNAhITCjAKBAQJAgASBNECAhgaIiBDYXRlZ29y
eSB0aGF0IGlzIGJlaW5nIHRhcmdldGVkLgoKDQoFBAkCAAYSBNECAgoKDQoFBAkCAAESBNEC
CxMKDQoFBAkCAAMSBNECFhcKQgoEBAkIABIG1AIC4AIDGjIgQ29udGFpbnMgcHJvamVjdGlv
bnMgKGlmIGFueSkgZm9yIHRoaXMgY2F0ZWdvcnkuCgoNCgUECQgAARIE1AIIEgoqCgQECQIB
EgTWAgQpGhwgVXNlIHdpdGggQ2F0ZWdvcnlUeXBlLkNPU1QKCg0KBQQJAgEGEgTWAgQSCg0K
BQQJAgEBEgTWAhMiCg0KBQQJAgEDEgTWAiUoCi4KBAQJAgISBNkCBDEaICBVc2Ugd2l0aCBD
YXRlZ29yeVR5cGUuU0VDVVJJVFkKCg0KBQQJAgIGEgTZAgQWCg0KBQQJAgIBEgTZAhcqCg0K
BQQJAgIDEgTZAi0wCjQKBAQJAgMSBNwCBD0aJiBVc2Ugd2l0aCBDYXRlZ29yeVR5cGUuU1VT
VEFJTkFCSUxJVFkKCg0KBQQJAgMGEgTcAgQcCg0KBQQJAgMBEgTcAh02Cg0KBQQJAgMDEgTc
Ajk8CjEKBAQJAgQSBN8CBDcaIyBVc2Ugd2l0aCBDYXRlZ29yeVR5cGUuUkVMSUFCSUxJVFkK
Cg0KBQQJAgQGEgTfAgQZCg0KBQQJAgQBEgTfAhowCg0KBQQJAgQDEgTfAjM2CkAKBAQJAgUS
BOMCAhUaMiBUaGUgc2VydmljZSB0aGF0IHRoaXMgaW1wYWN0IGlzIGFzc29jaWF0ZWQgd2l0
aC4KCg0KBQQJAgUFEgTjAgIICg0KBQQJAgUBEgTjAgkQCg0KBQQJAgUDEgTjAhMUCkMKAgQK
EgbnAgCRAwEaNSBJbmZvcm1hdGlvbiBmb3Igc3RhdGUuIENvbnRhaW5zIHN0YXRlIGFuZCBt
ZXRhZGF0YS4KCgsKAwQKARIE5wIIHwoyCgQECgQAEgbpAgKKAwMaIiBSZXByZXNlbnRzIFJl
Y29tbWVuZGF0aW9uIFN0YXRlLgoKDQoFBAoEAAESBOkCBwwKNAoGBAoEAAIAEgTrAgQaGiQg
RGVmYXVsdCBzdGF0ZS4gRG9uJ3QgdXNlIGRpcmVjdGx5LgoKDwoHBAoEAAIAARIE6wIEFQoP
CgcECgQAAgACEgTrAhgZCrsBCgYECgQAAgESBPECBA8aqgEgUmVjb21tZW5kYXRpb24gaXMg
YWN0aXZlIGFuZCBjYW4gYmUgYXBwbGllZC4gUmVjb21tZW5kYXRpb25zIGNvbnRlbnQgY2Fu
CiBiZSB1cGRhdGVkIGJ5IEdvb2dsZS4KCiBBQ1RJVkUgcmVjb21tZW5kYXRpb25zIGNhbiBi
ZSBtYXJrZWQgYXMgQ0xBSU1FRCwgU1VDQ0VFREVELCBvciBGQUlMRUQuCgoPCgcECgQAAgEB
EgTxAgQKCg8KBwQKBAACAQISBPECDQ4KxwEKBgQKBAACAhIE9wIEEBq2ASBSZWNvbW1lbmRh
dGlvbiBpcyBpbiBjbGFpbWVkIHN0YXRlLiBSZWNvbW1lbmRhdGlvbnMgY29udGVudCBpcwog
aW1tdXRhYmxlIGFuZCBjYW5ub3QgYmUgdXBkYXRlZCBieSBHb29nbGUuCgogQ0xBSU1FRCBy
ZWNvbW1lbmRhdGlvbnMgY2FuIGJlIG1hcmtlZCBhcyBDTEFJTUVELCBTVUNDRUVERUQsIG9y
IEZBSUxFRC4KCg8KBwQKBAACAgESBPcCBAsKDwoHBAoEAAICAhIE9wIODwrCAQoGBAoEAAID
EgT9AgQSGrEBIFJlY29tbWVuZGF0aW9uIGlzIGluIHN1Y2NlZWRlZCBzdGF0ZS4gUmVjb21t
ZW5kYXRpb25zIGNvbnRlbnQgaXMKIGltbXV0YWJsZSBhbmQgY2Fubm90IGJlIHVwZGF0ZWQg
YnkgR29vZ2xlLgoKIFNVQ0NFRURFRCByZWNvbW1lbmRhdGlvbnMgY2FuIGJlIG1hcmtlZCBh
cyBTVUNDRUVERUQsIG9yIEZBSUxFRC4KCg8KBwQKBAACAwESBP0CBA0KDwoHBAoEAAIDAhIE
/QIQEQq8AQoGBAoEAAIEEgSDAwQPGqsBIFJlY29tbWVuZGF0aW9uIGlzIGluIGZhaWxlZCBz
dGF0ZS4gUmVjb21tZW5kYXRpb25zIGNvbnRlbnQgaXMgaW1tdXRhYmxlCiBhbmQgY2Fubm90
IGJlIHVwZGF0ZWQgYnkgR29vZ2xlLgoKIEZBSUxFRCByZWNvbW1lbmRhdGlvbnMgY2FuIGJl
IG1hcmtlZCBhcyBTVUNDRUVERUQsIG9yIEZBSUxFRC4KCg8KBwQKBAACBAESBIMDBAoKDwoH
BAoEAAIEAhIEgwMNDgqfAQoGBAoEAAIFEgSJAwQSGo4BIFJlY29tbWVuZGF0aW9uIGlzIGlu
IGRpc21pc3NlZCBzdGF0ZS4gUmVjb21tZW5kYXRpb24gY29udGVudCBjYW4gYmUKIHVwZGF0
ZWQgYnkgR29vZ2xlLgoKIERJU01JU1NFRCByZWNvbW1lbmRhdGlvbnMgY2FuIGJlIG1hcmtl
ZCBhcyBBQ1RJVkUuCgoPCgcECgQAAgUBEgSJAwQNCg8KBwQKBAACBQISBIkDEBEKTgoEBAoC
ABIEjQMCEhpAIFRoZSBzdGF0ZSBvZiB0aGUgcmVjb21tZW5kYXRpb24sIEVnIEFDVElWRSwg
U1VDQ0VFREVELCBGQUlMRUQuCgoNCgUECgIABhIEjQMCBwoNCgUECgIAARIEjQMIDQoNCgUE
CgIAAxIEjQMQEQpZCgQECgIBEgSQAwIpGksgQSBtYXAgb2YgbWV0YWRhdGEgZm9yIHRoZSBz
dGF0ZSwgcHJvdmlkZWQgYnkgdXNlciBvciBhdXRvbWF0aW9ucyBzeXN0ZW1zLgoKDQoFBAoC
AQYSBJADAhUKDQoFBAoCAQESBJADFiQKDQoFBAoCAQMSBJADJyhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1::Recommendation::Recommendation ===
    # Fields for Recommendation
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: recommender_subtype Type: 9 ()
    # Field: last_refresh_time Type: 11 (.google.protobuf.Timestamp)
    # Field: primary_impact Type: 11 (.google.cloud.recommender.v1.Impact)
    # Field: additional_impact Type: 11 (.google.cloud.recommender.v1.Impact)
    # Field: priority Type: 14 (.google.cloud.recommender.v1.Recommendation.Priority)
    # Field: content Type: 11 (.google.cloud.recommender.v1.RecommendationContent)
    # Field: state_info Type: 11 (.google.cloud.recommender.v1.RecommendationStateInfo)
    # Field: etag Type: 9 ()
    # Field: associated_insights Type: 11 (.google.cloud.recommender.v1.Recommendation.InsightReference)
    # Field: xor_group_id Type: 9 ()
    # Field: target_resources Type: 9 ()

# Enum: Recommendation::Priority
our $Recommendation_PRIORITY_UNSPECIFIED = 0;
our $Recommendation_P4 = 1;
our $Recommendation_P3 = 2;
our $Recommendation_P2 = 3;
our $Recommendation_P1 = 4;

# === Message: Google::Cloud::Recommender::V1::Recommendation::RecommendationContent ===
    # Fields for RecommendationContent
    # Field: operation_groups Type: 11 (.google.cloud.recommender.v1.OperationGroup)
    # Field: overview Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Recommender::V1::Recommendation::OperationGroup ===
    # Fields for OperationGroup
    # Field: operations Type: 11 (.google.cloud.recommender.v1.Operation)

# === Message: Google::Cloud::Recommender::V1::Recommendation::Operation ===
    # Fields for Operation
    # Field: action Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: path Type: 9 ()
    # Field: source_resource Type: 9 ()
    # Field: source_path Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: value_matcher Type: 11 (.google.cloud.recommender.v1.ValueMatcher)
    # Field: path_filters Type: 11 (.google.cloud.recommender.v1.Operation.PathFiltersEntry)
    # Field: path_value_matchers Type: 11 (.google.cloud.recommender.v1.Operation.PathValueMatchersEntry)

# === Message: Google::Cloud::Recommender::V1::Recommendation::ValueMatcher ===
    # Fields for ValueMatcher
    # Field: matches_pattern Type: 9 ()

# === Message: Google::Cloud::Recommender::V1::Recommendation::CostProjection ===
    # Fields for CostProjection
    # Field: cost Type: 11 (.google.type.Money)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: cost_in_local_currency Type: 11 (.google.type.Money)

# === Message: Google::Cloud::Recommender::V1::Recommendation::SecurityProjection ===
    # Fields for SecurityProjection
    # Field: details Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Recommender::V1::Recommendation::SustainabilityProjection ===
    # Fields for SustainabilityProjection
    # Field: kg_c_o2e Type: 1 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Recommender::V1::Recommendation::ReliabilityProjection ===
    # Fields for ReliabilityProjection
    # Field: risks Type: 14 (.google.cloud.recommender.v1.ReliabilityProjection.RiskType)
    # Field: details Type: 11 (.google.protobuf.Struct)

# Enum: ReliabilityProjection::RiskType
our $ReliabilityProjection_RISK_TYPE_UNSPECIFIED = 0;
our $ReliabilityProjection_SERVICE_DISRUPTION = 1;
our $ReliabilityProjection_DATA_LOSS = 2;
our $ReliabilityProjection_ACCESS_DENY = 3;

# === Message: Google::Cloud::Recommender::V1::Recommendation::Impact ===
    # Fields for Impact
    # Field: category Type: 14 (.google.cloud.recommender.v1.Impact.Category)
    # Field: cost_projection Type: 11 (.google.cloud.recommender.v1.CostProjection)
    # Field: security_projection Type: 11 (.google.cloud.recommender.v1.SecurityProjection)
    # Field: sustainability_projection Type: 11 (.google.cloud.recommender.v1.SustainabilityProjection)
    # Field: reliability_projection Type: 11 (.google.cloud.recommender.v1.ReliabilityProjection)
    # Field: service Type: 9 ()

# Enum: Impact::Category
our $Impact_CATEGORY_UNSPECIFIED = 0;
our $Impact_COST = 1;
our $Impact_SECURITY = 2;
our $Impact_PERFORMANCE = 3;
our $Impact_MANAGEABILITY = 4;
our $Impact_SUSTAINABILITY = 5;
our $Impact_RELIABILITY = 6;

# === Message: Google::Cloud::Recommender::V1::Recommendation::RecommendationStateInfo ===
    # Fields for RecommendationStateInfo
    # Field: state Type: 14 (.google.cloud.recommender.v1.RecommendationStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.v1.RecommendationStateInfo.StateMetadataEntry)

# Enum: RecommendationStateInfo::State
our $RecommendationStateInfo_STATE_UNSPECIFIED = 0;
our $RecommendationStateInfo_ACTIVE = 1;
our $RecommendationStateInfo_CLAIMED = 6;
our $RecommendationStateInfo_SUCCEEDED = 3;
our $RecommendationStateInfo_FAILED = 4;
our $RecommendationStateInfo_DISMISSED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1::Recommendation - Compiled Protocol Buffers messages for google/cloud/recommender/v1/recommendation.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1::Recommendation;

    my $msg = Google::Cloud::Recommender::V1::Recommendation::Recommendation->new({
        name => $name,
        description => $description,
        recommender_subtype => $recommender_subtype,
        last_refresh_time => $last_refresh_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1::Recommendation::Recommendation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1/recommendation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1::Recommendation::Recommendation

A recommendation along with a suggested action. E.g., a rightsizing
recommendation for an underutilized VM, IAM role recommendations, etc

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of recommendation.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Free-form human readable summary in English. The maximum length is 500
characters.

=item * C<< $msg->recommender_subtype() >> / C<< $msg->recommender_subtype($value) >>

Type: C<String>

Contains an identifier for a subtype of recommendations produced for the
same recommender. Subtype is a function of content and impact, meaning a
new subtype might be added when significant changes to `content` or
`primary_impact.category` are introduced. See the Recommenders section
to see a list of subtypes for a given Recommender.

Examples:
  For recommender = "google.iam.policy.Recommender",
  recommender_subtype can be one of "REMOVE_ROLE"/"REPLACE_ROLE"

=item * C<< $msg->last_refresh_time() >> / C<< $msg->last_refresh_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Last time this recommendation was refreshed by the system that created it
in the first place.

=item * C<< $msg->primary_impact() >> / C<< $msg->primary_impact($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Impact>)

The primary impact that this recommendation can have while trying to
optimize for one category.

=item * C<< $msg->additional_impact() >> / C<< $msg->additional_impact($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Impact>)

Optional set of additional impact that this recommendation may have when
trying to optimize for the primary category. These may be positive
or negative.

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::Recommendation::Priority>)

Recommendation's priority.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::RecommendationContent>)

Content of the recommendation describing recommended changes to resources.

=item * C<< $msg->state_info() >> / C<< $msg->state_info($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::RecommendationStateInfo>)

Information for state. Contains state and metadata.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the Recommendation. Provides optimistic locking when
updating states.

=item * C<< $msg->associated_insights() >> / C<< $msg->associated_insights($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Recommendation::InsightReference>)

Insights that led to this recommendation.

=item * C<< $msg->xor_group_id() >> / C<< $msg->xor_group_id($value) >>

Type: C<String>

Corresponds to a mutually exclusive group ID within a recommender.
A non-empty ID indicates that the recommendation belongs to a mutually
exclusive group. This means that only one recommendation within the group
is suggested to be applied.

=item * C<< $msg->target_resources() >> / C<< $msg->target_resources($value) >>

Type: C<String>

Fully qualified resource names that this recommendation is targeting.

=back

=head3 Enum: Recommendation::Priority

=over 4

=item * C<PRIORITY_UNSPECIFIED> => C<0>

=item * C<P4> => C<1>

=item * C<P3> => C<2>

=item * C<P2> => C<3>

=item * C<P1> => C<4>

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::RecommendationContent

Contains what resources are changing and how they are changing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_groups() >> / C<< $msg->operation_groups($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::OperationGroup>)

Operations to one or more Google Cloud resources grouped in such a way
that, all operations within one group are expected to be performed
atomically and in an order.

=item * C<< $msg->overview() >> / C<< $msg->overview($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Condensed overview information about the recommendation.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::OperationGroup

Group of operations that need to be performed atomically.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operations() >> / C<< $msg->operations($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Operation>)

List of operations across one or more resources that belong to this group.
Loosely based on RFC6902 and should be performed in the order they appear.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::Operation

Contains an operation for a resource loosely based on the JSON-PATCH format
with support for:

* Custom filters for describing partial array patch.
* Extended path values for describing nested arrays.
* Custom fields for describing the resource for which the operation is being
  described.
* Allows extension to custom operations not natively supported by RFC6902.
See https://tools.ietf.org/html/rfc6902 for details on the original RFC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Type of this operation. Contains one of 'add', 'remove', 'replace', 'move',
'copy', 'test' and custom operations. This field is case-insensitive and
always populated.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Type of GCP resource being modified/tested. This field is always populated.
Example: cloudresourcemanager.googleapis.com/Project,
compute.googleapis.com/Instance

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Contains the fully qualified resource name. This field is always populated.
ex: //cloudresourcemanager.googleapis.com/projects/foo.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path to the target field being operated on. If the operation is at the
resource level, then path should be "/". This field is always populated.

=item * C<< $msg->source_resource() >> / C<< $msg->source_resource($value) >>

Type: C<String>

Can be set with action 'copy' to copy resource configuration across
different resources of the same type. Example: A resource clone can be
done via action = 'copy', path = "/", from = "/",
source_resource = <source> and resource_name = <target>.
This field is empty for all other values of `action`.

=item * C<< $msg->source_path() >> / C<< $msg->source_path($value) >>

Type: C<String>

Can be set with action 'copy' or 'move' to indicate the source field within
resource or source_resource, ignored if provided for other operation types.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Value for the `path` field. Will be set for actions:'add'/'replace'.
Maybe set for action: 'test'. Either this or `value_matcher` will be set
for 'test' operation. An exact match must be performed.

=item * C<< $msg->value_matcher() >> / C<< $msg->value_matcher($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::ValueMatcher>)

Can be set for action 'test' for advanced matching for the value of
'path' field. Either this or `value` will be set for 'test' operation.

=item * C<< $msg->path_filters() >> / C<< $msg->path_filters($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Operation::PathFiltersEntry>)

Set of filters to apply if `path` refers to array elements or nested array
elements in order to narrow down to a single unique element that is being
tested/modified.
This is intended to be an exact match per filter. To perform advanced
matching, use path_value_matchers.

* Example:
```
{
  "/versions/*/name" : "it-123"
  "/versions/*/targetSize/percent": 20
}
```
* Example:
```
{
  "/bindings/*/role": "roles/owner"
  "/bindings/*/condition" : null
}
```
* Example:
```
{
  "/bindings/*/role": "roles/owner"
  "/bindings/*/members/*" : ["x@example.com", "y@example.com"]
}
```
When both path_filters and path_value_matchers are set, an implicit AND
must be performed.

=item * C<< $msg->path_value_matchers() >> / C<< $msg->path_value_matchers($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::Operation::PathValueMatchersEntry>)

Similar to path_filters, this contains set of filters to apply if `path`
field refers to array elements. This is meant to support value matching
beyond exact match. To perform exact match, use path_filters.
When both path_filters and path_value_matchers are set, an implicit AND
must be performed.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::ValueMatcher

Contains various matching options for values for a GCP resource field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matches_pattern() >> / C<< $msg->matches_pattern($value) >>

Type: C<String>

To be used for full regex matching. The regular expression is using the
Google RE2 syntax (https://github.com/google/re2/wiki/Syntax), so to be
used with RE2::FullMatch

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::CostProjection

Contains metadata about how much money a recommendation can save or incur.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

An approximate projection on amount saved or amount incurred. Negative cost
units indicate cost savings and positive cost units indicate increase.
See google.type.Money documentation for positive/negative units.

A user's permissions may affect whether the cost is computed using list
prices or custom contract prices.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration for which this cost applies.

=item * C<< $msg->cost_in_local_currency() >> / C<< $msg->cost_in_local_currency($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

The approximate cost savings in the billing account's local currency.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::SecurityProjection

Contains various ways of describing the impact on Security.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Additional security impact details that is provided by the recommender.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::SustainabilityProjection

Contains metadata about how much sustainability a recommendation can save or
incur.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kg_c_o2e() >> / C<< $msg->kg_c_o2e($value) >>

Type: C<Double>

Carbon Footprint generated in kg of CO2 equivalent.
Chose kg_c_o2e so that the name renders correctly in camelCase (kgCO2e).

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration for which this sustainability applies.

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::ReliabilityProjection

Contains information on the impact of a reliability recommendation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->risks() >> / C<< $msg->risks($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::ReliabilityProjection::RiskType>)

Reliability risks mitigated by this recommendation.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Per-recommender projection.

=back

=head3 Enum: ReliabilityProjection::RiskType

=over 4

=item * C<RISK_TYPE_UNSPECIFIED> => C<0>

=item * C<SERVICE_DISRUPTION> => C<1>

=item * C<DATA_LOSS> => C<2>

=item * C<ACCESS_DENY> => C<3>

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::Impact

Contains the impact a recommendation can have for a given category.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::Impact::Category>)

Category that is being targeted.

=item * C<< $msg->cost_projection() >> / C<< $msg->cost_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::CostProjection>)

Use with CategoryType.COST

=item * C<< $msg->security_projection() >> / C<< $msg->security_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::SecurityProjection>)

Use with CategoryType.SECURITY

=item * C<< $msg->sustainability_projection() >> / C<< $msg->sustainability_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::SustainabilityProjection>)

Use with CategoryType.SUSTAINABILITY

=item * C<< $msg->reliability_projection() >> / C<< $msg->reliability_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::ReliabilityProjection>)

Use with CategoryType.RELIABILITY

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The service that this impact is associated with.

=back

=head3 Enum: Impact::Category

=over 4

=item * C<CATEGORY_UNSPECIFIED> => C<0>

=item * C<COST> => C<1>

=item * C<SECURITY> => C<2>

=item * C<PERFORMANCE> => C<3>

=item * C<MANAGEABILITY> => C<4>

=item * C<SUSTAINABILITY> => C<5>

=item * C<RELIABILITY> => C<6>

=back

=head2 Google::Cloud::Recommender::V1::Recommendation::RecommendationStateInfo

Information for state. Contains state and metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::RecommendationStateInfo::State>)

The state of the recommendation, Eg ACTIVE, SUCCEEDED, FAILED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Recommendation::RecommendationStateInfo::StateMetadataEntry>)

A map of metadata for the state, provided by user or automations systems.

=back

=head3 Enum: RecommendationStateInfo::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<CLAIMED> => C<6>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DISMISSED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1::Recommendation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
