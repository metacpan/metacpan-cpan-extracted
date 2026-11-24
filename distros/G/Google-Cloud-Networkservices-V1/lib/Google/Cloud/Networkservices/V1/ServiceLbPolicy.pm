package Google::Cloud::Networkservices::V1::ServiceLbPolicy;

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
Cjdnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL3NlcnZpY2VfbGJfcG9saWN5LnBy
b3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byKMDQoPU2VydmljZUxiUG9saWN5EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJACgtjcmVh
dGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZRJZCgZsYWJlbHMYBCADKAsyPC5nb29nbGUuY2xvdWQubmV0d29y
a3NlcnZpY2VzLnYxLlNlcnZpY2VMYlBvbGljeS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMS
JQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAVILZGVzY3JpcHRpb24ShgEKGGxvYWRfYmFsYW5j
aW5nX2FsZ29yaXRobRgGIAEoDjJHLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEu
U2VydmljZUxiUG9saWN5LkxvYWRCYWxhbmNpbmdBbGdvcml0aG1CA+BBAVIWbG9hZEJhbGFu
Y2luZ0FsZ29yaXRobRJ3ChNhdXRvX2NhcGFjaXR5X2RyYWluGAggASgLMkIuZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5TZXJ2aWNlTGJQb2xpY3kuQXV0b0NhcGFjaXR5RHJh
aW5CA+BBAVIRYXV0b0NhcGFjaXR5RHJhaW4SbQoPZmFpbG92ZXJfY29uZmlnGAogASgLMj8u
Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5TZXJ2aWNlTGJQb2xpY3kuRmFpbG92
ZXJDb25maWdCA+BBAVIOZmFpbG92ZXJDb25maWcScAoQaXNvbGF0aW9uX2NvbmZpZxgLIAEo
CzJALmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuU2VydmljZUxiUG9saWN5Lklz
b2xhdGlvbkNvbmZpZ0ID4EEBUg9pc29sYXRpb25Db25maWcaMAoRQXV0b0NhcGFjaXR5RHJh
aW4SGwoGZW5hYmxlGAEgASgIQgPgQQFSBmVuYWJsZRpRCg5GYWlsb3ZlckNvbmZpZxI/Chlm
YWlsb3Zlcl9oZWFsdGhfdGhyZXNob2xkGAEgASgFQgPgQQFSF2ZhaWxvdmVySGVhbHRoVGhy
ZXNob2xkGv4BCg9Jc29sYXRpb25Db25maWcSfwoVaXNvbGF0aW9uX2dyYW51bGFyaXR5GAEg
ASgOMkUuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5TZXJ2aWNlTGJQb2xpY3ku
SXNvbGF0aW9uR3JhbnVsYXJpdHlCA+BBAVIUaXNvbGF0aW9uR3JhbnVsYXJpdHkSagoOaXNv
bGF0aW9uX21vZGUYAiABKA4yPi5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlNl
cnZpY2VMYlBvbGljeS5Jc29sYXRpb25Nb2RlQgPgQQFSDWlzb2xhdGlvbk1vZGUaOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKb
AQoWTG9hZEJhbGFuY2luZ0FsZ29yaXRobRIoCiRMT0FEX0JBTEFOQ0lOR19BTEdPUklUSE1f
VU5TUEVDSUZJRUQQABISCg5TUFJBWV9UT19XT1JMRBADEhMKD1NQUkFZX1RPX1JFR0lPThAE
EhcKE1dBVEVSRkFMTF9CWV9SRUdJT04QBRIVChFXQVRFUkZBTExfQllfWk9ORRAGIkkKFElz
b2xhdGlvbkdyYW51bGFyaXR5EiUKIUlTT0xBVElPTl9HUkFOVUxBUklUWV9VTlNQRUNJRklF
RBAAEgoKBlJFR0lPThABIkgKDUlzb2xhdGlvbk1vZGUSHgoaSVNPTEFUSU9OX01PREVfVU5T
UEVDSUZJRUQQABILCgdORUFSRVNUEAESCgoGU1RSSUNUEAI6ggHqQX8KLm5ldHdvcmtzZXJ2
aWNlcy5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlTGJQb2xpY3kSTXByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlTGJQb2xpY2llcy97c2VydmljZV9sYl9w
b2xpY3l9IqoBChxMaXN0U2VydmljZUxiUG9saWNpZXNSZXF1ZXN0Ek4KBnBhcmVudBgBIAEo
CUI24EEC+kEwEi5uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vU2VydmljZUxiUG9s
aWN5UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2Vu
GAMgASgJUglwYWdlVG9rZW4iywEKHUxpc3RTZXJ2aWNlTGJQb2xpY2llc1Jlc3BvbnNlEmAK
E3NlcnZpY2VfbGJfcG9saWNpZXMYASADKAsyMC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxLlNlcnZpY2VMYlBvbGljeVIRc2VydmljZUxiUG9saWNpZXMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJl
YWNoYWJsZSJnChlHZXRTZXJ2aWNlTGJQb2xpY3lSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBB
AvpBMAoubmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VMYlBvbGljeVIE
bmFtZSKHAgocQ3JlYXRlU2VydmljZUxiUG9saWN5UmVxdWVzdBJOCgZwYXJlbnQYASABKAlC
NuBBAvpBMBIubmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VMYlBvbGlj
eVIGcGFyZW50EjQKFHNlcnZpY2VfbGJfcG9saWN5X2lkGAIgASgJQgPgQQJSEXNlcnZpY2VM
YlBvbGljeUlkEmEKEXNlcnZpY2VfbGJfcG9saWN5GAMgASgLMjAuZ29vZ2xlLmNsb3VkLm5l
dHdvcmtzZXJ2aWNlcy52MS5TZXJ2aWNlTGJQb2xpY3lCA+BBAlIPc2VydmljZUxiUG9saWN5
IsMBChxVcGRhdGVTZXJ2aWNlTGJQb2xpY3lSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEmEKEXNlcnZp
Y2VfbGJfcG9saWN5GAIgASgLMjAuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5T
ZXJ2aWNlTGJQb2xpY3lCA+BBAlIPc2VydmljZUxiUG9saWN5ImoKHERlbGV0ZVNlcnZpY2VM
YlBvbGljeVJlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5uZXR3b3Jrc2VydmljZXMu
Z29vZ2xlYXBpcy5jb20vU2VydmljZUxiUG9saWN5UgRuYW1lQvUBCiNjb20uZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZXJ2aWNlcy52MUIUU2VydmljZUxiUG9saWN5UHJvdG9QAVpNY2xvdWQu
Z29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VydmljZXMvYXBpdjEvbmV0d29ya3NlcnZpY2VzcGI7
bmV0d29ya3NlcnZpY2VzcGKqAh9Hb29nbGUuQ2xvdWQuTmV0d29ya1NlcnZpY2VzLlYxygIf
R29vZ2xlXENsb3VkXE5ldHdvcmtTZXJ2aWNlc1xWMeoCIkdvb2dsZTo6Q2xvdWQ6Ok5ldHdv
cmtTZXJ2aWNlczo6VjFKyksKBxIFDgCBAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoC
AwMSAxUAKQoICgEIEgMXADwKCQoCCCUSAxcAPAoICgEIEgMYAGQKCQoCCAsSAxgAZAoICgEI
EgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADUKCQoCCAgSAxoANQoICgEIEgMbADwKCQoCCAES
AxsAPAoICgEIEgMcADwKCQoCCCkSAxwAPAoICgEIEgMdADsKCQoCCC0SAx0AOwqLAQoCBAAS
BSEAnwEBGn4gU2VydmljZUxiUG9saWN5IGhvbGRzIGdsb2JhbCBsb2FkIGJhbGFuY2luZyBh
bmQgdHJhZmZpYyBkaXN0cmlidXRpb24KIGNvbmZpZ3VyYXRpb24gdGhhdCBjYW4gYmUgYXBw
bGllZCB0byBhIEJhY2tlbmRTZXJ2aWNlLgoKCgoDBAABEgMhCBcKCwoDBAAHEgQiAiUECg0K
BQQAB50IEgQiAiUECn0KBAQAAwASBCkCMAMabyBPcHRpb24gdG8gc3BlY2lmeSBpZiBhbiB1
bmhlYWx0aHkgSUcvTkVHIHNob3VsZCBiZSBjb25zaWRlcmVkIGZvciBnbG9iYWwKIGxvYWQg
YmFsYW5jaW5nIGFuZCB0cmFmZmljIHJvdXRpbmcuCgoMCgUEAAMAARIDKQobCrYCCgYEAAMA
AgASAy8EPRqmAiBPcHRpb25hbC4gSWYgc2V0IHRvICdUcnVlJywgYW4gdW5oZWFsdGh5IElH
L05FRyB3aWxsIGJlIHNldCBhcyBkcmFpbmVkLgogLSBBbiBJRy9ORUcgaXMgY29uc2lkZXJl
ZCB1bmhlYWx0aHkgaWYgbGVzcyB0aGFuIDI1JSBvZiB0aGUKIGluc3RhbmNlcy9lbmRwb2lu
dHMgaW4gdGhlIElHL05FRyBhcmUgaGVhbHRoeS4KIC0gVGhpcyBvcHRpb24gd2lsbCBuZXZl
ciByZXN1bHQgaW4gZHJhaW5pbmcgbW9yZSB0aGFuIDUwJSBvZiB0aGUKIGNvbmZpZ3VyZWQg
SUdzL05FR3MgZm9yIHRoZSBCYWNrZW5kIFNlcnZpY2UuCgoOCgcEAAMAAgAFEgMvBAgKDgoH
BAADAAIAARIDLwkPCg4KBwQAAwACAAMSAy8SEwoOCgcEAAMAAgAIEgMvFDwKEQoKBAADAAIA
CJwIABIDLxU7Cn8KBAQAAwESBDQCPQMacSBPcHRpb24gdG8gc3BlY2lmeSBoZWFsdGggYmFz
ZWQgZmFpbG92ZXIgYmVoYXZpb3IuCiBUaGlzIGlzIG5vdCByZWxhdGVkIHRvIE5ldHdvcmsg
bG9hZCBiYWxhbmNlciBGYWlsb3ZlclBvbGljeS4KCgwKBQQAAwEBEgM0ChgKsQMKBgQAAwEC
ABIEOwQ8MRqgAyBPcHRpb25hbC4gVGhlIHBlcmNlbnRhZ2UgdGhyZXNob2xkIHRoYXQgYSBs
b2FkIGJhbGFuY2VyIHdpbGwgYmVnaW4gdG8KIHNlbmQgdHJhZmZpYyB0byBmYWlsb3ZlciBi
YWNrZW5kcy4gSWYgdGhlIHBlcmNlbnRhZ2Ugb2YgZW5kcG9pbnRzIGluIGEKIE1JRy9ORUcg
aXMgc21hbGxlciB0aGFuIHRoaXMgdmFsdWUsIHRyYWZmaWMgd291bGQgYmUgc2VudCB0byBm
YWlsb3ZlcgogYmFja2VuZHMgaWYgcG9zc2libGUuIFRoaXMgZmllbGQgc2hvdWxkIGJlIHNl
dCB0byBhIHZhbHVlIGJldHdlZW4gMQogYW5kIDk5LiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyA1
MCBmb3IgR2xvYmFsIGV4dGVybmFsIEhUVFAoUykgbG9hZCBiYWxhbmNlcgogKGNsYXNzaWMp
IGFuZCBQcm94eWxlc3Mgc2VydmljZSBtZXNoLCBhbmQgNzAgZm9yIG90aGVycy4KCg4KBwQA
AwECAAUSAzsECQoOCgcEAAMBAgABEgM7CiMKDgoHBAADAQIAAxIDOyYnCg4KBwQAAwECAAgS
AzwIMAoRCgoEAAMBAgAInAgAEgM8CS8KXwoEBAADAhIEQQJIAxpRIENvbmZpZ3VyYXRpb24g
dG8gcHJvdmlkZSBpc29sYXRpb24gc3VwcG9ydCBmb3IgdGhlIGFzc29jaWF0ZWQgQmFja2Vu
ZAogU2VydmljZS4KCgwKBQQAAwIBEgNBChkKSwoGBAADAgIAEgRDBEQxGjsgT3B0aW9uYWwu
IFRoZSBpc29sYXRpb24gZ3JhbnVsYXJpdHkgb2YgdGhlIGxvYWQgYmFsYW5jZXIuCgoOCgcE
AAMCAgAGEgNDBBgKDgoHBAADAgIAARIDQxkuCg4KBwQAAwICAAMSA0MxMgoOCgcEAAMCAgAI
EgNECDAKEQoKBAADAgIACJwIABIDRAkvCkMKBgQAAwICARIDRwROGjQgT3B0aW9uYWwuIFRo
ZSBpc29sYXRpb24gbW9kZSBvZiB0aGUgbG9hZCBiYWxhbmNlci4KCg4KBwQAAwICAQYSA0cE
EQoOCgcEAAMCAgEBEgNHEiAKDgoHBAADAgIBAxIDRyMkCg4KBwQAAwICAQgSA0clTQoRCgoE
AAMCAgEInAgAEgNHJkwKPwoEBAAEABIESwJhAxoxIFRoZSBnbG9iYWwgbG9hZCBiYWxhbmNp
bmcgYWxnb3JpdGhtIHRvIGJlIHVzZWQuCgoMCgUEAAQAARIDSwcdCkgKBgQABAACABIDTQQt
GjkgVGhlIHR5cGUgb2YgdGhlIGxvYWRiYWxhbmNpbmcgYWxnb3JpdGhtIGlzIHVuc3BlY2lm
aWVkLgoKDgoHBAAEAAIAARIDTQQoCg4KBwQABAACAAISA00rLApoCgYEAAQAAgESA1EEFxpZ
IEJhbGFuY2UgdHJhZmZpYyBhY3Jvc3MgYWxsIGJhY2tlbmRzIGFjcm9zcyB0aGUgd29ybGQg
cHJvcG9ydGlvbmFsbHkgYmFzZWQKIG9uIGNhcGFjaXR5LgoKDgoHBAAEAAIBARIDUQQSCg4K
BwQABAACAQISA1EVFgrEAQoGBAAEAAICEgNWBBgatAEgRGlyZWN0IHRyYWZmaWMgdG8gdGhl
IG5lYXJlc3QgcmVnaW9uIHdpdGggZW5kcG9pbnRzIGFuZCBjYXBhY2l0eSBiZWZvcmUKIHNw
aWxsaW5nIG92ZXIgdG8gb3RoZXIgcmVnaW9ucyBhbmQgc3ByZWFkIHRoZSB0cmFmZmljIGZy
b20gZWFjaCBjbGllbnQgdG8KIGFsbCB0aGUgTUlHcy9ORUdzIGluIGEgcmVnaW9uLgoKDgoH
BAAEAAICARIDVgQTCg4KBwQABAACAgISA1YWFwr9AQoGBAAEAAIDEgNcBBwa7QEgRGlyZWN0
IHRyYWZmaWMgdG8gdGhlIG5lYXJlc3QgcmVnaW9uIHdpdGggZW5kcG9pbnRzIGFuZCBjYXBh
Y2l0eSBiZWZvcmUKIHNwaWxsaW5nIG92ZXIgdG8gb3RoZXIgcmVnaW9ucy4gQWxsIE1JR3Mv
TkVHcyB3aXRoaW4gYSByZWdpb24gYXJlIGV2ZW5seQogbG9hZGVkIGJ1dCBlYWNoIGNsaWVu
dCBtaWdodCBub3Qgc3ByZWFkIHRoZSB0cmFmZmljIHRvIGFsbCB0aGUgTUlHcy9ORUdzCiBp
biB0aGUgcmVnaW9uLgoKDgoHBAAEAAIDARIDXAQXCg4KBwQABAACAwISA1waGwp2CgYEAAQA
AgQSA2AEGhpnIEF0dGVtcHQgdG8ga2VlcCB0cmFmZmljIGluIGEgc2luZ2xlIHpvbmUgY2xv
c2VzdCB0byB0aGUgY2xpZW50LCBiZWZvcmUKIHNwaWxsaW5nIG92ZXIgdG8gb3RoZXIgem9u
ZXMuCgoOCgcEAAQAAgQBEgNgBBUKDgoHBAAEAAIEAhIDYBgZCj4KBAQABAESBGQCawMaMCBU
aGUgZ3JhbnVsYXJpdHkgb2YgdGhpcyBpc29sYXRpb24gcmVzdHJpY3Rpb24uCgoMCgUEAAQB
ARIDZAcbCoEBCgYEAAQBAgASA2cEKhpyIE5vIGlzb2xhdGlvbiBpcyBjb25maWd1cmVkIGZv
ciB0aGUgYmFja2VuZCBzZXJ2aWNlLiBUcmFmZmljIGNhbiBvdmVyZmxvdwogYmFzZWQgb24g
dGhlIGxvYWQgYmFsYW5jaW5nIGFsZ29yaXRobS4KCg4KBwQABAECAAESA2cEJQoOCgcEAAQB
AgACEgNnKCkKVQoGBAAEAQIBEgNqBA8aRiBUcmFmZmljIGZvciB0aGlzIHNlcnZpY2Ugd2ls
bCBiZSBpc29sYXRlZCBhdCB0aGUgY2xvdWQgcmVnaW9uIGxldmVsLgoKDgoHBAAEAQIBARID
agQKCg4KBwQABAECAQISA2oNDgqQAQoEBAAEAhIEbwJ5AxqBASBUaGUgbW9kZSBvZiB0aGlz
IGlzb2xhdGlvbiByZXN0cmljdGlvbiwgZGVmaW5pbmcgd2hldGhlciBjbGllbnRzIGluIGEg
Z2l2ZW4KIHJlZ2lvbiBhcmUgYWxsb3dlZCB0byByZWFjaCBvdXQgdG8gYW5vdGhlciByZWdp
b24uCgoMCgUEAAQCARIDbwcUCkkKBgQABAICABIDcQQjGjogTm8gaXNvbGF0aW9uIG1vZGUg
aXMgY29uZmlndXJlZCBmb3IgdGhlIGJhY2tlbmQgc2VydmljZS4KCg4KBwQABAICAAESA3EE
HgoOCgcEAAQCAgACEgNxISIKPAoGBAAEAgIBEgN0BBAaLSBUcmFmZmljIHdpbGwgYmUgc2Vu
dCB0byB0aGUgbmVhcmVzdCByZWdpb24uCgoOCgcEAAQCAgEBEgN0BAsKDgoHBAAEAgIBAhID
dA4PCnEKBgQABAICAhIDeAQPGmIgVHJhZmZpYyB3aWxsIGZhaWwgaWYgbm8gc2VydmluZyBi
YWNrZW5kcyBhcmUgYXZhaWxhYmxlIGluIHRoZSBzYW1lIHJlZ2lvbgogYXMgdGhlIGxvYWQg
YmFsYW5jZXIuCgoOCgcEAAQCAgIBEgN4BAoKDgoHBAAEAgICAhIDeA0OCqsBCgQEAAIAEgN9
Aj0anQEgSWRlbnRpZmllci4gTmFtZSBvZiB0aGUgU2VydmljZUxiUG9saWN5IHJlc291cmNl
LiBJdCBtYXRjaGVzIHBhdHRlcm4KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vc2VydmljZUxiUG9saWNpZXMve3NlcnZpY2VfbGJfcG9saWN5X25hbWV9YC4K
CgwKBQQAAgAFEgN9AggKDAoFBAACAAESA30JDQoMCgUEAAIAAxIDfRARCgwKBQQAAgAIEgN9
EjwKDwoIBAACAAicCAASA30TOwpMCgQEAAIBEgaAAQKBATIaPCBPdXRwdXQgb25seS4gVGhl
IHRpbWVzdGFtcCB3aGVuIHRoaXMgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoNCgUEAAIBBhIE
gAECGwoNCgUEAAIBARIEgAEcJwoNCgUEAAIBAxIEgAEqKwoNCgUEAAIBCBIEgQEGMQoQCggE
AAIBCJwIABIEgQEHMApRCgQEAAICEgaEAQKFATIaQSBPdXRwdXQgb25seS4gVGhlIHRpbWVz
dGFtcCB3aGVuIHRoaXMgcmVzb3VyY2Ugd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQAAgIGEgSE
AQIbCg0KBQQAAgIBEgSEARwnCg0KBQQAAgIDEgSEASorCg0KBQQAAgIIEgSFAQYxChAKCAQA
AgIInAgAEgSFAQcwClkKBAQAAgMSBIgBAkoaSyBPcHRpb25hbC4gU2V0IG9mIGxhYmVsIHRh
Z3MgYXNzb2NpYXRlZCB3aXRoIHRoZSBTZXJ2aWNlTGJQb2xpY3kgcmVzb3VyY2UuCgoNCgUE
AAIDBhIEiAECFQoNCgUEAAIDARIEiAEWHAoNCgUEAAIDAxIEiAEfIAoNCgUEAAIDCBIEiAEh
SQoQCggEAAIDCJwIABIEiAEiSApfCgQEAAIEEgSMAQJCGlEgT3B0aW9uYWwuIEEgZnJlZS10
ZXh0IGRlc2NyaXB0aW9uIG9mIHRoZSByZXNvdXJjZS4gTWF4IGxlbmd0aCAxMDI0CiBjaGFy
YWN0ZXJzLgoKDQoFBAACBAUSBIwBAggKDQoFBAACBAESBIwBCRQKDQoFBAACBAMSBIwBFxgK
DQoFBAACBAgSBIwBGUEKEAoIBAACBAicCAASBIwBGkAKegoEBAACBRIGkAECkQEvGmogT3B0
aW9uYWwuIFRoZSB0eXBlIG9mIGxvYWQgYmFsYW5jaW5nIGFsZ29yaXRobSB0byBiZSB1c2Vk
LiBUaGUgZGVmYXVsdAogYmVoYXZpb3IgaXMgV0FURVJGQUxMX0JZX1JFR0lPTi4KCg0KBQQA
AgUGEgSQAQIYCg0KBQQAAgUBEgSQARkxCg0KBQQAAgUDEgSQATQ1Cg0KBQQAAgUIEgSRAQYu
ChAKCAQAAgUInAgAEgSRAQctCoYBCgQEAAIGEgaVAQKWAS8adiBPcHRpb25hbC4gQ29uZmln
dXJhdGlvbiB0byBhdXRvbWF0aWNhbGx5IG1vdmUgdHJhZmZpYyBhd2F5IGZvciB1bmhlYWx0
aHkKIElHL05FRyBmb3IgdGhlIGFzc29jaWF0ZWQgQmFja2VuZCBTZXJ2aWNlLgoKDQoFBAAC
BgYSBJUBAhMKDQoFBAACBgESBJUBFCcKDQoFBAACBgMSBJUBKisKDQoFBAACBggSBJYBBi4K
EAoIBAACBgicCAASBJYBBy0KSQoEBAACBxIEmQECTxo7IE9wdGlvbmFsLiBDb25maWd1cmF0
aW9uIHJlbGF0ZWQgdG8gaGVhbHRoIGJhc2VkIGZhaWxvdmVyLgoKDQoFBAACBwYSBJkBAhAK
DQoFBAACBwESBJkBESAKDQoFBAACBwMSBJkBIyUKDQoFBAACBwgSBJkBJk4KEAoIBAACBwic
CAASBJkBJ00KawoEBAACCBIGnQECngEvGlsgT3B0aW9uYWwuIENvbmZpZ3VyYXRpb24gdG8g
cHJvdmlkZSBpc29sYXRpb24gc3VwcG9ydCBmb3IgdGhlIGFzc29jaWF0ZWQKIEJhY2tlbmQg
U2VydmljZS4KCg0KBQQAAggGEgSdAQIRCg0KBQQAAggBEgSdARIiCg0KBQQAAggDEgSdASUn
Cg0KBQQAAggIEgSeAQYuChAKCAQAAggInAgAEgSeAQctCkMKAgQBEgaiAQC0AQEaNSBSZXF1
ZXN0IHVzZWQgd2l0aCB0aGUgTGlzdFNlcnZpY2VMYlBvbGljaWVzIG1ldGhvZC4KCgsKAwQB
ARIEogEIJAqtAQoEBAECABIGpgECqwEEGpwBIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQg
bG9jYXRpb24gZnJvbSB3aGljaCB0aGUgU2VydmljZUxiUG9saWNpZXMgc2hvdWxkCiBiZSBs
aXN0ZWQsIHNwZWNpZmllZCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQBAgAFEgSmAQIICg0KBQQBAgABEgSmAQkPCg0K
BQQBAgADEgSmARITCg8KBQQBAgAIEgamARSrAQMKEAoIBAECAAicCAASBKcBBCoKEQoHBAEC
AAifCBIGqAEEqgEFCkcKBAQBAgESBK4BAhYaOSBNYXhpbXVtIG51bWJlciBvZiBTZXJ2aWNl
TGJQb2xpY2llcyB0byByZXR1cm4gcGVyIGNhbGwuCgoNCgUEAQIBBRIErgECBwoNCgUEAQIB
ARIErgEIEQoNCgUEAQIBAxIErgEUFQrPAQoEBAECAhIEswECGBrAASBUaGUgdmFsdWUgcmV0
dXJuZWQgYnkgdGhlIGxhc3QgYExpc3RTZXJ2aWNlTGJQb2xpY2llc1Jlc3BvbnNlYAogSW5k
aWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRpbnVhdGlvbiBvZiBhIHByaW9yIGBMaXN0Um91
dGVyc2AgY2FsbCwKIGFuZCB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUgbmV4
dCBwYWdlIG9mIGRhdGEuCgoNCgUEAQICBRIEswECCAoNCgUEAQICARIEswEJEwoNCgUEAQIC
AxIEswEWFwpGCgIEAhIGtwEAxAEBGjggUmVzcG9uc2UgcmV0dXJuZWQgYnkgdGhlIExpc3RT
ZXJ2aWNlTGJQb2xpY2llcyBtZXRob2QuCgoLCgMEAgESBLcBCCUKMgoEBAICABIEuQECMxok
IExpc3Qgb2YgU2VydmljZUxiUG9saWN5IHJlc291cmNlcy4KCg0KBQQCAgAEEgS5AQIKCg0K
BQQCAgAGEgS5AQsaCg0KBQQCAgABEgS5ARsuCg0KBQQCAgADEgS5ATEyCukBCgQEAgIBEgS+
AQIdGtoBIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUgcmVzdWx0cyB0aGFuIHRob3NlIGFwcGVh
cmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBgbmV4dF9wYWdlX3Rva2VuYCBpcyBpbmNs
dWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1bHRzLCBjYWxsIHRoaXMKIG1ldGhv
ZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgYG5leHRfcGFnZV90b2tlbmAgYXMgYHBhZ2Vf
dG9rZW5gLgoKDQoFBAICAQUSBL4BAggKDQoFBAICAQESBL4BCRgKDQoFBAICAQMSBL4BGxwK
tQEKBAQCAgISBMMBAiIapgEgVW5yZWFjaGFibGUgcmVzb3VyY2VzLiBQb3B1bGF0ZWQgd2hl
biB0aGUgcmVxdWVzdCBhdHRlbXB0cyB0byBsaXN0IGFsbAogcmVzb3VyY2VzIGFjcm9zcyBh
bGwgc3VwcG9ydGVkIGxvY2F0aW9ucywgd2hpbGUgc29tZSBsb2NhdGlvbnMgYXJlCiB0ZW1w
b3JhcmlseSB1bmF2YWlsYWJsZS4KCg0KBQQCAgIEEgTDAQIKCg0KBQQCAgIFEgTDAQsRCg0K
BQQCAgIBEgTDARIdCg0KBQQCAgIDEgTDASAhCj4KAgQDEgbHAQDQAQEaMCBSZXF1ZXN0IHVz
ZWQgYnkgdGhlIEdldFNlcnZpY2VMYlBvbGljeSBtZXRob2QuCgoLCgMEAwESBMcBCCEKmAEK
BAQDAgASBsoBAs8BBBqHASBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBTZXJ2aWNlTGJQb2xp
Y3kgdG8gZ2V0LiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZUxiUG9saWNpZXMvKmAuCgoNCgUEAwIABRIE
ygECCAoNCgUEAwIAARIEygEJDQoNCgUEAwIAAxIEygEQEQoPCgUEAwIACBIGygESzwEDChAK
CAQDAgAInAgAEgTLAQQqChEKBwQDAgAInwgSBswBBM4BBQo7CgIEBBIG0wEA5gEBGi0gUmVx
dWVzdCB1c2VkIGJ5IHRoZSBTZXJ2aWNlTGJQb2xpY3kgbWV0aG9kLgoKCwoDBAQBEgTTAQgk
CokBCgQEBAIAEgbWAQLbAQQaeSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0
aGUgU2VydmljZUxiUG9saWN5LiBNdXN0IGJlIGluIHRoZQogZm9ybWF0IGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoFBAQCAAUSBNYBAggKDQoFBAQC
AAESBNYBCQ8KDQoFBAQCAAMSBNYBEhMKDwoFBAQCAAgSBtYBFNsBAwoQCggEBAIACJwIABIE
1wEEKgoRCgcEBAIACJ8IEgbYAQTaAQUK8AEKBAQEAgESBOEBAksa4QEgUmVxdWlyZWQuIFNo
b3J0IG5hbWUgb2YgdGhlIFNlcnZpY2VMYlBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVk
LgogRS5nLiBmb3IgcmVzb3VyY2UgbmFtZQogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9zZXJ2aWNlTGJQb2xpY2llcy97c2VydmljZV9sYl9wb2xpY3lfbmFt
ZX1gLgogdGhlIGlkIGlzIHZhbHVlIG9mIHtzZXJ2aWNlX2xiX3BvbGljeV9uYW1lfQoKDQoF
BAQCAQUSBOEBAggKDQoFBAQCAQESBOEBCR0KDQoFBAQCAQMSBOEBICEKDQoFBAQCAQgSBOEB
IkoKEAoIBAQCAQicCAASBOEBI0kKQwoEBAQCAhIG5AEC5QEvGjMgUmVxdWlyZWQuIFNlcnZp
Y2VMYlBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgoKDQoFBAQCAgYSBOQBAhEKDQoF
BAQCAgESBOQBEiMKDQoFBAQCAgMSBOQBJicKDQoFBAQCAggSBOUBBi4KEAoIBAQCAgicCAAS
BOUBBy0KQQoCBAUSBukBAPUBARozIFJlcXVlc3QgdXNlZCBieSB0aGUgVXBkYXRlU2Vydmlj
ZUxiUG9saWN5IG1ldGhvZC4KCgsKAwQFARIE6QEIJArhAgoEBAUCABIG7wEC8AEvGtACIE9w
dGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJl
IG92ZXJ3cml0dGVuIGluIHRoZQogU2VydmljZUxiUG9saWN5IHJlc291cmNlIGJ5IHRoZSB1
cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJl
bGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxk
IHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQogdXNl
ciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVy
d3JpdHRlbi4KCg0KBQQFAgAGEgTvAQIbCg0KBQQFAgABEgTvARwnCg0KBQQFAgADEgTvASor
Cg0KBQQFAgAIEgTwAQYuChAKCAQFAgAInAgAEgTwAQctCj0KBAQFAgESBvMBAvQBLxotIFJl
cXVpcmVkLiBVcGRhdGVkIFNlcnZpY2VMYlBvbGljeSByZXNvdXJjZS4KCg0KBQQFAgEGEgTz
AQIRCg0KBQQFAgEBEgTzARIjCg0KBQQFAgEDEgTzASYnCg0KBQQFAgEIEgT0AQYuChAKCAQF
AgEInAgAEgT0AQctCkEKAgQGEgb4AQCBAgEaMyBSZXF1ZXN0IHVzZWQgYnkgdGhlIERlbGV0
ZVNlcnZpY2VMYlBvbGljeSBtZXRob2QuCgoLCgMEBgESBPgBCCQKmwEKBAQGAgASBvsBAoAC
BBqKASBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBTZXJ2aWNlTGJQb2xpY3kgdG8gZGVsZXRl
LiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2VydmljZUxiUG9saWNpZXMvKmAuCgoNCgUEBgIABRIE+wECCAoNCgUE
BgIAARIE+wEJDQoNCgUEBgIAAxIE+wEQEQoPCgUEBgIACBIG+wESgAIDChAKCAQGAgAInAgA
EgT8AQQqChEKBwQGAgAInwgSBv0BBP8BBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy ===
    # Fields for ServiceLbPolicy
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: load_balancing_algorithm Type: 14 (.google.cloud.networkservices.v1.ServiceLbPolicy.LoadBalancingAlgorithm)
    # Field: auto_capacity_drain Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy.AutoCapacityDrain)
    # Field: failover_config Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy.FailoverConfig)
    # Field: isolation_config Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy.IsolationConfig)

