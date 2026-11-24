package Google::Cloud::Gkehub::V1::Membership;

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
Cidnb29nbGUvY2xvdWQvZ2tlaHViL3YxL21lbWJlcnNoaXAucHJvdG8SFmdvb2dsZS5jbG91
ZC5na2VodWIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i2wcK
Ck1lbWJlcnNoaXASTQoIZW5kcG9pbnQYBCABKAsyKi5nb29nbGUuY2xvdWQuZ2tlaHViLnYx
Lk1lbWJlcnNoaXBFbmRwb2ludEID4EEBSABSCGVuZHBvaW50EhcKBG5hbWUYASABKAlCA+BB
A1IEbmFtZRJLCgZsYWJlbHMYAiADKAsyLi5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLk1lbWJl
cnNoaXAuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPg
QQNSC2Rlc2NyaXB0aW9uEkIKBXN0YXRlGAUgASgLMicuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52
MS5NZW1iZXJzaGlwU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
QAoLZGVsZXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmRlbGV0ZVRpbWUSJAoLZXh0ZXJuYWxfaWQYCSABKAlCA+BBAVIKZXh0ZXJuYWxJZBJRChRs
YXN0X2Nvbm5lY3Rpb25fdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1ISbGFzdENvbm5lY3Rpb25UaW1lEiAKCXVuaXF1ZV9pZBgLIAEoCUID4EEDUgh1bmlx
dWVJZBJECglhdXRob3JpdHkYDCABKAsyIS5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLkF1dGhv
cml0eUID4EEBUglhdXRob3JpdHkSWgoRbW9uaXRvcmluZ19jb25maWcYDiABKAsyKC5nb29n
bGUuY2xvdWQuZ2tlaHViLnYxLk1vbml0b3JpbmdDb25maWdCA+BBAVIQbW9uaXRvcmluZ0Nv
bmZpZxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBOmfqQWQKIGdrZWh1Yi5nb29nbGVhcGlzLmNvbS9NZW1iZXJzaGlwEkBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbWVtYmVyc2hpcHMve21lbWJl
cnNoaXB9QgYKBHR5cGUizgIKEk1lbWJlcnNoaXBFbmRwb2ludBJICgtna2VfY2x1c3RlchgB
IAEoCzIiLmdvb2dsZS5jbG91ZC5na2VodWIudjEuR2tlQ2x1c3RlckID4EEBUgpna2VDbHVz
dGVyEmAKE2t1YmVybmV0ZXNfbWV0YWRhdGEYAiABKAsyKi5nb29nbGUuY2xvdWQuZ2tlaHVi
LnYxLkt1YmVybmV0ZXNNZXRhZGF0YUID4EEDUhJrdWJlcm5ldGVzTWV0YWRhdGESYAoTa3Vi
ZXJuZXRlc19yZXNvdXJjZRgDIAEoCzIqLmdvb2dsZS5jbG91ZC5na2VodWIudjEuS3ViZXJu
ZXRlc1Jlc291cmNlQgPgQQFSEmt1YmVybmV0ZXNSZXNvdXJjZRIqCg5nb29nbGVfbWFuYWdl
ZBgIIAEoCEID4EEDUg1nb29nbGVNYW5hZ2VkIuYCChJLdWJlcm5ldGVzUmVzb3VyY2USOQoW
bWVtYmVyc2hpcF9jcl9tYW5pZmVzdBgBIAEoCUID4EEEUhRtZW1iZXJzaGlwQ3JNYW5pZmVz
dBJgChRtZW1iZXJzaGlwX3Jlc291cmNlcxgCIAMoCzIoLmdvb2dsZS5jbG91ZC5na2VodWIu
djEuUmVzb3VyY2VNYW5pZmVzdEID4EEDUhNtZW1iZXJzaGlwUmVzb3VyY2VzEloKEWNvbm5l
Y3RfcmVzb3VyY2VzGAMgAygLMiguZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MS5SZXNvdXJjZU1h
bmlmZXN0QgPgQQNSEGNvbm5lY3RSZXNvdXJjZXMSVwoQcmVzb3VyY2Vfb3B0aW9ucxgEIAEo
CzInLmdvb2dsZS5jbG91ZC5na2VodWIudjEuUmVzb3VyY2VPcHRpb25zQgPgQQFSD3Jlc291
cmNlT3B0aW9ucyK4AQoPUmVzb3VyY2VPcHRpb25zEiwKD2Nvbm5lY3RfdmVyc2lvbhgBIAEo
CUID4EEBUg5jb25uZWN0VmVyc2lvbhIkCgt2MWJldGExX2NyZBgCIAEoCEID4EEBUgp2MWJl
dGExQ3JkEiQKC2s4c192ZXJzaW9uGAMgASgJQgPgQQFSCms4c1ZlcnNpb24SKwoPazhzX2dp
dF92ZXJzaW9uGAQgASgJQgPgQQFSDWs4c0dpdFZlcnNpb24iVQoQUmVzb3VyY2VNYW5pZmVz
dBIaCghtYW5pZmVzdBgBIAEoCVIIbWFuaWZlc3QSJQoOY2x1c3Rlcl9zY29wZWQYAiABKAhS
DWNsdXN0ZXJTY29wZWQiZAoKR2tlQ2x1c3RlchIoCg1yZXNvdXJjZV9saW5rGAEgASgJQgPg
QQVSDHJlc291cmNlTGluaxIsCg9jbHVzdGVyX21pc3NpbmcYAiABKAhCA+BBA1IOY2x1c3Rl
ck1pc3NpbmcitwIKEkt1YmVybmV0ZXNNZXRhZGF0YRJGCh1rdWJlcm5ldGVzX2FwaV9zZXJ2
ZXJfdmVyc2lvbhgBIAEoCUID4EEDUhprdWJlcm5ldGVzQXBpU2VydmVyVmVyc2lvbhItChBu
b2RlX3Byb3ZpZGVyX2lkGAIgASgJQgPgQQNSDm5vZGVQcm92aWRlcklkEiIKCm5vZGVfY291
bnQYAyABKAVCA+BBA1IJbm9kZUNvdW50EiIKCnZjcHVfY291bnQYBCABKAVCA+BBA1IJdmNw
dUNvdW50EiAKCW1lbW9yeV9tYhgFIAEoBUID4EEDUghtZW1vcnlNYhJACgt1cGRhdGVfdGlt
ZRhkIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZSLa
AQoQTW9uaXRvcmluZ0NvbmZpZxIiCgpwcm9qZWN0X2lkGAEgASgJQgPgQQVSCXByb2plY3RJ
ZBIfCghsb2NhdGlvbhgCIAEoCUID4EEFUghsb2NhdGlvbhIdCgdjbHVzdGVyGAMgASgJQgPg
QQVSB2NsdXN0ZXISOgoZa3ViZXJuZXRlc19tZXRyaWNzX3ByZWZpeBgEIAEoCVIXa3ViZXJu
ZXRlc01ldHJpY3NQcmVmaXgSJgoMY2x1c3Rlcl9oYXNoGAUgASgJQgPgQQVSC2NsdXN0ZXJI
YXNoIsEBCg9NZW1iZXJzaGlwU3RhdGUSRQoEY29kZRgBIAEoDjIsLmdvb2dsZS5jbG91ZC5n
a2VodWIudjEuTWVtYmVyc2hpcFN0YXRlLkNvZGVCA+BBA1IEY29kZSJnCgRDb2RlEhQKEENP
REVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgkKBVJFQURZEAISDAoIREVMRVRJTkcQ
AxIMCghVUERBVElORxAEEhQKEFNFUlZJQ0VfVVBEQVRJTkcQBSK3AQoJQXV0aG9yaXR5EhsK
Bmlzc3VlchgBIAEoCUID4EEBUgZpc3N1ZXISOQoWd29ya2xvYWRfaWRlbnRpdHlfcG9vbBgC
IAEoCUID4EEDUhR3b3JrbG9hZElkZW50aXR5UG9vbBIwChFpZGVudGl0eV9wcm92aWRlchgD
IAEoCUID4EEDUhBpZGVudGl0eVByb3ZpZGVyEiAKCW9pZGNfandrcxgEIAEoDEID4EEBUghv
aWRjSndrc0KxAQoaY29tLmdvb2dsZS5jbG91ZC5na2VodWIudjFCD01lbWJlcnNoaXBQcm90
b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2drZWh1Yi9hcGl2MS9na2VodWJwYjtna2VodWJw
YqoCFkdvb2dsZS5DbG91ZC5Ha2VIdWIuVjHKAhZHb29nbGVcQ2xvdWRcR2tlSHViXFYx6gIZ
R29vZ2xlOjpDbG91ZDo6R2tlSHViOjpWMUqneAoHEgUOAOACAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQAKQoICgEIEgMWADMKCQoCCCUSAxYAMwoICgEIEgMXAEkKCQoCCAsSAxcASQoICgEI
EgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoCCAgSAxkAMAoICgEIEgMaADMKCQoCCAES
AxoAMwoICgEIEgMbADMKCQoCCCkSAxsAMwoICgEIEgMcADIKCQoCCC0SAxwAMgpFCgIEABIE
HwBvARo5IE1lbWJlcnNoaXAgY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgYSBtZW1iZXIg
Y2x1c3Rlci4KCgoKAwQAARIDHwgSCgsKAwQABxIEIAIjBAoNCgUEAAedCBIEIAIjBAo/CgQE
AAgAEgQmAikDGjEgVHlwZSBvZiByZXNvdXJjZSByZXByZXNlbnRlZCBieSB0aGlzIE1lbWJl
cnNoaXAKCgwKBQQACAABEgMmCAwKQwoEBAACABIDKARNGjYgT3B0aW9uYWwuIEVuZHBvaW50
IGluZm9ybWF0aW9uIHRvIHJlYWNoIHRoaXMgbWVtYmVyLgoKDAoFBAACAAYSAygEFgoMCgUE
AAIAARIDKBcfCgwKBQQAAgADEgMoIiMKDAoFBAACAAgSAygkTAoPCggEAAIACJwIABIDKCVL
Cv8DCgQEAAIBEgM3Aj4a8QMgT3V0cHV0IG9ubHkuIFRoZSBmdWxsLCB1bmlxdWUgbmFtZSBv
ZiB0aGlzIE1lbWJlcnNoaXAgcmVzb3VyY2UgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzLyov
bG9jYXRpb25zLyovbWVtYmVyc2hpcHMve21lbWJlcnNoaXBfaWR9YCwgc2V0IGR1cmluZwog
Y3JlYXRpb24uCgogYG1lbWJlcnNoaXBfaWRgIG11c3QgYmUgYSB2YWxpZCBSRkMgMTEyMyBj
b21wbGlhbnQgRE5TIGxhYmVsOgoKICAgMS4gQXQgbW9zdCA2MyBjaGFyYWN0ZXJzIGluIGxl
bmd0aAogICAyLiBJdCBtdXN0IGNvbnNpc3Qgb2YgbG93ZXIgY2FzZSBhbHBoYW51bWVyaWMg
Y2hhcmFjdGVycyBvciBgLWAKICAgMy4gSXQgbXVzdCBzdGFydCBhbmQgZW5kIHdpdGggYW4g
YWxwaGFudW1lcmljIGNoYXJhY3RlcgoKIFdoaWNoIGNhbiBiZSBleHByZXNzZWQgYXMgdGhl
IHJlZ2V4OiBgW2EtejAtOV0oWy1hLXowLTldKlthLXowLTldKT9gLAogd2l0aCBhIG1heGlt
dW0gbGVuZ3RoIG9mIDYzIGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDNwIICgwKBQQAAgEBEgM3
CQ0KDAoFBAACAQMSAzcQEQoMCgUEAAIBCBIDNxI9Cg8KCAQAAgEInAgAEgM3EzwKNAoEBAAC
AhIDOgJKGicgT3B0aW9uYWwuIExhYmVscyBmb3IgdGhpcyBtZW1iZXJzaGlwLgoKDAoFBAAC
AgYSAzoCFQoMCgUEAAICARIDOhYcCgwKBQQAAgIDEgM6HyAKDAoFBAACAggSAzohSQoPCggE
AAICCJwIABIDOiJICrsBCgQEAAIDEgNAAkUarQEgT3V0cHV0IG9ubHkuIERlc2NyaXB0aW9u
IG9mIHRoaXMgbWVtYmVyc2hpcCwgbGltaXRlZCB0byA2MyBjaGFyYWN0ZXJzLgogTXVzdCBt
YXRjaCB0aGUgcmVnZXg6IGBbYS16QS1aMC05XVthLXpBLVowLTlfXC1cLlwgXSpgCgogVGhp
cyBmaWVsZCBpcyBwcmVzZW50IGZvciBsZWdhY3kgcHVycG9zZXMuCgoMCgUEAAIDBRIDQAII
CgwKBQQAAgMBEgNACRQKDAoFBAACAwMSA0AXGAoMCgUEAAIDCBIDQBlECg8KCAQAAgMInAgA
EgNAGkMKPQoEBAACBBIDQwJIGjAgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBNZW1iZXJz
aGlwIHJlc291cmNlLgoKDAoFBAACBAYSA0MCEQoMCgUEAAIEARIDQxIXCgwKBQQAAgQDEgND
GhsKDAoFBAACBAgSA0McRwoPCggEAAIECJwIABIDQx1GCj0KBAQAAgUSBEYCRzIaLyBPdXRw
dXQgb25seS4gV2hlbiB0aGUgTWVtYmVyc2hpcCB3YXMgY3JlYXRlZC4KCgwKBQQAAgUGEgNG
AhsKDAoFBAACBQESA0YcJwoMCgUEAAIFAxIDRiorCgwKBQQAAgUIEgNHBjEKDwoIBAACBQic
CAASA0cHMApCCgQEAAIGEgRKAksyGjQgT3V0cHV0IG9ubHkuIFdoZW4gdGhlIE1lbWJlcnNo
aXAgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgYGEgNKAhsKDAoFBAACBgESA0ocJwoMCgUE
AAIGAxIDSiorCgwKBQQAAgYIEgNLBjEKDwoIBAACBgicCAASA0sHMAo9CgQEAAIHEgROAk8y
Gi8gT3V0cHV0IG9ubHkuIFdoZW4gdGhlIE1lbWJlcnNoaXAgd2FzIGRlbGV0ZWQuCgoMCgUE
AAIHBhIDTgIbCgwKBQQAAgcBEgNOHCcKDAoFBAACBwMSA04qKwoMCgUEAAIHCBIDTwYxCg8K
CAQAAgcInAgAEgNPBzAK2wIKBAQAAggSA1gCQhrNAiBPcHRpb25hbC4gQW4gZXh0ZXJuYWxs
eS1nZW5lcmF0ZWQgYW5kIG1hbmFnZWQgSUQgZm9yIHRoaXMgTWVtYmVyc2hpcC4gVGhpcwog
SUQgbWF5IGJlIG1vZGlmaWVkIGFmdGVyIGNyZWF0aW9uLCBidXQgdGhpcyBpcyBub3QgcmVj
b21tZW5kZWQuCgogVGhlIElEIG11c3QgbWF0Y2ggdGhlIHJlZ2V4OiBgW2EtekEtWjAtOV1b
YS16QS1aMC05X1wtXC5dKmAKCiBJZiB0aGlzIE1lbWJlcnNoaXAgcmVwcmVzZW50cyBhIEt1
YmVybmV0ZXMgY2x1c3RlciwgdGhpcyB2YWx1ZSBzaG91bGQgYmUKIHNldCB0byB0aGUgVUlE
IG9mIHRoZSBga3ViZS1zeXN0ZW1gIG5hbWVzcGFjZSBvYmplY3QuCgoMCgUEAAIIBRIDWAII
CgwKBQQAAggBEgNYCRQKDAoFBAACCAMSA1gXGAoMCgUEAAIICBIDWBlBCg8KCAQAAggInAgA
EgNYGkAKtQIKBAQAAgkSBF8CYDIapgIgT3V0cHV0IG9ubHkuIEZvciBjbHVzdGVycyB1c2lu
ZyBDb25uZWN0LCB0aGUgdGltZXN0YW1wIG9mIHRoZSBtb3N0IHJlY2VudAogY29ubmVjdGlv
biBlc3RhYmxpc2hlZCB3aXRoIEdvb2dsZSBDbG91ZC4gVGhpcyB0aW1lIGlzIHVwZGF0ZWQg
ZXZlcnkKIHNldmVyYWwgbWludXRlcywgbm90IGNvbnRpbnVvdXNseS4gRm9yIGNsdXN0ZXJz
IHRoYXQgZG8gbm90IHVzZSBHS0UKIENvbm5lY3QsIG9yIHRoYXQgaGF2ZSBuZXZlciBjb25u
ZWN0ZWQgc3VjY2Vzc2Z1bGx5LCB0aGlzIGZpZWxkIHdpbGwgYmUKIHVuc2V0LgoKDAoFBAAC
CQYSA18CGwoMCgUEAAIJARIDXxwwCgwKBQQAAgkDEgNfMzUKDAoFBAACCQgSA2AGMQoPCggE
AAIJCJwIABIDYAcwCu4BCgQEAAIKEgNlAkQa4AEgT3V0cHV0IG9ubHkuIEdvb2dsZS1nZW5l
cmF0ZWQgVVVJRCBmb3IgdGhpcyByZXNvdXJjZS4gVGhpcyBpcyB1bmlxdWUgYWNyb3NzCiBh
bGwgTWVtYmVyc2hpcCByZXNvdXJjZXMuIElmIGEgTWVtYmVyc2hpcCByZXNvdXJjZSBpcyBk
ZWxldGVkIGFuZCBhbm90aGVyCiByZXNvdXJjZSB3aXRoIHRoZSBzYW1lIG5hbWUgaXMgY3Jl
YXRlZCwgaXQgZ2V0cyBhIGRpZmZlcmVudCB1bmlxdWVfaWQuCgoMCgUEAAIKBRIDZQIICgwK
BQQAAgoBEgNlCRIKDAoFBAACCgMSA2UVFwoMCgUEAAIKCBIDZRhDCg8KCAQAAgoInAgAEgNl
GUIK0QEKBAQAAgsSA2oCRBrDASBPcHRpb25hbC4gSG93IHRvIGlkZW50aWZ5IHdvcmtsb2Fk
cyBmcm9tIHRoaXMgTWVtYmVyc2hpcC4KIFNlZSB0aGUgZG9jdW1lbnRhdGlvbiBvbiBXb3Jr
bG9hZCBJZGVudGl0eSBmb3IgbW9yZSBkZXRhaWxzOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2t1YmVybmV0ZXMtZW5naW5lL2RvY3MvaG93LXRvL3dvcmtsb2FkLWlkZW50aXR5CgoM
CgUEAAILBhIDagILCgwKBQQAAgsBEgNqDBUKDAoFBAACCwMSA2oYGgoMCgUEAAILCBIDahtD
Cg8KCAQAAgsInAgAEgNqHEIKUAoEBAACDBIEbQJuLxpCIE9wdGlvbmFsLiBUaGUgbW9uaXRv
cmluZyBjb25maWcgaW5mb3JtYXRpb24gZm9yIHRoaXMgbWVtYmVyc2hpcC4KCgwKBQQAAgwG
EgNtAhIKDAoFBAACDAESA20TJAoMCgUEAAIMAxIDbScpCgwKBQQAAgwIEgNuBi4KDwoIBAAC
DAicCAASA24HLQqMAQoCBAESBXMAiQEBGn8gTWVtYmVyc2hpcEVuZHBvaW50IGNvbnRhaW5z
IGluZm9ybWF0aW9uIG5lZWRlZCB0byBjb250YWN0IGEgS3ViZXJuZXRlcyBBUEksCiBlbmRw
b2ludCBhbmQgYW55IGFkZGl0aW9uYWwgS3ViZXJuZXRlcyBtZXRhZGF0YS4KCgoKAwQBARID
cwgaCmQKBAQBAgASA3UESBpXIE9wdGlvbmFsLiBHS0Utc3BlY2lmaWMgaW5mb3JtYXRpb24u
IE9ubHkgcHJlc2VudCBpZiB0aGlzIE1lbWJlcnNoaXAgaXMgYSBHS0UgY2x1c3Rlci4KCgwK
BQQBAgAGEgN1BA4KDAoFBAECAAESA3UPGgoMCgUEAQIAAxIDdR0eCgwKBQQBAgAIEgN1H0cK
DwoIBAECAAicCAASA3UgRgpBCgQEAQIBEgR4AnkyGjMgT3V0cHV0IG9ubHkuIFVzZWZ1bCBL
dWJlcm5ldGVzLXNwZWNpZmljIG1ldGFkYXRhLgoKDAoFBAECAQYSA3gCFAoMCgUEAQIBARID
eBUoCgwKBQQBAgEDEgN4KywKDAoFBAECAQgSA3kGMQoPCggEAQIBCJwIABIDeQcwCqADCgQE
AQICEgaDAQKEAS8ajwMgT3B0aW9uYWwuIFRoZSBpbi1jbHVzdGVyIEt1YmVybmV0ZXMgUmVz
b3VyY2VzIHRoYXQgc2hvdWxkIGJlIGFwcGxpZWQgZm9yIGEKIGNvcnJlY3RseSByZWdpc3Rl
cmVkIGNsdXN0ZXIsIGluIHRoZSBzdGVhZHkgc3RhdGUuIFRoZXNlIHJlc291cmNlczoKCiAg
ICogRW5zdXJlIHRoYXQgdGhlIGNsdXN0ZXIgaXMgZXhjbHVzaXZlbHkgcmVnaXN0ZXJlZCB0
byBvbmUgYW5kIG9ubHkgb25lCiAgICAgSHViIE1lbWJlcnNoaXAuCiAgICogUHJvcGFnYXRl
IFdvcmtsb2FkIFBvb2wgSW5mb3JtYXRpb24gYXZhaWxhYmxlIGluIHRoZSBNZW1iZXJzaGlw
CiAgICAgQXV0aG9yaXR5IGZpZWxkLgogICAqIEVuc3VyZSBwcm9wZXIgaW5pdGlhbCBjb25m
aWd1cmF0aW9uIG9mIGRlZmF1bHQgSHViIEZlYXR1cmVzLgoKDQoFBAECAgYSBIMBAhQKDQoF
BAECAgESBIMBFSgKDQoFBAECAgMSBIMBKywKDQoFBAECAggSBIQBBi4KEAoIBAECAgicCAAS
BIQBBy0KdwoEBAECAxIEiAECRhppIE91dHB1dCBvbmx5LiBXaGV0aGVyIHRoZSBsaWZlY3lj
bGUgb2YgdGhpcyBtZW1iZXJzaGlwIGlzIG1hbmFnZWQgYnkgYQogZ29vZ2xlIGNsdXN0ZXIg
cGxhdGZvcm0gc2VydmljZS4KCg0KBQQBAgMFEgSIAQIGCg0KBQQBAgMBEgSIAQcVCg0KBQQB
AgMDEgSIARgZCg0KBQQBAgMIEgSIARpFChAKCAQBAgMInAgAEgSIARtECugBCgIEAhIGjgEA
rwEBGtkBIEt1YmVybmV0ZXNSZXNvdXJjZSBjb250YWlucyB0aGUgWUFNTCBtYW5pZmVzdHMg
YW5kIGNvbmZpZ3VyYXRpb24gZm9yCiBNZW1iZXJzaGlwIEt1YmVybmV0ZXMgcmVzb3VyY2Vz
IGluIHRoZSBjbHVzdGVyLiBBZnRlciBDcmVhdGVNZW1iZXJzaGlwIG9yCiBVcGRhdGVNZW1i
ZXJzaGlwLCB0aGVzZSByZXNvdXJjZXMgc2hvdWxkIGJlIHJlLWFwcGxpZWQgaW4gdGhlIGNs
dXN0ZXIuCgoLCgMEAgESBI4BCBoKmgMKBAQCAgASBJYBAk8aiwMgSW5wdXQgb25seS4gVGhl
IFlBTUwgcmVwcmVzZW50YXRpb24gb2YgdGhlIE1lbWJlcnNoaXAgQ1IuIFRoaXMgZmllbGQg
aXMKIGlnbm9yZWQgZm9yIEdLRSBjbHVzdGVycyB3aGVyZSBIdWIgY2FuIHJlYWQgdGhlIENS
IGRpcmVjdGx5LgoKIENhbGxlcnMgc2hvdWxkIHByb3ZpZGUgdGhlIENSIHRoYXQgaXMgY3Vy
cmVudGx5IHByZXNlbnQgaW4gdGhlIGNsdXN0ZXIKIGR1cmluZyBDcmVhdGVNZW1iZXJzaGlw
IG9yIFVwZGF0ZU1lbWJlcnNoaXAsIG9yIGxlYXZlIHRoaXMgZmllbGQgZW1wdHkgaWYKIG5v
bmUgZXhpc3RzLiBUaGUgQ1IgbWFuaWZlc3QgaXMgdXNlZCB0byB2YWxpZGF0ZSB0aGUgY2x1
c3RlciBoYXMgbm90IGJlZW4KIHJlZ2lzdGVyZWQgd2l0aCBhbm90aGVyIE1lbWJlcnNoaXAu
CgoNCgUEAgIABRIElgECCAoNCgUEAgIAARIElgEJHwoNCgUEAgIAAxIElgEiIwoNCgUEAgIA
CBIElgEkTgoQCggEAgIACJwIABIElgElTQr/AwoEBAICARIGoAECoQEyGu4DIE91dHB1dCBv
bmx5LiBBZGRpdGlvbmFsIEt1YmVybmV0ZXMgcmVzb3VyY2VzIHRoYXQgbmVlZCB0byBiZSBh
cHBsaWVkIHRvIHRoZQogY2x1c3RlciBhZnRlciBNZW1iZXJzaGlwIGNyZWF0aW9uLCBhbmQg
YWZ0ZXIgZXZlcnkgdXBkYXRlLgoKIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgaW4g
dGhlIE1lbWJlcnNoaXAgcmV0dXJuZWQgZnJvbSBhIHN1Y2Nlc3NmdWwKIGxvbmctcnVubmlu
ZyBvcGVyYXRpb24gZnJvbSBDcmVhdGVNZW1iZXJzaGlwIG9yIFVwZGF0ZU1lbWJlcnNoaXAu
IEl0IGlzIG5vdAogcG9wdWxhdGVkIGR1cmluZyBub3JtYWwgR2V0TWVtYmVyc2hpcCBvciBM
aXN0TWVtYmVyc2hpcHMgcmVxdWVzdHMuIFRvIGdldAogdGhlIHJlc291cmNlIG1hbmlmZXN0
IGFmdGVyIHRoZSBpbml0aWFsIHJlZ2lzdHJhdGlvbiwgdGhlIGNhbGxlciBzaG91bGQKIG1h
a2UgYSBVcGRhdGVNZW1iZXJzaGlwIGNhbGwgd2l0aCBhbiBlbXB0eSBmaWVsZCBtYXNrLgoK
DQoFBAICAQQSBKABAgoKDQoFBAICAQYSBKABCxsKDQoFBAICAQESBKABHDAKDQoFBAICAQMS
BKABMzQKDQoFBAICAQgSBKEBBjEKEAoIBAICAQicCAASBKEBBzAKwgMKBAQCAgISBqoBAqsB
MhqxAyBPdXRwdXQgb25seS4gVGhlIEt1YmVybmV0ZXMgcmVzb3VyY2VzIGZvciBpbnN0YWxs
aW5nIHRoZSBHS0UgQ29ubmVjdCBhZ2VudAoKIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0
ZWQgaW4gdGhlIE1lbWJlcnNoaXAgcmV0dXJuZWQgZnJvbSBhIHN1Y2Nlc3NmdWwKIGxvbmct
cnVubmluZyBvcGVyYXRpb24gZnJvbSBDcmVhdGVNZW1iZXJzaGlwIG9yIFVwZGF0ZU1lbWJl
cnNoaXAuIEl0IGlzIG5vdAogcG9wdWxhdGVkIGR1cmluZyBub3JtYWwgR2V0TWVtYmVyc2hp
cCBvciBMaXN0TWVtYmVyc2hpcHMgcmVxdWVzdHMuIFRvIGdldAogdGhlIHJlc291cmNlIG1h
bmlmZXN0IGFmdGVyIHRoZSBpbml0aWFsIHJlZ2lzdHJhdGlvbiwgdGhlIGNhbGxlciBzaG91
bGQKIG1ha2UgYSBVcGRhdGVNZW1iZXJzaGlwIGNhbGwgd2l0aCBhbiBlbXB0eSBmaWVsZCBt
YXNrLgoKDQoFBAICAgQSBKoBAgoKDQoFBAICAgYSBKoBCxsKDQoFBAICAgESBKoBHC0KDQoF
BAICAgMSBKoBMDEKDQoFBAICAggSBKsBBjEKEAoIBAICAgicCAASBKsBBzAKRQoEBAICAxIE
rgECUBo3IE9wdGlvbmFsLiBPcHRpb25zIGZvciBLdWJlcm5ldGVzIHJlc291cmNlIGdlbmVy
YXRpb24uCgoNCgUEAgIDBhIErgECEQoNCgUEAgIDARIErgESIgoNCgUEAgIDAxIErgElJgoN
CgUEAgIDCBIErgEnTwoQCggEAgIDCJwIABIErgEoTgpVCgIEAxIGsgEAxwEBGkcgUmVzb3Vy
Y2VPcHRpb25zIHJlcHJlc2VudCBvcHRpb25zIGZvciBLdWJlcm5ldGVzIHJlc291cmNlIGdl
bmVyYXRpb24uCgoLCgMEAwESBLIBCBcK1wEKBAQDAgASBLYBAkYayAEgT3B0aW9uYWwuIFRo
ZSBDb25uZWN0IGFnZW50IHZlcnNpb24gdG8gdXNlIGZvciBjb25uZWN0X3Jlc291cmNlcy4g
RGVmYXVsdHMKIHRvIHRoZSBsYXRlc3QgR0tFIENvbm5lY3QgdmVyc2lvbi4gVGhlIHZlcnNp
b24gbXVzdCBiZSBhIGN1cnJlbnRseQogc3VwcG9ydGVkIHZlcnNpb24sIG9ic29sZXRlIHZl
cnNpb25zIHdpbGwgYmUgcmVqZWN0ZWQuCgoNCgUEAwIABRIEtgECCAoNCgUEAwIAARIEtgEJ
GAoNCgUEAwIAAxIEtgEbHAoNCgUEAwIACBIEtgEdRQoQCggEAwIACJwIABIEtgEeRArQAQoE
BAMCARIEvAECQBrBASBPcHRpb25hbC4gVXNlIGBhcGlleHRlbnNpb25zL3YxYmV0YTFgIGlu
c3RlYWQgb2YgYGFwaWV4dGVuc2lvbnMvdjFgIGZvcgogQ3VzdG9tUmVzb3VyY2VEZWZpbml0
aW9uIHJlc291cmNlcy4KIFRoaXMgb3B0aW9uIHNob3VsZCBiZSBzZXQgZm9yIGNsdXN0ZXJz
IHdpdGggS3ViZXJuZXRlcyBhcGlzZXJ2ZXIgdmVyc2lvbnMKIDwxLjE2LgoKDQoFBAMCAQUS
BLwBAgYKDQoFBAMCAQESBLwBBxIKDQoFBAMCAQMSBLwBFRYKDQoFBAMCAQgSBLwBFz8KEAoI
BAMCAQicCAASBLwBGD4K3QEKBAQDAgISBMEBAkIazgEgT3B0aW9uYWwuIE1ham9yIGFuZCBt
aW5vciB2ZXJzaW9uIG9mIHRoZSBLdWJlcm5ldGVzIGNsdXN0ZXIuIFRoaXMgaXMgb25seQog
dXNlZCB0byBkZXRlcm1pbmUgd2hpY2ggdmVyc2lvbiB0byB1c2UgZm9yIHRoZSBDdXN0b21S
ZXNvdXJjZURlZmluaXRpb24KIHJlc291cmNlcywgYGFwaWV4dGVuc2lvbnMvdjFiZXRhMWAg
b3JgYXBpZXh0ZW5zaW9ucy92MWAuCgoNCgUEAwICBRIEwQECCAoNCgUEAwICARIEwQEJFAoN
CgUEAwICAxIEwQEXGAoNCgUEAwICCBIEwQEZQQoQCggEAwICCJwIABIEwQEaQAqsAQoEBAMC
AxIExgECRhqdASBPcHRpb25hbC4gR2l0IHZlcnNpb24gb2YgdGhlIEt1YmVybmV0ZXMgY2x1
c3Rlci4gVGhpcyBpcyBvbmx5IHVzZWQgdG8gZ2F0ZQogdGhlIENvbm5lY3QgQWdlbnQgbWln
cmF0aW9uIHRvIHN2Yy5pZC5nb29nIG9uIEdEQy1TTyAxLjMzLjEwMCBwYXRjaCBhbmQKIGFi
b3ZlLgoKDQoFBAMCAwUSBMYBAggKDQoFBAMCAwESBMYBCRgKDQoFBAMCAwMSBMYBGxwKDQoF
BAMCAwgSBMYBHUUKEAoIBAMCAwicCAASBMYBHkQKZwoCBAQSBssBANUBARpZIFJlc291cmNl
TWFuaWZlc3QgcmVwcmVzZW50cyBhIHNpbmdsZSBLdWJlcm5ldGVzIHJlc291cmNlIHRvIGJl
IGFwcGxpZWQgdG8KIHRoZSBjbHVzdGVyLgoKCwoDBAQBEgTLAQgYCi4KBAQEAgASBM0BAhYa
ICBZQU1MIG1hbmlmZXN0IG9mIHRoZSByZXNvdXJjZS4KCg0KBQQEAgAFEgTNAQIICg0KBQQE
AgABEgTNAQkRCg0KBQQEAgADEgTNARQVCt4BCgQEBAIBEgTUAQIaGs8BIFdoZXRoZXIgdGhl
IHJlc291cmNlIHByb3ZpZGVkIGluIHRoZSBtYW5pZmVzdCBpcyBgY2x1c3Rlcl9zY29wZWRg
LgogSWYgdW5zZXQsIHRoZSBtYW5pZmVzdCBpcyBhc3N1bWVkIHRvIGJlIG5hbWVzcGFjZSBz
Y29wZWQuCgogVGhpcyBmaWVsZCBpcyB1c2VkIGZvciBSRVNUIG1hcHBpbmcgd2hlbiBhcHBs
eWluZyB0aGUgcmVzb3VyY2UgaW4gYQogY2x1c3Rlci4KCg0KBQQEAgEFEgTUAQIGCg0KBQQE
AgEBEgTUAQcVCg0KBQQEAgEDEgTUARgZCkkKAgQFEgbYAQDkAQEaOyBHa2VDbHVzdGVyIGNv
bnRhaW5zIGluZm9ybWF0aW9uIHNwZWNpZmljIHRvIEdLRSBjbHVzdGVycy4KCgsKAwQFARIE
2AEIEgrkAQoEBAUCABIE3wECRRrVASBJbW11dGFibGUuIFNlbGYtbGluayBvZiB0aGUgR29v
Z2xlIENsb3VkIHJlc291cmNlIGZvciB0aGUgR0tFIGNsdXN0ZXIuIEZvcgogZXhhbXBsZToK
CiAvL2NvbnRhaW5lci5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0
aW9ucy91cy13ZXN0MS1hL2NsdXN0ZXJzL215LWNsdXN0ZXIKCiBab25hbCBjbHVzdGVycyBh
cmUgYWxzbyBzdXBwb3J0ZWQuCgoNCgUEBQIABRIE3wECCAoNCgUEBQIAARIE3wEJFgoNCgUE
BQIAAxIE3wEZGgoNCgUEBQIACBIE3wEbRAoQCggEBQIACJwIABIE3wEcQwqHAQoEBAUCARIE
4wECRxp5IE91dHB1dCBvbmx5LiBJZiBjbHVzdGVyX21pc3NpbmcgaXMgc2V0IHRoZW4gaXQg
ZGVub3RlcyB0aGF0IHRoZSBHS0UgY2x1c3Rlcgogbm8gbG9uZ2VyIGV4aXN0cyBpbiB0aGUg
R0tFIENvbnRyb2wgUGxhbmUuCgoNCgUEBQIBBRIE4wECBgoNCgUEBQIBARIE4wEHFgoNCgUE
BQIBAxIE4wEZGgoNCgUEBQIBCBIE4wEbRgoQCggEBQIBCJwIABIE4wEcRQp1CgIEBhIG6AEA
gwIBGmcgS3ViZXJuZXRlc01ldGFkYXRhIHByb3ZpZGVzIGluZm9ybWF0aW9uYWwgbWV0YWRh
dGEgZm9yIE1lbWJlcnNoaXBzCiByZXByZXNlbnRpbmcgS3ViZXJuZXRlcyBjbHVzdGVycy4K
CgsKAwQGARIE6AEIGgpfCgQEBgIAEgbrAQLsATIaTyBPdXRwdXQgb25seS4gS3ViZXJuZXRl
cyBBUEkgc2VydmVyIHZlcnNpb24gc3RyaW5nIGFzIHJlcG9ydGVkIGJ5CiBgL3ZlcnNpb25g
LgoKDQoFBAYCAAUSBOsBAggKDQoFBAYCAAESBOsBCSYKDQoFBAYCAAMSBOsBKSoKDQoFBAYC
AAgSBOwBBjEKEAoIBAYCAAicCAASBOwBBzAKjgIKBAQGAgESBPIBAkoa/wEgT3V0cHV0IG9u
bHkuIE5vZGUgcHJvdmlkZXJJRCBhcyByZXBvcnRlZCBieSB0aGUgZmlyc3Qgbm9kZSBpbiB0
aGUgbGlzdCBvZgogbm9kZXMgb24gdGhlIEt1YmVybmV0ZXMgZW5kcG9pbnQuIE9uIEt1YmVy
bmV0ZXMgcGxhdGZvcm1zIHRoYXQgc3VwcG9ydAogemVyby1ub2RlIGNsdXN0ZXJzIChsaWtl
IEdLRS1vbi1HQ1ApLCB0aGUgbm9kZV9jb3VudCB3aWxsIGJlIHplcm8gYW5kIHRoZQogbm9k
ZV9wcm92aWRlcl9pZCB3aWxsIGJlIGVtcHR5LgoKDQoFBAYCAQUSBPIBAggKDQoFBAYCAQES
BPIBCRkKDQoFBAYCAQMSBPIBHB0KDQoFBAYCAQgSBPIBHkkKEAoIBAYCAQicCAASBPIBH0gK
UgoEBAYCAhIE9QECQxpEIE91dHB1dCBvbmx5LiBOb2RlIGNvdW50IGFzIHJlcG9ydGVkIGJ5
IEt1YmVybmV0ZXMgbm9kZXMgcmVzb3VyY2VzLgoKDQoFBAYCAgUSBPUBAgcKDQoFBAYCAgES
BPUBCBIKDQoFBAYCAgMSBPUBFRYKDQoFBAYCAggSBPUBF0IKEAoIBAYCAgicCAASBPUBGEEK
UgoEBAYCAxIE+AECQxpEIE91dHB1dCBvbmx5LiB2Q1BVIGNvdW50IGFzIHJlcG9ydGVkIGJ5
IEt1YmVybmV0ZXMgbm9kZXMgcmVzb3VyY2VzLgoKDQoFBAYCAwUSBPgBAgcKDQoFBAYCAwES
BPgBCBIKDQoFBAYCAwMSBPgBFRYKDQoFBAYCAwgSBPgBF0IKEAoIBAYCAwicCAASBPgBGEEK
gAEKBAQGAgQSBPwBAkIaciBPdXRwdXQgb25seS4gVGhlIHRvdGFsIG1lbW9yeSBjYXBhY2l0
eSBhcyByZXBvcnRlZCBieSB0aGUgc3VtIG9mIGFsbAogS3ViZXJuZXRlcyBub2RlcyByZXNv
dXJjZXMsIGRlZmluZWQgaW4gTUIuCgoNCgUEBgIEBRIE/AECBwoNCgUEBgIEARIE/AEIEQoN
CgUEBgIEAxIE/AEUFQoNCgUEBgIECBIE/AEWQQoQCggEBgIECJwIABIE/AEXQArYAQoEBAYC
BRIGgQICggIyGscBIE91dHB1dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGVzZSBkZXRh
aWxzIHdlcmUgbGFzdCB1cGRhdGVkLiBUaGlzCiB1cGRhdGVfdGltZSBpcyBkaWZmZXJlbnQg
ZnJvbSB0aGUgTWVtYmVyc2hpcC1sZXZlbCB1cGRhdGVfdGltZSBzaW5jZQogRW5kcG9pbnRE
ZXRhaWxzIGFyZSB1cGRhdGVkIGludGVybmFsbHkgZm9yIEFQSSBjb25zdW1lcnMuCgoNCgUE
BgIFBhIEgQICGwoNCgUEBgIFARIEgQIcJwoNCgUEBgIFAxIEgQIqLQoNCgUEBgIFCBIEggIG
MQoQCggEBgIFCJwIABIEggIHMAqgAQoCBAcSBocCAKACARqRASBUaGlzIGZpZWxkIGluZm9y
bXMgRmxlZXQtYmFzZWQgYXBwbGljYXRpb25zL3NlcnZpY2VzL1VJcyB3aXRoIHRoZSBuZWNl
c3NhcnkKIGluZm9ybWF0aW9uIGZvciB3aGVyZSBlYWNoIHVuZGVybHlpbmcgQ2x1c3RlciBy
ZXBvcnRzIGl0cyBtZXRyaWNzLgoKCwoDBAcBEgSHAggYCjkKBAQHAgASBIkCAkIaKyBJbW11
dGFibGUuIFByb2plY3QgdXNlZCB0byByZXBvcnQgTWV0cmljcwoKDQoFBAcCAAUSBIkCAggK
DQoFBAcCAAESBIkCCRMKDQoFBAcCAAMSBIkCFhcKDQoFBAcCAAgSBIkCGEEKEAoIBAcCAAic
CAASBIkCGUAKOgoEBAcCARIEjAICQBosIEltbXV0YWJsZS4gTG9jYXRpb24gdXNlZCB0byBy
ZXBvcnQgTWV0cmljcwoKDQoFBAcCAQUSBIwCAggKDQoFBAcCAQESBIwCCREKDQoFBAcCAQMS
BIwCFBUKDQoFBAcCAQgSBIwCFj8KEAoIBAcCAQicCAASBIwCFz4K+gEKBAQHAgISBJMCAj8a
6wEgSW1tdXRhYmxlLiBDbHVzdGVyIG5hbWUgdXNlZCB0byByZXBvcnQgbWV0cmljcy4KIEZv
ciBBbnRob3Mgb24gVk1XYXJlL0JhcmVtZXRhbCwgaXQgd291bGQgYmUgaW4gZm9ybWF0CiBg
bWVtYmVyQ2x1c3RlcnMvY2x1c3Rlcl9uYW1lYDsgQW5kIGZvciBBbnRob3Mgb24gTXVsdGlD
bG91ZCwgaXQgd291bGQgYmUgaW4KIGZvcm1hdAogYHthenVyZUNsdXN0ZXJzLCBhd3NDbHVz
dGVyc30vY2x1c3Rlcl9uYW1lYC4KCg0KBQQHAgIFEgSTAgIICg0KBQQHAgIBEgSTAgkQCg0K
BQQHAgIDEgSTAhMUCg0KBQQHAgIIEgSTAhU+ChAKCAQHAgIInAgAEgSTAhY9CqICCgQEBwID
EgSZAgInGpMCIEt1YmVybmV0ZXMgc3lzdGVtIG1ldHJpY3MsIGlmIGF2YWlsYWJsZSwgYXJl
IHdyaXR0ZW4gdG8gdGhpcyBwcmVmaXguCiBUaGlzIGRlZmF1bHRzIHRvIGt1YmVybmV0ZXMu
aW8gZm9yIEdLRSwgYW5kIGt1YmVybmV0ZXMuaW8vYW50aG9zIGZvciBBbnRob3MKIGV2ZW50
dWFsbHkuIE5vdGVkOiBBbnRob3MgTXVsdGlDbG91ZCB3aWxsIGhhdmUga3ViZXJuZXRlcy5p
byBwcmVmaXggdG9kYXkKIGJ1dCB3aWxsIG1pZ3JhdGlvbiB0byBiZSB1bmRlciBrdWJlcm5l
dGVzLmlvL2FudGhvcwoKDQoFBAcCAwUSBJkCAggKDQoFBAcCAwESBJkCCSIKDQoFBAcCAwMS
BJkCJSYKnQIKBAQHAgQSBJ8CAkQajgIgSW1tdXRhYmxlLiBDbHVzdGVyIGhhc2gsIHRoaXMg
aXMgYSB1bmlxdWUgc3RyaW5nIGdlbmVyYXRlZCBieSBnb29nbGUgY29kZSwKIHdoaWNoIGRv
ZXMgbm90IGNvbnRhaW4gYW55IFBJSSwgd2hpY2ggd2UgY2FuIHVzZSB0byByZWZlcmVuY2Ug
dGhlIGNsdXN0ZXIuCiBUaGlzIGlzIGV4cGVjdGVkIHRvIGJlIGNyZWF0ZWQgYnkgdGhlIG1v
bml0b3Jpbmcgc3RhY2sgYW5kIHBlcnNpc3RlZCBpbnRvCiB0aGUgQ2x1c3RlciBvYmplY3Qg
YXMgd2VsbCBhcyB0byBHS0UtSHViLgoKDQoFBAcCBAUSBJ8CAggKDQoFBAcCBAESBJ8CCRUK
DQoFBAcCBAMSBJ8CGBkKDQoFBAcCBAgSBJ8CGkMKEAoIBAcCBAicCAASBJ8CG0IKTQoCBAgS
BqMCALsCARo/IE1lbWJlcnNoaXBTdGF0ZSBkZXNjcmliZXMgdGhlIHN0YXRlIG9mIGEgTWVt
YmVyc2hpcCByZXNvdXJjZS4KCgsKAwQIARIEowIIFwpECgQECAQAEgalAgK3AgMaNCBDb2Rl
IGRlc2NyaWJlcyB0aGUgc3RhdGUgb2YgYSBNZW1iZXJzaGlwIHJlc291cmNlLgoKDQoFBAgE
AAESBKUCBwsKJgoGBAgEAAIAEgSnAgQZGhYgVGhlIGNvZGUgaXMgbm90IHNldC4KCg8KBwQI
BAACAAESBKcCBBQKDwoHBAgEAAIAAhIEpwIXGAoyCgYECAQAAgESBKoCBBEaIiBUaGUgY2x1
c3RlciBpcyBiZWluZyByZWdpc3RlcmVkLgoKDwoHBAgEAAIBARIEqgIEDAoPCgcECAQAAgEC
EgSqAg8QCiwKBgQIBAACAhIErQIEDhocIFRoZSBjbHVzdGVyIGlzIHJlZ2lzdGVyZWQuCgoP
CgcECAQAAgIBEgStAgQJCg8KBwQIBAACAgISBK0CDA0KNAoGBAgEAAIDEgSwAgQRGiQgVGhl
IGNsdXN0ZXIgaXMgYmVpbmcgdW5yZWdpc3RlcmVkLgoKDwoHBAgEAAIDARIEsAIEDAoPCgcE
CAQAAgMCEgSwAg8QCjIKBgQIBAACBBIEswIEERoiIFRoZSBNZW1iZXJzaGlwIGlzIGJlaW5n
IHVwZGF0ZWQuCgoPCgcECAQAAgQBEgSzAgQMCg8KBwQIBAACBAISBLMCDxAKRQoGBAgEAAIF
EgS2AgQZGjUgVGhlIE1lbWJlcnNoaXAgaXMgYmVpbmcgdXBkYXRlZCBieSB0aGUgSHViIFNl
cnZpY2UuCgoPCgcECAQAAgUBEgS2AgQUCg8KBwQIBAACBQISBLYCFxgKSgoEBAgCABIEugIC
PBo8IE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgTWVtYmVyc2hpcCBy
ZXNvdXJjZS4KCg0KBQQIAgAGEgS6AgIGCg0KBQQIAgABEgS6AgcLCg0KBQQIAgADEgS6Ag4P
Cg0KBQQIAgAIEgS6AhA7ChAKCAQIAgAInAgAEgS6AhE6CuIBCgIECRIGwAIA4AIBGtMBIEF1
dGhvcml0eSBlbmNvZGVzIGhvdyBHb29nbGUgd2lsbCByZWNvZ25pemUgaWRlbnRpdGllcyBm
cm9tIHRoaXMgTWVtYmVyc2hpcC4KIFNlZSB0aGUgd29ya2xvYWQgaWRlbnRpdHkgZG9jdW1l
bnRhdGlvbiBmb3IgbW9yZSBkZXRhaWxzOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2t1
YmVybmV0ZXMtZW5naW5lL2RvY3MvaG93LXRvL3dvcmtsb2FkLWlkZW50aXR5CgoLCgMECQES
BMACCBEKqAQKBAQJAgASBMsCAj0amQQgT3B0aW9uYWwuIEEgSlNPTiBXZWIgVG9rZW4gKEpX
VCkgaXNzdWVyIFVSSS4gYGlzc3VlcmAgbXVzdCBzdGFydCB3aXRoCiBgaHR0cHM6Ly9gIGFu
ZCBiZSBhIHZhbGlkIFVSTCB3aXRoIGxlbmd0aCA8MjAwMCBjaGFyYWN0ZXJzLgoKIElmIHNl
dCwgdGhlbiBHb29nbGUgd2lsbCBhbGxvdyB2YWxpZCBPSURDIHRva2VucyBmcm9tIHRoaXMg
aXNzdWVyIHRvCiBhdXRoZW50aWNhdGUgd2l0aGluIHRoZSB3b3JrbG9hZF9pZGVudGl0eV9w
b29sLiBPSURDIGRpc2NvdmVyeSB3aWxsIGJlCiBwZXJmb3JtZWQgb24gdGhpcyBVUkkgdG8g
dmFsaWRhdGUgdG9rZW5zIGZyb20gdGhlIGlzc3Vlci4KCiBDbGVhcmluZyBgaXNzdWVyYCBk
aXNhYmxlcyBXb3JrbG9hZCBJZGVudGl0eS4gYGlzc3VlcmAgY2Fubm90IGJlIGRpcmVjdGx5
CiBtb2RpZmllZDsgaXQgbXVzdCBiZSBjbGVhcmVkIChhbmQgV29ya2xvYWQgSWRlbnRpdHkg
ZGlzYWJsZWQpIGJlZm9yZSB1c2luZwogYSBuZXcgaXNzdWVyIChhbmQgcmUtZW5hYmxpbmcg
V29ya2xvYWQgSWRlbnRpdHkpLgoKDQoFBAkCAAUSBMsCAggKDQoFBAkCAAESBMsCCQ8KDQoF
BAkCAAMSBMsCEhMKDQoFBAkCAAgSBMsCFDwKEAoIBAkCAAicCAASBMsCFTsK/QIKBAQJAgES
BNQCAlAa7gIgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSB3b3JrbG9hZCBpZGVudGl0
eSBwb29sIGluIHdoaWNoIGBpc3N1ZXJgIHdpbGwKIGJlIHJlY29nbml6ZWQuCgogVGhlcmUg
aXMgYSBzaW5nbGUgV29ya2xvYWQgSWRlbnRpdHkgUG9vbCBwZXIgSHViIHRoYXQgaXMgc2hh
cmVkCiBiZXR3ZWVuIGFsbCBNZW1iZXJzaGlwcyB0aGF0IGJlbG9uZyB0byB0aGF0IEh1Yi4g
Rm9yIGEgSHViIGhvc3RlZCBpbgoge1BST0pFQ1RfSUR9LCB0aGUgd29ya2xvYWQgcG9vbCBm
b3JtYXQgaXMgYHtQUk9KRUNUX0lEfS5odWIuaWQuZ29vZ2AsCiBhbHRob3VnaCB0aGlzIGlz
IHN1YmplY3QgdG8gY2hhbmdlIGluIG5ld2VyIHZlcnNpb25zIG9mIHRoaXMgQVBJLgoKDQoF
BAkCAQUSBNQCAggKDQoFBAkCAQESBNQCCR8KDQoFBAkCAQMSBNQCIiMKDQoFBAkCAQgSBNQC
JE8KEAoIBAkCAQicCAASBNQCJU4KbAoEBAkCAhIE2AICSxpeIE91dHB1dCBvbmx5LiBBbiBp
ZGVudGl0eSBwcm92aWRlciB0aGF0IHJlZmxlY3RzIHRoZSBgaXNzdWVyYCBpbiB0aGUKIHdv
cmtsb2FkIGlkZW50aXR5IHBvb2wuCgoNCgUECQICBRIE2AICCAoNCgUECQICARIE2AIJGgoN
CgUECQICAxIE2AIdHgoNCgUECQICCBIE2AIfSgoQCggECQICCJwIABIE2AIgSQrqAQoEBAkC
AxIE3wICPxrbASBPcHRpb25hbC4gT0lEQyB2ZXJpZmljYXRpb24ga2V5cyBmb3IgdGhpcyBN
ZW1iZXJzaGlwIGluIEpXS1MgZm9ybWF0IChSRkMKIDc1MTcpLgoKIFdoZW4gdGhpcyBmaWVs
ZCBpcyBzZXQsIE9JREMgZGlzY292ZXJ5IHdpbGwgTk9UIGJlIHBlcmZvcm1lZCBvbiBgaXNz
dWVyYCwKIGFuZCBpbnN0ZWFkIE9JREMgdG9rZW5zIHdpbGwgYmUgdmFsaWRhdGVkIHVzaW5n
IHRoaXMgZmllbGQuCgoNCgUECQIDBRIE3wICBwoNCgUECQIDARIE3wIIEQoNCgUECQIDAxIE
3wIUFQoNCgUECQIDCBIE3wIWPgoQCggECQIDCJwIABIE3wIXPWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1::Membership::Membership ===
    # Fields for Membership
    # Field: endpoint Type: 11 (.google.cloud.gkehub.v1.MembershipEndpoint)
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkehub.v1.Membership.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: state Type: 11 (.google.cloud.gkehub.v1.MembershipState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: external_id Type: 9 ()
    # Field: last_connection_time Type: 11 (.google.protobuf.Timestamp)
    # Field: unique_id Type: 9 ()
    # Field: authority Type: 11 (.google.cloud.gkehub.v1.Authority)
    # Field: monitoring_config Type: 11 (.google.cloud.gkehub.v1.MonitoringConfig)

# === Message: Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint ===
    # Fields for MembershipEndpoint
    # Field: gke_cluster Type: 11 (.google.cloud.gkehub.v1.GkeCluster)
    # Field: kubernetes_metadata Type: 11 (.google.cloud.gkehub.v1.KubernetesMetadata)
    # Field: kubernetes_resource Type: 11 (.google.cloud.gkehub.v1.KubernetesResource)
    # Field: google_managed Type: 8 ()

# === Message: Google::Cloud::Gkehub::V1::Membership::KubernetesResource ===
    # Fields for KubernetesResource
    # Field: membership_cr_manifest Type: 9 ()
    # Field: membership_resources Type: 11 (.google.cloud.gkehub.v1.ResourceManifest)
    # Field: connect_resources Type: 11 (.google.cloud.gkehub.v1.ResourceManifest)
    # Field: resource_options Type: 11 (.google.cloud.gkehub.v1.ResourceOptions)

# === Message: Google::Cloud::Gkehub::V1::Membership::ResourceOptions ===
    # Fields for ResourceOptions
    # Field: connect_version Type: 9 ()
    # Field: v1beta1_crd Type: 8 ()
    # Field: k8s_version Type: 9 ()
    # Field: k8s_git_version Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1::Membership::ResourceManifest ===
    # Fields for ResourceManifest
    # Field: manifest Type: 9 ()
    # Field: cluster_scoped Type: 8 ()

# === Message: Google::Cloud::Gkehub::V1::Membership::GkeCluster ===
    # Fields for GkeCluster
    # Field: resource_link Type: 9 ()
    # Field: cluster_missing Type: 8 ()

# === Message: Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata ===
    # Fields for KubernetesMetadata
    # Field: kubernetes_api_server_version Type: 9 ()
    # Field: node_provider_id Type: 9 ()
    # Field: node_count Type: 5 ()
    # Field: vcpu_count Type: 5 ()
    # Field: memory_mb Type: 5 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Gkehub::V1::Membership::MonitoringConfig ===
    # Fields for MonitoringConfig
    # Field: project_id Type: 9 ()
    # Field: location Type: 9 ()
    # Field: cluster Type: 9 ()
    # Field: kubernetes_metrics_prefix Type: 9 ()
    # Field: cluster_hash Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1::Membership::MembershipState ===
    # Fields for MembershipState
    # Field: code Type: 14 (.google.cloud.gkehub.v1.MembershipState.Code)

# Enum: MembershipState::Code
our $MembershipState_CODE_UNSPECIFIED = 0;
our $MembershipState_CREATING = 1;
our $MembershipState_READY = 2;
our $MembershipState_DELETING = 3;
our $MembershipState_UPDATING = 4;
our $MembershipState_SERVICE_UPDATING = 5;

# === Message: Google::Cloud::Gkehub::V1::Membership::Authority ===
    # Fields for Authority
    # Field: issuer Type: 9 ()
    # Field: workload_identity_pool Type: 9 ()
    # Field: identity_provider Type: 9 ()
    # Field: oidc_jwks Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1::Membership - Compiled Protocol Buffers messages for google/cloud/gkehub/v1/membership.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1::Membership;

    my $msg = Google::Cloud::Gkehub::V1::Membership::Membership->new({
        endpoint => $endpoint,
        name => $name,
        labels => $labels,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->endpoint();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1::Membership::Membership->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1/membership.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1::Membership::Membership

Membership contains information about a member cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint>)

Optional. Endpoint information to reach this member.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full, unique name of this Membership resource in the
format `projects/*/locations/*/memberships/{membership_id}`, set during
creation.

`membership_id` must be a valid RFC 1123 compliant DNS label:

  1. At most 63 characters in length
  2. It must consist of lower case alphanumeric characters or `-`
  3. It must start and end with an alphanumeric character

Which can be expressed as the regex: `[a-z0-9]([-a-z0-9]*[a-z0-9])?`,
with a maximum length of 63 characters.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::Membership::LabelsEntry>)

Optional. Labels for this membership.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description of this membership, limited to 63 characters.
Must match the regex: `[a-zA-Z0-9][a-zA-Z0-9_\-\.\ ]*`

This field is present for legacy purposes.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::MembershipState>)

