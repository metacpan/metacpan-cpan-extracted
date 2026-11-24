package Google::Cloud::Policytroubleshooter::V1::Explanations;

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
Cjdnb29nbGUvY2xvdWQvcG9saWN5dHJvdWJsZXNob290ZXIvdjEvZXhwbGFuYXRpb25zLnBy
b3RvEiRnb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3RvGhZnb29n
bGUvdHlwZS9leHByLnByb3RvIogBCgtBY2Nlc3NUdXBsZRIhCglwcmluY2lwYWwYASABKAlC
A+BBAlIJcHJpbmNpcGFsEjEKEmZ1bGxfcmVzb3VyY2VfbmFtZRgCIAEoCUID4EECUhBmdWxs
UmVzb3VyY2VOYW1lEiMKCnBlcm1pc3Npb24YAyABKAlCA+BBAlIKcGVybWlzc2lvbiL+AgoP
RXhwbGFpbmVkUG9saWN5EkkKBmFjY2VzcxgBIAEoDjIxLmdvb2dsZS5jbG91ZC5wb2xpY3l0
cm91Ymxlc2hvb3Rlci52MS5BY2Nlc3NTdGF0ZVIGYWNjZXNzEiwKEmZ1bGxfcmVzb3VyY2Vf
bmFtZRgCIAEoCVIQZnVsbFJlc291cmNlTmFtZRItCgZwb2xpY3kYAyABKAsyFS5nb29nbGUu
aWFtLnYxLlBvbGljeVIGcG9saWN5EmsKFGJpbmRpbmdfZXhwbGFuYXRpb25zGAQgAygLMjgu
Z29vZ2xlLmNsb3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxLkJpbmRpbmdFeHBsYW5hdGlv
blITYmluZGluZ0V4cGxhbmF0aW9ucxJWCglyZWxldmFuY2UYBSABKA4yOC5nb29nbGUuY2xv
dWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuSGV1cmlzdGljUmVsZXZhbmNlUglyZWxldmFu
Y2UigAoKEkJpbmRpbmdFeHBsYW5hdGlvbhJOCgZhY2Nlc3MYASABKA4yMS5nb29nbGUuY2xv
dWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuQWNjZXNzU3RhdGVCA+BBAlIGYWNjZXNzEhIK
BHJvbGUYAiABKAlSBHJvbGUScAoPcm9sZV9wZXJtaXNzaW9uGAMgASgOMkcuZ29vZ2xlLmNs
b3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxLkJpbmRpbmdFeHBsYW5hdGlvbi5Sb2xlUGVy
bWlzc2lvblIOcm9sZVBlcm1pc3Npb24SdAoZcm9sZV9wZXJtaXNzaW9uX3JlbGV2YW5jZRgE
IAEoDjI4Lmdvb2dsZS5jbG91ZC5wb2xpY3l0cm91Ymxlc2hvb3Rlci52MS5IZXVyaXN0aWNS
ZWxldmFuY2VSF3JvbGVQZXJtaXNzaW9uUmVsZXZhbmNlEmsKC21lbWJlcnNoaXBzGAUgAygL
MkkuZ29vZ2xlLmNsb3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxLkJpbmRpbmdFeHBsYW5h
dGlvbi5NZW1iZXJzaGlwc0VudHJ5UgttZW1iZXJzaGlwcxJWCglyZWxldmFuY2UYBiABKA4y
OC5nb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuSGV1cmlzdGljUmVsZXZh
bmNlUglyZWxldmFuY2USLwoJY29uZGl0aW9uGAcgASgLMhEuZ29vZ2xlLnR5cGUuRXhwclIJ
Y29uZGl0aW9uGtIBChNBbm5vdGF0ZWRNZW1iZXJzaGlwEmMKCm1lbWJlcnNoaXAYASABKA4y
Qy5nb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuQmluZGluZ0V4cGxhbmF0
aW9uLk1lbWJlcnNoaXBSCm1lbWJlcnNoaXASVgoJcmVsZXZhbmNlGAIgASgOMjguZ29vZ2xl
LmNsb3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxLkhldXJpc3RpY1JlbGV2YW5jZVIJcmVs
ZXZhbmNlGowBChBNZW1iZXJzaGlwc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EmIKBXZhbHVl
GAIgASgLMkwuZ29vZ2xlLmNsb3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxLkJpbmRpbmdF
eHBsYW5hdGlvbi5Bbm5vdGF0ZWRNZW1iZXJzaGlwUgV2YWx1ZToCOAEimgEKDlJvbGVQZXJt
aXNzaW9uEh8KG1JPTEVfUEVSTUlTU0lPTl9VTlNQRUNJRklFRBAAEhwKGFJPTEVfUEVSTUlT
U0lPTl9JTkNMVURFRBABEiAKHFJPTEVfUEVSTUlTU0lPTl9OT1RfSU5DTFVERUQQAhInCiNS
T0xFX1BFUk1JU1NJT05fVU5LTk9XTl9JTkZPX0RFTklFRBADIqYBCgpNZW1iZXJzaGlwEhoK
Fk1FTUJFUlNISVBfVU5TUEVDSUZJRUQQABIXChNNRU1CRVJTSElQX0lOQ0xVREVEEAESGwoX
TUVNQkVSU0hJUF9OT1RfSU5DTFVERUQQAhIiCh5NRU1CRVJTSElQX1VOS05PV05fSU5GT19E
RU5JRUQQAxIiCh5NRU1CRVJTSElQX1VOS05PV05fVU5TVVBQT1JURUQQBCp7CgtBY2Nlc3NT
dGF0ZRIcChhBQ0NFU1NfU1RBVEVfVU5TUEVDSUZJRUQQABILCgdHUkFOVEVEEAESDwoLTk9U
X0dSQU5URUQQAhIXChNVTktOT1dOX0NPTkRJVElPTkFMEAMSFwoTVU5LTk9XTl9JTkZPX0RF
TklFRBAEKk8KEkhldXJpc3RpY1JlbGV2YW5jZRIjCh9IRVVSSVNUSUNfUkVMRVZBTkNFX1VO
U1BFQ0lGSUVEEAASCgoGTk9STUFMEAESCAoESElHSBACQtYBWlxjbG91ZC5nb29nbGUuY29t
L2dvL3BvbGljeXRyb3VibGVzaG9vdGVyL2FwaXYxL3BvbGljeXRyb3VibGVzaG9vdGVycGI7
cG9saWN5dHJvdWJsZXNob290ZXJwYqoCJEdvb2dsZS5DbG91ZC5Qb2xpY3lUcm91Ymxlc2hv
b3Rlci5WMcoCJEdvb2dsZVxDbG91ZFxQb2xpY3lUcm91Ymxlc2hvb3RlclxWMeoCJ0dvb2ds
ZTo6Q2xvdWQ6OlBvbGljeVRyb3VibGVzaG9vdGVyOjpWMUrlSgoHEgUOAPYBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMB
EgMTACQKCQoCAwISAxQAIAoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAHMKCQoCCAsS
AxcAcwoICgEIEgMYAEEKCQoCCCkSAxgAQQoICgEIEgMZAEAKCQoCCC0SAxkAQApRCgIEABIE
HAA2ARpFIEluZm9ybWF0aW9uIGFib3V0IHRoZSBwcmluY2lwYWwsIHJlc291cmNlLCBhbmQg
cGVybWlzc2lvbiB0byBjaGVjay4KCgoKAwQAARIDHAgTCtUCCgQEAAIAEgMkAkAaxwIgUmVx
dWlyZWQuIFRoZSBwcmluY2lwYWwgd2hvc2UgYWNjZXNzIHlvdSB3YW50IHRvIGNoZWNrLCBp
biB0aGUgZm9ybSBvZgogdGhlIGVtYWlsIGFkZHJlc3MgdGhhdCByZXByZXNlbnRzIHRoYXQg
cHJpbmNpcGFsLiBGb3IgZXhhbXBsZSwKIGBhbGljZUBleGFtcGxlLmNvbWAgb3IKIGBteS1z
ZXJ2aWNlLWFjY291bnRAbXktcHJvamVjdC5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgog
VGhlIHByaW5jaXBhbCBtdXN0IGJlIGEgR29vZ2xlIEFjY291bnQgb3IgYSBzZXJ2aWNlIGFj
Y291bnQuIE90aGVyIHR5cGVzIG9mCiBwcmluY2lwYWxzIGFyZSBub3Qgc3VwcG9ydGVkLgoK
DAoFBAACAAUSAyQCCAoMCgUEAAIAARIDJAkSCgwKBQQAAgADEgMkFRYKDAoFBAACAAgSAyQX
PwoPCggEAAIACJwIABIDJBg+CsICCgQEAAIBEgMrAkkatAIgUmVxdWlyZWQuIFRoZSBmdWxs
IHJlc291cmNlIG5hbWUgdGhhdCBpZGVudGlmaWVzIHRoZSByZXNvdXJjZS4gRm9yIGV4YW1w
bGUsCiBgLy9jb21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL215LXByb2plY3Qvem9u
ZXMvdXMtY2VudHJhbDEtYS9pbnN0YW5jZXMvbXktaW5zdGFuY2VgLgoKIEZvciBleGFtcGxl
cyBvZiBmdWxsIHJlc291cmNlIG5hbWVzIGZvciBHb29nbGUgQ2xvdWQgc2VydmljZXMsIHNl
ZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL3Ryb3VibGVzaG9vdGVyL2Z1
bGwtcmVzb3VyY2UtbmFtZXMuCgoMCgUEAAIBBRIDKwIICgwKBQQAAgEBEgMrCRsKDAoFBAAC
AQMSAyseHwoMCgUEAAIBCBIDKyBICg8KCAQAAgEInAgAEgMrIUcK0AIKBAQAAgISAzUCQRrC
AiBSZXF1aXJlZC4gVGhlIElBTSBwZXJtaXNzaW9uIHRvIGNoZWNrIGZvciB0aGUgc3BlY2lm
aWVkIHByaW5jaXBhbCBhbmQKIHJlc291cmNlLgoKIEZvciBhIGNvbXBsZXRlIGxpc3Qgb2Yg
SUFNIHBlcm1pc3Npb25zLCBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vaGVs
cC9wZXJtaXNzaW9ucy9yZWZlcmVuY2UuCgogRm9yIGEgY29tcGxldGUgbGlzdCBvZiBwcmVk
ZWZpbmVkIElBTSByb2xlcyBhbmQgdGhlIHBlcm1pc3Npb25zIGluIGVhY2gKIHJvbGUsIHNl
ZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtL2hlbHAvcm9sZXMvcmVmZXJlbmNlLgoK
DAoFBAACAgUSAzUCCAoMCgUEAAICARIDNQkTCgwKBQQAAgIDEgM1FhcKDAoFBAACAggSAzUY
QAoPCggEAAICCJwIABIDNRk/Cm8KAgQBEgQ6AGIBGmMgRGV0YWlscyBhYm91dCBob3cgYSBz
cGVjaWZpYyBJQU0gW1BvbGljeV1bZ29vZ2xlLmlhbS52MS5Qb2xpY3ldIGNvbnRyaWJ1dGVk
CiB0byB0aGUgYWNjZXNzIGNoZWNrLgoKCgoDBAEBEgM6CBcK1QMKBAQBAgASA0MCGRrHAyBJ
bmRpY2F0ZXMgd2hldGhlciBfdGhpcyBwb2xpY3lfIHByb3ZpZGVzIHRoZSBzcGVjaWZpZWQg
cGVybWlzc2lvbiB0byB0aGUKIHNwZWNpZmllZCBwcmluY2lwYWwgZm9yIHRoZSBzcGVjaWZp
ZWQgcmVzb3VyY2UuCgogVGhpcyBmaWVsZCBkb2VzIF9ub3RfIGluZGljYXRlIHdoZXRoZXIg
dGhlIHByaW5jaXBhbCBhY3R1YWxseSBoYXMgdGhlCiBwZXJtaXNzaW9uIGZvciB0aGUgcmVz
b3VyY2UuIFRoZXJlIG1pZ2h0IGJlIGFub3RoZXIgcG9saWN5IHRoYXQgb3ZlcnJpZGVzCiB0
aGlzIHBvbGljeS4gVG8gZGV0ZXJtaW5lIHdoZXRoZXIgdGhlIHByaW5jaXBhbCBhY3R1YWxs
eSBoYXMgdGhlCiBwZXJtaXNzaW9uLCB1c2UgdGhlIGBhY2Nlc3NgIGZpZWxkIGluIHRoZQog
W1Ryb3VibGVzaG9vdElhbVBvbGljeVJlc3BvbnNlXVtJYW1DaGVja2VyLlRyb3VibGVzaG9v
dElhbVBvbGljeVJlc3BvbnNlXS4KCgwKBQQBAgAGEgNDAg0KDAoFBAECAAESA0MOFAoMCgUE
AQIAAxIDQxcYCpMDCgQEAQIBEgNNAiAahQMgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSB0aGF0
IGlkZW50aWZpZXMgdGhlIHJlc291cmNlLiBGb3IgZXhhbXBsZSwKIGAvL2NvbXB1dGUuZ29v
Z2xlYXBpcy5jb20vcHJvamVjdHMvbXktcHJvamVjdC96b25lcy91cy1jZW50cmFsMS1hL2lu
c3RhbmNlcy9teS1pbnN0YW5jZWAuCgogSWYgdGhlIHNlbmRlciBvZiB0aGUgcmVxdWVzdCBk
b2VzIG5vdCBoYXZlIGFjY2VzcyB0byB0aGUgcG9saWN5LCB0aGlzIGZpZWxkCiBpcyBvbWl0
dGVkLgoKIEZvciBleGFtcGxlcyBvZiBmdWxsIHJlc291cmNlIG5hbWVzIGZvciBHb29nbGUg
Q2xvdWQgc2VydmljZXMsIHNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxw
L3Ryb3VibGVzaG9vdGVyL2Z1bGwtcmVzb3VyY2UtbmFtZXMuCgoMCgUEAQIBBRIDTQIICgwK
BQQBAgEBEgNNCRsKDAoFBAECAQMSA00eHwqRAQoEBAECAhIDUwIiGoMBIFRoZSBJQU0gcG9s
aWN5IGF0dGFjaGVkIHRvIHRoZSByZXNvdXJjZS4KCiBJZiB0aGUgc2VuZGVyIG9mIHRoZSBy
ZXF1ZXN0IGRvZXMgbm90IGhhdmUgYWNjZXNzIHRvIHRoZSBwb2xpY3ksIHRoaXMgZmllbGQK
IGlzIGVtcHR5LgoKDAoFBAECAgYSA1MCFgoMCgUEAQICARIDUxcdCgwKBQQBAgIDEgNTICEK
7wEKBAQBAgMSA1oCNxrhASBEZXRhaWxzIGFib3V0IGhvdyBlYWNoIGJpbmRpbmcgaW4gdGhl
IHBvbGljeSBhZmZlY3RzIHRoZSBwcmluY2lwYWwncwogYWJpbGl0eSwgb3IgaW5hYmlsaXR5
LCB0byB1c2UgdGhlIHBlcm1pc3Npb24gZm9yIHRoZSByZXNvdXJjZS4KCiBJZiB0aGUgc2Vu
ZGVyIG9mIHRoZSByZXF1ZXN0IGRvZXMgbm90IGhhdmUgYWNjZXNzIHRvIHRoZSBwb2xpY3ks
IHRoaXMgZmllbGQKIGlzIG9taXR0ZWQuCgoMCgUEAQIDBBIDWgIKCgwKBQQBAgMGEgNaCx0K
DAoFBAECAwESA1oeMgoMCgUEAQIDAxIDWjU2CvcBCgQEAQIEEgNhAiMa6QEgVGhlIHJlbGV2
YW5jZSBvZiB0aGlzIHBvbGljeSB0byB0aGUgb3ZlcmFsbCBkZXRlcm1pbmF0aW9uIGluIHRo
ZQogW1Ryb3VibGVzaG9vdElhbVBvbGljeVJlc3BvbnNlXVtJYW1DaGVja2VyLlRyb3VibGVz
aG9vdElhbVBvbGljeVJlc3BvbnNlXS4KCiBJZiB0aGUgc2VuZGVyIG9mIHRoZSByZXF1ZXN0
IGRvZXMgbm90IGhhdmUgYWNjZXNzIHRvIHRoZSBwb2xpY3ksIHRoaXMgZmllbGQKIGlzIG9t
aXR0ZWQuCgoMCgUEAQIEBhIDYQIUCgwKBQQBAgQBEgNhFR4KDAoFBAECBAMSA2EhIgpqCgIE
AhIFZgDSAQEaXSBEZXRhaWxzIGFib3V0IGhvdyBhIGJpbmRpbmcgaW4gYSBwb2xpY3kgYWZm
ZWN0cyBhIHByaW5jaXBhbCdzIGFiaWxpdHkgdG8gdXNlCiBhIHBlcm1pc3Npb24uCgoKCgME
AgESA2YIGgo+CgQEAgQAEgRoAnQDGjAgV2hldGhlciBhIHJvbGUgaW5jbHVkZXMgYSBzcGVj
aWZpYyBwZXJtaXNzaW9uLgoKDAoFBAIEAAESA2gHFQo1CgYEAgQAAgASA2oEJBomIERlZmF1
bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAIEAAIAARIDagQfCg4KBwQC
BAACAAISA2oiIwo4CgYEAgQAAgESA20EIRopIFRoZSBwZXJtaXNzaW9uIGlzIGluY2x1ZGVk
IGluIHRoZSByb2xlLgoKDgoHBAIEAAIBARIDbQQcCg4KBwQCBAACAQISA20fIAo8CgYEAgQA
AgISA3AEJRotIFRoZSBwZXJtaXNzaW9uIGlzIG5vdCBpbmNsdWRlZCBpbiB0aGUgcm9sZS4K
Cg4KBwQCBAACAgESA3AEIAoOCgcEAgQAAgICEgNwIyQKUAoGBAIEAAIDEgNzBCwaQSBUaGUg
c2VuZGVyIG9mIHRoZSByZXF1ZXN0IGlzIG5vdCBhbGxvd2VkIHRvIGFjY2VzcyB0aGUgYmlu
ZGluZy4KCg4KBwQCBAACAwESA3MEJwoOCgcEAgQAAgMCEgNzKisKPAoEBAIEARIFdwKNAQMa
LSBXaGV0aGVyIHRoZSBiaW5kaW5nIGluY2x1ZGVzIHRoZSBwcmluY2lwYWwuCgoMCgUEAgQB
ARIDdwcRCjUKBgQCBAECABIDeQQfGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1
bnVzZWQuCgoOCgcEAgQBAgABEgN5BBoKDgoHBAIEAQIAAhIDeR0eCtgCCgYEAgQBAgESBIIB
BBwaxwIgVGhlIGJpbmRpbmcgaW5jbHVkZXMgdGhlIHByaW5jaXBhbC4gVGhlIHByaW5jaXBh
bCBjYW4gYmUgaW5jbHVkZWQKIGRpcmVjdGx5IG9yIGluZGlyZWN0bHkuIEZvciBleGFtcGxl
OgoKICogQSBwcmluY2lwYWwgaXMgaW5jbHVkZWQgZGlyZWN0bHkgaWYgdGhhdCBwcmluY2lw
YWwgaXMgbGlzdGVkIGluIHRoZQogICBiaW5kaW5nLgogKiBBIHByaW5jaXBhbCBpcyBpbmNs
dWRlZCBpbmRpcmVjdGx5IGlmIHRoYXQgcHJpbmNpcGFsIGlzIGluIGEgR29vZ2xlCiAgIGdy
b3VwIG9yIEdvb2dsZSBXb3Jrc3BhY2UgZG9tYWluIHRoYXQgaXMgbGlzdGVkIGluIHRoZSBi
aW5kaW5nLgoKDwoHBAIEAQIBARIEggEEFwoPCgcEAgQBAgECEgSCARobCj0KBgQCBAECAhIE
hQEEIBotIFRoZSBiaW5kaW5nIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByaW5jaXBhbC4KCg8K
BwQCBAECAgESBIUBBBsKDwoHBAIEAQICAhIEhQEeHwpRCgYEAgQBAgMSBIgBBCcaQSBUaGUg
c2VuZGVyIG9mIHRoZSByZXF1ZXN0IGlzIG5vdCBhbGxvd2VkIHRvIGFjY2VzcyB0aGUgYmlu
ZGluZy4KCg8KBwQCBAECAwESBIgBBCIKDwoHBAIEAQIDAhIEiAElJgpxCgYEAgQBAgQSBIwB
BCcaYSBUaGUgcHJpbmNpcGFsIGlzIGFuIHVuc3VwcG9ydGVkIHR5cGUuIE9ubHkgR29vZ2xl
IEFjY291bnRzIGFuZCBzZXJ2aWNlCiBhY2NvdW50cyBhcmUgc3VwcG9ydGVkLgoKDwoHBAIE
AQIEARIEjAEEIgoPCgcEAgQBAgQCEgSMASUmCksKBAQCAwASBpABApcBAxo7IERldGFpbHMg
YWJvdXQgd2hldGhlciB0aGUgYmluZGluZyBpbmNsdWRlcyB0aGUgcHJpbmNpcGFsLgoKDQoF
BAIDAAESBJABCh0KRwoGBAIDAAIAEgSSAQQeGjcgSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGJp
bmRpbmcgaW5jbHVkZXMgdGhlIHByaW5jaXBhbC4KCg8KBwQCAwACAAYSBJIBBA4KDwoHBAID
AAIAARIEkgEPGQoPCgcEAgMAAgADEgSSARwdCmgKBgQCAwACARIElgEEJRpYIFRoZSByZWxl
dmFuY2Ugb2YgdGhlIHByaW5jaXBhbCdzIHN0YXR1cyB0byB0aGUgb3ZlcmFsbCBkZXRlcm1p
bmF0aW9uIGZvcgogdGhlIGJpbmRpbmcuCgoPCgcEAgMAAgEGEgSWAQQWCg8KBwQCAwACAQES
BJYBFyAKDwoHBAIDAAIBAxIElgEjJArjAwoEBAICABIEoQECQhrUAyBSZXF1aXJlZC4gSW5k
aWNhdGVzIHdoZXRoZXIgX3RoaXMgYmluZGluZ18gcHJvdmlkZXMgdGhlIHNwZWNpZmllZAog
cGVybWlzc2lvbiB0byB0aGUgc3BlY2lmaWVkIHByaW5jaXBhbCBmb3IgdGhlIHNwZWNpZmll
ZCByZXNvdXJjZS4KCiBUaGlzIGZpZWxkIGRvZXMgX25vdF8gaW5kaWNhdGUgd2hldGhlciB0
aGUgcHJpbmNpcGFsIGFjdHVhbGx5IGhhcyB0aGUKIHBlcm1pc3Npb24gZm9yIHRoZSByZXNv
dXJjZS4gVGhlcmUgbWlnaHQgYmUgYW5vdGhlciBiaW5kaW5nIHRoYXQgb3ZlcnJpZGVzCiB0
aGlzIGJpbmRpbmcuIFRvIGRldGVybWluZSB3aGV0aGVyIHRoZSBwcmluY2lwYWwgYWN0dWFs
bHkgaGFzIHRoZQogcGVybWlzc2lvbiwgdXNlIHRoZSBgYWNjZXNzYCBmaWVsZCBpbiB0aGUK
IFtUcm91Ymxlc2hvb3RJYW1Qb2xpY3lSZXNwb25zZV1bSWFtQ2hlY2tlci5Ucm91Ymxlc2hv
b3RJYW1Qb2xpY3lSZXNwb25zZV0uCgoNCgUEAgIABhIEoQECDQoNCgUEAgIAARIEoQEOFAoN
CgUEAgIAAxIEoQEXGAoNCgUEAgIACBIEoQEZQQoQCggEAgIACJwIABIEoQEaQArvAQoEBAIC
ARIEqAECEhrgASBUaGUgcm9sZSB0aGF0IHRoaXMgYmluZGluZyBncmFudHMuIEZvciBleGFt
cGxlLAogYHJvbGVzL2NvbXB1dGUuc2VydmljZUFnZW50YC4KCiBGb3IgYSBjb21wbGV0ZSBs
aXN0IG9mIHByZWRlZmluZWQgSUFNIHJvbGVzLCBhcyB3ZWxsIGFzIHRoZSBwZXJtaXNzaW9u
cyBpbgogZWFjaCByb2xlLCBzZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxw
L3JvbGVzL3JlZmVyZW5jZS4KCg0KBQQCAgEFEgSoAQIICg0KBQQCAgEBEgSoAQkNCg0KBQQC
AgEDEgSoARARCmYKBAQCAgISBKwBAiUaWCBJbmRpY2F0ZXMgd2hldGhlciB0aGUgcm9sZSBn
cmFudGVkIGJ5IHRoaXMgYmluZGluZyBjb250YWlucyB0aGUgc3BlY2lmaWVkCiBwZXJtaXNz
aW9uLgoKDQoFBAICAgYSBKwBAhAKDQoFBAICAgESBKwBESAKDQoFBAICAgMSBKwBIyQKjwEK
BAQCAgMSBLABAjMagAEgVGhlIHJlbGV2YW5jZSBvZiB0aGUgcGVybWlzc2lvbidzIGV4aXN0
ZW5jZSwgb3Igbm9uZXhpc3RlbmNlLCBpbiB0aGUgcm9sZQogdG8gdGhlIG92ZXJhbGwgZGV0
ZXJtaW5hdGlvbiBmb3IgdGhlIGVudGlyZSBwb2xpY3kuCgoNCgUEAgIDBhIEsAECFAoNCgUE
AgIDARIEsAEVLgoNCgUEAgIDAxIEsAExMgr3BgoEBAICBBIExgECMxroBiBJbmRpY2F0ZXMg
d2hldGhlciBlYWNoIHByaW5jaXBhbCBpbiB0aGUgYmluZGluZyBpbmNsdWRlcyB0aGUgcHJp
bmNpcGFsCiBzcGVjaWZpZWQgaW4gdGhlIHJlcXVlc3QsIGVpdGhlciBkaXJlY3RseSBvciBp
bmRpcmVjdGx5LiBFYWNoIGtleQogaWRlbnRpZmllcyBhIHByaW5jaXBhbCBpbiB0aGUgYmlu
ZGluZywgYW5kIGVhY2ggdmFsdWUgaW5kaWNhdGVzIHdoZXRoZXIgdGhlCiBwcmluY2lwYWwg
aW4gdGhlIGJpbmRpbmcgaW5jbHVkZXMgdGhlIHByaW5jaXBhbCBpbiB0aGUgcmVxdWVzdC4K
CiBGb3IgZXhhbXBsZSwgc3VwcG9zZSB0aGF0IGEgYmluZGluZyBpbmNsdWRlcyB0aGUgZm9s
bG93aW5nIHByaW5jaXBhbHM6CgogKiBgdXNlcjphbGljZUBleGFtcGxlLmNvbWAKICogYGdy
b3VwOnByb2R1Y3QtZW5nQGV4YW1wbGUuY29tYAoKIFlvdSB3YW50IHRvIHRyb3VibGVzaG9v
dCBhY2Nlc3MgZm9yIGB1c2VyOmJvYkBleGFtcGxlLmNvbWAuIFRoaXMgdXNlciBpcyBhCiBw
cmluY2lwYWwgb2YgdGhlIGdyb3VwIGBncm91cDpwcm9kdWN0LWVuZ0BleGFtcGxlLmNvbWAu
CgogRm9yIHRoZSBmaXJzdCBwcmluY2lwYWwgaW4gdGhlIGJpbmRpbmcsIHRoZSBrZXkgaXMK
IGB1c2VyOmFsaWNlQGV4YW1wbGUuY29tYCwgYW5kIHRoZSBgbWVtYmVyc2hpcGAgZmllbGQg
aW4gdGhlIHZhbHVlIGlzIHNldCB0bwogYE1FTUJFUlNISVBfTk9UX0lOQ0xVREVEYC4KCiBG
b3IgdGhlIHNlY29uZCBwcmluY2lwYWwgaW4gdGhlIGJpbmRpbmcsIHRoZSBrZXkgaXMKIGBn
cm91cDpwcm9kdWN0LWVuZ0BleGFtcGxlLmNvbWAsIGFuZCB0aGUgYG1lbWJlcnNoaXBgIGZp
ZWxkIGluIHRoZSB2YWx1ZSBpcwogc2V0IHRvIGBNRU1CRVJTSElQX0lOQ0xVREVEYC4KCg0K
BQQCAgQGEgTGAQIiCg0KBQQCAgQBEgTGASMuCg0KBQQCAgQDEgTGATEyCmIKBAQCAgUSBMoB
AiMaVCBUaGUgcmVsZXZhbmNlIG9mIHRoaXMgYmluZGluZyB0byB0aGUgb3ZlcmFsbCBkZXRl
cm1pbmF0aW9uIGZvciB0aGUgZW50aXJlCiBwb2xpY3kuCgoNCgUEAgIFBhIEygECFAoNCgUE
AgIFARIEygEVHgoNCgUEAgIFAxIEygEhIgrgAQoEBAICBhIE0QECIRrRASBBIGNvbmRpdGlv
biBleHByZXNzaW9uIHRoYXQgcHJldmVudHMgdGhpcyBiaW5kaW5nIGZyb20gZ3JhbnRpbmcg
YWNjZXNzCiB1bmxlc3MgdGhlIGV4cHJlc3Npb24gZXZhbHVhdGVzIHRvIGB0cnVlYC4KCiBU
byBsZWFybiBhYm91dCBJQU0gQ29uZGl0aW9ucywgc2VlCiBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vaWFtL2hlbHAvY29uZGl0aW9ucy9vdmVydmlldy4KCg0KBQQCAgYGEgTRAQISCg0K
BQQCAgYBEgTRARMcCg0KBQQCAgYDEgTRAR8gCkQKAgUAEgbVAQDmAQEaNiBXaGV0aGVyIGEg
cHJpbmNpcGFsIGhhcyBhIHBlcm1pc3Npb24gZm9yIGEgcmVzb3VyY2UuCgoLCgMFAAESBNUB
BRAKNAoEBQACABIE1wECHxomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2Vk
LgoKDQoFBQACAAESBNcBAhoKDQoFBQACAAISBNcBHR4KMQoEBQACARIE2gECDhojIFRoZSBw
cmluY2lwYWwgaGFzIHRoZSBwZXJtaXNzaW9uLgoKDQoFBQACAQESBNoBAgkKDQoFBQACAQIS
BNoBDA0KOwoEBQACAhIE3QECEhotIFRoZSBwcmluY2lwYWwgZG9lcyBub3QgaGF2ZSB0aGUg
cGVybWlzc2lvbi4KCg0KBQUAAgIBEgTdAQINCg0KBQUAAgICEgTdARARCmUKBAUAAgMSBOEB
AhoaVyBUaGUgcHJpbmNpcGFsIGhhcyB0aGUgcGVybWlzc2lvbiBvbmx5IGlmIGEgY29uZGl0
aW9uIGV4cHJlc3Npb24gZXZhbHVhdGVzCiB0byBgdHJ1ZWAuCgoNCgUFAAIDARIE4QECFQoN
CgUFAAIDAhIE4QEYGQqEAQoEBQACBBIE5QECGhp2IFRoZSBzZW5kZXIgb2YgdGhlIHJlcXVl
c3QgZG9lcyBub3QgaGF2ZSBhY2Nlc3MgdG8gYWxsIG9mIHRoZSBwb2xpY2llcyB0aGF0CiBQ
b2xpY3kgVHJvdWJsZXNob290ZXIgbmVlZHMgdG8gZXZhbHVhdGUuCgoNCgUFAAIEARIE5QEC
FQoNCgUFAAIEAhIE5QEYGQq7AQoCBQESBusBAPYBARqsASBUaGUgZXh0ZW50IHRvIHdoaWNo
IGEgc2luZ2xlIGRhdGEgcG9pbnQsIHN1Y2ggYXMgdGhlIGV4aXN0ZW5jZSBvZiBhIGJpbmRp
bmcKIG9yIHdoZXRoZXIgYSBiaW5kaW5nIGluY2x1ZGVzIGEgc3BlY2lmaWMgcHJpbmNpcGFs
LCBjb250cmlidXRlcyB0byBhbiBvdmVyYWxsCiBkZXRlcm1pbmF0aW9uLgoKCwoDBQEBEgTr
AQUXCjQKBAUBAgASBO0BAiYaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNl
ZC4KCg0KBQUBAgABEgTtAQIhCg0KBQUBAgACEgTtASQlCowBCgQFAQIBEgTxAQINGn4gVGhl
IGRhdGEgcG9pbnQgaGFzIGEgbGltaXRlZCBlZmZlY3Qgb24gdGhlIHJlc3VsdC4gQ2hhbmdp
bmcgdGhlIGRhdGEgcG9pbnQKIGlzIHVubGlrZWx5IHRvIGFmZmVjdCB0aGUgb3ZlcmFsbCBk
ZXRlcm1pbmF0aW9uLgoKDQoFBQECAQESBPEBAggKDQoFBQECAQISBPEBCwwKiQEKBAUBAgIS
BPUBAgsaeyBUaGUgZGF0YSBwb2ludCBoYXMgYSBzdHJvbmcgZWZmZWN0IG9uIHRoZSByZXN1
bHQuIENoYW5naW5nIHRoZSBkYXRhIHBvaW50CiBpcyBsaWtlbHkgdG8gYWZmZWN0IHRoZSBv
dmVyYWxsIGRldGVybWluYXRpb24uCgoNCgUFAQICARIE9QECBgoNCgUFAQICAhIE9QEJCmIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Policytroubleshooter::V1::Explanations::AccessTuple ===
    # Fields for AccessTuple
    # Field: principal Type: 9 ()
    # Field: full_resource_name Type: 9 ()
    # Field: permission Type: 9 ()

