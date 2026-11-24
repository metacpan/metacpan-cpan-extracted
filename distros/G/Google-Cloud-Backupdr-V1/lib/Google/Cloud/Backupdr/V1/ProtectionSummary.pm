package Google::Cloud::Backupdr::V1::ProtectionSummary;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvcHJvdGVjdGlvbl9zdW1tYXJ5LnByb3RvEhhn
b29nbGUuY2xvdWQuYmFja3VwZHIudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i6AEKIExpc3RSZXNvdXJj
ZUJhY2t1cENvbmZpZ3NSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlv
bnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVC
A+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoG
ZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRl
ckJ5IrMBCiFMaXN0UmVzb3VyY2VCYWNrdXBDb25maWdzUmVzcG9uc2USZgoXcmVzb3VyY2Vf
YmFja3VwX2NvbmZpZ3MYASADKAsyLi5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuUmVzb3Vy
Y2VCYWNrdXBDb25maWdSFXJlc291cmNlQmFja3VwQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iiQgKFFJlc291cmNlQmFja3VwQ29uZmlnEhcKBG5h
bWUYASABKAlCA+BBCFIEbmFtZRIdCgN1aWQYAiABKAlCC+KMz9cIAggB4EEDUgN1aWQSLAoP
dGFyZ2V0X3Jlc291cmNlGAMgASgJQgPgQQNSDnRhcmdldFJlc291cmNlEkQKHHRhcmdldF9y
ZXNvdXJjZV9kaXNwbGF5X25hbWUYBCABKAlCA+BBA1IZdGFyZ2V0UmVzb3VyY2VEaXNwbGF5
TmFtZRJyChR0YXJnZXRfcmVzb3VyY2VfdHlwZRgFIAEoDjI7Lmdvb2dsZS5jbG91ZC5iYWNr
dXBkci52MS5SZXNvdXJjZUJhY2t1cENvbmZpZy5SZXNvdXJjZVR5cGVCA+BBA1ISdGFyZ2V0
UmVzb3VyY2VUeXBlEn4KFnRhcmdldF9yZXNvdXJjZV9sYWJlbHMYBiADKAsySC5nb29nbGUu
Y2xvdWQuYmFja3VwZHIudjEuUmVzb3VyY2VCYWNrdXBDb25maWcuVGFyZ2V0UmVzb3VyY2VM
YWJlbHNFbnRyeVIUdGFyZ2V0UmVzb3VyY2VMYWJlbHMSYwoWYmFja3VwX2NvbmZpZ3NfZGV0
YWlscxgHIAMoCzItLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5CYWNrdXBDb25maWdEZXRh
aWxzUhRiYWNrdXBDb25maWdzRGV0YWlscxIwChFiYWNrdXBfY29uZmlndXJlZBgIIAEoCEID
4EEDUhBiYWNrdXBDb25maWd1cmVkEh0KB3ZhdWx0ZWQYCSABKAhCA+BBA1IHdmF1bHRlZBpH
ChlUYXJnZXRSZXNvdXJjZUxhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEilwEKDFJlc291cmNlVHlwZRIdChlSRVNPVVJDRV9UWVBFX1VO
U1BFQ0lGSUVEEAASFgoSQ0xPVURfU1FMX0lOU1RBTkNFEAESFQoRQ09NUFVURV9FTkdJTkVf
Vk0QAhIXChNDT01QVVRFX0VOR0lORV9ESVNLEAMSIAocQ09NUFVURV9FTkdJTkVfUkVHSU9O
QUxfRElTSxAEOrcB6kGzAQosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzb3VyY2VCYWNr
dXBDb25maWcSVnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXNv
dXJjZUJhY2t1cENvbmZpZ3Mve3Jlc291cmNlX2JhY2t1cF9jb25maWd9KhVyZXNvdXJjZUJh
Y2t1cENvbmZpZ3MyFHJlc291cmNlQmFja3VwQ29uZmlnIuoIChNCYWNrdXBDb25maWdEZXRh
aWxzEjUKFGJhY2t1cF9jb25maWdfc291cmNlGAEgASgJQgPgQQNSEmJhY2t1cENvbmZpZ1Nv
dXJjZRJNCiFiYWNrdXBfY29uZmlnX3NvdXJjZV9kaXNwbGF5X25hbWUYAiABKAlCA+BBA1Id
YmFja3VwQ29uZmlnU291cmNlRGlzcGxheU5hbWUSSwoEdHlwZRgDIAEoDjIyLmdvb2dsZS5j
bG91ZC5iYWNrdXBkci52MS5CYWNrdXBDb25maWdEZXRhaWxzLlR5cGVCA+BBA1IEdHlwZRJO
CgVzdGF0ZRgEIAEoDjIzLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5CYWNrdXBDb25maWdE
ZXRhaWxzLlN0YXRlQgPgQQNSBXN0YXRlElAKDXBpdHJfc2V0dGluZ3MYBSABKAsyJi5nb29n
bGUuY2xvdWQuYmFja3VwZHIudjEuUGl0clNldHRpbmdzQgPgQQNSDHBpdHJTZXR0aW5ncxJi
Ch1sYXRlc3Rfc3VjY2Vzc2Z1bF9iYWNrdXBfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IabGF0ZXN0U3VjY2Vzc2Z1bEJhY2t1cFRpbWUSNAoTYXBwbGlj
YWJsZV9yZXNvdXJjZRgHIAEoCUID4EEDUhJhcHBsaWNhYmxlUmVzb3VyY2USJgoMYmFja3Vw
X3ZhdWx0GAggASgJQgPgQQNSC2JhY2t1cFZhdWx0ElMKEGJhY2t1cF9sb2NhdGlvbnMYDCAD
KAsyKC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuQmFja3VwTG9jYXRpb25SD2JhY2t1cExv
Y2F0aW9ucxJhChViYWNrdXBfZHJfcGxhbl9jb25maWcYCiABKAsyLC5nb29nbGUuY2xvdWQu
YmFja3VwZHIudjEuQmFja3VwRHJQbGFuQ29uZmlnSABSEmJhY2t1cERyUGxhbkNvbmZpZxJt
ChliYWNrdXBfZHJfdGVtcGxhdGVfY29uZmlnGAsgASgLMjAuZ29vZ2xlLmNsb3VkLmJhY2t1
cGRyLnYxLkJhY2t1cERyVGVtcGxhdGVDb25maWdIAFIWYmFja3VwRHJUZW1wbGF0ZUNvbmZp
ZyKXAQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASJAogQ0xPVURfU1FMX0lOU1RBTkNF
X0JBQ0tVUF9DT05GSUcQARIiCh5DT01QVVRFX0VOR0lORV9SRVNPVVJDRV9QT0xJQ1kQAhIY
ChRCQUNLVVBEUl9CQUNLVVBfUExBThADEhUKEUJBQ0tVUERSX1RFTVBMQVRFEAQiQwoFU3Rh
dGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZBQ1RJVkUQARIMCghJTkFDVElWRRACEgkK
BUVSUk9SEANCFgoUcGxhbl9zcGVjaWZpY19jb25maWciOgoMUGl0clNldHRpbmdzEioKDnJl
dGVudGlvbl9kYXlzGAEgASgFQgPgQQNSDXJldGVudGlvbkRheXMinAEKFkJhY2t1cERyVGVt
cGxhdGVDb25maWcSQAoaZmlyc3RfcGFydHlfbWFuYWdlbWVudF91cmkYASABKAlCA+BBA1IX
Zmlyc3RQYXJ0eU1hbmFnZW1lbnRVcmkSQAoadGhpcmRfcGFydHlfbWFuYWdlbWVudF91cmkY
AiABKAlCA+BBA1IXdGhpcmRQYXJ0eU1hbmFnZW1lbnRVcmkicQoSQmFja3VwRHJQbGFuQ29u
ZmlnElsKFGJhY2t1cF9kcl9wbGFuX3J1bGVzGAEgAygLMiouZ29vZ2xlLmNsb3VkLmJhY2t1
cGRyLnYxLkJhY2t1cERyUGxhblJ1bGVSEWJhY2t1cERyUGxhblJ1bGVzIpABChBCYWNrdXBE
clBsYW5SdWxlEhwKB3J1bGVfaWQYASABKAlCA+BBA1IGcnVsZUlkEl4KG2xhc3Rfc3VjY2Vz
c2Z1bF9iYWNrdXBfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IYbGFzdFN1Y2Nlc3NmdWxCYWNrdXBUaW1lIskBCg5CYWNrdXBMb2NhdGlvbhJGCgR0eXBl
GAEgASgOMi0uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkJhY2t1cExvY2F0aW9uLlR5cGVC
A+BBA1IEdHlwZRIkCgtsb2NhdGlvbl9pZBgCIAEoCUID4EEDUgpsb2NhdGlvbklkIkkKBFR5
cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEgkKBVpPTkFMEAESDAoIUkVHSU9OQUwQAhISCg5N
VUxUSV9SRUdJT05BTBADMssCChlCYWNrdXBEclByb3RlY3Rpb25TdW1tYXJ5EuABChlMaXN0
UmVzb3VyY2VCYWNrdXBDb25maWdzEjouZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkxpc3RS
ZXNvdXJjZUJhY2t1cENvbmZpZ3NSZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
Lkxpc3RSZXNvdXJjZUJhY2t1cENvbmZpZ3NSZXNwb25zZSJKgtPkkwI7EjkvdjEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9yZXNvdXJjZUJhY2t1cENvbmZpZ3PaQQZwYXJl
bnQaS8pBF2JhY2t1cGRyLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULGAQocY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBk
ci52MUIWUHJvdGVjdGlvblN1bW1hcnlQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2Jh
Y2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCGEdvb2dsZS5DbG91ZC5CYWNr
dXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMeoCG0dvb2dsZTo6Q2xvdWQ6OkJh
Y2t1cERSOjpWMUqvXQoHEgUOAMECAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAlCgkKAgMEEgMWACMKCQoCAwUSAxcAKQoICgEIEgMZADUKCQoCCCUSAxkANQoICgEIEgMa
AE8KCQoCCAsSAxoATwoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADcKCQoCCAgSAxwA
NwoICgEIEgMdADUKCQoCCAESAx0ANQoICgEIEgMeADUKCQoCCCkSAx4ANQoICgEIEgMfADQK
CQoCCC0SAx8ANAotCgIGABIEIgAvARohIFRoZSBQcm90ZWN0aW9uIFN1bW1hcnkgc2Vydmlj
ZS4KCgoKAwYAARIDIgghCgoKAwYAAxIDIwI/CgwKBQYAA5kIEgMjAj8KCwoDBgADEgQkAiU3
Cg0KBQYAA5oIEgQkAiU3CiwKBAYAAgASBCgCLgMaHiBMaXN0cyBSZXNvdXJjZUJhY2t1cENv
bmZpZ3MuCgoMCgUGAAIAARIDKAYfCgwKBQYAAgACEgMoIEAKDAoFBgACAAMSAykPMAoNCgUG
AAIABBIEKgQsBgoRCgkGAAIABLDKvCISBCoELAYKDAoFBgACAAQSAy0ENAoPCggGAAIABJsI
ABIDLQQ0CjQKAgQAEgQyAEsBGiggUmVxdWVzdCBmb3IgTGlzdFJlc291cmNlQmFja3VwQ29u
Zmlncy4KCgoKAwQAARIDMggoCv4BCgQEAAIAEgQ3AjwEGu8BIFJlcXVpcmVkLiBUaGUgcHJv
amVjdCBhbmQgbG9jYXRpb24gZm9yIHdoaWNoIHRvIHJldHJpZXZlIHJlc291cmNlIGJhY2t1
cAogY29uZmlncy4gRm9ybWF0OiAncHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259Jy4gSW4gR29vZ2xlCiBDbG91ZCBCYWNrdXAgYW5kIERSLCBsb2NhdGlvbnMg
bWFwIHRvIEdvb2dsZSBDbG91ZCByZWdpb25zLCBmb3IgZXhhbXBsZQogKip1cy1jZW50cmFs
MSoqLgoKDAoFBAACAAUSAzcCCAoMCgUEAAIAARIDNwkPCgwKBQQAAgADEgM3EhMKDQoFBAAC
AAgSBDcUPAMKDwoIBAACAAicCAASAzgEKgoPCgcEAAIACJ8IEgQ5BDsFCtABCgQEAAIBEgNB
Aj8awgEgT3B0aW9uYWwuIFJlcXVlc3RlZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJu
IGZld2VyIGl0ZW1zIHRoYW4KIHJlcXVlc3RlZC4gSWYgdW5zcGVjaWZpZWQsIHNlcnZlciB3
aWxsIHVzZSAxMDAgYXMgZGVmYXVsdC4gTWF4aW11bSB2YWx1ZSBpcwogNTAwIGFuZCB2YWx1
ZXMgYWJvdmUgNTAwIHdpbGwgYmUgY29lcmNlZCB0byA1MDAuCgoMCgUEAAIBBRIDQQIHCgwK
BQQAAgEBEgNBCBEKDAoFBAACAQMSA0EUFQoMCgUEAAIBCBIDQRY+Cg8KCAQAAgEInAgAEgNB
Fz0KWAoEBAACAhIDRAJBGksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdl
IG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAACAgUSA0QCCAoM
CgUEAAICARIDRAkTCgwKBQQAAgIDEgNEFhcKDAoFBAACAggSA0QYQAoPCggEAAICCJwIABID
RBk/CisKBAQAAgMSA0cCPRoeIE9wdGlvbmFsLiBGaWx0ZXJpbmcgcmVzdWx0cy4KCgwKBQQA
AgMFEgNHAggKDAoFBAACAwESA0cJDwoMCgUEAAIDAxIDRxITCgwKBQQAAgMIEgNHFDwKDwoI
BAACAwicCAASA0cVOwo7CgQEAAIEEgNKAj8aLiBPcHRpb25hbC4gSGludCBmb3IgaG93IHRv
IG9yZGVyIHRoZSByZXN1bHRzLgoKDAoFBAACBAUSA0oCCAoMCgUEAAIEARIDSgkRCgwKBQQA
AgQDEgNKFBUKDAoFBAACBAgSA0oWPgoPCggEAAIECJwIABIDShc9CjUKAgQBEgROAFQBGikg
UmVzcG9uc2UgZm9yIExpc3RSZXNvdXJjZUJhY2t1cENvbmZpZ3MuCgoKCgMEAQESA04IKQpJ
CgQEAQIAEgNQAjwaPCBUaGUgbGlzdCBvZiBSZXNvdXJjZUJhY2t1cENvbmZpZ3MgZm9yIHRo
ZSBzcGVjaWZpZWQgc2NvcGUuCgoMCgUEAQIABBIDUAIKCgwKBQQBAgAGEgNQCx8KDAoFBAEC
AAESA1AgNwoMCgUEAQIAAxIDUDo7Ck4KBAQBAgESA1MCHRpBIEEgdG9rZW4gaWRlbnRpZnlp
bmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAEC
AQUSA1MCCAoMCgUEAQIBARIDUwkYCgwKBQQBAgEDEgNTGxwKYAoCBAISBVgAoAEBGlMgUmVz
b3VyY2VCYWNrdXBDb25maWcgcmVwcmVzZW50cyBhIHJlc291cmNlIGFsb25nIHdpdGggaXRz
IGJhY2t1cAogY29uZmlndXJhdGlvbnMuCgoKCgMEAgESA1gIHAoLCgMEAgcSBFkCXgQKDQoF
BAIHnQgSBFkCXgQKLwoEBAIEABIEYQJwAxohIFRoZSB0eXBlIG9mIHRoZSBjbG91ZCByZXNv
dXJjZS4KCgwKBQQCBAABEgNhBxMKJwoGBAIEAAIAEgNjBCIaGCBSZXNvdXJjZSB0eXBlIG5v
dCBzZXQuCgoOCgcEAgQAAgABEgNjBB0KDgoHBAIEAAIAAhIDYyAhCiQKBgQCBAACARIDZgQb
GhUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDgoHBAIEAAIBARIDZgQWCg4KBwQCBAACAQISA2YZ
GgojCgYEAgQAAgISA2kEGhoUIENvbXB1dGUgRW5naW5lIFZNLgoKDgoHBAIEAAICARIDaQQV
Cg4KBwQCBAACAgISA2kYGQolCgYEAgQAAgMSA2wEHBoWIENvbXB1dGUgRW5naW5lIERpc2su
CgoOCgcEAgQAAgMBEgNsBBcKDgoHBAIEAAIDAhIDbBobCi4KBgQCBAACBBIDbwQlGh8gQ29t
cHV0ZSBFbmdpbmUgUmVnaW9uYWwgRGlzay4KCg4KBwQCBAACBAESA28EIAoOCgcEAgQAAgQC
EgNvIyQKmAEKBAQCAgASA3UCPRqKASBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgUmVzb3VyY2VCYWNrdXBDb25maWcuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzb3VyY2VCYWNrdXBDb25maWdzL3t1aWR9CgoM
CgUEAgIABRIDdQIICgwKBQQCAgABEgN1CQ0KDAoFBAICAAMSA3UQEQoMCgUEAgIACBIDdRI8
Cg8KCAQCAgAInAgAEgN1EzsKUQoEBAICARIEeAJ7BBpDIE91dHB1dCBvbmx5LiBUaGUgdW5p
cXVlIGlkZW50aWZpZXIgb2YgdGhlIHJlc291cmNlIGJhY2t1cCBjb25maWcuCgoMCgUEAgIB
BRIDeAIICgwKBQQCAgEBEgN4CQwKDAoFBAICAQMSA3gPEAoNCgUEAgIBCBIEeBF7AwoSCgsE
AgIBCMzx+YoBARIDeQQqCg8KCAQCAgEInAgAEgN6BC0KtgIKBAQCAgISBIIBAkkapwIgT3V0
cHV0IG9ubHkuIFRoZSBbZnVsbCByZXNvdXJjZQogbmFtZV0oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2Fzc2V0LWludmVudG9yeS9kb2NzL3Jlc291cmNlLW5hbWUtZm9ybWF0KQogb2Yg
dGhlIGNsb3VkIHJlc291cmNlIHRoYXQgdGhpcyBjb25maWd1cmF0aW9uIGFwcGxpZXMgdG8u
IFN1cHBvcnRlZAogcmVzb3VyY2UgdHlwZXMgYXJlCiBbUmVzb3VyY2VCYWNrdXBDb25maWcu
UmVzb3VyY2VUeXBlXVtnb29nbGUuY2xvdWQuYmFja3VwZHIudjEuUmVzb3VyY2VCYWNrdXBD
b25maWcuUmVzb3VyY2VUeXBlXS4KCg0KBQQCAgIFEgSCAQIICg0KBQQCAgIBEgSCAQkYCg0K
BQQCAgIDEgSCARscCg0KBQQCAgIIEgSCAR1IChAKCAQCAgIInAgAEgSCAR5HCk4KBAQCAgMS
BoUBAoYBMho+IE91dHB1dCBvbmx5LiBUaGUgaHVtYW4gZnJpZW5kbHkgbmFtZSBvZiB0aGUg
dGFyZ2V0IHJlc291cmNlLgoKDQoFBAICAwUSBIUBAggKDQoFBAICAwESBIUBCSUKDQoFBAIC
AwMSBIUBKCkKDQoFBAICAwgSBIYBBjEKEAoIBAICAwicCAASBIYBBzAKPwoEBAICBBIGiQEC
igEyGi8gT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSB0YXJnZXQgcmVzb3VyY2UuCgoN
CgUEAgIEBhIEiQECDgoNCgUEAgIEARIEiQEPIwoNCgUEAgIEAxIEiQEmJwoNCgUEAgIECBIE
igEGMQoQCggEAgIECJwIABIEigEHMAo7CgQEAgIFEgSNAQIxGi0gTGFiZWxzIGFzc29jaWF0
ZWQgd2l0aCB0aGUgdGFyZ2V0IHJlc291cmNlLgoKDQoFBAICBQYSBI0BAhUKDQoFBAICBQES
BI0BFiwKDQoFBAICBQMSBI0BLzAKnQIKBAQCAgYSBJMBAjoajgIgQmFja3VwIGNvbmZpZ3Vy
YXRpb25zIGFwcGx5aW5nIHRvIHRoZSB0YXJnZXQgcmVzb3VyY2UsIGluY2x1ZGluZyB0aG9z
ZQogdGFyZ2V0aW5nIGl0cyByZWxhdGVkL2NoaWxkIHJlc291cmNlcy4gRm9yIGV4YW1wbGUs
IGJhY2t1cCBjb25maWd1cmF0aW9uCiBhcHBsaWNhYmxlIHRvIENvbXB1dGUgRW5naW5lIGRp
c2tzIHdpbGwgYmUgcG9wdWxhdGVkIGluIHRoaXMgZmllbGQgZm9yIGEKIENvbXB1dGUgRW5n
aW5lIFZNIHdoaWNoIGhhcyB0aGUgZGlzayBhc3NvY2lhdGVkLgoKDQoFBAICBgQSBJMBAgoK
DQoFBAICBgYSBJMBCx4KDQoFBAICBgESBJMBHzUKDQoFBAICBgMSBJMBODkKjAEKBAQCAgcS
BJcBAkkafiBPdXRwdXQgb25seS4gV2hldGhlciB0aGUgdGFyZ2V0IHJlc291cmNlIGlzIGNv
bmZpZ3VyZWQgZm9yIGJhY2t1cC4gVGhpcyBpcwogdHJ1ZSBpZiB0aGUgYmFja3VwX2NvbmZp
Z3NfZGV0YWlscyBpcyBub3QgZW1wdHkuCgoNCgUEAgIHBRIElwECBgoNCgUEAgIHARIElwEH
GAoNCgUEAgIHAxIElwEbHAoNCgUEAgIHCBIElwEdSAoQCggEAgIHCJwIABIElwEeRwqhAwoE
BAICCBIEnwECPxqSAyBPdXRwdXQgb25seS4gV2hldGhlciB0aGUgdGFyZ2V0IHJlc291cmNl
IGlzIHByb3RlY3RlZCBieSBhIGJhY2t1cCB2YXVsdC4KIFRoaXMgaXMgdHJ1ZSBpZiB0aGUg
YmFja3VwX2NvbmZpZ3NfZGV0YWlscyBpcyBub3QgZW1wdHkgYW5kIGFueSBvZiB0aGUKIFtS
ZXNvdXJjZUJhY2t1cENvbmZpZy5iYWNrdXBfY29uZmlnc19kZXRhaWxzXVtnb29nbGUuY2xv
dWQuYmFja3VwZHIudjEuUmVzb3VyY2VCYWNrdXBDb25maWcuYmFja3VwX2NvbmZpZ3NfZGV0
YWlsc10KIGhhcyBhIGJhY2t1cCBjb25maWd1cmF0aW9uIHdpdGgKIFtCYWNrdXBDb25maWdE
ZXRhaWxzLmJhY2t1cF92YXVsdF1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkJhY2t1cENv
bmZpZ0RldGFpbHMuYmFja3VwX3ZhdWx0XQogc2V0LiBzZXQuCgoNCgUEAgIIBRIEnwECBgoN
CgUEAgIIARIEnwEHDgoNCgUEAgIIAxIEnwEREgoNCgUEAgIICBIEnwETPgoQCggEAgIICJwI
ABIEnwEUPQqlAQoCBAMSBqQBAIMCARqWASBCYWNrdXBDb25maWdEZXRhaWxzIGhhcyBpbmZv
cm1hdGlvbiBhYm91dCBob3cgdGhlIHJlc291cmNlIGlzIGNvbmZpZ3VyZWQKIGZvciBiYWNr
dXBzIGFuZCBhYm91dCB0aGUgbW9zdCByZWNlbnQgYmFja3VwIHRha2VuIGZvciB0aGlzIGNv
bmZpZ3VyYXRpb24uCgoLCgMEAwESBKQBCBsKZAoEBAMEABIGpwECtgEDGlQgVHlwZSBvZiB0
aGUgYmFja3VwIGNvbmZpZ3VyYXRpb24uCiBUaGlzIGVudW0gbWF5IHJlY2VpdmUgbmV3IHZh
bHVlcyBpbiB0aGUgZnV0dXJlLgoKDQoFBAMEAAESBKcBBwsKNAoGBAMEAAIAEgSpAQQZGiQg
QmFja3VwIGNvbmZpZyB0eXBlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAMEAAIAARIEqQEEFAoP
CgcEAwQAAgACEgSpARcYClAKBgQDBAACARIErAEEKRpAIEJhY2t1cCBjb25maWcgaXMgQ2xv
dWQgU1FMIGluc3RhbmNlJ3MgYXV0b21hdGVkIGJhY2t1cCBjb25maWcuCgoPCgcEAwQAAgEB
EgSsAQQkCg8KBwQDBAACAQISBKwBJygKQgoGBAMEAAICEgSvAQQnGjIgQmFja3VwIGNvbmZp
ZyBpcyBDb21wdXRlIEVuZ2luZSBSZXNvdXJjZSBQb2xpY3kuCgoPCgcEAwQAAgIBEgSvAQQi
Cg8KBwQDBAACAgISBK8BJSYKTAoGBAMEAAIDEgSyAQQdGjwgQmFja3VwIGNvbmZpZyBpcyBH
b29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUidzIEJhY2t1cCBQbGFuLgoKDwoHBAMEAAIDARIE
sgEEGAoPCgcEAwQAAgMCEgSyARscCkkKBgQDBAACBBIEtQEEGho5IEJhY2t1cCBjb25maWcg
aXMgR29vZ2xlIENsb3VkIEJhY2t1cCBhbmQgRFIncyBUZW1wbGF0ZS4KCg8KBwQDBAACBAES
BLUBBBUKDwoHBAMEAAIEAhIEtQEYGQpNCgQEAwQBEga5AQLJAQMaPSBUaGUgc3RhdGUgdGVs
bHMgd2hldGhlciB0aGUgYmFja3VwIGNvbmZpZyBpcyBhY3RpdmUgb3Igbm90LgoKDQoFBAME
AQESBLkBBwwKLgoGBAMEAQIAEgS7AQQaGh4gQmFja3VwIGNvbmZpZyBzdGF0ZSBub3Qgc2V0
LgoKDwoHBAMEAQIAARIEuwEEFQoPCgcEAwQBAgACEgS7ARgZCkoKBgQDBAECARIEvgEEDxo6
IFRoZSBjb25maWcgaXMgaW4gYW4gYWN0aXZlIHN0YXRlIHByb3RlY3RpbmcgdGhlIHJlc291
cmNlCgoPCgcEAwQBAgEBEgS+AQQKCg8KBwQDBAECAQISBL4BDQ4KtgEKBgQDBAECAhIEwwEE
ERqlASBUaGUgY29uZmlnIGlzIGN1cnJlbnRseSBub3QgcHJvdGVjdGluZyB0aGUgcmVzb3Vy
Y2UuIEVpdGhlciBiZWNhdXNlIGl0IGlzCiBkaXNhYmxlZCBvciB0aGUgb3duaW5nIHByb2pl
Y3QgaGFzIGJlZW4gZGVsZXRlZCB3aXRob3V0IGNsZWFudXAgb2YgdGhlCiBhY3R1YWwgcmVz
b3VyY2UuCgoPCgcEAwQBAgIBEgTDAQQMCg8KBwQDBAECAgISBMMBDxAKwwEKBgQDBAECAxIE
yAEEDhqyASBUaGUgY29uZmlnIHN0aWxsIGV4aXN0cyBidXQgYmVjYXVzZSBvZiBzb21lIGVy
cm9yIHN0YXRlIGl0IGlzIG5vdAogcHJvdGVjdGluZyB0aGUgcmVzb3VyY2UuIExpa2UgdGhl
IHNvdXJjZSBwcm9qZWN0IGlzIGRlbGV0ZWQuIEZvciBlZy4KIFBsYW5Bc3NvY2lhdGlvbiwg
QmFja3VwUGxhbiBpcyBkZWxldGVkLgoKDwoHBAMEAQIDARIEyAEECQoPCgcEAwQBAgMCEgTI
AQwNCrQCCgQEAwIAEgTQAQJOGqUCIE91dHB1dCBvbmx5LiBUaGUgZnVsbCByZXNvdXJjZSBu
YW1lIG9mIHRoZSBiYWNrdXAgY29uZmlnIHNvdXJjZSByZXNvdXJjZS4KIEZvciBleGFtcGxl
LAogIi8vYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vdjEvcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97cmVnaW9ufS9iYWNrdXBQbGFucy97YmFja3VwcGxhbklkfSIKIG9yCiAiLy9j
b21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3Jl
Z2lvbn0vcmVzb3VyY2VQb2xpY2llcy97cmVzb3VyY2VQb2xpY3lJZH0iLgoKDQoFBAMCAAUS
BNABAggKDQoFBAMCAAESBNABCR0KDQoFBAMCAAMSBNABICEKDQoFBAMCAAgSBNABIk0KEAoI
BAMCAAicCAASBNABI0wKVQoEBAMCARIG0wEC1AEyGkUgT3V0cHV0IG9ubHkuIFRoZSBkaXNw
bGF5IG5hbWUgb2YgdGhlIGJhY2t1cCBjb25maWcgc291cmNlIHJlc291cmNlLgoKDQoFBAMC
AQUSBNMBAggKDQoFBAMCAQESBNMBCSoKDQoFBAMCAQMSBNMBLS4KDQoFBAMCAQgSBNQBBjEK
EAoIBAMCAQicCAASBNQBBzAKRAoEBAMCAhIE1wECPBo2IE91dHB1dCBvbmx5LiBUaGUgdHlw
ZSBvZiB0aGUgYmFja3VwIGNvbmZpZyByZXNvdXJjZS4KCg0KBQQDAgIGEgTXAQIGCg0KBQQD
AgIBEgTXAQcLCg0KBQQDAgIDEgTXAQ4PCg0KBQQDAgIIEgTXARA7ChAKCAQDAgIInAgAEgTX
ARE6CkUKBAQDAgMSBNoBAj4aNyBPdXRwdXQgb25seS4gVGhlIHN0YXRlIG9mIHRoZSBiYWNr
dXAgY29uZmlnIHJlc291cmNlLgoKDQoFBAMCAwYSBNoBAgcKDQoFBAMCAwESBNoBCA0KDQoF
BAMCAwMSBNoBEBEKDQoFBAMCAwgSBNoBEj0KEAoIBAMCAwicCAASBNoBEzwKYwoEBAMCBBIE
3gECTRpVIE91dHB1dCBvbmx5LiBQb2ludCBpbiB0aW1lIHJlY292ZXJ5IHNldHRpbmdzIG9m
IHRoZSBiYWNrdXAgY29uZmlndXJhdGlvbgogcmVzb3VyY2UuCgoNCgUEAwIEBhIE3gECDgoN
CgUEAwIEARIE3gEPHAoNCgUEAwIEAxIE3gEfIAoNCgUEAwIECBIE3gEhTAoQCggEAwIECJwI
ABIE3gEiSwpwCgQEAwIFEgbiAQLjATIaYCBPdXRwdXQgb25seS4gVGltZXN0YW1wIG9mIHRo
ZSBsYXRlc3Qgc3VjY2Vzc2Z1bCBiYWNrdXAgY3JlYXRlZCB2aWEgdGhpcwogYmFja3VwIGNv
bmZpZ3VyYXRpb24uCgoNCgUEAwIFBhIE4gECGwoNCgUEAwIFARIE4gEcOQoNCgUEAwIFAxIE
4gE8PQoNCgUEAwIFCBIE4wEGMQoQCggEAwIFCJwIABIE4wEHMAqXAgoEBAMCBhIE6QECTRqI
AiBPdXRwdXQgb25seS4gVGhlIFtmdWxsIHJlc291cmNlCiBuYW1lXShodHRwczovL2Nsb3Vk
Lmdvb2dsZS5jb20vYXNzZXQtaW52ZW50b3J5L2RvY3MvcmVzb3VyY2UtbmFtZS1mb3JtYXQp
CiBvZiB0aGUgcmVzb3VyY2UgdGhhdCBpcyBhcHBsaWNhYmxlIGZvciB0aGUgYmFja3VwIGNv
bmZpZ3VyYXRpb24uIEV4YW1wbGU6CiAiLy9jb21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2pl
Y3RzL3twcm9qZWN0fS96b25lcy97em9uZX0vaW5zdGFuY2VzL3tpbnN0YW5jZX0iCgoNCgUE
AwIGBRIE6QECCAoNCgUEAwIGARIE6QEJHAoNCgUEAwIGAxIE6QEfIAoNCgUEAwIGCBIE6QEh
TAoQCggEAwIGCJwIABIE6QEiSwrGAgoEBAMCBxIE8AECRhq3AiBPdXRwdXQgb25seS4gVGhl
IFtmdWxsIHJlc291cmNlCiBuYW1lXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXNzZXQt
aW52ZW50b3J5L2RvY3MvcmVzb3VyY2UtbmFtZS1mb3JtYXQpCiBvZiB0aGUgYmFja3VwIHZh
dWx0IHRoYXQgd2lsbCBzdG9yZSB0aGUgYmFja3VwcyBnZW5lcmF0ZWQgdGhyb3VnaCB0aGlz
CiBiYWNrdXAgY29uZmlndXJhdGlvbi4gRXhhbXBsZToKICIvL2JhY2t1cGRyLmdvb2dsZWFw
aXMuY29tL3YxL3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0vYmFja3Vw
VmF1bHRzL3tiYWNrdXB2YXVsdElkfSIKCg0KBQQDAgcFEgTwAQIICg0KBQQDAgcBEgTwAQkV
Cg0KBQQDAgcDEgTwARgZCg0KBQQDAgcIEgTwARpFChAKCAQDAgcInAgAEgTwARtECkEKBAQD
AggSBPMBAjAaMyBUaGUgbG9jYXRpb25zIHdoZXJlIHRoZSBiYWNrdXBzIGFyZSB0byBiZSBz
dG9yZWQuCgoNCgUEAwIIBBIE8wECCgoNCgUEAwIIBhIE8wELGQoNCgUEAwIIARIE8wEaKgoN
CgUEAwIIAxIE8wEtLwrNAwoEBAMIABIG/AECggIDGrwDIFRoZSBwbGFuIHNwZWNpZmljIGNv
bmZpZy4gVGhpcyBkZXBlbmRzIG9uIHRoZSB2YWx1ZSBvZgogW0JhY2t1cENvbmZpZ0RldGFp
bHMudHlwZV1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkJhY2t1cENvbmZpZ0RldGFpbHMu
dHlwZV0uCiBGb3IgdHlwZT1CQUNLVVBEUl9CQUNLVVBfUExBTiwgYmFja3VwX2RyX3BsYW5f
Y29uZmlnIHdvdWxkIGJlIHBvcHVsYXRlZCB0bwogY2FwdHVyZSBpbmZvcm1hdGlvbiByZWxh
dGVkIHRvIEdvb2dsZSBDbG91ZCBCYWNrdXAgYW5kIERSJ3MgQmFja3VwIFBsYW5zLgogRm9y
IHR5cGU9QkFDS1VQRFJfVEVNUExBVEUsIGJhY2t1cF9kcl90ZW1wbGF0ZV9jb25maWcgd291
bGQgYmUgcG9wdWxhdGVkIHRvCiBjYXB0dXJlIGluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gR29v
Z2xlIENsb3VkIEJhY2t1cCBhbmQgRFIncyBUZW1wbGF0ZQogZGV0YWlscy4KCg0KBQQDCAAB
EgT8AQgcCkcKBAQDAgkSBP4BBDIaOSBHb29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUidzIEJh
Y2t1cCBQbGFuIHNwZWNpZmljIGRhdGEuCgoNCgUEAwIJBhIE/gEEFgoNCgUEAwIJARIE/gEX
LAoNCgUEAwIJAxIE/gEvMQpECgQEAwIKEgSBAgQ6GjYgR29vZ2xlIENsb3VkIEJhY2t1cCBh
bmQgRFIncyBUZW1wbGF0ZSBzcGVjaWZpYyBkYXRhLgoKDQoFBAMCCgYSBIECBBoKDQoFBAMC
CgESBIECGzQKDQoFBAMCCgMSBIECNzkKVQoCBAQSBoYCAIkCARpHIFBvaW50IGluIHRpbWUg
cmVjb3Zlcnkgc2V0dGluZ3Mgb2YgdGhlIGJhY2t1cCBjb25maWd1cmF0aW9uIHJlc291cmNl
LgoKCwoDBAQBEgSGAggUCkEKBAQEAgASBIgCAkcaMyBPdXRwdXQgb25seS4gTnVtYmVyIG9m
IGRheXMgdG8gcmV0YWluIHRoZSBiYWNrdXAuCgoNCgUEBAIABRIEiAICBwoNCgUEBAIAARIE
iAIIFgoNCgUEBAIAAxIEiAIZGgoNCgUEBAIACBIEiAIbRgoQCggEBAIACJwIABIEiAIcRQpy
CgIEBRIGjQIAlwIBGmQgUHJvdmlkZXMgYWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCBH
b29nbGUgQ2xvdWQgQmFja3VwCiBhbmQgRFIncyBUZW1wbGF0ZSBiYWNrdXAgY29uZmlndXJh
dGlvbi4KCgsKAwQFARIEjQIIHgptCgQEBQIAEgaQAgKRAjIaXSBPdXRwdXQgb25seS4gVGhl
IFVSSSBvZiB0aGUgQmFja3VwRHIgdGVtcGxhdGUgcmVzb3VyY2UgZm9yIHRoZSBmaXJzdCBw
YXJ0eQogaWRlbnRpdHkgdXNlcnMuCgoNCgUEBQIABRIEkAICCAoNCgUEBQIAARIEkAIJIwoN
CgUEBQIAAxIEkAImJwoNCgUEBQIACBIEkQIGMQoQCggEBQIACJwIABIEkQIHMAptCgQEBQIB
EgaVAgKWAjIaXSBPdXRwdXQgb25seS4gVGhlIFVSSSBvZiB0aGUgQmFja3VwRHIgdGVtcGxh
dGUgcmVzb3VyY2UgZm9yIHRoZSB0aGlyZCBwYXJ0eQogaWRlbnRpdHkgdXNlcnMuCgoNCgUE
BQIBBRIElQICCAoNCgUEBQIBARIElQIJIwoNCgUEBQIBAxIElQImJwoNCgUEBQIBCBIElgIG
MQoQCggEBQIBCJwIABIElgIHMAp8CgIEBhIGmwIAngIBGm4gQmFja3VwRHJQbGFuQ29uZmln
IGhhcyBhZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0IEdvb2dsZSBDbG91ZCBCYWNrdXAg
YW5kCiBEUidzIFBsYW4gYmFja3VwIGNvbmZpZ3VyYXRpb24uCgoLCgMEBgESBJsCCBoKOQoE
BAYCABIEnQICNRorIEJhY2t1cCBydWxlcyBvZiB0aGUgYmFja3VwIHBsYW4gcmVzb3VyY2Uu
CgoNCgUEBgIABBIEnQICCgoNCgUEBgIABhIEnQILGwoNCgUEBgIAARIEnQIcMAoNCgUEBgIA
AxIEnQIzNApbCgIEBxIGoQIAqQIBGk0gQmFja3VwRHJQbGFuUnVsZSBoYXMgcnVsZSBzcGVj
aWZpYyBpbmZvcm1hdGlvbiBvZiB0aGUgYmFja3VwIHBsYW4gcmVzb3VyY2UuCgoLCgMEBwES
BKECCBgKOgoEBAcCABIEowICQRosIE91dHB1dCBvbmx5LiBVbmlxdWUgSWQgb2YgdGhlIGJh
Y2t1cCBydWxlLgoKDQoFBAcCAAUSBKMCAggKDQoFBAcCAAESBKMCCRAKDQoFBAcCAAMSBKMC
ExQKDQoFBAcCAAgSBKMCFUAKEAoIBAcCAAicCAASBKMCFj8KZwoEBAcCARIGpwICqAIyGlcg
T3V0cHV0IG9ubHkuIFRpbWVzdGFtcCBvZiB0aGUgbGF0ZXN0IHN1Y2Nlc3NmdWwgYmFja3Vw
IGNyZWF0ZWQgdmlhIHRoaXMKIGJhY2t1cCBydWxlLgoKDQoFBAcCAQYSBKcCAhsKDQoFBAcC
AQESBKcCHDcKDQoFBAcCAQMSBKcCOjsKDQoFBAcCAQgSBKgCBjEKEAoIBAcCAQicCAASBKgC
BzAKWAoCBAgSBqwCAMECARpKIEJhY2t1cExvY2F0aW9uIHJlcHJlc2VudHMgYSBjbG91ZCBs
b2NhdGlvbiB3aGVyZSBhIGJhY2t1cCBjYW4gYmUgc3RvcmVkLgoKCwoDBAgBEgSsAggWCisK
BAQIBAASBq4CAroCAxobIFRoZSB0eXBlIG9mIHRoZSBsb2NhdGlvbi4KCg0KBQQIBAABEgSu
AgcLCi8KBgQIBAACABIEsAIEGRofIExvY2F0aW9uIHR5cGUgaXMgdW5zcGVjaWZpZWQuCgoP
CgcECAQAAgABEgSwAgQUCg8KBwQIBAACAAISBLACFxgKKQoGBAgEAAIBEgSzAgQOGhkgTG9j
YXRpb24gdHlwZSBpcyB6b25hbC4KCg8KBwQIBAACAQESBLMCBAkKDwoHBAgEAAIBAhIEswIM
DQosCgYECAQAAgISBLYCBBEaHCBMb2NhdGlvbiB0eXBlIGlzIHJlZ2lvbmFsLgoKDwoHBAgE
AAICARIEtgIEDAoPCgcECAQAAgICEgS2Ag8QCjIKBgQIBAACAxIEuQIEFxoiIExvY2F0aW9u
IHR5cGUgaXMgbXVsdGkgcmVnaW9uYWwuCgoPCgcECAQAAgMBEgS5AgQSCg8KBwQIBAACAwIS
BLkCFRYKNgoEBAgCABIEvQICPBooIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgbG9j
YXRpb24uCgoNCgUECAIABhIEvQICBgoNCgUECAIAARIEvQIHCwoNCgUECAIAAxIEvQIODwoN
CgUECAIACBIEvQIQOwoQCggECAIACJwIABIEvQIROgpRCgQECAIBEgTAAgJFGkMgT3V0cHV0
IG9ubHkuIFRoZSBpZCBvZiB0aGUgY2xvdWQgbG9jYXRpb24uIEV4YW1wbGU6ICJ1cy1jZW50
cmFsMSIKCg0KBQQIAgEFEgTAAgIICg0KBQQIAgEBEgTAAgkUCg0KBQQIAgEDEgTAAhcYCg0K
BQQIAgEIEgTAAhlEChAKCAQIAgEInAgAEgTAAhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest ===
    # Fields for ListResourceBackupConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse ===
    # Fields for ListResourceBackupConfigsResponse
    # Field: resource_backup_configs Type: 11 (.google.cloud.backupdr.v1.ResourceBackupConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig ===
    # Fields for ResourceBackupConfig
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: target_resource Type: 9 ()
    # Field: target_resource_display_name Type: 9 ()
    # Field: target_resource_type Type: 14 (.google.cloud.backupdr.v1.ResourceBackupConfig.ResourceType)
    # Field: target_resource_labels Type: 11 (.google.cloud.backupdr.v1.ResourceBackupConfig.TargetResourceLabelsEntry)
    # Field: backup_configs_details Type: 11 (.google.cloud.backupdr.v1.BackupConfigDetails)
    # Field: backup_configured Type: 8 ()
    # Field: vaulted Type: 8 ()

