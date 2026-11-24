package Google::Actions::Sdk::V2::ActionsTesting;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Intent };
    eval { require Google::Actions::Sdk::V2::Conversation::Canvas };
    eval { require Google::Actions::Sdk::V2::Conversation::Prompt };
    eval { require Google::Actions::Sdk::V2::EventLogs };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvYWN0aW9ucy9zZGsvdjIvYWN0aW9uc190ZXN0aW5nLnByb3RvEhVnb29nbGUu
YWN0aW9ucy5zZGsudjIaL2dvb2dsZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vaW50
ZW50LnByb3RvGj5nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9j
b250ZW50L2NhbnZhcy5wcm90bxo2Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlv
bi9wcm9tcHQvcHJvbXB0LnByb3RvGiZnb29nbGUvYWN0aW9ucy9zZGsvdjIvZXZlbnRfbG9n
cy5wcm90bxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9wcm90
b2J1Zi9lbXB0eS5wcm90bxoYZ29vZ2xlL3R5cGUvbGF0bG5nLnByb3RvIv4BChZTZW5kSW50
ZXJhY3Rpb25SZXF1ZXN0Eh0KB3Byb2plY3QYASABKAlCA+BBAlIHcHJvamVjdBI7CgVpbnB1
dBgCIAEoCzIgLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5Vc2VySW5wdXRCA+BBAlIFaW5wdXQS
WQoRZGV2aWNlX3Byb3BlcnRpZXMYAyABKAsyJy5nb29nbGUuYWN0aW9ucy5zZGsudjIuRGV2
aWNlUHJvcGVydGllc0ID4EECUhBkZXZpY2VQcm9wZXJ0aWVzEi0KEmNvbnZlcnNhdGlvbl90
b2tlbhgEIAEoCVIRY29udmVyc2F0aW9uVG9rZW4itwEKCVVzZXJJbnB1dBIUCgVxdWVyeRgB
IAEoCVIFcXVlcnkSPgoEdHlwZRgCIAEoDjIqLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5Vc2Vy
SW5wdXQuSW5wdXRUeXBlUgR0eXBlIlQKCUlucHV0VHlwZRIaChZJTlBVVF9UWVBFX1VOU1BF
Q0lGSUVEEAASCQoFVE9VQ0gQARIJCgVWT0lDRRACEgwKCEtFWUJPQVJEEAMSBwoDVVJMEAQi
tAIKEERldmljZVByb3BlcnRpZXMSSQoHc3VyZmFjZRgBIAEoDjIvLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5EZXZpY2VQcm9wZXJ0aWVzLlN1cmZhY2VSB3N1cmZhY2USOwoIbG9jYXRpb24Y
AiABKAsyHy5nb29nbGUuYWN0aW9ucy5zZGsudjIuTG9jYXRpb25SCGxvY2F0aW9uEhYKBmxv
Y2FsZRgDIAEoCVIGbG9jYWxlEhsKCXRpbWVfem9uZRgEIAEoCVIIdGltZVpvbmUiYwoHU3Vy
ZmFjZRIXChNTVVJGQUNFX1VOU1BFQ0lGSUVEEAASCwoHU1BFQUtFUhABEgkKBVBIT05FEAIS
CAoEQUxMTxADEhEKDVNNQVJUX0RJU1BMQVkQBBIKCgZLQUlfT1MQBSKdAQoITG9jYXRpb24S
NQoLY29vcmRpbmF0ZXMYASABKAsyEy5nb29nbGUudHlwZS5MYXRMbmdSC2Nvb3JkaW5hdGVz
EisKEWZvcm1hdHRlZF9hZGRyZXNzGAIgASgJUhBmb3JtYXR0ZWRBZGRyZXNzEhkKCHppcF9j
b2RlGAMgASgJUgd6aXBDb2RlEhIKBGNpdHkYBCABKAlSBGNpdHkixQEKF1NlbmRJbnRlcmFj
dGlvblJlc3BvbnNlEjUKBm91dHB1dBgBIAEoCzIdLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5P
dXRwdXRSBm91dHB1dBJECgtkaWFnbm9zdGljcxgCIAEoCzIiLmdvb2dsZS5hY3Rpb25zLnNk
ay52Mi5EaWFnbm9zdGljc1ILZGlhZ25vc3RpY3MSLQoSY29udmVyc2F0aW9uX3Rva2VuGAMg
ASgJUhFjb252ZXJzYXRpb25Ub2tlbiLaAQoGT3V0cHV0EhIKBHRleHQYASABKAlSBHRleHQS
FgoGc3BlZWNoGAIgAygJUgZzcGVlY2gSQgoGY2FudmFzGAMgASgLMiouZ29vZ2xlLmFjdGlv
bnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5DYW52YXNSBmNhbnZhcxJgChZhY3Rpb25zX2J1aWxk
ZXJfcHJvbXB0GAQgASgLMiouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5Q
cm9tcHRSFGFjdGlvbnNCdWlsZGVyUHJvbXB0ImoKC0RpYWdub3N0aWNzElsKFmFjdGlvbnNf
YnVpbGRlcl9ldmVudHMYASADKAsyJS5nb29nbGUuYWN0aW9ucy5zZGsudjIuRXhlY3V0aW9u
RXZlbnRSFGFjdGlvbnNCdWlsZGVyRXZlbnRzImwKE01hdGNoSW50ZW50c1JlcXVlc3QSHQoH
cHJvamVjdBgBIAEoCUID4EECUgdwcm9qZWN0EhkKBXF1ZXJ5GAIgASgJQgPgQQJSBXF1ZXJ5
EhsKBmxvY2FsZRgDIAEoCUID4EECUgZsb2NhbGUiawoUTWF0Y2hJbnRlbnRzUmVzcG9uc2US
UwoPbWF0Y2hlZF9pbnRlbnRzGAEgAygLMiouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZl
cnNhdGlvbi5JbnRlbnRSDm1hdGNoZWRJbnRlbnRzIj4KIlNldFdlYkFuZEFwcEFjdGl2aXR5
Q29udHJvbFJlcXVlc3QSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZDKvBAoOQWN0aW9uc1Rl
c3RpbmcSpQEKD1NlbmRJbnRlcmFjdGlvbhItLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5TZW5k
SW50ZXJhY3Rpb25SZXF1ZXN0Gi4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlNlbmRJbnRlcmFj
dGlvblJlc3BvbnNlIjOC0+STAi0iKC92Mi97cHJvamVjdD1wcm9qZWN0cy8qfTpzZW5kSW50
ZXJhY3Rpb246ASoSsAEKDE1hdGNoSW50ZW50cxIqLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5N
YXRjaEludGVudHNSZXF1ZXN0GisuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLk1hdGNoSW50ZW50
c1Jlc3BvbnNlIkeC0+STAioiJS92Mi97cHJvamVjdD1wcm9qZWN0cy8qfTptYXRjaEludGVu
dHM6ASraQRRwcm9qZWN0LHF1ZXJ5LGxvY2FsZRKmAQobU2V0V2ViQW5kQXBwQWN0aXZpdHlD
b250cm9sEjkuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlNldFdlYkFuZEFwcEFjdGl2aXR5Q29u
dHJvbFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiNILT5JMCJCIfL3YyOnNldFdl
YkFuZEFwcEFjdGl2aXR5Q29udHJvbDoBKtpBB2VuYWJsZWQaGcpBFmFjdGlvbnMuZ29vZ2xl
YXBpcy5jb21CbAoZY29tLmdvb2dsZS5hY3Rpb25zLnNkay52MkITQWN0aW9uc1Rlc3RpbmdQ
cm90b1ABWjhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMv
c2RrL3YyO3Nka0q+QgoHEgUOAP8BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHgoJCgIDABIDEgA5CgkKAgMBEgMTAEgKCQoCAwISAxQAQAoJCgIDAxID
FQAwCgkKAgMEEgMWACYKCQoCAwUSAxcAIQoJCgIDBhIDGAApCgkKAgMHEgMZACUKCQoCAwgS
AxoAIgoICgEIEgMcAE8KCQoCCAsSAxwATwoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMe
ADQKCQoCCAgSAx4ANAoICgEIEgMfADIKCQoCCAESAx8AMgpRCgIGABIEIgBIARpFIEFjdGlv
bnMgVGVzdGluZyBBUEkgd2hpY2ggYWxsb3dzIGRldmVsb3BlcnMgdG8gcnVuIGF1dG9tYXRl
ZCB0ZXN0cy4KCgoKAwYAARIDIggWCgoKAwYAAxIDIwI+CgwKBQYAA5kIEgMjAj4KNAoEBgAC
ABIEJgIrAxomIFBsYXlzIG9uZSByb3VuZCBvZiB0aGUgY29udmVyc2F0aW9uLgoKDAoFBgAC
AAESAyYGFQoMCgUGAAIAAhIDJhYsCgwKBQYAAgADEgMmN04KDQoFBgACAAQSBCcEKgYKEQoJ
BgACAASwyrwiEgQnBCoGCjsKBAYAAgESBC4CNAMaLSBGaW5kcyB0aGUgaW50ZW50cyB0aGF0
IG1hdGNoIGEgZ2l2ZW4gcXVlcnkuCgoMCgUGAAIBARIDLgYSCgwKBQYAAgECEgMuEyYKDAoF
BgACAQMSAy4xRQoNCgUGAAIBBBIELwQyBgoRCgkGAAIBBLDKvCISBC8EMgYKDAoFBgACAQQS
AzMEQgoPCggGAAIBBJsIABIDMwRCCrwECgQGAAICEgRBAkcDGq0EIFNldHMgdGhlIFdlYiAm
IEFwcCBBY3Rpdml0eSBjb250cm9sIG9uIGEgc2VydmljZSBhY2NvdW50LgoKIEl0IGlzIG5l
Y2Vzc2FyeSB0byBoYXZlIHRoaXMgc2V0dGluZyBlbmFibGVkIGluIG9yZGVyIHRvIHVzZSBj
YWxsIEFjdGlvbnMuCiBUaGUgc2V0dGluZyBpcyBvcmlnaW5hbGx5IGRpc2FibGVkIGZvciBz
ZXJ2aWNlIGFjY291bnRzLCBhbmQgaXQgaXMKIHByZXNlcnZlZCB1bnRpbCBzZXQgdG8gYSBk
aWZmZXJlbnQgdmFsdWUuIFRoaXMgbWVhbnMgaXQgb25seSBuZWVkcyB0byBiZQogZW5hYmxl
ZCBvbmNlIHBlciBhY2NvdW50IChhbmQgbm90IG5lY2Vzc2FyaWx5IG9uY2UgcGVyIHRlc3Qp
LCB1bmxlc3MgaXQgaXMKIGxhdGVyIGRpc2FibGVkLgoKIFJldHVybnMgYW4gZXJyb3IgaWYg
dGhlIGNhbGxlciBpcyBub3QgYSBzZXJ2aWNlIGFjY291bnQuIFVzZXIgYWNjb3VudHMgY2Fu
CiBjaGFuZ2UgdGhpcyBzZXR0aW5nIHZpYSB0aGUgQWN0aXZpdHkgQ29udHJvbHMgcGFnZS4g
U2VlCiBodHRwczovL3N1cHBvcnQuZ29vZ2xlLmNvbS93ZWJzZWFyY2gvYW5zd2VyLzU0MDY4
LgoKDAoFBgACAgESA0EGIQoMCgUGAAICAhIDQSJECgwKBQYAAgIDEgNBT2QKDQoFBgACAgQS
BEIERQYKEQoJBgACAgSwyrwiEgRCBEUGCgwKBQYAAgIEEgNGBDUKDwoIBgACAgSbCAASA0YE
NQo+CgIEABIESwBbARoyIFJlcXVlc3QgZm9yIHBsYXlpbmcgYSByb3VuZCBvZiB0aGUgY29u
dmVyc2F0aW9uLgoKCgoDBAABEgNLCB4KawoEBAACABIDTgI+Gl4gUmVxdWlyZWQuIFRoZSBw
cm9qZWN0IGJlaW5nIHRlc3RlZCwgaW5kaWNhdGVkIGJ5IHRoZSBQcm9qZWN0IElELgogRm9y
bWF0OiBwcm9qZWN0cy97cHJvamVjdH0KCgwKBQQAAgAFEgNOAggKDAoFBAACAAESA04JEAoM
CgUEAAIAAxIDThMUCgwKBQQAAgAIEgNOFT0KDwoIBAACAAicCAASA04WPAo0CgQEAAIBEgNR
Aj8aJyBSZXF1aXJlZC4gSW5wdXQgcHJvdmlkZWQgYnkgdGhlIHVzZXIuCgoMCgUEAAIBBhID
UQILCgwKBQQAAgEBEgNRDBEKDAoFBAACAQMSA1EUFQoMCgUEAAIBCBIDURY+Cg8KCAQAAgEI
nAgAEgNRFz0KVwoEBAACAhIDVAJSGkogUmVxdWlyZWQuIFByb3BlcnRpZXMgb2YgdGhlIGRl
dmljZSB1c2VkIGZvciBpbnRlcmFjdGluZyB3aXRoIHRoZSBBY3Rpb24uCgoMCgUEAAICBhID
VAISCgwKBQQAAgIBEgNUEyQKDAoFBAACAgMSA1QnKAoMCgUEAAICCBIDVClRCg8KCAQAAgII
nAgAEgNUKlAKpgIKBAQAAgMSA1oCIBqYAiBPcGFxdWUgdG9rZW4gdGhhdCBtdXN0IGJlIHBh
c3NlZCBhcyByZWNlaXZlZCBmcm9tIFNlbmRJbnRlcmFjdGlvblJlc3BvbnNlCiBvbiB0aGUg
cHJldmlvdXMgaW50ZXJhY3Rpb24uIFRoaXMgY2FuIGJlIGxlZnQgdW5zZXQgaW4gb3JkZXIg
dG8gc3RhcnQgYSBuZXcKIGNvbnZlcnNhdGlvbiwgZWl0aGVyIGFzIHRoZSBmaXJzdCBpbnRl
cmFjdGlvbiBvZiBhIHRlc3Rpbmcgc2Vzc2lvbiBvciB0bwogYWJhbmRvbiBhIHByZXZpb3Vz
IGNvbnZlcnNhdGlvbiBhbmQgc3RhcnQgYSBuZXcgb25lLgoKDAoFBAACAwUSA1oCCAoMCgUE
AAIDARIDWgkbCgwKBQQAAgMDEgNaHh8KOgoCBAESBF4AdgEaLiBVc2VyIGlucHV0IHByb3Zp
ZGVkIG9uIGEgY29udmVyc2F0aW9uIHJvdW5kLgoKCgoDBAEBEgNeCBEKRwoEBAEEABIEYAJv
Axo5IEluZGljYXRlcyB0aGUgaW5wdXQgc291cmNlLCB0eXBlZCBxdWVyeSBvciB2b2ljZSBx
dWVyeS4KCgwKBQQBBAABEgNgBxAKKgoGBAEEAAIAEgNiBB8aGyBVbnNwZWNpZmllZCBpbnB1
dCBzb3VyY2UuCgoOCgcEAQQAAgABEgNiBBoKDgoHBAEEAAIAAhIDYh0eCi4KBgQBBAACARID
ZQQOGh8gUXVlcnkgZnJvbSBhIEdVSSBpbnRlcmFjdGlvbi4KCg4KBwQBBAACAQESA2UECQoO
CgcEAQQAAgECEgNlDA0KHQoGBAEEAAICEgNoBA4aDiBWb2ljZSBxdWVyeS4KCg4KBwQBBAAC
AgESA2gECQoOCgcEAQQAAgICEgNoDA0KHQoGBAEEAAIDEgNrBBEaDiBUeXBlZCBxdWVyeS4K
Cg4KBwQBBAACAwESA2sEDAoOCgcEAQQAAgMCEgNrDxAKOAoGBAEEAAIEEgNuBAwaKSBUaGUg
YWN0aW9uIHdhcyB0cmlnZ2VyZWQgYnkgYSBVUkwgbGluay4KCg4KBwQBBAACBAESA24EBwoO
CgcEAQQAAgQCEgNuCgsKNQoEBAECABIDcgITGiggQ29udGVudCBvZiB0aGUgaW5wdXQgc2Vu
dCBieSB0aGUgdXNlci4KCgwKBQQBAgAFEgNyAggKDAoFBAECAAESA3IJDgoMCgUEAQIAAxID
chESCiEKBAQBAgESA3UCFRoUIFR5cGUgb2YgdGhlIGlucHV0LgoKDAoFBAECAQYSA3UCCwoM
CgUEAQIBARIDdQwQCgwKBQQBAgEDEgN1ExQKRQoCBAISBXkAoAEBGjggUHJvcGVydGllcyBv
ZiBkZXZpY2UgcmVsZXZhbnQgdG8gYSBjb252ZXJzYXRpb24gcm91bmQuCgoKCgMEAgESA3kI
GAp2CgQEAgQAEgV8Ao4BAxpnIFBvc3NpYmxlIHN1cmZhY2VzIHVzZWQgdG8gaW50ZXJhY3Qg
d2l0aCB0aGUgQWN0aW9uLgogQWRkaXRpb25hbCB2YWx1ZXMgbWF5IGJlIGluY2x1ZGVkIGlu
IHRoZSBmdXR1cmUuCgoMCgUEAgQAARIDfAcOCjUKBgQCBAACABIDfgQcGiYgRGVmYXVsdCB2
YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAgQAAgABEgN+BBcKDgoHBAIEAAIA
AhIDfhobCi0KBgQCBAACARIEgQEEEBodIFNwZWFrZXIgKGUuZy4gR29vZ2xlIEhvbWUpLgoK
DwoHBAIEAAIBARIEgQEECwoPCgcEAgQAAgECEgSBAQ4PChgKBgQCBAACAhIEhAEEDhoIIFBo
b25lLgoKDwoHBAIEAAICARIEhAEECQoPCgcEAgQAAgICEgSEAQwNChwKBgQCBAACAxIEhwEE
DRoMIEFsbG8gQ2hhdC4KCg8KBwQCBAACAwESBIcBBAgKDwoHBAIEAAIDAhIEhwELDAonCgYE
AgQAAgQSBIoBBBYaFyBTbWFydCBEaXNwbGF5IERldmljZS4KCg8KBwQCBAACBAESBIoBBBEK
DwoHBAIEAAIEAhIEigEUFQoYCgYEAgQAAgUSBI0BBA8aCCBLYWlPUy4KCg8KBwQCBAACBQES
BI0BBAoKDwoHBAIEAAIFAhIEjQENDgo9CgQEAgIAEgSRAQIWGi8gU3VyZmFjZSB1c2VkIGZv
ciBpbnRlcmFjdGluZyB3aXRoIHRoZSBBY3Rpb24uCgoNCgUEAgIABhIEkQECCQoNCgUEAgIA
ARIEkQEKEQoNCgUEAgIAAxIEkQEUFQpTCgQEAgIBEgSUAQIYGkUgRGV2aWNlIGxvY2F0aW9u
IHN1Y2ggYXMgbGF0aXR1ZGUsIGxvbmdpdHVkZSwgYW5kIGZvcm1hdHRlZCBhZGRyZXNzLgoK
DQoFBAICAQYSBJQBAgoKDQoFBAICAQESBJQBCxMKDQoFBAICAQMSBJQBFhcK0AEKBAQCAgIS
BJoBAhQawQEgTG9jYWxlIGFzIHNldCBvbiB0aGUgZGV2aWNlLgogVGhlIGZvcm1hdCBzaG91
bGQgZm9sbG93IEJDUCA0NzogaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL2JjcDQ3CiBF
eGFtcGxlczogZW4sIGVuLVVTLCBlcy00MTkgKG1vcmUgZXhhbXBsZXMgYXQKIGh0dHBzOi8v
dG9vbHMuaWV0Zi5vcmcvaHRtbC9iY3A0NyNhcHBlbmRpeC1BKS4KCg0KBQQCAgIFEgSaAQII
Cg0KBQQCAgIBEgSaAQkPCg0KBQQCAgIDEgSaARITCqEBCgQEAgIDEgSfAQIXGpIBIFRpbWUg
em9uZSBhcyBzZXQgb24gdGhlIGRldmljZS4KIFRoZSBmb3JtYXQgc2hvdWxkIGZvbGxvdyB0
aGUgSUFOQSBUaW1lIFpvbmUgRGF0YWJhc2UsIGUuZy4KICJBbWVyaWNhL05ld19Zb3JrIjog
aHR0cHM6Ly93d3cuaWFuYS5vcmcvdGltZS16b25lcwoKDQoFBAICAwUSBJ8BAggKDQoFBAIC
AwESBJ8BCRIKDQoFBAICAwMSBJ8BFRYKNQoCBAMSBqMBALsBARonIENvbnRhaW5lciB0aGF0
IHJlcHJlc2VudHMgYSBsb2NhdGlvbi4KCgsKAwQDARIEowEIEAqMAQoEBAMCABIEpwECJRp+
IEdlbyBjb29yZGluYXRlcy4KIFJlcXVpcmVzIHRoZSBbREVWSUNFX1BSRUNJU0VfTE9DQVRJ
T05dCiBbZ29vZ2xlLmFjdGlvbnMudjIuUGVybWlzc2lvbi5ERVZJQ0VfUFJFQ0lTRV9MT0NB
VElPTl0gcGVybWlzc2lvbi4KCg0KBQQDAgAGEgSnAQIUCg0KBQQDAgABEgSnARUgCg0KBQQD
AgADEgSnASMkCsYBCgQEAwIBEgSsAQIfGrcBIERpc3BsYXkgYWRkcmVzcywgZS5nLiwgIjE2
MDAgQW1waGl0aGVhdHJlIFBrd3ksIE1vdW50YWluIFZpZXcsIENBIDk0MDQzIi4KIFJlcXVp
cmVzIHRoZSBbREVWSUNFX1BSRUNJU0VfTE9DQVRJT05dCiBbZ29vZ2xlLmFjdGlvbnMudjIu
UGVybWlzc2lvbi5ERVZJQ0VfUFJFQ0lTRV9MT0NBVElPTl0gcGVybWlzc2lvbi4KCg0KBQQD
AgEFEgSsAQIICg0KBQQDAgEBEgSsAQkaCg0KBQQDAgEDEgSsAR0eCtoBCgQEAwICEgSzAQIW
GssBIFppcCBjb2RlLgogUmVxdWlyZXMgdGhlIFtERVZJQ0VfUFJFQ0lTRV9MT0NBVElPTl0K
IFtnb29nbGUuYWN0aW9ucy52Mi5QZXJtaXNzaW9uLkRFVklDRV9QUkVDSVNFX0xPQ0FUSU9O
XSBvcgogW0RFVklDRV9DT0FSU0VfTE9DQVRJT05dCiBbZ29vZ2xlLmFjdGlvbnMudjIuUGVy
bWlzc2lvbi5ERVZJQ0VfQ09BUlNFX0xPQ0FUSU9OXSBwZXJtaXNzaW9uLgoKDQoFBAMCAgUS
BLMBAggKDQoFBAMCAgESBLMBCREKDQoFBAMCAgMSBLMBFBUK1gEKBAQDAgMSBLoBAhIaxwEg
Q2l0eS4KIFJlcXVpcmVzIHRoZSBbREVWSUNFX1BSRUNJU0VfTE9DQVRJT05dCiBbZ29vZ2xl
LmFjdGlvbnMudjIuUGVybWlzc2lvbi5ERVZJQ0VfUFJFQ0lTRV9MT0NBVElPTl0gb3IKIFtE
RVZJQ0VfQ09BUlNFX0xPQ0FUSU9OXQogW2dvb2dsZS5hY3Rpb25zLnYyLlBlcm1pc3Npb24u
REVWSUNFX0NPQVJTRV9MT0NBVElPTl0gcGVybWlzc2lvbi4KCg0KBQQDAgMFEgS6AQIICg0K
BQQDAgMBEgS6AQkNCg0KBQQDAgMDEgS6ARARCjgKAgQEEga+AQDIAQEaKiBSZXNwb25zZSB0
byBhIHJvdW5kIG9mIHRoZSBjb252ZXJzYXRpb24uCgoLCgMEBAESBL4BCB8KLAoEBAQCABIE
wAECFBoeIE91dHB1dCBwcm92aWRlZCB0byB0aGUgdXNlci4KCg0KBQQEAgAGEgTAAQIICg0K
BQQEAgABEgTAAQkPCg0KBQQEAgADEgTAARITClIKBAQEAgESBMMBAh4aRCBEaWFnbm9zdGlj
cyBpbmZvcm1hdGlvbiB0aGF0IGV4cGxhaW5zIGhvdyB0aGUgcmVxdWVzdCB3YXMgaGFuZGxl
ZC4KCg0KBQQEAgEGEgTDAQINCg0KBQQEAgEBEgTDAQ4ZCg0KBQQEAgEDEgTDARwdCoIBCgQE
BAICEgTHAQIgGnQgT3BhcXVlIHRva2VuIHRvIGJlIHNldCBvbiBTZW5kSW50ZXJhY3Rpb25S
ZXF1ZXN0IG9uIHRoZSBuZXh0IFJQQyBjYWxsIGluCiBvcmRlciB0byBjb250aW51ZSB0aGUg
c2FtZSBjb252ZXJzYXRpb24uCgoNCgUEBAICBRIExwECCAoNCgUEBAICARIExwEJGwoNCgUE
BAICAxIExwEeHwo+CgIEBRIGywEA2gEBGjAgVXNlci12aXNpYmxlIG91dHB1dCB0byB0aGUg
Y29udmVyc2F0aW9uIHJvdW5kLgoKCwoDBAUBEgTLAQgOCj8KBAQFAgASBM0BAhIaMSBTcG9r
ZW4gcmVzcG9uc2Ugc2VudCB0byB1c2VyIGFzIGEgcGxhaW4gc3RyaW5nLgoKDQoFBAUCAAUS
BM0BAggKDQoFBAUCAAESBM0BCQ0KDQoFBAUCAAMSBM0BEBEKZgoEBAUCARIE0QECHRpYIFNw
ZWVjaCBjb250ZW50IHByb2R1Y2VkIGJ5IHRoZSBBY3Rpb24uIFRoaXMgbWF5IGluY2x1ZGUg
bWFya3VwIGVsZW1lbnRzCiBzdWNoIGFzIFNTTUwuCgoNCgUEBQIBBBIE0QECCgoNCgUEBQIB
BRIE0QELEQoNCgUEBQIBARIE0QESGAoNCgUEBQIBAxIE0QEbHAorCgQEBQICEgTUAQI3Gh0g
SW50ZXJhY3RpdmUgQ2FudmFzIGNvbnRlbnQuCgoNCgUEBQICBhIE1AECKwoNCgUEBQICARIE
1AEsMgoNCgUEBQICAxIE1AE1NgquAQoEBAUCAxIE2QECRxqfASBTdGF0ZSBvZiB0aGUgcHJv
bXB0IGF0IHRoZSBlbmQgb2YgdGhlIGNvbnZlcnNhdGlvbiByb3VuZC4KIE1vcmUgaW5mb3Jt
YXRpb24gYWJvdXQgdGhlIHByb21wdDoKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29t
L2Fzc2lzdGFudC9jb252ZXJzYXRpb25hbC9wcm9tcHRzCgoNCgUEBQIDBhIE2QECKwoNCgUE
BQIDARIE2QEsQgoNCgUEBQIDAxIE2QFFRgpKCgIEBhIG3QEA4gEBGjwgRGlhZ25vc3RpY3Mg
aW5mb3JtYXRpb24gcmVsYXRlZCB0byB0aGUgY29udmVyc2F0aW9uIHJvdW5kLgoKCwoDBAYB
EgTdAQgTCtABCgQEBgIAEgThAQI1GsEBIExpc3Qgb2YgZXZlbnRzIHdpdGggZGV0YWlscyBh
Ym91dCBwcm9jZXNzaW5nIG9mIHRoZSBjb252ZXJzYXRpb24gcm91bmQKIHRocm91Z2hvdXQg
dGhlIHN0YWdlcyBvZiB0aGUgQWN0aW9ucyBCdWlsZGVyIGludGVyYWN0aW9uIG1vZGVsLgog
UG9wdWxhdGVkIGZvciBBY3Rpb25zIEJ1aWxkZXIgJiBBY3Rpb25zIFNESyBhcHBzIG9ubHku
CgoNCgUEBgIABBIE4QECCgoNCgUEBgIABhIE4QELGQoNCgUEBgIAARIE4QEaMAoNCgUEBgIA
AxIE4QEzNAo1CgIEBxIG5QEA8gEBGicgUmVxdWVzdCBmb3IgZmluZGluZyBtYXRjaGluZyBp
bnRlbnRzLgoKCwoDBAcBEgTlAQgbCmwKBAQHAgASBOgBAj4aXiBSZXF1aXJlZC4gVGhlIHBy
b2plY3QgYmVpbmcgdGVzdGVkLCBpbmRpY2F0ZWQgYnkgdGhlIFByb2plY3QgSUQuCiBGb3Jt
YXQ6IHByb2plY3RzL3twcm9qZWN0fQoKDQoFBAcCAAUSBOgBAggKDQoFBAcCAAESBOgBCRAK
DQoFBAcCAAMSBOgBExQKDQoFBAcCAAgSBOgBFT0KEAoIBAcCAAicCAASBOgBFjwKMwoEBAcC
ARIE6wECPBolIFJlcXVpcmVkLiBVc2VyIHF1ZXJ5IGFzIHBsYWluIHRleHQuCgoNCgUEBwIB
BRIE6wECCAoNCgUEBwIBARIE6wEJDgoNCgUEBwIBAxIE6wEREgoNCgUEBwIBCBIE6wETOwoQ
CggEBwIBCJwIABIE6wEUOgr8AQoEBAcCAhIE8QECPRrtASBSZXF1aXJlZC4gTG9jYWxlIHRv
IHVzZSB0byBldmFsdWF0ZSB0aGUgcXVlcnksIHN1Y2ggYXMgImVuIi4KIFRoZSBmb3JtYXQg
c2hvdWxkIGZvbGxvdyBCQ1AgNDc6IGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9iY3A0
NwogU2VlIHRoZSBsaXN0IG9mIHN1cHBvcnRlZCBsYW5ndWFnZXMgaW4KIGh0dHBzOi8vZGV2
ZWxvcGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9jb25zb2xlL2xhbmd1YWdlcy1sb2NhbGVz
CgoNCgUEBwICBRIE8QECCAoNCgUEBwICARIE8QEJDwoNCgUEBwICAxIE8QESEwoNCgUEBwIC
CBIE8QEUPAoQCggEBwICCJwIABIE8QEVOwo2CgIECBIG9QEA+QEBGiggUmVzcG9uc2UgZm9y
IGZpbmRpbmcgbWF0Y2hpbmcgaW50ZW50cy4KCgsKAwQIARIE9QEIHApuCgQECAIAEgT4AQJJ
GmAgSW50ZW50cyBtYXRjaGVkLCBvcmRlcmVkIGZyb20gbW9zdCB0byBsZWFzdCByZWxldmFu
dC4gT25seSB0aGUgZmlyc3QKIDUwIG1hdGNoZXMgYXJlIHJldHVybmVkLgoKDQoFBAgCAAQS
BPgBAgoKDQoFBAgCAAYSBPgBCzQKDQoFBAgCAAESBPgBNUQKDQoFBAgCAAMSBPgBR0gKQwoC
BAkSBvwBAP8BARo1IFJlcXVlc3QgZm9yIHNldHRpbmcgV2ViICYgQXBwIEFjdGl2aXR5IHBy
ZWZlcmVuY2VzLgoKCwoDBAkBEgT8AQgqClIKBAQJAgASBP4BAhMaRCBXaGV0aGVyIHRoZSBz
ZXR0aW5nIHNob3VsZCBiZSBzZXQgdG8gYW4gZW5hYmxlZCBvciBkaXNhYmxlZCBzdGF0ZS4K
Cg0KBQQJAgAFEgT+AQIGCg0KBQQJAgABEgT+AQcOCg0KBQQJAgADEgT+ARESYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest ===
    # Fields for SendInteractionRequest
    # Field: project Type: 9 ()
    # Field: input Type: 11 (.google.actions.sdk.v2.UserInput)
    # Field: device_properties Type: 11 (.google.actions.sdk.v2.DeviceProperties)
    # Field: conversation_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsTesting::UserInput ===
    # Fields for UserInput
    # Field: query Type: 9 ()
    # Field: type Type: 14 (.google.actions.sdk.v2.UserInput.InputType)

