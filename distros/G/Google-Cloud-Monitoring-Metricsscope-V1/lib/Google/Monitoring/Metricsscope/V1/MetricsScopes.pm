package Google::Monitoring::Metricsscope::V1::MetricsScopes;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Monitoring::Metricsscope::V1::MetricsScope };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvbW9uaXRvcmluZy9tZXRyaWNzc2NvcGUvdjEvbWV0cmljc19zY29wZXMucHJv
dG8SIWdvb2dsZS5tb25pdG9yaW5nLm1ldHJpY3NzY29wZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9s
b25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGjVnb29nbGUvbW9uaXRvcmluZy9tZXRyaWNz
c2NvcGUvdjEvbWV0cmljc19zY29wZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byJcChZHZXRNZXRyaWNzU2NvcGVSZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpB
KAombW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9NZXRyaWNzU2NvcGVSBG5hbWUicwoqTGlz
dE1ldHJpY3NTY29wZXNCeU1vbml0b3JlZFByb2plY3RSZXF1ZXN0EkUKHG1vbml0b3JlZF9y
ZXNvdXJjZV9jb250YWluZXIYASABKAlCA+BBAlIabW9uaXRvcmVkUmVzb3VyY2VDb250YWlu
ZXIihQEKK0xpc3RNZXRyaWNzU2NvcGVzQnlNb25pdG9yZWRQcm9qZWN0UmVzcG9uc2USVgoO
bWV0cmljc19zY29wZXMYASADKAsyLy5nb29nbGUubW9uaXRvcmluZy5tZXRyaWNzc2NvcGUu
djEuTWV0cmljc1Njb3BlUg1tZXRyaWNzU2NvcGVzIs4BCh1DcmVhdGVNb25pdG9yZWRQcm9q
ZWN0UmVxdWVzdBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKAombW9uaXRvcmluZy5nb29nbGVh
cGlzLmNvbS9NZXRyaWNzU2NvcGVSBnBhcmVudBJlChFtb25pdG9yZWRfcHJvamVjdBgCIAEo
CzIzLmdvb2dsZS5tb25pdG9yaW5nLm1ldHJpY3NzY29wZS52MS5Nb25pdG9yZWRQcm9qZWN0
QgPgQQJSEG1vbml0b3JlZFByb2plY3QiZwodRGVsZXRlTW9uaXRvcmVkUHJvamVjdFJlcXVl
c3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCiptb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL01v
bml0b3JlZFByb2plY3RSBG5hbWUisgIKEU9wZXJhdGlvbk1ldGFkYXRhElAKBXN0YXRlGAEg
ASgOMjouZ29vZ2xlLm1vbml0b3JpbmcubWV0cmljc3Njb3BlLnYxLk9wZXJhdGlvbk1ldGFk
YXRhLlN0YXRlUgVzdGF0ZRI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYBiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIlEKBVN0YXRlEhUKEVNUQVRFX1VOU1BF
Q0lGSUVEEAASCwoHQ1JFQVRFRBABEgsKB1JVTk5JTkcQAhIICgRET05FEAMSDQoJQ0FOQ0VM
TEVEEAQywgkKDU1ldHJpY3NTY29wZXMSuQEKD0dldE1ldHJpY3NTY29wZRI5Lmdvb2dsZS5t
b25pdG9yaW5nLm1ldHJpY3NzY29wZS52MS5HZXRNZXRyaWNzU2NvcGVSZXF1ZXN0Gi8uZ29v
Z2xlLm1vbml0b3JpbmcubWV0cmljc3Njb3BlLnYxLk1ldHJpY3NTY29wZSI6gtPkkwItEisv
djEve25hbWU9bG9jYXRpb25zL2dsb2JhbC9tZXRyaWNzU2NvcGVzLyp92kEEbmFtZRKUAgoj
TGlzdE1ldHJpY3NTY29wZXNCeU1vbml0b3JlZFByb2plY3QSTS5nb29nbGUubW9uaXRvcmlu
Zy5tZXRyaWNzc2NvcGUudjEuTGlzdE1ldHJpY3NTY29wZXNCeU1vbml0b3JlZFByb2plY3RS
ZXF1ZXN0Gk4uZ29vZ2xlLm1vbml0b3JpbmcubWV0cmljc3Njb3BlLnYxLkxpc3RNZXRyaWNz
U2NvcGVzQnlNb25pdG9yZWRQcm9qZWN0UmVzcG9uc2UiToLT5JMCSBJGL3YxL2xvY2F0aW9u
cy9nbG9iYWwvbWV0cmljc1Njb3BlczpsaXN0TWV0cmljc1Njb3Blc0J5TW9uaXRvcmVkUHJv
amVjdBKQAgoWQ3JlYXRlTW9uaXRvcmVkUHJvamVjdBJALmdvb2dsZS5tb25pdG9yaW5nLm1l
dHJpY3NzY29wZS52MS5DcmVhdGVNb25pdG9yZWRQcm9qZWN0UmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24ilAGC0+STAksiNi92MS97cGFyZW50PWxvY2F0aW9ucy9n
bG9iYWwvbWV0cmljc1Njb3Blcy8qfS9wcm9qZWN0czoRbW9uaXRvcmVkX3Byb2plY3TaQRhw
YXJlbnQsbW9uaXRvcmVkX3Byb2plY3TKQSUKEE1vbml0b3JlZFByb2plY3QSEU9wZXJhdGlv
bk1ldGFkYXRhEu0BChZEZWxldGVNb25pdG9yZWRQcm9qZWN0EkAuZ29vZ2xlLm1vbml0b3Jp
bmcubWV0cmljc3Njb3BlLnYxLkRlbGV0ZU1vbml0b3JlZFByb2plY3RSZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJygtPkkwI4KjYvdjEve25hbWU9bG9jYXRpb25z
L2dsb2JhbC9tZXRyaWNzU2NvcGVzLyovcHJvamVjdHMvKn3aQQRuYW1lykEqChVnb29nbGUu
cHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhGtoBykEZbW9uaXRvcmluZy5nb29n
bGVhcGlzLmNvbdJBugFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBs
YXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRvcmluZyxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3JpbmcucmVhZCxodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3Jpbmcud3JpdGVCkAIKJWNvbS5nb29nbGUu
bW9uaXRvcmluZy5tZXRyaWNzc2NvcGUudjFCEk1ldHJpY3NTY29wZXNQcm90b1ABWk9jbG91
ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvbWV0cmljc3Njb3BlL2FwaXYxL21ldHJpY3Nz
Y29wZXBiO21ldHJpY3NzY29wZXBiqgInR29vZ2xlLkNsb3VkLk1vbml0b3JpbmcuTWV0cmlj
c1Njb3BlLlYxygInR29vZ2xlXENsb3VkXE1vbml0b3JpbmdcTWV0cmljc1Njb3BlXFYx6gIr
R29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6TWV0cmljc1Njb3BlOjpWMUqCJwoHEgUOALYB
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC0KCQoCAwUS
AxcAPwoJCgIDBhIDGAApCggKAQgSAxoAZgoJCgIICxIDGgBmCggKAQgSAxsAIgoJCgIIChID
GwAiCggKAQgSAxwAMwoJCgIICBIDHAAzCggKAQgSAx0APgoJCgIIARIDHQA+CggKAQgSAx4A
RAoJCgIIJRIDHgBECggKAQgSAx8ARQoJCgIIKRIDHwBFCggKAQgSAyAARAoJCgIILRIDIABE
CnUKAgYAEgQkAFYBGmkgTWFuYWdlcyBDbG91ZCBNb25pdG9yaW5nIE1ldHJpY3MgU2NvcGVz
LCBhbmQgdGhlIG1vbml0b3Jpbmcgb2YgR29vZ2xlIENsb3VkCiBwcm9qZWN0cyBhbmQgQVdT
IGFjY291bnRzLgoKCgoDBgABEgMkCBUKCgoDBgADEgMlAkEKDAoFBgADmQgSAyUCQQoLCgMG
AAMSBCYCKjkKDQoFBgADmggSBCYCKjkKMwoEBgACABIELQIyAxolIFJldHVybnMgYSBzcGVj
aWZpYyBgTWV0cmljcyBTY29wZWAuCgoMCgUGAAIAARIDLQYVCgwKBQYAAgACEgMtFiwKDAoF
BgACAAMSAy03QwoNCgUGAAIABBIELgQwBgoRCgkGAAIABLDKvCISBC4EMAYKDAoFBgACAAQS
AzEEMgoPCggGAAIABJsIABIDMQQyCt8BCgQGAAIBEgQ3AjsDGtABIFJldHVybnMgYSBsaXN0
IG9mIGV2ZXJ5IGBNZXRyaWNzIFNjb3BlYCB0aGF0IGEgc3BlY2lmaWMgYE1vbml0b3JlZFBy
b2plY3RgCiBoYXMgYmVlbiBhZGRlZCB0by4gVGhlIG1ldHJpY3Mgc2NvcGUgcmVwcmVzZW50
aW5nIHRoZSBzcGVjaWZpZWQgbW9uaXRvcmVkCiBwcm9qZWN0IHdpbGwgYWx3YXlzIGJlIHRo
ZSBmaXJzdCBlbnRyeSBpbiB0aGUgcmVzcG9uc2UuCgoMCgUGAAIBARIDNwYpCgwKBQYAAgEC
EgM3KlQKDQoFBgACAQMSBDdfigEKDQoFBgACAQQSBDgEOgYKEQoJBgACAQSwyrwiEgQ4BDoG
CmYKBAYAAgISBD8CSQMaWCBBZGRzIGEgYE1vbml0b3JlZFByb2plY3RgIHdpdGggdGhlIGdp
dmVuIHByb2plY3QgSUQKIHRvIHRoZSBzcGVjaWZpZWQgYE1ldHJpY3MgU2NvcGVgLgoKDAoF
BgACAgESAz8GHAoMCgUGAAICAhIDPx06CgwKBQYAAgIDEgM/RWEKDQoFBgACAgQSBEAEQwYK
EQoJBgACAgSwyrwiEgRABEMGCgwKBQYAAgIEEgNEBEYKDwoIBgACAgSbCAASA0QERgoNCgUG
AAICBBIERQRIBgoPCgcGAAICBJkIEgRFBEgGClAKBAYAAgMSBEwCVQMaQiBEZWxldGVzIGEg
YE1vbml0b3JlZFByb2plY3RgIGZyb20gdGhlIHNwZWNpZmllZCBgTWV0cmljcyBTY29wZWAu
CgoMCgUGAAIDARIDTAYcCgwKBQYAAgMCEgNMHToKDAoFBgACAwMSA0xFYQoNCgUGAAIDBBIE
TQRPBgoRCgkGAAIDBLDKvCISBE0ETwYKDAoFBgACAwQSA1AEMgoPCggGAAIDBJsIABIDUAQy
Cg0KBQYAAgMEEgRRBFQGCg8KBwYAAgMEmQgSBFEEVAYKNwoCBAASBFkAYwEaKyBSZXF1ZXN0
IGZvciB0aGUgYEdldE1ldHJpY3NTY29wZWAgbWV0aG9kLgoKCgoDBAABEgNZCB4KjwEKBAQA
AgASBF0CYgQagAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBgTWV0cmlj
cyBTY29wZWAuCiBFeGFtcGxlOgogYGxvY2F0aW9ucy9nbG9iYWwvbWV0cmljc1Njb3Blcy97
U0NPUElOR19QUk9KRUNUX0lEX09SX05VTUJFUn1gCgoMCgUEAAIABRIDXQIICgwKBQQAAgAB
EgNdCQ0KDAoFBAACAAMSA10QEQoNCgUEAAIACBIEXRJiAwoPCggEAAIACJwIABIDXgQqCg8K
BwQAAgAInwgSBF8EYQUKSwoCBAESBGYAawEaPyBSZXF1ZXN0IGZvciB0aGUgYExpc3RNZXRy
aWNzU2NvcGVzQnlNb25pdG9yZWRQcm9qZWN0YCBtZXRob2QuCgoKCgMEAQESA2YIMgqOAQoE
BAECABIDagJTGoABIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYE1vbml0
b3JlZCBQcm9qZWN0YCBiZWluZyByZXF1ZXN0ZWQuCiBFeGFtcGxlOgogYHByb2plY3RzL3tN
T05JVE9SRURfUFJPSkVDVF9JRF9PUl9OVU1CRVJ9YAoKDAoFBAECAAUSA2oCCAoMCgUEAQIA
ARIDagklCgwKBQQBAgADEgNqKCkKDAoFBAECAAgSA2oqUgoPCggEAQIACJwIABIDaitRCkwK
AgQCEgRuAHIBGkAgUmVzcG9uc2UgZm9yIHRoZSBgTGlzdE1ldHJpY3NTY29wZXNCeU1vbml0
b3JlZFByb2plY3RgIG1ldGhvZC4KCgoKAwQCARIDbggzCmMKBAQCAgASA3ECKxpWIEEgc2V0
IG9mIGFsbCBtZXRyaWNzIHNjb3BlcyB0aGF0IHRoZSBzcGVjaWZpZWQgbW9uaXRvcmVkIHBy
b2plY3QgaGFzIGJlZW4KIGFkZGVkIHRvLgoKDAoFBAICAAQSA3ECCgoMCgUEAgIABhIDcQsX
CgwKBQQCAgABEgNxGCYKDAoFBAICAAMSA3EpKgo/CgIEAxIFdQCGAQEaMiBSZXF1ZXN0IGZv
ciB0aGUgYENyZWF0ZU1vbml0b3JlZFByb2plY3RgIG1ldGhvZC4KCgoKAwQDARIDdQglCrgB
CgQEAwIAEgR6An8EGqkBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZXhp
c3RpbmcgYE1ldHJpY3MgU2NvcGVgIHRoYXQgd2lsbCBtb25pdG9yIHRoaXMKIHByb2plY3Qu
CiBFeGFtcGxlOgogYGxvY2F0aW9ucy9nbG9iYWwvbWV0cmljc1Njb3Blcy97U0NPUElOR19Q
Uk9KRUNUX0lEX09SX05VTUJFUn1gCgoMCgUEAwIABRIDegIICgwKBQQDAgABEgN6CQ8KDAoF
BAMCAAMSA3oSEwoNCgUEAwIACBIEehR/AwoPCggEAwIACJwIABIDewQqCg8KBwQDAgAInwgS
BHwEfgUKuAIKBAQDAgESBIUBAlIaqQIgUmVxdWlyZWQuIFRoZSBpbml0aWFsIGBNb25pdG9y
ZWRQcm9qZWN0YCBjb25maWd1cmF0aW9uLgogU3BlY2lmeSBvbmx5IHRoZSBgbW9uaXRvcmVk
X3Byb2plY3QubmFtZWAgZmllbGQuIEFsbCBvdGhlciBmaWVsZHMgYXJlCiBpZ25vcmVkLiBU
aGUgYG1vbml0b3JlZF9wcm9qZWN0Lm5hbWVgIG11c3QgYmUgaW4gdGhlIGZvcm1hdDoKIGBs
b2NhdGlvbnMvZ2xvYmFsL21ldHJpY3NTY29wZXMve1NDT1BJTkdfUFJPSkVDVF9JRF9PUl9O
VU1CRVJ9L3Byb2plY3RzL3tNT05JVE9SRURfUFJPSkVDVF9JRF9PUl9OVU1CRVJ9YAoKDQoF
BAMCAQYSBIUBAhIKDQoFBAMCAQESBIUBEyQKDQoFBAMCAQMSBIUBJygKDQoFBAMCAQgSBIUB
KVEKEAoIBAMCAQicCAASBIUBKlAKQAoCBAQSBokBAJcBARoyIFJlcXVlc3QgZm9yIHRoZSBg
RGVsZXRlTW9uaXRvcmVkUHJvamVjdGAgbWV0aG9kLgoKCwoDBAQBEgSJAQglCvkCCgQEBAIA
EgaRAQKWAQQa6AIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBgTW9uaXRv
cmVkUHJvamVjdGAuCiBFeGFtcGxlOgogYGxvY2F0aW9ucy9nbG9iYWwvbWV0cmljc1Njb3Bl
cy97U0NPUElOR19QUk9KRUNUX0lEX09SX05VTUJFUn0vcHJvamVjdHMve01PTklUT1JFRF9Q
Uk9KRUNUX0lEX09SX05VTUJFUn1gCgogQXV0aG9yaXphdGlvbiByZXF1aXJlcyB0aGUgZm9s
bG93aW5nIFtHb29nbGUKIElBTV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbSkgcGVy
bWlzc2lvbnMgb24gYm90aCB0aGUgYE1ldHJpY3MgU2NvcGVgCiBhbmQgb24gdGhlIGBNb25p
dG9yZWRQcm9qZWN0YDogYG1vbml0b3JpbmcubWV0cmljc1Njb3Blcy5saW5rYAoKDQoFBAQC
AAUSBJEBAggKDQoFBAQCAAESBJEBCQ0KDQoFBAQCAAMSBJEBEBEKDwoFBAQCAAgSBpEBEpYB
AwoQCggEBAIACJwIABIEkgEEKgoRCgcEBAIACJ8IEgaTAQSVAQUKYgoCBAUSBpsBALYBARpU
IENvbnRhaW5zIG1ldGFkYXRhIGZvciBsb25ncnVubmluZyBvcGVyYXRpb24gZm9yIHRoZSBl
ZGl0IE1ldHJpY3MgU2NvcGUKIGVuZHBvaW50cy4KCgsKAwQFARIEmwEIGQopCgQEBQQAEgad
AQKsAQMaGSBCYXRjaCBvcGVyYXRpb24gc3RhdGVzLgoKDQoFBAUEAAESBJ0BBwwKGgoGBAUE
AAIAEgSfAQQaGgogSW52YWxpZC4KCg8KBwQFBAACAAESBJ8BBBUKDwoHBAUEAAIAAhIEnwEY
GQosCgYEBQQAAgESBKIBBBAaHCBSZXF1ZXN0IGhhcyBiZWVuIHJlY2VpdmVkLgoKDwoHBAUE
AAIBARIEogEECwoPCgcEBQQAAgECEgSiAQ4PCjYKBgQFBAACAhIEpQEEEBomIFJlcXVlc3Qg
aXMgYWN0aXZlbHkgYmVpbmcgcHJvY2Vzc2VkLgoKDwoHBAUEAAICARIEpQEECwoPCgcEBQQA
AgICEgSlAQ4PCi8KBgQFBAACAxIEqAEEDRofIFRoZSBiYXRjaCBwcm9jZXNzaW5nIGlzIGRv
bmUuCgoPCgcEBQQAAgMBEgSoAQQICg8KBwQFBAACAwISBKgBCwwKNQoGBAUEAAIEEgSrAQQS
GiUgVGhlIGJhdGNoIHByb2Nlc3Npbmcgd2FzIGNhbmNlbGxlZC4KCg8KBwQFBAACBAESBKsB
BA0KDwoHBAUEAAIEAhIEqwEQEQo1CgQEBQIAEgSvAQISGicgQ3VycmVudCBzdGF0ZSBvZiB0
aGUgYmF0Y2ggb3BlcmF0aW9uLgoKDQoFBAUCAAYSBK8BAgcKDQoFBAUCAAESBK8BCA0KDQoF
BAUCAAMSBK8BEBEKPQoEBAUCARIEsgECLBovIFRoZSB0aW1lIHdoZW4gdGhlIGJhdGNoIHJl
cXVlc3Qgd2FzIHJlY2VpdmVkLgoKDQoFBAUCAQYSBLIBAhsKDQoFBAUCAQESBLIBHCcKDQoF
BAUCAQMSBLIBKisKRAoEBAUCAhIEtQECLBo2IFRoZSB0aW1lIHdoZW4gdGhlIG9wZXJhdGlv
biByZXN1bHQgd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQFAgIGEgS1AQIbCg0KBQQFAgIBEgS1
ARwnCg0KBQQFAgIDEgS1ASorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest ===
    # Fields for GetMetricsScopeRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest ===
    # Fields for ListMetricsScopesByMonitoredProjectRequest
    # Field: monitored_resource_container Type: 9 ()

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse ===
    # Fields for ListMetricsScopesByMonitoredProjectResponse
    # Field: metrics_scopes Type: 11 (.google.monitoring.metricsscope.v1.MetricsScope)

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest ===
    # Fields for CreateMonitoredProjectRequest
    # Field: parent Type: 9 ()
    # Field: monitored_project Type: 11 (.google.monitoring.metricsscope.v1.MonitoredProject)

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest ===
    # Fields for DeleteMonitoredProjectRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScopes::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: state Type: 14 (.google.monitoring.metricsscope.v1.OperationMetadata.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: OperationMetadata::State
