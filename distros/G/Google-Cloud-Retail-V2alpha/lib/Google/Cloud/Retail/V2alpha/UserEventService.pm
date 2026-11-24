package Google::Cloud::Retail::V2alpha::UserEventService;

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
    eval { require Google::Api::Httpbody };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Retail::V2alpha::ExportConfig };
    eval { require Google::Cloud::Retail::V2alpha::ImportConfig };
    eval { require Google::Cloud::Retail::V2alpha::PurgeConfig };
    eval { require Google::Cloud::Retail::V2alpha::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvdXNlcl9ldmVudF9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL2h0dHBib2R5LnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGi9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvZXhwb3J0X2NvbmZpZy5w
cm90bxovZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmFscGhhL2ltcG9ydF9jb25maWcucHJvdG8a
Lmdvb2dsZS9jbG91ZC9yZXRhaWwvdjJhbHBoYS9wdXJnZV9jb25maWcucHJvdG8aLGdvb2ds
ZS9jbG91ZC9yZXRhaWwvdjJhbHBoYS91c2VyX2V2ZW50LnByb3RvGiNnb29nbGUvbG9uZ3J1
bm5pbmcvb3BlcmF0aW9ucy5wcm90byKhAQoVV3JpdGVVc2VyRXZlbnRSZXF1ZXN0EhsKBnBh
cmVudBgBIAEoCUID4EECUgZwYXJlbnQSSgoKdXNlcl9ldmVudBgCIAEoCzImLmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYS5Vc2VyRXZlbnRCA+BBAlIJdXNlckV2ZW50Eh8KC3dyaXRl
X2FzeW5jGAMgASgIUgp3cml0ZUFzeW5jItMBChdDb2xsZWN0VXNlckV2ZW50UmVxdWVzdBIl
Cg1wcmVidWlsdF9ydWxlGAYgASgJSABSDHByZWJ1aWx0UnVsZRIbCgZwYXJlbnQYASABKAlC
A+BBAlIGcGFyZW50EiIKCnVzZXJfZXZlbnQYAiABKAlCA+BBAlIJdXNlckV2ZW50EhAKA3Vy
aRgDIAEoCVIDdXJpEhAKA2V0cxgEIAEoA1IDZXRzEhkKCHJhd19qc29uGAUgASgJUgdyYXdK
c29uQhEKD2NvbnZlcnNpb25fcnVsZSKiAgoXUmVqb2luVXNlckV2ZW50c1JlcXVlc3QSGwoG
cGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBKAAQoXdXNlcl9ldmVudF9yZWpvaW5fc2NvcGUY
AiABKA4ySS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUmVqb2luVXNlckV2ZW50c1Jl
cXVlc3QuVXNlckV2ZW50UmVqb2luU2NvcGVSFHVzZXJFdmVudFJlam9pblNjb3BlImcKFFVz
ZXJFdmVudFJlam9pblNjb3BlEicKI1VTRVJfRVZFTlRfUkVKT0lOX1NDT1BFX1VOU1BFQ0lG
SUVEEAASEQoNSk9JTkVEX0VWRU5UUxABEhMKD1VOSk9JTkVEX0VWRU5UUxACIlcKGFJlam9p
blVzZXJFdmVudHNSZXNwb25zZRI7ChpyZWpvaW5lZF91c2VyX2V2ZW50c19jb3VudBgBIAEo
A1IXcmVqb2luZWRVc2VyRXZlbnRzQ291bnQiGgoYUmVqb2luVXNlckV2ZW50c01ldGFkYXRh
MvsMChBVc2VyRXZlbnRTZXJ2aWNlEsYBCg5Xcml0ZVVzZXJFdmVudBIyLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJhbHBoYS5Xcml0ZVVzZXJFdmVudFJlcXVlc3QaJi5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyYWxwaGEuVXNlckV2ZW50IliC0+STAlIiRC92MmFscGhhL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS91c2VyRXZlbnRzOndyaXRlOgp1c2Vy
X2V2ZW50Ev0BChBDb2xsZWN0VXNlckV2ZW50EjQuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkNvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0GhQuZ29vZ2xlLmFwaS5IdHRwQm9keSKcAYLT
5JMClQESRi92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9n
cy8qfS91c2VyRXZlbnRzOmNvbGxlY3RaSyJGL3YyYWxwaGEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6Y29sbGVjdDoBKhKaAgoPUHVy
Z2VVc2VyRXZlbnRzEjMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlB1cmdlVXNlckV2
ZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrIBgtPkkwJJIkQv
djJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vdXNl
ckV2ZW50czpwdXJnZToBKspBYAozZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlB1cmdl
VXNlckV2ZW50c1Jlc3BvbnNlEilnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUHVyZ2VN
ZXRhZGF0YRKfAgoQSW1wb3J0VXNlckV2ZW50cxI0Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5JbXBvcnRVc2VyRXZlbnRzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb24itQGC0+STAkoiRS92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qfS91c2VyRXZlbnRzOmltcG9ydDoBKspBYgo0Z29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLkltcG9ydFVzZXJFdmVudHNSZXNwb25zZRIqZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLkltcG9ydE1ldGFkYXRhEp8CChBFeHBvcnRVc2VyRXZlbnRzEjQuZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkV4cG9ydFVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiK1AYLT5JMCSiJFL3YyYWxwaGEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3VzZXJFdmVudHM6ZXhwb3J0OgEq
ykFiCjRnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuRXhwb3J0VXNlckV2ZW50c1Jlc3Bv
bnNlEipnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuRXhwb3J0TWV0YWRhdGES8QEKEFJl
am9pblVzZXJFdmVudHMSNC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUmVqb2luVXNl
ckV2ZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIocBgtPkkwJK
IkUvdjJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0v
dXNlckV2ZW50czpyZWpvaW46ASrKQTQKGFJlam9pblVzZXJFdmVudHNSZXNwb25zZRIYUmVq
b2luVXNlckV2ZW50c01ldGFkYXRhGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtkBCh9jb20uZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhQhVVc2VyRXZlbnRTZXJ2aWNlUHJvdG9QAVo3Y2xv
dWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqIC
BlJFVEFJTKoCG0dvb2dsZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxS
ZXRhaWxcVjJhbHBoYeoCHkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUrSOQoHEgUO
AOgBIwq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
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
ABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACMKCQoC
AwUSAxcAOQoJCgIDBhIDGAA5CgkKAgMHEgMZADgKCQoCAwgSAxoANgoJCgIDCRIDGwAtCggK
AQgSAx0AOAoJCgIIJRIDHQA4CggKAQgSAx4ATgoJCgIICxIDHgBOCggKAQgSAx8AIgoJCgII
ChIDHwAiCggKAQgSAyAANgoJCgIICBIDIAA2CggKAQgSAyEAOAoJCgIIARIDIQA4CggKAQgS
AyIAJAoJCgIIJBIDIgAkCggKAQgSAyMAOAoJCgIIKRIDIwA4CggKAQgSAyQANwoJCgIILRID
JAA3Ck4KAgYAEgUnAIsBARpBIFNlcnZpY2UgZm9yIGluZ2VzdGluZyBlbmQgdXNlciBhY3Rp
b25zIG9uIHRoZSBjdXN0b21lciB3ZWJzaXRlLgoKCgoDBgABEgMnCBgKCgoDBgADEgMoAj0K
DAoFBgADmQgSAygCPQoLCgMGAAMSBCkCKjcKDQoFBgADmggSBCkCKjcKKwoEBgACABIELQIy
AxodIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50LgoKDAoFBgACAAESAy0GFAoMCgUGAAIA
AhIDLRUqCgwKBQYAAgADEgMtNT4KDQoFBgACAAQSBC4EMQYKEQoJBgACAASwyrwiEgQuBDEG
CsQCCgQGAAIBEgQ7AkMDGrUCIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50IGZyb20gdGhl
IGJyb3dzZXIuCgogRm9yIGxhcmdlciB1c2VyIGV2ZW50IHBheWxvYWQgb3ZlciAxNiBLQiwg
dGhlIFBPU1QgbWV0aG9kIHNob3VsZCBiZSB1c2VkCiBpbnN0ZWFkLCBvdGhlcndpc2UgYSA0
MDAgQmFkIFJlcXVlc3QgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBtZXRob2QgaXMgdXNl
ZCBvbmx5IGJ5IHRoZSBSZXRhaWwgQVBJIEphdmFTY3JpcHQgcGl4ZWwgYW5kIEdvb2dsZSBU
YWcKIE1hbmFnZXIuIFVzZXJzIHNob3VsZCBub3QgY2FsbCB0aGlzIG1ldGhvZCBkaXJlY3Rs
eS4KCgwKBQYAAgEBEgM7BhYKDAoFBgACAQISAzsXLgoMCgUGAAIBAxIDOzlMCg0KBQYAAgEE
EgQ8BEIGChEKCQYAAgEEsMq8IhIEPARCBgr3AQoEBgACAhIESQJTAxroASBEZWxldGVzIHBl
cm1hbmVudGx5IGFsbCB1c2VyIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciBwcm92
aWRlZC4KIERlcGVuZGluZyBvbiB0aGUgbnVtYmVyIG9mIGV2ZW50cyBzcGVjaWZpZWQgYnkg
dGhlIGZpbHRlciwgdGhpcyBvcGVyYXRpb24KIGNvdWxkIHRha2UgaG91cnMgb3IgZGF5cyB0
byBjb21wbGV0ZS4gVG8gdGVzdCBhIGZpbHRlciwgdXNlIHRoZSBsaXN0CiBjb21tYW5kIGZp
cnN0LgoKDAoFBgACAgESA0kGFQoMCgUGAAICAhIDSRYsCgwKBQYAAgIDEgNKDysKDQoFBgAC
AgQSBEsETgYKEQoJBgACAgSwyrwiEgRLBE4GCg0KBQYAAgIEEgRPBFIGCg8KBwYAAgIEmQgS
BE8EUgYK7gIKBAYAAgMSBFwCZgMa3wIgQnVsayBpbXBvcnQgb2YgVXNlciBldmVudHMuIFJl
cXVlc3QgcHJvY2Vzc2luZyBtaWdodCBiZQogc3luY2hyb25vdXMuIEV2ZW50cyB0aGF0IGFs
cmVhZHkgZXhpc3QgYXJlIHNraXBwZWQuCiBVc2UgdGhpcyBtZXRob2QgZm9yIGJhY2tmaWxs
aW5nIGhpc3RvcmljYWwgdXNlciBldmVudHMuCgogYE9wZXJhdGlvbi5yZXNwb25zZWAgaXMg
b2YgdHlwZSBgSW1wb3J0UmVzcG9uc2VgLiBOb3RlIHRoYXQgaXQgaXMKIHBvc3NpYmxlIGZv
ciBhIHN1YnNldCBvZiB0aGUgaXRlbXMgdG8gYmUgc3VjY2Vzc2Z1bGx5IGluc2VydGVkLgog
YE9wZXJhdGlvbi5tZXRhZGF0YWAgaXMgb2YgdHlwZSBgSW1wb3J0TWV0YWRhdGFgLgoKDAoF
BgACAwESA1wGFgoMCgUGAAIDAhIDXBcuCgwKBQYAAgMDEgNdDysKDQoFBgACAwQSBF4EYQYK
EQoJBgACAwSwyrwiEgReBGEGCg0KBQYAAgMEEgRiBGUGCg8KBwYAAgMEmQgSBGIEZQYKiwEK
BAYAAgQSBGwCdgMafSBFeHBvcnRzIHVzZXIgZXZlbnRzLgoKIGBPcGVyYXRpb24ucmVzcG9u
c2VgIGlzIG9mIHR5cGUgYEV4cG9ydFJlc3BvbnNlYC4KIGBPcGVyYXRpb24ubWV0YWRhdGFg
IGlzIG9mIHR5cGUgYEV4cG9ydE1ldGFkYXRhYC4KCgwKBQYAAgQBEgNsBhYKDAoFBgACBAIS
A2wXLgoMCgUGAAIEAxIDbQ8rCg0KBQYAAgQEEgRuBHEGChEKCQYAAgQEsMq8IhIEbgRxBgoN
CgUGAAIEBBIEcgR1BgoPCgcGAAIEBJkIEgRyBHUGCrwECgQGAAIFEgaAAQKKAQMaqwQgU3Rh
cnRzIGEgdXNlci1ldmVudCByZWpvaW4gb3BlcmF0aW9uIHdpdGggbGF0ZXN0IHByb2R1Y3Qg
Y2F0YWxvZy4gRXZlbnRzCiBhcmUgbm90IGFubm90YXRlZCB3aXRoIGRldGFpbGVkIHByb2R1
Y3QgaW5mb3JtYXRpb24gZm9yIHByb2R1Y3RzIHRoYXQgYXJlCiBtaXNzaW5nIGZyb20gdGhl
IGNhdGFsb2cgd2hlbiB0aGUgdXNlciBldmVudCBpcyBpbmdlc3RlZC4gVGhlc2UKIGV2ZW50
cyBhcmUgc3RvcmVkIGFzIHVuam9pbmVkIGV2ZW50cyB3aXRoIGxpbWl0ZWQgdXNhZ2Ugb24g
dHJhaW5pbmcgYW5kCiBzZXJ2aW5nLiBZb3UgY2FuIHVzZSB0aGlzIG1ldGhvZCB0byBzdGFy
dCBhIGpvaW4gb3BlcmF0aW9uIG9uIHNwZWNpZmllZAogZXZlbnRzIHdpdGggdGhlIGxhdGVz
dCB2ZXJzaW9uIG9mIHByb2R1Y3QgY2F0YWxvZy4gWW91IGNhbiBhbHNvIHVzZSB0aGlzCiBt
ZXRob2QgdG8gY29ycmVjdCBldmVudHMgam9pbmVkIHdpdGggdGhlIHdyb25nIHByb2R1Y3Qg
Y2F0YWxvZy4gQSByZWpvaW4KIG9wZXJhdGlvbiBjYW4gdGFrZSBob3VycyBvciBkYXlzIHRv
IGNvbXBsZXRlLgoKDQoFBgACBQESBIABBhYKDQoFBgACBQISBIABFy4KDQoFBgACBQMSBIEB
DysKDwoFBgACBQQSBoIBBIUBBgoTCgkGAAIFBLDKvCISBoIBBIUBBgoPCgUGAAIFBBIGhgEE
iQEGChEKBwYAAgUEmQgSBoYBBIkBBgo6CgIEABIGjgEAmwEBGiwgUmVxdWVzdCBtZXNzYWdl
IGZvciBXcml0ZVVzZXJFdmVudCBtZXRob2QuCgoLCgMEAAESBI4BCB0KfwoEBAACABIEkQEC
PRpxIFJlcXVpcmVkLiBUaGUgcGFyZW50IGNhdGFsb2cgcmVzb3VyY2UgbmFtZSwgc3VjaCBh
cwogYHByb2plY3RzLzEyMzQvbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9kZWZhdWx0X2Nh
dGFsb2dgLgoKDQoFBAACAAUSBJEBAggKDQoFBAACAAESBJEBCQ8KDQoFBAACAAMSBJEBEhMK
DQoFBAACAAgSBJEBFDwKEAoIBAACAAicCAASBJEBFTsKLgoEBAACARIElAECRBogIFJlcXVp
cmVkLiBVc2VyIGV2ZW50IHRvIHdyaXRlLgoKDQoFBAACAQYSBJQBAgsKDQoFBAACAQESBJQB
DBYKDQoFBAACAQMSBJQBGRoKDQoFBAACAQgSBJQBG0MKEAoIBAACAQicCAASBJQBHEIKrgIK
BAQAAgISBJoBAhcanwIgSWYgc2V0IHRvIHRydWUsIHRoZSB1c2VyIGV2ZW50IHdpbGwgYmUg
d3JpdHRlbiBhc3luY2hyb25vdXNseSBhZnRlcgogdmFsaWRhdGlvbiwgYW5kIHRoZSBBUEkg
d2lsbCByZXNwb25kIHdpdGhvdXQgd2FpdGluZyBmb3IgdGhlIHdyaXRlLgogVGhlcmVmb3Jl
LCBzaWxlbnQgZmFpbHVyZXMgY2FuIG9jY3VyIGV2ZW4gaWYgdGhlIEFQSSByZXR1cm5zIHN1
Y2Nlc3MuIEluCiBjYXNlIG9mIHNpbGVudCBmYWlsdXJlcywgZXJyb3IgbWVzc2FnZXMgY2Fu
IGJlIGZvdW5kIGluIFN0YWNrZHJpdmVyIGxvZ3MuCgoNCgUEAAICBRIEmgECBgoNCgUEAAIC
ARIEmgEHEgoNCgUEAAICAxIEmgEVFgo8CgIEARIGngEAvwEBGi4gUmVxdWVzdCBtZXNzYWdl
IGZvciBDb2xsZWN0VXNlckV2ZW50IG1ldGhvZC4KCgsKAwQBARIEngEIHwp2CgQEAQgAEgah
AQKlAQMaZiBUaGUgcnVsZSB0aGF0IGNhbiBjb252ZXJ0IHRoZSByYXdfanNvbiB0byBhIHVz
ZXIgZXZlbnQuIEl0IGlzIG5lZWRlZAogb25seSB3aGVuIHRoZSByYXdfanNvbiBpcyBzZXQu
CgoNCgUEAQgAARIEoQEIFwqQAQoEBAECABIEpAEEHRqBASBUaGUgcHJlYnVpbHQgcnVsZSBu
YW1lIHRoYXQgY2FuIGNvbnZlcnQgYSBzcGVjaWZpYyB0eXBlIG9mIHJhd19qc29uLgogRm9y
IGV4YW1wbGU6ICJnYTRfYnEiIHJ1bGUgZm9yIHRoZSBHQTQgdXNlciBldmVudCBzY2hlbWEu
CgoNCgUEAQIABRIEpAEECgoNCgUEAQIAARIEpAELGAoNCgUEAQIAAxIEpAEbHAp2CgQEAQIB
EgSpAQI9GmggUmVxdWlyZWQuIFRoZSBwYXJlbnQgY2F0YWxvZyBuYW1lLCBzdWNoIGFzCiBg
cHJvamVjdHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxv
Z2AuCgoNCgUEAQIBBRIEqQECCAoNCgUEAQIBARIEqQEJDwoNCgUEAQIBAxIEqQESEwoNCgUE
AQIBCBIEqQEUPAoQCggEAQIBCJwIABIEqQEVOwpjCgQEAQICEgStAQJBGlUgUmVxdWlyZWQu
IFVSTCBlbmNvZGVkIFVzZXJFdmVudCBwcm90byB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDIs
MDAwLDAwMAogY2hhcmFjdGVycy4KCg0KBQQBAgIFEgStAQIICg0KBQQBAgIBEgStAQkTCg0K
BQQBAgIDEgStARYXCg0KBQQBAgIIEgStARhAChAKCAQBAgIInAgAEgStARk/CvABCgQEAQID
EgSzAQIRGuEBIFRoZSBVUkwgaW5jbHVkaW5nIGNnaS1wYXJhbWV0ZXJzIGJ1dCBleGNsdWRp
bmcgdGhlIGhhc2ggZnJhZ21lbnQgd2l0aCBhCiBsZW5ndGggbGltaXQgb2YgNSwwMDAgY2hh
cmFjdGVycy4gVGhpcyBpcyBvZnRlbiBtb3JlIHVzZWZ1bCB0aGFuIHRoZQogcmVmZXJlciBV
UkwsIGJlY2F1c2UgbWFueSBicm93c2VycyBvbmx5IHNlbmQgdGhlIGRvbWFpbiBmb3IgM3Jk
IHBhcnR5CiByZXF1ZXN0cy4KCg0KBQQBAgMFEgSzAQIICg0KBQQBAgMBEgSzAQkMCg0KBQQB
AgMDEgSzAQ8QCq8BCgQEAQIEEgS4AQIQGqABIFRoZSBldmVudCB0aW1lc3RhbXAgaW4gbWls
bGlzZWNvbmRzLiBUaGlzIHByZXZlbnRzIGJyb3dzZXIgY2FjaGluZyBvZgogb3RoZXJ3aXNl
IGlkZW50aWNhbCBnZXQgcmVxdWVzdHMuIFRoZSBuYW1lIGlzIGFiYnJldmlhdGVkIHRvIHJl
ZHVjZSB0aGUKIHBheWxvYWQgYnl0ZXMuCgoNCgUEAQIEBRIEuAECBwoNCgUEAQIEARIEuAEI
CwoNCgUEAQIEAxIEuAEODwr/AQoEBAECBRIEvgECFhrwASBBbiBhcmJpdHJhcnkgc2VyaWFs
aXplZCBKU09OIHN0cmluZyB0aGF0IGNvbnRhaW5zIG5lY2Vzc2FyeSBpbmZvcm1hdGlvbgog
dGhhdCBjYW4gY29tcHJpc2UgYSB1c2VyIGV2ZW50LiBXaGVuIHRoaXMgZmllbGQgaXMgc3Bl
Y2lmaWVkLCB0aGUKIHVzZXJfZXZlbnQgZmllbGQgd2lsbCBiZSBpZ25vcmVkLiBOb3RlOiBs
aW5lLWRlbGltaXRlZCBKU09OIGlzIG5vdAogc3VwcG9ydGVkLCBhIHNpbmdsZSBKU09OIG9u
bHkuCgoNCgUEAQIFBRIEvgECCAoNCgUEAQIFARIEvgEJEQoNCgUEAQIFAxIEvgEUFQo8CgIE
AhIGwgEA3wEBGi4gUmVxdWVzdCBtZXNzYWdlIGZvciBSZWpvaW5Vc2VyRXZlbnRzIG1ldGhv
ZC4KCgsKAwQCARIEwgEIHwq5AwoEBAIEABIGygEC1AEDGqgDIFRoZSBzY29wZSBvZiB1c2Vy
IGV2ZW50cyB0byBiZSByZWpvaW5lZCB3aXRoIHRoZSBsYXRlc3QgcHJvZHVjdCBjYXRhbG9n
LgogSWYgdGhlIHJlam9pbmluZyBhaW1zIGF0IHJlZHVjaW5nIG51bWJlciBvZiB1bmpvaW5l
ZCBldmVudHMsIHNldAogYFVzZXJFdmVudFJlam9pblNjb3BlYCB0byBgVU5KT0lORURfRVZF
TlRTYC4KIElmIHRoZSByZWpvaW5pbmcgYWltcyBhdCBjb3JyZWN0aW5nIHByb2R1Y3QgY2F0
YWxvZyBpbmZvcm1hdGlvbiBpbiBqb2luZWQKIGV2ZW50cywgc2V0IGBVc2VyRXZlbnRSZWpv
aW5TY29wZWAgdG8gYEpPSU5FRF9FVkVOVFNgLgogSWYgYWxsIGV2ZW50cyBuZWVkcyB0byBi
ZSByZWpvaW5lZCwgc2V0IGBVc2VyRXZlbnRSZWpvaW5TY29wZWAgdG8KIGBVU0VSX0VWRU5U
X1JFSk9JTl9TQ09QRV9VTlNQRUNJRklFRGAuCgoNCgUEAgQAARIEygEHGwp3CgYEAgQAAgAS
BM0BBCwaZyBSZWpvaW4gYWxsIGV2ZW50cyB3aXRoIHRoZSBsYXRlc3QgcHJvZHVjdCBjYXRh
bG9nLCBpbmNsdWRpbmcgYm90aCBqb2luZWQKIGV2ZW50cyBhbmQgdW5qb2luZWQgZXZlbnRz
LgoKDwoHBAIEAAIAARIEzQEEJwoPCgcEAgQAAgACEgTNASorCkwKBgQCBAACARIE0AEEFho8
IE9ubHkgcmVqb2luIGpvaW5lZCBldmVudHMgd2l0aCB0aGUgbGF0ZXN0IHByb2R1Y3QgY2F0
YWxvZy4KCg8KBwQCBAACAQESBNABBBEKDwoHBAIEAAIBAhIE0AEUFQpOCgYEAgQAAgISBNMB
BBgaPiBPbmx5IHJlam9pbiB1bmpvaW5lZCBldmVudHMgd2l0aCB0aGUgbGF0ZXN0IHByb2R1
Y3QgY2F0YWxvZy4KCg8KBwQCBAACAgESBNMBBBMKDwoHBAIEAAICAhIE0wEWFwp/CgQEAgIA
EgTYAQI9GnEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgY2F0YWxvZyByZXNvdXJjZSBuYW1lLCBz
dWNoIGFzCiBgcHJvamVjdHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1
bHRfY2F0YWxvZ2AuCgoNCgUEAgIABRIE2AECCAoNCgUEAgIAARIE2AEJDwoNCgUEAgIAAxIE
2AESEwoNCgUEAgIACBIE2AEUPAoQCggEAgIACJwIABIE2AEVOwqGAgoEBAICARIE3gECMxr3
ASBUaGUgdHlwZSBvZiB0aGUgdXNlciBldmVudCByZWpvaW4gdG8gZGVmaW5lIHRoZSBzY29w
ZSBhbmQgcmFuZ2Ugb2YgdGhlIHVzZXIKIGV2ZW50cyB0byBiZSByZWpvaW5lZCB3aXRoIHRo
ZSBsYXRlc3QgcHJvZHVjdCBjYXRhbG9nLiBEZWZhdWx0cyB0bwogYFVTRVJfRVZFTlRfUkVK
T0lOX1NDT1BFX1VOU1BFQ0lGSUVEYCBpZiB0aGlzIGZpZWxkIGlzIG5vdCBzZXQsIG9yIHNl
dCB0bwogYW4gaW52YWxpZCBpbnRlZ2VyIHZhbHVlLgoKDQoFBAICAQYSBN4BAhYKDQoFBAIC
AQESBN4BFy4KDQoFBAICAQMSBN4BMTIKPwoCBAMSBuIBAOUBARoxIFJlc3BvbnNlIG1lc3Nh
Z2UgZm9yIGBSZWpvaW5Vc2VyRXZlbnRzYCBtZXRob2QuCgoLCgMEAwESBOIBCCAKUwoEBAMC
ABIE5AECJxpFIE51bWJlciBvZiB1c2VyIGV2ZW50cyB0aGF0IHdlcmUgam9pbmVkIHdpdGgg
bGF0ZXN0IHByb2R1Y3QgY2F0YWxvZy4KCg0KBQQDAgAFEgTkAQIHCg0KBQQDAgABEgTkAQgi
Cg0KBQQDAgADEgTkASUmCjUKAgQEEgToAQAjGikgTWV0YWRhdGEgZm9yIGBSZWpvaW5Vc2Vy
RXZlbnRzYCBtZXRob2QuCgoLCgMEBAESBOgBCCBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2alpha.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Retail::V2alpha::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: prebuilt_rule Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()
    # Field: raw_json Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsRequest ===
    # Fields for RejoinUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: user_event_rejoin_scope Type: 14 (.google.cloud.retail.v2alpha.RejoinUserEventsRequest.UserEventRejoinScope)

# Enum: RejoinUserEventsRequest::UserEventRejoinScope
our $RejoinUserEventsRequest_USER_EVENT_REJOIN_SCOPE_UNSPECIFIED = 0;
our $RejoinUserEventsRequest_JOINED_EVENTS = 1;
our $RejoinUserEventsRequest_UNJOINED_EVENTS = 2;

# === Message: Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsResponse ===
    # Fields for RejoinUserEventsResponse
    # Field: rejoined_user_events_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsMetadata ===
    # Fields for RejoinUserEventsMetadata

# === Service Client: Google::Cloud::Retail::V2alpha::UserEventService::UserEventServiceClient ===
package Google::Cloud::Retail::V2alpha::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::UserEventService::UserEventServiceClient

Client stub representing the remote C<UserEventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub write_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ExportConfig::ExportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'ExportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rejoin_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.UserEventService',
        method         => 'RejoinUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::UserEventService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::UserEventService;

    my $msg = Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event will be written asynchronously after
validation, and the API will respond without waiting for the write.
Therefore, silent failures can occur even if the API returns success. In
case of silent failures, error messages can be found in Stackdriver logs.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEventService::CollectUserEventRequest

Request message for CollectUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->prebuilt_rule() >> / C<< $msg->prebuilt_rule($value) >>

Type: C<String>

The prebuilt rule name that can convert a specific type of raw_json.
For example: "ga4_bq" rule for the GA4 user event schema.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<String>

Required. URL encoded UserEvent proto with a length limit of 2,000,000
characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URL including cgi-parameters but excluding the hash fragment with a
length limit of 5,000 characters. This is often more useful than the
referer URL, because many browsers only send the domain for 3rd party
requests.

=item * C<< $msg->ets() >> / C<< $msg->ets($value) >>

Type: C<Int64>

The event timestamp in milliseconds. This prevents browser caching of
otherwise identical get requests. The name is abbreviated to reduce the
payload bytes.

=item * C<< $msg->raw_json() >> / C<< $msg->raw_json($value) >>

Type: C<String>

An arbitrary serialized JSON string that contains necessary information
that can comprise a user event. When this field is specified, the
user_event field will be ignored. Note: line-delimited JSON is not
supported, a single JSON only.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsRequest

Request message for RejoinUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name, such as
`projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->user_event_rejoin_scope() >> / C<< $msg->user_event_rejoin_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::RejoinUserEventsRequest::UserEventRejoinScope>)

The type of the user event rejoin to define the scope and range of the user
events to be rejoined with the latest product catalog. Defaults to
`USER_EVENT_REJOIN_SCOPE_UNSPECIFIED` if this field is not set, or set to
an invalid integer value.

=back

=head3 Enum: RejoinUserEventsRequest::UserEventRejoinScope

=over 4

=item * C<USER_EVENT_REJOIN_SCOPE_UNSPECIFIED> => C<0>

=item * C<JOINED_EVENTS> => C<1>

=item * C<UNJOINED_EVENTS> => C<2>

=back

=head2 Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsResponse

Response message for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rejoined_user_events_count() >> / C<< $msg->rejoined_user_events_count($value) >>

Type: C<Int64>

Number of user events that were joined with latest product catalog.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEventService::RejoinUserEventsMetadata

Metadata for `RejoinUserEvents` method.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
