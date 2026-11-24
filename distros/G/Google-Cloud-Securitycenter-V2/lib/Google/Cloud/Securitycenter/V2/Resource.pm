package Google::Cloud::Securitycenter::V2::Resource;

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
    eval { require Google::Cloud::Securitycenter::V2::Folder };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvcmVzb3VyY2UucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxorZ29vZ2xlL2Nsb3VkL3NlY3VyaXR5
Y2VudGVyL3YyL2ZvbGRlci5wcm90byL9BAoIUmVzb3VyY2USEgoEbmFtZRgBIAEoCVIEbmFt
ZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEhIKBHR5cGUYAyABKAlSBHR5
cGUSVAoOY2xvdWRfcHJvdmlkZXIYBCABKA4yLS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50
ZXIudjIuQ2xvdWRQcm92aWRlclINY2xvdWRQcm92aWRlchIYCgdzZXJ2aWNlGAUgASgJUgdz
ZXJ2aWNlEhoKCGxvY2F0aW9uGAYgASgJUghsb2NhdGlvbhJQCgxnY3BfbWV0YWRhdGEYByAB
KAsyKy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuR2NwTWV0YWRhdGFIAFILZ2Nw
TWV0YWRhdGESUAoMYXdzX21ldGFkYXRhGAggASgLMisuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYyLkF3c01ldGFkYXRhSABSC2F3c01ldGFkYXRhElYKDmF6dXJlX21ldGFkYXRh
GAkgASgLMi0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLkF6dXJlTWV0YWRhdGFI
AFINYXp1cmVNZXRhZGF0YRJRCg1yZXNvdXJjZV9wYXRoGAogASgLMiwuZ29vZ2xlLmNsb3Vk
LnNlY3VyaXR5Y2VudGVyLnYyLlJlc291cmNlUGF0aFIMcmVzb3VyY2VQYXRoEjAKFHJlc291
cmNlX3BhdGhfc3RyaW5nGAsgASgJUhJyZXNvdXJjZVBhdGhTdHJpbmdCGQoXY2xvdWRfcHJv
dmlkZXJfbWV0YWRhdGEijAIKC0djcE1ldGFkYXRhEhgKB3Byb2plY3QYASABKAlSB3Byb2pl
Y3QSMAoUcHJvamVjdF9kaXNwbGF5X25hbWUYAiABKAlSEnByb2plY3REaXNwbGF5TmFtZRIW
CgZwYXJlbnQYAyABKAlSBnBhcmVudBIuChNwYXJlbnRfZGlzcGxheV9uYW1lGAQgASgJUhFw
YXJlbnREaXNwbGF5TmFtZRJFCgdmb2xkZXJzGAUgAygLMiYuZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYyLkZvbGRlckID4EEDUgdmb2xkZXJzEiIKDG9yZ2FuaXphdGlvbhgGIAEo
CVIMb3JnYW5pemF0aW9uIsgDCgtBd3NNZXRhZGF0YRJfCgxvcmdhbml6YXRpb24YASABKAsy
Oy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQXdzTWV0YWRhdGEuQXdzT3JnYW5p
emF0aW9uUgxvcmdhbml6YXRpb24SdAoUb3JnYW5pemF0aW9uYWxfdW5pdHMYAiADKAsyQS5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQXdzTWV0YWRhdGEuQXdzT3JnYW5pemF0
aW9uYWxVbml0UhNvcmdhbml6YXRpb25hbFVuaXRzElAKB2FjY291bnQYAyABKAsyNi5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQXdzTWV0YWRhdGEuQXdzQWNjb3VudFIHYWNj
b3VudBohCg9Bd3NPcmdhbml6YXRpb24SDgoCaWQYASABKAlSAmlkGjsKFUF3c09yZ2FuaXph
dGlvbmFsVW5pdBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRowCgpBd3NB
Y2NvdW50Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lIrAFCg1BenVyZU1l
dGFkYXRhEm8KEW1hbmFnZW1lbnRfZ3JvdXBzGAEgAygLMkIuZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYyLkF6dXJlTWV0YWRhdGEuQXp1cmVNYW5hZ2VtZW50R3JvdXBSEG1hbmFn
ZW1lbnRHcm91cHMSYwoMc3Vic2NyaXB0aW9uGAIgASgLMj8uZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYyLkF6dXJlTWV0YWRhdGEuQXp1cmVTdWJzY3JpcHRpb25SDHN1YnNjcmlw
dGlvbhJnCg5yZXNvdXJjZV9ncm91cBgDIAEoCzJALmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52Mi5BenVyZU1ldGFkYXRhLkF6dXJlUmVzb3VyY2VHcm91cFINcmVzb3VyY2VHcm91
cBJRCgZ0ZW5hbnQYByABKAsyOS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQXp1
cmVNZXRhZGF0YS5BenVyZVRlbmFudFIGdGVuYW50GkkKFEF6dXJlTWFuYWdlbWVudEdyb3Vw
Eg4KAmlkGAEgASgJUgJpZBIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lGkYK
EUF6dXJlU3Vic2NyaXB0aW9uEg4KAmlkGAEgASgJUgJpZBIhCgxkaXNwbGF5X25hbWUYAiAB
KAlSC2Rpc3BsYXlOYW1lGjgKEkF6dXJlUmVzb3VyY2VHcm91cBIOCgJpZBgCIAEoCVICaWQS
EgoEbmFtZRgBIAEoCVIEbmFtZRpACgtBenVyZVRlbmFudBIOCgJpZBgBIAEoCVICaWQSIQoM
ZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZSKWBAoMUmVzb3VyY2VQYXRoElMKBW5v
ZGVzGAEgAygLMj0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlJlc291cmNlUGF0
aC5SZXNvdXJjZVBhdGhOb2RlUgVub2RlcxqlAQoQUmVzb3VyY2VQYXRoTm9kZRJeCglub2Rl
X3R5cGUYASABKA4yQS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuUmVzb3VyY2VQ
YXRoLlJlc291cmNlUGF0aE5vZGVUeXBlUghub2RlVHlwZRIOCgJpZBgCIAEoCVICaWQSIQoM
ZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZSKIAgoUUmVzb3VyY2VQYXRoTm9kZVR5
cGUSJwojUkVTT1VSQ0VfUEFUSF9OT0RFX1RZUEVfVU5TUEVDSUZJRUQQABIUChBHQ1BfT1JH
QU5JWkFUSU9OEAESDgoKR0NQX0ZPTERFUhACEg8KC0dDUF9QUk9KRUNUEAMSFAoQQVdTX09S
R0FOSVpBVElPThAEEhsKF0FXU19PUkdBTklaQVRJT05BTF9VTklUEAUSDwoLQVdTX0FDQ09V
TlQQBhIaChZBWlVSRV9NQU5BR0VNRU5UX0dST1VQEAcSFgoSQVpVUkVfU1VCU0NSSVBUSU9O
EAgSGAoUQVpVUkVfUkVTT1VSQ0VfR1JPVVAQCSp4Cg1DbG91ZFByb3ZpZGVyEh4KGkNMT1VE
X1BST1ZJREVSX1VOU1BFQ0lGSUVEEAASGQoVR09PR0xFX0NMT1VEX1BMQVRGT1JNEAESFwoT
QU1BWk9OX1dFQl9TRVJWSUNFUxACEhMKD01JQ1JPU09GVF9BWlVSRRADQucBCiJjb20uZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQg1SZXNvdXJjZVByb3RvUAFaSmNsb3VkLmdv
b2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1
cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xl
XENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50
ZXI6OlYySpxPCgcSBQ4AkgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
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
CAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA1CggKAQgSAxYAOwoJ
CgIIJRIDFgA7CggKAQgSAxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChIDGAAiCggK
AQgSAxkALgoJCgIICBIDGQAuCggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsAOwoJCgII
KRIDGwA7CggKAQgSAxwAOgoJCgIILRIDHAA6Cj8KAgQAEgQfAE0BGjMgSW5mb3JtYXRpb24g
cmVsYXRlZCB0byB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlLgoKCgoDBAABEgMfCBAKgwEK
BAQAAgASAyICEhp2IFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlc291cmNlLiBT
ZWU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFt
ZXMjZnVsbF9yZXNvdXJjZV9uYW1lCgoMCgUEAAIABRIDIgIICgwKBQQAAgABEgMiCQ0KDAoF
BAACAAMSAyIQEQo3CgQEAAIBEgMlAhoaKiBUaGUgaHVtYW4gcmVhZGFibGUgbmFtZSBvZiB0
aGUgcmVzb3VyY2UuCgoMCgUEAAIBBRIDJQIICgwKBQQAAgEBEgMlCRUKDAoFBAACAQMSAyUY
GQo2CgQEAAICEgMoAhIaKSBUaGUgZnVsbCByZXNvdXJjZSB0eXBlIG9mIHRoZSByZXNvdXJj
ZS4KCgwKBQQAAgIFEgMoAggKDAoFBAACAgESAygJDQoMCgUEAAICAxIDKBARCkIKBAQAAgMS
AysCIxo1IEluZGljYXRlcyB3aGljaCBjbG91ZCBwcm92aWRlciB0aGUgZmluZGluZyBpcyBm
cm9tLgoKDAoFBAACAwYSAysCDwoMCgUEAAIDARIDKxAeCgwKBQQAAgMDEgMrISIKTQoEBAAC
BBIDLgIVGkAgVGhlIHNlcnZpY2Ugb3IgcmVzb3VyY2UgcHJvdmlkZXIgYXNzb2NpYXRlZCB3
aXRoIHRoZSByZXNvdXJjZS4KCgwKBQQAAgQFEgMuAggKDAoFBAACBAESAy4JEAoMCgUEAAIE
AxIDLhMUCkUKBAQAAgUSAzECFho4IFRoZSByZWdpb24gb3IgbG9jYXRpb24gb2YgdGhlIHNl
cnZpY2UgKGlmIGFwcGxpY2FibGUpLgoKDAoFBAACBQUSAzECCAoMCgUEAAIFARIDMQkRCgwK
BQQAAgUDEgMxFBUKQAoEBAAIABIENAI9AxoyIFRoZSBtZXRhZGF0YSBhc3NvY2lhdGVkIHdp
dGggdGhlIGNsb3VkIHByb3ZpZGVyLgoKDAoFBAAIAAESAzQIHwo8CgQEAAIGEgM2BCEaLyBU
aGUgR0NQIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmluZGluZy4KCgwKBQQAAgYG
EgM2BA8KDAoFBAACBgESAzYQHAoMCgUEAAIGAxIDNh8gCjwKBAQAAgcSAzkEIRovIFRoZSBB
V1MgbWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5nLgoKDAoFBAACBwYSAzkE
DwoMCgUEAAIHARIDORAcCgwKBQQAAgcDEgM5HyAKPgoEBAACCBIDPAQlGjEgVGhlIEF6dXJl
IG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmluZGluZy4KCgwKBQQAAggGEgM8BBEK
DAoFBAACCAESAzwSIAoMCgUEAAIIAxIDPCMkCk8KBAQAAgkSA0ACIhpCIFByb3ZpZGVzIHRo
ZSBwYXRoIHRvIHRoZSByZXNvdXJjZSB3aXRoaW4gdGhlIHJlc291cmNlIGhpZXJhcmNoeS4K
CgwKBQQAAgkGEgNAAg4KDAoFBAACCQESA0APHAoMCgUEAAIJAxIDQB8hCvEECgQEAAIKEgNM
AiMa4wQgQSBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2YgdGhlIHJlc291cmNlIHBhdGguCiBG
b3IgR29vZ2xlIENsb3VkLCBpdCBoYXMgdGhlIGZvcm1hdCBvZgogYG9yZ2FuaXphdGlvbnMv
e29yZ2FuaXphdGlvbl9pZH0vZm9sZGVycy97Zm9sZGVyX2lkfS9mb2xkZXJzL3tmb2xkZXJf
aWR9L3Byb2plY3RzL3twcm9qZWN0X2lkfWAKIHdoZXJlIHRoZXJlIGNhbiBiZSBhbnkgbnVt
YmVyIG9mIGZvbGRlcnMuCiBGb3IgQVdTLCBpdCBoYXMgdGhlIGZvcm1hdCBvZgogYG9yZy97
b3JnYW5pemF0aW9uX2lkfS9vdS97b3JnYW5pemF0aW9uYWxfdW5pdF9pZH0vb3Uve29yZ2Fu
aXphdGlvbmFsX3VuaXRfaWR9L2FjY291bnQve2FjY291bnRfaWR9YAogd2hlcmUgdGhlcmUg
Y2FuIGJlIGFueSBudW1iZXIgb2Ygb3JnYW5pemF0aW9uYWwgdW5pdHMuCiBGb3IgQXp1cmUs
IGl0IGhhcyB0aGUgZm9ybWF0IG9mCiBgbWcve21hbmFnZW1lbnRfZ3JvdXBfaWR9L21nL3tt
YW5hZ2VtZW50X2dyb3VwX2lkfS9zdWJzY3JpcHRpb24ve3N1YnNjcmlwdGlvbl9pZH0vcmcv
e3Jlc291cmNlX2dyb3VwX25hbWV9YAogd2hlcmUgdGhlcmUgY2FuIGJlIGFueSBudW1iZXIg
b2YgbWFuYWdlbWVudCBncm91cHMuCgoMCgUEAAIKBRIDTAIICgwKBQQAAgoBEgNMCR0KDAoF
BAACCgMSA0wgIgo5CgIFABIEUABcARotIFRoZSBjbG91ZCBwcm92aWRlciB0aGUgZmluZGlu
ZyBwZXJ0YWlucyB0by4KCgoKAwUAARIDUAUSCjEKBAUAAgASA1ICIRokIFRoZSBjbG91ZCBw
cm92aWRlciBpcyB1bnNwZWNpZmllZC4KCgwKBQUAAgABEgNSAhwKDAoFBQACAAISA1IfIAoy
CgQFAAIBEgNVAhwaJSBUaGUgY2xvdWQgcHJvdmlkZXIgaXMgR29vZ2xlIENsb3VkLgoKDAoF
BQACAQESA1UCFwoMCgUFAAIBAhIDVRobCjkKBAUAAgISA1gCGhosIFRoZSBjbG91ZCBwcm92
aWRlciBpcyBBbWF6b24gV2ViIFNlcnZpY2VzLgoKDAoFBQACAgESA1gCFQoMCgUFAAICAhID
WBgZCjUKBAUAAgMSA1sCFhooIFRoZSBjbG91ZCBwcm92aWRlciBpcyBNaWNyb3NvZnQgQXp1
cmUuCgoMCgUFAAIDARIDWwIRCgwKBQUAAgMCEgNbFBUKgwEKAgQBEgRgAHQBGncgR29vZ2xl
IENsb3VkIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuIE9ubHkgYXBw
bGljYWJsZSBpZiB0aGUKIGZpbmRpbmcncyBjbG91ZCBwcm92aWRlciBpcyBHb29nbGUgQ2xv
dWQuCgoKCgMEAQESA2AIEwpOCgQEAQIAEgNiAhUaQSBUaGUgZnVsbCByZXNvdXJjZSBuYW1l
IG9mIHByb2plY3QgdGhhdCB0aGUgcmVzb3VyY2UgYmVsb25ncyB0by4KCgwKBQQBAgAFEgNi
AggKDAoFBAECAAESA2IJEAoMCgUEAQIAAxIDYhMUCjsKBAQBAgESA2UCIhouIFRoZSBwcm9q
ZWN0IElEIHRoYXQgdGhlIHJlc291cmNlIGJlbG9uZ3MgdG8uCgoMCgUEAQIBBRIDZQIICgwK
BQQBAgEBEgNlCR0KDAoFBAECAQMSA2UgIQo7CgQEAQICEgNoAhQaLiBUaGUgZnVsbCByZXNv
dXJjZSBuYW1lIG9mIHJlc291cmNlJ3MgcGFyZW50LgoKDAoFBAECAgUSA2gCCAoMCgUEAQIC
ARIDaAkPCgwKBQQBAgIDEgNoEhMKPAoEBAECAxIDawIhGi8gVGhlIGh1bWFuIHJlYWRhYmxl
IG5hbWUgb2YgcmVzb3VyY2UncyBwYXJlbnQuCgoMCgUEAQIDBRIDawIICgwKBQQBAgMBEgNr
CRwKDAoFBAECAwMSA2sfIArSAQoEBAECBBIDcAJKGsQBIE91dHB1dCBvbmx5LiBDb250YWlu
cyBhIEZvbGRlciBtZXNzYWdlIGZvciBlYWNoIGZvbGRlciBpbiB0aGUgYXNzZXRzCiBhbmNl
c3RyeS4gVGhlIGZpcnN0IGZvbGRlciBpcyB0aGUgZGVlcGVzdCBuZXN0ZWQgZm9sZGVyLCBh
bmQgdGhlIGxhc3QKIGZvbGRlciBpcyB0aGUgZm9sZGVyIGRpcmVjdGx5IHVuZGVyIHRoZSBP
cmdhbml6YXRpb24uCgoMCgUEAQIEBBIDcAIKCgwKBQQBAgQGEgNwCxEKDAoFBAECBAESA3AS
GQoMCgUEAQIEAxIDcBwdCgwKBQQBAgQIEgNwHkkKDwoIBAECBAicCAASA3AfSApJCgQEAQIF
EgNzAhoaPCBUaGUgbmFtZSBvZiB0aGUgb3JnYW5pemF0aW9uIHRoYXQgdGhlIHJlc291cmNl
IGJlbG9uZ3MgdG8uCgoMCgUEAQIFBRIDcwIICgwKBQQBAgUBEgNzCRUKDAoFBAECBQMSA3MY
GQqCAQoCBAISBXgApAEBGnUgQVdTIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVz
b3VyY2UsIG9ubHkgYXBwbGljYWJsZSBpZiB0aGUgZmluZGluZydzCiBjbG91ZCBwcm92aWRl
ciBpcyBBbWF6b24gV2ViIFNlcnZpY2VzLgoKCgoDBAIBEgN4CBMK1wEKBAQCAwASBXwCgQED
GscBIEFuIG9yZ2FuaXphdGlvbiBpcyBhIGNvbGxlY3Rpb24gb2YgYWNjb3VudHMgdGhhdCBh
cmUgY2VudHJhbGx5IG1hbmFnZWQKIHRvZ2V0aGVyIHVzaW5nIGNvbnNvbGlkYXRlZCBiaWxs
aW5nLCBvcmdhbml6ZWQgaGllcmFyY2hpY2FsbHkgd2l0aAogb3JnYW5pemF0aW9uYWwgdW5p
dHMgKE9VcyksIGFuZCBjb250cm9sbGVkIHdpdGggcG9saWNpZXMuCgoMCgUEAgMAARIDfAoZ
CroBCgYEAgMAAgASBIABBBIaqQEgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIChJRCkgZm9yIHRo
ZSBvcmdhbml6YXRpb24uIFRoZSByZWdleCBwYXR0ZXJuIGZvciBhbgogb3JnYW5pemF0aW9u
IElEIHN0cmluZyByZXF1aXJlcyAiby0iIGZvbGxvd2VkIGJ5IGZyb20gMTAgdG8gMzIgbG93
ZXJjYXNlCiBsZXR0ZXJzIG9yIGRpZ2l0cy4KCg8KBwQCAwACAAUSBIABBAoKDwoHBAIDAAIA
ARIEgAELDQoPCgcEAgMAAgADEgSAARARCtYBCgQEAgMBEgaGAQKQAQMaxQEgQW4gT3JnYW5p
emF0aW9uYWwgVW5pdCAoT1UpIGlzIGEgY29udGFpbmVyIG9mIEFXUyBhY2NvdW50cyB3aXRo
aW4gYSByb290IG9mCiBhbiBvcmdhbml6YXRpb24uIFBvbGljaWVzIHRoYXQgYXJlIGF0dGFj
aGVkIHRvIGFuIE9VIGFwcGx5IHRvIGFsbCBhY2NvdW50cwogY29udGFpbmVkIGluIHRoYXQg
T1UgYW5kIGluIGFueSBjaGlsZCBPVXMuCgoNCgUEAgMBARIEhgEKHwr3AgoGBAIDAQIAEgSM
AQQSGuYCIFRoZSB1bmlxdWUgaWRlbnRpZmllciAoSUQpIGFzc29jaWF0ZWQgd2l0aCB0aGlz
IE9VLiBUaGUgcmVnZXggcGF0dGVybiBmb3IKIGFuIG9yZ2FuaXphdGlvbmFsIHVuaXQgSUQg
c3RyaW5nIHJlcXVpcmVzICJvdS0iIGZvbGxvd2VkIGJ5IGZyb20gNCB0byAzMgogbG93ZXJj
YXNlIGxldHRlcnMgb3IgZGlnaXRzICh0aGUgSUQgb2YgdGhlIHJvb3QgdGhhdCBjb250YWlu
cyB0aGUgT1UpLgogVGhpcyBzdHJpbmcgaXMgZm9sbG93ZWQgYnkgYSBzZWNvbmQgIi0iIGRh
c2ggYW5kIGZyb20gOCB0byAzMiBhZGRpdGlvbmFsCiBsb3dlcmNhc2UgbGV0dGVycyBvciBk
aWdpdHMuIEZvciBleGFtcGxlLCAib3UtYWIxMi1jZDM0ZWY1NiIuCgoPCgcEAgMBAgAFEgSM
AQQKCg8KBwQCAwECAAESBIwBCw0KDwoHBAIDAQIAAxIEjAEQEQouCgYEAgMBAgESBI8BBBQa
HiBUaGUgZnJpZW5kbHkgbmFtZSBvZiB0aGUgT1UuCgoPCgcEAgMBAgEFEgSPAQQKCg8KBwQC
AwECAQESBI8BCw8KDwoHBAIDAQIBAxIEjwESEwpFCgQEAgMCEgaTAQKZAQMaNSBBbiBBV1Mg
YWNjb3VudCB0aGF0IGlzIGEgbWVtYmVyIG9mIGFuIG9yZ2FuaXphdGlvbi4KCg0KBQQCAwIB
EgSTAQoUCloKBgQCAwICABIElQEEEhpKIFRoZSB1bmlxdWUgaWRlbnRpZmllciAoSUQpIG9m
IHRoZSBhY2NvdW50LCBjb250YWluaW5nIGV4YWN0bHkgMTIgZGlnaXRzLgoKDwoHBAIDAgIA
BRIElQEECgoPCgcEAgMCAgABEgSVAQsNCg8KBwQCAwICAAMSBJUBEBEKNAoGBAIDAgIBEgSY
AQQUGiQgVGhlIGZyaWVuZGx5IG5hbWUgb2YgdGhpcyBhY2NvdW50LgoKDwoHBAIDAgIBBRIE
mAEECgoPCgcEAgMCAgEBEgSYAQsPCg8KBwQCAwICAQMSBJgBEhMKQgoEBAICABIEnAECIxo0
IFRoZSBBV1Mgb3JnYW5pemF0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuCgoN
CgUEAgIABhIEnAECEQoNCgUEAgIAARIEnAESHgoNCgUEAgIAAxIEnAEhIgqXAQoEBAICARIE
oAECOhqIASBBIGxpc3Qgb2YgQVdTIG9yZ2FuaXphdGlvbmFsIHVuaXRzIGFzc29jaWF0ZWQg
d2l0aCB0aGUgcmVzb3VyY2UsIG9yZGVyZWQKIGZyb20gbG93ZXN0IGxldmVsIChjbG9zZXN0
IHRvIHRoZSBhY2NvdW50KSB0byBoaWdoZXN0IGxldmVsLgoKDQoFBAICAQQSBKABAgoKDQoF
BAICAQYSBKABCyAKDQoFBAICAQESBKABITUKDQoFBAICAQMSBKABODkKPQoEBAICAhIEowEC
GRovIFRoZSBBV1MgYWNjb3VudCBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291cmNlLgoKDQoF
BAICAgYSBKMBAgwKDQoFBAICAgESBKMBDRQKDQoFBAICAgMSBKMBFxgKgQEKAgQDEgaoAQDc
AQEacyBBenVyZSBtZXRhZGF0YSBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291cmNlLCBvbmx5
IGFwcGxpY2FibGUgaWYgdGhlIGZpbmRpbmcncwogY2xvdWQgcHJvdmlkZXIgaXMgTWljcm9z
b2Z0IEF6dXJlLgoKCwoDBAMBEgSoAQgVCjcKBAQDAwASBqoBArEBAxonIFJlcHJlc2VudHMg
YW4gQXp1cmUgbWFuYWdlbWVudCBncm91cC4KCg0KBQQDAwABEgSqAQoeCm8KBgQDAwACABIE
rQEEEhpfIFRoZSBVVUlEIG9mIHRoZSBBenVyZSBtYW5hZ2VtZW50IGdyb3VwLCBmb3IgZXhh
bXBsZSwKIGAyMDAwMDAwMC0wMDAxLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDBgLgoKDwoHBAMD
AAIABRIErQEECgoPCgcEAwMAAgABEgStAQsNCg8KBwQDAwACAAMSBK0BEBEKQQoGBAMDAAIB
EgSwAQQcGjEgVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgQXp1cmUgbWFuYWdlbWVudCBncm91
cC4KCg8KBwQDAwACAQUSBLABBAoKDwoHBAMDAAIBARIEsAELFwoPCgcEAwMAAgEDEgSwARob
CjMKBAQDAwESBrQBArsBAxojIFJlcHJlc2VudHMgYW4gQXp1cmUgc3Vic2NyaXB0aW9uLgoK
DQoFBAMDAQESBLQBChsKawoGBAMDAQIAEgS3AQQSGlsgVGhlIFVVSUQgb2YgdGhlIEF6dXJl
IHN1YnNjcmlwdGlvbiwgZm9yIGV4YW1wbGUsCiBgMjkxYmJhM2YtZTBhNS00N2JjLWEwOTkt
M2JkY2IyYTUwYTA1YC4KCg8KBwQDAwECAAUSBLcBBAoKDwoHBAMDAQIAARIEtwELDQoPCgcE
AwMBAgADEgS3ARARCj0KBgQDAwECARIEugEEHBotIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhl
IEF6dXJlIHN1YnNjcmlwdGlvbi4KCg8KBwQDAwECAQUSBLoBBAoKDwoHBAMDAQIBARIEugEL
FwoPCgcEAwMBAgEDEgS6ARobCjUKBAQDAwISBr4BAsQBAxolIFJlcHJlc2VudHMgYW4gQXp1
cmUgcmVzb3VyY2UgZ3JvdXAuCgoNCgUEAwMCARIEvgEKHAo1CgYEAwMCAgASBMABBBIaJSBU
aGUgSUQgb2YgdGhlIEF6dXJlIHJlc291cmNlIGdyb3VwLgoKDwoHBAMDAgIABRIEwAEECgoP
CgcEAwMCAgABEgTAAQsNCg8KBwQDAwICAAMSBMABEBEKSwoGBAMDAgIBEgTDAQQUGjsgVGhl
IG5hbWUgb2YgdGhlIEF6dXJlIHJlc291cmNlIGdyb3VwLiBUaGlzIGlzIG5vdCBhIFVVSUQu
CgoPCgcEAwMCAgEFEgTDAQQKCg8KBwQDAwICAQESBMMBCw8KDwoHBAMDAgIBAxIEwwESEwo2
CgQEAwMDEgbHAQLOAQMaJiBSZXByZXNlbnRzIGEgTWljcm9zb2Z0IEVudHJhIHRlbmFudC4K
Cg0KBQQDAwMBEgTHAQoVCmgKBgQDAwMCABIEygEEEhpYIFRoZSBJRCBvZiB0aGUgTWljcm9z
b2Z0IEVudHJhIHRlbmFudCwgZm9yIGV4YW1wbGUsCiAiYTExYWFhMTEtYWExMS0xYWExLTEx
YWEtMWFhYTExYSIuCgoPCgcEAwMDAgAFEgTKAQQKCg8KBwQDAwMCAAESBMoBCw0KDwoHBAMD
AwIAAxIEygEQEQo3CgYEAwMDAgESBM0BBBwaJyBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBB
enVyZSB0ZW5hbnQuCgoPCgcEAwMDAgEFEgTNAQQKCg8KBwQDAwMCAQESBM0BCxcKDwoHBAMD
AwIBAxIEzQEaGwqbAQoEBAMCABIE0gECNhqMASBBIGxpc3Qgb2YgQXp1cmUgbWFuYWdlbWVu
dCBncm91cHMgYXNzb2NpYXRlZCB3aXRoIHRoZSByZXNvdXJjZSwgb3JkZXJlZAogZnJvbSBs
b3dlc3QgbGV2ZWwgKGNsb3Nlc3QgdG8gdGhlIHN1YnNjcmlwdGlvbikgdG8gaGlnaGVzdCBs
ZXZlbC4KCg0KBQQDAgAEEgTSAQIKCg0KBQQDAgAGEgTSAQsfCg0KBQQDAgABEgTSASAxCg0K
BQQDAgADEgTSATQ1CkQKBAQDAgESBNUBAiUaNiBUaGUgQXp1cmUgc3Vic2NyaXB0aW9uIGFz
c29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuCgoNCgUEAwIBBhIE1QECEwoNCgUEAwIBARIE
1QEUIAoNCgUEAwIBAxIE1QEjJApGCgQEAwICEgTYAQIoGjggVGhlIEF6dXJlIHJlc291cmNl
IGdyb3VwIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuCgoNCgUEAwICBhIE2AECFAoN
CgUEAwICARIE2AEVIwoNCgUEAwICAxIE2AEmJwpECgQEAwIDEgTbAQIZGjYgVGhlIEF6dXJl
IEVudHJhIHRlbmFudCBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291cmNlLgoKDQoFBAMCAwYS
BNsBAg0KDQoFBAMCAwESBNsBDhQKDQoFBAMCAwMSBNsBFxgKYwoCBAQSBuABAJICARpVIFJl
cHJlc2VudHMgdGhlIHBhdGggb2YgcmVzb3VyY2VzIGxlYWRpbmcgdXAgdG8gdGhlIHJlc291
cmNlIHRoaXMgZmluZGluZyBpcwogYWJvdXQuCgoLCgMEBAESBOABCBQKOwoEBAQEABIG4gEC
gAIDGisgVGhlIHR5cGUgb2YgcmVzb3VyY2UgdGhlIG5vZGUgcmVwcmVzZW50cy4KCg0KBQQE
BAABEgTiAQcbCisKBgQEBAACABIE5AEELBobIE5vZGUgdHlwZSBpcyB1bnNwZWNpZmllZC4K
Cg8KBwQEBAACAAESBOQBBCcKDwoHBAQEAAIAAhIE5AEqKwpCCgYEBAQAAgESBOcBBBkaMiBU
aGUgbm9kZSByZXByZXNlbnRzIGEgR29vZ2xlIENsb3VkIG9yZ2FuaXphdGlvbi4KCg8KBwQE
BAACAQESBOcBBBQKDwoHBAQEAAIBAhIE5wEXGAo8CgYEBAQAAgISBOoBBBMaLCBUaGUgbm9k
ZSByZXByZXNlbnRzIGEgR29vZ2xlIENsb3VkIGZvbGRlci4KCg8KBwQEBAACAgESBOoBBA4K
DwoHBAQEAAICAhIE6gEREgo9CgYEBAQAAgMSBO0BBBQaLSBUaGUgbm9kZSByZXByZXNlbnRz
IGEgR29vZ2xlIENsb3VkIHByb2plY3QuCgoPCgcEBAQAAgMBEgTtAQQPCg8KBwQEBAACAwIS
BO0BEhMKOgoGBAQEAAIEEgTwAQQZGiogVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBBV1Mgb3Jn
YW5pemF0aW9uLgoKDwoHBAQEAAIEARIE8AEEFAoPCgcEBAQAAgQCEgTwARcYCkEKBgQEBAAC
BRIE8wEEIBoxIFRoZSBub2RlIHJlcHJlc2VudHMgYW4gQVdTIG9yZ2FuaXphdGlvbmFsIHVu
aXQuCgoPCgcEBAQAAgUBEgTzAQQbCg8KBwQEBAACBQISBPMBHh8KNQoGBAQEAAIGEgT2AQQU
GiUgVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBBV1MgYWNjb3VudC4KCg8KBwQEBAACBgESBPYB
BA8KDwoHBAQEAAIGAhIE9gESEwpACgYEBAQAAgcSBPkBBB8aMCBUaGUgbm9kZSByZXByZXNl
bnRzIGFuIEF6dXJlIG1hbmFnZW1lbnQgZ3JvdXAuCgoPCgcEBAQAAgcBEgT5AQQaCg8KBwQE
BAACBwISBPkBHR4KPAoGBAQEAAIIEgT8AQQbGiwgVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBB
enVyZSBzdWJzY3JpcHRpb24uCgoPCgcEBAQAAggBEgT8AQQWCg8KBwQEBAACCAISBPwBGRoK
PgoGBAQEAAIJEgT/AQQdGi4gVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBBenVyZSByZXNvdXJj
ZSBncm91cC4KCg8KBwQEBAACCQESBP8BBBgKDwoHBAQEAAIJAhIE/wEbHApyCgQEBAMAEgaE
AgKNAgMaYiBBIG5vZGUgd2l0aGluIHRoZSByZXNvdXJjZSBwYXRoLiBFYWNoIG5vZGUgcmVw
cmVzZW50cyBhIHJlc291cmNlIHdpdGhpbiB0aGUKIHJlc291cmNlIGhpZXJhcmNoeS4KCg0K
BQQEAwABEgSEAgoaCjwKBgQEAwACABIEhgIEJxosIFRoZSB0eXBlIG9mIHJlc291cmNlIHRo
aXMgbm9kZSByZXByZXNlbnRzLgoKDwoHBAQDAAIABhIEhgIEGAoPCgcEBAMAAgABEgSGAhki
Cg8KBwQEAwACAAMSBIYCJSYKPgoGBAQDAAIBEgSJAgQSGi4gVGhlIElEIG9mIHRoZSByZXNv
dXJjZSB0aGlzIG5vZGUgcmVwcmVzZW50cy4KCg8KBwQEAwACAQUSBIkCBAoKDwoHBAQDAAIB
ARIEiQILDQoPCgcEBAMAAgEDEgSJAhARCkgKBgQEAwACAhIEjAIEHBo4IFRoZSBkaXNwbGF5
IG5hbWUgb2YgdGhlIHJlc291cmNlIHRoaXMgbm9kZSByZXByZXNlbnRzLgoKDwoHBAQDAAIC
BRIEjAIECgoPCgcEBAMAAgIBEgSMAgsXCg8KBwQEAwACAgMSBIwCGhsKbgoEBAQCABIEkQIC
JhpgIFRoZSBsaXN0IG9mIG5vZGVzIHRoYXQgbWFrZSB0aGUgdXAgcmVzb3VyY2UgcGF0aCwg
b3JkZXJlZCBmcm9tIGxvd2VzdAogbGV2ZWwgdG8gaGlnaGVzdCBsZXZlbC4KCg0KBQQEAgAE
EgSRAgIKCg0KBQQEAgAGEgSRAgsbCg0KBQQEAgABEgSRAhwhCg0KBQQEAgADEgSRAiQlYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Resource::Resource ===
    # Fields for Resource
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v2.CloudProvider)
    # Field: service Type: 9 ()
    # Field: location Type: 9 ()
    # Field: gcp_metadata Type: 11 (.google.cloud.securitycenter.v2.GcpMetadata)
    # Field: aws_metadata Type: 11 (.google.cloud.securitycenter.v2.AwsMetadata)
    # Field: azure_metadata Type: 11 (.google.cloud.securitycenter.v2.AzureMetadata)
    # Field: resource_path Type: 11 (.google.cloud.securitycenter.v2.ResourcePath)
    # Field: resource_path_string Type: 9 ()

