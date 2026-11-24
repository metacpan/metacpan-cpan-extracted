package Google::Appengine::V1beta::AppYaml;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9hcHBfeWFtbC5wcm90bxIXZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGEaHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byKfAgoQQXBpQ29u
ZmlnSGFuZGxlchJRChBhdXRoX2ZhaWxfYWN0aW9uGAEgASgOMicuZ29vZ2xlLmFwcGVuZ2lu
ZS52MWJldGEuQXV0aEZhaWxBY3Rpb25SDmF1dGhGYWlsQWN0aW9uEj8KBWxvZ2luGAIgASgO
MikuZ29vZ2xlLmFwcGVuZ2luZS52MWJldGEuTG9naW5SZXF1aXJlbWVudFIFbG9naW4SFgoG
c2NyaXB0GAMgASgJUgZzY3JpcHQSTQoOc2VjdXJpdHlfbGV2ZWwYBCABKA4yJi5nb29nbGUu
YXBwZW5naW5lLnYxYmV0YS5TZWN1cml0eUxldmVsUg1zZWN1cml0eUxldmVsEhAKA3VybBgF
IAEoCVIDdXJsIrQCCgxFcnJvckhhbmRsZXISTgoKZXJyb3JfY29kZRgBIAEoDjIvLmdvb2ds
ZS5hcHBlbmdpbmUudjFiZXRhLkVycm9ySGFuZGxlci5FcnJvckNvZGVSCWVycm9yQ29kZRIf
CgtzdGF0aWNfZmlsZRgCIAEoCVIKc3RhdGljRmlsZRIbCgltaW1lX3R5cGUYAyABKAlSCG1p
bWVUeXBlIpUBCglFcnJvckNvZGUSGgoWRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEhYKEkVS
Uk9SX0NPREVfREVGQVVMVBAAEhkKFUVSUk9SX0NPREVfT1ZFUl9RVU9UQRABEh0KGUVSUk9S
X0NPREVfRE9TX0FQSV9ERU5JQUwQAhIWChJFUlJPUl9DT0RFX1RJTUVPVVQQAxoCEAEi1QYK
BlVybE1hcBIbCgl1cmxfcmVnZXgYASABKAlSCHVybFJlZ2V4ElAKDHN0YXRpY19maWxlcxgC
IAEoCzIrLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLlN0YXRpY0ZpbGVzSGFuZGxlckgAUgtz
dGF0aWNGaWxlcxJACgZzY3JpcHQYAyABKAsyJi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5T
Y3JpcHRIYW5kbGVySABSBnNjcmlwdBJQCgxhcGlfZW5kcG9pbnQYBCABKAsyKy5nb29nbGUu
YXBwZW5naW5lLnYxYmV0YS5BcGlFbmRwb2ludEhhbmRsZXJIAFILYXBpRW5kcG9pbnQSTQoO
c2VjdXJpdHlfbGV2ZWwYBSABKA4yJi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5TZWN1cml0
eUxldmVsUg1zZWN1cml0eUxldmVsEj8KBWxvZ2luGAYgASgOMikuZ29vZ2xlLmFwcGVuZ2lu
ZS52MWJldGEuTG9naW5SZXF1aXJlbWVudFIFbG9naW4SUQoQYXV0aF9mYWlsX2FjdGlvbhgH
IAEoDjInLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLkF1dGhGYWlsQWN0aW9uUg5hdXRoRmFp
bEFjdGlvbhJ3ChtyZWRpcmVjdF9odHRwX3Jlc3BvbnNlX2NvZGUYCCABKA4yOC5nb29nbGUu
YXBwZW5naW5lLnYxYmV0YS5VcmxNYXAuUmVkaXJlY3RIdHRwUmVzcG9uc2VDb2RlUhhyZWRp
cmVjdEh0dHBSZXNwb25zZUNvZGUi2wEKGFJlZGlyZWN0SHR0cFJlc3BvbnNlQ29kZRIrCidS
RURJUkVDVF9IVFRQX1JFU1BPTlNFX0NPREVfVU5TUEVDSUZJRUQQABIjCh9SRURJUkVDVF9I
VFRQX1JFU1BPTlNFX0NPREVfMzAxEAESIwofUkVESVJFQ1RfSFRUUF9SRVNQT05TRV9DT0RF
XzMwMhACEiMKH1JFRElSRUNUX0hUVFBfUkVTUE9OU0VfQ09ERV8zMDMQAxIjCh9SRURJUkVD
VF9IVFRQX1JFU1BPTlNFX0NPREVfMzA3EARCDgoMaGFuZGxlcl90eXBlIrQDChJTdGF0aWNG
aWxlc0hhbmRsZXISEgoEcGF0aBgBIAEoCVIEcGF0aBIqChF1cGxvYWRfcGF0aF9yZWdleBgC
IAEoCVIPdXBsb2FkUGF0aFJlZ2V4El8KDGh0dHBfaGVhZGVycxgDIAMoCzI8Lmdvb2dsZS5h
cHBlbmdpbmUudjFiZXRhLlN0YXRpY0ZpbGVzSGFuZGxlci5IdHRwSGVhZGVyc0VudHJ5Ugto
dHRwSGVhZGVycxIbCgltaW1lX3R5cGUYBCABKAlSCG1pbWVUeXBlEjkKCmV4cGlyYXRpb24Y
BSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCmV4cGlyYXRpb24SMgoVcmVxdWly
ZV9tYXRjaGluZ19maWxlGAYgASgIUhNyZXF1aXJlTWF0Y2hpbmdGaWxlEjEKFGFwcGxpY2F0
aW9uX3JlYWRhYmxlGAcgASgIUhNhcHBsaWNhdGlvblJlYWRhYmxlGj4KEEh0dHBIZWFkZXJz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASIwCg1T
Y3JpcHRIYW5kbGVyEh8KC3NjcmlwdF9wYXRoGAEgASgJUgpzY3JpcHRQYXRoIjUKEkFwaUVu
ZHBvaW50SGFuZGxlchIfCgtzY3JpcHRfcGF0aBgBIAEoCVIKc2NyaXB0UGF0aCLVAgoLSGVh
bHRoQ2hlY2sSMAoUZGlzYWJsZV9oZWFsdGhfY2hlY2sYASABKAhSEmRpc2FibGVIZWFsdGhD
aGVjaxISCgRob3N0GAIgASgJUgRob3N0EisKEWhlYWx0aHlfdGhyZXNob2xkGAMgASgNUhBo
ZWFsdGh5VGhyZXNob2xkEi8KE3VuaGVhbHRoeV90aHJlc2hvbGQYBCABKA1SEnVuaGVhbHRo
eVRocmVzaG9sZBIrChFyZXN0YXJ0X3RocmVzaG9sZBgFIAEoDVIQcmVzdGFydFRocmVzaG9s
ZBJACg5jaGVja19pbnRlcnZhbBgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIN
Y2hlY2tJbnRlcnZhbBIzCgd0aW1lb3V0GAcgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0
aW9uUgd0aW1lb3V0ItACCg5SZWFkaW5lc3NDaGVjaxISCgRwYXRoGAEgASgJUgRwYXRoEhIK
BGhvc3QYAiABKAlSBGhvc3QSKwoRZmFpbHVyZV90aHJlc2hvbGQYAyABKA1SEGZhaWx1cmVU
aHJlc2hvbGQSKwoRc3VjY2Vzc190aHJlc2hvbGQYBCABKA1SEHN1Y2Nlc3NUaHJlc2hvbGQS
QAoOY2hlY2tfaW50ZXJ2YWwYBSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SDWNo
ZWNrSW50ZXJ2YWwSMwoHdGltZW91dBgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
blIHdGltZW91dBJFChFhcHBfc3RhcnRfdGltZW91dBgHIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblIPYXBwU3RhcnRUaW1lb3V0IsgCCg1MaXZlbmVzc0NoZWNrEhIKBHBhdGgY
ASABKAlSBHBhdGgSEgoEaG9zdBgCIAEoCVIEaG9zdBIrChFmYWlsdXJlX3RocmVzaG9sZBgD
IAEoDVIQZmFpbHVyZVRocmVzaG9sZBIrChFzdWNjZXNzX3RocmVzaG9sZBgEIAEoDVIQc3Vj
Y2Vzc1RocmVzaG9sZBJACg5jaGVja19pbnRlcnZhbBgFIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblINY2hlY2tJbnRlcnZhbBIzCgd0aW1lb3V0GAYgASgLMhkuZ29vZ2xlLnBy
b3RvYnVmLkR1cmF0aW9uUgd0aW1lb3V0Ej4KDWluaXRpYWxfZGVsYXkYByABKAsyGS5nb29n
bGUucHJvdG9idWYuRHVyYXRpb25SDGluaXRpYWxEZWxheSI3CgdMaWJyYXJ5EhIKBG5hbWUY
ASABKAlSBG5hbWUSGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2lvbip0Cg5BdXRoRmFpbEFjdGlv
bhIgChxBVVRIX0ZBSUxfQUNUSU9OX1VOU1BFQ0lGSUVEEAASHQoZQVVUSF9GQUlMX0FDVElP
Tl9SRURJUkVDVBABEiEKHUFVVEhfRkFJTF9BQ1RJT05fVU5BVVRIT1JJWkVEEAIqYgoQTG9n
aW5SZXF1aXJlbWVudBIVChFMT0dJTl9VTlNQRUNJRklFRBAAEhIKDkxPR0lOX09QVElPTkFM
EAESDwoLTE9HSU5fQURNSU4QAhISCg5MT0dJTl9SRVFVSVJFRBADKnkKDVNlY3VyaXR5TGV2
ZWwSFgoSU0VDVVJFX1VOU1BFQ0lGSUVEEAASEgoOU0VDVVJFX0RFRkFVTFQQABIQCgxTRUNV
UkVfTkVWRVIQARITCg9TRUNVUkVfT1BUSU9OQUwQAhIRCg1TRUNVUkVfQUxXQVlTEAMaAhAB
QtIBChtjb20uZ29vZ2xlLmFwcGVuZ2luZS52MWJldGFCDEFwcFlhbWxQcm90b1ABWkBnb29n
bGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FwcGVuZ2luZS92MWJldGE7YXBw
ZW5naW5lqgIdR29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMUJldGHKAh1Hb29nbGVcQ2xvdWRc
QXBwRW5naW5lXFYxYmV0YeoCIEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFiZXRhSoxh
CgcSBQ4A2wIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAg
CgkKAgMAEgMSACgKCAoBCBIDFAA6CgkKAgglEgMUADoKCAoBCBIDFQBXCgkKAggLEgMVAFcK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAtCgkKAggIEgMXAC0KCAoBCBIDGAA0CgkK
AggBEgMYADQKCAoBCBIDGQA6CgkKAggpEgMZADoKCAoBCBIDGgA5CgkKAggtEgMaADkKggEK
AgQAEgQeAC8BGnYgW0dvb2dsZSBDbG91ZCBFbmRwb2ludHNdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9weXRob24vZW5kcG9pbnRzLykKIGNvbmZpZ3VyYXRp
b24gZm9yIEFQSSBoYW5kbGVycy4KCgoKAwQAARIDHggYCm8KBAQAAgASAyECJhpiIEFjdGlv
biB0byB0YWtlIHdoZW4gdXNlcnMgYWNjZXNzIHJlc291cmNlcyB0aGF0IHJlcXVpcmUKIGF1
dGhlbnRpY2F0aW9uLiBEZWZhdWx0cyB0byBgcmVkaXJlY3RgLgoKDAoFBAACAAYSAyECEAoM
CgUEAAIAARIDIREhCgwKBQQAAgADEgMhJCUKWAoEBAACARIDJQIdGksgTGV2ZWwgb2YgbG9n
aW4gcmVxdWlyZWQgdG8gYWNjZXNzIHRoaXMgcmVzb3VyY2UuIERlZmF1bHRzIHRvCiBgb3B0
aW9uYWxgLgoKDAoFBAACAQYSAyUCEgoMCgUEAAIBARIDJRMYCgwKBQQAAgEDEgMlGxwKRgoE
BAACAhIDKAIUGjkgUGF0aCB0byB0aGUgc2NyaXB0IGZyb20gdGhlIGFwcGxpY2F0aW9uIHJv
b3QgZGlyZWN0b3J5LgoKDAoFBAACAgUSAygCCAoMCgUEAAICARIDKAkPCgwKBQQAAgIDEgMo
EhMKOQoEBAACAxIDKwIjGiwgU2VjdXJpdHkgKEhUVFBTKSBlbmZvcmNlbWVudCBmb3IgdGhp
cyBVUkwuCgoMCgUEAAIDBhIDKwIPCgwKBQQAAgMBEgMrEB4KDAoFBAACAwMSAyshIgosCgQE
AAIEEgMuAhEaHyBVUkwgdG8gc2VydmUgdGhlIGVuZHBvaW50IGF0LgoKDAoFBAACBAUSAy4C
CAoMCgUEAAIEARIDLgkMCgwKBQQAAgQDEgMuDxAKSQoCBAESBDIAUAEaPSBDdXN0b20gc3Rh
dGljIGVycm9yIHBhZ2UgdG8gYmUgc2VydmVkIHdoZW4gYW4gZXJyb3Igb2NjdXJzLgoKCgoD
BAEBEgMyCBQKHAoEBAEEABIENAJGAxoOIEVycm9yIGNvZGVzLgoKDAoFBAEEAAESAzQHEAoM
CgUEAQQAAxIDNQQeCg0KBgQBBAADAhIDNQQeCj4KBgQBBAACABIDOAQfGi8gTm90IHNwZWNp
ZmllZC4gRVJST1JfQ09ERV9ERUZBVUxUIGlzIGFzc3VtZWQuCgoOCgcEAQQAAgABEgM4BBoK
DgoHBAEEAAIAAhIDOB0eCicKBgQBBAACARIDOwQbGhggQWxsIG90aGVyIGVycm9yIHR5cGVz
LgoKDgoHBAEEAAIBARIDOwQWCg4KBwQBBAACAQISAzsZGgo7CgYEAQQAAgISAz4EHhosIEFw
cGxpY2F0aW9uIGhhcyBleGNlZWRlZCBhIHJlc291cmNlIHF1b3RhLgoKDgoHBAEEAAICARID
PgQZCg4KBwQBBAACAgISAz4cHQphCgYEAQQAAgMSA0IEIhpSIENsaWVudCBibG9ja2VkIGJ5
IHRoZSBhcHBsaWNhdGlvbidzIERlbmlhbCBvZiBTZXJ2aWNlIHByb3RlY3Rpb24KIGNvbmZp
Z3VyYXRpb24uCgoOCgcEAQQAAgMBEgNCBB0KDgoHBAEEAAIDAhIDQiAhCkIKBgQBBAACBBID
RQQbGjMgRGVhZGxpbmUgcmVhY2hlZCBiZWZvcmUgdGhlIGFwcGxpY2F0aW9uIHJlc3BvbmRz
LgoKDgoHBAEEAAIEARIDRQQWCg4KBwQBBAACBAISA0UZGgo3CgQEAQIAEgNJAhsaKiBFcnJv
ciBjb25kaXRpb24gdGhpcyBoYW5kbGVyIGFwcGxpZXMgdG8uCgoMCgUEAQIABhIDSQILCgwK
BQQBAgABEgNJDBYKDAoFBAECAAMSA0kZGgo/CgQEAQIBEgNMAhkaMiBTdGF0aWMgZmlsZSBj
b250ZW50IHRvIGJlIHNlcnZlZCBmb3IgdGhpcyBlcnJvci4KCgwKBQQBAgEFEgNMAggKDAoF
BAECAQESA0wJFAoMCgUEAQIBAxIDTBcYCjoKBAQBAgISA08CFxotIE1JTUUgdHlwZSBvZiBm
aWxlLiBEZWZhdWx0cyB0byBgdGV4dC9odG1sYC4KCgwKBQQBAgIFEgNPAggKDAoFBAECAgES
A08JEgoMCgUEAQICAxIDTxUWCuIBCgIEAhIFVQCKAQEa1AEgVVJMIHBhdHRlcm4gYW5kIGRl
c2NyaXB0aW9uIG9mIGhvdyB0aGUgVVJMIHNob3VsZCBiZSBoYW5kbGVkLiBBcHAgRW5naW5l
IGNhbgogaGFuZGxlIFVSTHMgYnkgZXhlY3V0aW5nIGFwcGxpY2F0aW9uIGNvZGUgb3IgYnkg
c2VydmluZyBzdGF0aWMgZmlsZXMKIHVwbG9hZGVkIHdpdGggdGhlIHZlcnNpb24sIHN1Y2gg
YXMgaW1hZ2VzLCBDU1MsIG9yIEphdmFTY3JpcHQuCgoKCgMEAgESA1UIDgofCgQEAgQAEgRX
AmYDGhEgUmVkaXJlY3QgY29kZXMuCgoMCgUEAgQAARIDVwcfCjEKBgQCBAACABIDWQQwGiIg
Tm90IHNwZWNpZmllZC4gYDMwMmAgaXMgYXNzdW1lZC4KCg4KBwQCBAACAAESA1kEKwoOCgcE
AgQAAgACEgNZLi8KLgoGBAIEAAIBEgNcBCgaHyBgMzAxIE1vdmVkIFBlcm1hbmVudGx5YCBj
b2RlLgoKDgoHBAIEAAIBARIDXAQjCg4KBwQCBAACAQISA1wmJwouCgYEAgQAAgISA18EKBof
IGAzMDIgTW92ZWQgVGVtcG9yYXJpbHlgIGNvZGUuCgoOCgcEAgQAAgIBEgNfBCMKDgoHBAIE
AAICAhIDXyYnCiYKBgQCBAACAxIDYgQoGhcgYDMwMyBTZWUgT3RoZXJgIGNvZGUuCgoOCgcE
AgQAAgMBEgNiBCMKDgoHBAIEAAIDAhIDYiYnCi8KBgQCBAACBBIDZQQoGiAgYDMwNyBUZW1w
b3JhcnkgUmVkaXJlY3RgIGNvZGUuCgoOCgcEAgQAAgQBEgNlBCMKDgoHBAIEAAIEAhIDZSYn
CqECCgQEAgIAEgNsAhcakwIgVVJMIHByZWZpeC4gVXNlcyByZWd1bGFyIGV4cHJlc3Npb24g
c3ludGF4LCB3aGljaCBtZWFucyByZWdleHAKIHNwZWNpYWwgY2hhcmFjdGVycyBtdXN0IGJl
IGVzY2FwZWQsIGJ1dCBzaG91bGQgbm90IGNvbnRhaW4gZ3JvdXBpbmdzLgogQWxsIFVSTHMg
dGhhdCBiZWdpbiB3aXRoIHRoaXMgcHJlZml4IGFyZSBoYW5kbGVkIGJ5IHRoaXMgaGFuZGxl
ciwgdXNpbmcgdGhlCiBwb3J0aW9uIG9mIHRoZSBVUkwgYWZ0ZXIgdGhlIHByZWZpeCBhcyBw
YXJ0IG9mIHRoZSBmaWxlIHBhdGguCgoMCgUEAgIABRIDbAIICgwKBQQCAgABEgNsCRIKDAoF
BAICAAMSA2wVFgo1CgQEAggAEgRvAnoDGicgVHlwZSBvZiBoYW5kbGVyIGZvciB0aGlzIFVS
TCBwYXR0ZXJuLgoKDAoFBAIIAAESA28IFApRCgQEAgIBEgNxBCgaRCBSZXR1cm5zIHRoZSBj
b250ZW50cyBvZiBhIGZpbGUsIHN1Y2ggYXMgYW4gaW1hZ2UsIGFzIHRoZSByZXNwb25zZS4K
CgwKBQQCAgEGEgNxBBYKDAoFBAICAQESA3EXIwoMCgUEAgIBAxIDcSYnCs4BCgQEAgICEgN2
BB0awAEgRXhlY3V0ZXMgYSBzY3JpcHQgdG8gaGFuZGxlIHRoZSByZXF1ZXN0cyB0aGF0IG1h
dGNoIHRoaXMgVVJMCiBwYXR0ZXJuLiBPbmx5IHRoZSBgYXV0b2AgdmFsdWUgaXMgc3VwcG9y
dGVkIGZvciBOb2RlLmpzIGluIHRoZQogQXBwIEVuZ2luZSBzdGFuZGFyZCBlbnZpcm9ubWVu
dCwgZm9yIGV4YW1wbGUgYCJzY3JpcHQiOiAiYXV0byJgLgoKDAoFBAICAgYSA3YEEQoMCgUE
AgICARIDdhIYCgwKBQQCAgIDEgN2GxwKNQoEBAICAxIDeQQoGiggVXNlcyBBUEkgRW5kcG9p
bnRzIHRvIGhhbmRsZSByZXF1ZXN0cy4KCgwKBQQCAgMGEgN5BBYKDAoFBAICAwESA3kXIwoM
CgUEAgIDAxIDeSYnCjkKBAQCAgQSA30CIxosIFNlY3VyaXR5IChIVFRQUykgZW5mb3JjZW1l
bnQgZm9yIHRoaXMgVVJMLgoKDAoFBAICBAYSA30CDwoMCgUEAgIEARIDfRAeCgwKBQQCAgQD
EgN9ISIKgwEKBAQCAgUSBIEBAh0adSBMZXZlbCBvZiBsb2dpbiByZXF1aXJlZCB0byBhY2Nl
c3MgdGhpcyByZXNvdXJjZS4gTm90IHN1cHBvcnRlZCBmb3IgTm9kZS5qcwogaW4gdGhlIEFw
cCBFbmdpbmUgc3RhbmRhcmQgZW52aXJvbm1lbnQuCgoNCgUEAgIFBhIEgQECEgoNCgUEAgIF
ARIEgQETGAoNCgUEAgIFAxIEgQEbHApwCgQEAgIGEgSFAQImGmIgQWN0aW9uIHRvIHRha2Ug
d2hlbiB1c2VycyBhY2Nlc3MgcmVzb3VyY2VzIHRoYXQgcmVxdWlyZQogYXV0aGVudGljYXRp
b24uIERlZmF1bHRzIHRvIGByZWRpcmVjdGAuCgoNCgUEAgIGBhIEhQECEAoNCgUEAgIGARIE
hQERIQoNCgUEAgIGAxIEhQEkJQpnCgQEAgIHEgSJAQI7GlkgYDMweGAgY29kZSB0byB1c2Ug
d2hlbiBwZXJmb3JtaW5nIHJlZGlyZWN0cyBmb3IgdGhlIGBzZWN1cmVgIGZpZWxkLgogRGVm
YXVsdHMgdG8gYDMwMmAuCgoNCgUEAgIHBhIEiQECGgoNCgUEAgIHARIEiQEbNgoNCgUEAgIH
AxIEiQE5Ogr3AQoCBAMSBpABALEBARroASBGaWxlcyBzZXJ2ZWQgZGlyZWN0bHkgdG8gdGhl
IHVzZXIgZm9yIGEgZ2l2ZW4gVVJMLCBzdWNoIGFzIGltYWdlcywgQ1NTCiBzdHlsZXNoZWV0
cywgb3IgSmF2YVNjcmlwdCBzb3VyY2UgZmlsZXMuIFN0YXRpYyBmaWxlIGhhbmRsZXJzIGRl
c2NyaWJlIHdoaWNoCiBmaWxlcyBpbiB0aGUgYXBwbGljYXRpb24gZGlyZWN0b3J5IGFyZSBz
dGF0aWMgZmlsZXMsIGFuZCB3aGljaCBVUkxzIHNlcnZlCiB0aGVtLgoKCwoDBAMBEgSQAQga
CrABCgQEAwIAEgSUAQISGqEBIFBhdGggdG8gdGhlIHN0YXRpYyBmaWxlcyBtYXRjaGVkIGJ5
IHRoZSBVUkwgcGF0dGVybiwgZnJvbSB0aGUKIGFwcGxpY2F0aW9uIHJvb3QgZGlyZWN0b3J5
LiBUaGUgcGF0aCBjYW4gcmVmZXIgdG8gdGV4dCBtYXRjaGVkIGluIGdyb3VwaW5ncwogaW4g
dGhlIFVSTCBwYXR0ZXJuLgoKDQoFBAMCAAUSBJQBAggKDQoFBAMCAAESBJQBCQ0KDQoFBAMC
AAMSBJQBEBEKeAoEBAMCARIEmAECHxpqIFJlZ3VsYXIgZXhwcmVzc2lvbiB0aGF0IG1hdGNo
ZXMgdGhlIGZpbGUgcGF0aHMgZm9yIGFsbCBmaWxlcyB0aGF0IHNob3VsZCBiZQogcmVmZXJl
bmNlZCBieSB0aGlzIGhhbmRsZXIuCgoNCgUEAwIBBRIEmAECCAoNCgUEAwIBARIEmAEJGgoN
CgUEAwIBAxIEmAEdHgpGCgQEAwICEgSbAQInGjggSFRUUCBoZWFkZXJzIHRvIHVzZSBmb3Ig
YWxsIHJlc3BvbnNlcyBmcm9tIHRoZXNlIFVSTHMuCgoNCgUEAwICBhIEmwECFQoNCgUEAwIC
ARIEmwEWIgoNCgUEAwICAxIEmwElJgqqAQoEBAMCAxIEoQECFxqbASBNSU1FIHR5cGUgdXNl
ZCB0byBzZXJ2ZSBhbGwgZmlsZXMgc2VydmVkIGJ5IHRoaXMgaGFuZGxlci4KCiBEZWZhdWx0
cyB0byBmaWxlLXNwZWNpZmljIE1JTUUgdHlwZXMsIHdoaWNoIGFyZSBkZXJpdmVkIGZyb20g
ZWFjaCBmaWxlJ3MKIGZpbGVuYW1lIGV4dGVuc2lvbi4KCg0KBQQDAgMFEgShAQIICg0KBQQD
AgMBEgShAQkSCg0KBQQDAgMDEgShARUWCmgKBAQDAgQSBKUBAioaWiBUaW1lIGEgc3RhdGlj
IGZpbGUgc2VydmVkIGJ5IHRoaXMgaGFuZGxlciBzaG91bGQgYmUgY2FjaGVkCiBieSB3ZWIg
cHJveGllcyBhbmQgYnJvd3NlcnMuCgoNCgUEAwIEBhIEpQECGgoNCgUEAwIEARIEpQEbJQoN
CgUEAwIEAxIEpQEoKQp0CgQEAwIFEgSpAQIhGmYgV2hldGhlciB0aGlzIGhhbmRsZXIgc2hv
dWxkIG1hdGNoIHRoZSByZXF1ZXN0IGlmIHRoZSBmaWxlCiByZWZlcmVuY2VkIGJ5IHRoZSBo
YW5kbGVyIGRvZXMgbm90IGV4aXN0LgoKDQoFBAMCBQUSBKkBAgYKDQoFBAMCBQESBKkBBxwK
DQoFBAMCBQMSBKkBHyAKwQIKBAQDAgYSBLABAiAasgIgV2hldGhlciBmaWxlcyBzaG91bGQg
YWxzbyBiZSB1cGxvYWRlZCBhcyBjb2RlIGRhdGEuIEJ5IGRlZmF1bHQsIGZpbGVzCiBkZWNs
YXJlZCBpbiBzdGF0aWMgZmlsZSBoYW5kbGVycyBhcmUgdXBsb2FkZWQgYXMgc3RhdGljCiBk
YXRhIGFuZCBhcmUgb25seSBzZXJ2ZWQgdG8gZW5kIHVzZXJzOyB0aGV5IGNhbm5vdCBiZSBy
ZWFkIGJ5IHRoZQogYXBwbGljYXRpb24uIElmIGVuYWJsZWQsIHVwbG9hZHMgYXJlIGNoYXJn
ZWQgYWdhaW5zdCBib3RoIHlvdXIgY29kZSBhbmQKIHN0YXRpYyBkYXRhIHN0b3JhZ2UgcmVz
b3VyY2UgcXVvdGFzLgoKDQoFBAMCBgUSBLABAgYKDQoFBAMCBgESBLABBxsKDQoFBAMCBgMS
BLABHh8KVQoCBAQSBrQBALcBARpHIEV4ZWN1dGVzIGEgc2NyaXB0IHRvIGhhbmRsZSB0aGUg
cmVxdWVzdCB0aGF0IG1hdGNoZXMgdGhlIFVSTCBwYXR0ZXJuLgoKCwoDBAQBEgS0AQgVCkcK
BAQEAgASBLYBAhkaOSBQYXRoIHRvIHRoZSBzY3JpcHQgZnJvbSB0aGUgYXBwbGljYXRpb24g
cm9vdCBkaXJlY3RvcnkuCgoNCgUEBAIABRIEtgECCAoNCgUEBAIAARIEtgEJFAoNCgUEBAIA
AxIEtgEXGAo/CgIEBRIGugEAvQEBGjEgVXNlcyBHb29nbGUgQ2xvdWQgRW5kcG9pbnRzIHRv
IGhhbmRsZSByZXF1ZXN0cy4KCgsKAwQFARIEugEIGgpHCgQEBQIAEgS8AQIZGjkgUGF0aCB0
byB0aGUgc2NyaXB0IGZyb20gdGhlIGFwcGxpY2F0aW9uIHJvb3QgZGlyZWN0b3J5LgoKDQoF
BAUCAAUSBLwBAggKDQoFBAUCAAESBLwBCRQKDQoFBAUCAAMSBLwBFxgKxAEKAgQGEgbCAQDb
AQEatQEgSGVhbHRoIGNoZWNraW5nIGNvbmZpZ3VyYXRpb24gZm9yIFZNIGluc3RhbmNlcy4g
VW5oZWFsdGh5IGluc3RhbmNlcwogYXJlIGtpbGxlZCBhbmQgcmVwbGFjZWQgd2l0aCBuZXcg
aW5zdGFuY2VzLiBPbmx5IGFwcGxpY2FibGUgZm9yCiBpbnN0YW5jZXMgaW4gQXBwIEVuZ2lu
ZSBmbGV4aWJsZSBlbnZpcm9ubWVudC4KCgsKAwQGARIEwgEIEwpOCgQEBgIAEgTEAQIgGkAg
V2hldGhlciB0byBleHBsaWNpdGx5IGRpc2FibGUgaGVhbHRoIGNoZWNrcyBmb3IgdGhpcyBp
bnN0YW5jZS4KCg0KBQQGAgAFEgTEAQIGCg0KBQQGAgABEgTEAQcbCg0KBQQGAgADEgTEAR4f
CmcKBAQGAgESBMgBAhIaWSBIb3N0IGhlYWRlciB0byBzZW5kIHdoZW4gcGVyZm9ybWluZyBh
biBIVFRQIGhlYWx0aCBjaGVjay4KIEV4YW1wbGU6ICJteWFwcC5hcHBzcG90LmNvbSIKCg0K
BQQGAgEFEgTIAQIICg0KBQQGAgEBEgTIAQkNCg0KBQQGAgEDEgTIARARCmIKBAQGAgISBMwB
Ah8aVCBOdW1iZXIgb2YgY29uc2VjdXRpdmUgc3VjY2Vzc2Z1bCBoZWFsdGggY2hlY2tzIHJl
cXVpcmVkIGJlZm9yZSByZWNlaXZpbmcKIHRyYWZmaWMuCgoNCgUEBgICBRIEzAECCAoNCgUE
BgICARIEzAEJGgoNCgUEBgICAxIEzAEdHgpdCgQEBgIDEgTQAQIhGk8gTnVtYmVyIG9mIGNv
bnNlY3V0aXZlIGZhaWxlZCBoZWFsdGggY2hlY2tzIHJlcXVpcmVkIGJlZm9yZSByZW1vdmlu
ZwogdHJhZmZpYy4KCg0KBQQGAgMFEgTQAQIICg0KBQQGAgMBEgTQAQkcCg0KBQQGAgMDEgTQ
AR8gCmUKBAQGAgQSBNQBAh8aVyBOdW1iZXIgb2YgY29uc2VjdXRpdmUgZmFpbGVkIGhlYWx0
aCBjaGVja3MgcmVxdWlyZWQgYmVmb3JlIGFuIGluc3RhbmNlIGlzCiByZXN0YXJ0ZWQuCgoN
CgUEBgIEBRIE1AECCAoNCgUEBgIEARIE1AEJGgoNCgUEBgIEAxIE1AEdHgovCgQEBgIFEgTX
AQIuGiEgSW50ZXJ2YWwgYmV0d2VlbiBoZWFsdGggY2hlY2tzLgoKDQoFBAYCBQYSBNcBAhoK
DQoFBAYCBQESBNcBGykKDQoFBAYCBQMSBNcBLC0KQgoEBAYCBhIE2gECJxo0IFRpbWUgYmVm
b3JlIHRoZSBoZWFsdGggY2hlY2sgaXMgY29uc2lkZXJlZCBmYWlsZWQuCgoNCgUEBgIGBhIE
2gECGgoNCgUEBgIGARIE2gEbIgoNCgUEBgIGAxIE2gElJgp6CgIEBxIG3wEA+QEBGmwgUmVh
ZGluZXNzIGNoZWNraW5nIGNvbmZpZ3VyYXRpb24gZm9yIFZNIGluc3RhbmNlcy4gVW5oZWFs
dGh5IGluc3RhbmNlcwogYXJlIHJlbW92ZWQgZnJvbSB0cmFmZmljIHJvdGF0aW9uLgoKCwoD
BAcBEgTfAQgWCiEKBAQHAgASBOEBAhIaEyBUaGUgcmVxdWVzdCBwYXRoLgoKDQoFBAcCAAUS
BOEBAggKDQoFBAcCAAESBOEBCQ0KDQoFBAcCAAMSBOEBEBEKaQoEBAcCARIE5QECEhpbIEhv
c3QgaGVhZGVyIHRvIHNlbmQgd2hlbiBwZXJmb3JtaW5nIGEgSFRUUCBSZWFkaW5lc3MgY2hl
Y2suCiBFeGFtcGxlOiAibXlhcHAuYXBwc3BvdC5jb20iCgoNCgUEBwIBBRIE5QECCAoNCgUE
BwIBARIE5QEJDQoNCgUEBwIBAxIE5QEQEQpWCgQEBwICEgTpAQIfGkggTnVtYmVyIG9mIGNv
bnNlY3V0aXZlIGZhaWxlZCBjaGVja3MgcmVxdWlyZWQgYmVmb3JlIHJlbW92aW5nCiB0cmFm
ZmljLgoKDQoFBAcCAgUSBOkBAggKDQoFBAcCAgESBOkBCRoKDQoFBAcCAgMSBOkBHR4KWwoE
BAcCAxIE7QECHxpNIE51bWJlciBvZiBjb25zZWN1dGl2ZSBzdWNjZXNzZnVsIGNoZWNrcyBy
ZXF1aXJlZCBiZWZvcmUgcmVjZWl2aW5nCiB0cmFmZmljLgoKDQoFBAcCAwUSBO0BAggKDQoF
BAcCAwESBO0BCRoKDQoFBAcCAwMSBO0BHR4KLwoEBAcCBBIE8AECLhohIEludGVydmFsIGJl
dHdlZW4gaGVhbHRoIGNoZWNrcy4KCg0KBQQHAgQGEgTwAQIaCg0KBQQHAgQBEgTwARspCg0K
BQQHAgQDEgTwASwtCjsKBAQHAgUSBPMBAicaLSBUaW1lIGJlZm9yZSB0aGUgY2hlY2sgaXMg
Y29uc2lkZXJlZCBmYWlsZWQuCgoNCgUEBwIFBhIE8wECGgoNCgUEBwIFARIE8wEbIgoNCgUE
BwIFAxIE8wElJgq1AQoEBAcCBhIE+AECMRqmASBBIG1heGltdW0gdGltZSBsaW1pdCBvbiBh
cHBsaWNhdGlvbiBpbml0aWFsaXphdGlvbiwgbWVhc3VyZWQgZnJvbSBtb21lbnQKIHRoZSBh
cHBsaWNhdGlvbiBzdWNjZXNzZnVsbHkgcmVwbGllcyB0byBhIGhlYWx0aGNoZWNrIHVudGls
IGl0IGlzIHJlYWR5IHRvCiBzZXJ2ZSB0cmFmZmljLgoKDQoFBAcCBgYSBPgBAhoKDQoFBAcC
BgESBPgBGywKDQoFBAcCBgMSBPgBLzAKgAEKAgQIEgb9AQCVAgEaciBIZWFsdGggY2hlY2tp
bmcgY29uZmlndXJhdGlvbiBmb3IgVk0gaW5zdGFuY2VzLiBVbmhlYWx0aHkgaW5zdGFuY2Vz
CiBhcmUga2lsbGVkIGFuZCByZXBsYWNlZCB3aXRoIG5ldyBpbnN0YW5jZXMuCgoLCgMECAES
BP0BCBUKIQoEBAgCABIE/wECEhoTIFRoZSByZXF1ZXN0IHBhdGguCgoNCgUECAIABRIE/wEC
CAoNCgUECAIAARIE/wEJDQoNCgUECAIAAxIE/wEQEQpoCgQECAIBEgSDAgISGlogSG9zdCBo
ZWFkZXIgdG8gc2VuZCB3aGVuIHBlcmZvcm1pbmcgYSBIVFRQIExpdmVuZXNzIGNoZWNrLgog
RXhhbXBsZTogIm15YXBwLmFwcHNwb3QuY29tIgoKDQoFBAgCAQUSBIMCAggKDQoFBAgCAQES
BIMCCQ0KDQoFBAgCAQMSBIMCEBEKYgoEBAgCAhIEhwICHxpUIE51bWJlciBvZiBjb25zZWN1
dGl2ZSBmYWlsZWQgY2hlY2tzIHJlcXVpcmVkIGJlZm9yZSBjb25zaWRlcmluZyB0aGUKIFZN
IHVuaGVhbHRoeS4KCg0KBQQIAgIFEgSHAgIICg0KBQQIAgIBEgSHAgkaCg0KBQQIAgIDEgSH
Ah0eCmQKBAQIAgMSBIsCAh8aViBOdW1iZXIgb2YgY29uc2VjdXRpdmUgc3VjY2Vzc2Z1bCBj
aGVja3MgcmVxdWlyZWQgYmVmb3JlIGNvbnNpZGVyaW5nCiB0aGUgVk0gaGVhbHRoeS4KCg0K
BQQIAgMFEgSLAgIICg0KBQQIAgMBEgSLAgkaCg0KBQQIAgMDEgSLAh0eCi8KBAQIAgQSBI4C
Ai4aISBJbnRlcnZhbCBiZXR3ZWVuIGhlYWx0aCBjaGVja3MuCgoNCgUECAIEBhIEjgICGgoN
CgUECAIEARIEjgIbKQoNCgUECAIEAxIEjgIsLQo7CgQECAIFEgSRAgInGi0gVGltZSBiZWZv
cmUgdGhlIGNoZWNrIGlzIGNvbnNpZGVyZWQgZmFpbGVkLgoKDQoFBAgCBQYSBJECAhoKDQoF
BAgCBQESBJECGyIKDQoFBAgCBQMSBJECJSYKSAoEBAgCBhIElAICLRo6IFRoZSBpbml0aWFs
IGRlbGF5IGJlZm9yZSBzdGFydGluZyB0byBleGVjdXRlIHRoZSBjaGVja3MuCgoNCgUECAIG
BhIElAICGgoNCgUECAIGARIElAIbKAoNCgUECAIGAxIElAIrLApXCgIECRIGmAIAngIBGkkg
VGhpcmQtcGFydHkgUHl0aG9uIHJ1bnRpbWUgbGlicmFyeSB0aGF0IGlzIHJlcXVpcmVkIGJ5
IHRoZSBhcHBsaWNhdGlvbi4KCgsKAwQJARIEmAIIDwo3CgQECQIAEgSaAgISGikgTmFtZSBv
ZiB0aGUgbGlicmFyeS4gRXhhbXBsZTogImRqYW5nbyIuCgoNCgUECQIABRIEmgICCAoNCgUE
CQIAARIEmgIJDQoNCgUECQIAAxIEmgIQEQo+CgQECQIBEgSdAgIVGjAgVmVyc2lvbiBvZiB0
aGUgbGlicmFyeSB0byBzZWxlY3QsIG9yICJsYXRlc3QiLgoKDQoFBAkCAQUSBJ0CAggKDQoF
BAkCAQESBJ0CCRAKDQoFBAkCAQMSBJ0CExQKPwoCBQASBqECAKwCARoxIEFjdGlvbnMgdG8g
dGFrZSB3aGVuIHRoZSB1c2VyIGlzIG5vdCBsb2dnZWQgaW4uCgoLCgMFAAESBKECBRMKRgoE
BQACABIEowICIxo4IE5vdCBzcGVjaWZpZWQuIGBBVVRIX0ZBSUxfQUNUSU9OX1JFRElSRUNU
YCBpcyBhc3N1bWVkLgoKDQoFBQACAAESBKMCAh4KDQoFBQACAAISBKMCISIKlgEKBAUAAgES
BKcCAiAahwEgUmVkaXJlY3RzIHVzZXIgdG8gImFjY291bnRzLmdvb2dsZS5jb20iLiBUaGUg
dXNlciBpcyByZWRpcmVjdGVkIGJhY2sgdG8gdGhlCiBhcHBsaWNhdGlvbiBVUkwgYWZ0ZXIg
c2lnbmluZyBpbiBvciBjcmVhdGluZyBhbiBhY2NvdW50LgoKDQoFBQACAQESBKcCAhsKDQoF
BQACAQISBKcCHh8KVAoEBQACAhIEqwICJBpGIFJlamVjdHMgcmVxdWVzdCB3aXRoIGEgYDQw
MWAgSFRUUCBzdGF0dXMgY29kZSBhbmQgYW4gZXJyb3IKIG1lc3NhZ2UuCgoNCgUFAAICARIE
qwICHwoNCgUFAAICAhIEqwIiIwpKCgIFARIGrwIAwAIBGjwgTWV0aG9kcyB0byByZXN0cmlj
dCBhY2Nlc3MgdG8gYSBVUkwgYmFzZWQgb24gbG9naW4gc3RhdHVzLgoKCwoDBQEBEgSvAgUV
CjsKBAUBAgASBLECAhgaLSBOb3Qgc3BlY2lmaWVkLiBgTE9HSU5fT1BUSU9OQUxgIGlzIGFz
c3VtZWQuCgoNCgUFAQIAARIEsQICEwoNCgUFAQIAAhIEsQIWFwo8CgQFAQIBEgS0AgIVGi4g
RG9lcyBub3QgcmVxdWlyZSB0aGF0IHRoZSB1c2VyIGlzIHNpZ25lZCBpbi4KCg0KBQUBAgEB
EgS0AgIQCg0KBQUBAgECEgS0AhMUCpICCgQFAQICEgS7AgISGoMCIElmIHRoZSB1c2VyIGlz
IG5vdCBzaWduZWQgaW4sIHRoZSBgYXV0aF9mYWlsX2FjdGlvbmAgaXMgdGFrZW4uCiBJbiBh
ZGRpdGlvbiwgaWYgdGhlIHVzZXIgaXMgbm90IGFuIGFkbWluaXN0cmF0b3IgZm9yIHRoZQog
YXBwbGljYXRpb24sIHRoZXkgYXJlIGdpdmVuIGFuIGVycm9yIG1lc3NhZ2UgcmVnYXJkbGVz
cyBvZgogYGF1dGhfZmFpbF9hY3Rpb25gLiBJZiB0aGUgdXNlciBpcyBhbiBhZG1pbmlzdHJh
dG9yLCB0aGUgaGFuZGxlcgogcHJvY2VlZHMuCgoNCgUFAQICARIEuwICDQoNCgUFAQICAhIE
uwIQEQp0CgQFAQIDEgS/AgIVGmYgSWYgdGhlIHVzZXIgaGFzIHNpZ25lZCBpbiwgdGhlIGhh
bmRsZXIgcHJvY2VlZHMgbm9ybWFsbHkuIE90aGVyd2lzZSwgdGhlCiBhdXRoX2ZhaWxfYWN0
aW9uIGlzIHRha2VuLgoKDQoFBQECAwESBL8CAhAKDQoFBQECAwISBL8CExQKPQoCBQISBsMC
ANsCARovIE1ldGhvZHMgdG8gZW5mb3JjZSBzZWN1cml0eSAoSFRUUFMpIG9uIGEgVVJMLgoK
CwoDBQIBEgTDAgUSCgsKAwUCAxIExAICHAoMCgQFAgMCEgTEAgIcCh4KBAUCAgASBMcCAhka
ECBOb3Qgc3BlY2lmaWVkLgoKDQoFBQICAAESBMcCAhQKDQoFBQICAAISBMcCFxgK0gEKBAUC
AgESBMwCAhUawwEgQm90aCBIVFRQIGFuZCBIVFRQUyByZXF1ZXN0cyB3aXRoIFVSTHMgdGhh
dCBtYXRjaCB0aGUgaGFuZGxlciBzdWNjZWVkCiB3aXRob3V0IHJlZGlyZWN0cy4gVGhlIGFw
cGxpY2F0aW9uIGNhbiBleGFtaW5lIHRoZSByZXF1ZXN0IHRvIGRldGVybWluZQogd2hpY2gg
cHJvdG9jb2wgd2FzIHVzZWQsIGFuZCByZXNwb25kIGFjY29yZGluZ2x5LgoKDQoFBQICAQES
BMwCAhAKDQoFBQICAQISBMwCExQKgwEKBAUCAgISBNACAhMadSBSZXF1ZXN0cyBmb3IgYSBV
UkwgdGhhdCBtYXRjaCB0aGlzIGhhbmRsZXIgdGhhdCB1c2UgSFRUUFMgYXJlIGF1dG9tYXRp
Y2FsbHkKIHJlZGlyZWN0ZWQgdG8gdGhlIEhUVFAgZXF1aXZhbGVudCBVUkwuCgoNCgUFAgIC
ARIE0AICDgoNCgUFAgICAhIE0AIREgrRAQoEBQICAxIE1QICFhrCASBCb3RoIEhUVFAgYW5k
IEhUVFBTIHJlcXVlc3RzIHdpdGggVVJMcyB0aGF0IG1hdGNoIHRoZSBoYW5kbGVyIHN1Y2Nl
ZWQKIHdpdGhvdXQgcmVkaXJlY3RzLiBUaGUgYXBwbGljYXRpb24gY2FuIGV4YW1pbmUgdGhl
IHJlcXVlc3QgdG8gZGV0ZXJtaW5lCiB3aGljaCBwcm90b2NvbCB3YXMgdXNlZCBhbmQgcmVz
cG9uZCBhY2NvcmRpbmdseS4KCg0KBQUCAgMBEgTVAgIRCg0KBQUCAgMCEgTVAhQVCsUBCgQF
AgIEEgTaAgIUGrYBIFJlcXVlc3RzIGZvciBhIFVSTCB0aGF0IG1hdGNoIHRoaXMgaGFuZGxl
ciB0aGF0IGRvIG5vdCB1c2UgSFRUUFMgYXJlCiBhdXRvbWF0aWNhbGx5IHJlZGlyZWN0ZWQg
dG8gdGhlIEhUVFBTIFVSTCB3aXRoIHRoZSBzYW1lIHBhdGguIFF1ZXJ5CiBwYXJhbWV0ZXJz
IGFyZSByZXNlcnZlZCBmb3IgdGhlIHJlZGlyZWN0LgoKDQoFBQICBAESBNoCAg8KDQoFBQIC
BAISBNoCEhNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::AppYaml::ApiConfigHandler ===
    # Fields for ApiConfigHandler
    # Field: auth_fail_action Type: 14 (.google.appengine.v1beta.AuthFailAction)
    # Field: login Type: 14 (.google.appengine.v1beta.LoginRequirement)
    # Field: script Type: 9 ()
    # Field: security_level Type: 14 (.google.appengine.v1beta.SecurityLevel)
    # Field: url Type: 9 ()

