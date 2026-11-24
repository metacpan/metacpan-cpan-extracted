package Google::Firestore::Admin::V1beta1::FirestoreAdmin;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Firestore::Admin::V1beta1::Index };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Api::Client };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTEvZmlyZXN0b3JlX2FkbWluLnByb3Rv
Eh5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aKmdvb2dsZS9maXJlc3RvcmUvYWRtaW4vdjFiZXRhMS9pbmRleC5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9l
bXB0eS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29vZ2xlL2Fw
aS9jbGllbnQucHJvdG8ixwMKFkluZGV4T3BlcmF0aW9uTWV0YWRhdGESOQoKc3RhcnRfdGlt
ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSFAoFaW5k
ZXgYAyABKAlSBWluZGV4EmsKDm9wZXJhdGlvbl90eXBlGAQgASgOMkQuZ29vZ2xlLmZpcmVz
dG9yZS5hZG1pbi52MWJldGExLkluZGV4T3BlcmF0aW9uTWV0YWRhdGEuT3BlcmF0aW9uVHlw
ZVINb3BlcmF0aW9uVHlwZRIcCgljYW5jZWxsZWQYBSABKAhSCWNhbmNlbGxlZBJVChFkb2N1
bWVudF9wcm9ncmVzcxgGIAEoCzIoLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5Q
cm9ncmVzc1IQZG9jdW1lbnRQcm9ncmVzcyJDCg1PcGVyYXRpb25UeXBlEh4KGk9QRVJBVElP
Tl9UWVBFX1VOU1BFQ0lGSUVEEAASEgoOQ1JFQVRJTkdfSU5ERVgQASJYCghQcm9ncmVzcxIl
Cg53b3JrX2NvbXBsZXRlZBgBIAEoA1INd29ya0NvbXBsZXRlZBIlCg53b3JrX2VzdGltYXRl
ZBgCIAEoA1INd29ya0VzdGltYXRlZCJpChJDcmVhdGVJbmRleFJlcXVlc3QSFgoGcGFyZW50
GAEgASgJUgZwYXJlbnQSOwoFaW5kZXgYAiABKAsyJS5nb29nbGUuZmlyZXN0b3JlLmFkbWlu
LnYxYmV0YTEuSW5kZXhSBWluZGV4IiUKD0dldEluZGV4UmVxdWVzdBISCgRuYW1lGAEgASgJ
UgRuYW1lIoABChJMaXN0SW5kZXhlc1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQS
FgoGZmlsdGVyGAIgASgJUgZmaWx0ZXISGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRId
CgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4iKAoSRGVsZXRlSW5kZXhSZXF1ZXN0EhIK
BG5hbWUYASABKAlSBG5hbWUifgoTTGlzdEluZGV4ZXNSZXNwb25zZRI/CgdpbmRleGVzGAEg
AygLMiUuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkluZGV4UgdpbmRleGVzEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJ/ChZFeHBvcnREb2N1bWVu
dHNSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSJQoOY29sbGVjdGlvbl9pZHMYAyADKAlS
DWNvbGxlY3Rpb25JZHMSKgoRb3V0cHV0X3VyaV9wcmVmaXgYBCABKAlSD291dHB1dFVyaVBy
ZWZpeCJ9ChZJbXBvcnREb2N1bWVudHNSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSJQoO
Y29sbGVjdGlvbl9pZHMYAyADKAlSDWNvbGxlY3Rpb25JZHMSKAoQaW5wdXRfdXJpX3ByZWZp
eBgEIAEoCVIOaW5wdXRVcmlQcmVmaXgiRQoXRXhwb3J0RG9jdW1lbnRzUmVzcG9uc2USKgoR
b3V0cHV0X3VyaV9wcmVmaXgYASABKAlSD291dHB1dFVyaVByZWZpeCLhAwoXRXhwb3J0RG9j
dW1lbnRzTWV0YWRhdGESOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSB2VuZFRpbWUSVwoPb3BlcmF0aW9uX3N0YXRlGAMgASgOMi4uZ29vZ2xl
LmZpcmVzdG9yZS5hZG1pbi52MWJldGExLk9wZXJhdGlvblN0YXRlUg5vcGVyYXRpb25TdGF0
ZRJXChJwcm9ncmVzc19kb2N1bWVudHMYBCABKAsyKC5nb29nbGUuZmlyZXN0b3JlLmFkbWlu
LnYxYmV0YTEuUHJvZ3Jlc3NSEXByb2dyZXNzRG9jdW1lbnRzEk8KDnByb2dyZXNzX2J5dGVz
GAUgASgLMiguZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLlByb2dyZXNzUg1wcm9n
cmVzc0J5dGVzEiUKDmNvbGxlY3Rpb25faWRzGAYgAygJUg1jb2xsZWN0aW9uSWRzEioKEW91
dHB1dF91cmlfcHJlZml4GAcgASgJUg9vdXRwdXRVcmlQcmVmaXgi3wMKF0ltcG9ydERvY3Vt
ZW50c01ldGFkYXRhEjkKCnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUglzdGFydFRpbWUSNQoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUgdlbmRUaW1lElcKD29wZXJhdGlvbl9zdGF0ZRgDIAEoDjIuLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMS5PcGVyYXRpb25TdGF0ZVIOb3BlcmF0aW9uU3RhdGUS
VwoScHJvZ3Jlc3NfZG9jdW1lbnRzGAQgASgLMiguZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52
MWJldGExLlByb2dyZXNzUhFwcm9ncmVzc0RvY3VtZW50cxJPCg5wcm9ncmVzc19ieXRlcxgF
IAEoCzIoLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5Qcm9ncmVzc1INcHJvZ3Jl
c3NCeXRlcxIlCg5jb2xsZWN0aW9uX2lkcxgGIAMoCVINY29sbGVjdGlvbklkcxIoChBpbnB1
dF91cmlfcHJlZml4GAcgASgJUg5pbnB1dFVyaVByZWZpeCqUAQoOT3BlcmF0aW9uU3RhdGUS
FQoRU1RBVEVfVU5TUEVDSUZJRUQQABIQCgxJTklUSUFMSVpJTkcQARIOCgpQUk9DRVNTSU5H
EAISDgoKQ0FOQ0VMTElORxADEg4KCkZJTkFMSVpJTkcQBBIOCgpTVUNDRVNTRlVMEAUSCgoG
RkFJTEVEEAYSDQoJQ0FOQ0VMTEVEEAcy8AgKDkZpcmVzdG9yZUFkbWluEqEBCgtDcmVhdGVJ
bmRleBIyLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5DcmVhdGVJbmRleFJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIj+C0+STAjkiMC92MWJldGExL3tw
YXJlbnQ9cHJvamVjdHMvKi9kYXRhYmFzZXMvKn0vaW5kZXhlczoFaW5kZXgSsAEKC0xpc3RJ
bmRleGVzEjIuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkxpc3RJbmRleGVzUmVx
dWVzdBozLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5MaXN0SW5kZXhlc1Jlc3Bv
bnNlIjiC0+STAjISMC92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9kYXRhYmFzZXMvKn0v
aW5kZXhlcxKcAQoIR2V0SW5kZXgSLy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEu
R2V0SW5kZXhSZXF1ZXN0GiUuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkluZGV4
IjiC0+STAjISMC92MWJldGExL3tuYW1lPXByb2plY3RzLyovZGF0YWJhc2VzLyovaW5kZXhl
cy8qfRKTAQoLRGVsZXRlSW5kZXgSMi5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEu
RGVsZXRlSW5kZXhSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IjiC0+STAjIqMC92
MWJldGExL3tuYW1lPXByb2plY3RzLyovZGF0YWJhc2VzLyovaW5kZXhlcy8qfRKrAQoPRXhw
b3J0RG9jdW1lbnRzEjYuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkV4cG9ydERv
Y3VtZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIkGC0+STAjsi
Ni92MWJldGExL3tuYW1lPXByb2plY3RzLyovZGF0YWJhc2VzLyp9OmV4cG9ydERvY3VtZW50
czoBKhKrAQoPSW1wb3J0RG9jdW1lbnRzEjYuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJl
dGExLkltcG9ydERvY3VtZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uIkGC0+STAjsiNi92MWJldGExL3tuYW1lPXByb2plY3RzLyovZGF0YWJhc2VzLyp9Omlt
cG9ydERvY3VtZW50czoBKhp2ykEYZmlyZXN0b3JlLmdvb2dsZWFwaXMuY29t0kFYaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2RhdGFzdG9yZUKpAQoiY29tLmdvb2dsZS5maXJlc3RvcmUu
YWRtaW4udjFiZXRhMUITRmlyZXN0b3JlQWRtaW5Qcm90b1ABWj5jbG91ZC5nb29nbGUuY29t
L2dvL2ZpcmVzdG9yZS9hZG1pbi9hcGl2MWJldGExL2FkbWlucGI7YWRtaW5wYqICBEdDRlOq
AiRHb29nbGUuQ2xvdWQuRmlyZXN0b3JlLkFkbWluLlYxQmV0YTFKwmcKBxIFDwDxAgEKvQQK
AQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAnCgkKAgMAEgMTACYK
CQoCAwESAxQANAoJCgIDAhIDFQAtCgkKAgMDEgMWACUKCQoCAwQSAxcAKQoJCgIDBRIDGAAh
CggKAQgSAxoAQQoJCgIIJRIDGgBBCggKAQgSAxsAVQoJCgIICxIDGwBVCggKAQgSAxwAIgoJ
CgIIChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4AOwoJCgIIARIDHgA7CggK
AQgSAx8AIgoJCgIIJBIDHwAiCo4LCgIGABIFTACVAQEagAsgVGhlIENsb3VkIEZpcmVzdG9y
ZSBBZG1pbiBBUEkuCgogVGhpcyBBUEkgcHJvdmlkZXMgc2V2ZXJhbCBhZG1pbmlzdHJhdGl2
ZSBzZXJ2aWNlcyBmb3IgQ2xvdWQgRmlyZXN0b3JlLgoKICMgQ29uY2VwdHMKCiBQcm9qZWN0
LCBEYXRhYmFzZSwgTmFtZXNwYWNlLCBDb2xsZWN0aW9uLCBhbmQgRG9jdW1lbnQgYXJlIHVz
ZWQgYXMgZGVmaW5lZCBpbgogdGhlIEdvb2dsZSBDbG91ZCBGaXJlc3RvcmUgQVBJLgoKIE9w
ZXJhdGlvbjogQW4gT3BlcmF0aW9uIHJlcHJlc2VudHMgd29yayBiZWluZyBwZXJmb3JtZWQg
aW4gdGhlIGJhY2tncm91bmQuCgoKICMgU2VydmljZXMKCiAjIyBJbmRleAoKIFRoZSBpbmRl
eCBzZXJ2aWNlIG1hbmFnZXMgQ2xvdWQgRmlyZXN0b3JlIGluZGV4ZXMuCgogSW5kZXggY3Jl
YXRpb24gaXMgcGVyZm9ybWVkIGFzeW5jaHJvbm91c2x5LgogQW4gT3BlcmF0aW9uIHJlc291
cmNlIGlzIGNyZWF0ZWQgZm9yIGVhY2ggc3VjaCBhc3luY2hyb25vdXMgb3BlcmF0aW9uLgog
VGhlIHN0YXRlIG9mIHRoZSBvcGVyYXRpb24gKGluY2x1ZGluZyBhbnkgZXJyb3JzIGVuY291
bnRlcmVkKQogbWF5IGJlIHF1ZXJpZWQgdmlhIHRoZSBPcGVyYXRpb24gcmVzb3VyY2UuCgog
IyMgTWV0YWRhdGEKCiBQcm92aWRlcyBtZXRhZGF0YSBhbmQgc3RhdGlzdGljYWwgaW5mb3Jt
YXRpb24gYWJvdXQgZGF0YSBpbiBDbG91ZCBGaXJlc3RvcmUuCiBUaGUgZGF0YSBwcm92aWRl
ZCBhcyBwYXJ0IG9mIHRoaXMgQVBJIG1heSBiZSBzdGFsZS4KCiAjIyBPcGVyYXRpb24KCiBU
aGUgT3BlcmF0aW9ucyBjb2xsZWN0aW9uIHByb3ZpZGVzIGEgcmVjb3JkIG9mIGFjdGlvbnMg
cGVyZm9ybWVkIGZvciB0aGUKIHNwZWNpZmllZCBQcm9qZWN0IChpbmNsdWRpbmcgYW55IE9w
ZXJhdGlvbnMgaW4gcHJvZ3Jlc3MpLiBPcGVyYXRpb25zIGFyZSBub3QKIGNyZWF0ZWQgZGly
ZWN0bHkgYnV0IHRocm91Z2ggY2FsbHMgb24gb3RoZXIgY29sbGVjdGlvbnMgb3IgcmVzb3Vy
Y2VzLgoKIEFuIE9wZXJhdGlvbiB0aGF0IGlzIG5vdCB5ZXQgZG9uZSBtYXkgYmUgY2FuY2Vs
bGVkLiBUaGUgcmVxdWVzdCB0byBjYW5jZWwgaXMKIGFzeW5jaHJvbm91cyBhbmQgdGhlIE9w
ZXJhdGlvbiBtYXkgY29udGludWUgdG8gcnVuIGZvciBzb21lIHRpbWUgYWZ0ZXIgdGhlCiBy
ZXF1ZXN0IHRvIGNhbmNlbCBpcyBtYWRlLgoKIEFuIE9wZXJhdGlvbiB0aGF0IGlzIGRvbmUg
bWF5IGJlIGRlbGV0ZWQgc28gdGhhdCBpdCBpcyBubyBsb25nZXIgbGlzdGVkIGFzCiBwYXJ0
IG9mIHRoZSBPcGVyYXRpb24gY29sbGVjdGlvbi4KCiBPcGVyYXRpb25zIGFyZSBjcmVhdGVk
IGJ5IHNlcnZpY2UgYEZpcmVzdG9yZUFkbWluYCwgYnV0IGFyZSBhY2Nlc3NlZCB2aWEKIHNl
cnZpY2UgYGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zYC4KCgoKAwYAARIDTAgWCgoK
AwYAAxIDTQJACgwKBQYAA5kIEgNNAkAKCwoDBgADEgROAlAyCg0KBQYAA5oIEgROAlAyCtoF
CgQGAAIAEgRfAmQDGssFIENyZWF0ZXMgdGhlIHNwZWNpZmllZCBpbmRleC4KIEEgbmV3bHkg
Y3JlYXRlZCBpbmRleCdzIGluaXRpYWwgc3RhdGUgaXMgYENSRUFUSU5HYC4gT24gY29tcGxl
dGlvbiBvZiB0aGUKIHJldHVybmVkIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXVtn
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXSwgdGhlIHN0YXRlIHdpbGwgYmUgYFJFQURZ
YC4KIElmIHRoZSBpbmRleCBhbHJlYWR5IGV4aXN0cywgdGhlIGNhbGwgd2lsbCByZXR1cm4g
YW4gYEFMUkVBRFlfRVhJU1RTYAogc3RhdHVzLgoKIER1cmluZyBjcmVhdGlvbiwgdGhlIHBy
b2Nlc3MgY291bGQgcmVzdWx0IGluIGFuIGVycm9yLCBpbiB3aGljaCBjYXNlIHRoZQogaW5k
ZXggd2lsbCBtb3ZlIHRvIHRoZSBgRVJST1JgIHN0YXRlLiBUaGUgcHJvY2VzcyBjYW4gYmUg
cmVjb3ZlcmVkIGJ5CiBmaXhpbmcgdGhlIGRhdGEgdGhhdCBjYXVzZWQgdGhlIGVycm9yLCBy
ZW1vdmluZyB0aGUgaW5kZXggd2l0aAogW2RlbGV0ZV1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1p
bi52MWJldGExLkZpcmVzdG9yZUFkbWluLkRlbGV0ZUluZGV4XSwgdGhlbiByZS1jcmVhdGlu
ZyB0aGUgaW5kZXggd2l0aAogW2NyZWF0ZV1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJl
dGExLkZpcmVzdG9yZUFkbWluLkNyZWF0ZUluZGV4XS4KCiBJbmRleGVzIHdpdGggYSBzaW5n
bGUgZmllbGQgY2Fubm90IGJlIGNyZWF0ZWQuCgoMCgUGAAIAARIDXwYRCgwKBQYAAgACEgNf
EiQKDAoFBgACAAMSA18vSwoNCgUGAAIABBIEYARjBgoRCgkGAAIABLDKvCISBGAEYwYKQwoE
BgACARIEZwJrAxo1IExpc3RzIHRoZSBpbmRleGVzIHRoYXQgbWF0Y2ggdGhlIHNwZWNpZmll
ZCBmaWx0ZXJzLgoKDAoFBgACAQESA2cGEQoMCgUGAAIBAhIDZxIkCgwKBQYAAgEDEgNnL0IK
DQoFBgACAQQSBGgEagYKEQoJBgACAQSwyrwiEgRoBGoGCh4KBAYAAgISBG4CcgMaECBHZXRz
IGFuIGluZGV4LgoKDAoFBgACAgESA24GDgoMCgUGAAICAhIDbg8eCgwKBQYAAgIDEgNuKS4K
DQoFBgACAgQSBG8EcQYKEQoJBgACAgSwyrwiEgRvBHEGCiEKBAYAAgMSBHUCeQMaEyBEZWxl
dGVzIGFuIGluZGV4LgoKDAoFBgACAwESA3UGEQoMCgUGAAIDAhIDdRIkCgwKBQYAAgMDEgN1
L0QKDQoFBgACAwQSBHYEeAYKEQoJBgACAwSwyrwiEgR2BHgGCpsECgQGAAIEEgaDAQKIAQMa
igQgRXhwb3J0cyBhIGNvcHkgb2YgYWxsIG9yIGEgc3Vic2V0IG9mIGRvY3VtZW50cyBmcm9t
IEdvb2dsZSBDbG91ZCBGaXJlc3RvcmUKIHRvIGFub3RoZXIgc3RvcmFnZSBzeXN0ZW0sIHN1
Y2ggYXMgR29vZ2xlIENsb3VkIFN0b3JhZ2UuIFJlY2VudCB1cGRhdGVzIHRvCiBkb2N1bWVu
dHMgbWF5IG5vdCBiZSByZWZsZWN0ZWQgaW4gdGhlIGV4cG9ydC4gVGhlIGV4cG9ydCBvY2N1
cnMgaW4gdGhlCiBiYWNrZ3JvdW5kIGFuZCBpdHMgcHJvZ3Jlc3MgY2FuIGJlIG1vbml0b3Jl
ZCBhbmQgbWFuYWdlZCB2aWEgdGhlCiBPcGVyYXRpb24gcmVzb3VyY2UgdGhhdCBpcyBjcmVh
dGVkLiBUaGUgb3V0cHV0IG9mIGFuIGV4cG9ydCBtYXkgb25seSBiZQogdXNlZCBvbmNlIHRo
ZSBhc3NvY2lhdGVkIG9wZXJhdGlvbiBpcyBkb25lLiBJZiBhbiBleHBvcnQgb3BlcmF0aW9u
IGlzCiBjYW5jZWxsZWQgYmVmb3JlIGNvbXBsZXRpb24gaXQgbWF5IGxlYXZlIHBhcnRpYWwg
ZGF0YSBiZWhpbmQgaW4gR29vZ2xlCiBDbG91ZCBTdG9yYWdlLgoKDQoFBgACBAESBIMBBhUK
DQoFBgACBAISBIMBFiwKDQoFBgACBAMSBIMBN1MKDwoFBgACBAQSBoQBBIcBBgoTCgkGAAIE
BLDKvCISBoQBBIcBBgr/AgoEBgACBRIGjwEClAEDGu4CIEltcG9ydHMgZG9jdW1lbnRzIGlu
dG8gR29vZ2xlIENsb3VkIEZpcmVzdG9yZS4gRXhpc3RpbmcgZG9jdW1lbnRzIHdpdGggdGhl
CiBzYW1lIG5hbWUgYXJlIG92ZXJ3cml0dGVuLiBUaGUgaW1wb3J0IG9jY3VycyBpbiB0aGUg
YmFja2dyb3VuZCBhbmQgaXRzCiBwcm9ncmVzcyBjYW4gYmUgbW9uaXRvcmVkIGFuZCBtYW5h
Z2VkIHZpYSB0aGUgT3BlcmF0aW9uIHJlc291cmNlIHRoYXQgaXMKIGNyZWF0ZWQuIElmIGFu
IEltcG9ydERvY3VtZW50cyBvcGVyYXRpb24gaXMgY2FuY2VsbGVkLCBpdCBpcyBwb3NzaWJs
ZQogdGhhdCBhIHN1YnNldCBvZiB0aGUgZGF0YSBoYXMgYWxyZWFkeSBiZWVuIGltcG9ydGVk
IHRvIENsb3VkIEZpcmVzdG9yZS4KCg0KBQYAAgUBEgSPAQYVCg0KBQYAAgUCEgSPARYsCg0K
BQYAAgUDEgSPATdTCg8KBQYAAgUEEgaQAQSTAQYKEwoJBgACBQSwyrwiEgaQAQSTAQYKnAEK
AgQAEgaZAQC4AQEajQEgTWV0YWRhdGEgZm9yIGluZGV4IG9wZXJhdGlvbnMuIFRoaXMgbWV0
YWRhdGEgcG9wdWxhdGVzCiB0aGUgbWV0YWRhdGEgZmllbGQgb2YgW2dvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dLgoKCwoDBAAB
EgSZAQgeCi4KBAQABAASBpsBAqEBAxoeIFRoZSB0eXBlIG9mIGluZGV4IG9wZXJhdGlvbi4K
Cg0KBQQABAABEgSbAQcUCjMKBgQABAACABIEnQEEIxojIFVuc3BlY2lmaWVkLiBOZXZlciBz
ZXQgYnkgc2VydmVyLgoKDwoHBAAEAAIAARIEnQEEHgoPCgcEAAQAAgACEgSdASEiClkKBgQA
BAACARIEoAEEFxpJIFRoZSBvcGVyYXRpb24gaXMgY3JlYXRpbmcgdGhlIGluZGV4LiBJbml0
aWF0ZWQgYnkgYSBgQ3JlYXRlSW5kZXhgIGNhbGwuCgoPCgcEAAQAAgEBEgSgAQQSCg8KBwQA
BAACAQISBKABFRYKOgoEBAACABIEpAECKxosIFRoZSB0aW1lIHRoYXQgd29yayBiZWdhbiBv
biB0aGUgb3BlcmF0aW9uLgoKDQoFBAACAAYSBKQBAhsKDQoFBAACAAESBKQBHCYKDQoFBAAC
AAMSBKQBKSoKeAoEBAACARIEqAECKRpqIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZW5kZWQs
IGVpdGhlciBzdWNjZXNzZnVsbHkgb3Igb3RoZXJ3aXNlLiBVbnNldCBpZgogdGhlIG9wZXJh
dGlvbiBpcyBzdGlsbCBhY3RpdmUuCgoNCgUEAAIBBhIEqAECGwoNCgUEAAIBARIEqAEcJAoN
CgUEAAIBAxIEqAEnKAqWAQoEBAACAhIErAECExqHASBUaGUgaW5kZXggcmVzb3VyY2UgdGhh
dCB0aGlzIG9wZXJhdGlvbiBpcyBhY3Rpbmcgb24uIEZvciBleGFtcGxlOgogYHByb2plY3Rz
L3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfS9pbmRleGVzL3tpbmRleF9p
ZH1gCgoNCgUEAAICBRIErAECCAoNCgUEAAICARIErAEJDgoNCgUEAAICAxIErAEREgosCgQE
AAIDEgSvAQIjGh4gVGhlIHR5cGUgb2YgaW5kZXggb3BlcmF0aW9uLgoKDQoFBAACAwYSBK8B
Ag8KDQoFBAACAwESBK8BEB4KDQoFBAACAwMSBK8BISIK4QEKBAQAAgQSBLQBAhUa0gEgVHJ1
ZSBpZiB0aGUgW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dIHdhcyBjYW5jZWxsZWQu
IElmIHRoZQogY2FuY2VsbGF0aW9uIGlzIGluIHByb2dyZXNzLCBjYW5jZWxsZWQgd2lsbCBi
ZSB0cnVlIGJ1dAogW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZG9uZV1bZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbi5kb25lXSB3aWxsIGJlIGZhbHNlLgoKDQoFBAACBAUS
BLQBAgYKDQoFBAACBAESBLQBBxAKDQoFBAACBAMSBLQBExQKVAoEBAACBRIEtwECIRpGIFBy
b2dyZXNzIG9mIHRoZSBleGlzdGluZyBvcGVyYXRpb24sIG1lYXN1cmVkIGluIG51bWJlciBv
ZiBkb2N1bWVudHMuCgoNCgUEAAIFBhIEtwECCgoNCgUEAAIFARIEtwELHAoNCgUEAAIFAxIE
twEfIAo9CgIEARIGuwEAwwEBGi8gTWVhc3VyZXMgdGhlIHByb2dyZXNzIG9mIGEgcGFydGlj
dWxhciBtZXRyaWMuCgoLCgMEAQESBLsBCBAKdgoEBAECABIEvgECGxpoIEFuIGVzdGltYXRl
IG9mIGhvdyBtdWNoIHdvcmsgaGFzIGJlZW4gY29tcGxldGVkLiBOb3RlIHRoYXQgdGhpcyBt
YXkgYmUKIGdyZWF0ZXIgdGhhbiBgd29ya19lc3RpbWF0ZWRgLgoKDQoFBAECAAUSBL4BAgcK
DQoFBAECAAESBL4BCBYKDQoFBAECAAMSBL4BGRoKjQEKBAQBAgESBMIBAhsafyBBbiBlc3Rp
bWF0ZSBvZiBob3cgbXVjaCB3b3JrIG5lZWRzIHRvIGJlIHBlcmZvcm1lZC4gWmVybyBpZiB0
aGUKIHdvcmsgZXN0aW1hdGUgaXMgdW5hdmFpbGFibGUuIE1heSBjaGFuZ2UgYXMgd29yayBw
cm9ncmVzc2VzLgoKDQoFBAECAQUSBMIBAgcKDQoFBAECAQESBMIBCBYKDQoFBAECAQMSBMIB
GRoKeAoCBAISBsYBAM4BARpqIFRoZSByZXF1ZXN0IGZvciBbRmlyZXN0b3JlQWRtaW4uQ3Jl
YXRlSW5kZXhdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5GaXJlc3RvcmVBZG1p
bi5DcmVhdGVJbmRleF0uCgoLCgMEAgESBMYBCBoKgAEKBAQCAgASBMkBAhQaciBUaGUgbmFt
ZSBvZiB0aGUgZGF0YWJhc2UgdGhpcyBpbmRleCB3aWxsIGFwcGx5IHRvLiBGb3IgZXhhbXBs
ZToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vZGF0YWJhc2VzL3tkYXRhYmFzZV9pZH1gCgoN
CgUEAgIABRIEyQECCAoNCgUEAgIAARIEyQEJDwoNCgUEAgIAAxIEyQESEwqgAQoEBAICARIE
zQECEhqRASBUaGUgaW5kZXggdG8gY3JlYXRlLiBUaGUgbmFtZSBhbmQgc3RhdGUgZmllbGRz
IGFyZSBvdXRwdXQgb25seSBhbmQgd2lsbCBiZQogaWdub3JlZC4gQ2VydGFpbiBzaW5nbGUg
ZmllbGQgaW5kZXhlcyBjYW5ub3QgYmUgY3JlYXRlZCBvciBkZWxldGVkLgoKDQoFBAICAQYS
BM0BAgcKDQoFBAICAQESBM0BCA0KDQoFBAICAQMSBM0BEBEKcgoCBAMSBtEBANUBARpkIFRo
ZSByZXF1ZXN0IGZvciBbRmlyZXN0b3JlQWRtaW4uR2V0SW5kZXhdW2dvb2dsZS5maXJlc3Rv
cmUuYWRtaW4udjFiZXRhMS5GaXJlc3RvcmVBZG1pbi5HZXRJbmRleF0uCgoLCgMEAwESBNEB
CBcKdwoEBAMCABIE1AECEhppIFRoZSBuYW1lIG9mIHRoZSBpbmRleC4gRm9yIGV4YW1wbGU6
CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2luZGV4
ZXMve2luZGV4X2lkfWAKCg0KBQQDAgAFEgTUAQIICg0KBQQDAgABEgTUAQkNCg0KBQQDAgAD
EgTUARARCngKAgQEEgbYAQDkAQEaaiBUaGUgcmVxdWVzdCBmb3IgW0ZpcmVzdG9yZUFkbWlu
Lkxpc3RJbmRleGVzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEuRmlyZXN0b3Jl
QWRtaW4uTGlzdEluZGV4ZXNdLgoKCwoDBAQBEgTYAQgaCmAKBAQEAgASBNsBAhQaUiBUaGUg
ZGF0YWJhc2UgbmFtZS4gRm9yIGV4YW1wbGU6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2Rh
dGFiYXNlcy97ZGF0YWJhc2VfaWR9YAoKDQoFBAQCAAUSBNsBAggKDQoFBAQCAAESBNsBCQ8K
DQoFBAQCAAMSBNsBEhMKDAoEBAQCARIE3QECFAoNCgUEBAIBBRIE3QECCAoNCgUEBAIBARIE
3QEJDwoNCgUEBAIBAxIE3QESEwosCgQEBAICEgTgAQIWGh4gVGhlIHN0YW5kYXJkIExpc3Qg
cGFnZSBzaXplLgoKDQoFBAQCAgUSBOABAgcKDQoFBAQCAgESBOABCBEKDQoFBAQCAgMSBOAB
FBUKLQoEBAQCAxIE4wECGBofIFRoZSBzdGFuZGFyZCBMaXN0IHBhZ2UgdG9rZW4uCgoNCgUE
BAIDBRIE4wECCAoNCgUEBAIDARIE4wEJEwoNCgUEBAIDAxIE4wEWFwp4CgIEBRIG5wEA6wEB
GmogVGhlIHJlcXVlc3QgZm9yIFtGaXJlc3RvcmVBZG1pbi5EZWxldGVJbmRleF1bZ29vZ2xl
LmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkZpcmVzdG9yZUFkbWluLkRlbGV0ZUluZGV4XS4K
CgsKAwQFARIE5wEIGgpwCgQEBQIAEgTqAQISGmIgVGhlIGluZGV4IG5hbWUuIEZvciBleGFt
cGxlOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfS9p
bmRleGVzL3tpbmRleF9pZH1gCgoNCgUEBQIABRIE6gECCAoNCgUEBQIAARIE6gEJDQoNCgUE
BQIAAxIE6gEQEQp5CgIEBhIG7gEA9AEBGmsgVGhlIHJlc3BvbnNlIGZvciBbRmlyZXN0b3Jl
QWRtaW4uTGlzdEluZGV4ZXNdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5GaXJl
c3RvcmVBZG1pbi5MaXN0SW5kZXhlc10uCgoLCgMEBgESBO4BCBsKHAoEBAYCABIE8AECHRoO
IFRoZSBpbmRleGVzLgoKDQoFBAYCAAQSBPABAgoKDQoFBAYCAAYSBPABCxAKDQoFBAYCAAES
BPABERgKDQoFBAYCAAMSBPABGxwKMgoEBAYCARIE8wECHRokIFRoZSBzdGFuZGFyZCBMaXN0
IG5leHQtcGFnZSB0b2tlbi4KCg0KBQQGAgEFEgTzAQIICg0KBQQGAgEBEgTzAQkYCg0KBQQG
AgEDEgTzARscCoABCgIEBxIG9wEAiAIBGnIgVGhlIHJlcXVlc3QgZm9yIFtGaXJlc3RvcmVB
ZG1pbi5FeHBvcnREb2N1bWVudHNdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5G
aXJlc3RvcmVBZG1pbi5FeHBvcnREb2N1bWVudHNdLgoKCwoDBAcBEgT3AQgeCmwKBAQHAgAS
BPoBAhIaXiBEYXRhYmFzZSB0byBleHBvcnQuIFNob3VsZCBiZSBvZiB0aGUgZm9ybToKIGBw
cm9qZWN0cy97cHJvamVjdF9pZH0vZGF0YWJhc2VzL3tkYXRhYmFzZV9pZH1gLgoKDQoFBAcC
AAUSBPoBAggKDQoFBAcCAAESBPoBCQ0KDQoFBAcCAAMSBPoBEBEKUgoEBAcCARIE/QECJRpE
IFdoaWNoIGNvbGxlY3Rpb24gaWRzIHRvIGV4cG9ydC4gVW5zcGVjaWZpZWQgbWVhbnMgYWxs
IGNvbGxlY3Rpb25zLgoKDQoFBAcCAQQSBP0BAgoKDQoFBAcCAQUSBP0BCxEKDQoFBAcCAQES
BP0BEiAKDQoFBAcCAQMSBP0BIyQK/gMKBAQHAgISBIcCAh8a7wMgVGhlIG91dHB1dCBVUkku
IEN1cnJlbnRseSBvbmx5IHN1cHBvcnRzIEdvb2dsZSBDbG91ZCBTdG9yYWdlIFVSSXMgb2Yg
dGhlCiBmb3JtOiBgZ3M6Ly9CVUNLRVRfTkFNRVsvTkFNRVNQQUNFX1BBVEhdYCwgd2hlcmUg
YEJVQ0tFVF9OQU1FYCBpcyB0aGUgbmFtZQogb2YgdGhlIEdvb2dsZSBDbG91ZCBTdG9yYWdl
IGJ1Y2tldCBhbmQgYE5BTUVTUEFDRV9QQVRIYCBpcyBhbiBvcHRpb25hbAogR29vZ2xlIENs
b3VkIFN0b3JhZ2UgbmFtZXNwYWNlIHBhdGguIFdoZW4KIGNob29zaW5nIGEgbmFtZSwgYmUg
c3VyZSB0byBjb25zaWRlciBHb29nbGUgQ2xvdWQgU3RvcmFnZSBuYW1pbmcKIGd1aWRlbGlu
ZXM6IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zdG9yYWdlL2RvY3MvbmFtaW5nLgogSWYg
dGhlIFVSSSBpcyBhIGJ1Y2tldCAod2l0aG91dCBhIG5hbWVzcGFjZSBwYXRoKSwgYSBwcmVm
aXggd2lsbCBiZQogZ2VuZXJhdGVkIGJhc2VkIG9uIHRoZSBzdGFydCB0aW1lLgoKDQoFBAcC
AgUSBIcCAggKDQoFBAcCAgESBIcCCRoKDQoFBAcCAgMSBIcCHR4KgAEKAgQIEgaLAgCaAgEa
ciBUaGUgcmVxdWVzdCBmb3IgW0ZpcmVzdG9yZUFkbWluLkltcG9ydERvY3VtZW50c11bZ29v
Z2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGExLkZpcmVzdG9yZUFkbWluLkltcG9ydERvY3Vt
ZW50c10uCgoLCgMECAESBIsCCB4KcQoEBAgCABIEjgICEhpjIERhdGFiYXNlIHRvIGltcG9y
dCBpbnRvLiBTaG91bGQgYmUgb2YgdGhlIGZvcm06CiBgcHJvamVjdHMve3Byb2plY3RfaWR9
L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9YC4KCg0KBQQIAgAFEgSOAgIICg0KBQQIAgABEgSO
AgkNCg0KBQQIAgADEgSOAhARCmoKBAQIAgESBJICAiUaXCBXaGljaCBjb2xsZWN0aW9uIGlk
cyB0byBpbXBvcnQuIFVuc3BlY2lmaWVkIG1lYW5zIGFsbCBjb2xsZWN0aW9ucyBpbmNsdWRl
ZAogaW4gdGhlIGltcG9ydC4KCg0KBQQIAgEEEgSSAgIKCg0KBQQIAgEFEgSSAgsRCg0KBQQI
AgEBEgSSAhIgCg0KBQQIAgEDEgSSAiMkCsMCCgQECAICEgSZAgIeGrQCIExvY2F0aW9uIG9m
IHRoZSBleHBvcnRlZCBmaWxlcy4KIFRoaXMgbXVzdCBtYXRjaCB0aGUgb3V0cHV0X3VyaV9w
cmVmaXggb2YgYW4gRXhwb3J0RG9jdW1lbnRzUmVzcG9uc2UgZnJvbQogYW4gZXhwb3J0IHRo
YXQgaGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCiBTZWU6CiBbZ29vZ2xlLmZpcmVzdG9y
ZS5hZG1pbi52MWJldGExLkV4cG9ydERvY3VtZW50c1Jlc3BvbnNlLm91dHB1dF91cmlfcHJl
Zml4XVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEuRXhwb3J0RG9jdW1lbnRzUmVz
cG9uc2Uub3V0cHV0X3VyaV9wcmVmaXhdLgoKDQoFBAgCAgUSBJkCAggKDQoFBAgCAgESBJkC
CRkKDQoFBAgCAgMSBJkCHB0KbAoCBAkSBp0CAKICARpeIFJldHVybmVkIGluIHRoZSBbZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
bl0gcmVzcG9uc2UgZmllbGQuCgoLCgMECQESBJ0CCB8KtwEKBAQJAgASBKECAh8aqAEgTG9j
YXRpb24gb2YgdGhlIG91dHB1dCBmaWxlcy4gVGhpcyBjYW4gYmUgdXNlZCB0byBiZWdpbiBh
biBpbXBvcnQKIGludG8gQ2xvdWQgRmlyZXN0b3JlICh0aGlzIHByb2plY3Qgb3IgYW5vdGhl
ciBwcm9qZWN0KSBhZnRlciB0aGUgb3BlcmF0aW9uCiBjb21wbGV0ZXMgc3VjY2Vzc2Z1bGx5
LgoKDQoFBAkCAAUSBKECAggKDQoFBAkCAAESBKECCRoKDQoFBAkCAAMSBKECHR4KOAoCBAoS
BqUCALsCARoqIE1ldGFkYXRhIGZvciBFeHBvcnREb2N1bWVudHMgb3BlcmF0aW9ucy4KCgsK
AwQKARIEpQIIHwo6CgQECgIAEgSnAgIrGiwgVGhlIHRpbWUgdGhhdCB3b3JrIGJlZ2FuIG9u
IHRoZSBvcGVyYXRpb24uCgoNCgUECgIABhIEpwICGwoNCgUECgIAARIEpwIcJgoNCgUECgIA
AxIEpwIpKgp4CgQECgIBEgSrAgIpGmogVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBlbmRlZCwg
ZWl0aGVyIHN1Y2Nlc3NmdWxseSBvciBvdGhlcndpc2UuIFVuc2V0IGlmCiB0aGUgb3BlcmF0
aW9uIGlzIHN0aWxsIGFjdGl2ZS4KCg0KBQQKAgEGEgSrAgIbCg0KBQQKAgEBEgSrAhwkCg0K
BQQKAgEDEgSrAicoCjIKBAQKAgISBK4CAiUaJCBUaGUgc3RhdGUgb2YgdGhlIGV4cG9ydCBv
cGVyYXRpb24uCgoNCgUECgICBhIErgICEAoNCgUECgICARIErgIRIAoNCgUECgICAxIErgIj
JApBCgQECgIDEgSxAgIiGjMgQW4gZXN0aW1hdGUgb2YgdGhlIG51bWJlciBvZiBkb2N1bWVu
dHMgcHJvY2Vzc2VkLgoKDQoFBAoCAwYSBLECAgoKDQoFBAoCAwESBLECCx0KDQoFBAoCAwMS
BLECICEKPQoEBAoCBBIEtAICHhovIEFuIGVzdGltYXRlIG9mIHRoZSBudW1iZXIgb2YgYnl0
ZXMgcHJvY2Vzc2VkLgoKDQoFBAoCBAYSBLQCAgoKDQoFBAoCBAESBLQCCxkKDQoFBAoCBAMS
BLQCHB0KOAoEBAoCBRIEtwICJRoqIFdoaWNoIGNvbGxlY3Rpb24gaWRzIGFyZSBiZWluZyBl
eHBvcnRlZC4KCg0KBQQKAgUEEgS3AgIKCg0KBQQKAgUFEgS3AgsRCg0KBQQKAgUBEgS3AhIg
Cg0KBQQKAgUDEgS3AiMkCjkKBAQKAgYSBLoCAh8aKyBXaGVyZSB0aGUgZW50aXRpZXMgYXJl
IGJlaW5nIGV4cG9ydGVkIHRvLgoKDQoFBAoCBgUSBLoCAggKDQoFBAoCBgESBLoCCRoKDQoF
BAoCBgMSBLoCHR4KOAoCBAsSBr4CANQCARoqIE1ldGFkYXRhIGZvciBJbXBvcnREb2N1bWVu
dHMgb3BlcmF0aW9ucy4KCgsKAwQLARIEvgIIHwo6CgQECwIAEgTAAgIrGiwgVGhlIHRpbWUg
dGhhdCB3b3JrIGJlZ2FuIG9uIHRoZSBvcGVyYXRpb24uCgoNCgUECwIABhIEwAICGwoNCgUE
CwIAARIEwAIcJgoNCgUECwIAAxIEwAIpKgp4CgQECwIBEgTEAgIpGmogVGhlIHRpbWUgdGhl
IG9wZXJhdGlvbiBlbmRlZCwgZWl0aGVyIHN1Y2Nlc3NmdWxseSBvciBvdGhlcndpc2UuIFVu
c2V0IGlmCiB0aGUgb3BlcmF0aW9uIGlzIHN0aWxsIGFjdGl2ZS4KCg0KBQQLAgEGEgTEAgIb
Cg0KBQQLAgEBEgTEAhwkCg0KBQQLAgEDEgTEAicoCjIKBAQLAgISBMcCAiUaJCBUaGUgc3Rh
dGUgb2YgdGhlIGltcG9ydCBvcGVyYXRpb24uCgoNCgUECwICBhIExwICEAoNCgUECwICARIE
xwIRIAoNCgUECwICAxIExwIjJApBCgQECwIDEgTKAgIiGjMgQW4gZXN0aW1hdGUgb2YgdGhl
IG51bWJlciBvZiBkb2N1bWVudHMgcHJvY2Vzc2VkLgoKDQoFBAsCAwYSBMoCAgoKDQoFBAsC
AwESBMoCCx0KDQoFBAsCAwMSBMoCICEKPQoEBAsCBBIEzQICHhovIEFuIGVzdGltYXRlIG9m
IHRoZSBudW1iZXIgb2YgYnl0ZXMgcHJvY2Vzc2VkLgoKDQoFBAsCBAYSBM0CAgoKDQoFBAsC
BAESBM0CCxkKDQoFBAsCBAMSBM0CHB0KOAoEBAsCBRIE0AICJRoqIFdoaWNoIGNvbGxlY3Rp
b24gaWRzIGFyZSBiZWluZyBpbXBvcnRlZC4KCg0KBQQLAgUEEgTQAgIKCg0KBQQLAgUFEgTQ
AgsRCg0KBQQLAgUBEgTQAhIgCg0KBQQLAgUDEgTQAiMkCj0KBAQLAgYSBNMCAh4aLyBUaGUg
bG9jYXRpb24gb2YgdGhlIGRvY3VtZW50cyBiZWluZyBpbXBvcnRlZC4KCg0KBQQLAgYFEgTT
AgIICg0KBQQLAgYBEgTTAgkZCg0KBQQLAgYDEgTTAhwdCkUKAgUAEgbXAgDxAgEaNyBUaGUg
dmFyaW91cyBwb3NzaWJsZSBzdGF0ZXMgZm9yIGFuIG9uZ29pbmcgT3BlcmF0aW9uLgoKCwoD
BQABEgTXAgUTChwKBAUAAgASBNkCAhgaDiBVbnNwZWNpZmllZC4KCg0KBQUAAgABEgTZAgIT
Cg0KBQUAAgACEgTZAhYXCjkKBAUAAgESBNwCAhMaKyBSZXF1ZXN0IGlzIGJlaW5nIHByZXBh
cmVkIGZvciBwcm9jZXNzaW5nLgoKDQoFBQACAQESBNwCAg4KDQoFBQACAQISBNwCERIKNAoE
BQACAhIE3wICERomIFJlcXVlc3QgaXMgYWN0aXZlbHkgYmVpbmcgcHJvY2Vzc2VkLgoKDQoF
BQACAgESBN8CAgwKDQoFBQACAgISBN8CDxAKkAEKBAUAAgMSBOMCAhEagQEgUmVxdWVzdCBp
cyBpbiB0aGUgcHJvY2VzcyBvZiBiZWluZyBjYW5jZWxsZWQgYWZ0ZXIgdXNlciBjYWxsZWQK
IGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLkNhbmNlbE9wZXJhdGlvbiBvbiB0aGUg
b3BlcmF0aW9uLgoKDQoFBQACAwESBOMCAgwKDQoFBQACAwISBOMCDxAKTAoEBQACBBIE5gIC
ERo+IFJlcXVlc3QgaGFzIGJlZW4gcHJvY2Vzc2VkIGFuZCBpcyBpbiBpdHMgZmluYWxpemF0
aW9uIHN0YWdlLgoKDQoFBQACBAESBOYCAgwKDQoFBQACBAISBOYCDxAKMwoEBQACBRIE6QIC
ERolIFJlcXVlc3QgaGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoNCgUFAAIFARIE6QIC
DAoNCgUFAAIFAhIE6QIPEApPCgQFAAIGEgTsAgINGkEgUmVxdWVzdCBoYXMgZmluaXNoZWQg
YmVpbmcgcHJvY2Vzc2VkLCBidXQgZW5jb3VudGVyZWQgYW4gZXJyb3IuCgoNCgUFAAIGARIE
7AICCAoNCgUFAAIGAhIE7AILDAp2CgQFAAIHEgTwAgIQGmggUmVxdWVzdCBoYXMgZmluaXNo
ZWQgYmVpbmcgY2FuY2VsbGVkIGFmdGVyIHVzZXIgY2FsbGVkCiBnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9ucy5DYW5jZWxPcGVyYXRpb24uCgoNCgUFAAIHARIE8AICCwoNCgUFAAIH
AhIE8AIOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata ===
    # Fields for IndexOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: index Type: 9 ()
    # Field: operation_type Type: 14 (.google.firestore.admin.v1beta1.IndexOperationMetadata.OperationType)
    # Field: cancelled Type: 8 ()
    # Field: document_progress Type: 11 (.google.firestore.admin.v1beta1.Progress)

