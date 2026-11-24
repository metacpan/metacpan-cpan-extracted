package Google::Firestore::Admin::V1beta2::FirestoreAdmin;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Firestore::Admin::V1beta2::Field };
    eval { require Google::Firestore::Admin::V1beta2::Index };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Api::Client };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTIvZmlyZXN0b3JlX2FkbWluLnByb3Rv
Eh5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aKmdvb2dsZS9maXJlc3RvcmUvYWRtaW4vdjFiZXRhMi9maWVsZC5wcm90bxoq
Z29vZ2xlL2ZpcmVzdG9yZS9hZG1pbi92MWJldGEyL2luZGV4LnByb3RvGiNnb29nbGUvbG9u
Z3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQu
cHJvdG8iaQoSQ3JlYXRlSW5kZXhSZXF1ZXN0EhYKBnBhcmVudBgBIAEoCVIGcGFyZW50EjsK
BWluZGV4GAIgASgLMiUuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkluZGV4UgVp
bmRleCKAAQoSTGlzdEluZGV4ZXNSZXF1ZXN0EhYKBnBhcmVudBgBIAEoCVIGcGFyZW50EhYK
BmZpbHRlchgCIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuIn4KE0xpc3RJbmRleGVzUmVzcG9uc2USPwoH
aW5kZXhlcxgBIAMoCzIlLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5JbmRleFIH
aW5kZXhlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iJQoPR2V0
SW5kZXhSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUiKAoSRGVsZXRlSW5kZXhSZXF1ZXN0
EhIKBG5hbWUYASABKAlSBG5hbWUijgEKElVwZGF0ZUZpZWxkUmVxdWVzdBI7CgVmaWVsZBgB
IAEoCzIlLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaWVsZFIFZmllbGQSOwoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVN
YXNrIiUKD0dldEZpZWxkUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lIn8KEUxpc3RGaWVs
ZHNSZXF1ZXN0EhYKBnBhcmVudBgBIAEoCVIGcGFyZW50EhYKBmZpbHRlchgCIAEoCVIGZmls
dGVyEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgEIAEoCVIJ
cGFnZVRva2VuInsKEkxpc3RGaWVsZHNSZXNwb25zZRI9CgZmaWVsZHMYASADKAsyJS5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmllbGRSBmZpZWxkcxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ifwoWRXhwb3J0RG9jdW1lbnRzUmVxdWVzdBIS
CgRuYW1lGAEgASgJUgRuYW1lEiUKDmNvbGxlY3Rpb25faWRzGAIgAygJUg1jb2xsZWN0aW9u
SWRzEioKEW91dHB1dF91cmlfcHJlZml4GAMgASgJUg9vdXRwdXRVcmlQcmVmaXgifQoWSW1w
b3J0RG9jdW1lbnRzUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEiUKDmNvbGxlY3Rpb25f
aWRzGAIgAygJUg1jb2xsZWN0aW9uSWRzEigKEGlucHV0X3VyaV9wcmVmaXgYAyABKAlSDmlu
cHV0VXJpUHJlZml4MusNCg5GaXJlc3RvcmVBZG1pbhK0AQoLQ3JlYXRlSW5kZXgSMi5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuQ3JlYXRlSW5kZXhSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiJSgtPkkwJMIkMvdjFiZXRhMi97cGFyZW50PXByb2pl
Y3RzLyovZGF0YWJhc2VzLyovY29sbGVjdGlvbkdyb3Vwcy8qfS9pbmRleGVzOgVpbmRleBLD
AQoLTGlzdEluZGV4ZXMSMi5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuTGlzdElu
ZGV4ZXNSZXF1ZXN0GjMuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkxpc3RJbmRl
eGVzUmVzcG9uc2UiS4LT5JMCRRJDL3YxYmV0YTIve3BhcmVudD1wcm9qZWN0cy8qL2RhdGFi
YXNlcy8qL2NvbGxlY3Rpb25Hcm91cHMvKn0vaW5kZXhlcxKvAQoIR2V0SW5kZXgSLy5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuR2V0SW5kZXhSZXF1ZXN0GiUuZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MWJldGEyLkluZGV4IkuC0+STAkUSQy92MWJldGEyL3tuYW1lPXBy
b2plY3RzLyovZGF0YWJhc2VzLyovY29sbGVjdGlvbkdyb3Vwcy8qL2luZGV4ZXMvKn0SpgEK
C0RlbGV0ZUluZGV4EjIuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkRlbGV0ZUlu
ZGV4UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJLgtPkkwJFKkMvdjFiZXRhMi97
bmFtZT1wcm9qZWN0cy8qL2RhdGFiYXNlcy8qL2NvbGxlY3Rpb25Hcm91cHMvKi9pbmRleGVz
Lyp9Eq4BCghHZXRGaWVsZBIvLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5HZXRG
aWVsZFJlcXVlc3QaJS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmllbGQiSoLT
5JMCRBJCL3YxYmV0YTIve25hbWU9cHJvamVjdHMvKi9kYXRhYmFzZXMvKi9jb2xsZWN0aW9u
R3JvdXBzLyovZmllbGRzLyp9ErkBCgtVcGRhdGVGaWVsZBIyLmdvb2dsZS5maXJlc3RvcmUu
YWRtaW4udjFiZXRhMi5VcGRhdGVGaWVsZFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uIleC0+STAlEySC92MWJldGEyL3tmaWVsZC5uYW1lPXByb2plY3RzLyovZGF0
YWJhc2VzLyovY29sbGVjdGlvbkdyb3Vwcy8qL2ZpZWxkcy8qfToFZmllbGQSvwEKCkxpc3RG
aWVsZHMSMS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuTGlzdEZpZWxkc1JlcXVl
c3QaMi5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuTGlzdEZpZWxkc1Jlc3BvbnNl
IkqC0+STAkQSQi92MWJldGEyL3twYXJlbnQ9cHJvamVjdHMvKi9kYXRhYmFzZXMvKi9jb2xs
ZWN0aW9uR3JvdXBzLyp9L2ZpZWxkcxKrAQoPRXhwb3J0RG9jdW1lbnRzEjYuZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MWJldGEyLkV4cG9ydERvY3VtZW50c1JlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIkGC0+STAjsiNi92MWJldGEyL3tuYW1lPXByb2plY3Rz
LyovZGF0YWJhc2VzLyp9OmV4cG9ydERvY3VtZW50czoBKhKrAQoPSW1wb3J0RG9jdW1lbnRz
EjYuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkltcG9ydERvY3VtZW50c1JlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIkGC0+STAjsiNi92MWJldGEyL3tu
YW1lPXByb2plY3RzLyovZGF0YWJhc2VzLyp9OmltcG9ydERvY3VtZW50czoBKhp2ykEYZmly
ZXN0b3JlLmdvb2dsZWFwaXMuY29t0kFYaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RhdGFz
dG9yZUKpAQoiY29tLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMkITRmlyZXN0b3Jl
QWRtaW5Qcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2ZpcmVzdG9yZS9hZG1pbi9hcGl2
MWJldGEyL2FkbWlucGI7YWRtaW5wYqICBEdDRlOqAiRHb29nbGUuQ2xvdWQuRmlyZXN0b3Jl
LkFkbWluLlYxQmV0YTJKhlMKBxIFDwCVAgEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAy
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
Y2Vuc2UuCgoKCAoBAhIDEQAnCgkKAgMAEgMTACYKCQoCAwESAxQANAoJCgIDAhIDFQA0CgkK
AgMDEgMWAC0KCQoCAwQSAxcAJQoJCgIDBRIDGAAqCgkKAgMGEgMZACEKCAoBCBIDGwBBCgkK
AgglEgMbAEEKCAoBCBIDHABVCgkKAggLEgMcAFUKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoB
CBIDHgA0CgkKAggIEgMeADQKCAoBCBIDHwA7CgkKAggBEgMfADsKCAoBCBIDIAAiCgkKAggk
EgMgACIKgQEKAgYAEgUkAIoBARp0IE9wZXJhdGlvbnMgYXJlIGNyZWF0ZWQgYnkgc2Vydmlj
ZSBgRmlyZXN0b3JlQWRtaW5gLCBidXQgYXJlIGFjY2Vzc2VkIHZpYQogc2VydmljZSBgZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnNgLgoKCgoDBgABEgMkCBYKCgoDBgADEgMlAkAK
DAoFBgADmQgSAyUCQAoLCgMGAAMSBCYCKDIKDQoFBgADmggSBCYCKDIKsQIKBAYAAgASBC0C
MgMaogIgQ3JlYXRlcyBhIGNvbXBvc2l0ZSBpbmRleC4gVGhpcyByZXR1cm5zIGEgW2dvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25d
CiB3aGljaCBtYXkgYmUgdXNlZCB0byB0cmFjayB0aGUgc3RhdHVzIG9mIHRoZSBjcmVhdGlv
bi4gVGhlIG1ldGFkYXRhIGZvcgogdGhlIG9wZXJhdGlvbiB3aWxsIGJlIHRoZSB0eXBlIFtJ
bmRleE9wZXJhdGlvbk1ldGFkYXRhXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIu
SW5kZXhPcGVyYXRpb25NZXRhZGF0YV0uCgoMCgUGAAIAARIDLQYRCgwKBQYAAgACEgMtEiQK
DAoFBgACAAMSAy0vSwoNCgUGAAIABBIELgQxBgoRCgkGAAIABLDKvCISBC4EMQYKKAoEBgAC
ARIENQI5AxoaIExpc3RzIGNvbXBvc2l0ZSBpbmRleGVzLgoKDAoFBgACAQESAzUGEQoMCgUG
AAIBAhIDNRIkCgwKBQYAAgEDEgM1L0IKDQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2
BDgGCicKBAYAAgISBDwCQAMaGSBHZXRzIGEgY29tcG9zaXRlIGluZGV4LgoKDAoFBgACAgES
AzwGDgoMCgUGAAICAhIDPA8eCgwKBQYAAgIDEgM8KS4KDQoFBgACAgQSBD0EPwYKEQoJBgAC
AgSwyrwiEgQ9BD8GCioKBAYAAgMSBEMCRwMaHCBEZWxldGVzIGEgY29tcG9zaXRlIGluZGV4
LgoKDAoFBgACAwESA0MGEQoMCgUGAAIDAhIDQxIkCgwKBQYAAgMDEgNDL0QKDQoFBgACAwQS
BEQERgYKEQoJBgACAwSwyrwiEgREBEYGCkAKBAYAAgQSBEoCTgMaMiBHZXRzIHRoZSBtZXRh
ZGF0YSBhbmQgY29uZmlndXJhdGlvbiBmb3IgYSBGaWVsZC4KCgwKBQYAAgQBEgNKBg4KDAoF
BgACBAISA0oPHgoMCgUGAAIEAxIDSikuCg0KBQYAAgQEEgRLBE0GChEKCQYAAgQEsMq8IhIE
SwRNBgrcBgoEBgACBRIEXQJiAxrNBiBVcGRhdGVzIGEgZmllbGQgY29uZmlndXJhdGlvbi4g
Q3VycmVudGx5LCBmaWVsZCB1cGRhdGVzIGFwcGx5IG9ubHkgdG8KIHNpbmdsZSBmaWVsZCBp
bmRleCBjb25maWd1cmF0aW9uLiBIb3dldmVyLCBjYWxscyB0bwogW0ZpcmVzdG9yZUFkbWlu
LlVwZGF0ZUZpZWxkXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmlyZXN0b3Jl
QWRtaW4uVXBkYXRlRmllbGRdIHNob3VsZCBwcm92aWRlIGEgZmllbGQgbWFzayB0byBhdm9p
ZAogY2hhbmdpbmcgYW55IGNvbmZpZ3VyYXRpb24gdGhhdCB0aGUgY2FsbGVyIGlzbid0IGF3
YXJlIG9mLiBUaGUgZmllbGQgbWFzawogc2hvdWxkIGJlIHNwZWNpZmllZCBhczogYHsgcGF0
aHM6ICJpbmRleF9jb25maWciIH1gLgoKIFRoaXMgY2FsbCByZXR1cm5zIGEgW2dvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dIHdo
aWNoIG1heSBiZSB1c2VkIHRvCiB0cmFjayB0aGUgc3RhdHVzIG9mIHRoZSBmaWVsZCB1cGRh
dGUuIFRoZSBtZXRhZGF0YSBmb3IKIHRoZSBvcGVyYXRpb24gd2lsbCBiZSB0aGUgdHlwZSBb
RmllbGRPcGVyYXRpb25NZXRhZGF0YV1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEy
LkZpZWxkT3BlcmF0aW9uTWV0YWRhdGFdLgoKIFRvIGNvbmZpZ3VyZSB0aGUgZGVmYXVsdCBm
aWVsZCBzZXR0aW5ncyBmb3IgdGhlIGRhdGFiYXNlLCB1c2UKIHRoZSBzcGVjaWFsIGBGaWVs
ZGAgd2l0aCByZXNvdXJjZSBuYW1lOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFz
ZXMve2RhdGFiYXNlX2lkfS9jb2xsZWN0aW9uR3JvdXBzL19fZGVmYXVsdF9fL2ZpZWxkcy8q
YC4KCgwKBQYAAgUBEgNdBhEKDAoFBgACBQISA10SJAoMCgUGAAIFAxIDXS9LCg0KBQYAAgUE
EgReBGEGChEKCQYAAgUEsMq8IhIEXgRhBgqmAwoEBgACBhIEagJuAxqXAyBMaXN0cyB0aGUg
ZmllbGQgY29uZmlndXJhdGlvbiBhbmQgbWV0YWRhdGEgZm9yIHRoaXMgZGF0YWJhc2UuCgog
Q3VycmVudGx5LCBbRmlyZXN0b3JlQWRtaW4uTGlzdEZpZWxkc11bZ29vZ2xlLmZpcmVzdG9y
ZS5hZG1pbi52MWJldGEyLkZpcmVzdG9yZUFkbWluLkxpc3RGaWVsZHNdIG9ubHkgc3VwcG9y
dHMgbGlzdGluZyBmaWVsZHMKIHRoYXQgaGF2ZSBiZWVuIGV4cGxpY2l0bHkgb3ZlcnJpZGRl
bi4gVG8gaXNzdWUgdGhpcyBxdWVyeSwgY2FsbAogW0ZpcmVzdG9yZUFkbWluLkxpc3RGaWVs
ZHNdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3RvcmVBZG1pbi5MaXN0
RmllbGRzXSB3aXRoIHRoZSBmaWx0ZXIgc2V0IHRvCiBgaW5kZXhDb25maWcudXNlc0FuY2Vz
dG9yQ29uZmlnOmZhbHNlYC4KCgwKBQYAAgYBEgNqBhAKDAoFBgACBgISA2oRIgoMCgUGAAIG
AxIDai0/Cg0KBQYAAgYEEgRrBG0GChEKCQYAAgYEsMq8IhIEawRtBgqZBAoEBgACBxIEeAJ9
AxqKBCBFeHBvcnRzIGEgY29weSBvZiBhbGwgb3IgYSBzdWJzZXQgb2YgZG9jdW1lbnRzIGZy
b20gR29vZ2xlIENsb3VkIEZpcmVzdG9yZQogdG8gYW5vdGhlciBzdG9yYWdlIHN5c3RlbSwg
c3VjaCBhcyBHb29nbGUgQ2xvdWQgU3RvcmFnZS4gUmVjZW50IHVwZGF0ZXMgdG8KIGRvY3Vt
ZW50cyBtYXkgbm90IGJlIHJlZmxlY3RlZCBpbiB0aGUgZXhwb3J0LiBUaGUgZXhwb3J0IG9j
Y3VycyBpbiB0aGUKIGJhY2tncm91bmQgYW5kIGl0cyBwcm9ncmVzcyBjYW4gYmUgbW9uaXRv
cmVkIGFuZCBtYW5hZ2VkIHZpYSB0aGUKIE9wZXJhdGlvbiByZXNvdXJjZSB0aGF0IGlzIGNy
ZWF0ZWQuIFRoZSBvdXRwdXQgb2YgYW4gZXhwb3J0IG1heSBvbmx5IGJlCiB1c2VkIG9uY2Ug
dGhlIGFzc29jaWF0ZWQgb3BlcmF0aW9uIGlzIGRvbmUuIElmIGFuIGV4cG9ydCBvcGVyYXRp
b24gaXMKIGNhbmNlbGxlZCBiZWZvcmUgY29tcGxldGlvbiBpdCBtYXkgbGVhdmUgcGFydGlh
bCBkYXRhIGJlaGluZCBpbiBHb29nbGUKIENsb3VkIFN0b3JhZ2UuCgoMCgUGAAIHARIDeAYV
CgwKBQYAAgcCEgN4FiwKDAoFBgACBwMSA3g3UwoNCgUGAAIHBBIEeQR8BgoRCgkGAAIHBLDK
vCISBHkEfAYK/wIKBAYAAggSBoQBAokBAxruAiBJbXBvcnRzIGRvY3VtZW50cyBpbnRvIEdv
b2dsZSBDbG91ZCBGaXJlc3RvcmUuIEV4aXN0aW5nIGRvY3VtZW50cyB3aXRoIHRoZQogc2Ft
ZSBuYW1lIGFyZSBvdmVyd3JpdHRlbi4gVGhlIGltcG9ydCBvY2N1cnMgaW4gdGhlIGJhY2tn
cm91bmQgYW5kIGl0cwogcHJvZ3Jlc3MgY2FuIGJlIG1vbml0b3JlZCBhbmQgbWFuYWdlZCB2
aWEgdGhlIE9wZXJhdGlvbiByZXNvdXJjZSB0aGF0IGlzCiBjcmVhdGVkLiBJZiBhbiBJbXBv
cnREb2N1bWVudHMgb3BlcmF0aW9uIGlzIGNhbmNlbGxlZCwgaXQgaXMgcG9zc2libGUKIHRo
YXQgYSBzdWJzZXQgb2YgdGhlIGRhdGEgaGFzIGFscmVhZHkgYmVlbiBpbXBvcnRlZCB0byBD
bG91ZCBGaXJlc3RvcmUuCgoNCgUGAAIIARIEhAEGFQoNCgUGAAIIAhIEhAEWLAoNCgUGAAII
AxIEhAE3UwoPCgUGAAIIBBIGhQEEiAEGChMKCQYAAggEsMq8IhIGhQEEiAEGCngKAgQAEgaN
AQCUAQEaaiBUaGUgcmVxdWVzdCBmb3IgW0ZpcmVzdG9yZUFkbWluLkNyZWF0ZUluZGV4XVtn
b29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmlyZXN0b3JlQWRtaW4uQ3JlYXRlSW5k
ZXhdLgoKCwoDBAABEgSNAQgaCnsKBAQAAgASBJABAhQabSBBIHBhcmVudCBuYW1lIG9mIHRo
ZSBmb3JtCiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9
L2NvbGxlY3Rpb25Hcm91cHMve2NvbGxlY3Rpb25faWR9YAoKDQoFBAACAAUSBJABAggKDQoF
BAACAAESBJABCQ8KDQoFBAACAAMSBJABEhMKLgoEBAACARIEkwECEhogIFRoZSBjb21wb3Np
dGUgaW5kZXggdG8gY3JlYXRlLgoKDQoFBAACAQYSBJMBAgcKDQoFBAACAQESBJMBCA0KDQoF
BAACAQMSBJMBEBEKeAoCBAESBpcBAKYBARpqIFRoZSByZXF1ZXN0IGZvciBbRmlyZXN0b3Jl
QWRtaW4uTGlzdEluZGV4ZXNdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJl
c3RvcmVBZG1pbi5MaXN0SW5kZXhlc10uCgoLCgMEAQESBJcBCBoKewoEBAECABIEmgECFBpt
IEEgcGFyZW50IG5hbWUgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vZGF0
YWJhc2VzL3tkYXRhYmFzZV9pZH0vY29sbGVjdGlvbkdyb3Vwcy97Y29sbGVjdGlvbl9pZH1g
CgoNCgUEAQIABRIEmgECCAoNCgUEAQIAARIEmgEJDwoNCgUEAQIAAxIEmgESEwo0CgQEAQIB
EgSdAQIUGiYgVGhlIGZpbHRlciB0byBhcHBseSB0byBsaXN0IHJlc3VsdHMuCgoNCgUEAQIB
BRIEnQECCAoNCgUEAQIBARIEnQEJDwoNCgUEAQIBAxIEnQESEwowCgQEAQICEgSgAQIWGiIg
VGhlIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybi4KCg0KBQQBAgIFEgSgAQIHCg0KBQQB
AgIBEgSgAQgRCg0KBQQBAgIDEgSgARQVCswBCgQEAQIDEgSlAQIYGr0BIEEgcGFnZSB0b2tl
biwgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGNhbGwgdG8KIFtGaXJlc3RvcmVBZG1pbi5M
aXN0SW5kZXhlc11bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkZpcmVzdG9yZUFk
bWluLkxpc3RJbmRleGVzXSwgdGhhdCBtYXkgYmUgdXNlZCB0byBnZXQgdGhlIG5leHQKIHBh
Z2Ugb2YgcmVzdWx0cy4KCg0KBQQBAgMFEgSlAQIICg0KBQQBAgMBEgSlAQkTCg0KBQQBAgMD
EgSlARYXCnkKAgQCEgapAQCwAQEaayBUaGUgcmVzcG9uc2UgZm9yIFtGaXJlc3RvcmVBZG1p
bi5MaXN0SW5kZXhlc11bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkZpcmVzdG9y
ZUFkbWluLkxpc3RJbmRleGVzXS4KCgsKAwQCARIEqQEIGwomCgQEAgIAEgSrAQIdGhggVGhl
IHJlcXVlc3RlZCBpbmRleGVzLgoKDQoFBAICAAQSBKsBAgoKDQoFBAICAAYSBKsBCxAKDQoF
BAICAAESBKsBERgKDQoFBAICAAMSBKsBGxwKcwoEBAICARIErwECHRplIEEgcGFnZSB0b2tl
biB0aGF0IG1heSBiZSB1c2VkIHRvIHJlcXVlc3QgYW5vdGhlciBwYWdlIG9mIHJlc3VsdHMu
IElmIGJsYW5rLAogdGhpcyBpcyB0aGUgbGFzdCBwYWdlLgoKDQoFBAICAQUSBK8BAggKDQoF
BAICAQESBK8BCRgKDQoFBAICAQMSBK8BGxwKcgoCBAMSBrMBALcBARpkIFRoZSByZXF1ZXN0
IGZvciBbRmlyZXN0b3JlQWRtaW4uR2V0SW5kZXhdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4u
djFiZXRhMi5GaXJlc3RvcmVBZG1pbi5HZXRJbmRleF0uCgoLCgMEAwESBLMBCBcKhwEKBAQD
AgASBLYBAhIaeSBBIG5hbWUgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdF9pZH0v
ZGF0YWJhc2VzL3tkYXRhYmFzZV9pZH0vY29sbGVjdGlvbkdyb3Vwcy97Y29sbGVjdGlvbl9p
ZH0vaW5kZXhlcy97aW5kZXhfaWR9YAoKDQoFBAMCAAUSBLYBAggKDQoFBAMCAAESBLYBCQ0K
DQoFBAMCAAMSBLYBEBEKeAoCBAQSBroBAL4BARpqIFRoZSByZXF1ZXN0IGZvciBbRmlyZXN0
b3JlQWRtaW4uRGVsZXRlSW5kZXhdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5G
aXJlc3RvcmVBZG1pbi5EZWxldGVJbmRleF0uCgoLCgMEBAESBLoBCBoKhwEKBAQEAgASBL0B
AhIaeSBBIG5hbWUgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vZGF0YWJh
c2VzL3tkYXRhYmFzZV9pZH0vY29sbGVjdGlvbkdyb3Vwcy97Y29sbGVjdGlvbl9pZH0vaW5k
ZXhlcy97aW5kZXhfaWR9YAoKDQoFBAQCAAUSBL0BAggKDQoFBAQCAAESBL0BCQ0KDQoFBAQC
AAMSBL0BEBEKeAoCBAUSBsEBAMgBARpqIFRoZSByZXF1ZXN0IGZvciBbRmlyZXN0b3JlQWRt
aW4uVXBkYXRlRmllbGRdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3Rv
cmVBZG1pbi5VcGRhdGVGaWVsZF0uCgoLCgMEBQESBMEBCBoKKAoEBAUCABIEwwECEhoaIFRo
ZSBmaWVsZCB0byBiZSB1cGRhdGVkLgoKDQoFBAUCAAYSBMMBAgcKDQoFBAUCAAESBMMBCA0K
DQoFBAUCAAMSBMMBEBEKiwEKBAQFAgESBMcBAiwafSBBIG1hc2ssIHJlbGF0aXZlIHRvIHRo
ZSBmaWVsZC4gSWYgc3BlY2lmaWVkLCBvbmx5IGNvbmZpZ3VyYXRpb24gc3BlY2lmaWVkCiBi
eSB0aGlzIGZpZWxkX21hc2sgd2lsbCBiZSB1cGRhdGVkIGluIHRoZSBmaWVsZC4KCg0KBQQF
AgEGEgTHAQIbCg0KBQQFAgEBEgTHARwnCg0KBQQFAgEDEgTHASorCnIKAgQGEgbLAQDPAQEa
ZCBUaGUgcmVxdWVzdCBmb3IgW0ZpcmVzdG9yZUFkbWluLkdldEZpZWxkXVtnb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxYmV0YTIuRmlyZXN0b3JlQWRtaW4uR2V0RmllbGRdLgoKCwoDBAYB
EgTLAQgXCoYBCgQEBgIAEgTOAQISGnggQSBuYW1lIG9mIHRoZSBmb3JtCiBgcHJvamVjdHMv
e3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91cHMv
e2NvbGxlY3Rpb25faWR9L2ZpZWxkcy97ZmllbGRfaWR9YAoKDQoFBAYCAAUSBM4BAggKDQoF
BAYCAAESBM4BCQ0KDQoFBAYCAAMSBM4BEBEKdgoCBAcSBtIBAOUBARpoIFRoZSByZXF1ZXN0
IGZvciBbRmlyZXN0b3JlQWRtaW4uTGlzdEZpZWxkc11bZ29vZ2xlLmZpcmVzdG9yZS5hZG1p
bi52MWJldGEyLkZpcmVzdG9yZUFkbWluLkxpc3RGaWVsZHNdLgoKCwoDBAcBEgTSAQgZCnsK
BAQHAgASBNUBAhQabSBBIHBhcmVudCBuYW1lIG9mIHRoZSBmb3JtCiBgcHJvamVjdHMve3By
b2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91cHMve2Nv
bGxlY3Rpb25faWR9YAoKDQoFBAcCAAUSBNUBAggKDQoFBAcCAAESBNUBCQ8KDQoFBAcCAAMS
BNUBEhMKjAMKBAQHAgESBNwBAhQa/QIgVGhlIGZpbHRlciB0byBhcHBseSB0byBsaXN0IHJl
c3VsdHMuIEN1cnJlbnRseSwKIFtGaXJlc3RvcmVBZG1pbi5MaXN0RmllbGRzXVtnb29nbGUu
ZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmlyZXN0b3JlQWRtaW4uTGlzdEZpZWxkc10gb25s
eSBzdXBwb3J0cyBsaXN0aW5nIGZpZWxkcwogdGhhdCBoYXZlIGJlZW4gZXhwbGljaXRseSBv
dmVycmlkZGVuLiBUbyBpc3N1ZSB0aGlzIHF1ZXJ5LCBjYWxsCiBbRmlyZXN0b3JlQWRtaW4u
TGlzdEZpZWxkc11bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkZpcmVzdG9yZUFk
bWluLkxpc3RGaWVsZHNdIHdpdGggdGhlIGZpbHRlciBzZXQgdG8KIGBpbmRleENvbmZpZy51
c2VzQW5jZXN0b3JDb25maWc6ZmFsc2VgLgoKDQoFBAcCAQUSBNwBAggKDQoFBAcCAQESBNwB
CQ8KDQoFBAcCAQMSBNwBEhMKMAoEBAcCAhIE3wECFhoiIFRoZSBudW1iZXIgb2YgcmVzdWx0
cyB0byByZXR1cm4uCgoNCgUEBwICBRIE3wECBwoNCgUEBwICARIE3wEIEQoNCgUEBwICAxIE
3wEUFQrKAQoEBAcCAxIE5AECGBq7ASBBIHBhZ2UgdG9rZW4sIHJldHVybmVkIGZyb20gYSBw
cmV2aW91cyBjYWxsIHRvCiBbRmlyZXN0b3JlQWRtaW4uTGlzdEZpZWxkc11bZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MWJldGEyLkZpcmVzdG9yZUFkbWluLkxpc3RGaWVsZHNdLCB0aGF0
IG1heSBiZSB1c2VkIHRvIGdldCB0aGUgbmV4dAogcGFnZSBvZiByZXN1bHRzLgoKDQoFBAcC
AwUSBOQBAggKDQoFBAcCAwESBOQBCRMKDQoFBAcCAwMSBOQBFhcKdwoCBAgSBugBAO8BARpp
IFRoZSByZXNwb25zZSBmb3IgW0ZpcmVzdG9yZUFkbWluLkxpc3RGaWVsZHNdW2dvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3RvcmVBZG1pbi5MaXN0RmllbGRzXS4KCgsK
AwQIARIE6AEIGgolCgQECAIAEgTqAQIcGhcgVGhlIHJlcXVlc3RlZCBmaWVsZHMuCgoNCgUE
CAIABBIE6gECCgoNCgUECAIABhIE6gELEAoNCgUECAIAARIE6gERFwoNCgUECAIAAxIE6gEa
GwpzCgQECAIBEgTuAQIdGmUgQSBwYWdlIHRva2VuIHRoYXQgbWF5IGJlIHVzZWQgdG8gcmVx
dWVzdCBhbm90aGVyIHBhZ2Ugb2YgcmVzdWx0cy4gSWYgYmxhbmssCiB0aGlzIGlzIHRoZSBs
YXN0IHBhZ2UuCgoNCgUECAIBBRIE7gECCAoNCgUECAIBARIE7gEJGAoNCgUECAIBAxIE7gEb
HAqAAQoCBAkSBvIBAIMCARpyIFRoZSByZXF1ZXN0IGZvciBbRmlyZXN0b3JlQWRtaW4uRXhw
b3J0RG9jdW1lbnRzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmlyZXN0b3Jl
QWRtaW4uRXhwb3J0RG9jdW1lbnRzXS4KCgsKAwQJARIE8gEIHgpsCgQECQIAEgT1AQISGl4g
RGF0YWJhc2UgdG8gZXhwb3J0LiBTaG91bGQgYmUgb2YgdGhlIGZvcm06CiBgcHJvamVjdHMv
e3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9YC4KCg0KBQQJAgAFEgT1AQII
Cg0KBQQJAgABEgT1AQkNCg0KBQQJAgADEgT1ARARClIKBAQJAgESBPgBAiUaRCBXaGljaCBj
b2xsZWN0aW9uIGlkcyB0byBleHBvcnQuIFVuc3BlY2lmaWVkIG1lYW5zIGFsbCBjb2xsZWN0
aW9ucy4KCg0KBQQJAgEEEgT4AQIKCg0KBQQJAgEFEgT4AQsRCg0KBQQJAgEBEgT4ARIgCg0K
BQQJAgEDEgT4ASMkCv4DCgQECQICEgSCAgIfGu8DIFRoZSBvdXRwdXQgVVJJLiBDdXJyZW50
bHkgb25seSBzdXBwb3J0cyBHb29nbGUgQ2xvdWQgU3RvcmFnZSBVUklzIG9mIHRoZQogZm9y
bTogYGdzOi8vQlVDS0VUX05BTUVbL05BTUVTUEFDRV9QQVRIXWAsIHdoZXJlIGBCVUNLRVRf
TkFNRWAgaXMgdGhlIG5hbWUKIG9mIHRoZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBidWNrZXQg
YW5kIGBOQU1FU1BBQ0VfUEFUSGAgaXMgYW4gb3B0aW9uYWwKIEdvb2dsZSBDbG91ZCBTdG9y
YWdlIG5hbWVzcGFjZSBwYXRoLiBXaGVuCiBjaG9vc2luZyBhIG5hbWUsIGJlIHN1cmUgdG8g
Y29uc2lkZXIgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbmFtaW5nCiBndWlkZWxpbmVzOiBodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vc3RvcmFnZS9kb2NzL25hbWluZy4KIElmIHRoZSBVUkkg
aXMgYSBidWNrZXQgKHdpdGhvdXQgYSBuYW1lc3BhY2UgcGF0aCksIGEgcHJlZml4IHdpbGwg
YmUKIGdlbmVyYXRlZCBiYXNlZCBvbiB0aGUgc3RhcnQgdGltZS4KCg0KBQQJAgIFEgSCAgII
Cg0KBQQJAgIBEgSCAgkaCg0KBQQJAgIDEgSCAh0eCoABCgIEChIGhgIAlQIBGnIgVGhlIHJl
cXVlc3QgZm9yIFtGaXJlc3RvcmVBZG1pbi5JbXBvcnREb2N1bWVudHNdW2dvb2dsZS5maXJl
c3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3RvcmVBZG1pbi5JbXBvcnREb2N1bWVudHNdLgoK
CwoDBAoBEgSGAggeCnEKBAQKAgASBIkCAhIaYyBEYXRhYmFzZSB0byBpbXBvcnQgaW50by4g
U2hvdWxkIGJlIG9mIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFz
ZXMve2RhdGFiYXNlX2lkfWAuCgoNCgUECgIABRIEiQICCAoNCgUECgIAARIEiQIJDQoNCgUE
CgIAAxIEiQIQEQpqCgQECgIBEgSNAgIlGlwgV2hpY2ggY29sbGVjdGlvbiBpZHMgdG8gaW1w
b3J0LiBVbnNwZWNpZmllZCBtZWFucyBhbGwgY29sbGVjdGlvbnMgaW5jbHVkZWQKIGluIHRo
ZSBpbXBvcnQuCgoNCgUECgIBBBIEjQICCgoNCgUECgIBBRIEjQILEQoNCgUECgIBARIEjQIS
IAoNCgUECgIBAxIEjQIjJArDAgoEBAoCAhIElAICHhq0AiBMb2NhdGlvbiBvZiB0aGUgZXhw
b3J0ZWQgZmlsZXMuCiBUaGlzIG11c3QgbWF0Y2ggdGhlIG91dHB1dF91cmlfcHJlZml4IG9m
IGFuIEV4cG9ydERvY3VtZW50c1Jlc3BvbnNlIGZyb20KIGFuIGV4cG9ydCB0aGF0IGhhcyBj
b21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgogU2VlOgogW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4u
djFiZXRhMi5FeHBvcnREb2N1bWVudHNSZXNwb25zZS5vdXRwdXRfdXJpX3ByZWZpeF1bZ29v
Z2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkV4cG9ydERvY3VtZW50c1Jlc3BvbnNlLm91
dHB1dF91cmlfcHJlZml4XS4KCg0KBQQKAgIFEgSUAgIICg0KBQQKAgIBEgSUAgkZCg0KBQQK
AgIDEgSUAhwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest ===
    # Fields for CreateIndexRequest
    # Field: parent Type: 9 ()
    # Field: index Type: 11 (.google.firestore.admin.v1beta2.Index)

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest ===
    # Fields for ListIndexesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse ===
    # Fields for ListIndexesResponse
    # Field: indexes Type: 11 (.google.firestore.admin.v1beta2.Index)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest ===
    # Fields for GetIndexRequest
    # Field: name Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest ===
    # Fields for DeleteIndexRequest
    # Field: name Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest ===
    # Fields for UpdateFieldRequest
    # Field: field Type: 11 (.google.firestore.admin.v1beta2.Field)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest ===
    # Fields for GetFieldRequest
    # Field: name Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest ===
    # Fields for ListFieldsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse ===
    # Fields for ListFieldsResponse
    # Field: fields Type: 11 (.google.firestore.admin.v1beta2.Field)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest ===
    # Fields for ExportDocumentsRequest
    # Field: name Type: 9 ()
    # Field: collection_ids Type: 9 ()
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest ===
    # Fields for ImportDocumentsRequest
    # Field: name Type: 9 ()
    # Field: collection_ids Type: 9 ()
    # Field: input_uri_prefix Type: 9 ()

