package Google::Monitoring::Dashboard::V1::Metrics;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Monitoring::Dashboard::V1::Common };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvbWV0cmljcy5wcm90bxIeZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGitnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvY29tbW9uLnByb3RvIrcDCg9U
aW1lU2VyaWVzUXVlcnkSYAoSdGltZV9zZXJpZXNfZmlsdGVyGAEgASgLMjAuZ29vZ2xlLm1v
bml0b3JpbmcuZGFzaGJvYXJkLnYxLlRpbWVTZXJpZXNGaWx0ZXJIAFIQdGltZVNlcmllc0Zp
bHRlchJwChh0aW1lX3Nlcmllc19maWx0ZXJfcmF0aW8YAiABKAsyNS5nb29nbGUubW9uaXRv
cmluZy5kYXNoYm9hcmQudjEuVGltZVNlcmllc0ZpbHRlclJhdGlvSABSFXRpbWVTZXJpZXNG
aWx0ZXJSYXRpbxI9Chp0aW1lX3Nlcmllc19xdWVyeV9sYW5ndWFnZRgDIAEoCUgAUhd0aW1l
U2VyaWVzUXVlcnlMYW5ndWFnZRIrChBwcm9tZXRoZXVzX3F1ZXJ5GAYgASgJSABSD3Byb21l
dGhldXNRdWVyeRIjCg11bml0X292ZXJyaWRlGAUgASgJUgx1bml0T3ZlcnJpZGUSNQoUb3V0
cHV0X2Z1bGxfZHVyYXRpb24YByABKAhCA+BBAVISb3V0cHV0RnVsbER1cmF0aW9uQggKBnNv
dXJjZSLpAwoQVGltZVNlcmllc0ZpbHRlchIbCgZmaWx0ZXIYASABKAlCA+BBAlIGZmlsdGVy
Ek0KC2FnZ3JlZ2F0aW9uGAIgASgLMisuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYx
LkFnZ3JlZ2F0aW9uUgthZ2dyZWdhdGlvbhJgChVzZWNvbmRhcnlfYWdncmVnYXRpb24YAyAB
KAsyKy5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuQWdncmVnYXRpb25SFHNlY29u
ZGFyeUFnZ3JlZ2F0aW9uEm0KF3BpY2tfdGltZV9zZXJpZXNfZmlsdGVyGAQgASgLMjQuZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlBpY2tUaW1lU2VyaWVzRmlsdGVySABSFHBp
Y2tUaW1lU2VyaWVzRmlsdGVyEoYBCh5zdGF0aXN0aWNhbF90aW1lX3Nlcmllc19maWx0ZXIY
BSABKAsyOy5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuU3RhdGlzdGljYWxUaW1l
U2VyaWVzRmlsdGVyQgIYAUgAUhtzdGF0aXN0aWNhbFRpbWVTZXJpZXNGaWx0ZXJCDwoNb3V0
cHV0X2ZpbHRlciK9BQoVVGltZVNlcmllc0ZpbHRlclJhdGlvEl0KCW51bWVyYXRvchgBIAEo
CzI/Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5UaW1lU2VyaWVzRmlsdGVyUmF0
aW8uUmF0aW9QYXJ0UgludW1lcmF0b3ISYQoLZGVub21pbmF0b3IYAiABKAsyPy5nb29nbGUu
bW9uaXRvcmluZy5kYXNoYm9hcmQudjEuVGltZVNlcmllc0ZpbHRlclJhdGlvLlJhdGlvUGFy
dFILZGVub21pbmF0b3ISYAoVc2Vjb25kYXJ5X2FnZ3JlZ2F0aW9uGAMgASgLMisuZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkFnZ3JlZ2F0aW9uUhRzZWNvbmRhcnlBZ2dyZWdh
dGlvbhJtChdwaWNrX3RpbWVfc2VyaWVzX2ZpbHRlchgEIAEoCzI0Lmdvb2dsZS5tb25pdG9y
aW5nLmRhc2hib2FyZC52MS5QaWNrVGltZVNlcmllc0ZpbHRlckgAUhRwaWNrVGltZVNlcmll
c0ZpbHRlchKGAQoec3RhdGlzdGljYWxfdGltZV9zZXJpZXNfZmlsdGVyGAUgASgLMjsuZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlN0YXRpc3RpY2FsVGltZVNlcmllc0ZpbHRl
ckICGAFIAFIbc3RhdGlzdGljYWxUaW1lU2VyaWVzRmlsdGVyGncKCVJhdGlvUGFydBIbCgZm
aWx0ZXIYASABKAlCA+BBAlIGZmlsdGVyEk0KC2FnZ3JlZ2F0aW9uGAIgASgLMisuZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkFnZ3JlZ2F0aW9uUgthZ2dyZWdhdGlvbkIPCg1v
dXRwdXRfZmlsdGVyItYDCglUaHJlc2hvbGQSFAoFbGFiZWwYASABKAlSBWxhYmVsEhQKBXZh
bHVlGAIgASgBUgV2YWx1ZRJFCgVjb2xvchgDIAEoDjIvLmdvb2dsZS5tb25pdG9yaW5nLmRh
c2hib2FyZC52MS5UaHJlc2hvbGQuQ29sb3JSBWNvbG9yElEKCWRpcmVjdGlvbhgEIAEoDjIz
Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5UaHJlc2hvbGQuRGlyZWN0aW9uUglk
aXJlY3Rpb24SVQoLdGFyZ2V0X2F4aXMYBSABKA4yNC5nb29nbGUubW9uaXRvcmluZy5kYXNo
Ym9hcmQudjEuVGhyZXNob2xkLlRhcmdldEF4aXNSCnRhcmdldEF4aXMiMwoFQ29sb3ISFQoR
Q09MT1JfVU5TUEVDSUZJRUQQABIKCgZZRUxMT1cQBBIHCgNSRUQQBiI8CglEaXJlY3Rpb24S
GQoVRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASCQoFQUJPVkUQARIJCgVCRUxPVxACIjkKClRh
cmdldEF4aXMSGwoXVEFSR0VUX0FYSVNfVU5TUEVDSUZJRUQQABIGCgJZMRABEgYKAlkyEAIq
UQoOU3BhcmtDaGFydFR5cGUSIAocU1BBUktfQ0hBUlRfVFlQRV9VTlNQRUNJRklFRBAAEg4K
ClNQQVJLX0xJTkUQARINCglTUEFSS19CQVIQAkL1AQoiY29tLmdvb2dsZS5tb25pdG9yaW5n
LmRhc2hib2FyZC52MUIMTWV0cmljc1Byb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9u
aXRvcmluZy9kYXNoYm9hcmQvYXBpdjEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29n
bGUuQ2xvdWQuTW9uaXRvcmluZy5EYXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRv
cmluZ1xEYXNoYm9hcmRcVjHqAihHb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNoYm9h
cmQ6OlYxStA5CgcSBQ4AzgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
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
CAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMANQoICgEIEgMVAEEKCQoCCCUSAxUAQQoI
CgEIEgMWAF0KCQoCCAsSAxYAXQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC0KCQoC
CAgSAxgALQoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaAEIKCQoCCCkSAxoAQgoICgEI
EgMbAEEKCQoCCC0SAxsAQQqEAQoCBAASBB8APgEaeCBUaW1lU2VyaWVzUXVlcnkgY29sbGVj
dHMgdGhlIHNldCBvZiBzdXBwb3J0ZWQgbWV0aG9kcyBmb3IgcXVlcnlpbmcgdGltZQogc2Vy
aWVzIGRhdGEgZnJvbSB0aGUgU3RhY2tkcml2ZXIgbWV0cmljcyBBUEkuCgoKCgMEAAESAx8I
Fwo/CgQEAAgAEgQhAi0DGjEgUGFyYW1ldGVycyBuZWVkZWQgdG8gb2J0YWluIGRhdGEgZm9y
IHRoZSBjaGFydC4KCgwKBQQACAABEgMhCA4KNgoEBAACABIDIwQsGikgRmlsdGVyIHBhcmFt
ZXRlcnMgdG8gZmV0Y2ggdGltZSBzZXJpZXMuCgoMCgUEAAIABhIDIwQUCgwKBQQAAgABEgMj
FScKDAoFBAACAAMSAyMqKwpLCgQEAAIBEgMmBDcaPiBQYXJhbWV0ZXJzIHRvIGZldGNoIGEg
cmF0aW8gYmV0d2VlbiB0d28gdGltZSBzZXJpZXMgZmlsdGVycy4KCgwKBQQAAgEGEgMmBBkK
DAoFBAACAQESAyYaMgoMCgUEAAIBAxIDJjU2CjoKBAQAAgISAykEKhotIEEgcXVlcnkgdXNl
ZCB0byBmZXRjaCB0aW1lIHNlcmllcyB3aXRoIE1RTC4KCgwKBQQAAgIFEgMpBAoKDAoFBAAC
AgESAykLJQoMCgUEAAICAxIDKSgpCj0KBAQAAgMSAywEIBowIEEgcXVlcnkgdXNlZCB0byBm
ZXRjaCB0aW1lIHNlcmllcyB3aXRoIFByb21RTC4KCgwKBQQAAgMFEgMsBAoKDAoFBAACAwES
AywLGwoMCgUEAAIDAxIDLB4fCqsCCgQEAAIEEgM0AhsanQIgVGhlIHVuaXQgb2YgZGF0YSBj
b250YWluZWQgaW4gZmV0Y2hlZCB0aW1lIHNlcmllcy4gSWYgbm9uLWVtcHR5LCB0aGlzCiB1
bml0IHdpbGwgb3ZlcnJpZGUgYW55IHVuaXQgdGhhdCBhY2NvbXBhbmllcyBmZXRjaGVkIGRh
dGEuIFRoZSBmb3JtYXQgaXMKIHRoZSBzYW1lIGFzIHRoZQogW2B1bml0YF0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3JlZl92My9yZXN0L3YzL3Byb2plY3Rz
Lm1ldHJpY0Rlc2NyaXB0b3JzKQogZmllbGQgaW4gYE1ldHJpY0Rlc2NyaXB0b3JgLgoKDAoF
BAACBAUSAzQCCAoMCgUEAAIEARIDNAkWCgwKBQQAAgQDEgM0GRoKxwIKBAQAAgUSAz0CSRq5
AiBPcHRpb25hbC4gSWYgc2V0LCBDbG91ZCBNb25pdG9yaW5nIHdpbGwgdHJlYXQgdGhlIGZ1
bGwgcXVlcnkgZHVyYXRpb24gYXMKIHRoZSBhbGlnbm1lbnQgcGVyaW9kIHNvIHRoYXQgdGhl
cmUgd2lsbCBiZSBvbmx5IDEgb3V0cHV0IHZhbHVlLgoKICpOb3RlOiBUaGlzIGNvdWxkIG92
ZXJyaWRlIHRoZSBjb25maWd1cmVkIGFsaWdubWVudCBwZXJpb2QgZXhjZXB0IGZvcgogdGhl
IGNhc2VzIHdoZXJlIGEgc2VyaWVzIG9mIGRhdGEgcG9pbnRzIGFyZSBleHBlY3RlZCwgbGlr
ZQogICAtIFh5Q2hhcnQKICAgLSBTY29yZWNhcmQncyBzcGFyayBjaGFydAoKDAoFBAACBQUS
Az0CBgoMCgUEAAIFARIDPQcbCgwKBQQAAgUDEgM9Hh8KDAoFBAACBQgSAz0gSAoPCggEAAIF
CJwIABIDPSFHCvUBCgIEARIERABcARroASBBIGZpbHRlciB0aGF0IGRlZmluZXMgYSBzdWJz
ZXQgb2YgdGltZSBzZXJpZXMgZGF0YSB0aGF0IGlzIGRpc3BsYXllZCBpbiBhCiB3aWRnZXQu
IFRpbWUgc2VyaWVzIGRhdGEgaXMgZmV0Y2hlZCB1c2luZyB0aGUKIFtgTGlzdFRpbWVTZXJp
ZXNgXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9hcGkvcmVmX3YzL3Jl
c3QvdjMvcHJvamVjdHMudGltZVNlcmllcy9saXN0KQogbWV0aG9kLgoKCgoDBAEBEgNECBgK
qwEKBAQBAgASA0gCPRqdASBSZXF1aXJlZC4gVGhlIFttb25pdG9yaW5nCiBmaWx0ZXJdKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9tb25pdG9yaW5nL2FwaS92My9maWx0ZXJzKSB0aGF0
IGlkZW50aWZpZXMKIHRoZSBtZXRyaWMgdHlwZXMsIHJlc291cmNlcywgYW5kIHByb2plY3Rz
IHRvIHF1ZXJ5LgoKDAoFBAECAAUSA0gCCAoMCgUEAQIAARIDSAkPCgwKBQQBAgADEgNIEhMK
DAoFBAECAAgSA0gUPAoPCggEAQIACJwIABIDSBU7CpMBCgQEAQIBEgNNAh4ahQEgQnkgZGVm
YXVsdCwgdGhlIHJhdyB0aW1lIHNlcmllcyBkYXRhIGlzIHJldHVybmVkLgogVXNlIHRoaXMg
ZmllbGQgdG8gY29tYmluZSBtdWx0aXBsZSB0aW1lIHNlcmllcyBmb3IgZGlmZmVyZW50IHZp
ZXdzIG9mIHRoZQogZGF0YS4KCgwKBQQBAgEGEgNNAg0KDAoFBAECAQESA00OGQoMCgUEAQIB
AxIDTRwdCkkKBAQBAgISA1ACKBo8IEFwcGx5IGEgc2Vjb25kIGFnZ3JlZ2F0aW9uIGFmdGVy
IGBhZ2dyZWdhdGlvbmAgaXMgYXBwbGllZC4KCgwKBQQBAgIGEgNQAg0KDAoFBAECAgESA1AO
IwoMCgUEAQICAxIDUCYnCjcKBAQBCAASBFMCWwMaKSBTZWxlY3RzIGFuIG9wdGlvbmFsIHRp
bWUgc2VyaWVzIGZpbHRlci4KCgwKBQQBCAABEgNTCBUKMAoEBAECAxIDVQQ1GiMgUmFua2lu
ZyBiYXNlZCB0aW1lIHNlcmllcyBmaWx0ZXIuCgoMCgUEAQIDBhIDVQQYCgwKBQQBAgMBEgNV
GTAKDAoFBAECAwMSA1UzNAp3CgQEAQIEEgRZBFocGmkgU3RhdGlzdGljcyBiYXNlZCB0aW1l
IHNlcmllcyBmaWx0ZXIuCiBOb3RlOiBUaGlzIGZpZWxkIGlzIGRlcHJlY2F0ZWQgYW5kIGNv
bXBsZXRlbHkgaWdub3JlZCBieSB0aGUgQVBJLgoKDAoFBAECBAYSA1kEHwoMCgUEAQIEARID
WSA+CgwKBQQBAgQDEgNZQUIKDAoFBAECBAgSA1oIGwoNCgYEAQIECAMSA1oJGgrJAQoCBAIS
BWEAhAEBGrsBIEEgcGFpciBvZiB0aW1lIHNlcmllcyBmaWx0ZXJzIHRoYXQgZGVmaW5lIGEg
cmF0aW8gY29tcHV0YXRpb24uIFRoZSBvdXRwdXQKIHRpbWUgc2VyaWVzIGlzIHRoZSBwYWly
LXdpc2UgZGl2aXNpb24gb2YgZWFjaCBhbGlnbmVkIGVsZW1lbnQgZnJvbSB0aGUKIG51bWVy
YXRvciBhbmQgZGVub21pbmF0b3IgdGltZSBzZXJpZXMuCgoKCgMEAgESA2EIHQpkCgQEAgMA
EgRkAm4DGlYgRGVzY3JpYmVzIGEgcXVlcnkgdG8gYnVpbGQgdGhlIG51bWVyYXRvciBvciBk
ZW5vbWluYXRvciBvZiBhCiBUaW1lU2VyaWVzRmlsdGVyUmF0aW8uCgoMCgUEAgMAARIDZAoT
Cq0BCgYEAgMAAgASA2gEPxqdASBSZXF1aXJlZC4gVGhlIFttb25pdG9yaW5nCiBmaWx0ZXJd
KGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9tb25pdG9yaW5nL2FwaS92My9maWx0ZXJzKSB0
aGF0CiBpZGVudGlmaWVzIHRoZSBtZXRyaWMgdHlwZXMsIHJlc291cmNlcywgYW5kIHByb2pl
Y3RzIHRvIHF1ZXJ5LgoKDgoHBAIDAAIABRIDaAQKCg4KBwQCAwACAAESA2gLEQoOCgcEAgMA
AgADEgNoFBUKDgoHBAIDAAIACBIDaBY+ChEKCgQCAwACAAicCAASA2gXPQqVAQoGBAIDAAIB
EgNtBCAahQEgQnkgZGVmYXVsdCwgdGhlIHJhdyB0aW1lIHNlcmllcyBkYXRhIGlzIHJldHVy
bmVkLgogVXNlIHRoaXMgZmllbGQgdG8gY29tYmluZSBtdWx0aXBsZSB0aW1lIHNlcmllcyBm
b3IgZGlmZmVyZW50IHZpZXdzIG9mIHRoZQogZGF0YS4KCg4KBwQCAwACAQYSA20EDwoOCgcE
AgMAAgEBEgNtEBsKDgoHBAIDAAIBAxIDbR4fCioKBAQCAgASA3ECGhodIFRoZSBudW1lcmF0
b3Igb2YgdGhlIHJhdGlvLgoKDAoFBAICAAYSA3ECCwoMCgUEAgIAARIDcQwVCgwKBQQCAgAD
EgNxGBkKLAoEBAICARIDdAIcGh8gVGhlIGRlbm9taW5hdG9yIG9mIHRoZSByYXRpby4KCgwK
BQQCAgEGEgN0AgsKDAoFBAICAQESA3QMFwoMCgUEAgIBAxIDdBobCkYKBAQCAgISA3cCKBo5
IEFwcGx5IGEgc2Vjb25kIGFnZ3JlZ2F0aW9uIGFmdGVyIHRoZSByYXRpbyBpcyBjb21wdXRl
ZC4KCgwKBQQCAgIGEgN3Ag0KDAoFBAICAgESA3cOIwoMCgUEAgICAxIDdyYnCmoKBAQCCAAS
BXsCgwEDGlsgU2VsZWN0cyBhbiBvcHRpb25hbCBmaWx0ZXIgdGhhdCBpcyBhcHBsaWVkIHRv
IHRoZSB0aW1lIHNlcmllcyBhZnRlcgogY29tcHV0aW5nIHRoZSByYXRpby4KCgwKBQQCCAAB
EgN7CBUKMAoEBAICAxIDfQQ1GiMgUmFua2luZyBiYXNlZCB0aW1lIHNlcmllcyBmaWx0ZXIu
CgoMCgUEAgIDBhIDfQQYCgwKBQQCAgMBEgN9GTAKDAoFBAICAwMSA30zNAp5CgQEAgIEEgaB
AQSCARwaaSBTdGF0aXN0aWNzIGJhc2VkIHRpbWUgc2VyaWVzIGZpbHRlci4KIE5vdGU6IFRo
aXMgZmllbGQgaXMgZGVwcmVjYXRlZCBhbmQgY29tcGxldGVseSBpZ25vcmVkIGJ5IHRoZSBB
UEkuCgoNCgUEAgIEBhIEgQEEHwoNCgUEAgIEARIEgQEgPgoNCgUEAgIEAxIEgQFBQgoNCgUE
AgIECBIEggEIGwoOCgYEAgIECAMSBIIBCRoKSAoCBAMSBocBAMIBARo6IERlZmluZXMgYSB0
aHJlc2hvbGQgZm9yIGNhdGVnb3JpemluZyB0aW1lIHNlcmllcyB2YWx1ZXMuCgoLCgMEAwES
BIcBCBEK2QEKBAQDBAASBosBApQBAxrIASBUaGUgY29sb3Igc3VnZ2VzdHMgYW4gaW50ZXJw
cmV0YXRpb24gdG8gdGhlIHZpZXdlciB3aGVuIGFjdHVhbCB2YWx1ZXMgY3Jvc3MKIHRoZSB0
aHJlc2hvbGQuIENvbW1lbnRzIG9uIGVhY2ggY29sb3IgcHJvdmlkZSBVWCBndWlkYW5jZSBv
biBob3cgdXNlcnMgY2FuCiBiZSBleHBlY3RlZCB0byBpbnRlcnByZXQgYSBnaXZlbiBzdGF0
ZSBjb2xvci4KCg0KBQQDBAABEgSLAQcMCkwKBgQDBAACABIEjQEEGho8IENvbG9yIGlzIHVu
c3BlY2lmaWVkLiBOb3QgYWxsb3dlZCBpbiB3ZWxsLWZvcm1lZCByZXF1ZXN0cy4KCg8KBwQD
BAACAAESBI0BBBUKDwoHBAMEAAIAAhIEjQEYGQpCCgYEAwQAAgESBJABBA8aMiBDcm9zc2lu
ZyB0aGUgdGhyZXNob2xkIGlzICJjb25jZXJuaW5nIiBiZWhhdmlvci4KCg8KBwQDBAACAQES
BJABBAoKDwoHBAMEAAIBAhIEkAENDgpBCgYEAwQAAgISBJMBBAwaMSBDcm9zc2luZyB0aGUg
dGhyZXNob2xkIGlzICJlbWVyZ2VuY3kiIGJlaGF2aW9yLgoKDwoHBAMEAAICARIEkwEEBwoP
CgcEAwQAAgICEgSTAQoLCnUKBAQDBAESBpgBAqMBAxplIFdoZXRoZXIgdGhlIHRocmVzaG9s
ZCBpcyBjb25zaWRlcmVkIGNyb3NzZWQgYnkgYW4gYWN0dWFsIHZhbHVlIGFib3ZlIG9yCiBi
ZWxvdyBpdHMgdGhyZXNob2xkIHZhbHVlLgoKDQoFBAMEAQESBJgBBxAKNgoGBAMEAQIAEgSa
AQQeGiYgTm90IGFsbG93ZWQgaW4gd2VsbC1mb3JtZWQgcmVxdWVzdHMuCgoPCgcEAwQBAgAB
EgSaAQQZCg8KBwQDBAECAAISBJoBHB0KbQoGBAMEAQIBEgSeAQQOGl0gVGhlIHRocmVzaG9s
ZCB3aWxsIGJlIGNvbnNpZGVyZWQgY3Jvc3NlZCBpZiB0aGUgYWN0dWFsIHZhbHVlIGlzIGFi
b3ZlCiB0aGUgdGhyZXNob2xkIHZhbHVlLgoKDwoHBAMEAQIBARIEngEECQoPCgcEAwQBAgEC
EgSeAQwNCm0KBgQDBAECAhIEogEEDhpdIFRoZSB0aHJlc2hvbGQgd2lsbCBiZSBjb25zaWRl
cmVkIGNyb3NzZWQgaWYgdGhlIGFjdHVhbCB2YWx1ZSBpcyBiZWxvdwogdGhlIHRocmVzaG9s
ZCB2YWx1ZS4KCg8KBwQDBAECAgESBKIBBAkKDwoHBAMEAQICAhIEogEMDQolCgQEAwQCEgam
AQKvAQMaFSBBbiBheGlzIGlkZW50aWZpZXIuCgoNCgUEAwQCARIEpgEHEQpECgYEAwQCAgAS
BKgBBCAaNCBUaGUgdGFyZ2V0IGF4aXMgd2FzIG5vdCBzcGVjaWZpZWQuIERlZmF1bHRzIHRv
IFkxLgoKDwoHBAMEAgIAARIEqAEEGwoPCgcEAwQCAgACEgSoAR4fCjcKBgQDBAICARIEqwEE
CxonIFRoZSB5X2F4aXMgKHRoZSByaWdodCBheGlzIG9mIGNoYXJ0KS4KCg8KBwQDBAICAQES
BKsBBAYKDwoHBAMEAgIBAhIEqwEJCgo3CgYEAwQCAgISBK4BBAsaJyBUaGUgeTJfYXhpcyAo
dGhlIGxlZnQgYXhpcyBvZiBjaGFydCkuCgoPCgcEAwQCAgIBEgSuAQQGCg8KBwQDBAICAgIS
BK4BCQoKKgoEBAMCABIEsgECExocIEEgbGFiZWwgZm9yIHRoZSB0aHJlc2hvbGQuCgoNCgUE
AwIABRIEsgECCAoNCgUEAwIAARIEsgEJDgoNCgUEAwIAAxIEsgEREgprCgQEAwIBEgS2AQIT
Gl0gVGhlIHZhbHVlIG9mIHRoZSB0aHJlc2hvbGQuIFRoZSB2YWx1ZSBzaG91bGQgYmUgZGVm
aW5lZCBpbiB0aGUgbmF0aXZlIHNjYWxlCiBvZiB0aGUgbWV0cmljLgoKDQoFBAMCAQUSBLYB
AggKDQoFBAMCAQESBLYBCQ4KDQoFBAMCAQMSBLYBERIKVgoEBAMCAhIEuQECEhpIIFRoZSBz
dGF0ZSBjb2xvciBmb3IgdGhpcyB0aHJlc2hvbGQuIENvbG9yIGlzIG5vdCBhbGxvd2VkIGlu
IGEgWHlDaGFydC4KCg0KBQQDAgIGEgS5AQIHCg0KBQQDAgIBEgS5AQgNCg0KBQQDAgIDEgS5
ARARCmAKBAQDAgMSBL0BAhoaUiBUaGUgZGlyZWN0aW9uIGZvciB0aGUgY3VycmVudCB0aHJl
c2hvbGQuIERpcmVjdGlvbiBpcyBub3QgYWxsb3dlZCBpbiBhCiBYeUNoYXJ0LgoKDQoFBAMC
AwYSBL0BAgsKDQoFBAMCAwESBL0BDBUKDQoFBAMCAwMSBL0BGBkKbgoEBAMCBBIEwQECHRpg
IFRoZSB0YXJnZXQgYXhpcyB0byB1c2UgZm9yIHBsb3R0aW5nIHRoZSB0aHJlc2hvbGQuIFRh
cmdldCBheGlzIGlzIG5vdAogYWxsb3dlZCBpbiBhIFNjb3JlY2FyZC4KCg0KBQQDAgQGEgTB
AQIMCg0KBQQDAgQBEgTBAQ0YCg0KBQQDAgQDEgTBARscClcKAgUAEgbFAQDOAQEaSSBEZWZp
bmVzIHRoZSBwb3NzaWJsZSB0eXBlcyBvZiBzcGFyayBjaGFydCBzdXBwb3J0ZWQgYnkgdGhl
IGBTY29yZWNhcmRgLgoKCwoDBQABEgTFAQUTCjQKBAUAAgASBMcBAiMaJiBOb3QgYWxsb3dl
ZCBpbiB3ZWxsLWZvcm1lZCByZXF1ZXN0cy4KCg0KBQUAAgABEgTHAQIeCg0KBQUAAgACEgTH
ASEiCkUKBAUAAgESBMoBAhEaNyBUaGUgc3BhcmtsaW5lIHdpbGwgYmUgcmVuZGVyZWQgYXMg
YSBzbWFsbCBsaW5lIGNoYXJ0LgoKDQoFBQACAQESBMoBAgwKDQoFBQACAQISBMoBDxAKQwoE
BQACAhIEzQECEBo1IFRoZSBzcGFya2JhciB3aWxsIGJlIHJlbmRlcmVkIGFzIGEgc21hbGwg
YmFyIGNoYXJ0LgoKDQoFBQACAgESBM0BAgsKDQoFBQACAgISBM0BDg9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery ===
    # Fields for TimeSeriesQuery
    # Field: time_series_filter Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesFilter)
    # Field: time_series_filter_ratio Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesFilterRatio)
    # Field: time_series_query_language Type: 9 ()
    # Field: prometheus_query Type: 9 ()
    # Field: unit_override Type: 9 ()
    # Field: output_full_duration Type: 8 ()

