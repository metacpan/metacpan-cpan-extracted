package Google::Cloud::Billing::Budgets::V1beta1::BudgetService;

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
    eval { require Google::Cloud::Billing::Budgets::V1beta1::BudgetModel };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvYmlsbGluZy9idWRnZXRzL3YxYmV0YTEvYnVkZ2V0X3NlcnZpY2Uu
cHJvdG8SJGdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMRocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aN2dv
b2dsZS9jbG91ZC9iaWxsaW5nL2J1ZGdldHMvdjFiZXRhMS9idWRnZXRfbW9kZWwucHJvdG8a
G2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21h
c2sucHJvdG8ipgEKE0NyZWF0ZUJ1ZGdldFJlcXVlc3QSRAoGcGFyZW50GAEgASgJQizgQQL6
QSYSJGJpbGxpbmdidWRnZXRzLmdvb2dsZWFwaXMuY29tL0J1ZGdldFIGcGFyZW50EkkKBmJ1
ZGdldBgCIAEoCzIsLmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5CdWRn
ZXRCA+BBAlIGYnVkZ2V0IqIBChNVcGRhdGVCdWRnZXRSZXF1ZXN0EkkKBmJ1ZGdldBgBIAEo
CzIsLmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5CdWRnZXRCA+BBAlIG
YnVkZ2V0EkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EEBUgp1cGRhdGVNYXNrIlQKEEdldEJ1ZGdldFJlcXVlc3QSQAoEbmFtZRgBIAEoCUIs
4EEC+kEmCiRiaWxsaW5nYnVkZ2V0cy5nb29nbGVhcGlzLmNvbS9CdWRnZXRSBG5hbWUiuwEK
Ekxpc3RCdWRnZXRzUmVxdWVzdBJECgZwYXJlbnQYASABKAlCLOBBAvpBJhIkYmlsbGluZ2J1
ZGdldHMuZ29vZ2xlYXBpcy5jb20vQnVkZ2V0UgZwYXJlbnQSGQoFc2NvcGUYBCABKAlCA+BB
AVIFc2NvcGUSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9r
ZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIoUBChNMaXN0QnVkZ2V0c1Jlc3BvbnNlEkYKB2J1
ZGdldHMYASADKAsyLC5nb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuQnVk
Z2V0UgdidWRnZXRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJX
ChNEZWxldGVCdWRnZXRSZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokYmlsbGluZ2J1
ZGdldHMuZ29vZ2xlYXBpcy5jb20vQnVkZ2V0UgRuYW1lMvcHCg1CdWRnZXRTZXJ2aWNlEq8B
CgxDcmVhdGVCdWRnZXQSOS5nb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEu
Q3JlYXRlQnVkZ2V0UmVxdWVzdBosLmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFi
ZXRhMS5CdWRnZXQiNoLT5JMCMCIrL3YxYmV0YTEve3BhcmVudD1iaWxsaW5nQWNjb3VudHMv
Kn0vYnVkZ2V0czoBKhK2AQoMVXBkYXRlQnVkZ2V0EjkuZ29vZ2xlLmNsb3VkLmJpbGxpbmcu
YnVkZ2V0cy52MWJldGExLlVwZGF0ZUJ1ZGdldFJlcXVlc3QaLC5nb29nbGUuY2xvdWQuYmls
bGluZy5idWRnZXRzLnYxYmV0YTEuQnVkZ2V0Ij2C0+STAjcyMi92MWJldGExL3tidWRnZXQu
bmFtZT1iaWxsaW5nQWNjb3VudHMvKi9idWRnZXRzLyp9OgEqEqYBCglHZXRCdWRnZXQSNi5n
b29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuR2V0QnVkZ2V0UmVxdWVzdBos
Lmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5CdWRnZXQiM4LT5JMCLRIr
L3YxYmV0YTEve25hbWU9YmlsbGluZ0FjY291bnRzLyovYnVkZ2V0cy8qfRK3AQoLTGlzdEJ1
ZGdldHMSOC5nb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuTGlzdEJ1ZGdl
dHNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52MWJldGExLkxpc3RC
dWRnZXRzUmVzcG9uc2UiM4LT5JMCLRIrL3YxYmV0YTEve3BhcmVudD1iaWxsaW5nQWNjb3Vu
dHMvKn0vYnVkZ2V0cxKWAQoMRGVsZXRlQnVkZ2V0EjkuZ29vZ2xlLmNsb3VkLmJpbGxpbmcu
YnVkZ2V0cy52MWJldGExLkRlbGV0ZUJ1ZGdldFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiM4LT5JMCLSorL3YxYmV0YTEve25hbWU9YmlsbGluZ0FjY291bnRzLyovYnVkZ2V0
cy8qfRp/ykEdYmlsbGluZ2J1ZGdldHMuZ29vZ2xlYXBpcy5jb23SQVxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLWJpbGxpbmcsaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJwCihjb20uZ29vZ2xlLmNsb3VkLmJpbGxpbmcu
YnVkZ2V0cy52MWJldGExUAFaQmNsb3VkLmdvb2dsZS5jb20vZ28vYmlsbGluZy9idWRnZXRz
L2FwaXYxYmV0YTEvYnVkZ2V0c3BiO2J1ZGdldHNwYkqhLQoHEgUOALgBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEEKCQoCAwUSAxcAJQoJCgIDBhID
GAAqCggKAQgSAxoAWQoJCgIICxIDGgBZCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwA
QQoJCgIIARIDHABBCpABCgIGABIEIABaARqDASBCdWRnZXRTZXJ2aWNlIHN0b3JlcyBDbG91
ZCBCaWxsaW5nIGJ1ZGdldHMsIHdoaWNoIGRlZmluZSBhCiBidWRnZXQgcGxhbiBhbmQgcnVs
ZXMgdG8gZXhlY3V0ZSBhcyB3ZSB0cmFjayBzcGVuZCBhZ2FpbnN0IHRoYXQgcGxhbi4KCgoK
AwYAARIDIAgVCgoKAwYAAxIDIQJFCgwKBQYAA5kIEgMhAkUKCwoDBgADEgQiAiQ3Cg0KBQYA
A5oIEgQiAiQ3CrUBCgQGAAIAEgQpAi4DGqYBIENyZWF0ZXMgYSBuZXcgYnVkZ2V0LiBTZWUK
IFtRdW90YXMgYW5kIGxpbWl0c10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpbGxpbmcv
cXVvdGFzKQogZm9yIG1vcmUgaW5mb3JtYXRpb24gb24gdGhlIGxpbWl0cyBvZiB0aGUgbnVt
YmVyIG9mIGJ1ZGdldHMgeW91IGNhbiBjcmVhdGUuCgoMCgUGAAIAARIDKQYSCgwKBQYAAgAC
EgMpEyYKDAoFBgACAAMSAykxNwoNCgUGAAIABBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYK
/gEKBAYAAgESBDUCOgMa7wEgVXBkYXRlcyBhIGJ1ZGdldCBhbmQgcmV0dXJucyB0aGUgdXBk
YXRlZCBidWRnZXQuCgogV0FSTklORzogVGhlcmUgYXJlIHNvbWUgZmllbGRzIGV4cG9zZWQg
b24gdGhlIEdvb2dsZSBDbG91ZCBDb25zb2xlIHRoYXQKIGFyZW4ndCBhdmFpbGFibGUgb24g
dGhpcyBBUEkuIEJ1ZGdldCBmaWVsZHMgdGhhdCBhcmUgbm90IGV4cG9zZWQgaW4KIHRoaXMg
QVBJIHdpbGwgbm90IGJlIGNoYW5nZWQgYnkgdGhpcyBtZXRob2QuCgoMCgUGAAIBARIDNQYS
CgwKBQYAAgECEgM1EyYKDAoFBgACAQMSAzUxNwoNCgUGAAIBBBIENgQ5BgoRCgkGAAIBBLDK
vCISBDYEOQYKjwIKBAYAAgISBEICRgMagAIgUmV0dXJucyBhIGJ1ZGdldC4KCiBXQVJOSU5H
OiBUaGVyZSBhcmUgc29tZSBmaWVsZHMgZXhwb3NlZCBvbiB0aGUgR29vZ2xlIENsb3VkIENv
bnNvbGUgdGhhdAogYXJlbid0IGF2YWlsYWJsZSBvbiB0aGlzIEFQSS4gV2hlbiByZWFkaW5n
IGZyb20gdGhlIEFQSSwgeW91IHdpbGwgbm90CiBzZWUgdGhlc2UgZmllbGRzIGluIHRoZSBy
ZXR1cm4gdmFsdWUsIHRob3VnaCB0aGV5IG1heSBoYXZlIGJlZW4gc2V0CiBpbiB0aGUgQ2xv
dWQgQ29uc29sZS4KCgwKBQYAAgIBEgNCBg8KDAoFBgACAgISA0IQIAoMCgUGAAICAxIDQisx
Cg0KBQYAAgIEEgRDBEUGChEKCQYAAgIEsMq8IhIEQwRFBgquAgoEBgACAxIETgJSAxqfAiBS
ZXR1cm5zIGEgbGlzdCBvZiBidWRnZXRzIGZvciBhIGJpbGxpbmcgYWNjb3VudC4KCiBXQVJO
SU5HOiBUaGVyZSBhcmUgc29tZSBmaWVsZHMgZXhwb3NlZCBvbiB0aGUgR29vZ2xlIENsb3Vk
IENvbnNvbGUgdGhhdAogYXJlbid0IGF2YWlsYWJsZSBvbiB0aGlzIEFQSS4gV2hlbiByZWFk
aW5nIGZyb20gdGhlIEFQSSwgeW91IHdpbGwgbm90CiBzZWUgdGhlc2UgZmllbGRzIGluIHRo
ZSByZXR1cm4gdmFsdWUsIHRob3VnaCB0aGV5IG1heSBoYXZlIGJlZW4gc2V0CiBpbiB0aGUg
Q2xvdWQgQ29uc29sZS4KCgwKBQYAAgMBEgNOBhEKDAoFBgACAwISA04SJAoMCgUGAAIDAxID
Ti9CCg0KBQYAAgMEEgRPBFEGChEKCQYAAgMEsMq8IhIETwRRBgpKCgQGAAIEEgRVAlkDGjwg
RGVsZXRlcyBhIGJ1ZGdldC4gUmV0dXJucyBzdWNjZXNzZnVsbHkgaWYgYWxyZWFkeSBkZWxl
dGVkLgoKDAoFBgACBAESA1UGEgoMCgUGAAIEAhIDVRMmCgwKBQYAAgQDEgNVMUYKDQoFBgAC
BAQSBFYEWAYKEQoJBgACBASwyrwiEgRWBFgGCiYKAgQAEgRdAGkBGhogUmVxdWVzdCBmb3Ig
Q3JlYXRlQnVkZ2V0CgoKCgMEAAESA10IGwqRAQoEBAACABIEYAJlBBqCASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIGJpbGxpbmcgYWNjb3VudCB0byBjcmVhdGUgdGhlIGJ1ZGdldCBp
bi4gVmFsdWVzCiBhcmUgb2YgdGhlIGZvcm0gYGJpbGxpbmdBY2NvdW50cy97YmlsbGluZ0Fj
Y291bnRJZH1gLgoKDAoFBAACAAUSA2ACCAoMCgUEAAIAARIDYAkPCgwKBQQAAgADEgNgEhMK
DQoFBAACAAgSBGAUZQMKDwoIBAACAAicCAASA2EEKgoPCgcEAAIACJ8IEgRiBGQFCioKBAQA
AgESA2gCPRodIFJlcXVpcmVkLiBCdWRnZXQgdG8gY3JlYXRlLgoKDAoFBAACAQYSA2gCCAoM
CgUEAAIBARIDaAkPCgwKBQQAAgEDEgNoEhMKDAoFBAACAQgSA2gUPAoPCggEAAIBCJwIABID
aBU7CiYKAgQBEgRsAHkBGhogUmVxdWVzdCBmb3IgVXBkYXRlQnVkZ2V0CgoKCgMEAQESA2wI
Gwp4CgQEAQIAEgNvAj0aayBSZXF1aXJlZC4gVGhlIHVwZGF0ZWQgYnVkZ2V0IG9iamVjdC4K
IFRoZSBidWRnZXQgdG8gdXBkYXRlIGlzIHNwZWNpZmllZCBieSB0aGUgYnVkZ2V0IG5hbWUg
aW4gdGhlIGJ1ZGdldC4KCgwKBQQBAgAGEgNvAggKDAoFBAECAAESA28JDwoMCgUEAQIAAxID
bxITCgwKBQQBAgAIEgNvFDwKDwoIBAECAAicCAASA28VOwrbAgoEBAECARIEdwJ4LxrMAiBP
cHRpb25hbC4gSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQgYnVkZ2V0
IHRvIHVwZGF0ZS4KIFJlYWQtb25seSBmaWVsZHMgKHN1Y2ggYXMgYG5hbWVgKSBjYW5ub3Qg
YmUgY2hhbmdlZC4gSWYgdGhpcyBpcyBub3QKIHByb3ZpZGVkLCB0aGVuIG9ubHkgZmllbGRz
IHdpdGggbm9uLWRlZmF1bHQgdmFsdWVzIGZyb20gdGhlIHJlcXVlc3QgYXJlCiB1cGRhdGVk
LiBTZWUKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMv
ZG9jcy9wcm90bzMjZGVmYXVsdCBmb3IgbW9yZQogZGV0YWlscyBhYm91dCBkZWZhdWx0IHZh
bHVlcy4KCgwKBQQBAgEGEgN3AhsKDAoFBAECAQESA3ccJwoMCgUEAQIBAxIDdyorCgwKBQQB
AgEIEgN4Bi4KDwoIBAECAQicCAASA3gHLQokCgIEAhIFfACFAQEaFyBSZXF1ZXN0IGZvciBH
ZXRCdWRnZXQKCgoKAwQCARIDfAgYCoIBCgQEAgIAEgV/AoQBBBpzIFJlcXVpcmVkLiBOYW1l
IG9mIGJ1ZGdldCB0byBnZXQuIFZhbHVlcyBhcmUgb2YgdGhlIGZvcm0KIGBiaWxsaW5nQWNj
b3VudHMve2JpbGxpbmdBY2NvdW50SWR9L2J1ZGdldHMve2J1ZGdldElkfWAuCgoMCgUEAgIA
BRIDfwIICgwKBQQCAgABEgN/CQ0KDAoFBAICAAMSA38QEQoOCgUEAgIACBIFfxKEAQMKEAoI
BAICAAicCAASBIABBCoKEQoHBAICAAifCBIGgQEEgwEFCicKAgQDEgaIAQCiAQEaGSBSZXF1
ZXN0IGZvciBMaXN0QnVkZ2V0cwoKCwoDBAMBEgSIAQgaCogBCgQEAwIAEgaLAQKQAQQaeCBS
ZXF1aXJlZC4gTmFtZSBvZiBiaWxsaW5nIGFjY291bnQgdG8gbGlzdCBidWRnZXRzIHVuZGVy
LiBWYWx1ZXMKIGFyZSBvZiB0aGUgZm9ybSBgYmlsbGluZ0FjY291bnRzL3tiaWxsaW5nQWNj
b3VudElkfWAuCgoNCgUEAwIABRIEiwECCAoNCgUEAwIAARIEiwEJDwoNCgUEAwIAAxIEiwES
EwoPCgUEAwIACBIGiwEUkAEDChAKCAQDAgAInAgAEgSMAQQqChEKBwQDAgAInwgSBo0BBI8B
BQrOAwoEBAMCARIEmAECPBq/AyBPcHRpb25hbC4gU2V0IHRoZSBzY29wZSBvZiB0aGUgYnVk
Z2V0cyB0byBiZSByZXR1cm5lZCwgaW4gdGhlIGZvcm1hdCBvZiB0aGUKIHJlc291cmNlIG5h
bWUuIFRoZSBzY29wZSBvZiBhIGJ1ZGdldCBpcyB0aGUgY29zdCB0aGF0IGl0IHRyYWNrcywg
c3VjaCBhcwogY29zdHMgZm9yIGEgc2luZ2xlIHByb2plY3QsIG9yIHRoZSBjb3N0cyBmb3Ig
YWxsIHByb2plY3RzIGluIGEgZm9sZGVyLiBPbmx5CiBwcm9qZWN0IHNjb3BlIChpbiB0aGUg
Zm9ybWF0IG9mICJwcm9qZWN0cy9wcm9qZWN0LWlkIiBvciAicHJvamVjdHMvMTIzIikgaXMK
IHN1cHBvcnRlZCBpbiB0aGlzIGZpZWxkLiBXaGVuIHRoaXMgZmllbGQgaXMgc2V0IHRvIGEg
cHJvamVjdCdzIHJlc291cmNlCiBuYW1lLCB0aGUgYnVkZ2V0cyByZXR1cm5lZCBhcmUgdHJh
Y2tpbmcgdGhlIGNvc3RzIGZvciB0aGF0IHByb2plY3QuCgoNCgUEAwIBBRIEmAECCAoNCgUE
AwIBARIEmAEJDgoNCgUEAwIBAxIEmAEREgoNCgUEAwIBCBIEmAETOwoQCggEAwIBCJwIABIE
mAEUOgpzCgQEAwICEgScAQI/GmUgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBi
dWRnZXRzIHRvIHJldHVybiBwZXIgcGFnZS4KIFRoZSBkZWZhdWx0IGFuZCBtYXhpbXVtIHZh
bHVlIGFyZSAxMDAuCgoNCgUEAwICBRIEnAECBwoNCgUEAwICARIEnAEIEQoNCgUEAwICAxIE
nAEUFQoNCgUEAwICCBIEnAEWPgoQCggEAwICCJwIABIEnAEXPQrVAQoEBAMCAxIEoQECQRrG
ASBPcHRpb25hbC4gVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IGBMaXN0QnVkZ2V0
c1Jlc3BvbnNlYCB3aGljaAogaW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRpbnVhdGlv
biBvZiBhIHByaW9yIGBMaXN0QnVkZ2V0c2AgY2FsbCwKIGFuZCB0aGF0IHRoZSBzeXN0ZW0g
c2hvdWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoNCgUEAwIDBRIEoQECCAoN
CgUEAwIDARIEoQEJEwoNCgUEAwIDAxIEoQEWFwoNCgUEAwIDCBIEoQEYQAoQCggEAwIDCJwI
ABIEoQEZPwooCgIEBBIGpQEArAEBGhogUmVzcG9uc2UgZm9yIExpc3RCdWRnZXRzCgoLCgME
BAESBKUBCBsKSwoEBAQCABIEpwECHho9IExpc3Qgb2YgdGhlIGJ1ZGdldHMgb3duZWQgYnkg
dGhlIHJlcXVlc3RlZCBiaWxsaW5nIGFjY291bnQuCgoNCgUEBAIABBIEpwECCgoNCgUEBAIA
BhIEpwELEQoNCgUEBAIAARIEpwESGQoNCgUEBAIAAxIEpwEcHQqbAQoEBAQCARIEqwECHRqM
ASBJZiBub3QgZW1wdHksIGluZGljYXRlcyB0aGF0IHRoZXJlIG1heSBiZSBtb3JlIGJ1ZGdl
dHMgdGhhdCBtYXRjaCB0aGUKIHJlcXVlc3Q7IHRoaXMgdmFsdWUgc2hvdWxkIGJlIHBhc3Nl
ZCBpbiBhIG5ldyBgTGlzdEJ1ZGdldHNSZXF1ZXN0YC4KCg0KBQQEAgEFEgSrAQIICg0KBQQE
AgEBEgSrAQkYCg0KBQQEAgEDEgSrARscCigKAgQFEgavAQC4AQEaGiBSZXF1ZXN0IGZvciBE
ZWxldGVCdWRnZXQKCgsKAwQFARIErwEIGwqKAQoEBAUCABIGsgECtwEEGnogUmVxdWlyZWQu
IE5hbWUgb2YgdGhlIGJ1ZGdldCB0byBkZWxldGUuIFZhbHVlcyBhcmUgb2YgdGhlIGZvcm0K
IGBiaWxsaW5nQWNjb3VudHMve2JpbGxpbmdBY2NvdW50SWR9L2J1ZGdldHMve2J1ZGdldElk
fWAuCgoNCgUEBQIABRIEsgECCAoNCgUEBQIAARIEsgEJDQoNCgUEBQIAAxIEsgEQEQoPCgUE
BQIACBIGsgEStwEDChAKCAQFAgAInAgAEgSzAQQqChEKBwQFAgAInwgSBrQBBLYBBWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest ===
    # Fields for CreateBudgetRequest
    # Field: parent Type: 9 ()
    # Field: budget Type: 11 (.google.cloud.billing.budgets.v1beta1.Budget)

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::UpdateBudgetRequest ===
    # Fields for UpdateBudgetRequest
    # Field: budget Type: 11 (.google.cloud.billing.budgets.v1beta1.Budget)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::GetBudgetRequest ===
    # Fields for GetBudgetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsRequest ===
    # Fields for ListBudgetsRequest
    # Field: parent Type: 9 ()
    # Field: scope Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsResponse ===
    # Fields for ListBudgetsResponse
    # Field: budgets Type: 11 (.google.cloud.billing.budgets.v1beta1.Budget)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::DeleteBudgetRequest ===
    # Fields for DeleteBudgetRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::BudgetServiceClient ===
