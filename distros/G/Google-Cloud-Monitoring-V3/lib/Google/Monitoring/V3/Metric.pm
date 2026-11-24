package Google::Monitoring::V3::Metric;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Label };
    eval { require Google::Api::Metric };
    eval { require Google::Api::MonitoredResource };
    eval { require Google::Monitoring::V3::Common };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvbW9uaXRvcmluZy92My9tZXRyaWMucHJvdG8SFGdvb2dsZS5tb25pdG9yaW5n
LnYzGhZnb29nbGUvYXBpL2xhYmVsLnByb3RvGhdnb29nbGUvYXBpL21ldHJpYy5wcm90bxoj
Z29vZ2xlL2FwaS9tb25pdG9yZWRfcmVzb3VyY2UucHJvdG8aIWdvb2dsZS9tb25pdG9yaW5n
L3YzL2NvbW1vbi5wcm90byJ/CgVQb2ludBI+CghpbnRlcnZhbBgBIAEoCzIiLmdvb2dsZS5t
b25pdG9yaW5nLnYzLlRpbWVJbnRlcnZhbFIIaW50ZXJ2YWwSNgoFdmFsdWUYAiABKAsyIC5n
b29nbGUubW9uaXRvcmluZy52My5UeXBlZFZhbHVlUgV2YWx1ZSKyAwoKVGltZVNlcmllcxIq
CgZtZXRyaWMYASABKAsyEi5nb29nbGUuYXBpLk1ldHJpY1IGbWV0cmljEjkKCHJlc291cmNl
GAIgASgLMh0uZ29vZ2xlLmFwaS5Nb25pdG9yZWRSZXNvdXJjZVIIcmVzb3VyY2USQQoIbWV0
YWRhdGEYByABKAsyJS5nb29nbGUuYXBpLk1vbml0b3JlZFJlc291cmNlTWV0YWRhdGFSCG1l
dGFkYXRhEkgKC21ldHJpY19raW5kGAMgASgOMicuZ29vZ2xlLmFwaS5NZXRyaWNEZXNjcmlw
dG9yLk1ldHJpY0tpbmRSCm1ldHJpY0tpbmQSRQoKdmFsdWVfdHlwZRgEIAEoDjImLmdvb2ds
ZS5hcGkuTWV0cmljRGVzY3JpcHRvci5WYWx1ZVR5cGVSCXZhbHVlVHlwZRIzCgZwb2ludHMY
BSADKAsyGy5nb29nbGUubW9uaXRvcmluZy52My5Qb2ludFIGcG9pbnRzEhIKBHVuaXQYCCAB
KAlSBHVuaXQSIAoLZGVzY3JpcHRpb24YCSABKAlSC2Rlc2NyaXB0aW9uIpQDChRUaW1lU2Vy
aWVzRGVzY3JpcHRvchJIChFsYWJlbF9kZXNjcmlwdG9ycxgBIAMoCzIbLmdvb2dsZS5hcGku
TGFiZWxEZXNjcmlwdG9yUhBsYWJlbERlc2NyaXB0b3JzEmcKEXBvaW50X2Rlc2NyaXB0b3Jz
GAUgAygLMjouZ29vZ2xlLm1vbml0b3JpbmcudjMuVGltZVNlcmllc0Rlc2NyaXB0b3IuVmFs
dWVEZXNjcmlwdG9yUhBwb2ludERlc2NyaXB0b3JzGsgBCg9WYWx1ZURlc2NyaXB0b3ISEAoD
a2V5GAEgASgJUgNrZXkSRQoKdmFsdWVfdHlwZRgCIAEoDjImLmdvb2dsZS5hcGkuTWV0cmlj
RGVzY3JpcHRvci5WYWx1ZVR5cGVSCXZhbHVlVHlwZRJICgttZXRyaWNfa2luZBgDIAEoDjIn
Lmdvb2dsZS5hcGkuTWV0cmljRGVzY3JpcHRvci5NZXRyaWNLaW5kUgptZXRyaWNLaW5kEhIK
BHVuaXQYBCABKAlSBHVuaXQitQIKDlRpbWVTZXJpZXNEYXRhEkMKDGxhYmVsX3ZhbHVlcxgB
IAMoCzIgLmdvb2dsZS5tb25pdG9yaW5nLnYzLkxhYmVsVmFsdWVSC2xhYmVsVmFsdWVzEk0K
CnBvaW50X2RhdGEYAiADKAsyLi5nb29nbGUubW9uaXRvcmluZy52My5UaW1lU2VyaWVzRGF0
YS5Qb2ludERhdGFSCXBvaW50RGF0YRqOAQoJUG9pbnREYXRhEjgKBnZhbHVlcxgBIAMoCzIg
Lmdvb2dsZS5tb25pdG9yaW5nLnYzLlR5cGVkVmFsdWVSBnZhbHVlcxJHCg10aW1lX2ludGVy
dmFsGAIgASgLMiIuZ29vZ2xlLm1vbml0b3JpbmcudjMuVGltZUludGVydmFsUgx0aW1lSW50
ZXJ2YWwifgoKTGFiZWxWYWx1ZRIfCgpib29sX3ZhbHVlGAEgASgISABSCWJvb2xWYWx1ZRIh
CgtpbnQ2NF92YWx1ZRgCIAEoA0gAUgppbnQ2NFZhbHVlEiMKDHN0cmluZ192YWx1ZRgDIAEo
CUgAUgtzdHJpbmdWYWx1ZUIHCgV2YWx1ZSJjCgpRdWVyeUVycm9yEjsKB2xvY2F0b3IYASAB
KAsyIS5nb29nbGUubW9uaXRvcmluZy52My5UZXh0TG9jYXRvclIHbG9jYXRvchIYCgdtZXNz
YWdlGAIgASgJUgdtZXNzYWdlIvACCgtUZXh0TG9jYXRvchIWCgZzb3VyY2UYASABKAlSBnNv
dXJjZRJRCg5zdGFydF9wb3NpdGlvbhgCIAEoCzIqLmdvb2dsZS5tb25pdG9yaW5nLnYzLlRl
eHRMb2NhdG9yLlBvc2l0aW9uUg1zdGFydFBvc2l0aW9uEk0KDGVuZF9wb3NpdGlvbhgDIAEo
CzIqLmdvb2dsZS5tb25pdG9yaW5nLnYzLlRleHRMb2NhdG9yLlBvc2l0aW9uUgtlbmRQb3Np
dGlvbhJICg5uZXN0ZWRfbG9jYXRvchgEIAEoCzIhLmdvb2dsZS5tb25pdG9yaW5nLnYzLlRl
eHRMb2NhdG9yUg1uZXN0ZWRMb2NhdG9yEiUKDm5lc3RpbmdfcmVhc29uGAUgASgJUg1uZXN0
aW5nUmVhc29uGjYKCFBvc2l0aW9uEhIKBGxpbmUYASABKAVSBGxpbmUSFgoGY29sdW1uGAIg
ASgFUgZjb2x1bW5CxgEKGGNvbS5nb29nbGUubW9uaXRvcmluZy52M0ILTWV0cmljUHJvdG9Q
AVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2FwaXYzL3YyL21vbml0b3Jpbmdw
Yjttb25pdG9yaW5ncGKqAhpHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5WM8oCGkdvb2dsZVxD
bG91ZFxNb25pdG9yaW5nXFYz6gIdR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6VjNKzkwK
BxIFDgD1AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB0K
CQoCAwASAxIAIAoJCgIDARIDEwAhCgkKAgMCEgMUAC0KCQoCAwMSAxUAKwoICgEIEgMXADcK
CQoCCCUSAxcANwoICgEIEgMYAFgKCQoCCAsSAxgAWAoICgEIEgMZACIKCQoCCAoSAxkAIgoI
CgEIEgMaACwKCQoCCAgSAxoALAoICgEIEgMbADEKCQoCCAESAxsAMQoICgEIEgMcADcKCQoC
CCkSAxwANwoICgEIEgMdADYKCQoCCC0SAx0ANgozCgIEABIEIAAuARonIEEgc2luZ2xlIGRh
dGEgcG9pbnQgaW4gYSB0aW1lIHNlcmllcy4KCgoKAwQAARIDIAgNCtkECgQEAAIAEgMqAhwa
ywQgVGhlIHRpbWUgaW50ZXJ2YWwgdG8gd2hpY2ggdGhlIGRhdGEgcG9pbnQgYXBwbGllcy4g
IEZvciBgR0FVR0VgIG1ldHJpY3MsCiB0aGUgc3RhcnQgdGltZSBpcyBvcHRpb25hbCwgYnV0
IGlmIGl0IGlzIHN1cHBsaWVkLCBpdCBtdXN0IGVxdWFsIHRoZQogZW5kIHRpbWUuICBGb3Ig
YERFTFRBYCBtZXRyaWNzLCB0aGUgc3RhcnQKIGFuZCBlbmQgdGltZSBzaG91bGQgc3BlY2lm
eSBhIG5vbi16ZXJvIGludGVydmFsLCB3aXRoIHN1YnNlcXVlbnQgcG9pbnRzCiBzcGVjaWZ5
aW5nIGNvbnRpZ3VvdXMgYW5kIG5vbi1vdmVybGFwcGluZyBpbnRlcnZhbHMuICBGb3IgYENV
TVVMQVRJVkVgCiBtZXRyaWNzLCB0aGUgc3RhcnQgYW5kIGVuZCB0aW1lIHNob3VsZCBzcGVj
aWZ5IGEgbm9uLXplcm8gaW50ZXJ2YWwsIHdpdGgKIHN1YnNlcXVlbnQgcG9pbnRzIHNwZWNp
ZnlpbmcgdGhlIHNhbWUgc3RhcnQgdGltZSBhbmQgaW5jcmVhc2luZyBlbmQgdGltZXMsCiB1
bnRpbCBhbiBldmVudCByZXNldHMgdGhlIGN1bXVsYXRpdmUgdmFsdWUgdG8gemVybyBhbmQg
c2V0cyBhIG5ldyBzdGFydAogdGltZSBmb3IgdGhlIGZvbGxvd2luZyBwb2ludHMuCgoMCgUE
AAIABhIDKgIOCgwKBQQAAgABEgMqDxcKDAoFBAACAAMSAyoaGworCgQEAAIBEgMtAhcaHiBU
aGUgdmFsdWUgb2YgdGhlIGRhdGEgcG9pbnQuCgoMCgUEAAIBBhIDLQIMCgwKBQQAAgEBEgMt
DRIKDAoFBAACAQMSAy0VFgqRAgoCBAESBDQAbAEahAIgQSBjb2xsZWN0aW9uIG9mIGRhdGEg
cG9pbnRzIHRoYXQgZGVzY3JpYmVzIHRoZSB0aW1lLXZhcnlpbmcgdmFsdWVzCiBvZiBhIG1l
dHJpYy4gQSB0aW1lIHNlcmllcyBpcyBpZGVudGlmaWVkIGJ5IGEgY29tYmluYXRpb24gb2Yg
YQogZnVsbHktc3BlY2lmaWVkIG1vbml0b3JlZCByZXNvdXJjZSBhbmQgYSBmdWxseS1zcGVj
aWZpZWQgbWV0cmljLgogVGhpcyB0eXBlIGlzIHVzZWQgZm9yIGJvdGggbGlzdGluZyBhbmQg
Y3JlYXRpbmcgdGltZSBzZXJpZXMuCgoKCgMEAQESAzQIEgphCgQEAQIAEgM3Ah8aVCBUaGUg
YXNzb2NpYXRlZCBtZXRyaWMuIEEgZnVsbHktc3BlY2lmaWVkIG1ldHJpYyB1c2VkIHRvIGlk
ZW50aWZ5IHRoZSB0aW1lCiBzZXJpZXMuCgoMCgUEAQIABhIDNwITCgwKBQQBAgABEgM3FBoK
DAoFBAECAAMSAzcdHgqvAgoEBAECARIDPQIsGqECIFRoZSBhc3NvY2lhdGVkIG1vbml0b3Jl
ZCByZXNvdXJjZS4gIEN1c3RvbSBtZXRyaWNzIGNhbiB1c2Ugb25seSBjZXJ0YWluCiBtb25p
dG9yZWQgcmVzb3VyY2UgdHlwZXMgaW4gdGhlaXIgdGltZSBzZXJpZXMgZGF0YS4gRm9yIG1v
cmUgaW5mb3JtYXRpb24sCiBzZWUgW01vbml0b3JlZCByZXNvdXJjZXMgZm9yIGN1c3RvbQog
bWV0cmljc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvY3VzdG9tLW1l
dHJpY3MvY3JlYXRpbmctbWV0cmljcyNjdXN0b20tbWV0cmljLXJlc291cmNlcykuCgoMCgUE
AQIBBhIDPQIeCgwKBQQBAgEBEgM9HycKDAoFBAECAQMSAz0qKwruAQoEBAECAhIDQgI0GuAB
IE91dHB1dCBvbmx5LiBUaGUgYXNzb2NpYXRlZCBtb25pdG9yZWQgcmVzb3VyY2UgbWV0YWRh
dGEuIFdoZW4gcmVhZGluZyBhCiB0aW1lIHNlcmllcywgdGhpcyBmaWVsZCB3aWxsIGluY2x1
ZGUgbWV0YWRhdGEgbGFiZWxzIHRoYXQgYXJlIGV4cGxpY2l0bHkKIG5hbWVkIGluIHRoZSBy
ZWR1Y3Rpb24uIFdoZW4gY3JlYXRpbmcgYSB0aW1lIHNlcmllcywgdGhpcyBmaWVsZCBpcyBp
Z25vcmVkLgoKDAoFBAECAgYSA0ICJgoMCgUEAQICARIDQicvCgwKBQQBAgIDEgNCMjMKpgQK
BAQBAgMSA00CORqYBCBUaGUgbWV0cmljIGtpbmQgb2YgdGhlIHRpbWUgc2VyaWVzLiBXaGVu
IGxpc3RpbmcgdGltZSBzZXJpZXMsIHRoaXMgbWV0cmljCiBraW5kIG1pZ2h0IGJlIGRpZmZl
cmVudCBmcm9tIHRoZSBtZXRyaWMga2luZCBvZiB0aGUgYXNzb2NpYXRlZCBtZXRyaWMgaWYK
IHRoaXMgdGltZSBzZXJpZXMgaXMgYW4gYWxpZ25tZW50IG9yIHJlZHVjdGlvbiBvZiBvdGhl
ciB0aW1lIHNlcmllcy4KCiBXaGVuIGNyZWF0aW5nIGEgdGltZSBzZXJpZXMsIHRoaXMgZmll
bGQgaXMgb3B0aW9uYWwuIElmIHByZXNlbnQsIGl0IG11c3QgYmUKIHRoZSBzYW1lIGFzIHRo
ZSBtZXRyaWMga2luZCBvZiB0aGUgYXNzb2NpYXRlZCBtZXRyaWMuIElmIHRoZSBhc3NvY2lh
dGVkCiBtZXRyaWMncyBkZXNjcmlwdG9yIG11c3QgYmUgYXV0by1jcmVhdGVkLCB0aGVuIHRo
aXMgZmllbGQgc3BlY2lmaWVzIHRoZQogbWV0cmljIGtpbmQgb2YgdGhlIG5ldyBkZXNjcmlw
dG9yIGFuZCBtdXN0IGJlIGVpdGhlciBgR0FVR0VgICh0aGUgZGVmYXVsdCkKIG9yIGBDVU1V
TEFUSVZFYC4KCgwKBQQBAgMGEgNNAigKDAoFBAECAwESA00pNAoMCgUEAQIDAxIDTTc4CuwC
CgQEAQIEEgNVAjca3gIgVGhlIHZhbHVlIHR5cGUgb2YgdGhlIHRpbWUgc2VyaWVzLiBXaGVu
IGxpc3RpbmcgdGltZSBzZXJpZXMsIHRoaXMgdmFsdWUKIHR5cGUgbWlnaHQgYmUgZGlmZmVy
ZW50IGZyb20gdGhlIHZhbHVlIHR5cGUgb2YgdGhlIGFzc29jaWF0ZWQgbWV0cmljIGlmCiB0
aGlzIHRpbWUgc2VyaWVzIGlzIGFuIGFsaWdubWVudCBvciByZWR1Y3Rpb24gb2Ygb3RoZXIg
dGltZSBzZXJpZXMuCgogV2hlbiBjcmVhdGluZyBhIHRpbWUgc2VyaWVzLCB0aGlzIGZpZWxk
IGlzIG9wdGlvbmFsLiBJZiBwcmVzZW50LCBpdCBtdXN0IGJlCiB0aGUgc2FtZSBhcyB0aGUg
dHlwZSBvZiB0aGUgZGF0YSBpbiB0aGUgYHBvaW50c2AgZmllbGQuCgoMCgUEAQIEBhIDVQIn
CgwKBQQBAgQBEgNVKDIKDAoFBAECBAMSA1U1NgraAwoEBAECBRIDXwIcGswDIFRoZSBkYXRh
IHBvaW50cyBvZiB0aGlzIHRpbWUgc2VyaWVzLiBXaGVuIGxpc3RpbmcgdGltZSBzZXJpZXMs
IHBvaW50cyBhcmUKIHJldHVybmVkIGluIHJldmVyc2UgdGltZSBvcmRlci4KCiBXaGVuIGNy
ZWF0aW5nIGEgdGltZSBzZXJpZXMsIHRoaXMgZmllbGQgbXVzdCBjb250YWluIGV4YWN0bHkg
b25lIHBvaW50IGFuZAogdGhlIHBvaW50J3MgdHlwZSBtdXN0IGJlIHRoZSBzYW1lIGFzIHRo
ZSB2YWx1ZSB0eXBlIG9mIHRoZSBhc3NvY2lhdGVkCiBtZXRyaWMuIElmIHRoZSBhc3NvY2lh
dGVkIG1ldHJpYydzIGRlc2NyaXB0b3IgbXVzdCBiZSBhdXRvLWNyZWF0ZWQsIHRoZW4KIHRo
ZSB2YWx1ZSB0eXBlIG9mIHRoZSBkZXNjcmlwdG9yIGlzIGRldGVybWluZWQgYnkgdGhlIHBv
aW50J3MgdHlwZSwgd2hpY2gKIG11c3QgYmUgYEJPT0xgLCBgSU5UNjRgLCBgRE9VQkxFYCwg
b3IgYERJU1RSSUJVVElPTmAuCgoMCgUEAQIFBBIDXwIKCgwKBQQBAgUGEgNfCxAKDAoFBAEC
BQESA18RFwoMCgUEAQIFAxIDXxobCqMCCgQEAQIGEgNlAhIalQIgVGhlIHVuaXRzIGluIHdo
aWNoIHRoZSBtZXRyaWMgdmFsdWUgaXMgcmVwb3J0ZWQuIEl0IGlzIG9ubHkgYXBwbGljYWJs
ZQogaWYgdGhlIGB2YWx1ZV90eXBlYCBpcyBgSU5UNjRgLCBgRE9VQkxFYCwgb3IgYERJU1RS
SUJVVElPTmAuIFRoZSBgdW5pdGAKIGRlZmluZXMgdGhlIHJlcHJlc2VudGF0aW9uIG9mIHRo
ZSBzdG9yZWQgbWV0cmljIHZhbHVlcy4gVGhpcyBmaWVsZCBjYW4gb25seQogYmUgY2hhbmdl
ZCB0aHJvdWdoIENyZWF0ZVRpbWVTZXJpZXMgd2hlbiBpdCBpcyBlbXB0eS4KCgwKBQQBAgYF
EgNlAggKDAoFBAECBgESA2UJDQoMCgUEAQIGAxIDZRARCvUBCgQEAQIHEgNrAhka5wEgSW5w
dXQgb25seS4gQSBkZXRhaWxlZCBkZXNjcmlwdGlvbiBvZiB0aGUgdGltZSBzZXJpZXMgdGhh
dCB3aWxsIGJlCiBhc3NvY2lhdGVkIHdpdGggdGhlCiBbZ29vZ2xlLmFwaS5NZXRyaWNEZXNj
cmlwdG9yXVtnb29nbGUuYXBpLk1ldHJpY0Rlc2NyaXB0b3JdIGZvciB0aGUgbWV0cmljLgog
T25jZSBzZXQsIHRoaXMgZmllbGQgY2Fubm90IGJlIGNoYW5nZWQgdGhyb3VnaCBDcmVhdGVU
aW1lU2VyaWVzLgoKDAoFBAECBwUSA2sCCAoMCgUEAQIHARIDawkUCgwKBQQBAgcDEgNrFxgK
RwoCBAISBW8AhwEBGjogQSBkZXNjcmlwdG9yIGZvciB0aGUgbGFiZWxzIGFuZCBwb2ludHMg
aW4gYSB0aW1lIHNlcmllcy4KCgoKAwQCARIDbwgcCkQKBAQCAwASBXECgAEDGjUgQSBkZXNj
cmlwdG9yIGZvciB0aGUgdmFsdWUgY29sdW1ucyBpbiBhIGRhdGEgcG9pbnQuCgoMCgUEAgMA
ARIDcQoZCh8KBgQCAwACABIDcwQTGhAgVGhlIHZhbHVlIGtleS4KCg4KBwQCAwACAAUSA3ME
CgoOCgcEAgMAAgABEgNzCw4KDgoHBAIDAAIAAxIDcxESCiAKBgQCAwACARIDdgQ5GhEgVGhl
IHZhbHVlIHR5cGUuCgoOCgcEAgMAAgEGEgN2BCkKDgoHBAIDAAIBARIDdio0Cg4KBwQCAwAC
AQMSA3Y3OAonCgYEAgMAAgISA3kEOxoYIFRoZSB2YWx1ZSBzdHJlYW0ga2luZC4KCg4KBwQC
AwACAgYSA3kEKgoOCgcEAgMAAgIBEgN5KzYKDgoHBAIDAAICAxIDeTk6CvABCgYEAgMAAgMS
A38EFBrgASBUaGUgdW5pdCBpbiB3aGljaCBgdGltZV9zZXJpZXNgIHBvaW50IHZhbHVlcyBh
cmUgcmVwb3J0ZWQuIGB1bml0YAogZm9sbG93cyB0aGUgVUNVTSBmb3JtYXQgZm9yIHVuaXRz
IGFzIHNlZW4gaW4KIGh0dHBzOi8vdW5pdHNvZm1lYXN1cmUub3JnL3VjdW0uaHRtbC4KIGB1
bml0YCBpcyBvbmx5IHZhbGlkIGlmIGB2YWx1ZV90eXBlYCBpcyBJTlRFR0VSLCBET1VCTEUs
IERJU1RSSUJVVElPTi4KCg4KBwQCAwACAwUSA38ECgoOCgcEAgMAAgMBEgN/Cw8KDgoHBAID
AAIDAxIDfxITCisKBAQCAgASBIMBAjwaHSBEZXNjcmlwdG9ycyBmb3IgdGhlIGxhYmVscy4K
Cg0KBQQCAgAEEgSDAQIKCg0KBQQCAgAGEgSDAQslCg0KBQQCAgABEgSDASY3Cg0KBQQCAgAD
EgSDATo7Cj0KBAQCAgESBIYBAjEaLyBEZXNjcmlwdG9ycyBmb3IgdGhlIHBvaW50IGRhdGEg
dmFsdWUgY29sdW1ucy4KCg0KBQQCAgEEEgSGAQIKCg0KBQQCAgEGEgSGAQsaCg0KBQQCAgEB
EgSGARssCg0KBQQCAgEDEgSGAS8wCl8KAgQDEgaLAQCfAQEaUSBSZXByZXNlbnRzIHRoZSB2
YWx1ZXMgb2YgYSB0aW1lIHNlcmllcyBhc3NvY2lhdGVkIHdpdGggYQogVGltZVNlcmllc0Rl
c2NyaXB0b3IuCgoLCgMEAwESBIsBCBYK2gEKBAQDAwASBo8BApUBAxrJASBBIHBvaW50J3Mg
dmFsdWUgY29sdW1ucyBhbmQgdGltZSBpbnRlcnZhbC4gRWFjaCBwb2ludCBoYXMgb25lIG9y
IG1vcmUKIHBvaW50IHZhbHVlcyBjb3JyZXNwb25kaW5nIHRvIHRoZSBlbnRyaWVzIGluIGBw
b2ludF9kZXNjcmlwdG9yc2AgZmllbGQgaW4KIHRoZSBUaW1lU2VyaWVzRGVzY3JpcHRvciBh
c3NvY2lhdGVkIHdpdGggdGhpcyBvYmplY3QuCgoNCgUEAwMAARIEjwEKEwo0CgYEAwMAAgAS
BJEBBCMaJCBUaGUgdmFsdWVzIHRoYXQgbWFrZSB1cCB0aGUgcG9pbnQuCgoPCgcEAwMAAgAE
EgSRAQQMCg8KBwQDAwACAAYSBJEBDRcKDwoHBAMDAAIAARIEkQEYHgoPCgcEAwMAAgADEgSR
ASEiCj4KBgQDAwACARIElAEEIxouIFRoZSB0aW1lIGludGVydmFsIGFzc29jaWF0ZWQgd2l0
aCB0aGUgcG9pbnQuCgoPCgcEAwMAAgEGEgSUAQQQCg8KBwQDAwACAQESBJQBER4KDwoHBAMD
AAIBAxIElAEhIgqfAgoEBAMCABIEmwECJxqQAiBUaGUgdmFsdWVzIG9mIHRoZSBsYWJlbHMg
aW4gdGhlIHRpbWUgc2VyaWVzIGlkZW50aWZpZXIsIGdpdmVuIGluIHRoZSBzYW1lCiBvcmRl
ciBhcyB0aGUgYGxhYmVsX2Rlc2NyaXB0b3JzYCBmaWVsZCBvZiB0aGUgVGltZVNlcmllc0Rl
c2NyaXB0b3IKIGFzc29jaWF0ZWQgd2l0aCB0aGlzIG9iamVjdC4gRWFjaCB2YWx1ZSBtdXN0
IGhhdmUgYSB2YWx1ZSBvZiB0aGUgdHlwZQogZ2l2ZW4gaW4gdGhlIGNvcnJlc3BvbmRpbmcg
ZW50cnkgb2YgYGxhYmVsX2Rlc2NyaXB0b3JzYC4KCg0KBQQDAgAEEgSbAQIKCg0KBQQDAgAG
EgSbAQsVCg0KBQQDAgABEgSbARYiCg0KBQQDAgADEgSbASUmCi4KBAQDAgESBJ4BAiQaICBU
aGUgcG9pbnRzIGluIHRoZSB0aW1lIHNlcmllcy4KCg0KBQQDAgEEEgSeAQIKCg0KBQQDAgEG
EgSeAQsUCg0KBQQDAgEBEgSeARUfCg0KBQQDAgEDEgSeASIjCh4KAgQEEgaiAQCuAQEaECBB
IGxhYmVsIHZhbHVlLgoKCwoDBAQBEgSiAQgSCkIKBAQECAASBqQBAq0BAxoyIFRoZSBsYWJl
bCB2YWx1ZSBjYW4gYmUgYSBib29sLCBpbnQ2NCwgb3Igc3RyaW5nLgoKDQoFBAQIAAESBKQB
CA0KIwoEBAQCABIEpgEEGBoVIEEgYm9vbCBsYWJlbCB2YWx1ZS4KCg0KBQQEAgAFEgSmAQQI
Cg0KBQQEAgABEgSmAQkTCg0KBQQEAgADEgSmARYXCiUKBAQEAgESBKkBBBoaFyBBbiBpbnQ2
NCBsYWJlbCB2YWx1ZS4KCg0KBQQEAgEFEgSpAQQJCg0KBQQEAgEBEgSpAQoVCg0KBQQEAgED
EgSpARgZCiUKBAQEAgISBKwBBBwaFyBBIHN0cmluZyBsYWJlbCB2YWx1ZS4KCg0KBQQEAgIF
EgSsAQQKCg0KBQQEAgIBEgSsAQsXCg0KBQQEAgIDEgSsARobCloKAgQFEgaxAQC4AQEaTCBB
biBlcnJvciBhc3NvY2lhdGVkIHdpdGggYSBxdWVyeSBpbiB0aGUgdGltZSBzZXJpZXMgcXVl
cnkgbGFuZ3VhZ2UgZm9ybWF0LgoKCwoDBAUBEgSxAQgSCmAKBAQFAgASBLQBAhoaUiBUaGUg
bG9jYXRpb24gb2YgdGhlIHRpbWUgc2VyaWVzIHF1ZXJ5IGxhbmd1YWdlIHRleHQgdGhhdCB0
aGlzIGVycm9yIGFwcGxpZXMKIHRvLgoKDQoFBAUCAAYSBLQBAg0KDQoFBAUCAAESBLQBDhUK
DQoFBAUCAAMSBLQBGBkKIgoEBAUCARIEtwECFRoUIFRoZSBlcnJvciBtZXNzYWdlLgoKDQoF
BAUCAQUSBLcBAggKDQoFBAUCAQESBLcBCRAKDQoFBAUCAQMSBLcBExQKsgMKAgQGEgbOAQD1
AQEaowMgQSBsb2NhdG9yIGZvciB0ZXh0LiBJbmRpY2F0ZXMgYSBwYXJ0aWN1bGFyIHBhcnQg
b2YgdGhlIHRleHQgb2YgYSByZXF1ZXN0IG9yCiBvZiBhbiBvYmplY3QgcmVmZXJlbmNlZCBp
biB0aGUgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgc3VwcG9zZSB0aGUgcmVxdWVzdCBmaWVs
ZCBgdGV4dGAgY29udGFpbnM6CgogICB0ZXh0OiAiVGhlIHF1aWNrIGJyb3duIGZveCBqdW1w
cyBvdmVyIHRoZSBsYXp5IGRvZy4iCgogVGhlbiB0aGUgbG9jYXRvcjoKCiAgIHNvdXJjZTog
InRleHQiCiAgIHN0YXJ0X3Bvc2l0aW9uIHsKICAgICBsaW5lOiAxCiAgICAgY29sdW1uOiAx
NwogICB9CiAgIGVuZF9wb3NpdGlvbiB7CiAgICAgbGluZTogMQogICAgIGNvbHVtbjogMTkK
ICAgfQoKIHJlZmVycyB0byB0aGUgcGFydCBvZiB0aGUgdGV4dDogImZveCIuCgoLCgMEBgES
BM4BCBMKOQoEBAYDABIG0AEC1wEDGikgVGhlIHBvc2l0aW9uIG9mIGEgYnl0ZSB3aXRoaW4g
dGhlIHRleHQuCgoNCgUEBgMAARIE0AEKEgpKCgYEBgMAAgASBNIBBBMaOiBUaGUgbGluZSwg
c3RhcnRpbmcgd2l0aCAxLCB3aGVyZSB0aGUgYnl0ZSBpcyBwb3NpdGlvbmVkLgoKDwoHBAYD
AAIABRIE0gEECQoPCgcEBgMAAgABEgTSAQoOCg8KBwQGAwACAAMSBNIBERIKkgEKBgQGAwAC
ARIE1gEEFRqBASBUaGUgY29sdW1uIHdpdGhpbiB0aGUgbGluZSwgc3RhcnRpbmcgd2l0aCAx
LCB3aGVyZSB0aGUgYnl0ZSBpcwogcG9zaXRpb25lZC4gVGhpcyBpcyBhIGJ5dGUgaW5kZXgg
ZXZlbiB0aG91Z2ggdGhlIHRleHQgaXMgVVRGLTguCgoPCgcEBgMAAgEFEgTWAQQJCg8KBwQG
AwACAQESBNYBChAKDwoHBAYDAAIBAxIE1gETFAqwAwoEBAYCABIE4AECFBqhAyBUaGUgc291
cmNlIG9mIHRoZSB0ZXh0LiBUaGUgc291cmNlIG1heSBiZSBhIGZpZWxkIGluIHRoZSByZXF1
ZXN0LCBpbiB3aGljaAogY2FzZSBpdHMgZm9ybWF0IGlzIHRoZSBmb3JtYXQgb2YgdGhlCiBn
b29nbGUucnBjLkJhZFJlcXVlc3QuRmllbGRWaW9sYXRpb24uZmllbGQgZmllbGQgaW4KIGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9lcnJvcnMjZXJyb3JfZGV0YWls
cy4gSXQgbWF5IGFsc28gYmUKIGJlIGEgc291cmNlIG90aGVyIHRoYW4gdGhlIHJlcXVlc3Qg
ZmllbGQgKGUuZy4gYSBtYWNybyBkZWZpbml0aW9uCiByZWZlcmVuY2VkIGluIHRoZSB0ZXh0
IG9mIHRoZSBxdWVyeSksIGluIHdoaWNoIGNhc2UgdGhpcyBpcyB0aGUgbmFtZSBvZgogdGhl
IHNvdXJjZSAoZS5nLiB0aGUgbWFjcm8gbmFtZSkuCgoNCgUEBgIABRIE4AECCAoNCgUEBgIA
ARIE4AEJDwoNCgUEBgIAAxIE4AESEwo/CgQEBgIBEgTjAQIeGjEgVGhlIHBvc2l0aW9uIG9m
IHRoZSBmaXJzdCBieXRlIHdpdGhpbiB0aGUgdGV4dC4KCg0KBQQGAgEGEgTjAQIKCg0KBQQG
AgEBEgTjAQsZCg0KBQQGAgEDEgTjARwdCj4KBAQGAgISBOYBAhwaMCBUaGUgcG9zaXRpb24g
b2YgdGhlIGxhc3QgYnl0ZSB3aXRoaW4gdGhlIHRleHQuCgoNCgUEBgICBhIE5gECCgoNCgUE
BgICARIE5gELFwoNCgUEBgICAxIE5gEaGwqRAgoEBAYCAxIE7AECIRqCAiBJZiBgc291cmNl
YCwgYHN0YXJ0X3Bvc2l0aW9uYCwgYW5kIGBlbmRfcG9zaXRpb25gIGRlc2NyaWJlIGEgY2Fs
bCBvbgogc29tZSBvYmplY3QgKGUuZy4gYSBtYWNybyBpbiB0aGUgdGltZSBzZXJpZXMgcXVl
cnkgbGFuZ3VhZ2UgdGV4dCkgYW5kIGEKIGxvY2F0aW9uIGlzIHRvIGJlIGRlc2lnbmF0ZWQg
aW4gdGhhdCBvYmplY3QncyB0ZXh0LCBgbmVzdGVkX2xvY2F0b3JgCiBpZGVudGlmaWVzIHRo
ZSBsb2NhdGlvbiB3aXRoaW4gdGhhdCBvYmplY3QuCgoNCgUEBgIDBhIE7AECDQoNCgUEBgID
ARIE7AEOHAoNCgUEBgIDAxIE7AEfIAqJAwoEBAYCBBIE9AECHBr6AiBXaGVuIGBuZXN0ZWRf
bG9jYXRvcmAgaXMgc2V0LCB0aGlzIGZpZWxkIGdpdmVzIHRoZSByZWFzb24gZm9yIHRoZSBu
ZXN0aW5nLgogVXN1YWxseSwgdGhlIHJlYXNvbiBpcyBhIG1hY3JvIGludm9jYXRpb24uIElu
IHRoYXQgY2FzZSwgdGhlIG1hY3JvIG5hbWUKIChpbmNsdWRpbmcgdGhlIGxlYWRpbmcgJ0An
KSBzaWduYWxzIHRoZSBsb2NhdGlvbiBvZiB0aGUgbWFjcm8gY2FsbAogaW4gdGhlIHRleHQg
YW5kIGEgbWFjcm8gYXJndW1lbnQgbmFtZSAoaW5jbHVkaW5nIHRoZSBsZWFkaW5nICckJykg
c2lnbmFscwogdGhlIGxvY2F0aW9uIG9mIHRoZSBtYWNybyBhcmd1bWVudCBpbnNpZGUgdGhl
IG1hY3JvIGJvZHkgdGhhdCBnb3QKIHN1YnN0aXR1dGVkIGF3YXkuCgoNCgUEBgIEBRIE9AEC
CAoNCgUEBgIEARIE9AEJFwoNCgUEBgIEAxIE9AEaG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::Metric::Point ===
    # Fields for Point
    # Field: interval Type: 11 (.google.monitoring.v3.TimeInterval)
    # Field: value Type: 11 (.google.monitoring.v3.TypedValue)

