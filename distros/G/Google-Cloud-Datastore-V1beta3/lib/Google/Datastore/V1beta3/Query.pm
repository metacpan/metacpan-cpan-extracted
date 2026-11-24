package Google::Datastore::V1beta3::Query;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Datastore::V1beta3::Entity };
    eval { require Google::Protobuf::Wrappers };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvZGF0YXN0b3JlL3YxYmV0YTMvcXVlcnkucHJvdG8SGGdvb2dsZS5kYXRhc3Rv
cmUudjFiZXRhMxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxolZ29vZ2xlL2RhdGFz
dG9yZS92MWJldGEzL2VudGl0eS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnBy
b3RvGhhnb29nbGUvdHlwZS9sYXRsbmcucHJvdG8izQEKDEVudGl0eVJlc3VsdBI4CgZlbnRp
dHkYASABKAsyIC5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRW50aXR5UgZlbnRpdHkSGAoH
dmVyc2lvbhgEIAEoA1IHdmVyc2lvbhIWCgZjdXJzb3IYAyABKAxSBmN1cnNvciJRCgpSZXN1
bHRUeXBlEhsKF1JFU1VMVF9UWVBFX1VOU1BFQ0lGSUVEEAASCAoERlVMTBABEg4KClBST0pF
Q1RJT04QAhIMCghLRVlfT05MWRADIt8DCgVRdWVyeRJECgpwcm9qZWN0aW9uGAIgAygLMiQu
Z29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLlByb2plY3Rpb25SCnByb2plY3Rpb24SPAoEa2lu
ZBgDIAMoCzIoLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5LaW5kRXhwcmVzc2lvblIEa2lu
ZBI4CgZmaWx0ZXIYBCABKAsyIC5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRmlsdGVyUgZm
aWx0ZXISPQoFb3JkZXIYBSADKAsyJy5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUHJvcGVy
dHlPcmRlclIFb3JkZXISTAoLZGlzdGluY3Rfb24YBiADKAsyKy5nb29nbGUuZGF0YXN0b3Jl
LnYxYmV0YTMuUHJvcGVydHlSZWZlcmVuY2VSCmRpc3RpbmN0T24SIQoMc3RhcnRfY3Vyc29y
GAcgASgMUgtzdGFydEN1cnNvchIdCgplbmRfY3Vyc29yGAggASgMUgllbmRDdXJzb3ISFgoG
b2Zmc2V0GAogASgFUgZvZmZzZXQSMQoFbGltaXQYDCABKAsyGy5nb29nbGUucHJvdG9idWYu
SW50MzJWYWx1ZVIFbGltaXQiJAoOS2luZEV4cHJlc3Npb24SEgoEbmFtZRgBIAEoCVIEbmFt
ZSInChFQcm9wZXJ0eVJlZmVyZW5jZRISCgRuYW1lGAIgASgJUgRuYW1lIlUKClByb2plY3Rp
b24SRwoIcHJvcGVydHkYASABKAsyKy5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUHJvcGVy
dHlSZWZlcmVuY2VSCHByb3BlcnR5IvABCg1Qcm9wZXJ0eU9yZGVyEkcKCHByb3BlcnR5GAEg
ASgLMisuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLlByb3BlcnR5UmVmZXJlbmNlUghwcm9w
ZXJ0eRJPCglkaXJlY3Rpb24YAiABKA4yMS5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUHJv
cGVydHlPcmRlci5EaXJlY3Rpb25SCWRpcmVjdGlvbiJFCglEaXJlY3Rpb24SGQoVRElSRUNU
SU9OX1VOU1BFQ0lGSUVEEAASDQoJQVNDRU5ESU5HEAESDgoKREVTQ0VORElORxACIsQBCgZG
aWx0ZXISVgoQY29tcG9zaXRlX2ZpbHRlchgBIAEoCzIpLmdvb2dsZS5kYXRhc3RvcmUudjFi
ZXRhMy5Db21wb3NpdGVGaWx0ZXJIAFIPY29tcG9zaXRlRmlsdGVyElMKD3Byb3BlcnR5X2Zp
bHRlchgCIAEoCzIoLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5Qcm9wZXJ0eUZpbHRlckgA
Ug5wcm9wZXJ0eUZpbHRlckINCgtmaWx0ZXJfdHlwZSLAAQoPQ29tcG9zaXRlRmlsdGVyEkIK
Am9wGAEgASgOMjIuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkNvbXBvc2l0ZUZpbHRlci5P
cGVyYXRvclICb3ASOgoHZmlsdGVycxgCIAMoCzIgLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRh
My5GaWx0ZXJSB2ZpbHRlcnMiLQoIT3BlcmF0b3ISGAoUT1BFUkFUT1JfVU5TUEVDSUZJRUQQ
ABIHCgNBTkQQASLrAgoOUHJvcGVydHlGaWx0ZXISRwoIcHJvcGVydHkYASABKAsyKy5nb29n
bGUuZGF0YXN0b3JlLnYxYmV0YTMuUHJvcGVydHlSZWZlcmVuY2VSCHByb3BlcnR5EkEKAm9w
GAIgASgOMjEuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLlByb3BlcnR5RmlsdGVyLk9wZXJh
dG9yUgJvcBI1CgV2YWx1ZRgDIAEoCzIfLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5WYWx1
ZVIFdmFsdWUilQEKCE9wZXJhdG9yEhgKFE9QRVJBVE9SX1VOU1BFQ0lGSUVEEAASDQoJTEVT
U19USEFOEAESFgoSTEVTU19USEFOX09SX0VRVUFMEAISEAoMR1JFQVRFUl9USEFOEAMSGQoV
R1JFQVRFUl9USEFOX09SX0VRVUFMEAQSCQoFRVFVQUwQBRIQCgxIQVNfQU5DRVNUT1IQCyL/
AgoIR3FsUXVlcnkSIQoMcXVlcnlfc3RyaW5nGAEgASgJUgtxdWVyeVN0cmluZxIlCg5hbGxv
d19saXRlcmFscxgCIAEoCFINYWxsb3dMaXRlcmFscxJcCg5uYW1lZF9iaW5kaW5ncxgFIAMo
CzI1Lmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5HcWxRdWVyeS5OYW1lZEJpbmRpbmdzRW50
cnlSDW5hbWVkQmluZGluZ3MSXAoTcG9zaXRpb25hbF9iaW5kaW5ncxgEIAMoCzIrLmdvb2ds
ZS5kYXRhc3RvcmUudjFiZXRhMy5HcWxRdWVyeVBhcmFtZXRlclIScG9zaXRpb25hbEJpbmRp
bmdzGm0KEk5hbWVkQmluZGluZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJBCgV2YWx1ZRgC
IAEoCzIrLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5HcWxRdWVyeVBhcmFtZXRlclIFdmFs
dWU6AjgBIngKEUdxbFF1ZXJ5UGFyYW1ldGVyEjcKBXZhbHVlGAIgASgLMh8uZ29vZ2xlLmRh
dGFzdG9yZS52MWJldGEzLlZhbHVlSABSBXZhbHVlEhgKBmN1cnNvchgDIAEoDEgAUgZjdXJz
b3JCEAoOcGFyYW1ldGVyX3R5cGUi1gQKEFF1ZXJ5UmVzdWx0QmF0Y2gSJwoPc2tpcHBlZF9y
ZXN1bHRzGAYgASgFUg5za2lwcGVkUmVzdWx0cxIlCg5za2lwcGVkX2N1cnNvchgDIAEoDFIN
c2tpcHBlZEN1cnNvchJfChJlbnRpdHlfcmVzdWx0X3R5cGUYASABKA4yMS5nb29nbGUuZGF0
YXN0b3JlLnYxYmV0YTMuRW50aXR5UmVzdWx0LlJlc3VsdFR5cGVSEGVudGl0eVJlc3VsdFR5
cGUSTQoOZW50aXR5X3Jlc3VsdHMYAiADKAsyJi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMu
RW50aXR5UmVzdWx0Ug1lbnRpdHlSZXN1bHRzEh0KCmVuZF9jdXJzb3IYBCABKAxSCWVuZEN1
cnNvchJdCgxtb3JlX3Jlc3VsdHMYBSABKA4yOi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMu
UXVlcnlSZXN1bHRCYXRjaC5Nb3JlUmVzdWx0c1R5cGVSC21vcmVSZXN1bHRzEikKEHNuYXBz
aG90X3ZlcnNpb24YByABKANSD3NuYXBzaG90VmVyc2lvbiKYAQoPTW9yZVJlc3VsdHNUeXBl
EiEKHU1PUkVfUkVTVUxUU19UWVBFX1VOU1BFQ0lGSUVEEAASEAoMTk9UX0ZJTklTSEVEEAES
HAoYTU9SRV9SRVNVTFRTX0FGVEVSX0xJTUlUEAISHQoZTU9SRV9SRVNVTFRTX0FGVEVSX0NV
UlNPUhAEEhMKD05PX01PUkVfUkVTVUxUUxADQtQBChxjb20uZ29vZ2xlLmRhdGFzdG9yZS52
MWJldGEzQgpRdWVyeVByb3RvUAFaQGNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXN0b3JlL2Fw
aXYxYmV0YTMvZGF0YXN0b3JlcGI7ZGF0YXN0b3JlcGKqAh5Hb29nbGUuQ2xvdWQuRGF0YXN0
b3JlLlYxQmV0YTPKAh5Hb29nbGVcQ2xvdWRcRGF0YXN0b3JlXFYxYmV0YTPqAiFHb29nbGU6
OkNsb3VkOjpEYXRhc3RvcmU6OlYxYmV0YTNKxlMKBxIFDgC5AgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAvCgkK
AgMCEgMUACgKCQoCAwMSAxUAIgoICgEIEgMXADsKCQoCCCUSAxcAOwoICgEIEgMYAFcKCQoC
CAsSAxgAVwoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaACsKCQoCCAgSAxoAKwoICgEI
EgMbADUKCQoCCAESAxsANQoICgEIEgMcADsKCQoCCCkSAxwAOwoICgEIEgMdADoKCQoCCC0S
Ax0AOgo+CgIEABIEIABGARoyIFRoZSByZXN1bHQgb2YgZmV0Y2hpbmcgYW4gZW50aXR5IGZy
b20gRGF0YXN0b3JlLgoKCgoDBAABEgMgCBQK6QIKBAQABAASBCYCMgMa2gIgU3BlY2lmaWVz
IHdoYXQgZGF0YSB0aGUgJ2VudGl0eScgZmllbGQgY29udGFpbnMuCiBBIGBSZXN1bHRUeXBl
YCBpcyBlaXRoZXIgaW1wbGllZCAoZm9yIGV4YW1wbGUsIGluIGBMb29rdXBSZXNwb25zZS5t
aXNzaW5nYAogZnJvbSBgZGF0YXN0b3JlLnByb3RvYCwgaXQgaXMgYWx3YXlzIGBLRVlfT05M
WWApIG9yIHNwZWNpZmllZCBieSBjb250ZXh0CiAoZm9yIGV4YW1wbGUsIGluIG1lc3NhZ2Ug
YFF1ZXJ5UmVzdWx0QmF0Y2hgLCBmaWVsZCBgZW50aXR5X3Jlc3VsdF90eXBlYAogc3BlY2lm
aWVzIGEgYFJlc3VsdFR5cGVgIGZvciBhbGwgdGhlIHZhbHVlcyBpbiBmaWVsZCBgZW50aXR5
X3Jlc3VsdHNgKS4KCgwKBQQABAABEgMmBxEKNwoGBAAEAAIAEgMoBCAaKCBVbnNwZWNpZmll
ZC4gVGhpcyB2YWx1ZSBpcyBuZXZlciB1c2VkLgoKDgoHBAAEAAIAARIDKAQbCg4KBwQABAAC
AAISAygeHwooCgYEAAQAAgESAysEDRoZIFRoZSBrZXkgYW5kIHByb3BlcnRpZXMuCgoOCgcE
AAQAAgEBEgMrBAgKDgoHBAAEAAIBAhIDKwsMCk4KBgQABAACAhIDLgQTGj8gQSBwcm9qZWN0
ZWQgc3Vic2V0IG9mIHByb3BlcnRpZXMuIFRoZSBlbnRpdHkgbWF5IGhhdmUgbm8ga2V5LgoK
DgoHBAAEAAICARIDLgQOCg4KBwQABAACAgISAy4REgoeCgYEAAQAAgMSAzEEERoPIE9ubHkg
dGhlIGtleS4KCg4KBwQABAACAwESAzEEDAoOCgcEAAQAAgMCEgMxDxAKJAoEBAACABIDNQIU
GhcgVGhlIHJlc3VsdGluZyBlbnRpdHkuCgoMCgUEAAIABhIDNQIICgwKBQQAAgABEgM1CQ8K
DAoFBAACAAMSAzUSEwrQAwoEBAACARIDQQIUGsIDIFRoZSB2ZXJzaW9uIG9mIHRoZSBlbnRp
dHksIGEgc3RyaWN0bHkgcG9zaXRpdmUgbnVtYmVyIHRoYXQgbW9ub3RvbmljYWxseQogaW5j
cmVhc2VzIHdpdGggY2hhbmdlcyB0byB0aGUgZW50aXR5LgoKIFRoaXMgZmllbGQgaXMgc2V0
IGZvcgogW2BGVUxMYF1bZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkVudGl0eVJlc3VsdC5S
ZXN1bHRUeXBlLkZVTExdIGVudGl0eQogcmVzdWx0cy4KCiBGb3IgW21pc3NpbmddW2dvb2ds
ZS5kYXRhc3RvcmUudjFiZXRhMy5Mb29rdXBSZXNwb25zZS5taXNzaW5nXSBlbnRpdGllcyBp
bgogYExvb2t1cFJlc3BvbnNlYCwgdGhpcyBpcyB0aGUgdmVyc2lvbiBvZiB0aGUgc25hcHNo
b3QgdGhhdCB3YXMgdXNlZCB0byBsb29rCiB1cCB0aGUgZW50aXR5LCBhbmQgaXQgaXMgYWx3
YXlzIHNldCBleGNlcHQgZm9yIGV2ZW50dWFsbHkgY29uc2lzdGVudCByZWFkcy4KCgwKBQQA
AgEFEgNBAgcKDAoFBAACAQESA0EIDwoMCgUEAAIBAxIDQRITCpgBCgQEAAICEgNFAhMaigEg
QSBjdXJzb3IgdGhhdCBwb2ludHMgdG8gdGhlIHBvc2l0aW9uIGFmdGVyIHRoZSByZXN1bHQg
ZW50aXR5LgogU2V0IG9ubHkgd2hlbiB0aGUgYEVudGl0eVJlc3VsdGAgaXMgcGFydCBvZiBh
IGBRdWVyeVJlc3VsdEJhdGNoYCBtZXNzYWdlLgoKDAoFBAACAgUSA0UCBwoMCgUEAAICARID
RQgOCgwKBQQAAgIDEgNFERIKIwoCBAESBEkAcQEaFyBBIHF1ZXJ5IGZvciBlbnRpdGllcy4K
CgoKAwQBARIDSQgNCk4KBAQBAgASA0sCJRpBIFRoZSBwcm9qZWN0aW9uIHRvIHJldHVybi4g
RGVmYXVsdHMgdG8gcmV0dXJuaW5nIGFsbCBwcm9wZXJ0aWVzLgoKDAoFBAECAAQSA0sCCgoM
CgUEAQIABhIDSwsVCgwKBQQBAgABEgNLFiAKDAoFBAECAAMSA0sjJAp4CgQEAQIBEgNPAiMa
ayBUaGUga2luZHMgdG8gcXVlcnkgKGlmIGVtcHR5LCByZXR1cm5zIGVudGl0aWVzIG9mIGFs
bCBraW5kcykuCiBDdXJyZW50bHkgYXQgbW9zdCAxIGtpbmQgbWF5IGJlIHNwZWNpZmllZC4K
CgwKBQQBAgEEEgNPAgoKDAoFBAECAQYSA08LGQoMCgUEAQIBARIDTxoeCgwKBQQBAgEDEgNP
ISIKIwoEBAECAhIDUgIUGhYgVGhlIGZpbHRlciB0byBhcHBseS4KCgwKBQQBAgIGEgNSAggK
DAoFBAECAgESA1IJDwoMCgUEAQICAxIDUhITClgKBAQBAgMSA1UCIxpLIFRoZSBvcmRlciB0
byBhcHBseSB0byB0aGUgcXVlcnkgcmVzdWx0cyAoaWYgZW1wdHksIG9yZGVyIGlzIHVuc3Bl
Y2lmaWVkKS4KCgwKBQQBAgMEEgNVAgoKDAoFBAECAwYSA1ULGAoMCgUEAQIDARIDVRkeCgwK
BQQBAgMDEgNVISIKyQEKBAQBAgQSA1oCLRq7ASBUaGUgcHJvcGVydGllcyB0byBtYWtlIGRp
c3RpbmN0LiBUaGUgcXVlcnkgcmVzdWx0cyB3aWxsIGNvbnRhaW4gdGhlIGZpcnN0CiByZXN1
bHQgZm9yIGVhY2ggZGlzdGluY3QgY29tYmluYXRpb24gb2YgdmFsdWVzIGZvciB0aGUgZ2l2
ZW4gcHJvcGVydGllcwogKGlmIGVtcHR5LCBhbGwgcmVzdWx0cyBhcmUgcmV0dXJuZWQpLgoK
DAoFBAECBAQSA1oCCgoMCgUEAQIEBhIDWgscCgwKBQQBAgQBEgNaHSgKDAoFBAECBAMSA1or
LAr1AQoEBAECBRIDYAIZGucBIEEgc3RhcnRpbmcgcG9pbnQgZm9yIHRoZSBxdWVyeSByZXN1
bHRzLiBRdWVyeSBjdXJzb3JzIGFyZQogcmV0dXJuZWQgaW4gcXVlcnkgcmVzdWx0IGJhdGNo
ZXMgYW5kCiBbY2FuIG9ubHkgYmUgdXNlZCB0byBjb250aW51ZSB0aGUgc2FtZQogcXVlcnld
KGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhc3RvcmUvZG9jcy9jb25jZXB0cy9xdWVy
aWVzI2N1cnNvcnNfbGltaXRzX2FuZF9vZmZzZXRzKS4KCgwKBQQBAgUFEgNgAgcKDAoFBAEC
BQESA2AIFAoMCgUEAQIFAxIDYBcYCvEBCgQEAQIGEgNmAhca4wEgQW4gZW5kaW5nIHBvaW50
IGZvciB0aGUgcXVlcnkgcmVzdWx0cy4gUXVlcnkgY3Vyc29ycyBhcmUKIHJldHVybmVkIGlu
IHF1ZXJ5IHJlc3VsdCBiYXRjaGVzIGFuZAogW2NhbiBvbmx5IGJlIHVzZWQgdG8gbGltaXQg
dGhlIHNhbWUKIHF1ZXJ5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXN0b3JlL2Rv
Y3MvY29uY2VwdHMvcXVlcmllcyNjdXJzb3JzX2xpbWl0c19hbmRfb2Zmc2V0cykuCgoMCgUE
AQIGBRIDZgIHCgwKBQQBAgYBEgNmCBIKDAoFBAECBgMSA2YVFgqKAQoEBAECBxIDagIUGn0g
VGhlIG51bWJlciBvZiByZXN1bHRzIHRvIHNraXAuIEFwcGxpZXMgYmVmb3JlIGxpbWl0LCBi
dXQgYWZ0ZXIgYWxsIG90aGVyCiBjb25zdHJhaW50cy4gT3B0aW9uYWwuIE11c3QgYmUgPj0g
MCBpZiBzcGVjaWZpZWQuCgoMCgUEAQIHBRIDagIHCgwKBQQBAgcBEgNqCA4KDAoFBAECBwMS
A2oREwqtAQoEBAECCBIDcAIoGp8BIFRoZSBtYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRv
IHJldHVybi4gQXBwbGllcyBhZnRlciBhbGwgb3RoZXIKIGNvbnN0cmFpbnRzLiBPcHRpb25h
bC4KIFVuc3BlY2lmaWVkIGlzIGludGVycHJldGVkIGFzIG5vIGxpbWl0LgogTXVzdCBiZSA+
PSAwIGlmIHNwZWNpZmllZC4KCgwKBQQBAggGEgNwAhwKDAoFBAECCAESA3AdIgoMCgUEAQII
AxIDcCUnCikKAgQCEgR0AHcBGh0gQSByZXByZXNlbnRhdGlvbiBvZiBhIGtpbmQuCgoKCgME
AgESA3QIFgokCgQEAgIAEgN2AhIaFyBUaGUgbmFtZSBvZiB0aGUga2luZC4KCgwKBQQCAgAF
EgN2AggKDAoFBAICAAESA3YJDQoMCgUEAgIAAxIDdhARCkkKAgQDEgR6AH4BGj0gQSByZWZl
cmVuY2UgdG8gYSBwcm9wZXJ0eSByZWxhdGl2ZSB0byB0aGUga2luZCBleHByZXNzaW9ucy4K
CgoKAwQDARIDeggZCm8KBAQDAgASA30CEhpiIFRoZSBuYW1lIG9mIHRoZSBwcm9wZXJ0eS4K
IElmIG5hbWUgaW5jbHVkZXMgIi4icywgaXQgbWF5IGJlIGludGVycHJldGVkIGFzIGEgcHJv
cGVydHkgbmFtZSBwYXRoLgoKDAoFBAMCAAUSA30CCAoMCgUEAwIAARIDfQkNCgwKBQQDAgAD
EgN9EBEKPwoCBAQSBoEBAIQBARoxIEEgcmVwcmVzZW50YXRpb24gb2YgYSBwcm9wZXJ0eSBp
biBhIHByb2plY3Rpb24uCgoLCgMEBAESBIEBCBIKKAoEBAQCABIEgwECIRoaIFRoZSBwcm9w
ZXJ0eSB0byBwcm9qZWN0LgoKDQoFBAQCAAYSBIMBAhMKDQoFBAQCAAESBIMBFBwKDQoFBAQC
AAMSBIMBHyAKOgoCBAUSBocBAJkBARosIFRoZSBkZXNpcmVkIG9yZGVyIGZvciBhIHNwZWNp
ZmljIHByb3BlcnR5LgoKCwoDBAUBEgSHAQgVCiUKBAQFBAASBokBApIBAxoVIFRoZSBzb3J0
IGRpcmVjdGlvbi4KCg0KBQQFBAABEgSJAQcQCjsKBgQFBAACABIEiwEEHhorIFVuc3BlY2lm
aWVkLiBUaGlzIHZhbHVlIG11c3Qgbm90IGJlIHVzZWQuCgoPCgcEBQQAAgABEgSLAQQZCg8K
BwQFBAACAAISBIsBHB0KHAoGBAUEAAIBEgSOAQQSGgwgQXNjZW5kaW5nLgoKDwoHBAUEAAIB
ARIEjgEEDQoPCgcEBQQAAgECEgSOARARCh0KBgQFBAACAhIEkQEEExoNIERlc2NlbmRpbmcu
CgoPCgcEBQQAAgIBEgSRAQQOCg8KBwQFBAACAgISBJEBERIKKQoEBAUCABIElQECIRobIFRo
ZSBwcm9wZXJ0eSB0byBvcmRlciBieS4KCg0KBQQFAgAGEgSVAQITCg0KBQQFAgABEgSVARQc
Cg0KBQQFAgADEgSVAR8gCkMKBAQFAgESBJgBAhoaNSBUaGUgZGlyZWN0aW9uIHRvIG9yZGVy
IGJ5LiBEZWZhdWx0cyB0byBgQVNDRU5ESU5HYC4KCg0KBQQFAgEGEgSYAQILCg0KBQQFAgEB
EgSYAQwVCg0KBQQFAgEDEgSYARgZCjAKAgQGEgacAQClAQEaIiBBIGhvbGRlciBmb3IgYW55
IHR5cGUgb2YgZmlsdGVyLgoKCwoDBAYBEgScAQgOCiUKBAQGCAASBp4BAqQBAxoVIFRoZSB0
eXBlIG9mIGZpbHRlci4KCg0KBQQGCAABEgSeAQgTCiMKBAQGAgASBKABBCkaFSBBIGNvbXBv
c2l0ZSBmaWx0ZXIuCgoNCgUEBgIABhIEoAEEEwoNCgUEBgIAARIEoAEUJAoNCgUEBgIAAxIE
oAEnKAonCgQEBgIBEgSjAQQnGhkgQSBmaWx0ZXIgb24gYSBwcm9wZXJ0eS4KCg0KBQQGAgEG
EgSjAQQSCg0KBQQGAgEBEgSjARMiCg0KBQQGAgEDEgSjASUmClUKAgQHEgaoAQC4AQEaRyBB
IGZpbHRlciB0aGF0IG1lcmdlcyBtdWx0aXBsZSBvdGhlciBmaWx0ZXJzIHVzaW5nIHRoZSBn
aXZlbiBvcGVyYXRvci4KCgsKAwQHARIEqAEIFwouCgQEBwQAEgaqAQKwAQMaHiBBIGNvbXBv
c2l0ZSBmaWx0ZXIgb3BlcmF0b3IuCgoNCgUEBwQAARIEqgEHDwo7CgYEBwQAAgASBKwBBB0a
KyBVbnNwZWNpZmllZC4gVGhpcyB2YWx1ZSBtdXN0IG5vdCBiZSB1c2VkLgoKDwoHBAcEAAIA
ARIErAEEGAoPCgcEBwQAAgACEgSsARscClMKBgQHBAACARIErwEEDBpDIFRoZSByZXN1bHRz
IGFyZSByZXF1aXJlZCB0byBzYXRpc2Z5IGVhY2ggb2YgdGhlIGNvbWJpbmVkIGZpbHRlcnMu
CgoPCgcEBwQAAgEBEgSvAQQHCg8KBwQHBAACAQISBK8BCgsKPAoEBAcCABIEswECEhouIFRo
ZSBvcGVyYXRvciBmb3IgY29tYmluaW5nIG11bHRpcGxlIGZpbHRlcnMuCgoNCgUEBwIABhIE
swECCgoNCgUEBwIAARIEswELDQoNCgUEBwIAAxIEswEQEQpSCgQEBwIBEgS3AQIeGkQgVGhl
IGxpc3Qgb2YgZmlsdGVycyB0byBjb21iaW5lLgogTXVzdCBjb250YWluIGF0IGxlYXN0IG9u
ZSBmaWx0ZXIuCgoNCgUEBwIBBBIEtwECCgoNCgUEBwIBBhIEtwELEQoNCgUEBwIBARIEtwES
GQoNCgUEBwIBAxIEtwEcHQowCgIECBIGuwEA3AEBGiIgQSBmaWx0ZXIgb24gYSBzcGVjaWZp
YyBwcm9wZXJ0eS4KCgsKAwQIARIEuwEIFgotCgQECAQAEga9AQLSAQMaHSBBIHByb3BlcnR5
IGZpbHRlciBvcGVyYXRvci4KCg0KBQQIBAABEgS9AQcPCjsKBgQIBAACABIEvwEEHRorIFVu
c3BlY2lmaWVkLiBUaGlzIHZhbHVlIG11c3Qgbm90IGJlIHVzZWQuCgoPCgcECAQAAgABEgS/
AQQYCg8KBwQIBAACAAISBL8BGxwKHAoGBAgEAAIBEgTCAQQSGgwgTGVzcyB0aGFuLgoKDwoH
BAgEAAIBARIEwgEEDQoPCgcECAQAAgECEgTCARARCiUKBgQIBAACAhIExQEEGxoVIExlc3Mg
dGhhbiBvciBlcXVhbC4KCg8KBwQIBAACAgESBMUBBBYKDwoHBAgEAAICAhIExQEZGgofCgYE
CAQAAgMSBMgBBBUaDyBHcmVhdGVyIHRoYW4uCgoPCgcECAQAAgMBEgTIAQQQCg8KBwQIBAAC
AwISBMgBExQKKAoGBAgEAAIEEgTLAQQeGhggR3JlYXRlciB0aGFuIG9yIGVxdWFsLgoKDwoH
BAgEAAIEARIEywEEGQoPCgcECAQAAgQCEgTLARwdChgKBgQIBAACBRIEzgEEDhoIIEVxdWFs
LgoKDwoHBAgEAAIFARIEzgEECQoPCgcECAQAAgUCEgTOAQwNCh8KBgQIBAACBhIE0QEEFhoP
IEhhcyBhbmNlc3Rvci4KCg8KBwQIBAACBgESBNEBBBAKDwoHBAgEAAIGAhIE0QETFQoqCgQE
CAIAEgTVAQIhGhwgVGhlIHByb3BlcnR5IHRvIGZpbHRlciBieS4KCg0KBQQIAgAGEgTVAQIT
Cg0KBQQIAgABEgTVARQcCg0KBQQIAgADEgTVAR8gCioKBAQIAgESBNgBAhIaHCBUaGUgb3Bl
cmF0b3IgdG8gZmlsdGVyIGJ5LgoKDQoFBAgCAQYSBNgBAgoKDQoFBAgCAQESBNgBCw0KDQoF
BAgCAQMSBNgBEBEKNQoEBAgCAhIE2wECEhonIFRoZSB2YWx1ZSB0byBjb21wYXJlIHRoZSBw
cm9wZXJ0eSB0by4KCg0KBQQIAgIGEgTbAQIHCg0KBQQIAgIBEgTbAQgNCg0KBQQIAgIDEgTb
ARARCl8KAgQJEgbgAQD4AQEaUSBBIFtHUUwKIHF1ZXJ5XShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vZGF0YXN0b3JlL2RvY3MvYXBpcy9ncWwvZ3FsX3JlZmVyZW5jZSkuCgoLCgMECQES
BOABCBAKeQoEBAkCABIE4wECGhprIEEgc3RyaW5nIG9mIHRoZSBmb3JtYXQgZGVzY3JpYmVk
CiBbaGVyZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RhdGFzdG9yZS9kb2NzL2FwaXMv
Z3FsL2dxbF9yZWZlcmVuY2UpLgoKDQoFBAkCAAUSBOMBAggKDQoFBAkCAAESBOMBCRUKDQoF
BAkCAAMSBOMBGBkK7QEKBAQJAgESBOkBAhoa3gEgV2hlbiBmYWxzZSwgdGhlIHF1ZXJ5IHN0
cmluZyBtdXN0IG5vdCBjb250YWluIGFueSBsaXRlcmFscyBhbmQgaW5zdGVhZCBtdXN0CiBi
aW5kIGFsbCB2YWx1ZXMuIEZvciBleGFtcGxlLAogYFNFTEVDVCAqIEZST00gS2luZCBXSEVS
RSBhID0gJ3N0cmluZyBsaXRlcmFsJ2AgaXMgbm90IGFsbG93ZWQsIHdoaWxlCiBgU0VMRUNU
ICogRlJPTSBLaW5kIFdIRVJFIGEgPSBAdmFsdWVgIGlzLgoKDQoFBAkCAQUSBOkBAgYKDQoF
BAkCAQESBOkBBxUKDQoFBAkCAQMSBOkBGBkKiQIKBAQJAgISBPABAjQa+gEgRm9yIGVhY2gg
bm9uLXJlc2VydmVkIG5hbWVkIGJpbmRpbmcgc2l0ZSBpbiB0aGUgcXVlcnkgc3RyaW5nLCB0
aGVyZSBtdXN0IGJlCiBhIG5hbWVkIHBhcmFtZXRlciB3aXRoIHRoYXQgbmFtZSwgYnV0IG5v
dCBuZWNlc3NhcmlseSB0aGUgaW52ZXJzZS4KCiBLZXkgbXVzdCBtYXRjaCByZWdleCBgW0Et
WmEtel8kXVtBLVphLXpfJDAtOV0qYCwgbXVzdCBub3QgbWF0Y2ggcmVnZXgKIGBfXy4qX19g
LCBhbmQgbXVzdCBub3QgYmUgYCIiYC4KCg0KBQQJAgIGEgTwAQIgCg0KBQQJAgIBEgTwASEv
Cg0KBQQJAgIDEgTwATIzCpACCgQECQIDEgT3AQI1GoECIE51bWJlcmVkIGJpbmRpbmcgc2l0
ZSBAMSByZWZlcmVuY2VzIHRoZSBmaXJzdCBudW1iZXJlZCBwYXJhbWV0ZXIsCiBlZmZlY3Rp
dmVseSB1c2luZyAxLWJhc2VkIGluZGV4aW5nLCByYXRoZXIgdGhhbiB0aGUgdXN1YWwgMC4K
CiBGb3IgZWFjaCBiaW5kaW5nIHNpdGUgbnVtYmVyZWQgaSBpbiBgcXVlcnlfc3RyaW5nYCwg
dGhlcmUgbXVzdCBiZSBhbiBpLXRoCiBudW1iZXJlZCBwYXJhbWV0ZXIuIFRoZSBpbnZlcnNl
IG11c3QgYWxzbyBiZSB0cnVlLgoKDQoFBAkCAwQSBPcBAgoKDQoFBAkCAwYSBPcBCxwKDQoF
BAkCAwESBPcBHTAKDQoFBAkCAwMSBPcBMzQKNAoCBAoSBvsBAIUCARomIEEgYmluZGluZyBw
YXJhbWV0ZXIgZm9yIGEgR1FMIHF1ZXJ5LgoKCwoDBAoBEgT7AQgZCigKBAQKCAASBv0BAoQC
AxoYIFRoZSB0eXBlIG9mIHBhcmFtZXRlci4KCg0KBQQKCAABEgT9AQgWCiIKBAQKAgASBP8B
BBQaFCBBIHZhbHVlIHBhcmFtZXRlci4KCg0KBQQKAgAGEgT/AQQJCg0KBQQKAgABEgT/AQoP
Cg0KBQQKAgADEgT/ARITClQKBAQKAgESBIMCBBUaRiBBIHF1ZXJ5IGN1cnNvci4gUXVlcnkg
Y3Vyc29ycyBhcmUgcmV0dXJuZWQgaW4gcXVlcnkKIHJlc3VsdCBiYXRjaGVzLgoKDQoFBAoC
AQUSBIMCBAkKDQoFBAoCAQESBIMCChAKDQoFBAoCAQMSBIMCExQKNwoCBAsSBogCALkCARop
IEEgYmF0Y2ggb2YgcmVzdWx0cyBwcm9kdWNlZCBieSBhIHF1ZXJ5LgoKCwoDBAsBEgSIAggY
CkMKBAQLBAASBooCApoCAxozIFRoZSBwb3NzaWJsZSB2YWx1ZXMgZm9yIHRoZSBgbW9yZV9y
ZXN1bHRzYCBmaWVsZC4KCg0KBQQLBAABEgSKAgcWCjgKBgQLBAACABIEjAIEJhooIFVuc3Bl
Y2lmaWVkLiBUaGlzIHZhbHVlIGlzIG5ldmVyIHVzZWQuCgoPCgcECwQAAgABEgSMAgQhCg8K
BwQLBAACAAISBIwCJCUKSwoGBAsEAAIBEgSPAgQVGjsgVGhlcmUgbWF5IGJlIGFkZGl0aW9u
YWwgYmF0Y2hlcyB0byBmZXRjaCBmcm9tIHRoaXMgcXVlcnkuCgoPCgcECwQAAgEBEgSPAgQQ
Cg8KBwQLBAACAQISBI8CExQKVwoGBAsEAAICEgSSAgQhGkcgVGhlIHF1ZXJ5IGlzIGZpbmlz
aGVkLCBidXQgdGhlcmUgbWF5IGJlIG1vcmUgcmVzdWx0cyBhZnRlciB0aGUgbGltaXQuCgoP
CgcECwQAAgIBEgSSAgQcCg8KBwQLBAACAgISBJICHyAKXQoGBAsEAAIDEgSWAgQiGk0gVGhl
IHF1ZXJ5IGlzIGZpbmlzaGVkLCBidXQgdGhlcmUgbWF5IGJlIG1vcmUgcmVzdWx0cyBhZnRl
ciB0aGUgZW5kCiBjdXJzb3IuCgoPCgcECwQAAgMBEgSWAgQdCg8KBwQLBAACAwISBJYCICEK
RwoGBAsEAAIEEgSZAgQYGjcgVGhlIHF1ZXJ5IGlzIGZpbmlzaGVkLCBhbmQgdGhlcmUgYXJl
IG5vIG1vcmUgcmVzdWx0cy4KCg8KBwQLBAACBAESBJkCBBMKDwoHBAsEAAIEAhIEmQIWFwpO
CgQECwIAEgSdAgIcGkAgVGhlIG51bWJlciBvZiByZXN1bHRzIHNraXBwZWQsIHR5cGljYWxs
eSBiZWNhdXNlIG9mIGFuIG9mZnNldC4KCg0KBQQLAgAFEgSdAgIHCg0KBQQLAgABEgSdAggX
Cg0KBQQLAgADEgSdAhobCn0KBAQLAgESBKECAhsabyBBIGN1cnNvciB0aGF0IHBvaW50cyB0
byB0aGUgcG9zaXRpb24gYWZ0ZXIgdGhlIGxhc3Qgc2tpcHBlZCByZXN1bHQuCiBXaWxsIGJl
IHNldCB3aGVuIGBza2lwcGVkX3Jlc3VsdHNgICE9IDAuCgoNCgUECwIBBRIEoQICBwoNCgUE
CwIBARIEoQIIFgoNCgUECwIBAxIEoQIZGgpFCgQECwICEgSkAgIxGjcgVGhlIHJlc3VsdCB0
eXBlIGZvciBldmVyeSBlbnRpdHkgaW4gYGVudGl0eV9yZXN1bHRzYC4KCg0KBQQLAgIGEgSk
AgIZCg0KBQQLAgIBEgSkAhosCg0KBQQLAgIDEgSkAi8wCisKBAQLAgMSBKcCAisaHSBUaGUg
cmVzdWx0cyBmb3IgdGhpcyBiYXRjaC4KCg0KBQQLAgMEEgSnAgIKCg0KBQQLAgMGEgSnAgsX
Cg0KBQQLAgMBEgSnAhgmCg0KBQQLAgMDEgSnAikqClgKBAQLAgQSBKoCAhcaSiBBIGN1cnNv
ciB0aGF0IHBvaW50cyB0byB0aGUgcG9zaXRpb24gYWZ0ZXIgdGhlIGxhc3QgcmVzdWx0IGlu
IHRoZSBiYXRjaC4KCg0KBQQLAgQFEgSqAgIHCg0KBQQLAgQBEgSqAggSCg0KBQQLAgQDEgSq
AhUWCj8KBAQLAgUSBK0CAiMaMSBUaGUgc3RhdGUgb2YgdGhlIHF1ZXJ5IGFmdGVyIHRoZSBj
dXJyZW50IGJhdGNoLgoKDQoFBAsCBQYSBK0CAhEKDQoFBAsCBQESBK0CEh4KDQoFBAsCBQMS
BK0CISIKhgQKBAQLAgYSBLgCAh0a9wMgVGhlIHZlcnNpb24gbnVtYmVyIG9mIHRoZSBzbmFw
c2hvdCB0aGlzIGJhdGNoIHdhcyByZXR1cm5lZCBmcm9tLgogVGhpcyBhcHBsaWVzIHRvIHRo
ZSByYW5nZSBvZiByZXN1bHRzIGZyb20gdGhlIHF1ZXJ5J3MgYHN0YXJ0X2N1cnNvcmAgKG9y
CiB0aGUgYmVnaW5uaW5nIG9mIHRoZSBxdWVyeSBpZiBubyBjdXJzb3Igd2FzIGdpdmVuKSB0
byB0aGlzIGJhdGNoJ3MKIGBlbmRfY3Vyc29yYCAobm90IHRoZSBxdWVyeSdzIGBlbmRfY3Vy
c29yYCkuCgogSW4gYSBzaW5nbGUgdHJhbnNhY3Rpb24sIHN1YnNlcXVlbnQgcXVlcnkgcmVz
dWx0IGJhdGNoZXMgZm9yIHRoZSBzYW1lIHF1ZXJ5CiBjYW4gaGF2ZSBhIGdyZWF0ZXIgc25h
cHNob3QgdmVyc2lvbiBudW1iZXIuIEVhY2ggYmF0Y2gncyBzbmFwc2hvdCB2ZXJzaW9uCiBp
cyB2YWxpZCBmb3IgYWxsIHByZWNlZGluZyBiYXRjaGVzLgogVGhlIHZhbHVlIHdpbGwgYmUg
emVybyBmb3IgZXZlbnR1YWxseSBjb25zaXN0ZW50IHF1ZXJpZXMuCgoNCgUECwIGBRIEuAIC
BwoNCgUECwIGARIEuAIIGAoNCgUECwIGAxIEuAIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1beta3::Query::EntityResult ===
    # Fields for EntityResult
    # Field: entity Type: 11 (.google.datastore.v1beta3.Entity)
    # Field: version Type: 3 ()
    # Field: cursor Type: 12 ()

