package Google::Cloud::Osconfig::V1beta::OsconfigService;

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
    eval { require Google::Cloud::Osconfig::V1beta::GuestPolicies };
    eval { require Google::Cloud::Osconfig::V1beta::PatchDeployments };
    eval { require Google::Cloud::Osconfig::V1beta::PatchJobs };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvb3Njb25maWcvdjFiZXRhL29zY29uZmlnX3NlcnZpY2UucHJvdG8S
HGdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGjFnb29nbGUvY2xvdWQvb3Njb25maWcv
djFiZXRhL2d1ZXN0X3BvbGljaWVzLnByb3RvGjRnb29nbGUvY2xvdWQvb3Njb25maWcvdjFi
ZXRhL3BhdGNoX2RlcGxveW1lbnRzLnByb3RvGi1nb29nbGUvY2xvdWQvb3Njb25maWcvdjFi
ZXRhL3BhdGNoX2pvYnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bzKTHAoP
T3NDb25maWdTZXJ2aWNlEqkBCg9FeGVjdXRlUGF0Y2hKb2ISNC5nb29nbGUuY2xvdWQub3Nj
b25maWcudjFiZXRhLkV4ZWN1dGVQYXRjaEpvYlJlcXVlc3QaJi5nb29nbGUuY2xvdWQub3Nj
b25maWcudjFiZXRhLlBhdGNoSm9iIjiC0+STAjIiLS92MWJldGEve3BhcmVudD1wcm9qZWN0
cy8qfS9wYXRjaEpvYnM6ZXhlY3V0ZToBKhKWAQoLR2V0UGF0Y2hKb2ISMC5nb29nbGUuY2xv
dWQub3Njb25maWcudjFiZXRhLkdldFBhdGNoSm9iUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy52MWJldGEuUGF0Y2hKb2IiLYLT5JMCJxIlL3YxYmV0YS97bmFtZT1wcm9qZWN0
cy8qL3BhdGNoSm9icy8qfRKmAQoOQ2FuY2VsUGF0Y2hKb2ISMy5nb29nbGUuY2xvdWQub3Nj
b25maWcudjFiZXRhLkNhbmNlbFBhdGNoSm9iUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5vc2Nv
bmZpZy52MWJldGEuUGF0Y2hKb2IiN4LT5JMCMSIsL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8q
L3BhdGNoSm9icy8qfTpjYW5jZWw6ASoSpwEKDUxpc3RQYXRjaEpvYnMSMi5nb29nbGUuY2xv
dWQub3Njb25maWcudjFiZXRhLkxpc3RQYXRjaEpvYnNSZXF1ZXN0GjMuZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLnYxYmV0YS5MaXN0UGF0Y2hKb2JzUmVzcG9uc2UiLYLT5JMCJxIlL3YxYmV0
YS97cGFyZW50PXByb2plY3RzLyp9L3BhdGNoSm9icxLsAQobTGlzdFBhdGNoSm9iSW5zdGFu
Y2VEZXRhaWxzEkAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5MaXN0UGF0Y2hKb2JJ
bnN0YW5jZURldGFpbHNSZXF1ZXN0GkEuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5M
aXN0UGF0Y2hKb2JJbnN0YW5jZURldGFpbHNSZXNwb25zZSJIgtPkkwI5EjcvdjFiZXRhL3tw
YXJlbnQ9cHJvamVjdHMvKi9wYXRjaEpvYnMvKn0vaW5zdGFuY2VEZXRhaWxz2kEGcGFyZW50
EsoBChVDcmVhdGVQYXRjaERlcGxveW1lbnQSOi5nb29nbGUuY2xvdWQub3Njb25maWcudjFi
ZXRhLkNyZWF0ZVBhdGNoRGVwbG95bWVudFJlcXVlc3QaLS5nb29nbGUuY2xvdWQub3Njb25m
aWcudjFiZXRhLlBhdGNoRGVwbG95bWVudCJGgtPkkwJAIiwvdjFiZXRhL3twYXJlbnQ9cHJv
amVjdHMvKn0vcGF0Y2hEZXBsb3ltZW50czoQcGF0Y2hfZGVwbG95bWVudBKyAQoSR2V0UGF0
Y2hEZXBsb3ltZW50EjcuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5HZXRQYXRjaERl
cGxveW1lbnRSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5QYXRjaERl
cGxveW1lbnQiNILT5JMCLhIsL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL3BhdGNoRGVwbG95
bWVudHMvKn0SwwEKFExpc3RQYXRjaERlcGxveW1lbnRzEjkuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLnYxYmV0YS5MaXN0UGF0Y2hEZXBsb3ltZW50c1JlcXVlc3QaOi5nb29nbGUuY2xvdWQu
b3Njb25maWcudjFiZXRhLkxpc3RQYXRjaERlcGxveW1lbnRzUmVzcG9uc2UiNILT5JMCLhIs
L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyp9L3BhdGNoRGVwbG95bWVudHMSoQEKFURlbGV0
ZVBhdGNoRGVwbG95bWVudBI6Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuRGVsZXRl
UGF0Y2hEZXBsb3ltZW50UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI0gtPkkwIu
KiwvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qfRL6AQoVVXBk
YXRlUGF0Y2hEZXBsb3ltZW50EjouZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5VcGRh
dGVQYXRjaERlcGxveW1lbnRSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0
YS5QYXRjaERlcGxveW1lbnQidoLT5JMCUTI9L3YxYmV0YS97cGF0Y2hfZGVwbG95bWVudC5u
YW1lPXByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qfToQcGF0Y2hfZGVwbG95bWVudNpB
HHBhdGNoX2RlcGxveW1lbnQsdXBkYXRlX21hc2sSxgEKFFBhdXNlUGF0Y2hEZXBsb3ltZW50
EjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5QYXVzZVBhdGNoRGVwbG95bWVudFJl
cXVlc3QaLS5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLlBhdGNoRGVwbG95bWVudCJE
gtPkkwI3IjIvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qfTpw
YXVzZToBKtpBBG5hbWUSyQEKFVJlc3VtZVBhdGNoRGVwbG95bWVudBI6Lmdvb2dsZS5jbG91
ZC5vc2NvbmZpZy52MWJldGEuUmVzdW1lUGF0Y2hEZXBsb3ltZW50UmVxdWVzdBotLmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuUGF0Y2hEZXBsb3ltZW50IkWC0+STAjgiMy92MWJl
dGEve25hbWU9cHJvamVjdHMvKi9wYXRjaERlcGxveW1lbnRzLyp9OnJlc3VtZToBKtpBBG5h
bWUSzgEKEUNyZWF0ZUd1ZXN0UG9saWN5EjYuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0
YS5DcmVhdGVHdWVzdFBvbGljeVJlcXVlc3QaKS5nb29nbGUuY2xvdWQub3Njb25maWcudjFi
ZXRhLkd1ZXN0UG9saWN5IlaC0+STAjkiKS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qfS9n
dWVzdFBvbGljaWVzOgxndWVzdF9wb2xpY3naQRRwYXJlbnQsIGd1ZXN0X3BvbGljeRKqAQoO
R2V0R3Vlc3RQb2xpY3kSMy5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLkdldEd1ZXN0
UG9saWN5UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuR3Vlc3RQb2xp
Y3kiOILT5JMCKxIpL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2d1ZXN0UG9saWNpZXMvKn3a
QQRuYW1lEsABChFMaXN0R3Vlc3RQb2xpY2llcxI2Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52
MWJldGEuTGlzdEd1ZXN0UG9saWNpZXNSZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLm9zY29uZmln
LnYxYmV0YS5MaXN0R3Vlc3RQb2xpY2llc1Jlc3BvbnNlIjqC0+STAisSKS92MWJldGEve3Bh
cmVudD1wcm9qZWN0cy8qfS9ndWVzdFBvbGljaWVz2kEGcGFyZW50Et8BChFVcGRhdGVHdWVz
dFBvbGljeRI2Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuVXBkYXRlR3Vlc3RQb2xp
Y3lSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5HdWVzdFBvbGljeSJn
gtPkkwJGMjYvdjFiZXRhL3tndWVzdF9wb2xpY3kubmFtZT1wcm9qZWN0cy8qL2d1ZXN0UG9s
aWNpZXMvKn06DGd1ZXN0X3BvbGljedpBGGd1ZXN0X3BvbGljeSx1cGRhdGVfbWFzaxKdAQoR
RGVsZXRlR3Vlc3RQb2xpY3kSNi5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLkRlbGV0
ZUd1ZXN0UG9saWN5UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI4gtPkkwIrKikv
djFiZXRhL3tuYW1lPXByb2plY3RzLyovZ3Vlc3RQb2xpY2llcy8qfdpBBG5hbWUS6gEKGkxv
b2t1cEVmZmVjdGl2ZUd1ZXN0UG9saWN5Ej8uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0
YS5Mb29rdXBFZmZlY3RpdmVHdWVzdFBvbGljeVJlcXVlc3QaMi5nb29nbGUuY2xvdWQub3Nj
b25maWcudjFiZXRhLkVmZmVjdGl2ZUd1ZXN0UG9saWN5IleC0+STAlEiTC92MWJldGEve2lu
c3RhbmNlPXByb2plY3RzLyovem9uZXMvKi9pbnN0YW5jZXMvKn06bG9va3VwRWZmZWN0aXZl
R3Vlc3RQb2xpY3k6ASoaS8pBF29zY29uZmlnLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJvCiBjb20uZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxYmV0YUINT3NDb25maWdQcm90b1o8Y2xvdWQuZ29vZ2xlLmNvbS9n
by9vc2NvbmZpZy9hcGl2MWJldGEvb3Njb25maWdwYjtvc2NvbmZpZ3BiSvEfCgcSBQ4AuQEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAA7CgkKAgMDEgMVAD4KCQoCAwQSAxYANwoJCgIDBRID
FwAlCggKAQgSAxkAUwoJCgIICxIDGQBTCggKAQgSAxoALgoJCgIICBIDGgAuCggKAQgSAxsA
OQoJCgIIARIDGwA5CrABCgIGABIFIQC5AQEaogEgT1MgQ29uZmlnIEFQSQoKIFRoZSBPUyBD
b25maWcgc2VydmljZSBpcyBhIHNlcnZlci1zaWRlIGNvbXBvbmVudCB0aGF0IHlvdSBjYW4g
dXNlIHRvCiBtYW5hZ2UgcGFja2FnZSBpbnN0YWxsYXRpb25zIGFuZCBwYXRjaCBqb2JzIGZv
ciB2aXJ0dWFsIG1hY2hpbmUgaW5zdGFuY2VzLgoKCgoDBgABEgMhCBcKCgoDBgADEgMiAj8K
DAoFBgADmQgSAyICPwoKCgMGAAMSAyMCVgoMCgUGAAOaCBIDIwJWCkcKBAYAAgASBCYCKwMa
OSBQYXRjaCBWTSBpbnN0YW5jZXMgYnkgY3JlYXRpbmcgYW5kIHJ1bm5pbmcgYSBwYXRjaCBq
b2IuCgoMCgUGAAIAARIDJgYVCgwKBQYAAgACEgMmFiwKDAoFBgACAAMSAyY3PwoNCgUGAAIA
BBIEJwQqBgoRCgkGAAIABLDKvCISBCcEKgYKiwEKBAYAAgESBC8CMwMafSBHZXQgdGhlIHBh
dGNoIGpvYi4gVGhpcyBjYW4gYmUgdXNlZCB0byB0cmFjayB0aGUgcHJvZ3Jlc3Mgb2YgYW4K
IG9uZ29pbmcgcGF0Y2ggam9iIG9yIHJldmlldyB0aGUgZGV0YWlscyBvZiBjb21wbGV0ZWQg
am9icy4KCgwKBQYAAgEBEgMvBhEKDAoFBgACAQISAy8SJAoMCgUGAAIBAxIDLy83Cg0KBQYA
AgEEEgQwBDIGChEKCQYAAgEEsMq8IhIEMAQyBgprCgQGAAICEgQ3AjwDGl0gQ2FuY2VsIGEg
cGF0Y2ggam9iLiBUaGUgcGF0Y2ggam9iIG11c3QgYmUgYWN0aXZlLiBDYW5jZWxlZCBwYXRj
aCBqb2JzCiBjYW5ub3QgYmUgcmVzdGFydGVkLgoKDAoFBgACAgESAzcGFAoMCgUGAAICAhID
NxUqCgwKBQYAAgIDEgM3NT0KDQoFBgACAgQSBDgEOwYKEQoJBgACAgSwyrwiEgQ4BDsGCikK
BAYAAgMSBD8CQwMaGyBHZXQgYSBsaXN0IG9mIHBhdGNoIGpvYnMuCgoMCgUGAAIDARIDPwYT
CgwKBQYAAgMCEgM/FCgKDAoFBgACAwMSAz8zSAoNCgUGAAIDBBIEQARCBgoRCgkGAAIDBLDK
vCISBEAEQgYKRQoEBgACBBIERgJLAxo3IEdldCBhIGxpc3Qgb2YgaW5zdGFuY2UgZGV0YWls
cyBmb3IgYSBnaXZlbiBwYXRjaCBqb2IuCgoMCgUGAAIEARIDRgYhCgwKBQYAAgQCEgNGIkQK
DAoFBgACBAMSA0ZPcgoNCgUGAAIEBBIERwRJBgoRCgkGAAIEBLDKvCISBEcESQYKDAoFBgAC
BAQSA0oENAoPCggGAAIEBJsIABIDSgQ0CjUKBAYAAgUSBE4CUwMaJyBDcmVhdGUgYW4gT1Mg
Q29uZmlnIHBhdGNoIGRlcGxveW1lbnQuCgoMCgUGAAIFARIDTgYbCgwKBQYAAgUCEgNOHDgK
DAoFBgACBQMSA05DUgoNCgUGAAIFBBIETwRSBgoRCgkGAAIFBLDKvCISBE8EUgYKMgoEBgAC
BhIEVgJaAxokIEdldCBhbiBPUyBDb25maWcgcGF0Y2ggZGVwbG95bWVudC4KCgwKBQYAAgYB
EgNWBhgKDAoFBgACBgISA1YZMgoMCgUGAAIGAxIDVj1MCg0KBQYAAgYEEgRXBFkGChEKCQYA
AgYEsMq8IhIEVwRZBgo6CgQGAAIHEgRdAmEDGiwgR2V0IGEgcGFnZSBvZiBPUyBDb25maWcg
cGF0Y2ggZGVwbG95bWVudHMuCgoMCgUGAAIHARIDXQYaCgwKBQYAAgcCEgNdGzYKDAoFBgAC
BwMSA11BXQoNCgUGAAIHBBIEXgRgBgoRCgkGAAIHBLDKvCISBF4EYAYKNQoEBgACCBIEZAJo
AxonIERlbGV0ZSBhbiBPUyBDb25maWcgcGF0Y2ggZGVwbG95bWVudC4KCgwKBQYAAggBEgNk
BhsKDAoFBgACCAISA2QcOAoMCgUGAAIIAxIDZENYCg0KBQYAAggEEgRlBGcGChEKCQYAAggE
sMq8IhIEZQRnBgo1CgQGAAIJEgRrAnEDGicgVXBkYXRlIGFuIE9TIENvbmZpZyBwYXRjaCBk
ZXBsb3ltZW50LgoKDAoFBgACCQESA2sGGwoMCgUGAAIJAhIDaxw4CgwKBQYAAgkDEgNrQ1IK
DQoFBgACCQQSBGwEbwYKEQoJBgACCQSwyrwiEgRsBG8GCgwKBQYAAgkEEgNwBEoKDwoIBgAC
CQSbCAASA3AESgp8CgQGAAIKEgR1AnsDGm4gQ2hhbmdlIHN0YXRlIG9mIHBhdGNoIGRlcGxv
eW1lbnQgdG8gIlBBVVNFRCIuCiBQYXRjaCBkZXBsb3ltZW50IGluIHBhdXNlZCBzdGF0ZSBk
b2Vzbid0IGdlbmVyYXRlIHBhdGNoIGpvYnMuCgoMCgUGAAIKARIDdQYaCgwKBQYAAgoCEgN1
GzYKDAoFBgACCgMSA3VBUAoNCgUGAAIKBBIEdgR5BgoRCgkGAAIKBLDKvCISBHYEeQYKDAoF
BgACCgQSA3oEMgoPCggGAAIKBJsIABIDegQyCocBCgQGAAILEgV/AoUBAxp4IENoYW5nZSBz
dGF0ZSBvZiBwYXRjaCBkZXBsb3ltZW50IGJhY2sgdG8gIkFDVElWRSIuCiBQYXRjaCBkZXBs
b3ltZW50IGluIGFjdGl2ZSBzdGF0ZSBjb250aW51ZXMgdG8gZ2VuZXJhdGUgcGF0Y2ggam9i
cy4KCgwKBQYAAgsBEgN/BhsKDAoFBgACCwISA38cOAoMCgUGAAILAxIDf0NSCg8KBQYAAgsE
EgaAAQSDAQYKEwoJBgACCwSwyrwiEgaAAQSDAQYKDQoFBgACCwQSBIQBBDIKEAoIBgACCwSb
CAASBIQBBDIKMwoEBgACDBIGiAECjgEDGiMgQ3JlYXRlIGFuIE9TIENvbmZpZyBndWVzdCBw
b2xpY3kuCgoNCgUGAAIMARIEiAEGFwoNCgUGAAIMAhIEiAEYMAoNCgUGAAIMAxIEiAE7RgoP
CgUGAAIMBBIGiQEEjAEGChMKCQYAAgwEsMq8IhIGiQEEjAEGCg0KBQYAAgwEEgSNAQRCChAK
CAYAAgwEmwgAEgSNAQRCCjAKBAYAAg0SBpEBApYBAxogIEdldCBhbiBPUyBDb25maWcgZ3Vl
c3QgcG9saWN5LgoKDQoFBgACDQESBJEBBhQKDQoFBgACDQISBJEBFSoKDQoFBgACDQMSBJEB
NUAKDwoFBgACDQQSBpIBBJQBBgoTCgkGAAINBLDKvCISBpIBBJQBBgoNCgUGAAINBBIElQEE
MgoQCggGAAINBJsIABIElQEEMgo5CgQGAAIOEgaZAQKeAQMaKSBHZXQgYSBwYWdlIG9mIE9T
IENvbmZpZyBndWVzdCBwb2xpY2llcy4KCg0KBQYAAg4BEgSZAQYXCg0KBQYAAg4CEgSZARgw
Cg0KBQYAAg4DEgSZATtUCg8KBQYAAg4EEgaaAQScAQYKEwoJBgACDgSwyrwiEgaaAQScAQYK
DQoFBgACDgQSBJ0BBDQKEAoIBgACDgSbCAASBJ0BBDQKMwoEBgACDxIGoQECpwEDGiMgVXBk
YXRlIGFuIE9TIENvbmZpZyBndWVzdCBwb2xpY3kuCgoNCgUGAAIPARIEoQEGFwoNCgUGAAIP
AhIEoQEYMAoNCgUGAAIPAxIEoQE7RgoPCgUGAAIPBBIGogEEpQEGChMKCQYAAg8EsMq8IhIG
ogEEpQEGCg0KBQYAAg8EEgSmAQRGChAKCAYAAg8EmwgAEgSmAQRGCjMKBAYAAhASBqoBAq8B
AxojIERlbGV0ZSBhbiBPUyBDb25maWcgZ3Vlc3QgcG9saWN5LgoKDQoFBgACEAESBKoBBhcK
DQoFBgACEAISBKoBGDAKDQoFBgACEAMSBKoBO1AKDwoFBgACEAQSBqsBBK0BBgoTCgkGAAIQ
BLDKvCISBqsBBK0BBgoNCgUGAAIQBBIErgEEMgoQCggGAAIQBJsIABIErgEEMgqgAQoEBgAC
ERIGswECuAEDGo8BIExvb2t1cCB0aGUgZWZmZWN0aXZlIGd1ZXN0IHBvbGljeSB0aGF0IGFw
cGxpZXMgdG8gYSBWTSBpbnN0YW5jZS4gVGhpcwogbG9va3VwIG1lcmdlcyBhbGwgcG9saWNp
ZXMgdGhhdCBhcmUgYXNzaWduZWQgdG8gdGhlIGluc3RhbmNlIGFuY2VzdHJ5LgoKDQoFBgAC
EQESBLMBBiAKDQoFBgACEQISBLMBIUIKDQoFBgACEQMSBLMBTWEKDwoFBgACEQQSBrQBBLcB
BgoTCgkGAAIRBLDKvCISBrQBBLcBBmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Osconfig::V1beta::OsconfigService::OsConfigServiceClient ===
package Google::Cloud::Osconfig::V1beta::OsconfigService::OsConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::V1beta::OsconfigService::OsConfigServiceClient

