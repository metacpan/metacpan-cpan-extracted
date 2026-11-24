package Google::Cloud::Discoveryengine::V1alpha::ProjectService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Project };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcHJvamVjdF9zZXJ2aWNl
LnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjJn
b29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcHJvamVjdC5wcm90bxojZ29v
Z2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8iVwoRR2V0UHJvamVjdFJlcXVlc3QS
QgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
UHJvamVjdFIEbmFtZSLPAQoXUHJvdmlzaW9uUHJvamVjdFJlcXVlc3QSQgoEbmFtZRgBIAEo
CUIu4EEC+kEoCiZkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIEbmFt
ZRI2ChVhY2NlcHRfZGF0YV91c2VfdGVybXMYAiABKAhCA+BBAlISYWNjZXB0RGF0YVVzZVRl
cm1zEjgKFmRhdGFfdXNlX3Rlcm1zX3ZlcnNpb24YAyABKAlCA+BBAlITZGF0YVVzZVRlcm1z
VmVyc2lvbiIaChhQcm92aXNpb25Qcm9qZWN0TWV0YWRhdGEipAMKGlJlcG9ydENvbnNlbnRD
aGFuZ2VSZXF1ZXN0Eo0BChVjb25zZW50X2NoYW5nZV9hY3Rpb24YASABKA4yVC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuUmVwb3J0Q29uc2VudENoYW5nZVJlcXVl
c3QuQ29uc2VudENoYW5nZUFjdGlvbkID4EECUhNjb25zZW50Q2hhbmdlQWN0aW9uEkgKB3By
b2plY3QYAiABKAlCLuBBAvpBKAomZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1By
b2plY3RSB3Byb2plY3QSKwoPc2VydmljZV90ZXJtX2lkGAMgASgJQgPgQQJSDXNlcnZpY2VU
ZXJtSWQSNQoUc2VydmljZV90ZXJtX3ZlcnNpb24YBCABKAlCA+BBAlISc2VydmljZVRlcm1W
ZXJzaW9uIkgKE0NvbnNlbnRDaGFuZ2VBY3Rpb24SJQohQ09OU0VOVF9DSEFOR0VfQUNUSU9O
X1VOU1BFQ0lGSUVEEAASCgoGQUNDRVBUEAEyrwYKDlByb2plY3RTZXJ2aWNlEp8BCgpHZXRQ
cm9qZWN0EjcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdldFByb2pl
Y3RSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlByb2pl
Y3QiKYLT5JMCHBIaL3YxYWxwaGEve25hbWU9cHJvamVjdHMvKn3aQQRuYW1lEpkCChBQcm92
aXNpb25Qcm9qZWN0Ej0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlBy
b3Zpc2lvblByb2plY3RSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKm
AYLT5JMCKSIkL3YxYWxwaGEve25hbWU9cHJvamVjdHMvKn06cHJvdmlzaW9uOgEq2kEEbmFt
ZcpBbQosZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlByb2plY3QSPWdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Qcm92aXNpb25Qcm9qZWN0TWV0
YWRhdGESigIKE1JlcG9ydENvbnNlbnRDaGFuZ2USQC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuUmVwb3J0Q29uc2VudENoYW5nZVJlcXVlc3QaLS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuUHJvamVjdCKBAYLT5JMCNiIxL3YxYWxwaGEv
e3Byb2plY3Q9cHJvamVjdHMvKn06cmVwb3J0Q29uc2VudENoYW5nZToBKtpBQmNvbnNlbnRf
Y2hhbmdlX2FjdGlvbixwcm9qZWN0LHNlcnZpY2VfdGVybV9pZCxzZXJ2aWNlX3Rlcm1fdmVy
c2lvbhpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKfAgooY29tLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUITUHJvamVjdFNlcnZpY2VQcm90b1ABWlJjbG91
ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVu
Z2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNs
b3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVu
Z2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhh
SuImCgcSBQ4ArAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYAPAoJCgIDBRIDFwAtCggKAQgSAxkAQQoJCgIIJRIDGQBBCggKAQgSAxoAaQoJCgIICxID
GgBpCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANAoJCgIICBIDHAA0CggKAQgSAx0A
QQoJCgIIARIDHQBBCggKAQgSAx4ALQoJCgIIJBIDHgAtCggKAQgSAx8AQQoJCgIIKRIDHwBB
CggKAQgSAyAAQAoJCgIILRIDIABACmUKAgYAEgQkAFQBGlkgU2VydmljZSBmb3Igb3BlcmF0
aW9ucyBvbiB0aGUKIFtQcm9qZWN0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuUHJvamVjdF0uCgoKCgMGAAESAyQIFgoKCgMGAAMSAyUCRgoMCgUGAAOZCBIDJQJG
CgsKAwYAAxIEJgInNwoNCgUGAAOaCBIEJgInNwqHAQoEBgACABIEKwIwAxp5IEdldHMgYSBb
UHJvamVjdF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlByb2plY3Rd
LgogUmV0dXJucyBOT1RfRk9VTkQgd2hlbiB0aGUgcHJvamVjdCBpcyBub3QgeWV0IGNyZWF0
ZWQuCgoMCgUGAAIAARIDKwYQCgwKBQYAAgACEgMrESIKDAoFBgACAAMSAystNAoNCgUGAAIA
BBIELAQuBgoRCgkGAAIABLDKvCISBCwELgYKDAoFBgACAAQSAy8EMgoPCggGAAIABJsIABID
LwQyCqQCCgQGAAIBEgQ4AkMDGpUCIFByb3Zpc2lvbnMgdGhlIHByb2plY3QgcmVzb3VyY2Uu
IER1cmluZyB0aGUKIHByb2Nlc3MsIHJlbGF0ZWQgc3lzdGVtcyB3aWxsIGdldCBwcmVwYXJl
ZCBhbmQgaW5pdGlhbGl6ZWQuCgogQ2FsbGVyIG11c3QgcmVhZCB0aGUgW1Rlcm1zIGZvciBk
YXRhCiB1c2VdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXRhaWwvZGF0YS11c2UtdGVy
bXMpLCBhbmQgb3B0aW9uYWxseQogc3BlY2lmeSBpbiByZXF1ZXN0IHRvIHByb3ZpZGUgY29u
c2VudCB0byB0aGF0IHNlcnZpY2UgdGVybXMuCgoMCgUGAAIBARIDOAYWCgwKBQYAAgECEgM4
Fy4KDAoFBgACAQMSAzkPKwoNCgUGAAIBBBIEOgQ9BgoRCgkGAAIBBLDKvCISBDoEPQYKDAoF
BgACAQQSAz4EMgoPCggGAAIBBJsIABIDPgQyCg0KBQYAAgEEEgQ/BEIGCg8KBwYAAgEEmQgS
BD8EQgYK4wEKBAYAAgISBEwCUwMa1AEgVXBkYXRlcyBzZXJ2aWNlIHRlcm1zIGZvciB0aGlz
IHByb2plY3QuCgogVGhpcyBtZXRob2QgY2FuIGJlIHVzZWQgdG8gcmV0cm9hY3RpdmVseSBh
Y2NlcHQgdGhlIGxhdGVzdCB0ZXJtcy4KCiBUZXJtcyBhdmFpbGFibGUgZm9yIHVwZGF0ZToK
CiAqIFtUZXJtcyBmb3IgZGF0YSB1c2VdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXRh
aWwvZGF0YS11c2UtdGVybXMpCgoMCgUGAAICARIDTAYZCgwKBQYAAgICEgNMGjQKDAoFBgAC
AgMSA0w/RgoNCgUGAAICBBIETQRQBgoRCgkGAAICBLDKvCISBE0EUAYKDQoFBgACAgQSBFEE
Uk0KEAoIBgACAgSbCAASBFEEUk0KhwEKAgQAEgRZAGMBGnsgUmVxdWVzdCBtZXNzYWdlIGZv
cgogW1Byb2plY3RTZXJ2aWNlLkdldFByb2plY3RdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Qcm9qZWN0U2VydmljZS5HZXRQcm9qZWN0XQogbWV0aG9kLgoKCgoD
BAABEgNZCBkKmAEKBAQAAgASBF0CYgQaiQEgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFt
ZSBvZiBhCiBbUHJvamVjdF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlByb2plY3RdLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3RfaWRfb3JfbnVtYmVyfWAu
CgoMCgUEAAIABRIDXQIICgwKBQQAAgABEgNdCQ0KDAoFBAACAAMSA10QEQoNCgUEAAIACBIE
XRJiAwoPCggEAAIACJwIABIDXgQqCg8KBwQAAgAInwgSBF8EYQUKiwEKAgQBEgRoAH4BGn8g
UmVxdWVzdCBmb3IKIFtQcm9qZWN0U2VydmljZS5Qcm92aXNpb25Qcm9qZWN0XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuUHJvamVjdFNlcnZpY2UuUHJvdmlzaW9u
UHJvamVjdF0KIG1ldGhvZC4KCgoKAwQBARIDaAgfCpgBCgQEAQIAEgRsAnEEGokBIFJlcXVp
cmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgYQogW1Byb2plY3RdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Qcm9qZWN0XSwgc3VjaCBhcwogYHByb2plY3RzL3tw
cm9qZWN0X2lkX29yX251bWJlcn1gLgoKDAoFBAECAAUSA2wCCAoMCgUEAQIAARIDbAkNCgwK
BQQBAgADEgNsEBEKDQoFBAECAAgSBGwScQMKDwoIBAECAAicCAASA20EKgoPCgcEAQIACJ8I
EgRuBHAFCrUBCgQEAQIBEgN2AkoapwEgUmVxdWlyZWQuIFNldCB0byBgdHJ1ZWAgdG8gc3Bl
Y2lmeSB0aGF0IGNhbGxlciBoYXMgcmVhZCBhbmQgd291bGQgbGlrZSB0bwogZ2l2ZSBjb25z
ZW50IHRvIHRoZSBbVGVybXMgZm9yIGRhdGEKIHVzZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3JldGFpbC9kYXRhLXVzZS10ZXJtcykuCgoMCgUEAQIBBRIDdgIGCgwKBQQBAgEBEgN2
BxwKDAoFBAECAQMSA3YfIAoMCgUEAQIBCBIDdiFJCg8KCAQBAgEInAgAEgN2IkgK8AEKBAQB
AgISA30CTRriASBSZXF1aXJlZC4gVGhlIHZlcnNpb24gb2YgdGhlIFtUZXJtcyBmb3IgZGF0
YQogdXNlXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RhdGEtdXNlLXRlcm1z
KSB0aGF0IGNhbGxlciBoYXMgcmVhZAogYW5kIHdvdWxkIGxpa2UgdG8gZ2l2ZSBjb25zZW50
IHRvLgoKIEFjY2VwdGFibGUgdmVyc2lvbiBpcyBgMjAyMi0xMS0yM2AsIGFuZCB0aGlzIG1h
eSBjaGFuZ2Ugb3ZlciB0aW1lLgoKDAoFBAECAgUSA30CCAoMCgUEAQICARIDfQkfCgwKBQQB
AgIDEgN9IiMKDAoFBAECAggSA30kTAoPCggEAQICCJwIABIDfSVLCkUKAgQCEgSBAQAjGjkg
TWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIGEgcHJvamVjdCBwcm92aXNpb24gb3BlcmF0aW9u
LgoKCwoDBAIBEgSBAQggCjcKAgQDEgaEAQCsAQEaKSBSZXF1ZXN0IGZvciBSZXBvcnRDb25z
ZW50Q2hhbmdlIG1ldGhvZC4KCgsKAwQDARIEhAEIIgp5CgQEAwQAEgaIAQKOAQMaaSBUeXBl
IG9mIGNvbnNlbnQgYWNrbm93bGVkZ2VtZW50IChhY2NlcHQgLyByZWplY3QpLgoKIEF0IHRo
aXMgbW9tZW50LCBvbmx5IGBBQ0NFUFRgIGFjdGlvbiBpcyBzdXBwb3J0ZWQuCgoNCgUEAwQA
ARIEiAEHGgpCCgYEAwQAAgASBIoBBCoaMiBJbnZhbGlkIGFjdGlvbiwgdXNlciBtdXN0IHNw
ZWNpZnkgYWNjZXB0L2RlY2xpbmUKCg8KBwQDBAACAAESBIoBBCUKDwoHBAMEAAIAAhIEigEo
KQotCgYEAwQAAgESBI0BBA8aHSBVc2VyIGFjY2VwdHMgc2VydmljZSB0ZXJtcy4KCg8KBwQD
BAACAQESBI0BBAoKDwoHBAMEAAIBAhIEjQENDgqKAQoEBAMCABIGkwEClAEvGnogUmVxdWly
ZWQuIFdoZXRoZXIgY3VzdG9tZXIgZGVjaWRlcyB0byBhY2NlcHQgb3IgZGVjbGluZSBzZXJ2
aWNlIHRlcm0uCgogQXQgdGhpcyBtb21lbnQsIG9ubHkgYWNjZXB0IGFjdGlvbiBpcyBzdXBw
b3J0ZWQuCgoNCgUEAwIABhIEkwECFQoNCgUEAwIAARIEkwEWKwoNCgUEAwIAAxIEkwEuLwoN
CgUEAwIACBIElAEGLgoQCggEAwIACJwIABIElAEHLQqaAQoEBAMCARIGmQECngEEGokBIFJl
cXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgYQogW1Byb2plY3RdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Qcm9qZWN0XSwgc3VjaCBhcwogYHByb2plY3Rz
L3twcm9qZWN0X2lkX29yX251bWJlcn1gLgoKDQoFBAMCAQUSBJkBAggKDQoFBAMCAQESBJkB
CRAKDQoFBAMCAQMSBJkBExQKDwoFBAMCAQgSBpkBFZ4BAwoQCggEAwIBCJwIABIEmgEEKgoR
CgcEAwIBCJ8IEgabAQSdAQUKhAMKBAQDAgISBKgBAkYa9QIgUmVxdWlyZWQuIFRoZSB1bmlx
dWUgaWRlbnRpZmllciBvZiB0aGUgdGVybXMgb2Ygc2VydmljZSB0byB1cGRhdGUuCiBBdmFp
bGFibGUgdGVybSBpZHM6CgogKiBgR0FfREFUQV9VU0VfVEVSTVNgOiBbVGVybXMgZm9yIGRh
dGEKIHVzZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9kYXRhLXVzZS10ZXJt
cykuIFdoZW4gdXNpbmcgdGhpcwogc2VydmljZSB0ZXJtIGlkLCB0aGUgYWNjZXB0YWJsZQog
W3NlcnZpY2VfdGVybV92ZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuUmVwb3J0Q29uc2VudENoYW5nZVJlcXVlc3Quc2VydmljZV90ZXJtX3ZlcnNpb25d
CiB0byBwcm92aWRlIGlzIGAyMDIyLTExLTIzYC4KCg0KBQQDAgIFEgSoAQIICg0KBQQDAgIB
EgSoAQkYCg0KBQQDAgIDEgSoARscCg0KBQQDAgIIEgSoAR1FChAKCAQDAgIInAgAEgSoAR5E
Ck8KBAQDAgMSBKsBAksaQSBSZXF1aXJlZC4gVGhlIHZlcnNpb24gc3RyaW5nIG9mIHRoZSB0
ZXJtcyBvZiBzZXJ2aWNlIHRvIHVwZGF0ZS4KCg0KBQQDAgMFEgSrAQIICg0KBQQDAgMBEgSr
AQkdCg0KBQQDAgMDEgSrASAhCg0KBQQDAgMIEgSrASJKChAKCAQDAgMInAgAEgSrASNJYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest ===
    # Fields for GetProjectRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest ===
    # Fields for ProvisionProjectRequest
    # Field: name Type: 9 ()
    # Field: accept_data_use_terms Type: 8 ()
    # Field: data_use_terms_version Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectMetadata ===
    # Fields for ProvisionProjectMetadata

