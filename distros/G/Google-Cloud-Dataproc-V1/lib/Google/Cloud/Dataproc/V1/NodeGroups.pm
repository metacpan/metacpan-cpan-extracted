package Google::Cloud::Dataproc::V1::NodeGroups;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dataproc::V1::Clusters };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZGF0YXByb2MvdjEvbm9kZV9ncm91cHMucHJvdG8SGGdvb2dsZS5j
bG91ZC5kYXRhcHJvYy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9kYXRhcHJvYy92MS9jbHVz
dGVycy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aHmdvb2ds
ZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byLxAQoWQ3JlYXRlTm9kZUdyb3VwUmVxdWVzdBJB
CgZwYXJlbnQYASABKAlCKeBBAvpBIxIhZGF0YXByb2MuZ29vZ2xlYXBpcy5jb20vTm9kZUdy
b3VwUgZwYXJlbnQSRwoKbm9kZV9ncm91cBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5kYXRhcHJv
Yy52MS5Ob2RlR3JvdXBCA+BBAlIJbm9kZUdyb3VwEicKDW5vZGVfZ3JvdXBfaWQYBCABKAlC
A+BBAVILbm9kZUdyb3VwSWQSIgoKcmVxdWVzdF9pZBgDIAEoCUID4EEBUglyZXF1ZXN0SWQi
0gEKFlJlc2l6ZU5vZGVHcm91cFJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEhcK
BHNpemUYAiABKAVCA+BBAlIEc2l6ZRIiCgpyZXF1ZXN0X2lkGAMgASgJQgPgQQFSCXJlcXVl
c3RJZBJiCh1ncmFjZWZ1bF9kZWNvbW1pc3Npb25fdGltZW91dBgEIAEoCzIZLmdvb2dsZS5w
cm90b2J1Zi5EdXJhdGlvbkID4EEBUhtncmFjZWZ1bERlY29tbWlzc2lvblRpbWVvdXQiVAoT
R2V0Tm9kZUdyb3VwUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWRhdGFwcm9jLmdv
b2dsZWFwaXMuY29tL05vZGVHcm91cFIEbmFtZTKnBgoTTm9kZUdyb3VwQ29udHJvbGxlchKV
AgoPQ3JlYXRlTm9kZUdyb3VwEjAuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkNyZWF0ZU5v
ZGVHcm91cFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrABgtPkkwJF
IjcvdjEve3BhcmVudD1wcm9qZWN0cy8qL3JlZ2lvbnMvKi9jbHVzdGVycy8qfS9ub2RlR3Jv
dXBzOgpub2RlX2dyb3Vw2kEfcGFyZW50LG5vZGVfZ3JvdXAsbm9kZV9ncm91cF9pZMpBQAoJ
Tm9kZUdyb3VwEjNnb29nbGUuY2xvdWQuZGF0YXByb2MudjEuTm9kZUdyb3VwT3BlcmF0aW9u
TWV0YWRhdGES/QEKD1Jlc2l6ZU5vZGVHcm91cBIwLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52
MS5SZXNpemVOb2RlR3JvdXBSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biKYAYLT5JMCQyI+L3YxL3tuYW1lPXByb2plY3RzLyovcmVnaW9ucy8qL2NsdXN0ZXJzLyov
bm9kZUdyb3Vwcy8qfTpyZXNpemU6ASraQQluYW1lLHNpemXKQUAKCU5vZGVHcm91cBIzZ29v
Z2xlLmNsb3VkLmRhdGFwcm9jLnYxLk5vZGVHcm91cE9wZXJhdGlvbk1ldGFkYXRhEqoBCgxH
ZXROb2RlR3JvdXASLS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuR2V0Tm9kZUdyb3VwUmVx
dWVzdBojLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5Ob2RlR3JvdXAiRoLT5JMCORI3L3Yx
L3tuYW1lPXByb2plY3RzLyovcmVnaW9ucy8qL2NsdXN0ZXJzLyovbm9kZUdyb3Vwcy8qfdpB
BG5hbWUaS8pBF2RhdGFwcm9jLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULQAQocY29tLmdvb2dsZS5jbG91ZC5kYXRh
cHJvYy52MUIPTm9kZUdyb3Vwc1Byb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXBy
b2MvdjIvYXBpdjEvZGF0YXByb2NwYjtkYXRhcHJvY3Bi6kFfCiVkYXRhcHJvYy5nb29nbGVh
cGlzLmNvbS9DbHVzdGVyUmVnaW9uEjZwcm9qZWN0cy97cHJvamVjdH0vcmVnaW9ucy97cmVn
aW9ufS9jbHVzdGVycy97Y2x1c3Rlcn1Koi4KBxIFDgCtAQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAxCgkKAgMFEgMXAC0KCQoCAwYSAxgAKAoICgEI
EgMaAFIKCQoCCAsSAxoAUgoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADAKCQoCCAgS
AxwAMAoICgEIEgMdADUKCQoCCAESAx0ANQoJCgEIEgQeACECCgwKBAidCAASBB4AIQIKewoC
BgASBCUAUgEabyBUaGUgYE5vZGVHcm91cENvbnRyb2xsZXJTZXJ2aWNlYCBwcm92aWRlcyBt
ZXRob2RzIHRvIG1hbmFnZSBub2RlIGdyb3Vwcwogb2YgQ29tcHV0ZSBFbmdpbmUgbWFuYWdl
ZCBpbnN0YW5jZXMuCgoKCgMGAAESAyUIGwoKCgMGAAMSAyYCPwoMCgUGAAOZCBIDJgI/CgsK
AwYAAxIEJwIoNwoNCgUGAAOaCBIEJwIoNwqJAgoEBgACABIELQI4Axr6ASBDcmVhdGVzIGEg
bm9kZSBncm91cCBpbiBhIGNsdXN0ZXIuIFRoZSByZXR1cm5lZAogW09wZXJhdGlvbi5tZXRh
ZGF0YV1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YV0gaXMKIFtOb2Rl
R3JvdXBPcGVyYXRpb25NZXRhZGF0YV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RhdGFw
cm9jL2RvY3MvcmVmZXJlbmNlL3JwYy9nb29nbGUuY2xvdWQuZGF0YXByb2MudjEjbm9kZWdy
b3Vwb3BlcmF0aW9ubWV0YWRhdGEpLgoKDAoFBgACAAESAy0GFQoMCgUGAAIAAhIDLRYsCgwK
BQYAAgADEgMuDysKDQoFBgACAAQSBC8EMgYKEQoJBgACAASwyrwiEgQvBDIGCgwKBQYAAgAE
EgMzBE0KDwoIBgACAASbCAASAzMETQoNCgUGAAIABBIENAQ3BgoPCgcGAAIABJkIEgQ0BDcG
CokCCgQGAAIBEgQ9AkgDGvoBIFJlc2l6ZXMgYSBub2RlIGdyb3VwIGluIGEgY2x1c3Rlci4g
VGhlIHJldHVybmVkCiBbT3BlcmF0aW9uLm1ldGFkYXRhXVtnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uLm1ldGFkYXRhXSBpcwogW05vZGVHcm91cE9wZXJhdGlvbk1ldGFkYXRhXSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXByb2MvZG9jcy9yZWZlcmVuY2UvcnBjL2dv
b2dsZS5jbG91ZC5kYXRhcHJvYy52MSNub2RlZ3JvdXBvcGVyYXRpb25tZXRhZGF0YSkuCgoM
CgUGAAIBARIDPQYVCgwKBQYAAgECEgM9FiwKDAoFBgACAQMSAz4PKwoNCgUGAAIBBBIEPwRC
BgoRCgkGAAIBBLDKvCISBD8EQgYKDAoFBgACAQQSA0MENwoPCggGAAIBBJsIABIDQwQ3Cg0K
BQYAAgEEEgREBEcGCg8KBwYAAgEEmQgSBEQERwYKUAoEBgACAhIETAJRAxpCIEdldHMgdGhl
IHJlc291cmNlIHJlcHJlc2VudGF0aW9uIGZvciBhIG5vZGUgZ3JvdXAgaW4gYQogY2x1c3Rl
ci4KCgwKBQYAAgIBEgNMBhIKDAoFBgACAgISA0wTJgoMCgUGAAICAxIDTDE6Cg0KBQYAAgIE
EgRNBE8GChEKCQYAAgIEsMq8IhIETQRPBgoMCgUGAAICBBIDUAQyCg8KCAYAAgIEmwgAEgNQ
BDIKLwoCBAASBFUAdgEaIyBBIHJlcXVlc3QgdG8gY3JlYXRlIGEgbm9kZSBncm91cC4KCgoK
AwQAARIDVQgeCpcBCgQEAAIAEgRYAl0EGogBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291
cmNlIHdoZXJlIHRoaXMgbm9kZSBncm91cCB3aWxsIGJlIGNyZWF0ZWQuCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vcmVnaW9ucy97cmVnaW9ufS9jbHVzdGVycy97Y2x1c3Rlcn1g
CgoMCgUEAAIABRIDWAIICgwKBQQAAgABEgNYCQ8KDAoFBAACAAMSA1gSEwoNCgUEAAIACBIE
WBRdAwoPCggEAAIACJwIABIDWQQqCg8KBwQAAgAInwgSBFoEXAUKMgoEBAACARIDYAJEGiUg
UmVxdWlyZWQuIFRoZSBub2RlIGdyb3VwIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNgAgsKDAoF
BAACAQESA2AMFgoMCgUEAAIBAxIDYBkaCgwKBQQAAgEIEgNgG0MKDwoIBAACAQicCAASA2Ac
QgqKAgoEBAACAhIDZwJEGvwBIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBub2RlIGdyb3VwIElE
LiBHZW5lcmF0ZWQgaWYgbm90IHNwZWNpZmllZC4KCiBUaGUgSUQgbXVzdCBjb250YWluIG9u
bHkgbGV0dGVycyAoYS16LCBBLVopLCBudW1iZXJzICgwLTkpLAogdW5kZXJzY29yZXMgKF8p
LCBhbmQgaHlwaGVucyAoLSkuIENhbm5vdCBiZWdpbiBvciBlbmQgd2l0aCB1bmRlcnNjb3Jl
CiBvciBoeXBoZW4uIE11c3QgY29uc2lzdCBvZiBmcm9tIDMgdG8gMzMgY2hhcmFjdGVycy4K
CgwKBQQAAgIFEgNnAggKDAoFBAACAgESA2cJFgoMCgUEAAICAxIDZxkaCgwKBQQAAgIIEgNn
G0MKDwoIBAACAgicCAASA2ccQgqYBQoEBAACAxIDdQJBGooFIE9wdGlvbmFsLiBBIHVuaXF1
ZSBJRCB1c2VkIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0LiBJZiB0aGUgc2VydmVyIHJlY2Vp
dmVzCiB0d28KIFtDcmVhdGVOb2RlR3JvdXBSZXF1ZXN0XShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vZGF0YXByb2MvZG9jcy9yZWZlcmVuY2UvcnBjL2dvb2dsZS5jbG91ZC5kYXRhcHJv
Yy52MSNnb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQ3JlYXRlTm9kZUdyb3VwUmVxdWVzdHMp
CiB3aXRoIHRoZSBzYW1lIElELCB0aGUgc2Vjb25kIHJlcXVlc3QgaXMgaWdub3JlZCBhbmQg
dGhlCiBmaXJzdCBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbl0gY3JlYXRlZAogYW5kIHN0b3JlZCBpbiB0aGUgYmFja2VuZCBp
cyByZXR1cm5lZC4KCiBSZWNvbW1lbmRhdGlvbjogU2V0IHRoaXMgdmFsdWUgdG8gYQogW1VV
SURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VuaXZlcnNhbGx5X3VuaXF1ZV9p
ZGVudGlmaWVyKS4KCiBUaGUgSUQgbXVzdCBjb250YWluIG9ubHkgbGV0dGVycyAoYS16LCBB
LVopLCBudW1iZXJzICgwLTkpLAogdW5kZXJzY29yZXMgKF8pLCBhbmQgaHlwaGVucyAoLSku
IFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA0MCBjaGFyYWN0ZXJzLgoKDAoFBAACAwUSA3UCCAoM
CgUEAAIDARIDdQkTCgwKBQQAAgMDEgN1FhcKDAoFBAACAwgSA3UYQAoPCggEAAIDCJwIABID
dRk/CjAKAgQBEgV5AKABARojIEEgcmVxdWVzdCB0byByZXNpemUgYSBub2RlIGdyb3VwLgoK
CgoDBAEBEgN5CB4KmQEKBAQBAgASA30COxqLASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IG5vZGUgZ3JvdXAgdG8gcmVzaXplLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9y
ZWdpb25zL3tyZWdpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9ub2RlR3JvdXBzL3tub2RlR3Jv
dXB9YAoKDAoFBAECAAUSA30CCAoMCgUEAQIAARIDfQkNCgwKBQQBAgADEgN9EBEKDAoFBAEC
AAgSA30SOgoPCggEAQIACJwIABIDfRM5CsEBCgQEAQIBEgSCAQI6GrIBIFJlcXVpcmVkLiBU
aGUgbnVtYmVyIG9mIHJ1bm5pbmcgaW5zdGFuY2VzIGZvciB0aGUgbm9kZSBncm91cCB0byBt
YWludGFpbi4KIFRoZSBncm91cCBhZGRzIG9yIHJlbW92ZXMgaW5zdGFuY2VzIHRvIG1haW50
YWluIHRoZSBudW1iZXIgb2YgaW5zdGFuY2VzCiBzcGVjaWZpZWQgYnkgdGhpcyBwYXJhbWV0
ZXIuCgoNCgUEAQIBBRIEggECBwoNCgUEAQIBARIEggEIDAoNCgUEAQIBAxIEggEPEAoNCgUE
AQIBCBIEggEROQoQCggEAQIBCJwIABIEggESOAqZBQoEBAECAhIEkAECQRqKBSBPcHRpb25h
bC4gQSB1bmlxdWUgSUQgdXNlZCB0byBpZGVudGlmeSB0aGUgcmVxdWVzdC4gSWYgdGhlIHNl
cnZlciByZWNlaXZlcwogdHdvCiBbUmVzaXplTm9kZUdyb3VwUmVxdWVzdF0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2RhdGFwcm9jL2RvY3MvcmVmZXJlbmNlL3JwYy9nb29nbGUuY2xv
dWQuZGF0YXByb2MudjEjZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLlJlc2l6ZU5vZGVHcm91
cFJlcXVlc3RzKQogd2l0aCB0aGUgc2FtZSBJRCwgdGhlIHNlY29uZCByZXF1ZXN0IGlzIGln
bm9yZWQgYW5kIHRoZQogZmlyc3QgW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dW2dv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dIGNyZWF0ZWQKIGFuZCBzdG9yZWQgaW4gdGhl
IGJhY2tlbmQgaXMgcmV0dXJuZWQuCgogUmVjb21tZW5kYXRpb246IFNldCB0aGlzIHZhbHVl
IHRvIGEKIFtVVUlEXShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxs
eV91bmlxdWVfaWRlbnRpZmllcikuCgogVGhlIElEIG11c3QgY29udGFpbiBvbmx5IGxldHRl
cnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwKIHVuZGVyc2NvcmVzIChfKSwgYW5kIGh5
cGhlbnMgKC0pLiBUaGUgbWF4aW11bSBsZW5ndGggaXMgNDAgY2hhcmFjdGVycy4KCg0KBQQB
AgIFEgSQAQIICg0KBQQBAgIBEgSQAQkTCg0KBQQBAgIDEgSQARYXCg0KBQQBAgIIEgSQARhA
ChAKCAQBAgIInAgAEgSQARk/CtEFCgQEAQIDEgaeAQKfAS8awAUgT3B0aW9uYWwuIFRpbWVv
dXQgZm9yIGdyYWNlZnVsIFlBUk4gZGVjb21taXNzaW9uaW5nLiBbR3JhY2VmdWwKIGRlY29t
bWlzc2lvbmluZ10KIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXByb2MvZG9jcy9j
b25jZXB0cy9jb25maWd1cmluZy1jbHVzdGVycy9zY2FsaW5nLWNsdXN0ZXJzI2dyYWNlZnVs
X2RlY29tbWlzc2lvbmluZykKIGFsbG93cyB0aGUgcmVtb3ZhbCBvZiBub2RlcyBmcm9tIHRo
ZSBDb21wdXRlIEVuZ2luZSBub2RlIGdyb3VwCiB3aXRob3V0IGludGVycnVwdGluZyBqb2Jz
IGluIHByb2dyZXNzLiBUaGlzIHRpbWVvdXQgc3BlY2lmaWVzIGhvdyBsb25nIHRvCiB3YWl0
IGZvciBqb2JzIGluIHByb2dyZXNzIHRvIGZpbmlzaCBiZWZvcmUgZm9yY2VmdWxseSByZW1v
dmluZyBub2RlcyAoYW5kCiBwb3RlbnRpYWxseSBpbnRlcnJ1cHRpbmcgam9icykuIERlZmF1
bHQgdGltZW91dCBpcyAwIChmb3IgZm9yY2VmdWwKIGRlY29tbWlzc2lvbiksIGFuZCB0aGUg
bWF4aW11bSBhbGxvd2VkIHRpbWVvdXQgaXMgMSBkYXkuIChzZWUgSlNPTgogcmVwcmVzZW50
YXRpb24gb2YKIFtEdXJhdGlvbl0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJv
dG9jb2wtYnVmZmVycy9kb2NzL3Byb3RvMyNqc29uKSkuCgogT25seSBzdXBwb3J0ZWQgb24g
RGF0YXByb2MgaW1hZ2UgdmVyc2lvbnMgMS4yIGFuZCBoaWdoZXIuCgoNCgUEAQIDBhIEngEC
GgoNCgUEAQIDARIEngEbOAoNCgUEAQIDAxIEngE7PAoNCgUEAQIDCBIEnwEGLgoQCggEAQID
CJwIABIEnwEHLQovCgIEAhIGowEArQEBGiEgQSByZXF1ZXN0IHRvIGdldCBhIG5vZGUgZ3Jv
dXAgLgoKCwoDBAIBEgSjAQgbCp4BCgQEAgIAEganAQKsAQQajQEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBub2RlIGdyb3VwIHRvIHJldHJpZXZlLgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9ub2RlR3Jv
dXBzL3tub2RlR3JvdXB9YAoKDQoFBAICAAUSBKcBAggKDQoFBAICAAESBKcBCQ0KDQoFBAIC
AAMSBKcBEBEKDwoFBAICAAgSBqcBEqwBAwoQCggEAgIACJwIABIEqAEEKgoRCgcEAgIACJ8I
EgapAQSrAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest ===
    # Fields for CreateNodeGroupRequest
    # Field: parent Type: 9 ()
    # Field: node_group Type: 11 (.google.cloud.dataproc.v1.NodeGroup)
    # Field: node_group_id Type: 9 ()
    # Field: request_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::NodeGroups;

    my $msg = Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<node_group>