# === Message: Google::Cloud::Securitycenter::V2::Resource::GcpMetadata ===
    # Fields for GcpMetadata
    # Field: project Type: 9 ()
    # Field: project_display_name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: parent_display_name Type: 9 ()
    # Field: folders Type: 11 (.google.cloud.securitycenter.v2.Folder)
    # Field: organization Type: 9 ()

# === Message: Google::Cloud::Securitycenter::V2::Resource::AwsMetadata ===
    # Fields for AwsMetadata
    # Field: organization Type: 11 (.google.cloud.securitycenter.v2.AwsMetadata.AwsOrganization)
    # Field: organizational_units Type: 11 (.google.cloud.securitycenter.v2.AwsMetadata.AwsOrganizationalUnit)
    # Field: account Type: 11 (.google.cloud.securitycenter.v2.AwsMetadata.AwsAccount)

# === Message: Google::Cloud::Securitycenter::V2::Resource::AzureMetadata ===
    # Fields for AzureMetadata
    # Field: management_groups Type: 11 (.google.cloud.securitycenter.v2.AzureMetadata.AzureManagementGroup)
    # Field: subscription Type: 11 (.google.cloud.securitycenter.v2.AzureMetadata.AzureSubscription)
    # Field: resource_group Type: 11 (.google.cloud.securitycenter.v2.AzureMetadata.AzureResourceGroup)
    # Field: tenant Type: 11 (.google.cloud.securitycenter.v2.AzureMetadata.AzureTenant)