# Enum: ServiceLbPolicy::LoadBalancingAlgorithm
our $ServiceLbPolicy_LOAD_BALANCING_ALGORITHM_UNSPECIFIED = 0;
our $ServiceLbPolicy_SPRAY_TO_WORLD = 3;
our $ServiceLbPolicy_SPRAY_TO_REGION = 4;
our $ServiceLbPolicy_WATERFALL_BY_REGION = 5;
our $ServiceLbPolicy_WATERFALL_BY_ZONE = 6;

# Enum: ServiceLbPolicy::IsolationGranularity
our $ServiceLbPolicy_ISOLATION_GRANULARITY_UNSPECIFIED = 0;
our $ServiceLbPolicy_REGION = 1;

# Enum: ServiceLbPolicy::IsolationMode
our $ServiceLbPolicy_ISOLATION_MODE_UNSPECIFIED = 0;
our $ServiceLbPolicy_NEAREST = 1;
our $ServiceLbPolicy_STRICT = 2;

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesRequest ===
    # Fields for ListServiceLbPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesResponse ===
    # Fields for ListServiceLbPoliciesResponse
    # Field: service_lb_policies Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::GetServiceLbPolicyRequest ===
    # Fields for GetServiceLbPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::CreateServiceLbPolicyRequest ===
    # Fields for CreateServiceLbPolicyRequest
    # Field: parent Type: 9 ()
    # Field: service_lb_policy_id Type: 9 ()
    # Field: service_lb_policy Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy)

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::UpdateServiceLbPolicyRequest ===
    # Fields for UpdateServiceLbPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: service_lb_policy Type: 11 (.google.cloud.networkservices.v1.ServiceLbPolicy)

