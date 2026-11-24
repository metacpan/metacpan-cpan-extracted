package Google::Chromeos::Uidetection::V1::UiDetection;

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
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2hyb21lb3MvdWlkZXRlY3Rpb24vdjEvdWlfZGV0ZWN0aW9uLnByb3RvEh5n
b29nbGUuY2hyb21lb3MudWlkZXRlY3Rpb24udjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvIqsDChJVaURldGVjdGlvblJlcXVlc3QSIAoJaW1hZ2VfcG5nGAEgASgMQgPg
QQJSCGltYWdlUG5nEk8KB3JlcXVlc3QYAiABKAsyMC5nb29nbGUuY2hyb21lb3MudWlkZXRl
Y3Rpb24udjEuRGV0ZWN0aW9uUmVxdWVzdEID4EECUgdyZXF1ZXN0EiYKDHJlc2l6ZV9pbWFn
ZRgDIAEoCEgAUgtyZXNpemVJbWFnZYgBARIbCgd0ZXN0X2lkGAQgASgJQgIYAVIGdGVzdElk
ElYKDXRlc3RfbWV0YWRhdGEYBSABKAsyLC5nb29nbGUuY2hyb21lb3MudWlkZXRlY3Rpb24u
djEuVGVzdE1ldGFkYXRhQgPgQQFSDHRlc3RNZXRhZGF0YRI1ChRmb3JjZV9pbWFnZV9yZXNp
emluZxgGIAEoCEID4EEBUhJmb3JjZUltYWdlUmVzaXppbmcSPQoYcmV0dXJuX3RyYW5zZm9y
bWVkX2ltYWdlGAcgASgIQgPgQQFSFnJldHVyblRyYW5zZm9ybWVkSW1hZ2VCDwoNX3Jlc2l6
ZV9pbWFnZSKZAwoQRGV0ZWN0aW9uUmVxdWVzdBJsChZ3b3JkX2RldGVjdGlvbl9yZXF1ZXN0
GAEgASgLMjQuZ29vZ2xlLmNocm9tZW9zLnVpZGV0ZWN0aW9uLnYxLldvcmREZXRlY3Rpb25S
ZXF1ZXN0SABSFHdvcmREZXRlY3Rpb25SZXF1ZXN0EnwKHHRleHRfYmxvY2tfZGV0ZWN0aW9u
X3JlcXVlc3QYAiABKAsyOS5nb29nbGUuY2hyb21lb3MudWlkZXRlY3Rpb24udjEuVGV4dEJs
b2NrRGV0ZWN0aW9uUmVxdWVzdEgAUhl0ZXh0QmxvY2tEZXRlY3Rpb25SZXF1ZXN0En8KHWN1
c3RvbV9pY29uX2RldGVjdGlvbl9yZXF1ZXN0GAMgASgLMjouZ29vZ2xlLmNocm9tZW9zLnVp
ZGV0ZWN0aW9uLnYxLkN1c3RvbUljb25EZXRlY3Rpb25SZXF1ZXN0SABSGmN1c3RvbUljb25E
ZXRlY3Rpb25SZXF1ZXN0QhgKFmRldGVjdGlvbl9yZXF1ZXN0X3R5cGUicgoMVGVzdE1ldGFk
YXRhEhcKB3Rlc3RfaWQYASABKAlSBnRlc3RJZBIUCgVib2FyZBgCIAEoCVIFYm9hcmQSFAoF
bW9kZWwYAyABKAlSBW1vZGVsEh0KCmNyb3NfYnVpbGQYBCABKAlSCWNyb3NCdWlsZCLHAQoU
V29yZERldGVjdGlvblJlcXVlc3QSFwoEd29yZBgBIAEoCUID4EECUgR3b3JkEh0KCnJlZ2V4
X21vZGUYAiABKAhSCXJlZ2V4TW9kZRIwChRkaXNhYmxlX2FwcHJveF9tYXRjaBgDIAEoCFIS
ZGlzYWJsZUFwcHJveE1hdGNoEi8KEW1heF9lZGl0X2Rpc3RhbmNlGAQgASgFSABSD21heEVk
aXREaXN0YW5jZYgBAUIUChJfbWF4X2VkaXRfZGlzdGFuY2UigAIKGVRleHRCbG9ja0RldGVj
dGlvblJlcXVlc3QSGQoFd29yZHMYASADKAlCA+BBAlIFd29yZHMSHQoKcmVnZXhfbW9kZRgC
IAEoCFIJcmVnZXhNb2RlEjAKFGRpc2FibGVfYXBwcm94X21hdGNoGAMgASgIUhJkaXNhYmxl
QXBwcm94TWF0Y2gSLwoRbWF4X2VkaXRfZGlzdGFuY2UYBCABKAVIAFIPbWF4RWRpdERpc3Rh
bmNliAEBEjAKFHNwZWNpZmllZF93b3Jkc19vbmx5GAUgASgIUhJzcGVjaWZpZWRXb3Jkc09u
bHlCFAoSX21heF9lZGl0X2Rpc3RhbmNlIpcBChpDdXN0b21JY29uRGV0ZWN0aW9uUmVxdWVz
dBIeCghpY29uX3BuZxgBIAEoDEID4EECUgdpY29uUG5nEh8KC21hdGNoX2NvdW50GAIgASgF
UgptYXRjaENvdW50EjgKGG1pbl9jb25maWRlbmNlX3RocmVzaG9sZBgDIAEoAVIWbWluQ29u
ZmlkZW5jZVRocmVzaG9sZCLRAQoTVWlEZXRlY3Rpb25SZXNwb25zZRJSCg5ib3VuZGluZ19i
b3hlcxgBIAMoCzIrLmdvb2dsZS5jaHJvbWVvcy51aWRldGVjdGlvbi52MS5Cb3VuZGluZ0Jv
eFINYm91bmRpbmdCb3hlcxIyChV0cmFuc2Zvcm1lZF9pbWFnZV9wbmcYAiABKAxSE3RyYW5z
Zm9ybWVkSW1hZ2VQbmcSMgoVcmVzaXppbmdfc2NhbGVfZmFjdG9yGAMgASgCUhNyZXNpemlu
Z1NjYWxlRmFjdG9yInUKC0JvdW5kaW5nQm94EhIKBHRleHQYASABKAlSBHRleHQSEAoDdG9w
GAIgASgFUgN0b3ASEgoEbGVmdBgDIAEoBVIEbGVmdBIWCgZib3R0b20YBCABKAVSBmJvdHRv
bRIUCgVyaWdodBgFIAEoBVIFcmlnaHQy3wEKElVpRGV0ZWN0aW9uU2VydmljZRKhAQoQRXhl
Y3V0ZURldGVjdGlvbhIyLmdvb2dsZS5jaHJvbWVvcy51aWRldGVjdGlvbi52MS5VaURldGVj
dGlvblJlcXVlc3QaMy5nb29nbGUuY2hyb21lb3MudWlkZXRlY3Rpb24udjEuVWlEZXRlY3Rp
b25SZXNwb25zZSIkgtPkkwIeEhwvdjEvZXhlY3V0ZURldGVjdGlvbjpleGVjdXRlGiXKQSJj
aHJvbWVvc3VpZGV0ZWN0aW9uLmdvb2dsZWFwaXMuY29tQoMBCiJjb20uZ29vZ2xlLmNocm9t
ZW9zLnVpZGV0ZWN0aW9uLnYxQhBVaURldGVjdGlvblByb3RvUAFaSWdvb2dsZS5nb2xhbmcu
b3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvY2hyb21lb3MvdWlkZXRlY3Rpb24vdjE7dWlkZXRl
Y3Rpb25K7S8KBxIFDgCvAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACcKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCAoBCBIDFgBgCgkK
AggLEgMWAGAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAxCgkKAggIEgMYADEKCAoB
CBIDGQA7CgkKAggBEgMZADsKOAoCBgASBBwAJQEaLCBQcm92aWRlcyBpbWFnZS1iYXNlZCBV
SSBkZXRlY3Rpb24gc2VydmljZS4KCgoKAwYAARIDHAgaCgoKAwYAAxIDHQJKCgwKBQYAA5kI
EgMdAkoKIwoEBgACABIEIAIkAxoVIFJ1bnMgdGhlIGRldGVjdGlvbi4KCgwKBQYAAgABEgMg
BhYKDAoFBgACAAISAyAXKQoMCgUGAAIAAxIDIDRHCg0KBQYAAgAEEgQhBCMGChEKCQYAAgAE
sMq8IhIEIQQjBgovCgIEABIEKAA+ARojIFJlcXVlc3QgbWVzc2FnZSBmb3IgVUkgZGV0ZWN0
aW9uLgoKCgoDBAABEgMoCBoKRAoEBAACABIDKgI/GjcgUmVxdWlyZWQuIFJlcXVpcmVkIGZp
ZWxkIHRoYXQgcmVwcmVzZW50cyBhIFBORyBpbWFnZS4KCgwKBQQAAgAFEgMqAgcKDAoFBAAC
AAESAyoIEQoMCgUEAAIAAxIDKhQVCgwKBQQAAgAIEgMqFj4KDwoIBAACAAicCAASAyoXPQpK
CgQEAAIBEgMtAkgaPSBSZXF1aXJlZC4gUmVxdWlyZWQgZmllbGQgdGhhdCBpbmRpY2F0ZXMg
dGhlIGRldGVjdGlvbiB0eXBlLgoKDAoFBAACAQYSAy0CEgoMCgUEAAIBARIDLRMaCgwKBQQA
AgEDEgMtHR4KDAoFBAACAQgSAy0fRwoPCggEAAIBCJwIABIDLSBGCmEKBAQAAgISAzECIRpU
IEluZGljYXRlcyB3aGV0aGVyIHRvIGZhbGwgYmFjayB0byByZXNpemluZyB0aGUgaW1hZ2Ug
aWYgbm8gZWxlbWVudHMgYXJlCiBkZXRlY3RlZC4KCgwKBQQAAgIEEgMxAgoKDAoFBAACAgUS
AzELDwoMCgUEAAICARIDMRAcCgwKBQQAAgIDEgMxHyAKRgoEBAACAxIDNAIpGjkgRGVwcmVj
YXRlZCBhcyBvZiAyMDIzLTAzLTI5LiBVc2UgdGVzdF9tZXRhZGF0YSBpbnN0ZWFkLgoKDAoF
BAACAwUSAzQCCAoMCgUEAAIDARIDNAkQCgwKBQQAAgMDEgM0ExQKDAoFBAACAwgSAzQVKAoN
CgYEAAIDCAMSAzQWJwpBCgQEAAIEEgM3AkoaNCBPcHRpb25hbC4gTWV0YWRhdGEgYWJvdXQg
dGhlIGNsaWVudCBmb3IgYW5hbHl0aWNzLgoKDAoFBAACBAYSAzcCDgoMCgUEAAIEARIDNw8c
CgwKBQQAAgQDEgM3HyAKDAoFBAACBAgSAzchSQoPCggEAAIECJwIABIDNyJIClEKBAQAAgUS
AzoCSRpEIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0byBhbHdheXMgc3RhcnQgYnkg
cmVzaXppbmcgdGhlIGltYWdlLgoKDAoFBAACBQUSAzoCBgoMCgUEAAIFARIDOgcbCgwKBQQA
AgUDEgM6Hh8KDAoFBAACBQgSAzogSAoPCggEAAIFCJwIABIDOiFHClUKBAQAAgYSAz0CTRpI
IE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0byByZXNwb25kIHdpdGggdGhlIHRyYW5z
Zm9ybWVkIGltYWdlIHBuZy4KCgwKBQQAAgYFEgM9AgYKDAoFBAACBgESAz0HHwoMCgUEAAIG
AxIDPSIjCgwKBQQAAgYIEgM9JEwKDwoIBAACBgicCAASAz0lSwpDCgIEARIEQQBMARo3IERl
dGVjdGlvbiB0eXBlIHNwZWNpZmllcyB3aGF0IHRvIGRldGVjdCBpbiB0aGUgaW1hZ2UuCgoK
CgMEAQESA0EIGAoMCgQEAQgAEgRCAksDCgwKBQQBCAABEgNCCB4KMQoEBAECABIDRAQ0GiQg
RGV0ZWN0aW9uIHR5cGUgZm9yIHdvcmQgZGV0ZWN0aW9uLgoKDAoFBAECAAYSA0QEGAoMCgUE
AQIAARIDRBkvCgwKBQQBAgADEgNEMjMKNwoEBAECARIDRwQ/GiogRGV0ZWN0aW9uIHR5cGUg
Zm9yIHRleHQgYmxvY2sgZGV0ZWN0aW9uLgoKDAoFBAECAQYSA0cEHQoMCgUEAQIBARIDRx46
CgwKBQQBAgEDEgNHPT4KOAoEBAECAhIDSgRBGisgRGV0ZWN0aW9uIHR5cGUgZm9yIGN1c3Rv
bSBpY29uIGRldGVjdGlvbi4KCgwKBQQBAgIGEgNKBB4KDAoFBAECAgESA0ofPAoMCgUEAQIC
AxIDSj9ACj0KAgQCEgRPAFwBGjEgTWV0YWRhdGEgYWJvdXQgdGhlIGNsaWVudCB0ZXN0IGFu
ZCB0ZXN0IGRldmljZS4KCgoKAwQCARIDTwgUClkKBAQCAgASA1ECFRpMIE5hbWUgb2YgdGhl
IGNhbGxpbmcgdGVzdC4gRm9yIGV4YW1wbGUsICd0YXN0LnVpZGV0ZWN0aW9uLkJhc2ljRGV0
ZWN0aW9ucycuCgoMCgUEAgIABRIDUQIICgwKBQQCAgABEgNRCRAKDAoFBAICAAMSA1ETFApU
CgQEAgIBEgNUAhMaRyBCb2FyZCBuYW1lIG9mIHRoZSBDaHJvbWVPUyBkZXZpY2UgdW5kZXIg
dGVzdC4gRm9yIGV4YW1wbGUsICd2b2x0ZWVyJy4KCgwKBQQCAgEFEgNUAggKDAoFBAICAQES
A1QJDgoMCgUEAgIBAxIDVBESClIKBAQCAgISA1cCExpFIE1vZGVsIG5hbWUgb2YgdGhlIENo
cm9tZU9TIGRldmljZSB1bmRlciB0ZXN0LiBGb3IgZXhhbXBsZSwgJ3ZvbGV0Jy4KCgwKBQQC
AgIFEgNXAggKDAoFBAICAgESA1cJDgoMCgUEAgICAxIDVxESCoEBCgQEAgIDEgNbAhgadCBD
aHJvbWVPUyBidWlsZCBvZiB0aGUgZGV2aWNlIHVuZGVyIHRlc3QuCiBGb3IgZXhhbXBsZSwg
J3ZvbHRlZXItcmVsZWFzZS9SMTEwLTE1Mjc1LjAuMC03NTAzMS04Nzk0OTU2NjgxMjYzMzMw
NTYxJy4KCgwKBQQCAgMFEgNbAggKDAoFBAICAwESA1sJEwoMCgUEAgIDAxIDWxYXCjAKAgQD
EgRfAGwBGiQgRGV0ZWN0aW9uIHR5cGUgZm9yIHdvcmQgZGV0ZWN0aW9uLgoKCgoDBAMBEgNf
CBwKOQoEBAMCABIDYQI7GiwgUmVxdWlyZWQuIFRoZSB3b3JkIHRvIGxvY2F0ZSBpbiB0aGUg
aW1hZ2UuCgoMCgUEAwIABRIDYQIICgwKBQQDAgABEgNhCQ0KDAoFBAMCAAMSA2EQEQoMCgUE
AwIACBIDYRI6Cg8KCAQDAgAInAgAEgNhEzkKRQoEBAMCARIDZAIWGjggSW5kaWNhdGluZyB3
aGV0aGVyIHRoZSBxdWVyeSBzdHJpbmcgaXMgYSByZWdleCBvciBub3QuCgoMCgUEAwIBBRID
ZAIGCgwKBQQDAgEBEgNkBxEKDAoFBAMCAQMSA2QUFQpICgQEAwICEgNnAiAaOyBJbmRpY2F0
aW5nIHdoZXRoZXIgdGhlIGRldGVjdGlvbiBpcyBhbiBhcHByb3hpbWF0ZSBtYXRjaC4KCgwK
BQQDAgIFEgNnAgYKDAoFBAMCAgESA2cHGwoMCgUEAwICAxIDZx4fClcKBAQDAgMSA2sCJxpK
IExldmVuc2h0ZWluIGRpc3RhbmNlIHRocmVzaG9sZC4KIEFwcGxpY2FibGUgb25seSBpZiBy
ZWdleF9tb2RlIGlzIEZhbHNlLgoKDAoFBAMCAwQSA2sCCgoMCgUEAwIDBRIDawsQCgwKBQQD
AgMBEgNrESIKDAoFBAMCAwMSA2slJgo3CgIEBBIFbwCAAQEaKiBEZXRlY3Rpb24gdHlwZSBm
b3IgdGV4dCBibG9jayBkZXRlY3Rpb24uCgoKCgMEBAESA28IIQpaCgQEBAIAEgNxAkUaTSBS
ZXF1aXJlZC4gVGhlIHRleHQgYmxvY2sgY29uc2lzdGluZyBhIGxpc3Qgb2Ygd29yZHMgdG8g
bG9jYXRlIGluIHRoZSBpbWFnZS4KCgwKBQQEAgAEEgNxAgoKDAoFBAQCAAUSA3ELEQoMCgUE
BAIAARIDcRIXCgwKBQQEAgADEgNxGhsKDAoFBAQCAAgSA3EcRAoPCggEBAIACJwIABIDcR1D
CkUKBAQEAgESA3QCFho4IEluZGljYXRpbmcgd2hldGhlciB0aGUgcXVlcnkgc3RyaW5nIGlz
IGEgcmVnZXggb3Igbm90LgoKDAoFBAQCAQUSA3QCBgoMCgUEBAIBARIDdAcRCgwKBQQEAgED
EgN0FBUKSAoEBAQCAhIDdwIgGjsgSW5kaWNhdGluZyB3aGV0aGVyIHRoZSBkZXRlY3Rpb24g
aXMgYW4gYXBwcm94aW1hdGUgbWF0Y2guCgoMCgUEBAICBRIDdwIGCgwKBQQEAgIBEgN3BxsK
DAoFBAQCAgMSA3ceHwpXCgQEBAIDEgN7AicaSiBMZXZlbnNodGVpbiBkaXN0YW5jZSB0aHJl
c2hvbGQuCiBBcHBsaWNhYmxlIG9ubHkgaWYgcmVnZXhfbW9kZSBpcyBGYWxzZS4KCgwKBQQE
AgMEEgN7AgoKDAoFBAQCAwUSA3sLEAoMCgUEBAIDARIDexEiCgwKBQQEAgMDEgN7JSYKYAoE
BAQCBBIDfwIgGlMgSW5kaWNhdGluZyB3aGV0aGVyIHRoZSBkZXRlY3Rpb24gcmVzdWx0IHNo
b3VsZCBvbmx5IGNvbnRhaW4gdGhlIHNwZWNpZmllZAogd29yZHMuCgoMCgUEBAIEBRIDfwIG
CgwKBQQEAgQBEgN/BxsKDAoFBAQCBAMSA38eHwo5CgIEBRIGgwEAjQEBGisgRGV0ZWN0aW9u
IHR5cGUgZm9yIGN1c3RvbSBpY29uIGRldGVjdGlvbi4KCgsKAwQFARIEgwEIIgpPCgQEBQIA
EgSFAQI+GkEgUmVxdWlyZWQuIFJlcXVpcmVkIGZpZWxkIHRoYXQgcmVwcmVzZW50cyBhbiBp
Y29uIGluIFBORyBmb3JtYXQuCgoNCgUEBQIABRIEhQECBwoNCgUEBQIAARIEhQEIEAoNCgUE
BQIAAxIEhQETFAoNCgUEBQIACBIEhQEVPQoQCggEBQIACJwIABIEhQEWPApJCgQEBQIBEgSI
AQIYGjsgU2V0IG1hdGNoX2NvdW50IHRvIC0xIHRvIG5vdCBsaW1pdCB0aGUgbnVtYmVyIG9m
IG1hdGNoZXMuCgoNCgUEBQIBBRIEiAECBwoNCgUEBQIBARIEiAEIEwoNCgUEBQIBAxIEiAEW
Fwp5CgQEBQICEgSMAQImGmsgQ29uZmlkZW5jZSB0aHJlc2hvbGQgaW4gdGhlIHJhbmdlIFsw
LjAsIDEuMF0gYmVsb3cgd2hpY2ggdGhlIG1hdGNoZXMgd2lsbAogYmUgY29uc2lkZXJlZCBh
cyBub24tZXhpc3RlbnQuCgoNCgUEBQICBRIEjAECCAoNCgUEBQICARIEjAEJIQoNCgUEBQIC
AxIEjAEkJQoyCgIEBhIGkAEAmwEBGiQgUmVzcG9uc2UgbWVzc2FnZSBmb3IgVUkgZGV0ZWN0
aW9uLgoKCwoDBAYBEgSQAQgbCjIKBAQGAgASBJIBAioaJCBMb2NhdGlvbnMgb2YgbWF0Y2hp
bmcgVUkgZWxlbWVudHMuCgoNCgUEBgIABBIEkgECCgoNCgUEBgIABhIEkgELFgoNCgUEBgIA
ARIEkgEXJQoNCgUEBgIAAxIEkgEoKQpkCgQEBgIBEgSWAQIiGlYgVGhlIHRyYW5zZm9ybWVk
IGRldGVjdGlvbiBpbWFnZSBQTkcsIGlmIHJlcXVlc3RlZCBhbmQgdHJhbnNmb3JtYXRpb25z
IHdlcmUKIGFwcGxpZWQuCgoNCgUEBgIBBRIElgECBwoNCgUEBgIBARIElgEIHQoNCgUEBgIB
AxIElgEgIQqZAQoEBAYCAhIEmgECIhqKASBUaGUgYW1vdW50IHRoZSBvcmlnaW5hbCBpbWFn
ZSB3YXMgc2NhbGVkIGJ5IHRvIG1ha2UgdGhlIHRyYW5zZm9ybWVkIGltYWdlLgogMS4wIGlm
IHRoZSBkZXRlY3Rpb24gcmVzdWx0IGlzIG5vdCBiYXNlZCBvbiBhIHJlc2l6ZWQgaW1hZ2Uu
CgoNCgUEBgICBRIEmgECBwoNCgUEBgICARIEmgEIHQoNCgUEBgICAxIEmgEgIQqdAQoCBAcS
BqABAK8BARqOASBUaGUgbG9jYXRpb24gb2YgYSBVSSBlbGVtZW50LgogQSBib3VuZGluZyBi
b3ggaXMgcmVwcmVuc2VudGVkIGJ5IGl0cyB0b3AtbGVmdCBwb2ludCBbbGVmdCwgdG9wXQog
YW5kIGl0cyBib3R0b20tcmlnaHQgcG9pbnQgW3JpZ2h0LCBib3R0b21dLgoKCwoDBAcBEgSg
AQgTCjMKBAQHAgASBKIBAhIaJSBUaGUgdGV4dCBmb3VuZCBpbiB0aGUgYm91bmRpbmcgYm94
LgoKDQoFBAcCAAUSBKIBAggKDQoFBAcCAAESBKIBCQ0KDQoFBAcCAAMSBKIBEBEKNwoEBAcC
ARIEpQECEBopIFRoZSB5LWNvb3JkaW5hdGUgb2YgdGhlIHRvcC1sZWZ0IHBvaW50LgoKDQoF
BAcCAQUSBKUBAgcKDQoFBAcCAQESBKUBCAsKDQoFBAcCAQMSBKUBDg8KNwoEBAcCAhIEqAEC
ERopIFRoZSB4LWNvb3JkaW5hdGUgb2YgdGhlIHRvcC1sZWZ0IHBvaW50LgoKDQoFBAcCAgUS
BKgBAgcKDQoFBAcCAgESBKgBCAwKDQoFBAcCAgMSBKgBDxAKOwoEBAcCAxIEqwECExotIFRo
ZSB5LWNvb3JkaW5hdGUgb2YgdGhlIGJvdHRvbS1yaWdodCBwb2ludC4KCg0KBQQHAgMFEgSr
AQIHCg0KBQQHAgMBEgSrAQgOCg0KBQQHAgMDEgSrARESCjsKBAQHAgQSBK4BAhIaLSBUaGUg
eC1jb29yZGluYXRlIG9mIHRoZSBib3R0b20tcmlnaHQgcG9pbnQuCgoNCgUEBwIEBRIErgEC
BwoNCgUEBwIEARIErgEIDQoNCgUEBwIEAxIErgEQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest ===
    # Fields for UiDetectionRequest
    # Field: image_png Type: 12 ()
    # Field: request Type: 11 (.google.chromeos.uidetection.v1.DetectionRequest)
    # Field: resize_image Type: 8 ()
    # Field: test_id Type: 9 ()
    # Field: test_metadata Type: 11 (.google.chromeos.uidetection.v1.TestMetadata)
    # Field: force_image_resizing Type: 8 ()
    # Field: return_transformed_image Type: 8 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest ===
    # Fields for DetectionRequest
    # Field: word_detection_request Type: 11 (.google.chromeos.uidetection.v1.WordDetectionRequest)
    # Field: text_block_detection_request Type: 11 (.google.chromeos.uidetection.v1.TextBlockDetectionRequest)
    # Field: custom_icon_detection_request Type: 11 (.google.chromeos.uidetection.v1.CustomIconDetectionRequest)

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata ===
    # Fields for TestMetadata
    # Field: test_id Type: 9 ()
    # Field: board Type: 9 ()
    # Field: model Type: 9 ()
    # Field: cros_build Type: 9 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest ===
    # Fields for WordDetectionRequest
    # Field: word Type: 9 ()
    # Field: regex_mode Type: 8 ()
    # Field: disable_approx_match Type: 8 ()
    # Field: max_edit_distance Type: 5 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest ===
    # Fields for TextBlockDetectionRequest
    # Field: words Type: 9 ()
    # Field: regex_mode Type: 8 ()
    # Field: disable_approx_match Type: 8 ()
    # Field: max_edit_distance Type: 5 ()
    # Field: specified_words_only Type: 8 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest ===
    # Fields for CustomIconDetectionRequest
    # Field: icon_png Type: 12 ()
    # Field: match_count Type: 5 ()
    # Field: min_confidence_threshold Type: 1 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse ===
    # Fields for UiDetectionResponse
    # Field: bounding_boxes Type: 11 (.google.chromeos.uidetection.v1.BoundingBox)
    # Field: transformed_image_png Type: 12 ()
    # Field: resizing_scale_factor Type: 2 ()