# Enum: IndexOperationMetadata::OperationType
our $IndexOperationMetadata_OPERATION_TYPE_UNSPECIFIED = 0;
our $IndexOperationMetadata_CREATING_INDEX = 1;

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress ===
    # Fields for Progress
    # Field: work_completed Type: 3 ()
    # Field: work_estimated Type: 3 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest ===
    # Fields for CreateIndexRequest
    # Field: parent Type: 9 ()
    # Field: index Type: 11 (.google.firestore.admin.v1beta1.Index)

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest ===
    # Fields for GetIndexRequest
    # Field: name Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest ===
    # Fields for ListIndexesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest ===
    # Fields for DeleteIndexRequest
    # Field: name Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse ===
    # Fields for ListIndexesResponse
    # Field: indexes Type: 11 (.google.firestore.admin.v1beta1.Index)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest ===
    # Fields for ExportDocumentsRequest
    # Field: name Type: 9 ()
    # Field: collection_ids Type: 9 ()
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest ===
    # Fields for ImportDocumentsRequest
    # Field: name Type: 9 ()
    # Field: collection_ids Type: 9 ()
    # Field: input_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsResponse ===
    # Fields for ExportDocumentsResponse
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsMetadata ===
    # Fields for ExportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1beta1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1beta1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1beta1.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsMetadata ===
    # Fields for ImportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1beta1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1beta1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1beta1.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: input_uri_prefix Type: 9 ()

