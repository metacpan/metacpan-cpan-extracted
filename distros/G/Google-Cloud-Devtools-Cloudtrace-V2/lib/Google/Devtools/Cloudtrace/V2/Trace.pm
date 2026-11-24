package Google::Devtools::Cloudtrace::V2::Trace;

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
    eval { require Google::Protobuf::Wrappers };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvZGV2dG9vbHMvY2xvdWR0cmFjZS92Mi90cmFjZS5wcm90bxIdZ29vZ2xlLmRl
dnRvb2xzLmNsb3VkdHJhY2UudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8aHmdvb2dsZS9wcm90b2J1Zi93cmFwcGVycy5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0
dXMucHJvdG8isBUKBFNwYW4SFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEhwKB3NwYW5faWQY
AiABKAlCA+BBAlIGc3BhbklkEiQKDnBhcmVudF9zcGFuX2lkGAMgASgJUgxwYXJlbnRTcGFu
SWQSWAoMZGlzcGxheV9uYW1lGAQgASgLMjAuZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2Uu
djIuVHJ1bmNhdGFibGVTdHJpbmdCA+BBAlILZGlzcGxheU5hbWUSPgoKc3RhcnRfdGltZRgF
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIJc3RhcnRUaW1lEjoKCGVu
ZF90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EECUgdlbmRUaW1l
Ek4KCmF0dHJpYnV0ZXMYByABKAsyLi5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5T
cGFuLkF0dHJpYnV0ZXNSCmF0dHJpYnV0ZXMSSgoLc3RhY2tfdHJhY2UYCCABKAsyKS5nb29n
bGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5TdGFja1RyYWNlUgpzdGFja1RyYWNlEk8KC3Rp
bWVfZXZlbnRzGAkgASgLMi4uZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuU3Bhbi5U
aW1lRXZlbnRzUgp0aW1lRXZlbnRzEj8KBWxpbmtzGAogASgLMikuZ29vZ2xlLmRldnRvb2xz
LmNsb3VkdHJhY2UudjIuU3Bhbi5MaW5rc1IFbGlua3MSLwoGc3RhdHVzGAsgASgLMhIuZ29v
Z2xlLnJwYy5TdGF0dXNCA+BBAVIGc3RhdHVzEl0KG3NhbWVfcHJvY2Vzc19hc19wYXJlbnRf
c3BhbhgMIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5Cb29sVmFsdWVCA+BBAVIXc2FtZVByb2Nl
c3NBc1BhcmVudFNwYW4SSgoQY2hpbGRfc3Bhbl9jb3VudBgNIAEoCzIbLmdvb2dsZS5wcm90
b2J1Zi5JbnQzMlZhbHVlQgPgQQFSDmNoaWxkU3BhbkNvdW50Ek4KCXNwYW5fa2luZBgOIAEo
DjIsLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyLlNwYW4uU3BhbktpbmRCA+BBAVII
c3BhbktpbmQanQIKCkF0dHJpYnV0ZXMSZQoNYXR0cmlidXRlX21hcBgBIAMoCzJALmdvb2ds
ZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyLlNwYW4uQXR0cmlidXRlcy5BdHRyaWJ1dGVNYXBF
bnRyeVIMYXR0cmlidXRlTWFwEjgKGGRyb3BwZWRfYXR0cmlidXRlc19jb3VudBgCIAEoBVIW
ZHJvcHBlZEF0dHJpYnV0ZXNDb3VudBpuChFBdHRyaWJ1dGVNYXBFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRJDCgV2YWx1ZRgCIAEoCzItLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYy
LkF0dHJpYnV0ZVZhbHVlUgV2YWx1ZToCOAEazgUKCVRpbWVFdmVudBIuCgR0aW1lGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIEdGltZRJaCgphbm5vdGF0aW9uGAIgASgL
MjguZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuU3Bhbi5UaW1lRXZlbnQuQW5ub3Rh
dGlvbkgAUgphbm5vdGF0aW9uEmEKDW1lc3NhZ2VfZXZlbnQYAyABKAsyOi5nb29nbGUuZGV2
dG9vbHMuY2xvdWR0cmFjZS52Mi5TcGFuLlRpbWVFdmVudC5NZXNzYWdlRXZlbnRIAFIMbWVz
c2FnZUV2ZW50GrABCgpBbm5vdGF0aW9uElIKC2Rlc2NyaXB0aW9uGAEgASgLMjAuZ29vZ2xl
LmRldnRvb2xzLmNsb3VkdHJhY2UudjIuVHJ1bmNhdGFibGVTdHJpbmdSC2Rlc2NyaXB0aW9u
Ek4KCmF0dHJpYnV0ZXMYAiABKAsyLi5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5T
cGFuLkF0dHJpYnV0ZXNSCmF0dHJpYnV0ZXMalQIKDE1lc3NhZ2VFdmVudBJTCgR0eXBlGAEg
ASgOMj8uZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuU3Bhbi5UaW1lRXZlbnQuTWVz
c2FnZUV2ZW50LlR5cGVSBHR5cGUSDgoCaWQYAiABKANSAmlkEjYKF3VuY29tcHJlc3NlZF9z
aXplX2J5dGVzGAMgASgDUhV1bmNvbXByZXNzZWRTaXplQnl0ZXMSMgoVY29tcHJlc3NlZF9z
aXplX2J5dGVzGAQgASgDUhNjb21wcmVzc2VkU2l6ZUJ5dGVzIjQKBFR5cGUSFAoQVFlQRV9V
TlNQRUNJRklFRBAAEggKBFNFTlQQARIMCghSRUNFSVZFRBACQgcKBXZhbHVlGtcBCgpUaW1l
RXZlbnRzEkwKCnRpbWVfZXZlbnQYASADKAsyLS5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFj
ZS52Mi5TcGFuLlRpbWVFdmVudFIJdGltZUV2ZW50EjoKGWRyb3BwZWRfYW5ub3RhdGlvbnNf
Y291bnQYAiABKAVSF2Ryb3BwZWRBbm5vdGF0aW9uc0NvdW50Ej8KHGRyb3BwZWRfbWVzc2Fn
ZV9ldmVudHNfY291bnQYAyABKAVSGWRyb3BwZWRNZXNzYWdlRXZlbnRzQ291bnQamgIKBExp
bmsSGQoIdHJhY2VfaWQYASABKAlSB3RyYWNlSWQSFwoHc3Bhbl9pZBgCIAEoCVIGc3Bhbklk
EkEKBHR5cGUYAyABKA4yLS5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5TcGFuLkxp
bmsuVHlwZVIEdHlwZRJOCgphdHRyaWJ1dGVzGAQgASgLMi4uZ29vZ2xlLmRldnRvb2xzLmNs
b3VkdHJhY2UudjIuU3Bhbi5BdHRyaWJ1dGVzUgphdHRyaWJ1dGVzIksKBFR5cGUSFAoQVFlQ
RV9VTlNQRUNJRklFRBAAEhUKEUNISUxEX0xJTktFRF9TUEFOEAESFgoSUEFSRU5UX0xJTktF
RF9TUEFOEAIadQoFTGlua3MSPAoEbGluaxgBIAMoCzIoLmdvb2dsZS5kZXZ0b29scy5jbG91
ZHRyYWNlLnYyLlNwYW4uTGlua1IEbGluaxIuChNkcm9wcGVkX2xpbmtzX2NvdW50GAIgASgF
UhFkcm9wcGVkTGlua3NDb3VudCJnCghTcGFuS2luZBIZChVTUEFOX0tJTkRfVU5TUEVDSUZJ
RUQQABIMCghJTlRFUk5BTBABEgoKBlNFUlZFUhACEgoKBkNMSUVOVBADEgwKCFBST0RVQ0VS
EAQSDAoIQ09OU1VNRVIQBTpT6kFQCh5jbG91ZHRyYWNlLmdvb2dsZWFwaXMuY29tL1NwYW4S
LnByb2plY3RzL3twcm9qZWN0fS90cmFjZXMve3RyYWNlfS9zcGFucy97c3Bhbn0isAEKDkF0
dHJpYnV0ZVZhbHVlElUKDHN0cmluZ192YWx1ZRgBIAEoCzIwLmdvb2dsZS5kZXZ0b29scy5j
bG91ZHRyYWNlLnYyLlRydW5jYXRhYmxlU3RyaW5nSABSC3N0cmluZ1ZhbHVlEh0KCWludF92
YWx1ZRgCIAEoA0gAUghpbnRWYWx1ZRIfCgpib29sX3ZhbHVlGAMgASgISABSCWJvb2xWYWx1
ZUIHCgV2YWx1ZSKnBgoKU3RhY2tUcmFjZRJYCgxzdGFja19mcmFtZXMYASABKAsyNS5nb29n
bGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5TdGFja1RyYWNlLlN0YWNrRnJhbWVzUgtzdGFj
a0ZyYW1lcxItChNzdGFja190cmFjZV9oYXNoX2lkGAIgASgDUhBzdGFja1RyYWNlSGFzaElk
GoEECgpTdGFja0ZyYW1lElUKDWZ1bmN0aW9uX25hbWUYASABKAsyMC5nb29nbGUuZGV2dG9v
bHMuY2xvdWR0cmFjZS52Mi5UcnVuY2F0YWJsZVN0cmluZ1IMZnVuY3Rpb25OYW1lEmYKFm9y
aWdpbmFsX2Z1bmN0aW9uX25hbWUYAiABKAsyMC5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFj
ZS52Mi5UcnVuY2F0YWJsZVN0cmluZ1IUb3JpZ2luYWxGdW5jdGlvbk5hbWUSTQoJZmlsZV9u
YW1lGAMgASgLMjAuZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuVHJ1bmNhdGFibGVT
dHJpbmdSCGZpbGVOYW1lEh8KC2xpbmVfbnVtYmVyGAQgASgDUgpsaW5lTnVtYmVyEiMKDWNv
bHVtbl9udW1iZXIYBSABKANSDGNvbHVtbk51bWJlchJGCgtsb2FkX21vZHVsZRgGIAEoCzIl
Lmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyLk1vZHVsZVIKbG9hZE1vZHVsZRJXCg5z
b3VyY2VfdmVyc2lvbhgHIAEoCzIwLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyLlRy
dW5jYXRhYmxlU3RyaW5nUg1zb3VyY2VWZXJzaW9uGosBCgtTdGFja0ZyYW1lcxJKCgVmcmFt
ZRgBIAMoCzI0Lmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyLlN0YWNrVHJhY2UuU3Rh
Y2tGcmFtZVIFZnJhbWUSMAoUZHJvcHBlZF9mcmFtZXNfY291bnQYAiABKAVSEmRyb3BwZWRG
cmFtZXNDb3VudCKfAQoGTW9kdWxlEkgKBm1vZHVsZRgBIAEoCzIwLmdvb2dsZS5kZXZ0b29s
cy5jbG91ZHRyYWNlLnYyLlRydW5jYXRhYmxlU3RyaW5nUgZtb2R1bGUSSwoIYnVpbGRfaWQY
AiABKAsyMC5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52Mi5UcnVuY2F0YWJsZVN0cmlu
Z1IHYnVpbGRJZCJbChFUcnVuY2F0YWJsZVN0cmluZxIUCgV2YWx1ZRgBIAEoCVIFdmFsdWUS
MAoUdHJ1bmNhdGVkX2J5dGVfY291bnQYAiABKAVSEnRydW5jYXRlZEJ5dGVDb3VudEKtAQoh
Y29tLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYyQgpUcmFjZVByb3RvUAFaL2Nsb3Vk
Lmdvb2dsZS5jb20vZ28vdHJhY2UvYXBpdjIvdHJhY2VwYjt0cmFjZXBiqgIVR29vZ2xlLkNs
b3VkLlRyYWNlLlYyygIVR29vZ2xlXENsb3VkXFRyYWNlXFYy6gIYR29vZ2xlOjpDbG91ZDo6
VHJhY2U6OlYySu13CgcSBQ4AggMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAmCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCgkKAgMDEgMV
ACgKCQoCAwQSAxYAIQoICgEIEgMYADIKCQoCCCUSAxgAMgoICgEIEgMZAEYKCQoCCAsSAxkA
RgoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACsKCQoCCAgSAxsAKwoICgEIEgMcADoK
CQoCCAESAxwAOgoICgEIEgMdADIKCQoCCCkSAx0AMgoICgEIEgMeADEKCQoCCC0SAx4AMQqN
AwoCBAASBSgAngIBGv8CIEEgc3BhbiByZXByZXNlbnRzIGEgc2luZ2xlIG9wZXJhdGlvbiB3
aXRoaW4gYSB0cmFjZS4gU3BhbnMgY2FuIGJlCiBuZXN0ZWQgdG8gZm9ybSBhIHRyYWNlIHRy
ZWUuIE9mdGVuLCBhIHRyYWNlIGNvbnRhaW5zIGEgcm9vdCBzcGFuCiB0aGF0IGRlc2NyaWJl
cyB0aGUgZW5kLXRvLWVuZCBsYXRlbmN5LCBhbmQgb25lIG9yIG1vcmUgc3Vic3BhbnMgZm9y
CiBpdHMgc3ViLW9wZXJhdGlvbnMuCgogQSB0cmFjZSBjYW4gYWxzbyBjb250YWluIG11bHRp
cGxlIHJvb3Qgc3BhbnMsIG9yIG5vbmUgYXQgYWxsLgogU3BhbnMgZG8gbm90IG5lZWQgdG8g
YmUgY29udGlndW91cy4gVGhlcmUgbWlnaHQgYmUKIGdhcHMgb3Igb3ZlcmxhcHMgYmV0d2Vl
biBzcGFucyBpbiBhIHRyYWNlLgoKCgoDBAABEgMoCAwKCwoDBAAHEgQpAiwECg0KBQQAB50I
EgQpAiwECjcKBAQAAwASBC8CPQMaKSBBIHNldCBvZiBhdHRyaWJ1dGVzIGFzIGtleS12YWx1
ZSBwYWlycy4KCgwKBQQAAwABEgMvChQK/gIKBgQAAwACABIDNwQyGu4CIEEgc2V0IG9mIGF0
dHJpYnV0ZXMuIEVhY2ggYXR0cmlidXRlJ3Mga2V5IGNhbiBiZSB1cCB0byAxMjggYnl0ZXMK
IGxvbmcuIFRoZSB2YWx1ZSBjYW4gYmUgYSBzdHJpbmcgdXAgdG8gMjU2IGJ5dGVzLCBhIHNp
Z25lZCA2NC1iaXQgaW50ZWdlciwKIG9yIHRoZSBib29sZWFuIHZhbHVlcyBgdHJ1ZWAgb3Ig
YGZhbHNlYC4gRm9yIGV4YW1wbGU6CgogICAgICIvaW5zdGFuY2VfaWQiOiB7ICJzdHJpbmdf
dmFsdWUiOiB7ICJ2YWx1ZSI6ICJteS1pbnN0YW5jZSIgfSB9CiAgICAgIi9odHRwL3JlcXVl
c3RfYnl0ZXMiOiB7ICJpbnRfdmFsdWUiOiAzMDAgfQogICAgICJhYmMuY29tL215YXR0cmli
dXRlIjogeyAiYm9vbF92YWx1ZSI6IGZhbHNlIH0KCg4KBwQAAwACAAYSAzcEHwoOCgcEAAMA
AgABEgM3IC0KDgoHBAADAAIAAxIDNzAxCtkBCgYEAAMAAgESAzwEJxrJASBUaGUgbnVtYmVy
IG9mIGF0dHJpYnV0ZXMgdGhhdCB3ZXJlIGRpc2NhcmRlZC4gQXR0cmlidXRlcyBjYW4gYmUg
ZGlzY2FyZGVkCiBiZWNhdXNlIHRoZWlyIGtleXMgYXJlIHRvbyBsb25nIG9yIGJlY2F1c2Ug
dGhlcmUgYXJlIHRvbyBtYW55IGF0dHJpYnV0ZXMuCiBJZiB0aGlzIHZhbHVlIGlzIDAgdGhl
biBhbGwgYXR0cmlidXRlcyBhcmUgdmFsaWQuCgoOCgcEAAMAAgEFEgM8BAkKDgoHBAADAAIB
ARIDPAoiCg4KBwQAAwACAQMSAzwlJgpHCgQEAAMBEgRAAncDGjkgQSB0aW1lLXN0YW1wZWQg
YW5ub3RhdGlvbiBvciBtZXNzYWdlIGV2ZW50IGluIHRoZSBTcGFuLgoKDAoFBAADAQESA0AK
Ewo7CgYEAAMBAwASBEIESgUaKyBUZXh0IGFubm90YXRpb24gd2l0aCBhIHNldCBvZiBhdHRy
aWJ1dGVzLgoKDgoHBAADAQMAARIDQgwWCnYKCAQAAwEDAAIAEgNFBigaZSBBIHVzZXItc3Vw
cGxpZWQgbWVzc2FnZSBkZXNjcmliaW5nIHRoZSBldmVudC4gVGhlIG1heGltdW0gbGVuZ3Ro
IGZvcgogdGhlIGRlc2NyaXB0aW9uIGlzIDI1NiBieXRlcy4KChAKCQQAAwEDAAIABhIDRQYX
ChAKCQQAAwEDAAIAARIDRRgjChAKCQQAAwEDAAIAAxIDRSYnCmoKCAQAAwEDAAIBEgNJBiAa
WSBBIHNldCBvZiBhdHRyaWJ1dGVzIG9uIHRoZSBhbm5vdGF0aW9uLiBZb3UgY2FuIGhhdmUg
dXAgdG8gNCBhdHRyaWJ1dGVzCiBwZXIgQW5ub3RhdGlvbi4KChAKCQQAAwEDAAIBBhIDSQYQ
ChAKCQQAAwEDAAIBARIDSREbChAKCQQAAwEDAAIBAxIDSR4fCkwKBgQAAwEDARIETQRpBRo8
IEFuIGV2ZW50IGRlc2NyaWJpbmcgYSBtZXNzYWdlIHNlbnQvcmVjZWl2ZWQgYmV0d2VlbiBT
cGFucy4KCg4KBwQAAwEDAQESA00MGApHCggEAAMBAwEEABIETwZYBxo1IEluZGljYXRlcyB3
aGV0aGVyIHRoZSBtZXNzYWdlIHdhcyBzZW50IG9yIHJlY2VpdmVkLgoKEAoJBAADAQMBBAAB
EgNPCw8KKAoKBAADAQMBBAACABIDUQgdGhUgVW5rbm93biBldmVudCB0eXBlLgoKEgoLBAAD
AQMBBAACAAESA1EIGAoSCgsEAAMBAwEEAAIAAhIDURscCi4KCgQAAwEDAQQAAgESA1QIERob
IEluZGljYXRlcyBhIHNlbnQgbWVzc2FnZS4KChIKCwQAAwEDAQQAAgEBEgNUCAwKEgoLBAAD
AQMBBAACAQISA1QPEAoyCgoEAAMBAwEEAAICEgNXCBUaHyBJbmRpY2F0ZXMgYSByZWNlaXZl
ZCBtZXNzYWdlLgoKEgoLBAADAQMBBAACAgESA1cIEAoSCgsEAAMBAwEEAAICAhIDVxMUCl0K
CAQAAwEDAQIAEgNcBhQaTCBUeXBlIG9mIE1lc3NhZ2VFdmVudC4gSW5kaWNhdGVzIHdoZXRo
ZXIgdGhlIG1lc3NhZ2Ugd2FzIHNlbnQgb3IKIHJlY2VpdmVkLgoKEAoJBAADAQMBAgAGEgNc
BgoKEAoJBAADAQMBAgABEgNcCw8KEAoJBAADAQMBAgADEgNcEhMKfwoIBAADAQMBAgESA2AG
ExpuIEFuIGlkZW50aWZpZXIgZm9yIHRoZSBNZXNzYWdlRXZlbnQncyBtZXNzYWdlIHRoYXQg
Y2FuIGJlIHVzZWQgdG8gbWF0Y2gKIGBTRU5UYCBhbmQgYFJFQ0VJVkVEYCBNZXNzYWdlRXZl
bnRzLgoKEAoJBAADAQMBAgEFEgNgBgsKEAoJBAADAQMBAgEBEgNgDA4KEAoJBAADAQMBAgED
EgNgERIKRQoIBAADAQMBAgISA2MGKBo0IFRoZSBudW1iZXIgb2YgdW5jb21wcmVzc2VkIGJ5
dGVzIHNlbnQgb3IgcmVjZWl2ZWQuCgoQCgkEAAMBAwECAgUSA2MGCwoQCgkEAAMBAwECAgES
A2MMIwoQCgkEAAMBAwECAgMSA2MmJwqfAQoIBAADAQMBAgMSA2gGJhqNASBUaGUgbnVtYmVy
IG9mIGNvbXByZXNzZWQgYnl0ZXMgc2VudCBvciByZWNlaXZlZC4gSWYgbWlzc2luZywgdGhl
CiBjb21wcmVzc2VkIHNpemUgaXMgYXNzdW1lZCB0byBiZSB0aGUgc2FtZSBzaXplIGFzIHRo
ZSB1bmNvbXByZXNzZWQKIHNpemUuCgoQCgkEAAMBAwECAwUSA2gGCwoQCgkEAAMBAwECAwES
A2gMIQoQCgkEAAMBAwECAwMSA2gkJQpGCgYEAAMBAgASA2wEJxo3IFRoZSB0aW1lc3RhbXAg
aW5kaWNhdGluZyB0aGUgdGltZSB0aGUgZXZlbnQgb2NjdXJyZWQuCgoOCgcEAAMBAgAGEgNs
BB0KDgoHBAADAQIAARIDbB4iCg4KBwQAAwECAAMSA2wlJgp0CgYEAAMBCAASBHAEdgUaZCBB
IGBUaW1lRXZlbnRgIGNhbiBjb250YWluIGVpdGhlciBhbiBgQW5ub3RhdGlvbmAgb2JqZWN0
IG9yIGEKIGBNZXNzYWdlRXZlbnRgIG9iamVjdCwgYnV0IG5vdCBib3RoLgoKDgoHBAADAQgA
ARIDcAoPCjoKBgQAAwECARIDcgYgGisgVGV4dCBhbm5vdGF0aW9uIHdpdGggYSBzZXQgb2Yg
YXR0cmlidXRlcy4KCg4KBwQAAwECAQYSA3IGEAoOCgcEAAMBAgEBEgNyERsKDgoHBAADAQIB
AxIDch4fCksKBgQAAwECAhIDdQYlGjwgQW4gZXZlbnQgZGVzY3JpYmluZyBhIG1lc3NhZ2Ug
c2VudC9yZWNlaXZlZCBiZXR3ZWVuIFNwYW5zLgoKDgoHBAADAQICBhIDdQYSCg4KBwQAAwEC
AgESA3UTIAoOCgcEAAMBAgIDEgN1IyQK0gEKBAQAAwISBXwChwEDGsIBIEEgY29sbGVjdGlv
biBvZiBgVGltZUV2ZW50YHMuIEEgYFRpbWVFdmVudGAgaXMgYSB0aW1lLXN0YW1wZWQgYW5u
b3RhdGlvbgogb24gdGhlIHNwYW4sIGNvbnNpc3Rpbmcgb2YgZWl0aGVyIHVzZXItc3VwcGxp
ZWQga2V5OnZhbHVlIHBhaXJzLCBvcgogZGV0YWlscyBvZiBhIG1lc3NhZ2Ugc2VudC9yZWNl
aXZlZCBiZXR3ZWVuIFNwYW5zLgoKDAoFBAADAgESA3wKFAouCgYEAAMCAgASA34EJhofIEEg
Y29sbGVjdGlvbiBvZiBgVGltZUV2ZW50YHMuCgoOCgcEAAMCAgAEEgN+BAwKDgoHBAADAgIA
BhIDfg0WCg4KBwQAAwICAAESA34XIQoOCgcEAAMCAgADEgN+JCUKigEKBgQAAwICARIEggEE
KBp6IFRoZSBudW1iZXIgb2YgZHJvcHBlZCBhbm5vdGF0aW9ucyBpbiBhbGwgdGhlIGluY2x1
ZGVkIHRpbWUgZXZlbnRzLgogSWYgdGhlIHZhbHVlIGlzIDAsIHRoZW4gbm8gYW5ub3RhdGlv
bnMgd2VyZSBkcm9wcGVkLgoKDwoHBAADAgIBBRIEggEECQoPCgcEAAMCAgEBEgSCAQojCg8K
BwQAAwICAQMSBIIBJicKkQEKBgQAAwICAhIEhgEEKxqAASBUaGUgbnVtYmVyIG9mIGRyb3Bw
ZWQgbWVzc2FnZSBldmVudHMgaW4gYWxsIHRoZSBpbmNsdWRlZCB0aW1lIGV2ZW50cy4KIElm
IHRoZSB2YWx1ZSBpcyAwLCB0aGVuIG5vIG1lc3NhZ2UgZXZlbnRzIHdlcmUgZHJvcHBlZC4K
Cg8KBwQAAwICAgUSBIYBBAkKDwoHBAADAgICARIEhgEKJgoPCgcEAAMCAgIDEgSGASkqCrYC
CgQEAAMDEgaNAQKnAQMapQIgQSBwb2ludGVyIGZyb20gdGhlIGN1cnJlbnQgc3BhbiB0byBh
bm90aGVyIHNwYW4gaW4gdGhlIHNhbWUgdHJhY2Ugb3IgaW4gYQogZGlmZmVyZW50IHRyYWNl
LiBGb3IgZXhhbXBsZSwgdGhpcyBjYW4gYmUgdXNlZCBpbiBiYXRjaGluZyBvcGVyYXRpb25z
LAogd2hlcmUgYSBzaW5nbGUgYmF0Y2ggaGFuZGxlciBwcm9jZXNzZXMgbXVsdGlwbGUgcmVx
dWVzdHMgZnJvbSBkaWZmZXJlbnQKIHRyYWNlcyBvciB3aGVuIHRoZSBoYW5kbGVyIHJlY2Vp
dmVzIGEgcmVxdWVzdCBmcm9tIGEgZGlmZmVyZW50IHByb2plY3QuCgoNCgUEAAMDARIEjQEK
Dgp1CgYEAAMDBAASBpABBJkBBRpjIFRoZSByZWxhdGlvbnNoaXAgb2YgdGhlIGN1cnJlbnQg
c3BhbiByZWxhdGl2ZSB0byB0aGUgbGlua2VkIHNwYW46IGNoaWxkLAogcGFyZW50LCBvciB1
bnNwZWNpZmllZC4KCg8KBwQAAwMEAAESBJABCQ0KQQoIBAADAwQAAgASBJIBBhsaLyBUaGUg
cmVsYXRpb25zaGlwIG9mIHRoZSB0d28gc3BhbnMgaXMgdW5rbm93bi4KChEKCQQAAwMEAAIA
ARIEkgEGFgoRCgkEAAMDBAACAAISBJIBGRoKQwoIBAADAwQAAgESBJUBBhwaMSBUaGUgbGlu
a2VkIHNwYW4gaXMgYSBjaGlsZCBvZiB0aGUgY3VycmVudCBzcGFuLgoKEQoJBAADAwQAAgEB
EgSVAQYXChEKCQQAAwMEAAIBAhIElQEaGwpECggEAAMDBAACAhIEmAEGHRoyIFRoZSBsaW5r
ZWQgc3BhbiBpcyBhIHBhcmVudCBvZiB0aGUgY3VycmVudCBzcGFuLgoKEQoJBAADAwQAAgIB
EgSYAQYYChEKCQQAAwMEAAICAhIEmAEbHApACgYEAAMDAgASBJwBBBgaMCBUaGUgYFtUUkFD
RV9JRF1gIGZvciBhIHRyYWNlIHdpdGhpbiBhIHByb2plY3QuCgoPCgcEAAMDAgAFEgScAQQK
Cg8KBwQAAwMCAAESBJwBCxMKDwoHBAADAwIAAxIEnAEWFwo8CgYEAAMDAgESBJ8BBBcaLCBU
aGUgYFtTUEFOX0lEXWAgZm9yIGEgc3BhbiB3aXRoaW4gYSB0cmFjZS4KCg8KBwQAAwMCAQUS
BJ8BBAoKDwoHBAADAwIBARIEnwELEgoPCgcEAAMDAgEDEgSfARUWClMKBgQAAwMCAhIEogEE
EhpDIFRoZSByZWxhdGlvbnNoaXAgb2YgdGhlIGN1cnJlbnQgc3BhbiByZWxhdGl2ZSB0byB0
aGUgbGlua2VkIHNwYW4uCgoPCgcEAAMDAgIGEgSiAQQICg8KBwQAAwMCAgESBKIBCQ0KDwoH
BAADAwICAxIEogEQEQpiCgYEAAMDAgMSBKYBBB4aUiBBIHNldCBvZiBhdHRyaWJ1dGVzIG9u
IHRoZSBsaW5rLiBVcCB0byAzMiBhdHRyaWJ1dGVzIGNhbiBiZQogc3BlY2lmaWVkIHBlciBs
aW5rLgoKDwoHBAADAwIDBhIEpgEEDgoPCgcEAAMDAgMBEgSmAQ8ZCg8KBwQAAwMCAwMSBKYB
HB0KdwoEBAADBBIGqwECsgEDGmcgQSBjb2xsZWN0aW9uIG9mIGxpbmtzLCB3aGljaCBhcmUg
cmVmZXJlbmNlcyBmcm9tIHRoaXMgc3BhbiB0byBhIHNwYW4KIGluIHRoZSBzYW1lIG9yIGRp
ZmZlcmVudCB0cmFjZS4KCg0KBQQAAwQBEgSrAQoPCigKBgQAAwQCABIErQEEGxoYIEEgY29s
bGVjdGlvbiBvZiBsaW5rcy4KCg8KBwQAAwQCAAQSBK0BBAwKDwoHBAADBAIABhIErQENEQoP
CgcEAAMEAgABEgStARIWCg8KBwQAAwQCAAMSBK0BGRoKgwEKBgQAAwQCARIEsQEEIhpzIFRo
ZSBudW1iZXIgb2YgZHJvcHBlZCBsaW5rcyBhZnRlciB0aGUgbWF4aW11bSBzaXplIHdhcyBl
bmZvcmNlZC4gSWYKIHRoaXMgdmFsdWUgaXMgMCwgdGhlbiBubyBsaW5rcyB3ZXJlIGRyb3Bw
ZWQuCgoPCgcEAAMEAgEFEgSxAQQJCg8KBwQAAwQCAQESBLEBCh0KDwoHBAADBAIBAxIEsQEg
IQqKAQoEBAAEABIGtgEC0QEDGnogVHlwZSBvZiBzcGFuLiBDYW4gYmUgdXNlZCB0byBzcGVj
aWZ5IGFkZGl0aW9uYWwgcmVsYXRpb25zaGlwcyBiZXR3ZWVuIHNwYW5zCiBpbiBhZGRpdGlv
biB0byBhIHBhcmVudC9jaGlsZCByZWxhdGlvbnNoaXAuCgoNCgUEAAQAARIEtgEHDwpyCgYE
AAQAAgASBLkBBB4aYiBVbnNwZWNpZmllZC4gRG8gTk9UIHVzZSBhcyBkZWZhdWx0LgogSW1w
bGVtZW50YXRpb25zIE1BWSBhc3N1bWUgU3BhbktpbmQuSU5URVJOQUwgdG8gYmUgZGVmYXVs
dC4KCg8KBwQABAACAAESBLkBBBkKDwoHBAAEAAIAAhIEuQEcHQpMCgYEAAQAAgESBLwBBBEa
PCBJbmRpY2F0ZXMgdGhhdCB0aGUgc3BhbiBpcyB1c2VkIGludGVybmFsbHkuIERlZmF1bHQg
dmFsdWUuCgoPCgcEAAQAAgEBEgS8AQQMCg8KBwQABAACAQISBLwBDxAKcQoGBAAEAAICEgTA
AQQPGmEgSW5kaWNhdGVzIHRoYXQgdGhlIHNwYW4gY292ZXJzIHNlcnZlci1zaWRlIGhhbmRs
aW5nIG9mIGFuIFJQQyBvciBvdGhlcgogcmVtb3RlIG5ldHdvcmsgcmVxdWVzdC4KCg8KBwQA
BAACAgESBMABBAoKDwoHBAAEAAICAhIEwAENDgpwCgYEAAQAAgMSBMQBBA8aYCBJbmRpY2F0
ZXMgdGhhdCB0aGUgc3BhbiBjb3ZlcnMgdGhlIGNsaWVudC1zaWRlIHdyYXBwZXIgYXJvdW5k
IGFuIFJQQyBvcgogb3RoZXIgcmVtb3RlIHJlcXVlc3QuCgoPCgcEAAQAAgMBEgTEAQQKCg8K
BwQABAACAwISBMQBDQ4KhQIKBgQABAACBBIEygEEERr0ASBJbmRpY2F0ZXMgdGhhdCB0aGUg
c3BhbiBkZXNjcmliZXMgcHJvZHVjZXIgc2VuZGluZyBhIG1lc3NhZ2UgdG8gYSBicm9rZXIu
CiBVbmxpa2UgY2xpZW50IGFuZCAgc2VydmVyLCB0aGVyZSBpcyBubyBkaXJlY3QgY3JpdGlj
YWwgcGF0aCBsYXRlbmN5CiByZWxhdGlvbnNoaXAgYmV0d2VlbiBwcm9kdWNlciBhbmQgY29u
c3VtZXIgc3BhbnMgKGUuZy4gcHVibGlzaGluZyBhCiBtZXNzYWdlIHRvIGEgcHVic3ViIHNl
cnZpY2UpLgoKDwoHBAAEAAIEARIEygEEDAoPCgcEAAQAAgQCEgTKAQ8QCpcCCgYEAAQAAgUS
BNABBBEahgIgSW5kaWNhdGVzIHRoYXQgdGhlIHNwYW4gZGVzY3JpYmVzIGNvbnN1bWVyIHJl
Y2VpdmluZyBhIG1lc3NhZ2UgZnJvbSBhCiBicm9rZXIuIFVubGlrZSBjbGllbnQgYW5kICBz
ZXJ2ZXIsIHRoZXJlIGlzIG5vIGRpcmVjdCBjcml0aWNhbCBwYXRoCiBsYXRlbmN5IHJlbGF0
aW9uc2hpcCBiZXR3ZWVuIHByb2R1Y2VyIGFuZCBjb25zdW1lciBzcGFucyAoZS5nLiByZWNl
aXZpbmcKIGEgbWVzc2FnZSBmcm9tIGEgcHVic3ViIHNlcnZpY2Ugc3Vic2NyaXB0aW9uKS4K
Cg8KBwQABAACBQESBNABBAwKDwoHBAAEAAIFAhIE0AEPEArFAwoEBAACABIE3wECOxq2AyBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHNwYW4gaW4gdGhlIGZvbGxvd2lu
ZyBmb3JtYXQ6CgogICogYHByb2plY3RzL1tQUk9KRUNUX0lEXS90cmFjZXMvW1RSQUNFX0lE
XS9zcGFucy9bU1BBTl9JRF1gCgogYFtUUkFDRV9JRF1gIGlzIGEgdW5pcXVlIGlkZW50aWZp
ZXIgZm9yIGEgdHJhY2Ugd2l0aGluIGEgcHJvamVjdDsKIGl0IGlzIGEgMzItY2hhcmFjdGVy
IGhleGFkZWNpbWFsIGVuY29kaW5nIG9mIGEgMTYtYnl0ZSBhcnJheS4gSXQgc2hvdWxkCiBu
b3QgYmUgemVyby4KCiBgW1NQQU5fSURdYCBpcyBhIHVuaXF1ZSBpZGVudGlmaWVyIGZvciBh
IHNwYW4gd2l0aGluIGEgdHJhY2U7IGl0CiBpcyBhIDE2LWNoYXJhY3RlciBoZXhhZGVjaW1h
bCBlbmNvZGluZyBvZiBhbiA4LWJ5dGUgYXJyYXkuIEl0IHNob3VsZCBub3QKIGJlIHplcm8u
CiAuCgoNCgUEAAIABRIE3wECCAoNCgUEAAIAARIE3wEJDQoNCgUEAAIAAxIE3wEQEQoNCgUE
AAIACBIE3wESOgoQCggEAAIACJwIABIE3wETOQpOCgQEAAIBEgTiAQI+GkAgUmVxdWlyZWQu
IFRoZSBgW1NQQU5fSURdYCBwb3J0aW9uIG9mIHRoZSBzcGFuJ3MgcmVzb3VyY2UgbmFtZS4K
Cg0KBQQAAgEFEgTiAQIICg0KBQQAAgEBEgTiAQkQCg0KBQQAAgEDEgTiARMUCg0KBQQAAgEI
EgTiARU9ChAKCAQAAgEInAgAEgTiARY8CnMKBAQAAgISBOYBAhwaZSBUaGUgYFtTUEFOX0lE
XWAgb2YgdGhpcyBzcGFuJ3MgcGFyZW50IHNwYW4uIElmIHRoaXMgaXMgYSByb290IHNwYW4s
CiB0aGVuIHRoaXMgZmllbGQgbXVzdCBiZSBlbXB0eS4KCg0KBQQAAgIFEgTmAQIICg0KBQQA
AgIBEgTmAQkXCg0KBQQAAgIDEgTmARobCrADCgQEAAIDEgTvAQJOGqEDIFJlcXVpcmVkLiBB
IGRlc2NyaXB0aW9uIG9mIHRoZSBzcGFuJ3Mgb3BlcmF0aW9uICh1cCB0byAxMjggYnl0ZXMp
LgogQ2xvdWQgVHJhY2UgZGlzcGxheXMgdGhlIGRlc2NyaXB0aW9uIGluIHRoZQogQ2xvdWQg
Y29uc29sZS4KIEZvciBleGFtcGxlLCB0aGUgZGlzcGxheSBuYW1lIGNhbiBiZSBhIHF1YWxp
ZmllZCBtZXRob2QgbmFtZSBvciBhIGZpbGUgbmFtZQogYW5kIGEgbGluZSBudW1iZXIgd2hl
cmUgdGhlIG9wZXJhdGlvbiBpcyBjYWxsZWQuIEEgYmVzdCBwcmFjdGljZSBpcyB0byB1c2UK
IHRoZSBzYW1lIGRpc3BsYXkgbmFtZSB3aXRoaW4gYW4gYXBwbGljYXRpb24gYW5kIGF0IHRo
ZSBzYW1lIGNhbGwgcG9pbnQuCiBUaGlzIG1ha2VzIGl0IGVhc2llciB0byBjb3JyZWxhdGUg
c3BhbnMgaW4gZGlmZmVyZW50IHRyYWNlcy4KCg0KBQQAAgMGEgTvAQITCg0KBQQAAgMBEgTv
ARQgCg0KBQQAAgMDEgTvASMkCg0KBQQAAgMIEgTvASVNChAKCAQAAgMInAgAEgTvASZMCvYB
CgQEAAIEEgb1AQL2AS8a5QEgUmVxdWlyZWQuIFRoZSBzdGFydCB0aW1lIG9mIHRoZSBzcGFu
LiBPbiB0aGUgY2xpZW50IHNpZGUsIHRoaXMgaXMgdGhlIHRpbWUKIGtlcHQgYnkgdGhlIGxv
Y2FsIG1hY2hpbmUgd2hlcmUgdGhlIHNwYW4gZXhlY3V0aW9uIHN0YXJ0cy4gT24gdGhlIHNl
cnZlcgogc2lkZSwgdGhpcyBpcyB0aGUgdGltZSB3aGVuIHRoZSBzZXJ2ZXIncyBhcHBsaWNh
dGlvbiBoYW5kbGVyIHN0YXJ0cwogcnVubmluZy4KCg0KBQQAAgQGEgT1AQIbCg0KBQQAAgQB
EgT1ARwmCg0KBQQAAgQDEgT1ASkqCg0KBQQAAgQIEgT2AQYuChAKCAQAAgQInAgAEgT2AQct
Cu4BCgQEAAIFEgb7AQL8AS8a3QEgUmVxdWlyZWQuIFRoZSBlbmQgdGltZSBvZiB0aGUgc3Bh
bi4gT24gdGhlIGNsaWVudCBzaWRlLCB0aGlzIGlzIHRoZSB0aW1lCiBrZXB0IGJ5IHRoZSBs
b2NhbCBtYWNoaW5lIHdoZXJlIHRoZSBzcGFuIGV4ZWN1dGlvbiBlbmRzLiBPbiB0aGUgc2Vy
dmVyCiBzaWRlLCB0aGlzIGlzIHRoZSB0aW1lIHdoZW4gdGhlIHNlcnZlciBhcHBsaWNhdGlv
biBoYW5kbGVyIHN0b3BzIHJ1bm5pbmcuCgoNCgUEAAIFBhIE+wECGwoNCgUEAAIFARIE+wEc
JAoNCgUEAAIFAxIE+wEnKAoNCgUEAAIFCBIE/AEGLgoQCggEAAIFCJwIABIE/AEHLQpcCgQE
AAIGEgSAAgIcGk4gQSBzZXQgb2YgYXR0cmlidXRlcyBvbiB0aGUgc3Bhbi4gWW91IGNhbiBo
YXZlIHVwIHRvIDMyIGF0dHJpYnV0ZXMgcGVyCiBzcGFuLgoKDQoFBAACBgYSBIACAgwKDQoF
BAACBgESBIACDRcKDQoFBAACBgMSBIACGhsKPgoEBAACBxIEgwICHRowIFN0YWNrIHRyYWNl
IGNhcHR1cmVkIGF0IHRoZSBzdGFydCBvZiB0aGUgc3Bhbi4KCg0KBQQAAgcGEgSDAgIMCg0K
BQQAAgcBEgSDAg0YCg0KBQQAAgcDEgSDAhscCmkKBAQAAggSBIcCAh0aWyBBIHNldCBvZiB0
aW1lIGV2ZW50cy4gWW91IGNhbiBoYXZlIHVwIHRvIDMyIGFubm90YXRpb25zIGFuZCAxMjgg
bWVzc2FnZQogZXZlbnRzIHBlciBzcGFuLgoKDQoFBAACCAYSBIcCAgwKDQoFBAACCAESBIcC
DRgKDQoFBAACCAMSBIcCGxwKVgoEBAACCRIEigICExpIIExpbmtzIGFzc29jaWF0ZWQgd2l0
aCB0aGUgc3Bhbi4gWW91IGNhbiBoYXZlIHVwIHRvIDEyOCBsaW5rcyBwZXIgU3Bhbi4KCg0K
BQQAAgkGEgSKAgIHCg0KBQQAAgkBEgSKAggNCg0KBQQAAgkDEgSKAhASCjkKBAQAAgoSBI0C
AkkaKyBPcHRpb25hbC4gVGhlIGZpbmFsIHN0YXR1cyBmb3IgdGhpcyBzcGFuLgoKDQoFBAAC
CgYSBI0CAhMKDQoFBAACCgESBI0CFBoKDQoFBAACCgMSBI0CHR8KDQoFBAACCggSBI0CIEgK
EAoIBAACCgicCAASBI0CIUcK1gEKBAQAAgsSBpICApMCLxrFASBPcHRpb25hbC4gU2V0IHRo
aXMgcGFyYW1ldGVyIHRvIGluZGljYXRlIHdoZXRoZXIgdGhpcyBzcGFuIGlzIGluCiB0aGUg
c2FtZSBwcm9jZXNzIGFzIGl0cyBwYXJlbnQuIElmIHlvdSBkbyBub3Qgc2V0IHRoaXMgcGFy
YW1ldGVyLAogVHJhY2UgaXMgdW5hYmxlIHRvIHRha2UgYWR2YW50YWdlIG9mIHRoaXMgaGVs
cGZ1bCBpbmZvcm1hdGlvbi4KCg0KBQQAAgsGEgSSAgIbCg0KBQQAAgsBEgSSAhw3Cg0KBQQA
AgsDEgSSAjo8Cg0KBQQAAgsIEgSTAgYuChAKCAQAAgsInAgAEgSTAgctCqQBCgQEAAIMEgaX
AgKYAi8akwEgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgY2hpbGQgc3BhbnMgdGhhdCB3ZXJl
IGdlbmVyYXRlZCB3aGlsZSB0aGlzIHNwYW4KIHdhcyBhY3RpdmUuIElmIHNldCwgYWxsb3dz
IGltcGxlbWVudGF0aW9uIHRvIGRldGVjdCBtaXNzaW5nIGNoaWxkIHNwYW5zLgoKDQoFBAAC
DAYSBJcCAhwKDQoFBAACDAESBJcCHS0KDQoFBAACDAMSBJcCMDIKDQoFBAACDAgSBJgCBi4K
EAoIBAACDAicCAASBJgCBy0K4QEKBAQAAg0SBJ0CAkMa0gEgT3B0aW9uYWwuIERpc3Rpbmd1
aXNoZXMgYmV0d2VlbiBzcGFucyBnZW5lcmF0ZWQgaW4gYSBwYXJ0aWN1bGFyIGNvbnRleHQu
CiBGb3IgZXhhbXBsZSwgdHdvIHNwYW5zIHdpdGggdGhlIHNhbWUgbmFtZSBtYXkgYmUgZGlz
dGluZ3Vpc2hlZCB1c2luZwogYENMSUVOVGAgKGNhbGxlcikgYW5kIGBTRVJWRVJgIChjYWxs
ZWUpIHRvIGlkZW50aWZ5IGFuIFJQQyBjYWxsLgoKDQoFBAACDQYSBJ0CAgoKDQoFBAACDQES
BJ0CCxQKDQoFBAACDQMSBJ0CFxkKDQoFBAACDQgSBJ0CGkIKEAoIBAACDQicCAASBJ0CG0EK
TwoCBAESBqECAK0CARpBIFRoZSBhbGxvd2VkIHR5cGVzIGZvciBgW1ZBTFVFXWAgaW4gYSBg
W0tFWV06W1ZBTFVFXWAgYXR0cmlidXRlLgoKCwoDBAEBEgShAggWCigKBAQBCAASBqMCAqwC
AxoYIFRoZSB0eXBlIG9mIHRoZSB2YWx1ZS4KCg0KBQQBCAABEgSjAggNCi4KBAQBAgASBKUC
BCcaICBBIHN0cmluZyB1cCB0byAyNTYgYnl0ZXMgbG9uZy4KCg0KBQQBAgAGEgSlAgQVCg0K
BQQBAgABEgSlAhYiCg0KBQQBAgADEgSlAiUmCigKBAQBAgESBKgCBBgaGiBBIDY0LWJpdCBz
aWduZWQgaW50ZWdlci4KCg0KBQQBAgEFEgSoAgQJCg0KBQQBAgEBEgSoAgoTCg0KBQQBAgED
EgSoAhYXCkEKBAQBAgISBKsCBBgaMyBBIEJvb2xlYW4gdmFsdWUgcmVwcmVzZW50ZWQgYnkg
YHRydWVgIG9yIGBmYWxzZWAuCgoNCgUEAQICBRIEqwIECAoNCgUEAQICARIEqwIJEwoNCgUE
AQICAxIEqwIWFwoyCgIEAhIGsAIA5wIBGiQgQSBjYWxsIHN0YWNrIGFwcGVhcmluZyBpbiBh
IHRyYWNlLgoKCwoDBAIBEgSwAggSCkMKBAQCAwASBrICAs0CAxozIFJlcHJlc2VudHMgYSBz
aW5nbGUgc3RhY2sgZnJhbWUgaW4gYSBzdGFjayB0cmFjZS4KCg0KBQQCAwABEgSyAgoUCowB
CgYEAgMAAgASBLUCBCgafCBUaGUgZnVsbHktcXVhbGlmaWVkIG5hbWUgdGhhdCB1bmlxdWVs
eSBpZGVudGlmaWVzIHRoZSBmdW5jdGlvbiBvcgogbWV0aG9kIHRoYXQgaXMgYWN0aXZlIGlu
IHRoaXMgZnJhbWUgKHVwIHRvIDEwMjQgYnl0ZXMpLgoKDwoHBAIDAAIABhIEtQIEFQoPCgcE
AgMAAgABEgS1AhYjCg8KBwQCAwACAAMSBLUCJicK8wEKBgQCAwACARIEuwIEMRriASBBbiB1
bi1tYW5nbGVkIGZ1bmN0aW9uIG5hbWUsIGlmIGBmdW5jdGlvbl9uYW1lYCBpcyBtYW5nbGVk
LgogVG8gZ2V0IGluZm9ybWF0aW9uIGFib3V0IG5hbWUgbWFuZ2xpbmcsIHJ1bgogW3RoaXMg
c2VhcmNoXShodHRwczovL3d3dy5nb29nbGUuY29tL3NlYXJjaD9xPWN4eCtuYW1lK21hbmds
aW5nKS4KIFRoZSBuYW1lIGNhbiBiZSBmdWxseS1xdWFsaWZpZWQgKHVwIHRvIDEwMjQgYnl0
ZXMpLgoKDwoHBAIDAAIBBhIEuwIEFQoPCgcEAgMAAgEBEgS7AhYsCg8KBwQCAwACAQMSBLsC
LzAKYQoGBAIDAAICEgS/AgQkGlEgVGhlIG5hbWUgb2YgdGhlIHNvdXJjZSBmaWxlIHdoZXJl
IHRoZSBmdW5jdGlvbiBjYWxsIGFwcGVhcnMgKHVwIHRvIDI1NgogYnl0ZXMpLgoKDwoHBAID
AAICBhIEvwIEFQoPCgcEAgMAAgIBEgS/AhYfCg8KBwQCAwACAgMSBL8CIiMKUQoGBAIDAAID
EgTCAgQaGkEgVGhlIGxpbmUgbnVtYmVyIGluIGBmaWxlX25hbWVgIHdoZXJlIHRoZSBmdW5j
dGlvbiBjYWxsIGFwcGVhcnMuCgoPCgcEAgMAAgMFEgTCAgQJCg8KBwQCAwACAwESBMICChUK
DwoHBAIDAAIDAxIEwgIYGQqYAQoGBAIDAAIEEgTGAgQcGocBIFRoZSBjb2x1bW4gbnVtYmVy
IHdoZXJlIHRoZSBmdW5jdGlvbiBjYWxsIGFwcGVhcnMsIGlmIGF2YWlsYWJsZS4KIFRoaXMg
aXMgaW1wb3J0YW50IGluIEphdmFTY3JpcHQgYmVjYXVzZSBvZiBpdHMgYW5vbnltb3VzIGZ1
bmN0aW9ucy4KCg8KBwQCAwACBAUSBMYCBAkKDwoHBAIDAAIEARIExgIKFwoPCgcEAgMAAgQD
EgTGAhobCkMKBgQCAwACBRIEyQIEGxozIFRoZSBiaW5hcnkgbW9kdWxlIGZyb20gd2hlcmUg
dGhlIGNvZGUgd2FzIGxvYWRlZC4KCg8KBwQCAwACBQYSBMkCBAoKDwoHBAIDAAIFARIEyQIL
FgoPCgcEAgMAAgUDEgTJAhkaCkwKBgQCAwACBhIEzAIEKRo8IFRoZSB2ZXJzaW9uIG9mIHRo
ZSBkZXBsb3llZCBzb3VyY2UgY29kZSAodXAgdG8gMTI4IGJ5dGVzKS4KCg8KBwQCAwACBgYS
BMwCBBUKDwoHBAIDAAIGARIEzAIWJAoPCgcEAgMAAgYDEgTMAicoCkcKBAQCAwESBtACAtgC
Axo3IEEgY29sbGVjdGlvbiBvZiBzdGFjayBmcmFtZXMsIHdoaWNoIGNhbiBiZSB0cnVuY2F0
ZWQuCgoNCgUEAgMBARIE0AIKFQoyCgYEAgMBAgASBNICBCIaIiBTdGFjayBmcmFtZXMgaW4g
dGhpcyBjYWxsIHN0YWNrLgoKDwoHBAIDAQIABBIE0gIEDAoPCgcEAgMBAgAGEgTSAg0XCg8K
BwQCAwECAAESBNICGB0KDwoHBAIDAQIAAxIE0gIgIQqiAQoGBAIDAQIBEgTXAgQjGpEBIFRo
ZSBudW1iZXIgb2Ygc3RhY2sgZnJhbWVzIHRoYXQgd2VyZSBkcm9wcGVkIGJlY2F1c2UgdGhl
cmUKIHdlcmUgdG9vIG1hbnkgc3RhY2sgZnJhbWVzLgogSWYgdGhpcyB2YWx1ZSBpcyAwLCB0
aGVuIG5vIHN0YWNrIGZyYW1lcyB3ZXJlIGRyb3BwZWQuCgoPCgcEAgMBAgEFEgTXAgQJCg8K
BwQCAwECAQESBNcCCh4KDwoHBAIDAQIBAxIE1wIhIgpWCgQEAgIAEgTbAgIfGkggU3RhY2sg
ZnJhbWVzIGluIHRoaXMgc3RhY2sgdHJhY2UuIEEgbWF4aW11bSBvZiAxMjggZnJhbWVzIGFy
ZSBhbGxvd2VkLgoKDQoFBAICAAYSBNsCAg0KDQoFBAICAAESBNsCDhoKDQoFBAICAAMSBNsC
HR4KlAMKBAQCAgESBOYCAiAahQMgVGhlIGhhc2ggSUQgaXMgdXNlZCB0byBjb25zZXJ2ZSBu
ZXR3b3JrIGJhbmR3aWR0aCBmb3IgZHVwbGljYXRlCiBzdGFjayB0cmFjZXMgd2l0aGluIGEg
c2luZ2xlIHRyYWNlLgoKIE9mdGVuIG11bHRpcGxlIHNwYW5zIHdpbGwgaGF2ZSBpZGVudGlj
YWwgc3RhY2sgdHJhY2VzLgogVGhlIGZpcnN0IG9jY3VycmVuY2Ugb2YgYSBzdGFjayB0cmFj
ZSBzaG91bGQgY29udGFpbiBib3RoIHRoZQogYHN0YWNrRnJhbWVgIGNvbnRlbnQgYW5kIGEg
dmFsdWUgaW4gYHN0YWNrVHJhY2VIYXNoSWRgLgoKIFN1YnNlcXVlbnQgc3BhbnMgd2l0aGlu
IHRoZSBzYW1lIHJlcXVlc3QgY2FuIHJlZmVyCiB0byB0aGF0IHN0YWNrIHRyYWNlIGJ5IG9u
bHkgc2V0dGluZyBgc3RhY2tUcmFjZUhhc2hJZGAuCgoNCgUEAgIBBRIE5gICBwoNCgUEAgIB
ARIE5gIIGwoNCgUEAgIBAxIE5gIeHwoeCgIEAxIG6gIA8gIBGhAgQmluYXJ5IG1vZHVsZS4K
CgsKAwQDARIE6gIIDgqBAQoEBAMCABIE7QICHxpzIEZvciBleGFtcGxlOiBtYWluIGJpbmFy
eSwga2VybmVsIG1vZHVsZXMsIGFuZCBkeW5hbWljIGxpYnJhcmllcwogc3VjaCBhcyBsaWJj
LnNvLCBzaGFyZWRsaWIuc28gKHVwIHRvIDI1NiBieXRlcykuCgoNCgUEAwIABhIE7QICEwoN
CgUEAwIAARIE7QIUGgoNCgUEAwIAAxIE7QIdHgpmCgQEAwIBEgTxAgIhGlggQSB1bmlxdWUg
aWRlbnRpZmllciBmb3IgdGhlIG1vZHVsZSwgdXN1YWxseSBhIGhhc2ggb2YgaXRzCiBjb250
ZW50cyAodXAgdG8gMTI4IGJ5dGVzKS4KCg0KBQQDAgEGEgTxAgITCg0KBQQDAgEBEgTxAhQc
Cg0KBQQDAgEDEgTxAh8gClIKAgQEEgb1AgCCAwEaRCBSZXByZXNlbnRzIGEgc3RyaW5nIHRo
YXQgbWlnaHQgYmUgc2hvcnRlbmVkIHRvIGEgc3BlY2lmaWVkIGxlbmd0aC4KCgsKAwQEARIE
9QIIGQqDAwoEBAQCABIE/QICExr0AiBUaGUgc2hvcnRlbmVkIHN0cmluZy4gRm9yIGV4YW1w
bGUsIGlmIHRoZSBvcmlnaW5hbCBzdHJpbmcgaXMgNTAwCiBieXRlcyBsb25nIGFuZCB0aGUg
bGltaXQgb2YgdGhlIHN0cmluZyBpcyAxMjggYnl0ZXMsIHRoZW4KIGB2YWx1ZWAgY29udGFp
bnMgdGhlIGZpcnN0IDEyOCBieXRlcyBvZiB0aGUgNTAwLWJ5dGUgc3RyaW5nLgoKIFRydW5j
YXRpb24gYWx3YXlzIGhhcHBlbnMgb24gYSBVVEY4IGNoYXJhY3RlciBib3VuZGFyeS4gSWYg
dGhlcmUKIGFyZSBtdWx0aS1ieXRlIGNoYXJhY3RlcnMgaW4gdGhlIHN0cmluZywgdGhlbiB0
aGUgbGVuZ3RoIG9mIHRoZQogc2hvcnRlbmVkIHN0cmluZyBtaWdodCBiZSBsZXNzIHRoYW4g
dGhlIHNpemUgbGltaXQuCgoNCgUEBAIABRIE/QICCAoNCgUEBAIAARIE/QIJDgoNCgUEBAIA
AxIE/QIREgp9CgQEBAIBEgSBAwIhGm8gVGhlIG51bWJlciBvZiBieXRlcyByZW1vdmVkIGZy
b20gdGhlIG9yaWdpbmFsIHN0cmluZy4gSWYgdGhpcwogdmFsdWUgaXMgMCwgdGhlbiB0aGUg
c3RyaW5nIHdhcyBub3Qgc2hvcnRlbmVkLgoKDQoFBAQCAQUSBIEDAgcKDQoFBAQCAQESBIED
CBwKDQoFBAQCAQMSBIEDHyBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Cloudtrace::V2::Trace::Span ===
    # Fields for Span
    # Field: name Type: 9 ()
    # Field: span_id Type: 9 ()
    # Field: parent_span_id Type: 9 ()
    # Field: display_name Type: 11 (.google.devtools.cloudtrace.v2.TruncatableString)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attributes Type: 11 (.google.devtools.cloudtrace.v2.Span.Attributes)
    # Field: stack_trace Type: 11 (.google.devtools.cloudtrace.v2.StackTrace)
    # Field: time_events Type: 11 (.google.devtools.cloudtrace.v2.Span.TimeEvents)
    # Field: links Type: 11 (.google.devtools.cloudtrace.v2.Span.Links)
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: same_process_as_parent_span Type: 11 (.google.protobuf.BoolValue)
    # Field: child_span_count Type: 11 (.google.protobuf.Int32Value)
    # Field: span_kind Type: 14 (.google.devtools.cloudtrace.v2.Span.SpanKind)

