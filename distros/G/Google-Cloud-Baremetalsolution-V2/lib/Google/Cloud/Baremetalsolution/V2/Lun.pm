package Google::Cloud::Baremetalsolution::V2::Lun;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvbHVuLnByb3RvEiFnb29nbGUu
Y2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8i1gcKA0x1bhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSDgoCaWQYCiAB
KAlSAmlkEkIKBXN0YXRlGAIgASgOMiwuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9u
LnYyLkx1bi5TdGF0ZVIFc3RhdGUSFwoHc2l6ZV9nYhgDIAEoA1IGc2l6ZUdiEmcKEm11bHRp
cHJvdG9jb2xfdHlwZRgEIAEoDjI4Lmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52
Mi5MdW4uTXVsdGlwcm90b2NvbFR5cGVSEW11bHRpcHJvdG9jb2xUeXBlElMKDnN0b3JhZ2Vf
dm9sdW1lGAUgASgJQiz6QSkKJ2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1Zv
bHVtZVINc3RvcmFnZVZvbHVtZRIcCglzaGFyZWFibGUYBiABKAhSCXNoYXJlYWJsZRIZCghi
b290X2x1bhgHIAEoCFIHYm9vdEx1bhJVCgxzdG9yYWdlX3R5cGUYCCABKA4yMi5nb29nbGUu
Y2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuTHVuLlN0b3JhZ2VUeXBlUgtzdG9yYWdlVHlw
ZRISCgR3d2lkGAkgASgJUgR3d2lkEkAKC2V4cGlyZV90aW1lGAsgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpleHBpcmVUaW1lEk8KCWluc3RhbmNlcxgMIAMoCUIx
4EED+kErCiliYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIJaW5z
dGFuY2VzImEKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIM
CghVUERBVElORxACEgkKBVJFQURZEAMSDAoIREVMRVRJTkcQBBIMCghDT09MX09GRhAFIkIK
EU11bHRpcHJvdG9jb2xUeXBlEiIKHk1VTFRJUFJPVE9DT0xfVFlQRV9VTlNQRUNJRklFRBAA
EgkKBUxJTlVYEAEiPQoLU3RvcmFnZVR5cGUSHAoYU1RPUkFHRV9UWVBFX1VOU1BFQ0lGSUVE
EAASBwoDU1NEEAESBwoDSEREEAI6bupBawokYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBp
cy5jb20vTHVuEkNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdm9s
dW1lcy97dm9sdW1lfS9sdW5zL3tsdW59IlEKDUdldEx1blJlcXVlc3QSQAoEbmFtZRgBIAEo
CUIs4EEC+kEmCiRiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9MdW5SBG5hbWUi
lgEKD0xpc3RMdW5zUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKQonYmFyZW1ldGFs
c29sdXRpb24uZ29vZ2xlYXBpcy5jb20vVm9sdW1lUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIg
ASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4imAEKEExpc3RM
dW5zUmVzcG9uc2USOgoEbHVucxgBIAMoCzImLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1
dGlvbi52Mi5MdW5SBGx1bnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJTCg9FdmljdEx1blJlcXVl
c3QSQAoEbmFtZRgBIAEoCUIs4EEC+kEmCiRiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlz
LmNvbS9MdW5SBG5hbWVC9wEKJWNvbS5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24u
djJCCEx1blByb3RvUAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vYmFyZW1ldGFsc29sdXRpb24v
YXBpdjIvYmFyZW1ldGFsc29sdXRpb25wYjtiYXJlbWV0YWxzb2x1dGlvbnBiqgIhR29vZ2xl
LkNsb3VkLkJhcmVNZXRhbFNvbHV0aW9uLlYyygIhR29vZ2xlXENsb3VkXEJhcmVNZXRhbFNv
bHV0aW9uXFYy6gIkR29vZ2xlOjpDbG91ZDo6QmFyZU1ldGFsU29sdXRpb246OlYySsgmCgcS
BQ4AsAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAPgoJCgIIJRIDFgA+CggK
AQgSAxcAagoJCgIICxIDFwBqCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAKQoJCgII
CBIDGQApCggKAQgSAxoAPgoJCgIIARIDGgA+CggKAQgSAxsAPgoJCgIIKRIDGwA+CggKAQgS
AxwAPQoJCgIILRIDHAA9CjkKAgQAEgQfAHwBGi0gQSBzdG9yYWdlIHZvbHVtZSBsb2dpY2Fs
IHVuaXQgbnVtYmVyIChMVU4pLgoKCgoDBAABEgMfCAsKCwoDBAAHEgQgAiMECg0KBQQAB50I
EgQgAiMECjAKBAQABAASBCYCOAMaIiBUaGUgcG9zc2libGUgc3RhdGVzIGZvciB0aGUgTFVO
LgoKDAoFBAAEAAESAyYHDAowCgYEAAQAAgASAygEGhohIFRoZSBMVU4gaXMgaW4gYW4gdW5r
bm93biBzdGF0ZS4KCg4KBwQABAACAAESAygEFQoOCgcEAAQAAgACEgMoGBkKKgoGBAAEAAIB
EgMrBBEaGyBUaGUgTFVOIGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMrBAwKDgoH
BAAEAAIBAhIDKw8QCioKBgQABAACAhIDLgQRGhsgVGhlIExVTiBpcyBiZWluZyB1cGRhdGVk
LgoKDgoHBAAEAAICARIDLgQMCg4KBwQABAACAgISAy4PEAoqCgYEAAQAAgMSAzEEDhobIFRo
ZSBMVU4gaXMgcmVhZHkgZm9yIHVzZS4KCg4KBwQABAACAwESAzEECQoOCgcEAAQAAgMCEgMx
DA0KOgoGBAAEAAIEEgM0BBEaKyBUaGUgTFVOIGhhcyBiZWVuIHJlcXVlc3RlZCB0byBiZSBk
ZWxldGVkLgoKDgoHBAAEAAIEARIDNAQMCg4KBwQABAACBAISAzQPEApWCgYEAAQAAgUSAzcE
ERpHIFRoZSBMVU4gaXMgaW4gY29vbCBvZmYgc3RhdGUuIEl0IHdpbGwgYmUgZGVsZXRlZCBh
ZnRlciBgZXhwaXJlX3RpbWVgLgoKDgoHBAAEAAIFARIDNwQMCg4KBwQABAACBQISAzcPEApV
CgQEAAQBEgQ7AkEDGkcgRGlzcGxheSB0aGUgb3BlcmF0aW5nIHN5c3RlbXMgcHJlc2VudCBm
b3IgdGhlIExVTiBtdWx0aXByb3RvY29sIHR5cGUuCgoMCgUEAAQBARIDOwcYCiwKBgQABAEC
ABIDPQQnGh0gU2VydmVyIGhhcyBubyBPUyBzcGVjaWZpZWQuCgoOCgcEAAQBAgABEgM9BCIK
DgoHBAAEAQIAAhIDPSUmCiYKBgQABAECARIDQAQOGhcgU2VydmVyIHdpdGggTGludXggT1Mu
CgoOCgcEAAQBAgEBEgNABAkKDgoHBAAEAQIBAhIDQAwNCiwKBAQABAISBEQCTQMaHiBUaGUg
c3RvcmFnZSB0eXBlcyBmb3IgYSBMVU4uCgoMCgUEAAQCARIDRAcSCjoKBgQABAICABIDRgQh
GisgVGhlIHN0b3JhZ2UgdHlwZSBmb3IgdGhpcyBMVU4gaXMgdW5rbm93bi4KCg4KBwQABAIC
AAESA0YEHAoOCgcEAAQCAgACEgNGHyAKNwoGBAAEAgIBEgNJBAwaKCBUaGlzIHN0b3JhZ2Ug
dHlwZSBmb3IgdGhpcyBMVU4gaXMgU1NELgoKDgoHBAAEAgIBARIDSQQHCg4KBwQABAICAQIS
A0kKCwo3CgYEAAQCAgISA0wEDBooIFRoaXMgc3RvcmFnZSB0eXBlIGZvciB0aGlzIExVTiBp
cyBIREQuCgoOCgcEAAQCAgIBEgNMBAcKDgoHBAAEAgICAhIDTAoLCjAKBAQAAgASA1ACPhoj
IE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUgTFVOLgoKDAoFBAACAAUSA1ACCAoMCgUE
AAIAARIDUAkNCgwKBQQAAgADEgNQEBEKDAoFBAACAAgSA1ASPQoPCggEAAIACJwIABIDUBM8
CkMKBAQAAgESA1MCERo2IEFuIGlkZW50aWZpZXIgZm9yIHRoZSBMVU4sIGdlbmVyYXRlZCBi
eSB0aGUgYmFja2VuZC4KCgwKBQQAAgEFEgNTAggKDAoFBAACAQESA1MJCwoMCgUEAAIBAxID
Uw4QCjAKBAQAAgISA1YCEhojIFRoZSBzdGF0ZSBvZiB0aGlzIHN0b3JhZ2Ugdm9sdW1lLgoK
DAoFBAACAgYSA1YCBwoMCgUEAAICARIDVggNCgwKBQQAAgIDEgNWEBEKMgoEBAACAxIDWQIU
GiUgVGhlIHNpemUgb2YgdGhpcyBMVU4sIGluIGdpZ2FieXRlcy4KCgwKBQQAAgMFEgNZAgcK
DAoFBAACAwESA1kIDwoMCgUEAAIDAxIDWRITCnoKBAQAAgQSA10CKxptIFRoZSBMVU4gbXVs
dGlwcm90b2NvbCB0eXBlIGVuc3VyZXMgdGhlIGNoYXJhY3RlcmlzdGljcyBvZiB0aGUgTFVO
IGFyZQogb3B0aW1pemVkIGZvciBlYWNoIG9wZXJhdGluZyBzeXN0ZW0uCgoMCgUEAAIEBhID
XQITCgwKBQQAAgQBEgNdFCYKDAoFBAACBAMSA10pKgo4CgQEAAIFEgRgAmIFGiogRGlzcGxh
eSB0aGUgc3RvcmFnZSB2b2x1bWUgZm9yIHRoaXMgTFVOLgoKDAoFBAACBQUSA2ACCAoMCgUE
AAIFARIDYAkXCgwKBQQAAgUDEgNgGhsKDQoFBAACBQgSBGAcYgQKDwoHBAACBQifCBIEYB1i
AwpTCgQEAAIGEgNlAhUaRiBEaXNwbGF5IGlmIHRoaXMgTFVOIGNhbiBiZSBzaGFyZWQgYmV0
d2VlbiBtdWx0aXBsZSBwaHlzaWNhbCBzZXJ2ZXJzLgoKDAoFBAACBgUSA2UCBgoMCgUEAAIG
ARIDZQcQCgwKBQQAAgYDEgNlExQKMQoEBAACBxIDaAIUGiQgRGlzcGxheSBpZiB0aGlzIExV
TiBpcyBhIGJvb3QgTFVOLgoKDAoFBAACBwUSA2gCBgoMCgUEAAIHARIDaAcPCgwKBQQAAgcD
EgNoEhMKLQoEBAACCBIDawIfGiAgVGhlIHN0b3JhZ2UgdHlwZSBmb3IgdGhpcyBMVU4uCgoM
CgUEAAIIBhIDawINCgwKBQQAAggBEgNrDhoKDAoFBAACCAMSA2sdHgolCgQEAAIJEgNuAhIa
GCBUaGUgV1dJRCBmb3IgdGhpcyBMVU4uCgoMCgUEAAIJBRIDbgIICgwKBQQAAgkBEgNuCQ0K
DAoFBAACCQMSA24QEQp3CgQEAAIKEgRyAnMyGmkgT3V0cHV0IG9ubHkuIFRpbWUgYWZ0ZXIg
d2hpY2ggTFVOIHdpbGwgYmUgZnVsbHkgZGVsZXRlZC4KIEl0IGlzIGZpbGxlZCBvbmx5IGZv
ciBMVU5zIGluIENPT0xfT0ZGIHN0YXRlLgoKDAoFBAACCgYSA3ICGwoMCgUEAAIKARIDchwn
CgwKBQQAAgoDEgNyKiwKDAoFBAACCggSA3MGMQoPCggEAAIKCJwIABIDcwcwCj8KBAQAAgsS
BHYCewQaMSBPdXRwdXQgb25seS4gSW5zdGFuY2VzIHRoaXMgTHVuIGlzIGF0dGFjaGVkIHRv
LgoKDAoFBAACCwQSA3YCCgoMCgUEAAILBRIDdgsRCgwKBQQAAgsBEgN2EhsKDAoFBAACCwMS
A3YeIAoNCgUEAAILCBIEdiF7AwoPCggEAAILCJwIABIDdwQtCg8KBwQAAgsInwgSBHgEegUK
PgoCBAESBX8AhwEBGjEgTWVzc2FnZSBmb3IgcmVxdWVzdGluZyBzdG9yYWdlIGx1biBpbmZv
cm1hdGlvbi4KCgoKAwQBARIDfwgVCjEKBAQBAgASBoEBAoYBBBohIFJlcXVpcmVkLiBOYW1l
IG9mIHRoZSByZXNvdXJjZS4KCg0KBQQBAgAFEgSBAQIICg0KBQQBAgABEgSBAQkNCg0KBQQB
AgADEgSBARARCg8KBQQBAgAIEgaBARKGAQMKEAoIBAECAAicCAASBIIBBCoKEQoHBAECAAif
CBIGgwEEhQEFCkUKAgQCEgaKAQCZAQEaNyBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEgbGlz
dCBvZiBzdG9yYWdlIHZvbHVtZSBsdW5zLgoKCwoDBAIBEgSKAQgXCj0KBAQCAgASBowBApEB
BBotIFJlcXVpcmVkLiBQYXJlbnQgdmFsdWUgZm9yIExpc3RMdW5zUmVxdWVzdC4KCg0KBQQC
AgAFEgSMAQIICg0KBQQCAgABEgSMAQkPCg0KBQQCAgADEgSMARITCg8KBQQCAgAIEgaMARSR
AQMKEAoIBAICAAicCAASBI0BBCoKEQoHBAICAAifCBIGjgEEkAEFCpMBCgQEAgIBEgSVAQIW
GoQBIFJlcXVlc3RlZCBwYWdlIHNpemUuIFRoZSBzZXJ2ZXIgbWlnaHQgcmV0dXJuIGZld2Vy
IGl0ZW1zIHRoYW4gcmVxdWVzdGVkLgogSWYgdW5zcGVjaWZpZWQsIHNlcnZlciB3aWxsIHBp
Y2sgYW4gYXBwcm9wcmlhdGUgZGVmYXVsdC4KCg0KBQQCAgEFEgSVAQIHCg0KBQQCAgEBEgSV
AQgRCg0KBQQCAgEDEgSVARQVCkYKBAQCAgISBJgBAhgaOCBBIHRva2VuIGlkZW50aWZ5aW5n
IGEgcGFnZSBvZiByZXN1bHRzIGZyb20gdGhlIHNlcnZlci4KCg0KBQQCAgIFEgSYAQIICg0K
BQQCAgIBEgSYAQkTCg0KBQQCAgIDEgSYARYXCkwKAgQDEgacAQClAQEaPiBSZXNwb25zZSBt
ZXNzYWdlIGNvbnRhaW5pbmcgdGhlIGxpc3Qgb2Ygc3RvcmFnZSB2b2x1bWUgbHVucy4KCgsK
AwQDARIEnAEIGAohCgQEAwIAEgSeAQIYGhMgVGhlIGxpc3Qgb2YgbHVucy4KCg0KBQQDAgAE
EgSeAQIKCg0KBQQDAgAGEgSeAQsOCg0KBQQDAgABEgSeAQ8TCg0KBQQDAgADEgSeARYXCkYK
BAQDAgESBKEBAh0aOCBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIGZy
b20gdGhlIHNlcnZlci4KCg0KBQQDAgEFEgShAQIICg0KBQQDAgEBEgShAQkYCg0KBQQDAgED
EgShARscCjQKBAQDAgISBKQBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVh
Y2hlZC4KCg0KBQQDAgIEEgSkAQIKCg0KBQQDAgIFEgSkAQsRCg0KBQQDAgIBEgSkARIdCg0K
BQQDAgIDEgSkASAhCjsKAgQEEgaoAQCwAQEaLSBSZXF1ZXN0IGZvciBza2lwIGx1biBjb29s
b2ZmIGFuZCBkZWxldGUgaXQuCgoLCgMEBAESBKgBCBcKMAoEBAQCABIGqgECrwEEGiAgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBsdW4uCgoNCgUEBAIABRIEqgECCAoNCgUEBAIAARIE
qgEJDQoNCgUEBAIAAxIEqgEQEQoPCgUEBAIACBIGqgESrwEDChAKCAQEAgAInAgAEgSrAQQq
ChEKBwQEAgAInwgSBqwBBK4BBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::Lun::Lun ===
    # Fields for Lun
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.Lun.State)
    # Field: size_gb Type: 3 ()
    # Field: multiprotocol_type Type: 14 (.google.cloud.baremetalsolution.v2.Lun.MultiprotocolType)
    # Field: storage_volume Type: 9 ()
    # Field: shareable Type: 8 ()
    # Field: boot_lun Type: 8 ()
    # Field: storage_type Type: 14 (.google.cloud.baremetalsolution.v2.Lun.StorageType)
    # Field: wwid Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instances Type: 9 ()

