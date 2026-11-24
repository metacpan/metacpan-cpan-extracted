package Google::Cloud::Universalledger::V1::Query;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Universalledger::V1::Accounts };
    eval { require Google::Cloud::Universalledger::V1::Common };
    eval { require Google::Cloud::Universalledger::V1::Transactions };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Rpc::Code };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL3F1ZXJ5LnByb3RvEh9nb29nbGUu
Y2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGi5nb29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL2FjY291bnRzLnByb3RvGixn
b29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL2NvbW1vbi5wcm90bxoyZ29vZ2xlL2Ns
b3VkL3VuaXZlcnNhbGxlZGdlci92MS90cmFuc2FjdGlvbnMucHJvdG8aIGdvb2dsZS9wcm90
b2J1Zi9maWVsZF9tYXNrLnByb3RvGhVnb29nbGUvcnBjL2NvZGUucHJvdG8iyQgKB0FjY291
bnQSVgoMdXNlcl9kZXRhaWxzGAYgASgLMiwuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdl
ci52MS5Vc2VyRGV0YWlsc0ID4EEDSABSC3VzZXJEZXRhaWxzEnUKF2FjY291bnRfbWFuYWdl
cl9kZXRhaWxzGAQgASgLMjYuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5BY2Nv
dW50TWFuYWdlckRldGFpbHNCA+BBA0gAUhVhY2NvdW50TWFuYWdlckRldGFpbHMSbwoVdG9r
ZW5fbWFuYWdlcl9kZXRhaWxzGAUgASgLMjQuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdl
ci52MS5Ub2tlbk1hbmFnZXJEZXRhaWxzQgPgQQNIAFITdG9rZW5NYW5hZ2VyRGV0YWlscxKI
AQoeY29udHJhY3RfdG9rZW5fbWFuYWdlcl9kZXRhaWxzGAwgASgLMjwuZ29vZ2xlLmNsb3Vk
LnVuaXZlcnNhbGxlZGdlci52MS5Db250cmFjdFRva2VuTWFuYWdlckRldGFpbHNCA+BBA0gA
Uhtjb250cmFjdFRva2VuTWFuYWdlckRldGFpbHMSYgoQY29udHJhY3RfZGV0YWlscxgLIAEo
CzIwLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQ29udHJhY3REZXRhaWxzQgPg
QQNIAFIPY29udHJhY3REZXRhaWxzEnEKFWNsZWFyaW5naG91c2VfZGV0YWlscxgKIAEoCzI1
Lmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQ2xlYXJpbmdIb3VzZURldGFpbHNC
A+BBA0gAUhRjbGVhcmluZ2hvdXNlRGV0YWlscxJ7ChljdXJyZW5jeV9vcGVyYXRvcl9kZXRh
aWxzGAcgASgLMjguZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5DdXJyZW5jeU9w
ZXJhdG9yRGV0YWlsc0ID4EEDSABSF2N1cnJlbmN5T3BlcmF0b3JEZXRhaWxzEnsKGXBsYXRm
b3JtX29wZXJhdG9yX2RldGFpbHMYCCABKAsyOC5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVk
Z2VyLnYxLlBsYXRmb3JtT3BlcmF0b3JEZXRhaWxzQgPgQQNIAFIXcGxhdGZvcm1PcGVyYXRv
ckRldGFpbHMSLAoPc2VxdWVuY2VfbnVtYmVyGAEgASgDQgPgQQNSDnNlcXVlbmNlTnVtYmVy
EiIKCnB1YmxpY19rZXkYAiABKAxCA+BBA1IJcHVibGljS2V5Eh4KCHJvdW5kX2lkGAMgASgD
QgPgQQNSB3JvdW5kSWQSHQoHY29tbWVudBgJIAEoCUID4EEDUgdjb21tZW50QhEKD2FjY291
bnRfZGV0YWlscyJuChVBY2NvdW50TWFuYWdlckRldGFpbHMSJgoMbnVtX2FjY291bnRzGAIg
ASgFQgPgQQNSC251bUFjY291bnRzEi0KEHRva2VuX21hbmFnZXJfaWQYAyABKAlCA+BBA1IO
dG9rZW5NYW5hZ2VySWQiywEKE1Rva2VuTWFuYWdlckRldGFpbHMSWgoOaXNzdWFuY2VfbGlt
aXQYASABKAsyLi5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkN1cnJlbmN5VmFs
dWVCA+BBA1INaXNzdWFuY2VMaW1pdBJYCg1pc3N1ZWRfdG9rZW5zGAIgASgLMi4uZ29vZ2xl
LmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5DdXJyZW5jeVZhbHVlQgPgQQNSDGlzc3VlZFRv
a2VucyKAAwobQ29udHJhY3RUb2tlbk1hbmFnZXJEZXRhaWxzEloKDmlzc3VhbmNlX2xpbWl0
GAEgASgLMi4uZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5DdXJyZW5jeVZhbHVl
QgPgQQNSDWlzc3VhbmNlTGltaXQSWAoNaXNzdWVkX3Rva2VucxgCIAEoCzIuLmdvb2dsZS5j
bG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQ3VycmVuY3lWYWx1ZUID4EEDUgxpc3N1ZWRUb2tl
bnMSTwoicHJldmlvdXNfY29udHJhY3RfdG9rZW5fbWFuYWdlcl9pZBgDIAEoCUID4EEDUh5w
cmV2aW91c0NvbnRyYWN0VG9rZW5NYW5hZ2VySWQSWgoOYWNjb3VudF9zdGF0dXMYBCABKA4y
Li5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkFjY291bnRTdGF0dXNCA+BBA1IN
YWNjb3VudFN0YXR1cyLWBAoLVXNlckRldGFpbHMSMQoSYWNjb3VudF9tYW5hZ2VyX2lkGAcg
ASgJQgPgQQNSEGFjY291bnRNYW5hZ2VySWQSLQoQdG9rZW5fbWFuYWdlcl9pZBgIIAEoCUID
4EEDUg50b2tlbk1hbmFnZXJJZBJACgVyb2xlcxgDIAMoDjIlLmdvb2dsZS5jbG91ZC51bml2
ZXJzYWxsZWRnZXIudjEuUm9sZUID4EEDUgVyb2xlcxJaCg5hY2NvdW50X3N0YXR1cxgEIAEo
DjIuLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQWNjb3VudFN0YXR1c0ID4EED
Ug1hY2NvdW50U3RhdHVzEk0KB2JhbGFuY2UYBSABKAsyLi5nb29nbGUuY2xvdWQudW5pdmVy
c2FsbGVkZ2VyLnYxLkN1cnJlbmN5VmFsdWVCA+BBA1IHYmFsYW5jZRKEAQoXY29udHJhY3Rf
YWNjb3VudF9maWVsZHMYECADKAsyRy5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYx
LlVzZXJEZXRhaWxzLkNvbnRyYWN0QWNjb3VudEZpZWxkc0VudHJ5QgPgQQNSFWNvbnRyYWN0
QWNjb3VudEZpZWxkcxpxChpDb250cmFjdEFjY291bnRGaWVsZHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRI9CgV2YWx1ZRgCIAEoCzInLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIu
djEuRmllbGRzUgV2YWx1ZToCOAEijgMKF0N1cnJlbmN5T3BlcmF0b3JEZXRhaWxzEigKDWN1
cnJlbmN5X2NvZGUYCSABKAlCA+BBA1IMY3VycmVuY3lDb2RlEloKDmFjY291bnRfc3RhdHVz
GAIgASgOMi4uZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5BY2NvdW50U3RhdHVz
QgPgQQNSDWFjY291bnRTdGF0dXMSRgodcHJldmlvdXNfY3VycmVuY3lfb3BlcmF0b3JfaWQY
CiABKAlCA+BBA1IacHJldmlvdXNDdXJyZW5jeU9wZXJhdG9ySWQSNQoUcGxhdGZvcm1fb3Bl
cmF0b3JfaWQYCyABKAlCA+BBA1IScGxhdGZvcm1PcGVyYXRvcklkEj4KGWNvbnRyYWN0X3Rv
a2VuX21hbmFnZXJfaWQYCCABKAlCA+BBA1IWY29udHJhY3RUb2tlbk1hbmFnZXJJZBIuChBj
bGVhcmluZ2hvdXNlX2lkGAwgASgJQgPgQQNSD2NsZWFyaW5naG91c2VJZCK9AQoXUGxhdGZv
cm1PcGVyYXRvckRldGFpbHMSWgoOYWNjb3VudF9zdGF0dXMYASABKA4yLi5nb29nbGUuY2xv
dWQudW5pdmVyc2FsbGVkZ2VyLnYxLkFjY291bnRTdGF0dXNCA+BBA1INYWNjb3VudFN0YXR1
cxJGCh1wcmV2aW91c19wbGF0Zm9ybV9vcGVyYXRvcl9pZBgDIAEoCUID4EEDUhpwcmV2aW91
c1BsYXRmb3JtT3BlcmF0b3JJZCKkAgoUQ2xlYXJpbmdIb3VzZURldGFpbHMSWgoOYWNjb3Vu
dF9zdGF0dXMYASABKA4yLi5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkFjY291
bnRTdGF0dXNCA+BBA1INYWNjb3VudFN0YXR1cxJRCghiYWxhbmNlcxgCIAMoCzIwLmdvb2ds
ZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQmFsYW5jZVRvU2V0dGxlQgPgQQNSCGJhbGFu
Y2VzEl0KD3NldHRsZW1lbnRfbW9kZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxs
ZWRnZXIudjEuU2V0dGxlbWVudE1vZGVCA+BBA1IOc2V0dGxlbWVudE1vZGUikAMKD0NvbnRy
YWN0RGV0YWlscxIeCghvd25lcl9pZBgFIAEoCUID4EEDUgdvd25lcklkEhcKBGNvZGUYAiAB
KAxCA+BBA1IEY29kZRJVCg9jb250cmFjdF9maWVsZHMYAyABKAsyJy5nb29nbGUuY2xvdWQu
dW5pdmVyc2FsbGVkZ2VyLnYxLkZpZWxkc0ID4EEDUg5jb250cmFjdEZpZWxkcxJ4ChFjdXJy
ZW5jeV9iYWxhbmNlcxgEIAMoCzJGLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEu
Q29udHJhY3REZXRhaWxzLkN1cnJlbmN5QmFsYW5jZXNFbnRyeUID4EEDUhBjdXJyZW5jeUJh
bGFuY2VzGnMKFUN1cnJlbmN5QmFsYW5jZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJECgV2
YWx1ZRgCIAEoCzIuLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQ3VycmVuY3lW
YWx1ZVIFdmFsdWU6AjgBIsQBCg9CYWxhbmNlVG9TZXR0bGUSLQoQYmFsYW5jZV9wYXllcl9p
ZBgEIAEoCUID4EEDUg5iYWxhbmNlUGF5ZXJJZBIzChNiYWxhbmNlX3JlY2VpdmVyX2lkGAUg
ASgJQgPgQQNSEWJhbGFuY2VSZWNlaXZlcklkEk0KB2JhbGFuY2UYAyABKAsyLi5nb29nbGUu
Y2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkN1cnJlbmN5VmFsdWVCA+BBA1IHYmFsYW5jZSK9
AQoGRmllbGRzElAKBmZpZWxkcxgBIAMoCzIzLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRn
ZXIudjEuRmllbGRzLkZpZWxkc0VudHJ5QgPgQQNSBmZpZWxkcxphCgtGaWVsZHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRI8CgV2YWx1ZRgCIAEoCzImLmdvb2dsZS5jbG91ZC51bml2ZXJz
YWxsZWRnZXIudjEuVmFsdWVSBXZhbHVlOgI4ASKqAQoNUmVkYWN0ZWRGaWVsZBJECg1yZWRh
Y3RlZF9wYXRoGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEDUgxyZWRh
Y3RlZFBhdGgSGwoGcmVhc29uGAIgASgJQgPgQQNSBnJlYXNvbhI2CgtyZWFzb25fY29kZRgD
IAEoDjIQLmdvb2dsZS5ycGMuQ29kZUID4EEDUgpyZWFzb25Db2RlQusBCiNjb20uZ29vZ2xl
LmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MUIKUXVlcnlQcm90b1ABWk1jbG91ZC5nb29nbGUu
Y29tL2dvL3VuaXZlcnNhbGxlZGdlci9hcGl2MS91bml2ZXJzYWxsZWRnZXJwYjt1bml2ZXJz
YWxsZWRnZXJwYqoCH0dvb2dsZS5DbG91ZC5Vbml2ZXJzYWxMZWRnZXIuVjHKAh9Hb29nbGVc
Q2xvdWRcVW5pdmVyc2FsTGVkZ2VyXFYx6gIiR29vZ2xlOjpDbG91ZDo6VW5pdmVyc2FsTGVk
Z2VyOjpWMUqqUQoHEgUOAIMCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTADgKCQoCAwISAxQANgoJCgIDAxIDFQA8
CgkKAgMEEgMWACoKCQoCAwUSAxcAHwoICgEIEgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAGQK
CQoCCAsSAxoAZAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcACsKCQoCCAgSAxwAKwoI
CgEIEgMdADwKCQoCCAESAx0APAoICgEIEgMeADwKCQoCCCkSAx4APAoICgEIEgMfADsKCQoC
CC0SAx8AOwo/CgIEABIEIgBTARozIFJlcHJlc2VudHMgdGhlIHN0YXRlIG9mIGFuIGFjY291
bnQgb24gdGhlIGxlZGdlci4KCgoKAwQAARIDIggPCj4KBAQACAASBCQCQwMaMCBTcGVjaWZp
YyBkZXRhaWxzIGJhc2VkIG9uIHRoZSB0eXBlIG9mIGFjY291bnQuCgoMCgUEAAgAARIDJAgX
CkAKBAQAAgASAyYETRozIE91dHB1dCBvbmx5LiBEZXRhaWxzIGZvciBhIHN0YW5kYXJkIHVz
ZXIgYWNjb3VudC4KCgwKBQQAAgAGEgMmBA8KDAoFBAACAAESAyYQHAoMCgUEAAIAAxIDJh8g
CgwKBQQAAgAIEgMmIUwKDwoIBAACAAicCAASAyYiSwpECgQEAAIBEgQpBCo0GjYgT3V0cHV0
IG9ubHkuIERldGFpbHMgZm9yIGFuIGFjY291bnQgbWFuYWdlciBhY2NvdW50LgoKDAoFBAAC
AQYSAykEGQoMCgUEAAIBARIDKRoxCgwKBQQAAgEDEgMpNDUKDAoFBAACAQgSAyoIMwoPCggE
AAIBCJwIABIDKgkyCkEKBAQAAgISBC0ELjQaMyBPdXRwdXQgb25seS4gRGV0YWlscyBmb3Ig
YSB0b2tlbiBtYW5hZ2VyIGFjY291bnQuCgoMCgUEAAICBhIDLQQXCgwKBQQAAgIBEgMtGC0K
DAoFBAACAgMSAy0wMQoMCgUEAAICCBIDLggzCg8KCAQAAgIInAgAEgMuCTIKSgoEBAACAxIE
MQQyNBo8IE91dHB1dCBvbmx5LiBEZXRhaWxzIGZvciBhIGNvbnRyYWN0IHRva2VuIG1hbmFn
ZXIgYWNjb3VudC4KCgwKBQQAAgMGEgMxBB8KDAoFBAACAwESAzEgPgoMCgUEAAIDAxIDMUFD
CgwKBQQAAgMIEgMyCDMKDwoIBAACAwicCAASAzIJMgpCCgQEAAIEEgQ1BDY0GjQgT3V0cHV0
IG9ubHkuIERldGFpbHMgZm9yIGEgc21hcnQgY29udHJhY3QgYWNjb3VudC4KCgwKBQQAAgQG
EgM1BBMKDAoFBAACBAESAzUUJAoMCgUEAAIEAxIDNScpCgwKBQQAAgQIEgM2CDMKDwoIBAAC
BAicCAASAzYJMgpBCgQEAAIFEgQ5BDo0GjMgT3V0cHV0IG9ubHkuIERldGFpbHMgZm9yIGEg
Y2xlYXJpbmdob3VzZSBhY2NvdW50LgoKDAoFBAACBQYSAzkEGAoMCgUEAAIFARIDORkuCgwK
BQQAAgUDEgM5MTMKDAoFBAACBQgSAzoIMwoPCggEAAIFCJwIABIDOgkyCkUKBAQAAgYSBD0E
PjQaNyBPdXRwdXQgb25seS4gRGV0YWlscyBmb3IgYSBjdXJyZW5jeSBvcGVyYXRvciBhY2Nv
dW50LgoKDAoFBAACBgYSAz0EGwoMCgUEAAIGARIDPRw1CgwKBQQAAgYDEgM9ODkKDAoFBAAC
BggSAz4IMwoPCggEAAIGCJwIABIDPgkyCkUKBAQAAgcSBEEEQjQaNyBPdXRwdXQgb25seS4g
RGV0YWlscyBmb3IgYSBwbGF0Zm9ybSBvcGVyYXRvciBhY2NvdW50LgoKDAoFBAACBwYSA0EE
GwoMCgUEAAIHARIDQRw1CgwKBQQAAgcDEgNBODkKDAoFBAACBwgSA0IIMwoPCggEAAIHCJwI
ABIDQgkyCoQBCgQEAAIIEgNHAkgadyBPdXRwdXQgb25seS4gVGhlIHNlcXVlbmNlIG51bWJl
ciBvZiB0aGlzIGFjY291bnQuIFRoaXMgbnVtYmVyIGluY3JlbWVudHMKIHdpdGggZWFjaCB0
cmFuc2FjdGlvbiBzZW50IGJ5IHRoaXMgYWNjb3VudC4KCgwKBQQAAggFEgNHAgcKDAoFBAAC
CAESA0cIFwoMCgUEAAIIAxIDRxobCgwKBQQAAggIEgNHHEcKDwoIBAACCAicCAASA0cdRgpy
CgQEAAIJEgNLAkMaZSBPdXRwdXQgb25seS4gVGhlIHByaW1hcnkgcHVibGljIGtleSBhc3Nv
Y2lhdGVkIHdpdGggdGhpcyBhY2NvdW50LCB1c2VkIGZvcgogc2lnbmF0dXJlIHZlcmlmaWNh
dGlvbi4KCgwKBQQAAgkFEgNLAgcKDAoFBAACCQESA0sIEgoMCgUEAAIJAxIDSxUWCgwKBQQA
AgkIEgNLF0IKDwoIBAACCQicCAASA0sYQQqOAQoEBAACChIDTwJBGoABIE91dHB1dCBvbmx5
LiBUaGUgSUQgb2YgdGhlIGV4ZWN1dGlvbiByb3VuZCAoc2ltaWxhciB0byBibG9jayAiaGVp
Z2h0IikgYXQKIHdoaWNoIHRoZSBhY2NvdW50IGluZm9ybWF0aW9uIHByb3ZpZGVkIGlzIGFj
Y3VyYXRlLgoKDAoFBAACCgUSA08CBwoMCgUEAAIKARIDTwgQCgwKBQQAAgoDEgNPExQKDAoF
BAACCggSA08VQAoPCggEAAIKCJwIABIDTxY/ClUKBAQAAgsSA1ICQRpIIE91dHB1dCBvbmx5
LiBUaGUgYWNjb3VudCBjb21tZW50IHN0b3JlZCB3aGVuIHRoaXMgYWNjb3VudCB3YXMgY3Jl
YXRlZC4KCgwKBQQAAgsFEgNSAggKDAoFBAACCwESA1IJEAoMCgUEAAILAxIDUhMUCgwKBQQA
AgsIEgNSFUAKDwoIBAACCwicCAASA1IWPwo1CgIEARIEVgBdARopIERldGFpbHMgc3BlY2lm
aWMgdG8gYW4gQWNjb3VudCBNYW5hZ2VyLgoKCgoDBAEBEgNWCB0KUwoEBAECABIDWAJFGkYg
T3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgYWNjb3VudHMgY3JlYXRlZCBieSB0aGlzIGFj
Y291bnQgbWFuYWdlci4KCgwKBQQBAgAFEgNYAgcKDAoFBAECAAESA1gIFAoMCgUEAQIAAxID
WBcYCgwKBQQBAgAIEgNYGUQKDwoIBAECAAicCAASA1gaQwpuCgQEAQIBEgNcAkoaYSBPdXRw
dXQgb25seS4gVGhlIElEIG9mIHRoZSBkZWZhdWx0IHRva2VuIG1hbmFnZXIgZm9yIGFjY291
bnRzIGNyZWF0ZWQgYnkKIHRoaXMgYWNjb3VudCBtYW5hZ2VyLgoKDAoFBAECAQUSA1wCCAoM
CgUEAQIBARIDXAkZCgwKBQQBAgEDEgNcHB0KDAoFBAECAQgSA1weSQoPCggEAQIBCJwIABID
XB9ICjIKAgQCEgRgAGcBGiYgRGV0YWlscyBzcGVjaWZpYyB0byBhIFRva2VuIE1hbmFnZXIu
CgoKCgMEAgESA2AIGwpXCgQEAgIAEgNiAk8aSiBPdXRwdXQgb25seS4gVGhlIGFtb3VudCBv
ZiB0b2tlbnMgdGhpcyB0b2tlbiBtYW5hZ2VyIGlzIGFsbG93ZWQgdG8gbWludC4KCgwKBQQC
AgAGEgNiAg8KDAoFBAICAAESA2IQHgoMCgUEAgIAAxIDYiEiCgwKBQQCAgAIEgNiI04KDwoI
BAICAAicCAASA2IkTQqSAQoEBAICARIDZgJOGoQBIE91dHB1dCBvbmx5LiBUaGUgYW1vdW50
IG9mIHRva2VucyBtaW50ZWQgYnkgdGhpcyB0b2tlbiBtYW5hZ2VyLgogVGhpcyBudW1iZXIg
d2lsbCBpbmNyZWFzZSB3aGVuIG1pbnRpbmcgYW5kIGRlY3JlYXNlIHdoZW4gYnVybmluZy4K
CgwKBQQCAgEGEgNmAg8KDAoFBAICAQESA2YQHQoMCgUEAgIBAxIDZiAhCgwKBQQCAgEIEgNm
Ik0KDwoIBAICAQicCAASA2YjTAo8CgIEAxIFagCCAQEaLyBEZXRhaWxzIHNwZWNpZmljIHRv
IGEgQ29udHJhY3QgVG9rZW4gTWFuYWdlci4KCgoKAwQDARIDaggjCusBCgQEAwIAEgNwAk8a
3QEgT3V0cHV0IG9ubHkuIFRoZSBhbW91bnQgb2YgdG9rZW5zIHRoaXMgY29udHJhY3QgdG9r
ZW4gbWFuYWdlciBpcyBhbGxvd2VkCiB0byBwcm92aWRlIGJhY2tpbmcgZm9yLgoKIFNpbmNl
IGNvbnRyYWN0IHRva2VuIG1hbmFnZXJzIGNhbm5vdCBpbmNyZWFzZSBvciBkZWNyZWFzZQog
dGhlaXIgaXNzdWFuY2UgbGltaXQsIHRoaXMgc2hvdWxkIGVxdWFsIHRoZSBgaXNzdWVkX3Rv
a2Vuc2AuCgoMCgUEAwIABhIDcAIPCgwKBQQDAgABEgNwEB4KDAoFBAMCAAMSA3AhIgoMCgUE
AwIACBIDcCNOCg8KCAQDAgAInAgAEgNwJE0KhQIKBAQDAgESA3cCThr3ASBPdXRwdXQgb25s
eS4gVGhlIGFtb3VudCBvZiB0b2tlbnMgdGhpcyBjb250cmFjdCB0b2tlbiBtYW5hZ2VyIGlz
CiBwcm92aWRpbmcgYmFja2luZyBmb3IgKHRoYXQgaXMsIGl0cyB0b3RhbCBsaWFiaWxpdHkp
LgoKIFRoaXMgZXF1YWxzIHRvIHRoZSBzdW0gb2YgYWxsIGJhbGFuY2VzIGhlbGQgaW4gY29u
dHJhY3RzIGZvciBpdHMgY3VycmVuY3ksCiBwbHVzIGl0cyBuZXQgcG9zaXRpb24gaW4gdGhl
IHNldHRsZW1lbnQgbWF0cml4LgoKDAoFBAMCAQYSA3cCDwoMCgUEAwIBARIDdxAdCgwKBQQD
AgEDEgN3ICEKDAoFBAMCAQgSA3ciTQoPCggEAwIBCJwIABIDdyNMCo4CCgQEAwICEgR9An4y
Gv8BIE91dHB1dCBvbmx5LiBUaGUgYWNjb3VudCBJRCBvZiB0aGUgcHJldmlvdXMgY29udHJh
Y3QgdG9rZW4gbWFuYWdlciBmb3IgdGhpcwogY3VycmVuY3kuIFRoaXMgZm9ybXMgYW4gYXVk
aXQgdHJhaWwgdGhhdCBjYW4gYmUgdHJhdmVyc2VkIHRvIGRpc2NvdmVyIGFsbAogcHJldmlv
dXMgbWFuYWdlcnMuIElmIHRoaXMgaXMgdGhlIGZpcnN0IGNvbnRyYWN0IHRva2VuIG1hbmFn
ZXIgZm9yIHRoZQogY3VycmVuY3ksIHRoaXMgd2lsbCBiZSBlbXB0eS4KCgwKBQQDAgIFEgN9
AggKDAoFBAMCAgESA30JKwoMCgUEAwICAxIDfS4vCgwKBQQDAgIIEgN+BjEKDwoIBAMCAgic
CAASA34HMAo4CgQEAwIDEgSBAQJPGiogT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhp
cyBhY2NvdW50LgoKDQoFBAMCAwYSBIEBAg8KDQoFBAMCAwESBIEBEB4KDQoFBAMCAwMSBIEB
ISIKDQoFBAMCAwgSBIEBI04KEAoIBAMCAwicCAASBIEBJE0KMwoCBAQSBoUBAJkBARolIERl
dGFpbHMgc3BlY2lmaWMgdG8gYSBVc2VyIGFjY291bnQuCgoLCgMEBAESBIUBCBMKSQoEBAQC
ABIEhwECTBo7IE91dHB1dCBvbmx5LiBUaGUgSUQgb2YgdGhlIGFjY291bnQgbWFuYWdlciBm
b3IgdGhpcyB1c2VyLgoKDQoFBAQCAAUSBIcBAggKDQoFBAQCAAESBIcBCRsKDQoFBAQCAAMS
BIcBHh8KDQoFBAQCAAgSBIcBIEsKEAoIBAQCAAicCAASBIcBIUoKRwoEBAQCARIEigECSho5
IE91dHB1dCBvbmx5LiBUaGUgSUQgb2YgdGhlIHRva2VuIG1hbmFnZXIgZm9yIHRoaXMgdXNl
ci4KCg0KBQQEAgEFEgSKAQIICg0KBQQEAgEBEgSKAQkZCg0KBQQEAgEDEgSKARwdCg0KBQQE
AgEIEgSKAR5JChAKCAQEAgEInAgAEgSKAR9ICkcKBAQEAgISBI0BAkYaOSBPdXRwdXQgb25s
eS4gVGhlIGxpc3Qgb2Ygcm9sZXMgZ3JhbnRlZCB0byB0aGlzIGFjY291bnQuCgoNCgUEBAIC
BBIEjQECCgoNCgUEBAICBhIEjQELDwoNCgUEBAICARIEjQEQFQoNCgUEBAICAxIEjQEYGQoN
CgUEBAICCBIEjQEaRQoQCggEBAICCJwIABIEjQEbRAo4CgQEBAIDEgSQAQJPGiogT3V0cHV0
IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhpcyBhY2NvdW50LgoKDQoFBAQCAwYSBJABAg8KDQoF
BAQCAwESBJABEB4KDQoFBAQCAwMSBJABISIKDQoFBAQCAwgSBJABI04KEAoIBAQCAwicCAAS
BJABJE0KRAoEBAQCBBIEkwECSBo2IE91dHB1dCBvbmx5LiBUaGUgdG9rZW4gYmFsYW5jZSBv
ZiB0aGlzIHVzZXIgYWNjb3VudC4KCg0KBQQEAgQGEgSTAQIPCg0KBQQEAgQBEgSTARAXCg0K
BQQEAgQDEgSTARobCg0KBQQEAgQIEgSTARxHChAKCAQEAgQInAgAEgSTAR1GCmIKBAQEAgUS
BpcBApgBMhpSIE91dHB1dCBvbmx5LiBUaGUgY29udHJhY3QgYWNjb3VudCBmaWVsZHMgKGNv
bnRyYWN0IElEIC0+IGZpZWxkcykgZm9yIHRoaXMKIHVzZXIuCgoNCgUEBAIFBhIElwECFQoN
CgUEBAIFARIElwEWLQoNCgUEBAIFAxIElwEwMgoNCgUEBAIFCBIEmAEGMQoQCggEBAIFCJwI
ABIEmAEHMAo4CgIEBRIGnAEAtgEBGiogRGV0YWlscyBzcGVjaWZpYyB0byBhIEN1cnJlbmN5
IE9wZXJhdG9yLgoKCwoDBAUBEgScAQgfCn0KBAQFAgASBJ8BAkcabyBPdXRwdXQgb25seS4g
VGhlIElEIG9mIHRoZSBjdXJyZW5jeSBhc3NvY2lhdGVkIHdpdGggdGhpcyBhY2NvdW50LAog
cmVwcmVzZW50ZWQgYnkgdGhlIDMtbGV0dGVyIElTTyA0MjE3IGNvZGUuCgoNCgUEBQIABRIE
nwECCAoNCgUEBQIAARIEnwEJFgoNCgUEBQIAAxIEnwEZGgoNCgUEBQIACBIEnwEbRgoQCggE
BQIACJwIABIEnwEcRQo4CgQEBQIBEgSiAQJPGiogT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMg
b2YgdGhpcyBhY2NvdW50LgoKDQoFBAUCAQYSBKIBAg8KDQoFBAUCAQESBKIBEB4KDQoFBAUC
AQMSBKIBISIKDQoFBAUCAQgSBKIBI04KEAoIBAUCAQicCAASBKIBJE0K4gEKBAQFAgISBqcB
AqgBMhrRASBPdXRwdXQgb25seS4gVGhlIElEIG9mIHRoZSBwcmV2aW91cyBjdXJyZW5jeSBv
cGVyYXRvciB3aGljaCB0cmFuc2ZlcnJlZAogb3duZXJzaGlwIG9mIHRoZSBjdXJyZW5jeSBv
cGVyYXRvciByb2xlIHRvIHRoaXMgYWNjb3VudC4gSWYgdGhpcyBpcyB0aGUKIGZpcnN0IGN1
cnJlbmN5IG9wZXJhdG9yIGZvciB0aGUgY3VycmVuY3ksIHRoaXMgd2lsbCBiZSBlbXB0eS4K
Cg0KBQQFAgIFEgSnAQIICg0KBQQFAgIBEgSnAQkmCg0KBQQFAgIDEgSnASkrCg0KBQQFAgII
EgSoAQYxChAKCAQFAgIInAgAEgSoAQcwCmMKBAQFAgMSBKwBAk8aVSBPdXRwdXQgb25seS4g
VGhlIElEIG9mIHRoZSBwbGF0Zm9ybSBvcGVyYXRvciB3aGljaCBjcmVhdGVkIHRoaXMgY3Vy
cmVuY3kKIG9wZXJhdG9yLgoKDQoFBAUCAwUSBKwBAggKDQoFBAUCAwESBKwBCR0KDQoFBAUC
AwMSBKwBICIKDQoFBAUCAwgSBKwBI04KEAoIBAUCAwicCAASBKwBJE0KbAoEBAUCBBIGsAEC
sQEyGlwgT3V0cHV0IG9ubHkuIFRoZSBJRCBvZiB0aGUgY29udHJhY3QgdG9rZW4gbWFuYWdl
ciBhc3NvY2lhdGVkIHdpdGggdGhpcwogY3VycmVuY3kgb3BlcmF0b3IuCgoNCgUEBQIEBRIE
sAECCAoNCgUEBQIEARIEsAEJIgoNCgUEBQIEAxIEsAElJgoNCgUEBQIECBIEsQEGMQoQCggE
BQIECJwIABIEsQEHMAphCgQEBQIFEgS1AQJLGlMgT3V0cHV0IG9ubHkuIFRoZSBJRCBvZiB0
aGUgY2xlYXJpbmdob3VzZSBhc3NvY2lhdGVkIHdpdGggdGhpcyBjdXJyZW5jeQogb3BlcmF0
b3IuCgoNCgUEBQIFBRIEtQECCAoNCgUEBQIFARIEtQEJGQoNCgUEBQIFAxIEtQEcHgoNCgUE
BQIFCBIEtQEfSgoQCggEBQIFCJwIABIEtQEgSQo4CgIEBhIGuQEAwgEBGiogRGV0YWlscyBz
cGVjaWZpYyB0byBhIFBsYXRmb3JtIE9wZXJhdG9yLgoKCwoDBAYBEgS5AQgfCjgKBAQGAgAS
BLsBAk8aKiBPdXRwdXQgb25seS4gVGhlIHN0YXR1cyBvZiB0aGlzIGFjY291bnQuCgoNCgUE
BgIABhIEuwECDwoNCgUEBgIAARIEuwEQHgoNCgUEBgIAAxIEuwEhIgoNCgUEBgIACBIEuwEj
TgoQCggEBgIACJwIABIEuwEkTQrRAQoEBAYCARIGwAECwQEyGsABIE91dHB1dCBvbmx5LiBU
aGUgSUQgb2YgdGhlIHByZXZpb3VzIHBsYXRmb3JtIG9wZXJhdG9yIHdoaWNoIHRyYW5zZmVy
cmVkCiBvd25lcnNoaXAgb2YgdGhlIHBsYXRmb3JtIG9wZXJhdG9yIHJvbGUgdG8gdGhpcyBh
Y2NvdW50LiBJZiB0aGlzIGlzIHRoZQogZmlyc3QgcGxhdGZvcm0gb3BlcmF0b3IsIHRoaXMg
d2lsbCBiZSBlbXB0eS4KCg0KBQQGAgEFEgTAAQIICg0KBQQGAgEBEgTAAQkmCg0KBQQGAgED
EgTAASkqCg0KBQQGAgEIEgTBAQYxChAKCAQGAgEInAgAEgTBAQcwCjQKAgQHEgbFAQDRAQEa
JiBEZXRhaWxzIHNwZWNpZmljIHRvIGEgQ2xlYXJpbmdob3VzZS4KCgsKAwQHARIExQEIHAo4
CgQEBwIAEgTHAQJPGiogT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhpcyBhY2NvdW50
LgoKDQoFBAcCAAYSBMcBAg8KDQoFBAcCAAESBMcBEB4KDQoFBAcCAAMSBMcBISIKDQoFBAcC
AAgSBMcBI04KEAoIBAcCAAicCAASBMcBJE0KagoEBAcCARIGywECzAEyGlogT3V0cHV0IG9u
bHkuIFRoZSBiYWxhbmNlcyB0aGF0IHRoaXMgY2xlYXJpbmdob3VzZSBpcyBjdXJyZW50bHkg
dHJhY2tpbmcgZm9yCiBzZXR0bGVtZW50LgoKDQoFBAcCAQQSBMsBAgoKDQoFBAcCAQYSBMsB
CxoKDQoFBAcCAQESBMsBGyMKDQoFBAcCAQMSBMsBJicKDQoFBAcCAQgSBMwBBjEKEAoIBAcC
AQicCAASBMwBBzAKSQoEBAcCAhIGzwEC0AEyGjkgT3V0cHV0IG9ubHkuIFRoZSBzZXR0bGVt
ZW50IG1vZGUgb2YgdGhpcyBjbGVhcmluZ2hvdXNlLgoKDQoFBAcCAgYSBM8BAhAKDQoFBAcC
AgESBM8BESAKDQoFBAcCAgMSBM8BIyQKDQoFBAcCAggSBNABBjEKEAoIBAcCAgicCAASBNAB
BzAKNQoCBAgSBtQBAOIBARonIERldGFpbHMgc3BlY2lmaWMgdG8gYSBTbWFydCBDb250cmFj
dC4KCgsKAwQIARIE1AEIFwpBCgQECAIAEgTWAQJCGjMgT3V0cHV0IG9ubHkuIFRoZSBJRCBv
ZiB0aGUgb3duZXIgb2YgdGhlIGNvbnRyYWN0LgoKDQoFBAgCAAUSBNYBAggKDQoFBAgCAAES
BNYBCREKDQoFBAgCAAMSBNYBFBUKDQoFBAgCAAgSBNYBFkEKEAoIBAgCAAicCAASBNYBF0AK
OgoEBAgCARIE2QECPRosIE91dHB1dCBvbmx5LiBUaGUgc2VyaWFsaXplZCBjb250cmFjdCBj
b2RlLgoKDQoFBAgCAQUSBNkBAgcKDQoFBAgCAQESBNkBCAwKDQoFBAgCAQMSBNkBDxAKDQoF
BAgCAQgSBNkBETwKEAoIBAgCAQicCAASBNkBEjsKWQoEBAgCAhIE3AECSRpLIE91dHB1dCBv
bmx5LiBUaGUgY29udHJhY3QgZmllbGRzIChmaWVsZCBuYW1lIC0+IHZhbHVlKSBmb3IgdGhp
cyBjb250cmFjdC4KCg0KBQQIAgIGEgTcAQIICg0KBQQIAgIBEgTcAQkYCg0KBQQIAgIDEgTc
ARscCg0KBQQIAgIIEgTcAR1IChAKCAQIAgIInAgAEgTcAR5HCmoKBAQIAgMSBuABAuEBMhpa
IE91dHB1dCBvbmx5LiBUaGUgY3VycmVuY3kgYmFsYW5jZXMgaGVsZCBieSB0aGUgY29udHJh
Y3QgKGN1cnJlbmN5IG9wZXJhdG9yCiAtPiBiYWxhbmNlKS4KCg0KBQQIAgMGEgTgAQIcCg0K
BQQIAgMBEgTgAR0uCg0KBQQIAgMDEgTgATEyCg0KBQQIAgMIEgThAQYxChAKCAQIAgMInAgA
EgThAQcwCj8KAgQJEgblAQDuAQEaMSBBIGJhbGFuY2UgdG8gc2V0dGxlIGJldHdlZW4gdHdv
IHRva2VuIG1hbmFnZXJzLgoKCwoDBAkBEgTlAQgXClgKBAQJAgASBOcBAkoaSiBPdXRwdXQg
b25seS4gVGhlIElEIG9mIHRoZSBhY2NvdW50IHdoaWNoIG93ZXMgdGhlIGJhbGFuY2UgdG8g
YmUgc2V0dGxlZC4KCg0KBQQJAgAFEgTnAQIICg0KBQQJAgABEgTnAQkZCg0KBQQJAgADEgTn
ARwdCg0KBQQJAgAIEgTnAR5JChAKCAQJAgAInAgAEgTnAR9IClsKBAQJAgESBOoBAk0aTSBP
dXRwdXQgb25seS4gVGhlIElEIG9mIHRoZSBhY2NvdW50IHdoaWNoIGlzIG93ZWQgdGhlIGJh
bGFuY2UgdG8gYmUgc2V0dGxlZC4KCg0KBQQJAgEFEgTqAQIICg0KBQQJAgEBEgTqAQkcCg0K
BQQJAgEDEgTqAR8gCg0KBQQJAgEIEgTqASFMChAKCAQJAgEInAgAEgTqASJLCkUKBAQJAgIS
BO0BAkgaNyBPdXRwdXQgb25seS4gVGhlIGJhbGFuY2UgdG8gc2V0dGxlLiBNdXN0IGJlIHBv
c2l0aXZlLgoKDQoFBAkCAgYSBO0BAg8KDQoFBAkCAgESBO0BEBcKDQoFBAkCAgMSBO0BGhsK
DQoFBAkCAggSBO0BHEcKEAoIBAkCAgicCAASBO0BHUYKewoCBAoSBvIBAPUBARptIEEgbWFw
IG9mIGZpZWxkcyAoZmllbGQgbmFtZSAtPiB2YWx1ZSkgZnJvbSBhIGNvbnRyYWN0IHVzZWQg
dG8gcmVwcmVzZW50CiBjb250cmFjdCBmaWVsZHMgb3IgYWNjb3VudCBmaWVsZHMuCgoLCgME
CgESBPIBCA4KRAoEBAoCABIE9AECTBo2IE91dHB1dCBvbmx5LiBUaGUgbWFwIG9mIGZpZWxk
IG5hbWVzIHRvIHRoZWlyIHZhbHVlcy4KCg0KBQQKAgAGEgT0AQIUCg0KBQQKAgABEgT0ARUb
Cg0KBQQKAgADEgT0AR4fCg0KBQQKAgAIEgT0ASBLChAKCAQKAgAInAgAEgT0ASFKCkMKAgQL
Egb4AQCDAgEaNSBJbmZvcm1hdGlvbiBhYm91dCBhIHJlZGFjdGVkIGZpZWxkIGluIHRoZSBy
ZXNwb25zZS4KCgsKAwQLARIE+AEIFQpkCgQECwIAEgb7AQL8ATIaVCBPdXRwdXQgb25seS4g
VGhlIGZ1bGx5IHF1YWxpZmllZCBmaWVsZCBwYXRocyB0aGF0IHdlcmUgcmVkYWN0ZWQgZnJv
bSB0aGUKIHBheWxvYWQuCgoNCgUECwIABhIE+wECGwoNCgUECwIAARIE+wEcKQoNCgUECwIA
AxIE+wEsLQoNCgUECwIACBIE/AEGMQoQCggECwIACJwIABIE/AEHMApaCgQECwIBEgT/AQJA
GkwgT3V0cHV0IG9ubHkuIEEgaHVtYW4tcmVhZGFibGUgZXhwbGFuYXRpb24gb2Ygd2h5IHRo
ZSBmaWVsZHMgd2VyZSByZWRhY3RlZC4KCg0KBQQLAgEFEgT/AQIICg0KBQQLAgEBEgT/AQkP
Cg0KBQQLAgEDEgT/ARITCg0KBQQLAgEIEgT/ARQ/ChAKCAQLAgEInAgAEgT/ARU+ClYKBAQL
AgISBIICAk4aSCBPdXRwdXQgb25seS4gQSBtYWNoaW5lIHJlYWRhYmxlIGNvZGUgZm9yIHdo
eSB0aGUgZmllbGRzIHdlcmUgcmVkYWN0ZWQuCgoNCgUECwICBhIEggICEQoNCgUECwICARIE
ggISHQoNCgUECwICAxIEggIgIQoNCgUECwICCBIEggIiTQoQCggECwICCJwIABIEggIjTGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Universalledger::V1::Query::Account ===
    # Fields for Account
    # Field: user_details Type: 11 (.google.cloud.universalledger.v1.UserDetails)
    # Field: account_manager_details Type: 11 (.google.cloud.universalledger.v1.AccountManagerDetails)
    # Field: token_manager_details Type: 11 (.google.cloud.universalledger.v1.TokenManagerDetails)
    # Field: contract_token_manager_details Type: 11 (.google.cloud.universalledger.v1.ContractTokenManagerDetails)
    # Field: contract_details Type: 11 (.google.cloud.universalledger.v1.ContractDetails)
    # Field: clearinghouse_details Type: 11 (.google.cloud.universalledger.v1.ClearingHouseDetails)
    # Field: currency_operator_details Type: 11 (.google.cloud.universalledger.v1.CurrencyOperatorDetails)
    # Field: platform_operator_details Type: 11 (.google.cloud.universalledger.v1.PlatformOperatorDetails)
    # Field: sequence_number Type: 3 ()
    # Field: public_key Type: 12 ()
    # Field: round_id Type: 3 ()
    # Field: comment Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Query::AccountManagerDetails ===
    # Fields for AccountManagerDetails
    # Field: num_accounts Type: 5 ()
    # Field: token_manager_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Query::TokenManagerDetails ===
    # Fields for TokenManagerDetails
    # Field: issuance_limit Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)
    # Field: issued_tokens Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)

