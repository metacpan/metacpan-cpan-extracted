package Google::Cloud::Apiregistry::V1beta::Service;

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
    eval { require Google::Cloud::Apiregistry::V1beta::Resources };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjFiZXRhL3NlcnZpY2UucHJvdG8SH2dvb2ds
ZS5jbG91ZC5hcGlyZWdpc3RyeS52MWJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi9nb29nbGUvY2xvdWQvYXBpcmVn
aXN0cnkvdjFiZXRhL3Jlc291cmNlcy5wcm90byJcChNHZXRNY3BTZXJ2ZXJSZXF1ZXN0EkUK
BG5hbWUYASABKAlCMeBBAvpBKwopY2xvdWRhcGlyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9N
Y3BTZXJ2ZXJSBG5hbWUi3QEKFUxpc3RNY3BTZXJ2ZXJzUmVxdWVzdBJBCgZwYXJlbnQYASAB
KAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQS
IAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlC
A+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJf
YnkYBSABKAlCA+BBAVIHb3JkZXJCeSKvAQoWTGlzdE1jcFNlcnZlcnNSZXNwb25zZRJLCgtt
Y3Bfc2VydmVycxgBIAMoCzIqLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MWJldGEuTWNw
U2VydmVyUgptY3BTZXJ2ZXJzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiWAoRR2V0TWNwVG9vbFJl
cXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidjbG91ZGFwaXJlZ2lzdHJ5Lmdvb2dsZWFw
aXMuY29tL01jcFRvb2xSBG5hbWUi4QEKE0xpc3RNY3BUb29sc1JlcXVlc3QSRwoGcGFyZW50
GAEgASgJQi/gQQL6QSkSJ2Nsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTWNwVG9v
bFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVy
Eh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkipwEKFExpc3RNY3BUb29sc1Jlc3Bv
bnNlEkUKCW1jcF90b29scxgBIAMoCzIoLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MWJl
dGEuTWNwVG9vbFIIbWNwVG9vbHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZTLvBgoQQ2xvdWRBcGlS
ZWdpc3RyeRKzAQoMR2V0TWNwU2VydmVyEjQuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYx
YmV0YS5HZXRNY3BTZXJ2ZXJSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYx
YmV0YS5NY3BTZXJ2ZXIiQYLT5JMCNBIyL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL21jcFNlcnZlcnMvKn3aQQRuYW1lEsYBCg5MaXN0TWNwU2VydmVycxI2Lmdvb2ds
ZS5jbG91ZC5hcGlyZWdpc3RyeS52MWJldGEuTGlzdE1jcFNlcnZlcnNSZXF1ZXN0GjcuZ29v
Z2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YS5MaXN0TWNwU2VydmVyc1Jlc3BvbnNlIkOC
0+STAjQSMi92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9tY3BTZXJ2
ZXJz2kEGcGFyZW50ErgBCgpHZXRNY3BUb29sEjIuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5
LnYxYmV0YS5HZXRNY3BUb29sUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52
MWJldGEuTWNwVG9vbCJMgtPkkwI/Ej0vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovbWNwU2VydmVycy8qL21jcFRvb2xzLyp92kEEbmFtZRLLAQoMTGlzdE1jcFRvb2xz
EjQuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YS5MaXN0TWNwVG9vbHNSZXF1ZXN0
GjUuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YS5MaXN0TWNwVG9vbHNSZXNwb25z
ZSJOgtPkkwI/Ej0vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9tY3BT
ZXJ2ZXJzLyp9L21jcFRvb2xz2kEGcGFyZW50GlPKQR9jbG91ZGFwaXJlZ2lzdHJ5Lmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybULdAgojY29tLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MWJldGFCDFNlcnZpY2VQ
cm90b1ABWkVjbG91ZC5nb29nbGUuY29tL2dvL2FwaXJlZ2lzdHJ5L2FwaXYxYmV0YS9hcGly
ZWdpc3RyeXBiO2FwaXJlZ2lzdHJ5cGKqAh9Hb29nbGUuQ2xvdWQuQXBpUmVnaXN0cnkuVjFC
ZXRhygIfR29vZ2xlXENsb3VkXEFwaVJlZ2lzdHJ5XFYxYmV0YeoCIkdvb2dsZTo6Q2xvdWQ6
OkFwaVJlZ2lzdHJ5OjpWMWJldGHqQXUKLGNsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBpcy5j
b20vQXBpTmFtZXNwYWNlEkVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYXBpTmFtZXNwYWNlcy97YXBpX25hbWVzcGFjZX1K2CMKBxIFDgCoAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA5CggKAQgSAxgAPAoJCgIIJRID
GAA8CggKAQgSAxkAXAoJCgIICxIDGQBcCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
LQoJCgIICBIDGwAtCggKAQgSAxwAPAoJCgIIARIDHAA8CggKAQgSAx0APAoJCgIIKRIDHQA8
CggKAQgSAx4AOwoJCgIILRIDHgA7CgkKAQgSBB8AIgIKDAoECJ0IABIEHwAiAgpgCgIGABIE
JgBKARpUIFRoZSBDbG91ZCBBUEkgUmVnaXN0cnkgc2VydmljZSBwcm92aWRlcyBhIGNlbnRy
YWwgcmVnaXN0cnkgZm9yIG1hbmFnaW5nIEFQSQogRGF0YS4KCgoKAwYAARIDJggYCgoKAwYA
AxIDJwJHCgwKBQYAA5kIEgMnAkcKCwoDBgADEgQoAik3Cg0KBQYAA5oIEgQoAik3CigKBAYA
AgASBCwCMQMaGiBHZXRzIGEgc2luZ2xlIE1jcFNlcnZlci4KCgwKBQYAAgABEgMsBhIKDAoF
BgACAAISAywTJgoMCgUGAAIAAxIDLDE6Cg0KBQYAAgAEEgQtBC8GChEKCQYAAgAEsMq8IhIE
LQQvBgoMCgUGAAIABBIDMAQyCg8KCAYAAgAEmwgAEgMwBDIKNAoEBgACARIENAI5AxomIExp
c3RzIE1jcFNlcnZlcnMgaW4gYSBnaXZlbiBQcm9qZWN0LgoKDAoFBgACAQESAzQGFAoMCgUG
AAIBAhIDNBUqCgwKBQYAAgEDEgM0NUsKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwiEgQ1
BDcGCgwKBQYAAgEEEgM4BDQKDwoIBgACAQSbCAASAzgENAomCgQGAAICEgQ8AkEDGhggR2V0
cyBhIHNpbmdsZSBNY3BUb29sLgoKDAoFBgACAgESAzwGEAoMCgUGAAICAhIDPBEiCgwKBQYA
AgIDEgM8LTQKDQoFBgACAgQSBD0EPwYKEQoJBgACAgSwyrwiEgQ9BD8GCgwKBQYAAgIEEgNA
BDIKDwoIBgACAgSbCAASA0AEMgo0CgQGAAIDEgREAkkDGiYgTGlzdHMgTWNwVG9vbHMgaW4g
YSBnaXZlbiBNY3BTZXJ2ZXIuCgoMCgUGAAIDARIDRAYSCgwKBQYAAgMCEgNEEyYKDAoFBgAC
AwMSA0QxRQoNCgUGAAIDBBIERQRHBgoRCgkGAAIDBLDKvCISBEUERwYKDAoFBgACAwQSA0gE
NAoPCggGAAIDBJsIABIDSAQ0Ci0KAgQAEgRNAFUBGiEgTWVzc2FnZSBmb3IgZ2V0dGluZyBh
IE1jcFNlcnZlcgoKCgoDBAABEgNNCBsKLgoEBAACABIETwJUBBogIFJlcXVpcmVkLiBOYW1l
IG9mIHRoZSByZXNvdXJjZQoKDAoFBAACAAUSA08CCAoMCgUEAAIAARIDTwkNCgwKBQQAAgAD
EgNPEBEKDQoFBAACAAgSBE8SVAMKDwoIBAACAAicCAASA1AEKgoPCgcEAAIACJ8IEgRRBFMF
CjcKAgQBEgRYAG0BGisgTWVzc2FnZSBmb3IgcmVxdWVzdGluZyBsaXN0IG9mIE1jcFNlcnZl
cnMKCgoKAwQBARIDWAgdCkAKBAQBAgASBFoCXwQaMiBSZXF1aXJlZC4gUGFyZW50IHZhbHVl
IGZvciBMaXN0TWNwU2VydmVyc1JlcXVlc3QKCgwKBQQBAgAFEgNaAggKDAoFBAECAAESA1oJ
DwoMCgUEAQIAAxIDWhITCg0KBQQBAgAIEgRaFF8DCg8KCAQBAgAInAgAEgNbBCoKDwoHBAEC
AAifCBIEXAReBQqWAQoEBAECARIDYwI/GogBIE9wdGlvbmFsLiBSZXF1ZXN0ZWQgcGFnZSBz
aXplLiBTZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIElm
IHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQu
CgoMCgUEAQIBBRIDYwIHCgwKBQQBAgEBEgNjCBEKDAoFBAECAQMSA2MUFQoMCgUEAQIBCBID
YxY+Cg8KCAQBAgEInAgAEgNjFz0KWAoEBAECAhIDZgJBGksgT3B0aW9uYWwuIEEgdG9rZW4g
aWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJu
LgoKDAoFBAECAgUSA2YCCAoMCgUEAQICARIDZgkTCgwKBQQBAgIDEgNmFhcKDAoFBAECAggS
A2YYQAoPCggEAQICCJwIABIDZhk/CioKBAQBAgMSA2kCPRodIE9wdGlvbmFsLiBGaWx0ZXJp
bmcgcmVzdWx0cwoKDAoFBAECAwUSA2kCCAoMCgUEAQIDARIDaQkPCgwKBQQBAgMDEgNpEhMK
DAoFBAECAwgSA2kUPAoPCggEAQIDCJwIABIDaRU7CjoKBAQBAgQSA2wCPxotIE9wdGlvbmFs
LiBIaW50IGZvciBob3cgdG8gb3JkZXIgdGhlIHJlc3VsdHMKCgwKBQQBAgQFEgNsAggKDAoF
BAECBAESA2wJEQoMCgUEAQIEAxIDbBQVCgwKBQQBAgQIEgNsFj4KDwoIBAECBAicCAASA2wX
PQo4CgIEAhIEcAB5ARosIE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgTWNwU2Vy
dmVycwoKCgoDBAIBEgNwCB4KJAoEBAICABIDcgIlGhcgVGhlIGxpc3Qgb2YgTWNwU2VydmVy
CgoMCgUEAgIABBIDcgIKCgwKBQQCAgAGEgNyCxQKDAoFBAICAAESA3IVIAoMCgUEAgIAAxID
ciMkCk4KBAQCAgESA3UCHRpBIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3Vs
dHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAICAQUSA3UCCAoMCgUEAgIBARID
dQkYCgwKBQQCAgEDEgN1GxwKMwoEBAICAhIDeAIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQg
bm90IGJlIHJlYWNoZWQuCgoMCgUEAgICBBIDeAIKCgwKBQQCAgIFEgN4CxEKDAoFBAICAgES
A3gSHQoMCgUEAgICAxIDeCAhCiwKAgQDEgV8AIQBARofIE1lc3NhZ2UgZm9yIGdldHRpbmcg
YSBNY3BUb29sCgoKCgMEAwESA3wIGQovCgQEAwIAEgV+AoMBBBogIFJlcXVpcmVkLiBOYW1l
IG9mIHRoZSByZXNvdXJjZQoKDAoFBAMCAAUSA34CCAoMCgUEAwIAARIDfgkNCgwKBQQDAgAD
EgN+EBEKDgoFBAMCAAgSBX4SgwEDCg8KCAQDAgAInAgAEgN/BCoKEQoHBAMCAAifCBIGgAEE
ggEFCjcKAgQEEgaHAQCcAQEaKSBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGxpc3Qgb2YgTWNw
VG9vbHMKCgsKAwQEARIEhwEIGwpACgQEBAIAEgaJAQKOAQQaMCBSZXF1aXJlZC4gUGFyZW50
IHZhbHVlIGZvciBMaXN0TWNwVG9vbHNSZXF1ZXN0CgoNCgUEBAIABRIEiQECCAoNCgUEBAIA
ARIEiQEJDwoNCgUEBAIAAxIEiQESEwoPCgUEBAIACBIGiQEUjgEDChAKCAQEAgAInAgAEgSK
AQQqChEKBwQEAgAInwgSBosBBI0BBQqXAQoEBAQCARIEkgECPxqIASBPcHRpb25hbC4gUmVx
dWVzdGVkIHBhZ2Ugc2l6ZS4gU2VydmVyIG1heSByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbgog
cmVxdWVzdGVkLiBJZiB1bnNwZWNpZmllZCwgc2VydmVyIHdpbGwgcGljayBhbiBhcHByb3By
aWF0ZSBkZWZhdWx0LgoKDQoFBAQCAQUSBJIBAgcKDQoFBAQCAQESBJIBCBEKDQoFBAQCAQMS
BJIBFBUKDQoFBAQCAQgSBJIBFj4KEAoIBAQCAQicCAASBJIBFz0KWQoEBAQCAhIElQECQRpL
IE9wdGlvbmFsLiBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBz
ZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQEAgIFEgSVAQIICg0KBQQEAgIBEgSVAQkTCg0K
BQQEAgIDEgSVARYXCg0KBQQEAgIIEgSVARhAChAKCAQEAgIInAgAEgSVARk/CisKBAQEAgMS
BJgBAj0aHSBPcHRpb25hbC4gRmlsdGVyaW5nIHJlc3VsdHMKCg0KBQQEAgMFEgSYAQIICg0K
BQQEAgMBEgSYAQkPCg0KBQQEAgMDEgSYARITCg0KBQQEAgMIEgSYARQ8ChAKCAQEAgMInAgA
EgSYARU7CjsKBAQEAgQSBJsBAj8aLSBPcHRpb25hbC4gSGludCBmb3IgaG93IHRvIG9yZGVy
IHRoZSByZXN1bHRzCgoNCgUEBAIEBRIEmwECCAoNCgUEBAIEARIEmwEJEQoNCgUEBAIEAxIE
mwEUFQoNCgUEBAIECBIEmwEWPgoQCggEBAIECJwIABIEmwEXPQo4CgIEBRIGnwEAqAEBGiog
TWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGluZyBNY3BUb29scwoKCwoDBAUBEgSfAQgc
CiMKBAQFAgASBKEBAiEaFSBUaGUgbGlzdCBvZiBNY3BUb29sCgoNCgUEBQIABBIEoQECCgoN
CgUEBQIABhIEoQELEgoNCgUEBQIAARIEoQETHAoNCgUEBQIAAxIEoQEfIApPCgQEBQIBEgSk
AQIdGkEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVy
IHNob3VsZCByZXR1cm4uCgoNCgUEBQIBBRIEpAECCAoNCgUEBQIBARIEpAEJGAoNCgUEBQIB
AxIEpAEbHAo0CgQEBQICEgSnAQIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJl
YWNoZWQuCgoNCgUEBQICBBIEpwECCgoNCgUEBQICBRIEpwELEQoNCgUEBQICARIEpwESHQoN
CgUEBQICAxIEpwEgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apiregistry::V1beta::Service::GetMcpServerRequest ===
    # Fields for GetMcpServerRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersRequest ===
    # Fields for ListMcpServersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersResponse ===
    # Fields for ListMcpServersResponse
    # Field: mcp_servers Type: 11 (.google.cloud.apiregistry.v1beta.McpServer)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1beta::Service::GetMcpToolRequest ===
    # Fields for GetMcpToolRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsRequest ===
    # Fields for ListMcpToolsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsResponse ===
    # Fields for ListMcpToolsResponse
    # Field: mcp_tools Type: 11 (.google.cloud.apiregistry.v1beta.McpTool)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Service Client: Google::Cloud::Apiregistry::V1beta::Service::CloudApiRegistryClient ===
