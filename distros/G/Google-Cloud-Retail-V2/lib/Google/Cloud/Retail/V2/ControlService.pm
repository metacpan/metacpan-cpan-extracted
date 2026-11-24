package Google::Cloud::Retail::V2::ControlService;

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
    eval { require Google::Cloud::Retail::V2::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NvbnRyb2xfc2VydmljZS5wcm90bxIWZ29vZ2xl
LmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJGdvb2dsZS9jbG91ZC9yZXRhaWwvdjIvY29udHJv
bC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYv
ZmllbGRfbWFzay5wcm90byK5AQoUQ3JlYXRlQ29udHJvbFJlcXVlc3QSPQoGcGFyZW50GAEg
ASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9nUgZwYXJlbnQSPgoH
Y29udHJvbBgCIAEoCzIfLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJvbEID4EECUgdj
b250cm9sEiIKCmNvbnRyb2xfaWQYAyABKAlCA+BBAlIJY29udHJvbElkIpMBChRVcGRhdGVD
b250cm9sUmVxdWVzdBI+Cgdjb250cm9sGAEgASgLMh8uZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5Db250cm9sQgPgQQJSB2NvbnRyb2wSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIlEKFERlbGV0ZUNvbnRyb2xSZXF1ZXN0
EjkKBG5hbWUYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NvbnRyb2xS
BG5hbWUiTgoRR2V0Q29udHJvbFJlcXVlc3QSOQoEbmFtZRgBIAEoCUIl4EEC+kEfCh1yZXRh
aWwuZ29vZ2xlYXBpcy5jb20vQ29udHJvbFIEbmFtZSK3AQoTTGlzdENvbnRyb2xzUmVxdWVz
dBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFs
b2dSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90
b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRl
ciJ7ChRMaXN0Q29udHJvbHNSZXNwb25zZRI7Cghjb250cm9scxgBIAMoCzIfLmdvb2dsZS5j
bG91ZC5yZXRhaWwudjIuQ29udHJvbFIIY29udHJvbHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuMuQHCg5Db250cm9sU2VydmljZRLEAQoNQ3JlYXRlQ29udHJv
bBIsLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ3JlYXRlQ29udHJvbFJlcXVlc3QaHy5nb29n
bGUuY2xvdWQucmV0YWlsLnYyLkNvbnRyb2wiZILT5JMCQiI3L3YyL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9jb250cm9sczoHY29udHJvbNpBGXBhcmVu
dCxjb250cm9sLGNvbnRyb2xfaWQSnQEKDURlbGV0ZUNvbnRyb2wSLC5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyLkRlbGV0ZUNvbnRyb2xSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5
IkaC0+STAjkqNy92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyov
Y29udHJvbHMvKn3aQQRuYW1lEsYBCg1VcGRhdGVDb250cm9sEiwuZ29vZ2xlLmNsb3VkLnJl
dGFpbC52Mi5VcGRhdGVDb250cm9sUmVxdWVzdBofLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIu
Q29udHJvbCJmgtPkkwJKMj8vdjIve2NvbnRyb2wubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NhdGFsb2dzLyovY29udHJvbHMvKn06B2NvbnRyb2zaQRNjb250cm9sLHVwZGF0ZV9t
YXNrEqABCgpHZXRDb250cm9sEikuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5HZXRDb250cm9s
UmVxdWVzdBofLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJvbCJGgtPkkwI5EjcvdjIv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL2NvbnRyb2xzLyp92kEE
bmFtZRKzAQoMTGlzdENvbnRyb2xzEisuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5MaXN0Q29u
dHJvbHNSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5MaXN0Q29udHJvbHNSZXNw
b25zZSJIgtPkkwI5EjcvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFs
b2dzLyp9L2NvbnRyb2xz2kEGcGFyZW50GknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23SQS5o
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQr4BChpjb20u
Z29vZ2xlLmNsb3VkLnJldGFpbC52MkITQ29udHJvbFNlcnZpY2VQcm90b1ABWjJjbG91ZC5n
b29nbGUuY29tL2dvL3JldGFpbC9hcGl2Mi9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoC
Fkdvb2dsZS5DbG91ZC5SZXRhaWwuVjLKAhZHb29nbGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29v
Z2xlOjpDbG91ZDo6UmV0YWlsOjpWMkreKgoHEgUOALgBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC4KCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgS
AxoAMwoJCgIIJRIDGgAzCggKAQgSAxsASQoJCgIICxIDGwBJCggKAQgSAxwAIgoJCgIIChID
HAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4AMwoJCgIIARIDHgAzCggKAQgSAx8A
JAoJCgIIJBIDHwAkCggKAQgSAyAAMwoJCgIIKRIDIAAzCggKAQgSAyEAMgoJCgIILRIDIQAy
CiwKAgYAEgQkAF4BGiAgU2VydmljZSBmb3IgbW9kaWZ5aW5nIENvbnRyb2wuCgoKCgMGAAES
AyQIFgoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYAAxIEJgInNwoNCgUGAAOaCBIE
JgInNwqWAQoEBgACABIELQIzAxqHASBDcmVhdGVzIGEgQ29udHJvbC4KCiBJZiB0aGUgW0Nv
bnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJvbF0gdG8gY3JlYXRlIGFscmVh
ZHkgZXhpc3RzLAogYW4gQUxSRUFEWV9FWElTVFMgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUG
AAIAARIDLQYTCgwKBQYAAgACEgMtFCgKDAoFBgACAAMSAy0zOgoNCgUGAAIABBIELgQxBgoR
CgkGAAIABLDKvCISBC4EMQYKDAoFBgACAAQSAzIERwoPCggGAAIABJsIABIDMgRHCpABCgQG
AAIBEgQ5Aj4DGoEBIERlbGV0ZXMgYSBDb250cm9sLgoKIElmIHRoZSBbQ29udHJvbF1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5Db250cm9sXSB0byBkZWxldGUgZG9lcyBub3QgZXhpc3Qs
CiBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgEBEgM5BhMKDAoFBgAC
AQISAzkUKAoMCgUGAAIBAxIDOTNICg0KBQYAAgEEEgQ6BDwGChEKCQYAAgEEsMq8IhIEOgQ8
BgoMCgUGAAIBBBIDPQQyCg8KCAYAAgEEmwgAEgM9BDIKjQIKBAYAAgISBEYCTAMa/gEgVXBk
YXRlcyBhIENvbnRyb2wuCgogW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29u
dHJvbF0gY2Fubm90IGJlIHNldCB0byBhIGRpZmZlcmVudAogb25lb2YgZmllbGQsIGlmIHNv
IGFuIElOVkFMSURfQVJHVU1FTlQgaXMgcmV0dXJuZWQuIElmIHRoZQogW0NvbnRyb2xdW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJvbF0gdG8gdXBkYXRlIGRvZXMgbm90IGV4aXN0
LCBhCiBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAICARIDRgYTCgwKBQYA
AgICEgNGFCgKDAoFBgACAgMSA0YzOgoNCgUGAAICBBIERwRKBgoRCgkGAAICBLDKvCISBEcE
SgYKDAoFBgACAgQSA0sEQQoPCggGAAICBJsIABIDSwRBCh8KBAYAAgMSBE8CVAMaESBHZXRz
IGEgQ29udHJvbC4KCgwKBQYAAgMBEgNPBhAKDAoFBgACAwISA08RIgoMCgUGAAIDAxIDTy00
Cg0KBQYAAgMEEgRQBFIGChEKCQYAAgMEsMq8IhIEUARSBgoMCgUGAAIDBBIDUwQyCg8KCAYA
AgMEmwgAEgNTBDIKXgoEBgACBBIEWAJdAxpQIExpc3RzIGFsbCBDb250cm9scyBieSB0aGVp
ciBwYXJlbnQKIFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2ddLgoK
DAoFBgACBAESA1gGEgoMCgUGAAIEAhIDWBMmCgwKBQYAAgQDEgNYMUUKDQoFBgACBAQSBFkE
WwYKEQoJBgACBASwyrwiEgRZBFsGCgwKBQYAAgQEEgNcBDQKDwoIBgACBASbCAASA1wENAov
CgIEABIEYQByARojIFJlcXVlc3QgZm9yIENyZWF0ZUNvbnRyb2wgbWV0aG9kLgoKCgoDBAAB
EgNhCBwKkwEKBAQAAgASBGQCZwQahAEgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBv
ZiBwYXJlbnQgY2F0YWxvZy4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0v
bG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9YAoKDAoFBAAC
AAUSA2QCCAoMCgUEAAIAARIDZAkPCgwKBQQAAgADEgNkEhMKDQoFBAACAAgSBGQUZwMKDwoI
BAACAAicCAASA2UEKgoOCgcEAAIACJ8IEgNmBE8KLwoEBAACARIDagI/GiIgUmVxdWlyZWQu
IFRoZSBDb250cm9sIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNqAgkKDAoFBAACAQESA2oKEQoM
CgUEAAIBAxIDahQVCgwKBQQAAgEIEgNqFj4KDwoIBAACAQicCAASA2oXPQrRAQoEBAACAhID
cQJBGsMBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgQ29udHJvbCwgd2hpY2gg
d2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIENvbnRyb2wncyByZXNv
dXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDQtNjMgY2hhcmFjdGVycywgYW5k
IHZhbGlkIGNoYXJhY3RlcnMKIGFyZSAvW2Etel1bMC05XS1fLy4KCgwKBQQAAgIFEgNxAggK
DAoFBAACAgESA3EJEwoMCgUEAAICAxIDcRYXCgwKBQQAAgIIEgNxGEAKDwoIBAACAgicCAAS
A3EZPwowCgIEARIFdQCBAQEaIyBSZXF1ZXN0IGZvciBVcGRhdGVDb250cm9sIG1ldGhvZC4K
CgoKAwQBARIDdQgcCi8KBAQBAgASA3cCPxoiIFJlcXVpcmVkLiBUaGUgQ29udHJvbCB0byB1
cGRhdGUuCgoMCgUEAQIABhIDdwIJCgwKBQQBAgABEgN3ChEKDAoFBAECAAMSA3cUFQoMCgUE
AQIACBIDdxY+Cg8KCAQBAgAInAgAEgN3Fz0KgAIKBAQBAgESBIABAiwa8QEgSW5kaWNhdGVz
IHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtDb250cm9sXVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyLkNvbnRyb2xdIHRvIHVwZGF0ZS4gVGhlIGZvbGxvd2luZyBhcmUgTk9UCiBz
dXBwb3J0ZWQ6CgogKiBbQ29udHJvbC5uYW1lXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNv
bnRyb2wubmFtZV0KCiBJZiBub3Qgc2V0IG9yIGVtcHR5LCBhbGwgc3VwcG9ydGVkIGZpZWxk
cyBhcmUgdXBkYXRlZC4KCg0KBQQBAgEGEgSAAQIbCg0KBQQBAgEBEgSAARwnCg0KBQQBAgED
EgSAASorCjEKAgQCEgaEAQCLAQEaIyBSZXF1ZXN0IGZvciBEZWxldGVDb250cm9sIG1ldGhv
ZC4KCgsKAwQCARIEhAEIHAqxAQoEBAICABIGhwECigEEGqABIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgQ29udHJvbCB0byBkZWxldGUuIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tj
YXRhbG9nX2lkfS9jb250cm9scy97Y29udHJvbF9pZH1gCgoNCgUEAgIABRIEhwECCAoNCgUE
AgIAARIEhwEJDQoNCgUEAgIAAxIEhwEQEQoPCgUEAgIACBIGhwESigEDChAKCAQCAgAInAgA
EgSIAQQqCg8KBwQCAgAInwgSBIkBBE8KLgoCBAMSBo4BAJUBARogIFJlcXVlc3QgZm9yIEdl
dENvbnRyb2wgbWV0aG9kLgoKCwoDBAMBEgSOAQgZCq4BCgQEAwIAEgaRAQKUAQQanQEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBDb250cm9sIHRvIGdldC4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0v
Y2F0YWxvZ3Mve2NhdGFsb2dfaWR9L2NvbnRyb2xzL3tjb250cm9sX2lkfWAKCg0KBQQDAgAF
EgSRAQIICg0KBQQDAgABEgSRAQkNCg0KBQQDAgADEgSRARARCg8KBQQDAgAIEgaRARKUAQMK
EAoIBAMCAAicCAASBJIBBCoKDwoHBAMCAAifCBIEkwEETwowCgIEBBIGmAEArwEBGiIgUmVx
dWVzdCBmb3IgTGlzdENvbnRyb2xzIG1ldGhvZC4KCgsKAwQEARIEmAEIGwqJAQoEBAQCABIG
mwECngEEGnkgUmVxdWlyZWQuIFRoZSBjYXRhbG9nIHJlc291cmNlIG5hbWUuIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Nh
dGFsb2dzL3tjYXRhbG9nX2lkfWAKCg0KBQQEAgAFEgSbAQIICg0KBQQEAgABEgSbAQkPCg0K
BQQEAgADEgSbARITCg8KBQQEAgAIEgabARSeAQMKEAoIBAQCAAicCAASBJwBBCoKDwoHBAQC
AAifCBIEnQEETwp6CgQEBAIBEgSiAQI/GmwgT3B0aW9uYWwuIE1heGltdW0gbnVtYmVyIG9m
IHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgZGVmYXVsdHMKIHRvIDUwLiBN
YXggYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLgoKDQoFBAQCAQUSBKIBAgcKDQoFBAQCAQESBKIB
CBEKDQoFBAQCAQMSBKIBFBUKDQoFBAQCAQgSBKIBFj4KEAoIBAQCAQicCAASBKIBFz0KhAEK
BAQEAgISBKYBAkEadiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEg
cHJldmlvdXMgYExpc3RDb250cm9sc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2
ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAQCAgUSBKYBAggKDQoFBAQCAgESBKYBCRMK
DQoFBAQCAgMSBKYBFhcKDQoFBAQCAggSBKYBGEAKEAoIBAQCAgicCAASBKYBGT8KuwIKBAQE
AgMSBK4BAj0arAIgT3B0aW9uYWwuIEEgZmlsdGVyIHRvIGFwcGx5IG9uIHRoZSBsaXN0IHJl
c3VsdHMuIFN1cHBvcnRlZCBmZWF0dXJlczoKCiAqIExpc3QgYWxsIHRoZSBwcm9kdWN0cyB1
bmRlciB0aGUgcGFyZW50IGJyYW5jaCBpZgogW2ZpbHRlcl1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5MaXN0Q29udHJvbHNSZXF1ZXN0LmZpbHRlcl0gaXMgdW5zZXQuCiAqIExpc3QgY29u
dHJvbHMgdGhhdCBhcmUgdXNlZCBpbiBhIHNpbmdsZSBTZXJ2aW5nQ29uZmlnOgogICAgICdz
ZXJ2aW5nX2NvbmZpZyA9ICJib29zdGVkX2hvbWVfcGFnZV9jdnIiJwoKDQoFBAQCAwUSBK4B
AggKDQoFBAQCAwESBK4BCQ8KDQoFBAQCAwMSBK4BEhMKDQoFBAQCAwgSBK4BFDwKEAoIBAQC
AwicCAASBK4BFTsKMQoCBAUSBrIBALgBARojIFJlc3BvbnNlIGZvciBMaXN0Q29udHJvbHMg
bWV0aG9kLgoKCwoDBAUBEgSyAQgcCjUKBAQFAgASBLQBAiAaJyBBbGwgdGhlIENvbnRyb2xz
IGZvciBhIGdpdmVuIGNhdGFsb2cuCgoNCgUEBQIABBIEtAECCgoNCgUEBQIABhIEtAELEgoN
CgUEBQIAARIEtAETGwoNCgUEBQIAAxIEtAEeHwpKCgQEBQIBEgS3AQIdGjwgUGFnaW5hdGlv
biB0b2tlbiwgaWYgbm90IHJldHVybmVkIGluZGljYXRlcyB0aGUgbGFzdCBwYWdlLgoKDQoF
BAUCAQUSBLcBAggKDQoFBAUCAQESBLcBCRgKDQoFBAUCAQMSBLcBGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.retail.v2.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.retail.v2.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.retail.v2.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2::ControlService::ControlServiceClient ===
package Google::Cloud::Retail::V2::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::ControlService::ControlServiceClient

Client stub representing the remote C<ControlService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ControlService - Compiled Protocol Buffers messages for google/cloud/retail/v2/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ControlService;

    my $msg = Google::Cloud::Retail::V2::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent catalog. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Control][google.cloud.retail.v2.Control] to update. The following are NOT
supported:

* [Control.name][google.cloud.retail.v2.Control.name]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2::ControlService::ListControlsRequest

Request for ListControls method.

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
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListControls` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter to apply on the list results. Supported features:

* List all the products under the parent branch if
[filter][google.cloud.retail.v2.ListControlsRequest.filter] is unset.
* List controls that are used in a single ServingConfig:
    'serving_config = "boosted_home_page_cvr"'

=back

=head2 Google::Cloud::Retail::V2::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Control::Control>)

All the Controls for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
