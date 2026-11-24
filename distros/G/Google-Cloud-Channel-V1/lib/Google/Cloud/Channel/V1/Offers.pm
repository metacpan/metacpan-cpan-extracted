package Google::Cloud::Channel::V1::Offers;

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
    eval { require Google::Cloud::Channel::V1::Common };
    eval { require Google::Cloud::Channel::V1::Products };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Money };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9vZmZlcnMucHJvdG8SF2dvb2dsZS5jbG91ZC5j
aGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jb21tb24ucHJvdG8a
Jmdvb2dsZS9jbG91ZC9jaGFubmVsL3YxL3Byb2R1Y3RzLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvdHlwZS9tb25leS5wcm90byKvBQoFT2ZmZXIS
EgoEbmFtZRgBIAEoCVIEbmFtZRJNCg5tYXJrZXRpbmdfaW5mbxgCIAEoCzImLmdvb2dsZS5j
bG91ZC5jaGFubmVsLnYxLk1hcmtldGluZ0luZm9SDW1hcmtldGluZ0luZm8SLgoDc2t1GAMg
ASgLMhwuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuU2t1UgNza3USMQoEcGxhbhgEIAEoCzId
Lmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlBsYW5SBHBsYW4SRgoLY29uc3RyYWludHMYBSAB
KAsyJC5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5Db25zdHJhaW50c1ILY29uc3RyYWludHMS
VgoScHJpY2VfYnlfcmVzb3VyY2VzGAYgAygLMiguZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEu
UHJpY2VCeVJlc291cmNlUhBwcmljZUJ5UmVzb3VyY2VzEjkKCnN0YXJ0X3RpbWUYByABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRpbWUSOgoIZW5kX3RpbWUYCCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSYQoVcGFyYW1l
dGVyX2RlZmluaXRpb25zGAkgAygLMiwuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUGFyYW1l
dGVyRGVmaW5pdGlvblIUcGFyYW1ldGVyRGVmaW5pdGlvbnMSGwoJZGVhbF9jb2RlGAwgASgJ
UghkZWFsQ29kZTpJ6kFGCiFjbG91ZGNoYW5uZWwuZ29vZ2xlYXBpcy5jb20vT2ZmZXISIWFj
Y291bnRzL3thY2NvdW50fS9vZmZlcnMve29mZmVyfSLKAwoTUGFyYW1ldGVyRGVmaW5pdGlv
bhISCgRuYW1lGAEgASgJUgRuYW1lEmEKDnBhcmFtZXRlcl90eXBlGAIgASgOMjouZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuUGFyYW1ldGVyRGVmaW5pdGlvbi5QYXJhbWV0ZXJUeXBlUg1w
YXJhbWV0ZXJUeXBlEjsKCW1pbl92YWx1ZRgDIAEoCzIeLmdvb2dsZS5jbG91ZC5jaGFubmVs
LnYxLlZhbHVlUghtaW5WYWx1ZRI7CgltYXhfdmFsdWUYBCABKAsyHi5nb29nbGUuY2xvdWQu
Y2hhbm5lbC52MS5WYWx1ZVIIbWF4VmFsdWUSRQoOYWxsb3dlZF92YWx1ZXMYBSADKAsyHi5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5WYWx1ZVINYWxsb3dlZFZhbHVlcxIaCghvcHRpb25h
bBgGIAEoCFIIb3B0aW9uYWwiXwoNUGFyYW1ldGVyVHlwZRIeChpQQVJBTUVURVJfVFlQRV9V
TlNQRUNJRklFRBAAEgkKBUlOVDY0EAESCgoGU1RSSU5HEAISCgoGRE9VQkxFEAMSCwoHQk9P
TEVBThAEIm4KC0NvbnN0cmFpbnRzEl8KFGN1c3RvbWVyX2NvbnN0cmFpbnRzGAEgASgLMiwu
Z29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuQ3VzdG9tZXJDb25zdHJhaW50c1ITY3VzdG9tZXJD
b25zdHJhaW50cyKUAgoTQ3VzdG9tZXJDb25zdHJhaW50cxInCg9hbGxvd2VkX3JlZ2lvbnMY
ASADKAlSDmFsbG93ZWRSZWdpb25zEm0KFmFsbG93ZWRfY3VzdG9tZXJfdHlwZXMYAiADKA4y
Ny5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5DbG91ZElkZW50aXR5SW5mby5DdXN0b21lclR5
cGVSFGFsbG93ZWRDdXN0b21lclR5cGVzEmUKF3Byb21vdGlvbmFsX29yZGVyX3R5cGVzGAMg
AygOMi0uZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUHJvbW90aW9uYWxPcmRlclR5cGVSFXBy
b21vdGlvbmFsT3JkZXJUeXBlcyLLAgoEUGxhbhJHCgxwYXltZW50X3BsYW4YASABKA4yJC5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5QYXltZW50UGxhblILcGF5bWVudFBsYW4SRwoMcGF5
bWVudF90eXBlGAIgASgOMiQuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUGF5bWVudFR5cGVS
C3BheW1lbnRUeXBlEkQKDXBheW1lbnRfY3ljbGUYAyABKAsyHy5nb29nbGUuY2xvdWQuY2hh
bm5lbC52MS5QZXJpb2RSDHBheW1lbnRDeWNsZRJCCgx0cmlhbF9wZXJpb2QYBCABKAsyHy5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5QZXJpb2RSC3RyaWFsUGVyaW9kEicKD2JpbGxpbmdf
YWNjb3VudBgFIAEoCVIOYmlsbGluZ0FjY291bnQi2wEKD1ByaWNlQnlSZXNvdXJjZRJKCg1y
ZXNvdXJjZV90eXBlGAEgASgOMiUuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUmVzb3VyY2VU
eXBlUgxyZXNvdXJjZVR5cGUSNAoFcHJpY2UYAiABKAsyHi5nb29nbGUuY2xvdWQuY2hhbm5l
bC52MS5QcmljZVIFcHJpY2USRgoMcHJpY2VfcGhhc2VzGAMgAygLMiMuZ29vZ2xlLmNsb3Vk
LmNoYW5uZWwudjEuUHJpY2VQaGFzZVILcHJpY2VQaGFzZXMi4gIKBVByaWNlEjEKCmJhc2Vf
cHJpY2UYASABKAsyEi5nb29nbGUudHlwZS5Nb25leVIJYmFzZVByaWNlEhoKCGRpc2NvdW50
GAIgASgBUghkaXNjb3VudBI7Cg9lZmZlY3RpdmVfcHJpY2UYAyABKAsyEi5nb29nbGUudHlw
ZS5Nb25leVIOZWZmZWN0aXZlUHJpY2USQgoMcHJpY2VfcGVyaW9kGAYgASgLMh8uZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuUGVyaW9kUgtwcmljZVBlcmlvZBIsChJleHRlcm5hbF9wcmlj
ZV91cmkYBCABKAlSEGV4dGVybmFsUHJpY2VVcmkSWwoTZGlzY291bnRfY29tcG9uZW50cxgF
IAMoCzIqLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkRpc2NvdW50Q29tcG9uZW50UhJkaXNj
b3VudENvbXBvbmVudHMikQIKClByaWNlUGhhc2USRAoLcGVyaW9kX3R5cGUYASABKA4yIy5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5QZXJpb2RUeXBlUgpwZXJpb2RUeXBlEiEKDGZpcnN0
X3BlcmlvZBgCIAEoBVILZmlyc3RQZXJpb2QSHwoLbGFzdF9wZXJpb2QYAyABKAVSCmxhc3RQ
ZXJpb2QSNAoFcHJpY2UYBCABKAsyHi5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5QcmljZVIF
cHJpY2USQwoLcHJpY2VfdGllcnMYBSADKAsyIi5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5Q
cmljZVRpZXJSCnByaWNlVGllcnMijQEKCVByaWNlVGllchIlCg5maXJzdF9yZXNvdXJjZRgB
IAEoBVINZmlyc3RSZXNvdXJjZRIjCg1sYXN0X3Jlc291cmNlGAIgASgFUgxsYXN0UmVzb3Vy
Y2USNAoFcHJpY2UYAyABKAsyHi5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5QcmljZVIFcHJp
Y2UiagoGUGVyaW9kEhoKCGR1cmF0aW9uGAEgASgFUghkdXJhdGlvbhJECgtwZXJpb2RfdHlw
ZRgCIAEoDjIjLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlBlcmlvZFR5cGVSCnBlcmlvZFR5
cGUi5wEKEURpc2NvdW50Q29tcG9uZW50EjEKE2Rpc2NvdW50X3BlcmNlbnRhZ2UYAyABKAFI
AFISZGlzY291bnRQZXJjZW50YWdlEkEKEWRpc2NvdW50X2Fic29sdXRlGAQgASgLMhIuZ29v
Z2xlLnR5cGUuTW9uZXlIAFIQZGlzY291bnRBYnNvbHV0ZRJKCg1kaXNjb3VudF90eXBlGAIg
ASgOMiUuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuRGlzY291bnRUeXBlUgxkaXNjb3VudFR5
cGVCEAoOZGlzY291bnRfdmFsdWUqbQoUUHJvbW90aW9uYWxPcmRlclR5cGUSIAocUFJPTU9U
SU9OQUxfVFlQRV9VTlNQRUNJRklFRBAAEg8KC05FV19VUEdSQURFEAESDAoIVFJBTlNGRVIQ
AhIUChBQUk9NT1RJT05fU1dJVENIEAMqawoLUGF5bWVudFBsYW4SHAoYUEFZTUVOVF9QTEFO
X1VOU1BFQ0lGSUVEEAASDgoKQ09NTUlUTUVOVBABEgwKCEZMRVhJQkxFEAISCAoERlJFRRAD
EgkKBVRSSUFMEAQSCwoHT0ZGTElORRAFKkQKC1BheW1lbnRUeXBlEhwKGFBBWU1FTlRfVFlQ
RV9VTlNQRUNJRklFRBAAEgoKBlBSRVBBWRABEgsKB1BPU1RQQVkQAiqKAQoMUmVzb3VyY2VU
eXBlEh0KGVJFU09VUkNFX1RZUEVfVU5TUEVDSUZJRUQQABIICgRTRUFUEAESBwoDTUFVEAIS
BgoCR0IQAxIRCg1MSUNFTlNFRF9VU0VSEAQSCwoHTUlOVVRFUxAFEg4KCklBQVNfVVNBR0UQ
BhIQCgxTVUJTQ1JJUFRJT04QBypHCgpQZXJpb2RUeXBlEhsKF1BFUklPRF9UWVBFX1VOU1BF
Q0lGSUVEEAASBwoDREFZEAESCQoFTU9OVEgQAhIICgRZRUFSEAMqlgEKDERpc2NvdW50VHlw
ZRIdChlESVNDT1VOVF9UWVBFX1VOU1BFQ0lGSUVEEAASFQoRUkVHSU9OQUxfRElTQ09VTlQQ
ARIYChRQUk9NT1RJT05BTF9ESVNDT1VOVBACEhIKDlNBTEVTX0RJU0NPVU5UEAMSEwoPUkVT
RUxMRVJfTUFSR0lOEAQSDQoJREVBTF9DT0RFEAVCYwobY29tLmdvb2dsZS5jbG91ZC5jaGFu
bmVsLnYxQgtPZmZlcnNQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2NoYW5uZWwvYXBp
djEvY2hhbm5lbHBiO2NoYW5uZWxwYkqoXAoHEgUOAPoCAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQALgoJCgIDAxIDFQAwCgkKAgMEEgMWACkKCQoCAwUSAxcAIQoICgEIEgMZAEwKCQoCCAsS
AxkATAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACwKCQoCCAgSAxsALAoICgEIEgMc
ADQKCQoCCAESAxwANAo2CgIFABIEHwArARoqIENvbnN0cmFpbnRzIHR5cGUgZm9yIFByb21v
dGlvbmFsIG9mZmVycy4KCgoKAwUAARIDHwUZChgKBAUAAgASAyECIxoLIE5vdCB1c2VkLgoK
DAoFBQACAAESAyECHgoMCgUFAAIAAhIDISEiCkwKBAUAAgESAyQCEho/IE9yZGVyIHVzZWQg
Zm9yIG5ldyBjdXN0b21lcnMsIHRyaWFsIGNvbnZlcnNpb25zIGFuZCB1cGdyYWRlcy4KCgwK
BQUAAgEBEgMkAg0KDAoFBQACAQISAyQQEQpACgQFAAICEgMnAg8aMyBBbGwgb3JkZXJzIGZv
ciB0cmFuc2ZlcnJpbmcgYW4gZXhpc3RpbmcgY3VzdG9tZXIuCgoMCgUFAAICARIDJwIKCgwK
BQUAAgICEgMnDQ4KVQoEBQACAxIDKgIXGkggT3JkZXJzIGZvciBtb2RpZnlpbmcgYW4gZXhp
c3RpbmcgY3VzdG9tZXIncyBwcm9tb3Rpb24gb24gdGhlIHNhbWUgU0tVLgoKDAoFBQACAwES
AyoCEgoMCgUFAAIDAhIDKhUWCjgKAgUBEgQuAEABGiwgRGVzY3JpYmVzIGhvdyB0aGUgcmVz
ZWxsZXIgd2lsbCBiZSBiaWxsZWQuCgoKCgMFAQESAy4FEAoYCgQFAQIAEgMwAh8aCyBOb3Qg
dXNlZC4KCgwKBQUBAgABEgMwAhoKDAoFBQECAAISAzAdHgoaCgQFAQIBEgMzAhEaDSBDb21t
aXRtZW50LgoKDAoFBQECAQESAzMCDAoMCgUFAQIBAhIDMw8QCh0KBAUBAgISAzYCDxoQIE5v
IGNvbW1pdG1lbnQuCgoMCgUFAQICARIDNgIKCgwKBQUBAgICEgM2DQ4KFAoEBQECAxIDOQIL
GgcgRnJlZS4KCgwKBQUBAgMBEgM5AgYKDAoFBQECAwISAzkJCgoVCgQFAQIEEgM8AgwaCCBU
cmlhbC4KCgwKBQUBAgQBEgM8AgcKDAoFBQECBAISAzwKCwo8CgQFAQIFEgM/Ag4aLyBQcmlj
ZSBhbmQgb3JkZXJpbmcgbm90IGF2YWlsYWJsZSB0aHJvdWdoIEFQSS4KCgwKBQUBAgUBEgM/
AgkKDAoFBQECBQISAz8MDQo5CgIFAhIEQwBMARotIFNwZWNpZmllcyB3aGVuIHRoZSBwYXlt
ZW50IG5lZWRzIHRvIGhhcHBlbi4KCgoKAwUCARIDQwUQChgKBAUCAgASA0UCHxoLIE5vdCB1
c2VkLgoKDAoFBQICAAESA0UCGgoMCgUFAgIAAhIDRR0eCkgKBAUCAgESA0gCDRo7IFByZXBh
eS4gQW1vdW50IGhhcyB0byBiZSBwYWlkIGJlZm9yZSBzZXJ2aWNlIGlzIHJlbmRlcmVkLgoK
DAoFBQICAQESA0gCCAoMCgUFAgIBAhIDSAsMCkwKBAUCAgISA0sCDho/IFBvc3RwYXkuIFJl
c2VsbGVyIGlzIGNoYXJnZWQgYXQgdGhlIGVuZCBvZiB0aGUgUGF5bWVudCBjeWNsZS4KCgwK
BQUCAgIBEgNLAgkKDAoFBQICAgISA0sMDQrlAQoCBQMSBFEAbAEa2AEgUmVwcmVzZW50cyB0
aGUgdHlwZSBmb3IgYSBtb25ldGl6YWJsZSByZXNvdXJjZShhbnkgZW50aXR5IG9uIHdoaWNo
IGJpbGxpbmcKIGhhcHBlbnMpLiBGb3IgZXhhbXBsZSwgdGhpcyBjb3VsZCBiZSBNSU5VVEVT
IGZvciBHb29nbGUgVm9pY2UgYW5kIEdCIGZvcgogR29vZ2xlIERyaXZlLiBPbmUgU0tVIGNh
biBtYXAgdG8gbXVsdGlwbGUgbW9uZXRpemFibGUgcmVzb3VyY2VzLgoKCgoDBQMBEgNRBREK
GAoEBQMCABIDUwIgGgsgTm90IHVzZWQuCgoMCgUFAwIAARIDUwIbCgwKBQUDAgACEgNTHh8K
FAoEBQMCARIDVgILGgcgU2VhdC4KCgwKBQUDAgEBEgNWAgYKDAoFBQMCAQISA1YJCgojCgQF
AwICEgNZAgoaFiBNb250aGx5IGFjdGl2ZSB1c2VyLgoKDAoFBQMCAgESA1kCBQoMCgUFAwIC
AhIDWQgJCioKBAUDAgMSA1wCCRodIEdCICh1c2VkIGZvciBzdG9yYWdlIFNLVXMpLgoKDAoF
BQMCAwESA1wCBAoMCgUFAwIDAhIDXAcICjUKBAUDAgQSA18CFBooIEFjdGl2ZSBsaWNlbnNl
ZCB1c2Vycyhmb3IgVm9pY2UgU0tVcykuCgoMCgUFAwIEARIDXwIPCgwKBQUDAgQCEgNfEhMK
GwoEBQMCBRIDYgIOGg4gVm9pY2UgdXNhZ2UuCgoMCgUFAwIFARIDYgIJCgwKBQUDAgUCEgNi
DA0KrwIKBAUDAgYSA2gCERqhAiBGb3IgSWFhUyBTS1VzIGxpa2UgR29vZ2xlIENsb3VkLCBt
b25ldGl6YXRpb24gaXMgYmFzZWQgb24gdXNhZ2UgYWNjcnVlZCBvbgogeW91ciBiaWxsaW5n
IGFjY291bnQgaXJyZXNwZWN0aXZlIG9mIHRoZSB0eXBlIG9mIG1vbmV0aXphYmxlIHJlc291
cmNlLiBUaGlzCiBlbnVtIHJlcHJlc2VudHMgYW4gYWdncmVnYXRlZCByZXNvdXJjZS9jb250
YWluZXIgZm9yIGFsbCB1c2FnZSBTS1VzIG9uIGEKIGJpbGxpbmcgYWNjb3VudC4gQ3VycmVu
dGx5LCBvbmx5IGFwcGxpY2FibGUgdG8gR29vZ2xlIENsb3VkLgoKDAoFBQMCBgESA2gCDAoM
CgUFAwIGAhIDaA8QCkEKBAUDAgcSA2sCExo0IEZvciBHb29nbGUgQ2xvdWQgc3Vic2NyaXB0
aW9ucyBsaWtlIEFudGhvcyBvciBTQVAuCgoMCgUFAwIHARIDawIOCgwKBQUDAgcCEgNrERIK
GgoCBQQSBG8AewEaDiBQZXJpb2QgVHlwZS4KCgoKAwUEARIDbwUPChgKBAUEAgASA3ECHhoL
IE5vdCB1c2VkLgoKDAoFBQQCAAESA3ECGQoMCgUFBAIAAhIDcRwdChMKBAUEAgESA3QCChoG
IERheS4KCgwKBQUEAgEBEgN0AgUKDAoFBQQCAQISA3QICQoVCgQFBAICEgN3AgwaCCBNb250
aC4KCgwKBQUEAgIBEgN3AgcKDAoFBQQCAgISA3cKCwoUCgQFBAIDEgN6AgsaByBZZWFyLgoK
DAoFBQQCAwESA3oCBgoMCgUFBAIDAhIDegkKCh0KAgUFEgV+AJABARoQIERpc2NvdW50IFR5
cGUuCgoKCgMFBQESA34FEQoZCgQFBQIAEgSAAQIgGgsgTm90IHVzZWQuCgoNCgUFBQIAARIE
gAECGwoNCgUFBQIAAhIEgAEeHwoiCgQFBQIBEgSDAQIYGhQgUmVnaW9uYWwgZGlzY291bnQu
CgoNCgUFBQIBARIEgwECEwoNCgUFBQIBAhIEgwEWFwolCgQFBQICEgSGAQIbGhcgUHJvbW90
aW9uYWwgZGlzY291bnQuCgoNCgUFBQICARIEhgECFgoNCgUFBQICAhIEhgEZGgooCgQFBQID
EgSJAQIVGhogU2FsZXMtcHJvdmlkZWQgZGlzY291bnQuCgoNCgUFBQIDARIEiQECEAoNCgUF
BQIDAhIEiQETFAogCgQFBQIEEgSMAQIWGhIgUmVzZWxsZXIgbWFyZ2luLgoKDQoFBQUCBAES
BIwBAhEKDQoFBQUCBAISBIwBFBUKIwoEBQUCBRIEjwECEBoVIERlYWwgY29kZSBkaXNjb3Vu
dC4KCg0KBQUFAgUBEgSPAQILCg0KBQUFAgUCEgSPAQ4PCtEBCgIEABIGlQEAugEBGsIBIFJl
cHJlc2VudHMgYW4gb2ZmZXIgbWFkZSB0byByZXNlbGxlcnMgZm9yIHB1cmNoYXNlLgogQW4g
b2ZmZXIgaXMgYXNzb2NpYXRlZCB3aXRoIGEgW1NrdV1bZ29vZ2xlLmNsb3VkLmNoYW5uZWwu
djEuU2t1XSwgaGFzIGEgcGxhbgogZm9yIHBheW1lbnQsIGEgcHJpY2UsIGFuZCBkZWZpbmVz
IHRoZSBjb25zdHJhaW50cyBmb3IgYnV5aW5nLgoKCwoDBAABEgSVAQgNCg0KAwQABxIGlgEC
mQEECg8KBQQAB50IEgaWAQKZAQQKXAoEBAACABIEnQECEhpOIFJlc291cmNlIE5hbWUgb2Yg
dGhlIE9mZmVyLgogRm9ybWF0OiBhY2NvdW50cy97YWNjb3VudF9pZH0vb2ZmZXJzL3tvZmZl
cl9pZH0KCg0KBQQAAgAFEgSdAQIICg0KBQQAAgABEgSdAQkNCg0KBQQAAgADEgSdARARCjQK
BAQAAgESBKABAiMaJiBNYXJrZXRpbmcgaW5mb3JtYXRpb24gZm9yIHRoZSBPZmZlci4KCg0K
BQQAAgEGEgSgAQIPCg0KBQQAAgEBEgSgARAeCg0KBQQAAgEDEgSgASEiCjEKBAQAAgISBKMB
Ag4aIyBTS1UgdGhlIG9mZmVyIGlzIGFzc29jaWF0ZWQgd2l0aC4KCg0KBQQAAgIGEgSjAQIF
Cg0KBQQAAgIBEgSjAQYJCg0KBQQAAgIDEgSjAQwNCjkKBAQAAgMSBKYBAhAaKyBEZXNjcmli
ZXMgdGhlIHBheW1lbnQgcGxhbiBmb3IgdGhlIE9mZmVyLgoKDQoFBAACAwYSBKYBAgYKDQoF
BAACAwESBKYBBwsKDQoFBAACAwMSBKYBDg8KNQoEBAACBBIEqQECHhonIENvbnN0cmFpbnRz
IG9uIHRyYW5zYWN0aW5nIHRoZSBPZmZlci4KCg0KBQQAAgQGEgSpAQINCg0KBQQAAgQBEgSp
AQ4ZCg0KBQQAAgQDEgSpARwdCjkKBAQAAgUSBKwBAjIaKyBQcmljZSBmb3IgZWFjaCBtb25l
dGl6YWJsZSByZXNvdXJjZSB0eXBlLgoKDQoFBAACBQQSBKwBAgoKDQoFBAACBQYSBKwBCxoK
DQoFBAACBQESBKwBGy0KDQoFBAACBQMSBKwBMDEKMQoEBAACBhIErwECKxojIFN0YXJ0IG9m
IHRoZSBPZmZlciB2YWxpZGl0eSB0aW1lLgoKDQoFBAACBgYSBK8BAhsKDQoFBAACBgESBK8B
HCYKDQoFBAACBgMSBK8BKSoKPgoEBAACBxIGsgECswEyGi4gT3V0cHV0IG9ubHkuIEVuZCBv
ZiB0aGUgT2ZmZXIgdmFsaWRpdHkgdGltZS4KCg0KBQQAAgcGEgSyAQIbCg0KBQQAAgcBEgSy
ARwkCg0KBQQAAgcDEgSyAScoCg0KBQQAAgcIEgSzAQYxChAKCAQAAgcInAgAEgSzAQcwCkUK
BAQAAggSBLYBAjkaNyBQYXJhbWV0ZXJzIHJlcXVpcmVkIHRvIHVzZSBjdXJyZW50IE9mZmVy
IHRvIHB1cmNoYXNlLgoKDQoFBAACCAQSBLYBAgoKDQoFBAACCAYSBLYBCx4KDQoFBAACCAES
BLYBHzQKDQoFBAACCAMSBLYBNzgKUgoEBAACCRIEuQECGBpEIFRoZSBkZWFsIGNvZGUgb2Yg
dGhlIG9mZmVyIHRvIGdldCBhIHNwZWNpYWwgcHJvbW90aW9uIG9yIGRpc2NvdW50LgoKDQoF
BAACCQUSBLkBAggKDQoFBAACCQESBLkBCRIKDQoFBAACCQMSBLkBFRcKcwoCBAESBr4BAOkB
ARplIFBhcmFtZXRlcidzIGRlZmluaXRpb24uIFNwZWNpZmllcyB3aGF0IHBhcmFtZXRlciBp
cyByZXF1aXJlZCB0byB1c2UgdGhlCiBjdXJyZW50IE9mZmVyIHRvIHB1cmNoYXNlLgoKCwoD
BAEBEgS+AQgbCi0KBAQBBAASBsABAs8BAxodIERhdGEgdHlwZSBvZiB0aGUgcGFyYW1ldGVy
LgoKDQoFBAEEAAESBMABBxQKGwoGBAEEAAIAEgTCAQQjGgsgTm90IHVzZWQuCgoPCgcEAQQA
AgABEgTCAQQeCg8KBwQBBAACAAISBMIBISIKHQoGBAEEAAIBEgTFAQQOGg0gSW50NjQgdHlw
ZS4KCg8KBwQBBAACAQESBMUBBAkKDwoHBAEEAAIBAhIExQEMDQoeCgYEAQQAAgISBMgBBA8a
DiBTdHJpbmcgdHlwZS4KCg8KBwQBBAACAgESBMgBBAoKDwoHBAEEAAICAhIEyAENDgoeCgYE
AQQAAgMSBMsBBA8aDiBEb3VibGUgdHlwZS4KCg8KBwQBBAACAwESBMsBBAoKDwoHBAEEAAID
AhIEywENDgofCgYEAQQAAgQSBM4BBBAaDyBCb29sZWFuIHR5cGUuCgoPCgcEAQQAAgQBEgTO
AQQLCg8KBwQBBAACBAISBM4BDg8KJgoEBAECABIE0gECEhoYIE5hbWUgb2YgdGhlIHBhcmFt
ZXRlci4KCg0KBQQBAgAFEgTSAQIICg0KBQQBAgABEgTSAQkNCg0KBQQBAgADEgTSARARCn8K
BAQBAgESBNYBAiMacSBEYXRhIHR5cGUgb2YgdGhlIHBhcmFtZXRlci4gTWluaW1hbCB2YWx1
ZSwgTWF4aW11bSB2YWx1ZSBhbmQgYWxsb3dlZCB2YWx1ZXMKIHdpbGwgdXNlIHNwZWNpZmll
ZCBkYXRhIHR5cGUgaGVyZS4KCg0KBQQBAgEGEgTWAQIPCg0KBQQBAgEBEgTWARAeCg0KBQQB
AgEDEgTWASEiCrwBCgQEAQICEgTbAQIWGq0BIE1pbmltYWwgdmFsdWUgb2YgdGhlIHBhcmFt
ZXRlciwgaWYgYXBwbGljYWJsZS4gSW5jbHVzaXZlLiBGb3IgZXhhbXBsZSwKIG1pbmltYWwg
Y29tbWl0bWVudCB3aGVuIHB1cmNoYXNpbmcgQW50aG9zIGlzIDAuMDEuCiBBcHBsaWNhYmxl
IHRvIElOVDY0IGFuZCBET1VCTEUgcGFyYW1ldGVyIHR5cGVzLgoKDQoFBAECAgYSBNsBAgcK
DQoFBAECAgESBNsBCBEKDQoFBAECAgMSBNsBFBUKywEKBAQBAgMSBOABAhYavAEgTWF4aW11
bSB2YWx1ZSBvZiB0aGUgcGFyYW1ldGVyLCBpZiBhcHBsaWNhYmxlLiBJbmNsdXNpdmUuIEZv
ciBleGFtcGxlLAogbWF4aW11bSBzZWF0cyB3aGVuIHB1cmNoYXNpbmcgR29vZ2xlIFdvcmtz
cGFjZSBCdXNpbmVzcyBTdGFuZGFyZC4KIEFwcGxpY2FibGUgdG8gSU5UNjQgYW5kIERPVUJM
RSBwYXJhbWV0ZXIgdHlwZXMuCgoNCgUEAQIDBhIE4AECBwoNCgUEAQIDARIE4AEIEQoNCgUE
AQIDAxIE4AEUFQqbAQoEBAECBBIE5QECJBqMASBJZiBub3QgZW1wdHksIHBhcmFtZXRlciB2
YWx1ZXMgbXVzdCBiZSBkcmF3biBmcm9tIHRoaXMgbGlzdC4KIEZvciBleGFtcGxlLCBbdXMt
d2VzdDEsIHVzLXdlc3QyLCAuLi5dCiBBcHBsaWNhYmxlIHRvIFNUUklORyBwYXJhbWV0ZXIg
dHlwZS4KCg0KBQQBAgQEEgTlAQIKCg0KBQQBAgQGEgTlAQsQCg0KBQQBAgQBEgTlAREfCg0K
BQQBAgQDEgTlASIjCk0KBAQBAgUSBOgBAhQaPyBJZiBzZXQgdG8gdHJ1ZSwgcGFyYW1ldGVy
IGlzIG9wdGlvbmFsIHRvIHB1cmNoYXNlIHRoaXMgT2ZmZXIuCgoNCgUEAQIFBRIE6AECBgoN
CgUEAQIFARIE6AEHDwoNCgUEAQIFAxIE6AESEwpACgIEAhIG7AEA7wEBGjIgUmVwcmVzZW50
cyB0aGUgY29uc3RyYWludHMgZm9yIGJ1eWluZyB0aGUgT2ZmZXIuCgoLCgMEAgESBOwBCBMK
VQoEBAICABIE7gECLxpHIFJlcHJlc2VudHMgY29uc3RyYWludHMgcmVxdWlyZWQgdG8gcHVy
Y2hhc2UgdGhlIE9mZmVyIGZvciBhIGN1c3RvbWVyLgoKDQoFBAICAAYSBO4BAhUKDQoFBAIC
AAESBO4BFioKDQoFBAICAAMSBO4BLS4KVQoCBAMSBvIBAPsBARpHIFJlcHJlc2VudHMgY29u
c3RyYWludHMgcmVxdWlyZWQgdG8gcHVyY2hhc2UgdGhlIE9mZmVyIGZvciBhIGN1c3RvbWVy
LgoKCwoDBAMBEgTyAQgbCj0KBAQDAgASBPQBAiYaLyBBbGxvd2VkIGdlb2dyYXBoaWNhbCBy
ZWdpb25zIG9mIHRoZSBjdXN0b21lci4KCg0KBQQDAgAEEgT0AQIKCg0KBQQDAgAFEgT0AQsR
Cg0KBQQDAgABEgT0ARIhCg0KBQQDAgADEgT0ASQlCiYKBAQDAgESBPcBAkUaGCBBbGxvd2Vk
IEN1c3RvbWVyIFR5cGUuCgoNCgUEAwIBBBIE9wECCgoNCgUEAwIBBhIE9wELKQoNCgUEAwIB
ARIE9wEqQAoNCgUEAwIBAxIE9wFDRApPCgQEAwICEgT6AQI8GkEgQWxsb3dlZCBQcm9tb3Rp
b25hbCBPcmRlciBUeXBlLiBQcmVzZW50IGZvciBQcm9tb3Rpb25hbCBvZmZlcnMuCgoNCgUE
AwICBBIE+gECCgoNCgUEAwICBhIE+gELHwoNCgUEAwICARIE+gEgNwoNCgUEAwICAxIE+gE6
OwpQCgIEBBIG/gEAlAIBGkIgVGhlIHBheW1lbnQgcGxhbiBmb3IgdGhlIE9mZmVyLiBEZXNj
cmliZXMgaG93IHRvIG1ha2UgYSBwYXltZW50LgoKCwoDBAQBEgT+AQgMCjgKBAQEAgASBIAC
Ah8aKiBEZXNjcmliZXMgaG93IGEgcmVzZWxsZXIgd2lsbCBiZSBiaWxsZWQuCgoNCgUEBAIA
BhIEgAICDQoNCgUEBAIAARIEgAIOGgoNCgUEBAIAAxIEgAIdHgo7CgQEBAIBEgSDAgIfGi0g
U3BlY2lmaWVzIHdoZW4gdGhlIHBheW1lbnQgbmVlZHMgdG8gaGFwcGVuLgoKDQoFBAQCAQYS
BIMCAg0KDQoFBAQCAQESBIMCDhoKDQoFBAQCAQMSBIMCHR4KXgoEBAQCAhIEhwICGxpQIERl
c2NyaWJlcyBob3cgZnJlcXVlbnRseSB0aGUgcmVzZWxsZXIgd2lsbCBiZSBiaWxsZWQsIHN1
Y2ggYXMKIG9uY2UgcGVyIG1vbnRoLgoKDQoFBAQCAgYSBIcCAggKDQoFBAQCAgESBIcCCRYK
DQoFBAQCAgMSBIcCGRoKzQIKBAQEAgMSBI8CAhoavgIgUHJlc2VudCBmb3IgT2ZmZXJzIHdp
dGggYSB0cmlhbCBwZXJpb2QuCiBGb3IgdHJpYWwtb25seSBPZmZlcnMsIGEgcGFpZCBzZXJ2
aWNlIG5lZWRzIHRvIHN0YXJ0IGJlZm9yZSB0aGUgdHJpYWwKIHBlcmlvZCBlbmRzIGZvciBj
b250aW51ZWQgc2VydmljZS4KIEZvciBSZWd1bGFyIE9mZmVycyB3aXRoIGEgdHJpYWwgcGVy
aW9kLCB0aGUgcmVndWxhciBwcmljaW5nIGdvZXMgaW50bwogZWZmZWN0IHdoZW4gdHJpYWwg
cGVyaW9kIGVuZHMsIG9yIGlmIHBhaWQgc2VydmljZSBpcyBzdGFydGVkIGJlZm9yZSB0aGUg
ZW5kCiBvZiB0aGUgdHJpYWwgcGVyaW9kLgoKDQoFBAQCAwYSBI8CAggKDQoFBAQCAwESBI8C
CRUKDQoFBAQCAwMSBI8CGBkKdQoEBAQCBBIEkwICHRpnIFJlc2VsbGVyIEJpbGxpbmcgYWNj
b3VudCB0byBjaGFyZ2UgYWZ0ZXIgYW4gb2ZmZXIgdHJhbnNhY3Rpb24uCiBPbmx5IHByZXNl
bnQgZm9yIEdvb2dsZSBDbG91ZCBvZmZlcnMuCgoNCgUEBAIEBRIEkwICCAoNCgUEBAIEARIE
kwIJGAoNCgUEBAIEAxIEkwIbHAoyCgIEBRIGlwIAoAIBGiQgUmVwcmVzZW50cyBwcmljZSBi
eSByZXNvdXJjZSB0eXBlLgoKCwoDBAUBEgSXAggXCiwKBAQFAgASBJkCAiEaHiBSZXNvdXJj
ZSBUeXBlLiBFeGFtcGxlOiBTRUFUCgoNCgUEBQIABhIEmQICDgoNCgUEBQIAARIEmQIPHAoN
CgUEBQIAAxIEmQIfIApJCgQEBQIBEgScAgISGjsgUHJpY2Ugb2YgdGhlIE9mZmVyLiBQcmVz
ZW50IGlmIHRoZXJlIGFyZSBubyBwcmljZSBwaGFzZXMuCgoNCgUEBQIBBhIEnAICBwoNCgUE
BQIBARIEnAIIDQoNCgUEBQIBAxIEnAIQEQoyCgQEBQICEgSfAgInGiQgU3BlY2lmaWVzIHRo
ZSBwcmljZSBieSB0aW1lIHJhbmdlLgoKDQoFBAUCAgQSBJ8CAgoKDQoFBAUCAgYSBJ8CCxUK
DQoFBAUCAgESBJ8CFiIKDQoFBAUCAgMSBJ8CJSYKMgoCBAYSBqMCALkCARokIFJlcHJlc2Vu
dHMgdGhlIHByaWNlIG9mIHRoZSBPZmZlci4KCgsKAwQGARIEowIIDQobCgQEBgIAEgSlAgIj
Gg0gQmFzZSBwcmljZS4KCg0KBQQGAgAGEgSlAgITCg0KBQQGAgABEgSlAhQeCg0KBQQGAgAD
EgSlAiEiCnMKBAQGAgESBKkCAhYaZSBEaXNjb3VudCBwZXJjZW50YWdlLCByZXByZXNlbnRl
ZCBhcyBkZWNpbWFsLgogRm9yIGV4YW1wbGUsIGEgMjAlIGRpc2NvdW50IHdpbGwgYmUgcmVw
cmVzZW50IGFzIDAuMi4KCg0KBQQGAgEFEgSpAgIICg0KBQQGAgEBEgSpAgkRCg0KBQQGAgED
EgSpAhQVCj0KBAQGAgISBKwCAigaLyBFZmZlY3RpdmUgUHJpY2UgYWZ0ZXIgYXBwbHlpbmcg
dGhlIGRpc2NvdW50cy4KCg0KBQQGAgIGEgSsAgITCg0KBQQGAgIBEgSsAhQjCg0KBQQGAgID
EgSsAiYnCocBCgQEBgIDEgSxAgIaGnkgVGhlIHRpbWUgcGVyaW9kIHdpdGggcmVzcGVjdCB0
byB3aGljaCBiYXNlIGFuZCBlZmZlY3RpdmUgcHJpY2VzIGFyZQogZGVmaW5lZC4KIEV4YW1w
bGU6IDEgbW9udGgsIDYgbW9udGhzLCAxIHllYXIsIGV0Yy4KCg0KBQQGAgMGEgSxAgIICg0K
BQQGAgMBEgSxAgkVCg0KBQQGAgMDEgSxAhgZClQKBAQGAgQSBLQCAiAaRiBMaW5rIHRvIGV4
dGVybmFsIHByaWNlIGxpc3QsIHN1Y2ggYXMgbGluayB0byBHb29nbGUgVm9pY2UgcmF0ZSBj
YXJkLgoKDQoFBAYCBAUSBLQCAggKDQoFBAYCBAESBLQCCRsKDQoFBAYCBAMSBLQCHh8KcwoE
BAYCBRIEuAICNRplIEJyZWFrZG93biBvZiB0aGUgZGlzY291bnQgaW50byBpdHMgY29tcG9u
ZW50cy4KIFRoaXMgd2lsbCBiZSBlbXB0eSBpZiB0aGVyZSBpcyBubyBkaXNjb3VudCBwcmVz
ZW50LgoKDQoFBAYCBQQSBLgCAgoKDQoFBAYCBQYSBLgCCxwKDQoFBAYCBQESBLgCHTAKDQoF
BAYCBQMSBLgCMzQKqgEKAgQHEga+AgDNAgEamwEgU3BlY2lmaWVzIHRoZSBwcmljZSBieSB0
aGUgZHVyYXRpb24gb2YgbW9udGhzLgogRm9yIGV4YW1wbGUsIGEgMjAlIGRpc2NvdW50IGZv
ciB0aGUgZmlyc3Qgc2l4IG1vbnRocywgdGhlbiBhIDEwJSBkaXNjb3VudAogc3RhcnRpbmcg
b24gdGhlIHNldmVudGggbW9udGguCgoLCgMEBwESBL4CCBIKLgoEBAcCABIEwAICHRogIERl
ZmluZXMgdGhlIHBoYXNlIHBlcmlvZCB0eXBlLgoKDQoFBAcCAAYSBMACAgwKDQoFBAcCAAES
BMACDRgKDQoFBAcCAAMSBMACGxwKMwoEBAcCARIEwwICGRolIERlZmluZXMgZmlyc3QgcGVy
aW9kIGZvciB0aGUgcGhhc2UuCgoNCgUEBwIBBRIEwwICBwoNCgUEBwIBARIEwwIIFAoNCgUE
BwIBAxIEwwIXGAozCgQEBwICEgTGAgIYGiUgRGVmaW5lcyBmaXJzdCBwZXJpb2QgZm9yIHRo
ZSBwaGFzZS4KCg0KBQQHAgIFEgTGAgIHCg0KBQQHAgIBEgTGAggTCg0KBQQHAgIDEgTGAhYX
CkgKBAQHAgMSBMkCAhIaOiBQcmljZSBvZiB0aGUgcGhhc2UuIFByZXNlbnQgaWYgdGhlcmUg
YXJlIG5vIHByaWNlIHRpZXJzLgoKDQoFBAcCAwYSBMkCAgcKDQoFBAcCAwESBMkCCA0KDQoF
BAcCAwMSBMkCEBEKLAoEBAcCBBIEzAICJRoeIFByaWNlIGJ5IHRoZSByZXNvdXJjZSB0aWVy
cy4KCg0KBQQHAgQEEgTMAgIKCg0KBQQHAgQGEgTMAgsUCg0KBQQHAgQBEgTMAhUgCg0KBQQH
AgQDEgTMAiMkCt8CCgIECBIG1wIA4AIBGtACIERlZmluZXMgcHJpY2UgYXQgcmVzb3VyY2Ug
dGllciBsZXZlbC4KIEZvciBleGFtcGxlLCBhbiBvZmZlciB3aXRoIGZvbGxvd2luZyBkZWZp
bml0aW9uIDoKCiAqIFRpZXIgMTogUHJvdmlkZSAyNSUgZGlzY291bnQgZm9yIGFsbCBzZWF0
cyBiZXR3ZWVuIDEgYW5kIDI1LgogKiBUaWVyIDI6IFByb3ZpZGUgMTAlIGRpc2NvdW50IGZv
ciBhbGwgc2VhdHMgYmV0d2VlbiAyNiBhbmQgMTAwLgogKiBUaWVyIDM6IFByb3ZpZGUgZmxh
dCAxNSUgZGlzY291bnQgZm9yIGFsbCBzZWF0cyBhYm92ZSAxMDAuCgogRWFjaCBvZiB0aGVz
ZSB0aWVycyBpcyByZXByZXNlbnRlZCBhcyBhIFByaWNlVGllci4KCgsKAwQIARIE1wIIEQpA
CgQECAIAEgTZAgIbGjIgRmlyc3QgcmVzb3VyY2UgZm9yIHdoaWNoIHRoZSB0aWVyIHByaWNl
IGFwcGxpZXMuCgoNCgUECAIABRIE2QICBwoNCgUECAIAARIE2QIIFgoNCgUECAIAAxIE2QIZ
Ggo/CgQECAIBEgTcAgIaGjEgTGFzdCByZXNvdXJjZSBmb3Igd2hpY2ggdGhlIHRpZXIgcHJp
Y2UgYXBwbGllcy4KCg0KBQQIAgEFEgTcAgIHCg0KBQQIAgEBEgTcAggVCg0KBQQIAgEDEgTc
AhgZCiIKBAQIAgISBN8CAhIaFCBQcmljZSBvZiB0aGUgdGllci4KCg0KBQQIAgIGEgTfAgIH
Cg0KBQQIAgIBEgTfAggNCg0KBQQIAgIDEgTfAhARCjcKAgQJEgbjAgDpAgEaKSBSZXByZXNl
bnRzIHBlcmlvZCBpbiBkYXlzL21vbnRocy95ZWFycy4KCgsKAwQJARIE4wIIDgo2CgQECQIA
EgTlAgIVGiggVG90YWwgZHVyYXRpb24gb2YgUGVyaW9kIFR5cGUgZGVmaW5lZC4KCg0KBQQJ
AgAFEgTlAgIHCg0KBQQJAgABEgTlAggQCg0KBQQJAgADEgTlAhMUChwKBAQJAgESBOgCAh0a
DiBQZXJpb2QgVHlwZS4KCg0KBQQJAgEGEgToAgIMCg0KBQQJAgEBEgToAg0YCg0KBQQJAgED
EgToAhscCloKAgQKEgbsAgD6AgEaTCBSZXByZXNlbnRzIGEgc2luZ2xlIGNvbXBvbmVudCBv
ZiB0aGUgdG90YWwgZGlzY291bnQgYXBwbGljYWJsZSBvbiBhIFByaWNlLgoKCwoDBAoBEgTs
AggZCl8KBAQKCAASBu8CAvYCAxpPIFNwZWNpZmllcyB0aGUgY29udHJpYnV0aW9uIG9mIHRo
aXMgZGlzY291bnQgY29tcG9uZW50IHRvIHRoZSB0b3RhbAogZGlzY291bnQuCgoNCgUECggA
ARIE7wIIFgp1CgQECgIAEgTyAgQjGmcgRGlzY291bnQgcGVyY2VudGFnZSwgcmVwcmVzZW50
ZWQgYXMgZGVjaW1hbC4KIEZvciBleGFtcGxlLCBhIDIwJSBkaXNjb3VudCB3aWxsIGJlIHJl
cHJlc2VudGVkIGFzIDAuMi4KCg0KBQQKAgAFEgTyAgQKCg0KBQQKAgABEgTyAgseCg0KBQQK
AgADEgTyAiEiCiUKBAQKAgESBPUCBCwaFyBGaXhlZCB2YWx1ZSBkaXNjb3VudC4KCg0KBQQK
AgEGEgT1AgQVCg0KBQQKAgEBEgT1AhYnCg0KBQQKAgEDEgT1AiorCiUKBAQKAgISBPkCAiEa
FyBUeXBlIG9mIHRoZSBkaXNjb3VudC4KCg0KBQQKAgIGEgT5AgIOCg0KBQQKAgIBEgT5Ag8c
Cg0KBQQKAgIDEgT5Ah8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Offers::Offer ===
    # Fields for Offer
    # Field: name Type: 9 ()
    # Field: marketing_info Type: 11 (.google.cloud.channel.v1.MarketingInfo)
    # Field: sku Type: 11 (.google.cloud.channel.v1.Sku)
    # Field: plan Type: 11 (.google.cloud.channel.v1.Plan)
    # Field: constraints Type: 11 (.google.cloud.channel.v1.Constraints)
    # Field: price_by_resources Type: 11 (.google.cloud.channel.v1.PriceByResource)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: parameter_definitions Type: 11 (.google.cloud.channel.v1.ParameterDefinition)
    # Field: deal_code Type: 9 ()