# Enum: EntityResult::ResultType
our $EntityResult_RESULT_TYPE_UNSPECIFIED = 0;
our $EntityResult_FULL = 1;
our $EntityResult_PROJECTION = 2;
our $EntityResult_KEY_ONLY = 3;

# === Message: Google::Datastore::V1beta3::Query::Query ===
    # Fields for Query
    # Field: projection Type: 11 (.google.datastore.v1beta3.Projection)
    # Field: kind Type: 11 (.google.datastore.v1beta3.KindExpression)
    # Field: filter Type: 11 (.google.datastore.v1beta3.Filter)
    # Field: order Type: 11 (.google.datastore.v1beta3.PropertyOrder)
    # Field: distinct_on Type: 11 (.google.datastore.v1beta3.PropertyReference)
    # Field: start_cursor Type: 12 ()
    # Field: end_cursor Type: 12 ()
    # Field: offset Type: 5 ()
    # Field: limit Type: 11 (.google.protobuf.Int32Value)

# === Message: Google::Datastore::V1beta3::Query::KindExpression ===
    # Fields for KindExpression
    # Field: name Type: 9 ()

# === Message: Google::Datastore::V1beta3::Query::PropertyReference ===
    # Fields for PropertyReference
    # Field: name Type: 9 ()

# === Message: Google::Datastore::V1beta3::Query::Projection ===
    # Fields for Projection
    # Field: property Type: 11 (.google.datastore.v1beta3.PropertyReference)

