package Google::Datastore::Admin::V1beta1::DatastoreAdmin;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZGF0YXN0b3JlL2FkbWluL3YxYmV0YTEvZGF0YXN0b3JlX2FkbWluLnByb3Rv
Eh5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsEECg5Db21tb25NZXRhZGF0YRI5CgpzdGFydF90
aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGVu
ZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZRJUCg5v
cGVyYXRpb25fdHlwZRgDIAEoDjItLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5P
cGVyYXRpb25UeXBlUg1vcGVyYXRpb25UeXBlElIKBmxhYmVscxgEIAMoCzI6Lmdvb2dsZS5k
YXRhc3RvcmUuYWRtaW4udjFiZXRhMS5Db21tb25NZXRhZGF0YS5MYWJlbHNFbnRyeVIGbGFi
ZWxzEkoKBXN0YXRlGAUgASgOMjQuZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGExLkNv
bW1vbk1ldGFkYXRhLlN0YXRlUgVzdGF0ZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIosBCgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEhAKDElOSVRJQUxJWklORxABEg4KClBST0NFU1NJTkcQAhIOCgpDQU5DRUxM
SU5HEAMSDgoKRklOQUxJWklORxAEEg4KClNVQ0NFU1NGVUwQBRIKCgZGQUlMRUQQBhINCglD
QU5DRUxMRUQQByJYCghQcm9ncmVzcxIlCg53b3JrX2NvbXBsZXRlZBgBIAEoA1INd29ya0Nv
bXBsZXRlZBIlCg53b3JrX2VzdGltYXRlZBgCIAEoA1INd29ya0VzdGltYXRlZCLLAgoVRXhw
b3J0RW50aXRpZXNSZXF1ZXN0Eh0KCnByb2plY3RfaWQYASABKAlSCXByb2plY3RJZBJZCgZs
YWJlbHMYAiADKAsyQS5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RW50
aXRpZXNSZXF1ZXN0LkxhYmVsc0VudHJ5UgZsYWJlbHMSUQoNZW50aXR5X2ZpbHRlchgDIAEo
CzIsLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5FbnRpdHlGaWx0ZXJSDGVudGl0
eUZpbHRlchIqChFvdXRwdXRfdXJsX3ByZWZpeBgEIAEoCVIPb3V0cHV0VXJsUHJlZml4GjkK
C0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC
OAEivAIKFUltcG9ydEVudGl0aWVzUmVxdWVzdBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9q
ZWN0SWQSWQoGbGFiZWxzGAIgAygLMkEuZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGEx
LkltcG9ydEVudGl0aWVzUmVxdWVzdC5MYWJlbHNFbnRyeVIGbGFiZWxzEhsKCWlucHV0X3Vy
bBgDIAEoCVIIaW5wdXRVcmwSUQoNZW50aXR5X2ZpbHRlchgEIAEoCzIsLmdvb2dsZS5kYXRh
c3RvcmUuYWRtaW4udjFiZXRhMS5FbnRpdHlGaWx0ZXJSDGVudGl0eUZpbHRlcho5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIjcK
FkV4cG9ydEVudGl0aWVzUmVzcG9uc2USHQoKb3V0cHV0X3VybBgBIAEoCVIJb3V0cHV0VXJs
IocDChZFeHBvcnRFbnRpdGllc01ldGFkYXRhEkYKBmNvbW1vbhgBIAEoCzIuLmdvb2dsZS5k
YXRhc3RvcmUuYWRtaW4udjFiZXRhMS5Db21tb25NZXRhZGF0YVIGY29tbW9uElUKEXByb2dy
ZXNzX2VudGl0aWVzGAIgASgLMiguZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGExLlBy
b2dyZXNzUhBwcm9ncmVzc0VudGl0aWVzEk8KDnByb2dyZXNzX2J5dGVzGAMgASgLMiguZ29v
Z2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGExLlByb2dyZXNzUg1wcm9ncmVzc0J5dGVzElEK
DWVudGl0eV9maWx0ZXIYBCABKAsyLC5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEu
RW50aXR5RmlsdGVyUgxlbnRpdHlGaWx0ZXISKgoRb3V0cHV0X3VybF9wcmVmaXgYBSABKAlS
D291dHB1dFVybFByZWZpeCL4AgoWSW1wb3J0RW50aXRpZXNNZXRhZGF0YRJGCgZjb21tb24Y
ASABKAsyLi5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuQ29tbW9uTWV0YWRhdGFS
BmNvbW1vbhJVChFwcm9ncmVzc19lbnRpdGllcxgCIAEoCzIoLmdvb2dsZS5kYXRhc3RvcmUu
YWRtaW4udjFiZXRhMS5Qcm9ncmVzc1IQcHJvZ3Jlc3NFbnRpdGllcxJPCg5wcm9ncmVzc19i
eXRlcxgDIAEoCzIoLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5Qcm9ncmVzc1IN
cHJvZ3Jlc3NCeXRlcxJRCg1lbnRpdHlfZmlsdGVyGAQgASgLMiwuZ29vZ2xlLmRhdGFzdG9y
ZS5hZG1pbi52MWJldGExLkVudGl0eUZpbHRlclIMZW50aXR5RmlsdGVyEhsKCWlucHV0X3Vy
bBgFIAEoCVIIaW5wdXRVcmwiSQoMRW50aXR5RmlsdGVyEhQKBWtpbmRzGAEgAygJUgVraW5k
cxIjCg1uYW1lc3BhY2VfaWRzGAIgAygJUgxuYW1lc3BhY2VJZHMqWQoNT3BlcmF0aW9uVHlw
ZRIeChpPUEVSQVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEhMKD0VYUE9SVF9FTlRJVElFUxAB
EhMKD0lNUE9SVF9FTlRJVElFUxACMsYCCg5EYXRhc3RvcmVBZG1pbhKYAQoORXhwb3J0RW50
aXRpZXMSNS5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RW50aXRpZXNS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiIwgtPkkwIqIiUvdjFiZXRh
MS9wcm9qZWN0cy97cHJvamVjdF9pZH06ZXhwb3J0OgEqEpgBCg5JbXBvcnRFbnRpdGllcxI1
Lmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5JbXBvcnRFbnRpdGllc1JlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIjCC0+STAioiJS92MWJldGExL3Byb2pl
Y3RzL3twcm9qZWN0X2lkfTppbXBvcnQ6ASpCzQEKImNvbS5nb29nbGUuZGF0YXN0b3JlLmFk
bWluLnYxYmV0YTFCE0RhdGFzdG9yZUFkbWluUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9n
by9kYXRhc3RvcmUvYWRtaW4vYXBpdjFiZXRhMS9hZG1pbnBiO2FkbWlucGKqAiRHb29nbGUu
Q2xvdWQuRGF0YXN0b3JlLkFkbWluLlYxQmV0YTHqAihHb29nbGU6OkNsb3VkOjpEYXRhc3Rv
cmU6OkFkbWluOjpWMWJldGExSs5kCgcSBQ4AywIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACYKCQoCAwESAxMALQoJCgIDAhIDFAAp
CggKAQgSAxYAQQoJCgIIJRIDFgBBCggKAQgSAxcAVQoJCgIICxIDFwBVCggKAQgSAxgAIgoJ
CgIIChIDGAAiCggKAQgSAxkANAoJCgIICBIDGQA0CggKAQgSAxoAOwoJCgIIARIDGgA7CggK
AQgSAxsAQQoJCgIILRIDGwBBCtkPCgIGABIEUABtARrMDyBHb29nbGUgQ2xvdWQgRGF0YXN0
b3JlIEFkbWluIEFQSQoKIFRoZSBEYXRhc3RvcmUgQWRtaW4gQVBJIHByb3ZpZGVzIHNldmVy
YWwgYWRtaW4gc2VydmljZXMgZm9yIENsb3VkIERhdGFzdG9yZS4KCiAtLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLQogIyMgQ29uY2VwdHMKCiBQcm9qZWN0LCBuYW1lc3BhY2UsIGtpbmQsIGFu
ZCBlbnRpdHkgYXMgZGVmaW5lZCBpbiB0aGUgR29vZ2xlIENsb3VkIERhdGFzdG9yZQogQVBJ
LgoKIE9wZXJhdGlvbjogQW4gT3BlcmF0aW9uIHJlcHJlc2VudHMgd29yayBiZWluZyBwZXJm
b3JtZWQgaW4gdGhlIGJhY2tncm91bmQuCgogRW50aXR5RmlsdGVyOiBBbGxvd3Mgc3BlY2lm
eWluZyBhIHN1YnNldCBvZiBlbnRpdGllcyBpbiBhIHByb2plY3QuIFRoaXMgaXMKIHNwZWNp
ZmllZCBhcyBhIGNvbWJpbmF0aW9uIG9mIGtpbmRzIGFuZCBuYW1lc3BhY2VzIChlaXRoZXIg
b3IgYm90aCBvZiB3aGljaAogbWF5IGJlIGFsbCkuCgogLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0KICMjIFNlcnZpY2VzCgogIyBFeHBvcnQvSW1wb3J0CgogVGhlIEV4cG9ydC9JbXBvcnQg
c2VydmljZSBwcm92aWRlcyB0aGUgYWJpbGl0eSB0byBjb3B5IGFsbCBvciBhIHN1YnNldCBv
ZgogZW50aXRpZXMgdG8vZnJvbSBHb29nbGUgQ2xvdWQgU3RvcmFnZS4KCiBFeHBvcnRlZCBk
YXRhIG1heSBiZSBpbXBvcnRlZCBpbnRvIENsb3VkIERhdGFzdG9yZSBmb3IgYW55IEdvb2ds
ZSBDbG91ZAogUGxhdGZvcm0gcHJvamVjdC4gSXQgaXMgbm90IHJlc3RyaWN0ZWQgdG8gdGhl
IGV4cG9ydCBzb3VyY2UgcHJvamVjdC4gSXQgaXMKIHBvc3NpYmxlIHRvIGV4cG9ydCBmcm9t
IG9uZSBwcm9qZWN0IGFuZCB0aGVuIGltcG9ydCBpbnRvIGFub3RoZXIuCgogRXhwb3J0ZWQg
ZGF0YSBjYW4gYWxzbyBiZSBsb2FkZWQgaW50byBHb29nbGUgQmlnUXVlcnkgZm9yIGFuYWx5
c2lzLgoKIEV4cG9ydHMgYW5kIGltcG9ydHMgYXJlIHBlcmZvcm1lZCBhc3luY2hyb25vdXNs
eS4gQW4gT3BlcmF0aW9uIHJlc291cmNlIGlzCiBjcmVhdGVkIGZvciBlYWNoIGV4cG9ydC9p
bXBvcnQuIFRoZSBzdGF0ZSAoaW5jbHVkaW5nIGFueSBlcnJvcnMgZW5jb3VudGVyZWQpCiBv
ZiB0aGUgZXhwb3J0L2ltcG9ydCBtYXkgYmUgcXVlcmllZCB2aWEgdGhlIE9wZXJhdGlvbiBy
ZXNvdXJjZS4KCiAjIE9wZXJhdGlvbgoKIFRoZSBPcGVyYXRpb25zIGNvbGxlY3Rpb24gcHJv
dmlkZXMgYSByZWNvcmQgb2YgYWN0aW9ucyBwZXJmb3JtZWQgZm9yIHRoZQogc3BlY2lmaWVk
IHByb2plY3QgKGluY2x1ZGluZyBhbnkgb3BlcmF0aW9ucyBpbiBwcm9ncmVzcykuIE9wZXJh
dGlvbnMgYXJlIG5vdAogY3JlYXRlZCBkaXJlY3RseSBidXQgdGhyb3VnaCBjYWxscyBvbiBv
dGhlciBjb2xsZWN0aW9ucyBvciByZXNvdXJjZXMuCgogQW4gb3BlcmF0aW9uIHRoYXQgaXMg
bm90IHlldCBkb25lIG1heSBiZSBjYW5jZWxsZWQuIFRoZSByZXF1ZXN0IHRvIGNhbmNlbCBp
cwogYXN5bmNocm9ub3VzIGFuZCB0aGUgb3BlcmF0aW9uIG1heSBjb250aW51ZSB0byBydW4g
Zm9yIHNvbWUgdGltZSBhZnRlciB0aGUKIHJlcXVlc3QgdG8gY2FuY2VsIGlzIG1hZGUuCgog
QW4gb3BlcmF0aW9uIHRoYXQgaXMgZG9uZSBtYXkgYmUgZGVsZXRlZCBzbyB0aGF0IGl0IGlz
IG5vIGxvbmdlciBsaXN0ZWQgYXMKIHBhcnQgb2YgdGhlIE9wZXJhdGlvbiBjb2xsZWN0aW9u
LgoKIExpc3RPcGVyYXRpb25zIHJldHVybnMgYWxsIHBlbmRpbmcgb3BlcmF0aW9ucywgYnV0
IG5vdCBjb21wbGV0ZWQgb3BlcmF0aW9ucy4KCiBPcGVyYXRpb25zIGFyZSBjcmVhdGVkIGJ5
IHNlcnZpY2UgRGF0YXN0b3JlQWRtaW4sCiBidXQgYXJlIGFjY2Vzc2VkIHZpYSBzZXJ2aWNl
IGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLgoKCgoDBgABEgNQCBYKlwQKBAYAAgAS
BFkCXwMaiAQgRXhwb3J0cyBhIGNvcHkgb2YgYWxsIG9yIGEgc3Vic2V0IG9mIGVudGl0aWVz
IGZyb20gR29vZ2xlIENsb3VkIERhdGFzdG9yZQogdG8gYW5vdGhlciBzdG9yYWdlIHN5c3Rl
bSwgc3VjaCBhcyBHb29nbGUgQ2xvdWQgU3RvcmFnZS4gUmVjZW50IHVwZGF0ZXMgdG8KIGVu
dGl0aWVzIG1heSBub3QgYmUgcmVmbGVjdGVkIGluIHRoZSBleHBvcnQuIFRoZSBleHBvcnQg
b2NjdXJzIGluIHRoZQogYmFja2dyb3VuZCBhbmQgaXRzIHByb2dyZXNzIGNhbiBiZSBtb25p
dG9yZWQgYW5kIG1hbmFnZWQgdmlhIHRoZQogT3BlcmF0aW9uIHJlc291cmNlIHRoYXQgaXMg
Y3JlYXRlZC4gVGhlIG91dHB1dCBvZiBhbiBleHBvcnQgbWF5IG9ubHkgYmUKIHVzZWQgb25j
ZSB0aGUgYXNzb2NpYXRlZCBvcGVyYXRpb24gaXMgZG9uZS4gSWYgYW4gZXhwb3J0IG9wZXJh
dGlvbiBpcwogY2FuY2VsbGVkIGJlZm9yZSBjb21wbGV0aW9uIGl0IG1heSBsZWF2ZSBwYXJ0
aWFsIGRhdGEgYmVoaW5kIGluIEdvb2dsZQogQ2xvdWQgU3RvcmFnZS4KCgwKBQYAAgABEgNZ
BhQKDAoFBgACAAISA1kVKgoMCgUGAAIAAxIDWg8rCg0KBQYAAgAEEgRbBF4GChEKCQYAAgAE
sMq8IhIEWwReBgr5AgoEBgACARIEZgJsAxrqAiBJbXBvcnRzIGVudGl0aWVzIGludG8gR29v
Z2xlIENsb3VkIERhdGFzdG9yZS4gRXhpc3RpbmcgZW50aXRpZXMgd2l0aCB0aGUKIHNhbWUg
a2V5IGFyZSBvdmVyd3JpdHRlbi4gVGhlIGltcG9ydCBvY2N1cnMgaW4gdGhlIGJhY2tncm91
bmQgYW5kIGl0cwogcHJvZ3Jlc3MgY2FuIGJlIG1vbml0b3JlZCBhbmQgbWFuYWdlZCB2aWEg
dGhlIE9wZXJhdGlvbiByZXNvdXJjZSB0aGF0IGlzCiBjcmVhdGVkLiBJZiBhbiBJbXBvcnRF
bnRpdGllcyBvcGVyYXRpb24gaXMgY2FuY2VsbGVkLCBpdCBpcyBwb3NzaWJsZQogdGhhdCBh
IHN1YnNldCBvZiB0aGUgZGF0YSBoYXMgYWxyZWFkeSBiZWVuIGltcG9ydGVkIHRvIENsb3Vk
IERhdGFzdG9yZS4KCgwKBQYAAgEBEgNmBhQKDAoFBgACAQISA2YVKgoMCgUGAAIBAxIDZw8r
Cg0KBQYAAgEEEgRoBGsGChEKCQYAAgEEsMq8IhIEaARrBgpBCgIEABIFcACeAQEaNCBNZXRh
ZGF0YSBjb21tb24gdG8gYWxsIERhdGFzdG9yZSBBZG1pbiBvcGVyYXRpb25zLgoKCgoDBAAB
EgNwCBYKRgoEBAAEABIFcgKMAQMaNyBUaGUgdmFyaW91cyBwb3NzaWJsZSBzdGF0ZXMgZm9y
IGFuIG9uZ29pbmcgT3BlcmF0aW9uLgoKDAoFBAAEAAESA3IHDAodCgYEAAQAAgASA3QEGhoO
IFVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDdAQVCg4KBwQABAACAAISA3QYGQo6CgYEAAQA
AgESA3cEFRorIFJlcXVlc3QgaXMgYmVpbmcgcHJlcGFyZWQgZm9yIHByb2Nlc3NpbmcuCgoO
CgcEAAQAAgEBEgN3BBAKDgoHBAAEAAIBAhIDdxMUCjUKBgQABAACAhIDegQTGiYgUmVxdWVz
dCBpcyBhY3RpdmVseSBiZWluZyBwcm9jZXNzZWQuCgoOCgcEAAQAAgIBEgN6BA4KDgoHBAAE
AAICAhIDehESCpEBCgYEAAQAAgMSA34EExqBASBSZXF1ZXN0IGlzIGluIHRoZSBwcm9jZXNz
IG9mIGJlaW5nIGNhbmNlbGxlZCBhZnRlciB1c2VyIGNhbGxlZAogZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbnMuQ2FuY2VsT3BlcmF0aW9uIG9uIHRoZSBvcGVyYXRpb24uCgoOCgcE
AAQAAgMBEgN+BA4KDgoHBAAEAAIDAhIDfhESCk4KBgQABAACBBIEgQEEExo+IFJlcXVlc3Qg
aGFzIGJlZW4gcHJvY2Vzc2VkIGFuZCBpcyBpbiBpdHMgZmluYWxpemF0aW9uIHN0YWdlLgoK
DwoHBAAEAAIEARIEgQEEDgoPCgcEAAQAAgQCEgSBARESCjUKBgQABAACBRIEhAEEExolIFJl
cXVlc3QgaGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoPCgcEAAQAAgUBEgSEAQQOCg8K
BwQABAACBQISBIQBERIKUQoGBAAEAAIGEgSHAQQPGkEgUmVxdWVzdCBoYXMgZmluaXNoZWQg
YmVpbmcgcHJvY2Vzc2VkLCBidXQgZW5jb3VudGVyZWQgYW4gZXJyb3IuCgoPCgcEAAQAAgYB
EgSHAQQKCg8KBwQABAACBgISBIcBDQ4KeAoGBAAEAAIHEgSLAQQSGmggUmVxdWVzdCBoYXMg
ZmluaXNoZWQgYmVpbmcgY2FuY2VsbGVkIGFmdGVyIHVzZXIgY2FsbGVkCiBnb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9ucy5DYW5jZWxPcGVyYXRpb24uCgoPCgcEAAQAAgcBEgSLAQQN
Cg8KBwQABAACBwISBIsBEBEKOgoEBAACABIEjwECKxosIFRoZSB0aW1lIHRoYXQgd29yayBi
ZWdhbiBvbiB0aGUgb3BlcmF0aW9uLgoKDQoFBAACAAYSBI8BAhsKDQoFBAACAAESBI8BHCYK
DQoFBAACAAMSBI8BKSoKTwoEBAACARIEkgECKRpBIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24g
ZW5kZWQsIGVpdGhlciBzdWNjZXNzZnVsbHkgb3Igb3RoZXJ3aXNlLgoKDQoFBAACAQYSBJIB
AhsKDQoFBAACAQESBJIBHCQKDQoFBAACAQMSBJIBJygKXQoEBAACAhIElgECIxpPIFRoZSB0
eXBlIG9mIHRoZSBvcGVyYXRpb24uIENhbiBiZSB1c2VkIGFzIGEgZmlsdGVyIGluCiBMaXN0
T3BlcmF0aW9uc1JlcXVlc3QuCgoNCgUEAAICBhIElgECDwoNCgUEAAICARIElgEQHgoNCgUE
AAICAxIElgEhIgqDAQoEBAACAxIEmgECIRp1IFRoZSBjbGllbnQtYXNzaWduZWQgbGFiZWxz
IHdoaWNoIHdlcmUgcHJvdmlkZWQgd2hlbiB0aGUgb3BlcmF0aW9uIHdhcwogY3JlYXRlZC4g
TWF5IGFsc28gaW5jbHVkZSBhZGRpdGlvbmFsIGxhYmVscy4KCg0KBQQAAgMGEgSaAQIVCg0K
BQQAAgMBEgSaARYcCg0KBQQAAgMDEgSaAR8gCjMKBAQAAgQSBJ0BAhIaJSBUaGUgY3VycmVu
dCBzdGF0ZSBvZiB0aGUgT3BlcmF0aW9uLgoKDQoFBAACBAYSBJ0BAgcKDQoFBAACBAESBJ0B
CA0KDQoFBAACBAMSBJ0BEBEKPQoCBAESBqEBAKkBARovIE1lYXN1cmVzIHRoZSBwcm9ncmVz
cyBvZiBhIHBhcnRpY3VsYXIgbWV0cmljLgoKCwoDBAEBEgShAQgQCm8KBAQBAgASBKQBAhsa
YSBUaGUgYW1vdW50IG9mIHdvcmsgdGhhdCBoYXMgYmVlbiBjb21wbGV0ZWQuIE5vdGUgdGhh
dCB0aGlzIG1heSBiZSBncmVhdGVyCiB0aGFuIHdvcmtfZXN0aW1hdGVkLgoKDQoFBAECAAUS
BKQBAgcKDQoFBAECAAESBKQBCBYKDQoFBAECAAMSBKQBGRoKdQoEBAECARIEqAECGxpnIEFu
IGVzdGltYXRlIG9mIGhvdyBtdWNoIHdvcmsgbmVlZHMgdG8gYmUgcGVyZm9ybWVkLiBNYXkg
YmUgemVybyBpZiB0aGUKIHdvcmsgZXN0aW1hdGUgaXMgdW5hdmFpbGFibGUuCgoNCgUEAQIB
BRIEqAECBwoNCgUEAQIBARIEqAEIFgoNCgUEAQIBAxIEqAEZGgqfAQoCBAISBq0BAMoBARqQ
ASBUaGUgcmVxdWVzdCBmb3IKIFtnb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRGF0
YXN0b3JlQWRtaW4uRXhwb3J0RW50aXRpZXNdW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFi
ZXRhMS5EYXRhc3RvcmVBZG1pbi5FeHBvcnRFbnRpdGllc10uCgoLCgMEAgESBK0BCB0KPQoE
BAICABIErwECGBovIFByb2plY3QgSUQgYWdhaW5zdCB3aGljaCB0byBtYWtlIHRoZSByZXF1
ZXN0LgoKDQoFBAICAAUSBK8BAggKDQoFBAICAAESBK8BCRMKDQoFBAICAAMSBK8BFhcKJwoE
BAICARIEsgECIRoZIENsaWVudC1hc3NpZ25lZCBsYWJlbHMuCgoNCgUEAgIBBhIEsgECFQoN
CgUEAgIBARIEsgEWHAoNCgUEAgIBAxIEsgEfIApUCgQEAgICEgS1AQIhGkYgRGVzY3JpcHRp
b24gb2Ygd2hhdCBkYXRhIGZyb20gdGhlIHByb2plY3QgaXMgaW5jbHVkZWQgaW4gdGhlIGV4
cG9ydC4KCg0KBQQCAgIGEgS1AQIOCg0KBQQCAgIBEgS1AQ8cCg0KBQQCAgIDEgS1AR8gCqAI
CgQEAgIDEgTJAQIfGpEIIExvY2F0aW9uIGZvciB0aGUgZXhwb3J0IG1ldGFkYXRhIGFuZCBk
YXRhIGZpbGVzLgoKIFRoZSBmdWxsIHJlc291cmNlIFVSTCBvZiB0aGUgZXh0ZXJuYWwgc3Rv
cmFnZSBsb2NhdGlvbi4gQ3VycmVudGx5LCBvbmx5CiBHb29nbGUgQ2xvdWQgU3RvcmFnZSBp
cyBzdXBwb3J0ZWQuIFNvIG91dHB1dF91cmxfcHJlZml4IHNob3VsZCBiZSBvZiB0aGUKIGZv
cm06IGBnczovL0JVQ0tFVF9OQU1FWy9OQU1FU1BBQ0VfUEFUSF1gLCB3aGVyZSBgQlVDS0VU
X05BTUVgIGlzIHRoZQogbmFtZSBvZiB0aGUgQ2xvdWQgU3RvcmFnZSBidWNrZXQgYW5kIGBO
QU1FU1BBQ0VfUEFUSGAgaXMgYW4gb3B0aW9uYWwgQ2xvdWQKIFN0b3JhZ2UgbmFtZXNwYWNl
IHBhdGggKHRoaXMgaXMgbm90IGEgQ2xvdWQgRGF0YXN0b3JlIG5hbWVzcGFjZSkuIEZvciBt
b3JlCiBpbmZvcm1hdGlvbiBhYm91dCBDbG91ZCBTdG9yYWdlIG5hbWVzcGFjZSBwYXRocywg
c2VlCiBbT2JqZWN0IG5hbWUKIGNvbnNpZGVyYXRpb25zXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vc3RvcmFnZS9kb2NzL25hbWluZyNvYmplY3QtY29uc2lkZXJhdGlvbnMpLgoKIFRo
ZSByZXN1bHRpbmcgZmlsZXMgd2lsbCBiZSBuZXN0ZWQgZGVlcGVyIHRoYW4gdGhlIHNwZWNp
ZmllZCBVUkwgcHJlZml4LgogVGhlIGZpbmFsIG91dHB1dCBVUkwgd2lsbCBiZSBwcm92aWRl
ZCBpbiB0aGUKIFtnb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RW50aXRp
ZXNSZXNwb25zZS5vdXRwdXRfdXJsXVtnb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEu
RXhwb3J0RW50aXRpZXNSZXNwb25zZS5vdXRwdXRfdXJsXQogZmllbGQuIFRoYXQgdmFsdWUg
c2hvdWxkIGJlIHVzZWQgZm9yIHN1YnNlcXVlbnQgSW1wb3J0RW50aXRpZXMgb3BlcmF0aW9u
cy4KCiBCeSBuZXN0aW5nIHRoZSBkYXRhIGZpbGVzIGRlZXBlciwgdGhlIHNhbWUgQ2xvdWQg
U3RvcmFnZSBidWNrZXQgY2FuIGJlIHVzZWQKIGluIG11bHRpcGxlIEV4cG9ydEVudGl0aWVz
IG9wZXJhdGlvbnMgd2l0aG91dCBjb25mbGljdC4KCg0KBQQCAgMFEgTJAQIICg0KBQQCAgMB
EgTJAQkaCg0KBQQCAgMDEgTJAR0eCp8BCgIEAxIGzgEA6QEBGpABIFRoZSByZXF1ZXN0IGZv
cgogW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5EYXRhc3RvcmVBZG1pbi5JbXBv
cnRFbnRpdGllc11bZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGExLkRhdGFzdG9yZUFk
bWluLkltcG9ydEVudGl0aWVzXS4KCgsKAwQDARIEzgEIHQo9CgQEAwIAEgTQAQIYGi8gUHJv
amVjdCBJRCBhZ2FpbnN0IHdoaWNoIHRvIG1ha2UgdGhlIHJlcXVlc3QuCgoNCgUEAwIABRIE
0AECCAoNCgUEAwIAARIE0AEJEwoNCgUEAwIAAxIE0AEWFwonCgQEAwIBEgTTAQIhGhkgQ2xp
ZW50LWFzc2lnbmVkIGxhYmVscy4KCg0KBQQDAgEGEgTTAQIVCg0KBQQDAgEBEgTTARYcCg0K
BQQDAgEDEgTTAR8gCrMGCgQEAwICEgTiAQIXGqQGIFRoZSBmdWxsIHJlc291cmNlIFVSTCBv
ZiB0aGUgZXh0ZXJuYWwgc3RvcmFnZSBsb2NhdGlvbi4gQ3VycmVudGx5LCBvbmx5CiBHb29n
bGUgQ2xvdWQgU3RvcmFnZSBpcyBzdXBwb3J0ZWQuIFNvIGlucHV0X3VybCBzaG91bGQgYmUg
b2YgdGhlIGZvcm06CiBgZ3M6Ly9CVUNLRVRfTkFNRVsvTkFNRVNQQUNFX1BBVEhdL09WRVJB
TExfRVhQT1JUX01FVEFEQVRBX0ZJTEVgLCB3aGVyZQogYEJVQ0tFVF9OQU1FYCBpcyB0aGUg
bmFtZSBvZiB0aGUgQ2xvdWQgU3RvcmFnZSBidWNrZXQsIGBOQU1FU1BBQ0VfUEFUSGAgaXMK
IGFuIG9wdGlvbmFsIENsb3VkIFN0b3JhZ2UgbmFtZXNwYWNlIHBhdGggKHRoaXMgaXMgbm90
IGEgQ2xvdWQgRGF0YXN0b3JlCiBuYW1lc3BhY2UpLCBhbmQgYE9WRVJBTExfRVhQT1JUX01F
VEFEQVRBX0ZJTEVgIGlzIHRoZSBtZXRhZGF0YSBmaWxlIHdyaXR0ZW4KIGJ5IHRoZSBFeHBv
cnRFbnRpdGllcyBvcGVyYXRpb24uIEZvciBtb3JlIGluZm9ybWF0aW9uIGFib3V0IENsb3Vk
IFN0b3JhZ2UKIG5hbWVzcGFjZSBwYXRocywgc2VlCiBbT2JqZWN0IG5hbWUKIGNvbnNpZGVy
YXRpb25zXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3RvcmFnZS9kb2NzL25hbWluZyNv
YmplY3QtY29uc2lkZXJhdGlvbnMpLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtn
b29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RW50aXRpZXNSZXNwb25zZS5v
dXRwdXRfdXJsXVtnb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RW50aXRp
ZXNSZXNwb25zZS5vdXRwdXRfdXJsXS4KCg0KBQQDAgIFEgTiAQIICg0KBQQDAgIBEgTiAQkS
Cg0KBQQDAgIDEgTiARUWCqsCCgQEAwIDEgToAQIhGpwCIE9wdGlvbmFsbHkgc3BlY2lmeSB3
aGljaCBraW5kcy9uYW1lc3BhY2VzIGFyZSB0byBiZSBpbXBvcnRlZC4gSWYgcHJvdmlkZWQs
CiB0aGUgbGlzdCBtdXN0IGJlIGEgc3Vic2V0IG9mIHRoZSBFbnRpdHlGaWx0ZXIgdXNlZCBp
biBjcmVhdGluZyB0aGUgZXhwb3J0LAogb3RoZXJ3aXNlIGEgRkFJTEVEX1BSRUNPTkRJVElP
TiBlcnJvciB3aWxsIGJlIHJldHVybmVkLiBJZiBubyBmaWx0ZXIgaXMKIHNwZWNpZmllZCB0
aGVuIGFsbCBlbnRpdGllcyBmcm9tIHRoZSBleHBvcnQgYXJlIGltcG9ydGVkLgoKDQoFBAMC
AwYSBOgBAg4KDQoFBAMCAwESBOgBDxwKDQoFBAMCAwMSBOgBHyAKoAEKAgQEEgbtAQDzAQEa
kQEgVGhlIHJlc3BvbnNlIGZvcgogW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5E
YXRhc3RvcmVBZG1pbi5FeHBvcnRFbnRpdGllc11bZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52
MWJldGExLkRhdGFzdG9yZUFkbWluLkV4cG9ydEVudGl0aWVzXS4KCgsKAwQEARIE7QEIHgrR
AgoEBAQCABIE8gECGBrCAiBMb2NhdGlvbiBvZiB0aGUgb3V0cHV0IG1ldGFkYXRhIGZpbGUu
IFRoaXMgY2FuIGJlIHVzZWQgdG8gYmVnaW4gYW4gaW1wb3J0CiBpbnRvIENsb3VkIERhdGFz
dG9yZSAodGhpcyBwcm9qZWN0IG9yIGFub3RoZXIgcHJvamVjdCkuIFNlZQogW2dvb2dsZS5k
YXRhc3RvcmUuYWRtaW4udjFiZXRhMS5JbXBvcnRFbnRpdGllc1JlcXVlc3QuaW5wdXRfdXJs
XVtnb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxYmV0YTEuSW1wb3J0RW50aXRpZXNSZXF1ZXN0
LmlucHV0X3VybF0uCiBPbmx5IHByZXNlbnQgaWYgdGhlIG9wZXJhdGlvbiBjb21wbGV0ZWQg
c3VjY2Vzc2Z1bGx5LgoKDQoFBAQCAAUSBPIBAggKDQoFBAQCAAESBPIBCRMKDQoFBAQCAAMS
BPIBFhcKNwoCBAUSBvYBAIkCARopIE1ldGFkYXRhIGZvciBFeHBvcnRFbnRpdGllcyBvcGVy
YXRpb25zLgoKCwoDBAUBEgT2AQgeCkIKBAQFAgASBPgBAhwaNCBNZXRhZGF0YSBjb21tb24g
dG8gYWxsIERhdGFzdG9yZSBBZG1pbiBvcGVyYXRpb25zLgoKDQoFBAUCAAYSBPgBAhAKDQoF
BAUCAAESBPgBERcKDQoFBAUCAAMSBPgBGhsKQAoEBAUCARIE+wECIRoyIEFuIGVzdGltYXRl
IG9mIHRoZSBudW1iZXIgb2YgZW50aXRpZXMgcHJvY2Vzc2VkLgoKDQoFBAUCAQYSBPsBAgoK
DQoFBAUCAQESBPsBCxwKDQoFBAUCAQMSBPsBHyAKPQoEBAUCAhIE/gECHhovIEFuIGVzdGlt
YXRlIG9mIHRoZSBudW1iZXIgb2YgYnl0ZXMgcHJvY2Vzc2VkLgoKDQoFBAUCAgYSBP4BAgoK
DQoFBAUCAgESBP4BCxkKDQoFBAUCAgMSBP4BHB0KQQoEBAUCAxIEgQICIRozIERlc2NyaXB0
aW9uIG9mIHdoaWNoIGVudGl0aWVzIGFyZSBiZWluZyBleHBvcnRlZC4KCg0KBQQFAgMGEgSB
AgIOCg0KBQQFAgMBEgSBAg8cCg0KBQQFAgMDEgSBAh8gCq8DCgQEBQIEEgSIAgIfGqADIExv
Y2F0aW9uIGZvciB0aGUgZXhwb3J0IG1ldGFkYXRhIGFuZCBkYXRhIGZpbGVzLiBUaGlzIHdp
bGwgYmUgdGhlIHNhbWUKIHZhbHVlIGFzIHRoZQogW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4u
djFiZXRhMS5FeHBvcnRFbnRpdGllc1JlcXVlc3Qub3V0cHV0X3VybF9wcmVmaXhdW2dvb2ds
ZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5FeHBvcnRFbnRpdGllc1JlcXVlc3Qub3V0cHV0
X3VybF9wcmVmaXhdCiBmaWVsZC4gVGhlIGZpbmFsIG91dHB1dCBsb2NhdGlvbiBpcyBwcm92
aWRlZCBpbgogW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5FeHBvcnRFbnRpdGll
c1Jlc3BvbnNlLm91dHB1dF91cmxdW2dvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjFiZXRhMS5F
eHBvcnRFbnRpdGllc1Jlc3BvbnNlLm91dHB1dF91cmxdLgoKDQoFBAUCBAUSBIgCAggKDQoF
BAUCBAESBIgCCRoKDQoFBAUCBAMSBIgCHR4KNwoCBAYSBowCAJ4CARopIE1ldGFkYXRhIGZv
ciBJbXBvcnRFbnRpdGllcyBvcGVyYXRpb25zLgoKCwoDBAYBEgSMAggeCkIKBAQGAgASBI4C
AhwaNCBNZXRhZGF0YSBjb21tb24gdG8gYWxsIERhdGFzdG9yZSBBZG1pbiBvcGVyYXRpb25z
LgoKDQoFBAYCAAYSBI4CAhAKDQoFBAYCAAESBI4CERcKDQoFBAYCAAMSBI4CGhsKQAoEBAYC
ARIEkQICIRoyIEFuIGVzdGltYXRlIG9mIHRoZSBudW1iZXIgb2YgZW50aXRpZXMgcHJvY2Vz
c2VkLgoKDQoFBAYCAQYSBJECAgoKDQoFBAYCAQESBJECCxwKDQoFBAYCAQMSBJECHyAKPQoE
BAYCAhIElAICHhovIEFuIGVzdGltYXRlIG9mIHRoZSBudW1iZXIgb2YgYnl0ZXMgcHJvY2Vz
c2VkLgoKDQoFBAYCAgYSBJQCAgoKDQoFBAYCAgESBJQCCxkKDQoFBAYCAgMSBJQCHB0KQQoE
BAYCAxIElwICIRozIERlc2NyaXB0aW9uIG9mIHdoaWNoIGVudGl0aWVzIGFyZSBiZWluZyBp
bXBvcnRlZC4KCg0KBQQGAgMGEgSXAgIOCg0KBQQGAgMBEgSXAg8cCg0KBQQGAgMDEgSXAh8g
CuwBCgQEBgIEEgSdAgIXGt0BIFRoZSBsb2NhdGlvbiBvZiB0aGUgaW1wb3J0IG1ldGFkYXRh
IGZpbGUuIFRoaXMgd2lsbCBiZSB0aGUgc2FtZSB2YWx1ZSBhcwogdGhlCiBbZ29vZ2xlLmRh
dGFzdG9yZS5hZG1pbi52MWJldGExLkV4cG9ydEVudGl0aWVzUmVzcG9uc2Uub3V0cHV0X3Vy
bF1bZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MWJldGExLkV4cG9ydEVudGl0aWVzUmVzcG9u
c2Uub3V0cHV0X3VybF0KIGZpZWxkLgoKDQoFBAYCBAUSBJ0CAggKDQoFBAYCBAESBJ0CCRIK
DQoFBAYCBAMSBJ0CFRYK5gQKAgQHEgazAgC/AgEa1wQgSWRlbnRpZmllcyBhIHN1YnNldCBv
ZiBlbnRpdGllcyBpbiBhIHByb2plY3QuIFRoaXMgaXMgc3BlY2lmaWVkIGFzCiBjb21iaW5h
dGlvbnMgb2Yga2luZHMgYW5kIG5hbWVzcGFjZXMgKGVpdGhlciBvciBib3RoIG9mIHdoaWNo
IG1heSBiZSBhbGwsIGFzCiBkZXNjcmliZWQgaW4gdGhlIGZvbGxvd2luZyBleGFtcGxlcyku
CiBFeGFtcGxlIHVzYWdlOgoKIEVudGlyZSBwcm9qZWN0OgogICBraW5kcz1bXSwgbmFtZXNw
YWNlX2lkcz1bXQoKIEtpbmRzIEZvbyBhbmQgQmFyIGluIGFsbCBuYW1lc3BhY2VzOgogICBr
aW5kcz1bJ0ZvbycsICdCYXInXSwgbmFtZXNwYWNlX2lkcz1bXQoKIEtpbmRzIEZvbyBhbmQg
QmFyIG9ubHkgaW4gdGhlIGRlZmF1bHQgbmFtZXNwYWNlOgogICBraW5kcz1bJ0ZvbycsICdC
YXInXSwgbmFtZXNwYWNlX2lkcz1bJyddCgogS2luZHMgRm9vIGFuZCBCYXIgaW4gYm90aCB0
aGUgZGVmYXVsdCBhbmQgQmF6IG5hbWVzcGFjZXM6CiAgIGtpbmRzPVsnRm9vJywgJ0Jhcidd
LCBuYW1lc3BhY2VfaWRzPVsnJywgJ0JheiddCgogVGhlIGVudGlyZSBCYXogbmFtZXNwYWNl
OgogICBraW5kcz1bXSwgbmFtZXNwYWNlX2lkcz1bJ0JheiddCgoLCgMEBwESBLMCCBQKOQoE
BAcCABIEtQICHBorIElmIGVtcHR5LCB0aGVuIHRoaXMgcmVwcmVzZW50cyBhbGwga2luZHMu
CgoNCgUEBwIABBIEtQICCgoNCgUEBwIABRIEtQILEQoNCgUEBwIAARIEtQISFwoNCgUEBwIA
AxIEtQIaGwrSAgoEBAcCARIEvgICJBrDAiBBbiBlbXB0eSBsaXN0IHJlcHJlc2VudHMgYWxs
IG5hbWVzcGFjZXMuIFRoaXMgaXMgdGhlIHByZWZlcnJlZAogdXNhZ2UgZm9yIHByb2plY3Rz
IHRoYXQgZG9uJ3QgdXNlIG5hbWVzcGFjZXMuCgogQW4gZW1wdHkgc3RyaW5nIGVsZW1lbnQg
cmVwcmVzZW50cyB0aGUgZGVmYXVsdCBuYW1lc3BhY2UuIFRoaXMgc2hvdWxkIGJlCiB1c2Vk
IGlmIHRoZSBwcm9qZWN0IGhhcyBkYXRhIGluIG5vbi1kZWZhdWx0IG5hbWVzcGFjZXMsIGJ1
dCBkb2Vzbid0IHdhbnQgdG8KIGluY2x1ZGUgdGhlbS4KIEVhY2ggbmFtZXNwYWNlIGluIHRo
aXMgbGlzdCBtdXN0IGJlIHVuaXF1ZS4KCg0KBQQHAgEEEgS+AgIKCg0KBQQHAgEFEgS+AgsR
Cg0KBQQHAgEBEgS+AhIfCg0KBQQHAgEDEgS+AiIjCiAKAgUAEgbCAgDLAgEaEiBPcGVyYXRp
b24gdHlwZXMuCgoLCgMFAAESBMICBRIKHAoEBQACABIExAICIRoOIFVuc3BlY2lmaWVkLgoK
DQoFBQACAAESBMQCAhwKDQoFBQACAAISBMQCHyAKHwoEBQACARIExwICFhoRIEV4cG9ydEVu
dGl0aWVzLgoKDQoFBQACAQESBMcCAhEKDQoFBQACAQISBMcCFBUKHwoEBQACAhIEygICFhoR
IEltcG9ydEVudGl0aWVzLgoKDQoFBQACAgESBMoCAhEKDQoFBQACAgISBMoCFBViBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata ===
    # Fields for CommonMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_type Type: 14 (.google.datastore.admin.v1beta1.OperationType)
    # Field: labels Type: 11 (.google.datastore.admin.v1beta1.CommonMetadata.LabelsEntry)
    # Field: state Type: 14 (.google.datastore.admin.v1beta1.CommonMetadata.State)

