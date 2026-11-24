package Google::Cloud::Gkemulticloud::V1::CommonResources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZ2tlbXVsdGljbG91ZC92MS9jb21tb25fcmVzb3VyY2VzLnByb3Rv
Eh1nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKXAQoDSndrEhAK
A2t0eRgBIAEoCVIDa3R5EhAKA2FsZxgCIAEoCVIDYWxnEhAKA3VzZRgDIAEoCVIDdXNlEhAK
A2tpZBgEIAEoCVIDa2lkEgwKAW4YBSABKAlSAW4SDAoBZRgGIAEoCVIBZRIMCgF4GAcgASgJ
UgF4EgwKAXkYCCABKAlSAXkSEAoDY3J2GAkgASgJUgNjcnYiiQEKFldvcmtsb2FkSWRlbnRp
dHlDb25maWcSHQoKaXNzdWVyX3VyaRgBIAEoCVIJaXNzdWVyVXJpEiMKDXdvcmtsb2FkX3Bv
b2wYAiABKAlSDHdvcmtsb2FkUG9vbBIrChFpZGVudGl0eV9wcm92aWRlchgDIAEoCVIQaWRl
bnRpdHlQcm92aWRlciJDChFNYXhQb2RzQ29uc3RyYWludBIuChFtYXhfcG9kc19wZXJfbm9k
ZRgBIAEoA0ID4EECUg5tYXhQb2RzUGVyTm9kZSLVAgoRT3BlcmF0aW9uTWV0YWRhdGESQAoL
Y3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIoCg1zdGF0dXNf
ZGV0YWlsGAQgASgJQgPgQQNSDHN0YXR1c0RldGFpbBImCgxlcnJvcl9kZXRhaWwYBSABKAlC
A+BBA1ILZXJyb3JEZXRhaWwSFwoEdmVyYhgHIAEoCUID4EEDUgR2ZXJiEjoKFnJlcXVlc3Rl
ZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uIuYBCglO
b2RlVGFpbnQSFQoDa2V5GAEgASgJQgPgQQJSA2tleRIZCgV2YWx1ZRgCIAEoCUID4EECUgV2
YWx1ZRJMCgZlZmZlY3QYAyABKA4yLy5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5O
b2RlVGFpbnQuRWZmZWN0QgPgQQJSBmVmZmVjdCJZCgZFZmZlY3QSFgoSRUZGRUNUX1VOU1BF
Q0lGSUVEEAASDwoLTk9fU0NIRURVTEUQARIWChJQUkVGRVJfTk9fU0NIRURVTEUQAhIOCgpO
T19FWEVDVVRFEAMikgMKEU5vZGVLdWJlbGV0Q29uZmlnElcKJmluc2VjdXJlX2t1YmVsZXRf
cmVhZG9ubHlfcG9ydF9lbmFibGVkGAEgASgIQgPgQQFSImluc2VjdXJlS3ViZWxldFJlYWRv
bmx5UG9ydEVuYWJsZWQSNgoSY3B1X21hbmFnZXJfcG9saWN5GAIgASgJQgPgQQFIAFIQY3B1
TWFuYWdlclBvbGljeYgBARIsCg1jcHVfY2ZzX3F1b3RhGAMgASgIQgPgQQFIAVILY3B1Q2Zz
UXVvdGGIAQESOQoUY3B1X2Nmc19xdW90YV9wZXJpb2QYBCABKAlCA+BBAUgCUhFjcHVDZnNR
dW90YVBlcmlvZIgBARIuCg5wb2RfcGlkc19saW1pdBgFIAEoA0ID4EEBSANSDHBvZFBpZHNM
aW1pdIgBAUIVChNfY3B1X21hbmFnZXJfcG9saWN5QhAKDl9jcHVfY2ZzX3F1b3RhQhcKFV9j
cHVfY2ZzX3F1b3RhX3BlcmlvZEIRCg9fcG9kX3BpZHNfbGltaXQiSwoFRmxlZXQSHQoHcHJv
amVjdBgBIAEoCUID4EECUgdwcm9qZWN0EiMKCm1lbWJlcnNoaXAYAiABKAlCA+BBA1IKbWVt
YmVyc2hpcCJxCg1Mb2dnaW5nQ29uZmlnEmAKEGNvbXBvbmVudF9jb25maWcYASABKAsyNS5n
b29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5Mb2dnaW5nQ29tcG9uZW50Q29uZmlnUg9j
b21wb25lbnRDb25maWci1AEKFkxvZ2dpbmdDb21wb25lbnRDb25maWcSbAoRZW5hYmxlX2Nv
bXBvbmVudHMYASADKA4yPy5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5Mb2dnaW5n
Q29tcG9uZW50Q29uZmlnLkNvbXBvbmVudFIQZW5hYmxlQ29tcG9uZW50cyJMCglDb21wb25l
bnQSGQoVQ09NUE9ORU5UX1VOU1BFQ0lGSUVEEAASFQoRU1lTVEVNX0NPTVBPTkVOVFMQARIN
CglXT1JLTE9BRFMQAiL0AQoQTW9uaXRvcmluZ0NvbmZpZxJyChltYW5hZ2VkX3Byb21ldGhl
dXNfY29uZmlnGAIgASgLMjYuZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xvdWQudjEuTWFuYWdl
ZFByb21ldGhldXNDb25maWdSF21hbmFnZWRQcm9tZXRoZXVzQ29uZmlnEmwKF2Nsb3VkX21v
bml0b3JpbmdfY29uZmlnGAQgASgLMjQuZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xvdWQudjEu
Q2xvdWRNb25pdG9yaW5nQ29uZmlnUhVjbG91ZE1vbml0b3JpbmdDb25maWciMwoXTWFuYWdl
ZFByb21ldGhldXNDb25maWcSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZCJCChVDbG91ZE1v
bml0b3JpbmdDb25maWcSHQoHZW5hYmxlZBgBIAEoCEgAUgdlbmFibGVkiAEBQgoKCF9lbmFi
bGVkIugBChNCaW5hcnlBdXRob3JpemF0aW9uEmoKD2V2YWx1YXRpb25fbW9kZRgBIAEoDjJB
Lmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxLkJpbmFyeUF1dGhvcml6YXRpb24uRXZh
bHVhdGlvbk1vZGVSDmV2YWx1YXRpb25Nb2RlImUKDkV2YWx1YXRpb25Nb2RlEh8KG0VWQUxV
QVRJT05fTU9ERV9VTlNQRUNJRklFRBAAEgwKCERJU0FCTEVEEAESJAogUFJPSkVDVF9TSU5H
TEVUT05fUE9MSUNZX0VORk9SQ0UQAiKBAgoVU2VjdXJpdHlQb3N0dXJlQ29uZmlnEnUKEnZ1
bG5lcmFiaWxpdHlfbW9kZRgBIAEoDjJGLmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYx
LlNlY3VyaXR5UG9zdHVyZUNvbmZpZy5WdWxuZXJhYmlsaXR5TW9kZVIRdnVsbmVyYWJpbGl0
eU1vZGUicQoRVnVsbmVyYWJpbGl0eU1vZGUSIgoeVlVMTkVSQUJJTElUWV9NT0RFX1VOU1BF
Q0lGSUVEEAASGgoWVlVMTkVSQUJJTElUWV9ESVNBQkxFRBABEhwKGFZVTE5FUkFCSUxJVFlf
RU5URVJQUklTRRACQucBCiFjb20uZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xvdWQudjFCFENv
bW1vblJlc291cmNlc1Byb3RvUAFaR2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlbXVsdGljbG91
ZC9hcGl2MS9na2VtdWx0aWNsb3VkcGI7Z2tlbXVsdGljbG91ZHBiqgIdR29vZ2xlLkNsb3Vk
LkdrZU11bHRpQ2xvdWQuVjHKAh1Hb29nbGVcQ2xvdWRcR2tlTXVsdGlDbG91ZFxWMeoCIEdv
b2dsZTo6Q2xvdWQ6OkdrZU11bHRpQ2xvdWQ6OlYxSs1VCgcSBQ4AswIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACkKCQoCAwESAxMA
KQoICgEIEgMVADoKCQoCCCUSAxUAOgoICgEIEgMWAF4KCQoCCAsSAxYAXgoICgEIEgMXACIK
CQoCCAoSAxcAIgoICgEIEgMYADUKCQoCCAgSAxgANQoICgEIEgMZADoKCQoCCAESAxkAOgoI
CgEIEgMaADoKCQoCCCkSAxoAOgoICgEIEgMbADkKCQoCCC0SAxsAOQo9CgIEABIEHgA5ARox
IEp3ayBpcyBhIEpTT04gV2ViIEtleSBhcyBzcGVjaWZpZWQgaW4gUkZDIDc1MTcuCgoKCgME
AAESAx4ICwoYCgQEAAIAEgMgAhEaCyBLZXkgVHlwZS4KCgwKBQQAAgAFEgMgAggKDAoFBAAC
AAESAyAJDAoMCgUEAAIAAxIDIA8QChkKBAQAAgESAyMCERoMIEFsZ29yaXRobS4KCgwKBQQA
AgEFEgMjAggKDAoFBAACAQESAyMJDAoMCgUEAAIBAxIDIw8QCjIKBAQAAgISAyYCERolIFBl
cm1pdHRlZCB1c2VzIGZvciB0aGUgcHVibGljIGtleXMuCgoMCgUEAAICBRIDJgIICgwKBQQA
AgIBEgMmCQwKDAoFBAACAgMSAyYPEAoWCgQEAAIDEgMpAhEaCSBLZXkgSUQuCgoMCgUEAAID
BRIDKQIICgwKBQQAAgMBEgMpCQwKDAoFBAACAwMSAykPEAohCgQEAAIEEgMsAg8aFCBVc2Vk
IGZvciBSU0Ega2V5cy4KCgwKBQQAAgQFEgMsAggKDAoFBAACBAESAywJCgoMCgUEAAIEAxID
LA0OCiEKBAQAAgUSAy8CDxoUIFVzZWQgZm9yIFJTQSBrZXlzLgoKDAoFBAACBQUSAy8CCAoM
CgUEAAIFARIDLwkKCgwKBQQAAgUDEgMvDQ4KIwoEBAACBhIDMgIPGhYgVXNlZCBmb3IgRUNE
U0Ega2V5cy4KCgwKBQQAAgYFEgMyAggKDAoFBAACBgESAzIJCgoMCgUEAAIGAxIDMg0OCiMK
BAQAAgcSAzUCDxoWIFVzZWQgZm9yIEVDRFNBIGtleXMuCgoMCgUEAAIHBRIDNQIICgwKBQQA
AgcBEgM1CQoKDAoFBAACBwMSAzUNDgojCgQEAAIIEgM4AhEaFiBVc2VkIGZvciBFQ0RTQSBr
ZXlzLgoKDAoFBAACCAUSAzgCCAoMCgUEAAIIARIDOAkMCgwKBQQAAggDEgM4DxAKKQoCBAES
BDwARgEaHSBXb3JrbG9hZCBJZGVudGl0eSBzZXR0aW5ncy4KCgoKAwQBARIDPAgeCjQKBAQB
AgASAz4CGBonIFRoZSBPSURDIGlzc3VlciBVUkwgZm9yIHRoaXMgY2x1c3Rlci4KCgwKBQQB
AgAFEgM+AggKDAoFBAECAAESAz4JEwoMCgUEAQIAAxIDPhYXCkQKBAQBAgESA0ECGxo3IFRo
ZSBXb3JrbG9hZCBJZGVudGl0eSBQb29sIGFzc29jaWF0ZWQgdG8gdGhlIGNsdXN0ZXIuCgoM
CgUEAQIBBRIDQQIICgwKBQQBAgEBEgNBCRYKDAoFBAECAQMSA0EZGgpkCgQEAQICEgNFAh8a
VyBUaGUgSUQgb2YgdGhlIE9JREMgSWRlbnRpdHkgUHJvdmlkZXIgKElkUCkgYXNzb2NpYXRl
ZCB0byB0aGUgV29ya2xvYWQKIElkZW50aXR5IFBvb2wuCgoMCgUEAQICBRIDRQIICgwKBQQB
AgIBEgNFCRoKDAoFBAECAgMSA0UdHgoqCgIEAhIESQBMARoeIENvbnN0cmFpbnRzIGFwcGxp
ZWQgdG8gcG9kcy4KCgoKAwQCARIDSQgZClEKBAQCAgASA0sCRxpEIFJlcXVpcmVkLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgcG9kcyB0byBzY2hlZHVsZSBvbiBhIHNpbmdsZSBub2RlLgoK
DAoFBAICAAUSA0sCBwoMCgUEAgIAARIDSwgZCgwKBQQCAgADEgNLHB0KDAoFBAICAAgSA0se
RgoPCggEAgIACJwIABIDSx9FCjYKAgQDEgRPAGwBGiogTWV0YWRhdGEgYWJvdXQgYSBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uLgoKCgoDBAMBEgNPCBkKSgoEBAMCABIEUQJSMho8IE91dHB1
dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGlzIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4K
CgwKBQQDAgAGEgNRAhsKDAoFBAMCAAESA1EcJwoMCgUEAwIAAxIDUSorCgwKBQQDAgAIEgNS
BjEKDwoIBAMCAAicCAASA1IHMApMCgQEAwIBEgRVAlYyGj4gT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIGF0IHdoaWNoIHRoaXMgb3BlcmF0aW9uIHdhcyBjb21wbGV0ZWQuCgoMCgUEAwIBBhID
VQIbCgwKBQQDAgEBEgNVHCQKDAoFBAMCAQMSA1UnKAoMCgUEAwIBCBIDVgYxCg8KCAQDAgEI
nAgAEgNWBzAKUgoEBAMCAhIDWQJAGkUgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBy
ZXNvdXJjZSBhc3NvY2lhdGVkIHRvIHRoaXMgb3BlcmF0aW9uLgoKDAoFBAMCAgUSA1kCCAoM
CgUEAwICARIDWQkPCgwKBQQDAgIDEgNZEhMKDAoFBAMCAggSA1kUPwoPCggEAwICCJwIABID
WRU+CksKBAQDAgMSA1wCRxo+IE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMg
b2YgdGhlIG9wZXJhdGlvbiwgaWYgYW55LgoKDAoFBAMCAwUSA1wCCAoMCgUEAwIDARIDXAkW
CgwKBQQDAgMDEgNcGRoKDAoFBAMCAwgSA1wbRgoPCggEAwIDCJwIABIDXBxFCmMKBAQDAgQS
A2ACRhpWIE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMgb2YgYW55IGVycm9y
IHRoYXQgb2NjdXJyZWQgZHVyaW5nIHRoZQogb3BlcmF0aW9uLgoKDAoFBAMCBAUSA2ACCAoM
CgUEAwIEARIDYAkVCgwKBQQDAgQDEgNgGBkKDAoFBAMCBAgSA2AaRQoPCggEAwIECJwIABID
YBtECqQBCgQEAwIFEgNkAj4algEgT3V0cHV0IG9ubHkuIFRoZSB2ZXJiIGFzc29jaWF0ZWQg
d2l0aCB0aGUgQVBJIG1ldGhvZCB3aGljaCB0cmlnZ2VyZWQgdGhpcwogb3BlcmF0aW9uLiBQ
b3NzaWJsZSB2YWx1ZXMgYXJlICJjcmVhdGUiLCAiZGVsZXRlIiwgInVwZGF0ZSIgYW5kICJp
bXBvcnQiLgoKDAoFBAMCBQUSA2QCCAoMCgUEAwIFARIDZAkNCgwKBQQDAgUDEgNkEBEKDAoF
BAMCBQgSA2QSPQoPCggEAwIFCJwIABIDZBM8CswCCgQEAwIGEgNrAk4avgIgT3V0cHV0IG9u
bHkuIElkZW50aWZpZXMgd2hldGhlciBjYW5jZWxsYXRpb24gaGFzIGJlZW4gcmVxdWVzdGVk
IGZvciB0aGUKIG9wZXJhdGlvbi4gT3BlcmF0aW9ucyB0aGF0IGhhdmUgc3VjY2Vzc2Z1bGx5
IGJlZW4gY2FuY2VsbGVkIGhhdmUKIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVy
cm9yXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXQogdmFsdWUgd2l0aCBh
IFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiAx
LAogY29ycmVzcG9uZGluZyB0byBgQ29kZS5DQU5DRUxMRURgLgoKDAoFBAMCBgUSA2sCBgoM
CgUEAwIGARIDawcdCgwKBQQDAgYDEgNrICEKDAoFBAMCBggSA2siTQoPCggEAwIGCJwIABID
ayNMCjQKAgQEEgVvAI0BARonIFRoZSB0YWludCBjb250ZW50IGZvciB0aGUgbm9kZSB0YWlu
dC4KCgoKAwQEARIDbwgRCiIKBAQEBAASBXECgwEDGhMgVGhlIHRhaW50IGVmZmVjdC4KCgwK
BQQEBAABEgNxBw0KGQoGBAQEAAIAEgNzBBsaCiBOb3Qgc2V0LgoKDgoHBAQEAAIAARIDcwQW
Cg4KBwQEBAACAAISA3MZGgqNAgoGBAQEAAIBEgN5BBQa/QEgRG8gbm90IGFsbG93IG5ldyBw
b2RzIHRvIHNjaGVkdWxlIG9udG8gdGhlIG5vZGUgdW5sZXNzIHRoZXkgdG9sZXJhdGUgdGhl
CiB0YWludCwgYnV0IGFsbG93IGFsbCBwb2RzIHN1Ym1pdHRlZCB0byBLdWJlbGV0IHdpdGhv
dXQgZ29pbmcgdGhyb3VnaCB0aGUKIHNjaGVkdWxlciB0byBzdGFydCwgYW5kIGFsbG93IGFs
bCBhbHJlYWR5LXJ1bm5pbmcgcG9kcyB0byBjb250aW51ZQogcnVubmluZy4gRW5mb3JjZWQg
YnkgdGhlIHNjaGVkdWxlci4KCg4KBwQEBAACAQESA3kEDwoOCgcEBAQAAgECEgN5EhMK0wEK
BgQEBAACAhIDfgQbGsMBIExpa2UgVGFpbnRFZmZlY3ROb1NjaGVkdWxlLCBidXQgdGhlIHNj
aGVkdWxlciB0cmllcyBub3QgdG8gc2NoZWR1bGUKIG5ldyBwb2RzIG9udG8gdGhlIG5vZGUs
IHJhdGhlciB0aGFuIHByb2hpYml0aW5nIG5ldyBwb2RzIGZyb20gc2NoZWR1bGluZwogb250
byB0aGUgbm9kZSBlbnRpcmVseS4gRW5mb3JjZWQgYnkgdGhlIHNjaGVkdWxlci4KCg4KBwQE
BAACAgESA34EFgoOCgcEBAQAAgICEgN+GRoKdwoGBAQEAAIDEgSCAQQTGmcgRXZpY3QgYW55
IGFscmVhZHktcnVubmluZyBwb2RzIHRoYXQgZG8gbm90IHRvbGVyYXRlIHRoZSB0YWludC4K
IEN1cnJlbnRseSBlbmZvcmNlZCBieSBOb2RlQ29udHJvbGxlci4KCg8KBwQEBAACAwESBIIB
BA4KDwoHBAQEAAIDAhIEggEREgosCgQEBAIAEgSGAQI6Gh4gUmVxdWlyZWQuIEtleSBmb3Ig
dGhlIHRhaW50LgoKDQoFBAQCAAUSBIYBAggKDQoFBAQCAAESBIYBCQwKDQoFBAQCAAMSBIYB
DxAKDQoFBAQCAAgSBIYBETkKEAoIBAQCAAicCAASBIYBEjgKLgoEBAQCARIEiQECPBogIFJl
cXVpcmVkLiBWYWx1ZSBmb3IgdGhlIHRhaW50LgoKDQoFBAQCAQUSBIkBAggKDQoFBAQCAQES
BIkBCQ4KDQoFBAQCAQMSBIkBERIKDQoFBAQCAQgSBIkBEzsKEAoIBAQCAQicCAASBIkBFDoK
KwoEBAQCAhIEjAECPRodIFJlcXVpcmVkLiBUaGUgdGFpbnQgZWZmZWN0LgoKDQoFBAQCAgYS
BIwBAggKDQoFBAQCAgESBIwBCQ8KDQoFBAQCAgMSBIwBEhMKDQoFBAQCAggSBIwBFDwKEAoI
BAQCAgicCAASBIwBFTsKPAoCBAUSBpABAMABARouIENvbmZpZ3VyYXRpb24gZm9yIG5vZGUg
cG9vbCBrdWJlbGV0IG9wdGlvbnMuCgoLCgMEBQESBJABCBkKRwoEBAUCABIGkgECkwEvGjcg
T3B0aW9uYWwuIEVuYWJsZSB0aGUgaW5zZWN1cmUga3ViZWxldCByZWFkIG9ubHkgcG9ydC4K
Cg0KBQQFAgAFEgSSAQIGCg0KBQQFAgABEgSSAQctCg0KBQQFAgADEgSSATAxCg0KBQQFAgAI
EgSTAQYuChAKCAQFAgAInAgAEgSTAQctCrwDCgQEBQIBEgaeAQKfAS8aqwMgT3B0aW9uYWwu
IENvbnRyb2wgdGhlIENQVSBtYW5hZ2VtZW50IHBvbGljeSBvbiB0aGUgbm9kZS4KIFNlZQog
aHR0cHM6Ly9rdWJlcm5ldGVzLmlvL2RvY3MvdGFza3MvYWRtaW5pc3Rlci1jbHVzdGVyL2Nw
dS1tYW5hZ2VtZW50LXBvbGljaWVzLwoKIFRoZSBmb2xsb3dpbmcgdmFsdWVzIGFyZSBhbGxv
d2VkLgogKiAibm9uZSI6IHRoZSBkZWZhdWx0LCB3aGljaCByZXByZXNlbnRzIHRoZSBleGlz
dGluZyBzY2hlZHVsaW5nIGJlaGF2aW9yLgogKiAic3RhdGljIjogYWxsb3dzIHBvZHMgd2l0
aCBjZXJ0YWluIHJlc291cmNlIGNoYXJhY3RlcmlzdGljcyB0byBiZSBncmFudGVkCiBpbmNy
ZWFzZWQgQ1BVIGFmZmluaXR5IGFuZCBleGNsdXNpdml0eSBvbiB0aGUgbm9kZS4KIFRoZSBk
ZWZhdWx0IHZhbHVlIGlzICdub25lJyBpZiB1bnNwZWNpZmllZC4KCg0KBQQFAgEEEgSeAQIK
Cg0KBQQFAgEFEgSeAQsRCg0KBQQFAgEBEgSeARIkCg0KBQQFAgEDEgSeAScoCg0KBQQFAgEI
EgSfAQYuChAKCAQFAgEInAgAEgSfAQctCoYECgQEBQICEgStAQJLGvcDIE9wdGlvbmFsLiBF
bmFibGUgQ1BVIENGUyBxdW90YSBlbmZvcmNlbWVudCBmb3IgY29udGFpbmVycyB0aGF0IHNw
ZWNpZnkgQ1BVCiBsaW1pdHMuCgogVGhpcyBvcHRpb24gaXMgZW5hYmxlZCBieSBkZWZhdWx0
IHdoaWNoIG1ha2VzIGt1YmVsZXQgdXNlIENGUyBxdW90YQogKGh0dHBzOi8vd3d3Lmtlcm5l
bC5vcmcvZG9jL0RvY3VtZW50YXRpb24vc2NoZWR1bGVyL3NjaGVkLWJ3Yy50eHQpIHRvCiBl
bmZvcmNlIGNvbnRhaW5lciBDUFUgbGltaXRzLiBPdGhlcndpc2UsIENQVSBsaW1pdHMgd2ls
bCBub3QgYmUgZW5mb3JjZWQgYXQKIGFsbC4KCiBEaXNhYmxlIHRoaXMgb3B0aW9uIHRvIG1p
dGlnYXRlIENQVSB0aHJvdHRsaW5nIHByb2JsZW1zIHdoaWxlIHN0aWxsIGhhdmluZwogeW91
ciBwb2RzIHRvIGJlIGluIEd1YXJhbnRlZWQgUW9TIGNsYXNzIGJ5IHNwZWNpZnlpbmcgdGhl
IENQVSBsaW1pdHMuCgogVGhlIGRlZmF1bHQgdmFsdWUgaXMgJ3RydWUnIGlmIHVuc3BlY2lm
aWVkLgoKDQoFBAUCAgQSBK0BAgoKDQoFBAUCAgUSBK0BCw8KDQoFBAUCAgESBK0BEB0KDQoF
BAUCAgMSBK0BICEKDQoFBAUCAggSBK0BIkoKEAoIBAUCAgicCAASBK0BI0kK4gIKBAQFAgMS
BrcBArgBLxrRAiBPcHRpb25hbC4gU2V0IHRoZSBDUFUgQ0ZTIHF1b3RhIHBlcmlvZCB2YWx1
ZSAnY3B1LmNmc19wZXJpb2RfdXMnLgoKIFRoZSBzdHJpbmcgbXVzdCBiZSBhIHNlcXVlbmNl
IG9mIGRlY2ltYWwgbnVtYmVycywgZWFjaCB3aXRoIG9wdGlvbmFsCiBmcmFjdGlvbiBhbmQg
YSB1bml0IHN1ZmZpeCwgc3VjaCBhcyAiMzAwbXMiLgogVmFsaWQgdGltZSB1bml0cyBhcmUg
Im5zIiwgInVzIiAob3IgIsK1cyIpLCAibXMiLCAicyIsICJtIiwgImgiLgogVGhlIHZhbHVl
IG11c3QgYmUgYSBwb3NpdGl2ZSBkdXJhdGlvbi4KCiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyAn
MTAwbXMnIGlmIHVuc3BlY2lmaWVkLgoKDQoFBAUCAwQSBLcBAgoKDQoFBAUCAwUSBLcBCxEK
DQoFBAUCAwESBLcBEiYKDQoFBAUCAwMSBLcBKSoKDQoFBAUCAwgSBLgBBi4KEAoIBAUCAwic
CAASBLgBBy0KiwIKBAQFAgQSBL8BAk0a/AEgT3B0aW9uYWwuIFNldCB0aGUgUG9kIFBJRCBs
aW1pdHMuIFNlZQogaHR0cHM6Ly9rdWJlcm5ldGVzLmlvL2RvY3MvY29uY2VwdHMvcG9saWN5
L3BpZC1saW1pdGluZy8jcG9kLXBpZC1saW1pdHMKCiBDb250cm9scyB0aGUgbWF4aW11bSBu
dW1iZXIgb2YgcHJvY2Vzc2VzIGFsbG93ZWQgdG8gcnVuIGluIGEgcG9kLiBUaGUgdmFsdWUK
IG11c3QgYmUgZ3JlYXRlciB0aGFuIG9yIGVxdWFsIHRvIDEwMjQgYW5kIGxlc3MgdGhhbiA0
MTk0MzA0LgoKDQoFBAUCBAQSBL8BAgoKDQoFBAUCBAUSBL8BCxAKDQoFBAUCBAESBL8BER8K
DQoFBAUCBAMSBL8BIiMKDQoFBAUCBAgSBL8BJEwKEAoIBAUCBAicCAASBL8BJUsK+wIKAgQG
EgbLAQDZAQEa7AIgRmxlZXQgcmVsYXRlZCBjb25maWd1cmF0aW9uLgoKIEZsZWV0cyBhcmUg
YSBHb29nbGUgQ2xvdWQgY29uY2VwdCBmb3IgbG9naWNhbGx5IG9yZ2FuaXppbmcgY2x1c3Rl
cnMsCiBsZXR0aW5nIHlvdSB1c2UgYW5kIG1hbmFnZSBtdWx0aS1jbHVzdGVyIGNhcGFiaWxp
dGllcyBhbmQgYXBwbHkKIGNvbnNpc3RlbnQgcG9saWNpZXMgYWNyb3NzIHlvdXIgc3lzdGVt
cy4KCiBTZWUgW0FudGhvcwogRmxlZXRzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYW50
aG9zL211bHRpY2x1c3Rlci1tYW5hZ2VtZW50L2ZsZWV0cykgZm9yCiBtb3JlIGRldGFpbHMg
b24gQW50aG9zIG11bHRpLWNsdXN0ZXIgY2FwYWJpbGl0aWVzIHVzaW5nIEZsZWV0cy4KCgsK
AwQGARIEywEIDQqkAQoEBAYCABIE0QECPhqVASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IEZsZWV0IGhvc3QgcHJvamVjdCB3aGVyZSB0aGlzIGNsdXN0ZXIgd2lsbCBiZQogcmVnaXN0
ZXJlZC4KCiBQcm9qZWN0IG5hbWVzIGFyZSBmb3JtYXR0ZWQgYXMKIGBwcm9qZWN0cy88cHJv
amVjdC1udW1iZXI+YC4KCg0KBQQGAgAFEgTRAQIICg0KBQQGAgABEgTRAQkQCg0KBQQGAgAD
EgTRARMUCg0KBQQGAgAIEgTRARU9ChAKCAQGAgAInAgAEgTRARY8CtUBCgQEBgIBEgTYAQJE
GsYBIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUgbWFuYWdlZCBIdWIgTWVtYmVyc2hp
cCByZXNvdXJjZSBhc3NvY2lhdGVkIHRvCiB0aGlzIGNsdXN0ZXIuCgogTWVtYmVyc2hpcCBu
YW1lcyBhcmUgZm9ybWF0dGVkIGFzCiBgcHJvamVjdHMvPHByb2plY3QtbnVtYmVyPi9sb2Nh
dGlvbnMvZ2xvYmFsL21lbWJlcnNoaXAvPGNsdXN0ZXItaWQ+YC4KCg0KBQQGAgEFEgTYAQII
Cg0KBQQGAgEBEgTYAQkTCg0KBQQGAgEDEgTYARYXCg0KBQQGAgEIEgTYARhDChAKCAQGAgEI
nAgAEgTYARlCClAKAgQHEgbcAQDfAQEaQiBQYXJhbWV0ZXJzIHRoYXQgZGVzY3JpYmUgdGhl
IExvZ2dpbmcgY29uZmlndXJhdGlvbiBpbiBhIGNsdXN0ZXIuCgoLCgMEBwESBNwBCBUKPAoE
BAcCABIE3gECLhouIFRoZSBjb25maWd1cmF0aW9uIG9mIHRoZSBsb2dnaW5nIGNvbXBvbmVu
dHM7CgoNCgUEBwIABhIE3gECGAoNCgUEBwIAARIE3gEZKQoNCgUEBwIAAxIE3gEsLQpaCgIE
CBIG4gEA8QEBGkwgUGFyYW1ldGVycyB0aGF0IGRlc2NyaWJlIHRoZSBMb2dnaW5nIGNvbXBv
bmVudCBjb25maWd1cmF0aW9uIGluIGEgY2x1c3Rlci4KCgsKAwQIARIE4gEIHgo+CgQECAQA
EgbkAQLtAQMaLiBUaGUgY29tcG9uZW50cyBvZiB0aGUgbG9nZ2luZyBjb25maWd1cmF0aW9u
OwoKDQoFBAgEAAESBOQBBxAKKwoGBAgEAAIAEgTmAQQeGhsgTm8gY29tcG9uZW50IGlzIHNw
ZWNpZmllZAoKDwoHBAgEAAIAARIE5gEEGQoPCgcECAQAAgACEgTmARwdCksKBgQIBAACARIE
6QEEGho7IFRoaXMgaW5kaWNhdGVzIHRoYXQgc3lzdGVtIGxvZ2dpbmcgY29tcG9uZW50cyBp
cyBlbmFibGVkLgoKDwoHBAgEAAIBARIE6QEEFQoPCgcECAQAAgECEgTpARgZClEKBgQIBAAC
AhIE7AEEEhpBIFRoaXMgaW5kaWNhdGVzIHRoYXQgdXNlciB3b3JrbG9hZCBsb2dnaW5nIGNv
bXBvbmVudCBpcyBlbmFibGVkLgoKDwoHBAgEAAICARIE7AEEDQoPCgcECAQAAgICEgTsARAR
Ci0KBAQIAgASBPABAisaHyBUaGUgY29tcG9uZW50cyB0byBiZSBlbmFibGVkLgoKDQoFBAgC
AAQSBPABAgoKDQoFBAgCAAYSBPABCxQKDQoFBAgCAAESBPABFSYKDQoFBAgCAAMSBPABKSoK
UwoCBAkSBvQBAPsBARpFIFBhcmFtZXRlcnMgdGhhdCBkZXNjcmliZSB0aGUgTW9uaXRvcmlu
ZyBjb25maWd1cmF0aW9uIGluIGEgY2x1c3Rlci4KCgsKAwQJARIE9AEIGApSCgQECQIAEgT2
AQI4GkQgRW5hYmxlIEdvb2dsZSBDbG91ZCBNYW5hZ2VkIFNlcnZpY2UgZm9yIFByb21ldGhl
dXMgaW4gdGhlIGNsdXN0ZXIuCgoNCgUECQIABhIE9gECGQoNCgUECQIAARIE9gEaMwoNCgUE
CQIAAxIE9gE2NwpLCgQECQIBEgT6AQI0Gj0gT3B0aW9uYWxseSBlbmFibGUgR0tFIG1ldHJp
Y3MuCiBPbmx5IGZvciBBdHRhY2hlZCBDbHVzdGVycy4KCg0KBQQJAgEGEgT6AQIXCg0KBQQJ
AgEBEgT6ARgvCg0KBQQJAgEDEgT6ATIzCnMKAgQKEgb/AQCCAgEaZSBNYW5hZ2VkUHJvbWV0
aGV1c0NvbmZpZyBkZWZpbmVzIHRoZSBjb25maWd1cmF0aW9uIGZvcgogR29vZ2xlIENsb3Vk
IE1hbmFnZWQgU2VydmljZSBmb3IgUHJvbWV0aGV1cy4KCgsKAwQKARIE/wEIHwoqCgQECgIA
EgSBAgITGhwgRW5hYmxlIE1hbmFnZWQgQ29sbGVjdGlvbi4KCg0KBQQKAgAFEgSBAgIGCg0K
BQQKAgABEgSBAgcOCg0KBQQKAgADEgSBAhESCogBCgIECxIGhwIAiwIBGnogQ2xvdWRNb25p
dG9yaW5nQ29uZmlnIGRlZmluZXMgdGhlIGNvbmZpZ3VyYXRpb24gZm9yCiBidWlsdC1pbiBD
bG91ZCBMb2dnaW5nIGFuZCBNb25pdG9yaW5nLgogT25seSBmb3IgQXR0YWNoZWQgQ2x1c3Rl
cnMuCgoLCgMECwESBIcCCB0KUwoEBAsCABIEigICHBpFIEVuYWJsZSBHS0UtbmF0aXZlIGxv
Z2dpbmcgYW5kIG1ldHJpY3MuCiBPbmx5IGZvciBBdHRhY2hlZCBDbHVzdGVycy4KCg0KBQQL
AgAEEgSKAgIKCg0KBQQLAgAFEgSKAgsPCg0KBQQLAgABEgSKAhAXCg0KBQQLAgADEgSKAhob
CjcKAgQMEgaOAgCfAgEaKSBDb25maWd1cmF0aW9uIGZvciBCaW5hcnkgQXV0aG9yaXphdGlv
bi4KCgsKAwQMARIEjgIIGwo5CgQEDAQAEgaQAgKaAgMaKSBCaW5hcnkgQXV0aG9yaXphdGlv
biBtb2RlIG9mIG9wZXJhdGlvbi4KCg0KBQQMBAABEgSQAgcVCh8KBgQMBAACABIEkgIEJBoP
IERlZmF1bHQgdmFsdWUKCg8KBwQMBAACAAESBJICBB8KDwoHBAwEAAIAAhIEkgIiIwotCgYE
DAQAAgESBJUCBBEaHSBEaXNhYmxlIEJpbmFyeUF1dGhvcml6YXRpb24KCg8KBwQMBAACAQES
BJUCBAwKDwoHBAwEAAIBAhIElQIPEAp3CgYEDAQAAgISBJkCBCkaZyBFbmZvcmNlIEt1YmVy
bmV0ZXMgYWRtaXNzaW9uIHJlcXVlc3RzIHdpdGggQmluYXJ5QXV0aG9yaXphdGlvbiB1c2lu
ZyB0aGUKIHByb2plY3QncyBzaW5nbGV0b24gcG9saWN5LgoKDwoHBAwEAAICARIEmQIEJAoP
CgcEDAQAAgICEgSZAicoCmgKBAQMAgASBJ4CAiUaWiBNb2RlIG9mIG9wZXJhdGlvbiBmb3Ig
YmluYXV0aHogcG9saWN5IGV2YWx1YXRpb24uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwog
dG8gRElTQUJMRUQuCgoNCgUEDAIABhIEngICEAoNCgUEDAIAARIEngIRIAoNCgUEDAIAAxIE
ngIjJAp4CgIEDRIGowIAswIBGmogU2VjdXJpdHlQb3N0dXJlQ29uZmlnIGRlZmluZXMgdGhl
IGZsYWdzIG5lZWRlZCB0byBlbmFibGUvZGlzYWJsZSBmZWF0dXJlcyBmb3IKIHRoZSBTZWN1
cml0eSBQb3N0dXJlIEFQSS4KCgsKAwQNARIEowIIHQpXCgQEDQQAEgalAgKvAgMaRyBWdWxu
ZXJhYmlsaXR5TW9kZSBkZWZpbmVzIGVuYWJsZW1lbnQgbW9kZSBmb3IgdnVsbmVyYWJpbGl0
eSBzY2FubmluZy4KCg0KBQQNBAABEgSlAgcYCi4KBgQNBAACABIEpwIEJxoeIERlZmF1bHQg
dmFsdWUgbm90IHNwZWNpZmllZC4KCg8KBwQNBAACAAESBKcCBCIKDwoHBA0EAAIAAhIEpwIl
JgpBCgYEDQQAAgESBKoCBB8aMSBEaXNhYmxlcyB2dWxuZXJhYmlsaXR5IHNjYW5uaW5nIG9u
IHRoZSBjbHVzdGVyLgoKDwoHBA0EAAIBARIEqgIEGgoPCgcEDQQAAgECEgSqAh0eCmUKBgQN
BAACAhIErgIEIRpVIEFwcGxpZXMgdGhlIFNlY3VyaXR5IFBvc3R1cmUncyB2dWxuZXJhYmls
aXR5IG9uIGNsdXN0ZXIgRW50ZXJwcmlzZSBsZXZlbAogZmVhdHVyZXMuCgoPCgcEDQQAAgIB
EgSuAgQcCg8KBwQNBAACAgISBK4CHyAKQgoEBA0CABIEsgICKxo0IFNldHMgd2hpY2ggbW9k
ZSB0byB1c2UgZm9yIHZ1bG5lcmFiaWxpdHkgc2Nhbm5pbmcuCgoNCgUEDQIABhIEsgICEwoN
CgUEDQIAARIEsgIUJgoNCgUEDQIAAxIEsgIpKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk ===
    # Fields for Jwk
    # Field: kty Type: 9 ()
    # Field: alg Type: 9 ()
    # Field: use Type: 9 ()
    # Field: kid Type: 9 ()
    # Field: n Type: 9 ()
    # Field: e Type: 9 ()
    # Field: x Type: 9 ()
    # Field: y Type: 9 ()
    # Field: crv Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig ===
    # Fields for WorkloadIdentityConfig
    # Field: issuer_uri Type: 9 ()
    # Field: workload_pool Type: 9 ()
    # Field: identity_provider Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::MaxPodsConstraint ===
    # Fields for MaxPodsConstraint
    # Field: max_pods_per_node Type: 3 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: error_detail Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::NodeTaint ===
    # Fields for NodeTaint
    # Field: key Type: 9 ()
    # Field: value Type: 9 ()
    # Field: effect Type: 14 (.google.cloud.gkemulticloud.v1.NodeTaint.Effect)

