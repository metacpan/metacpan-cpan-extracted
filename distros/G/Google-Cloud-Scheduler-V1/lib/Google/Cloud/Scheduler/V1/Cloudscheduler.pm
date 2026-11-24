package Google::Cloud::Scheduler::V1::Cloudscheduler;

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
    eval { require Google::Cloud::Scheduler::V1::Job };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxL2Nsb3Vkc2NoZWR1bGVyLnByb3RvEhlnb29n
bGUuY2xvdWQuc2NoZWR1bGVyLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdn
b29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3NjaGVkdWxlci92
MS9qb2IucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3Rv
YnVmL2ZpZWxkX21hc2sucHJvdG8ikAEKD0xpc3RKb2JzUmVxdWVzdBJBCgZwYXJlbnQYASAB
KAlCKeBBAvpBIxIhY2xvdWRzY2hlZHVsZXIuZ29vZ2xlYXBpcy5jb20vSm9iUgZwYXJlbnQS
GwoJcGFnZV9zaXplGAUgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAYgASgJUglwYWdl
VG9rZW4ibgoQTGlzdEpvYnNSZXNwb25zZRIyCgRqb2JzGAEgAygLMh4uZ29vZ2xlLmNsb3Vk
LnNjaGVkdWxlci52MS5Kb2JSBGpvYnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0
UGFnZVRva2VuIk4KDUdldEpvYlJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91
ZHNjaGVkdWxlci5nb29nbGVhcGlzLmNvbS9Kb2JSBG5hbWUijAEKEENyZWF0ZUpvYlJlcXVl
c3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIWNsb3Vkc2NoZWR1bGVyLmdvb2dsZWFwaXMu
Y29tL0pvYlIGcGFyZW50EjUKA2pvYhgCIAEoCzIeLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djEuSm9iQgPgQQJSA2pvYiKGAQoQVXBkYXRlSm9iUmVxdWVzdBI1CgNqb2IYASABKAsyHi5n
b29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkpvYkID4EECUgNqb2ISOwoLdXBkYXRlX21hc2sY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIlEKEERlbGV0
ZUpvYlJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91ZHNjaGVkdWxlci5nb29n
bGVhcGlzLmNvbS9Kb2JSBG5hbWUiUAoPUGF1c2VKb2JSZXF1ZXN0Ej0KBG5hbWUYASABKAlC
KeBBAvpBIwohY2xvdWRzY2hlZHVsZXIuZ29vZ2xlYXBpcy5jb20vSm9iUgRuYW1lIlEKEFJl
c3VtZUpvYlJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91ZHNjaGVkdWxlci5n
b29nbGVhcGlzLmNvbS9Kb2JSBG5hbWUiTgoNUnVuSm9iUmVxdWVzdBI9CgRuYW1lGAEgASgJ
QingQQL6QSMKIWNsb3Vkc2NoZWR1bGVyLmdvb2dsZWFwaXMuY29tL0pvYlIEbmFtZTKzCgoO
Q2xvdWRTY2hlZHVsZXISngEKCExpc3RKb2JzEiouZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52
MS5MaXN0Sm9ic1JlcXVlc3QaKy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkxpc3RKb2Jz
UmVzcG9uc2UiOYLT5JMCKhIoL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0v
am9ic9pBBnBhcmVudBKLAQoGR2V0Sm9iEiguZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5H
ZXRKb2JSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5Kb2IiN4LT5JMCKhIo
L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovam9icy8qfdpBBG5hbWUSnAEKCUNy
ZWF0ZUpvYhIrLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ3JlYXRlSm9iUmVxdWVzdBoe
Lmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSm9iIkKC0+STAi8iKC92MS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyp9L2pvYnM6A2pvYtpBCnBhcmVudCxqb2ISpQEKCVVwZGF0
ZUpvYhIrLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuVXBkYXRlSm9iUmVxdWVzdBoeLmdv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSm9iIkuC0+STAjMyLC92MS97am9iLm5hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyp9OgNqb2LaQQ9qb2IsdXBkYXRlX21hc2sSiQEK
CURlbGV0ZUpvYhIrLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuRGVsZXRlSm9iUmVxdWVz
dBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI3gtPkkwIqKigvdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9qb2JzLyp92kEEbmFtZRKYAQoIUGF1c2VKb2ISKi5nb29nbGUuY2xv
dWQuc2NoZWR1bGVyLnYxLlBhdXNlSm9iUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zY2hlZHVs
ZXIudjEuSm9iIkCC0+STAjMiLi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pv
YnMvKn06cGF1c2U6ASraQQRuYW1lEpsBCglSZXN1bWVKb2ISKy5nb29nbGUuY2xvdWQuc2No
ZWR1bGVyLnYxLlJlc3VtZUpvYlJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYx
LkpvYiJBgtPkkwI0Ii8vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyp9
OnJlc3VtZToBKtpBBG5hbWUSkgEKBlJ1bkpvYhIoLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djEuUnVuSm9iUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSm9iIj6C0+ST
AjEiLC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn06cnVuOgEq2kEE
bmFtZRpRykEdY2xvdWRzY2hlZHVsZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQnoKHWNvbS5nb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxQg5TY2hlZHVsZXJQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL3Nj
aGVkdWxlci9hcGl2MS9zY2hlZHVsZXJwYjtzY2hlZHVsZXJwYqICCVNDSEVEVUxFUkq9QAoH
EgUOAJoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJ
CgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC0K
CQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAUgoJCgIICxIDGgBSCggKAQgSAxsAIgoJ
CgIIChIDGwAiCggKAQgSAxwALwoJCgIICBIDHAAvCggKAQgSAx0ANgoJCgIIARIDHQA2CggK
AQgSAx4AJwoJCgIIJBIDHgAnCmgKAgYAEgUiAIgBARpbIFRoZSBDbG91ZCBTY2hlZHVsZXIg
QVBJIGFsbG93cyBleHRlcm5hbCBlbnRpdGllcyB0byByZWxpYWJseQogc2NoZWR1bGUgYXN5
bmNocm9ub3VzIGpvYnMuCgoKCgMGAAESAyIIFgoKCgMGAAMSAyMCRQoMCgUGAAOZCBIDIwJF
CgsKAwYAAxIEJAIlNwoNCgUGAAOaCBIEJAIlNwobCgQGAAIAEgQoAi0DGg0gTGlzdHMgam9i
cy4KCgwKBQYAAgABEgMoBg4KDAoFBgACAAISAygPHgoMCgUGAAIAAxIDKCk5Cg0KBQYAAgAE
EgQpBCsGChEKCQYAAgAEsMq8IhIEKQQrBgoMCgUGAAIABBIDLAQ0Cg8KCAYAAgAEmwgAEgMs
BDQKGwoEBgACARIEMAI1AxoNIEdldHMgYSBqb2IuCgoMCgUGAAIBARIDMAYMCgwKBQYAAgEC
EgMwDRoKDAoFBgACAQMSAzAlKAoNCgUGAAIBBBIEMQQzBgoRCgkGAAIBBLDKvCISBDEEMwYK
DAoFBgACAQQSAzQEMgoPCggGAAIBBJsIABIDNAQyCh4KBAYAAgISBDgCPgMaECBDcmVhdGVz
IGEgam9iLgoKDAoFBgACAgESAzgGDwoMCgUGAAICAhIDOBAgCgwKBQYAAgIDEgM4Ky4KDQoF
BgACAgQSBDkEPAYKEQoJBgACAgSwyrwiEgQ5BDwGCgwKBQYAAgIEEgM9BDgKDwoIBgACAgSb
CAASAz0EOArOAwoEBgACAxIESgJQAxq/AyBVcGRhdGVzIGEgam9iLgoKIElmIHN1Y2Nlc3Nm
dWwsIHRoZSB1cGRhdGVkIFtKb2JdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSm9iXSBp
cwogcmV0dXJuZWQuIElmIHRoZSBqb2IgZG9lcyBub3QgZXhpc3QsIGBOT1RfRk9VTkRgIGlz
IHJldHVybmVkLgoKIElmIFVwZGF0ZUpvYiBkb2VzIG5vdCBzdWNjZXNzZnVsbHkgcmV0dXJu
LCBpdCBpcyBwb3NzaWJsZSBmb3IgdGhlCiBqb2IgdG8gYmUgaW4gYW4KIFtKb2IuU3RhdGUu
VVBEQVRFX0ZBSUxFRF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5Kb2IuU3RhdGUuVVBE
QVRFX0ZBSUxFRF0KIHN0YXRlLiBBIGpvYiBpbiB0aGlzIHN0YXRlIG1heSBub3QgYmUgZXhl
Y3V0ZWQuIElmIHRoaXMgaGFwcGVucywgcmV0cnkgdGhlCiBVcGRhdGVKb2IgcmVxdWVzdCB1
bnRpbCBhIHN1Y2Nlc3NmdWwgcmVzcG9uc2UgaXMgcmVjZWl2ZWQuCgoMCgUGAAIDARIDSgYP
CgwKBQYAAgMCEgNKECAKDAoFBgACAwMSA0orLgoNCgUGAAIDBBIESwROBgoRCgkGAAIDBLDK
vCISBEsETgYKDAoFBgACAwQSA08EPQoPCggGAAIDBJsIABIDTwQ9Ch4KBAYAAgQSBFMCWAMa
ECBEZWxldGVzIGEgam9iLgoKDAoFBgACBAESA1MGDwoMCgUGAAIEAhIDUxAgCgwKBQYAAgQD
EgNTK0AKDQoFBgACBAQSBFQEVgYKEQoJBgACBASwyrwiEgRUBFYGCgwKBQYAAgQEEgNXBDIK
DwoIBgACBASbCAASA1cEMgrOAwoEBgACBRIEZAJqAxq/AyBQYXVzZXMgYSBqb2IuCgogSWYg
YSBqb2IgaXMgcGF1c2VkIHRoZW4gdGhlIHN5c3RlbSB3aWxsIHN0b3AgZXhlY3V0aW5nIHRo
ZSBqb2IKIHVudGlsIGl0IGlzIHJlLWVuYWJsZWQgdmlhCiBbUmVzdW1lSm9iXVtnb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxLkNsb3VkU2NoZWR1bGVyLlJlc3VtZUpvYl0uIFRoZSBzdGF0
ZQogb2YgdGhlIGpvYiBpcyBzdG9yZWQgaW4gW3N0YXRlXVtnb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxLkpvYi5zdGF0ZV07IGlmCiBwYXVzZWQgaXQgd2lsbCBiZSBzZXQgdG8KIFtKb2Iu
U3RhdGUuUEFVU0VEXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkpvYi5TdGF0ZS5QQVVT
RURdLiBBIGpvYiBtdXN0CiBiZSBpbiBbSm9iLlN0YXRlLkVOQUJMRURdW2dvb2dsZS5jbG91
ZC5zY2hlZHVsZXIudjEuSm9iLlN0YXRlLkVOQUJMRURdIHRvCiBiZSBwYXVzZWQuCgoMCgUG
AAIFARIDZAYOCgwKBQYAAgUCEgNkDx4KDAoFBgACBQMSA2QpLAoNCgUGAAIFBBIEZQRoBgoR
CgkGAAIFBLDKvCISBGUEaAYKDAoFBgACBQQSA2kEMgoPCggGAAIFBJsIABIDaQQyCrMDCgQG
AAIGEgR1AnsDGqQDIFJlc3VtZSBhIGpvYi4KCiBUaGlzIG1ldGhvZCByZWVuYWJsZXMgYSBq
b2IgYWZ0ZXIgaXQgaGFzIGJlZW4KIFtKb2IuU3RhdGUuUEFVU0VEXVtnb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxLkpvYi5TdGF0ZS5QQVVTRURdLiBUaGUgc3RhdGUKIG9mIGEgam9iIGlz
IHN0b3JlZCBpbiBbSm9iLnN0YXRlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkpvYi5z
dGF0ZV07CiBhZnRlciBjYWxsaW5nIHRoaXMgbWV0aG9kIGl0IHdpbGwgYmUgc2V0IHRvCiBb
Sm9iLlN0YXRlLkVOQUJMRURdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSm9iLlN0YXRl
LkVOQUJMRURdLiBBIGpvYgogbXVzdCBiZSBpbiBbSm9iLlN0YXRlLlBBVVNFRF1bZ29vZ2xl
LmNsb3VkLnNjaGVkdWxlci52MS5Kb2IuU3RhdGUuUEFVU0VEXQogdG8gYmUgcmVzdW1lZC4K
CgwKBQYAAgYBEgN1Bg8KDAoFBgACBgISA3UQIAoMCgUGAAIGAxIDdSsuCg0KBQYAAgYEEgR2
BHkGChEKCQYAAgYEsMq8IhIEdgR5BgoMCgUGAAIGBBIDegQyCg8KCAYAAgYEmwgAEgN6BDIK
lQEKBAYAAgcSBoEBAocBAxqEASBGb3JjZXMgYSBqb2IgdG8gcnVuIG5vdy4KCiBXaGVuIHRo
aXMgbWV0aG9kIGlzIGNhbGxlZCwgQ2xvdWQgU2NoZWR1bGVyIHdpbGwgZGlzcGF0Y2ggdGhl
IGpvYiwgZXZlbgogaWYgdGhlIGpvYiBpcyBhbHJlYWR5IHJ1bm5pbmcuCgoNCgUGAAIHARIE
gQEGDAoNCgUGAAIHAhIEgQENGgoNCgUGAAIHAxIEgQElKAoPCgUGAAIHBBIGggEEhQEGChMK
CQYAAgcEsMq8IhIGggEEhQEGCg0KBQYAAgcEEgSGAQQyChAKCAYAAgcEmwgAEgSGAQQyCnYK
AgQAEgaMAQClAQEaaCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGxpc3Rpbmcgam9icyB1c2luZwog
W0xpc3RKb2JzXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkNsb3VkU2NoZWR1bGVyLkxp
c3RKb2JzXS4KCgsKAwQAARIEjAEIFwppCgQEAAIAEgaPAQKUAQQaWSBSZXF1aXJlZC4gVGhl
IGxvY2F0aW9uIG5hbWUuIEZvciBleGFtcGxlOgogYHByb2plY3RzL1BST0pFQ1RfSUQvbG9j
YXRpb25zL0xPQ0FUSU9OX0lEYC4KCg0KBQQAAgAFEgSPAQIICg0KBQQAAgABEgSPAQkPCg0K
BQQAAgADEgSPARITCg8KBQQAAgAIEgaPARSUAQMKEAoIBAACAAicCAASBJABBCoKEQoHBAAC
AAifCBIGkQEEkwEFCvYBCgQEAAIBEgScAQIWGucBIFJlcXVlc3RlZCBwYWdlIHNpemUuCgog
VGhlIG1heGltdW0gcGFnZSBzaXplIGlzIDUwMC4gSWYgdW5zcGVjaWZpZWQsIHRoZSBwYWdl
IHNpemUgd2lsbAogYmUgdGhlIG1heGltdW0uIEZld2VyIGpvYnMgdGhhbiByZXF1ZXN0ZWQg
bWlnaHQgYmUgcmV0dXJuZWQsCiBldmVuIGlmIG1vcmUgam9icyBleGlzdDsgdXNlIG5leHRf
cGFnZV90b2tlbiB0byBkZXRlcm1pbmUgaWYgbW9yZQogam9icyBleGlzdC4KCg0KBQQAAgEF
EgScAQIHCg0KBQQAAgEBEgScAQgRCg0KBQQAAgEDEgScARQVCoUDCgQEAAICEgSkAQIYGvYC
IEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciB3aWxs
IHJldHVybi4gVG8KIHJlcXVlc3QgdGhlIGZpcnN0IHBhZ2UgcmVzdWx0cywgcGFnZV90b2tl
biBtdXN0IGJlIGVtcHR5LiBUbwogcmVxdWVzdCB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMs
IHBhZ2VfdG9rZW4gbXVzdCBiZSB0aGUgdmFsdWUgb2YKIFtuZXh0X3BhZ2VfdG9rZW5dW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuTGlzdEpvYnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9r
ZW5dCiByZXR1cm5lZCBmcm9tIHRoZSBwcmV2aW91cyBjYWxsIHRvCiBbTGlzdEpvYnNdW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuTGlzdEpvYnNdLgoKDQoF
BAACAgUSBKQBAggKDQoFBAACAgESBKQBCRMKDQoFBAACAgMSBKQBFhcKdwoCBAESBqkBALYB
ARppIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIGxpc3Rpbmcgam9icyB1c2luZwogW0xpc3RKb2Jz
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkNsb3VkU2NoZWR1bGVyLkxpc3RKb2JzXS4K
CgsKAwQBARIEqQEIGAohCgQEAQIAEgSrAQIYGhMgVGhlIGxpc3Qgb2Ygam9icy4KCg0KBQQB
AgAEEgSrAQIKCg0KBQQBAgAGEgSrAQsOCg0KBQQBAgABEgSrAQ8TCg0KBQQBAgADEgSrARYX
CqEDCgQEAQIBEgS1AQIdGpIDIEEgdG9rZW4gdG8gcmV0cmlldmUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMuIFBhc3MgdGhpcyB2YWx1ZSBpbiB0aGUKIFtwYWdlX3Rva2VuXVtnb29nbGUuY2xv
dWQuc2NoZWR1bGVyLnYxLkxpc3RKb2JzUmVxdWVzdC5wYWdlX3Rva2VuXSBmaWVsZCBpbgog
dGhlIHN1YnNlcXVlbnQgY2FsbCB0bwogW0xpc3RKb2JzXVtnb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxLkNsb3VkU2NoZWR1bGVyLkxpc3RKb2JzXSB0byByZXRyaWV2ZQogdGhlIG5leHQg
cGFnZSBvZiByZXN1bHRzLiBJZiB0aGlzIGlzIGVtcHR5IGl0IGluZGljYXRlcyB0aGF0IHRo
ZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIHRocm91Z2ggd2hpY2ggdG8gcGFnaW5hdGUuCgog
VGhlIHBhZ2UgdG9rZW4gaXMgdmFsaWQgZm9yIG9ubHkgMiBob3Vycy4KCg0KBQQBAgEFEgS1
AQIICg0KBQQBAgEBEgS1AQkYCg0KBQQBAgEDEgS1ARscCl8KAgQCEga6AQDDAQEaUSBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbR2V0Sm9iXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkNs
b3VkU2NoZWR1bGVyLkdldEpvYl0uCgoLCgMEAgESBLoBCBUKcAoEBAICABIGvQECwgEEGmAg
UmVxdWlyZWQuIFRoZSBqb2IgbmFtZS4gRm9yIGV4YW1wbGU6CiBgcHJvamVjdHMvUFJPSkVD
VF9JRC9sb2NhdGlvbnMvTE9DQVRJT05fSUQvam9icy9KT0JfSURgLgoKDQoFBAICAAUSBL0B
AggKDQoFBAICAAESBL0BCQ0KDQoFBAICAAMSBL0BEBEKDwoFBAICAAgSBr0BEsIBAwoQCggE
AgIACJwIABIEvgEEKgoRCgcEAgIACJ8IEga/AQTBAQUKZQoCBAMSBscBANgBARpXIFJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtDcmVhdGVKb2JdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEu
Q2xvdWRTY2hlZHVsZXIuQ3JlYXRlSm9iXS4KCgsKAwQDARIExwEIGAppCgQEAwIAEgbKAQLP
AQQaWSBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIG5hbWUuIEZvciBleGFtcGxlOgogYHByb2pl
Y3RzL1BST0pFQ1RfSUQvbG9jYXRpb25zL0xPQ0FUSU9OX0lEYC4KCg0KBQQDAgAFEgTKAQII
Cg0KBQQDAgABEgTKAQkPCg0KBQQDAgADEgTKARITCg8KBQQDAgAIEgbKARTPAQMKEAoIBAMC
AAicCAASBMsBBCoKEQoHBAMCAAifCBIGzAEEzgEFCoUDCgQEAwIBEgTXAQI3GvYCIFJlcXVp
cmVkLiBUaGUgam9iIHRvIGFkZC4gVGhlIHVzZXIgY2FuIG9wdGlvbmFsbHkgc3BlY2lmeSBh
IG5hbWUgZm9yIHRoZQogam9iIGluIFtuYW1lXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYx
LkpvYi5uYW1lXS4KIFtuYW1lXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkpvYi5uYW1l
XSBjYW5ub3QgYmUgdGhlIHNhbWUgYXMgYW4KIGV4aXN0aW5nIGpvYi4gSWYgYSBuYW1lIGlz
IG5vdCBzcGVjaWZpZWQgdGhlbiB0aGUgc3lzdGVtIHdpbGwKIGdlbmVyYXRlIGEgcmFuZG9t
IHVuaXF1ZSBuYW1lIHRoYXQgd2lsbCBiZSByZXR1cm5lZAogKFtuYW1lXVtnb29nbGUuY2xv
dWQuc2NoZWR1bGVyLnYxLkpvYi5uYW1lXSkgaW4gdGhlIHJlc3BvbnNlLgoKDQoFBAMCAQYS
BNcBAgUKDQoFBAMCAQESBNcBBgkKDQoFBAMCAQMSBNcBDA0KDQoFBAMCAQgSBNcBDjYKEAoI
BAMCAQicCAASBNcBDzUKZQoCBAQSBtwBAOYBARpXIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtV
cGRhdGVKb2JdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuVXBk
YXRlSm9iXS4KCgsKAwQEARIE3AEIGArpAQoEBAQCABIE4gECNxraASBSZXF1aXJlZC4gVGhl
IG5ldyBqb2IgcHJvcGVydGllcy4KIFtuYW1lXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYx
LkpvYi5uYW1lXSBtdXN0IGJlIHNwZWNpZmllZC4KCiBPdXRwdXQgb25seSBmaWVsZHMgY2Fu
bm90IGJlIG1vZGlmaWVkIHVzaW5nIFVwZGF0ZUpvYi4KIEFueSB2YWx1ZSBzcGVjaWZpZWQg
Zm9yIGFuIG91dHB1dCBvbmx5IGZpZWxkIHdpbGwgYmUgaWdub3JlZC4KCg0KBQQEAgAGEgTi
AQIFCg0KBQQEAgABEgTiAQYJCg0KBQQEAgADEgTiAQwNCg0KBQQEAgAIEgTiAQ42ChAKCAQE
AgAInAgAEgTiAQ81ClIKBAQEAgESBOUBAiwaRCBBICBtYXNrIHVzZWQgdG8gc3BlY2lmeSB3
aGljaCBmaWVsZHMgb2YgdGhlIGpvYiBhcmUgYmVpbmcgdXBkYXRlZC4KCg0KBQQEAgEGEgTl
AQIbCg0KBQQEAgEBEgTlARwnCg0KBQQEAgEDEgTlASorCnoKAgQFEgbqAQDzAQEabCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEgam9iIHVzaW5nCiBbRGVsZXRlSm9iXVtnb29n
bGUuY2xvdWQuc2NoZWR1bGVyLnYxLkNsb3VkU2NoZWR1bGVyLkRlbGV0ZUpvYl0uCgoLCgME
BQESBOoBCBgKcAoEBAUCABIG7QEC8gEEGmAgUmVxdWlyZWQuIFRoZSBqb2IgbmFtZS4gRm9y
IGV4YW1wbGU6CiBgcHJvamVjdHMvUFJPSkVDVF9JRC9sb2NhdGlvbnMvTE9DQVRJT05fSUQv
am9icy9KT0JfSURgLgoKDQoFBAUCAAUSBO0BAggKDQoFBAUCAAESBO0BCQ0KDQoFBAUCAAMS
BO0BEBEKDwoFBAUCAAgSBu0BEvIBAwoQCggEBQIACJwIABIE7gEEKgoRCgcEBQIACJ8IEgbv
AQTxAQUKYwoCBAYSBvcBAIACARpVIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtQYXVzZUpvYl1b
Z29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5DbG91ZFNjaGVkdWxlci5QYXVzZUpvYl0uCgoL
CgMEBgESBPcBCBcKcAoEBAYCABIG+gEC/wEEGmAgUmVxdWlyZWQuIFRoZSBqb2IgbmFtZS4g
Rm9yIGV4YW1wbGU6CiBgcHJvamVjdHMvUFJPSkVDVF9JRC9sb2NhdGlvbnMvTE9DQVRJT05f
SUQvam9icy9KT0JfSURgLgoKDQoFBAYCAAUSBPoBAggKDQoFBAYCAAESBPoBCQ0KDQoFBAYC
AAMSBPoBEBEKDwoFBAYCAAgSBvoBEv8BAwoQCggEBgIACJwIABIE+wEEKgoRCgcEBgIACJ8I
Egb8AQT+AQUKZQoCBAcSBoQCAI0CARpXIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtSZXN1bWVK
b2JdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuUmVzdW1lSm9i
XS4KCgsKAwQHARIEhAIIGApwCgQEBwIAEgaHAgKMAgQaYCBSZXF1aXJlZC4gVGhlIGpvYiBu
YW1lLiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NB
VElPTl9JRC9qb2JzL0pPQl9JRGAuCgoNCgUEBwIABRIEhwICCAoNCgUEBwIAARIEhwIJDQoN
CgUEBwIAAxIEhwIQEQoPCgUEBwIACBIGhwISjAIDChAKCAQHAgAInAgAEgSIAgQqChEKBwQH
AgAInwgSBokCBIsCBQp+CgIECBIGkQIAmgIBGnAgUmVxdWVzdCBtZXNzYWdlIGZvciBmb3Jj
aW5nIGEgam9iIHRvIHJ1biBub3cgdXNpbmcKIFtSdW5Kb2JdW2dvb2dsZS5jbG91ZC5zY2hl
ZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuUnVuSm9iXS4KCgsKAwQIARIEkQIIFQpwCgQECAIA
EgaUAgKZAgQaYCBSZXF1aXJlZC4gVGhlIGpvYiBuYW1lLiBGb3IgZXhhbXBsZToKIGBwcm9q
ZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElPTl9JRC9qb2JzL0pPQl9JRGAuCgoN
CgUECAIABRIElAICCAoNCgUECAIAARIElAIJDQoNCgUECAIAAxIElAIQEQoPCgUECAIACBIG
lAISmQIDChAKCAQIAgAInAgAEgSVAgQqChEKBwQIAgAInwgSBpYCBJgCBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsRequest ===
    # Fields for ListJobsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsResponse ===
    # Fields for ListJobsResponse
    # Field: jobs Type: 11 (.google.cloud.scheduler.v1.Job)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::GetJobRequest ===
    # Fields for GetJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::CreateJobRequest ===
    # Fields for CreateJobRequest
    # Field: parent Type: 9 ()
    # Field: job Type: 11 (.google.cloud.scheduler.v1.Job)

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::UpdateJobRequest ===
    # Fields for UpdateJobRequest
    # Field: job Type: 11 (.google.cloud.scheduler.v1.Job)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::DeleteJobRequest ===
    # Fields for DeleteJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::PauseJobRequest ===
    # Fields for PauseJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::ResumeJobRequest ===
    # Fields for ResumeJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Cloudscheduler::RunJobRequest ===
    # Fields for RunJobRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Scheduler::V1::Cloudscheduler::CloudSchedulerClient ===
