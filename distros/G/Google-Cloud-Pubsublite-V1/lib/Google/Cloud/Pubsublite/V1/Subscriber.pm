package Google::Cloud::Pubsublite::V1::Subscriber;

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
    eval { require Google::Cloud::Pubsublite::V1::Common };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92MS9zdWJzY3JpYmVyLnByb3RvEhpnb29nbGUu
Y2xvdWQucHVic3VibGl0ZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
J2dvb2dsZS9jbG91ZC9wdWJzdWJsaXRlL3YxL2NvbW1vbi5wcm90byK0AQoXSW5pdGlhbFN1
YnNjcmliZVJlcXVlc3QSIgoMc3Vic2NyaXB0aW9uGAEgASgJUgxzdWJzY3JpcHRpb24SHAoJ
cGFydGl0aW9uGAIgASgDUglwYXJ0aXRpb24SVwoQaW5pdGlhbF9sb2NhdGlvbhgEIAEoCzIn
Lmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlNlZWtSZXF1ZXN0QgPgQQFSD2luaXRpYWxM
b2NhdGlvbiJWChhJbml0aWFsU3Vic2NyaWJlUmVzcG9uc2USOgoGY3Vyc29yGAEgASgLMiIu
Z29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuQ3Vyc29yUgZjdXJzb3Ii/AEKC1NlZWtSZXF1
ZXN0ElgKDG5hbWVkX3RhcmdldBgBIAEoDjIzLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYx
LlNlZWtSZXF1ZXN0Lk5hbWVkVGFyZ2V0SABSC25hbWVkVGFyZ2V0EjwKBmN1cnNvchgCIAEo
CzIiLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkN1cnNvckgAUgZjdXJzb3IiSwoLTmFt
ZWRUYXJnZXQSHAoYTkFNRURfVEFSR0VUX1VOU1BFQ0lGSUVEEAASCAoESEVBRBABEhQKEENP
TU1JVFRFRF9DVVJTT1IQAkIICgZ0YXJnZXQiSgoMU2Vla1Jlc3BvbnNlEjoKBmN1cnNvchgB
IAEoCzIiLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkN1cnNvclIGY3Vyc29yImQKEkZs
b3dDb250cm9sUmVxdWVzdBIpChBhbGxvd2VkX21lc3NhZ2VzGAEgASgDUg9hbGxvd2VkTWVz
c2FnZXMSIwoNYWxsb3dlZF9ieXRlcxgCIAEoA1IMYWxsb3dlZEJ5dGVzIoICChBTdWJzY3Jp
YmVSZXF1ZXN0Ek8KB2luaXRpYWwYASABKAsyMy5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52
MS5Jbml0aWFsU3Vic2NyaWJlUmVxdWVzdEgAUgdpbml0aWFsEj0KBHNlZWsYAiABKAsyJy5n
b29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5TZWVrUmVxdWVzdEgAUgRzZWVrElMKDGZsb3df
Y29udHJvbBgDIAEoCzIuLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkZsb3dDb250cm9s
UmVxdWVzdEgAUgtmbG93Q29udHJvbEIJCgdyZXF1ZXN0IlsKD01lc3NhZ2VSZXNwb25zZRJI
CghtZXNzYWdlcxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlNlcXVlbmNl
ZE1lc3NhZ2VSCG1lc3NhZ2VzIvwBChFTdWJzY3JpYmVSZXNwb25zZRJQCgdpbml0aWFsGAEg
ASgLMjQuZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuSW5pdGlhbFN1YnNjcmliZVJlc3Bv
bnNlSABSB2luaXRpYWwSPgoEc2VlaxgCIAEoCzIoLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRl
LnYxLlNlZWtSZXNwb25zZUgAUgRzZWVrEkkKCG1lc3NhZ2VzGAMgASgLMisuZ29vZ2xlLmNs
b3VkLnB1YnN1YmxpdGUudjEuTWVzc2FnZVJlc3BvbnNlSABSCG1lc3NhZ2VzQgoKCHJlc3Bv
bnNlImQKIUluaXRpYWxQYXJ0aXRpb25Bc3NpZ25tZW50UmVxdWVzdBIiCgxzdWJzY3JpcHRp
b24YASABKAlSDHN1YnNjcmlwdGlvbhIbCgljbGllbnRfaWQYAiABKAxSCGNsaWVudElkIjUK
E1BhcnRpdGlvbkFzc2lnbm1lbnQSHgoKcGFydGl0aW9ucxgBIAMoA1IKcGFydGl0aW9ucyIY
ChZQYXJ0aXRpb25Bc3NpZ25tZW50QWNrIsoBChpQYXJ0aXRpb25Bc3NpZ25tZW50UmVxdWVz
dBJZCgdpbml0aWFsGAEgASgLMj0uZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuSW5pdGlh
bFBhcnRpdGlvbkFzc2lnbm1lbnRSZXF1ZXN0SABSB2luaXRpYWwSRgoDYWNrGAIgASgLMjIu
Z29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuUGFydGl0aW9uQXNzaWdubWVudEFja0gAUgNh
Y2tCCQoHcmVxdWVzdDLSAQoRU3Vic2NyaWJlclNlcnZpY2USbgoJU3Vic2NyaWJlEiwuZ29v
Z2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuU3Vic2NyaWJlUmVxdWVzdBotLmdvb2dsZS5jbG91
ZC5wdWJzdWJsaXRlLnYxLlN1YnNjcmliZVJlc3BvbnNlIgAoATABGk3KQRlwdWJzdWJsaXRl
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybTLvAQoaUGFydGl0aW9uQXNzaWdubWVudFNlcnZpY2USgQEKEEFzc2lnblBh
cnRpdGlvbnMSNi5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5QYXJ0aXRpb25Bc3NpZ25t
ZW50UmVxdWVzdBovLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlBhcnRpdGlvbkFzc2ln
bm1lbnQiACgBMAEaTcpBGXB1YnN1YmxpdGUuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtMBCiFjb20uZ29vZ2xlLmNs
b3VkLnB1YnN1YmxpdGUucHJvdG9CD1N1YnNjcmliZXJQcm90b1ABWj5jbG91ZC5nb29nbGUu
Y29tL2dvL3B1YnN1YmxpdGUvYXBpdjEvcHVic3VibGl0ZXBiO3B1YnN1YmxpdGVwYvgBAaoC
Gkdvb2dsZS5DbG91ZC5QdWJTdWJMaXRlLlYxygIaR29vZ2xlXENsb3VkXFB1YlN1YkxpdGVc
VjHqAh1Hb29nbGU6OkNsb3VkOjpQdWJTdWJMaXRlOjpWMUrDOwoHEgUOANkBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAxCggKAQgSAxcAHwoJCgIIHxIDFwAfCggKAQgS
AxgANwoJCgIIJRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsAMAoJCgIICBIDGwAwCggKAQgSAxwAOgoJCgIIARIDHAA6CggKAQgSAx0A
NwoJCgIIKRIDHQA3CggKAQgSAx4ANgoJCgIILRIDHgA2CmwKAgYAEgQiACkBGmAgVGhlIHNl
cnZpY2UgdGhhdCBhIHN1YnNjcmliZXIgY2xpZW50IGFwcGxpY2F0aW9uIHVzZXMgdG8gcmVj
ZWl2ZSBtZXNzYWdlcwogZnJvbSBzdWJzY3JpcHRpb25zLgoKCgoDBgABEgMiCBkKCgoDBgAD
EgMjAkEKDAoFBgADmQgSAyMCQQoLCgMGAAMSBCQCJTcKDQoFBgADmggSBCQCJTcKSwoEBgAC
ABIDKAJOGj4gRXN0YWJsaXNoZXMgYSBzdHJlYW0gd2l0aCB0aGUgc2VydmVyIGZvciByZWNl
aXZpbmcgbWVzc2FnZXMuCgoMCgUGAAIAARIDKAYPCgwKBQYAAgAFEgMoEBYKDAoFBgACAAIS
AygXJwoMCgUGAAIABhIDKDI4CgwKBQYAAgADEgMoOUoKeAoCBgESBC0AOwEabCBUaGUgc2Vy
dmljZSB0aGF0IGEgc3Vic2NyaWJlciBjbGllbnQgYXBwbGljYXRpb24gdXNlcyB0byBkZXRl
cm1pbmUgd2hpY2gKIHBhcnRpdGlvbnMgaXQgc2hvdWxkIGNvbm5lY3QgdG8uCgoKCgMGAQES
Ay0IIgoKCgMGAQMSAy4CQQoMCgUGAQOZCBIDLgJBCgsKAwYBAxIELwIwNwoNCgUGAQOaCBIE
LwIwNwqRAwoEBgECABIEOQI6LRqCAyBBc3NpZ24gcGFydGl0aW9ucyBmb3IgdGhpcyBjbGll
bnQgdG8gaGFuZGxlIGZvciB0aGUgc3BlY2lmaWVkIHN1YnNjcmlwdGlvbi4KCiBUaGUgY2xp
ZW50IG11c3Qgc2VuZCBhbiBJbml0aWFsUGFydGl0aW9uQXNzaWdubWVudFJlcXVlc3QgZmly
c3QuCiBUaGUgc2VydmVyIHdpbGwgdGhlbiBzZW5kIGF0IG1vc3Qgb25lIHVuYWNrbm93bGVk
Z2VkIFBhcnRpdGlvbkFzc2lnbm1lbnQKIG91dHN0YW5kaW5nIG9uIHRoZSBzdHJlYW0gYXQg
YSB0aW1lLgogVGhlIGNsaWVudCBzaG91bGQgc2VuZCBhIFBhcnRpdGlvbkFzc2lnbm1lbnRB
Y2sgYWZ0ZXIgdXBkYXRpbmcgdGhlCiBwYXJ0aXRpb25zIGl0IGlzIGNvbm5lY3RlZCB0byB0
byByZWZsZWN0IHRoZSBuZXcgYXNzaWdubWVudC4KCgwKBQYBAgABEgM5BhYKDAoFBgECAAUS
AzkXHQoMCgUGAQIAAhIDOR44CgwKBQYBAgAGEgM6DxUKDAoFBgECAAMSAzoWKQqlAQoCBAAS
BD8ASwEamAEgVGhlIGZpcnN0IHJlcXVlc3QgdGhhdCBtdXN0IGJlIHNlbnQgb24gYSBuZXds
eS1vcGVuZWQgc3RyZWFtLiBUaGUgY2xpZW50IG11c3QKIHdhaXQgZm9yIHRoZSByZXNwb25z
ZSBiZWZvcmUgc2VuZGluZyBzdWJzZXF1ZW50IHJlcXVlc3RzIG9uIHRoZSBzdHJlYW0uCgoK
CgMEAAESAz8IHwo/CgQEAAIAEgNBAhoaMiBUaGUgc3Vic2NyaXB0aW9uIGZyb20gd2hpY2gg
dG8gcmVjZWl2ZSBtZXNzYWdlcy4KCgwKBQQAAgAFEgNBAggKDAoFBAACAAESA0EJFQoMCgUE
AAIAAxIDQRgZCpoBCgQEAAIBEgNFAhYajAEgVGhlIHBhcnRpdGlvbiBmcm9tIHdoaWNoIHRv
IHJlY2VpdmUgbWVzc2FnZXMuIFBhcnRpdGlvbnMgYXJlIHplcm8gaW5kZXhlZCwKIHNvIGBw
YXJ0aXRpb25gIG11c3QgYmUgaW4gdGhlIHJhbmdlIFswLCB0b3BpYy5udW1fcGFydGl0aW9u
cykuCgoMCgUEAAIBBRIDRQIHCgwKBQQAAgEBEgNFCBEKDAoFBAACAQMSA0UUFQq3AQoEBAAC
AhIDSgJMGqkBIE9wdGlvbmFsLiBJbml0aWFsIHRhcmdldCBsb2NhdGlvbiB3aXRoaW4gdGhl
IG1lc3NhZ2UgYmFja2xvZy4gSWYgbm90IHNldCwKIG1lc3NhZ2VzIHdpbGwgYmUgZGVsaXZl
cmVkIGZyb20gdGhlIGNvbW1pdCBjdXJzb3IgZm9yIHRoZSBnaXZlbgogc3Vic2NyaXB0aW9u
IGFuZCBwYXJ0aXRpb24uCgoMCgUEAAICBhIDSgINCgwKBQQAAgIBEgNKDh4KDAoFBAACAgMS
A0ohIgoMCgUEAAICCBIDSiNLCg8KCAQAAgIInAgAEgNKJEoKNQoCBAESBE4AUgEaKSBSZXNw
b25zZSB0byBhbiBJbml0aWFsU3Vic2NyaWJlUmVxdWVzdC4KCgoKAwQBARIDTgggCn0KBAQB
AgASA1ECFBpwIFRoZSBjdXJzb3IgZnJvbSB3aGljaCB0aGUgc3Vic2NyaWJlciB3aWxsIHN0
YXJ0IHJlY2VpdmluZyBtZXNzYWdlcyBvbmNlCiBmbG93IGNvbnRyb2wgdG9rZW5zIGJlY29t
ZSBhdmFpbGFibGUuCgoMCgUEAQIABhIDUQIICgwKBQQBAgABEgNRCQ8KDAoFBAECAAMSA1ES
Ewq6AgoCBAISBFoAcgEarQIgUmVxdWVzdCB0byB1cGRhdGUgdGhlIHN0cmVhbSdzIGRlbGl2
ZXJ5IGN1cnNvciBiYXNlZCBvbiB0aGUgZ2l2ZW4gdGFyZ2V0LgogUmVzZXRzIHRoZSBzZXJ2
ZXIgYXZhaWxhYmxlIHRva2VucyB0byAwLiBTZWVrUmVxdWVzdHMgcGFzdCBoZWFkIHJlc3Vs
dCBpbgogc3RyZWFtIGJyZWFrYWdlLgoKIFNlZWtSZXF1ZXN0cyBtYXkgbm90IGJlIHNlbnQg
d2hpbGUgYW5vdGhlciBTZWVrUmVxdWVzdCBpcyBvdXRzdGFuZGluZyAoaS5lLiwKIGhhcyBu
b3QgcmVjZWl2ZWQgYSBTZWVrUmVzcG9uc2UpIG9uIHRoZSBzYW1lIHN0cmVhbS4KCgoKAwQC
ARIDWggTClEKBAQCBAASBFwCZwMaQyBBIHNwZWNpYWwgdGFyZ2V0IGluIHRoZSBwYXJ0aXRp
b24gdGhhdCB0YWtlcyBubyBvdGhlciBwYXJhbWV0ZXJzLgoKDAoFBAIEAAESA1wHEgo1CgYE
AgQAAgASA14EIRomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoH
BAIEAAIAARIDXgQcCg4KBwQCBAACAAISA14fIAphCgYEAgQAAgESA2IEDRpSIEEgdGFyZ2V0
IGNvcnJlc3BvbmRpbmcgdG8gdGhlIG1vc3QgcmVjZW50bHkgcHVibGlzaGVkIG1lc3NhZ2Ug
aW4gdGhlCiBwYXJ0aXRpb24uCgoOCgcEAgQAAgEBEgNiBAgKDgoHBAIEAAIBAhIDYgsMCnAK
BgQCBAACAhIDZgQZGmEgQSB0YXJnZXQgY29ycmVzcG9uZGluZyB0byB0aGUgY29tbWl0dGVk
IGN1cnNvciBmb3IgdGhlIGdpdmVuIHN1YnNjcmlwdGlvbgogYW5kIHRvcGljIHBhcnRpdGlv
bi4KCg4KBwQCBAACAgESA2YEFAoOCgcEAgQAAgICEgNmFxgKMwoEBAIIABIEagJxAxolIFRo
ZSB0YXJnZXQgdG8gc2VlayB0by4gTXVzdCBiZSBzZXQuCgoMCgUEAggAARIDaggOCh4KBAQC
AgASA2wEIRoRIEEgbmFtZWQgdGFyZ2V0LgoKDAoFBAICAAYSA2wEDwoMCgUEAgIAARIDbBAc
CgwKBQQCAgADEgNsHyAKYgoEBAICARIDcAQWGlUgQSB0YXJnZXQgY29ycmVzcG9uZGluZyB0
byB0aGUgY3Vyc29yLCBwb2ludGluZyB0byBhbnl3aGVyZSBpbiB0aGUKIHRvcGljIHBhcnRp
dGlvbi4KCgwKBQQCAgEGEgNwBAoKDAoFBAICAQESA3ALEQoMCgUEAgIBAxIDcBQVCigKAgQD
EgR1AHgBGhwgUmVzcG9uc2UgdG8gYSBTZWVrUmVxdWVzdC4KCgoKAwQDARIDdQgUCj4KBAQD
AgASA3cCFBoxIFRoZSBuZXcgZGVsaXZlcnkgY3Vyc29yIGZvciB0aGUgY3VycmVudCBzdHJl
YW0uCgoMCgUEAwIABhIDdwIICgwKBQQDAgABEgN3CQ8KDAoFBAMCAAMSA3cSEwpyCgIEBBIF
fACCAQEaZSBSZXF1ZXN0IHRvIGdyYW50IHRva2VucyB0byB0aGUgc2VydmVyLCByZXF1ZXN0
aW5nIGRlbGl2ZXJ5IG9mIG1lc3NhZ2VzIHdoZW4KIHRoZXkgYmVjb21lIGF2YWlsYWJsZS4K
CgoKAwQEARIDfAgaClkKBAQEAgASA34CHRpMIFRoZSBudW1iZXIgb2YgbWVzc2FnZSB0b2tl
bnMgdG8gZ3JhbnQuIE11c3QgYmUgZ3JlYXRlciB0aGFuIG9yIGVxdWFsIHRvIDAuCgoMCgUE
BAIABRIDfgIHCgwKBQQEAgABEgN+CBgKDAoFBAQCAAMSA34bHApXCgQEBAIBEgSBAQIaGkkg
VGhlIG51bWJlciBvZiBieXRlIHRva2VucyB0byBncmFudC4gTXVzdCBiZSBncmVhdGVyIHRo
YW4gb3IgZXF1YWwgdG8gMC4KCg0KBQQEAgEFEgSBAQIHCg0KBQQEAgEBEgSBAQgVCg0KBQQE
AgEDEgSBARgZCkkKAgQFEgaFAQCRAQEaOyBBIHJlcXVlc3Qgc2VudCBmcm9tIHRoZSBjbGll
bnQgdG8gdGhlIHNlcnZlciBvbiBhIHN0cmVhbS4KCgsKAwQFARIEhQEIGAouCgQEBQgAEgaH
AQKQAQMaHiBUaGUgdHlwZSBvZiByZXF1ZXN0IHRoaXMgaXMuCgoNCgUEBQgAARIEhwEIDwou
CgQEBQIAEgSJAQQoGiAgSW5pdGlhbCByZXF1ZXN0IG9uIHRoZSBzdHJlYW0uCgoNCgUEBQIA
BhIEiQEEGwoNCgUEBQIAARIEiQEcIwoNCgUEBQIAAxIEiQEmJwo/CgQEBQIBEgSMAQQZGjEg
UmVxdWVzdCB0byB1cGRhdGUgdGhlIHN0cmVhbSdzIGRlbGl2ZXJ5IGN1cnNvci4KCg0KBQQF
AgEGEgSMAQQPCg0KBQQFAgEBEgSMARAUCg0KBQQFAgEDEgSMARcYCjYKBAQFAgISBI8BBCga
KCBSZXF1ZXN0IHRvIGdyYW50IHRva2VucyB0byB0aGUgc2VydmVyLAoKDQoFBAUCAgYSBI8B
BBYKDQoFBAUCAgESBI8BFyMKDQoFBAUCAgMSBI8BJicKxQIKAgQGEgaZAQCcAQEatgIgUmVz
cG9uc2UgY29udGFpbmluZyBhIGxpc3Qgb2YgbWVzc2FnZXMuIFVwb24gZGVsaXZlcmluZyBh
IE1lc3NhZ2VSZXNwb25zZSB0bwogdGhlIGNsaWVudCwgdGhlIHNlcnZlcjoKICogIFVwZGF0
ZXMgdGhlIHN0cmVhbSdzIGRlbGl2ZXJ5IGN1cnNvciB0byBvbmUgZ3JlYXRlciB0aGFuIHRo
ZSBjdXJzb3Igb2YgdGhlCiAgICBsYXN0IG1lc3NhZ2UgaW4gdGhlIGxpc3QuCiAqICBTdWJ0
cmFjdHMgdGhlIHRvdGFsIG51bWJlciBvZiBieXRlcyBhbmQgbWVzc2FnZXMgZnJvbSB0aGUg
dG9rZW5zIGF2YWlsYWJsZQogICAgdG8gdGhlIHNlcnZlci4KCgsKAwQGARIEmQEIFwoyCgQE
BgIAEgSbAQIpGiQgTWVzc2FnZXMgZnJvbSB0aGUgdG9waWMgcGFydGl0aW9uLgoKDQoFBAYC
AAQSBJsBAgoKDQoFBAYCAAYSBJsBCxsKDQoFBAYCAAESBJsBHCQKDQoFBAYCAAMSBJsBJygK
LQoCBAcSBp8BAKsBARofIFJlc3BvbnNlIHRvIFN1YnNjcmliZVJlcXVlc3QuCgoLCgMEBwES
BJ8BCBkKLwoEBAcIABIGoQECqgEDGh8gVGhlIHR5cGUgb2YgcmVzcG9uc2UgdGhpcyBpcy4K
Cg0KBQQHCAABEgShAQgQCi8KBAQHAgASBKMBBCkaISBJbml0aWFsIHJlc3BvbnNlIG9uIHRo
ZSBzdHJlYW0uCgoNCgUEBwIABhIEowEEHAoNCgUEBwIAARIEowEdJAoNCgUEBwIAAxIEowEn
KAotCgQEBwIBEgSmAQQaGh8gUmVzcG9uc2UgdG8gYSBTZWVrIG9wZXJhdGlvbi4KCg0KBQQH
AgEGEgSmAQQQCg0KBQQHAgEBEgSmAREVCg0KBQQHAgEDEgSmARgZCkYKBAQHAgISBKkBBCEa
OCBSZXNwb25zZSBjb250YWluaW5nIG1lc3NhZ2VzIGZyb20gdGhlIHRvcGljIHBhcnRpdGlv
bi4KCg0KBQQHAgIGEgSpAQQTCg0KBQQHAgIBEgSpARQcCg0KBQQHAgIDEgSpAR8gCqcBCgIE
CBIGrwEAvgEBGpgBIFRoZSBmaXJzdCByZXF1ZXN0IHRoYXQgbXVzdCBiZSBzZW50IG9uIGEg
bmV3bHktb3BlbmVkIHN0cmVhbS4gVGhlIGNsaWVudCBtdXN0CiB3YWl0IGZvciB0aGUgcmVz
cG9uc2UgYmVmb3JlIHNlbmRpbmcgc3Vic2VxdWVudCByZXF1ZXN0cyBvbiB0aGUgc3RyZWFt
LgoKCwoDBAgBEgSvAQgpCokBCgQECAIAEgSzAQIaGnsgVGhlIHN1YnNjcmlwdGlvbiBuYW1l
LiBTdHJ1Y3R1cmVkIGxpa2U6CiBwcm9qZWN0cy88cHJvamVjdCBudW1iZXI+L2xvY2F0aW9u
cy88em9uZSBuYW1lPi9zdWJzY3JpcHRpb25zLzxzdWJzY3JpcHRpb24KIGlkPgoKDQoFBAgC
AAUSBLMBAggKDQoFBAgCAAESBLMBCRUKDQoFBAgCAAMSBLMBGBkK2wMKBAQIAgESBL0BAhYa
zAMgQW4gb3BhcXVlLCB1bmlxdWUgY2xpZW50IGlkZW50aWZpZXIuIFRoaXMgZmllbGQgbXVz
dCBiZSBleGFjdGx5IDE2IGJ5dGVzCiBsb25nIGFuZCBpcyBpbnRlcnByZXRlZCBhcyBhbiB1
bnNpZ25lZCAxMjggYml0IGludGVnZXIuIE90aGVyIHNpemUgdmFsdWVzCiB3aWxsIGJlIHJl
amVjdGVkIGFuZCB0aGUgc3RyZWFtIHdpbGwgYmUgZmFpbGVkIHdpdGggYSBub24tcmV0cnlh
YmxlIGVycm9yLgoKIFRoaXMgZmllbGQgaXMgbGFyZ2UgZW5vdWdoIHRvIGZpdCBhIHV1aWQg
ZnJvbSBzdGFuZGFyZCB1dWlkIGFsZ29yaXRobXMgbGlrZQogdXVpZDEgb3IgdXVpZDQsIHdo
aWNoIHNob3VsZCBiZSB1c2VkIHRvIGdlbmVyYXRlIHRoaXMgbnVtYmVyLiBUaGUgc2FtZQog
aWRlbnRpZmllciBzaG91bGQgYmUgcmV1c2VkIGZvbGxvd2luZyBkaXNjb25uZWN0aW9ucyB3
aXRoIHJldHJ5YWJsZSBzdHJlYW0KIGVycm9ycy4KCg0KBQQIAgEFEgS9AQIHCg0KBQQIAgEB
EgS9AQgRCg0KBQQIAgEDEgS9ARQVCsIBCgIECRIGwwEAxgEBGrMBIFBhcnRpdGlvbkFzc2ln
bm1lbnRzIHNob3VsZCBub3QgcmFjZSB3aXRoIGFja25vd2xlZGdlbWVudHMuIFRoZXJlCiBz
aG91bGQgYmUgZXhhY3RseSBvbmUgdW5hY2tub3dsZWRnZWQgUGFydGl0aW9uQXNzaWdubWVu
dCBhdCBhIHRpbWUuIElmIG5vdCwKIHRoZSBjbGllbnQgbXVzdCBicmVhayB0aGUgc3RyZWFt
LgoKCwoDBAkBEgTDAQgbCk0KBAQJAgASBMUBAiAaPyBUaGUgbGlzdCBvZiBwYXJ0aXRpb24g
bnVtYmVycyB0aGlzIHN1YnNjcmliZXIgaXMgYXNzaWduZWQgdG8uCgoNCgUECQIABBIExQEC
CgoNCgUECQIABRIExQELEAoNCgUECQIAARIExQERGwoNCgUECQIAAxIExQEeHwqkAgoCBAoS
BM0BACEalwIgQWNrbm93bGVkZ2UgcmVjZWlwdCBhbmQgaGFuZGxpbmcgb2YgdGhlIHByZXZp
b3VzIGFzc2lnbm1lbnQuCiBJZiBub3Qgc2VudCB3aXRoaW4gYSBzaG9ydCBwZXJpb2QgYWZ0
ZXIgcmVjZWl2aW5nIHRoZSBhc3NpZ25tZW50LAogcGFydGl0aW9ucyBtYXkgcmVtYWluIHVu
YXNzaWduZWQgZm9yIGEgcGVyaW9kIG9mIHRpbWUgdW50aWwgdGhlCiBjbGllbnQgaXMga25v
d24gdG8gYmUgaW5hY3RpdmUsIGFmdGVyIHdoaWNoIHRpbWUgdGhlIHNlcnZlciB3aWxsIGJy
ZWFrIHRoZQogc3RyZWFtLgoKCwoDBAoBEgTNAQgeCjwKAgQLEgbQAQDZAQEaLiBBIHJlcXVl
c3Qgb24gdGhlIFBhcnRpdGlvbkFzc2lnbm1lbnQgc3RyZWFtLgoKCwoDBAsBEgTQAQgiCi4K
BAQLCAASBtIBAtgBAxoeIFRoZSB0eXBlIG9mIHJlcXVlc3QgdGhpcyBpcy4KCg0KBQQLCAAB
EgTSAQgPCi4KBAQLAgASBNQBBDIaICBJbml0aWFsIHJlcXVlc3Qgb24gdGhlIHN0cmVhbS4K
Cg0KBQQLAgAGEgTUAQQlCg0KBQQLAgABEgTUASYtCg0KBQQLAgADEgTUATAxCjoKBAQLAgES
BNcBBCMaLCBBY2tub3dsZWRnZW1lbnQgb2YgYSBwYXJ0aXRpb24gYXNzaWdubWVudC4KCg0K
BQQLAgEGEgTXAQQaCg0KBQQLAgEBEgTXARseCg0KBQQLAgEDEgTXASEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest ===
    # Fields for InitialSubscribeRequest
    # Field: subscription Type: 9 ()
    # Field: partition Type: 3 ()
    # Field: initial_location Type: 11 (.google.cloud.pubsublite.v1.SeekRequest)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse ===
    # Fields for InitialSubscribeResponse
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest ===
    # Fields for SeekRequest
    # Field: named_target Type: 14 (.google.cloud.pubsublite.v1.SeekRequest.NamedTarget)
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# Enum: SeekRequest::NamedTarget
our $SeekRequest_NAMED_TARGET_UNSPECIFIED = 0;
our $SeekRequest_HEAD = 1;
our $SeekRequest_COMMITTED_CURSOR = 2;

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse ===
    # Fields for SeekResponse
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest ===
    # Fields for FlowControlRequest
    # Field: allowed_messages Type: 3 ()
    # Field: allowed_bytes Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest ===
    # Fields for SubscribeRequest
    # Field: initial Type: 11 (.google.cloud.pubsublite.v1.InitialSubscribeRequest)
    # Field: seek Type: 11 (.google.cloud.pubsublite.v1.SeekRequest)
    # Field: flow_control Type: 11 (.google.cloud.pubsublite.v1.FlowControlRequest)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse ===
    # Fields for MessageResponse
    # Field: messages Type: 11 (.google.cloud.pubsublite.v1.SequencedMessage)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse ===
    # Fields for SubscribeResponse
    # Field: initial Type: 11 (.google.cloud.pubsublite.v1.InitialSubscribeResponse)
    # Field: seek Type: 11 (.google.cloud.pubsublite.v1.SeekResponse)
    # Field: messages Type: 11 (.google.cloud.pubsublite.v1.MessageResponse)

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest ===
    # Fields for InitialPartitionAssignmentRequest
    # Field: subscription Type: 9 ()
    # Field: client_id Type: 12 ()

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment ===
    # Fields for PartitionAssignment
    # Field: partitions Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck ===
    # Fields for PartitionAssignmentAck

