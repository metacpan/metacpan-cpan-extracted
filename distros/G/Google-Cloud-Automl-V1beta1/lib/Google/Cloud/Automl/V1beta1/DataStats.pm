package Google::Cloud::Automl::V1beta1::DataStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGF0YV9zdGF0cy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExIoUFCglEYXRhU3RhdHMSUAoNZmxvYXQ2NF9zdGF0cxgD
IAEoCzIpLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5GbG9hdDY0U3RhdHNIAFIMZmxv
YXQ2NFN0YXRzEk0KDHN0cmluZ19zdGF0cxgEIAEoCzIoLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMS5TdHJpbmdTdGF0c0gAUgtzdHJpbmdTdGF0cxJWCg90aW1lc3RhbXBfc3RhdHMY
BSABKAsyKy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGltZXN0YW1wU3RhdHNIAFIO
dGltZXN0YW1wU3RhdHMSSgoLYXJyYXlfc3RhdHMYBiABKAsyJy5nb29nbGUuY2xvdWQuYXV0
b21sLnYxYmV0YTEuQXJyYXlTdGF0c0gAUgphcnJheVN0YXRzEk0KDHN0cnVjdF9zdGF0cxgH
IAEoCzIoLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5TdHJ1Y3RTdGF0c0gAUgtzdHJ1
Y3RTdGF0cxJTCg5jYXRlZ29yeV9zdGF0cxgIIAEoCzIqLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMS5DYXRlZ29yeVN0YXRzSABSDWNhdGVnb3J5U3RhdHMSMAoUZGlzdGluY3RfdmFs
dWVfY291bnQYASABKANSEmRpc3RpbmN0VmFsdWVDb3VudBIoChBudWxsX3ZhbHVlX2NvdW50
GAIgASgDUg5udWxsVmFsdWVDb3VudBIqChF2YWxpZF92YWx1ZV9jb3VudBgJIAEoA1IPdmFs
aWRWYWx1ZUNvdW50QgcKBXN0YXRzIqQCCgxGbG9hdDY0U3RhdHMSEgoEbWVhbhgBIAEoAVIE
bWVhbhItChJzdGFuZGFyZF9kZXZpYXRpb24YAiABKAFSEXN0YW5kYXJkRGV2aWF0aW9uEhwK
CXF1YW50aWxlcxgDIAMoAVIJcXVhbnRpbGVzEmYKEWhpc3RvZ3JhbV9idWNrZXRzGAQgAygL
MjkuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkZsb2F0NjRTdGF0cy5IaXN0b2dyYW1C
dWNrZXRSEGhpc3RvZ3JhbUJ1Y2tldHMaSwoPSGlzdG9ncmFtQnVja2V0EhAKA21pbhgBIAEo
AVIDbWluEhAKA21heBgCIAEoAVIDbWF4EhQKBWNvdW50GAMgASgDUgVjb3VudCKsAQoLU3Ry
aW5nU3RhdHMSYQoRdG9wX3VuaWdyYW1fc3RhdHMYASADKAsyNS5nb29nbGUuY2xvdWQuYXV0
b21sLnYxYmV0YTEuU3RyaW5nU3RhdHMuVW5pZ3JhbVN0YXRzUg90b3BVbmlncmFtU3RhdHMa
OgoMVW5pZ3JhbVN0YXRzEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIUCgVjb3VudBgCIAEoA1IF
Y291bnQipAMKDlRpbWVzdGFtcFN0YXRzEmUKDmdyYW51bGFyX3N0YXRzGAEgAygLMj4uZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRpbWVzdGFtcFN0YXRzLkdyYW51bGFyU3RhdHNF
bnRyeVINZ3JhbnVsYXJTdGF0cxqtAQoNR3JhbnVsYXJTdGF0cxJgCgdidWNrZXRzGAEgAygL
MkYuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRpbWVzdGFtcFN0YXRzLkdyYW51bGFy
U3RhdHMuQnVja2V0c0VudHJ5UgdidWNrZXRzGjoKDEJ1Y2tldHNFbnRyeRIQCgNrZXkYASAB
KAVSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgBGnsKEkdyYW51bGFyU3RhdHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRJPCgV2YWx1ZRgCIAEoCzI5Lmdvb2dsZS5jbG91ZC5hdXRv
bWwudjFiZXRhMS5UaW1lc3RhbXBTdGF0cy5HcmFudWxhclN0YXRzUgV2YWx1ZToCOAEiVwoK
QXJyYXlTdGF0cxJJCgxtZW1iZXJfc3RhdHMYAiABKAsyJi5nb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuRGF0YVN0YXRzUgttZW1iZXJTdGF0cyLPAQoLU3RydWN0U3RhdHMSWQoLZmll
bGRfc3RhdHMYASADKAsyOC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuU3RydWN0U3Rh
dHMuRmllbGRTdGF0c0VudHJ5UgpmaWVsZFN0YXRzGmUKD0ZpZWxkU3RhdHNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRI8CgV2YWx1ZRgCIAEoCzImLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFi
ZXRhMS5EYXRhU3RhdHNSBXZhbHVlOgI4ASLAAQoNQ2F0ZWdvcnlTdGF0cxJsChJ0b3BfY2F0
ZWdvcnlfc3RhdHMYASADKAsyPi5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQ2F0ZWdv
cnlTdGF0cy5TaW5nbGVDYXRlZ29yeVN0YXRzUhB0b3BDYXRlZ29yeVN0YXRzGkEKE1Npbmds
ZUNhdGVnb3J5U3RhdHMSFAoFdmFsdWUYASABKAlSBXZhbHVlEhQKBWNvdW50GAIgASgDUgVj
b3VudCIvChBDb3JyZWxhdGlvblN0YXRzEhsKCWNyYW1lcnNfdhgBIAEoAVIIY3JhbWVyc1ZC
mwEKH2NvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTFQAVo3Y2xvdWQuZ29vZ2xlLmNv
bS9nby9hdXRvbWwvYXBpdjFiZXRhMS9hdXRvbWxwYjthdXRvbWxwYsoCG0dvb2dsZVxDbG91
ZFxBdXRvTWxcVjFiZXRhMeoCHkdvb2dsZTo6Q2xvdWQ6OkF1dG9NTDo6VjFiZXRhMUq9LQoH
EgUOAKQBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoI
CgEIEgMTAE4KCQoCCAsSAxMATgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADgKCQoC
CAESAxUAOAoICgEIEgMWADgKCQoCCCkSAxYAOAoICgEIEgMXADcKCQoCCC0SAxcANwpVCgIE
ABIEGgA4ARpJIFRoZSBkYXRhIHN0YXRpc3RpY3Mgb2YgYSBzZXJpZXMgb2YgdmFsdWVzIHRo
YXQgc2hhcmUgdGhlIHNhbWUgRGF0YVR5cGUuCgoKCgMEAAESAxoIEQo7CgQEAAgAEgQcAi4D
Gi0gVGhlIGRhdGEgc3RhdGlzdGljcyBzcGVjaWZpYyB0byBhIERhdGFUeXBlLgoKDAoFBAAI
AAESAxwIDQozCgQEAAIAEgMeBCMaJiBUaGUgc3RhdGlzdGljcyBmb3IgRkxPQVQ2NCBEYXRh
VHlwZS4KCgwKBQQAAgAGEgMeBBAKDAoFBAACAAESAx4RHgoMCgUEAAIAAxIDHiEiCjIKBAQA
AgESAyEEIRolIFRoZSBzdGF0aXN0aWNzIGZvciBTVFJJTkcgRGF0YVR5cGUuCgoMCgUEAAIB
BhIDIQQPCgwKBQQAAgEBEgMhEBwKDAoFBAACAQMSAyEfIAo1CgQEAAICEgMkBCcaKCBUaGUg
c3RhdGlzdGljcyBmb3IgVElNRVNUQU1QIERhdGFUeXBlLgoKDAoFBAACAgYSAyQEEgoMCgUE
AAICARIDJBMiCgwKBQQAAgIDEgMkJSYKMQoEBAACAxIDJwQfGiQgVGhlIHN0YXRpc3RpY3Mg
Zm9yIEFSUkFZIERhdGFUeXBlLgoKDAoFBAACAwYSAycEDgoMCgUEAAIDARIDJw8aCgwKBQQA
AgMDEgMnHR4KMgoEBAACBBIDKgQhGiUgVGhlIHN0YXRpc3RpY3MgZm9yIFNUUlVDVCBEYXRh
VHlwZS4KCgwKBQQAAgQGEgMqBA8KDAoFBAACBAESAyoQHAoMCgUEAAIEAxIDKh8gCjQKBAQA
AgUSAy0EJRonIFRoZSBzdGF0aXN0aWNzIGZvciBDQVRFR09SWSBEYXRhVHlwZS4KCgwKBQQA
AgUGEgMtBBEKDAoFBAACBQESAy0SIAoMCgUEAAIFAxIDLSMkCi0KBAQAAgYSAzECIRogIFRo
ZSBudW1iZXIgb2YgZGlzdGluY3QgdmFsdWVzLgoKDAoFBAACBgUSAzECBwoMCgUEAAIGARID
MQgcCgwKBQQAAgYDEgMxHyAKMgoEBAACBxIDNAIdGiUgVGhlIG51bWJlciBvZiB2YWx1ZXMg
dGhhdCBhcmUgbnVsbC4KCgwKBQQAAgcFEgM0AgcKDAoFBAACBwESAzQIGAoMCgUEAAIHAxID
NBscCjMKBAQAAggSAzcCHhomIFRoZSBudW1iZXIgb2YgdmFsdWVzIHRoYXQgYXJlIHZhbGlk
LgoKDAoFBAACCAUSAzcCBwoMCgUEAAIIARIDNwgZCgwKBQQAAggDEgM3HB0KQAoCBAESBDsA
XAEaNCBUaGUgZGF0YSBzdGF0aXN0aWNzIG9mIGEgc2VyaWVzIG9mIEZMT0FUNjQgdmFsdWVz
LgoKCgoDBAEBEgM7CBQKKAoEBAEDABIEPQJIAxoaIEEgYnVja2V0IG9mIGEgaGlzdG9ncmFt
LgoKDAoFBAEDAAESAz0KGQo8CgYEAQMAAgASAz8EExotIFRoZSBtaW5pbXVtIHZhbHVlIG9m
IHRoZSBidWNrZXQsIGluY2x1c2l2ZS4KCg4KBwQBAwACAAUSAz8ECgoOCgcEAQMAAgABEgM/
Cw4KDgoHBAEDAAIAAxIDPxESCnUKBgQBAwACARIDQwQTGmYgVGhlIG1heGltdW0gdmFsdWUg
b2YgdGhlIGJ1Y2tldCwgZXhjbHVzaXZlIHVubGVzcyBtYXggPSBgIkluZmluaXR5ImAsIGlu
CiB3aGljaCBjYXNlIGl0J3MgaW5jbHVzaXZlLgoKDgoHBAEDAAIBBRIDQwQKCg4KBwQBAwAC
AQESA0MLDgoOCgcEAQMAAgEDEgNDERIKaAoGBAEDAAICEgNHBBQaWSBUaGUgbnVtYmVyIG9m
IGRhdGEgdmFsdWVzIHRoYXQgYXJlIGluIHRoZSBidWNrZXQsIGkuZS4gYXJlIGJldHdlZW4K
IG1pbiBhbmQgbWF4IHZhbHVlcy4KCg4KBwQBAwACAgUSA0cECQoOCgcEAQMAAgIBEgNHCg8K
DgoHBAEDAAICAxIDRxITCiYKBAQBAgASA0sCEhoZIFRoZSBtZWFuIG9mIHRoZSBzZXJpZXMu
CgoMCgUEAQIABRIDSwIICgwKBQQBAgABEgNLCQ0KDAoFBAECAAMSA0sQEQo0CgQEAQIBEgNO
AiAaJyBUaGUgc3RhbmRhcmQgZGV2aWF0aW9uIG9mIHRoZSBzZXJpZXMuCgoMCgUEAQIBBRID
TgIICgwKBQQBAgEBEgNOCRsKDAoFBAECAQMSA04eHwrwAQoEBAECAhIDVAIgGuIBIE9yZGVy
ZWQgZnJvbSAwIHRvIGsgay1xdWFudGlsZSB2YWx1ZXMgb2YgdGhlIGRhdGEgc2VyaWVzIG9m
IG4gdmFsdWVzLgogVGhlIHZhbHVlIGF0IGluZGV4IGkgaXMsIGFwcHJveGltYXRlbHksIHRo
ZSBpKm4vay10aCBzbWFsbGVzdCB2YWx1ZSBpbiB0aGUKIHNlcmllczsgZm9yIGkgPSAwIGFu
ZCBpID0gayB0aGVzZSBhcmUsIHJlc3BlY3RpdmVseSwgdGhlIG1pbiBhbmQgbWF4CiB2YWx1
ZXMuCgoMCgUEAQICBBIDVAIKCgwKBQQBAgIFEgNUCxEKDAoFBAECAgESA1QSGwoMCgUEAQIC
AxIDVB4fCsgCCgQEAQIDEgNbAjEaugIgSGlzdG9ncmFtIGJ1Y2tldHMgb2YgdGhlIGRhdGEg
c2VyaWVzLiBTb3J0ZWQgYnkgdGhlIG1pbiB2YWx1ZSBvZiB0aGUKIGJ1Y2tldCwgYXNjZW5k
aW5nbHksIGFuZCB0aGUgbnVtYmVyIG9mIHRoZSBidWNrZXRzIGlzIGR5bmFtaWNhbGx5CiBn
ZW5lcmF0ZWQuIFRoZSBidWNrZXRzIGFyZSBub24tb3ZlcmxhcHBpbmcgYW5kIGNvbXBsZXRl
bHkgY292ZXIgd2hvbGUKIEZMT0FUNjQgcmFuZ2Ugd2l0aCBtaW4gb2YgZmlyc3QgYnVja2V0
IGJlaW5nIGAiLUluZmluaXR5ImAsIGFuZCBtYXggb2YKIHRoZSBsYXN0IG9uZSBiZWluZyBg
IkluZmluaXR5ImAuCgoMCgUEAQIDBBIDWwIKCgwKBQQBAgMGEgNbCxoKDAoFBAECAwESA1sb
LAoMCgUEAQIDAxIDWy8wCj8KAgQCEgRfAGwBGjMgVGhlIGRhdGEgc3RhdGlzdGljcyBvZiBh
IHNlcmllcyBvZiBTVFJJTkcgdmFsdWVzLgoKCgoDBAIBEgNfCBMKLAoEBAIDABIEYQJnAxoe
IFRoZSBzdGF0aXN0aWNzIG9mIGEgdW5pZ3JhbS4KCgwKBQQCAwABEgNhChYKHQoGBAIDAAIA
EgNjBBUaDiBUaGUgdW5pZ3JhbS4KCg4KBwQCAwACAAUSA2MECgoOCgcEAgMAAgABEgNjCxAK
DgoHBAIDAAIAAxIDYxMUCkkKBgQCAwACARIDZgQUGjogVGhlIG51bWJlciBvZiBvY2N1cnJl
bmNlcyBvZiB0aGlzIHVuaWdyYW0gaW4gdGhlIHNlcmllcy4KCg4KBwQCAwACAQUSA2YECQoO
CgcEAgMAAgEBEgNmCg8KDgoHBAIDAAIBAxIDZhITCoYBCgQEAgIAEgNrAi4aeSBUaGUgc3Rh
dGlzdGljcyBvZiB0aGUgdG9wIDIwIHVuaWdyYW1zLCBvcmRlcmVkIGJ5CiBbY291bnRdW2dv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5TdHJpbmdTdGF0cy5VbmlncmFtU3RhdHMuY291
bnRdLgoKDAoFBAICAAQSA2sCCgoMCgUEAgIABhIDawsXCgwKBQQCAgABEgNrGCkKDAoFBAIC
AAMSA2ssLQpCCgIEAxIEbwB9ARo2IFRoZSBkYXRhIHN0YXRpc3RpY3Mgb2YgYSBzZXJpZXMg
b2YgVElNRVNUQU1QIHZhbHVlcy4KCgoKAwQDARIDbwgWCkAKBAQDAwASBHECdQMaMiBTdGF0
cyBzcGxpdCBieSBhIGRlZmluZWQgaW4gY29udGV4dCBncmFudWxhcml0eS4KCgwKBQQDAwAB
EgNxChcKlgEKBgQDAwACABIDdAQiGoYBIEEgbWFwIGZyb20gZ3JhbnVsYXJpdHkga2V5IHRv
IGV4YW1wbGUgY291bnQgZm9yIHRoYXQga2V5LgogRS5nLiBmb3IgaG91cl9vZl9kYXkgYDEz
YCBtZWFucyAxcG0sIG9yIGZvciBtb250aF9vZl95ZWFyIGA1YCBtZWFucyBNYXkpLgoKDgoH
BAMDAAIABhIDdAQVCg4KBwQDAwACAAESA3QWHQoOCgcEAwMAAgADEgN0ICEKnQIKBAQDAgAS
A3wCMBqPAiBUaGUgc3RyaW5nIGtleSBpcyB0aGUgcHJlLWRlZmluZWQgZ3JhbnVsYXJpdHku
IEN1cnJlbnRseSBzdXBwb3J0ZWQ6CiBob3VyX29mX2RheSwgZGF5X29mX3dlZWssIG1vbnRo
X29mX3llYXIuCiBHcmFudWxhcml0aWVzIGZpbmVyIHRoYXQgdGhlIGdyYW51bGFyaXR5IG9m
IHRpbWVzdGFtcCBkYXRhIGFyZSBub3QKIHBvcHVsYXRlZCAoZS5nLiBpZiB0aW1lc3RhbXBz
IGFyZSBhdCBkYXkgZ3JhbnVsYXJpdHksIHRoZW4gaG91cl9vZl9kYXkKIGlzIG5vdCBwb3B1
bGF0ZWQpLgoKDAoFBAMCAAYSA3wCHAoMCgUEAwIAARIDfB0rCgwKBQQDAgADEgN8Li8KQAoC
BAQSBoABAIQBARoyIFRoZSBkYXRhIHN0YXRpc3RpY3Mgb2YgYSBzZXJpZXMgb2YgQVJSQVkg
dmFsdWVzLgoKCwoDBAQBEgSAAQgSCpkBCgQEBAIAEgSDAQIdGooBIFN0YXRzIG9mIGFsbCB0
aGUgdmFsdWVzIG9mIGFsbCBhcnJheXMsIGFzIGlmIHRoZXkgd2VyZSBhIHNpbmdsZSBsb25n
CiBzZXJpZXMgb2YgZGF0YS4gVGhlIHR5cGUgZGVwZW5kcyBvbiB0aGUgZWxlbWVudCB0eXBl
IG9mIHRoZSBhcnJheS4KCg0KBQQEAgAGEgSDAQILCg0KBQQEAgABEgSDAQwYCg0KBQQEAgAD
EgSDARscCkEKAgQFEgaHAQCLAQEaMyBUaGUgZGF0YSBzdGF0aXN0aWNzIG9mIGEgc2VyaWVz
IG9mIFNUUlVDVCB2YWx1ZXMuCgoLCgMEBQESBIcBCBMKiwEKBAQFAgASBIoBAikafSBNYXAg
ZnJvbSBhIGZpZWxkIG5hbWUgb2YgdGhlIHN0cnVjdCB0byBkYXRhIHN0YXRzIGFnZ3JlZ2F0
ZWQgb3ZlciBzZXJpZXMKIG9mIGFsbCBkYXRhIGluIHRoYXQgZmllbGQgYWNyb3NzIGFsbCB0
aGUgc3RydWN0cy4KCg0KBQQFAgAGEgSKAQIYCg0KBQQFAgABEgSKARkkCg0KBQQFAgADEgSK
AScoCkMKAgQGEgaOAQCcAQEaNSBUaGUgZGF0YSBzdGF0aXN0aWNzIG9mIGEgc2VyaWVzIG9m
IENBVEVHT1JZIHZhbHVlcy4KCgsKAwQGARIEjgEIFQo8CgQEBgMAEgaQAQKWAQMaLCBUaGUg
c3RhdGlzdGljcyBvZiBhIHNpbmdsZSBDQVRFR09SWSB2YWx1ZS4KCg0KBQQGAwABEgSQAQod
CiUKBgQGAwACABIEkgEEFRoVIFRoZSBDQVRFR09SWSB2YWx1ZS4KCg8KBwQGAwACAAUSBJIB
BAoKDwoHBAYDAAIAARIEkgELEAoPCgcEBgMAAgADEgSSARMUCkgKBgQGAwACARIElQEEFBo4
IFRoZSBudW1iZXIgb2Ygb2NjdXJyZW5jZXMgb2YgdGhpcyB2YWx1ZSBpbiB0aGUgc2VyaWVz
LgoKDwoHBAYDAAIBBRIElQEECQoPCgcEBgMAAgEBEgSVAQoPCg8KBwQGAwACAQMSBJUBEhMK
mQEKBAQGAgASBJsBAjYaigEgVGhlIHN0YXRpc3RpY3Mgb2YgdGhlIHRvcCAyMCBDQVRFR09S
WSB2YWx1ZXMsIG9yZGVyZWQgYnkKCiBbY291bnRdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFi
ZXRhMS5DYXRlZ29yeVN0YXRzLlNpbmdsZUNhdGVnb3J5U3RhdHMuY291bnRdLgoKDQoFBAYC
AAQSBJsBAgoKDQoFBAYCAAYSBJsBCx4KDQoFBAYCAAESBJsBHzEKDQoFBAYCAAMSBJsBNDUK
tgEKAgQHEgahAQCkAQEapwEgQSBjb3JyZWxhdGlvbiBzdGF0aXN0aWNzIGJldHdlZW4gdHdv
IHNlcmllcyBvZiBEYXRhVHlwZSB2YWx1ZXMuIFRoZSBzZXJpZXMKIG1heSBoYXZlIGRpZmZl
cmluZyBEYXRhVHlwZS1zLCBidXQgd2l0aGluIGEgc2luZ2xlIHNlcmllcyB0aGUgRGF0YVR5
cGUgbXVzdAogYmUgdGhlIHNhbWUuCgoLCgMEBwESBKEBCBgKQwoEBAcCABIEowECFxo1IFRo
ZSBjb3JyZWxhdGlvbiB2YWx1ZSB1c2luZyB0aGUgQ3JhbWVyJ3MgViBtZWFzdXJlLgoKDQoF
BAcCAAUSBKMBAggKDQoFBAcCAAESBKMBCRIKDQoFBAcCAAMSBKMBFRZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::DataStats::DataStats ===
    # Fields for DataStats
    # Field: float64_stats Type: 11 (.google.cloud.automl.v1beta1.Float64Stats)
    # Field: string_stats Type: 11 (.google.cloud.automl.v1beta1.StringStats)
    # Field: timestamp_stats Type: 11 (.google.cloud.automl.v1beta1.TimestampStats)
    # Field: array_stats Type: 11 (.google.cloud.automl.v1beta1.ArrayStats)
    # Field: struct_stats Type: 11 (.google.cloud.automl.v1beta1.StructStats)
    # Field: category_stats Type: 11 (.google.cloud.automl.v1beta1.CategoryStats)
    # Field: distinct_value_count Type: 3 ()
    # Field: null_value_count Type: 3 ()
    # Field: valid_value_count Type: 3 ()