# Enum: CommonMetadata::State
our $CommonMetadata_STATE_UNSPECIFIED = 0;
our $CommonMetadata_INITIALIZING = 1;
our $CommonMetadata_PROCESSING = 2;
our $CommonMetadata_CANCELLING = 3;
our $CommonMetadata_FINALIZING = 4;
our $CommonMetadata_SUCCESSFUL = 5;
our $CommonMetadata_FAILED = 6;
our $CommonMetadata_CANCELLED = 7;

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress ===
    # Fields for Progress
    # Field: work_completed Type: 3 ()
    # Field: work_estimated Type: 3 ()

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest ===
    # Fields for ExportEntitiesRequest
    # Field: project_id Type: 9 ()
    # Field: labels Type: 11 (.google.datastore.admin.v1beta1.ExportEntitiesRequest.LabelsEntry)
    # Field: entity_filter Type: 11 (.google.datastore.admin.v1beta1.EntityFilter)
    # Field: output_url_prefix Type: 9 ()

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest ===
    # Fields for ImportEntitiesRequest
    # Field: project_id Type: 9 ()
    # Field: labels Type: 11 (.google.datastore.admin.v1beta1.ImportEntitiesRequest.LabelsEntry)
    # Field: input_url Type: 9 ()
    # Field: entity_filter Type: 11 (.google.datastore.admin.v1beta1.EntityFilter)

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesResponse ===
    # Fields for ExportEntitiesResponse
    # Field: output_url Type: 9 ()

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesMetadata ===
    # Fields for ExportEntitiesMetadata
    # Field: common Type: 11 (.google.datastore.admin.v1beta1.CommonMetadata)
    # Field: progress_entities Type: 11 (.google.datastore.admin.v1beta1.Progress)
    # Field: progress_bytes Type: 11 (.google.datastore.admin.v1beta1.Progress)
    # Field: entity_filter Type: 11 (.google.datastore.admin.v1beta1.EntityFilter)
    # Field: output_url_prefix Type: 9 ()

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesMetadata ===
    # Fields for ImportEntitiesMetadata
    # Field: common Type: 11 (.google.datastore.admin.v1beta1.CommonMetadata)
    # Field: progress_entities Type: 11 (.google.datastore.admin.v1beta1.Progress)
    # Field: progress_bytes Type: 11 (.google.datastore.admin.v1beta1.Progress)
    # Field: entity_filter Type: 11 (.google.datastore.admin.v1beta1.EntityFilter)
    # Field: input_url Type: 9 ()

