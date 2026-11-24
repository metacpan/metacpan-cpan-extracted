package Google::Cloud::Speech::V1::CloudSpeechAdaptation;

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
    eval { require Google::Cloud::Speech::V1::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc3BlZWNoL3YxL2Nsb3VkX3NwZWVjaF9hZGFwdGF0aW9uLnByb3Rv
EhZnb29nbGUuY2xvdWQuc3BlZWNoLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxolZ29vZ2xlL2Nsb3VkL3NwZWVjaC92
MS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90byLJAQoWQ3JlYXRlUGhyYXNlU2V0UmVxdWVzdBI/
CgZwYXJlbnQYASABKAlCJ+BBAvpBIRIfc3BlZWNoLmdvb2dsZWFwaXMuY29tL1BocmFzZVNl
dFIGcGFyZW50EicKDXBocmFzZV9zZXRfaWQYAiABKAlCA+BBAlILcGhyYXNlU2V0SWQSRQoK
cGhyYXNlX3NldBgDIAEoCzIhLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuUGhyYXNlU2V0QgPg
QQJSCXBocmFzZVNldCKcAQoWVXBkYXRlUGhyYXNlU2V0UmVxdWVzdBJFCgpwaHJhc2Vfc2V0
GAEgASgLMiEuZ29vZ2xlLmNsb3VkLnNwZWVjaC52MS5QaHJhc2VTZXRCA+BBAlIJcGhyYXNl
U2V0EjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IK
dXBkYXRlTWFzayJSChNHZXRQaHJhc2VTZXRSZXF1ZXN0EjsKBG5hbWUYASABKAlCJ+BBAvpB
IQofc3BlZWNoLmdvb2dsZWFwaXMuY29tL1BocmFzZVNldFIEbmFtZSKTAQoUTGlzdFBocmFz
ZVNldFJlcXVlc3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSESH3NwZWVjaC5nb29nbGVhcGlz
LmNvbS9QaHJhc2VTZXRSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0K
CnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKDAQoVTGlzdFBocmFzZVNldFJlc3BvbnNl
EkIKC3BocmFzZV9zZXRzGAEgAygLMiEuZ29vZ2xlLmNsb3VkLnNwZWVjaC52MS5QaHJhc2VT
ZXRSCnBocmFzZVNldHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
IlUKFkRlbGV0ZVBocmFzZVNldFJlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9zcGVl
Y2guZ29vZ2xlYXBpcy5jb20vUGhyYXNlU2V0UgRuYW1lItcBChhDcmVhdGVDdXN0b21DbGFz
c1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIXNwZWVjaC5nb29nbGVhcGlzLmNv
bS9DdXN0b21DbGFzc1IGcGFyZW50EisKD2N1c3RvbV9jbGFzc19pZBgCIAEoCUID4EECUg1j
dXN0b21DbGFzc0lkEksKDGN1c3RvbV9jbGFzcxgDIAEoCzIjLmdvb2dsZS5jbG91ZC5zcGVl
Y2gudjEuQ3VzdG9tQ2xhc3NCA+BBAlILY3VzdG9tQ2xhc3MipAEKGFVwZGF0ZUN1c3RvbUNs
YXNzUmVxdWVzdBJLCgxjdXN0b21fY2xhc3MYASABKAsyIy5nb29nbGUuY2xvdWQuc3BlZWNo
LnYxLkN1c3RvbUNsYXNzQgPgQQJSC2N1c3RvbUNsYXNzEjsKC3VwZGF0ZV9tYXNrGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJWChVHZXRDdXN0b21D
bGFzc1JlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFzcGVlY2guZ29vZ2xlYXBpcy5j
b20vQ3VzdG9tQ2xhc3NSBG5hbWUimQEKGExpc3RDdXN0b21DbGFzc2VzUmVxdWVzdBJBCgZw
YXJlbnQYASABKAlCKeBBAvpBIxIhc3BlZWNoLmdvb2dsZWFwaXMuY29tL0N1c3RvbUNsYXNz
UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMg
ASgJUglwYWdlVG9rZW4ijwEKGUxpc3RDdXN0b21DbGFzc2VzUmVzcG9uc2USSgoOY3VzdG9t
X2NsYXNzZXMYASADKAsyIy5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLkN1c3RvbUNsYXNzUg1j
dXN0b21DbGFzc2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJZ
ChhEZWxldGVDdXN0b21DbGFzc1JlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFzcGVl
Y2guZ29vZ2xlYXBpcy5jb20vQ3VzdG9tQ2xhc3NSBG5hbWUyjg8KCkFkYXB0YXRpb24SwQEK
D0NyZWF0ZVBocmFzZVNldBIuLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuQ3JlYXRlUGhyYXNl
U2V0UmVxdWVzdBohLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuUGhyYXNlU2V0IluC0+STAjMi
Li92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3BocmFzZVNldHM6ASraQR9w
YXJlbnQscGhyYXNlX3NldCxwaHJhc2Vfc2V0X2lkEp0BCgxHZXRQaHJhc2VTZXQSKy5nb29n
bGUuY2xvdWQuc3BlZWNoLnYxLkdldFBocmFzZVNldFJlcXVlc3QaIS5nb29nbGUuY2xvdWQu
c3BlZWNoLnYxLlBocmFzZVNldCI9gtPkkwIwEi4vdjEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9waHJhc2VTZXRzLyp92kEEbmFtZRKtAQoNTGlzdFBocmFzZVNldBIsLmdvb2ds
ZS5jbG91ZC5zcGVlY2gudjEuTGlzdFBocmFzZVNldFJlcXVlc3QaLS5nb29nbGUuY2xvdWQu
c3BlZWNoLnYxLkxpc3RQaHJhc2VTZXRSZXNwb25zZSI/gtPkkwIwEi4vdjEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9waHJhc2VTZXRz2kEGcGFyZW50EswBCg9VcGRhdGVQ
aHJhc2VTZXQSLi5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlVwZGF0ZVBocmFzZVNldFJlcXVl
c3QaIS5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlBocmFzZVNldCJmgtPkkwJHMjkvdjEve3Bo
cmFzZV9zZXQubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3BocmFzZVNldHMvKn06CnBo
cmFzZV9zZXTaQRZwaHJhc2Vfc2V0LHVwZGF0ZV9tYXNrEpgBCg9EZWxldGVQaHJhc2VTZXQS
Li5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLkRlbGV0ZVBocmFzZVNldFJlcXVlc3QaFi5nb29n
bGUucHJvdG9idWYuRW1wdHkiPYLT5JMCMCouL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovcGhyYXNlU2V0cy8qfdpBBG5hbWUSzgEKEUNyZWF0ZUN1c3RvbUNsYXNzEjAuZ29v
Z2xlLmNsb3VkLnNwZWVjaC52MS5DcmVhdGVDdXN0b21DbGFzc1JlcXVlc3QaIy5nb29nbGUu
Y2xvdWQuc3BlZWNoLnYxLkN1c3RvbUNsYXNzImKC0+STAjYiMS92MS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9L2N1c3RvbUNsYXNzZXM6ASraQSNwYXJlbnQsY3VzdG9tX2Ns
YXNzLGN1c3RvbV9jbGFzc19pZBKmAQoOR2V0Q3VzdG9tQ2xhc3MSLS5nb29nbGUuY2xvdWQu
c3BlZWNoLnYxLkdldEN1c3RvbUNsYXNzUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zcGVlY2gu
djEuQ3VzdG9tQ2xhc3MiQILT5JMCMxIxL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovY3VzdG9tQ2xhc3Nlcy8qfdpBBG5hbWUSvAEKEUxpc3RDdXN0b21DbGFzc2VzEjAuZ29v
Z2xlLmNsb3VkLnNwZWVjaC52MS5MaXN0Q3VzdG9tQ2xhc3Nlc1JlcXVlc3QaMS5nb29nbGUu
Y2xvdWQuc3BlZWNoLnYxLkxpc3RDdXN0b21DbGFzc2VzUmVzcG9uc2UiQoLT5JMCMxIxL3Yx
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY3VzdG9tQ2xhc3Nlc9pBBnBhcmVu
dBLbAQoRVXBkYXRlQ3VzdG9tQ2xhc3MSMC5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlVwZGF0
ZUN1c3RvbUNsYXNzUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuQ3VzdG9tQ2xh
c3Mib4LT5JMCTjI+L3YxL3tjdXN0b21fY2xhc3MubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2N1c3RvbUNsYXNzZXMvKn06DGN1c3RvbV9jbGFzc9pBGGN1c3RvbV9jbGFzcyx1cGRh
dGVfbWFzaxKfAQoRRGVsZXRlQ3VzdG9tQ2xhc3MSMC5nb29nbGUuY2xvdWQuc3BlZWNoLnYx
LkRlbGV0ZUN1c3RvbUNsYXNzUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJAgtPk
kwIzKjEvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jdXN0b21DbGFzc2VzLyp9
2kEEbmFtZRpJykEVc3BlZWNoLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJyChpjb20uZ29vZ2xlLmNsb3VkLnNwZWVj
aC52MUIVU3BlZWNoQWRhcHRhdGlvblByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vc3Bl
ZWNoL2FwaXYxL3NwZWVjaHBiO3NwZWVjaHBi+AEBogIDR0NTSrpcCgcSBQ4A9wIBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYALwoJCgIDBRIDFwAlCgkK
AgMGEgMYACoKCAoBCBIDGgAfCgkKAggfEgMaAB8KCAoBCBIDGwBJCgkKAggLEgMbAEkKCAoB
CBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA2CgkKAggIEgMdADYKCAoBCBIDHgAzCgkKAggB
EgMeADMKCAoBCBIDHwAhCgkKAggkEgMfACEKSQoCBgASBCIAfwEaPSBTZXJ2aWNlIHRoYXQg
aW1wbGVtZW50cyBHb29nbGUgQ2xvdWQgU3BlZWNoIEFkYXB0YXRpb24gQVBJLgoKCgoDBgAB
EgMiCBIKCgoDBgADEgMjAj0KDAoFBgADmQgSAyMCPQoLCgMGAAMSBCQCJTcKDQoFBgADmggS
BCQCJTcK5AEKBAYAAgASBCoCMAMa1QEgQ3JlYXRlIGEgc2V0IG9mIHBocmFzZSBoaW50cy4g
RWFjaCBpdGVtIGluIHRoZSBzZXQgY2FuIGJlIGEgc2luZ2xlIHdvcmQgb3IKIGEgbXVsdGkt
d29yZCBwaHJhc2UuIFRoZSBpdGVtcyBpbiB0aGUgUGhyYXNlU2V0IGFyZSBmYXZvcmVkIGJ5
IHRoZQogcmVjb2duaXRpb24gbW9kZWwgd2hlbiB5b3Ugc2VuZCBhIGNhbGwgdGhhdCBpbmNs
dWRlcyB0aGUgUGhyYXNlU2V0LgoKDAoFBgACAAESAyoGFQoMCgUGAAIAAhIDKhYsCgwKBQYA
AgADEgMqN0AKDQoFBgACAAQSBCsELgYKEQoJBgACAASwyrwiEgQrBC4GCgwKBQYAAgAEEgMv
BE0KDwoIBgACAASbCAASAy8ETQohCgQGAAIBEgQzAjgDGhMgR2V0IGEgcGhyYXNlIHNldC4K
CgwKBQYAAgEBEgMzBhIKDAoFBgACAQISAzMTJgoMCgUGAAIBAxIDMzE6Cg0KBQYAAgEEEgQ0
BDYGChEKCQYAAgEEsMq8IhIENAQ2BgoMCgUGAAIBBBIDNwQyCg8KCAYAAgEEmwgAEgM3BDIK
IQoEBgACAhIEOwJAAxoTIExpc3QgcGhyYXNlIHNldHMuCgoMCgUGAAICARIDOwYTCgwKBQYA
AgICEgM7FCgKDAoFBgACAgMSAzszSAoNCgUGAAICBBIEPAQ+BgoRCgkGAAICBLDKvCISBDwE
PgYKDAoFBgACAgQSAz8ENAoPCggGAAICBJsIABIDPwQ0CiQKBAYAAgMSBEMCSQMaFiBVcGRh
dGUgYSBwaHJhc2Ugc2V0LgoKDAoFBgACAwESA0MGFQoMCgUGAAIDAhIDQxYsCgwKBQYAAgMD
EgNDN0AKDQoFBgACAwQSBEQERwYKEQoJBgACAwSwyrwiEgREBEcGCgwKBQYAAgMEEgNIBEQK
DwoIBgACAwSbCAASA0gERAokCgQGAAIEEgRMAlEDGhYgRGVsZXRlIGEgcGhyYXNlIHNldC4K
CgwKBQYAAgQBEgNMBhUKDAoFBgACBAISA0wWLAoMCgUGAAIEAxIDTDdMCg0KBQYAAgQEEgRN
BE8GChEKCQYAAgQEsMq8IhIETQRPBgoMCgUGAAIEBBIDUAQyCg8KCAYAAgQEmwgAEgNQBDIK
JgoEBgACBRIEVAJbAxoYIENyZWF0ZSBhIGN1c3RvbSBjbGFzcy4KCgwKBQYAAgUBEgNUBhcK
DAoFBgACBQISA1QYMAoMCgUGAAIFAxIDVDtGCg0KBQYAAgUEEgRVBFgGChEKCQYAAgUEsMq8
IhIEVQRYBgoNCgUGAAIFBBIEWQRaLgoQCggGAAIFBJsIABIEWQRaLgojCgQGAAIGEgReAmMD
GhUgR2V0IGEgY3VzdG9tIGNsYXNzLgoKDAoFBgACBgESA14GFAoMCgUGAAIGAhIDXhUqCgwK
BQYAAgYDEgNeNUAKDQoFBgACBgQSBF8EYQYKEQoJBgACBgSwyrwiEgRfBGEGCgwKBQYAAgYE
EgNiBDIKDwoIBgACBgSbCAASA2IEMgokCgQGAAIHEgRmAmwDGhYgTGlzdCBjdXN0b20gY2xh
c3Nlcy4KCgwKBQYAAgcBEgNmBhcKDAoFBgACBwISA2YYMAoMCgUGAAIHAxIDZw8oCg0KBQYA
AgcEEgRoBGoGChEKCQYAAgcEsMq8IhIEaARqBgoMCgUGAAIHBBIDawQ0Cg8KCAYAAgcEmwgA
EgNrBDQKJgoEBgACCBIEbwJ1AxoYIFVwZGF0ZSBhIGN1c3RvbSBjbGFzcy4KCgwKBQYAAggB
EgNvBhcKDAoFBgACCAISA28YMAoMCgUGAAIIAxIDbztGCg0KBQYAAggEEgRwBHMGChEKCQYA
AggEsMq8IhIEcARzBgoMCgUGAAIIBBIDdARGCg8KCAYAAggEmwgAEgN0BEYKJgoEBgACCRIE
eAJ+AxoYIERlbGV0ZSBhIGN1c3RvbSBjbGFzcy4KCgwKBQYAAgkBEgN4BhcKDAoFBgACCQIS
A3gYMAoMCgUGAAIJAxIDeQ8kCg0KBQYAAgkEEgR6BHwGChEKCQYAAgkEsMq8IhIEegR8BgoM
CgUGAAIJBBIDfQQyCg8KCAYAAgkEmwgAEgN9BDIKTAoCBAASBoIBAJ0BARo+IE1lc3NhZ2Ug
c2VudCBieSB0aGUgY2xpZW50IGZvciB0aGUgYENyZWF0ZVBocmFzZVNldGAgbWV0aG9kLgoK
CwoDBAABEgSCAQgeCtcDCgQEAAIAEgaNAQKSAQQaxgMgUmVxdWlyZWQuIFRoZSBwYXJlbnQg
cmVzb3VyY2Ugd2hlcmUgdGhpcyBwaHJhc2Ugc2V0IHdpbGwgYmUgY3JlYXRlZC4KIEZvcm1h
dDoKCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKIFNwZWVj
aC10by1UZXh0IHN1cHBvcnRzIHRocmVlIGxvY2F0aW9uczogYGdsb2JhbGAsIGB1c2AgKFVT
IE5vcnRoIEFtZXJpY2EpLAogYW5kIGBldWAgKEV1cm9wZSkuIElmIHlvdSBhcmUgY2FsbGlu
ZyB0aGUgYHNwZWVjaC5nb29nbGVhcGlzLmNvbWAKIGVuZHBvaW50LCB1c2UgdGhlIGBnbG9i
YWxgIGxvY2F0aW9uLiBUbyBzcGVjaWZ5IGEgcmVnaW9uLCB1c2UgYQogW3JlZ2lvbmFsIGVu
ZHBvaW50XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3BlZWNoLXRvLXRleHQvZG9jcy9l
bmRwb2ludHMpCiB3aXRoIG1hdGNoaW5nIGB1c2Agb3IgYGV1YCBsb2NhdGlvbiB2YWx1ZS4K
Cg0KBQQAAgAFEgSNAQIICg0KBQQAAgABEgSNAQkPCg0KBQQAAgADEgSNARITCg8KBQQAAgAI
EgaNARSSAQMKEAoIBAACAAicCAASBI4BBCoKEQoHBAACAAifCBIGjwEEkQEFCqACCgQEAAIB
EgSZAQJEGpECIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgcGhyYXNlIHNldCwg
d2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIHBocmFzZSBz
ZXQncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIHJlc3RyaWN0IHRvIGxl
dHRlcnMsIG51bWJlcnMsIGFuZCBoeXBoZW5zLCB3aXRoIHRoZSBmaXJzdAogY2hhcmFjdGVy
IGEgbGV0dGVyLCB0aGUgbGFzdCBhIGxldHRlciBvciBhIG51bWJlciwgYW5kIGJlIDQtNjMg
Y2hhcmFjdGVycy4KCg0KBQQAAgEFEgSZAQIICg0KBQQAAgEBEgSZAQkWCg0KBQQAAgEDEgSZ
ARkaCg0KBQQAAgEIEgSZARtDChAKCAQAAgEInAgAEgSZARxCCjMKBAQAAgISBJwBAkQaJSBS
ZXF1aXJlZC4gVGhlIHBocmFzZSBzZXQgdG8gY3JlYXRlLgoKDQoFBAACAgYSBJwBAgsKDQoF
BAACAgESBJwBDBYKDQoFBAACAgMSBJwBGRoKDQoFBAACAggSBJwBG0MKEAoIBAACAgicCAAS
BJwBHEIKTAoCBAESBqABALEBARo+IE1lc3NhZ2Ugc2VudCBieSB0aGUgY2xpZW50IGZvciB0
aGUgYFVwZGF0ZVBocmFzZVNldGAgbWV0aG9kLgoKCwoDBAEBEgSgAQgeCpcECgQEAQIAEgSt
AQJEGogEIFJlcXVpcmVkLiBUaGUgcGhyYXNlIHNldCB0byB1cGRhdGUuCgogVGhlIHBocmFz
ZSBzZXQncyBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgc2V0IHRvIGJl
CiB1cGRhdGVkLiBGb3JtYXQ6CgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9waHJhc2VTZXRzL3twaHJhc2Vfc2V0fWAKCiBTcGVlY2gtdG8tVGV4dCBzdXBw
b3J0cyB0aHJlZSBsb2NhdGlvbnM6IGBnbG9iYWxgLCBgdXNgIChVUyBOb3J0aCBBbWVyaWNh
KSwKIGFuZCBgZXVgIChFdXJvcGUpLiBJZiB5b3UgYXJlIGNhbGxpbmcgdGhlIGBzcGVlY2gu
Z29vZ2xlYXBpcy5jb21gCiBlbmRwb2ludCwgdXNlIHRoZSBgZ2xvYmFsYCBsb2NhdGlvbi4g
VG8gc3BlY2lmeSBhIHJlZ2lvbiwgdXNlIGEKIFtyZWdpb25hbCBlbmRwb2ludF0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3NwZWVjaC10by10ZXh0L2RvY3MvZW5kcG9pbnRzKQogd2l0
aCBtYXRjaGluZyBgdXNgIG9yIGBldWAgbG9jYXRpb24gdmFsdWUuCgoNCgUEAQIABhIErQEC
CwoNCgUEAQIAARIErQEMFgoNCgUEAQIAAxIErQEZGgoNCgUEAQIACBIErQEbQwoQCggEAQIA
CJwIABIErQEcQgoxCgQEAQIBEgSwAQIsGiMgVGhlIGxpc3Qgb2YgZmllbGRzIHRvIGJlIHVw
ZGF0ZWQuCgoNCgUEAQIBBhIEsAECGwoNCgUEAQIBARIEsAEcJwoNCgUEAQIBAxIEsAEqKwpJ
CgIEAhIGtAEAxAEBGjsgTWVzc2FnZSBzZW50IGJ5IHRoZSBjbGllbnQgZm9yIHRoZSBgR2V0
UGhyYXNlU2V0YCBtZXRob2QuCgoLCgMEAgESBLQBCBsK2wMKBAQCAgASBr4BAsMBBBrKAyBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHBocmFzZSBzZXQgdG8gcmV0cmlldmUuIEZvcm1h
dDoKCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3BocmFzZVNl
dHMve3BocmFzZV9zZXR9YAoKIFNwZWVjaC10by1UZXh0IHN1cHBvcnRzIHRocmVlIGxvY2F0
aW9uczogYGdsb2JhbGAsIGB1c2AgKFVTIE5vcnRoIEFtZXJpY2EpLAogYW5kIGBldWAgKEV1
cm9wZSkuIElmIHlvdSBhcmUgY2FsbGluZyB0aGUgYHNwZWVjaC5nb29nbGVhcGlzLmNvbWAK
IGVuZHBvaW50LCB1c2UgdGhlIGBnbG9iYWxgIGxvY2F0aW9uLiBUbyBzcGVjaWZ5IGEgcmVn
aW9uLCB1c2UgYQogW3JlZ2lvbmFsIGVuZHBvaW50XShodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vc3BlZWNoLXRvLXRleHQvZG9jcy9lbmRwb2ludHMpCiB3aXRoIG1hdGNoaW5nIGB1c2Ag
b3IgYGV1YCBsb2NhdGlvbiB2YWx1ZS4KCg0KBQQCAgAFEgS+AQIICg0KBQQCAgABEgS+AQkN
Cg0KBQQCAgADEgS+ARARCg8KBQQCAgAIEga+ARLDAQMKEAoIBAICAAicCAASBL8BBCoKEQoH
BAICAAifCBIGwAEEwgEFCkoKAgQDEgbHAQDkAQEaPCBNZXNzYWdlIHNlbnQgYnkgdGhlIGNs
aWVudCBmb3IgdGhlIGBMaXN0UGhyYXNlU2V0YCBtZXRob2QuCgoLCgMEAwESBMcBCBwK0QMK
BAQDAgASBtEBAtYBBBrAAyBSZXF1aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlz
IGNvbGxlY3Rpb24gb2YgcGhyYXNlIHNldC4gRm9ybWF0OgoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCgogU3BlZWNoLXRvLVRleHQgc3VwcG9ydHMgdGhy
ZWUgbG9jYXRpb25zOiBgZ2xvYmFsYCwgYHVzYCAoVVMgTm9ydGggQW1lcmljYSksCiBhbmQg
YGV1YCAoRXVyb3BlKS4gSWYgeW91IGFyZSBjYWxsaW5nIHRoZSBgc3BlZWNoLmdvb2dsZWFw
aXMuY29tYAogZW5kcG9pbnQsIHVzZSB0aGUgYGdsb2JhbGAgbG9jYXRpb24uIFRvIHNwZWNp
ZnkgYSByZWdpb24sIHVzZSBhCiBbcmVnaW9uYWwgZW5kcG9pbnRdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2NzL2VuZHBvaW50cykKIHdpdGggbWF0Y2hp
bmcgYHVzYCBvciBgZXVgIGxvY2F0aW9uIHZhbHVlLgoKDQoFBAMCAAUSBNEBAggKDQoFBAMC
AAESBNEBCQ8KDQoFBAMCAAMSBNEBEhMKDwoFBAMCAAgSBtEBFNYBAwoQCggEAwIACJwIABIE
0gEEKgoRCgcEAwIACJ8IEgbTAQTVAQUK7QEKBAQDAgESBNwBAhYa3gEgVGhlIG1heGltdW0g
bnVtYmVyIG9mIHBocmFzZSBzZXRzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVy
bgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBw
aHJhc2Ugc2V0cyB3aWxsIGJlCiByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAw
MDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvCiAxMDAwLgoKDQoFBAMC
AQUSBNwBAgcKDQoFBAMCAQESBNwBCBEKDQoFBAMCAQMSBNwBFBUK8wEKBAQDAgISBOMBAhga
5AEgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RQaHJhc2VT
ZXRgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFn
ZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRv
IGBMaXN0UGhyYXNlU2V0YCBtdXN0CiBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRo
ZSBwYWdlIHRva2VuLgoKDQoFBAMCAgUSBOMBAggKDQoFBAMCAgESBOMBCRMKDQoFBAMCAgMS
BOMBFhcKTQoCBAQSBucBAO4BARo/IE1lc3NhZ2UgcmV0dXJuZWQgdG8gdGhlIGNsaWVudCBi
eSB0aGUgYExpc3RQaHJhc2VTZXRgIG1ldGhvZC4KCgsKAwQEARIE5wEIHQofCgQEBAIAEgTp
AQIlGhEgVGhlIHBocmFzZSBzZXQuCgoNCgUEBAIABBIE6QECCgoNCgUEBAIABhIE6QELFAoN
CgUEBAIAARIE6QEVIAoNCgUEBAIAAxIE6QEjJAqQAQoEBAQCARIE7QECHRqBASBBIHRva2Vu
LCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5l
eHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNl
cXVlbnQgcGFnZXMuCgoNCgUEBAIBBRIE7QECCAoNCgUEBAIBARIE7QEJGAoNCgUEBAIBAxIE
7QEbHApMCgIEBRIG8QEA+wEBGj4gTWVzc2FnZSBzZW50IGJ5IHRoZSBjbGllbnQgZm9yIHRo
ZSBgRGVsZXRlUGhyYXNlU2V0YCBtZXRob2QuCgoLCgMEBQESBPEBCB4KjQEKBAQFAgASBvUB
AvoBBBp9IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcGhyYXNlIHNldCB0byBkZWxldGUu
IEZvcm1hdDoKCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Bo
cmFzZVNldHMve3BocmFzZV9zZXR9YAoKDQoFBAUCAAUSBPUBAggKDQoFBAUCAAESBPUBCQ0K
DQoFBAUCAAMSBPUBEBEKDwoFBAUCAAgSBvUBEvoBAwoQCggEBQIACJwIABIE9gEEKgoRCgcE
BQIACJ8IEgb3AQT5AQUKTgoCBAYSBv4BAJkCARpAIE1lc3NhZ2Ugc2VudCBieSB0aGUgY2xp
ZW50IGZvciB0aGUgYENyZWF0ZUN1c3RvbUNsYXNzYCBtZXRob2QuCgoLCgMEBgESBP4BCCAK
5wMKBAQGAgASBokCAo4CBBrWAyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSB3aGVy
ZSB0aGlzIGN1c3RvbSBjbGFzcyB3aWxsIGJlIGNyZWF0ZWQuCiBGb3JtYXQ6CgogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jdXN0b21DbGFzc2VzYAoKIFNw
ZWVjaC10by1UZXh0IHN1cHBvcnRzIHRocmVlIGxvY2F0aW9uczogYGdsb2JhbGAsIGB1c2Ag
KFVTIE5vcnRoIEFtZXJpY2EpLAogYW5kIGBldWAgKEV1cm9wZSkuIElmIHlvdSBhcmUgY2Fs
bGluZyB0aGUgYHNwZWVjaC5nb29nbGVhcGlzLmNvbWAKIGVuZHBvaW50LCB1c2UgdGhlIGBn
bG9iYWxgIGxvY2F0aW9uLiBUbyBzcGVjaWZ5IGEgcmVnaW9uLCB1c2UgYQogW3JlZ2lvbmFs
IGVuZHBvaW50XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3BlZWNoLXRvLXRleHQvZG9j
cy9lbmRwb2ludHMpCiB3aXRoIG1hdGNoaW5nIGB1c2Agb3IgYGV1YCBsb2NhdGlvbiB2YWx1
ZS4KCg0KBQQGAgAFEgSJAgIICg0KBQQGAgABEgSJAgkPCg0KBQQGAgADEgSJAhITCg8KBQQG
AgAIEgaJAhSOAgMKEAoIBAYCAAicCAASBIoCBCoKEQoHBAYCAAifCBIGiwIEjQIFCqMCCgQE
BgIBEgSVAgJGGpQCIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgY3VzdG9tIGNs
YXNzLCB3aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgY3Vz
dG9tIGNsYXNzJyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIHJlc3RyaWN0
IHRvIGxldHRlcnMsIG51bWJlcnMsIGFuZCBoeXBoZW5zLCB3aXRoIHRoZSBmaXJzdAogY2hh
cmFjdGVyIGEgbGV0dGVyLCB0aGUgbGFzdCBhIGxldHRlciBvciBhIG51bWJlciwgYW5kIGJl
IDQtNjMgY2hhcmFjdGVycy4KCg0KBQQGAgEFEgSVAgIICg0KBQQGAgEBEgSVAgkYCg0KBQQG
AgEDEgSVAhscCg0KBQQGAgEIEgSVAh1FChAKCAQGAgEInAgAEgSVAh5ECjUKBAQGAgISBJgC
AkgaJyBSZXF1aXJlZC4gVGhlIGN1c3RvbSBjbGFzcyB0byBjcmVhdGUuCgoNCgUEBgICBhIE
mAICDQoNCgUEBgICARIEmAIOGgoNCgUEBgICAxIEmAIdHgoNCgUEBgICCBIEmAIfRwoQCggE
BgICCJwIABIEmAIgRgpOCgIEBxIGnAIArQIBGkAgTWVzc2FnZSBzZW50IGJ5IHRoZSBjbGll
bnQgZm9yIHRoZSBgVXBkYXRlQ3VzdG9tQ2xhc3NgIG1ldGhvZC4KCgsKAwQHARIEnAIIIAqp
BAoEBAcCABIEqQICSBqaBCBSZXF1aXJlZC4gVGhlIGN1c3RvbSBjbGFzcyB0byB1cGRhdGUu
CgogVGhlIGN1c3RvbSBjbGFzcydzIGBuYW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5
IHRoZSBjdXN0b20gY2xhc3MgdG8gYmUKIHVwZGF0ZWQuIEZvcm1hdDoKCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbUNsYXNzZXMve2N1c3RvbV9j
bGFzc31gCgogU3BlZWNoLXRvLVRleHQgc3VwcG9ydHMgdGhyZWUgbG9jYXRpb25zOiBgZ2xv
YmFsYCwgYHVzYCAoVVMgTm9ydGggQW1lcmljYSksCiBhbmQgYGV1YCAoRXVyb3BlKS4gSWYg
eW91IGFyZSBjYWxsaW5nIHRoZSBgc3BlZWNoLmdvb2dsZWFwaXMuY29tYAogZW5kcG9pbnQs
IHVzZSB0aGUgYGdsb2JhbGAgbG9jYXRpb24uIFRvIHNwZWNpZnkgYSByZWdpb24sIHVzZSBh
CiBbcmVnaW9uYWwgZW5kcG9pbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gt
dG8tdGV4dC9kb2NzL2VuZHBvaW50cykKIHdpdGggbWF0Y2hpbmcgYHVzYCBvciBgZXVgIGxv
Y2F0aW9uIHZhbHVlLgoKDQoFBAcCAAYSBKkCAg0KDQoFBAcCAAESBKkCDhoKDQoFBAcCAAMS
BKkCHR4KDQoFBAcCAAgSBKkCH0cKEAoIBAcCAAicCAASBKkCIEYKMQoEBAcCARIErAICLBoj
IFRoZSBsaXN0IG9mIGZpZWxkcyB0byBiZSB1cGRhdGVkLgoKDQoFBAcCAQYSBKwCAhsKDQoF
BAcCAQESBKwCHCcKDQoFBAcCAQMSBKwCKisKSwoCBAgSBrACALoCARo9IE1lc3NhZ2Ugc2Vu
dCBieSB0aGUgY2xpZW50IGZvciB0aGUgYEdldEN1c3RvbUNsYXNzYCBtZXRob2QuCgoLCgME
CAESBLACCB0KlwEKBAQIAgASBrQCArkCBBqGASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IGN1c3RvbSBjbGFzcyB0byByZXRyaWV2ZS4gRm9ybWF0OgoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9tQ2xhc3Nlcy97Y3VzdG9tX2NsYXNzfWAK
Cg0KBQQIAgAFEgS0AgIICg0KBQQIAgABEgS0AgkNCg0KBQQIAgADEgS0AhARCg8KBQQIAgAI
Ega0AhK5AgMKEAoIBAgCAAicCAASBLUCBCoKEQoHBAgCAAifCBIGtgIEuAIFCk4KAgQJEga9
AgDaAgEaQCBNZXNzYWdlIHNlbnQgYnkgdGhlIGNsaWVudCBmb3IgdGhlIGBMaXN0Q3VzdG9t
Q2xhc3Nlc2AgbWV0aG9kLgoKCwoDBAkBEgS9AgggCuMDCgQECQIAEgbHAgLMAgQa0gMgUmVx
dWlyZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIGN1c3Rv
bSBjbGFzc2VzLiBGb3JtYXQ6CgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jdXN0b21DbGFzc2VzYAoKIFNwZWVjaC10by1UZXh0IHN1cHBvcnRzIHRocmVl
IGxvY2F0aW9uczogYGdsb2JhbGAsIGB1c2AgKFVTIE5vcnRoIEFtZXJpY2EpLAogYW5kIGBl
dWAgKEV1cm9wZSkuIElmIHlvdSBhcmUgY2FsbGluZyB0aGUgYHNwZWVjaC5nb29nbGVhcGlz
LmNvbWAKIGVuZHBvaW50LCB1c2UgdGhlIGBnbG9iYWxgIGxvY2F0aW9uLiBUbyBzcGVjaWZ5
IGEgcmVnaW9uLCB1c2UgYQogW3JlZ2lvbmFsIGVuZHBvaW50XShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vc3BlZWNoLXRvLXRleHQvZG9jcy9lbmRwb2ludHMpCiB3aXRoIG1hdGNoaW5n
IGB1c2Agb3IgYGV1YCBsb2NhdGlvbiB2YWx1ZS4KCg0KBQQJAgAFEgTHAgIICg0KBQQJAgAB
EgTHAgkPCg0KBQQJAgADEgTHAhITCg8KBQQJAgAIEgbHAhTMAgMKEAoIBAkCAAicCAASBMgC
BCoKEQoHBAkCAAifCBIGyQIEywIFCvMBCgQECQIBEgTSAgIWGuQBIFRoZSBtYXhpbXVtIG51
bWJlciBvZiBjdXN0b20gY2xhc3NlcyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heSByZXR1
cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAg
Y3VzdG9tIGNsYXNzZXMgd2lsbCBiZQogcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlz
IDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0bwogMTAwMC4KCg0K
BQQJAgEFEgTSAgIHCg0KBQQJAgEBEgTSAggRCg0KBQQJAgEDEgTSAhQVCvcBCgQECQICEgTZ
AgIYGugBIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0Q3Vz
dG9tQ2xhc3NgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVl
bnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3Zp
ZGVkIHRvIGBMaXN0Q3VzdG9tQ2xhc3NgIG11c3QKIG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJv
dmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUECQICBRIE2QICCAoNCgUECQICARIE2QIJEwoN
CgUECQICAxIE2QIWFwpRCgIEChIG3QIA5AIBGkMgTWVzc2FnZSByZXR1cm5lZCB0byB0aGUg
Y2xpZW50IGJ5IHRoZSBgTGlzdEN1c3RvbUNsYXNzZXNgIG1ldGhvZC4KCgsKAwQKARIE3QII
IQojCgQECgIAEgTfAgIqGhUgVGhlIGN1c3RvbSBjbGFzc2VzLgoKDQoFBAoCAAQSBN8CAgoK
DQoFBAoCAAYSBN8CCxYKDQoFBAoCAAESBN8CFyUKDQoFBAoCAAMSBN8CKCkKkAEKBAQKAgES
BOMCAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRv
IHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRo
ZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAoCAQUSBOMCAggKDQoFBAoCAQES
BOMCCRgKDQoFBAoCAQMSBOMCGxwKTgoCBAsSBucCAPcCARpAIE1lc3NhZ2Ugc2VudCBieSB0
aGUgY2xpZW50IGZvciB0aGUgYERlbGV0ZUN1c3RvbUNsYXNzYCBtZXRob2QuCgoLCgMECwES
BOcCCCAK4AMKBAQLAgASBvECAvYCBBrPAyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGN1
c3RvbSBjbGFzcyB0byBkZWxldGUuIEZvcm1hdDoKCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2N1c3RvbUNsYXNzZXMve2N1c3RvbV9jbGFzc31gCgogU3Bl
ZWNoLXRvLVRleHQgc3VwcG9ydHMgdGhyZWUgbG9jYXRpb25zOiBgZ2xvYmFsYCwgYHVzYCAo
VVMgTm9ydGggQW1lcmljYSksCiBhbmQgYGV1YCAoRXVyb3BlKS4gSWYgeW91IGFyZSBjYWxs
aW5nIHRoZSBgc3BlZWNoLmdvb2dsZWFwaXMuY29tYAogZW5kcG9pbnQsIHVzZSB0aGUgYGds
b2JhbGAgbG9jYXRpb24uIFRvIHNwZWNpZnkgYSByZWdpb24sIHVzZSBhCiBbcmVnaW9uYWwg
ZW5kcG9pbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2Nz
L2VuZHBvaW50cykKIHdpdGggbWF0Y2hpbmcgYHVzYCBvciBgZXVgIGxvY2F0aW9uIHZhbHVl
LgoKDQoFBAsCAAUSBPECAggKDQoFBAsCAAESBPECCQ0KDQoFBAsCAAMSBPECEBEKDwoFBAsC
AAgSBvECEvYCAwoQCggECwIACJwIABIE8gIEKgoRCgcECwIACJ8IEgbzAgT1AgViBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest ===
    # Fields for CreatePhraseSetRequest
    # Field: parent Type: 9 ()
    # Field: phrase_set_id Type: 9 ()
    # Field: phrase_set Type: 11 (.google.cloud.speech.v1.PhraseSet)

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest ===
    # Fields for UpdatePhraseSetRequest
    # Field: phrase_set Type: 11 (.google.cloud.speech.v1.PhraseSet)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest ===
    # Fields for GetPhraseSetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest ===
    # Fields for ListPhraseSetRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse ===
    # Fields for ListPhraseSetResponse
    # Field: phrase_sets Type: 11 (.google.cloud.speech.v1.PhraseSet)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest ===
    # Fields for DeletePhraseSetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest ===
    # Fields for CreateCustomClassRequest
    # Field: parent Type: 9 ()
    # Field: custom_class_id Type: 9 ()
    # Field: custom_class Type: 11 (.google.cloud.speech.v1.CustomClass)

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest ===
    # Fields for UpdateCustomClassRequest
    # Field: custom_class Type: 11 (.google.cloud.speech.v1.CustomClass)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest ===
    # Fields for GetCustomClassRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest ===
    # Fields for ListCustomClassesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse ===
    # Fields for ListCustomClassesResponse
    # Field: custom_classes Type: 11 (.google.cloud.speech.v1.CustomClass)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest ===
    # Fields for DeleteCustomClassRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Speech::V1::CloudSpeechAdaptation::AdaptationClient ===
package Google::Cloud::Speech::V1::CloudSpeechAdaptation::AdaptationClient;

=pod

=head2 Service Client: Google::Cloud::Speech::V1::CloudSpeechAdaptation::AdaptationClient

Client stub representing the remote C<Adaptation> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<speech.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'speech.googleapis.com:443' );

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

