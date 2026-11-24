package Google::Cloud::Policysimulator::V1::Explanations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvcG9saWN5c2ltdWxhdG9yL3YxL2V4cGxhbmF0aW9ucy5wcm90bxIf
Z29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3kucHJvdG8aFmdvb2dsZS90eXBlL2V4
cHIucHJvdG8iiAEKC0FjY2Vzc1R1cGxlEiEKCXByaW5jaXBhbBgBIAEoCUID4EECUglwcmlu
Y2lwYWwSMQoSZnVsbF9yZXNvdXJjZV9uYW1lGAIgASgJQgPgQQJSEGZ1bGxSZXNvdXJjZU5h
bWUSIwoKcGVybWlzc2lvbhgDIAEoCUID4EECUgpwZXJtaXNzaW9uIu8CCg9FeHBsYWluZWRQ
b2xpY3kSRAoGYWNjZXNzGAEgASgOMiwuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52
MS5BY2Nlc3NTdGF0ZVIGYWNjZXNzEiwKEmZ1bGxfcmVzb3VyY2VfbmFtZRgCIAEoCVIQZnVs
bFJlc291cmNlTmFtZRItCgZwb2xpY3kYAyABKAsyFS5nb29nbGUuaWFtLnYxLlBvbGljeVIG
cG9saWN5EmYKFGJpbmRpbmdfZXhwbGFuYXRpb25zGAQgAygLMjMuZ29vZ2xlLmNsb3VkLnBv
bGljeXNpbXVsYXRvci52MS5CaW5kaW5nRXhwbGFuYXRpb25SE2JpbmRpbmdFeHBsYW5hdGlv
bnMSUQoJcmVsZXZhbmNlGAUgASgOMjMuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52
MS5IZXVyaXN0aWNSZWxldmFuY2VSCXJlbGV2YW5jZSLYCQoSQmluZGluZ0V4cGxhbmF0aW9u
EkkKBmFjY2VzcxgBIAEoDjIsLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuQWNj
ZXNzU3RhdGVCA+BBAlIGYWNjZXNzEhIKBHJvbGUYAiABKAlSBHJvbGUSawoPcm9sZV9wZXJt
aXNzaW9uGAMgASgOMkIuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5CaW5kaW5n
RXhwbGFuYXRpb24uUm9sZVBlcm1pc3Npb25SDnJvbGVQZXJtaXNzaW9uEm8KGXJvbGVfcGVy
bWlzc2lvbl9yZWxldmFuY2UYBCABKA4yMy5nb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9y
LnYxLkhldXJpc3RpY1JlbGV2YW5jZVIXcm9sZVBlcm1pc3Npb25SZWxldmFuY2USZgoLbWVt
YmVyc2hpcHMYBSADKAsyRC5nb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkJpbmRp
bmdFeHBsYW5hdGlvbi5NZW1iZXJzaGlwc0VudHJ5UgttZW1iZXJzaGlwcxJRCglyZWxldmFu
Y2UYBiABKA4yMy5nb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkhldXJpc3RpY1Jl
bGV2YW5jZVIJcmVsZXZhbmNlEi8KCWNvbmRpdGlvbhgHIAEoCzIRLmdvb2dsZS50eXBlLkV4
cHJSCWNvbmRpdGlvbhrIAQoTQW5ub3RhdGVkTWVtYmVyc2hpcBJeCgptZW1iZXJzaGlwGAEg
ASgOMj4uZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5CaW5kaW5nRXhwbGFuYXRp
b24uTWVtYmVyc2hpcFIKbWVtYmVyc2hpcBJRCglyZWxldmFuY2UYAiABKA4yMy5nb29nbGUu
Y2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkhldXJpc3RpY1JlbGV2YW5jZVIJcmVsZXZhbmNl
GocBChBNZW1iZXJzaGlwc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5El0KBXZhbHVlGAIgASgL
MkcuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5CaW5kaW5nRXhwbGFuYXRpb24u
QW5ub3RhdGVkTWVtYmVyc2hpcFIFdmFsdWU6AjgBIpoBCg5Sb2xlUGVybWlzc2lvbhIfChtS
T0xFX1BFUk1JU1NJT05fVU5TUEVDSUZJRUQQABIcChhST0xFX1BFUk1JU1NJT05fSU5DTFVE
RUQQARIgChxST0xFX1BFUk1JU1NJT05fTk9UX0lOQ0xVREVEEAISJwojUk9MRV9QRVJNSVNT
SU9OX1VOS05PV05fSU5GT19ERU5JRUQQAyKmAQoKTWVtYmVyc2hpcBIaChZNRU1CRVJTSElQ
X1VOU1BFQ0lGSUVEEAASFwoTTUVNQkVSU0hJUF9JTkNMVURFRBABEhsKF01FTUJFUlNISVBf
Tk9UX0lOQ0xVREVEEAISIgoeTUVNQkVSU0hJUF9VTktOT1dOX0lORk9fREVOSUVEEAMSIgoe
TUVNQkVSU0hJUF9VTktOT1dOX1VOU1VQUE9SVEVEEAQqewoLQWNjZXNzU3RhdGUSHAoYQUND
RVNTX1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHR1JBTlRFRBABEg8KC05PVF9HUkFOVEVEEAIS
FwoTVU5LTk9XTl9DT05ESVRJT05BTBADEhcKE1VOS05PV05fSU5GT19ERU5JRUQQBCpPChJI
ZXVyaXN0aWNSZWxldmFuY2USIwofSEVVUklTVElDX1JFTEVWQU5DRV9VTlNQRUNJRklFRBAA
EgoKBk5PUk1BTBABEggKBEhJR0gQAkLyAQojY29tLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11
bGF0b3IudjFCEUV4cGxhbmF0aW9uc1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vcG9s
aWN5c2ltdWxhdG9yL2FwaXYxL3BvbGljeXNpbXVsYXRvcnBiO3BvbGljeXNpbXVsYXRvcnBi
qgIfR29vZ2xlLkNsb3VkLlBvbGljeVNpbXVsYXRvci5WMcoCH0dvb2dsZVxDbG91ZFxQb2xp
Y3lTaW11bGF0b3JcVjHqAiJHb29nbGU6OkNsb3VkOjpQb2xpY3lTaW11bGF0b3I6OlYxStVO
CgcSBQ4AggIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAo
CgkKAgMAEgMSACkKCQoCAwESAxMAJAoJCgIDAhIDFAAgCggKAQgSAxYAPAoJCgIIJRIDFgA8
CggKAQgSAxcAZAoJCgIICxIDFwBkCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMgoJ
CgIICBIDGQAyCggKAQgSAxoAPAoJCgIIARIDGgA8CggKAQgSAxsAPAoJCgIIKRIDGwA8CggK
AQgSAxwAOwoJCgIILRIDHAA7CkIKAgUAEgQfADEBGjYgV2hldGhlciBhIHByaW5jaXBhbCBo
YXMgYSBwZXJtaXNzaW9uIGZvciBhIHJlc291cmNlLgoKCgoDBQABEgMfBRAKMwoEBQACABID
IQIfGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoMCgUFAAIAARID
IQIaCgwKBQUAAgACEgMhHR4KMAoEBQACARIDJAIOGiMgVGhlIHByaW5jaXBhbCBoYXMgdGhl
IHBlcm1pc3Npb24uCgoMCgUFAAIBARIDJAIJCgwKBQUAAgECEgMkDA0KOgoEBQACAhIDJwIS
Gi0gVGhlIHByaW5jaXBhbCBkb2VzIG5vdCBoYXZlIHRoZSBwZXJtaXNzaW9uLgoKDAoFBQAC
AgESAycCDQoMCgUFAAICAhIDJxARCmQKBAUAAgMSAysCGhpXIFRoZSBwcmluY2lwYWwgaGFz
IHRoZSBwZXJtaXNzaW9uIG9ubHkgaWYgYSBjb25kaXRpb24gZXhwcmVzc2lvbiBldmFsdWF0
ZXMKIHRvIGB0cnVlYC4KCgwKBQUAAgMBEgMrAhUKDAoFBQACAwISAysYGQqwAQoEBQACBBID
MAIaGqIBIFRoZSB1c2VyIHdobyBjcmVhdGVkIHRoZQogW1JlcGxheV1bZ29vZ2xlLmNsb3Vk
LnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldIGRvZXMgbm90IGhhdmUKIGFjY2VzcyB0byBh
bGwgb2YgdGhlIHBvbGljaWVzIHRoYXQgUG9saWN5IFNpbXVsYXRvciBuZWVkcyB0byBldmFs
dWF0ZS4KCgwKBQUAAgQBEgMwAhUKDAoFBQACBAISAzAYGQq5AQoCBQESBDYAQQEarAEgVGhl
IGV4dGVudCB0byB3aGljaCBhIHNpbmdsZSBkYXRhIHBvaW50LCBzdWNoIGFzIHRoZSBleGlz
dGVuY2Ugb2YgYSBiaW5kaW5nCiBvciB3aGV0aGVyIGEgYmluZGluZyBpbmNsdWRlcyBhIHNw
ZWNpZmljIHByaW5jaXBhbCwgY29udHJpYnV0ZXMgdG8gYW4gb3ZlcmFsbAogZGV0ZXJtaW5h
dGlvbi4KCgoKAwUBARIDNgUXCjMKBAUBAgASAzgCJhomIERlZmF1bHQgdmFsdWUuIFRoaXMg
dmFsdWUgaXMgdW51c2VkLgoKDAoFBQECAAESAzgCIQoMCgUFAQIAAhIDOCQlCosBCgQFAQIB
EgM8Ag0afiBUaGUgZGF0YSBwb2ludCBoYXMgYSBsaW1pdGVkIGVmZmVjdCBvbiB0aGUgcmVz
dWx0LiBDaGFuZ2luZyB0aGUgZGF0YSBwb2ludAogaXMgdW5saWtlbHkgdG8gYWZmZWN0IHRo
ZSBvdmVyYWxsIGRldGVybWluYXRpb24uCgoMCgUFAQIBARIDPAIICgwKBQUBAgECEgM8CwwK
iAEKBAUBAgISA0ACCxp7IFRoZSBkYXRhIHBvaW50IGhhcyBhIHN0cm9uZyBlZmZlY3Qgb24g
dGhlIHJlc3VsdC4gQ2hhbmdpbmcgdGhlIGRhdGEgcG9pbnQKIGlzIGxpa2VseSB0byBhZmZl
Y3QgdGhlIG92ZXJhbGwgZGV0ZXJtaW5hdGlvbi4KCgwKBQUBAgIBEgNAAgYKDAoFBQECAgIS
A0AJCgpRCgIEABIERABeARpFIEluZm9ybWF0aW9uIGFib3V0IHRoZSBwcmluY2lwYWwsIHJl
c291cmNlLCBhbmQgcGVybWlzc2lvbiB0byBjaGVjay4KCgoKAwQAARIDRAgTCtUCCgQEAAIA
EgNMAkAaxwIgUmVxdWlyZWQuIFRoZSBwcmluY2lwYWwgd2hvc2UgYWNjZXNzIHlvdSB3YW50
IHRvIGNoZWNrLCBpbiB0aGUgZm9ybSBvZgogdGhlIGVtYWlsIGFkZHJlc3MgdGhhdCByZXBy
ZXNlbnRzIHRoYXQgcHJpbmNpcGFsLiBGb3IgZXhhbXBsZSwKIGBhbGljZUBleGFtcGxlLmNv
bWAgb3IKIGBteS1zZXJ2aWNlLWFjY291bnRAbXktcHJvamVjdC5pYW0uZ3NlcnZpY2VhY2Nv
dW50LmNvbWAuCgogVGhlIHByaW5jaXBhbCBtdXN0IGJlIGEgR29vZ2xlIEFjY291bnQgb3Ig
YSBzZXJ2aWNlIGFjY291bnQuIE90aGVyIHR5cGVzIG9mCiBwcmluY2lwYWxzIGFyZSBub3Qg
c3VwcG9ydGVkLgoKDAoFBAACAAUSA0wCCAoMCgUEAAIAARIDTAkSCgwKBQQAAgADEgNMFRYK
DAoFBAACAAgSA0wXPwoPCggEAAIACJwIABIDTBg+CsICCgQEAAIBEgNTAkkatAIgUmVxdWly
ZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgdGhhdCBpZGVudGlmaWVzIHRoZSByZXNvdXJj
ZS4gRm9yIGV4YW1wbGUsCiBgLy9jb21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL215
LXByb2plY3Qvem9uZXMvdXMtY2VudHJhbDEtYS9pbnN0YW5jZXMvbXktaW5zdGFuY2VgLgoK
IEZvciBleGFtcGxlcyBvZiBmdWxsIHJlc291cmNlIG5hbWVzIGZvciBHb29nbGUgQ2xvdWQg
c2VydmljZXMsIHNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL3Ryb3Vi
bGVzaG9vdGVyL2Z1bGwtcmVzb3VyY2UtbmFtZXMuCgoMCgUEAAIBBRIDUwIICgwKBQQAAgEB
EgNTCRsKDAoFBAACAQMSA1MeHwoMCgUEAAIBCBIDUyBICg8KCAQAAgEInAgAEgNTIUcK0AIK
BAQAAgISA10CQRrCAiBSZXF1aXJlZC4gVGhlIElBTSBwZXJtaXNzaW9uIHRvIGNoZWNrIGZv
ciB0aGUgc3BlY2lmaWVkIHByaW5jaXBhbCBhbmQKIHJlc291cmNlLgoKIEZvciBhIGNvbXBs
ZXRlIGxpc3Qgb2YgSUFNIHBlcm1pc3Npb25zLCBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9pYW0vaGVscC9wZXJtaXNzaW9ucy9yZWZlcmVuY2UuCgogRm9yIGEgY29tcGxldGUg
bGlzdCBvZiBwcmVkZWZpbmVkIElBTSByb2xlcyBhbmQgdGhlIHBlcm1pc3Npb25zIGluIGVh
Y2gKIHJvbGUsIHNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtL2hlbHAvcm9sZXMv
cmVmZXJlbmNlLgoKDAoFBAACAgUSA10CCAoMCgUEAAICARIDXQkTCgwKBQQAAgIDEgNdFhcK
DAoFBAACAggSA10YQAoPCggEAAICCJwIABIDXRk/CnAKAgQBEgViAI4BARpjIERldGFpbHMg
YWJvdXQgaG93IGEgc3BlY2lmaWMgSUFNIFtQb2xpY3ldW2dvb2dsZS5pYW0udjEuUG9saWN5
XSBjb250cmlidXRlZAogdG8gdGhlIGFjY2VzcyBjaGVjay4KCgoKAwQBARIDYggXCu8DCgQE
AQIAEgNrAhka4QMgSW5kaWNhdGVzIHdoZXRoZXIgX3RoaXMgcG9saWN5XyBwcm92aWRlcyB0
aGUgc3BlY2lmaWVkIHBlcm1pc3Npb24gdG8gdGhlCiBzcGVjaWZpZWQgcHJpbmNpcGFsIGZv
ciB0aGUgc3BlY2lmaWVkIHJlc291cmNlLgoKIFRoaXMgZmllbGQgZG9lcyBfbm90XyBpbmRp
Y2F0ZSB3aGV0aGVyIHRoZSBwcmluY2lwYWwgYWN0dWFsbHkgaGFzIHRoZQogcGVybWlzc2lv
biBmb3IgdGhlIHJlc291cmNlLiBUaGVyZSBtaWdodCBiZSBhbm90aGVyIHBvbGljeSB0aGF0
IG92ZXJyaWRlcwogdGhpcyBwb2xpY3kuIFRvIGRldGVybWluZSB3aGV0aGVyIHRoZSBwcmlu
Y2lwYWwgYWN0dWFsbHkgaGFzIHRoZQogcGVybWlzc2lvbiwgdXNlIHRoZSBgYWNjZXNzYCBm
aWVsZCBpbiB0aGUKIFtUcm91Ymxlc2hvb3RJYW1Qb2xpY3lSZXNwb25zZV1bZ29vZ2xlLmNs
b3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYzLlRyb3VibGVzaG9vdElhbVBvbGljeVJlc3Bv
bnNlXS4KCgwKBQQBAgAGEgNrAg0KDAoFBAECAAESA2sOFAoMCgUEAQIAAxIDaxcYCsQDCgQE
AQIBEgN2AiAatgMgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSB0aGF0IGlkZW50aWZpZXMgdGhl
IHJlc291cmNlLiBGb3IgZXhhbXBsZSwKIGAvL2NvbXB1dGUuZ29vZ2xlYXBpcy5jb20vcHJv
amVjdHMvbXktcHJvamVjdC96b25lcy91cy1jZW50cmFsMS1hL2luc3RhbmNlcy9teS1pbnN0
YW5jZWAuCgogSWYgdGhlIHVzZXIgd2hvIGNyZWF0ZWQgdGhlCiBbUmVwbGF5XVtnb29nbGUu
Y2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0gZG9lcyBub3QgaGF2ZQogYWNjZXNz
IHRvIHRoZSBwb2xpY3ksIHRoaXMgZmllbGQgaXMgb21pdHRlZC4KCiBGb3IgZXhhbXBsZXMg
b2YgZnVsbCByZXNvdXJjZSBuYW1lcyBmb3IgR29vZ2xlIENsb3VkIHNlcnZpY2VzLCBzZWUK
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vaGVscC90cm91Ymxlc2hvb3Rlci9mdWxs
LXJlc291cmNlLW5hbWVzLgoKDAoFBAECAQUSA3YCCAoMCgUEAQIBARIDdgkbCgwKBQQBAgED
EgN2Hh8KwgEKBAQBAgISA30CIhq0ASBUaGUgSUFNIHBvbGljeSBhdHRhY2hlZCB0byB0aGUg
cmVzb3VyY2UuCgogSWYgdGhlIHVzZXIgd2hvIGNyZWF0ZWQgdGhlCiBbUmVwbGF5XVtnb29n
bGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0gZG9lcyBub3QgaGF2ZQogYWNj
ZXNzIHRvIHRoZSBwb2xpY3ksIHRoaXMgZmllbGQgaXMgZW1wdHkuCgoMCgUEAQICBhIDfQIW
CgwKBQQBAgIBEgN9Fx0KDAoFBAECAgMSA30gIQqhAgoEBAECAxIEhQECNxqSAiBEZXRhaWxz
IGFib3V0IGhvdyBlYWNoIGJpbmRpbmcgaW4gdGhlIHBvbGljeSBhZmZlY3RzIHRoZSBwcmlu
Y2lwYWwncwogYWJpbGl0eSwgb3IgaW5hYmlsaXR5LCB0byB1c2UgdGhlIHBlcm1pc3Npb24g
Zm9yIHRoZSByZXNvdXJjZS4KCiBJZiB0aGUgdXNlciB3aG8gY3JlYXRlZCB0aGUKIFtSZXBs
YXldW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5XSBkb2VzIG5vdCBo
YXZlCiBhY2Nlc3MgdG8gdGhlIHBvbGljeSwgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLgoKDQoF
BAECAwQSBIUBAgoKDQoFBAECAwYSBIUBCx0KDQoFBAECAwESBIUBHjIKDQoFBAECAwMSBIUB
NTYKwwIKBAQBAgQSBI0BAiMatAIgVGhlIHJlbGV2YW5jZSBvZiB0aGlzIHBvbGljeSB0byB0
aGUgb3ZlcmFsbCBkZXRlcm1pbmF0aW9uIGluIHRoZQogW1Ryb3VibGVzaG9vdElhbVBvbGlj
eVJlc3BvbnNlXVtnb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjMuVHJvdWJs
ZXNob290SWFtUG9saWN5UmVzcG9uc2VdLgoKIElmIHRoZSB1c2VyIHdobyBjcmVhdGVkIHRo
ZQogW1JlcGxheV1bZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldIGRv
ZXMgbm90IGhhdmUKIGFjY2VzcyB0byB0aGUgcG9saWN5LCB0aGlzIGZpZWxkIGlzIG9taXR0
ZWQuCgoNCgUEAQIEBhIEjQECFAoNCgUEAQIEARIEjQEVHgoNCgUEAQIEAxIEjQEhIgprCgIE
AhIGkgEAggIBGl0gRGV0YWlscyBhYm91dCBob3cgYSBiaW5kaW5nIGluIGEgcG9saWN5IGFm
ZmVjdHMgYSBwcmluY2lwYWwncyBhYmlsaXR5IHRvIHVzZQogYSBwZXJtaXNzaW9uLgoKCwoD
BAIBEgSSAQgaCksKBAQCAwASBpQBApsBAxo7IERldGFpbHMgYWJvdXQgd2hldGhlciB0aGUg
YmluZGluZyBpbmNsdWRlcyB0aGUgcHJpbmNpcGFsLgoKDQoFBAIDAAESBJQBCh0KRwoGBAID
AAIAEgSWAQQeGjcgSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGJpbmRpbmcgaW5jbHVkZXMgdGhl
IHByaW5jaXBhbC4KCg8KBwQCAwACAAYSBJYBBA4KDwoHBAIDAAIAARIElgEPGQoPCgcEAgMA
AgADEgSWARwdCmgKBgQCAwACARIEmgEEJRpYIFRoZSByZWxldmFuY2Ugb2YgdGhlIHByaW5j
aXBhbCdzIHN0YXR1cyB0byB0aGUgb3ZlcmFsbCBkZXRlcm1pbmF0aW9uIGZvcgogdGhlIGJp
bmRpbmcuCgoPCgcEAgMAAgEGEgSaAQQWCg8KBwQCAwACAQESBJoBFyAKDwoHBAIDAAIBAxIE
mgEjJApACgQEAgQAEgaeAQKsAQMaMCBXaGV0aGVyIGEgcm9sZSBpbmNsdWRlcyBhIHNwZWNp
ZmljIHBlcm1pc3Npb24uCgoNCgUEAgQAARIEngEHFQo2CgYEAgQAAgASBKABBCQaJiBEZWZh
dWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg8KBwQCBAACAAESBKABBB8KDwoH
BAIEAAIAAhIEoAEiIwo5CgYEAgQAAgESBKMBBCEaKSBUaGUgcGVybWlzc2lvbiBpcyBpbmNs
dWRlZCBpbiB0aGUgcm9sZS4KCg8KBwQCBAACAQESBKMBBBwKDwoHBAIEAAIBAhIEowEfIAo9
CgYEAgQAAgISBKYBBCUaLSBUaGUgcGVybWlzc2lvbiBpcyBub3QgaW5jbHVkZWQgaW4gdGhl
IHJvbGUuCgoPCgcEAgQAAgIBEgSmAQQgCg8KBwQCBAACAgISBKYBIyQKgwEKBgQCBAACAxIE
qwEELBpzIFRoZSB1c2VyIHdobyBjcmVhdGVkIHRoZQogW1JlcGxheV1bZ29vZ2xlLmNsb3Vk
LnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldIGlzIG5vdAogYWxsb3dlZCB0byBhY2Nlc3Mg
dGhlIGJpbmRpbmcuCgoPCgcEAgQAAgMBEgSrAQQnCg8KBwQCBAACAwISBKsBKisKPQoEBAIE
ARIGrwECxwEDGi0gV2hldGhlciB0aGUgYmluZGluZyBpbmNsdWRlcyB0aGUgcHJpbmNpcGFs
LgoKDQoFBAIEAQESBK8BBxEKNgoGBAIEAQIAEgSxAQQfGiYgRGVmYXVsdCB2YWx1ZS4gVGhp
cyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEAgQBAgABEgSxAQQaCg8KBwQCBAECAAISBLEBHR4K
2AIKBgQCBAECARIEugEEHBrHAiBUaGUgYmluZGluZyBpbmNsdWRlcyB0aGUgcHJpbmNpcGFs
LiBUaGUgcHJpbmNpcGFsIGNhbiBiZSBpbmNsdWRlZAogZGlyZWN0bHkgb3IgaW5kaXJlY3Rs
eS4gRm9yIGV4YW1wbGU6CgogKiBBIHByaW5jaXBhbCBpcyBpbmNsdWRlZCBkaXJlY3RseSBp
ZiB0aGF0IHByaW5jaXBhbCBpcyBsaXN0ZWQgaW4gdGhlCiAgIGJpbmRpbmcuCiAqIEEgcHJp
bmNpcGFsIGlzIGluY2x1ZGVkIGluZGlyZWN0bHkgaWYgdGhhdCBwcmluY2lwYWwgaXMgaW4g
YSBHb29nbGUKICAgZ3JvdXAgb3IgR29vZ2xlIFdvcmtzcGFjZSBkb21haW4gdGhhdCBpcyBs
aXN0ZWQgaW4gdGhlIGJpbmRpbmcuCgoPCgcEAgQBAgEBEgS6AQQXCg8KBwQCBAECAQISBLoB
GhsKPQoGBAIEAQICEgS9AQQgGi0gVGhlIGJpbmRpbmcgZG9lcyBub3QgaW5jbHVkZSB0aGUg
cHJpbmNpcGFsLgoKDwoHBAIEAQICARIEvQEEGwoPCgcEAgQBAgICEgS9AR4fCoMBCgYEAgQB
AgMSBMIBBCcacyBUaGUgdXNlciB3aG8gY3JlYXRlZCB0aGUKIFtSZXBsYXldW2dvb2dsZS5j
bG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5XSBpcyBub3QKIGFsbG93ZWQgdG8gYWNj
ZXNzIHRoZSBiaW5kaW5nLgoKDwoHBAIEAQIDARIEwgEEIgoPCgcEAgQBAgMCEgTCASUmCnEK
BgQCBAECBBIExgEEJxphIFRoZSBwcmluY2lwYWwgaXMgYW4gdW5zdXBwb3J0ZWQgdHlwZS4g
T25seSBHb29nbGUgQWNjb3VudHMgYW5kIHNlcnZpY2UKIGFjY291bnRzIGFyZSBzdXBwb3J0
ZWQuCgoPCgcEAgQBAgQBEgTGAQQiCg8KBwQCBAECBAISBMYBJSYK/QMKBAQCAgASBNEBAkIa
7gMgUmVxdWlyZWQuIEluZGljYXRlcyB3aGV0aGVyIF90aGlzIGJpbmRpbmdfIHByb3ZpZGVz
IHRoZSBzcGVjaWZpZWQKIHBlcm1pc3Npb24gdG8gdGhlIHNwZWNpZmllZCBwcmluY2lwYWwg
Zm9yIHRoZSBzcGVjaWZpZWQgcmVzb3VyY2UuCgogVGhpcyBmaWVsZCBkb2VzIF9ub3RfIGlu
ZGljYXRlIHdoZXRoZXIgdGhlIHByaW5jaXBhbCBhY3R1YWxseSBoYXMgdGhlCiBwZXJtaXNz
aW9uIGZvciB0aGUgcmVzb3VyY2UuIFRoZXJlIG1pZ2h0IGJlIGFub3RoZXIgYmluZGluZyB0
aGF0IG92ZXJyaWRlcwogdGhpcyBiaW5kaW5nLiBUbyBkZXRlcm1pbmUgd2hldGhlciB0aGUg
cHJpbmNpcGFsIGFjdHVhbGx5IGhhcyB0aGUKIHBlcm1pc3Npb24sIHVzZSB0aGUgYGFjY2Vz
c2AgZmllbGQgaW4gdGhlCiBbVHJvdWJsZXNob290SWFtUG9saWN5UmVzcG9uc2VdW2dvb2ds
ZS5jbG91ZC5wb2xpY3l0cm91Ymxlc2hvb3Rlci52My5Ucm91Ymxlc2hvb3RJYW1Qb2xpY3lS
ZXNwb25zZV0uCgoNCgUEAgIABhIE0QECDQoNCgUEAgIAARIE0QEOFAoNCgUEAgIAAxIE0QEX
GAoNCgUEAgIACBIE0QEZQQoQCggEAgIACJwIABIE0QEaQArvAQoEBAICARIE2AECEhrgASBU
aGUgcm9sZSB0aGF0IHRoaXMgYmluZGluZyBncmFudHMuIEZvciBleGFtcGxlLAogYHJvbGVz
L2NvbXB1dGUuc2VydmljZUFnZW50YC4KCiBGb3IgYSBjb21wbGV0ZSBsaXN0IG9mIHByZWRl
ZmluZWQgSUFNIHJvbGVzLCBhcyB3ZWxsIGFzIHRoZSBwZXJtaXNzaW9ucyBpbgogZWFjaCBy
b2xlLCBzZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL3JvbGVzL3JlZmVy
ZW5jZS4KCg0KBQQCAgEFEgTYAQIICg0KBQQCAgEBEgTYAQkNCg0KBQQCAgEDEgTYARARCmYK
BAQCAgISBNwBAiUaWCBJbmRpY2F0ZXMgd2hldGhlciB0aGUgcm9sZSBncmFudGVkIGJ5IHRo
aXMgYmluZGluZyBjb250YWlucyB0aGUgc3BlY2lmaWVkCiBwZXJtaXNzaW9uLgoKDQoFBAIC
AgYSBNwBAhAKDQoFBAICAgESBNwBESAKDQoFBAICAgMSBNwBIyQKjwEKBAQCAgMSBOABAjMa
gAEgVGhlIHJlbGV2YW5jZSBvZiB0aGUgcGVybWlzc2lvbidzIGV4aXN0ZW5jZSwgb3Igbm9u
ZXhpc3RlbmNlLCBpbiB0aGUgcm9sZQogdG8gdGhlIG92ZXJhbGwgZGV0ZXJtaW5hdGlvbiBm
b3IgdGhlIGVudGlyZSBwb2xpY3kuCgoNCgUEAgIDBhIE4AECFAoNCgUEAgIDARIE4AEVLgoN
CgUEAgIDAxIE4AExMgqBBwoEBAICBBIE9gECMxryBiBJbmRpY2F0ZXMgd2hldGhlciBlYWNo
IHByaW5jaXBhbCBpbiB0aGUgYmluZGluZyBpbmNsdWRlcyB0aGUgcHJpbmNpcGFsCiBzcGVj
aWZpZWQgaW4gdGhlIHJlcXVlc3QsIGVpdGhlciBkaXJlY3RseSBvciBpbmRpcmVjdGx5LiBF
YWNoIGtleQogaWRlbnRpZmllcyBhIHByaW5jaXBhbCBpbiB0aGUgYmluZGluZywgYW5kIGVh
Y2ggdmFsdWUgaW5kaWNhdGVzIHdoZXRoZXIgdGhlCiBwcmluY2lwYWwgaW4gdGhlIGJpbmRp
bmcgaW5jbHVkZXMgdGhlIHByaW5jaXBhbCBpbiB0aGUgcmVxdWVzdC4KCiBGb3IgZXhhbXBs
ZSwgc3VwcG9zZSB0aGF0IGEgYmluZGluZyBpbmNsdWRlcyB0aGUgZm9sbG93aW5nIHByaW5j
aXBhbHM6CgogKiBgdXNlcjphbGljZUBleGFtcGxlLmNvbWAKICogYGdyb3VwOnByb2R1Y3Qt
ZW5nQGV4YW1wbGUuY29tYAoKIFRoZSBwcmluY2lwYWwgaW4gdGhlIHJlcGxheWVkIGFjY2Vz
cyB0dXBsZSBpcyBgdXNlcjpib2JAZXhhbXBsZS5jb21gLiBUaGlzCiB1c2VyIGlzIGEgcHJp
bmNpcGFsIG9mIHRoZSBncm91cCBgZ3JvdXA6cHJvZHVjdC1lbmdAZXhhbXBsZS5jb21gLgoK
IEZvciB0aGUgZmlyc3QgcHJpbmNpcGFsIGluIHRoZSBiaW5kaW5nLCB0aGUga2V5IGlzCiBg
dXNlcjphbGljZUBleGFtcGxlLmNvbWAsIGFuZCB0aGUgYG1lbWJlcnNoaXBgIGZpZWxkIGlu
IHRoZSB2YWx1ZSBpcyBzZXQgdG8KIGBNRU1CRVJTSElQX05PVF9JTkNMVURFRGAuCgogRm9y
IHRoZSBzZWNvbmQgcHJpbmNpcGFsIGluIHRoZSBiaW5kaW5nLCB0aGUga2V5IGlzCiBgZ3Jv
dXA6cHJvZHVjdC1lbmdAZXhhbXBsZS5jb21gLCBhbmQgdGhlIGBtZW1iZXJzaGlwYCBmaWVs
ZCBpbiB0aGUgdmFsdWUgaXMKIHNldCB0byBgTUVNQkVSU0hJUF9JTkNMVURFRGAuCgoNCgUE
AgIEBhIE9gECIgoNCgUEAgIEARIE9gEjLgoNCgUEAgIEAxIE9gExMgpiCgQEAgIFEgT6AQIj
GlQgVGhlIHJlbGV2YW5jZSBvZiB0aGlzIGJpbmRpbmcgdG8gdGhlIG92ZXJhbGwgZGV0ZXJt
aW5hdGlvbiBmb3IgdGhlIGVudGlyZQogcG9saWN5LgoKDQoFBAICBQYSBPoBAhQKDQoFBAIC
BQESBPoBFR4KDQoFBAICBQMSBPoBISIK4AEKBAQCAgYSBIECAiEa0QEgQSBjb25kaXRpb24g
ZXhwcmVzc2lvbiB0aGF0IHByZXZlbnRzIHRoaXMgYmluZGluZyBmcm9tIGdyYW50aW5nIGFj
Y2VzcwogdW5sZXNzIHRoZSBleHByZXNzaW9uIGV2YWx1YXRlcyB0byBgdHJ1ZWAuCgogVG8g
bGVhcm4gYWJvdXQgSUFNIENvbmRpdGlvbnMsIHNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2lhbS9kb2NzL2NvbmRpdGlvbnMtb3ZlcnZpZXcuCgoNCgUEAgIGBhIEgQICEgoNCgUE
AgIGARIEgQITHAoNCgUEAgIGAxIEgQIfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Policysimulator::V1::Explanations::AccessTuple ===
    # Fields for AccessTuple
    # Field: principal Type: 9 ()
    # Field: full_resource_name Type: 9 ()
    # Field: permission Type: 9 ()

