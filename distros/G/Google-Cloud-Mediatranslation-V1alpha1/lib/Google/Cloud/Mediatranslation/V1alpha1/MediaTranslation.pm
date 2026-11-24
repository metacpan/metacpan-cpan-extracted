package Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Rpc::Status };
    eval { require Google::Api::Client };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvbWVkaWF0cmFuc2xhdGlvbi92MWFscGhhMS9tZWRpYV90cmFuc2xh
dGlvbi5wcm90bxImZ29vZ2xlLmNsb3VkLm1lZGlhdHJhbnNsYXRpb24udjFhbHBoYTEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90byLNAgoVVHJhbnNsYXRlU3BlZWNoQ29uZmlnEioK
DmF1ZGlvX2VuY29kaW5nGAEgASgJQgPgQQJSDWF1ZGlvRW5jb2RpbmcSNQoUc291cmNlX2xh
bmd1YWdlX2NvZGUYAiABKAlCA+BBAlISc291cmNlTGFuZ3VhZ2VDb2RlEjUKFHRhcmdldF9s
YW5ndWFnZV9jb2RlGAMgASgJQgPgQQJSEnRhcmdldExhbmd1YWdlQ29kZRJOCiFhbHRlcm5h
dGl2ZV9zb3VyY2VfbGFuZ3VhZ2VfY29kZXMYBiADKAlCA+BBAVIeYWx0ZXJuYXRpdmVTb3Vy
Y2VMYW5ndWFnZUNvZGVzEi8KEXNhbXBsZV9yYXRlX2hlcnR6GAQgASgFQgPgQQFSD3NhbXBs
ZVJhdGVIZXJ0ehIZCgVtb2RlbBgFIAEoCUID4EEBUgVtb2RlbCLHAgoeU3RyZWFtaW5nVHJh
bnNsYXRlU3BlZWNoQ29uZmlnEmUKDGF1ZGlvX2NvbmZpZxgBIAEoCzI9Lmdvb2dsZS5jbG91
ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYWxwaGExLlRyYW5zbGF0ZVNwZWVjaENvbmZpZ0ID4EEC
UgthdWRpb0NvbmZpZxIuChBzaW5nbGVfdXR0ZXJhbmNlGAIgASgIQgPgQQFSD3NpbmdsZVV0
dGVyYW5jZRIhCglzdGFiaWxpdHkYAyABKAlCA+BBAVIJc3RhYmlsaXR5Ei4KEHRyYW5zbGF0
aW9uX21vZGUYBCABKAlCA+BBAVIPdHJhbnNsYXRpb25Nb2RlEjsKF2Rpc2FibGVfaW50ZXJp
bV9yZXN1bHRzGAUgASgIQgPgQQFSFWRpc2FibGVJbnRlcmltUmVzdWx0cyLSAQofU3RyZWFt
aW5nVHJhbnNsYXRlU3BlZWNoUmVxdWVzdBJzChBzdHJlYW1pbmdfY29uZmlnGAEgASgLMkYu
Z29vZ2xlLmNsb3VkLm1lZGlhdHJhbnNsYXRpb24udjFhbHBoYTEuU3RyZWFtaW5nVHJhbnNs
YXRlU3BlZWNoQ29uZmlnSABSD3N0cmVhbWluZ0NvbmZpZxIlCg1hdWRpb19jb250ZW50GAIg
ASgMSABSDGF1ZGlvQ29udGVudEITChFzdHJlYW1pbmdfcmVxdWVzdCL5BAoeU3RyZWFtaW5n
VHJhbnNsYXRlU3BlZWNoUmVzdWx0EpQBChd0ZXh0X3RyYW5zbGF0aW9uX3Jlc3VsdBgBIAEo
CzJcLmdvb2dsZS5jbG91ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYWxwaGExLlN0cmVhbWluZ1Ry
YW5zbGF0ZVNwZWVjaFJlc3VsdC5UZXh0VHJhbnNsYXRpb25SZXN1bHRSFXRleHRUcmFuc2xh
dGlvblJlc3VsdBKXAQoYYXVkaW9fdHJhbnNsYXRpb25fcmVzdWx0GAIgASgLMl0uZ29vZ2xl
LmNsb3VkLm1lZGlhdHJhbnNsYXRpb24udjFhbHBoYTEuU3RyZWFtaW5nVHJhbnNsYXRlU3Bl
ZWNoUmVzdWx0LkF1ZGlvVHJhbnNsYXRpb25SZXN1bHRSFmF1ZGlvVHJhbnNsYXRpb25SZXN1
bHQSMgoScmVjb2duaXRpb25fcmVzdWx0GAMgASgJQgPgQQNSEXJlY29nbml0aW9uUmVzdWx0
EkYKHWRldGVjdGVkX3NvdXJjZV9sYW5ndWFnZV9jb2RlGAQgASgJQgPgQQNSGmRldGVjdGVk
U291cmNlTGFuZ3VhZ2VDb2RlGl4KFVRleHRUcmFuc2xhdGlvblJlc3VsdBIlCgt0cmFuc2xh
dGlvbhgBIAEoCUID4EEDUgt0cmFuc2xhdGlvbhIeCghpc19maW5hbBgCIAEoCEID4EEDUgdp
c0ZpbmFsGkoKFkF1ZGlvVHJhbnNsYXRpb25SZXN1bHQSMAoRYXVkaW9fdHJhbnNsYXRpb24Y
ASABKAxCA+BBA1IQYXVkaW9UcmFuc2xhdGlvbiKVAwogU3RyZWFtaW5nVHJhbnNsYXRlU3Bl
ZWNoUmVzcG9uc2USLQoFZXJyb3IYASABKAsyEi5nb29nbGUucnBjLlN0YXR1c0ID4EEDUgVl
cnJvchJjCgZyZXN1bHQYAiABKAsyRi5nb29nbGUuY2xvdWQubWVkaWF0cmFuc2xhdGlvbi52
MWFscGhhMS5TdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hSZXN1bHRCA+BBA1IGcmVzdWx0EokB
ChFzcGVlY2hfZXZlbnRfdHlwZRgDIAEoDjJYLmdvb2dsZS5jbG91ZC5tZWRpYXRyYW5zbGF0
aW9uLnYxYWxwaGExLlN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlc3BvbnNlLlNwZWVjaEV2
ZW50VHlwZUID4EEDUg9zcGVlY2hFdmVudFR5cGUiUQoPU3BlZWNoRXZlbnRUeXBlEiEKHVNQ
RUVDSF9FVkVOVF9UWVBFX1VOU1BFQ0lGSUVEEAASGwoXRU5EX09GX1NJTkdMRV9VVFRFUkFO
Q0UQATKlAgoYU3BlZWNoVHJhbnNsYXRpb25TZXJ2aWNlErMBChhTdHJlYW1pbmdUcmFuc2xh
dGVTcGVlY2gSRy5nb29nbGUuY2xvdWQubWVkaWF0cmFuc2xhdGlvbi52MWFscGhhMS5TdHJl
YW1pbmdUcmFuc2xhdGVTcGVlY2hSZXF1ZXN0GkguZ29vZ2xlLmNsb3VkLm1lZGlhdHJhbnNs
YXRpb24udjFhbHBoYTEuU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVzcG9uc2UiACgBMAEa
U8pBH21lZGlhdHJhbnNsYXRpb24uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQocBCipjb20uZ29vZ2xlLmNsb3VkLm1l
ZGlhdHJhbnNsYXRpb24udjFhbHBoYTFaVmNsb3VkLmdvb2dsZS5jb20vZ28vbWVkaWF0cmFu
c2xhdGlvbi9hcGl2MWFscGhhMS9tZWRpYXRyYW5zbGF0aW9ucGI7bWVkaWF0cmFuc2xhdGlv
bnBi+AEBSv5gCgcSBQ4AkgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAvCgkKAgMAEgMSACkKCQoCAwESAxMAIQoJCgIDAhIDFAAhCggKAQgSAxYAHwoJ
CgIIHxIDFgAfCggKAQgSAxcAbQoJCgIICxIDFwBtCggKAQgSAxgAQwoJCgIIARIDGABDCjcK
AgYAEgQbACMBGisgUHJvdmlkZXMgdHJhbnNsYXRpb24gZnJvbS90byBtZWRpYSB0eXBlcy4K
CgoKAwYAARIDGwggCgoKAwYAAxIDHAJHCgwKBQYAA5kIEgMcAkcKCgoDBgADEgMdAlYKDAoF
BgADmggSAx0CVgqmAQoEBgACABIEIQIiAxqXASBQZXJmb3JtcyBiaWRpcmVjdGlvbmFsIHN0
cmVhbWluZyBzcGVlY2ggdHJhbnNsYXRpb246IHJlY2VpdmUgcmVzdWx0cyB3aGlsZQogc2Vu
ZGluZyBhdWRpby4gVGhpcyBtZXRob2QgaXMgb25seSBhdmFpbGFibGUgdmlhIHRoZSBnUlBD
IEFQSSAobm90IFJFU1QpLgoKDAoFBgACAAESAyEGHgoMCgUGAAIABRIDIR8lCgwKBQYAAgAC
EgMhJkUKDAoFBgACAAYSAyFQVgoMCgUGAAIAAxIDIVd3CmgKAgQAEgQnAG4BGlwgUHJvdmlk
ZXMgaW5mb3JtYXRpb24gdG8gdGhlIHNwZWVjaCB0cmFuc2xhdGlvbiB0aGF0IHNwZWNpZmll
cyBob3cgdG8gcHJvY2VzcwogdGhlIHJlcXVlc3QuCgoKCgMEAAESAycIHQrsBwoEBAACABID
TgJFGt4HIFJlcXVpcmVkLiBFbmNvZGluZyBvZiBhdWRpbyBkYXRhLgogU3VwcG9ydGVkIGZv
cm1hdHM6CgogLSBgbGluZWFyMTZgCgogICBVbmNvbXByZXNzZWQgMTYtYml0IHNpZ25lZCBs
aXR0bGUtZW5kaWFuIHNhbXBsZXMgKExpbmVhciBQQ00pLgoKIC0gYGZsYWNgCgogICBgZmxh
Y2AgKEZyZWUgTG9zc2xlc3MgQXVkaW8gQ29kZWMpIGlzIHRoZSByZWNvbW1lbmRlZCBlbmNv
ZGluZwogICBiZWNhdXNlIGl0IGlzIGxvc3NsZXNzLS10aGVyZWZvcmUgcmVjb2duaXRpb24g
aXMgbm90IGNvbXByb21pc2VkLS1hbmQKICAgcmVxdWlyZXMgb25seSBhYm91dCBoYWxmIHRo
ZSBiYW5kd2lkdGggb2YgYGxpbmVhcjE2YC4KCiAtIGBtdWxhd2AKCiAgIDgtYml0IHNhbXBs
ZXMgdGhhdCBjb21wYW5kIDE0LWJpdCBhdWRpbyBzYW1wbGVzIHVzaW5nIEcuNzExIFBDTVUv
bXUtbGF3LgoKIC0gYGFtcmAKCiAgIEFkYXB0aXZlIE11bHRpLVJhdGUgTmFycm93YmFuZCBj
b2RlYy4gYHNhbXBsZV9yYXRlX2hlcnR6YCBtdXN0IGJlIDgwMDAuCgogLSBgYW1yLXdiYAoK
ICAgQWRhcHRpdmUgTXVsdGktUmF0ZSBXaWRlYmFuZCBjb2RlYy4gYHNhbXBsZV9yYXRlX2hl
cnR6YCBtdXN0IGJlIDE2MDAwLgoKIC0gYG9nZy1vcHVzYAoKICAgT3B1cyBlbmNvZGVkIGF1
ZGlvIGZyYW1lcyBpbiBPZ2cgY29udGFpbmVyCiAgIChbT2dnT3B1c10oaHR0cHM6Ly93aWtp
LnhpcGgub3JnL09nZ09wdXMpKS4KICAgYHNhbXBsZV9yYXRlX2hlcnR6YCBtdXN0IGJlIG9u
ZSBvZiA4MDAwLCAxMjAwMCwgMTYwMDAsIDI0MDAwLCBvciA0ODAwMC4KCiAtIGBtcDNgCgog
ICBNUDMgYXVkaW8uIFN1cHBvcnQgYWxsIHN0YW5kYXJkIE1QMyBiaXRyYXRlcyAod2hpY2gg
cmFuZ2UgZnJvbSAzMi0zMjAKICAga2JwcykuIFdoZW4gdXNpbmcgdGhpcyBlbmNvZGluZywg
YHNhbXBsZV9yYXRlX2hlcnR6YCBoYXMgdG8gbWF0Y2ggdGhlCiAgIHNhbXBsZSByYXRlIG9m
IHRoZSBmaWxlIGJlaW5nIHVzZWQuCgoKCgwKBQQAAgAFEgNOAggKDAoFBAACAAESA04JFwoM
CgUEAAIAAxIDThobCgwKBQQAAgAIEgNOHEQKDwoIBAACAAicCAASA04dQwpKCgQEAAIBEgNR
AksaPSBSZXF1aXJlZC4gU291cmNlIGxhbmd1YWdlIGNvZGUgKEJDUC00Nykgb2YgdGhlIGlu
cHV0IGF1ZGlvLgoKDAoFBAACAQUSA1ECCAoMCgUEAAIBARIDUQkdCgwKBQQAAgEDEgNRICEK
DAoFBAACAQgSA1EiSgoPCggEAAIBCJwIABIDUSNJCkUKBAQAAgISA1QCSxo4IFJlcXVpcmVk
LiBUYXJnZXQgbGFuZ3VhZ2UgY29kZSAoQkNQLTQ3KSBvZiB0aGUgb3V0cHV0LgoKDAoFBAAC
AgUSA1QCCAoMCgUEAAICARIDVAkdCgwKBQQAAgIDEgNUICEKDAoFBAACAggSA1QiSgoPCggE
AAICCJwIABIDVCNJCpcGCgQEAAIDEgNjAmEaiQYgT3B0aW9uYWwuIEEgbGlzdCBvZiB1cCB0
byAzIGFkZGl0aW9uYWwgbGFuZ3VhZ2UgY29kZXMgKEJDUC00NyksIGxpc3RpbmcgcG9zc2li
bGUKIGFsdGVybmF0aXZlIGxhbmd1YWdlcyBvZiB0aGUgc3VwcGxpZWQgYXVkaW8uIElmIGFs
dGVybmF0aXZlIHNvdXJjZQogbGFuZ3VhZ2VzIGFyZSBsaXN0ZWQsIHNwZWVjaCB0cmFuc2xh
dGlvbiByZXN1bHQgd2lsbCB0cmFuc2xhdGUgaW4gdGhlIG1vc3QKIGxpa2VseSBsYW5ndWFn
ZSBkZXRlY3RlZCBpbmNsdWRpbmcgdGhlIG1haW4gc291cmNlX2xhbmd1YWdlX2NvZGUuIFRo
ZQogdHJhbnNsYXRlZCByZXN1bHQgd2lsbCBpbmNsdWRlIHRoZSBsYW5ndWFnZSBjb2RlIG9m
IHRoZSBsYW5ndWFnZSBkZXRlY3RlZAogaW4gdGhlIGF1ZGlvLgogTm90ZToKIDEuIElmIHRo
ZSBwcm92aWRlZCBhbHRlcm5hdGl2ZV9zb3VyY2VfbGFuZ3VhZ2VfY29kZSBpcyBub3Qgc3Vw
cG9ydGVkCiBieSBjdXJyZW50IEFQSSB2ZXJzaW9uLCB3ZSB3aWxsIHNraXAgdGhhdCBsYW5n
dWFnZSBjb2RlLgogMi4gSWYgdXNlciBvbmx5IHByb3ZpZGVkIG9uZSBlbGlnaWJsZSBhbHRl
cm5hdGl2ZV9zb3VyY2VfbGFuZ3VhZ2VfY29kZXMsCiB0aGUgdHJhbnNsYXRpb24gd2lsbCBo
YXBwZW4gYmV0d2VlbiBzb3VyY2VfbGFuZ3VhZ2VfY29kZSBhbmQKIGFsdGVybmF0aXZlX3Nv
dXJjZV9sYW5ndWFnZV9jb2Rlcy4gVGhlIHRhcmdldF9sYW5ndWFnZV9jb2RlIHdpbGwgYmUK
IGlnbm9yZWQuIEl0IHdpbGwgYmUgdXNlZnVsIGluIGNvbnZlcnNhdGlvbiBtb2RlLgoKDAoF
BAACAwQSA2MCCgoMCgUEAAIDBRIDYwsRCgwKBQQAAgMBEgNjEjMKDAoFBAACAwMSA2M2NwoM
CgUEAAIDCBIDYzhgCg8KCAQAAgMInAgAEgNjOV8KnwIKBAQAAgQSA2oCRxqRAiBPcHRpb25h
bC4gU2FtcGxlIHJhdGUgaW4gSGVydHogb2YgdGhlIGF1ZGlvIGRhdGEuIFZhbGlkIHZhbHVl
cyBhcmU6CiA4MDAwLTQ4MDAwLiAxNjAwMCBpcyBvcHRpbWFsLiBGb3IgYmVzdCByZXN1bHRz
LCBzZXQgdGhlIHNhbXBsaW5nIHJhdGUgb2YKIHRoZSBhdWRpbyBzb3VyY2UgdG8gMTYwMDAg
SHouIElmIHRoYXQncyBub3QgcG9zc2libGUsIHVzZSB0aGUgbmF0aXZlIHNhbXBsZQogcmF0
ZSBvZiB0aGUgYXVkaW8gc291cmNlIChpbnN0ZWFkIG9mIHJlLXNhbXBsaW5nKS4KCgoMCgUE
AAIEBRIDagIHCgwKBQQAAgQBEgNqCBkKDAoFBAACBAMSA2ocHQoMCgUEAAIECBIDah5GCg8K
CAQAAgQInAgAEgNqH0UKGAoEBAACBRIDbQI8GgsgT3B0aW9uYWwuCgoMCgUEAAIFBRIDbQII
CgwKBQQAAgUBEgNtCQ4KDAoFBAACBQMSA20REgoMCgUEAAIFCBIDbRM7Cg8KCAQAAgUInAgA
EgNtFDoKNQoCBAESBXEArgEBGiggQ29uZmlnIHVzZWQgZm9yIHN0cmVhbWluZyB0cmFuc2xh
dGlvbi4KCgoKAwQBARIDcQgmClAKBAQBAgASA3MCUhpDIFJlcXVpcmVkLiBUaGUgY29tbW9u
IGNvbmZpZyBmb3IgYWxsIHRoZSBmb2xsb3dpbmcgYXVkaW8gY29udGVudHMuCgoMCgUEAQIA
BhIDcwIXCgwKBQQBAgABEgNzGCQKDAoFBAECAAMSA3MnKAoMCgUEAQIACBIDcylRCg8KCAQB
AgAInAgAEgNzKlAKvAcKBAQBAgESBIMBAkUarQcgT3B0aW9uYWwuIElmIGBmYWxzZWAgb3Ig
b21pdHRlZCwgdGhlIHN5c3RlbSBwZXJmb3JtcwogY29udGludW91cyB0cmFuc2xhdGlvbiAo
Y29udGludWluZyB0byB3YWl0IGZvciBhbmQgcHJvY2VzcyBhdWRpbyBldmVuIGlmCiB0aGUg
dXNlciBwYXVzZXMgc3BlYWtpbmcpIHVudGlsIHRoZSBjbGllbnQgY2xvc2VzIHRoZSBpbnB1
dCBzdHJlYW0gKGdSUEMKIEFQSSkgb3IgdW50aWwgdGhlIG1heGltdW0gdGltZSBsaW1pdCBo
YXMgYmVlbiByZWFjaGVkLiBNYXkgcmV0dXJuIG11bHRpcGxlCiBgU3RyZWFtaW5nVHJhbnNs
YXRlU3BlZWNoUmVzdWx0YHMgd2l0aCB0aGUgYGlzX2ZpbmFsYCBmbGFnIHNldCB0byBgdHJ1
ZWAuCgogSWYgYHRydWVgLCB0aGUgc3BlZWNoIHRyYW5zbGF0b3Igd2lsbCBkZXRlY3QgYSBz
aW5nbGUgc3Bva2VuIHV0dGVyYW5jZS4KIFdoZW4gaXQgZGV0ZWN0cyB0aGF0IHRoZSB1c2Vy
IGhhcyBwYXVzZWQgb3Igc3RvcHBlZCBzcGVha2luZywgaXQgd2lsbAogcmV0dXJuIGFuIGBF
TkRfT0ZfU0lOR0xFX1VUVEVSQU5DRWAgZXZlbnQgYW5kIGNlYXNlIHRyYW5zbGF0aW9uLgog
V2hlbiB0aGUgY2xpZW50IHJlY2VpdmVzIGBFTkRfT0ZfU0lOR0xFX1VUVEVSQU5DRWAgZXZl
bnQsIHRoZSBjbGllbnQgc2hvdWxkCiBzdG9wIHNlbmRpbmcgdGhlIHJlcXVlc3RzLiBIb3dl
dmVyLCBjbGllbnRzIHNob3VsZCBrZWVwIHJlY2VpdmluZyByZW1haW5pbmcKIHJlc3BvbnNl
cyB1bnRpbCB0aGUgc3RyZWFtIGlzIHRlcm1pbmF0ZWQuIFRvIGNvbnN0cnVjdCB0aGUgY29t
cGxldGUKIHNlbnRlbmNlIGluIGEgc3RyZWFtaW5nIHdheSwgb25lIHNob3VsZCBvdmVycmlk
ZSAoaWYgYGlzX2ZpbmFsYCBvZiBwcmV2aW91cwogcmVzcG9uc2UgaXMgZmFsc2UpLCBvciBh
cHBlbmQgKGlmICdpc19maW5hbCcgb2YgcHJldmlvdXMgcmVzcG9uc2UgaXMgdHJ1ZSkuCgoN
CgUEAQIBBRIEgwECBgoNCgUEAQIBARIEgwEHFwoNCgUEAQIBAxIEgwEaGwoNCgUEAQIBCBIE
gwEcRAoQCggEAQIBCJwIABIEgwEdQwr7CAoEBAECAhIEmAECQBrsCCBPcHRpb25hbC4gU3Rh
YmlsaXR5IGNvbnRyb2wgZm9yIHRoZSBtZWRpYSB0cmFuc2xhdGlvbiB0ZXh0LiBUaGUgdmFs
dWUgc2hvdWxkIGJlCiAiTE9XIiwgIk1FRElVTSIsICJISUdIIi4gSXQgYXBwbGllcyB0byB0
ZXh0L3RleHRfYW5kX2F1ZGlvIHRyYW5zbGF0aW9uCiBvbmx5LgogRm9yIGF1ZGlvIHRyYW5z
bGF0aW9uIG1vZGUsIHdlIG9ubHkgc3VwcG9ydCBISUdIIHN0YWJpbGl0eSBtb2RlLAogbG93
L21lZGl1bSBzdGFiaWxpdHkgbW9kZSB3aWxsIHRocm93IGFyZ3VtZW50IGVycm9yLgogRGVm
YXVsdCBlbXB0eSBzdHJpbmcgd2lsbCBiZSB0cmVhdGVkIGFzICJISUdIIiBpbiBhdWRpbyB0
cmFuc2xhdGlvbiBtb2RlOwogd2lsbCBiZSB0cmVhdGVkIGFzICJMT1ciIGluIG90aGVyIHRy
YW5zbGF0aW9uIG1vZGUuCiBOb3RlIHRoYXQgc3RhYmlsaXR5IGFuZCBzcGVlZCB3b3VsZCBi
ZSB0cmFkZSBvZmYuCiAxLiAiTE9XIjogSW4gbG93IG1vZGUsIHRyYW5zbGF0aW9uIHNlcnZp
Y2Ugd2lsbCBzdGFydCB0byBkbyB0cmFuc2xhdGlvbgogcmlnaHQgYWZ0ZXIgZ2V0dGluZyBy
ZWNvZ25pdGlvbiByZXNwb25zZS4gVGhlIHNwZWVkIHdpbGwgYmUgZmFzdGVyLgogMi4gIk1F
RElVTSI6IEluIG1lZGl1bSBtb2RlLCB0cmFuc2xhdGlvbiBzZXJ2aWNlIHdpbGwKIGNoZWNr
IGlmIHRoZSByZWNvZ25pdGlvbiByZXNwb25zZSBpcyBzdGFibGUgZW5vdWdoIG9yIG5vdCwg
YW5kIG9ubHkKIHRyYW5zbGF0ZSByZWNvZ25pdGlvbiByZXNwb25zZSB3aGljaCBpcyBub3Qg
bGlrZWx5IHRvIGJlIGNoYW5nZWQgbGF0ZXIuCiAzLiAiSElHSCI6IEluIGhpZ2ggbW9kZSwg
dHJhbnNsYXRpb24gc2VydmljZSB3aWxsIHdhaXQgZm9yIG1vcmUgc3RhYmxlCiByZWNvZ25p
dGlvbiByZXNwb25zZXMsIGFuZCB0aGVuIHN0YXJ0IHRvIGRvIHRyYW5zbGF0aW9uLiBBbHNv
LCB0aGUKIGZvbGxvd2luZyByZWNvZ25pdGlvbiByZXNwb25zZXMgY2Fubm90IG1vZGlmeSBw
cmV2aW91cyByZWNvZ25pdGlvbgogcmVzcG9uc2VzLiBUaHVzIGl0IG1heSBpbXBhY3QgcXVh
bGl0eSBpbiBzb21lIHNpdHVhdGlvbi4gIkhJR0giIHN0YWJpbGl0eQogd2lsbCBnZW5lcmF0
ZSAiZmluYWwiIHJlc3BvbnNlcyBtb3JlIGZyZXF1ZW50bHkuCgoKDQoFBAECAgUSBJgBAggK
DQoFBAECAgESBJgBCRIKDQoFBAECAgMSBJgBFRYKDQoFBAECAggSBJgBFz8KEAoIBAECAgic
CAASBJgBGD4KlwYKBAQBAgMSBKcBAkcaiAYgT3B0aW9uYWwuIFRyYW5zbGF0aW9uIG1vZGUs
IHRoZSB2YWx1ZSBzaG91bGQgYmUgInRleHQiLCAiYXVkaW8iLCAidGV4dF9hbmRfYXVkaW8i
LgogRGVmYXVsdCBlbXB0eSBzdHJpbmcgd2lsbCBiZSB0cmVhdGVkIGFzICJ0ZXh0Ii4KIDEu
ICJ0ZXh0IjogVGhlIHJlc3BvbnNlIHdpbGwgYmUgdGV4dCB0cmFuc2xhdGlvbi4gVGV4dCB0
cmFuc2xhdGlvbiBoYXMgYQogZmllbGQgImlzX2ZpbmFsIi4gRGV0YWlsZWQgZGVmaW5pdGlv
biBjYW4gYmUgZm91bmQgaW4KIGBUZXh0VHJhbnNsYXRpb25SZXN1bHRgLgogMi4gImF1ZGlv
IjogVGhlIHJlc3BvbnNlIHdpbGwgYmUgYXVkaW8gdHJhbnNsYXRpb24uIEF1ZGlvIHRyYW5z
bGF0aW9uIGRvZXMKIG5vdCBoYXZlICJpc19maW5hbCIgZmllbGQsIHdoaWNoIG1lYW5zIGVh
Y2ggYXVkaW8gdHJhbnNsYXRpb24gcmVzcG9uc2UgaXMKIHN0YWJsZSBhbmQgd2lsbCBub3Qg
YmUgY2hhbmdlZCBieSBsYXRlciByZXNwb25zZS4KIFRyYW5zbGF0aW9uIG1vZGUgImF1ZGlv
IiBjYW4gb25seSBiZSB1c2VkIHdpdGggImhpZ2giIHN0YWJpbGl0eSBtb2RlLAogMy4gInRl
eHRfYW5kX2F1ZGlvIjogVGhlIHJlc3BvbnNlIHdpbGwgaGF2ZSBhIHRleHQgdHJhbnNsYXRp
b24sIHdoZW4KICJpc19maW5hbCIgaXMgdHJ1ZSwgd2Ugd2lsbCBhbHNvIG91dHB1dCBpdHMg
Y29ycmVzcG9uZGluZyBhdWRpbwogdHJhbnNsYXRpb24uIFdoZW4gImlzX2ZpbmFsIiBpcyBm
YWxzZSwgYXVkaW9fdHJhbnNsYXRpb24gZmllbGQgd2lsbCBiZQogZW1wdHkuCgoNCgUEAQID
BRIEpwECCAoNCgUEAQIDARIEpwEJGQoNCgUEAQIDAxIEpwEcHQoNCgUEAQIDCBIEpwEeRgoQ
CggEAQIDCJwIABIEpwEfRQqDAgoEBAECBBIErQECTBr0ASBPcHRpb25hbC4gSWYgZGlzYWJs
ZV9pbnRlcmltX3Jlc3VsdHMgaXMgdHJ1ZSwgd2Ugd2lsbCBvbmx5IHJldHVybiAiZmluYWwi
IHJlc3BvbnNlcy4KIE90aGVyd2lzZSwgd2Ugd2lsbCByZXR1cm4gYWxsIHRoZSByZXNwb25z
ZXMuIERlZmF1bHQgdmFsdWUgd2lsbCBiZSBmYWxzZS4KIFVzZXIgY2FuIG9ubHkgc2V0IGRp
c2FibGVfaW50ZXJpbV9yZXN1bHRzIHRvIGJlIHRydWUgd2l0aCAiaGlnaCIgc3RhYmlsaXR5
CiBtb2RlLgoKDQoFBAECBAUSBK0BAgYKDQoFBAECBAESBK0BBx4KDQoFBAECBAMSBK0BISIK
DQoFBAECBAgSBK0BI0sKEAoIBAECBAicCAASBK0BJEoK+gIKAgQCEga1AQDHAQEa6wIgVGhl
IHRvcC1sZXZlbCBtZXNzYWdlIHNlbnQgYnkgdGhlIGNsaWVudCBmb3IgdGhlIGBTdHJlYW1p
bmdUcmFuc2xhdGVTcGVlY2hgCiBtZXRob2QuIE11bHRpcGxlIGBTdHJlYW1pbmdUcmFuc2xh
dGVTcGVlY2hSZXF1ZXN0YCBtZXNzYWdlcyBhcmUgc2VudC4gVGhlCiBmaXJzdCBtZXNzYWdl
IG11c3QgY29udGFpbiBhIGBzdHJlYW1pbmdfY29uZmlnYCBtZXNzYWdlIGFuZCBtdXN0IG5v
dCBjb250YWluCiBgYXVkaW9fY29udGVudGAgZGF0YS4gQWxsIHN1YnNlcXVlbnQgbWVzc2Fn
ZXMgbXVzdCBjb250YWluIGBhdWRpb19jb250ZW50YAogZGF0YSBhbmQgbXVzdCBub3QgY29u
dGFpbiBhIGBzdHJlYW1pbmdfY29uZmlnYCBtZXNzYWdlLgoKCwoDBAIBEgS1AQgnClcKBAQC
CAASBrcBAsYBAxpHIFRoZSBzdHJlYW1pbmcgcmVxdWVzdCwgd2hpY2ggaXMgZWl0aGVyIGEg
c3RyZWFtaW5nIGNvbmZpZyBvciBjb250ZW50LgoKDQoFBAIIAAESBLcBCBkKwwEKBAQCAgAS
BLsBBDgatAEgUHJvdmlkZXMgaW5mb3JtYXRpb24gdG8gdGhlIHJlY29nbml6ZXIgdGhhdCBz
cGVjaWZpZXMgaG93IHRvIHByb2Nlc3MgdGhlCiByZXF1ZXN0LiBUaGUgZmlyc3QgYFN0cmVh
bWluZ1RyYW5zbGF0ZVNwZWVjaFJlcXVlc3RgIG1lc3NhZ2UgbXVzdCBjb250YWluCiBhIGBz
dHJlYW1pbmdfY29uZmlnYCBtZXNzYWdlLgoKDQoFBAICAAYSBLsBBCIKDQoFBAICAAESBLsB
IzMKDQoFBAICAAMSBLsBNjcKhAQKBAQCAgESBMUBBBwa9QMgVGhlIGF1ZGlvIGRhdGEgdG8g
YmUgdHJhbnNsYXRlZC4gU2VxdWVudGlhbCBjaHVua3Mgb2YgYXVkaW8gZGF0YSBhcmUgc2Vu
dAogaW4gc2VxdWVudGlhbCBgU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVxdWVzdGAgbWVz
c2FnZXMuIFRoZSBmaXJzdAogYFN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlcXVlc3RgIG1l
c3NhZ2UgbXVzdCBub3QgY29udGFpbgogYGF1ZGlvX2NvbnRlbnRgIGRhdGEgYW5kIGFsbCBz
dWJzZXF1ZW50IGBTdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hSZXF1ZXN0YAogbWVzc2FnZXMg
bXVzdCBjb250YWluIGBhdWRpb19jb250ZW50YCBkYXRhLiBUaGUgYXVkaW8gYnl0ZXMgbXVz
dCBiZQogZW5jb2RlZCBhcyBzcGVjaWZpZWQgaW4gYFN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVj
aENvbmZpZ2AuIE5vdGU6IGFzIHdpdGgKIGFsbCBieXRlcyBmaWVsZHMsIHByb3RvYnVmZmVy
cyB1c2UgYSBwdXJlIGJpbmFyeSByZXByZXNlbnRhdGlvbiAobm90CiBiYXNlNjQpLgoKDQoF
BAICAQUSBMUBBAkKDQoFBAICAQESBMUBChcKDQoFBAICAQMSBMUBGhsKgQEKAgQDEgbLAQDt
AQEacyBBIHN0cmVhbWluZyBzcGVlY2ggdHJhbnNsYXRpb24gcmVzdWx0IGNvcnJlc3BvbmRp
bmcgdG8gYSBwb3J0aW9uIG9mIHRoZSBhdWRpbwogdGhhdCBpcyBjdXJyZW50bHkgYmVpbmcg
cHJvY2Vzc2VkLgoKCwoDBAMBEgTLAQgmCioKBAQDAwASBs0BAtgBAxoaIFRleHQgdHJhbnNs
YXRpb24gcmVzdWx0LgoKDQoFBAMDAAESBM0BCh8KNwoGBAMDAAIAEgTPAQRHGicgT3V0cHV0
IG9ubHkuIFRoZSB0cmFuc2xhdGVkIHNlbnRlbmNlLgoKDwoHBAMDAAIABRIEzwEECgoPCgcE
AwMAAgABEgTPAQsWCg8KBwQDAwACAAMSBM8BGRoKDwoHBAMDAAIACBIEzwEbRgoSCgoEAwMA
AgAInAgAEgTPARxFCvgCCgYEAwMAAgESBNcBBEIa5wIgT3V0cHV0IG9ubHkuIElmIGBmYWxz
ZWAsIHRoaXMgYFN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlc3VsdGAgcmVwcmVzZW50cwog
YW4gaW50ZXJpbSByZXN1bHQgdGhhdCBtYXkgY2hhbmdlLiBJZiBgdHJ1ZWAsIHRoaXMgaXMg
dGhlIGZpbmFsIHRpbWUgdGhlCiB0cmFuc2xhdGlvbiBzZXJ2aWNlIHdpbGwgcmV0dXJuIHRo
aXMgcGFydGljdWxhcgogYFN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlc3VsdGAsIHRoZSBz
dHJlYW1pbmcgdHJhbnNsYXRvciB3aWxsIG5vdAogcmV0dXJuIGFueSBmdXJ0aGVyIGh5cG90
aGVzZXMgZm9yIHRoaXMgcG9ydGlvbiBvZiB0aGUgdHJhbnNjcmlwdCBhbmQKIGNvcnJlc3Bv
bmRpbmcgYXVkaW8uCgoPCgcEAwMAAgEFEgTXAQQICg8KBwQDAwACAQESBNcBCREKDwoHBAMD
AAIBAxIE1wEUFQoPCgcEAwMAAgEIEgTXARZBChIKCgQDAwACAQicCAASBNcBF0AKKwoEBAMD
ARIG2wEC3gEDGhsgQXVkaW8gdHJhbnNsYXRpb24gcmVzdWx0LgoKDQoFBAMDAQESBNsBCiAK
NAoGBAMDAQIAEgTdAQRMGiQgT3V0cHV0IG9ubHkuIFRoZSB0cmFuc2xhdGVkIGF1ZGlvLgoK
DwoHBAMDAQIABRIE3QEECQoPCgcEAwMBAgABEgTdAQobCg8KBwQDAwECAAMSBN0BHh8KDwoH
BAMDAQIACBIE3QEgSwoSCgoEAwMBAgAInAgAEgTdASFKCigKBAQDAgASBOEBAjQaGiBUZXh0
IHRyYW5zbGF0aW9uIHJlc3VsdC4KCg0KBQQDAgAGEgThAQIXCg0KBQQDAgABEgThARgvCg0K
BQQDAgADEgThATIzCikKBAQDAgESBOQBAjYaGyBBdWRpbyB0cmFuc2xhdGlvbiByZXN1bHQu
CgoNCgUEAwIBBhIE5AECGAoNCgUEAwIBARIE5AEZMQoNCgUEAwIBAxIE5AE0NQrlAQoEBAMC
AhIE6QECTBrWASBPdXRwdXQgb25seS4gVGhlIGRlYnVnIG9ubHkgcmVjb2duaXRpb24gcmVz
dWx0IGluIG9yaWdpbmFsIGxhbmd1YWdlLiBUaGlzIGZpZWxkIGlzIGRlYnVnCiBvbmx5IGFu
ZCB3aWxsIGJlIHNldCB0byBlbXB0eSBzdHJpbmcgaWYgbm90IGF2YWlsYWJsZS4KIFRoaXMg
aXMgaW1wbGVtZW50YXRpb24gZGV0YWlsIGFuZCB3aWxsIG5vdCBiZSBiYWNrd2FyZCBjb21w
YXRpYmxlLgoKDQoFBAMCAgUSBOkBAggKDQoFBAMCAgESBOkBCRsKDQoFBAMCAgMSBOkBHh8K
DQoFBAMCAggSBOkBIEsKEAoIBAMCAgicCAASBOkBIUoKHAoEBAMCAxIE7AECVxoOIE91dHB1
dCBvbmx5LgoKDQoFBAMCAwUSBOwBAggKDQoFBAMCAwESBOwBCSYKDQoFBAMCAwMSBOwBKSoK
DQoFBAMCAwgSBOwBK1YKEAoIBAMCAwicCAASBOwBLFUKdQoCBAQSBvEBAJICARpnIEEgc3Ry
ZWFtaW5nIHNwZWVjaCB0cmFuc2xhdGlvbiByZXNwb25zZSBjb3JyZXNwb25kaW5nIHRvIGEg
cG9ydGlvbiBvZgogdGhlIGF1ZGlvIGN1cnJlbnRseSBwcm9jZXNzZWQuCgoLCgMEBAESBPEB
CCgKNQoEBAQEABIG8wECggIDGiUgSW5kaWNhdGVzIHRoZSB0eXBlIG9mIHNwZWVjaCBldmVu
dC4KCg0KBQQEBAABEgTzAQcWCiwKBgQEBAACABIE9QEEJhocIE5vIHNwZWVjaCBldmVudCBz
cGVjaWZpZWQuCgoPCgcEBAQAAgABEgT1AQQhCg8KBwQEBAACAAISBPUBJCUK3AUKBgQEBAAC
ARIEgQIEIBrLBSBUaGlzIGV2ZW50IGluZGljYXRlcyB0aGF0IHRoZSBzZXJ2ZXIgaGFzIGRl
dGVjdGVkIHRoZSBlbmQgb2YgdGhlIHVzZXIncwogc3BlZWNoIHV0dGVyYW5jZSBhbmQgZXhw
ZWN0cyBubyBhZGRpdGlvbmFsIHNwZWVjaC4gVGhlcmVmb3JlLCB0aGUgc2VydmVyCiB3aWxs
IG5vdCBwcm9jZXNzIGFkZGl0aW9uYWwgYXVkaW8gKGFsdGhvdWdoIGl0IG1heSBzdWJzZXF1
ZW50bHkgcmV0dXJuCiBhZGRpdGlvbmFsIHJlc3VsdHMpLiBXaGVuIHRoZSBjbGllbnQgcmVj
ZWl2ZXMgYEVORF9PRl9TSU5HTEVfVVRURVJBTkNFYAogZXZlbnQsIHRoZSBjbGllbnQgc2hv
dWxkIHN0b3Agc2VuZGluZyB0aGUgcmVxdWVzdHMuIEhvd2V2ZXIsIGNsaWVudHMKIHNob3Vs
ZCBrZWVwIHJlY2VpdmluZyByZW1haW5pbmcgcmVzcG9uc2VzIHVudGlsIHRoZSBzdHJlYW0g
aXMgdGVybWluYXRlZC4KIFRvIGNvbnN0cnVjdCB0aGUgY29tcGxldGUgc2VudGVuY2UgaW4g
YSBzdHJlYW1pbmcgd2F5LCBvbmUgc2hvdWxkCiBvdmVycmlkZSAoaWYgYGlzX2ZpbmFsYCBv
ZiBwcmV2aW91cyByZXNwb25zZSBpcyBgZmFsc2VgKSwgb3IgYXBwZW5kIChpZgogYGlzX2Zp
bmFsYCBvZiBwcmV2aW91cyByZXNwb25zZSBpcyBgdHJ1ZWApLiBUaGlzIGV2ZW50IGlzIG9u
bHkgc2VudCBpZgogYHNpbmdsZV91dHRlcmFuY2VgIHdhcyBzZXQgdG8gYHRydWVgLCBhbmQg
aXMgbm90IHVzZWQgb3RoZXJ3aXNlLgoKDwoHBAQEAAIBARIEgQIEGwoPCgcEBAQAAgECEgSB
Ah4fCooBCgQEBAIAEgSGAgJKGnwgT3V0cHV0IG9ubHkuIElmIHNldCwgcmV0dXJucyBhIFtn
b29nbGUucnBjLlN0YXR1c11bZ29vZ2xlLnJwYy5TdGF0dXNdIG1lc3NhZ2UgdGhhdAogc3Bl
Y2lmaWVzIHRoZSBlcnJvciBmb3IgdGhlIG9wZXJhdGlvbi4KCg0KBQQEAgAGEgSGAgITCg0K
BQQEAgABEgSGAhQZCg0KBQQEAgADEgSGAhwdCg0KBQQEAgAIEgSGAh5JChAKCAQEAgAInAgA
EgSGAh9ICqQDCgQEBAIBEgSOAgJYGpUDIE91dHB1dCBvbmx5LiBUaGUgdHJhbnNsYXRpb24g
cmVzdWx0IHRoYXQgaXMgY3VycmVudGx5IGJlaW5nIHByb2Nlc3NlZCAoRm9yIHRleHQKIHRy
YW5zbGF0aW9uLCBgaXNfZmluYWxgIGNvdWxkIGJlIGB0cnVlYCBvciBgZmFsc2VgLgogRm9y
IGF1ZGlvIHRyYW5zbGF0aW9uLCB3ZSBkbyBub3QgaGF2ZSBpc19maW5hbCBmaWVsZCwgd2hp
Y2ggbWVhbnMgZWFjaAogYXVkaW8gcmVzcG9uc2UgaXMgc3RhYmxlIGFuZCB3aWxsIG5vdCBn
ZXQgY2hhbmdlZCBsYXRlci4gRm9yCiB0ZXh0X2FuZF9hdWRpbywgd2Ugc3RpbGwgaGF2ZSBg
aXNfZmluYWxgIGZpZWxkIGluIHRleHQgdHJhbnNsYXRpb24sIGJ1dCB3ZQogb25seSBvdXRw
dXQgY29ycmVzcG9uc2RpbmcgYXVkaW8gd2hlbiBgaXNfZmluYWxgIGlzIHRydWUuKS4KCg0K
BQQEAgEGEgSOAgIgCg0KBQQEAgEBEgSOAiEnCg0KBQQEAgEDEgSOAiorCg0KBQQEAgEIEgSO
AixXChAKCAQEAgEInAgAEgSOAi1WCkAKBAQEAgISBJECAlQaMiBPdXRwdXQgb25seS4gSW5k
aWNhdGVzIHRoZSB0eXBlIG9mIHNwZWVjaCBldmVudC4KCg0KBQQEAgIGEgSRAgIRCg0KBQQE
AgIBEgSRAhIjCg0KBQQEAgIDEgSRAiYnCg0KBQQEAgIIEgSRAihTChAKCAQEAgIInAgAEgSR
AilSYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::TranslateSpeechConfig ===
    # Fields for TranslateSpeechConfig
    # Field: audio_encoding Type: 9 ()
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()
    # Field: alternative_source_language_codes Type: 9 ()
    # Field: sample_rate_hertz Type: 5 ()
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechConfig ===
    # Fields for StreamingTranslateSpeechConfig
    # Field: audio_config Type: 11 (.google.cloud.mediatranslation.v1alpha1.TranslateSpeechConfig)
    # Field: single_utterance Type: 8 ()
    # Field: stability Type: 9 ()
    # Field: translation_mode Type: 9 ()
    # Field: disable_interim_results Type: 8 ()

