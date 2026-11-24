package Google::Cloud::Contentwarehouse::V1::DocumentService;

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
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Contentwarehouse::V1::Common };
    eval { require Google::Cloud::Contentwarehouse::V1::Document };
    eval { require Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest };
    eval { require Google::Cloud::Contentwarehouse::V1::Histogram };
    eval { require Google::Cloud::Contentwarehouse::V1::RuleEngine };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9zZXJ2aWNlLnBy
b3RvEiBnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL2NvbW1vbi5w
cm90bxovZ29vZ2xlL2Nsb3VkL2NvbnRlbnR3YXJlaG91c2UvdjEvZG9jdW1lbnQucHJvdG8a
P2dvb2dsZS9jbG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL2RvY3VtZW50X3NlcnZpY2VfcmVx
dWVzdC5wcm90bxowZ29vZ2xlL2Nsb3VkL2NvbnRlbnR3YXJlaG91c2UvdjEvaGlzdG9ncmFt
LnByb3RvGjJnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9ydWxlX2VuZ2luZS5w
cm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3kucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9v
cGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8i6QIKFkNyZWF0
ZURvY3VtZW50UmVzcG9uc2USRgoIZG9jdW1lbnQYASABKAsyKi5nb29nbGUuY2xvdWQuY29u
dGVudHdhcmVob3VzZS52MS5Eb2N1bWVudFIIZG9jdW1lbnQSYAoScnVsZV9lbmdpbmVfb3V0
cHV0GAIgASgLMjIuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVsZUVuZ2lu
ZU91dHB1dFIQcnVsZUVuZ2luZU91dHB1dBJOCghtZXRhZGF0YRgDIAEoCzIyLmdvb2dsZS5j
bG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlc3BvbnNlTWV0YWRhdGFSCG1ldGFkYXRhElUK
F2xvbmdfcnVubmluZ19vcGVyYXRpb25zGAQgAygLMh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvblIVbG9uZ1J1bm5pbmdPcGVyYXRpb25zIpICChZVcGRhdGVEb2N1bWVudFJlc3Bv
bnNlEkYKCGRvY3VtZW50GAEgASgLMiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuRG9jdW1lbnRSCGRvY3VtZW50EmAKEnJ1bGVfZW5naW5lX291dHB1dBgCIAEoCzIyLmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJ1bGVFbmdpbmVPdXRwdXRSEHJ1bGVF
bmdpbmVPdXRwdXQSTgoIbWV0YWRhdGEYAyABKAsyMi5nb29nbGUuY2xvdWQuY29udGVudHdh
cmVob3VzZS52MS5SZXNwb25zZU1ldGFkYXRhUghtZXRhZGF0YSLWAQoIUUFSZXN1bHQSVAoK
aGlnaGxpZ2h0cxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlFB
UmVzdWx0LkhpZ2hsaWdodFIKaGlnaGxpZ2h0cxIpChBjb25maWRlbmNlX3Njb3JlGAIgASgC
Ug9jb25maWRlbmNlU2NvcmUaSQoJSGlnaGxpZ2h0Eh8KC3N0YXJ0X2luZGV4GAEgASgFUgpz
dGFydEluZGV4EhsKCWVuZF9pbmRleBgCIAEoBVIIZW5kSW5kZXgi1wUKF1NlYXJjaERvY3Vt
ZW50c1Jlc3BvbnNlEnkKEm1hdGNoaW5nX2RvY3VtZW50cxgBIAMoCzJKLmdvb2dsZS5jbG91
ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNlYXJjaERvY3VtZW50c1Jlc3BvbnNlLk1hdGNoaW5n
RG9jdW1lbnRSEW1hdGNoaW5nRG9jdW1lbnRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVIN
bmV4dFBhZ2VUb2tlbhIdCgp0b3RhbF9zaXplGAMgASgFUgl0b3RhbFNpemUSTgoIbWV0YWRh
dGEYBCABKAsyMi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SZXNwb25zZU1l
dGFkYXRhUghtZXRhZGF0YRJuChdoaXN0b2dyYW1fcXVlcnlfcmVzdWx0cxgGIAMoCzI2Lmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkhpc3RvZ3JhbVF1ZXJ5UmVzdWx0UhVo
aXN0b2dyYW1RdWVyeVJlc3VsdHMSJwoPcXVlc3Rpb25fYW5zd2VyGAcgASgJUg5xdWVzdGlv
bkFuc3dlchqQAgoQTWF0Y2hpbmdEb2N1bWVudBJGCghkb2N1bWVudBgBIAEoCzIqLmdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkRvY3VtZW50Ughkb2N1bWVudBIuChNzZWFy
Y2hfdGV4dF9zbmlwcGV0GAIgASgJUhFzZWFyY2hUZXh0U25pcHBldBJHCglxYV9yZXN1bHQY
AyABKAsyKi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5RQVJlc3VsdFIIcWFS
ZXN1bHQSOwoabWF0Y2hlZF90b2tlbl9wYWdlX2luZGljZXMYBCADKANSF21hdGNoZWRUb2tl
blBhZ2VJbmRpY2VzIpEBChBGZXRjaEFjbFJlc3BvbnNlEi0KBnBvbGljeRgBIAEoCzIVLmdv
b2dsZS5pYW0udjEuUG9saWN5UgZwb2xpY3kSTgoIbWV0YWRhdGEYAiABKAsyMi5nb29nbGUu
Y2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SZXNwb25zZU1ldGFkYXRhUghtZXRhZGF0YSKP
AQoOU2V0QWNsUmVzcG9uc2USLQoGcG9saWN5GAEgASgLMhUuZ29vZ2xlLmlhbS52MS5Qb2xp
Y3lSBnBvbGljeRJOCghtZXRhZGF0YRgCIAEoCzIyLmdvb2dsZS5jbG91ZC5jb250ZW50d2Fy
ZWhvdXNlLnYxLlJlc3BvbnNlTWV0YWRhdGFSCG1ldGFkYXRhMqIPCg9Eb2N1bWVudFNlcnZp
Y2USzwEKDkNyZWF0ZURvY3VtZW50EjcuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuQ3JlYXRlRG9jdW1lbnRSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91
c2UudjEuQ3JlYXRlRG9jdW1lbnRSZXNwb25zZSJKgtPkkwIyIi0vdjEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qfS9kb2N1bWVudHM6ASraQQ9wYXJlbnQsZG9jdW1lbnQS+QEK
C0dldERvY3VtZW50EjQuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuR2V0RG9j
dW1lbnRSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9jdW1l
bnQihwGC0+STAnoiMS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50
cy8qfTpnZXQ6ASpaQiI9L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZG9jdW1l
bnRzL3JlZmVyZW5jZUlkLyp9OmdldDoBKtpBBG5hbWUSjgIKDlVwZGF0ZURvY3VtZW50Ejcu
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuVXBkYXRlRG9jdW1lbnRSZXF1ZXN0
GjguZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuVXBkYXRlRG9jdW1lbnRSZXNw
b25zZSKIAYLT5JMCcjItL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZG9jdW1l
bnRzLyp9OgEqWj4yOS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50
cy9yZWZlcmVuY2VJZC8qfToBKtpBDW5hbWUsZG9jdW1lbnQS8gEKDkRlbGV0ZURvY3VtZW50
EjcuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRGVsZXRlRG9jdW1lbnRSZXF1
ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5Io4BgtPkkwKAASI0L3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovZG9jdW1lbnRzLyp9OmRlbGV0ZToBKlpFIkAvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kb2N1bWVudHMvcmVmZXJlbmNlSWQvKn06ZGVsZXRl
OgEq2kEEbmFtZRLQAQoPU2VhcmNoRG9jdW1lbnRzEjguZ29vZ2xlLmNsb3VkLmNvbnRlbnR3
YXJlaG91c2UudjEuU2VhcmNoRG9jdW1lbnRzUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5jb250
ZW50d2FyZWhvdXNlLnYxLlNlYXJjaERvY3VtZW50c1Jlc3BvbnNlIkiC0+STAjkiNC92MS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2RvY3VtZW50czpzZWFyY2g6ASraQQZw
YXJlbnQStwEKDExvY2tEb2N1bWVudBI1Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNl
LnYxLkxvY2tEb2N1bWVudFJlcXVlc3QaKi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3Vz
ZS52MS5Eb2N1bWVudCJEgtPkkwI3IjIvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9kb2N1bWVudHMvKn06bG9jazoBKtpBBG5hbWUS7AEKCEZldGNoQWNsEjEuZ29vZ2xlLmNs
b3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRmV0Y2hBY2xSZXF1ZXN0GjIuZ29vZ2xlLmNsb3Vk
LmNvbnRlbnR3YXJlaG91c2UudjEuRmV0Y2hBY2xSZXNwb25zZSJ5gtPkkwJoIjovdjEve3Jl
c291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovZG9jdW1lbnRzLyp9OmZldGNoQWNsOgEq
WiciIi92MS97cmVzb3VyY2U9cHJvamVjdHMvKn06ZmV0Y2hBY2w6ASraQQhyZXNvdXJjZRLp
AQoGU2V0QWNsEi8uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU2V0QWNsUmVx
dWVzdBowLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNldEFjbFJlc3BvbnNl
InyC0+STAmQiOC92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kb2N1bWVu
dHMvKn06c2V0QWNsOgEqWiUiIC92MS97cmVzb3VyY2U9cHJvamVjdHMvKn06c2V0QWNsOgEq
2kEPcmVzb3VyY2UscG9saWN5GlPKQR9jb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUL8AQok
Y29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxQhREb2N1bWVudFNlcnZpY2VQ
cm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2NvbnRlbnR3YXJlaG91c2UvYXBpdjEvY29u
dGVudHdhcmVob3VzZXBiO2NvbnRlbnR3YXJlaG91c2VwYqoCIEdvb2dsZS5DbG91ZC5Db250
ZW50V2FyZWhvdXNlLlYxygIgR29vZ2xlXENsb3VkXENvbnRlbnRXYXJlaG91c2VcVjHqAiNH
b29nbGU6OkNsb3VkOjpDb250ZW50V2FyZWhvdXNlOjpWMUqhQgoHEgUOAJYCAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAIwoJCgIDAxIDFQA3CgkKAgMEEgMWADkKCQoCAwUSAxcASQoJCgID
BhIDGAA6CgkKAgMHEgMZADwKCQoCAwgSAxoAJAoJCgIDCRIDGwAtCgkKAgMKEgMcACUKCAoB
CBIDHgA9CgkKAgglEgMeAD0KCAoBCBIDHwBnCgkKAggLEgMfAGcKCAoBCBIDIAAiCgkKAggK
EgMgACIKCAoBCBIDIQA1CgkKAggIEgMhADUKCAoBCBIDIgA9CgkKAggBEgMiAD0KCAoBCBID
IwA9CgkKAggpEgMjAD0KCAoBCBIDJAA8CgkKAggtEgMkADwKNQoCBgASBScAjAEBGiggVGhp
cyBzZXJ2aWNlIGxldHMgeW91IG1hbmFnZSBkb2N1bWVudC4KCgoKAwYAARIDJwgXCgoKAwYA
AxIDKAJHCgwKBQYAA5kIEgMoAkcKCwoDBgADEgQpAio3Cg0KBQYAA5oIEgQpAio3CiMKBAYA
AgASBC0CMwMaFSBDcmVhdGVzIGEgZG9jdW1lbnQuCgoMCgUGAAIAARIDLQYUCgwKBQYAAgAC
EgMtFSoKDAoFBgACAAMSAy01SwoNCgUGAAIABBIELgQxBgoRCgkGAAIABLDKvCISBC4EMQYK
DAoFBgACAAQSAzIEPQoPCggGAAIABJsIABIDMgQ9ClIKBAYAAgESBDYCQAMaRCBHZXRzIGEg
ZG9jdW1lbnQuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSBkb2N1bWVudCBkb2VzIG5vdCBl
eGlzdC4KCgwKBQYAAgEBEgM2BhEKDAoFBgACAQISAzYSJAoMCgUGAAIBAxIDNi83Cg0KBQYA
AgEEEgQ3BD4GChEKCQYAAgEEsMq8IhIENwQ+BgoMCgUGAAIBBBIDPwQyCg8KCAYAAgEEmwgA
EgM/BDIKjAEKBAYAAgISBEQCTgMafiBVcGRhdGVzIGEgZG9jdW1lbnQuIFJldHVybnMgSU5W
QUxJRF9BUkdVTUVOVCBpZiB0aGUgbmFtZSBvZiB0aGUgZG9jdW1lbnQKIGlzIG5vbi1lbXB0
eSBhbmQgZG9lcyBub3QgZXF1YWwgdGhlIGV4aXN0aW5nIG5hbWUuCgoMCgUGAAICARIDRAYU
CgwKBQYAAgICEgNEFSoKDAoFBgACAgMSA0Q1SwoNCgUGAAICBBIERQRMBgoRCgkGAAICBLDK
vCISBEUETAYKDAoFBgACAgQSA00EOwoPCggGAAICBJsIABIDTQQ7ClUKBAYAAgMSBFECWwMa
RyBEZWxldGVzIGEgZG9jdW1lbnQuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSBkb2N1bWVu
dCBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgMBEgNRBhQKDAoFBgACAwISA1EVKgoMCgUGAAID
AxIDUTVKCg0KBQYAAgMEEgRSBFkGChEKCQYAAgMEsMq8IhIEUgRZBgoMCgUGAAIDBBIDWgQy
Cg8KCAYAAgMEmwgAEgNaBDIK3wEKBAYAAgQSBGECaAMa0AEgU2VhcmNoZXMgZm9yIGRvY3Vt
ZW50cyB1c2luZyBwcm92aWRlZAogW1NlYXJjaERvY3VtZW50c1JlcXVlc3RdW2dvb2dsZS5j
bG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNlYXJjaERvY3VtZW50c1JlcXVlc3RdLgogVGhp
cyBjYWxsIG9ubHkgcmV0dXJucyBkb2N1bWVudHMgdGhhdCB0aGUgY2FsbGVyIGhhcyBwZXJt
aXNzaW9uIHRvIHNlYXJjaAogYWdhaW5zdC4KCgwKBQYAAgQBEgNhBhUKDAoFBgACBAISA2EW
LAoMCgUGAAIEAxIDYg8mCg0KBQYAAgQEEgRjBGYGChEKCQYAAgQEsMq8IhIEYwRmBgoMCgUG
AAIEBBIDZwQ0Cg8KCAYAAgQEmwgAEgNnBDQKUwoEBgACBRIEawJxAxpFIExvY2sgdGhlIGRv
Y3VtZW50IHNvIHRoZSBkb2N1bWVudCBjYW5ub3QgYmUgdXBkYXRlZCBieSBvdGhlciB1c2Vy
cy4KCgwKBQYAAgUBEgNrBhIKDAoFBgACBQISA2sTJgoMCgUGAAIFAxIDazE5Cg0KBQYAAgUE
EgRsBG8GChEKCQYAAgUEsMq8IhIEbARvBgoMCgUGAAIFBBIDcAQyCg8KCAYAAgUEmwgAEgNw
BDIKyQEKBAYAAgYSBXYCgAEDGrkBIEdldHMgdGhlIGFjY2VzcyBjb250cm9sIHBvbGljeSBm
b3IgYSByZXNvdXJjZS4gUmV0dXJucyBOT1RfRk9VTkQgZXJyb3IgaWYKIHRoZSByZXNvdXJj
ZSBkb2VzIG5vdCBleGlzdC4gUmV0dXJucyBhbiBlbXB0eSBwb2xpY3kgaWYgdGhlIHJlc291
cmNlIGV4aXN0cwogYnV0IGRvZXMgbm90IGhhdmUgYSBwb2xpY3kgc2V0LgoKDAoFBgACBgES
A3YGDgoMCgUGAAIGAhIDdg8eCgwKBQYAAgYDEgN2KTkKDQoFBgACBgQSBHcEfgYKEQoJBgAC
BgSwyrwiEgR3BH4GCgwKBQYAAgYEEgN/BDYKDwoIBgACBgSbCAASA38ENgpfCgQGAAIHEgaE
AQKLAQMaTyBTZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9yIGEgcmVzb3VyY2Uu
IFJlcGxhY2VzIGFueSBleGlzdGluZwogcG9saWN5LgoKDQoFBgACBwESBIQBBgwKDQoFBgAC
BwISBIQBDRoKDQoFBgACBwMSBIQBJTMKDwoFBgACBwQSBoUBBIkBBgoTCgkGAAIHBLDKvCIS
BoUBBIkBBgoNCgUGAAIHBBIEigEEPQoQCggGAAIHBJsIABIEigEEPQpECgIEABIGjwEAnwEB
GjYgUmVzcG9uc2UgbWVzc2FnZSBmb3IgRG9jdW1lbnRTZXJ2aWNlLkNyZWF0ZURvY3VtZW50
LgoKCwoDBAABEgSPAQgeCkAKBAQAAgASBJEBAhgaMiBEb2N1bWVudCBjcmVhdGVkIGFmdGVy
IGV4ZWN1dGluZyBjcmVhdGUgcmVxdWVzdC4KCg0KBQQAAgAGEgSRAQIKCg0KBQQAAgABEgSR
AQsTCg0KBQQAAgADEgSRARYXCqoBCgQEAAIBEgSXAQIqGpsBIE91dHB1dCBmcm9tIFJ1bGUg
RW5naW5lIHJlY29yZGluZyB0aGUgcnVsZSBldmFsdWF0b3IgYW5kIGFjdGlvbiBleGVjdXRv
cidzCiBvdXRwdXQuCgogUmVmZXIgZm9ybWF0IGluOiBnb29nbGUvY2xvdWQvY29udGVudHdh
cmVob3VzZS92MS9ydWxlX2VuZ2luZS5wcm90bwoKDQoFBAACAQYSBJcBAhIKDQoFBAACAQES
BJcBEyUKDQoFBAACAQMSBJcBKCkKYAoEBAACAhIEmwECIBpSIEFkZGl0aW9uYWwgaW5mb3Jt
YXRpb24gZm9yIHRoZSBBUEkgaW52b2NhdGlvbiwgc3VjaCBhcyB0aGUgcmVxdWVzdCB0cmFj
a2luZwogaWQuCgoNCgUEAAICBhIEmwECEgoNCgUEAAICARIEmwETGwoNCgUEAAICAxIEmwEe
HwokCgQEAAIDEgSeAQJEGhYgcG9zdC1wcm9jZXNzaW5nIExST3MKCg0KBQQAAgMEEgSeAQIK
Cg0KBQQAAgMGEgSeAQsnCg0KBQQAAgMBEgSeASg/Cg0KBQQAAgMDEgSeAUJDCkQKAgQBEgai
AQCvAQEaNiBSZXNwb25zZSBtZXNzYWdlIGZvciBEb2N1bWVudFNlcnZpY2UuVXBkYXRlRG9j
dW1lbnQuCgoLCgMEAQESBKIBCB4KQAoEBAECABIEpAECGBoyIFVwZGF0ZWQgZG9jdW1lbnQg
YWZ0ZXIgZXhlY3V0aW5nIHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAECAAYSBKQBAgoKDQoFBAEC
AAESBKQBCxMKDQoFBAECAAMSBKQBFhcKqgEKBAQBAgESBKoBAioamwEgT3V0cHV0IGZyb20g
UnVsZSBFbmdpbmUgcmVjb3JkaW5nIHRoZSBydWxlIGV2YWx1YXRvciBhbmQgYWN0aW9uIGV4
ZWN1dG9yJ3MKIG91dHB1dC4KCiBSZWZlciBmb3JtYXQgaW46IGdvb2dsZS9jbG91ZC9jb250
ZW50d2FyZWhvdXNlL3YxL3J1bGVfZW5naW5lLnByb3RvCgoNCgUEAQIBBhIEqgECEgoNCgUE
AQIBARIEqgETJQoNCgUEAQIBAxIEqgEoKQpgCgQEAQICEgSuAQIgGlIgQWRkaXRpb25hbCBp
bmZvcm1hdGlvbiBmb3IgdGhlIEFQSSBpbnZvY2F0aW9uLCBzdWNoIGFzIHRoZSByZXF1ZXN0
IHRyYWNraW5nCiBpZC4KCg0KBQQBAgIGEgSuAQISCg0KBQQBAgIBEgSuARMbCg0KBQQBAgID
EgSuAR4fCkoKAgQCEgayAQDEAQEaPCBBZGRpdGlvbmFsIHJlc3VsdCBpbmZvIGZvciB0aGUg
cXVlc3Rpb24tYW5zd2VyaW5nIGZlYXR1cmUuCgoLCgMEAgESBLIBCBAKkgEKBAQCAwASBrUB
ArsBAxqBASBBIHRleHQgc3BhbiBpbiB0aGUgc2VhcmNoIHRleHQgc25pcHBldCB0aGF0IHJl
cHJlc2VudHMgYSBoaWdobGlnaHRlZAogc2VjdGlvbiAoYW5zd2VyIGNvbnRleHQsIGhpZ2hs
eSByZWxldmFudCBzZW50ZW5jZSwgZXRjLikuCgoNCgUEAgMAARIEtQEKEwovCgYEAgMAAgAS
BLcBBBoaHyBTdGFydCBpbmRleCBvZiB0aGUgaGlnaGxpZ2h0LgoKDwoHBAIDAAIABRIEtwEE
CQoPCgcEAgMAAgABEgS3AQoVCg8KBwQCAwACAAMSBLcBGBkKOAoGBAIDAAIBEgS6AQQYGigg
RW5kIGluZGV4IG9mIHRoZSBoaWdobGlnaHQsIGV4Y2x1c2l2ZS4KCg8KBwQCAwACAQUSBLoB
BAkKDwoHBAIDAAIBARIEugEKEwoPCgcEAgMAAgEDEgS6ARYXCjQKBAQCAgASBL4BAiQaJiBI
aWdobGlnaHRlZCBzZWN0aW9ucyBpbiB0aGUgc25pcHBldC4KCg0KBQQCAgAEEgS+AQIKCg0K
BQQCAgAGEgS+AQsUCg0KBQQCAgABEgS+ARUfCg0KBQQCAgADEgS+ASIjCskBCgQEAgIBEgTD
AQIdGroBIFRoZSBjYWxpYnJhdGVkIGNvbmZpZGVuY2Ugc2NvcmUgZm9yIHRoaXMgZG9jdW1l
bnQsIGluIHRoZSByYW5nZQogWzAuLCAxLl0uIFRoaXMgcmVwcmVzZW50cyB0aGUgY29uZmlk
ZW5jZSBsZXZlbCBmb3Igd2hldGhlciB0aGUgcmV0dXJuZWQKIGRvY3VtZW50IGFuZCBzbmlw
cGV0IGFuc3dlcnMgdGhlIHVzZXIncyBxdWVyeS4KCg0KBQQCAgEFEgTDAQIHCg0KBQQCAgEB
EgTDAQgYCg0KBQQCAgEDEgTDARscCkUKAgQDEgbHAQCCAgEaNyBSZXNwb25zZSBtZXNzYWdl
IGZvciBEb2N1bWVudFNlcnZpY2UuU2VhcmNoRG9jdW1lbnRzLgoKCwoDBAMBEgTHAQgfCooB
CgQEAwMAEgbKAQLjAQMaeiBEb2N1bWVudCBlbnRyeSB3aXRoIG1ldGFkYXRhIGluc2lkZQog
W1NlYXJjaERvY3VtZW50c1Jlc3BvbnNlXVtnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3Vz
ZS52MS5TZWFyY2hEb2N1bWVudHNSZXNwb25zZV0KCg0KBQQDAwABEgTKAQoaCsUBCgYEAwMA
AgASBM4BBBoatAEgRG9jdW1lbnQgdGhhdCBtYXRjaGVzIHRoZSBzcGVjaWZpZWQKIFtTZWFy
Y2hEb2N1bWVudHNSZXF1ZXN0XVtnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5T
ZWFyY2hEb2N1bWVudHNSZXF1ZXN0XS4KIFRoaXMgZG9jdW1lbnQgb25seSBjb250YWlucyBp
bmRleGVkIG1ldGFkYXRhIGluZm9ybWF0aW9uLgoKDwoHBAMDAAIABhIEzgEEDAoPCgcEAwMA
AgABEgTOAQ0VCg8KBwQDAwACAAMSBM4BGBkKzgQKBgQDAwACARIE2gEEIxq9BCBDb250YWlu
cyBzbmlwcGV0cyBvZiB0ZXh0IGZyb20gdGhlIGRvY3VtZW50IGZ1bGwgcmF3IHRleHQgdGhh
dCBtb3N0CiBjbG9zZWx5IG1hdGNoIGEgc2VhcmNoIHF1ZXJ5J3Mga2V5d29yZHMsIGlmIGF2
YWlsYWJsZS4gQWxsIEhUTUwgdGFncyBpbgogdGhlIG9yaWdpbmFsIGZpZWxkcyBhcmUgc3Ry
aXBwZWQgd2hlbiByZXR1cm5lZCBpbiB0aGlzIGZpZWxkLCBhbmQKIG1hdGNoaW5nIHF1ZXJ5
IGtleXdvcmRzIGFyZSBlbmNsb3NlZCBpbiBIVE1MIGJvbGQgdGFncy4KCiBJZiB0aGUgcXVl
c3Rpb24tYW5zd2VyaW5nIGZlYXR1cmUgaXMgZW5hYmxlZCwgdGhpcyBmaWVsZCB3aWxsIGlu
c3RlYWQKIGNvbnRhaW4gYSBzbmlwcGV0IHRoYXQgYW5zd2VycyB0aGUgdXNlcidzIG5hdHVy
YWwtbGFuZ3VhZ2UgcXVlcnkuIE5vIEhUTUwKIGJvbGQgdGFncyB3aWxsIGJlIHByZXNlbnQs
IGFuZCBoaWdobGlnaHRzIGluIHRoZSBhbnN3ZXIgc25pcHBldCBjYW4gYmUKIGZvdW5kIGlu
CiBbUUFSZXN1bHQuaGlnaGxpZ2h0c11bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuUUFSZXN1bHQuaGlnaGxpZ2h0c10uCgoPCgcEAwMAAgEFEgTaAQQKCg8KBwQDAwACAQES
BNoBCx4KDwoHBAMDAAIBAxIE2gEhIgplCgYEAwMAAgISBN4BBBsaVSBFeHBlcmltZW50YWwu
CiBBZGRpdGlvbmFsIHJlc3VsdCBpbmZvIGlmIHRoZSBxdWVzdGlvbi1hbnN3ZXJpbmcgZmVh
dHVyZSBpcyBlbmFibGVkLgoKDwoHBAMDAAICBhIE3gEEDAoPCgcEAwMAAgIBEgTeAQ0WCg8K
BwQDAwACAgMSBN4BGRoKZQoGBAMDAAIDEgTiAQQyGlUgUmV0dXJuIHRoZSAxLWJhc2VkIHBh
Z2UgaW5kaWNlcyB3aGVyZSB0aG9zZSBwYWdlcyBoYXZlIG9uZSBvciBtb3JlCiBtYXRjaGVk
IHRva2Vucy4KCg8KBwQDAwACAwQSBOIBBAwKDwoHBAMDAAIDBRIE4gENEgoPCgcEAwMAAgMB
EgTiARMtCg8KBwQDAwACAwMSBOIBMDEKkwEKBAQDAgASBOcBAjMahAEgVGhlIGRvY3VtZW50
IGVudGl0aWVzIHRoYXQgbWF0Y2ggdGhlIHNwZWNpZmllZAogW1NlYXJjaERvY3VtZW50c1Jl
cXVlc3RdW2dvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNlYXJjaERvY3VtZW50
c1JlcXVlc3RdLgoKDQoFBAMCAAQSBOcBAgoKDQoFBAMCAAYSBOcBCxsKDQoFBAMCAAESBOcB
HC4KDQoFBAMCAAMSBOcBMTIKjwEKBAQDAgESBOsBAh0agAEgVGhlIHRva2VuIHRoYXQgc3Bl
Y2lmaWVzIHRoZSBzdGFydGluZyBwb3NpdGlvbiBvZiB0aGUgbmV4dCBwYWdlIG9mIHJlc3Vs
dHMuCiBUaGlzIGZpZWxkIGlzIGVtcHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlIHJlc3VsdHMu
CgoNCgUEAwIBBRIE6wECCAoNCgUEAwIBARIE6wEJGAoNCgUEAwIBAxIE6wEbHAqtBAoEBAMC
AhIE9QECFxqeBCBUaGUgdG90YWwgbnVtYmVyIG9mIG1hdGNoZWQgZG9jdW1lbnRzIHdoaWNo
IGlzIGF2YWlsYWJsZSBvbmx5IGlmIHRoZSBjbGllbnQKIHNldAogW1NlYXJjaERvY3VtZW50
c1JlcXVlc3QucmVxdWlyZV90b3RhbF9zaXplXVtnb29nbGUuY2xvdWQuY29udGVudHdhcmVo
b3VzZS52MS5TZWFyY2hEb2N1bWVudHNSZXF1ZXN0LnJlcXVpcmVfdG90YWxfc2l6ZV0KIHRv
IGB0cnVlYCBvciBzZXQKIFtTZWFyY2hEb2N1bWVudHNSZXF1ZXN0LnRvdGFsX3Jlc3VsdF9z
aXplXVtnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5TZWFyY2hEb2N1bWVudHNS
ZXF1ZXN0LnRvdGFsX3Jlc3VsdF9zaXplXQogdG8gYEVTVElNQVRFRF9TSVpFYCBvciBgQUNU
VUFMX1NJWkVgLiBPdGhlcndpc2UsIHRoZSB2YWx1ZSB3aWxsIGJlIGAtMWAuCiBUeXBpY2Fs
bHkgYSBVSSB3b3VsZCBoYW5kbGUgdGhpcyBjb25kaXRpb24gYnkgZGlzcGxheWluZyAmcXVv
dDtvZgogbWFueSZxdW90OywgZm9yIGV4YW1wbGU6ICZxdW90O0Rpc3BsYXlpbmcgMTAgb2Yg
bWFueSZxdW90Oy4KCg0KBQQDAgIFEgT1AQIHCg0KBQQDAgIBEgT1AQgSCg0KBQQDAgIDEgT1
ARUWCmAKBAQDAgMSBPkBAiAaUiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGZvciB0aGUgQVBJ
IGludm9jYXRpb24sIHN1Y2ggYXMgdGhlIHJlcXVlc3QgdHJhY2tpbmcKIGlkLgoKDQoFBAMC
AwYSBPkBAhIKDQoFBAMCAwESBPkBExsKDQoFBAMCAwMSBPkBHh8KvAEKBAQDAgQSBP0BAjwa
rQEgVGhlIGhpc3RvZ3JhbSByZXN1bHRzIHRoYXQgbWF0Y2ggd2l0aCB0aGUgc3BlY2lmaWVk
CiBbU2VhcmNoRG9jdW1lbnRzUmVxdWVzdC5oaXN0b2dyYW1fcXVlcmllc11bZ29vZ2xlLmNs
b3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU2VhcmNoRG9jdW1lbnRzUmVxdWVzdC5oaXN0b2dy
YW1fcXVlcmllc10uCgoNCgUEAwIEBBIE/QECCgoNCgUEAwIEBhIE/QELHwoNCgUEAwIEARIE
/QEgNwoNCgUEAwIEAxIE/QE6OwpTCgQEAwIFEgSBAgIdGkUgRXhwZXJpbWVudGFsLgogUXVl
c3Rpb24gYW5zd2VyIGZyb20gdGhlIHF1ZXJ5IGFnYWluc3QgdGhlIGRvY3VtZW50LgoKDQoF
BAMCBQUSBIECAggKDQoFBAMCBQESBIECCRgKDQoFBAMCBQMSBIECGxwKPgoCBAQSBoUCAIwC
ARowIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIERvY3VtZW50U2VydmljZS5GZXRjaEFjbC4KCgsK
AwQEARIEhQIIGAofCgQEBAIAEgSHAgIiGhEgVGhlIElBTSBwb2xpY3kuCgoNCgUEBAIABhIE
hwICFgoNCgUEBAIAARIEhwIXHQoNCgUEBAIAAxIEhwIgIQpgCgQEBAIBEgSLAgIgGlIgQWRk
aXRpb25hbCBpbmZvcm1hdGlvbiBmb3IgdGhlIEFQSSBpbnZvY2F0aW9uLCBzdWNoIGFzIHRo
ZSByZXF1ZXN0IHRyYWNraW5nCiBpZC4KCg0KBQQEAgEGEgSLAgISCg0KBQQEAgEBEgSLAhMb
Cg0KBQQEAgEDEgSLAh4fCjwKAgQFEgaPAgCWAgEaLiBSZXNwb25zZSBtZXNzYWdlIGZvciBE
b2N1bWVudFNlcnZpY2UuU2V0QWNsLgoKCwoDBAUBEgSPAggWClQKBAQFAgASBJECAiIaRiBU
aGUgcG9saWN5IHdpbGwgYmUgYXR0YWNoZWQgdG8gYSByZXNvdXJjZSAoZS5nLiBwcm9qZWNj
dCwgZG9jdW1lbnQpLgoKDQoFBAUCAAYSBJECAhYKDQoFBAUCAAESBJECFx0KDQoFBAUCAAMS
BJECICEKYAoEBAUCARIElQICIBpSIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZm9yIHRoZSBB
UEkgaW52b2NhdGlvbiwgc3VjaCBhcyB0aGUgcmVxdWVzdCB0cmFja2luZwogaWQuCgoNCgUE
BQIBBhIElQICEgoNCgUEBQIBARIElQITGwoNCgUEBQIBAxIElQIeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse ===
    # Fields for CreateDocumentResponse
    # Field: document Type: 11 (.google.cloud.contentwarehouse.v1.Document)
    # Field: rule_engine_output Type: 11 (.google.cloud.contentwarehouse.v1.RuleEngineOutput)
    # Field: metadata Type: 11 (.google.cloud.contentwarehouse.v1.ResponseMetadata)
    # Field: long_running_operations Type: 11 (.google.longrunning.Operation)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse ===
    # Fields for UpdateDocumentResponse
    # Field: document Type: 11 (.google.cloud.contentwarehouse.v1.Document)
    # Field: rule_engine_output Type: 11 (.google.cloud.contentwarehouse.v1.RuleEngineOutput)
    # Field: metadata Type: 11 (.google.cloud.contentwarehouse.v1.ResponseMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult ===
    # Fields for QAResult
    # Field: highlights Type: 11 (.google.cloud.contentwarehouse.v1.QAResult.Highlight)
    # Field: confidence_score Type: 2 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse ===
    # Fields for SearchDocumentsResponse
    # Field: matching_documents Type: 11 (.google.cloud.contentwarehouse.v1.SearchDocumentsResponse.MatchingDocument)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()
    # Field: metadata Type: 11 (.google.cloud.contentwarehouse.v1.ResponseMetadata)
    # Field: histogram_query_results Type: 11 (.google.cloud.contentwarehouse.v1.HistogramQueryResult)
    # Field: question_answer Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse ===
    # Fields for FetchAclResponse
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: metadata Type: 11 (.google.cloud.contentwarehouse.v1.ResponseMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse ===
    # Fields for SetAclResponse
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: metadata Type: 11 (.google.cloud.contentwarehouse.v1.ResponseMetadata)

# === Service Client: Google::Cloud::Contentwarehouse::V1::DocumentService::DocumentServiceClient ===
package Google::Cloud::Contentwarehouse::V1::DocumentService::DocumentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::DocumentService::DocumentServiceClient

Client stub representing the remote C<DocumentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<contentwarehouse.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'contentwarehouse.googleapis.com:443' );

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