# Enum: Span::SpanKind
our $Span_SPAN_KIND_UNSPECIFIED = 0;
our $Span_INTERNAL = 1;
our $Span_SERVER = 2;
our $Span_CLIENT = 3;
our $Span_PRODUCER = 4;
our $Span_CONSUMER = 5;

# === Message: Google::Devtools::Cloudtrace::V2::Trace::AttributeValue ===
    # Fields for AttributeValue
    # Field: string_value Type: 11 (.google.devtools.cloudtrace.v2.TruncatableString)
    # Field: int_value Type: 3 ()
    # Field: bool_value Type: 8 ()

# === Message: Google::Devtools::Cloudtrace::V2::Trace::StackTrace ===
    # Fields for StackTrace
    # Field: stack_frames Type: 11 (.google.devtools.cloudtrace.v2.StackTrace.StackFrames)
    # Field: stack_trace_hash_id Type: 3 ()

# === Message: Google::Devtools::Cloudtrace::V2::Trace::Module ===
    # Fields for Module
    # Field: module Type: 11 (.google.devtools.cloudtrace.v2.TruncatableString)
    # Field: build_id Type: 11 (.google.devtools.cloudtrace.v2.TruncatableString)

# === Message: Google::Devtools::Cloudtrace::V2::Trace::TruncatableString ===
    # Fields for TruncatableString
    # Field: value Type: 9 ()
    # Field: truncated_byte_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Cloudtrace::V2::Trace - Compiled Protocol Buffers messages for google/devtools/cloudtrace/v2/trace.proto

