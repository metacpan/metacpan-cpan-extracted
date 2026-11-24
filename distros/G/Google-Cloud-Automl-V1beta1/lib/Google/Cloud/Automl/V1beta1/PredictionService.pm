package Google::Cloud::Automl::V1beta1::PredictionService;

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
    eval { require Google::Cloud::Automl::V1beta1::AnnotationPayload };
    eval { require Google::Cloud::Automl::V1beta1::DataItems };
    eval { require Google::Cloud::Automl::V1beta1::Io };
    eval { require Google::Cloud::Automl::V1beta1::Operations };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvcHJlZGljdGlvbl9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29nbGUvY2xvdWQvYXV0
b21sL3YxYmV0YTEvYW5ub3RhdGlvbl9wYXlsb2FkLnByb3RvGixnb29nbGUvY2xvdWQvYXV0
b21sL3YxYmV0YTEvZGF0YV9pdGVtcy5wcm90bxokZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJl
dGExL2lvLnByb3RvGixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvb3BlcmF0aW9ucy5w
cm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8ioQIKDlByZWRpY3RS
ZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobYXV0b21sLmdvb2dsZWFwaXMuY29tL01v
ZGVsUgRuYW1lEkoKB3BheWxvYWQYAiABKAsyKy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuRXhhbXBsZVBheWxvYWRCA+BBAlIHcGF5bG9hZBJPCgZwYXJhbXMYAyADKAsyNy5nb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuUHJlZGljdFJlcXVlc3QuUGFyYW1zRW50cnlSBnBh
cmFtcxo5CgtQYXJhbXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBIswCCg9QcmVkaWN0UmVzcG9uc2USSAoHcGF5bG9hZBgBIAMoCzIuLmdvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Bbm5vdGF0aW9uUGF5bG9hZFIHcGF5bG9hZBJaChJw
cmVwcm9jZXNzZWRfaW5wdXQYAyABKAsyKy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
RXhhbXBsZVBheWxvYWRSEXByZXByb2Nlc3NlZElucHV0ElYKCG1ldGFkYXRhGAIgAygLMjou
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlByZWRpY3RSZXNwb25zZS5NZXRhZGF0YUVu
dHJ5UghtZXRhZGF0YRo7Cg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZh
bHVlGAIgASgJUgV2YWx1ZToCOAEiowMKE0JhdGNoUHJlZGljdFJlcXVlc3QSNwoEbmFtZRgB
IAEoCUIj4EEC+kEdChthdXRvbWwuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBG5hbWUSXAoMaW5w
dXRfY29uZmlnGAMgASgLMjQuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkJhdGNoUHJl
ZGljdElucHV0Q29uZmlnQgPgQQJSC2lucHV0Q29uZmlnEl8KDW91dHB1dF9jb25maWcYBCAB
KAsyNS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQmF0Y2hQcmVkaWN0T3V0cHV0Q29u
ZmlnQgPgQQJSDG91dHB1dENvbmZpZxJZCgZwYXJhbXMYBSADKAsyPC5nb29nbGUuY2xvdWQu
YXV0b21sLnYxYmV0YTEuQmF0Y2hQcmVkaWN0UmVxdWVzdC5QYXJhbXNFbnRyeUID4EECUgZw
YXJhbXMaOQoLUGFyYW1zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ASKsAQoSQmF0Y2hQcmVkaWN0UmVzdWx0ElkKCG1ldGFkYXRhGAEgAygLMj0u
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkJhdGNoUHJlZGljdFJlc3VsdC5NZXRhZGF0
YUVudHJ5UghtZXRhZGF0YRo7Cg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAEyngQKEVByZWRpY3Rpb25TZXJ2aWNlEr4BCgdQcmVk
aWN0EisuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlByZWRpY3RSZXF1ZXN0GiwuZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlByZWRpY3RSZXNwb25zZSJYgtPkkwI8IjcvdjFi
ZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL21vZGVscy8qfTpwcmVkaWN0OgEq
2kETbmFtZSxwYXlsb2FkLHBhcmFtcxL8AQoMQmF0Y2hQcmVkaWN0EjAuZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MWJldGExLkJhdGNoUHJlZGljdFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIpoBgtPkkwJBIjwvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL21vZGVscy8qfTpiYXRjaFByZWRpY3Q6ASraQSZuYW1lLGlucHV0X2NvbmZpZyxv
dXRwdXRfY29uZmlnLHBhcmFtc8pBJwoSQmF0Y2hQcmVkaWN0UmVzdWx0EhFPcGVyYXRpb25N
ZXRhZGF0YRpJykEVYXV0b21sLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKzAQofY29tLmdvb2dsZS5jbG91ZC5hdXRv
bWwudjFiZXRhMUIWUHJlZGljdGlvblNlcnZpY2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29t
L2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3Vk
XEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSsZWCgcS
BQ4AiwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPgoJ
CgIDBRIDFwA2CgkKAgMGEgMYAC4KCQoCAwcSAxkANgoJCgIDCBIDGgAtCggKAQgSAxwATgoJ
CgIICxIDHABOCggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4ANwoJCgIICBIDHgA3CggK
AQgSAx8AOAoJCgIIARIDHwA4CggKAQgSAyAAOAoJCgIIKRIDIAA4CggKAQgSAyEANwoJCgII
LRIDIQA3CqUBCgIGABIEJwBdARqYASBBdXRvTUwgUHJlZGljdGlvbiBBUEkuCgogT24gYW55
IGlucHV0IHRoYXQgaXMgZG9jdW1lbnRlZCB0byBleHBlY3QgYSBzdHJpbmcgcGFyYW1ldGVy
IGluCiBzbmFrZV9jYXNlIG9yIGtlYmFiLWNhc2UsIGVpdGhlciBvZiB0aG9zZSBjYXNlcyBp
cyBhY2NlcHRlZC4KCgoKAwYAARIDJwgZCgoKAwYAAxIDKAI9CgwKBQYAA5kIEgMoAj0KCgoD
BgADEgMpAlYKDAoFBgADmggSAykCVgqMCAoEBgACABIEPgJEAxr9ByBQZXJmb3JtIGFuIG9u
bGluZSBwcmVkaWN0aW9uLiBUaGUgcHJlZGljdGlvbiByZXN1bHQgd2lsbCBiZSBkaXJlY3Rs
eQogcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlLgogQXZhaWxhYmxlIGZvciBmb2xsb3dpbmcg
TUwgcHJvYmxlbXMsIGFuZCB0aGVpciBleHBlY3RlZCByZXF1ZXN0IHBheWxvYWRzOgogKiBJ
bWFnZSBDbGFzc2lmaWNhdGlvbiAtIEltYWdlIGluIC5KUEVHLCAuR0lGIG9yIC5QTkcgZm9y
bWF0LCBpbWFnZV9ieXRlcwogICAgICAgICAgICAgICAgICAgICAgICAgIHVwIHRvIDMwTUIu
CiAqIEltYWdlIE9iamVjdCBEZXRlY3Rpb24gLSBJbWFnZSBpbiAuSlBFRywgLkdJRiBvciAu
UE5HIGZvcm1hdCwgaW1hZ2VfYnl0ZXMKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVw
IHRvIDMwTUIuCiAqIFRleHQgQ2xhc3NpZmljYXRpb24gLSBUZXh0U25pcHBldCwgY29udGVu
dCB1cCB0byA2MCwwMDAgY2hhcmFjdGVycywKICAgICAgICAgICAgICAgICAgICAgICAgIFVU
Ri04IGVuY29kZWQuCiAqIFRleHQgRXh0cmFjdGlvbiAtIFRleHRTbmlwcGV0LCBjb250ZW50
IHVwIHRvIDMwLDAwMCBjaGFyYWN0ZXJzLAogICAgICAgICAgICAgICAgICAgICBVVEYtOCBO
RkMgZW5jb2RlZC4KICogVHJhbnNsYXRpb24gLSBUZXh0U25pcHBldCwgY29udGVudCB1cCB0
byAyNSwwMDAgY2hhcmFjdGVycywgVVRGLTgKICAgICAgICAgICAgICAgICBlbmNvZGVkLgog
KiBUYWJsZXMgLSBSb3csIHdpdGggY29sdW1uIHZhbHVlcyBtYXRjaGluZyB0aGUgY29sdW1u
cyBvZiB0aGUgbW9kZWwsCiAgICAgICAgICAgIHVwIHRvIDVNQi4gTm90IGF2YWlsYWJsZSBm
b3IgRk9SRUNBU1RJTkcKCiBbcHJlZGljdGlvbl90eXBlXVtnb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuVGFibGVzTW9kZWxNZXRhZGF0YS5wcmVkaWN0aW9uX3R5cGVdLgogKiBUZXh0
IFNlbnRpbWVudCAtIFRleHRTbmlwcGV0LCBjb250ZW50IHVwIDUwMCBjaGFyYWN0ZXJzLCBV
VEYtOAogICAgICAgICAgICAgICAgICAgICBlbmNvZGVkLgoKDAoFBgACAAESAz4GDQoMCgUG
AAIAAhIDPg4cCgwKBQYAAgADEgM+JzYKDQoFBgACAAQSBD8EQgYKEQoJBgACAASwyrwiEgQ/
BEIGCgwKBQYAAgAEEgNDBEEKDwoIBgACAASbCAASA0MEQQq/BQoEBgACARIEUgJcAxqwBSBQ
ZXJmb3JtIGEgYmF0Y2ggcHJlZGljdGlvbi4gVW5saWtlIHRoZSBvbmxpbmUgW1ByZWRpY3Rd
W2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5QcmVkaWN0aW9uU2VydmljZS5QcmVkaWN0
XSwgYmF0Y2gKIHByZWRpY3Rpb24gcmVzdWx0IHdvbid0IGJlIGltbWVkaWF0ZWx5IGF2YWls
YWJsZSBpbiB0aGUgcmVzcG9uc2UuIEluc3RlYWQsCiBhIGxvbmcgcnVubmluZyBvcGVyYXRp
b24gb2JqZWN0IGlzIHJldHVybmVkLiBVc2VyIGNhbiBwb2xsIHRoZSBvcGVyYXRpb24KIHJl
c3VsdCB2aWEgW0dldE9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMu
R2V0T3BlcmF0aW9uXQogbWV0aG9kLiBPbmNlIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgW0Jh
dGNoUHJlZGljdFJlc3VsdF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkJhdGNoUHJl
ZGljdFJlc3VsdF0gaXMgcmV0dXJuZWQgaW4KIHRoZSBbcmVzcG9uc2VdW2dvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24ucmVzcG9uc2VdIGZpZWxkLgogQXZhaWxhYmxlIGZvciBmb2xs
b3dpbmcgTUwgcHJvYmxlbXM6CiAqIEltYWdlIENsYXNzaWZpY2F0aW9uCiAqIEltYWdlIE9i
amVjdCBEZXRlY3Rpb24KICogVmlkZW8gQ2xhc3NpZmljYXRpb24KICogVmlkZW8gT2JqZWN0
IFRyYWNraW5nICogVGV4dCBFeHRyYWN0aW9uCiAqIFRhYmxlcwoKDAoFBgACAQESA1IGEgoM
CgUGAAIBAhIDUhMmCgwKBQYAAgEDEgNSMU0KDQoFBgACAQQSBFMEVgYKEQoJBgACAQSwyrwi
EgRTBFYGCgwKBQYAAgEEEgNXBFQKDwoIBgACAQSbCAASA1cEVAoNCgUGAAIBBBIEWARbBgoP
CgcGAAIBBJkIEgRYBFsGCnYKAgQAEgVgAIIBARppIFJlcXVlc3QgbWVzc2FnZSBmb3IgW1By
ZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Q
cmVkaWN0aW9uU2VydmljZS5QcmVkaWN0XS4KCgoKAwQAARIDYAgWCk4KBAQAAgASBGICZwQa
QCBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgbW9kZWwgcmVxdWVzdGVkIHRvIHNlcnZlIHRoZSBw
cmVkaWN0aW9uLgoKDAoFBAACAAUSA2ICCAoMCgUEAAIAARIDYgkNCgwKBQQAAgADEgNiEBEK
DQoFBAACAAgSBGISZwMKDwoIBAACAAicCAASA2MEKgoPCgcEAAIACJ8IEgRkBGYFCooBCgQE
AAIBEgNrAkYafSBSZXF1aXJlZC4gUGF5bG9hZCB0byBwZXJmb3JtIGEgcHJlZGljdGlvbiBv
bi4gVGhlIHBheWxvYWQgbXVzdCBtYXRjaCB0aGUKIHByb2JsZW0gdHlwZSB0aGF0IHRoZSBt
b2RlbCB3YXMgdHJhaW5lZCB0byBzb2x2ZS4KCgwKBQQAAgEGEgNrAhAKDAoFBAACAQESA2sR
GAoMCgUEAAIBAxIDaxscCgwKBQQAAgEIEgNrHUUKDwoIBAACAQicCAASA2seRAq/BwoEBAAC
AhIEgQECIRqwByBBZGRpdGlvbmFsIGRvbWFpbi1zcGVjaWZpYyBwYXJhbWV0ZXJzLCBhbnkg
c3RyaW5nIG11c3QgYmUgdXAgdG8gMjUwMDAKIGNoYXJhY3RlcnMgbG9uZy4KCiAqICBGb3Ig
SW1hZ2UgQ2xhc3NpZmljYXRpb246CgogICAgYHNjb3JlX3RocmVzaG9sZGAgLSAoZmxvYXQp
IEEgdmFsdWUgZnJvbSAwLjAgdG8gMS4wLiBXaGVuIHRoZSBtb2RlbAogICAgIG1ha2VzIHBy
ZWRpY3Rpb25zIGZvciBhbiBpbWFnZSwgaXQgd2lsbCBvbmx5IHByb2R1Y2UgcmVzdWx0cyB0
aGF0IGhhdmUKICAgICBhdCBsZWFzdCB0aGlzIGNvbmZpZGVuY2Ugc2NvcmUuIFRoZSBkZWZh
dWx0IGlzIDAuNS4KCiAgKiAgRm9yIEltYWdlIE9iamVjdCBEZXRlY3Rpb246CiAgICBgc2Nv
cmVfdGhyZXNob2xkYCAtIChmbG9hdCkgV2hlbiBNb2RlbCBkZXRlY3RzIG9iamVjdHMgb24g
dGhlIGltYWdlLAogICAgICAgIGl0IHdpbGwgb25seSBwcm9kdWNlIGJvdW5kaW5nIGJveGVz
IHdoaWNoIGhhdmUgYXQgbGVhc3QgdGhpcwogICAgICAgIGNvbmZpZGVuY2Ugc2NvcmUuIFZh
bHVlIGluIDAgdG8gMSByYW5nZSwgZGVmYXVsdCBpcyAwLjUuCiAgICBgbWF4X2JvdW5kaW5n
X2JveF9jb3VudGAgLSAoaW50NjQpIE5vIG1vcmUgdGhhbiB0aGlzIG51bWJlciBvZiBib3Vu
ZGluZwogICAgICAgIGJveGVzIHdpbGwgYmUgcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlLiBE
ZWZhdWx0IGlzIDEwMCwgdGhlCiAgICAgICAgcmVxdWVzdGVkIHZhbHVlIG1heSBiZSBsaW1p
dGVkIGJ5IHNlcnZlci4KICogIEZvciBUYWJsZXM6CiAgICBmZWF0dXJlX2ltcDxzcGFuPm9y
dGFuPC9zcGFuPmNlIC0gKGJvb2xlYW4pIFdoZXRoZXIgZmVhdHVyZSBpbXBvcnRhbmNlCiAg
ICAgICAgc2hvdWxkIGJlIHBvcHVsYXRlZCBpbiB0aGUgcmV0dXJuZWQgVGFibGVzQW5ub3Rh
dGlvbi4KICAgICAgICBUaGUgZGVmYXVsdCBpcyBmYWxzZS4KCg0KBQQAAgIGEgSBAQIVCg0K
BQQAAgIBEgSBARYcCg0KBQQAAgIDEgSBAR8gCngKAgQBEgaFAQChAQEaaiBSZXNwb25zZSBt
ZXNzYWdlIGZvciBbUHJlZGljdGlvblNlcnZpY2UuUHJlZGljdF1bZ29vZ2xlLmNsb3VkLmF1
dG9tbC52MWJldGExLlByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgoKCwoDBAEBEgSFAQgX
CmUKBAQBAgASBIgBAikaVyBQcmVkaWN0aW9uIHJlc3VsdC4KIFRyYW5zbGF0aW9uIGFuZCBU
ZXh0IFNlbnRpbWVudCB3aWxsIHJldHVybiBwcmVjaXNlbHkgb25lIHBheWxvYWQuCgoNCgUE
AQIABBIEiAECCgoNCgUEAQIABhIEiAELHAoNCgUEAQIAARIEiAEdJAoNCgUEAQIAAxIEiAEn
KAqvAgoEBAECARIEjwECKBqgAiBUaGUgcHJlcHJvY2Vzc2VkIGV4YW1wbGUgdGhhdCBBdXRv
TUwgYWN0dWFsbHkgbWFrZXMgcHJlZGljdGlvbiBvbi4KIEVtcHR5IGlmIEF1dG9NTCBkb2Vz
IG5vdCBwcmVwcm9jZXNzIHRoZSBpbnB1dCBleGFtcGxlLgogKiBGb3IgVGV4dCBFeHRyYWN0
aW9uOgogICBJZiB0aGUgaW5wdXQgaXMgYSAucGRmIGZpbGUsIHRoZSBPQ1InZWQgdGV4dCB3
aWxsIGJlIHByb3ZpZGVkIGluCiAgIFtkb2N1bWVudF90ZXh0XVtnb29nbGUuY2xvdWQuYXV0
b21sLnYxYmV0YTEuRG9jdW1lbnQuZG9jdW1lbnRfdGV4dF0uCgoNCgUEAQIBBhIEjwECEAoN
CgUEAQIBARIEjwERIwoNCgUEAQIBAxIEjwEmJwqABgoEBAECAhIEoAECIxrxBSBBZGRpdGlv
bmFsIGRvbWFpbi1zcGVjaWZpYyBwcmVkaWN0aW9uIHJlc3BvbnNlIG1ldGFkYXRhLgoKICog
Rm9yIEltYWdlIE9iamVjdCBEZXRlY3Rpb246CiAgYG1heF9ib3VuZGluZ19ib3hfY291bnRg
IC0gKGludDY0KSBBdCBtb3N0IHRoYXQgbWFueSBib3VuZGluZyBib3hlcyBwZXIKICAgICAg
aW1hZ2UgY291bGQgaGF2ZSBiZWVuIHJldHVybmVkLgoKICogRm9yIFRleHQgU2VudGltZW50
OgogIGBzZW50aW1lbnRfc2NvcmVgIC0gKGZsb2F0LCBkZXByZWNhdGVkKSBBIHZhbHVlIGJl
dHdlZW4gLTEgYW5kIDEsCiAgICAgIC0xIG1hcHMgdG8gbGVhc3QgcG9zaXRpdmUgc2VudGlt
ZW50LCB3aGlsZSAxIG1hcHMgdG8gdGhlIG1vc3QgcG9zaXRpdmUKICAgICAgb25lIGFuZCB0
aGUgaGlnaGVyIHRoZSBzY29yZSwgdGhlIG1vcmUgcG9zaXRpdmUgdGhlIHNlbnRpbWVudCBp
biB0aGUKICAgICAgZG9jdW1lbnQgaXMuIFlldCB0aGVzZSB2YWx1ZXMgYXJlIHJlbGF0aXZl
IHRvIHRoZSB0cmFpbmluZyBkYXRhLCBzbwogICAgICBlLmcuIGlmIGFsbCBkYXRhIHdhcyBw
b3NpdGl2ZSB0aGVuIC0xIHdpbGwgYmUgYWxzbyBwb3NpdGl2ZSAodGhvdWdoCiAgICAgIHRo
ZSBsZWFzdCkuCiAgICAgIFRoZSBzZW50aW1lbnRfc2NvcmUgc2hvdWxkbid0IGJlIGNvbmZ1
c2VkIHdpdGggInNjb3JlIiBvciAibWFnbml0dWRlIgogICAgICBmcm9tIHRoZSBwcmV2aW91
cyBOYXR1cmFsIExhbmd1YWdlIFNlbnRpbWVudCBBbmFseXNpcyBBUEkuCgoNCgUEAQICBhIE
oAECFQoNCgUEAQICARIEoAEWHgoNCgUEAQICAxIEoAEhIgqBAQoCBAISBqQBAPsBARpzIFJl
cXVlc3QgbWVzc2FnZSBmb3IgW1ByZWRpY3Rpb25TZXJ2aWNlLkJhdGNoUHJlZGljdF1bZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlByZWRpY3Rpb25TZXJ2aWNlLkJhdGNoUHJlZGlj
dF0uCgoLCgMEAgESBKQBCBsKVgoEBAICABIGpgECqwEEGkYgUmVxdWlyZWQuIE5hbWUgb2Yg
dGhlIG1vZGVsIHJlcXVlc3RlZCB0byBzZXJ2ZSB0aGUgYmF0Y2ggcHJlZGljdGlvbi4KCg0K
BQQCAgAFEgSmAQIICg0KBQQCAgABEgSmAQkNCg0KBQQCAgADEgSmARARCg8KBQQCAgAIEgam
ARKrAQMKEAoIBAICAAicCAASBKcBBCoKEQoHBAICAAifCBIGqAEEqgEFCkcKBAQCAgESBK4B
AlQaOSBSZXF1aXJlZC4gVGhlIGlucHV0IGNvbmZpZ3VyYXRpb24gZm9yIGJhdGNoIHByZWRp
Y3Rpb24uCgoNCgUEAgIBBhIErgECGQoNCgUEAgIBARIErgEaJgoNCgUEAgIBAxIErgEpKgoN
CgUEAgIBCBIErgErUwoQCggEAgIBCJwIABIErgEsUgpjCgQEAgICEgSyAQJWGlUgUmVxdWly
ZWQuIFRoZSBDb25maWd1cmF0aW9uIHNwZWNpZnlpbmcgd2hlcmUgb3V0cHV0IHByZWRpY3Rp
b25zIHNob3VsZAogYmUgd3JpdHRlbi4KCg0KBQQCAgIGEgSyAQIaCg0KBQQCAgIBEgSyARso
Cg0KBQQCAgIDEgSyASssCg0KBQQCAgIIEgSyAS1VChAKCAQCAgIInAgAEgSyAS5UCqocCgQE
AgIDEgT6AQJKGpscIFJlcXVpcmVkLiBBZGRpdGlvbmFsIGRvbWFpbi1zcGVjaWZpYyBwYXJh
bWV0ZXJzIGZvciB0aGUgcHJlZGljdGlvbnMsIGFueSBzdHJpbmcgbXVzdAogYmUgdXAgdG8g
MjUwMDAgY2hhcmFjdGVycyBsb25nLgoKICogIEZvciBUZXh0IENsYXNzaWZpY2F0aW9uOgoK
ICAgIGBzY29yZV90aHJlc2hvbGRgIC0gKGZsb2F0KSBBIHZhbHVlIGZyb20gMC4wIHRvIDEu
MC4gV2hlbiB0aGUgbW9kZWwKICAgICAgICAgbWFrZXMgcHJlZGljdGlvbnMgZm9yIGEgdGV4
dCBzbmlwcGV0LCBpdCB3aWxsIG9ubHkgcHJvZHVjZSByZXN1bHRzCiAgICAgICAgIHRoYXQg
aGF2ZSBhdCBsZWFzdCB0aGlzIGNvbmZpZGVuY2Ugc2NvcmUuIFRoZSBkZWZhdWx0IGlzIDAu
NS4KCiAqICBGb3IgSW1hZ2UgQ2xhc3NpZmljYXRpb246CgogICAgYHNjb3JlX3RocmVzaG9s
ZGAgLSAoZmxvYXQpIEEgdmFsdWUgZnJvbSAwLjAgdG8gMS4wLiBXaGVuIHRoZSBtb2RlbAog
ICAgICAgICBtYWtlcyBwcmVkaWN0aW9ucyBmb3IgYW4gaW1hZ2UsIGl0IHdpbGwgb25seSBw
cm9kdWNlIHJlc3VsdHMgdGhhdAogICAgICAgICBoYXZlIGF0IGxlYXN0IHRoaXMgY29uZmlk
ZW5jZSBzY29yZS4gVGhlIGRlZmF1bHQgaXMgMC41LgoKICogIEZvciBJbWFnZSBPYmplY3Qg
RGV0ZWN0aW9uOgoKICAgIGBzY29yZV90aHJlc2hvbGRgIC0gKGZsb2F0KSBXaGVuIE1vZGVs
IGRldGVjdHMgb2JqZWN0cyBvbiB0aGUgaW1hZ2UsCiAgICAgICAgaXQgd2lsbCBvbmx5IHBy
b2R1Y2UgYm91bmRpbmcgYm94ZXMgd2hpY2ggaGF2ZSBhdCBsZWFzdCB0aGlzCiAgICAgICAg
Y29uZmlkZW5jZSBzY29yZS4gVmFsdWUgaW4gMCB0byAxIHJhbmdlLCBkZWZhdWx0IGlzIDAu
NS4KICAgIGBtYXhfYm91bmRpbmdfYm94X2NvdW50YCAtIChpbnQ2NCkgTm8gbW9yZSB0aGFu
IHRoaXMgbnVtYmVyIG9mIGJvdW5kaW5nCiAgICAgICAgYm94ZXMgd2lsbCBiZSBwcm9kdWNl
ZCBwZXIgaW1hZ2UuIERlZmF1bHQgaXMgMTAwLCB0aGUKICAgICAgICByZXF1ZXN0ZWQgdmFs
dWUgbWF5IGJlIGxpbWl0ZWQgYnkgc2VydmVyLgoKICogIEZvciBWaWRlbyBDbGFzc2lmaWNh
dGlvbiA6CgogICAgYHNjb3JlX3RocmVzaG9sZGAgLSAoZmxvYXQpIEEgdmFsdWUgZnJvbSAw
LjAgdG8gMS4wLiBXaGVuIHRoZSBtb2RlbAogICAgICAgIG1ha2VzIHByZWRpY3Rpb25zIGZv
ciBhIHZpZGVvLCBpdCB3aWxsIG9ubHkgcHJvZHVjZSByZXN1bHRzIHRoYXQKICAgICAgICBo
YXZlIGF0IGxlYXN0IHRoaXMgY29uZmlkZW5jZSBzY29yZS4gVGhlIGRlZmF1bHQgaXMgMC41
LgogICAgYHNlZ21lbnRfY2xhc3NpZmljYXRpb25gIC0gKGJvb2xlYW4pIFNldCB0byB0cnVl
IHRvIHJlcXVlc3QKICAgICAgICBzZWdtZW50LWxldmVsIGNsYXNzaWZpY2F0aW9uLiBBdXRv
TUwgVmlkZW8gSW50ZWxsaWdlbmNlIHJldHVybnMKICAgICAgICBsYWJlbHMgYW5kIHRoZWly
IGNvbmZpZGVuY2Ugc2NvcmVzIGZvciB0aGUgZW50aXJlIHNlZ21lbnQgb2YgdGhlCiAgICAg
ICAgdmlkZW8gdGhhdCB1c2VyIHNwZWNpZmllZCBpbiB0aGUgcmVxdWVzdCBjb25maWd1cmF0
aW9uLgogICAgICAgIFRoZSBkZWZhdWx0IGlzICJ0cnVlIi4KICAgIGBzaG90X2NsYXNzaWZp
Y2F0aW9uYCAtIChib29sZWFuKSBTZXQgdG8gdHJ1ZSB0byByZXF1ZXN0IHNob3QtbGV2ZWwK
ICAgICAgICBjbGFzc2lmaWNhdGlvbi4gQXV0b01MIFZpZGVvIEludGVsbGlnZW5jZSBkZXRl
cm1pbmVzIHRoZSBib3VuZGFyaWVzCiAgICAgICAgZm9yIGVhY2ggY2FtZXJhIHNob3QgaW4g
dGhlIGVudGlyZSBzZWdtZW50IG9mIHRoZSB2aWRlbyB0aGF0IHVzZXIKICAgICAgICBzcGVj
aWZpZWQgaW4gdGhlIHJlcXVlc3QgY29uZmlndXJhdGlvbi4gQXV0b01MIFZpZGVvIEludGVs
bGlnZW5jZQogICAgICAgIHRoZW4gcmV0dXJucyBsYWJlbHMgYW5kIHRoZWlyIGNvbmZpZGVu
Y2Ugc2NvcmVzIGZvciBlYWNoIGRldGVjdGVkCiAgICAgICAgc2hvdCwgYWxvbmcgd2l0aCB0
aGUgc3RhcnQgYW5kIGVuZCB0aW1lIG9mIHRoZSBzaG90LgogICAgICAgIFdBUk5JTkc6IE1v
ZGVsIGV2YWx1YXRpb24gaXMgbm90IGRvbmUgZm9yIHRoaXMgY2xhc3NpZmljYXRpb24gdHlw
ZSwKICAgICAgICB0aGUgcXVhbGl0eSBvZiBpdCBkZXBlbmRzIG9uIHRyYWluaW5nIGRhdGEs
IGJ1dCB0aGVyZSBhcmUgbm8gbWV0cmljcwogICAgICAgIHByb3ZpZGVkIHRvIGRlc2NyaWJl
IHRoYXQgcXVhbGl0eS4gVGhlIGRlZmF1bHQgaXMgImZhbHNlIi4KICAgIGAxc19pbnRlcnZh
bF9jbGFzc2lmaWNhdGlvbmAgLSAoYm9vbGVhbikgU2V0IHRvIHRydWUgdG8gcmVxdWVzdAog
ICAgICAgIGNsYXNzaWZpY2F0aW9uIGZvciBhIHZpZGVvIGF0IG9uZS1zZWNvbmQgaW50ZXJ2
YWxzLiBBdXRvTUwgVmlkZW8KICAgICAgICBJbnRlbGxpZ2VuY2UgcmV0dXJucyBsYWJlbHMg
YW5kIHRoZWlyIGNvbmZpZGVuY2Ugc2NvcmVzIGZvciBlYWNoCiAgICAgICAgc2Vjb25kIG9m
IHRoZSBlbnRpcmUgc2VnbWVudCBvZiB0aGUgdmlkZW8gdGhhdCB1c2VyIHNwZWNpZmllZCBp
biB0aGUKICAgICAgICByZXF1ZXN0IGNvbmZpZ3VyYXRpb24uCiAgICAgICAgV0FSTklORzog
TW9kZWwgZXZhbHVhdGlvbiBpcyBub3QgZG9uZSBmb3IgdGhpcyBjbGFzc2lmaWNhdGlvbgog
ICAgICAgIHR5cGUsIHRoZSBxdWFsaXR5IG9mIGl0IGRlcGVuZHMgb24gdHJhaW5pbmcgZGF0
YSwgYnV0IHRoZXJlIGFyZSBubwogICAgICAgIG1ldHJpY3MgcHJvdmlkZWQgdG8gZGVzY3Jp
YmUgdGhhdCBxdWFsaXR5LiBUaGUgZGVmYXVsdCBpcwogICAgICAgICJmYWxzZSIuCgogKiAg
Rm9yIFRhYmxlczoKCiAgICBmZWF0dXJlX2ltcDxzcGFuPm9ydGFuPC9zcGFuPmNlIC0gKGJv
b2xlYW4pIFdoZXRoZXIgZmVhdHVyZSBpbXBvcnRhbmNlCiAgICAgICAgc2hvdWxkIGJlIHBv
cHVsYXRlZCBpbiB0aGUgcmV0dXJuZWQgVGFibGVzQW5ub3RhdGlvbnMuIFRoZQogICAgICAg
IGRlZmF1bHQgaXMgZmFsc2UuCgogKiAgRm9yIFZpZGVvIE9iamVjdCBUcmFja2luZzoKCiAg
ICBgc2NvcmVfdGhyZXNob2xkYCAtIChmbG9hdCkgV2hlbiBNb2RlbCBkZXRlY3RzIG9iamVj
dHMgb24gdmlkZW8gZnJhbWVzLAogICAgICAgIGl0IHdpbGwgb25seSBwcm9kdWNlIGJvdW5k
aW5nIGJveGVzIHdoaWNoIGhhdmUgYXQgbGVhc3QgdGhpcwogICAgICAgIGNvbmZpZGVuY2Ug
c2NvcmUuIFZhbHVlIGluIDAgdG8gMSByYW5nZSwgZGVmYXVsdCBpcyAwLjUuCiAgICBgbWF4
X2JvdW5kaW5nX2JveF9jb3VudGAgLSAoaW50NjQpIE5vIG1vcmUgdGhhbiB0aGlzIG51bWJl
ciBvZiBib3VuZGluZwogICAgICAgIGJveGVzIHdpbGwgYmUgcmV0dXJuZWQgcGVyIGZyYW1l
LiBEZWZhdWx0IGlzIDEwMCwgdGhlIHJlcXVlc3RlZAogICAgICAgIHZhbHVlIG1heSBiZSBs
aW1pdGVkIGJ5IHNlcnZlci4KICAgIGBtaW5fYm91bmRpbmdfYm94X3NpemVgIC0gKGZsb2F0
KSBPbmx5IGJvdW5kaW5nIGJveGVzIHdpdGggc2hvcnRlc3QgZWRnZQogICAgICBhdCBsZWFz
dCB0aGF0IGxvbmcgYXMgYSByZWxhdGl2ZSB2YWx1ZSBvZiB2aWRlbyBmcmFtZSBzaXplIHdp
bGwgYmUKICAgICAgcmV0dXJuZWQuIFZhbHVlIGluIDAgdG8gMSByYW5nZS4gRGVmYXVsdCBp
cyAwLgoKDQoFBAICAwYSBPoBAhUKDQoFBAICAwESBPoBFhwKDQoFBAICAwMSBPoBHyAKDQoF
BAICAwgSBPoBIUkKEAoIBAICAwicCAASBPoBIkgK/AEKAgQDEgaAAgCLAgEa7QEgUmVzdWx0
IG9mIHRoZSBCYXRjaCBQcmVkaWN0LiBUaGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgaW4KIFty
ZXNwb25zZV1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5yZXNwb25zZV0gb2YgdGhl
IG9wZXJhdGlvbiByZXR1cm5lZAogYnkgdGhlIFtQcmVkaWN0aW9uU2VydmljZS5CYXRjaFBy
ZWRpY3RdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5QcmVkaWN0aW9uU2VydmljZS5C
YXRjaFByZWRpY3RdLgoKCwoDBAMBEgSAAggaCuoCCgQEAwIAEgSKAgIjGtsCIEFkZGl0aW9u
YWwgZG9tYWluLXNwZWNpZmljIHByZWRpY3Rpb24gcmVzcG9uc2UgbWV0YWRhdGEuCgogKiAg
Rm9yIEltYWdlIE9iamVjdCBEZXRlY3Rpb246CiAgYG1heF9ib3VuZGluZ19ib3hfY291bnRg
IC0gKGludDY0KSBBdCBtb3N0IHRoYXQgbWFueSBib3VuZGluZyBib3hlcyBwZXIKICAgICAg
aW1hZ2UgY291bGQgaGF2ZSBiZWVuIHJldHVybmVkLgoKICogIEZvciBWaWRlbyBPYmplY3Qg
VHJhY2tpbmc6CiAgYG1heF9ib3VuZGluZ19ib3hfY291bnRgIC0gKGludDY0KSBBdCBtb3N0
IHRoYXQgbWFueSBib3VuZGluZyBib3hlcyBwZXIKICAgICAgZnJhbWUgY291bGQgaGF2ZSBi
ZWVuIHJldHVybmVkLgoKDQoFBAMCAAYSBIoCAhUKDQoFBAMCAAESBIoCFh4KDQoFBAMCAAMS
BIoCISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: name Type: 9 ()
    # Field: payload Type: 11 (.google.cloud.automl.v1beta1.ExamplePayload)
    # Field: params Type: 11 (.google.cloud.automl.v1beta1.PredictRequest.ParamsEntry)

