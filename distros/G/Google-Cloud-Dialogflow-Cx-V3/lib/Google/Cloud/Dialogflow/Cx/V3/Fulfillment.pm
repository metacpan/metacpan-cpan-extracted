package Google::Cloud::Dialogflow::Cx::V3::Fulfillment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::Cx::V3::AdvancedSettings };
    eval { require Google::Cloud::Dialogflow::Cx::V3::ResponseMessage };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9mdWxmaWxsbWVudC5wcm90bxIdZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aNWdvb2dsZS9jbG91ZC9kaWFsb2dm
bG93L2N4L3YzL2FkdmFuY2VkX3NldHRpbmdzLnByb3RvGjRnb29nbGUvY2xvdWQvZGlhbG9n
Zmxvdy9jeC92My9yZXNwb25zZV9tZXNzYWdlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3Ry
dWN0LnByb3RvIocNCgtGdWxmaWxsbWVudBJKCghtZXNzYWdlcxgBIAMoCzIuLmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzLlJlc3BvbnNlTWVzc2FnZVIIbWVzc2FnZXMSQAoHd2Vi
aG9vaxgCIAEoCUIm+kEjCiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1dlYmhvb2tSB3dl
Ymhvb2sSOAoYcmV0dXJuX3BhcnRpYWxfcmVzcG9uc2VzGAggASgIUhZyZXR1cm5QYXJ0aWFs
UmVzcG9uc2VzEhAKA3RhZxgDIAEoCVIDdGFnEjMKE2NvZGVfYmxvY2tfZnVuY3Rpb24YESAB
KAlCA+BBAVIRY29kZUJsb2NrRnVuY3Rpb24ScQoVc2V0X3BhcmFtZXRlcl9hY3Rpb25zGAQg
AygLMj0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRnVsZmlsbG1lbnQuU2V0UGFy
YW1ldGVyQWN0aW9uUhNzZXRQYXJhbWV0ZXJBY3Rpb25zEmgKEWNvbmRpdGlvbmFsX2Nhc2Vz
GAUgAygLMjsuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRnVsZmlsbG1lbnQuQ29u
ZGl0aW9uYWxDYXNlc1IQY29uZGl0aW9uYWxDYXNlcxJcChFhZHZhbmNlZF9zZXR0aW5ncxgH
IAEoCzIvLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkFkdmFuY2VkU2V0dGluZ3NS
EGFkdmFuY2VkU2V0dGluZ3MSPAoaZW5hYmxlX2dlbmVyYXRpdmVfZmFsbGJhY2sYDCABKAhS
GGVuYWJsZUdlbmVyYXRpdmVGYWxsYmFjaxJcCgpnZW5lcmF0b3JzGA0gAygLMjwuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRnVsZmlsbG1lbnQuR2VuZXJhdG9yU2V0dGluZ3NS
CmdlbmVyYXRvcnMaYAoSU2V0UGFyYW1ldGVyQWN0aW9uEhwKCXBhcmFtZXRlchgBIAEoCVIJ
cGFyYW1ldGVyEiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1
ZRrcAwoQQ29uZGl0aW9uYWxDYXNlcxJWCgVjYXNlcxgBIAMoCzJALmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLkZ1bGZpbGxtZW50LkNvbmRpdGlvbmFsQ2FzZXMuQ2FzZVIFY2Fz
ZXMa7wIKBENhc2USHAoJY29uZGl0aW9uGAEgASgJUgljb25kaXRpb24SbwoMY2FzZV9jb250
ZW50GAIgAygLMkwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRnVsZmlsbG1lbnQu
Q29uZGl0aW9uYWxDYXNlcy5DYXNlLkNhc2VDb250ZW50UgtjYXNlQ29udGVudBrXAQoLQ2Fz
ZUNvbnRlbnQSSgoHbWVzc2FnZRgBIAEoCzIuLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlJlc3BvbnNlTWVzc2FnZUgAUgdtZXNzYWdlEmgKEGFkZGl0aW9uYWxfY2FzZXMYAiAB
KAsyOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5GdWxmaWxsbWVudC5Db25kaXRp
b25hbENhc2VzSABSD2FkZGl0aW9uYWxDYXNlc0ISChBjYXNlc19vcl9tZXNzYWdlGtACChFH
ZW5lcmF0b3JTZXR0aW5ncxJJCglnZW5lcmF0b3IYASABKAlCK+BBAvpBJQojZGlhbG9nZmxv
dy5nb29nbGVhcGlzLmNvbS9HZW5lcmF0b3JSCWdlbmVyYXRvchJ8ChBpbnB1dF9wYXJhbWV0
ZXJzGAIgAygLMlEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRnVsZmlsbG1lbnQu
R2VuZXJhdG9yU2V0dGluZ3MuSW5wdXRQYXJhbWV0ZXJzRW50cnlSD2lucHV0UGFyYW1ldGVy
cxIuChBvdXRwdXRfcGFyYW1ldGVyGAMgASgJQgPgQQJSD291dHB1dFBhcmFtZXRlchpCChRJ
bnB1dFBhcmFtZXRlcnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBQrMBCiFjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNCEEZ1bGZp
bGxtZW50UHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYz
L2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuQ3guVjPqAiFHb29n
bGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNK0jYKBxIFDgCuAQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUAD8KCQoCAwMSAxUAPgoJCgIDBBIDFgAmCggKAQgSAxgAOgoJCgIIJRIDGAA6
CggKAQgSAxkASAoJCgIICxIDGQBICggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMQoJ
CgIICBIDGwAxCggKAQgSAxwAOgoJCgIIARIDHAA6CggKAQgSAx0AIAoJCgIIJBIDHQAgCggK
AQgSAx4AOgoJCgIILRIDHgA6CvkFCgIEABIFLwCuAQEa6wUgQSBmdWxmaWxsbWVudCBjYW4g
ZG8gb25lIG9yIG1vcmUgb2YgdGhlIGZvbGxvd2luZyBhY3Rpb25zIGF0IHRoZSBzYW1lIHRp
bWU6CgogICAqIEdlbmVyYXRlIHJpY2ggbWVzc2FnZSByZXNwb25zZXMuCiAgICogU2V0IHBh
cmFtZXRlciB2YWx1ZXMuCiAgICogQ2FsbCB0aGUgd2ViaG9vay4KCiBGdWxmaWxsbWVudHMg
Y2FuIGJlIGNhbGxlZCBhdCB2YXJpb3VzIHN0YWdlcyBpbiB0aGUKIFtQYWdlXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5QYWdlXSBvcgogW0Zvcm1dW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLkZvcm1dIGxpZmVjeWNsZS4gRm9yIGV4YW1wbGUsIHdoZW4gYQog
W0RldGVjdEludGVudFJlcXVlc3RdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkRl
dGVjdEludGVudFJlcXVlc3RdCiBkcml2ZXMgYSBzZXNzaW9uIHRvIGVudGVyIGEgbmV3IHBh
Z2UsIHRoZSBwYWdlJ3MgZW50cnkgZnVsZmlsbG1lbnQgY2FuIGFkZCBhCiBzdGF0aWMgcmVz
cG9uc2UgdG8gdGhlCiBbUXVlcnlSZXN1bHRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlF1ZXJ5UmVzdWx0XSBpbiB0aGUgcmV0dXJuaW5nCiBbRGV0ZWN0SW50ZW50UmVzcG9u
c2VdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkRldGVjdEludGVudFJlc3BvbnNl
XSwKIGNhbGwgdGhlIHdlYmhvb2sgKGZvciBleGFtcGxlLCB0byBsb2FkIHVzZXIgZGF0YSBm
cm9tIGEgZGF0YWJhc2UpLCBvciBib3RoLgoKCgoDBAABEgMvCBMKKgoEBAADABIEMQI3Axoc
IFNldHRpbmcgYSBwYXJhbWV0ZXIgdmFsdWUuCgoMCgUEAAMAARIDMQocCi8KBgQAAwACABID
MwQZGiAgRGlzcGxheSBuYW1lIG9mIHRoZSBwYXJhbWV0ZXIuCgoOCgcEAAMAAgAFEgMzBAoK
DgoHBAADAAIAARIDMwsUCg4KBwQAAwACAAMSAzMXGApTCgYEAAMAAgESAzYEJBpEIFRoZSBu
ZXcgdmFsdWUgb2YgdGhlIHBhcmFtZXRlci4gQSBudWxsIHZhbHVlIGNsZWFycyB0aGUgcGFy
YW1ldGVyLgoKDgoHBAADAAIBBhIDNgQZCg4KBwQAAwACAQESAzYaHwoOCgcEAAMAAgEDEgM2
IiMKogEKBAQAAwESBDsCWgMakwEgQSBsaXN0IG9mIGNhc2NhZGluZyBpZi1lbHNlIGNvbmRp
dGlvbnMuIENhc2VzIGFyZSBtdXR1YWxseSBleGNsdXNpdmUuCiBUaGUgZmlyc3Qgb25lIHdp
dGggYSBtYXRjaGluZyBjb25kaXRpb24gaXMgc2VsZWN0ZWQsIGFsbCB0aGUgcmVzdCBpZ25v
cmVkLgoKDAoFBAADAQESAzsKGgqeAQoGBAADAQMAEgQ+BFYFGo0BIEVhY2ggY2FzZSBoYXMg
YSBCb29sZWFuIGNvbmRpdGlvbi4gV2hlbiBpdCBpcyBldmFsdWF0ZWQgdG8gYmUgVHJ1ZSwg
dGhlCiBjb3JyZXNwb25kaW5nIG1lc3NhZ2VzIHdpbGwgYmUgc2VsZWN0ZWQgYW5kIGV2YWx1
YXRlZCByZWN1cnNpdmVseS4KCg4KBwQAAwEDAAESAz4MEApYCggEAAMBAwADABIEQAZJBxpG
IFRoZSBsaXN0IG9mIG1lc3NhZ2VzIG9yIGNvbmRpdGlvbmFsIGNhc2VzIHRvIGFjdGl2YXRl
IGZvciB0aGlzIGNhc2UuCgoQCgkEAAMBAwADAAESA0AOGQpXCgoEAAMBAwADAAgAEgRCCEgJ
GkMgRWl0aGVyIGEgbWVzc2FnZSBpcyByZXR1cm5lZCBvciBhZGRpdGlvbmFsIGNhc2VzIHRv
IGJlIGV2YWx1YXRlZC4KChIKCwQAAwEDAAMACAABEgNCDh4KJgoKBAADAQMAAwACABIDRAom
GhMgUmV0dXJuZWQgbWVzc2FnZS4KChIKCwQAAwEDAAMAAgAGEgNEChkKEgoLBAADAQMAAwAC
AAESA0QaIQoSCgsEAAMBAwADAAIAAxIDRCQlCjYKCgQAAwEDAAMAAgESA0cKMBojIEFkZGl0
aW9uYWwgY2FzZXMgdG8gYmUgZXZhbHVhdGVkLgoKEgoLBAADAQMAAwACAQYSA0cKGgoSCgsE
AAMBAwADAAIBARIDRxsrChIKCwQAAwEDAAMAAgEDEgNHLi8KywIKCAQAAwEDAAIAEgNSBhsa
uQIgVGhlIGNvbmRpdGlvbiB0byBhY3RpdmF0ZSBhbmQgc2VsZWN0IHRoaXMgY2FzZS4gRW1w
dHkgbWVhbnMgdGhlCiBjb25kaXRpb24gaXMgYWx3YXlzIHRydWUuIFRoZSBjb25kaXRpb24g
aXMgZXZhbHVhdGVkIGFnYWluc3QgW2Zvcm0KIHBhcmFtZXRlcnNdW0Zvcm0ucGFyYW1ldGVy
c10gb3IgW3Nlc3Npb24KIHBhcmFtZXRlcnNdW1Nlc3Npb25JbmZvLnBhcmFtZXRlcnNdLgoK
IFNlZSB0aGUgW2NvbmRpdGlvbnMKIHJlZmVyZW5jZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2RpYWxvZ2Zsb3cvY3gvZG9jcy9yZWZlcmVuY2UvY29uZGl0aW9uKS4KChAKCQQAAwED
AAIABRIDUgYMChAKCQQAAwEDAAIAARIDUg0WChAKCQQAAwEDAAIAAxIDUhkaCioKCAQAAwED
AAIBEgNVBiwaGSBBIGxpc3Qgb2YgY2FzZSBjb250ZW50LgoKEAoJBAADAQMAAgEEEgNVBg4K
EAoJBAADAQMAAgEGEgNVDxoKEAoJBAADAQMAAgEBEgNVGycKEAoJBAADAQMAAgEDEgNVKisK
OAoGBAADAQIAEgNZBBwaKSBBIGxpc3Qgb2YgY2FzY2FkaW5nIGlmLWVsc2UgY29uZGl0aW9u
cy4KCg4KBwQAAwECAAQSA1kEDAoOCgcEAAMBAgAGEgNZDREKDgoHBAADAQIAARIDWRIXCg4K
BwQAAwECAAMSA1kaGwpPCgQEAAMCEgRdAnYDGkEgR2VuZXJhdG9yIHNldHRpbmdzIHVzZWQg
YnkgdGhlIExMTSB0byBnZW5lcmF0ZSBhIHRleHQgcmVzcG9uc2UuCgoMCgUEAAMCARIDXQob
CpYBCgYEAAMCAgASBGEEZgYahQEgUmVxdWlyZWQuIFRoZSBnZW5lcmF0b3IgdG8gY2FsbC4K
IEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+
L2FnZW50cy88QWdlbnRJRD4vZ2VuZXJhdG9ycy88R2VuZXJhdG9ySUQ+YC4KCg4KBwQAAwIC
AAUSA2EECgoOCgcEAAMCAgABEgNhCxQKDgoHBAADAgIAAxIDYRcYCg8KBwQAAwICAAgSBGEZ
ZgUKEQoKBAADAgIACJwIABIDYgYsChEKCQQAAwICAAifCBIEYwZlBwrKBAoGBAADAgIBEgNy
BC0augQgTWFwIGZyb20gW3BsYWNlaG9sZGVyIHBhcmFtZXRlcl1bR2VuZXJhdG9yLlBhcmFt
ZXRlci5pZF0gaW4gdGhlCiBbR2VuZXJhdG9yXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5HZW5lcmF0b3JdIHRvIGNvcnJlc3BvbmRpbmcKIHNlc3Npb24gcGFyYW1ldGVycy4g
QnkgZGVmYXVsdCwgRGlhbG9nZmxvdyB1c2VzIHRoZSBzZXNzaW9uIHBhcmFtZXRlcgogd2l0
aCB0aGUgc2FtZSBuYW1lIHRvIGZpbGwgaW4gdGhlIGdlbmVyYXRvciB0ZW1wbGF0ZS4gZS5n
LiBJZiB0aGVyZSBpcyBhCiBwbGFjZWhvbGRlciBwYXJhbWV0ZXIgYGNpdHlgIGluIHRoZSBH
ZW5lcmF0b3IsIERpYWxvZ2Zsb3cgZGVmYXVsdCB0byBmaWxsCiBpbiB0aGUgYCRjaXR5YCB3
aXRoCiBgJHNlc3Npb24ucGFyYW1zLmNpdHlgLiBIb3dldmVyLCB5b3UgbWF5IGNob29zZSB0
byBmaWxsIGAkY2l0eWAgd2l0aAogYCRzZXNzaW9uLnBhcmFtcy5kZXNpbmF0aW9uLWNpdHlg
LgogLSBNYXAga2V5OiBbcGFyYW1ldGVyIElEXVtHZW5yYXRvci5QYXJhbWV0ZXIuaWRdCiAt
IE1hcCB2YWx1ZTogc2Vzc2lvbiBwYXJhbWV0ZXIgbmFtZQoKDgoHBAADAgIBBhIDcgQXCg4K
BwQAAwICAQESA3IYKAoOCgcEAAMCAgEDEgNyKywKWAoGBAADAgICEgN1BEkaSSBSZXF1aXJl
ZC4gT3V0cHV0IHBhcmFtZXRlciB3aGljaCBzaG91bGQgY29udGFpbiB0aGUgZ2VuZXJhdG9y
IHJlc3BvbnNlLgoKDgoHBAADAgICBRIDdQQKCg4KBwQAAwICAgESA3ULGwoOCgcEAAMCAgID
EgN1Hh8KDgoHBAADAgICCBIDdSBIChEKCgQAAwICAgicCAASA3UhRwpJCgQEAAIAEgN5Aiga
PCBUaGUgbGlzdCBvZiByaWNoIG1lc3NhZ2UgcmVzcG9uc2VzIHRvIHByZXNlbnQgdG8gdGhl
IHVzZXIuCgoMCgUEAAIABBIDeQIKCgwKBQQAAgAGEgN5CxoKDAoFBAACAAESA3kbIwoMCgUE
AAIAAxIDeSYnCoQBCgQEAAIBEgV+AoABBRp1IFRoZSB3ZWJob29rIHRvIGNhbGwuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2Vu
dHMvPEFnZW50SUQ+L3dlYmhvb2tzLzxXZWJob29rSUQ+YC4KCgwKBQQAAgEFEgN+AggKDAoF
BAACAQESA34JEAoMCgUEAAIBAxIDfhMUCg4KBQQAAgEIEgV+FYABBAoQCgcEAAIBCJ8IEgV+
FoABAwrnAwoEBAACAhIEiwECJBrYAyBXaGV0aGVyIERpYWxvZ2Zsb3cgc2hvdWxkIHJldHVy
biBjdXJyZW50bHkgcXVldWVkIGZ1bGZpbGxtZW50IHJlc3BvbnNlCiBtZXNzYWdlcyBpbiBz
dHJlYW1pbmcgQVBJcy4gSWYgYSB3ZWJob29rIGlzIHNwZWNpZmllZCwgaXQgaGFwcGVucyBi
ZWZvcmUKIERpYWxvZ2Zsb3cgaW52b2tlcyB3ZWJob29rLgogV2FybmluZzoKIDEpIFRoaXMg
ZmxhZyBvbmx5IGFmZmVjdHMgc3RyZWFtaW5nIEFQSS4gUmVzcG9uc2VzIGFyZSBzdGlsbCBx
dWV1ZWQKIGFuZCByZXR1cm5lZCBvbmNlIGluIG5vbi1zdHJlYW1pbmcgQVBJLgogMikgVGhl
IGZsYWcgY2FuIGJlIGVuYWJsZWQgaW4gYW55IGZ1bGZpbGxtZW50IGJ1dCBvbmx5IHRoZSBm
aXJzdCAzIHBhcnRpYWwKIHJlc3BvbnNlcyB3aWxsIGJlIHJldHVybmVkLiBZb3UgbWF5IG9u
bHkgd2FudCB0byBhcHBseSBpdCB0byBmdWxmaWxsbWVudHMKIHRoYXQgaGF2ZSBzbG93IHdl
Ymhvb2tzLgoKDQoFBAACAgUSBIsBAgYKDQoFBAACAgESBIsBBx8KDQoFBAACAgMSBIsBIiMK
kgMKBAQAAgMSBJQBAhEagwMgVGhlIHZhbHVlIG9mIHRoaXMgZmllbGQgd2lsbCBiZSBwb3B1
bGF0ZWQgaW4gdGhlCiBbV2ViaG9va1JlcXVlc3RdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzLldlYmhvb2tSZXF1ZXN0XQogYGZ1bGZpbGxtZW50SW5mby50YWdgIGZpZWxkIGJ5
IERpYWxvZ2Zsb3cgd2hlbiB0aGUgYXNzb2NpYXRlZCB3ZWJob29rIGlzCiBjYWxsZWQuCiBU
aGUgdGFnIGlzIHR5cGljYWxseSB1c2VkIGJ5IHRoZSB3ZWJob29rIHNlcnZpY2UgdG8gaWRl
bnRpZnkgd2hpY2gKIGZ1bGZpbGxtZW50IGlzIGJlaW5nIGNhbGxlZCwgYnV0IGl0IGNvdWxk
IGJlIHVzZWQgZm9yIG90aGVyIHB1cnBvc2VzLgogVGhpcyBmaWVsZCBpcyByZXF1aXJlZCBp
ZiBgd2ViaG9va2AgaXMgc3BlY2lmaWVkLgoKDQoFBAACAwUSBJQBAggKDQoFBAACAwESBJQB
CQwKDQoFBAACAwMSBJQBDxAKwAEKBAQAAgQSBJkBAksasQEgT3B0aW9uYWwuIFRoZSBuYW1l
IG9mIHRoZSBjb2RlIGJsb2NrIGZ1bmN0aW9uIHRvIGV4ZWN1dGUsIGlmIHRoaXMgaXMgYSBj
b2RlCiBibG9jayBmdWxmaWxsbWVudC4gVGhlIGNvZGUgYmxvY2sgaXRzZWxmIGlzIGltcGxp
ZWQgYnkgdGhlIGZ1bGZpbGxtZW50J3MKIHBhcmVudCwgZS5nLiBhIHBsYXlib29rLgoKDQoF
BAACBAUSBJkBAggKDQoFBAACBAESBJkBCRwKDQoFBAACBAMSBJkBHyEKDQoFBAACBAgSBJkB
IkoKEAoIBAACBAicCAASBJkBI0kKQgoEBAACBRIEnAECOBo0IFNldCBwYXJhbWV0ZXIgdmFs
dWVzIGJlZm9yZSBleGVjdXRpbmcgdGhlIHdlYmhvb2suCgoNCgUEAAIFBBIEnAECCgoNCgUE
AAIFBhIEnAELHQoNCgUEAAIFARIEnAEeMwoNCgUEAAIFAxIEnAE2Nwo3CgQEAAIGEgSfAQIy
GikgQ29uZGl0aW9uYWwgY2FzZXMgZm9yIHRoaXMgZnVsZmlsbG1lbnQuCgoNCgUEAAIGBBIE
nwECCgoNCgUEAAIGBhIEnwELGwoNCgUEAAIGARIEnwEcLQoNCgUEAAIGAxIEnwEwMQqiAQoE
BAACBxIEowECKRqTASBIaWVyYXJjaGljYWwgYWR2YW5jZWQgc2V0dGluZ3MgZm9yIHRoaXMg
ZnVsZmlsbG1lbnQuIFRoZSBzZXR0aW5ncyBleHBvc2VkCiBhdCB0aGUgbG93ZXIgbGV2ZWwg
b3ZlcnJpZGVzIHRoZSBzZXR0aW5ncyBleHBvc2VkIGF0IHRoZSBoaWdoZXIgbGV2ZWwuCgoN
CgUEAAIHBhIEowECEgoNCgUEAAIHARIEowETJAoNCgUEAAIHAxIEowEnKAq/AgoEBAACCBIE
qgECJxqwAiBJZiB0aGUgZmxhZyBpcyB0cnVlLCB0aGUgYWdlbnQgd2lsbCB1dGlsaXplIExM
TSB0byBnZW5lcmF0ZSBhIHRleHQKIHJlc3BvbnNlLiBJZiBMTE0gZ2VuZXJhdGlvbiBmYWls
cywgdGhlIGRlZmluZWQKIFtyZXNwb25zZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLkZ1bGZpbGxtZW50Lm1lc3NhZ2VzXSBpbiB0aGUKIGZ1bGZpbGxtZW50IHdpbGwgYmUg
cmVzcGVjdGVkLiBUaGlzIGZsYWcgaXMgb25seSB1c2VmdWwgZm9yIGZ1bGZpbGxtZW50cwog
YXNzb2NpYXRlZCB3aXRoIG5vLW1hdGNoIGV2ZW50IGhhbmRsZXJzLgoKDQoFBAACCAUSBKoB
AgYKDQoFBAACCAESBKoBByEKDQoFBAACCAMSBKoBJCYKSgoEBAACCRIErQECLRo8IEEgbGlz
dCBvZiBHZW5lcmF0b3JzIHRvIGJlIGNhbGxlZCBkdXJpbmcgdGhpcyBmdWxmaWxsbWVudC4K
Cg0KBQQAAgkEEgStAQIKCg0KBQQAAgkGEgStAQscCg0KBQQAAgkBEgStAR0nCg0KBQQAAgkD
EgStASosYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment ===
    # Fields for Fulfillment
    # Field: messages Type: 11 (.google.cloud.dialogflow.cx.v3.ResponseMessage)
    # Field: webhook Type: 9 ()
    # Field: return_partial_responses Type: 8 ()
    # Field: tag Type: 9 ()
    # Field: code_block_function Type: 9 ()
    # Field: set_parameter_actions Type: 11 (.google.cloud.dialogflow.cx.v3.Fulfillment.SetParameterAction)
    # Field: conditional_cases Type: 11 (.google.cloud.dialogflow.cx.v3.Fulfillment.ConditionalCases)
    # Field: advanced_settings Type: 11 (.google.cloud.dialogflow.cx.v3.AdvancedSettings)
    # Field: enable_generative_fallback Type: 8 ()
    # Field: generators Type: 11 (.google.cloud.dialogflow.cx.v3.Fulfillment.GeneratorSettings)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Fulfillment - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/fulfillment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Fulfillment;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment->new({
        messages => $messages,
        webhook => $webhook,
        return_partial_responses => $return_partial_responses,
        tag => $tag,
    });

    # Read or update a field
    my $val = $msg->messages();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/fulfillment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment

A fulfillment can do one or more of the following actions at the same time:

  * Generate rich message responses.
  * Set parameter values.
  * Call the webhook.

Fulfillments can be called at various stages in the
[Page][google.cloud.dialogflow.cx.v3.Page] or
[Form][google.cloud.dialogflow.cx.v3.Form] lifecycle. For example, when a
[DetectIntentRequest][google.cloud.dialogflow.cx.v3.DetectIntentRequest]
drives a session to enter a new page, the page's entry fulfillment can add a
static response to the
[QueryResult][google.cloud.dialogflow.cx.v3.QueryResult] in the returning
[DetectIntentResponse][google.cloud.dialogflow.cx.v3.DetectIntentResponse],
call the webhook (for example, to load user data from a database), or both.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage>)

The list of rich message responses to present to the user.

=item * C<< $msg->webhook() >> / C<< $msg->webhook($value) >>

Type: C<String>

The webhook to call.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/webhooks/<WebhookID>`.

=item * C<< $msg->return_partial_responses() >> / C<< $msg->return_partial_responses($value) >>

Type: C<Bool>

Whether Dialogflow should return currently queued fulfillment response
messages in streaming APIs. If a webhook is specified, it happens before
Dialogflow invokes webhook.
Warning:
1) This flag only affects streaming API. Responses are still queued
and returned once in non-streaming API.
2) The flag can be enabled in any fulfillment but only the first 3 partial
responses will be returned. You may only want to apply it to fulfillments
that have slow webhooks.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

The value of this field will be populated in the
[WebhookRequest][google.cloud.dialogflow.cx.v3.WebhookRequest]
`fulfillmentInfo.tag` field by Dialogflow when the associated webhook is
called.
The tag is typically used by the webhook service to identify which
fulfillment is being called, but it could be used for other purposes.
This field is required if `webhook` is specified.

=item * C<< $msg->code_block_function() >> / C<< $msg->code_block_function($value) >>

Type: C<String>

Optional. The name of the code block function to execute, if this is a code
block fulfillment. The code block itself is implied by the fulfillment's
parent, e.g. a playbook.

=item * C<< $msg->set_parameter_actions() >> / C<< $msg->set_parameter_actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment::SetParameterAction>)

Set parameter values before executing the webhook.

=item * C<< $msg->conditional_cases() >> / C<< $msg->conditional_cases($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment::ConditionalCases>)

Conditional cases for this fulfillment.

=item * C<< $msg->advanced_settings() >> / C<< $msg->advanced_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::AdvancedSettings::AdvancedSettings>)

Hierarchical advanced settings for this fulfillment. The settings exposed
at the lower level overrides the settings exposed at the higher level.

=item * C<< $msg->enable_generative_fallback() >> / C<< $msg->enable_generative_fallback($value) >>

Type: C<Bool>

If the flag is true, the agent will utilize LLM to generate a text
response. If LLM generation fails, the defined
[responses][google.cloud.dialogflow.cx.v3.Fulfillment.messages] in the
fulfillment will be respected. This flag is only useful for fulfillments
associated with no-match event handlers.

=item * C<< $msg->generators() >> / C<< $msg->generators($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Fulfillment::GeneratorSettings>)

A list of Generators to be called during this fulfillment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Fulfillment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
