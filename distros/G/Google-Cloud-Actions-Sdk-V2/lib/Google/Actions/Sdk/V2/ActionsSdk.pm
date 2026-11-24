package Google::Actions::Sdk::V2::ActionsSdk;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::AccountLinkingSecret };
    eval { require Google::Actions::Sdk::V2::Files };
    eval { require Google::Actions::Sdk::V2::ReleaseChannel };
    eval { require Google::Actions::Sdk::V2::ValidationResults };
    eval { require Google::Actions::Sdk::V2::Version };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvYWN0aW9ucy9zZGsvdjIvYWN0aW9uc19zZGsucHJvdG8SFWdvb2dsZS5hY3Rp
b25zLnNkay52MhoyZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2FjY291bnRfbGlua2luZ19zZWNy
ZXQucHJvdG8aIWdvb2dsZS9hY3Rpb25zL3Nkay92Mi9maWxlcy5wcm90bxorZ29vZ2xlL2Fj
dGlvbnMvc2RrL3YyL3JlbGVhc2VfY2hhbm5lbC5wcm90bxouZ29vZ2xlL2FjdGlvbnMvc2Rr
L3YyL3ZhbGlkYXRpb25fcmVzdWx0cy5wcm90bxojZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL3Zl
cnNpb24ucHJvdG8aHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkv
Y2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8iigEK
EVdyaXRlRHJhZnRSZXF1ZXN0EjwKBnBhcmVudBgBIAEoCUIk4EEC+kEeEhxhY3Rpb25zLmdv
b2dsZWFwaXMuY29tL0RyYWZ0UgZwYXJlbnQSNwoFZmlsZXMYBCABKAsyHC5nb29nbGUuYWN0
aW9ucy5zZGsudjIuRmlsZXNCA+BBAlIFZmlsZXMisQEKBURyYWZ0EhIKBG5hbWUYASABKAlS
BG5hbWUSVwoSdmFsaWRhdGlvbl9yZXN1bHRzGAIgASgLMiguZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLlZhbGlkYXRpb25SZXN1bHRzUhF2YWxpZGF0aW9uUmVzdWx0czo76kE4ChxhY3Rpb25z
Lmdvb2dsZWFwaXMuY29tL0RyYWZ0Ehhwcm9qZWN0cy97cHJvamVjdH0vZHJhZnQiiwUKE1dy
aXRlUHJldmlld1JlcXVlc3QSPgoGcGFyZW50GAEgASgJQibgQQL6QSASHmFjdGlvbnMuZ29v
Z2xlYXBpcy5jb20vUHJldmlld1IGcGFyZW50EjQKBWZpbGVzGAUgASgLMhwuZ29vZ2xlLmFj
dGlvbnMuc2RrLnYyLkZpbGVzSABSBWZpbGVzElMKBWRyYWZ0GAYgASgLMjsuZ29vZ2xlLmFj
dGlvbnMuc2RrLnYyLldyaXRlUHJldmlld1JlcXVlc3QuQ29udGVudEZyb21EcmFmdEgAUgVk
cmFmdBJ1ChFzdWJtaXR0ZWRfdmVyc2lvbhgHIAEoCzJGLmdvb2dsZS5hY3Rpb25zLnNkay52
Mi5Xcml0ZVByZXZpZXdSZXF1ZXN0LkNvbnRlbnRGcm9tU3VibWl0dGVkVmVyc2lvbkgAUhBz
dWJtaXR0ZWRWZXJzaW9uEmoKEHByZXZpZXdfc2V0dGluZ3MYBCABKAsyOi5nb29nbGUuYWN0
aW9ucy5zZGsudjIuV3JpdGVQcmV2aWV3UmVxdWVzdC5QcmV2aWV3U2V0dGluZ3NCA+BBAlIP
cHJldmlld1NldHRpbmdzGhIKEENvbnRlbnRGcm9tRHJhZnQaXwobQ29udGVudEZyb21TdWJt
aXR0ZWRWZXJzaW9uEkAKB3ZlcnNpb24YASABKAlCJuBBAvpBIAoeYWN0aW9ucy5nb29nbGVh
cGlzLmNvbS9WZXJzaW9uUgd2ZXJzaW9uGkcKD1ByZXZpZXdTZXR0aW5ncxI0CgdzYW5kYm94
GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkJvb2xWYWx1ZVIHc2FuZGJveEIICgZzb3VyY2Ui
5wEKB1ByZXZpZXcSEgoEbmFtZRgBIAEoCVIEbmFtZRJXChJ2YWxpZGF0aW9uX3Jlc3VsdHMY
AiABKAsyKC5nb29nbGUuYWN0aW9ucy5zZGsudjIuVmFsaWRhdGlvblJlc3VsdHNSEXZhbGlk
YXRpb25SZXN1bHRzEiMKDXNpbXVsYXRvcl91cmwYAyABKAlSDHNpbXVsYXRvclVybDpK6kFH
Ch5hY3Rpb25zLmdvb2dsZWFwaXMuY29tL1ByZXZpZXcSJXByb2plY3RzL3twcm9qZWN0fS9w
cmV2aWV3cy97cHJldmlld30ivQEKFENyZWF0ZVZlcnNpb25SZXF1ZXN0Ej4KBnBhcmVudBgB
IAEoCUIm4EEC+kEgEh5hY3Rpb25zLmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBnBhcmVudBI3
CgVmaWxlcxgFIAEoCzIcLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5GaWxlc0ID4EECUgVmaWxl
cxIsCg9yZWxlYXNlX2NoYW5uZWwYBCABKAlCA+BBAVIOcmVsZWFzZUNoYW5uZWwigAEKEFJl
YWREcmFmdFJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lElMKJGNsaWVudF9zZWNy
ZXRfZW5jcnlwdGlvbl9rZXlfdmVyc2lvbhgCIAEoCUID4EEBUiBjbGllbnRTZWNyZXRFbmNy
eXB0aW9uS2V5VmVyc2lvbiJHChFSZWFkRHJhZnRSZXNwb25zZRIyCgVmaWxlcxgDIAEoCzIc
Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5GaWxlc1IFZmlsZXMiggEKElJlYWRWZXJzaW9uUmVx
dWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSUwokY2xpZW50X3NlY3JldF9lbmNyeXB0
aW9uX2tleV92ZXJzaW9uGAIgASgJQgPgQQFSIGNsaWVudFNlY3JldEVuY3J5cHRpb25LZXlW
ZXJzaW9uIkkKE1JlYWRWZXJzaW9uUmVzcG9uc2USMgoFZmlsZXMYASABKAsyHC5nb29nbGUu
YWN0aW9ucy5zZGsudjIuRmlsZXNSBWZpbGVzIkAKFEVuY3J5cHRTZWNyZXRSZXF1ZXN0EigK
DWNsaWVudF9zZWNyZXQYASABKAlCA+BBAlIMY2xpZW50U2VjcmV0InoKFUVuY3J5cHRTZWNy
ZXRSZXNwb25zZRJhChZhY2NvdW50X2xpbmtpbmdfc2VjcmV0GAEgASgLMisuZ29vZ2xlLmFj
dGlvbnMuc2RrLnYyLkFjY291bnRMaW5raW5nU2VjcmV0UhRhY2NvdW50TGlua2luZ1NlY3Jl
dCJTChREZWNyeXB0U2VjcmV0UmVxdWVzdBI7ChdlbmNyeXB0ZWRfY2xpZW50X3NlY3JldBgB
IAEoDEID4EECUhVlbmNyeXB0ZWRDbGllbnRTZWNyZXQiPAoVRGVjcnlwdFNlY3JldFJlc3Bv
bnNlEiMKDWNsaWVudF9zZWNyZXQYASABKAlSDGNsaWVudFNlY3JldCJhChlMaXN0U2FtcGxl
UHJvamVjdHNSZXF1ZXN0EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAIgASgJQgPgQQFSCXBhZ2VUb2tlbiKTAQoaTGlzdFNhbXBsZVByb2plY3Rz
UmVzcG9uc2USTQoPc2FtcGxlX3Byb2plY3RzGAEgAygLMiQuZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLlNhbXBsZVByb2plY3RSDnNhbXBsZVByb2plY3RzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbiKwAQoNU2FtcGxlUHJvamVjdBISCgRuYW1lGAEgASgJUgRu
YW1lEh0KCmhvc3RlZF91cmwYAiABKAlSCWhvc3RlZFVybBIgCgtkZXNjcmlwdGlvbhgDIAEo
CVILZGVzY3JpcHRpb246SupBRwokYWN0aW9ucy5nb29nbGVhcGlzLmNvbS9TYW1wbGVQcm9q
ZWN0Eh9zYW1wbGVQcm9qZWN0cy97c2FtcGxlX3Byb2plY3R9Ip8BChpMaXN0UmVsZWFzZUNo
YW5uZWxzUmVxdWVzdBJFCgZwYXJlbnQYASABKAlCLeBBAvpBJxIlYWN0aW9ucy5nb29nbGVh
cGlzLmNvbS9SZWxlYXNlQ2hhbm5lbFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFn
ZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIpcBChtMaXN0UmVsZWFzZUNo
YW5uZWxzUmVzcG9uc2USUAoQcmVsZWFzZV9jaGFubmVscxgBIAMoCzIlLmdvb2dsZS5hY3Rp
b25zLnNkay52Mi5SZWxlYXNlQ2hhbm5lbFIPcmVsZWFzZUNoYW5uZWxzEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKRAQoTTGlzdFZlcnNpb25zUmVxdWVzdBI+
CgZwYXJlbnQYASABKAlCJuBBAvpBIBIeYWN0aW9ucy5nb29nbGVhcGlzLmNvbS9WZXJzaW9u
UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMg
ASgJUglwYWdlVG9rZW4iegoUTGlzdFZlcnNpb25zUmVzcG9uc2USOgoIdmVyc2lvbnMYASAD
KAsyHi5nb29nbGUuYWN0aW9ucy5zZGsudjIuVmVyc2lvblIIdmVyc2lvbnMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMoUMCgpBY3Rpb25zU2RrEoYBCgpXcml0
ZURyYWZ0EiguZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLldyaXRlRHJhZnRSZXF1ZXN0GhwuZ29v
Z2xlLmFjdGlvbnMuc2RrLnYyLkRyYWZ0Ii6C0+STAigiIy92Mi97cGFyZW50PXByb2plY3Rz
Lyp9L2RyYWZ0OndyaXRlOgEqKAESjgEKDFdyaXRlUHJldmlldxIqLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5Xcml0ZVByZXZpZXdSZXF1ZXN0Gh4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlBy
ZXZpZXciMILT5JMCKiIlL3YyL3twYXJlbnQ9cHJvamVjdHMvKn0vcHJldmlldzp3cml0ZToB
KigBEpIBCg1DcmVhdGVWZXJzaW9uEisuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLkNyZWF0ZVZl
cnNpb25SZXF1ZXN0Gh4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLlZlcnNpb24iMoLT5JMCLCIn
L3YyL3twYXJlbnQ9cHJvamVjdHMvKn0vdmVyc2lvbnM6Y3JlYXRlOgEqKAESjQEKCVJlYWRE
cmFmdBInLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5SZWFkRHJhZnRSZXF1ZXN0GiguZ29vZ2xl
LmFjdGlvbnMuc2RrLnYyLlJlYWREcmFmdFJlc3BvbnNlIiuC0+STAiUiIC92Mi97bmFtZT1w
cm9qZWN0cy8qL2RyYWZ0fTpyZWFkOgEqMAESmAEKC1JlYWRWZXJzaW9uEikuZ29vZ2xlLmFj
dGlvbnMuc2RrLnYyLlJlYWRWZXJzaW9uUmVxdWVzdBoqLmdvb2dsZS5hY3Rpb25zLnNkay52
Mi5SZWFkVmVyc2lvblJlc3BvbnNlIjCC0+STAioiJS92Mi97bmFtZT1wcm9qZWN0cy8qL3Zl
cnNpb25zLyp9OnJlYWQ6ASowARKIAQoNRW5jcnlwdFNlY3JldBIrLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5FbmNyeXB0U2VjcmV0UmVxdWVzdBosLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5F
bmNyeXB0U2VjcmV0UmVzcG9uc2UiHILT5JMCFiIRL3YyOmVuY3J5cHRTZWNyZXQ6ASoSiAEK
DURlY3J5cHRTZWNyZXQSKy5nb29nbGUuYWN0aW9ucy5zZGsudjIuRGVjcnlwdFNlY3JldFJl
cXVlc3QaLC5nb29nbGUuYWN0aW9ucy5zZGsudjIuRGVjcnlwdFNlY3JldFJlc3BvbnNlIhyC
0+STAhYiES92MjpkZWNyeXB0U2VjcmV0OgEqEpUBChJMaXN0U2FtcGxlUHJvamVjdHMSMC5n
b29nbGUuYWN0aW9ucy5zZGsudjIuTGlzdFNhbXBsZVByb2plY3RzUmVxdWVzdBoxLmdvb2ds
ZS5hY3Rpb25zLnNkay52Mi5MaXN0U2FtcGxlUHJvamVjdHNSZXNwb25zZSIagtPkkwIUEhIv
djIvc2FtcGxlUHJvamVjdHMStgEKE0xpc3RSZWxlYXNlQ2hhbm5lbHMSMS5nb29nbGUuYWN0
aW9ucy5zZGsudjIuTGlzdFJlbGVhc2VDaGFubmVsc1JlcXVlc3QaMi5nb29nbGUuYWN0aW9u
cy5zZGsudjIuTGlzdFJlbGVhc2VDaGFubmVsc1Jlc3BvbnNlIjiC0+STAikSJy92Mi97cGFy
ZW50PXByb2plY3RzLyp9L3JlbGVhc2VDaGFubmVsc9pBBnBhcmVudBKaAQoMTGlzdFZlcnNp
b25zEiouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLkxpc3RWZXJzaW9uc1JlcXVlc3QaKy5nb29n
bGUuYWN0aW9ucy5zZGsudjIuTGlzdFZlcnNpb25zUmVzcG9uc2UiMYLT5JMCIhIgL3YyL3tw
YXJlbnQ9cHJvamVjdHMvKn0vdmVyc2lvbnPaQQZwYXJlbnQaGcpBFmFjdGlvbnMuZ29vZ2xl
YXBpcy5jb21CaAoZY29tLmdvb2dsZS5hY3Rpb25zLnNkay52MkIPQWN0aW9uc1Nka1Byb3Rv
UAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsv
djI7c2RrSqNvCgcSBQ4AswMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAeCgkKAgMAEgMSADwKCQoCAwESAxMAKwoJCgIDAhIDFAA1CgkKAgMDEgMVADgK
CQoCAwQSAxYALQoJCgIDBRIDFwAmCgkKAgMGEgMYACEKCQoCAwcSAxkAKQoJCgIDCBIDGgAj
CgkKAgMJEgMbACgKCAoBCBIDHQBPCgkKAggLEgMdAE8KCAoBCBIDHgAiCgkKAggKEgMeACIK
CAoBCBIDHwAwCgkKAggIEgMfADAKCAoBCBIDIAAyCgkKAggBEgMgADIKVgoCBgASBCMAegEa
SiBBY3Rpb25zIFNESyBBUEkgd2hpY2ggYWxsb3dzIGRldmVsb3BlcnMgdG8gYnVpbGQgcHJv
amVjdHMgdXNpbmcgdGhlIFNESy4KCgoKAwYAARIDIwgSCgoKAwYAAxIDJAI+CgwKBQYAA5kI
EgMkAj4KPQoEBgACABIEJwIsAxovIFVwZGF0ZXMgdGhlIHByb2plY3QgZHJhZnQgYmFzZWQg
b24gdGhlIG1vZGVsLgoKDAoFBgACAAESAycGEAoMCgUGAAIABRIDJxEXCgwKBQYAAgACEgMn
GCkKDAoFBgACAAMSAyc0OQoNCgUGAAIABBIEKAQrBgoRCgkGAAIABLDKvCISBCgEKwYKRgoE
BgACARIELwI0Axo4IFVwZGF0ZXMgdGhlIHVzZXIncyBwcm9qZWN0IHByZXZpZXcgYmFzZWQg
b24gdGhlIG1vZGVsLgoKDAoFBgACAQESAy8GEgoMCgUGAAIBBRIDLxMZCgwKBQYAAgECEgMv
Gi0KDAoFBgACAQMSAy84PwoNCgUGAAIBBBIEMAQzBgoRCgkGAAIBBLDKvCISBDAEMwYKhQEK
BAYAAgISBDgCPQMadyBDcmVhdGVzIGEgcHJvamVjdCB2ZXJzaW9uIGJhc2VkIG9uIHRoZSBt
b2RlbCBhbmQgdHJpZ2dlcnMgZGVwbG95bWVudCB0byB0aGUKIHNwZWNpZmllZCByZWxlYXNl
IGNoYW5uZWwsIGlmIHNwZWNpZmllZC4KCgwKBQYAAgIBEgM4BhMKDAoFBgACAgUSAzgUGgoM
CgUGAAICAhIDOBsvCgwKBQYAAgIDEgM4OkEKDQoFBgACAgQSBDkEPAYKEQoJBgACAgSwyrwi
EgQ5BDwGCj4KBAYAAgMSBEACRQMaMCBSZWFkcyB0aGUgZW50aXJlIGNvbnRlbnQgb2YgdGhl
IHByb2plY3QgZHJhZnQuCgoMCgUGAAIDARIDQAYPCgwKBQYAAgMCEgNAECAKDAoFBgACAwYS
A0ArMQoMCgUGAAIDAxIDQDJDCg0KBQYAAgMEEgRBBEQGChEKCQYAAgMEsMq8IhIEQQREBgo+
CgQGAAIEEgRIAk0DGjAgUmVhZHMgdGhlIGVudGlyZSBjb250ZW50IG9mIGEgcHJvamVjdCB2
ZXJzaW9uLgoKDAoFBgACBAESA0gGEQoMCgUGAAIEAhIDSBIkCgwKBQYAAgQGEgNILzUKDAoF
BgACBAMSA0g2SQoNCgUGAAIEBBIESQRMBgoRCgkGAAIEBLDKvCISBEkETAYKuAIKBAYAAgUS
BFQCWQMaqQIgRW5jcnlwdHMgdGhlIE9BdXRoIGNsaWVudCBzZWNyZXQgdXNlZCBpbiBhY2Nv
dW50IGxpbmtpbmcgZmxvd3MuCiBUaGlzIGNhbiBiZSB1c2VkIHRvIGVuY3J5cHQgdGhlIGNs
aWVudCBzZWNyZXQgZm9yIHRoZSBmaXJzdCB0aW1lIChlLmcuCiBiZWZvcmUgdGhlIGZpcnN0
IHB1c2ggb3IgYWZ0ZXIgY2hhbmdpbmcgdGhlIGNsaWVudCBzZWNyZXQpIG9yIHRvIHJlLWVu
Y3J5cHQKIGEgY2xpZW50IHNlY3JldCB1c2luZyB0aGUgbGF0ZXN0IHByaW1hcnkga2V5IHZl
cnNpb24gKGNvbnNpZGVyaW5nIGtleQogcm90YXRpb24pLgoKDAoFBgACBQESA1QGEwoMCgUG
AAIFAhIDVBQoCgwKBQYAAgUDEgNUM0gKDQoFBgACBQQSBFUEWAYKEQoJBgACBQSwyrwiEgRV
BFgGCpwBCgQGAAIGEgRdAmIDGo0BIERlY3J5cHRzIHRoZSBPQXV0aCBjbGllbnQgc2VjcmV0
IHVzZWQgaW4gYWNjb3VudCBsaW5raW5nIGZsb3dzLgogVGhpcyBjYW4gYmUgdXNlZCB0byB2
aWV3IHRoZSBjbGllbnQgc2VjcmV0IChlLmcuIGFmdGVyIHB1bGxpbmcgYSBwcm9qZWN0KS4K
CgwKBQYAAgYBEgNdBhMKDAoFBgACBgISA10UKAoMCgUGAAIGAxIDXTNICg0KBQYAAgYEEgRe
BGEGChEKCQYAAgYEsMq8IhIEXgRhBgpMCgQGAAIHEgRlAmkDGj4gTGlzdHMgYWxsIHRoZSBz
YW1wbGUgcHJvamVjdHMgc3VwcG9ydGVkIGJ5IHRoZSBnYWN0aW9ucyBDTEkuCgoMCgUGAAIH
ARIDZQYYCgwKBQYAAgcCEgNlGTIKDAoFBgACBwMSA2U9VwoNCgUGAAIHBBIEZgRoBgoRCgkG
AAIHBLDKvCISBGYEaAYKTgoEBgACCBIEbAJxAxpAIExpc3RzIGFsbCByZWxlYXNlIGNoYW5u
ZWxzIGFuZCBjb3JyZXNwb25kaW5nIHZlcnNpb25zLCBpZiBhbnkuCgoMCgUGAAIIARIDbAYZ
CgwKBQYAAggCEgNsGjQKDAoFBgACCAMSA2w/WgoNCgUGAAIIBBIEbQRvBgoRCgkGAAIIBLDK
vCISBG0EbwYKDAoFBgACCAQSA3AENAoPCggGAAIIBJsIABIDcAQ0CjwKBAYAAgkSBHQCeQMa
LiBMaXN0cyBhbGwgdmVyc2lvbnMgYW5kIHRoZWlyIGN1cnJlbnQgc3RhdGVzLgoKDAoFBgAC
CQESA3QGEgoMCgUGAAIJAhIDdBMmCgwKBQYAAgkDEgN0MUUKDQoFBgACCQQSBHUEdwYKEQoJ
BgACCQSwyrwiEgR1BHcGCgwKBQYAAgkEEgN4BDQKDwoIBgACCQSbCAASA3gENAo0CgIEABIF
fQCPAQEaJyBTdHJlYW1pbmcgUlBDIHJlcXVlc3QgZm9yIFdyaXRlRHJhZnQuCgoKCgMEAAES
A30IGQqfAQoEBAACABIGgAEChQEEGo4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IG5hbWUgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMve3Byb2plY3R9YC4gVGhlCiBge3Byb2pl
Y3R9YCBpcyB0aGUgY2xvdWQgcHJvamVjdCBJRCBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2pl
Y3QuCgoNCgUEAAIABRIEgAECCAoNCgUEAAIAARIEgAEJDwoNCgUEAAIAAxIEgAESEwoPCgUE
AAIACBIGgAEUhQEDChAKCAQAAgAInAgAEgSBAQQqChEKBwQAAgAInwgSBoIBBIQBBQqrAwoE
BAACARIEjgECOxqcAyBSZXF1aXJlZC4gTGlzdCBvZiBmaWxlcyBzZW50IHRvIHRoZSBzZXJ2
ZXIgYXQgYSB0aW1lLiBUaGlzIGlzIGEgbGlzdCBvZiBjb25maWcgZmlsZXMKIG9yIGRhdGEg
ZmlsZXMuCiAxLiBUaGUgZmlyc3QgcmVxdWVzdCBtdXN0IGJlIGEgQ29uZmlnRmlsZXMuCiAy
LiBUaGUgZmlyc3QgcmVxdWVzdCBtdXN0IGhhdmUgYSBDb25maWdGaWxlIHdpdGggJ3NldHRp
bmdzJy4KIDMuIFRoZSBmaXJzdCByZXF1ZXN0IG11c3QgaGF2ZSBhIENvbmZpZ0ZpbGUgd2l0
aCAnbWFuaWZlc3QnLgogNC4gVGhlIHdlYmhvb2sgQ29uZmlnRmlsZSBjb3JyZXNwb25kaW5n
IHRvIGlubGluZSBjbG91ZCBmdW5jdGlvbiBtdXN0IGJlCiAgICBzdHJlYW1lZCBiZWZvcmUg
dGhlIERhdGFGaWxlIGNvcnJlc3BvbmRpbmcgdG8gaXRzIHNvdXJjZSBjb2RlLgoKDQoFBAAC
AQYSBI4BAgcKDQoFBAACAQESBI4BCA0KDQoFBAACAQMSBI4BEBEKDQoFBAACAQgSBI4BEjoK
EAoIBAACAQicCAASBI4BEzkKLQoCBAESBpIBAKABARofIERlZmluaXRpb24gb2YgZHJhZnQg
cmVzb3VyY2UuCgoLCgMEAQESBJIBCA0KDQoDBAEHEgaTAQKWAQQKDwoFBAEHnQgSBpMBApYB
BApnCgQEAQIAEgSaAQISGlkgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBkcmFmdCBp
biB0aGUgZm9sbG93aW5nIGZvcm1hdC4KIGBwcm9qZWN0cy97cHJvamVjdH0vZHJhZnRgCgoN
CgUEAQIABRIEmgECCAoNCgUEAQIAARIEmgEJDQoNCgUEAQIAAxIEmgEQEQqwAQoEBAECARIE
nwECKxqhASBWYWxpZGF0aW9uIHJlc3VsdHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9qZWN0
IGRyYWZ0IGNvbnRlbnQuIE5vdGUgdGhhdAogV3JpdGVEcmFmdCB1cGRhdGVzIHRoZSBkcmFm
dCBkZXNwaXRlIHRoZSB3YXJuaW5ncyBhcyB3YXJuaW5ncyBhcmUgbm90IGRyYWZ0CiBibG9j
a2luZy4KCg0KBQQBAgEGEgSfAQITCg0KBQQBAgEBEgSfARQmCg0KBQQBAgEDEgSfASkqCjcK
AgQCEgajAQDaAQEaKSBTdHJlYW1pbmcgUlBDIHJlcXVlc3QgZm9yIFdyaXRlUHJldmlldy4K
CgsKAwQCARIEowEIGwpOCgQEAgMAEgalAQKnAQMaPiBJbmRpY2F0ZXMgdGhlIHByZXZpZXcg
Y29udGVudCB3aWxsIGJlIGNvbWluZyBmcm9tIHRoZSBEcmFmdC4KCg0KBQQCAwABEgSlAQoa
ClcKBAQCAwESBqoBArMBAxpHIEluZGljYXRlcyB0aGUgcHJldmlldyBjb250ZW50IHdpbGwg
YmUgY29taW5nIGZyb20gYW4gZXhpdGluZyB2ZXJzaW9uLgoKDQoFBAIDAQESBKoBCiUKjwEK
BgQCAwECABIGrQEEsgEGGn0gUmVxdWlyZWQuIFN1Ym1pdHRlZCB2ZXJzaW9uIG9mIHRoZSBw
cm9qZWN0IHRvIGJlIHVzZWQgdG8gY3JlYXRlIGEgcHJldmlldy4KIEZvcm1hdDogYHByb2pl
Y3RzL3twcm9qZWN0fS92ZXJzaW9ucy97dmVyc2lvbn1gCgoPCgcEAgMBAgAFEgStAQQKCg8K
BwQCAwECAAESBK0BCxIKDwoHBAIDAQIAAxIErQEVFgoRCgcEAgMBAgAIEgatAReyAQUKEgoK
BAIDAQIACJwIABIErgEGLAoTCgkEAgMBAgAInwgSBq8BBrEBBwo0CgQEAgMCEga2AQK7AQMa
JCBTZXR0aW5ncyBmb3IgdXBkYXRpbmcgdGhlIHByZXZpZXcuCgoNCgUEAgMCARIEtgEKGQrt
AQoGBAIDAgIAEgS6AQQqGtwBIEluZGljYXRlcyB3aGV0aGVyIG9yIG5vdCB0byBydW4gY2Vy
dGFpbiBvcGVyYXRpb25zLCBzdWNoIGFzIHRyYW5zYWN0aW9ucywKIGluIHNhbmRib3ggbW9k
ZS4gQnkgZGVmYXVsdCwgcHJldmlldyByZXF1ZXN0cyBydW4gdGhlc2Ugb3BlcmF0aW9ucyBp
bgogc2FuZGJveCBtb2RlLiBJbiBvdGhlciB3b3JkcywgdGhlIGRlZmF1bHQgdmFsdWUgZm9y
IGBzYW5kYm94YCBpcyBgdHJ1ZWAuCgoPCgcEAgMCAgAGEgS6AQQdCg8KBwQCAwICAAESBLoB
HiUKDwoHBAIDAgIAAxIEugEoKQqfAQoEBAICABIGvwECxAEEGo4BIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIG5hbWUgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMve3Byb2plY3R9
YC4gVGhlCiBge3Byb2plY3R9YCBpcyB0aGUgY2xvdWQgcHJvamVjdCBJRCBhc3NvY2lhdGVk
IHdpdGggdGhlIHByb2plY3QuCgoNCgUEAgIABRIEvwECCAoNCgUEAgIAARIEvwEJDwoNCgUE
AgIAAxIEvwESEwoPCgUEAgIACBIGvwEUxAEDChAKCAQCAgAInAgAEgTAAQQqChEKBwQCAgAI
nwgSBsEBBMMBBQo6CgQEAggAEgbHAQLWAQMaKiBEYXRhIHNvdXJjZSB1c2VkIHRvIGNyZWF0
ZWQgdGhlIHByZXZpZXcuCgoNCgUEAggAARIExwEIDgqhAwoEBAICARIEzwEEFBqSAyBMaXN0
IG9mIGZpbGVzIHNlbnQgdG8gdGhlIHNlcnZlciBhdCBhIHRpbWUuIFRoaXMgaXMgYSBsaXN0
IG9mIGNvbmZpZwogZmlsZXMgb3IgZGF0YSBmaWxlcy4KIDEuIFRoZSBmaXJzdCByZXF1ZXN0
IG11c3QgYmUgYSBDb25maWdGaWxlcy4KIDIuIFRoZSBmaXJzdCByZXF1ZXN0IG11c3QgaGF2
ZSBhIENvbmZpZ0ZpbGUgd2l0aCAnc2V0dGluZ3MnLgogMy4gVGhlIGZpcnN0IHJlcXVlc3Qg
bXVzdCBoYXZlIGEgQ29uZmlnRmlsZSB3aXRoICdtYW5pZmVzdCcuCiA0LiBUaGUgd2ViaG9v
ayBDb25maWdGaWxlIGNvcnJlc3BvbmRpbmcgdG8gaW5saW5lIGNsb3VkIGZ1bmN0aW9uIG11
c3QgYmUKICAgIHN0cmVhbWVkIGJlZm9yZSB0aGUgRGF0YUZpbGUgY29ycmVzcG9uZGluZyB0
byBpdHMgc291cmNlIGNvZGUuCgoNCgUEAgIBBhIEzwEECQoNCgUEAgIBARIEzwEKDwoNCgUE
AgIBAxIEzwESEwo3CgQEAgICEgTSAQQfGikgQ29udGVudCBzb3VyY2VkIGZyb20gdGhlIHBy
b2plY3QgZHJhZnQuCgoNCgUEAgICBhIE0gEEFAoNCgUEAgICARIE0gEVGgoNCgUEAgICAxIE
0gEdHgo8CgQEAgIDEgTVAQQ2Gi4gQ29udGVudCBzb3VyY2VkIGZyb20gdGhlIGFuIGV4aXRp
bmcgdmVyc2lvbi4KCg0KBQQCAgMGEgTVAQQfCg0KBQQCAgMBEgTVASAxCg0KBQQCAgMDEgTV
ATQ1CkcKBAQCAgQSBNkBAlAaOSBSZXF1aXJlZC4gVGhlIHNldHRpbmdzIGZvciB1cGRhdGlu
ZyB0aGUgdXNlcidzIHByZXZpZXcuCgoNCgUEAgIEBhIE2QECEQoNCgUEAgIEARIE2QESIgoN
CgUEAgIEAxIE2QElJgoNCgUEAgIECBIE2QEnTwoQCggEAgIECJwIABIE2QEoTgovCgIEAxIG
3QEA7AEBGiEgRGVmaW5pdGlvbiBvZiBwcmV2aWV3IHJlc291cmNlLgoKCwoDBAMBEgTdAQgP
Cg0KAwQDBxIG3gEC4QEECg8KBQQDB50IEgbeAQLhAQQKWwoEBAMCABIE5QECEhpNIFRoZSB1
bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgcHJldmlldy4KIEZvcm1hdDogYHByb2plY3RzL3tw
cm9qZWN0fS9wcmV2aWV3YAoKDQoFBAMCAAUSBOUBAggKDQoFBAMCAAESBOUBCQ0KDQoFBAMC
AAMSBOUBEBEKVAoEBAMCARIE6AECKxpGIFZhbGlkYXRpb24gcmVzdWx0cyBhc3NvY2lhdGVk
IHdpdGggdGhlIHVzZXIgcHJvamVjdCBwcmV2aWV3IGNvbnRlbnQuCgoNCgUEAwIBBhIE6AEC
EwoNCgUEAwIBARIE6AEUJgoNCgUEAwIBAxIE6AEpKgo7CgQEAwICEgTrAQIbGi0gVGhlIHNp
bXVsYXRvciBVUkwgdG8gdGVzdCB0aGUgdXNlciBwcmV2aWV3LgoKDQoFBAMCAgUSBOsBAggK
DQoFBAMCAgESBOsBCRYKDQoFBAMCAgMSBOsBGRoKOAoCBAQSBu8BAIcCARoqIFN0cmVhbWlu
ZyBSUEMgcmVxdWVzdCBmb3IgQ3JlYXRlVmVyc2lvbi4KCgsKAwQEARIE7wEIHAqfAQoEBAQC
ABIG8gEC9wEEGo4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUgaW4gdGhl
IGZvcm1hdCBgcHJvamVjdHMve3Byb2plY3R9YC4gVGhlCiBge3Byb2plY3R9YCBpcyB0aGUg
Y2xvdWQgcHJvamVjdCBJRCBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoNCgUEBAIA
BRIE8gECCAoNCgUEBAIAARIE8gEJDwoNCgUEBAIAAxIE8gESEwoPCgUEBAIACBIG8gEU9wED
ChAKCAQEAgAInAgAEgTzAQQqChEKBwQEAgAInwgSBvQBBPYBBQqrAwoEBAQCARIEgAICOxqc
AyBSZXF1aXJlZC4gTGlzdCBvZiBmaWxlcyBzZW50IHRvIHRoZSBzZXJ2ZXIgYXQgYSB0aW1l
LiBUaGlzIGlzIGEgbGlzdCBvZiBjb25maWcgZmlsZXMKIG9yIGRhdGEgZmlsZXMuCiAxLiBU
aGUgZmlyc3QgcmVxdWVzdCBtdXN0IGJlIGEgQ29uZmlnRmlsZXMuCiAyLiBUaGUgZmlyc3Qg
cmVxdWVzdCBtdXN0IGhhdmUgYSBDb25maWdGaWxlIHdpdGggJ3NldHRpbmdzJy4KIDMuIFRo
ZSBmaXJzdCByZXF1ZXN0IG11c3QgaGF2ZSBhIENvbmZpZ0ZpbGUgd2l0aCAnbWFuaWZlc3Qn
LgogNC4gVGhlIHdlYmhvb2sgQ29uZmlnRmlsZSBjb3JyZXNwb25kaW5nIHRvIGlubGluZSBj
bG91ZCBmdW5jdGlvbiBtdXN0IGJlCiAgICBzdHJlYW1lZCBiZWZvcmUgdGhlIERhdGFGaWxl
IGNvcnJlc3BvbmRpbmcgdG8gaXRzIHNvdXJjZSBjb2RlLgoKDQoFBAQCAQYSBIACAgcKDQoF
BAQCAQESBIACCA0KDQoFBAQCAQMSBIACEBEKDQoFBAQCAQgSBIACEjoKEAoIBAQCAQicCAAS
BIACEzkK1gEKBAQEAgISBIYCAkYaxwEgT3B0aW9uYWwuIFRoZSByZWxlYXNlIGNoYW5uZWwg
dG8gZGVwbG95IHRoZSB2ZXJzaW9uLCBpZiBzcGVjaWZpZWQuIFRoZSBzdXBwb3J0ZWQKIGJ1
aWx0IGluIHJlbGVhc2UgY2hhbm5lbHMgYXJlIGFjdGlvbnMuY2hhbm5lbHMuUHJvZHVjdGlv
biwKIGFjdGlvbnMuY2hhbm5lbHMuQ2xvc2VkQmV0YSwgYWN0aW9ucy5jaGFubmVscy5BbHBo
YS4KIC4KCg0KBQQEAgIFEgSGAgIICg0KBQQEAgIBEgSGAgkYCg0KBQQEAgIDEgSGAhscCg0K
BQQEAgIIEgSGAh1FChAKCAQEAgIInAgAEgSGAh5ECioKAgQFEgaKAgCUAgEaHCBSUEMgcmVx
dWVzdCBmb3IgUmVhZERyYWZ0LgoKCwoDBAUBEgSKAggYCqMBCgQEBQIAEgSNAgI7GpQBIFJl
cXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcmVzb3VyY2UgaW4gdGhlIGZvcm1hdCBgcHJvamVj
dHMve3Byb2plY3R9L2RyYWZ0YC4gVGhlCiBge3Byb2plY3R9YCBpcyB0aGUgY2xvdWQgcHJv
amVjdCBJRCBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoNCgUEBQIABRIEjQICCAoN
CgUEBQIAARIEjQIJDQoNCgUEBQIAAxIEjQIQEQoNCgUEBQIACBIEjQISOgoQCggEBQIACJwI
ABIEjQITOQr6AQoEBAUCARIEkwICWxrrASBPcHRpb25hbC4gVGhlIHZlcnNpb24gb2YgdGhl
IGNyeXB0byBrZXkgdXNlZCB0byBlbmNyeXB0IHRoZSBhY2NvdW50IGxpbmtpbmcgT0F1dGgK
IGNsaWVudCBzZWNyZXQuIElmIG5vdCBzcGVjaWZpZWQsIHRoZSBwcmltYXJ5IGtleSB2ZXJz
aW9uIGlzIHVzZWQgZm9yCiBlbmNyeXB0aW9uLiBPbmx5IHJlbGV2YW50IGZvciBwcm9qZWN0
cyB3aXRoIGFjY291bnQgbGlua2luZyB3aXRoIGNsaWVudAogc2VjcmV0LgoKDQoFBAUCAQUS
BJMCAggKDQoFBAUCAQESBJMCCS0KDQoFBAUCAQMSBJMCMDEKDQoFBAUCAQgSBJMCMloKEAoI
BAUCAQicCAASBJMCM1kKNQoCBAYSBpcCAJoCARonIFN0cmVhbWluZyBSUEMgcmVzcG9uc2Ug
Zm9yIFJlYWREcmFmdC4KCgsKAwQGARIElwIIGQo9CgQEBgIAEgSZAgISGi8gTGlzdCBvZiBm
aWxlcyBzZW50IGZyb20gdGhlIHNlcnZlciBhdCBhIHRpbWUuCgoNCgUEBgIABhIEmQICBwoN
CgUEBgIAARIEmQIIDQoNCgUEBgIAAxIEmQIQEQosCgIEBxIGnQIAqQIBGh4gUlBDIHJlcXVl
c3QgZm9yIFJlYWRWZXJzaW9uLgoKCwoDBAcBEgSdAggaCu8BCgQEBwIAEgSiAgI7GuABIFJl
cXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgdmVyc2lvbiByZXNvdXJjZSBpbiB0aGUgZm9ybWF0
CiBgcHJvamVjdHMve3Byb2plY3R9L3ZlcnNpb25zL3t2ZXJzaW9ufWAuIGB7cHJvamVjdH1g
IGlzIHRoZQogY2xvdWQgcHJvamVjdCBJRCBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3Qs
IGB7dmVyc2lvbn1gIGlzIHRoZQogaWRlbnRpZmllciBvZiB0aGUgdmVyc2lvbiBiZWluZyBy
ZWFkLgoKDQoFBAcCAAUSBKICAggKDQoFBAcCAAESBKICCQ0KDQoFBAcCAAMSBKICEBEKDQoF
BAcCAAgSBKICEjoKEAoIBAcCAAicCAASBKICEzkK+gEKBAQHAgESBKgCAlsa6wEgT3B0aW9u
YWwuIFRoZSB2ZXJzaW9uIG9mIHRoZSBjcnlwdG8ga2V5IHVzZWQgdG8gZW5jcnlwdCB0aGUg
YWNjb3VudCBsaW5raW5nIE9BdXRoCiBjbGllbnQgc2VjcmV0LiBJZiBub3Qgc3BlY2lmaWVk
LCB0aGUgcHJpbWFyeSBrZXkgdmVyc2lvbiBpcyB1c2VkIGZvcgogZW5jcnlwdGlvbi4gT25s
eSByZWxldmFudCBmb3IgcHJvamVjdHMgd2l0aCBhY2NvdW50IGxpbmtpbmcgd2l0aCBjbGll
bnQKIHNlY3JldC4KCg0KBQQHAgEFEgSoAgIICg0KBQQHAgEBEgSoAgktCg0KBQQHAgEDEgSo
AjAxCg0KBQQHAgEIEgSoAjJaChAKCAQHAgEInAgAEgSoAjNZCjcKAgQIEgasAgCvAgEaKSBT
dHJlYW1pbmcgUlBDIHJlc3BvbnNlIGZvciBSZWFkVmVyc2lvbi4KCgsKAwQIARIErAIIGwo9
CgQECAIAEgSuAgISGi8gTGlzdCBvZiBmaWxlcyBzZW50IGZyb20gdGhlIHNlcnZlciBhdCBh
IHRpbWUuCgoNCgUECAIABhIErgICBwoNCgUECAIAARIErgIIDQoNCgUECAIAAxIErgIQEQou
CgIECRIGsgIAtQIBGiAgUlBDIHJlcXVlc3QgZm9yIEVuY3J5cHRTZWNyZXQuCgoLCgMECQES
BLICCBwKRgoEBAkCABIEtAICRBo4IFJlcXVpcmVkLiBUaGUgYWNjb3VudCBsaW5raW5nIGNs
aWVudCBzZWNyZXQgcGxhaW50ZXh0LgoKDQoFBAkCAAUSBLQCAggKDQoFBAkCAAESBLQCCRYK
DQoFBAkCAAMSBLQCGRoKDQoFBAkCAAgSBLQCG0MKEAoIBAkCAAicCAASBLQCHEIKLwoCBAoS
BrgCALwCARohIFJQQyByZXNwb25zZSBmb3IgRW5jcnlwdFNlY3JldC4KCgsKAwQKARIEuAII
HQp1CgQECgIAEgS7AgIyGmcgQ29udGFpbnMgdGhlIGVuY3J5cHRlZCBhY2NvdW50IGxpbmtp
bmcgY2xpZW50IHNlY3JldCBhbmQgdGhlIGtleSB2ZXJzaW9uCiB1c2VkIHRvIGVuY3J5cHQg
dGhlIHNlY3JldC4KCg0KBQQKAgAGEgS7AgIWCg0KBQQKAgABEgS7AhctCg0KBQQKAgADEgS7
AjAxCi4KAgQLEga/AgDCAgEaICBSUEMgcmVxdWVzdCBmb3IgRGVjcnlwdFNlY3JldC4KCgsK
AwQLARIEvwIIHApHCgQECwIAEgTBAgJNGjkgUmVxdWlyZWQuIFRoZSBhY2NvdW50IGxpbmtp
bmcgY2xpZW50IHNlY3JldCBjaXBoZXJ0ZXh0LgoKDQoFBAsCAAUSBMECAgcKDQoFBAsCAAES
BMECCB8KDQoFBAsCAAMSBMECIiMKDQoFBAsCAAgSBMECJEwKEAoIBAsCAAicCAASBMECJUsK
LwoCBAwSBsUCAMgCARohIFJQQyByZXNwb25zZSBmb3IgRGVjcnlwdFNlY3JldC4KCgsKAwQM
ARIExQIIHQo8CgQEDAIAEgTHAgIbGi4gVGhlIGFjY291bnQgbGlua2luZyBjbGllbnQgc2Vj
cmV0IHBsYWludGV4dC4KCg0KBQQMAgAFEgTHAgIICg0KBQQMAgABEgTHAgkWCg0KBQQMAgAD
EgTHAhkaCjMKAgQNEgbLAgDVAgEaJSBSUEMgcmVxdWVzdCBmb3IgTGlzdFNhbXBsZVByb2pl
Y3RzLgoKCwoDBA0BEgTLAgghCuYBCgQEDQIAEgTQAgI/GtcBIE9wdGlvbmFsLiBUaGUgbWF4
aW11bSBudW1iZXIgb2Ygc2FtcGxlIHByb2plY3RzIHRvIHJldHVybi4gVGhlIHNlcnZpY2Ug
bWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLgogSWYgdW5zcGVjaWZpZWQsIGF0
IG1vc3QgMTAwMCBzYW1wbGUgcHJvamVjdHMgd2lsbCBiZSByZXR1cm5lZC4gVmFsdWVzIGFi
b3ZlCiAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBA0CAAUSBNACAgcKDQoF
BA0CAAESBNACCBEKDQoFBA0CAAMSBNACFBUKDQoFBA0CAAgSBNACFj4KEAoIBA0CAAicCAAS
BNACFz0KigEKBAQNAgESBNQCAkEafCBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZl
ZCBmcm9tIGEgcHJldmlvdXMgJ0xpc3RTYW1wbGVQcm9qZWN0cycgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBA0CAQUSBNQCAggK
DQoFBA0CAQESBNQCCRMKDQoFBA0CAQMSBNQCFhcKDQoFBA0CAQgSBNQCGEAKEAoIBA0CAQic
CAASBNQCGT8KNAoCBA4SBtgCAN8CARomIFJQQyByZXNwb25zZSBmb3IgTGlzdFNhbXBsZVBy
b2plY3RzLgoKCwoDBA4BEgTYAggiCjYKBAQOAgASBNoCAi0aKCBUaGUgbGlzdCBvZiBzYW1w
bGUgcHJvamVjdHMgc3VwcG9ydGVkLgoKDQoFBA4CAAQSBNoCAgoKDQoFBA4CAAYSBNoCCxgK
DQoFBA4CAAESBNoCGSgKDQoFBA4CAAMSBNoCKywKkAEKBAQOAgESBN4CAh0agQEgQSB0b2tl
biwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJz
ZXF1ZW50IHBhZ2VzLgoKDQoFBA4CAQUSBN4CAggKDQoFBA4CAQESBN4CCRgKDQoFBA4CAQMS
BN4CGxwKNgoCBA8SBuICAPECARooIERlZmluaXRpb24gb2Ygc2FtcGxlIHByb2plY3QgcmVz
b3VyY2UuCgoLCgMEDwESBOICCBUKDQoDBA8HEgbjAgLmAgQKDwoFBA8HnQgSBuMCAuYCBApa
CgQEDwIAEgTqAgISGkwgVGhlIG5hbWUgb2YgdGhlIHNhbXBsZSBwcm9qZWN0LgogRm9ybWF0
OiBgc2FtcGxlUHJvamVjdHMve3NhbXBsZV9wcm9qZWN0fWAKCg0KBQQPAgAFEgTqAgIICg0K
BQQPAgABEgTqAgkNCg0KBQQPAgADEgTqAhARCkMKBAQPAgESBO0CAhgaNSBUaGUgVVJMIHRv
IHRoZSB6aXAgZmlsZSB3aGVyZSB0aGUgc2FtcGxlIGlzIGhvc3RlZC4KCg0KBQQPAgEFEgTt
AgIICg0KBQQPAgEBEgTtAgkTCg0KBQQPAgEDEgTtAhYXCjYKBAQPAgISBPACAhkaKCBUaGUg
ZGVzY3JpcHRpb24gb2YgdGhlIHNhbXBsZSBwcm9qZWN0LgoKDQoFBA8CAgUSBPACAggKDQoF
BA8CAgESBPACCRQKDQoFBA8CAgMSBPACFxgKOAoCBBASBvQCAIgDARoqIFJQQyByZXF1ZXN0
IGZvciBsaXN0aW5nIHJlbGVhc2UgY2hhbm5lbHMKCgsKAwQQARIE9AIIIgqfAQoEBBACABIG
9wIC/AIEGo4BIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcmVzb3VyY2UgaW4gdGhlIGZv
cm1hdCBgcHJvamVjdHMve3Byb2plY3R9YC4gVGhlCiBge3Byb2plY3R9YCBpcyB0aGUgY2xv
dWQgcHJvamVjdCBJRCBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoNCgUEEAIABRIE
9wICCAoNCgUEEAIAARIE9wIJDwoNCgUEEAIAAxIE9wISEwoPCgUEEAIACBIG9wIU/AIDChAK
CAQQAgAInAgAEgT4AgQqChEKBwQQAgAInwgSBvkCBPsCBQqwAQoEBBACARIEgQMCFhqhASBU
aGUgbWF4aW11bSBudW1iZXIgb2YgcmVsZWFzZSBjaGFubmVscyB0byByZXR1cm4uIFRoZSBz
ZXJ2aWNlIG1heSByZXR1cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZp
ZWQsIGF0IG1vc3QgNTAgcmVsZWFzZSBjaGFubmVscyB3aWxsIGJlCiByZXR1cm5lZC4KCg0K
BQQQAgEFEgSBAwIHCg0KBQQQAgEBEgSBAwgRCg0KBQQQAgEDEgSBAxQVCv4BCgQEEAICEgSH
AwIYGu8BIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0UmVs
ZWFzZUNoYW5uZWxzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJz
ZXF1ZW50IHBhZ2UuCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHBy
b3ZpZGVkIHRvIGBMaXN0UmVsZWFzZUNoYW5uZWxzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0
aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBBACAgUSBIcDAggKDQoFBBACAgES
BIcDCRMKDQoFBBACAgMSBIcDFhcKOQoCBBESBosDAJIDARorIFJQQyByZXNwb25zZSBmb3Ig
bGlzdGluZyByZWxlYXNlIGNoYW5uZWxzCgoLCgMEEQESBIsDCCMKRgoEBBECABIEjQMCLxo4
IExpc3Qgb2YgdGhlIHJlbGVhc2UgY2hhbm5lbHMgZm9yIHRoZSBnaXZlbiBwcm9qZWN0IGlk
LgoKDQoFBBECAAQSBI0DAgoKDQoFBBECAAYSBI0DCxkKDQoFBBECAAESBI0DGioKDQoFBBEC
AAMSBI0DLS4KkAEKBAQRAgESBJEDAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQg
YXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBBEC
AQUSBJEDAggKDQoFBBECAQESBJEDCRgKDQoFBBECAQMSBJEDGxwKMAoCBBISBpUDAKkDARoi
IFJQQyByZXF1ZXN0IGZvciBsaXN0aW5nIHZlcnNpb25zCgoLCgMEEgESBJUDCBsKnwEKBAQS
AgASBpgDAp0DBBqOASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHJlc291cmNlIGluIHRo
ZSBmb3JtYXQgYHByb2plY3RzL3twcm9qZWN0fWAuIFRoZQogYHtwcm9qZWN0fWAgaXMgdGhl
IGNsb3VkIHByb2plY3QgSUQgYXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9qZWN0LgoKDQoFBBIC
AAUSBJgDAggKDQoFBBICAAESBJgDCQ8KDQoFBBICAAMSBJgDEhMKDwoFBBICAAgSBpgDFJ0D
AwoQCggEEgIACJwIABIEmQMEKgoRCgcEEgIACJ8IEgaaAwScAwUKoAEKBAQSAgESBKIDAhYa
kQEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHZlcnNpb25zIHRvIHJldHVybi4gVGhlIHNlcnZp
Y2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwg
YXQgbW9zdCA1MCB2ZXJzaW9ucyB3aWxsIGJlCiByZXR1cm5lZC4KCg0KBQQSAgEFEgSiAwIH
Cg0KBQQSAgEBEgSiAwgRCg0KBQQSAgEDEgSiAxQVCvABCgQEEgICEgSoAwIYGuEBIEEgcGFn
ZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0VmVyc2lvbnNgIGNhbGwu
CiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KIFdoZW4g
cGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RWZXJz
aW9uc2AKIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tl
bi4KCg0KBQQSAgIFEgSoAwIICg0KBQQSAgIBEgSoAwkTCg0KBQQSAgIDEgSoAxYXCjEKAgQT
EgasAwCzAwEaIyBSUEMgcmVzcG9uc2UgZm9yIGxpc3RpbmcgdmVyc2lvbnMKCgsKAwQTARIE
rAMIHAo+CgQEEwIAEgSuAwIgGjAgTGlzdCBvZiB0aGUgdmVyc2lvbnMgZm9yIHRoZSBnaXZl
biBwcm9qZWN0IGlkLgoKDQoFBBMCAAQSBK4DAgoKDQoFBBMCAAYSBK4DCxIKDQoFBBMCAAES
BK4DExsKDQoFBBMCAAMSBK4DHh8KkAEKBAQTAgESBLIDAh0agQEgQSB0b2tlbiwgd2hpY2gg
Y2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Uu
CiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBh
Z2VzLgoKDQoFBBMCAQUSBLIDAggKDQoFBBMCAQESBLIDCRgKDQoFBBMCAQMSBLIDGxxiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest ===
    # Fields for WriteDraftRequest
    # Field: parent Type: 9 ()
    # Field: files Type: 11 (.google.actions.sdk.v2.Files)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::Draft ===
    # Fields for Draft
    # Field: name Type: 9 ()
    # Field: validation_results Type: 11 (.google.actions.sdk.v2.ValidationResults)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest ===
    # Fields for WritePreviewRequest
    # Field: parent Type: 9 ()
    # Field: files Type: 11 (.google.actions.sdk.v2.Files)
    # Field: draft Type: 11 (.google.actions.sdk.v2.WritePreviewRequest.ContentFromDraft)
    # Field: submitted_version Type: 11 (.google.actions.sdk.v2.WritePreviewRequest.ContentFromSubmittedVersion)
    # Field: preview_settings Type: 11 (.google.actions.sdk.v2.WritePreviewRequest.PreviewSettings)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::Preview ===
    # Fields for Preview
    # Field: name Type: 9 ()
    # Field: validation_results Type: 11 (.google.actions.sdk.v2.ValidationResults)
    # Field: simulator_url Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest ===
    # Fields for CreateVersionRequest
    # Field: parent Type: 9 ()
    # Field: files Type: 11 (.google.actions.sdk.v2.Files)
    # Field: release_channel Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest ===
    # Fields for ReadDraftRequest
    # Field: name Type: 9 ()
    # Field: client_secret_encryption_key_version Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse ===
    # Fields for ReadDraftResponse
    # Field: files Type: 11 (.google.actions.sdk.v2.Files)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest ===
    # Fields for ReadVersionRequest
    # Field: name Type: 9 ()
    # Field: client_secret_encryption_key_version Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse ===
    # Fields for ReadVersionResponse
    # Field: files Type: 11 (.google.actions.sdk.v2.Files)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest ===
    # Fields for EncryptSecretRequest
    # Field: client_secret Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse ===
    # Fields for EncryptSecretResponse
    # Field: account_linking_secret Type: 11 (.google.actions.sdk.v2.AccountLinkingSecret)