Type: Message (.google.cloud.dataproc.v1.NodeGroup)

=item * B<node_group_id>

Type: String

=item * B<request_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest ===
    # Fields for ResizeNodeGroupRequest
    # Field: name Type: 9 ()
    # Field: size Type: 5 ()
    # Field: request_id Type: 9 ()
    # Field: graceful_decommission_timeout Type: 11 (.google.protobuf.Duration)

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::NodeGroups;

    my $msg = Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<size>

Type: Int32

=item * B<request_id>

Type: String

=item * B<graceful_decommission_timeout>

Type: Message (.google.protobuf.Duration)

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest ===
    # Fields for GetNodeGroupRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::NodeGroups;

    my $msg = Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Dataproc::V1::NodeGroups::NodeGroupControllerClient ===
package Google::Cloud::Dataproc::V1::NodeGroups::NodeGroupControllerClient;

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups::NodeGroupControllerClient - Client stub representing the remote NodeGroupController service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<dataproc.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataproc.googleapis.com:443' );

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

sub create_node_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.NodeGroupController',
        method         => 'CreateNodeGroup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub resize_node_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.NodeGroupController',
        method         => 'ResizeNodeGroup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_node_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.NodeGroupController',
        method         => 'GetNodeGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::Clusters::NodeGroup',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
