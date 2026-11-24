package Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint;

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
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::Inventory };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::Tasks };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MS9hZ2VudGVuZHBvaW50
LnByb3RvEiZnb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MRocZ29vZ2xl
L2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aNmdvb2dsZS9jbG91ZC9vc2NvbmZpZy9hZ2Vu
dGVuZHBvaW50L3YxL2ludmVudG9yeS5wcm90bxoyZ29vZ2xlL2Nsb3VkL29zY29uZmlnL2Fn
ZW50ZW5kcG9pbnQvdjEvdGFza3MucHJvdG8aOWdvb2dsZS9jbG91ZC9vc2NvbmZpZy9hZ2Vu
dGVuZHBvaW50L3YxL3ZtX2ludmVudG9yeS5wcm90byJ7Ch5SZWNlaXZlVGFza05vdGlmaWNh
dGlvblJlcXVlc3QSLwoRaW5zdGFuY2VfaWRfdG9rZW4YASABKAlCA+BBAlIPaW5zdGFuY2VJ
ZFRva2VuEigKDWFnZW50X3ZlcnNpb24YAiABKAlCA+BBAlIMYWdlbnRWZXJzaW9uIiEKH1Jl
Y2VpdmVUYXNrTm90aWZpY2F0aW9uUmVzcG9uc2UiRwoUU3RhcnROZXh0VGFza1JlcXVlc3QS
LwoRaW5zdGFuY2VfaWRfdG9rZW4YASABKAlCA+BBAlIPaW5zdGFuY2VJZFRva2VuIlkKFVN0
YXJ0TmV4dFRhc2tSZXNwb25zZRJACgR0YXNrGAEgASgLMiwuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjEuVGFza1IEdGFzayLFBAoZUmVwb3J0VGFza1Byb2dyZXNz
UmVxdWVzdBIvChFpbnN0YW5jZV9pZF90b2tlbhgBIAEoCUID4EECUg9pbnN0YW5jZUlkVG9r
ZW4SHAoHdGFza19pZBgCIAEoCUID4EECUgZ0YXNrSWQSUgoJdGFza190eXBlGAMgASgOMjAu
Z29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuVGFza1R5cGVCA+BBAlII
dGFza1R5cGUSgQEKG2FwcGx5X3BhdGNoZXNfdGFza19wcm9ncmVzcxgEIAEoCzJALmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLkFwcGx5UGF0Y2hlc1Rhc2tQcm9n
cmVzc0gAUhhhcHBseVBhdGNoZXNUYXNrUHJvZ3Jlc3MSdQoXZXhlY19zdGVwX3Rhc2tfcHJv
Z3Jlc3MYBSABKAsyPC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5F
eGVjU3RlcFRhc2tQcm9ncmVzc0gAUhRleGVjU3RlcFRhc2tQcm9ncmVzcxJ+ChphcHBseV9j
b25maWdfdGFza19wcm9ncmVzcxgGIAEoCzI/Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2Vu
dGVuZHBvaW50LnYxLkFwcGx5Q29uZmlnVGFza1Byb2dyZXNzSABSF2FwcGx5Q29uZmlnVGFz
a1Byb2dyZXNzQgoKCHByb2dyZXNzInoKGlJlcG9ydFRhc2tQcm9ncmVzc1Jlc3BvbnNlElwK
DnRhc2tfZGlyZWN0aXZlGAEgASgOMjUuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5k
cG9pbnQudjEuVGFza0RpcmVjdGl2ZVINdGFza0RpcmVjdGl2ZSLVBAoZUmVwb3J0VGFza0Nv
bXBsZXRlUmVxdWVzdBIvChFpbnN0YW5jZV9pZF90b2tlbhgBIAEoCUID4EECUg9pbnN0YW5j
ZUlkVG9rZW4SHAoHdGFza19pZBgCIAEoCUID4EECUgZ0YXNrSWQSUgoJdGFza190eXBlGAMg
ASgOMjAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuVGFza1R5cGVC
A+BBAlIIdGFza1R5cGUSIwoNZXJyb3JfbWVzc2FnZRgEIAEoCVIMZXJyb3JNZXNzYWdlEnsK
GWFwcGx5X3BhdGNoZXNfdGFza19vdXRwdXQYBSABKAsyPi5nb29nbGUuY2xvdWQub3Njb25m
aWcuYWdlbnRlbmRwb2ludC52MS5BcHBseVBhdGNoZXNUYXNrT3V0cHV0SABSFmFwcGx5UGF0
Y2hlc1Rhc2tPdXRwdXQSbwoVZXhlY19zdGVwX3Rhc2tfb3V0cHV0GAYgASgLMjouZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuRXhlY1N0ZXBUYXNrT3V0cHV0SABS
EmV4ZWNTdGVwVGFza091dHB1dBJ4ChhhcHBseV9jb25maWdfdGFza19vdXRwdXQYByABKAsy
PS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5BcHBseUNvbmZpZ1Rh
c2tPdXRwdXRIAFIVYXBwbHlDb25maWdUYXNrT3V0cHV0QggKBm91dHB1dCIcChpSZXBvcnRU
YXNrQ29tcGxldGVSZXNwb25zZSK7AgoUUmVnaXN0ZXJBZ2VudFJlcXVlc3QSLwoRaW5zdGFu
Y2VfaWRfdG9rZW4YASABKAlCA+BBAlIPaW5zdGFuY2VJZFRva2VuEigKDWFnZW50X3ZlcnNp
b24YAiABKAlCA+BBAlIMYWdlbnRWZXJzaW9uEjoKFnN1cHBvcnRlZF9jYXBhYmlsaXRpZXMY
AyADKAlCA+BBAlIVc3VwcG9ydGVkQ2FwYWJpbGl0aWVzEiAKDG9zX2xvbmdfbmFtZRgEIAEo
CVIKb3NMb25nTmFtZRIiCg1vc19zaG9ydF9uYW1lGAUgASgJUgtvc1Nob3J0TmFtZRIdCgpv
c192ZXJzaW9uGAYgASgJUglvc1ZlcnNpb24SJwoPb3NfYXJjaGl0ZWN0dXJlGAcgASgJUg5v
c0FyY2hpdGVjdHVyZSIXChVSZWdpc3RlckFnZW50UmVzcG9uc2Ui0wEKFlJlcG9ydEludmVu
dG9yeVJlcXVlc3QSLwoRaW5zdGFuY2VfaWRfdG9rZW4YASABKAlCA+BBAlIPaW5zdGFuY2VJ
ZFRva2VuEjIKEmludmVudG9yeV9jaGVja3N1bRgCIAEoCUID4EECUhFpbnZlbnRvcnlDaGVj
a3N1bRJUCglpbnZlbnRvcnkYAyABKAsyMS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRl
bmRwb2ludC52MS5JbnZlbnRvcnlCA+BBAVIJaW52ZW50b3J5Ik0KF1JlcG9ydEludmVudG9y
eVJlc3BvbnNlEjIKFXJlcG9ydF9mdWxsX2ludmVudG9yeRgBIAEoCFITcmVwb3J0RnVsbElu
dmVudG9yeSLcAQoYUmVwb3J0Vm1JbnZlbnRvcnlSZXF1ZXN0Ei8KEWluc3RhbmNlX2lkX3Rv
a2VuGAEgASgJQgPgQQJSD2luc3RhbmNlSWRUb2tlbhIyChJpbnZlbnRvcnlfY2hlY2tzdW0Y
AiABKAlCA+BBAlIRaW52ZW50b3J5Q2hlY2tzdW0SWwoMdm1faW52ZW50b3J5GAMgASgLMjMu
Z29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuVm1JbnZlbnRvcnlCA+BB
AVILdm1JbnZlbnRvcnkiTwoZUmVwb3J0Vm1JbnZlbnRvcnlSZXNwb25zZRIyChVyZXBvcnRf
ZnVsbF9pbnZlbnRvcnkYASABKAhSE3JlcG9ydEZ1bGxJbnZlbnRvcnkypwsKFEFnZW50RW5k
cG9pbnRTZXJ2aWNlEtABChdSZWNlaXZlVGFza05vdGlmaWNhdGlvbhJGLmdvb2dsZS5jbG91
ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlY2VpdmVUYXNrTm90aWZpY2F0aW9uUmVx
dWVzdBpHLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlY2VpdmVU
YXNrTm90aWZpY2F0aW9uUmVzcG9uc2UiItpBH2luc3RhbmNlX2lkX3Rva2VuLGFnZW50X3Zl
cnNpb24wARKiAQoNU3RhcnROZXh0VGFzaxI8Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2Vu
dGVuZHBvaW50LnYxLlN0YXJ0TmV4dFRhc2tSZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjEuU3RhcnROZXh0VGFza1Jlc3BvbnNlIhTaQRFpbnN0YW5j
ZV9pZF90b2tlbhLDAQoSUmVwb3J0VGFza1Byb2dyZXNzEkEuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjEuUmVwb3J0VGFza1Byb2dyZXNzUmVxdWVzdBpCLmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlcG9ydFRhc2tQcm9ncmVzc1Jl
c3BvbnNlIibaQSNpbnN0YW5jZV9pZF90b2tlbix0YXNrX2lkLHRhc2tfdHlwZRLRAQoSUmVw
b3J0VGFza0NvbXBsZXRlEkEuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQu
djEuUmVwb3J0VGFza0NvbXBsZXRlUmVxdWVzdBpCLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5h
Z2VudGVuZHBvaW50LnYxLlJlcG9ydFRhc2tDb21wbGV0ZVJlc3BvbnNlIjTaQTFpbnN0YW5j
ZV9pZF90b2tlbix0YXNrX2lkLHRhc2tfdHlwZSxlcnJvcl9tZXNzYWdlEscBCg1SZWdpc3Rl
ckFnZW50EjwuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuUmVnaXN0
ZXJBZ2VudFJlcXVlc3QaPS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52
MS5SZWdpc3RlckFnZW50UmVzcG9uc2UiOdpBNmluc3RhbmNlX2lkX3Rva2VuLGFnZW50X3Zl
cnNpb24sc3VwcG9ydGVkX2NhcGFiaWxpdGllcxLFAQoPUmVwb3J0SW52ZW50b3J5Ej4uZ29v
Z2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuUmVwb3J0SW52ZW50b3J5UmVx
dWVzdBo/Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlcG9ydElu
dmVudG9yeVJlc3BvbnNlIjHaQS5pbnN0YW5jZV9pZF90b2tlbixpbnZlbnRvcnlfY2hlY2tz
dW0saW52ZW50b3J5Es4BChFSZXBvcnRWbUludmVudG9yeRJALmdvb2dsZS5jbG91ZC5vc2Nv
bmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlcG9ydFZtSW52ZW50b3J5UmVxdWVzdBpBLmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlJlcG9ydFZtSW52ZW50b3J5UmVz
cG9uc2UiNNpBMWluc3RhbmNlX2lkX3Rva2VuLGludmVudG9yeV9jaGVja3N1bSx2bV9pbnZl
bnRvcnkaGspBF29zY29uZmlnLmdvb2dsZWFwaXMuY29tQpQBCipjb20uZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFCEkFnZW50RW5kcG9pbnRQcm90b1ABWlBjbG91
ZC5nb29nbGUuY29tL2dvL29zY29uZmlnL2FnZW50ZW5kcG9pbnQvYXBpdjEvYWdlbnRlbmRw
b2ludHBiO2FnZW50ZW5kcG9pbnRwYkrxTgoHEgUOAI0CAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQBACgkKAgMEEgMWADwKCQoCAwUSAxcAQwoICgEIEgMZAGcKCQoCCAsS
AxkAZwoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADMKCQoCCAgSAxsAMwoICgEIEgMc
AEMKCQoCCAESAxwAQworCgIGABIEHwBPARofIE9TIENvbmZpZyBhZ2VudCBlbmRwb2ludCBB
UEkuCgoKCgMGAAESAx8IHAoKCgMGAAMSAyACPwoMCgUGAAOZCBIDIAI/CksKBAYAAgASBCMC
JgMaPSBTdHJlYW0gZXN0YWJsaXNoZWQgYnkgY2xpZW50IHRvIHJlY2VpdmUgVGFzayBub3Rp
ZmljYXRpb25zLgoKDAoFBgACAAESAyMGHQoMCgUGAAIAAhIDIx48CgwKBQYAAgAGEgMkDxUK
DAoFBgACAAMSAyQWNQoMCgUGAAIABBIDJQRNCg8KCAYAAgAEmwgAEgMlBE0KUAoEBgACARIE
KQIrAxpCIFNpZ25hbHMgdGhlIHN0YXJ0IG9mIGEgdGFzayBleGVjdXRpb24gYW5kIHJldHVy
bnMgdGhlIHRhc2sgaW5mby4KCgwKBQYAAgEBEgMpBhMKDAoFBgACAQISAykUKAoMCgUGAAIB
AxIDKTNICgwKBQYAAgEEEgMqBD8KDwoIBgACAQSbCAASAyoEPwpOCgQGAAICEgQuAjIDGkAg
U2lnbmFscyBhbiBpbnRlcm1lZGlhcnkgcHJvZ3Jlc3MgY2hlY2twb2ludCBpbiB0YXNrIGV4
ZWN1dGlvbi4KCgwKBQYAAgIBEgMuBhgKDAoFBgACAgISAy4ZMgoMCgUGAAICAxIDLw8pCg0K
BQYAAgIEEgQwBDEuChAKCAYAAgIEmwgAEgQwBDEuCmIKBAYAAgMSBDYCOgMaVCBTaWduYWxz
IHRoYXQgdGhlIHRhc2sgZXhlY3V0aW9uIGlzIGNvbXBsZXRlIGFuZCBvcHRpb25hbGx5IHJl
dHVybnMgdGhlIG5leHQKIHRhc2suCgoMCgUGAAIDARIDNgYYCgwKBQYAAgMCEgM2GTIKDAoF
BgACAwMSAzcPKQoNCgUGAAIDBBIEOAQ5PAoQCggGAAIDBJsIABIEOAQ5PAo2CgQGAAIEEgQ9
AkADGiggUmVnaXN0ZXJzIHRoZSBhZ2VudCBydW5uaW5nIG9uIHRoZSBWTS4KCgwKBQYAAgQB
EgM9BhMKDAoFBgACBAISAz0UKAoMCgUGAAIEAxIDPTNICg0KBQYAAgQEEgQ+BD9BChAKCAYA
AgQEmwgAEgQ+BD9BCjIKBAYAAgUSBEMCRwMaJCBSZXBvcnRzIHRoZSBWTXMgY3VycmVudCBp
bnZlbnRvcnkuCgoMCgUGAAIFARIDQwYVCgwKBQYAAgUCEgNDFiwKDAoFBgACBQMSA0QPJgoN
CgUGAAIFBBIERQRGOQoQCggGAAIFBJsIABIERQRGOQoyCgQGAAIGEgRKAk4DGiQgUmVwb3J0
cyB0aGUgVk1zIGN1cnJlbnQgaW52ZW50b3J5LgoKDAoFBgACBgESA0oGFwoMCgUGAAIGAhID
ShgwCgwKBQYAAgYDEgNLDygKDQoFBgACBgQSBEwETTwKEAoIBgACBgSbCAASBEwETTwKPgoC
BAASBFIAWgEaMiBBIHJlcXVlc3QgbWVzc2FnZSB0byByZWNlaXZlIHRhc2sgbm90aWZpY2F0
aW9ucy4KCgoKAwQAARIDUggmCvEBCgQEAAIAEgNWAkga4wEgUmVxdWlyZWQuIFRoaXMgaXMg
dGhlIENvbXB1dGUgRW5naW5lIGluc3RhbmNlIGlkZW50aXR5IHRva2VuIGRlc2NyaWJlZCBp
bgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvdmVy
aWZ5aW5nLWluc3RhbmNlLWlkZW50aXR5CiB3aGVyZSB0aGUgYXVkaWVuY2UgaXMgJ29zY29u
ZmlnLmdvb2dsZWFwaXMuY29tJyBhbmQgdGhlIGZvcm1hdCBpcyAnZnVsbCcuCgoMCgUEAAIA
BRIDVgIICgwKBQQAAgABEgNWCRoKDAoFBAACAAMSA1YdHgoMCgUEAAIACBIDVh9HCg8KCAQA
AgAInAgAEgNWIEYKRQoEBAACARIDWQJEGjggUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIG9mIHRo
ZSBhZ2VudCBtYWtpbmcgdGhlIHJlcXVlc3QuCgoMCgUEAAIBBRIDWQIICgwKBQQAAgEBEgNZ
CRYKDAoFBAACAQMSA1kZGgoMCgUEAAIBCBIDWRtDCg8KCAQAAgEInAgAEgNZHEIKegoCBAES
A14AKhpvIFRoZSBzdHJlYW1pbmcgcnBjIG1lc3NhZ2UgdGhhdCB3aWxsIG5vdGlmeSB0aGUg
YWdlbnQgd2hlbiBpdCBoYXMgYSB0YXNrCiBpdCBuZWVkcyB0byBwZXJmb3JtIG9uIHRoZSBp
bnN0YW5jZS4KCgoKAwQBARIDXggnCkwKAgQCEgRhAGYBGkAgQSByZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIHNpZ25hbGluZyB0aGUgc3RhcnQgb2YgYSB0YXNrIGV4ZWN1dGlvbi4KCgoKAwQCARID
YQgcCvEBCgQEAgIAEgNlAkga4wEgUmVxdWlyZWQuIFRoaXMgaXMgdGhlIENvbXB1dGUgRW5n
aW5lIGluc3RhbmNlIGlkZW50aXR5IHRva2VuIGRlc2NyaWJlZCBpbgogaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvdmVyaWZ5aW5nLWluc3RhbmNl
LWlkZW50aXR5CiB3aGVyZSB0aGUgYXVkaWVuY2UgaXMgJ29zY29uZmlnLmdvb2dsZWFwaXMu
Y29tJyBhbmQgdGhlIGZvcm1hdCBpcyAnZnVsbCcuCgoMCgUEAgIABRIDZQIICgwKBQQCAgAB
EgNlCRoKDAoFBAICAAMSA2UdHgoMCgUEAgIACBIDZR9HCg8KCAQCAgAInAgAEgNlIEYKUgoC
BAMSBGkAbQEaRiBBIHJlc3BvbnNlIG1lc3NhZ2UgdGhhdCBjb250YWlucyB0aGUgZGV0YWls
cyBvZiB0aGUgdGFzayB0byB3b3JrIG9uLgoKCgoDBAMBEgNpCB0KcwoEBAMCABIDbAIQGmYg
VGhlIGRldGFpbHMgb2YgdGhlIHRhc2sgdGhhdCBzaG91bGQgYmUgd29ya2VkIG9uLiAgQ2Fu
IGJlIGVtcHR5IGlmIHRoZXJlCiBpcyBubyBuZXcgdGFzayB0byB3b3JrIG9uLgoKDAoFBAMC
AAYSA2wCBgoMCgUEAwIAARIDbAcLCgwKBQQDAgADEgNsDg8KTAoCBAQSBXAAjQEBGj8gQSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHJlcG9ydGluZyB0aGUgcHJvZ3Jlc3Mgb2YgY3VycmVudCB0
YXNrLgoKCgoDBAQBEgNwCCEK8QEKBAQEAgASA3QCSBrjASBSZXF1aXJlZC4gVGhpcyBpcyB0
aGUgQ29tcHV0ZSBFbmdpbmUgaW5zdGFuY2UgaWRlbnRpdHkgdG9rZW4gZGVzY3JpYmVkIGlu
CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2luc3RhbmNlcy92ZXJp
ZnlpbmctaW5zdGFuY2UtaWRlbnRpdHkKIHdoZXJlIHRoZSBhdWRpZW5jZSBpcyAnb3Njb25m
aWcuZ29vZ2xlYXBpcy5jb20nIGFuZCB0aGUgZm9ybWF0IGlzICdmdWxsJy4KCgwKBQQEAgAF
EgN0AggKDAoFBAQCAAESA3QJGgoMCgUEBAIAAxIDdB0eCgwKBQQEAgAIEgN0H0cKDwoIBAQC
AAicCAASA3QgRgpHCgQEBAIBEgN3Aj4aOiBSZXF1aXJlZC4gVW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIHRhc2sgdGhpcyBhcHBsaWVzIHRvLgoKDAoFBAQCAQUSA3cCCAoMCgUEBAIBARID
dwkQCgwKBQQEAgEDEgN3ExQKDAoFBAQCAQgSA3cVPQoPCggEBAIBCJwIABIDdxY8CqoCCgQE
BAICEgSAAQJCGpsCIFJlcXVpcmVkLiBUaGUgdHlwZSBvZiB0YXNrIHRvIHJlcG9ydCBwcm9n
cmVzcyBvbi4KCiBQcm9ncmVzcyBtdXN0IGluY2x1ZGUgdGhlIGFwcHJvcHJpYXRlIG1lc3Nh
Z2UgYmFzZWQgb24gdGhpcyBlbnVtIGFzCiBzcGVjaWZpZWQgYmVsb3c6CiBgQVBQTFlfUEFU
Q0hFU2AgPSBBcHBseVBhdGNoZXNUYXNrUHJvZ3Jlc3MKIGBFWEVDX1NURVBgID0gUHJvZ3Jl
c3Mgbm90IHN1cHBvcnRlZCBmb3IgdGhpcyB0eXBlLgogYEFQUExZX0NPTkZJR19UQVNLYCA9
IEFwcGx5Q29uZmlnVGFza1Byb2dyZXNzCgoNCgUEBAICBhIEgAECCgoNCgUEBAICARIEgAEL
FAoNCgUEBAICAxIEgAEXGAoNCgUEBAICCBIEgAEZQQoQCggEBAICCJwIABIEgAEaQAo8CgQE
BAgAEgaDAQKMAQMaLCBJbnRlcm1lZGlhdGUgcHJvZ3Jlc3Mgb2YgdGhlIGN1cnJlbnQgdGFz
ay4KCg0KBQQECAABEgSDAQgQCkUKBAQEAgMSBIUBBD0aNyBEZXRhaWxzIGFib3V0IHRoZSBw
cm9ncmVzcyBvZiB0aGUgYXBwbHkgcGF0Y2hlcyB0YXNrLgoKDQoFBAQCAwYSBIUBBBwKDQoF
BAQCAwESBIUBHTgKDQoFBAQCAwMSBIUBOzwKQQoEBAQCBBIEiAEENRozIERldGFpbHMgYWJv
dXQgdGhlIHByb2dyZXNzIG9mIHRoZSBleGVjIHN0ZXAgdGFzay4KCg0KBQQEAgQGEgSIAQQY
Cg0KBQQEAgQBEgSIARkwCg0KBQQEAgQDEgSIATM0CkQKBAQEAgUSBIsBBDsaNiBEZXRhaWxz
IGFib3V0IHRoZSBwcm9ncmVzcyBvZiB0aGUgYXBwbHkgY29uZmlnIHRhc2suCgoNCgUEBAIF
BhIEiwEEGwoNCgUEBAIFARIEiwEcNgoNCgUEBAIFAxIEiwE5OgpYCgIEBRIGkAEAkwEBGkog
VGhlIHJlc3BvbnNlIG1lc3NhZ2UgYWZ0ZXIgdGhlIGFnZW50IHJlcG9ydGVkIHRoZSBjdXJy
ZW50IHRhc2sgcHJvZ3Jlc3MuCgoLCgMEBQESBJABCCIKMwoEBAUCABIEkgECIxolIEluc3Ry
dWN0cyBhZ2VudCB0byBjb250aW51ZSBvciBub3QuCgoNCgUEBQIABhIEkgECDwoNCgUEBQIA
ARIEkgEQHgoNCgUEBQIAAxIEkgEhIgpTCgIEBhIGlgEAtgEBGkUgQSByZXF1ZXN0IG1lc3Nh
Z2UgZm9yIHNpZ25hbGluZyB0aGUgY29tcGxldGlvbiBvZiBhIHRhc2sgZXhlY3V0aW9uLgoK
CwoDBAYBEgSWAQghCvIBCgQEBgIAEgSaAQJIGuMBIFJlcXVpcmVkLiBUaGlzIGlzIHRoZSBD
b21wdXRlIEVuZ2luZSBpbnN0YW5jZSBpZGVudGl0eSB0b2tlbiBkZXNjcmliZWQgaW4KIGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3MvaW5zdGFuY2VzL3ZlcmlmeWlu
Zy1pbnN0YW5jZS1pZGVudGl0eQogd2hlcmUgdGhlIGF1ZGllbmNlIGlzICdvc2NvbmZpZy5n
b29nbGVhcGlzLmNvbScgYW5kIHRoZSBmb3JtYXQgaXMgJ2Z1bGwnLgoKDQoFBAYCAAUSBJoB
AggKDQoFBAYCAAESBJoBCRoKDQoFBAYCAAMSBJoBHR4KDQoFBAYCAAgSBJoBH0cKEAoIBAYC
AAicCAASBJoBIEYKSAoEBAYCARIEnQECPho6IFJlcXVpcmVkLiBVbmlxdWUgaWRlbnRpZmll
ciBvZiB0aGUgdGFzayB0aGlzIGFwcGxpZXMgdG8uCgoNCgUEBgIBBRIEnQECCAoNCgUEBgIB
ARIEnQEJEAoNCgUEBgIBAxIEnQETFAoNCgUEBgIBCBIEnQEVPQoQCggEBgIBCJwIABIEnQEW
PAqJAgoEBAYCAhIEpgECQhr6ASBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgdGFzayB0byByZXBv
cnQgY29tcGxldGVkLgoKIE91dHB1dCBtdXN0IGluY2x1ZGUgdGhlIGFwcHJvcHJpYXRlIG1l
c3NhZ2UgYmFzZWQgb24gdGhpcyBlbnVtIGFzCiBzcGVjaWZpZWQgYmVsb3c6CiBBUFBMWV9Q
QVRDSEVTID0gQXBwbHlQYXRjaGVzVGFza091dHB1dAogRVhFQ19TVEVQID0gRXhlY1N0ZXBU
YXNrT3V0cHV0CiBBUFBMWV9DT05GSUdfVEFTSyA9IEFwcGx5Q29uZmlnVGFza091dHB1dAoK
DQoFBAYCAgYSBKYBAgoKDQoFBAYCAgESBKYBCxQKDQoFBAYCAgMSBKYBFxgKDQoFBAYCAggS
BKYBGUEKEAoIBAYCAgicCAASBKYBGkAKTwoEBAYCAxIEqQECGxpBIERlc2NyaXB0aXZlIGVy
cm9yIG1lc3NhZ2UgaWYgdGhlIHRhc2sgZXhlY3V0aW9uIGVuZGVkIGluIGVycm9yLgoKDQoF
BAYCAwUSBKkBAggKDQoFBAYCAwESBKkBCRYKDQoFBAYCAwMSBKkBGRoKOwoEBAYIABIGrAEC
tQEDGisgRmluYWwgb3V0cHV0IGRldGFpbHMgb2YgdGhlIGN1cnJlbnQgdGFzay4KCg0KBQQG
CAABEgSsAQgOCj8KBAQGAgQSBK4BBDkaMSBGaW5hbCBvdXRwdXQgZGV0YWlscyBvZiB0aGUg
YXBwbHkgcGF0Y2hlcyB0YXNrOwoKDQoFBAYCBAYSBK4BBBoKDQoFBAYCBAESBK4BGzQKDQoF
BAYCBAMSBK4BNzgKOwoEBAYCBRIEsQEEMRotIEZpbmFsIG91dHB1dCBkZXRhaWxzIG9mIHRo
ZSBleGVjIHN0ZXAgdGFzazsKCg0KBQQGAgUGEgSxAQQWCg0KBQQGAgUBEgSxARcsCg0KBQQG
AgUDEgSxAS8wCj4KBAQGAgYSBLQBBDcaMCBGaW5hbCBvdXRwdXQgZGV0YWlscyBvZiB0aGUg
YXBwbHkgY29uZmlnIHRhc2s7CgoNCgUEBgIGBhIEtAEEGQoNCgUEBgIGARIEtAEaMgoNCgUE
BgIGAxIEtAE1NgpWCgIEBxIEuQEAJRpKIFRoZSByZXNwb25zZSBtZXNzYWdlIGFmdGVyIHRo
ZSBhZ2VudCBzaWduYWxlZCB0aGUgY3VycmVudCB0YXNrIGNvbXBsZXRlLgoKCwoDBAcBEgS5
AQgiCj4KAgQIEga8AQDaAQEaMCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciByZWdpc3Rlcmlu
ZyB0aGUgYWdlbnQuCgoLCgMECAESBLwBCBwK8gEKBAQIAgASBMABAkga4wEgUmVxdWlyZWQu
IFRoaXMgaXMgdGhlIENvbXB1dGUgRW5naW5lIGluc3RhbmNlIGlkZW50aXR5IHRva2VuIGRl
c2NyaWJlZCBpbgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9pbnN0
YW5jZXMvdmVyaWZ5aW5nLWluc3RhbmNlLWlkZW50aXR5CiB3aGVyZSB0aGUgYXVkaWVuY2Ug
aXMgJ29zY29uZmlnLmdvb2dsZWFwaXMuY29tJyBhbmQgdGhlIGZvcm1hdCBpcyAnZnVsbCcu
CgoNCgUECAIABRIEwAECCAoNCgUECAIAARIEwAEJGgoNCgUECAIAAxIEwAEdHgoNCgUECAIA
CBIEwAEfRwoQCggECAIACJwIABIEwAEgRgozCgQECAIBEgTDAQJEGiUgUmVxdWlyZWQuIFRo
ZSB2ZXJzaW9uIG9mIHRoZSBhZ2VudC4KCg0KBQQIAgEFEgTDAQIICg0KBQQIAgEBEgTDAQkW
Cg0KBQQIAgEDEgTDARkaCg0KBQQIAgEIEgTDARtDChAKCAQIAgEInAgAEgTDARxCCoIBCgQE
CAICEgbJAQLKAS8aciBSZXF1aXJlZC4gVGhlIGNhcGFiaWxpdGllcyBzdXBwb3J0ZWQgYnkg
dGhlIGFnZW50LiBTdXBwb3J0ZWQgdmFsdWVzIGFyZToKIFBBVENIX0dBCiBHVUVTVF9QT0xJ
Q1lfQkVUQQogQ09ORklHX1YxCgoNCgUECAICBBIEyQECCgoNCgUECAICBRIEyQELEQoNCgUE
CAICARIEyQESKAoNCgUECAICAxIEyQErLAoNCgUECAICCBIEygEGLgoQCggECAICCJwIABIE
ygEHLQqAAQoEBAgCAxIEzwECGhpyIFRoZSBvcGVyYXRpbmcgc3lzdGVtIGxvbmcgbmFtZS4K
IEZvciBleGFtcGxlICdEZWJpYW4gR05VL0xpbnV4IDknIG9yICdNaWNyb3NvZnQgV2luZG93
IFNlcnZlciAyMDE5CiBEYXRhY2VudGVyJy4KCg0KBQQIAgMFEgTPAQIICg0KBQQIAgMBEgTP
AQkVCg0KBQQIAgMDEgTPARgZClUKBAQIAgQSBNMBAhsaRyBUaGUgb3BlcmF0aW5nIHN5c3Rl
bSBzaG9ydCBuYW1lLgogRm9yIGV4YW1wbGUsICd3aW5kb3dzJyBvciAnZGViaWFuJy4KCg0K
BQQIAgQFEgTTAQIICg0KBQQIAgQBEgTTAQkWCg0KBQQIAgQDEgTTARkaCjQKBAQIAgUSBNYB
AhgaJiBUaGUgdmVyc2lvbiBvZiB0aGUgb3BlcmF0aW5nIHN5c3RlbS4KCg0KBQQIAgUFEgTW
AQIICg0KBQQIAgUBEgTWAQkTCg0KBQQIAgUDEgTWARYXCkAKBAQIAgYSBNkBAh0aMiBUaGUg
c3lzdGVtIGFyY2hpdGVjdHVyZSBvZiB0aGUgb3BlcmF0aW5nIHN5c3RlbS4KCg0KBQQIAgYF
EgTZAQIICg0KBQQIAgYBEgTZAQkYCg0KBQQIAgYDEgTZARscCj4KAgQJEgTdAQAgGjIgVGhl
IHJlc3BvbnNlIG1lc3NhZ2UgYWZ0ZXIgdGhlIGFnZW50IHJlZ2lzdGVyZWQuCgoLCgMECQES
BN0BCB0KSgoCBAoSBuABAO8BARo8IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGhhdmluZyB0
aGUgYWdlbnQgcmVwb3J0IGludmVudG9yeS4KCgsKAwQKARIE4AEIHgryAQoEBAoCABIE5AEC
SBrjASBSZXF1aXJlZC4gVGhpcyBpcyB0aGUgQ29tcHV0ZSBFbmdpbmUgaW5zdGFuY2UgaWRl
bnRpdHkgdG9rZW4gZGVzY3JpYmVkIGluCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29t
cHV0ZS9kb2NzL2luc3RhbmNlcy92ZXJpZnlpbmctaW5zdGFuY2UtaWRlbnRpdHkKIHdoZXJl
IHRoZSBhdWRpZW5jZSBpcyAnb3Njb25maWcuZ29vZ2xlYXBpcy5jb20nIGFuZCB0aGUgZm9y
bWF0IGlzICdmdWxsJy4KCg0KBQQKAgAFEgTkAQIICg0KBQQKAgABEgTkAQkaCg0KBQQKAgAD
EgTkAR0eCg0KBQQKAgAIEgTkAR9HChAKCAQKAgAInAgAEgTkASBGCuIBCgQECgIBEgTpAQJJ
GtMBIFJlcXVpcmVkLiBUaGlzIGlzIGEgY2xpZW50IGNyZWF0ZWQgY2hlY2tzdW0gdGhhdCBz
aG91bGQgYmUgZ2VuZXJhdGVkIGJhc2VkCiBvbiB0aGUgY29udGVudHMgb2YgdGhlIHJlcG9y
dGVkIGludmVudG9yeS4gIFRoaXMgd2lsbCBiZSB1c2VkIGJ5IHRoZQogc2VydmljZSB0byBk
ZXRlcm1pbmUgaWYgaXQgaGFzIHRoZSBsYXRlc3QgdmVyc2lvbiBvZiBpbnZlbnRvcnkuCgoN
CgUECgIBBRIE6QECCAoNCgUECgIBARIE6QEJGwoNCgUECgIBAxIE6QEeHwoNCgUECgIBCBIE
6QEgSAoQCggECgIBCJwIABIE6QEhRwrKAQoEBAoCAhIE7gECQxq7ASBPcHRpb25hbC4gVGhp
cyBpcyB0aGUgZGV0YWlscyBvZiB0aGUgaW52ZW50b3J5LiAgU2hvdWxkIG9ubHkgYmUgcHJv
dmlkZWQgaWYKIHRoZSBpbnZlbnRvcnkgaGFzIGNoYW5nZWQgc2luY2UgdGhlIGxhc3QgcmVw
b3J0LCBvciBpZiBpbnN0cnVjdGVkIGJ5IHRoZQogc2VydmljZSB0byBwcm92aWRlIGZ1bGwg
aW52ZW50b3J5LgoKDQoFBAoCAgYSBO4BAgsKDQoFBAoCAgESBO4BDBUKDQoFBAoCAgMSBO4B
GBkKDQoFBAoCAggSBO4BGkIKEAoIBAoCAgicCAASBO4BG0EKTAoCBAsSBvIBAPUBARo+IFRo
ZSByZXNwb25zZSBtZXNzYWdlIGFmdGVyIHRoZSBhZ2VudCBoYXMgcmVwb3J0ZWQgaW52ZW50
b3J5LgoKCwoDBAsBEgTyAQgfClIKBAQLAgASBPQBAiEaRCBJZiB0cnVlLCB0aGUgZnVsbCBp
bnZlbnRvcnkgc2hvdWxkIGJlIHJlcG9ydGVkIGJhY2sgdG8gdGhlIHNlcnZlci4KCg0KBQQL
AgAFEgT0AQIGCg0KBQQLAgABEgT0AQccCg0KBQQLAgADEgT0AR8gCksKAgQMEgb4AQCHAgEa
PSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciByZXBvcnRpbmcgdGhlIGFnZW50J3MgVk0gaW52
ZW50b3J5LgoKCwoDBAwBEgT4AQggCvIBCgQEDAIAEgT8AQJIGuMBIFJlcXVpcmVkLiBUaGlz
IGlzIHRoZSBDb21wdXRlIEVuZ2luZSBpbnN0YW5jZSBpZGVudGl0eSB0b2tlbiBkZXNjcmli
ZWQgaW4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3MvaW5zdGFuY2Vz
L3ZlcmlmeWluZy1pbnN0YW5jZS1pZGVudGl0eQogd2hlcmUgdGhlIGF1ZGllbmNlIGlzICdv
c2NvbmZpZy5nb29nbGVhcGlzLmNvbScgYW5kIHRoZSBmb3JtYXQgaXMgJ2Z1bGwnLgoKDQoF
BAwCAAUSBPwBAggKDQoFBAwCAAESBPwBCRoKDQoFBAwCAAMSBPwBHR4KDQoFBAwCAAgSBPwB
H0cKEAoIBAwCAAicCAASBPwBIEYK4QEKBAQMAgESBIECAkka0gEgUmVxdWlyZWQuIFRoaXMg
aXMgYSBjbGllbnQgY3JlYXRlZCBjaGVja3N1bSB0aGF0IHNob3VsZCBiZSBnZW5lcmF0ZWQg
YmFzZWQKIG9uIHRoZSBjb250ZW50cyBvZiB0aGUgcmVwb3J0ZWQgaW52ZW50b3J5LiBUaGlz
IHdpbGwgYmUgdXNlZCBieSB0aGUgc2VydmljZQogdG8gZGV0ZXJtaW5lIGlmIGl0IGhhcyB0
aGUgbGF0ZXN0IHZlcnNpb24gb2YgaW52ZW50b3J5LgoKDQoFBAwCAQUSBIECAggKDQoFBAwC
AQESBIECCRsKDQoFBAwCAQMSBIECHh8KDQoFBAwCAQgSBIECIEgKEAoIBAwCAQicCAASBIEC
IUcKzAEKBAQMAgISBIYCAkgavQEgT3B0aW9uYWwuIFRoaXMgaXMgdGhlIGRldGFpbHMgb2Yg
dGhlIFZNIGludmVudG9yeS4gU2hvdWxkIG9ubHkgYmUgcHJvdmlkZWQKIGlmIHRoZSBpbnZl
bnRvcnkgaGFzIGNoYW5nZWQgc2luY2UgdGhlIGxhc3QgcmVwb3J0LCBvciBpZiBpbnN0cnVj
dGVkIGJ5IHRoZQogc2VydmljZSB0byBwcm92aWRlIGZ1bGwgaW52ZW50b3J5LgoKDQoFBAwC
AgYSBIYCAg0KDQoFBAwCAgESBIYCDhoKDQoFBAwCAgMSBIYCHR4KDQoFBAwCAggSBIYCH0cK
EAoIBAwCAgicCAASBIYCIEYKTwoCBA0SBooCAI0CARpBIFRoZSByZXNwb25zZSBtZXNzYWdl
IGFmdGVyIHRoZSBhZ2VudCBoYXMgcmVwb3J0ZWQgVk0gaW52ZW50b3J5LgoKCwoDBA0BEgSK
AgghClIKBAQNAgASBIwCAiEaRCBJZiB0cnVlLCB0aGUgZnVsbCBpbnZlbnRvcnkgc2hvdWxk
IGJlIHJlcG9ydGVkIGJhY2sgdG8gdGhlIHNlcnZlci4KCg0KBQQNAgAFEgSMAgIGCg0KBQQN
AgABEgSMAgccCg0KBQQNAgADEgSMAh8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest ===
    # Fields for ReceiveTaskNotificationRequest
    # Field: instance_id_token Type: 9 ()
    # Field: agent_version Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse ===
    # Fields for ReceiveTaskNotificationResponse

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest ===
    # Fields for StartNextTaskRequest
    # Field: instance_id_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse ===
    # Fields for StartNextTaskResponse
    # Field: task Type: 11 (.google.cloud.osconfig.agentendpoint.v1.Task)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest ===
    # Fields for ReportTaskProgressRequest
    # Field: instance_id_token Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1.TaskType)
    # Field: apply_patches_task_progress Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyPatchesTaskProgress)
    # Field: exec_step_task_progress Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStepTaskProgress)
    # Field: apply_config_task_progress Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTaskProgress)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse ===
    # Fields for ReportTaskProgressResponse
    # Field: task_directive Type: 14 (.google.cloud.osconfig.agentendpoint.v1.TaskDirective)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest ===
    # Fields for ReportTaskCompleteRequest
    # Field: instance_id_token Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1.TaskType)
    # Field: error_message Type: 9 ()
    # Field: apply_patches_task_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyPatchesTaskOutput)
    # Field: exec_step_task_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStepTaskOutput)
    # Field: apply_config_task_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTaskOutput)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse ===
    # Fields for ReportTaskCompleteResponse

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest ===
    # Fields for RegisterAgentRequest
    # Field: instance_id_token Type: 9 ()
    # Field: agent_version Type: 9 ()
    # Field: supported_capabilities Type: 9 ()
    # Field: os_long_name Type: 9 ()
    # Field: os_short_name Type: 9 ()
    # Field: os_version Type: 9 ()
    # Field: os_architecture Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse ===
    # Fields for RegisterAgentResponse

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest ===
    # Fields for ReportInventoryRequest
    # Field: instance_id_token Type: 9 ()
    # Field: inventory_checksum Type: 9 ()
    # Field: inventory Type: 11 (.google.cloud.osconfig.agentendpoint.v1.Inventory)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse ===
    # Fields for ReportInventoryResponse
    # Field: report_full_inventory Type: 8 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest ===
    # Fields for ReportVmInventoryRequest
    # Field: instance_id_token Type: 9 ()
    # Field: inventory_checksum Type: 9 ()
    # Field: vm_inventory Type: 11 (.google.cloud.osconfig.agentendpoint.v1.VmInventory)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse ===
    # Fields for ReportVmInventoryResponse
    # Field: report_full_inventory Type: 8 ()