# === Message: Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest ===
    # Fields for ReportConsentChangeRequest
    # Field: consent_change_action Type: 14 (.google.cloud.discoveryengine.v1alpha.ReportConsentChangeRequest.ConsentChangeAction)
    # Field: project Type: 9 ()
    # Field: service_term_id Type: 9 ()
    # Field: service_term_version Type: 9 ()

# Enum: ReportConsentChangeRequest::ConsentChangeAction
our $ReportConsentChangeRequest_CONSENT_CHANGE_ACTION_UNSPECIFIED = 0;
our $ReportConsentChangeRequest_ACCEPT = 1;

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProjectServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub get_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'GetProject',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Project::Project',
    });
}

sub provision_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'ProvisionProject',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub report_consent_change {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'ReportConsentChange',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Project::Project',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ProjectService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/project_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::ProjectService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/project_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest

Request message for
[ProjectService.GetProject][google.cloud.discoveryengine.v1alpha.ProjectService.GetProject]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of a
[Project][google.cloud.discoveryengine.v1alpha.Project], such as
`projects/{project_id_or_number}`.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest

Request for
[ProjectService.ProvisionProject][google.cloud.discoveryengine.v1alpha.ProjectService.ProvisionProject]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of a
[Project][google.cloud.discoveryengine.v1alpha.Project], such as
`projects/{project_id_or_number}`.

=item * C<< $msg->accept_data_use_terms() >> / C<< $msg->accept_data_use_terms($value) >>

Type: C<Bool>

Required. Set to `true` to specify that caller has read and would like to
give consent to the [Terms for data
use](https://cloud.google.com/retail/data-use-terms).

=item * C<< $msg->data_use_terms_version() >> / C<< $msg->data_use_terms_version($value) >>

Type: C<String>

Required. The version of the [Terms for data
use](https://cloud.google.com/retail/data-use-terms) that caller has read
and would like to give consent to.

Acceptable version is `2022-11-23`, and this may change over time.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectMetadata

Metadata associated with a project provision operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest

Request for ReportConsentChange method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->consent_change_action() >> / C<< $msg->consent_change_action($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::ReportConsentChangeRequest::ConsentChangeAction>)

Required. Whether customer decides to accept or decline service term.

At this moment, only accept action is supported.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Full resource name of a
[Project][google.cloud.discoveryengine.v1alpha.Project], such as
`projects/{project_id_or_number}`.

=item * C<< $msg->service_term_id() >> / C<< $msg->service_term_id($value) >>

Type: C<String>

Required. The unique identifier of the terms of service to update.
Available term ids:

* `GA_DATA_USE_TERMS`: [Terms for data
use](https://cloud.google.com/retail/data-use-terms). When using this
service term id, the acceptable
[service_term_version][google.cloud.discoveryengine.v1alpha.ReportConsentChangeRequest.service_term_version]
to provide is `2022-11-23`.

=item * C<< $msg->service_term_version() >> / C<< $msg->service_term_version($value) >>

Type: C<String>

Required. The version string of the terms of service to update.

=back

=head3 Enum: ReportConsentChangeRequest::ConsentChangeAction

=over 4

=item * C<CONSENT_CHANGE_ACTION_UNSPECIFIED> => C<0>

=item * C<ACCEPT> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::ProjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
