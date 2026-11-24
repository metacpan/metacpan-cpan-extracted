package Google::Cloud::Retail::V2::PurgeConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3B1cmdlX2NvbmZpZy5wcm90bxIWZ29vZ2xlLmNs
b3VkLnJldGFpbC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byIP
Cg1QdXJnZU1ldGFkYXRhItsBChVQdXJnZVByb2R1Y3RzTWV0YWRhdGESOwoLY3JlYXRlX3Rp
bWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3Vw
ZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGlt
ZRIjCg1zdWNjZXNzX2NvdW50GAMgASgDUgxzdWNjZXNzQ291bnQSIwoNZmFpbHVyZV9jb3Vu
dBgEIAEoA1IMZmFpbHVyZUNvdW50IocBChRQdXJnZVByb2R1Y3RzUmVxdWVzdBI8CgZwYXJl
bnQYASABKAlCJOBBAvpBHgoccmV0YWlsLmdvb2dsZWFwaXMuY29tL0JyYW5jaFIGcGFyZW50
EhsKBmZpbHRlchgCIAEoCUID4EECUgZmaWx0ZXISFAoFZm9yY2UYAyABKAhSBWZvcmNlIn8K
FVB1cmdlUHJvZHVjdHNSZXNwb25zZRIfCgtwdXJnZV9jb3VudBgBIAEoA1IKcHVyZ2VDb3Vu
dBJFCgxwdXJnZV9zYW1wbGUYAiADKAlCIvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL1By
b2R1Y3RSC3B1cmdlU2FtcGxlIooBChZQdXJnZVVzZXJFdmVudHNSZXF1ZXN0Ej0KBnBhcmVu
dBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50
EhsKBmZpbHRlchgCIAEoCUID4EECUgZmaWx0ZXISFAoFZm9yY2UYAyABKAhSBWZvcmNlIkkK
F1B1cmdlVXNlckV2ZW50c1Jlc3BvbnNlEi4KE3B1cmdlZF9ldmVudHNfY291bnQYASABKANS
EXB1cmdlZEV2ZW50c0NvdW50QrsBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MkIQUHVy
Z2VDb25maWdQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2Mi9yZXRh
aWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5SZXRhaWwuVjLKAhZHb29n
bGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMkrTLgoHEgUO
AKsBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADMKCQoCCCUSAxYAMwoICgEI
EgMXAEkKCQoCCAsSAxcASQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEKCQoCCAgS
AxkAMQoICgEIEgMaADMKCQoCCAESAxoAMwoICgEIEgMbACQKCQoCCCQSAxsAJAoICgEIEgMc
ADMKCQoCCCkSAxwAMwoICgEIEgMdADIKCQoCCC0SAx0AMgqRAQoCBAASAyEAGBqFASBNZXRh
ZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUgUHVyZ2Ugb3BlcmF0aW9uLgog
VGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uLm1ldGFkYXRhIGZpZWxkLgoKCgoDBAABEgMhCBUKmgEKAgQBEgQlADIBGo0BIE1ldGFk
YXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBQdXJnZVByb2R1Y3RzIG9wZXJh
dGlvbi4KIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbi5tZXRhZGF0YSBmaWVsZC4KCgoKAwQBARIDJQgdCiUKBAQBAgASAycCLBoY
IE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCgwKBQQBAgAGEgMnAhsKDAoFBAECAAESAyccJwoM
CgUEAQIAAxIDJyorCmMKBAQBAgESAysCLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1l
LiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0
aW1lLgoKDAoFBAECAQYSAysCGwoMCgUEAQIBARIDKxwnCgwKBQQBAgEDEgMrKisKPwoEBAEC
AhIDLgIaGjIgQ291bnQgb2YgZW50cmllcyB0aGF0IHdlcmUgZGVsZXRlZCBzdWNjZXNzZnVs
bHkuCgoMCgUEAQICBRIDLgIHCgwKBQQBAgIBEgMuCBUKDAoFBAECAgMSAy4YGQpJCgQEAQID
EgMxAhoaPCBDb3VudCBvZiBlbnRyaWVzIHRoYXQgZW5jb3VudGVyZWQgZXJyb3JzIHdoaWxl
IHByb2Nlc3NpbmcuCgoMCgUEAQIDBRIDMQIHCgwKBQQBAgMBEgMxCBUKDAoFBAECAwMSAzEY
GQo3CgIEAhIENQBrARorIFJlcXVlc3QgbWVzc2FnZSBmb3IgUHVyZ2VQcm9kdWN0cyBtZXRo
b2QuCgoKCgMEAgESAzUIHArEAQoEBAICABIEOQI8BBq1ASBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIGJyYW5jaCB1bmRlciB3aGljaCB0aGUgcHJvZHVjdHMgYXJlCiBj
cmVhdGVkLiBUaGUgZm9ybWF0IGlzCiBgcHJvamVjdHMvJHtwcm9qZWN0SWR9L2xvY2F0aW9u
cy9nbG9iYWwvY2F0YWxvZ3MvJHtjYXRhbG9nSWR9L2JyYW5jaGVzLyR7YnJhbmNoSWR9YAoK
DAoFBAICAAUSAzkCCAoMCgUEAgIAARIDOQkPCgwKBQQCAgADEgM5EhMKDQoFBAICAAgSBDkU
PAMKDwoIBAICAAicCAASAzoEKgoOCgcEAgIACJ8IEgM7BE4K3AkKBAQCAgESA2UCPRrOCSBS
ZXF1aXJlZC4gVGhlIGZpbHRlciBzdHJpbmcgdG8gc3BlY2lmeSB0aGUgcHJvZHVjdHMgdG8g
YmUgZGVsZXRlZCB3aXRoIGEKIGxlbmd0aCBsaW1pdCBvZiA1LDAwMCBjaGFyYWN0ZXJzLgoK
IEVtcHR5IHN0cmluZyBmaWx0ZXIgaXMgbm90IGFsbG93ZWQuICIqIiBpbXBsaWVzIGRlbGV0
ZSBhbGwgaXRlbXMgaW4gYQogYnJhbmNoLgoKIFRoZSBlbGlnaWJsZSBmaWVsZHMgZm9yIGZp
bHRlcmluZyBhcmU6CgogKiBgYXZhaWxhYmlsaXR5YDogRG91YmxlIHF1b3RlZAogW1Byb2R1
Y3QuYXZhaWxhYmlsaXR5XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1Y3QuYXZhaWxh
YmlsaXR5XSBzdHJpbmcuCiAqIGBjcmVhdGVfdGltZWAgOiBpbiBJU08gODYwMSAienVsdSIg
Zm9ybWF0LgoKIFN1cHBvcnRlZCBzeW50YXg6CgogKiBDb21wYXJhdG9ycyAoIj4iLCAiPCIs
ICI+PSIsICI8PSIsICI9IikuCiAgIEV4YW1wbGVzOgogICAqIGNyZWF0ZV90aW1lIDw9ICIy
MDE1LTAyLTEzVDE3OjA1OjQ2WiIKICAgKiBhdmFpbGFiaWxpdHkgPSAiSU5fU1RPQ0siCgog
KiBDb25qdW5jdGlvbnMgKCJBTkQiKQogICBFeGFtcGxlczoKICAgKiBjcmVhdGVfdGltZSA8
PSAiMjAxNS0wMi0xM1QxNzowNTo0NloiIEFORCBhdmFpbGFiaWxpdHkgPSAiUFJFT1JERVIi
CgogKiBEaXNqdW5jdGlvbnMgKCJPUiIpCiAgIEV4YW1wbGVzOgogICAqIGNyZWF0ZV90aW1l
IDw9ICIyMDE1LTAyLTEzVDE3OjA1OjQ2WiIgT1IgYXZhaWxhYmlsaXR5ID0gIklOX1NUT0NL
IgoKICogQ2FuIHN1cHBvcnQgbmVzdGVkIHF1ZXJpZXMuCiAgIEV4YW1wbGVzOgogICAqIChj
cmVhdGVfdGltZSA8PSAiMjAxNS0wMi0xM1QxNzowNTo0NloiIEFORCBhdmFpbGFiaWxpdHkg
PSAiUFJFT1JERVIiKQogICBPUiAoY3JlYXRlX3RpbWUgPj0gIjIwMTUtMDItMTRUMTM6MDM6
MzJaIiBBTkQgYXZhaWxhYmlsaXR5ID0gIklOX1NUT0NLIikKCiAqIEZpbHRlciBMaW1pdHM6
CiAgICogRmlsdGVyIHNob3VsZCBub3QgY29udGFpbiBtb3JlIHRoYW4gNiBjb25kaXRpb25z
LgogICAqIE1heCBuZXN0aW5nIGRlcHRoIHNob3VsZCBub3QgZXhjZWVkIDIgbGV2ZWxzLgoK
IEV4YW1wbGVzIHF1ZXJpZXM6CiAqIERlbGV0ZSBiYWNrIG9yZGVyIHByb2R1Y3RzIGNyZWF0
ZWQgYmVmb3JlIGEgdGltZXN0YW1wLgogICBjcmVhdGVfdGltZSA8PSAiMjAxNS0wMi0xM1Qx
NzowNTo0NloiIE9SIGF2YWlsYWJpbGl0eSA9ICJCQUNLT1JERVIiCgoMCgUEAgIBBRIDZQII
CgwKBQQCAgEBEgNlCQ8KDAoFBAICAQMSA2USEwoMCgUEAgIBCBIDZRQ8Cg8KCAQCAgEInAgA
EgNlFTsKmAEKBAQCAgISA2oCERqKASBBY3R1YWxseSBwZXJmb3JtIHRoZSBwdXJnZS4KIElm
IGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCB0aGUgbWV0aG9kIHdpbGwgcmV0dXJuIHRoZSBl
eHBlY3RlZCBwdXJnZSBjb3VudAogd2l0aG91dCBkZWxldGluZyBhbnkgcHJvZHVjdHMuCgoM
CgUEAgICBRIDagIGCgwKBQQCAgIBEgNqBwwKDAoFBAICAgMSA2oPEAq9AQoCBAMSBHAAegEa
sAEgUmVzcG9uc2Ugb2YgdGhlIFB1cmdlUHJvZHVjdHNSZXF1ZXN0LiBJZiB0aGUgbG9uZyBy
dW5uaW5nIG9wZXJhdGlvbiBpcwogc3VjY2Vzc2Z1bGx5IGRvbmUsIHRoZW4gdGhpcyBtZXNz
YWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMu
cmVzcG9uc2UgZmllbGQuCgoKCgMEAwESA3AIHQpPCgQEAwIAEgNyAhgaQiBUaGUgdG90YWwg
Y291bnQgb2YgcHJvZHVjdHMgcHVyZ2VkIGFzIGEgcmVzdWx0IG9mIHRoZSBvcGVyYXRpb24u
CgoMCgUEAwIABRIDcgIHCgwKBQQDAgABEgNyCBMKDAoFBAMCAAMSA3IWFwq5AQoEBAMCARIE
dwJ5BBqqASBBIHNhbXBsZSBvZiB0aGUgcHJvZHVjdCBuYW1lcyB0aGF0IHdpbGwgYmUgZGVs
ZXRlZC4KIE9ubHkgcG9wdWxhdGVkIGlmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLiBBIG1h
eCBvZiAxMDAgbmFtZXMgd2lsbCBiZQogcmV0dXJuZWQgYW5kIHRoZSBuYW1lcyBhcmUgY2hv
c2VuIGF0IHJhbmRvbS4KCgwKBQQDAgEEEgN3AgoKDAoFBAMCAQUSA3cLEQoMCgUEAwIBARID
dxIeCgwKBQQDAgEDEgN3ISIKDQoFBAMCAQgSBHcjeQMKDgoHBAMCAQifCBIDeARPCjoKAgQE
EgV9AKMBARotIFJlcXVlc3QgbWVzc2FnZSBmb3IgUHVyZ2VVc2VyRXZlbnRzIG1ldGhvZC4K
CgoKAwQEARIDfQgeCrABCgQEBAIAEgaBAQKEAQQanwEgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBjYXRhbG9nIHVuZGVyIHdoaWNoIHRoZSBldmVudHMgYXJlCiBjcmVh
dGVkLiBUaGUgZm9ybWF0IGlzCiBgcHJvamVjdHMvJHtwcm9qZWN0SWR9L2xvY2F0aW9ucy9n
bG9iYWwvY2F0YWxvZ3MvJHtjYXRhbG9nSWR9YAoKDQoFBAQCAAUSBIEBAggKDQoFBAQCAAES
BIEBCQ8KDQoFBAQCAAMSBIEBEhMKDwoFBAQCAAgSBoEBFIQBAwoQCggEBAIACJwIABIEggEE
KgoPCgcEBAIACJ8IEgSDAQRPCrsHCgQEBAIBEgSdAQI9GqwHIFJlcXVpcmVkLiBUaGUgZmls
dGVyIHN0cmluZyB0byBzcGVjaWZ5IHRoZSBldmVudHMgdG8gYmUgZGVsZXRlZCB3aXRoIGEK
IGxlbmd0aCBsaW1pdCBvZiA1LDAwMCBjaGFyYWN0ZXJzLiBFbXB0eSBzdHJpbmcgZmlsdGVy
IGlzIG5vdCBhbGxvd2VkLiBUaGUKIGVsaWdpYmxlIGZpZWxkcyBmb3IgZmlsdGVyaW5nIGFy
ZToKCiAqIGBldmVudFR5cGVgOiBEb3VibGUgcXVvdGVkCiBbVXNlckV2ZW50LmV2ZW50X3R5
cGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2ZW50LmV2ZW50X3R5cGVdIHN0cmlu
Zy4KICogYGV2ZW50VGltZWA6IGluIElTTyA4NjAxICJ6dWx1IiBmb3JtYXQuCiAqIGB2aXNp
dG9ySWRgOiBEb3VibGUgcXVvdGVkIHN0cmluZy4gU3BlY2lmeWluZyB0aGlzIHdpbGwgZGVs
ZXRlIGFsbAogICBldmVudHMgYXNzb2NpYXRlZCB3aXRoIGEgdmlzaXRvci4KICogYHVzZXJJ
ZGA6IERvdWJsZSBxdW90ZWQgc3RyaW5nLiBTcGVjaWZ5aW5nIHRoaXMgd2lsbCBkZWxldGUg
YWxsIGV2ZW50cwogICBhc3NvY2lhdGVkIHdpdGggYSB1c2VyLgoKIEV4YW1wbGVzOgoKICog
RGVsZXRpbmcgYWxsIGV2ZW50cyBpbiBhIHRpbWUgcmFuZ2U6CiAgIGBldmVudFRpbWUgPiAi
MjAxMi0wNC0yM1QxODoyNTo0My41MTFaIgogICBldmVudFRpbWUgPCAiMjAxMi0wNC0yM1Qx
ODozMDo0My41MTFaImAKICogRGVsZXRpbmcgc3BlY2lmaWMgZXZlbnRUeXBlIGluIHRpbWUg
cmFuZ2U6CiAgIGBldmVudFRpbWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaIiBldmVu
dFR5cGUgPSAiZGV0YWlsLXBhZ2UtdmlldyJgCiAqIERlbGV0aW5nIGFsbCBldmVudHMgZm9y
IGEgc3BlY2lmaWMgdmlzaXRvcjoKICAgYHZpc2l0b3JJZCA9ICJ2aXNpdG9yMTAyNCJgCgog
VGhlIGZpbHRlcmluZyBmaWVsZHMgYXJlIGFzc3VtZWQgdG8gaGF2ZSBhbiBpbXBsaWNpdCBB
TkQuCgoNCgUEBAIBBRIEnQECCAoNCgUEBAIBARIEnQEJDwoNCgUEBAIBAxIEnQESEwoNCgUE
BAIBCBIEnQEUPAoQCggEBAIBCJwIABIEnQEVOwqcAQoEBAQCAhIEogECERqNASBBY3R1YWxs
eSBwZXJmb3JtIHRoZSBwdXJnZS4KIElmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCB0aGUg
bWV0aG9kIHdpbGwgcmV0dXJuIHRoZSBleHBlY3RlZCBwdXJnZSBjb3VudAogd2l0aG91dCBk
ZWxldGluZyBhbnkgdXNlciBldmVudHMuCgoNCgUEBAICBRIEogECBgoNCgUEBAICARIEogEH
DAoNCgUEBAICAxIEogEPEArBAQoCBAUSBqgBAKsBARqyASBSZXNwb25zZSBvZiB0aGUgUHVy
Z2VVc2VyRXZlbnRzUmVxdWVzdC4gSWYgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24gaXMK
IHN1Y2Nlc3NmdWxseSBkb25lLCB0aGVuIHRoaXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0
aGUKIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkLgoKCwoD
BAUBEgSoAQgfCk4KBAQFAgASBKoBAiAaQCBUaGUgdG90YWwgY291bnQgb2YgZXZlbnRzIHB1
cmdlZCBhcyBhIHJlc3VsdCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAUCAAUSBKoBAgcKDQoF
BAUCAAESBKoBCBsKDQoFBAUCAAMSBKoBHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeMetadata ===
    # Fields for PurgeMetadata

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsMetadata ===
    # Fields for PurgeProductsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsRequest ===
    # Fields for PurgeProductsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsResponse ===
    # Fields for PurgeProductsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purged_events_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::PurgeConfig;

    my $msg = Google::Cloud::Retail::V2::PurgeConfig::PurgeMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::PurgeConfig::PurgeMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeMetadata

