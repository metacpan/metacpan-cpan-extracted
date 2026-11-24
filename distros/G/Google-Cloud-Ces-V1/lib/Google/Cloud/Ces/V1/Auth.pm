package Google::Cloud::Ces::V1::Auth;

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
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvY2xvdWQvY2VzL3YxL2F1dGgucHJvdG8SE2dvb2dsZS5jbG91ZC5jZXMudjEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8izQIKDEFwaUtleUNvbmZpZxIeCghrZXlfbmFtZRgBIAEoCUID4EECUgdrZXlOYW1l
EmcKFmFwaV9rZXlfc2VjcmV0X3ZlcnNpb24YAiABKAlCMuBBAvpBLAoqc2VjcmV0bWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9TZWNyZXRWZXJzaW9uUhNhcGlLZXlTZWNyZXRWZXJzaW9uEmEK
EHJlcXVlc3RfbG9jYXRpb24YAyABKA4yMS5nb29nbGUuY2xvdWQuY2VzLnYxLkFwaUtleUNv
bmZpZy5SZXF1ZXN0TG9jYXRpb25CA+BBAlIPcmVxdWVzdExvY2F0aW9uIlEKD1JlcXVlc3RM
b2NhdGlvbhIgChxSRVFVRVNUX0xPQ0FUSU9OX1VOU1BFQ0lGSUVEEAASCgoGSEVBREVSEAES
EAoMUVVFUllfU1RSSU5HEAIiiwMKC09BdXRoQ29uZmlnEl4KEG9hdXRoX2dyYW50X3R5cGUY
ASABKA4yLy5nb29nbGUuY2xvdWQuY2VzLnYxLk9BdXRoQ29uZmlnLk9hdXRoR3JhbnRUeXBl
QgPgQQJSDm9hdXRoR3JhbnRUeXBlEiAKCWNsaWVudF9pZBgCIAEoCUID4EECUghjbGllbnRJ
ZBJmChVjbGllbnRfc2VjcmV0X3ZlcnNpb24YAyABKAlCMuBBAvpBLAoqc2VjcmV0bWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9TZWNyZXRWZXJzaW9uUhNjbGllbnRTZWNyZXRWZXJzaW9uEioK
DnRva2VuX2VuZHBvaW50GAQgASgJQgPgQQJSDXRva2VuRW5kcG9pbnQSGwoGc2NvcGVzGAUg
AygJQgPgQQFSBnNjb3BlcyJJCg5PYXV0aEdyYW50VHlwZRIgChxPQVVUSF9HUkFOVF9UWVBF
X1VOU1BFQ0lGSUVEEAASFQoRQ0xJRU5UX0NSRURFTlRJQUwQASIfCh1TZXJ2aWNlQWdlbnRJ
ZFRva2VuQXV0aENvbmZpZyJlChhTZXJ2aWNlQWNjb3VudEF1dGhDb25maWcSLAoPc2Vydmlj
ZV9hY2NvdW50GAEgASgJQgPgQQJSDnNlcnZpY2VBY2NvdW50EhsKBnNjb3BlcxgCIAMoCUID
4EEBUgZzY29wZXMiLgoRQmVhcmVyVG9rZW5Db25maWcSGQoFdG9rZW4YASABKAlCA+BBAlIF
dG9rZW4iyAMKEUVuZFVzZXJBdXRoQ29uZmlnEnQKF29hdXRoMl9hdXRoX2NvZGVfY29uZmln
GAIgASgLMjsuZ29vZ2xlLmNsb3VkLmNlcy52MS5FbmRVc2VyQXV0aENvbmZpZy5PYXV0aDJB
dXRoQ29kZUNvbmZpZ0gAUhRvYXV0aDJBdXRoQ29kZUNvbmZpZxJ3ChhvYXV0aDJfand0X2Jl
YXJlcl9jb25maWcYAyABKAsyPC5nb29nbGUuY2xvdWQuY2VzLnYxLkVuZFVzZXJBdXRoQ29u
ZmlnLk9hdXRoMkp3dEJlYXJlckNvbmZpZ0gAUhVvYXV0aDJKd3RCZWFyZXJDb25maWcaPAoU
T2F1dGgyQXV0aENvZGVDb25maWcSJAoLb2F1dGhfdG9rZW4YASABKAlCA+BBAlIKb2F1dGhU
b2tlbhp3ChVPYXV0aDJKd3RCZWFyZXJDb25maWcSGwoGaXNzdWVyGAEgASgJQgPgQQJSBmlz
c3VlchIdCgdzdWJqZWN0GAIgASgJQgPgQQJSB3N1YmplY3QSIgoKY2xpZW50X2tleRgDIAEo
CUID4EECUgljbGllbnRLZXlCDQoLYXV0aF9jb25maWcimQQKEUFwaUF1dGhlbnRpY2F0aW9u
Ek4KDmFwaV9rZXlfY29uZmlnGAEgASgLMiEuZ29vZ2xlLmNsb3VkLmNlcy52MS5BcGlLZXlD
b25maWdCA+BBAUgAUgxhcGlLZXlDb25maWcSSgoMb2F1dGhfY29uZmlnGAIgASgLMiAuZ29v
Z2xlLmNsb3VkLmNlcy52MS5PQXV0aENvbmZpZ0ID4EEBSABSC29hdXRoQ29uZmlnEoQBCiJz
ZXJ2aWNlX2FnZW50X2lkX3Rva2VuX2F1dGhfY29uZmlnGAMgASgLMjIuZ29vZ2xlLmNsb3Vk
LmNlcy52MS5TZXJ2aWNlQWdlbnRJZFRva2VuQXV0aENvbmZpZ0ID4EEBSABSHXNlcnZpY2VB
Z2VudElkVG9rZW5BdXRoQ29uZmlnEnMKG3NlcnZpY2VfYWNjb3VudF9hdXRoX2NvbmZpZxgE
IAEoCzItLmdvb2dsZS5jbG91ZC5jZXMudjEuU2VydmljZUFjY291bnRBdXRoQ29uZmlnQgPg
QQFIAFIYc2VydmljZUFjY291bnRBdXRoQ29uZmlnEl0KE2JlYXJlcl90b2tlbl9jb25maWcY
BSABKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxLkJlYXJlclRva2VuQ29uZmlnQgPgQQFIAFIR
YmVhcmVyVG9rZW5Db25maWdCDQoLYXV0aF9jb25maWdCvwEKF2NvbS5nb29nbGUuY2xvdWQu
Y2VzLnYxQglBdXRoUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjEvY2Vz
cGI7Y2VzcGLqQWsKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lv
bhI9cHJvamVjdHMve3Byb2plY3R9L3NlY3JldHMve3NlY3JldH0vdmVyc2lvbnMve3NlY3Jl
dF92ZXJzaW9ufUq+NwoHEgUOAMIBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
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
ZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQBACgkKAggLEgMV
AEAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAqCgkKAggIEgMXACoKCAoBCBIDGAAw
CgkKAggBEgMYADAKCQoBCBIEGQAcAgoMCgQInQgAEgQZABwCCj0KAgQAEgQfAEABGjEgQ29u
ZmlndXJhdGlvbnMgZm9yIGF1dGhlbnRpY2F0aW9uIHdpdGggQVBJIGtleS4KCgoKAwQAARID
HwgUCjsKBAQABAASBCECKgMaLSBUaGUgbG9jYXRpb24gb2YgdGhlIEFQSSBrZXkgaW4gdGhl
IHJlcXVlc3QuCgoMCgUEAAQAARIDIQcWCjwKBgQABAACABIDIwQlGi0gVW5zcGVjaWZpZWQu
IFRoaXMgdmFsdWUgc2hvdWxkIG5vdCBiZSB1c2VkLgoKDgoHBAAEAAIAARIDIwQgCg4KBwQA
BAACAAISAyMjJAozCgYEAAQAAgESAyYEDxokIFJlcHJlc2VudHMgdGhlIGtleSBpbiBodHRw
IGhlYWRlci4KCg4KBwQABAACAQESAyYECgoOCgcEAAQAAgECEgMmDQ4KNAoGBAAEAAICEgMp
BBUaJSBSZXByZXNlbnRzIHRoZSBrZXkgaW4gcXVlcnkgc3RyaW5nLgoKDgoHBAAEAAICARID
KQQQCg4KBwQABAACAgISAykTFArFAQoEBAACABIDLwI/GrcBIFJlcXVpcmVkLiBUaGUgcGFy
YW1ldGVyIG5hbWUgb3IgdGhlIGhlYWRlciBuYW1lIG9mIHRoZSBBUEkga2V5LgogRS5nLiwg
SWYgdGhlIEFQSSByZXF1ZXN0IGlzICJodHRwczovL2V4YW1wbGUuY29tL2FjdD9YLUFwaS1L
ZXk9PEFQSQogS0VZPiIsICJYLUFwaS1LZXkiIHdvdWxkIGJlIHRoZSBwYXJhbWV0ZXIgbmFt
ZS4KCgwKBQQAAgAFEgMvAggKDAoFBAACAAESAy8JEQoMCgUEAAIAAxIDLxQVCgwKBQQAAgAI
EgMvFj4KDwoIBAACAAicCAASAy8XPQrEAgoEBAACARIENwI8BBq1AiBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIFNlY3JldE1hbmFnZXIgc2VjcmV0IHZlcnNpb24gcmVzb3VyY2Ugc3Rv
cmluZyB0aGUKIEFQSSBrZXkuIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9zZWNyZXRz
L3tzZWNyZXR9L3ZlcnNpb25zL3t2ZXJzaW9ufWAKCiBOb3RlOiBZb3Ugc2hvdWxkIGdyYW50
IGByb2xlcy9zZWNyZXRtYW5hZ2VyLnNlY3JldEFjY2Vzc29yYCByb2xlIHRvIHRoZSBDRVMK
IHNlcnZpY2UgYWdlbnQKIGBzZXJ2aWNlLTxQUk9KRUNULU5VTUJFUj5AZ2NwLXNhLWNlcy5p
YW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgoMCgUEAAIBBRIDNwIICgwKBQQAAgEBEgM3CR8K
DAoFBAACAQMSAzciIwoNCgUEAAIBCBIENyQ8AwoPCggEAAIBCJwIABIDOAQqCg8KBwQAAgEI
nwgSBDkEOwUKNQoEBAACAhIDPwJQGiggUmVxdWlyZWQuIEtleSBsb2NhdGlvbiBpbiB0aGUg
cmVxdWVzdC4KCgwKBQQAAgIGEgM/AhEKDAoFBAACAgESAz8SIgoMCgUEAAICAxIDPyUmCgwK
BQQAAgIIEgM/J08KDwoIBAACAgicCAASAz8oTgo7CgIEARIEQwBpARovIENvbmZpZ3VyYXRp
b25zIGZvciBhdXRoZW50aWNhdGlvbiB3aXRoIE9BdXRoLgoKCgoDBAEBEgNDCBMKhAEKBAQB
BAASBEYCTQMadiBPQXV0aCBncmFudCB0eXBlcy4gT25seSBbY2xpZW50IGNyZWRlbnRpYWwK
IGdyYW50XShodHRwczovL29hdXRoLm5ldC8yL2dyYW50LXR5cGVzL2NsaWVudC1jcmVkZW50
aWFscykgaXMgc3VwcG9ydGVkLgoKDAoFBAEEAAESA0YHFQo8CgYEAQQAAgASA0gEJRotIFVu
c3BlY2lmaWVkLiBEZWZhdWx0cyB0byBDTElFTlRfQ1JFREVOVElBTC4KCg4KBwQBBAACAAES
A0gEIAoOCgcEAQQAAgACEgNIIyQKbgoGBAEEAAIBEgNMBBoaXyBSZXByZXNlbnRzIHRoZSBb
Y2xpZW50IGNyZWRlbnRpYWwKIGZsb3ddKGh0dHBzOi8vb2F1dGgubmV0LzIvZ3JhbnQtdHlw
ZXMvY2xpZW50LWNyZWRlbnRpYWxzKS4KCg4KBwQBBAACAQESA0wEFQoOCgcEAQQAAgECEgNM
GBkKKwoEBAECABIDUAJPGh4gUmVxdWlyZWQuIE9BdXRoIGdyYW50IHR5cGVzLgoKDAoFBAEC
AAYSA1ACEAoMCgUEAQIAARIDUBEhCgwKBQQBAgADEgNQJCUKDAoFBAECAAgSA1AmTgoPCggE
AQIACJwIABIDUCdNCj8KBAQBAgESA1MCQBoyIFJlcXVpcmVkLiBUaGUgY2xpZW50IElEIGZy
b20gdGhlIE9BdXRoIHByb3ZpZGVyLgoKDAoFBAECAQUSA1MCCAoMCgUEAQIBARIDUwkSCgwK
BQQBAgEDEgNTFRYKDAoFBAECAQgSA1MXPwoPCggEAQIBCJwIABIDUxg+CssCCgQEAQICEgRc
AmEEGrwCIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgU2VjcmV0TWFuYWdlciBzZWNyZXQg
dmVyc2lvbiByZXNvdXJjZSBzdG9yaW5nIHRoZQogY2xpZW50IHNlY3JldC4KIEZvcm1hdDog
YHByb2plY3RzL3twcm9qZWN0fS9zZWNyZXRzL3tzZWNyZXR9L3ZlcnNpb25zL3t2ZXJzaW9u
fWAKCiBOb3RlOiBZb3Ugc2hvdWxkIGdyYW50IGByb2xlcy9zZWNyZXRtYW5hZ2VyLnNlY3Jl
dEFjY2Vzc29yYCByb2xlIHRvIHRoZSBDRVMKIHNlcnZpY2UgYWdlbnQKIGBzZXJ2aWNlLTxQ
Uk9KRUNULU5VTUJFUj5AZ2NwLXNhLWNlcy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgoM
CgUEAQICBRIDXAIICgwKBQQBAgIBEgNcCR4KDAoFBAECAgMSA1whIgoNCgUEAQICCBIEXCNh
AwoPCggEAQICCJwIABIDXQQqCg8KBwQBAgIInwgSBF4EYAUKYwoEBAECAxIDZQJFGlYgUmVx
dWlyZWQuIFRoZSB0b2tlbiBlbmRwb2ludCBpbiB0aGUgT0F1dGggcHJvdmlkZXIgdG8gZXhj
aGFuZ2UgZm9yIGFuCiBhY2Nlc3MgdG9rZW4uCgoMCgUEAQIDBRIDZQIICgwKBQQBAgMBEgNl
CRcKDAoFBAECAwMSA2UaGwoMCgUEAQIDCBIDZRxECg8KCAQBAgMInAgAEgNlHUMKMwoEBAEC
BBIDaAJGGiYgT3B0aW9uYWwuIFRoZSBPQXV0aCBzY29wZXMgdG8gZ3JhbnQuCgoMCgUEAQIE
BBIDaAIKCgwKBQQBAgQFEgNoCxEKDAoFBAECBAESA2gSGAoMCgUEAQIEAxIDaBscCgwKBQQB
AgQIEgNoHUUKDwoIBAECBAicCAASA2geRAqcAQoCBAISA24AKBqQASBDb25maWd1cmF0aW9u
cyBmb3IgYXV0aGVudGljYXRpb24gd2l0aCBbSUQKIHRva2VuXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vZG9jcy9hdXRoZW50aWNhdGlvbi90b2tlbi10eXBlcyNpZCkgZ2VuZXJhdGVk
CiBmcm9tIHNlcnZpY2UgYWdlbnQuCgoKCgMEAgESA24IJQpPCgIEAxIEcQB/ARpDIENvbmZp
Z3VyYXRpb25zIGZvciBhdXRoZW50aWNhdGlvbiB1c2luZyBhIGN1c3RvbSBzZXJ2aWNlIGFj
Y291bnQuCgoKCgMEAwESA3EIIAqaAwoEBAMCABIDegJGGowDIFJlcXVpcmVkLiBUaGUgZW1h
aWwgYWRkcmVzcyBvZiB0aGUgc2VydmljZSBhY2NvdW50IHVzZWQgZm9yIGF1dGhlbnRpY2F0
aW9uLgogQ0VTIHVzZXMgdGhpcyBzZXJ2aWNlIGFjY291bnQgdG8gZXhjaGFuZ2UgYW4gYWNj
ZXNzIHRva2VuIGFuZCB0aGUgYWNjZXNzCiB0b2tlbiBpcyB0aGVuIHNlbnQgaW4gdGhlIGBB
dXRob3JpemF0aW9uYCBoZWFkZXIgb2YgdGhlIHJlcXVlc3QuCgogVGhlIHNlcnZpY2UgYWNj
b3VudCBtdXN0IGhhdmUgdGhlCiBgcm9sZXMvaWFtLnNlcnZpY2VBY2NvdW50VG9rZW5DcmVh
dG9yYCByb2xlIGdyYW50ZWQgdG8gdGhlCiBDRVMgc2VydmljZSBhZ2VudAogYHNlcnZpY2Ut
PFBST0pFQ1QtTlVNQkVSPkBnY3Atc2EtY2VzLmlhbS5nc2VydmljZWFjY291bnQuY29tYC4K
CgwKBQQDAgAFEgN6AggKDAoFBAMCAAESA3oJGAoMCgUEAwIAAxIDehscCgwKBQQDAgAIEgN6
HUUKDwoIBAMCAAicCAASA3oeRAqTAQoEBAMCARIDfgJGGoUBIE9wdGlvbmFsLiBUaGUgT0F1
dGggc2NvcGVzIHRvIGdyYW50LiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgZGVmYXVsdCBzY29w
ZQogYGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1gIGlz
IHVzZWQuCgoMCgUEAwIBBBIDfgIKCgwKBQQDAgEFEgN+CxEKDAoFBAMCAQESA34SGAoMCgUE
AwIBAxIDfhscCgwKBQQDAgEIEgN+HUUKDwoIBAMCAQicCAASA34eRApGCgIEBBIGggEAhgEB
GjggQ29uZmlndXJhdGlvbnMgZm9yIGF1dGhlbnRpY2F0aW9uIHdpdGggYSBiZWFyZXIgdG9r
ZW4uCgoLCgMEBAESBIIBCBkKawoEBAQCABIEhQECPBpdIFJlcXVpcmVkLiBUaGUgYmVhcmVy
IHRva2VuLgogTXVzdCBiZSBpbiB0aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5h
bWVfb2ZfdmFyaWFibGU+YC4KCg0KBQQEAgAFEgSFAQIICg0KBQQEAgABEgSFAQkOCg0KBQQE
AgADEgSFARESCg0KBQQEAgAIEgSFARM7ChAKCAQEAgAInAgAEgSFARQ6CsIBCgIEBRIGiwEA
qgEBGrMBIEVuZC11c2VyIGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24gdXNlZCBmb3Ig
Q29ubmVjdGlvbiBjYWxscy4KIFRoZSBmaWVsZCB2YWx1ZXMgbXVzdCBiZSB0aGUgbmFtZXMg
b2YgY29udGV4dCB2YXJpYWJsZXMgaW4gdGhlIGZvcm1hdAogYCRjb250ZXh0LnZhcmlhYmxl
cy48bmFtZV9vZl92YXJpYWJsZT5gLgoKCwoDBAUBEgSLAQgZCkwKBAQFAwASBo0BApEBAxo8
IE9hdXRoIDIuMCBBdXRob3JpemF0aW9uIENvZGUgYXV0aGVudGljYXRpb24gY29uZmlndXJh
dGlvbi4KCg0KBQQFAwABEgSNAQoeCocBCgYEBQMAAgASBJABBEQadyBSZXF1aXJlZC4gT2F1
dGggdG9rZW4gcGFyYW1ldGVyIG5hbWUgdG8gcGFzcyB0aHJvdWdoLgogTXVzdCBiZSBpbiB0
aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5hbWVfb2ZfdmFyaWFibGU+YC4KCg8K
BwQFAwACAAUSBJABBAoKDwoHBAUDAAIAARIEkAELFgoPCgcEBQMAAgADEgSQARkaCg8KBwQF
AwACAAgSBJABG0MKEgoKBAUDAAIACJwIABIEkAEcQgpZCgQEBQMBEgaUAQKgAQMaSSBKV1Qg
UHJvZmlsZSBPYXV0aCAyLjAgQXV0aG9yaXphdGlvbiBHcmFudCBhdXRoZW50aWNhdGlvbiBj
b25maWd1cmF0aW9uLgoKDQoFBAUDAQESBJQBCh8KggEKBgQFAwECABIElwEEPxpyIFJlcXVp
cmVkLiBJc3N1ZXIgcGFyYW1ldGVyIG5hbWUgdG8gcGFzcyB0aHJvdWdoLgogTXVzdCBiZSBp
biB0aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5hbWVfb2ZfdmFyaWFibGU+YC4K
Cg8KBwQFAwECAAUSBJcBBAoKDwoHBAUDAQIAARIElwELEQoPCgcEBQMBAgADEgSXARQVCg8K
BwQFAwECAAgSBJcBFj4KEgoKBAUDAQIACJwIABIElwEXPQqDAQoGBAUDAQIBEgSbAQRAGnMg
UmVxdWlyZWQuIFN1YmplY3QgcGFyYW1ldGVyIG5hbWUgdG8gcGFzcyB0aHJvdWdoLgogTXVz
dCBiZSBpbiB0aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5hbWVfb2ZfdmFyaWFi
bGU+YC4KCg8KBwQFAwECAQUSBJsBBAoKDwoHBAUDAQIBARIEmwELEgoPCgcEBQMBAgEDEgSb
ARUWCg8KBwQFAwECAQgSBJsBFz8KEgoKBAUDAQIBCJwIABIEmwEYPgqCAQoGBAUDAQICEgSf
AQRDGnIgUmVxdWlyZWQuIENsaWVudCBwYXJhbWV0ZXIgbmFtZSB0byBwYXNzIHRocm91Z2gu
CiBNdXN0IGJlIGluIHRoZSBmb3JtYXQgYCRjb250ZXh0LnZhcmlhYmxlcy48bmFtZV9vZl92
YXJpYWJsZT5gLgoKDwoHBAUDAQICBRIEnwEECgoPCgcEBQMBAgIBEgSfAQsVCg8KBwQFAwEC
AgMSBJ8BGBkKDwoHBAUDAQICCBIEnwEaQgoSCgoEBQMBAgIInAgAEgSfARtBCikKBAQFCAAS
BqMBAqkBAxoZIFRoZSBhdXRoIGNvbmZpZ3VyYXRpb24uCgoNCgUEBQgAARIEowEIEwo8CgQE
BQIAEgSlAQQ1Gi4gT2F1dGggMi4wIEF1dGhvcml6YXRpb24gQ29kZSBhdXRoZW50aWNhdGlv
bi4KCg0KBQQFAgAGEgSlAQQYCg0KBQQFAgABEgSlARkwCg0KBQQFAgADEgSlATM0CkkKBAQF
AgESBKgBBDcaOyBKV1QgUHJvZmlsZSBPYXV0aCAyLjAgQXV0aG9yaXphdGlvbiBHcmFudCBh
dXRoZW50aWNhdGlvbi4KCg0KBQQFAgEGEgSoAQQZCg0KBQQFAgEBEgSoARoyCg0KBQQFAgED
EgSoATU2CkIKAgQGEgatAQDCAQEaNCBBdXRoZW50aWNhdGlvbiBpbmZvcm1hdGlvbiByZXF1
aXJlZCBmb3IgQVBJIGNhbGxzLgoKCwoDBAYBEgStAQgZCikKBAQGCAASBq8BAsEBAxoZIFRo
ZSBhdXRoIGNvbmZpZ3VyYXRpb24uCgoNCgUEBggAARIErwEIEwoyCgQEBgIAEgSxAQRNGiQg
T3B0aW9uYWwuIENvbmZpZyBmb3IgQVBJIGtleSBhdXRoLgoKDQoFBAYCAAYSBLEBBBAKDQoF
BAYCAAESBLEBER8KDQoFBAYCAAMSBLEBIiMKDQoFBAYCAAgSBLEBJEwKEAoIBAYCAAicCAAS
BLEBJUsKKwoEBAYCARIEtAEEShodIE9wdGlvbmFsLiBDb25maWcgZm9yIE9BdXRoLgoKDQoF
BAYCAQYSBLQBBA8KDQoFBAYCAQESBLQBEBwKDQoFBAYCAQMSBLQBHyAKDQoFBAYCAQgSBLQB
IUkKEAoIBAYCAQicCAASBLQBIkgKVgoEBAYCAhIGtwEEuAExGkYgT3B0aW9uYWwuIENvbmZp
ZyBmb3IgSUQgdG9rZW4gYXV0aCBnZW5lcmF0ZWQgZnJvbSBDRVMgc2VydmljZSBhZ2VudC4K
Cg0KBQQGAgIGEgS3AQQhCg0KBQQGAgIBEgS3ASJECg0KBQQGAgIDEgS3AUdICg0KBQQGAgII
EgS4AQgwChAKCAQGAgIInAgAEgS4AQkvCkYKBAQGAgMSBrsBBLwBMRo2IE9wdGlvbmFsLiBD
b25maWcgZm9yIHNlcnZpY2UgYWNjb3VudCBhdXRoZW50aWNhdGlvbi4KCg0KBQQGAgMGEgS7
AQQcCg0KBQQGAgMBEgS7AR04Cg0KBQQGAgMDEgS7ATs8Cg0KBQQGAgMIEgS8AQgwChAKCAQG
AgMInAgAEgS8AQkvCjkKBAQGAgQSBr8BBMABMRopIE9wdGlvbmFsLiBDb25maWcgZm9yIGJl
YXJlciB0b2tlbiBhdXRoLgoKDQoFBAYCBAYSBL8BBBUKDQoFBAYCBAESBL8BFikKDQoFBAYC
BAMSBL8BLC0KDQoFBAYCBAgSBMABCDAKEAoIBAYCBAicCAASBMABCS9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Auth::ApiKeyConfig ===
    # Fields for ApiKeyConfig
    # Field: key_name Type: 9 ()
    # Field: api_key_secret_version Type: 9 ()
    # Field: request_location Type: 14 (.google.cloud.ces.v1.ApiKeyConfig.RequestLocation)

