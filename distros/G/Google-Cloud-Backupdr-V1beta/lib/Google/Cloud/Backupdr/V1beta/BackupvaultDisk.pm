package Google::Cloud::Backupdr::V1beta::BackupvaultDisk;

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
    eval { require Google::Cloud::Backupdr::V1beta::BackupvaultGce };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2JhY2t1cHZhdWx0X2Rpc2sucHJvdG8S
HGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2dsZS9jbG91ZC9iYWNr
dXBkci92MWJldGEvYmFja3VwdmF1bHRfZ2NlLnByb3RvIrgBChVEaXNrVGFyZ2V0RW52aXJv
bm1lbnQSHQoHcHJvamVjdBgBIAEoCUID4EECUgdwcm9qZWN0EhcKBHpvbmUYAiABKAlCA+BB
AlIEem9uZRJHCht1c2VfcHJvamVjdF9zZXJ2aWNlX2FjY291bnQYAyABKAhCA+BBAUgAUhh1
c2VQcm9qZWN0U2VydmljZUFjY291bnSIAQFCHgocX3VzZV9wcm9qZWN0X3NlcnZpY2VfYWNj
b3VudCLsAQobUmVnaW9uRGlza1RhcmdldEVudmlyb25tZW50Eh0KB3Byb2plY3QYASABKAlC
A+BBAlIHcHJvamVjdBIbCgZyZWdpb24YAiABKAlCA+BBAlIGcmVnaW9uEigKDXJlcGxpY2Ff
em9uZXMYAyADKAlCA+BBAlIMcmVwbGljYVpvbmVzEkcKG3VzZV9wcm9qZWN0X3NlcnZpY2Vf
YWNjb3VudBgEIAEoCEID4EEBSABSGHVzZVByb2plY3RTZXJ2aWNlQWNjb3VudIgBAUIeChxf
dXNlX3Byb2plY3Rfc2VydmljZV9hY2NvdW50ItsOChVEaXNrUmVzdG9yZVByb3BlcnRpZXMS
dAoWaW5zdGFuY2VfYmFja3VwX3NvdXJjZRgTIAEoCzI8Lmdvb2dsZS5jbG91ZC5iYWNrdXBk
ci52MWJldGEuUmVzdG9yZURpc2tGcm9tSW5zdGFuY2VPcHRpb25zSABSFGluc3RhbmNlQmFj
a3VwU291cmNlEhwKBG5hbWUYASABKAlCA+BBAkgBUgRuYW1liAEBEioKC2Rlc2NyaXB0aW9u
GAIgASgJQgPgQQFIAlILZGVzY3JpcHRpb26IAQESIQoHc2l6ZV9nYhgDIAEoA0ID4EECSANS
BnNpemVHYogBARIfCghsaWNlbnNlcxgEIAMoCUID4EEBUghsaWNlbnNlcxJbChBndWVzdF9v
c19mZWF0dXJlGAUgAygLMiwuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5HdWVzdE9z
RmVhdHVyZUID4EEBUg5ndWVzdE9zRmVhdHVyZRJtChNkaXNrX2VuY3J5cHRpb25fa2V5GAYg
ASgLMjMuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5DdXN0b21lckVuY3J5cHRpb25L
ZXlCA+BBAUgEUhFkaXNrRW5jcnlwdGlvbktleYgBARJDChlwaHlzaWNhbF9ibG9ja19zaXpl
X2J5dGVzGAcgASgDQgPgQQFIBVIWcGh5c2ljYWxCbG9ja1NpemVCeXRlc4gBARIzChBwcm92
aXNpb25lZF9pb3BzGAggASgDQgPgQQFIBlIPcHJvdmlzaW9uZWRJb3BziAEBEj8KFnByb3Zp
c2lvbmVkX3Rocm91Z2hwdXQYCSABKANCA+BBAUgHUhVwcm92aXNpb25lZFRocm91Z2hwdXSI
AQESSAobZW5hYmxlX2NvbmZpZGVudGlhbF9jb21wdXRlGAogASgIQgPgQQFICFIZZW5hYmxl
Q29uZmlkZW50aWFsQ29tcHV0ZYgBARJSCgxzdG9yYWdlX3Bvb2wYCyABKAlCKuBBAfpBJAoi
Y29tcHV0ZS5nb29nbGVhcGlzLmNvbS9TdG9yYWdlUG9vbEgJUgtzdG9yYWdlUG9vbIgBARJp
CgthY2Nlc3NfbW9kZRgMIAEoDjI+Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuRGlz
a1Jlc3RvcmVQcm9wZXJ0aWVzLkFjY2Vzc01vZGVCA+BBAUgKUgphY2Nlc3NNb2RliAEBEm4K
DGFyY2hpdGVjdHVyZRgOIAEoDjJALmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuRGlz
a1Jlc3RvcmVQcm9wZXJ0aWVzLkFyY2hpdGVjdHVyZUID4EEBSAtSDGFyY2hpdGVjdHVyZYgB
ARIsCg9yZXNvdXJjZV9wb2xpY3kYDyADKAlCA+BBAVIOcmVzb3VyY2VQb2xpY3kSHAoEdHlw
ZRgQIAEoCUID4EECSAxSBHR5cGWIAQESXAoGbGFiZWxzGBEgAygLMj8uZ29vZ2xlLmNsb3Vk
LmJhY2t1cGRyLnYxYmV0YS5EaXNrUmVzdG9yZVByb3BlcnRpZXMuTGFiZWxzRW50cnlCA+BB
AVIGbGFiZWxzEoUBChVyZXNvdXJjZV9tYW5hZ2VyX3RhZ3MYEiADKAsyTC5nb29nbGUuY2xv
dWQuYmFja3VwZHIudjFiZXRhLkRpc2tSZXN0b3JlUHJvcGVydGllcy5SZXNvdXJjZU1hbmFn
ZXJUYWdzRW50cnlCA+BBAVITcmVzb3VyY2VNYW5hZ2VyVGFncxo5CgtMYWJlbHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGkYKGFJlc291cmNl
TWFuYWdlclRhZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIkwKCkFjY2Vzc01vZGUSFQoRUkVBRF9XUklURV9TSU5HTEUQABITCg9SRUFEX1dS
SVRFX01BTlkQARISCg5SRUFEX09OTFlfTUFOWRACIkMKDEFyY2hpdGVjdHVyZRIcChhBUkNI
SVRFQ1RVUkVfVU5TUEVDSUZJRUQQABIKCgZYODZfNjQQARIJCgVBUk02NBACQhAKDnNvdXJj
ZV9vcHRpb25zQgcKBV9uYW1lQg4KDF9kZXNjcmlwdGlvbkIKCghfc2l6ZV9nYkIWChRfZGlz
a19lbmNyeXB0aW9uX2tleUIcChpfcGh5c2ljYWxfYmxvY2tfc2l6ZV9ieXRlc0ITChFfcHJv
dmlzaW9uZWRfaW9wc0IZChdfcHJvdmlzaW9uZWRfdGhyb3VnaHB1dEIeChxfZW5hYmxlX2Nv
bmZpZGVudGlhbF9jb21wdXRlQg8KDV9zdG9yYWdlX3Bvb2xCDgoMX2FjY2Vzc19tb2RlQg8K
DV9hcmNoaXRlY3R1cmVCBwoFX3R5cGUifgoeUmVzdG9yZURpc2tGcm9tSW5zdGFuY2VPcHRp
b25zEi4KEnNvdXJjZV9kZXZpY2VfbmFtZRgBIAEoCUgAUhBzb3VyY2VEZXZpY2VOYW1lEh0K
CWJvb3RfZGlzaxgCIAEoCEgAUghib290RGlza0INCgtzb3VyY2VfZGlzayL5CQoURGlza0Jh
Y2t1cFByb3BlcnRpZXMSJQoLZGVzY3JpcHRpb24YASABKAlIAFILZGVzY3JpcHRpb26IAQES
GgoIbGljZW5zZXMYAiADKAlSCGxpY2Vuc2VzElYKEGd1ZXN0X29zX2ZlYXR1cmUYAyADKAsy
LC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkd1ZXN0T3NGZWF0dXJlUg5ndWVzdE9z
RmVhdHVyZRJoCgxhcmNoaXRlY3R1cmUYBCABKA4yPy5nb29nbGUuY2xvdWQuYmFja3VwZHIu
djFiZXRhLkRpc2tCYWNrdXBQcm9wZXJ0aWVzLkFyY2hpdGVjdHVyZUgBUgxhcmNoaXRlY3R1
cmWIAQESFwoEdHlwZRgFIAEoCUgCUgR0eXBliAEBEhwKB3NpemVfZ2IYBiABKANIA1IGc2l6
ZUdiiAEBEhsKBnJlZ2lvbhgHIAEoCUgEUgZyZWdpb26IAQESFwoEem9uZRgIIAEoCUgFUgR6
b25liAEBEiMKDXJlcGxpY2Ffem9uZXMYCSADKAlSDHJlcGxpY2Fab25lcxIkCgtzb3VyY2Vf
ZGlzaxgKIAEoCUgGUgpzb3VyY2VEaXNriAEBEiQKC2FjY2Vzc19tb2RlGAsgASgJSAdSCmFj
Y2Vzc01vZGWIAQESLgoQcHJvdmlzaW9uZWRfaW9wcxgMIAEoA0gIUg9wcm92aXNpb25lZElv
cHOIAQESOgoWcHJvdmlzaW9uZWRfdGhyb3VnaHB1dBgNIAEoA0gJUhVwcm92aXNpb25lZFRo
cm91Z2hwdXSIAQESPgoZcGh5c2ljYWxfYmxvY2tfc2l6ZV9ieXRlcxgOIAEoA0gKUhZwaHlz
aWNhbEJsb2NrU2l6ZUJ5dGVziAEBEkMKG2VuYWJsZV9jb25maWRlbnRpYWxfY29tcHV0ZRgP
IAEoCEgLUhllbmFibGVDb25maWRlbnRpYWxDb21wdXRliAEBEiYKDHN0b3JhZ2VfcG9vbBgQ
IAEoCUgMUgtzdG9yYWdlUG9vbIgBARJWCgZsYWJlbHMYESADKAsyPi5nb29nbGUuY2xvdWQu
YmFja3VwZHIudjFiZXRhLkRpc2tCYWNrdXBQcm9wZXJ0aWVzLkxhYmVsc0VudHJ5UgZsYWJl
bHMSJAoLZ3Vlc3RfZmx1c2gYEiABKAhCA+BBAVIKZ3Vlc3RGbHVzaBo5CgtMYWJlbHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIkMKDEFyY2hp
dGVjdHVyZRIcChhBUkNISVRFQ1RVUkVfVU5TUEVDSUZJRUQQABIKCgZYODZfNjQQARIJCgVB
Uk02NBACQg4KDF9kZXNjcmlwdGlvbkIPCg1fYXJjaGl0ZWN0dXJlQgcKBV90eXBlQgoKCF9z
aXplX2diQgkKB19yZWdpb25CBwoFX3pvbmVCDgoMX3NvdXJjZV9kaXNrQg4KDF9hY2Nlc3Nf
bW9kZUITChFfcHJvdmlzaW9uZWRfaW9wc0IZChdfcHJvdmlzaW9uZWRfdGhyb3VnaHB1dEIc
ChpfcGh5c2ljYWxfYmxvY2tfc2l6ZV9ieXRlc0IeChxfZW5hYmxlX2NvbmZpZGVudGlhbF9j
b21wdXRlQg8KDV9zdG9yYWdlX3Bvb2wifQoYRGlza0RhdGFTb3VyY2VQcm9wZXJ0aWVzEhIK
BG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEhIK
BHR5cGUYAyABKAlSBHR5cGUSFwoHc2l6ZV9nYhgEIAEoA1IGc2l6ZUdiQrwCCiBjb20uZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YUIUQmFja3VwdmF1bHREaXNrUHJvdG9QAVo8Y2xv
dWQuZ29vZ2xlLmNvbS9nby9iYWNrdXBkci9hcGl2MWJldGEvYmFja3VwZHJwYjtiYWNrdXBk
cnBiqgIcR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxQmV0YcoCHEdvb2dsZVxDbG91ZFxCYWNr
dXBEUlxWMWJldGHqAh9Hb29nbGU6OkNsb3VkOjpCYWNrdXBEUjo6VjFiZXRh6kFhCiJjb21w
dXRlLmdvb2dsZWFwaXMuY29tL1N0b3JhZ2VQb29sEjtwcm9qZWN0cy97cHJvamVjdH0vem9u
ZXMve3pvbmV9L3N0b3JhZ2VQb29scy97c3RvcmFnZV9wb29sfUrjUgoHEgUOAJcCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAPAoICgEIEgMWADkKCQoCCCUSAxYAOQoICgEIEgMXAFMKCQoC
CAsSAxcAUwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADUKCQoCCAgSAxkANQoICgEI
EgMaADkKCQoCCAESAxoAOQoICgEIEgMbADkKCQoCCCkSAxsAOQoICgEIEgMcADgKCQoCCC0S
AxwAOAoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKUwoCBAASBCMALQEaRyBEaXNrVGFyZ2V0
RW52aXJvbm1lbnQgcmVwcmVzZW50cyB0aGUgdGFyZ2V0IGVudmlyb25tZW50IGZvciB0aGUg
ZGlzay4KCgoKAwQAARIDIwgdCjUKBAQAAgASAyUCPhooIFJlcXVpcmVkLiBUYXJnZXQgcHJv
amVjdCBmb3IgdGhlIGRpc2suCgoMCgUEAAIABRIDJQIICgwKBQQAAgABEgMlCRAKDAoFBAAC
AAMSAyUTFAoMCgUEAAIACBIDJRU9Cg8KCAQAAgAInAgAEgMlFjwKMgoEBAACARIDKAI7GiUg
UmVxdWlyZWQuIFRhcmdldCB6b25lIGZvciB0aGUgZGlzay4KCgwKBQQAAgEFEgMoAggKDAoF
BAACAQESAygJDQoMCgUEAAIBAxIDKBARCgwKBQQAAgEIEgMoEjoKDwoIBAACAQicCAASAygT
OQpaCgQEAAICEgQrAiwvGkwgT3B0aW9uYWwuIFdoZXRoZXIgdG8gdXNlIHRoZSBwcm9qZWN0
IHNlcnZpY2UgYWNjb3VudCBmb3IgdGhlIGRpc2sgcmVzdG9yZS4KCgwKBQQAAgIEEgMrAgoK
DAoFBAACAgUSAysLDwoMCgUEAAICARIDKxArCgwKBQQAAgIDEgMrLi8KDAoFBAACAggSAywG
LgoPCggEAAICCJwIABIDLActClkKAgQBEgQwAD0BGk0gUmVnaW9uRGlza1RhcmdldEVudmly
b25tZW50IHJlcHJlc2VudHMgdGhlIHRhcmdldCBlbnZpcm9ubWVudCBmb3IgdGhlIGRpc2su
CgoKCgMEAQESAzAIIwo1CgQEAQIAEgMyAj4aKCBSZXF1aXJlZC4gVGFyZ2V0IHByb2plY3Qg
Zm9yIHRoZSBkaXNrLgoKDAoFBAECAAUSAzICCAoMCgUEAQIAARIDMgkQCgwKBQQBAgADEgMy
ExQKDAoFBAECAAgSAzIVPQoPCggEAQIACJwIABIDMhY8CjQKBAQBAgESAzUCPRonIFJlcXVp
cmVkLiBUYXJnZXQgcmVnaW9uIGZvciB0aGUgZGlzay4KCgwKBQQBAgEFEgM1AggKDAoFBAEC
AQESAzUJDwoMCgUEAQIBAxIDNRITCgwKBQQBAgEIEgM1FDwKDwoIBAECAQicCAASAzUVOwpH
CgQEAQICEgM4Ak0aOiBSZXF1aXJlZC4gVGFyZ2V0IFVSTHMgb2YgdGhlIHJlcGxpY2Egem9u
ZXMgZm9yIHRoZSBkaXNrLgoKDAoFBAECAgQSAzgCCgoMCgUEAQICBRIDOAsRCgwKBQQBAgIB
EgM4Eh8KDAoFBAECAgMSAzgiIwoMCgUEAQICCBIDOCRMCg8KCAQBAgIInAgAEgM4JUsKWgoE
BAECAxIEOwI8LxpMIE9wdGlvbmFsLiBXaGV0aGVyIHRvIHVzZSB0aGUgcHJvamVjdCBzZXJ2
aWNlIGFjY291bnQgZm9yIHRoZSBkaXNrIHJlc3RvcmUuCgoMCgUEAQIDBBIDOwIKCgwKBQQB
AgMFEgM7Cw8KDAoFBAECAwESAzsQKwoMCgUEAQIDAxIDOy4vCgwKBQQBAgMIEgM8Bi4KDwoI
BAECAwicCAASAzwHLQpRCgIEAhIFQACvAQEaRCBEaXNrUmVzdG9yZVByb3BlcnRpZXMgcmVw
cmVzZW50cyB0aGUgcHJvcGVydGllcyBvZiBhIERpc2sgcmVzdG9yZS4KCgoKAwQCARIDQAgd
CjcKBAQCBAASBEICTgMaKSBUaGUgc3VwcG9ydGVkIGFjY2VzcyBtb2RlcyBvZiB0aGUgZGlz
ay4KCgwKBQQCBAABEgNCBxEKZwoGBAIEAAIAEgNFBBoaWCBUaGUgZGVmYXVsdCBBY2Nlc3NN
b2RlLCBtZWFucyB0aGUgZGlzayBjYW4gYmUgYXR0YWNoZWQgdG8gc2luZ2xlIGluc3RhbmNl
CiBpbiBSVyBtb2RlLgoKDgoHBAIEAAIAARIDRQQVCg4KBwQCBAACAAISA0UYGQphCgYEAgQA
AgESA0kEGBpSIFRoZSBBY2Nlc3NNb2RlIG1lYW5zIHRoZSBkaXNrIGNhbiBiZSBhdHRhY2hl
ZCB0byBtdWx0aXBsZSBpbnN0YW5jZXMgaW4gUlcKIG1vZGUuCgoOCgcEAgQAAgEBEgNJBBMK
DgoHBAIEAAIBAhIDSRYXCmEKBgQCBAACAhIDTQQXGlIgVGhlIEFjY2Vzc01vZGUgbWVhbnMg
dGhlIGRpc2sgY2FuIGJlIGF0dGFjaGVkIHRvIG11bHRpcGxlIGluc3RhbmNlcyBpbiBSTwog
bW9kZS4KCg4KBwQCBAACAgESA00EEgoOCgcEAgQAAgICEgNNFRYKMAoEBAIEARIEUQJaAxoi
IEFyY2hpdGVjdHVyZSBvZiB0aGUgc291cmNlIGRpc2suCgoMCgUEAgQBARIDUQcTCjUKBgQC
BAECABIDUwQhGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcE
AgQBAgABEgNTBBwKDgoHBAIEAQIAAhIDUx8gCi8KBgQCBAECARIDVgQPGiAgRGlza3Mgd2l0
aCBhcmNoaXRlY3R1cmUgWDg2XzY0CgoOCgcEAgQBAgEBEgNWBAoKDgoHBAIEAQIBAhIDVg0O
Ci4KBgQCBAECAhIDWQQOGh8gRGlza3Mgd2l0aCBhcmNoaXRlY3R1cmUgQVJNNjQKCg4KBwQC
BAECAgESA1kECQoOCgcEAgQBAgICEgNZDA0KcAoEBAIIABIEXgJhAxpiIFNwZWNpZmllcyB0
aGUgc291cmNlIG9mIHRoZSByZXN0b3JlLgogVGhpcyBpcyByZXF1aXJlZCBmb3Igc2VsZWN0
aXZlIG9yIGNyb3NzLXdvcmtsb2FkIHJlc3RvcmVzLgoKDAoFBAIIAAESA14IFgpRCgQEAgIA
EgNgBD8aRCBPcHRpb25zIGZvciBjcmVhdGluZyBhIGRpc2sgZnJvbSBhIHNvdXJjZSBDb21w
dXRlIEluc3RhbmNlIGJhY2t1cC4KCgwKBQQCAgAGEgNgBCIKDAoFBAICAAESA2AjOQoMCgUE
AgIAAxIDYDw+CioKBAQCAgESA2QCRBodIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBkaXNrLgoK
DAoFBAICAQQSA2QCCgoMCgUEAgIBBRIDZAsRCgwKBQQCAgEBEgNkEhYKDAoFBAICAQMSA2QZ
GgoMCgUEAgIBCBIDZBtDCg8KCAQCAgEInAgAEgNkHEIKdwoEBAICAhIDaAJLGmogT3B0aW9u
YWwuIEFuIG9wdGlvbmFsIGRlc2NyaXB0aW9uIG9mIHRoaXMgcmVzb3VyY2UuIFByb3ZpZGUg
dGhpcyBwcm9wZXJ0eQogd2hlbiB5b3UgY3JlYXRlIHRoZSByZXNvdXJjZS4KCgwKBQQCAgIE
EgNoAgoKDAoFBAICAgUSA2gLEQoMCgUEAgICARIDaBIdCgwKBQQCAgIDEgNoICEKDAoFBAIC
AggSA2giSgoPCggEAgICCJwIABIDaCNJCjQKBAQCAgMSA2sCRhonIFJlcXVpcmVkLiBUaGUg
c2l6ZSBvZiB0aGUgZGlzayBpbiBHQi4KCgwKBQQCAgMEEgNrAgoKDAoFBAICAwUSA2sLEAoM
CgUEAgIDARIDaxEYCgwKBQQCAgMDEgNrGxwKDAoFBAICAwgSA2sdRQoPCggEAgIDCJwIABID
ax5ECrgBCgQEAgIEEgNwAkgaqgEgT3B0aW9uYWwuIEEgbGlzdCBvZiBwdWJsaWNseSBhdmFp
bGFibGUgbGljZW5zZXMgdGhhdCBhcmUgYXBwbGljYWJsZSB0byB0aGlzCiBiYWNrdXAuIFRo
aXMgaXMgYXBwbGljYWJsZSBpZiB0aGUgb3JpZ2luYWwgaW1hZ2UgaGFkIGxpY2Vuc2VzIGF0
dGFjaGVkLAogZS5nLiBXaW5kb3dzIGltYWdlCgoMCgUEAgIEBBIDcAIKCgwKBQQCAgQFEgNw
CxEKDAoFBAICBAESA3ASGgoMCgUEAgIEAxIDcB0eCgwKBQQCAgQIEgNwH0cKDwoIBAICBAic
CAASA3AgRgqDAQoEBAICBRIEdAJ1Lxp1IE9wdGlvbmFsLiBBIGxpc3Qgb2YgZmVhdHVyZXMg
dG8gZW5hYmxlIGluIHRoZSBndWVzdCBvcGVyYXRpbmcgc3lzdGVtLiBUaGlzCiBpcyBhcHBs
aWNhYmxlIG9ubHkgZm9yIGJvb3RhYmxlIGltYWdlcy4KCgwKBQQCAgUEEgN0AgoKDAoFBAIC
BQYSA3QLGQoMCgUEAgIFARIDdBoqCgwKBQQCAgUDEgN0LS4KDAoFBAICBQgSA3UGLgoPCggE
AgIFCJwIABIDdQctCnsKBAQCAgYSBHkCei8abSBPcHRpb25hbC4gRW5jcnlwdHMgdGhlIGRp
c2sgdXNpbmcgYQogY3VzdG9tZXItc3VwcGxpZWQgZW5jcnlwdGlvbiBrZXkgb3IgYSBjdXN0
b21lci1tYW5hZ2VkIGVuY3J5cHRpb24ga2V5LgoKDAoFBAICBgQSA3kCCgoMCgUEAgIGBhID
eQsgCgwKBQQCAgYBEgN5ITQKDAoFBAICBgMSA3k3OAoMCgUEAgIGCBIDegYuCg8KCAQCAgYI
nAgAEgN6By0KsAEKBAQCAgcSBX8CgAEvGqABIE9wdGlvbmFsLiBQaHlzaWNhbCBibG9jayBz
aXplIG9mIHRoZSBwZXJzaXN0ZW50IGRpc2ssIGluIGJ5dGVzLgogSWYgbm90IHByZXNlbnQg
aW4gYSByZXF1ZXN0LCBhIGRlZmF1bHQgdmFsdWUgaXMgdXNlZC4KIEN1cnJlbnRseSwgdGhl
IHN1cHBvcnRlZCBzaXplIGlzIDQwOTYuCgoMCgUEAgIHBBIDfwIKCgwKBQQCAgcFEgN/CxAK
DAoFBAICBwESA38RKgoMCgUEAgIHAxIDfy0uCg0KBQQCAgcIEgSAAQYuChAKCAQCAgcInAgA
EgSAAQctCpoBCgQEAgIIEgSEAQJPGosBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaG93IG1hbnkg
SU9QUyB0byBwcm92aXNpb24gZm9yIHRoZSBkaXNrLiBUaGlzIHNldHMgdGhlCiBudW1iZXIg
b2YgSS9PIG9wZXJhdGlvbnMgcGVyIHNlY29uZCB0aGF0IHRoZSBkaXNrIGNhbiBoYW5kbGUu
CgoNCgUEAgIIBBIEhAECCgoNCgUEAgIIBRIEhAELEAoNCgUEAgIIARIEhAERIQoNCgUEAgII
AxIEhAEkJQoNCgUEAgIICBIEhAEmTgoQCggEAgIICJwIABIEhAEnTQqhAQoEBAICCRIGiAEC
iQEvGpABIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaG93IG11Y2ggdGhyb3VnaHB1dCB0byBwcm92
aXNpb24gZm9yIHRoZSBkaXNrLiBUaGlzCiBzZXRzIHRoZSBudW1iZXIgb2YgdGhyb3VnaHB1
dCBNQiBwZXIgc2Vjb25kIHRoYXQgdGhlIGRpc2sgY2FuIGhhbmRsZS4KCg0KBQQCAgkEEgSI
AQIKCg0KBQQCAgkFEgSIAQsQCg0KBQQCAgkBEgSIAREnCg0KBQQCAgkDEgSIASorCg0KBQQC
AgkIEgSJAQYuChAKCAQCAgkInAgAEgSJAQctCqABCgQEAgIKEgaNAQKOAS8ajwEgT3B0aW9u
YWwuIEluZGljYXRlcyB3aGV0aGVyIHRoaXMgZGlzayBpcyB1c2luZyBjb25maWRlbnRpYWwg
Y29tcHV0ZSBtb2RlLgogRW5jcnlwdGlvbiB3aXRoIGEgQ2xvdWQgS01TIGtleSBpcyByZXF1
aXJlZCB0byBlbmFibGUgdGhpcyBvcHRpb24uCgoNCgUEAgIKBBIEjQECCgoNCgUEAgIKBRIE
jQELDwoNCgUEAgIKARIEjQEQKwoNCgUEAgIKAxIEjQEuMAoNCgUEAgIKCBIEjgEGLgoQCggE
AgIKCJwIABIEjgEHLQqOAQoEBAICCxIGkgEClwEEGn4gT3B0aW9uYWwuIFRoZSBzdG9yYWdl
IHBvb2wgaW4gd2hpY2ggdGhlIG5ldyBkaXNrIGlzIGNyZWF0ZWQuIFlvdSBjYW4KIHByb3Zp
ZGUgdGhpcyBhcyBhIHBhcnRpYWwgb3IgZnVsbCBVUkwgdG8gdGhlIHJlc291cmNlLgoKDQoF
BAICCwQSBJIBAgoKDQoFBAICCwUSBJIBCxEKDQoFBAICCwESBJIBEh4KDQoFBAICCwMSBJIB
ISMKDwoFBAICCwgSBpIBJJcBAwoQCggEAgILCJwIABIEkwEEKgoRCgcEAgILCJ8IEgaUAQSW
AQUKNgoEBAICDBIEmgECUBooIE9wdGlvbmFsLiBUaGUgYWNjZXNzIG1vZGUgb2YgdGhlIGRp
c2suCgoNCgUEAgIMBBIEmgECCgoNCgUEAgIMBhIEmgELFQoNCgUEAgIMARIEmgEWIQoNCgUE
AgIMAxIEmgEkJgoNCgUEAgIMCBIEmgEnTwoQCggEAgIMCJwIABIEmgEoTgpjCgQEAgINEgae
AQKfAS8aUyBPcHRpb25hbC4gVGhlIGFyY2hpdGVjdHVyZSBvZiB0aGUgc291cmNlIGRpc2su
IFZhbGlkIHZhbHVlcyBhcmUKIEFSTTY0IG9yIFg4Nl82NC4KCg0KBQQCAg0EEgSeAQIKCg0K
BQQCAg0GEgSeAQsXCg0KBQQCAg0BEgSeARgkCg0KBQQCAg0DEgSeAScpCg0KBQQCAg0IEgSf
AQYuChAKCAQCAg0InAgAEgSfAQctCkEKBAQCAg4SBKIBAlAaMyBPcHRpb25hbC4gUmVzb3Vy
Y2UgcG9saWNpZXMgYXBwbGllZCB0byB0aGlzIGRpc2suCgoNCgUEAgIOBBIEogECCgoNCgUE
AgIOBRIEogELEQoNCgUEAgIOARIEogESIQoNCgUEAgIOAxIEogEkJgoNCgUEAgIOCBIEogEn
TwoQCggEAgIOCJwIABIEogEoTgpuCgQEAgIPEgSmAQJFGmAgUmVxdWlyZWQuIFVSTCBvZiB0
aGUgZGlzayB0eXBlIHJlc291cmNlIGRlc2NyaWJpbmcgd2hpY2ggZGlzayB0eXBlIHRvIHVz
ZQogdG8gY3JlYXRlIHRoZSBkaXNrLgoKDQoFBAICDwQSBKYBAgoKDQoFBAICDwUSBKYBCxEK
DQoFBAICDwESBKYBEhYKDQoFBAICDwMSBKYBGRsKDQoFBAICDwgSBKYBHEQKEAoIBAICDwic
CAASBKYBHUMKlQEKBAQCAhASBKoBAksahgEgT3B0aW9uYWwuIExhYmVscyB0byBhcHBseSB0
byB0aGlzIGRpc2suIFRoZXNlIGNhbiBiZSBtb2RpZmllZCBsYXRlciB1c2luZwogPGNvZGU+
c2V0TGFiZWxzPC9jb2RlPiBtZXRob2QuIExhYmVsIHZhbHVlcyBjYW4gYmUgZW1wdHkuCgoN
CgUEAgIQBhIEqgECFQoNCgUEAgIQARIEqgEWHAoNCgUEAgIQAxIEqgEfIQoNCgUEAgIQCBIE
qgEiSgoQCggEAgIQCJwIABIEqgEjSQpKCgQEAgIREgatAQKuAS8aOiBPcHRpb25hbC4gUmVz
b3VyY2UgbWFuYWdlciB0YWdzIHRvIGJlIGJvdW5kIHRvIHRoZSBkaXNrLgoKDQoFBAICEQYS
BK0BAhUKDQoFBAICEQESBK0BFisKDQoFBAICEQMSBK0BLjAKDQoFBAICEQgSBK4BBi4KEAoI
BAICEQicCAASBK4BBy0KUgoCBAMSBrIBALwBARpEIE9wdGlvbnMgZm9yIGNyZWF0aW5nIGEg
ZGlzayBmcm9tIGEgc291cmNlIENvbXB1dGUgSW5zdGFuY2UgYmFja3VwLgoKCwoDBAMBEgSy
AQgmCk0KBAQDCAASBrQBArsBAxo9IFJlcXVpcmVkOiBUaGUgZGlzayB0byBiZSByZXN0b3Jl
ZCBmcm9tIHRoZSBpbnN0YW5jZSBiYWNrdXAuCgoNCgUEAwgAARIEtAEIEwpKCgQEAwIAEgS2
AQQiGjwgVGhlIGRldmljZSBuYW1lIG9mIHRoZSBkaXNrIHRvIHJlc3RvcmUgZnJvbSB0aGUg
Vk0gYmFja3VwLgoKDQoFBAMCAAUSBLYBBAoKDQoFBAMCAAESBLYBCx0KDQoFBAMCAAMSBLYB
ICEKggEKBAQDAgESBLoBBBcadCBTZXQgdG8gdHJ1ZSB0byByZXN0b3JlIHRoZSBib290IGRp
c2sgZnJvbSB0aGUgaW5zdGFuY2UgYmFja3VwLgogVGhpcyBmaWVsZCBzaG91bGQgb25seSBi
ZSBzZXQgdG8gdHJ1ZSBpZiBzZWxlY3RlZC4KCg0KBQQDAgEFEgS6AQQICg0KBQQDAgEBEgS6
AQkSCg0KBQQDAgEDEgS6ARUWClAKAgQEEga/AQCGAgEaQiBEaXNrQmFja3VwUHJvcGVydGll
cyByZXByZXNlbnRzIHRoZSBwcm9wZXJ0aWVzIG9mIGEgRGlzayBiYWNrdXAuCgoLCgMEBAES
BL8BCBwKMgoEBAQEABIGwQECygEDGiIgQXJjaGl0ZWN0dXJlIG9mIHRoZSBzb3VyY2UgZGlz
ay4KCg0KBQQEBAABEgTBAQcTCjYKBgQEBAACABIEwwEEIRomIERlZmF1bHQgdmFsdWUuIFRo
aXMgdmFsdWUgaXMgdW51c2VkLgoKDwoHBAQEAAIAARIEwwEEHAoPCgcEBAQAAgACEgTDAR8g
CjAKBgQEBAACARIExgEEDxogIERpc2tzIHdpdGggYXJjaGl0ZWN0dXJlIFg4Nl82NAoKDwoH
BAQEAAIBARIExgEECgoPCgcEBAQAAgECEgTGAQ0OCi8KBgQEBAACAhIEyQEEDhofIERpc2tz
IHdpdGggYXJjaGl0ZWN0dXJlIEFSTTY0CgoPCgcEBAQAAgIBEgTJAQQJCg8KBwQEBAACAgIS
BMkBDA0KMQoEBAQCABIEzQECIhojIEEgZGVzY3JpcHRpb24gb2YgdGhlIHNvdXJjZSBkaXNr
LgoKDQoFBAQCAAQSBM0BAgoKDQoFBAQCAAUSBM0BCxEKDQoFBAQCAAESBM0BEh0KDQoFBAQC
AAMSBM0BICEKsAEKBAQEAgESBNIBAh8aoQEgQSBsaXN0IG9mIHB1YmxpY2x5IGF2YWlsYWJs
ZSBsaWNlbnNlcyB0aGF0IGFyZSBhcHBsaWNhYmxlIHRvIHRoaXMgYmFja3VwLgogVGhpcyBp
cyBhcHBsaWNhYmxlIGlmIHRoZSBvcmlnaW5hbCBpbWFnZSBoYWQgbGljZW5zZXMgYXR0YWNo
ZWQsIGUuZy4KIFdpbmRvd3MgaW1hZ2UuCgoNCgUEBAIBBBIE0gECCgoNCgUEBAIBBRIE0gEL
EQoNCgUEBAIBARIE0gESGgoNCgUEBAIBAxIE0gEdHgpPCgQEBAICEgTVAQIvGkEgQSBsaXN0
IG9mIGd1ZXN0IE9TIGZlYXR1cmVzIHRoYXQgYXJlIGFwcGxpY2FibGUgdG8gdGhpcyBiYWNr
dXAuCgoNCgUEBAICBBIE1QECCgoNCgUEBAICBhIE1QELGQoNCgUEBAICARIE1QEaKgoNCgUE
BAICAxIE1QEtLgpXCgQEBAIDEgTZAQIpGkkgVGhlIGFyY2hpdGVjdHVyZSBvZiB0aGUgc291
cmNlIGRpc2suIFZhbGlkIHZhbHVlcyBhcmUKIEFSTTY0IG9yIFg4Nl82NC4KCg0KBQQEAgME
EgTZAQIKCg0KBQQEAgMGEgTZAQsXCg0KBQQEAgMBEgTZARgkCg0KBQQEAgMDEgTZAScoCjAK
BAQEAgQSBNwBAhsaIiBUaGUgVVJMIG9mIHRoZSB0eXBlIG9mIHRoZSBkaXNrLgoKDQoFBAQC
BAQSBNwBAgoKDQoFBAQCBAUSBNwBCxEKDQoFBAQCBAESBNwBEhYKDQoFBAQCBAMSBNwBGRoK
LwoEBAQCBRIE3wECHRohIFNpemUoaW4gR0IpIG9mIHRoZSBzb3VyY2UgZGlzay4KCg0KBQQE
AgUEEgTfAQIKCg0KBQQEAgUFEgTfAQsQCg0KBQQEAgUBEgTfAREYCg0KBQQEAgUDEgTfARsc
CmkKBAQEAgYSBOMBAh0aWyBSZWdpb24gYW5kIHpvbmUgYXJlIG11dHVhbGx5IGV4Y2x1c2l2
ZSBmaWVsZHMuCiBUaGUgVVJMIG9mIHRoZSByZWdpb24gb2YgdGhlIHNvdXJjZSBkaXNrLgoK
DQoFBAQCBgQSBOMBAgoKDQoFBAQCBgUSBOMBCxEKDQoFBAQCBgESBOMBEhgKDQoFBAQCBgMS
BOMBGxwKOgoEBAQCBxIE5gECGxosIFRoZSBVUkwgb2YgdGhlIFpvbmUgd2hlcmUgdGhlIHNv
dXJjZSBkaXNrLgoKDQoFBAQCBwQSBOYBAgoKDQoFBAQCBwUSBOYBCxEKDQoFBAQCBwESBOYB
EhYKDQoFBAQCBwMSBOYBGRoKUAoEBAQCCBIE6QECJBpCIFRoZSBVUkwgb2YgdGhlIFpvbmVz
IHdoZXJlIHRoZSBzb3VyY2UgZGlzayBzaG91bGQgYmUgcmVwbGljYXRlZC4KCg0KBQQEAggE
EgTpAQIKCg0KBQQEAggFEgTpAQsRCg0KBQQEAggBEgTpARIfCg0KBQQEAggDEgTpASIjCjsK
BAQEAgkSBOwBAiMaLSBUaGUgc291cmNlIGRpc2sgdXNlZCB0byBjcmVhdGUgdGhpcyBiYWNr
dXAuCgoNCgUEBAIJBBIE7AECCgoNCgUEBAIJBRIE7AELEQoNCgUEBAIJARIE7AESHQoNCgUE
BAIJAxIE7AEgIgozCgQEBAIKEgTvAQIjGiUgVGhlIGFjY2VzcyBtb2RlIG9mIHRoZSBzb3Vy
Y2UgZGlzay4KCg0KBQQEAgoEEgTvAQIKCg0KBQQEAgoFEgTvAQsRCg0KBQQEAgoBEgTvARId
Cg0KBQQEAgoDEgTvASAiCkMKBAQEAgsSBPIBAicaNSBUaGUgbnVtYmVyIG9mIElPUFMgcHJv
dmlzaW9uZWQgZm9yIHRoZSBzb3VyY2UgZGlzay4KCg0KBQQEAgsEEgTyAQIKCg0KBQQEAgsF
EgTyAQsQCg0KBQQEAgsBEgTyAREhCg0KBQQEAgsDEgTyASQmCkkKBAQEAgwSBPUBAi0aOyBU
aGUgbnVtYmVyIG9mIHRocm91Z2hwdXQgcHJvdmlzaW9uZWQgZm9yIHRoZSBzb3VyY2UgZGlz
ay4KCg0KBQQEAgwEEgT1AQIKCg0KBQQEAgwFEgT1AQsQCg0KBQQEAgwBEgT1AREnCg0KBQQE
AgwDEgT1ASosCjsKBAQEAg0SBPgBAjAaLSBUaGUgcGh5c2ljYWwgYmxvY2sgc2l6ZSBvZiB0
aGUgc291cmNlIGRpc2suCgoNCgUEBAINBBIE+AECCgoNCgUEBAINBRIE+AELEAoNCgUEBAIN
ARIE+AERKgoNCgUEBAINAxIE+AEtLwpVCgQEBAIOEgT7AQIxGkcgSW5kaWNhdGVzIHdoZXRo
ZXIgdGhlIHNvdXJjZSBkaXNrIGlzIHVzaW5nIGNvbmZpZGVudGlhbCBjb21wdXRlIG1vZGUu
CgoNCgUEBAIOBBIE+wECCgoNCgUEBAIOBRIE+wELDwoNCgUEBAIOARIE+wEQKwoNCgUEBAIO
AxIE+wEuMAo0CgQEBAIPEgT+AQIkGiYgVGhlIHN0b3JhZ2UgcG9vbCBvZiB0aGUgc291cmNl
IGRpc2suCgoNCgUEBAIPBBIE/gECCgoNCgUEBAIPBRIE/gELEQoNCgUEBAIPARIE/gESHgoN
CgUEBAIPAxIE/gEhIwouCgQEBAIQEgSBAgIiGiAgVGhlIGxhYmVscyBvZiB0aGUgc291cmNl
IGRpc2suCgoNCgUEBAIQBhIEgQICFQoNCgUEBAIQARIEgQIWHAoNCgUEBAIQAxIEgQIfIQpt
CgQEBAIREgSFAgJBGl8gT3B0aW9uYWwuIERlZmluZXMgaWYgdGhlIGd1ZXN0IGZsdXNoIGlz
IGVuYWJsZWQgZm9yIHRoZSBzb3VyY2UgZGlzay4KIERlZmF1bHQgdmFsdWUgaXMgZmFsc2Uu
CgoNCgUEBAIRBRIEhQICBgoNCgUEBAIRARIEhQIHEgoNCgUEBAIRAxIEhQIVFwoNCgUEBAIR
CBIEhQIYQAoQCggEBAIRCJwIABIEhQIZPwp8CgIEBRIGiwIAlwIBGm4gRGlza0RhdGFTb3Vy
Y2VQcm9wZXJ0aWVzIHJlcHJlc2VudHMgdGhlIHByb3BlcnRpZXMgb2YgYQogRGlzayByZXNv
dXJjZSB0aGF0IGFyZSBzdG9yZWQgaW4gdGhlIERhdGFTb3VyY2UuCiAuCgoLCgMEBQESBIsC
CCAKPQoEBAUCABIEjQICEhovIE5hbWUgb2YgdGhlIGRpc2sgYmFja2VkIHVwIGJ5IHRoZSBk
YXRhc291cmNlLgoKDQoFBAUCAAUSBI0CAggKDQoFBAUCAAESBI0CCQ0KDQoFBAUCAAMSBI0C
EBEKLAoEBAUCARIEkAICGRoeIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgZGlzay4KCg0KBQQF
AgEFEgSQAgIICg0KBQQFAgEBEgSQAgkUCg0KBQQFAgEDEgSQAhcYCiUKBAQFAgISBJMCAhIa
FyBUaGUgdHlwZSBvZiB0aGUgZGlzay4KCg0KBQQFAgIFEgSTAgIICg0KBQQFAgIBEgSTAgkN
Cg0KBQQFAgIDEgSTAhARCisKBAQFAgMSBJYCAhQaHSBUaGUgc2l6ZSBvZiB0aGUgZGlzayBp
biBHQi4KCg0KBQQFAgMFEgSWAgIHCg0KBQQFAgMBEgSWAggPCg0KBQQFAgMDEgSWAhITYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment ===
    # Fields for DiskTargetEnvironment
    # Field: project Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: use_project_service_account Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RegionDiskTargetEnvironment ===
    # Fields for RegionDiskTargetEnvironment
    # Field: project Type: 9 ()
    # Field: region Type: 9 ()
    # Field: replica_zones Type: 9 ()
    # Field: use_project_service_account Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties ===
    # Fields for DiskRestoreProperties
    # Field: instance_backup_source Type: 11 (.google.cloud.backupdr.v1beta.RestoreDiskFromInstanceOptions)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: size_gb Type: 3 ()
    # Field: licenses Type: 9 ()
    # Field: guest_os_feature Type: 11 (.google.cloud.backupdr.v1beta.GuestOsFeature)
    # Field: disk_encryption_key Type: 11 (.google.cloud.backupdr.v1beta.CustomerEncryptionKey)
    # Field: physical_block_size_bytes Type: 3 ()
    # Field: provisioned_iops Type: 3 ()
    # Field: provisioned_throughput Type: 3 ()
    # Field: enable_confidential_compute Type: 8 ()
    # Field: storage_pool Type: 9 ()
    # Field: access_mode Type: 14 (.google.cloud.backupdr.v1beta.DiskRestoreProperties.AccessMode)
    # Field: architecture Type: 14 (.google.cloud.backupdr.v1beta.DiskRestoreProperties.Architecture)
    # Field: resource_policy Type: 9 ()
    # Field: type Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1beta.DiskRestoreProperties.LabelsEntry)
    # Field: resource_manager_tags Type: 11 (.google.cloud.backupdr.v1beta.DiskRestoreProperties.ResourceManagerTagsEntry)