# === Message: Google::Appengine::V1beta::AppYaml::ErrorHandler ===
    # Fields for ErrorHandler
    # Field: error_code Type: 14 (.google.appengine.v1beta.ErrorHandler.ErrorCode)
    # Field: static_file Type: 9 ()
    # Field: mime_type Type: 9 ()

# Enum: ErrorHandler::ErrorCode
our $ErrorHandler_ERROR_CODE_UNSPECIFIED = 0;
our $ErrorHandler_ERROR_CODE_DEFAULT = 0;
our $ErrorHandler_ERROR_CODE_OVER_QUOTA = 1;
our $ErrorHandler_ERROR_CODE_DOS_API_DENIAL = 2;
our $ErrorHandler_ERROR_CODE_TIMEOUT = 3;

# === Message: Google::Appengine::V1beta::AppYaml::UrlMap ===
    # Fields for UrlMap
    # Field: url_regex Type: 9 ()
    # Field: static_files Type: 11 (.google.appengine.v1beta.StaticFilesHandler)
    # Field: script Type: 11 (.google.appengine.v1beta.ScriptHandler)
    # Field: api_endpoint Type: 11 (.google.appengine.v1beta.ApiEndpointHandler)
    # Field: security_level Type: 14 (.google.appengine.v1beta.SecurityLevel)
    # Field: login Type: 14 (.google.appengine.v1beta.LoginRequirement)
    # Field: auth_fail_action Type: 14 (.google.appengine.v1beta.AuthFailAction)
    # Field: redirect_http_response_code Type: 14 (.google.appengine.v1beta.UrlMap.RedirectHttpResponseCode)