# === Message: Google::Datastore::V1beta3::Query::PropertyOrder ===
    # Fields for PropertyOrder
    # Field: property Type: 11 (.google.datastore.v1beta3.PropertyReference)
    # Field: direction Type: 14 (.google.datastore.v1beta3.PropertyOrder.Direction)

# Enum: PropertyOrder::Direction
our $PropertyOrder_DIRECTION_UNSPECIFIED = 0;
our $PropertyOrder_ASCENDING = 1;
our $PropertyOrder_DESCENDING = 2;

# === Message: Google::Datastore::V1beta3::Query::Filter ===
    # Fields for Filter
    # Field: composite_filter Type: 11 (.google.datastore.v1beta3.CompositeFilter)
    # Field: property_filter Type: 11 (.google.datastore.v1beta3.PropertyFilter)

# === Message: Google::Datastore::V1beta3::Query::CompositeFilter ===
    # Fields for CompositeFilter
    # Field: op Type: 14 (.google.datastore.v1beta3.CompositeFilter.Operator)
    # Field: filters Type: 11 (.google.datastore.v1beta3.Filter)

# Enum: CompositeFilter::Operator
our $CompositeFilter_OPERATOR_UNSPECIFIED = 0;
our $CompositeFilter_AND = 1;

# === Message: Google::Datastore::V1beta3::Query::PropertyFilter ===
    # Fields for PropertyFilter
    # Field: property Type: 11 (.google.datastore.v1beta3.PropertyReference)
    # Field: op Type: 14 (.google.datastore.v1beta3.PropertyFilter.Operator)
    # Field: value Type: 11 (.google.datastore.v1beta3.Value)

