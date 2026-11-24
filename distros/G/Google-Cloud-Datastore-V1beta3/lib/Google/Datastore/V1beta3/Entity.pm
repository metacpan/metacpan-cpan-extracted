package Google::Datastore::V1beta3::Entity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvZGF0YXN0b3JlL3YxYmV0YTMvZW50aXR5LnByb3RvEhhnb29nbGUuZGF0YXN0
b3JlLnYxYmV0YTMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aHGdvb2dsZS9wcm90
b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aGGdv
b2dsZS90eXBlL2xhdGxuZy5wcm90byJPCgtQYXJ0aXRpb25JZBIdCgpwcm9qZWN0X2lkGAIg
ASgJUglwcm9qZWN0SWQSIQoMbmFtZXNwYWNlX2lkGAQgASgJUgtuYW1lc3BhY2VJZCLkAQoD
S2V5EkgKDHBhcnRpdGlvbl9pZBgBIAEoCzIlLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5Q
YXJ0aXRpb25JZFILcGFydGl0aW9uSWQSPQoEcGF0aBgCIAMoCzIpLmdvb2dsZS5kYXRhc3Rv
cmUudjFiZXRhMy5LZXkuUGF0aEVsZW1lbnRSBHBhdGgaVAoLUGF0aEVsZW1lbnQSEgoEa2lu
ZBgBIAEoCVIEa2luZBIQCgJpZBgCIAEoA0gAUgJpZBIUCgRuYW1lGAMgASgJSABSBG5hbWVC
CQoHaWRfdHlwZSJFCgpBcnJheVZhbHVlEjcKBnZhbHVlcxgBIAMoCzIfLmdvb2dsZS5kYXRh
c3RvcmUudjFiZXRhMy5WYWx1ZVIGdmFsdWVzIqsFCgVWYWx1ZRI7CgpudWxsX3ZhbHVlGAsg
ASgOMhouZ29vZ2xlLnByb3RvYnVmLk51bGxWYWx1ZUgAUgludWxsVmFsdWUSJQoNYm9vbGVh
bl92YWx1ZRgBIAEoCEgAUgxib29sZWFuVmFsdWUSJQoNaW50ZWdlcl92YWx1ZRgCIAEoA0gA
UgxpbnRlZ2VyVmFsdWUSIwoMZG91YmxlX3ZhbHVlGAMgASgBSABSC2RvdWJsZVZhbHVlEkUK
D3RpbWVzdGFtcF92YWx1ZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFIO
dGltZXN0YW1wVmFsdWUSPAoJa2V5X3ZhbHVlGAUgASgLMh0uZ29vZ2xlLmRhdGFzdG9yZS52
MWJldGEzLktleUgAUghrZXlWYWx1ZRIjCgxzdHJpbmdfdmFsdWUYESABKAlIAFILc3RyaW5n
VmFsdWUSHwoKYmxvYl92YWx1ZRgSIAEoDEgAUglibG9iVmFsdWUSPQoPZ2VvX3BvaW50X3Zh
bHVlGAggASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nSABSDWdlb1BvaW50VmFsdWUSRQoMZW50
aXR5X3ZhbHVlGAYgASgLMiAuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkVudGl0eUgAUgtl
bnRpdHlWYWx1ZRJHCgthcnJheV92YWx1ZRgJIAEoCzIkLmdvb2dsZS5kYXRhc3RvcmUudjFi
ZXRhMy5BcnJheVZhbHVlSABSCmFycmF5VmFsdWUSGAoHbWVhbmluZxgOIAEoBVIHbWVhbmlu
ZxIwChRleGNsdWRlX2Zyb21faW5kZXhlcxgTIAEoCFISZXhjbHVkZUZyb21JbmRleGVzQgwK
CnZhbHVlX3R5cGUi6wEKBkVudGl0eRIvCgNrZXkYASABKAsyHS5nb29nbGUuZGF0YXN0b3Jl
LnYxYmV0YTMuS2V5UgNrZXkSUAoKcHJvcGVydGllcxgDIAMoCzIwLmdvb2dsZS5kYXRhc3Rv
cmUudjFiZXRhMy5FbnRpdHkuUHJvcGVydGllc0VudHJ5Ugpwcm9wZXJ0aWVzGl4KD1Byb3Bl
cnRpZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI1CgV2YWx1ZRgCIAEoCzIfLmdvb2dsZS5k
YXRhc3RvcmUudjFiZXRhMy5WYWx1ZVIFdmFsdWU6AjgBQtUBChxjb20uZ29vZ2xlLmRhdGFz
dG9yZS52MWJldGEzQgtFbnRpdHlQcm90b1ABWkBjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFz
dG9yZS9hcGl2MWJldGEzL2RhdGFzdG9yZXBiO2RhdGFzdG9yZXBiqgIeR29vZ2xlLkNsb3Vk
LkRhdGFzdG9yZS5WMUJldGEzygIeR29vZ2xlXENsb3VkXERhdGFzdG9yZVxWMWJldGEz6gIh
R29vZ2xlOjpDbG91ZDo6RGF0YXN0b3JlOjpWMWJldGEzSuM3CgcSBQ4AzAEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACYKCQoCAwES
AxMAJgoJCgIDAhIDFAApCgkKAgMDEgMVACIKCAoBCBIDFwA7CgkKAgglEgMXADsKCAoBCBID
GABXCgkKAggLEgMYAFcKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAsCgkKAggIEgMa
ACwKCAoBCBIDGwA1CgkKAggBEgMbADUKCAoBCBIDHAA7CgkKAggpEgMcADsKCAoBCBIDHQA6
CgkKAggtEgMdADoK4gUKAgQAEgQzADkBGtUFIEEgcGFydGl0aW9uIElEIGlkZW50aWZpZXMg
YSBncm91cGluZyBvZiBlbnRpdGllcy4gVGhlIGdyb3VwaW5nIGlzIGFsd2F5cwogYnkgcHJv
amVjdCBhbmQgbmFtZXNwYWNlLCBob3dldmVyIHRoZSBuYW1lc3BhY2UgSUQgbWF5IGJlIGVt
cHR5LgoKIEEgcGFydGl0aW9uIElEIGNvbnRhaW5zIHNldmVyYWwgZGltZW5zaW9uczoKIHBy
b2plY3QgSUQgYW5kIG5hbWVzcGFjZSBJRC4KCiBQYXJ0aXRpb24gZGltZW5zaW9uczoKCiAt
IE1heSBiZSBgIiJgLgogLSBNdXN0IGJlIHZhbGlkIFVURi04IGJ5dGVzLgogLSBNdXN0IGhh
dmUgdmFsdWVzIHRoYXQgbWF0Y2ggcmVnZXggYFtBLVphLXpcZFwuXC1fXXsxLDEwMH1gCiBJ
ZiB0aGUgdmFsdWUgb2YgYW55IGRpbWVuc2lvbiBtYXRjaGVzIHJlZ2V4IGBfXy4qX19gLCB0
aGUgcGFydGl0aW9uIGlzCiByZXNlcnZlZC9yZWFkLW9ubHkuCiBBIHJlc2VydmVkL3JlYWQt
b25seSBwYXJ0aXRpb24gSUQgaXMgZm9yYmlkZGVuIGluIGNlcnRhaW4gZG9jdW1lbnRlZAog
Y29udGV4dHMuCgogRm9yZWlnbiBwYXJ0aXRpb24gSURzIChpbiB3aGljaCB0aGUgcHJvamVj
dCBJRCBkb2VzCiBub3QgbWF0Y2ggdGhlIGNvbnRleHQgcHJvamVjdCBJRCApIGFyZSBkaXNj
b3VyYWdlZC4KIFJlYWRzIGFuZCB3cml0ZXMgb2YgZm9yZWlnbiBwYXJ0aXRpb24gSURzIG1h
eSBmYWlsIGlmIHRoZSBwcm9qZWN0IGlzIG5vdCBpbgogYW4gYWN0aXZlIHN0YXRlLgoKCgoD
BAABEgMzCBMKQgoEBAACABIDNQIYGjUgVGhlIElEIG9mIHRoZSBwcm9qZWN0IHRvIHdoaWNo
IHRoZSBlbnRpdGllcyBiZWxvbmcuCgoMCgUEAAIABRIDNQIICgwKBQQAAgABEgM1CRMKDAoF
BAACAAMSAzUWFwpSCgQEAAIBEgM4AhoaRSBJZiBub3QgZW1wdHksIHRoZSBJRCBvZiB0aGUg
bmFtZXNwYWNlIHRvIHdoaWNoIHRoZSBlbnRpdGllcyBiZWxvbmcuCgoMCgUEAAIBBRIDOAII
CgwKBQQAAgEBEgM4CRUKDAoFBAACAQMSAzgYGQrrAQoCBAESBD8AcAEa3gEgQSB1bmlxdWUg
aWRlbnRpZmllciBmb3IgYW4gZW50aXR5LgogSWYgYSBrZXkncyBwYXJ0aXRpb24gSUQgb3Ig
YW55IG9mIGl0cyBwYXRoIGtpbmRzIG9yIG5hbWVzIGFyZQogcmVzZXJ2ZWQvcmVhZC1vbmx5
LCB0aGUga2V5IGlzIHJlc2VydmVkL3JlYWQtb25seS4KIEEgcmVzZXJ2ZWQvcmVhZC1vbmx5
IGtleSBpcyBmb3JiaWRkZW4gaW4gY2VydGFpbiBkb2N1bWVudGVkIGNvbnRleHRzLgoKCgoD
BAEBEgM/CAsKrAEKBAQBAwASBEQCWAManQEgQSAoa2luZCwgSUQvbmFtZSkgcGFpciB1c2Vk
IHRvIGNvbnN0cnVjdCBhIGtleSBwYXRoLgoKIElmIGVpdGhlciBuYW1lIG9yIElEIGlzIHNl
dCwgdGhlIGVsZW1lbnQgaXMgY29tcGxldGUuCiBJZiBuZWl0aGVyIGlzIHNldCwgdGhlIGVs
ZW1lbnQgaXMgaW5jb21wbGV0ZS4KCgwKBQQBAwABEgNEChUKswEKBgQBAwACABIDSQQUGqMB
IFRoZSBraW5kIG9mIHRoZSBlbnRpdHkuCiBBIGtpbmQgbWF0Y2hpbmcgcmVnZXggYF9fLipf
X2AgaXMgcmVzZXJ2ZWQvcmVhZC1vbmx5LgogQSBraW5kIG11c3Qgbm90IGNvbnRhaW4gbW9y
ZSB0aGFuIDE1MDAgYnl0ZXMgd2hlbiBVVEYtOCBlbmNvZGVkLgogQ2Fubm90IGJlIGAiImAu
CgoOCgcEAQMAAgAFEgNJBAoKDgoHBAEDAAIAARIDSQsPCg4KBwQBAwACAAMSA0kSEwohCgYE
AQMACAASBEwEVwUaESBUaGUgdHlwZSBvZiBJRC4KCg4KBwQBAwAIAAESA0wKEQqbAQoGBAED
AAIBEgNQBhMaiwEgVGhlIGF1dG8tYWxsb2NhdGVkIElEIG9mIHRoZSBlbnRpdHkuCiBOZXZl
ciBlcXVhbCB0byB6ZXJvLiBWYWx1ZXMgbGVzcyB0aGFuIHplcm8gYXJlIGRpc2NvdXJhZ2Vk
IGFuZCBtYXkgbm90CiBiZSBzdXBwb3J0ZWQgaW4gdGhlIGZ1dHVyZS4KCg4KBwQBAwACAQUS
A1AGCwoOCgcEAQMAAgEBEgNQDA4KDgoHBAEDAAIBAxIDUBESCq4BCgYEAQMAAgISA1YGFhqe
ASBUaGUgbmFtZSBvZiB0aGUgZW50aXR5LgogQSBuYW1lIG1hdGNoaW5nIHJlZ2V4IGBfXy4q
X19gIGlzIHJlc2VydmVkL3JlYWQtb25seS4KIEEgbmFtZSBtdXN0IG5vdCBiZSBtb3JlIHRo
YW4gMTUwMCBieXRlcyB3aGVuIFVURi04IGVuY29kZWQuCiBDYW5ub3QgYmUgYCIiYC4KCg4K
BwQBAwACAgUSA1YGDAoOCgcEAQMAAgIBEgNWDREKDgoHBAEDAAICAxIDVhQVCpkBCgQEAQIA
EgNdAh8aiwEgRW50aXRpZXMgYXJlIHBhcnRpdGlvbmVkIGludG8gc3Vic2V0cywgY3VycmVu
dGx5IGlkZW50aWZpZWQgYnkgYSBwcm9qZWN0CiBJRCBhbmQgbmFtZXNwYWNlIElELgogUXVl
cmllcyBhcmUgc2NvcGVkIHRvIGEgc2luZ2xlIHBhcnRpdGlvbi4KCgwKBQQBAgAGEgNdAg0K
DAoFBAECAAESA10OGgoMCgUEAQIAAxIDXR0eCvQGCgQEAQIBEgNvAiAa5gYgVGhlIGVudGl0
eSBwYXRoLgogQW4gZW50aXR5IHBhdGggY29uc2lzdHMgb2Ygb25lIG9yIG1vcmUgZWxlbWVu
dHMgY29tcG9zZWQgb2YgYSBraW5kIGFuZCBhCiBzdHJpbmcgb3IgbnVtZXJpY2FsIGlkZW50
aWZpZXIsIHdoaWNoIGlkZW50aWZ5IGVudGl0aWVzLiBUaGUgZmlyc3QKIGVsZW1lbnQgaWRl
bnRpZmllcyBhIF9yb290IGVudGl0eV8sIHRoZSBzZWNvbmQgZWxlbWVudCBpZGVudGlmaWVz
CiBhIF9jaGlsZF8gb2YgdGhlIHJvb3QgZW50aXR5LCB0aGUgdGhpcmQgZWxlbWVudCBpZGVu
dGlmaWVzIGEgY2hpbGQgb2YgdGhlCiBzZWNvbmQgZW50aXR5LCBhbmQgc28gZm9ydGguIFRo
ZSBlbnRpdGllcyBpZGVudGlmaWVkIGJ5IGFsbCBwcmVmaXhlcyBvZgogdGhlIHBhdGggYXJl
IGNhbGxlZCB0aGUgZWxlbWVudCdzIF9hbmNlc3RvcnNfLgoKIEFuIGVudGl0eSBwYXRoIGlz
IGFsd2F5cyBmdWxseSBjb21wbGV0ZTogKmFsbCogb2YgdGhlIGVudGl0eSdzIGFuY2VzdG9y
cwogYXJlIHJlcXVpcmVkIHRvIGJlIGluIHRoZSBwYXRoIGFsb25nIHdpdGggdGhlIGVudGl0
eSBpZGVudGlmaWVyIGl0c2VsZi4KIFRoZSBvbmx5IGV4Y2VwdGlvbiBpcyB0aGF0IGluIHNv
bWUgZG9jdW1lbnRlZCBjYXNlcywgdGhlIGlkZW50aWZpZXIgaW4gdGhlCiBsYXN0IHBhdGgg
ZWxlbWVudCAoZm9yIHRoZSBlbnRpdHkpIGl0c2VsZiBtYXkgYmUgb21pdHRlZC4gRm9yIGV4
YW1wbGUsCiB0aGUgbGFzdCBwYXRoIGVsZW1lbnQgb2YgdGhlIGtleSBvZiBgTXV0YXRpb24u
aW5zZXJ0YCBtYXkgaGF2ZSBubwogaWRlbnRpZmllci4KCiBBIHBhdGggY2FuIG5ldmVyIGJl
IGVtcHR5LCBhbmQgYSBwYXRoIGNhbiBoYXZlIGF0IG1vc3QgMTAwIGVsZW1lbnRzLgoKDAoF
BAECAQQSA28CCgoMCgUEAQIBBhIDbwsWCgwKBQQBAgEBEgNvFxsKDAoFBAECAQMSA28eHwod
CgIEAhIEcwB4ARoRIEFuIGFycmF5IHZhbHVlLgoKCgoDBAIBEgNzCBIKiAEKBAQCAgASA3cC
HBp7IFZhbHVlcyBpbiB0aGUgYXJyYXkuCiBUaGUgb3JkZXIgb2YgdGhpcyBhcnJheSBtYXkg
bm90IGJlIHByZXNlcnZlZCBpZiBpdCBjb250YWlucyBhIG1peCBvZgogaW5kZXhlZCBhbmQg
dW5pbmRleGVkIHZhbHVlcy4KCgwKBQQCAgAEEgN3AgoKDAoFBAICAAYSA3cLEAoMCgUEAgIA
ARIDdxEXCgwKBQQCAgADEgN3GhsKYQoCBAMSBXwAtQEBGlQgQSBtZXNzYWdlIHRoYXQgY2Fu
IGhvbGQgYW55IG9mIHRoZSBzdXBwb3J0ZWQgdmFsdWUgdHlwZXMgYW5kIGFzc29jaWF0ZWQK
IG1ldGFkYXRhLgoKCgoDBAMBEgN8CA0KJwoEBAMIABIFfgKtAQMaGCBNdXN0IGhhdmUgYSB2
YWx1ZSBzZXQuCgoMCgUEAwgAARIDfggSCh0KBAQDAgASBIABBC4aDyBBIG51bGwgdmFsdWUu
CgoNCgUEAwIABhIEgAEEHQoNCgUEAwIAARIEgAEeKAoNCgUEAwIAAxIEgAErLQogCgQEAwIB
EgSDAQQbGhIgQSBib29sZWFuIHZhbHVlLgoKDQoFBAMCAQUSBIMBBAgKDQoFBAMCAQESBIMB
CRYKDQoFBAMCAQMSBIMBGRoKIQoEBAMCAhIEhgEEHBoTIEFuIGludGVnZXIgdmFsdWUuCgoN
CgUEAwICBRIEhgEECQoNCgUEAwICARIEhgEKFwoNCgUEAwICAxIEhgEaGwofCgQEAwIDEgSJ
AQQcGhEgQSBkb3VibGUgdmFsdWUuCgoNCgUEAwIDBRIEiQEECgoNCgUEAwIDARIEiQELFwoN
CgUEAwIDAxIEiQEaGwqKAQoEBAMCBBIEjgEEMxp8IEEgdGltZXN0YW1wIHZhbHVlLgogV2hl
biBzdG9yZWQgaW4gdGhlIERhdGFzdG9yZSwgcHJlY2lzZSBvbmx5IHRvIG1pY3Jvc2Vjb25k
czsKIGFueSBhZGRpdGlvbmFsIHByZWNpc2lvbiBpcyByb3VuZGVkIGRvd24uCgoNCgUEAwIE
BhIEjgEEHQoNCgUEAwIEARIEjgEeLQoNCgUEAwIEAxIEjgEwMgocCgQEAwIFEgSRAQQWGg4g
QSBrZXkgdmFsdWUuCgoNCgUEAwIFBhIEkQEEBwoNCgUEAwIFARIEkQEIEQoNCgUEAwIFAxIE
kQEUFQq1AQoEBAMCBhIElgEEHRqmASBBIFVURi04IGVuY29kZWQgc3RyaW5nIHZhbHVlLgog
V2hlbiBgZXhjbHVkZV9mcm9tX2luZGV4ZXNgIGlzIGZhbHNlIChpdCBpcyBpbmRleGVkKSwg
bWF5IGhhdmUgYXQgbW9zdAogMTUwMCBieXRlcy4gT3RoZXJ3aXNlLCBtYXkgYmUgc2V0IHRv
IGF0IG1vc3QgMSwwMDAsMDAwIGJ5dGVzLgoKDQoFBAMCBgUSBJYBBAoKDQoFBAMCBgESBJYB
CxcKDQoFBAMCBgMSBJYBGhwKsAEKBAQDAgcSBJwBBBoaoQEgQSBibG9iIHZhbHVlLgogTWF5
IGhhdmUgYXQgbW9zdCAxLDAwMCwwMDAgYnl0ZXMuCiBXaGVuIGBleGNsdWRlX2Zyb21faW5k
ZXhlc2AgaXMgZmFsc2UsIG1heSBoYXZlIGF0IG1vc3QgMTUwMCBieXRlcy4KIEluIEpTT04g
cmVxdWVzdHMsIG11c3QgYmUgYmFzZTY0LWVuY29kZWQuCgoNCgUEAwIHBRIEnAEECQoNCgUE
AwIHARIEnAEKFAoNCgUEAwIHAxIEnAEXGQpPCgQEAwIIEgSfAQQrGkEgQSBnZW8gcG9pbnQg
dmFsdWUgcmVwcmVzZW50aW5nIGEgcG9pbnQgb24gdGhlIHN1cmZhY2Ugb2YgRWFydGguCgoN
CgUEAwIIBhIEnwEEFgoNCgUEAwIIARIEnwEXJgoNCgUEAwIIAxIEnwEpKgqKAQoEBAMCCRIE
pgEEHBp8IEFuIGVudGl0eSB2YWx1ZS4KCiAtIE1heSBoYXZlIG5vIGtleS4KIC0gTWF5IGhh
dmUgYSBrZXkgd2l0aCBhbiBpbmNvbXBsZXRlIGtleSBwYXRoLgogLSBNYXkgaGF2ZSBhIHJl
c2VydmVkL3JlYWQtb25seSBrZXkuCgoNCgUEAwIJBhIEpgEECgoNCgUEAwIJARIEpgELFwoN
CgUEAwIJAxIEpgEaGwqxAQoEBAMCChIErAEEHxqiASBBbiBhcnJheSB2YWx1ZS4KIENhbm5v
dCBjb250YWluIGFub3RoZXIgYXJyYXkgdmFsdWUuCiBBIGBWYWx1ZWAgaW5zdGFuY2UgdGhh
dCBzZXRzIGZpZWxkIGBhcnJheV92YWx1ZWAgbXVzdCBub3Qgc2V0IGZpZWxkcwogYG1lYW5p
bmdgIG9yIGBleGNsdWRlX2Zyb21faW5kZXhlc2AuCgoNCgUEAwIKBhIErAEEDgoNCgUEAwIK
ARIErAEPGgoNCgUEAwIKAxIErAEdHgpZCgQEAwILEgSwAQIVGksgVGhlIGBtZWFuaW5nYCBm
aWVsZCBzaG91bGQgb25seSBiZSBwb3B1bGF0ZWQgZm9yIGJhY2t3YXJkcyBjb21wYXRpYmls
aXR5LgoKDQoFBAMCCwUSBLABAgcKDQoFBAMCCwESBLABCA8KDQoFBAMCCwMSBLABEhQKZQoE
BAMCDBIEtAECIRpXIElmIHRoZSB2YWx1ZSBzaG91bGQgYmUgZXhjbHVkZWQgZnJvbSBhbGwg
aW5kZXhlcyBpbmNsdWRpbmcgdGhvc2UgZGVmaW5lZAogZXhwbGljaXRseS4KCg0KBQQDAgwF
EgS0AQIGCg0KBQQDAgwBEgS0AQcbCg0KBQQDAgwDEgS0AR4gCroBCgIEBBIGvAEAzAEBGqsB
IEEgRGF0YXN0b3JlIGRhdGEgb2JqZWN0LgoKIEFuIGVudGl0eSBpcyBsaW1pdGVkIHRvIDEg
bWVnYWJ5dGUgd2hlbiBzdG9yZWQuIFRoYXQgX3JvdWdobHlfCiBjb3JyZXNwb25kcyB0byBh
IGxpbWl0IG9mIDEgbWVnYWJ5dGUgZm9yIHRoZSBzZXJpYWxpemVkIGZvcm0gb2YgdGhpcwog
bWVzc2FnZS4KCgsKAwQEARIEvAEIDgryAQoEBAQCABIEwwECDhrjASBUaGUgZW50aXR5J3Mg
a2V5LgoKIEFuIGVudGl0eSBtdXN0IGhhdmUgYSBrZXksIHVubGVzcyBvdGhlcndpc2UgZG9j
dW1lbnRlZCAoZm9yIGV4YW1wbGUsCiBhbiBlbnRpdHkgaW4gYFZhbHVlLmVudGl0eV92YWx1
ZWAgbWF5IGhhdmUgbm8ga2V5KS4KIEFuIGVudGl0eSdzIGtpbmQgaXMgaXRzIGtleSBwYXRo
J3MgbGFzdCBlbGVtZW50J3Mga2luZCwKIG9yIG51bGwgaWYgaXQgaGFzIG5vIGtleS4KCg0K
BQQEAgAGEgTDAQIFCg0KBQQEAgABEgTDAQYJCg0KBQQEAgADEgTDAQwNCpkCCgQEBAIBEgTL
AQIkGooCIFRoZSBlbnRpdHkncyBwcm9wZXJ0aWVzLgogVGhlIG1hcCdzIGtleXMgYXJlIHBy
b3BlcnR5IG5hbWVzLgogQSBwcm9wZXJ0eSBuYW1lIG1hdGNoaW5nIHJlZ2V4IGBfXy4qX19g
IGlzIHJlc2VydmVkLgogQSByZXNlcnZlZCBwcm9wZXJ0eSBuYW1lIGlzIGZvcmJpZGRlbiBp
biBjZXJ0YWluIGRvY3VtZW50ZWQgY29udGV4dHMuCiBUaGUgbmFtZSBtdXN0IG5vdCBjb250
YWluIG1vcmUgdGhhbiA1MDAgY2hhcmFjdGVycy4KIFRoZSBuYW1lIGNhbm5vdCBiZSBgIiJg
LgoKDQoFBAQCAQYSBMsBAhQKDQoFBAQCAQESBMsBFR8KDQoFBAQCAQMSBMsBIiNiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1beta3::Entity::PartitionId ===
    # Fields for PartitionId
    # Field: project_id Type: 9 ()
    # Field: namespace_id Type: 9 ()