# === Message: Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest ===
    # Fields for DecryptSecretRequest
    # Field: encrypted_client_secret Type: 12 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse ===
    # Fields for DecryptSecretResponse
    # Field: client_secret Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest ===
    # Fields for ListSampleProjectsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse ===
    # Fields for ListSampleProjectsResponse
    # Field: sample_projects Type: 11 (.google.actions.sdk.v2.SampleProject)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::SampleProject ===
    # Fields for SampleProject
    # Field: name Type: 9 ()
    # Field: hosted_url Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest ===
    # Fields for ListReleaseChannelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse ===
    # Fields for ListReleaseChannelsResponse
    # Field: release_channels Type: 11 (.google.actions.sdk.v2.ReleaseChannel)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.actions.sdk.v2.Version)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Actions::Sdk::V2::ActionsSdk::ActionsSdkClient ===
package Google::Actions::Sdk::V2::ActionsSdk::ActionsSdkClient;

=pod

=head2 Service Client: Google::Actions::Sdk::V2::ActionsSdk::ActionsSdkClient

Client stub representing the remote C<ActionsSdk> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<actions.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'actions.googleapis.com:443' );

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

sub write_draft {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'WriteDraft',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::Draft',
    });
}

sub write_preview {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'WritePreview',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::Preview',
    });
}

