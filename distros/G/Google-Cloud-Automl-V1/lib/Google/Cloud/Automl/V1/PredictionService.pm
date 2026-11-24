package Google::Cloud::Automl::V1::PredictionService;

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
    eval { require Google::Cloud::Automl::V1::AnnotationPayload };
    eval { require Google::Cloud::Automl::V1::DataItems };
    eval { require Google::Cloud::Automl::V1::Io };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYXV0b21sL3YxL3ByZWRpY3Rpb25fc2VydmljZS5wcm90bxIWZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aL2dvb2dsZS9jbG91ZC9hdXRvbWwvdjEvYW5u
b3RhdGlvbl9wYXlsb2FkLnByb3RvGidnb29nbGUvY2xvdWQvYXV0b21sL3YxL2RhdGFfaXRl
bXMucHJvdG8aH2dvb2dsZS9jbG91ZC9hdXRvbWwvdjEvaW8ucHJvdG8aI2dvb2dsZS9sb25n
cnVubmluZy9vcGVyYXRpb25zLnByb3RvIpcCCg5QcmVkaWN0UmVxdWVzdBI3CgRuYW1lGAEg
ASgJQiPgQQL6QR0KG2F1dG9tbC5nb29nbGVhcGlzLmNvbS9Nb2RlbFIEbmFtZRJFCgdwYXls
b2FkGAIgASgLMiYuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5FeGFtcGxlUGF5bG9hZEID4EEC
UgdwYXlsb2FkEkoKBnBhcmFtcxgDIAMoCzIyLmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuUHJl
ZGljdFJlcXVlc3QuUGFyYW1zRW50cnlSBnBhcmFtcxo5CgtQYXJhbXNFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIr0CCg9QcmVkaWN0UmVzcG9u
c2USQwoHcGF5bG9hZBgBIAMoCzIpLmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuQW5ub3RhdGlv
blBheWxvYWRSB3BheWxvYWQSVQoScHJlcHJvY2Vzc2VkX2lucHV0GAMgASgLMiYuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MS5FeGFtcGxlUGF5bG9hZFIRcHJlcHJvY2Vzc2VkSW5wdXQSUQoI
bWV0YWRhdGEYAiADKAsyNS5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlByZWRpY3RSZXNwb25z
ZS5NZXRhZGF0YUVudHJ5UghtZXRhZGF0YRo7Cg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEijwMKE0JhdGNoUHJlZGljdFJlcXVl
c3QSNwoEbmFtZRgBIAEoCUIj4EEC+kEdChthdXRvbWwuZ29vZ2xlYXBpcy5jb20vTW9kZWxS
BG5hbWUSVwoMaW5wdXRfY29uZmlnGAMgASgLMi8uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5C
YXRjaFByZWRpY3RJbnB1dENvbmZpZ0ID4EECUgtpbnB1dENvbmZpZxJaCg1vdXRwdXRfY29u
ZmlnGAQgASgLMjAuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5CYXRjaFByZWRpY3RPdXRwdXRD
b25maWdCA+BBAlIMb3V0cHV0Q29uZmlnEk8KBnBhcmFtcxgFIAMoCzI3Lmdvb2dsZS5jbG91
ZC5hdXRvbWwudjEuQmF0Y2hQcmVkaWN0UmVxdWVzdC5QYXJhbXNFbnRyeVIGcGFyYW1zGjkK
C1BhcmFtc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC
OAEipwEKEkJhdGNoUHJlZGljdFJlc3VsdBJUCghtZXRhZGF0YRgBIAMoCzI4Lmdvb2dsZS5j
bG91ZC5hdXRvbWwudjEuQmF0Y2hQcmVkaWN0UmVzdWx0Lk1ldGFkYXRhRW50cnlSCG1ldGFk
YXRhGjsKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ATKFBAoRUHJlZGljdGlvblNlcnZpY2USrwEKB1ByZWRpY3QSJi5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxLlByZWRpY3RSZXF1ZXN0GicuZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MS5QcmVkaWN0UmVzcG9uc2UiU4LT5JMCNyIyL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovbW9kZWxzLyp9OnByZWRpY3Q6ASraQRNuYW1lLHBheWxvYWQscGFyYW1zEvIBCgxC
YXRjaFByZWRpY3QSKy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLkJhdGNoUHJlZGljdFJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpUBgtPkkwI8IjcvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9tb2RlbHMvKn06YmF0Y2hQcmVkaWN0OgEq2kEmbmFt
ZSxpbnB1dF9jb25maWcsb3V0cHV0X2NvbmZpZyxwYXJhbXPKQScKEkJhdGNoUHJlZGljdFJl
c3VsdBIRT3BlcmF0aW9uTWV0YWRhdGEaScpBFWF1dG9tbC5nb29nbGVhcGlzLmNvbdJBLmh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CuAEKGmNvbS5n
b29nbGUuY2xvdWQuYXV0b21sLnYxQhZQcmVkaWN0aW9uU2VydmljZVByb3RvUAFaMmNsb3Vk
Lmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9tbHBiqgIWR29vZ2xl
LkNsb3VkLkF1dG9NTC5WMcoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHqAhlHb29nbGU6OkNs
b3VkOjpBdXRvTUw6OlYxSrBWCgcSBQ4AwAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkK
AgMDEgMVACMKCQoCAwQSAxYAOQoJCgIDBRIDFwAxCgkKAgMGEgMYACkKCQoCAwcSAxkALQoI
CgEIEgMbADMKCQoCCCUSAxsAMwoICgEIEgMcAEkKCQoCCAsSAxwASQoICgEIEgMdACIKCQoC
CAoSAx0AIgoICgEIEgMeADcKCQoCCAgSAx4ANwoICgEIEgMfADMKCQoCCAESAx8AMwoICgEI
EgMgADMKCQoCCCkSAyAAMwoICgEIEgMhADIKCQoCCC0SAyEAMgqkAQoCBgASBCcAcQEalwEg
QXV0b01MIFByZWRpY3Rpb24gQVBJLgoKIE9uIGFueSBpbnB1dCB0aGF0IGlzIGRvY3VtZW50
ZWQgdG8gZXhwZWN0IGEgc3RyaW5nIHBhcmFtZXRlciBpbgogc25ha2VfY2FzZSBvciBkYXNo
LWNhc2UsIGVpdGhlciBvZiB0aG9zZSBjYXNlcyBpcyBhY2NlcHRlZC4KCgoKAwYAARIDJwgZ
CgoKAwYAAxIDKAI9CgwKBQYAA5kIEgMoAj0KCgoDBgADEgMpAlYKDAoFBgADmggSAykCVgrW
CAoEBgACABIETwJVAxrHCCBQZXJmb3JtIGFuIG9ubGluZSBwcmVkaWN0aW9uLiBUaGUgcHJl
ZGljdGlvbiByZXN1bHQgaXMgZGlyZWN0bHkKIHJldHVybmVkIGluIHRoZSByZXNwb25zZS4K
IEF2YWlsYWJsZSBmb3IgZm9sbG93aW5nIE1MIHNjZW5hcmlvcywgYW5kIHRoZWlyIGV4cGVj
dGVkIHJlcXVlc3QgcGF5bG9hZHM6CgogQXV0b01MIFZpc2lvbiBDbGFzc2lmaWNhdGlvbgoK
ICogQW4gaW1hZ2UgaW4gLkpQRUcsIC5HSUYgb3IgLlBORyBmb3JtYXQsIGltYWdlX2J5dGVz
IHVwIHRvIDMwTUIuCgogQXV0b01MIFZpc2lvbiBPYmplY3QgRGV0ZWN0aW9uCgogKiBBbiBp
bWFnZSBpbiAuSlBFRywgLkdJRiBvciAuUE5HIGZvcm1hdCwgaW1hZ2VfYnl0ZXMgdXAgdG8g
MzBNQi4KCiBBdXRvTUwgTmF0dXJhbCBMYW5ndWFnZSBDbGFzc2lmaWNhdGlvbgoKICogQSBU
ZXh0U25pcHBldCB1cCB0byA2MCwwMDAgY2hhcmFjdGVycywgVVRGLTggZW5jb2RlZCBvciBh
IGRvY3VtZW50IGluCiAuUERGLCAuVElGIG9yIC5USUZGIGZvcm1hdCB3aXRoIHNpemUgdXB0
byAyTUIuCgogQXV0b01MIE5hdHVyYWwgTGFuZ3VhZ2UgRW50aXR5IEV4dHJhY3Rpb24KCiAq
IEEgVGV4dFNuaXBwZXQgdXAgdG8gMTAsMDAwIGNoYXJhY3RlcnMsIFVURi04IE5GQyBlbmNv
ZGVkIG9yIGEgZG9jdW1lbnQKICBpbiAuUERGLCAuVElGIG9yIC5USUZGIGZvcm1hdCB3aXRo
IHNpemUgdXB0byAyME1CLgoKIEF1dG9NTCBOYXR1cmFsIExhbmd1YWdlIFNlbnRpbWVudCBB
bmFseXNpcwoKICogQSBUZXh0U25pcHBldCB1cCB0byA2MCwwMDAgY2hhcmFjdGVycywgVVRG
LTggZW5jb2RlZCBvciBhIGRvY3VtZW50IGluCiAuUERGLCAuVElGIG9yIC5USUZGIGZvcm1h
dCB3aXRoIHNpemUgdXB0byAyTUIuCgogQXV0b01MIFRyYW5zbGF0aW9uCgogKiBBIFRleHRT
bmlwcGV0IHVwIHRvIDI1LDAwMCBjaGFyYWN0ZXJzLCBVVEYtOCBlbmNvZGVkLgoKIEF1dG9N
TCBUYWJsZXMKCiAqIEEgcm93IHdpdGggY29sdW1uIHZhbHVlcyBtYXRjaGluZwogICB0aGUg
Y29sdW1ucyBvZiB0aGUgbW9kZWwsIHVwIHRvIDVNQi4gTm90IGF2YWlsYWJsZSBmb3IgRk9S
RUNBU1RJTkcKICAgYHByZWRpY3Rpb25fdHlwZWAuCgoMCgUGAAIAARIDTwYNCgwKBQYAAgAC
EgNPDhwKDAoFBgACAAMSA08nNgoNCgUGAAIABBIEUARTBgoRCgkGAAIABLDKvCISBFAEUwYK
DAoFBgACAAQSA1QEQQoPCggGAAIABJsIABIDVARBCugGCgQGAAIBEgRmAnADGtkGIFBlcmZv
cm0gYSBiYXRjaCBwcmVkaWN0aW9uLiBVbmxpa2UgdGhlIG9ubGluZSBbUHJlZGljdF1bZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MS5QcmVkaWN0aW9uU2VydmljZS5QcmVkaWN0XSwgYmF0Y2gK
IHByZWRpY3Rpb24gcmVzdWx0IHdvbid0IGJlIGltbWVkaWF0ZWx5IGF2YWlsYWJsZSBpbiB0
aGUgcmVzcG9uc2UuIEluc3RlYWQsCiBhIGxvbmcgcnVubmluZyBvcGVyYXRpb24gb2JqZWN0
IGlzIHJldHVybmVkLiBVc2VyIGNhbiBwb2xsIHRoZSBvcGVyYXRpb24KIHJlc3VsdCB2aWEg
W0dldE9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMuR2V0T3BlcmF0
aW9uXQogbWV0aG9kLiBPbmNlIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgW0JhdGNoUHJlZGlj
dFJlc3VsdF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5CYXRjaFByZWRpY3RSZXN1bHRdIGlz
IHJldHVybmVkIGluCiB0aGUgW3Jlc3BvbnNlXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uLnJlc3BvbnNlXSBmaWVsZC4KIEF2YWlsYWJsZSBmb3IgZm9sbG93aW5nIE1MIHNjZW5h
cmlvczoKCiAqIEF1dG9NTCBWaXNpb24gQ2xhc3NpZmljYXRpb24KICogQXV0b01MIFZpc2lv
biBPYmplY3QgRGV0ZWN0aW9uCiAqIEF1dG9NTCBWaWRlbyBJbnRlbGxpZ2VuY2UgQ2xhc3Np
ZmljYXRpb24KICogQXV0b01MIFZpZGVvIEludGVsbGlnZW5jZSBPYmplY3QgVHJhY2tpbmcg
KiBBdXRvTUwgTmF0dXJhbCBMYW5ndWFnZSBDbGFzc2lmaWNhdGlvbgogKiBBdXRvTUwgTmF0
dXJhbCBMYW5ndWFnZSBFbnRpdHkgRXh0cmFjdGlvbgogKiBBdXRvTUwgTmF0dXJhbCBMYW5n
dWFnZSBTZW50aW1lbnQgQW5hbHlzaXMKICogQXV0b01MIFRhYmxlcwoKDAoFBgACAQESA2YG
EgoMCgUGAAIBAhIDZhMmCgwKBQYAAgEDEgNmMU0KDQoFBgACAQQSBGcEagYKEQoJBgACAQSw
yrwiEgRnBGoGCgwKBQYAAgEEEgNrBFQKDwoIBgACAQSbCAASA2sEVAoNCgUGAAIBBBIEbARv
BgoPCgcGAAIBBJkIEgRsBG8GCnEKAgQAEgV0AKABARpkIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
W1ByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjEuUHJl
ZGljdGlvblNlcnZpY2UuUHJlZGljdF0uCgoKCgMEAAESA3QIFgpOCgQEAAIAEgR2AnsEGkAg
UmVxdWlyZWQuIE5hbWUgb2YgdGhlIG1vZGVsIHJlcXVlc3RlZCB0byBzZXJ2ZSB0aGUgcHJl
ZGljdGlvbi4KCgwKBQQAAgAFEgN2AggKDAoFBAACAAESA3YJDQoMCgUEAAIAAxIDdhARCg0K
BQQAAgAIEgR2EnsDCg8KCAQAAgAInAgAEgN3BCoKDwoHBAACAAifCBIEeAR6BQqKAQoEBAAC
ARIDfwJGGn0gUmVxdWlyZWQuIFBheWxvYWQgdG8gcGVyZm9ybSBhIHByZWRpY3Rpb24gb24u
IFRoZSBwYXlsb2FkIG11c3QgbWF0Y2ggdGhlCiBwcm9ibGVtIHR5cGUgdGhhdCB0aGUgbW9k
ZWwgd2FzIHRyYWluZWQgdG8gc29sdmUuCgoMCgUEAAIBBhIDfwIQCgwKBQQAAgEBEgN/ERgK
DAoFBAACAQMSA38bHAoMCgUEAAIBCBIDfx1FCg8KCAQAAgEInAgAEgN/HkQKhQgKBAQAAgIS
BJ8BAiEa9gcgQWRkaXRpb25hbCBkb21haW4tc3BlY2lmaWMgcGFyYW1ldGVycywgYW55IHN0
cmluZyBtdXN0IGJlIHVwIHRvIDI1MDAwCiBjaGFyYWN0ZXJzIGxvbmcuCgogQXV0b01MIFZp
c2lvbiBDbGFzc2lmaWNhdGlvbgoKIGBzY29yZV90aHJlc2hvbGRgCiA6IChmbG9hdCkgQSB2
YWx1ZSBmcm9tIDAuMCB0byAxLjAuIFdoZW4gdGhlIG1vZGVsCiAgIG1ha2VzIHByZWRpY3Rp
b25zIGZvciBhbiBpbWFnZSwgaXQgd2lsbCBvbmx5IHByb2R1Y2UgcmVzdWx0cyB0aGF0IGhh
dmUKICAgYXQgbGVhc3QgdGhpcyBjb25maWRlbmNlIHNjb3JlLiBUaGUgZGVmYXVsdCBpcyAw
LjUuCgogQXV0b01MIFZpc2lvbiBPYmplY3QgRGV0ZWN0aW9uCgogYHNjb3JlX3RocmVzaG9s
ZGAKIDogKGZsb2F0KSBXaGVuIE1vZGVsIGRldGVjdHMgb2JqZWN0cyBvbiB0aGUgaW1hZ2Us
CiAgIGl0IHdpbGwgb25seSBwcm9kdWNlIGJvdW5kaW5nIGJveGVzIHdoaWNoIGhhdmUgYXQg
bGVhc3QgdGhpcwogICBjb25maWRlbmNlIHNjb3JlLiBWYWx1ZSBpbiAwIHRvIDEgcmFuZ2Us
IGRlZmF1bHQgaXMgMC41LgoKIGBtYXhfYm91bmRpbmdfYm94X2NvdW50YAogOiAoaW50NjQp
IFRoZSBtYXhpbXVtIG51bWJlciBvZiBib3VuZGluZwogICBib3hlcyByZXR1cm5lZC4gVGhl
IGRlZmF1bHQgaXMgMTAwLiBUaGUKICAgbnVtYmVyIG9mIHJldHVybmVkIGJvdW5kaW5nIGJv
eGVzIG1pZ2h0IGJlIGxpbWl0ZWQgYnkgdGhlIHNlcnZlci4KCiBBdXRvTUwgVGFibGVzCgog
YGZlYXR1cmVfaW1wb3J0YW5jZWAKIDogKGJvb2xlYW4pIFdoZXRoZXIKIFtmZWF0dXJlX2lt
cG9ydGFuY2VdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjEuVGFibGVzTW9kZWxDb2x1bW5JbmZv
LmZlYXR1cmVfaW1wb3J0YW5jZV0KICAgaXMgcG9wdWxhdGVkIGluIHRoZSByZXR1cm5lZCBs
aXN0IG9mCiAgIFtUYWJsZXNBbm5vdGF0aW9uXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLlRh
Ymxlc0Fubm90YXRpb25dCiAgIG9iamVjdHMuIFRoZSBkZWZhdWx0IGlzIGZhbHNlLgoKDQoF
BAACAgYSBJ8BAhUKDQoFBAACAgESBJ8BFhwKDQoFBAACAgMSBJ8BHyAKcwoCBAESBqMBAMYB
ARplIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFtQcmVkaWN0aW9uU2VydmljZS5QcmVkaWN0XVtn
b29nbGUuY2xvdWQuYXV0b21sLnYxLlByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgoKCwoD
BAEBEgSjAQgXCoQBCgQEAQIAEgSnAQIpGnYgUHJlZGljdGlvbiByZXN1bHQuCiBBdXRvTUwg
VHJhbnNsYXRpb24gYW5kIEF1dG9NTCBOYXR1cmFsIExhbmd1YWdlIFNlbnRpbWVudCBBbmFs
eXNpcwogcmV0dXJuIHByZWNpc2VseSBvbmUgcGF5bG9hZC4KCg0KBQQBAgAEEgSnAQIKCg0K
BQQBAgAGEgSnAQscCg0KBQQBAgABEgSnAR0kCg0KBQQBAgADEgSnAScoCvYCCgQEAQIBEgSx
AQIoGucCIFRoZSBwcmVwcm9jZXNzZWQgZXhhbXBsZSB0aGF0IEF1dG9NTCBhY3R1YWxseSBt
YWtlcyBwcmVkaWN0aW9uIG9uLgogRW1wdHkgaWYgQXV0b01MIGRvZXMgbm90IHByZXByb2Nl
c3MgdGhlIGlucHV0IGV4YW1wbGUuCgogRm9yIEF1dG9NTCBOYXR1cmFsIExhbmd1YWdlIChD
bGFzc2lmaWNhdGlvbiwgRW50aXR5IEV4dHJhY3Rpb24sIGFuZAogU2VudGltZW50IEFuYWx5
c2lzKSwgaWYgdGhlIGlucHV0IGlzIGEgZG9jdW1lbnQsIHRoZSByZWNvZ25pemVkIHRleHQg
aXMKIHJldHVybmVkIGluIHRoZQogW2RvY3VtZW50X3RleHRdW2dvb2dsZS5jbG91ZC5hdXRv
bWwudjEuRG9jdW1lbnQuZG9jdW1lbnRfdGV4dF0KIHByb3BlcnR5LgoKDQoFBAECAQYSBLEB
AhAKDQoFBAECAQESBLEBESMKDQoFBAECAQMSBLEBJicK3gUKBAQBAgISBMUBAiMazwUgQWRk
aXRpb25hbCBkb21haW4tc3BlY2lmaWMgcHJlZGljdGlvbiByZXNwb25zZSBtZXRhZGF0YS4K
CiBBdXRvTUwgVmlzaW9uIE9iamVjdCBEZXRlY3Rpb24KCiBgbWF4X2JvdW5kaW5nX2JveF9j
b3VudGAKIDogKGludDY0KSBUaGUgbWF4aW11bSBudW1iZXIgb2YgYm91bmRpbmcgYm94ZXMg
dG8gcmV0dXJuIHBlciBpbWFnZS4KCiBBdXRvTUwgTmF0dXJhbCBMYW5ndWFnZSBTZW50aW1l
bnQgQW5hbHlzaXMKCiBgc2VudGltZW50X3Njb3JlYAogOiAoZmxvYXQsIGRlcHJlY2F0ZWQp
IEEgdmFsdWUgYmV0d2VlbiAtMSBhbmQgMSwKICAgLTEgbWFwcyB0byBsZWFzdCBwb3NpdGl2
ZSBzZW50aW1lbnQsIHdoaWxlIDEgbWFwcyB0byB0aGUgbW9zdCBwb3NpdGl2ZQogICBvbmUg
YW5kIHRoZSBoaWdoZXIgdGhlIHNjb3JlLCB0aGUgbW9yZSBwb3NpdGl2ZSB0aGUgc2VudGlt
ZW50IGluIHRoZQogICBkb2N1bWVudCBpcy4gWWV0IHRoZXNlIHZhbHVlcyBhcmUgcmVsYXRp
dmUgdG8gdGhlIHRyYWluaW5nIGRhdGEsIHNvCiAgIGUuZy4gaWYgYWxsIGRhdGEgd2FzIHBv
c2l0aXZlIHRoZW4gLTEgaXMgYWxzbyBwb3NpdGl2ZSAodGhvdWdoCiAgIHRoZSBsZWFzdCku
CiAgIGBzZW50aW1lbnRfc2NvcmVgIGlzIG5vdCB0aGUgc2FtZSBhcyAic2NvcmUiIGFuZCAi
bWFnbml0dWRlIgogICBmcm9tIFNlbnRpbWVudCBBbmFseXNpcyBpbiB0aGUgTmF0dXJhbCBM
YW5ndWFnZSBBUEkuCgoNCgUEAQICBhIExQECFQoNCgUEAQICARIExQEWHgoNCgUEAQICAxIE
xQEhIgp8CgIEAhIGyQEArgIBGm4gUmVxdWVzdCBtZXNzYWdlIGZvciBbUHJlZGljdGlvblNl
cnZpY2UuQmF0Y2hQcmVkaWN0XVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLlByZWRpY3Rpb25T
ZXJ2aWNlLkJhdGNoUHJlZGljdF0uCgoLCgMEAgESBMkBCBsKVgoEBAICABIGywEC0AEEGkYg
UmVxdWlyZWQuIE5hbWUgb2YgdGhlIG1vZGVsIHJlcXVlc3RlZCB0byBzZXJ2ZSB0aGUgYmF0
Y2ggcHJlZGljdGlvbi4KCg0KBQQCAgAFEgTLAQIICg0KBQQCAgABEgTLAQkNCg0KBQQCAgAD
EgTLARARCg8KBQQCAgAIEgbLARLQAQMKEAoIBAICAAicCAASBMwBBCoKEQoHBAICAAifCBIG
zQEEzwEFCkcKBAQCAgESBNMBAlQaOSBSZXF1aXJlZC4gVGhlIGlucHV0IGNvbmZpZ3VyYXRp
b24gZm9yIGJhdGNoIHByZWRpY3Rpb24uCgoNCgUEAgIBBhIE0wECGQoNCgUEAgIBARIE0wEa
JgoNCgUEAgIBAxIE0wEpKgoNCgUEAgIBCBIE0wErUwoQCggEAgIBCJwIABIE0wEsUgpjCgQE
AgICEgTXAQJWGlUgUmVxdWlyZWQuIFRoZSBDb25maWd1cmF0aW9uIHNwZWNpZnlpbmcgd2hl
cmUgb3V0cHV0IHByZWRpY3Rpb25zIHNob3VsZAogYmUgd3JpdHRlbi4KCg0KBQQCAgIGEgTX
AQIaCg0KBQQCAgIBEgTXARsoCg0KBQQCAgIDEgTXASssCg0KBQQCAgIIEgTXAS1VChAKCAQC
AgIInAgAEgTXAS5UCtkZCgQEAgIDEgStAgIhGsoZIEFkZGl0aW9uYWwgZG9tYWluLXNwZWNp
ZmljIHBhcmFtZXRlcnMgZm9yIHRoZSBwcmVkaWN0aW9ucywgYW55IHN0cmluZyBtdXN0CiBi
ZSB1cCB0byAyNTAwMCBjaGFyYWN0ZXJzIGxvbmcuCgogQXV0b01MIE5hdHVyYWwgTGFuZ3Vh
Z2UgQ2xhc3NpZmljYXRpb24KCiBgc2NvcmVfdGhyZXNob2xkYAogOiAoZmxvYXQpIEEgdmFs
dWUgZnJvbSAwLjAgdG8gMS4wLiBXaGVuIHRoZSBtb2RlbAogICBtYWtlcyBwcmVkaWN0aW9u
cyBmb3IgYSB0ZXh0IHNuaXBwZXQsIGl0IHdpbGwgb25seSBwcm9kdWNlIHJlc3VsdHMKICAg
dGhhdCBoYXZlIGF0IGxlYXN0IHRoaXMgY29uZmlkZW5jZSBzY29yZS4gVGhlIGRlZmF1bHQg
aXMgMC41LgoKCiBBdXRvTUwgVmlzaW9uIENsYXNzaWZpY2F0aW9uCgogYHNjb3JlX3RocmVz
aG9sZGAKIDogKGZsb2F0KSBBIHZhbHVlIGZyb20gMC4wIHRvIDEuMC4gV2hlbiB0aGUgbW9k
ZWwKICAgbWFrZXMgcHJlZGljdGlvbnMgZm9yIGFuIGltYWdlLCBpdCB3aWxsIG9ubHkgcHJv
ZHVjZSByZXN1bHRzIHRoYXQKICAgaGF2ZSBhdCBsZWFzdCB0aGlzIGNvbmZpZGVuY2Ugc2Nv
cmUuIFRoZSBkZWZhdWx0IGlzIDAuNS4KCiBBdXRvTUwgVmlzaW9uIE9iamVjdCBEZXRlY3Rp
b24KCiBgc2NvcmVfdGhyZXNob2xkYAogOiAoZmxvYXQpIFdoZW4gTW9kZWwgZGV0ZWN0cyBv
YmplY3RzIG9uIHRoZSBpbWFnZSwKICAgaXQgd2lsbCBvbmx5IHByb2R1Y2UgYm91bmRpbmcg
Ym94ZXMgd2hpY2ggaGF2ZSBhdCBsZWFzdCB0aGlzCiAgIGNvbmZpZGVuY2Ugc2NvcmUuIFZh
bHVlIGluIDAgdG8gMSByYW5nZSwgZGVmYXVsdCBpcyAwLjUuCgogYG1heF9ib3VuZGluZ19i
b3hfY291bnRgCiA6IChpbnQ2NCkgVGhlIG1heGltdW0gbnVtYmVyIG9mIGJvdW5kaW5nCiAg
IGJveGVzIHJldHVybmVkIHBlciBpbWFnZS4gVGhlIGRlZmF1bHQgaXMgMTAwLCB0aGUKICAg
bnVtYmVyIG9mIGJvdW5kaW5nIGJveGVzIHJldHVybmVkIG1pZ2h0IGJlIGxpbWl0ZWQgYnkg
dGhlIHNlcnZlci4KIEF1dG9NTCBWaWRlbyBJbnRlbGxpZ2VuY2UgQ2xhc3NpZmljYXRpb24K
CiBgc2NvcmVfdGhyZXNob2xkYAogOiAoZmxvYXQpIEEgdmFsdWUgZnJvbSAwLjAgdG8gMS4w
LiBXaGVuIHRoZSBtb2RlbAogICBtYWtlcyBwcmVkaWN0aW9ucyBmb3IgYSB2aWRlbywgaXQg
d2lsbCBvbmx5IHByb2R1Y2UgcmVzdWx0cyB0aGF0CiAgIGhhdmUgYXQgbGVhc3QgdGhpcyBj
b25maWRlbmNlIHNjb3JlLiBUaGUgZGVmYXVsdCBpcyAwLjUuCgogYHNlZ21lbnRfY2xhc3Np
ZmljYXRpb25gCiA6IChib29sZWFuKSBTZXQgdG8gdHJ1ZSB0byByZXF1ZXN0CiAgIHNlZ21l
bnQtbGV2ZWwgY2xhc3NpZmljYXRpb24uIEF1dG9NTCBWaWRlbyBJbnRlbGxpZ2VuY2UgcmV0
dXJucwogICBsYWJlbHMgYW5kIHRoZWlyIGNvbmZpZGVuY2Ugc2NvcmVzIGZvciB0aGUgZW50
aXJlIHNlZ21lbnQgb2YgdGhlCiAgIHZpZGVvIHRoYXQgdXNlciBzcGVjaWZpZWQgaW4gdGhl
IHJlcXVlc3QgY29uZmlndXJhdGlvbi4KICAgVGhlIGRlZmF1bHQgaXMgdHJ1ZS4KCiBgc2hv
dF9jbGFzc2lmaWNhdGlvbmAKIDogKGJvb2xlYW4pIFNldCB0byB0cnVlIHRvIHJlcXVlc3Qg
c2hvdC1sZXZlbAogICBjbGFzc2lmaWNhdGlvbi4gQXV0b01MIFZpZGVvIEludGVsbGlnZW5j
ZSBkZXRlcm1pbmVzIHRoZSBib3VuZGFyaWVzCiAgIGZvciBlYWNoIGNhbWVyYSBzaG90IGlu
IHRoZSBlbnRpcmUgc2VnbWVudCBvZiB0aGUgdmlkZW8gdGhhdCB1c2VyCiAgIHNwZWNpZmll
ZCBpbiB0aGUgcmVxdWVzdCBjb25maWd1cmF0aW9uLiBBdXRvTUwgVmlkZW8gSW50ZWxsaWdl
bmNlCiAgIHRoZW4gcmV0dXJucyBsYWJlbHMgYW5kIHRoZWlyIGNvbmZpZGVuY2Ugc2NvcmVz
IGZvciBlYWNoIGRldGVjdGVkCiAgIHNob3QsIGFsb25nIHdpdGggdGhlIHN0YXJ0IGFuZCBl
bmQgdGltZSBvZiB0aGUgc2hvdC4KICAgVGhlIGRlZmF1bHQgaXMgZmFsc2UuCgogICBXQVJO
SU5HOiBNb2RlbCBldmFsdWF0aW9uIGlzIG5vdCBkb25lIGZvciB0aGlzIGNsYXNzaWZpY2F0
aW9uIHR5cGUsCiAgIHRoZSBxdWFsaXR5IG9mIGl0IGRlcGVuZHMgb24gdHJhaW5pbmcgZGF0
YSwgYnV0IHRoZXJlIGFyZSBubyBtZXRyaWNzCiAgIHByb3ZpZGVkIHRvIGRlc2NyaWJlIHRo
YXQgcXVhbGl0eS4KCiBgMXNfaW50ZXJ2YWxfY2xhc3NpZmljYXRpb25gCiA6IChib29sZWFu
KSBTZXQgdG8gdHJ1ZSB0byByZXF1ZXN0CiAgIGNsYXNzaWZpY2F0aW9uIGZvciBhIHZpZGVv
IGF0IG9uZS1zZWNvbmQgaW50ZXJ2YWxzLiBBdXRvTUwgVmlkZW8KICAgSW50ZWxsaWdlbmNl
IHJldHVybnMgbGFiZWxzIGFuZCB0aGVpciBjb25maWRlbmNlIHNjb3JlcyBmb3IgZWFjaAog
ICBzZWNvbmQgb2YgdGhlIGVudGlyZSBzZWdtZW50IG9mIHRoZSB2aWRlbyB0aGF0IHVzZXIg
c3BlY2lmaWVkIGluIHRoZQogICByZXF1ZXN0IGNvbmZpZ3VyYXRpb24uIFRoZSBkZWZhdWx0
IGlzIGZhbHNlLgoKICAgV0FSTklORzogTW9kZWwgZXZhbHVhdGlvbiBpcyBub3QgZG9uZSBm
b3IgdGhpcyBjbGFzc2lmaWNhdGlvbgogICB0eXBlLCB0aGUgcXVhbGl0eSBvZiBpdCBkZXBl
bmRzIG9uIHRyYWluaW5nIGRhdGEsIGJ1dCB0aGVyZSBhcmUgbm8KICAgbWV0cmljcyBwcm92
aWRlZCB0byBkZXNjcmliZSB0aGF0IHF1YWxpdHkuCgogQXV0b01MIFZpZGVvIEludGVsbGln
ZW5jZSBPYmplY3QgVHJhY2tpbmcKCiBgc2NvcmVfdGhyZXNob2xkYAogOiAoZmxvYXQpIFdo
ZW4gTW9kZWwgZGV0ZWN0cyBvYmplY3RzIG9uIHZpZGVvIGZyYW1lcywKICAgaXQgd2lsbCBv
bmx5IHByb2R1Y2UgYm91bmRpbmcgYm94ZXMgd2hpY2ggaGF2ZSBhdCBsZWFzdCB0aGlzCiAg
IGNvbmZpZGVuY2Ugc2NvcmUuIFZhbHVlIGluIDAgdG8gMSByYW5nZSwgZGVmYXVsdCBpcyAw
LjUuCgogYG1heF9ib3VuZGluZ19ib3hfY291bnRgCiA6IChpbnQ2NCkgVGhlIG1heGltdW0g
bnVtYmVyIG9mIGJvdW5kaW5nCiAgIGJveGVzIHJldHVybmVkIHBlciBpbWFnZS4gVGhlIGRl
ZmF1bHQgaXMgMTAwLCB0aGUKICAgbnVtYmVyIG9mIGJvdW5kaW5nIGJveGVzIHJldHVybmVk
IG1pZ2h0IGJlIGxpbWl0ZWQgYnkgdGhlIHNlcnZlci4KCiBgbWluX2JvdW5kaW5nX2JveF9z
aXplYAogOiAoZmxvYXQpIE9ubHkgYm91bmRpbmcgYm94ZXMgd2l0aCBzaG9ydGVzdCBlZGdl
CiAgIGF0IGxlYXN0IHRoYXQgbG9uZyBhcyBhIHJlbGF0aXZlIHZhbHVlIG9mIHZpZGVvIGZy
YW1lIHNpemUgYXJlCiAgIHJldHVybmVkLiBWYWx1ZSBpbiAwIHRvIDEgcmFuZ2UuIERlZmF1
bHQgaXMgMC4KCgoNCgUEAgIDBhIErQICFQoNCgUEAgIDARIErQIWHAoNCgUEAgIDAxIErQIf
IAr3AQoCBAMSBrMCAMACARroASBSZXN1bHQgb2YgdGhlIEJhdGNoIFByZWRpY3QuIFRoaXMg
bWVzc2FnZSBpcyByZXR1cm5lZCBpbgogW3Jlc3BvbnNlXVtnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uLnJlc3BvbnNlXSBvZiB0aGUgb3BlcmF0aW9uIHJldHVybmVkCiBieSB0aGUg
W1ByZWRpY3Rpb25TZXJ2aWNlLkJhdGNoUHJlZGljdF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MS5QcmVkaWN0aW9uU2VydmljZS5CYXRjaFByZWRpY3RdLgoKCwoDBAMBEgSzAggaCtQCCgQE
AwIAEgS/AgIjGsUCIEFkZGl0aW9uYWwgZG9tYWluLXNwZWNpZmljIHByZWRpY3Rpb24gcmVz
cG9uc2UgbWV0YWRhdGEuCgogQXV0b01MIFZpc2lvbiBPYmplY3QgRGV0ZWN0aW9uCgogYG1h
eF9ib3VuZGluZ19ib3hfY291bnRgCiA6IChpbnQ2NCkgVGhlIG1heGltdW0gbnVtYmVyIG9m
IGJvdW5kaW5nIGJveGVzIHJldHVybmVkIHBlciBpbWFnZS4KCiBBdXRvTUwgVmlkZW8gSW50
ZWxsaWdlbmNlIE9iamVjdCBUcmFja2luZwoKIGBtYXhfYm91bmRpbmdfYm94X2NvdW50YAog
OiAoaW50NjQpIFRoZSBtYXhpbXVtIG51bWJlciBvZiBib3VuZGluZyBib3hlcyByZXR1cm5l
ZCBwZXIgZnJhbWUuCgoNCgUEAwIABhIEvwICFQoNCgUEAwIAARIEvwIWHgoNCgUEAwIAAxIE
vwIhImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: name Type: 9 ()
    # Field: payload Type: 11 (.google.cloud.automl.v1.ExamplePayload)
    # Field: params Type: 11 (.google.cloud.automl.v1.PredictRequest.ParamsEntry)