# Enum: ApiKeyConfig::RequestLocation
our $ApiKeyConfig_REQUEST_LOCATION_UNSPECIFIED = 0;
our $ApiKeyConfig_HEADER = 1;
our $ApiKeyConfig_QUERY_STRING = 2;

# === Message: Google::Cloud::Ces::V1::Auth::OAuthConfig ===
    # Fields for OAuthConfig
    # Field: oauth_grant_type Type: 14 (.google.cloud.ces.v1.OAuthConfig.OauthGrantType)
    # Field: client_id Type: 9 ()
    # Field: client_secret_version Type: 9 ()
    # Field: token_endpoint Type: 9 ()
    # Field: scopes Type: 9 ()

# Enum: OAuthConfig::OauthGrantType
our $OAuthConfig_OAUTH_GRANT_TYPE_UNSPECIFIED = 0;
our $OAuthConfig_CLIENT_CREDENTIAL = 1;

# === Message: Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig ===
    # Fields for ServiceAgentIdTokenAuthConfig

# === Message: Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig ===
    # Fields for ServiceAccountAuthConfig
    # Field: service_account Type: 9 ()
    # Field: scopes Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Auth::BearerTokenConfig ===
    # Fields for BearerTokenConfig
    # Field: token Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Auth::EndUserAuthConfig ===
    # Fields for EndUserAuthConfig
    # Field: oauth2_auth_code_config Type: 11 (.google.cloud.ces.v1.EndUserAuthConfig.Oauth2AuthCodeConfig)
    # Field: oauth2_jwt_bearer_config Type: 11 (.google.cloud.ces.v1.EndUserAuthConfig.Oauth2JwtBearerConfig)