# === Message: Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: payload Type: 11 (.google.cloud.automl.v1beta1.AnnotationPayload)
    # Field: preprocessed_input Type: 11 (.google.cloud.automl.v1beta1.ExamplePayload)
    # Field: metadata Type: 11 (.google.cloud.automl.v1beta1.PredictResponse.MetadataEntry)

# === Message: Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictRequest ===
    # Fields for BatchPredictRequest
    # Field: name Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.automl.v1beta1.BatchPredictInputConfig)
    # Field: output_config Type: 11 (.google.cloud.automl.v1beta1.BatchPredictOutputConfig)
    # Field: params Type: 11 (.google.cloud.automl.v1beta1.BatchPredictRequest.ParamsEntry)

# === Message: Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictResult ===
    # Fields for BatchPredictResult
    # Field: metadata Type: 11 (.google.cloud.automl.v1beta1.BatchPredictResult.MetadataEntry)

# === Service Client: Google::Cloud::Automl::V1beta1::PredictionService::PredictionServiceClient ===
package Google::Cloud::Automl::V1beta1::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Automl::V1beta1::PredictionService::PredictionServiceClient

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
        ? Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.automl.v1beta1.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse',
    });
}

sub batch_predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.automl.v1beta1.PredictionService',
        method         => 'BatchPredict',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::PredictionService - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/prediction_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::PredictionService;

    my $msg = Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest->new({
        name => $name,
        payload => $payload,
        params => $params,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest

Request message for [PredictionService.Predict][google.cloud.automl.v1beta1.PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the model requested to serve the prediction.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload>)

Required. Payload to perform a prediction on. The payload must match the
problem type that the model was trained to solve.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest::ParamsEntry>)

Additional domain-specific parameters, any string must be up to 25000
characters long.

*  For Image Classification:

   `score_threshold` - (float) A value from 0.0 to 1.0. When the model
    makes predictions for an image, it will only produce results that have
    at least this confidence score. The default is 0.5.

 *  For Image Object Detection:
   `score_threshold` - (float) When Model detects objects on the image,
       it will only produce bounding boxes which have at least this
       confidence score. Value in 0 to 1 range, default is 0.5.
   `max_bounding_box_count` - (int64) No more than this number of bounding
       boxes will be returned in the response. Default is 100, the
       requested value may be limited by server.
*  For Tables:
   feature_imp<span>ortan</span>ce - (boolean) Whether feature importance
       should be populated in the returned TablesAnnotation.
       The default is false.

=back

=head2 Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse

Response message for [PredictionService.Predict][google.cloud.automl.v1beta1.PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload>)

Prediction result.
Translation and Text Sentiment will return precisely one payload.

=item * C<< $msg->preprocessed_input() >> / C<< $msg->preprocessed_input($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload>)

The preprocessed example that AutoML actually makes prediction on.
Empty if AutoML does not preprocess the input example.
* For Text Extraction:
  If the input is a .pdf file, the OCR'ed text will be provided in
  [document_text][google.cloud.automl.v1beta1.Document.document_text].

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse::MetadataEntry>)

