package Google::Cloud::Securitycenter::V1::Resource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Securitycenter::V1::Folder };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvcmVzb3VyY2UucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxorZ29vZ2xlL2Nsb3VkL3NlY3VyaXR5Y2VudGVyL3YxL2ZvbGRlci5wcm90byKqBgoI
UmVzb3VyY2USEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYCCABKAlSC2Rp
c3BsYXlOYW1lEhIKBHR5cGUYBiABKAlSBHR5cGUSGAoHcHJvamVjdBgCIAEoCVIHcHJvamVj
dBIwChRwcm9qZWN0X2Rpc3BsYXlfbmFtZRgDIAEoCVIScHJvamVjdERpc3BsYXlOYW1lEhYK
BnBhcmVudBgEIAEoCVIGcGFyZW50Ei4KE3BhcmVudF9kaXNwbGF5X25hbWUYBSABKAlSEXBh
cmVudERpc3BsYXlOYW1lEkUKB2ZvbGRlcnMYByADKAsyJi5nb29nbGUuY2xvdWQuc2VjdXJp
dHljZW50ZXIudjEuRm9sZGVyQgPgQQNSB2ZvbGRlcnMSVAoOY2xvdWRfcHJvdmlkZXIYCSAB
KA4yLS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQ2xvdWRQcm92aWRlclINY2xv
dWRQcm92aWRlchIiCgxvcmdhbml6YXRpb24YCiABKAlSDG9yZ2FuaXphdGlvbhIYCgdzZXJ2
aWNlGAsgASgJUgdzZXJ2aWNlEhoKCGxvY2F0aW9uGAwgASgJUghsb2NhdGlvbhJQCgxhd3Nf
bWV0YWRhdGEYECABKAsyKy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQXdzTWV0
YWRhdGFIAFILYXdzTWV0YWRhdGESVgoOYXp1cmVfbWV0YWRhdGEYESABKAsyLS5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQXp1cmVNZXRhZGF0YUgAUg1henVyZU1ldGFkYXRh
ElEKDXJlc291cmNlX3BhdGgYEiABKAsyLC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIu
djEuUmVzb3VyY2VQYXRoUgxyZXNvdXJjZVBhdGgSMAoUcmVzb3VyY2VfcGF0aF9zdHJpbmcY
EyABKAlSEnJlc291cmNlUGF0aFN0cmluZ0IZChdjbG91ZF9wcm92aWRlcl9tZXRhZGF0YSLI
AwoLQXdzTWV0YWRhdGESXwoMb3JnYW5pemF0aW9uGAIgASgLMjsuZ29vZ2xlLmNsb3VkLnNl
Y3VyaXR5Y2VudGVyLnYxLkF3c01ldGFkYXRhLkF3c09yZ2FuaXphdGlvblIMb3JnYW5pemF0
aW9uEnQKFG9yZ2FuaXphdGlvbmFsX3VuaXRzGAMgAygLMkEuZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYxLkF3c01ldGFkYXRhLkF3c09yZ2FuaXphdGlvbmFsVW5pdFITb3JnYW5p
emF0aW9uYWxVbml0cxJQCgdhY2NvdW50GAQgASgLMjYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxLkF3c01ldGFkYXRhLkF3c0FjY291bnRSB2FjY291bnQaIQoPQXdzT3JnYW5p
emF0aW9uEg4KAmlkGAEgASgJUgJpZBo7ChVBd3NPcmdhbml6YXRpb25hbFVuaXQSDgoCaWQY
ASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUaMAoKQXdzQWNjb3VudBIOCgJpZBgBIAEo
CVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZSKLBAoNQXp1cmVNZXRhZGF0YRJvChFtYW5hZ2Vt
ZW50X2dyb3VwcxgEIAMoCzJCLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5BenVy
ZU1ldGFkYXRhLkF6dXJlTWFuYWdlbWVudEdyb3VwUhBtYW5hZ2VtZW50R3JvdXBzEmMKDHN1
YnNjcmlwdGlvbhgFIAEoCzI/Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5BenVy
ZU1ldGFkYXRhLkF6dXJlU3Vic2NyaXB0aW9uUgxzdWJzY3JpcHRpb24SZwoOcmVzb3VyY2Vf
Z3JvdXAYBiABKAsyQC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQXp1cmVNZXRh
ZGF0YS5BenVyZVJlc291cmNlR3JvdXBSDXJlc291cmNlR3JvdXAaSQoUQXp1cmVNYW5hZ2Vt
ZW50R3JvdXASDgoCaWQYASABKAlSAmlkEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxh
eU5hbWUaRgoRQXp1cmVTdWJzY3JpcHRpb24SDgoCaWQYASABKAlSAmlkEiEKDGRpc3BsYXlf
bmFtZRgCIAEoCVILZGlzcGxheU5hbWUaKAoSQXp1cmVSZXNvdXJjZUdyb3VwEhIKBG5hbWUY
ASABKAlSBG5hbWUilgQKDFJlc291cmNlUGF0aBJTCgVub2RlcxgBIAMoCzI9Lmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MS5SZXNvdXJjZVBhdGguUmVzb3VyY2VQYXRoTm9kZVIF
bm9kZXMapQEKEFJlc291cmNlUGF0aE5vZGUSXgoJbm9kZV90eXBlGAEgASgOMkEuZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLlJlc291cmNlUGF0aC5SZXNvdXJjZVBhdGhOb2Rl
VHlwZVIIbm9kZVR5cGUSDgoCaWQYAiABKAlSAmlkEiEKDGRpc3BsYXlfbmFtZRgDIAEoCVIL
ZGlzcGxheU5hbWUiiAIKFFJlc291cmNlUGF0aE5vZGVUeXBlEicKI1JFU09VUkNFX1BBVEhf
Tk9ERV9UWVBFX1VOU1BFQ0lGSUVEEAASFAoQR0NQX09SR0FOSVpBVElPThABEg4KCkdDUF9G
T0xERVIQAhIPCgtHQ1BfUFJPSkVDVBADEhQKEEFXU19PUkdBTklaQVRJT04QBBIbChdBV1Nf
T1JHQU5JWkFUSU9OQUxfVU5JVBAFEg8KC0FXU19BQ0NPVU5UEAYSGgoWQVpVUkVfTUFOQUdF
TUVOVF9HUk9VUBAHEhYKEkFaVVJFX1NVQlNDUklQVElPThAIEhgKFEFaVVJFX1JFU09VUkNF
X0dST1VQEAkqeAoNQ2xvdWRQcm92aWRlchIeChpDTE9VRF9QUk9WSURFUl9VTlNQRUNJRklF
RBAAEhkKFUdPT0dMRV9DTE9VRF9QTEFURk9STRABEhcKE0FNQVpPTl9XRUJfU0VSVklDRVMQ
AhITCg9NSUNST1NPRlRfQVpVUkUQA0LnAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52MUINUmVzb3VyY2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5
Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2ds
ZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRl
clxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUqnSQoHEgUOAPwBAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAp
CgkKAgMBEgMTADUKCAoBCBIDFQA7CgkKAgglEgMVADsKCAoBCBIDFgBhCgkKAggLEgMWAGEK
CAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAuCgkKAggIEgMYAC4KCAoBCBIDGQA7CgkK
AggBEgMZADsKCAoBCBIDGgA7CgkKAggpEgMaADsKCAoBCBIDGwA6CgkKAggtEgMbADoKPwoC
BAASBB4AXgEaMyBJbmZvcm1hdGlvbiByZWxhdGVkIHRvIHRoZSBHb29nbGUgQ2xvdWQgcmVz
b3VyY2UuCgoKCgMEAAESAx4IEAqDAQoEBAACABIDIQISGnYgVGhlIGZ1bGwgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgcmVzb3VyY2UuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9h
cGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNmdWxsX3Jlc291cmNlX25hbWUKCgwKBQQAAgAF
EgMhAggKDAoFBAACAAESAyEJDQoMCgUEAAIAAxIDIRARCjcKBAQAAgESAyQCGhoqIFRoZSBo
dW1hbiByZWFkYWJsZSBuYW1lIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQAAgEFEgMkAggKDAoF
BAACAQESAyQJFQoMCgUEAAIBAxIDJBgZCjYKBAQAAgISAycCEhopIFRoZSBmdWxsIHJlc291
cmNlIHR5cGUgb2YgdGhlIHJlc291cmNlLgoKDAoFBAACAgUSAycCCAoMCgUEAAICARIDJwkN
CgwKBQQAAgIDEgMnEBEKTgoEBAACAxIDKgIVGkEgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBv
ZiBwcm9qZWN0IHRoYXQgdGhlIHJlc291cmNlIGJlbG9uZ3MgdG8uCgoMCgUEAAIDBRIDKgII
CgwKBQQAAgMBEgMqCRAKDAoFBAACAwMSAyoTFAo7CgQEAAIEEgMtAiIaLiBUaGUgcHJvamVj
dCBJRCB0aGF0IHRoZSByZXNvdXJjZSBiZWxvbmdzIHRvLgoKDAoFBAACBAUSAy0CCAoMCgUE
AAIEARIDLQkdCgwKBQQAAgQDEgMtICEKOwoEBAACBRIDMAIUGi4gVGhlIGZ1bGwgcmVzb3Vy
Y2UgbmFtZSBvZiByZXNvdXJjZSdzIHBhcmVudC4KCgwKBQQAAgUFEgMwAggKDAoFBAACBQES
AzAJDwoMCgUEAAIFAxIDMBITCjwKBAQAAgYSAzMCIRovIFRoZSBodW1hbiByZWFkYWJsZSBu
YW1lIG9mIHJlc291cmNlJ3MgcGFyZW50LgoKDAoFBAACBgUSAzMCCAoMCgUEAAIGARIDMwkc
CgwKBQQAAgYDEgMzHyAK0gEKBAQAAgcSAzgCShrEASBPdXRwdXQgb25seS4gQ29udGFpbnMg
YSBGb2xkZXIgbWVzc2FnZSBmb3IgZWFjaCBmb2xkZXIgaW4gdGhlIGFzc2V0cwogYW5jZXN0
cnkuIFRoZSBmaXJzdCBmb2xkZXIgaXMgdGhlIGRlZXBlc3QgbmVzdGVkIGZvbGRlciwgYW5k
IHRoZSBsYXN0CiBmb2xkZXIgaXMgdGhlIGZvbGRlciBkaXJlY3RseSB1bmRlciB0aGUgT3Jn
YW5pemF0aW9uLgoKDAoFBAACBwQSAzgCCgoMCgUEAAIHBhIDOAsRCgwKBQQAAgcBEgM4EhkK
DAoFBAACBwMSAzgcHQoMCgUEAAIHCBIDOB5JCg8KCAQAAgcInAgAEgM4H0gKRgoEBAACCBID
OwIjGjkgSW5kaWNhdGVzIHdoaWNoIGNsb3VkIHByb3ZpZGVyIHRoZSByZXNvdXJjZSByZXNp
ZGVzIGluLgoKDAoFBAACCAYSAzsCDwoMCgUEAAIIARIDOxAeCgwKBQQAAggDEgM7ISIKZAoE
BAACCRIDPwIbGlcgSW5kaWNhdGVzIHdoaWNoIG9yZ2FuaXphdGlvbiBvciB0ZW5hbnQgaW4g
dGhlIGNsb3VkIHByb3ZpZGVyIHRoZSBmaW5kaW5nCiBhcHBsaWVzIHRvLgoKDAoFBAACCQUS
Az8CCAoMCgUEAAIJARIDPwkVCgwKBQQAAgkDEgM/GBoKawoEBAACChIDQwIWGl4gVGhlIHBh
cmVudCBzZXJ2aWNlIG9yIHByb2R1Y3QgZnJvbSB3aGljaCB0aGUgcmVzb3VyY2UgaXMgcHJv
dmlkZWQsIGZvcgogZXhhbXBsZSwgR0tFIG9yIFNOUy4KCgwKBQQAAgoFEgNDAggKDAoFBAAC
CgESA0MJEAoMCgUEAAIKAxIDQxMVCkUKBAQAAgsSA0YCFxo4IFRoZSByZWdpb24gb3IgbG9j
YXRpb24gb2YgdGhlIHNlcnZpY2UgKGlmIGFwcGxpY2FibGUpLgoKDAoFBAACCwUSA0YCCAoM
CgUEAAILARIDRgkRCgwKBQQAAgsDEgNGFBYKDAoEBAAIABIESAJOAwoMCgUEAAgAARIDSAgf
CjwKBAQAAgwSA0oEIhovIFRoZSBBV1MgbWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIHRoZSBm
aW5kaW5nLgoKDAoFBAACDAYSA0oEDwoMCgUEAAIMARIDShAcCgwKBQQAAgwDEgNKHyEKPgoE
BAACDRIDTQQmGjEgVGhlIEF6dXJlIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmlu
ZGluZy4KCgwKBQQAAg0GEgNNBBEKDAoFBAACDQESA00SIAoMCgUEAAINAxIDTSMlCk8KBAQA
Ag4SA1ECIhpCIFByb3ZpZGVzIHRoZSBwYXRoIHRvIHRoZSByZXNvdXJjZSB3aXRoaW4gdGhl
IHJlc291cmNlIGhpZXJhcmNoeS4KCgwKBQQAAg4GEgNRAg4KDAoFBAACDgESA1EPHAoMCgUE
AAIOAxIDUR8hCvEECgQEAAIPEgNdAiMa4wQgQSBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2Yg
dGhlIHJlc291cmNlIHBhdGguCiBGb3IgR29vZ2xlIENsb3VkLCBpdCBoYXMgdGhlIGZvcm1h
dCBvZgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vZm9sZGVycy97Zm9sZGVy
X2lkfS9mb2xkZXJzL3tmb2xkZXJfaWR9L3Byb2plY3RzL3twcm9qZWN0X2lkfWAKIHdoZXJl
IHRoZXJlIGNhbiBiZSBhbnkgbnVtYmVyIG9mIGZvbGRlcnMuCiBGb3IgQVdTLCBpdCBoYXMg
dGhlIGZvcm1hdCBvZgogYG9yZy97b3JnYW5pemF0aW9uX2lkfS9vdS97b3JnYW5pemF0aW9u
YWxfdW5pdF9pZH0vb3Uve29yZ2FuaXphdGlvbmFsX3VuaXRfaWR9L2FjY291bnQve2FjY291
bnRfaWR9YAogd2hlcmUgdGhlcmUgY2FuIGJlIGFueSBudW1iZXIgb2Ygb3JnYW5pemF0aW9u
YWwgdW5pdHMuCiBGb3IgQXp1cmUsIGl0IGhhcyB0aGUgZm9ybWF0IG9mCiBgbWcve21hbmFn
ZW1lbnRfZ3JvdXBfaWR9L21nL3ttYW5hZ2VtZW50X2dyb3VwX2lkfS9zdWJzY3JpcHRpb24v
e3N1YnNjcmlwdGlvbl9pZH0vcmcve3Jlc291cmNlX2dyb3VwX25hbWV9YAogd2hlcmUgdGhl
cmUgY2FuIGJlIGFueSBudW1iZXIgb2YgbWFuYWdlbWVudCBncm91cHMuCgoMCgUEAAIPBRID
XQIICgwKBQQAAg8BEgNdCR0KDAoFBAACDwMSA10gIgppCgIFABIEYgBuARpdIEVudW1lcmF0
aW9uIHJlcHJlc2VudGluZyB0aGUgdmFyaW91cyBjbG91ZCBwcm92aWRlcnMgYSBmaW5kaW5n
J3MgcmVzb3VyY2UKIGNvdWxkIHJlc2lkZSBpbi4KCgoKAwUAARIDYgUSCjEKBAUAAgASA2QC
IRokIFRoZSBjbG91ZCBwcm92aWRlciBpcyB1bnNwZWNpZmllZC4KCgwKBQUAAgABEgNkAhwK
DAoFBQACAAISA2QfIAo7CgQFAAIBEgNnAhwaLiBUaGUgY2xvdWQgcHJvdmlkZXIgaXMgR29v
Z2xlIENsb3VkIFBsYXRmb3JtLgoKDAoFBQACAQESA2cCFwoMCgUFAAIBAhIDZxobCjkKBAUA
AgISA2oCGhosIFRoZSBjbG91ZCBwcm92aWRlciBpcyBBbWF6b24gV2ViIFNlcnZpY2VzLgoK
DAoFBQACAgESA2oCFQoMCgUFAAICAhIDahgZCjUKBAUAAgMSA20CFhooIFRoZSBjbG91ZCBw
cm92aWRlciBpcyBNaWNyb3NvZnQgQXp1cmUuCgoMCgUFAAIDARIDbQIRCgwKBQUAAgMCEgNt
FBUKggEKAgQBEgVyAJ4BARp1IEFXUyBtZXRhZGF0YSBhc3NvY2lhdGVkIHdpdGggdGhlIHJl
c291cmNlLCBvbmx5IGFwcGxpY2FibGUgaWYgdGhlIGZpbmRpbmcncwogY2xvdWQgcHJvdmlk
ZXIgaXMgQW1hem9uIFdlYiBTZXJ2aWNlcy4KCgoKAwQBARIDcggTCtYBCgQEAQMAEgR2AnsD
GscBIEFuIG9yZ2FuaXphdGlvbiBpcyBhIGNvbGxlY3Rpb24gb2YgYWNjb3VudHMgdGhhdCBh
cmUgY2VudHJhbGx5IG1hbmFnZWQKIHRvZ2V0aGVyIHVzaW5nIGNvbnNvbGlkYXRlZCBiaWxs
aW5nLCBvcmdhbml6ZWQgaGllcmFyY2hpY2FsbHkgd2l0aAogb3JnYW5pemF0aW9uYWwgdW5p
dHMgKE9VcyksIGFuZCBjb250cm9sbGVkIHdpdGggcG9saWNpZXMuCgoMCgUEAQMAARIDdgoZ
CrkBCgYEAQMAAgASA3oEEhqpASBUaGUgdW5pcXVlIGlkZW50aWZpZXIgKElEKSBmb3IgdGhl
IG9yZ2FuaXphdGlvbi4gVGhlIHJlZ2V4IHBhdHRlcm4gZm9yIGFuCiBvcmdhbml6YXRpb24g
SUQgc3RyaW5nIHJlcXVpcmVzICJvLSIgZm9sbG93ZWQgYnkgZnJvbSAxMCB0byAzMiBsb3dl
cmNhc2UKIGxldHRlcnMgb3IgZGlnaXRzLgoKDgoHBAEDAAIABRIDegQKCg4KBwQBAwACAAES
A3oLDQoOCgcEAQMAAgADEgN6EBEK1gEKBAQBAwESBoABAooBAxrFASBBbiBPcmdhbml6YXRp
b25hbCBVbml0IChPVSkgaXMgYSBjb250YWluZXIgb2YgQVdTIGFjY291bnRzIHdpdGhpbiBh
IHJvb3Qgb2YKIGFuIG9yZ2FuaXphdGlvbi4gUG9saWNpZXMgdGhhdCBhcmUgYXR0YWNoZWQg
dG8gYW4gT1UgYXBwbHkgdG8gYWxsIGFjY291bnRzCiBjb250YWluZWQgaW4gdGhhdCBPVSBh
bmQgaW4gYW55IGNoaWxkIE9Vcy4KCg0KBQQBAwEBEgSAAQofCvcCCgYEAQMBAgASBIYBBBIa
5gIgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIChJRCkgYXNzb2NpYXRlZCB3aXRoIHRoaXMgT1Uu
IFRoZSByZWdleCBwYXR0ZXJuIGZvcgogYW4gb3JnYW5pemF0aW9uYWwgdW5pdCBJRCBzdHJp
bmcgcmVxdWlyZXMgIm91LSIgZm9sbG93ZWQgYnkgZnJvbSA0IHRvIDMyCiBsb3dlcmNhc2Ug
bGV0dGVycyBvciBkaWdpdHMgKHRoZSBJRCBvZiB0aGUgcm9vdCB0aGF0IGNvbnRhaW5zIHRo
ZSBPVSkuCiBUaGlzIHN0cmluZyBpcyBmb2xsb3dlZCBieSBhIHNlY29uZCAiLSIgZGFzaCBh
bmQgZnJvbSA4IHRvIDMyIGFkZGl0aW9uYWwKIGxvd2VyY2FzZSBsZXR0ZXJzIG9yIGRpZ2l0
cy4gRm9yIGV4YW1wbGUsICJvdS1hYjEyLWNkMzRlZjU2Ii4KCg8KBwQBAwECAAUSBIYBBAoK
DwoHBAEDAQIAARIEhgELDQoPCgcEAQMBAgADEgSGARARCi4KBgQBAwECARIEiQEEFBoeIFRo
ZSBmcmllbmRseSBuYW1lIG9mIHRoZSBPVS4KCg8KBwQBAwECAQUSBIkBBAoKDwoHBAEDAQIB
ARIEiQELDwoPCgcEAQMBAgEDEgSJARITCkUKBAQBAwISBo0BApMBAxo1IEFuIEFXUyBhY2Nv
dW50IHRoYXQgaXMgYSBtZW1iZXIgb2YgYW4gb3JnYW5pemF0aW9uLgoKDQoFBAEDAgESBI0B
ChQKWgoGBAEDAgIAEgSPAQQSGkogVGhlIHVuaXF1ZSBpZGVudGlmaWVyIChJRCkgb2YgdGhl
IGFjY291bnQsIGNvbnRhaW5pbmcgZXhhY3RseSAxMiBkaWdpdHMuCgoPCgcEAQMCAgAFEgSP
AQQKCg8KBwQBAwICAAESBI8BCw0KDwoHBAEDAgIAAxIEjwEQEQo0CgYEAQMCAgESBJIBBBQa
JCBUaGUgZnJpZW5kbHkgbmFtZSBvZiB0aGlzIGFjY291bnQuCgoPCgcEAQMCAgEFEgSSAQQK
Cg8KBwQBAwICAQESBJIBCw8KDwoHBAEDAgIBAxIEkgESEwpCCgQEAQIAEgSWAQIjGjQgVGhl
IEFXUyBvcmdhbml6YXRpb24gYXNzb2NpYXRlZCB3aXRoIHRoZSByZXNvdXJjZS4KCg0KBQQB
AgAGEgSWAQIRCg0KBQQBAgABEgSWARIeCg0KBQQBAgADEgSWASEiCpcBCgQEAQIBEgSaAQI6
GogBIEEgbGlzdCBvZiBBV1Mgb3JnYW5pemF0aW9uYWwgdW5pdHMgYXNzb2NpYXRlZCB3aXRo
IHRoZSByZXNvdXJjZSwgb3JkZXJlZAogZnJvbSBsb3dlc3QgbGV2ZWwgKGNsb3Nlc3QgdG8g
dGhlIGFjY291bnQpIHRvIGhpZ2hlc3QgbGV2ZWwuCgoNCgUEAQIBBBIEmgECCgoNCgUEAQIB
BhIEmgELIAoNCgUEAQIBARIEmgEhNQoNCgUEAQIBAxIEmgE4OQo9CgQEAQICEgSdAQIZGi8g
VGhlIEFXUyBhY2NvdW50IGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuCgoNCgUEAQIC
BhIEnQECDAoNCgUEAQICARIEnQENFAoNCgUEAQICAxIEnQEXGAqBAQoCBAISBqIBAMYBARpz
IEF6dXJlIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UsIG9ubHkgYXBw
bGljYWJsZSBpZiB0aGUgZmluZGluZydzCiBjbG91ZCBwcm92aWRlciBpcyBNaWNyb3NvZnQg
QXp1cmUuCgoLCgMEAgESBKIBCBUKNwoEBAIDABIGpAECqwEDGicgUmVwcmVzZW50cyBhbiBB
enVyZSBtYW5hZ2VtZW50IGdyb3VwLgoKDQoFBAIDAAESBKQBCh4KbwoGBAIDAAIAEgSnAQQS
Gl8gVGhlIFVVSUQgb2YgdGhlIEF6dXJlIG1hbmFnZW1lbnQgZ3JvdXAsIGZvciBleGFtcGxl
LAogYDIwMDAwMDAwLTAwMDEtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMGAuCgoPCgcEAgMAAgAF
EgSnAQQKCg8KBwQCAwACAAESBKcBCw0KDwoHBAIDAAIAAxIEpwEQEQpBCgYEAgMAAgESBKoB
BBwaMSBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBBenVyZSBtYW5hZ2VtZW50IGdyb3VwLgoK
DwoHBAIDAAIBBRIEqgEECgoPCgcEAgMAAgEBEgSqAQsXCg8KBwQCAwACAQMSBKoBGhsKMwoE
BAIDARIGrgECtQEDGiMgUmVwcmVzZW50cyBhbiBBenVyZSBzdWJzY3JpcHRpb24uCgoNCgUE
AgMBARIErgEKGwprCgYEAgMBAgASBLEBBBIaWyBUaGUgVVVJRCBvZiB0aGUgQXp1cmUgc3Vi
c2NyaXB0aW9uLCBmb3IgZXhhbXBsZSwKIGAyOTFiYmEzZi1lMGE1LTQ3YmMtYTA5OS0zYmRj
YjJhNTBhMDVgLgoKDwoHBAIDAQIABRIEsQEECgoPCgcEAgMBAgABEgSxAQsNCg8KBwQCAwEC
AAMSBLEBEBEKPQoGBAIDAQIBEgS0AQQcGi0gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgQXp1
cmUgc3Vic2NyaXB0aW9uLgoKDwoHBAIDAQIBBRIEtAEECgoPCgcEAgMBAgEBEgS0AQsXCg8K
BwQCAwECAQMSBLQBGhsKNQoEBAIDAhIGuAECuwEDGiUgUmVwcmVzZW50cyBhbiBBenVyZSBy
ZXNvdXJjZSBncm91cC4KCg0KBQQCAwIBEgS4AQocCksKBgQCAwICABIEugEEFBo7IFRoZSBu
YW1lIG9mIHRoZSBBenVyZSByZXNvdXJjZSBncm91cC4gVGhpcyBpcyBub3QgYSBVVUlELgoK
DwoHBAIDAgIABRIEugEECgoPCgcEAgMCAgABEgS6AQsPCg8KBwQCAwICAAMSBLoBEhMKmwEK
BAQCAgASBL8BAjYajAEgQSBsaXN0IG9mIEF6dXJlIG1hbmFnZW1lbnQgZ3JvdXBzIGFzc29j
aWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UsIG9yZGVyZWQKIGZyb20gbG93ZXN0IGxldmVsIChj
bG9zZXN0IHRvIHRoZSBzdWJzY3JpcHRpb24pIHRvIGhpZ2hlc3QgbGV2ZWwuCgoNCgUEAgIA
BBIEvwECCgoNCgUEAgIABhIEvwELHwoNCgUEAgIAARIEvwEgMQoNCgUEAgIAAxIEvwE0NQpE
CgQEAgIBEgTCAQIlGjYgVGhlIEF6dXJlIHN1YnNjcmlwdGlvbiBhc3NvY2lhdGVkIHdpdGgg
dGhlIHJlc291cmNlLgoKDQoFBAICAQYSBMIBAhMKDQoFBAICAQESBMIBFCAKDQoFBAICAQMS
BMIBIyQKRgoEBAICAhIExQECKBo4IFRoZSBBenVyZSByZXNvdXJjZSBncm91cCBhc3NvY2lh
dGVkIHdpdGggdGhlIHJlc291cmNlLgoKDQoFBAICAgYSBMUBAhQKDQoFBAICAgESBMUBFSMK
DQoFBAICAgMSBMUBJicKYwoCBAMSBsoBAPwBARpVIFJlcHJlc2VudHMgdGhlIHBhdGggb2Yg
cmVzb3VyY2VzIGxlYWRpbmcgdXAgdG8gdGhlIHJlc291cmNlIHRoaXMgZmluZGluZyBpcwog
YWJvdXQuCgoLCgMEAwESBMoBCBQKOwoEBAMEABIGzAEC6gEDGisgVGhlIHR5cGUgb2YgcmVz
b3VyY2UgdGhlIG5vZGUgcmVwcmVzZW50cy4KCg0KBQQDBAABEgTMAQcbCisKBgQDBAACABIE
zgEELBobIE5vZGUgdHlwZSBpcyB1bnNwZWNpZmllZC4KCg8KBwQDBAACAAESBM4BBCcKDwoH
BAMEAAIAAhIEzgEqKwpCCgYEAwQAAgESBNEBBBkaMiBUaGUgbm9kZSByZXByZXNlbnRzIGEg
R29vZ2xlIENsb3VkIG9yZ2FuaXphdGlvbi4KCg8KBwQDBAACAQESBNEBBBQKDwoHBAMEAAIB
AhIE0QEXGAo8CgYEAwQAAgISBNQBBBMaLCBUaGUgbm9kZSByZXByZXNlbnRzIGEgR29vZ2xl
IENsb3VkIGZvbGRlci4KCg8KBwQDBAACAgESBNQBBA4KDwoHBAMEAAICAhIE1AEREgo9CgYE
AwQAAgMSBNcBBBQaLSBUaGUgbm9kZSByZXByZXNlbnRzIGEgR29vZ2xlIENsb3VkIHByb2pl
Y3QuCgoPCgcEAwQAAgMBEgTXAQQPCg8KBwQDBAACAwISBNcBEhMKOgoGBAMEAAIEEgTaAQQZ
GiogVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBBV1Mgb3JnYW5pemF0aW9uLgoKDwoHBAMEAAIE
ARIE2gEEFAoPCgcEAwQAAgQCEgTaARcYCkEKBgQDBAACBRIE3QEEIBoxIFRoZSBub2RlIHJl
cHJlc2VudHMgYW4gQVdTIG9yZ2FuaXphdGlvbmFsIHVuaXQuCgoPCgcEAwQAAgUBEgTdAQQb
Cg8KBwQDBAACBQISBN0BHh8KNQoGBAMEAAIGEgTgAQQUGiUgVGhlIG5vZGUgcmVwcmVzZW50
cyBhbiBBV1MgYWNjb3VudC4KCg8KBwQDBAACBgESBOABBA8KDwoHBAMEAAIGAhIE4AESEwpA
CgYEAwQAAgcSBOMBBB8aMCBUaGUgbm9kZSByZXByZXNlbnRzIGFuIEF6dXJlIG1hbmFnZW1l
bnQgZ3JvdXAuCgoPCgcEAwQAAgcBEgTjAQQaCg8KBwQDBAACBwISBOMBHR4KPAoGBAMEAAII
EgTmAQQbGiwgVGhlIG5vZGUgcmVwcmVzZW50cyBhbiBBenVyZSBzdWJzY3JpcHRpb24uCgoP
CgcEAwQAAggBEgTmAQQWCg8KBwQDBAACCAISBOYBGRoKPgoGBAMEAAIJEgTpAQQdGi4gVGhl
IG5vZGUgcmVwcmVzZW50cyBhbiBBenVyZSByZXNvdXJjZSBncm91cC4KCg8KBwQDBAACCQES
BOkBBBgKDwoHBAMEAAIJAhIE6QEbHApyCgQEAwMAEgbuAQL3AQMaYiBBIG5vZGUgd2l0aGlu
IHRoZSByZXNvdXJjZSBwYXRoLiBFYWNoIG5vZGUgcmVwcmVzZW50cyBhIHJlc291cmNlIHdp
dGhpbiB0aGUKIHJlc291cmNlIGhpZXJhcmNoeS4KCg0KBQQDAwABEgTuAQoaCjwKBgQDAwAC
ABIE8AEEJxosIFRoZSB0eXBlIG9mIHJlc291cmNlIHRoaXMgbm9kZSByZXByZXNlbnRzLgoK
DwoHBAMDAAIABhIE8AEEGAoPCgcEAwMAAgABEgTwARkiCg8KBwQDAwACAAMSBPABJSYKPgoG
BAMDAAIBEgTzAQQSGi4gVGhlIElEIG9mIHRoZSByZXNvdXJjZSB0aGlzIG5vZGUgcmVwcmVz
ZW50cy4KCg8KBwQDAwACAQUSBPMBBAoKDwoHBAMDAAIBARIE8wELDQoPCgcEAwMAAgEDEgTz
ARARCkgKBgQDAwACAhIE9gEEHBo4IFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHJlc291cmNl
IHRoaXMgbm9kZSByZXByZXNlbnRzLgoKDwoHBAMDAAICBRIE9gEECgoPCgcEAwMAAgIBEgT2
AQsXCg8KBwQDAwACAgMSBPYBGhsKbgoEBAMCABIE+wECJhpgIFRoZSBsaXN0IG9mIG5vZGVz
IHRoYXQgbWFrZSB0aGUgdXAgcmVzb3VyY2UgcGF0aCwgb3JkZXJlZCBmcm9tIGxvd2VzdAog
bGV2ZWwgdG8gaGlnaGVzdCBsZXZlbC4KCg0KBQQDAgAEEgT7AQIKCg0KBQQDAgAGEgT7AQsb
Cg0KBQQDAgABEgT7ARwhCg0KBQQDAgADEgT7ASQlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Resource::Resource ===
    # Fields for Resource
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: project Type: 9 ()
    # Field: project_display_name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: parent_display_name Type: 9 ()
    # Field: folders Type: 11 (.google.cloud.securitycenter.v1.Folder)
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v1.CloudProvider)
    # Field: organization Type: 9 ()
    # Field: service Type: 9 ()
    # Field: location Type: 9 ()
    # Field: aws_metadata Type: 11 (.google.cloud.securitycenter.v1.AwsMetadata)
    # Field: azure_metadata Type: 11 (.google.cloud.securitycenter.v1.AzureMetadata)
    # Field: resource_path Type: 11 (.google.cloud.securitycenter.v1.ResourcePath)
    # Field: resource_path_string Type: 9 ()

