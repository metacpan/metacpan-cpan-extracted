package Google::Cloud::Dialogflow::Cx::V3::SecuritySettings;

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
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9zZWN1cml0eV9zZXR0aW5ncy5wcm90
bxIdZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9i
dWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvImQKGkdl
dFNlY3VyaXR5U2V0dGluZ3NSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbS9TZWN1cml0eVNldHRpbmdzUgRuYW1lIsQBCh1VcGRhdGVT
ZWN1cml0eVNldHRpbmdzUmVxdWVzdBJhChFzZWN1cml0eV9zZXR0aW5ncxgBIAEoCzIvLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlY3VyaXR5U2V0dGluZ3NCA+BBAlIQc2Vj
dXJpdHlTZXR0aW5ncxJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzayKlAQobTGlzdFNlY3VyaXR5U2V0dGluZ3NSZXF1
ZXN0EkoKBnBhcmVudBgBIAEoCUIy4EEC+kEsEipkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t
L1NlY3VyaXR5U2V0dGluZ3NSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXpl
Eh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKkAQocTGlzdFNlY3VyaXR5U2V0dGlu
Z3NSZXNwb25zZRJcChFzZWN1cml0eV9zZXR0aW5ncxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLlNlY3VyaXR5U2V0dGluZ3NSEHNlY3VyaXR5U2V0dGluZ3MSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIs4BCh1DcmVhdGVTZWN1cml0
eVNldHRpbmdzUmVxdWVzdBJKCgZwYXJlbnQYASABKAlCMuBBAvpBLBIqZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9TZWN1cml0eVNldHRpbmdzUgZwYXJlbnQSYQoRc2VjdXJpdHlfc2V0
dGluZ3MYAiABKAsyLy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNl
dHRpbmdzQgPgQQJSEHNlY3VyaXR5U2V0dGluZ3MiZwodRGVsZXRlU2VjdXJpdHlTZXR0aW5n
c1JlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipkaWFsb2dmbG93Lmdvb2dsZWFwaXMu
Y29tL1NlY3VyaXR5U2V0dGluZ3NSBG5hbWUijw8KEFNlY3VyaXR5U2V0dGluZ3MSEgoEbmFt
ZRgBIAEoCVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUS
cAoScmVkYWN0aW9uX3N0cmF0ZWd5GAMgASgOMkEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjMuU2VjdXJpdHlTZXR0aW5ncy5SZWRhY3Rpb25TdHJhdGVneVIRcmVkYWN0aW9uU3Ry
YXRlZ3kSZwoPcmVkYWN0aW9uX3Njb3BlGAQgASgOMj4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuU2VjdXJpdHlTZXR0aW5ncy5SZWRhY3Rpb25TY29wZVIOcmVkYWN0aW9uU2Nv
cGUSUgoQaW5zcGVjdF90ZW1wbGF0ZRgJIAEoCUIn+kEkCiJkbHAuZ29vZ2xlYXBpcy5jb20v
SW5zcGVjdFRlbXBsYXRlUg9pbnNwZWN0VGVtcGxhdGUSWwoTZGVpZGVudGlmeV90ZW1wbGF0
ZRgRIAEoCUIq+kEnCiVkbHAuZ29vZ2xlYXBpcy5jb20vRGVpZGVudGlmeVRlbXBsYXRlUhJk
ZWlkZW50aWZ5VGVtcGxhdGUSNAoVcmV0ZW50aW9uX3dpbmRvd19kYXlzGAYgASgFSABSE3Jl
dGVudGlvbldpbmRvd0RheXMScgoScmV0ZW50aW9uX3N0cmF0ZWd5GAcgASgOMkEuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5ncy5SZXRlbnRpb25TdHJh
dGVneUgAUhFyZXRlbnRpb25TdHJhdGVneRJnChBwdXJnZV9kYXRhX3R5cGVzGAggAygOMj0u
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5ncy5QdXJnZURh
dGFUeXBlUg5wdXJnZURhdGFUeXBlcxJ3ChVhdWRpb19leHBvcnRfc2V0dGluZ3MYDCABKAsy
Qy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNldHRpbmdzLkF1ZGlv
RXhwb3J0U2V0dGluZ3NSE2F1ZGlvRXhwb3J0U2V0dGluZ3MSgAEKGGluc2lnaHRzX2V4cG9y
dF9zZXR0aW5ncxgNIAEoCzJGLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlY3Vy
aXR5U2V0dGluZ3MuSW5zaWdodHNFeHBvcnRTZXR0aW5nc1IWaW5zaWdodHNFeHBvcnRTZXR0
aW5ncxqCAwoTQXVkaW9FeHBvcnRTZXR0aW5ncxIdCgpnY3NfYnVja2V0GAEgASgJUglnY3NC
dWNrZXQSMAoUYXVkaW9fZXhwb3J0X3BhdHRlcm4YAiABKAlSEmF1ZGlvRXhwb3J0UGF0dGVy
bhI0ChZlbmFibGVfYXVkaW9fcmVkYWN0aW9uGAMgASgIUhRlbmFibGVBdWRpb1JlZGFjdGlv
bhJyCgxhdWRpb19mb3JtYXQYBCABKA4yTy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
My5TZWN1cml0eVNldHRpbmdzLkF1ZGlvRXhwb3J0U2V0dGluZ3MuQXVkaW9Gb3JtYXRSC2F1
ZGlvRm9ybWF0EiYKD3N0b3JlX3R0c19hdWRpbxgGIAEoCFINc3RvcmVUdHNBdWRpbyJICgtB
dWRpb0Zvcm1hdBIcChhBVURJT19GT1JNQVRfVU5TUEVDSUZJRUQQABIJCgVNVUxBVxABEgcK
A01QMxACEgcKA09HRxADGk4KFkluc2lnaHRzRXhwb3J0U2V0dGluZ3MSNAoWZW5hYmxlX2lu
c2lnaHRzX2V4cG9ydBgBIAEoCFIUZW5hYmxlSW5zaWdodHNFeHBvcnQiUAoRUmVkYWN0aW9u
U3RyYXRlZ3kSIgoeUkVEQUNUSU9OX1NUUkFURUdZX1VOU1BFQ0lGSUVEEAASFwoTUkVEQUNU
X1dJVEhfU0VSVklDRRABIkoKDlJlZGFjdGlvblNjb3BlEh8KG1JFREFDVElPTl9TQ09QRV9V
TlNQRUNJRklFRBAAEhcKE1JFREFDVF9ESVNLX1NUT1JBR0UQAiJWChFSZXRlbnRpb25TdHJh
dGVneRIiCh5SRVRFTlRJT05fU1RSQVRFR1lfVU5TUEVDSUZJRUQQABIdChlSRU1PVkVfQUZU
RVJfQ09OVkVSU0FUSU9OEAEiSAoNUHVyZ2VEYXRhVHlwZRIfChtQVVJHRV9EQVRBX1RZUEVf
VU5TUEVDSUZJRUQQABIWChJESUFMT0dGTE9XX0hJU1RPUlkQATp96kF6CipkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1NlY3VyaXR5U2V0dGluZ3MSTHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9zZWN1cml0eVNldHRpbmdzL3tzZWN1cml0eV9zZXR0aW5n
c31CEAoOZGF0YV9yZXRlbnRpb24y7wkKF1NlY3VyaXR5U2V0dGluZ3NTZXJ2aWNlEvMBChZD
cmVhdGVTZWN1cml0eVNldHRpbmdzEjwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMu
Q3JlYXRlU2VjdXJpdHlTZXR0aW5nc1JlcXVlc3QaLy5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5TZWN1cml0eVNldHRpbmdzImqC0+STAkkiNC92My97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L3NlY3VyaXR5U2V0dGluZ3M6EXNlY3VyaXR5X3NldHRpbmdz2kEY
cGFyZW50LHNlY3VyaXR5X3NldHRpbmdzEsYBChNHZXRTZWN1cml0eVNldHRpbmdzEjkuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2V0U2VjdXJpdHlTZXR0aW5nc1JlcXVlc3Qa
Ly5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNldHRpbmdzIkOC0+ST
AjYSNC92My97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NlY3VyaXR5U2V0dGluZ3Mv
Kn3aQQRuYW1lEosCChZVcGRhdGVTZWN1cml0eVNldHRpbmdzEjwuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuVXBkYXRlU2VjdXJpdHlTZXR0aW5nc1JlcXVlc3QaLy5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNldHRpbmdzIoEBgtPkkwJbMkYvdjMv
e3NlY3VyaXR5X3NldHRpbmdzLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZWN1cml0
eVNldHRpbmdzLyp9OhFzZWN1cml0eV9zZXR0aW5nc9pBHXNlY3VyaXR5X3NldHRpbmdzLHVw
ZGF0ZV9tYXNrEtYBChRMaXN0U2VjdXJpdHlTZXR0aW5ncxI6Lmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLkxpc3RTZWN1cml0eVNldHRpbmdzUmVxdWVzdBo7Lmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLkxpc3RTZWN1cml0eVNldHRpbmdzUmVzcG9uc2UiRYLT5JMC
NhI0L3YzL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc2VjdXJpdHlTZXR0aW5n
c9pBBnBhcmVudBKzAQoWRGVsZXRlU2VjdXJpdHlTZXR0aW5ncxI8Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLkRlbGV0ZVNlY3VyaXR5U2V0dGluZ3NSZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IkOC0+STAjYqNC92My97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3NlY3VyaXR5U2V0dGluZ3MvKn3aQQRuYW1lGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dC3wQKIWNvbS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M0IVU2VjdXJpdHlTZXR0aW5nc1Byb3RvUAFa
MWNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2My9jeHBiO2N4cGKiAgJE
RqoCHUdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LkN4LlYz6gIhR29vZ2xlOjpDbG91ZDo6RGlh
bG9nZmxvdzo6Q1g6OlYz6kHIAQoiZGxwLmdvb2dsZWFwaXMuY29tL0luc3BlY3RUZW1wbGF0
ZRJVb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9p
bnNwZWN0VGVtcGxhdGVzL3tpbnNwZWN0X3RlbXBsYXRlfRJLcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3BlY3RUZW1wbGF0ZXMve2luc3BlY3RfdGVtcGxh
dGV96kHXAQolZGxwLmdvb2dsZWFwaXMuY29tL0RlaWRlbnRpZnlUZW1wbGF0ZRJbb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kZWlkZW50aWZ5
VGVtcGxhdGVzL3tkZWlkZW50aWZ5X3RlbXBsYXRlfRJRcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2RlaWRlbnRpZnlUZW1wbGF0ZXMve2RlaWRlbnRpZnlfdGVt
cGxhdGV9StlqCgcSBQ4AlQMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
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
CAoBAhIDEAAmCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CQoCAwQSAxYAJQoJCgIDBRIDFwAqCggKAQgSAxkAOgoJCgIIJRIDGQA6CggKAQgSAxoASAoJ
CgIICxIDGgBICggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANgoJCgIICBIDHAA2CggK
AQgSAx0AOgoJCgIIARIDHQA6CggKAQgSAx4AIAoJCgIIJBIDHgAgCggKAQgSAx8AOgoJCgII
LRIDHwA6CgkKAQgSBCAAJAIKDAoECJ0IABIEIAAkAgoJCgEIEgQlACkCCgwKBAidCAESBCUA
KQIKRAoCBgASBCwAZAEaOCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBzZWN1cml0eSBzZXR0aW5n
cyBmb3IgRGlhbG9nZmxvdy4KCgoKAwYAARIDLAgfCgoKAwYAAxIDLQJBCgwKBQYAA5kIEgMt
AkEKCwoDBgADEgQuAjAzCg0KBQYAA5oIEgQuAjAzCkMKBAYAAgASBDMCOgMaNSBDcmVhdGUg
c2VjdXJpdHkgc2V0dGluZ3MgaW4gdGhlIHNwZWNpZmllZCBsb2NhdGlvbi4KCgwKBQYAAgAB
EgMzBhwKDAoFBgACAAISAzMdOgoMCgUGAAIAAxIDNA8fCg0KBQYAAgAEEgQ1BDgGChEKCQYA
AgAEsMq8IhIENQQ4BgoMCgUGAAIABBIDOQRGCg8KCAYAAgAEmwgAEgM5BEYKpAEKBAYAAgES
BD8CRQMalQEgUmV0cmlldmVzIHRoZSBzcGVjaWZpZWQKIFtTZWN1cml0eVNldHRpbmdzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNldHRpbmdzXS4gVGhlCiBy
ZXR1cm5lZCBzZXR0aW5ncyBtYXkgYmUgc3RhbGUgYnkgdXAgdG8gMSBtaW51dGUuCgoMCgUG
AAIBARIDPwYZCgwKBQYAAgECEgM/GjQKDAoFBgACAQMSA0APHwoNCgUGAAIBBBIEQQRDBgoR
CgkGAAIBBLDKvCISBEEEQwYKDAoFBgACAQQSA0QEMgoPCggGAAIBBJsIABIDRAQyCmoKBAYA
AgISBEkCUAMaXCBVcGRhdGVzIHRoZSBzcGVjaWZpZWQKIFtTZWN1cml0eVNldHRpbmdzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNldHRpbmdzXS4KCgwKBQYA
AgIBEgNJBhwKDAoFBgACAgISA0kdOgoMCgUGAAICAxIDSg8fCg0KBQYAAgIEEgRLBE4GChEK
CQYAAgIEsMq8IhIESwROBgoMCgUGAAICBBIDTwRLCg8KCAYAAgIEmwgAEgNPBEsKVAoEBgAC
AxIEUwJZAxpGIFJldHVybnMgdGhlIGxpc3Qgb2YgYWxsIHNlY3VyaXR5IHNldHRpbmdzIGlu
IHRoZSBzcGVjaWZpZWQgbG9jYXRpb24uCgoMCgUGAAIDARIDUwYaCgwKBQYAAgMCEgNTGzYK
DAoFBgACAwMSA1QPKwoNCgUGAAIDBBIEVQRXBgoRCgkGAAIDBLDKvCISBFUEVwYKDAoFBgAC
AwQSA1gENAoPCggGAAIDBJsIABIDWAQ0CmoKBAYAAgQSBF0CYwMaXCBEZWxldGVzIHRoZSBz
cGVjaWZpZWQKIFtTZWN1cml0eVNldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5TZWN1cml0eVNldHRpbmdzXS4KCgwKBQYAAgQBEgNdBhwKDAoFBgACBAISA10dOgoM
CgUGAAIEAxIDXg8kCg0KBQYAAgQEEgRfBGEGChEKCQYAAgQEsMq8IhIEXwRhBgoMCgUGAAIE
BBIDYgQyCg8KCAYAAgQEmwgAEgNiBDIKoQEKAgQAEgRoAHIBGpQBIFRoZSByZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbU2VjdXJpdHlTZXR0aW5nc1NlcnZpY2UuR2V0U2VjdXJpdHlTZXR0aW5n
c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5nc1NlcnZp
Y2UuR2V0U2VjdXJpdHlTZXR0aW5nc10uCgoKCgMEAAESA2gIIgqYAQoEBAACABIEbAJxBBqJ
ASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgc2V0dGluZ3MuCiBGb3JtYXQ6CiBg
cHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9zZWN1cml0eVNl
dHRpbmdzLzxzZWN1cml0eXNldHRpbmdzSUQ+YC4KCgwKBQQAAgAFEgNsAggKDAoFBAACAAES
A2wJDQoMCgUEAAIAAxIDbBARCg0KBQQAAgAIEgRsEnEDCg8KCAQAAgAInAgAEgNtBCoKDwoH
BAACAAifCBIEbgRwBQqoAQoCBAESBXYAgAEBGpoBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbU2VjdXJpdHlTZXR0aW5nc1NlcnZpY2UuVXBkYXRlU2VjdXJpdHlTZXR0aW5nc11bZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5nc1NlcnZpY2UuVXBk
YXRlU2VjdXJpdHlTZXR0aW5nc10uCgoKCgMEAQESA3YIJQprCgQEAQIAEgR5AnovGl0gUmVx
dWlyZWQuIFtTZWN1cml0eVNldHRpbmdzXSBvYmplY3QgdGhhdCBjb250YWlucyB2YWx1ZXMg
Zm9yIGVhY2ggb2YgdGhlCiBmaWVsZHMgdG8gdXBkYXRlLgoKDAoFBAECAAYSA3kCEgoMCgUE
AQIAARIDeRMkCgwKBQQBAgADEgN5JygKDAoFBAECAAgSA3oGLgoPCggEAQIACJwIABIDegct
CoABCgQEAQIBEgR+An8vGnIgUmVxdWlyZWQuIFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hpY2gg
ZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUgbWFzayBpcyBub3QKIHByZXNlbnQsIGFsbCBm
aWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDAoFBAECAQYSA34CGwoMCgUEAQIBARIDfhwnCgwK
BQQBAgEDEgN+KisKDAoFBAECAQgSA38GLgoPCggEAQIBCJwIABIDfwctClIKAgQCEgaDAQCT
AQEaRCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbU2VjdXJpdHlTZXR0aW5ncy5MaXN0U2Vj
dXJpdHlTZXR0aW5nc11bXS4KCgsKAwQCARIEgwEIIwqDAQoEBAICABIGhgECiwEEGnMgUmVx
dWlyZWQuIFRoZSBsb2NhdGlvbiB0byBsaXN0IGFsbCBzZWN1cml0eSBzZXR0aW5ncyBmb3Iu
CiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+
YC4KCg0KBQQCAgAFEgSGAQIICg0KBQQCAgABEgSGAQkPCg0KBQQCAgADEgSGARITCg8KBQQC
AgAIEgaGARSLAQMKEAoIBAICAAicCAASBIcBBCoKEQoHBAICAAifCBIGiAEEigEFCmcKBAQC
AgESBI8BAhYaWSBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEg
c2luZ2xlIHBhZ2UuIEJ5IGRlZmF1bHQgMjAgYW5kCiBhdCBtb3N0IDEwMC4KCg0KBQQCAgEF
EgSPAQIHCg0KBQQCAgEBEgSPAQgRCg0KBQQCAgEDEgSPARQVClAKBAQCAgISBJIBAhgaQiBU
aGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0
IHJlcXVlc3QuCgoNCgUEAgICBRIEkgECCAoNCgUEAgICARIEkgEJEwoNCgUEAgICAxIEkgEW
FwpTCgIEAxIGlgEAnQEBGkUgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIFtTZWN1cml0eVNl
dHRpbmdzLkxpc3RTZWN1cml0eVNldHRpbmdzXVtdLgoKCwoDBAMBEgSWAQgkCi4KBAQDAgAS
BJgBAjIaICBUaGUgbGlzdCBvZiBzZWN1cml0eSBzZXR0aW5ncy4KCg0KBQQDAgAEEgSYAQIK
Cg0KBQQDAgAGEgSYAQsbCg0KBQQDAgABEgSYARwtCg0KBQQDAgADEgSYATAxCm8KBAQDAgES
BJwBAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9y
IGVtcHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlCiByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoF
BAMCAQUSBJwBAggKDQoFBAMCAQESBJwBCRgKDQoFBAMCAQMSBJwBGxwKVAoCBAQSBqABAK4B
ARpGIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIFtTZWN1cml0eVNldHRpbmdzLkNyZWF0ZVNl
Y3VyaXR5U2V0dGluZ3NdW10uCgoLCgMEBAESBKABCCUKtwEKBAQEAgASBqQBAqkBBBqmASBS
ZXF1aXJlZC4gVGhlIGxvY2F0aW9uIHRvIGNyZWF0ZSBhbgogW1NlY3VyaXR5U2V0dGluZ3Nd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlY3VyaXR5U2V0dGluZ3NdIGZvci4K
IEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD5g
LgoKDQoFBAQCAAUSBKQBAggKDQoFBAQCAAESBKQBCQ8KDQoFBAQCAAMSBKQBEhMKDwoFBAQC
AAgSBqQBFKkBAwoQCggEBAIACJwIABIEpQEEKgoRCgcEBAIACJ8IEgamAQSoAQUKPAoEBAQC
ARIGrAECrQEvGiwgUmVxdWlyZWQuIFRoZSBzZWN1cml0eSBzZXR0aW5ncyB0byBjcmVhdGUu
CgoNCgUEBAIBBhIErAECEgoNCgUEBAIBARIErAETJAoNCgUEBAIBAxIErAEnKAoNCgUEBAIB
CBIErQEGLgoQCggEBAIBCJwIABIErQEHLQpUCgIEBRIGsQEAvAEBGkYgVGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IgW1NlY3VyaXR5U2V0dGluZ3MuRGVsZXRlU2VjdXJpdHlTZXR0aW5nc11b
XS4KCgsKAwQFARIEsQEIJQraAQoEBAUCABIGtgECuwEEGskBIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUKIFtTZWN1cml0eVNldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5TZWN1cml0eVNldHRpbmdzXSB0bwogZGVsZXRlLiBGb3JtYXQ6CiBgcHJvamVjdHMv
PFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9zZWN1cml0eVNldHRpbmdzLzxT
ZWN1cml0eVNldHRpbmdzSUQ+YC4KCg0KBQQFAgAFEgS2AQIICg0KBQQFAgABEgS2AQkNCg0K
BQQFAgADEgS2ARARCg8KBQQFAgAIEga2ARK7AQMKEAoIBAUCAAicCAASBLcBBCoKEQoHBAUC
AAifCBIGuAEEugEFCtsBCgIEBhIGwQEAlQMBGswBIFJlcHJlc2VudHMgdGhlIHNldHRpbmdz
IHJlbGF0ZWQgdG8gc2VjdXJpdHkgaXNzdWVzLCBzdWNoIGFzIGRhdGEgcmVkYWN0aW9uCiBh
bmQgZGF0YSByZXRlbnRpb24uIEl0IG1heSB0YWtlIGhvdXJzIGZvciB1cGRhdGVzIG9uIHRo
ZSBzZXR0aW5ncyB0bwogcHJvcGFnYXRlIHRvIGFsbCB0aGUgcmVsYXRlZCBjb21wb25lbnRz
IGFuZCB0YWtlIGVmZmVjdC4KCgsKAwQGARIEwQEIGAoNCgMEBgcSBsIBAsUBBAoPCgUEBged
CBIGwgECxQEECi0KBAQGBAASBsgBAs4BAxodIERlZmluZXMgaG93IHdlIHJlZGFjdCBkYXRh
LgoKDQoFBAYEAAESBMgBBxgKIAoGBAYEAAIAEgTKAQQnGhAgRG8gbm90IHJlZGFjdC4KCg8K
BwQGBAACAAESBMoBBCIKDwoHBAYEAAIAAhIEygElJgpOCgYEBgQAAgESBM0BBBwaPiBDYWxs
IHJlZGFjdGlvbiBzZXJ2aWNlIHRvIGNsZWFuIHVwIHRoZSBkYXRhIHRvIGJlIHBlcnNpc3Rl
ZC4KCg8KBwQGBAACAQESBM0BBBcKDwoHBAYEAAIBAhIEzQEaGwo3CgQEBgQBEgbRAQLZAQMa
JyBEZWZpbmVzIHdoYXQgdHlwZXMgb2YgZGF0YSB0byByZWRhY3QuCgoNCgUEBgQBARIE0QEH
FQowCgYEBgQBAgASBNMBBCQaICBEb24ndCByZWRhY3QgYW55IGtpbmQgb2YgZGF0YS4KCg8K
BwQGBAECAAESBNMBBB8KDwoHBAYEAQIAAhIE0wEiIwq8AQoGBAYEAQIBEgTYAQQcGqsBIE9u
IGRhdGEgdG8gYmUgd3JpdHRlbiB0byBkaXNrIG9yIHNpbWlsYXIgZGV2aWNlcyB0aGF0IGFy
ZSBjYXBhYmxlIG9mCiBob2xkaW5nIGRhdGEgZXZlbiBpZiBwb3dlciBpcyBkaXNjb25uZWN0
ZWQuIFRoaXMgaW5jbHVkZXMgZGF0YSB0aGF0IGFyZQogdGVtcG9yYXJpbHkgc2F2ZWQgb24g
ZGlzay4KCg8KBwQGBAECAQESBNgBBBcKDwoHBAYEAQIBAhIE2AEaGwpZCgQEBgQCEgbcAQLk
AQMaSSBEZWZpbmVzIGhvdyBsb25nIHdlIHJldGFpbiBwZXJzaXN0ZWQgZGF0YSB0aGF0IGNv
bnRhaW5zIHNlbnNpdGl2ZSBpbmZvLgoKDQoFBAYEAgESBNwBBxgKWgoGBAYEAgIAEgTeAQQn
GkogUmV0YWlucyB0aGUgcGVyc2lzdGVkIGRhdGEgd2l0aCBEaWFsb2dmbG93J3MgaW50ZXJu
YWwgZGVmYXVsdCAzNjVkIFRUTHMuCgoPCgcEBgQCAgABEgTeAQQiCg8KBwQGBAICAAISBN4B
JSYKwQEKBgQGBAICARIE4wEEIhqwASBSZW1vdmVzIGRhdGEgd2hlbiB0aGUgY29udmVyc2F0
aW9uIGVuZHMuIElmIHRoZXJlIGlzIG5vIFtDb252ZXJzYXRpb25dW10KIGV4cGxpY2l0bHkg
ZXN0YWJsaXNoZWQsIGEgZGVmYXVsdCBjb252ZXJzYXRpb24gZW5kcyB3aGVuIHRoZQogY29y
cmVzcG9uZGluZyBEaWFsb2dmbG93IHNlc3Npb24gZW5kcy4KCg8KBwQGBAICAQESBOMBBB0K
DwoHBAYEAgIBAhIE4wEgIQpQCgQEBgQDEgbnAQLuAQMaQCBUeXBlIG9mIGRhdGEgd2UgcHVy
Z2UgYWZ0ZXIgcmV0ZW50aW9uIHNldHRpbmdzIHRyaWdnZXJzIHB1cmdlLgoKDQoFBAYEAwES
BOcBBxQKKgoGBAYEAwIAEgTpAQQkGhogVW5zcGVjaWZpZWQuIERvIG5vdCB1c2UuCgoPCgcE
BgQDAgABEgTpAQQfCg8KBwQGBAMCAAISBOkBIiMKeAoGBAYEAwIBEgTtAQQbGmggRGlhbG9n
ZmxvdyBoaXN0b3J5LiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgQ2xvdWQgbG9nZ2luZywgd2hp
Y2ggaXMKIG93bmVkIGJ5IHRoZSB1c2VyIC0gbm90IERpYWxvZ2Zsb3cuCgoPCgcEBgQDAgEB
EgTtAQQWCg8KBwQGBAMCAQISBO0BGRoKLwoEBAYDABIG8QECmwIDGh8gU2V0dGluZ3MgZm9y
IGV4cG9ydGluZyBhdWRpby4KCg0KBQQGAwABEgTxAQodCmEKBgQGAwAEABIG9AEEgAIFGk8g
RmlsZSBmb3JtYXQgZm9yIGV4cG9ydGVkIGF1ZGlvIGZpbGUuIEN1cnJlbnRseSBvbmx5IGlu
IHRlbGVwaG9ueQogcmVjb3JkaW5ncy4KCg8KBwQGAwAEAAESBPQBCRQKLAoIBAYDAAQAAgAS
BPYBBiMaGiBVbnNwZWNpZmllZC4gRG8gbm90IHVzZS4KChEKCQQGAwAEAAIAARIE9gEGHgoR
CgkEBgMABAACAAISBPYBISIKOwoIBAYDAAQAAgESBPkBBhAaKSBHLjcxMSBtdS1sYXcgUENN
IHdpdGggOGtIeiBzYW1wbGUgcmF0ZS4KChEKCQQGAwAEAAIBARIE+QEGCwoRCgkEBgMABAAC
AQISBPkBDg8KJAoIBAYDAAQAAgISBPwBBg4aEiBNUDMgZmlsZSBmb3JtYXQuCgoRCgkEBgMA
BAACAgESBPwBBgkKEQoJBAYDAAQAAgICEgT8AQwNCh8KCAQGAwAEAAIDEgT/AQYOGg0gT0dH
IFZvcmJpcy4KChEKCQQGAwAEAAIDARIE/wEGCQoRCgkEBgMABAACAwISBP8BDA0KjQIKBgQG
AwACABIEhwIEGhr8ASBDbG91ZCBTdG9yYWdlIGJ1Y2tldCB0byBleHBvcnQgYXVkaW8gcmVj
b3JkIHRvLgogU2V0dGluZyB0aGlzIGZpZWxkIHdvdWxkIGdyYW50IHRoZSBTdG9yYWdlIE9i
amVjdCBDcmVhdG9yIHJvbGUgdG8KIHRoZSBEaWFsb2dmbG93IFNlcnZpY2UgQWdlbnQuCiBB
UEkgY2FsbGVyIHRoYXQgdHJpZXMgdG8gbW9kaWZ5IHRoaXMgZmllbGQgc2hvdWxkIGhhdmUg
dGhlIHBlcm1pc3Npb24gb2YKIHN0b3JhZ2UuYnVja2V0cy5zZXRJYW1Qb2xpY3kuCgoPCgcE
BgMAAgAFEgSHAgQKCg8KBwQGAwACAAESBIcCCxUKDwoHBAYDAAIAAxIEhwIYGQr6AQoGBAYD
AAIBEgSNAgQkGukBIEZpbGVuYW1lIHBhdHRlcm4gZm9yIGV4cG9ydGVkIGF1ZGlvLgoge2Nv
bnZlcnNhdGlvbn0gYW5kIHt0aW1lc3RhbXB9IGFyZSBwbGFjZWhvbGRlcnMgdGhhdCB3aWxs
IGJlIHJlcGxhY2VkCiB3aXRoIHRoZSBjb252ZXJzYXRpb24gSUQgYW5kIGVwb2NoIG1pY3Jv
cyBvZiB0aGUgY29udmVyc2F0aW9uLgogRm9yIGV4YW1wbGUsICJ7Y29udmVyc2F0aW9ufS9y
ZWNvcmRpbmdfe3RpbWVzdGFtcH0ubXVsYXciLgoKDwoHBAYDAAIBBRIEjQIECgoPCgcEBgMA
AgEBEgSNAgsfCg8KBwQGAwACAQMSBI0CIiMKpQEKBgQGAwACAhIEkgIEJBqUASBFbmFibGUg
YXVkaW8gcmVkYWN0aW9uIGlmIGl0IGlzIHRydWUuCiBOb3RlIHRoYXQgdGhpcyBvbmx5IHJl
ZGFjdHMgZW5kLXVzZXIgYXVkaW8gZGF0YTsKIFN5bnRoZXNpc2VkIGF1ZGlvIGZyb20gdGhl
IHZpcnR1YWwgYWdlbnQgaXMgbm90IHJlZGFjdGVkLgoKDwoHBAYDAAICBRIEkgIECAoPCgcE
BgMAAgIBEgSSAgkfCg8KBwQGAwACAgMSBJICIiMKXwoGBAYDAAIDEgSWAgQhGk8gRmlsZSBm
b3JtYXQgZm9yIGV4cG9ydGVkIGF1ZGlvIGZpbGUuIEN1cnJlbnRseSBvbmx5IGluIHRlbGVw
aG9ueQogcmVjb3JkaW5ncy4KCg8KBwQGAwACAwYSBJYCBA8KDwoHBAYDAAIDARIElgIQHAoP
CgcEBgMAAgMDEgSWAh8gCmwKBgQGAwACBBIEmgIEHRpcIFdoZXRoZXIgdG8gc3RvcmUgVFRT
IGF1ZGlvLiBCeSBkZWZhdWx0LCBUVFMgYXVkaW8gZnJvbSB0aGUgdmlydHVhbCBhZ2VudAog
aXMgbm90IGV4cG9ydGVkLgoKDwoHBAYDAAIEBRIEmgIECAoPCgcEBgMAAgQBEgSaAgkYCg8K
BwQGAwACBAMSBJoCGxwKfQoEBAYDARIGnwICowIDGm0gU2V0dGluZ3MgZm9yIGV4cG9ydGlu
ZyBjb252ZXJzYXRpb25zIHRvCiBbSW5zaWdodHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9jb250YWN0LWNlbnRlci9pbnNpZ2h0cy9kb2NzKS4KCg0KBQQGAwEBEgSfAgogCncKBgQG
AwECABIEogIEJBpnIElmIGVuYWJsZWQsIHdlIHdpbGwgYXV0b21hdGljYWxseSBleHBvcnRz
CiBjb252ZXJzYXRpb25zIHRvIEluc2lnaHRzIGFuZCBJbnNpZ2h0cyBydW5zIGl0cyBhbmFs
eXplcnMuCgoPCgcEBgMBAgAFEgSiAgQICg8KBwQGAwECAAESBKICCR8KDwoHBAYDAQIAAxIE
ogIiIwrLAwoEBAYCABIErAICEhq8AyBSZXNvdXJjZSBuYW1lIG9mIHRoZSBzZXR0aW5ncy4K
IFJlcXVpcmVkIGZvciB0aGUKIFtTZWN1cml0eVNldHRpbmdzU2VydmljZS5VcGRhdGVTZWN1
cml0eVNldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZWN1cml0eVNl
dHRpbmdzU2VydmljZS5VcGRhdGVTZWN1cml0eVNldHRpbmdzXQogbWV0aG9kLgogW1NlY3Vy
aXR5U2V0dGluZ3NTZXJ2aWNlLkNyZWF0ZVNlY3VyaXR5U2V0dGluZ3NdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLlNlY3VyaXR5U2V0dGluZ3NTZXJ2aWNlLkNyZWF0ZVNlY3Vy
aXR5U2V0dGluZ3NdCiBwb3B1bGF0ZXMgdGhlIG5hbWUgYXV0b21hdGljYWxseS4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vc2VjdXJp
dHlTZXR0aW5ncy88U2VjdXJpdHlTZXR0aW5nc0lEPmAuCgoNCgUEBgIABRIErAICCAoNCgUE
BgIAARIErAIJDQoNCgUEBgIAAxIErAIQEQpoCgQEBgIBEgSwAgJDGlogUmVxdWlyZWQuIFRo
ZSBodW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBzZWN1cml0eSBzZXR0aW5ncywgdW5pcXVl
IHdpdGhpbgogdGhlIGxvY2F0aW9uLgoKDQoFBAYCAQUSBLACAggKDQoFBAYCAQESBLACCRUK
DQoFBAYCAQMSBLACGBkKDQoFBAYCAQgSBLACGkIKEAoIBAYCAQicCAASBLACG0EKOgoEBAYC
AhIEswICKxosIFN0cmF0ZWd5IHRoYXQgZGVmaW5lcyBob3cgd2UgZG8gcmVkYWN0aW9uLgoK
DQoFBAYCAgYSBLMCAhMKDQoFBAYCAgESBLMCFCYKDQoFBAYCAgMSBLMCKSoKqwEKBAQGAgMS
BLgCAiUanAEgRGVmaW5lcyB0aGUgZGF0YSBmb3Igd2hpY2ggRGlhbG9nZmxvdyBhcHBsaWVz
IHJlZGFjdGlvbi4gRGlhbG9nZmxvdyBkb2VzCiBub3QgcmVkYWN0IGRhdGEgdGhhdCBpdCBk
b2VzIG5vdCBoYXZlIGFjY2VzcyB0byDigJMgZm9yIGV4YW1wbGUsIENsb3VkCiBsb2dnaW5n
LgoKDQoFBAYCAwYSBLgCAhAKDQoFBAYCAwESBLgCESAKDQoFBAYCAwMSBLgCIyQKzQUKBAQG
AgQSBssCAs0CBRq8BSBbRExQXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGxwL2RvY3Mp
IGluc3BlY3QgdGVtcGxhdGUgbmFtZS4gVXNlIHRoaXMKIHRlbXBsYXRlIHRvIGRlZmluZSBp
bnNwZWN0IGJhc2Ugc2V0dGluZ3MuCgogVGhlIGBETFAgSW5zcGVjdCBUZW1wbGF0ZXMgUmVh
ZGVyYCByb2xlIGlzIG5lZWRlZCBvbiB0aGUgRGlhbG9nZmxvdwogc2VydmljZSBpZGVudGl0
eSBzZXJ2aWNlIGFjY291bnQgKGhhcyB0aGUgZm9ybQogYHNlcnZpY2UtUFJPSkVDVF9OVU1C
RVJAZ2NwLXNhLWRpYWxvZ2Zsb3cuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gKQogZm9yIHlv
dXIgYWdlbnQncyBwcm9qZWN0LgoKIElmIGVtcHR5LCB3ZSB1c2UgdGhlIGRlZmF1bHQgRExQ
IGluc3BlY3QgY29uZmlnLgoKIFRoZSB0ZW1wbGF0ZSBuYW1lIHdpbGwgaGF2ZSBvbmUgb2Yg
dGhlIGZvbGxvd2luZyBmb3JtYXRzOgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9u
cy88TG9jYXRpb25JRD4vaW5zcGVjdFRlbXBsYXRlcy88VGVtcGxhdGVJRD5gCiBPUgogYG9y
Z2FuaXphdGlvbnMvPE9yZ2FuaXphdGlvbklEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2lu
c3BlY3RUZW1wbGF0ZXMvPFRlbXBsYXRlSUQ+YAoKIE5vdGU6IGBpbnNwZWN0X3RlbXBsYXRl
YCBtdXN0IGJlIGxvY2F0ZWQgaW4gdGhlIHNhbWUgcmVnaW9uIGFzIHRoZQogYFNlY3VyaXR5
U2V0dGluZ3NgLgoKDQoFBAYCBAUSBMsCAggKDQoFBAYCBAESBMsCCRkKDQoFBAYCBAMSBMsC
HB0KDwoFBAYCBAgSBssCHs0CBAoRCgcEBgIECJ8IEgbLAh/NAgMKiwYKBAQGAgUSBuACAuIC
BRr6BSBbRExQXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGxwL2RvY3MpIGRlaWRlbnRp
ZnkgdGVtcGxhdGUgbmFtZS4gVXNlIHRoaXMKIHRlbXBsYXRlIHRvIGRlZmluZSBkZS1pZGVu
dGlmaWNhdGlvbiBjb25maWd1cmF0aW9uIGZvciB0aGUgY29udGVudC4KCiBUaGUgYERMUCBE
ZS1pZGVudGlmeSBUZW1wbGF0ZXMgUmVhZGVyYCByb2xlIGlzIG5lZWRlZCBvbiB0aGUgRGlh
bG9nZmxvdwogc2VydmljZSBpZGVudGl0eSBzZXJ2aWNlIGFjY291bnQgKGhhcyB0aGUgZm9y
bQogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJAZ2NwLXNhLWRpYWxvZ2Zsb3cuaWFtLmdzZXJ2
aWNlYWNjb3VudC5jb21gKQogZm9yIHlvdXIgYWdlbnQncyBwcm9qZWN0LgoKIElmIGVtcHR5
LCBEaWFsb2dmbG93IHJlcGxhY2VzIHNlbnNpdGl2ZSBpbmZvIHdpdGggYFtyZWRhY3RlZF1g
IHRleHQuCgogVGhlIHRlbXBsYXRlIG5hbWUgd2lsbCBoYXZlIG9uZSBvZiB0aGUgZm9sbG93
aW5nIGZvcm1hdHM6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlv
bklEPi9kZWlkZW50aWZ5VGVtcGxhdGVzLzxUZW1wbGF0ZUlEPmAKIE9SCiBgb3JnYW5pemF0
aW9ucy88T3JnYW5pemF0aW9uSUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vZGVpZGVudGlm
eVRlbXBsYXRlcy88VGVtcGxhdGVJRD5gCgogTm90ZTogYGRlaWRlbnRpZnlfdGVtcGxhdGVg
IG11c3QgYmUgbG9jYXRlZCBpbiB0aGUgc2FtZSByZWdpb24gYXMgdGhlCiBgU2VjdXJpdHlT
ZXR0aW5nc2AuCgoNCgUEBgIFBRIE4AICCAoNCgUEBgIFARIE4AIJHAoNCgUEBgIFAxIE4AIf
IQoPCgUEBgIFCBIG4AIi4gIEChEKBwQGAgUInwgSBuACI+ICAwrKAQoEBAYIABIG5wIC9QID
GrkBIFNwZWNpZmllcyBob3cgZGF0YSBpcyByZXRhaW5lZC4gTm90ZSB0aGF0IGV2ZW4gaWYg
dGhlIGRhdGEgaXMKIHB1cmdlZCBkdWUgdG8gcmV0ZW50aW9uIHBvbGljeSwgd2UgbWF5IHN0
aWxsIGhvbGQgaXQgaW4gYmFja3VwIHN0b3JhZ2UgZm9yCiBhIGZldyBkYXlzIHdpdGhvdXQg
YWxsb3dpbmcgZGlyZWN0IHJlYWRpbmdzLgoKDQoFBAYIAAESBOcCCBYK7wMKBAQGAgYSBPAC
BCQa4AMgUmV0YWlucyB0aGUgZGF0YSBmb3IgdGhlIHNwZWNpZmllZCBudW1iZXIgb2YgZGF5
cy4KIFVzZXIgbXVzdCBzZXQgYSB2YWx1ZSBsb3dlciB0aGFuIERpYWxvZ2Zsb3cncyBkZWZh
dWx0IDM2NWQgVFRMICgzMCBkYXlzCiBmb3IgQWdlbnQgQXNzaXN0IHRyYWZmaWMpLCBoaWdo
ZXIgdmFsdWUgd2lsbCBiZSBpZ25vcmVkIGFuZCB1c2UgZGVmYXVsdC4KIFNldHRpbmcgYSB2
YWx1ZSBoaWdoZXIgdGhhbiB0aGF0IGhhcyBubyBlZmZlY3QuIEEgbWlzc2luZyB2YWx1ZSBv
cgogc2V0dGluZyB0byAwIGFsc28gbWVhbnMgd2UgdXNlIGRlZmF1bHQgVFRMLgogV2hlbiBk
YXRhIHJldGVudGlvbiBjb25maWd1cmF0aW9uIGlzIGNoYW5nZWQsIGl0IG9ubHkgYXBwbGll
cyB0byB0aGUgZGF0YQogY3JlYXRlZCBhZnRlciB0aGUgY2hhbmdlOyB0aGUgVFRMIG9mIGV4
aXN0aW5nIGRhdGEgY3JlYXRlZCBiZWZvcmUgdGhlCiBjaGFuZ2Ugc3RheXMgaW50YWN0LgoK
DQoFBAYCBgUSBPACBAkKDQoFBAYCBgESBPACCh8KDQoFBAYCBgMSBPACIiMKpQEKBAQGAgcS
BPQCBC0algEgU3BlY2lmaWVzIHRoZSByZXRlbnRpb24gYmVoYXZpb3IgZGVmaW5lZCBieQog
W1NlY3VyaXR5U2V0dGluZ3MuUmV0ZW50aW9uU3RyYXRlZ3ldW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLlNlY3VyaXR5U2V0dGluZ3MuUmV0ZW50aW9uU3RyYXRlZ3ldLgoKDQoF
BAYCBwYSBPQCBBUKDQoFBAYCBwESBPQCFigKDQoFBAYCBwMSBPQCKywKVwoEBAYCCBIE+AIC
LhpJIExpc3Qgb2YgdHlwZXMgb2YgZGF0YSB0byByZW1vdmUgd2hlbiByZXRlbnRpb24gc2V0
dGluZ3MgdHJpZ2dlcnMgcHVyZ2UuCgoNCgUEBgIIBBIE+AICCgoNCgUEBgIIBhIE+AILGAoN
CgUEBgIIARIE+AIZKQoNCgUEBgIIAxIE+AIsLQq3BgoEBAYCCRIEiwMCMRqoBiBDb250cm9s
cyBhdWRpbyBleHBvcnQgc2V0dGluZ3MgZm9yIHBvc3QtY29udmVyc2F0aW9uIGFuYWx5dGlj
cyB3aGVuCiBpbmdlc3RpbmcgYXVkaW8gdG8gY29udmVyc2F0aW9ucyB2aWEgW1BhcnRpY2lw
YW50cy5BbmFseXplQ29udGVudF1bXSBvcgogW1BhcnRpY2lwYW50cy5TdHJlYW1pbmdBbmFs
eXplQ29udGVudF1bXS4KCiBJZgogW3JldGVudGlvbl9zdHJhdGVneV1bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5ncy5yZXRlbnRpb25fc3RyYXRlZ3ld
CiBpcyBzZXQgdG8gUkVNT1ZFX0FGVEVSX0NPTlZFUlNBVElPTiBvciBbYXVkaW9fZXhwb3J0
X3NldHRpbmdzLmdjc19idWNrZXRdW10KIGlzIGVtcHR5LCBhdWRpbyBleHBvcnQgaXMgZGlz
YWJsZWQuCgogSWYgYXVkaW8gZXhwb3J0IGlzIGVuYWJsZWQsIGF1ZGlvIGlzIHJlY29yZGVk
IGFuZCBzYXZlZCB0bwogW2F1ZGlvX2V4cG9ydF9zZXR0aW5ncy5nY3NfYnVja2V0XVtdLCBz
dWJqZWN0IHRvIHJldGVudGlvbiBwb2xpY3kgb2YKIFthdWRpb19leHBvcnRfc2V0dGluZ3Mu
Z2NzX2J1Y2tldF1bXS4KCiBUaGlzIHNldHRpbmcgd29uJ3QgZWZmZWN0IGF1ZGlvIGlucHV0
IGZvciBpbXBsaWNpdCBzZXNzaW9ucyB2aWEKIFtTZXNzaW9ucy5EZXRlY3RJbnRlbnRdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlc3Npb25zLkRldGVjdEludGVudF0KIG9y
CiBbU2Vzc2lvbnMuU3RyZWFtaW5nRGV0ZWN0SW50ZW50XVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5TZXNzaW9ucy5TdHJlYW1pbmdEZXRlY3RJbnRlbnRdLgoKDQoFBAYCCQYS
BIsDAhUKDQoFBAYCCQESBIsDFisKDQoFBAYCCQMSBIsDLjAKqwIKBAQGAgoSBJQDAjcanAIg
Q29udHJvbHMgY29udmVyc2F0aW9uIGV4cG9ydGluZyBzZXR0aW5ncyB0byBJbnNpZ2h0cyBh
ZnRlciBjb252ZXJzYXRpb24gaXMKIGNvbXBsZXRlZC4KCiBJZgogW3JldGVudGlvbl9zdHJh
dGVneV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2VjdXJpdHlTZXR0aW5ncy5y
ZXRlbnRpb25fc3RyYXRlZ3ldCiBpcyBzZXQgdG8gUkVNT1ZFX0FGVEVSX0NPTlZFUlNBVElP
TiwgSW5zaWdodHMgZXhwb3J0IGlzIGRpc2FibGVkIG5vIG1hdHRlcgogd2hhdCB5b3UgY29u
ZmlndXJlIGhlcmUuCgoNCgUEBgIKBhIElAMCGAoNCgUEBgIKARIElAMZMQoNCgUEBgIKAxIE
lAM0NmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest ===
    # Fields for GetSecuritySettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest ===
    # Fields for UpdateSecuritySettingsRequest
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SecuritySettings)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest ===
    # Fields for ListSecuritySettingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse ===
    # Fields for ListSecuritySettingsResponse
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SecuritySettings)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest ===
    # Fields for CreateSecuritySettingsRequest
    # Field: parent Type: 9 ()
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SecuritySettings)

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest ===
    # Fields for DeleteSecuritySettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings ===
    # Fields for SecuritySettings
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: redaction_strategy Type: 14 (.google.cloud.dialogflow.cx.v3.SecuritySettings.RedactionStrategy)
    # Field: redaction_scope Type: 14 (.google.cloud.dialogflow.cx.v3.SecuritySettings.RedactionScope)
    # Field: inspect_template Type: 9 ()
    # Field: deidentify_template Type: 9 ()
    # Field: retention_window_days Type: 5 ()
    # Field: retention_strategy Type: 14 (.google.cloud.dialogflow.cx.v3.SecuritySettings.RetentionStrategy)
    # Field: purge_data_types Type: 14 (.google.cloud.dialogflow.cx.v3.SecuritySettings.PurgeDataType)
    # Field: audio_export_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SecuritySettings.AudioExportSettings)
    # Field: insights_export_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SecuritySettings.InsightsExportSettings)

