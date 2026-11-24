package Google::Logging::V2::LoggingMetrics;

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
    eval { require Google::Api::Distribution };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Metric };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvbG9nZ2luZy92Mi9sb2dnaW5nX21ldHJpY3MucHJvdG8SEWdvb2dsZS5sb2dn
aW5nLnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVu
dC5wcm90bxodZ29vZ2xlL2FwaS9kaXN0cmlidXRpb24ucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aF2dvb2dsZS9hcGkvbWV0cmljLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3QYKCUxvZ01ldHJpYxIXCgRuYW1lGAEgASgJQgPg
QQJSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SGwoGZmls
dGVyGAMgASgJQgPgQQJSBmZpbHRlchIkCgtidWNrZXRfbmFtZRgNIAEoCUID4EEBUgpidWNr
ZXROYW1lEh8KCGRpc2FibGVkGAwgASgIQgPgQQFSCGRpc2FibGVkEk4KEW1ldHJpY19kZXNj
cmlwdG9yGAUgASgLMhwuZ29vZ2xlLmFwaS5NZXRyaWNEZXNjcmlwdG9yQgPgQQFSEG1ldHJp
Y0Rlc2NyaXB0b3ISLAoPdmFsdWVfZXh0cmFjdG9yGAYgASgJQgPgQQFSDnZhbHVlRXh0cmFj
dG9yEmEKEGxhYmVsX2V4dHJhY3RvcnMYByADKAsyMS5nb29nbGUubG9nZ2luZy52Mi5Mb2dN
ZXRyaWMuTGFiZWxFeHRyYWN0b3JzRW50cnlCA+BBAVIPbGFiZWxFeHRyYWN0b3JzElIKDmJ1
Y2tldF9vcHRpb25zGAggASgLMiYuZ29vZ2xlLmFwaS5EaXN0cmlidXRpb24uQnVja2V0T3B0
aW9uc0ID4EEBUg1idWNrZXRPcHRpb25zEkAKC2NyZWF0ZV90aW1lGAkgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAog
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkUKB3Zl
cnNpb24YBCABKA4yJy5nb29nbGUubG9nZ2luZy52Mi5Mb2dNZXRyaWMuQXBpVmVyc2lvbkIC
GAFSB3ZlcnNpb24aQgoUTGFiZWxFeHRyYWN0b3JzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASIcCgpBcGlWZXJzaW9uEgYKAlYyEAASBgoCVjEQ
ATpK6kFHCiBsb2dnaW5nLmdvb2dsZWFwaXMuY29tL0xvZ01ldHJpYxIjcHJvamVjdHMve3By
b2plY3R9L21ldHJpY3Mve21ldHJpY30iqgEKFUxpc3RMb2dNZXRyaWNzUmVxdWVzdBJLCgZw
YXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5j
b20vUHJvamVjdFIGcGFyZW50EiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2Vu
EiAKCXBhZ2Vfc2l6ZRgDIAEoBUID4EEBUghwYWdlU2l6ZSJ4ChZMaXN0TG9nTWV0cmljc1Jl
c3BvbnNlEjYKB21ldHJpY3MYASADKAsyHC5nb29nbGUubG9nZ2luZy52Mi5Mb2dNZXRyaWNS
B21ldHJpY3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuImAKE0dl
dExvZ01ldHJpY1JlcXVlc3QSSQoLbWV0cmljX25hbWUYASABKAlCKOBBAvpBIgogbG9nZ2lu
Zy5nb29nbGVhcGlzLmNvbS9Mb2dNZXRyaWNSCm1ldHJpY05hbWUilQEKFkNyZWF0ZUxvZ01l
dHJpY1JlcXVlc3QSQAoGcGFyZW50GAEgASgJQijgQQL6QSISIGxvZ2dpbmcuZ29vZ2xlYXBp
cy5jb20vTG9nTWV0cmljUgZwYXJlbnQSOQoGbWV0cmljGAIgASgLMhwuZ29vZ2xlLmxvZ2dp
bmcudjIuTG9nTWV0cmljQgPgQQJSBm1ldHJpYyKeAQoWVXBkYXRlTG9nTWV0cmljUmVxdWVz
dBJJCgttZXRyaWNfbmFtZRgBIAEoCUIo4EEC+kEiCiBsb2dnaW5nLmdvb2dsZWFwaXMuY29t
L0xvZ01ldHJpY1IKbWV0cmljTmFtZRI5CgZtZXRyaWMYAiABKAsyHC5nb29nbGUubG9nZ2lu
Zy52Mi5Mb2dNZXRyaWNCA+BBAlIGbWV0cmljImMKFkRlbGV0ZUxvZ01ldHJpY1JlcXVlc3QS
SQoLbWV0cmljX25hbWUYASABKAlCKOBBAvpBIgogbG9nZ2luZy5nb29nbGVhcGlzLmNvbS9M
b2dNZXRyaWNSCm1ldHJpY05hbWUyrggKEE1ldHJpY3NTZXJ2aWNlVjISlwEKDkxpc3RMb2dN
ZXRyaWNzEiguZ29vZ2xlLmxvZ2dpbmcudjIuTGlzdExvZ01ldHJpY3NSZXF1ZXN0GikuZ29v
Z2xlLmxvZ2dpbmcudjIuTGlzdExvZ01ldHJpY3NSZXNwb25zZSIwgtPkkwIhEh8vdjIve3Bh
cmVudD1wcm9qZWN0cy8qfS9tZXRyaWNz2kEGcGFyZW50EpIBCgxHZXRMb2dNZXRyaWMSJi5n
b29nbGUubG9nZ2luZy52Mi5HZXRMb2dNZXRyaWNSZXF1ZXN0GhwuZ29vZ2xlLmxvZ2dpbmcu
djIuTG9nTWV0cmljIjyC0+STAigSJi92Mi97bWV0cmljX25hbWU9cHJvamVjdHMvKi9tZXRy
aWNzLyp92kELbWV0cmljX25hbWUSmwEKD0NyZWF0ZUxvZ01ldHJpYxIpLmdvb2dsZS5sb2dn
aW5nLnYyLkNyZWF0ZUxvZ01ldHJpY1JlcXVlc3QaHC5nb29nbGUubG9nZ2luZy52Mi5Mb2dN
ZXRyaWMiP4LT5JMCKSIfL3YyL3twYXJlbnQ9cHJvamVjdHMvKn0vbWV0cmljczoGbWV0cmlj
2kENcGFyZW50LG1ldHJpYxKnAQoPVXBkYXRlTG9nTWV0cmljEikuZ29vZ2xlLmxvZ2dpbmcu
djIuVXBkYXRlTG9nTWV0cmljUmVxdWVzdBocLmdvb2dsZS5sb2dnaW5nLnYyLkxvZ01ldHJp
YyJLgtPkkwIwGiYvdjIve21ldHJpY19uYW1lPXByb2plY3RzLyovbWV0cmljcy8qfToGbWV0
cmlj2kESbWV0cmljX25hbWUsbWV0cmljEpIBCg9EZWxldGVMb2dNZXRyaWMSKS5nb29nbGUu
bG9nZ2luZy52Mi5EZWxldGVMb2dNZXRyaWNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5IjyC0+STAigqJi92Mi97bWV0cmljX25hbWU9cHJvamVjdHMvKi9tZXRyaWNzLyp92kEL
bWV0cmljX25hbWUajQLKQRZsb2dnaW5nLmdvb2dsZWFwaXMuY29t0kHwAWh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybS5yZWFkLW9ubHksaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9sb2dnaW5nLmFkbWluLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvbG9nZ2luZy5yZWFkLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
bG9nZ2luZy53cml0ZUK5AQoVY29tLmdvb2dsZS5sb2dnaW5nLnYyQhNMb2dnaW5nTWV0cmlj
c1Byb3RvUAFaNWNsb3VkLmdvb2dsZS5jb20vZ28vbG9nZ2luZy9hcGl2Mi9sb2dnaW5ncGI7
bG9nZ2luZ3Bi+AEBqgIXR29vZ2xlLkNsb3VkLkxvZ2dpbmcuVjLKAhdHb29nbGVcQ2xvdWRc
TG9nZ2luZ1xWMuoCGkdvb2dsZTo6Q2xvdWQ6OkxvZ2dpbmc6OlYySrxZCgcSBQ4A0gIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAaCgkKAgMAEgMSACYK
CQoCAwESAxMAIQoJCgIDAhIDFAAnCgkKAgMDEgMVACkKCQoCAwQSAxYAIQoJCgIDBRIDFwAj
CgkKAgMGEgMYACUKCQoCAwcSAxkAKQoICgEIEgMbAB8KCQoCCB8SAxsAHwoICgEIEgMcADQK
CQoCCCUSAxwANAoICgEIEgMdAEwKCQoCCAsSAx0ATAoICgEIEgMeACIKCQoCCAoSAx4AIgoI
CgEIEgMfADQKCQoCCAgSAx8ANAoICgEIEgMgAC4KCQoCCAESAyAALgoICgEIEgMhADQKCQoC
CCkSAyEANAoICgEIEgMiADMKCQoCCC0SAyIAMwo5CgIGABIEJQBXARotIFNlcnZpY2UgZm9y
IGNvbmZpZ3VyaW5nIGxvZ3MtYmFzZWQgbWV0cmljcy4KCgoKAwYAARIDJQgYCgoKAwYAAxID
JgI+CgwKBQYAA5kIEgMmAj4KCwoDBgADEgQnAiw2Cg0KBQYAA5oIEgQnAiw2CikKBAYAAgAS
BC8CNAMaGyBMaXN0cyBsb2dzLWJhc2VkIG1ldHJpY3MuCgoMCgUGAAIAARIDLwYUCgwKBQYA
AgACEgMvFSoKDAoFBgACAAMSAy81SwoNCgUGAAIABBIEMAQyBgoRCgkGAAIABLDKvCISBDAE
MgYKDAoFBgACAAQSAzMENAoPCggGAAIABJsIABIDMwQ0CikKBAYAAgESBDcCPAMaGyBHZXRz
IGEgbG9ncy1iYXNlZCBtZXRyaWMuCgoMCgUGAAIBARIDNwYSCgwKBQYAAgECEgM3EyYKDAoF
BgACAQMSAzcxOgoNCgUGAAIBBBIEOAQ6BgoRCgkGAAIBBLDKvCISBDgEOgYKDAoFBgACAQQS
AzsEOQoPCggGAAIBBJsIABIDOwQ5CiwKBAYAAgISBD8CRQMaHiBDcmVhdGVzIGEgbG9ncy1i
YXNlZCBtZXRyaWMuCgoMCgUGAAICARIDPwYVCgwKBQYAAgICEgM/FiwKDAoFBgACAgMSAz83
QAoNCgUGAAICBBIEQARDBgoRCgkGAAICBLDKvCISBEAEQwYKDAoFBgACAgQSA0QEOwoPCggG
AAICBJsIABIDRAQ7CjcKBAYAAgMSBEgCTgMaKSBDcmVhdGVzIG9yIHVwZGF0ZXMgYSBsb2dz
LWJhc2VkIG1ldHJpYy4KCgwKBQYAAgMBEgNIBhUKDAoFBgACAwISA0gWLAoMCgUGAAIDAxID
SDdACg0KBQYAAgMEEgRJBEwGChEKCQYAAgMEsMq8IhIESQRMBgoMCgUGAAIDBBIDTQRACg8K
CAYAAgMEmwgAEgNNBEAKLAoEBgACBBIEUQJWAxoeIERlbGV0ZXMgYSBsb2dzLWJhc2VkIG1l
dHJpYy4KCgwKBQYAAgQBEgNRBhUKDAoFBgACBAISA1EWLAoMCgUGAAIEAxIDUTdMCg0KBQYA
AgQEEgRSBFQGChEKCQYAAgQEsMq8IhIEUgRUBgoMCgUGAAIEBBIDVQQ5Cg8KCAYAAgQEmwgA
EgNVBDkKmAMKAgQAEgVgAO4BARqKAyBEZXNjcmliZXMgYSBsb2dzLWJhc2VkIG1ldHJpYy4g
VGhlIHZhbHVlIG9mIHRoZSBtZXRyaWMgaXMgdGhlIG51bWJlciBvZiBsb2cKIGVudHJpZXMg
dGhhdCBtYXRjaCBhIGxvZ3MgZmlsdGVyIGluIGEgZ2l2ZW4gdGltZSBpbnRlcnZhbC4KCiBM
b2dzLWJhc2VkIG1ldHJpY3MgY2FuIGFsc28gYmUgdXNlZCB0byBleHRyYWN0IHZhbHVlcyBm
cm9tIGxvZ3MgYW5kIGNyZWF0ZSBhCiBkaXN0cmlidXRpb24gb2YgdGhlIHZhbHVlcy4gVGhl
IGRpc3RyaWJ1dGlvbiByZWNvcmRzIHRoZSBzdGF0aXN0aWNzIG9mIHRoZQogZXh0cmFjdGVk
IHZhbHVlcyBhbG9uZyB3aXRoIGFuIG9wdGlvbmFsIGhpc3RvZ3JhbSBvZiB0aGUgdmFsdWVz
IGFzIHNwZWNpZmllZAogYnkgdGhlIGJ1Y2tldCBvcHRpb25zLgoKCgoDBAABEgNgCBEKCwoD
BAAHEgRhAmQECg0KBQQAB50IEgRhAmQECiQKBAQABAASBGcCbQMaFiBMb2dnaW5nIEFQSSB2
ZXJzaW9uLgoKDAoFBAAEAAESA2cHEQogCgYEAAQAAgASA2kECxoRIExvZ2dpbmcgQVBJIHYy
LgoKDgoHBAAEAAIAARIDaQQGCg4KBwQABAACAAISA2kJCgogCgYEAAQAAgESA2wECxoRIExv
Z2dpbmcgQVBJIHYxLgoKDgoHBAAEAAIBARIDbAQGCg4KBwQABAACAQISA2wJCgqXBQoEBAAC
ABIDfAI7GokFIFJlcXVpcmVkLiBUaGUgY2xpZW50LWFzc2lnbmVkIG1ldHJpYyBpZGVudGlm
aWVyLgogRXhhbXBsZXM6IGAiZXJyb3JfY291bnQiYCwgYCJuZ2lueC9yZXF1ZXN0cyJgLgoK
IE1ldHJpYyBpZGVudGlmaWVycyBhcmUgbGltaXRlZCB0byAxMDAgY2hhcmFjdGVycyBhbmQg
Y2FuIGluY2x1ZGUgb25seSB0aGUKIGZvbGxvd2luZyBjaGFyYWN0ZXJzOiBgQS1aYCwgYGEt
emAsIGAwLTlgLCBhbmQgdGhlIHNwZWNpYWwgY2hhcmFjdGVycwogYF8tLiwrISonLCgpJS9g
LiBUaGUgZm9yd2FyZC1zbGFzaCBjaGFyYWN0ZXIgKGAvYCkgZGVub3RlcyBhIGhpZXJhcmNo
eSBvZgogbmFtZSBwaWVjZXMsIGFuZCBpdCBjYW5ub3QgYmUgdGhlIGZpcnN0IGNoYXJhY3Rl
ciBvZiB0aGUgbmFtZS4KCiBUaGlzIGZpZWxkIGlzIHRoZSBgW01FVFJJQ19JRF1gIHBhcnQg
b2YgYSBtZXRyaWMgcmVzb3VyY2UgbmFtZSBpbiB0aGUKIGZvcm1hdCAicHJvamVjdHMvW1BS
T0pFQ1RfSURdL21ldHJpY3MvW01FVFJJQ19JRF0iLiBFeGFtcGxlOiBJZiB0aGUKIHJlc291
cmNlIG5hbWUgb2YgYSBtZXRyaWMgaXMKIGAicHJvamVjdHMvbXktcHJvamVjdC9tZXRyaWNz
L25naW54JTJGcmVxdWVzdHMiYCwgdGhpcyBmaWVsZCdzIHZhbHVlIGlzCiBgIm5naW54L3Jl
cXVlc3RzImAuCgoMCgUEAAIABRIDfAIICgwKBQQAAgABEgN8CQ0KDAoFBAACAAMSA3wQEQoM
CgUEAAIACBIDfBI6Cg8KCAQAAgAInAgAEgN8EzkKkwEKBAQAAgESBIABAkIahAEgT3B0aW9u
YWwuIEEgZGVzY3JpcHRpb24gb2YgdGhpcyBtZXRyaWMsIHdoaWNoIGlzIHVzZWQgaW4gZG9j
dW1lbnRhdGlvbi4KIFRoZSBtYXhpbXVtIGxlbmd0aCBvZiB0aGUgZGVzY3JpcHRpb24gaXMg
ODAwMCBjaGFyYWN0ZXJzLgoKDQoFBAACAQUSBIABAggKDQoFBAACAQESBIABCRQKDQoFBAAC
AQMSBIABFxgKDQoFBAACAQgSBIABGUEKEAoIBAACAQicCAASBIABGkAKigIKBAQAAgISBIkB
Aj0a+wEgUmVxdWlyZWQuIEFuIFthZHZhbmNlZCBsb2dzCiBmaWx0ZXJdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9sb2dnaW5nL2RvY3Mvdmlldy9hZHZhbmNlZF9maWx0ZXJzKSB3aGlj
aAogaXMgdXNlZCB0byBtYXRjaCBsb2cgZW50cmllcy4gRXhhbXBsZToKCiAgICAgInJlc291
cmNlLnR5cGU9Z2FlX2FwcCBBTkQgc2V2ZXJpdHk+PUVSUk9SIgoKIFRoZSBtYXhpbXVtIGxl
bmd0aCBvZiB0aGUgZmlsdGVyIGlzIDIwMDAwIGNoYXJhY3RlcnMuCgoNCgUEAAICBRIEiQEC
CAoNCgUEAAICARIEiQEJDwoNCgUEAAICAxIEiQESEwoNCgUEAAICCBIEiQEUPAoQCggEAAIC
CJwIABIEiQEVOwrRAgoEBAACAxIElAECQxrCAiBPcHRpb25hbC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIExvZyBCdWNrZXQgdGhhdCBvd25zIHRoZSBMb2cgTWV0cmljLgogT25seSBM
b2cgQnVja2V0cyBpbiBwcm9qZWN0cyBhcmUgc3VwcG9ydGVkLiBUaGUgYnVja2V0IGhhcyB0
byBiZSBpbiB0aGUKIHNhbWUgcHJvamVjdCBhcyB0aGUgbWV0cmljLgoKIEZvciBleGFtcGxl
OgoKICAgYHByb2plY3RzL215LXByb2plY3QvbG9jYXRpb25zL2dsb2JhbC9idWNrZXRzL215
LWJ1Y2tldGAKCiBJZiBlbXB0eSwgdGhlbiB0aGUgTG9nIE1ldHJpYyBpcyBjb25zaWRlcmVk
IGEgbm9uLUJ1Y2tldCBMb2cgTWV0cmljLgoKDQoFBAACAwUSBJQBAggKDQoFBAACAwESBJQB
CRQKDQoFBAACAwMSBJQBFxkKDQoFBAACAwgSBJQBGkIKEAoIBAACAwicCAASBJQBG0EKbAoE
BAACBBIEmAECPhpeIE9wdGlvbmFsLiBJZiBzZXQgdG8gVHJ1ZSwgdGhlbiB0aGlzIG1ldHJp
YyBpcyBkaXNhYmxlZCBhbmQgaXQgZG9lcyBub3QKIGdlbmVyYXRlIGFueSBwb2ludHMuCgoN
CgUEAAIEBRIEmAECBgoNCgUEAAIEARIEmAEHDwoNCgUEAAIEAxIEmAESFAoNCgUEAAIECBIE
mAEVPQoQCggEAAIECJwIABIEmAEWPAquCAoEBAACBRIGrwECsAEvGp0IIE9wdGlvbmFsLiBU
aGUgbWV0cmljIGRlc2NyaXB0b3IgYXNzb2NpYXRlZCB3aXRoIHRoZSBsb2dzLWJhc2VkIG1l
dHJpYy4KIElmIHVuc3BlY2lmaWVkLCBpdCB1c2VzIGEgZGVmYXVsdCBtZXRyaWMgZGVzY3Jp
cHRvciB3aXRoIGEgREVMVEEgbWV0cmljCiBraW5kLCBJTlQ2NCB2YWx1ZSB0eXBlLCB3aXRo
IG5vIGxhYmVscyBhbmQgYSB1bml0IG9mICIxIi4gU3VjaCBhIG1ldHJpYwogY291bnRzIHRo
ZSBudW1iZXIgb2YgbG9nIGVudHJpZXMgbWF0Y2hpbmcgdGhlIGBmaWx0ZXJgIGV4cHJlc3Np
b24uCgogVGhlIGBuYW1lYCwgYHR5cGVgLCBhbmQgYGRlc2NyaXB0aW9uYCBmaWVsZHMgaW4g
dGhlIGBtZXRyaWNfZGVzY3JpcHRvcmAKIGFyZSBvdXRwdXQgb25seSwgYW5kIGlzIGNvbnN0
cnVjdGVkIHVzaW5nIHRoZSBgbmFtZWAgYW5kIGBkZXNjcmlwdGlvbmAKIGZpZWxkIGluIHRo
ZSBMb2dNZXRyaWMuCgogVG8gY3JlYXRlIGEgbG9ncy1iYXNlZCBtZXRyaWMgdGhhdCByZWNv
cmRzIGEgZGlzdHJpYnV0aW9uIG9mIGxvZyB2YWx1ZXMsIGEKIERFTFRBIG1ldHJpYyBraW5k
IHdpdGggYSBESVNUUklCVVRJT04gdmFsdWUgdHlwZSBtdXN0IGJlIHVzZWQgYWxvbmcgd2l0
aAogYSBgdmFsdWVfZXh0cmFjdG9yYCBleHByZXNzaW9uIGluIHRoZSBMb2dNZXRyaWMuCgog
RWFjaCBsYWJlbCBpbiB0aGUgbWV0cmljIGRlc2NyaXB0b3IgbXVzdCBoYXZlIGEgbWF0Y2hp
bmcgbGFiZWwKIG5hbWUgYXMgdGhlIGtleSBhbmQgYW4gZXh0cmFjdG9yIGV4cHJlc3Npb24g
YXMgdGhlIHZhbHVlIGluIHRoZQogYGxhYmVsX2V4dHJhY3RvcnNgIG1hcC4KCiBUaGUgYG1l
dHJpY19raW5kYCBhbmQgYHZhbHVlX3R5cGVgIGZpZWxkcyBpbiB0aGUgYG1ldHJpY19kZXNj
cmlwdG9yYCBjYW5ub3QKIGJlIHVwZGF0ZWQgb25jZSBpbml0aWFsbHkgY29uZmlndXJlZC4g
TmV3IGxhYmVscyBjYW4gYmUgYWRkZWQgaW4gdGhlCiBgbWV0cmljX2Rlc2NyaXB0b3JgLCBi
dXQgZXhpc3RpbmcgbGFiZWxzIGNhbm5vdCBiZSBtb2RpZmllZCBleGNlcHQgZm9yCiB0aGVp
ciBkZXNjcmlwdGlvbi4KCg0KBQQAAgUGEgSvAQIdCg0KBQQAAgUBEgSvAR4vCg0KBQQAAgUD
EgSvATIzCg0KBQQAAgUIEgSwAQYuChAKCAQAAgUInAgAEgSwAQctCpwICgQEAAIGEgTGAQJG
Go0IIE9wdGlvbmFsLiBBIGB2YWx1ZV9leHRyYWN0b3JgIGlzIHJlcXVpcmVkIHdoZW4gdXNp
bmcgYSBkaXN0cmlidXRpb24KIGxvZ3MtYmFzZWQgbWV0cmljIHRvIGV4dHJhY3QgdGhlIHZh
bHVlcyB0byByZWNvcmQgZnJvbSBhIGxvZyBlbnRyeS4KIFR3byBmdW5jdGlvbnMgYXJlIHN1
cHBvcnRlZCBmb3IgdmFsdWUgZXh0cmFjdGlvbjogYEVYVFJBQ1QoZmllbGQpYCBvcgogYFJF
R0VYUF9FWFRSQUNUKGZpZWxkLCByZWdleClgLiBUaGUgYXJndW1lbnRzIGFyZToKCiAgIDEu
IGZpZWxkOiBUaGUgbmFtZSBvZiB0aGUgbG9nIGVudHJ5IGZpZWxkIGZyb20gd2hpY2ggdGhl
IHZhbHVlIGlzIHRvIGJlCiAgICAgIGV4dHJhY3RlZC4KICAgMi4gcmVnZXg6IEEgcmVndWxh
ciBleHByZXNzaW9uIHVzaW5nIHRoZSBHb29nbGUgUkUyIHN5bnRheAogICAgICAoaHR0cHM6
Ly9naXRodWIuY29tL2dvb2dsZS9yZTIvd2lraS9TeW50YXgpIHdpdGggYSBzaW5nbGUgY2Fw
dHVyZQogICAgICBncm91cCB0byBleHRyYWN0IGRhdGEgZnJvbSB0aGUgc3BlY2lmaWVkIGxv
ZyBlbnRyeSBmaWVsZC4gVGhlIHZhbHVlCiAgICAgIG9mIHRoZSBmaWVsZCBpcyBjb252ZXJ0
ZWQgdG8gYSBzdHJpbmcgYmVmb3JlIGFwcGx5aW5nIHRoZSByZWdleC4KICAgICAgSXQgaXMg
YW4gZXJyb3IgdG8gc3BlY2lmeSBhIHJlZ2V4IHRoYXQgZG9lcyBub3QgaW5jbHVkZSBleGFj
dGx5IG9uZQogICAgICBjYXB0dXJlIGdyb3VwLgoKIFRoZSByZXN1bHQgb2YgdGhlIGV4dHJh
Y3Rpb24gbXVzdCBiZSBjb252ZXJ0aWJsZSB0byBhIGRvdWJsZSB0eXBlLCBhcyB0aGUKIGRp
c3RyaWJ1dGlvbiBhbHdheXMgcmVjb3JkcyBkb3VibGUgdmFsdWVzLiBJZiBlaXRoZXIgdGhl
IGV4dHJhY3Rpb24gb3IKIHRoZSBjb252ZXJzaW9uIHRvIGRvdWJsZSBmYWlscywgdGhlbiB0
aG9zZSB2YWx1ZXMgYXJlIG5vdCByZWNvcmRlZCBpbiB0aGUKIGRpc3RyaWJ1dGlvbi4KCiBF
eGFtcGxlOiBgUkVHRVhQX0VYVFJBQ1QoanNvblBheWxvYWQucmVxdWVzdCwgIi4qcXVhbnRp
dHk9KFxkKykuKiIpYAoKDQoFBAACBgUSBMYBAggKDQoFBAACBgESBMYBCRgKDQoFBAACBgMS
BMYBGxwKDQoFBAACBggSBMYBHUUKEAoIBAACBgicCAASBMYBHkQKoAYKBAQAAgcSBtYBAtcB
LxqPBiBPcHRpb25hbC4gQSBtYXAgZnJvbSBhIGxhYmVsIGtleSBzdHJpbmcgdG8gYW4gZXh0
cmFjdG9yIGV4cHJlc3Npb24gd2hpY2ggaXMKIHVzZWQgdG8gZXh0cmFjdCBkYXRhIGZyb20g
YSBsb2cgZW50cnkgZmllbGQgYW5kIGFzc2lnbiBhcyB0aGUgbGFiZWwgdmFsdWUuCiBFYWNo
IGxhYmVsIGtleSBzcGVjaWZpZWQgaW4gdGhlIExhYmVsRGVzY3JpcHRvciBtdXN0IGhhdmUg
YW4gYXNzb2NpYXRlZAogZXh0cmFjdG9yIGV4cHJlc3Npb24gaW4gdGhpcyBtYXAuIFRoZSBz
eW50YXggb2YgdGhlIGV4dHJhY3RvciBleHByZXNzaW9uCiBpcyB0aGUgc2FtZSBhcyBmb3Ig
dGhlIGB2YWx1ZV9leHRyYWN0b3JgIGZpZWxkLgoKIFRoZSBleHRyYWN0ZWQgdmFsdWUgaXMg
Y29udmVydGVkIHRvIHRoZSB0eXBlIGRlZmluZWQgaW4gdGhlIGxhYmVsCiBkZXNjcmlwdG9y
LiBJZiBlaXRoZXIgdGhlIGV4dHJhY3Rpb24gb3IgdGhlIHR5cGUgY29udmVyc2lvbiBmYWls
cywKIHRoZSBsYWJlbCB3aWxsIGhhdmUgYSBkZWZhdWx0IHZhbHVlLiBUaGUgZGVmYXVsdCB2
YWx1ZSBmb3IgYSBzdHJpbmcKIGxhYmVsIGlzIGFuIGVtcHR5IHN0cmluZywgZm9yIGFuIGlu
dGVnZXIgbGFiZWwgaXRzIDAsIGFuZCBmb3IgYSBib29sZWFuCiBsYWJlbCBpdHMgYGZhbHNl
YC4KCiBOb3RlIHRoYXQgdGhlcmUgYXJlIHVwcGVyIGJvdW5kcyBvbiB0aGUgbWF4aW11bSBu
dW1iZXIgb2YgbGFiZWxzIGFuZCB0aGUKIG51bWJlciBvZiBhY3RpdmUgdGltZSBzZXJpZXMg
dGhhdCBhcmUgYWxsb3dlZCBpbiBhIHByb2plY3QuCgoNCgUEAAIHBhIE1gECFQoNCgUEAAIH
ARIE1gEWJgoNCgUEAAIHAxIE1gEpKgoNCgUEAAIHCBIE1wEGLgoQCggEAAIHCJwIABIE1wEH
LQrZAQoEBAACCBIG3AEC3QEvGsgBIE9wdGlvbmFsLiBUaGUgYGJ1Y2tldF9vcHRpb25zYCBh
cmUgcmVxdWlyZWQgd2hlbiB0aGUgbG9ncy1iYXNlZCBtZXRyaWMgaXMKIHVzaW5nIGEgRElT
VFJJQlVUSU9OIHZhbHVlIHR5cGUgYW5kIGl0IGRlc2NyaWJlcyB0aGUgYnVja2V0IGJvdW5k
YXJpZXMKIHVzZWQgdG8gY3JlYXRlIGEgaGlzdG9ncmFtIG9mIHRoZSBleHRyYWN0ZWQgdmFs
dWVzLgoKDQoFBAACCAYSBNwBAicKDQoFBAACCAESBNwBKDYKDQoFBAACCAMSBNwBOToKDQoF
BAACCAgSBN0BBi4KEAoIBAACCAicCAASBN0BBy0KdwoEBAACCRIG4gEC4wEyGmcgT3V0cHV0
IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lc3RhbXAgb2YgdGhlIG1ldHJpYy4KCiBUaGlzIGZp
ZWxkIG1heSBub3QgYmUgcHJlc2VudCBmb3Igb2xkZXIgbWV0cmljcy4KCg0KBQQAAgkGEgTi
AQIbCg0KBQQAAgkBEgTiARwnCg0KBQQAAgkDEgTiASorCg0KBQQAAgkIEgTjAQYxChAKCAQA
AgkInAgAEgTjAQcwCnoKBAQAAgoSBugBAukBMhpqIE91dHB1dCBvbmx5LiBUaGUgbGFzdCB1
cGRhdGUgdGltZXN0YW1wIG9mIHRoZSBtZXRyaWMuCgogVGhpcyBmaWVsZCBtYXkgbm90IGJl
IHByZXNlbnQgZm9yIG9sZGVyIG1ldHJpY3MuCgoNCgUEAAIKBhIE6AECGwoNCgUEAAIKARIE
6AEcJwoNCgUEAAIKAxIE6AEqLAoNCgUEAAIKCBIE6QEGMQoQCggEAAIKCJwIABIE6QEHMAqJ
AQoEBAACCxIE7QECLRp7IERlcHJlY2F0ZWQuIFRoZSBBUEkgdmVyc2lvbiB0aGF0IGNyZWF0
ZWQgb3IgdXBkYXRlZCB0aGlzIG1ldHJpYy4KIFRoZSB2MiBmb3JtYXQgaXMgdXNlZCBieSBk
ZWZhdWx0IGFuZCBjYW5ub3QgYmUgY2hhbmdlZC4KCg0KBQQAAgsGEgTtAQIMCg0KBQQAAgsB
EgTtAQ0UCg0KBQQAAgsDEgTtARcYCg0KBQQAAgsIEgTtARksCg4KBgQAAgsIAxIE7QEaKwox
CgIEARIG8QEAhgIBGiMgVGhlIHBhcmFtZXRlcnMgdG8gTGlzdExvZ01ldHJpY3MuCgoLCgME
AQESBPEBCB0KaQoEBAECABIG9QEC+gEEGlkgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBw
cm9qZWN0IGNvbnRhaW5pbmcgdGhlIG1ldHJpY3M6CgogICAgICJwcm9qZWN0cy9bUFJPSkVD
VF9JRF0iCgoNCgUEAQIABRIE9QECCAoNCgUEAQIAARIE9QEJDwoNCgUEAQIAAxIE9QESEwoP
CgUEAQIACBIG9QEU+gEDChAKCAQBAgAInAgAEgT2AQQqChEKBwQBAgAInwgSBvcBBPkBBQqf
AgoEBAECARIEgAICQRqQAiBPcHRpb25hbC4gSWYgcHJlc2VudCwgdGhlbiByZXRyaWV2ZSB0
aGUgbmV4dCBiYXRjaCBvZiByZXN1bHRzIGZyb20gdGhlCiBwcmVjZWRpbmcgY2FsbCB0byB0
aGlzIG1ldGhvZC4gYHBhZ2VUb2tlbmAgbXVzdCBiZSB0aGUgdmFsdWUgb2YKIGBuZXh0UGFn
ZVRva2VuYCBmcm9tIHRoZSBwcmV2aW91cyByZXNwb25zZS4gVGhlIHZhbHVlcyBvZiBvdGhl
ciBtZXRob2QKIHBhcmFtZXRlcnMgc2hvdWxkIGJlIGlkZW50aWNhbCB0byB0aG9zZSBpbiB0
aGUgcHJldmlvdXMgY2FsbC4KCg0KBQQBAgEFEgSAAgIICg0KBQQBAgEBEgSAAgkTCg0KBQQB
AgEDEgSAAhYXCg0KBQQBAgEIEgSAAhhAChAKCAQBAgEInAgAEgSAAhk/CtgBCgQEAQICEgSF
AgI/GskBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1
cm4gZnJvbSB0aGlzIHJlcXVlc3QuCiBOb24tcG9zaXRpdmUgdmFsdWVzIGFyZSBpZ25vcmVk
LiBUaGUgcHJlc2VuY2Ugb2YgYG5leHRQYWdlVG9rZW5gIGluIHRoZQogcmVzcG9uc2UgaW5k
aWNhdGVzIHRoYXQgbW9yZSByZXN1bHRzIG1pZ2h0IGJlIGF2YWlsYWJsZS4KCg0KBQQBAgIF
EgSFAgIHCg0KBQQBAgIBEgSFAggRCg0KBQQBAgIDEgSFAhQVCg0KBQQBAgIIEgSFAhY+ChAK
CAQBAgIInAgAEgSFAhc9CjQKAgQCEgaJAgCRAgEaJiBSZXN1bHQgcmV0dXJuZWQgZnJvbSBM
aXN0TG9nTWV0cmljcy4KCgsKAwQCARIEiQIIHgotCgQEAgIAEgSLAgIhGh8gQSBsaXN0IG9m
IGxvZ3MtYmFzZWQgbWV0cmljcy4KCg0KBQQCAgAEEgSLAgIKCg0KBQQCAgAGEgSLAgsUCg0K
BQQCAgABEgSLAhUcCg0KBQQCAgADEgSLAh8gCtsBCgQEAgIBEgSQAgIdGswBIElmIHRoZXJl
IG1pZ2h0IGJlIG1vcmUgcmVzdWx0cyB0aGFuIGFwcGVhciBpbiB0aGlzIHJlc3BvbnNlLCB0
aGVuCiBgbmV4dFBhZ2VUb2tlbmAgaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQg
b2YgcmVzdWx0cywgY2FsbCB0aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9m
IGBuZXh0UGFnZVRva2VuYCBhcyBgcGFnZVRva2VuYC4KCg0KBQQCAgEFEgSQAgIICg0KBQQC
AgEBEgSQAgkYCg0KBQQCAgEDEgSQAhscCi8KAgQDEgaUAgCeAgEaISBUaGUgcGFyYW1ldGVy
cyB0byBHZXRMb2dNZXRyaWMuCgoLCgMEAwESBJQCCBsKdgoEBAMCABIGmAICnQIEGmYgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkZXNpcmVkIG1ldHJpYzoKCiAgICAg
InByb2plY3RzL1tQUk9KRUNUX0lEXS9tZXRyaWNzL1tNRVRSSUNfSURdIgoKDQoFBAMCAAUS
BJgCAggKDQoFBAMCAAESBJgCCRQKDQoFBAMCAAMSBJgCFxgKDwoFBAMCAAgSBpgCGZ0CAwoQ
CggEAwIACJwIABIEmQIEKgoRCgcEAwIACJ8IEgaaAgScAgUKMgoCBAQSBqECALECARokIFRo
ZSBwYXJhbWV0ZXJzIHRvIENyZWF0ZUxvZ01ldHJpYy4KCgsKAwQEARIEoQIIHgqsAQoEBAQC
ABIGpwICrAIEGpsBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvamVj
dCBpbiB3aGljaCB0byBjcmVhdGUgdGhlIG1ldHJpYzoKCiAgICAgInByb2plY3RzL1tQUk9K
RUNUX0lEXSIKCiBUaGUgbmV3IG1ldHJpYyBtdXN0IGJlIHByb3ZpZGVkIGluIHRoZSByZXF1
ZXN0LgoKDQoFBAQCAAUSBKcCAggKDQoFBAQCAAESBKcCCQ8KDQoFBAQCAAMSBKcCEhMKDwoF
BAQCAAgSBqcCFKwCAwoQCggEBAIACJwIABIEqAIEKgoRCgcEBAIACJ8IEgapAgSrAgUKbAoE
BAQCARIEsAICQBpeIFJlcXVpcmVkLiBUaGUgbmV3IGxvZ3MtYmFzZWQgbWV0cmljLCB3aGlj
aCBtdXN0IG5vdCBoYXZlIGFuIGlkZW50aWZpZXIgdGhhdAogYWxyZWFkeSBleGlzdHMuCgoN
CgUEBAIBBhIEsAICCwoNCgUEBAIBARIEsAIMEgoNCgUEBAIBAxIEsAIVFgoNCgUEBAIBCBIE
sAIXPwoQCggEBAIBCJwIABIEsAIYPgoyCgIEBRIGtAIAxQIBGiQgVGhlIHBhcmFtZXRlcnMg
dG8gVXBkYXRlTG9nTWV0cmljLgoKCwoDBAUBEgS0AggeCrYCCgQEBQIAEga8AgLBAgQapQIg
UmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRyaWMgdG8gdXBkYXRlOgoK
ICAgICAicHJvamVjdHMvW1BST0pFQ1RfSURdL21ldHJpY3MvW01FVFJJQ19JRF0iCgogVGhl
IHVwZGF0ZWQgbWV0cmljIG11c3QgYmUgcHJvdmlkZWQgaW4gdGhlIHJlcXVlc3QgYW5kIGl0
J3MKIGBuYW1lYCBmaWVsZCBtdXN0IGJlIHRoZSBzYW1lIGFzIGBbTUVUUklDX0lEXWAgSWYg
dGhlIG1ldHJpYwogZG9lcyBub3QgZXhpc3QgaW4gYFtQUk9KRUNUX0lEXWAsIHRoZW4gYSBu
ZXcgbWV0cmljIGlzIGNyZWF0ZWQuCgoNCgUEBQIABRIEvAICCAoNCgUEBQIAARIEvAIJFAoN
CgUEBQIAAxIEvAIXGAoPCgUEBQIACBIGvAIZwQIDChAKCAQFAgAInAgAEgS9AgQqChEKBwQF
AgAInwgSBr4CBMACBQotCgQEBQIBEgTEAgJAGh8gUmVxdWlyZWQuIFRoZSB1cGRhdGVkIG1l
dHJpYy4KCg0KBQQFAgEGEgTEAgILCg0KBQQFAgEBEgTEAgwSCg0KBQQFAgEDEgTEAhUWCg0K
BQQFAgEIEgTEAhc/ChAKCAQFAgEInAgAEgTEAhg+CjIKAgQGEgbIAgDSAgEaJCBUaGUgcGFy
YW1ldGVycyB0byBEZWxldGVMb2dNZXRyaWMuCgoLCgMEBgESBMgCCB4KeAoEBAYCABIGzAIC
0QIEGmggUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRyaWMgdG8gZGVs
ZXRlOgoKICAgICAicHJvamVjdHMvW1BST0pFQ1RfSURdL21ldHJpY3MvW01FVFJJQ19JRF0i
CgoNCgUEBgIABRIEzAICCAoNCgUEBgIAARIEzAIJFAoNCgUEBgIAAxIEzAIXGAoPCgUEBgIA
CBIGzAIZ0QIDChAKCAQGAgAInAgAEgTNAgQqChEKBwQGAgAInwgSBs4CBNACBWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Logging::V2::LoggingMetrics::LogMetric ===
    # Fields for LogMetric
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: bucket_name Type: 9 ()
    # Field: disabled Type: 8 ()
    # Field: metric_descriptor Type: 11 (.google.api.MetricDescriptor)
    # Field: value_extractor Type: 9 ()
    # Field: label_extractors Type: 11 (.google.logging.v2.LogMetric.LabelExtractorsEntry)
    # Field: bucket_options Type: 11 (.google.api.Distribution.BucketOptions)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: version Type: 14 (.google.logging.v2.LogMetric.ApiVersion)