# === Message: Google::Cloud::Channel::V1::Offers::ParameterDefinition ===
    # Fields for ParameterDefinition
    # Field: name Type: 9 ()
    # Field: parameter_type Type: 14 (.google.cloud.channel.v1.ParameterDefinition.ParameterType)
    # Field: min_value Type: 11 (.google.cloud.channel.v1.Value)
    # Field: max_value Type: 11 (.google.cloud.channel.v1.Value)
    # Field: allowed_values Type: 11 (.google.cloud.channel.v1.Value)
    # Field: optional Type: 8 ()

# Enum: ParameterDefinition::ParameterType
our $ParameterDefinition_PARAMETER_TYPE_UNSPECIFIED = 0;
our $ParameterDefinition_INT64 = 1;
our $ParameterDefinition_STRING = 2;
our $ParameterDefinition_DOUBLE = 3;
our $ParameterDefinition_BOOLEAN = 4;

# === Message: Google::Cloud::Channel::V1::Offers::Constraints ===
    # Fields for Constraints
    # Field: customer_constraints Type: 11 (.google.cloud.channel.v1.CustomerConstraints)

# === Message: Google::Cloud::Channel::V1::Offers::CustomerConstraints ===
    # Fields for CustomerConstraints
    # Field: allowed_regions Type: 9 ()
    # Field: allowed_customer_types Type: 14 (.google.cloud.channel.v1.CloudIdentityInfo.CustomerType)
    # Field: promotional_order_types Type: 14 (.google.cloud.channel.v1.PromotionalOrderType)