# === Service Client: Google::Firestore::Admin::V1beta1::FirestoreAdmin::FirestoreAdminClient ===
package Google::Firestore::Admin::V1beta1::FirestoreAdmin::FirestoreAdminClient;

=pod

=head2 Service Client: Google::Firestore::Admin::V1beta1::FirestoreAdmin::FirestoreAdminClient

Client stub representing the remote C<FirestoreAdmin> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<firestore.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'firestore.googleapis.com:443' );

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

sub create_index {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'CreateIndex',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_indexes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'ListIndexes',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse',
    });
}

sub get_index {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'GetIndex',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta1::Index::Index',
    });
}

sub delete_index {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'DeleteIndex',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub export_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'ExportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta1.FirestoreAdmin',
        method         => 'ImportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta1::FirestoreAdmin - Compiled Protocol Buffers messages for google/firestore/admin/v1beta1/firestore_admin.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta1::FirestoreAdmin;

    my $msg = Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata->new({
        start_time => $start_time,
        end_time => $end_time,
        index => $index,
        operation_type => $operation_type,
    });

    # Read or update a field
    my $val = $msg->start_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta1/firestore_admin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata

Metadata for index operations. This metadata populates
the metadata field of [google.longrunning.Operation][google.longrunning.Operation].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time that work began on the operation.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation ended, either successfully or otherwise. Unset if
the operation is still active.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<String>

The index resource that this operation is acting on. For example:
`projects/{project_id}/databases/{database_id}/indexes/{index_id}`

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta1::IndexOperationMetadata::OperationType>)

