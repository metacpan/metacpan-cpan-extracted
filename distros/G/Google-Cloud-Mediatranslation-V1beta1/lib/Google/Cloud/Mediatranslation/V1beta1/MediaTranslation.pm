package Google::Cloud::Mediatranslation::V1beta1::MediaTranslation;

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
Cj1nb29nbGUvY2xvdWQvbWVkaWF0cmFuc2xhdGlvbi92MWJldGExL21lZGlhX3RyYW5zbGF0
aW9uLnByb3RvEiVnb29nbGUuY2xvdWQubWVkaWF0cmFuc2xhdGlvbi52MWJldGExGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8i/QEKFVRyYW5zbGF0ZVNwZWVjaENvbmZpZxIqCg5h
dWRpb19lbmNvZGluZxgBIAEoCUID4EECUg1hdWRpb0VuY29kaW5nEjUKFHNvdXJjZV9sYW5n
dWFnZV9jb2RlGAIgASgJQgPgQQJSEnNvdXJjZUxhbmd1YWdlQ29kZRI1ChR0YXJnZXRfbGFu
Z3VhZ2VfY29kZRgDIAEoCUID4EECUhJ0YXJnZXRMYW5ndWFnZUNvZGUSLwoRc2FtcGxlX3Jh
dGVfaGVydHoYBCABKAVCA+BBAVIPc2FtcGxlUmF0ZUhlcnR6EhkKBW1vZGVsGAUgASgJQgPg
QQFSBW1vZGVsIrYBCh5TdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hDb25maWcSZAoMYXVkaW9f
Y29uZmlnGAEgASgLMjwuZ29vZ2xlLmNsb3VkLm1lZGlhdHJhbnNsYXRpb24udjFiZXRhMS5U
cmFuc2xhdGVTcGVlY2hDb25maWdCA+BBAlILYXVkaW9Db25maWcSLgoQc2luZ2xlX3V0dGVy
YW5jZRgCIAEoCEID4EEBUg9zaW5nbGVVdHRlcmFuY2Ui0QEKH1N0cmVhbWluZ1RyYW5zbGF0
ZVNwZWVjaFJlcXVlc3QScgoQc3RyZWFtaW5nX2NvbmZpZxgBIAEoCzJFLmdvb2dsZS5jbG91
ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYmV0YTEuU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoQ29u
ZmlnSABSD3N0cmVhbWluZ0NvbmZpZxIlCg1hdWRpb19jb250ZW50GAIgASgMSABSDGF1ZGlv
Q29udGVudEITChFzdHJlYW1pbmdfcmVxdWVzdCKiAgoeU3RyZWFtaW5nVHJhbnNsYXRlU3Bl
ZWNoUmVzdWx0EpUBChd0ZXh0X3RyYW5zbGF0aW9uX3Jlc3VsdBgBIAEoCzJbLmdvb2dsZS5j
bG91ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYmV0YTEuU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNo
UmVzdWx0LlRleHRUcmFuc2xhdGlvblJlc3VsdEgAUhV0ZXh0VHJhbnNsYXRpb25SZXN1bHQa
XgoVVGV4dFRyYW5zbGF0aW9uUmVzdWx0EiUKC3RyYW5zbGF0aW9uGAEgASgJQgPgQQNSC3Ry
YW5zbGF0aW9uEh4KCGlzX2ZpbmFsGAIgASgIQgPgQQNSB2lzRmluYWxCCAoGcmVzdWx0IpMD
CiBTdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hSZXNwb25zZRItCgVlcnJvchgBIAEoCzISLmdv
b2dsZS5ycGMuU3RhdHVzQgPgQQNSBWVycm9yEmIKBnJlc3VsdBgCIAEoCzJFLmdvb2dsZS5j
bG91ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYmV0YTEuU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNo
UmVzdWx0QgPgQQNSBnJlc3VsdBKIAQoRc3BlZWNoX2V2ZW50X3R5cGUYAyABKA4yVy5nb29n
bGUuY2xvdWQubWVkaWF0cmFuc2xhdGlvbi52MWJldGExLlN0cmVhbWluZ1RyYW5zbGF0ZVNw
ZWVjaFJlc3BvbnNlLlNwZWVjaEV2ZW50VHlwZUID4EEDUg9zcGVlY2hFdmVudFR5cGUiUQoP
U3BlZWNoRXZlbnRUeXBlEiEKHVNQRUVDSF9FVkVOVF9UWVBFX1VOU1BFQ0lGSUVEEAASGwoX
RU5EX09GX1NJTkdMRV9VVFRFUkFOQ0UQATKjAgoYU3BlZWNoVHJhbnNsYXRpb25TZXJ2aWNl
ErEBChhTdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2gSRi5nb29nbGUuY2xvdWQubWVkaWF0cmFu
c2xhdGlvbi52MWJldGExLlN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlcXVlc3QaRy5nb29n
bGUuY2xvdWQubWVkaWF0cmFuc2xhdGlvbi52MWJldGExLlN0cmVhbWluZ1RyYW5zbGF0ZVNw
ZWVjaFJlc3BvbnNlIgAoATABGlPKQR9tZWRpYXRyYW5zbGF0aW9uLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKZAgop
Y29tLmdvb2dsZS5jbG91ZC5tZWRpYXRyYW5zbGF0aW9uLnYxYmV0YTFCFU1lZGlhVHJhbnNs
YXRpb25Qcm90b1ABWlVjbG91ZC5nb29nbGUuY29tL2dvL21lZGlhdHJhbnNsYXRpb24vYXBp
djFiZXRhMS9tZWRpYXRyYW5zbGF0aW9ucGI7bWVkaWF0cmFuc2xhdGlvbnBi+AEBqgIlR29v
Z2xlLkNsb3VkLk1lZGlhVHJhbnNsYXRpb24uVjFCZXRhMcoCJUdvb2dsZVxDbG91ZFxNZWRp
YVRyYW5zbGF0aW9uXFYxYmV0YTHqAihHb29nbGU6OkNsb3VkOjpNZWRpYVRyYW5zbGF0aW9u
OjpWMWJldGExSrxBCgcSBQ4AywEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAuCgkKAgMAEgMSACkKCQoCAwESAxMAIQoJCgIDAhIDFAAhCggKAQgSAxYA
HwoJCgIIHxIDFgAfCggKAQgSAxcAbAoJCgIICxIDFwBsCggKAQgSAxgAIgoJCgIIChIDGAAi
CggKAQgSAxkANgoJCgIICBIDGQA2CggKAQgSAxoAQgoJCgIIARIDGgBCCggKAQgSAxsAQgoJ
CgIIJRIDGwBCCggKAQgSAxwAQQoJCgIILRIDHABBCggKAQgSAx0AQgoJCgIIKRIDHQBCCjcK
AgYAEgQgACgBGisgUHJvdmlkZXMgdHJhbnNsYXRpb24gZnJvbS90byBtZWRpYSB0eXBlcy4K
CgoKAwYAARIDIAggCgoKAwYAAxIDIQJHCgwKBQYAA5kIEgMhAkcKCgoDBgADEgMiAlYKDAoF
BgADmggSAyICVgqmAQoEBgACABIEJgInAxqXASBQZXJmb3JtcyBiaWRpcmVjdGlvbmFsIHN0
cmVhbWluZyBzcGVlY2ggdHJhbnNsYXRpb246IHJlY2VpdmUgcmVzdWx0cyB3aGlsZQogc2Vu
ZGluZyBhdWRpby4gVGhpcyBtZXRob2QgaXMgb25seSBhdmFpbGFibGUgdmlhIHRoZSBnUlBD
IEFQSSAobm90IFJFU1QpLgoKDAoFBgACAAESAyYGHgoMCgUGAAIABRIDJh8lCgwKBQYAAgAC
EgMmJkUKDAoFBgACAAYSAyZQVgoMCgUGAAIAAxIDJld3CmgKAgQAEgQsAGMBGlwgUHJvdmlk
ZXMgaW5mb3JtYXRpb24gdG8gdGhlIHNwZWVjaCB0cmFuc2xhdGlvbiB0aGF0IHNwZWNpZmll
cyBob3cgdG8gcHJvY2VzcwogdGhlIHJlcXVlc3QuCgoKCgMEAAESAywIHQrhBwoEBAACABID
UQJFGtMHIFJlcXVpcmVkLiBFbmNvZGluZyBvZiBhdWRpbyBkYXRhLgogU3VwcG9ydGVkIGZv
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
ZGlvIGZyYW1lcyBpbiBbT2dnXShodHRwczovL3dpa2lwZWRpYS5vcmcvd2lraS9PZ2cpCiAg
IGNvbnRhaW5lci4gYHNhbXBsZV9yYXRlX2hlcnR6YCBtdXN0IGJlIG9uZSBvZiA4MDAwLCAx
MjAwMCwgMTYwMDAsIDI0MDAwLAogICBvciA0ODAwMC4KCiAtIGBtcDNgCgogICBNUDMgYXVk
aW8uIFN1cHBvcnQgYWxsIHN0YW5kYXJkIE1QMyBiaXRyYXRlcyAod2hpY2ggcmFuZ2UgZnJv
bSAzMi0zMjAKICAga2JwcykuIFdoZW4gdXNpbmcgdGhpcyBlbmNvZGluZywgYHNhbXBsZV9y
YXRlX2hlcnR6YCBoYXMgdG8gbWF0Y2ggdGhlCiAgIHNhbXBsZSByYXRlIG9mIHRoZSBmaWxl
IGJlaW5nIHVzZWQuCgoMCgUEAAIABRIDUQIICgwKBQQAAgABEgNRCRcKDAoFBAACAAMSA1Ea
GwoMCgUEAAIACBIDURxECg8KCAQAAgAInAgAEgNRHUMKSgoEBAACARIDVAJLGj0gUmVxdWly
ZWQuIFNvdXJjZSBsYW5ndWFnZSBjb2RlIChCQ1AtNDcpIG9mIHRoZSBpbnB1dCBhdWRpby4K
CgwKBQQAAgEFEgNUAggKDAoFBAACAQESA1QJHQoMCgUEAAIBAxIDVCAhCgwKBQQAAgEIEgNU
IkoKDwoIBAACAQicCAASA1QjSQpFCgQEAAICEgNXAksaOCBSZXF1aXJlZC4gVGFyZ2V0IGxh
bmd1YWdlIGNvZGUgKEJDUC00Nykgb2YgdGhlIG91dHB1dC4KCgwKBQQAAgIFEgNXAggKDAoF
BAACAgESA1cJHQoMCgUEAAICAxIDVyAhCgwKBQQAAgIIEgNXIkoKDwoIBAACAgicCAASA1cj
SQqeAgoEBAACAxIDXQJHGpACIE9wdGlvbmFsLiBTYW1wbGUgcmF0ZSBpbiBIZXJ0eiBvZiB0
aGUgYXVkaW8gZGF0YS4gVmFsaWQgdmFsdWVzIGFyZToKIDgwMDAtNDgwMDAuIDE2MDAwIGlz
IG9wdGltYWwuIEZvciBiZXN0IHJlc3VsdHMsIHNldCB0aGUgc2FtcGxpbmcgcmF0ZSBvZgog
dGhlIGF1ZGlvIHNvdXJjZSB0byAxNjAwMCBIei4gSWYgdGhhdCdzIG5vdCBwb3NzaWJsZSwg
dXNlIHRoZSBuYXRpdmUgc2FtcGxlCiByYXRlIG9mIHRoZSBhdWRpbyBzb3VyY2UgKGluc3Rl
YWQgb2YgcmUtc2FtcGxpbmcpLgoKDAoFBAACAwUSA10CBwoMCgUEAAIDARIDXQgZCgwKBQQA
AgMDEgNdHB0KDAoFBAACAwgSA10eRgoPCggEAAIDCJwIABIDXR9FCrYBCgQEAAIEEgNiAjwa
qAEgT3B0aW9uYWwuIGBnb29nbGUtcHJvdmlkZWQtbW9kZWwvdmlkZW9gIGFuZAogYGdvb2ds
ZS1wcm92aWRlZC1tb2RlbC9lbmhhbmNlZC1waG9uZS1jYWxsYCBhcmUgcHJlbWl1bSBtb2Rl
bHMuCiBgZ29vZ2xlLXByb3ZpZGVkLW1vZGVsL3Bob25lLWNhbGxgIGlzIG5vdCBwcmVtaXVt
IG1vZGVsLgoKDAoFBAACBAUSA2ICCAoMCgUEAAIEARIDYgkOCgwKBQQAAgQDEgNiERIKDAoF
BAACBAgSA2ITOwoPCggEAAIECJwIABIDYhQ6CjQKAgQBEgRmAHkBGiggQ29uZmlnIHVzZWQg
Zm9yIHN0cmVhbWluZyB0cmFuc2xhdGlvbi4KCgoKAwQBARIDZggmClAKBAQBAgASA2gCUhpD
IFJlcXVpcmVkLiBUaGUgY29tbW9uIGNvbmZpZyBmb3IgYWxsIHRoZSBmb2xsb3dpbmcgYXVk
aW8gY29udGVudHMuCgoMCgUEAQIABhIDaAIXCgwKBQQBAgABEgNoGCQKDAoFBAECAAMSA2gn
KAoMCgUEAQIACBIDaClRCg8KCAQBAgAInAgAEgNoKlAKuwcKBAQBAgESA3gCRRqtByBPcHRp
b25hbC4gSWYgYGZhbHNlYCBvciBvbWl0dGVkLCB0aGUgc3lzdGVtIHBlcmZvcm1zCiBjb250
aW51b3VzIHRyYW5zbGF0aW9uIChjb250aW51aW5nIHRvIHdhaXQgZm9yIGFuZCBwcm9jZXNz
IGF1ZGlvIGV2ZW4gaWYKIHRoZSB1c2VyIHBhdXNlcyBzcGVha2luZykgdW50aWwgdGhlIGNs
aWVudCBjbG9zZXMgdGhlIGlucHV0IHN0cmVhbSAoZ1JQQwogQVBJKSBvciB1bnRpbCB0aGUg
bWF4aW11bSB0aW1lIGxpbWl0IGhhcyBiZWVuIHJlYWNoZWQuIE1heSByZXR1cm4gbXVsdGlw
bGUKIGBTdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hSZXN1bHRgcyB3aXRoIHRoZSBgaXNfZmlu
YWxgIGZsYWcgc2V0IHRvIGB0cnVlYC4KCiBJZiBgdHJ1ZWAsIHRoZSBzcGVlY2ggdHJhbnNs
YXRvciB3aWxsIGRldGVjdCBhIHNpbmdsZSBzcG9rZW4gdXR0ZXJhbmNlLgogV2hlbiBpdCBk
ZXRlY3RzIHRoYXQgdGhlIHVzZXIgaGFzIHBhdXNlZCBvciBzdG9wcGVkIHNwZWFraW5nLCBp
dCB3aWxsCiByZXR1cm4gYW4gYEVORF9PRl9TSU5HTEVfVVRURVJBTkNFYCBldmVudCBhbmQg
Y2Vhc2UgdHJhbnNsYXRpb24uCiBXaGVuIHRoZSBjbGllbnQgcmVjZWl2ZXMgJ0VORF9PRl9T
SU5HTEVfVVRURVJBTkNFJyBldmVudCwgdGhlIGNsaWVudCBzaG91bGQKIHN0b3Agc2VuZGlu
ZyB0aGUgcmVxdWVzdHMuIEhvd2V2ZXIsIGNsaWVudHMgc2hvdWxkIGtlZXAgcmVjZWl2aW5n
IHJlbWFpbmluZwogcmVzcG9uc2VzIHVudGlsIHRoZSBzdHJlYW0gaXMgdGVybWluYXRlZC4g
VG8gY29uc3RydWN0IHRoZSBjb21wbGV0ZQogc2VudGVuY2UgaW4gYSBzdHJlYW1pbmcgd2F5
LCBvbmUgc2hvdWxkIG92ZXJyaWRlIChpZiAnaXNfZmluYWwnIG9mIHByZXZpb3VzCiByZXNw
b25zZSBpcyBmYWxzZSksIG9yIGFwcGVuZCAoaWYgJ2lzX2ZpbmFsJyBvZiBwcmV2aW91cyBy
ZXNwb25zZSBpcyB0cnVlKS4KCgwKBQQBAgEFEgN4AgYKDAoFBAECAQESA3gHFwoMCgUEAQIB
AxIDeBobCgwKBQQBAgEIEgN4HEQKDwoIBAECAQicCAASA3gdQwr6AgoCBAISBoABAJIBARrr
AiBUaGUgdG9wLWxldmVsIG1lc3NhZ2Ugc2VudCBieSB0aGUgY2xpZW50IGZvciB0aGUgYFN0
cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaGAKIG1ldGhvZC4gTXVsdGlwbGUgYFN0cmVhbWluZ1Ry
YW5zbGF0ZVNwZWVjaFJlcXVlc3RgIG1lc3NhZ2VzIGFyZSBzZW50LiBUaGUKIGZpcnN0IG1l
c3NhZ2UgbXVzdCBjb250YWluIGEgYHN0cmVhbWluZ19jb25maWdgIG1lc3NhZ2UgYW5kIG11
c3Qgbm90IGNvbnRhaW4KIGBhdWRpb19jb250ZW50YCBkYXRhLiBBbGwgc3Vic2VxdWVudCBt
ZXNzYWdlcyBtdXN0IGNvbnRhaW4gYGF1ZGlvX2NvbnRlbnRgCiBkYXRhIGFuZCBtdXN0IG5v
dCBjb250YWluIGEgYHN0cmVhbWluZ19jb25maWdgIG1lc3NhZ2UuCgoLCgMEAgESBIABCCcK
VwoEBAIIABIGggECkQEDGkcgVGhlIHN0cmVhbWluZyByZXF1ZXN0LCB3aGljaCBpcyBlaXRo
ZXIgYSBzdHJlYW1pbmcgY29uZmlnIG9yIGNvbnRlbnQuCgoNCgUEAggAARIEggEIGQrDAQoE
BAICABIEhgEEOBq0ASBQcm92aWRlcyBpbmZvcm1hdGlvbiB0byB0aGUgcmVjb2duaXplciB0
aGF0IHNwZWNpZmllcyBob3cgdG8gcHJvY2VzcyB0aGUKIHJlcXVlc3QuIFRoZSBmaXJzdCBg
U3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVxdWVzdGAgbWVzc2FnZSBtdXN0IGNvbnRhaW4K
IGEgYHN0cmVhbWluZ19jb25maWdgIG1lc3NhZ2UuCgoNCgUEAgIABhIEhgEEIgoNCgUEAgIA
ARIEhgEjMwoNCgUEAgIAAxIEhgE2NwqEBAoEBAICARIEkAEEHBr1AyBUaGUgYXVkaW8gZGF0
YSB0byBiZSB0cmFuc2xhdGVkLiBTZXF1ZW50aWFsIGNodW5rcyBvZiBhdWRpbyBkYXRhIGFy
ZSBzZW50CiBpbiBzZXF1ZW50aWFsIGBTdHJlYW1pbmdUcmFuc2xhdGVTcGVlY2hSZXF1ZXN0
YCBtZXNzYWdlcy4gVGhlIGZpcnN0CiBgU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVxdWVz
dGAgbWVzc2FnZSBtdXN0IG5vdCBjb250YWluCiBgYXVkaW9fY29udGVudGAgZGF0YSBhbmQg
YWxsIHN1YnNlcXVlbnQgYFN0cmVhbWluZ1RyYW5zbGF0ZVNwZWVjaFJlcXVlc3RgCiBtZXNz
YWdlcyBtdXN0IGNvbnRhaW4gYGF1ZGlvX2NvbnRlbnRgIGRhdGEuIFRoZSBhdWRpbyBieXRl
cyBtdXN0IGJlCiBlbmNvZGVkIGFzIHNwZWNpZmllZCBpbiBgU3RyZWFtaW5nVHJhbnNsYXRl
U3BlZWNoQ29uZmlnYC4gTm90ZTogYXMgd2l0aAogYWxsIGJ5dGVzIGZpZWxkcywgcHJvdG9i
dWZmZXJzIHVzZSBhIHB1cmUgYmluYXJ5IHJlcHJlc2VudGF0aW9uIChub3QKIGJhc2U2NCku
CgoNCgUEAgIBBRIEkAEECQoNCgUEAgIBARIEkAEKFwoNCgUEAgIBAxIEkAEaGwqBAQoCBAMS
BpYBAKoBARpzIEEgc3RyZWFtaW5nIHNwZWVjaCB0cmFuc2xhdGlvbiByZXN1bHQgY29ycmVz
cG9uZGluZyB0byBhIHBvcnRpb24gb2YgdGhlIGF1ZGlvCiB0aGF0IGlzIGN1cnJlbnRseSBi
ZWluZyBwcm9jZXNzZWQuCgoLCgMEAwESBJYBCCYKKgoEBAMDABIGmAECowEDGhogVGV4dCB0
cmFuc2xhdGlvbiByZXN1bHQuCgoNCgUEAwMAARIEmAEKHwo3CgYEAwMAAgASBJoBBEcaJyBP
dXRwdXQgb25seS4gVGhlIHRyYW5zbGF0ZWQgc2VudGVuY2UuCgoPCgcEAwMAAgAFEgSaAQQK
Cg8KBwQDAwACAAESBJoBCxYKDwoHBAMDAAIAAxIEmgEZGgoPCgcEAwMAAgAIEgSaARtGChIK
CgQDAwACAAicCAASBJoBHEUK+AIKBgQDAwACARIEogEEQhrnAiBPdXRwdXQgb25seS4gSWYg
YGZhbHNlYCwgdGhpcyBgU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVzdWx0YCByZXByZXNl
bnRzCiBhbiBpbnRlcmltIHJlc3VsdCB0aGF0IG1heSBjaGFuZ2UuIElmIGB0cnVlYCwgdGhp
cyBpcyB0aGUgZmluYWwgdGltZSB0aGUKIHRyYW5zbGF0aW9uIHNlcnZpY2Ugd2lsbCByZXR1
cm4gdGhpcyBwYXJ0aWN1bGFyCiBgU3RyZWFtaW5nVHJhbnNsYXRlU3BlZWNoUmVzdWx0YCwg
dGhlIHN0cmVhbWluZyB0cmFuc2xhdG9yIHdpbGwgbm90CiByZXR1cm4gYW55IGZ1cnRoZXIg
aHlwb3RoZXNlcyBmb3IgdGhpcyBwb3J0aW9uIG9mIHRoZSB0cmFuc2NyaXB0IGFuZAogY29y
cmVzcG9uZGluZyBhdWRpby4KCg8KBwQDAwACAQUSBKIBBAgKDwoHBAMDAAIBARIEogEJEQoP
CgcEAwMAAgEDEgSiARQVCg8KBwQDAwACAQgSBKIBFkEKEgoKBAMDAAIBCJwIABIEogEXQAol
CgQEAwgAEgamAQKpAQMaFSBUcmFuc2xhdGlvbiByZXN1bHQuCgoNCgUEAwgAARIEpgEIDgoo
CgQEAwIAEgSoAQQ2GhogVGV4dCB0cmFuc2xhdGlvbiByZXN1bHQuCgoNCgUEAwIABhIEqAEE
GQoNCgUEAwIAARIEqAEaMQoNCgUEAwIAAxIEqAE0NQp1CgIEBBIGrgEAywEBGmcgQSBzdHJl
YW1pbmcgc3BlZWNoIHRyYW5zbGF0aW9uIHJlc3BvbnNlIGNvcnJlc3BvbmRpbmcgdG8gYSBw
b3J0aW9uIG9mCiB0aGUgYXVkaW8gY3VycmVudGx5IHByb2Nlc3NlZC4KCgsKAwQEARIErgEI
KAo1CgQEBAQAEgawAQK/AQMaJSBJbmRpY2F0ZXMgdGhlIHR5cGUgb2Ygc3BlZWNoIGV2ZW50
LgoKDQoFBAQEAAESBLABBxYKLAoGBAQEAAIAEgSyAQQmGhwgTm8gc3BlZWNoIGV2ZW50IHNw
ZWNpZmllZC4KCg8KBwQEBAACAAESBLIBBCEKDwoHBAQEAAIAAhIEsgEkJQrYBQoGBAQEAAIB
EgS+AQQgGscFIFRoaXMgZXZlbnQgaW5kaWNhdGVzIHRoYXQgdGhlIHNlcnZlciBoYXMgZGV0
ZWN0ZWQgdGhlIGVuZCBvZiB0aGUgdXNlcidzCiBzcGVlY2ggdXR0ZXJhbmNlIGFuZCBleHBl
Y3RzIG5vIGFkZGl0aW9uYWwgc3BlZWNoLiBUaGVyZWZvcmUsIHRoZSBzZXJ2ZXIKIHdpbGwg
bm90IHByb2Nlc3MgYWRkaXRpb25hbCBhdWRpbyAoYWx0aG91Z2ggaXQgbWF5IHN1YnNlcXVl
bnRseSByZXR1cm4KIGFkZGl0aW9uYWwgcmVzdWx0cykuIFdoZW4gdGhlIGNsaWVudCByZWNl
aXZlcyAnRU5EX09GX1NJTkdMRV9VVFRFUkFOQ0UnCiBldmVudCwgdGhlIGNsaWVudCBzaG91
bGQgc3RvcCBzZW5kaW5nIHRoZSByZXF1ZXN0cy4gSG93ZXZlciwgY2xpZW50cwogc2hvdWxk
IGtlZXAgcmVjZWl2aW5nIHJlbWFpbmluZyByZXNwb25zZXMgdW50aWwgdGhlIHN0cmVhbSBp
cyB0ZXJtaW5hdGVkLgogVG8gY29uc3RydWN0IHRoZSBjb21wbGV0ZSBzZW50ZW5jZSBpbiBh
IHN0cmVhbWluZyB3YXksIG9uZSBzaG91bGQKIG92ZXJyaWRlIChpZiAnaXNfZmluYWwnIG9m
IHByZXZpb3VzIHJlc3BvbnNlIGlzIGZhbHNlKSwgb3IgYXBwZW5kIChpZgogJ2lzX2ZpbmFs
JyBvZiBwcmV2aW91cyByZXNwb25zZSBpcyB0cnVlKS4gVGhpcyBldmVudCBpcyBvbmx5IHNl
bnQgaWYKIGBzaW5nbGVfdXR0ZXJhbmNlYCB3YXMgc2V0IHRvIGB0cnVlYCwgYW5kIGlzIG5v
dCB1c2VkIG90aGVyd2lzZS4KCg8KBwQEBAACAQESBL4BBBsKDwoHBAQEAAIBAhIEvgEeHwqK
AQoEBAQCABIEwwECShp8IE91dHB1dCBvbmx5LiBJZiBzZXQsIHJldHVybnMgYSBbZ29vZ2xl
LnJwYy5TdGF0dXNdW2dvb2dsZS5ycGMuU3RhdHVzXSBtZXNzYWdlIHRoYXQKIHNwZWNpZmll
cyB0aGUgZXJyb3IgZm9yIHRoZSBvcGVyYXRpb24uCgoNCgUEBAIABhIEwwECEwoNCgUEBAIA
ARIEwwEUGQoNCgUEBAIAAxIEwwEcHQoNCgUEBAIACBIEwwEeSQoQCggEBAIACJwIABIEwwEf
SAp5CgQEBAIBEgTHAQJYGmsgT3V0cHV0IG9ubHkuIFRoZSB0cmFuc2xhdGlvbiByZXN1bHQg
dGhhdCBpcyBjdXJyZW50bHkgYmVpbmcgcHJvY2Vzc2VkIChpc19maW5hbCBjb3VsZCBiZQog
dHJ1ZSBvciBmYWxzZSkuCgoNCgUEBAIBBhIExwECIAoNCgUEBAIBARIExwEhJwoNCgUEBAIB
AxIExwEqKwoNCgUEBAIBCBIExwEsVwoQCggEBAIBCJwIABIExwEtVgpACgQEBAICEgTKAQJU
GjIgT3V0cHV0IG9ubHkuIEluZGljYXRlcyB0aGUgdHlwZSBvZiBzcGVlY2ggZXZlbnQuCgoN
CgUEBAICBhIEygECEQoNCgUEBAICARIEygESIwoNCgUEBAICAxIEygEmJwoNCgUEBAICCBIE
ygEoUwoQCggEBAICCJwIABIEygEpUmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig ===
    # Fields for TranslateSpeechConfig
    # Field: audio_encoding Type: 9 ()
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()
    # Field: sample_rate_hertz Type: 5 ()
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig ===
    # Fields for StreamingTranslateSpeechConfig
    # Field: audio_config Type: 11 (.google.cloud.mediatranslation.v1beta1.TranslateSpeechConfig)
    # Field: single_utterance Type: 8 ()

