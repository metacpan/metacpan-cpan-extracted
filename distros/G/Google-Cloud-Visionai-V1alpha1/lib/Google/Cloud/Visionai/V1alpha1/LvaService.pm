package Google::Cloud::Visionai::V1alpha1::LvaService;

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
    eval { require Google::Cloud::Visionai::V1alpha1::LvaResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvbHZhX3NlcnZpY2UucHJvdG8SHmdv
b2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2dsZS9jbG91ZC92aXNp
b25haS92MWFscGhhMS9sdmFfcmVzb3VyY2VzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8ixQEK
E0xpc3RBbmFseXNlc1JlcXVlc3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSEKH3Zpc2lvbmFp
Lmdvb2dsZWFwaXMuY29tL0NsdXN0ZXJSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlS
BmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSKmAQoUTGlzdEFuYWx5c2VzUmVz
cG9uc2USRAoIYW5hbHlzZXMYASADKAsyKC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBo
YTEuQW5hbHlzaXNSCGFuYWx5c2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiUgoSR2V0QW5hbHlz
aXNSZXF1ZXN0EjwKBG5hbWUYASABKAlCKOBBAvpBIgogdmlzaW9uYWkuZ29vZ2xlYXBpcy5j
b20vQW5hbHlzaXNSBG5hbWUi7QEKFUNyZWF0ZUFuYWx5c2lzUmVxdWVzdBI/CgZwYXJlbnQY
ASABKAlCJ+BBAvpBIQofdmlzaW9uYWkuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIGcGFyZW50
EiQKC2FuYWx5c2lzX2lkGAIgASgJQgPgQQJSCmFuYWx5c2lzSWQSSQoIYW5hbHlzaXMYAyAB
KAsyKC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHlzaXNCA+BBAlIIYW5h
bHlzaXMSIgoKcmVxdWVzdF9pZBgEIAEoCUID4EEBUglyZXF1ZXN0SWQiyAEKFVVwZGF0ZUFu
YWx5c2lzUmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzaxJJCghhbmFseXNpcxgCIAEoCzIoLmdvb2dsZS5j
bG91ZC52aXNpb25haS52MWFscGhhMS5BbmFseXNpc0ID4EECUghhbmFseXNpcxIiCgpyZXF1
ZXN0X2lkGAMgASgJQgPgQQFSCXJlcXVlc3RJZCJ5ChVEZWxldGVBbmFseXNpc1JlcXVlc3QS
PAoEbmFtZRgBIAEoCUIo4EEC+kEiCiB2aXNpb25haS5nb29nbGVhcGlzLmNvbS9BbmFseXNp
c1IEbmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZDLBCQoSTGl2ZVZp
ZGVvQW5hbHl0aWNzEskBCgxMaXN0QW5hbHlzZXMSMy5nb29nbGUuY2xvdWQudmlzaW9uYWku
djFhbHBoYTEuTGlzdEFuYWx5c2VzUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC52aXNpb25haS52
MWFscGhhMS5MaXN0QW5hbHlzZXNSZXNwb25zZSJOgtPkkwI/Ej0vdjFhbHBoYTEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NsdXN0ZXJzLyp9L2FuYWx5c2Vz2kEGcGFyZW50
ErkBCgtHZXRBbmFseXNpcxIyLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5HZXRB
bmFseXNpc1JlcXVlc3QaKC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHlz
aXMiTILT5JMCPxI9L3YxYWxwaGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2x1
c3RlcnMvKi9hbmFseXNlcy8qfdpBBG5hbWUS9gEKDkNyZWF0ZUFuYWx5c2lzEjUuZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkNyZWF0ZUFuYWx5c2lzUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24ijQGC0+STAkkiPS92MWFscGhhMS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2x1c3RlcnMvKn0vYW5hbHlzZXM6CGFuYWx5c2lz2kEb
cGFyZW50LGFuYWx5c2lzLGFuYWx5c2lzX2lkykEdCghBbmFseXNpcxIRT3BlcmF0aW9uTWV0
YWRhdGES+AEKDlVwZGF0ZUFuYWx5c2lzEjUuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxw
aGExLlVwZGF0ZUFuYWx5c2lzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24ijwGC0+STAlIyRi92MWFscGhhMS97YW5hbHlzaXMubmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NsdXN0ZXJzLyovYW5hbHlzZXMvKn06CGFuYWx5c2lz2kEUYW5hbHlzaXMsdXBk
YXRlX21hc2vKQR0KCEFuYWx5c2lzEhFPcGVyYXRpb25NZXRhZGF0YRLhAQoORGVsZXRlQW5h
bHlzaXMSNS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuRGVsZXRlQW5hbHlzaXNS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ5gtPkkwI/Kj0vdjFhbHBo
YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbHVzdGVycy8qL2FuYWx5c2VzLyp9
2kEEbmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRpL
ykEXdmlzaW9uYWkuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtQt0BCiJjb20uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYx
YWxwaGExQg9MdmFTZXJ2aWNlUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb25h
aS9hcGl2MWFscGhhMS92aXNpb25haXBiO3Zpc2lvbmFpcGKqAh5Hb29nbGUuQ2xvdWQuVmlz
aW9uQUkuVjFBbHBoYTHKAh5Hb29nbGVcQ2xvdWRcVmlzaW9uQUlcVjFhbHBoYTHqAiFHb29n
bGU6OkNsb3VkOjpWaXNpb25BSTo6VjFhbHBoYTFKgTgKBxIFDgDiAQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA8CgkKAgMFEgMXAC0KCQoCAwYSAxgA
KgoICgEIEgMaADsKCQoCCCUSAxoAOwoICgEIEgMbAFUKCQoCCAsSAxsAVQoICgEIEgMcACIK
CQoCCAoSAxwAIgoICgEIEgMdADAKCQoCCAgSAx0AMAoICgEIEgMeADsKCQoCCAESAx4AOwoI
CgEIEgMfADsKCQoCCCkSAx8AOwoICgEIEgMgADoKCQoCCC0SAyAAOgqRAQoCBgASBCQAXQEa
hAEgU2VydmljZSBkZXNjcmliaW5nIGhhbmRsZXJzIGZvciByZXNvdXJjZXMuIFRoZSBzZXJ2
aWNlIGVuYWJsZXMgY2xpZW50cyB0byBydW4KIExpdmUgVmlkZW8gQW5hbHl0aWNzIChMVkEp
IG9uIHRoZSBzdHJlYW1pbmcgaW5wdXRzLgoKCgoDBgABEgMkCBoKCgoDBgADEgMlAj8KDAoF
BgADmQgSAyUCPwoKCgMGAAMSAyYCVgoMCgUGAAOaCBIDJgJWCj8KBAYAAgASBCkCLgMaMSBM
aXN0cyBBbmFseXNlcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgAC
AAESAykGEgoMCgUGAAIAAhIDKRMmCgwKBQYAAgADEgMpMUUKDQoFBgACAAQSBCoELAYKEQoJ
BgACAASwyrwiEgQqBCwGCgwKBQYAAgAEEgMtBDQKDwoIBgACAASbCAASAy0ENAoyCgQGAAIB
EgQxAjYDGiQgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIEFuYWx5c2lzLgoKDAoFBgACAQES
AzEGEQoMCgUGAAIBAhIDMRIkCgwKBQYAAgEDEgMxLzcKDQoFBgACAQQSBDIENAYKEQoJBgAC
AQSwyrwiEgQyBDQGCgwKBQYAAgEEEgM1BDIKDwoIBgACAQSbCAASAzUEMgpHCgQGAAICEgQ5
AkMDGjkgQ3JlYXRlcyBhIG5ldyBBbmFseXNpcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxv
Y2F0aW9uLgoKDAoFBgACAgESAzkGFAoMCgUGAAICAhIDORUqCgwKBQYAAgIDEgM5NVEKDQoF
BgACAgQSBDoEPQYKEQoJBgACAgSwyrwiEgQ6BD0GCgwKBQYAAgIEEgM+BEkKDwoIBgACAgSb
CAASAz4ESQoNCgUGAAICBBIEPwRCBgoPCgcGAAICBJkIEgQ/BEIGCjwKBAYAAgMSBEYCUAMa
LiBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIEFuYWx5c2lzLgoKDAoFBgAC
AwESA0YGFAoMCgUGAAIDAhIDRhUqCgwKBQYAAgMDEgNGNVEKDQoFBgACAwQSBEcESgYKEQoJ
BgACAwSwyrwiEgRHBEoGCgwKBQYAAgMEEgNLBEIKDwoIBgACAwSbCAASA0sEQgoNCgUGAAID
BBIETARPBgoPCgcGAAIDBJkIEgRMBE8GCioKBAYAAgQSBFMCXAMaHCBEZWxldGVzIGEgc2lu
Z2xlIEFuYWx5c2lzLgoKDAoFBgACBAESA1MGFAoMCgUGAAIEAhIDUxUqCgwKBQYAAgQDEgNT
NVEKDQoFBgACBAQSBFQEVgYKEQoJBgACBASwyrwiEgRUBFYGCgwKBQYAAgQEEgNXBDIKDwoI
BgACBASbCAASA1cEMgoNCgUGAAIEBBIEWARbBgoPCgcGAAIEBJkIEgRYBFsGCjUKAgQAEgRg
AHUBGikgTWVzc2FnZSBmb3IgcmVxdWVzdGluZyBsaXN0IG9mIEFuYWx5c2VzCgoKCgMEAAES
A2AIGwo+CgQEAAIAEgRiAmcEGjAgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgTGlzdEFu
YWx5c2VzUmVxdWVzdAoKDAoFBAACAAUSA2ICCAoMCgUEAAIAARIDYgkPCgwKBQQAAgADEgNi
EhMKDQoFBAACAAgSBGIUZwMKDwoIBAACAAicCAASA2MEKgoPCgcEAAIACJ8IEgRkBGYFCosB
CgQEAAIBEgNrAhYafiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBm
ZXdlciBpdGVtcyB0aGFuIHJlcXVlc3RlZC4KIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2ls
bCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoMCgUEAAIBBRIDawIHCgwKBQQAAgEB
EgNrCBEKDAoFBAACAQMSA2sUFQpOCgQEAAICEgNuAhgaQSBBIHRva2VuIGlkZW50aWZ5aW5n
IGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQAAgIF
EgNuAggKDAoFBAACAgESA24JEwoMCgUEAAICAxIDbhYXCiAKBAQAAgMSA3ECFBoTIEZpbHRl
cmluZyByZXN1bHRzCgoMCgUEAAIDBRIDcQIICgwKBQQAAgMBEgNxCQ8KDAoFBAACAwMSA3ES
EwowCgQEAAIEEgN0AhYaIyBIaW50IGZvciBob3cgdG8gb3JkZXIgdGhlIHJlc3VsdHMKCgwK
BQQAAgQFEgN0AggKDAoFBAACBAESA3QJEQoMCgUEAAIEAxIDdBQVCjcKAgQBEgV4AIEBARoq
IE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgQW5hbHlzZXMKCgoKAwQBARIDeAgc
CiMKBAQBAgASA3oCIRoWIFRoZSBsaXN0IG9mIEFuYWx5c2lzCgoMCgUEAQIABBIDegIKCgwK
BQQBAgAGEgN6CxMKDAoFBAECAAESA3oUHAoMCgUEAQIAAxIDeh8gCk4KBAQBAgESA30CHRpB
IEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91
bGQgcmV0dXJuLgoKDAoFBAECAQUSA30CCAoMCgUEAQIBARIDfQkYCgwKBQQBAgEDEgN9GxwK
NAoEBAECAhIEgAECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoK
DQoFBAECAgQSBIABAgoKDQoFBAECAgUSBIABCxEKDQoFBAECAgESBIABEh0KDQoFBAECAgMS
BIABICEKMAoCBAISBoQBAIwBARoiIE1lc3NhZ2UgZm9yIGdldHRpbmcgYW4gQW5hbHlzaXMu
CgoLCgMEAgESBIQBCBoKMQoEBAICABIGhgECiwEEGiEgUmVxdWlyZWQuIE5hbWUgb2YgdGhl
IHJlc291cmNlLgoKDQoFBAICAAUSBIYBAggKDQoFBAICAAESBIYBCQ0KDQoFBAICAAMSBIYB
EBEKDwoFBAICAAgSBoYBEosBAwoQCggEAgIACJwIABIEhwEEKgoRCgcEAgIACJ8IEgaIAQSK
AQUKMQoCBAMSBo8BAKwBARojIE1lc3NhZ2UgZm9yIGNyZWF0aW5nIGFuIEFuYWx5c2lzLgoK
CwoDBAMBEgSPAQgdCi0KBAQDAgASBpEBApYBBBodIFJlcXVpcmVkLiBWYWx1ZSBmb3IgcGFy
ZW50LgoKDQoFBAMCAAUSBJEBAggKDQoFBAMCAAESBJEBCQ8KDQoFBAMCAAMSBJEBEhMKDwoF
BAMCAAgSBpEBFJYBAwoQCggEAwIACJwIABIEkgEEKgoRCgcEAwIACJ8IEgaTAQSVAQUKNgoE
BAMCARIEmQECQhooIFJlcXVpcmVkLiBJZCBvZiB0aGUgcmVxdWVzdGluZyBvYmplY3QuCgoN
CgUEAwIBBRIEmQECCAoNCgUEAwIBARIEmQEJFAoNCgUEAwIBAxIEmQEXGAoNCgUEAwIBCBIE
mQEZQQoQCggEAwIBCJwIABIEmQEaQAo1CgQEAwICEgScAQJBGicgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBiZWluZyBjcmVhdGVkLgoKDQoFBAMCAgYSBJwBAgoKDQoFBAMCAgESBJwBCxMK
DQoFBAMCAgMSBJwBFhcKDQoFBAMCAggSBJwBGEAKEAoIBAMCAgicCAASBJwBGT8KjwYKBAQD
AgMSBKsBAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRp
ZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5
b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGln
bm9yZQogdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRo
ZSBzZXJ2ZXIgd2lsbCBndWFyYW50ZWUKIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMg
c2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0
dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1
ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUg
c2FtZSByZXF1ZXN0IElELAogdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3Bl
cmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRCB3YXMKIHJlY2VpdmVkLCBhbmQgaWYg
c28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cyBjbGll
bnRzCiBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMu
CgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0
aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAw
MDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAMCAwUSBKsBAggKDQoFBAMCAwESBKsBCRMK
DQoFBAMCAwMSBKsBFhcKDQoFBAMCAwgSBKsBGEAKEAoIBAMCAwicCAASBKsBGT8KMQoCBAQS
Bq8BAMgBARojIE1lc3NhZ2UgZm9yIHVwZGF0aW5nIGFuIEFuYWx5c2lzLgoKCwoDBAQBEgSv
AQgdCtgCCgQEBAIAEgS1AQJVGskCIFJlcXVpcmVkLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8g
c3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogQW5hbHlzaXMg
cmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1
cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxs
IHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUg
bWFzay4gSWYgdGhlCiB1c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZp
ZWxkcyB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAQCAAYSBLUBAhsKDQoFBAQCAAESBLUB
HCcKDQoFBAQCAAMSBLUBKisKDQoFBAQCAAgSBLUBLFQKEAoIBAQCAAicCAASBLUBLVMKNQoE
BAQCARIEuAECQRonIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVpbmcgdXBkYXRlZC4KCg0K
BQQEAgEGEgS4AQIKCg0KBQQEAgEBEgS4AQsTCg0KBQQEAgEDEgS4ARYXCg0KBQQEAgEIEgS4
ARhAChAKCAQEAgEInAgAEgS4ARk/Co8GCgQEBAICEgTHAQJBGoAGIE9wdGlvbmFsLiBBbiBv
cHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5p
cXVlIHJlcXVlc3QgSUQKIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0
LCB0aGUgc2VydmVyIHdpbGwga25vdyB0byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhh
cyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0
aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoK
IEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBp
bml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtl
IHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRCwKIHRoZSBzZXJ2
ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVl
c3QgSUQgd2FzCiByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25k
IHJlcXVlc3QuIFRoaXMgcHJldmVudHMgY2xpZW50cwogZnJvbSBhY2NpZGVudGFsbHkgY3Jl
YXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUg
YSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90
IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0K
BQQEAgIFEgTHAQIICg0KBQQEAgIBEgTHAQkTCg0KBQQEAgIDEgTHARYXCg0KBQQEAgIIEgTH
ARhAChAKCAQEAgIInAgAEgTHARk/CjEKAgQFEgbLAQDiAQEaIyBNZXNzYWdlIGZvciBkZWxl
dGluZyBhbiBBbmFseXNpcy4KCgsKAwQFARIEywEIHQoxCgQEBQIAEgbNAQLSAQQaISBSZXF1
aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEBQIABRIEzQECCAoNCgUEBQIAARIE
zQEJDQoNCgUEBQIAAxIEzQEQEQoPCgUEBQIACBIGzQES0gEDChAKCAQFAgAInAgAEgTOAQQq
ChEKBwQFAgAInwgSBs8BBNEBBQqPBgoEBAUCARIE4QECQRqABiBPcHRpb25hbC4gQW4gb3B0
aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1
ZSByZXF1ZXN0IElECiBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwg
dGhlIHNlcnZlciB3aWxsIGtub3cgdG8gaWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMg
YWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGd1YXJhbnRlZQogdGhh
dCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRlciB0aGUgZmlyc3QgcmVxdWVzdC4KCiBG
b3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5p
dGlhbCByZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0
aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQsCiB0aGUgc2VydmVy
IGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0
IElEIHdhcwogcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCBy
ZXF1ZXN0LiBUaGlzIHByZXZlbnRzIGNsaWVudHMKIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0
aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEg
dmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBz
dXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUE
BQIBBRIE4QECCAoNCgUEBQIBARIE4QEJEwoNCgUEBQIBAxIE4QEWFwoNCgUEBQIBCBIE4QEY
QAoQCggEBQIBCJwIABIE4QEZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest ===
    # Fields for ListAnalysesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse ===
    # Fields for ListAnalysesResponse
    # Field: analyses Type: 11 (.google.cloud.visionai.v1alpha1.Analysis)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest ===
    # Fields for GetAnalysisRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest ===
    # Fields for CreateAnalysisRequest
    # Field: parent Type: 9 ()
    # Field: analysis_id Type: 9 ()
    # Field: analysis Type: 11 (.google.cloud.visionai.v1alpha1.Analysis)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest ===
    # Fields for UpdateAnalysisRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: analysis Type: 11 (.google.cloud.visionai.v1alpha1.Analysis)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest ===
    # Fields for DeleteAnalysisRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Visionai::V1alpha1::LvaService::LiveVideoAnalyticsClient ===
package Google::Cloud::Visionai::V1alpha1::LvaService::LiveVideoAnalyticsClient;

=pod

=head2 Service Client: Google::Cloud::Visionai::V1alpha1::LvaService::LiveVideoAnalyticsClient

Client stub representing the remote C<LiveVideoAnalytics> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<visionai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'visionai.googleapis.com:443' );

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

