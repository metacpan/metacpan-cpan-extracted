package Google::Actions::Sdk::V2::EventLogs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Intent };
    eval { require Google::Actions::Sdk::V2::Conversation::Prompt };
    eval { require Google::Actions::Sdk::V2::Conversation::Scene };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvYWN0aW9ucy9zZGsvdjIvZXZlbnRfbG9ncy5wcm90bxIVZ29vZ2xlLmFjdGlv
bnMuc2RrLnYyGi9nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL2ludGVudC5w
cm90bxo2Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlvbi9wcm9tcHQvcHJvbXB0
LnByb3RvGi5nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3NjZW5lLnByb3Rv
Ghxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byK7CgoORXhlY3V0aW9uRXZlbnQS
OQoKZXZlbnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWV2ZW50
VGltZRJOCg9leGVjdXRpb25fc3RhdGUYAiABKAsyJS5nb29nbGUuYWN0aW9ucy5zZGsudjIu
RXhlY3V0aW9uU3RhdGVSDmV4ZWN1dGlvblN0YXRlEioKBnN0YXR1cxgDIAEoCzISLmdvb2ds
ZS5ycGMuU3RhdHVzUgZzdGF0dXMSTQoKdXNlcl9pbnB1dBgEIAEoCzIsLmdvb2dsZS5hY3Rp
b25zLnNkay52Mi5Vc2VyQ29udmVyc2F0aW9uSW5wdXRIAFIJdXNlcklucHV0EkcKDGludGVu
dF9tYXRjaBgFIAEoCzIiLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5JbnRlbnRNYXRjaEgAUgtp
bnRlbnRNYXRjaBJfChRjb25kaXRpb25zX2V2YWx1YXRlZBgGIAEoCzIqLmdvb2dsZS5hY3Rp
b25zLnNkay52Mi5Db25kaXRpb25zRXZhbHVhdGVkSABSE2NvbmRpdGlvbnNFdmFsdWF0ZWQS
SwoOb25fc2NlbmVfZW50ZXIYByABKAsyIy5nb29nbGUuYWN0aW9ucy5zZGsudjIuT25TY2Vu
ZUVudGVySABSDG9uU2NlbmVFbnRlchJQCg93ZWJob29rX3JlcXVlc3QYCCABKAsyJS5nb29n
bGUuYWN0aW9ucy5zZGsudjIuV2ViaG9va1JlcXVlc3RIAFIOd2ViaG9va1JlcXVlc3QSUwoQ
d2ViaG9va19yZXNwb25zZRgJIAEoCzImLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5XZWJob29r
UmVzcG9uc2VIAFIPd2ViaG9va1Jlc3BvbnNlEnUKHHdlYmhvb2tfaW5pdGlhdGVkX3RyYW5z
aXRpb24YCiABKAsyMS5nb29nbGUuYWN0aW9ucy5zZGsudjIuV2ViaG9va0luaXRpYXRlZFRy
YW5zaXRpb25IAFIad2ViaG9va0luaXRpYXRlZFRyYW5zaXRpb24SQQoKc2xvdF9tYXRjaBgL
IAEoCzIgLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5TbG90TWF0Y2hIAFIJc2xvdE1hdGNoEk0K
DnNsb3RfcmVxdWVzdGVkGAwgASgLMiQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlNsb3RSZXF1
ZXN0ZWRIAFINc2xvdFJlcXVlc3RlZBJNCg5zbG90X3ZhbGlkYXRlZBgNIAEoCzIkLmdvb2ds
ZS5hY3Rpb25zLnNkay52Mi5TbG90VmFsaWRhdGVkSABSDXNsb3RWYWxpZGF0ZWQSRAoLZm9y
bV9maWxsZWQYDiABKAsyIS5nb29nbGUuYWN0aW9ucy5zZGsudjIuRm9ybUZpbGxlZEgAUgpm
b3JtRmlsbGVkEloKEndhaXRpbmdfdXNlcl9pbnB1dBgPIAEoCzIqLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5XYWl0aW5nRm9yVXNlcklucHV0SABSEHdhaXRpbmdVc2VySW5wdXQSUwoQZW5k
X2NvbnZlcnNhdGlvbhgQIAEoCzImLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5FbmRDb252ZXJz
YXRpb25IAFIPZW5kQ29udmVyc2F0aW9uEikKEHdhcm5pbmdfbWVzc2FnZXMYESADKAlSD3dh
cm5pbmdNZXNzYWdlc0ILCglFdmVudERhdGEigQMKDkV4ZWN1dGlvblN0YXRlEigKEGN1cnJl
bnRfc2NlbmVfaWQYASABKAlSDmN1cnJlbnRTY2VuZUlkEkAKD3Nlc3Npb25fc3RvcmFnZRgC
IAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSDnNlc3Npb25TdG9yYWdlEjIKBXNsb3Rz
GAUgASgLMhwuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlNsb3RzUgVzbG90cxJNCgxwcm9tcHRf
cXVldWUYByADKAsyKi5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLlByb21w
dFILcHJvbXB0UXVldWUSOgoMdXNlcl9zdG9yYWdlGAYgASgLMhcuZ29vZ2xlLnByb3RvYnVm
LlN0cnVjdFILdXNlclN0b3JhZ2USRAoRaG91c2Vob2xkX3N0b3JhZ2UYCCABKAsyFy5nb29n
bGUucHJvdG9idWYuU3RydWN0UhBob3VzZWhvbGRTdG9yYWdlIvkBCgVTbG90cxJNCgZzdGF0
dXMYAiABKA4yNS5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLlNsb3RGaWxs
aW5nU3RhdHVzUgZzdGF0dXMSPQoFc2xvdHMYAyADKAsyJy5nb29nbGUuYWN0aW9ucy5zZGsu
djIuU2xvdHMuU2xvdHNFbnRyeVIFc2xvdHMaYgoKU2xvdHNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRI+CgV2YWx1ZRgCIAEoCzIoLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRp
b24uU2xvdFIFdmFsdWU6AjgBIlIKFVVzZXJDb252ZXJzYXRpb25JbnB1dBISCgR0eXBlGAEg
ASgJUgR0eXBlEiUKDm9yaWdpbmFsX3F1ZXJ5GAIgASgJUg1vcmlnaW5hbFF1ZXJ5Is4CCgtJ
bnRlbnRNYXRjaBIbCglpbnRlbnRfaWQYASABKAlSCGludGVudElkEmUKEWludGVudF9wYXJh
bWV0ZXJzGAUgAygLMjguZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLkludGVudE1hdGNoLkludGVu
dFBhcmFtZXRlcnNFbnRyeVIQaW50ZW50UGFyYW1ldGVycxIYCgdoYW5kbGVyGAMgASgJUgdo
YW5kbGVyEiIKDW5leHRfc2NlbmVfaWQYBCABKAlSC25leHRTY2VuZUlkGn0KFUludGVudFBh
cmFtZXRlcnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJOCgV2YWx1ZRgCIAEoCzI4Lmdvb2ds
ZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uSW50ZW50UGFyYW1ldGVyVmFsdWVSBXZh
bHVlOgI4ASKzAQoTQ29uZGl0aW9uc0V2YWx1YXRlZBJNChFmYWlsZWRfY29uZGl0aW9ucxgB
IAMoCzIgLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5Db25kaXRpb25SEGZhaWxlZENvbmRpdGlv
bnMSTQoRc3VjY2Vzc19jb25kaXRpb24YAiABKAsyIC5nb29nbGUuYWN0aW9ucy5zZGsudjIu
Q29uZGl0aW9uUhBzdWNjZXNzQ29uZGl0aW9uImkKCUNvbmRpdGlvbhIeCgpleHByZXNzaW9u
GAEgASgJUgpleHByZXNzaW9uEhgKB2hhbmRsZXIYAiABKAlSB2hhbmRsZXISIgoNbmV4dF9z
Y2VuZV9pZBgDIAEoCVILbmV4dFNjZW5lSWQiKAoMT25TY2VuZUVudGVyEhgKB2hhbmRsZXIY
ASABKAlSB2hhbmRsZXIiQAoaV2ViaG9va0luaXRpYXRlZFRyYW5zaXRpb24SIgoNbmV4dF9z
Y2VuZV9pZBgBIAEoCVILbmV4dFNjZW5lSWQiMwoOV2ViaG9va1JlcXVlc3QSIQoMcmVxdWVz
dF9qc29uGAEgASgJUgtyZXF1ZXN0SnNvbiI2Cg9XZWJob29rUmVzcG9uc2USIwoNcmVzcG9u
c2VfanNvbhgBIAEoCVIMcmVzcG9uc2VKc29uIuMBCglTbG90TWF0Y2gSWgoObmx1X3BhcmFt
ZXRlcnMYAiADKAsyMy5nb29nbGUuYWN0aW9ucy5zZGsudjIuU2xvdE1hdGNoLk5sdVBhcmFt
ZXRlcnNFbnRyeVINbmx1UGFyYW1ldGVycxp6ChJObHVQYXJhbWV0ZXJzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSTgoFdmFsdWUYAiABKAsyOC5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29u
dmVyc2F0aW9uLkludGVudFBhcmFtZXRlclZhbHVlUgV2YWx1ZToCOAEiZwoNU2xvdFJlcXVl
c3RlZBISCgRzbG90GAEgASgJUgRzbG90EkIKBnByb21wdBgDIAEoCzIqLmdvb2dsZS5hY3Rp
b25zLnNkay52Mi5jb252ZXJzYXRpb24uUHJvbXB0UgZwcm9tcHQiDwoNU2xvdFZhbGlkYXRl
ZCIMCgpGb3JtRmlsbGVkIhUKE1dhaXRpbmdGb3JVc2VySW5wdXQiEQoPRW5kQ29udmVyc2F0
aW9uQmcKGWNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjJCDkV2ZW50TG9nc1Byb3RvUAFaOGdv
b2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjI7c2Rr
Sp9ACgcSBQ4A9QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
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
EAAeCgkKAgMAEgMSADkKCQoCAwESAxMAQAoJCgIDAhIDFAA4CgkKAgMDEgMVACYKCQoCAwQS
AxYAKQoJCgIDBRIDFwAhCggKAQgSAxkATwoJCgIICxIDGQBPCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsALwoJCgIICBIDGwAvCggKAQgSAxwAMgoJCgIIARIDHAAyCokCCgIEABIE
IgBfARr8ASBDb250YWlucyBpbmZvcm1hdGlvbiBhYm91dCBleGVjdXRpb24gZXZlbnQgd2hp
Y2ggaGFwcGVuZWQgZHVyaW5nIHByb2Nlc3NpbmcKIEFjdGlvbnMgQnVpbGRlciBjb252ZXJz
YXRpb24gcmVxdWVzdC4gRm9yIGFuIG92ZXJ2aWV3IG9mIHRoZSBzdGFnZXMgaW52b2x2ZWQK
IGluIGEgY29udmVyc2F0aW9uIHJlcXVlc3QsIHNlZQogaHR0cHM6Ly9kZXZlbG9wZXJzLmdv
b2dsZS5jb20vYXNzaXN0YW50L2NvbnZlcnNhdGlvbmFsL2FjdGlvbnMuCgoKCgMEAAESAyII
FgoxCgQEAAIAEgMkAisaJCBUaW1lc3RhbXAgd2hlbiB0aGUgZXZlbnQgaGFwcGVuZWQuCgoM
CgUEAAIABhIDJAIbCgwKBQQAAgABEgMkHCYKDAoFBAACAAMSAyQpKgo4CgQEAAIBEgMnAiUa
KyBTdGF0ZSBvZiB0aGUgZXhlY3V0aW9uIGR1cmluZyB0aGlzIGV2ZW50LgoKDAoFBAACAQYS
AycCEAoMCgUEAAIBARIDJxEgCgwKBQQAAgEDEgMnIyQKPQoEBAACAhIDKgIfGjAgUmVzdWx0
aW5nIHN0YXR1cyBvZiBwYXJ0aWN1bGFyIGV4ZWN1dGlvbiBzdGVwLgoKDAoFBAACAgYSAyoC
EwoMCgUEAAICARIDKhQaCgwKBQQAAgIDEgMqHR4KswEKBAQACAASBC8CVgMapAEgRGV0YWls
ZWQgaW5mb3JtYXRpb24gc3BlY2lmaWMgdG8gZGlmZmVyZW50IG9mIGV2ZW50cyB0aGF0IG1h
eSBiZSBpbnZvbHZlZAogaW4gcHJvY2Vzc2luZyBhIGNvbnZlcnNhdGlvbiByb3VuZC4gVGhl
IGZpZWxkIHNldCBoZXJlIGRlZmluZXMgdGhlIHR5cGUgb2YKIHRoaXMgZXZlbnQuCgoMCgUE
AAgAARIDLwgRCikKBAQAAgMSAzEEKRocIFVzZXIgaW5wdXQgaGFuZGxpbmcgZXZlbnQuCgoM
CgUEAAIDBhIDMQQZCgwKBQQAAgMBEgMxGiQKDAoFBAACAwMSAzEnKAolCgQEAAIEEgM0BCEa
GCBJbnRlbnQgbWF0Y2hpbmcgZXZlbnQuCgoMCgUEAAIEBhIDNAQPCgwKBQQAAgQBEgM0EBwK
DAoFBAACBAMSAzQfIAoqCgQEAAIFEgM3BDEaHSBDb25kaXRpb24gZXZhbHVhdGlvbiBldmVu
dC4KCgwKBQQAAgUGEgM3BBcKDAoFBAACBQESAzcYLAoMCgUEAAIFAxIDNy8wCiwKBAQAAgYS
AzoEJBofIE9uU2NlbmVFbnRlciBleGVjdXRpb24gZXZlbnQuCgoMCgUEAAIGBhIDOgQQCgwK
BQQAAgYBEgM6ER8KDAoFBAACBgMSAzoiIwouCgQEAAIHEgM9BCcaISBXZWJob29rIHJlcXVl
c3QgZGlzcGF0Y2ggZXZlbnQuCgoMCgUEAAIHBhIDPQQSCgwKBQQAAgcBEgM9EyIKDAoFBAAC
BwMSAz0lJgouCgQEAAIIEgNABCkaISBXZWJob29rIHJlc3BvbnNlIHJlY2VpcHQgZXZlbnQu
CgoMCgUEAAIIBhIDQAQTCgwKBQQAAggBEgNAFCQKDAoFBAACCAMSA0AnKAoyCgQEAAIJEgND
BEEaJSBXZWJob29rLWluaXRpYXRlZCB0cmFuc2l0aW9uIGV2ZW50LgoKDAoFBAACCQYSA0ME
HgoMCgUEAAIJARIDQx87CgwKBQQAAgkDEgNDPkAKIwoEBAACChIDRgQeGhYgU2xvdCBtYXRj
aGluZyBldmVudC4KCgwKBQQAAgoGEgNGBA0KDAoFBAACCgESA0YOGAoMCgUEAAIKAxIDRhsd
CiUKBAQAAgsSA0kEJhoYIFNsb3QgcmVxdWVzdGluZyBldmVudC4KCgwKBQQAAgsGEgNJBBEK
DAoFBAACCwESA0kSIAoMCgUEAAILAxIDSSMlCiUKBAQAAgwSA0wEJhoYIFNsb3QgdmFsaWRh
dGlvbiBldmVudC4KCgwKBQQAAgwGEgNMBBEKDAoFBAACDAESA0wSIAoMCgUEAAIMAxIDTCMl
CiIKBAQAAg0SA08EIBoVIEZvcm0gZmlsbGluZyBldmVudC4KCgwKBQQAAg0GEgNPBA4KDAoF
BAACDQESA08PGgoMCgUEAAINAxIDTx0fCiwKBAQAAg4SA1IEMBofIFdhaXRpbmctZm9yLXVz
ZXItaW5wdXQgZXZlbnQuCgoMCgUEAAIOBhIDUgQXCgwKBQQAAg4BEgNSGCoKDAoFBAACDgMS
A1ItLwopCgQEAAIPEgNVBCoaHCBFbmQtb2YtY29udmVyc2F0aW9uIGV2ZW50LgoKDAoFBAAC
DwYSA1UEEwoMCgUEAAIPARIDVRQkCgwKBQQAAg8DEgNVJykKvwMKBAQAAhASA14CKBqxAyBM
aXN0IG9mIHdhcm5pbmdzIGdlbmVyYXRlZCBkdXJpbmcgZXhlY3V0aW9uIG9mIHRoaXMgRXZl
bnQuIFdhcm5pbmdzIGFyZQogdGlwcyBmb3IgdGhlIGRldmVsb3BlciBkaXNjb3ZlcmVkIGR1
cmluZyB0aGUgY29udmVyc2F0aW9uIHJlcXVlc3QuIFRoZXNlCiBhcmUgdXN1YWxseSBub24t
Y3JpdGljYWwgYW5kIGRvIG5vdCBoYWx0IHRoZSBleGVjdXRpb24gb2YgdGhlIHJlcXVlc3Qu
IEZvcgogZXhhbXBsZSwgYSB3YXJuaW5ncyBtaWdodCBiZSBnZW5lcmF0ZWQgd2hlbiB3ZWJo
b29rIHRyaWVzIHRvIG92ZXJyaWRlIGEKIGN1c3RvbSBUeXBlIHdoaWNoIGRvZXMgbm90IGV4
aXN0LiBFcnJvcnMgYXJlIHJlcG9ydGVkIGFzIGEgZmFpbGVkIHN0YXR1cwogY29kZSwgYnV0
IHdhcm5pbmdzIGNhbiBiZSBwcmVzZW50IGV2ZW4gd2hlbiB0aGUgc3RhdHVzIGlzIE9LLgoK
DAoFBAACEAQSA14CCgoMCgUEAAIQBRIDXgsRCgwKBQQAAhABEgNeEiIKDAoFBAACEAMSA14l
JwotCgIEARIEYgB5ARohIEN1cnJlbnQgc3RhdGUgb2YgdGhlIGV4ZWN1dGlvbi4KCgoKAwQB
ARIDYggWCjoKBAQBAgASA2QCHhotIElEIG9mIHRoZSBzY2VuZSB3aGljaCBpcyBjdXJyZW50
bHkgIGFjdGl2ZS4KCgwKBQQBAgAFEgNkAggKDAoFBAECAAESA2QJGQoMCgUEAQIAAxIDZBwd
CnQKBAQBAgESA2gCLRpnIFN0YXRlIG9mIHRoZSBzZXNzaW9uIHN0b3JhZ2U6CiBodHRwczov
L2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0aW9uYWwvc3RvcmFn
ZS1zZXNzaW9uCgoMCgUEAQIBBhIDaAIYCgwKBQQBAgEBEgNoGSgKDAoFBAECAQMSA2grLAqF
AQoEBAECAhIDbAISGnggU3RhdGUgb2YgdGhlIHNsb3RzIGZpbGxpbmcsIGlmIGFwcGxpY2Fi
bGU6CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0
aW9uYWwvc2NlbmVzI3Nsb3RfZmlsbGluZwoKDAoFBAECAgYSA2wCBwoMCgUEAQICARIDbAgN
CgwKBQQBAgIDEgNsEBEKXAoEBAECAxIDcAJGGk8gUHJvbXB0IHF1ZXVlOgogaHR0cHM6Ly9k
ZXZlbG9wZXJzLmdvb2dsZS5jb20vYXNzaXN0YW50L2NvbnZlcnNhdGlvbmFsL3Byb21wdHMK
CgwKBQQBAgMEEgNwAgoKDAoFBAECAwYSA3ALNAoMCgUEAQIDARIDcDVBCgwKBQQBAgMDEgNw
REUKbgoEBAECBBIDdAIqGmEgU3RhdGUgb2YgdGhlIHVzZXIgc3RvcmFnZToKIGh0dHBzOi8v
ZGV2ZWxvcGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9jb252ZXJzYXRpb25hbC9zdG9yYWdl
LXVzZXIKCgwKBQQBAgQGEgN0AhgKDAoFBAECBAESA3QZJQoMCgUEAQIEAxIDdCgpCm4KBAQB
AgUSA3gCLxphIFN0YXRlIG9mIHRoZSBob21lIHN0b3JhZ2U6CiBodHRwczovL2RldmVsb3Bl
cnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0aW9uYWwvc3RvcmFnZS1ob21lCgoM
CgUEAQIFBhIDeAIYCgwKBQQBAgUBEgN4GSoKDAoFBAECBQMSA3gtLgpDCgIEAhIFfACCAQEa
NiBSZXByZXNlbnRzIHRoZSBjdXJyZW50IHN0YXRlIG9mIGEgdGhlIHNjZW5lJ3Mgc2xvdHMu
CgoKCgMEAgESA3wIDQoyCgQEAgIAEgN+AkIaJSBUaGUgY3VycmVudCBzdGF0dXMgb2Ygc2xv
dCBmaWxsaW5nLgoKDAoFBAICAAYSA34CNgoMCgUEAgIAARIDfjc9CgwKBQQCAgADEgN+QEEK
PAoEBAICARIEgQECQRouIFRoZSBzbG90cyBhc3NvY2lhdGVkIHdpdGggdGhlIGN1cnJlbnQg
c2NlbmUuCgoNCgUEAgIBBhIEgQECNgoNCgUEAgIBARIEgQE3PAoNCgUEAgIBAxIEgQE/QAoy
CgIEAxIGhQEAiwEBGiQgSW5mb3JtYXRpb24gcmVsYXRlZCB0byB1c2VyIGlucHV0LgoKCwoD
BAMBEgSFAQgdCkUKBAQDAgASBIcBAhIaNyBUeXBlIG9mIHVzZXIgaW5wdXQuIEUuZy4ga2V5
Ym9hcmQsIHZvaWNlLCB0b3VjaCwgZXRjLgoKDQoFBAMCAAUSBIcBAggKDQoFBAMCAAESBIcB
CQ0KDQoFBAMCAAMSBIcBEBEKMgoEBAMCARIEigECHBokIE9yaWdpbmFsIHRleHQgaW5wdXQg
ZnJvbSB0aGUgdXNlci4KCg0KBQQDAgEFEgSKAQIICg0KBQQDAgEBEgSKAQkXCg0KBQQDAgED
EgSKARobCpUBCgIEBBIGjwEAmwEBGoYBIEluZm9ybWF0aW9uIGFib3V0IHRyaWdnZXJlZCBp
bnRlbnQgbWF0Y2ggKGdsb2JhbCBvciB3aXRoaW4gYSBzY2VuZSk6CiBodHRwczovL2RldmVs
b3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0aW9uYWwvaW50ZW50cwoKCwoD
BAQBEgSPAQgTCjsKBAQEAgASBJEBAhcaLSBJbnRlbnQgaWQgd2hpY2ggdHJpZ2dlcmVkIHRo
aXMgaW50ZXJhY3Rpb24uCgoNCgUEBAIABRIEkQECCAoNCgUEBAIAARIEkQEJEgoNCgUEBAIA
AxIEkQEVFgpGCgQEBAIBEgSUAQJdGjggUGFyYW1ldGVycyBvZiBpbnRlbnQgd2hpY2ggdHJp
Z2dlcmVkIHRoaXMgaW50ZXJhY3Rpb24uCgoNCgUEBAIBBhIElAECRgoNCgUEBAIBARIElAFH
WAoNCgUEBAIBAxIElAFbXApBCgQEBAICEgSXAQIVGjMgTmFtZSBvZiB0aGUgaGFuZGxlciBh
dHRhY2hlZCB0byB0aGlzIGludGVyYWN0aW9uLgoKDQoFBAQCAgUSBJcBAggKDQoFBAQCAgES
BJcBCRAKDQoFBAQCAgMSBJcBExQKOQoEBAQCAxIEmgECGxorIFNjZW5lIHRvIHdoaWNoIHRo
aXMgaW50ZXJhY3Rpb24gbGVhZHMgdG8uCgoNCgUEBAIDBRIEmgECCAoNCgUEBAIDARIEmgEJ
FgoNCgUEBAIDAxIEmgEZGgp7CgIEBRIGnwEApQEBGm0gUmVzdWx0cyBvZiBjb25kaXRpb25z
IGV2YWx1YXRpb246CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQv
Y29udmVyc2F0aW9uYWwvc2NlbmVzI2NvbmRpdGlvbnMKCgsKAwQFARIEnwEIGwpDCgQEBQIA
EgShAQIrGjUgTGlzdCBvZiBjb25kaXRpb25zIHdoaWNoIHdlcmUgZXZhbHVhdGVkIHRvICdm
YWxzZScuCgoNCgUEBQIABBIEoQECCgoNCgUEBQIABhIEoQELFAoNCgUEBQIAARIEoQEVJgoN
CgUEBQIAAxIEoQEpKgpKCgQEBQIBEgSkAQIiGjwgVGhlIGZpcnN0IGNvbmRpdGlvbiB3aGlj
aCB3YXMgZXZhbHVhdGVkIHRvICd0cnVlJywgaWYgYW55LgoKDQoFBAUCAQYSBKQBAgsKDQoF
BAUCAQESBKQBDB0KDQoFBAUCAQMSBKQBICEKJAoCBAYSBqgBALEBARoWIEV2YWx1YXRlZCBj
b25kaXRpb24uCgoLCgMEBgESBKgBCBEKNwoEBAYCABIEqgECGBopIEV4cHJlc3Npb24gc3Bl
Y2lmaWVkIGluIHRoaXMgY29uZGl0aW9uLgoKDQoFBAYCAAUSBKoBAggKDQoFBAYCAAESBKoB
CRMKDQoFBAYCAAMSBKoBFhcKPgoEBAYCARIErQECFRowIEhhbmRsZXIgbmFtZSBzcGVjaWZp
ZWQgaW4gZXZhbHVhdGVkIGNvbmRpdGlvbi4KCg0KBQQGAgEFEgStAQIICg0KBQQGAgEBEgSt
AQkQCg0KBQQGAgEDEgStARMUCkMKBAQGAgISBLABAhsaNSBEZXN0aW5hdGlvbiBzY2VuZSBz
cGVjaWZpZWQgaW4gZXZhbHVhdGVkIGNvbmRpdGlvbi4KCg0KBQQGAgIFEgSwAQIICg0KBQQG
AgIBEgSwAQkWCg0KBQQGAgIDEgSwARkaCooBCgIEBxIGtQEAuAEBGnwgSW5mb3JtYXRpb24g
YWJvdXQgZXhlY3V0aW9uIG9mIG9uU2NlbmVFbnRlciBzdGFnZToKIGh0dHBzOi8vZGV2ZWxv
cGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9jb252ZXJzYXRpb25hbC9zY2VuZXMjb25fZW50
ZXIKCgsKAwQHARIEtQEIFAo9CgQEBwIAEgS3AQIVGi8gSGFuZGxlciBuYW1lIHNwZWNpZmll
ZCBpbiBvblNjZW5lRW50ZXIgZXZlbnQuCgoNCgUEBwIABRIEtwECCAoNCgUEBwIAARIEtwEJ
EAoNCgUEBwIAAxIEtwETFAqfAQoCBAgSBrwBAL8BARqQASBFdmVudCB0cmlnZ2VyZWQgYnkg
ZGVzdGluYXRpb24gc2NlbmUgcmV0dXJuZWQgZnJvbSB3ZWJob29rOgogaHR0cHM6Ly9kZXZl
bG9wZXJzLmdvb2dsZS5jb20vYXNzaXN0YW50L2NvbnZlcnNhdGlvbmFsL3dlYmhvb2tzI3Ry
YW5zaXRpb25fc2NlbmVzCgoLCgMECAESBLwBCCIKPQoEBAgCABIEvgECGxovIElEIG9mIHRo
ZSBzY2VuZSB0aGUgdHJhbnNpdGlvbiBpcyBsZWFkaW5nIHRvLgoKDQoFBAgCAAUSBL4BAggK
DQoFBAgCAAESBL4BCRYKDQoFBAgCAAMSBL4BGRoKmAEKAgQJEgbDAQDGAQEaiQEgSW5mb3Jt
YXRpb24gYWJvdXQgYSByZXF1ZXN0IGRpc3BhdGNoZWQgdG8gdGhlIEFjdGlvbiB3ZWJob29r
OgogaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYXNzaXN0YW50L2NvbnZlcnNhdGlv
bmFsL3dlYmhvb2tzI3BheWxvYWRzCgoLCgMECQESBMMBCBYKLwoEBAkCABIExQECGhohIFBh
eWxvYWQgb2YgdGhlIHdlYmhvb2sgcmVxdWVzdC4KCg0KBQQJAgAFEgTFAQIICg0KBQQJAgAB
EgTFAQkVCg0KBQQJAgADEgTFARgZCpkBCgIEChIGygEAzQEBGooBIEluZm9ybWF0aW9uIGFi
b3V0IGEgcmVzcG9uc2UgcmVjZWl2ZWQgZnJvbSB0aGUgQWN0aW9uIHdlYmhvb2s6CiBodHRw
czovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0aW9uYWwvd2Vi
aG9va3MjcGF5bG9hZHMKCgsKAwQKARIEygEIFwowCgQECgIAEgTMAQIbGiIgUGF5bG9hZCBv
ZiB0aGUgd2ViaG9vayByZXNwb25zZS4KCg0KBQQKAgAFEgTMAQIICg0KBQQKAgABEgTMAQkW
Cg0KBQQKAgADEgTMARkaCn4KAgQLEgbRAQDUAQEacCBJbmZvcm1hdGlvbiBhYm91dCBtYXRj
aGVkIHNsb3Qocyk6CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQv
Y29udmVyc2F0aW9uYWwvc2NlbmVzI3Nsb3RfZmlsbGluZwoKCwoDBAsBEgTRAQgRCjwKBAQL
AgASBNMBAloaLiBQYXJhbWV0ZXJzIGV4dHJhY3RlZCBieSBOTFUgZnJvbSB1c2VyIGlucHV0
LgoKDQoFBAsCAAYSBNMBAkYKDQoFBAsCAAESBNMBR1UKDQoFBAsCAAMSBNMBWFkKhwEKAgQM
EgbYAQDeAQEaeSBJbmZvcm1hdGlvbiBhYm91dCBjdXJyZW50bHkgcmVxdWVzdGVkIHNsb3Q6
CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQvY29udmVyc2F0aW9u
YWwvc2NlbmVzI3Nsb3RfZmlsbGluZwoKCwoDBAwBEgTYAQgVCisKBAQMAgASBNoBAhIaHSBO
YW1lIG9mIHRoZSByZXF1ZXN0ZWQgc2xvdC4KCg0KBQQMAgAFEgTaAQIICg0KBQQMAgABEgTa
AQkNCg0KBQQMAgADEgTaARARChwKBAQMAgESBN0BAjcaDiBTbG90IHByb21wdC4KCg0KBQQM
AgEGEgTdAQIrCg0KBQQMAgEBEgTdASwyCg0KBQQMAgEDEgTdATU2CqMBCgIEDRIG4gEA5AEB
GpQBIEV2ZW50IHdoaWNoIGhhcHBlbnMgYWZ0ZXIgd2ViaG9vayB2YWxpZGF0aW9uIHdhcyBm
aW5pc2hlZCBmb3Igc2xvdChzKToKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2Fz
c2lzdGFudC9jb252ZXJzYXRpb25hbC9zY2VuZXMjc2xvdF9maWxsaW5nCgoLCgMEDQESBOIB
CBUKigEKAgQOEgboAQDqAQEafCBFdmVudCB3aGljaCBoYXBwZW5zIHdoZW4gZm9ybSBpcyBm
dWxseSBmaWxsZWQ6CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9hc3Npc3RhbnQv
Y29udmVyc2F0aW9uYWwvc2NlbmVzI3Nsb3RfZmlsbGluZwoKCwoDBA4BEgToAQgSCoYBCgIE
DxIG7gEA8AEBGnggRXZlbnQgd2hpY2ggaGFwcGVucyB3aGVuIHN5c3RlbSBuZWVkcyB1c2Vy
IGlucHV0OgogaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYXNzaXN0YW50L2NvbnZl
cnNhdGlvbmFsL3NjZW5lcyNpbnB1dAoKCwoDBA8BEgTuAQgbCksKAgQQEgbzAQD1AQEaPSBF
dmVudCB3aGljaCBpbmZvcm1zIHRoYXQgY29udmVyc2F0aW9uIHdpdGggYWdlbnQgd2FzIGVu
ZGVkLgoKCwoDBBABEgTzAQgXYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::EventLogs::ExecutionEvent ===
    # Fields for ExecutionEvent
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: execution_state Type: 11 (.google.actions.sdk.v2.ExecutionState)
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: user_input Type: 11 (.google.actions.sdk.v2.UserConversationInput)
    # Field: intent_match Type: 11 (.google.actions.sdk.v2.IntentMatch)
    # Field: conditions_evaluated Type: 11 (.google.actions.sdk.v2.ConditionsEvaluated)
    # Field: on_scene_enter Type: 11 (.google.actions.sdk.v2.OnSceneEnter)
    # Field: webhook_request Type: 11 (.google.actions.sdk.v2.WebhookRequest)
    # Field: webhook_response Type: 11 (.google.actions.sdk.v2.WebhookResponse)
    # Field: webhook_initiated_transition Type: 11 (.google.actions.sdk.v2.WebhookInitiatedTransition)
    # Field: slot_match Type: 11 (.google.actions.sdk.v2.SlotMatch)
    # Field: slot_requested Type: 11 (.google.actions.sdk.v2.SlotRequested)
    # Field: slot_validated Type: 11 (.google.actions.sdk.v2.SlotValidated)
    # Field: form_filled Type: 11 (.google.actions.sdk.v2.FormFilled)
    # Field: waiting_user_input Type: 11 (.google.actions.sdk.v2.WaitingForUserInput)
    # Field: end_conversation Type: 11 (.google.actions.sdk.v2.EndConversation)
    # Field: warning_messages Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::ExecutionState ===
    # Fields for ExecutionState
    # Field: current_scene_id Type: 9 ()
    # Field: session_storage Type: 11 (.google.protobuf.Struct)
    # Field: slots Type: 11 (.google.actions.sdk.v2.Slots)
    # Field: prompt_queue Type: 11 (.google.actions.sdk.v2.conversation.Prompt)
    # Field: user_storage Type: 11 (.google.protobuf.Struct)
    # Field: household_storage Type: 11 (.google.protobuf.Struct)