sub create_phrase_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'CreatePhraseSet',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::PhraseSet',
    });
}

sub get_phrase_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'GetPhraseSet',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::PhraseSet',
    });
}

sub list_phrase_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'ListPhraseSet',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse',
    });
}

sub update_phrase_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'UpdatePhraseSet',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::PhraseSet',
    });
}

sub delete_phrase_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'DeletePhraseSet',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub create_custom_class {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'CreateCustomClass',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::CustomClass',
    });
}

sub get_custom_class {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'GetCustomClass',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::CustomClass',
    });
}

sub list_custom_classes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'ListCustomClasses',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse',
    });
}

sub update_custom_class {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'UpdateCustomClass',
        request        => $req,
        response_class => 'Google::Cloud::Speech::V1::Resource::CustomClass',
    });
}

sub delete_custom_class {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.speech.v1.Adaptation',
        method         => 'DeleteCustomClass',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Speech::V1::CloudSpeechAdaptation - Compiled Protocol Buffers messages for google/cloud/speech/v1/cloud_speech_adaptation.proto

=head1 SYNOPSIS

    use Google::Cloud::Speech::V1::CloudSpeechAdaptation;

    my $msg = Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest->new({
        parent => $parent,
        phrase_set_id => $phrase_set_id,
        phrase_set => $phrase_set,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/speech/v1/cloud_speech_adaptation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest

Message sent by the client for the `CreatePhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this phrase set will be created.
Format:

`projects/{project}/locations/{location}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->phrase_set_id() >> / C<< $msg->phrase_set_id($value) >>

Type: C<String>

Required. The ID to use for the phrase set, which will become the final
component of the phrase set's resource name.

This value should restrict to letters, numbers, and hyphens, with the first
character a letter, the last a letter or a number, and be 4-63 characters.

=item * C<< $msg->phrase_set() >> / C<< $msg->phrase_set($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::PhraseSet>)

Required. The phrase set to create.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest

Message sent by the client for the `UpdatePhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phrase_set() >> / C<< $msg->phrase_set($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::PhraseSet>)

Required. The phrase set to update.

The phrase set's `name` field is used to identify the set to be
updated. Format:

`projects/{project}/locations/{location}/phraseSets/{phrase_set}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be updated.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest

Message sent by the client for the `GetPhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the phrase set to retrieve. Format:

`projects/{project}/locations/{location}/phraseSets/{phrase_set}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest

Message sent by the client for the `ListPhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of phrase set. Format:

`projects/{project}/locations/{location}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of phrase sets to return. The service may return
fewer than this value. If unspecified, at most 50 phrase sets will be
returned. The maximum value is 1000; values above 1000 will be coerced to
1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListPhraseSet` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListPhraseSet` must
match the call that provided the page token.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse

Message returned to the client by the `ListPhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phrase_sets() >> / C<< $msg->phrase_sets($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::PhraseSet>)

The phrase set.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest

Message sent by the client for the `DeletePhraseSet` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the phrase set to delete. Format:

`projects/{project}/locations/{location}/phraseSets/{phrase_set}`

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest

Message sent by the client for the `CreateCustomClass` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this custom class will be created.
Format:

`projects/{project}/locations/{location}/customClasses`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->custom_class_id() >> / C<< $msg->custom_class_id($value) >>

Type: C<String>

Required. The ID to use for the custom class, which will become the final
component of the custom class' resource name.

This value should restrict to letters, numbers, and hyphens, with the first
character a letter, the last a letter or a number, and be 4-63 characters.

=item * C<< $msg->custom_class() >> / C<< $msg->custom_class($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::CustomClass>)

Required. The custom class to create.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest

Message sent by the client for the `UpdateCustomClass` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->custom_class() >> / C<< $msg->custom_class($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::CustomClass>)

Required. The custom class to update.

The custom class's `name` field is used to identify the custom class to be
updated. Format:

`projects/{project}/locations/{location}/customClasses/{custom_class}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be updated.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest

Message sent by the client for the `GetCustomClass` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the custom class to retrieve. Format:

`projects/{project}/locations/{location}/customClasses/{custom_class}`

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest

Message sent by the client for the `ListCustomClasses` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of custom classes. Format:

`projects/{project}/locations/{location}/customClasses`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of custom classes to return. The service may return
fewer than this value. If unspecified, at most 50 custom classes will be
returned. The maximum value is 1000; values above 1000 will be coerced to
1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListCustomClass` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListCustomClass` must
match the call that provided the page token.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse

Message returned to the client by the `ListCustomClasses` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->custom_classes() >> / C<< $msg->custom_classes($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::CustomClass>)

The custom classes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest

Message sent by the client for the `DeleteCustomClass` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the custom class to delete. Format:

`projects/{project}/locations/{location}/customClasses/{custom_class}`

Speech-to-Text supports three locations: `global`, `us` (US North America),
and `eu` (Europe). If you are calling the `speech.googleapis.com`
endpoint, use the `global` location. To specify a region, use a
[regional endpoint](https://cloud.google.com/speech-to-text/docs/endpoints)
with matching `us` or `eu` location value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Speech::V1::CloudSpeechAdaptation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