# === Message: Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter ===
    # Fields for EntityFilter
    # Field: kinds Type: 9 ()
    # Field: namespace_ids Type: 9 ()

# === Service Client: Google::Datastore::Admin::V1beta1::DatastoreAdmin::DatastoreAdminClient ===
package Google::Datastore::Admin::V1beta1::DatastoreAdmin::DatastoreAdminClient;

=pod

=head2 Service Client: Google::Datastore::Admin::V1beta1::DatastoreAdmin::DatastoreAdminClient

Client stub representing the remote C<DatastoreAdmin> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<datastore.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'datastore.googleapis.com:443' );

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

sub export_entities {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.admin.v1beta1.DatastoreAdmin',
        method         => 'ExportEntities',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_entities {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.admin.v1beta1.DatastoreAdmin',
        method         => 'ImportEntities',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::Admin::V1beta1::DatastoreAdmin - Compiled Protocol Buffers messages for google/datastore/admin/v1beta1/datastore_admin.proto

=head1 SYNOPSIS

    use Google::Datastore::Admin::V1beta1::DatastoreAdmin;

    my $msg = Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata->new({
        start_time => $start_time,
        end_time => $end_time,
        operation_type => $operation_type,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->start_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/admin/v1beta1/datastore_admin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata

Metadata common to all Datastore Admin operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time that work began on the operation.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation ended, either successfully or otherwise.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1beta1::OperationType>)

The type of the operation. Can be used as a filter in
ListOperationsRequest.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata::LabelsEntry>)

The client-assigned labels which were provided when the operation was
created. May also include additional labels.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1beta1::CommonMetadata::State>)

The current state of the Operation.

=back

=head3 Enum: CommonMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<INITIALIZING> => C<1>

=item * C<PROCESSING> => C<2>

=item * C<CANCELLING> => C<3>

=item * C<FINALIZING> => C<4>

=item * C<SUCCESSFUL> => C<5>

=item * C<FAILED> => C<6>

=item * C<CANCELLED> => C<7>

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress

Measures the progress of a particular metric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->work_completed() >> / C<< $msg->work_completed($value) >>

Type: C<Int64>

The amount of work that has been completed. Note that this may be greater
than work_estimated.

=item * C<< $msg->work_estimated() >> / C<< $msg->work_estimated($value) >>

Type: C<Int64>

An estimate of how much work needs to be performed. May be zero if the
work estimate is unavailable.

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest

The request for
[google.datastore.admin.v1beta1.DatastoreAdmin.ExportEntities][google.datastore.admin.v1beta1.DatastoreAdmin.ExportEntities].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Project ID against which to make the request.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry>)

