package Google::Cloud::Pubsublite::V1::Publisher;

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
    eval { require Google::Cloud::Pubsublite::V1::Common };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92MS9wdWJsaXNoZXIucHJvdG8SGmdvb2dsZS5j
bG91ZC5wdWJzdWJsaXRlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxonZ29vZ2xlL2Nsb3VkL3B1YnN1YmxpdGUvdjEvY29tbW9u
LnByb3RvImgKFUluaXRpYWxQdWJsaXNoUmVxdWVzdBIUCgV0b3BpYxgBIAEoCVIFdG9waWMS
HAoJcGFydGl0aW9uGAIgASgDUglwYXJ0aXRpb24SGwoJY2xpZW50X2lkGAMgASgMUghjbGll
bnRJZCIYChZJbml0aWFsUHVibGlzaFJlc3BvbnNlIpIBChVNZXNzYWdlUHVibGlzaFJlcXVl
c3QSRQoIbWVzc2FnZXMYASADKAsyKS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5QdWJT
dWJNZXNzYWdlUghtZXNzYWdlcxIyChVmaXJzdF9zZXF1ZW5jZV9udW1iZXIYAiABKANSE2Zp
cnN0U2VxdWVuY2VOdW1iZXIi2QIKFk1lc3NhZ2VQdWJsaXNoUmVzcG9uc2USRQoMc3RhcnRf
Y3Vyc29yGAEgASgLMiIuZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuQ3Vyc29yUgtzdGFy
dEN1cnNvchJjCg1jdXJzb3JfcmFuZ2VzGAIgAygLMj4uZ29vZ2xlLmNsb3VkLnB1YnN1Ymxp
dGUudjEuTWVzc2FnZVB1Ymxpc2hSZXNwb25zZS5DdXJzb3JSYW5nZVIMY3Vyc29yUmFuZ2Vz
GpIBCgtDdXJzb3JSYW5nZRJFCgxzdGFydF9jdXJzb3IYASABKAsyIi5nb29nbGUuY2xvdWQu
cHVic3VibGl0ZS52MS5DdXJzb3JSC3N0YXJ0Q3Vyc29yEh8KC3N0YXJ0X2luZGV4GAIgASgF
UgpzdGFydEluZGV4EhsKCWVuZF9pbmRleBgDIAEoBVIIZW5kSW5kZXgi6wEKDlB1Ymxpc2hS
ZXF1ZXN0ElwKD2luaXRpYWxfcmVxdWVzdBgBIAEoCzIxLmdvb2dsZS5jbG91ZC5wdWJzdWJs
aXRlLnYxLkluaXRpYWxQdWJsaXNoUmVxdWVzdEgAUg5pbml0aWFsUmVxdWVzdBJrChdtZXNz
YWdlX3B1Ymxpc2hfcmVxdWVzdBgCIAEoCzIxLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYx
Lk1lc3NhZ2VQdWJsaXNoUmVxdWVzdEgAUhVtZXNzYWdlUHVibGlzaFJlcXVlc3RCDgoMcmVx
dWVzdF90eXBlIuQBCg9QdWJsaXNoUmVzcG9uc2USXwoQaW5pdGlhbF9yZXNwb25zZRgBIAEo
CzIyLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkluaXRpYWxQdWJsaXNoUmVzcG9uc2VI
AFIPaW5pdGlhbFJlc3BvbnNlEl8KEG1lc3NhZ2VfcmVzcG9uc2UYAiABKAsyMi5nb29nbGUu
Y2xvdWQucHVic3VibGl0ZS52MS5NZXNzYWdlUHVibGlzaFJlc3BvbnNlSABSD21lc3NhZ2VS
ZXNwb25zZUIPCg1yZXNwb25zZV90eXBlMssBChBQdWJsaXNoZXJTZXJ2aWNlEmgKB1B1Ymxp
c2gSKi5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5QdWJsaXNoUmVxdWVzdBorLmdvb2ds
ZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlB1Ymxpc2hSZXNwb25zZSIAKAEwARpNykEZcHVic3Vi
bGl0ZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm1C0gEKIWNvbS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS5wcm90b0IO
UHVibGlzaGVyUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9wdWJzdWJsaXRlL2FwaXYx
L3B1YnN1YmxpdGVwYjtwdWJzdWJsaXRlcGL4AQGqAhpHb29nbGUuQ2xvdWQuUHViU3ViTGl0
ZS5WMcoCGkdvb2dsZVxDbG91ZFxQdWJTdWJMaXRlXFYx6gIdR29vZ2xlOjpDbG91ZDo6UHVi
U3ViTGl0ZTo6VjFK2isKBxIFDgCRAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUADEKCAoBCBID
FgAfCgkKAggfEgMWAB8KCAoBCBIDFwA3CgkKAgglEgMXADcKCAoBCBIDGABVCgkKAggLEgMY
AFUKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAvCgkKAggIEgMaAC8KCAoBCBIDGwA6
CgkKAggBEgMbADoKCAoBCBIDHAA3CgkKAggpEgMcADcKCAoBCBIDHQA2CgkKAggtEgMdADYK
tgIKAgYAEgQjADABGqkCIFRoZSBzZXJ2aWNlIHRoYXQgYSBwdWJsaXNoZXIgY2xpZW50IGFw
cGxpY2F0aW9uIHVzZXMgdG8gcHVibGlzaCBtZXNzYWdlcyB0bwogdG9waWNzLiBQdWJsaXNo
ZWQgbWVzc2FnZXMgYXJlIHJldGFpbmVkIGJ5IHRoZSBzZXJ2aWNlIGZvciB0aGUgZHVyYXRp
b24gb2YKIHRoZSByZXRlbnRpb24gcGVyaW9kIGNvbmZpZ3VyZWQgZm9yIHRoZSByZXNwZWN0
aXZlIHRvcGljLCBhbmQgYXJlIGRlbGl2ZXJlZAogdG8gc3Vic2NyaWJlciBjbGllbnRzIHVw
b24gcmVxdWVzdCAodmlhIHRoZSBgU3Vic2NyaWJlclNlcnZpY2VgKS4KCgoKAwYAARIDIwgY
CgoKAwYAAxIDJAJBCgwKBQYAA5kIEgMkAkEKCwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3
CvADCgQGAAIAEgMvAkga4gMgRXN0YWJsaXNoZXMgYSBzdHJlYW0gd2l0aCB0aGUgc2VydmVy
IGZvciBwdWJsaXNoaW5nIG1lc3NhZ2VzLiBPbmNlIHRoZQogc3RyZWFtIGlzIGluaXRpYWxp
emVkLCB0aGUgY2xpZW50IHB1Ymxpc2hlcyBtZXNzYWdlcyBieSBzZW5kaW5nIHB1Ymxpc2gK
IHJlcXVlc3RzIG9uIHRoZSBzdHJlYW0uIFRoZSBzZXJ2ZXIgcmVzcG9uZHMgd2l0aCBhIFB1
Ymxpc2hSZXNwb25zZSBmb3IgZWFjaAogUHVibGlzaFJlcXVlc3Qgc2VudCBieSB0aGUgY2xp
ZW50LCBpbiB0aGUgc2FtZSBvcmRlciB0aGF0IHRoZSByZXF1ZXN0cwogd2VyZSBzZW50LiBO
b3RlIHRoYXQgbXVsdGlwbGUgUHVibGlzaFJlcXVlc3RzIGNhbiBiZSBpbiBmbGlnaHQKIHNp
bXVsdGFuZW91c2x5LCBidXQgdGhleSB3aWxsIGJlIHByb2Nlc3NlZCBieSB0aGUgc2VydmVy
IGluIHRoZSBvcmRlciB0aGF0CiB0aGV5IGFyZSBzZW50IGJ5IHRoZSBjbGllbnQgb24gYSBn
aXZlbiBzdHJlYW0uCgoMCgUGAAIAARIDLwYNCgwKBQYAAgAFEgMvDhQKDAoFBgACAAISAy8V
IwoMCgUGAAIABhIDLy40CgwKBQYAAgADEgMvNUQKSwoCBAASBDMARAEaPyBUaGUgZmlyc3Qg
cmVxdWVzdCB0aGF0IG11c3QgYmUgc2VudCBvbiBhIG5ld2x5LW9wZW5lZCBzdHJlYW0uCgoK
CgMEAAESAzMIHQo7CgQEAAIAEgM1AhMaLiBUaGUgdG9waWMgdG8gd2hpY2ggbWVzc2FnZXMg
d2lsbCBiZSB3cml0dGVuLgoKDAoFBAACAAUSAzUCCAoMCgUEAAIAARIDNQkOCgwKBQQAAgAD
EgM1ERIKrwEKBAQAAgESAzoCFhqhASBUaGUgcGFydGl0aW9uIHdpdGhpbiB0aGUgdG9waWMg
dG8gd2hpY2ggbWVzc2FnZXMgd2lsbCBiZSB3cml0dGVuLgogUGFydGl0aW9ucyBhcmUgemVy
byBpbmRleGVkLCBzbyBgcGFydGl0aW9uYCBtdXN0IGJlIGluIHRoZSByYW5nZSBbMCwKIHRv
cGljLm51bV9wYXJ0aXRpb25zKS4KCgwKBQQAAgEFEgM6AgcKDAoFBAACAQESAzoIEQoMCgUE
AAIBAxIDOhQVCoEDCgQEAAICEgNDAhYa8wIgVW5pcXVlIGlkZW50aWZpZXIgZm9yIGEgcHVi
bGlzaGVyIGNsaWVudC4gSWYgc2V0LCBlbmFibGVzIHB1Ymxpc2gKIGlkZW1wb3RlbmN5IHdp
dGhpbiBhIHB1Ymxpc2hlciBjbGllbnQgc2Vzc2lvbi4KCiBUaGUgbGVuZ3RoIG9mIHRoaXMg
ZmllbGQgbXVzdCBiZSBleGFjdGx5IDE2IGJ5dGVzIGxvbmcgYW5kIHNob3VsZCBiZQogcG9w
dWxhdGVkIHdpdGggYSAxMjggYml0IHV1aWQsIGdlbmVyYXRlZCBieSBzdGFuZGFyZCB1dWlk
IGFsZ29yaXRobXMgbGlrZQogdXVpZDEgb3IgdXVpZDQuIFRoZSBzYW1lIGlkZW50aWZpZXIg
c2hvdWxkIGJlIHJldXNlZCBmb2xsb3dpbmcKIGRpc2Nvbm5lY3Rpb25zIHdpdGggcmV0cnlh
YmxlIHN0cmVhbSBlcnJvcnMuCgoMCgUEAAICBRIDQwIHCgwKBQQAAgIBEgNDCBEKDAoFBAAC
AgMSA0MUFQoyCgIEARIDRwAhGicgUmVzcG9uc2UgdG8gYW4gSW5pdGlhbFB1Ymxpc2hSZXF1
ZXN0LgoKCgoDBAEBEgNHCB4KNwoCBAISBEoAWgEaKyBSZXF1ZXN0IHRvIHB1Ymxpc2ggbWVz
c2FnZXMgdG8gdGhlIHRvcGljLgoKCgoDBAIBEgNKCB0KJwoEBAICABIDTAImGhogVGhlIG1l
c3NhZ2VzIHRvIHB1Ymxpc2guCgoMCgUEAgIABBIDTAIKCgwKBQQCAgAGEgNMCxgKDAoFBAIC
AAESA0wZIQoMCgUEAgIAAxIDTCQlCtEFCgQEAgIBEgNZAiIawwUgVGhlIHNlcXVlbmNlIG51
bWJlciBjb3JyZXNwb25kaW5nIHRvIHRoZSBmaXJzdCBtZXNzYWdlIGluIGBtZXNzYWdlc2Au
CiBNZXNzYWdlcyB3aXRoaW4gYSBiYXRjaCBhcmUgb3JkZXJlZCBhbmQgdGhlIHNlcXVlbmNl
IG51bWJlcnMgb2YgYWxsCiBzdWJzZXF1ZW50IG1lc3NhZ2VzIGluIHRoZSBiYXRjaCBhcmUg
YXNzdW1lZCB0byBiZSBpbmNyZW1lbnRhbC4KCiBTZXF1ZW5jZSBudW1iZXJzIGFyZSBhc3Np
Z25lZCBhdCB0aGUgbWVzc2FnZSBsZXZlbCBhbmQgdGhlIGZpcnN0IG1lc3NhZ2UKIHB1Ymxp
c2hlZCBpbiBhIHB1Ymxpc2hlciBjbGllbnQgc2Vzc2lvbiBtdXN0IGhhdmUgYSBzZXF1ZW5j
ZSBudW1iZXIgb2YgMC4KIEFsbCBtZXNzYWdlcyBtdXN0IGhhdmUgY29udGlndW91cyBzZXF1
ZW5jZSBudW1iZXJzLCB3aGljaCB1bmlxdWVseSBpZGVudGlmeQogdGhlIG1lc3NhZ2VzIGFj
Y2VwdGVkIGJ5IHRoZSBwdWJsaXNoZXIgY2xpZW50LiBTaW5jZSBtZXNzYWdlcyBhcmUgb3Jk
ZXJlZCwKIHRoZSBjbGllbnQgb25seSBuZWVkcyB0byBzcGVjaWZ5IHRoZSBzZXF1ZW5jZSBu
dW1iZXIgb2YgdGhlIGZpcnN0IG1lc3NhZ2UKIGluIGEgcHVibGlzaGVkIGJhdGNoLiBUaGUg
c2VydmVyIGRlZHVwbGljYXRlcyBtZXNzYWdlcyB3aXRoIHRoZSBzYW1lCiBzZXF1ZW5jZSBu
dW1iZXIgZnJvbSB0aGUgc2FtZSBwdWJsaXNoZXIgYGNsaWVudF9pZGAuCgoMCgUEAgIBBRID
WQIHCgwKBQQCAgEBEgNZCB0KDAoFBAICAQMSA1kgIQoyCgIEAxIEXQB5ARomIFJlc3BvbnNl
IHRvIGEgTWVzc2FnZVB1Ymxpc2hSZXF1ZXN0LgoKCgoDBAMBEgNdCB4KPQoEBAMDABIEXwJq
AxovIEN1cnNvcnMgZm9yIGEgc3VicmFuZ2Ugb2YgcHVibGlzaGVkIG1lc3NhZ2VzLgoKDAoF
BAMDAAESA18KFQqTAQoGBAMDAAIAEgNiBBwagwEgVGhlIGN1cnNvciBvZiB0aGUgbWVzc2Fn
ZSBhdCB0aGUgc3RhcnQgaW5kZXguIFRoZSBjdXJzb3JzIGZvciByZW1haW5pbmcKIG1lc3Nh
Z2VzIHVwIHRvIHRoZSBlbmQgaW5kZXggKGV4Y2x1c2l2ZSkgYXJlIHNlcXVlbnRpYWwuCgoO
CgcEAwMAAgAGEgNiBAoKDgoHBAMDAAIAARIDYgsXCg4KBwQDAwACAAMSA2IaGwpuCgYEAwMA
AgESA2YEGhpfIEluZGV4IG9mIHRoZSBtZXNzYWdlIGluIHRoZSBwdWJsaXNoZWQgYmF0Y2gg
dGhhdCBjb3JyZXNwb25kcyB0byB0aGUKIHN0YXJ0IGN1cnNvci4gSW5jbHVzaXZlLgoKDgoH
BAMDAAIBBRIDZgQJCg4KBwQDAwACAQESA2YKFQoOCgcEAwMAAgEDEgNmGBkKRAoGBAMDAAIC
EgNpBBgaNSBJbmRleCBvZiB0aGUgbGFzdCBtZXNzYWdlIGluIHRoaXMgcmFuZ2UuIEV4Y2x1
c2l2ZS4KCg4KBwQDAwACAgUSA2kECQoOCgcEAwMAAgIBEgNpChMKDgoHBAMDAAICAxIDaRYX
Cp0BCgQEAwIAEgNuAhoajwEgVGhlIGN1cnNvciBvZiB0aGUgZmlyc3QgcHVibGlzaGVkIG1l
c3NhZ2UgaW4gdGhlIGJhdGNoLiBUaGUgY3Vyc29ycyBmb3IgYW55CiByZW1haW5pbmcgbWVz
c2FnZXMgaW4gdGhlIGJhdGNoIGFyZSBndWFyYW50ZWVkIHRvIGJlIHNlcXVlbnRpYWwuCgoM
CgUEAwIABhIDbgIICgwKBQQDAgABEgNuCRUKDAoFBAMCAAMSA24YGQrtAwoEBAMCARIDeAIp
Gt8DIEN1cnNvcnMgZm9yIG1lc3NhZ2VzIHB1Ymxpc2hlZCBpbiB0aGUgYmF0Y2guIFRoZXJl
IHdpbGwgZXhpc3QgbXVsdGlwbGUKIHJhbmdlcyB3aGVuIGN1cnNvcnMgYXJlIG5vdCBjb250
aWd1b3VzIHdpdGhpbiB0aGUgYmF0Y2guCgogVGhlIGN1cnNvciByYW5nZXMgbWF5IG5vdCBh
Y2NvdW50IGZvciBhbGwgbWVzc2FnZXMgaW4gdGhlIGJhdGNoIHdoZW4KIHB1Ymxpc2ggaWRl
bXBvdGVuY3kgaXMgZW5hYmxlZC4gQSBtaXNzaW5nIHJhbmdlIGluZGljYXRlcyB0aGF0IGN1
cnNvcnMKIGNvdWxkIG5vdCBiZSBkZXRlcm1pbmVkIGZvciBtZXNzYWdlcyB3aXRoaW4gdGhl
IHJhbmdlLCBhcyB0aGV5IHdlcmUKIGRlZHVwbGljYXRlZCBhbmQgdGhlIG5lY2Vzc2FyeSBk
YXRhIHdhcyBub3QgYXZhaWxhYmxlIGF0IHB1Ymxpc2ggdGltZS4KIFRoZXNlIG1lc3NhZ2Vz
IHdpbGwgaGF2ZSBvZmZzZXRzIHdoZW4gcmVjZWl2ZWQgYnkgYSBzdWJzY3JpYmVyLgoKDAoF
BAMCAQQSA3gCCgoMCgUEAwIBBhIDeAsWCgwKBQQDAgEBEgN4FyQKDAoFBAMCAQMSA3gnKApG
CgIEBBIFfACFAQEaOSBSZXF1ZXN0IHNlbnQgZnJvbSB0aGUgY2xpZW50IHRvIHRoZSBzZXJ2
ZXIgb24gYSBzdHJlYW0uCgoKCgMEBAESA3wIFgotCgQEBAgAEgV+AoQBAxoeIFRoZSB0eXBl
IG9mIHJlcXVlc3QgdGhpcyBpcy4KCgwKBQQECAABEgN+CBQKLgoEBAQCABIEgAEELhogIElu
aXRpYWwgcmVxdWVzdCBvbiB0aGUgc3RyZWFtLgoKDQoFBAQCAAYSBIABBBkKDQoFBAQCAAES
BIABGikKDQoFBAQCAAMSBIABLC0KLAoEBAQCARIEgwEENhoeIFJlcXVlc3QgdG8gcHVibGlz
aCBtZXNzYWdlcy4KCg0KBQQEAgEGEgSDAQQZCg0KBQQEAgEBEgSDARoxCg0KBQQEAgEDEgSD
ATQ1Ci0KAgQFEgaIAQCRAQEaHyBSZXNwb25zZSB0byBhIFB1Ymxpc2hSZXF1ZXN0LgoKCwoD
BAUBEgSIAQgXCi8KBAQFCAASBooBApABAxofIFRoZSB0eXBlIG9mIHJlc3BvbnNlIHRoaXMg
aXMuCgoNCgUEBQgAARIEigEIFQovCgQEBQIAEgSMAQQwGiEgSW5pdGlhbCByZXNwb25zZSBv
biB0aGUgc3RyZWFtLgoKDQoFBAUCAAYSBIwBBBoKDQoFBAUCAAESBIwBGysKDQoFBAUCAAMS
BIwBLi8KMAoEBAUCARIEjwEEMBoiIFJlc3BvbnNlIHRvIHB1Ymxpc2hpbmcgbWVzc2FnZXMu
CgoNCgUEBQIBBhIEjwEEGgoNCgUEBQIBARIEjwEbKwoNCgUEBQIBAxIEjwEuL2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest ===
    # Fields for InitialPublishRequest
    # Field: topic Type: 9 ()
    # Field: partition Type: 3 ()
    # Field: client_id Type: 12 ()