# === Message: Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails ===
    # Fields for ContractTokenManagerDetails
    # Field: issuance_limit Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)
    # Field: issued_tokens Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)
    # Field: previous_contract_token_manager_id Type: 9 ()
    # Field: account_status Type: 14 (.google.cloud.universalledger.v1.AccountStatus)

# === Message: Google::Cloud::Universalledger::V1::Query::UserDetails ===
    # Fields for UserDetails
    # Field: account_manager_id Type: 9 ()
    # Field: token_manager_id Type: 9 ()
    # Field: roles Type: 14 (.google.cloud.universalledger.v1.Role)
    # Field: account_status Type: 14 (.google.cloud.universalledger.v1.AccountStatus)
    # Field: balance Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)
    # Field: contract_account_fields Type: 11 (.google.cloud.universalledger.v1.UserDetails.ContractAccountFieldsEntry)

# === Message: Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails ===
    # Fields for CurrencyOperatorDetails
    # Field: currency_code Type: 9 ()
    # Field: account_status Type: 14 (.google.cloud.universalledger.v1.AccountStatus)
    # Field: previous_currency_operator_id Type: 9 ()
    # Field: platform_operator_id Type: 9 ()
    # Field: contract_token_manager_id Type: 9 ()
    # Field: clearinghouse_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails ===
    # Fields for PlatformOperatorDetails
    # Field: account_status Type: 14 (.google.cloud.universalledger.v1.AccountStatus)
    # Field: previous_platform_operator_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails ===
    # Fields for ClearingHouseDetails
    # Field: account_status Type: 14 (.google.cloud.universalledger.v1.AccountStatus)
    # Field: balances Type: 11 (.google.cloud.universalledger.v1.BalanceToSettle)
    # Field: settlement_mode Type: 14 (.google.cloud.universalledger.v1.SettlementMode)