# Enum: NodeTaint::Effect
our $NodeTaint_EFFECT_UNSPECIFIED = 0;
our $NodeTaint_NO_SCHEDULE = 1;
our $NodeTaint_PREFER_NO_SCHEDULE = 2;
our $NodeTaint_NO_EXECUTE = 3;

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::NodeKubeletConfig ===
    # Fields for NodeKubeletConfig
    # Field: insecure_kubelet_readonly_port_enabled Type: 8 ()
    # Field: cpu_manager_policy Type: 9 ()
    # Field: cpu_cfs_quota Type: 8 ()
    # Field: cpu_cfs_quota_period Type: 9 ()
    # Field: pod_pids_limit Type: 3 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet ===
    # Fields for Fleet
    # Field: project Type: 9 ()
    # Field: membership Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig ===
    # Fields for LoggingConfig
    # Field: component_config Type: 11 (.google.cloud.gkemulticloud.v1.LoggingComponentConfig)

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig ===
    # Fields for LoggingComponentConfig
    # Field: enable_components Type: 14 (.google.cloud.gkemulticloud.v1.LoggingComponentConfig.Component)

# Enum: LoggingComponentConfig::Component
our $LoggingComponentConfig_COMPONENT_UNSPECIFIED = 0;
our $LoggingComponentConfig_SYSTEM_COMPONENTS = 1;
our $LoggingComponentConfig_WORKLOADS = 2;

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig ===
    # Fields for MonitoringConfig
    # Field: managed_prometheus_config Type: 11 (.google.cloud.gkemulticloud.v1.ManagedPrometheusConfig)
    # Field: cloud_monitoring_config Type: 11 (.google.cloud.gkemulticloud.v1.CloudMonitoringConfig)

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig ===
    # Fields for ManagedPrometheusConfig
    # Field: enabled Type: 8 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig ===
    # Fields for CloudMonitoringConfig
    # Field: enabled Type: 8 ()

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization ===
    # Fields for BinaryAuthorization
    # Field: evaluation_mode Type: 14 (.google.cloud.gkemulticloud.v1.BinaryAuthorization.EvaluationMode)