sub create_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'CreateVersion',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::Version::Version',
    });
}

sub read_draft {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ReadDraft',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse',
    });
}

sub read_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ReadVersion',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse',
    });
}

sub encrypt_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'EncryptSecret',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse',
    });
}

sub decrypt_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'DecryptSecret',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse',
    });
}

sub list_sample_projects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListSampleProjects',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse',
    });
}

sub list_release_channels {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListReleaseChannels',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse',
    });
}

sub list_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.actions.sdk.v2.ActionsSdk',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ActionsSdk - Compiled Protocol Buffers messages for google/actions/sdk/v2/actions_sdk.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ActionsSdk;

    my $msg = Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest->new({
        parent => $parent,
        files => $files,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/actions_sdk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest

Streaming RPC request for WriteDraft.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the format `projects/{project}`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Files::Files>)

Required. List of files sent to the server at a time. This is a list of config files
or data files.
1. The first request must be a ConfigFiles.
2. The first request must have a ConfigFile with 'settings'.
3. The first request must have a ConfigFile with 'manifest'.
4. The webhook ConfigFile corresponding to inline cloud function must be
   streamed before the DataFile corresponding to its source code.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::Draft

Definition of draft resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the draft in the following format.
`projects/{project}/draft`

=item * C<< $msg->validation_results() >> / C<< $msg->validation_results($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ValidationResults::ValidationResults>)

Validation results associated with the project draft content. Note that
WriteDraft updates the draft despite the warnings as warnings are not draft
blocking.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest

Streaming RPC request for WritePreview.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the format `projects/{project}`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Files::Files>)