# === Message: Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse ===
    # Fields for InitialPublishResponse

# === Message: Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest ===
    # Fields for MessagePublishRequest
    # Field: messages Type: 11 (.google.cloud.pubsublite.v1.PubSubMessage)
    # Field: first_sequence_number Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse ===
    # Fields for MessagePublishResponse
    # Field: start_cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)
    # Field: cursor_ranges Type: 11 (.google.cloud.pubsublite.v1.MessagePublishResponse.CursorRange)

# === Message: Google::Cloud::Pubsublite::V1::Publisher::PublishRequest ===
    # Fields for PublishRequest
    # Field: initial_request Type: 11 (.google.cloud.pubsublite.v1.InitialPublishRequest)
    # Field: message_publish_request Type: 11 (.google.cloud.pubsublite.v1.MessagePublishRequest)

# === Message: Google::Cloud::Pubsublite::V1::Publisher::PublishResponse ===
    # Fields for PublishResponse
    # Field: initial_response Type: 11 (.google.cloud.pubsublite.v1.InitialPublishResponse)
    # Field: message_response Type: 11 (.google.cloud.pubsublite.v1.MessagePublishResponse)

# === Service Client: Google::Cloud::Pubsublite::V1::Publisher::PublisherServiceClient ===
package Google::Cloud::Pubsublite::V1::Publisher::PublisherServiceClient;