# Enum: PropertyFilter::Operator
our $PropertyFilter_OPERATOR_UNSPECIFIED = 0;
our $PropertyFilter_LESS_THAN = 1;
our $PropertyFilter_LESS_THAN_OR_EQUAL = 2;
our $PropertyFilter_GREATER_THAN = 3;
our $PropertyFilter_GREATER_THAN_OR_EQUAL = 4;
our $PropertyFilter_EQUAL = 5;
our $PropertyFilter_HAS_ANCESTOR = 11;

# === Message: Google::Datastore::V1beta3::Query::GqlQuery ===
    # Fields for GqlQuery
    # Field: query_string Type: 9 ()
    # Field: allow_literals Type: 8 ()
    # Field: named_bindings Type: 11 (.google.datastore.v1beta3.GqlQuery.NamedBindingsEntry)
    # Field: positional_bindings Type: 11 (.google.datastore.v1beta3.GqlQueryParameter)

# === Message: Google::Datastore::V1beta3::Query::GqlQueryParameter ===
    # Fields for GqlQueryParameter
    # Field: value Type: 11 (.google.datastore.v1beta3.Value)
    # Field: cursor Type: 12 ()

# === Message: Google::Datastore::V1beta3::Query::QueryResultBatch ===
    # Fields for QueryResultBatch
    # Field: skipped_results Type: 5 ()
    # Field: skipped_cursor Type: 12 ()
    # Field: entity_result_type Type: 14 (.google.datastore.v1beta3.EntityResult.ResultType)
    # Field: entity_results Type: 11 (.google.datastore.v1beta3.EntityResult)
    # Field: end_cursor Type: 12 ()
    # Field: more_results Type: 14 (.google.datastore.v1beta3.QueryResultBatch.MoreResultsType)
    # Field: snapshot_version Type: 3 ()