Output only. State of the Membership resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Membership was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Membership was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Membership was deleted.

=item * C<< $msg->external_id() >> / C<< $msg->external_id($value) >>

Type: C<String>

Optional. An externally-generated and managed ID for this Membership. This
ID may be modified after creation, but this is not recommended.

The ID must match the regex: `[a-zA-Z0-9][a-zA-Z0-9_\-\.]*`

If this Membership represents a Kubernetes cluster, this value should be
set to the UID of the `kube-system` namespace object.

=item * C<< $msg->last_connection_time() >> / C<< $msg->last_connection_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. For clusters using Connect, the timestamp of the most recent
connection established with Google Cloud. This time is updated every
several minutes, not continuously. For clusters that do not use GKE
Connect, or that have never connected successfully, this field will be
unset.

=item * C<< $msg->unique_id() >> / C<< $msg->unique_id($value) >>

Type: C<String>

Output only. Google-generated UUID for this resource. This is unique across
all Membership resources. If a Membership resource is deleted and another
resource with the same name is created, it gets a different unique_id.

=item * C<< $msg->authority() >> / C<< $msg->authority($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::Authority>)

Optional. How to identify workloads from this Membership.
See the documentation on Workload Identity for more details:
https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

=item * C<< $msg->monitoring_config() >> / C<< $msg->monitoring_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::MonitoringConfig>)

