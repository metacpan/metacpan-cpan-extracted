package Google::Cloud::Retail::V2alpha::Project;

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
    eval { require Google::Cloud::Retail::V2alpha::Common };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHJvamVjdC5wcm90bxIbZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEv
Y29tbW9uLnByb3RvIvoGCg1Mb2dnaW5nQ29uZmlnEhoKBG5hbWUYASABKAlCBuBBAuBBBVIE
bmFtZRJ7ChtkZWZhdWx0X2xvZ19nZW5lcmF0aW9uX3J1bGUYAiABKAsyPC5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZy5Mb2dHZW5lcmF0aW9uUnVsZVIYZGVm
YXVsdExvZ0dlbmVyYXRpb25SdWxlEoQBChxzZXJ2aWNlX2xvZ19nZW5lcmF0aW9uX3J1bGVz
GAQgAygLMkMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxvZ2dpbmdDb25maWcuU2Vy
dmljZUxvZ0dlbmVyYXRpb25SdWxlUhlzZXJ2aWNlTG9nR2VuZXJhdGlvblJ1bGVzGsABChFM
b2dHZW5lcmF0aW9uUnVsZRJcCg1sb2dnaW5nX2xldmVsGAEgASgOMjcuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmFscGhhLkxvZ2dpbmdDb25maWcuTG9nZ2luZ0xldmVsUgxsb2dnaW5nTGV2
ZWwSNAoUaW5mb19sb2dfc2FtcGxlX3JhdGUYAiABKAJIAFIRaW5mb0xvZ1NhbXBsZVJhdGWI
AQFCFwoVX2luZm9fbG9nX3NhbXBsZV9yYXRlGrABChhTZXJ2aWNlTG9nR2VuZXJhdGlvblJ1
bGUSJgoMc2VydmljZV9uYW1lGAEgASgJQgPgQQJSC3NlcnZpY2VOYW1lEmwKE2xvZ19nZW5l
cmF0aW9uX3J1bGUYAyABKAsyPC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTG9nZ2lu
Z0NvbmZpZy5Mb2dHZW5lcmF0aW9uUnVsZVIRbG9nR2VuZXJhdGlvblJ1bGUihgEKDExvZ2dp
bmdMZXZlbBIdChlMT0dHSU5HX0xFVkVMX1VOU1BFQ0lGSUVEEAASFAoQTE9HR0lOR19ESVNB
QkxFRBABEhgKFExPR19FUlJPUlNfQU5EX0FCT1ZFEAISGgoWTE9HX1dBUk5JTkdTX0FORF9B
Qk9WRRADEgsKB0xPR19BTEwQBDpK6kFHCiNyZXRhaWwuZ29vZ2xlYXBpcy5jb20vTG9nZ2lu
Z0NvbmZpZxIgcHJvamVjdHMve3Byb2plY3R9L2xvZ2dpbmdDb25maWcizQEKB1Byb2plY3QS
FwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEl0KEmVucm9sbGVkX3NvbHV0aW9ucxgCIAMoDjIp
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlvblR5cGVCA+BBA1IRZW5yb2xs
ZWRTb2x1dGlvbnM6SupBRwojcmV0YWlsLmdvb2dsZWFwaXMuY29tL1JldGFpbFByb2plY3QS
IHByb2plY3RzL3twcm9qZWN0fS9yZXRhaWxQcm9qZWN0IsQECgtBbGVydENvbmZpZxIaCgRu
YW1lGAEgASgJQgbgQQLgQQVSBG5hbWUSWwoOYWxlcnRfcG9saWNpZXMYAiADKAsyNC5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQWxlcnRDb25maWcuQWxlcnRQb2xpY3lSDWFsZXJ0
UG9saWNpZXMa8wIKC0FsZXJ0UG9saWN5Eh8KC2FsZXJ0X2dyb3VwGAEgASgJUgphbGVydEdy
b3VwEmYKDWVucm9sbF9zdGF0dXMYAiABKA4yQS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxw
aGEuQWxlcnRDb25maWcuQWxlcnRQb2xpY3kuRW5yb2xsU3RhdHVzUgxlbnJvbGxTdGF0dXMS
XgoKcmVjaXBpZW50cxgDIAMoCzI+Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5BbGVy
dENvbmZpZy5BbGVydFBvbGljeS5SZWNpcGllbnRSCnJlY2lwaWVudHMaMAoJUmVjaXBpZW50
EiMKDWVtYWlsX2FkZHJlc3MYASABKAlSDGVtYWlsQWRkcmVzcyJJCgxFbnJvbGxTdGF0dXMS
HQoZRU5ST0xMX1NUQVRVU19VTlNQRUNJRklFRBAAEgwKCEVOUk9MTEVEEAESDAoIREVDTElO
RUQQAjpG6kFDCiFyZXRhaWwuZ29vZ2xlYXBpcy5jb20vQWxlcnRDb25maWcSHnByb2plY3Rz
L3twcm9qZWN0fS9hbGVydENvbmZpZ0LQAQofY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYUIMUHJvamVjdFByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYy
YWxwaGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWls
LlYyQWxwaGHKAhtHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3Vk
OjpSZXRhaWw6OlYyYWxwaGFKpC8KBxIFDgC9AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADIK
CAoBCBIDFgA4CgkKAgglEgMWADgKCAoBCBIDFwBOCgkKAggLEgMXAE4KCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAtCgkKAggIEgMZAC0KCAoBCBIDGgA4CgkKAggBEgMaADgKCAoB
CBIDGwAkCgkKAggkEgMbACQKCAoBCBIDHAA4CgkKAggpEgMcADgKCAoBCBIDHQA3CgkKAggt
EgMdADcKeAoCBAASBCEAdwEabCBQcm9qZWN0IGxldmVsIGxvZ2dpbmcgY29uZmlnIHRvIGNv
bnRyb2wgd2hhdCBsZXZlbCBvZiBsb2cgd2lsbCBiZSBnZW5lcmF0ZWQKIGFuZCB3cml0dGVu
IHRvIENsb3VkIExvZ2dpbmcuCgoKCgMEAAESAyEIFQoLCgMEAAcSBCICJQQKDQoFBAAHnQgS
BCICJQQKUgoEBAADABIEKAI7AxpEIFRoZSBsb2dnaW5nIGNvbmZpZ3VyYXRpb25zIGZvciBz
ZXJ2aWNlcyBzdXBwb3J0aW5nIGxvZyBnZW5lcmF0aW9uLgoKDAoFBAADAAESAygKGwpXCgYE
AAMAAgASAywEIxpIIFRoZSBsb2dnaW5nIGxldmVsLgoKIEJ5IGRlZmF1bHQgaXQgaXMgc2V0
IHRvIGBMT0dfV0FSTklOR1NfQU5EX0FCT1ZFYC4KCg4KBwQAAwACAAYSAywEEAoOCgcEAAMA
AgABEgMsER4KDgoHBAADAAIAAxIDLCEiCsoECgYEAAMAAgESAzoELBq6BCBUaGUgbG9nIHNh
bXBsZSByYXRlIGZvciBJTkZPIGxldmVsIGxvZyBlbnRyaWVzLiBZb3UgY2FuIHVzZSB0aGlz
IHRvCiByZWR1Y2UgdGhlIG51bWJlciBvZiBlbnRyaWVzIGdlbmVyYXRlZCBmb3IgSU5GTyBs
ZXZlbCBsb2dzLgoKIERPIE5PVCBzZXQgdGhpcyBmaWVsZCBpZiB0aGUKIFtsb2dnaW5nX2xl
dmVsXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZy5Mb2dHZW5l
cmF0aW9uUnVsZS5sb2dnaW5nX2xldmVsXQogaXMgbm90CiBbTG9nZ2luZ0xldmVsLkxPR19B
TExdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Mb2dnaW5nQ29uZmlnLkxvZ2dpbmdM
ZXZlbC5MT0dfQUxMXS4KIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBp
cyByZXR1cm5lZC4KCiBTYW1wbGUgcmF0ZSBmb3IgSU5GTyBsb2dzIGRlZmF1bHRzIHRvIDEg
d2hlbiB1bnNldCAoZ2VuZXJhdGUgYW5kIHNlbmQgYWxsCiBJTkZPIGxvZ3MgdG8gQ2xvdWQg
TG9nZ2luZykuIEl0cyB2YWx1ZSBtdXN0IGJlIGdyZWF0ZXIgdGhhbiAwIGFuZCBsZXNzCiB0
aGFuIG9yIGVxdWFsIHRvIDEuCgoOCgcEAAMAAgEEEgM6BAwKDgoHBAADAAIBBRIDOg0SCg4K
BwQAAwACAQESAzoTJwoOCgcEAAMAAgEDEgM6KisKSwoEBAADARIEPgJNAxo9IFRoZSBncmFu
dWxhciBsb2dnaW5nIGNvbmZpZ3VyYXRpb25zIGZvciBzdXBwb3J0ZWQgc2VydmljZXMuCgoM
CgUEAAMBARIDPgoiCvQBCgYEAAMBAgASA0kERRrkASBSZXF1aXJlZC4gU3VwcG9ydGVkIHNl
cnZpY2UgbmFtZXM6CiAiQ2F0YWxvZ1NlcnZpY2UiLAogIkNvbXBsZXRpb25TZXJ2aWNlIiwK
ICJDb250cm9sU2VydmljZSIsCiAiTWVyY2hhbnRDZW50ZXJTdHJlYW1pbmciLAogIk1vZGVs
U2VydmljZSIsCiAiUHJlZGljdGlvblNlcnZpY2UiLAogIlByb2R1Y3RTZXJ2aWNlIiwKICJT
ZXJ2aW5nQ29uZmlnU2VydmljZSIsCiAiVXNlckV2ZW50U2VydmljZSIsCgoOCgcEAAMBAgAF
EgNJBAoKDgoHBAADAQIAARIDSQsXCg4KBwQAAwECAAMSA0kaGwoOCgcEAAMBAgAIEgNJHEQK
EQoKBAADAQIACJwIABIDSR1DCkYKBgQAAwECARIDTAQuGjcgVGhlIGxvZyBnZW5lcmF0aW9u
IHJ1bGUgdGhhdCBhcHBsaWVzIHRvIHRoaXMgc2VydmljZS4KCg4KBwQAAwECAQYSA0wEFQoO
CgcEAAMBAgEBEgNMFikKDgoHBAADAQIBAxIDTCwtCjYKBAQABAASBFACYAMaKCBUaGUgc2V0
dGluZyB0byBjb250cm9sIGxvZyBnZW5lcmF0aW9uLgoKDAoFBAAEAAESA1AHEwpSCgYEAAQA
AgASA1IEIhpDIERlZmF1bHQgdmFsdWUuIERlZmF1bHRzIHRvIGBMT0dfRk9SX1dBUk5JTkdT
X0FORF9BQk9WRWAgaWYgdW5zZXQuCgoOCgcEAAQAAgABEgNSBB0KDgoHBAAEAAIAAhIDUiAh
CkQKBgQABAACARIDVQQZGjUgTm8gbG9nIHdpbGwgYmUgZ2VuZXJhdGVkIGFuZCBzZW50IHRv
IENsb3VkIExvZ2dpbmcuCgoOCgcEAAQAAgEBEgNVBBQKDgoHBAAEAAIBAhIDVRcYCjwKBgQA
BAACAhIDWAQdGi0gTG9nIGZvciBvcGVyYXRpb25zIHJlc3VsdGVkIGluIGZhdGFsIGVycm9y
LgoKDgoHBAAEAAICARIDWAQYCg4KBwQABAACAgISA1gbHAp8CgYEAAQAAgMSA1wEHxptIElu
IGFkZGl0aW9uIHRvIGBMT0dfRVJST1JTX0FORF9BQk9WRWAsIGFsc28gbG9nIGZvciBvcGVy
YXRpb25zIHRoYXQgaGF2ZQogc29mdCBlcnJvcnMsIHF1YWxpdHkgc3VnZ2VzdGlvbnMuCgoO
CgcEAAQAAgMBEgNcBBoKDgoHBAAEAAIDAhIDXB0eCj8KBgQABAACBBIDXwQQGjAgTG9nIGFs
bCBvcGVyYXRpb25zLCBpbmNsdWRpbmcgc3VjY2Vzc2Z1bCBvbmVzLgoKDgoHBAAEAAIEARID
XwQLCg4KBwQABAACBAISA18ODwp4CgQEAAIAEgRkAmcEGmogUmVxdWlyZWQuIEltbXV0YWJs
ZS4gVGhlIG5hbWUgb2YgdGhlIExvZ2dpbmdDb25maWcgc2luZ2xldG9uIHJlc291cmNlLgog
Rm9ybWF0OiBwcm9qZWN0cy8qL2xvZ2dpbmdDb25maWcKCgwKBQQAAgAFEgNkAggKDAoFBAAC
AAESA2QJDQoMCgUEAAIAAxIDZBARCg0KBQQAAgAIEgRkEmcDCg8KCAQAAgAInAgAEgNlBCoK
DwoIBAACAAicCAESA2YEKwr/AQoEBAACARIDbQI0GvEBIFRoZSBsb2cgZ2VuZXJhdGlvbiBy
dWxlIHRoYXQgYXBwbGllcyBieSBkZWZhdWx0IHRvIGFsbCBzZXJ2aWNlcwogc3VwcG9ydGlu
ZyBsb2cgZ2VuZXJhdGlvbi4gSXQgY2FuIGJlIG92ZXJyaWRkZW4gYnkKIFtTZXJ2aWNlTG9n
R2VuZXJhdGlvblJ1bGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Mb2dnaW5nQ29u
ZmlnLlNlcnZpY2VMb2dHZW5lcmF0aW9uUnVsZV0KIGZvciBzZXJ2aWNlIGxldmVsIGNvbnRy
b2wuCgoMCgUEAAIBBhIDbQITCgwKBQQAAgEBEgNtFC8KDAoFBAACAQMSA20yMwrFAgoEBAAC
AhIDdgJFGrcCIENvbnRyb2xzIGxvZ2dpbmcgY29uZmlndXJhdGlvbnMgbW9yZSBncmFudWxh
cmx5IGZvciBlYWNoIHN1cHBvcnRlZAogc2VydmljZS4KCiBUaGlzIG92ZXJyaWRlcyB0aGUK
IFtkZWZhdWx0X2xvZ19nZW5lcmF0aW9uX3J1bGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5Mb2dnaW5nQ29uZmlnLmRlZmF1bHRfbG9nX2dlbmVyYXRpb25fcnVsZV0KIGZvciB0
aGUgc2VydmljZXMgc3BlY2lmaWVkLiBGb3IgdGhvc2Ugbm90IG1lbnRpb25lZCwgdGhleSB3
aWxsIGZhbGxiYWNrIHRvCiB0aGUgZGVmYXVsdCBsb2cgZ2VuZXJhdGlvbiBydWxlLgoKDAoF
BAACAgQSA3YCCgoMCgUEAAICBhIDdgsjCgwKBQQAAgIBEgN2JEAKDAoFBAACAgMSA3ZDRAo+
CgIEARIFegCHAQEaMSBNZXRhZGF0YSB0aGF0IGRlc2NyaWJlcyBhIENsb3VkIFJldGFpbCBQ
cm9qZWN0LgoKCgoDBAEBEgN6CA8KCwoDBAEHEgR7An4ECg0KBQQBB50IEgR7An4ECoABCgQE
AQIAEgSCAQI+GnIgT3V0cHV0IG9ubHkuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmV0
YWlsIHByb2plY3QsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdF9pZF9vcl9udW1iZXJ9
L3JldGFpbFByb2plY3RgLgoKDQoFBAECAAUSBIIBAggKDQoFBAECAAESBIIBCQ0KDQoFBAEC
AAMSBIIBEBEKDQoFBAECAAgSBIIBEj0KEAoIBAECAAicCAASBIIBEzwKUgoEBAECARIGhQEC
hgEyGkIgT3V0cHV0IG9ubHkuIFJldGFpbCBBUEkgc29sdXRpb25zIHRoYXQgdGhlIHByb2pl
Y3QgaGFzIGVucm9sbGVkLgoKDQoFBAECAQQSBIUBAgoKDQoFBAECAQYSBIUBCxcKDQoFBAEC
AQESBIUBGCoKDQoFBAECAQMSBIUBLS4KDQoFBAECAQgSBIYBBjEKEAoIBAECAQicCAASBIYB
BzAKKwoCBAISBooBAL0BARodIFByb2plY3QgbGV2ZWwgYWxlcnQgY29uZmlnLgoKCwoDBAIB
EgSKAQgTCg0KAwQCBxIGiwECjgEECg8KBQQCB50IEgaLAQKOAQQKLgoEBAIDABIGkQECsQED
Gh4gQWxlcnQgcG9saWN5IGZvciBhIGN1c3RvbWVyLgoKDQoFBAIDAAESBJEBChUKMgoGBAID
AAMAEgaTAQSWAQUaICBSZWNpcGllbnQgY29udGFjdCBpbmZvcm1hdGlvbi4KCg8KBwQCAwAD
AAESBJMBDBUKMwoIBAIDAAMAAgASBJUBBh8aISBFbWFpbCBhZGRyZXNzIG9mIHRoZSByZWNp
cGllbnQuCgoRCgkEAgMAAwACAAUSBJUBBgwKEQoJBAIDAAMAAgABEgSVAQ0aChEKCQQCAwAD
AAIAAxIElQEdHgpACgYEAgMABAASBpkBBKMBBRouIFRoZSBlbnJvbGxtZW50IHN0YXR1cyBl
bnVtIGZvciBhbGVydCBwb2xpY3kuCgoPCgcEAgMABAABEgSZAQkVCmIKCAQCAwAEAAIAEgSc
AQYkGlAgRGVmYXVsdCB2YWx1ZS4gVXNlZCBmb3IgY3VzdG9tZXJzIHdobyBoYXZlIG5vdCBy
ZXNwb25kZWQgdG8gdGhlCiBhbGVydCBwb2xpY3kuCgoRCgkEAgMABAACAAESBJwBBh8KEQoJ
BAIDAAQAAgACEgScASIjCjgKCAQCAwAEAAIBEgSfAQYTGiYgQ3VzdG9tZXIgaXMgZW5yb2xs
ZWQgaW4gdGhpcyBwb2xpY3kuCgoRCgkEAgMABAACAQESBJ8BBg4KEQoJBAIDAAQAAgECEgSf
ARESCjIKCAQCAwAEAAICEgSiAQYTGiAgQ3VzdG9tZXIgZGVjbGluZWQgdGhpcyBwb2xpY3ku
CgoRCgkEAgMABAACAgESBKIBBg4KEQoJBAIDAAQAAgICEgSiARESCsMBCgYEAgMAAgASBKkB
BBsasgEgVGhlIGZlYXR1cmUgdGhhdCBwcm92aWRlcyBhbGVydGluZyBjYXBhYmlsaXR5Lgog
U3VwcG9ydGVkIHZhbHVlOgogLSBgc2VhcmNoLWRhdGEtcXVhbGl0eWAgZm9yIHJldGFpbCBz
ZWFyY2ggY3VzdG9tZXJzLgogLSBgY29udi1kYXRhLXF1YWxpdHlgIGZvciByZXRhaWwgY29u
dmVyc2F0aW9uIGN1c3RvbWVycy4KCg8KBwQCAwACAAUSBKkBBAoKDwoHBAIDAAIAARIEqQEL
FgoPCgcEAgMAAgADEgSpARkaCjYKBgQCAwACARIErAEEIxomIFRoZSBlbnJvbGxtZW50IHN0
YXR1cyBvZiBhIGN1c3RvbWVyLgoKDwoHBAIDAAIBBhIErAEEEAoPCgcEAgMAAgEBEgSsAREe
Cg8KBwQCAwACAQMSBKwBISIKZQoGBAIDAAICEgSwAQQmGlUgUmVjaXBpZW50cyBmb3IgdGhl
IGFsZXJ0IHBvbGljeS4KIE9uZSBhbGVydCBwb2xpY3kgc2hvdWxkIG5vdCBleGNlZWQgMjAg
cmVjaXBpZW50cy4KCg8KBwQCAwACAgQSBLABBAwKDwoHBAIDAAICBhIEsAENFgoPCgcEAgMA
AgIBEgSwARchCg8KBwQCAwACAgMSBLABJCUKdgoEBAICABIGtQECuAEEGmYgUmVxdWlyZWQu
IEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIEFsZXJ0Q29uZmlnIHNpbmdsZXRvbiByZXNv
dXJjZS4KIEZvcm1hdDogcHJvamVjdHMvKi9hbGVydENvbmZpZwoKDQoFBAICAAUSBLUBAggK
DQoFBAICAAESBLUBCQ0KDQoFBAICAAMSBLUBEBEKDwoFBAICAAgSBrUBErgBAwoQCggEAgIA
CJwIABIEtgEEKgoQCggEAgIACJwIARIEtwEEKwpgCgQEAgIBEgS8AQIqGlIgQWxlcnQgcG9s
aWNpZXMgZm9yIGEgY3VzdG9tZXIuCiBUaGV5IG11c3QgYmUgdW5pcXVlIGJ5IFtBbGVydFBv
bGljeS5hbGVydF9ncm91cF0KCg0KBQQCAgEEEgS8AQIKCg0KBQQCAgEGEgS8AQsWCg0KBQQC
AgEBEgS8ARclCg0KBQQCAgEDEgS8ASgpYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::Project::LoggingConfig ===
    # Fields for LoggingConfig
    # Field: name Type: 9 ()
    # Field: default_log_generation_rule Type: 11 (.google.cloud.retail.v2alpha.LoggingConfig.LogGenerationRule)
    # Field: service_log_generation_rules Type: 11 (.google.cloud.retail.v2alpha.LoggingConfig.ServiceLogGenerationRule)