# === Message: Google::Cloud::Policytroubleshooter::V1::Explanations::ExplainedPolicy ===
    # Fields for ExplainedPolicy
    # Field: access Type: 14 (.google.cloud.policytroubleshooter.v1.AccessState)
    # Field: full_resource_name Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: binding_explanations Type: 11 (.google.cloud.policytroubleshooter.v1.BindingExplanation)
    # Field: relevance Type: 14 (.google.cloud.policytroubleshooter.v1.HeuristicRelevance)

# === Message: Google::Cloud::Policytroubleshooter::V1::Explanations::BindingExplanation ===
    # Fields for BindingExplanation
    # Field: access Type: 14 (.google.cloud.policytroubleshooter.v1.AccessState)
    # Field: role Type: 9 ()
    # Field: role_permission Type: 14 (.google.cloud.policytroubleshooter.v1.BindingExplanation.RolePermission)
    # Field: role_permission_relevance Type: 14 (.google.cloud.policytroubleshooter.v1.HeuristicRelevance)
    # Field: memberships Type: 11 (.google.cloud.policytroubleshooter.v1.BindingExplanation.MembershipsEntry)
    # Field: relevance Type: 14 (.google.cloud.policytroubleshooter.v1.HeuristicRelevance)
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

Google::Cloud::Policytroubleshooter::V1::Explanations - Compiled Protocol Buffers messages for google/cloud/policytroubleshooter/v1/explanations.proto