# === Message: Google::Cloud::Channel::V1::Offers::Plan ===
    # Fields for Plan
    # Field: payment_plan Type: 14 (.google.cloud.channel.v1.PaymentPlan)
    # Field: payment_type Type: 14 (.google.cloud.channel.v1.PaymentType)
    # Field: payment_cycle Type: 11 (.google.cloud.channel.v1.Period)
    # Field: trial_period Type: 11 (.google.cloud.channel.v1.Period)
    # Field: billing_account Type: 9 ()

# === Message: Google::Cloud::Channel::V1::Offers::PriceByResource ===
    # Fields for PriceByResource
    # Field: resource_type Type: 14 (.google.cloud.channel.v1.ResourceType)
    # Field: price Type: 11 (.google.cloud.channel.v1.Price)
    # Field: price_phases Type: 11 (.google.cloud.channel.v1.PricePhase)

# === Message: Google::Cloud::Channel::V1::Offers::Price ===
    # Fields for Price
    # Field: base_price Type: 11 (.google.type.Money)
    # Field: discount Type: 1 ()
    # Field: effective_price Type: 11 (.google.type.Money)
    # Field: price_period Type: 11 (.google.cloud.channel.v1.Period)
    # Field: external_price_uri Type: 9 ()
    # Field: discount_components Type: 11 (.google.cloud.channel.v1.DiscountComponent)