# Enum: QueryResultBatch::MoreResultsType
our $QueryResultBatch_MORE_RESULTS_TYPE_UNSPECIFIED = 0;
our $QueryResultBatch_NOT_FINISHED = 1;
our $QueryResultBatch_MORE_RESULTS_AFTER_LIMIT = 2;
our $QueryResultBatch_MORE_RESULTS_AFTER_CURSOR = 4;
our $QueryResultBatch_NO_MORE_RESULTS = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1beta3::Query - Compiled Protocol Buffers messages for google/datastore/v1beta3/query.proto

=head1 SYNOPSIS

    use Google::Datastore::V1beta3::Query;

    my $msg = Google::Datastore::V1beta3::Query::EntityResult->new({
        entity => $entity,
        version => $version,
        cursor => $cursor,
    });

    # Read or update a field
    my $val = $msg->entity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1beta3::Query::EntityResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1beta3/query.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1beta3::Query::EntityResult

The result of fetching an entity from Datastore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity>)

The resulting entity.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Int64>

The version of the entity, a strictly positive number that monotonically
increases with changes to the entity.

This field is set for
[`FULL`][google.datastore.v1beta3.EntityResult.ResultType.FULL] entity
results.

For [missing][google.datastore.v1beta3.LookupResponse.missing] entities in
`LookupResponse`, this is the version of the snapshot that was used to look
up the entity, and it is always set except for eventually consistent reads.

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Bytes>