# === Message: Google::Cloud::Automl::V1::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: payload Type: 11 (.google.cloud.automl.v1.AnnotationPayload)
    # Field: preprocessed_input Type: 11 (.google.cloud.automl.v1.ExamplePayload)
    # Field: metadata Type: 11 (.google.cloud.automl.v1.PredictResponse.MetadataEntry)

# === Message: Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest ===
    # Fields for BatchPredictRequest
    # Field: name Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.automl.v1.BatchPredictInputConfig)
    # Field: output_config Type: 11 (.google.cloud.automl.v1.BatchPredictOutputConfig)
    # Field: params Type: 11 (.google.cloud.automl.v1.BatchPredictRequest.ParamsEntry)

# === Message: Google::Cloud::Automl::V1::PredictionService::BatchPredictResult ===
    # Fields for BatchPredictResult
    # Field: metadata Type: 11 (.google.cloud.automl.v1.BatchPredictResult.MetadataEntry)

# === Service Client: Google::Cloud::Automl::V1::PredictionService::PredictionServiceClient ===
package Google::Cloud::Automl::V1::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Automl::V1::PredictionService::PredictionServiceClient

Client stub representing the remote C<PredictionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<automl.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'automl.googleapis.com:443' );

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Automl::V1::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.automl.v1.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Cloud::Automl::V1::PredictionService::PredictResponse',
    });
}