# === Message: Google::Cloud::Universalledger::V1::Query::ContractDetails ===
    # Fields for ContractDetails
    # Field: owner_id Type: 9 ()
    # Field: code Type: 12 ()
    # Field: contract_fields Type: 11 (.google.cloud.universalledger.v1.Fields)
    # Field: currency_balances Type: 11 (.google.cloud.universalledger.v1.ContractDetails.CurrencyBalancesEntry)

# === Message: Google::Cloud::Universalledger::V1::Query::BalanceToSettle ===
    # Fields for BalanceToSettle
    # Field: balance_payer_id Type: 9 ()
    # Field: balance_receiver_id Type: 9 ()
    # Field: balance Type: 11 (.google.cloud.universalledger.v1.CurrencyValue)

# === Message: Google::Cloud::Universalledger::V1::Query::Fields ===
    # Fields for Fields
    # Field: fields Type: 11 (.google.cloud.universalledger.v1.Fields.FieldsEntry)

# === Message: Google::Cloud::Universalledger::V1::Query::RedactedField ===
    # Fields for RedactedField
    # Field: redacted_path Type: 11 (.google.protobuf.FieldMask)
    # Field: reason Type: 9 ()
    # Field: reason_code Type: 14 (.google.rpc.Code)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Universalledger::V1::Query - Compiled Protocol Buffers messages for google/cloud/universalledger/v1/query.proto

