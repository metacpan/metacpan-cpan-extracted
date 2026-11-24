package Google::Monitoring::V3::AlertService;

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
    eval { require Google::Monitoring::V3::Alert };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvbW9uaXRvcmluZy92My9hbGVydF9zZXJ2aWNlLnByb3RvEhRnb29nbGUubW9u
aXRvcmluZy52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9tb25pdG9yaW5nL3YzL2FsZXJ0LnByb3RvGhtn
b29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNr
LnByb3RvIqgBChhDcmVhdGVBbGVydFBvbGljeVJlcXVlc3QSQQoEbmFtZRgDIAEoCUIt4EEC
+kEnEiVtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL0FsZXJ0UG9saWN5UgRuYW1lEkkKDGFs
ZXJ0X3BvbGljeRgCIAEoCzIhLmdvb2dsZS5tb25pdG9yaW5nLnYzLkFsZXJ0UG9saWN5QgPg
QQJSC2FsZXJ0UG9saWN5IloKFUdldEFsZXJ0UG9saWN5UmVxdWVzdBJBCgRuYW1lGAMgASgJ
Qi3gQQL6QScKJW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vQWxlcnRQb2xpY3lSBG5hbWUi
4AEKGExpc3RBbGVydFBvbGljaWVzUmVxdWVzdBJBCgRuYW1lGAQgASgJQi3gQQL6QScSJW1v
bml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vQWxlcnRQb2xpY3lSBG5hbWUSGwoGZmlsdGVyGAUg
ASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgGIAEoCUID4EEBUgdvcmRlckJ5EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbiKsAQoZTGlzdEFsZXJ0UG9saWNpZXNSZXNwb25zZRJICg5hbGVydF9wb2xp
Y2llcxgDIAMoCzIhLmdvb2dsZS5tb25pdG9yaW5nLnYzLkFsZXJ0UG9saWN5Ug1hbGVydFBv
bGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIdCgp0b3Rh
bF9zaXplGAQgASgFUgl0b3RhbFNpemUipwEKGFVwZGF0ZUFsZXJ0UG9saWN5UmVxdWVzdBJA
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIK
dXBkYXRlTWFzaxJJCgxhbGVydF9wb2xpY3kYAyABKAsyIS5nb29nbGUubW9uaXRvcmluZy52
My5BbGVydFBvbGljeUID4EECUgthbGVydFBvbGljeSJdChhEZWxldGVBbGVydFBvbGljeVJl
cXVlc3QSQQoEbmFtZRgDIAEoCUIt4EEC+kEnCiVtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29t
L0FsZXJ0UG9saWN5UgRuYW1lMp4IChJBbGVydFBvbGljeVNlcnZpY2USqAEKEUxpc3RBbGVy
dFBvbGljaWVzEi4uZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdEFsZXJ0UG9saWNpZXNSZXF1
ZXN0Gi8uZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdEFsZXJ0UG9saWNpZXNSZXNwb25zZSIy
gtPkkwIlEiMvdjMve25hbWU9cHJvamVjdHMvKn0vYWxlcnRQb2xpY2llc9pBBG5hbWUSlgEK
DkdldEFsZXJ0UG9saWN5EisuZ29vZ2xlLm1vbml0b3JpbmcudjMuR2V0QWxlcnRQb2xpY3lS
ZXF1ZXN0GiEuZ29vZ2xlLm1vbml0b3JpbmcudjMuQWxlcnRQb2xpY3kiNILT5JMCJxIlL3Yz
L3tuYW1lPXByb2plY3RzLyovYWxlcnRQb2xpY2llcy8qfdpBBG5hbWUStQEKEUNyZWF0ZUFs
ZXJ0UG9saWN5Ei4uZ29vZ2xlLm1vbml0b3JpbmcudjMuQ3JlYXRlQWxlcnRQb2xpY3lSZXF1
ZXN0GiEuZ29vZ2xlLm1vbml0b3JpbmcudjMuQWxlcnRQb2xpY3kiTYLT5JMCMyIjL3YzL3tu
YW1lPXByb2plY3RzLyp9L2FsZXJ0UG9saWNpZXM6DGFsZXJ0X3BvbGljedpBEW5hbWUsYWxl
cnRfcG9saWN5EpEBChFEZWxldGVBbGVydFBvbGljeRIuLmdvb2dsZS5tb25pdG9yaW5nLnYz
LkRlbGV0ZUFsZXJ0UG9saWN5UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI0gtPk
kwInKiUvdjMve25hbWU9cHJvamVjdHMvKi9hbGVydFBvbGljaWVzLyp92kEEbmFtZRLLAQoR
VXBkYXRlQWxlcnRQb2xpY3kSLi5nb29nbGUubW9uaXRvcmluZy52My5VcGRhdGVBbGVydFBv
bGljeVJlcXVlc3QaIS5nb29nbGUubW9uaXRvcmluZy52My5BbGVydFBvbGljeSJjgtPkkwJC
MjIvdjMve2FsZXJ0X3BvbGljeS5uYW1lPXByb2plY3RzLyovYWxlcnRQb2xpY2llcy8qfToM
YWxlcnRfcG9saWN52kEYdXBkYXRlX21hc2ssYWxlcnRfcG9saWN5GqkBykEZbW9uaXRvcmlu
Zy5nb29nbGVhcGlzLmNvbdJBiQFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRvcmlu
ZyxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3JpbmcucmVhZELMAQoY
Y29tLmdvb2dsZS5tb25pdG9yaW5nLnYzQhFBbGVydFNlcnZpY2VQcm90b1ABWkFjbG91ZC5n
b29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmluZ3BiO21vbml0b3Jp
bmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xlXENsb3VkXE1vbml0
b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0qcRwoHEgUOAIECAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHQoJCgIDABIDEgAm
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACoKCQoCAwUSAxcA
JQoJCgIDBhIDGAAqCggKAQgSAxoANwoJCgIIJRIDGgA3CggKAQgSAxsAWAoJCgIICxIDGwBY
CggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AMgoJCgIICBIDHQAyCggKAQgSAx4AMQoJ
CgIIARIDHgAxCggKAQgSAx8ANwoJCgIIKRIDHwA3CggKAQgSAyAANgoJCgIILRIDIAA2CrME
CgIGABIEKwBsARqmBCBUaGUgQWxlcnRQb2xpY3lTZXJ2aWNlIEFQSSBpcyB1c2VkIHRvIG1h
bmFnZSAobGlzdCwgY3JlYXRlLCBkZWxldGUsCiBlZGl0KSBhbGVydCBwb2xpY2llcyBpbiBD
bG91ZCBNb25pdG9yaW5nLiBBbiBhbGVydGluZyBwb2xpY3kgaXMKIGEgZGVzY3JpcHRpb24g
b2YgdGhlIGNvbmRpdGlvbnMgdW5kZXIgd2hpY2ggc29tZSBhc3BlY3Qgb2YgeW91cgogc3lz
dGVtIGlzIGNvbnNpZGVyZWQgdG8gYmUgInVuaGVhbHRoeSIgYW5kIHRoZSB3YXlzIHRvIG5v
dGlmeQogcGVvcGxlIG9yIHNlcnZpY2VzIGFib3V0IHRoaXMgc3RhdGUuIEluIGFkZGl0aW9u
IHRvIHVzaW5nIHRoaXMgQVBJLCBhbGVydAogcG9saWNpZXMgY2FuIGFsc28gYmUgbWFuYWdl
ZCB0aHJvdWdoCiBbQ2xvdWQgTW9uaXRvcmluZ10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L21vbml0b3JpbmcvZG9jcy8pLAogd2hpY2ggY2FuIGJlIHJlYWNoZWQgYnkgY2xpY2tpbmcg
dGhlICJNb25pdG9yaW5nIiB0YWIgaW4KIFtDbG91ZCBjb25zb2xlXShodHRwczovL2NvbnNv
bGUuY2xvdWQuZ29vZ2xlLmNvbS8pLgoKCgoDBgABEgMrCBoKCgoDBgADEgMsAkEKDAoFBgAD
mQgSAywCQQoLCgMGAAMSBC0CMDgKDQoFBgADmggSBC0CMDgKRwoEBgACABIEMwI5Axo5IExp
c3RzIHRoZSBleGlzdGluZyBhbGVydGluZyBwb2xpY2llcyBmb3IgdGhlIHdvcmtzcGFjZS4K
CgwKBQYAAgABEgMzBhcKDAoFBgACAAISAzMYMAoMCgUGAAIAAxIDNA8oCg0KBQYAAgAEEgQ1
BDcGChEKCQYAAgAEsMq8IhIENQQ3BgoMCgUGAAIABBIDOAQyCg8KCAYAAgAEmwgAEgM4BDIK
LgoEBgACARIEPAJBAxogIEdldHMgYSBzaW5nbGUgYWxlcnRpbmcgcG9saWN5LgoKDAoFBgAC
AQESAzwGFAoMCgUGAAIBAhIDPBUqCgwKBQYAAgEDEgM8NUAKDQoFBgACAQQSBD0EPwYKEQoJ
BgACAQSwyrwiEgQ9BD8GCgwKBQYAAgEEEgNABDIKDwoIBgACAQSbCAASA0AEMgr5AQoEBgAC
AhIESAJOAxrqASBDcmVhdGVzIGEgbmV3IGFsZXJ0aW5nIHBvbGljeS4KCiBEZXNpZ24geW91
ciBhcHBsaWNhdGlvbiB0byBzaW5nbGUtdGhyZWFkIEFQSSBjYWxscyB0aGF0IG1vZGlmeSB0
aGUgc3RhdGUgb2YKIGFsZXJ0aW5nIHBvbGljaWVzIGluIGEgc2luZ2xlIHByb2plY3QuIFRo
aXMgaW5jbHVkZXMgY2FsbHMgdG8KIENyZWF0ZUFsZXJ0UG9saWN5LCBEZWxldGVBbGVydFBv
bGljeSBhbmQgVXBkYXRlQWxlcnRQb2xpY3kuCgoMCgUGAAICARIDSAYXCgwKBQYAAgICEgNI
GDAKDAoFBgACAgMSA0g7RgoNCgUGAAICBBIESQRMBgoRCgkGAAICBLDKvCISBEkETAYKDAoF
BgACAgQSA00EPwoPCggGAAICBJsIABIDTQQ/CvYBCgQGAAIDEgRVAlsDGucBIERlbGV0ZXMg
YW4gYWxlcnRpbmcgcG9saWN5LgoKIERlc2lnbiB5b3VyIGFwcGxpY2F0aW9uIHRvIHNpbmds
ZS10aHJlYWQgQVBJIGNhbGxzIHRoYXQgbW9kaWZ5IHRoZSBzdGF0ZSBvZgogYWxlcnRpbmcg
cG9saWNpZXMgaW4gYSBzaW5nbGUgcHJvamVjdC4gVGhpcyBpbmNsdWRlcyBjYWxscyB0bwog
Q3JlYXRlQWxlcnRQb2xpY3ksIERlbGV0ZUFsZXJ0UG9saWN5IGFuZCBVcGRhdGVBbGVydFBv
bGljeS4KCgwKBQYAAgMBEgNVBhcKDAoFBgACAwISA1UYMAoMCgUGAAIDAxIDVg8kCg0KBQYA
AgMEEgRXBFkGChEKCQYAAgMEsMq8IhIEVwRZBgoMCgUGAAIDBBIDWgQyCg8KCAYAAgMEmwgA
EgNaBDIKzQMKBAYAAgQSBGUCawMavgMgVXBkYXRlcyBhbiBhbGVydGluZyBwb2xpY3kuIFlv
dSBjYW4gZWl0aGVyIHJlcGxhY2UgdGhlIGVudGlyZSBwb2xpY3kgd2l0aAogYSBuZXcgb25l
IG9yIHJlcGxhY2Ugb25seSBjZXJ0YWluIGZpZWxkcyBpbiB0aGUgY3VycmVudCBhbGVydGlu
ZyBwb2xpY3kgYnkKIHNwZWNpZnlpbmcgdGhlIGZpZWxkcyB0byBiZSB1cGRhdGVkIHZpYSBg
dXBkYXRlTWFza2AuIFJldHVybnMgdGhlCiB1cGRhdGVkIGFsZXJ0aW5nIHBvbGljeS4KCiBE
ZXNpZ24geW91ciBhcHBsaWNhdGlvbiB0byBzaW5nbGUtdGhyZWFkIEFQSSBjYWxscyB0aGF0
IG1vZGlmeSB0aGUgc3RhdGUgb2YKIGFsZXJ0aW5nIHBvbGljaWVzIGluIGEgc2luZ2xlIHBy
b2plY3QuIFRoaXMgaW5jbHVkZXMgY2FsbHMgdG8KIENyZWF0ZUFsZXJ0UG9saWN5LCBEZWxl
dGVBbGVydFBvbGljeSBhbmQgVXBkYXRlQWxlcnRQb2xpY3kuCgoMCgUGAAIEARIDZQYXCgwK
BQYAAgQCEgNlGDAKDAoFBgACBAMSA2U7RgoNCgUGAAIEBBIEZgRpBgoRCgkGAAIEBLDKvCIS
BGYEaQYKDAoFBgACBAQSA2oERgoPCggGAAIEBJsIABIDagRGCkAKAgQAEgVvAIgBARozIFRo
ZSBwcm90b2NvbCBmb3IgdGhlIGBDcmVhdGVBbGVydFBvbGljeWAgcmVxdWVzdC4KCgoKAwQA
ARIDbwggCo8FCgQEAAIAEgV9AoIBBBr/BCBSZXF1aXJlZC4gVGhlCiBbcHJvamVjdF0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkg
aW4gd2hpY2gKIHRvIGNyZWF0ZSB0aGUgYWxlcnRpbmcgcG9saWN5LiBUaGUgZm9ybWF0IGlz
OgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdCgogTm90ZSB0aGF0IHRo
aXMgZmllbGQgbmFtZXMgdGhlIHBhcmVudCBjb250YWluZXIgaW4gd2hpY2ggdGhlIGFsZXJ0
aW5nCiBwb2xpY3kgd2lsbCBiZSB3cml0dGVuLCBub3QgdGhlIG5hbWUgb2YgdGhlIGNyZWF0
ZWQgcG9saWN5LiB8bmFtZXwgbXVzdCBiZQogYSBob3N0IHByb2plY3Qgb2YgYSBNZXRyaWNz
IFNjb3BlLCBvdGhlcndpc2UgSU5WQUxJRF9BUkdVTUVOVCBlcnJvciB3aWxsCiByZXR1cm4u
IFRoZSBhbGVydGluZyBwb2xpY3kgdGhhdCBpcyByZXR1cm5lZCB3aWxsIGhhdmUgYSBuYW1l
IHRoYXQgY29udGFpbnMKIGEgbm9ybWFsaXplZCByZXByZXNlbnRhdGlvbiBvZiB0aGlzIG5h
bWUgYXMgYSBwcmVmaXggYnV0IGFkZHMgYSBzdWZmaXggb2YKIHRoZSBmb3JtIGAvYWxlcnRQ
b2xpY2llcy9bQUxFUlRfUE9MSUNZX0lEXWAsIGlkZW50aWZ5aW5nIHRoZSBwb2xpY3kgaW4g
dGhlCiBjb250YWluZXIuCgoMCgUEAAIABRIDfQIICgwKBQQAAgABEgN9CQ0KDAoFBAACAAMS
A30QEQoOCgUEAAIACBIFfRKCAQMKDwoIBAACAAicCAASA34EKgoQCgcEAAIACJ8IEgV/BIEB
BQrEAQoEBAACARIEhwECSBq1ASBSZXF1aXJlZC4gVGhlIHJlcXVlc3RlZCBhbGVydGluZyBw
b2xpY3kuIFlvdSBzaG91bGQgb21pdCB0aGUgYG5hbWVgIGZpZWxkCiBpbiB0aGlzIHBvbGlj
eS4gVGhlIG5hbWUgd2lsbCBiZSByZXR1cm5lZCBpbiB0aGUgbmV3IHBvbGljeSwgaW5jbHVk
aW5nIGEKIG5ldyBgW0FMRVJUX1BPTElDWV9JRF1gIHZhbHVlLgoKDQoFBAACAQYSBIcBAg0K
DQoFBAACAQESBIcBDhoKDQoFBAACAQMSBIcBHR4KDQoFBAACAQgSBIcBH0cKEAoIBAACAQic
CAASBIcBIEYKPgoCBAESBosBAJUBARowIFRoZSBwcm90b2NvbCBmb3IgdGhlIGBHZXRBbGVy
dFBvbGljeWAgcmVxdWVzdC4KCgsKAwQBARIEiwEIHQqSAQoEBAECABIGjwEClAEEGoEBIFJl
cXVpcmVkLiBUaGUgYWxlcnRpbmcgcG9saWN5IHRvIHJldHJpZXZlLiBUaGUgZm9ybWF0IGlz
OgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL2FsZXJ0UG9saWNpZXMv
W0FMRVJUX1BPTElDWV9JRF0KCg0KBQQBAgAFEgSPAQIICg0KBQQBAgABEgSPAQkNCg0KBQQB
AgADEgSPARARCg8KBQQBAgAIEgaPARKUAQMKEAoIBAECAAicCAASBJABBCoKEQoHBAECAAif
CBIGkQEEkwEFCkEKAgQCEgaYAQDCAQEaMyBUaGUgcHJvdG9jb2wgZm9yIHRoZSBgTGlzdEFs
ZXJ0UG9saWNpZXNgIHJlcXVlc3QuCgoLCgMEAgESBJgBCCAKwgMKBAQCAgASBqQBAqkBBBqx
AyBSZXF1aXJlZC4gVGhlCiBbcHJvamVjdF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21v
bml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkgd2hvc2UKIGFsZXJ0IHBvbGljaWVzIGFy
ZSB0byBiZSBsaXN0ZWQuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNU
X0lEX09SX05VTUJFUl0KCiBOb3RlIHRoYXQgdGhpcyBmaWVsZCBuYW1lcyB0aGUgcGFyZW50
IGNvbnRhaW5lciBpbiB3aGljaCB0aGUgYWxlcnRpbmcKIHBvbGljaWVzIHRvIGJlIGxpc3Rl
ZCBhcmUgc3RvcmVkLiBUbyByZXRyaWV2ZSBhIHNpbmdsZSBhbGVydGluZyBwb2xpY3kKIGJ5
IG5hbWUsIHVzZSB0aGUKIFtHZXRBbGVydFBvbGljeV1bZ29vZ2xlLm1vbml0b3JpbmcudjMu
QWxlcnRQb2xpY3lTZXJ2aWNlLkdldEFsZXJ0UG9saWN5XQogb3BlcmF0aW9uLCBpbnN0ZWFk
LgoKDQoFBAICAAUSBKQBAggKDQoFBAICAAESBKQBCQ0KDQoFBAICAAMSBKQBEBEKDwoFBAIC
AAgSBqQBEqkBAwoQCggEAgIACJwIABIEpQEEKgoRCgcEAgIACJ8IEgamAQSoAQUKgQIKBAQC
AgESBLABAj0a8gEgT3B0aW9uYWwuIElmIHByb3ZpZGVkLCB0aGlzIGZpZWxkIHNwZWNpZmll
cyB0aGUgY3JpdGVyaWEgdGhhdCBtdXN0IGJlIG1ldAogYnkgYWxlcnQgcG9saWNpZXMgdG8g
YmUgaW5jbHVkZWQgaW4gdGhlIHJlc3BvbnNlLgoKIEZvciBtb3JlIGRldGFpbHMsIHNlZSBb
c29ydGluZyBhbmQKIGZpbHRlcmluZ10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0
b3JpbmcvYXBpL3YzL3NvcnRpbmctYW5kLWZpbHRlcmluZykuCgoNCgUEAgIBBRIEsAECCAoN
CgUEAgIBARIEsAEJDwoNCgUEAgIBAxIEsAESEwoNCgUEAgIBCBIEsAEUPAoQCggEAgIBCJwI
ABIEsAEVOwrjAgoEBAICAhIEuAECPxrUAiBPcHRpb25hbC4gQSBjb21tYS1zZXBhcmF0ZWQg
bGlzdCBvZiBmaWVsZHMgYnkgd2hpY2ggdG8gc29ydCB0aGUgcmVzdWx0LgogU3VwcG9ydHMg
dGhlIHNhbWUgc2V0IG9mIGZpZWxkIHJlZmVyZW5jZXMgYXMgdGhlIGBmaWx0ZXJgIGZpZWxk
LiBFbnRyaWVzCiBjYW4gYmUgcHJlZml4ZWQgd2l0aCBhIG1pbnVzIHNpZ24gdG8gc29ydCBi
eSB0aGUgZmllbGQgaW4gZGVzY2VuZGluZyBvcmRlci4KCiBGb3IgbW9yZSBkZXRhaWxzLCBz
ZWUgW3NvcnRpbmcgYW5kCiBmaWx0ZXJpbmddKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9t
b25pdG9yaW5nL2FwaS92My9zb3J0aW5nLWFuZC1maWx0ZXJpbmcpLgoKDQoFBAICAgUSBLgB
AggKDQoFBAICAgESBLgBCREKDQoFBAICAgMSBLgBFBUKDQoFBAICAggSBLgBFj4KEAoIBAIC
AgicCAASBLgBFz0KVwoEBAICAxIEuwECPxpJIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1i
ZXIgb2YgcmVzdWx0cyB0byByZXR1cm4gaW4gYSBzaW5nbGUgcmVzcG9uc2UuCgoNCgUEAgID
BRIEuwECBwoNCgUEAgIDARIEuwEIEQoNCgUEAgIDAxIEuwEUFQoNCgUEAgIDCBIEuwEWPgoQ
CggEAgIDCJwIABIEuwEXPQrtAQoEBAICBBIEwQECQRreASBPcHRpb25hbC4gSWYgdGhpcyBm
aWVsZCBpcyBub3QgZW1wdHkgdGhlbiBpdCBtdXN0IGNvbnRhaW4gdGhlCiBgbmV4dFBhZ2VU
b2tlbmAgdmFsdWUgcmV0dXJuZWQgYnkgYSBwcmV2aW91cyBjYWxsIHRvIHRoaXMgbWV0aG9k
LiAgVXNpbmcKIHRoaXMgZmllbGQgY2F1c2VzIHRoZSBtZXRob2QgdG8gcmV0dXJuIG1vcmUg
cmVzdWx0cyBmcm9tIHRoZSBwcmV2aW91cwogbWV0aG9kIGNhbGwuCgoNCgUEAgIEBRIEwQEC
CAoNCgUEAgIEARIEwQEJEwoNCgUEAgIEAxIEwQEWFwoNCgUEAgIECBIEwQEYQAoQCggEAgIE
CJwIABIEwQEZPwpCCgIEAxIGxQEA0QEBGjQgVGhlIHByb3RvY29sIGZvciB0aGUgYExpc3RB
bGVydFBvbGljaWVzYCByZXNwb25zZS4KCgsKAwQDARIExQEIIQosCgQEAwIAEgTHAQIqGh4g
VGhlIHJldHVybmVkIGFsZXJ0IHBvbGljaWVzLgoKDQoFBAMCAAQSBMcBAgoKDQoFBAMCAAYS
BMcBCxYKDQoFBAMCAAESBMcBFyUKDQoFBAMCAAMSBMcBKCkK0QEKBAQDAgESBMwBAh0awgEg
SWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gd2VyZSByZXR1cm5lZCwgdGhl
biB0aGlzIGZpZWxkIGlzIHNldAogdG8gYSBub24tZW1wdHkgdmFsdWUuIFRvIHNlZSB0aGUg
YWRkaXRpb25hbCByZXN1bHRzLAogdXNlIHRoYXQgdmFsdWUgYXMgYHBhZ2VfdG9rZW5gIGlu
IHRoZSBuZXh0IGNhbGwgdG8gdGhpcyBtZXRob2QuCgoNCgUEAwIBBRIEzAECCAoNCgUEAwIB
ARIEzAEJGAoNCgUEAwIBAxIEzAEbHAqbAQoEBAMCAhIE0AECFxqMASBUaGUgdG90YWwgbnVt
YmVyIG9mIGFsZXJ0IHBvbGljaWVzIGluIGFsbCBwYWdlcy4gVGhpcyBudW1iZXIgaXMgb25s
eSBhbgogZXN0aW1hdGUsIGFuZCBtYXkgY2hhbmdlIGluIHN1YnNlcXVlbnQgcGFnZXMuIGh0
dHBzOi8vYWlwLmRldi8xNTgKCg0KBQQDAgIFEgTQAQIHCg0KBQQDAgIBEgTQAQgSCg0KBQQD
AgIDEgTQARUWCkEKAgQEEgbUAQDyAQEaMyBUaGUgcHJvdG9jb2wgZm9yIHRoZSBgVXBkYXRl
QWxlcnRQb2xpY3lgIHJlcXVlc3QuCgoLCgMEBAESBNQBCCAKvAkKBAQEAgASBuoBAusBLxqr
CSBPcHRpb25hbC4gQSBsaXN0IG9mIGFsZXJ0aW5nIHBvbGljeSBmaWVsZCBuYW1lcy4gSWYg
dGhpcyBmaWVsZCBpcyBub3QKIGVtcHR5LCBlYWNoIGxpc3RlZCBmaWVsZCBpbiB0aGUgZXhp
c3RpbmcgYWxlcnRpbmcgcG9saWN5IGlzIHNldCB0byB0aGUKIHZhbHVlIG9mIHRoZSBjb3Jy
ZXNwb25kaW5nIGZpZWxkIGluIHRoZSBzdXBwbGllZCBwb2xpY3kgKGBhbGVydF9wb2xpY3lg
KSwKIG9yIHRvIHRoZSBmaWVsZCdzIGRlZmF1bHQgdmFsdWUgaWYgdGhlIGZpZWxkIGlzIG5v
dCBpbiB0aGUgc3VwcGxpZWQKIGFsZXJ0aW5nIHBvbGljeS4gIEZpZWxkcyBub3QgbGlzdGVk
IHJldGFpbiB0aGVpciBwcmV2aW91cyB2YWx1ZS4KCiBFeGFtcGxlcyBvZiB2YWxpZCBmaWVs
ZCBtYXNrcyBpbmNsdWRlIGBkaXNwbGF5X25hbWVgLCBgZG9jdW1lbnRhdGlvbmAsCiBgZG9j
dW1lbnRhdGlvbi5jb250ZW50YCwgYGRvY3VtZW50YXRpb24ubWltZV90eXBlYCwgYHVzZXJf
bGFiZWxzYCwKIGB1c2VyX2xhYmVsLm5hbWVvZmtleWAsIGBlbmFibGVkYCwgYGNvbmRpdGlv
bnNgLCBgY29tYmluZXJgLCBldGMuCgogSWYgdGhpcyBmaWVsZCBpcyBlbXB0eSwgdGhlbiB0
aGUgc3VwcGxpZWQgYWxlcnRpbmcgcG9saWN5IHJlcGxhY2VzIHRoZQogZXhpc3RpbmcgcG9s
aWN5LiBJdCBpcyB0aGUgc2FtZSBhcyBkZWxldGluZyB0aGUgZXhpc3RpbmcgcG9saWN5IGFu
ZAogYWRkaW5nIHRoZSBzdXBwbGllZCBwb2xpY3ksIGV4Y2VwdCBmb3IgdGhlIGZvbGxvd2lu
ZzoKCiArICAgVGhlIG5ldyBwb2xpY3kgd2lsbCBoYXZlIHRoZSBzYW1lIGBbQUxFUlRfUE9M
SUNZX0lEXWAgYXMgdGhlIGZvcm1lcgogICAgIHBvbGljeS4gVGhpcyBnaXZlcyB5b3UgY29u
dGludWl0eSB3aXRoIHRoZSBmb3JtZXIgcG9saWN5IGluIHlvdXIKICAgICBub3RpZmljYXRp
b25zIGFuZCBpbmNpZGVudHMuCiArICAgQ29uZGl0aW9ucyBpbiB0aGUgbmV3IHBvbGljeSB3
aWxsIGtlZXAgdGhlaXIgZm9ybWVyIGBbQ09ORElUSU9OX0lEXWAgaWYKICAgICB0aGUgc3Vw
cGxpZWQgY29uZGl0aW9uIGluY2x1ZGVzIHRoZSBgbmFtZWAgZmllbGQgd2l0aCB0aGF0CiAg
ICAgYFtDT05ESVRJT05fSURdYC4gSWYgdGhlIHN1cHBsaWVkIGNvbmRpdGlvbiBvbWl0cyB0
aGUgYG5hbWVgIGZpZWxkLAogICAgIHRoZW4gYSBuZXcgYFtDT05ESVRJT05fSURdYCBpcyBj
cmVhdGVkLgoKDQoFBAQCAAYSBOoBAhsKDQoFBAQCAAESBOoBHCcKDQoFBAQCAAMSBOoBKisK
DQoFBAQCAAgSBOsBBi4KEAoIBAQCAAicCAASBOsBBy0K2wEKBAQEAgESBPEBAkgazAEgUmVx
dWlyZWQuIFRoZSB1cGRhdGVkIGFsZXJ0aW5nIHBvbGljeSBvciB0aGUgdXBkYXRlZCB2YWx1
ZXMgZm9yIHRoZQogZmllbGRzIGxpc3RlZCBpbiBgdXBkYXRlX21hc2tgLgogSWYgYHVwZGF0
ZV9tYXNrYCBpcyBub3QgZW1wdHksIGFueSBmaWVsZHMgaW4gdGhpcyBwb2xpY3kgdGhhdCBh
cmUKIG5vdCBpbiBgdXBkYXRlX21hc2tgIGFyZSBpZ25vcmVkLgoKDQoFBAQCAQYSBPEBAg0K
DQoFBAQCAQESBPEBDhoKDQoFBAQCAQMSBPEBHR4KDQoFBAQCAQgSBPEBH0cKEAoIBAQCAQic
CAASBPEBIEYKQQoCBAUSBvUBAIECARozIFRoZSBwcm90b2NvbCBmb3IgdGhlIGBEZWxldGVB
bGVydFBvbGljeWAgcmVxdWVzdC4KCgsKAwQFARIE9QEIIArdAQoEBAUCABIG+wECgAIEGswB
IFJlcXVpcmVkLiBUaGUgYWxlcnRpbmcgcG9saWN5IHRvIGRlbGV0ZS4gVGhlIGZvcm1hdCBp
czoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9hbGVydFBvbGljaWVz
L1tBTEVSVF9QT0xJQ1lfSURdCgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBbQWxlcnRQ
b2xpY3ldW2dvb2dsZS5tb25pdG9yaW5nLnYzLkFsZXJ0UG9saWN5XS4KCg0KBQQFAgAFEgT7
AQIICg0KBQQFAgABEgT7AQkNCg0KBQQFAgADEgT7ARARCg8KBQQFAgAIEgb7ARKAAgMKEAoI
BAUCAAicCAASBPwBBCoKEQoHBAUCAAifCBIG/QEE/wEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest ===
    # Fields for CreateAlertPolicyRequest
    # Field: name Type: 9 ()
    # Field: alert_policy Type: 11 (.google.monitoring.v3.AlertPolicy)