=pod

=head2 Service Client: Google::Cloud::Pubsublite::V1::Publisher::PublisherServiceClient

Client stub representing the remote C<PublisherService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsublite.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsublite.googleapis.com:443' );

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

sub publish {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Publisher::PublishRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.PublisherService',
        method         => 'Publish',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Publisher::PublishResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Pubsublite::V1::Publisher - Compiled Protocol Buffers messages for google/cloud/pubsublite/v1/publisher.proto

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1::Publisher;

    my $msg = Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest->new({
        topic => $topic,
        partition => $partition,
        client_id => $client_id,
    });

    # Read or update a field
    my $val = $msg->topic();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/pubsublite/v1/publisher.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest

The first request that must be sent on a newly-opened stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The topic to which messages will be written.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

The partition within the topic to which messages will be written.
Partitions are zero indexed, so `partition` must be in the range [0,
topic.num_partitions).

=item * C<< $msg->client_id() >> / C<< $msg->client_id($value) >>

Type: C<Bytes>

Unique identifier for a publisher client. If set, enables publish
idempotency within a publisher client session.

The length of this field must be exactly 16 bytes long and should be
populated with a 128 bit uuid, generated by standard uuid algorithms like
uuid1 or uuid4. The same identifier should be reused following
disconnections with retryable stream errors.

=back

=head2 Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse

Response to an InitialPublishRequest.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest

Request to publish messages to the topic.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::PubSubMessage>)