# === Message: Google::Cloud::Automl::V1beta1::DataStats::Float64Stats ===
    # Fields for Float64Stats
    # Field: mean Type: 1 ()
    # Field: standard_deviation Type: 1 ()
    # Field: quantiles Type: 1 ()
    # Field: histogram_buckets Type: 11 (.google.cloud.automl.v1beta1.Float64Stats.HistogramBucket)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::StringStats ===
    # Fields for StringStats
    # Field: top_unigram_stats Type: 11 (.google.cloud.automl.v1beta1.StringStats.UnigramStats)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::TimestampStats ===
    # Fields for TimestampStats
    # Field: granular_stats Type: 11 (.google.cloud.automl.v1beta1.TimestampStats.GranularStatsEntry)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::ArrayStats ===
    # Fields for ArrayStats
    # Field: member_stats Type: 11 (.google.cloud.automl.v1beta1.DataStats)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::StructStats ===
    # Fields for StructStats
    # Field: field_stats Type: 11 (.google.cloud.automl.v1beta1.StructStats.FieldStatsEntry)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::CategoryStats ===
    # Fields for CategoryStats
    # Field: top_category_stats Type: 11 (.google.cloud.automl.v1beta1.CategoryStats.SingleCategoryStats)

# === Message: Google::Cloud::Automl::V1beta1::DataStats::CorrelationStats ===
    # Fields for CorrelationStats
    # Field: cramers_v Type: 1 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::DataStats - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/data_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::DataStats;

    my $msg = Google::Cloud::Automl::V1beta1::DataStats::DataStats->new({
        float64_stats => $float64_stats,
        string_stats => $string_stats,
        timestamp_stats => $timestamp_stats,
        array_stats => $array_stats,
    });

    # Read or update a field
    my $val = $msg->float64_stats();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::DataStats::DataStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/data_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::DataStats::DataStats