# === Message: Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy ===
    # Fields for ExplainedPolicy
    # Field: access Type: 14 (.google.cloud.policysimulator.v1.AccessState)
    # Field: full_resource_name Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: binding_explanations Type: 11 (.google.cloud.policysimulator.v1.BindingExplanation)
    # Field: relevance Type: 14 (.google.cloud.policysimulator.v1.HeuristicRelevance)

# === Message: Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation ===
    # Fields for BindingExplanation
    # Field: access Type: 14 (.google.cloud.policysimulator.v1.AccessState)
    # Field: role Type: 9 ()
    # Field: role_permission Type: 14 (.google.cloud.policysimulator.v1.BindingExplanation.RolePermission)
    # Field: role_permission_relevance Type: 14 (.google.cloud.policysimulator.v1.HeuristicRelevance)
    # Field: memberships Type: 11 (.google.cloud.policysimulator.v1.BindingExplanation.MembershipsEntry)
    # Field: relevance Type: 14 (.google.cloud.policysimulator.v1.HeuristicRelevance)
    # Field: condition Type: 11 (.google.type.Expr)

# Enum: BindingExplanation::RolePermission
our $BindingExplanation_ROLE_PERMISSION_UNSPECIFIED = 0;
our $BindingExplanation_ROLE_PERMISSION_INCLUDED = 1;
our $BindingExplanation_ROLE_PERMISSION_NOT_INCLUDED = 2;
our $BindingExplanation_ROLE_PERMISSION_UNKNOWN_INFO_DENIED = 3;