# === Message: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechRequest ===
    # Fields for StreamingTranslateSpeechRequest
    # Field: streaming_config Type: 11 (.google.cloud.mediatranslation.v1alpha1.StreamingTranslateSpeechConfig)
    # Field: audio_content Type: 12 ()

# === Message: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResult ===
    # Fields for StreamingTranslateSpeechResult
    # Field: text_translation_result Type: 11 (.google.cloud.mediatranslation.v1alpha1.StreamingTranslateSpeechResult.TextTranslationResult)
    # Field: audio_translation_result Type: 11 (.google.cloud.mediatranslation.v1alpha1.StreamingTranslateSpeechResult.AudioTranslationResult)
    # Field: recognition_result Type: 9 ()
    # Field: detected_source_language_code Type: 9 ()

# === Message: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResponse ===
    # Fields for StreamingTranslateSpeechResponse
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: result Type: 11 (.google.cloud.mediatranslation.v1alpha1.StreamingTranslateSpeechResult)
    # Field: speech_event_type Type: 14 (.google.cloud.mediatranslation.v1alpha1.StreamingTranslateSpeechResponse.SpeechEventType)

# Enum: StreamingTranslateSpeechResponse::SpeechEventType
our $StreamingTranslateSpeechResponse_SPEECH_EVENT_TYPE_UNSPECIFIED = 0;
our $StreamingTranslateSpeechResponse_END_OF_SINGLE_UTTERANCE = 1;

