package Google::Cloud::Talent::V4beta1::CompletionService;

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
    eval { require Google::Cloud::Talent::V4beta1::Common };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvY29tcGxldGlvbl9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvdGFs
ZW50L3Y0YmV0YTEvY29tbW9uLnByb3RvItEEChRDb21wbGV0ZVF1ZXJ5UmVxdWVzdBI7CgZw
YXJlbnQYASABKAlCI+BBAvpBHRIbam9icy5nb29nbGVhcGlzLmNvbS9Db21wYW55UgZwYXJl
bnQSGQoFcXVlcnkYAiABKAlCA+BBAlIFcXVlcnkSJQoObGFuZ3VhZ2VfY29kZXMYAyADKAlS
DWxhbmd1YWdlQ29kZXMSIAoJcGFnZV9zaXplGAQgASgFQgPgQQJSCHBhZ2VTaXplEjoKB2Nv
bXBhbnkYBSABKAlCIPpBHQobam9icy5nb29nbGVhcGlzLmNvbS9Db21wYW55Ugdjb21wYW55
ElcKBXNjb3BlGAYgASgOMkEuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBsZXRl
UXVlcnlSZXF1ZXN0LkNvbXBsZXRpb25TY29wZVIFc2NvcGUSVAoEdHlwZRgHIAEoDjJALmdv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5Db21wbGV0
aW9uVHlwZVIEdHlwZSJLCg9Db21wbGV0aW9uU2NvcGUSIAocQ09NUExFVElPTl9TQ09QRV9V
TlNQRUNJRklFRBAAEgoKBlRFTkFOVBABEgoKBlBVQkxJQxACImAKDkNvbXBsZXRpb25UeXBl
Eh8KG0NPTVBMRVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEg0KCUpPQl9USVRMRRABEhAKDENP
TVBBTllfTkFNRRACEgwKCENPTUJJTkVEEAMi/gIKFUNvbXBsZXRlUXVlcnlSZXNwb25zZRJy
ChJjb21wbGV0aW9uX3Jlc3VsdHMYASADKAsyQy5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuQ29tcGxldGVRdWVyeVJlc3BvbnNlLkNvbXBsZXRpb25SZXN1bHRSEWNvbXBsZXRpb25S
ZXN1bHRzEkkKCG1ldGFkYXRhGAIgASgLMi0uZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGEx
LlJlc3BvbnNlTWV0YWRhdGFSCG1ldGFkYXRhGqUBChBDb21wbGV0aW9uUmVzdWx0Eh4KCnN1
Z2dlc3Rpb24YASABKAlSCnN1Z2dlc3Rpb24SVAoEdHlwZRgCIAEoDjJALmdvb2dsZS5jbG91
ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5Db21wbGV0aW9uVHlwZVIE
dHlwZRIbCglpbWFnZV91cmkYAyABKAlSCGltYWdlVXJpMtUCCgpDb21wbGV0aW9uEtgBCg1D
b21wbGV0ZVF1ZXJ5EjEuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBsZXRlUXVl
cnlSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBsZXRlUXVlcnlS
ZXNwb25zZSJggtPkkwJaEi8vdjRiZXRhMS97cGFyZW50PXByb2plY3RzLyovdGVuYW50cy8q
fTpjb21wbGV0ZVonEiUvdjRiZXRhMS97cGFyZW50PXByb2plY3RzLyp9OmNvbXBsZXRlGmzK
QRNqb2JzLmdvb2dsZWFwaXMuY29t0kFTaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2pvYnNC
egofY29tLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMUIWQ29tcGxldGlvblNlcnZpY2VQ
cm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL3RhbGVudC9hcGl2NGJldGExL3RhbGVudHBi
O3RhbGVudHBiogIDQ1RTSu8qCgcSBQ4AqwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
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
aWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkK
AgMDEgMVACMKCQoCAwQSAxYAMgoICgEIEgMYAE4KCQoCCAsSAxgATgoICgEIEgMZACIKCQoC
CAoSAxkAIgoICgEIEgMaADcKCQoCCAgSAxoANwoICgEIEgMbADgKCQoCCAESAxsAOAoICgEI
EgMcACEKCQoCCCQSAxwAIQowCgIGABIEHwAtARokIEEgc2VydmljZSBoYW5kbGVzIGF1dG8g
Y29tcGxldGlvbi4KCgoKAwYAARIDHwgSCgoKAwYAAxIDIAI7CgwKBQYAA5kIEgMgAjsKCwoD
BgADEgQhAiMtCg0KBQYAA5oIEgQhAiMtCoQBCgQGAAIAEgQnAiwDGnYgQ29tcGxldGVzIHRo
ZSBzcGVjaWZpZWQgcHJlZml4IHdpdGgga2V5d29yZCBzdWdnZXN0aW9ucy4KIEludGVuZGVk
IGZvciB1c2UgYnkgYSBqb2Igc2VhcmNoIGF1dG8tY29tcGxldGUgc2VhcmNoIGJveC4KCgwK
BQYAAgABEgMnBhMKDAoFBgACAAISAycUKAoMCgUGAAIAAxIDJzNICg0KBQYAAgAEEgQoBCsG
ChEKCQYAAgAEsMq8IhIEKAQrBgooCgIEABIFMACUAQEaGyBBdXRvLWNvbXBsZXRlIHBhcmFt
ZXRlcnMuCgoKCgMEAAESAzAIHAo4CgQEAAQAEgQyAjwDGiogRW51bSB0byBzcGVjaWZ5IHRo
ZSBzY29wZSBvZiBjb21wbGV0aW9uLgoKDAoFBAAEAAESAzIHFgofCgYEAAQAAgASAzQEJRoQ
IERlZmF1bHQgdmFsdWUuCgoOCgcEAAQAAgABEgM0BCAKDgoHBAAEAAIAAhIDNCMkCk8KBgQA
BAACARIDNwQPGkAgU3VnZ2VzdGlvbnMgYXJlIGJhc2VkIG9ubHkgb24gdGhlIGRhdGEgcHJv
dmlkZWQgYnkgdGhlIGNsaWVudC4KCg4KBwQABAACAQESAzcECgoOCgcEAAQAAgECEgM3DQ4K
YwoGBAAEAAICEgM7BA8aVCBTdWdnZXN0aW9ucyBhcmUgYmFzZWQgb24gYWxsIGpvYnMgZGF0
YSBpbiB0aGUgc3lzdGVtIHRoYXQncyB2aXNpYmxlIHRvCiB0aGUgY2xpZW50CgoOCgcEAAQA
AgIBEgM7BAoKDgoHBAAEAAICAhIDOw0OCjcKBAQABAESBD8CXwMaKSBFbnVtIHRvIHNwZWNp
ZnkgYXV0by1jb21wbGV0aW9uIHRvcGljcy4KCgwKBQQABAEBEgM/BxUKHwoGBAAEAQIAEgNB
BCQaECBEZWZhdWx0IHZhbHVlLgoKDgoHBAAEAQIAARIDQQQfCg4KBwQABAECAAISA0EiIwqu
AgoGBAAEAQIBEgNKBBIangIgU3VnZ2VzdCBqb2IgdGl0bGVzIGZvciBqb2JzIGF1dG9jb21w
bGV0ZS4KCiBGb3IKIFtDb21wbGV0aW9uVHlwZS5KT0JfVElUTEVdW2dvb2dsZS5jbG91ZC50
YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5Db21wbGV0aW9uVHlwZS5KT0Jf
VElUTEVdCiB0eXBlLCBvbmx5IG9wZW4gam9icyB3aXRoIHRoZSBzYW1lCiBbbGFuZ3VhZ2Vf
Y29kZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVz
dC5sYW5ndWFnZV9jb2Rlc10KIGFyZSByZXR1cm5lZC4KCg4KBwQABAECAQESA0oEDQoOCgcE
AAQBAgECEgNKEBEKyAIKBgQABAECAhIDUwQVGrgCIFN1Z2dlc3QgY29tcGFueSBuYW1lcyBm
b3Igam9icyBhdXRvY29tcGxldGUuCgogRm9yCiBbQ29tcGxldGlvblR5cGUuQ09NUEFOWV9O
QU1FXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGxldGVRdWVyeVJlcXVlc3Qu
Q29tcGxldGlvblR5cGUuQ09NUEFOWV9OQU1FXQogdHlwZSwgb25seSBjb21wYW5pZXMgaGF2
aW5nIG9wZW4gam9icyB3aXRoIHRoZSBzYW1lCiBbbGFuZ3VhZ2VfY29kZXNdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5sYW5ndWFnZV9jb2Rl
c10KIGFyZSByZXR1cm5lZC4KCg4KBwQABAECAgESA1MEEAoOCgcEAAQBAgICEgNTExQKwwMK
BgQABAECAxIDXgQRGrMDIFN1Z2dlc3QgYm90aCBqb2IgdGl0bGVzIGFuZCBjb21wYW55IG5h
bWVzIGZvciBqb2JzIGF1dG9jb21wbGV0ZS4KCiBGb3IKIFtDb21wbGV0aW9uVHlwZS5DT01C
SU5FRF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBsZXRlUXVlcnlSZXF1ZXN0
LkNvbXBsZXRpb25UeXBlLkNPTUJJTkVEXQogdHlwZSwgb25seSBvcGVuIGpvYnMgd2l0aCB0
aGUgc2FtZQogW2xhbmd1YWdlX2NvZGVzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEu
Q29tcGxldGVRdWVyeVJlcXVlc3QubGFuZ3VhZ2VfY29kZXNdCiBvciBjb21wYW5pZXMgaGF2
aW5nIG9wZW4gam9icyB3aXRoIHRoZSBzYW1lCiBbbGFuZ3VhZ2VfY29kZXNdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5sYW5ndWFnZV9jb2Rl
c10KIGFyZSByZXR1cm5lZC4KCg4KBwQABAECAwESA14EDAoOCgcEAAQBAgMCEgNeDxAKlQIK
BAQAAgASBGgCbQQahgIgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGVuYW50IHRoZSBj
b21wbGV0aW9uIGlzIHBlcmZvcm1lZCB3aXRoaW4uCgogVGhlIGZvcm1hdCBpcyAicHJvamVj
dHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9pZH0iLCBmb3IgZXhhbXBsZSwKICJw
cm9qZWN0cy9mb28vdGVuYW50L2JhciIuCgogSWYgdGVuYW50IGlkIGlzIHVuc3BlY2lmaWVk
LCB0aGUgZGVmYXVsdCB0ZW5hbnQgaXMgdXNlZCwgZm9yCiBleGFtcGxlLCAicHJvamVjdHMv
Zm9vIi4KCgwKBQQAAgAFEgNoAggKDAoFBAACAAESA2gJDwoMCgUEAAIAAxIDaBITCg0KBQQA
AgAIEgRoFG0DCg8KCAQAAgAInAgAEgNpBCoKDwoHBAACAAifCBIEagRsBQpzCgQEAAIBEgNy
AjwaZiBSZXF1aXJlZC4gVGhlIHF1ZXJ5IHVzZWQgdG8gZ2VuZXJhdGUgc3VnZ2VzdGlvbnMu
CgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAyNTUuCgoM
CgUEAAIBBRIDcgIICgwKBQQAAgEBEgNyCQ4KDAoFBAACAQMSA3IREgoMCgUEAAIBCBIDchM7
Cg8KCAQAAgEInAgAEgNyFDoKiAIKBAQAAgISA3oCJRr6ASBUaGUgbGlzdCBvZiBsYW5ndWFn
ZXMgb2YgdGhlIHF1ZXJ5LiBUaGlzIGlzCiB0aGUgQkNQLTQ3IGxhbmd1YWdlIGNvZGUsIHN1
Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2Vl
CiBbVGFncyBmb3IgSWRlbnRpZnlpbmcgTGFuZ3VhZ2VzXShodHRwczovL3Rvb2xzLmlldGYu
b3JnL2h0bWwvYmNwNDcpLgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJh
Y3RlcnMgaXMgMjU1LgoKDAoFBAACAgQSA3oCCgoMCgUEAAICBRIDegsRCgwKBQQAAgIBEgN6
EiAKDAoFBAACAgMSA3ojJApYCgQEAAIDEgN/Aj8aSyBSZXF1aXJlZC4gQ29tcGxldGlvbiBy
ZXN1bHQgY291bnQuCgogVGhlIG1heGltdW0gYWxsb3dlZCBwYWdlIHNpemUgaXMgMTAuCgoM
CgUEAAIDBRIDfwIHCgwKBQQAAgMBEgN/CBEKDAoFBAACAwMSA38UFQoMCgUEAAIDCBIDfxY+
Cg8KCAQAAgMInAgAEgN/Fz0KsAIKBAQAAgQSBokBAosBBBqfAiBJZiBwcm92aWRlZCwgcmVz
dHJpY3RzIGNvbXBsZXRpb24gdG8gc3BlY2lmaWVkIGNvbXBhbnkuCgogVGhlIGZvcm1hdCBp
cwogInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9L2NvbXBhbmll
cy97Y29tcGFueV9pZH0iLCBmb3IKIGV4YW1wbGUsICJwcm9qZWN0cy9mb28vdGVuYW50cy9i
YXIvY29tcGFuaWVzL2JheiIuCgogSWYgdGVuYW50IGlkIGlzIHVuc3BlY2lmaWVkLCB0aGUg
ZGVmYXVsdCB0ZW5hbnQgaXMgdXNlZCwgZm9yCiBleGFtcGxlLCAicHJvamVjdHMvZm9vIi4K
Cg0KBQQAAgQFEgSJAQIICg0KBQQAAgQBEgSJAQkQCg0KBQQAAgQDEgSJARMUCg8KBQQAAgQI
EgaJARWLAQMKDwoHBAACBAifCBIEigEETQqhAQoEBAACBRIEjwECHBqSASBUaGUgc2NvcGUg
b2YgdGhlIGNvbXBsZXRpb24uIFRoZSBkZWZhdWx0cyBpcwogW0NvbXBsZXRpb25TY29wZS5Q
VUJMSUNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVz
dC5Db21wbGV0aW9uU2NvcGUuUFVCTElDXS4KCg0KBQQAAgUGEgSPAQIRCg0KBQQAAgUBEgSP
ARIXCg0KBQQAAgUDEgSPARobCpsBCgQEAAIGEgSTAQIaGowBIFRoZSBjb21wbGV0aW9uIHRv
cGljLiBUaGUgZGVmYXVsdCBpcwogW0NvbXBsZXRpb25UeXBlLkNPTUJJTkVEXVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGxldGVRdWVyeVJlcXVlc3QuQ29tcGxldGlvblR5
cGUuQ09NQklORURdLgoKDQoFBAACBgYSBJMBAhAKDQoFBAACBgESBJMBERUKDQoFBAACBgMS
BJMBGBkKMAoCBAESBpcBAKsBARoiIFJlc3BvbnNlIG9mIGF1dG8tY29tcGxldGUgcXVlcnku
CgoLCgMEAQESBJcBCB0KPgoEBAEDABIGmQECowEDGi4gUmVzb3VyY2UgdGhhdCByZXByZXNl
bnRzIGNvbXBsZXRpb24gcmVzdWx0cy4KCg0KBQQBAwABEgSZAQoaCi8KBgQBAwACABIEmwEE
GhofIFRoZSBzdWdnZXN0aW9uIGZvciB0aGUgcXVlcnkuCgoPCgcEAQMAAgAFEgSbAQQKCg8K
BwQBAwACAAESBJsBCxUKDwoHBAEDAAIAAxIEmwEYGQonCgYEAQMAAgESBJ4BBDEaFyBUaGUg
Y29tcGxldGlvbiB0b3BpYy4KCg8KBwQBAwACAQYSBJ4BBCcKDwoHBAEDAAIBARIEngEoLAoP
CgcEAQMAAgEDEgSeAS8wCpIBCgYEAQMAAgISBKIBBBkagQEgVGhlIFVSSSBvZiB0aGUgY29t
cGFueSBpbWFnZSBmb3IKIFtDT01QQU5ZX05BTUVdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRi
ZXRhMS5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5Db21wbGV0aW9uVHlwZS5DT01QQU5ZX05BTUVd
LgoKDwoHBAEDAAICBRIEogEECgoPCgcEAQMAAgIBEgSiAQsUCg8KBwQBAwACAgMSBKIBFxgK
PwoEBAECABIEpgECMxoxIFJlc3VsdHMgb2YgdGhlIG1hdGNoaW5nIGpvYi9jb21wYW55IGNh
bmRpZGF0ZXMuCgoNCgUEAQIABBIEpgECCgoNCgUEAQIABhIEpgELGwoNCgUEAQIAARIEpgEc
LgoNCgUEAQIAAxIEpgExMgpgCgQEAQIBEgSqAQIgGlIgQWRkaXRpb25hbCBpbmZvcm1hdGlv
biBmb3IgdGhlIEFQSSBpbnZvY2F0aW9uLCBzdWNoIGFzIHRoZSByZXF1ZXN0CiB0cmFja2lu
ZyBpZC4KCg0KBQQBAgEGEgSqAQISCg0KBQQBAgEBEgSqARMbCg0KBQQBAgEDEgSqAR4fYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest ===
    # Fields for CompleteQueryRequest
    # Field: parent Type: 9 ()
    # Field: query Type: 9 ()
    # Field: language_codes Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: company Type: 9 ()
    # Field: scope Type: 14 (.google.cloud.talent.v4beta1.CompleteQueryRequest.CompletionScope)
    # Field: type Type: 14 (.google.cloud.talent.v4beta1.CompleteQueryRequest.CompletionType)

