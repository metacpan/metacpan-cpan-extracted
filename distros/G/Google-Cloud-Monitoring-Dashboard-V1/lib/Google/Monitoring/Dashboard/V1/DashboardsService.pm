package Google::Monitoring::Dashboard::V1::DashboardsService;

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
    eval { require Google::Monitoring::Dashboard::V1::Dashboard };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvZGFzaGJvYXJkc19zZXJ2aWNlLnBy
b3RvEh5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvbW9u
aXRvcmluZy9kYXNoYm9hcmQvdjEvZGFzaGJvYXJkLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8i2AEKFkNyZWF0ZURhc2hib2FyZFJlcXVlc3QSSwoGcGFyZW50GAEgASgJ
QjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RS
BnBhcmVudBJMCglkYXNoYm9hcmQYAiABKAsyKS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9h
cmQudjEuRGFzaGJvYXJkQgPgQQJSCWRhc2hib2FyZBIjCg12YWxpZGF0ZV9vbmx5GAMgASgI
Ugx2YWxpZGF0ZU9ubHkipQEKFUxpc3REYXNoYm9hcmRzUmVxdWVzdBJLCgZwYXJlbnQYASAB
KAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVj
dFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4iiwEKFkxpc3REYXNoYm9hcmRzUmVzcG9uc2USSQoKZGFz
aGJvYXJkcxgBIAMoCzIpLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5EYXNoYm9h
cmRSCmRhc2hib2FyZHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
IlYKE0dldERhc2hib2FyZFJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNtb25pdG9y
aW5nLmdvb2dsZWFwaXMuY29tL0Rhc2hib2FyZFIEbmFtZSJZChZEZWxldGVEYXNoYm9hcmRS
ZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpBJQojbW9uaXRvcmluZy5nb29nbGVhcGlzLmNv
bS9EYXNoYm9hcmRSBG5hbWUiiwEKFlVwZGF0ZURhc2hib2FyZFJlcXVlc3QSTAoJZGFzaGJv
YXJkGAEgASgLMikuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkRhc2hib2FyZEID
4EECUglkYXNoYm9hcmQSIwoNdmFsaWRhdGVfb25seRgDIAEoCFIMdmFsaWRhdGVPbmx5MtsI
ChFEYXNoYm9hcmRzU2VydmljZRK+AQoPQ3JlYXRlRGFzaGJvYXJkEjYuZ29vZ2xlLm1vbml0
b3JpbmcuZGFzaGJvYXJkLnYxLkNyZWF0ZURhc2hib2FyZFJlcXVlc3QaKS5nb29nbGUubW9u
aXRvcmluZy5kYXNoYm9hcmQudjEuRGFzaGJvYXJkIkiC0+STAi8iIi92MS97cGFyZW50PXBy
b2plY3RzLyp9L2Rhc2hib2FyZHM6CWRhc2hib2FyZNpBEHBhcmVudCxkYXNoYm9hcmQStAEK
Dkxpc3REYXNoYm9hcmRzEjUuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkxpc3RE
YXNoYm9hcmRzUmVxdWVzdBo2Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5MaXN0
RGFzaGJvYXJkc1Jlc3BvbnNlIjOC0+STAiQSIi92MS97cGFyZW50PXByb2plY3RzLyp9L2Rh
c2hib2FyZHPaQQZwYXJlbnQSoQEKDEdldERhc2hib2FyZBIzLmdvb2dsZS5tb25pdG9yaW5n
LmRhc2hib2FyZC52MS5HZXREYXNoYm9hcmRSZXF1ZXN0GikuZ29vZ2xlLm1vbml0b3Jpbmcu
ZGFzaGJvYXJkLnYxLkRhc2hib2FyZCIxgtPkkwIkEiIvdjEve25hbWU9cHJvamVjdHMvKi9k
YXNoYm9hcmRzLyp92kEEbmFtZRKUAQoPRGVsZXRlRGFzaGJvYXJkEjYuZ29vZ2xlLm1vbml0
b3JpbmcuZGFzaGJvYXJkLnYxLkRlbGV0ZURhc2hib2FyZFJlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkiMYLT5JMCJCoiL3YxL3tuYW1lPXByb2plY3RzLyovZGFzaGJvYXJkcy8q
fdpBBG5hbWUStQEKD1VwZGF0ZURhc2hib2FyZBI2Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hi
b2FyZC52MS5VcGRhdGVEYXNoYm9hcmRSZXF1ZXN0GikuZ29vZ2xlLm1vbml0b3JpbmcuZGFz
aGJvYXJkLnYxLkRhc2hib2FyZCI/gtPkkwI5MiwvdjEve2Rhc2hib2FyZC5uYW1lPXByb2pl
Y3RzLyovZGFzaGJvYXJkcy8qfToJZGFzaGJvYXJkGtoBykEZbW9uaXRvcmluZy5nb29nbGVh
cGlzLmNvbdJBugFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRvcmluZyxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3JpbmcucmVhZCxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3Jpbmcud3JpdGVC/wEKImNvbS5nb29nbGUubW9u
aXRvcmluZy5kYXNoYm9hcmQudjFCFkRhc2hib2FyZHNTZXJ2aWNlUHJvdG9QAVpGY2xvdWQu
Z29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9hcmRwYjtk
YXNoYm9hcmRwYqoCJEdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5WMcoCJEdv
b2dsZVxDbG91ZFxNb25pdG9yaW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xvdWQ6Ok1v
bml0b3Jpbmc6OkRhc2hib2FyZDo6VjFKyS0KBxIFDgDGAQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA4CgkKAgMFEgMXACUKCAoBCBIDGQBBCgkKAggl
EgMZAEEKCAoBCBIDGgBdCgkKAggLEgMaAF0KCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBID
HAA3CgkKAggIEgMcADcKCAoBCBIDHQA7CgkKAggBEgMdADsKCAoBCBIDHgBCCgkKAggpEgMe
AEIKCAoBCBIDHwBBCgkKAggtEgMfAEEKegoCBgASBCMAaAEabiBNYW5hZ2VzIFN0YWNrZHJp
dmVyIGRhc2hib2FyZHMuIEEgZGFzaGJvYXJkIGlzIGFuIGFycmFuZ2VtZW50IG9mIGRhdGEg
ZGlzcGxheQogd2lkZ2V0cyBpbiBhIHNwZWNpZmljIGxheW91dC4KCgoKAwYAARIDIwgZCgoK
AwYAAxIDJAJBCgwKBQYAA5kIEgMkAkEKCwoDBgADEgQlAik5Cg0KBQYAA5oIEgQlAik5CqMD
CgQGAAIAEgQxAjcDGpQDIENyZWF0ZXMgYSBuZXcgY3VzdG9tIGRhc2hib2FyZC4gRm9yIGV4
YW1wbGVzIG9uIGhvdyB5b3UgY2FuIHVzZSB0aGlzIEFQSSB0bwogY3JlYXRlIGRhc2hib2Fy
ZHMsIHNlZSBbTWFuYWdpbmcgZGFzaGJvYXJkcyBieQogQVBJXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vbW9uaXRvcmluZy9kYXNoYm9hcmRzL2FwaS1kYXNoYm9hcmQpLiBUaGlzCiBt
ZXRob2QgcmVxdWlyZXMgdGhlIGBtb25pdG9yaW5nLmRhc2hib2FyZHMuY3JlYXRlYCBwZXJt
aXNzaW9uIG9uIHRoZQogc3BlY2lmaWVkIHByb2plY3QuIEZvciBtb3JlIGluZm9ybWF0aW9u
IGFib3V0IHBlcm1pc3Npb25zLCBzZWUgW0Nsb3VkCiBJZGVudGl0eSBhbmQgQWNjZXNzIE1h
bmFnZW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0pLgoKDAoFBgACAAESAzEG
FQoMCgUGAAIAAhIDMRYsCgwKBQYAAgADEgMxN0AKDQoFBgACAAQSBDIENQYKEQoJBgACAASw
yrwiEgQyBDUGCgwKBQYAAgAEEgM2BD4KDwoIBgACAASbCAASAzYEPgruAQoEBgACARIEPgJD
AxrfASBMaXN0cyB0aGUgZXhpc3RpbmcgZGFzaGJvYXJkcy4KCiBUaGlzIG1ldGhvZCByZXF1
aXJlcyB0aGUgYG1vbml0b3JpbmcuZGFzaGJvYXJkcy5saXN0YCBwZXJtaXNzaW9uCiBvbiB0
aGUgc3BlY2lmaWVkIHByb2plY3QuIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtDbG91
ZCBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9pYW0pLgoKDAoFBgACAQESAz4GFAoMCgUGAAIBAhIDPhUqCgwKBQYAAgEDEgM+NUsK
DQoFBgACAQQSBD8EQQYKEQoJBgACAQSwyrwiEgQ/BEEGCgwKBQYAAgEEEgNCBDQKDwoIBgAC
AQSbCAASA0IENAruAQoEBgACAhIESgJPAxrfASBGZXRjaGVzIGEgc3BlY2lmaWMgZGFzaGJv
YXJkLgoKIFRoaXMgbWV0aG9kIHJlcXVpcmVzIHRoZSBgbW9uaXRvcmluZy5kYXNoYm9hcmRz
LmdldGAgcGVybWlzc2lvbgogb24gdGhlIHNwZWNpZmllZCBkYXNoYm9hcmQuIEZvciBtb3Jl
IGluZm9ybWF0aW9uLCBzZWUKIFtDbG91ZCBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1l
bnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0pLgoKDAoFBgACAgESA0oGEgoMCgUG
AAICAhIDShMmCgwKBQYAAgIDEgNKMToKDQoFBgACAgQSBEsETQYKEQoJBgACAgSwyrwiEgRL
BE0GCgwKBQYAAgIEEgNOBDIKDwoIBgACAgSbCAASA04EMgr5AQoEBgACAxIEVgJbAxrqASBE
ZWxldGVzIGFuIGV4aXN0aW5nIGN1c3RvbSBkYXNoYm9hcmQuCgogVGhpcyBtZXRob2QgcmVx
dWlyZXMgdGhlIGBtb25pdG9yaW5nLmRhc2hib2FyZHMuZGVsZXRlYCBwZXJtaXNzaW9uCiBv
biB0aGUgc3BlY2lmaWVkIGRhc2hib2FyZC4gRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQog
W0Nsb3VkIElkZW50aXR5IGFuZCBBY2Nlc3MgTWFuYWdlbWVudF0oaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2lhbSkuCgoMCgUGAAIDARIDVgYVCgwKBQYAAgMCEgNWFiwKDAoFBgACAwMS
A1Y3TAoNCgUGAAIDBBIEVwRZBgoRCgkGAAIDBLDKvCISBFcEWQYKDAoFBgACAwQSA1oEMgoP
CggGAAIDBJsIABIDWgQyCpACCgQGAAIEEgRiAmcDGoECIFJlcGxhY2VzIGFuIGV4aXN0aW5n
IGN1c3RvbSBkYXNoYm9hcmQgd2l0aCBhIG5ldyBkZWZpbml0aW9uLgoKIFRoaXMgbWV0aG9k
IHJlcXVpcmVzIHRoZSBgbW9uaXRvcmluZy5kYXNoYm9hcmRzLnVwZGF0ZWAgcGVybWlzc2lv
bgogb24gdGhlIHNwZWNpZmllZCBkYXNoYm9hcmQuIEZvciBtb3JlIGluZm9ybWF0aW9uLCBz
ZWUKIFtDbG91ZCBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1lbnRdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9pYW0pLgoKDAoFBgACBAESA2IGFQoMCgUGAAIEAhIDYhYsCgwKBQYA
AgQDEgNiN0AKDQoFBgACBAQSBGMEZgYKEQoJBgACBASwyrwiEgRjBGYGCiwKAgQAEgRrAH4B
GiAgVGhlIGBDcmVhdGVEYXNoYm9hcmRgIHJlcXVlc3QuCgoKCgMEAAESA2sIHgrDAQoEBAAC
ABIEcQJ2BBq0ASBSZXF1aXJlZC4gVGhlIHByb2plY3Qgb24gd2hpY2ggdG8gZXhlY3V0ZSB0
aGUgcmVxdWVzdC4gVGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURf
T1JfTlVNQkVSXQoKIFRoZSBgW1BST0pFQ1RfSURfT1JfTlVNQkVSXWAgbXVzdCBtYXRjaCB0
aGUgZGFzaGJvYXJkIHJlc291cmNlIG5hbWUuCgoMCgUEAAIABRIDcQIICgwKBQQAAgABEgNx
CQ8KDAoFBAACAAMSA3ESEwoNCgUEAAIACBIEcRR2AwoPCggEAAIACJwIABIDcgQqCg8KBwQA
AgAInwgSBHMEdQUKPQoEBAACARIDeQJDGjAgUmVxdWlyZWQuIFRoZSBpbml0aWFsIGRhc2hi
b2FyZCBzcGVjaWZpY2F0aW9uLgoKDAoFBAACAQYSA3kCCwoMCgUEAAIBARIDeQwVCgwKBQQA
AgEDEgN5GBkKDAoFBAACAQgSA3kaQgoPCggEAAIBCJwIABIDeRtBCmEKBAQAAgISA30CGRpU
IElmIHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIHJldmlldywg
YnV0IGRvIG5vdCBhY3R1YWxseQogc2F2ZSBpdC4KCgwKBQQAAgIFEgN9AgYKDAoFBAACAgES
A30HFAoMCgUEAAICAxIDfRcYCi0KAgQBEgaBAQCVAQEaHyBUaGUgYExpc3REYXNoYm9hcmRz
YCByZXF1ZXN0LgoKCwoDBAEBEgSBAQgdCnUKBAQBAgASBoUBAooBBBplIFJlcXVpcmVkLiBU
aGUgc2NvcGUgb2YgdGhlIGRhc2hib2FyZHMgdG8gbGlzdC4gVGhlIGZvcm1hdCBpczoKCiAg
ICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXQoKDQoFBAECAAUSBIUBAggKDQoF
BAECAAESBIUBCQ8KDQoFBAECAAMSBIUBEhMKDwoFBAECAAgSBoUBFIoBAwoQCggEAQIACJwI
ABIEhgEEKgoRCgcEAQIACJ8IEgaHAQSJAQUKfgoEBAECARIEjgECFhpwIEEgcG9zaXRpdmUg
bnVtYmVyIHRoYXQgaXMgdGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJu
LgogSWYgdW5zcGVjaWZpZWQsIGEgZGVmYXVsdCBvZiAxMDAwIGlzIHVzZWQuCgoNCgUEAQIB
BRIEjgECBwoNCgUEAQIBARIEjgEIEQoNCgUEAQIBAxIEjgEUFQrzAQoEBAECAhIElAECQRrk
ASBPcHRpb25hbC4gSWYgdGhpcyBmaWVsZCBpcyBub3QgZW1wdHkgdGhlbiBpdCBtdXN0IGNv
bnRhaW4gdGhlCiBgbmV4dFBhZ2VUb2tlbmAgdmFsdWUgcmV0dXJuZWQgYnkgYSBwcmV2aW91
cyBjYWxsIHRvIHRoaXMgbWV0aG9kLiAgVXNpbmcKIHRoaXMgZmllbGQgY2F1c2VzIHRoZSBt
ZXRob2QgdG8gcmV0dXJuIGFkZGl0aW9uYWwgcmVzdWx0cyBmcm9tIHRoZSBwcmV2aW91cwog
bWV0aG9kIGNhbGwuCgoNCgUEAQICBRIElAECCAoNCgUEAQICARIElAEJEwoNCgUEAQICAxIE
lAEWFwoNCgUEAQICCBIElAEYQAoQCggEAQICCJwIABIElAEZPwotCgIEAhIGmAEAoAEBGh8g
VGhlIGBMaXN0RGFzaGJvYXJkc2AgcmVxdWVzdC4KCgsKAwQCARIEmAEIHgoxCgQEAgIAEgSa
AQIkGiMgVGhlIGxpc3Qgb2YgcmVxdWVzdGVkIGRhc2hib2FyZHMuCgoNCgUEAgIABBIEmgEC
CgoNCgUEAgIABhIEmgELFAoNCgUEAgIAARIEmgEVHwoNCgUEAgIAAxIEmgEiIwrSAQoEBAIC
ARIEnwECHRrDASBJZiB0aGVyZSBhcmUgbW9yZSByZXN1bHRzIHRoYW4gaGF2ZSBiZWVuIHJl
dHVybmVkLCB0aGVuIHRoaXMgZmllbGQgaXMgc2V0CiB0byBhIG5vbi1lbXB0eSB2YWx1ZS4g
IFRvIHNlZSB0aGUgYWRkaXRpb25hbCByZXN1bHRzLAogdXNlIHRoYXQgdmFsdWUgYXMgYHBh
Z2VfdG9rZW5gIGluIHRoZSBuZXh0IGNhbGwgdG8gdGhpcyBtZXRob2QuCgoNCgUEAgIBBRIE
nwECCAoNCgUEAgIBARIEnwEJGAoNCgUEAgIBAxIEnwEbHAorCgIEAxIGowEArwEBGh0gVGhl
IGBHZXREYXNoYm9hcmRgIHJlcXVlc3QuCgoLCgMEAwESBKMBCBsK8QEKBAQDAgASBqkBAq4B
BBrgASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIERhc2hib2FyZC4gVGhl
IGZvcm1hdCBpcyBvbmUgb2Y6CgogIC0gIGBkYXNoYm9hcmRzL1tEQVNIQk9BUkRfSURdYCAo
Zm9yIHN5c3RlbSBkYXNoYm9hcmRzKQogIC0gIGBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9O
VU1CRVJdL2Rhc2hib2FyZHMvW0RBU0hCT0FSRF9JRF1gCiAgICAgICAoZm9yIGN1c3RvbSBk
YXNoYm9hcmRzKS4KCg0KBQQDAgAFEgSpAQIICg0KBQQDAgABEgSpAQkNCg0KBQQDAgADEgSp
ARARCg8KBQQDAgAIEgapARKuAQMKEAoIBAMCAAicCAASBKoBBCoKEQoHBAMCAAifCBIGqwEE
rQEFCi4KAgQEEgayAQC8AQEaICBUaGUgYERlbGV0ZURhc2hib2FyZGAgcmVxdWVzdC4KCgsK
AwQEARIEsgEIHgqOAQoEBAQCABIGtgECuwEEGn4gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBEYXNoYm9hcmQuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQ
Uk9KRUNUX0lEX09SX05VTUJFUl0vZGFzaGJvYXJkcy9bREFTSEJPQVJEX0lEXQoKDQoFBAQC
AAUSBLYBAggKDQoFBAQCAAESBLYBCQ0KDQoFBAQCAAMSBLYBEBEKDwoFBAQCAAgSBrYBErsB
AwoQCggEBAIACJwIABIEtwEEKgoRCgcEBAIACJ8IEga4AQS6AQUKLgoCBAUSBr8BAMYBARog
IFRoZSBgVXBkYXRlRGFzaGJvYXJkYCByZXF1ZXN0LgoKCwoDBAUBEgS/AQgeClEKBAQFAgAS
BMEBAkMaQyBSZXF1aXJlZC4gVGhlIGRhc2hib2FyZCB0aGF0IHdpbGwgcmVwbGFjZSB0aGUg
ZXhpc3RpbmcgZGFzaGJvYXJkLgoKDQoFBAUCAAYSBMEBAgsKDQoFBAUCAAESBMEBDBUKDQoF
BAUCAAMSBMEBGBkKDQoFBAUCAAgSBMEBGkIKEAoIBAUCAAicCAASBMEBG0EKYgoEBAUCARIE
xQECGRpUIElmIHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIHJl
dmlldywgYnV0IGRvIG5vdCBhY3R1YWxseQogc2F2ZSBpdC4KCg0KBQQFAgEFEgTFAQIGCg0K
BQQFAgEBEgTFAQcUCg0KBQQFAgEDEgTFARcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest ===
    # Fields for CreateDashboardRequest
    # Field: parent Type: 9 ()
    # Field: dashboard Type: 11 (.google.monitoring.dashboard.v1.Dashboard)
    # Field: validate_only Type: 8 ()

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest ===
    # Fields for ListDashboardsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse ===
    # Fields for ListDashboardsResponse
    # Field: dashboards Type: 11 (.google.monitoring.dashboard.v1.Dashboard)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest ===
    # Fields for GetDashboardRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest ===
    # Fields for DeleteDashboardRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest ===
    # Fields for UpdateDashboardRequest
    # Field: dashboard Type: 11 (.google.monitoring.dashboard.v1.Dashboard)
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Monitoring::Dashboard::V1::DashboardsService::DashboardsServiceClient ===
package Google::Monitoring::Dashboard::V1::DashboardsService::DashboardsServiceClient;