Metadata related to the progress of the Purge operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsMetadata

Metadata related to the progress of the PurgeProducts operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=back

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsRequest

Request message for PurgeProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the branch under which the products are
created. The format is
`projects/${projectId}/locations/global/catalogs/${catalogId}/branches/${branchId}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the products to be deleted with a
length limit of 5,000 characters.

Empty string filter is not allowed. "*" implies delete all items in a
branch.

The eligible fields for filtering are:

* `availability`: Double quoted
[Product.availability][google.cloud.retail.v2.Product.availability] string.
* `create_time` : in ISO 8601 "zulu" format.

Supported syntax:

* Comparators (">", "<", ">=", "<=", "=").
  Examples:
  * create_time <= "2015-02-13T17:05:46Z"
  * availability = "IN_STOCK"

* Conjunctions ("AND")
  Examples:
  * create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER"

* Disjunctions ("OR")
  Examples:
  * create_time <= "2015-02-13T17:05:46Z" OR availability = "IN_STOCK"

* Can support nested queries.
  Examples:
  * (create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER")
  OR (create_time >= "2015-02-14T13:03:32Z" AND availability = "IN_STOCK")

* Filter Limits:
  * Filter should not contain more than 6 conditions.
  * Max nesting depth should not exceed 2 levels.

Examples queries:
* Delete back order products created before a timestamp.
  create_time <= "2015-02-13T17:05:46Z" OR availability = "BACKORDER"

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually perform the purge.
If `force` is set to false, the method will return the expected purge count
without deleting any products.

=back

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeProductsResponse

Response of the PurgeProductsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of products purged as a result of the operation.

=item * C<< $msg->purge_sample() >> / C<< $msg->purge_sample($value) >>

Type: C<String>

A sample of the product names that will be deleted.
Only populated if `force` is set to false. A max of 100 names will be
returned and the names are chosen at random.

=back

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeUserEventsRequest

Request message for PurgeUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the catalog under which the events are
created. The format is
`projects/${projectId}/locations/global/catalogs/${catalogId}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the events to be deleted with a
length limit of 5,000 characters. Empty string filter is not allowed. The
eligible fields for filtering are:

* `eventType`: Double quoted
[UserEvent.event_type][google.cloud.retail.v2.UserEvent.event_type] string.
* `eventTime`: in ISO 8601 "zulu" format.
* `visitorId`: Double quoted string. Specifying this will delete all
  events associated with a visitor.
* `userId`: Double quoted string. Specifying this will delete all events
  associated with a user.

Examples:

* Deleting all events in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z"`
* Deleting specific eventType in time range:
  `eventTime > "2012-04-23T18:25:43.511Z" eventType = "detail-page-view"`
* Deleting all events for a specific visitor:
  `visitorId = "visitor1024"`

The filtering fields are assumed to have an implicit AND.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually perform the purge.
If `force` is set to false, the method will return the expected purge count
without deleting any user events.

=back

=head2 Google::Cloud::Retail::V2::PurgeConfig::PurgeUserEventsResponse

Response of the PurgeUserEventsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purged_events_count() >> / C<< $msg->purged_events_count($value) >>

Type: C<Int64>

The total count of events purged as a result of the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