# === Message: Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox ===
    # Fields for BoundingBox
    # Field: text Type: 9 ()
    # Field: top Type: 5 ()
    # Field: left Type: 5 ()
    # Field: bottom Type: 5 ()
    # Field: right Type: 5 ()

# === Service Client: Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionServiceClient ===
package Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionServiceClient;

=pod

=head2 Service Client: Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionServiceClient

Client stub representing the remote C<UiDetectionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chromeos.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chromeos.googleapis.com:443' );

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

sub execute_detection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.uidetection.v1.UiDetectionService',
        method         => 'ExecuteDetection',
        request        => $req,
        response_class => 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Chromeos::Uidetection::V1::UiDetection - Compiled Protocol Buffers messages for google/chromeos/uidetection/v1/ui_detection.proto

=head1 SYNOPSIS

    use Google::Chromeos::Uidetection::V1::UiDetection;

    my $msg = Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest->new({
        image_png => $image_png,
        request => $request,
        resize_image => $resize_image,
        test_id => $test_id,
    });

    # Read or update a field
    my $val = $msg->image_png();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/chromeos/uidetection/v1/ui_detection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest

Request message for UI detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_png() >> / C<< $msg->image_png($value) >>

Type: C<Bytes>

Required. Required field that represents a PNG image.

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest>)