# === Message: Google::Cloud::Networkservices::V1::ServiceLbPolicy::DeleteServiceLbPolicyRequest ===
    # Fields for DeleteServiceLbPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceLbPolicy - Compiled Protocol Buffers messages for google/cloud/networkservices/v1/service_lb_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceLbPolicy;

    my $msg = Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1/service_lb_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy

ServiceLbPolicy holds global load balancing and traffic distribution
configuration that can be applied to a BackendService.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the ServiceLbPolicy resource. It matches pattern
`projects/{project}/locations/{location}/serviceLbPolicies/{service_lb_policy_name}`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this resource was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::LabelsEntry>)

Optional. Set of label tags associated with the ServiceLbPolicy resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A free-text description of the resource. Max length 1024
characters.

=item * C<< $msg->load_balancing_algorithm() >> / C<< $msg->load_balancing_algorithm($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::LoadBalancingAlgorithm>)

Optional. The type of load balancing algorithm to be used. The default
behavior is WATERFALL_BY_REGION.

=item * C<< $msg->auto_capacity_drain() >> / C<< $msg->auto_capacity_drain($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::AutoCapacityDrain>)

Optional. Configuration to automatically move traffic away for unhealthy
IG/NEG for the associated Backend Service.

=item * C<< $msg->failover_config() >> / C<< $msg->failover_config($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::FailoverConfig>)

