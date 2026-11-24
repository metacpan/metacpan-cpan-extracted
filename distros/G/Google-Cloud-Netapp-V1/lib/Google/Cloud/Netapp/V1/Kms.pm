package Google::Cloud::Netapp::V1::Kms;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvbmV0YXBwL3YxL2ttcy5wcm90bxIWZ29vZ2xlLmNsb3VkLm5ldGFw
cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8iUgoTR2V0S21zQ29uZmlnUmVxdWVzdBI7CgRuYW1l
GAEgASgJQifgQQL6QSEKH25ldGFwcC5nb29nbGVhcGlzLmNvbS9LbXNDb25maWdSBG5hbWUi
xwEKFUxpc3RLbXNDb25maWdzUmVxdWVzdBI/CgZwYXJlbnQYASABKAlCJ+BBAvpBIRIfbmV0
YXBwLmdvb2dsZWFwaXMuY29tL0ttc0NvbmZpZ1IGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEo
BVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhkKCG9yZGVyX2J5
GAQgASgJUgdvcmRlckJ5EhYKBmZpbHRlchgFIAEoCVIGZmlsdGVyIqYBChZMaXN0S21zQ29u
Zmlnc1Jlc3BvbnNlEkIKC2ttc19jb25maWdzGAEgAygLMiEuZ29vZ2xlLmNsb3VkLm5ldGFw
cC52MS5LbXNDb25maWdSCmttc0NvbmZpZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSLJAQoWQ3Jl
YXRlS21zQ29uZmlnUmVxdWVzdBI/CgZwYXJlbnQYASABKAlCJ+BBAvpBIRIfbmV0YXBwLmdv
b2dsZWFwaXMuY29tL0ttc0NvbmZpZ1IGcGFyZW50EicKDWttc19jb25maWdfaWQYAiABKAlC
A+BBAlILa21zQ29uZmlnSWQSRQoKa21zX2NvbmZpZxgDIAEoCzIhLmdvb2dsZS5jbG91ZC5u
ZXRhcHAudjEuS21zQ29uZmlnQgPgQQJSCWttc0NvbmZpZyKhAQoWVXBkYXRlS21zQ29uZmln
UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1h
c2tCA+BBAlIKdXBkYXRlTWFzaxJFCgprbXNfY29uZmlnGAIgASgLMiEuZ29vZ2xlLmNsb3Vk
Lm5ldGFwcC52MS5LbXNDb25maWdCA+BBAlIJa21zQ29uZmlnIlUKFkRlbGV0ZUttc0NvbmZp
Z1JlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9uZXRhcHAuZ29vZ2xlYXBpcy5jb20v
S21zQ29uZmlnUgRuYW1lIlQKFUVuY3J5cHRWb2x1bWVzUmVxdWVzdBI7CgRuYW1lGAEgASgJ
QifgQQL6QSEKH25ldGFwcC5nb29nbGVhcGlzLmNvbS9LbXNDb25maWdSBG5hbWUiVQoWVmVy
aWZ5S21zQ29uZmlnUmVxdWVzdBI7CgRuYW1lGAEgASgJQifgQQL6QSEKH25ldGFwcC5nb29n
bGVhcGlzLmNvbS9LbXNDb25maWdSBG5hbWUiiQEKF1ZlcmlmeUttc0NvbmZpZ1Jlc3BvbnNl
Eh0KB2hlYWx0aHkYASABKAhCA+BBA1IHaGVhbHRoeRImCgxoZWFsdGhfZXJyb3IYAiABKAlC
A+BBA1ILaGVhbHRoRXJyb3ISJwoMaW5zdHJ1Y3Rpb25zGAMgASgJQgPgQQNSDGluc3RydWN0
aW9ucyLnBgoJS21zQ29uZmlnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJRCg9jcnlwdG9f
a2V5X25hbWUYAiABKAlCKeBBAvpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRv
S2V5Ug1jcnlwdG9LZXlOYW1lEkIKBXN0YXRlGAMgASgOMicuZ29vZ2xlLmNsb3VkLm5ldGFw
cC52MS5LbXNDb25maWcuU3RhdGVCA+BBA1IFc3RhdGUSKAoNc3RhdGVfZGV0YWlscxgEIAEo
CUID4EEDUgxzdGF0ZURldGFpbHMSQAoLY3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSIAoLZGVzY3JpcHRpb24YBiABKAlS
C2Rlc2NyaXB0aW9uEkUKBmxhYmVscxgHIAMoCzItLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEu
S21zQ29uZmlnLkxhYmVsc0VudHJ5UgZsYWJlbHMSJwoMaW5zdHJ1Y3Rpb25zGAggASgJQgPg
QQNSDGluc3RydWN0aW9ucxIsCg9zZXJ2aWNlX2FjY291bnQYCSABKAlCA+BBA1IOc2Vydmlj
ZUFjY291bnQaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ASLEAQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIJCgVSRUFE
WRABEgwKCENSRUFUSU5HEAISDAoIREVMRVRJTkcQAxIMCghVUERBVElORxAEEgoKBklOX1VT
RRAFEgkKBUVSUk9SEAYSFQoRS0VZX0NIRUNLX1BFTkRJTkcQBxIVChFLRVlfTk9UX1JFQUNI
QUJMRRAIEg0KCURJU0FCTElORxAJEgwKCERJU0FCTEVEEAoSDQoJTUlHUkFUSU5HEAs6fOpB
eQofbmV0YXBwLmdvb2dsZWFwaXMuY29tL0ttc0NvbmZpZxI/cHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2ttc0NvbmZpZ3Mve2ttc19jb25maWd9KgprbXNDb25m
aWdzMglrbXNDb25maWdCzwMKGmNvbS5nb29nbGUuY2xvdWQubmV0YXBwLnYxQghLbXNQcm90
b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL25ldGFwcC9hcGl2MS9uZXRhcHBwYjtuZXRhcHBw
YqoCFkdvb2dsZS5DbG91ZC5OZXRBcHAuVjHKAhZHb29nbGVcQ2xvdWRcTmV0QXBwXFYx6gIZ
R29vZ2xlOjpDbG91ZDo6TmV0QXBwOjpWMepBeAohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20v
Q3J5cHRvS2V5ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5
UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fepBpgEKKGNsb3Vka21z
Lmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleVZlcnNpb24SenByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tleXMve2Ny
eXB0b19rZXl9L2NyeXB0b0tleVZlcnNpb25zL3tjcnlwdG9fa2V5X3ZlcnNpb259SuY6CgcS
BQ4A/gEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAqCgkKAgMDEgMVACkKCAoBCBIDFwAzCgkK
AgglEgMXADMKCAoBCBIDGABJCgkKAggLEgMYAEkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgApCgkKAggIEgMaACkKCAoBCBIDGwAzCgkKAggBEgMbADMKCAoBCBIDHAAzCgkKAggp
EgMcADMKCAoBCBIDHQAyCgkKAggtEgMdADIKCQoBCBIEHgAhAgoMCgQInQgAEgQeACECCgkK
AQgSBCIAJQIKDAoECJ0IARIEIgAlAgo0CgIEABIEKAAwARooIEdldEttc0NvbmZpZ1JlcXVl
c3QgZ2V0cyBhIEtNUyBDb25maWcuCgoKCgMEAAESAygIGwovCgQEAAIAEgQqAi8EGiEgUmVx
dWlyZWQuIE5hbWUgb2YgdGhlIEttc0NvbmZpZwoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARID
KgkNCgwKBQQAAgADEgMqEBEKDQoFBAACAAgSBCoSLwMKDwoIBAACAAicCAASAysEKgoPCgcE
AAIACJ8IEgQsBC4FCjYKAgQBEgQzAEgBGiogTGlzdEttc0NvbmZpZ3NSZXF1ZXN0IGxpc3Rz
IEtNUyBDb25maWdzLgoKCgoDBAEBEgMzCB0KJgoEBAECABIENQI6BBoYIFJlcXVpcmVkLiBQ
YXJlbnQgdmFsdWUKCgwKBQQBAgAFEgM1AggKDAoFBAECAAESAzUJDwoMCgUEAQIAAxIDNRIT
Cg0KBQQBAgAIEgQ1FDoDCg8KCAQBAgAInAgAEgM2BCoKDwoHBAECAAifCBIENwQ5BQo1CgQE
AQIBEgM9AhYaKCBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgoKDAoF
BAECAQUSAz0CBwoMCgUEAQIBARIDPQgRCgwKBQQBAgEDEgM9FBUKcwoEBAECAhIDQQIYGmYg
VGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSB0byB1c2UgaWYgdGhlcmUgYXJlIGFkZGl0aW9u
YWwKIHJlc3VsdHMgdG8gcmV0cmlldmUgZm9yIHRoaXMgbGlzdCByZXF1ZXN0LgoKDAoFBAEC
AgUSA0ECCAoMCgUEAQICARIDQQkTCgwKBQQBAgIDEgNBFhcKVwoEBAECAxIDRAIWGkogU29y
dCByZXN1bHRzLiBTdXBwb3J0ZWQgdmFsdWVzIGFyZSAibmFtZSIsICJuYW1lIGRlc2MiIG9y
ICIiICh1bnNvcnRlZCkuCgoMCgUEAQIDBRIDRAIICgwKBQQBAgMBEgNECREKDAoFBAECAwMS
A0QUFQobCgQEAQIEEgNHAhQaDiBMaXN0IGZpbHRlci4KCgwKBQQBAgQFEgNHAggKDAoFBAEC
BAESA0cJDwoMCgUEAQIEAxIDRxITClAKAgQCEgRLAFQBGkQgTGlzdEttc0NvbmZpZ3NSZXNw
b25zZSBpcyB0aGUgcmVzcG9uc2UgdG8gYSBMaXN0S21zQ29uZmlnc1JlcXVlc3QuCgoKCgME
AgESA0sIHgolCgQEAgIAEgNNAiUaGCBUaGUgbGlzdCBvZiBLbXNDb25maWdzCgoMCgUEAgIA
BBIDTQIKCgwKBQQCAgAGEgNNCxQKDAoFBAICAAESA00VIAoMCgUEAgIAAxIDTSMkCk4KBAQC
AgESA1ACHRpBIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNl
cnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAICAQUSA1ACCAoMCgUEAgIBARIDUAkYCgwKBQQC
AgEDEgNQGxwKMwoEBAICAhIDUwIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJl
YWNoZWQuCgoMCgUEAgICBBIDUwIKCgwKBQQCAgIFEgNTCxEKDAoFBAICAgESA1MSHQoMCgUE
AgICAxIDUyAhCjoKAgQDEgRXAGgBGi4gQ3JlYXRlS21zQ29uZmlnUmVxdWVzdCBjcmVhdGVz
IGEgS01TIENvbmZpZy4KCgoKAwQDARIDVwgeCisKBAQDAgASBFkCXgQaHSBSZXF1aXJlZC4g
VmFsdWUgZm9yIHBhcmVudC4KCgwKBQQDAgAFEgNZAggKDAoFBAMCAAESA1kJDwoMCgUEAwIA
AxIDWRITCg0KBQQDAgAIEgRZFF4DCg8KCAQDAgAInAgAEgNaBCoKDwoHBAMCAAifCBIEWwRd
BQr0AQoEBAMCARIDZAJEGuYBIFJlcXVpcmVkLiBJZCBvZiB0aGUgcmVxdWVzdGluZyBLbXND
b25maWcuIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcGFyZW50CiByZXNvdXJjZS4gTXVz
dCBjb250YWluIG9ubHkgbGV0dGVycywgbnVtYmVycyBhbmQgaHlwaGVuLCB3aXRoIHRoZSBm
aXJzdAogY2hhcmFjdGVyIGEgbGV0dGVyLCB0aGUgbGFzdCBhIGxldHRlciBvciBhCiBudW1i
ZXIsIGFuZCBhIDYzIGNoYXJhY3RlciBtYXhpbXVtLgoKDAoFBAMCAQUSA2QCCAoMCgUEAwIB
ARIDZAkWCgwKBQQDAgEDEgNkGRoKDAoFBAMCAQgSA2QbQwoPCggEAwIBCJwIABIDZBxCCksK
BAQDAgISA2cCRBo+IFJlcXVpcmVkLiBUaGUgcmVxdWlyZWQgcGFyYW1ldGVycyB0byBjcmVh
dGUgYSBuZXcgS21zQ29uZmlnLgoKDAoFBAMCAgYSA2cCCwoMCgUEAwICARIDZwwWCgwKBQQD
AgIDEgNnGRoKDAoFBAMCAggSA2cbQwoPCggEAwICCJwIABIDZxxCCjoKAgQEEgRrAHYBGi4g
VXBkYXRlS21zQ29uZmlnUmVxdWVzdCB1cGRhdGVzIGEgS01TIENvbmZpZy4KCgoKAwQEARID
awgeCtkCCgQEBAIAEgRxAnIvGsoCIFJlcXVpcmVkLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8g
c3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogS21zQ29uZmln
IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUg
dXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVs
bCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhl
IG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBm
aWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCgwKBQQEAgAGEgNxAhsKDAoFBAQCAAESA3Ec
JwoMCgUEBAIAAxIDcSorCgwKBQQEAgAIEgNyBi4KDwoIBAQCAAicCAASA3IHLQo0CgQEBAIB
EgN1AkQaJyBSZXF1aXJlZC4gVGhlIEttc0NvbmZpZyBiZWluZyB1cGRhdGVkCgoMCgUEBAIB
BhIDdQILCgwKBQQEAgEBEgN1DBYKDAoFBAQCAQMSA3UZGgoMCgUEBAIBCBIDdRtDCg8KCAQE
AgEInAgAEgN1HEIKOwoCBAUSBXkAgQEBGi4gRGVsZXRlS21zQ29uZmlnUmVxdWVzdCBkZWxl
dGVzIGEgS01TIENvbmZpZy4KCgoKAwQFARIDeQgeCjEKBAQFAgASBXsCgAEEGiIgUmVxdWly
ZWQuIE5hbWUgb2YgdGhlIEttc0NvbmZpZy4KCgwKBQQFAgAFEgN7AggKDAoFBAUCAAESA3sJ
DQoMCgUEBQIAAxIDexARCg4KBQQFAgAIEgV7EoABAwoPCggEBQIACJwIABIDfAQqCg8KBwQF
AgAInwgSBH0EfwUKWwoCBAYSBoQBAIwBARpNIEVuY3J5cHRWb2x1bWVzUmVxdWVzdCBzcGVj
aWZpZXMgdGhlIEtNUyBjb25maWcgdG8gZW5jcnlwdCBleGlzdGluZyB2b2x1bWVzLgoKCwoD
BAYBEgSEAQgdCjIKBAQGAgASBoYBAosBBBoiIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBLbXND
b25maWcuCgoNCgUEBgIABRIEhgECCAoNCgUEBgIAARIEhgEJDQoNCgUEBgIAAxIEhgEQEQoP
CgUEBgIACBIGhgESiwEDChAKCAQGAgAInAgAEgSHAQQqChEKBwQGAgAInwgSBogBBIoBBQpQ
CgIEBxIGjwEAlwEBGkIgVmVyaWZ5S21zQ29uZmlnUmVxdWVzdCBzcGVjaWZpZXMgdGhlIEtN
UyBjb25maWcgdG8gYmUgdmFsaWRhdGVkLgoKCwoDBAcBEgSPAQgeCkIKBAQHAgASBpEBApYB
BBoyIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBLTVMgQ29uZmlnIHRvIGJlIHZlcmlmaWVkLgoK
DQoFBAcCAAUSBJEBAggKDQoFBAcCAAESBJEBCQ0KDQoFBAcCAAMSBJEBEBEKDwoFBAcCAAgS
BpEBEpYBAwoQCggEBwIACJwIABIEkgEEKgoRCgcEBwIACJ8IEgaTAQSVAQUKbwoCBAgSBpsB
AKYBARphIFZlcmlmeUttc0NvbmZpZ1Jlc3BvbnNlIGNvbnRhaW5zIHRoZSBpbmZvcm1hdGlv
biBpZiB0aGUgY29uZmlnIGlzIGNvcnJlY3RseQogYW5kIGVycm9yIG1lc3NhZ2UuCgoLCgME
CAESBJsBCB8KXQoEBAgCABIEngECPxpPIE91dHB1dCBvbmx5LiBJZiB0aGUgY3VzdG9tZXIg
a2V5IGNvbmZpZ3VyZWQgY29ycmVjdGx5IHRvIHRoZSBlbmNyeXB0CiB2b2x1bWUuCgoNCgUE
CAIABRIEngECBgoNCgUECAIAARIEngEHDgoNCgUECAIAAxIEngEREgoNCgUECAIACBIEngET
PgoQCggECAIACJwIABIEngEUPQpECgQECAIBEgShAQJGGjYgT3V0cHV0IG9ubHkuIEVycm9y
IG1lc3NhZ2UgaWYgY29uZmlnIGlzIG5vdCBoZWFsdGh5LgoKDQoFBAgCAQUSBKEBAggKDQoF
BAgCAQESBKEBCRUKDQoFBAgCAQMSBKEBGBkKDQoFBAgCAQgSBKEBGkUKEAoIBAgCAQicCAAS
BKEBG0QKaQoEBAgCAhIEpQECRhpbIE91dHB1dCBvbmx5LiBJbnN0cnVjdGlvbnMgZm9yIHRo
ZSBjdXN0b21lcnMgdG8gcHJvdmlkZSB0aGUgYWNjZXNzIHRvIHRoZQogZW5jcnlwdGlvbiBr
ZXkuCgoNCgUECAICBRIEpQECCAoNCgUECAICARIEpQEJFQoNCgUECAICAxIEpQEYGQoNCgUE
CAICCBIEpQEaRQoQCggECAICCJwIABIEpQEbRApVCgIECRIGqQEA/gEBGkcgS21zQ29uZmln
IGlzIHRoZSBjdXN0b21lci1tYW5hZ2VkIGVuY3J5cHRpb24ga2V5KENNRUspIGNvbmZpZ3Vy
YXRpb24uCgoLCgMECQESBKkBCBEKDQoDBAkHEgaqAQKvAQQKDwoFBAkHnQgSBqoBAq8BBAom
CgQECQQAEgayAQLYAQMaFiBUaGUgS21zQ29uZmlnIFN0YXRlcwoKDQoFBAkEAAESBLIBBwwK
LQoGBAkEAAIAEgS0AQQaGh0gVW5zcGVjaWZpZWQgS21zQ29uZmlnIFN0YXRlCgoPCgcECQQA
AgABEgS0AQQVCg8KBwQJBAACAAISBLQBGBkKKgoGBAkEAAIBEgS3AQQOGhogS21zQ29uZmln
IFN0YXRlIGlzIFJlYWR5CgoPCgcECQQAAgEBEgS3AQQJCg8KBwQJBAACAQISBLcBDA0KLQoG
BAkEAAICEgS6AQQRGh0gS21zQ29uZmlnIFN0YXRlIGlzIENyZWF0aW5nCgoPCgcECQQAAgIB
EgS6AQQMCg8KBwQJBAACAgISBLoBDxAKLQoGBAkEAAIDEgS9AQQRGh0gS21zQ29uZmlnIFN0
YXRlIGlzIERlbGV0aW5nCgoPCgcECQQAAgMBEgS9AQQMCg8KBwQJBAACAwISBL0BDxAKLQoG
BAkEAAIEEgTAAQQRGh0gS21zQ29uZmlnIFN0YXRlIGlzIFVwZGF0aW5nCgoPCgcECQQAAgQB
EgTAAQQMCg8KBwQJBAACBAISBMABDxAKLAoGBAkEAAIFEgTDAQQPGhwgS21zQ29uZmlnIFN0
YXRlIGlzIEluIFVzZS4KCg8KBwQJBAACBQESBMMBBAoKDwoHBAkEAAIFAhIEwwENDgoqCgYE
CQQAAgYSBMYBBA4aGiBLbXNDb25maWcgU3RhdGUgaXMgRXJyb3IKCg8KBwQJBAACBgESBMYB
BAkKDwoHBAkEAAIGAhIExgEMDQpJCgYECQQAAgcSBMkBBBoaOSBLbXNDb25maWcgU3RhdGUg
aXMgUGVuZGluZyB0byB2ZXJpZnkgY3J5cHRvIGtleSBhY2Nlc3MuCgoPCgcECQQAAgcBEgTJ
AQQVCg8KBwQJBAACBwISBMkBGBkKYgoGBAkEAAIIEgTNAQQaGlIgS21zQ29uZmlnIFN0YXRl
IGlzIE5vdCBhY2Nlc3NiaWxlIGJ5IHRoZSBTREUgc2VydmljZSBhY2NvdW50IHRvIHRoZQog
Y3J5cHRvIGtleS4KCg8KBwQJBAACCAESBM0BBBUKDwoHBAkEAAIIAhIEzQEYGQovCgYECQQA
AgkSBNABBBIaHyBLbXNDb25maWcgU3RhdGUgaXMgRGlzYWJsaW5nLgoKDwoHBAkEAAIJARIE
0AEEDQoPCgcECQQAAgkCEgTQARARCi4KBgQJBAACChIE0wEEEhoeIEttc0NvbmZpZyBTdGF0
ZSBpcyBEaXNhYmxlZC4KCg8KBwQJBAACCgESBNMBBAwKDwoHBAkEAAIKAhIE0wEPEQpmCgYE
CQQAAgsSBNcBBBMaViBLbXNDb25maWcgU3RhdGUgaXMgTWlncmF0aW5nLgogVGhlIGV4aXN0
aW5nIHZvbHVtZXMgYXJlIG1pZ3JhdGluZyBmcm9tIFNNRUsgdG8gQ01FSy4KCg8KBwQJBAAC
CwESBNcBBA0KDwoHBAkEAAILAhIE1wEQEgp/CgQECQIAEgTcAQI9GnEgSWRlbnRpZmllci4g
TmFtZSBvZiB0aGUgYEttc0NvbmZpZ2AuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0va21zQ29uZmlncy97a21zX2NvbmZpZ31gCgoNCgUECQIA
BRIE3AECCAoNCgUECQIAARIE3AEJDQoNCgUECQIAAxIE3AEQEQoNCgUECQIACBIE3AESPAoQ
CggECQIACJwIABIE3AETOwqrAQoEBAkCARIG4AEC5QEEGpoBIFJlcXVpcmVkLiBDdXN0b21l
ci1tYW5hZ2VkIGNyeXB0byBrZXkgcmVzb3VyY2UgZnVsbCBuYW1lLiBGb3JtYXQ6CiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlfcmlu
Z30vY3J5cHRvS2V5cy97Y3J5cHRvX2tleX1gCgoNCgUECQIBBRIE4AECCAoNCgUECQIBARIE
4AEJGAoNCgUECQIBAxIE4AEbHAoPCgUECQIBCBIG4AEd5QEDChAKCAQJAgEInAgAEgThAQQq
ChEKBwQJAgEInwgSBuIBBOQBBQo0CgQECQICEgToAQI+GiYgT3V0cHV0IG9ubHkuIFN0YXRl
IG9mIHRoZSBLbXNDb25maWcuCgoNCgUECQICBhIE6AECBwoNCgUECQICARIE6AEIDQoNCgUE
CQICAxIE6AEQEQoNCgUECQICCBIE6AESPQoQCggECQICCJwIABIE6AETPAo8CgQECQIDEgTr
AQJHGi4gT3V0cHV0IG9ubHkuIFN0YXRlIGRldGFpbHMgb2YgdGhlIEttc0NvbmZpZy4KCg0K
BQQJAgMFEgTrAQIICg0KBQQJAgMBEgTrAQkWCg0KBQQJAgMDEgTrARkaCg0KBQQJAgMIEgTr
ARtGChAKCAQJAgMInAgAEgTrARxFCjwKBAQJAgQSBu4BAu8BMhosIE91dHB1dCBvbmx5LiBD
cmVhdGUgdGltZSBvZiB0aGUgS21zQ29uZmlnLgoKDQoFBAkCBAYSBO4BAhsKDQoFBAkCBAES
BO4BHCcKDQoFBAkCBAMSBO4BKisKDQoFBAkCBAgSBO8BBjEKEAoIBAkCBAicCAASBO8BBzAK
LQoEBAkCBRIE8gECGRofIERlc2NyaXB0aW9uIG9mIHRoZSBLbXNDb25maWcuCgoNCgUECQIF
BRIE8gECCAoNCgUECQIFARIE8gEJFAoNCgUECQIFAxIE8gEXGAopCgQECQIGEgT1AQIhGhsg
TGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycwoKDQoFBAkCBgYSBPUBAhUKDQoFBAkCBgESBPUB
FhwKDQoFBAkCBgMSBPUBHyAKaQoEBAkCBxIE+QECRhpbIE91dHB1dCBvbmx5LiBJbnN0cnVj
dGlvbnMgdG8gcHJvdmlkZSB0aGUgYWNjZXNzIHRvIHRoZSBjdXN0b21lciBwcm92aWRlZAog
ZW5jcnlwdGlvbiBrZXkuCgoNCgUECQIHBRIE+QECCAoNCgUECQIHARIE+QEJFQoNCgUECQIH
AxIE+QEYGQoNCgUECQIHCBIE+QEaRQoQCggECQIHCJwIABIE+QEbRApxCgQECQIIEgT9AQJJ
GmMgT3V0cHV0IG9ubHkuIFRoZSBTZXJ2aWNlIGFjY291bnQgd2hpY2ggd2lsbCBoYXZlIGFj
Y2VzcyB0byB0aGUgY3VzdG9tZXIKIHByb3ZpZGVkIGVuY3J5cHRpb24ga2V5LgoKDQoFBAkC
CAUSBP0BAggKDQoFBAkCCAESBP0BCRgKDQoFBAkCCAMSBP0BGxwKDQoFBAkCCAgSBP0BHUgK
EAoIBAkCCAicCAASBP0BHkdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest ===
    # Fields for GetKmsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::ListKmsConfigsRequest ===
    # Fields for ListKmsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::ListKmsConfigsResponse ===
    # Fields for ListKmsConfigsResponse
    # Field: kms_configs Type: 11 (.google.cloud.netapp.v1.KmsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::CreateKmsConfigRequest ===
    # Fields for CreateKmsConfigRequest
    # Field: parent Type: 9 ()
    # Field: kms_config_id Type: 9 ()
    # Field: kms_config Type: 11 (.google.cloud.netapp.v1.KmsConfig)