# === Message: Google::Monitoring::V3::Metric::TimeSeries ===
    # Fields for TimeSeries
    # Field: metric Type: 11 (.google.api.Metric)
    # Field: resource Type: 11 (.google.api.MonitoredResource)
    # Field: metadata Type: 11 (.google.api.MonitoredResourceMetadata)
    # Field: metric_kind Type: 14 (.google.api.MetricDescriptor.MetricKind)
    # Field: value_type Type: 14 (.google.api.MetricDescriptor.ValueType)
    # Field: points Type: 11 (.google.monitoring.v3.Point)
    # Field: unit Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Monitoring::V3::Metric::TimeSeriesDescriptor ===
    # Fields for TimeSeriesDescriptor
    # Field: label_descriptors Type: 11 (.google.api.LabelDescriptor)
    # Field: point_descriptors Type: 11 (.google.monitoring.v3.TimeSeriesDescriptor.ValueDescriptor)

# === Message: Google::Monitoring::V3::Metric::TimeSeriesData ===
    # Fields for TimeSeriesData
    # Field: label_values Type: 11 (.google.monitoring.v3.LabelValue)
    # Field: point_data Type: 11 (.google.monitoring.v3.TimeSeriesData.PointData)

# === Message: Google::Monitoring::V3::Metric::LabelValue ===
    # Fields for LabelValue
    # Field: bool_value Type: 8 ()
    # Field: int64_value Type: 3 ()
    # Field: string_value Type: 9 ()