# === Message: Google::Cloud::Securitycenter::V1::Resource::AwsMetadata ===
    # Fields for AwsMetadata
    # Field: organization Type: 11 (.google.cloud.securitycenter.v1.AwsMetadata.AwsOrganization)
    # Field: organizational_units Type: 11 (.google.cloud.securitycenter.v1.AwsMetadata.AwsOrganizationalUnit)
    # Field: account Type: 11 (.google.cloud.securitycenter.v1.AwsMetadata.AwsAccount)

# === Message: Google::Cloud::Securitycenter::V1::Resource::AzureMetadata ===
    # Fields for AzureMetadata
    # Field: management_groups Type: 11 (.google.cloud.securitycenter.v1.AzureMetadata.AzureManagementGroup)
    # Field: subscription Type: 11 (.google.cloud.securitycenter.v1.AzureMetadata.AzureSubscription)
    # Field: resource_group Type: 11 (.google.cloud.securitycenter.v1.AzureMetadata.AzureResourceGroup)

# === Message: Google::Cloud::Securitycenter::V1::Resource::ResourcePath ===
    # Fields for ResourcePath
    # Field: nodes Type: 11 (.google.cloud.securitycenter.v1.ResourcePath.ResourcePathNode)

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

Google::Cloud::Securitycenter::V1::Resource - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Resource;

    my $msg = Google::Cloud::Securitycenter::V1::Resource::Resource->new({
        name => $name,
        display_name => $display_name,
        type => $type,
        project => $project,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Resource::Resource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Resource::Resource

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Folder::Folder>)

Output only. Contains a Folder message for each folder in the assets
ancestry. The first folder is the deepest nested folder, and the last
folder is the folder directly under the Organization.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::CloudProvider>)