# === Message: Google::Cloud::Channel::V1::Offers::PricePhase ===
    # Fields for PricePhase
    # Field: period_type Type: 14 (.google.cloud.channel.v1.PeriodType)
    # Field: first_period Type: 5 ()
    # Field: last_period Type: 5 ()
    # Field: price Type: 11 (.google.cloud.channel.v1.Price)
    # Field: price_tiers Type: 11 (.google.cloud.channel.v1.PriceTier)

# === Message: Google::Cloud::Channel::V1::Offers::PriceTier ===
    # Fields for PriceTier
    # Field: first_resource Type: 5 ()
    # Field: last_resource Type: 5 ()
    # Field: price Type: 11 (.google.cloud.channel.v1.Price)

# === Message: Google::Cloud::Channel::V1::Offers::Period ===
    # Fields for Period
    # Field: duration Type: 5 ()
    # Field: period_type Type: 14 (.google.cloud.channel.v1.PeriodType)

# === Message: Google::Cloud::Channel::V1::Offers::DiscountComponent ===
    # Fields for DiscountComponent
    # Field: discount_percentage Type: 1 ()
    # Field: discount_absolute Type: 11 (.google.type.Money)
    # Field: discount_type Type: 14 (.google.cloud.channel.v1.DiscountType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Offers - Compiled Protocol Buffers messages for google/cloud/channel/v1/offers.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Offers;

    my $msg = Google::Cloud::Channel::V1::Offers::Offer->new({
        name => $name,
        marketing_info => $marketing_info,
        sku => $sku,
        plan => $plan,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Offers::Offer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/offers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Offers::Offer

Represents an offer made to resellers for purchase.
An offer is associated with a [Sku][google.cloud.channel.v1.Sku], has a plan
for payment, a price, and defines the constraints for buying.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource Name of the Offer.
Format: accounts/{account_id}/offers/{offer_id}

=item * C<< $msg->marketing_info() >> / C<< $msg->marketing_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::MarketingInfo>)

Marketing information for the Offer.

=item * C<< $msg->sku() >> / C<< $msg->sku($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::Sku>)

SKU the offer is associated with.

=item * C<< $msg->plan() >> / C<< $msg->plan($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Plan>)

Describes the payment plan for the Offer.

=item * C<< $msg->constraints() >> / C<< $msg->constraints($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Constraints>)

Constraints on transacting the Offer.

=item * C<< $msg->price_by_resources() >> / C<< $msg->price_by_resources($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::PriceByResource>)

Price for each monetizable resource type.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start of the Offer validity time.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. End of the Offer validity time.

=item * C<< $msg->parameter_definitions() >> / C<< $msg->parameter_definitions($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::ParameterDefinition>)

Parameters required to use current Offer to purchase.

=item * C<< $msg->deal_code() >> / C<< $msg->deal_code($value) >>

Type: C<String>

The deal code of the offer to get a special promotion or discount.

=back

=head2 Google::Cloud::Channel::V1::Offers::ParameterDefinition

Parameter's definition. Specifies what parameter is required to use the
current Offer to purchase.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the parameter.

=item * C<< $msg->parameter_type() >> / C<< $msg->parameter_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::ParameterDefinition::ParameterType>)

