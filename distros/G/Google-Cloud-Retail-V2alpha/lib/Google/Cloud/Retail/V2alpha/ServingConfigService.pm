package Google::Cloud::Retail::V2alpha::ServingConfigService;

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
    eval { require Google::Cloud::Retail::V2alpha::ServingConfig };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvc2VydmluZ19jb25maWdfc2VydmljZS5w
cm90bxIbZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29vZ2xlL2Nsb3Vk
L3JldGFpbC92MmFscGhhL3NlcnZpbmdfY29uZmlnLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIuQBChpDcmVh
dGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWls
Lmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJWCg5zZXJ2aW5nX2NvbmZpZxgCIAEo
CzIqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnQgPgQQJSDXNl
cnZpbmdDb25maWcSLwoRc2VydmluZ19jb25maWdfaWQYAyABKAlCA+BBAlIPc2VydmluZ0Nv
bmZpZ0lkIrEBChpVcGRhdGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBJWCg5zZXJ2aW5nX2NvbmZp
ZxgBIAEoCzIqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnQgPg
QQJSDXNlcnZpbmdDb25maWcSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIl0KGkRlbGV0ZVNlcnZpbmdDb25maWdSZXF1ZXN0
Ej8KBG5hbWUYASABKAlCK+BBAvpBJQojcmV0YWlsLmdvb2dsZWFwaXMuY29tL1NlcnZpbmdD
b25maWdSBG5hbWUiWgoXR2V0U2VydmluZ0NvbmZpZ1JlcXVlc3QSPwoEbmFtZRgBIAEoCUIr
4EEC+kElCiNyZXRhaWwuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1IEbmFtZSKgAQoZ
TGlzdFNlcnZpbmdDb25maWdzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0
YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVC
A+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4imQEK
Gkxpc3RTZXJ2aW5nQ29uZmlnc1Jlc3BvbnNlElMKD3NlcnZpbmdfY29uZmlncxgBIAMoCzIq
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnUg5zZXJ2aW5nQ29u
ZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iiwEKEUFkZENv
bnRyb2xSZXF1ZXN0ElIKDnNlcnZpbmdfY29uZmlnGAEgASgJQivgQQL6QSUKI3JldGFpbC5n
b29nbGVhcGlzLmNvbS9TZXJ2aW5nQ29uZmlnUg1zZXJ2aW5nQ29uZmlnEiIKCmNvbnRyb2xf
aWQYAiABKAlCA+BBAlIJY29udHJvbElkIo4BChRSZW1vdmVDb250cm9sUmVxdWVzdBJSCg5z
ZXJ2aW5nX2NvbmZpZxgBIAEoCUIr4EEC+kElCiNyZXRhaWwuZ29vZ2xlYXBpcy5jb20vU2Vy
dmluZ0NvbmZpZ1INc2VydmluZ0NvbmZpZxIiCgpjb250cm9sX2lkGAIgASgJQgPgQQJSCWNv
bnRyb2xJZDKXDQoUU2VydmluZ0NvbmZpZ1NlcnZpY2USgQIKE0NyZWF0ZVNlcnZpbmdDb25m
aWcSNy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ3JlYXRlU2VydmluZ0NvbmZpZ1Jl
cXVlc3QaKi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2VydmluZ0NvbmZpZyKEAYLT
5JMCVCJCL3YyYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dz
Lyp9L3NlcnZpbmdDb25maWdzOg5zZXJ2aW5nX2NvbmZpZ9pBJ3BhcmVudCxzZXJ2aW5nX2Nv
bmZpZyxzZXJ2aW5nX2NvbmZpZ19pZBK5AQoTRGVsZXRlU2VydmluZ0NvbmZpZxI3Lmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5EZWxldGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBoWLmdv
b2dsZS5wcm90b2J1Zi5FbXB0eSJRgtPkkwJEKkIvdjJhbHBoYS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn3aQQRuYW1lEoMCChNV
cGRhdGVTZXJ2aW5nQ29uZmlnEjcuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVwZGF0
ZVNlcnZpbmdDb25maWdSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNl
cnZpbmdDb25maWcihgGC0+STAmMyUS92MmFscGhhL3tzZXJ2aW5nX2NvbmZpZy5uYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9zZXJ2aW5nQ29uZmlncy8qfToOc2Vy
dmluZ19jb25maWfaQRpzZXJ2aW5nX2NvbmZpZyx1cGRhdGVfbWFzaxLHAQoQR2V0U2Vydmlu
Z0NvbmZpZxI0Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5HZXRTZXJ2aW5nQ29uZmln
UmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnIlGC
0+STAkQSQi92MmFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3Mv
Ki9zZXJ2aW5nQ29uZmlncy8qfdpBBG5hbWUS2gEKEkxpc3RTZXJ2aW5nQ29uZmlncxI2Lmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5MaXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0Gjcu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxpc3RTZXJ2aW5nQ29uZmlnc1Jlc3BvbnNl
IlOC0+STAkQSQi92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRh
bG9ncy8qfS9zZXJ2aW5nQ29uZmlnc9pBBnBhcmVudBLdAQoKQWRkQ29udHJvbBIuLmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5BZGRDb250cm9sUmVxdWVzdBoqLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnInOC0+STAlwiVy92MmFscGhhL3tzZXJ2
aW5nX2NvbmZpZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0Nv
bmZpZ3MvKn06YWRkQ29udHJvbDoBKtpBDnNlcnZpbmdfY29uZmlnEuYBCg1SZW1vdmVDb250
cm9sEjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlJlbW92ZUNvbnRyb2xSZXF1ZXN0
GiouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWcidoLT5JMCXyJa
L3YyYWxwaGEve3NlcnZpbmdfY29uZmlnPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxv
Z3MvKi9zZXJ2aW5nQ29uZmlncy8qfTpyZW1vdmVDb250cm9sOgEq2kEOc2VydmluZ19jb25m
aWcaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C3QEKH2NvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGFCGVNlcnZpbmdDb25maWdTZXJ2aWNlUHJvdG9QAVo3Y2xvdWQuZ29vZ2xlLmNvbS9n
by9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCG0dvb2ds
ZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxSZXRhaWxcVjJhbHBoYeoC
Hkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUr8NwoHEgUOAPABAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADoKCQoCAwUSAxcAJQoJCgIDBhID
GAAqCggKAQgSAxoAOAoJCgIIJRIDGgA4CggKAQgSAxsATgoJCgIICxIDGwBOCggKAQgSAxwA
IgoJCgIIChIDHAAiCggKAQgSAx0AOgoJCgIICBIDHQA6CggKAQgSAx4AOAoJCgIIARIDHgA4
CggKAQgSAx8AJAoJCgIIJBIDHwAkCggKAQgSAyAAOAoJCgIIKRIDIAA4CggKAQgSAyEANwoJ
CgIILRIDIQA3CjIKAgYAEgQkAHkBGiYgU2VydmljZSBmb3IgbW9kaWZ5aW5nIFNlcnZpbmdD
b25maWcuCgoKCgMGAAESAyQIHAoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYAAxIE
JgInNwoNCgUGAAOaCBIEJgInNwrvAQoEBgACABIELwI2AxrgASBDcmVhdGVzIGEgU2Vydmlu
Z0NvbmZpZy4KCiBBIG1heGltdW0gb2YgMTAwCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWddcyBhcmUgYWxsb3dlZCBpbgogYSBb
Q2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNhdGFsb2ddLCBvdGhlcndp
c2UgYQogRkFJTEVEX1BSRUNPTkRJVElPTiBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgAB
EgMvBhkKDAoFBgACAAISAy8aNAoMCgUGAAIAAxIDLz9MCg0KBQYAAgAEEgQwBDMGChEKCQYA
AgAEsMq8IhIEMAQzBgoNCgUGAAIABBIENAQ1MgoQCggGAAIABJsIABIENAQ1MgpoCgQGAAIB
EgQ7AkEDGlogRGVsZXRlcyBhIFNlcnZpbmdDb25maWcuCgogUmV0dXJucyBhIE5vdEZvdW5k
IGVycm9yIGlmIHRoZSBTZXJ2aW5nQ29uZmlnIGRvZXMgbm90IGV4aXN0LgoKDAoFBgACAQES
AzsGGQoMCgUGAAIBAhIDOxo0CgwKBQYAAgEDEgM8DyQKDQoFBgACAQQSBD0EPwYKEQoJBgAC
AQSwyrwiEgQ9BD8GCgwKBQYAAgEEEgNABDIKDwoIBgACAQSbCAASA0AEMgooCgQGAAICEgRE
AkoDGhogVXBkYXRlcyBhIFNlcnZpbmdDb25maWcuCgoMCgUGAAICARIDRAYZCgwKBQYAAgIC
EgNEGjQKDAoFBgACAgMSA0Q/TAoNCgUGAAICBBIERQRIBgoRCgkGAAICBLDKvCISBEUESAYK
DAoFBgACAgQSA0kESAoPCggGAAICBJsIABIDSQRICmUKBAYAAgMSBE8CVAMaVyBHZXRzIGEg
U2VydmluZ0NvbmZpZy4KCiBSZXR1cm5zIGEgTm90Rm91bmQgZXJyb3IgaWYgdGhlIFNlcnZp
bmdDb25maWcgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAIDARIDTwYWCgwKBQYAAgMCEgNPFy4K
DAoFBgACAwMSA085RgoNCgUGAAIDBBIEUARSBgoRCgkGAAIDBLDKvCISBFAEUgYKDAoFBgAC
AwQSA1MEMgoPCggGAAIDBJsIABIDUwQyCkAKBAYAAgQSBFcCXQMaMiBMaXN0cyBhbGwgU2Vy
dmluZ0NvbmZpZ3MgbGlua2VkIHRvIHRoaXMgY2F0YWxvZy4KCgwKBQYAAgQBEgNXBhgKDAoF
BgACBAISA1cZMgoMCgUGAAIEAxIDWA8pCg0KBQYAAgQEEgRZBFsGChEKCQYAAgQEsMq8IhIE
WQRbBgoMCgUGAAIEBBIDXAQ0Cg8KCAYAAgQEmwgAEgNcBDQKxwMKBAYAAgUSBGYCbAMauAMg
RW5hYmxlcyBhIENvbnRyb2wgb24gdGhlIHNwZWNpZmllZCBTZXJ2aW5nQ29uZmlnLgogVGhl
IGNvbnRyb2wgaXMgYWRkZWQgaW4gdGhlIGxhc3QgcG9zaXRpb24gb2YgdGhlIGxpc3Qgb2Yg
Y29udHJvbHMKIGl0IGJlbG9uZ3MgdG8gKGUuZy4gaWYgaXQncyBhIGZhY2V0IHNwZWMgY29u
dHJvbCBpdCB3aWxsIGJlIGFwcGxpZWQKIGluIHRoZSBsYXN0IHBvc2l0aW9uIG9mIHNlcnZp
bmdDb25maWcuZmFjZXRTcGVjSWRzKQogUmV0dXJucyBhIEFMUkVBRFlfRVhJU1RTIGVycm9y
IGlmIHRoZSBjb250cm9sIGhhcyBhbHJlYWR5IGJlZW4gYXBwbGllZC4KIFJldHVybnMgYSBG
QUlMRURfUFJFQ09ORElUSU9OIGVycm9yIGlmIHRoZSBhZGRpdGlvbiBjb3VsZCBleGNlZWQg
bWF4aW11bQogbnVtYmVyIG9mIGNvbnRyb2wgYWxsb3dlZCBmb3IgdGhhdCB0eXBlIG9mIGNv
bnRyb2wuCgoMCgUGAAIFARIDZgYQCgwKBQYAAgUCEgNmESIKDAoFBgACBQMSA2YtOgoNCgUG
AAIFBBIEZwRqBgoRCgkGAAIFBLDKvCISBGcEagYKDAoFBgACBQQSA2sEPAoPCggGAAIFBJsI
ABIDawQ8CsQBCgQGAAIGEgRyAngDGrUBIERpc2FibGVzIGEgQ29udHJvbCBvbiB0aGUgc3Bl
Y2lmaWVkIFNlcnZpbmdDb25maWcuCiBUaGUgY29udHJvbCBpcyByZW1vdmVkIGZyb20gdGhl
IFNlcnZpbmdDb25maWcuCiBSZXR1cm5zIGEgTk9UX0ZPVU5EIGVycm9yIGlmIHRoZSBDb250
cm9sIGlzIG5vdCBlbmFibGVkIGZvciB0aGUKIFNlcnZpbmdDb25maWcuCgoMCgUGAAIGARID
cgYTCgwKBQYAAgYCEgNyFCgKDAoFBgACBgMSA3IzQAoNCgUGAAIGBBIEcwR2BgoRCgkGAAIG
BLDKvCISBHMEdgYKDAoFBgACBgQSA3cEPAoPCggGAAIGBJsIABIDdwQ8CjYKAgQAEgV8AI0B
ARopIFJlcXVlc3QgZm9yIENyZWF0ZVNlcnZpbmdDb25maWcgbWV0aG9kLgoKCgoDBAABEgN8
CCIKiwEKBAQAAgASBX8CggEEGnwgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBw
YXJlbnQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfWAKCgwKBQQAAgAFEgN/AggKDAoF
BAACAAESA38JDwoMCgUEAAIAAxIDfxITCg4KBQQAAgAIEgV/FIIBAwoQCggEAAIACJwIABIE
gAEEKgoPCgcEAAIACJ8IEgSBAQRPCjYKBAQAAgESBIUBAkwaKCBSZXF1aXJlZC4gVGhlIFNl
cnZpbmdDb25maWcgdG8gY3JlYXRlLgoKDQoFBAACAQYSBIUBAg8KDQoFBAACAQESBIUBEB4K
DQoFBAACAQMSBIUBISIKDQoFBAACAQgSBIUBI0sKEAoIBAACAQicCAASBIUBJEoK3gEKBAQA
AgISBIwBAkgazwEgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2UgZm9yIHRoZSBTZXJ2aW5nQ29u
ZmlnLCB3aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgU2Vy
dmluZ0NvbmZpZydzIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBzaG91bGQgYmUgNC02
MyBjaGFyYWN0ZXJzLCBhbmQgdmFsaWQgY2hhcmFjdGVycwogYXJlIC9bYS16XVswLTldLV8v
LgoKDQoFBAACAgUSBIwBAggKDQoFBAACAgESBIwBCRoKDQoFBAACAgMSBIwBHR4KDQoFBAAC
AggSBIwBH0cKEAoIBAACAgicCAASBIwBIEYKNwoCBAESBpABAJwBARopIFJlcXVlc3QgZm9y
IFVwZGF0ZVNlcnZpbmdDb25maWcgbWV0aG9kLgoKCwoDBAEBEgSQAQgiCjYKBAQBAgASBJIB
AkwaKCBSZXF1aXJlZC4gVGhlIFNlcnZpbmdDb25maWcgdG8gdXBkYXRlLgoKDQoFBAECAAYS
BJIBAg8KDQoFBAECAAESBJIBEB4KDQoFBAECAAMSBJIBISIKDQoFBAECAAgSBJIBI0sKEAoI
BAECAAicCAASBJIBJEoKmQIKBAQBAgESBJsBAiwaigIgSW5kaWNhdGVzIHdoaWNoIGZpZWxk
cyBpbiB0aGUgcHJvdmlkZWQKIFtTZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuU2VydmluZ0NvbmZpZ10gdG8gdXBkYXRlLiBUaGUKIGZvbGxvd2luZyBhcmUg
Tk9UIHN1cHBvcnRlZDoKCiAqIFtTZXJ2aW5nQ29uZmlnLm5hbWVdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnLm5hbWVdCgogSWYgbm90IHNldCwgYWxsIHN1
cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUEAQIBBhIEmwECGwoNCgUEAQIBARIE
mwEcJwoNCgUEAQIBAxIEmwEqKwo3CgIEAhIGnwEAqAEBGikgUmVxdWVzdCBmb3IgRGVsZXRl
U2VydmluZ0NvbmZpZyBtZXRob2QuCgoLCgMEAgESBJ8BCCIKxAEKBAQCAgASBqIBAqcBBBqz
ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNlcnZpbmdDb25maWcgdG8g
ZGVsZXRlLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMv
e2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vc2VydmluZ0NvbmZpZ3Mve3Nl
cnZpbmdfY29uZmlnX2lkfWAKCg0KBQQCAgAFEgSiAQIICg0KBQQCAgABEgSiAQkNCg0KBQQC
AgADEgSiARARCg8KBQQCAgAIEgaiARKnAQMKEAoIBAICAAicCAASBKMBBCoKEQoHBAICAAif
CBIGpAEEpgEFCjQKAgQDEgarAQC0AQEaJiBSZXF1ZXN0IGZvciBHZXRTZXJ2aW5nQ29uZmln
IG1ldGhvZC4KCgsKAwQDARIEqwEIHwrBAQoEBAMCABIGrgECswEEGrABIFJlcXVpcmVkLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2VydmluZ0NvbmZpZyB0byBnZXQuIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Nh
dGFsb2dzL3tjYXRhbG9nX2lkfS9zZXJ2aW5nQ29uZmlncy97c2VydmluZ19jb25maWdfaWR9
YAoKDQoFBAMCAAUSBK4BAggKDQoFBAMCAAESBK4BCQ0KDQoFBAMCAAMSBK4BEBEKDwoFBAMC
AAgSBq4BErMBAwoQCggEAwIACJwIABIErwEEKgoRCgcEAwIACJ8IEgawAQSyAQUKNgoCBAQS
BrcBAMcBARooIFJlcXVlc3QgZm9yIExpc3RTZXJ2aW5nQ29uZmlncyBtZXRob2QuCgoLCgME
BAESBLcBCCEKiQEKBAQEAgASBroBAr0BBBp5IFJlcXVpcmVkLiBUaGUgY2F0YWxvZyByZXNv
dXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlv
bnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH1gCgoNCgUEBAIABRIEugEC
CAoNCgUEBAIAARIEugEJDwoNCgUEBAIAAxIEugESEwoPCgUEBAIACBIGugEUvQEDChAKCAQE
AgAInAgAEgS7AQQqCg8KBwQEAgAInwgSBLwBBE8KrQEKBAQEAgESBMIBAj8angEgT3B0aW9u
YWwuIE1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmll
ZCwgZGVmYXVsdHMKIHRvIDEwMC4gSWYgYSB2YWx1ZSBncmVhdGVyIHRoYW4gMTAwIGlzIHBy
b3ZpZGVkLCBhdCBtb3N0IDEwMCByZXN1bHRzIGFyZQogcmV0dXJuZWQuCgoNCgUEBAIBBRIE
wgECBwoNCgUEBAIBARIEwgEIEQoNCgUEBAIBAxIEwgEUFQoNCgUEBAIBCBIEwgEWPgoQCggE
BAIBCJwIABIEwgEXPQqKAQoEBAQCAhIExgECQRp8IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4s
IHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdFNlcnZpbmdDb25maWdzYCBjYWxsLgog
UHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoNCgUEBAIC
BRIExgECCAoNCgUEBAICARIExgEJEwoNCgUEBAICAxIExgEWFwoNCgUEBAICCBIExgEYQAoQ
CggEBAICCJwIABIExgEZPwo3CgIEBRIGygEA0AEBGikgUmVzcG9uc2UgZm9yIExpc3RTZXJ2
aW5nQ29uZmlncyBtZXRob2QuCgoLCgMEBQESBMoBCCIKOwoEBAUCABIEzAECLRotIEFsbCB0
aGUgU2VydmluZ0NvbmZpZ3MgZm9yIGEgZ2l2ZW4gY2F0YWxvZy4KCg0KBQQFAgAEEgTMAQIK
Cg0KBQQFAgAGEgTMAQsYCg0KBQQFAgABEgTMARkoCg0KBQQFAgADEgTMASssCkoKBAQFAgES
BM8BAh0aPCBQYWdpbmF0aW9uIHRva2VuLCBpZiBub3QgcmV0dXJuZWQgaW5kaWNhdGVzIHRo
ZSBsYXN0IHBhZ2UuCgoNCgUEBQIBBRIEzwECCAoNCgUEBQIBARIEzwEJGAoNCgUEBQIBAxIE
zwEbHAouCgIEBhIG0wEA4AEBGiAgUmVxdWVzdCBmb3IgQWRkQ29udHJvbCBtZXRob2QuCgoL
CgMEBgESBNMBCBkKuwEKBAQGAgASBtYBAtsBBBqqASBSZXF1aXJlZC4gVGhlIHNvdXJjZSBT
ZXJ2aW5nQ29uZmlnIHJlc291cmNlIG5hbWUgLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19p
ZH0vc2VydmluZ0NvbmZpZ3Mve3NlcnZpbmdfY29uZmlnX2lkfWAKCg0KBQQGAgAFEgTWAQII
Cg0KBQQGAgABEgTWAQkXCg0KBQQGAgADEgTWARobCg8KBQQGAgAIEgbWARzbAQMKEAoIBAYC
AAicCAASBNcBBCoKEQoHBAYCAAifCBIG2AEE2gEFCqcBCgQEBgIBEgTfAQJBGpgBIFJlcXVp
cmVkLiBUaGUgaWQgb2YgdGhlIGNvbnRyb2wgdG8gYXBwbHkuIEFzc3VtZWQgdG8gYmUgaW4g
dGhlIHNhbWUgY2F0YWxvZwogYXMgdGhlIHNlcnZpbmcgY29uZmlnIC0gaWYgaWQgaXMgbm90
IGZvdW5kIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAYCAQUSBN8BAggK
DQoFBAYCAQESBN8BCRMKDQoFBAYCAQMSBN8BFhcKDQoFBAYCAQgSBN8BGEAKEAoIBAYCAQic
CAASBN8BGT8KMQoCBAcSBuMBAPABARojIFJlcXVlc3QgZm9yIFJlbW92ZUNvbnRyb2wgbWV0
aG9kLgoKCwoDBAcBEgTjAQgcCrsBCgQEBwIAEgbmAQLrAQQaqgEgUmVxdWlyZWQuIFRoZSBz
b3VyY2UgU2VydmluZ0NvbmZpZyByZXNvdXJjZSBuYW1lIC4gRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2Nh
dGFsb2dfaWR9L3NlcnZpbmdDb25maWdzL3tzZXJ2aW5nX2NvbmZpZ19pZH1gCgoNCgUEBwIA
BRIE5gECCAoNCgUEBwIAARIE5gEJFwoNCgUEBwIAAxIE5gEaGwoPCgUEBwIACBIG5gEc6wED
ChAKCAQHAgAInAgAEgTnAQQqChEKBwQHAgAInwgSBugBBOoBBQpzCgQEBwIBEgTvAQJBGmUg
UmVxdWlyZWQuIFRoZSBpZCBvZiB0aGUgY29udHJvbCB0byBhcHBseS4gQXNzdW1lZCB0byBi
ZSBpbiB0aGUgc2FtZSBjYXRhbG9nCiBhcyB0aGUgc2VydmluZyBjb25maWcuCgoNCgUEBwIB
BRIE7wECCAoNCgUEBwIBARIE7wEJEwoNCgUEBwIBAxIE7wEWFwoNCgUEBwIBCBIE7wEYQAoQ
CggEBwIBCJwIABIE7wEZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest ===
    # Fields for CreateServingConfigRequest
    # Field: parent Type: 9 ()
    # Field: serving_config Type: 11 (.google.cloud.retail.v2alpha.ServingConfig)
    # Field: serving_config_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.retail.v2alpha.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest ===
    # Fields for DeleteServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.retail.v2alpha.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest ===
    # Fields for AddControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest ===
    # Fields for RemoveControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2alpha::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Retail::V2alpha::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::ServingConfigService::ServingConfigServiceClient

Client stub representing the remote C<ServingConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig',
    });
}

sub delete_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'DeleteServingConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse',
    });
}

sub add_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'AddControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig',
    });
}

sub remove_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ServingConfigService',
        method         => 'RemoveControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ServingConfigService;

    my $msg = Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest->new({
        parent => $parent,
        serving_config => $serving_config,
        serving_config_id => $serving_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest

Request for CreateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig>)

Required. The ServingConfig to create.

=item * C<< $msg->serving_config_id() >> / C<< $msg->serving_config_id($value) >>

Type: C<String>

Required. The ID to use for the ServingConfig, which will become the final
component of the ServingConfig's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.retail.v2alpha.ServingConfig] to update. The
following are NOT supported:

* [ServingConfig.name][google.cloud.retail.v2alpha.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest

Request for DeleteServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest

Request for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 100. If a value greater than 100 is provided, at most 100 results are
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListServingConfigs` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig>)

All the ServingConfigs for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest

Request for AddControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config - if id is not found a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest

Request for RemoveControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