package Google::Cloud::Apiregistry::V1beta::Service::CloudApiRegistryClient;

=pod

=head2 Service Client: Google::Cloud::Apiregistry::V1beta::Service::CloudApiRegistryClient

Client stub representing the remote C<CloudApiRegistry> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apiregistry.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apiregistry.googleapis.com:443' );

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

sub get_mcp_server {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1beta::Service::GetMcpServerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1beta.CloudApiRegistry',
        method         => 'GetMcpServer',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1beta::Resources::McpServer',
    });
}

sub list_mcp_servers {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1beta.CloudApiRegistry',
        method         => 'ListMcpServers',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersResponse',
    });
}

sub get_mcp_tool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1beta::Service::GetMcpToolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1beta.CloudApiRegistry',
        method         => 'GetMcpTool',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1beta::Resources::McpTool',
    });
}

sub list_mcp_tools {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1beta.CloudApiRegistry',
        method         => 'ListMcpTools',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apiregistry::V1beta::Service - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1beta/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apiregistry::V1beta::Service;

    my $msg = Google::Cloud::Apiregistry::V1beta::Service::GetMcpServerRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apiregistry::V1beta::Service::GetMcpServerRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1beta/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apiregistry::V1beta::Service::GetMcpServerRequest

Message for getting a McpServer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource

=back

=head2 Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersRequest

Message for requesting list of McpServers

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListMcpServersRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Apiregistry::V1beta::Service::ListMcpServersResponse

Message for response to listing McpServers

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_servers() >> / C<< $msg->mcp_servers($value) >>

Type: C<Message> (L<Google::Cloud::Apiregistry::V1beta::Resources::McpServer>)

The list of McpServer

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Apiregistry::V1beta::Service::GetMcpToolRequest

Message for getting a McpTool

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource

=back

=head2 Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsRequest

Message for requesting list of McpTools

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListMcpToolsRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Apiregistry::V1beta::Service::ListMcpToolsResponse

Message for response to listing McpTools

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_tools() >> / C<< $msg->mcp_tools($value) >>

Type: C<Message> (L<Google::Cloud::Apiregistry::V1beta::Resources::McpTool>)

The list of McpTool

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1beta::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
