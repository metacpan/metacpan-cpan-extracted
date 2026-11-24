package Google::Cloud::Dialogflow::V2::KnowledgeBase;

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
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9rbm93bGVkZ2VfYmFzZS5wcm90bxIaZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIp0CCg1Lbm93bGVkZ2VC
YXNlEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rp
c3BsYXlOYW1lEiMKDWxhbmd1YWdlX2NvZGUYBCABKAlSDGxhbmd1YWdlQ29kZTqqAepBpgEK
J2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vS25vd2xlZGdlQmFzZRIycHJvamVjdHMve3By
b2plY3R9L2tub3dsZWRnZUJhc2VzL3trbm93bGVkZ2VfYmFzZX0SR3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rbm93bGVkZ2VCYXNlcy97a25vd2xlZGdlX2Jh
c2V9IrgBChlMaXN0S25vd2xlZGdlQmFzZXNSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC
+kEpEidkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0tub3dsZWRnZUJhc2VSBnBhcmVudBIb
CglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VU
b2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlciKYAQoaTGlzdEtub3dsZWRnZUJhc2VzUmVz
cG9uc2USUgoPa25vd2xlZGdlX2Jhc2VzGAEgAygLMikuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjIuS25vd2xlZGdlQmFzZVIOa25vd2xlZGdlQmFzZXMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuIl4KF0dldEtub3dsZWRnZUJhc2VSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Lbm93bGVkZ2VC
YXNlUgRuYW1lIrwBChpDcmVhdGVLbm93bGVkZ2VCYXNlUmVxdWVzdBJHCgZwYXJlbnQYASAB
KAlCL+BBAvpBKRInZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Lbm93bGVkZ2VCYXNlUgZw
YXJlbnQSVQoOa25vd2xlZGdlX2Jhc2UYAiABKAsyKS5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5Lbm93bGVkZ2VCYXNlQgPgQQJSDWtub3dsZWRnZUJhc2UifAoaRGVsZXRlS25vd2xl
ZGdlQmFzZVJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidkaWFsb2dmbG93Lmdvb2ds
ZWFwaXMuY29tL0tub3dsZWRnZUJhc2VSBG5hbWUSGQoFZm9yY2UYAiABKAhCA+BBAVIFZm9y
Y2UitQEKGlVwZGF0ZUtub3dsZWRnZUJhc2VSZXF1ZXN0ElUKDmtub3dsZWRnZV9iYXNlGAEg
ASgLMikuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuS25vd2xlZGdlQmFzZUID4EECUg1r
bm93bGVkZ2VCYXNlEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrMrQNCg5Lbm93bGVkZ2VCYXNlcxKkAgoSTGlzdEtu
b3dsZWRnZUJhc2VzEjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuTGlzdEtub3dsZWRn
ZUJhc2VzUmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkxpc3RLbm93bGVk
Z2VCYXNlc1Jlc3BvbnNlIp4BgtPkkwKOARImL3YyL3twYXJlbnQ9cHJvamVjdHMvKn0va25v
d2xlZGdlQmFzZXNaNBIyL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0va25v
d2xlZGdlQmFzZXNaLhIsL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9hZ2VudH0va25vd2xlZGdl
QmFzZXPaQQZwYXJlbnQSkQIKEEdldEtub3dsZWRnZUJhc2USMy5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5HZXRLbm93bGVkZ2VCYXNlUmVxdWVzdBopLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLktub3dsZWRnZUJhc2UinAGC0+STAo4BEiYvdjIve25hbWU9cHJvamVjdHMv
Ki9rbm93bGVkZ2VCYXNlcy8qfVo0EjIvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9rbm93bGVkZ2VCYXNlcy8qfVouEiwvdjIve25hbWU9cHJvamVjdHMvKi9hZ2VudC9rbm93
bGVkZ2VCYXNlcy8qfdpBBG5hbWUS2AIKE0NyZWF0ZUtub3dsZWRnZUJhc2USNi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5DcmVhdGVLbm93bGVkZ2VCYXNlUmVxdWVzdBopLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLktub3dsZWRnZUJhc2Ui3QGC0+STAr4BIiYvdjIve3Bh
cmVudD1wcm9qZWN0cy8qfS9rbm93bGVkZ2VCYXNlczoOa25vd2xlZGdlX2Jhc2VaRCIyL3Yy
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0va25vd2xlZGdlQmFzZXM6Dmtub3ds
ZWRnZV9iYXNlWj4iLC92Mi97cGFyZW50PXByb2plY3RzLyovYWdlbnR9L2tub3dsZWRnZUJh
c2VzOg5rbm93bGVkZ2VfYmFzZdpBFXBhcmVudCxrbm93bGVkZ2VfYmFzZRKEAgoTRGVsZXRl
S25vd2xlZGdlQmFzZRI2Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkRlbGV0ZUtub3ds
ZWRnZUJhc2VSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IpwBgtPkkwKOASomL3Yy
L3tuYW1lPXByb2plY3RzLyova25vd2xlZGdlQmFzZXMvKn1aNCoyL3YyL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyova25vd2xlZGdlQmFzZXMvKn1aLiosL3YyL3tuYW1lPXByb2pl
Y3RzLyovYWdlbnQva25vd2xlZGdlQmFzZXMvKn3aQQRuYW1lEooDChNVcGRhdGVLbm93bGVk
Z2VCYXNlEjYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVXBkYXRlS25vd2xlZGdlQmFz
ZVJlcXVlc3QaKS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Lbm93bGVkZ2VCYXNlIo8C
gtPkkwLrATI1L3YyL3trbm93bGVkZ2VfYmFzZS5uYW1lPXByb2plY3RzLyova25vd2xlZGdl
QmFzZXMvKn06Dmtub3dsZWRnZV9iYXNlWlMyQS92Mi97a25vd2xlZGdlX2Jhc2UubmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2tub3dsZWRnZUJhc2VzLyp9Og5rbm93bGVkZ2VfYmFz
ZVpNMjsvdjIve2tub3dsZWRnZV9iYXNlLm5hbWU9cHJvamVjdHMvKi9hZ2VudC9rbm93bGVk
Z2VCYXNlcy8qfToOa25vd2xlZGdlX2Jhc2XaQRprbm93bGVkZ2VfYmFzZSx1cGRhdGVfbWFz
axp4ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaWFsb2dmbG93QpgBCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCEktu
b3dsZWRnZUJhc2VQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBp
djIvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29vZ2xlLkNsb3VkLkRpYWxv
Z2Zsb3cuVjJK/TgKBxIFDgCOAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgAlCgkKAgMFEgMXACoKCAoBCBIDGQA3CgkKAgglEgMZADcKCAoBCBIDGgBV
CgkKAggLEgMaAFUKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAzCgkKAggIEgMcADMK
CAoBCBIDHQA3CgkKAggBEgMdADcKCAoBCBIDHgAgCgkKAggkEgMeACAKXwoCBgASBCIAdQEa
UyBTZXJ2aWNlIGZvciBtYW5hZ2luZwogW0tub3dsZWRnZUJhc2VzXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5Lbm93bGVkZ2VCYXNlXS4KCgoKAwYAARIDIggWCgoKAwYAAxIDIwJB
CgwKBQYAA5kIEgMjAkEKCwoDBgADEgQkAiYzCg0KBQYAA5oIEgQkAiYzCk8KBAYAAgASBCkC
NQMaQSBSZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCBrbm93bGVkZ2UgYmFzZXMgb2YgdGhlIHNw
ZWNpZmllZCBhZ2VudC4KCgwKBQYAAgABEgMpBhgKDAoFBgACAAISAykZMgoMCgUGAAIAAxID
Kg8pCg0KBQYAAgAEEgQrBDMGChEKCQYAAgAEsMq8IhIEKwQzBgoMCgUGAAIABBIDNAQ0Cg8K
CAYAAgAEmwgAEgM0BDQKNwoEBgACARIEOAJDAxopIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVk
IGtub3dsZWRnZSBiYXNlLgoKDAoFBgACAQESAzgGFgoMCgUGAAIBAhIDOBcuCgwKBQYAAgED
EgM4OUYKDQoFBgACAQQSBDkEQQYKEQoJBgACAQSwyrwiEgQ5BEEGCgwKBQYAAgEEEgNCBDIK
DwoIBgACAQSbCAASA0IEMgopCgQGAAICEgRGAlQDGhsgQ3JlYXRlcyBhIGtub3dsZWRnZSBi
YXNlLgoKDAoFBgACAgESA0YGGQoMCgUGAAICAhIDRho0CgwKBQYAAgIDEgNGP0wKDQoFBgAC
AgQSBEcEUgYKEQoJBgACAgSwyrwiEgRHBFIGCgwKBQYAAgIEEgNTBEMKDwoIBgACAgSbCAAS
A1MEQwo1CgQGAAIDEgRXAmMDGicgRGVsZXRlcyB0aGUgc3BlY2lmaWVkIGtub3dsZWRnZSBi
YXNlLgoKDAoFBgACAwESA1cGGQoMCgUGAAIDAhIDVxo0CgwKBQYAAgMDEgNYDyQKDQoFBgAC
AwQSBFkEYQYKEQoJBgACAwSwyrwiEgRZBGEGCgwKBQYAAgMEEgNiBDIKDwoIBgACAwSbCAAS
A2IEMgo1CgQGAAIEEgRmAnQDGicgVXBkYXRlcyB0aGUgc3BlY2lmaWVkIGtub3dsZWRnZSBi
YXNlLgoKDAoFBgACBAESA2YGGQoMCgUGAAIEAhIDZho0CgwKBQYAAgQDEgNmP0wKDQoFBgAC
BAQSBGcEcgYKEQoJBgACBASwyrwiEgRnBHIGCgwKBQYAAgQEEgNzBEgKDwoIBgACBASbCAAS
A3MESAqXBAoCBAASBoEBAJYBARqIBCBBIGtub3dsZWRnZSBiYXNlIHJlcHJlc2VudHMgYSBj
b2xsZWN0aW9uIG9mIGtub3dsZWRnZSBkb2N1bWVudHMgdGhhdCB5b3UKIHByb3ZpZGUgdG8g
RGlhbG9nZmxvdy4gWW91ciBrbm93bGVkZ2UgZG9jdW1lbnRzIGNvbnRhaW4gaW5mb3JtYXRp
b24gdGhhdCBtYXkKIGJlIHVzZWZ1bCBkdXJpbmcgY29udmVyc2F0aW9ucyB3aXRoIGVuZC11
c2Vycy4gU29tZSBEaWFsb2dmbG93IGZlYXR1cmVzIHVzZQoga25vd2xlZGdlIGJhc2VzIHdo
ZW4gbG9va2luZyBmb3IgYSByZXNwb25zZSB0byBhbiBlbmQtdXNlciBpbnB1dC4KCiBGb3Ig
bW9yZSBpbmZvcm1hdGlvbiwgc2VlIHRoZSBba25vd2xlZGdlIGJhc2UKIGd1aWRlXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9kb2NzL2hvdy9rbm93bGVkZ2UtYmFz
ZXMpLgoKIE5vdGU6IFRoZSBgcHJvamVjdHMuYWdlbnQua25vd2xlZGdlQmFzZXNgIHJlc291
cmNlIGlzIGRlcHJlY2F0ZWQ7CiBvbmx5IHVzZSBgcHJvamVjdHMua25vd2xlZGdlQmFzZXNg
LgoKCwoDBAABEgSBAQgVCg0KAwQABxIGggEChgEECg8KBQQAB50IEgaCAQKGAQQKyAEKBAQA
AgASBIwBAhIauQEgVGhlIGtub3dsZWRnZSBiYXNlIHJlc291cmNlIG5hbWUuCiBUaGUgbmFt
ZSBtdXN0IGJlIGVtcHR5IHdoZW4gY3JlYXRpbmcgYSBrbm93bGVkZ2UgYmFzZS4KIEZvcm1h
dDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiBJRD4va25v
d2xlZGdlQmFzZXMvPEtub3dsZWRnZSBCYXNlIElEPmAuCgoNCgUEAAIABRIEjAECCAoNCgUE
AAIAARIEjAEJDQoNCgUEAAIAAxIEjAEQEQqPAQoEBAACARIEkAECQxqAASBSZXF1aXJlZC4g
VGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUga25vd2xlZGdlIGJhc2UuIFRoZSBuYW1lIG11c3Qg
YmUgMTAyNAogYnl0ZXMgb3IgbGVzczsgb3RoZXJ3aXNlLCB0aGUgY3JlYXRpb24gcmVxdWVz
dCBmYWlscy4KCg0KBQQAAgEFEgSQAQIICg0KBQQAAgEBEgSQAQkVCg0KBQQAAgEDEgSQARgZ
Cg0KBQQAAgEIEgSQARpCChAKCAQAAgEInAgAEgSQARtBCtgBCgQEAAICEgSVAQIbGskBIExh
bmd1YWdlIHdoaWNoIHJlcHJlc2VudHMgdGhlIEtub3dsZWRnZUJhc2UuIFdoZW4gdGhlIEtu
b3dsZWRnZUJhc2UgaXMKIGNyZWF0ZWQvdXBkYXRlZCwgZXhwZWN0IHRoaXMgdG8gYmUgcHJl
c2VudCBmb3Igbm9uIGVuLXVzIGxhbmd1YWdlcy4gV2hlbgogdW5zcGVjaWZpZWQsIHRoZSBk
ZWZhdWx0IGxhbmd1YWdlIGNvZGUgZW4tdXMgYXBwbGllcy4KCg0KBQQAAgIFEgSVAQIICg0K
BQQAAgIBEgSVAQkWCg0KBQQAAgIDEgSVARkaCocBCgIEARIGmgEAxgEBGnkgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW0tub3dsZWRnZUJhc2VzLkxpc3RLbm93bGVkZ2VCYXNlc11bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuS25vd2xlZGdlQmFzZXMuTGlzdEtub3dsZWRnZUJhc2Vz
XS4KCgsKAwQBARIEmgEIIQqBAQoEBAECABIGnQECogEEGnEgUmVxdWlyZWQuIFRoZSBwcm9q
ZWN0IHRvIGxpc3Qgb2Yga25vd2xlZGdlIGJhc2VzIGZvci4KIEZvcm1hdDogYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPmAuCgoNCgUEAQIABRIEnQEC
CAoNCgUEAQIAARIEnQEJDwoNCgUEAQIAAxIEnQESEwoPCgUEAQIACBIGnQEUogEDChAKCAQB
AgAInAgAEgSeAQQqChEKBwQBAgAInwgSBp8BBKEBBQpnCgQEAQIBEgSmAQIWGlkgVGhlIG1h
eGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeQog
ZGVmYXVsdCAxMCBhbmQgYXQgbW9zdCAxMDAuCgoNCgUEAQIBBRIEpgECBwoNCgUEAQIBARIE
pgEIEQoNCgUEAQIBAxIEpgEUFQpQCgQEAQICEgSpAQIYGkIgVGhlIG5leHRfcGFnZV90b2tl
biB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAEC
AgUSBKkBAggKDQoFBAECAgESBKkBCRMKDQoFBAECAgMSBKkBFhcKvAcKBAQBAgMSBMUBAhQa
rQcgVGhlIGZpbHRlciBleHByZXNzaW9uIHVzZWQgdG8gZmlsdGVyIGtub3dsZWRnZSBiYXNl
cyByZXR1cm5lZCBieSB0aGUgbGlzdAogbWV0aG9kLiBUaGUgZXhwcmVzc2lvbiBoYXMgdGhl
IGZvbGxvd2luZyBzeW50YXg6CgogICA8ZmllbGQ+IDxvcGVyYXRvcj4gPHZhbHVlPiBbQU5E
IDxmaWVsZD4gPG9wZXJhdG9yPiA8dmFsdWU+XSAuLi4KCiBUaGUgZm9sbG93aW5nIGZpZWxk
cyBhbmQgb3BlcmF0b3JzIGFyZSBzdXBwb3J0ZWQ6CgogKiBkaXNwbGF5X25hbWUgd2l0aCBo
YXMoOikgb3BlcmF0b3IKICogbGFuZ3VhZ2VfY29kZSB3aXRoIGVxdWFscyg9KSBvcGVyYXRv
cgoKIEV4YW1wbGVzOgoKICogJ2xhbmd1YWdlX2NvZGU9ZW4tdXMnIG1hdGNoZXMga25vd2xl
ZGdlIGJhc2VzIHdpdGggZW4tdXMgbGFuZ3VhZ2UgY29kZS4KICogJ2Rpc3BsYXlfbmFtZTph
cnRpY2xlcycgbWF0Y2hlcyBrbm93bGVkZ2UgYmFzZXMgd2hvc2UgZGlzcGxheSBuYW1lCiAg
IGNvbnRhaW5zICJhcnRpY2xlcyIuCiAqICdkaXNwbGF5X25hbWU6IkJlc3QgQXJ0aWNsZXMi
JyBtYXRjaGVzIGtub3dsZWRnZSBiYXNlcyB3aG9zZSBkaXNwbGF5CiAgIG5hbWUgY29udGFp
bnMgIkJlc3QgQXJ0aWNsZXMiLgogKiAnbGFuZ3VhZ2VfY29kZT1lbi1nYiBBTkQgZGlzcGxh
eV9uYW1lPWFydGljbGVzJyBtYXRjaGVzIGFsbCBrbm93bGVkZ2UKICAgYmFzZXMgd2hvc2Ug
ZGlzcGxheSBuYW1lIGNvbnRhaW5zICJhcnRpY2xlcyIgYW5kIHdob3NlIGxhbmd1YWdlIGNv
ZGUgaXMKICAgImVuLWdiIi4KCiBOb3RlOiBBbiBlbXB0eSBmaWx0ZXIgc3RyaW5nIChpLmUu
ICIiKSBpcyBhIG5vLW9wIGFuZCB3aWxsIHJlc3VsdCBpbiBubwogZmlsdGVyaW5nLgoKIEZv
ciBtb3JlIGluZm9ybWF0aW9uIGFib3V0IGZpbHRlcmluZywgc2VlCiBbQVBJIEZpbHRlcmlu
Z10oaHR0cHM6Ly9haXAuZGV2LzE2MCkuCgoNCgUEAQIDBRIExQECCAoNCgUEAQIDARIExQEJ
DwoNCgUEAQIDAxIExQESEwqIAQoCBAISBsoBANEBARp6IFJlc3BvbnNlIG1lc3NhZ2UgZm9y
CiBbS25vd2xlZGdlQmFzZXMuTGlzdEtub3dsZWRnZUJhc2VzXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5Lbm93bGVkZ2VCYXNlcy5MaXN0S25vd2xlZGdlQmFzZXNdLgoKCwoDBAIB
EgTKAQgiCiwKBAQCAgASBMwBAi0aHiBUaGUgbGlzdCBvZiBrbm93bGVkZ2UgYmFzZXMuCgoN
CgUEAgIABBIEzAECCgoNCgUEAgIABhIEzAELGAoNCgUEAgIAARIEzAEZKAoNCgUEAgIAAxIE
zAErLApvCgQEAgIBEgTQAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBv
ZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0
aGUgbGlzdC4KCg0KBQQCAgEFEgTQAQIICg0KBQQCAgEBEgTQAQkYCg0KBQQCAgEDEgTQARsc
CoMBCgIEAxIG1QEA3wEBGnUgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0tub3dsZWRnZUJhc2Vz
LkdldEtub3dsZWRnZUJhc2VdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLktub3dsZWRn
ZUJhc2VzLkdldEtub3dsZWRnZUJhc2VdLgoKCwoDBAMBEgTVAQgfCqUBCgQEAwIAEgbZAQLe
AQQalAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBrbm93bGVkZ2UgYmFzZSB0byByZXRy
aWV2ZS4KIEZvcm1hdCBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRp
b24KIElEPi9rbm93bGVkZ2VCYXNlcy88S25vd2xlZGdlIEJhc2UgSUQ+YC4KCg0KBQQDAgAF
EgTZAQIICg0KBQQDAgABEgTZAQkNCg0KBQQDAgADEgTZARARCg8KBQQDAgAIEgbZARLeAQMK
EAoIBAMCAAicCAASBNoBBCoKEQoHBAMCAAifCBIG2wEE3QEFCokBCgIEBBIG4wEA7wEBGnsg
UmVxdWVzdCBtZXNzYWdlIGZvcgogW0tub3dsZWRnZUJhc2VzLkNyZWF0ZUtub3dsZWRnZUJh
c2VdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLktub3dsZWRnZUJhc2VzLkNyZWF0ZUtu
b3dsZWRnZUJhc2VdLgoKCwoDBAQBEgTjAQgiCoEBCgQEBAIAEgbmAQLrAQQacSBSZXF1aXJl
ZC4gVGhlIHByb2plY3QgdG8gY3JlYXRlIGEga25vd2xlZGdlIGJhc2UgZm9yLgogRm9ybWF0
OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+YC4KCg0K
BQQEAgAFEgTmAQIICg0KBQQEAgABEgTmAQkPCg0KBQQEAgADEgTmARITCg8KBQQEAgAIEgbm
ARTrAQMKEAoIBAQCAAicCAASBOcBBCoKEQoHBAQCAAifCBIG6AEE6gEFCjcKBAQEAgESBO4B
AkwaKSBSZXF1aXJlZC4gVGhlIGtub3dsZWRnZSBiYXNlIHRvIGNyZWF0ZS4KCg0KBQQEAgEG
EgTuAQIPCg0KBQQEAgEBEgTuARAeCg0KBQQEAgEDEgTuASEiCg0KBQQEAgEIEgTuASNLChAK
CAQEAgEInAgAEgTuASRKCokBCgIEBRIG8wEAgQIBGnsgUmVxdWVzdCBtZXNzYWdlIGZvcgog
W0tub3dsZWRnZUJhc2VzLkRlbGV0ZUtub3dsZWRnZUJhc2VdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLktub3dsZWRnZUJhc2VzLkRlbGV0ZUtub3dsZWRnZUJhc2VdLgoKCwoDBAUB
EgTzAQgiCqQBCgQEBQIAEgb3AQL8AQQakwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBr
bm93bGVkZ2UgYmFzZSB0byBkZWxldGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vbG9jYXRpb25zLzxMb2NhdGlvbgogSUQ+L2tub3dsZWRnZUJhc2VzLzxLbm93bGVkZ2Ug
QmFzZSBJRD5gLgoKDQoFBAUCAAUSBPcBAggKDQoFBAUCAAESBPcBCQ0KDQoFBAUCAAMSBPcB
EBEKDwoFBAUCAAgSBvcBEvwBAwoQCggEBQIACJwIABIE+AEEKgoRCgcEBQIACJ8IEgb5AQT7
AQUKhAEKBAQFAgESBIACAjoadiBPcHRpb25hbC4gRm9yY2UgZGVsZXRlcyB0aGUga25vd2xl
ZGdlIGJhc2UuIFdoZW4gc2V0IHRvIHRydWUsIGFueSBkb2N1bWVudHMKIGluIHRoZSBrbm93
bGVkZ2UgYmFzZSBhcmUgYWxzbyBkZWxldGVkLgoKDQoFBAUCAQUSBIACAgYKDQoFBAUCAQES
BIACBwwKDQoFBAUCAQMSBIACDxAKDQoFBAUCAQgSBIACETkKEAoIBAUCAQicCAASBIACEjgK
iQEKAgQGEgaFAgCOAgEaeyBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbS25vd2xlZGdlQmFzZXMu
VXBkYXRlS25vd2xlZGdlQmFzZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuS25vd2xl
ZGdlQmFzZXMuVXBkYXRlS25vd2xlZGdlQmFzZV0uCgoLCgMEBgESBIUCCCIKNwoEBAYCABIE
hwICTBopIFJlcXVpcmVkLiBUaGUga25vd2xlZGdlIGJhc2UgdG8gdXBkYXRlLgoKDQoFBAYC
AAYSBIcCAg8KDQoFBAYCAAESBIcCEB4KDQoFBAYCAAMSBIcCISIKDQoFBAYCAAgSBIcCI0sK
EAoIBAYCAAicCAASBIcCJEoKugEKBAQGAgESBowCAo0CLxqpASBPcHRpb25hbC4gTm90IHNw
ZWNpZmllZCBtZWFucyBgdXBkYXRlIGFsbGAuCiBDdXJyZW50bHksIG9ubHkgYGRpc3BsYXlf
bmFtZWAgY2FuIGJlIHVwZGF0ZWQsIGFuIEludmFsaWRBcmd1bWVudCB3aWxsIGJlCiByZXR1
cm5lZCBmb3IgYXR0ZW1wdGluZyB0byB1cGRhdGUgb3RoZXIgZmllbGRzLgoKDQoFBAYCAQYS
BIwCAhsKDQoFBAYCAQESBIwCHCcKDQoFBAYCAQMSBIwCKisKDQoFBAYCAQgSBI0CBi4KEAoI
BAYCAQicCAASBI0CBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase ===
    # Fields for KnowledgeBase
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesRequest ===
    # Fields for ListKnowledgeBasesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse ===
    # Fields for ListKnowledgeBasesResponse
    # Field: knowledge_bases Type: 11 (.google.cloud.dialogflow.v2.KnowledgeBase)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::GetKnowledgeBaseRequest ===
    # Fields for GetKnowledgeBaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::CreateKnowledgeBaseRequest ===
    # Fields for CreateKnowledgeBaseRequest
    # Field: parent Type: 9 ()
    # Field: knowledge_base Type: 11 (.google.cloud.dialogflow.v2.KnowledgeBase)

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::DeleteKnowledgeBaseRequest ===
    # Fields for DeleteKnowledgeBaseRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2::KnowledgeBase::UpdateKnowledgeBaseRequest ===
    # Fields for UpdateKnowledgeBaseRequest
    # Field: knowledge_base Type: 11 (.google.cloud.dialogflow.v2.KnowledgeBase)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBasesClient ===
package Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBasesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBasesClient

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
        ? Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.KnowledgeBases',
        method         => 'ListKnowledgeBases',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse',
    });
}

sub get_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::KnowledgeBase::GetKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.KnowledgeBases',
        method         => 'GetKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase',
    });
}

sub create_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::KnowledgeBase::CreateKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.KnowledgeBases',
        method         => 'CreateKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase',
    });
}

sub delete_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::KnowledgeBase::DeleteKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.KnowledgeBases',
        method         => 'DeleteKnowledgeBase',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_knowledge_base {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::KnowledgeBase::UpdateKnowledgeBaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.KnowledgeBases',
        method         => 'UpdateKnowledgeBase',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::KnowledgeBase - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/knowledge_base.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::KnowledgeBase;

    my $msg = Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase->new({
        name => $name,
        display_name => $display_name,
        language_code => $language_code,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/knowledge_base.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase

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
created/updated, expect this to be present for non en-us languages. When
unspecified, the default language code en-us applies.

=back

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesRequest

Request message for
[KnowledgeBases.ListKnowledgeBases][google.cloud.dialogflow.v2.KnowledgeBases.ListKnowledgeBases].

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

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse

Response message for
[KnowledgeBases.ListKnowledgeBases][google.cloud.dialogflow.v2.KnowledgeBases.ListKnowledgeBases].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->knowledge_bases() >> / C<< $msg->knowledge_bases($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase>)

The list of knowledge bases.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::GetKnowledgeBaseRequest

Request message for
[KnowledgeBases.GetKnowledgeBase][google.cloud.dialogflow.v2.KnowledgeBases.GetKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the knowledge base to retrieve.
Format `projects/<Project ID>/locations/<Location
ID>/knowledgeBases/<Knowledge Base ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::CreateKnowledgeBaseRequest

Request message for
[KnowledgeBases.CreateKnowledgeBase][google.cloud.dialogflow.v2.KnowledgeBases.CreateKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to create a knowledge base for.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->knowledge_base() >> / C<< $msg->knowledge_base($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase>)

Required. The knowledge base to create.

=back

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::DeleteKnowledgeBaseRequest

Request message for
[KnowledgeBases.DeleteKnowledgeBase][google.cloud.dialogflow.v2.KnowledgeBases.DeleteKnowledgeBase].

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

=head2 Google::Cloud::Dialogflow::V2::KnowledgeBase::UpdateKnowledgeBaseRequest

Request message for
[KnowledgeBases.UpdateKnowledgeBase][google.cloud.dialogflow.v2.KnowledgeBases.UpdateKnowledgeBase].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->knowledge_base() >> / C<< $msg->knowledge_base($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase>)

Required. The knowledge base to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Not specified means `update all`.
Currently, only `display_name` can be updated, an InvalidArgument will be
returned for attempting to update other fields.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::KnowledgeBase::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
