package Google::Watcher::V1::Watch;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ch1nb29nbGUvd2F0Y2hlci92MS93YXRjaC5wcm90bxIRZ29vZ2xlLndhdGNoZXIudjEaHGdv
b2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8a
G2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90byJGCgdSZXF1ZXN0EhYKBnRhcmdldBgBIAEo
CVIGdGFyZ2V0EiMKDXJlc3VtZV9tYXJrZXIYAiABKAxSDHJlc3VtZU1hcmtlciJCCgtDaGFu
Z2VCYXRjaBIzCgdjaGFuZ2VzGAEgAygLMhkuZ29vZ2xlLndhdGNoZXIudjEuQ2hhbmdlUgdj
aGFuZ2VzIpUCCgZDaGFuZ2USGAoHZWxlbWVudBgBIAEoCVIHZWxlbWVudBI1CgVzdGF0ZRgC
IAEoDjIfLmdvb2dsZS53YXRjaGVyLnYxLkNoYW5nZS5TdGF0ZVIFc3RhdGUSKAoEZGF0YRgG
IAEoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlSBGRhdGESIwoNcmVzdW1lX21hcmtlchgEIAEo
DFIMcmVzdW1lTWFya2VyEhwKCWNvbnRpbnVlZBgFIAEoCFIJY29udGludWVkIk0KBVN0YXRl
EgoKBkVYSVNUUxAAEhIKDkRPRVNfTk9UX0VYSVNUEAESGQoVSU5JVElBTF9TVEFURV9TS0lQ
UEVEEAISCQoFRVJST1IQAzJjCgdXYXRjaGVyElgKBVdhdGNoEhouZ29vZ2xlLndhdGNoZXIu
djEuUmVxdWVzdBoeLmdvb2dsZS53YXRjaGVyLnYxLkNoYW5nZUJhdGNoIhGC0+STAgsSCS92
MS93YXRjaDABQl8KFWNvbS5nb29nbGUud2F0Y2hlci52MUIKV2F0Y2hQcm90b1ABWjhnb29n
bGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL3dhdGNoZXIvdjE7d2F0Y2hlckqF
YwoHEgUOAJwCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
GgoJCgIDABIDEgAmCgkKAgMBEgMTACMKCQoCAwISAxQAJQoICgEIEgMWAE8KCQoCCAsSAxYA
TwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYACsKCQoCCAgSAxgAKwoICgEIEgMZAC4K
CQoCCAESAxkALgr8MwoCBgASBqUBAKwBARqiASBUaGUgc2VydmljZSB0aGF0IGEgY2xpZW50
IHVzZXMgdG8gY29ubmVjdCB0byB0aGUgd2F0Y2hlciBzeXN0ZW0uCiBUaGUgZXJyb3JzIHJl
dHVybmVkIGJ5IHRoZSBzZXJ2aWNlIGFyZSBpbiB0aGUgY2Fub25pY2FsIGVycm9yIHNwYWNl
LAogc2VlIFtnb29nbGUucnBjLkNvZGVdW10uCjLIMiAjIyBBUEkgT3ZlcnZpZXcKCiBbV2F0
Y2hlcl1bXSBsZXRzIGEgY2xpZW50IHdhdGNoIGZvciB1cGRhdGVzIHRvIGEgbmFtZWQgZW50
aXR5LCBzdWNoIGFzIGEKIGRpcmVjdG9yeSBvciBkYXRhYmFzZSB0YWJsZS4gRm9yIGVhY2gg
d2F0Y2hlZCBlbnRpdHksIHRoZSBjbGllbnQgcmVjZWl2ZXMgYQogcmVsaWFibGUgc3RyZWFt
IG9mIHdhdGNoIGV2ZW50cywgd2l0aG91dCByZS1vcmRlcmluZy4KCiBXYXRjaGluZyBpcyBk
b25lIGJ5IHNlbmRpbmcgYW4gUlBDIHRvIGEgc2VydmljZSB0aGF0IGltcGxlbWVudHMgdGhl
IEFQSS4gVGhlCiBhcmd1bWVudCB0byB0aGUgUlBDIGNvbnRhaW5zIHRoZSBuYW1lIG9mIHRo
ZSBlbnRpdHkuIFRoZSByZXN1bHQgc3RyZWFtCiBjb25zaXN0cyBvZiBhIHNlcXVlbmNlIG9m
IENoYW5nZSBtZXNzYWdlcyB0aGF0IHRoZSBzZXJ2aWNlIGNvbnRpbnVlcyB0bwogc2VuZCB1
bnRpbCB0aGUgY2FsbCBmYWlscyBvciBpcyBjYW5jZWxsZWQuCgogIyMgRGF0YSBtb2RlbAoK
IFRoaXMgQVBJIGFzc3VtZXMgdGhhdCBlYWNoICplbnRpdHkqIGhhcyBhIG5hbWUgYW5kIGEK
IHNldCBvZiAqZWxlbWVudHMqLCB3aGVyZSBlYWNoIGVsZW1lbnQgaGFzIGEgbmFtZSBhbmQg
YSB2YWx1ZS4gVGhlCiBlbnRpdHkncyBuYW1lIG11c3QgYmUgYSB1bmlxdWUgaWRlbnRpZmll
ciB3aXRoaW4gdGhlIHNlcnZpY2UsIHN1Y2ggYXMKIGEgcmVzb3VyY2UgbmFtZS4gV2hhdCBj
b25zdGl0dXRlcyBhbiBlbnRpdHkgb3IgZWxlbWVudCBpcwogaW1wbGVtZW50YXRpb24tc3Bl
Y2lmaWM6IGZvciBleGFtcGxlLCBhIGZpbGUgc3lzdGVtIGltcGxlbWVudGF0aW9uCiBtaWdo
dCBkZWZpbmUgYW4gZW50aXR5IGFzIGVpdGhlciBhIGRpcmVjdG9yeSBvciBhIGZpbGUsIGFu
ZCBlbGVtZW50cyB3b3VsZCBiZQogY2hpbGQgZmlsZXMgb3IgZGlyZWN0b3JpZXMgb2YgdGhh
dCBlbnRpdHkuCgogVGhlIFdhdGNoIEFQSSBhbGxvd3MgYSBjbGllbnQgdG8gd2F0Y2ggYW4g
ZW50aXR5IEUncyBpbW1lZGlhdGUKIGVsZW1lbnRzIG9yIHRoZSB3aG9sZSB0cmVlIHJvb3Rl
ZCBhdCBFLiBFbGVtZW50cyBhcmUgb3JnYW5pemVkIGludG8KIGEgaGllcmFyY2h5ICgiIiBh
dCB0aGUgdG9wOyB0aGUgcmVzdCBmb2xsb3dzIHRoZSBuYXR1cmFsIGhpZXJhcmNoeSBvZiB0
aGUKIG5hbWVzcGFjZSBvZiBlbGVtZW50cyB0aGF0IGlzIGJlaW5nIHdhdGNoZWQpLiBGb3Ig
ZXhhbXBsZSwgd2hlbgogcmVjdXJzaXZlbHkgd2F0Y2hpbmcgYSBmaWxlc3lzdGVtIG5hbWVz
cGFjZSwgWCBpcyBhbiBhbmNlc3RvciBvZgogWC9ZIGFuZCBYL1kvWikuCgogIyMgV2F0Y2gg
cmVxdWVzdAoKIFdoZW4gYSBjbGllbnQgbWFrZXMgYSByZXF1ZXN0IHRvIHdhdGNoIGFuIGVu
dGl0eSwgaXQgY2FuIGluZGljYXRlCiB3aGV0aGVyIGl0IHdhbnRzIHRvIHJlY2VpdmUgdGhl
IGluaXRpYWwgc3RhdGUgb2YgdGhlIGVudGl0eSwganVzdAogbmV3IGNoYW5nZXMgdG8gdGhl
IGVudGl0eSwgb3IgcmVzdW1lIHdhdGNoaW5nIGZyb20gYSBwYXJ0aWN1bGFyCiBwb2ludCBp
biBhIHByZXZpb3VzIHdhdGNoIHN0cmVhbSwgc3BlY2lmaWVkIHdpdGggYSBgcmVzdW1lX21h
cmtlcmAgdmFsdWUuCiBJdCBjYW4gYWxzbyBpbmRpY2F0ZSB3aGV0aGVyIGl0IHdhbnRzIHRv
IHdhdGNoIG9ubHkgb25lIGVudGl0eSBvciBhbGwKIGVudGl0aWVzIGluIHRoZSBzdWJ0cmVl
IHJvb3RlZCBhdCBhIHBhcnRpY3VsYXIgZW50aXR5J3MgbmFtZS4KCiBPbiByZWNlaXZpbmcg
YSB3YXRjaCByZXF1ZXN0IGZvciBhbiBlbnRpdHksIHRoZSBzZXJ2ZXIgc2VuZHMgb25lIG9y
IG1vcmUKIG1lc3NhZ2VzIHRvIHRoZSBjbGllbnQuIFRoZSBmaXJzdCBtZXNzYWdlIGluZm9y
bXMgdGhlIGNsaWVudCB0aGF0IHRoZSBzZXJ2ZXIKIGhhcyByZWdpc3RlcmVkIHRoZSBjbGll
bnQncyByZXF1ZXN0OiB0aGUgaW5zdGFudCBvZiB0aW1lIHdoZW4gdGhlCiBjbGllbnQgcmVj
ZWl2ZXMgdGhlIGV2ZW50IGlzIHJlZmVycmVkIHRvIGFzIHRoZSBjbGllbnQncyAid2F0Y2gK
IHBvaW50IiBmb3IgdGhhdCBlbnRpdHkuCgogIyMgQXRvbWljIGRlbGl2ZXJ5CgogVGhlIHJl
c3BvbnNlIHN0cmVhbSBjb25zaXN0cyBvZiBhIHNlcXVlbmNlIG9mIENoYW5nZSBtZXNzYWdl
cy4gRWFjaAogbWVzc2FnZSBjb250YWlucyBhbiBgY29udGludWVkYCBiaXQuIEEgc3ViLXNl
cXVlbmNlIG9mIENoYW5nZSBtZXNzYWdlcyB3aXRoCiBgY29udGludWVkPXRydWVgIGZvbGxv
d2VkIGJ5IGEgQ2hhbmdlIG1lc3NhZ2Ugd2l0aCBgY29udGludWVkPWZhbHNlYCBmb3JtcyBh
bgogKmF0b21pYyBncm91cCouIFN5c3RlbXMgdGhhdCBzdXBwb3J0IG11bHRpLWVsZW1lbnQg
YXRvbWljIHVwZGF0ZXMgbWF5CiBndWFyYW50ZWUgdGhhdCBhbGwgY2hhbmdlcyByZXN1bHRp
bmcgZnJvbSBhIHNpbmdsZSBhdG9taWMKIHVwZGF0ZSBhcmUgZGVsaXZlcmVkIGluIHRoZSBz
YW1lIGF0b21pYyBncm91cC4gSXQgaXMgdXAgdG8gdGhlCiBkb2N1bWVudGF0aW9uIG9mIGEg
cGFydGljdWxhciBzeXN0ZW0gdGhhdCBpbXBsZW1lbnRzIHRoZSBXYXRjaCBBUEkgdG8KIGRv
Y3VtZW50IHdoZXRoZXIgb3Igbm90IGl0IHN1cHBvcnRzIHN1Y2ggZ3JvdXBpbmcuIFdlIGV4
cGVjdCB0aGF0IG1vc3QKIGNhbGxlcnMgd2lsbCBpZ25vcmUgdGhlIG5vdGlvbiBvZiBhdG9t
aWMgZGVsaXZlcnkgYW5kIHRoZSBgY29udGludWVkYCBiaXQsCiBpLmUuLCB0aGV5IHdpbGwg
anVzdCBwcm9jZXNzIGVhY2ggQ2hhbmdlIG1lc3NhZ2UgYXMgaXQgaXMgcmVjZWl2ZWQuCgog
IyMgQmF0Y2hpbmcKCiBNdWx0aXBsZSBDaGFuZ2UgbWVzc2FnZXMgbWF5IGJlIGdyb3VwZWQg
aW50byBhIHNpbmdsZSBDaGFuZ2VCYXRjaCBtZXNzYWdlCiB0byByZWR1Y2UgbWVzc2FnZSB0
cmFuc2ZlciBvdmVyaGVhZC4gQSBzaW5nbGUgQ2hhbmdlQmF0Y2ggbWF5IGNvbnRhaW4gbWFu
eQogYXRvbWljIGdyb3Vwcywgb3IgYSBzaW5nbGUgYXRvbWljIGdyb3VwIG1heSBiZSBzcGxp
dCBhY3Jvc3MgbWFueQogQ2hhbmdlQmF0Y2ggbWVzc2FnZXMuCgogIyMgSW5pdGlhbCBTdGF0
ZQoKIFRoZSBmaXJzdCBhdG9taWMgZ3JvdXAgZGVsaXZlcmVkIGJ5IGEgd2F0Y2ggY2FsbCBp
cyBzcGVjaWFsLiBJdCBpcwogZGVsaXZlcmVkIGFzIHNvb24gYXMgcG9zc2libGUgYW5kIGNv
bnRhaW5zIHRoZSBpbml0aWFsIHN0YXRlIG9mIHRoZQogZW50aXR5IGJlaW5nIHdhdGNoZWQu
IFRoZSBjbGllbnQgc2hvdWxkIGNvbnNpZGVyIGl0c2VsZiBjYXVnaHQgdXAKIGFmdGVyIHBy
b2Nlc3NpbmcgdGhpcyBmaXJzdCBhdG9taWMgZ3JvdXAuCgogVGhlIG1lc3NhZ2VzIGluIHRo
ZSBmaXJzdCBhdG9taWMgZ3JvdXAgd2lsbCBlaXRoZXIgcmVmZXIgdG8gdGhlCiBlbnRpdHkg
aXRzZWxmIChgQ2hhbmdlLmVsZW1lbnRgID09ICIiKSBvciB0byBlbGVtZW50cyBpbnNpZGUg
dGhlCiBlbnRpdHkgKGBDaGFuZ2UuZWxlbWVudGAgIT0gIiIpLiBIZXJlIGFyZSB0aGUgY2Fz
ZXMgdG8gY29uc2lkZXI6CgogMS4gYHJlc3VtZV9tYXJrZXJgIGlzICIiIG9yIG5vdCBzcGVj
aWZpZWQ6IEZvciBldmVyeSBlbGVtZW50IFAKICAgIChpbmNsdWRpbmcgdGhlIGVudGl0eSBp
dHNlbGYpIHRoYXQgZXhpc3RzLCB0aGVyZSB3aWxsIGJlIGF0IGxlYXN0CiAgICBvbmUgbWVz
c2FnZSBkZWxpdmVyZWQgd2l0aCBlbGVtZW50ID09IFAgYW5kIHRoZSBsYXN0IHN1Y2ggbWVz
c2FnZQogICAgd2lsbCBjb250YWluIHRoZSBjdXJyZW50IHN0YXRlIG9mIFAuIEZvciBldmVy
eSBlbGVtZW50IFEKICAgIChpbmNsdWRpbmcgdGhlIGVudGl0eSBpdHNlbGYpIHRoYXQgZG9l
cyBub3QgZXhpc3QsIGVpdGhlciBubwogICAgbWVzc2FnZSB3aWxsIGJlIGRlbGl2ZXJlZCwg
b3IgdGhlIGxhc3QgbWVzc2FnZSBmb3IgUSB3aWxsIGhhdmUKICAgIHN0YXRlID09IERPRVNf
Tk9UX0VYSVNULiBBdCBsZWFzdCBvbmUgbWVzc2FnZSBmb3IgZWxlbWVudD0iIiB3aWxsCiAg
ICBiZSBkZWxpdmVyZWQuCgogMi4gYHJlc3VtZV9tYXJrZXJgID09ICJub3ciOiB0aGVyZSB3
aWxsIGJlIGV4YWN0bHkgb25lIG1lc3NhZ2Ugd2l0aAogICAgZWxlbWVudCA9ICIiIGFuZCBz
dGF0ZSBJTklUSUFMX1NUQVRFX1NLSVBQRUQuIFRoZSBjbGllbnQgY2Fubm90CiAgICBhc3N1
bWUgd2hldGhlciBvciBub3QgdGhlIGVudGl0eSBleGlzdHMgYWZ0ZXIgcmVjZWl2aW5nIHRo
aXMKICAgIG1lc3NhZ2UuCgogMy4gYHJlc3VtZV9tYXJrZXJgIGhhcyBhIHZhbHVlIFIgZnJv
bSBhIHByZWNlZGluZyB3YXRjaCBjYWxsIG9uIHRoaXMKICAgIGVudGl0eTogVGhlIHNhbWUg
bWVzc2FnZXMgYXMgZGVzY3JpYmVkIGluICgxKSB3aWxsIGJlIGRlbGl2ZXJlZCB0bwogICAg
dGhlIGNsaWVudCwgZXhjZXB0IHRoYXQgYW55IGluZm9ybWF0aW9uIGltcGxpZWQgYnkgbWVz
c2FnZXMgcmVjZWl2ZWQKICAgIG9uIHRoZSBwcmVjZWRpbmcgY2FsbCB1cCB0byBhbmQgaW5j
bHVkaW5nIFIgbWF5IG5vdCBiZQogICAgZGVsaXZlcmVkLiBUaGUgZXhwZWN0YXRpb24gaXMg
dGhhdCB0aGUgY2xpZW50IHdpbGwgc3RhcnQgd2l0aCBzdGF0ZQogICAgaXQgaGFkIGJ1aWx0
IHVwIGZyb20gdGhlIHByZWNlZGluZyB3YXRjaCBjYWxsLCBhcHBseSB0aGUgY2hhbmdlcwog
ICAgcmVjZWl2ZWQgZnJvbSB0aGlzIGNhbGwsIGFuZCBidWlsZCBhbiB1cC10by1kYXRlIHZp
ZXcgb2YgdGhlIGVudGl0eQogICAgd2l0aG91dCBoYXZpbmcgdG8gZmV0Y2ggYSBwb3RlbnRp
YWxseSBsYXJnZSBhbW91bnQgb2YgaW5mb3JtYXRpb24KICAgIHRoYXQgaGFzIG5vdCBjaGFu
Z2VkLiBOb3RlIHRoYXQgc29tZSBpbmZvcm1hdGlvbiB0aGF0IGhhZCBhbHJlYWR5CiAgICBi
ZWVuIGRlbGl2ZXJlZCBieSB0aGUgcHJlY2VkaW5nIGNhbGwgbWlnaHQgYmUgZGVsaXZlcmVk
IGFnYWluLgoKICMjIE9yZGVyaW5nIGFuZCBSZWxpYWJpbGl0eQoKIFRoZSBDaGFuZ2UgbWVz
c2FnZXMgdGhhdCBhcHBseSB0byBhIHBhcnRpY3VsYXIgZWxlbWVudCBvZiB0aGUgZW50aXR5
IGFyZQogZGVsaXZlcmVkIGV2ZW50dWFsbHkgaW4gb3JkZXIgd2l0aG91dCBsb3NzIGZvciB0
aGUgZHVyYXRpb24gb2YgdGhlIFJQQy4gTm90ZQogaG93ZXZlciB0aGF0IGlmIG11bHRpcGxl
IENoYW5nZXMgYXBwbHkgdG8gdGhlIHNhbWUgZWxlbWVudCwgdGhlCiBpbXBsZW1lbnRhdGlv
biBpcyBmcmVlIHRvIHN1cHByZXNzIHRoZW0gYW5kIGRlbGl2ZXIganVzdCB0aGUgbGFzdCBv
bmUuIFRoZQogdW5kZXJseWluZyBzeXN0ZW0gbXVzdCBwcm92aWRlIHRoZSBndWFyYW50ZWUg
dGhhdCBhbnkgcmVsZXZhbnQgdXBkYXRlCiByZWNlaXZlZCBmb3IgYW4gZW50aXR5IEUgYWZ0
ZXIgYSBjbGllbnQncyB3YXRjaCBwb2ludCBmb3IgRSBNVVNUIGJlIGRlbGl2ZXJlZAogdG8g
dGhhdCBjbGllbnQuCgogVGhlc2UgdGlnaHQgZ3VhcmFudGVlcyBhbGxvdyBmb3IgdGhlIGZv
bGxvd2luZyBzaW1wbGlmaWNhdGlvbnMgaW4gdGhlIGNsaWVudDoKCiAgIDEuIFRoZSBjbGll
bnQgZG9lcyBub3QgbmVlZCB0byBoYXZlIGEgc2VwYXJhdGUgcG9sbGluZyBsb29wIHRvIG1h
a2UgdXAgZm9yCiAgICAgIG1pc3NlZCB1cGRhdGVzLgoKICAgMi4gVGhlIGNsaWVudCBkb2Vz
IG5vdCBuZWVkIHRvIG1hbmFnZSB0aW1lc3RhbXBzL3ZlcnNpb25zIG1hbnVhbGx5OyB0aGUK
ICAgICAgbGFzdCB1cGRhdGUgZGVsaXZlcmVkIGNvcnJlc3BvbmRzIHRvIHRoZSBldmVudHVh
bCBzdGF0ZSBvZiB0aGUgZW50aXR5LgoKIEV4YW1wbGU6IGEgY2FsZW5kYXIgZW50cnkgbWF5
IGhhdmUgZWxlbWVudHMgbmFtZWQgeyAic3RhcnR0aW1lIiwgImVuZHRpbWUiLAogImF0dGVu
ZGVlcyIgfSB3aXRoIGNvcnJlc3BvbmRpbmcgdmFsdWVzIG9yIGl0IG1heSBoYXZlIGEgc2lu
Z2xlIGVsZW1lbnQgbmFtZQogImVudHJ5IiB3aXRoIGEgc2VyaWFsaXplZCBwcm90byBmb3Ig
dGhlIGNhbGVuZGFyIGVudHJ5LgoKICMjIE9yZGVyaW5nIGNvbnN0cmFpbnRzIGZvciBwYXJl
bnRzL2Rlc2NlbmRhbnRzCgogVGhlIFdhdGNoIEFQSSBwcm92aWRlcyBndWFyYW50ZWVzIHJl
Z2FyZGluZyB0aGUgb3JkZXIgaW4gd2hpY2gKIG1lc3NhZ2VzIGZvciBhIHBhcmVudCBhbmQg
aXRzIGRlc2NlbmRhbnRzIGFyZSBkZWxpdmVyZWQ6CgogMS4gVGhlIGNyZWF0aW9uIG9mIGFu
IGFuY2VzdG9yIChpLmUuLCB0aGUgZmlyc3QgRVhJU1RTIG1lc3NhZ2UgZm9yCiAgICB0aGUg
YW5jZXN0b3IpIGlzIHJlcG9ydGVkIGJlZm9yZSB0aGUgY3JlYXRpb24gb2YgYW55IG9mIGl0
cwogICAgZGVzY2VuZGFudHMuCgogMi4gVGhlIGRlbGV0aW9uIG9mIGFuIGFuY2VzdG9yICh2
aWEgYSBET0VTX05PVF9FWElTVCBtZXNzYWdlKQogICAgaW1wbGllcyB0aGUgZGVsZXRpb24g
b2YgYWxsIGl0cyBkZXNjZW5kYW50cy4gVGhlIHNlcnZpY2Ugd2lsbAogICAgbm90IGRlbGl2
ZXIgYW55IG1lc3NhZ2VzIGZvciB0aGUgZGVzY2VuZGFudHMgdW50aWwgdGhlIHBhcmVudAog
ICAgaGFzIGJlZW4gcmVjcmVhdGVkLgoKCwoDBgABEgSlAQgPClEKBAYAAgASBqcBAqsBAxpB
IFN0YXJ0IGEgc3RyZWFtaW5nIFJQQyB0byBnZXQgd2F0Y2ggaW5mb3JtYXRpb24gZnJvbSB0
aGUgc2VydmVyLgoKDQoFBgACAAESBKcBBgsKDQoFBgACAAISBKcBDBMKDQoFBgACAAYSBKcB
HiQKDQoFBgACAAMSBKcBJTAKDwoFBgACAAQSBqgBBKoBBgoTCgkGAAIABLDKvCISBqgBBKoB
BgpRCgIEABIGrwEA6AEBGkMgVGhlIG1lc3NhZ2UgdXNlZCBieSB0aGUgY2xpZW50IHRvIHJl
Z2lzdGVyIGludGVyZXN0IGluIGFuIGVudGl0eS4KCgsKAwQAARIErwEIDwqmCgoEBAACABIE
yAECFBqXCiBUaGUgYHRhcmdldGAgdmFsdWUgKiptdXN0KiogYmUgYSB2YWxpZCBVUkwgcGF0
aCBwb2ludGluZyB0byBhbiBlbnRpdHkKIHRvIHdhdGNoLiBOb3RlIHRoYXQgdGhlIHNlcnZp
Y2UgbmFtZSAqKm11c3QqKiBiZQogcmVtb3ZlZCBmcm9tIHRoZSB0YXJnZXQgZmllbGQgKGUu
Zy4sIHRoZSB0YXJnZXQgZmllbGQgbXVzdCBzYXkKICIvZm9vL2JhciIsIG5vdCAibXlzZXJ2
aWNlLmdvb2dsZWFwaXMuY29tL2Zvby9iYXIiKS4gQSBjbGllbnQgaXMKIGFsc28gYWxsb3dl
ZCB0byBwYXNzIHN5c3RlbS1zcGVjaWZpYyBwYXJhbWV0ZXJzIGluIHRoZSBVUkwgdGhhdAog
YXJlIG9ubHkgb2JleWVkIGJ5IHNvbWUgaW1wbGVtZW50YXRpb25zLiBTb21lIHBhcmFtZXRl
cnMgd2lsbCBiZQogaW1wbGVtZW50YXRpb24tc3BlY2lmaWMuIEhvd2V2ZXIsIHNvbWUgaGF2
ZSBwcmVkZWZpbmVkIG1lYW5pbmcKIGFuZCBhcmUgbGlzdGVkIGhlcmU6CgogICogcmVjdXJz
aXZlID0gdHJ1ZXxmYWxzZSBbZGVmYXVsdD1mYWxzZV0KICAgIElmIHNldCB0byB0cnVlLCBp
bmRpY2F0ZXMgdGhhdCB0aGUgY2xpZW50IHdhbnRzIHRvIHdhdGNoIGFsbCBlbGVtZW50cwog
ICAgb2YgZW50aXRpZXMgaW4gdGhlIHN1YnRyZWUgcm9vdGVkIGF0IHRoZSBlbnRpdHkncyBu
YW1lIGluIGB0YXJnZXRgLiBGb3IKICAgIGRlc2NlbmRhbnRzIHRoYXQgYXJlIG5vdCB0aGUg
aW1tZWRpYXRlIGNoaWxkcmVuIG9mIHRoZSB0YXJnZXQsIHRoZQogICAgYENoYW5nZS5lbGVt
ZW50YCB3aWxsIGNvbnRhaW4gc2xhc2hlcy4KCiAgICBOb3RlIHRoYXQgc29tZSBuYW1lc3Bh
Y2VzIGFuZCBlbnRpdGllcyB3aWxsIG5vdCBzdXBwb3J0IHJlY3Vyc2l2ZQogICAgd2F0Y2hp
bmcuIFdoZW4gd2F0Y2hpbmcgc3VjaCBhbiBlbnRpdHksIGEgY2xpZW50IG11c3Qgbm90IHNl
dCByZWN1cnNpdmUKICAgIHRvIHRydWUuIE90aGVyd2lzZSwgaXQgd2lsbCByZWNlaXZlIGFu
IGBVTklNUExFTUVOVEVEYCBlcnJvci4KCiBOb3JtYWwgVVJMIGVuY29kaW5nIG11c3QgYmUg
dXNlZCBpbnNpZGUgYHRhcmdldGAuICBGb3IgZXhhbXBsZSwgaWYgYSBxdWVyeQogcGFyYW1l
dGVyIG5hbWUgb3IgdmFsdWUsIG9yIHRoZSBub24tcXVlcnkgcGFyYW1ldGVyIHBvcnRpb24g
b2YgYHRhcmdldGAKIGNvbnRhaW5zIGEgc3BlY2lhbCBjaGFyYWN0ZXIsIGl0IG11c3QgYmUg
JS1lbmNvZGVkLiAgV2UgcmVjb21tZW5kIHRoYXQKIGNsaWVudHMgYW5kIHNlcnZlcnMgdXNl
IHRoZWlyIHJ1bnRpbWUncyBVUkwgbGlicmFyeSB0byBwcm9kdWNlIGFuZCBjb25zdW1lCiB0
YXJnZXQgdmFsdWVzLgoKDQoFBAACAAUSBMgBAggKDQoFBAACAAESBMgBCQ8KDQoFBAACAAMS
BMgBEhMKzQsKBAQAAgESBOcBAhoavgsgVGhlIGByZXN1bWVfbWFya2VyYCBzcGVjaWZpZXMg
aG93IG11Y2ggb2YgdGhlIGV4aXN0aW5nIHVuZGVybHlpbmcgc3RhdGUgaXMKIGRlbGl2ZXJl
ZCB0byB0aGUgY2xpZW50IHdoZW4gdGhlIHdhdGNoIHJlcXVlc3QgaXMgcmVjZWl2ZWQgYnkg
dGhlCiBzeXN0ZW0uIFRoZSBjbGllbnQgY2FuIHNldCB0aGlzIG1hcmtlciBpbiBvbmUgb2Yg
dGhlIGZvbGxvd2luZyB3YXlzIHRvIGdldAogZGlmZmVyZW50IHNlbWFudGljczoKCiAqICAg
UGFyYW1ldGVyIGlzIG5vdCBzcGVjaWZpZWQgb3IgaGFzIHRoZSB2YWx1ZSAiIi4KICAgICBT
ZW1hbnRpY3M6IEZldGNoIGluaXRpYWwgc3RhdGUuCiAgICAgVGhlIGNsaWVudCB3YW50cyB0
aGUgZW50aXR5J3MgaW5pdGlhbCBzdGF0ZSB0byBiZSBkZWxpdmVyZWQuIFNlZSB0aGUKICAg
ICBkZXNjcmlwdGlvbiBpbiAiSW5pdGlhbCBTdGF0ZSIuCgogKiAgIFBhcmFtZXRlciBpcyBz
ZXQgdG8gdGhlIHN0cmluZyAibm93IiAoVVRGLTggZW5jb2RpbmcpLgogICAgIFNlbWFudGlj
czogRmV0Y2ggbmV3IGNoYW5nZXMgb25seS4KICAgICBUaGUgY2xpZW50IGp1c3Qgd2FudHMg
dG8gZ2V0IHRoZSBjaGFuZ2VzIHJlY2VpdmVkIGJ5IHRoZSBzeXN0ZW0gYWZ0ZXIKICAgICB0
aGUgd2F0Y2ggcG9pbnQuIFRoZSBzeXN0ZW0gbWF5IGRlbGl2ZXIgY2hhbmdlcyBmcm9tIGJl
Zm9yZSB0aGUgd2F0Y2gKICAgICBwb2ludCBhcyB3ZWxsLgoKICogICBQYXJhbWV0ZXIgaXMg
c2V0IHRvIGEgdmFsdWUgcmVjZWl2ZWQgaW4gYW4gZWFybGllcgogICAgIGBDaGFuZ2UucmVz
dW1lX21hcmtlcmAgZmllbGQgd2hpbGUgd2F0Y2hpbmcgdGhlIHNhbWUgZW50aXR5LgogICAg
IFNlbWFudGljczogUmVzdW1lIGZyb20gYSBzcGVjaWZpYyBwb2ludC4KICAgICBUaGUgY2xp
ZW50IHdhbnRzIHRvIHJlY2VpdmUgdGhlIGNoYW5nZXMgZnJvbSBhIHNwZWNpZmljIHBvaW50
OyB0aGlzCiAgICAgdmFsdWUgbXVzdCBjb3JyZXNwb25kIHRvIGEgdmFsdWUgcmVjZWl2ZWQg
aW4gdGhlIGBDaGFuZ2UucmVzdW1lX21hcmtlcmAKICAgICBmaWVsZC4gVGhlIHN5c3RlbSBt
YXkgZGVsaXZlciBjaGFuZ2VzIGZyb20gYmVmb3JlIHRoZSBgcmVzdW1lX21hcmtlcmAKICAg
ICBhcyB3ZWxsLiBJZiB0aGUgc3lzdGVtIGNhbm5vdCByZXN1bWUgdGhlIHN0cmVhbSBmcm9t
IHRoaXMgcG9pbnQgKGUuZy4sCiAgICAgaWYgaXQgaXMgdG9vIGZhciBiZWhpbmQgaW4gdGhl
IHN0cmVhbSksIGl0IGNhbiByYWlzZSB0aGUKICAgICBgRkFJTEVEX1BSRUNPTkRJVElPTmAg
ZXJyb3IuCgogQW4gaW1wbGVtZW50YXRpb24gTVVTVCBzdXBwb3J0IGFuIHVuc3BlY2lmaWVk
IHBhcmFtZXRlciBhbmQgdGhlCiBlbXB0eSBzdHJpbmcgIiIgbWFya2VyIChpbml0aWFsIHN0
YXRlIGZldGNoaW5nKSBhbmQgdGhlICJub3ciIG1hcmtlci4KIEl0IG5lZWQgbm90IHN1cHBv
cnQgcmVzdW1pbmcgZnJvbSBhIHNwZWNpZmljIHBvaW50LgoKDQoFBAACAQUSBOcBAgcKDQoF
BAACAQESBOcBCBUKDQoFBAACAQMSBOcBGBkKKwoCBAESBusBAO4BARodIEEgYmF0Y2ggb2Yg
Q2hhbmdlIG1lc3NhZ2VzLgoKCwoDBAEBEgTrAQgTCioKBAQBAgASBO0BAh4aHCBBIGxpc3Qg
b2YgQ2hhbmdlIG1lc3NhZ2VzLgoKDQoFBAECAAQSBO0BAgoKDQoFBAECAAYSBO0BCxEKDQoF
BAECAAESBO0BEhkKDQoFBAECAAMSBO0BHB0KRwoCBAISBvEBAJwCARo5IEEgQ2hhbmdlIGlu
ZGljYXRlcyB0aGUgbW9zdCByZWNlbnQgc3RhdGUgb2YgYW4gZWxlbWVudC4KCgsKAwQCARIE
8QEIDgpJCgQEAgQAEgbzAQKDAgMaOSBBIHJlcG9ydGVkIHZhbHVlIGNhbiBiZSBpbiBvbmUg
b2YgdGhlIGZvbGxvd2luZyBzdGF0ZXM6CgoNCgUEAgQAARIE8wEHDApMCgYEAgQAAgASBPUB
BA8aPCBUaGUgZWxlbWVudCBleGlzdHMgYW5kIGl0cyBmdWxsIHZhbHVlIGlzIGluY2x1ZGVk
IGluIGRhdGEuCgoPCgcEAgQAAgABEgT1AQQKCg8KBwQCBAACAAISBPUBDQ4KLQoGBAIEAAIB
EgT4AQQXGh0gVGhlIGVsZW1lbnQgZG9lcyBub3QgZXhpc3QuCgoPCgcEAgQAAgEBEgT4AQQS
Cg8KBwQCBAACAQISBPgBFRYKvwEKBgQCBAACAhIE/QEEHhquASBFbGVtZW50IG1heSBvciBt
YXkgbm90IGV4aXN0LiBVc2VkIG9ubHkgZm9yIGluaXRpYWwgc3RhdGUgZGVsaXZlcnkgd2hl
bgogdGhlIGNsaWVudCBpcyBub3QgaW50ZXJlc3RlZCBpbiBmZXRjaGluZyB0aGUgaW5pdGlh
bCBzdGF0ZS4gU2VlIHRoZQogIkluaXRpYWwgU3RhdGUiIHNlY3Rpb24gYWJvdmUuCgoPCgcE
AgQAAgIBEgT9AQQZCg8KBwQCBAACAgISBP0BHB0KvgEKBgQCBAACAxIEggIEDhqtASBUaGUg
ZWxlbWVudCBtYXkgZXhpc3QsIGJ1dCBzb21lIGVycm9yIGhhcyBvY2N1cnJlZC4gTW9yZSBp
bmZvcm1hdGlvbiBpcwogYXZhaWxhYmxlIGluIHRoZSBkYXRhIGZpZWxkIC0gdGhlIHZhbHVl
IGlzIGEgc2VyaWFsaXplZCBTdGF0dXMKIHByb3RvIChmcm9tIFtnb29nbGUucnBjLlN0YXR1
c11bXSkKCg8KBwQCBAACAwESBIICBAkKDwoHBAIEAAIDAhIEggIMDQqjAQoEBAICABIEiAIC
FRqUASBOYW1lIG9mIHRoZSBlbGVtZW50LCBpbnRlcnByZXRlZCByZWxhdGl2ZSB0byB0aGUg
ZW50aXR5J3MgYWN0dWFsCiBuYW1lLiAiIiByZWZlcnMgdG8gdGhlIGVudGl0eSBpdHNlbGYu
IFRoZSBlbGVtZW50IG5hbWUgaXMgYSB2YWxpZAogVVRGLTggc3RyaW5nLgoKDQoFBAICAAUS
BIgCAggKDQoFBAICAAESBIgCCRAKDQoFBAICAAMSBIgCExQKKwoEBAICARIEiwICEhodIFRo
ZSBzdGF0ZSBvZiB0aGUgYGVsZW1lbnRgLgoKDQoFBAICAQYSBIsCAgcKDQoFBAICAQESBIsC
CA0KDQoFBAICAQMSBIsCEBEKygEKBAQCAgISBJACAh8auwEgVGhlIGFjdHVhbCBjaGFuZ2Ug
ZGF0YS4gVGhpcyBmaWVsZCBpcyBwcmVzZW50IG9ubHkgd2hlbiBgc3RhdGUoKSA9PSBFWElT
VFNgCiBvciBgc3RhdGUoKSA9PSBFUlJPUmAuIFBsZWFzZSBzZWUKIFtnb29nbGUucHJvdG9i
dWYuQW55XVtnb29nbGUucHJvdG9idWYuQW55XSBhYm91dCBob3cgdG8gdXNlIHRoZSBBbnkg
dHlwZS4KCg0KBQQCAgIGEgSQAgIVCg0KBQQCAgIBEgSQAhYaCg0KBQQCAgIDEgSQAh0eCv4C
CgQEAgIDEgSXAgIaGu8CIElmIHByZXNlbnQsIHByb3ZpZGVzIGEgY29tcGFjdCByZXByZXNl
bnRhdGlvbiBvZiBhbGwgdGhlIG1lc3NhZ2VzIHRoYXQgaGF2ZQogYmVlbiByZWNlaXZlZCBi
eSB0aGUgY2FsbGVyIGZvciB0aGUgZ2l2ZW4gZW50aXR5LCBlLmcuLCBpdCBjb3VsZCBiZSBh
CiBzZXF1ZW5jZSBudW1iZXIgb3IgYSBtdWx0aS1wYXJ0IHRpbWVzdGFtcC92ZXJzaW9uIHZl
Y3Rvci4gVGhpcyBtYXJrZXIgY2FuCiBiZSBwcm92aWRlZCBpbiB0aGUgUmVxdWVzdCBtZXNz
YWdlLCBhbGxvd2luZyB0aGUgY2FsbGVyIHRvIHJlc3VtZSB0aGUKIHN0cmVhbSB3YXRjaGlu
ZyBhdCBhIHNwZWNpZmljIHBvaW50IHdpdGhvdXQgZmV0Y2hpbmcgdGhlIGluaXRpYWwgc3Rh
dGUuCgoNCgUEAgIDBRIElwICBwoNCgUEAgIDARIElwIIFQoNCgUEAgIDAxIElwIYGQpsCgQE
AgIEEgSbAgIVGl4gSWYgdHJ1ZSwgdGhpcyBDaGFuZ2UgaXMgZm9sbG93ZWQgYnkgbW9yZSBD
aGFuZ2VzIHRoYXQgYXJlIGluIHRoZSBzYW1lIGdyb3VwCiBhcyB0aGlzIENoYW5nZS4KCg0K
BQQCAgQFEgSbAgIGCg0KBQQCAgQBEgSbAgcQCg0KBQQCAgQDEgSbAhMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Watcher::V1::Watch::Request ===
    # Fields for Request
    # Field: target Type: 9 ()
    # Field: resume_marker Type: 12 ()