# === Message: Google::Datastore::V1beta3::Entity::Key ===
    # Fields for Key
    # Field: partition_id Type: 11 (.google.datastore.v1beta3.PartitionId)
    # Field: path Type: 11 (.google.datastore.v1beta3.Key.PathElement)

# === Message: Google::Datastore::V1beta3::Entity::ArrayValue ===
    # Fields for ArrayValue
    # Field: values Type: 11 (.google.datastore.v1beta3.Value)

# === Message: Google::Datastore::V1beta3::Entity::Value ===
    # Fields for Value
    # Field: null_value Type: 14 (.google.protobuf.NullValue)
    # Field: boolean_value Type: 8 ()
    # Field: integer_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: key_value Type: 11 (.google.datastore.v1beta3.Key)
    # Field: string_value Type: 9 ()
    # Field: blob_value Type: 12 ()
    # Field: geo_point_value Type: 11 (.google.type.LatLng)
    # Field: entity_value Type: 11 (.google.datastore.v1beta3.Entity)
    # Field: array_value Type: 11 (.google.datastore.v1beta3.ArrayValue)
    # Field: meaning Type: 5 ()
    # Field: exclude_from_indexes Type: 8 ()

# === Message: Google::Datastore::V1beta3::Entity::Entity ===
    # Fields for Entity
    # Field: key Type: 11 (.google.datastore.v1beta3.Key)
    # Field: properties Type: 11 (.google.datastore.v1beta3.Entity.PropertiesEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1beta3::Entity - Compiled Protocol Buffers messages for google/datastore/v1beta3/entity.proto