Client-assigned labels.

=item * C<< $msg->entity_filter() >> / C<< $msg->entity_filter($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter>)

Description of what data from the project is included in the export.

=item * C<< $msg->output_url_prefix() >> / C<< $msg->output_url_prefix($value) >>

Type: C<String>

Location for the export metadata and data files.

The full resource URL of the external storage location. Currently, only
Google Cloud Storage is supported. So output_url_prefix should be of the
form: `gs://BUCKET_NAME[/NAMESPACE_PATH]`, where `BUCKET_NAME` is the
name of the Cloud Storage bucket and `NAMESPACE_PATH` is an optional Cloud
Storage namespace path (this is not a Cloud Datastore namespace). For more
information about Cloud Storage namespace paths, see
[Object name
considerations](https://cloud.google.com/storage/docs/naming#object-considerations).

The resulting files will be nested deeper than the specified URL prefix.
The final output URL will be provided in the
[google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url][google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url]
field. That value should be used for subsequent ImportEntities operations.

By nesting the data files deeper, the same Cloud Storage bucket can be used
in multiple ExportEntities operations without conflict.

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest

The request for
[google.datastore.admin.v1beta1.DatastoreAdmin.ImportEntities][google.datastore.admin.v1beta1.DatastoreAdmin.ImportEntities].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Project ID against which to make the request.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry>)