sub batch_predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.automl.v1.PredictionService',
        method         => 'BatchPredict',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::PredictionService - Compiled Protocol Buffers messages for google/cloud/automl/v1/prediction_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::PredictionService;

    my $msg = Google::Cloud::Automl::V1::PredictionService::PredictRequest->new({
        name => $name,
        payload => $payload,
        params => $params,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::PredictionService::PredictRequest

Request message for [PredictionService.Predict][google.cloud.automl.v1.PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the model requested to serve the prediction.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::ExamplePayload>)

Required. Payload to perform a prediction on. The payload must match the
problem type that the model was trained to solve.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::PredictionService::PredictRequest::ParamsEntry>)

Additional domain-specific parameters, any string must be up to 25000
characters long.

AutoML Vision Classification

`score_threshold`
: (float) A value from 0.0 to 1.0. When the model
  makes predictions for an image, it will only produce results that have
  at least this confidence score. The default is 0.5.

AutoML Vision Object Detection

`score_threshold`
: (float) When Model detects objects on the image,
  it will only produce bounding boxes which have at least this
  confidence score. Value in 0 to 1 range, default is 0.5.

`max_bounding_box_count`
: (int64) The maximum number of bounding
  boxes returned. The default is 100. The
  number of returned bounding boxes might be limited by the server.

AutoML Tables

`feature_importance`
: (boolean) Whether
[feature_importance][google.cloud.automl.v1.TablesModelColumnInfo.feature_importance]
  is populated in the returned list of
  [TablesAnnotation][google.cloud.automl.v1.TablesAnnotation]
  objects. The default is false.

=back

=head2 Google::Cloud::Automl::V1::PredictionService::PredictResponse

Response message for [PredictionService.Predict][google.cloud.automl.v1.PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::AnnotationPayload::AnnotationPayload>)

Prediction result.
AutoML Translation and AutoML Natural Language Sentiment Analysis
return precisely one payload.

=item * C<< $msg->preprocessed_input() >> / C<< $msg->preprocessed_input($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::ExamplePayload>)

The preprocessed example that AutoML actually makes prediction on.
Empty if AutoML does not preprocess the input example.

For AutoML Natural Language (Classification, Entity Extraction, and
Sentiment Analysis), if the input is a document, the recognized text is
returned in the
[document_text][google.cloud.automl.v1.Document.document_text]
property.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::PredictionService::PredictResponse::MetadataEntry>)