A cursor that points to the position after the result entity.
Set only when the `EntityResult` is part of a `QueryResultBatch` message.

=back

=head3 Enum: EntityResult::ResultType

=over 4

=item * C<RESULT_TYPE_UNSPECIFIED> => C<0>

=item * C<FULL> => C<1>

=item * C<PROJECTION> => C<2>

=item * C<KEY_ONLY> => C<3>

=back

=head2 Google::Datastore::V1beta3::Query::Query

A query for entities.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->projection() >> / C<< $msg->projection($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::Projection>)

The projection to return. Defaults to returning all properties.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::KindExpression>)

The kinds to query (if empty, returns entities of all kinds).
Currently at most 1 kind may be specified.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::Filter>)

The filter to apply.

=item * C<< $msg->order() >> / C<< $msg->order($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyOrder>)

The order to apply to the query results (if empty, order is unspecified).

=item * C<< $msg->distinct_on() >> / C<< $msg->distinct_on($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyReference>)

The properties to make distinct. The query results will contain the first
result for each distinct combination of values for the given properties
(if empty, all results are returned).

=item * C<< $msg->start_cursor() >> / C<< $msg->start_cursor($value) >>

Type: C<Bytes>

A starting point for the query results. Query cursors are
returned in query result batches and
[can only be used to continue the same
query](https://cloud.google.com/datastore/docs/concepts/queries#cursors_limits_and_offsets).

=item * C<< $msg->end_cursor() >> / C<< $msg->end_cursor($value) >>

Type: C<Bytes>

An ending point for the query results. Query cursors are
returned in query result batches and
[can only be used to limit the same
query](https://cloud.google.com/datastore/docs/concepts/queries#cursors_limits_and_offsets).

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int32>

The number of results to skip. Applies before limit, but after all other
constraints. Optional. Must be >= 0 if specified.

=item * C<< $msg->limit() >> / C<< $msg->limit($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

The maximum number of results to return. Applies after all other
constraints. Optional.
Unspecified is interpreted as no limit.
Must be >= 0 if specified.

=back

=head2 Google::Datastore::V1beta3::Query::KindExpression

A representation of a kind.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the kind.

=back

=head2 Google::Datastore::V1beta3::Query::PropertyReference

A reference to a property relative to the kind expressions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the property.
If name includes "."s, it may be interpreted as a property name path.

=back

=head2 Google::Datastore::V1beta3::Query::Projection

A representation of a property in a projection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyReference>)

The property to project.

=back

=head2 Google::Datastore::V1beta3::Query::PropertyOrder

The desired order for a specific property.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyReference>)

The property to order by.

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::PropertyOrder::Direction>)