# === Message: Google::Monitoring::V3::AlertService::GetAlertPolicyRequest ===
    # Fields for GetAlertPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest ===
    # Fields for ListAlertPoliciesRequest
    # Field: name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse ===
    # Fields for ListAlertPoliciesResponse
    # Field: alert_policies Type: 11 (.google.monitoring.v3.AlertPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest ===
    # Fields for UpdateAlertPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: alert_policy Type: 11 (.google.monitoring.v3.AlertPolicy)

# === Message: Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest ===
    # Fields for DeleteAlertPolicyRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Monitoring::V3::AlertService::AlertPolicyServiceClient ===
package Google::Monitoring::V3::AlertService::AlertPolicyServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::AlertService::AlertPolicyServiceClient

Client stub representing the remote C<AlertPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_alert_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'ListAlertPolicies',
        request        => $req,
        response_class => 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse',
    });
}

sub get_alert_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::AlertService::GetAlertPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'GetAlertPolicy',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Alert::AlertPolicy',
    });
}

sub create_alert_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'CreateAlertPolicy',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Alert::AlertPolicy',
    });
}

sub delete_alert_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'DeleteAlertPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_alert_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'UpdateAlertPolicy',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Alert::AlertPolicy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::AlertService - Compiled Protocol Buffers messages for google/monitoring/v3/alert_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::AlertService;

    my $msg = Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest->new({
        name => $name,
        alert_policy => $alert_policy,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/alert_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest

The protocol for the `CreateAlertPolicy` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) in which
to create the alerting policy. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

Note that this field names the parent container in which the alerting
policy will be written, not the name of the created policy. |name| must be
a host project of a Metrics Scope, otherwise INVALID_ARGUMENT error will
return. The alerting policy that is returned will have a name that contains
a normalized representation of this name as a prefix but adds a suffix of
the form `/alertPolicies/[ALERT_POLICY_ID]`, identifying the policy in the
container.

=item * C<< $msg->alert_policy() >> / C<< $msg->alert_policy($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Alert::AlertPolicy>)

Required. The requested alerting policy. You should omit the `name` field
in this policy. The name will be returned in the new policy, including a
new `[ALERT_POLICY_ID]` value.

=back

=head2 Google::Monitoring::V3::AlertService::GetAlertPolicyRequest

The protocol for the `GetAlertPolicy` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The alerting policy to retrieve. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/alertPolicies/[ALERT_POLICY_ID]

=back

=head2 Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest

The protocol for the `ListAlertPolicies` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) whose
alert policies are to be listed. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

