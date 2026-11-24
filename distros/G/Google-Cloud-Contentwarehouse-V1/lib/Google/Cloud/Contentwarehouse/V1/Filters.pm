package Google::Cloud::Contentwarehouse::V1::Filters;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9maWx0ZXJzLnByb3RvEiBnb29n
bGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxoaZ29vZ2xlL3R5cGUvaW50ZXJ2YWwucHJvdG8i6QUKDURvY3VtZW50UXVlcnkSFAoFcXVl
cnkYASABKAlSBXF1ZXJ5Eh4KC2lzX25sX3F1ZXJ5GAwgASgIUglpc05sUXVlcnkSOAoWY3Vz
dG9tX3Byb3BlcnR5X2ZpbHRlchgEIAEoCUICGAFSFGN1c3RvbVByb3BlcnR5RmlsdGVyEk8K
DHRpbWVfZmlsdGVycxgFIAMoCzIsLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYx
LlRpbWVGaWx0ZXJSC3RpbWVGaWx0ZXJzEjIKFWRvY3VtZW50X3NjaGVtYV9uYW1lcxgGIAMo
CVITZG9jdW1lbnRTY2hlbWFOYW1lcxJZCg9wcm9wZXJ0eV9maWx0ZXIYByADKAsyMC5nb29n
bGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Qcm9wZXJ0eUZpbHRlclIOcHJvcGVydHlG
aWx0ZXISWgoQZmlsZV90eXBlX2ZpbHRlchgIIAEoCzIwLmdvb2dsZS5jbG91ZC5jb250ZW50
d2FyZWhvdXNlLnYxLkZpbGVUeXBlRmlsdGVyUg5maWxlVHlwZUZpbHRlchIsChJmb2xkZXJf
bmFtZV9maWx0ZXIYCSABKAlSEGZvbGRlck5hbWVGaWx0ZXISMAoUZG9jdW1lbnRfbmFtZV9m
aWx0ZXIYDiADKAlSEmRvY3VtZW50TmFtZUZpbHRlchIjCg1xdWVyeV9jb250ZXh0GAogAygJ
UgxxdWVyeUNvbnRleHQSNgoXZG9jdW1lbnRfY3JlYXRvcl9maWx0ZXIYCyADKAlSFWRvY3Vt
ZW50Q3JlYXRvckZpbHRlchJvChdjdXN0b21fd2VpZ2h0c19tZXRhZGF0YRgNIAEoCzI3Lmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkN1c3RvbVdlaWdodHNNZXRhZGF0YVIV
Y3VzdG9tV2VpZ2h0c01ldGFkYXRhIvoBCgpUaW1lRmlsdGVyEjQKCnRpbWVfcmFuZ2UYASAB
KAsyFS5nb29nbGUudHlwZS5JbnRlcnZhbFIJdGltZVJhbmdlElUKCnRpbWVfZmllbGQYAiAB
KA4yNi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5UaW1lRmlsdGVyLlRpbWVG
aWVsZFIJdGltZUZpZWxkIl8KCVRpbWVGaWVsZBIaChZUSU1FX0ZJRUxEX1VOU1BFQ0lGSUVE
EAASDwoLQ1JFQVRFX1RJTUUQARIPCgtVUERBVEVfVElNRRACEhQKEERJU1BPU0lUSU9OX1RJ
TUUQAyKVAQoOUHJvcGVydHlGaWx0ZXISZQoUZG9jdW1lbnRfc2NoZW1hX25hbWUYASABKAlC
M/pBMAouY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudFNjaGVtYVIS
ZG9jdW1lbnRTY2hlbWFOYW1lEhwKCWNvbmRpdGlvbhgCIAEoCVIJY29uZGl0aW9uIsMBCg5G
aWxlVHlwZUZpbHRlchJWCglmaWxlX3R5cGUYASABKA4yOS5nb29nbGUuY2xvdWQuY29udGVu
dHdhcmVob3VzZS52MS5GaWxlVHlwZUZpbHRlci5GaWxlVHlwZVIIZmlsZVR5cGUiWQoIRmls
ZVR5cGUSGQoVRklMRV9UWVBFX1VOU1BFQ0lGSUVEEAASBwoDQUxMEAESCgoGRk9MREVSEAIS
DAoIRE9DVU1FTlQQAxIPCgtST09UX0ZPTERFUhAEIo8BChVDdXN0b21XZWlnaHRzTWV0YWRh
dGESdgoad2VpZ2h0ZWRfc2NoZW1hX3Byb3BlcnRpZXMYASADKAsyOC5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MS5XZWlnaHRlZFNjaGVtYVByb3BlcnR5Uhh3ZWlnaHRlZFNj
aGVtYVByb3BlcnRpZXMipgEKFldlaWdodGVkU2NoZW1hUHJvcGVydHkSZQoUZG9jdW1lbnRf
c2NoZW1hX25hbWUYASABKAlCM/pBMAouY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNv
bS9Eb2N1bWVudFNjaGVtYVISZG9jdW1lbnRTY2hlbWFOYW1lEiUKDnByb3BlcnR5X25hbWVz
GAIgAygJUg1wcm9wZXJ0eU5hbWVzQvQBCiRjb20uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJl
aG91c2UudjFCDEZpbHRlcnNQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2NvbnRlbnR3
YXJlaG91c2UvYXBpdjEvY29udGVudHdhcmVob3VzZXBiO2NvbnRlbnR3YXJlaG91c2VwYqoC
IEdvb2dsZS5DbG91ZC5Db250ZW50V2FyZWhvdXNlLlYxygIgR29vZ2xlXENsb3VkXENvbnRl
bnRXYXJlaG91c2VcVjHqAiNHb29nbGU6OkNsb3VkOjpDb250ZW50V2FyZWhvdXNlOjpWMUr5
WQoHEgUOAKECAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
KQoJCgIDABIDEgAjCgkKAgMBEgMTACQKCAoBCBIDFQA9CgkKAgglEgMVAD0KCAoBCBIDFgBn
CgkKAggLEgMWAGcKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAtCgkKAggIEgMYAC0K
CAoBCBIDGQA9CgkKAggBEgMZAD0KCAoBCBIDGgA9CgkKAggpEgMaAD0KCAoBCBIDGwA8CgkK
AggtEgMbADwKCwoCBAASBR0AqAEBCgoKAwQAARIDHQgVCr4PCgQEAAIAEgNKAhMasA8gVGhl
IHF1ZXJ5IHN0cmluZyB0aGF0IG1hdGNoZXMgYWdhaW5zdCB0aGUgZnVsbCB0ZXh0IG9mIHRo
ZSBkb2N1bWVudCBhbmQKIHRoZSBzZWFyY2hhYmxlIHByb3BlcnRpZXMuCgogVGhlIHF1ZXJ5
IHBhcnRpYWxseSBzdXBwb3J0cyBbR29vZ2xlIEFJUCBzdHlsZQogc3ludGF4XShodHRwczov
L2dvb2dsZS5haXAuZGV2LzE2MCkuIFNwZWNpZmljYWxseSwgdGhlIHF1ZXJ5IHN1cHBvcnRz
CiBsaXRlcmFscywgbG9naWNhbCBvcGVyYXRvcnMsIG5lZ2F0aW9uIG9wZXJhdG9ycywgY29t
cGFyaXNvbiBvcGVyYXRvcnMsIGFuZAogZnVuY3Rpb25zLgoKIExpdGVyYWxzOiBBIGJhcmUg
bGl0ZXJhbCB2YWx1ZSAoZXhhbXBsZXM6ICI0MiIsICJIdWdvIikgaXMgYSB2YWx1ZSB0byBi
ZQogbWF0Y2hlZCBhZ2FpbnN0LiBJdCBzZWFyY2hlcyBvdmVyIHRoZSBmdWxsIHRleHQgb2Yg
dGhlIGRvY3VtZW50IGFuZCB0aGUKIHNlYXJjaGFibGUgcHJvcGVydGllcy4KCiBMb2dpY2Fs
IG9wZXJhdG9yczogIkFORCIsICJhbmQiLCAiT1IiLCBhbmQgIm9yIiBhcmUgYmluYXJ5IGxv
Z2ljYWwKIG9wZXJhdG9ycyAoZXhhbXBsZTogImVuZ2luZWVyIE9SIGRldmVsb3BlciIpLgoK
IE5lZ2F0aW9uIG9wZXJhdG9yczogIk5PVCIgYW5kICIhIiBhcmUgbmVnYXRpb24gb3BlcmF0
b3JzIChleGFtcGxlOiAiTk9UCiBzb2Z0d2FyZSIpLgoKIENvbXBhcmlzb24gb3BlcmF0b3Jz
OiBzdXBwb3J0IHRoZSBiaW5hcnkgY29tcGFyaXNvbiBvcGVyYXRvcnMgPSwgIT0sIDwsID4s
CiA8PSBhbmQgPj0gZm9yIHN0cmluZywgbnVtZXJpYywgZW51bSwgYm9vbGVhbi4gQWxzbyBz
dXBwb3J0IGxpa2Ugb3BlcmF0b3IKIGB+fmAgZm9yIHN0cmluZy4gSXQgcHJvdmlkZXMgc2Vt
YW50aWMgc2VhcmNoIGZ1bmN0aW9uYWxpdHkgYnkgcGFyc2luZywKIHN0ZW1taW5nIGFuZCBk
b2luZyBzeW5vbnltcyBleHBhbnNpb24gYWdhaW5zdCB0aGUgaW5wdXQgcXVlcnkuCgogVG8g
c3BlY2lmeSBhIHByb3BlcnR5IGluIHRoZSBxdWVyeSwgdGhlIGxlZnQgaGFuZCBzaWRlIGV4
cHJlc3Npb24gaW4gdGhlCiBjb21wYXJpc29uIG11c3QgYmUgdGhlIHByb3BlcnR5IElEIGlu
Y2x1ZGluZyB0aGUgcGFyZW50LiBUaGUgcmlnaHQgaGFuZAogc2lkZSBtdXN0IGJlIGxpdGVy
YWxzLiBGb3IgZXhhbXBsZToKICJcInByb2plY3RzLzEyMy9sb2NhdGlvbnMvdXNcIi5wcm9w
ZXJ0eV9hIDwgMSIgbWF0Y2hlcyByZXN1bHRzIHdob3NlCiAicHJvcGVydHlfYSIgaXMgbGVz
cyB0aGFuIDEgaW4gcHJvamVjdCAxMjMgYW5kIHVzIGxvY2F0aW9uLgogVGhlIGxpdGVyYWxz
IGFuZCBjb21wYXJpc29uIGV4cHJlc3Npb24gY2FuIGJlIGNvbm5lY3RlZCBpbiBhIHNpbmds
ZSBxdWVyeQogKGV4YW1wbGU6ICJzb2Z0d2FyZSBlbmdpbmVlciBcInByb2plY3RzLzEyMy9s
b2NhdGlvbnMvdXNcIi5zYWxhcnkgPiAxMDAiKS4KCiBGdW5jdGlvbnM6IHN1cHBvcnRlZCBm
dW5jdGlvbnMgYXJlIGBMT1dFUihbcHJvcGVydHlfbmFtZV0pYCB0byBwZXJmb3JtIGEKIGNh
c2UgaW5zZW5zaXRpdmUgbWF0Y2ggYW5kIGBFTVBUWShbcHJvcGVydHlfbmFtZV0pYCB0byBm
aWx0ZXIgb24gdGhlCiBleGlzdGVuY2Ugb2YgYSBrZXkuCgogU3VwcG9ydCBuZXN0ZWQgZXhw
cmVzc2lvbnMgY29ubmVjdGVkIHVzaW5nIHBhcmVudGhlc2lzIGFuZCBsb2dpY2FsCiBvcGVy
YXRvcnMuIFRoZSBkZWZhdWx0IGxvZ2ljYWwgb3BlcmF0b3JzIGlzIGBBTkRgIGlmIHRoZXJl
IGlzIG5vIG9wZXJhdG9ycwogYmV0d2VlbiBleHByZXNzaW9ucy4KCiBUaGUgcXVlcnkgY2Fu
IGJlIHVzZWQgd2l0aCBvdGhlciBmaWx0ZXJzIGUuZy4gYHRpbWVfZmlsdGVyc2AgYW5kCiBg
Zm9sZGVyX25hbWVfZmlsdGVyYC4gVGhleSBhcmUgY29ubmVjdGVkIHdpdGggYEFORGAgb3Bl
cmF0b3IgdW5kZXIgdGhlCiBob29kLgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2Vk
IGNoYXJhY3RlcnMgaXMgMjU1LgoKDAoFBAACAAUSA0oCCAoMCgUEAAIAARIDSgkOCgwKBQQA
AgADEgNKERIKlgMKBAQAAgESA1MCGBqIAyBFeHBlcmltZW50YWwsIGRvIG5vdCB1c2UuCiBJ
ZiB0aGUgcXVlcnkgaXMgYSBuYXR1cmFsIGxhbmd1YWdlIHF1ZXN0aW9uLiBGYWxzZSBieSBk
ZWZhdWx0LiBJZiB0cnVlLAogdGhlbiB0aGUgcXVlc3Rpb24tYW5zd2VyaW5nIGZlYXR1cmUg
d2lsbCBiZSB1c2VkIGluc3RlYWQgb2Ygc2VhcmNoLCBhbmQKIGByZXN1bHRfY291bnRgIGlu
CiBbU2VhcmNoRG9jdW1lbnRzUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91
c2UudjEuU2VhcmNoRG9jdW1lbnRzUmVxdWVzdF0KIG11c3QgYmUgc2V0LiBJbiBhZGRpdGlv
biwgYWxsIG90aGVyIGlucHV0IGZpZWxkcyByZWxhdGVkIHRvIHNlYXJjaAogKHBhZ2luYXRp
b24sIGhpc3RvZ3JhbXMsIGV0Yy4pIHdpbGwgYmUgaWdub3JlZC4KCgwKBQQAAgEFEgNTAgYK
DAoFBAACAQESA1MHEgoMCgUEAAIBAxIDUxUXCq0HCgQEAAICEgNoAjganwcgVGhpcyBmaWx0
ZXIgc3BlY2lmaWVzIGEgc3RydWN0dXJlZCBzeW50YXggdG8gbWF0Y2ggYWdhaW5zdCB0aGUK
IFtQcm9wZXJ0eURlZmluaXRpb25dLltpc19maWx0ZXJhYmxlXVtdIG1hcmtlZCBhcyBgdHJ1
ZWAuIFRoZSBzeW50YXggZm9yCiB0aGlzIGV4cHJlc3Npb24gaXMgYSBzdWJzZXQgb2YgU1FM
IHN5bnRheC4KCiBTdXBwb3J0ZWQgb3BlcmF0b3JzIGFyZTogYD1gLCBgIT1gLCBgPGAsIGA8
PWAsIGA+YCwgYW5kIGA+PWAgd2hlcmUgdGhlIGxlZnQKIG9mIHRoZSBvcGVyYXRvciBpcyBh
IHByb3BlcnR5IG5hbWUgYW5kIHRoZSByaWdodCBvZiB0aGUgb3BlcmF0b3IgaXMgYQogbnVt
YmVyIG9yIGEgcXVvdGVkIHN0cmluZy4gWW91IG11c3QgZXNjYXBlIGJhY2tzbGFzaCAoXFwp
IGFuZCBxdW90ZSAoXCIpCiBjaGFyYWN0ZXJzLiBTdXBwb3J0ZWQgZnVuY3Rpb25zIGFyZSBg
TE9XRVIoW3Byb3BlcnR5X25hbWVdKWAgdG8gcGVyZm9ybSBhCiBjYXNlIGluc2Vuc2l0aXZl
IG1hdGNoIGFuZCBgRU1QVFkoW3Byb3BlcnR5X25hbWVdKWAgdG8gZmlsdGVyIG9uIHRoZQog
ZXhpc3RlbmNlIG9mIGEga2V5LgoKIEJvb2xlYW4gZXhwcmVzc2lvbnMgKEFORC9PUi9OT1Qp
IGFyZSBzdXBwb3J0ZWQgdXAgdG8gMyBsZXZlbHMgb2YgbmVzdGluZwogKGZvciBleGFtcGxl
LCAiKChBIEFORCBCIEFORCBDKSBPUiBOT1QgRCkgQU5EIEUiKSwgYSBtYXhpbXVtIG9mIDEw
MAogY29tcGFyaXNvbnMgb3IgZnVuY3Rpb25zIGFyZSBhbGxvd2VkIGluIHRoZSBleHByZXNz
aW9uLiBUaGUgZXhwcmVzc2lvbiBtdXN0CiBiZSA8IDYwMDAgYnl0ZXMgaW4gbGVuZ3RoLgoK
IFNhbXBsZSBRdWVyeToKIGAoTE9XRVIoZHJpdmluZ19saWNlbnNlKT0iY2xhc3MgXCJhXCIi
IE9SIEVNUFRZKGRyaXZpbmdfbGljZW5zZSkpIEFORAogZHJpdmluZ195ZWFycyA+IDEwYAoK
DAoFBAACAgUSA2gCCAoMCgUEAAICARIDaAkfCgwKBQQAAgIDEgNoIiMKDAoFBAACAggSA2gk
NwoNCgYEAAICCAMSA2glNgpnCgQEAAIDEgNsAicaWiBEb2N1bWVudHMgY3JlYXRlZC91cGRh
dGVkIHdpdGhpbiBhIHJhbmdlIHNwZWNpZmllZCBieSB0aGlzIGZpbHRlciBhcmUKIHNlYXJj
aGVkIGFnYWluc3QuCgoMCgUEAAIDBBIDbAIKCgwKBQQAAgMGEgNsCxUKDAoFBAACAwESA2wW
IgoMCgUEAAIDAxIDbCUmCtUDCgQEAAIEEgN4AiwaxwMgVGhpcyBmaWx0ZXIgc3BlY2lmaWVz
IHRoZSBleGFjdCBkb2N1bWVudCBzY2hlbWEKIFtEb2N1bWVudC5kb2N1bWVudF9zY2hlbWFf
bmFtZV1bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9jdW1lbnQuZG9jdW1l
bnRfc2NoZW1hX25hbWVdCiBvZiB0aGUgZG9jdW1lbnRzIHRvIHNlYXJjaCBhZ2FpbnN0LgoK
IElmIGEgdmFsdWUgaXNuJ3Qgc3BlY2lmaWVkLCBkb2N1bWVudHMgd2l0aGluIHRoZSBzZWFy
Y2ggcmVzdWx0cyBhcmUKIGFzc29jaWF0ZWQgd2l0aCBhbnkgc2NoZW1hLiBJZiBtdWx0aXBs
ZSB2YWx1ZXMgYXJlIHNwZWNpZmllZCwgZG9jdW1lbnRzCiB3aXRoaW4gdGhlIHNlYXJjaCBy
ZXN1bHRzIG1heSBiZSBhc3NvY2lhdGVkIHdpdGggYW55IG9mIHRoZSBzcGVjaWZpZWQKIHNj
aGVtYXMuCgogQXQgbW9zdCAyMCBkb2N1bWVudCBzY2hlbWEgbmFtZXMgYXJlIGFsbG93ZWQu
CgoMCgUEAAIEBBIDeAIKCgwKBQQAAgQFEgN4CxEKDAoFBAACBAESA3gSJwoMCgUEAAIEAxID
eCorCvwBCgQEAAIFEgN9Ai4a7gEgVGhpcyBmaWx0ZXIgc3BlY2lmaWVzIGEgc3RydWN0dXJl
ZCBzeW50YXggdG8gbWF0Y2ggYWdhaW5zdCB0aGUKIFtQcm9wZXJ0eURlZmluaXRpb24uaXNf
ZmlsdGVyYWJsZV1bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUHJvcGVydHlE
ZWZpbml0aW9uLmlzX2ZpbHRlcmFibGVdCiBtYXJrZWQgYXMgYHRydWVgLiBUaGUgcmVsYXRp
b25zaGlwIGJldHdlZW4gdGhlIFByb3BlcnR5RmlsdGVycyBpcyBPUi4KCgwKBQQAAgUEEgN9
AgoKDAoFBAACBQYSA30LGQoMCgUEAAIFARIDfRopCgwKBQQAAgUDEgN9LC0KtQIKBAQAAgYS
BIUBAiYapgIgVGhpcyBmaWx0ZXIgc3BlY2lmaWVzIHRoZSB0eXBlcyBvZiBmaWxlcyB0byBy
ZXR1cm46IEFMTCwgRk9MREVSLCBvciBGSUxFLgogSWYgRk9MREVSIG9yIEZJTEUgaXMgc3Bl
Y2lmaWVkLCB0aGVuIG9ubHkgZWl0aGVyIGZvbGRlcnMgb3IgZmlsZXMgd2lsbCBiZQogcmV0
dXJuZWQsIHJlc3BlY3RpdmVseS4gSWYgQUxMIGlzIHNwZWNpZmllZCwgYm90aCBmb2xkZXJz
IGFuZCBmaWxlcyB3aWxsIGJlCiByZXR1cm5lZC4KCiBJZiBubyB2YWx1ZSBpcyBzcGVjaWZp
ZWQsIEFMTCBmaWxlcyB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAACBgYSBIUBAhAKDQoFBAAC
BgESBIUBESEKDQoFBAACBgMSBIUBJCUKmAEKBAQAAgcSBIoBAiAaiQEgU2VhcmNoIGFsbCB0
aGUgZG9jdW1lbnRzIHVuZGVyIHRoaXMgc3BlY2lmaWVkIGZvbGRlci4KIEZvcm1hdDoKIHBy
b2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRz
L3tkb2N1bWVudF9pZH0uCgoNCgUEAAIHBRIEigECCAoNCgUEAAIHARIEigEJGwoNCgUEAAIH
AxIEigEeHwqDAQoEBAACCBIEjwECLBp1IFNlYXJjaCB0aGUgZG9jdW1lbnRzIGluIHRoZSBs
aXN0LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9kb2N1bWVudHMve2RvY3VtZW50X2lkfS4KCg0KBQQAAggEEgSPAQIKCg0KBQQA
AggFEgSPAQsRCg0KBQQAAggBEgSPARImCg0KBQQAAggDEgSPASkrCoUDCgQEAAIJEgSYAQIl
GvYCIEZvciBjdXN0b20gc3lub255bXMuCiBDdXN0b21lcnMgcHJvdmlkZSB0aGUgc3lub255
bXMgYmFzZWQgb24gY29udGV4dC4gT25lIGN1c3RvbWVyIGNhbiBwcm92aWRlCiBtdWx0aXBs
ZSBzZXQgb2Ygc3lub255bXMgYmFzZWQgb24gZGlmZmVyZW50IGNvbnRleHQuIFRoZSBzZWFy
Y2ggcXVlcnkgd2lsbAogYmUgZXhwYW5kZWQgYmFzZWQgb24gdGhlIGN1c3RvbSBzeW5vbnlt
cyBvZiB0aGUgcXVlcnkgY29udGV4dCBzZXQuCiBCeSBkZWZhdWx0LCBubyBjdXN0b20gc3lu
b255bXMgd2xsIGJlIGFwcGxpZWQgaWYgbm8gcXVlcnkgY29udGV4dCBpcwogcHJvdmlkZWQu
CiBJdCBpcyBub3Qgc3VwcG9ydGVkIGZvciBDTUVLIGNvbXBsaWFudCBkZXBsb3ltZW50LgoK
DQoFBAACCQQSBJgBAgoKDQoFBAACCQUSBJgBCxEKDQoFBAACCQESBJgBEh8KDQoFBAACCQMS
BJgBIiQKqwIKBAQAAgoSBKABAi8anAIgVGhlIGV4YWN0IGNyZWF0b3Iocykgb2YgdGhlIGRv
Y3VtZW50cyB0byBzZWFyY2ggYWdhaW5zdC4KCiBJZiBhIHZhbHVlIGlzbid0IHNwZWNpZmll
ZCwgZG9jdW1lbnRzIHdpdGhpbiB0aGUgc2VhcmNoIHJlc3VsdHMgYXJlCiBhc3NvY2lhdGVk
IHdpdGggYW55IGNyZWF0b3IuIElmIG11bHRpcGxlIHZhbHVlcyBhcmUgc3BlY2lmaWVkLCBk
b2N1bWVudHMKIHdpdGhpbiB0aGUgc2VhcmNoIHJlc3VsdHMgbWF5IGJlIGFzc29jaWF0ZWQg
d2l0aCBhbnkgb2YgdGhlIHNwZWNpZmllZAogY3JlYXRvcnMuCgoNCgUEAAIKBBIEoAECCgoN
CgUEAAIKBRIEoAELEQoNCgUEAAIKARIEoAESKQoNCgUEAAIKAxIEoAEsLgrEAgoEBAACCxIE
pwECNRq1AiBUbyBzdXBwb3J0IHRoZSBjdXN0b20gd2VpZ2h0aW5nIGFjcm9zcyBkb2N1bWVu
dCBzY2hlbWFzLCBjdXN0b21lcnMgbmVlZCB0bwogcHJvdmlkZSB0aGUgcHJvcGVydGllcyB0
byBiZSB1c2VkIHRvIGJvb3N0IHRoZSByYW5raW5nIGluIHRoZSBzZWFyY2gKIHJlcXVlc3Qu
IEZvciBhIHNlYXJjaCBxdWVyeSB3aXRoIEN1c3RvbVdlaWdodHNNZXRhZGF0YSBzcGVjaWZp
ZWQsIG9ubHkgdGhlCiBSZXRyaWV2YWxJbXBvcnRhbmNlIGZvciB0aGUgcHJvcGVydGllcyBp
biB0aGUgQ3VzdG9tV2VpZ2h0c01ldGFkYXRhIHdpbGwKIGJlIGhvbm9yZWQuCgoNCgUEAAIL
BhIEpwECFwoNCgUEAAILARIEpwEYLwoNCgUEAAILAxIEpwEyNApMCgIEARIGqwEAwQEBGj4g
RmlsdGVyIG9uIGNyZWF0ZSB0aW1lc3RhbXAgb3IgdXBkYXRlIHRpbWVzdGFtcCBvZiBkb2N1
bWVudHMuCgoLCgMEAQESBKsBCBIKMAoEBAEEABIGrQECuQEDGiAgVGltZSBmaWVsZCB1c2Vk
IGluIFRpbWVGaWx0ZXIuCgoNCgUEAQQAARIErQEHEAogCgYEAQQAAgASBK8BBB8aECBEZWZh
dWx0IHZhbHVlLgoKDwoHBAEEAAIAARIErwEEGgoPCgcEAQQAAgACEgSvAR0eCjAKBgQBBAAC
ARIEsgEEFBogIEVhcmxpZXN0IGRvY3VtZW50IGNyZWF0ZSB0aW1lLgoKDwoHBAEEAAIBARIE
sgEEDwoPCgcEAQQAAgECEgSyARITCi4KBgQBBAACAhIEtQEEFBoeIExhdGVzdCBkb2N1bWVu
dCB1cGRhdGUgdGltZS4KCg8KBwQBBAACAgESBLUBBA8KDwoHBAEEAAICAhIEtQESEwo7CgYE
AQQAAgMSBLgBBBkaKyBUaW1lIHdoZW4gZG9jdW1lbnQgYmVjb21lcyBtdXRhYmxlIGFnYWlu
LgoKDwoHBAEEAAIDARIEuAEEFAoPCgcEAQQAAgMCEgS4ARcYCgwKBAQBAgASBLsBAiYKDQoF
BAECAAYSBLsBAhYKDQoFBAECAAESBLsBFyEKDQoFBAECAAMSBLsBJCUKawoEBAECARIEwAEC
GxpdIFNwZWNpZmllcyB3aGljaCB0aW1lIGZpZWxkIHRvIGZpbHRlciBkb2N1bWVudHMgb24u
CgogRGVmYXVsdHMgdG8gW1RpbWVGaWVsZC5VUExPQURfVElNRV1bXS4KCg0KBQQBAgEGEgTA
AQILCg0KBQQBAgEBEgTAAQwWCg0KBQQBAgEDEgTAARkaCgwKAgQCEgbDAQD3AQEKCwoDBAIB
EgTDAQgWCuwBCgQEAgIAEgbIAQLKAQUa2wEgVGhlIERvY3VtZW50IHNjaGVtYSBuYW1lCiBb
RG9jdW1lbnQuZG9jdW1lbnRfc2NoZW1hX25hbWVdW2dvb2dsZS5jbG91ZC5jb250ZW50d2Fy
ZWhvdXNlLnYxLkRvY3VtZW50LmRvY3VtZW50X3NjaGVtYV9uYW1lXS4KIEZvcm1hdDoKIHBy
b2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRT
Y2hlbWFzL3tkb2N1bWVudF9zY2hlbWFfaWR9LgoKDQoFBAICAAUSBMgBAggKDQoFBAICAAES
BMgBCR0KDQoFBAICAAMSBMgBICEKDwoFBAICAAgSBsgBIsoBBAoRCgcEAgIACJ8IEgbIASPK
AQMKhQ8KBAQCAgESBPYBAhca9g4gVGhlIGZpbHRlciBjb25kaXRpb24uCiBUaGUgc3ludGF4
IGZvciB0aGlzIGV4cHJlc3Npb24gaXMgYSBzdWJzZXQgb2YgU1FMIHN5bnRheC4KCiBTdXBw
b3J0ZWQgb3BlcmF0b3JzIGFyZTogYD1gLCBgIT1gLCBgPGAsIGA8PWAsIGA+YCwgYD49YCwg
YW5kIGB+fmAgd2hlcmUKIHRoZSBsZWZ0IG9mIHRoZSBvcGVyYXRvciBpcyBhIHByb3BlcnR5
IG5hbWUgYW5kIHRoZSByaWdodCBvZiB0aGUgb3BlcmF0b3IKIGlzIGEgbnVtYmVyIG9yIGEg
cXVvdGVkIHN0cmluZy4gWW91IG11c3QgZXNjYXBlIGJhY2tzbGFzaCAoXFwpIGFuZCBxdW90
ZQogKFwiKSBjaGFyYWN0ZXJzLgoKIGB+fmAgaXMgdGhlIExJS0Ugb3BlcmF0b3IuIFRoZSBy
aWdodCBvZiB0aGUgb3BlcmF0b3IgbXVzdCBiZSBhIHN0cmluZy4gVGhlCiBvbmx5IHN1cHBv
cnRlZCBwcm9wZXJ0eSBkYXRhIHR5cGUgZm9yIExJS0UgaXMgdGV4dF92YWx1ZXMuIEl0IHBy
b3ZpZGVzCiBzZW1hbnRpYyBzZWFyY2ggZnVuY3Rpb25hbGl0eSBieSBwYXJzaW5nLCBzdGVt
bWluZyBhbmQgZG9pbmcgc3lub255bXMKIGV4cGFuc2lvbiBhZ2FpbnN0IHRoZSBpbnB1dCBx
dWVyeS4gSXQgbWF0Y2hlcyBpZiB0aGUgcHJvcGVydHkgY29udGFpbnMKIHNlbWFudGljIHNp
bWlsYXIgY29udGVudCB0byB0aGUgcXVlcnkuIEl0IGlzIG5vdCByZWdleCBtYXRjaGluZyBv
ciB3aWxkY2FyZAogbWF0Y2hpbmcuIEZvciBleGFtcGxlLCAicHJvcGVydHkuY29tcGFueSB+
fiBcImdvb2dsZVwiIiB3aWxsIG1hdGNoIHJlY29yZHMKIHdob3NlIHByb3BlcnR5IGBwcm9w
ZXJ0eS5jb21wbmF5YCBoYXZlIHZhbHVlcyBsaWtlICJHb29nbGUgSW5jLiIsICJHb29nbGUK
IExMQyIgb3IgIkdvb2dsZSBDb21wYW55Ii4KCiBTdXBwb3J0ZWQgZnVuY3Rpb25zIGFyZSBg
TE9XRVIoW3Byb3BlcnR5X25hbWVdKWAgdG8gcGVyZm9ybSBhCiBjYXNlIGluc2Vuc2l0aXZl
IG1hdGNoIGFuZCBgRU1QVFkoW3Byb3BlcnR5X25hbWVdKWAgdG8gZmlsdGVyIG9uIHRoZQog
ZXhpc3RlbmNlIG9mIGEga2V5LgoKIEJvb2xlYW4gZXhwcmVzc2lvbnMgKEFORC9PUi9OT1Qp
IGFyZSBzdXBwb3J0ZWQgdXAgdG8gMyBsZXZlbHMgb2YgbmVzdGluZwogKGZvciBleGFtcGxl
LCAiKChBIEFORCBCIEFORCBDKSBPUiBOT1QgRCkgQU5EIEUiKSwgYSBtYXhpbXVtIG9mIDEw
MAogY29tcGFyaXNvbnMgb3IgZnVuY3Rpb25zIGFyZSBhbGxvd2VkIGluIHRoZSBleHByZXNz
aW9uLiBUaGUgZXhwcmVzc2lvbiBtdXN0CiBiZSA8IDYwMDAgYnl0ZXMgaW4gbGVuZ3RoLgoK
IE9ubHkgcHJvcGVydGllcyB0aGF0IGFyZSBtYXJrZWQgZmlsdGVyYWJsZSBhcmUgYWxsb3dl
ZAogKFtQcm9wZXJ0eURlZmluaXRpb24uaXNfZmlsdGVyYWJsZV1bZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjEuUHJvcGVydHlEZWZpbml0aW9uLmlzX2ZpbHRlcmFibGVdKS4K
IFByb3BlcnR5IG5hbWVzIGRvIG5vdCBuZWVkIHRvIGJlIHByZWZpeGVkIGJ5IHRoZSBkb2N1
bWVudCBzY2hlbWEgaWQgKGFzIGlzCiB0aGUgY2FzZSB3aXRoIGhpc3RvZ3JhbXMpLCBob3dl
dmVyIHByb3BlcnR5IG5hbWVzIHdpbGwgbmVlZCB0byBiZSBwcmVmaXhlZAogYnkgaXRzIHBh
cmVudCBoaWVyYXJjaHksIGlmIGFueS4gIEZvciBleGFtcGxlOgogdG9wX3Byb3BlcnR5X25h
bWUuc3ViX3Byb3BlcnR5X25hbWUuCgogU2FtcGxlIFF1ZXJ5OgogYChMT1dFUihkcml2aW5n
X2xpY2Vuc2UpPSJjbGFzcyBcImFcIiIgT1IgRU1QVFkoZHJpdmluZ19saWNlbnNlKSkgQU5E
CiBkcml2aW5nX3llYXJzID4gMTBgCgoKIENNRUsgY29tcGxpYW50IGRlcGxveW1lbnQgb25s
eSBzdXBwb3J0czoKCiAqIE9wZXJhdG9yczogYD1gLCBgPGAsIGA8PWAsIGA+YCwgYW5kIGA+
PWAuCiAqIEJvb2xlYW4gZXhwcmVzc2lvbnM6IEFORCBhbmQgT1IuCgoNCgUEAgIBBRIE9gEC
CAoNCgUEAgIBARIE9gEJEgoNCgUEAgIBAxIE9gEVFgpECgIEAxIG+gEAjwIBGjYgRmlsdGVy
IGZvciB0aGUgc3BlY2lmaWMgdHlwZXMgb2YgZG9jdW1lbnRzIHJldHVybmVkLgoKCwoDBAMB
EgT6AQgWCjcKBAQDBAASBvwBAosCAxonIFJlcHJlc2VudGF0aW9uIG9mIHRoZSB0eXBlcyBv
ZiBmaWxlcy4KCg0KBQQDBAABEgT8AQcPCkUKBgQDBAACABIE/gEEHho1IERlZmF1bHQgZG9j
dW1lbnQgdHlwZS4gSWYgc2V0LCBkaXNhYmxlcyB0aGUgZmlsdGVyLgoKDwoHBAMEAAIAARIE
/gEEGQoPCgcEAwQAAgACEgT+ARwdCkAKBgQDBAACARIEgQIEDBowIFJldHVybnMgYWxsIGRv
Y3VtZW50IHR5cGVzLCBpbmNsdWRpbmcgZm9sZGVycy4KCg8KBwQDBAACAQESBIECBAcKDwoH
BAMEAAIBAhIEgQIKCwonCgYEAwQAAgISBIQCBA8aFyBSZXR1cm5zIG9ubHkgZm9sZGVycy4K
Cg8KBwQDBAACAgESBIQCBAoKDwoHBAMEAAICAhIEhAINDgo0CgYEAwQAAgMSBIcCBBEaJCBS
ZXR1cm5zIG9ubHkgbm9uLWZvbGRlciBkb2N1bWVudHMuCgoPCgcEAwQAAgMBEgSHAgQMCg8K
BwQDBAACAwISBIcCDxAKKwoGBAMEAAIEEgSKAgQUGhsgUmV0dXJucyBvbmx5IHJvb3QgZm9s
ZGVycwoKDwoHBAMEAAIEARIEigIEDwoPCgcEAwQAAgQCEgSKAhITCiwKBAQDAgASBI4CAhka
HiBUaGUgdHlwZSBvZiBmaWxlcyB0byByZXR1cm4uCgoNCgUEAwIABhIEjgICCgoNCgUEAwIA
ARIEjgILFAoNCgUEAwIAAxIEjgIXGApICgIEBBIGkgIAlgIBGjogVG8gc3VwcG9ydCB0aGUg
Y3VzdG9tIHdlaWdodGluZyBhY3Jvc3MgZG9jdW1lbnQgc2NoZW1hcy4KCgsKAwQEARIEkgII
HQp5CgQEBAIAEgSVAgJBGmsgTGlzdCBvZiBzY2hlbWEgYW5kIHByb3BlcnR5IG5hbWUuIEFs
bG93cyBhIG1heGltdW0gb2YgMTAgc2NoZW1hcyB0byBiZQogc3BlY2lmaWVkIGZvciByZWxl
dmFuY2UgYm9vc3RpbmcuCgoNCgUEBAIABBIElQICCgoNCgUEBAIABhIElQILIQoNCgUEBAIA
ARIElQIiPAoNCgUEBAIAAxIElQI/QAozCgIEBRIGmQIAoQIBGiUgU3BlY2lmaWVzIHRoZSBz
Y2hlbWEgcHJvcGVydHkgbmFtZS4KCgsKAwQFARIEmQIIHgorCgQEBQIAEgabAgKdAgUaGyBU
aGUgZG9jdW1lbnQgc2NoZW1hIG5hbWUuCgoNCgUEBQIABRIEmwICCAoNCgUEBQIAARIEmwIJ
HQoNCgUEBQIAAxIEmwIgIQoPCgUEBQIACBIGmwIinQIEChEKBwQFAgAInwgSBpsCI50CAwo8
CgQEBQIBEgSgAgIlGi4gVGhlIHByb3BlcnR5IGRlZmluaXRpb24gbmFtZXMgaW4gdGhlIHNj
aGVtYS4KCg0KBQQFAgEEEgSgAgIKCg0KBQQFAgEFEgSgAgsRCg0KBQQFAgEBEgSgAhIgCg0K
BQQFAgEDEgSgAiMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery ===
    # Fields for DocumentQuery
    # Field: query Type: 9 ()
    # Field: is_nl_query Type: 8 ()
    # Field: custom_property_filter Type: 9 ()
    # Field: time_filters Type: 11 (.google.cloud.contentwarehouse.v1.TimeFilter)
    # Field: document_schema_names Type: 9 ()
    # Field: property_filter Type: 11 (.google.cloud.contentwarehouse.v1.PropertyFilter)
    # Field: file_type_filter Type: 11 (.google.cloud.contentwarehouse.v1.FileTypeFilter)
    # Field: folder_name_filter Type: 9 ()
    # Field: document_name_filter Type: 9 ()
    # Field: query_context Type: 9 ()
    # Field: document_creator_filter Type: 9 ()
    # Field: custom_weights_metadata Type: 11 (.google.cloud.contentwarehouse.v1.CustomWeightsMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter ===
    # Fields for TimeFilter
    # Field: time_range Type: 11 (.google.type.Interval)
    # Field: time_field Type: 14 (.google.cloud.contentwarehouse.v1.TimeFilter.TimeField)