# === Message: Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter ===
    # Fields for TimeSeriesFilter
    # Field: filter Type: 9 ()
    # Field: aggregation Type: 11 (.google.monitoring.dashboard.v1.Aggregation)
    # Field: secondary_aggregation Type: 11 (.google.monitoring.dashboard.v1.Aggregation)
    # Field: pick_time_series_filter Type: 11 (.google.monitoring.dashboard.v1.PickTimeSeriesFilter)
    # Field: statistical_time_series_filter Type: 11 (.google.monitoring.dashboard.v1.StatisticalTimeSeriesFilter)

# === Message: Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio ===
    # Fields for TimeSeriesFilterRatio
    # Field: numerator Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesFilterRatio.RatioPart)
    # Field: denominator Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesFilterRatio.RatioPart)
    # Field: secondary_aggregation Type: 11 (.google.monitoring.dashboard.v1.Aggregation)
    # Field: pick_time_series_filter Type: 11 (.google.monitoring.dashboard.v1.PickTimeSeriesFilter)
    # Field: statistical_time_series_filter Type: 11 (.google.monitoring.dashboard.v1.StatisticalTimeSeriesFilter)

# === Message: Google::Monitoring::Dashboard::V1::Metrics::Threshold ===
    # Fields for Threshold
    # Field: label Type: 9 ()
    # Field: value Type: 1 ()
    # Field: color Type: 14 (.google.monitoring.dashboard.v1.Threshold.Color)
    # Field: direction Type: 14 (.google.monitoring.dashboard.v1.Threshold.Direction)
    # Field: target_axis Type: 14 (.google.monitoring.dashboard.v1.Threshold.TargetAxis)