Optional. The monitoring config information for this membership.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint

MembershipEndpoint contains information needed to contact a Kubernetes API,
endpoint and any additional Kubernetes metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gke_cluster() >> / C<< $msg->gke_cluster($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::GkeCluster>)

Optional. GKE-specific information. Only present if this Membership is a GKE cluster.

=item * C<< $msg->kubernetes_metadata() >> / C<< $msg->kubernetes_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata>)

Output only. Useful Kubernetes-specific metadata.

=item * C<< $msg->kubernetes_resource() >> / C<< $msg->kubernetes_resource($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::KubernetesResource>)

Optional. The in-cluster Kubernetes Resources that should be applied for a
correctly registered cluster, in the steady state. These resources:

  * Ensure that the cluster is exclusively registered to one and only one
    Hub Membership.
  * Propagate Workload Pool Information available in the Membership
    Authority field.
  * Ensure proper initial configuration of default Hub Features.

=item * C<< $msg->google_managed() >> / C<< $msg->google_managed($value) >>

Type: C<Bool>

Output only. Whether the lifecycle of this membership is managed by a
google cluster platform service.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::KubernetesResource

KubernetesResource contains the YAML manifests and configuration for
Membership Kubernetes resources in the cluster. After CreateMembership or
UpdateMembership, these resources should be re-applied in the cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->membership_cr_manifest() >> / C<< $msg->membership_cr_manifest($value) >>