# Enum: BinaryAuthorization::EvaluationMode
our $BinaryAuthorization_EVALUATION_MODE_UNSPECIFIED = 0;
our $BinaryAuthorization_DISABLED = 1;
our $BinaryAuthorization_PROJECT_SINGLETON_POLICY_ENFORCE = 2;

# === Message: Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig ===
    # Fields for SecurityPostureConfig
    # Field: vulnerability_mode Type: 14 (.google.cloud.gkemulticloud.v1.SecurityPostureConfig.VulnerabilityMode)

# Enum: SecurityPostureConfig::VulnerabilityMode
our $SecurityPostureConfig_VULNERABILITY_MODE_UNSPECIFIED = 0;
our $SecurityPostureConfig_VULNERABILITY_DISABLED = 1;
our $SecurityPostureConfig_VULNERABILITY_ENTERPRISE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkemulticloud::V1::CommonResources - Compiled Protocol Buffers messages for google/cloud/gkemulticloud/v1/common_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkemulticloud::V1::CommonResources;

    my $msg = Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk->new({
        kty => $kty,
        alg => $alg,
        use => $use,
        kid => $kid,
    });

    # Read or update a field
    my $val = $msg->kty();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkemulticloud/v1/common_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk

Jwk is a JSON Web Key as specified in RFC 7517.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kty() >> / C<< $msg->kty($value) >>