# === Message: Google::Watcher::V1::Watch::ChangeBatch ===
    # Fields for ChangeBatch
    # Field: changes Type: 11 (.google.watcher.v1.Change)

# === Message: Google::Watcher::V1::Watch::Change ===
    # Fields for Change
    # Field: element Type: 9 ()
    # Field: state Type: 14 (.google.watcher.v1.Change.State)
    # Field: data Type: 11 (.google.protobuf.Any)
    # Field: resume_marker Type: 12 ()
    # Field: continued Type: 8 ()

# Enum: Change::State
our $Change_EXISTS = 0;
our $Change_DOES_NOT_EXIST = 1;
our $Change_INITIAL_STATE_SKIPPED = 2;
our $Change_ERROR = 3;

# === Service Client: Google::Watcher::V1::Watch::WatcherClient ===
package Google::Watcher::V1::Watch::WatcherClient;

=pod

=head2 Service Client: Google::Watcher::V1::Watch::WatcherClient

Client stub representing the remote C<Watcher> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<watcher.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'watcher.googleapis.com:443' );

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

sub watch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Watcher::V1::Watch::Request->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.watcher.v1.Watcher',
        method         => 'Watch',
        request        => $req,
        response_class => 'Google::Watcher::V1::Watch::ChangeBatch',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Watcher::V1::Watch - Compiled Protocol Buffers messages for google/watcher/v1/watch.proto