# === Service Client: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::SpeechTranslationServiceClient ===
package Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::SpeechTranslationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::SpeechTranslationServiceClient

Client stub representing the remote C<SpeechTranslationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<mediatranslation.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'mediatranslation.googleapis.com:443' );

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

sub streaming_translate_speech {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.mediatranslation.v1alpha1.SpeechTranslationService',
        method         => 'StreamingTranslateSpeech',
        request        => $req,
        response_class => 'Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation - Compiled Protocol Buffers messages for google/cloud/mediatranslation/v1alpha1/media_translation.proto

=head1 SYNOPSIS

    use Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation;

    my $msg = Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::TranslateSpeechConfig->new({
        audio_encoding => $audio_encoding,
        source_language_code => $source_language_code,
        target_language_code => $target_language_code,
        alternative_source_language_codes => $alternative_source_language_codes,
    });

    # Read or update a field
    my $val = $msg->audio_encoding();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::TranslateSpeechConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/mediatranslation/v1alpha1/media_translation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::TranslateSpeechConfig

Provides information to the speech translation that specifies how to process
the request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_encoding() >> / C<< $msg->audio_encoding($value) >>

Type: C<String>

Required. Encoding of audio data.
Supported formats:

- `linear16`

  Uncompressed 16-bit signed little-endian samples (Linear PCM).

- `flac`

  `flac` (Free Lossless Audio Codec) is the recommended encoding
  because it is lossless--therefore recognition is not compromised--and
  requires only about half the bandwidth of `linear16`.

- `mulaw`

  8-bit samples that compand 14-bit audio samples using G.711 PCMU/mu-law.

- `amr`

  Adaptive Multi-Rate Narrowband codec. `sample_rate_hertz` must be 8000.

- `amr-wb`

  Adaptive Multi-Rate Wideband codec. `sample_rate_hertz` must be 16000.

- `ogg-opus`

  Opus encoded audio frames in Ogg container
  ([OggOpus](https://wiki.xiph.org/OggOpus)).
  `sample_rate_hertz` must be one of 8000, 12000, 16000, 24000, or 48000.

- `mp3`

  MP3 audio. Support all standard MP3 bitrates (which range from 32-320
  kbps). When using this encoding, `sample_rate_hertz` has to match the
  sample rate of the file being used.



=item * C<< $msg->source_language_code() >> / C<< $msg->source_language_code($value) >>

Type: C<String>

Required. Source language code (BCP-47) of the input audio.

=item * C<< $msg->target_language_code() >> / C<< $msg->target_language_code($value) >>

Type: C<String>

Required. Target language code (BCP-47) of the output.

=item * C<< $msg->alternative_source_language_codes() >> / C<< $msg->alternative_source_language_codes($value) >>

Type: C<String>

Optional. A list of up to 3 additional language codes (BCP-47), listing possible
alternative languages of the supplied audio. If alternative source
languages are listed, speech translation result will translate in the most
likely language detected including the main source_language_code. The
translated result will include the language code of the language detected
in the audio.
Note:
1. If the provided alternative_source_language_code is not supported
by current API version, we will skip that language code.
2. If user only provided one eligible alternative_source_language_codes,
the translation will happen between source_language_code and
alternative_source_language_codes. The target_language_code will be
ignored. It will be useful in conversation mode.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. Sample rate in Hertz of the audio data. Valid values are:
8000-48000. 16000 is optimal. For best results, set the sampling rate of
the audio source to 16000 Hz. If that's not possible, use the native sample
rate of the audio source (instead of re-sampling).


=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Optional.

=back

=head2 Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechConfig

Config used for streaming translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_config() >> / C<< $msg->audio_config($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::TranslateSpeechConfig>)

Required. The common config for all the following audio contents.

=item * C<< $msg->single_utterance() >> / C<< $msg->single_utterance($value) >>

Type: C<Bool>

Optional. If `false` or omitted, the system performs
continuous translation (continuing to wait for and process audio even if
the user pauses speaking) until the client closes the input stream (gRPC
API) or until the maximum time limit has been reached. May return multiple
`StreamingTranslateSpeechResult`s with the `is_final` flag set to `true`.

If `true`, the speech translator will detect a single spoken utterance.
When it detects that the user has paused or stopped speaking, it will
return an `END_OF_SINGLE_UTTERANCE` event and cease translation.
When the client receives `END_OF_SINGLE_UTTERANCE` event, the client should
stop sending the requests. However, clients should keep receiving remaining
responses until the stream is terminated. To construct the complete
sentence in a streaming way, one should override (if `is_final` of previous
response is false), or append (if 'is_final' of previous response is true).

=item * C<< $msg->stability() >> / C<< $msg->stability($value) >>

Type: C<String>

Optional. Stability control for the media translation text. The value should be
"LOW", "MEDIUM", "HIGH". It applies to text/text_and_audio translation
only.
For audio translation mode, we only support HIGH stability mode,
low/medium stability mode will throw argument error.
Default empty string will be treated as "HIGH" in audio translation mode;
will be treated as "LOW" in other translation mode.
Note that stability and speed would be trade off.
1. "LOW": In low mode, translation service will start to do translation
right after getting recognition response. The speed will be faster.
2. "MEDIUM": In medium mode, translation service will
check if the recognition response is stable enough or not, and only
translate recognition response which is not likely to be changed later.
3. "HIGH": In high mode, translation service will wait for more stable
recognition responses, and then start to do translation. Also, the
following recognition responses cannot modify previous recognition
responses. Thus it may impact quality in some situation. "HIGH" stability
will generate "final" responses more frequently.


=item * C<< $msg->translation_mode() >> / C<< $msg->translation_mode($value) >>

Type: C<String>

Optional. Translation mode, the value should be "text", "audio", "text_and_audio".
Default empty string will be treated as "text".
1. "text": The response will be text translation. Text translation has a
field "is_final". Detailed definition can be found in
`TextTranslationResult`.
2. "audio": The response will be audio translation. Audio translation does
not have "is_final" field, which means each audio translation response is
stable and will not be changed by later response.
Translation mode "audio" can only be used with "high" stability mode,
3. "text_and_audio": The response will have a text translation, when
"is_final" is true, we will also output its corresponding audio
translation. When "is_final" is false, audio_translation field will be
empty.

=item * C<< $msg->disable_interim_results() >> / C<< $msg->disable_interim_results($value) >>

Type: C<Bool>

Optional. If disable_interim_results is true, we will only return "final" responses.
Otherwise, we will return all the responses. Default value will be false.
User can only set disable_interim_results to be true with "high" stability
mode.

=back

=head2 Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechRequest

The top-level message sent by the client for the `StreamingTranslateSpeech`
method. Multiple `StreamingTranslateSpeechRequest` messages are sent. The
first message must contain a `streaming_config` message and must not contain
`audio_content` data. All subsequent messages must contain `audio_content`
data and must not contain a `streaming_config` message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streaming_config() >> / C<< $msg->streaming_config($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechConfig>)

Provides information to the recognizer that specifies how to process the
request. The first `StreamingTranslateSpeechRequest` message must contain
a `streaming_config` message.

=item * C<< $msg->audio_content() >> / C<< $msg->audio_content($value) >>

Type: C<Bytes>

The audio data to be translated. Sequential chunks of audio data are sent
in sequential `StreamingTranslateSpeechRequest` messages. The first
`StreamingTranslateSpeechRequest` message must not contain
`audio_content` data and all subsequent `StreamingTranslateSpeechRequest`
messages must contain `audio_content` data. The audio bytes must be
encoded as specified in `StreamingTranslateSpeechConfig`. Note: as with
all bytes fields, protobuffers use a pure binary representation (not
base64).

=back

=head2 Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResult

A streaming speech translation result corresponding to a portion of the audio
that is currently being processed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_translation_result() >> / C<< $msg->text_translation_result($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResult::TextTranslationResult>)

Text translation result.

=item * C<< $msg->audio_translation_result() >> / C<< $msg->audio_translation_result($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResult::AudioTranslationResult>)

Audio translation result.

=item * C<< $msg->recognition_result() >> / C<< $msg->recognition_result($value) >>

Type: C<String>

Output only. The debug only recognition result in original language. This field is debug
only and will be set to empty string if not available.
This is implementation detail and will not be backward compatible.

=item * C<< $msg->detected_source_language_code() >> / C<< $msg->detected_source_language_code($value) >>

Type: C<String>

Output only.

=back

=head2 Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResponse

A streaming speech translation response corresponding to a portion of
the audio currently processed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. If set, returns a [google.rpc.Status][google.rpc.Status] message that
specifies the error for the operation.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::StreamingTranslateSpeechResult>)

Output only. The translation result that is currently being processed (For text
translation, `is_final` could be `true` or `false`.
For audio translation, we do not have is_final field, which means each
audio response is stable and will not get changed later. For
text_and_audio, we still have `is_final` field in text translation, but we
only output corresponsding audio when `is_final` is true.).

=item * C<< $msg->speech_event_type() >> / C<< $msg->speech_event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Mediatranslation::V1alpha1::StreamingTranslateSpeechResponse::SpeechEventType>)

Output only. Indicates the type of speech event.

=back

=head3 Enum: StreamingTranslateSpeechResponse::SpeechEventType

=over 4

=item * C<SPEECH_EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<END_OF_SINGLE_UTTERANCE> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Mediatranslation::V1alpha1::MediaTranslation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