Type: C<String>

Key Type.

=item * C<< $msg->alg() >> / C<< $msg->alg($value) >>

Type: C<String>

Algorithm.

=item * C<< $msg->use() >> / C<< $msg->use($value) >>

Type: C<String>

Permitted uses for the public keys.

=item * C<< $msg->kid() >> / C<< $msg->kid($value) >>

Type: C<String>

Key ID.

=item * C<< $msg->n() >> / C<< $msg->n($value) >>

Type: C<String>

Used for RSA keys.

=item * C<< $msg->e() >> / C<< $msg->e($value) >>

Type: C<String>

Used for RSA keys.

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<String>

Used for ECDSA keys.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<String>

Used for ECDSA keys.

=item * C<< $msg->crv() >> / C<< $msg->crv($value) >>

Type: C<String>

Used for ECDSA keys.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig

Workload Identity settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->issuer_uri() >> / C<< $msg->issuer_uri($value) >>

Type: C<String>

The OIDC issuer URL for this cluster.

=item * C<< $msg->workload_pool() >> / C<< $msg->workload_pool($value) >>

Type: C<String>

The Workload Identity Pool associated to the cluster.

=item * C<< $msg->identity_provider() >> / C<< $msg->identity_provider($value) >>

Type: C<String>

The ID of the OIDC Identity Provider (IdP) associated to the Workload
Identity Pool.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::MaxPodsConstraint