# Enum: DiskRestoreProperties::AccessMode
our $DiskRestoreProperties_READ_WRITE_SINGLE = 0;
our $DiskRestoreProperties_READ_WRITE_MANY = 1;
our $DiskRestoreProperties_READ_ONLY_MANY = 2;

# Enum: DiskRestoreProperties::Architecture
our $DiskRestoreProperties_ARCHITECTURE_UNSPECIFIED = 0;
our $DiskRestoreProperties_X86_64 = 1;
our $DiskRestoreProperties_ARM64 = 2;

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions ===
    # Fields for RestoreDiskFromInstanceOptions
    # Field: source_device_name Type: 9 ()
    # Field: boot_disk Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties ===
    # Fields for DiskBackupProperties
    # Field: description Type: 9 ()
    # Field: licenses Type: 9 ()
    # Field: guest_os_feature Type: 11 (.google.cloud.backupdr.v1beta.GuestOsFeature)
    # Field: architecture Type: 14 (.google.cloud.backupdr.v1beta.DiskBackupProperties.Architecture)
    # Field: type Type: 9 ()
    # Field: size_gb Type: 3 ()
    # Field: region Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: replica_zones Type: 9 ()
    # Field: source_disk Type: 9 ()
    # Field: access_mode Type: 9 ()
    # Field: provisioned_iops Type: 3 ()
    # Field: provisioned_throughput Type: 3 ()
    # Field: physical_block_size_bytes Type: 3 ()
    # Field: enable_confidential_compute Type: 8 ()
    # Field: storage_pool Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1beta.DiskBackupProperties.LabelsEntry)
    # Field: guest_flush Type: 8 ()