# === Message: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest ===
    # Fields for StreamingTranslateSpeechRequest
    # Field: streaming_config Type: 11 (.google.cloud.mediatranslation.v1beta1.StreamingTranslateSpeechConfig)
    # Field: audio_content Type: 12 ()

# === Message: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult ===
    # Fields for StreamingTranslateSpeechResult
    # Field: text_translation_result Type: 11 (.google.cloud.mediatranslation.v1beta1.StreamingTranslateSpeechResult.TextTranslationResult)

# === Message: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse ===
    # Fields for StreamingTranslateSpeechResponse
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: result Type: 11 (.google.cloud.mediatranslation.v1beta1.StreamingTranslateSpeechResult)
    # Field: speech_event_type Type: 14 (.google.cloud.mediatranslation.v1beta1.StreamingTranslateSpeechResponse.SpeechEventType)

# Enum: StreamingTranslateSpeechResponse::SpeechEventType
our $StreamingTranslateSpeechResponse_SPEECH_EVENT_TYPE_UNSPECIFIED = 0;
our $StreamingTranslateSpeechResponse_END_OF_SINGLE_UTTERANCE = 1;

# === Service Client: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::SpeechTranslationServiceClient ===
package Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::SpeechTranslationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::SpeechTranslationServiceClient

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
        ? Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.mediatranslation.v1beta1.SpeechTranslationService',
        method         => 'StreamingTranslateSpeech',
        request        => $req,
        response_class => 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Mediatranslation::V1beta1::MediaTranslation - Compiled Protocol Buffers messages for google/cloud/mediatranslation/v1beta1/media_translation.proto