Client-assigned labels.

=item * C<< $msg->input_url() >> / C<< $msg->input_url($value) >>

Type: C<String>

The full resource URL of the external storage location. Currently, only
Google Cloud Storage is supported. So input_url should be of the form:
`gs://BUCKET_NAME[/NAMESPACE_PATH]/OVERALL_EXPORT_METADATA_FILE`, where
`BUCKET_NAME` is the name of the Cloud Storage bucket, `NAMESPACE_PATH` is
an optional Cloud Storage namespace path (this is not a Cloud Datastore
namespace), and `OVERALL_EXPORT_METADATA_FILE` is the metadata file written
by the ExportEntities operation. For more information about Cloud Storage
namespace paths, see
[Object name
considerations](https://cloud.google.com/storage/docs/naming#object-considerations).

For more information, see
[google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url][google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url].

=item * C<< $msg->entity_filter() >> / C<< $msg->entity_filter($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter>)

Optionally specify which kinds/namespaces are to be imported. If provided,
the list must be a subset of the EntityFilter used in creating the export,
otherwise a FAILED_PRECONDITION error will be returned. If no filter is
specified then all entities from the export are imported.

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesResponse

The response for
[google.datastore.admin.v1beta1.DatastoreAdmin.ExportEntities][google.datastore.admin.v1beta1.DatastoreAdmin.ExportEntities].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_url() >> / C<< $msg->output_url($value) >>

Type: C<String>

Location of the output metadata file. This can be used to begin an import
into Cloud Datastore (this project or another project). See
[google.datastore.admin.v1beta1.ImportEntitiesRequest.input_url][google.datastore.admin.v1beta1.ImportEntitiesRequest.input_url].
Only present if the operation completed successfully.

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesMetadata

Metadata for ExportEntities operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->common() >> / C<< $msg->common($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata>)

Metadata common to all Datastore Admin operations.

=item * C<< $msg->progress_entities() >> / C<< $msg->progress_entities($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress>)

An estimate of the number of entities processed.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress>)

