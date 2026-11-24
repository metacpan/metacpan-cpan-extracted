package Google::Cloud::Retail::V2beta::UserEventService;

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
    eval { require Google::Api::Httpbody };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Retail::V2beta::ExportConfig };
    eval { require Google::Cloud::Retail::V2beta::ImportConfig };
    eval { require Google::Cloud::Retail::V2beta::PurgeConfig };
    eval { require Google::Cloud::Retail::V2beta::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS91c2VyX2V2ZW50X3NlcnZpY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9odHRwYm9keS5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxouZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvZXhwb3J0X2NvbmZpZy5wcm90
bxouZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvaW1wb3J0X2NvbmZpZy5wcm90bxotZ29v
Z2xlL2Nsb3VkL3JldGFpbC92MmJldGEvcHVyZ2VfY29uZmlnLnByb3RvGitnb29nbGUvY2xv
dWQvcmV0YWlsL3YyYmV0YS91c2VyX2V2ZW50LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90byKgAQoVV3JpdGVVc2VyRXZlbnRSZXF1ZXN0EhsKBnBhcmVudBgB
IAEoCUID4EECUgZwYXJlbnQSSQoKdXNlcl9ldmVudBgCIAEoCzIlLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhLlVzZXJFdmVudEID4EECUgl1c2VyRXZlbnQSHwoLd3JpdGVfYXN5bmMY
AyABKAhSCndyaXRlQXN5bmMi0wEKF0NvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0EiUKDXByZWJ1
aWx0X3J1bGUYBiABKAlIAFIMcHJlYnVpbHRSdWxlEhsKBnBhcmVudBgBIAEoCUID4EECUgZw
YXJlbnQSIgoKdXNlcl9ldmVudBgCIAEoCUID4EECUgl1c2VyRXZlbnQSEAoDdXJpGAMgASgJ
UgN1cmkSEAoDZXRzGAQgASgDUgNldHMSGQoIcmF3X2pzb24YBSABKAlSB3Jhd0pzb25CEQoP
Y29udmVyc2lvbl9ydWxlIqACChdSZWpvaW5Vc2VyRXZlbnRzUmVxdWVzdBIbCgZwYXJlbnQY
ASABKAlCA+BBAlIGcGFyZW50En8KF3VzZXJfZXZlbnRfcmVqb2luX3Njb3BlGAIgASgOMkgu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUmVqb2luVXNlckV2ZW50c1JlcXVlc3QuVXNl
ckV2ZW50UmVqb2luU2NvcGVSFHVzZXJFdmVudFJlam9pblNjb3BlImcKFFVzZXJFdmVudFJl
am9pblNjb3BlEicKI1VTRVJfRVZFTlRfUkVKT0lOX1NDT1BFX1VOU1BFQ0lGSUVEEAASEQoN
Sk9JTkVEX0VWRU5UUxABEhMKD1VOSk9JTkVEX0VWRU5UUxACIlcKGFJlam9pblVzZXJFdmVu
dHNSZXNwb25zZRI7ChpyZWpvaW5lZF91c2VyX2V2ZW50c19jb3VudBgBIAEoA1IXcmVqb2lu
ZWRVc2VyRXZlbnRzQ291bnQiGgoYUmVqb2luVXNlckV2ZW50c01ldGFkYXRhMucMChBVc2Vy
RXZlbnRTZXJ2aWNlEsMBCg5Xcml0ZVVzZXJFdmVudBIxLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLldyaXRlVXNlckV2ZW50UmVxdWVzdBolLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLlVzZXJFdmVudCJXgtPkkwJRIkMvdjJiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jYXRhbG9ncy8qfS91c2VyRXZlbnRzOndyaXRlOgp1c2VyX2V2ZW50EvoBChBD
b2xsZWN0VXNlckV2ZW50EjMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29sbGVjdFVz
ZXJFdmVudFJlcXVlc3QaFC5nb29nbGUuYXBpLkh0dHBCb2R5IpoBgtPkkwKTARJFL3YyYmV0
YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vdXNlckV2ZW50
czpjb2xsZWN0WkoiRS92MmJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nh
dGFsb2dzLyp9L3VzZXJFdmVudHM6Y29sbGVjdDoBKhKWAgoPUHVyZ2VVc2VyRXZlbnRzEjIu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24irwGC0+STAkgiQy92MmJldGEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6cHVyZ2U6ASrK
QV4KMmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlB1cmdlVXNlckV2ZW50c1Jlc3BvbnNl
Eihnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QdXJnZU1ldGFkYXRhEpsCChBJbXBvcnRV
c2VyRXZlbnRzEjMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0VXNlckV2ZW50
c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrIBgtPkkwJJIkQvdjJi
ZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS91c2VyRXZl
bnRzOmltcG9ydDoBKspBYAozZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0VXNl
ckV2ZW50c1Jlc3BvbnNlEilnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5JbXBvcnRNZXRh
ZGF0YRKbAgoQRXhwb3J0VXNlckV2ZW50cxIzLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkV4cG9ydFVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biKyAYLT5JMCSSJEL3YyYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0
YWxvZ3MvKn0vdXNlckV2ZW50czpleHBvcnQ6ASrKQWAKM2dvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLkV4cG9ydFVzZXJFdmVudHNSZXNwb25zZRIpZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuRXhwb3J0TWV0YWRhdGES7wEKEFJlam9pblVzZXJFdmVudHMSMy5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYmV0YS5SZWpvaW5Vc2VyRXZlbnRzUmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24ihgGC0+STAkkiRC92MmJldGEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6cmVqb2luOgEqykE0ChhSZWpv
aW5Vc2VyRXZlbnRzUmVzcG9uc2USGFJlam9pblVzZXJFdmVudHNNZXRhZGF0YRpJykEVcmV0
YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybULUAQoeY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhQhVVc2Vy
RXZlbnRTZXJ2aWNlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJi
ZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3VkLlJldGFpbC5W
MkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6Q2xvdWQ6OlJl
dGFpbDo6VjJiZXRhStI5CgcSBQ4A6AEjCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAIwoJCgIDBRIDFwA4CgkKAgMGEgMYADgKCQoCAwcSAxkANwoJCgID
CBIDGgA1CgkKAgMJEgMbAC0KCAoBCBIDHQA3CgkKAgglEgMdADcKCAoBCBIDHgBNCgkKAggL
EgMeAE0KCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAA2CgkKAggIEgMgADYKCAoBCBID
IQA3CgkKAggBEgMhADcKCAoBCBIDIgAkCgkKAggkEgMiACQKCAoBCBIDIwA3CgkKAggpEgMj
ADcKCAoBCBIDJAA2CgkKAggtEgMkADYKTgoCBgASBScAiwEBGkEgU2VydmljZSBmb3IgaW5n
ZXN0aW5nIGVuZCB1c2VyIGFjdGlvbnMgb24gdGhlIGN1c3RvbWVyIHdlYnNpdGUuCgoKCgMG
AAESAycIGAoKCgMGAAMSAygCPQoMCgUGAAOZCBIDKAI9CgsKAwYAAxIEKQIqNwoNCgUGAAOa
CBIEKQIqNworCgQGAAIAEgQtAjIDGh0gV3JpdGVzIGEgc2luZ2xlIHVzZXIgZXZlbnQuCgoM
CgUGAAIAARIDLQYUCgwKBQYAAgACEgMtFSoKDAoFBgACAAMSAy01PgoNCgUGAAIABBIELgQx
BgoRCgkGAAIABLDKvCISBC4EMQYKxAIKBAYAAgESBDsCQwMatQIgV3JpdGVzIGEgc2luZ2xl
IHVzZXIgZXZlbnQgZnJvbSB0aGUgYnJvd3Nlci4KCiBGb3IgbGFyZ2VyIHVzZXIgZXZlbnQg
cGF5bG9hZCBvdmVyIDE2IEtCLCB0aGUgUE9TVCBtZXRob2Qgc2hvdWxkIGJlIHVzZWQKIGlu
c3RlYWQsIG90aGVyd2lzZSBhIDQwMCBCYWQgUmVxdWVzdCBlcnJvciBpcyByZXR1cm5lZC4K
CiBUaGlzIG1ldGhvZCBpcyB1c2VkIG9ubHkgYnkgdGhlIFJldGFpbCBBUEkgSmF2YVNjcmlw
dCBwaXhlbCBhbmQgR29vZ2xlIFRhZwogTWFuYWdlci4gVXNlcnMgc2hvdWxkIG5vdCBjYWxs
IHRoaXMgbWV0aG9kIGRpcmVjdGx5LgoKDAoFBgACAQESAzsGFgoMCgUGAAIBAhIDOxcuCgwK
BQYAAgEDEgM7OUwKDQoFBgACAQQSBDwEQgYKEQoJBgACAQSwyrwiEgQ8BEIGCvcBCgQGAAIC
EgRJAlMDGugBIERlbGV0ZXMgcGVybWFuZW50bHkgYWxsIHVzZXIgZXZlbnRzIHNwZWNpZmll
ZCBieSB0aGUgZmlsdGVyIHByb3ZpZGVkLgogRGVwZW5kaW5nIG9uIHRoZSBudW1iZXIgb2Yg
ZXZlbnRzIHNwZWNpZmllZCBieSB0aGUgZmlsdGVyLCB0aGlzIG9wZXJhdGlvbgogY291bGQg
dGFrZSBob3VycyBvciBkYXlzIHRvIGNvbXBsZXRlLiBUbyB0ZXN0IGEgZmlsdGVyLCB1c2Ug
dGhlIGxpc3QKIGNvbW1hbmQgZmlyc3QuCgoMCgUGAAICARIDSQYVCgwKBQYAAgICEgNJFiwK
DAoFBgACAgMSA0oPKwoNCgUGAAICBBIESwROBgoRCgkGAAICBLDKvCISBEsETgYKDQoFBgAC
AgQSBE8EUgYKDwoHBgACAgSZCBIETwRSBgruAgoEBgACAxIEXAJmAxrfAiBCdWxrIGltcG9y
dCBvZiBVc2VyIGV2ZW50cy4gUmVxdWVzdCBwcm9jZXNzaW5nIG1pZ2h0IGJlCiBzeW5jaHJv
bm91cy4gRXZlbnRzIHRoYXQgYWxyZWFkeSBleGlzdCBhcmUgc2tpcHBlZC4KIFVzZSB0aGlz
IG1ldGhvZCBmb3IgYmFja2ZpbGxpbmcgaGlzdG9yaWNhbCB1c2VyIGV2ZW50cy4KCiBgT3Bl
cmF0aW9uLnJlc3BvbnNlYCBpcyBvZiB0eXBlIGBJbXBvcnRSZXNwb25zZWAuIE5vdGUgdGhh
dCBpdCBpcwogcG9zc2libGUgZm9yIGEgc3Vic2V0IG9mIHRoZSBpdGVtcyB0byBiZSBzdWNj
ZXNzZnVsbHkgaW5zZXJ0ZWQuCiBgT3BlcmF0aW9uLm1ldGFkYXRhYCBpcyBvZiB0eXBlIGBJ
bXBvcnRNZXRhZGF0YWAuCgoMCgUGAAIDARIDXAYWCgwKBQYAAgMCEgNcFy4KDAoFBgACAwMS
A10PKwoNCgUGAAIDBBIEXgRhBgoRCgkGAAIDBLDKvCISBF4EYQYKDQoFBgACAwQSBGIEZQYK
DwoHBgACAwSZCBIEYgRlBgqLAQoEBgACBBIEbAJ2Axp9IEV4cG9ydHMgdXNlciBldmVudHMu
CgogYE9wZXJhdGlvbi5yZXNwb25zZWAgaXMgb2YgdHlwZSBgRXhwb3J0UmVzcG9uc2VgLgog
YE9wZXJhdGlvbi5tZXRhZGF0YWAgaXMgb2YgdHlwZSBgRXhwb3J0TWV0YWRhdGFgLgoKDAoF
BgACBAESA2wGFgoMCgUGAAIEAhIDbBcuCgwKBQYAAgQDEgNtDysKDQoFBgACBAQSBG4EcQYK
EQoJBgACBASwyrwiEgRuBHEGCg0KBQYAAgQEEgRyBHUGCg8KBwYAAgQEmQgSBHIEdQYKvAQK
BAYAAgUSBoABAooBAxqrBCBTdGFydHMgYSB1c2VyLWV2ZW50IHJlam9pbiBvcGVyYXRpb24g
d2l0aCBsYXRlc3QgcHJvZHVjdCBjYXRhbG9nLiBFdmVudHMKIGFyZSBub3QgYW5ub3RhdGVk
IHdpdGggZGV0YWlsZWQgcHJvZHVjdCBpbmZvcm1hdGlvbiBmb3IgcHJvZHVjdHMgdGhhdCBh
cmUKIG1pc3NpbmcgZnJvbSB0aGUgY2F0YWxvZyB3aGVuIHRoZSB1c2VyIGV2ZW50IGlzIGlu
Z2VzdGVkLiBUaGVzZQogZXZlbnRzIGFyZSBzdG9yZWQgYXMgdW5qb2luZWQgZXZlbnRzIHdp
dGggbGltaXRlZCB1c2FnZSBvbiB0cmFpbmluZyBhbmQKIHNlcnZpbmcuIFlvdSBjYW4gdXNl
IHRoaXMgbWV0aG9kIHRvIHN0YXJ0IGEgam9pbiBvcGVyYXRpb24gb24gc3BlY2lmaWVkCiBl
dmVudHMgd2l0aCB0aGUgbGF0ZXN0IHZlcnNpb24gb2YgcHJvZHVjdCBjYXRhbG9nLiBZb3Ug
Y2FuIGFsc28gdXNlIHRoaXMKIG1ldGhvZCB0byBjb3JyZWN0IGV2ZW50cyBqb2luZWQgd2l0
aCB0aGUgd3JvbmcgcHJvZHVjdCBjYXRhbG9nLiBBIHJlam9pbgogb3BlcmF0aW9uIGNhbiB0
YWtlIGhvdXJzIG9yIGRheXMgdG8gY29tcGxldGUuCgoNCgUGAAIFARIEgAEGFgoNCgUGAAIF
AhIEgAEXLgoNCgUGAAIFAxIEgQEPKwoPCgUGAAIFBBIGggEEhQEGChMKCQYAAgUEsMq8IhIG
ggEEhQEGCg8KBQYAAgUEEgaGAQSJAQYKEQoHBgACBQSZCBIGhgEEiQEGCjoKAgQAEgaOAQCb
AQEaLCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFdyaXRlVXNlckV2ZW50IG1ldGhvZC4KCgsKAwQA
ARIEjgEIHQp/CgQEAAIAEgSRAQI9GnEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgY2F0YWxvZyBy
ZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFs
L2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZ2AuCgoNCgUEAAIABRIEkQECCAoNCgUEAAIAARIE
kQEJDwoNCgUEAAIAAxIEkQESEwoNCgUEAAIACBIEkQEUPAoQCggEAAIACJwIABIEkQEVOwou
CgQEAAIBEgSUAQJEGiAgUmVxdWlyZWQuIFVzZXIgZXZlbnQgdG8gd3JpdGUuCgoNCgUEAAIB
BhIElAECCwoNCgUEAAIBARIElAEMFgoNCgUEAAIBAxIElAEZGgoNCgUEAAIBCBIElAEbQwoQ
CggEAAIBCJwIABIElAEcQgquAgoEBAACAhIEmgECFxqfAiBJZiBzZXQgdG8gdHJ1ZSwgdGhl
IHVzZXIgZXZlbnQgd2lsbCBiZSB3cml0dGVuIGFzeW5jaHJvbm91c2x5IGFmdGVyCiB2YWxp
ZGF0aW9uLCBhbmQgdGhlIEFQSSB3aWxsIHJlc3BvbmQgd2l0aG91dCB3YWl0aW5nIGZvciB0
aGUgd3JpdGUuCiBUaGVyZWZvcmUsIHNpbGVudCBmYWlsdXJlcyBjYW4gb2NjdXIgZXZlbiBp
ZiB0aGUgQVBJIHJldHVybnMgc3VjY2Vzcy4gSW4KIGNhc2Ugb2Ygc2lsZW50IGZhaWx1cmVz
LCBlcnJvciBtZXNzYWdlcyBjYW4gYmUgZm91bmQgaW4gU3RhY2tkcml2ZXIgbG9ncy4KCg0K
BQQAAgIFEgSaAQIGCg0KBQQAAgIBEgSaAQcSCg0KBQQAAgIDEgSaARUWCjwKAgQBEgaeAQC/
AQEaLiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIENvbGxlY3RVc2VyRXZlbnQgbWV0aG9kLgoKCwoD
BAEBEgSeAQgfCnYKBAQBCAASBqEBAqUBAxpmIFRoZSBydWxlIHRoYXQgY2FuIGNvbnZlcnQg
dGhlIHJhd19qc29uIHRvIGEgdXNlciBldmVudC4gSXQgaXMgbmVlZGVkCiBvbmx5IHdoZW4g
dGhlIHJhd19qc29uIGlzIHNldC4KCg0KBQQBCAABEgShAQgXCpABCgQEAQIAEgSkAQQdGoEB
IFRoZSBwcmVidWlsdCBydWxlIG5hbWUgdGhhdCBjYW4gY29udmVydCBhIHNwZWNpZmljIHR5
cGUgb2YgcmF3X2pzb24uCiBGb3IgZXhhbXBsZTogImdhNF9icSIgcnVsZSBmb3IgdGhlIEdB
NCB1c2VyIGV2ZW50IHNjaGVtYS4KCg0KBQQBAgAFEgSkAQQKCg0KBQQBAgABEgSkAQsYCg0K
BQQBAgADEgSkARscCnYKBAQBAgESBKkBAj0aaCBSZXF1aXJlZC4gVGhlIHBhcmVudCBjYXRh
bG9nIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9iYWwvY2F0
YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYC4KCg0KBQQBAgEFEgSpAQIICg0KBQQBAgEBEgSpAQkP
Cg0KBQQBAgEDEgSpARITCg0KBQQBAgEIEgSpARQ8ChAKCAQBAgEInAgAEgSpARU7CmMKBAQB
AgISBK0BAkEaVSBSZXF1aXJlZC4gVVJMIGVuY29kZWQgVXNlckV2ZW50IHByb3RvIHdpdGgg
YSBsZW5ndGggbGltaXQgb2YgMiwwMDAsMDAwCiBjaGFyYWN0ZXJzLgoKDQoFBAECAgUSBK0B
AggKDQoFBAECAgESBK0BCRMKDQoFBAECAgMSBK0BFhcKDQoFBAECAggSBK0BGEAKEAoIBAEC
AgicCAASBK0BGT8K8AEKBAQBAgMSBLMBAhEa4QEgVGhlIFVSTCBpbmNsdWRpbmcgY2dpLXBh
cmFtZXRlcnMgYnV0IGV4Y2x1ZGluZyB0aGUgaGFzaCBmcmFnbWVudCB3aXRoIGEKIGxlbmd0
aCBsaW1pdCBvZiA1LDAwMCBjaGFyYWN0ZXJzLiBUaGlzIGlzIG9mdGVuIG1vcmUgdXNlZnVs
IHRoYW4gdGhlCiByZWZlcmVyIFVSTCwgYmVjYXVzZSBtYW55IGJyb3dzZXJzIG9ubHkgc2Vu
ZCB0aGUgZG9tYWluIGZvciAzcmQgcGFydHkKIHJlcXVlc3RzLgoKDQoFBAECAwUSBLMBAggK
DQoFBAECAwESBLMBCQwKDQoFBAECAwMSBLMBDxAKrwEKBAQBAgQSBLgBAhAaoAEgVGhlIGV2
ZW50IHRpbWVzdGFtcCBpbiBtaWxsaXNlY29uZHMuIFRoaXMgcHJldmVudHMgYnJvd3NlciBj
YWNoaW5nIG9mCiBvdGhlcndpc2UgaWRlbnRpY2FsIGdldCByZXF1ZXN0cy4gVGhlIG5hbWUg
aXMgYWJicmV2aWF0ZWQgdG8gcmVkdWNlIHRoZQogcGF5bG9hZCBieXRlcy4KCg0KBQQBAgQF
EgS4AQIHCg0KBQQBAgQBEgS4AQgLCg0KBQQBAgQDEgS4AQ4PCv8BCgQEAQIFEgS+AQIWGvAB
IEFuIGFyYml0cmFyeSBzZXJpYWxpemVkIEpTT04gc3RyaW5nIHRoYXQgY29udGFpbnMgbmVj
ZXNzYXJ5IGluZm9ybWF0aW9uCiB0aGF0IGNhbiBjb21wcmlzZSBhIHVzZXIgZXZlbnQuIFdo
ZW4gdGhpcyBmaWVsZCBpcyBzcGVjaWZpZWQsIHRoZQogdXNlcl9ldmVudCBmaWVsZCB3aWxs
IGJlIGlnbm9yZWQuIE5vdGU6IGxpbmUtZGVsaW1pdGVkIEpTT04gaXMgbm90CiBzdXBwb3J0
ZWQsIGEgc2luZ2xlIEpTT04gb25seS4KCg0KBQQBAgUFEgS+AQIICg0KBQQBAgUBEgS+AQkR
Cg0KBQQBAgUDEgS+ARQVCjwKAgQCEgbCAQDfAQEaLiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFJl
am9pblVzZXJFdmVudHMgbWV0aG9kLgoKCwoDBAIBEgTCAQgfCrkDCgQEAgQAEgbKAQLUAQMa
qAMgVGhlIHNjb3BlIG9mIHVzZXIgZXZlbnRzIHRvIGJlIHJlam9pbmVkIHdpdGggdGhlIGxh
dGVzdCBwcm9kdWN0IGNhdGFsb2cuCiBJZiB0aGUgcmVqb2luaW5nIGFpbXMgYXQgcmVkdWNp
bmcgbnVtYmVyIG9mIHVuam9pbmVkIGV2ZW50cywgc2V0CiBgVXNlckV2ZW50UmVqb2luU2Nv
cGVgIHRvIGBVTkpPSU5FRF9FVkVOVFNgLgogSWYgdGhlIHJlam9pbmluZyBhaW1zIGF0IGNv
cnJlY3RpbmcgcHJvZHVjdCBjYXRhbG9nIGluZm9ybWF0aW9uIGluIGpvaW5lZAogZXZlbnRz
LCBzZXQgYFVzZXJFdmVudFJlam9pblNjb3BlYCB0byBgSk9JTkVEX0VWRU5UU2AuCiBJZiBh
bGwgZXZlbnRzIG5lZWRzIHRvIGJlIHJlam9pbmVkLCBzZXQgYFVzZXJFdmVudFJlam9pblNj
b3BlYCB0bwogYFVTRVJfRVZFTlRfUkVKT0lOX1NDT1BFX1VOU1BFQ0lGSUVEYC4KCg0KBQQC
BAABEgTKAQcbCncKBgQCBAACABIEzQEELBpnIFJlam9pbiBhbGwgZXZlbnRzIHdpdGggdGhl
IGxhdGVzdCBwcm9kdWN0IGNhdGFsb2csIGluY2x1ZGluZyBib3RoIGpvaW5lZAogZXZlbnRz
IGFuZCB1bmpvaW5lZCBldmVudHMuCgoPCgcEAgQAAgABEgTNAQQnCg8KBwQCBAACAAISBM0B
KisKTAoGBAIEAAIBEgTQAQQWGjwgT25seSByZWpvaW4gam9pbmVkIGV2ZW50cyB3aXRoIHRo
ZSBsYXRlc3QgcHJvZHVjdCBjYXRhbG9nLgoKDwoHBAIEAAIBARIE0AEEEQoPCgcEAgQAAgEC
EgTQARQVCk4KBgQCBAACAhIE0wEEGBo+IE9ubHkgcmVqb2luIHVuam9pbmVkIGV2ZW50cyB3
aXRoIHRoZSBsYXRlc3QgcHJvZHVjdCBjYXRhbG9nLgoKDwoHBAIEAAICARIE0wEEEwoPCgcE
AgQAAgICEgTTARYXCn8KBAQCAgASBNgBAj0acSBSZXF1aXJlZC4gVGhlIHBhcmVudCBjYXRh
bG9nIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9n
bG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYC4KCg0KBQQCAgAFEgTYAQIICg0KBQQC
AgABEgTYAQkPCg0KBQQCAgADEgTYARITCg0KBQQCAgAIEgTYARQ8ChAKCAQCAgAInAgAEgTY
ARU7CoYCCgQEAgIBEgTeAQIzGvcBIFRoZSB0eXBlIG9mIHRoZSB1c2VyIGV2ZW50IHJlam9p
biB0byBkZWZpbmUgdGhlIHNjb3BlIGFuZCByYW5nZSBvZiB0aGUgdXNlcgogZXZlbnRzIHRv
IGJlIHJlam9pbmVkIHdpdGggdGhlIGxhdGVzdCBwcm9kdWN0IGNhdGFsb2cuIERlZmF1bHRz
IHRvCiBgVVNFUl9FVkVOVF9SRUpPSU5fU0NPUEVfVU5TUEVDSUZJRURgIGlmIHRoaXMgZmll
bGQgaXMgbm90IHNldCwgb3Igc2V0IHRvCiBhbiBpbnZhbGlkIGludGVnZXIgdmFsdWUuCgoN
CgUEAgIBBhIE3gECFgoNCgUEAgIBARIE3gEXLgoNCgUEAgIBAxIE3gExMgo/CgIEAxIG4gEA
5QEBGjEgUmVzcG9uc2UgbWVzc2FnZSBmb3IgYFJlam9pblVzZXJFdmVudHNgIG1ldGhvZC4K
CgsKAwQDARIE4gEIIApTCgQEAwIAEgTkAQInGkUgTnVtYmVyIG9mIHVzZXIgZXZlbnRzIHRo
YXQgd2VyZSBqb2luZWQgd2l0aCBsYXRlc3QgcHJvZHVjdCBjYXRhbG9nLgoKDQoFBAMCAAUS
BOQBAgcKDQoFBAMCAAESBOQBCCIKDQoFBAMCAAMSBOQBJSYKNQoCBAQSBOgBACMaKSBNZXRh
ZGF0YSBmb3IgYFJlam9pblVzZXJFdmVudHNgIG1ldGhvZC4KCgsKAwQEARIE6AEIIGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2beta.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: prebuilt_rule Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()
    # Field: raw_json Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest ===
    # Fields for RejoinUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: user_event_rejoin_scope Type: 14 (.google.cloud.retail.v2beta.RejoinUserEventsRequest.UserEventRejoinScope)

# Enum: RejoinUserEventsRequest::UserEventRejoinScope
our $RejoinUserEventsRequest_USER_EVENT_REJOIN_SCOPE_UNSPECIFIED = 0;
our $RejoinUserEventsRequest_JOINED_EVENTS = 1;
our $RejoinUserEventsRequest_UNJOINED_EVENTS = 2;

# === Message: Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsResponse ===
    # Fields for RejoinUserEventsResponse
    # Field: rejoined_user_events_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsMetadata ===
    # Fields for RejoinUserEventsMetadata

# === Service Client: Google::Cloud::Retail::V2beta::UserEventService::UserEventServiceClient ===
package Google::Cloud::Retail::V2beta::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::UserEventService::UserEventServiceClient

Client stub representing the remote C<UserEventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub write_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'ExportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rejoin_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'RejoinUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::UserEventService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::UserEventService;

    my $msg = Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event will be written asynchronously after
validation, and the API will respond without waiting for the write.
Therefore, silent failures can occur even if the API returns success. In
case of silent failures, error messages can be found in Stackdriver logs.

=back

=head2 Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest

Request message for CollectUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->prebuilt_rule() >> / C<< $msg->prebuilt_rule($value) >>

Type: C<String>

The prebuilt rule name that can convert a specific type of raw_json.
For example: "ga4_bq" rule for the GA4 user event schema.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<String>

Required. URL encoded UserEvent proto with a length limit of 2,000,000
characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URL including cgi-parameters but excluding the hash fragment with a
length limit of 5,000 characters. This is often more useful than the
referer URL, because many browsers only send the domain for 3rd party
requests.

=item * C<< $msg->ets() >> / C<< $msg->ets($value) >>

Type: C<Int64>

The event timestamp in milliseconds. This prevents browser caching of
otherwise identical get requests. The name is abbreviated to reduce the
payload bytes.

=item * C<< $msg->raw_json() >> / C<< $msg->raw_json($value) >>

Type: C<String>

An arbitrary serialized JSON string that contains necessary information
that can comprise a user event. When this field is specified, the
user_event field will be ignored. Note: line-delimited JSON is not
supported, a single JSON only.

=back

=head2 Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest

Request message for RejoinUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event_rejoin_scope() >> / C<< $msg->user_event_rejoin_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::RejoinUserEventsRequest::UserEventRejoinScope>)

The type of the user event rejoin to define the scope and range of the user
events to be rejoined with the latest product catalog. Defaults to
`USER_EVENT_REJOIN_SCOPE_UNSPECIFIED` if this field is not set, or set to
an invalid integer value.

=back

=head3 Enum: RejoinUserEventsRequest::UserEventRejoinScope

=over 4

=item * C<USER_EVENT_REJOIN_SCOPE_UNSPECIFIED> => C<0>

=item * C<JOINED_EVENTS> => C<1>

=item * C<UNJOINED_EVENTS> => C<2>

=back

=head2 Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsResponse

Response message for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rejoined_user_events_count() >> / C<< $msg->rejoined_user_events_count($value) >>

Type: C<Int64>

Number of user events that were joined with latest product catalog.

=back

=head2 Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsMetadata

Metadata for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