=head1 SYNOPSIS

    use Google::Devtools::Cloudtrace::V2::Trace;

    my $msg = Google::Devtools::Cloudtrace::V2::Trace::Span->new({
        name => $name,
        span_id => $span_id,
        parent_span_id => $parent_span_id,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Cloudtrace::V2::Trace::Span->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/cloudtrace/v2/trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Cloudtrace::V2::Trace::Span

A span represents a single operation within a trace. Spans can be
nested to form a trace tree. Often, a trace contains a root span
that describes the end-to-end latency, and one or more subspans for
its sub-operations.

A trace can also contain multiple root spans, or none at all.
Spans do not need to be contiguous. There might be
gaps or overlaps between spans in a trace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the span in the following format:

 * `projects/[PROJECT_ID]/traces/[TRACE_ID]/spans/[SPAN_ID]`

`[TRACE_ID]` is a unique identifier for a trace within a project;
it is a 32-character hexadecimal encoding of a 16-byte array. It should
not be zero.

`[SPAN_ID]` is a unique identifier for a span within a trace; it
is a 16-character hexadecimal encoding of an 8-byte array. It should not
be zero.
.

=item * C<< $msg->span_id() >> / C<< $msg->span_id($value) >>

Type: C<String>

Required. The `[SPAN_ID]` portion of the span's resource name.

=item * C<< $msg->parent_span_id() >> / C<< $msg->parent_span_id($value) >>

Type: C<String>

The `[SPAN_ID]` of this span's parent span. If this is a root span,
then this field must be empty.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::TruncatableString>)

Required. A description of the span's operation (up to 128 bytes).
Cloud Trace displays the description in the
Cloud console.
For example, the display name can be a qualified method name or a file name
and a line number where the operation is called. A best practice is to use
the same display name within an application and at the same call point.
This makes it easier to correlate spans in different traces.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The start time of the span. On the client side, this is the time
kept by the local machine where the span execution starts. On the server
side, this is the time when the server's application handler starts
running.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The end time of the span. On the client side, this is the time
kept by the local machine where the span execution ends. On the server
side, this is the time when the server application handler stops running.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes>)