# === Message: Google::Cloud::Securitycenter::V2::Resource::ResourcePath ===
    # Fields for ResourcePath
    # Field: nodes Type: 11 (.google.cloud.securitycenter.v2.ResourcePath.ResourcePathNode)

# Enum: ResourcePath::ResourcePathNodeType
our $ResourcePath_RESOURCE_PATH_NODE_TYPE_UNSPECIFIED = 0;
our $ResourcePath_GCP_ORGANIZATION = 1;
our $ResourcePath_GCP_FOLDER = 2;
our $ResourcePath_GCP_PROJECT = 3;
our $ResourcePath_AWS_ORGANIZATION = 4;
our $ResourcePath_AWS_ORGANIZATIONAL_UNIT = 5;
our $ResourcePath_AWS_ACCOUNT = 6;
our $ResourcePath_AZURE_MANAGEMENT_GROUP = 7;
our $ResourcePath_AZURE_SUBSCRIPTION = 8;
our $ResourcePath_AZURE_RESOURCE_GROUP = 9;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Resource - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Resource;

    my $msg = Google::Cloud::Securitycenter::V2::Resource::Resource->new({
        name => $name,
        display_name => $display_name,
        type => $type,
        cloud_provider => $cloud_provider,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Resource::Resource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Resource::Resource

Information related to the Google Cloud resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full resource name of the resource. See:
https://cloud.google.com/apis/design/resource_names#full_resource_name

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human readable name of the resource.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The full resource type of the resource.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::CloudProvider>)

Indicates which cloud provider the finding is from.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The service or resource provider associated with the resource.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The region or location of the service (if applicable).

=item * C<< $msg->gcp_metadata() >> / C<< $msg->gcp_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::GcpMetadata>)