our $OperationMetadata_STATE_UNSPECIFIED = 0;
our $OperationMetadata_CREATED = 1;
our $OperationMetadata_RUNNING = 2;
our $OperationMetadata_DONE = 3;
our $OperationMetadata_CANCELLED = 4;

# === Service Client: Google::Monitoring::Metricsscope::V1::MetricsScopes::MetricsScopesClient ===
package Google::Monitoring::Metricsscope::V1::MetricsScopes::MetricsScopesClient;

=pod

=head2 Service Client: Google::Monitoring::Metricsscope::V1::MetricsScopes::MetricsScopesClient

Client stub representing the remote C<MetricsScopes> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub get_metrics_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.metricsscope.v1.MetricsScopes',
        method         => 'GetMetricsScope',
        request        => $req,
        response_class => 'Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope',
    });
}

sub list_metrics_scopes_by_monitored_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.metricsscope.v1.MetricsScopes',
        method         => 'ListMetricsScopesByMonitoredProject',
        request        => $req,
        response_class => 'Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse',
    });
}

sub create_monitored_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.metricsscope.v1.MetricsScopes',
        method         => 'CreateMonitoredProject',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_monitored_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.metricsscope.v1.MetricsScopes',
        method         => 'DeleteMonitoredProject',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Metricsscope::V1::MetricsScopes - Compiled Protocol Buffers messages for google/monitoring/metricsscope/v1/metrics_scopes.proto