# Enum: SecuritySettings::RedactionStrategy
our $SecuritySettings_REDACTION_STRATEGY_UNSPECIFIED = 0;
our $SecuritySettings_REDACT_WITH_SERVICE = 1;

# Enum: SecuritySettings::RedactionScope
our $SecuritySettings_REDACTION_SCOPE_UNSPECIFIED = 0;
our $SecuritySettings_REDACT_DISK_STORAGE = 2;

# Enum: SecuritySettings::RetentionStrategy
our $SecuritySettings_RETENTION_STRATEGY_UNSPECIFIED = 0;
our $SecuritySettings_REMOVE_AFTER_CONVERSATION = 1;

# Enum: SecuritySettings::PurgeDataType
our $SecuritySettings_PURGE_DATA_TYPE_UNSPECIFIED = 0;
our $SecuritySettings_DIALOGFLOW_HISTORY = 1;

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettingsServiceClient ===
package Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettingsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettingsServiceClient

Client stub representing the remote C<SecuritySettingsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub create_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'CreateSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings',
    });
}

sub get_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'GetSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings',
    });
}

sub update_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'UpdateSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings',
    });
}

sub list_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'ListSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse',
    });
}

sub delete_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SecuritySettingsService',
        method         => 'DeleteSecuritySettings',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::SecuritySettings - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/security_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::SecuritySettings;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/security_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::GetSecuritySettingsRequest