Additional domain-specific prediction response metadata.

AutoML Vision Object Detection

`max_bounding_box_count`
: (int64) The maximum number of bounding boxes to return per image.

AutoML Natural Language Sentiment Analysis

`sentiment_score`
: (float, deprecated) A value between -1 and 1,
  -1 maps to least positive sentiment, while 1 maps to the most positive
  one and the higher the score, the more positive the sentiment in the
  document is. Yet these values are relative to the training data, so
  e.g. if all data was positive then -1 is also positive (though
  the least).
  `sentiment_score` is not the same as "score" and "magnitude"
  from Sentiment Analysis in the Natural Language API.

=back

=head2 Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest

Request message for [PredictionService.BatchPredict][google.cloud.automl.v1.PredictionService.BatchPredict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the model requested to serve the batch prediction.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Io::BatchPredictInputConfig>)

Required. The input configuration for batch prediction.

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Io::BatchPredictOutputConfig>)

Required. The Configuration specifying where output predictions should
be written.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest::ParamsEntry>)

Additional domain-specific parameters for the predictions, any string must
be up to 25000 characters long.

AutoML Natural Language Classification

`score_threshold`
: (float) A value from 0.0 to 1.0. When the model
  makes predictions for a text snippet, it will only produce results
  that have at least this confidence score. The default is 0.5.