package Google::Cloud::Billing::Budgets::V1beta1::BudgetService::BudgetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Billing::Budgets::V1beta1::BudgetService::BudgetServiceClient

Client stub representing the remote C<BudgetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<billing.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'billing.googleapis.com:443' );

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

sub create_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'CreateBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget',
    });
}

sub update_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1beta1::BudgetService::UpdateBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'UpdateBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget',
    });
}

sub get_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1beta1::BudgetService::GetBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'GetBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget',
    });
}

sub list_budgets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'ListBudgets',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsResponse',
    });
}

sub delete_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1beta1::BudgetService::DeleteBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'DeleteBudget',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Billing::Budgets::V1beta1::BudgetService - Compiled Protocol Buffers messages for google/cloud/billing/budgets/v1beta1/budget_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Billing::Budgets::V1beta1::BudgetService;

    my $msg = Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest->new({
        parent => $parent,
        budget => $budget,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/billing/budgets/v1beta1/budget_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest

Request for CreateBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the billing account to create the budget in. Values
are of the form `billingAccounts/{billingAccountId}`.

=item * C<< $msg->budget() >> / C<< $msg->budget($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget>)

Required. Budget to create.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::UpdateBudgetRequest

Request for UpdateBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->budget() >> / C<< $msg->budget($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget>)

Required. The updated budget object.
The budget to update is specified by the budget name in the budget.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided budget to update.
Read-only fields (such as `name`) cannot be changed. If this is not
provided, then only fields with non-default values from the request are
updated. See
https://developers.google.com/protocol-buffers/docs/proto3#default for more
details about default values.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::GetBudgetRequest

Request for GetBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of budget to get. Values are of the form
`billingAccounts/{billingAccountId}/budgets/{budgetId}`.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsRequest

Request for ListBudgets

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of billing account to list budgets under. Values
are of the form `billingAccounts/{billingAccountId}`.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Optional. Set the scope of the budgets to be returned, in the format of the
resource name. The scope of a budget is the cost that it tracks, such as
costs for a single project, or the costs for all projects in a folder. Only
project scope (in the format of "projects/project-id" or "projects/123") is
supported in this field. When this field is set to a project's resource
name, the budgets returned are tracking the costs for that project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of budgets to return per page.
The default and maximum value are 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value returned by the last `ListBudgetsResponse` which
indicates that this is a continuation of a prior `ListBudgets` call,
and that the system should return the next page of data.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::ListBudgetsResponse

Response for ListBudgets

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->budgets() >> / C<< $msg->budgets($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget>)

List of the budgets owned by the requested billing account.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more budgets that match the
request; this value should be passed in a new `ListBudgetsRequest`.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetService::DeleteBudgetRequest

Request for DeleteBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the budget to delete. Values are of the form
`billingAccounts/{billingAccountId}/budgets/{budgetId}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Billing::Budgets::V1beta1::BudgetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