Note that this field names the parent container in which the alerting
policies to be listed are stored. To retrieve a single alerting policy
by name, use the
[GetAlertPolicy][google.monitoring.v3.AlertPolicyService.GetAlertPolicy]
operation, instead.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. If provided, this field specifies the criteria that must be met
by alert policies to be included in the response.

For more details, see [sorting and
filtering](https://cloud.google.com/monitoring/api/v3/sorting-and-filtering).

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields by which to sort the result.
Supports the same set of field references as the `filter` field. Entries
can be prefixed with a minus sign to sort by the field in descending order.

For more details, see [sorting and
filtering](https://cloud.google.com/monitoring/api/v3/sorting-and-filtering).

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return in a single response.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If this field is not empty then it must contain the
`nextPageToken` value returned by a previous call to this method.  Using
this field causes the method to return more results from the previous
method call.

=back

=head2 Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse

The protocol for the `ListAlertPolicies` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alert_policies() >> / C<< $msg->alert_policies($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Alert::AlertPolicy>)

The returned alert policies.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than were returned, then this field is set
to a non-empty value. To see the additional results,
use that value as `page_token` in the next call to this method.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of alert policies in all pages. This number is only an
estimate, and may change in subsequent pages. https://aip.dev/158

=back

=head2 Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest

The protocol for the `UpdateAlertPolicy` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A list of alerting policy field names. If this field is not
empty, each listed field in the existing alerting policy is set to the
value of the corresponding field in the supplied policy (`alert_policy`),
or to the field's default value if the field is not in the supplied
alerting policy.  Fields not listed retain their previous value.

Examples of valid field masks include `display_name`, `documentation`,
`documentation.content`, `documentation.mime_type`, `user_labels`,
`user_label.nameofkey`, `enabled`, `conditions`, `combiner`, etc.

If this field is empty, then the supplied alerting policy replaces the
existing policy. It is the same as deleting the existing policy and
adding the supplied policy, except for the following:

+   The new policy will have the same `[ALERT_POLICY_ID]` as the former
    policy. This gives you continuity with the former policy in your
    notifications and incidents.
+   Conditions in the new policy will keep their former `[CONDITION_ID]` if
    the supplied condition includes the `name` field with that
    `[CONDITION_ID]`. If the supplied condition omits the `name` field,
    then a new `[CONDITION_ID]` is created.

=item * C<< $msg->alert_policy() >> / C<< $msg->alert_policy($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Alert::AlertPolicy>)

Required. The updated alerting policy or the updated values for the
fields listed in `update_mask`.
If `update_mask` is not empty, any fields in this policy that are
not in `update_mask` are ignored.

=back

=head2 Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest

The protocol for the `DeleteAlertPolicy` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The alerting policy to delete. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/alertPolicies/[ALERT_POLICY_ID]

For more information, see [AlertPolicy][google.monitoring.v3.AlertPolicy].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::AlertService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