sub create_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'CreateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse',
    });
}

sub get_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'GetDocument',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::Document::Document',
    });
}

sub update_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'UpdateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse',
    });
}

sub delete_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'DeleteDocument',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub search_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'SearchDocuments',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse',
    });
}

sub lock_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'LockDocument',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::Document::Document',
    });
}

sub fetch_acl {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'FetchAcl',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse',
    });
}

sub set_acl {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentService',
        method         => 'SetAcl',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentService;

    my $msg = Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse->new({
        document => $document,
        rule_engine_output => $rule_engine_output,
        metadata => $metadata,
        long_running_operations => $long_running_operations,
    });

    # Read or update a field
    my $val = $msg->document();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse

Response message for DocumentService.CreateDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Document>)

Document created after executing create request.

=item * C<< $msg->rule_engine_output() >> / C<< $msg->rule_engine_output($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput>)

Output from Rule Engine recording the rule evaluator and action executor's
output.

Refer format in: google/cloud/contentwarehouse/v1/rule_engine.proto

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request tracking
id.

=item * C<< $msg->long_running_operations() >> / C<< $msg->long_running_operations($value) >>

Type: C<Message> (L<Google::Longrunning::Operations::Operation>)

post-processing LROs

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse

Response message for DocumentService.UpdateDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Document>)

