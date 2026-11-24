package Google::Cloud::Osconfig::V1::OsconfigZonalService;

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
    eval { require Google::Cloud::Osconfig::V1::Inventory };
    eval { require Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports };
    eval { require Google::Cloud::Osconfig::V1::OsPolicyAssignments };
    eval { require Google::Cloud::Osconfig::V1::Vulnerability };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvb3Njb25maWcvdjEvb3Njb25maWdfem9uYWxfc2VydmljZS5wcm90
bxIYZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxooZ29vZ2xlL2Nsb3VkL29zY29uZmlnL3Yx
L2ludmVudG9yeS5wcm90bxo7Z29vZ2xlL2Nsb3VkL29zY29uZmlnL3YxL29zX3BvbGljeV9h
c3NpZ25tZW50X3JlcG9ydHMucHJvdG8aNGdvb2dsZS9jbG91ZC9vc2NvbmZpZy92MS9vc19w
b2xpY3lfYXNzaWdubWVudHMucHJvdG8aLGdvb2dsZS9jbG91ZC9vc2NvbmZpZy92MS92dWxu
ZXJhYmlsaXR5LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bzKs
FwoUT3NDb25maWdab25hbFNlcnZpY2USvgIKGENyZWF0ZU9TUG9saWN5QXNzaWdubWVudBI5
Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5DcmVhdGVPU1BvbGljeUFzc2lnbm1lbnRSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLHAYLT5JMCTyI3L3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vb3NQb2xpY3lBc3NpZ25tZW50czoUb3NfcG9s
aWN5X2Fzc2lnbm1lbnTaQTNwYXJlbnQsb3NfcG9saWN5X2Fzc2lnbm1lbnQsb3NfcG9saWN5
X2Fzc2lnbm1lbnRfaWTKQTkKEk9TUG9saWN5QXNzaWdubWVudBIjT1NQb2xpY3lBc3NpZ25t
ZW50T3BlcmF0aW9uTWV0YWRhdGESwAIKGFVwZGF0ZU9TUG9saWN5QXNzaWdubWVudBI5Lmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MS5VcGRhdGVPU1BvbGljeUFzc2lnbm1lbnRSZXF1ZXN0
Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLJAYLT5JMCZDJML3YxL3tvc19wb2xp
Y3lfYXNzaWdubWVudC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovb3NQb2xpY3lBc3Np
Z25tZW50cy8qfToUb3NfcG9saWN5X2Fzc2lnbm1lbnTaQSBvc19wb2xpY3lfYXNzaWdubWVu
dCx1cGRhdGVfbWFza8pBOQoST1NQb2xpY3lBc3NpZ25tZW50EiNPU1BvbGljeUFzc2lnbm1l
bnRPcGVyYXRpb25NZXRhZGF0YRLFAQoVR2V0T1NQb2xpY3lBc3NpZ25tZW50EjYuZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLnYxLkdldE9TUG9saWN5QXNzaWdubWVudFJlcXVlc3QaLC5nb29n
bGUuY2xvdWQub3Njb25maWcudjEuT1NQb2xpY3lBc3NpZ25tZW50IkaC0+STAjkSNy92MS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL29zUG9saWN5QXNzaWdubWVudHMvKn3aQQRu
YW1lEtgBChdMaXN0T1NQb2xpY3lBc3NpZ25tZW50cxI4Lmdvb2dsZS5jbG91ZC5vc2NvbmZp
Zy52MS5MaXN0T1NQb2xpY3lBc3NpZ25tZW50c1JlcXVlc3QaOS5nb29nbGUuY2xvdWQub3Nj
b25maWcudjEuTGlzdE9TUG9saWN5QXNzaWdubWVudHNSZXNwb25zZSJIgtPkkwI5EjcvdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9vc1BvbGljeUFzc2lnbm1lbnRz2kEG
cGFyZW50EvwBCh9MaXN0T1NQb2xpY3lBc3NpZ25tZW50UmV2aXNpb25zEkAuZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxLkxpc3RPU1BvbGljeUFzc2lnbm1lbnRSZXZpc2lvbnNSZXF1ZXN0
GkEuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLkxpc3RPU1BvbGljeUFzc2lnbm1lbnRSZXZp
c2lvbnNSZXNwb25zZSJUgtPkkwJHEkUvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9vc1BvbGljeUFzc2lnbm1lbnRzLyp9Omxpc3RSZXZpc2lvbnPaQQRuYW1lEvwBChhEZWxl
dGVPU1BvbGljeUFzc2lnbm1lbnQSOS5nb29nbGUuY2xvdWQub3Njb25maWcudjEuRGVsZXRl
T1NQb2xpY3lBc3NpZ25tZW50UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24ihQGC0+STAjkqNy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL29zUG9saWN5
QXNzaWdubWVudHMvKn3aQQRuYW1lykE8ChVnb29nbGUucHJvdG9idWYuRW1wdHkSI09TUG9s
aWN5QXNzaWdubWVudE9wZXJhdGlvbk1ldGFkYXRhEuoBChtHZXRPU1BvbGljeUFzc2lnbm1l
bnRSZXBvcnQSPC5nb29nbGUuY2xvdWQub3Njb25maWcudjEuR2V0T1NQb2xpY3lBc3NpZ25t
ZW50UmVwb3J0UmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUFz
c2lnbm1lbnRSZXBvcnQiWYLT5JMCTBJKL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovaW5zdGFuY2VzLyovb3NQb2xpY3lBc3NpZ25tZW50cy8qL3JlcG9ydH3aQQRuYW1lEoAC
Ch1MaXN0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0cxI+Lmdvb2dsZS5jbG91ZC5vc2NvbmZp
Zy52MS5MaXN0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0c1JlcXVlc3QaPy5nb29nbGUuY2xv
dWQub3Njb25maWcudjEuTGlzdE9TUG9saWN5QXNzaWdubWVudFJlcG9ydHNSZXNwb25zZSJe
gtPkkwJPEk0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8q
L29zUG9saWN5QXNzaWdubWVudHMvKn0vcmVwb3J0c9pBBnBhcmVudBKqAQoMR2V0SW52ZW50
b3J5Ei0uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLkdldEludmVudG9yeVJlcXVlc3QaIy5n
b29nbGUuY2xvdWQub3Njb25maWcudjEuSW52ZW50b3J5IkaC0+STAjkSNy92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qL2ludmVudG9yeX3aQQRuYW1lEsQB
Cg9MaXN0SW52ZW50b3JpZXMSMC5nb29nbGUuY2xvdWQub3Njb25maWcudjEuTGlzdEludmVu
dG9yaWVzUmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5MaXN0SW52ZW50b3Jp
ZXNSZXNwb25zZSJMgtPkkwI9EjsvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2luc3RhbmNlcy8qfS9pbnZlbnRvcmllc9pBBnBhcmVudBLSAQoWR2V0VnVsbmVyYWJpbGl0
eVJlcG9ydBI3Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5HZXRWdWxuZXJhYmlsaXR5UmVw
b3J0UmVxdWVzdBotLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5WdWxuZXJhYmlsaXR5UmVw
b3J0IlCC0+STAkMSQS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNl
cy8qL3Z1bG5lcmFiaWxpdHlSZXBvcnR92kEEbmFtZRLoAQoYTGlzdFZ1bG5lcmFiaWxpdHlS
ZXBvcnRzEjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLkxpc3RWdWxuZXJhYmlsaXR5UmVw
b3J0c1JlcXVlc3QaOi5nb29nbGUuY2xvdWQub3Njb25maWcudjEuTGlzdFZ1bG5lcmFiaWxp
dHlSZXBvcnRzUmVzcG9uc2UiVYLT5JMCRhJEL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9pbnN0YW5jZXMvKn0vdnVsbmVyYWJpbGl0eVJlcG9ydHPaQQZwYXJlbnQaS8pB
F29zY29uZmlnLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybULJAQocY29tLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MUIZ
T3NDb25maWdab25hbFNlcnZpY2VQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL29zY29u
ZmlnL2FwaXYxL29zY29uZmlncGI7b3Njb25maWdwYqoCGEdvb2dsZS5DbG91ZC5Pc0NvbmZp
Zy5WMcoCGEdvb2dsZVxDbG91ZFxPc0NvbmZpZ1xWMeoCG0dvb2dsZTo6Q2xvdWQ6Ok9zQ29u
ZmlnOjpWMUrmKAoHEgUOAMkBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAMgoJCgIDAxIDFQBF
CgkKAgMEEgMWAD4KCQoCAwUSAxcANgoJCgIDBhIDGAAtCggKAQgSAxoANQoJCgIIJRIDGgA1
CggKAQgSAxsATwoJCgIICxIDGwBPCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOgoJ
CgIICBIDHQA6CggKAQgSAx4ANQoJCgIIARIDHgA1CggKAQgSAx8ANQoJCgIIKRIDHwA1CggK
AQgSAyAANAoJCgIILRIDIAA0CrsBCgIGABIFJgDJAQEarQEgWm9uYWwgT1MgQ29uZmlnIEFQ
SQoKIFRoZSBPUyBDb25maWcgc2VydmljZSBpcyB0aGUgc2VydmVyLXNpZGUgY29tcG9uZW50
IHRoYXQgYWxsb3dzIHVzZXJzIHRvCiBtYW5hZ2UgcGFja2FnZSBpbnN0YWxsYXRpb25zIGFu
ZCBwYXRjaCBqb2JzIGZvciBDb21wdXRlIEVuZ2luZSBWTSBpbnN0YW5jZXMuCgoKCgMGAAES
AyYIHAoKCgMGAAMSAycCPwoMCgUGAAOZCBIDJwI/CgsKAwYAAxIEKAIpNwoNCgUGAAOaCBIE
KAIpNwraAwoEBgACABIENAJAAxrLAyBDcmVhdGUgYW4gT1MgcG9saWN5IGFzc2lnbm1lbnQu
CgogVGhpcyBtZXRob2QgYWxzbyBjcmVhdGVzIHRoZSBmaXJzdCByZXZpc2lvbiBvZiB0aGUg
T1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBtZXRob2QgcmV0dXJucyBhIGxvbmcgcnVu
bmluZyBvcGVyYXRpb24gKExSTykgdGhhdCBjb250YWlucyB0aGUKIHJvbGxvdXQgZGV0YWls
cy4gVGhlIHJvbGxvdXQgY2FuIGJlIGNhbmNlbGxlZCBieSBjYW5jZWxsaW5nIHRoZSBMUk8u
CgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBbTWV0aG9kOgogcHJvamVjdHMubG9jYXRp
b25zLm9zUG9saWN5QXNzaWdubWVudHMub3BlcmF0aW9ucy5jYW5jZWxdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3Mvb3Njb25maWcvcmVzdC92MS9wcm9qZWN0cy5s
b2NhdGlvbnMub3NQb2xpY3lBc3NpZ25tZW50cy5vcGVyYXRpb25zL2NhbmNlbCkuCgoMCgUG
AAIAARIDNAYeCgwKBQYAAgACEgM0Hz4KDAoFBgACAAMSAzUPKwoNCgUGAAIABBIENgQ5BgoR
CgkGAAIABLDKvCISBDYEOQYKDQoFBgACAAQSBDoEOz4KEAoIBgACAASbCAASBDoEOz4KDQoF
BgACAAQSBDwEPwYKDwoHBgACAASZCBIEPAQ/BgraAwoEBgACARIESwJWAxrLAyBVcGRhdGUg
YW4gZXhpc3RpbmcgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBtZXRob2QgY3JlYXRl
cyBhIG5ldyByZXZpc2lvbiBvZiB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBt
ZXRob2QgcmV0dXJucyBhIGxvbmcgcnVubmluZyBvcGVyYXRpb24gKExSTykgdGhhdCBjb250
YWlucyB0aGUKIHJvbGxvdXQgZGV0YWlscy4gVGhlIHJvbGxvdXQgY2FuIGJlIGNhbmNlbGxl
ZCBieSBjYW5jZWxsaW5nIHRoZSBMUk8uCgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBb
TWV0aG9kOgogcHJvamVjdHMubG9jYXRpb25zLm9zUG9saWN5QXNzaWdubWVudHMub3BlcmF0
aW9ucy5jYW5jZWxdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3Mvb3Nj
b25maWcvcmVzdC92MS9wcm9qZWN0cy5sb2NhdGlvbnMub3NQb2xpY3lBc3NpZ25tZW50cy5v
cGVyYXRpb25zL2NhbmNlbCkuCgoMCgUGAAIBARIDSwYeCgwKBQYAAgECEgNLHz4KDAoFBgAC
AQMSA0wPKwoNCgUGAAIBBBIETQRQBgoRCgkGAAIBBLDKvCISBE0EUAYKDAoFBgACAQQSA1EE
TgoPCggGAAIBBJsIABIDUQROCg0KBQYAAgEEEgRSBFUGCg8KBwYAAgEEmQgSBFIEVQYK4QEK
BAYAAgISBF0CYwMa0gEgUmV0cmlldmUgYW4gZXhpc3RpbmcgT1MgcG9saWN5IGFzc2lnbm1l
bnQuCgogVGhpcyBtZXRob2QgYWx3YXlzIHJldHVybnMgdGhlIGxhdGVzdCByZXZpc2lvbi4g
SW4gb3JkZXIgdG8gcmV0cmlldmUgYQogcHJldmlvdXMgcmV2aXNpb24gb2YgdGhlIGFzc2ln
bm1lbnQsIGFsc28gcHJvdmlkZSB0aGUgcmV2aXNpb24gSUQgaW4gdGhlCiBgbmFtZWAgcGFy
YW1ldGVyLgoKDAoFBgACAgESA10GGwoMCgUGAAICAhIDXRw4CgwKBQYAAgIDEgNeDyEKDQoF
BgACAgQSBF8EYQYKEQoJBgACAgSwyrwiEgRfBGEGCgwKBQYAAgIEEgNiBDIKDwoIBgACAgSb
CAASA2IEMgqLAQoEBgACAxIEaAJuAxp9IExpc3QgdGhlIE9TIHBvbGljeSBhc3NpZ25tZW50
cyB1bmRlciB0aGUgcGFyZW50IHJlc291cmNlLgoKIEZvciBlYWNoIE9TIHBvbGljeSBhc3Np
Z25tZW50LCB0aGUgbGF0ZXN0IHJldmlzaW9uIGlzIHJldHVybmVkLgoKDAoFBgACAwESA2gG
HQoMCgUGAAIDAhIDaB48CgwKBQYAAgMDEgNpDy4KDQoFBgACAwQSBGoEbAYKEQoJBgACAwSw
yrwiEgRqBGwGCgwKBQYAAgMEEgNtBDQKDwoIBgACAwSbCAASA20ENApZCgQGAAIEEgRxAncD
GksgTGlzdCB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgcmV2aXNpb25zIGZvciBhIGdpdmVu
IE9TIHBvbGljeSBhc3NpZ25tZW50LgoKDAoFBgACBAESA3EGJQoMCgUGAAIEAhIDcSZMCgwK
BQYAAgQDEgNyDzYKDQoFBgACBAQSBHMEdQYKEQoJBgACBASwyrwiEgRzBHUGCgwKBQYAAgQE
EgN2BDIKDwoIBgACBASbCAASA3YEMgrGBAoEBgACBRIGhQECjwEDGrUEIERlbGV0ZSB0aGUg
T1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBtZXRob2QgY3JlYXRlcyBhIG5ldyByZXZp
c2lvbiBvZiB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBtZXRob2QgcmV0dXJu
cyBhIGxvbmcgcnVubmluZyBvcGVyYXRpb24gKExSTykgdGhhdCBjb250YWlucyB0aGUKIHJv
bGxvdXQgZGV0YWlscy4gVGhlIHJvbGxvdXQgY2FuIGJlIGNhbmNlbGxlZCBieSBjYW5jZWxs
aW5nIHRoZSBMUk8uCgogSWYgdGhlIExSTyBjb21wbGV0ZXMgYW5kIGlzIG5vdCBjYW5jZWxs
ZWQsIGFsbCByZXZpc2lvbnMgYXNzb2NpYXRlZCB3aXRoCiB0aGUgT1MgcG9saWN5IGFzc2ln
bm1lbnQgYXJlIGRlbGV0ZWQuCgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBbTWV0aG9k
OgogcHJvamVjdHMubG9jYXRpb25zLm9zUG9saWN5QXNzaWdubWVudHMub3BlcmF0aW9ucy5j
YW5jZWxdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3Mvb3Njb25maWcv
cmVzdC92MS9wcm9qZWN0cy5sb2NhdGlvbnMub3NQb2xpY3lBc3NpZ25tZW50cy5vcGVyYXRp
b25zL2NhbmNlbCkuCgoNCgUGAAIFARIEhQEGHgoNCgUGAAIFAhIEhQEfPgoNCgUGAAIFAxIE
hgEPKwoPCgUGAAIFBBIGhwEEiQEGChMKCQYAAgUEsMq8IhIGhwEEiQEGCg0KBQYAAgUEEgSK
AQQyChAKCAYAAgUEmwgAEgSKAQQyCg8KBQYAAgUEEgaLAQSOAQYKEQoHBgACBQSZCBIGiwEE
jgEGCmUKBAYAAgYSBpMBApkBAxpVIEdldCB0aGUgT1MgcG9saWN5IGFzc3NpZ25tZW50IHJl
cG9ydCBmb3IgdGhlIHNwZWNpZmllZCBDb21wdXRlIEVuZ2luZSBWTQogaW5zdGFuY2UuCgoN
CgUGAAIGARIEkwEGIQoNCgUGAAIGAhIEkwEiRAoNCgUGAAIGAxIElAEPJwoPCgUGAAIGBBIG
lQEElwEGChMKCQYAAgYEsMq8IhIGlQEElwEGCg0KBQYAAgYEEgSYAQQyChAKCAYAAgYEmwgA
EgSYAQQyCnAKBAYAAgcSBp0BAqMBAxpgIExpc3QgT1MgcG9saWN5IGFzc3NpZ25tZW50IHJl
cG9ydHMgZm9yIGFsbCBDb21wdXRlIEVuZ2luZSBWTSBpbnN0YW5jZXMgaW4KIHRoZSBzcGVj
aWZpZWQgem9uZS4KCg0KBQYAAgcBEgSdAQYjCg0KBQYAAgcCEgSdASRICg0KBQYAAgcDEgSe
AQ80Cg8KBQYAAgcEEgafAQShAQYKEwoJBgACBwSwyrwiEgafAQShAQYKDQoFBgACBwQSBKIB
BDQKEAoIBgACBwSbCAASBKIBBDQKkQEKBAYAAggSBqcBAqwBAxqAASBHZXQgaW52ZW50b3J5
IGRhdGEgZm9yIHRoZSBzcGVjaWZpZWQgVk0gaW5zdGFuY2UuIElmIHRoZSBWTSBoYXMgbm8K
IGFzc29jaWF0ZWQgaW52ZW50b3J5LCB0aGUgbWVzc2FnZSBgTk9UX0ZPVU5EYCBpcyByZXR1
cm5lZC4KCg0KBQYAAggBEgSnAQYSCg0KBQYAAggCEgSnARMmCg0KBQYAAggDEgSnATE6Cg8K
BQYAAggEEgaoAQSqAQYKEwoJBgACCASwyrwiEgaoAQSqAQYKDQoFBgACCAQSBKsBBDIKEAoI
BgACCASbCAASBKsBBDIKUQoEBgACCRIGrwECtQEDGkEgTGlzdCBpbnZlbnRvcnkgZGF0YSBm
b3IgYWxsIFZNIGluc3RhbmNlcyBpbiB0aGUgc3BlY2lmaWVkIHpvbmUuCgoNCgUGAAIJARIE
rwEGFQoNCgUGAAIJAhIErwEWLAoNCgUGAAIJAxIEsAEPJgoPCgUGAAIJBBIGsQEEswEGChMK
CQYAAgkEsMq8IhIGsQEEswEGCg0KBQYAAgkEEgS0AQQ0ChAKCAYAAgkEmwgAEgS0AQQ0Cp4B
CgQGAAIKEga5AQK/AQMajQEgR2V0cyB0aGUgdnVsbmVyYWJpbGl0eSByZXBvcnQgZm9yIHRo
ZSBzcGVjaWZpZWQgVk0gaW5zdGFuY2UuIE9ubHkgVk1zIHdpdGgKIGludmVudG9yeSBkYXRh
IGhhdmUgdnVsbmVyYWJpbGl0eSByZXBvcnRzIGFzc29jaWF0ZWQgd2l0aCB0aGVtLgoKDQoF
BgACCgESBLkBBhwKDQoFBgACCgISBLkBHToKDQoFBgACCgMSBLoBDyIKDwoFBgACCgQSBrsB
BL0BBgoTCgkGAAIKBLDKvCISBrsBBL0BBgoNCgUGAAIKBBIEvgEEMgoQCggGAAIKBJsIABIE
vgEEMgpYCgQGAAILEgbCAQLIAQMaSCBMaXN0IHZ1bG5lcmFiaWxpdHkgcmVwb3J0cyBmb3Ig
YWxsIFZNIGluc3RhbmNlcyBpbiB0aGUgc3BlY2lmaWVkIHpvbmUuCgoNCgUGAAILARIEwgEG
HgoNCgUGAAILAhIEwgEfPgoNCgUGAAILAxIEwwEPLwoPCgUGAAILBBIGxAEExgEGChMKCQYA
AgsEsMq8IhIGxAEExgEGCg0KBQYAAgsEEgTHAQQ0ChAKCAYAAgsEmwgAEgTHAQQ0YgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Osconfig::V1::OsconfigZonalService::OsConfigZonalServiceClient ===
package Google::Cloud::Osconfig::V1::OsconfigZonalService::OsConfigZonalServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::V1::OsconfigZonalService::OsConfigZonalServiceClient