# Enum: ResourceBackupConfig::ResourceType
our $ResourceBackupConfig_RESOURCE_TYPE_UNSPECIFIED = 0;
our $ResourceBackupConfig_CLOUD_SQL_INSTANCE = 1;
our $ResourceBackupConfig_COMPUTE_ENGINE_VM = 2;
our $ResourceBackupConfig_COMPUTE_ENGINE_DISK = 3;
our $ResourceBackupConfig_COMPUTE_ENGINE_REGIONAL_DISK = 4;

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails ===
    # Fields for BackupConfigDetails
    # Field: backup_config_source Type: 9 ()
    # Field: backup_config_source_display_name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.backupdr.v1.BackupConfigDetails.Type)
    # Field: state Type: 14 (.google.cloud.backupdr.v1.BackupConfigDetails.State)
    # Field: pitr_settings Type: 11 (.google.cloud.backupdr.v1.PitrSettings)
    # Field: latest_successful_backup_time Type: 11 (.google.protobuf.Timestamp)
    # Field: applicable_resource Type: 9 ()
    # Field: backup_vault Type: 9 ()
    # Field: backup_locations Type: 11 (.google.cloud.backupdr.v1.BackupLocation)
    # Field: backup_dr_plan_config Type: 11 (.google.cloud.backupdr.v1.BackupDrPlanConfig)
    # Field: backup_dr_template_config Type: 11 (.google.cloud.backupdr.v1.BackupDrTemplateConfig)

