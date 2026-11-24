package Google::Cloud::Dialogflow::V2beta1::ToolCall;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3Rvb2xfY2FsbC5wcm90bxIfZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0
cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLfBQoIVG9vbENh
bGwSPAoEdG9vbBgBIAEoCUIm4EEB+kEgCh5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rv
b2xIAFIEdG9vbBI8CghjZXNfdG9vbBgLIAEoCUIf4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5j
b20vVG9vbEgAUgdjZXNUb29sEkUKC2Nlc190b29sc2V0GAwgASgJQiLgQQH6QRwKGmNlcy5n
b29nbGVhcGlzLmNvbS9Ub29sc2V0SABSCmNlc1Rvb2xzZXQSOQoHY2VzX2FwcBgIIAEoCUIe
4EEB+kEYChZjZXMuZ29vZ2xlYXBpcy5jb20vQXBwSABSBmNlc0FwcBIvChF0b29sX2Rpc3Bs
YXlfbmFtZRgJIAEoCUID4EEBUg90b29sRGlzcGxheU5hbWUSNQoUdG9vbF9kaXNwbGF5X2Rl
dGFpbHMYCiABKAlCA+BBAVISdG9vbERpc3BsYXlEZXRhaWxzEhsKBmFjdGlvbhgCIAEoCUID
4EEBUgZhY3Rpb24SRwoQaW5wdXRfcGFyYW1ldGVycxgDIAEoCzIXLmdvb2dsZS5wcm90b2J1
Zi5TdHJ1Y3RCA+BBAVIPaW5wdXRQYXJhbWV0ZXJzEkAKC2NyZWF0ZV90aW1lGAQgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEigKDWFuc3dlcl9y
ZWNvcmQYBiABKAlCA+BBAVIMYW5zd2VyUmVjb3JkEkoKBXN0YXRlGAcgASgOMi8uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Ub29sQ2FsbC5TdGF0ZUID4EEDUgVzdGF0ZSJF
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg0KCVRSSUdHRVJFRBABEhYKEk5FRURT
X0NPTkZJUk1BVElPThACQggKBnNvdXJjZSKTBQoOVG9vbENhbGxSZXN1bHQSPAoEdG9vbBgB
IAEoCUIm4EEB+kEgCh5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rvb2xIAFIEdG9vbBI8
CghjZXNfdG9vbBgMIAEoCUIf4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgdj
ZXNUb29sEkUKC2Nlc190b29sc2V0GA0gASgJQiLgQQH6QRwKGmNlcy5nb29nbGVhcGlzLmNv
bS9Ub29sc2V0SABSCmNlc1Rvb2xzZXQSOQoHY2VzX2FwcBgLIAEoCUIe4EEB+kEYChZjZXMu
Z29vZ2xlYXBpcy5jb20vQXBwSABSBmNlc0FwcBIbCgZhY3Rpb24YAiABKAlCA+BBAVIGYWN0
aW9uElIKBWVycm9yGAMgASgLMjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5U
b29sQ2FsbFJlc3VsdC5FcnJvckID4EEBSAFSBWVycm9yEiYKC3Jhd19jb250ZW50GAUgASgM
QgPgQQFIAVIKcmF3Q29udGVudBIfCgdjb250ZW50GAYgASgJQgPgQQFIAVIHY29udGVudBJA
CgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRIoCg1hbnN3ZXJfcmVjb3JkGAkgASgJQgPgQQFSDGFuc3dlclJlY29yZBpJ
CgVFcnJvchIdCgdtZXNzYWdlGAEgASgJQgPgQQFSB21lc3NhZ2USIQoJcmV0cnlhYmxlGAIg
ASgIQgPgQQFSCXJldHJ5YWJsZUIICgZzb3VyY2VCCAoGcmVzdWx0QqIBCiNjb20uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMUINVG9vbENhbGxQcm90b1ABWkNjbG91ZC5nb29n
bGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxv
d3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkJldGExStIsCgcSBQ4ArwEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAAmCgkKAgMDEgMVACkKCAoBCBIDFwA8CgkKAgglEgMX
ADwKCAoBCBIDGABaCgkKAggLEgMYAFoKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAu
CgkKAggIEgMaAC4KCAoBCBIDGwA8CgkKAggBEgMbADwKCAoBCBIDHAAgCgkKAggkEgMcACAK
VgoCBAASBB8AZwEaSiBSZXByZXNlbnRzIGEgY2FsbCBvZiBhIHNwZWNpZmljIHRvb2wncyBh
Y3Rpb24gd2l0aCB0aGUgc3BlY2lmaWVkIGlucHV0cy4KCgoKAwQAARIDHwgQCiEKBAQABAAS
BCECKgMaEyBUb29sIGNhbGwgc3RhdGVzLgoKDAoFBAAEAAESAyEHDAofCgYEAAQAAgASAyME
GhoQIERlZmF1bHQgdmFsdWUuCgoOCgcEAAQAAgABEgMjBBUKDgoHBAAEAAIAAhIDIxgZCjIK
BgQABAACARIDJgQSGiMgVGhlIHRvb2wgY2FsbCBoYXMgYmVlbiB0cmlnZ2VyZWQuCgoOCgcE
AAQAAgEBEgMmBA0KDgoHBAAEAAIBAhIDJhARCkIKBgQABAACAhIDKQQbGjMgVGhlIHRvb2wg
Y2FsbCByZXF1aXJlcyBjb25maXJtYXRpb24gZnJvbSBhIGh1bWFuLgoKDgoHBAAEAAICARID
KQQWCg4KBwQABAACAgISAykZGgo3CgQEAAgAEgQtAk8DGikgU3BlY2lmaWVzIHRoZSBzb3Vy
Y2Ugb2YgdGhpcyB0b29sIGNhbGwuCgoMCgUEAAgAARIDLQgOCq4BCgQEAAIAEgQxBDYGGp8B
IE9wdGlvbmFsLiBUaGUgW3Rvb2xdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
VG9vbF0gYXNzb2NpYXRlZAogd2l0aCB0aGlzIGNhbGwuIEZvcm1hdDoKIGBwcm9qZWN0cy88
UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L3Rvb2xzLzxUb29sSUQ+YC4KCgwK
BQQAAgAFEgMxBAoKDAoFBAACAAESAzELDwoMCgUEAAIAAxIDMRITCg0KBQQAAgAIEgQxFDYF
Cg8KCAQAAgAInAgAEgMyBiwKDwoHBAACAAifCBIEMwY1BwqLAQoEBAACARIEOwQ+Bhp9IE9w
dGlvbmFsLiBDRVMgdG9vbCBuYW1lIGZvciB0aGlzIGNhbGwuCiBGb3JtYXQ6CiBgcHJvamVj
dHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hcHBzLzxBcHBJRD4vdG9v
bHMvPFRvb2xJRD5gLgoKDAoFBAACAQUSAzsECgoMCgUEAAIBARIDOwsTCgwKBQQAAgEDEgM7
FhgKDQoFBAACAQgSBDsZPgUKDwoIBAACAQicCAASAzwGLAoOCgcEAAIBCJ8IEgM9BksKlAEK
BAQAAgISBEMERgYahQEgT3B0aW9uYWwuIENFUyB0b29sc2V0IG5hbWUgZm9yIHRoaXMgY2Fs
bC4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9u
SUQ+L2FwcHMvPEFwcElEPi90b29sc2V0cy9Ub29sc2V0SUQ+YC4KCgwKBQQAAgIFEgNDBAoK
DAoFBAACAgESA0MLFgoMCgUEAAICAxIDQxkbCg0KBQQAAgIIEgRDHEYFCg8KCAQAAgIInAgA
EgNEBiwKDgoHBAACAgifCBIDRQZOCnsKBAQAAgMSBEsETgYabSBPcHRpb25hbC4gQ0VTIGFw
cCBuYW1lIGZvciB0aGlzIGNhbGwuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbklEPi9hcHBzLzxBcHBJRD5gLgoKDAoFBAACAwUSA0sECgoM
CgUEAAIDARIDSwsSCgwKBQQAAgMDEgNLFRYKDQoFBAACAwgSBEsXTgUKDwoIBAACAwicCAAS
A0wGLAoOCgcEAAIDCJ8IEgNNBkoKWAoEBAACBBIDUgJIGksgT3B0aW9uYWwuIEEgaHVtYW4g
cmVhZGFibGUgc2hvcnQgbmFtZSBvZiB0aGUgdG9vbCwgdG8gYmUgc2hvd24gb24gdGhlIFVJ
LgoKDAoFBAACBAUSA1ICCAoMCgUEAAIEARIDUgkaCgwKBQQAAgQDEgNSHR4KDAoFBAACBAgS
A1IfRwoPCggEAAIECJwIABIDUiBGCkIKBAQAAgUSA1UCTBo1IE9wdGlvbmFsLiBBIGh1bWFu
IHJlYWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoZSB0b29sLgoKDAoFBAACBQUSA1UCCAoMCgUE
AAIFARIDVQkdCgwKBQQAAgUDEgNVICIKDAoFBAACBQgSA1UjSwoPCggEAAIFCJwIABIDVSRK
ClEKBAQAAgYSA1gCPRpEIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdG9vbCdzIGFjdGlv
biBhc3NvY2lhdGVkIHdpdGggdGhpcyBjYWxsLgoKDAoFBAACBgUSA1gCCAoMCgUEAAIGARID
WAkPCgwKBQQAAgYDEgNYEhMKDAoFBAACBggSA1gUPAoPCggEAAIGCJwIABIDWBU7CjgKBAQA
AgcSBFsCXC8aKiBPcHRpb25hbC4gVGhlIGFjdGlvbidzIGlucHV0IHBhcmFtZXRlcnMuCgoM
CgUEAAIHBhIDWwIYCgwKBQQAAgcBEgNbGSkKDAoFBAACBwMSA1ssLQoMCgUEAAIHCBIDXAYu
Cg8KCAQAAgcInAgAEgNcBy0KOgoEBAACCBIEXwJgMhosIE91dHB1dCBvbmx5LiBDcmVhdGUg
dGltZSBvZiB0aGUgdG9vbCBjYWxsLgoKDAoFBAACCAYSA18CGwoMCgUEAAIIARIDXxwnCgwK
BQQAAggDEgNfKisKDAoFBAACCAgSA2AGMQoPCggEAAIICJwIABIDYAcwCkoKBAQAAgkSA2MC
RBo9IE9wdGlvbmFsLiBUaGUgYW5zd2VyIHJlY29yZCBhc3NvY2lhdGVkIHdpdGggdGhpcyB0
b29sIGNhbGwuCgoMCgUEAAIJBRIDYwIICgwKBQQAAgkBEgNjCRYKDAoFBAACCQMSA2MZGgoM
CgUEAAIJCBIDYxtDCg8KCAQAAgkInAgAEgNjHEIKMgoEBAACChIDZgI+GiUgT3V0cHV0IG9u
bHkuIFN0YXRlIG9mIHRoZSB0b29sIGNhbGwKCgwKBQQAAgoGEgNmAgcKDAoFBAACCgESA2YI
DQoMCgUEAAIKAxIDZhARCgwKBQQAAgoIEgNmEj0KDwoIBAACCgicCAASA2YTPAo1CgIEARIF
agCvAQEaKCBUaGUgcmVzdWx0IG9mIGNhbGxpbmcgYSB0b29sJ3MgYWN0aW9uLgoKCgoDBAEB
EgNqCBYKMwoEBAEDABIEbAJyAxolIEFuIGVycm9yIHByb2R1Y2VkIGJ5IHRoZSB0b29sIGNh
bGwuCgoMCgUEAQMAARIDbAoPCj0KBgQBAwACABIDbgRAGi4gT3B0aW9uYWwuIFRoZSBlcnJv
ciBtZXNzYWdlIG9mIHRoZSBmdW5jdGlvbi4KCg4KBwQBAwACAAUSA24ECgoOCgcEAQMAAgAB
EgNuCxIKDgoHBAEDAAIAAxIDbhUWCg4KBwQBAwACAAgSA24XPwoRCgoEAQMAAgAInAgAEgNu
GD4KSAoGBAEDAAIBEgNxBEAaOSBPcHRpb25hbC4gU3BlY2lmaWVzIHdoZXRoZXIgdGhlIHRv
b2wgY2FsbCBpcyByZXRyeWFibGUuCgoOCgcEAQMAAgEFEgNxBAgKDgoHBAEDAAIBARIDcQkS
Cg4KBwQBAwACAQMSA3EVFgoOCgcEAQMAAgEIEgNxFz8KEQoKBAEDAAIBCJwIABIDcRg+CjgK
BAQBCAASBXUClwEDGikgU3BlY2lmaWVzIHRoZSBzb3VyY2Ugb2YgdGhpcyB0b29sIGNhbGwu
CgoMCgUEAQgAARIDdQgOCq4BCgQEAQIAEgR5BH4GGp8BIE9wdGlvbmFsLiBUaGUgW3Rvb2xd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuVG9vbF0gYXNzb2NpYXRlZAogd2l0
aCB0aGlzIGNhbGwuIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMv
PExvY2F0aW9uSUQ+L3Rvb2xzLzxUb29sSUQ+YC4KCgwKBQQBAgAFEgN5BAoKDAoFBAECAAES
A3kLDwoMCgUEAQIAAxIDeRITCg0KBQQBAgAIEgR5FH4FCg8KCAQBAgAInAgAEgN6BiwKDwoH
BAECAAifCBIEewZ9BwqNAQoEBAECARIGgwEEhgEGGn0gT3B0aW9uYWwuIENFUyB0b29sIG5h
bWUgZm9yIHRoaXMgY2FsbC4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FwcHMvPEFwcElEPi90b29scy88VG9vbElEPmAuCgoNCgUE
AQIBBRIEgwEECgoNCgUEAQIBARIEgwELEwoNCgUEAQIBAxIEgwEWGAoPCgUEAQIBCBIGgwEZ
hgEFChAKCAQBAgEInAgAEgSEAQYsCg8KBwQBAgEInwgSBIUBBksKlgEKBAQBAgISBosBBI4B
BhqFASBPcHRpb25hbC4gQ0VTIHRvb2xzZXQgbmFtZSBmb3IgdGhpcyBjYWxsLgogRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYXBwcy88
QXBwSUQ+L3Rvb2xzZXRzL1Rvb2xzZXRJRD5gLgoKDQoFBAECAgUSBIsBBAoKDQoFBAECAgES
BIsBCxYKDQoFBAECAgMSBIsBGRsKDwoFBAECAggSBosBHI4BBQoQCggEAQICCJwIABIEjAEG
LAoPCgcEAQICCJ8IEgSNAQZOCn0KBAQBAgMSBpMBBJYBBhptIE9wdGlvbmFsLiBDRVMgYXBw
IG5hbWUgZm9yIHRoaXMgY2FsbC4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FwcHMvPEFwcElEPmAuCgoNCgUEAQIDBRIEkwEECgoN
CgUEAQIDARIEkwELEgoNCgUEAQIDAxIEkwEVFwoPCgUEAQIDCBIGkwEYlgEFChAKCAQBAgMI
nAgAEgSUAQYsCg8KBwQBAgMInwgSBJUBBkoKUgoEBAECBBIEmgECPRpEIE9wdGlvbmFsLiBU
aGUgbmFtZSBvZiB0aGUgdG9vbCdzIGFjdGlvbiBhc3NvY2lhdGVkIHdpdGggdGhpcyBjYWxs
LgoKDQoFBAECBAUSBJoBAggKDQoFBAECBAESBJoBCQ8KDQoFBAECBAMSBJoBEhMKDQoFBAEC
BAgSBJoBFDwKEAoIBAECBAicCAASBJoBFTsKKQoEBAEIARIGnQECpwEDGhkgVGhlIHRvb2wg
Y2FsbCdzIHJlc3VsdC4KCg0KBQQBCAEBEgSdAQgOCjAKBAQBAgUSBJ8BBD0aIiBPcHRpb25h
bC4gVGhlIHRvb2wgY2FsbCdzIGVycm9yLgoKDQoFBAECBQYSBJ8BBAkKDQoFBAECBQESBJ8B
Cg8KDQoFBAECBQMSBJ8BEhMKDQoFBAECBQgSBJ8BFDwKEAoIBAECBQicCAASBJ8BFTsKhwEK
BAQBAgYSBKMBBEMaeSBPcHRpb25hbC4gT25seSBwb3B1bGF0ZWQgaWYgdGhlIHJlc3BvbnNl
IGNvbnRlbnQgaXMgbm90IHV0Zi04IGVuY29kZWQuCiAoYnkgZGVmaW5pdGlvbiBieXRlIGZp
ZWxkcyBhcmUgYmFzZTY0IGVuY29kZWQpLgoKDQoFBAECBgUSBKMBBAkKDQoFBAECBgESBKMB
ChUKDQoFBAECBgMSBKMBGBkKDQoFBAECBggSBKMBGkIKEAoIBAECBgicCAASBKMBG0EKUgoE
BAECBxIEpgEEQBpEIE9wdGlvbmFsLiBPbmx5IHBvcHVsYXRlZCBpZiB0aGUgcmVzcG9uc2Ug
Y29udGVudCBpcyB1dGYtOCBlbmNvZGVkLgoKDQoFBAECBwUSBKYBBAoKDQoFBAECBwESBKYB
CxIKDQoFBAECBwMSBKYBFRYKDQoFBAECBwgSBKYBFz8KEAoIBAECBwicCAASBKYBGD4KQwoE
BAECCBIGqgECqwEyGjMgT3V0cHV0IG9ubHkuIENyZWF0ZSB0aW1lIG9mIHRoZSB0b29sIGNh
bGwgcmVzdWx0LgoKDQoFBAECCAYSBKoBAhsKDQoFBAECCAESBKoBHCcKDQoFBAECCAMSBKoB
KisKDQoFBAECCAgSBKsBBjEKEAoIBAECCAicCAASBKsBBzAKUgoEBAECCRIErgECRBpEIE9w
dGlvbmFsLiBUaGUgYW5zd2VyIHJlY29yZCBhc3NvY2lhdGVkIHdpdGggdGhpcyB0b29sIGNh
bGwgcmVzdWx0LgoKDQoFBAECCQUSBK4BAggKDQoFBAECCQESBK4BCRYKDQoFBAECCQMSBK4B
GRoKDQoFBAECCQgSBK4BG0MKEAoIBAECCQicCAASBK4BHEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: ces_tool Type: 9 ()
    # Field: ces_toolset Type: 9 ()
    # Field: ces_app Type: 9 ()
    # Field: tool_display_name Type: 9 ()
    # Field: tool_display_details Type: 9 ()
    # Field: action Type: 9 ()
    # Field: input_parameters Type: 11 (.google.protobuf.Struct)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: answer_record Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2beta1.ToolCall.State)