# Enum: BindingExplanation::Membership
our $BindingExplanation_MEMBERSHIP_UNSPECIFIED = 0;
our $BindingExplanation_MEMBERSHIP_INCLUDED = 1;
our $BindingExplanation_MEMBERSHIP_NOT_INCLUDED = 2;
our $BindingExplanation_MEMBERSHIP_UNKNOWN_INFO_DENIED = 3;
our $BindingExplanation_MEMBERSHIP_UNKNOWN_UNSUPPORTED = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Policysimulator::V1::Explanations - Compiled Protocol Buffers messages for google/cloud/policysimulator/v1/explanations.proto

=head1 SYNOPSIS

    use Google::Cloud::Policysimulator::V1::Explanations;

    my $msg = Google::Cloud::Policysimulator::V1::Explanations::AccessTuple->new({
        principal => $principal,
        full_resource_name => $full_resource_name,
        permission => $permission,
    });

    # Read or update a field
    my $val = $msg->principal();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Policysimulator::V1::Explanations::AccessTuple->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/policysimulator/v1/explanations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Policysimulator::V1::Explanations::AccessTuple

Information about the principal, resource, and permission to check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal() >> / C<< $msg->principal($value) >>

Type: C<String>

Required. The principal whose access you want to check, in the form of
the email address that represents that principal. For example,
`alice@example.com` or
`my-service-account@my-project.iam.gserviceaccount.com`.

