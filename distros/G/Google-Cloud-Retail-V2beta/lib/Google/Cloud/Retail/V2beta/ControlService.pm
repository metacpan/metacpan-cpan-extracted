package Google::Cloud::Retail::V2beta::ControlService;

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
    eval { require Google::Cloud::Retail::V2beta::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9jb250cm9sX3NlcnZpY2UucHJvdG8SGmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL3JldGFpbC92
MmJldGEvY29udHJvbC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29n
bGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byK9AQoUQ3JlYXRlQ29udHJvbFJlcXVlc3QS
PQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9n
UgZwYXJlbnQSQgoHY29udHJvbBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkNvbnRyb2xCA+BBAlIHY29udHJvbBIiCgpjb250cm9sX2lkGAMgASgJQgPgQQJSCWNvbnRy
b2xJZCKXAQoUVXBkYXRlQ29udHJvbFJlcXVlc3QSQgoHY29udHJvbBgBIAEoCzIjLmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNvbnRyb2xCA+BBAlIHY29udHJvbBI7Cgt1cGRhdGVf
bWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siUQoU
RGVsZXRlQ29udHJvbFJlcXVlc3QSOQoEbmFtZRgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29v
Z2xlYXBpcy5jb20vQ29udHJvbFIEbmFtZSJOChFHZXRDb250cm9sUmVxdWVzdBI5CgRuYW1l
GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9Db250cm9sUgRuYW1lIrcB
ChNMaXN0Q29udHJvbHNSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwu
Z29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEB
UghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0
ZXIYBCABKAlCA+BBAVIGZmlsdGVyIn8KFExpc3RDb250cm9sc1Jlc3BvbnNlEj8KCGNvbnRy
b2xzGAEgAygLMiMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29udHJvbFIIY29udHJv
bHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMpwICg5Db250cm9s
U2VydmljZRLQAQoNQ3JlYXRlQ29udHJvbBIwLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkNyZWF0ZUNvbnRyb2xSZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29u
dHJvbCJogtPkkwJGIjsvdjJiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
YXRhbG9ncy8qfS9jb250cm9sczoHY29udHJvbNpBGXBhcmVudCxjb250cm9sLGNvbnRyb2xf
aWQSpQEKDURlbGV0ZUNvbnRyb2wSMC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5EZWxl
dGVDb250cm9sUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJKgtPkkwI9KjsvdjJi
ZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9jb250cm9scy8q
fdpBBG5hbWUS0gEKDVVwZGF0ZUNvbnRyb2wSMC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5VcGRhdGVDb250cm9sUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNv
bnRyb2wiaoLT5JMCTjJDL3YyYmV0YS97Y29udHJvbC5uYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovY2F0YWxvZ3MvKi9jb250cm9scy8qfToHY29udHJvbNpBE2NvbnRyb2wsdXBkYXRl
X21hc2sSrAEKCkdldENvbnRyb2wSLS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5HZXRD
b250cm9sUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNvbnRyb2wiSoLT
5JMCPRI7L3YyYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyov
Y29udHJvbHMvKn3aQQRuYW1lEr8BCgxMaXN0Q29udHJvbHMSLy5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YS5MaXN0Q29udHJvbHNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuTGlzdENvbnRyb2xzUmVzcG9uc2UiTILT5JMCPRI7L3YyYmV0YS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vY29udHJvbHPaQQZwYXJlbnQaScpB
FXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm1C0gEKHmNvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YUIT
Q29udHJvbFNlcnZpY2VQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2
MmJldGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhpHb29nbGUuQ2xvdWQuUmV0YWls
LlYyQmV0YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxcVjJiZXRh6gIdR29vZ2xlOjpDbG91ZDo6
UmV0YWlsOjpWMmJldGFK/ioKBxIFDgC4AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgAyCgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMaADcKCQoC
CCUSAxoANwoICgEIEgMbAE0KCQoCCAsSAxsATQoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEI
EgMdADQKCQoCCAgSAx0ANAoICgEIEgMeADcKCQoCCAESAx4ANwoICgEIEgMfACQKCQoCCCQS
Ax8AJAoICgEIEgMgADcKCQoCCCkSAyAANwoICgEIEgMhADYKCQoCCC0SAyEANgosCgIGABIE
JABeARogIFNlcnZpY2UgZm9yIG1vZGlmeWluZyBDb250cm9sLgoKCgoDBgABEgMkCBYKCgoD
BgADEgMlAj0KDAoFBgADmQgSAyUCPQoLCgMGAAMSBCYCJzcKDQoFBgADmggSBCYCJzcKmgEK
BAYAAgASBC0CMwMaiwEgQ3JlYXRlcyBhIENvbnRyb2wuCgogSWYgdGhlIFtDb250cm9sXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db250cm9sXSB0byBjcmVhdGUgYWxyZWFkeQog
ZXhpc3RzLCBhbiBBTFJFQURZX0VYSVNUUyBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgAB
EgMtBhMKDAoFBgACAAISAy0UKAoMCgUGAAIAAxIDLTM6Cg0KBQYAAgAEEgQuBDEGChEKCQYA
AgAEsMq8IhIELgQxBgoMCgUGAAIABBIDMgRHCg8KCAYAAgAEmwgAEgMyBEcKlAEKBAYAAgES
BDkCPgMahQEgRGVsZXRlcyBhIENvbnRyb2wuCgogSWYgdGhlIFtDb250cm9sXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5Db250cm9sXSB0byBkZWxldGUgZG9lcyBub3QKIGV4aXN0
LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgEBEgM5BhMKDAoFBgAC
AQISAzkUKAoMCgUGAAIBAxIDOTNICg0KBQYAAgEEEgQ6BDwGChEKCQYAAgEEsMq8IhIEOgQ8
BgoMCgUGAAIBBBIDPQQyCg8KCAYAAgEEmwgAEgM9BDIKlQIKBAYAAgISBEYCTAMahgIgVXBk
YXRlcyBhIENvbnRyb2wuCgogW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkNvbnRyb2xdIGNhbm5vdCBiZSBzZXQgdG8gYSBkaWZmZXJlbnQKIG9uZW9mIGZpZWxkLCBp
ZiBzbyBhbiBJTlZBTElEX0FSR1VNRU5UIGlzIHJldHVybmVkLiBJZiB0aGUKIFtDb250cm9s
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db250cm9sXSB0byB1cGRhdGUgZG9lcyBu
b3QgZXhpc3QsIGEKIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgIBEgNG
BhMKDAoFBgACAgISA0YUKAoMCgUGAAICAxIDRjM6Cg0KBQYAAgIEEgRHBEoGChEKCQYAAgIE
sMq8IhIERwRKBgoMCgUGAAICBBIDSwRBCg8KCAYAAgIEmwgAEgNLBEEKHwoEBgACAxIETwJU
AxoRIEdldHMgYSBDb250cm9sLgoKDAoFBgACAwESA08GEAoMCgUGAAIDAhIDTxEiCgwKBQYA
AgMDEgNPLTQKDQoFBgACAwQSBFAEUgYKEQoJBgACAwSwyrwiEgRQBFIGCgwKBQYAAgMEEgNT
BDIKDwoIBgACAwSbCAASA1MEMgpiCgQGAAIEEgRYAl0DGlQgTGlzdHMgYWxsIENvbnRyb2xz
IGJ5IHRoZWlyIHBhcmVudAogW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkNhdGFsb2ddLgoKDAoFBgACBAESA1gGEgoMCgUGAAIEAhIDWBMmCgwKBQYAAgQDEgNYMUUK
DQoFBgACBAQSBFkEWwYKEQoJBgACBASwyrwiEgRZBFsGCgwKBQYAAgQEEgNcBDQKDwoIBgAC
BASbCAASA1wENAovCgIEABIEYQByARojIFJlcXVlc3QgZm9yIENyZWF0ZUNvbnRyb2wgbWV0
aG9kLgoKCgoDBAABEgNhCBwKkwEKBAQAAgASBGQCZwQahAEgUmVxdWlyZWQuIEZ1bGwgcmVz
b3VyY2UgbmFtZSBvZiBwYXJlbnQgY2F0YWxvZy4gRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2df
aWR9YAoKDAoFBAACAAUSA2QCCAoMCgUEAAIAARIDZAkPCgwKBQQAAgADEgNkEhMKDQoFBAAC
AAgSBGQUZwMKDwoIBAACAAicCAASA2UEKgoOCgcEAAIACJ8IEgNmBE8KLwoEBAACARIDagI/
GiIgUmVxdWlyZWQuIFRoZSBDb250cm9sIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNqAgkKDAoF
BAACAQESA2oKEQoMCgUEAAIBAxIDahQVCgwKBQQAAgEIEgNqFj4KDwoIBAACAQicCAASA2oX
PQrRAQoEBAACAhIDcQJBGsMBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgQ29u
dHJvbCwgd2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIENv
bnRyb2wncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDQtNjMgY2hh
cmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMKIGFyZSAvW2Etel1bMC05XS1fLy4KCgwK
BQQAAgIFEgNxAggKDAoFBAACAgESA3EJEwoMCgUEAAICAxIDcRYXCgwKBQQAAgIIEgNxGEAK
DwoIBAACAgicCAASA3EZPwowCgIEARIFdQCBAQEaIyBSZXF1ZXN0IGZvciBVcGRhdGVDb250
cm9sIG1ldGhvZC4KCgoKAwQBARIDdQgcCi8KBAQBAgASA3cCPxoiIFJlcXVpcmVkLiBUaGUg
Q29udHJvbCB0byB1cGRhdGUuCgoMCgUEAQIABhIDdwIJCgwKBQQBAgABEgN3ChEKDAoFBAEC
AAMSA3cUFQoMCgUEAQIACBIDdxY+Cg8KCAQBAgAInAgAEgN3Fz0KiAIKBAQBAgESBIABAiwa
+QEgSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtDb250cm9sXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db250cm9sXSB0byB1cGRhdGUuIFRoZSBmb2xs
b3dpbmcgYXJlCiBOT1Qgc3VwcG9ydGVkOgoKICogW0NvbnRyb2wubmFtZV1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmJldGEuQ29udHJvbC5uYW1lXQoKIElmIG5vdCBzZXQgb3IgZW1wdHks
IGFsbCBzdXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAECAQYSBIABAhsKDQoF
BAECAQESBIABHCcKDQoFBAECAQMSBIABKisKMQoCBAISBoQBAIsBARojIFJlcXVlc3QgZm9y
IERlbGV0ZUNvbnRyb2wgbWV0aG9kLgoKCwoDBAIBEgSEAQgcCrEBCgQEAgIAEgaHAQKKAQQa
oAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBDb250cm9sIHRvIGRlbGV0
ZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2Nh
dGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L2NvbnRyb2xzL3tjb250cm9sX2lkfWAK
Cg0KBQQCAgAFEgSHAQIICg0KBQQCAgABEgSHAQkNCg0KBQQCAgADEgSHARARCg8KBQQCAgAI
EgaHARKKAQMKEAoIBAICAAicCAASBIgBBCoKDwoHBAICAAifCBIEiQEETwouCgIEAxIGjgEA
lQEBGiAgUmVxdWVzdCBmb3IgR2V0Q29udHJvbCBtZXRob2QuCgoLCgMEAwESBI4BCBkKrgEK
BAQDAgASBpEBApQBBBqdASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENv
bnRyb2wgdG8gZ2V0LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2Nh
dGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vY29udHJvbHMve2Nv
bnRyb2xfaWR9YAoKDQoFBAMCAAUSBJEBAggKDQoFBAMCAAESBJEBCQ0KDQoFBAMCAAMSBJEB
EBEKDwoFBAMCAAgSBpEBEpQBAwoQCggEAwIACJwIABIEkgEEKgoPCgcEAwIACJ8IEgSTAQRP
CjAKAgQEEgaYAQCvAQEaIiBSZXF1ZXN0IGZvciBMaXN0Q29udHJvbHMgbWV0aG9kLgoKCwoD
BAQBEgSYAQgbCokBCgQEBAIAEgabAQKeAQQaeSBSZXF1aXJlZC4gVGhlIGNhdGFsb2cgcmVz
b3VyY2UgbmFtZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9YAoKDQoFBAQCAAUSBJsB
AggKDQoFBAQCAAESBJsBCQ8KDQoFBAQCAAMSBJsBEhMKDwoFBAQCAAgSBpsBFJ4BAwoQCggE
BAIACJwIABIEnAEEKgoPCgcEBAIACJ8IEgSdAQRPCnoKBAQEAgESBKIBAj8abCBPcHRpb25h
bC4gTWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVk
LCBkZWZhdWx0cwogdG8gNTAuIE1heCBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuCgoNCgUEBAIB
BRIEogECBwoNCgUEBAIBARIEogEIEQoNCgUEBAIBAxIEogEUFQoNCgUEBAIBCBIEogEWPgoQ
CggEBAIBCJwIABIEogEXPQqEAQoEBAQCAhIEpgECQRp2IE9wdGlvbmFsLiBBIHBhZ2UgdG9r
ZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdENvbnRyb2xzYCBjYWxsLgogUHJv
dmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoNCgUEBAICBRIE
pgECCAoNCgUEBAICARIEpgEJEwoNCgUEBAICAxIEpgEWFwoNCgUEBAICCBIEpgEYQAoQCggE
BAICCJwIABIEpgEZPwq/AgoEBAQCAxIErgECPRqwAiBPcHRpb25hbC4gQSBmaWx0ZXIgdG8g
YXBwbHkgb24gdGhlIGxpc3QgcmVzdWx0cy4gU3VwcG9ydGVkIGZlYXR1cmVzOgoKICogTGlz
dCBhbGwgdGhlIHByb2R1Y3RzIHVuZGVyIHRoZSBwYXJlbnQgYnJhbmNoIGlmCiBbZmlsdGVy
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5MaXN0Q29udHJvbHNSZXF1ZXN0LmZpbHRl
cl0gaXMgdW5zZXQuCiAqIExpc3QgY29udHJvbHMgdGhhdCBhcmUgdXNlZCBpbiBhIHNpbmds
ZSBTZXJ2aW5nQ29uZmlnOgogICAgICdzZXJ2aW5nX2NvbmZpZyA9ICJib29zdGVkX2hvbWVf
cGFnZV9jdnIiJwoKDQoFBAQCAwUSBK4BAggKDQoFBAQCAwESBK4BCQ8KDQoFBAQCAwMSBK4B
EhMKDQoFBAQCAwgSBK4BFDwKEAoIBAQCAwicCAASBK4BFTsKMQoCBAUSBrIBALgBARojIFJl
c3BvbnNlIGZvciBMaXN0Q29udHJvbHMgbWV0aG9kLgoKCwoDBAUBEgSyAQgcCjUKBAQFAgAS
BLQBAiAaJyBBbGwgdGhlIENvbnRyb2xzIGZvciBhIGdpdmVuIGNhdGFsb2cuCgoNCgUEBQIA
BBIEtAECCgoNCgUEBQIABhIEtAELEgoNCgUEBQIAARIEtAETGwoNCgUEBQIAAxIEtAEeHwpK
CgQEBQIBEgS3AQIdGjwgUGFnaW5hdGlvbiB0b2tlbiwgaWYgbm90IHJldHVybmVkIGluZGlj
YXRlcyB0aGUgbGFzdCBwYWdlLgoKDQoFBAUCAQUSBLcBAggKDQoFBAUCAQESBLcBCRgKDQoF
BAUCAQMSBLcBGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.retail.v2beta.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.retail.v2beta.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2beta::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.retail.v2beta.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2beta::ControlService::ControlServiceClient ===
package Google::Cloud::Retail::V2beta::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::ControlService::ControlServiceClient

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
        ? Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ControlService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ControlService;

    my $msg = Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent catalog. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2beta::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Control][google.cloud.retail.v2beta.Control] to update. The following are
NOT supported:

* [Control.name][google.cloud.retail.v2beta.Control.name]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2beta::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ControlService::ListControlsRequest

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
[filter][google.cloud.retail.v2beta.ListControlsRequest.filter] is unset.
* List controls that are used in a single ServingConfig:
    'serving_config = "boosted_home_page_cvr"'

=back

=head2 Google::Cloud::Retail::V2beta::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Control::Control>)

All the Controls for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