Type: C<String>

Input only. The YAML representation of the Membership CR. This field is
ignored for GKE clusters where Hub can read the CR directly.

Callers should provide the CR that is currently present in the cluster
during CreateMembership or UpdateMembership, or leave this field empty if
none exists. The CR manifest is used to validate the cluster has not been
registered with another Membership.

=item * C<< $msg->membership_resources() >> / C<< $msg->membership_resources($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::ResourceManifest>)

Output only. Additional Kubernetes resources that need to be applied to the
cluster after Membership creation, and after every update.

This field is only populated in the Membership returned from a successful
long-running operation from CreateMembership or UpdateMembership. It is not
populated during normal GetMembership or ListMemberships requests. To get
the resource manifest after the initial registration, the caller should
make a UpdateMembership call with an empty field mask.

=item * C<< $msg->connect_resources() >> / C<< $msg->connect_resources($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::ResourceManifest>)

Output only. The Kubernetes resources for installing the GKE Connect agent

This field is only populated in the Membership returned from a successful
long-running operation from CreateMembership or UpdateMembership. It is not
populated during normal GetMembership or ListMemberships requests. To get
the resource manifest after the initial registration, the caller should
make a UpdateMembership call with an empty field mask.

=item * C<< $msg->resource_options() >> / C<< $msg->resource_options($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Membership::ResourceOptions>)