# Enum: UrlMap::RedirectHttpResponseCode
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED = 0;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_301 = 1;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_302 = 2;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_303 = 3;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_307 = 4;

# === Message: Google::Appengine::V1beta::AppYaml::StaticFilesHandler ===
    # Fields for StaticFilesHandler
    # Field: path Type: 9 ()
    # Field: upload_path_regex Type: 9 ()
    # Field: http_headers Type: 11 (.google.appengine.v1beta.StaticFilesHandler.HttpHeadersEntry)
    # Field: mime_type Type: 9 ()
    # Field: expiration Type: 11 (.google.protobuf.Duration)
    # Field: require_matching_file Type: 8 ()
    # Field: application_readable Type: 8 ()

# === Message: Google::Appengine::V1beta::AppYaml::ScriptHandler ===
    # Fields for ScriptHandler
    # Field: script_path Type: 9 ()

# === Message: Google::Appengine::V1beta::AppYaml::ApiEndpointHandler ===
    # Fields for ApiEndpointHandler
    # Field: script_path Type: 9 ()

# === Message: Google::Appengine::V1beta::AppYaml::HealthCheck ===
    # Fields for HealthCheck
    # Field: disable_health_check Type: 8 ()
    # Field: host Type: 9 ()
    # Field: healthy_threshold Type: 13 ()
    # Field: unhealthy_threshold Type: 13 ()
    # Field: restart_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1beta::AppYaml::ReadinessCheck ===
    # Fields for ReadinessCheck
    # Field: path Type: 9 ()
    # Field: host Type: 9 ()
    # Field: failure_threshold Type: 13 ()
    # Field: success_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: app_start_timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1beta::AppYaml::LivenessCheck ===
    # Fields for LivenessCheck
    # Field: path Type: 9 ()
    # Field: host Type: 9 ()
    # Field: failure_threshold Type: 13 ()
    # Field: success_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: initial_delay Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1beta::AppYaml::Library ===
    # Fields for Library
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::AppYaml - Compiled Protocol Buffers messages for google/appengine/v1beta/app_yaml.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::AppYaml;

    my $msg = Google::Appengine::V1beta::AppYaml::ApiConfigHandler->new({
        auth_fail_action => $auth_fail_action,
        login => $login,
        script => $script,
        security_level => $security_level,
    });

    # Read or update a field
    my $val = $msg->auth_fail_action();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::AppYaml::ApiConfigHandler->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/app_yaml.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::AppYaml::ApiConfigHandler