The data statistics of a series of values that share the same DataType.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->float64_stats() >> / C<< $msg->float64_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::Float64Stats>)

The statistics for FLOAT64 DataType.

=item * C<< $msg->string_stats() >> / C<< $msg->string_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::StringStats>)

The statistics for STRING DataType.

=item * C<< $msg->timestamp_stats() >> / C<< $msg->timestamp_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::TimestampStats>)

The statistics for TIMESTAMP DataType.

=item * C<< $msg->array_stats() >> / C<< $msg->array_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::ArrayStats>)

The statistics for ARRAY DataType.

=item * C<< $msg->struct_stats() >> / C<< $msg->struct_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::StructStats>)

The statistics for STRUCT DataType.

=item * C<< $msg->category_stats() >> / C<< $msg->category_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::CategoryStats>)

The statistics for CATEGORY DataType.

=item * C<< $msg->distinct_value_count() >> / C<< $msg->distinct_value_count($value) >>

Type: C<Int64>

The number of distinct values.

=item * C<< $msg->null_value_count() >> / C<< $msg->null_value_count($value) >>

Type: C<Int64>

The number of values that are null.

=item * C<< $msg->valid_value_count() >> / C<< $msg->valid_value_count($value) >>

Type: C<Int64>

The number of values that are valid.

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::Float64Stats

