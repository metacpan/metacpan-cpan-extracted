package Google::Cloud::Dialogflow::V2beta1::KnowledgeBase;

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
CjRnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2tub3dsZWRnZV9iYXNlLnByb3Rv
Eh9nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKdAgoN
S25vd2xlZGdlQmFzZRISCgRuYW1lGAEgASgJUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEo
CUID4EECUgtkaXNwbGF5TmFtZRIjCg1sYW5ndWFnZV9jb2RlGAQgASgJUgxsYW5ndWFnZUNv
ZGU6qgHqQaYBCidkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0tub3dsZWRnZUJhc2USMnBy
b2plY3RzL3twcm9qZWN0fS9rbm93bGVkZ2VCYXNlcy97a25vd2xlZGdlX2Jhc2V9Ekdwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va25vd2xlZGdlQmFzZXMve2tu
b3dsZWRnZV9iYXNlfSK4AQoZTGlzdEtub3dsZWRnZUJhc2VzUmVxdWVzdBJHCgZwYXJlbnQY
ASABKAlCL+BBAvpBKRInZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Lbm93bGVkZ2VCYXNl
UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMg
ASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXIinQEKGkxpc3RLbm93bGVk
Z2VCYXNlc1Jlc3BvbnNlElcKD2tub3dsZWRnZV9iYXNlcxgBIAMoCzIuLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuS25vd2xlZGdlQmFzZVIOa25vd2xlZGdlQmFzZXMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIl4KF0dldEtub3dsZWRnZUJh
c2VSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9Lbm93bGVkZ2VCYXNlUgRuYW1lIsEBChpDcmVhdGVLbm93bGVkZ2VCYXNlUmVxdWVz
dBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9L
bm93bGVkZ2VCYXNlUgZwYXJlbnQSWgoOa25vd2xlZGdlX2Jhc2UYAiABKAsyLi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MmJldGExLktub3dsZWRnZUJhc2VCA+BBAlINa25vd2xlZGdl
QmFzZSJ8ChpEZWxldGVLbm93bGVkZ2VCYXNlUmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6
QSkKJ2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vS25vd2xlZGdlQmFzZVIEbmFtZRIZCgVm
b3JjZRgCIAEoCEID4EEBUgVmb3JjZSK6AQoaVXBkYXRlS25vd2xlZGdlQmFzZVJlcXVlc3QS
WgoOa25vd2xlZGdlX2Jhc2UYASABKAsyLi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJl
dGExLktub3dsZWRnZUJhc2VCA+BBAlINa25vd2xlZGdlQmFzZRJACgt1cGRhdGVfbWFzaxgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzazK9DgoO
S25vd2xlZGdlQmFzZXMSvQIKEkxpc3RLbm93bGVkZ2VCYXNlcxI6Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuTGlzdEtub3dsZWRnZUJhc2VzUmVxdWVzdBo7Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuTGlzdEtub3dsZWRnZUJhc2VzUmVzcG9uc2UirQGC
0+STAp0BEisvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyp9L2tub3dsZWRnZUJhc2VzWjkS
Ny92MmJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0va25vd2xlZGdlQmFz
ZXNaMxIxL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50fS9rbm93bGVkZ2VCYXNl
c9pBBnBhcmVudBKqAgoQR2V0S25vd2xlZGdlQmFzZRI4Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyYmV0YTEuR2V0S25vd2xlZGdlQmFzZVJlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLktub3dsZWRnZUJhc2UiqwGC0+STAp0BEisvdjJiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL2tub3dsZWRnZUJhc2VzLyp9WjkSNy92MmJldGExL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyova25vd2xlZGdlQmFzZXMvKn1aMxIxL3YyYmV0YTEve25hbWU9
cHJvamVjdHMvKi9hZ2VudC9rbm93bGVkZ2VCYXNlcy8qfdpBBG5hbWUS8QIKE0NyZWF0ZUtu
b3dsZWRnZUJhc2USOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNyZWF0ZUtu
b3dsZWRnZUJhc2VSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5L
bm93bGVkZ2VCYXNlIuwBgtPkkwLNASIrL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qfS9r
bm93bGVkZ2VCYXNlczoOa25vd2xlZGdlX2Jhc2VaSSI3L3YyYmV0YTEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qfS9rbm93bGVkZ2VCYXNlczoOa25vd2xlZGdlX2Jhc2VaQyIx
L3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50fS9rbm93bGVkZ2VCYXNlczoOa25v
d2xlZGdlX2Jhc2XaQRVwYXJlbnQsa25vd2xlZGdlX2Jhc2USmAIKE0RlbGV0ZUtub3dsZWRn
ZUJhc2USOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkRlbGV0ZUtub3dsZWRn
ZUJhc2VSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IqsBgtPkkwKdASorL3YyYmV0
YTEve25hbWU9cHJvamVjdHMvKi9rbm93bGVkZ2VCYXNlcy8qfVo5KjcvdjJiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2tub3dsZWRnZUJhc2VzLyp9WjMqMS92MmJldGEx
L3tuYW1lPXByb2plY3RzLyovYWdlbnQva25vd2xlZGdlQmFzZXMvKn3aQQRuYW1lErQDChNV
cGRhdGVLbm93bGVkZ2VCYXNlEjsuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5V
cGRhdGVLbm93bGVkZ2VCYXNlUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
YmV0YTEuS25vd2xlZGdlQmFzZSKvAoLT5JMC+gEyOi92MmJldGExL3trbm93bGVkZ2VfYmFz
ZS5uYW1lPXByb2plY3RzLyova25vd2xlZGdlQmFzZXMvKn06Dmtub3dsZWRnZV9iYXNlWlgy
Ri92MmJldGExL3trbm93bGVkZ2VfYmFzZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
a25vd2xlZGdlQmFzZXMvKn06Dmtub3dsZWRnZV9iYXNlWlIyQC92MmJldGExL3trbm93bGVk
Z2VfYmFzZS5uYW1lPXByb2plY3RzLyovYWdlbnQva25vd2xlZGdlQmFzZXMvKn06Dmtub3ds
ZWRnZV9iYXNl2kEaa25vd2xlZGdlX2Jhc2UsdXBkYXRlX21hc2vaQQ5rbm93bGVkZ2VfYmFz
ZRp4ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaWFsb2dmbG93QqcBCiNjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRh
MUISS25vd2xlZGdlQmFzZVByb3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxv
dy9hcGl2MmJldGExL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoCH0dvb2dsZS5D
bG91ZC5EaWFsb2dmbG93LlYyQmV0YTFK2D0KBxIFDgCeAgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAlCgkKAgMFEgMXACoKCAoBCBIDGQA8CgkKAggl
EgMZADwKCAoBCBIDGgBaCgkKAggLEgMaAFoKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBID
HAAzCgkKAggIEgMcADMKCAoBCBIDHQA8CgkKAggBEgMdADwKCAoBCBIDHgAgCgkKAggkEgMe
ACAKZQoCBgASBSIAhQEBGlggU2VydmljZSBmb3IgbWFuYWdpbmcKIFtLbm93bGVkZ2VCYXNl
c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Lbm93bGVkZ2VCYXNlXS4KCgoK
AwYAARIDIggWCgoKAwYAAxIDIwJBCgwKBQYAA5kIEgMjAkEKCwoDBgADEgQkAiYzCg0KBQYA
A5oIEgQkAiYzCrkBCgQGAAIAEgQsAjgDGqoBIFJldHVybnMgdGhlIGxpc3Qgb2YgYWxsIGtu
b3dsZWRnZSBiYXNlcyBvZiB0aGUgc3BlY2lmaWVkIGFnZW50LgoKIE5vdGU6IFRoZSBgcHJv
amVjdHMuYWdlbnQua25vd2xlZGdlQmFzZXNgIHJlc291cmNlIGlzIGRlcHJlY2F0ZWQ7CiBv
bmx5IHVzZSBgcHJvamVjdHMua25vd2xlZGdlQmFzZXNgLgoKDAoFBgACAAESAywGGAoMCgUG
AAIAAhIDLBkyCgwKBQYAAgADEgMtDykKDQoFBgACAAQSBC4ENgYKEQoJBgACAASwyrwiEgQu
BDYGCgwKBQYAAgAEEgM3BDQKDwoIBgACAASbCAASAzcENAqhAQoEBgACARIEPgJJAxqSASBS
ZXRyaWV2ZXMgdGhlIHNwZWNpZmllZCBrbm93bGVkZ2UgYmFzZS4KCiBOb3RlOiBUaGUgYHBy
b2plY3RzLmFnZW50Lmtub3dsZWRnZUJhc2VzYCByZXNvdXJjZSBpcyBkZXByZWNhdGVkOwog
b25seSB1c2UgYHByb2plY3RzLmtub3dsZWRnZUJhc2VzYC4KCgwKBQYAAgEBEgM+BhYKDAoF
BgACAQISAz4XLgoMCgUGAAIBAxIDPjlGCg0KBQYAAgEEEgQ/BEcGChEKCQYAAgEEsMq8IhIE
PwRHBgoMCgUGAAIBBBIDSAQyCg8KCAYAAgEEmwgAEgNIBDIKkwEKBAYAAgISBE8CXQMahAEg
Q3JlYXRlcyBhIGtub3dsZWRnZSBiYXNlLgoKIE5vdGU6IFRoZSBgcHJvamVjdHMuYWdlbnQu
a25vd2xlZGdlQmFzZXNgIHJlc291cmNlIGlzIGRlcHJlY2F0ZWQ7CiBvbmx5IHVzZSBgcHJv
amVjdHMua25vd2xlZGdlQmFzZXNgLgoKDAoFBgACAgESA08GGQoMCgUGAAICAhIDTxo0CgwK
BQYAAgIDEgNPP0wKDQoFBgACAgQSBFAEWwYKEQoJBgACAgSwyrwiEgRQBFsGCgwKBQYAAgIE
EgNcBEMKDwoIBgACAgSbCAASA1wEQwqfAQoEBgACAxIEYwJvAxqQASBEZWxldGVzIHRoZSBz
cGVjaWZpZWQga25vd2xlZGdlIGJhc2UuCgogTm90ZTogVGhlIGBwcm9qZWN0cy5hZ2VudC5r
bm93bGVkZ2VCYXNlc2AgcmVzb3VyY2UgaXMgZGVwcmVjYXRlZDsKIG9ubHkgdXNlIGBwcm9q
ZWN0cy5rbm93bGVkZ2VCYXNlc2AuCgoMCgUGAAIDARIDYwYZCgwKBQYAAgMCEgNjGjQKDAoF
BgACAwMSA2QPJAoNCgUGAAIDBBIEZQRtBgoRCgkGAAIDBLDKvCISBGUEbQYKDAoFBgACAwQS
A24EMgoPCggGAAIDBJsIABIDbgQyCqABCgQGAAIEEgV1AoQBAxqQASBVcGRhdGVzIHRoZSBz
cGVjaWZpZWQga25vd2xlZGdlIGJhc2UuCgogTm90ZTogVGhlIGBwcm9qZWN0cy5hZ2VudC5r
bm93bGVkZ2VCYXNlc2AgcmVzb3VyY2UgaXMgZGVwcmVjYXRlZDsKIG9ubHkgdXNlIGBwcm9q
ZWN0cy5rbm93bGVkZ2VCYXNlc2AuCgoMCgUGAAIEARIDdQYZCgwKBQYAAgQCEgN1GjQKDAoF
BgACBAMSA3U/TAoOCgUGAAIEBBIFdgSBAQYKEgoJBgACBASwyrwiEgV2BIEBBgoNCgUGAAIE
BBIEggEESAoQCggGAAIEBJsIABIEggEESAoNCgUGAAIEBBIEgwEEPAoQCggGAAIEBJsIARIE
gwEEPAqXBAoCBAASBpEBAKYBARqIBCBBIGtub3dsZWRnZSBiYXNlIHJlcHJlc2VudHMgYSBj
b2xsZWN0aW9uIG9mIGtub3dsZWRnZSBkb2N1bWVudHMgdGhhdCB5b3UKIHByb3ZpZGUgdG8g
RGlhbG9nZmxvdy4gWW91ciBrbm93bGVkZ2UgZG9jdW1lbnRzIGNvbnRhaW4gaW5mb3JtYXRp
b24gdGhhdCBtYXkKIGJlIHVzZWZ1bCBkdXJpbmcgY29udmVyc2F0aW9ucyB3aXRoIGVuZC11
c2Vycy4gU29tZSBEaWFsb2dmbG93IGZlYXR1cmVzIHVzZQoga25vd2xlZGdlIGJhc2VzIHdo
ZW4gbG9va2luZyBmb3IgYSByZXNwb25zZSB0byBhbiBlbmQtdXNlciBpbnB1dC4KCiBGb3Ig
bW9yZSBpbmZvcm1hdGlvbiwgc2VlIHRoZSBba25vd2xlZGdlIGJhc2UKIGd1aWRlXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9kb2NzL2hvdy9rbm93bGVkZ2UtYmFz
ZXMpLgoKIE5vdGU6IFRoZSBgcHJvamVjdHMuYWdlbnQua25vd2xlZGdlQmFzZXNgIHJlc291
cmNlIGlzIGRlcHJlY2F0ZWQ7CiBvbmx5IHVzZSBgcHJvamVjdHMua25vd2xlZGdlQmFzZXNg
LgoKCwoDBAABEgSRAQgVCg0KAwQABxIGkgEClgEECg8KBQQAB50IEgaSAQKWAQQKyAEKBAQA
AgASBJwBAhIauQEgVGhlIGtub3dsZWRnZSBiYXNlIHJlc291cmNlIG5hbWUuCiBUaGUgbmFt
ZSBtdXN0IGJlIGVtcHR5IHdoZW4gY3JlYXRpbmcgYSBrbm93bGVkZ2UgYmFzZS4KIEZvcm1h
dDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiBJRD4va25v
d2xlZGdlQmFzZXMvPEtub3dsZWRnZSBCYXNlIElEPmAuCgoNCgUEAAIABRIEnAECCAoNCgUE
AAIAARIEnAEJDQoNCgUEAAIAAxIEnAEQEQqPAQoEBAACARIEoAECQxqAASBSZXF1aXJlZC4g
VGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUga25vd2xlZGdlIGJhc2UuIFRoZSBuYW1lIG11c3Qg
YmUgMTAyNAogYnl0ZXMgb3IgbGVzczsgb3RoZXJ3aXNlLCB0aGUgY3JlYXRpb24gcmVxdWVz
dCBmYWlscy4KCg0KBQQAAgEFEgSgAQIICg0KBQQAAgEBEgSgAQkVCg0KBQQAAgEDEgSgARgZ
Cg0KBQQAAgEIEgSgARpCChAKCAQAAgEInAgAEgSgARtBCs8BCgQEAAICEgSlAQIbGsABIExh
bmd1YWdlIHdoaWNoIHJlcHJlc2VudHMgdGhlIEtub3dsZWRnZUJhc2UuIFdoZW4gdGhlIEtu
b3dsZWRnZUJhc2UgaXMKIGNyZWF0ZWQvdXBkYXRlZCwgdGhpcyBpcyBwb3B1bGF0ZWQgZm9y
IGFsbCBub24gZW4tdXMgbGFuZ3VhZ2VzLiBJZiBub3QKIHBvcHVsYXRlZCwgdGhlIGRlZmF1
bHQgbGFuZ3VhZ2UgZW4tdXMgYXBwbGllcy4KCg0KBQQAAgIFEgSlAQIICg0KBQQAAgIBEgSl
AQkWCg0KBQQAAgIDEgSlARkaCowBCgIEARIGqgEA1gEBGn4gUmVxdWVzdCBtZXNzYWdlIGZv
cgogW0tub3dsZWRnZUJhc2VzLkxpc3RLbm93bGVkZ2VCYXNlc11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5Lbm93bGVkZ2VCYXNlcy5MaXN0S25vd2xlZGdlQmFzZXNdLgoK
CwoDBAEBEgSqAQghCoEBCgQEAQIAEgatAQKyAQQacSBSZXF1aXJlZC4gVGhlIHByb2plY3Qg
dG8gbGlzdCBvZiBrbm93bGVkZ2UgYmFzZXMgZm9yLgogRm9ybWF0OiBgcHJvamVjdHMvPFBy
b2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+YC4KCg0KBQQBAgAFEgStAQIICg0K
BQQBAgABEgStAQkPCg0KBQQBAgADEgStARITCg8KBQQBAgAIEgatARSyAQMKEAoIBAECAAic
CAASBK4BBCoKEQoHBAECAAifCBIGrwEEsQEFCmcKBAQBAgESBLYBAhYaWSBUaGUgbWF4aW11
bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZh
dWx0IDEwIGFuZCBhdCBtb3N0IDEwMC4KCg0KBQQBAgEFEgS2AQIHCg0KBQQBAgEBEgS2AQgR
Cg0KBQQBAgEDEgS2ARQVClAKBAQBAgISBLkBAhgaQiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZh
bHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUEAQICBRIE
uQECCAoNCgUEAQICARIEuQEJEwoNCgUEAQICAxIEuQEWFwq8BwoEBAECAxIE1QECFBqtByBU
aGUgZmlsdGVyIGV4cHJlc3Npb24gdXNlZCB0byBmaWx0ZXIga25vd2xlZGdlIGJhc2VzIHJl
dHVybmVkIGJ5IHRoZSBsaXN0CiBtZXRob2QuIFRoZSBleHByZXNzaW9uIGhhcyB0aGUgZm9s
bG93aW5nIHN5bnRheDoKCiAgIDxmaWVsZD4gPG9wZXJhdG9yPiA8dmFsdWU+IFtBTkQgPGZp
ZWxkPiA8b3BlcmF0b3I+IDx2YWx1ZT5dIC4uLgoKIFRoZSBmb2xsb3dpbmcgZmllbGRzIGFu
ZCBvcGVyYXRvcnMgYXJlIHN1cHBvcnRlZDoKCiAqIGRpc3BsYXlfbmFtZSB3aXRoIGhhcyg6
KSBvcGVyYXRvcgogKiBsYW5ndWFnZV9jb2RlIHdpdGggZXF1YWxzKD0pIG9wZXJhdG9yCgog
RXhhbXBsZXM6CgogKiAnbGFuZ3VhZ2VfY29kZT1lbi11cycgbWF0Y2hlcyBrbm93bGVkZ2Ug
YmFzZXMgd2l0aCBlbi11cyBsYW5ndWFnZSBjb2RlLgogKiAnZGlzcGxheV9uYW1lOmFydGlj
bGVzJyBtYXRjaGVzIGtub3dsZWRnZSBiYXNlcyB3aG9zZSBkaXNwbGF5IG5hbWUKICAgY29u
dGFpbnMgImFydGljbGVzIi4KICogJ2Rpc3BsYXlfbmFtZToiQmVzdCBBcnRpY2xlcyInIG1h
dGNoZXMga25vd2xlZGdlIGJhc2VzIHdob3NlIGRpc3BsYXkKICAgbmFtZSBjb250YWlucyAi
QmVzdCBBcnRpY2xlcyIuCiAqICdsYW5ndWFnZV9jb2RlPWVuLWdiIEFORCBkaXNwbGF5X25h
bWU9YXJ0aWNsZXMnIG1hdGNoZXMgYWxsIGtub3dsZWRnZQogICBiYXNlcyB3aG9zZSBkaXNw
bGF5IG5hbWUgY29udGFpbnMgImFydGljbGVzIiBhbmQgd2hvc2UgbGFuZ3VhZ2UgY29kZSBp
cwogICAiZW4tZ2IiLgoKIE5vdGU6IEFuIGVtcHR5IGZpbHRlciBzdHJpbmcgKGkuZS4gIiIp
IGlzIGEgbm8tb3AgYW5kIHdpbGwgcmVzdWx0IGluIG5vCiBmaWx0ZXJpbmcuCgogRm9yIG1v
cmUgaW5mb3JtYXRpb24gYWJvdXQgZmlsdGVyaW5nLCBzZWUKIFtBUEkgRmlsdGVyaW5nXSho
dHRwczovL2FpcC5kZXYvMTYwKS4KCg0KBQQBAgMFEgTVAQIICg0KBQQBAgMBEgTVAQkPCg0K
BQQBAgMDEgTVARITCo0BCgIEAhIG2gEA4QEBGn8gUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtL
bm93bGVkZ2VCYXNlcy5MaXN0S25vd2xlZGdlQmFzZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyYmV0YTEuS25vd2xlZGdlQmFzZXMuTGlzdEtub3dsZWRnZUJhc2VzXS4KCgsKAwQC
ARIE2gEIIgosCgQEAgIAEgTcAQItGh4gVGhlIGxpc3Qgb2Yga25vd2xlZGdlIGJhc2VzLgoK
DQoFBAICAAQSBNwBAgoKDQoFBAICAAYSBNwBCxgKDQoFBAICAAESBNwBGSgKDQoFBAICAAMS
BNwBKywKbwoEBAICARIE4AECHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ug
b2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHJlc3VsdHMgaW4g
dGhlIGxpc3QuCgoNCgUEAgIBBRIE4AECCAoNCgUEAgIBARIE4AEJGAoNCgUEAgIBAxIE4AEb
HAqIAQoCBAMSBuUBAO8BARp6IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtLbm93bGVkZ2VCYXNl
cy5HZXRLbm93bGVkZ2VCYXNlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLktu
b3dsZWRnZUJhc2VzLkdldEtub3dsZWRnZUJhc2VdLgoKCwoDBAMBEgTlAQgfCqUBCgQEAwIA
EgbpAQLuAQQalAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBrbm93bGVkZ2UgYmFzZSB0
byByZXRyaWV2ZS4KIEZvcm1hdCBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88
TG9jYXRpb24KIElEPi9rbm93bGVkZ2VCYXNlcy88S25vd2xlZGdlIEJhc2UgSUQ+YC4KCg0K
BQQDAgAFEgTpAQIICg0KBQQDAgABEgTpAQkNCg0KBQQDAgADEgTpARARCg8KBQQDAgAIEgbp
ARLuAQMKEAoIBAMCAAicCAASBOoBBCoKEQoHBAMCAAifCBIG6wEE7QEFCo8BCgIEBBIG8wEA
/wEBGoABIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtLbm93bGVkZ2VCYXNlcy5DcmVhdGVLbm93
bGVkZ2VCYXNlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLktub3dsZWRnZUJh
c2VzLkNyZWF0ZUtub3dsZWRnZUJhc2VdLgoKCwoDBAQBEgTzAQgiCoEBCgQEBAIAEgb2AQL7
AQQacSBSZXF1aXJlZC4gVGhlIHByb2plY3QgdG8gY3JlYXRlIGEga25vd2xlZGdlIGJhc2Ug
Zm9yLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRp
b24gSUQ+YC4KCg0KBQQEAgAFEgT2AQIICg0KBQQEAgABEgT2AQkPCg0KBQQEAgADEgT2ARIT
Cg8KBQQEAgAIEgb2ART7AQMKEAoIBAQCAAicCAASBPcBBCoKEQoHBAQCAAifCBIG+AEE+gEF
CjcKBAQEAgESBP4BAkwaKSBSZXF1aXJlZC4gVGhlIGtub3dsZWRnZSBiYXNlIHRvIGNyZWF0
ZS4KCg0KBQQEAgEGEgT+AQIPCg0KBQQEAgEBEgT+ARAeCg0KBQQEAgEDEgT+ASEiCg0KBQQE
AgEIEgT+ASNLChAKCAQEAgEInAgAEgT+ASRKCo8BCgIEBRIGgwIAkQIBGoABIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtLbm93bGVkZ2VCYXNlcy5EZWxldGVLbm93bGVkZ2VCYXNlXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLktub3dsZWRnZUJhc2VzLkRlbGV0ZUtub3ds
ZWRnZUJhc2VdLgoKCwoDBAUBEgSDAggiCqQBCgQEBQIAEgaHAgKMAgQakwEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBrbm93bGVkZ2UgYmFzZSB0byBkZWxldGUuCiBGb3JtYXQ6IGBw
cm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogSUQ+L2tub3dsZWRn
ZUJhc2VzLzxLbm93bGVkZ2UgQmFzZSBJRD5gLgoKDQoFBAUCAAUSBIcCAggKDQoFBAUCAAES
BIcCCQ0KDQoFBAUCAAMSBIcCEBEKDwoFBAUCAAgSBocCEowCAwoQCggEBQIACJwIABIEiAIE
KgoRCgcEBQIACJ8IEgaJAgSLAgUKhAEKBAQFAgESBJACAjoadiBPcHRpb25hbC4gRm9yY2Ug
ZGVsZXRlcyB0aGUga25vd2xlZGdlIGJhc2UuIFdoZW4gc2V0IHRvIHRydWUsIGFueSBkb2N1
bWVudHMKIGluIHRoZSBrbm93bGVkZ2UgYmFzZSBhcmUgYWxzbyBkZWxldGVkLgoKDQoFBAUC
AQUSBJACAgYKDQoFBAUCAQESBJACBwwKDQoFBAUCAQMSBJACDxAKDQoFBAUCAQgSBJACETkK
EAoIBAUCAQicCAASBJACEjgKjwEKAgQGEgaVAgCeAgEagAEgUmVxdWVzdCBtZXNzYWdlIGZv
cgogW0tub3dsZWRnZUJhc2VzLlVwZGF0ZUtub3dsZWRnZUJhc2VdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuS25vd2xlZGdlQmFzZXMuVXBkYXRlS25vd2xlZGdlQmFzZV0u
CgoLCgMEBgESBJUCCCIKNwoEBAYCABIElwICTBopIFJlcXVpcmVkLiBUaGUga25vd2xlZGdl
IGJhc2UgdG8gdXBkYXRlLgoKDQoFBAYCAAYSBJcCAg8KDQoFBAYCAAESBJcCEB4KDQoFBAYC
AAMSBJcCISIKDQoFBAYCAAgSBJcCI0sKEAoIBAYCAAicCAASBJcCJEoKugEKBAQGAgESBpwC
Ap0CLxqpASBPcHRpb25hbC4gTm90IHNwZWNpZmllZCBtZWFucyBgdXBkYXRlIGFsbGAuCiBD
dXJyZW50bHksIG9ubHkgYGRpc3BsYXlfbmFtZWAgY2FuIGJlIHVwZGF0ZWQsIGFuIEludmFs
aWRBcmd1bWVudCB3aWxsIGJlCiByZXR1cm5lZCBmb3IgYXR0ZW1wdGluZyB0byB1cGRhdGUg
b3RoZXIgZmllbGRzLgoKDQoFBAYCAQYSBJwCAhsKDQoFBAYCAQESBJwCHCcKDQoFBAYCAQMS
BJwCKisKDQoFBAYCAQgSBJ0CBi4KEAoIBAYCAQicCAASBJ0CBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase ===
    # Fields for KnowledgeBase
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest ===
    # Fields for ListKnowledgeBasesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse ===
    # Fields for ListKnowledgeBasesResponse
    # Field: knowledge_bases Type: 11 (.google.cloud.dialogflow.v2beta1.KnowledgeBase)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest ===
    # Fields for GetKnowledgeBaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest ===
    # Fields for CreateKnowledgeBaseRequest
    # Field: parent Type: 9 ()
    # Field: knowledge_base Type: 11 (.google.cloud.dialogflow.v2beta1.KnowledgeBase)

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest ===
    # Fields for DeleteKnowledgeBaseRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest ===
    # Fields for UpdateKnowledgeBaseRequest
    # Field: knowledge_base Type: 11 (.google.cloud.dialogflow.v2beta1.KnowledgeBase)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBasesClient ===
package Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBasesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBasesClient

Client stub representing the remote C<KnowledgeBases> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_knowledge_bases {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'ListKnowledgeBases',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse',
    });
}

sub get_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'GetKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase',
    });
}

sub create_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'CreateKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase',
    });
}

sub delete_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'DeleteKnowledgeBase',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'UpdateKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::KnowledgeBase - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/knowledge_base.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::KnowledgeBase;

    my $msg = Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase->new({
        name => $name,
        display_name => $display_name,
        language_code => $language_code,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/knowledge_base.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase

A knowledge base represents a collection of knowledge documents that you
provide to Dialogflow. Your knowledge documents contain information that may
be useful during conversations with end-users. Some Dialogflow features use
knowledge bases when looking for a response to an end-user input.

For more information, see the [knowledge base
guide](https://cloud.google.com/dialogflow/docs/how/knowledge-bases).

Note: The `projects.agent.knowledgeBases` resource is deprecated;
only use `projects.knowledgeBases`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The knowledge base resource name.
The name must be empty when creating a knowledge base.
Format: `projects/<Project ID>/locations/<Location
ID>/knowledgeBases/<Knowledge Base ID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the knowledge base. The name must be 1024
bytes or less; otherwise, the creation request fails.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Language which represents the KnowledgeBase. When the KnowledgeBase is
created/updated, this is populated for all non en-us languages. If not
populated, the default language en-us applies.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest

Request message for
[KnowledgeBases.ListKnowledgeBases][google.cloud.dialogflow.v2beta1.KnowledgeBases.ListKnowledgeBases].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to list of knowledge bases for.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By
default 10 and at most 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter expression used to filter knowledge bases returned by the list
method. The expression has the following syntax:

  <field> <operator> <value> [AND <field> <operator> <value>] ...

The following fields and operators are supported:

* display_name with has(:) operator
* language_code with equals(=) operator

Examples:

* 'language_code=en-us' matches knowledge bases with en-us language code.
* 'display_name:articles' matches knowledge bases whose display name
  contains "articles".
* 'display_name:"Best Articles"' matches knowledge bases whose display
  name contains "Best Articles".
* 'language_code=en-gb AND display_name=articles' matches all knowledge
  bases whose display name contains "articles" and whose language code is
  "en-gb".

Note: An empty filter string (i.e. "") is a no-op and will result in no
filtering.

For more information about filtering, see
[API Filtering](https://aip.dev/160).

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse

Response message for
[KnowledgeBases.ListKnowledgeBases][google.cloud.dialogflow.v2beta1.KnowledgeBases.ListKnowledgeBases].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->knowledge_bases() >> / C<< $msg->knowledge_bases($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase>)

The list of knowledge bases.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest

Request message for
[KnowledgeBases.GetKnowledgeBase][google.cloud.dialogflow.v2beta1.KnowledgeBases.GetKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the knowledge base to retrieve.
Format `projects/<Project ID>/locations/<Location
ID>/knowledgeBases/<Knowledge Base ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest

Request message for
[KnowledgeBases.CreateKnowledgeBase][google.cloud.dialogflow.v2beta1.KnowledgeBases.CreateKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to create a knowledge base for.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->knowledge_base() >> / C<< $msg->knowledge_base($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase>)

Required. The knowledge base to create.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest

Request message for
[KnowledgeBases.DeleteKnowledgeBase][google.cloud.dialogflow.v2beta1.KnowledgeBases.DeleteKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the knowledge base to delete.
Format: `projects/<Project ID>/locations/<Location
ID>/knowledgeBases/<Knowledge Base ID>`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. Force deletes the knowledge base. When set to true, any documents
in the knowledge base are also deleted.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest

Request message for
[KnowledgeBases.UpdateKnowledgeBase][google.cloud.dialogflow.v2beta1.KnowledgeBases.UpdateKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->knowledge_base() >> / C<< $msg->knowledge_base($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase>)

Required. The knowledge base to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Not specified means `update all`.
Currently, only `display_name` can be updated, an InvalidArgument will be
returned for attempting to update other fields.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