=head1 SYNOPSIS

    use Google::Watcher::V1::Watch;

    my $msg = Google::Watcher::V1::Watch::Request->new({
        target => $target,
        resume_marker => $resume_marker,
    });

    # Read or update a field
    my $val = $msg->target();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Watcher::V1::Watch::Request->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/watcher/v1/watch.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Watcher::V1::Watch::Request

The message used by the client to register interest in an entity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

The `target` value B<must> be a valid URL path pointing to an entity
to watch. Note that the service name B<must> be
removed from the target field (e.g., the target field must say
"/foo/bar", not "myservice.googleapis.com/foo/bar"). A client is
also allowed to pass system-specific parameters in the URL that
are only obeyed by some implementations. Some parameters will be
implementation-specific. However, some have predefined meaning
and are listed here:

 * recursive = true|false [default=false]
   If set to true, indicates that the client wants to watch all elements
   of entities in the subtree rooted at the entity's name in `target`. For
   descendants that are not the immediate children of the target, the
   `Change.element` will contain slashes.

   Note that some namespaces and entities will not support recursive
   watching. When watching such an entity, a client must not set recursive
   to true. Otherwise, it will receive an `UNIMPLEMENTED` error.

Normal URL encoding must be used inside `target`.  For example, if a query
parameter name or value, or the non-query parameter portion of `target`
contains a special character, it must be %-encoded.  We recommend that
clients and servers use their runtime's URL library to produce and consume
target values.