The principal must be a Google Account or a service account. Other types of
principals are not supported.

=item * C<< $msg->full_resource_name() >> / C<< $msg->full_resource_name($value) >>

Type: C<String>

Required. The full resource name that identifies the resource. For example,
`//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`.

For examples of full resource names for Google Cloud services, see
https://cloud.google.com/iam/help/troubleshooter/full-resource-names.

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<String>

Required. The IAM permission to check for the specified principal and
resource.

For a complete list of IAM permissions, see
https://cloud.google.com/iam/help/permissions/reference.

For a complete list of predefined IAM roles and the permissions in each
role, see https://cloud.google.com/iam/help/roles/reference.

=back

=head2 Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy

Details about how a specific IAM [Policy][google.iam.v1.Policy] contributed
to the access check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::AccessState>)

Indicates whether _this policy_ provides the specified permission to the
specified principal for the specified resource.

This field does _not_ indicate whether the principal actually has the
permission for the resource. There might be another policy that overrides
this policy. To determine whether the principal actually has the
permission, use the `access` field in the
[TroubleshootIamPolicyResponse][google.cloud.policytroubleshooter.v3.TroubleshootIamPolicyResponse].

=item * C<< $msg->full_resource_name() >> / C<< $msg->full_resource_name($value) >>

Type: C<String>