[Google Cloud Endpoints](https://cloud.google.com/appengine/docs/python/endpoints/)
configuration for API handlers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_fail_action() >> / C<< $msg->auth_fail_action($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::AuthFailAction>)

Action to take when users access resources that require
authentication. Defaults to `redirect`.

=item * C<< $msg->login() >> / C<< $msg->login($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::LoginRequirement>)

Level of login required to access this resource. Defaults to
`optional`.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<String>

Path to the script from the application root directory.

=item * C<< $msg->security_level() >> / C<< $msg->security_level($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::SecurityLevel>)

Security (HTTPS) enforcement for this URL.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

URL to serve the endpoint at.

=back

=head2 Google::Appengine::V1beta::AppYaml::ErrorHandler

Custom static error page to be served when an error occurs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::ErrorHandler::ErrorCode>)

Error condition this handler applies to.

=item * C<< $msg->static_file() >> / C<< $msg->static_file($value) >>

Type: C<String>

Static file content to be served for this error.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

MIME type of file. Defaults to `text/html`.

=back

=head3 Enum: ErrorHandler::ErrorCode

=over 4

=item * C<ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<ERROR_CODE_DEFAULT> => C<0>

=item * C<ERROR_CODE_OVER_QUOTA> => C<1>

=item * C<ERROR_CODE_DOS_API_DENIAL> => C<2>