# Enum: BackupConfigDetails::Type
our $BackupConfigDetails_TYPE_UNSPECIFIED = 0;
our $BackupConfigDetails_CLOUD_SQL_INSTANCE_BACKUP_CONFIG = 1;
our $BackupConfigDetails_COMPUTE_ENGINE_RESOURCE_POLICY = 2;
our $BackupConfigDetails_BACKUPDR_BACKUP_PLAN = 3;
our $BackupConfigDetails_BACKUPDR_TEMPLATE = 4;

# Enum: BackupConfigDetails::State
our $BackupConfigDetails_STATE_UNSPECIFIED = 0;
our $BackupConfigDetails_ACTIVE = 1;
our $BackupConfigDetails_INACTIVE = 2;
our $BackupConfigDetails_ERROR = 3;

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings ===
    # Fields for PitrSettings
    # Field: retention_days Type: 5 ()

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig ===
    # Fields for BackupDrTemplateConfig
    # Field: first_party_management_uri Type: 9 ()
    # Field: third_party_management_uri Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig ===
    # Fields for BackupDrPlanConfig
    # Field: backup_dr_plan_rules Type: 11 (.google.cloud.backupdr.v1.BackupDrPlanRule)

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule ===
    # Fields for BackupDrPlanRule
    # Field: rule_id Type: 9 ()
    # Field: last_successful_backup_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation ===
    # Fields for BackupLocation
    # Field: type Type: 14 (.google.cloud.backupdr.v1.BackupLocation.Type)
    # Field: location_id Type: 9 ()