AutoML Vision Classification

`score_threshold`
: (float) A value from 0.0 to 1.0. When the model
  makes predictions for an image, it will only produce results that
  have at least this confidence score. The default is 0.5.

AutoML Vision Object Detection

`score_threshold`
: (float) When Model detects objects on the image,
  it will only produce bounding boxes which have at least this
  confidence score. Value in 0 to 1 range, default is 0.5.

`max_bounding_box_count`
: (int64) The maximum number of bounding
  boxes returned per image. The default is 100, the
  number of bounding boxes returned might be limited by the server.
AutoML Video Intelligence Classification

`score_threshold`
: (float) A value from 0.0 to 1.0. When the model
  makes predictions for a video, it will only produce results that
  have at least this confidence score. The default is 0.5.

`segment_classification`
: (boolean) Set to true to request
  segment-level classification. AutoML Video Intelligence returns
  labels and their confidence scores for the entire segment of the
  video that user specified in the request configuration.
  The default is true.

`shot_classification`
: (boolean) Set to true to request shot-level
  classification. AutoML Video Intelligence determines the boundaries
  for each camera shot in the entire segment of the video that user
  specified in the request configuration. AutoML Video Intelligence
  then returns labels and their confidence scores for each detected
  shot, along with the start and end time of the shot.
  The default is false.

  WARNING: Model evaluation is not done for this classification type,
  the quality of it depends on training data, but there are no metrics
  provided to describe that quality.