The full resource name that identifies the resource. For example,
`//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`.

If the user who created the
[Replay][google.cloud.policysimulator.v1.Replay] does not have
access to the policy, this field is omitted.

For examples of full resource names for Google Cloud services, see
https://cloud.google.com/iam/help/troubleshooter/full-resource-names.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

The IAM policy attached to the resource.

If the user who created the
[Replay][google.cloud.policysimulator.v1.Replay] does not have
access to the policy, this field is empty.

=item * C<< $msg->binding_explanations() >> / C<< $msg->binding_explanations($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation>)

Details about how each binding in the policy affects the principal's
ability, or inability, to use the permission for the resource.

If the user who created the
[Replay][google.cloud.policysimulator.v1.Replay] does not have
access to the policy, this field is omitted.

=item * C<< $msg->relevance() >> / C<< $msg->relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::HeuristicRelevance>)

The relevance of this policy to the overall determination in the
[TroubleshootIamPolicyResponse][google.cloud.policytroubleshooter.v3.TroubleshootIamPolicyResponse].

If the user who created the
[Replay][google.cloud.policysimulator.v1.Replay] does not have
access to the policy, this field is omitted.

=back

=head2 Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation

Details about how a binding in a policy affects a principal's ability to use
a permission.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::AccessState>)