# Enum: DiskBackupProperties::Architecture
our $DiskBackupProperties_ARCHITECTURE_UNSPECIFIED = 0;
our $DiskBackupProperties_X86_64 = 1;
our $DiskBackupProperties_ARM64 = 2;

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskDataSourceProperties ===
    # Fields for DiskDataSourceProperties
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: type Type: 9 ()
    # Field: size_gb Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultDisk - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/backupvault_disk.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::BackupvaultDisk;

    my $msg = Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment->new({
        project => $project,
        zone => $zone,
        use_project_service_account => $use_project_service_account,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/backupvault_disk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment

DiskTargetEnvironment represents the target environment for the disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Target project for the disk.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

Required. Target zone for the disk.

=item * C<< $msg->use_project_service_account() >> / C<< $msg->use_project_service_account($value) >>

Type: C<Bool>

Optional. Whether to use the project service account for the disk restore.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RegionDiskTargetEnvironment

RegionDiskTargetEnvironment represents the target environment for the disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Target project for the disk.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Required. Target region for the disk.

=item * C<< $msg->replica_zones() >> / C<< $msg->replica_zones($value) >>

Type: C<String>

Required. Target URLs of the replica zones for the disk.

=item * C<< $msg->use_project_service_account() >> / C<< $msg->use_project_service_account($value) >>

Type: C<Bool>

Optional. Whether to use the project service account for the disk restore.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties

DiskRestoreProperties represents the properties of a Disk restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_backup_source() >> / C<< $msg->instance_backup_source($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions>)

Options for creating a disk from a source Compute Instance backup.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the disk.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. An optional description of this resource. Provide this property
when you create the resource.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

Required. The size of the disk in GB.

=item * C<< $msg->licenses() >> / C<< $msg->licenses($value) >>

Type: C<String>

Optional. A list of publicly available licenses that are applicable to this
backup. This is applicable if the original image had licenses attached,
e.g. Windows image

=item * C<< $msg->guest_os_feature() >> / C<< $msg->guest_os_feature($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultGce::GuestOsFeature>)

Optional. A list of features to enable in the guest operating system. This
is applicable only for bootable images.

=item * C<< $msg->disk_encryption_key() >> / C<< $msg->disk_encryption_key($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultGce::CustomerEncryptionKey>)

Optional. Encrypts the disk using a
customer-supplied encryption key or a customer-managed encryption key.

=item * C<< $msg->physical_block_size_bytes() >> / C<< $msg->physical_block_size_bytes($value) >>

Type: C<Int64>

Optional. Physical block size of the persistent disk, in bytes.
If not present in a request, a default value is used.
Currently, the supported size is 4096.

=item * C<< $msg->provisioned_iops() >> / C<< $msg->provisioned_iops($value) >>

Type: C<Int64>

Optional. Indicates how many IOPS to provision for the disk. This sets the
number of I/O operations per second that the disk can handle.

=item * C<< $msg->provisioned_throughput() >> / C<< $msg->provisioned_throughput($value) >>

Type: C<Int64>

Optional. Indicates how much throughput to provision for the disk. This
sets the number of throughput MB per second that the disk can handle.

=item * C<< $msg->enable_confidential_compute() >> / C<< $msg->enable_confidential_compute($value) >>

Type: C<Bool>

Optional. Indicates whether this disk is using confidential compute mode.
Encryption with a Cloud KMS key is required to enable this option.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<String>

Optional. The storage pool in which the new disk is created. You can
provide this as a partial or full URL to the resource.

=item * C<< $msg->access_mode() >> / C<< $msg->access_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::DiskRestoreProperties::AccessMode>)

Optional. The access mode of the disk.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::DiskRestoreProperties::Architecture>)