Client stub representing the remote C<OsConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub execute_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchJobs::ExecutePatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ExecutePatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob',
    });
}

sub get_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchJobs::GetPatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'GetPatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob',
    });
}

sub cancel_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchJobs::CancelPatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'CancelPatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob',
    });
}

sub list_patch_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ListPatchJobs',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsResponse',
    });
}

sub list_patch_job_instance_details {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ListPatchJobInstanceDetails',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsResponse',
    });
}

sub create_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::CreatePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'CreatePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment',
    });
}

sub get_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::GetPatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'GetPatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment',
    });
}

sub list_patch_deployments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ListPatchDeployments',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsResponse',
    });
}

sub delete_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::DeletePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'DeletePatchDeployment',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::UpdatePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'UpdatePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment',
    });
}

sub pause_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::PausePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'PausePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment',
    });
}

sub resume_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::PatchDeployments::ResumePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ResumePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment',
    });
}

sub create_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::CreateGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'CreateGuestPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy',
    });
}

sub get_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::GetGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'GetGuestPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy',
    });
}

sub list_guest_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'ListGuestPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesResponse',
    });
}

sub update_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::UpdateGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'UpdateGuestPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy',
    });
}

sub delete_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::DeleteGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'DeleteGuestPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub lookup_effective_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1beta.OsConfigService',
        method         => 'LookupEffectiveGuestPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1beta::OsconfigService - Compiled Protocol Buffers messages for google/cloud/osconfig/v1beta/osconfig_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1beta/osconfig_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1beta::OsconfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