# === Message: Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest ===
    # Fields for PartitionAssignmentRequest
    # Field: initial Type: 11 (.google.cloud.pubsublite.v1.InitialPartitionAssignmentRequest)
    # Field: ack Type: 11 (.google.cloud.pubsublite.v1.PartitionAssignmentAck)

# === Service Client: Google::Cloud::Pubsublite::V1::Subscriber::SubscriberServiceClient ===
package Google::Cloud::Pubsublite::V1::Subscriber::SubscriberServiceClient;

=pod

=head2 Service Client: Google::Cloud::Pubsublite::V1::Subscriber::SubscriberServiceClient

Client stub representing the remote C<SubscriberService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsublite.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsublite.googleapis.com:443' );

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

sub subscribe {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.SubscriberService',
        method         => 'Subscribe',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse',
    });
}

# === Service Client: Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentServiceClient ===
package Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentServiceClient

Client stub representing the remote C<PartitionAssignmentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsublite.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsublite.googleapis.com:443' );

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

sub assign_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.PartitionAssignmentService',
        method         => 'AssignPartitions',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Pubsublite::V1::Subscriber - Compiled Protocol Buffers messages for google/cloud/pubsublite/v1/subscriber.proto

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1::Subscriber;

    my $msg = Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest->new({
        subscription => $subscription,
        partition => $partition,
        initial_location => $initial_location,
    });

    # Read or update a field
    my $val = $msg->subscription();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/pubsublite/v1/subscriber.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest

The first request that must be sent on a newly-opened stream. The client must
wait for the response before sending subsequent requests on the stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription from which to receive messages.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

The partition from which to receive messages. Partitions are zero indexed,
so `partition` must be in the range [0, topic.num_partitions).

=item * C<< $msg->initial_location() >> / C<< $msg->initial_location($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest>)

Optional. Initial target location within the message backlog. If not set,
messages will be delivered from the commit cursor for the given
subscription and partition.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse

Response to an InitialSubscribeRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The cursor from which the subscriber will start receiving messages once
flow control tokens become available.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest

Request to update the stream's delivery cursor based on the given target.
Resets the server available tokens to 0. SeekRequests past head result in
stream breakage.

SeekRequests may not be sent while another SeekRequest is outstanding (i.e.,
has not received a SeekResponse) on the same stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->named_target() >> / C<< $msg->named_target($value) >>

Type: C<Enum> (L<Google::Cloud::Pubsublite::V1::SeekRequest::NamedTarget>)

A named target.

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

A target corresponding to the cursor, pointing to anywhere in the
topic partition.

=back

=head3 Enum: SeekRequest::NamedTarget

=over 4

=item * C<NAMED_TARGET_UNSPECIFIED> => C<0>

=item * C<HEAD> => C<1>

=item * C<COMMITTED_CURSOR> => C<2>

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse

Response to a SeekRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The new delivery cursor for the current stream.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest

Request to grant tokens to the server, requesting delivery of messages when
they become available.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allowed_messages() >> / C<< $msg->allowed_messages($value) >>

Type: C<Int64>

The number of message tokens to grant. Must be greater than or equal to 0.

=item * C<< $msg->allowed_bytes() >> / C<< $msg->allowed_bytes($value) >>

Type: C<Int64>

The number of byte tokens to grant. Must be greater than or equal to 0.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest

A request sent from the client to the server on a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial() >> / C<< $msg->initial($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest>)

Initial request on the stream.

=item * C<< $msg->seek() >> / C<< $msg->seek($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest>)

Request to update the stream's delivery cursor.

=item * C<< $msg->flow_control() >> / C<< $msg->flow_control($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest>)

Request to grant tokens to the server,

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse

Response containing a list of messages. Upon delivering a MessageResponse to
the client, the server:
*  Updates the stream's delivery cursor to one greater than the cursor of the
   last message in the list.
*  Subtracts the total number of bytes and messages from the tokens available
   to the server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::SequencedMessage>)

Messages from the topic partition.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse

Response to SubscribeRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial() >> / C<< $msg->initial($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse>)

Initial response on the stream.

=item * C<< $msg->seek() >> / C<< $msg->seek($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse>)