Optional. The architecture of the source disk. Valid values are
ARM64 or X86_64.

=item * C<< $msg->resource_policy() >> / C<< $msg->resource_policy($value) >>

Type: C<String>

Optional. Resource policies applied to this disk.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. URL of the disk type resource describing which disk type to use
to create the disk.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::LabelsEntry>)

Optional. Labels to apply to this disk. These can be modified later using
<code>setLabels</code> method. Label values can be empty.

=item * C<< $msg->resource_manager_tags() >> / C<< $msg->resource_manager_tags($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::ResourceManagerTagsEntry>)

Optional. Resource manager tags to be bound to the disk.

=back

=head3 Enum: DiskRestoreProperties::AccessMode

=over 4

=item * C<READ_WRITE_SINGLE> => C<0>

=item * C<READ_WRITE_MANY> => C<1>

=item * C<READ_ONLY_MANY> => C<2>

=back

=head3 Enum: DiskRestoreProperties::Architecture

=over 4

=item * C<ARCHITECTURE_UNSPECIFIED> => C<0>

=item * C<X86_64> => C<1>

=item * C<ARM64> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions

Options for creating a disk from a source Compute Instance backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_device_name() >> / C<< $msg->source_device_name($value) >>

Type: C<String>

The device name of the disk to restore from the VM backup.