=head1 SYNOPSIS

    use Google::Cloud::Policytroubleshooter::V1::Explanations;

    my $msg = Google::Cloud::Policytroubleshooter::V1::Explanations::AccessTuple->new({
        principal => $principal,
        full_resource_name => $full_resource_name,
        permission => $permission,
    });

    # Read or update a field
    my $val = $msg->principal();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Policytroubleshooter::V1::Explanations::AccessTuple->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/policytroubleshooter/v1/explanations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Policytroubleshooter::V1::Explanations::AccessTuple

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

=head2 Google::Cloud::Policytroubleshooter::V1::Explanations::ExplainedPolicy

Details about how a specific IAM [Policy][google.iam.v1.Policy] contributed
to the access check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::AccessState>)

Indicates whether _this policy_ provides the specified permission to the
specified principal for the specified resource.

This field does _not_ indicate whether the principal actually has the
permission for the resource. There might be another policy that overrides
this policy. To determine whether the principal actually has the
permission, use the `access` field in the
[TroubleshootIamPolicyResponse][IamChecker.TroubleshootIamPolicyResponse].

=item * C<< $msg->full_resource_name() >> / C<< $msg->full_resource_name($value) >>

Type: C<String>

The full resource name that identifies the resource. For example,
`//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`.

If the sender of the request does not have access to the policy, this field
is omitted.