# Enum: UserInput::InputType
our $UserInput_INPUT_TYPE_UNSPECIFIED = 0;
our $UserInput_TOUCH = 1;
our $UserInput_VOICE = 2;
our $UserInput_KEYBOARD = 3;
our $UserInput_URL = 4;

# === Message: Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties ===
    # Fields for DeviceProperties
    # Field: surface Type: 14 (.google.actions.sdk.v2.DeviceProperties.Surface)
    # Field: location Type: 11 (.google.actions.sdk.v2.Location)
    # Field: locale Type: 9 ()
    # Field: time_zone Type: 9 ()

# Enum: DeviceProperties::Surface
our $DeviceProperties_SURFACE_UNSPECIFIED = 0;
our $DeviceProperties_SPEAKER = 1;
our $DeviceProperties_PHONE = 2;
our $DeviceProperties_ALLO = 3;
our $DeviceProperties_SMART_DISPLAY = 4;
our $DeviceProperties_KAI_OS = 5;

# === Message: Google::Actions::Sdk::V2::ActionsTesting::Location ===
    # Fields for Location
    # Field: coordinates Type: 11 (.google.type.LatLng)
    # Field: formatted_address Type: 9 ()
    # Field: zip_code Type: 9 ()
    # Field: city Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse ===
    # Fields for SendInteractionResponse
    # Field: output Type: 11 (.google.actions.sdk.v2.Output)
    # Field: diagnostics Type: 11 (.google.actions.sdk.v2.Diagnostics)
    # Field: conversation_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsTesting::Output ===
    # Fields for Output
    # Field: text Type: 9 ()
    # Field: speech Type: 9 ()
    # Field: canvas Type: 11 (.google.actions.sdk.v2.conversation.Canvas)
    # Field: actions_builder_prompt Type: 11 (.google.actions.sdk.v2.conversation.Prompt)

