package Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings;

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
Cjpnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3NlY3VyaXR5X3NldHRpbmdz
LnByb3RvEiJnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29v
Z2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90byJkChpHZXRTZWN1cml0eVNldHRpbmdzUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6
QSwKKmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlTZXR0aW5nc1IEbmFtZSLJ
AQodVXBkYXRlU2VjdXJpdHlTZXR0aW5nc1JlcXVlc3QSZgoRc2VjdXJpdHlfc2V0dGluZ3MY
ASABKAsyNC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5U2V0
dGluZ3NCA+BBAlIQc2VjdXJpdHlTZXR0aW5ncxJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzayKlAQobTGlzdFNlY3Vy
aXR5U2V0dGluZ3NSZXF1ZXN0EkoKBnBhcmVudBgBIAEoCUIy4EEC+kEsEipkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1NlY3VyaXR5U2V0dGluZ3NSBnBhcmVudBIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKpAQocTGlz
dFNlY3VyaXR5U2V0dGluZ3NSZXNwb25zZRJhChFzZWN1cml0eV9zZXR0aW5ncxgBIAMoCzI0
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5nc1IQ
c2VjdXJpdHlTZXR0aW5ncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4i0wEKHUNyZWF0ZVNlY3VyaXR5U2V0dGluZ3NSZXF1ZXN0EkoKBnBhcmVudBgBIAEoCUIy
4EEC+kEsEipkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1NlY3VyaXR5U2V0dGluZ3NSBnBh
cmVudBJmChFzZWN1cml0eV9zZXR0aW5ncxgCIAEoCzI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5nc0ID4EECUhBzZWN1cml0eVNldHRpbmdz
ImcKHURlbGV0ZVNlY3VyaXR5U2V0dGluZ3NSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpB
LAoqZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TZWN1cml0eVNldHRpbmdzUgRuYW1lIrIP
ChBTZWN1cml0eVNldHRpbmdzEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1l
GAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEnUKEnJlZGFjdGlvbl9zdHJhdGVneRgDIAEoDjJG
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncy5S
ZWRhY3Rpb25TdHJhdGVneVIRcmVkYWN0aW9uU3RyYXRlZ3kSbAoPcmVkYWN0aW9uX3Njb3Bl
GAQgASgOMkMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZWN1cml0eVNl
dHRpbmdzLlJlZGFjdGlvblNjb3BlUg5yZWRhY3Rpb25TY29wZRJSChBpbnNwZWN0X3RlbXBs
YXRlGAkgASgJQif6QSQKImRscC5nb29nbGVhcGlzLmNvbS9JbnNwZWN0VGVtcGxhdGVSD2lu
c3BlY3RUZW1wbGF0ZRJbChNkZWlkZW50aWZ5X3RlbXBsYXRlGBEgASgJQir6QScKJWRscC5n
b29nbGVhcGlzLmNvbS9EZWlkZW50aWZ5VGVtcGxhdGVSEmRlaWRlbnRpZnlUZW1wbGF0ZRI0
ChVyZXRlbnRpb25fd2luZG93X2RheXMYBiABKAVIAFITcmV0ZW50aW9uV2luZG93RGF5cxJ3
ChJyZXRlbnRpb25fc3RyYXRlZ3kYByABKA4yRi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLlNlY3VyaXR5U2V0dGluZ3MuUmV0ZW50aW9uU3RyYXRlZ3lIAFIRcmV0ZW50
aW9uU3RyYXRlZ3kSbAoQcHVyZ2VfZGF0YV90eXBlcxgIIAMoDjJCLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncy5QdXJnZURhdGFUeXBlUg5w
dXJnZURhdGFUeXBlcxJ8ChVhdWRpb19leHBvcnRfc2V0dGluZ3MYDCABKAsySC5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5U2V0dGluZ3MuQXVkaW9FeHBv
cnRTZXR0aW5nc1ITYXVkaW9FeHBvcnRTZXR0aW5ncxKFAQoYaW5zaWdodHNfZXhwb3J0X3Nl
dHRpbmdzGA0gASgLMksuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZWN1
cml0eVNldHRpbmdzLkluc2lnaHRzRXhwb3J0U2V0dGluZ3NSFmluc2lnaHRzRXhwb3J0U2V0
dGluZ3MahwMKE0F1ZGlvRXhwb3J0U2V0dGluZ3MSHQoKZ2NzX2J1Y2tldBgBIAEoCVIJZ2Nz
QnVja2V0EjAKFGF1ZGlvX2V4cG9ydF9wYXR0ZXJuGAIgASgJUhJhdWRpb0V4cG9ydFBhdHRl
cm4SNAoWZW5hYmxlX2F1ZGlvX3JlZGFjdGlvbhgDIAEoCFIUZW5hYmxlQXVkaW9SZWRhY3Rp
b24SdwoMYXVkaW9fZm9ybWF0GAQgASgOMlQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMS5TZWN1cml0eVNldHRpbmdzLkF1ZGlvRXhwb3J0U2V0dGluZ3MuQXVkaW9Gb3Jt
YXRSC2F1ZGlvRm9ybWF0EiYKD3N0b3JlX3R0c19hdWRpbxgGIAEoCFINc3RvcmVUdHNBdWRp
byJICgtBdWRpb0Zvcm1hdBIcChhBVURJT19GT1JNQVRfVU5TUEVDSUZJRUQQABIJCgVNVUxB
VxABEgcKA01QMxACEgcKA09HRxADGk4KFkluc2lnaHRzRXhwb3J0U2V0dGluZ3MSNAoWZW5h
YmxlX2luc2lnaHRzX2V4cG9ydBgBIAEoCFIUZW5hYmxlSW5zaWdodHNFeHBvcnQiUAoRUmVk
YWN0aW9uU3RyYXRlZ3kSIgoeUkVEQUNUSU9OX1NUUkFURUdZX1VOU1BFQ0lGSUVEEAASFwoT
UkVEQUNUX1dJVEhfU0VSVklDRRABIkoKDlJlZGFjdGlvblNjb3BlEh8KG1JFREFDVElPTl9T
Q09QRV9VTlNQRUNJRklFRBAAEhcKE1JFREFDVF9ESVNLX1NUT1JBR0UQAiJWChFSZXRlbnRp
b25TdHJhdGVneRIiCh5SRVRFTlRJT05fU1RSQVRFR1lfVU5TUEVDSUZJRUQQABIdChlSRU1P
VkVfQUZURVJfQ09OVkVSU0FUSU9OEAEiSAoNUHVyZ2VEYXRhVHlwZRIfChtQVVJHRV9EQVRB
X1RZUEVfVU5TUEVDSUZJRUQQABIWChJESUFMT0dGTE9XX0hJU1RPUlkQATp96kF6CipkaWFs
b2dmbG93Lmdvb2dsZWFwaXMuY29tL1NlY3VyaXR5U2V0dGluZ3MSTHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZWN1cml0eVNldHRpbmdzL3tzZWN1cml0eV9z
ZXR0aW5nc31CEAoOZGF0YV9yZXRlbnRpb24ytQoKF1NlY3VyaXR5U2V0dGluZ3NTZXJ2aWNl
EoICChZDcmVhdGVTZWN1cml0eVNldHRpbmdzEkEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5DcmVhdGVTZWN1cml0eVNldHRpbmdzUmVxdWVzdBo0Lmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncyJvgtPkkwJOIjkvdjNi
ZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3NlY3VyaXR5U2V0dGluZ3M6
EXNlY3VyaXR5X3NldHRpbmdz2kEYcGFyZW50LHNlY3VyaXR5X3NldHRpbmdzEtUBChNHZXRT
ZWN1cml0eVNldHRpbmdzEj4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5H
ZXRTZWN1cml0eVNldHRpbmdzUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncyJIgtPkkwI7EjkvdjNiZXRhMS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL3NlY3VyaXR5U2V0dGluZ3MvKn3aQQRuYW1lEpoCChZVcGRh
dGVTZWN1cml0eVNldHRpbmdzEkEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MS5VcGRhdGVTZWN1cml0eVNldHRpbmdzUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncyKGAYLT5JMCYDJLL3YzYmV0YTEve3Nl
Y3VyaXR5X3NldHRpbmdzLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZWN1cml0eVNl
dHRpbmdzLyp9OhFzZWN1cml0eV9zZXR0aW5nc9pBHXNlY3VyaXR5X3NldHRpbmdzLHVwZGF0
ZV9tYXNrEuUBChRMaXN0U2VjdXJpdHlTZXR0aW5ncxI/Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuTGlzdFNlY3VyaXR5U2V0dGluZ3NSZXF1ZXN0GkAuZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5MaXN0U2VjdXJpdHlTZXR0aW5nc1Jlc3BvbnNl
IkqC0+STAjsSOS92M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc2Vj
dXJpdHlTZXR0aW5nc9pBBnBhcmVudBK9AQoWRGVsZXRlU2VjdXJpdHlTZXR0aW5ncxJBLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGVsZXRlU2VjdXJpdHlTZXR0aW5n
c1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiSILT5JMCOyo5L3YzYmV0YTEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZWN1cml0eVNldHRpbmdzLyp92kEEbmFtZRp4
ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9kaWFsb2dmbG93QvMECiZjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MUIVU2VjdXJpdHlTZXR0aW5nc1Byb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9n
Zmxvdy9jeC9hcGl2M2JldGExL2N4cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNsb3VkLkRpYWxv
Z2Zsb3cuQ3guVjNCZXRhMeoCJkdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpWM2Jl
dGEx6kHIAQoiZGxwLmdvb2dsZWFwaXMuY29tL0luc3BlY3RUZW1wbGF0ZRJVb3JnYW5pemF0
aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnNwZWN0VGVtcGxh
dGVzL3tpbnNwZWN0X3RlbXBsYXRlfRJLcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2luc3BlY3RUZW1wbGF0ZXMve2luc3BlY3RfdGVtcGxhdGV96kHXAQolZGxw
Lmdvb2dsZWFwaXMuY29tL0RlaWRlbnRpZnlUZW1wbGF0ZRJbb3JnYW5pemF0aW9ucy97b3Jn
YW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kZWlkZW50aWZ5VGVtcGxhdGVzL3tk
ZWlkZW50aWZ5X3RlbXBsYXRlfRJRcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2RlaWRlbnRpZnlUZW1wbGF0ZXMve2RlaWRlbnRpZnlfdGVtcGxhdGV9SrdsCgcS
BQ4AmAMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAJQoJ
CgIDBRIDFwAqCggKAQgSAxkAPwoJCgIIJRIDGQA/CggKAQgSAxoATQoJCgIICxIDGgBNCggK
AQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANgoJCgIICBIDHAA2CggKAQgSAx0APwoJCgII
ARIDHQA/CggKAQgSAx4AIAoJCgIIJBIDHgAgCggKAQgSAx8APwoJCgIILRIDHwA/CgkKAQgS
BCAAJAIKDAoECJ0IABIEIAAkAgoJCgEIEgQlACkCCgwKBAidCAESBCUAKQIKRAoCBgASBCwA
ZAEaOCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBzZWN1cml0eSBzZXR0aW5ncyBmb3IgRGlhbG9n
Zmxvdy4KCgoKAwYAARIDLAgfCgoKAwYAAxIDLQJBCgwKBQYAA5kIEgMtAkEKCwoDBgADEgQu
AjAzCg0KBQYAA5oIEgQuAjAzCkMKBAYAAgASBDMCOgMaNSBDcmVhdGUgc2VjdXJpdHkgc2V0
dGluZ3MgaW4gdGhlIHNwZWNpZmllZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMzBhwKDAoFBgAC
AAISAzMdOgoMCgUGAAIAAxIDNA8fCg0KBQYAAgAEEgQ1BDgGChEKCQYAAgAEsMq8IhIENQQ4
BgoMCgUGAAIABBIDOQRGCg8KCAYAAgAEmwgAEgM5BEYKqQEKBAYAAgESBD8CRQMamgEgUmV0
cmlldmVzIHRoZSBzcGVjaWZpZWQKIFtTZWN1cml0eVNldHRpbmdzXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5U2V0dGluZ3NdLgogVGhlIHJldHVybmVk
IHNldHRpbmdzIG1heSBiZSBzdGFsZSBieSB1cCB0byAxIG1pbnV0ZS4KCgwKBQYAAgEBEgM/
BhkKDAoFBgACAQISAz8aNAoMCgUGAAIBAxIDQA8fCg0KBQYAAgEEEgRBBEMGChEKCQYAAgEE
sMq8IhIEQQRDBgoMCgUGAAIBBBIDRAQyCg8KCAYAAgEEmwgAEgNEBDIKbwoEBgACAhIESQJQ
AxphIFVwZGF0ZXMgdGhlIHNwZWNpZmllZAogW1NlY3VyaXR5U2V0dGluZ3NdW2dvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5nc10uCgoMCgUGAAIC
ARIDSQYcCgwKBQYAAgICEgNJHToKDAoFBgACAgMSA0oPHwoNCgUGAAICBBIESwROBgoRCgkG
AAICBLDKvCISBEsETgYKDAoFBgACAgQSA08ESwoPCggGAAICBJsIABIDTwRLClQKBAYAAgMS
BFMCWQMaRiBSZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCBzZWN1cml0eSBzZXR0aW5ncyBpbiB0
aGUgc3BlY2lmaWVkIGxvY2F0aW9uLgoKDAoFBgACAwESA1MGGgoMCgUGAAIDAhIDUxs2CgwK
BQYAAgMDEgNUDysKDQoFBgACAwQSBFUEVwYKEQoJBgACAwSwyrwiEgRVBFcGCgwKBQYAAgME
EgNYBDQKDwoIBgACAwSbCAASA1gENApvCgQGAAIEEgRdAmMDGmEgRGVsZXRlcyB0aGUgc3Bl
Y2lmaWVkCiBbU2VjdXJpdHlTZXR0aW5nc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMS5TZWN1cml0eVNldHRpbmdzXS4KCgwKBQYAAgQBEgNdBhwKDAoFBgACBAISA10d
OgoMCgUGAAIEAxIDXg8kCg0KBQYAAgQEEgRfBGEGChEKCQYAAgQEsMq8IhIEXwRhBgoMCgUG
AAIEBBIDYgQyCg8KCAYAAgQEmwgAEgNiBDIKpgEKAgQAEgRoAHIBGpkBIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbU2VjdXJpdHlTZXR0aW5nc1NlcnZpY2UuR2V0U2VjdXJpdHlTZXR0
aW5nc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZWN1cml0eVNldHRp
bmdzU2VydmljZS5HZXRTZWN1cml0eVNldHRpbmdzXS4KCgoKAwQAARIDaAgiCpgBCgQEAAIA
EgRsAnEEGokBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBzZXR0aW5ncy4KIEZv
cm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L3Nl
Y3VyaXR5U2V0dGluZ3MvPHNlY3VyaXR5c2V0dGluZ3NJRD5gLgoKDAoFBAACAAUSA2wCCAoM
CgUEAAIAARIDbAkNCgwKBQQAAgADEgNsEBEKDQoFBAACAAgSBGwScQMKDwoIBAACAAicCAAS
A20EKgoPCgcEAAIACJ8IEgRuBHAFCq0BCgIEARIFdgCAAQEanwEgVGhlIHJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtTZWN1cml0eVNldHRpbmdzU2VydmljZS5VcGRhdGVTZWN1cml0eVNldHRp
bmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5U2V0dGlu
Z3NTZXJ2aWNlLlVwZGF0ZVNlY3VyaXR5U2V0dGluZ3NdLgoKCgoDBAEBEgN2CCUKawoEBAEC
ABIEeQJ6LxpdIFJlcXVpcmVkLiBbU2VjdXJpdHlTZXR0aW5nc10gb2JqZWN0IHRoYXQgY29u
dGFpbnMgdmFsdWVzIGZvciBlYWNoIG9mIHRoZQogZmllbGRzIHRvIHVwZGF0ZS4KCgwKBQQB
AgAGEgN5AhIKDAoFBAECAAESA3kTJAoMCgUEAQIAAxIDeScoCgwKBQQBAgAIEgN6Bi4KDwoI
BAECAAicCAASA3oHLQqAAQoEBAECARIEfgJ/LxpyIFJlcXVpcmVkLiBUaGUgbWFzayB0byBj
b250cm9sIHdoaWNoIGZpZWxkcyBnZXQgdXBkYXRlZC4gSWYgdGhlIG1hc2sgaXMgbm90CiBw
cmVzZW50LCBhbGwgZmllbGRzIHdpbGwgYmUgdXBkYXRlZC4KCgwKBQQBAgEGEgN+AhsKDAoF
BAECAQESA34cJwoMCgUEAQIBAxIDfiorCgwKBQQBAgEIEgN/Bi4KDwoIBAECAQicCAASA38H
LQpSCgIEAhIGgwEAkwEBGkQgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgW1NlY3VyaXR5U2V0
dGluZ3MuTGlzdFNlY3VyaXR5U2V0dGluZ3NdW10uCgoLCgMEAgESBIMBCCMKgwEKBAQCAgAS
BoYBAosBBBpzIFJlcXVpcmVkLiBUaGUgbG9jYXRpb24gdG8gbGlzdCBhbGwgc2VjdXJpdHkg
c2V0dGluZ3MgZm9yLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25z
LzxMb2NhdGlvbklEPmAuCgoNCgUEAgIABRIEhgECCAoNCgUEAgIAARIEhgEJDwoNCgUEAgIA
AxIEhgESEwoPCgUEAgIACBIGhgEUiwEDChAKCAQCAgAInAgAEgSHAQQqChEKBwQCAgAInwgS
BogBBIoBBQpnCgQEAgIBEgSPAQIWGlkgVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRv
IHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZhdWx0IDIwIGFuZAogYXQgbW9zdCAx
MDAuCgoNCgUEAgIBBRIEjwECBwoNCgUEAgIBARIEjwEIEQoNCgUEAgIBAxIEjwEUFQpQCgQE
AgICEgSSAQIYGkIgVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEg
cHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAICAgUSBJIBAggKDQoFBAICAgESBJIBCRMK
DQoFBAICAgMSBJIBFhcKUwoCBAMSBpYBAJ0BARpFIFRoZSByZXNwb25zZSBtZXNzYWdlIGZv
ciBbU2VjdXJpdHlTZXR0aW5ncy5MaXN0U2VjdXJpdHlTZXR0aW5nc11bXS4KCgsKAwQDARIE
lgEIJAouCgQEAwIAEgSYAQIyGiAgVGhlIGxpc3Qgb2Ygc2VjdXJpdHkgc2V0dGluZ3MuCgoN
CgUEAwIABBIEmAECCgoNCgUEAwIABhIEmAELGwoNCgUEAwIAARIEmAEcLQoNCgUEAwIAAxIE
mAEwMQpvCgQEAwIBEgScAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBv
ZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0
aGUgbGlzdC4KCg0KBQQDAgEFEgScAQIICg0KBQQDAgEBEgScAQkYCg0KBQQDAgEDEgScARsc
ClQKAgQEEgagAQCuAQEaRiBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbU2VjdXJpdHlTZXR0
aW5ncy5DcmVhdGVTZWN1cml0eVNldHRpbmdzXVtdLgoKCwoDBAQBEgSgAQglCrwBCgQEBAIA
EgakAQKpAQQaqwEgUmVxdWlyZWQuIFRoZSBsb2NhdGlvbiB0byBjcmVhdGUgYW4KIFtTZWN1
cml0eVNldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3Vy
aXR5U2V0dGluZ3NdCiBmb3IuIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD5gLgoKDQoFBAQCAAUSBKQBAggKDQoFBAQCAAESBKQBCQ8KDQoF
BAQCAAMSBKQBEhMKDwoFBAQCAAgSBqQBFKkBAwoQCggEBAIACJwIABIEpQEEKgoRCgcEBAIA
CJ8IEgamAQSoAQUKPAoEBAQCARIGrAECrQEvGiwgUmVxdWlyZWQuIFRoZSBzZWN1cml0eSBz
ZXR0aW5ncyB0byBjcmVhdGUuCgoNCgUEBAIBBhIErAECEgoNCgUEBAIBARIErAETJAoNCgUE
BAIBAxIErAEnKAoNCgUEBAIBCBIErQEGLgoQCggEBAIBCJwIABIErQEHLQpUCgIEBRIGsQEA
vAEBGkYgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgW1NlY3VyaXR5U2V0dGluZ3MuRGVsZXRl
U2VjdXJpdHlTZXR0aW5nc11bXS4KCgsKAwQFARIEsQEIJQrfAQoEBAUCABIGtgECuwEEGs4B
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUKIFtTZWN1cml0eVNldHRpbmdzXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5U2V0dGluZ3NdIHRvCiBkZWxl
dGUuIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9u
SUQ+L3NlY3VyaXR5U2V0dGluZ3MvPFNlY3VyaXR5U2V0dGluZ3NJRD5gLgoKDQoFBAUCAAUS
BLYBAggKDQoFBAUCAAESBLYBCQ0KDQoFBAUCAAMSBLYBEBEKDwoFBAUCAAgSBrYBErsBAwoQ
CggEBQIACJwIABIEtwEEKgoRCgcEBQIACJ8IEga4AQS6AQUK2wEKAgQGEgbBAQCYAwEazAEg
UmVwcmVzZW50cyB0aGUgc2V0dGluZ3MgcmVsYXRlZCB0byBzZWN1cml0eSBpc3N1ZXMsIHN1
Y2ggYXMgZGF0YSByZWRhY3Rpb24KIGFuZCBkYXRhIHJldGVudGlvbi4gSXQgbWF5IHRha2Ug
aG91cnMgZm9yIHVwZGF0ZXMgb24gdGhlIHNldHRpbmdzIHRvCiBwcm9wYWdhdGUgdG8gYWxs
IHRoZSByZWxhdGVkIGNvbXBvbmVudHMgYW5kIHRha2UgZWZmZWN0LgoKCwoDBAYBEgTBAQgY
Cg0KAwQGBxIGwgECxQEECg8KBQQGB50IEgbCAQLFAQQKLQoEBAYEABIGyAECzgEDGh0gRGVm
aW5lcyBob3cgd2UgcmVkYWN0IGRhdGEuCgoNCgUEBgQAARIEyAEHGAogCgYEBgQAAgASBMoB
BCcaECBEbyBub3QgcmVkYWN0LgoKDwoHBAYEAAIAARIEygEEIgoPCgcEBgQAAgACEgTKASUm
Ck4KBgQGBAACARIEzQEEHBo+IENhbGwgcmVkYWN0aW9uIHNlcnZpY2UgdG8gY2xlYW4gdXAg
dGhlIGRhdGEgdG8gYmUgcGVyc2lzdGVkLgoKDwoHBAYEAAIBARIEzQEEFwoPCgcEBgQAAgEC
EgTNARobCjcKBAQGBAESBtEBAtkBAxonIERlZmluZXMgd2hhdCB0eXBlcyBvZiBkYXRhIHRv
IHJlZGFjdC4KCg0KBQQGBAEBEgTRAQcVCjAKBgQGBAECABIE0wEEJBogIERvbid0IHJlZGFj
dCBhbnkga2luZCBvZiBkYXRhLgoKDwoHBAYEAQIAARIE0wEEHwoPCgcEBgQBAgACEgTTASIj
CrwBCgYEBgQBAgESBNgBBBwaqwEgT24gZGF0YSB0byBiZSB3cml0dGVuIHRvIGRpc2sgb3Ig
c2ltaWxhciBkZXZpY2VzIHRoYXQgYXJlIGNhcGFibGUgb2YKIGhvbGRpbmcgZGF0YSBldmVu
IGlmIHBvd2VyIGlzIGRpc2Nvbm5lY3RlZC4gVGhpcyBpbmNsdWRlcyBkYXRhIHRoYXQgYXJl
CiB0ZW1wb3JhcmlseSBzYXZlZCBvbiBkaXNrLgoKDwoHBAYEAQIBARIE2AEEFwoPCgcEBgQB
AgECEgTYARobClkKBAQGBAISBtwBAuUBAxpJIERlZmluZXMgaG93IGxvbmcgd2UgcmV0YWlu
IHBlcnNpc3RlZCBkYXRhIHRoYXQgY29udGFpbnMgc2Vuc2l0aXZlIGluZm8uCgoNCgUEBgQC
ARIE3AEHGApaCgYEBgQCAgASBN4BBCcaSiBSZXRhaW5zIHRoZSBwZXJzaXN0ZWQgZGF0YSB3
aXRoIERpYWxvZ2Zsb3cncyBpbnRlcm5hbCBkZWZhdWx0IDM2NWQgVFRMcy4KCg8KBwQGBAIC
AAESBN4BBCIKDwoHBAYEAgIAAhIE3gElJgrxAQoGBAYEAgIBEgTkAQQiGuABIFJlbW92ZXMg
ZGF0YSB3aGVuIHRoZSBjb252ZXJzYXRpb24gZW5kcy4gSWYgdGhlcmUgaXMgbm8KIFtDb252
ZXJzYXRpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuQ29udmVyc2F0
aW9uXQogZXhwbGljaXRseSBlc3RhYmxpc2hlZCwgYSBkZWZhdWx0IGNvbnZlcnNhdGlvbiBl
bmRzIHdoZW4gdGhlCiBjb3JyZXNwb25kaW5nIERpYWxvZ2Zsb3cgc2Vzc2lvbiBlbmRzLgoK
DwoHBAYEAgIBARIE5AEEHQoPCgcEBgQCAgECEgTkASAhClAKBAQGBAMSBugBAu8BAxpAIFR5
cGUgb2YgZGF0YSB3ZSBwdXJnZSBhZnRlciByZXRlbnRpb24gc2V0dGluZ3MgdHJpZ2dlcnMg
cHVyZ2UuCgoNCgUEBgQDARIE6AEHFAoqCgYEBgQDAgASBOoBBCQaGiBVbnNwZWNpZmllZC4g
RG8gbm90IHVzZS4KCg8KBwQGBAMCAAESBOoBBB8KDwoHBAYEAwIAAhIE6gEiIwp4CgYEBgQD
AgESBO4BBBsaaCBEaWFsb2dmbG93IGhpc3RvcnkuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSBD
bG91ZCBsb2dnaW5nLCB3aGljaCBpcwogb3duZWQgYnkgdGhlIHVzZXIgLSBub3QgRGlhbG9n
Zmxvdy4KCg8KBwQGBAMCAQESBO4BBBYKDwoHBAYEAwIBAhIE7gEZGgovCgQEBgMAEgbyAQKc
AgMaHyBTZXR0aW5ncyBmb3IgZXhwb3J0aW5nIGF1ZGlvLgoKDQoFBAYDAAESBPIBCh0KYQoG
BAYDAAQAEgb1AQSBAgUaTyBGaWxlIGZvcm1hdCBmb3IgZXhwb3J0ZWQgYXVkaW8gZmlsZS4g
Q3VycmVudGx5IG9ubHkgaW4gdGVsZXBob255CiByZWNvcmRpbmdzLgoKDwoHBAYDAAQAARIE
9QEJFAosCggEBgMABAACABIE9wEGIxoaIFVuc3BlY2lmaWVkLiBEbyBub3QgdXNlLgoKEQoJ
BAYDAAQAAgABEgT3AQYeChEKCQQGAwAEAAIAAhIE9wEhIgo7CggEBgMABAACARIE+gEGEBop
IEcuNzExIG11LWxhdyBQQ00gd2l0aCA4a0h6IHNhbXBsZSByYXRlLgoKEQoJBAYDAAQAAgEB
EgT6AQYLChEKCQQGAwAEAAIBAhIE+gEODwokCggEBgMABAACAhIE/QEGDhoSIE1QMyBmaWxl
IGZvcm1hdC4KChEKCQQGAwAEAAICARIE/QEGCQoRCgkEBgMABAACAgISBP0BDA0KHwoIBAYD
AAQAAgMSBIACBg4aDSBPR0cgVm9yYmlzLgoKEQoJBAYDAAQAAgMBEgSAAgYJChEKCQQGAwAE
AAIDAhIEgAIMDQqNAgoGBAYDAAIAEgSIAgQaGvwBIENsb3VkIFN0b3JhZ2UgYnVja2V0IHRv
IGV4cG9ydCBhdWRpbyByZWNvcmQgdG8uCiBTZXR0aW5nIHRoaXMgZmllbGQgd291bGQgZ3Jh
bnQgdGhlIFN0b3JhZ2UgT2JqZWN0IENyZWF0b3Igcm9sZSB0bwogdGhlIERpYWxvZ2Zsb3cg
U2VydmljZSBBZ2VudC4KIEFQSSBjYWxsZXIgdGhhdCB0cmllcyB0byBtb2RpZnkgdGhpcyBm
aWVsZCBzaG91bGQgaGF2ZSB0aGUgcGVybWlzc2lvbiBvZgogc3RvcmFnZS5idWNrZXRzLnNl
dElhbVBvbGljeS4KCg8KBwQGAwACAAUSBIgCBAoKDwoHBAYDAAIAARIEiAILFQoPCgcEBgMA
AgADEgSIAhgZCvoBCgYEBgMAAgESBI4CBCQa6QEgRmlsZW5hbWUgcGF0dGVybiBmb3IgZXhw
b3J0ZWQgYXVkaW8uCiB7Y29udmVyc2F0aW9ufSBhbmQge3RpbWVzdGFtcH0gYXJlIHBsYWNl
aG9sZGVycyB0aGF0IHdpbGwgYmUgcmVwbGFjZWQKIHdpdGggdGhlIGNvbnZlcnNhdGlvbiBJ
RCBhbmQgZXBvY2ggbWljcm9zIG9mIHRoZSBjb252ZXJzYXRpb24uCiBGb3IgZXhhbXBsZSwg
Intjb252ZXJzYXRpb259L3JlY29yZGluZ197dGltZXN0YW1wfS5tdWxhdyIuCgoPCgcEBgMA
AgEFEgSOAgQKCg8KBwQGAwACAQESBI4CCx8KDwoHBAYDAAIBAxIEjgIiIwqlAQoGBAYDAAIC
EgSTAgQkGpQBIEVuYWJsZSBhdWRpbyByZWRhY3Rpb24gaWYgaXQgaXMgdHJ1ZS4KIE5vdGUg
dGhhdCB0aGlzIG9ubHkgcmVkYWN0cyBlbmQtdXNlciBhdWRpbyBkYXRhOwogU3ludGhlc2lz
ZWQgYXVkaW8gZnJvbSB0aGUgdmlydHVhbCBhZ2VudCBpcyBub3QgcmVkYWN0ZWQuCgoPCgcE
BgMAAgIFEgSTAgQICg8KBwQGAwACAgESBJMCCR8KDwoHBAYDAAICAxIEkwIiIwpfCgYEBgMA
AgMSBJcCBCEaTyBGaWxlIGZvcm1hdCBmb3IgZXhwb3J0ZWQgYXVkaW8gZmlsZS4gQ3VycmVu
dGx5IG9ubHkgaW4gdGVsZXBob255CiByZWNvcmRpbmdzLgoKDwoHBAYDAAIDBhIElwIEDwoP
CgcEBgMAAgMBEgSXAhAcCg8KBwQGAwACAwMSBJcCHyAKbAoGBAYDAAIEEgSbAgQdGlwgV2hl
dGhlciB0byBzdG9yZSBUVFMgYXVkaW8uIEJ5IGRlZmF1bHQsIFRUUyBhdWRpbyBmcm9tIHRo
ZSB2aXJ0dWFsIGFnZW50CiBpcyBub3QgZXhwb3J0ZWQuCgoPCgcEBgMAAgQFEgSbAgQICg8K
BwQGAwACBAESBJsCCRgKDwoHBAYDAAIEAxIEmwIbHAp9CgQEBgMBEgagAgKkAgMabSBTZXR0
aW5ncyBmb3IgZXhwb3J0aW5nIGNvbnZlcnNhdGlvbnMgdG8KIFtJbnNpZ2h0c10oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2NvbnRhY3QtY2VudGVyL2luc2lnaHRzL2RvY3MpLgoKDQoF
BAYDAQESBKACCiAKdwoGBAYDAQIAEgSjAgQkGmcgSWYgZW5hYmxlZCwgd2Ugd2lsbCBhdXRv
bWF0aWNhbGx5IGV4cG9ydHMKIGNvbnZlcnNhdGlvbnMgdG8gSW5zaWdodHMgYW5kIEluc2ln
aHRzIHJ1bnMgaXRzIGFuYWx5emVycy4KCg8KBwQGAwECAAUSBKMCBAgKDwoHBAYDAQIAARIE
owIJHwoPCgcEBgMBAgADEgSjAiIjCtUDCgQEBgIAEgStAgISGsYDIFJlc291cmNlIG5hbWUg
b2YgdGhlIHNldHRpbmdzLgogUmVxdWlyZWQgZm9yIHRoZQogW1NlY3VyaXR5U2V0dGluZ3NT
ZXJ2aWNlLlVwZGF0ZVNlY3VyaXR5U2V0dGluZ3NdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5nc1NlcnZpY2UuVXBkYXRlU2VjdXJpdHlTZXR0
aW5nc10KIG1ldGhvZC4KIFtTZWN1cml0eVNldHRpbmdzU2VydmljZS5DcmVhdGVTZWN1cml0
eVNldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlY3VyaXR5
U2V0dGluZ3NTZXJ2aWNlLkNyZWF0ZVNlY3VyaXR5U2V0dGluZ3NdCiBwb3B1bGF0ZXMgdGhl
IG5hbWUgYXV0b21hdGljYWxseS4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb25JRD4vc2VjdXJpdHlTZXR0aW5ncy88U2VjdXJpdHlTZXR0aW5n
c0lEPmAuCgoNCgUEBgIABRIErQICCAoNCgUEBgIAARIErQIJDQoNCgUEBgIAAxIErQIQEQpo
CgQEBgIBEgSxAgJDGlogUmVxdWlyZWQuIFRoZSBodW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRo
ZSBzZWN1cml0eSBzZXR0aW5ncywgdW5pcXVlIHdpdGhpbgogdGhlIGxvY2F0aW9uLgoKDQoF
BAYCAQUSBLECAggKDQoFBAYCAQESBLECCRUKDQoFBAYCAQMSBLECGBkKDQoFBAYCAQgSBLEC
GkIKEAoIBAYCAQicCAASBLECG0EKOgoEBAYCAhIEtAICKxosIFN0cmF0ZWd5IHRoYXQgZGVm
aW5lcyBob3cgd2UgZG8gcmVkYWN0aW9uLgoKDQoFBAYCAgYSBLQCAhMKDQoFBAYCAgESBLQC
FCYKDQoFBAYCAgMSBLQCKSoKqwEKBAQGAgMSBLkCAiUanAEgRGVmaW5lcyB0aGUgZGF0YSBm
b3Igd2hpY2ggRGlhbG9nZmxvdyBhcHBsaWVzIHJlZGFjdGlvbi4gRGlhbG9nZmxvdyBkb2Vz
CiBub3QgcmVkYWN0IGRhdGEgdGhhdCBpdCBkb2VzIG5vdCBoYXZlIGFjY2VzcyB0byDigJMg
Zm9yIGV4YW1wbGUsIENsb3VkCiBsb2dnaW5nLgoKDQoFBAYCAwYSBLkCAhAKDQoFBAYCAwES
BLkCESAKDQoFBAYCAwMSBLkCIyQKzQUKBAQGAgQSBswCAs4CBRq8BSBbRExQXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vZGxwL2RvY3MpIGluc3BlY3QgdGVtcGxhdGUgbmFtZS4gVXNl
IHRoaXMKIHRlbXBsYXRlIHRvIGRlZmluZSBpbnNwZWN0IGJhc2Ugc2V0dGluZ3MuCgogVGhl
IGBETFAgSW5zcGVjdCBUZW1wbGF0ZXMgUmVhZGVyYCByb2xlIGlzIG5lZWRlZCBvbiB0aGUg
RGlhbG9nZmxvdwogc2VydmljZSBpZGVudGl0eSBzZXJ2aWNlIGFjY291bnQgKGhhcyB0aGUg
Zm9ybQogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJAZ2NwLXNhLWRpYWxvZ2Zsb3cuaWFtLmdz
ZXJ2aWNlYWNjb3VudC5jb21gKQogZm9yIHlvdXIgYWdlbnQncyBwcm9qZWN0LgoKIElmIGVt
cHR5LCB3ZSB1c2UgdGhlIGRlZmF1bHQgRExQIGluc3BlY3QgY29uZmlnLgoKIFRoZSB0ZW1w
bGF0ZSBuYW1lIHdpbGwgaGF2ZSBvbmUgb2YgdGhlIGZvbGxvd2luZyBmb3JtYXRzOgogYHBy
b2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vaW5zcGVjdFRlbXBs
YXRlcy88VGVtcGxhdGVJRD5gCiBPUgogYG9yZ2FuaXphdGlvbnMvPE9yZ2FuaXphdGlvbklE
Pi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2luc3BlY3RUZW1wbGF0ZXMvPFRlbXBsYXRlSUQ+
YAoKIE5vdGU6IGBpbnNwZWN0X3RlbXBsYXRlYCBtdXN0IGJlIGxvY2F0ZWQgaW4gdGhlIHNh
bWUgcmVnaW9uIGFzIHRoZQogYFNlY3VyaXR5U2V0dGluZ3NgLgoKDQoFBAYCBAUSBMwCAggK
DQoFBAYCBAESBMwCCRkKDQoFBAYCBAMSBMwCHB0KDwoFBAYCBAgSBswCHs4CBAoRCgcEBgIE
CJ8IEgbMAh/OAgMKiwYKBAQGAgUSBuECAuMCBRr6BSBbRExQXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vZGxwL2RvY3MpIGRlaWRlbnRpZnkgdGVtcGxhdGUgbmFtZS4gVXNlIHRoaXMK
IHRlbXBsYXRlIHRvIGRlZmluZSBkZS1pZGVudGlmaWNhdGlvbiBjb25maWd1cmF0aW9uIGZv
ciB0aGUgY29udGVudC4KCiBUaGUgYERMUCBEZS1pZGVudGlmeSBUZW1wbGF0ZXMgUmVhZGVy
YCByb2xlIGlzIG5lZWRlZCBvbiB0aGUgRGlhbG9nZmxvdwogc2VydmljZSBpZGVudGl0eSBz
ZXJ2aWNlIGFjY291bnQgKGhhcyB0aGUgZm9ybQogYHNlcnZpY2UtUFJPSkVDVF9OVU1CRVJA
Z2NwLXNhLWRpYWxvZ2Zsb3cuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gKQogZm9yIHlvdXIg
YWdlbnQncyBwcm9qZWN0LgoKIElmIGVtcHR5LCBEaWFsb2dmbG93IHJlcGxhY2VzIHNlbnNp
dGl2ZSBpbmZvIHdpdGggYFtyZWRhY3RlZF1gIHRleHQuCgogVGhlIHRlbXBsYXRlIG5hbWUg
d2lsbCBoYXZlIG9uZSBvZiB0aGUgZm9sbG93aW5nIGZvcm1hdHM6CiBgcHJvamVjdHMvPFBy
b2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9kZWlkZW50aWZ5VGVtcGxhdGVzLzxU
ZW1wbGF0ZUlEPmAKIE9SCiBgb3JnYW5pemF0aW9ucy88T3JnYW5pemF0aW9uSUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD4vZGVpZGVudGlmeVRlbXBsYXRlcy88VGVtcGxhdGVJRD5gCgog
Tm90ZTogYGRlaWRlbnRpZnlfdGVtcGxhdGVgIG11c3QgYmUgbG9jYXRlZCBpbiB0aGUgc2Ft
ZSByZWdpb24gYXMgdGhlCiBgU2VjdXJpdHlTZXR0aW5nc2AuCgoNCgUEBgIFBRIE4QICCAoN
CgUEBgIFARIE4QIJHAoNCgUEBgIFAxIE4QIfIQoPCgUEBgIFCBIG4QIi4wIEChEKBwQGAgUI
nwgSBuECI+MCAwrKAQoEBAYIABIG6AIC+AIDGrkBIFNwZWNpZmllcyBob3cgZGF0YSBpcyBy
ZXRhaW5lZC4gTm90ZSB0aGF0IGV2ZW4gaWYgdGhlIGRhdGEgaXMKIHB1cmdlZCBkdWUgdG8g
cmV0ZW50aW9uIHBvbGljeSwgd2UgbWF5IHN0aWxsIGhvbGQgaXQgaW4gYmFja3VwIHN0b3Jh
Z2UgZm9yCiBhIGZldyBkYXlzIHdpdGhvdXQgYWxsb3dpbmcgZGlyZWN0IHJlYWRpbmdzLgoK
DQoFBAYIAAESBOgCCBYK1wQKBAQGAgYSBPMCBCQayAQgUmV0YWlucyBkYXRhIGluIGludGVy
YWN0aW9uIGxvZ2dpbmcgZm9yIHRoZSBzcGVjaWZpZWQgbnVtYmVyIG9mIGRheXMuCiBUaGlz
IGRvZXMgbm90IGFwcGx5IHRvIENsb3VkIGxvZ2dpbmcsIHdoaWNoIGlzIG93bmVkIGJ5IHRo
ZSB1c2VyIC0gbm90CiBEaWFsb2dmbG93LgogVXNlciBtdXN0IHNldCBhIHZhbHVlIGxvd2Vy
IHRoYW4gRGlhbG9nZmxvdydzIGRlZmF1bHQgMzY1ZCBUVEwgKDMwIGRheXMKIGZvciBBZ2Vu
dCBBc3Npc3QgdHJhZmZpYyksIGhpZ2hlciB2YWx1ZSB3aWxsIGJlIGlnbm9yZWQgYW5kIHVz
ZSBkZWZhdWx0LgogU2V0dGluZyBhIHZhbHVlIGhpZ2hlciB0aGFuIHRoYXQgaGFzIG5vIGVm
ZmVjdC4gQSBtaXNzaW5nIHZhbHVlIG9yCiBzZXR0aW5nIHRvIDAgYWxzbyBtZWFucyB3ZSB1
c2UgZGVmYXVsdCBUVEwuCiBXaGVuIGRhdGEgcmV0ZW50aW9uIGNvbmZpZ3VyYXRpb24gaXMg
Y2hhbmdlZCwgaXQgb25seSBhcHBsaWVzIHRvIHRoZSBkYXRhCiBjcmVhdGVkIGFmdGVyIHRo
ZSBjaGFuZ2U7IHRoZSBUVEwgb2YgZXhpc3RpbmcgZGF0YSBjcmVhdGVkIGJlZm9yZSB0aGUK
IGNoYW5nZSBzdGF5cyBpbnRhY3QuCgoNCgUEBgIGBRIE8wIECQoNCgUEBgIGARIE8wIKHwoN
CgUEBgIGAxIE8wIiIwqqAQoEBAYCBxIE9wIELRqbASBTcGVjaWZpZXMgdGhlIHJldGVudGlv
biBiZWhhdmlvciBkZWZpbmVkIGJ5CiBbU2VjdXJpdHlTZXR0aW5ncy5SZXRlbnRpb25TdHJh
dGVneV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZWN1cml0eVNldHRp
bmdzLlJldGVudGlvblN0cmF0ZWd5XS4KCg0KBQQGAgcGEgT3AgQVCg0KBQQGAgcBEgT3AhYo
Cg0KBQQGAgcDEgT3AissClcKBAQGAggSBPsCAi4aSSBMaXN0IG9mIHR5cGVzIG9mIGRhdGEg
dG8gcmVtb3ZlIHdoZW4gcmV0ZW50aW9uIHNldHRpbmdzIHRyaWdnZXJzIHB1cmdlLgoKDQoF
BAYCCAQSBPsCAgoKDQoFBAYCCAYSBPsCCxgKDQoFBAYCCAESBPsCGSkKDQoFBAYCCAMSBPsC
LC0KxgYKBAQGAgkSBI4DAjEatwYgQ29udHJvbHMgYXVkaW8gZXhwb3J0IHNldHRpbmdzIGZv
ciBwb3N0LWNvbnZlcnNhdGlvbiBhbmFseXRpY3Mgd2hlbgogaW5nZXN0aW5nIGF1ZGlvIHRv
IGNvbnZlcnNhdGlvbnMgdmlhIFtQYXJ0aWNpcGFudHMuQW5hbHl6ZUNvbnRlbnRdW10gb3IK
IFtQYXJ0aWNpcGFudHMuU3RyZWFtaW5nQW5hbHl6ZUNvbnRlbnRdW10uCgogSWYKIFtyZXRl
bnRpb25fc3RyYXRlZ3ldW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2Vj
dXJpdHlTZXR0aW5ncy5yZXRlbnRpb25fc3RyYXRlZ3ldCiBpcyBzZXQgdG8gUkVNT1ZFX0FG
VEVSX0NPTlZFUlNBVElPTiBvciBbYXVkaW9fZXhwb3J0X3NldHRpbmdzLmdjc19idWNrZXRd
W10KIGlzIGVtcHR5LCBhdWRpbyBleHBvcnQgaXMgZGlzYWJsZWQuCgogSWYgYXVkaW8gZXhw
b3J0IGlzIGVuYWJsZWQsIGF1ZGlvIGlzIHJlY29yZGVkIGFuZCBzYXZlZCB0bwogW2F1ZGlv
X2V4cG9ydF9zZXR0aW5ncy5nY3NfYnVja2V0XVtdLCBzdWJqZWN0IHRvIHJldGVudGlvbiBw
b2xpY3kgb2YKIFthdWRpb19leHBvcnRfc2V0dGluZ3MuZ2NzX2J1Y2tldF1bXS4KCiBUaGlz
IHNldHRpbmcgd29uJ3QgZWZmZWN0IGF1ZGlvIGlucHV0IGZvciBpbXBsaWNpdCBzZXNzaW9u
cyB2aWEKIFtTZXNzaW9ucy5EZXRlY3RJbnRlbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuU2Vzc2lvbnMuRGV0ZWN0SW50ZW50XQogb3IKIFtTZXNzaW9ucy5TdHJl
YW1pbmdEZXRlY3RJbnRlbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEu
U2Vzc2lvbnMuU3RyZWFtaW5nRGV0ZWN0SW50ZW50XS4KCg0KBQQGAgkGEgSOAwIVCg0KBQQG
AgkBEgSOAxYrCg0KBQQGAgkDEgSOAy4wCrACCgQEBgIKEgSXAwI3GqECIENvbnRyb2xzIGNv
bnZlcnNhdGlvbiBleHBvcnRpbmcgc2V0dGluZ3MgdG8gSW5zaWdodHMgYWZ0ZXIgY29udmVy
c2F0aW9uIGlzCiBjb21wbGV0ZWQuCgogSWYKIFtyZXRlbnRpb25fc3RyYXRlZ3ldW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU2VjdXJpdHlTZXR0aW5ncy5yZXRlbnRp
b25fc3RyYXRlZ3ldCiBpcyBzZXQgdG8gUkVNT1ZFX0FGVEVSX0NPTlZFUlNBVElPTiwgSW5z
aWdodHMgZXhwb3J0IGlzIGRpc2FibGVkIG5vIG1hdHRlcgogd2hhdCB5b3UgY29uZmlndXJl
IGhlcmUuCgoNCgUEBgIKBhIElwMCGAoNCgUEBgIKARIElwMZMQoNCgUEBgIKAxIElwM0NmIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::GetSecuritySettingsRequest ===
    # Fields for GetSecuritySettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::UpdateSecuritySettingsRequest ===
    # Fields for UpdateSecuritySettingsRequest
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsRequest ===
    # Fields for ListSecuritySettingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsResponse ===
    # Fields for ListSecuritySettingsResponse
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::CreateSecuritySettingsRequest ===
    # Fields for CreateSecuritySettingsRequest
    # Field: parent Type: 9 ()
    # Field: security_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::DeleteSecuritySettingsRequest ===
    # Fields for DeleteSecuritySettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings ===
    # Fields for SecuritySettings
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: redaction_strategy Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.RedactionStrategy)
    # Field: redaction_scope Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.RedactionScope)
    # Field: inspect_template Type: 9 ()
    # Field: deidentify_template Type: 9 ()
    # Field: retention_window_days Type: 5 ()
    # Field: retention_strategy Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.RetentionStrategy)
    # Field: purge_data_types Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.PurgeDataType)
    # Field: audio_export_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.AudioExportSettings)
    # Field: insights_export_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SecuritySettings.InsightsExportSettings)

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

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettingsServiceClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettingsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettingsServiceClient

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
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::CreateSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'CreateSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings',
    });
}

