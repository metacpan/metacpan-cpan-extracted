package Google::Devtools::Sourcerepo::V1::Sourcerepo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZGV2dG9vbHMvc291cmNlcmVwby92MS9zb3VyY2VyZXBvLnByb3RvEh1nb29n
bGUuZGV2dG9vbHMuc291cmNlcmVwby52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoeZ29vZ2xlL2lhbS92MS9pYW1fcG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3BvbGlj
eS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvIpIBCgRSZXBvEhIKBG5hbWUY
ASABKAlSBG5hbWUSEgoEc2l6ZRgCIAEoA1IEc2l6ZRIQCgN1cmwYAyABKAlSA3VybBJQCg1t
aXJyb3JfY29uZmlnGAQgASgLMisuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJlcG8udjEuTWly
cm9yQ29uZmlnUgxtaXJyb3JDb25maWciYwoMTWlycm9yQ29uZmlnEhAKA3VybBgBIAEoCVID
dXJsEh0KCndlYmhvb2tfaWQYAiABKAlSCXdlYmhvb2tJZBIiCg1kZXBsb3lfa2V5X2lkGAMg
ASgJUgtkZXBsb3lLZXlJZCIkCg5HZXRSZXBvUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1l
ImIKEExpc3RSZXBvc1JlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiJ2ChFMaXN0
UmVwb3NSZXNwb25zZRI5CgVyZXBvcxgBIAMoCzIjLmdvb2dsZS5kZXZ0b29scy5zb3VyY2Vy
ZXBvLnYxLlJlcG9SBXJlcG9zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiJkChFDcmVhdGVSZXBvUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBI3CgRy
ZXBvGAIgASgLMiMuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJlcG8udjEuUmVwb1IEcmVwbyIn
ChFEZWxldGVSZXBvUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lMvgHCgpTb3VyY2VSZXBv
EpMBCglMaXN0UmVwb3MSLy5nb29nbGUuZGV2dG9vbHMuc291cmNlcmVwby52MS5MaXN0UmVw
b3NSZXF1ZXN0GjAuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJlcG8udjEuTGlzdFJlcG9zUmVz
cG9uc2UiI4LT5JMCHRIbL3YxL3tuYW1lPXByb2plY3RzLyp9L3JlcG9zEoUBCgdHZXRSZXBv
Ei0uZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJlcG8udjEuR2V0UmVwb1JlcXVlc3QaIy5nb29n
bGUuZGV2dG9vbHMuc291cmNlcmVwby52MS5SZXBvIiaC0+STAiASHi92MS97bmFtZT1wcm9q
ZWN0cy8qL3JlcG9zLyoqfRKQAQoKQ3JlYXRlUmVwbxIwLmdvb2dsZS5kZXZ0b29scy5zb3Vy
Y2VyZXBvLnYxLkNyZWF0ZVJlcG9SZXF1ZXN0GiMuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJl
cG8udjEuUmVwbyIrgtPkkwIlIh0vdjEve3BhcmVudD1wcm9qZWN0cy8qfS9yZXBvczoEcmVw
bxJ+CgpEZWxldGVSZXBvEjAuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZXJlcG8udjEuRGVsZXRl
UmVwb1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiJoLT5JMCICoeL3YxL3tuYW1l
PXByb2plY3RzLyovcmVwb3MvKip9EoUBCgxTZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYx
LlNldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSI6gtPkkwI0Ii8v
djEve3Jlc291cmNlPXByb2plY3RzLyovcmVwb3MvKip9OnNldElhbVBvbGljeToBKhKCAQoM
R2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5HZXRJYW1Qb2xpY3lSZXF1ZXN0GhUuZ29v
Z2xlLmlhbS52MS5Qb2xpY3kiN4LT5JMCMRIvL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL3Jl
cG9zLyoqfTpnZXRJYW1Qb2xpY3kSqwEKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5p
YW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElh
bVBlcm1pc3Npb25zUmVzcG9uc2UiQILT5JMCOiI1L3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8q
L3JlcG9zLyoqfTp0ZXN0SWFtUGVybWlzc2lvbnM6ASpCfwohY29tLmdvb2dsZS5kZXZ0b29s
cy5zb3VyY2VyZXBvLnYxQg9Tb3VyY2VSZXBvUHJvdG9QAVpHZ29vZ2xlLmdvbGFuZy5vcmcv
Z2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9zb3VyY2VyZXBvL3YxO3NvdXJjZXJlcG9K
sisKBxIFDgC3AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACYKCQoCAwASAxIAJgoJCgIDARIDEwAoCgkKAgMCEgMUACQKCQoCAwMSAxUAJQoICgEIEgMX
AF4KCQoCCAsSAxcAXgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoCCAgSAxkA
MAoICgEIEgMaADoKCQoCCAESAxoAOgoqCgIGABIEHQBdARoeIFRoZSBTb3VyY2UgUmVwbyBB
UEkgc2VydmljZS4KCgoKAwYAARIDHQgSCpUBCgQGAAIAEgQgAiQDGoYBIFJldHVybnMgYWxs
IHJlcG9zIGJlbG9uZ2luZyB0byBhIHByb2plY3QuIFRoZSBzaXplcyBvZiB0aGUgcmVwb3Mg
YXJlCiBub3Qgc2V0IGJ5IExpc3RSZXBvcy4gIFRvIGdldCB0aGUgc2l6ZSBvZiBhIHJlcG8s
IHVzZSBHZXRSZXBvLgoKDAoFBgACAAESAyAGDwoMCgUGAAIAAhIDIBAgCgwKBQYAAgADEgMg
KzwKDQoFBgACAAQSBCEEIwYKEQoJBgACAASwyrwiEgQhBCMGCjEKBAYAAgESBCcCKwMaIyBS
ZXR1cm5zIGluZm9ybWF0aW9uIGFib3V0IGEgcmVwby4KCgwKBQYAAgEBEgMnBg0KDAoFBgAC
AQISAycOHAoMCgUGAAIBAxIDJycrCg0KBQYAAgEEEgQoBCoGChEKCQYAAgEEsMq8IhIEKAQq
BgqbAQoEBgACAhIEMQI2AxqMASBDcmVhdGVzIGEgcmVwbyBpbiB0aGUgZ2l2ZW4gcHJvamVj
dCB3aXRoIHRoZSBnaXZlbiBuYW1lLgoKIElmIHRoZSBuYW1lZCByZXBvc2l0b3J5IGFscmVh
ZHkgZXhpc3RzLCBgQ3JlYXRlUmVwb2AgcmV0dXJucwogYEFMUkVBRFlfRVhJU1RTYC4KCgwK
BQYAAgIBEgMxBhAKDAoFBgACAgISAzERIgoMCgUGAAICAxIDMS0xCg0KBQYAAgIEEgQyBDUG
ChEKCQYAAgIEsMq8IhIEMgQ1BgofCgQGAAIDEgQ5Aj0DGhEgRGVsZXRlcyBhIHJlcG8uCgoM
CgUGAAIDARIDOQYQCgwKBQYAAgMCEgM5ESIKDAoFBgACAwMSAzktQgoNCgUGAAIDBBIEOgQ8
BgoRCgkGAAIDBLDKvCISBDoEPAYKaAoEBgACBBIEQQJHAxpaIFNldHMgdGhlIGFjY2VzcyBj
b250cm9sIHBvbGljeSBvbiB0aGUgc3BlY2lmaWVkIHJlc291cmNlLiBSZXBsYWNlcyBhbnkK
IGV4aXN0aW5nIHBvbGljeS4KCgwKBQYAAgQBEgNBBhIKDAoFBgACBAISA0ETNAoMCgUGAAIE
AxIDQg8jCg0KBQYAAgQEEgRDBEYGChEKCQYAAgQEsMq8IhIEQwRGBgqQAQoEBgACBRIETAJR
AxqBASBHZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9yIGEgcmVzb3VyY2UuCiBS
ZXR1cm5zIGFuIGVtcHR5IHBvbGljeSBpZiB0aGUgcmVzb3VyY2UgZXhpc3RzIGFuZCBkb2Vz
IG5vdCBoYXZlIGEgcG9saWN5CiBzZXQuCgoMCgUGAAIFARIDTAYSCgwKBQYAAgUCEgNMEzQK
DAoFBgACBQMSA00PIwoNCgUGAAIFBBIETgRQBgoRCgkGAAIFBLDKvCISBE4EUAYKuAEKBAYA
AgYSBFYCXAMaqQEgUmV0dXJucyBwZXJtaXNzaW9ucyB0aGF0IGEgY2FsbGVyIGhhcyBvbiB0
aGUgc3BlY2lmaWVkIHJlc291cmNlLgogSWYgdGhlIHJlc291cmNlIGRvZXMgbm90IGV4aXN0
LCB0aGlzIHdpbGwgcmV0dXJuIGFuIGVtcHR5IHNldCBvZgogcGVybWlzc2lvbnMsIG5vdCBh
IE5PVF9GT1VORCBlcnJvci4KCgwKBQYAAgYBEgNWBhgKDAoFBgACBgISA1YZQAoMCgUGAAIG
AxIDVw83Cg0KBQYAAgYEEgRYBFsGChEKCQYAAgYEsMq8IhIEWARbBgpaCgIEABIEYABxARpO
IEEgcmVwb3NpdG9yeSAob3IgcmVwbykgaXMgYSBHaXQgcmVwb3NpdG9yeSBzdG9yaW5nIHZl
cnNpb25lZCBzb3VyY2UgY29udGVudC4KCgoKAwQAARIDYAgMCrQBCgQEAAIAEgNkAhIapgEg
UmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVwb3NpdG9yeSwgb2YgdGhlIGZvcm0KIGBwcm9qZWN0
cy88cHJvamVjdD4vcmVwb3MvPHJlcG8+YC4gIFRoZSByZXBvIG5hbWUgbWF5IGNvbnRhaW4g
c2xhc2hlcy4KIGVnLCBgcHJvamVjdHMvbXlwcm9qZWN0L3JlcG9zL25hbWUvd2l0aC9zbGFz
aGAKCgwKBQQAAgAFEgNkAggKDAoFBAACAAESA2QJDQoMCgUEAAIAAxIDZBARCmgKBAQAAgES
A2gCERpbIFRoZSBkaXNrIHVzYWdlIG9mIHRoZSByZXBvLCBpbiBieXRlcy4gUmVhZC1vbmx5
IGZpZWxkLiBTaXplIGlzIG9ubHkKIHJldHVybmVkIGJ5IEdldFJlcG8uCgoMCgUEAAIBBRID
aAIHCgwKBQQAAgEBEgNoCAwKDAoFBAACAQMSA2gPEApjCgQEAAICEgNsAhEaViBVUkwgdG8g
Y2xvbmUgdGhlIHJlcG9zaXRvcnkgZnJvbSBHb29nbGUgQ2xvdWQgU291cmNlIFJlcG9zaXRv
cmllcy4KIFJlYWQtb25seSBmaWVsZC4KCgwKBQQAAgIFEgNsAggKDAoFBAACAgESA2wJDAoM
CgUEAAICAxIDbA8QCmUKBAQAAgMSA3ACIRpYIEhvdyB0aGlzIHJlcG9zaXRvcnkgbWlycm9y
cyBhIHJlcG9zaXRvcnkgbWFuYWdlZCBieSBhbm90aGVyIHNlcnZpY2UuCiBSZWFkLW9ubHkg
ZmllbGQuCgoMCgUEAAIDBhIDcAIOCgwKBQQAAgMBEgNwDxwKDAoFBAACAwMSA3AfIAqBAQoC
BAESBXUAgwEBGnQgQ29uZmlndXJhdGlvbiB0byBhdXRvbWF0aWNhbGx5IG1pcnJvciBhIHJl
cG9zaXRvcnkgZnJvbSBhbm90aGVyCiBob3N0aW5nIHNlcnZpY2UsIGZvciBleGFtcGxlIEdp
dEh1YiBvciBCaXRCdWNrZXQuCgoKCgMEAQESA3UIFApHCgQEAQIAEgN3AhEaOiBVUkwgb2Yg
dGhlIG1haW4gcmVwb3NpdG9yeSBhdCB0aGUgb3RoZXIgaG9zdGluZyBzZXJ2aWNlLgoKDAoF
BAECAAUSA3cCCAoMCgUEAQIAARIDdwkMCgwKBQQBAgADEgN3DxAK7gEKBAQBAgESA30CGBrg
ASBJRCBvZiB0aGUgd2ViaG9vayBsaXN0ZW5pbmcgdG8gdXBkYXRlcyB0byB0cmlnZ2VyIG1p
cnJvcmluZy4KIFJlbW92aW5nIHRoaXMgd2ViaG9vayBmcm9tIHRoZSBvdGhlciBob3N0aW5n
IHNlcnZpY2Ugd2lsbCBzdG9wCiBHb29nbGUgQ2xvdWQgU291cmNlIFJlcG9zaXRvcmllcyBm
cm9tIHJlY2VpdmluZyBub3RpZmljYXRpb25zLAogYW5kIHRoZXJlYnkgZGlzYWJsaW5nIG1p
cnJvcmluZy4KCgwKBQQBAgEFEgN9AggKDAoFBAECAQESA30JEwoMCgUEAQIBAxIDfRYXCrUB
CgQEAQICEgSCAQIbGqYBIElEIG9mIHRoZSBTU0ggZGVwbG95IGtleSBhdCB0aGUgb3RoZXIg
aG9zdGluZyBzZXJ2aWNlLgogUmVtb3ZpbmcgdGhpcyBrZXkgZnJvbSB0aGUgb3RoZXIgc2Vy
dmljZSB3b3VsZCBkZWF1dGhvcml6ZQogR29vZ2xlIENsb3VkIFNvdXJjZSBSZXBvc2l0b3Jp
ZXMgZnJvbSBtaXJyb3JpbmcuCgoNCgUEAQICBRIEggECCAoNCgUEAQICARIEggEJFgoNCgUE
AQICAxIEggEZGgokCgIEAhIGhgEAigEBGhYgUmVxdWVzdCBmb3IgR2V0UmVwby4KCgsKAwQC
ARIEhgEIFgpwCgQEAgIAEgSJAQISGmIgVGhlIG5hbWUgb2YgdGhlIHJlcXVlc3RlZCByZXBv
c2l0b3J5LiBWYWx1ZXMgYXJlIG9mIHRoZSBmb3JtCiBgcHJvamVjdHMvPHByb2plY3Q+L3Jl
cG9zLzxyZXBvPmAuCgoNCgUEAgIABRIEiQECCAoNCgUEAgIAARIEiQEJDQoNCgUEAgIAAxIE
iQEQEQomCgIEAxIGjQEAmgEBGhggUmVxdWVzdCBmb3IgTGlzdFJlcG9zLgoKCwoDBAMBEgSN
AQgYCmoKBAQDAgASBJABAhIaXCBUaGUgcHJvamVjdCBJRCB3aG9zZSByZXBvcyBzaG91bGQg
YmUgbGlzdGVkLiBWYWx1ZXMgYXJlIG9mIHRoZSBmb3JtCiBgcHJvamVjdHMvPHByb2plY3Q+
YC4KCg0KBQQDAgAFEgSQAQIICg0KBQQDAgABEgSQAQkNCg0KBQQDAgADEgSQARARCoABCgQE
AwIBEgSUAQIWGnIgTWF4aW11bSBudW1iZXIgb2YgcmVwb3NpdG9yaWVzIHRvIHJldHVybjsg
YmV0d2VlbiAxIGFuZCA1MDAuCiBJZiBub3Qgc2V0IG9yIHplcm8sIGRlZmF1bHRzIHRvIDEw
MCBhdCB0aGUgc2VydmVyLgoKDQoFBAMCAQUSBJQBAgcKDQoFBAMCAQESBJQBCBEKDQoFBAMC
AQMSBJQBFBUKxgEKBAQDAgISBJkBAhgatwEgUmVzdW1lIGxpc3RpbmcgcmVwb3NpdG9yaWVz
IHdoZXJlIGEgcHJpb3IgTGlzdFJlcG9zUmVzcG9uc2UKIGxlZnQgb2ZmLiBUaGlzIGlzIGFu
IG9wYXF1ZSB0b2tlbiB0aGF0IG11c3QgYmUgb2J0YWluZWQgZnJvbQogYSByZWNlbnQsIHBy
aW9yIExpc3RSZXBvc1Jlc3BvbnNlJ3MgbmV4dF9wYWdlX3Rva2VuIGZpZWxkLgoKDQoFBAMC
AgUSBJkBAggKDQoFBAMCAgESBJkBCRMKDQoFBAMCAgMSBJkBFhcKWgoCBAQSBp0BAKUBARpM
IFJlc3BvbnNlIGZvciBMaXN0UmVwb3MuICBUaGUgc2l6ZSBpcyBub3Qgc2V0IGluIHRoZSBy
ZXR1cm5lZCByZXBvc2l0b3JpZXMuCgoLCgMEBAESBJ0BCBkKIQoEBAQCABIEnwECGhoTIFRo
ZSBsaXN0ZWQgcmVwb3MuCgoNCgUEBAIABBIEnwECCgoNCgUEBAIABhIEnwELDwoNCgUEBAIA
ARIEnwEQFQoNCgUEBAIAAxIEnwEYGQqyAQoEBAQCARIEpAECHRqjASBJZiBub24tZW1wdHks
IGFkZGl0aW9uYWwgcmVwb3NpdG9yaWVzIGV4aXN0IHdpdGhpbiB0aGUgcHJvamVjdC4gVGhl
c2UKIGNhbiBiZSByZXRyaWV2ZWQgYnkgaW5jbHVkaW5nIHRoaXMgdmFsdWUgaW4gdGhlIG5l
eHQgTGlzdFJlcG9zUmVxdWVzdCdzCiBwYWdlX3Rva2VuIGZpZWxkLgoKDQoFBAQCAQUSBKQB
AggKDQoFBAQCAQESBKQBCRgKDQoFBAQCAQMSBKQBGxwKJgoCBAUSBqgBALABARoYIFJlcXVl
c3QgZm9yIENyZWF0ZVJlcG8KCgsKAwQFARIEqAEIGQpmCgQEBQIAEgSrAQIUGlggVGhlIHBy
b2plY3QgaW4gd2hpY2ggdG8gY3JlYXRlIHRoZSByZXBvLiBWYWx1ZXMgYXJlIG9mIHRoZSBm
b3JtCiBgcHJvamVjdHMvPHByb2plY3Q+YC4KCg0KBQQFAgAFEgSrAQIICg0KBQQFAgABEgSr
AQkPCg0KBQQFAgADEgSrARITCpkBCgQEBQIBEgSvAQIQGooBIFRoZSByZXBvIHRvIGNyZWF0
ZS4gIE9ubHkgbmFtZSBzaG91bGQgYmUgc2V0OyBzZXR0aW5nIG90aGVyIGZpZWxkcwogaXMg
YW4gZXJyb3IuICBUaGUgcHJvamVjdCBpbiB0aGUgbmFtZSBzaG91bGQgbWF0Y2ggdGhlIHBh
cmVudCBmaWVsZC4KCg0KBQQFAgEGEgSvAQIGCg0KBQQFAgEBEgSvAQcLCg0KBQQFAgEDEgSv
AQ4PCicKAgQGEgazAQC3AQEaGSBSZXF1ZXN0IGZvciBEZWxldGVSZXBvLgoKCwoDBAYBEgSz
AQgZCmoKBAQGAgASBLYBAhIaXCBUaGUgbmFtZSBvZiB0aGUgcmVwbyB0byBkZWxldGUuIFZh
bHVlcyBhcmUgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy88cHJvamVjdD4vcmVwb3MvPHJlcG8+
YC4KCg0KBQQGAgAFEgS2AQIICg0KBQQGAgABEgS2AQkNCg0KBQQGAgADEgS2ARARYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo ===
    # Fields for Repo
    # Field: name Type: 9 ()
    # Field: size Type: 3 ()
    # Field: url Type: 9 ()
    # Field: mirror_config Type: 11 (.google.devtools.sourcerepo.v1.MirrorConfig)

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig ===
    # Fields for MirrorConfig
    # Field: url Type: 9 ()
    # Field: webhook_id Type: 9 ()
    # Field: deploy_key_id Type: 9 ()

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest ===
    # Fields for GetRepoRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest ===
    # Fields for ListReposRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse ===
    # Fields for ListReposResponse
    # Field: repos Type: 11 (.google.devtools.sourcerepo.v1.Repo)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest ===
    # Fields for CreateRepoRequest
    # Field: parent Type: 9 ()
    # Field: repo Type: 11 (.google.devtools.sourcerepo.v1.Repo)