Indicates which cloud provider the resource resides in.

=item * C<< $msg->organization() >> / C<< $msg->organization($value) >>

Type: C<String>

Indicates which organization or tenant in the cloud provider the finding
applies to.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The parent service or product from which the resource is provided, for
example, GKE or SNS.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The region or location of the service (if applicable).

=item * C<< $msg->aws_metadata() >> / C<< $msg->aws_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AwsMetadata>)

The AWS metadata associated with the finding.

=item * C<< $msg->azure_metadata() >> / C<< $msg->azure_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AzureMetadata>)

The Azure metadata associated with the finding.

=item * C<< $msg->resource_path() >> / C<< $msg->resource_path($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::ResourcePath>)

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

=head2 Google::Cloud::Securitycenter::V1::Resource::AwsMetadata

AWS metadata associated with the resource, only applicable if the finding's
cloud provider is Amazon Web Services.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->organization() >> / C<< $msg->organization($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AwsMetadata::AwsOrganization>)

The AWS organization associated with the resource.

=item * C<< $msg->organizational_units() >> / C<< $msg->organizational_units($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AwsMetadata::AwsOrganizationalUnit>)

A list of AWS organizational units associated with the resource, ordered
from lowest level (closest to the account) to highest level.

=item * C<< $msg->account() >> / C<< $msg->account($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AwsMetadata::AwsAccount>)

The AWS account associated with the resource.

=back

=head2 Google::Cloud::Securitycenter::V1::Resource::AzureMetadata

Azure metadata associated with the resource, only applicable if the finding's
cloud provider is Microsoft Azure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->management_groups() >> / C<< $msg->management_groups($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AzureMetadata::AzureManagementGroup>)

A list of Azure management groups associated with the resource, ordered
from lowest level (closest to the subscription) to highest level.

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AzureMetadata::AzureSubscription>)

The Azure subscription associated with the resource.

=item * C<< $msg->resource_group() >> / C<< $msg->resource_group($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::AzureMetadata::AzureResourceGroup>)

The Azure resource group associated with the resource.

=back

=head2 Google::Cloud::Securitycenter::V1::Resource::ResourcePath

Represents the path of resources leading up to the resource this finding is
about.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodes() >> / C<< $msg->nodes($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::ResourcePath::ResourcePathNode>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