=item * C<ERROR_CODE_TIMEOUT> => C<3>

=back

=head2 Google::Appengine::V1beta::AppYaml::UrlMap

URL pattern and description of how the URL should be handled. App Engine can
handle URLs by executing application code or by serving static files
uploaded with the version, such as images, CSS, or JavaScript.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url_regex() >> / C<< $msg->url_regex($value) >>

Type: C<String>

URL prefix. Uses regular expression syntax, which means regexp
special characters must be escaped, but should not contain groupings.
All URLs that begin with this prefix are handled by this handler, using the
portion of the URL after the prefix as part of the file path.

=item * C<< $msg->static_files() >> / C<< $msg->static_files($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AppYaml::StaticFilesHandler>)

Returns the contents of a file, such as an image, as the response.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AppYaml::ScriptHandler>)

Executes a script to handle the requests that match this URL
pattern. Only the `auto` value is supported for Node.js in the
App Engine standard environment, for example `"script": "auto"`.

=item * C<< $msg->api_endpoint() >> / C<< $msg->api_endpoint($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AppYaml::ApiEndpointHandler>)

Uses API Endpoints to handle requests.

=item * C<< $msg->security_level() >> / C<< $msg->security_level($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::SecurityLevel>)

Security (HTTPS) enforcement for this URL.