=item * C<< $msg->boot_disk() >> / C<< $msg->boot_disk($value) >>

Type: C<Bool>

Set to true to restore the boot disk from the instance backup.
This field should only be set to true if selected.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties

DiskBackupProperties represents the properties of a Disk backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the source disk.

=item * C<< $msg->licenses() >> / C<< $msg->licenses($value) >>

Type: C<String>

A list of publicly available licenses that are applicable to this backup.
This is applicable if the original image had licenses attached, e.g.
Windows image.

=item * C<< $msg->guest_os_feature() >> / C<< $msg->guest_os_feature($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultGce::GuestOsFeature>)

A list of guest OS features that are applicable to this backup.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::DiskBackupProperties::Architecture>)

The architecture of the source disk. Valid values are
ARM64 or X86_64.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The URL of the type of the disk.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

Size(in GB) of the source disk.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Region and zone are mutually exclusive fields.
The URL of the region of the source disk.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

The URL of the Zone where the source disk.

=item * C<< $msg->replica_zones() >> / C<< $msg->replica_zones($value) >>

Type: C<String>

The URL of the Zones where the source disk should be replicated.

=item * C<< $msg->source_disk() >> / C<< $msg->source_disk($value) >>

Type: C<String>

The source disk used to create this backup.

=item * C<< $msg->access_mode() >> / C<< $msg->access_mode($value) >>

