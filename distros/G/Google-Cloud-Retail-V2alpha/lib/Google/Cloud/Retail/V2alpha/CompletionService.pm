package Google::Cloud::Retail::V2alpha::CompletionService;

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
    eval { require Google::Cloud::Retail::V2alpha::Common };
    eval { require Google::Cloud::Retail::V2alpha::ImportConfig };
    eval { require Google::Cloud::Retail::V2alpha::SearchService };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvY29tcGxldGlvbl9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvcmV0
YWlsL3YyYWxwaGEvY29tbW9uLnByb3RvGi9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEv
aW1wb3J0X2NvbmZpZy5wcm90bxowZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmFscGhhL3NlYXJj
aF9zZXJ2aWNlLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byL2
AgoUQ29tcGxldGVRdWVyeVJlcXVlc3QSPwoHY2F0YWxvZxgBIAEoCUIl4EEC+kEfCh1yZXRh
aWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IHY2F0YWxvZxIZCgVxdWVyeRgCIAEoCUID4EEC
UgVxdWVyeRIdCgp2aXNpdG9yX2lkGAcgASgJUgl2aXNpdG9ySWQSJQoObGFuZ3VhZ2VfY29k
ZXMYAyADKAlSDWxhbmd1YWdlQ29kZXMSHwoLZGV2aWNlX3R5cGUYBCABKAlSCmRldmljZVR5
cGUSGAoHZGF0YXNldBgGIAEoCVIHZGF0YXNldBInCg9tYXhfc3VnZ2VzdGlvbnMYBSABKAVS
Dm1heFN1Z2dlc3Rpb25zEkAKHGVuYWJsZV9hdHRyaWJ1dGVfc3VnZ2VzdGlvbnMYCSABKAhS
GmVuYWJsZUF0dHJpYnV0ZVN1Z2dlc3Rpb25zEhYKBmVudGl0eRgKIAEoCVIGZW50aXR5IrMK
ChVDb21wbGV0ZVF1ZXJ5UmVzcG9uc2UScgoSY29tcGxldGlvbl9yZXN1bHRzGAEgAygLMkMu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbXBsZXRlUXVlcnlSZXNwb25zZS5Db21w
bGV0aW9uUmVzdWx0UhFjb21wbGV0aW9uUmVzdWx0cxIrChFhdHRyaWJ1dGlvbl90b2tlbhgC
IAEoCVIQYXR0cmlidXRpb25Ub2tlbhJ9ChVyZWNlbnRfc2VhcmNoX3Jlc3VsdHMYAyADKAsy
RS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29tcGxldGVRdWVyeVJlc3BvbnNlLlJl
Y2VudFNlYXJjaFJlc3VsdEICGAFSE3JlY2VudFNlYXJjaFJlc3VsdHMSdQoRYXR0cmlidXRl
X3Jlc3VsdHMYBCADKAsySC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29tcGxldGVR
dWVyeVJlc3BvbnNlLkF0dHJpYnV0ZVJlc3VsdHNFbnRyeVIQYXR0cmlidXRlUmVzdWx0cxJj
Cg1hZ2VudF9wcm9tcHRzGAUgAygLMj4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNv
bXBsZXRlUXVlcnlSZXNwb25zZS5BZ2VudFByb21wdFIMYWdlbnRQcm9tcHRzGvgDChBDb21w
bGV0aW9uUmVzdWx0Eh4KCnN1Z2dlc3Rpb24YASABKAlSCnN1Z2dlc3Rpb24ScwoKYXR0cmli
dXRlcxgCIAMoCzJTLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Db21wbGV0ZVF1ZXJ5
UmVzcG9uc2UuQ29tcGxldGlvblJlc3VsdC5BdHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMS
SQoGZmFjZXRzGAMgAygLMjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlYXJjaFJl
c3BvbnNlLkZhY2V0UgZmYWNldHMSLgoTdG90YWxfcHJvZHVjdF9jb3VudBgEIAEoBVIRdG90
YWxQcm9kdWN0Q291bnQSZwoNYWdlbnRfcHJvbXB0cxgGIAMoCzI+Lmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5Db21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQWdlbnRQcm9tcHRCAhgBUgxh
Z2VudFByb21wdHMaawoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkIKBXZh
bHVlGAIgASgLMiwuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkN1c3RvbUF0dHJpYnV0
ZVIFdmFsdWU6AjgBGj0KElJlY2VudFNlYXJjaFJlc3VsdBIjCg1yZWNlbnRfc2VhcmNoGAEg
ASgJUgxyZWNlbnRTZWFyY2g6AhgBGjMKD0F0dHJpYnV0ZVJlc3VsdBIgCgtzdWdnZXN0aW9u
cxgBIAMoCVILc3VnZ2VzdGlvbnMaJQoLQWdlbnRQcm9tcHQSFgoGcHJvbXB0GAEgASgJUgZw
cm9tcHQahwEKFUF0dHJpYnV0ZVJlc3VsdHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJYCgV2
YWx1ZRgCIAEoCzJCLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Db21wbGV0ZVF1ZXJ5
UmVzcG9uc2UuQXR0cmlidXRlUmVzdWx0UgV2YWx1ZToCOAEy1QQKEUNvbXBsZXRpb25TZXJ2
aWNlEsIBCg1Db21wbGV0ZVF1ZXJ5EjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNv
bXBsZXRlUXVlcnlSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbXBs
ZXRlUXVlcnlSZXNwb25zZSJKgtPkkwJEEkIvdjJhbHBoYS97Y2F0YWxvZz1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9OmNvbXBsZXRlUXVlcnkSrwIKFEltcG9ydENvbXBs
ZXRpb25EYXRhEjguZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkltcG9ydENvbXBsZXRp
b25EYXRhUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ivQGC0+STAk4i
SS92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9j
b21wbGV0aW9uRGF0YTppbXBvcnQ6ASrKQWYKOGdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBo
YS5JbXBvcnRDb21wbGV0aW9uRGF0YVJlc3BvbnNlEipnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuSW1wb3J0TWV0YWRhdGEaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C2gEKH2NvbS5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYWxwaGFCFkNvbXBsZXRpb25TZXJ2aWNlUHJvdG9QAVo3Y2xv
dWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqIC
BlJFVEFJTKoCG0dvb2dsZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxS
ZXRhaWxcVjJhbHBoYeoCHkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUqqTwoHEgUO
AJoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgID
ABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADIKCQoC
AwUSAxcAOQoJCgIDBhIDGAA6CgkKAgMHEgMZAC0KCAoBCBIDGwA4CgkKAgglEgMbADgKCAoB
CBIDHABOCgkKAggLEgMcAE4KCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgA3CgkKAggI
EgMeADcKCAoBCBIDHwA4CgkKAggBEgMfADgKCAoBCBIDIAAkCgkKAggkEgMgACQKCAoBCBID
IQA4CgkKAggpEgMhADgKCAoBCBIDIgA3CgkKAggtEgMiADcKvAEKAgYAEgQoAEsBGq8BIEF1
dG9jb21wbGV0ZSBzZXJ2aWNlIGZvciByZXRhaWwuCgogVGhpcyBmZWF0dXJlIGlzIG9ubHkg
YXZhaWxhYmxlIGZvciB1c2VycyB3aG8gaGF2ZSBSZXRhaWwgU2VhcmNoIGVuYWJsZWQuCiBF
bmFibGUgUmV0YWlsIFNlYXJjaCBvbiBDbG91ZCBDb25zb2xlIGJlZm9yZSB1c2luZyB0aGlz
IGZlYXR1cmUuCgoKCgMGAAESAygIGQoKCgMGAAMSAykCPQoMCgUGAAOZCBIDKQI9CgsKAwYA
AxIEKgIrNwoNCgUGAAOaCBIEKgIrNwrWAQoEBgACABIEMQI1AxrHASBDb21wbGV0ZXMgdGhl
IHNwZWNpZmllZCBwcmVmaXggd2l0aCBrZXl3b3JkIHN1Z2dlc3Rpb25zLgoKIFRoaXMgZmVh
dHVyZSBpcyBvbmx5IGF2YWlsYWJsZSBmb3IgdXNlcnMgd2hvIGhhdmUgUmV0YWlsIFNlYXJj
aCBlbmFibGVkLgogRW5hYmxlIFJldGFpbCBTZWFyY2ggb24gQ2xvdWQgQ29uc29sZSBiZWZv
cmUgdXNpbmcgdGhpcyBmZWF0dXJlLgoKDAoFBgACAAESAzEGEwoMCgUGAAIAAhIDMRQoCgwK
BQYAAgADEgMxM0gKDQoFBgACAAQSBDIENAYKEQoJBgACAASwyrwiEgQyBDQGCqoDCgQGAAIB
EgRAAkoDGpsDIEJ1bGsgaW1wb3J0IG9mIHByb2Nlc3NlZCBjb21wbGV0aW9uIGRhdGFzZXQu
CgogUmVxdWVzdCBwcm9jZXNzaW5nIGlzIGFzeW5jaHJvbm91cy4gUGFydGlhbCB1cGRhdGlu
ZyBpcyBub3Qgc3VwcG9ydGVkLgoKIFRoZSBvcGVyYXRpb24gaXMgc3VjY2Vzc2Z1bGx5IGZp
bmlzaGVkIG9ubHkgYWZ0ZXIgdGhlIGltcG9ydGVkIHN1Z2dlc3Rpb25zCiBhcmUgaW5kZXhl
ZCBzdWNjZXNzZnVsbHkgYW5kIHJlYWR5IGZvciBzZXJ2aW5nLiBUaGUgcHJvY2VzcyB0YWtl
cyBob3Vycy4KCiBUaGlzIGZlYXR1cmUgaXMgb25seSBhdmFpbGFibGUgZm9yIHVzZXJzIHdo
byBoYXZlIFJldGFpbCBTZWFyY2ggZW5hYmxlZC4KIEVuYWJsZSBSZXRhaWwgU2VhcmNoIG9u
IENsb3VkIENvbnNvbGUgYmVmb3JlIHVzaW5nIHRoaXMgZmVhdHVyZS4KCgwKBQYAAgEBEgNA
BhoKDAoFBgACAQISA0AbNgoMCgUGAAIBAxIDQQ8rCg0KBQYAAgEEEgRCBEUGChEKCQYAAgEE
sMq8IhIEQgRFBgoNCgUGAAIBBBIERgRJBgoPCgcGAAIBBJkIEgRGBEkGCicKAgQAEgVOAKwB
ARoaIEF1dG9jb21wbGV0ZSBwYXJhbWV0ZXJzLgoKCgoDBAABEgNOCBwKqwEKBAQAAgASBFMC
VgQanAEgUmVxdWlyZWQuIENhdGFsb2cgZm9yIHdoaWNoIHRoZSBjb21wbGV0aW9uIGlzIHBl
cmZvcm1lZC4KCiBGdWxsIHJlc291cmNlIG5hbWUgb2YgY2F0YWxvZywgc3VjaCBhcwogYHBy
b2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2dgLgoK
DAoFBAACAAUSA1MCCAoMCgUEAAIAARIDUwkQCgwKBQQAAgADEgNTExQKDQoFBAACAAgSBFMV
VgMKDwoIBAACAAicCAASA1QEKgoOCgcEAAIACJ8IEgNVBE8KcwoEBAACARIDWwI8GmYgUmVx
dWlyZWQuIFRoZSBxdWVyeSB1c2VkIHRvIGdlbmVyYXRlIHN1Z2dlc3Rpb25zLgoKIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgaXMgMjU1LgoKDAoFBAACAQUS
A1sCCAoMCgUEAAIBARIDWwkOCgwKBQQAAgEDEgNbERIKDAoFBAACAQgSA1sTOwoPCggEAAIB
CJwIABIDWxQ6CrADCgQEAAICEgNkAhgaogMgUmVjb21tZW5kZWQgZmllbGQuIEEgdW5pcXVl
IGlkZW50aWZpZXIgZm9yIHRyYWNraW5nIHZpc2l0b3JzLiBGb3IgZXhhbXBsZSwKIHRoaXMg
Y291bGQgYmUgaW1wbGVtZW50ZWQgd2l0aCBhbiBIVFRQIGNvb2tpZSwgd2hpY2ggc2hvdWxk
IGJlIGFibGUgdG8KIHVuaXF1ZWx5IGlkZW50aWZ5IGEgdmlzaXRvciBvbiBhIHNpbmdsZSBk
ZXZpY2UuIFRoaXMgdW5pcXVlIGlkZW50aWZpZXIKIHNob3VsZCBub3QgY2hhbmdlIGlmIHRo
ZSB2aXNpdG9yIGxvZ3MgaW4gb3Igb3V0IG9mIHRoZSB3ZWJzaXRlLgoKIFRoZSBmaWVsZCBt
dXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAx
MjgKIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBp
cyByZXR1cm5lZC4KCgwKBQQAAgIFEgNkAggKDAoFBAACAgESA2QJEwoMCgUEAAICAxIDZBYX
CqUECgQEAAIDEgNvAiUalwQgTm90ZSB0aGF0IHRoaXMgZmllbGQgYXBwbGllcyBmb3IgYHVz
ZXItZGF0YWAgZGF0YXNldCBvbmx5LiBGb3IgcmVxdWVzdHMKIHdpdGggYGNsb3VkLXJldGFp
bGAgZGF0YXNldCwgc2V0dGluZyB0aGlzIGZpZWxkIGhhcyBubyBlZmZlY3QuCgogVGhlIGxh
bmd1YWdlIGZpbHRlcnMgYXBwbGllZCB0byB0aGUgb3V0cHV0IHN1Z2dlc3Rpb25zLiBJZiBz
ZXQsIGl0IHNob3VsZAogY29udGFpbiB0aGUgbGFuZ3VhZ2Ugb2YgdGhlIHF1ZXJ5LiBJZiBu
b3Qgc2V0LCBzdWdnZXN0aW9ucyBhcmUgcmV0dXJuZWQKIHdpdGhvdXQgY29uc2lkZXJpbmcg
bGFuZ3VhZ2UgcmVzdHJpY3Rpb25zLiBUaGlzIGlzIHRoZSBCQ1AtNDcgbGFuZ3VhZ2UKIGNv
ZGUsIHN1Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuIEZvciBtb3JlIGluZm9ybWF0aW9u
LCBzZWUgW1RhZ3MgZm9yCiBJZGVudGlmeWluZyBMYW5ndWFnZXNdKGh0dHBzOi8vdG9vbHMu
aWV0Zi5vcmcvaHRtbC9iY3A0NykuIFRoZSBtYXhpbXVtCiBudW1iZXIgb2YgbGFuZ3VhZ2Ug
Y29kZXMgaXMgMy4KCgwKBQQAAgMEEgNvAgoKDAoFBAACAwUSA28LEQoMCgUEAAIDARIDbxIg
CgwKBQQAAgMDEgNvIyQKmQMKBAQAAgQSBIEBAhkaigMgVGhlIGRldmljZSB0eXBlIGNvbnRl
eHQgZm9yIGNvbXBsZXRpb24gc3VnZ2VzdGlvbnMuIFdlIHJlY29tbWVuZCB0aGF0IHlvdQog
bGVhdmUgdGhpcyBmaWVsZCBlbXB0eS4KCiBJdCBjYW4gYXBwbHkgZGlmZmVyZW50IHN1Z2dl
c3Rpb25zIG9uIGRpZmZlcmVudCBkZXZpY2UgdHlwZXMsIGUuZy4KIGBERVNLVE9QYCwgYE1P
QklMRWAuIElmIGl0IGlzIGVtcHR5LCB0aGUgc3VnZ2VzdGlvbnMgYXJlIGFjcm9zcyBhbGwg
ZGV2aWNlCiB0eXBlcy4KCiBTdXBwb3J0ZWQgZm9ybWF0czoKCiAqIGBVTktOT1dOX0RFVklD
RV9UWVBFYAoKICogYERFU0tUT1BgCgogKiBgTU9CSUxFYAoKICogQSBjdXN0b21pemVkIHN0
cmluZyBzdGFydHMgd2l0aCBgT1RIRVJfYCwgZS5nLiBgT1RIRVJfSVBIT05FYC4KCg0KBQQA
AgQFEgSBAQIICg0KBQQAAgQBEgSBAQkUCg0KBQQAAgQDEgSBARcYCvIECgQEAAIFEgSRAQIV
GuMEIERldGVybWluZXMgd2hpY2ggZGF0YXNldCB0byB1c2UgZm9yIGZldGNoaW5nIGNvbXBs
ZXRpb24uICJ1c2VyLWRhdGEiIHdpbGwKIHVzZSB0aGUgZGF0YXNldCBpbXBvcnRlZCB0aHJv
dWdoCiBbQ29tcGxldGlvblNlcnZpY2UuSW1wb3J0Q29tcGxldGlvbkRhdGFdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYS5Db21wbGV0aW9uU2VydmljZS5JbXBvcnRDb21wbGV0aW9u
RGF0YV0uCiBgY2xvdWQtcmV0YWlsYCB3aWxsIHVzZSB0aGUgZGF0YXNldCBnZW5lcmF0ZWQg
YnkgQ2xvdWQgUmV0YWlsIGJhc2VkIG9uIHVzZXIKIGV2ZW50cy4gSWYgbGVmdCBlbXB0eSwg
Y29tcGxldGlvbnMgd2lsbCBiZSBmZXRjaGVkIGZyb20gdGhlIGB1c2VyLWRhdGFgCiBkYXRh
c2V0LgoKIEN1cnJlbnQgc3VwcG9ydGVkIHZhbHVlczoKCiAqIHVzZXItZGF0YQoKICogY2xv
dWQtcmV0YWlsOgogICBUaGlzIG9wdGlvbiByZXF1aXJlcyBlbmFibGluZyBhdXRvLWxlYXJu
aW5nIGZ1bmN0aW9uIGZpcnN0LiBTZWUKICAgW2d1aWRlbGluZXNdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9yZXRhaWwvZG9jcy9jb21wbGV0aW9uLW92ZXJ2aWV3I2dlbmVyYXRlZC1j
b21wbGV0aW9uLWRhdGFzZXQpLgoKDQoFBAACBQUSBJEBAggKDQoFBAACBQESBJEBCRAKDQoF
BAACBQMSBJEBExQKsgIKBAQAAgYSBJkBAhwaowIgQ29tcGxldGlvbiBtYXggc3VnZ2VzdGlv
bnMuIElmIGxlZnQgdW5zZXQgb3Igc2V0IHRvIDAsIHRoZW4gd2lsbCBmYWxsYmFjawogdG8g
dGhlIGNvbmZpZ3VyZWQgdmFsdWUKIFtDb21wbGV0aW9uQ29uZmlnLm1heF9zdWdnZXN0aW9u
c11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbXBsZXRpb25Db25maWcubWF4X3N1
Z2dlc3Rpb25zXS4KCiBUaGUgbWF4aW11bSBhbGxvd2VkIG1heCBzdWdnZXN0aW9ucyBpcyAy
MC4gSWYgaXQgaXMgc2V0IGhpZ2hlciwgaXQgd2lsbCBiZQogY2FwcGVkIGJ5IDIwLgoKDQoF
BAACBgUSBJkBAgcKDQoFBAACBgESBJkBCBcKDQoFBAACBgMSBJkBGhsKmAEKBAQAAgcSBJ4B
AigaiQEgSWYgdHJ1ZSwgYXR0cmlidXRlIHN1Z2dlc3Rpb25zIGFyZSBlbmFibGVkIGFuZCBw
cm92aWRlZCBpbiB0aGUgcmVzcG9uc2UuCgogVGhpcyBmaWVsZCBpcyBvbmx5IGF2YWlsYWJs
ZSBmb3IgdGhlIGBjbG91ZC1yZXRhaWxgIGRhdGFzZXQuCgoNCgUEAAIHBRIEngECBgoNCgUE
AAIHARIEngEHIwoNCgUEAAIHAxIEngEmJwqzBQoEBAACCBIEqwECFRqkBSBUaGUgZW50aXR5
IGZvciBjdXN0b21lcnMgd2hvIHJ1biBtdWx0aXBsZSBlbnRpdGllcywgZG9tYWlucywgc2l0
ZXMsIG9yCiByZWdpb25zLCBmb3IgZXhhbXBsZSwgYEdvb2dsZSBVU2AsIGBHb29nbGUgQWRz
YCwgYFdheW1vYCwKIGBnb29nbGUuY29tYCwgYHlvdXR1YmUuY29tYCwgZXRjLgogSWYgdGhp
cyBpcyBzZXQsIGl0IG11c3QgYmUgYW4gZXhhY3QgbWF0Y2ggd2l0aAogW1VzZXJFdmVudC5l
bnRpdHldW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Vc2VyRXZlbnQuZW50aXR5XSB0
byBnZXQKIHBlci1lbnRpdHkgYXV0b2NvbXBsZXRlIHJlc3VsdHMuIFRoaXMgZmllbGQgd2ls
bCBiZSBhcHBsaWVkIHRvCiBgY29tcGxldGlvbl9yZXN1bHRzYCBvbmx5LiBJdCBoYXMgbm8g
ZWZmZWN0IG9uIHRoZSBgYXR0cmlidXRlX3Jlc3VsdHNgLgogQWxzbywgdGhpcyBlbnRpdHkg
c2hvdWxkIGJlIGxpbWl0ZWQgdG8gMjU2IGNoYXJhY3RlcnMsIGlmIHRvbyBsb25nLCBpdCB3
aWxsCiBiZSB0cnVuY2F0ZWQgdG8gMjU2IGNoYXJhY3RlcnMgaW4gYm90aCBnZW5lcmF0aW9u
IGFuZCBzZXJ2aW5nIHRpbWUsIGFuZCBtYXkKIGxlYWQgdG8gbWlzLW1hdGNoLiBUbyBlbnN1
cmUgaXQgd29ya3MsIHBsZWFzZSBzZXQgdGhlIGVudGl0eSB3aXRoIHN0cmluZwogd2l0aGlu
IDI1NiBjaGFyYWN0ZXJzLgoKDQoFBAACCAUSBKsBAggKDQoFBAACCAESBKsBCQ8KDQoFBAAC
CAMSBKsBEhQKMwoCBAESBq8BAJoCARolIFJlc3BvbnNlIG9mIHRoZSBhdXRvY29tcGxldGUg
cXVlcnkuCgoLCgMEAQESBK8BCB0KPgoEBAEDABIGsQEC1QEDGi4gUmVzb3VyY2UgdGhhdCBy
ZXByZXNlbnRzIGNvbXBsZXRpb24gcmVzdWx0cy4KCg0KBQQBAwABEgSxAQoaCi8KBgQBAwAC
ABIEswEEGhofIFRoZSBzdWdnZXN0aW9uIGZvciB0aGUgcXVlcnkuCgoPCgcEAQMAAgAFEgSz
AQQKCg8KBwQBAwACAAESBLMBCxUKDwoHBAEDAAIAAxIEswEYGQrvAgoGBAEDAAIBEgS+AQQw
Gt4CIEN1c3RvbSBhdHRyaWJ1dGVzIGZvciB0aGUgc3VnZ2VzdGlvbiB0ZXJtLgoKICogRm9y
IGB1c2VyLWRhdGFgLCB0aGUgYXR0cmlidXRlcyBhcmUgYWRkaXRpb25hbCBjdXN0b20gYXR0
cmlidXRlcwogaW5nZXN0ZWQgdGhyb3VnaCBCaWdRdWVyeS4KCiAqIEZvciBgY2xvdWQtcmV0
YWlsYCwgdGhlIGF0dHJpYnV0ZXMgYXJlIHByb2R1Y3QgYXR0cmlidXRlcyBnZW5lcmF0ZWQK
IGJ5IENsb3VkIFJldGFpbC4gSXQgcmVxdWlyZXMKIFtVc2VyRXZlbnQucHJvZHVjdF9kZXRh
aWxzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXNlckV2ZW50LnByb2R1Y3RfZGV0
YWlsc10KIGlzIGltcG9ydGVkIHByb3Blcmx5LgoKDwoHBAEDAAIBBhIEvgEEIAoPCgcEAQMA
AgEBEgS+ASErCg8KBwQBAwACAQMSBL4BLi8KqQIKBgQBAwACAhIExQEELRqYAiBGYWNldCBp
bmZvcm1hdGlvbiBmb3IgdGhlIHN1Z2dlc3Rpb24gdGVybS4gR2l2ZXMgdGhlIG51bWJlciBv
ZiBpdGVtcwogcmVzdWx0aW5nIGZyb20gYSBzZWFyY2ggd2l0aCB0aGlzIHN1Z2dlc3Rpb24g
dGVybSBmb3IgZWFjaCBmYWNldC4KCiBUaGlzIGlzIGFuIGV4cGVyaW1lbnRhbCBmZWF0dXJl
IGZvciBsaW1pdGVkIGN1c3RvbWVycy4gSWYgeW91IHdhbnQgdG8KIHJlY2VpdmUgdGhpcyBm
YWNldCBpbmZvcm1hdGlvbiwgcmVhY2ggb3V0IHRvIHRoZSBSZXRhaWwgc3VwcG9ydCB0ZWFt
LgoKDwoHBAEDAAICBBIExQEEDAoPCgcEAQMAAgIGEgTFAQ0hCg8KBwQBAwACAgESBMUBIigK
DwoHBAEDAAICAxIExQErLAryAQoGBAEDAAIDEgTMAQQiGuEBIFRvdGFsIG51bWJlciBvZiBw
cm9kdWN0cyBhc3NvY2lhdGVkIHdpdGggYSBzZWFyY2ggd2l0aCB0aGlzIHN1Z2dlc3Rpb24u
CgogVGhpcyBpcyBhbiBleHBlcmltZW50YWwgZmVhdHVyZSBmb3IgbGltaXRlZCBjdXN0b21l
cnMuIElmIHlvdSB3YW50IHRvCiByZWNlaXZlIHRoaXMgcHJvZHVjdCBjb3VudCBpbmZvcm1h
dGlvbiwgcmVhY2ggb3V0IHRvIHRoZSBSZXRhaWwgc3VwcG9ydAogdGVhbS4KCg8KBwQBAwAC
AwUSBMwBBAkKDwoHBAEDAAIDARIEzAEKHQoPCgcEAQMAAgMDEgTMASAhCsICCgYEAQMAAgQS
BNQBBD8asQIgRGVwcmVjYXRlZDogVXNlCiBbQ29tcGxldGVRdWVyeVJlc3BvbnNlLmFnZW50
X3Byb21wdHNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Db21wbGV0ZVF1ZXJ5UmVz
cG9uc2UuYWdlbnRfcHJvbXB0c10KIGluc3RlYWQuIENvbnZlcnNhdGlvbmFsIHByb21wdHMg
dG8gdHJpZ2dlciBhZ2VudHMgbGlrZSBTaG9wcGluZyBBZ2VudC4KIFRoZXJlIG1heSBiZSBt
dWx0aXBsZSBwcm9tcHRzIGZvciBhIHNpbmdsZSBzdWdnZXN0aW9uLgoKIFRoaXMgaXMgYW4g
ZXhwZXJpbWVudGFsIGZlYXR1cmUgZm9yIHNlbGVjdCBjdXN0b21lcnMuCgoPCgcEAQMAAgQE
EgTUAQQMCg8KBwQBAwACBAYSBNQBDRgKDwoHBAEDAAIEARIE1AEZJgoPCgcEAQMAAgQDEgTU
ASkqCg8KBwQBAwACBAgSBNQBKz4KEAoIBAEDAAIECAMSBNQBLD0KOQoEBAEDARIG2AEC3QED
GikgRGVwcmVjYXRlZDogUmVjZW50IHNlYXJjaCBvZiB0aGlzIHVzZXIuCgoNCgUEAQMBARIE
2AEKHAoNCgUEAQMBBxIE2QEEHQoOCgYEAQMBBwMSBNkBBB0KKgoGBAEDAQIAEgTcAQQdGhog
VGhlIHJlY2VudCBzZWFyY2ggcXVlcnkuCgoPCgcEAQMBAgAFEgTcAQQKCg8KBwQBAwECAAES
BNwBCxgKDwoHBAEDAQIAAxIE3AEbHAo9CgQEAQMCEgbgAQLjAQMaLSBSZXNvdXJjZSB0aGF0
IHJlcHJlc2VudHMgYXR0cmlidXRlIHJlc3VsdHMuCgoNCgUEAQMCARIE4AEKGQo8CgYEAQMC
AgASBOIBBCQaLCBUaGUgbGlzdCBvZiBzdWdnZXN0aW9ucyBmb3IgdGhlIGF0dHJpYnV0ZS4K
Cg8KBwQBAwICAAQSBOIBBAwKDwoHBAEDAgIABRIE4gENEwoPCgcEAQMCAgABEgTiARQfCg8K
BwQBAwICAAMSBOIBIiMKUAoEBAEDAxIG5gEC6QEDGkAgQSBjb252ZXJzYXRpb25hbCBwcm9t
cHQgdG8gdHJpZ2dlciBhZ2VudHMgbGlrZSBTaG9wcGluZyBBZ2VudC4KCg0KBQQBAwMBEgTm
AQoVCjMKBgQBAwMCABIE6AEEFhojIFRoZSBjb252ZXJzYXRpb25hbCBwcm9tcHQgc3RyaW5n
LgoKDwoHBAEDAwIABRIE6AEECgoPCgcEAQMDAgABEgToAQsRCg8KBwQBAwMCAAMSBOgBFBUK
eAoEBAECABIE7QECMxpqIFJlc3VsdHMgb2YgdGhlIG1hdGNoaW5nIHN1Z2dlc3Rpb25zLiBU
aGUgcmVzdWx0IGxpc3QgaXMgb3JkZXJlZCBhbmQgdGhlCiBmaXJzdCByZXN1bHQgaXMgdG9w
IHN1Z2dlc3Rpb24uCgoNCgUEAQIABBIE7QECCgoNCgUEAQIABhIE7QELGwoNCgUEAQIAARIE
7QEcLgoNCgUEAQIAAxIE7QExMgqWAgoEBAECARIE8wECHxqHAiBBIHVuaXF1ZSBjb21wbGV0
ZSB0b2tlbi4gVGhpcyBzaG91bGQgYmUgaW5jbHVkZWQgaW4gdGhlCiBbVXNlckV2ZW50LmNv
bXBsZXRpb25fZGV0YWlsXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXNlckV2ZW50
LmNvbXBsZXRpb25fZGV0YWlsXQogZm9yIHNlYXJjaCBldmVudHMgcmVzdWx0aW5nIGZyb20g
dGhpcyBjb21wbGV0aW9uLCB3aGljaCBlbmFibGVzIGFjY3VyYXRlCiBhdHRyaWJ1dGlvbiBv
ZiBjb21wbGV0ZSBtb2RlbCBwZXJmb3JtYW5jZS4KCg0KBQQBAgEFEgTzAQIICg0KBQQBAgEB
EgTzAQkaCg0KBQQBAgEDEgTzAR0eCrIGCgQEAQICEgSKAgJMGqMGIERlcHJlY2F0ZWQuIE1h
dGNoZWQgcmVjZW50IHNlYXJjaGVzIG9mIHRoaXMgdXNlci4gVGhlIG1heGltdW0gbnVtYmVy
IG9mCiByZWNlbnQgc2VhcmNoZXMgaXMgMTAuIFRoaXMgZmllbGQgaXMgYSByZXN0cmljdGVk
IGZlYXR1cmUuIElmIHlvdSB3YW50IHRvCiBlbmFibGUgaXQsIGNvbnRhY3QgUmV0YWlsIFNl
YXJjaCBzdXBwb3J0LgoKIFRoaXMgZmVhdHVyZSBpcyBvbmx5IGF2YWlsYWJsZSB3aGVuCiBb
Q29tcGxldGVRdWVyeVJlcXVlc3QudmlzaXRvcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLkNvbXBsZXRlUXVlcnlSZXF1ZXN0LnZpc2l0b3JfaWRdCiBmaWVsZCBpcyBzZXQg
YW5kIFtVc2VyRXZlbnRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Vc2VyRXZlbnRd
IGlzCiBpbXBvcnRlZC4gVGhlIHJlY2VudCBzZWFyY2hlcyBzYXRpc2Z5IHRoZSBmb2xsb3cg
cnVsZXM6CgogICogVGhleSBhcmUgb3JkZXJlZCBmcm9tIGxhdGVzdCB0byBvbGRlc3QuCgog
ICogVGhleSBhcmUgbWF0Y2hlZCB3aXRoCiAgW0NvbXBsZXRlUXVlcnlSZXF1ZXN0LnF1ZXJ5
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29tcGxldGVRdWVyeVJlcXVlc3QucXVl
cnldCiAgY2FzZSBpbnNlbnNpdGl2ZWx5LgoKICAqIFRoZXkgYXJlIHRyYW5zZm9ybWVkIHRv
IGxvd2VyIGNhc2UuCgogICogVGhleSBhcmUgVVRGLTggc2FmZS4KCiBSZWNlbnQgc2VhcmNo
ZXMgYXJlIGRlZHVwbGljYXRlZC4gTW9yZSByZWNlbnQgc2VhcmNoZXMgd2lsbCBiZSByZXNl
cnZlZAogd2hlbiBkdXBsaWNhdGlvbiBoYXBwZW5zLgoKDQoFBAECAgQSBIoCAgoKDQoFBAEC
AgYSBIoCCx0KDQoFBAECAgESBIoCHjMKDQoFBAECAgMSBIoCNjcKDQoFBAECAggSBIoCOEsK
DgoGBAECAggDEgSKAjlKCqoBCgQEAQIDEgSUAgI1GpsBIEEgbWFwIG9mIG1hdGNoZWQgYXR0
cmlidXRlIHN1Z2dlc3Rpb25zLiBUaGlzIGZpZWxkIGlzIG9ubHkgYXZhaWxhYmxlIGZvcgog
YGNsb3VkLXJldGFpbGAgZGF0YXNldC4KCiBDdXJyZW50IHN1cHBvcnRlZCBrZXlzOgoKICog
YGJyYW5kc2AKCiAqIGBjYXRlZ29yaWVzYAoKDQoFBAECAwYSBJQCAh4KDQoFBAECAwESBJQC
HzAKDQoFBAECAwMSBJQCMzQKhQEKBAQBAgQSBJkCAikadyBDb252ZXJzYXRpb25hbCBwcm9t
cHRzIHRvIHRyaWdnZXIgYWdlbnRzIGxpa2UgU2hvcHBpbmcgQWdlbnQuCgogVGhpcyBpcyBh
biBleHBlcmltZW50YWwgZmVhdHVyZSBmb3Igc2VsZWN0IGN1c3RvbWVycy4KCg0KBQQBAgQE
EgSZAgIKCg0KBQQBAgQGEgSZAgsWCg0KBQQBAgQBEgSZAhckCg0KBQQBAgQDEgSZAicoYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest ===
    # Fields for CompleteQueryRequest
    # Field: catalog Type: 9 ()
    # Field: query Type: 9 ()
    # Field: visitor_id Type: 9 ()
    # Field: language_codes Type: 9 ()
    # Field: device_type Type: 9 ()
    # Field: dataset Type: 9 ()
    # Field: max_suggestions Type: 5 ()
    # Field: enable_attribute_suggestions Type: 8 ()
    # Field: entity Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: completion_results Type: 11 (.google.cloud.retail.v2alpha.CompleteQueryResponse.CompletionResult)
    # Field: attribution_token Type: 9 ()
    # Field: recent_search_results Type: 11 (.google.cloud.retail.v2alpha.CompleteQueryResponse.RecentSearchResult)
    # Field: attribute_results Type: 11 (.google.cloud.retail.v2alpha.CompleteQueryResponse.AttributeResultsEntry)
    # Field: agent_prompts Type: 11 (.google.cloud.retail.v2alpha.CompleteQueryResponse.AgentPrompt)