=head1 SYNOPSIS

    use Google::Cloud::Mediatranslation::V1beta1::MediaTranslation;

    my $msg = Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig->new({
        audio_encoding => $audio_encoding,
        source_language_code => $source_language_code,
        target_language_code => $target_language_code,
        sample_rate_hertz => $sample_rate_hertz,
    });

    # Read or update a field
    my $val = $msg->audio_encoding();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/mediatranslation/v1beta1/media_translation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig

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

  Opus encoded audio frames in [Ogg](https://wikipedia.org/wiki/Ogg)
  container. `sample_rate_hertz` must be one of 8000, 12000, 16000, 24000,
  or 48000.

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

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. Sample rate in Hertz of the audio data. Valid values are:
8000-48000. 16000 is optimal. For best results, set the sampling rate of
the audio source to 16000 Hz. If that's not possible, use the native sample
rate of the audio source (instead of re-sampling).

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Optional. `google-provided-model/video` and
`google-provided-model/enhanced-phone-call` are premium models.
`google-provided-model/phone-call` is not premium model.

=back

=head2 Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig

Config used for streaming translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_config() >> / C<< $msg->audio_config($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig>)

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
When the client receives 'END_OF_SINGLE_UTTERANCE' event, the client should
stop sending the requests. However, clients should keep receiving remaining
responses until the stream is terminated. To construct the complete
sentence in a streaming way, one should override (if 'is_final' of previous
response is false), or append (if 'is_final' of previous response is true).

=back

=head2 Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest

The top-level message sent by the client for the `StreamingTranslateSpeech`
method. Multiple `StreamingTranslateSpeechRequest` messages are sent. The
first message must contain a `streaming_config` message and must not contain
`audio_content` data. All subsequent messages must contain `audio_content`
data and must not contain a `streaming_config` message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streaming_config() >> / C<< $msg->streaming_config($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig>)

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

=head2 Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult

A streaming speech translation result corresponding to a portion of the audio
that is currently being processed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_translation_result() >> / C<< $msg->text_translation_result($value) >>

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult::TextTranslationResult>)

Text translation result.

=back

=head2 Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse

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

Type: C<Message> (L<Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult>)

Output only. The translation result that is currently being processed (is_final could be
true or false).

=item * C<< $msg->speech_event_type() >> / C<< $msg->speech_event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Mediatranslation::V1beta1::StreamingTranslateSpeechResponse::SpeechEventType>)

Output only. Indicates the type of speech event.

=back

=head3 Enum: StreamingTranslateSpeechResponse::SpeechEventType

=over 4

=item * C<SPEECH_EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<END_OF_SINGLE_UTTERANCE> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