=item * C<< $msg->resume_marker() >> / C<< $msg->resume_marker($value) >>

Type: C<Bytes>

The `resume_marker` specifies how much of the existing underlying state is
delivered to the client when the watch request is received by the
system. The client can set this marker in one of the following ways to get
different semantics:

*   Parameter is not specified or has the value "".
    Semantics: Fetch initial state.
    The client wants the entity's initial state to be delivered. See the
    description in "Initial State".

*   Parameter is set to the string "now" (UTF-8 encoding).
    Semantics: Fetch new changes only.
    The client just wants to get the changes received by the system after
    the watch point. The system may deliver changes from before the watch
    point as well.

*   Parameter is set to a value received in an earlier
    `Change.resume_marker` field while watching the same entity.
    Semantics: Resume from a specific point.
    The client wants to receive the changes from a specific point; this
    value must correspond to a value received in the `Change.resume_marker`
    field. The system may deliver changes from before the `resume_marker`
    as well. If the system cannot resume the stream from this point (e.g.,
    if it is too far behind in the stream), it can raise the
    `FAILED_PRECONDITION` error.

An implementation MUST support an unspecified parameter and the
empty string "" marker (initial state fetching) and the "now" marker.
It need not support resuming from a specific point.

=back

=head2 Google::Watcher::V1::Watch::ChangeBatch