Data type of the parameter. Minimal value, Maximum value and allowed values
will use specified data type here.

=item * C<< $msg->min_value() >> / C<< $msg->min_value($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::Value>)

Minimal value of the parameter, if applicable. Inclusive. For example,
minimal commitment when purchasing Anthos is 0.01.
Applicable to INT64 and DOUBLE parameter types.

=item * C<< $msg->max_value() >> / C<< $msg->max_value($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::Value>)

Maximum value of the parameter, if applicable. Inclusive. For example,
maximum seats when purchasing Google Workspace Business Standard.
Applicable to INT64 and DOUBLE parameter types.

=item * C<< $msg->allowed_values() >> / C<< $msg->allowed_values($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::Value>)

If not empty, parameter values must be drawn from this list.
For example, [us-west1, us-west2, ...]
Applicable to STRING parameter type.

=item * C<< $msg->optional() >> / C<< $msg->optional($value) >>

Type: C<Bool>

If set to true, parameter is optional to purchase this Offer.

=back

=head3 Enum: ParameterDefinition::ParameterType

=over 4

=item * C<PARAMETER_TYPE_UNSPECIFIED> => C<0>

=item * C<INT64> => C<1>

=item * C<STRING> => C<2>

=item * C<DOUBLE> => C<3>

=item * C<BOOLEAN> => C<4>