# Enum: LogMetric::ApiVersion
our $LogMetric_V2 = 0;
our $LogMetric_V1 = 1;

# === Message: Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest ===
    # Fields for ListLogMetricsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse ===
    # Fields for ListLogMetricsResponse
    # Field: metrics Type: 11 (.google.logging.v2.LogMetric)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Logging::V2::LoggingMetrics::GetLogMetricRequest ===
    # Fields for GetLogMetricRequest
    # Field: metric_name Type: 9 ()

# === Message: Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest ===
    # Fields for CreateLogMetricRequest
    # Field: parent Type: 9 ()
    # Field: metric Type: 11 (.google.logging.v2.LogMetric)

# === Message: Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest ===
    # Fields for UpdateLogMetricRequest
    # Field: metric_name Type: 9 ()
    # Field: metric Type: 11 (.google.logging.v2.LogMetric)

# === Message: Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest ===
    # Fields for DeleteLogMetricRequest
    # Field: metric_name Type: 9 ()

# === Service Client: Google::Logging::V2::LoggingMetrics::MetricsServiceV2Client ===
package Google::Logging::V2::LoggingMetrics::MetricsServiceV2Client;

=pod

=head2 Service Client: Google::Logging::V2::LoggingMetrics::MetricsServiceV2Client

Client stub representing the remote C<MetricsServiceV2> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<logging.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'logging.googleapis.com:443' );

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