List of files sent to the server at a time. This is a list of config
files or data files.
1. The first request must be a ConfigFiles.
2. The first request must have a ConfigFile with 'settings'.
3. The first request must have a ConfigFile with 'manifest'.
4. The webhook ConfigFile corresponding to inline cloud function must be
   streamed before the DataFile corresponding to its source code.

=item * C<< $msg->draft() >> / C<< $msg->draft($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromDraft>)

Content sourced from the project draft.

=item * C<< $msg->submitted_version() >> / C<< $msg->submitted_version($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromSubmittedVersion>)

Content sourced from the an exiting version.

=item * C<< $msg->preview_settings() >> / C<< $msg->preview_settings($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::PreviewSettings>)

Required. The settings for updating the user's preview.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::Preview

Definition of preview resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the preview.
Format: `projects/{project}/preview`

=item * C<< $msg->validation_results() >> / C<< $msg->validation_results($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ValidationResults::ValidationResults>)

Validation results associated with the user project preview content.

=item * C<< $msg->simulator_url() >> / C<< $msg->simulator_url($value) >>

Type: C<String>

The simulator URL to test the user preview.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest

Streaming RPC request for CreateVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the format `projects/{project}`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Files::Files>)

Required. List of files sent to the server at a time. This is a list of config files
or data files.
1. The first request must be a ConfigFiles.
2. The first request must have a ConfigFile with 'settings'.
3. The first request must have a ConfigFile with 'manifest'.
4. The webhook ConfigFile corresponding to inline cloud function must be
   streamed before the DataFile corresponding to its source code.