package Google::Cloud::Scheduler::V1::Cloudscheduler::CloudSchedulerClient;

=pod

=head2 Service Client: Google::Cloud::Scheduler::V1::Cloudscheduler::CloudSchedulerClient

Client stub representing the remote C<CloudScheduler> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<scheduler.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'scheduler.googleapis.com:443' );

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

sub list_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'ListJobs',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsResponse',
    });
}

sub get_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::GetJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'GetJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

sub create_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::CreateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'CreateJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

sub update_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::UpdateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'UpdateJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

sub delete_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::DeleteJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'DeleteJob',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub pause_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::PauseJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'PauseJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

sub resume_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::ResumeJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'ResumeJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

sub run_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1::Cloudscheduler::RunJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1.CloudScheduler',
        method         => 'RunJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1::Job::Job',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Scheduler::V1::Cloudscheduler - Compiled Protocol Buffers messages for google/cloud/scheduler/v1/cloudscheduler.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1::Cloudscheduler;

    my $msg = Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1/cloudscheduler.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsRequest

Request message for listing jobs using
[ListJobs][google.cloud.scheduler.v1.CloudScheduler.ListJobs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size.

The maximum page size is 500. If unspecified, the page size will
be the maximum. Fewer jobs than requested might be returned,
even if more jobs exist; use next_page_token to determine if more
jobs exist.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server will return. To
request the first page results, page_token must be empty. To
request the next page of results, page_token must be the value of
[next_page_token][google.cloud.scheduler.v1.ListJobsResponse.next_page_token]
returned from the previous call to
[ListJobs][google.cloud.scheduler.v1.CloudScheduler.ListJobs].

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::ListJobsResponse

Response message for listing jobs using
[ListJobs][google.cloud.scheduler.v1.CloudScheduler.ListJobs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Job::Job>)

The list of jobs.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve next page of results. Pass this value in the
[page_token][google.cloud.scheduler.v1.ListJobsRequest.page_token] field in
the subsequent call to
[ListJobs][google.cloud.scheduler.v1.CloudScheduler.ListJobs] to retrieve
the next page of results. If this is empty it indicates that there are no
more results through which to paginate.

The page token is valid for only 2 hours.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::GetJobRequest

Request message for
[GetJob][google.cloud.scheduler.v1.CloudScheduler.GetJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::CreateJobRequest

Request message for
[CreateJob][google.cloud.scheduler.v1.CloudScheduler.CreateJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID`.

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Job::Job>)

Required. The job to add. The user can optionally specify a name for the
job in [name][google.cloud.scheduler.v1.Job.name].
[name][google.cloud.scheduler.v1.Job.name] cannot be the same as an
existing job. If a name is not specified then the system will
generate a random unique name that will be returned
([name][google.cloud.scheduler.v1.Job.name]) in the response.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::UpdateJobRequest

Request message for
[UpdateJob][google.cloud.scheduler.v1.CloudScheduler.UpdateJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Job::Job>)

Required. The new job properties.
[name][google.cloud.scheduler.v1.Job.name] must be specified.

Output only fields cannot be modified using UpdateJob.
Any value specified for an output only field will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A  mask used to specify which fields of the job are being updated.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::DeleteJobRequest

Request message for deleting a job using
[DeleteJob][google.cloud.scheduler.v1.CloudScheduler.DeleteJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::PauseJobRequest

Request message for
[PauseJob][google.cloud.scheduler.v1.CloudScheduler.PauseJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::ResumeJobRequest

Request message for
[ResumeJob][google.cloud.scheduler.v1.CloudScheduler.ResumeJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1::Cloudscheduler::RunJobRequest

Request message for forcing a job to run now using
[RunJob][google.cloud.scheduler.v1.CloudScheduler.RunJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1::Cloudscheduler::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