# Enum: TimeFilter::TimeField
our $TimeFilter_TIME_FIELD_UNSPECIFIED = 0;
our $TimeFilter_CREATE_TIME = 1;
our $TimeFilter_UPDATE_TIME = 2;
our $TimeFilter_DISPOSITION_TIME = 3;

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter ===
    # Fields for PropertyFilter
    # Field: document_schema_name Type: 9 ()
    # Field: condition Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter ===
    # Fields for FileTypeFilter
    # Field: file_type Type: 14 (.google.cloud.contentwarehouse.v1.FileTypeFilter.FileType)

# Enum: FileTypeFilter::FileType
our $FileTypeFilter_FILE_TYPE_UNSPECIFIED = 0;
our $FileTypeFilter_ALL = 1;
our $FileTypeFilter_FOLDER = 2;
our $FileTypeFilter_DOCUMENT = 3;
our $FileTypeFilter_ROOT_FOLDER = 4;

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata ===
    # Fields for CustomWeightsMetadata
    # Field: weighted_schema_properties Type: 11 (.google.cloud.contentwarehouse.v1.WeightedSchemaProperty)

# === Message: Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty ===
    # Fields for WeightedSchemaProperty
    # Field: document_schema_name Type: 9 ()
    # Field: property_names Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Filters - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/filters.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Filters;

    my $msg = Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery->new({
        query => $query,
        is_nl_query => $is_nl_query,
        custom_property_filter => $custom_property_filter,
        time_filters => $time_filters,
    });

    # Read or update a field
    my $val = $msg->query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/filters.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The query string that matches against the full text of the document and
