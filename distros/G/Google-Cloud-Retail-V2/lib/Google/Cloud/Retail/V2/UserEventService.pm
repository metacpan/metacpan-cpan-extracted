package Google::Cloud::Retail::V2::UserEventService;

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
    eval { require Google::Cloud::Retail::V2::ImportConfig };
    eval { require Google::Cloud::Retail::V2::PurgeConfig };
    eval { require Google::Cloud::Retail::V2::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyL3VzZXJfZXZlbnRfc2VydmljZS5wcm90bxIWZ29v
Z2xlLmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvaHR0cGJvZHkucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
Kmdvb2dsZS9jbG91ZC9yZXRhaWwvdjIvaW1wb3J0X2NvbmZpZy5wcm90bxopZ29vZ2xlL2Ns
b3VkL3JldGFpbC92Mi9wdXJnZV9jb25maWcucHJvdG8aJ2dvb2dsZS9jbG91ZC9yZXRhaWwv
djIvdXNlcl9ldmVudC5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJv
dG8inAEKFVdyaXRlVXNlckV2ZW50UmVxdWVzdBIbCgZwYXJlbnQYASABKAlCA+BBAlIGcGFy
ZW50EkUKCnVzZXJfZXZlbnQYAiABKAsyIS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlVzZXJF
dmVudEID4EECUgl1c2VyRXZlbnQSHwoLd3JpdGVfYXN5bmMYAyABKAhSCndyaXRlQXN5bmMi
0wEKF0NvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0EiUKDXByZWJ1aWx0X3J1bGUYBiABKAlIAFIM
cHJlYnVpbHRSdWxlEhsKBnBhcmVudBgBIAEoCUID4EECUgZwYXJlbnQSIgoKdXNlcl9ldmVu
dBgCIAEoCUID4EECUgl1c2VyRXZlbnQSEAoDdXJpGAMgASgJUgN1cmkSEAoDZXRzGAQgASgD
UgNldHMSGQoIcmF3X2pzb24YBSABKAlSB3Jhd0pzb25CEQoPY29udmVyc2lvbl9ydWxlIpwC
ChdSZWpvaW5Vc2VyRXZlbnRzUmVxdWVzdBIbCgZwYXJlbnQYASABKAlCA+BBAlIGcGFyZW50
EnsKF3VzZXJfZXZlbnRfcmVqb2luX3Njb3BlGAIgASgOMkQuZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5SZWpvaW5Vc2VyRXZlbnRzUmVxdWVzdC5Vc2VyRXZlbnRSZWpvaW5TY29wZVIUdXNl
ckV2ZW50UmVqb2luU2NvcGUiZwoUVXNlckV2ZW50UmVqb2luU2NvcGUSJwojVVNFUl9FVkVO
VF9SRUpPSU5fU0NPUEVfVU5TUEVDSUZJRUQQABIRCg1KT0lORURfRVZFTlRTEAESEwoPVU5K
T0lORURfRVZFTlRTEAIiVwoYUmVqb2luVXNlckV2ZW50c1Jlc3BvbnNlEjsKGnJlam9pbmVk
X3VzZXJfZXZlbnRzX2NvdW50GAEgASgDUhdyZWpvaW5lZFVzZXJFdmVudHNDb3VudCIaChhS
ZWpvaW5Vc2VyRXZlbnRzTWV0YWRhdGEyiQoKEFVzZXJFdmVudFNlcnZpY2UStwEKDldyaXRl
VXNlckV2ZW50Ei0uZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Xcml0ZVVzZXJFdmVudFJlcXVl
c3QaIS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlVzZXJFdmVudCJTgtPkkwJNIj8vdjIve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6d3Jp
dGU6CnVzZXJfZXZlbnQS7gEKEENvbGxlY3RVc2VyRXZlbnQSLy5nb29nbGUuY2xvdWQucmV0
YWlsLnYyLkNvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0GhQuZ29vZ2xlLmFwaS5IdHRwQm9keSKS
AYLT5JMCiwESQS92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3Mv
Kn0vdXNlckV2ZW50czpjb2xsZWN0WkYiQS92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovY2F0YWxvZ3MvKn0vdXNlckV2ZW50czpjb2xsZWN0OgEqEoYCCg9QdXJnZVVzZXJF
dmVudHMSLi5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlB1cmdlVXNlckV2ZW50c1JlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqMBgtPkkwJEIj8vdjIve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6cHVyZ2U6ASrK
QVYKLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuUHVyZ2VVc2VyRXZlbnRzUmVzcG9uc2USJGdv
b2dsZS5jbG91ZC5yZXRhaWwudjIuUHVyZ2VNZXRhZGF0YRKLAgoQSW1wb3J0VXNlckV2ZW50
cxIvLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuSW1wb3J0VXNlckV2ZW50c1JlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqYBgtPkkwJFIkAvdjIve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6aW1wb3J0OgEqykFY
Ci9nb29nbGUuY2xvdWQucmV0YWlsLnYyLkltcG9ydFVzZXJFdmVudHNSZXNwb25zZRIlZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRNZXRhZGF0YRLnAQoQUmVqb2luVXNlckV2ZW50
cxIvLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuUmVqb2luVXNlckV2ZW50c1JlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIoIBgtPkkwJFIkAvdjIve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6cmVqb2luOgEqykE0
ChhSZWpvaW5Vc2VyRXZlbnRzUmVzcG9uc2USGFJlam9pblVzZXJFdmVudHNNZXRhZGF0YRpJ
ykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybULAAQoaY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJCFVVz
ZXJFdmVudFNlcnZpY2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2
Mi9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5SZXRhaWwuVjLK
AhZHb29nbGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMkq9
NwoHEgUOANcBIwq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
HwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
ACMKCQoCAwUSAxcANAoJCgIDBhIDGAAzCgkKAgMHEgMZADEKCQoCAwgSAxoALQoICgEIEgMc
ADMKCQoCCCUSAxwAMwoICgEIEgMdAEkKCQoCCAsSAx0ASQoICgEIEgMeACIKCQoCCAoSAx4A
IgoICgEIEgMfADYKCQoCCAgSAx8ANgoICgEIEgMgADMKCQoCCAESAyAAMwoICgEIEgMhACQK
CQoCCCQSAyEAJAoICgEIEgMiADMKCQoCCCkSAyIAMwoICgEIEgMjADIKCQoCCC0SAyMAMgpN
CgIGABIEJgB6ARpBIFNlcnZpY2UgZm9yIGluZ2VzdGluZyBlbmQgdXNlciBhY3Rpb25zIG9u
IHRoZSBjdXN0b21lciB3ZWJzaXRlLgoKCgoDBgABEgMmCBgKCgoDBgADEgMnAj0KDAoFBgAD
mQgSAycCPQoLCgMGAAMSBCgCKTcKDQoFBgADmggSBCgCKTcKKwoEBgACABIELAIxAxodIFdy
aXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50LgoKDAoFBgACAAESAywGFAoMCgUGAAIAAhIDLBUq
CgwKBQYAAgADEgMsNT4KDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAGCsQCCgQG
AAIBEgQ6AkIDGrUCIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50IGZyb20gdGhlIGJyb3dz
ZXIuCgogRm9yIGxhcmdlciB1c2VyIGV2ZW50IHBheWxvYWQgb3ZlciAxNiBLQiwgdGhlIFBP
U1QgbWV0aG9kIHNob3VsZCBiZSB1c2VkCiBpbnN0ZWFkLCBvdGhlcndpc2UgYSA0MDAgQmFk
IFJlcXVlc3QgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBtZXRob2QgaXMgdXNlZCBvbmx5
IGJ5IHRoZSBSZXRhaWwgQVBJIEphdmFTY3JpcHQgcGl4ZWwgYW5kIEdvb2dsZSBUYWcKIE1h
bmFnZXIuIFVzZXJzIHNob3VsZCBub3QgY2FsbCB0aGlzIG1ldGhvZCBkaXJlY3RseS4KCgwK
BQYAAgEBEgM6BhYKDAoFBgACAQISAzoXLgoMCgUGAAIBAxIDOjlMCg0KBQYAAgEEEgQ7BEEG
ChEKCQYAAgEEsMq8IhIEOwRBBgr3AQoEBgACAhIESAJSAxroASBEZWxldGVzIHBlcm1hbmVu
dGx5IGFsbCB1c2VyIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciBwcm92aWRlZC4K
IERlcGVuZGluZyBvbiB0aGUgbnVtYmVyIG9mIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZp
bHRlciwgdGhpcyBvcGVyYXRpb24KIGNvdWxkIHRha2UgaG91cnMgb3IgZGF5cyB0byBjb21w
bGV0ZS4gVG8gdGVzdCBhIGZpbHRlciwgdXNlIHRoZSBsaXN0CiBjb21tYW5kIGZpcnN0LgoK
DAoFBgACAgESA0gGFQoMCgUGAAICAhIDSBYsCgwKBQYAAgIDEgNJDysKDQoFBgACAgQSBEoE
TQYKEQoJBgACAgSwyrwiEgRKBE0GCg0KBQYAAgIEEgROBFEGCg8KBwYAAgIEmQgSBE4EUQYK
7gIKBAYAAgMSBFsCZQMa3wIgQnVsayBpbXBvcnQgb2YgVXNlciBldmVudHMuIFJlcXVlc3Qg
cHJvY2Vzc2luZyBtaWdodCBiZQogc3luY2hyb25vdXMuIEV2ZW50cyB0aGF0IGFscmVhZHkg
ZXhpc3QgYXJlIHNraXBwZWQuCiBVc2UgdGhpcyBtZXRob2QgZm9yIGJhY2tmaWxsaW5nIGhp
c3RvcmljYWwgdXNlciBldmVudHMuCgogYE9wZXJhdGlvbi5yZXNwb25zZWAgaXMgb2YgdHlw
ZSBgSW1wb3J0UmVzcG9uc2VgLiBOb3RlIHRoYXQgaXQgaXMKIHBvc3NpYmxlIGZvciBhIHN1
YnNldCBvZiB0aGUgaXRlbXMgdG8gYmUgc3VjY2Vzc2Z1bGx5IGluc2VydGVkLgogYE9wZXJh
dGlvbi5tZXRhZGF0YWAgaXMgb2YgdHlwZSBgSW1wb3J0TWV0YWRhdGFgLgoKDAoFBgACAwES
A1sGFgoMCgUGAAIDAhIDWxcuCgwKBQYAAgMDEgNcDysKDQoFBgACAwQSBF0EYAYKEQoJBgAC
AwSwyrwiEgRdBGAGCg0KBQYAAgMEEgRhBGQGCg8KBwYAAgMEmQgSBGEEZAYKugQKBAYAAgQS
BG8CeQMaqwQgU3RhcnRzIGEgdXNlci1ldmVudCByZWpvaW4gb3BlcmF0aW9uIHdpdGggbGF0
ZXN0IHByb2R1Y3QgY2F0YWxvZy4gRXZlbnRzCiBhcmUgbm90IGFubm90YXRlZCB3aXRoIGRl
dGFpbGVkIHByb2R1Y3QgaW5mb3JtYXRpb24gZm9yIHByb2R1Y3RzIHRoYXQgYXJlCiBtaXNz
aW5nIGZyb20gdGhlIGNhdGFsb2cgd2hlbiB0aGUgdXNlciBldmVudCBpcyBpbmdlc3RlZC4g
VGhlc2UKIGV2ZW50cyBhcmUgc3RvcmVkIGFzIHVuam9pbmVkIGV2ZW50cyB3aXRoIGxpbWl0
ZWQgdXNhZ2Ugb24gdHJhaW5pbmcgYW5kCiBzZXJ2aW5nLiBZb3UgY2FuIHVzZSB0aGlzIG1l
dGhvZCB0byBzdGFydCBhIGpvaW4gb3BlcmF0aW9uIG9uIHNwZWNpZmllZAogZXZlbnRzIHdp
dGggdGhlIGxhdGVzdCB2ZXJzaW9uIG9mIHByb2R1Y3QgY2F0YWxvZy4gWW91IGNhbiBhbHNv
IHVzZSB0aGlzCiBtZXRob2QgdG8gY29ycmVjdCBldmVudHMgam9pbmVkIHdpdGggdGhlIHdy
b25nIHByb2R1Y3QgY2F0YWxvZy4gQSByZWpvaW4KIG9wZXJhdGlvbiBjYW4gdGFrZSBob3Vy
cyBvciBkYXlzIHRvIGNvbXBsZXRlLgoKDAoFBgACBAESA28GFgoMCgUGAAIEAhIDbxcuCgwK
BQYAAgQDEgNwDysKDQoFBgACBAQSBHEEdAYKEQoJBgACBASwyrwiEgRxBHQGCg0KBQYAAgQE
EgR1BHgGCg8KBwYAAgQEmQgSBHUEeAYKOQoCBAASBX0AigEBGiwgUmVxdWVzdCBtZXNzYWdl
IGZvciBXcml0ZVVzZXJFdmVudCBtZXRob2QuCgoKCgMEAAESA30IHQp/CgQEAAIAEgSAAQI9
GnEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgY2F0YWxvZyByZXNvdXJjZSBuYW1lLCBzdWNoIGFz
CiBgcHJvamVjdHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0
YWxvZ2AuCgoNCgUEAAIABRIEgAECCAoNCgUEAAIAARIEgAEJDwoNCgUEAAIAAxIEgAESEwoN
CgUEAAIACBIEgAEUPAoQCggEAAIACJwIABIEgAEVOwouCgQEAAIBEgSDAQJEGiAgUmVxdWly
ZWQuIFVzZXIgZXZlbnQgdG8gd3JpdGUuCgoNCgUEAAIBBhIEgwECCwoNCgUEAAIBARIEgwEM
FgoNCgUEAAIBAxIEgwEZGgoNCgUEAAIBCBIEgwEbQwoQCggEAAIBCJwIABIEgwEcQgquAgoE
BAACAhIEiQECFxqfAiBJZiBzZXQgdG8gdHJ1ZSwgdGhlIHVzZXIgZXZlbnQgd2lsbCBiZSB3
cml0dGVuIGFzeW5jaHJvbm91c2x5IGFmdGVyCiB2YWxpZGF0aW9uLCBhbmQgdGhlIEFQSSB3
aWxsIHJlc3BvbmQgd2l0aG91dCB3YWl0aW5nIGZvciB0aGUgd3JpdGUuCiBUaGVyZWZvcmUs
IHNpbGVudCBmYWlsdXJlcyBjYW4gb2NjdXIgZXZlbiBpZiB0aGUgQVBJIHJldHVybnMgc3Vj
Y2Vzcy4gSW4KIGNhc2Ugb2Ygc2lsZW50IGZhaWx1cmVzLCBlcnJvciBtZXNzYWdlcyBjYW4g
YmUgZm91bmQgaW4gU3RhY2tkcml2ZXIgbG9ncy4KCg0KBQQAAgIFEgSJAQIGCg0KBQQAAgIB
EgSJAQcSCg0KBQQAAgIDEgSJARUWCjwKAgQBEgaNAQCuAQEaLiBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIENvbGxlY3RVc2VyRXZlbnQgbWV0aG9kLgoKCwoDBAEBEgSNAQgfCnYKBAQBCAASBpAB
ApQBAxpmIFRoZSBydWxlIHRoYXQgY2FuIGNvbnZlcnQgdGhlIHJhd19qc29uIHRvIGEgdXNl
ciBldmVudC4gSXQgaXMgbmVlZGVkCiBvbmx5IHdoZW4gdGhlIHJhd19qc29uIGlzIHNldC4K
Cg0KBQQBCAABEgSQAQgXCpABCgQEAQIAEgSTAQQdGoEBIFRoZSBwcmVidWlsdCBydWxlIG5h
bWUgdGhhdCBjYW4gY29udmVydCBhIHNwZWNpZmljIHR5cGUgb2YgcmF3X2pzb24uCiBGb3Ig
ZXhhbXBsZTogImdhNF9icSIgcnVsZSBmb3IgdGhlIEdBNCB1c2VyIGV2ZW50IHNjaGVtYS4K
Cg0KBQQBAgAFEgSTAQQKCg0KBQQBAgABEgSTAQsYCg0KBQQBAgADEgSTARscCnYKBAQBAgES
BJgBAj0aaCBSZXF1aXJlZC4gVGhlIHBhcmVudCBjYXRhbG9nIG5hbWUsIHN1Y2ggYXMKIGBw
cm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9n
YC4KCg0KBQQBAgEFEgSYAQIICg0KBQQBAgEBEgSYAQkPCg0KBQQBAgEDEgSYARITCg0KBQQB
AgEIEgSYARQ8ChAKCAQBAgEInAgAEgSYARU7CmMKBAQBAgISBJwBAkEaVSBSZXF1aXJlZC4g
VVJMIGVuY29kZWQgVXNlckV2ZW50IHByb3RvIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMiww
MDAsMDAwCiBjaGFyYWN0ZXJzLgoKDQoFBAECAgUSBJwBAggKDQoFBAECAgESBJwBCRMKDQoF
BAECAgMSBJwBFhcKDQoFBAECAggSBJwBGEAKEAoIBAECAgicCAASBJwBGT8K8AEKBAQBAgMS
BKIBAhEa4QEgVGhlIFVSTCBpbmNsdWRpbmcgY2dpLXBhcmFtZXRlcnMgYnV0IGV4Y2x1ZGlu
ZyB0aGUgaGFzaCBmcmFnbWVudCB3aXRoIGEKIGxlbmd0aCBsaW1pdCBvZiA1LDAwMCBjaGFy
YWN0ZXJzLiBUaGlzIGlzIG9mdGVuIG1vcmUgdXNlZnVsIHRoYW4gdGhlCiByZWZlcmVyIFVS
TCwgYmVjYXVzZSBtYW55IGJyb3dzZXJzIG9ubHkgc2VuZCB0aGUgZG9tYWluIGZvciAzcmQg
cGFydHkKIHJlcXVlc3RzLgoKDQoFBAECAwUSBKIBAggKDQoFBAECAwESBKIBCQwKDQoFBAEC
AwMSBKIBDxAKrwEKBAQBAgQSBKcBAhAaoAEgVGhlIGV2ZW50IHRpbWVzdGFtcCBpbiBtaWxs
aXNlY29uZHMuIFRoaXMgcHJldmVudHMgYnJvd3NlciBjYWNoaW5nIG9mCiBvdGhlcndpc2Ug
aWRlbnRpY2FsIGdldCByZXF1ZXN0cy4gVGhlIG5hbWUgaXMgYWJicmV2aWF0ZWQgdG8gcmVk
dWNlIHRoZQogcGF5bG9hZCBieXRlcy4KCg0KBQQBAgQFEgSnAQIHCg0KBQQBAgQBEgSnAQgL
Cg0KBQQBAgQDEgSnAQ4PCv8BCgQEAQIFEgStAQIWGvABIEFuIGFyYml0cmFyeSBzZXJpYWxp
emVkIEpTT04gc3RyaW5nIHRoYXQgY29udGFpbnMgbmVjZXNzYXJ5IGluZm9ybWF0aW9uCiB0
aGF0IGNhbiBjb21wcmlzZSBhIHVzZXIgZXZlbnQuIFdoZW4gdGhpcyBmaWVsZCBpcyBzcGVj
aWZpZWQsIHRoZQogdXNlcl9ldmVudCBmaWVsZCB3aWxsIGJlIGlnbm9yZWQuIE5vdGU6IGxp
bmUtZGVsaW1pdGVkIEpTT04gaXMgbm90CiBzdXBwb3J0ZWQsIGEgc2luZ2xlIEpTT04gb25s
eS4KCg0KBQQBAgUFEgStAQIICg0KBQQBAgUBEgStAQkRCg0KBQQBAgUDEgStARQVCjwKAgQC
EgaxAQDOAQEaLiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFJlam9pblVzZXJFdmVudHMgbWV0aG9k
LgoKCwoDBAIBEgSxAQgfCrkDCgQEAgQAEga5AQLDAQMaqAMgVGhlIHNjb3BlIG9mIHVzZXIg
ZXZlbnRzIHRvIGJlIHJlam9pbmVkIHdpdGggdGhlIGxhdGVzdCBwcm9kdWN0IGNhdGFsb2cu
CiBJZiB0aGUgcmVqb2luaW5nIGFpbXMgYXQgcmVkdWNpbmcgbnVtYmVyIG9mIHVuam9pbmVk
IGV2ZW50cywgc2V0CiBgVXNlckV2ZW50UmVqb2luU2NvcGVgIHRvIGBVTkpPSU5FRF9FVkVO
VFNgLgogSWYgdGhlIHJlam9pbmluZyBhaW1zIGF0IGNvcnJlY3RpbmcgcHJvZHVjdCBjYXRh
bG9nIGluZm9ybWF0aW9uIGluIGpvaW5lZAogZXZlbnRzLCBzZXQgYFVzZXJFdmVudFJlam9p
blNjb3BlYCB0byBgSk9JTkVEX0VWRU5UU2AuCiBJZiBhbGwgZXZlbnRzIG5lZWRzIHRvIGJl
IHJlam9pbmVkLCBzZXQgYFVzZXJFdmVudFJlam9pblNjb3BlYCB0bwogYFVTRVJfRVZFTlRf
UkVKT0lOX1NDT1BFX1VOU1BFQ0lGSUVEYC4KCg0KBQQCBAABEgS5AQcbCncKBgQCBAACABIE
vAEELBpnIFJlam9pbiBhbGwgZXZlbnRzIHdpdGggdGhlIGxhdGVzdCBwcm9kdWN0IGNhdGFs
b2csIGluY2x1ZGluZyBib3RoIGpvaW5lZAogZXZlbnRzIGFuZCB1bmpvaW5lZCBldmVudHMu
CgoPCgcEAgQAAgABEgS8AQQnCg8KBwQCBAACAAISBLwBKisKTAoGBAIEAAIBEgS/AQQWGjwg
T25seSByZWpvaW4gam9pbmVkIGV2ZW50cyB3aXRoIHRoZSBsYXRlc3QgcHJvZHVjdCBjYXRh
bG9nLgoKDwoHBAIEAAIBARIEvwEEEQoPCgcEAgQAAgECEgS/ARQVCk4KBgQCBAACAhIEwgEE
GBo+IE9ubHkgcmVqb2luIHVuam9pbmVkIGV2ZW50cyB3aXRoIHRoZSBsYXRlc3QgcHJvZHVj
dCBjYXRhbG9nLgoKDwoHBAIEAAICARIEwgEEEwoPCgcEAgQAAgICEgTCARYXCn8KBAQCAgAS
BMcBAj0acSBSZXF1aXJlZC4gVGhlIHBhcmVudCBjYXRhbG9nIHJlc291cmNlIG5hbWUsIHN1
Y2ggYXMKIGBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVs
dF9jYXRhbG9nYC4KCg0KBQQCAgAFEgTHAQIICg0KBQQCAgABEgTHAQkPCg0KBQQCAgADEgTH
ARITCg0KBQQCAgAIEgTHARQ8ChAKCAQCAgAInAgAEgTHARU7CoYCCgQEAgIBEgTNAQIzGvcB
IFRoZSB0eXBlIG9mIHRoZSB1c2VyIGV2ZW50IHJlam9pbiB0byBkZWZpbmUgdGhlIHNjb3Bl
IGFuZCByYW5nZSBvZiB0aGUgdXNlcgogZXZlbnRzIHRvIGJlIHJlam9pbmVkIHdpdGggdGhl
IGxhdGVzdCBwcm9kdWN0IGNhdGFsb2cuIERlZmF1bHRzIHRvCiBgVVNFUl9FVkVOVF9SRUpP
SU5fU0NPUEVfVU5TUEVDSUZJRURgIGlmIHRoaXMgZmllbGQgaXMgbm90IHNldCwgb3Igc2V0
IHRvCiBhbiBpbnZhbGlkIGludGVnZXIgdmFsdWUuCgoNCgUEAgIBBhIEzQECFgoNCgUEAgIB
ARIEzQEXLgoNCgUEAgIBAxIEzQExMgo/CgIEAxIG0QEA1AEBGjEgUmVzcG9uc2UgbWVzc2Fn
ZSBmb3IgYFJlam9pblVzZXJFdmVudHNgIG1ldGhvZC4KCgsKAwQDARIE0QEIIApTCgQEAwIA
EgTTAQInGkUgTnVtYmVyIG9mIHVzZXIgZXZlbnRzIHRoYXQgd2VyZSBqb2luZWQgd2l0aCBs
YXRlc3QgcHJvZHVjdCBjYXRhbG9nLgoKDQoFBAMCAAUSBNMBAgcKDQoFBAMCAAESBNMBCCIK
DQoFBAMCAAMSBNMBJSYKNQoCBAQSBNcBACMaKSBNZXRhZGF0YSBmb3IgYFJlam9pblVzZXJF
dmVudHNgIG1ldGhvZC4KCgsKAwQEARIE1wEIIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Retail::V2::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: prebuilt_rule Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()
    # Field: raw_json Type: 9 ()

# === Message: Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsRequest ===
    # Fields for RejoinUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: user_event_rejoin_scope Type: 14 (.google.cloud.retail.v2.RejoinUserEventsRequest.UserEventRejoinScope)

# Enum: RejoinUserEventsRequest::UserEventRejoinScope
our $RejoinUserEventsRequest_USER_EVENT_REJOIN_SCOPE_UNSPECIFIED = 0;
our $RejoinUserEventsRequest_JOINED_EVENTS = 1;
our $RejoinUserEventsRequest_UNJOINED_EVENTS = 2;

# === Message: Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsResponse ===
    # Fields for RejoinUserEventsResponse
    # Field: rejoined_user_events_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsMetadata ===
    # Fields for RejoinUserEventsMetadata

# === Service Client: Google::Cloud::Retail::V2::UserEventService::UserEventServiceClient ===
package Google::Cloud::Retail::V2::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::UserEventService::UserEventServiceClient

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
        ? Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rejoin_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'RejoinUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::UserEventService - Compiled Protocol Buffers messages for google/cloud/retail/v2/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::UserEventService;

    my $msg = Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event will be written asynchronously after
validation, and the API will respond without waiting for the write.
Therefore, silent failures can occur even if the API returns success. In
case of silent failures, error messages can be found in Stackdriver logs.

=back

=head2 Google::Cloud::Retail::V2::UserEventService::CollectUserEventRequest

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

=head2 Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsRequest

Request message for RejoinUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event_rejoin_scope() >> / C<< $msg->user_event_rejoin_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::RejoinUserEventsRequest::UserEventRejoinScope>)

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

=head2 Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsResponse

Response message for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rejoined_user_events_count() >> / C<< $msg->rejoined_user_events_count($value) >>

Type: C<Int64>

Number of user events that were joined with latest product catalog.

=back

=head2 Google::Cloud::Retail::V2::UserEventService::RejoinUserEventsMetadata

Metadata for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