# Enum: LoggingConfig::LoggingLevel
our $LoggingConfig_LOGGING_LEVEL_UNSPECIFIED = 0;
our $LoggingConfig_LOGGING_DISABLED = 1;
our $LoggingConfig_LOG_ERRORS_AND_ABOVE = 2;
our $LoggingConfig_LOG_WARNINGS_AND_ABOVE = 3;
our $LoggingConfig_LOG_ALL = 4;

# === Message: Google::Cloud::Retail::V2alpha::Project::Project ===
    # Fields for Project
    # Field: name Type: 9 ()
    # Field: enrolled_solutions Type: 14 (.google.cloud.retail.v2alpha.SolutionType)

# === Message: Google::Cloud::Retail::V2alpha::Project::AlertConfig ===
    # Fields for AlertConfig
    # Field: name Type: 9 ()
    # Field: alert_policies Type: 11 (.google.cloud.retail.v2alpha.AlertConfig.AlertPolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::Project - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/project.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::Project;

    my $msg = Google::Cloud::Retail::V2alpha::Project::LoggingConfig->new({
        name => $name,
        default_log_generation_rule => $default_log_generation_rule,
        service_log_generation_rules => $service_log_generation_rules,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::Project::LoggingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/project.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::Project::LoggingConfig

Project level logging config to control what level of log will be generated
and written to Cloud Logging.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Immutable. The name of the LoggingConfig singleton resource.
Format: projects/*/loggingConfig

=item * C<< $msg->default_log_generation_rule() >> / C<< $msg->default_log_generation_rule($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Project::LoggingConfig::LogGenerationRule>)

The log generation rule that applies by default to all services
supporting log generation. It can be overridden by
[ServiceLogGenerationRule][google.cloud.retail.v2alpha.LoggingConfig.ServiceLogGenerationRule]
for service level control.

=item * C<< $msg->service_log_generation_rules() >> / C<< $msg->service_log_generation_rules($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Project::LoggingConfig::ServiceLogGenerationRule>)

Controls logging configurations more granularly for each supported
service.

This overrides the
[default_log_generation_rule][google.cloud.retail.v2alpha.LoggingConfig.default_log_generation_rule]
for the services specified. For those not mentioned, they will fallback to
the default log generation rule.

=back

=head3 Enum: LoggingConfig::LoggingLevel

=over 4

=item * C<LOGGING_LEVEL_UNSPECIFIED> => C<0>

=item * C<LOGGING_DISABLED> => C<1>

=item * C<LOG_ERRORS_AND_ABOVE> => C<2>

=item * C<LOG_WARNINGS_AND_ABOVE> => C<3>

=item * C<LOG_ALL> => C<4>

=back

=head2 Google::Cloud::Retail::V2alpha::Project::Project

Metadata that describes a Cloud Retail Project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Full resource name of the retail project, such as
`projects/{project_id_or_number}/retailProject`.

=item * C<< $msg->enrolled_solutions() >> / C<< $msg->enrolled_solutions($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Output only. Retail API solutions that the project has enrolled.

=back

=head2 Google::Cloud::Retail::V2alpha::Project::AlertConfig

Project level alert config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Immutable. The name of the AlertConfig singleton resource.
Format: projects/*/alertConfig

=item * C<< $msg->alert_policies() >> / C<< $msg->alert_policies($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Project::AlertConfig::AlertPolicy>)

Alert policies for a customer.
They must be unique by [AlertPolicy.alert_group]

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::Project::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