# === Message: Google::Cloud::Ces::V1::Auth::ApiAuthentication ===
    # Fields for ApiAuthentication
    # Field: api_key_config Type: 11 (.google.cloud.ces.v1.ApiKeyConfig)
    # Field: oauth_config Type: 11 (.google.cloud.ces.v1.OAuthConfig)
    # Field: service_agent_id_token_auth_config Type: 11 (.google.cloud.ces.v1.ServiceAgentIdTokenAuthConfig)
    # Field: service_account_auth_config Type: 11 (.google.cloud.ces.v1.ServiceAccountAuthConfig)
    # Field: bearer_token_config Type: 11 (.google.cloud.ces.v1.BearerTokenConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Auth - Compiled Protocol Buffers messages for google/cloud/ces/v1/auth.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Auth;

    my $msg = Google::Cloud::Ces::V1::Auth::ApiKeyConfig->new({
        key_name => $key_name,
        api_key_secret_version => $api_key_secret_version,
        request_location => $request_location,
    });

    # Read or update a field
    my $val = $msg->key_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Auth::ApiKeyConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/auth.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Auth::ApiKeyConfig

Configurations for authentication with API key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key_name() >> / C<< $msg->key_name($value) >>

Type: C<String>

Required. The parameter name or the header name of the API key.
E.g., If the API request is "https://example.com/act?X-Api-Key=<API
KEY>", "X-Api-Key" would be the parameter name.