# === Message: Google::Actions::Sdk::V2::EventLogs::Slots ===
    # Fields for Slots
    # Field: status Type: 14 (.google.actions.sdk.v2.conversation.SlotFillingStatus)
    # Field: slots Type: 11 (.google.actions.sdk.v2.Slots.SlotsEntry)

# === Message: Google::Actions::Sdk::V2::EventLogs::UserConversationInput ===
    # Fields for UserConversationInput
    # Field: type Type: 9 ()
    # Field: original_query Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::IntentMatch ===
    # Fields for IntentMatch
    # Field: intent_id Type: 9 ()
    # Field: intent_parameters Type: 11 (.google.actions.sdk.v2.IntentMatch.IntentParametersEntry)
    # Field: handler Type: 9 ()
    # Field: next_scene_id Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated ===
    # Fields for ConditionsEvaluated
    # Field: failed_conditions Type: 11 (.google.actions.sdk.v2.Condition)
    # Field: success_condition Type: 11 (.google.actions.sdk.v2.Condition)

# === Message: Google::Actions::Sdk::V2::EventLogs::Condition ===
    # Fields for Condition
    # Field: expression Type: 9 ()
    # Field: handler Type: 9 ()
    # Field: next_scene_id Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::OnSceneEnter ===
    # Fields for OnSceneEnter
    # Field: handler Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition ===
    # Fields for WebhookInitiatedTransition
    # Field: next_scene_id Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::WebhookRequest ===
    # Fields for WebhookRequest
    # Field: request_json Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::WebhookResponse ===
    # Fields for WebhookResponse
    # Field: response_json Type: 9 ()