Client stub representing the remote C<OsConfigZonalService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub create_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'CreateOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'UpdateOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'GetOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment',
    });
}

sub list_o_s_policy_assignments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListOSPolicyAssignments',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse',
    });
}

sub list_o_s_policy_assignment_revisions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListOSPolicyAssignmentRevisions',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse',
    });
}

sub delete_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'DeleteOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_o_s_policy_assignment_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports::GetOSPolicyAssignmentReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'GetOSPolicyAssignmentReport',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports::OSPolicyAssignmentReport',
    });
}

sub list_o_s_policy_assignment_reports {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListOSPolicyAssignmentReports',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsResponse',
    });
}

sub get_inventory {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::Inventory::GetInventoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'GetInventory',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::Inventory::Inventory',
    });
}

sub list_inventories {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::Inventory::ListInventoriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListInventories',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse',
    });
}

sub get_vulnerability_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::Vulnerability::GetVulnerabilityReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'GetVulnerabilityReport',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::Vulnerability::VulnerabilityReport',
    });
}

sub list_vulnerability_reports {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListVulnerabilityReports',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1::OsconfigZonalService - Compiled Protocol Buffers messages for google/cloud/osconfig/v1/osconfig_zonal_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1/osconfig_zonal_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1::OsconfigZonalService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