# Enum: BackupLocation::Type
our $BackupLocation_TYPE_UNSPECIFIED = 0;
our $BackupLocation_ZONAL = 1;
our $BackupLocation_REGIONAL = 2;
our $BackupLocation_MULTI_REGIONAL = 3;

# === Service Client: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrProtectionSummaryClient ===
package Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrProtectionSummaryClient;

=pod

=head2 Service Client: Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrProtectionSummaryClient

Client stub representing the remote C<BackupDrProtectionSummary> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<backupdr.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'backupdr.googleapis.com:443' );

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

sub list_resource_backup_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.backupdr.v1.BackupDrProtectionSummary',
        method         => 'ListResourceBackupConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::ProtectionSummary - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/protection_summary.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::ProtectionSummary;

    my $msg = Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/protection_summary.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest

Request for ListResourceBackupConfigs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve resource backup
configs. Format: 'projects/{project_id}/locations/{location}'. In Google
Cloud Backup and DR, locations map to Google Cloud regions, for example
B<us-central1>.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will use 100 as default. Maximum value is
500 and values above 500 will be coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse

Response for ListResourceBackupConfigs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_backup_configs() >> / C<< $msg->resource_backup_configs($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig>)

The list of ResourceBackupConfigs for the specified scope.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig

ResourceBackupConfig represents a resource along with its backup
configurations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the ResourceBackupConfig.
Format:
projects/{project}/locations/{location}/resourceBackupConfigs/{uid}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The unique identifier of the resource backup config.