=head1 SYNOPSIS

    use Google::Datastore::V1beta3::Entity;

    my $msg = Google::Datastore::V1beta3::Entity::PartitionId->new({
        project_id => $project_id,
        namespace_id => $namespace_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1beta3::Entity::PartitionId->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1beta3/entity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1beta3::Entity::PartitionId

A partition ID identifies a grouping of entities. The grouping is always
by project and namespace, however the namespace ID may be empty.

A partition ID contains several dimensions:
project ID and namespace ID.

Partition dimensions:

- May be `""`.
- Must be valid UTF-8 bytes.
- Must have values that match regex `[A-Za-z\d\.\-_]{1,100}`
If the value of any dimension matches regex `__.*__`, the partition is
reserved/read-only.
A reserved/read-only partition ID is forbidden in certain documented
contexts.

Foreign partition IDs (in which the project ID does
not match the context project ID ) are discouraged.
Reads and writes of foreign partition IDs may fail if the project is not in
an active state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project to which the entities belong.

=item * C<< $msg->namespace_id() >> / C<< $msg->namespace_id($value) >>

Type: C<String>

If not empty, the ID of the namespace to which the entities belong.

=back

=head2 Google::Datastore::V1beta3::Entity::Key

A unique identifier for an entity.
If a key's partition ID or any of its path kinds or names are
reserved/read-only, the key is reserved/read-only.
A reserved/read-only key is forbidden in certain documented contexts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partition_id() >> / C<< $msg->partition_id($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::PartitionId>)

Entities are partitioned into subsets, currently identified by a project
ID and namespace ID.
Queries are scoped to a single partition.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key::PathElement>)

The entity path.
An entity path consists of one or more elements composed of a kind and a
string or numerical identifier, which identify entities. The first
element identifies a _root entity_, the second element identifies
a _child_ of the root entity, the third element identifies a child of the
second entity, and so forth. The entities identified by all prefixes of
the path are called the element's _ancestors_.

An entity path is always fully complete: *all* of the entity's ancestors
are required to be in the path along with the entity identifier itself.
The only exception is that in some documented cases, the identifier in the
last path element (for the entity) itself may be omitted. For example,
the last path element of the key of `Mutation.insert` may have no
identifier.

A path can never be empty, and a path can have at most 100 elements.

=back

=head2 Google::Datastore::V1beta3::Entity::ArrayValue

An array value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Value>)