# === Message: Google::Cloud::Netapp::V1::Kms::UpdateKmsConfigRequest ===
    # Fields for UpdateKmsConfigRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: kms_config Type: 11 (.google.cloud.netapp.v1.KmsConfig)

# === Message: Google::Cloud::Netapp::V1::Kms::DeleteKmsConfigRequest ===
    # Fields for DeleteKmsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::EncryptVolumesRequest ===
    # Fields for EncryptVolumesRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigRequest ===
    # Fields for VerifyKmsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigResponse ===
    # Fields for VerifyKmsConfigResponse
    # Field: healthy Type: 8 ()
    # Field: health_error Type: 9 ()
    # Field: instructions Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Kms::KmsConfig ===
    # Fields for KmsConfig
    # Field: name Type: 9 ()
    # Field: crypto_key_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.KmsConfig.State)
    # Field: state_details Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.KmsConfig.LabelsEntry)
    # Field: instructions Type: 9 ()
    # Field: service_account Type: 9 ()

# Enum: KmsConfig::State
our $KmsConfig_STATE_UNSPECIFIED = 0;
our $KmsConfig_READY = 1;
our $KmsConfig_CREATING = 2;
our $KmsConfig_DELETING = 3;
our $KmsConfig_UPDATING = 4;
our $KmsConfig_IN_USE = 5;
our $KmsConfig_ERROR = 6;
our $KmsConfig_KEY_CHECK_PENDING = 7;
our $KmsConfig_KEY_NOT_REACHABLE = 8;
our $KmsConfig_DISABLING = 9;
our $KmsConfig_DISABLED = 10;
our $KmsConfig_MIGRATING = 11;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::Kms - Compiled Protocol Buffers messages for google/cloud/netapp/v1/kms.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::Kms;

    my $msg = Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/kms.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest

GetKmsConfigRequest gets a KMS Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the KmsConfig

=back

=head2 Google::Cloud::Netapp::V1::Kms::ListKmsConfigsRequest

ListKmsConfigsRequest lists KMS Configs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value to use if there are additional
results to retrieve for this list request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort results. Supported values are "name", "name desc" or "" (unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Netapp::V1::Kms::ListKmsConfigsResponse

ListKmsConfigsResponse is the response to a ListKmsConfigsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kms_configs() >> / C<< $msg->kms_configs($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Kms::KmsConfig>)

The list of KmsConfigs

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::Kms::CreateKmsConfigRequest

CreateKmsConfigRequest creates a KMS Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->kms_config_id() >> / C<< $msg->kms_config_id($value) >>

Type: C<String>

Required. Id of the requesting KmsConfig. Must be unique within the parent
resource. Must contain only letters, numbers and hyphen, with the first
character a letter, the last a letter or a
number, and a 63 character maximum.

=item * C<< $msg->kms_config() >> / C<< $msg->kms_config($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Kms::KmsConfig>)

Required. The required parameters to create a new KmsConfig.

=back

=head2 Google::Cloud::Netapp::V1::Kms::UpdateKmsConfigRequest

UpdateKmsConfigRequest updates a KMS Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
KmsConfig resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->kms_config() >> / C<< $msg->kms_config($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Kms::KmsConfig>)

Required. The KmsConfig being updated

=back

=head2 Google::Cloud::Netapp::V1::Kms::DeleteKmsConfigRequest

DeleteKmsConfigRequest deletes a KMS Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the KmsConfig.

=back

=head2 Google::Cloud::Netapp::V1::Kms::EncryptVolumesRequest

EncryptVolumesRequest specifies the KMS config to encrypt existing volumes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the KmsConfig.

=back

=head2 Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigRequest

VerifyKmsConfigRequest specifies the KMS config to be validated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the KMS Config to be verified.

=back

=head2 Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigResponse

VerifyKmsConfigResponse contains the information if the config is correctly
and error message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->healthy() >> / C<< $msg->healthy($value) >>

Type: C<Bool>

Output only. If the customer key configured correctly to the encrypt
volume.

=item * C<< $msg->health_error() >> / C<< $msg->health_error($value) >>

Type: C<String>

Output only. Error message if config is not healthy.

=item * C<< $msg->instructions() >> / C<< $msg->instructions($value) >>

Type: C<String>

Output only. Instructions for the customers to provide the access to the
encryption key.

=back

=head2 Google::Cloud::Netapp::V1::Kms::KmsConfig

KmsConfig is the customer-managed encryption key(CMEK) configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the `KmsConfig`.
Format: `projects/{project}/locations/{location}/kmsConfigs/{kms_config}`

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Required. Customer-managed crypto key resource full name. Format:
`projects/{project}/locations/{location}/keyRings/{key_ring}/cryptoKeys/{crypto_key}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::KmsConfig::State>)

Output only. State of the KmsConfig.

=item * C<< $msg->state_details() >> / C<< $msg->state_details($value) >>

Type: C<String>

Output only. State details of the KmsConfig.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the KmsConfig.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the KmsConfig.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Kms::KmsConfig::LabelsEntry>)

Labels as key value pairs

=item * C<< $msg->instructions() >> / C<< $msg->instructions($value) >>

Type: C<String>

Output only. Instructions to provide the access to the customer provided
encryption key.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Output only. The Service account which will have access to the customer
provided encryption key.

=back

=head3 Enum: KmsConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<READY> => C<1>

=item * C<CREATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<IN_USE> => C<5>

=item * C<ERROR> => C<6>

=item * C<KEY_CHECK_PENDING> => C<7>

=item * C<KEY_NOT_REACHABLE> => C<8>

=item * C<DISABLING> => C<9>

=item * C<DISABLED> => C<10>

=item * C<MIGRATING> => C<11>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::Kms::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