# === Message: Google::Actions::Sdk::V2::ActionsTesting::Diagnostics ===
    # Fields for Diagnostics
    # Field: actions_builder_events Type: 11 (.google.actions.sdk.v2.ExecutionEvent)

# === Message: Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest ===
    # Fields for MatchIntentsRequest
    # Field: project Type: 9 ()
    # Field: query Type: 9 ()
    # Field: locale Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse ===
    # Fields for MatchIntentsResponse
    # Field: matched_intents Type: 11 (.google.actions.sdk.v2.conversation.Intent)

# === Message: Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest ===
    # Fields for SetWebAndAppActivityControlRequest
    # Field: enabled Type: 8 ()

# === Service Client: Google::Actions::Sdk::V2::ActionsTesting::ActionsTestingClient ===
package Google::Actions::Sdk::V2::ActionsTesting::ActionsTestingClient;

=pod

=head2 Service Client: Google::Actions::Sdk::V2::ActionsTesting::ActionsTestingClient

Client stub representing the remote C<ActionsTesting> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<actions.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'actions.googleapis.com:443' );

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

sub send_interaction {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsTesting',
        method         => 'SendInteraction',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse',
    });
}

sub match_intents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsTesting',
        method         => 'MatchIntents',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse',
    });
}

sub set_web_and_app_activity_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsTesting',
        method         => 'SetWebAndAppActivityControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ActionsTesting - Compiled Protocol Buffers messages for google/actions/sdk/v2/actions_testing.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ActionsTesting;

    my $msg = Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest->new({
        project => $project,
        input => $input,
        device_properties => $device_properties,
        conversation_token => $conversation_token,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/actions_testing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest

Request for playing a round of the conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The project being tested, indicated by the Project ID.
Format: projects/{project}

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsTesting::UserInput>)

Required. Input provided by the user.

=item * C<< $msg->device_properties() >> / C<< $msg->device_properties($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties>)

Required. Properties of the device used for interacting with the Action.

=item * C<< $msg->conversation_token() >> / C<< $msg->conversation_token($value) >>

Type: C<String>

Opaque token that must be passed as received from SendInteractionResponse
on the previous interaction. This can be left unset in order to start a new
conversation, either as the first interaction of a testing session or to
abandon a previous conversation and start a new one.

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::UserInput

User input provided on a conversation round.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Content of the input sent by the user.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::UserInput::InputType>)