`1s_interval_classification`
: (boolean) Set to true to request
  classification for a video at one-second intervals. AutoML Video
  Intelligence returns labels and their confidence scores for each
  second of the entire segment of the video that user specified in the
  request configuration. The default is false.

  WARNING: Model evaluation is not done for this classification
  type, the quality of it depends on training data, but there are no
  metrics provided to describe that quality.

AutoML Video Intelligence Object Tracking

`score_threshold`
: (float) When Model detects objects on video frames,
  it will only produce bounding boxes which have at least this
  confidence score. Value in 0 to 1 range, default is 0.5.

`max_bounding_box_count`
: (int64) The maximum number of bounding
  boxes returned per image. The default is 100, the
  number of bounding boxes returned might be limited by the server.

`min_bounding_box_size`
: (float) Only bounding boxes with shortest edge
  at least that long as a relative value of video frame size are
  returned. Value in 0 to 1 range. Default is 0.


=back

=head2 Google::Cloud::Automl::V1::PredictionService::BatchPredictResult

Result of the Batch Predict. This message is returned in
[response][google.longrunning.Operation.response] of the operation returned
by the [PredictionService.BatchPredict][google.cloud.automl.v1.PredictionService.BatchPredict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::PredictionService::BatchPredictResult::MetadataEntry>)

Additional domain-specific prediction response metadata.

AutoML Vision Object Detection

`max_bounding_box_count`
: (int64) The maximum number of bounding boxes returned per image.

AutoML Video Intelligence Object Tracking

`max_bounding_box_count`
: (int64) The maximum number of bounding boxes returned per frame.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