=head1 SYNOPSIS

    use Google::Monitoring::Metricsscope::V1::MetricsScopes;

    my $msg = Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/metricsscope/v1/metrics_scopes.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest

Request for the `GetMetricsScope` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `Metrics Scope`.
Example:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}`

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest

Request for the `ListMetricsScopesByMonitoredProject` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->monitored_resource_container() >> / C<< $msg->monitored_resource_container($value) >>

Type: C<String>

Required. The resource name of the `Monitored Project` being requested.
Example:
`projects/{MONITORED_PROJECT_ID_OR_NUMBER}`

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse

Response for the `ListMetricsScopesByMonitoredProject` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metrics_scopes() >> / C<< $msg->metrics_scopes($value) >>

Type: C<Message> (L<Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope>)

A set of all metrics scopes that the specified monitored project has been
added to.

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest

Request for the `CreateMonitoredProject` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the existing `Metrics Scope` that will monitor this
project.
Example:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}`

=item * C<< $msg->monitored_project() >> / C<< $msg->monitored_project($value) >>

Type: C<Message> (L<Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject>)

Required. The initial `MonitoredProject` configuration.
Specify only the `monitored_project.name` field. All other fields are
ignored. The `monitored_project.name` must be in the format:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}/projects/{MONITORED_PROJECT_ID_OR_NUMBER}`

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest

Request for the `DeleteMonitoredProject` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `MonitoredProject`.
Example:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}/projects/{MONITORED_PROJECT_ID_OR_NUMBER}`

Authorization requires the following [Google
IAM](https://cloud.google.com/iam) permissions on both the `Metrics Scope`
and on the `MonitoredProject`: `monitoring.metricsScopes.link`

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScopes::OperationMetadata

Contains metadata for longrunning operation for the edit Metrics Scope
endpoints.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Monitoring::Metricsscope::V1::OperationMetadata::State>)

Current state of the batch operation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the batch request was received.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the operation result was last updated.

=back

=head3 Enum: OperationMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATED> => C<1>

=item * C<RUNNING> => C<2>

=item * C<DONE> => C<3>

=item * C<CANCELLED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Metricsscope::V1::MetricsScopes::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