An estimate of the number of bytes processed.

=item * C<< $msg->entity_filter() >> / C<< $msg->entity_filter($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter>)

Description of which entities are being exported.

=item * C<< $msg->output_url_prefix() >> / C<< $msg->output_url_prefix($value) >>

Type: C<String>

Location for the export metadata and data files. This will be the same
value as the
[google.datastore.admin.v1beta1.ExportEntitiesRequest.output_url_prefix][google.datastore.admin.v1beta1.ExportEntitiesRequest.output_url_prefix]
field. The final output location is provided in
[google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url][google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url].

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesMetadata

Metadata for ImportEntities operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->common() >> / C<< $msg->common($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata>)

Metadata common to all Datastore Admin operations.

=item * C<< $msg->progress_entities() >> / C<< $msg->progress_entities($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress>)

An estimate of the number of entities processed.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress>)

An estimate of the number of bytes processed.

=item * C<< $msg->entity_filter() >> / C<< $msg->entity_filter($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter>)

Description of which entities are being imported.

=item * C<< $msg->input_url() >> / C<< $msg->input_url($value) >>

Type: C<String>

The location of the import metadata file. This will be the same value as
the
[google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url][google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url]
field.

=back

=head2 Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter

Identifies a subset of entities in a project. This is specified as
combinations of kinds and namespaces (either or both of which may be all, as
described in the following examples).
Example usage:

Entire project:
  kinds=[], namespace_ids=[]

Kinds Foo and Bar in all namespaces:
  kinds=['Foo', 'Bar'], namespace_ids=[]

Kinds Foo and Bar only in the default namespace:
  kinds=['Foo', 'Bar'], namespace_ids=['']

Kinds Foo and Bar in both the default and Baz namespaces:
  kinds=['Foo', 'Bar'], namespace_ids=['', 'Baz']

The entire Baz namespace:
  kinds=[], namespace_ids=['Baz']

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kinds() >> / C<< $msg->kinds($value) >>

Type: C<String>

If empty, then this represents all kinds.

=item * C<< $msg->namespace_ids() >> / C<< $msg->namespace_ids($value) >>

Type: C<String>

An empty list represents all namespaces. This is the preferred
usage for projects that don't use namespaces.

An empty string element represents the default namespace. This should be
used if the project has data in non-default namespaces, but doesn't want to
include them.
Each namespace in this list must be unique.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::Admin::V1beta1::DatastoreAdmin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