The data statistics of a series of FLOAT64 values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mean() >> / C<< $msg->mean($value) >>

Type: C<Double>

The mean of the series.

=item * C<< $msg->standard_deviation() >> / C<< $msg->standard_deviation($value) >>

Type: C<Double>

The standard deviation of the series.

=item * C<< $msg->quantiles() >> / C<< $msg->quantiles($value) >>

Type: C<Double>

Ordered from 0 to k k-quantile values of the data series of n values.
The value at index i is, approximately, the i*n/k-th smallest value in the
series; for i = 0 and i = k these are, respectively, the min and max
values.

=item * C<< $msg->histogram_buckets() >> / C<< $msg->histogram_buckets($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::Float64Stats::HistogramBucket>)

Histogram buckets of the data series. Sorted by the min value of the
bucket, ascendingly, and the number of the buckets is dynamically
generated. The buckets are non-overlapping and completely cover whole
FLOAT64 range with min of first bucket being `"-Infinity"`, and max of
the last one being `"Infinity"`.

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::StringStats

The data statistics of a series of STRING values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->top_unigram_stats() >> / C<< $msg->top_unigram_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::StringStats::UnigramStats>)

The statistics of the top 20 unigrams, ordered by
[count][google.cloud.automl.v1beta1.StringStats.UnigramStats.count].

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::TimestampStats