Optional. Options for Kubernetes resource generation.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::ResourceOptions

ResourceOptions represent options for Kubernetes resource generation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connect_version() >> / C<< $msg->connect_version($value) >>

Type: C<String>

Optional. The Connect agent version to use for connect_resources. Defaults
to the latest GKE Connect version. The version must be a currently
supported version, obsolete versions will be rejected.

=item * C<< $msg->v1beta1_crd() >> / C<< $msg->v1beta1_crd($value) >>

Type: C<Bool>

Optional. Use `apiextensions/v1beta1` instead of `apiextensions/v1` for
CustomResourceDefinition resources.
This option should be set for clusters with Kubernetes apiserver versions
<1.16.

=item * C<< $msg->k8s_version() >> / C<< $msg->k8s_version($value) >>

Type: C<String>

Optional. Major and minor version of the Kubernetes cluster. This is only
used to determine which version to use for the CustomResourceDefinition
resources, `apiextensions/v1beta1` or`apiextensions/v1`.

=item * C<< $msg->k8s_git_version() >> / C<< $msg->k8s_git_version($value) >>

Type: C<String>

Optional. Git version of the Kubernetes cluster. This is only used to gate
the Connect Agent migration to svc.id.goog on GDC-SO 1.33.100 patch and
above.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::ResourceManifest