=item * C<< $msg->release_channel() >> / C<< $msg->release_channel($value) >>

Type: C<String>

Optional. The release channel to deploy the version, if specified. The supported
built in release channels are actions.channels.Production,
actions.channels.ClosedBeta, actions.channels.Alpha.
.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest

RPC request for ReadDraft.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the format `projects/{project}/draft`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->client_secret_encryption_key_version() >> / C<< $msg->client_secret_encryption_key_version($value) >>

Type: C<String>

Optional. The version of the crypto key used to encrypt the account linking OAuth
client secret. If not specified, the primary key version is used for
encryption. Only relevant for projects with account linking with client
secret.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse

Streaming RPC response for ReadDraft.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Files::Files>)

List of files sent from the server at a time.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest

RPC request for ReadVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the version resource in the format
`projects/{project}/versions/{version}`. `{project}` is the
cloud project ID associated with the project, `{version}` is the
identifier of the version being read.

=item * C<< $msg->client_secret_encryption_key_version() >> / C<< $msg->client_secret_encryption_key_version($value) >>

Type: C<String>

Optional. The version of the crypto key used to encrypt the account linking OAuth
client secret. If not specified, the primary key version is used for
encryption. Only relevant for projects with account linking with client
secret.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse

Streaming RPC response for ReadVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Files::Files>)