=item * C<< $msg->api_key_secret_version() >> / C<< $msg->api_key_secret_version($value) >>

Type: C<String>

Required. The name of the SecretManager secret version resource storing the
API key. Format: `projects/{project}/secrets/{secret}/versions/{version}`

Note: You should grant `roles/secretmanager.secretAccessor` role to the CES
service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->request_location() >> / C<< $msg->request_location($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::ApiKeyConfig::RequestLocation>)

Required. Key location in the request.

=back

=head3 Enum: ApiKeyConfig::RequestLocation

=over 4

=item * C<REQUEST_LOCATION_UNSPECIFIED> => C<0>

=item * C<HEADER> => C<1>

=item * C<QUERY_STRING> => C<2>

=back

=head2 Google::Cloud::Ces::V1::Auth::OAuthConfig

Configurations for authentication with OAuth.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth_grant_type() >> / C<< $msg->oauth_grant_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::OAuthConfig::OauthGrantType>)

Required. OAuth grant types.

=item * C<< $msg->client_id() >> / C<< $msg->client_id($value) >>

Type: C<String>

Required. The client ID from the OAuth provider.

=item * C<< $msg->client_secret_version() >> / C<< $msg->client_secret_version($value) >>

Type: C<String>

Required. The name of the SecretManager secret version resource storing the
client secret.
Format: `projects/{project}/secrets/{secret}/versions/{version}`

