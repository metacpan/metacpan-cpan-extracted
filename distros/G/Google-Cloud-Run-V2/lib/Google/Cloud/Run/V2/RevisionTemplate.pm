package Google::Cloud::Run::V2::RevisionTemplate;

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
    eval { require Google::Cloud::Run::V2::K8sMin };
    eval { require Google::Cloud::Run::V2::Sandbox };
    eval { require Google::Cloud::Run::V2::VendorSettings };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvcnVuL3YyL3JldmlzaW9uX3RlbXBsYXRlLnByb3RvEhNnb29nbGUu
Y2xvdWQucnVuLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGiFnb29nbGUvY2xvdWQvcnVuL3YyL2s4cy5taW4ucHJvdG8a
IWdvb2dsZS9jbG91ZC9ydW4vdjIvc2FuZGJveC5wcm90bxopZ29vZ2xlL2Nsb3VkL3J1bi92
Mi92ZW5kb3Jfc2V0dGluZ3MucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90
byKmDwoQUmV2aXNpb25UZW1wbGF0ZRI/CghyZXZpc2lvbhgBIAEoCUIj4EEB+kEdChtydW4u
Z29vZ2xlYXBpcy5jb20vUmV2aXNpb25SCHJldmlzaW9uEk4KBmxhYmVscxgCIAMoCzIxLmdv
b2dsZS5jbG91ZC5ydW4udjIuUmV2aXNpb25UZW1wbGF0ZS5MYWJlbHNFbnRyeUID4EEBUgZs
YWJlbHMSXQoLYW5ub3RhdGlvbnMYAyADKAsyNi5nb29nbGUuY2xvdWQucnVuLnYyLlJldmlz
aW9uVGVtcGxhdGUuQW5ub3RhdGlvbnNFbnRyeUID4EEBUgthbm5vdGF0aW9ucxJDCgdzY2Fs
aW5nGAQgASgLMiQuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5SZXZpc2lvblNjYWxpbmdCA+BBAVIH
c2NhbGluZxJCCgp2cGNfYWNjZXNzGAYgASgLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5WcGNB
Y2Nlc3NCA+BBAVIJdnBjQWNjZXNzEjgKB3RpbWVvdXQYCCABKAsyGS5nb29nbGUucHJvdG9i
dWYuRHVyYXRpb25CA+BBAVIHdGltZW91dBIsCg9zZXJ2aWNlX2FjY291bnQYCSABKAlCA+BB
AVIOc2VydmljZUFjY291bnQSPgoKY29udGFpbmVycxgKIAMoCzIeLmdvb2dsZS5jbG91ZC5y
dW4udjIuQ29udGFpbmVyUgpjb250YWluZXJzEkwKCXNhbmRib3hlcxgfIAEoCzIpLmdvb2ds
ZS5jbG91ZC5ydW4udjIuU2FuZGJveENvbmZpZ3VyYXRpb25CA+BBAVIJc2FuZGJveGVzEjoK
B3ZvbHVtZXMYCyADKAsyGy5nb29nbGUuY2xvdWQucnVuLnYyLlZvbHVtZUID4EEBUgd2b2x1
bWVzEmMKFWV4ZWN1dGlvbl9lbnZpcm9ubWVudBgNIAEoDjIpLmdvb2dsZS5jbG91ZC5ydW4u
djIuRXhlY3V0aW9uRW52aXJvbm1lbnRCA+BBAVIUZXhlY3V0aW9uRW52aXJvbm1lbnQSTQoO
ZW5jcnlwdGlvbl9rZXkYDiABKAlCJvpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5
cHRvS2V5Ug1lbmNyeXB0aW9uS2V5EkwKIG1heF9pbnN0YW5jZV9yZXF1ZXN0X2NvbmN1cnJl
bmN5GA8gASgFQgPgQQFSHW1heEluc3RhbmNlUmVxdWVzdENvbmN1cnJlbmN5EkgKDHNlcnZp
Y2VfbWVzaBgQIAEoCzIgLmdvb2dsZS5jbG91ZC5ydW4udjIuU2VydmljZU1lc2hCA+BBAVIL
c2VydmljZU1lc2gSgAEKIGVuY3J5cHRpb25fa2V5X3Jldm9jYXRpb25fYWN0aW9uGBEgASgO
MjIuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5FbmNyeXB0aW9uS2V5UmV2b2NhdGlvbkFjdGlvbkID
4EEBUh1lbmNyeXB0aW9uS2V5UmV2b2NhdGlvbkFjdGlvbhJnCiBlbmNyeXB0aW9uX2tleV9z
aHV0ZG93bl9kdXJhdGlvbhgSIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EEB
Uh1lbmNyeXB0aW9uS2V5U2h1dGRvd25EdXJhdGlvbhIuChBzZXNzaW9uX2FmZmluaXR5GBMg
ASgIQgPgQQFSD3Nlc3Npb25BZmZpbml0eRI3ChVoZWFsdGhfY2hlY2tfZGlzYWJsZWQYFCAB
KAhCA+BBAVITaGVhbHRoQ2hlY2tEaXNhYmxlZBJLCg1ub2RlX3NlbGVjdG9yGBUgASgLMiEu
Z29vZ2xlLmNsb3VkLnJ1bi52Mi5Ob2RlU2VsZWN0b3JCA+BBAVIMbm9kZVNlbGVjdG9yEmoK
GHdvcmtsb2FkX2lkZW50aXR5X2NvbmZpZxgbIAEoCzIrLmdvb2dsZS5jbG91ZC5ydW4udjIu
V29ya2xvYWRJZGVudGl0eUNvbmZpZ0ID4EEBUhZ3b3JrbG9hZElkZW50aXR5Q29uZmlnEksK
HWdwdV96b25hbF9yZWR1bmRhbmN5X2Rpc2FibGVkGBggASgIQgPgQQFIAFIaZ3B1Wm9uYWxS
ZWR1bmRhbmN5RGlzYWJsZWSIAQESGwoGY2xpZW50GBwgASgJQgPgQQFSBmNsaWVudBIqCg5j
bGllbnRfdmVyc2lvbhgdIAEoCUID4EEBUg1jbGllbnRWZXJzaW9uEloKEmFtYmllbnRfbmV0
d29ya2luZxghIAEoCzImLmdvb2dsZS5jbG91ZC5ydW4udjIuQW1iaWVudE5ldHdvcmtpbmdC
A+BBAVIRYW1iaWVudE5ldHdvcmtpbmcaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo+ChBBbm5vdGF0aW9uc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCIAoeX2dwdV96b25hbF9y
ZWR1bmRhbmN5X2Rpc2FibGVkQl0KF2NvbS5nb29nbGUuY2xvdWQucnVuLnYyQhVSZXZpc2lv
blRlbXBsYXRlUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9ydW4vYXBpdjIvcnVucGI7
cnVucGJKvzEKBxIFDgCUAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
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
CgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACsKCQoCAwMSAxUAKwoJ
CgIDBBIDFgAzCgkKAgMFEgMXACgKCAoBCBIDGQBACgkKAggLEgMZAEAKCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwA2CgkKAggIEgMbADYKCAoBCBIDHAAwCgkKAggBEgMcADAKaAoC
BAASBSAAlAEBGlsgUmV2aXNpb25UZW1wbGF0ZSBkZXNjcmliZXMgdGhlIGRhdGEgYSByZXZp
c2lvbiBzaG91bGQgaGF2ZSB3aGVuIGNyZWF0ZWQgZnJvbQogYSB0ZW1wbGF0ZS4KCgoKAwQA
ARIDIAgYCpUBCgQEAAIAEgQjAiYEGoYBIE9wdGlvbmFsLiBUaGUgdW5pcXVlIG5hbWUgZm9y
IHRoZSByZXZpc2lvbi4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCBpdAogd2lsbCBiZSBh
dXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBiYXNlZCBvbiB0aGUgU2VydmljZSBuYW1lLgoKDAoF
BAACAAUSAyMCCAoMCgUEAAIAARIDIwkRCgwKBQQAAgADEgMjFBUKDQoFBAACAAgSBCMWJgMK
DwoIBAACAAicCAASAyQEKgoOCgcEAAIACJ8IEgMlBE0KwQUKBAQAAgESAzMCShqzBSBPcHRp
b25hbC4gVW5zdHJ1Y3R1cmVkIGtleSB2YWx1ZSBtYXAgdGhhdCBjYW4gYmUgdXNlZCB0byBv
cmdhbml6ZSBhbmQKIGNhdGVnb3JpemUgb2JqZWN0cy4gVXNlci1wcm92aWRlZCBsYWJlbHMg
YXJlIHNoYXJlZCB3aXRoIEdvb2dsZSdzIGJpbGxpbmcKIHN5c3RlbSwgc28gdGhleSBjYW4g
YmUgdXNlZCB0byBmaWx0ZXIsIG9yIGJyZWFrIGRvd24gYmlsbGluZyBjaGFyZ2VzIGJ5CiB0
ZWFtLCBjb21wb25lbnQsIGVudmlyb25tZW50LCBzdGF0ZSwgZXRjLiBGb3IgbW9yZSBpbmZv
cm1hdGlvbiwgdmlzaXQKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5h
Z2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzIG9yCiBodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vcnVuL2RvY3MvY29uZmlndXJpbmcvbGFiZWxzLgoKIDxwPkNsb3VkIFJ1biBB
UEkgdjIgZG9lcyBub3Qgc3VwcG9ydCBsYWJlbHMgd2l0aCBgcnVuLmdvb2dsZWFwaXMuY29t
YCwKIGBjbG91ZC5nb29nbGVhcGlzLmNvbWAsIGBzZXJ2aW5nLmtuYXRpdmUuZGV2YCwgb3Ig
YGF1dG9zY2FsaW5nLmtuYXRpdmUuZGV2YAogbmFtZXNwYWNlcywgYW5kIHRoZXkgd2lsbCBi
ZSByZWplY3RlZC4gQWxsIHN5c3RlbSBsYWJlbHMgaW4gdjEgbm93IGhhdmUgYQogY29ycmVz
cG9uZGluZyBmaWVsZCBpbiB2MiBSZXZpc2lvblRlbXBsYXRlLgoKDAoFBAACAQYSAzMCFQoM
CgUEAAIBARIDMxYcCgwKBQQAAgEDEgMzHyAKDAoFBAACAQgSAzMhSQoPCggEAAIBCJwIABID
MyJICqkECgQEAAICEgNAAk8amwQgT3B0aW9uYWwuIFVuc3RydWN0dXJlZCBrZXkgdmFsdWUg
bWFwIHRoYXQgbWF5IGJlIHNldCBieSBleHRlcm5hbCB0b29scyB0bwogc3RvcmUgYW5kIGFy
Yml0cmFyeSBtZXRhZGF0YS4gVGhleSBhcmUgbm90IHF1ZXJ5YWJsZSBhbmQgc2hvdWxkIGJl
CiBwcmVzZXJ2ZWQgd2hlbiBtb2RpZnlpbmcgb2JqZWN0cy4KCiA8cD5DbG91ZCBSdW4gQVBJ
IHYyIGRvZXMgbm90IHN1cHBvcnQgYW5ub3RhdGlvbnMgd2l0aCBgcnVuLmdvb2dsZWFwaXMu
Y29tYCwKIGBjbG91ZC5nb29nbGVhcGlzLmNvbWAsIGBzZXJ2aW5nLmtuYXRpdmUuZGV2YCwg
b3IgYGF1dG9zY2FsaW5nLmtuYXRpdmUuZGV2YAogbmFtZXNwYWNlcywgYW5kIHRoZXkgd2ls
bCBiZSByZWplY3RlZC4gQWxsIHN5c3RlbSBhbm5vdGF0aW9ucyBpbiB2MSBub3cKIGhhdmUg
YSBjb3JyZXNwb25kaW5nIGZpZWxkIGluIHYyIFJldmlzaW9uVGVtcGxhdGUuCgogPHA+VGhp
cyBmaWVsZCBmb2xsb3dzIEt1YmVybmV0ZXMgYW5ub3RhdGlvbnMnIG5hbWVzcGFjaW5nLCBs
aW1pdHMsIGFuZAogcnVsZXMuCgoMCgUEAAICBhIDQAIVCgwKBQQAAgIBEgNAFiEKDAoFBAAC
AgMSA0AkJQoMCgUEAAICCBIDQCZOCg8KCAQAAgIInAgAEgNAJ00KPAoEBAACAxIDQwJHGi8g
T3B0aW9uYWwuIFNjYWxpbmcgc2V0dGluZ3MgZm9yIHRoaXMgUmV2aXNpb24uCgoMCgUEAAID
BhIDQwIRCgwKBQQAAgMBEgNDEhkKDAoFBAACAwMSA0McHQoMCgUEAAIDCBIDQx5GCg8KCAQA
AgMInAgAEgNDH0UKqAEKBAQAAgQSA0gCRBqaASBPcHRpb25hbC4gVlBDIEFjY2VzcyBjb25m
aWd1cmF0aW9uIHRvIHVzZSBmb3IgdGhpcyBSZXZpc2lvbi4gRm9yIG1vcmUKIGluZm9ybWF0
aW9uLCB2aXNpdAogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3J1bi9kb2NzL2NvbmZpZ3Vy
aW5nL2Nvbm5lY3RpbmctdnBjLgoKDAoFBAACBAYSA0gCCwoMCgUEAAIEARIDSAwWCgwKBQQA
AgQDEgNIGRoKDAoFBAACBAgSA0gbQwoPCggEAAIECJwIABIDSBxCClIKBAQAAgUSA0sCUBpF
IE9wdGlvbmFsLiBNYXggYWxsb3dlZCB0aW1lIGZvciBhbiBpbnN0YW5jZSB0byByZXNwb25k
IHRvIGEgcmVxdWVzdC4KCgwKBQQAAgUGEgNLAhoKDAoFBAACBQESA0sbIgoMCgUEAAIFAxID
SyUmCgwKBQQAAgUIEgNLJ08KDwoIBAACBQicCAASA0soTgq3AgoEBAACBhIDUQJGGqkCIE9w
dGlvbmFsLiBFbWFpbCBhZGRyZXNzIG9mIHRoZSBJQU0gc2VydmljZSBhY2NvdW50IGFzc29j
aWF0ZWQgd2l0aCB0aGUKIHJldmlzaW9uIG9mIHRoZSBzZXJ2aWNlLiBUaGUgc2VydmljZSBh
Y2NvdW50IHJlcHJlc2VudHMgdGhlIGlkZW50aXR5IG9mIHRoZQogcnVubmluZyByZXZpc2lv
biwgYW5kIGRldGVybWluZXMgd2hhdCBwZXJtaXNzaW9ucyB0aGUgcmV2aXNpb24gaGFzLiBJ
ZiBub3QKIHByb3ZpZGVkLCB0aGUgcmV2aXNpb24gd2lsbCB1c2UgdGhlIHByb2plY3QncyBk
ZWZhdWx0IHNlcnZpY2UgYWNjb3VudC4KCgwKBQQAAgYFEgNRAggKDAoFBAACBgESA1EJGAoM
CgUEAAIGAxIDURscCgwKBQQAAgYIEgNRHUUKDwoIBAACBgicCAASA1EeRApVCgQEAAIHEgNV
AiUaSCBIb2xkcyB0aGUgbGlzdCB3aGljaCBkZWZpbmUgdGhlIHVuaXRzIG9mIGV4ZWN1dGlv
biBmb3IgdGhpcwogUmV2aXNpb24uCgoMCgUEAAIHBBIDVQIKCgwKBQQAAgcGEgNVCxQKDAoF
BAACBwESA1UVHwoMCgUEAAIHAxIDVSIkCjUKBAQAAggSA1gCTxooIE9wdGlvbmFsLiBDb25m
aWd1cmF0aW9uIGZvciBzYW5kYm94ZXMuCgoMCgUEAAIIBhIDWAIWCgwKBQQAAggBEgNYFyAK
DAoFBAACCAMSA1gjJQoMCgUEAAIICBIDWCZOCg8KCAQAAggInAgAEgNYJ00KSwoEBAACCRID
WwJIGj4gT3B0aW9uYWwuIEEgbGlzdCBvZiBWb2x1bWVzIHRvIG1ha2UgYXZhaWxhYmxlIHRv
IGNvbnRhaW5lcnMuCgoMCgUEAAIJBBIDWwIKCgwKBQQAAgkGEgNbCxEKDAoFBAACCQESA1sS
GQoMCgUEAAIJAxIDWxweCgwKBQQAAgkIEgNbH0cKDwoIBAACCQicCAASA1sgRgpICgQEAAIK
EgReAl8vGjogT3B0aW9uYWwuIFRoZSBzYW5kYm94IGVudmlyb25tZW50IHRvIGhvc3QgdGhp
cyBSZXZpc2lvbi4KCgwKBQQAAgoGEgNeAhYKDAoFBAACCgESA14XLAoMCgUEAAIKAxIDXi8x
CgwKBQQAAgoIEgNfBi4KDwoIBAACCgicCAASA18HLQrEAQoEBAACCxIEZAJmBRq1ASBBIHJl
ZmVyZW5jZSB0byBhIGN1c3RvbWVyIG1hbmFnZWQgZW5jcnlwdGlvbiBrZXkgKENNRUspIHRv
IHVzZSB0byBlbmNyeXB0CiB0aGlzIGNvbnRhaW5lciBpbWFnZS4gRm9yIG1vcmUgaW5mb3Jt
YXRpb24sIGdvIHRvCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcnVuL2RvY3Mvc2VjdXJp
bmcvdXNpbmctY21lawoKDAoFBAACCwUSA2QCCAoMCgUEAAILARIDZAkXCgwKBQQAAgsDEgNk
GhwKDQoFBAACCwgSBGQdZgQKDwoHBAACCwifCBIEZB5mAwrgAQoEBAACDBIEawJsLxrRASBP
cHRpb25hbC4gU2V0cyB0aGUgbWF4aW11bSBudW1iZXIgb2YgcmVxdWVzdHMgdGhhdCBlYWNo
IHNlcnZpbmcgaW5zdGFuY2UKIGNhbiByZWNlaXZlLiBJZiBub3Qgc3BlY2lmaWVkIG9yIDAs
IGNvbmN1cnJlbmN5IGRlZmF1bHRzIHRvIDgwIHdoZW4KIHJlcXVlc3RlZCBgQ1BVID49IDFg
IGFuZCBkZWZhdWx0cyB0byAxIHdoZW4gcmVxdWVzdGVkIGBDUFUgPCAxYC4KCgwKBQQAAgwF
EgNrAgcKDAoFBAACDAESA2sIKAoMCgUEAAIMAxIDaystCgwKBQQAAgwIEgNsBi4KDwoIBAAC
DAicCAASA2wHLQo7CgQEAAINEgNvAkkaLiBPcHRpb25hbC4gRW5hYmxlcyBzZXJ2aWNlIG1l
c2ggY29ubmVjdGl2aXR5LgoKDAoFBAACDQYSA28CDQoMCgUEAAINARIDbw4aCgwKBQQAAg0D
EgNvHR8KDAoFBAACDQgSA28gSAoPCggEAAINCJwIABIDbyFHCk4KBAQAAg4SBHICcy8aQCBP
cHRpb25hbC4gVGhlIGFjdGlvbiB0byB0YWtlIGlmIHRoZSBlbmNyeXB0aW9uIGtleSBpcyBy
ZXZva2VkLgoKDAoFBAACDgYSA3ICHwoMCgUEAAIOARIDciBACgwKBQQAAg4DEgNyQ0UKDAoF
BAACDggSA3MGLgoPCggEAAIOCJwIABIDcwctCp4BCgQEAAIPEgR3AngvGo8BIE9wdGlvbmFs
LiBJZiBlbmNyeXB0aW9uX2tleV9yZXZvY2F0aW9uX2FjdGlvbiBpcyBTSFVURE9XTiwgdGhl
IGR1cmF0aW9uCiBiZWZvcmUgc2h1dHRpbmcgZG93biBhbGwgaW5zdGFuY2VzLiBUaGUgbWlu
aW11bSBpbmNyZW1lbnQgaXMgMSBob3VyLgoKDAoFBAACDwYSA3cCGgoMCgUEAAIPARIDdxs7
CgwKBQQAAg8DEgN3PkAKDAoFBAACDwgSA3gGLgoPCggEAAIPCJwIABIDeActCjEKBAQAAhAS
A3sCRhokIE9wdGlvbmFsLiBFbmFibGUgc2Vzc2lvbiBhZmZpbml0eS4KCgwKBQQAAhAFEgN7
AgYKDAoFBAACEAESA3sHFwoMCgUEAAIQAxIDexocCgwKBQQAAhAIEgN7HUUKDwoIBAACEAic
CAASA3seRApPCgQEAAIREgN+AksaQiBPcHRpb25hbC4gRGlzYWJsZXMgaGVhbHRoIGNoZWNr
aW5nIGNvbnRhaW5lcnMgZHVyaW5nIGRlcGxveW1lbnQuCgoMCgUEAAIRBRIDfgIGCgwKBQQA
AhEBEgN+BxwKDAoFBAACEQMSA34fIQoMCgUEAAIRCBIDfiJKCg8KCAQAAhEInAgAEgN+I0kK
RgoEBAACEhIEgQECSxo4IE9wdGlvbmFsLiBUaGUgbm9kZSBzZWxlY3RvciBmb3IgdGhlIHJl
dmlzaW9uIHRlbXBsYXRlLgoKDQoFBAACEgYSBIEBAg4KDQoFBAACEgESBIEBDxwKDQoFBAAC
EgMSBIEBHyEKDQoFBAACEggSBIEBIkoKEAoIBAACEgicCAASBIEBI0kKRgoEBAACExIGhAEC
hQEvGjYgT3B0aW9uYWwuIFRoZSBSZXZpc2lvbidzIHdvcmtsb2FkIGlkZW50aXR5IHNldHRp
bmdzLgoKDQoFBAACEwYSBIQBAhgKDQoFBAACEwESBIQBGTEKDQoFBAACEwMSBIQBNDYKDQoF
BAACEwgSBIUBBi4KEAoIBAACEwicCAASBIUBBy0KVgoEBAACFBIGiAECiQEvGkYgT3B0aW9u
YWwuIFRydWUgaWYgR1BVIHpvbmFsIHJlZHVuZGFuY3kgaXMgZGlzYWJsZWQgb24gdGhpcyBy
ZXZpc2lvbi4KCg0KBQQAAhQEEgSIAQIKCg0KBQQAAhQFEgSIAQsPCg0KBQQAAhQBEgSIARAt
Cg0KBQQAAhQDEgSIATAyCg0KBQQAAhQIEgSJAQYuChAKCAQAAhQInAgAEgSJAQctCkIKBAQA
AhUSBIwBAj4aNCBPcHRpb25hbC4gQXJiaXRyYXJ5IGlkZW50aWZpZXIgZm9yIHRoZSBBUEkg
Y2xpZW50LgoKDQoFBAACFQUSBIwBAggKDQoFBAACFQESBIwBCQ8KDQoFBAACFQMSBIwBEhQK
DQoFBAACFQgSBIwBFT0KEAoIBAACFQicCAASBIwBFjwKSgoEBAACFhIEjwECRho8IE9wdGlv
bmFsLiBBcmJpdHJhcnkgdmVyc2lvbiBpZGVudGlmaWVyIGZvciB0aGUgQVBJIGNsaWVudC4K
Cg0KBQQAAhYFEgSPAQIICg0KBQQAAhYBEgSPAQkXCg0KBQQAAhYDEgSPARocCg0KBQQAAhYI
EgSPAR1FChAKCAQAAhYInAgAEgSPAR5EClMKBAQAAhcSBpIBApMBLxpDIE9wdGlvbmFsLiBU
aGUgYW1iaWVudCBuZXR3b3JraW5nIGNvbmZpZ3VyYXRpb24gZm9yIHRoaXMgcmV2aXNpb24u
CgoNCgUEAAIXBhIEkgECEwoNCgUEAAIXARIEkgEUJgoNCgUEAAIXAxIEkgEpKwoNCgUEAAIX
CBIEkwEGLgoQCggEAAIXCJwIABIEkwEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate ===
    # Fields for RevisionTemplate
    # Field: revision Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.run.v2.RevisionTemplate.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.RevisionTemplate.AnnotationsEntry)
    # Field: scaling Type: 11 (.google.cloud.run.v2.RevisionScaling)
    # Field: vpc_access Type: 11 (.google.cloud.run.v2.VpcAccess)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: service_account Type: 9 ()
    # Field: containers Type: 11 (.google.cloud.run.v2.Container)
    # Field: sandboxes Type: 11 (.google.cloud.run.v2.SandboxConfiguration)
    # Field: volumes Type: 11 (.google.cloud.run.v2.Volume)
    # Field: execution_environment Type: 14 (.google.cloud.run.v2.ExecutionEnvironment)
    # Field: encryption_key Type: 9 ()
    # Field: max_instance_request_concurrency Type: 5 ()
    # Field: service_mesh Type: 11 (.google.cloud.run.v2.ServiceMesh)
    # Field: encryption_key_revocation_action Type: 14 (.google.cloud.run.v2.EncryptionKeyRevocationAction)
    # Field: encryption_key_shutdown_duration Type: 11 (.google.protobuf.Duration)
    # Field: session_affinity Type: 8 ()
    # Field: health_check_disabled Type: 8 ()
    # Field: node_selector Type: 11 (.google.cloud.run.v2.NodeSelector)
    # Field: workload_identity_config Type: 11 (.google.cloud.run.v2.WorkloadIdentityConfig)
    # Field: gpu_zonal_redundancy_disabled Type: 8 ()
    # Field: client Type: 9 ()
    # Field: client_version Type: 9 ()
    # Field: ambient_networking Type: 11 (.google.cloud.run.v2.AmbientNetworking)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::RevisionTemplate - Compiled Protocol Buffers messages for google/cloud/run/v2/revision_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::RevisionTemplate;

    my $msg = Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate->new({
        revision => $revision,
        labels => $labels,
        annotations => $annotations,
        scaling => $scaling,
    });

    # Read or update a field
    my $val = $msg->revision();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/revision_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate

RevisionTemplate describes the data a revision should have when created from
a template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Optional. The unique name for the revision. If this field is omitted, it
will be automatically generated based on the Service name.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::LabelsEntry>)

Optional. Unstructured key value map that can be used to organize and
categorize objects. User-provided labels are shared with Google's billing
system, so they can be used to filter, or break down billing charges by
team, component, environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels.

<p>Cloud Run API v2 does not support labels with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system labels in v1 now have a
corresponding field in v2 RevisionTemplate.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::AnnotationsEntry>)

Optional. Unstructured key value map that may be set by external tools to
store and arbitrary metadata. They are not queryable and should be
preserved when modifying objects.

<p>Cloud Run API v2 does not support annotations with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system annotations in v1 now
have a corresponding field in v2 RevisionTemplate.

<p>This field follows Kubernetes annotations' namespacing, limits, and
rules.

=item * C<< $msg->scaling() >> / C<< $msg->scaling($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::RevisionScaling>)

Optional. Scaling settings for this Revision.

=item * C<< $msg->vpc_access() >> / C<< $msg->vpc_access($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess>)

Optional. VPC Access configuration to use for this Revision. For more
information, visit
https://cloud.google.com/run/docs/configuring/connecting-vpc.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Max allowed time for an instance to respond to a request.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Email address of the IAM service account associated with the
revision of the service. The service account represents the identity of the
running revision, and determines what permissions the revision has. If not
provided, the revision will use the project's default service account.