=head1 SYNOPSIS

    use Google::Cloud::Universalledger::V1::Query;

    my $msg = Google::Cloud::Universalledger::V1::Query::Account->new({
        user_details => $user_details,
        account_manager_details => $account_manager_details,
        token_manager_details => $token_manager_details,
        contract_token_manager_details => $contract_token_manager_details,
    });

    # Read or update a field
    my $val = $msg->user_details();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Universalledger::V1::Query::Account->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/universalledger/v1/query.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Universalledger::V1::Query::Account

Represents the state of an account on the ledger.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_details() >> / C<< $msg->user_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::UserDetails>)

Output only. Details for a standard user account.

=item * C<< $msg->account_manager_details() >> / C<< $msg->account_manager_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::AccountManagerDetails>)

Output only. Details for an account manager account.

=item * C<< $msg->token_manager_details() >> / C<< $msg->token_manager_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::TokenManagerDetails>)

Output only. Details for a token manager account.

=item * C<< $msg->contract_token_manager_details() >> / C<< $msg->contract_token_manager_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails>)

Output only. Details for a contract token manager account.

=item * C<< $msg->contract_details() >> / C<< $msg->contract_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::ContractDetails>)

Output only. Details for a smart contract account.

=item * C<< $msg->clearinghouse_details() >> / C<< $msg->clearinghouse_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails>)