# === Service Client: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::AgentEndpointServiceClient ===
package Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::AgentEndpointServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::AgentEndpointServiceClient

Client stub representing the remote C<AgentEndpointService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub receive_task_notification {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'ReceiveTaskNotification',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse',
    });
}

sub start_next_task {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'StartNextTask',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse',
    });
}

sub report_task_progress {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'ReportTaskProgress',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse',
    });
}

sub report_task_complete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'ReportTaskComplete',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse',
    });
}

sub register_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'RegisterAgent',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse',
    });
}

sub report_inventory {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'ReportInventory',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse',
    });
}

sub report_vm_inventory {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1.AgentEndpointService',
        method         => 'ReportVmInventory',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1/agentendpoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest->new({
        instance_id_token => $instance_id_token,
        agent_version => $agent_version,
    });

    # Read or update a field
    my $val = $msg->instance_id_token();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1/agentendpoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest

A request message to receive task notifications.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Required. The version of the agent making the request.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse

The streaming rpc message that will notify the agent when it has a task
it needs to perform on the instance.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest

A request message for signaling the start of a task execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse

A response message that contains the details of the task to work on.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task() >> / C<< $msg->task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task>)

The details of the task that should be worked on.  Can be empty if there
is no new task to work on.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest

A request message for reporting the progress of current task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Required. Unique identifier of the task this applies to.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::TaskType>)

