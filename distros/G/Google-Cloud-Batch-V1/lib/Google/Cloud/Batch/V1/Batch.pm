package Google::Cloud::Batch::V1::Batch;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Batch::V1::Job };
    eval { require Google::Cloud::Batch::V1::Task };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvYmF0Y2gvdjEvYmF0Y2gucHJvdG8SFWdvb2dsZS5jbG91ZC5iYXRj
aC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQu
cHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmll
bGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL2Nsb3Vk
L2JhdGNoL3YxL2pvYi5wcm90bxogZ29vZ2xlL2Nsb3VkL2JhdGNoL3YxL3Rhc2sucHJvdG8a
I2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iugEKEENyZWF0
ZUpvYlJlcXVlc3QSOAoGcGFyZW50GAEgASgJQiDgQQL6QRoSGGJhdGNoLmdvb2dsZWFwaXMu
Y29tL0pvYlIGcGFyZW50EhUKBmpvYl9pZBgCIAEoCVIFam9iSWQSMQoDam9iGAMgASgLMhou
Z29vZ2xlLmNsb3VkLmJhdGNoLnYxLkpvYkID4EECUgNqb2ISIgoKcmVxdWVzdF9pZBgEIAEo
CUID4EEBUglyZXF1ZXN0SWQiRQoNR2V0Sm9iUmVxdWVzdBI0CgRuYW1lGAEgASgJQiDgQQL6
QRoKGGJhdGNoLmdvb2dsZWFwaXMuY29tL0pvYlIEbmFtZSJnChBEZWxldGVKb2JSZXF1ZXN0
EhIKBG5hbWUYASABKAlSBG5hbWUSGwoGcmVhc29uGAIgASgJQgPgQQFSBnJlYXNvbhIiCgpy
ZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCJ0ChBDYW5jZWxKb2JSZXF1ZXN0EjQK
BG5hbWUYASABKAlCIOBBAvpBGgoYYmF0Y2guZ29vZ2xlYXBpcy5jb20vSm9iUgRuYW1lEioK
CnJlcXVlc3RfaWQYBCABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQiEwoRQ2FuY2VsSm9i
UmVzcG9uc2UinQEKD0xpc3RKb2JzUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIW
CgZmaWx0ZXIYBCABKAlSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5
EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFn
ZVRva2VuIowBChBMaXN0Sm9ic1Jlc3BvbnNlEi4KBGpvYnMYASADKAsyGi5nb29nbGUuY2xv
dWQuYmF0Y2gudjEuSm9iUgRqb2JzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUipgEKEExpc3RUYXNr
c1JlcXVlc3QSPgoGcGFyZW50GAEgASgJQibgQQL6QSAKHmJhdGNoLmdvb2dsZWFwaXMuY29t
L1Rhc2tHcm91cFIGcGFyZW50EhYKBmZpbHRlchgCIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6
ZRgDIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuIpABChFM
aXN0VGFza3NSZXNwb25zZRIxCgV0YXNrcxgBIAMoCzIbLmdvb2dsZS5jbG91ZC5iYXRjaC52
MS5UYXNrUgV0YXNrcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4S
IAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIkcKDkdldFRhc2tSZXF1ZXN0EjUK
BG5hbWUYASABKAlCIeBBAvpBGwoZYmF0Y2guZ29vZ2xlYXBpcy5jb20vVGFza1IEbmFtZSLV
AgoRT3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJ
QgPgQQNSBnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3Nh
Z2UYBSABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9u
GAYgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEo
CUID4EEDUgphcGlWZXJzaW9uMqUKCgxCYXRjaFNlcnZpY2USmwEKCUNyZWF0ZUpvYhInLmdv
b2dsZS5jbG91ZC5iYXRjaC52MS5DcmVhdGVKb2JSZXF1ZXN0GhouZ29vZ2xlLmNsb3VkLmJh
dGNoLnYxLkpvYiJJgtPkkwIvIigvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
fS9qb2JzOgNqb2LaQRFwYXJlbnQsam9iLGpvYl9pZBKDAQoGR2V0Sm9iEiQuZ29vZ2xlLmNs
b3VkLmJhdGNoLnYxLkdldEpvYlJlcXVlc3QaGi5nb29nbGUuY2xvdWQuYmF0Y2gudjEuSm9i
IjeC0+STAioSKC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn3aQQRu
YW1lEs8BCglEZWxldGVKb2ISJy5nb29nbGUuY2xvdWQuYmF0Y2gudjEuRGVsZXRlSm9iUmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieoLT5JMCKiooL3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovam9icy8qfdpBBG5hbWXKQUAKFWdvb2dsZS5wcm90
b2J1Zi5FbXB0eRInZ29vZ2xlLmNsb3VkLmJhdGNoLnYxLk9wZXJhdGlvbk1ldGFkYXRhEuwB
CglDYW5jZWxKb2ISJy5nb29nbGUuY2xvdWQuYmF0Y2gudjEuQ2FuY2VsSm9iUmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ilgGC0+STAjQiLy92MS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn06Y2FuY2VsOgEq2kEEbmFtZcpBUgonZ29vZ2xl
LmNsb3VkLmJhdGNoLnYxLkNhbmNlbEpvYlJlc3BvbnNlEidnb29nbGUuY2xvdWQuYmF0Y2gu
djEuT3BlcmF0aW9uTWV0YWRhdGESlgEKCExpc3RKb2JzEiYuZ29vZ2xlLmNsb3VkLmJhdGNo
LnYxLkxpc3RKb2JzUmVxdWVzdBonLmdvb2dsZS5jbG91ZC5iYXRjaC52MS5MaXN0Sm9ic1Jl
c3BvbnNlIjmC0+STAioSKC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2pv
YnPaQQZwYXJlbnQSmwEKB0dldFRhc2sSJS5nb29nbGUuY2xvdWQuYmF0Y2gudjEuR2V0VGFz
a1JlcXVlc3QaGy5nb29nbGUuY2xvdWQuYmF0Y2gudjEuVGFzayJMgtPkkwI/Ej0vdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyovdGFza0dyb3Vwcy8qL3Rhc2tzLyp9
2kEEbmFtZRKuAQoJTGlzdFRhc2tzEicuZ29vZ2xlLmNsb3VkLmJhdGNoLnYxLkxpc3RUYXNr
c1JlcXVlc3QaKC5nb29nbGUuY2xvdWQuYmF0Y2gudjEuTGlzdFRhc2tzUmVzcG9uc2UiToLT
5JMCPxI9L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyovdGFza0dy
b3Vwcy8qfS90YXNrc9pBBnBhcmVudBpIykEUYmF0Y2guZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQqsBChljb20uZ29v
Z2xlLmNsb3VkLmJhdGNoLnYxQgpCYXRjaFByb3RvUAFaL2Nsb3VkLmdvb2dsZS5jb20vZ28v
YmF0Y2gvYXBpdjEvYmF0Y2hwYjtiYXRjaHBiogIDR0NCqgIVR29vZ2xlLkNsb3VkLkJhdGNo
LlYxygIVR29vZ2xlXENsb3VkXEJhdGNoXFYx6gIYR29vZ2xlOjpDbG91ZDo6QmF0Y2g6OlYx
Sq5NCgcSBQ4AvgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAeCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACUKCQoCAwQS
AxYAIwoJCgIDBRIDFwApCgkKAgMGEgMYACoKCQoCAwcSAxkALQoJCgIDCBIDGgAlCgkKAgMJ
EgMbACkKCAoBCBIDHQAyCgkKAgglEgMdADIKCAoBCBIDHgBGCgkKAggLEgMeAEYKCAoBCBID
HwAiCgkKAggKEgMfACIKCAoBCBIDIAArCgkKAggIEgMgACsKCAoBCBIDIQAyCgkKAggBEgMh
ADIKCAoBCBIDIgAhCgkKAggkEgMiACEKCAoBCBIDIwAyCgkKAggpEgMjADIKCAoBCBIDJAAx
CgkKAggtEgMkADEKlgEKAgYAEgQpAG8BGokBIEdvb2dsZSBCYXRjaCBTZXJ2aWNlLgogVGhl
IHNlcnZpY2UgbWFuYWdlcyB1c2VyIHN1Ym1pdHRlZCBiYXRjaCBqb2JzIGFuZCBhbGxvY2F0
ZXMgR29vZ2xlIENvbXB1dGUKIEVuZ2luZSBWTSBpbnN0YW5jZXMgdG8gcnVuIHRoZSBqb2Jz
LgoKCgoDBgABEgMpCBQKCgoDBgADEgMqAjwKDAoFBgADmQgSAyoCPAoLCgMGAAMSBCsCLDcK
DQoFBgADmggSBCsCLDcKHQoEBgACABIELwI1AxoPIENyZWF0ZSBhIEpvYi4KCgwKBQYAAgAB
EgMvBg8KDAoFBgACAAISAy8QIAoMCgUGAAIAAxIDLysuCg0KBQYAAgAEEgQwBDMGChEKCQYA
AgAEsMq8IhIEMAQzBgoMCgUGAAIABBIDNAQ/Cg8KCAYAAgAEmwgAEgM0BD8KOQoEBgACARIE
OAI9AxorIEdldCBhIEpvYiBzcGVjaWZpZWQgYnkgaXRzIHJlc291cmNlIG5hbWUuCgoMCgUG
AAIBARIDOAYMCgwKBQYAAgECEgM4DRoKDAoFBgACAQMSAzglKAoNCgUGAAIBBBIEOQQ7BgoR
CgkGAAIBBLDKvCISBDkEOwYKDAoFBgACAQQSAzwEMgoPCggGAAIBBJsIABIDPAQyCh0KBAYA
AgISBEACSQMaDyBEZWxldGUgYSBKb2IuCgoMCgUGAAICARIDQAYPCgwKBQYAAgICEgNAECAK
DAoFBgACAgMSA0ArRwoNCgUGAAICBBIEQQRDBgoRCgkGAAICBLDKvCISBEEEQwYKDAoFBgAC
AgQSA0QEMgoPCggGAAICBJsIABIDRAQyCg0KBQYAAgIEEgRFBEgGCg8KBwYAAgIEmQgSBEUE
SAYKHQoEBgACAxIETAJWAxoPIENhbmNlbCBhIEpvYi4KCgwKBQYAAgMBEgNMBg8KDAoFBgAC
AwISA0wQIAoMCgUGAAIDAxIDTCtHCg0KBQYAAgMEEgRNBFAGChEKCQYAAgMEsMq8IhIETQRQ
BgoMCgUGAAIDBBIDUQQyCg8KCAYAAgMEmwgAEgNRBDIKDQoFBgACAwQSBFIEVQYKDwoHBgAC
AwSZCBIEUgRVBgo8CgQGAAIEEgRZAl4DGi4gTGlzdCBhbGwgSm9icyBmb3IgYSBwcm9qZWN0
IHdpdGhpbiBhIHJlZ2lvbi4KCgwKBQYAAgQBEgNZBg4KDAoFBgACBAISA1kPHgoMCgUGAAIE
AxIDWSk5Cg0KBQYAAgQEEgRaBFwGChEKCQYAAgQEsMq8IhIEWgRcBgoMCgUGAAIEBBIDXQQ0
Cg8KCAYAAgQEmwgAEgNdBDQKJQoEBgACBRIEYQJmAxoXIFJldHVybiBhIHNpbmdsZSBUYXNr
LgoKDAoFBgACBQESA2EGDQoMCgUGAAIFAhIDYQ4cCgwKBQYAAgUDEgNhJysKDQoFBgACBQQS
BGIEZAYKEQoJBgACBQSwyrwiEgRiBGQGCgwKBQYAAgUEEgNlBDIKDwoIBgACBQSbCAASA2UE
MgoxCgQGAAIGEgRpAm4DGiMgTGlzdCBUYXNrcyBhc3NvY2lhdGVkIHdpdGggYSBqb2IuCgoM
CgUGAAIGARIDaQYPCgwKBQYAAgYCEgNpECAKDAoFBgACBgMSA2krPAoNCgUGAAIGBBIEagRs
BgoRCgkGAAIGBLDKvCISBGoEbAYKDAoFBgACBgQSA20ENAoPCggGAAIGBJsIABIDbQQ0CiEK
AgQAEgVyAJYBARoUIENyZWF0ZUpvYiBSZXF1ZXN0LgoKCgoDBAABEgNyCBgKhQEKBAQAAgAS
BHUCeAQadyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lIHdoZXJlIHRoZSBK
b2Igd2lsbCBiZSBjcmVhdGVkLgogUGF0dGVybjogInByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufSIKCgwKBQQAAgAFEgN1AggKDAoFBAACAAESA3UJDwoMCgUEAAIA
AxIDdRITCg0KBQQAAgAIEgR1FHgDCg8KCAQAAgAInAgAEgN2BCoKDgoHBAACAAifCBIDdwRQ
CtkDCgQEAAIBEgSDAQIUGsoDIElEIHVzZWQgdG8gdW5pcXVlbHkgaWRlbnRpZnkgdGhlIEpv
YiB3aXRoaW4gaXRzIHBhcmVudCBzY29wZS4KIFRoaXMgZmllbGQgc2hvdWxkIGNvbnRhaW4g
YXQgbW9zdCA2MyBjaGFyYWN0ZXJzIGFuZCBtdXN0IHN0YXJ0IHdpdGgKIGxvd2VyY2FzZSBj
aGFyYWN0ZXJzLgogT25seSBsb3dlcmNhc2UgY2hhcmFjdGVycywgbnVtYmVycyBhbmQgJy0n
IGFyZSBhY2NlcHRlZC4KIFRoZSAnLScgY2hhcmFjdGVyIGNhbm5vdCBiZSB0aGUgZmlyc3Qg
b3IgdGhlIGxhc3Qgb25lLgogQSBzeXN0ZW0gZ2VuZXJhdGVkIElEIHdpbGwgYmUgdXNlZCBp
ZiB0aGUgZmllbGQgaXMgbm90IHNldC4KCiBUaGUgam9iLm5hbWUgZmllbGQgaW4gdGhlIHJl
cXVlc3Qgd2lsbCBiZSBpZ25vcmVkIGFuZCB0aGUgY3JlYXRlZCByZXNvdXJjZQogbmFtZSBv
ZiB0aGUgSm9iIHdpbGwgYmUgIntwYXJlbnR9L2pvYnMve2pvYl9pZH0iLgoKDQoFBAACAQUS
BIMBAggKDQoFBAACAQESBIMBCQ8KDQoFBAACAQMSBIMBEhMKLAoEBAACAhIEhgECNxoeIFJl
cXVpcmVkLiBUaGUgSm9iIHRvIGNyZWF0ZS4KCg0KBQQAAgIGEgSGAQIFCg0KBQQAAgIBEgSG
AQYJCg0KBQQAAgIDEgSGAQwNCg0KBQQAAgIIEgSGAQ42ChAKCAQAAgIInAgAEgSGAQ81Co8G
CgQEAAIDEgSVAQJBGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlk
ZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQg
aWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0
bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVk
LiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51
dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBh
IHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUg
cmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGgg
dGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFs
IG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5k
IGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMK
IGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1l
bnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4
Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAw
MC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQAAgMFEgSVAQIICg0KBQQAAgMBEgSV
AQkTCg0KBQQAAgMDEgSVARYXCg0KBQQAAgMIEgSVARhAChAKCAQAAgMInAgAEgSVARk/Ch8K
AgQBEgaZAQCfAQEaESBHZXRKb2IgUmVxdWVzdC4KCgsKAwQBARIEmQEIFQolCgQEAQIAEgab
AQKeAQQaFSBSZXF1aXJlZC4gSm9iIG5hbWUuCgoNCgUEAQIABRIEmwECCAoNCgUEAQIAARIE
mwEJDQoNCgUEAQIAAxIEmwEQEQoPCgUEAQIACBIGmwESngEDChAKCAQBAgAInAgAEgScAQQq
Cg8KBwQBAgAInwgSBJ0BBEoKIgoCBAISBqIBALcBARoUIERlbGV0ZUpvYiBSZXF1ZXN0LgoK
CwoDBAIBEgSiAQgYChkKBAQCAgASBKQBAhIaCyBKb2IgbmFtZS4KCg0KBQQCAgAFEgSkAQII
Cg0KBQQCAgABEgSkAQkNCg0KBQQCAgADEgSkARARCjMKBAQCAgESBKcBAj0aJSBPcHRpb25h
bC4gUmVhc29uIGZvciB0aGlzIGRlbGV0aW9uLgoKDQoFBAICAQUSBKcBAggKDQoFBAICAQES
BKcBCQ8KDQoFBAICAQMSBKcBEhMKDQoFBAICAQgSBKcBFDwKEAoIBAICAQicCAASBKcBFTsK
jwYKBAQCAgISBLYBAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8g
aWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhh
dCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93
IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0
ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1p
bnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVy
IGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRo
ZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0
aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2lu
YWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBh
bmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50
cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0
bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUg
ZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0w
MDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAgUSBLYBAggKDQoFBAICAgES
BLYBCRMKDQoFBAICAgMSBLYBFhcKDQoFBAICAggSBLYBGEAKEAoIBAICAgicCAASBLYBGT8K
IgoCBAMSBroBANIBARoUIENhbmNlbEpvYiBSZXF1ZXN0LgoKCwoDBAMBEgS6AQgYCiUKBAQD
AgASBrwBAr8BBBoVIFJlcXVpcmVkLiBKb2IgbmFtZS4KCg0KBQQDAgAFEgS8AQIICg0KBQQD
AgABEgS8AQkNCg0KBQQDAgADEgS8ARARCg8KBQQDAgAIEga8ARK/AQMKEAoIBAMCAAicCAAS
BL0BBCoKDwoHBAMCAAifCBIEvgEESgqRBgoEBAMCARIGzgEC0QEEGoAGIE9wdGlvbmFsLiBB
biBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEg
dW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1
ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0
IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRl
ZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0
LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBh
biBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBt
YWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBz
ZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJl
cXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vj
b25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkg
Y3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3Qg
YmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwog
bm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4K
Cg0KBQQDAgEFEgTOAQIICg0KBQQDAgEBEgTOAQkTCg0KBQQDAgEDEgTOARYXCg8KBQQDAgEI
EgbOARjRAQMKEwoLBAMCAQjM8fmKAQESBM8BBCoKEAoIBAMCAQicCAASBNABBCoKMAoCBAQS
BNUBABwaJCBSZXNwb25zZSB0byB0aGUgQ2FuY2VsSm9iIHJlcXVlc3QuCgoLCgMEBAESBNUB
CBkKIAoCBAUSBtgBAOgBARoSIExpc3RKb2IgUmVxdWVzdC4KCgsKAwQFARIE2AEIFwocCgQE
BQIAEgTaAQIUGg4gUGFyZW50IHBhdGguCgoNCgUEBQIABRIE2gECCAoNCgUEBQIAARIE2gEJ
DwoNCgUEBQIAAxIE2gESEwocCgQEBQIBEgTdAQIUGg4gTGlzdCBmaWx0ZXIuCgoNCgUEBQIB
BRIE3QECCAoNCgUEBQIBARIE3QEJDwoNCgUEBQIBAxIE3QESEwpyCgQEBQICEgThAQI/GmQg
T3B0aW9uYWwuIFNvcnQgcmVzdWx0cy4gU3VwcG9ydGVkIGFyZSAibmFtZSIsICJuYW1lIGRl
c2MiLCAiY3JlYXRlX3RpbWUiLAogYW5kICJjcmVhdGVfdGltZSBkZXNjIi4KCg0KBQQFAgIF
EgThAQIICg0KBQQFAgIBEgThAQkRCg0KBQQFAgIDEgThARQVCg0KBQQFAgIIEgThARY+ChAK
CAQFAgIInAgAEgThARc9ChoKBAQFAgMSBOQBAhYaDCBQYWdlIHNpemUuCgoNCgUEBQIDBRIE
5AECBwoNCgUEBQIDARIE5AEIEQoNCgUEBQIDAxIE5AEUFQobCgQEBQIEEgTnAQIYGg0gUGFn
ZSB0b2tlbi4KCg0KBQQFAgQFEgTnAQIICg0KBQQFAgQBEgTnAQkTCg0KBQQFAgQDEgTnARYX
CiEKAgQGEgbrAQD0AQEaEyBMaXN0Sm9iIFJlc3BvbnNlLgoKCwoDBAYBEgTrAQgYChUKBAQG
AgASBO0BAhgaByBKb2JzLgoKDQoFBAYCAAQSBO0BAgoKDQoFBAYCAAYSBO0BCw4KDQoFBAYC
AAESBO0BDxMKDQoFBAYCAAMSBO0BFhcKIAoEBAYCARIE8AECHRoSIE5leHQgcGFnZSB0b2tl
bi4KCg0KBQQGAgEFEgTwAQIICg0KBQQGAgEBEgTwAQkYCg0KBQQGAgEDEgTwARscCjQKBAQG
AgISBPMBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQG
AgIEEgTzAQIKCg0KBQQGAgIFEgTzAQsRCg0KBQQGAgIBEgTzARIdCg0KBQQGAgIDEgTzASAh
CiIKAgQHEgb3AQCKAgEaFCBMaXN0VGFza3MgUmVxdWVzdC4KCgsKAwQHARIE9wEIGAquAQoE
BAcCABIG+wEC/gEEGp0BIFJlcXVpcmVkLiBOYW1lIG9mIGEgVGFza0dyb3VwIGZyb20gd2hp
Y2ggVGFza3MgYXJlIGJlaW5nIHJlcXVlc3RlZC4KIFBhdHRlcm46CiAicHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2pvYnMve2pvYn0vdGFza0dyb3Vwcy97dGFz
a19ncm91cH0iCgoNCgUEBwIABRIE+wECCAoNCgUEBwIAARIE+wEJDwoNCgUEBwIAAxIE+wES
EwoPCgUEBwIACBIG+wEU/gEDChAKCAQHAgAInAgAEgT8AQQqCg8KBwQHAgAInwgSBP0BBFAK
jQEKBAQHAgESBIMCAhQafyBUYXNrIGZpbHRlciwgbnVsbCBmaWx0ZXIgbWF0Y2hlcyBhbGwg
VGFza3MuCiBGaWx0ZXIgc3RyaW5nIHNob3VsZCBiZSBvZiB0aGUgZm9ybWF0IFN0YXRlPVRh
c2tTdGF0dXMuU3RhdGUgZS5nLgogU3RhdGU9UlVOTklORwoKDQoFBAcCAQUSBIMCAggKDQoF
BAcCAQESBIMCCQ8KDQoFBAcCAQMSBIMCEhMKGgoEBAcCAhIEhgICFhoMIFBhZ2Ugc2l6ZS4K
Cg0KBQQHAgIFEgSGAgIHCg0KBQQHAgIBEgSGAggRCg0KBQQHAgIDEgSGAhQVChsKBAQHAgMS
BIkCAhgaDSBQYWdlIHRva2VuLgoKDQoFBAcCAwUSBIkCAggKDQoFBAcCAwESBIkCCRMKDQoF
BAcCAwMSBIkCFhcKIwoCBAgSBo0CAJYCARoVIExpc3RUYXNrcyBSZXNwb25zZS4KCgsKAwQI
ARIEjQIIGQoWCgQECAIAEgSPAgIaGgggVGFza3MuCgoNCgUECAIABBIEjwICCgoNCgUECAIA
BhIEjwILDwoNCgUECAIAARIEjwIQFQoNCgUECAIAAxIEjwIYGQogCgQECAIBEgSSAgIdGhIg
TmV4dCBwYWdlIHRva2VuLgoKDQoFBAgCAQUSBJICAggKDQoFBAgCAQESBJICCRgKDQoFBAgC
AQMSBJICGxwKNAoEBAgCAhIElQICIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSBy
ZWFjaGVkLgoKDQoFBAgCAgQSBJUCAgoKDQoFBAgCAgUSBJUCCxEKDQoFBAgCAgESBJUCEh0K
DQoFBAgCAgMSBJUCICEKMgoCBAkSBpkCAJ8CARokIFJlcXVlc3QgZm9yIGEgc2luZ2xlIFRh
c2sgYnkgbmFtZS4KCgsKAwQJARIEmQIIFgomCgQECQIAEgabAgKeAgQaFiBSZXF1aXJlZC4g
VGFzayBuYW1lLgoKDQoFBAkCAAUSBJsCAggKDQoFBAkCAAESBJsCCQ0KDQoFBAkCAAMSBJsC
EBEKDwoFBAkCAAgSBpsCEp4CAwoQCggECQIACJwIABIEnAIEKgoPCgcECQIACJ8IEgSdAgRL
CkYKAgQKEgaiAgC+AgEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1y
dW5uaW5nIG9wZXJhdGlvbi4KCgsKAwQKARIEogIIGQpCCgQECgIAEgakAgKlAjIaMiBPdXRw
dXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQKAgAG
EgSkAgIbCg0KBQQKAgABEgSkAhwnCg0KBQQKAgADEgSkAiorCg0KBQQKAgAIEgSlAgYxChAK
CAQKAgAInAgAEgSlAgcwCkcKBAQKAgESBqgCAqkCMho3IE91dHB1dCBvbmx5LiBUaGUgdGlt
ZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoNCgUECgIBBhIEqAICGwoNCgUE
CgIBARIEqAIcJAoNCgUECgIBAxIEqAInKAoNCgUECgIBCBIEqQIGMQoQCggECgIBCJwIABIE
qQIHMApaCgQECgICEgSsAgJAGkwgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291
cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQgb2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQKAgIFEgSs
AgIICg0KBQQKAgIBEgSsAgkPCg0KBQQKAgIDEgSsAhITCg0KBQQKAgIIEgSsAhQ/ChAKCAQK
AgIInAgAEgSsAhU+CkgKBAQKAgMSBK8CAj4aOiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUg
dmVyYiBleGVjdXRlZCBieSB0aGUgb3BlcmF0aW9uLgoKDQoFBAoCAwUSBK8CAggKDQoFBAoC
AwESBK8CCQ0KDQoFBAoCAwMSBK8CEBEKDQoFBAoCAwgSBK8CEj0KEAoIBAoCAwicCAASBK8C
EzwKTAoEBAoCBBIEsgICSBo+IE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMg
b2YgdGhlIG9wZXJhdGlvbiwgaWYgYW55LgoKDQoFBAoCBAUSBLICAggKDQoFBAoCBAESBLIC
CRcKDQoFBAoCBAMSBLICGhsKDQoFBAoCBAgSBLICHEcKEAoIBAoCBAicCAASBLICHUYK0QIK
BAQKAgUSBLoCAk4awgIgT3V0cHV0IG9ubHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNl
ciBoYXMgcmVxdWVzdGVkIGNhbmNlbGxhdGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0
aW9ucyB0aGF0IGhhdmUgc3VjY2Vzc2Z1bGx5IGJlZW4gY2FuY2VsbGVkCiBoYXZlCiBbZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbi5lcnJvcl0KIHZhbHVlIHdpdGggYSBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1b
Z29vZ2xlLnJwYy5TdGF0dXMuY29kZV0gb2YgMSwKIGNvcnJlc3BvbmRpbmcgdG8gYENvZGUu
Q0FOQ0VMTEVEYC4KCg0KBQQKAgUFEgS6AgIGCg0KBQQKAgUBEgS6AgcdCg0KBQQKAgUDEgS6
AiAhCg0KBQQKAgUIEgS6AiJNChAKCAQKAgUInAgAEgS6AiNMCkUKBAQKAgYSBL0CAkUaNyBP
dXRwdXQgb25seS4gQVBJIHZlcnNpb24gdXNlZCB0byBzdGFydCB0aGUgb3BlcmF0aW9uLgoK
DQoFBAoCBgUSBL0CAggKDQoFBAoCBgESBL0CCRQKDQoFBAoCBgMSBL0CFxgKDQoFBAoCBggS
BL0CGUQKEAoIBAoCBgicCAASBL0CGkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Batch::V1::Batch::CreateJobRequest ===
    # Fields for CreateJobRequest
    # Field: parent Type: 9 ()
    # Field: job_id Type: 9 ()
    # Field: job Type: 11 (.google.cloud.batch.v1.Job)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::GetJobRequest ===
    # Fields for GetJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::DeleteJobRequest ===
    # Fields for DeleteJobRequest
    # Field: name Type: 9 ()
    # Field: reason Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::CancelJobRequest ===
    # Fields for CancelJobRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::CancelJobResponse ===
    # Fields for CancelJobResponse