Type: C<String>

The access mode of the source disk.

=item * C<< $msg->provisioned_iops() >> / C<< $msg->provisioned_iops($value) >>

Type: C<Int64>

The number of IOPS provisioned for the source disk.

=item * C<< $msg->provisioned_throughput() >> / C<< $msg->provisioned_throughput($value) >>

Type: C<Int64>

The number of throughput provisioned for the source disk.

=item * C<< $msg->physical_block_size_bytes() >> / C<< $msg->physical_block_size_bytes($value) >>

Type: C<Int64>

The physical block size of the source disk.

=item * C<< $msg->enable_confidential_compute() >> / C<< $msg->enable_confidential_compute($value) >>

Type: C<Bool>

Indicates whether the source disk is using confidential compute mode.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<String>

The storage pool of the source disk.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties::LabelsEntry>)

The labels of the source disk.

=item * C<< $msg->guest_flush() >> / C<< $msg->guest_flush($value) >>

Type: C<Bool>

Optional. Defines if the guest flush is enabled for the source disk.
Default value is false.

=back

=head3 Enum: DiskBackupProperties::Architecture

=over 4

=item * C<ARCHITECTURE_UNSPECIFIED> => C<0>

=item * C<X86_64> => C<1>

=item * C<ARM64> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskDataSourceProperties

DiskDataSourceProperties represents the properties of a
Disk resource that are stored in the DataSource.
.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the disk backed up by the datasource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the disk.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the disk.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

The size of the disk in GB.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::BackupvaultDisk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