# === Message: Google::Monitoring::V3::Metric::QueryError ===
    # Fields for QueryError
    # Field: locator Type: 11 (.google.monitoring.v3.TextLocator)
    # Field: message Type: 9 ()

# === Message: Google::Monitoring::V3::Metric::TextLocator ===
    # Fields for TextLocator
    # Field: source Type: 9 ()
    # Field: start_position Type: 11 (.google.monitoring.v3.TextLocator.Position)
    # Field: end_position Type: 11 (.google.monitoring.v3.TextLocator.Position)
    # Field: nested_locator Type: 11 (.google.monitoring.v3.TextLocator)
    # Field: nesting_reason Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::Metric - Compiled Protocol Buffers messages for google/monitoring/v3/metric.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::Metric;

    my $msg = Google::Monitoring::V3::Metric::Point->new({
        interval => $interval,
        value => $value,
    });

    # Read or update a field
    my $val = $msg->interval();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::Metric::Point->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/metric.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::Metric::Point

A single data point in a time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Common::TimeInterval>)

The time interval to which the data point applies.  For `GAUGE` metrics,
the start time is optional, but if it is supplied, it must equal the
end time.  For `DELTA` metrics, the start
and end time should specify a non-zero interval, with subsequent points
specifying contiguous and non-overlapping intervals.  For `CUMULATIVE`
metrics, the start and end time should specify a non-zero interval, with
subsequent points specifying the same start time and increasing end times,
until an event resets the cumulative value to zero and sets a new start
time for the following points.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Common::TypedValue>)