sub get_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::GetSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'GetSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings',
    });
}

sub update_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::UpdateSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'UpdateSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings',
    });
}

sub list_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'ListSecuritySettings',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsResponse',
    });
}

sub delete_security_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::DeleteSecuritySettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService',
        method         => 'DeleteSecuritySettings',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/security_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::GetSecuritySettingsRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::GetSecuritySettingsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/security_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::GetSecuritySettingsRequest

The request message for
[SecuritySettingsService.GetSecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService.GetSecuritySettings].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the settings.
Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<securitysettingsID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::UpdateSecuritySettingsRequest

The request message for
[SecuritySettingsService.UpdateSecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService.UpdateSecuritySettings].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings>)

Required. [SecuritySettings] object that contains values for each of the
fields to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsRequest

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::ListSecuritySettingsResponse

The response message for [SecuritySettings.ListSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings>)

The list of security settings.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::CreateSecuritySettingsRequest

The request message for [SecuritySettings.CreateSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create an
[SecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettings]
for. Format: `projects/<ProjectID>/locations/<LocationID>`.

=item * C<< $msg->security_settings() >> / C<< $msg->security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings>)

Required. The security settings to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::DeleteSecuritySettingsRequest

The request message for [SecuritySettings.DeleteSecuritySettings][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[SecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettings] to
delete. Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<SecuritySettingsID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings

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
[SecuritySettingsService.UpdateSecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService.UpdateSecuritySettings]
method.
[SecuritySettingsService.CreateSecuritySettings][google.cloud.dialogflow.cx.v3beta1.SecuritySettingsService.CreateSecuritySettings]
populates the name automatically. Format:
`projects/<ProjectID>/locations/<LocationID>/securitySettings/<SecuritySettingsID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the security settings, unique within
the location.

=item * C<< $msg->redaction_strategy() >> / C<< $msg->redaction_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::RedactionStrategy>)

Strategy that defines how we do redaction.

=item * C<< $msg->redaction_scope() >> / C<< $msg->redaction_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::RedactionScope>)

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

Retains data in interaction logging for the specified number of days.
This does not apply to Cloud logging, which is owned by the user - not
Dialogflow.
User must set a value lower than Dialogflow's default 365d TTL (30 days
for Agent Assist traffic), higher value will be ignored and use default.
Setting a value higher than that has no effect. A missing value or
setting to 0 also means we use default TTL.
When data retention configuration is changed, it only applies to the data
created after the change; the TTL of existing data created before the
change stays intact.

=item * C<< $msg->retention_strategy() >> / C<< $msg->retention_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::RetentionStrategy>)

Specifies the retention behavior defined by
[SecuritySettings.RetentionStrategy][google.cloud.dialogflow.cx.v3beta1.SecuritySettings.RetentionStrategy].

=item * C<< $msg->purge_data_types() >> / C<< $msg->purge_data_types($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::PurgeDataType>)

List of types of data to remove when retention settings triggers purge.

=item * C<< $msg->audio_export_settings() >> / C<< $msg->audio_export_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings::AudioExportSettings>)

Controls audio export settings for post-conversation analytics when
ingesting audio to conversations via [Participants.AnalyzeContent][] or
[Participants.StreamingAnalyzeContent][].

If
[retention_strategy][google.cloud.dialogflow.cx.v3beta1.SecuritySettings.retention_strategy]
is set to REMOVE_AFTER_CONVERSATION or [audio_export_settings.gcs_bucket][]
is empty, audio export is disabled.

If audio export is enabled, audio is recorded and saved to
[audio_export_settings.gcs_bucket][], subject to retention policy of
[audio_export_settings.gcs_bucket][].

This setting won't effect audio input for implicit sessions via
[Sessions.DetectIntent][google.cloud.dialogflow.cx.v3beta1.Sessions.DetectIntent]
or
[Sessions.StreamingDetectIntent][google.cloud.dialogflow.cx.v3beta1.Sessions.StreamingDetectIntent].

=item * C<< $msg->insights_export_settings() >> / C<< $msg->insights_export_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::SecuritySettings::InsightsExportSettings>)

Controls conversation exporting settings to Insights after conversation is
completed.

If
[retention_strategy][google.cloud.dialogflow.cx.v3beta1.SecuritySettings.retention_strategy]
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