ResourceManifest represents a single Kubernetes resource to be applied to
the cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->manifest() >> / C<< $msg->manifest($value) >>

Type: C<String>

YAML manifest of the resource.

=item * C<< $msg->cluster_scoped() >> / C<< $msg->cluster_scoped($value) >>

Type: C<Bool>

Whether the resource provided in the manifest is `cluster_scoped`.
If unset, the manifest is assumed to be namespace scoped.

This field is used for REST mapping when applying the resource in a
cluster.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::GkeCluster

GkeCluster contains information specific to GKE clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_link() >> / C<< $msg->resource_link($value) >>

Type: C<String>

Immutable. Self-link of the Google Cloud resource for the GKE cluster. For
example:

//container.googleapis.com/projects/my-project/locations/us-west1-a/clusters/my-cluster

Zonal clusters are also supported.

=item * C<< $msg->cluster_missing() >> / C<< $msg->cluster_missing($value) >>

Type: C<Bool>

Output only. If cluster_missing is set then it denotes that the GKE cluster
no longer exists in the GKE Control Plane.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata

KubernetesMetadata provides informational metadata for Memberships
representing Kubernetes clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kubernetes_api_server_version() >> / C<< $msg->kubernetes_api_server_version($value) >>

Type: C<String>

Output only. Kubernetes API server version string as reported by
`/version`.