Note: You should grant `roles/secretmanager.secretAccessor` role to the CES
service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->token_endpoint() >> / C<< $msg->token_endpoint($value) >>

Type: C<String>

Required. The token endpoint in the OAuth provider to exchange for an
access token.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Optional. The OAuth scopes to grant.

=back

=head3 Enum: OAuthConfig::OauthGrantType

=over 4

=item * C<OAUTH_GRANT_TYPE_UNSPECIFIED> => C<0>

=item * C<CLIENT_CREDENTIAL> => C<1>

=back

=head2 Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig

Configurations for authentication with [ID
token](https://cloud.google.com/docs/authentication/token-types#id) generated
from service agent.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig

Configurations for authentication using a custom service account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Required. The email address of the service account used for authentication.
CES uses this service account to exchange an access token and the access
token is then sent in the `Authorization` header of the request.

The service account must have the
`roles/iam.serviceAccountTokenCreator` role granted to the
CES service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Optional. The OAuth scopes to grant. If not specified, the default scope
`https://www.googleapis.com/auth/cloud-platform` is used.

=back

=head2 Google::Cloud::Ces::V1::Auth::BearerTokenConfig

Configurations for authentication with a bearer token.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<String>

Required. The bearer token.
Must be in the format `$context.variables.<name_of_variable>`.

=back

=head2 Google::Cloud::Ces::V1::Auth::EndUserAuthConfig

End-user authentication configuration used for Connection calls.
The field values must be the names of context variables in the format
`$context.variables.<name_of_variable>`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth2_auth_code_config() >> / C<< $msg->oauth2_auth_code_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2AuthCodeConfig>)

Oauth 2.0 Authorization Code authentication.

=item * C<< $msg->oauth2_jwt_bearer_config() >> / C<< $msg->oauth2_jwt_bearer_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2JwtBearerConfig>)

JWT Profile Oauth 2.0 Authorization Grant authentication.

=back

=head2 Google::Cloud::Ces::V1::Auth::ApiAuthentication

Authentication information required for API calls.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_key_config() >> / C<< $msg->api_key_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiKeyConfig>)

Optional. Config for API key auth.

=item * C<< $msg->oauth_config() >> / C<< $msg->oauth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::OAuthConfig>)

Optional. Config for OAuth.

=item * C<< $msg->service_agent_id_token_auth_config() >> / C<< $msg->service_agent_id_token_auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig>)

Optional. Config for ID token auth generated from CES service agent.

=item * C<< $msg->service_account_auth_config() >> / C<< $msg->service_account_auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig>)

Optional. Config for service account authentication.

=item * C<< $msg->bearer_token_config() >> / C<< $msg->bearer_token_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::BearerTokenConfig>)

Optional. Config for bearer token auth.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Auth::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
