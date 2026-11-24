package Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Osconfig::V1alpha::ConfigCommon };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvb3Njb25maWcvdjFhbHBoYS9pbnN0YW5jZV9vc19wb2xpY2llc19j
b21wbGlhbmNlLnByb3RvEh1nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxox
Z29vZ2xlL2Nsb3VkL29zY29uZmlnL3YxYWxwaGEvY29uZmlnX2NvbW1vbi5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKxCAocSW5zdGFuY2VPU1BvbGljaWVzQ29t
cGxpYW5jZRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSHwoIaW5zdGFuY2UYAiABKAlCA+BB
A1IIaW5zdGFuY2USUQoFc3RhdGUYAyABKA4yNi5nb29nbGUuY2xvdWQub3Njb25maWcudjFh
bHBoYS5PU1BvbGljeUNvbXBsaWFuY2VTdGF0ZUID4EEDUgVzdGF0ZRIqCg5kZXRhaWxlZF9z
dGF0ZRgEIAEoCUID4EEDUg1kZXRhaWxlZFN0YXRlEjcKFWRldGFpbGVkX3N0YXRlX3JlYXNv
bhgFIAEoCUID4EEDUhNkZXRhaWxlZFN0YXRlUmVhc29uEocBChVvc19wb2xpY3lfY29tcGxp
YW5jZXMYBiADKAsyTi5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5JbnN0YW5jZU9T
UG9saWNpZXNDb21wbGlhbmNlLk9TUG9saWN5Q29tcGxpYW5jZUID4EEDUhNvc1BvbGljeUNv
bXBsaWFuY2VzElwKGmxhc3RfY29tcGxpYW5jZV9jaGVja190aW1lGAcgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhdsYXN0Q29tcGxpYW5jZUNoZWNrVGltZRI4ChZs
YXN0X2NvbXBsaWFuY2VfcnVuX2lkGAggASgJQgPgQQNSE2xhc3RDb21wbGlhbmNlUnVuSWQa
6wIKEk9TUG9saWN5Q29tcGxpYW5jZRIgCgxvc19wb2xpY3lfaWQYASABKAlSCm9zUG9saWN5
SWQSYQoUb3NfcG9saWN5X2Fzc2lnbm1lbnQYAiABKAlCL/pBLAoqb3Njb25maWcuZ29vZ2xl
YXBpcy5jb20vT1NQb2xpY3lBc3NpZ25tZW50UhJvc1BvbGljeUFzc2lnbm1lbnQSTAoFc3Rh
dGUYBCABKA4yNi5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5PU1BvbGljeUNvbXBs
aWFuY2VTdGF0ZVIFc3RhdGUSfgoeb3NfcG9saWN5X3Jlc291cmNlX2NvbXBsaWFuY2VzGAUg
AygLMjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuT1NQb2xpY3lSZXNvdXJjZUNv
bXBsaWFuY2VSG29zUG9saWN5UmVzb3VyY2VDb21wbGlhbmNlczoCGAE6jgEYAepBiAEKNG9z
Y29uZmlnLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlT1NQb2xpY2llc0NvbXBsaWFuY2USUHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZU9TUG9saWNp
ZXNDb21wbGlhbmNlcy97aW5zdGFuY2V9In4KJkdldEluc3RhbmNlT1NQb2xpY2llc0NvbXBs
aWFuY2VSZXF1ZXN0ElAKBG5hbWUYASABKAlCPOBBAvpBNgo0b3Njb25maWcuZ29vZ2xlYXBp
cy5jb20vSW5zdGFuY2VPU1BvbGljaWVzQ29tcGxpYW5jZVIEbmFtZToCGAEixQEKKExpc3RJ
bnN0YW5jZU9TUG9saWNpZXNDb21wbGlhbmNlc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQing
QQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
EhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyOgIYASLeAQopTGlzdEluc3RhbmNlT1NQb2xpY2ll
c0NvbXBsaWFuY2VzUmVzcG9uc2UShAEKIGluc3RhbmNlX29zX3BvbGljaWVzX2NvbXBsaWFu
Y2VzGAEgAygLMjsuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuSW5zdGFuY2VPU1Bv
bGljaWVzQ29tcGxpYW5jZVIdaW5zdGFuY2VPc1BvbGljaWVzQ29tcGxpYW5jZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuOgIYAULqAQohY29tLmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy52MWFscGhhQiFJbnN0YW5jZU9TUG9saWNpZXNDb21wbGlhbmNlUHJv
dG9QAVo9Y2xvdWQuZ29vZ2xlLmNvbS9nby9vc2NvbmZpZy9hcGl2MWFscGhhL29zY29uZmln
cGI7b3Njb25maWdwYqoCHUdvb2dsZS5DbG91ZC5Pc0NvbmZpZy5WMUFscGhhygIdR29vZ2xl
XENsb3VkXE9zQ29uZmlnXFYxYWxwaGHqAiBHb29nbGU6OkNsb3VkOjpPc0NvbmZpZzo6VjFh
bHBoYUqcMQoHEgUOALUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOwoJCgIDAxIDFQApCggK
AQgSAxcAOgoJCgIIJRIDFwA6CggKAQgSAxgAVAoJCgIICxIDGABUCggKAQgSAxkAIgoJCgII
ChIDGQAiCggKAQgSAxoAQgoJCgIICBIDGgBCCggKAQgSAxsAOgoJCgIIARIDGwA6CggKAQgS
AxwAOgoJCgIIKRIDHAA6CggKAQgSAx0AOQoJCgIILRIDHQA5CuIECgIEABIEKwBzARrVBCBU
aGlzIEFQSSByZXNvdXJjZSByZXByZXNlbnRzIHRoZSBPUyBwb2xpY2llcyBjb21wbGlhbmNl
IGRhdGEgZm9yIGEgQ29tcHV0ZQogRW5naW5lIHZpcnR1YWwgbWFjaGluZSAoVk0pIGluc3Rh
bmNlIGF0IGEgZ2l2ZW4gcG9pbnQgaW4gdGltZS4KCiBBIENvbXB1dGUgRW5naW5lIFZNIGNh
biBoYXZlIG11bHRpcGxlIE9TIHBvbGljeSBhc3NpZ25tZW50cywgYW5kIGVhY2gKIGFzc2ln
bm1lbnQgY2FuIGhhdmUgbXVsdGlwbGUgT1MgcG9saWNpZXMuIEFzIGEgcmVzdWx0LCBtdWx0
aXBsZSBPUyBwb2xpY2llcwogY291bGQgYmUgYXBwbGllZCB0byBhIHNpbmdsZSBWTS4KCiBZ
b3UgY2FuIHVzZSB0aGlzIEFQSSByZXNvdXJjZSB0byBkZXRlcm1pbmUgYm90aCB0aGUgY29t
cGxpYW5jZSBzdGF0ZSBvZiB5b3VyCiBWTSBhcyB3ZWxsIGFzIHRoZSBjb21wbGlhbmNlIHN0
YXRlIG9mIGFuIGluZGl2aWR1YWwgT1MgcG9saWN5LgoKIEZvciBtb3JlIGluZm9ybWF0aW9u
LCBzZWUgW1ZpZXcKIGNvbXBsaWFuY2VdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21w
dXRlL2RvY3Mvb3MtY29uZmlndXJhdGlvbi1tYW5hZ2VtZW50L3ZpZXctY29tcGxpYW5jZSku
CgoKCgMEAAESAysIJAoKCgMEAAcSAywCGwoLCgQEAAcDEgMsAhsKCwoDBAAHEgQtAjAECg0K
BQQAB50IEgQtAjAECjAKBAQAAwASBDMCSAMaIiBDb21wbGlhbmNlIGRhdGEgZm9yIGFuIE9T
IHBvbGljeQoKDAoFBAADAAESAzMKHAoMCgUEAAMABxIDNAQdCg0KBgQAAwAHAxIDNAQdCiEK
BgQAAwACABIDNwQcGhIgVGhlIE9TIHBvbGljeSBpZAoKDgoHBAADAAIABRIDNwQKCg4KBwQA
AwACAAESAzcLFwoOCgcEAAMAAgADEgM3GhsK3AEKBgQAAwACARIEPgRAKBrLASBSZWZlcmVu
Y2UgdG8gdGhlIGBPU1BvbGljeUFzc2lnbm1lbnRgIEFQSSByZXNvdXJjZSB0aGF0IHRoZSBg
T1NQb2xpY3lgCiBiZWxvbmdzIHRvLgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9u
dW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L29zUG9saWN5QXNzaWdubWVudHMve29zX3Bv
bGljeV9hc3NpZ25tZW50X2lkQHJldmlzaW9uX2lkfWAKCg4KBwQAAwACAQUSAz4ECgoOCgcE
AAMAAgEBEgM+Cx8KDgoHBAADAAIBAxIDPiIjCg8KBwQAAwACAQgSBD4kQCcKEQoJBAADAAIB
CJ8IEgQ+JUAmCjMKBgQAAwACAhIDQwQmGiQgQ29tcGxpYW5jZSBzdGF0ZSBvZiB0aGUgT1Mg
cG9saWN5LgoKDgoHBAADAAICBhIDQwQbCg4KBwQAAwACAgESA0McIQoOCgcEAAMAAgIDEgND
JCUKWAoGBAADAAIDEgNHBEsaSSBDb21wbGlhbmNlIGRhdGEgZm9yIGVhY2ggYE9TUG9saWN5
UmVzb3VyY2VgIHRoYXQgaXMgYXBwbGllZCB0byB0aGUKIFZNLgoKDgoHBAADAAIDBBIDRwQM
Cg4KBwQAAwACAwYSA0cNJwoOCgcEAAMAAgMBEgNHKEYKDgoHBAADAAIDAxIDR0lKCroBCgQE
AAIAEgNOAj4arAEgT3V0cHV0IG9ubHkuIFRoZSBgSW5zdGFuY2VPU1BvbGljaWVzQ29tcGxp
YW5jZWAgQVBJIHJlc291cmNlIG5hbWUuCgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VPU1BvbGljaWVzQ29tcGxp
YW5jZXMve2luc3RhbmNlX2lkfWAKCgwKBQQAAgAFEgNOAggKDAoFBAACAAESA04JDQoMCgUE
AAIAAxIDThARCgwKBQQAAgAIEgNOEj0KDwoIBAACAAicCAASA04TPApACgQEAAIBEgNRAkIa
MyBPdXRwdXQgb25seS4gVGhlIENvbXB1dGUgRW5naW5lIFZNIGluc3RhbmNlIG5hbWUuCgoM
CgUEAAIBBRIDUQIICgwKBQQAAgEBEgNRCREKDAoFBAACAQMSA1EUFQoMCgUEAAIBCBIDURZB
Cg8KCAQAAgEInAgAEgNRF0AKNwoEBAACAhIDVAJQGiogT3V0cHV0IG9ubHkuIENvbXBsaWFu
Y2Ugc3RhdGUgb2YgdGhlIFZNLgoKDAoFBAACAgYSA1QCGQoMCgUEAAICARIDVBofCgwKBQQA
AgIDEgNUIiMKDAoFBAACAggSA1QkTwoPCggEAAICCJwIABIDVCVOCqMFCgQEAAIDEgNkAkga
lQUgT3V0cHV0IG9ubHkuIERldGFpbGVkIGNvbXBsaWFuY2Ugc3RhdGUgb2YgdGhlIFZNLgog
VGhpcyBmaWVsZCBpcyBwb3B1bGF0ZWQgb25seSB3aGVuIGNvbXBsaWFuY2Ugc3RhdGUgaXMg
YFVOS05PV05gLgoKIEl0IG1heSBjb250YWluIG9uZSBvZiB0aGUgZm9sbG93aW5nIHZhbHVl
czoKCiAqIGBuby1jb21wbGlhbmNlLWRhdGFgOiBDb21wbGlhbmNlIGRhdGEgaXMgbm90IGF2
YWlsYWJsZSBmb3IgdGhpcyBWTS4KICogYG5vLWFnZW50LWRldGVjdGVkYDogT1MgQ29uZmln
IGFnZW50IGlzIG5vdCBkZXRlY3RlZCBmb3IgdGhpcyBWTS4KICogYGNvbmZpZy1ub3Qtc3Vw
cG9ydGVkLWJ5LWFnZW50YDogVGhlIHZlcnNpb24gb2YgdGhlIE9TIENvbmZpZyBhZ2VudAog
cnVubmluZyBvbiB0aGlzIFZNIGRvZXMgbm90IHN1cHBvcnQgY29uZmlndXJhdGlvbiBtYW5h
Z2VtZW50LgogKiBgaW5hY3RpdmVgOiBWTSBpcyBub3QgcnVubmluZy4KICogYGludGVybmFs
LXNlcnZpY2UtZXJyb3JzYDogVGhlcmUgd2VyZSBpbnRlcm5hbCBzZXJ2aWNlIGVycm9ycyBl
bmNvdW50ZXJlZAogd2hpbGUgZW5mb3JjaW5nIGNvbXBsaWFuY2UuCiAqIGBhZ2VudC1lcnJv
cnNgOiBPUyBjb25maWcgYWdlbnQgZW5jb3VudGVyZWQgZXJyb3JzIHdoaWxlIGVuZm9yY2lu
ZwogY29tcGxpYW5jZS4KCgwKBQQAAgMFEgNkAggKDAoFBAACAwESA2QJFwoMCgUEAAIDAxID
ZBobCgwKBQQAAgMIEgNkHEcKDwoIBAACAwicCAASA2QdRgpTCgQEAAIEEgNnAk8aRiBPdXRw
dXQgb25seS4gVGhlIHJlYXNvbiBmb3IgdGhlIGBkZXRhaWxlZF9zdGF0ZWAgb2YgdGhlIFZN
IChpZiBhbnkpLgoKDAoFBAACBAUSA2cCCAoMCgUEAAIEARIDZwkeCgwKBQQAAgQDEgNnISIK
DAoFBAACBAgSA2cjTgoPCggEAAIECJwIABIDZyRNCloKBAQAAgUSA2oCZBpNIE91dHB1dCBv
bmx5LiBDb21wbGlhbmNlIGRhdGEgZm9yIGVhY2ggYE9TUG9saWN5YCB0aGF0IGlzIGFwcGxp
ZWQgdG8gdGhlIFZNLgoKDAoFBAACBQQSA2oCCgoMCgUEAAIFBhIDagsdCgwKBQQAAgUBEgNq
HjMKDAoFBAACBQMSA2o2NwoMCgUEAAIFCBIDajhjCg8KCAQAAgUInAgAEgNqOWIKTgoEBAAC
BhIDbQJnGkEgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCBvZiB0aGUgbGFzdCBjb21wbGlhbmNl
IGNoZWNrIGZvciB0aGUgVk0uCgoMCgUEAAIGBhIDbQIbCgwKBQQAAgYBEgNtHDYKDAoFBAAC
BgMSA205OgoMCgUEAAIGCBIDbTtmCg8KCAQAAgYInAgAEgNtPGUKxgEKBAQAAgcSA3ICUBq4
ASBPdXRwdXQgb25seS4gVW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBsYXN0IGNvbXBsaWFu
Y2UgcnVuLgogVGhpcyBpZCB3aWxsIGJlIGxvZ2dlZCBieSB0aGUgT1MgY29uZmlnIGFnZW50
IGR1cmluZyBhIGNvbXBsaWFuY2UgcnVuIGFuZAogY2FuIGJlIHVzZWQgZm9yIGRlYnVnZ2lu
ZyBhbmQgdHJhY2luZyBwdXJwb3NlLgoKDAoFBAACBwUSA3ICCAoMCgUEAAIHARIDcgkfCgwK
BQQAAgcDEgNyIiMKDAoFBAACBwgSA3IkTwoPCggEAAIHCJwIABIDciVOCnMKAgQBEgV3AIkB
ARpmIEEgcmVxdWVzdCBtZXNzYWdlIGZvciBnZXR0aW5nIE9TIHBvbGljaWVzIGNvbXBsaWFu
Y2UgZGF0YSBmb3IgdGhlIGdpdmVuCiBDb21wdXRlIEVuZ2luZSBWTSBpbnN0YW5jZS4KCgoK
AwQBARIDdwguCgoKAwQBBxIDeAIbCgsKBAQBBwMSA3gCGwrtAgoEBAECABIGgwECiAEEGtwC
IFJlcXVpcmVkLiBBUEkgcmVzb3VyY2UgbmFtZSBmb3IgaW5zdGFuY2UgT1MgcG9saWNpZXMg
Y29tcGxpYW5jZSByZXNvdXJjZS4KCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlT1NQb2xpY2llc0NvbXBsaWFuY2VzL3tpbnN0
YW5jZX1gCgogRm9yIGB7cHJvamVjdH1gLCBlaXRoZXIgQ29tcHV0ZSBFbmdpbmUgcHJvamVj
dC1udW1iZXIgb3IgcHJvamVjdC1pZCBjYW4gYmUKIHByb3ZpZGVkLgogRm9yIGB7aW5zdGFu
Y2V9YCwgZWl0aGVyIENvbXB1dGUgRW5naW5lIFZNIGluc3RhbmNlLWlkIG9yIGluc3RhbmNl
LW5hbWUgY2FuCiBiZSBwcm92aWRlZC4KCg0KBQQBAgAFEgSDAQIICg0KBQQBAgABEgSDAQkN
Cg0KBQQBAgADEgSDARARCg8KBQQBAgAIEgaDARKIAQMKEAoIBAECAAicCAASBIQBBCoKEQoH
BAECAAifCBIGhQEEhwEFCnwKAgQCEgaNAQCoAQEabiBBIHJlcXVlc3QgbWVzc2FnZSBmb3Ig
bGlzdGluZyBPUyBwb2xpY2llcyBjb21wbGlhbmNlIGRhdGEgZm9yIGFsbCBDb21wdXRlCiBF
bmdpbmUgVk1zIGluIHRoZSBnaXZlbiBsb2NhdGlvbi4KCgsKAwQCARIEjQEIMAoLCgMEAgcS
BI4BAhsKDAoEBAIHAxIEjgECGwrCAQoEBAICABIGlgECmwEEGrEBIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIG5hbWUuCgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259YAoKIEZvciBge3Byb2plY3R9YCwgZWl0aGVyIENvbXB1dGUg
RW5naW5lIHByb2plY3QtbnVtYmVyIG9yIHByb2plY3QtaWQgY2FuIGJlCiBwcm92aWRlZC4K
Cg0KBQQCAgAFEgSWAQIICg0KBQQCAgABEgSWAQkPCg0KBQQCAgADEgSWARITCg8KBQQCAgAI
EgaWARSbAQMKEAoIBAICAAicCAASBJcBBCoKEQoHBAICAAifCBIGmAEEmgEFCjgKBAQCAgES
BJ4BAhYaKiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uCgoNCgUE
AgIBBRIEngECBwoNCgUEAgIBARIEngEIEQoNCgUEAgIBAxIEngEUFQqiAQoEBAICAhIEowEC
GBqTASBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGNhbGwg
dG8KIGBMaXN0SW5zdGFuY2VPU1BvbGljaWVzQ29tcGxpYW5jZXNgIHRoYXQgaW5kaWNhdGVz
IHdoZXJlIHRoaXMgbGlzdGluZwogc2hvdWxkIGNvbnRpbnVlIGZyb20uCgoNCgUEAgICBRIE
owECCAoNCgUEAgICARIEowEJEwoNCgUEAgICAxIEowEWFwqiAQoEBAICAxIEpwECFBqTASBJ
ZiBwcm92aWRlZCwgdGhpcyBmaWVsZCBzcGVjaWZpZXMgdGhlIGNyaXRlcmlhIHRoYXQgbXVz
dCBiZSBtZXQgYnkgYQogYEluc3RhbmNlT1NQb2xpY2llc0NvbXBsaWFuY2VgIEFQSSByZXNv
dXJjZSB0byBiZSBpbmNsdWRlZCBpbiB0aGUgcmVzcG9uc2UuCgoNCgUEAgIDBRIEpwECCAoN
CgUEAgIDARIEpwEJDwoNCgUEAgIDAxIEpwESEwp9CgIEAxIGrAEAtQEBGm8gQSByZXNwb25z
ZSBtZXNzYWdlIGZvciBsaXN0aW5nIE9TIHBvbGljaWVzIGNvbXBsaWFuY2UgZGF0YSBmb3Ig
YWxsIENvbXB1dGUKIEVuZ2luZSBWTXMgaW4gdGhlIGdpdmVuIGxvY2F0aW9uLgoKCwoDBAMB
EgSsAQgxCgsKAwQDBxIErQECGwoMCgQEAwcDEgStAQIbCkAKBAQDAgASBLABAk0aMiBMaXN0
IG9mIGluc3RhbmNlIE9TIHBvbGljaWVzIGNvbXBsaWFuY2Ugb2JqZWN0cy4KCg0KBQQDAgAE
EgSwAQIKCg0KBQQDAgAGEgSwAQsnCg0KBQQDAgABEgSwAShICg0KBQQDAgADEgSwAUtMCmsK
BAQDAgESBLQBAh0aXSBUaGUgcGFnaW5hdGlvbiB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlIG9mIGluc3RhbmNlIE9TIHBvbGljaWVzCiBjb21wbGlhbmNlIG9iamVjdHMuCgoN
CgUEAwIBBRIEtAECCAoNCgUEAwIBARIEtAEJGAoNCgUEAwIBAxIEtAEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance ===
    # Fields for InstanceOSPoliciesCompliance
    # Field: name Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: state Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyComplianceState)
    # Field: detailed_state Type: 9 ()
    # Field: detailed_state_reason Type: 9 ()
    # Field: os_policy_compliances Type: 11 (.google.cloud.osconfig.v1alpha.InstanceOSPoliciesCompliance.OSPolicyCompliance)
    # Field: last_compliance_check_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_compliance_run_id Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest ===
    # Fields for GetInstanceOSPoliciesComplianceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest ===
    # Fields for ListInstanceOSPoliciesCompliancesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse ===
    # Fields for ListInstanceOSPoliciesCompliancesResponse
    # Field: instance_os_policies_compliances Type: 11 (.google.cloud.osconfig.v1alpha.InstanceOSPoliciesCompliance)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance - Compiled Protocol Buffers messages for google/cloud/osconfig/v1alpha/instance_os_policies_compliance.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance;

    my $msg = Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance->new({
        name => $name,
        instance => $instance,
        state => $state,
        detailed_state => $detailed_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1alpha/instance_os_policies_compliance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance

This API resource represents the OS policies compliance data for a Compute
Engine virtual machine (VM) instance at a given point in time.

A Compute Engine VM can have multiple OS policy assignments, and each
assignment can have multiple OS policies. As a result, multiple OS policies
could be applied to a single VM.

You can use this API resource to determine both the compliance state of your
VM as well as the compliance state of an individual OS policy.

For more information, see [View
compliance](https://cloud.google.com/compute/docs/os-configuration-management/view-compliance).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The `InstanceOSPoliciesCompliance` API resource name.

Format:
`projects/{project_number}/locations/{location}/instanceOSPoliciesCompliances/{instance_id}`

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Output only. The Compute Engine VM instance name.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyComplianceState>)

Output only. Compliance state of the VM.

=item * C<< $msg->detailed_state() >> / C<< $msg->detailed_state($value) >>

Type: C<String>

Output only. Detailed compliance state of the VM.
This field is populated only when compliance state is `UNKNOWN`.

It may contain one of the following values:

* `no-compliance-data`: Compliance data is not available for this VM.
* `no-agent-detected`: OS Config agent is not detected for this VM.
* `config-not-supported-by-agent`: The version of the OS Config agent
running on this VM does not support configuration management.
* `inactive`: VM is not running.
* `internal-service-errors`: There were internal service errors encountered
while enforcing compliance.
* `agent-errors`: OS config agent encountered errors while enforcing
compliance.

=item * C<< $msg->detailed_state_reason() >> / C<< $msg->detailed_state_reason($value) >>

Type: C<String>

Output only. The reason for the `detailed_state` of the VM (if any).

=item * C<< $msg->os_policy_compliances() >> / C<< $msg->os_policy_compliances($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance::OSPolicyCompliance>)

Output only. Compliance data for each `OSPolicy` that is applied to the VM.

=item * C<< $msg->last_compliance_check_time() >> / C<< $msg->last_compliance_check_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last compliance check for the VM.

=item * C<< $msg->last_compliance_run_id() >> / C<< $msg->last_compliance_run_id($value) >>

Type: C<String>

Output only. Unique identifier for the last compliance run.
This id will be logged by the OS config agent during a compliance run and
can be used for debugging and tracing purpose.

=back

=head2 Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest

A request message for getting OS policies compliance data for the given
Compute Engine VM instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. API resource name for instance OS policies compliance resource.

Format:
`projects/{project}/locations/{location}/instanceOSPoliciesCompliances/{instance}`

For `{project}`, either Compute Engine project-number or project-id can be
provided.
For `{instance}`, either Compute Engine VM instance-id or instance-name can
be provided.

=back

=head2 Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest

A request message for listing OS policies compliance data for all Compute
Engine VMs in the given location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.

Format: `projects/{project}/locations/{location}`

For `{project}`, either Compute Engine project-number or project-id can be
provided.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to
`ListInstanceOSPoliciesCompliances` that indicates where this listing
should continue from.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

If provided, this field specifies the criteria that must be met by a
`InstanceOSPoliciesCompliance` API resource to be included in the response.

=back

=head2 Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse

A response message for listing OS policies compliance data for all Compute
Engine VMs in the given location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_os_policies_compliances() >> / C<< $msg->instance_os_policies_compliances($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance>)

List of instance OS policies compliance objects.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token to retrieve the next page of instance OS policies
compliance objects.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