# === Message: Google::Cloud::Batch::V1::Batch::ListJobsRequest ===
    # Fields for ListJobsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::ListJobsResponse ===
    # Fields for ListJobsResponse
    # Field: jobs Type: 11 (.google.cloud.batch.v1.Job)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::ListTasksRequest ===
    # Fields for ListTasksRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::ListTasksResponse ===
    # Fields for ListTasksResponse
    # Field: tasks Type: 11 (.google.cloud.batch.v1.Task)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::GetTaskRequest ===
    # Fields for GetTaskRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Batch::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Batch::V1::Batch::BatchServiceClient ===
package Google::Cloud::Batch::V1::Batch::BatchServiceClient;

=pod

=head2 Service Client: Google::Cloud::Batch::V1::Batch::BatchServiceClient

Client stub representing the remote C<BatchService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<batch.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'batch.googleapis.com:443' );

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

sub create_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::CreateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'CreateJob',
        request        => $req,
        response_class => 'Google::Cloud::Batch::V1::Job::Job',
    });
}

sub get_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::GetJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'GetJob',
        request        => $req,
        response_class => 'Google::Cloud::Batch::V1::Job::Job',
    });
}

sub delete_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::DeleteJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'DeleteJob',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub cancel_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::CancelJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'CancelJob',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::ListJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'ListJobs',
        request        => $req,
        response_class => 'Google::Cloud::Batch::V1::Batch::ListJobsResponse',
    });
}