=item * C<< $msg->login() >> / C<< $msg->login($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::LoginRequirement>)

Level of login required to access this resource. Not supported for Node.js
in the App Engine standard environment.

=item * C<< $msg->auth_fail_action() >> / C<< $msg->auth_fail_action($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::AuthFailAction>)

Action to take when users access resources that require
authentication. Defaults to `redirect`.

=item * C<< $msg->redirect_http_response_code() >> / C<< $msg->redirect_http_response_code($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::UrlMap::RedirectHttpResponseCode>)

`30x` code to use when performing redirects for the `secure` field.
Defaults to `302`.

=back

=head3 Enum: UrlMap::RedirectHttpResponseCode

=over 4

=item * C<REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED> => C<0>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_301> => C<1>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_302> => C<2>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_303> => C<3>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_307> => C<4>

=back

=head2 Google::Appengine::V1beta::AppYaml::StaticFilesHandler

Files served directly to the user for a given URL, such as images, CSS
stylesheets, or JavaScript source files. Static file handlers describe which
files in the application directory are static files, and which URLs serve
them.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path to the static files matched by the URL pattern, from the
application root directory. The path can refer to text matched in groupings
in the URL pattern.

=item * C<< $msg->upload_path_regex() >> / C<< $msg->upload_path_regex($value) >>

