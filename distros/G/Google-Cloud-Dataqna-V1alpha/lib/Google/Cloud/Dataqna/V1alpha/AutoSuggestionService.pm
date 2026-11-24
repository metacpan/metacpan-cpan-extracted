package Google::Cloud::Dataqna::V1alpha::AutoSuggestionService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dataqna::V1alpha::AnnotatedString };
    eval { require Google::Api::Client };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL2F1dG9fc3VnZ2VzdGlvbl9zZXJ2aWNl
LnByb3RvEhxnb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGjNnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL2Fubm90
YXRlZF9zdHJpbmcucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvIuEBChVTdWdnZXN0
UXVlcmllc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29n
bGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhYKBnNjb3BlcxgCIAMoCVIGc2NvcGVzEhQK
BXF1ZXJ5GAMgASgJUgVxdWVyeRJXChBzdWdnZXN0aW9uX3R5cGVzGAQgAygOMiwuZ29vZ2xl
LmNsb3VkLmRhdGFxbmEudjFhbHBoYS5TdWdnZXN0aW9uVHlwZVIPc3VnZ2VzdGlvblR5cGVz
It8BCgpTdWdnZXN0aW9uElUKD3N1Z2dlc3Rpb25faW5mbxgBIAEoCzIsLmdvb2dsZS5jbG91
ZC5kYXRhcW5hLnYxYWxwaGEuU3VnZ2VzdGlvbkluZm9SDnN1Z2dlc3Rpb25JbmZvEiMKDXJh
bmtpbmdfc2NvcmUYAiABKAFSDHJhbmtpbmdTY29yZRJVCg9zdWdnZXN0aW9uX3R5cGUYAyAB
KA4yLC5nb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhLlN1Z2dlc3Rpb25UeXBlUg5zdWdn
ZXN0aW9uVHlwZSKeAgoOU3VnZ2VzdGlvbkluZm8SYAoUYW5ub3RhdGVkX3N1Z2dlc3Rpb24Y
ASABKAsyLS5nb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhLkFubm90YXRlZFN0cmluZ1IT
YW5ub3RhdGVkU3VnZ2VzdGlvbhJbCg1xdWVyeV9tYXRjaGVzGAIgAygLMjYuZ29vZ2xlLmNs
b3VkLmRhdGFxbmEudjFhbHBoYS5TdWdnZXN0aW9uSW5mby5NYXRjaEluZm9SDHF1ZXJ5TWF0
Y2hlcxpNCglNYXRjaEluZm8SKAoQc3RhcnRfY2hhcl9pbmRleBgBIAEoBVIOc3RhcnRDaGFy
SW5kZXgSFgoGbGVuZ3RoGAIgASgFUgZsZW5ndGgiZAoWU3VnZ2VzdFF1ZXJpZXNSZXNwb25z
ZRJKCgtzdWdnZXN0aW9ucxgBIAMoCzIoLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEu
U3VnZ2VzdGlvblILc3VnZ2VzdGlvbnMqSwoOU3VnZ2VzdGlvblR5cGUSHwobU1VHR0VTVElP
Tl9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGRU5USVRZEAESDAoIVEVNUExBVEUQAjKlAgoVQXV0
b1N1Z2dlc3Rpb25TZXJ2aWNlEr8BCg5TdWdnZXN0UXVlcmllcxIzLmdvb2dsZS5jbG91ZC5k
YXRhcW5hLnYxYWxwaGEuU3VnZ2VzdFF1ZXJpZXNSZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLmRh
dGFxbmEudjFhbHBoYS5TdWdnZXN0UXVlcmllc1Jlc3BvbnNlIkKC0+STAjwiNy92MWFscGhh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn06c3VnZ2VzdFF1ZXJpZXM6ASoaSspB
FmRhdGFxbmEuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtQtwBCiBjb20uZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBo
YUIaQXV0b1N1Z2dlc3Rpb25TZXJ2aWNlUHJvdG9QAVo6Y2xvdWQuZ29vZ2xlLmNvbS9nby9k
YXRhcW5hL2FwaXYxYWxwaGEvZGF0YXFuYXBiO2RhdGFxbmFwYqoCHEdvb2dsZS5DbG91ZC5E
YXRhUW5BLlYxQWxwaGHKAhxHb29nbGVcQ2xvdWRcRGF0YVFuQVxWMWFscGhh6gIfR29vZ2xl
OjpDbG91ZDo6RGF0YVFuQTo6VjFhbHBoYUqgMgoHEgUOANYBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgAmCgkKAgMBEgMTACkKCQoC
AwISAxQAIwoJCgIDAxIDFQA9CgkKAgMEEgMWACEKCAoBCBIDGAA5CgkKAgglEgMYADkKCAoB
CBIDGQBRCgkKAggLEgMZAFEKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA7CgkKAggI
EgMbADsKCAoBCBIDHAA5CgkKAggBEgMcADkKCAoBCBIDHQA5CgkKAggpEgMdADkKCAoBCBID
HgA4CgkKAggtEgMeADgKuA0KAgYAEgRiAG4BGqsNIFRoaXMgc3RhdGVsZXNzIEFQSSBwcm92
aWRlcyBhdXRvbWF0aWMgc3VnZ2VzdGlvbnMgZm9yIG5hdHVyYWwgbGFuZ3VhZ2UKIHF1ZXJp
ZXMgZm9yIHRoZSBkYXRhIHNvdXJjZXMgaW4gdGhlIHByb3ZpZGVkIHByb2plY3QgYW5kIGxv
Y2F0aW9uLgoKIFRoZSBzZXJ2aWNlIHByb3ZpZGVzIGEgcmVzb3VyY2VsZXNzIG9wZXJhdGlv
biBgc3VnZ2VzdFF1ZXJpZXNgIHRoYXQgY2FuIGJlCiBjYWxsZWQgdG8gZ2V0IGEgbGlzdCBv
ZiBzdWdnZXN0aW9ucyBmb3IgYSBnaXZlbiBpbmNvbXBsZXRlIHF1ZXJ5IGFuZCBzY29wZQog
KG9yIGxpc3Qgb2Ygc2NvcGVzKSB1bmRlciB3aGljaCB0aGUgcXVlcnkgaXMgdG8gYmUgaW50
ZXJwcmV0ZWQuCgogVGhlcmUgYXJlIHR3byB0eXBlcyBvZiBzdWdnZXN0aW9ucywgRU5USVRZ
IGZvciBzaW5nbGUgZW50aXR5IHN1Z2dlc3Rpb25zCiBhbmQgVEVNUExBVEUgZm9yIGZ1bGwg
c2VudGVuY2VzLiBCeSBkZWZhdWx0LCBib3RoIHR5cGVzIGFyZSByZXR1cm5lZC4KCiBFeGFt
cGxlIFJlcXVlc3Q6CiBgYGAKIEdldFN1Z2dlc3Rpb25zKHsKICAgcGFyZW50OiAibG9jYXRp
b25zL3VzL3Byb2plY3RzL215LXByb2plY3QiCiAgIHNjb3BlczoKICAgIi8vYmlncXVlcnku
Z29vZ2xlYXBpcy5jb20vcHJvamVjdHMvbXktcHJvamVjdC9kYXRhc2V0cy9teS1kYXRhc2V0
L3RhYmxlcy9teS10YWJsZSIKICAgcXVlcnk6ICJ0b3AgaXQiCiB9KQogYGBgCgogVGhlIHNl
cnZpY2Ugd2lsbCByZXRyaWV2ZSBpbmZvcm1hdGlvbiBiYXNlZCBvbiB0aGUgZ2l2ZW4gc2Nv
cGUocykgYW5kIGdpdmUKIHN1Z2dlc3Rpb25zIGJhc2VkIG9uIHRoYXQgKGUuZy4gInRvcCBp
dGVtIiBmb3IgInRvcCBpdCIgaWYgIml0ZW0iIGlzIGEga25vd24KIGRpbWVuc2lvbiBmb3Ig
dGhlIHByb3ZpZGVkIHNjb3BlKS4KIGBgYAogc3VnZ2VzdGlvbnMgewogICBzdWdnZXN0aW9u
X2luZm8gewogICAgIGFubm90YXRlZF9zdWdnZXN0aW9uIHsKICAgICAgIHRleHRfZm9ybWF0
dGVkOiAidG9wIGl0ZW0gYnkgc3VtIG9mIHVzZF9yZXZlbnVlX25ldCIKICAgICAgIG1hcmt1
cHMgewogICAgICAgICB0eXBlOiBESU1FTlNJT04KICAgICAgICAgc3RhcnRfY2hhcl9pbmRl
eDogNAogICAgICAgICBsZW5ndGg6IDQKICAgICAgIH0KICAgICAgIG1hcmt1cHMgewogICAg
ICAgICB0eXBlOiBNRVRSSUMKICAgICAgICAgc3RhcnRfY2hhcl9pbmRleDogMTkKICAgICAg
ICAgbGVuZ3RoOiAxNQogICAgICAgfQogICAgIH0KICAgICBxdWVyeV9tYXRjaGVzIHsKICAg
ICAgIHN0YXJ0X2NoYXJfaW5kZXg6IDAKICAgICAgIGxlbmd0aDogNgogICAgIH0KICAgfQog
ICBzdWdnZXN0aW9uX3R5cGU6IFRFTVBMQVRFCiAgIHJhbmtpbmdfc2NvcmU6IDAuOQogfQog
c3VnZ2VzdGlvbnMgewogICBzdWdnZXN0aW9uX2luZm8gewogICAgIGFubm90YXRlZF9zdWdn
ZXN0aW9uIHsKICAgICAgIHRleHRfZm9ybWF0dGVkOiAiaXRlbSIKICAgICAgIG1hcmt1cHMg
ewogICAgICAgICB0eXBlOiBESU1FTlNJT04KICAgICAgICAgc3RhcnRfY2hhcl9pbmRleDog
NAogICAgICAgICBsZW5ndGg6IDIKICAgICAgIH0KICAgICB9CiAgICAgcXVlcnlfbWF0Y2hl
cyB7CiAgICAgICBzdGFydF9jaGFyX2luZGV4OiAwCiAgICAgICBsZW5ndGg6IDYKICAgICB9
CiAgIH0KICAgc3VnZ2VzdGlvbl90eXBlOiBFTlRJVFkKICAgcmFua2luZ19zY29yZTogMC44
CiB9CiBgYGAKCgoKAwYAARIDYggdCgoKAwYAAxIDYwI+CgwKBQYAA5kIEgNjAj4KCgoDBgAD
EgNkAlYKDAoFBgADmggSA2QCVgp8CgQGAAIAEgRoAm0DGm4gR2V0cyBhIGxpc3Qgb2Ygc3Vn
Z2VzdGlvbnMgYmFzZWQgb24gYSBwcmVmaXggc3RyaW5nLgogQXV0b1N1Z2dlc3Rpb24gdG9s
ZXJhbmNlIHNob3VsZCBiZSBsZXNzIHRoYW4gMSBzZWNvbmQuCgoMCgUGAAIAARIDaAYUCgwK
BQYAAgACEgNoFSoKDAoFBgACAAMSA2g1SwoNCgUGAAIABBIEaQRsBgoRCgkGAAIABLDKvCIS
BGkEbAYKLQoCBAASBXEAjAEBGiAgUmVxdWVzdCBmb3IgcXVlcnkgc3VnZ2VzdGlvbnMuCgoK
CgMEAAESA3EIHQpwCgQEAAIAEgR0AnkEGmIgUmVxdWlyZWQuIFRoZSBwYXJlbnQgb2YgdGhl
IHN1Z2dlc3Rpb24gcXVlcnkgaXMgdGhlIHJlc291cmNlIGRlbm90aW5nIHRoZSBwcm9qZWN0
IGFuZAogbG9jYXRpb24uCgoMCgUEAAIABRIDdAIICgwKBQQAAgABEgN0CQ8KDAoFBAACAAMS
A3QSEwoNCgUEAAIACBIEdBR5AwoPCggEAAIACJwIABIDdQQqCg8KBwQAAgAInwgSBHYEeAUK
wwEKBAQAAgESA34CHRq1ASBUaGUgc2NvcGVzIHRvIHdoaWNoIHRoaXMgc2VhcmNoIGlzIHJl
c3RyaWN0ZWQuIFRoZSBvbmx5IHN1cHBvcnRlZCBzY29wZQogcGF0dGVybiBpcwogYC8vYmln
cXVlcnkuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMve0dDUC1QUk9KRUNULUlEfS9kYXRhc2V0
cy97REFUQVNFVC1JRH0vdGFibGVzL3tUQUJMRS1JRH1gLgoKDAoFBAACAQQSA34CCgoMCgUE
AAIBBRIDfgsRCgwKBQQAAgEBEgN+EhgKDAoFBAACAQMSA34bHArxAQoEBAACAhIEhAECExri
ASBVc2VyIHF1ZXJ5IGZvciB3aGljaCB0byBnZW5lcmF0ZSBzdWdnZXN0aW9ucy4gSWYgdGhl
IHF1ZXJ5IGlzIGVtcHR5LCB6ZXJvCiBzdGF0ZSBzdWdnZXN0aW9ucyBhcmUgcmV0dXJuZWQu
IFRoaXMgYWxsb3dzIFVJcyB0byBkaXNwbGF5IHN1Z2dlc3Rpb25zCiByaWdodCBhd2F5LCBo
ZWxwaW5nIHRoZSB1c2VyIHRvIGdldCBhIHNlbnNlIG9mIHdoYXQgYSBxdWVyeSBtaWdodCBs
b29rCiBsaWtlLgoKDQoFBAACAgUSBIQBAggKDQoFBAACAgESBIQBCQ4KDQoFBAACAgMSBIQB
ERIKvQIKBAQAAgMSBIsBAi8argIgVGhlIHJlcXVlc3RlZCBzdWdnZXN0aW9uIHR5cGUuIE11
bHRpcGxlIHN1Z2dlc3Rpb24gdHlwZXMgY2FuIGJlCiByZXF1ZXN0ZWQsIGJ1dCB0aGVyZSBp
cyBubyBndWFyYW50ZWUgdGhhdCB0aGUgc2VydmljZSB3aWxsIHJldHVybgogc3VnZ2VzdGlv
bnMgZm9yIGVhY2ggdHlwZS4gU3VnZ2VzdGlvbnMgZm9yIGEgcmVxdWVzdGVkIHR5cGUgbWln
aHQgcmFuawogbG93ZXIgdGhhbiBzdWdnZXN0aW9ucyBmb3Igb3RoZXIgdHlwZXMgYW5kIHRo
ZSBzZXJ2aWNlIG1heSBkZWNpZGUgdG8gY3V0CiB0aGVzZSBzdWdnZXN0aW9ucyBvZmYuCgoN
CgUEAAIDBBIEiwECCgoNCgUEAAIDBhIEiwELGQoNCgUEAAIDARIEiwEaKgoNCgUEAAIDAxIE
iwEtLgo+CgIEARIGjwEAmgEBGjAgQSBzdWdnZXN0aW9uIGZvciBhIHF1ZXJ5IHdpdGggYSBy
YW5raW5nIHNjb3JlLgoKCwoDBAEBEgSPAQgSCjoKBAQBAgASBJEBAiUaLCBEZXRhaWxlZCBp
bmZvcm1hdGlvbiBhYm91dCB0aGUgc3VnZ2VzdGlvbi4KCg0KBQQBAgAGEgSRAQIQCg0KBQQB
AgABEgSRAREgCg0KBQQBAgADEgSRASMkCtIBCgQEAQIBEgSWAQIbGsMBIFRoZSBzY29yZSBv
ZiB0aGUgc3VnZ2VzdGlvbi4gVGhpcyBjYW4gYmUgdXNlZCB0byBkZWZpbmUgb3JkZXJpbmcg
aW4gVUkuCiBUaGUgc2NvcmUgcmVwcmVzZW50cyBjb25maWRlbmNlIGluIHRoZSBzdWdnZXN0
aW9uIHdoZXJlIGhpZ2hlciBpcyBiZXR0ZXIuCiBBbGwgc2NvcmUgdmFsdWVzIG11c3QgYmUg
aW4gdGhlIHJhbmdlIFswLCAxKS4KCg0KBQQBAgEFEgSWAQIICg0KBQQBAgEBEgSWAQkWCg0K
BQQBAgEDEgSWARkaCisKBAQBAgISBJkBAiUaHSBUaGUgdHlwZSBvZiB0aGUgc3VnZ2VzdGlv
bi4KCg0KBQQBAgIGEgSZAQIQCg0KBQQBAgIBEgSZAREgCg0KBQQBAgIDEgSZASMkCjoKAgQC
EgadAQDEAQEaLCBEZXRhaWxlZCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgc3VnZ2VzdGlvbi4K
CgsKAwQCARIEnQEIFgruBQoEBAIDABIGtgECvAEDGt0FIE1hdGNoSW5mbyBkZXNjcmliZXMg
d2hpY2ggcGFydCBvZiBzdWdnZXN0aW9uIG1hdGNoZWQgd2l0aCBkYXRhIGluIHVzZXIKIHR5
cGVkIHF1ZXJ5LiBUaGlzIGNhbiBiZSB1c2VkIHRvIGhpZ2hsaWdodCBtYXRjaGluZyBwYXJ0
cyBpbiB0aGUgVUkuIFRoaXMKIGlzIGRpZmZlcmVudCBmcm9tIHRoZSBhbm5vdGF0aW9ucyBw
cm92aWRlZCBpbiBhbm5vdGF0ZWRfc3VnZ2VzdGlvbi4gVGhlCiBhbm5vdGF0ZWRfc3VnZ2Vz
dGlvbiBwcm92aWRlcyBpbmZvcm1hdGlvbiBhYm91dCB0aGUgc2VtYW50aWMgbWVhbmluZywg
d2hpbGUKIHRoaXMgcHJvdmlkZXMgaW5mb3JtYXRpb24gYWJvdXQgaG93IGl0IHJlbGF0ZXMg
dG8gdGhlIGlucHV0LgoKIEV4YW1wbGU6CiB1c2VyIHF1ZXJ5OiBgdG9wIHByb2R1Y3RzYAoK
IGBgYAogYW5ub3RhdGVkX3N1Z2dlc3Rpb24gewogIHRleHRfZm9ybWF0dGVkID0gInRvcCBw
cm9kdWN0X2dyb3VwIgogIGh0bWxfZm9ybWF0dGVkID0gInRvcCA8Yj5wcm9kdWN0X2dyb3Vw
PC9iPiIKICBtYXJrdXBzIHsKICAge3R5cGU6IFRFWFQsIHN0YXJ0X2NoYXJfaW5kZXg6IDAs
IGxlbmd0aDogM30KICAge3R5cGU6IERJTUVOU0lPTiwgc3RhcnRfY2hhcl9pbmRleDogNCwg
bGVuZ3RoOiAxM30KICB9CiB9CgogcXVlcnlfbWF0Y2hlcyB7CiAgeyBzdGFydF9jaGFyX2lu
ZGV4OiAwLCBsZW5ndGg6IDMgfQogIHsgc3RhcnRfY2hhcl9pbmRleDogNCwgbGVuZ3RoOiA3
fQogfQogYGBgCgoNCgUEAgMAARIEtgEKEwpDCgYEAgMAAgASBLgBBB8aMyBVbmljb2RlIGNo
YXJhY3RlciBpbmRleCBvZiB0aGUgc3RyaW5nIGFubm90YXRpb24uCgoPCgcEAgMAAgAFEgS4
AQQJCg8KBwQCAwACAAESBLgBChoKDwoHBAIDAAIAAxIEuAEdHgpACgYEAgMAAgESBLsBBBUa
MCBDb3VudCBvZiB1bmljb2RlIGNoYXJhY3RlcnMgb2YgdGhpcyBzdWJzdHJpbmcuCgoPCgcE
AgMAAgEFEgS7AQQJCg8KBwQCAwACAQESBLsBChAKDwoHBAIDAAIBAxIEuwETFAqkAQoEBAIC
ABIEwAECKxqVASBBbm5vdGF0aW9ucyBmb3IgdGhlIHN1Z2dlc3Rpb24uIFRoaXMgcHJvdmlk
ZXMgaW5mb3JtYXRpb24gYWJvdXQgd2hpY2ggcGFydAogb2YgdGhlIHN1Z2dlc3Rpb24gY29y
cmVzcG9uZHMgdG8gd2hhdCBzZW1hbnRpYyBtZWFuaW5nIChlLmcuIGEgbWV0cmljKS4KCg0K
BQQCAgAGEgTAAQIRCg0KBQQCAgABEgTAARImCg0KBQQCAgADEgTAASkqCkQKBAQCAgESBMMB
AicaNiBNYXRjaGVzIGJldHdlZW4gdXNlciBxdWVyeSBhbmQgdGhlIGFubm90YXRlZCBzdHJp
bmcuCgoNCgUEAgIBBBIEwwECCgoNCgUEAgIBBhIEwwELFAoNCgUEAgIBARIEwwEVIgoNCgUE
AgIBAxIEwwElJgorCgIEAxIGxwEAygEBGh0gUmVzcG9uc2UgdG8gU3VnZ2VzdFF1ZXJpZXMu
CgoLCgMEAwESBMcBCB4KJgoEBAMCABIEyQECJhoYIEEgbGlzdCBvZiBzdWdnZXN0aW9ucy4K
Cg0KBQQDAgAEEgTJAQIKCg0KBQQDAgAGEgTJAQsVCg0KBQQDAgABEgTJARYhCg0KBQQDAgAD
EgTJASQlCicKAgUAEgbNAQDWAQEaGSBUaGUgdHlwZSBvZiBzdWdnZXN0aW9uLgoKCwoDBQAB
EgTNAQUTCjEKBAUAAgASBM8BAiIaIyBObyBzdWdnZXN0aW9udCB0eXBlIGlzIHNwZWNpZmll
ZC4KCg0KBQUAAgABEgTPAQIdCg0KBQUAAgACEgTPASAhCkwKBAUAAgESBNIBAg0aPiBFbnRp
dHkgc3VnZ2VzdGlvbiB0eXBlLiBTdWdnZXN0aW9ucyBhcmUgZm9yIHNpbmdsZSBlbnRpdGll
cy4KCg0KBQUAAgEBEgTSAQIICg0KBQUAAgECEgTSAQsMCk0KBAUAAgISBNUBAg8aPyBUZW1w
bGF0ZSBzdWdnZXN0aW9uIHR5cGUuIFN1Z2dlc3Rpb25zIGFyZSBmb3IgZnVsbCBzZW50ZW5j
ZXMuCgoNCgUFAAICARIE1QECCgoNCgUFAAICAhIE1QENDmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest ===
    # Fields for SuggestQueriesRequest
    # Field: parent Type: 9 ()
    # Field: scopes Type: 9 ()
    # Field: query Type: 9 ()
    # Field: suggestion_types Type: 14 (.google.cloud.dataqna.v1alpha.SuggestionType)