Values in the array.
The order of this array may not be preserved if it contains a mix of
indexed and unindexed values.

=back

=head2 Google::Datastore::V1beta3::Entity::Value

A message that can hold any of the supported value types and associated
metadata.

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
When stored in the Datastore, precise only to microseconds;
any additional precision is rounded down.

=item * C<< $msg->key_value() >> / C<< $msg->key_value($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

A key value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A UTF-8 encoded string value.
When `exclude_from_indexes` is false (it is indexed), may have at most
1500 bytes. Otherwise, may be set to at most 1,000,000 bytes.

=item * C<< $msg->blob_value() >> / C<< $msg->blob_value($value) >>

Type: C<Bytes>

A blob value.
May have at most 1,000,000 bytes.
When `exclude_from_indexes` is false, may have at most 1500 bytes.
In JSON requests, must be base64-encoded.

=item * C<< $msg->geo_point_value() >> / C<< $msg->geo_point_value($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

A geo point value representing a point on the surface of Earth.

=item * C<< $msg->entity_value() >> / C<< $msg->entity_value($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity>)

An entity value.

- May have no key.
- May have a key with an incomplete key path.
- May have a reserved/read-only key.

=item * C<< $msg->array_value() >> / C<< $msg->array_value($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::ArrayValue>)

An array value.
Cannot contain another array value.
A `Value` instance that sets field `array_value` must not set fields
`meaning` or `exclude_from_indexes`.

=item * C<< $msg->meaning() >> / C<< $msg->meaning($value) >>

Type: C<Int32>

The `meaning` field should only be populated for backwards compatibility.

=item * C<< $msg->exclude_from_indexes() >> / C<< $msg->exclude_from_indexes($value) >>

Type: C<Bool>

If the value should be excluded from all indexes including those defined
explicitly.

=back

=head2 Google::Datastore::V1beta3::Entity::Entity

A Datastore data object.

An entity is limited to 1 megabyte when stored. That _roughly_
corresponds to a limit of 1 megabyte for the serialized form of this
message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

The entity's key.

An entity must have a key, unless otherwise documented (for example,
an entity in `Value.entity_value` may have no key).
An entity's kind is its key path's last element's kind,
or null if it has no key.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity::PropertiesEntry>)

The entity's properties.
The map's keys are property names.
A property name matching regex `__.*__` is reserved.
A reserved property name is forbidden in certain documented contexts.
The name must not contain more than 500 characters.
The name cannot be `""`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1beta3::Entity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