Required. Required field that indicates the detection type.

=item * C<< $msg->resize_image() >> / C<< $msg->resize_image($value) >>

Type: C<Bool>

Indicates whether to fall back to resizing the image if no elements are
detected.

=item * C<< $msg->test_id() >> / C<< $msg->test_id($value) >>

Type: C<String>

Deprecated as of 2023-03-29. Use test_metadata instead.

=item * C<< $msg->test_metadata() >> / C<< $msg->test_metadata($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata>)

Optional. Metadata about the client for analytics.

=item * C<< $msg->force_image_resizing() >> / C<< $msg->force_image_resizing($value) >>

Type: C<Bool>

Optional. Indicates whether to always start by resizing the image.

=item * C<< $msg->return_transformed_image() >> / C<< $msg->return_transformed_image($value) >>

Type: C<Bool>

Optional. Indicates whether to respond with the transformed image png.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest

Detection type specifies what to detect in the image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->word_detection_request() >> / C<< $msg->word_detection_request($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest>)

Detection type for word detection.

=item * C<< $msg->text_block_detection_request() >> / C<< $msg->text_block_detection_request($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest>)

Detection type for text block detection.

=item * C<< $msg->custom_icon_detection_request() >> / C<< $msg->custom_icon_detection_request($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest>)