=item * C<< $msg->target_resource() >> / C<< $msg->target_resource($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the cloud resource that this configuration applies to. Supported
resource types are
[ResourceBackupConfig.ResourceType][google.cloud.backupdr.v1.ResourceBackupConfig.ResourceType].

=item * C<< $msg->target_resource_display_name() >> / C<< $msg->target_resource_display_name($value) >>

Type: C<String>

Output only. The human friendly name of the target resource.

=item * C<< $msg->target_resource_type() >> / C<< $msg->target_resource_type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::ResourceBackupConfig::ResourceType>)

Output only. The type of the target resource.

=item * C<< $msg->target_resource_labels() >> / C<< $msg->target_resource_labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig::TargetResourceLabelsEntry>)

Labels associated with the target resource.

=item * C<< $msg->backup_configs_details() >> / C<< $msg->backup_configs_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails>)

Backup configurations applying to the target resource, including those
targeting its related/child resources. For example, backup configuration
applicable to Compute Engine disks will be populated in this field for a
Compute Engine VM which has the disk associated.

=item * C<< $msg->backup_configured() >> / C<< $msg->backup_configured($value) >>

Type: C<Bool>

Output only. Whether the target resource is configured for backup. This is
true if the backup_configs_details is not empty.

=item * C<< $msg->vaulted() >> / C<< $msg->vaulted($value) >>