Output only. Details for a clearinghouse account.

=item * C<< $msg->currency_operator_details() >> / C<< $msg->currency_operator_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails>)

Output only. Details for a currency operator account.

=item * C<< $msg->platform_operator_details() >> / C<< $msg->platform_operator_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails>)

Output only. Details for a platform operator account.

=item * C<< $msg->sequence_number() >> / C<< $msg->sequence_number($value) >>

Type: C<Int64>

Output only. The sequence number of this account. This number increments
with each transaction sent by this account.

=item * C<< $msg->public_key() >> / C<< $msg->public_key($value) >>

Type: C<Bytes>

Output only. The primary public key associated with this account, used for
signature verification.

=item * C<< $msg->round_id() >> / C<< $msg->round_id($value) >>

Type: C<Int64>

Output only. The ID of the execution round (similar to block "height") at
which the account information provided is accurate.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<String>

Output only. The account comment stored when this account was created.

=back

=head2 Google::Cloud::Universalledger::V1::Query::AccountManagerDetails

Details specific to an Account Manager.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->num_accounts() >> / C<< $msg->num_accounts($value) >>

Type: C<Int32>

Output only. The number of accounts created by this account manager.

=item * C<< $msg->token_manager_id() >> / C<< $msg->token_manager_id($value) >>