The GCP metadata associated with the finding.

=item * C<< $msg->aws_metadata() >> / C<< $msg->aws_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AwsMetadata>)

The AWS metadata associated with the finding.

=item * C<< $msg->azure_metadata() >> / C<< $msg->azure_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AzureMetadata>)

The Azure metadata associated with the finding.

=item * C<< $msg->resource_path() >> / C<< $msg->resource_path($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::ResourcePath>)

Provides the path to the resource within the resource hierarchy.

=item * C<< $msg->resource_path_string() >> / C<< $msg->resource_path_string($value) >>

Type: C<String>

A string representation of the resource path.
For Google Cloud, it has the format of
`organizations/{organization_id}/folders/{folder_id}/folders/{folder_id}/projects/{project_id}`
where there can be any number of folders.
For AWS, it has the format of
`org/{organization_id}/ou/{organizational_unit_id}/ou/{organizational_unit_id}/account/{account_id}`
where there can be any number of organizational units.
For Azure, it has the format of
`mg/{management_group_id}/mg/{management_group_id}/subscription/{subscription_id}/rg/{resource_group_name}`
where there can be any number of management groups.

=back

=head2 Google::Cloud::Securitycenter::V2::Resource::GcpMetadata

Google Cloud metadata associated with the resource. Only applicable if the
finding's cloud provider is Google Cloud.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The full resource name of project that the resource belongs to.

