package Google::Actions::Sdk::V2::Interactionmodel::Slot;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::EventHandler };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9zbG90LnByb3RvEiZn
b29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbBo6Z29vZ2xlL2FjdGlvbnMv
c2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvZXZlbnRfaGFuZGxlci5wcm90bxpBZ29vZ2xlL2Fj
dGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlwZS9jbGFzc19yZWZlcmVuY2UucHJv
dG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9z
dHJ1Y3QucHJvdG8i/QoKBFNsb3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lElQKBHR5cGUY
AiABKAsyOy5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50eXBlLkNs
YXNzUmVmZXJlbmNlQgPgQQJSBHR5cGUSHwoIcmVxdWlyZWQYAyABKAhCA+BBAVIIcmVxdWly
ZWQSaQoPcHJvbXB0X3NldHRpbmdzGAQgASgLMjsuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwuU2xvdC5Qcm9tcHRTZXR0aW5nc0ID4EEBUg5wcm9tcHRTZXR0aW5n
cxJpCg9jb21taXRfYmVoYXZpb3IYBSABKAsyOy5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50
ZXJhY3Rpb25tb2RlbC5TbG90LkNvbW1pdEJlaGF2aW9yQgPgQQFSDmNvbW1pdEJlaGF2aW9y
EjMKBmNvbmZpZxgGIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZUID4EEBUgZjb25maWcS
YwoNZGVmYXVsdF92YWx1ZRgHIAEoCzI5Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFj
dGlvbm1vZGVsLlNsb3QuRGVmYXVsdFZhbHVlQgPgQQFSDGRlZmF1bHRWYWx1ZRq/BQoOUHJv
bXB0U2V0dGluZ3MSWwoOaW5pdGlhbF9wcm9tcHQYASABKAsyNC5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5FdmVudEhhbmRsZXJSDWluaXRpYWxQcm9tcHQSXgoQ
bm9fbWF0Y2hfcHJvbXB0MRgCIAEoCzI0Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFj
dGlvbm1vZGVsLkV2ZW50SGFuZGxlclIObm9NYXRjaFByb21wdDESXgoQbm9fbWF0Y2hfcHJv
bXB0MhgDIAEoCzI0Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLkV2
ZW50SGFuZGxlclIObm9NYXRjaFByb21wdDISZwoVbm9fbWF0Y2hfZmluYWxfcHJvbXB0GAQg
ASgLMjQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwuRXZlbnRIYW5k
bGVyUhJub01hdGNoRmluYWxQcm9tcHQSXgoQbm9faW5wdXRfcHJvbXB0MRgFIAEoCzI0Lmdv
b2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLkV2ZW50SGFuZGxlclIObm9J
bnB1dFByb21wdDESXgoQbm9faW5wdXRfcHJvbXB0MhgGIAEoCzI0Lmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLkV2ZW50SGFuZGxlclIObm9JbnB1dFByb21wdDIS
ZwoVbm9faW5wdXRfZmluYWxfcHJvbXB0GAcgASgLMjQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
LmludGVyYWN0aW9ubW9kZWwuRXZlbnRIYW5kbGVyUhJub0lucHV0RmluYWxQcm9tcHQaQAoO
Q29tbWl0QmVoYXZpb3ISLgoTd3JpdGVfc2Vzc2lvbl9wYXJhbRgBIAEoCVIRd3JpdGVTZXNz
aW9uUGFyYW0acQoMRGVmYXVsdFZhbHVlEigKDXNlc3Npb25fcGFyYW0YASABKAlCA+BBAVIM
c2Vzc2lvblBhcmFtEjcKCGNvbnN0YW50GAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVl
QgPgQQFSCGNvbnN0YW50QpEBCipjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0
aW9ubW9kZWxCCVNsb3RQcm90b1ABWlZnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29n
bGVhcGlzL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWw7aW50ZXJhY3Rpb25tb2Rl
bErfKwoHEgUOAIQBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAALwoJCgIDABIDEgBECgkKAgMBEgMTAEsKCQoCAwISAxQAKQoJCgIDAxIDFQAmCggKAQgS
AxcAbQoJCgIICxIDFwBtCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAKgoJCgIICBID
GQAqCggKAQgSAxoAQwoJCgIIARIDGgBDCrYBCgIEABIFHwCEAQEaqAEgQ29uZmlndXJhdGlv
biBmb3IgYSBzbG90LiBTbG90cyBhcmUgc2luZ2xlIHVuaXRzIG9mIGRhdGEgdGhhdCBjYW4g
YmUgZmlsbGVkCiB0aHJvdWdoIG5hdHVyYWwgbGFuZ3VhZ2UgKGllLiBpbnRlbnQgcGFyYW1l
dGVycyksIHNlc3Npb24gcGFyYW1ldGVycywgYW5kCiBvdGhlciBzb3VyY2VzLgoKCgoDBAAB
EgMfCAwKPgoEBAADABIEIQI/AxowIEEgc2luZ2xlIHBsYWNlIHdoZXJlIHNsb3QgcHJvbXB0
cyBhcmUgZGVmaW5lZC4KCgwKBQQAAwABEgMhChgKVQoGBAADAAIAEgMjBCQaRiBQcm9tcHQg
Zm9yIHRoZSBzbG90IHZhbHVlIGl0c2VsZi4gRXhhbXBsZTogIldoYXQgc2l6ZSBkaWQgeW91
IHdhbnQ/IgoKDgoHBAADAAIABhIDIwQQCg4KBwQAAwACAAESAyMRHwoOCgcEAAMAAgADEgMj
IiMKpQEKBgQAAwACARIDKAQmGpUBIFByb21wdCB0byBnaXZlIHdoZW4gdGhlIHVzZXIncyBp
bnB1dCBkb2VzIG5vdCBtYXRjaCB0aGUgZXhwZWN0ZWQKIHZhbHVlIHR5cGUgZm9yIHRoZSBz
bG90IGZvciB0aGUgZmlyc3QgdGltZS4gRXhhbXBsZTogIlNvcnJ5LCBJCiBkaWRuJ3QgZ2V0
IHRoYXQuIgoKDgoHBAADAAIBBhIDKAQQCg4KBwQAAwACAQESAygRIQoOCgcEAAMAAgEDEgMo
JCUKpgEKBgQAAwACAhIDLQQmGpYBIFByb21wdCB0byBnaXZlIHdoZW4gdGhlIHVzZXIncyBp
bnB1dCBkb2VzIG5vdCBtYXRjaCB0aGUgZXhwZWN0ZWQKIHZhbHVlIHR5cGUgZm9yIHRoZSBz
bG90IGZvciB0aGUgc2Vjb25kIHRpbWUuIEV4YW1wbGU6ICJTb3JyeSwgSQogZGlkbid0IGdl
dCB0aGF0LiIKCg4KBwQAAwACAgYSAy0EEAoOCgcEAAMAAgIBEgMtESEKDgoHBAADAAICAxID
LSQlCqQBCgYEAAMAAgMSAzIEKxqUASBQcm9tcHQgdG8gZ2l2ZSB3aGVuIHRoZSB1c2VyJ3Mg
aW5wdXQgZG9lcyBub3QgbWF0Y2ggdGhlIGV4cGVjdGVkCiB2YWx1ZSB0eXBlIGZvciB0aGUg
c2xvdCBmb3IgdGhlIGxhc3QgdGltZS4gRXhhbXBsZTogIlNvcnJ5LCBJCiBkaWRuJ3QgZ2V0
IHRoYXQuIgoKDgoHBAADAAIDBhIDMgQQCg4KBwQAAwACAwESAzIRJgoOCgcEAAMAAgMDEgMy
KSoKgQEKBgQAAwACBBIDNgQmGnIgUHJvbXB0IHRvIGdpdmUgd2hlbiB0aGUgdXNlciBkb2Vz
IG5vdCBwcm92aWRlIGFuIGlucHV0IGZvciB0aGUgZmlyc3QKIHRpbWUuIEV4YW1wbGU6ICJT
b3JyeSwgSSBkaWRuJ3QgZ2V0IHRoYXQuIgoKDgoHBAADAAIEBhIDNgQQCg4KBwQAAwACBAES
AzYRIQoOCgcEAAMAAgQDEgM2JCUKggEKBgQAAwACBRIDOgQmGnMgUHJvbXB0IHRvIGdpdmUg
d2hlbiB0aGUgdXNlciBkb2VzIG5vdCBwcm92aWRlIGFuIGlucHV0IGZvciB0aGUgc2Vjb25k
CiB0aW1lLiBFeGFtcGxlOiAiU29ycnksIEkgZGlkbid0IGdldCB0aGF0LiIKCg4KBwQAAwAC
BQYSAzoEEAoOCgcEAAMAAgUBEgM6ESEKDgoHBAADAAIFAxIDOiQlCoABCgYEAAMAAgYSAz4E
KxpxIFByb21wdCB0byBnaXZlIHdoZW4gdGhlIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhbiBp
bnB1dCBmb3IgdGhlIGxhc3QKIHRpbWUuIEV4YW1wbGU6ICJTb3JyeSwgSSBkaWRuJ3QgZ2V0
IHRoYXQuIgoKDgoHBAADAAIGBhIDPgQQCg4KBwQAAwACBgESAz4RJgoOCgcEAAMAAgYDEgM+
KSoKdwoEBAADARIEQwJKAxppIE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgY29tbWl0IGJlaGF2
aW9yIGFzc29jaWF0ZWQgd2l0aCB0aGUgc2xvdCBhZnRlciBpdAogaGFzIGJlZW4gc3VjY2Vz
c2Z1bGx5IGZpbGxlZC4KCgwKBQQAAwEBEgNDChgK9QIKBgQAAwECABIDSQQjGuUCIFRoZSBz
ZXNzaW9uIHBhcmFtZXRlciB0byB3cml0ZSB0aGUgc2xvdCB2YWx1ZSBhZnRlciBpdCBpcyBm
aWxsZWQuIE5vdGUKIHRoYXQgbmVzdGVkIHBhdGhzIGFyZSBub3QgY3VycmVudGx5IHN1cHBv
cnRlZC4gIiQkIiBpcyB1c2VkIHRvIHdyaXRlIHRoZQogc2xvdCB2YWx1ZSB0byBhIHNlc3Np
b24gcGFyYW1ldGVyIHdpdGggc2FtZSBuYW1lIGFzIHRoZSBzbG90LgogRWc6IHdyaXRlX3Nl
c3Npb25fcGFyYW0gPSAiZnJ1aXQiIGNvcnJlc3BvbmRzIHRvICIkc2Vzc2lvbi5wYXJhbXMu
ZnJ1aXQiLgogd3JpdGVfc2Vzc2lvbl9wYXJhbSA9ICJ0aWNrZXQiIGNvcnJlc3BvbmRzIHRv
ICIkc2Vzc2lvbi5wYXJhbXMudGlja2V0Ii4KCg4KBwQAAwECAAUSA0kECgoOCgcEAAMBAgAB
EgNJCx4KDgoHBAADAQIAAxIDSSEiCkgKBAQAAwISBE0CWQMaOiBDb25maWd1cmF0aW9uIHRv
IHBvcHVsYXRlIGEgZGVmYXVsdCB2YWx1ZSBmb3IgdGhpcyBzbG90LgoKDAoFBAADAgESA00K
FgrwAgoGBAADAgIAEgNTBEYa4AIgT3B0aW9uYWwuIFRoZSBzZXNzaW9uIHBhcmFtZXRlciB0
byBiZSB1c2VkIHRvIGluaXRpYWxpemUgdGhlIHNsb3QgdmFsdWUsIGlmIGl0IGhhcwogYSBu
b24tZW1wdHkgdmFsdWUuIFRoZSB0eXBlIG9mIHRoZSB2YWx1ZSBtdXN0IG1hdGNoIHRoZSB0
eXBlIG9mIHRoZSBzbG90LgogTm90ZSB0aGF0IG5lc3RlZCBwYXRocyBhcmUgbm90IGN1cnJl
bnRseSBzdXBwb3J0ZWQuCiBFZzogYHNlc3Npb25fcGFyYW0gPSAiZnJ1aXQiYCBjb3JyZXNw
b25kcyB0byBgJHNlc3Npb24ucGFyYW1zLmZydWl0YC4KIGBzZXNzaW9uX3BhcmFtID0gInRp
Y2tldCJgIGNvcnJlc3BvbmRzIHRvIGAkc2Vzc2lvbi5wYXJhbXMudGlja2V0YC4KCg4KBwQA
AwICAAUSA1MECgoOCgcEAAMCAgABEgNTCxgKDgoHBAADAgIAAxIDUxscCg4KBwQAAwICAAgS
A1MdRQoRCgoEAAMCAgAInAgAEgNTHkQK2gEKBgQAAwICARIDWARQGsoBIE9wdGlvbmFsLiBD
b25zdGFudCBkZWZhdWx0IHZhbHVlIGZvciB0aGUgc2xvdC4gVGhpcyB3aWxsIG9ubHkgYmUg
dXNlZCBpZiBhIHZhbHVlCiBmb3IgdGhpcyBzbG90IHdhcyBub3QgcG9wdWxhdGVkIHRocm91
Z2ggdGhlIGBzZXNzaW9uX3BhcmFtYC4gVGhlCiB0eXBlIGZvciB0aGlzIHZhbHVlIG11c3Qg
bWF0Y2ggdGhlIHR5cGUgb2YgdGhlIHNsb3QuCgoOCgcEAAMCAgEGEgNYBBkKDgoHBAADAgIB
ARIDWBoiCg4KBwQAAwICAQMSA1glJgoOCgcEAAMCAgEIEgNYJ08KEQoKBAADAgIBCJwIABID
WChOCioKBAQAAgASA1wCOxodIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBzbG90LgoKDAoFBAAC
AAUSA1wCCAoMCgUEAAIAARIDXAkNCgwKBQQAAgADEgNcEBEKDAoFBAACAAgSA1wSOgoPCggE
AAIACJwIABIDXBM5Cj0KBAQAAgESA18CbxowIFJlcXVpcmVkLiBEZWNsYXJlcyB0aGUgZGF0
YSB0eXBlIG9mIHRoaXMgc2xvdC4KCgwKBQQAAgEGEgNfAjwKDAoFBAACAQESA189QQoMCgUE
AAIBAxIDX0RFCgwKBQQAAgEIEgNfRm4KDwoIBAACAQicCAASA19HbQq0AQoEBAACAhIDZAI9
GqYBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgc2xvdCBpcyByZXF1aXJlZCB0
byBiZSBmaWxsZWQgYmVmb3JlCiBhZHZhbmNpbmcuIFJlcXVpcmVkIHNsb3RzIHRoYXQgYXJl
IG5vdCBmaWxsZWQgd2lsbCB0cmlnZ2VyIGEgY3VzdG9taXphYmxlCiBwcm9tcHQgdG8gdGhl
IHVzZXIuCgoMCgUEAAICBRIDZAIGCgwKBQQAAgIBEgNkBw8KDAoFBAACAgMSA2QSEwoMCgUE
AAICCBIDZBQ8Cg8KCAQAAgIInAgAEgNkFTsKUAoEBAACAxIDZwJOGkMgT3B0aW9uYWwuIFJl
Z2lzdGVycyBQcm9tcHRzIGZvciBkaWZmZXJlbnQgc3RhZ2VzIG9mIHNsb3QgZmlsbGluZy4K
CgwKBQQAAgMGEgNnAhAKDAoFBAACAwESA2cRIAoMCgUEAAIDAxIDZyMkCgwKBQQAAgMIEgNn
JU0KDwoIBAACAwicCAASA2cmTApCCgQEAAIEEgNqAk4aNSBPcHRpb25hbC4gQ29tbWl0IGJl
aGF2aW9yIGFzc29jaWF0ZWQgd2l0aCB0aGUgc2xvdC4KCgwKBQQAAgQGEgNqAhAKDAoFBAAC
BAESA2oRIAoMCgUEAAIEAxIDaiMkCgwKBQQAAgQIEgNqJU0KDwoIBAACBAicCAASA2omTAq6
BgoEBAACBRIEgAECTBqrBiBPcHRpb25hbC4gQWRkaXRpb25hbCBjb25maWd1cmF0aW9uIGFz
c29jaWF0ZWQgd2l0aCB0aGUgc2xvdCB3aGljaCBpcwogdXNlZCBmb3IgZmlsbGluZyB0aGUg
c2xvdC4gVGhlIGZvcm1hdCBvZiB0aGUgY29uZmlnIGlzIHNwZWNpZmljIHRvIHRoZQogdHlw
ZSBvZiB0aGUgc2xvdC4gUmVzb3VyY2UgcmVmZXJlbmNlcyB0byB1c2VyIG9yIHNlc3Npb24g
cGFyYW1ldGVyIGNhbiBiZQogYWRkZWQgdG8gdGhpcyBjb25maWcuIFRoaXMgY29uZmlnIGlz
IG5lZWRlZCBmb3IgZmlsbGluZyBzbG90cyByZWxhdGVkIHRvCiB0cmFuc2FjdGlvbnMgYW5k
IHVzZXIgZW5nYWdlbWVudC4KCiBFeGFtcGxlOgogIEZvciBhIHNsb3Qgb2YgdHlwZSBhY3Rp
b25zLnR5cGUuQ29tcGxldGVQdXJjaGFzZVZhbHVlLCB0aGUgZm9sbG93aW5nCiAgY29uZmln
IHByb3Bvc2VzIGEgZGlnaXRhbCBnb29kIG9yZGVyIHdpdGggYSByZWZlcmVuY2UgdG8gYSBj
bGllbnQgZGVmaW5lZAogIHNlc3Npb24gcGFyYW1ldGVyIGB1c2VyU2VsZWN0ZWRTa3VJZGA6
CgogICAgewogICAgICAiQHR5cGUiOiAidHlwZS5nb29nbGVhcGlzLmNvbS8KICAgICAgICAg
ICAgICAgICAgZ29vZ2xlLmFjdGlvbnMudHJhbnNhY3Rpb25zLnYzLkNvbXBsZXRlUHVyY2hh
c2VWYWx1ZVNwZWMiLAogICAgICAic2t1SWQiOiB7CiAgICAgICAgInNrdVR5cGUiOiAiU0tV
X1RZUEVfSU5fQVBQIiwKICAgICAgICAiaWQiOiAiJHNlc3Npb24ucGFyYW1zLnVzZXJTZWxl
Y3RlZFNrdUlkIiwKICAgICAgICAicGFja2FnZU5hbWUiOiAiY29tLmV4YW1wbGUuY29tcGFu
eSIKICAgICAgfQogICAgfQoKDQoFBAACBQYSBIABAhcKDQoFBAACBQESBIABGB4KDQoFBAAC
BQMSBIABISIKDQoFBAACBQgSBIABI0sKEAoIBAACBQicCAASBIABJEoKUgoEBAACBhIEgwEC
ShpEIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIHRvIHBvcHVsYXRlIGEgZGVmYXVsdCB2YWx1
ZSBmb3IgdGhpcyBzbG90LgoKDQoFBAACBgYSBIMBAg4KDQoFBAACBgESBIMBDxwKDQoFBAAC
BgMSBIMBHyAKDQoFBAACBggSBIMBIUkKEAoIBAACBgicCAASBIMBIkhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot ===
    # Fields for Slot
    # Field: name Type: 9 ()
    # Field: type Type: 11 (.google.actions.sdk.v2.interactionmodel.type.ClassReference)
    # Field: required Type: 8 ()
    # Field: prompt_settings Type: 11 (.google.actions.sdk.v2.interactionmodel.Slot.PromptSettings)
    # Field: commit_behavior Type: 11 (.google.actions.sdk.v2.interactionmodel.Slot.CommitBehavior)
    # Field: config Type: 11 (.google.protobuf.Value)
    # Field: default_value Type: 11 (.google.actions.sdk.v2.interactionmodel.Slot.DefaultValue)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Slot - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/slot.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Slot;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot->new({
        name => $name,
        type => $type,
        required => $required,
        prompt_settings => $prompt_settings,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/slot.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot

Configuration for a slot. Slots are single units of data that can be filled
through natural language (ie. intent parameters), session parameters, and
other sources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the slot.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference>)

Required. Declares the data type of this slot.

=item * C<< $msg->required() >> / C<< $msg->required($value) >>

Type: C<Bool>

Optional. Indicates whether the slot is required to be filled before
advancing. Required slots that are not filled will trigger a customizable
prompt to the user.

=item * C<< $msg->prompt_settings() >> / C<< $msg->prompt_settings($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::PromptSettings>)

Optional. Registers Prompts for different stages of slot filling.

=item * C<< $msg->commit_behavior() >> / C<< $msg->commit_behavior($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::CommitBehavior>)

Optional. Commit behavior associated with the slot.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. Additional configuration associated with the slot which is
used for filling the slot. The format of the config is specific to the
type of the slot. Resource references to user or session parameter can be
added to this config. This config is needed for filling slots related to
transactions and user engagement.

Example:
 For a slot of type actions.type.CompletePurchaseValue, the following
 config proposes a digital good order with a reference to a client defined
 session parameter `userSelectedSkuId`:

   {
     "@type": "type.googleapis.com/
                 google.actions.transactions.v3.CompletePurchaseValueSpec",
     "skuId": {
       "skuType": "SKU_TYPE_IN_APP",
       "id": "$session.params.userSelectedSkuId",
       "packageName": "com.example.company"
     }
   }

=item * C<< $msg->default_value() >> / C<< $msg->default_value($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::DefaultValue>)

Optional. Configuration to populate a default value for this slot.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Slot::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