Additional domain-specific prediction response metadata.

* For Image Object Detection:
 `max_bounding_box_count` - (int64) At most that many bounding boxes per
     image could have been returned.

* For Text Sentiment:
 `sentiment_score` - (float, deprecated) A value between -1 and 1,
     -1 maps to least positive sentiment, while 1 maps to the most positive
     one and the higher the score, the more positive the sentiment in the
     document is. Yet these values are relative to the training data, so
     e.g. if all data was positive then -1 will be also positive (though
     the least).
     The sentiment_score shouldn't be confused with "score" or "magnitude"
     from the previous Natural Language Sentiment Analysis API.

=back

=head2 Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictRequest

Request message for [PredictionService.BatchPredict][google.cloud.automl.v1beta1.PredictionService.BatchPredict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the model requested to serve the batch prediction.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::BatchPredictInputConfig>)

Required. The input configuration for batch prediction.

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::BatchPredictOutputConfig>)

Required. The Configuration specifying where output predictions should
be written.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictRequest::ParamsEntry>)

Required. Additional domain-specific parameters for the predictions, any string must
be up to 25000 characters long.

*  For Text Classification:

   `score_threshold` - (float) A value from 0.0 to 1.0. When the model
        makes predictions for a text snippet, it will only produce results
        that have at least this confidence score. The default is 0.5.