The messages to publish.

=item * C<< $msg->first_sequence_number() >> / C<< $msg->first_sequence_number($value) >>

Type: C<Int64>

The sequence number corresponding to the first message in `messages`.
Messages within a batch are ordered and the sequence numbers of all
subsequent messages in the batch are assumed to be incremental.

Sequence numbers are assigned at the message level and the first message
published in a publisher client session must have a sequence number of 0.
All messages must have contiguous sequence numbers, which uniquely identify
the messages accepted by the publisher client. Since messages are ordered,
the client only needs to specify the sequence number of the first message
in a published batch. The server deduplicates messages with the same
sequence number from the same publisher `client_id`.

=back

=head2 Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse

Response to a MessagePublishRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_cursor() >> / C<< $msg->start_cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The cursor of the first published message in the batch. The cursors for any
remaining messages in the batch are guaranteed to be sequential.

=item * C<< $msg->cursor_ranges() >> / C<< $msg->cursor_ranges($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse::CursorRange>)

Cursors for messages published in the batch. There will exist multiple
ranges when cursors are not contiguous within the batch.

The cursor ranges may not account for all messages in the batch when
publish idempotency is enabled. A missing range indicates that cursors
could not be determined for messages within the range, as they were
deduplicated and the necessary data was not available at publish time.
These messages will have offsets when received by a subscriber.

=back

=head2 Google::Cloud::Pubsublite::V1::Publisher::PublishRequest

Request sent from the client to the server on a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_request() >> / C<< $msg->initial_request($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest>)

Initial request on the stream.

=item * C<< $msg->message_publish_request() >> / C<< $msg->message_publish_request($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest>)

Request to publish messages.

=back

=head2 Google::Cloud::Pubsublite::V1::Publisher::PublishResponse

Response to a PublishRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_response() >> / C<< $msg->initial_response($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse>)

Initial response on the stream.

=item * C<< $msg->message_response() >> / C<< $msg->message_response($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse>)

Response to publishing messages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Pubsublite::V1::Publisher::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