# Enum: Lun::State
our $Lun_STATE_UNSPECIFIED = 0;
our $Lun_CREATING = 1;
our $Lun_UPDATING = 2;
our $Lun_READY = 3;
our $Lun_DELETING = 4;
our $Lun_COOL_OFF = 5;

# Enum: Lun::MultiprotocolType
our $Lun_MULTIPROTOCOL_TYPE_UNSPECIFIED = 0;
our $Lun_LINUX = 1;

# Enum: Lun::StorageType
our $Lun_STORAGE_TYPE_UNSPECIFIED = 0;
our $Lun_SSD = 1;
our $Lun_HDD = 2;

# === Message: Google::Cloud::Baremetalsolution::V2::Lun::GetLunRequest ===
    # Fields for GetLunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Lun::ListLunsRequest ===
    # Fields for ListLunsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Lun::ListLunsResponse ===
    # Fields for ListLunsResponse
    # Field: luns Type: 11 (.google.cloud.baremetalsolution.v2.Lun)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Lun::EvictLunRequest ===
    # Fields for EvictLunRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Lun - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/lun.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::Lun;

    my $msg = Google::Cloud::Baremetalsolution::V2::Lun::Lun->new({
        name => $name,
        id => $id,
        state => $state,
        size_gb => $size_gb,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::Lun::Lun->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/lun.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::Lun::Lun

A storage volume logical unit number (LUN).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the LUN.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

An identifier for the LUN, generated by the backend.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Lun::State>)

The state of this storage volume.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

The size of this LUN, in gigabytes.

=item * C<< $msg->multiprotocol_type() >> / C<< $msg->multiprotocol_type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Lun::MultiprotocolType>)