# === Message: Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest ===
    # Fields for DeleteRepoRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Devtools::Sourcerepo::V1::Sourcerepo::SourceRepoClient ===
package Google::Devtools::Sourcerepo::V1::Sourcerepo::SourceRepoClient;

=pod

=head2 Service Client: Google::Devtools::Sourcerepo::V1::Sourcerepo::SourceRepoClient

Client stub representing the remote C<SourceRepo> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub list_repos {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'ListRepos',
        request        => $req,
        response_class => 'Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse',
    });
}

sub get_repo {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'GetRepo',
        request        => $req,
        response_class => 'Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo',
    });
}

sub create_repo {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'CreateRepo',
        request        => $req,
        response_class => 'Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo',
    });
}

sub delete_repo {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'DeleteRepo',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.sourcerepo.v1.SourceRepo',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Sourcerepo::V1::Sourcerepo - Compiled Protocol Buffers messages for google/devtools/sourcerepo/v1/sourcerepo.proto

=head1 SYNOPSIS

    use Google::Devtools::Sourcerepo::V1::Sourcerepo;

    my $msg = Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo->new({
        name => $name,
        size => $size,
        url => $url,
        mirror_config => $mirror_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/sourcerepo/v1/sourcerepo.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo

A repository (or repo) is a Git repository storing versioned source content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource name of the repository, of the form
`projects/<project>/repos/<repo>`.  The repo name may contain slashes.
eg, `projects/myproject/repos/name/with/slash`

=item * C<< $msg->size() >> / C<< $msg->size($value) >>

Type: C<Int64>

The disk usage of the repo, in bytes. Read-only field. Size is only
returned by GetRepo.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

URL to clone the repository from Google Cloud Source Repositories.
Read-only field.

=item * C<< $msg->mirror_config() >> / C<< $msg->mirror_config($value) >>

Type: C<Message> (L<Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig>)

How this repository mirrors a repository managed by another service.
Read-only field.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig

Configuration to automatically mirror a repository from another
hosting service, for example GitHub or BitBucket.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

URL of the main repository at the other hosting service.

=item * C<< $msg->webhook_id() >> / C<< $msg->webhook_id($value) >>

Type: C<String>

ID of the webhook listening to updates to trigger mirroring.
Removing this webhook from the other hosting service will stop
Google Cloud Source Repositories from receiving notifications,
and thereby disabling mirroring.

=item * C<< $msg->deploy_key_id() >> / C<< $msg->deploy_key_id($value) >>

Type: C<String>

ID of the SSH deploy key at the other hosting service.
Removing this key from the other service would deauthorize
Google Cloud Source Repositories from mirroring.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest

Request for GetRepo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the requested repository. Values are of the form
`projects/<project>/repos/<repo>`.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest

Request for ListRepos.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The project ID whose repos should be listed. Values are of the form
`projects/<project>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of repositories to return; between 1 and 500.
If not set or zero, defaults to 100 at the server.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Resume listing repositories where a prior ListReposResponse
left off. This is an opaque token that must be obtained from
a recent, prior ListReposResponse's next_page_token field.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse

Response for ListRepos.  The size is not set in the returned repositories.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repos() >> / C<< $msg->repos($value) >>

Type: C<Message> (L<Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo>)

The listed repos.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If non-empty, additional repositories exist within the project. These
can be retrieved by including this value in the next ListReposRequest's
page_token field.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest

Request for CreateRepo

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The project in which to create the repo. Values are of the form
`projects/<project>`.

=item * C<< $msg->repo() >> / C<< $msg->repo($value) >>

Type: C<Message> (L<Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo>)

The repo to create.  Only name should be set; setting other fields
is an error.  The project in the name should match the parent field.

=back

=head2 Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest

Request for DeleteRepo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the repo to delete. Values are of the form
`projects/<project>/repos/<repo>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Sourcerepo::V1::Sourcerepo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