The value of the data point.

=back

=head2 Google::Monitoring::V3::Metric::TimeSeries

A collection of data points that describes the time-varying values
of a metric. A time series is identified by a combination of a
fully-specified monitored resource and a fully-specified metric.
This type is used for both listing and creating time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metric() >> / C<< $msg->metric($value) >>

Type: C<Message> (L<Google::Api::Metric::Metric>)

The associated metric. A fully-specified metric used to identify the time
series.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Api::MonitoredResource::MonitoredResource>)

The associated monitored resource.  Custom metrics can use only certain
monitored resource types in their time series data. For more information,
see [Monitored resources for custom
metrics](https://cloud.google.com/monitoring/custom-metrics/creating-metrics#custom-metric-resources).

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Api::MonitoredResource::MonitoredResourceMetadata>)

Output only. The associated monitored resource metadata. When reading a
time series, this field will include metadata labels that are explicitly
named in the reduction. When creating a time series, this field is ignored.

=item * C<< $msg->metric_kind() >> / C<< $msg->metric_kind($value) >>

Type: C<Enum> (L<Google::Api::MetricDescriptor::MetricKind>)

The metric kind of the time series. When listing time series, this metric
kind might be different from the metric kind of the associated metric if
this time series is an alignment or reduction of other time series.

When creating a time series, this field is optional. If present, it must be
the same as the metric kind of the associated metric. If the associated
metric's descriptor must be auto-created, then this field specifies the
metric kind of the new descriptor and must be either `GAUGE` (the default)
or `CUMULATIVE`.