Type: C<String>

Regular expression that matches the file paths for all files that should be
referenced by this handler.

=item * C<< $msg->http_headers() >> / C<< $msg->http_headers($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AppYaml::StaticFilesHandler::HttpHeadersEntry>)

HTTP headers to use for all responses from these URLs.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

MIME type used to serve all files served by this handler.

Defaults to file-specific MIME types, which are derived from each file's
filename extension.

=item * C<< $msg->expiration() >> / C<< $msg->expiration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time a static file served by this handler should be cached
by web proxies and browsers.

=item * C<< $msg->require_matching_file() >> / C<< $msg->require_matching_file($value) >>

Type: C<Bool>

Whether this handler should match the request if the file
referenced by the handler does not exist.

=item * C<< $msg->application_readable() >> / C<< $msg->application_readable($value) >>

Type: C<Bool>

Whether files should also be uploaded as code data. By default, files
declared in static file handlers are uploaded as static
data and are only served to end users; they cannot be read by the
application. If enabled, uploads are charged against both your code and
static data storage resource quotas.

=back

=head2 Google::Appengine::V1beta::AppYaml::ScriptHandler

Executes a script to handle the request that matches the URL pattern.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->script_path() >> / C<< $msg->script_path($value) >>

Type: C<String>

Path to the script from the application root directory.