The direction to order by. Defaults to `ASCENDING`.

=back

=head3 Enum: PropertyOrder::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<ASCENDING> => C<1>

=item * C<DESCENDING> => C<2>

=back

=head2 Google::Datastore::V1beta3::Query::Filter

A holder for any type of filter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->composite_filter() >> / C<< $msg->composite_filter($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::CompositeFilter>)

A composite filter.

=item * C<< $msg->property_filter() >> / C<< $msg->property_filter($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyFilter>)

A filter on a property.

=back

=head2 Google::Datastore::V1beta3::Query::CompositeFilter

A filter that merges multiple other filters using the given operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->op() >> / C<< $msg->op($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::CompositeFilter::Operator>)

The operator for combining multiple filters.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::Filter>)

The list of filters to combine.
Must contain at least one filter.

=back

=head3 Enum: CompositeFilter::Operator

=over 4

=item * C<OPERATOR_UNSPECIFIED> => C<0>

=item * C<AND> => C<1>

=back

=head2 Google::Datastore::V1beta3::Query::PropertyFilter

A filter on a specific property.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::PropertyReference>)

The property to filter by.

=item * C<< $msg->op() >> / C<< $msg->op($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::PropertyFilter::Operator>)

The operator to filter by.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Value>)

The value to compare the property to.