=pod

=head2 Service Client: Google::Monitoring::Dashboard::V1::DashboardsService::DashboardsServiceClient

Client stub representing the remote C<DashboardsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub create_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.dashboard.v1.DashboardsService',
        method         => 'CreateDashboard',
        request        => $req,
        response_class => 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard',
    });
}

sub list_dashboards {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.dashboard.v1.DashboardsService',
        method         => 'ListDashboards',
        request        => $req,
        response_class => 'Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse',
    });
}

sub get_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.dashboard.v1.DashboardsService',
        method         => 'GetDashboard',
        request        => $req,
        response_class => 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard',
    });
}

sub delete_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.dashboard.v1.DashboardsService',
        method         => 'DeleteDashboard',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.dashboard.v1.DashboardsService',
        method         => 'UpdateDashboard',
        request        => $req,
        response_class => 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::DashboardsService - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/dashboards_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::DashboardsService;

    my $msg = Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest->new({
        parent => $parent,
        dashboard => $dashboard,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/dashboards_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest

The `CreateDashboard` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project on which to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

The `[PROJECT_ID_OR_NUMBER]` must match the dashboard resource name.

=item * C<< $msg->dashboard() >> / C<< $msg->dashboard($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Dashboard::Dashboard>)

Required. The initial dashboard specification.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If set, validate the request and preview the review, but do not actually
save it.

=back

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest

The `ListDashboards` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The scope of the dashboards to list. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A positive number that is the maximum number of results to return.
If unspecified, a default of 1000 is used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If this field is not empty then it must contain the
`nextPageToken` value returned by a previous call to this method.  Using
this field causes the method to return additional results from the previous
method call.

=back

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse

The `ListDashboards` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dashboards() >> / C<< $msg->dashboards($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Dashboard::Dashboard>)

The list of requested dashboards.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than have been returned, then this field is set
to a non-empty value.  To see the additional results,
use that value as `page_token` in the next call to this method.

=back

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest

The `GetDashboard` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Dashboard. The format is one of:

 -  `dashboards/[DASHBOARD_ID]` (for system dashboards)
 -  `projects/[PROJECT_ID_OR_NUMBER]/dashboards/[DASHBOARD_ID]`
      (for custom dashboards).

=back

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest

The `DeleteDashboard` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Dashboard. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/dashboards/[DASHBOARD_ID]

=back

=head2 Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest

The `UpdateDashboard` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dashboard() >> / C<< $msg->dashboard($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Dashboard::Dashboard>)

Required. The dashboard that will replace the existing dashboard.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If set, validate the request and preview the review, but do not actually
save it.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::DashboardsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