# === Service Client: Google::Cloud::Retail::V2alpha::CompletionService::CompletionServiceClient ===
package Google::Cloud::Retail::V2alpha::CompletionService::CompletionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::CompletionService::CompletionServiceClient

Client stub representing the remote C<CompletionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub complete_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.CompletionService',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse',
    });
}

sub import_completion_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ImportConfig::ImportCompletionDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.CompletionService',
        method         => 'ImportCompletionData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::CompletionService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::CompletionService;

    my $msg = Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest->new({
        catalog => $catalog,
        query => $query,
        visitor_id => $visitor_id,
        language_codes => $language_codes,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest

Autocomplete parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Catalog for which the completion is performed.

Full resource name of catalog, such as
`projects/*/locations/global/catalogs/default_catalog`.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The query used to generate suggestions.

The maximum number of allowed characters is 255.

=item * C<< $msg->visitor_id() >> / C<< $msg->visitor_id($value) >>

Type: C<String>

Recommended field. A unique identifier for tracking visitors. For example,
this could be implemented with an HTTP cookie, which should be able to
uniquely identify a visitor on a single device. This unique identifier
should not change if the visitor logs in or out of the website.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

Note that this field applies for `user-data` dataset only. For requests
with `cloud-retail` dataset, setting this field has no effect.

The language filters applied to the output suggestions. If set, it should
contain the language of the query. If not set, suggestions are returned
without considering language restrictions. This is the BCP-47 language
code, such as "en-US" or "sr-Latn". For more information, see [Tags for
Identifying Languages](https://tools.ietf.org/html/bcp47). The maximum
number of language codes is 3.

=item * C<< $msg->device_type() >> / C<< $msg->device_type($value) >>

Type: C<String>

The device type context for completion suggestions. We recommend that you
leave this field empty.

It can apply different suggestions on different device types, e.g.
`DESKTOP`, `MOBILE`. If it is empty, the suggestions are across all device
types.

Supported formats:

* `UNKNOWN_DEVICE_TYPE`

* `DESKTOP`

* `MOBILE`

* A customized string starts with `OTHER_`, e.g. `OTHER_IPHONE`.

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Determines which dataset to use for fetching completion. "user-data" will
use the dataset imported through
[CompletionService.ImportCompletionData][google.cloud.retail.v2alpha.CompletionService.ImportCompletionData].
`cloud-retail` will use the dataset generated by Cloud Retail based on user
events. If left empty, completions will be fetched from the `user-data`
dataset.

Current supported values:

* user-data

* cloud-retail:
  This option requires enabling auto-learning function first. See
  [guidelines](https://cloud.google.com/retail/docs/completion-overview#generated-completion-dataset).

=item * C<< $msg->max_suggestions() >> / C<< $msg->max_suggestions($value) >>

Type: C<Int32>

Completion max suggestions. If left unset or set to 0, then will fallback
to the configured value
[CompletionConfig.max_suggestions][google.cloud.retail.v2alpha.CompletionConfig.max_suggestions].

The maximum allowed max suggestions is 20. If it is set higher, it will be
capped by 20.

=item * C<< $msg->enable_attribute_suggestions() >> / C<< $msg->enable_attribute_suggestions($value) >>

Type: C<Bool>

If true, attribute suggestions are enabled and provided in the response.

This field is only available for the `cloud-retail` dataset.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<String>

The entity for customers who run multiple entities, domains, sites, or
regions, for example, `Google US`, `Google Ads`, `Waymo`,
`google.com`, `youtube.com`, etc.
If this is set, it must be an exact match with
[UserEvent.entity][google.cloud.retail.v2alpha.UserEvent.entity] to get
per-entity autocomplete results. This field will be applied to
`completion_results` only. It has no effect on the `attribute_results`.
Also, this entity should be limited to 256 characters, if too long, it will
be truncated to 256 characters in both generation and serving time, and may
lead to mis-match. To ensure it works, please set the entity with string
within 256 characters.

=back

=head2 Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse

Response of the autocomplete query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_results() >> / C<< $msg->completion_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse::CompletionResult>)

Results of the matching suggestions. The result list is ordered and the
first result is top suggestion.

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique complete token. This should be included in the
[UserEvent.completion_detail][google.cloud.retail.v2alpha.UserEvent.completion_detail]
for search events resulting from this completion, which enables accurate
attribution of complete model performance.

=item * C<< $msg->recent_search_results() >> / C<< $msg->recent_search_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse::RecentSearchResult>)

Deprecated. Matched recent searches of this user. The maximum number of
recent searches is 10. This field is a restricted feature. If you want to
enable it, contact Retail Search support.

This feature is only available when
[CompleteQueryRequest.visitor_id][google.cloud.retail.v2alpha.CompleteQueryRequest.visitor_id]
field is set and [UserEvent][google.cloud.retail.v2alpha.UserEvent] is
imported. The recent searches satisfy the follow rules:

 * They are ordered from latest to oldest.

 * They are matched with
 [CompleteQueryRequest.query][google.cloud.retail.v2alpha.CompleteQueryRequest.query]
 case insensitively.

 * They are transformed to lower case.

 * They are UTF-8 safe.

Recent searches are deduplicated. More recent searches will be reserved
when duplication happens.

=item * C<< $msg->attribute_results() >> / C<< $msg->attribute_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse::AttributeResultsEntry>)

A map of matched attribute suggestions. This field is only available for
`cloud-retail` dataset.

Current supported keys:

* `brands`

* `categories`

=item * C<< $msg->agent_prompts() >> / C<< $msg->agent_prompts($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse::AgentPrompt>)

Conversational prompts to trigger agents like Shopping Agent.

This is an experimental feature for select customers.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