sub get_task {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::GetTaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'GetTask',
        request        => $req,
        response_class => 'Google::Cloud::Batch::V1::Task::Task',
    });
}

sub list_tasks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Batch::V1::Batch::ListTasksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.batch.v1.BatchService',
        method         => 'ListTasks',
        request        => $req,
        response_class => 'Google::Cloud::Batch::V1::Batch::ListTasksResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Batch::V1::Batch - Compiled Protocol Buffers messages for google/cloud/batch/v1/batch.proto

=head1 SYNOPSIS

    use Google::Cloud::Batch::V1::Batch;

    my $msg = Google::Cloud::Batch::V1::Batch::CreateJobRequest->new({
        parent => $parent,
        job_id => $job_id,
        job => $job,
        request_id => $request_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Batch::V1::Batch::CreateJobRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/batch/v1/batch.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Batch::V1::Batch::CreateJobRequest

CreateJob Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the Job will be created.
Pattern: "projects/{project}/locations/{location}"

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

ID used to uniquely identify the Job within its parent scope.
This field should contain at most 63 characters and must start with
lowercase characters.
Only lowercase characters, numbers and '-' are accepted.
The '-' character cannot be the first or the last one.
A system generated ID will be used if the field is not set.

The job.name field in the request will be ignored and the created resource
name of the Job will be "{parent}/jobs/{job_id}".

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1::Job::Job>)

Required. The Job to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Batch::V1::Batch::GetJobRequest

GetJob Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Job name.

=back

=head2 Google::Cloud::Batch::V1::Batch::DeleteJobRequest

DeleteJob Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Job name.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Optional. Reason for this deletion.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Batch::V1::Batch::CancelJobRequest

CancelJob Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Job name.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Batch::V1::Batch::CancelJobResponse

Response to the CancelJob request.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Batch::V1::Batch::ListJobsRequest

ListJob Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Parent path.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Sort results. Supported are "name", "name desc", "create_time",
and "create_time desc".

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=back

=head2 Google::Cloud::Batch::V1::Batch::ListJobsResponse

ListJob Response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1::Job::Job>)

Jobs.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Batch::V1::Batch::ListTasksRequest

ListTasks Request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of a TaskGroup from which Tasks are being requested.
Pattern:
"projects/{project}/locations/{location}/jobs/{job}/taskGroups/{task_group}"

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Task filter, null filter matches all Tasks.
Filter string should be of the format State=TaskStatus.State e.g.
State=RUNNING

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=back

=head2 Google::Cloud::Batch::V1::Batch::ListTasksResponse

ListTasks Response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tasks() >> / C<< $msg->tasks($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1::Task::Task>)

Tasks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Batch::V1::Batch::GetTaskRequest

Request for a single Task by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Task name.

=back

=head2 Google::Cloud::Batch::V1::Batch::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Batch::V1::Batch::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