=item * C<< $msg->value_type() >> / C<< $msg->value_type($value) >>

Type: C<Enum> (L<Google::Api::MetricDescriptor::ValueType>)

The value type of the time series. When listing time series, this value
type might be different from the value type of the associated metric if
this time series is an alignment or reduction of other time series.

When creating a time series, this field is optional. If present, it must be
the same as the type of the data in the `points` field.

=item * C<< $msg->points() >> / C<< $msg->points($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::Point>)

The data points of this time series. When listing time series, points are
returned in reverse time order.

When creating a time series, this field must contain exactly one point and
the point's type must be the same as the value type of the associated
metric. If the associated metric's descriptor must be auto-created, then
the value type of the descriptor is determined by the point's type, which
must be `BOOL`, `INT64`, `DOUBLE`, or `DISTRIBUTION`.

=item * C<< $msg->unit() >> / C<< $msg->unit($value) >>

Type: C<String>

The units in which the metric value is reported. It is only applicable
if the `value_type` is `INT64`, `DOUBLE`, or `DISTRIBUTION`. The `unit`
defines the representation of the stored metric values. This field can only
be changed through CreateTimeSeries when it is empty.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Input only. A detailed description of the time series that will be
associated with the
[google.api.MetricDescriptor][google.api.MetricDescriptor] for the metric.
Once set, this field cannot be changed through CreateTimeSeries.