Detection type for custom icon detection.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata

Metadata about the client test and test device.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_id() >> / C<< $msg->test_id($value) >>

Type: C<String>

Name of the calling test. For example, 'tast.uidetection.BasicDetections'.

=item * C<< $msg->board() >> / C<< $msg->board($value) >>

Type: C<String>

Board name of the ChromeOS device under test. For example, 'volteer'.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Model name of the ChromeOS device under test. For example, 'volet'.

=item * C<< $msg->cros_build() >> / C<< $msg->cros_build($value) >>

Type: C<String>

ChromeOS build of the device under test.
For example, 'volteer-release/R110-15275.0.0-75031-8794956681263330561'.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest

Detection type for word detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->word() >> / C<< $msg->word($value) >>

Type: C<String>

Required. The word to locate in the image.

=item * C<< $msg->regex_mode() >> / C<< $msg->regex_mode($value) >>

Type: C<Bool>

Indicating whether the query string is a regex or not.

=item * C<< $msg->disable_approx_match() >> / C<< $msg->disable_approx_match($value) >>

Type: C<Bool>

Indicating whether the detection is an approximate match.

=item * C<< $msg->max_edit_distance() >> / C<< $msg->max_edit_distance($value) >>

Type: C<Int32>

Levenshtein distance threshold.
Applicable only if regex_mode is False.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest

Detection type for text block detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->words() >> / C<< $msg->words($value) >>

Type: C<String>

Required. The text block consisting a list of words to locate in the image.

=item * C<< $msg->regex_mode() >> / C<< $msg->regex_mode($value) >>

Type: C<Bool>

Indicating whether the query string is a regex or not.

=item * C<< $msg->disable_approx_match() >> / C<< $msg->disable_approx_match($value) >>

Type: C<Bool>

Indicating whether the detection is an approximate match.

=item * C<< $msg->max_edit_distance() >> / C<< $msg->max_edit_distance($value) >>

Type: C<Int32>

Levenshtein distance threshold.
Applicable only if regex_mode is False.

=item * C<< $msg->specified_words_only() >> / C<< $msg->specified_words_only($value) >>

Type: C<Bool>

Indicating whether the detection result should only contain the specified
words.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest

Detection type for custom icon detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->icon_png() >> / C<< $msg->icon_png($value) >>

Type: C<Bytes>

Required. Required field that represents an icon in PNG format.

=item * C<< $msg->match_count() >> / C<< $msg->match_count($value) >>

Type: C<Int32>

Set match_count to -1 to not limit the number of matches.

=item * C<< $msg->min_confidence_threshold() >> / C<< $msg->min_confidence_threshold($value) >>