# Enum: Threshold::Color
our $Threshold_COLOR_UNSPECIFIED = 0;
our $Threshold_YELLOW = 4;
our $Threshold_RED = 6;

# Enum: Threshold::Direction
our $Threshold_DIRECTION_UNSPECIFIED = 0;
our $Threshold_ABOVE = 1;
our $Threshold_BELOW = 2;

# Enum: Threshold::TargetAxis
our $Threshold_TARGET_AXIS_UNSPECIFIED = 0;
our $Threshold_Y1 = 1;
our $Threshold_Y2 = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Metrics - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/metrics.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Metrics;

    my $msg = Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery->new({
        time_series_filter => $time_series_filter,
        time_series_filter_ratio => $time_series_filter_ratio,
        time_series_query_language => $time_series_query_language,
        prometheus_query => $prometheus_query,
    });

    # Read or update a field
    my $val = $msg->time_series_filter();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/metrics.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery

TimeSeriesQuery collects the set of supported methods for querying time
series data from the Stackdriver metrics API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_series_filter() >> / C<< $msg->time_series_filter($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter>)

Filter parameters to fetch time series.

=item * C<< $msg->time_series_filter_ratio() >> / C<< $msg->time_series_filter_ratio($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio>)

Parameters to fetch a ratio between two time series filters.