=item * C<< $msg->node_provider_id() >> / C<< $msg->node_provider_id($value) >>

Type: C<String>

Output only. Node providerID as reported by the first node in the list of
nodes on the Kubernetes endpoint. On Kubernetes platforms that support
zero-node clusters (like GKE-on-GCP), the node_count will be zero and the
node_provider_id will be empty.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int32>

Output only. Node count as reported by Kubernetes nodes resources.

=item * C<< $msg->vcpu_count() >> / C<< $msg->vcpu_count($value) >>

Type: C<Int32>

Output only. vCPU count as reported by Kubernetes nodes resources.

=item * C<< $msg->memory_mb() >> / C<< $msg->memory_mb($value) >>

Type: C<Int32>

Output only. The total memory capacity as reported by the sum of all
Kubernetes nodes resources, defined in MB.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which these details were last updated. This
update_time is different from the Membership-level update_time since
EndpointDetails are updated internally for API consumers.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::MonitoringConfig

This field informs Fleet-based applications/services/UIs with the necessary
information for where each underlying Cluster reports its metrics.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Immutable. Project used to report Metrics

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Immutable. Location used to report Metrics

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Immutable. Cluster name used to report metrics.
For Anthos on VMWare/Baremetal, it would be in format
`memberClusters/cluster_name`; And for Anthos on MultiCloud, it would be in
format
`{azureClusters, awsClusters}/cluster_name`.