Required. Indicates whether _this binding_ provides the specified
permission to the specified principal for the specified resource.

This field does _not_ indicate whether the principal actually has the
permission for the resource. There might be another binding that overrides
this binding. To determine whether the principal actually has the
permission, use the `access` field in the
[TroubleshootIamPolicyResponse][google.cloud.policytroubleshooter.v3.TroubleshootIamPolicyResponse].

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

The role that this binding grants. For example,
`roles/compute.serviceAgent`.

For a complete list of predefined IAM roles, as well as the permissions in
each role, see https://cloud.google.com/iam/help/roles/reference.

=item * C<< $msg->role_permission() >> / C<< $msg->role_permission($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::BindingExplanation::RolePermission>)

Indicates whether the role granted by this binding contains the specified
permission.

=item * C<< $msg->role_permission_relevance() >> / C<< $msg->role_permission_relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::HeuristicRelevance>)

The relevance of the permission's existence, or nonexistence, in the role
to the overall determination for the entire policy.

=item * C<< $msg->memberships() >> / C<< $msg->memberships($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::MembershipsEntry>)

Indicates whether each principal in the binding includes the principal
specified in the request, either directly or indirectly. Each key
identifies a principal in the binding, and each value indicates whether the
principal in the binding includes the principal in the request.