# === Service Client: Google::Firestore::Admin::V1beta2::FirestoreAdmin::FirestoreAdminClient ===
package Google::Firestore::Admin::V1beta2::FirestoreAdmin::FirestoreAdminClient;

=pod

=head2 Service Client: Google::Firestore::Admin::V1beta2::FirestoreAdmin::FirestoreAdminClient

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
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'CreateIndex',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_indexes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'ListIndexes',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse',
    });
}

sub get_index {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'GetIndex',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta2::Index::Index',
    });
}

sub delete_index {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'DeleteIndex',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_field {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'GetField',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta2::Field::Field',
    });
}

sub update_field {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'UpdateField',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_fields {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'ListFields',
        request        => $req,
        response_class => 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse',
    });
}

sub export_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'ExportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firestore.admin.v1beta2.FirestoreAdmin',
        method         => 'ImportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta2::FirestoreAdmin - Compiled Protocol Buffers messages for google/firestore/admin/v1beta2/firestore_admin.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta2::FirestoreAdmin;

    my $msg = Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest->new({
        parent => $parent,
        index => $index,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta2/firestore_admin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest

The request for [FirestoreAdmin.CreateIndex][google.firestore.admin.v1beta2.FirestoreAdmin.CreateIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

A parent name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Index::Index>)

The composite index to create.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest

The request for [FirestoreAdmin.ListIndexes][google.firestore.admin.v1beta2.FirestoreAdmin.ListIndexes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

A parent name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter to apply to list results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, returned from a previous call to
[FirestoreAdmin.ListIndexes][google.firestore.admin.v1beta2.FirestoreAdmin.ListIndexes], that may be used to get the next
page of results.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse

The response for [FirestoreAdmin.ListIndexes][google.firestore.admin.v1beta2.FirestoreAdmin.ListIndexes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->indexes() >> / C<< $msg->indexes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Index::Index>)

The requested indexes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A page token that may be used to request another page of results. If blank,
this is the last page.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest

The request for [FirestoreAdmin.GetIndex][google.firestore.admin.v1beta2.FirestoreAdmin.GetIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest

The request for [FirestoreAdmin.DeleteIndex][google.firestore.admin.v1beta2.FirestoreAdmin.DeleteIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest

The request for [FirestoreAdmin.UpdateField][google.firestore.admin.v1beta2.FirestoreAdmin.UpdateField].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Field::Field>)

The field to be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A mask, relative to the field. If specified, only configuration specified
by this field_mask will be updated in the field.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest

The request for [FirestoreAdmin.GetField][google.firestore.admin.v1beta2.FirestoreAdmin.GetField].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_id}`

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest

The request for [FirestoreAdmin.ListFields][google.firestore.admin.v1beta2.FirestoreAdmin.ListFields].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

A parent name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter to apply to list results. Currently,
[FirestoreAdmin.ListFields][google.firestore.admin.v1beta2.FirestoreAdmin.ListFields] only supports listing fields
that have been explicitly overridden. To issue this query, call
[FirestoreAdmin.ListFields][google.firestore.admin.v1beta2.FirestoreAdmin.ListFields] with the filter set to
`indexConfig.usesAncestorConfig:false`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, returned from a previous call to
[FirestoreAdmin.ListFields][google.firestore.admin.v1beta2.FirestoreAdmin.ListFields], that may be used to get the next
page of results.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse

The response for [FirestoreAdmin.ListFields][google.firestore.admin.v1beta2.FirestoreAdmin.ListFields].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Field::Field>)

The requested fields.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A page token that may be used to request another page of results. If blank,
this is the last page.

=back

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest

The request for [FirestoreAdmin.ExportDocuments][google.firestore.admin.v1beta2.FirestoreAdmin.ExportDocuments].

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

=head2 Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest

The request for [FirestoreAdmin.ImportDocuments][google.firestore.admin.v1beta2.FirestoreAdmin.ImportDocuments].

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
[google.firestore.admin.v1beta2.ExportDocumentsResponse.output_uri_prefix][google.firestore.admin.v1beta2.ExportDocumentsResponse.output_uri_prefix].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta2::FirestoreAdmin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