=back

=head2 Google::Monitoring::V3::Metric::TimeSeriesDescriptor

A descriptor for the labels and points in a time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_descriptors() >> / C<< $msg->label_descriptors($value) >>

Type: C<Message> (L<Google::Api::Label::LabelDescriptor>)

Descriptors for the labels.

=item * C<< $msg->point_descriptors() >> / C<< $msg->point_descriptors($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TimeSeriesDescriptor::ValueDescriptor>)

Descriptors for the point data value columns.

=back

=head2 Google::Monitoring::V3::Metric::TimeSeriesData

Represents the values of a time series associated with a
TimeSeriesDescriptor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_values() >> / C<< $msg->label_values($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::LabelValue>)

The values of the labels in the time series identifier, given in the same
order as the `label_descriptors` field of the TimeSeriesDescriptor
associated with this object. Each value must have a value of the type
given in the corresponding entry of `label_descriptors`.

=item * C<< $msg->point_data() >> / C<< $msg->point_data($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TimeSeriesData::PointData>)

The points in the time series.

=back

=head2 Google::Monitoring::V3::Metric::LabelValue

A label value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

A bool label value.

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

An int64 label value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A string label value.

=back

=head2 Google::Monitoring::V3::Metric::QueryError

An error associated with a query in the time series query language format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->locator() >> / C<< $msg->locator($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TextLocator>)