For examples of full resource names for Google Cloud services, see
https://cloud.google.com/iam/help/troubleshooter/full-resource-names.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

The IAM policy attached to the resource.

If the sender of the request does not have access to the policy, this field
is empty.

=item * C<< $msg->binding_explanations() >> / C<< $msg->binding_explanations($value) >>

Type: C<Message> (L<Google::Cloud::Policytroubleshooter::V1::Explanations::BindingExplanation>)

Details about how each binding in the policy affects the principal's
ability, or inability, to use the permission for the resource.

If the sender of the request does not have access to the policy, this field
is omitted.

=item * C<< $msg->relevance() >> / C<< $msg->relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::HeuristicRelevance>)

The relevance of this policy to the overall determination in the
[TroubleshootIamPolicyResponse][IamChecker.TroubleshootIamPolicyResponse].

If the sender of the request does not have access to the policy, this field
is omitted.

=back

=head2 Google::Cloud::Policytroubleshooter::V1::Explanations::BindingExplanation

Details about how a binding in a policy affects a principal's ability to use
a permission.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::AccessState>)

Required. Indicates whether _this binding_ provides the specified
permission to the specified principal for the specified resource.

This field does _not_ indicate whether the principal actually has the
permission for the resource. There might be another binding that overrides
this binding. To determine whether the principal actually has the
permission, use the `access` field in the
[TroubleshootIamPolicyResponse][IamChecker.TroubleshootIamPolicyResponse].

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