sub list_analyses {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.LiveVideoAnalytics',
        method         => 'ListAnalyses',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse',
    });
}

sub get_analysis {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.LiveVideoAnalytics',
        method         => 'GetAnalysis',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis',
    });
}

sub create_analysis {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.LiveVideoAnalytics',
        method         => 'CreateAnalysis',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_analysis {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.LiveVideoAnalytics',
        method         => 'UpdateAnalysis',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_analysis {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.LiveVideoAnalytics',
        method         => 'DeleteAnalysis',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::LvaService - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/lva_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::LvaService;

    my $msg = Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/lva_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest

Message for requesting list of Analyses

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListAnalysesRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Server may return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Hint for how to order the results

=back

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse

Message for response to listing Analyses

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyses() >> / C<< $msg->analyses($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis>)

The list of Analysis

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest

Message for getting an Analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest

Message for creating an Analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->analysis_id() >> / C<< $msg->analysis_id($value) >>

Type: C<String>

Required. Id of the requesting object.

=item * C<< $msg->analysis() >> / C<< $msg->analysis($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis>)

Required. The resource being created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID,
the server can check if original operation with the same request ID was
received, and if so, will ignore the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest

Message for updating an Analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Analysis resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->analysis() >> / C<< $msg->analysis($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis>)

Required. The resource being updated.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID,
the server can check if original operation with the same request ID was
received, and if so, will ignore the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest

Message for deleting an Analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID,
the server can check if original operation with the same request ID was
received, and if so, will ignore the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::LvaService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