# Enum: ToolCall::State
our $ToolCall_STATE_UNSPECIFIED = 0;
our $ToolCall_TRIGGERED = 1;
our $ToolCall_NEEDS_CONFIRMATION = 2;

# === Message: Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult ===
    # Fields for ToolCallResult
    # Field: tool Type: 9 ()
    # Field: ces_tool Type: 9 ()
    # Field: ces_toolset Type: 9 ()
    # Field: ces_app Type: 9 ()
    # Field: action Type: 9 ()
    # Field: error Type: 11 (.google.cloud.dialogflow.v2beta1.ToolCallResult.Error)
    # Field: raw_content Type: 12 ()
    # Field: content Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: answer_record Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::ToolCall - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/tool_call.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::ToolCall;

    my $msg = Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall->new({
        tool => $tool,
        ces_tool => $ces_tool,
        ces_toolset => $ces_toolset,
        ces_app => $ces_app,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/tool_call.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall

Represents a call of a specific tool's action with the specified inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The [tool][google.cloud.dialogflow.v2beta1.Tool] associated
with this call. Format:
`projects/<ProjectID>/locations/<LocationID>/tools/<ToolID>`.

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. CES tool name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/tools/<ToolID>`.

=item * C<< $msg->ces_toolset() >> / C<< $msg->ces_toolset($value) >>

Type: C<String>

Optional. CES toolset name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/toolsets/ToolsetID>`.

=item * C<< $msg->ces_app() >> / C<< $msg->ces_app($value) >>

Type: C<String>

Optional. CES app name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>`.

=item * C<< $msg->tool_display_name() >> / C<< $msg->tool_display_name($value) >>

Type: C<String>

Optional. A human readable short name of the tool, to be shown on the UI.

=item * C<< $msg->tool_display_details() >> / C<< $msg->tool_display_details($value) >>

Type: C<String>

Optional. A human readable description of the tool.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Optional. The name of the tool's action associated with this call.

=item * C<< $msg->input_parameters() >> / C<< $msg->input_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The action's input parameters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the tool call.

=item * C<< $msg->answer_record() >> / C<< $msg->answer_record($value) >>

Type: C<String>

Optional. The answer record associated with this tool call.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::ToolCall::State>)

Output only. State of the tool call

=back

=head3 Enum: ToolCall::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<TRIGGERED> => C<1>

=item * C<NEEDS_CONFIRMATION> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult

The result of calling a tool's action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The [tool][google.cloud.dialogflow.v2beta1.Tool] associated
with this call. Format:
`projects/<ProjectID>/locations/<LocationID>/tools/<ToolID>`.

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. CES tool name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/tools/<ToolID>`.

=item * C<< $msg->ces_toolset() >> / C<< $msg->ces_toolset($value) >>

Type: C<String>

Optional. CES toolset name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/toolsets/ToolsetID>`.

=item * C<< $msg->ces_app() >> / C<< $msg->ces_app($value) >>

Type: C<String>

Optional. CES app name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Optional. The name of the tool's action associated with this call.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult::Error>)

Optional. The tool call's error.

=item * C<< $msg->raw_content() >> / C<< $msg->raw_content($value) >>

Type: C<Bytes>

Optional. Only populated if the response content is not utf-8 encoded.
(by definition byte fields are base64 encoded).

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Optional. Only populated if the response content is utf-8 encoded.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the tool call result.

=item * C<< $msg->answer_record() >> / C<< $msg->answer_record($value) >>

Type: C<String>

Optional. The answer record associated with this tool call result.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::ToolCall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