A batch of Change messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->changes() >> / C<< $msg->changes($value) >>

Type: C<Message> (L<Google::Watcher::V1::Watch::Change>)

A list of Change messages.

=back

=head2 Google::Watcher::V1::Watch::Change

A Change indicates the most recent state of an element.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->element() >> / C<< $msg->element($value) >>

Type: C<String>

Name of the element, interpreted relative to the entity's actual
name. "" refers to the entity itself. The element name is a valid
UTF-8 string.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Watcher::V1::Change::State>)

The state of the `element`.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The actual change data. This field is present only when `state() == EXISTS`
or `state() == ERROR`. Please see
[google.protobuf.Any][google.protobuf.Any] about how to use the Any type.

=item * C<< $msg->resume_marker() >> / C<< $msg->resume_marker($value) >>

Type: C<Bytes>

If present, provides a compact representation of all the messages that have
been received by the caller for the given entity, e.g., it could be a
sequence number or a multi-part timestamp/version vector. This marker can
be provided in the Request message, allowing the caller to resume the
stream watching at a specific point without fetching the initial state.

=item * C<< $msg->continued() >> / C<< $msg->continued($value) >>

Type: C<Bool>

If true, this Change is followed by more Changes that are in the same group
as this Change.

=back

=head3 Enum: Change::State

=over 4

=item * C<EXISTS> => C<0>

=item * C<DOES_NOT_EXIST> => C<1>

=item * C<INITIAL_STATE_SKIPPED> => C<2>

=item * C<ERROR> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Watcher::V1::Watch::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