List of files sent from the server at a time.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest

RPC request for EncryptSecret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_secret() >> / C<< $msg->client_secret($value) >>

Type: C<String>

Required. The account linking client secret plaintext.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse

RPC response for EncryptSecret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account_linking_secret() >> / C<< $msg->account_linking_secret($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret>)

Contains the encrypted account linking client secret and the key version
used to encrypt the secret.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest

RPC request for DecryptSecret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encrypted_client_secret() >> / C<< $msg->encrypted_client_secret($value) >>

Type: C<Bytes>

Required. The account linking client secret ciphertext.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse

RPC response for DecryptSecret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_secret() >> / C<< $msg->client_secret($value) >>

Type: C<String>

The account linking client secret plaintext.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest

RPC request for ListSampleProjects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of sample projects to return. The service may return
fewer than this value.
If unspecified, at most 1000 sample projects will be returned. Values above
1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous 'ListSampleProjects' call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse

RPC response for ListSampleProjects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_projects() >> / C<< $msg->sample_projects($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ActionsSdk::SampleProject>)

The list of sample projects supported.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::SampleProject

Definition of sample project resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the sample project.
Format: `sampleProjects/{sample_project}`

=item * C<< $msg->hosted_url() >> / C<< $msg->hosted_url($value) >>

Type: C<String>

The URL to the zip file where the sample is hosted.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the sample project.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest

RPC request for listing release channels

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the resource in the format `projects/{project}`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of release channels to return. The service may return
fewer than this value. If unspecified, at most 50 release channels will be
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListReleaseChannels` call.
Provide this to retrieve the subsequent page.
When paginating, all other parameters provided to `ListReleaseChannels`
must match the call that provided the page token.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse

RPC response for listing release channels

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->release_channels() >> / C<< $msg->release_channels($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel>)

List of the release channels for the given project id.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest

RPC request for listing versions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the resource in the format `projects/{project}`. The
`{project}` is the cloud project ID associated with the project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of versions to return. The service may return
fewer than this value. If unspecified, at most 50 versions will be
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListVersions` call.
Provide this to retrieve the subsequent page.
When paginating, all other parameters provided to `ListVersions`
must match the call that provided the page token.

=back

=head2 Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse

RPC response for listing versions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Version::Version>)

List of the versions for the given project id.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ActionsSdk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