Updated document after executing update request.

=item * C<< $msg->rule_engine_output() >> / C<< $msg->rule_engine_output($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput>)

Output from Rule Engine recording the rule evaluator and action executor's
output.

Refer format in: google/cloud/contentwarehouse/v1/rule_engine.proto

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request tracking
id.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult

Additional result info for the question-answering feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->highlights() >> / C<< $msg->highlights($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult::Highlight>)

Highlighted sections in the snippet.

=item * C<< $msg->confidence_score() >> / C<< $msg->confidence_score($value) >>

Type: C<Float>

The calibrated confidence score for this document, in the range
[0., 1.]. This represents the confidence level for whether the returned
document and snippet answers the user's query.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse

Response message for DocumentService.SearchDocuments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_documents() >> / C<< $msg->matching_documents($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse::MatchingDocument>)

The document entities that match the specified
[SearchDocumentsRequest][google.cloud.contentwarehouse.v1.SearchDocumentsRequest].

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token that specifies the starting position of the next page of results.
This field is empty if there are no more results.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of matched documents which is available only if the client
set
[SearchDocumentsRequest.require_total_size][google.cloud.contentwarehouse.v1.SearchDocumentsRequest.require_total_size]
to `true` or set
[SearchDocumentsRequest.total_result_size][google.cloud.contentwarehouse.v1.SearchDocumentsRequest.total_result_size]
to `ESTIMATED_SIZE` or `ACTUAL_SIZE`. Otherwise, the value will be `-1`.
Typically a UI would handle this condition by displaying &quot;of
many&quot;, for example: &quot;Displaying 10 of many&quot;.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request tracking
id.

=item * C<< $msg->histogram_query_results() >> / C<< $msg->histogram_query_results($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryResult>)

The histogram results that match with the specified
[SearchDocumentsRequest.histogram_queries][google.cloud.contentwarehouse.v1.SearchDocumentsRequest.histogram_queries].

=item * C<< $msg->question_answer() >> / C<< $msg->question_answer($value) >>

Type: C<String>

Experimental.
Question answer from the query against the document.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse

Response message for DocumentService.FetchAcl.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

The IAM policy.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request tracking
id.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse

Response message for DocumentService.SetAcl.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

The policy will be attached to a resource (e.g. projecct, document).

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request tracking
id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::DocumentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