=item * C<< $msg->containers() >> / C<< $msg->containers($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Container>)

Holds the list which define the units of execution for this
Revision.

=item * C<< $msg->sandboxes() >> / C<< $msg->sandboxes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxConfiguration>)

Optional. Configuration for sandboxes.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Volume>)

Optional. A list of Volumes to make available to containers.

=item * C<< $msg->execution_environment() >> / C<< $msg->execution_environment($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::ExecutionEnvironment>)

Optional. The sandbox environment to host this Revision.

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<String>

A reference to a customer managed encryption key (CMEK) to use to encrypt
this container image. For more information, go to
https://cloud.google.com/run/docs/securing/using-cmek

=item * C<< $msg->max_instance_request_concurrency() >> / C<< $msg->max_instance_request_concurrency($value) >>

Type: C<Int32>

Optional. Sets the maximum number of requests that each serving instance
can receive. If not specified or 0, concurrency defaults to 80 when
requested `CPU >= 1` and defaults to 1 when requested `CPU < 1`.

=item * C<< $msg->service_mesh() >> / C<< $msg->service_mesh($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::ServiceMesh>)

Optional. Enables service mesh connectivity.

=item * C<< $msg->encryption_key_revocation_action() >> / C<< $msg->encryption_key_revocation_action($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::EncryptionKeyRevocationAction>)