Response to a Seek operation.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse>)

Response containing messages from the topic partition.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest

The first request that must be sent on a newly-opened stream. The client must
wait for the response before sending subsequent requests on the stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription name. Structured like:
projects/<project number>/locations/<zone name>/subscriptions/<subscription
id>

=item * C<< $msg->client_id() >> / C<< $msg->client_id($value) >>

Type: C<Bytes>

An opaque, unique client identifier. This field must be exactly 16 bytes
long and is interpreted as an unsigned 128 bit integer. Other size values
will be rejected and the stream will be failed with a non-retryable error.

This field is large enough to fit a uuid from standard uuid algorithms like
uuid1 or uuid4, which should be used to generate this number. The same
identifier should be reused following disconnections with retryable stream
errors.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment

PartitionAssignments should not race with acknowledgements. There
should be exactly one unacknowledged PartitionAssignment at a time. If not,
the client must break the stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Int64>

The list of partition numbers this subscriber is assigned to.

=back

=head2 Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck

Acknowledge receipt and handling of the previous assignment.
If not sent within a short period after receiving the assignment,
partitions may remain unassigned for a period of time until the
client is known to be inactive, after which time the server will break the
stream.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest

A request on the PartitionAssignment stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial() >> / C<< $msg->initial($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest>)

Initial request on the stream.

=item * C<< $msg->ack() >> / C<< $msg->ack($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck>)

Acknowledgement of a partition assignment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Pubsublite::V1::Subscriber::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