*  For Image Classification:

   `score_threshold` - (float) A value from 0.0 to 1.0. When the model
        makes predictions for an image, it will only produce results that
        have at least this confidence score. The default is 0.5.

*  For Image Object Detection:

   `score_threshold` - (float) When Model detects objects on the image,
       it will only produce bounding boxes which have at least this
       confidence score. Value in 0 to 1 range, default is 0.5.
   `max_bounding_box_count` - (int64) No more than this number of bounding
       boxes will be produced per image. Default is 100, the
       requested value may be limited by server.

*  For Video Classification :

   `score_threshold` - (float) A value from 0.0 to 1.0. When the model
       makes predictions for a video, it will only produce results that
       have at least this confidence score. The default is 0.5.
   `segment_classification` - (boolean) Set to true to request
       segment-level classification. AutoML Video Intelligence returns
       labels and their confidence scores for the entire segment of the
       video that user specified in the request configuration.
       The default is "true".
   `shot_classification` - (boolean) Set to true to request shot-level
       classification. AutoML Video Intelligence determines the boundaries
       for each camera shot in the entire segment of the video that user
       specified in the request configuration. AutoML Video Intelligence
       then returns labels and their confidence scores for each detected
       shot, along with the start and end time of the shot.
       WARNING: Model evaluation is not done for this classification type,
       the quality of it depends on training data, but there are no metrics
       provided to describe that quality. The default is "false".
   `1s_interval_classification` - (boolean) Set to true to request
       classification for a video at one-second intervals. AutoML Video
       Intelligence returns labels and their confidence scores for each
       second of the entire segment of the video that user specified in the
       request configuration.
       WARNING: Model evaluation is not done for this classification
       type, the quality of it depends on training data, but there are no
       metrics provided to describe that quality. The default is
       "false".