Optional. The action to take if the encryption key is revoked.

=item * C<< $msg->encryption_key_shutdown_duration() >> / C<< $msg->encryption_key_shutdown_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. If encryption_key_revocation_action is SHUTDOWN, the duration
before shutting down all instances. The minimum increment is 1 hour.

=item * C<< $msg->session_affinity() >> / C<< $msg->session_affinity($value) >>

Type: C<Bool>

Optional. Enable session affinity.

=item * C<< $msg->health_check_disabled() >> / C<< $msg->health_check_disabled($value) >>

Type: C<Bool>

Optional. Disables health checking containers during deployment.

=item * C<< $msg->node_selector() >> / C<< $msg->node_selector($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::NodeSelector>)

Optional. The node selector for the revision template.

=item * C<< $msg->workload_identity_config() >> / C<< $msg->workload_identity_config($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig>)

Optional. The Revision's workload identity settings.

=item * C<< $msg->gpu_zonal_redundancy_disabled() >> / C<< $msg->gpu_zonal_redundancy_disabled($value) >>

Type: C<Bool>

Optional. True if GPU zonal redundancy is disabled on this revision.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Optional. Arbitrary identifier for the API client.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Optional. Arbitrary version identifier for the API client.

=item * C<< $msg->ambient_networking() >> / C<< $msg->ambient_networking($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::AmbientNetworking>)

Optional. The ambient networking configuration for this revision.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::RevisionTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