=back

=head3 Enum: PropertyFilter::Operator

=over 4

=item * C<OPERATOR_UNSPECIFIED> => C<0>

=item * C<LESS_THAN> => C<1>

=item * C<LESS_THAN_OR_EQUAL> => C<2>

=item * C<GREATER_THAN> => C<3>

=item * C<GREATER_THAN_OR_EQUAL> => C<4>

=item * C<EQUAL> => C<5>

=item * C<HAS_ANCESTOR> => C<11>

=back

=head2 Google::Datastore::V1beta3::Query::GqlQuery

A [GQL
query](https://cloud.google.com/datastore/docs/apis/gql/gql_reference).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_string() >> / C<< $msg->query_string($value) >>

Type: C<String>

A string of the format described
[here](https://cloud.google.com/datastore/docs/apis/gql/gql_reference).

=item * C<< $msg->allow_literals() >> / C<< $msg->allow_literals($value) >>

Type: C<Bool>

When false, the query string must not contain any literals and instead must
bind all values. For example,
`SELECT * FROM Kind WHERE a = 'string literal'` is not allowed, while
`SELECT * FROM Kind WHERE a = @value` is.

=item * C<< $msg->named_bindings() >> / C<< $msg->named_bindings($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::GqlQuery::NamedBindingsEntry>)

For each non-reserved named binding site in the query string, there must be
a named parameter with that name, but not necessarily the inverse.

Key must match regex `[A-Za-z_$][A-Za-z_$0-9]*`, must not match regex
`__.*__`, and must not be `""`.

=item * C<< $msg->positional_bindings() >> / C<< $msg->positional_bindings($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::GqlQueryParameter>)

Numbered binding site @1 references the first numbered parameter,
effectively using 1-based indexing, rather than the usual 0.

For each binding site numbered i in `query_string`, there must be an i-th
numbered parameter. The inverse must also be true.

=back

=head2 Google::Datastore::V1beta3::Query::GqlQueryParameter

A binding parameter for a GQL query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Value>)

A value parameter.

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Bytes>

A query cursor. Query cursors are returned in query
result batches.

=back

=head2 Google::Datastore::V1beta3::Query::QueryResultBatch

A batch of results produced by a query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->skipped_results() >> / C<< $msg->skipped_results($value) >>

Type: C<Int32>

The number of results skipped, typically because of an offset.

=item * C<< $msg->skipped_cursor() >> / C<< $msg->skipped_cursor($value) >>

Type: C<Bytes>

A cursor that points to the position after the last skipped result.
Will be set when `skipped_results` != 0.

=item * C<< $msg->entity_result_type() >> / C<< $msg->entity_result_type($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::EntityResult::ResultType>)

The result type for every entity in `entity_results`.

=item * C<< $msg->entity_results() >> / C<< $msg->entity_results($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::EntityResult>)

The results for this batch.

=item * C<< $msg->end_cursor() >> / C<< $msg->end_cursor($value) >>

Type: C<Bytes>

A cursor that points to the position after the last result in the batch.

=item * C<< $msg->more_results() >> / C<< $msg->more_results($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::QueryResultBatch::MoreResultsType>)

The state of the query after the current batch.

=item * C<< $msg->snapshot_version() >> / C<< $msg->snapshot_version($value) >>

Type: C<Int64>

The version number of the snapshot this batch was returned from.
This applies to the range of results from the query's `start_cursor` (or
the beginning of the query if no cursor was given) to this batch's
`end_cursor` (not the query's `end_cursor`).

In a single transaction, subsequent query result batches for the same query
can have a greater snapshot version number. Each batch's snapshot version
is valid for all preceding batches.
The value will be zero for eventually consistent queries.

=back

=head3 Enum: QueryResultBatch::MoreResultsType

=over 4

=item * C<MORE_RESULTS_TYPE_UNSPECIFIED> => C<0>

=item * C<NOT_FINISHED> => C<1>

=item * C<MORE_RESULTS_AFTER_LIMIT> => C<2>

=item * C<MORE_RESULTS_AFTER_CURSOR> => C<4>

=item * C<NO_MORE_RESULTS> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1beta3::Query::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