# === Message: Google::Actions::Sdk::V2::EventLogs::SlotMatch ===
    # Fields for SlotMatch
    # Field: nlu_parameters Type: 11 (.google.actions.sdk.v2.SlotMatch.NluParametersEntry)

# === Message: Google::Actions::Sdk::V2::EventLogs::SlotRequested ===
    # Fields for SlotRequested
    # Field: slot Type: 9 ()
    # Field: prompt Type: 11 (.google.actions.sdk.v2.conversation.Prompt)

# === Message: Google::Actions::Sdk::V2::EventLogs::SlotValidated ===
    # Fields for SlotValidated

# === Message: Google::Actions::Sdk::V2::EventLogs::FormFilled ===
    # Fields for FormFilled

# === Message: Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput ===
    # Fields for WaitingForUserInput

# === Message: Google::Actions::Sdk::V2::EventLogs::EndConversation ===
    # Fields for EndConversation

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::EventLogs - Compiled Protocol Buffers messages for google/actions/sdk/v2/event_logs.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::EventLogs;

    my $msg = Google::Actions::Sdk::V2::EventLogs::ExecutionEvent->new({
        event_time => $event_time,
        execution_state => $execution_state,
        status => $status,
        user_input => $user_input,
    });

    # Read or update a field
    my $val = $msg->event_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::EventLogs::ExecutionEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/event_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::EventLogs::ExecutionEvent