*  For Tables:

   feature_imp<span>ortan</span>ce - (boolean) Whether feature importance
       should be populated in the returned TablesAnnotations. The
       default is false.

*  For Video Object Tracking:

   `score_threshold` - (float) When Model detects objects on video frames,
       it will only produce bounding boxes which have at least this
       confidence score. Value in 0 to 1 range, default is 0.5.
   `max_bounding_box_count` - (int64) No more than this number of bounding
       boxes will be returned per frame. Default is 100, the requested
       value may be limited by server.
   `min_bounding_box_size` - (float) Only bounding boxes with shortest edge
     at least that long as a relative value of video frame size will be
     returned. Value in 0 to 1 range. Default is 0.

=back

=head2 Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictResult

Result of the Batch Predict. This message is returned in
[response][google.longrunning.Operation.response] of the operation returned
by the [PredictionService.BatchPredict][google.cloud.automl.v1beta1.PredictionService.BatchPredict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::PredictionService::BatchPredictResult::MetadataEntry>)

Additional domain-specific prediction response metadata.

*  For Image Object Detection:
 `max_bounding_box_count` - (int64) At most that many bounding boxes per
     image could have been returned.

*  For Video Object Tracking:
 `max_bounding_box_count` - (int64) At most that many bounding boxes per
     frame could have been returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