Required. The type of task to report progress on.

Progress must include the appropriate message based on this enum as
specified below:
`APPLY_PATCHES` = ApplyPatchesTaskProgress
`EXEC_STEP` = Progress not supported for this type.
`APPLY_CONFIG_TASK` = ApplyConfigTaskProgress

=item * C<< $msg->apply_patches_task_progress() >> / C<< $msg->apply_patches_task_progress($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskProgress>)

Details about the progress of the apply patches task.

=item * C<< $msg->exec_step_task_progress() >> / C<< $msg->exec_step_task_progress($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskProgress>)

Details about the progress of the exec step task.

=item * C<< $msg->apply_config_task_progress() >> / C<< $msg->apply_config_task_progress($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskProgress>)

Details about the progress of the apply config task.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse

The response message after the agent reported the current task progress.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_directive() >> / C<< $msg->task_directive($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::TaskDirective>)

Instructs agent to continue or not.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest

A request message for signaling the completion of a task execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Required. Unique identifier of the task this applies to.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::TaskType>)

Required. The type of task to report completed.

Output must include the appropriate message based on this enum as
specified below:
APPLY_PATCHES = ApplyPatchesTaskOutput
EXEC_STEP = ExecStepTaskOutput
APPLY_CONFIG_TASK = ApplyConfigTaskOutput

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Descriptive error message if the task execution ended in error.