Contains information about execution event which happened during processing
Actions Builder conversation request. For an overview of the stages involved
in a conversation request, see
https://developers.google.com/assistant/conversational/actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the event happened.

=item * C<< $msg->execution_state() >> / C<< $msg->execution_state($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::ExecutionState>)

State of the execution during this event.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Resulting status of particular execution step.

=item * C<< $msg->user_input() >> / C<< $msg->user_input($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::UserConversationInput>)

User input handling event.

=item * C<< $msg->intent_match() >> / C<< $msg->intent_match($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::IntentMatch>)

Intent matching event.

=item * C<< $msg->conditions_evaluated() >> / C<< $msg->conditions_evaluated($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated>)

Condition evaluation event.

=item * C<< $msg->on_scene_enter() >> / C<< $msg->on_scene_enter($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::OnSceneEnter>)

OnSceneEnter execution event.

=item * C<< $msg->webhook_request() >> / C<< $msg->webhook_request($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::WebhookRequest>)

Webhook request dispatch event.

=item * C<< $msg->webhook_response() >> / C<< $msg->webhook_response($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::WebhookResponse>)

Webhook response receipt event.

=item * C<< $msg->webhook_initiated_transition() >> / C<< $msg->webhook_initiated_transition($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition>)

Webhook-initiated transition event.