A set of attributes on the span. You can have up to 32 attributes per
span.

=item * C<< $msg->stack_trace() >> / C<< $msg->stack_trace($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::StackTrace>)

Stack trace captured at the start of the span.

=item * C<< $msg->time_events() >> / C<< $msg->time_events($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvents>)

A set of time events. You can have up to 32 annotations and 128 message
events per span.

=item * C<< $msg->links() >> / C<< $msg->links($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::Span::Links>)

Links associated with the span. You can have up to 128 links per Span.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Optional. The final status for this span.

=item * C<< $msg->same_process_as_parent_span() >> / C<< $msg->same_process_as_parent_span($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Optional. Set this parameter to indicate whether this span is in
the same process as its parent. If you do not set this parameter,
Trace is unable to take advantage of this helpful information.

=item * C<< $msg->child_span_count() >> / C<< $msg->child_span_count($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

Optional. The number of child spans that were generated while this span
was active. If set, allows implementation to detect missing child spans.

=item * C<< $msg->span_kind() >> / C<< $msg->span_kind($value) >>

Type: C<Enum> (L<Google::Devtools::Cloudtrace::V2::Span::SpanKind>)

Optional. Distinguishes between spans generated in a particular context.
For example, two spans with the same name may be distinguished using
`CLIENT` (caller) and `SERVER` (callee) to identify an RPC call.

=back

=head3 Enum: Span::SpanKind

=over 4

=item * C<SPAN_KIND_UNSPECIFIED> => C<0>

=item * C<INTERNAL> => C<1>

=item * C<SERVER> => C<2>

=item * C<CLIENT> => C<3>

=item * C<PRODUCER> => C<4>

=item * C<CONSUMER> => C<5>

=back

=head2 Google::Devtools::Cloudtrace::V2::Trace::AttributeValue

The allowed types for `[VALUE]` in a `[KEY]:[VALUE]` attribute.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::TruncatableString>)

A string up to 256 bytes long.

=item * C<< $msg->int_value() >> / C<< $msg->int_value($value) >>

Type: C<Int64>

A 64-bit signed integer.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

A Boolean value represented by `true` or `false`.

=back

=head2 Google::Devtools::Cloudtrace::V2::Trace::StackTrace

A call stack appearing in a trace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stack_frames() >> / C<< $msg->stack_frames($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrames>)

Stack frames in this stack trace. A maximum of 128 frames are allowed.

=item * C<< $msg->stack_trace_hash_id() >> / C<< $msg->stack_trace_hash_id($value) >>

Type: C<Int64>

The hash ID is used to conserve network bandwidth for duplicate
stack traces within a single trace.

Often multiple spans will have identical stack traces.
The first occurrence of a stack trace should contain both the
`stackFrame` content and a value in `stackTraceHashId`.

Subsequent spans within the same request can refer
to that stack trace by only setting `stackTraceHashId`.

=back

=head2 Google::Devtools::Cloudtrace::V2::Trace::Module

Binary module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->module() >> / C<< $msg->module($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::TruncatableString>)

For example: main binary, kernel modules, and dynamic libraries
such as libc.so, sharedlib.so (up to 256 bytes).

=item * C<< $msg->build_id() >> / C<< $msg->build_id($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::TruncatableString>)

A unique identifier for the module, usually a hash of its
contents (up to 128 bytes).

=back

=head2 Google::Devtools::Cloudtrace::V2::Trace::TruncatableString

Represents a string that might be shortened to a specified length.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The shortened string. For example, if the original string is 500
bytes long and the limit of the string is 128 bytes, then
`value` contains the first 128 bytes of the 500-byte string.

Truncation always happens on a UTF8 character boundary. If there
are multi-byte characters in the string, then the length of the
shortened string might be less than the size limit.

=item * C<< $msg->truncated_byte_count() >> / C<< $msg->truncated_byte_count($value) >>

Type: C<Int32>

The number of bytes removed from the original string. If this
value is 0, then the string was not shortened.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Cloudtrace::V2::Trace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