# Enum: CompleteQueryRequest::CompletionScope
our $CompleteQueryRequest_COMPLETION_SCOPE_UNSPECIFIED = 0;
our $CompleteQueryRequest_TENANT = 1;
our $CompleteQueryRequest_PUBLIC = 2;

# Enum: CompleteQueryRequest::CompletionType
our $CompleteQueryRequest_COMPLETION_TYPE_UNSPECIFIED = 0;
our $CompleteQueryRequest_JOB_TITLE = 1;
our $CompleteQueryRequest_COMPANY_NAME = 2;
our $CompleteQueryRequest_COMBINED = 3;

# === Message: Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: completion_results Type: 11 (.google.cloud.talent.v4beta1.CompleteQueryResponse.CompletionResult)
    # Field: metadata Type: 11 (.google.cloud.talent.v4beta1.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4beta1::CompletionService::CompletionClient ===
package Google::Cloud::Talent::V4beta1::CompletionService::CompletionClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4beta1::CompletionService::CompletionClient

Client stub representing the remote C<Completion> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<talent.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'talent.googleapis.com:443' );

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

sub complete_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.Completion',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::CompletionService - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::CompletionService;

    my $msg = Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest->new({
        parent => $parent,
        query => $query,
        language_codes => $language_codes,
        page_size => $page_size,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest

Auto-complete parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of tenant the completion is performed within.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenant/bar".

If tenant id is unspecified, the default tenant is used, for
example, "projects/foo".

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The query used to generate suggestions.

The maximum number of allowed characters is 255.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

The list of languages of the query. This is
the BCP-47 language code, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

The maximum number of allowed characters is 255.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Required. Completion result count.

The maximum allowed page size is 10.

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<String>

If provided, restricts completion to specified company.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/foo/tenants/bar/companies/baz".

If tenant id is unspecified, the default tenant is used, for
example, "projects/foo".

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CompleteQueryRequest::CompletionScope>)

The scope of the completion. The defaults is
[CompletionScope.PUBLIC][google.cloud.talent.v4beta1.CompleteQueryRequest.CompletionScope.PUBLIC].

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CompleteQueryRequest::CompletionType>)

The completion topic. The default is
[CompletionType.COMBINED][google.cloud.talent.v4beta1.CompleteQueryRequest.CompletionType.COMBINED].

=back

=head3 Enum: CompleteQueryRequest::CompletionScope

=over 4

=item * C<COMPLETION_SCOPE_UNSPECIFIED> => C<0>

=item * C<TENANT> => C<1>

=item * C<PUBLIC> => C<2>

=back

=head3 Enum: CompleteQueryRequest::CompletionType

=over 4

=item * C<COMPLETION_TYPE_UNSPECIFIED> => C<0>

=item * C<JOB_TITLE> => C<1>

=item * C<COMPANY_NAME> => C<2>

=item * C<COMBINED> => C<3>

=back

=head2 Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse

Response of auto-complete query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_results() >> / C<< $msg->completion_results($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse::CompletionResult>)

Results of the matching job/company candidates.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