Type: C<Bool>

Output only. Whether the target resource is protected by a backup vault.
This is true if the backup_configs_details is not empty and any of the
[ResourceBackupConfig.backup_configs_details][google.cloud.backupdr.v1.ResourceBackupConfig.backup_configs_details]
has a backup configuration with
[BackupConfigDetails.backup_vault][google.cloud.backupdr.v1.BackupConfigDetails.backup_vault]
set. set.

=back

=head3 Enum: ResourceBackupConfig::ResourceType

=over 4

=item * C<RESOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_SQL_INSTANCE> => C<1>

=item * C<COMPUTE_ENGINE_VM> => C<2>

=item * C<COMPUTE_ENGINE_DISK> => C<3>

=item * C<COMPUTE_ENGINE_REGIONAL_DISK> => C<4>

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails

BackupConfigDetails has information about how the resource is configured
for backups and about the most recent backup taken for this configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_config_source() >> / C<< $msg->backup_config_source($value) >>

Type: C<String>

Output only. The full resource name of the backup config source resource.
For example,
"//backupdr.googleapis.com/v1/projects/{project}/locations/{region}/backupPlans/{backupplanId}"
or
"//compute.googleapis.com/projects/{project}/locations/{region}/resourcePolicies/{resourcePolicyId}".