=item * C<< $msg->project_display_name() >> / C<< $msg->project_display_name($value) >>

Type: C<String>

The project ID that the resource belongs to.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The full resource name of resource's parent.

=item * C<< $msg->parent_display_name() >> / C<< $msg->parent_display_name($value) >>

Type: C<String>

The human readable name of resource's parent.

=item * C<< $msg->folders() >> / C<< $msg->folders($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Folder::Folder>)

Output only. Contains a Folder message for each folder in the assets
ancestry. The first folder is the deepest nested folder, and the last
folder is the folder directly under the Organization.

=item * C<< $msg->organization() >> / C<< $msg->organization($value) >>

Type: C<String>

The name of the organization that the resource belongs to.

=back

=head2 Google::Cloud::Securitycenter::V2::Resource::AwsMetadata

AWS metadata associated with the resource, only applicable if the finding's
cloud provider is Amazon Web Services.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->organization() >> / C<< $msg->organization($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganization>)

The AWS organization associated with the resource.

=item * C<< $msg->organizational_units() >> / C<< $msg->organizational_units($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganizationalUnit>)

A list of AWS organizational units associated with the resource, ordered
from lowest level (closest to the account) to highest level.

=item * C<< $msg->account() >> / C<< $msg->account($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsAccount>)