sub list_log_metrics {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.logging.v2.MetricsServiceV2',
        method         => 'ListLogMetrics',
        request        => $req,
        response_class => 'Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse',
    });
}

sub get_log_metric {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Logging::V2::LoggingMetrics::GetLogMetricRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.logging.v2.MetricsServiceV2',
        method         => 'GetLogMetric',
        request        => $req,
        response_class => 'Google::Logging::V2::LoggingMetrics::LogMetric',
    });
}

sub create_log_metric {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.logging.v2.MetricsServiceV2',
        method         => 'CreateLogMetric',
        request        => $req,
        response_class => 'Google::Logging::V2::LoggingMetrics::LogMetric',
    });
}

sub update_log_metric {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.logging.v2.MetricsServiceV2',
        method         => 'UpdateLogMetric',
        request        => $req,
        response_class => 'Google::Logging::V2::LoggingMetrics::LogMetric',
    });
}

sub delete_log_metric {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.logging.v2.MetricsServiceV2',
        method         => 'DeleteLogMetric',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Logging::V2::LoggingMetrics - Compiled Protocol Buffers messages for google/logging/v2/logging_metrics.proto

=head1 SYNOPSIS

    use Google::Logging::V2::LoggingMetrics;

    my $msg = Google::Logging::V2::LoggingMetrics::LogMetric->new({
        name => $name,
        description => $description,
        filter => $filter,
        bucket_name => $bucket_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Logging::V2::LoggingMetrics::LogMetric->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/logging/v2/logging_metrics.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Logging::V2::LoggingMetrics::LogMetric

Describes a logs-based metric. The value of the metric is the number of log
entries that match a logs filter in a given time interval.

Logs-based metrics can also be used to extract values from logs and create a
distribution of the values. The distribution records the statistics of the
extracted values along with an optional histogram of the values as specified
by the bucket options.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The client-assigned metric identifier.
Examples: `"error_count"`, `"nginx/requests"`.

Metric identifiers are limited to 100 characters and can include only the
following characters: `A-Z`, `a-z`, `0-9`, and the special characters
`_-.,+!*',()%/`. The forward-slash character (`/`) denotes a hierarchy of
name pieces, and it cannot be the first character of the name.

This field is the `[METRIC_ID]` part of a metric resource name in the
format "projects/[PROJECT_ID]/metrics/[METRIC_ID]". Example: If the
resource name of a metric is
`"projects/my-project/metrics/nginx%2Frequests"`, this field's value is
`"nginx/requests"`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A description of this metric, which is used in documentation.
The maximum length of the description is 8000 characters.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. An [advanced logs
filter](https://cloud.google.com/logging/docs/view/advanced_filters) which
is used to match log entries. Example:

    "resource.type=gae_app AND severity>=ERROR"

The maximum length of the filter is 20000 characters.

=item * C<< $msg->bucket_name() >> / C<< $msg->bucket_name($value) >>

Type: C<String>

Optional. The resource name of the Log Bucket that owns the Log Metric.
Only Log Buckets in projects are supported. The bucket has to be in the
same project as the metric.

For example:

  `projects/my-project/locations/global/buckets/my-bucket`

If empty, then the Log Metric is considered a non-Bucket Log Metric.

=item * C<< $msg->disabled() >> / C<< $msg->disabled($value) >>

Type: C<Bool>

Optional. If set to True, then this metric is disabled and it does not
generate any points.

=item * C<< $msg->metric_descriptor() >> / C<< $msg->metric_descriptor($value) >>

Type: C<Message> (L<Google::Api::Metric::MetricDescriptor>)

Optional. The metric descriptor associated with the logs-based metric.
If unspecified, it uses a default metric descriptor with a DELTA metric
kind, INT64 value type, with no labels and a unit of "1". Such a metric
counts the number of log entries matching the `filter` expression.

The `name`, `type`, and `description` fields in the `metric_descriptor`
are output only, and is constructed using the `name` and `description`
field in the LogMetric.

To create a logs-based metric that records a distribution of log values, a
DELTA metric kind with a DISTRIBUTION value type must be used along with
a `value_extractor` expression in the LogMetric.

Each label in the metric descriptor must have a matching label
name as the key and an extractor expression as the value in the
`label_extractors` map.

The `metric_kind` and `value_type` fields in the `metric_descriptor` cannot
be updated once initially configured. New labels can be added in the
`metric_descriptor`, but existing labels cannot be modified except for
their description.

=item * C<< $msg->value_extractor() >> / C<< $msg->value_extractor($value) >>

Type: C<String>

Optional. A `value_extractor` is required when using a distribution
logs-based metric to extract the values to record from a log entry.
Two functions are supported for value extraction: `EXTRACT(field)` or
`REGEXP_EXTRACT(field, regex)`. The arguments are:

  1. field: The name of the log entry field from which the value is to be
     extracted.
  2. regex: A regular expression using the Google RE2 syntax
     (https://github.com/google/re2/wiki/Syntax) with a single capture
     group to extract data from the specified log entry field. The value
     of the field is converted to a string before applying the regex.
     It is an error to specify a regex that does not include exactly one
     capture group.

The result of the extraction must be convertible to a double type, as the
distribution always records double values. If either the extraction or
the conversion to double fails, then those values are not recorded in the
distribution.

Example: `REGEXP_EXTRACT(jsonPayload.request, ".*quantity=(\d+).*")`

=item * C<< $msg->label_extractors() >> / C<< $msg->label_extractors($value) >>

Type: C<Message> (L<Google::Logging::V2::LoggingMetrics::LogMetric::LabelExtractorsEntry>)

Optional. A map from a label key string to an extractor expression which is
used to extract data from a log entry field and assign as the label value.
Each label key specified in the LabelDescriptor must have an associated
extractor expression in this map. The syntax of the extractor expression
is the same as for the `value_extractor` field.

The extracted value is converted to the type defined in the label
descriptor. If either the extraction or the type conversion fails,
the label will have a default value. The default value for a string
label is an empty string, for an integer label its 0, and for a boolean
label its `false`.

Note that there are upper bounds on the maximum number of labels and the
number of active time series that are allowed in a project.

=item * C<< $msg->bucket_options() >> / C<< $msg->bucket_options($value) >>

Type: C<Message> (L<Google::Api::Distribution::Distribution::BucketOptions>)

Optional. The `bucket_options` are required when the logs-based metric is
using a DISTRIBUTION value type and it describes the bucket boundaries
used to create a histogram of the extracted values.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation timestamp of the metric.

This field may not be present for older metrics.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update timestamp of the metric.

This field may not be present for older metrics.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Enum> (L<Google::Logging::V2::LogMetric::ApiVersion>)

Deprecated. The API version that created or updated this metric.
The v2 format is used by default and cannot be changed.

=back

=head3 Enum: LogMetric::ApiVersion

=over 4

=item * C<V2> => C<0>

=item * C<V1> => C<1>

=back

=head2 Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest

The parameters to ListLogMetrics.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project containing the metrics:

    "projects/[PROJECT_ID]"

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, then retrieve the next batch of results from the
preceding call to this method. `pageToken` must be the value of
`nextPageToken` from the previous response. The values of other method
parameters should be identical to those in the previous call.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive values are ignored. The presence of `nextPageToken` in the
response indicates that more results might be available.

=back

=head2 Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse

Result returned from ListLogMetrics.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Logging::V2::LoggingMetrics::LogMetric>)

A list of logs-based metrics.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than appear in this response, then
`nextPageToken` is included. To get the next set of results, call this
method again using the value of `nextPageToken` as `pageToken`.

=back

=head2 Google::Logging::V2::LoggingMetrics::GetLogMetricRequest

The parameters to GetLogMetric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metric_name() >> / C<< $msg->metric_name($value) >>

Type: C<String>

Required. The resource name of the desired metric:

    "projects/[PROJECT_ID]/metrics/[METRIC_ID]"

=back

=head2 Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest

The parameters to CreateLogMetric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the project in which to create the metric:

    "projects/[PROJECT_ID]"

The new metric must be provided in the request.

=item * C<< $msg->metric() >> / C<< $msg->metric($value) >>

Type: C<Message> (L<Google::Logging::V2::LoggingMetrics::LogMetric>)

Required. The new logs-based metric, which must not have an identifier that
already exists.

=back

=head2 Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest

The parameters to UpdateLogMetric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metric_name() >> / C<< $msg->metric_name($value) >>

Type: C<String>

Required. The resource name of the metric to update:

    "projects/[PROJECT_ID]/metrics/[METRIC_ID]"

The updated metric must be provided in the request and it's
`name` field must be the same as `[METRIC_ID]` If the metric
does not exist in `[PROJECT_ID]`, then a new metric is created.

=item * C<< $msg->metric() >> / C<< $msg->metric($value) >>

Type: C<Message> (L<Google::Logging::V2::LoggingMetrics::LogMetric>)

Required. The updated metric.

=back

=head2 Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest

The parameters to DeleteLogMetric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metric_name() >> / C<< $msg->metric_name($value) >>

Type: C<String>

Required. The resource name of the metric to delete:

    "projects/[PROJECT_ID]/metrics/[METRIC_ID]"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Logging::V2::LoggingMetrics::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