Constraints applied to pods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->max_pods_per_node() >> / C<< $msg->max_pods_per_node($value) >>

Type: C<Int64>

Required. The maximum number of pods to schedule on a single node.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::OperationMetadata

Metadata about a long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this operation was completed.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. The name of the resource associated to this operation.

=item * C<< $msg->status_detail() >> / C<< $msg->status_detail($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->error_detail() >> / C<< $msg->error_detail($value) >>

Type: C<String>

Output only. Human-readable status of any error that occurred during the
operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. The verb associated with the API method which triggered this
operation. Possible values are "create", "delete", "update" and "import".

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether cancellation has been requested for the
operation. Operations that have successfully been cancelled have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::NodeTaint

The taint content for the node taint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. Key for the taint.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Required. Value for the taint.

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::NodeTaint::Effect>)

Required. The taint effect.

=back

=head3 Enum: NodeTaint::Effect

=over 4

=item * C<EFFECT_UNSPECIFIED> => C<0>

=item * C<NO_SCHEDULE> => C<1>

=item * C<PREFER_NO_SCHEDULE> => C<2>

=item * C<NO_EXECUTE> => C<3>

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::NodeKubeletConfig

Configuration for node pool kubelet options.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->insecure_kubelet_readonly_port_enabled() >> / C<< $msg->insecure_kubelet_readonly_port_enabled($value) >>