=back

=head2 Google::Cloud::Channel::V1::Offers::Constraints

Represents the constraints for buying the Offer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customer_constraints() >> / C<< $msg->customer_constraints($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::CustomerConstraints>)

Represents constraints required to purchase the Offer for a customer.

=back

=head2 Google::Cloud::Channel::V1::Offers::CustomerConstraints

Represents constraints required to purchase the Offer for a customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allowed_regions() >> / C<< $msg->allowed_regions($value) >>

Type: C<String>

Allowed geographical regions of the customer.

=item * C<< $msg->allowed_customer_types() >> / C<< $msg->allowed_customer_types($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::CloudIdentityInfo::CustomerType>)

Allowed Customer Type.

=item * C<< $msg->promotional_order_types() >> / C<< $msg->promotional_order_types($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PromotionalOrderType>)

Allowed Promotional Order Type. Present for Promotional offers.

=back

=head2 Google::Cloud::Channel::V1::Offers::Plan

The payment plan for the Offer. Describes how to make a payment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payment_plan() >> / C<< $msg->payment_plan($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PaymentPlan>)

Describes how a reseller will be billed.

=item * C<< $msg->payment_type() >> / C<< $msg->payment_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PaymentType>)

Specifies when the payment needs to happen.

=item * C<< $msg->payment_cycle() >> / C<< $msg->payment_cycle($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Period>)