=item * C<< $msg->time_series_query_language() >> / C<< $msg->time_series_query_language($value) >>

Type: C<String>

A query used to fetch time series with MQL.

=item * C<< $msg->prometheus_query() >> / C<< $msg->prometheus_query($value) >>

Type: C<String>

A query used to fetch time series with PromQL.

=item * C<< $msg->unit_override() >> / C<< $msg->unit_override($value) >>

Type: C<String>

The unit of data contained in fetched time series. If non-empty, this
unit will override any unit that accompanies fetched data. The format is
the same as the
[`unit`](https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.metricDescriptors)
field in `MetricDescriptor`.

=item * C<< $msg->output_full_duration() >> / C<< $msg->output_full_duration($value) >>

Type: C<Bool>

Optional. If set, Cloud Monitoring will treat the full query duration as
the alignment period so that there will be only 1 output value.

*Note: This could override the configured alignment period except for
the cases where a series of data points are expected, like
  - XyChart
  - Scorecard's spark chart

=back

=head2 Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter

A filter that defines a subset of time series data that is displayed in a
widget. Time series data is fetched using the
[`ListTimeSeries`](https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/list)
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The [monitoring
filter](https://cloud.google.com/monitoring/api/v3/filters) that identifies
the metric types, resources, and projects to query.

=item * C<< $msg->aggregation() >> / C<< $msg->aggregation($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::Aggregation>)

By default, the raw time series data is returned.
Use this field to combine multiple time series for different views of the
data.

=item * C<< $msg->secondary_aggregation() >> / C<< $msg->secondary_aggregation($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::Aggregation>)

Apply a second aggregation after `aggregation` is applied.

=item * C<< $msg->pick_time_series_filter() >> / C<< $msg->pick_time_series_filter($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::PickTimeSeriesFilter>)

Ranking based time series filter.

=item * C<< $msg->statistical_time_series_filter() >> / C<< $msg->statistical_time_series_filter($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::StatisticalTimeSeriesFilter>)

Statistics based time series filter.
Note: This field is deprecated and completely ignored by the API.

=back

=head2 Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio

A pair of time series filters that define a ratio computation. The output
time series is the pair-wise division of each aligned element from the
numerator and denominator time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->numerator() >> / C<< $msg->numerator($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio::RatioPart>)

The numerator of the ratio.

=item * C<< $msg->denominator() >> / C<< $msg->denominator($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio::RatioPart>)

The denominator of the ratio.

=item * C<< $msg->secondary_aggregation() >> / C<< $msg->secondary_aggregation($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::Aggregation>)

Apply a second aggregation after the ratio is computed.

=item * C<< $msg->pick_time_series_filter() >> / C<< $msg->pick_time_series_filter($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::PickTimeSeriesFilter>)

Ranking based time series filter.

=item * C<< $msg->statistical_time_series_filter() >> / C<< $msg->statistical_time_series_filter($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Common::StatisticalTimeSeriesFilter>)

Statistics based time series filter.
Note: This field is deprecated and completely ignored by the API.

=back

=head2 Google::Monitoring::Dashboard::V1::Metrics::Threshold

Defines a threshold for categorizing time series values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

A label for the threshold.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Double>

The value of the threshold. The value should be defined in the native scale
of the metric.

=item * C<< $msg->color() >> / C<< $msg->color($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::Threshold::Color>)

The state color for this threshold. Color is not allowed in a XyChart.

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::Threshold::Direction>)

The direction for the current threshold. Direction is not allowed in a
XyChart.

=item * C<< $msg->target_axis() >> / C<< $msg->target_axis($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::Threshold::TargetAxis>)

The target axis to use for plotting the threshold. Target axis is not
allowed in a Scorecard.

=back

=head3 Enum: Threshold::Color

=over 4

=item * C<COLOR_UNSPECIFIED> => C<0>

=item * C<YELLOW> => C<4>

=item * C<RED> => C<6>

=back

=head3 Enum: Threshold::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<ABOVE> => C<1>

=item * C<BELOW> => C<2>

=back

=head3 Enum: Threshold::TargetAxis

=over 4

=item * C<TARGET_AXIS_UNSPECIFIED> => C<0>

=item * C<Y1> => C<1>

=item * C<Y2> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Metrics::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