Type: C<Bool>

Optional. Enable the insecure kubelet read only port.

=item * C<< $msg->cpu_manager_policy() >> / C<< $msg->cpu_manager_policy($value) >>

Type: C<String>

Optional. Control the CPU management policy on the node.
See
https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/

The following values are allowed.
* "none": the default, which represents the existing scheduling behavior.
* "static": allows pods with certain resource characteristics to be granted
increased CPU affinity and exclusivity on the node.
The default value is 'none' if unspecified.

=item * C<< $msg->cpu_cfs_quota() >> / C<< $msg->cpu_cfs_quota($value) >>

Type: C<Bool>

Optional. Enable CPU CFS quota enforcement for containers that specify CPU
limits.

This option is enabled by default which makes kubelet use CFS quota
(https://www.kernel.org/doc/Documentation/scheduler/sched-bwc.txt) to
enforce container CPU limits. Otherwise, CPU limits will not be enforced at
all.

Disable this option to mitigate CPU throttling problems while still having
your pods to be in Guaranteed QoS class by specifying the CPU limits.

The default value is 'true' if unspecified.

=item * C<< $msg->cpu_cfs_quota_period() >> / C<< $msg->cpu_cfs_quota_period($value) >>

Type: C<String>

Optional. Set the CPU CFS quota period value 'cpu.cfs_period_us'.

The string must be a sequence of decimal numbers, each with optional
fraction and a unit suffix, such as "300ms".
Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".
The value must be a positive duration.

The default value is '100ms' if unspecified.

=item * C<< $msg->pod_pids_limit() >> / C<< $msg->pod_pids_limit($value) >>

Type: C<Int64>

Optional. Set the Pod PID limits. See
https://kubernetes.io/docs/concepts/policy/pid-limiting/#pod-pid-limits

Controls the maximum number of processes allowed to run in a pod. The value
must be greater than or equal to 1024 and less than 4194304.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet

Fleet related configuration.

Fleets are a Google Cloud concept for logically organizing clusters,
letting you use and manage multi-cluster capabilities and apply
consistent policies across your systems.

See [Anthos
Fleets](https://cloud.google.com/anthos/multicluster-management/fleets) for
more details on Anthos multi-cluster capabilities using Fleets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The name of the Fleet host project where this cluster will be
registered.

Project names are formatted as
`projects/<project-number>`.

=item * C<< $msg->membership() >> / C<< $msg->membership($value) >>

Type: C<String>

Output only. The name of the managed Hub Membership resource associated to
this cluster.

Membership names are formatted as
`projects/<project-number>/locations/global/membership/<cluster-id>`.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig

Parameters that describe the Logging configuration in a cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->component_config() >> / C<< $msg->component_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig>)

The configuration of the logging components;

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig

Parameters that describe the Logging component configuration in a cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_components() >> / C<< $msg->enable_components($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::LoggingComponentConfig::Component>)

The components to be enabled.

=back

=head3 Enum: LoggingComponentConfig::Component

=over 4

=item * C<COMPONENT_UNSPECIFIED> => C<0>

=item * C<SYSTEM_COMPONENTS> => C<1>

=item * C<WORKLOADS> => C<2>

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig

Parameters that describe the Monitoring configuration in a cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->managed_prometheus_config() >> / C<< $msg->managed_prometheus_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig>)