=item * C<< $msg->backup_config_source_display_name() >> / C<< $msg->backup_config_source_display_name($value) >>

Type: C<String>

Output only. The display name of the backup config source resource.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::BackupConfigDetails::Type>)

Output only. The type of the backup config resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::BackupConfigDetails::State>)

Output only. The state of the backup config resource.

=item * C<< $msg->pitr_settings() >> / C<< $msg->pitr_settings($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings>)

Output only. Point in time recovery settings of the backup configuration
resource.

=item * C<< $msg->latest_successful_backup_time() >> / C<< $msg->latest_successful_backup_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the latest successful backup created via this
backup configuration.

=item * C<< $msg->applicable_resource() >> / C<< $msg->applicable_resource($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the resource that is applicable for the backup configuration. Example:
"//compute.googleapis.com/projects/{project}/zones/{zone}/instances/{instance}"

=item * C<< $msg->backup_vault() >> / C<< $msg->backup_vault($value) >>

Type: C<String>

Output only. The [full resource
name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
of the backup vault that will store the backups generated through this
backup configuration. Example:
"//backupdr.googleapis.com/v1/projects/{project}/locations/{region}/backupVaults/{backupvaultId}"

=item * C<< $msg->backup_locations() >> / C<< $msg->backup_locations($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation>)

The locations where the backups are to be stored.

=item * C<< $msg->backup_dr_plan_config() >> / C<< $msg->backup_dr_plan_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig>)

Google Cloud Backup and DR's Backup Plan specific data.

=item * C<< $msg->backup_dr_template_config() >> / C<< $msg->backup_dr_template_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig>)