The LUN multiprotocol type ensures the characteristics of the LUN are
optimized for each operating system.

=item * C<< $msg->storage_volume() >> / C<< $msg->storage_volume($value) >>

Type: C<String>

Display the storage volume for this LUN.

=item * C<< $msg->shareable() >> / C<< $msg->shareable($value) >>

Type: C<Bool>

Display if this LUN can be shared between multiple physical servers.

=item * C<< $msg->boot_lun() >> / C<< $msg->boot_lun($value) >>

Type: C<Bool>

Display if this LUN is a boot LUN.

=item * C<< $msg->storage_type() >> / C<< $msg->storage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Lun::StorageType>)

The storage type for this LUN.

=item * C<< $msg->wwid() >> / C<< $msg->wwid($value) >>

Type: C<String>

The WWID for this LUN.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time after which LUN will be fully deleted.
It is filled only for LUNs in COOL_OFF state.

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<String>

Output only. Instances this Lun is attached to.

=back

=head3 Enum: Lun::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPDATING> => C<2>

=item * C<READY> => C<3>

=item * C<DELETING> => C<4>

=item * C<COOL_OFF> => C<5>

=back

=head3 Enum: Lun::MultiprotocolType

=over 4

=item * C<MULTIPROTOCOL_TYPE_UNSPECIFIED> => C<0>

=item * C<LINUX> => C<1>

=back

=head3 Enum: Lun::StorageType

=over 4

=item * C<STORAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<SSD> => C<1>

=item * C<HDD> => C<2>

=back

=head2 Google::Cloud::Baremetalsolution::V2::Lun::GetLunRequest

Message for requesting storage lun information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Lun::ListLunsRequest

Message for requesting a list of storage volume luns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListLunsRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Lun::ListLunsResponse

Response message containing the list of storage volume luns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->luns() >> / C<< $msg->luns($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Lun::Lun>)

The list of luns.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Lun::EvictLunRequest

Request for skip lun cooloff and delete it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the lun.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::Lun::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