# === Message: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion ===
    # Fields for Suggestion
    # Field: suggestion_info Type: 11 (.google.cloud.dataqna.v1alpha.SuggestionInfo)
    # Field: ranking_score Type: 1 ()
    # Field: suggestion_type Type: 14 (.google.cloud.dataqna.v1alpha.SuggestionType)

# === Message: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo ===
    # Fields for SuggestionInfo
    # Field: annotated_suggestion Type: 11 (.google.cloud.dataqna.v1alpha.AnnotatedString)
    # Field: query_matches Type: 11 (.google.cloud.dataqna.v1alpha.SuggestionInfo.MatchInfo)

# === Message: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse ===
    # Fields for SuggestQueriesResponse
    # Field: suggestions Type: 11 (.google.cloud.dataqna.v1alpha.Suggestion)

# === Service Client: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::AutoSuggestionServiceClient ===
package Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::AutoSuggestionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::AutoSuggestionServiceClient

Client stub representing the remote C<AutoSuggestionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dataqna.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataqna.googleapis.com:443' );

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

sub suggest_queries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.AutoSuggestionService',
        method         => 'SuggestQueries',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataqna::V1alpha::AutoSuggestionService - Compiled Protocol Buffers messages for google/cloud/dataqna/v1alpha/auto_suggestion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataqna::V1alpha::AutoSuggestionService;

    my $msg = Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest->new({
        parent => $parent,
        scopes => $scopes,
        query => $query,
        suggestion_types => $suggestion_types,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataqna/v1alpha/auto_suggestion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest

Request for query suggestions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the suggestion query is the resource denoting the project and
location.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

The scopes to which this search is restricted. The only supported scope
pattern is
`//bigquery.googleapis.com/projects/{GCP-PROJECT-ID}/datasets/{DATASET-ID}/tables/{TABLE-ID}`.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

User query for which to generate suggestions. If the query is empty, zero
state suggestions are returned. This allows UIs to display suggestions
right away, helping the user to get a sense of what a query might look
like.

=item * C<< $msg->suggestion_types() >> / C<< $msg->suggestion_types($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::SuggestionType>)

The requested suggestion type. Multiple suggestion types can be
requested, but there is no guarantee that the service will return
suggestions for each type. Suggestions for a requested type might rank
lower than suggestions for other types and the service may decide to cut
these suggestions off.

=back

=head2 Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion

A suggestion for a query with a ranking score.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->suggestion_info() >> / C<< $msg->suggestion_info($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo>)

Detailed information about the suggestion.

=item * C<< $msg->ranking_score() >> / C<< $msg->ranking_score($value) >>

Type: C<Double>

The score of the suggestion. This can be used to define ordering in UI.
The score represents confidence in the suggestion where higher is better.
All score values must be in the range [0, 1).

=item * C<< $msg->suggestion_type() >> / C<< $msg->suggestion_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::SuggestionType>)

The type of the suggestion.

=back

=head2 Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo

Detailed information about the suggestion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotated_suggestion() >> / C<< $msg->annotated_suggestion($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString>)

Annotations for the suggestion. This provides information about which part
of the suggestion corresponds to what semantic meaning (e.g. a metric).

=item * C<< $msg->query_matches() >> / C<< $msg->query_matches($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo::MatchInfo>)

Matches between user query and the annotated string.

=back

=head2 Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse

Response to SuggestQueries.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->suggestions() >> / C<< $msg->suggestions($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion>)

A list of suggestions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