For example, suppose that a binding includes the following principals:

* `user:alice@example.com`
* `group:product-eng@example.com`

The principal in the replayed access tuple is `user:bob@example.com`. This
user is a principal of the group `group:product-eng@example.com`.

For the first principal in the binding, the key is
`user:alice@example.com`, and the `membership` field in the value is set to
`MEMBERSHIP_NOT_INCLUDED`.

For the second principal in the binding, the key is
`group:product-eng@example.com`, and the `membership` field in the value is
set to `MEMBERSHIP_INCLUDED`.

=item * C<< $msg->relevance() >> / C<< $msg->relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::HeuristicRelevance>)

The relevance of this binding to the overall determination for the entire
policy.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

A condition expression that prevents this binding from granting access
unless the expression evaluates to `true`.

To learn about IAM Conditions, see
https://cloud.google.com/iam/docs/conditions-overview.

=back

=head3 Enum: BindingExplanation::RolePermission

=over 4

=item * C<ROLE_PERMISSION_UNSPECIFIED> => C<0>

=item * C<ROLE_PERMISSION_INCLUDED> => C<1>

=item * C<ROLE_PERMISSION_NOT_INCLUDED> => C<2>

=item * C<ROLE_PERMISSION_UNKNOWN_INFO_DENIED> => C<3>

=back

=head3 Enum: BindingExplanation::Membership

=over 4

=item * C<MEMBERSHIP_UNSPECIFIED> => C<0>

=item * C<MEMBERSHIP_INCLUDED> => C<1>

=item * C<MEMBERSHIP_NOT_INCLUDED> => C<2>

=item * C<MEMBERSHIP_UNKNOWN_INFO_DENIED> => C<3>

=item * C<MEMBERSHIP_UNKNOWN_UNSUPPORTED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Policysimulator::V1::Explanations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
