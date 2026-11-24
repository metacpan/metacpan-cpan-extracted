package Google::Cloud::Dialogflow::V2::Fulfillment;

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
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9mdWxmaWxsbWVudC5wcm90bxIaZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90byKvBwoLRnVsZmlsbG1lbnQSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEiYKDGRp
c3BsYXlfbmFtZRgCIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJrChNnZW5lcmljX3dlYl9zZXJ2
aWNlGAMgASgLMjkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRnVsZmlsbG1lbnQuR2Vu
ZXJpY1dlYlNlcnZpY2VIAFIRZ2VuZXJpY1dlYlNlcnZpY2USHQoHZW5hYmxlZBgEIAEoCEID
4EEBUgdlbmFibGVkElAKCGZlYXR1cmVzGAUgAygLMi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjIuRnVsZmlsbG1lbnQuRmVhdHVyZUID4EEBUghmZWF0dXJlcxrfAgoRR2VuZXJpY1dl
YlNlcnZpY2USFQoDdXJpGAEgASgJQgPgQQJSA3VyaRIfCgh1c2VybmFtZRgCIAEoCUID4EEB
Ugh1c2VybmFtZRIfCghwYXNzd29yZBgDIAEoCUID4EEBUghwYXNzd29yZBJ7Cg9yZXF1ZXN0
X2hlYWRlcnMYBCADKAsyTS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5GdWxmaWxsbWVu
dC5HZW5lcmljV2ViU2VydmljZS5SZXF1ZXN0SGVhZGVyc0VudHJ5QgPgQQFSDnJlcXVlc3RI
ZWFkZXJzEjEKEWlzX2Nsb3VkX2Z1bmN0aW9uGAUgASgIQgUYAeBBAVIPaXNDbG91ZEZ1bmN0
aW9uGkEKE1JlcXVlc3RIZWFkZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ARqAAQoHRmVhdHVyZRJICgR0eXBlGAEgASgOMjQuZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjIuRnVsZmlsbG1lbnQuRmVhdHVyZS5UeXBlUgR0eXBlIisKBFR5
cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEg0KCVNNQUxMVEFMSxABOowB6kGIAQolZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbS9GdWxmaWxsbWVudBIkcHJvamVjdHMve3Byb2plY3R9L2Fn
ZW50L2Z1bGZpbGxtZW50Ejlwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYWdlbnQvZnVsZmlsbG1lbnRCDQoLZnVsZmlsbG1lbnQiWgoVR2V0RnVsZmlsbG1lbnRS
ZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNv
bS9GdWxmaWxsbWVudFIEbmFtZSKsAQoYVXBkYXRlRnVsZmlsbG1lbnRSZXF1ZXN0Ek4KC2Z1
bGZpbGxtZW50GAEgASgLMicuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRnVsZmlsbG1l
bnRCA+BBAlILZnVsZmlsbG1lbnQSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2sykQUKDEZ1bGZpbGxtZW50cxLbAQoO
R2V0RnVsZmlsbG1lbnQSMS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5HZXRGdWxmaWxs
bWVudFJlcXVlc3QaJy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5GdWxmaWxsbWVudCJt
gtPkkwJgEicvdjIve25hbWU9cHJvamVjdHMvKi9hZ2VudC9mdWxmaWxsbWVudH1aNRIzL3Yy
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZnVsZmlsbG1lbnR92kEEbmFt
ZRKoAgoRVXBkYXRlRnVsZmlsbG1lbnQSNC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5V
cGRhdGVGdWxmaWxsbWVudFJlcXVlc3QaJy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5G
dWxmaWxsbWVudCKzAYLT5JMCkgEyMy92Mi97ZnVsZmlsbG1lbnQubmFtZT1wcm9qZWN0cy8q
L2FnZW50L2Z1bGZpbGxtZW50fToLZnVsZmlsbG1lbnRaTjI/L3YyL3tmdWxmaWxsbWVudC5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZnVsZmlsbG1lbnR9OgtmdWxmaWxs
bWVudNpBF2Z1bGZpbGxtZW50LHVwZGF0ZV9tYXNrGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dClgEKHmNvbS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MkIQRnVsZmlsbG1lbnRQcm90b1ABWj5jbG91ZC5n
b29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjIvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dw
YqICAkRGqgIaR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJK9ysKBxIFDgC0AQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJCgID
ARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAqCggKAQgSAxgANwoJCgII
JRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgS
AxsAMQoJCgIICBIDGwAxCggKAQgSAxwANwoJCgIIARIDHAA3CggKAQgSAx0AIAoJCgIIJBID
HQAgCloKAgYAEgQgAD0BGk4gU2VydmljZSBmb3IgbWFuYWdpbmcgW0Z1bGZpbGxtZW50c11b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRnVsZmlsbG1lbnRdLgoKCgoDBgABEgMgCBQK
CgoDBgADEgMhAkEKDAoFBgADmQgSAyECQQoLCgMGAAMSBCICJDMKDQoFBgADmggSBCICJDMK
KgoEBgACABIEJwIvAxocIFJldHJpZXZlcyB0aGUgZnVsZmlsbG1lbnQuCgoMCgUGAAIAARID
JwYUCgwKBQYAAgACEgMnFSoKDAoFBgACAAMSAyc1QAoNCgUGAAIABBIEKAQtBgoRCgkGAAIA
BLDKvCISBCgELQYKDAoFBgACAAQSAy4EMgoPCggGAAIABJsIABIDLgQyCigKBAYAAgESBDIC
PAMaGiBVcGRhdGVzIHRoZSBmdWxmaWxsbWVudC4KCgwKBQYAAgEBEgMyBhcKDAoFBgACAQIS
AzIYMAoMCgUGAAIBAxIDMjtGCg0KBQYAAgEEEgQzBDoGChEKCQYAAgEEsMq8IhIEMwQ6BgoM
CgUGAAIBBBIDOwRFCg8KCAYAAgEEmwgAEgM7BEUKyQQKAgQAEgVJAJsBARq7BCBCeSBkZWZh
dWx0LCB5b3VyIGFnZW50IHJlc3BvbmRzIHRvIGEgbWF0Y2hlZCBpbnRlbnQgd2l0aCBhIHN0
YXRpYyByZXNwb25zZS4KIEFzIGFuIGFsdGVybmF0aXZlLCB5b3UgY2FuIHByb3ZpZGUgYSBt
b3JlIGR5bmFtaWMgcmVzcG9uc2UgYnkgdXNpbmcKIGZ1bGZpbGxtZW50LiBXaGVuIHlvdSBl
bmFibGUgZnVsZmlsbG1lbnQgZm9yIGFuIGludGVudCwgRGlhbG9nZmxvdyByZXNwb25kcwog
dG8gdGhhdCBpbnRlbnQgYnkgY2FsbGluZyBhIHNlcnZpY2UgdGhhdCB5b3UgZGVmaW5lLiBG
b3IgZXhhbXBsZSwgaWYgYW4KIGVuZC11c2VyIHdhbnRzIHRvIHNjaGVkdWxlIGEgaGFpcmN1
dCBvbiBGcmlkYXksIHlvdXIgc2VydmljZSBjYW4gY2hlY2sgeW91cgogZGF0YWJhc2UgYW5k
IHJlc3BvbmQgdG8gdGhlIGVuZC11c2VyIHdpdGggYXZhaWxhYmlsaXR5IGluZm9ybWF0aW9u
IGZvcgogRnJpZGF5LgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgdGhlIFtmdWxmaWxs
bWVudAogZ3VpZGVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2RvY3Mv
ZnVsZmlsbG1lbnQtb3ZlcnZpZXcpLgoKCgoDBAABEgNJCBMKCwoDBAAHEgRKAk4ECg0KBQQA
B50IEgRKAk4ECtMCCgQEAAMAEgRYAm8DGsQCIFJlcHJlc2VudHMgY29uZmlndXJhdGlvbiBm
b3IgYSBnZW5lcmljIHdlYiBzZXJ2aWNlLgogRGlhbG9nZmxvdyBzdXBwb3J0cyB0d28gbWVj
aGFuaXNtcyBmb3IgYXV0aGVudGljYXRpb25zOgoKIC0gQmFzaWMgYXV0aGVudGljYXRpb24g
d2l0aCB1c2VybmFtZSBhbmQgcGFzc3dvcmQuCiAtIEF1dGhlbnRpY2F0aW9uIHdpdGggYWRk
aXRpb25hbCBhdXRoZW50aWNhdGlvbiBoZWFkZXJzLgoKIE1vcmUgaW5mb3JtYXRpb24gY291
bGQgYmUgZm91bmQgYXQ6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9k
b2NzL2Z1bGZpbGxtZW50LWNvbmZpZ3VyZS4KCgwKBQQAAwABEgNYChsKaAoGBAADAAIAEgNb
BDwaWSBSZXF1aXJlZC4gVGhlIGZ1bGZpbGxtZW50IFVSSSBmb3IgcmVjZWl2aW5nIFBPU1Qg
cmVxdWVzdHMuCiBJdCBtdXN0IHVzZSBodHRwcyBwcm90b2NvbC4KCg4KBwQAAwACAAUSA1sE
CgoOCgcEAAMAAgABEgNbCw4KDgoHBAADAAIAAxIDWxESCg4KBwQAAwACAAgSA1sTOwoRCgoE
AAMAAgAInAgAEgNbFDoKRwoGBAADAAIBEgNeBEEaOCBPcHRpb25hbC4gVGhlIHVzZXIgbmFt
ZSBmb3IgSFRUUCBCYXNpYyBhdXRoZW50aWNhdGlvbi4KCg4KBwQAAwACAQUSA14ECgoOCgcE
AAMAAgEBEgNeCxMKDgoHBAADAAIBAxIDXhYXCg4KBwQAAwACAQgSA14YQAoRCgoEAAMAAgEI
nAgAEgNeGT8KRgoGBAADAAICEgNhBEEaNyBPcHRpb25hbC4gVGhlIHBhc3N3b3JkIGZvciBI
VFRQIEJhc2ljIGF1dGhlbnRpY2F0aW9uLgoKDgoHBAADAAICBRIDYQQKCg4KBwQAAwACAgES
A2ELEwoOCgcEAAMAAgIDEgNhFhcKDgoHBAADAAICCBIDYRhAChEKCgQAAwACAgicCAASA2EZ
PwphCgYEAAMAAgMSBGUEZjEaUSBPcHRpb25hbC4gVGhlIEhUVFAgcmVxdWVzdCBoZWFkZXJz
IHRvIHNlbmQgdG9nZXRoZXIgd2l0aCBmdWxmaWxsbWVudAogcmVxdWVzdHMuCgoOCgcEAAMA
AgMGEgNlBBcKDgoHBAADAAIDARIDZRgnCg4KBwQAAwACAwMSA2UqKwoOCgcEAAMAAgMIEgNm
CDAKEQoKBAADAAIDCJwIABIDZgkvCvABCgYEAAMAAgQSBG0EbkQa3wEgT3B0aW9uYWwuIElu
ZGljYXRlcyBpZiBnZW5lcmljIHdlYiBzZXJ2aWNlIGlzIGNyZWF0ZWQgdGhyb3VnaCBDbG91
ZAogRnVuY3Rpb25zIGludGVncmF0aW9uLiBEZWZhdWx0cyB0byBmYWxzZS4KCiBpc19jbG91
ZF9mdW5jdGlvbiBpcyBkZXByZWNhdGVkLiBDbG91ZCBmdW5jdGlvbnMgY2FuIGJlIGNvbmZp
Z3VyZWQgYnkKIGl0cyB1cmkgYXMgYSByZWd1bGFyIHdlYiBzZXJ2aWNlIG5vdy4KCg4KBwQA
AwACBAUSA20ECAoOCgcEAAMAAgQBEgNtCRoKDgoHBAADAAIEAxIDbR0eCg4KBwQAAwACBAgS
A24IQwoPCggEAAMAAgQIAxIDbgkaChEKCgQAAwACBAicCAASA24cQgpICgQEAAMBEgRyAn4D
GjogV2hldGhlciBmdWxmaWxsbWVudCBpcyBlbmFibGVkIGZvciB0aGUgc3BlY2lmaWMgZmVh
dHVyZS4KCgwKBQQAAwEBEgNyChEKKgoGBAADAQQAEgR0BHoFGhogVGhlIHR5cGUgb2YgdGhl
IGZlYXR1cmUuCgoOCgcEAAMBBAABEgN0CQ0KLgoIBAADAQQAAgASA3YGGxodIEZlYXR1cmUg
dHlwZSBub3Qgc3BlY2lmaWVkLgoKEAoJBAADAQQAAgABEgN2BhYKEAoJBAADAQQAAgACEgN2
GRoKOAoIBAADAQQAAgESA3kGFBonIEZ1bGZpbGxtZW50IGlzIGVuYWJsZWQgZm9yIFNtYWxs
VGFsay4KChAKCQQAAwEEAAIBARIDeQYPChAKCQQAAwEEAAIBAhIDeRITCkYKBgQAAwECABID
fQQSGjcgVGhlIHR5cGUgb2YgdGhlIGZlYXR1cmUgdGhhdCBlbmFibGVkIGZvciBmdWxmaWxs
bWVudC4KCg4KBwQAAwECAAYSA30ECAoOCgcEAAMBAgABEgN9CQ0KDgoHBAADAQIAAxIDfRAR
CocCCgQEAAIAEgSHAQI7GvgBIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2Yg
dGhlIGZ1bGZpbGxtZW50LgogU3VwcG9ydGVkIGZvcm1hdHM6CgogLSBgcHJvamVjdHMvPFBy
b2plY3QgSUQ+L2FnZW50L2Z1bGZpbGxtZW50YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+
L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+L2FnZW50L2Z1bGZpbGxtZW50YAoKIFRoaXMgZmll
bGQgaXMgbm90IHVzZWQgZm9yIEZ1bGZpbGxtZW50IGluIGFuIEVudmlyb25tZW50LgoKDQoF
BAACAAUSBIcBAggKDQoFBAACAAESBIcBCQ0KDQoFBAACAAMSBIcBEBEKDQoFBAACAAgSBIcB
EjoKEAoIBAACAAicCAASBIcBEzkKnAEKBAQAAgESBI0BAkMajQEgT3B0aW9uYWwuIFRoZSBo
dW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBmdWxmaWxsbWVudCwgdW5pcXVlIHdpdGhpbiB0
aGUKIGFnZW50LgoKIFRoaXMgZmllbGQgaXMgbm90IHVzZWQgZm9yIEZ1bGZpbGxtZW50IGlu
IGFuIEVudmlyb25tZW50LgoKDQoFBAACAQUSBI0BAggKDQoFBAACAQESBI0BCRUKDQoFBAAC
AQMSBI0BGBkKDQoFBAACAQgSBI0BGkIKEAoIBAACAQicCAASBI0BG0EKOgoEBAAIABIGkAEC
kwEDGiogUmVxdWlyZWQuIFRoZSBmdWxmaWxsbWVudCBjb25maWd1cmF0aW9uLgoKDQoFBAAI
AAESBJABCBMKOAoEBAACAhIEkgEELhoqIENvbmZpZ3VyYXRpb24gZm9yIGEgZ2VuZXJpYyB3
ZWIgc2VydmljZS4KCg0KBQQAAgIGEgSSAQQVCg0KBQQAAgIBEgSSARYpCg0KBQQAAgIDEgSS
ASwtCjkKBAQAAgMSBJYBAjwaKyBPcHRpb25hbC4gV2hldGhlciBmdWxmaWxsbWVudCBpcyBl
bmFibGVkLgoKDQoFBAACAwUSBJYBAgYKDQoFBAACAwESBJYBBw4KDQoFBAACAwMSBJYBERIK
DQoFBAACAwgSBJYBEzsKEAoIBAACAwicCAASBJYBFDoKZQoEBAACBBIEmgECSRpXIE9wdGlv
bmFsLiBUaGUgZmllbGQgZGVmaW5lcyB3aGV0aGVyIHRoZSBmdWxmaWxsbWVudCBpcyBlbmFi
bGVkIGZvciBjZXJ0YWluCiBmZWF0dXJlcy4KCg0KBQQAAgQEEgSaAQIKCg0KBQQAAgQGEgSa
AQsSCg0KBQQAAgQBEgSaARMbCg0KBQQAAgQDEgSaAR4fCg0KBQQAAgQIEgSaASBIChAKCAQA
AgQInAgAEgSaASFHCn8KAgQBEgafAQCoAQEacSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgog
W0Z1bGZpbGxtZW50cy5HZXRGdWxmaWxsbWVudF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djIuRnVsZmlsbG1lbnRzLkdldEZ1bGZpbGxtZW50XS4KCgsKAwQBARIEnwEIHQpsCgQEAQIA
EgaiAQKnAQQaXCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGZ1bGZpbGxtZW50LgogRm9y
bWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Z1bGZpbGxtZW50YC4KCg0KBQQB
AgAFEgSiAQIICg0KBQQBAgABEgSiAQkNCg0KBQQBAgADEgSiARARCg8KBQQBAgAIEgaiARKn
AQMKEAoIBAECAAicCAASBKMBBCoKEQoHBAECAAifCBIGpAEEpgEFCoUBCgIEAhIGrAEAtAEB
GncgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtGdWxmaWxsbWVudHMuVXBkYXRlRnVsZmls
bG1lbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkZ1bGZpbGxtZW50cy5VcGRhdGVG
dWxmaWxsbWVudF0uCgoLCgMEAgESBKwBCCAKNAoEBAICABIErgECRxomIFJlcXVpcmVkLiBU
aGUgZnVsZmlsbG1lbnQgdG8gdXBkYXRlLgoKDQoFBAICAAYSBK4BAg0KDQoFBAICAAESBK4B
DhkKDQoFBAICAAMSBK4BHB0KDQoFBAICAAgSBK4BHkYKEAoIBAICAAicCAASBK4BH0UKggEK
BAQCAgESBrIBArMBLxpyIFJlcXVpcmVkLiBUaGUgbWFzayB0byBjb250cm9sIHdoaWNoIGZp
ZWxkcyBnZXQgdXBkYXRlZC4gSWYgdGhlIG1hc2sgaXMgbm90CiBwcmVzZW50LCBhbGwgZmll
bGRzIHdpbGwgYmUgdXBkYXRlZC4KCg0KBQQCAgEGEgSyAQIbCg0KBQQCAgEBEgSyARwnCg0K
BQQCAgEDEgSyASorCg0KBQQCAgEIEgSzAQYuChAKCAQCAgEInAgAEgSzAQctYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment ===
    # Fields for Fulfillment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: generic_web_service Type: 11 (.google.cloud.dialogflow.v2.Fulfillment.GenericWebService)
    # Field: enabled Type: 8 ()
    # Field: features Type: 11 (.google.cloud.dialogflow.v2.Fulfillment.Feature)