Optional. Configuration related to health based failover.

=item * C<< $msg->isolation_config() >> / C<< $msg->isolation_config($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::IsolationConfig>)

Optional. Configuration to provide isolation support for the associated
Backend Service.

=back

=head3 Enum: ServiceLbPolicy::LoadBalancingAlgorithm

=over 4

=item * C<LOAD_BALANCING_ALGORITHM_UNSPECIFIED> => C<0>

=item * C<SPRAY_TO_WORLD> => C<3>

=item * C<SPRAY_TO_REGION> => C<4>

=item * C<WATERFALL_BY_REGION> => C<5>

=item * C<WATERFALL_BY_ZONE> => C<6>

=back

=head3 Enum: ServiceLbPolicy::IsolationGranularity

=over 4

=item * C<ISOLATION_GRANULARITY_UNSPECIFIED> => C<0>

=item * C<REGION> => C<1>

=back

=head3 Enum: ServiceLbPolicy::IsolationMode

=over 4

=item * C<ISOLATION_MODE_UNSPECIFIED> => C<0>

=item * C<NEAREST> => C<1>

=item * C<STRICT> => C<2>

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesRequest

Request used with the ListServiceLbPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the ServiceLbPolicies should
be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of ServiceLbPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListServiceLbPoliciesResponse`
Indicates that this is a continuation of a prior `ListRouters` call,
and that the system should return the next page of data.

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesResponse

Response returned by the ListServiceLbPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_lb_policies() >> / C<< $msg->service_lb_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy>)

List of ServiceLbPolicy resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable resources. Populated when the request attempts to list all
resources across all supported locations, while some locations are
temporarily unavailable.

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::GetServiceLbPolicyRequest

Request used by the GetServiceLbPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ServiceLbPolicy to get. Must be in the format
`projects/{project}/locations/{location}/serviceLbPolicies/*`.

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::CreateServiceLbPolicyRequest

Request used by the ServiceLbPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the ServiceLbPolicy. Must be in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->service_lb_policy_id() >> / C<< $msg->service_lb_policy_id($value) >>

Type: C<String>

Required. Short name of the ServiceLbPolicy resource to be created.
E.g. for resource name
`projects/{project}/locations/{location}/serviceLbPolicies/{service_lb_policy_name}`.
the id is value of {service_lb_policy_name}

=item * C<< $msg->service_lb_policy() >> / C<< $msg->service_lb_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy>)

Required. ServiceLbPolicy resource to be created.

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::UpdateServiceLbPolicyRequest

Request used by the UpdateServiceLbPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
ServiceLbPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->service_lb_policy() >> / C<< $msg->service_lb_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy>)

Required. Updated ServiceLbPolicy resource.

=back

=head2 Google::Cloud::Networkservices::V1::ServiceLbPolicy::DeleteServiceLbPolicyRequest

Request used by the DeleteServiceLbPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ServiceLbPolicy to delete. Must be in the format
`projects/{project}/locations/{location}/serviceLbPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1::ServiceLbPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