Google Cloud Backup and DR's Template specific data.

=back

=head3 Enum: BackupConfigDetails::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_SQL_INSTANCE_BACKUP_CONFIG> => C<1>

=item * C<COMPUTE_ENGINE_RESOURCE_POLICY> => C<2>

=item * C<BACKUPDR_BACKUP_PLAN> => C<3>

=item * C<BACKUPDR_TEMPLATE> => C<4>

=back

=head3 Enum: BackupConfigDetails::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<INACTIVE> => C<2>

=item * C<ERROR> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings

Point in time recovery settings of the backup configuration resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Output only. Number of days to retain the backup.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig

Provides additional information about Google Cloud Backup
and DR's Template backup configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_party_management_uri() >> / C<< $msg->first_party_management_uri($value) >>

Type: C<String>

Output only. The URI of the BackupDr template resource for the first party
identity users.

=item * C<< $msg->third_party_management_uri() >> / C<< $msg->third_party_management_uri($value) >>

Type: C<String>

Output only. The URI of the BackupDr template resource for the third party
identity users.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig

BackupDrPlanConfig has additional information about Google Cloud Backup and
DR's Plan backup configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_dr_plan_rules() >> / C<< $msg->backup_dr_plan_rules($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule>)

Backup rules of the backup plan resource.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule

BackupDrPlanRule has rule specific information of the backup plan resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_id() >> / C<< $msg->rule_id($value) >>

Type: C<String>

Output only. Unique Id of the backup rule.

=item * C<< $msg->last_successful_backup_time() >> / C<< $msg->last_successful_backup_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the latest successful backup created via this
backup rule.

=back

=head2 Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation

BackupLocation represents a cloud location where a backup can be stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::BackupLocation::Type>)

Output only. The type of the location.

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Output only. The id of the cloud location. Example: "us-central1"

=back

=head3 Enum: BackupLocation::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<ZONAL> => C<1>

=item * C<REGIONAL> => C<2>

=item * C<MULTI_REGIONAL> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::ProtectionSummary::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