The location of the time series query language text that this error applies
to.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

The error message.

=back

=head2 Google::Monitoring::V3::Metric::TextLocator

A locator for text. Indicates a particular part of the text of a request or
of an object referenced in the request.

For example, suppose the request field `text` contains:

  text: "The quick brown fox jumps over the lazy dog."

Then the locator:

  source: "text"
  start_position {
    line: 1
    column: 17
  }
  end_position {
    line: 1
    column: 19
  }

refers to the part of the text: "fox".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

The source of the text. The source may be a field in the request, in which
case its format is the format of the
google.rpc.BadRequest.FieldViolation.field field in
https://cloud.google.com/apis/design/errors#error_details. It may also be
be a source other than the request field (e.g. a macro definition
referenced in the text of the query), in which case this is the name of
the source (e.g. the macro name).

=item * C<< $msg->start_position() >> / C<< $msg->start_position($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TextLocator::Position>)

The position of the first byte within the text.

=item * C<< $msg->end_position() >> / C<< $msg->end_position($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TextLocator::Position>)

The position of the last byte within the text.

=item * C<< $msg->nested_locator() >> / C<< $msg->nested_locator($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Metric::TextLocator>)

If `source`, `start_position`, and `end_position` describe a call on
some object (e.g. a macro in the time series query language text) and a
location is to be designated in that object's text, `nested_locator`
identifies the location within that object.

=item * C<< $msg->nesting_reason() >> / C<< $msg->nesting_reason($value) >>

Type: C<String>

When `nested_locator` is set, this field gives the reason for the nesting.
Usually, the reason is a macro invocation. In that case, the macro name
(including the leading '@') signals the location of the macro call
in the text and a macro argument name (including the leading '$') signals
the location of the macro argument inside the macro body that got
substituted away.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::Metric::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