# === Message: Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest ===
    # Fields for GetFulfillmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest ===
    # Fields for UpdateFulfillmentRequest
    # Field: fulfillment Type: 11 (.google.cloud.dialogflow.v2.Fulfillment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dialogflow::V2::Fulfillment::FulfillmentsClient ===
package Google::Cloud::Dialogflow::V2::Fulfillment::FulfillmentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::Fulfillment::FulfillmentsClient

Client stub representing the remote C<Fulfillments> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub get_fulfillment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Fulfillments',
        method         => 'GetFulfillment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment',
    });
}

sub update_fulfillment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Fulfillments',
        method         => 'UpdateFulfillment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Fulfillment - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/fulfillment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Fulfillment;

    my $msg = Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment->new({
        name => $name,
        display_name => $display_name,
        generic_web_service => $generic_web_service,
        enabled => $enabled,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/fulfillment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment

By default, your agent responds to a matched intent with a static response.
As an alternative, you can provide a more dynamic response by using
fulfillment. When you enable fulfillment for an intent, Dialogflow responds
to that intent by calling a service that you define. For example, if an
end-user wants to schedule a haircut on Friday, your service can check your
database and respond to the end-user with availability information for
Friday.

For more information, see the [fulfillment
guide](https://cloud.google.com/dialogflow/docs/fulfillment-overview).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the fulfillment.
Supported formats:

- `projects/<Project ID>/agent/fulfillment`
- `projects/<Project ID>/locations/<Location ID>/agent/fulfillment`

This field is not used for Fulfillment in an Environment.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The human-readable name of the fulfillment, unique within the
agent.

This field is not used for Fulfillment in an Environment.

=item * C<< $msg->generic_web_service() >> / C<< $msg->generic_web_service($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService>)

Configuration for a generic web service.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Optional. Whether fulfillment is enabled.

=item * C<< $msg->features() >> / C<< $msg->features($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::Feature>)

Optional. The field defines whether the fulfillment is enabled for certain
features.

=back

=head2 Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest

The request message for
[Fulfillments.GetFulfillment][google.cloud.dialogflow.v2.Fulfillments.GetFulfillment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the fulfillment.
Format: `projects/<Project ID>/agent/fulfillment`.

=back

=head2 Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest

The request message for
[Fulfillments.UpdateFulfillment][google.cloud.dialogflow.v2.Fulfillments.UpdateFulfillment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fulfillment() >> / C<< $msg->fulfillment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment>)

Required. The fulfillment to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Fulfillment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