=item * C<< $msg->kubernetes_metrics_prefix() >> / C<< $msg->kubernetes_metrics_prefix($value) >>

Type: C<String>

Kubernetes system metrics, if available, are written to this prefix.
This defaults to kubernetes.io for GKE, and kubernetes.io/anthos for Anthos
eventually. Noted: Anthos MultiCloud will have kubernetes.io prefix today
but will migration to be under kubernetes.io/anthos

=item * C<< $msg->cluster_hash() >> / C<< $msg->cluster_hash($value) >>

Type: C<String>

Immutable. Cluster hash, this is a unique string generated by google code,
which does not contain any PII, which we can use to reference the cluster.
This is expected to be created by the monitoring stack and persisted into
the Cluster object as well as to GKE-Hub.

=back

=head2 Google::Cloud::Gkehub::V1::Membership::MembershipState

MembershipState describes the state of a Membership resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1::MembershipState::Code>)

Output only. The current state of the Membership resource.

=back

=head3 Enum: MembershipState::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<SERVICE_UPDATING> => C<5>

=back

=head2 Google::Cloud::Gkehub::V1::Membership::Authority

Authority encodes how Google will recognize identities from this Membership.
See the workload identity documentation for more details:
https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->issuer() >> / C<< $msg->issuer($value) >>

Type: C<String>

Optional. A JSON Web Token (JWT) issuer URI. `issuer` must start with
`https://` and be a valid URL with length <2000 characters.

If set, then Google will allow valid OIDC tokens from this issuer to
authenticate within the workload_identity_pool. OIDC discovery will be
performed on this URI to validate tokens from the issuer.

Clearing `issuer` disables Workload Identity. `issuer` cannot be directly
modified; it must be cleared (and Workload Identity disabled) before using
a new issuer (and re-enabling Workload Identity).

=item * C<< $msg->workload_identity_pool() >> / C<< $msg->workload_identity_pool($value) >>

Type: C<String>

Output only. The name of the workload identity pool in which `issuer` will
be recognized.

There is a single Workload Identity Pool per Hub that is shared
between all Memberships that belong to that Hub. For a Hub hosted in
{PROJECT_ID}, the workload pool format is `{PROJECT_ID}.hub.id.goog`,
although this is subject to change in newer versions of this API.

=item * C<< $msg->identity_provider() >> / C<< $msg->identity_provider($value) >>

Type: C<String>

Output only. An identity provider that reflects the `issuer` in the
workload identity pool.

=item * C<< $msg->oidc_jwks() >> / C<< $msg->oidc_jwks($value) >>

Type: C<Bytes>

Optional. OIDC verification keys for this Membership in JWKS format (RFC
7517).

When this field is set, OIDC discovery will NOT be performed on `issuer`,
and instead OIDC tokens will be validated using this field.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1::Membership::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