=item * C<< $msg->slot_match() >> / C<< $msg->slot_match($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::SlotMatch>)

Slot matching event.

=item * C<< $msg->slot_requested() >> / C<< $msg->slot_requested($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::SlotRequested>)

Slot requesting event.

=item * C<< $msg->slot_validated() >> / C<< $msg->slot_validated($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::SlotValidated>)

Slot validation event.

=item * C<< $msg->form_filled() >> / C<< $msg->form_filled($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::FormFilled>)

Form filling event.

=item * C<< $msg->waiting_user_input() >> / C<< $msg->waiting_user_input($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput>)

Waiting-for-user-input event.

=item * C<< $msg->end_conversation() >> / C<< $msg->end_conversation($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::EndConversation>)

End-of-conversation event.

=item * C<< $msg->warning_messages() >> / C<< $msg->warning_messages($value) >>

Type: C<String>

List of warnings generated during execution of this Event. Warnings are
tips for the developer discovered during the conversation request. These
are usually non-critical and do not halt the execution of the request. For
example, a warnings might be generated when webhook tries to override a
custom Type which does not exist. Errors are reported as a failed status
code, but warnings can be present even when the status is OK.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::ExecutionState

Current state of the execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->current_scene_id() >> / C<< $msg->current_scene_id($value) >>