Type of the input.

=back

=head3 Enum: UserInput::InputType

=over 4

=item * C<INPUT_TYPE_UNSPECIFIED> => C<0>

=item * C<TOUCH> => C<1>

=item * C<VOICE> => C<2>

=item * C<KEYBOARD> => C<3>

=item * C<URL> => C<4>

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties

Properties of device relevant to a conversation round.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->surface() >> / C<< $msg->surface($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::DeviceProperties::Surface>)

Surface used for interacting with the Action.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsTesting::Location>)

Device location such as latitude, longitude, and formatted address.

=item * C<< $msg->locale() >> / C<< $msg->locale($value) >>

Type: C<String>

Locale as set on the device.
The format should follow BCP 47: https://tools.ietf.org/html/bcp47
Examples: en, en-US, es-419 (more examples at
https://tools.ietf.org/html/bcp47#appendix-A).

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Time zone as set on the device.
The format should follow the IANA Time Zone Database, e.g.
"America/New_York": https://www.iana.org/time-zones

=back

=head3 Enum: DeviceProperties::Surface

=over 4

=item * C<SURFACE_UNSPECIFIED> => C<0>

=item * C<SPEAKER> => C<1>

=item * C<PHONE> => C<2>

=item * C<ALLO> => C<3>

=item * C<SMART_DISPLAY> => C<4>

=item * C<KAI_OS> => C<5>

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::Location

Container that represents a location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->coordinates() >> / C<< $msg->coordinates($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

Geo coordinates.
Requires the [DEVICE_PRECISE_LOCATION]
[google.actions.v2.Permission.DEVICE_PRECISE_LOCATION] permission.

=item * C<< $msg->formatted_address() >> / C<< $msg->formatted_address($value) >>

Type: C<String>

Display address, e.g., "1600 Amphitheatre Pkwy, Mountain View, CA 94043".
Requires the [DEVICE_PRECISE_LOCATION]
[google.actions.v2.Permission.DEVICE_PRECISE_LOCATION] permission.

=item * C<< $msg->zip_code() >> / C<< $msg->zip_code($value) >>

Type: C<String>

Zip code.
Requires the [DEVICE_PRECISE_LOCATION]
[google.actions.v2.Permission.DEVICE_PRECISE_LOCATION] or
[DEVICE_COARSE_LOCATION]
[google.actions.v2.Permission.DEVICE_COARSE_LOCATION] permission.

=item * C<< $msg->city() >> / C<< $msg->city($value) >>

Type: C<String>

City.
Requires the [DEVICE_PRECISE_LOCATION]
[google.actions.v2.Permission.DEVICE_PRECISE_LOCATION] or
[DEVICE_COARSE_LOCATION]
[google.actions.v2.Permission.DEVICE_COARSE_LOCATION] permission.

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse

Response to a round of the conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsTesting::Output>)

Output provided to the user.

=item * C<< $msg->diagnostics() >> / C<< $msg->diagnostics($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsTesting::Diagnostics>)

Diagnostics information that explains how the request was handled.

=item * C<< $msg->conversation_token() >> / C<< $msg->conversation_token($value) >>

Type: C<String>

Opaque token to be set on SendInteractionRequest on the next RPC call in
order to continue the same conversation.

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::Output

User-visible output to the conversation round.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Spoken response sent to user as a plain string.

=item * C<< $msg->speech() >> / C<< $msg->speech($value) >>

Type: C<String>

Speech content produced by the Action. This may include markup elements
such as SSML.

=item * C<< $msg->canvas() >> / C<< $msg->canvas($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Canvas::Canvas>)

Interactive Canvas content.

=item * C<< $msg->actions_builder_prompt() >> / C<< $msg->actions_builder_prompt($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Prompt::Prompt>)

State of the prompt at the end of the conversation round.
More information about the prompt:
https://developers.google.com/assistant/conversational/prompts

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::Diagnostics

Diagnostics information related to the conversation round.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actions_builder_events() >> / C<< $msg->actions_builder_events($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::ExecutionEvent>)

List of events with details about processing of the conversation round
throughout the stages of the Actions Builder interaction model.
Populated for Actions Builder & Actions SDK apps only.

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest

Request for finding matching intents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The project being tested, indicated by the Project ID.
Format: projects/{project}

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. User query as plain text.

=item * C<< $msg->locale() >> / C<< $msg->locale($value) >>

Type: C<String>

Required. Locale to use to evaluate the query, such as "en".
The format should follow BCP 47: https://tools.ietf.org/html/bcp47
See the list of supported languages in
https://developers.google.com/assistant/console/languages-locales

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse

Response for finding matching intents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matched_intents() >> / C<< $msg->matched_intents($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Intent::Intent>)

Intents matched, ordered from most to least relevant. Only the first
50 matches are returned.

=back

=head2 Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest

Request for setting Web & App Activity preferences.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Whether the setting should be set to an enabled or disabled state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ActionsTesting::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