the searchable properties.

The query partially supports [Google AIP style
syntax](https://google.aip.dev/160). Specifically, the query supports
literals, logical operators, negation operators, comparison operators, and
functions.

Literals: A bare literal value (examples: "42", "Hugo") is a value to be
matched against. It searches over the full text of the document and the
searchable properties.

Logical operators: "AND", "and", "OR", and "or" are binary logical
operators (example: "engineer OR developer").

Negation operators: "NOT" and "!" are negation operators (example: "NOT
software").

Comparison operators: support the binary comparison operators =, !=, <, >,
<= and >= for string, numeric, enum, boolean. Also support like operator
`~~` for string. It provides semantic search functionality by parsing,
stemming and doing synonyms expansion against the input query.

To specify a property in the query, the left hand side expression in the
comparison must be the property ID including the parent. The right hand
side must be literals. For example:
"\"projects/123/locations/us\".property_a < 1" matches results whose
"property_a" is less than 1 in project 123 and us location.
The literals and comparison expression can be connected in a single query
(example: "software engineer \"projects/123/locations/us\".salary > 100").

Functions: supported functions are `LOWER([property_name])` to perform a
case insensitive match and `EMPTY([property_name])` to filter on the
existence of a key.

Support nested expressions connected using parenthesis and logical
operators. The default logical operators is `AND` if there is no operators
between expressions.

The query can be used with other filters e.g. `time_filters` and
`folder_name_filter`. They are connected with `AND` operator under the
hood.

The maximum number of allowed characters is 255.

=item * C<< $msg->is_nl_query() >> / C<< $msg->is_nl_query($value) >>

Type: C<Bool>

Experimental, do not use.
If the query is a natural language question. False by default. If true,
then the question-answering feature will be used instead of search, and
`result_count` in
[SearchDocumentsRequest][google.cloud.contentwarehouse.v1.SearchDocumentsRequest]
must be set. In addition, all other input fields related to search
(pagination, histograms, etc.) will be ignored.

=item * C<< $msg->custom_property_filter() >> / C<< $msg->custom_property_filter($value) >>

Type: C<String>

This filter specifies a structured syntax to match against the
[PropertyDefinition].[is_filterable][] marked as `true`. The syntax for
this expression is a subset of SQL syntax.

Supported operators are: `=`, `!=`, `<`, `<=`, `>`, and `>=` where the left
of the operator is a property name and the right of the operator is a
number or a quoted string. You must escape backslash (\\) and quote (\")
characters. Supported functions are `LOWER([property_name])` to perform a
case insensitive match and `EMPTY([property_name])` to filter on the
existence of a key.

Boolean expressions (AND/OR/NOT) are supported up to 3 levels of nesting
(for example, "((A AND B AND C) OR NOT D) AND E"), a maximum of 100
comparisons or functions are allowed in the expression. The expression must
be < 6000 bytes in length.

Sample Query:
`(LOWER(driving_license)="class \"a\"" OR EMPTY(driving_license)) AND
driving_years > 10`

=item * C<< $msg->time_filters() >> / C<< $msg->time_filters($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter>)

Documents created/updated within a range specified by this filter are
searched against.

=item * C<< $msg->document_schema_names() >> / C<< $msg->document_schema_names($value) >>

Type: C<String>

This filter specifies the exact document schema
[Document.document_schema_name][google.cloud.contentwarehouse.v1.Document.document_schema_name]
of the documents to search against.

If a value isn't specified, documents within the search results are
associated with any schema. If multiple values are specified, documents
within the search results may be associated with any of the specified
schemas.

At most 20 document schema names are allowed.

=item * C<< $msg->property_filter() >> / C<< $msg->property_filter($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter>)

This filter specifies a structured syntax to match against the
[PropertyDefinition.is_filterable][google.cloud.contentwarehouse.v1.PropertyDefinition.is_filterable]
marked as `true`. The relationship between the PropertyFilters is OR.

=item * C<< $msg->file_type_filter() >> / C<< $msg->file_type_filter($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter>)

This filter specifies the types of files to return: ALL, FOLDER, or FILE.
If FOLDER or FILE is specified, then only either folders or files will be
returned, respectively. If ALL is specified, both folders and files will be
returned.

If no value is specified, ALL files will be returned.

=item * C<< $msg->folder_name_filter() >> / C<< $msg->folder_name_filter($value) >>

Type: C<String>

Search all the documents under this specified folder.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=item * C<< $msg->document_name_filter() >> / C<< $msg->document_name_filter($value) >>

Type: C<String>

Search the documents in the list.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=item * C<< $msg->query_context() >> / C<< $msg->query_context($value) >>

Type: C<String>

For custom synonyms.
Customers provide the synonyms based on context. One customer can provide
multiple set of synonyms based on different context. The search query will
be expanded based on the custom synonyms of the query context set.
By default, no custom synonyms wll be applied if no query context is
provided.
It is not supported for CMEK compliant deployment.

=item * C<< $msg->document_creator_filter() >> / C<< $msg->document_creator_filter($value) >>

Type: C<String>

The exact creator(s) of the documents to search against.

If a value isn't specified, documents within the search results are
associated with any creator. If multiple values are specified, documents
within the search results may be associated with any of the specified
creators.

=item * C<< $msg->custom_weights_metadata() >> / C<< $msg->custom_weights_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata>)

To support the custom weighting across document schemas, customers need to
provide the properties to be used to boost the ranking in the search
request. For a search query with CustomWeightsMetadata specified, only the
RetrievalImportance for the properties in the CustomWeightsMetadata will
be honored.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter

Filter on create timestamp or update timestamp of documents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_range() >> / C<< $msg->time_range($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

=item * C<< $msg->time_field() >> / C<< $msg->time_field($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::TimeFilter::TimeField>)

Specifies which time field to filter documents on.

Defaults to [TimeField.UPLOAD_TIME][].

=back

=head3 Enum: TimeFilter::TimeField

=over 4

=item * C<TIME_FIELD_UNSPECIFIED> => C<0>

=item * C<CREATE_TIME> => C<1>

=item * C<UPDATE_TIME> => C<2>

=item * C<DISPOSITION_TIME> => C<3>

=back

=head2 Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_schema_name() >> / C<< $msg->document_schema_name($value) >>

Type: C<String>

The Document schema name
[Document.document_schema_name][google.cloud.contentwarehouse.v1.Document.document_schema_name].
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

The filter condition.
The syntax for this expression is a subset of SQL syntax.

Supported operators are: `=`, `!=`, `<`, `<=`, `>`, `>=`, and `~~` where
the left of the operator is a property name and the right of the operator
is a number or a quoted string. You must escape backslash (\\) and quote
(\") characters.

`~~` is the LIKE operator. The right of the operator must be a string. The
only supported property data type for LIKE is text_values. It provides
semantic search functionality by parsing, stemming and doing synonyms
expansion against the input query. It matches if the property contains
semantic similar content to the query. It is not regex matching or wildcard
matching. For example, "property.company ~~ \"google\"" will match records
whose property `property.compnay` have values like "Google Inc.", "Google
LLC" or "Google Company".

Supported functions are `LOWER([property_name])` to perform a
case insensitive match and `EMPTY([property_name])` to filter on the
existence of a key.

Boolean expressions (AND/OR/NOT) are supported up to 3 levels of nesting
(for example, "((A AND B AND C) OR NOT D) AND E"), a maximum of 100
comparisons or functions are allowed in the expression. The expression must
be < 6000 bytes in length.

Only properties that are marked filterable are allowed
([PropertyDefinition.is_filterable][google.cloud.contentwarehouse.v1.PropertyDefinition.is_filterable]).
Property names do not need to be prefixed by the document schema id (as is
the case with histograms), however property names will need to be prefixed
by its parent hierarchy, if any.  For example:
top_property_name.sub_property_name.

Sample Query:
`(LOWER(driving_license)="class \"a\"" OR EMPTY(driving_license)) AND
driving_years > 10`


CMEK compliant deployment only supports:

* Operators: `=`, `<`, `<=`, `>`, and `>=`.
* Boolean expressions: AND and OR.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter

Filter for the specific types of documents returned.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_type() >> / C<< $msg->file_type($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::FileTypeFilter::FileType>)

The type of files to return.

=back

=head3 Enum: FileTypeFilter::FileType

=over 4

=item * C<FILE_TYPE_UNSPECIFIED> => C<0>

=item * C<ALL> => C<1>

=item * C<FOLDER> => C<2>

=item * C<DOCUMENT> => C<3>

=item * C<ROOT_FOLDER> => C<4>

=back

=head2 Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata

To support the custom weighting across document schemas.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->weighted_schema_properties() >> / C<< $msg->weighted_schema_properties($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty>)

List of schema and property name. Allows a maximum of 10 schemas to be
specified for relevance boosting.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty

Specifies the schema property name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_schema_name() >> / C<< $msg->document_schema_name($value) >>

Type: C<String>

The document schema name.

=item * C<< $msg->property_names() >> / C<< $msg->property_names($value) >>

Type: C<String>

The property definition names in the schema.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Filters::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