The request message for
[SecuritySettingsService.GetSecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettingsService.GetSecuritySettings].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the settings.
Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<securitysettingsID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::UpdateSecuritySettingsRequest

The request message for
[SecuritySettingsService.UpdateSecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettingsService.UpdateSecuritySettings].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings>)

Required. [SecuritySettings] object that contains values for each of the
fields to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsRequest

The request message for [SecuritySettings.ListSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to list all security settings for.
Format: `projects/<ProjectID>/locations/<LocationID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 20 and
at most 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::ListSecuritySettingsResponse

The response message for [SecuritySettings.ListSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings>)

The list of security settings.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::CreateSecuritySettingsRequest

The request message for [SecuritySettings.CreateSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create an
[SecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettings] for.
Format: `projects/<ProjectID>/locations/<LocationID>`.

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings>)

Required. The security settings to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::DeleteSecuritySettingsRequest

The request message for [SecuritySettings.DeleteSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[SecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettings] to
delete. Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<SecuritySettingsID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings

Represents the settings related to security issues, such as data redaction
and data retention. It may take hours for updates on the settings to
propagate to all the related components and take effect.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource name of the settings.
Required for the
[SecuritySettingsService.UpdateSecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettingsService.UpdateSecuritySettings]
method.
[SecuritySettingsService.CreateSecuritySettings][google.cloud.dialogflow.cx.v3.SecuritySettingsService.CreateSecuritySettings]
populates the name automatically. Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<SecuritySettingsID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the security settings, unique within
the location.

=item * C<< $msg->redaction_strategy() >> / C<< $msg->redaction_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::RedactionStrategy>)

Strategy that defines how we do redaction.

=item * C<< $msg->redaction_scope() >> / C<< $msg->redaction_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::RedactionScope>)

Defines the data for which Dialogflow applies redaction. Dialogflow does
not redact data that it does not have access to – for example, Cloud
logging.

=item * C<< $msg->inspect_template() >> / C<< $msg->inspect_template($value) >>

Type: C<String>

[DLP](https://cloud.google.com/dlp/docs) inspect template name. Use this
template to define inspect base settings.

The `DLP Inspect Templates Reader` role is needed on the Dialogflow
service identity service account (has the form
`service-PROJECT_NUMBER@gcp-sa-dialogflow.iam.gserviceaccount.com`)
for your agent's project.

If empty, we use the default DLP inspect config.

The template name will have one of the following formats:
`projects/<ProjectID>/locations/<LocationID>/inspectTemplates/<TemplateID>`
OR
`organizations/<OrganizationID>/locations/<LocationID>/inspectTemplates/<TemplateID>`

Note: `inspect_template` must be located in the same region as the
`SecuritySettings`.

=item * C<< $msg->deidentify_template() >> / C<< $msg->deidentify_template($value) >>

Type: C<String>

[DLP](https://cloud.google.com/dlp/docs) deidentify template name. Use this
template to define de-identification configuration for the content.

The `DLP De-identify Templates Reader` role is needed on the Dialogflow
service identity service account (has the form
`service-PROJECT_NUMBER@gcp-sa-dialogflow.iam.gserviceaccount.com`)
for your agent's project.

If empty, Dialogflow replaces sensitive info with `[redacted]` text.

The template name will have one of the following formats:
`projects/<ProjectID>/locations/<LocationID>/deidentifyTemplates/<TemplateID>`
OR
`organizations/<OrganizationID>/locations/<LocationID>/deidentifyTemplates/<TemplateID>`

Note: `deidentify_template` must be located in the same region as the
`SecuritySettings`.

=item * C<< $msg->retention_window_days() >> / C<< $msg->retention_window_days($value) >>

Type: C<Int32>

Retains the data for the specified number of days.
User must set a value lower than Dialogflow's default 365d TTL (30 days
for Agent Assist traffic), higher value will be ignored and use default.
Setting a value higher than that has no effect. A missing value or
setting to 0 also means we use default TTL.
When data retention configuration is changed, it only applies to the data
created after the change; the TTL of existing data created before the
change stays intact.

=item * C<< $msg->retention_strategy() >> / C<< $msg->retention_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::RetentionStrategy>)

Specifies the retention behavior defined by
[SecuritySettings.RetentionStrategy][google.cloud.dialogflow.cx.v3.SecuritySettings.RetentionStrategy].

=item * C<< $msg->purge_data_types() >> / C<< $msg->purge_data_types($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::PurgeDataType>)

List of types of data to remove when retention settings triggers purge.

=item * C<< $msg->audio_export_settings() >> / C<< $msg->audio_export_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::AudioExportSettings>)

Controls audio export settings for post-conversation analytics when
ingesting audio to conversations via [Participants.AnalyzeContent][] or
[Participants.StreamingAnalyzeContent][].

If
[retention_strategy][google.cloud.dialogflow.cx.v3.SecuritySettings.retention_strategy]
is set to REMOVE_AFTER_CONVERSATION or [audio_export_settings.gcs_bucket][]
is empty, audio export is disabled.

If audio export is enabled, audio is recorded and saved to
[audio_export_settings.gcs_bucket][], subject to retention policy of
[audio_export_settings.gcs_bucket][].

This setting won't effect audio input for implicit sessions via
[Sessions.DetectIntent][google.cloud.dialogflow.cx.v3.Sessions.DetectIntent]
or
[Sessions.StreamingDetectIntent][google.cloud.dialogflow.cx.v3.Sessions.StreamingDetectIntent].

=item * C<< $msg->insights_export_settings() >> / C<< $msg->insights_export_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::SecuritySettings::InsightsExportSettings>)

Controls conversation exporting settings to Insights after conversation is
completed.

If
[retention_strategy][google.cloud.dialogflow.cx.v3.SecuritySettings.retention_strategy]
is set to REMOVE_AFTER_CONVERSATION, Insights export is disabled no matter
what you configure here.

=back

=head3 Enum: SecuritySettings::RedactionStrategy

=over 4

=item * C<REDACTION_STRATEGY_UNSPECIFIED> => C<0>

=item * C<REDACT_WITH_SERVICE> => C<1>

=back

=head3 Enum: SecuritySettings::RedactionScope

=over 4

=item * C<REDACTION_SCOPE_UNSPECIFIED> => C<0>

=item * C<REDACT_DISK_STORAGE> => C<2>

=back

=head3 Enum: SecuritySettings::RetentionStrategy

=over 4

=item * C<RETENTION_STRATEGY_UNSPECIFIED> => C<0>

=item * C<REMOVE_AFTER_CONVERSATION> => C<1>

=back

=head3 Enum: SecuritySettings::PurgeDataType

=over 4

=item * C<PURGE_DATA_TYPE_UNSPECIFIED> => C<0>

=item * C<DIALOGFLOW_HISTORY> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::SecuritySettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