The AWS account associated with the resource.

=back

=head2 Google::Cloud::Securitycenter::V2::Resource::AzureMetadata

Azure metadata associated with the resource, only applicable if the finding's
cloud provider is Microsoft Azure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->management_groups() >> / C<< $msg->management_groups($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureManagementGroup>)

A list of Azure management groups associated with the resource, ordered
from lowest level (closest to the subscription) to highest level.

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureSubscription>)

The Azure subscription associated with the resource.

=item * C<< $msg->resource_group() >> / C<< $msg->resource_group($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureResourceGroup>)

The Azure resource group associated with the resource.

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureTenant>)

The Azure Entra tenant associated with the resource.

=back

=head2 Google::Cloud::Securitycenter::V2::Resource::ResourcePath

Represents the path of resources leading up to the resource this finding is
about.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodes() >> / C<< $msg->nodes($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Resource::ResourcePath::ResourcePathNode>)

The list of nodes that make the up resource path, ordered from lowest
level to highest level.

=back

=head3 Enum: ResourcePath::ResourcePathNodeType

=over 4

=item * C<RESOURCE_PATH_NODE_TYPE_UNSPECIFIED> => C<0>

=item * C<GCP_ORGANIZATION> => C<1>

=item * C<GCP_FOLDER> => C<2>

=item * C<GCP_PROJECT> => C<3>

=item * C<AWS_ORGANIZATION> => C<4>

=item * C<AWS_ORGANIZATIONAL_UNIT> => C<5>

=item * C<AWS_ACCOUNT> => C<6>

=item * C<AZURE_MANAGEMENT_GROUP> => C<7>

=item * C<AZURE_SUBSCRIPTION> => C<8>

=item * C<AZURE_RESOURCE_GROUP> => C<9>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