Describes how frequently the reseller will be billed, such as
once per month.

=item * C<< $msg->trial_period() >> / C<< $msg->trial_period($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Period>)

Present for Offers with a trial period.
For trial-only Offers, a paid service needs to start before the trial
period ends for continued service.
For Regular Offers with a trial period, the regular pricing goes into
effect when trial period ends, or if paid service is started before the end
of the trial period.

=item * C<< $msg->billing_account() >> / C<< $msg->billing_account($value) >>

Type: C<String>

Reseller Billing account to charge after an offer transaction.
Only present for Google Cloud offers.

=back

=head2 Google::Cloud::Channel::V1::Offers::PriceByResource

Represents price by resource type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::ResourceType>)

Resource Type. Example: SEAT

=item * C<< $msg->price() >> / C<< $msg->price($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Price>)

Price of the Offer. Present if there are no price phases.

=item * C<< $msg->price_phases() >> / C<< $msg->price_phases($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::PricePhase>)

Specifies the price by time range.

=back

=head2 Google::Cloud::Channel::V1::Offers::Price

Represents the price of the Offer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_price() >> / C<< $msg->base_price($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

Base price.

=item * C<< $msg->discount() >> / C<< $msg->discount($value) >>

Type: C<Double>

Discount percentage, represented as decimal.
For example, a 20% discount will be represent as 0.2.

=item * C<< $msg->effective_price() >> / C<< $msg->effective_price($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

Effective Price after applying the discounts.

=item * C<< $msg->price_period() >> / C<< $msg->price_period($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Period>)

The time period with respect to which base and effective prices are
defined.
Example: 1 month, 6 months, 1 year, etc.

=item * C<< $msg->external_price_uri() >> / C<< $msg->external_price_uri($value) >>

Type: C<String>

Link to external price list, such as link to Google Voice rate card.

=item * C<< $msg->discount_components() >> / C<< $msg->discount_components($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::DiscountComponent>)

Breakdown of the discount into its components.
This will be empty if there is no discount present.

=back

=head2 Google::Cloud::Channel::V1::Offers::PricePhase

Specifies the price by the duration of months.
For example, a 20% discount for the first six months, then a 10% discount
starting on the seventh month.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->period_type() >> / C<< $msg->period_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PeriodType>)

Defines the phase period type.

=item * C<< $msg->first_period() >> / C<< $msg->first_period($value) >>

Type: C<Int32>

Defines first period for the phase.

=item * C<< $msg->last_period() >> / C<< $msg->last_period($value) >>

Type: C<Int32>

Defines first period for the phase.

=item * C<< $msg->price() >> / C<< $msg->price($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Price>)

Price of the phase. Present if there are no price tiers.

=item * C<< $msg->price_tiers() >> / C<< $msg->price_tiers($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::PriceTier>)

Price by the resource tiers.

=back

=head2 Google::Cloud::Channel::V1::Offers::PriceTier

Defines price at resource tier level.
For example, an offer with following definition :

* Tier 1: Provide 25% discount for all seats between 1 and 25.
* Tier 2: Provide 10% discount for all seats between 26 and 100.
* Tier 3: Provide flat 15% discount for all seats above 100.

Each of these tiers is represented as a PriceTier.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_resource() >> / C<< $msg->first_resource($value) >>

Type: C<Int32>

First resource for which the tier price applies.

=item * C<< $msg->last_resource() >> / C<< $msg->last_resource($value) >>

Type: C<Int32>

Last resource for which the tier price applies.

=item * C<< $msg->price() >> / C<< $msg->price($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Price>)

Price of the tier.

=back

=head2 Google::Cloud::Channel::V1::Offers::Period

Represents period in days/months/years.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Int32>

Total duration of Period Type defined.

=item * C<< $msg->period_type() >> / C<< $msg->period_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PeriodType>)

Period Type.

=back

=head2 Google::Cloud::Channel::V1::Offers::DiscountComponent

Represents a single component of the total discount applicable on a Price.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->discount_percentage() >> / C<< $msg->discount_percentage($value) >>

Type: C<Double>

Discount percentage, represented as decimal.
For example, a 20% discount will be represented as 0.2.

=item * C<< $msg->discount_absolute() >> / C<< $msg->discount_absolute($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

Fixed value discount.

=item * C<< $msg->discount_type() >> / C<< $msg->discount_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::DiscountType>)

Type of the discount.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Offers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