=item * C<< $msg->apply_patches_task_output() >> / C<< $msg->apply_patches_task_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskOutput>)

Final output details of the apply patches task;

=item * C<< $msg->exec_step_task_output() >> / C<< $msg->exec_step_task_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskOutput>)

Final output details of the exec step task;

=item * C<< $msg->apply_config_task_output() >> / C<< $msg->apply_config_task_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskOutput>)

Final output details of the apply config task;

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse

The response message after the agent signaled the current task complete.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest

The request message for registering the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Required. The version of the agent.

=item * C<< $msg->supported_capabilities() >> / C<< $msg->supported_capabilities($value) >>

Type: C<String>

Required. The capabilities supported by the agent. Supported values are:
PATCH_GA
GUEST_POLICY_BETA
CONFIG_V1

=item * C<< $msg->os_long_name() >> / C<< $msg->os_long_name($value) >>

Type: C<String>

The operating system long name.
For example 'Debian GNU/Linux 9' or 'Microsoft Window Server 2019
Datacenter'.

=item * C<< $msg->os_short_name() >> / C<< $msg->os_short_name($value) >>

Type: C<String>

The operating system short name.
For example, 'windows' or 'debian'.

=item * C<< $msg->os_version() >> / C<< $msg->os_version($value) >>

Type: C<String>

