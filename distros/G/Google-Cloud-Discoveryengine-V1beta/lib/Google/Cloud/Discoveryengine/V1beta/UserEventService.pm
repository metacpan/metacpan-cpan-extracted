package Google::Cloud::Discoveryengine::V1beta::UserEventService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1beta::PurgeConfig };
    eval { require Google::Cloud::Discoveryengine::V1beta::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX2V2ZW50X3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9odHRwYm9keS5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo3Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2lu
ZS92MWJldGEvaW1wb3J0X2NvbmZpZy5wcm90bxo2Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVu
Z2luZS92MWJldGEvcHVyZ2VfY29uZmlnLnByb3RvGjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5
ZW5naW5lL3YxYmV0YS91c2VyX2V2ZW50LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3Bl
cmF0aW9ucy5wcm90byLqAQoVV3JpdGVVc2VyRXZlbnRSZXF1ZXN0EkgKBnBhcmVudBgBIAEo
CUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRGF0YVN0b3JlUgZw
YXJlbnQSVwoKdXNlcl9ldmVudBgCIAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlVzZXJFdmVudEID4EECSABSCXVzZXJFdmVudIgBARIfCgt3cml0ZV9hc3lu
YxgDIAEoCFIKd3JpdGVBc3luY0INCgtfdXNlcl9ldmVudCLFAQoXQ29sbGVjdFVzZXJFdmVu
dFJlcXVlc3QSSAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29n
bGVhcGlzLmNvbS9EYXRhU3RvcmVSBnBhcmVudBIiCgp1c2VyX2V2ZW50GAIgASgJQgPgQQJS
CXVzZXJFdmVudBIVCgN1cmkYAyABKAlIAFIDdXJpiAEBEhUKA2V0cxgEIAEoA0gBUgNldHOI
AQFCBgoEX3VyaUIGCgRfZXRzMvsOChBVc2VyRXZlbnRTZXJ2aWNlEoQDCg5Xcml0ZVVzZXJF
dmVudBI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLldyaXRlVXNlckV2
ZW50UmVxdWVzdBouLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJF
dmVudCKFAoLT5JMC/gEiRS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50czp3cml0ZToKdXNlcl9ldmVudFphIlMvdjFiZXRh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9y
ZXMvKn0vdXNlckV2ZW50czp3cml0ZToKdXNlcl9ldmVudFpGIjgvdjFiZXRhL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vdXNlckV2ZW50czp3cml0ZToKdXNlcl9ldmVudBLQ
AgoQQ29sbGVjdFVzZXJFdmVudBI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkNvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0GhQuZ29vZ2xlLmFwaS5IdHRwQm9keSLnAYLT
5JMC4AESRy92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9y
ZXMvKn0vdXNlckV2ZW50czpjb2xsZWN0WlcSVS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfS91c2VyRXZlbnRzOmNv
bGxlY3RaPBI6L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3VzZXJF
dmVudHM6Y29sbGVjdBKYAwoPUHVyZ2VVc2VyRXZlbnRzEjsuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24iqAKC0+STAqQBIkUvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVudHM6cHVyZ2U6ASpaWCJTL3Yx
YmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyp9L3VzZXJFdmVudHM6cHVyZ2U6ASrKQXoKO2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLlB1cmdlVXNlckV2ZW50c1Jlc3BvbnNlEjtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5QdXJnZVVzZXJFdmVudHNNZXRhZGF0YRLeAwoQSW1w
b3J0VXNlckV2ZW50cxI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLklt
cG9ydFVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLs
AoLT5JMC5gEiRi92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFT
dG9yZXMvKn0vdXNlckV2ZW50czppbXBvcnQ6ASpaWSJUL3YxYmV0YS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVu
dHM6aW1wb3J0OgEqWj4iOS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
fS91c2VyRXZlbnRzOmltcG9ydDoBKspBfAo8Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuSW1wb3J0VXNlckV2ZW50c1Jlc3BvbnNlEjxnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5JbXBvcnRVc2VyRXZlbnRzTWV0YWRhdGEakALKQR5kaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQesBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rp
c2NvdmVyeWVuZ2luZS5hc3Npc3QucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKcAgonY29t
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhVVc2VyRXZlbnRTZXJ2aWNl
UHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRh
L2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5F
qgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRc
RGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2lu
ZTo6VjFiZXRhSs0mCgcSBQ4AuwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYAIwoJCgIDBRIDFwBBCgkKAgMGEgMYAEAKCQoCAwcSAxkAPgoJCgIDCBID
GgAtCggKAQgSAxwAQAoJCgIIJRIDHABACggKAQgSAx0AaAoJCgIICxIDHQBoCggKAQgSAx4A
IgoJCgIIChIDHgAiCggKAQgSAx8ANgoJCgIICBIDHwA2CggKAQgSAyAAQAoJCgIIARIDIABA
CggKAQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAQAoJCgIIKRIDIgBACggKAQgSAyMAPwoJ
CgIILRIDIwA/CloKAgYAEgQmAH0BGk4gU2VydmljZSBmb3IgaW5nZXN0aW5nIGVuZCB1c2Vy
IGFjdGlvbnMgb24gYSB3ZWJzaXRlIHRvIERpc2NvdmVyeSBFbmdpbmUgQVBJLgoKCgoDBgAB
EgMmCBgKCgoDBgADEgMnAkYKDAoFBgADmQgSAycCRgoLCgMGAAMSBCgCLEoKDQoFBgADmggS
BCgCLEoKKwoEBgACABIELwI8AxodIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50LgoKDAoF
BgACAAESAy8GFAoMCgUGAAIAAhIDLxUqCgwKBQYAAgADEgMvNT4KDQoFBgACAAQSBDAEOwYK
EQoJBgACAASwyrwiEgQwBDsGCqYCCgQGAAIBEgRDAk0DGpcCIFdyaXRlcyBhIHNpbmdsZSB1
c2VyIGV2ZW50IGZyb20gdGhlIGJyb3dzZXIuIFRoaXMgdXNlcyBhIEdFVCByZXF1ZXN0IHRv
CiBkdWUgdG8gYnJvd3NlciByZXN0cmljdGlvbiBvZiBQT1NULWluZyB0byBhIHRoaXJkLXBh
cnR5IGRvbWFpbi4KCiBUaGlzIG1ldGhvZCBpcyB1c2VkIG9ubHkgYnkgdGhlIERpc2NvdmVy
eSBFbmdpbmUgQVBJIEphdmFTY3JpcHQgcGl4ZWwgYW5kCiBHb29nbGUgVGFnIE1hbmFnZXIu
IFVzZXJzIHNob3VsZCBub3QgY2FsbCB0aGlzIG1ldGhvZCBkaXJlY3RseS4KCgwKBQYAAgEB
EgNDBhYKDAoFBgACAQISA0MXLgoMCgUGAAIBAxIDQzlMCg0KBQYAAgEEEgREBEwGChEKCQYA
AgEEsMq8IhIERARMBgr3AQoEBgACAhIEUwJhAxroASBEZWxldGVzIHBlcm1hbmVudGx5IGFs
bCB1c2VyIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciBwcm92aWRlZC4KIERlcGVu
ZGluZyBvbiB0aGUgbnVtYmVyIG9mIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciwg
dGhpcyBvcGVyYXRpb24KIGNvdWxkIHRha2UgaG91cnMgb3IgZGF5cyB0byBjb21wbGV0ZS4g
VG8gdGVzdCBhIGZpbHRlciwgdXNlIHRoZSBsaXN0CiBjb21tYW5kIGZpcnN0LgoKDAoFBgAC
AgESA1MGFQoMCgUGAAICAhIDUxYsCgwKBQYAAgIDEgNUDysKDQoFBgACAgQSBFUEXAYKEQoJ
BgACAgSwyrwiEgRVBFwGCg0KBQYAAgIEEgRdBGAGCg8KBwYAAgIEmQgSBF0EYAYK5gIKBAYA
AgMSBGoCfAMa1wIgQnVsayBpbXBvcnQgb2YgdXNlciBldmVudHMuIFJlcXVlc3QgcHJvY2Vz
c2luZyBtaWdodCBiZQogc3luY2hyb25vdXMuIEV2ZW50cyB0aGF0IGFscmVhZHkgZXhpc3Qg
YXJlIHNraXBwZWQuCiBVc2UgdGhpcyBtZXRob2QgZm9yIGJhY2tmaWxsaW5nIGhpc3Rvcmlj
YWwgdXNlciBldmVudHMuCgogT3BlcmF0aW9uLnJlc3BvbnNlIGlzIG9mIHR5cGUgSW1wb3J0
UmVzcG9uc2UuIE5vdGUgdGhhdCBpdCBpcwogcG9zc2libGUgZm9yIGEgc3Vic2V0IG9mIHRo
ZSBpdGVtcyB0byBiZSBzdWNjZXNzZnVsbHkgaW5zZXJ0ZWQuCiBPcGVyYXRpb24ubWV0YWRh
dGEgaXMgb2YgdHlwZSBJbXBvcnRNZXRhZGF0YS4KCgwKBQYAAgMBEgNqBhYKDAoFBgACAwIS
A2oXLgoMCgUGAAIDAxIDaw8rCg0KBQYAAgMEEgRsBHcGChEKCQYAAgMEsMq8IhIEbAR3BgoN
CgUGAAIDBBIEeAR7BgoPCgcGAAIDBJkIEgR4BHsGCjoKAgQAEgaAAQCYAQEaLCBSZXF1ZXN0
IG1lc3NhZ2UgZm9yIFdyaXRlVXNlckV2ZW50IG1ldGhvZC4KCgsKAwQAARIEgAEIHQrTBAoE
BAACABIGiwECkAEEGsIEIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUuCiBJ
ZiB0aGUgd3JpdGUgdXNlciBldmVudCBhY3Rpb24gaXMgYXBwbGllZCBpbgogW0RhdGFTdG9y
ZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXSBsZXZl
bCwgdGhlCiBmb3JtYXQgaXM6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3Jl
fWAuCiBJZiB0aGUgd3JpdGUgdXNlciBldmVudCBhY3Rpb24gaXMgYXBwbGllZCBpbgogW0xv
Y2F0aW9uXVtnb29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25dIGxldmVsLCBmb3IgZXhh
bXBsZSwgdGhlIGV2ZW50CiB3aXRoIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRG9jdW1lbnRdIGFjcm9zcwogbXVsdGlwbGUgW0RhdGFTdG9yZV1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXSwgdGhlCiBm
b3JtYXQgaXM6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoK
DQoFBAACAAUSBIsBAggKDQoFBAACAAESBIsBCQ8KDQoFBAACAAMSBIsBEhMKDwoFBAACAAgS
BosBFJABAwoQCggEAAIACJwIABIEjAEEKgoRCgcEAAIACJ8IEgaNAQSPAQUKLgoEBAACARIE
kwECTRogIFJlcXVpcmVkLiBVc2VyIGV2ZW50IHRvIHdyaXRlLgoKDQoFBAACAQQSBJMBAgoK
DQoFBAACAQYSBJMBCxQKDQoFBAACAQESBJMBFR8KDQoFBAACAQMSBJMBIiMKDQoFBAACAQgS
BJMBJEwKEAoIBAACAQicCAASBJMBJUsKkAEKBAQAAgISBJcBAhcagQEgSWYgc2V0IHRvIHRy
dWUsIHRoZSB1c2VyIGV2ZW50IGlzIHdyaXR0ZW4gYXN5bmNocm9ub3VzbHkgYWZ0ZXIKIHZh
bGlkYXRpb24sIGFuZCB0aGUgQVBJIHJlc3BvbmRzIHdpdGhvdXQgd2FpdGluZyBmb3IgdGhl
IHdyaXRlLgoKDQoFBAACAgUSBJcBAgYKDQoFBAACAgESBJcBBxIKDQoFBAACAgMSBJcBFRYK
PAoCBAESBpsBALsBARouIFJlcXVlc3QgbWVzc2FnZSBmb3IgQ29sbGVjdFVzZXJFdmVudCBt
ZXRob2QuCgoLCgMEAQESBJsBCB8K1wQKBAQBAgASBqYBAqsBBBrGBCBSZXF1aXJlZC4gVGhl
IHBhcmVudCByZXNvdXJjZSBuYW1lLgogSWYgdGhlIGNvbGxlY3QgdXNlciBldmVudCBhY3Rp
b24gaXMgYXBwbGllZCBpbgogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuRGF0YVN0b3JlXSBsZXZlbCwgdGhlCiBmb3JtYXQgaXM6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfWAuCiBJZiB0aGUgY29sbGVjdCB1c2VyIGV2
ZW50IGFjdGlvbiBpcyBhcHBsaWVkIGluCiBbTG9jYXRpb25dW2dvb2dsZS5jbG91ZC5sb2Nh
dGlvbi5Mb2NhdGlvbl0gbGV2ZWwsIGZvciBleGFtcGxlLCB0aGUgZXZlbnQKIHdpdGggW0Rv
Y3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF0g
YWNyb3NzCiBtdWx0aXBsZSBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5EYXRhU3RvcmVdLCB0aGUKIGZvcm1hdCBpczogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoNCgUEAQIABRIEpgECCAoNCgUEAQIAARIE
pgEJDwoNCgUEAQIAAxIEpgESEwoPCgUEAQIACBIGpgEUqwEDChAKCAQBAgAInAgAEgSnAQQq
ChEKBwQBAgAInwgSBqgBBKoBBQpjCgQEAQIBEgSvAQJBGlUgUmVxdWlyZWQuIFVSTCBlbmNv
ZGVkIFVzZXJFdmVudCBwcm90byB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDIsMDAwLDAwMAog
Y2hhcmFjdGVycy4KCg0KBQQBAgEFEgSvAQIICg0KBQQBAgEBEgSvAQkTCg0KBQQBAgEDEgSv
ARYXCg0KBQQBAgEIEgSvARhAChAKCAQBAgEInAgAEgSvARk/CvIBCgQEAQICEgS1AQIaGuMB
IFRoZSBVUkwgaW5jbHVkaW5nIGNnaS1wYXJhbWV0ZXJzIGJ1dCBleGNsdWRpbmcgdGhlIGhh
c2ggZnJhZ21lbnQgd2l0aCBhCiBsZW5ndGggbGltaXQgb2YgNSwwMDAgY2hhcmFjdGVycy4g
VGhpcyBpcyBvZnRlbiBtb3JlIHVzZWZ1bCB0aGFuIHRoZQogcmVmZXJlciBVUkwsIGJlY2F1
c2UgbWFueSBicm93c2VycyBvbmx5IHNlbmQgdGhlIGRvbWFpbiBmb3IgdGhpcmQtcGFydHkK
IHJlcXVlc3RzLgoKDQoFBAECAgQSBLUBAgoKDQoFBAECAgUSBLUBCxEKDQoFBAECAgESBLUB
EhUKDQoFBAECAgMSBLUBGBkKrwEKBAQBAgMSBLoBAhkaoAEgVGhlIGV2ZW50IHRpbWVzdGFt
cCBpbiBtaWxsaXNlY29uZHMuIFRoaXMgcHJldmVudHMgYnJvd3NlciBjYWNoaW5nIG9mCiBv
dGhlcndpc2UgaWRlbnRpY2FsIGdldCByZXF1ZXN0cy4gVGhlIG5hbWUgaXMgYWJicmV2aWF0
ZWQgdG8gcmVkdWNlIHRoZQogcGF5bG9hZCBieXRlcy4KCg0KBQQBAgMEEgS6AQIKCg0KBQQB
AgMFEgS6AQsQCg0KBQQBAgMBEgS6AREUCg0KBQQBAgMDEgS6ARcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1beta.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::UserEventService::UserEventServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::UserEventService::UserEventServiceClient

Client stub representing the remote C<UserEventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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
        ? Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserEventService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::UserEventService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
If the write user event action is applied in
[DataStore][google.cloud.discoveryengine.v1beta.DataStore] level, the
format is:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.
If the write user event action is applied in
[Location][google.cloud.location.Location] level, for example, the event
with [Document][google.cloud.discoveryengine.v1beta.Document] across
multiple [DataStore][google.cloud.discoveryengine.v1beta.DataStore], the
format is: `projects/{project}/locations/{location}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event is written asynchronously after
validation, and the API responds without waiting for the write.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserEventService::CollectUserEventRequest

Request message for CollectUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
If the collect user event action is applied in
[DataStore][google.cloud.discoveryengine.v1beta.DataStore] level, the
format is:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.
If the collect user event action is applied in
[Location][google.cloud.location.Location] level, for example, the event
with [Document][google.cloud.discoveryengine.v1beta.Document] across
multiple [DataStore][google.cloud.discoveryengine.v1beta.DataStore], the
format is: `projects/{project}/locations/{location}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<String>

Required. URL encoded UserEvent proto with a length limit of 2,000,000
characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URL including cgi-parameters but excluding the hash fragment with a
length limit of 5,000 characters. This is often more useful than the
referer URL, because many browsers only send the domain for third-party
requests.

=item * C<< $msg->ets() >> / C<< $msg->ets($value) >>

Type: C<Int64>

The event timestamp in milliseconds. This prevents browser caching of
otherwise identical get requests. The name is abbreviated to reduce the
payload bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