Type: C<String>

ID of the scene which is currently  active.

=item * C<< $msg->session_storage() >> / C<< $msg->session_storage($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

State of the session storage:
https://developers.google.com/assistant/conversational/storage-session

=item * C<< $msg->slots() >> / C<< $msg->slots($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::Slots>)

State of the slots filling, if applicable:
https://developers.google.com/assistant/conversational/scenes#slot_filling

=item * C<< $msg->prompt_queue() >> / C<< $msg->prompt_queue($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Prompt::Prompt>)

Prompt queue:
https://developers.google.com/assistant/conversational/prompts

=item * C<< $msg->user_storage() >> / C<< $msg->user_storage($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

State of the user storage:
https://developers.google.com/assistant/conversational/storage-user

=item * C<< $msg->household_storage() >> / C<< $msg->household_storage($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

State of the home storage:
https://developers.google.com/assistant/conversational/storage-home

=back

=head2 Google::Actions::Sdk::V2::EventLogs::Slots

Represents the current state of a the scene's slots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::SlotFillingStatus>)

The current status of slot filling.

=item * C<< $msg->slots() >> / C<< $msg->slots($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::Slots::SlotsEntry>)

The slots associated with the current scene.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::UserConversationInput

Information related to user input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Type of user input. E.g. keyboard, voice, touch, etc.

=item * C<< $msg->original_query() >> / C<< $msg->original_query($value) >>

Type: C<String>

Original text input from the user.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::IntentMatch

Information about triggered intent match (global or within a scene):
https://developers.google.com/assistant/conversational/intents

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->intent_id() >> / C<< $msg->intent_id($value) >>

Type: C<String>

Intent id which triggered this interaction.

=item * C<< $msg->intent_parameters() >> / C<< $msg->intent_parameters($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::IntentMatch::IntentParametersEntry>)

Parameters of intent which triggered this interaction.

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<String>

Name of the handler attached to this interaction.

=item * C<< $msg->next_scene_id() >> / C<< $msg->next_scene_id($value) >>

Type: C<String>

Scene to which this interaction leads to.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated

Results of conditions evaluation:
https://developers.google.com/assistant/conversational/scenes#conditions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->failed_conditions() >> / C<< $msg->failed_conditions($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::Condition>)

List of conditions which were evaluated to 'false'.

=item * C<< $msg->success_condition() >> / C<< $msg->success_condition($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::Condition>)

The first condition which was evaluated to 'true', if any.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::Condition

Evaluated condition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expression() >> / C<< $msg->expression($value) >>

Type: C<String>

Expression specified in this condition.

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<String>

Handler name specified in evaluated condition.

=item * C<< $msg->next_scene_id() >> / C<< $msg->next_scene_id($value) >>

Type: C<String>

Destination scene specified in evaluated condition.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::OnSceneEnter

Information about execution of onSceneEnter stage:
https://developers.google.com/assistant/conversational/scenes#on_enter

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<String>

Handler name specified in onSceneEnter event.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition

Event triggered by destination scene returned from webhook:
https://developers.google.com/assistant/conversational/webhooks#transition_scenes

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->next_scene_id() >> / C<< $msg->next_scene_id($value) >>

Type: C<String>

ID of the scene the transition is leading to.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::WebhookRequest

Information about a request dispatched to the Action webhook:
https://developers.google.com/assistant/conversational/webhooks#payloads

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request_json() >> / C<< $msg->request_json($value) >>

Type: C<String>

Payload of the webhook request.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::WebhookResponse

Information about a response received from the Action webhook:
https://developers.google.com/assistant/conversational/webhooks#payloads

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response_json() >> / C<< $msg->response_json($value) >>

Type: C<String>

Payload of the webhook response.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::SlotMatch

Information about matched slot(s):
https://developers.google.com/assistant/conversational/scenes#slot_filling

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nlu_parameters() >> / C<< $msg->nlu_parameters($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::EventLogs::SlotMatch::NluParametersEntry>)

Parameters extracted by NLU from user input.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::SlotRequested

Information about currently requested slot:
https://developers.google.com/assistant/conversational/scenes#slot_filling

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->slot() >> / C<< $msg->slot($value) >>

Type: C<String>

Name of the requested slot.

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Prompt::Prompt>)

Slot prompt.

=back

=head2 Google::Actions::Sdk::V2::EventLogs::SlotValidated

Event which happens after webhook validation was finished for slot(s):
https://developers.google.com/assistant/conversational/scenes#slot_filling

Inherits from L<Protobuf::Message>.

=head2 Google::Actions::Sdk::V2::EventLogs::FormFilled

Event which happens when form is fully filled:
https://developers.google.com/assistant/conversational/scenes#slot_filling

Inherits from L<Protobuf::Message>.

=head2 Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput

Event which happens when system needs user input:
https://developers.google.com/assistant/conversational/scenes#input

Inherits from L<Protobuf::Message>.

=head2 Google::Actions::Sdk::V2::EventLogs::EndConversation

Event which informs that conversation with agent was ended.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::EventLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