The version of the operating system.

=item * C<< $msg->os_architecture() >> / C<< $msg->os_architecture($value) >>

Type: C<String>

The system architecture of the operating system.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse

The response message after the agent registered.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest

The request message for having the agent report inventory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->inventory_checksum() >> / C<< $msg->inventory_checksum($value) >>

Type: C<String>

Required. This is a client created checksum that should be generated based
on the contents of the reported inventory.  This will be used by the
service to determine if it has the latest version of inventory.

=item * C<< $msg->inventory() >> / C<< $msg->inventory($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Inventory::Inventory>)

Optional. This is the details of the inventory.  Should only be provided if
the inventory has changed since the last report, or if instructed by the
service to provide full inventory.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse

The response message after the agent has reported inventory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->report_full_inventory() >> / C<< $msg->report_full_inventory($value) >>

Type: C<Bool>

If true, the full inventory should be reported back to the server.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest

The request message for reporting the agent's VM inventory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->inventory_checksum() >> / C<< $msg->inventory_checksum($value) >>

Type: C<String>

Required. This is a client created checksum that should be generated based
on the contents of the reported inventory. This will be used by the service
to determine if it has the latest version of inventory.

=item * C<< $msg->vm_inventory() >> / C<< $msg->vm_inventory($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::VmInventory::VmInventory>)

Optional. This is the details of the VM inventory. Should only be provided
if the inventory has changed since the last report, or if instructed by the
service to provide full inventory.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse

The response message after the agent has reported VM inventory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->report_full_inventory() >> / C<< $msg->report_full_inventory($value) >>

Type: C<Bool>

If true, the full inventory should be reported back to the server.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