Type: C<Double>

Confidence threshold in the range [0.0, 1.0] below which the matches will
be considered as non-existent.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse

Response message for UI detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_boxes() >> / C<< $msg->bounding_boxes($value) >>

Type: C<Message> (L<Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox>)

Locations of matching UI elements.

=item * C<< $msg->transformed_image_png() >> / C<< $msg->transformed_image_png($value) >>

Type: C<Bytes>

The transformed detection image PNG, if requested and transformations were
applied.

=item * C<< $msg->resizing_scale_factor() >> / C<< $msg->resizing_scale_factor($value) >>

Type: C<Float>

The amount the original image was scaled by to make the transformed image.
1.0 if the detection result is not based on a resized image.

=back

=head2 Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox

The location of a UI element.
A bounding box is reprensented by its top-left point [left, top]
and its bottom-right point [right, bottom].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

The text found in the bounding box.

=item * C<< $msg->top() >> / C<< $msg->top($value) >>

Type: C<Int32>

The y-coordinate of the top-left point.

=item * C<< $msg->left() >> / C<< $msg->left($value) >>

Type: C<Int32>

The x-coordinate of the top-left point.

=item * C<< $msg->bottom() >> / C<< $msg->bottom($value) >>

Type: C<Int32>

The y-coordinate of the bottom-right point.

=item * C<< $msg->right() >> / C<< $msg->right($value) >>

Type: C<Int32>

The x-coordinate of the bottom-right point.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Chromeos::Uidetection::V1::UiDetection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
