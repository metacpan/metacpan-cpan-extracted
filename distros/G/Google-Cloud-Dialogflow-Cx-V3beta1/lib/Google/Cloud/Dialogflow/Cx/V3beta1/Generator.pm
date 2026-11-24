package Google::Cloud::Dialogflow::Cx::V3beta1::Generator;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2dlbmVyYXRvci5wcm90bxIi
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aPGdvb2dsZS9jbG91
ZC9kaWFsb2dmbG93L2N4L3YzYmV0YTEvZ2VuZXJhdGl2ZV9zZXR0aW5ncy5wcm90bxobZ29v
Z2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90byLKBgoJR2VuZXJhdG9yEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1l
GAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lElAKC3Byb21wdF90ZXh0GAMgASgLMiouZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QaHJhc2VCA+BBAlIKcHJvbXB0VGV4dBJi
CgxwbGFjZWhvbGRlcnMYBSADKAsyOS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLkdlbmVyYXRvci5QbGFjZWhvbGRlckID4EEBUgxwbGFjZWhvbGRlcnMSYgoSbGxtX21v
ZGVsX3NldHRpbmdzGAkgASgLMjQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MS5MbG1Nb2RlbFNldHRpbmdzUhBsbG1Nb2RlbFNldHRpbmdzEmUKD21vZGVsX3BhcmFtZXRl
chgIIAEoCzI8Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2VuZXJhdG9y
Lk1vZGVsUGFyYW1ldGVyUg5tb2RlbFBhcmFtZXRlchoxCgtQbGFjZWhvbGRlchIOCgJpZBgB
IAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRrTAQoOTW9kZWxQYXJhbWV0ZXISJQoLdGVt
cGVyYXR1cmUYASABKAJIAFILdGVtcGVyYXR1cmWIAQESLQoQbWF4X2RlY29kZV9zdGVwcxgC
IAEoBUgBUg5tYXhEZWNvZGVTdGVwc4gBARIYCgV0b3BfcBgDIAEoAkgCUgR0b3BQiAEBEhgK
BXRvcF9rGAQgASgFSANSBHRvcEuIAQFCDgoMX3RlbXBlcmF0dXJlQhMKEV9tYXhfZGVjb2Rl
X3N0ZXBzQggKBl90b3BfcEIICgZfdG9wX2s6d+pBdAojZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9HZW5lcmF0b3ISTXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hZ2VudHMve2FnZW50fS9nZW5lcmF0b3JzL3tnZW5lcmF0b3J9IiEKBlBocmFzZRIXCgR0
ZXh0GAEgASgJQgPgQQJSBHRleHQivQEKFUxpc3RHZW5lcmF0b3JzUmVxdWVzdBJDCgZwYXJl
bnQYASABKAlCK+BBAvpBJRIjZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9HZW5lcmF0b3JS
BnBhcmVudBIjCg1sYW5ndWFnZV9jb2RlGAIgASgJUgxsYW5ndWFnZUNvZGUSGwoJcGFnZV9z
aXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4ijwEK
Fkxpc3RHZW5lcmF0b3JzUmVzcG9uc2USTQoKZ2VuZXJhdG9ycxgBIAMoCzItLmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2VuZXJhdG9yUgpnZW5lcmF0b3JzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJ7ChNHZXRHZW5lcmF0b3JSZXF1
ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpBJQojZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9H
ZW5lcmF0b3JSBG5hbWUSIwoNbGFuZ3VhZ2VfY29kZRgCIAEoCVIMbGFuZ3VhZ2VDb2RlItQB
ChZDcmVhdGVHZW5lcmF0b3JSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElEiNkaWFs
b2dmbG93Lmdvb2dsZWFwaXMuY29tL0dlbmVyYXRvclIGcGFyZW50ElAKCWdlbmVyYXRvchgC
IAEoCzItLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2VuZXJhdG9yQgPg
QQJSCWdlbmVyYXRvchIjCg1sYW5ndWFnZV9jb2RlGAMgASgJUgxsYW5ndWFnZUNvZGUizAEK
FlVwZGF0ZUdlbmVyYXRvclJlcXVlc3QSUAoJZ2VuZXJhdG9yGAEgASgLMi0uZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5HZW5lcmF0b3JCA+BBAlIJZ2VuZXJhdG9yEiMK
DWxhbmd1YWdlX2NvZGUYAiABKAlSDGxhbmd1YWdlQ29kZRI7Cgt1cGRhdGVfbWFzaxgDIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sibwoWRGVsZXRlR2Vu
ZXJhdG9yUmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI2RpYWxvZ2Zsb3cuZ29vZ2xl
YXBpcy5jb20vR2VuZXJhdG9yUgRuYW1lEhQKBWZvcmNlGAIgASgIUgVmb3JjZTKvCQoKR2Vu
ZXJhdG9ycxLWAQoOTGlzdEdlbmVyYXRvcnMSOS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLkxpc3RHZW5lcmF0b3JzUmVxdWVzdBo6Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuTGlzdEdlbmVyYXRvcnNSZXNwb25zZSJNgtPkkwI+EjwvdjNiZXRh
MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyp9L2dlbmVyYXRvcnPa
QQZwYXJlbnQSwwEKDEdldEdlbmVyYXRvchI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuR2V0R2VuZXJhdG9yUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuR2VuZXJhdG9yIkuC0+STAj4SPC92M2JldGExL3tuYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovYWdlbnRzLyovZ2VuZXJhdG9ycy8qfdpBBG5hbWUS4AEKD0NyZWF0
ZUdlbmVyYXRvchI6Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuQ3JlYXRl
R2VuZXJhdG9yUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEu
R2VuZXJhdG9yImKC0+STAkkiPC92M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudHMvKn0vZ2VuZXJhdG9yczoJZ2VuZXJhdG9y2kEQcGFyZW50LGdlbmVyYXRv
chLvAQoPVXBkYXRlR2VuZXJhdG9yEjouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5VcGRhdGVHZW5lcmF0b3JSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5HZW5lcmF0b3IicYLT5JMCUzJGL3YzYmV0YTEve2dlbmVyYXRvci5uYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZ2VuZXJhdG9ycy8qfToJZ2VuZXJh
dG9y2kEVZ2VuZXJhdG9yLHVwZGF0ZV9tYXNrErIBCg9EZWxldGVHZW5lcmF0b3ISOi5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkRlbGV0ZUdlbmVyYXRvclJlcXVlc3Qa
Fi5nb29nbGUucHJvdG9idWYuRW1wdHkiS4LT5JMCPio8L3YzYmV0YTEve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9nZW5lcmF0b3JzLyp92kEEbmFtZRp4ykEZZGlh
bG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFs
b2dmbG93QsUBCiZjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMUIOR2Vu
ZXJhdG9yUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYz
YmV0YTEvY3hwYjtjeHBiogICREaqAiJHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM0Jl
dGEx6gImR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYzYmV0YTFKz0YKBxIFDgCS
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBGCgkKAgMF
EgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAD8KCQoCCCUSAxoAPwoICgEIEgMbAE0KCQoCCAsS
AxsATQoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdAC8KCQoCCAgSAx0ALwoICgEIEgMe
AD8KCQoCCAESAx4APwoICgEIEgMfACAKCQoCCCQSAx8AIAoICgEIEgMgAD8KCQoCCC0SAyAA
PwpeCgIGABIEJABTARpSIFNlcnZpY2UgZm9yIG1hbmFnaW5nCiBbR2VuZXJhdG9yc11bZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5HZW5lcmF0b3JdCgoKCgMGAAESAyQI
EgoKCgMGAAMSAyUCQQoMCgUGAAOZCBIDJQJBCgsKAwYAAxIEJgIoMwoNCgUGAAOaCBIEJgIo
MwpKCgQGAAIAEgQrAjADGjwgUmV0dXJucyB0aGUgbGlzdCBvZiBhbGwgZ2VuZXJhdG9ycyBp
biB0aGUgc3BlY2lmaWVkIGFnZW50LgoKDAoFBgACAAESAysGFAoMCgUGAAIAAhIDKxUqCgwK
BQYAAgADEgMrNUsKDQoFBgACAAQSBCwELgYKEQoJBgACAASwyrwiEgQsBC4GCgwKBQYAAgAE
EgMvBDQKDwoIBgACAASbCAASAy8ENAoyCgQGAAIBEgQzAjgDGiQgUmV0cmlldmVzIHRoZSBz
cGVjaWZpZWQgZ2VuZXJhdG9yLgoKDAoFBgACAQESAzMGEgoMCgUGAAIBAhIDMxMmCgwKBQYA
AgEDEgMzMToKDQoFBgACAQQSBDQENgYKEQoJBgACAQSwyrwiEgQ0BDYGCgwKBQYAAgEEEgM3
BDIKDwoIBgACAQSbCAASAzcEMgo7CgQGAAICEgQ7AkEDGi0gQ3JlYXRlcyBhIGdlbmVyYXRv
ciBpbiB0aGUgc3BlY2lmaWVkIGFnZW50LgoKDAoFBgACAgESAzsGFQoMCgUGAAICAhIDOxYs
CgwKBQYAAgIDEgM7N0AKDQoFBgACAgQSBDwEPwYKEQoJBgACAgSwyrwiEgQ8BD8GCgwKBQYA
AgIEEgNABD4KDwoIBgACAgSbCAASA0AEPgovCgQGAAIDEgREAkoDGiEgVXBkYXRlIHRoZSBz
cGVjaWZpZWQgZ2VuZXJhdG9yLgoKDAoFBgACAwESA0QGFQoMCgUGAAIDAhIDRBYsCgwKBQYA
AgMDEgNEN0AKDQoFBgACAwQSBEUESAYKEQoJBgACAwSwyrwiEgRFBEgGCgwKBQYAAgMEEgNJ
BEMKDwoIBgACAwSbCAASA0kEQwoxCgQGAAIEEgRNAlIDGiMgRGVsZXRlcyB0aGUgc3BlY2lm
aWVkIGdlbmVyYXRvcnMuCgoMCgUGAAIEARIDTQYVCgwKBQYAAgQCEgNNFiwKDAoFBgACBAMS
A003TAoNCgUGAAIEBBIETgRQBgoRCgkGAAIEBLDKvCISBE4EUAYKDAoFBgACBAQSA1EEMgoP
CggGAAIEBJsIABIDUQQyCv4BCgIEABIFWQCdAQEa8AEgR2VuZXJhdG9ycyBjb250YWluIHBy
b21wdCB0byBiZSBzZW50IHRvIHRoZSBMTE0gbW9kZWwgdG8gZ2VuZXJhdGUgdGV4dC4gVGhl
CiBwcm9tcHQgY2FuIGNvbnRhaW4gcGFyYW1ldGVycyB3aGljaCB3aWxsIGJlIHJlc29sdmVk
IGJlZm9yZSBjYWxsaW5nIHRoZQogbW9kZWwuIEl0IGNhbiBvcHRpb25hbGx5IGNvbnRhaW4g
YmFubmVkIHBocmFzZXMgdG8gZW5zdXJlIHRoZSBtb2RlbCByZXNwb25zZXMKIGFyZSBzYWZl
LgoKCgoDBAABEgNZCBEKCwoDBAAHEgRaAl0ECg0KBQQAB50IEgRaAl0ECkMKBAQAAwASBGAC
ZgMaNSBSZXByZXNlbnRzIGEgY3VzdG9tIHBsYWNlaG9sZGVyIGluIHRoZSBwcm9tcHQgdGV4
dC4KCgwKBQQAAwABEgNgChUKVwoGBAADAAIAEgNiBBIaSCBVbmlxdWUgSUQgdXNlZCB0byBt
YXAgY3VzdG9tIHBsYWNlaG9sZGVyIHRvIHBhcmFtZXRlcnMgaW4gZnVsZmlsbG1lbnQuCgoO
CgcEAAMAAgAFEgNiBAoKDgoHBAADAAIAARIDYgsNCg4KBwQAAwACAAMSA2IQEQo9CgYEAAMA
AgESA2UEFBouIEN1c3RvbSBwbGFjZWhvbGRlciB2YWx1ZSBpbiB0aGUgcHJvbXB0IHRleHQu
CgoOCgcEAAMAAgEFEgNlBAoKDgoHBAADAAIBARIDZQsPCg4KBwQAAwACAQMSA2USEwpeCgQE
AAMBEgVqAoEBAxpPIFBhcmFtZXRlcnMgdG8gYmUgcGFzc2VkIHRvIHRoZSBMTE0uIElmIG5v
dCBzZXQsIGRlZmF1bHQgdmFsdWVzIHdpbGwgYmUKIHVzZWQuCgoMCgUEAAMBARIDagoYCtYB
CgYEAAMBAgASA28EIxrGASBUaGUgdGVtcGVyYXR1cmUgdXNlZCBmb3Igc2FtcGxpbmcuIFRl
bXBlcmF0dXJlIHNhbXBsaW5nIG9jY3VycyBhZnRlciBib3RoCiB0b3BQIGFuZCB0b3BLIGhh
dmUgYmVlbiBhcHBsaWVkLgogVmFsaWQgcmFuZ2U6IFswLjAsIDEuMF0KIExvdyB0ZW1wZXJh
dHVyZSA9IGxlc3MgcmFuZG9tLiBIaWdoIHRlbXBlcmF0dXJlID0gbW9yZSByYW5kb20uCgoO
CgcEAAMBAgAEEgNvBAwKDgoHBAADAQIABRIDbw0SCg4KBwQAAwECAAESA28THgoOCgcEAAMB
AgADEgNvISIKOgoGBAADAQIBEgNyBCgaKyBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9rZW5z
IHRvIGdlbmVyYXRlLgoKDgoHBAADAQIBBBIDcgQMCg4KBwQAAwECAQUSA3INEgoOCgcEAAMB
AgEBEgNyEyMKDgoHBAADAQIBAxIDciYnCp4CCgYEAAMBAgISA3oEHRqOAiBJZiBzZXQsIG9u
bHkgdGhlIHRva2VucyBjb21wcmlzaW5nIHRoZSB0b3AgdG9wX3AgcHJvYmFiaWxpdHkgbWFz
cyBhcmUKIGNvbnNpZGVyZWQuIElmIGJvdGggdG9wX3AgYW5kIHRvcF9rIGFyZQogc2V0LCB0
b3BfcCB3aWxsIGJlIHVzZWQgZm9yIGZ1cnRoZXIgcmVmaW5pbmcgY2FuZGlkYXRlcyBzZWxl
Y3RlZCB3aXRoCiB0b3Bfay4KIFZhbGlkIHJhbmdlOiAoMC4wLCAxLjBdLgogU21hbGwgdG9w
UCA9IGxlc3MgcmFuZG9tLiBMYXJnZSB0b3BQID0gbW9yZSByYW5kb20uCgoOCgcEAAMBAgIE
EgN6BAwKDgoHBAADAQICBRIDeg0SCg4KBwQAAwECAgESA3oTGAoOCgcEAAMBAgIDEgN6GxwK
zQEKBgQAAwECAxIEgAEEHRq8ASBJZiBzZXQsIHRoZSBzYW1wbGluZyBwcm9jZXNzIGluIGVh
Y2ggc3RlcCBpcyBsaW1pdGVkIHRvIHRoZSB0b3BfayB0b2tlbnMKIHdpdGggaGlnaGVzdCBw
cm9iYWJpbGl0aWVzLgogVmFsaWQgcmFuZ2U6IFsxLCA0MF0gb3IgMTAwMCsuCiBTbWFsbCB0
b3BLID0gbGVzcyByYW5kb20uIExhcmdlIHRvcEsgPSBtb3JlIHJhbmRvbS4KCg8KBwQAAwEC
AwQSBIABBAwKDwoHBAADAQIDBRIEgAENEgoPCgcEAAMBAgMBEgSAARMYCg8KBwQAAwECAwMS
BIABGxwK1gIKBAQAAgASBIkBAhIaxwIgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBn
ZW5lcmF0b3IuCiBNdXN0IGJlIHNldCBmb3IgdGhlCiBbR2VuZXJhdG9ycy5VcGRhdGVHZW5l
cmF0b3JdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2VuZXJhdG9ycy5V
cGRhdGVHZW5lcmF0b3JdCiBtZXRob2QuIFtHZW5lcmF0b3JzLkNyZWF0ZUdlbmVyYXRlXVtd
IHBvcHVsYXRlcyB0aGUgbmFtZSBhdXRvbWF0aWNhbGx5LgogRm9ybWF0OgogYHByb2plY3Rz
LzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9n
ZW5lcmF0b3JzLzxHZW5lcmF0b3JJRD5gLgoKDQoFBAACAAUSBIkBAggKDQoFBAACAAESBIkB
CQ0KDQoFBAACAAMSBIkBEBEKqQIKBAQAAgESBI8BAkMamgIgUmVxdWlyZWQuIFRoZSBodW1h
bi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBnZW5lcmF0b3IsIHVuaXF1ZSB3aXRoaW4gdGhlCiBh
Z2VudC4gVGhlIHByb21wdCBjb250YWlucyBwcmUtZGVmaW5lZCBwYXJhbWV0ZXJzIHN1Y2gg
YXMgJGNvbnZlcnNhdGlvbiwKICRsYXN0LXVzZXItdXR0ZXJhbmNlLCBldGMuIHBvcHVsYXRl
ZCBieSBEaWFsb2dmbG93LiBJdCBjYW4gYWxzbyBjb250YWluCiBjdXN0b20gcGxhY2Vob2xk
ZXJzIHdoaWNoIHdpbGwgYmUgcmVzb2x2ZWQgZHVyaW5nIGZ1bGZpbGxtZW50LgoKDQoFBAAC
AQUSBI8BAggKDQoFBAACAQESBI8BCRUKDQoFBAACAQMSBI8BGBkKDQoFBAACAQgSBI8BGkIK
EAoIBAACAQicCAASBI8BG0EKMwoEBAACAhIEkgECQholIFJlcXVpcmVkLiBQcm9tcHQgZm9y
IHRoZSBMTE0gbW9kZWwuCgoNCgUEAAICBhIEkgECCAoNCgUEAAICARIEkgEJFAoNCgUEAAIC
AxIEkgEXGAoNCgUEAAICCBIEkgEZQQoQCggEAAICCJwIABIEkgEaQApLCgQEAAIDEgaVAQKW
AS8aOyBPcHRpb25hbC4gTGlzdCBvZiBjdXN0b20gcGxhY2Vob2xkZXJzIGluIHRoZSBwcm9t
cHQgdGV4dC4KCg0KBQQAAgMEEgSVAQIKCg0KBQQAAgMGEgSVAQsWCg0KBQQAAgMBEgSVARcj
Cg0KBQQAAgMDEgSVASYnCg0KBQQAAgMIEgSWAQYuChAKCAQAAgMInAgAEgSWAQctCicKBAQA
AgQSBJkBAioaGSBUaGUgTExNIG1vZGVsIHNldHRpbmdzLgoKDQoFBAACBAYSBJkBAhIKDQoF
BAACBAESBJkBEyUKDQoFBAACBAMSBJkBKCkKRwoEBAACBRIEnAECJRo5IFBhcmFtZXRlcnMg
cGFzc2VkIHRvIHRoZSBMTE0gdG8gY29uZmlndXJlIGl0cyBiZWhhdmlvci4KCg0KBQQAAgUG
EgScAQIQCg0KBQQAAgUBEgScAREgCg0KBQQAAgUDEgScASMkCkoKAgQBEgagAQCjAQEaPCBU
ZXh0IGlucHV0IHdoaWNoIGNhbiBiZSB1c2VkIGZvciBwcm9tcHQgb3IgYmFubmVkIHBocmFz
ZXMuCgoLCgMEAQESBKABCA4KVAoEBAECABIEogECOxpGIFJlcXVpcmVkLiBUZXh0IGlucHV0
IHdoaWNoIGNhbiBiZSB1c2VkIGZvciBwcm9tcHQgb3IgYmFubmVkIHBocmFzZXMuCgoNCgUE
AQIABRIEogECCAoNCgUEAQIAARIEogEJDQoNCgUEAQIAAxIEogEQEQoNCgUEAQIACBIEogES
OgoQCggEAQIACJwIABIEogETOQqDAQoCBAISBqcBALoBARp1IFRoZSByZXF1ZXN0IG1lc3Nh
Z2UgZm9yCiBbR2VuZXJhdG9ycy5MaXN0R2VuZXJhdG9yc11bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjNiZXRhMS5HZW5lcmF0b3JzLkxpc3RHZW5lcmF0b3JzXS4KCgsKAwQCARIE
pwEIHQqKAQoEBAICABIGqgECrwEEGnogUmVxdWlyZWQuIFRoZSBhZ2VudCB0byBsaXN0IGFs
bCBnZW5lcmF0b3JzIGZvci4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPmAuCgoNCgUEAgIABRIEqgECCAoN
CgUEAgIAARIEqgEJDwoNCgUEAgIAAxIEqgESEwoPCgUEAgIACBIGqgEUrwEDChAKCAQCAgAI
nAgAEgSrAQQqChEKBwQCAgAInwgSBqwBBK4BBQo0CgQEAgIBEgSyAQIbGiYgVGhlIGxhbmd1
YWdlIHRvIGxpc3QgZ2VuZXJhdG9ycyBmb3IuCgoNCgUEAgIBBRIEsgECCAoNCgUEAgIBARIE
sgEJFgoNCgUEAgIBAxIEsgEZGgppCgQEAgICEgS2AQIWGlsgVGhlIG1heGltdW0gbnVtYmVy
IG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZhdWx0IDEwMCBh
bmQKIGF0IG1vc3QgMTAwMC4KCg0KBQQCAgIFEgS2AQIHCg0KBQQCAgIBEgS2AQgRCg0KBQQC
AgIDEgS2ARQVClAKBAQCAgMSBLkBAhgaQiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJl
dHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUEAgIDBRIEuQECCAoN
CgUEAgIDARIEuQEJEwoNCgUEAgIDAxIEuQEWFwqEAQoCBAMSBr4BAMYBARp2IFRoZSByZXNw
b25zZSBtZXNzYWdlIGZvcgogW0dlbmVyYXRvcnMuTGlzdEdlbmVyYXRvcnNdW2dvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2VuZXJhdG9ycy5MaXN0R2VuZXJhdG9yc10u
CgoLCgMEAwESBL4BCB4KhgEKBAQDAgASBMEBAiQaeCBUaGUgbGlzdCBvZiBnZW5lcmF0b3Jz
LiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgcmV0dXJuZWQKIGJh
c2VkIG9uIHRoZSBwYWdlX3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3QuCgoNCgUEAwIABBIE
wQECCgoNCgUEAwIABhIEwQELFAoNCgUEAwIAARIEwQEVHwoNCgUEAwIAAxIEwQEiIwpvCgQE
AwIBEgTFAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRz
LCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0aGUgbGlzdC4K
Cg0KBQQDAgEFEgTFAQIICg0KBQQDAgEBEgTFAQkYCg0KBQQDAgEDEgTFARscCn8KAgQEEgbK
AQDXAQEacSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0dlbmVyYXRvcnMuR2V0R2VuZXJh
dG9yXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkdlbmVyYXRvcnMuR2V0
R2VuZXJhdG9yXS4KCgsKAwQEARIEygEIGwqaAQoEBAQCABIGzgEC0wEEGokBIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgZ2VuZXJhdG9yLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9q
ZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9nZW5lcmF0
b3JzLzxHZW5lcmF0b3JJRD5gLgoKDQoFBAQCAAUSBM4BAggKDQoFBAQCAAESBM4BCQ0KDQoF
BAQCAAMSBM4BEBEKDwoFBAQCAAgSBs4BEtMBAwoQCggEBAIACJwIABIEzwEEKgoRCgcEBAIA
CJ8IEgbQAQTSAQUKNAoEBAQCARIE1gECGxomIFRoZSBsYW5ndWFnZSB0byBsaXN0IGdlbmVy
YXRvcnMgZm9yLgoKDQoFBAQCAQUSBNYBAggKDQoFBAQCAQESBNYBCRYKDQoFBAQCAQMSBNYB
GRoKhQEKAgQFEgbbAQDsAQEadyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0dlbmVyYXRv
cnMuQ3JlYXRlR2VuZXJhdG9yXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGEx
LkdlbmVyYXRvcnMuQ3JlYXRlR2VuZXJhdG9yXS4KCgsKAwQFARIE2wEIHgqJAQoEBAUCABIG
3gEC4wEEGnkgUmVxdWlyZWQuIFRoZSBhZ2VudCB0byBjcmVhdGUgYSBnZW5lcmF0b3IgZm9y
LgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklE
Pi9hZ2VudHMvPEFnZW50SUQ+YC4KCg0KBQQFAgAFEgTeAQIICg0KBQQFAgABEgTeAQkPCg0K
BQQFAgADEgTeARITCg8KBQQFAgAIEgbeARTjAQMKEAoIBAUCAAicCAASBN8BBCoKEQoHBAUC
AAifCBIG4AEE4gEFCjIKBAQFAgESBOYBAkMaJCBSZXF1aXJlZC4gVGhlIGdlbmVyYXRvciB0
byBjcmVhdGUuCgoNCgUEBQIBBhIE5gECCwoNCgUEBQIBARIE5gEMFQoNCgUEBQIBAxIE5gEY
GQoNCgUEBQIBCBIE5gEaQgoQCggEBQIBCJwIABIE5gEbQQqmAQoEBAUCAhIE6wECGxqXASBU
aGUgbGFuZ3VhZ2UgdG8gY3JlYXRlIGdlbmVyYXRvcnMgZm9yIHRoZSBmb2xsb3dpbmcgZmll
bGRzOgogKiAgYEdlbmVyYXRvci5wcm9tcHRfdGV4dC50ZXh0YAogSWYgbm90IHNwZWNpZmll
ZCwgdGhlIGFnZW50J3MgZGVmYXVsdCBsYW5ndWFnZSBpcyB1c2VkLgoKDQoFBAUCAgUSBOsB
AggKDQoFBAUCAgESBOsBCRYKDQoFBAUCAgMSBOsBGRoKhQEKAgQGEgbwAQD6AQEadyBUaGUg
cmVxdWVzdCBtZXNzYWdlIGZvcgogW0dlbmVyYXRvcnMuVXBkYXRlR2VuZXJhdG9yXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkdlbmVyYXRvcnMuVXBkYXRlR2VuZXJh
dG9yXS4KCgsKAwQGARIE8AEIHgoyCgQEBgIAEgTyAQJDGiQgUmVxdWlyZWQuIFRoZSBnZW5l
cmF0b3IgdG8gdXBkYXRlLgoKDQoFBAYCAAYSBPIBAgsKDQoFBAYCAAESBPIBDBUKDQoFBAYC
AAMSBPIBGBkKDQoFBAYCAAgSBPIBGkIKEAoIBAYCAAicCAASBPIBG0EKNAoEBAYCARIE9QEC
GxomIFRoZSBsYW5ndWFnZSB0byBsaXN0IGdlbmVyYXRvcnMgZm9yLgoKDQoFBAYCAQUSBPUB
AggKDQoFBAYCAQESBPUBCRYKDQoFBAYCAQMSBPUBGRoKdgoEBAYCAhIE+QECLBpoIFRoZSBt
YXNrIHRvIGNvbnRyb2wgd2hpY2ggZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUgbWFzayBp
cyBub3QgcHJlc2VudCwKIGFsbCBmaWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDQoFBAYCAgYS
BPkBAhsKDQoFBAYCAgESBPkBHCcKDQoFBAYCAgMSBPkBKisKhQEKAgQHEgb+AQCSAgEadyBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0dlbmVyYXRvcnMuRGVsZXRlR2VuZXJhdG9yXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkdlbmVyYXRvcnMuRGVsZXRlR2Vu
ZXJhdG9yXS4KCgsKAwQHARIE/gEIHgqkAQoEBAcCABIGggIChwIEGpMBIFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgZ2VuZXJhdG9yIHRvIGRlbGV0ZS4KIEZvcm1hdDoKIGBwcm9qZWN0
cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4v
Z2VuZXJhdG9ycy88R2VuZXJhdG9ySUQ+YC4KCg0KBQQHAgAFEgSCAgIICg0KBQQHAgABEgSC
AgkNCg0KBQQHAgADEgSCAhARCg8KBQQHAgAIEgaCAhKHAgMKEAoIBAcCAAicCAASBIMCBCoK
EQoHBAcCAAifCBIGhAIEhgIFCrIDCgQEBwIBEgSRAgIRGqMDIFRoaXMgZmllbGQgaGFzIG5v
IGVmZmVjdCBmb3IgZ2VuZXJhdG9ycyBub3QgYmVpbmcgdXNlZC4KIEZvciBnZW5lcmF0b3Jz
IHRoYXQgYXJlIHVzZWQgYnkgcGFnZXMvZmxvd3MvdHJhbnNpdGlvbiByb3V0ZSBncm91cHM6
CgogKiAgSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UsIGFuIGVycm9yIHdpbGwgYmUgcmV0
dXJuZWQgd2l0aCBtZXNzYWdlCiAgICBpbmRpY2F0aW5nIHRoZSByZWZlcmVuY2VkIHJlc291
cmNlcy4KICogIElmIGBmb3JjZWAgaXMgc2V0IHRvIHRydWUsIERpYWxvZ2Zsb3cgd2lsbCBy
ZW1vdmUgdGhlIGdlbmVyYXRvciwgYXMgd2VsbAogICAgYXMgYW55IHJlZmVyZW5jZXMgdG8g
dGhlIGdlbmVyYXRvciAoaS5lLgogICAgW0dlbmVyYXRvcl1bRnVsZmlsbG1lbnQuZ2VuZXJh
dG9yXSkgaW4gZnVsZmlsbG1lbnRzLgoKDQoFBAcCAQUSBJECAgYKDQoFBAcCAQESBJECBwwK
DQoFBAcCAQMSBJECDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator ===
    # Fields for Generator
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: prompt_text Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Phrase)
    # Field: placeholders Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Generator.Placeholder)
    # Field: llm_model_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.LlmModelSettings)
    # Field: model_parameter Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Generator.ModelParameter)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Phrase ===
    # Fields for Phrase
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsRequest ===
    # Fields for ListGeneratorsRequest
    # Field: parent Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsResponse ===
    # Fields for ListGeneratorsResponse
    # Field: generators Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Generator)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GetGeneratorRequest ===
    # Fields for GetGeneratorRequest
    # Field: name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::CreateGeneratorRequest ===
    # Fields for CreateGeneratorRequest
    # Field: parent Type: 9 ()
    # Field: generator Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Generator)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::UpdateGeneratorRequest ===
    # Fields for UpdateGeneratorRequest
    # Field: generator Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Generator)
    # Field: language_code Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::DeleteGeneratorRequest ===
    # Fields for DeleteGeneratorRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GeneratorsClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GeneratorsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GeneratorsClient

Client stub representing the remote C<Generators> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_generators {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'ListGenerators',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsResponse',
    });
}

sub get_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GetGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'GetGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator',
    });
}

sub create_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Generator::CreateGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'CreateGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator',
    });
}

sub update_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Generator::UpdateGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'UpdateGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator',
    });
}

sub delete_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Generator::DeleteGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Generators',
        method         => 'DeleteGenerator',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Generator - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/generator.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Generator;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator->new({
        name => $name,
        display_name => $display_name,
        prompt_text => $prompt_text,
        placeholders => $placeholders,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/generator.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator

Generators contain prompt to be sent to the LLM model to generate text. The
prompt can contain parameters which will be resolved before calling the
model. It can optionally contain banned phrases to ensure the model responses
are safe.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the generator.
Must be set for the
[Generators.UpdateGenerator][google.cloud.dialogflow.cx.v3beta1.Generators.UpdateGenerator]
method. [Generators.CreateGenerate][] populates the name automatically.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the generator, unique within the
agent. The prompt contains pre-defined parameters such as $conversation,
$last-user-utterance, etc. populated by Dialogflow. It can also contain
custom placeholders which will be resolved during fulfillment.

=item * C<< $msg->prompt_text() >> / C<< $msg->prompt_text($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Phrase>)

Required. Prompt for the LLM model.

=item * C<< $msg->placeholders() >> / C<< $msg->placeholders($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator::Placeholder>)

Optional. List of custom placeholders in the prompt text.

=item * C<< $msg->llm_model_settings() >> / C<< $msg->llm_model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings::LlmModelSettings>)

The LLM model settings.

=item * C<< $msg->model_parameter() >> / C<< $msg->model_parameter($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator::ModelParameter>)

Parameters passed to the LLM to configure its behavior.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Phrase

Text input which can be used for prompt or banned phrases.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Text input which can be used for prompt or banned phrases.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsRequest

The request message for
[Generators.ListGenerators][google.cloud.dialogflow.cx.v3beta1.Generators.ListGenerators].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all generators for.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 100 and
at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::ListGeneratorsResponse

The response message for
[Generators.ListGenerators][google.cloud.dialogflow.cx.v3beta1.Generators.ListGenerators].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generators() >> / C<< $msg->generators($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator>)

The list of generators. There will be a maximum number of items returned
based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::GetGeneratorRequest

The request message for
[Generators.GetGenerator][google.cloud.dialogflow.cx.v3beta1.Generators.GetGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the generator.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::CreateGeneratorRequest

The request message for
[Generators.CreateGenerator][google.cloud.dialogflow.cx.v3beta1.Generators.CreateGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create a generator for.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->generator() >> / C<< $msg->generator($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator>)

Required. The generator to create.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to create generators for the following fields:
*  `Generator.prompt_text.text`
If not specified, the agent's default language is used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::UpdateGeneratorRequest

The request message for
[Generators.UpdateGenerator][google.cloud.dialogflow.cx.v3beta1.Generators.UpdateGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generator() >> / C<< $msg->generator($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Generator>)

Required. The generator to update.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The mask to control which fields get updated. If the mask is not present,
all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Generator::DeleteGeneratorRequest

The request message for
[Generators.DeleteGenerator][google.cloud.dialogflow.cx.v3beta1.Generators.DeleteGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the generator to delete.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

This field has no effect for generators not being used.
For generators that are used by pages/flows/transition route groups:

*  If `force` is set to false, an error will be returned with message
   indicating the referenced resources.
*  If `force` is set to true, Dialogflow will remove the generator, as well
   as any references to the generator (i.e.
   [Generator][Fulfillment.generator]) in fulfillments.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Generator::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