The type of index operation.

=item * C<< $msg->cancelled() >> / C<< $msg->cancelled($value) >>

Type: C<Bool>

True if the [google.longrunning.Operation] was cancelled. If the
cancellation is in progress, cancelled will be true but
[google.longrunning.Operation.done][google.longrunning.Operation.done] will be false.

=item * C<< $msg->document_progress() >> / C<< $msg->document_progress($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress>)

Progress of the existing operation, measured in number of documents.

=back

=head3 Enum: IndexOperationMetadata::OperationType

=over 4

=item * C<OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATING_INDEX> => C<1>

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress

Measures the progress of a particular metric.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->work_completed() >> / C<< $msg->work_completed($value) >>

Type: C<Int64>

An estimate of how much work has been completed. Note that this may be
greater than `work_estimated`.

=item * C<< $msg->work_estimated() >> / C<< $msg->work_estimated($value) >>

Type: C<Int64>

An estimate of how much work needs to be performed. Zero if the
work estimate is unavailable. May change as work progresses.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest

The request for [FirestoreAdmin.CreateIndex][google.firestore.admin.v1beta1.FirestoreAdmin.CreateIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the database this index will apply to. For example:
`projects/{project_id}/databases/{database_id}`

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::Index::Index>)

The index to create. The name and state fields are output only and will be
ignored. Certain single field indexes cannot be created or deleted.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest

The request for [FirestoreAdmin.GetIndex][google.firestore.admin.v1beta1.FirestoreAdmin.GetIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the index. For example:
`projects/{project_id}/databases/{database_id}/indexes/{index_id}`

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest

The request for [FirestoreAdmin.ListIndexes][google.firestore.admin.v1beta1.FirestoreAdmin.ListIndexes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The database name. For example:
`projects/{project_id}/databases/{database_id}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The standard List page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The standard List page token.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest

The request for [FirestoreAdmin.DeleteIndex][google.firestore.admin.v1beta1.FirestoreAdmin.DeleteIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The index name. For example:
`projects/{project_id}/databases/{database_id}/indexes/{index_id}`

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse

The response for [FirestoreAdmin.ListIndexes][google.firestore.admin.v1beta1.FirestoreAdmin.ListIndexes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->indexes() >> / C<< $msg->indexes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::Index::Index>)

The indexes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The standard List next-page token.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest

The request for [FirestoreAdmin.ExportDocuments][google.firestore.admin.v1beta1.FirestoreAdmin.ExportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Database to export. Should be of the form:
`projects/{project_id}/databases/{database_id}`.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids to export. Unspecified means all collections.

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

The output URI. Currently only supports Google Cloud Storage URIs of the
form: `gs://BUCKET_NAME[/NAMESPACE_PATH]`, where `BUCKET_NAME` is the name
of the Google Cloud Storage bucket and `NAMESPACE_PATH` is an optional
Google Cloud Storage namespace path. When
choosing a name, be sure to consider Google Cloud Storage naming
guidelines: https://cloud.google.com/storage/docs/naming.
If the URI is a bucket (without a namespace path), a prefix will be
generated based on the start time.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest

The request for [FirestoreAdmin.ImportDocuments][google.firestore.admin.v1beta1.FirestoreAdmin.ImportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Database to import into. Should be of the form:
`projects/{project_id}/databases/{database_id}`.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids to import. Unspecified means all collections included
in the import.

=item * C<< $msg->input_uri_prefix() >> / C<< $msg->input_uri_prefix($value) >>

Type: C<String>

Location of the exported files.
This must match the output_uri_prefix of an ExportDocumentsResponse from
an export that has completed successfully.
See:
[google.firestore.admin.v1beta1.ExportDocumentsResponse.output_uri_prefix][google.firestore.admin.v1beta1.ExportDocumentsResponse.output_uri_prefix].

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsResponse

Returned in the [google.longrunning.Operation][google.longrunning.Operation] response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Location of the output files. This can be used to begin an import
into Cloud Firestore (this project or another project) after the operation
completes successfully.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsMetadata

Metadata for ExportDocuments operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time that work began on the operation.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation ended, either successfully or otherwise. Unset if
the operation is still active.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta1::OperationState>)

The state of the export operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress>)

An estimate of the number of documents processed.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress>)

An estimate of the number of bytes processed.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids are being exported.

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Where the entities are being exported to.

=back

=head2 Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsMetadata

Metadata for ImportDocuments operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time that work began on the operation.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation ended, either successfully or otherwise. Unset if
the operation is still active.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta1::OperationState>)

The state of the import operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress>)

An estimate of the number of documents processed.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress>)

An estimate of the number of bytes processed.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids are being imported.

=item * C<< $msg->input_uri_prefix() >> / C<< $msg->input_uri_prefix($value) >>

Type: C<String>

The location of the documents being imported.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta1::FirestoreAdmin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
