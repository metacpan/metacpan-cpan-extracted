package Google::Firestore::V1::Document;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvZmlyZXN0b3JlL3YxL2RvY3VtZW50LnByb3RvEhNnb29nbGUuZmlyZXN0b3Jl
LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhxnb29nbGUvcHJvdG9idWYv
c3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhhnb29nbGUv
dHlwZS9sYXRsbmcucHJvdG8isgIKCERvY3VtZW50EhIKBG5hbWUYASABKAlSBG5hbWUSQQoG
ZmllbGRzGAIgAygLMikuZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVudC5GaWVsZHNFbnRy
eVIGZmllbGRzEjsKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUaVQoLRmllbGRzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSMAoFdmFsdWUYAiABKAsyGi5nb29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlUgV2YWx1ZToC
OAEiwgYKBVZhbHVlEjsKCm51bGxfdmFsdWUYCyABKA4yGi5nb29nbGUucHJvdG9idWYuTnVs
bFZhbHVlSABSCW51bGxWYWx1ZRIlCg1ib29sZWFuX3ZhbHVlGAEgASgISABSDGJvb2xlYW5W
YWx1ZRIlCg1pbnRlZ2VyX3ZhbHVlGAIgASgDSABSDGludGVnZXJWYWx1ZRIjCgxkb3VibGVf
dmFsdWUYAyABKAFIAFILZG91YmxlVmFsdWUSRQoPdGltZXN0YW1wX3ZhbHVlGAogASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUg50aW1lc3RhbXBWYWx1ZRIjCgxzdHJpbmdf
dmFsdWUYESABKAlIAFILc3RyaW5nVmFsdWUSIQoLYnl0ZXNfdmFsdWUYEiABKAxIAFIKYnl0
ZXNWYWx1ZRIpCg9yZWZlcmVuY2VfdmFsdWUYBSABKAlIAFIOcmVmZXJlbmNlVmFsdWUSPQoP
Z2VvX3BvaW50X3ZhbHVlGAggASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nSABSDWdlb1BvaW50
VmFsdWUSQgoLYXJyYXlfdmFsdWUYCSABKAsyHy5nb29nbGUuZmlyZXN0b3JlLnYxLkFycmF5
VmFsdWVIAFIKYXJyYXlWYWx1ZRI8CgltYXBfdmFsdWUYBiABKAsyHS5nb29nbGUuZmlyZXN0
b3JlLnYxLk1hcFZhbHVlSABSCG1hcFZhbHVlEjQKFWZpZWxkX3JlZmVyZW5jZV92YWx1ZRgT
IAEoCUgAUhNmaWVsZFJlZmVyZW5jZVZhbHVlEjoKGHZhcmlhYmxlX3JlZmVyZW5jZV92YWx1
ZRgWIAEoCUgAUhZ2YXJpYWJsZVJlZmVyZW5jZVZhbHVlEkYKDmZ1bmN0aW9uX3ZhbHVlGBQg
ASgLMh0uZ29vZ2xlLmZpcmVzdG9yZS52MS5GdW5jdGlvbkgAUg1mdW5jdGlvblZhbHVlEkYK
DnBpcGVsaW5lX3ZhbHVlGBUgASgLMh0uZ29vZ2xlLmZpcmVzdG9yZS52MS5QaXBlbGluZUgA
Ug1waXBlbGluZVZhbHVlQgwKCnZhbHVlX3R5cGUiQAoKQXJyYXlWYWx1ZRIyCgZ2YWx1ZXMY
ASADKAsyGi5nb29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlUgZ2YWx1ZXMipAEKCE1hcFZhbHVl
EkEKBmZpZWxkcxgBIAMoCzIpLmdvb2dsZS5maXJlc3RvcmUudjEuTWFwVmFsdWUuRmllbGRz
RW50cnlSBmZpZWxkcxpVCgtGaWVsZHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIwCgV2YWx1
ZRgCIAEoCzIaLmdvb2dsZS5maXJlc3RvcmUudjEuVmFsdWVSBXZhbHVlOgI4ASL7AQoIRnVu
Y3Rpb24SFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEjMKBGFyZ3MYAiADKAsyGi5nb29nbGUu
ZmlyZXN0b3JlLnYxLlZhbHVlQgPgQQFSBGFyZ3MSSQoHb3B0aW9ucxgDIAMoCzIqLmdvb2ds
ZS5maXJlc3RvcmUudjEuRnVuY3Rpb24uT3B0aW9uc0VudHJ5QgPgQQFSB29wdGlvbnMaVgoM
T3B0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjAKBXZhbHVlGAIgASgLMhouZ29vZ2xl
LmZpcmVzdG9yZS52MS5WYWx1ZVIFdmFsdWU6AjgBIs0CCghQaXBlbGluZRJACgZzdGFnZXMY
ASADKAsyIy5nb29nbGUuZmlyZXN0b3JlLnYxLlBpcGVsaW5lLlN0YWdlQgPgQQJSBnN0YWdl
cxr+AQoFU3RhZ2USFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEjMKBGFyZ3MYAiADKAsyGi5n
b29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlQgPgQQFSBGFyZ3MSTwoHb3B0aW9ucxgDIAMoCzIw
Lmdvb2dsZS5maXJlc3RvcmUudjEuUGlwZWxpbmUuU3RhZ2UuT3B0aW9uc0VudHJ5QgPgQQFS
B29wdGlvbnMaVgoMT3B0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjAKBXZhbHVlGAIg
ASgLMhouZ29vZ2xlLmZpcmVzdG9yZS52MS5WYWx1ZVIFdmFsdWU6AjgBQsUBChdjb20uZ29v
Z2xlLmZpcmVzdG9yZS52MUINRG9jdW1lbnRQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dv
L2ZpcmVzdG9yZS9hcGl2MS9maXJlc3RvcmVwYjtmaXJlc3RvcmVwYqICBEdDRlOqAhlHb29n
bGUuQ2xvdWQuRmlyZXN0b3JlLlYxygIZR29vZ2xlXENsb3VkXEZpcmVzdG9yZVxWMeoCHEdv
b2dsZTo6Q2xvdWQ6OkZpcmVzdG9yZTo6VjFKrT8KBxIFDgD2AQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAmCgkK
AgMCEgMUACkKCQoCAwMSAxUAIgoICgEIEgMXADYKCQoCCCUSAxcANgoICgEIEgMYAFIKCQoC
CAsSAxgAUgoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC4KCQoCCAgSAxoALgoICgEI
EgMbADAKCQoCCAESAxsAMAoICgEIEgMcACIKCQoCCCQSAxwAIgoICgEIEgMdADYKCQoCCCkS
Ax0ANgoICgEIEgMeADUKCQoCCC0SAx4ANQpGCgIEABIEIwBPARo6IEEgRmlyZXN0b3JlIGRv
Y3VtZW50LgoKIE11c3Qgbm90IGV4Y2VlZCAxIE1pQiAtIDQgYnl0ZXMuCgoKCgMEAAESAyMI
EAqJAQoEBAACABIDJgISGnwgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGRvY3VtZW50LCBm
b3IgZXhhbXBsZQogYHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNl
X2lkfS9kb2N1bWVudHMve2RvY3VtZW50X3BhdGh9YC4KCgwKBQQAAgAFEgMmAggKDAoFBAAC
AAESAyYJDQoMCgUEAAIAAxIDJhARCuQICgQEAAIBEgNAAiAa1gggVGhlIGRvY3VtZW50J3Mg
ZmllbGRzLgoKIFRoZSBtYXAga2V5cyByZXByZXNlbnQgZmllbGQgbmFtZXMuCgogRmllbGQg
bmFtZXMgbWF0Y2hpbmcgdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbiBgX18uKl9fYCBhcmUgcmVz
ZXJ2ZWQuIFJlc2VydmVkCiBmaWVsZCBuYW1lcyBhcmUgZm9yYmlkZGVuIGV4Y2VwdCBpbiBj
ZXJ0YWluIGRvY3VtZW50ZWQgY29udGV4dHMuIFRoZSBmaWVsZAogbmFtZXMsIHJlcHJlc2Vu
dGVkIGFzIFVURi04LCBtdXN0IG5vdCBleGNlZWQgMSw1MDAgYnl0ZXMgYW5kIGNhbm5vdCBi
ZQogZW1wdHkuCgogRmllbGQgcGF0aHMgbWF5IGJlIHVzZWQgaW4gb3RoZXIgY29udGV4dHMg
dG8gcmVmZXIgdG8gc3RydWN0dXJlZCBmaWVsZHMKIGRlZmluZWQgaGVyZS4gRm9yIGBtYXBf
dmFsdWVgLCB0aGUgZmllbGQgcGF0aCBpcyByZXByZXNlbnRlZCBieSBhCiBkb3QtZGVsaW1p
dGVkIChgLmApIHN0cmluZyBvZiBzZWdtZW50cy4gRWFjaCBzZWdtZW50IGlzIGVpdGhlciBh
IHNpbXBsZQogZmllbGQgbmFtZSAoZGVmaW5lZCBiZWxvdykgb3IgYSBxdW90ZWQgZmllbGQg
bmFtZS4gRm9yIGV4YW1wbGUsIHRoZQogc3RydWN0dXJlZCBmaWVsZCBgImZvbyIgOiB7IG1h
cF92YWx1ZTogeyAieCZ5IiA6IHsgc3RyaW5nX3ZhbHVlOiAiaGVsbG8iCiB9fX1gIHdvdWxk
IGJlIHJlcHJlc2VudGVkIGJ5IHRoZSBmaWVsZCBwYXRoIGBgIGZvby5geCZ5YCBgYC4KCiBB
IHNpbXBsZSBmaWVsZCBuYW1lIGNvbnRhaW5zIG9ubHkgY2hhcmFjdGVycyBgYWAgdG8gYHpg
LCBgQWAgdG8gYFpgLAogYDBgIHRvIGA5YCwgb3IgYF9gLCBhbmQgbXVzdCBub3Qgc3RhcnQg
d2l0aCBgMGAgdG8gYDlgLiBGb3IgZXhhbXBsZSwKIGBmb29fYmFyXzE3YC4KCiBBIHF1b3Rl
ZCBmaWVsZCBuYW1lIHN0YXJ0cyBhbmQgZW5kcyB3aXRoIGBgIGAgYGAgYW5kCiBtYXkgY29u
dGFpbiBhbnkgY2hhcmFjdGVyLiBTb21lIGNoYXJhY3RlcnMsIGluY2x1ZGluZyBgYCBgIGBg
LCBtdXN0IGJlCiBlc2NhcGVkIHVzaW5nIGEgYFxgLiBGb3IgZXhhbXBsZSwgYGAgYHgmeWAg
YGAgcmVwcmVzZW50cyBgeCZ5YCBhbmQKIGBgIGBiYWtcYHRpa2AgYGAgcmVwcmVzZW50cyBg
YCBiYWtgdGlrIGBgLgoKDAoFBAACAQYSA0ACFAoMCgUEAAIBARIDQBUbCgwKBQQAAgEDEgNA
Hh8K8QEKBAQAAgISA0cCLBrjASBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhl
IGRvY3VtZW50IHdhcyBjcmVhdGVkLgoKIFRoaXMgdmFsdWUgaW5jcmVhc2VzIG1vbm90b25p
Y2FsbHkgd2hlbiBhIGRvY3VtZW50IGlzIGRlbGV0ZWQgdGhlbgogcmVjcmVhdGVkLiBJdCBj
YW4gYWxzbyBiZSBjb21wYXJlZCB0byB2YWx1ZXMgZnJvbSBvdGhlciBkb2N1bWVudHMgYW5k
CiB0aGUgYHJlYWRfdGltZWAgb2YgYSBxdWVyeS4KCgwKBQQAAgIGEgNHAhsKDAoFBAACAgES
A0ccJwoMCgUEAAICAxIDRyorCpgCCgQEAAIDEgNOAiwaigIgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIGF0IHdoaWNoIHRoZSBkb2N1bWVudCB3YXMgbGFzdCBjaGFuZ2VkLgoKIFRoaXMgdmFs
dWUgaXMgaW5pdGlhbGx5IHNldCB0byB0aGUgYGNyZWF0ZV90aW1lYCB0aGVuIGluY3JlYXNl
cwogbW9ub3RvbmljYWxseSB3aXRoIGVhY2ggY2hhbmdlIHRvIHRoZSBkb2N1bWVudC4gSXQg
Y2FuIGFsc28gYmUKIGNvbXBhcmVkIHRvIHZhbHVlcyBmcm9tIG90aGVyIGRvY3VtZW50cyBh
bmQgdGhlIGByZWFkX3RpbWVgIG9mIGEgcXVlcnkuCgoMCgUEAAIDBhIDTgIbCgwKBQQAAgMB
EgNOHCcKDAoFBAACAwMSA04qKwpICgIEARIFUgClAQEaOyBBIG1lc3NhZ2UgdGhhdCBjYW4g
aG9sZCBhbnkgb2YgdGhlIHN1cHBvcnRlZCB2YWx1ZSB0eXBlcy4KCgoKAwQBARIDUggNCicK
BAQBCAASBVQCpAEDGhggTXVzdCBoYXZlIGEgdmFsdWUgc2V0LgoKDAoFBAEIAAESA1QIEgoc
CgQEAQIAEgNWBC4aDyBBIG51bGwgdmFsdWUuCgoMCgUEAQIABhIDVgQdCgwKBQQBAgABEgNW
HigKDAoFBAECAAMSA1YrLQofCgQEAQIBEgNZBBsaEiBBIGJvb2xlYW4gdmFsdWUuCgoMCgUE
AQIBBRIDWQQICgwKBQQBAgEBEgNZCRYKDAoFBAECAQMSA1kZGgogCgQEAQICEgNcBBwaEyBB
biBpbnRlZ2VyIHZhbHVlLgoKDAoFBAECAgUSA1wECQoMCgUEAQICARIDXAoXCgwKBQQBAgID
EgNcGhsKHgoEBAECAxIDXwQcGhEgQSBkb3VibGUgdmFsdWUuCgoMCgUEAQIDBRIDXwQKCgwK
BQQBAgMBEgNfCxcKDAoFBAECAwMSA18aGwp5CgQEAQIEEgNlBDMabCBBIHRpbWVzdGFtcCB2
YWx1ZS4KCiBQcmVjaXNlIG9ubHkgdG8gbWljcm9zZWNvbmRzLiBXaGVuIHN0b3JlZCwgYW55
IGFkZGl0aW9uYWwgcHJlY2lzaW9uIGlzCiByb3VuZGVkIGRvd24uCgoMCgUEAQIEBhIDZQQd
CgwKBQQBAgQBEgNlHi0KDAoFBAECBAMSA2UwMgq5AQoEBAECBRIDbAQdGqsBIEEgc3RyaW5n
IHZhbHVlLgoKIFRoZSBzdHJpbmcsIHJlcHJlc2VudGVkIGFzIFVURi04LCBtdXN0IG5vdCBl
eGNlZWQgMSBNaUIgLSA4OSBieXRlcy4KIE9ubHkgdGhlIGZpcnN0IDEsNTAwIGJ5dGVzIG9m
IHRoZSBVVEYtOCByZXByZXNlbnRhdGlvbiBhcmUgY29uc2lkZXJlZCBieQogcXVlcmllcy4K
CgwKBQQBAgUFEgNsBAoKDAoFBAECBQESA2wLFwoMCgUEAQIFAxIDbBocCngKBAQBAgYSA3IE
GxprIEEgYnl0ZXMgdmFsdWUuCgogTXVzdCBub3QgZXhjZWVkIDEgTWlCIC0gODkgYnl0ZXMu
CiBPbmx5IHRoZSBmaXJzdCAxLDUwMCBieXRlcyBhcmUgY29uc2lkZXJlZCBieSBxdWVyaWVz
LgoKDAoFBAECBgUSA3IECQoMCgUEAQIGARIDcgoVCgwKBQQBAgYDEgNyGBoKggEKBAQBAgcS
A3YEHxp1IEEgcmVmZXJlbmNlIHRvIGEgZG9jdW1lbnQuIEZvciBleGFtcGxlOgogYHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfS9kb2N1bWVudHMve2Rv
Y3VtZW50X3BhdGh9YC4KCgwKBQQBAgcFEgN2BAoKDAoFBAECBwESA3YLGgoMCgUEAQIHAxID
dh0eCk4KBAQBAggSA3kEKxpBIEEgZ2VvIHBvaW50IHZhbHVlIHJlcHJlc2VudGluZyBhIHBv
aW50IG9uIHRoZSBzdXJmYWNlIG9mIEVhcnRoLgoKDAoFBAECCAYSA3kEFgoMCgUEAQIIARID
eRcmCgwKBQQBAggDEgN5KSoKhQEKBAQBAgkSA38EHxp4IEFuIGFycmF5IHZhbHVlLgoKIENh
bm5vdCBkaXJlY3RseSBjb250YWluIGFub3RoZXIgYXJyYXkgdmFsdWUsIHRob3VnaCBjYW4g
Y29udGFpbiBhCiBtYXAgd2hpY2ggY29udGFpbnMgYW5vdGhlciBhcnJheS4KCgwKBQQBAgkG
EgN/BA4KDAoFBAECCQESA38PGgoMCgUEAQIJAxIDfx0eChwKBAQBAgoSBIIBBBsaDiBBIG1h
cCB2YWx1ZS4KCg0KBQQBAgoGEgSCAQQMCg0KBQQBAgoBEgSCAQ0WCg0KBQQBAgoDEgSCARka
CrgCCgQEAQILEgSOAQQmGqkCIFZhbHVlIHdoaWNoIHJlZmVyZW5jZXMgYSBmaWVsZC4KCiBU
aGlzIGlzIGNvbnNpZGVyZWQgcmVsYXRpdmUgKHZzIGFic29sdXRlKSBzaW5jZSBpdCBvbmx5
IHJlZmVycyB0byBhIGZpZWxkCiBhbmQgbm90IGEgZmllbGQgd2l0aGluIGEgcGFydGljdWxh
ciBkb2N1bWVudC4KCiAqKlJlcXVpcmVzOioqCgogKiBNdXN0IGZvbGxvdyBbZmllbGQgcmVm
ZXJlbmNlXVtGaWVsZFJlZmVyZW5jZS5maWVsZF9wYXRoXSBsaW1pdGF0aW9ucy4KCiAqIE5v
dCBhbGxvd2VkIHRvIGJlIHVzZWQgd2hlbiB3cml0aW5nIGRvY3VtZW50cy4KCg0KBQQBAgsF
EgSOAQQKCg0KBQQBAgsBEgSOAQsgCg0KBQQBAgsDEgSOASMlCvABCgQEAQIMEgSVAQQpGuEB
IFBvaW50ZXIgdG8gYSB2YXJpYWJsZSBkZWZpbmVkIGVsc2V3aGVyZSBpbiBhIHBpcGVsaW5l
LgoKIFVubGlrZSBgZmllbGRfcmVmZXJlbmNlX3ZhbHVlYCB3aGljaCByZWZlcmVuY2VzIGEg
ZmllbGQgd2l0aGluIGEKIGRvY3VtZW50LCB0aGlzIHJlZmVycyB0byBhIHZhcmlhYmxlLCBk
ZWZpbmVkIGluIGEgc2VwYXJhdGUgbmFtZXNwYWNlIHRoYW4KIHRoZSBmaWVsZHMgb2YgYSBk
b2N1bWVudC4KCg0KBQQBAgwFEgSVAQQKCg0KBQQBAgwBEgSVAQsjCg0KBQQBAgwDEgSVASYo
CoUBCgQEAQINEgScAQQhGncgQSB2YWx1ZSB0aGF0IHJlcHJlc2VudHMgYW4gdW5ldmFsdWF0
ZWQgZXhwcmVzc2lvbi4KCiAqKlJlcXVpcmVzOioqCgogKiBOb3QgYWxsb3dlZCB0byBiZSB1
c2VkIHdoZW4gd3JpdGluZyBkb2N1bWVudHMuCgoNCgUEAQINBhIEnAEEDAoNCgUEAQINARIE
nAENGwoNCgUEAQINAxIEnAEeIAqDAQoEBAECDhIEowEEIRp1IEEgdmFsdWUgdGhhdCByZXBy
ZXNlbnRzIGFuIHVuZXZhbHVhdGVkIHBpcGVsaW5lLgoKICoqUmVxdWlyZXM6KioKCiAqIE5v
dCBhbGxvd2VkIHRvIGJlIHVzZWQgd2hlbiB3cml0aW5nIGRvY3VtZW50cy4KCg0KBQQBAg4G
EgSjAQQMCg0KBQQBAg4BEgSjAQ0bCg0KBQQBAg4DEgSjAR4gCh8KAgQCEgaoAQCrAQEaESBB
biBhcnJheSB2YWx1ZS4KCgsKAwQCARIEqAEIEgokCgQEAgIAEgSqAQIcGhYgVmFsdWVzIGlu
IHRoZSBhcnJheS4KCg0KBQQCAgAEEgSqAQIKCg0KBQQCAgAGEgSqAQsQCg0KBQQCAgABEgSq
AREXCg0KBQQCAgADEgSqARobChwKAgQDEgauAQC2AQEaDiBBIG1hcCB2YWx1ZS4KCgsKAwQD
ARIErgEIEAqtAgoEBAMCABIEtQECIBqeAiBUaGUgbWFwJ3MgZmllbGRzLgoKIFRoZSBtYXAg
a2V5cyByZXByZXNlbnQgZmllbGQgbmFtZXMuIEZpZWxkIG5hbWVzIG1hdGNoaW5nIHRoZSBy
ZWd1bGFyCiBleHByZXNzaW9uIGBfXy4qX19gIGFyZSByZXNlcnZlZC4gUmVzZXJ2ZWQgZmll
bGQgbmFtZXMgYXJlIGZvcmJpZGRlbiBleGNlcHQKIGluIGNlcnRhaW4gZG9jdW1lbnRlZCBj
b250ZXh0cy4gVGhlIG1hcCBrZXlzLCByZXByZXNlbnRlZCBhcyBVVEYtOCwgbXVzdAogbm90
IGV4Y2VlZCAxLDUwMCBieXRlcyBhbmQgY2Fubm90IGJlIGVtcHR5LgoKDQoFBAMCAAYSBLUB
AhQKDQoFBAMCAAESBLUBFRsKDQoFBAMCAAMSBLUBHh8K7QEKAgQEEgbBAQDOAQEa3gEgUmVw
cmVzZW50cyBhbiB1bmV2YWx1YXRlZCBzY2FsYXIgZXhwcmVzc2lvbi4KCiBGb3IgZXhhbXBs
ZSwgdGhlIGV4cHJlc3Npb24gYGxpa2UodXNlcl9uYW1lLCAiJWFsaWNlJSIpYCBpcyByZXBy
ZXNlbnRlZCBhczoKCiBgYGAKIG5hbWU6ICJsaWtlIgogYXJncyB7IGZpZWxkX3JlZmVyZW5j
ZTogInVzZXJfbmFtZSIgfQogYXJncyB7IHN0cmluZ192YWx1ZTogIiVhbGljZSUiIH0KIGBg
YAoKCwoDBAQBEgTBAQgQCpIBCgQEBAIAEgTHAQI7GoMBIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgZnVuY3Rpb24gdG8gZXZhbHVhdGUuCgogKipSZXF1aXJlczoqKgoKICogbXVzdCBi
ZSBpbiBzbmFrZSBjYXNlIChsb3dlciBjYXNlIHdpdGggdW5kZXJzY29yZSBzZXBhcmF0b3Ip
LgoKDQoFBAQCAAUSBMcBAggKDQoFBAQCAAESBMcBCQ0KDQoFBAQCAAMSBMcBEBEKDQoFBAQC
AAgSBMcBEjoKEAoIBAQCAAicCAASBMcBEzkKTwoEBAQCARIEygECQxpBIE9wdGlvbmFsLiBP
cmRlcmVkIGxpc3Qgb2YgYXJndW1lbnRzIHRoZSBnaXZlbiBmdW5jdGlvbiBleHBlY3RzLgoK
DQoFBAQCAQQSBMoBAgoKDQoFBAQCAQYSBMoBCxAKDQoFBAQCAQESBMoBERUKDQoFBAQCAQMS
BMoBGBkKDQoFBAQCAQgSBMoBGkIKEAoIBAQCAQicCAASBMoBG0EKVgoEBAQCAhIEzQECShpI
IE9wdGlvbmFsLiBPcHRpb25hbCBuYW1lZCBhcmd1bWVudHMgdGhhdCBjZXJ0YWluIGZ1bmN0
aW9ucyBtYXkgc3VwcG9ydC4KCg0KBQQEAgIGEgTNAQIUCg0KBQQEAgIBEgTNARUcCg0KBQQE
AgIDEgTNAR8gCg0KBQQEAgIIEgTNASFJChAKCAQEAgIInAgAEgTNASJIClgKAgQFEgbRAQD2
AQEaSiBBIEZpcmVzdG9yZSBxdWVyeSByZXByZXNlbnRlZCBhcyBhbiBvcmRlcmVkIGxpc3Qg
b2Ygb3BlcmF0aW9ucyAvIHN0YWdlcy4KCgsKAwQFARIE0QEIEArWAwoEBAUDABIG5QEC8gED
GsUDIEEgc2luZ2xlIG9wZXJhdGlvbiB3aXRoaW4gYSBwaXBlbGluZS4KCiBBIHN0YWdlIGlz
IG1hZGUgdXAgb2YgYSB1bmlxdWUgbmFtZSwgYW5kIGEgbGlzdCBvZiBhcmd1bWVudHMuIFRo
ZSBleGFjdAogbnVtYmVyIG9mIGFyZ3VtZW50cyAmIHR5cGVzIGlzIGRlcGVuZGVudCBvbiB0
aGUgc3RhZ2UgdHlwZS4KCiBUbyBnaXZlIGFuIGV4YW1wbGUsIHRoZSBzdGFnZSBgZmlsdGVy
KHN0YXRlID0gIk1EIilgIHdvdWxkIGJlIGVuY29kZWQgYXM6CgogYGBgCiBuYW1lOiAiZmls
dGVyIgogYXJncyB7CiAgIGZ1bmN0aW9uX3ZhbHVlIHsKICAgICBuYW1lOiAiZXEiCiAgICAg
YXJncyB7IGZpZWxkX3JlZmVyZW5jZV92YWx1ZTogInN0YXRlIiB9CiAgICAgYXJncyB7IHN0
cmluZ192YWx1ZTogIk1EIiB9CiAgIH0KIH0KIGBgYAoKIFNlZSBwdWJsaWMgZG9jdW1lbnRh
dGlvbiBmb3IgdGhlIGZ1bGwgbGlzdC4KCg0KBQQFAwABEgTlAQoPCpEBCgYEBQMAAgASBOsB
BD0agAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzdGFnZSB0byBldmFsdWF0ZS4KCiAq
KlJlcXVpcmVzOioqCgogKiBtdXN0IGJlIGluIHNuYWtlIGNhc2UgKGxvd2VyIGNhc2Ugd2l0
aCB1bmRlcnNjb3JlIHNlcGFyYXRvcikuCgoPCgcEBQMAAgAFEgTrAQQKCg8KBwQFAwACAAES
BOsBCw8KDwoHBAUDAAIAAxIE6wESEwoPCgcEBQMAAgAIEgTrARQ8ChIKCgQFAwACAAicCAAS
BOsBFTsKTgoGBAUDAAIBEgTuAQRFGj4gT3B0aW9uYWwuIE9yZGVyZWQgbGlzdCBvZiBhcmd1
bWVudHMgdGhlIGdpdmVuIHN0YWdlIGV4cGVjdHMuCgoPCgcEBQMAAgEEEgTuAQQMCg8KBwQF
AwACAQYSBO4BDRIKDwoHBAUDAAIBARIE7gETFwoPCgcEBQMAAgEDEgTuARobCg8KBwQFAwAC
AQgSBO4BHEQKEgoKBAUDAAIBCJwIABIE7gEdQwpYCgYEBQMAAgISBPEBBEwaSCBPcHRpb25h
bC4gT3B0aW9uYWwgbmFtZWQgYXJndW1lbnRzIHRoYXQgY2VydGFpbiBmdW5jdGlvbnMgbWF5
IHN1cHBvcnQuCgoPCgcEBQMAAgIGEgTxAQQWCg8KBwQFAwACAgESBPEBFx4KDwoHBAUDAAIC
AxIE8QEhIgoPCgcEBQMAAgIIEgTxASNLChIKCgQFAwACAgicCAASBPEBJEoKPQoEBAUCABIE
9QECRRovIFJlcXVpcmVkLiBPcmRlcmVkIGxpc3Qgb2Ygc3RhZ2VzIHRvIGV2YWx1YXRlLgoK
DQoFBAUCAAQSBPUBAgoKDQoFBAUCAAYSBPUBCxAKDQoFBAUCAAESBPUBERcKDQoFBAUCAAMS
BPUBGhsKDQoFBAUCAAgSBPUBHEQKEAoIBAUCAAicCAASBPUBHUNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::Document::Document ===
    # Fields for Document
    # Field: name Type: 9 ()
    # Field: fields Type: 11 (.google.firestore.v1.Document.FieldsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1::Document::Value ===
    # Fields for Value
    # Field: null_value Type: 14 (.google.protobuf.NullValue)
    # Field: boolean_value Type: 8 ()
    # Field: integer_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: string_value Type: 9 ()
    # Field: bytes_value Type: 12 ()
    # Field: reference_value Type: 9 ()
    # Field: geo_point_value Type: 11 (.google.type.LatLng)
    # Field: array_value Type: 11 (.google.firestore.v1.ArrayValue)
    # Field: map_value Type: 11 (.google.firestore.v1.MapValue)
    # Field: field_reference_value Type: 9 ()
    # Field: variable_reference_value Type: 9 ()
    # Field: function_value Type: 11 (.google.firestore.v1.Function)
    # Field: pipeline_value Type: 11 (.google.firestore.v1.Pipeline)