Enable Google Cloud Managed Service for Prometheus in the cluster.

=item * C<< $msg->cloud_monitoring_config() >> / C<< $msg->cloud_monitoring_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig>)

Optionally enable GKE metrics.
Only for Attached Clusters.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig

ManagedPrometheusConfig defines the configuration for
Google Cloud Managed Service for Prometheus.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Enable Managed Collection.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig

CloudMonitoringConfig defines the configuration for
built-in Cloud Logging and Monitoring.
Only for Attached Clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Enable GKE-native logging and metrics.
Only for Attached Clusters.

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization

Configuration for Binary Authorization.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluation_mode() >> / C<< $msg->evaluation_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::BinaryAuthorization::EvaluationMode>)

Mode of operation for binauthz policy evaluation. If unspecified, defaults
to DISABLED.

=back

=head3 Enum: BinaryAuthorization::EvaluationMode

=over 4

=item * C<EVALUATION_MODE_UNSPECIFIED> => C<0>

=item * C<DISABLED> => C<1>

=item * C<PROJECT_SINGLETON_POLICY_ENFORCE> => C<2>

=back

=head2 Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig

SecurityPostureConfig defines the flags needed to enable/disable features for
the Security Posture API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vulnerability_mode() >> / C<< $msg->vulnerability_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::SecurityPostureConfig::VulnerabilityMode>)

Sets which mode to use for vulnerability scanning.

=back

=head3 Enum: SecurityPostureConfig::VulnerabilityMode

=over 4

=item * C<VULNERABILITY_MODE_UNSPECIFIED> => C<0>

=item * C<VULNERABILITY_DISABLED> => C<1>

=item * C<VULNERABILITY_ENTERPRISE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkemulticloud::V1::CommonResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