The role that this binding grants. For example,
`roles/compute.serviceAgent`.

For a complete list of predefined IAM roles, as well as the permissions in
each role, see https://cloud.google.com/iam/help/roles/reference.

=item * C<< $msg->role_permission() >> / C<< $msg->role_permission($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::BindingExplanation::RolePermission>)

Indicates whether the role granted by this binding contains the specified
permission.

=item * C<< $msg->role_permission_relevance() >> / C<< $msg->role_permission_relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::HeuristicRelevance>)

The relevance of the permission's existence, or nonexistence, in the role
to the overall determination for the entire policy.

=item * C<< $msg->memberships() >> / C<< $msg->memberships($value) >>

Type: C<Message> (L<Google::Cloud::Policytroubleshooter::V1::Explanations::BindingExplanation::MembershipsEntry>)

Indicates whether each principal in the binding includes the principal
specified in the request, either directly or indirectly. Each key
identifies a principal in the binding, and each value indicates whether the
principal in the binding includes the principal in the request.

For example, suppose that a binding includes the following principals:

* `user:alice@example.com`
* `group:product-eng@example.com`

You want to troubleshoot access for `user:bob@example.com`. This user is a
principal of the group `group:product-eng@example.com`.

For the first principal in the binding, the key is
`user:alice@example.com`, and the `membership` field in the value is set to
`MEMBERSHIP_NOT_INCLUDED`.

For the second principal in the binding, the key is
`group:product-eng@example.com`, and the `membership` field in the value is
set to `MEMBERSHIP_INCLUDED`.

=item * C<< $msg->relevance() >> / C<< $msg->relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::HeuristicRelevance>)

The relevance of this binding to the overall determination for the entire
policy.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

A condition expression that prevents this binding from granting access
unless the expression evaluates to `true`.

To learn about IAM Conditions, see
https://cloud.google.com/iam/help/conditions/overview.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Policytroubleshooter::V1::Explanations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