# === Message: Google::Firestore::V1::Document::ArrayValue ===
    # Fields for ArrayValue
    # Field: values Type: 11 (.google.firestore.v1.Value)

# === Message: Google::Firestore::V1::Document::MapValue ===
    # Fields for MapValue
    # Field: fields Type: 11 (.google.firestore.v1.MapValue.FieldsEntry)

# === Message: Google::Firestore::V1::Document::Function ===
    # Fields for Function
    # Field: name Type: 9 ()
    # Field: args Type: 11 (.google.firestore.v1.Value)
    # Field: options Type: 11 (.google.firestore.v1.Function.OptionsEntry)

# === Message: Google::Firestore::V1::Document::Pipeline ===
    # Fields for Pipeline
    # Field: stages Type: 11 (.google.firestore.v1.Pipeline.Stage)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::Document - Compiled Protocol Buffers messages for google/firestore/v1/document.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::Document;

    my $msg = Google::Firestore::V1::Document::Document->new({
        name => $name,
        fields => $fields,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::Document::Document->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/document.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::Document::Document

A Firestore document.

Must not exceed 1 MiB - 4 bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the document, for example
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Document::FieldsEntry>)

The document's fields.

The map keys represent field names.

Field names matching the regular expression `__.*__` are reserved. Reserved
field names are forbidden except in certain documented contexts. The field
names, represented as UTF-8, must not exceed 1,500 bytes and cannot be
empty.

Field paths may be used in other contexts to refer to structured fields
defined here. For `map_value`, the field path is represented by a
dot-delimited (`.`) string of segments. Each segment is either a simple
field name (defined below) or a quoted field name. For example, the
structured field `"foo" : { map_value: { "x&y" : { string_value: "hello"
}}}` would be represented by the field path `` foo.`x&y` ``.

A simple field name contains only characters `a` to `z`, `A` to `Z`,
`0` to `9`, or `_`, and must not start with `0` to `9`. For example,
`foo_bar_17`.

A quoted field name starts and ends with `` ` `` and
may contain any character. Some characters, including `` ` ``, must be
escaped using a `\`. For example, `` `x&y` `` represents `x&y` and
`` `bak\`tik` `` represents `` bak`tik ``.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the document was created.

This value increases monotonically when a document is deleted then
recreated. It can also be compared to values from other documents and
the `read_time` of a query.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the document was last changed.

This value is initially set to the `create_time` then increases
monotonically with each change to the document. It can also be
compared to values from other documents and the `read_time` of a query.

=back

=head2 Google::Firestore::V1::Document::Value

A message that can hold any of the supported value types.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->null_value() >> / C<< $msg->null_value($value) >>

Type: C<Enum> (L<Google::Protobuf::NullValue>)

A null value.

=item * C<< $msg->boolean_value() >> / C<< $msg->boolean_value($value) >>

Type: C<Bool>

A boolean value.

=item * C<< $msg->integer_value() >> / C<< $msg->integer_value($value) >>

Type: C<Int64>

An integer value.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

A double value.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

A timestamp value.

Precise only to microseconds. When stored, any additional precision is
rounded down.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A string value.

The string, represented as UTF-8, must not exceed 1 MiB - 89 bytes.
Only the first 1,500 bytes of the UTF-8 representation are considered by
queries.

=item * C<< $msg->bytes_value() >> / C<< $msg->bytes_value($value) >>

Type: C<Bytes>

A bytes value.

Must not exceed 1 MiB - 89 bytes.
Only the first 1,500 bytes are considered by queries.

=item * C<< $msg->reference_value() >> / C<< $msg->reference_value($value) >>

Type: C<String>

A reference to a document. For example:
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->geo_point_value() >> / C<< $msg->geo_point_value($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

A geo point value representing a point on the surface of Earth.

=item * C<< $msg->array_value() >> / C<< $msg->array_value($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::ArrayValue>)

An array value.

Cannot directly contain another array value, though can contain a
map which contains another array.

=item * C<< $msg->map_value() >> / C<< $msg->map_value($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::MapValue>)

A map value.

=item * C<< $msg->field_reference_value() >> / C<< $msg->field_reference_value($value) >>

Type: C<String>

Value which references a field.

This is considered relative (vs absolute) since it only refers to a field
and not a field within a particular document.

B<Requires:>

* Must follow [field reference][FieldReference.field_path] limitations.

* Not allowed to be used when writing documents.

=item * C<< $msg->variable_reference_value() >> / C<< $msg->variable_reference_value($value) >>

Type: C<String>

Pointer to a variable defined elsewhere in a pipeline.

Unlike `field_reference_value` which references a field within a
document, this refers to a variable, defined in a separate namespace than
the fields of a document.

=item * C<< $msg->function_value() >> / C<< $msg->function_value($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Function>)

A value that represents an unevaluated expression.

B<Requires:>

* Not allowed to be used when writing documents.

=item * C<< $msg->pipeline_value() >> / C<< $msg->pipeline_value($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Pipeline>)

A value that represents an unevaluated pipeline.

B<Requires:>

* Not allowed to be used when writing documents.

=back

=head2 Google::Firestore::V1::Document::ArrayValue

An array value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Value>)

Values in the array.

=back

=head2 Google::Firestore::V1::Document::MapValue

A map value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::MapValue::FieldsEntry>)

The map's fields.

The map keys represent field names. Field names matching the regular
expression `__.*__` are reserved. Reserved field names are forbidden except
in certain documented contexts. The map keys, represented as UTF-8, must
not exceed 1,500 bytes and cannot be empty.

=back

=head2 Google::Firestore::V1::Document::Function

Represents an unevaluated scalar expression.

For example, the expression `like(user_name, "%alice%")` is represented as:

```
name: "like"
args { field_reference: "user_name" }
args { string_value: "%alice%" }
```

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the function to evaluate.

B<Requires:>

* must be in snake case (lower case with underscore separator).

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Value>)

Optional. Ordered list of arguments the given function expects.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Function::OptionsEntry>)

Optional. Optional named arguments that certain functions may support.

=back

=head2 Google::Firestore::V1::Document::Pipeline

A Firestore query represented as an ordered list of operations / stages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stages() >> / C<< $msg->stages($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Pipeline::Stage>)

Required. Ordered list of stages to evaluate.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::Document::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