The data statistics of a series of TIMESTAMP values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->granular_stats() >> / C<< $msg->granular_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStatsEntry>)

The string key is the pre-defined granularity. Currently supported:
hour_of_day, day_of_week, month_of_year.
Granularities finer that the granularity of timestamp data are not
populated (e.g. if timestamps are at day granularity, then hour_of_day
is not populated).

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::ArrayStats

The data statistics of a series of ARRAY values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->member_stats() >> / C<< $msg->member_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::DataStats>)

Stats of all the values of all arrays, as if they were a single long
series of data. The type depends on the element type of the array.

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::StructStats

The data statistics of a series of STRUCT values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_stats() >> / C<< $msg->field_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::StructStats::FieldStatsEntry>)

Map from a field name of the struct to data stats aggregated over series
of all data in that field across all the structs.

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::CategoryStats

The data statistics of a series of CATEGORY values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->top_category_stats() >> / C<< $msg->top_category_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::CategoryStats::SingleCategoryStats>)

The statistics of the top 20 CATEGORY values, ordered by

[count][google.cloud.automl.v1beta1.CategoryStats.SingleCategoryStats.count].

=back

=head2 Google::Cloud::Automl::V1beta1::DataStats::CorrelationStats

A correlation statistics between two series of DataType values. The series
may have differing DataType-s, but within a single series the DataType must
be the same.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cramers_v() >> / C<< $msg->cramers_v($value) >>

Type: C<Double>

The correlation value using the Cramer's V measure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::DataStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