=back

=head2 Google::Appengine::V1beta::AppYaml::ApiEndpointHandler

Uses Google Cloud Endpoints to handle requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->script_path() >> / C<< $msg->script_path($value) >>

Type: C<String>

Path to the script from the application root directory.

=back

=head2 Google::Appengine::V1beta::AppYaml::HealthCheck

Health checking configuration for VM instances. Unhealthy instances
are killed and replaced with new instances. Only applicable for
instances in App Engine flexible environment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disable_health_check() >> / C<< $msg->disable_health_check($value) >>

Type: C<Bool>

Whether to explicitly disable health checks for this instance.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing an HTTP health check.
Example: "myapp.appspot.com"

=item * C<< $msg->healthy_threshold() >> / C<< $msg->healthy_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful health checks required before receiving
traffic.

=item * C<< $msg->unhealthy_threshold() >> / C<< $msg->unhealthy_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed health checks required before removing
traffic.

=item * C<< $msg->restart_threshold() >> / C<< $msg->restart_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed health checks required before an instance is
restarted.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the health check is considered failed.

=back

=head2 Google::Appengine::V1beta::AppYaml::ReadinessCheck

Readiness checking configuration for VM instances. Unhealthy instances
are removed from traffic rotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The request path.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing a HTTP Readiness check.
Example: "myapp.appspot.com"

=item * C<< $msg->failure_threshold() >> / C<< $msg->failure_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed checks required before removing
traffic.

=item * C<< $msg->success_threshold() >> / C<< $msg->success_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful checks required before receiving
traffic.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the check is considered failed.

=item * C<< $msg->app_start_timeout() >> / C<< $msg->app_start_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

A maximum time limit on application initialization, measured from moment
the application successfully replies to a healthcheck until it is ready to
serve traffic.

=back

=head2 Google::Appengine::V1beta::AppYaml::LivenessCheck

Health checking configuration for VM instances. Unhealthy instances
are killed and replaced with new instances.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The request path.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing a HTTP Liveness check.
Example: "myapp.appspot.com"

=item * C<< $msg->failure_threshold() >> / C<< $msg->failure_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed checks required before considering the
VM unhealthy.

=item * C<< $msg->success_threshold() >> / C<< $msg->success_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful checks required before considering
the VM healthy.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the check is considered failed.

=item * C<< $msg->initial_delay() >> / C<< $msg->initial_delay($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The initial delay before starting to execute the checks.

=back

=head2 Google::Appengine::V1beta::AppYaml::Library

Third-party Python runtime library that is required by the application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the library. Example: "django".

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of the library to select, or "latest".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::AppYaml::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