Type: C<String>

Output only. The ID of the default token manager for accounts created by
this account manager.

=back

=head2 Google::Cloud::Universalledger::V1::Query::TokenManagerDetails

Details specific to a Token Manager.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->issuance_limit() >> / C<< $msg->issuance_limit($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The amount of tokens this token manager is allowed to mint.

=item * C<< $msg->issued_tokens() >> / C<< $msg->issued_tokens($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The amount of tokens minted by this token manager.
This number will increase when minting and decrease when burning.

=back

=head2 Google::Cloud::Universalledger::V1::Query::ContractTokenManagerDetails

Details specific to a Contract Token Manager.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->issuance_limit() >> / C<< $msg->issuance_limit($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The amount of tokens this contract token manager is allowed
to provide backing for.

Since contract token managers cannot increase or decrease
their issuance limit, this should equal the `issued_tokens`.

=item * C<< $msg->issued_tokens() >> / C<< $msg->issued_tokens($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The amount of tokens this contract token manager is
providing backing for (that is, its total liability).

This equals to the sum of all balances held in contracts for its currency,
plus its net position in the settlement matrix.

=item * C<< $msg->previous_contract_token_manager_id() >> / C<< $msg->previous_contract_token_manager_id($value) >>

Type: C<String>

Output only. The account ID of the previous contract token manager for this
currency. This forms an audit trail that can be traversed to discover all
previous managers. If this is the first contract token manager for the
currency, this will be empty.

=item * C<< $msg->account_status() >> / C<< $msg->account_status($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::AccountStatus>)

Output only. The status of this account.

=back

=head2 Google::Cloud::Universalledger::V1::Query::UserDetails

Details specific to a User account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account_manager_id() >> / C<< $msg->account_manager_id($value) >>

Type: C<String>

Output only. The ID of the account manager for this user.

=item * C<< $msg->token_manager_id() >> / C<< $msg->token_manager_id($value) >>

Type: C<String>

Output only. The ID of the token manager for this user.

=item * C<< $msg->roles() >> / C<< $msg->roles($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::Role>)

Output only. The list of roles granted to this account.

=item * C<< $msg->account_status() >> / C<< $msg->account_status($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::AccountStatus>)

Output only. The status of this account.

=item * C<< $msg->balance() >> / C<< $msg->balance($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The token balance of this user account.

=item * C<< $msg->contract_account_fields() >> / C<< $msg->contract_account_fields($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::UserDetails::ContractAccountFieldsEntry>)

Output only. The contract account fields (contract ID -> fields) for this
user.

=back

=head2 Google::Cloud::Universalledger::V1::Query::CurrencyOperatorDetails

Details specific to a Currency Operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

Output only. The ID of the currency associated with this account,
represented by the 3-letter ISO 4217 code.

=item * C<< $msg->account_status() >> / C<< $msg->account_status($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::AccountStatus>)

Output only. The status of this account.

=item * C<< $msg->previous_currency_operator_id() >> / C<< $msg->previous_currency_operator_id($value) >>

Type: C<String>

Output only. The ID of the previous currency operator which transferred
ownership of the currency operator role to this account. If this is the
first currency operator for the currency, this will be empty.

=item * C<< $msg->platform_operator_id() >> / C<< $msg->platform_operator_id($value) >>

Type: C<String>

Output only. The ID of the platform operator which created this currency
operator.

=item * C<< $msg->contract_token_manager_id() >> / C<< $msg->contract_token_manager_id($value) >>

Type: C<String>

Output only. The ID of the contract token manager associated with this
currency operator.

=item * C<< $msg->clearinghouse_id() >> / C<< $msg->clearinghouse_id($value) >>

Type: C<String>

Output only. The ID of the clearinghouse associated with this currency
operator.

=back

=head2 Google::Cloud::Universalledger::V1::Query::PlatformOperatorDetails

Details specific to a Platform Operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account_status() >> / C<< $msg->account_status($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::AccountStatus>)

Output only. The status of this account.

=item * C<< $msg->previous_platform_operator_id() >> / C<< $msg->previous_platform_operator_id($value) >>

Type: C<String>

Output only. The ID of the previous platform operator which transferred
ownership of the platform operator role to this account. If this is the
first platform operator, this will be empty.

=back

=head2 Google::Cloud::Universalledger::V1::Query::ClearingHouseDetails

Details specific to a Clearinghouse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account_status() >> / C<< $msg->account_status($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::AccountStatus>)

Output only. The status of this account.

=item * C<< $msg->balances() >> / C<< $msg->balances($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::BalanceToSettle>)

Output only. The balances that this clearinghouse is currently tracking for
settlement.

=item * C<< $msg->settlement_mode() >> / C<< $msg->settlement_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::SettlementMode>)

Output only. The settlement mode of this clearinghouse.

=back

=head2 Google::Cloud::Universalledger::V1::Query::ContractDetails

Details specific to a Smart Contract.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->owner_id() >> / C<< $msg->owner_id($value) >>

Type: C<String>

Output only. The ID of the owner of the contract.

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Bytes>

Output only. The serialized contract code.

=item * C<< $msg->contract_fields() >> / C<< $msg->contract_fields($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::Fields>)

Output only. The contract fields (field name -> value) for this contract.

=item * C<< $msg->currency_balances() >> / C<< $msg->currency_balances($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::ContractDetails::CurrencyBalancesEntry>)

Output only. The currency balances held by the contract (currency operator
-> balance).

=back

=head2 Google::Cloud::Universalledger::V1::Query::BalanceToSettle

A balance to settle between two token managers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->balance_payer_id() >> / C<< $msg->balance_payer_id($value) >>

Type: C<String>

Output only. The ID of the account which owes the balance to be settled.

=item * C<< $msg->balance_receiver_id() >> / C<< $msg->balance_receiver_id($value) >>

Type: C<String>

Output only. The ID of the account which is owed the balance to be settled.

=item * C<< $msg->balance() >> / C<< $msg->balance($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::CurrencyValue>)

Output only. The balance to settle. Must be positive.

=back

=head2 Google::Cloud::Universalledger::V1::Query::Fields

A map of fields (field name -> value) from a contract used to represent
contract fields or account fields.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::Fields::FieldsEntry>)

Output only. The map of field names to their values.

=back

=head2 Google::Cloud::Universalledger::V1::Query::RedactedField

Information about a redacted field in the response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->redacted_path() >> / C<< $msg->redacted_path($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Output only. The fully qualified field paths that were redacted from the
payload.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Output only. A human-readable explanation of why the fields were redacted.

=item * C<< $msg->reason_code() >> / C<< $msg->reason_code($value) >>

Type: C<Enum> (L<Google::Rpc::Code>)

Output only. A machine readable code for why the fields were redacted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Universalledger::V1::Query::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
