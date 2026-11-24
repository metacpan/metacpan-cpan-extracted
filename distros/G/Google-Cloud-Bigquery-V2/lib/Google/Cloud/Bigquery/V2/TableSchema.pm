package Google::Cloud::Bigquery::V2::TableSchema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvdGFibGVfc2NoZW1hLnByb3RvEhhnb29nbGUu
Y2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdv
b2dsZS9wcm90b2J1Zi93cmFwcGVycy5wcm90byKtAQoLVGFibGVTY2hlbWESQgoGZmllbGRz
GAEgAygLMiouZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlRhYmxlRmllbGRTY2hlbWFSBmZp
ZWxkcxJaChFmb3JlaWduX3R5cGVfaW5mbxgDIAEoCzIpLmdvb2dsZS5jbG91ZC5iaWdxdWVy
eS52Mi5Gb3JlaWduVHlwZUluZm9CA+BBAVIPZm9yZWlnblR5cGVJbmZvIqIBCg9Gb3JlaWdu
VHlwZUluZm8SWgoLdHlwZV9zeXN0ZW0YASABKA4yNC5nb29nbGUuY2xvdWQuYmlncXVlcnku
djIuRm9yZWlnblR5cGVJbmZvLlR5cGVTeXN0ZW1CA+BBAlIKdHlwZVN5c3RlbSIzCgpUeXBl
U3lzdGVtEhsKF1RZUEVfU1lTVEVNX1VOU1BFQ0lGSUVEEAASCAoESElWRRABIjQKEERhdGFQ
b2xpY3lPcHRpb24SFwoEbmFtZRgBIAEoCUgAUgRuYW1liAEBQgcKBV9uYW1lImEKDkRhdGFQ
b2xpY3lMaXN0Ek8KDWRhdGFfcG9saWNpZXMYASADKAsyKi5nb29nbGUuY2xvdWQuYmlncXVl
cnkudjIuRGF0YVBvbGljeU9wdGlvblIMZGF0YVBvbGljaWVzIu4SChBUYWJsZUZpZWxkU2No
ZW1hEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIXCgR0eXBlGAIgASgJQgPgQQJSBHR5cGUS
FwoEbW9kZRgDIAEoCUID4EEBUgRtb2RlEkcKBmZpZWxkcxgEIAMoCzIqLmdvb2dsZS5jbG91
ZC5iaWdxdWVyeS52Mi5UYWJsZUZpZWxkU2NoZW1hQgPgQQFSBmZpZWxkcxJDCgtkZXNjcmlw
dGlvbhgGIAEoCzIcLmdvb2dsZS5wcm90b2J1Zi5TdHJpbmdWYWx1ZUID4EEBUgtkZXNjcmlw
dGlvbhJeCgtwb2xpY3lfdGFncxgJIAEoCzI4Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5U
YWJsZUZpZWxkU2NoZW1hLlBvbGljeVRhZ0xpc3RCA+BBAVIKcG9saWN5VGFncxKBAQoZZGF0
YV9nb3Zlcm5hbmNlX3RhZ3NfaW5mbxgeIAEoCzJBLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52
Mi5UYWJsZUZpZWxkU2NoZW1hLkRhdGFHb3Zlcm5hbmNlVGFnc0luZm9CA+BBAVIWZGF0YUdv
dmVybmFuY2VUYWdzSW5mbxJUCg1kYXRhX3BvbGljaWVzGBUgAygLMiouZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyLkRhdGFQb2xpY3lPcHRpb25CA+BBAVIMZGF0YVBvbGljaWVzElcKEGRh
dGFfcG9saWN5X2xpc3QYHSABKAsyKC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuRGF0YVBv
bGljeUxpc3RCA+BBAVIOZGF0YVBvbGljeUxpc3QSIgoKbWF4X2xlbmd0aBgKIAEoA0ID4EEB
UgltYXhMZW5ndGgSIQoJcHJlY2lzaW9uGAsgASgDQgPgQQFSCXByZWNpc2lvbhIZCgVzY2Fs
ZRgMIAEoA0ID4EEBUgVzY2FsZRJRChN0aW1lc3RhbXBfcHJlY2lzaW9uGBsgASgLMhsuZ29v
Z2xlLnByb3RvYnVmLkludDY0VmFsdWVCA+BBAVISdGltZXN0YW1wUHJlY2lzaW9uEmEKDXJv
dW5kaW5nX21vZGUYDyABKA4yNy5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuVGFibGVGaWVs
ZFNjaGVtYS5Sb3VuZGluZ01vZGVCA+BBAVIMcm91bmRpbmdNb2RlEj8KCWNvbGxhdGlvbhgN
IAEoCzIcLmdvb2dsZS5wcm90b2J1Zi5TdHJpbmdWYWx1ZUID4EEBUgljb2xsYXRpb24SWwoY
ZGVmYXVsdF92YWx1ZV9leHByZXNzaW9uGA4gASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0cmlu
Z1ZhbHVlQgPgQQFSFmRlZmF1bHRWYWx1ZUV4cHJlc3Npb24SbgoScmFuZ2VfZWxlbWVudF90
eXBlGBIgASgLMjsuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlRhYmxlRmllbGRTY2hlbWEu
RmllbGRFbGVtZW50VHlwZUID4EEBUhByYW5nZUVsZW1lbnRUeXBlEjsKF2ZvcmVpZ25fdHlw
ZV9kZWZpbml0aW9uGBcgASgJQgPgQQFSFWZvcmVpZ25UeXBlRGVmaW5pdGlvbhJqChBnZW5l
cmF0ZWRfY29sdW1uGBwgASgLMjouZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlRhYmxlRmll
bGRTY2hlbWEuR2VuZXJhdGVkQ29sdW1uQgPgQQFSD2dlbmVyYXRlZENvbHVtbholCg1Qb2xp
Y3lUYWdMaXN0EhQKBW5hbWVzGAEgAygJUgVuYW1lcxryAQoWRGF0YUdvdmVybmFuY2VUYWdz
SW5mbxKQAQoUZGF0YV9nb3Zlcm5hbmNlX3RhZ3MYASADKAsyWS5nb29nbGUuY2xvdWQuYmln
cXVlcnkudjIuVGFibGVGaWVsZFNjaGVtYS5EYXRhR292ZXJuYW5jZVRhZ3NJbmZvLkRhdGFH
b3Zlcm5hbmNlVGFnc0VudHJ5QgPgQQFSEmRhdGFHb3Zlcm5hbmNlVGFncxpFChdEYXRhR292
ZXJuYW5jZVRhZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBGisKEEZpZWxkRWxlbWVudFR5cGUSFwoEdHlwZRgBIAEoCUID4EECUgR0eXBlGt4B
ChdHZW5lcmF0ZWRFeHByZXNzaW9uSW5mbxI9ChVnZW5lcmF0aW9uX2V4cHJlc3Npb24YASAB
KAlCA+BBAUgAUhRnZW5lcmF0aW9uRXhwcmVzc2lvbogBARIsCgxhc3luY2hyb25vdXMYAiAB
KAhCA+BBAUgBUgxhc3luY2hyb25vdXOIAQESIAoGc3RvcmVkGAMgASgIQgPgQQFIAlIGc3Rv
cmVkiAEBQhgKFl9nZW5lcmF0aW9uX2V4cHJlc3Npb25CDwoNX2FzeW5jaHJvbm91c0IJCgdf
c3RvcmVkGpEDCg9HZW5lcmF0ZWRDb2x1bW4SeQoOZ2VuZXJhdGVkX21vZGUYASABKA4ySC5n
b29nbGUuY2xvdWQuYmlncXVlcnkudjIuVGFibGVGaWVsZFNjaGVtYS5HZW5lcmF0ZWRDb2x1
bW4uR2VuZXJhdGVkTW9kZUID4EEBSAFSDWdlbmVyYXRlZE1vZGWIAQESgAEKGWdlbmVyYXRl
ZF9leHByZXNzaW9uX2luZm8YAyABKAsyQi5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuVGFi
bGVGaWVsZFNjaGVtYS5HZW5lcmF0ZWRFeHByZXNzaW9uSW5mb0gAUhdnZW5lcmF0ZWRFeHBy
ZXNzaW9uSW5mbyJfCg1HZW5lcmF0ZWRNb2RlEh4KGkdFTkVSQVRFRF9NT0RFX1VOU1BFQ0lG
SUVEEAASFAoQR0VORVJBVEVEX0FMV0FZUxABEhgKFEdFTkVSQVRFRF9CWV9ERUZBVUxUEAJC
DAoKZGVmaW5pdGlvbkIRCg9fZ2VuZXJhdGVkX21vZGUiYQoMUm91bmRpbmdNb2RlEh0KGVJP
VU5ESU5HX01PREVfVU5TUEVDSUZJRUQQABIdChlST1VORF9IQUxGX0FXQVlfRlJPTV9aRVJP
EAESEwoPUk9VTkRfSEFMRl9FVkVOEAJCbQocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52
MkIQVGFibGVTY2hlbWFQcm90b1o7Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9h
cGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGJKsGkKBxIFDgDUAgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAoCggK
AQgSAxUAUgoJCgIICxIDFQBSCggKAQgSAxYAMQoJCgIICBIDFgAxCggKAQgSAxcANQoJCgII
ARIDFwA1Ch8KAgQAEgQaACMBGhMgU2NoZW1hIG9mIGEgdGFibGUKCgoKAwQAARIDGggTCi8K
BAQAAgASAxwCJxoiIERlc2NyaWJlcyB0aGUgZmllbGRzIGluIGEgdGFibGUuCgoMCgUEAAIA
BBIDHAIKCgwKBQQAAgAGEgMcCxsKDAoFBAACAAESAxwcIgoMCgUEAAIAAxIDHCUmCtQBCgQE
AAIBEgQhAiIvGsUBIE9wdGlvbmFsLiBTcGVjaWZpZXMgbWV0YWRhdGEgb2YgdGhlIGZvcmVp
Z24gZGF0YSB0eXBlIGRlZmluaXRpb24gaW4gZmllbGQKIHNjaGVtYQogKFtUYWJsZUZpZWxk
U2NoZW1hLmZvcmVpZ25fdHlwZV9kZWZpbml0aW9uXVtnb29nbGUuY2xvdWQuYmlncXVlcnku
djIuVGFibGVGaWVsZFNjaGVtYS5mb3JlaWduX3R5cGVfZGVmaW5pdGlvbl0pLgoKDAoFBAAC
AQYSAyECEQoMCgUEAAIBARIDIRIjCgwKBQQAAgEDEgMhJicKDAoFBAACAQgSAyIGLgoPCggE
AAIBCJwIABIDIgctCm8KAgQBEgQnADQBGmMgTWV0YWRhdGEgYWJvdXQgdGhlIGZvcmVpZ24g
ZGF0YSB0eXBlIGRlZmluaXRpb24gc3VjaCBhcyB0aGUgc3lzdGVtCiBpbiB3aGljaCB0aGUg
dHlwZSBpcyBkZWZpbmVkLgoKCgoDBAEBEgMnCBcKagoEBAEEABIEKgIwAxpcIEV4dGVybmFs
IHN5c3RlbXMsIHN1Y2ggYXMgcXVlcnkgZW5naW5lcyBvciB0YWJsZSBmb3JtYXRzLCB0aGF0
IGhhdmUgdGhlaXIKIG93biBkYXRhIHR5cGVzLgoKDAoFBAEEAAESAyoHEQoqCgYEAQQAAgAS
AywEIBobIFR5cGVTeXN0ZW0gbm90IHNwZWNpZmllZC4KCg4KBwQBBAACAAESAywEGwoOCgcE
AQQAAgACEgMsHh8KLAoGBAEEAAIBEgMvBA0aHSBSZXByZXNlbnRzIEhpdmUgZGF0YSB0eXBl
cy4KCg4KBwQBBAACAQESAy8ECAoOCgcEAQQAAgECEgMvCwwKUgoEBAECABIDMwJGGkUgUmVx
dWlyZWQuIFNwZWNpZmllcyB0aGUgc3lzdGVtIHdoaWNoIGRlZmluZXMgdGhlIGZvcmVpZ24g
ZGF0YSB0eXBlLgoKDAoFBAECAAYSAzMCDAoMCgUEAQIAARIDMw0YCgwKBQQBAgADEgMzGxwK
DAoFBAECAAgSAzMdRQoPCggEAQIACJwIABIDMx5ECsoBCgIEAhIEOQA9ARq9ASBEYXRhIHBv
bGljeSBvcHRpb24uIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtNYXNrIGRhdGEgYnkg
YXBwbHlpbmcgZGF0YSBwb2xpY2llcyB0byBhCiBjb2x1bW5dKGh0dHBzOi8vZG9jcy5jbG91
ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvY29sdW1uLWRhdGEtbWFza2luZyNkYXRhLXBv
bGljaWVzLW9uLWNvbHVtbikuCgoKCgMEAgESAzkIGAp/CgQEAgIAEgM8AhsaciBEYXRhIHBv
bGljeSByZXNvdXJjZSBuYW1lIGluIHRoZSBmb3JtIG9mCiBwcm9qZWN0cy9wcm9qZWN0X2lk
L2xvY2F0aW9ucy9sb2NhdGlvbl9pZC9kYXRhUG9saWNpZXMvZGF0YV9wb2xpY3lfaWQuCgoM
CgUEAgIABBIDPAIKCgwKBQQCAgAFEgM8CxEKDAoFBAICAAESAzwSFgoMCgUEAgIAAxIDPBka
CtUBCgIEAxIEQgBGARrIASBBIGxpc3Qgb2YgZGF0YSBwb2xpY3kgb3B0aW9ucy4gRm9yIG1v
cmUgaW5mb3JtYXRpb24sIHNlZQogW01hc2sgZGF0YSBieSBhcHBseWluZyBkYXRhIHBvbGlj
aWVzIHRvIGEKIGNvbHVtbl0oaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vYmlncXVl
cnkvZG9jcy9jb2x1bW4tZGF0YS1tYXNraW5nI2RhdGEtcG9saWNpZXMtb24tY29sdW1uKS4K
CgoKAwQDARIDQggWCmYKBAQDAgASA0UCLhpZIENvbnRhaW5zIGEgbGlzdCBvZiBkYXRhIHBv
bGljeSBvcHRpb25zLiBBdCBtb3N0IDkgZGF0YSBwb2xpY2llcyBhcmUKIGFsbG93ZWQgcGVy
IGZpZWxkLgoKDAoFBAMCAAQSA0UCCgoMCgUEAwIABhIDRQsbCgwKBQQDAgABEgNFHCkKDAoF
BAMCAAMSA0UsLQolCgIEBBIFSQDUAgEaGCBBIGZpZWxkIGluIFRhYmxlU2NoZW1hCgoKCgME
BAESA0kIGAoMCgQEBAMAEgRKAk8DCgwKBQQEAwABEgNKChcKpQEKBgQEAwACABIDTgQeGpUB
IEEgbGlzdCBvZiBwb2xpY3kgdGFnIHJlc291cmNlIG5hbWVzLiBGb3IgZXhhbXBsZSwKICJw
cm9qZWN0cy8xL2xvY2F0aW9ucy9ldS90YXhvbm9taWVzLzIvcG9saWN5VGFncy8zIi4gQXQg
bW9zdCAxIHBvbGljeSB0YWcKIGlzIGN1cnJlbnRseSBhbGxvd2VkLgoKDgoHBAQDAAIABBID
TgQMCg4KBwQEAwACAAUSA04NEwoOCgcEBAMAAgABEgNOFBkKDgoHBAQDAAIAAxIDThwdCgwK
BAQEAwESBFECXwMKDAoFBAQDAQESA1EKIAqFBQoGBAQDAQIAEgRdBF4xGvQEIE9wdGlvbmFs
LiBUaGUgZGF0YSBnb3Zlcm5hbmNlIHRhZ3MgYWRkZWQgdG8gdGhpcyBmaWVsZCBhcmUgdXNl
ZCBmb3IKIGZpZWxkLWxldmVsIGFjY2VzcyBjb250cm9sLiBPbmx5IG9uZSBkYXRhIGdvdmVy
bmFuY2UgdGFnIGlzIGN1cnJlbnRseQogc3VwcG9ydGVkIG9uIGEgZmllbGQuIFRhZyBrZXlz
IGFyZSBnbG9iYWxseSB1bmlxdWUuIFRhZyBrZXkgaXMgZXhwZWN0ZWQKIHRvIGJlIGluIHRo
ZSBuYW1lc3BhY2VkIGZvcm1hdCwgZm9yIGV4YW1wbGUgInBhcmVudC1pZC9waWkiIHdoZXJl
CiBwYXJlbnQtaWQgaXMgdGhlIElEIG9mIHRoZSBwYXJlbnQgb3JnYW5pemF0aW9uIG9yIHBy
b2plY3QgcmVzb3VyY2UgZm9yCiB0aGlzIHRhZyBrZXkuIFRhZyB2YWx1ZSBpcyBleHBlY3Rl
ZCB0byBiZSB0aGUgc2hvcnQgbmFtZSwgZm9yIGV4YW1wbGUKICJzZW5zaXRpdmUiLiBTZWUg
W1RhZwogZGVmaW5pdGlvbnNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vZG9jcy90
YWdzLWFjY2Vzcy1jb250cm9sI2RlZmluaXRpb25zKQogZm9yIG1vcmUgZGV0YWlscy4gRm9y
IGV4YW1wbGU6CiAgICJwYXJlbnQtaWQvcGlpIjogInNlbnNpdGl2ZSIsCiAgICJteVByb2pl
Y3QvY29zdF9jZW50ZXIiOiAic2FsZXMiCgoOCgcEBAMBAgAGEgNdBBcKDgoHBAQDAQIAARID
XRgsCg4KBwQEAwECAAMSA10vMAoOCgcEBAMBAgAIEgNeCDAKEQoKBAQDAQIACJwIABIDXgkv
CmIKBAQEBAASBGMCeAMaVCBSb3VuZGluZyBtb2RlIG9wdGlvbnMgdGhhdCBjYW4gYmUgdXNl
ZCB3aGVuIHN0b3JpbmcgTlVNRVJJQwogb3IgQklHTlVNRVJJQyB2YWx1ZXMuCgoMCgUEBAQA
ARIDYwcTCk0KBgQEBAACABIDZQQiGj4gVW5zcGVjaWZpZWQgd2lsbCBkZWZhdWx0IHRvIHVz
aW5nIFJPVU5EX0hBTEZfQVdBWV9GUk9NX1pFUk8uCgoOCgcEBAQAAgABEgNlBB0KDgoHBAQE
AAIAAhIDZSAhCuUBCgYEBAQAAgESA20EIhrVASBST1VORF9IQUxGX0FXQVlfRlJPTV9aRVJP
IHJvdW5kcyBoYWxmIHZhbHVlcyBhd2F5IGZyb20gemVybwogd2hlbiBhcHBseWluZyBwcmVj
aXNpb24gYW5kIHNjYWxlIHVwb24gd3JpdGluZyBvZiBOVU1FUklDIGFuZCBCSUdOVU1FUklD
CiB2YWx1ZXMuCiBGb3IgU2NhbGU6IDAKIDEuMSwgMS4yLCAxLjMsIDEuNCA9PiAxCiAxLjUs
IDEuNiwgMS43LCAxLjgsIDEuOSA9PiAyCgoOCgcEBAQAAgEBEgNtBB0KDgoHBAQEAAIBAhID
bSAhCvUBCgYEBAQAAgISA3cEGBrlASBST1VORF9IQUxGX0VWRU4gcm91bmRzIGhhbGYgdmFs
dWVzIHRvIHRoZSBuZWFyZXN0IGV2ZW4gdmFsdWUKIHdoZW4gYXBwbHlpbmcgcHJlY2lzaW9u
IGFuZCBzY2FsZSB1cG9uIHdyaXRpbmcgb2YgTlVNRVJJQyBhbmQgQklHTlVNRVJJQwogdmFs
dWVzLgogRm9yIFNjYWxlOiAwCiAxLjEsIDEuMiwgMS4zLCAxLjQgPT4gMQogMS41ID0+IDIK
IDEuNiwgMS43LCAxLjgsIDEuOSA9PiAyCiAyLjUgPT4gMgoKDgoHBAQEAAICARIDdwQTCg4K
BwQEBAACAgISA3cWFwo3CgQEBAMCEgR7An8DGikgUmVwcmVzZW50cyB0aGUgdHlwZSBvZiBh
IGZpZWxkIGVsZW1lbnQuCgoMCgUEBAMCARIDewoaCpwBCgYEBAMCAgASA34EPRqMASBSZXF1
aXJlZC4gVGhlIHR5cGUgb2YgYSBmaWVsZCBlbGVtZW50LiBGb3IgbW9yZSBpbmZvcm1hdGlv
biwgc2VlCiBbVGFibGVGaWVsZFNjaGVtYS50eXBlXVtnb29nbGUuY2xvdWQuYmlncXVlcnku
djIuVGFibGVGaWVsZFNjaGVtYS50eXBlXS4KCg4KBwQEAwICAAUSA34ECgoOCgcEBAMCAgAB
EgN+Cw8KDgoHBAQDAgIAAxIDfhITCg4KBwQEAwICAAgSA34UPAoRCgoEBAMCAgAInAgAEgN+
FTsKSgoEBAQDAxIGggECjQEDGjogRGVmaW5pdGlvbiBvZiB0aGUgZXhwcmVzc2lvbiB1c2Vk
IHRvIGdlbmVyYXRlIHRoZSBmaWVsZC4KCg0KBQQEAwMBEgSCAQohCmkKBgQEAwMCABIGhQEE
hgExGlcgT3B0aW9uYWwuIFRoZSBnZW5lcmF0aW9uIGV4cHJlc3Npb24gKGUuZy4gQUkuRU1C
RUQoLi4uKSkgdXNlZCB0byBnZW5lcmF0ZQogdGhlIGZpZWxkLgoKDwoHBAQDAwIABBIEhQEE
DAoPCgcEBAMDAgAFEgSFAQ0TCg8KBwQEAwMCAAESBIUBFCkKDwoHBAQDAwIAAxIEhQEsLQoP
CgcEBAMDAgAIEgSGAQgwChIKCgQEAwMCAAicCAASBIYBCS8KUQoGBAQDAwIBEgSJAQRMGkEg
T3B0aW9uYWwuIFdoZXRoZXIgdGhlIGNvbHVtbiBnZW5lcmF0aW9uIGlzIGRvbmUgYXN5bmNo
cm9ub3VzbHkuCgoPCgcEBAMDAgEEEgSJAQQMCg8KBwQEAwMCAQUSBIkBDREKDwoHBAQDAwIB
ARIEiQESHgoPCgcEBAMDAgEDEgSJASEiCg8KBwQEAwMCAQgSBIkBI0sKEgoKBAQDAwIBCJwI
ABIEiQEkSgpQCgYEBAMDAgISBIwBBEYaQCBPcHRpb25hbC4gV2hldGhlciB0aGUgZ2VuZXJh
dGVkIGNvbHVtbiBpcyBzdG9yZWQgaW4gdGhlIHRhYmxlLgoKDwoHBAQDAwICBBIEjAEEDAoP
CgcEBAMDAgIFEgSMAQ0RCg8KBwQEAwMCAgESBIwBEhgKDwoHBAQDAwICAxIEjAEbHAoPCgcE
BAMDAgIIEgSMAR1FChIKCgQEAwMCAgicCAASBIwBHkQKjgEKBAQEAwQSBpEBAqoBAxp+IE9w
dGlvbmFsLiBEZWZpbml0aW9uIG9mIGhvdyB2YWx1ZXMgYXJlIGdlbmVyYXRlZCBmb3IgdGhl
IGZpZWxkLgogT25seSB2YWxpZCBmb3IgdG9wLWxldmVsIHNjaGVtYSBmaWVsZHMgKG5vdCBu
ZXN0ZWQgZmllbGRzKS4KCg0KBQQEAwQBEgSRAQoZClkKBgQEAwQEABIGkwEEngEFGkcgRGlj
dGF0ZXMgd2hlbiBzeXN0ZW0gZ2VuZXJhdGVkIHZhbHVlcyBhcmUgdXNlZCB0byBwb3B1bGF0
ZSB0aGUgZmllbGQuCgoPCgcEBAMEBAABEgSTAQkWCk8KCAQEAwQEAAIAEgSVAQYlGj0gVW5z
cGVjaWZpZWQgR2VuZXJhdGVkTW9kZSB3aWxsIGRlZmF1bHQgdG8gR0VORVJBVEVEX0FMV0FZ
Uy4KChEKCQQEAwQEAAIAARIElQEGIAoRCgkEBAMEBAACAAISBJUBIyQKdQoIBAQDBAQAAgES
BJkBBhsaYyBGaWVsZCBjYW4gb25seSBoYXZlIHN5c3RlbSBnZW5lcmF0ZWQgdmFsdWVzLiBV
c2VycyBjYW5ub3QgbWFudWFsbHkKIGluc2VydCB2YWx1ZXMgaW50byB0aGUgZmllbGQuCgoR
CgkEBAMEBAACAQESBJkBBhYKEQoJBAQDBAQAAgECEgSZARkaCmYKCAQEAwQEAAICEgSdAQYf
GlQgVXNlIHN5c3RlbSBnZW5lcmF0ZWQgdmFsdWVzIG9ubHkgaWYgdGhlIHVzZXIgZG9lcyBu
b3QgZXhwbGljaXRseQogcHJvdmlkZSBhIHZhbHVlLgoKEQoJBAQDBAQAAgIBEgSdAQYaChEK
CQQEAwQEAAICAhIEnQEdHgpkCgYEBAMEAgASBqIBBKMBMRpSIE9wdGlvbmFsLiBEaWN0YXRl
cyB3aGVuIHN5c3RlbSBnZW5lcmF0ZWQgdmFsdWVzIGFyZSB1c2VkIHRvIHBvcHVsYXRlIHRo
ZQogZmllbGQuCgoPCgcEBAMEAgAEEgSiAQQMCg8KBwQEAwQCAAYSBKIBDRoKDwoHBAQDBAIA
ARIEogEbKQoPCgcEBAMEAgADEgSiASwtCg8KBwQEAwQCAAgSBKMBCDAKEgoKBAQDBAIACJwI
ABIEowEJLwpDCgYEBAMECAASBqYBBKkBBRoxIENhcHR1cmVzIHRoZSBtZXRhZGF0YSBmb3Ig
dGhlIGdlbmVyYXRlZCBjb2x1bW4uCgoPCgcEBAMECAABEgSmAQoUCkoKBgQEAwQCARIEqAEG
PBo6IERlZmluaXRpb24gb2YgdGhlIGV4cHJlc3Npb24gdXNlZCB0byBnZW5lcmF0ZSB0aGUg
ZmllbGQuCgoPCgcEBAMEAgEGEgSoAQYdCg8KBwQEAwQCAQESBKgBHjcKDwoHBAQDBAIBAxIE
qAE6OwrQAQoEBAQCABIErwECOxrBASBSZXF1aXJlZC4gVGhlIGZpZWxkIG5hbWUuIFRoZSBu
YW1lIG11c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1aKSwKIG51bWJlcnMgKDAt
OSksIG9yIHVuZGVyc2NvcmVzIChfKSwgYW5kIG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBv
cgogdW5kZXJzY29yZS4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDMwMCBjaGFyYWN0ZXJzLgoK
DQoFBAQCAAUSBK8BAggKDQoFBAQCAAESBK8BCQ0KDQoFBAQCAAMSBK8BEBEKDQoFBAQCAAgS
BK8BEjoKEAoIBAQCAAicCAASBK8BEzkK3QIKBAQEAgESBMQBAjsazgIgUmVxdWlyZWQuIFRo
ZSBmaWVsZCBkYXRhIHR5cGUuIFBvc3NpYmxlIHZhbHVlcyBpbmNsdWRlOgoKICogU1RSSU5H
CiAqIEJZVEVTCiAqIElOVEVHRVIgKG9yIElOVDY0KQogKiBGTE9BVCAob3IgRkxPQVQ2NCkK
ICogQk9PTEVBTiAob3IgQk9PTCkKICogVElNRVNUQU1QCiAqIERBVEUKICogVElNRQogKiBE
QVRFVElNRQogKiBHRU9HUkFQSFkKICogTlVNRVJJQwogKiBCSUdOVU1FUklDCiAqIEpTT04K
ICogUkVDT1JEIChvciBTVFJVQ1QpCiAqIFJBTkdFCgogVXNlIG9mIFJFQ09SRC9TVFJVQ1Qg
aW5kaWNhdGVzIHRoYXQgdGhlIGZpZWxkIGNvbnRhaW5zIGEgbmVzdGVkIHNjaGVtYS4KCg0K
BQQEAgEFEgTEAQIICg0KBQQEAgEBEgTEAQkNCg0KBQQEAgEDEgTEARARCg0KBQQEAgEIEgTE
ARI6ChAKCAQEAgEInAgAEgTEARM5CoIBCgQEBAICEgTIAQI7GnQgT3B0aW9uYWwuIFRoZSBm
aWVsZCBtb2RlLiBQb3NzaWJsZSB2YWx1ZXMgaW5jbHVkZSBOVUxMQUJMRSwgUkVRVUlSRUQg
YW5kCiBSRVBFQVRFRC4gVGhlIGRlZmF1bHQgdmFsdWUgaXMgTlVMTEFCTEUuCgoNCgUEBAIC
BRIEyAECCAoNCgUEBAICARIEyAEJDQoNCgUEBAICAxIEyAEQEQoNCgUEBAICCBIEyAESOgoQ
CggEBAICCJwIABIEyAETOQpkCgQEBAIDEgTMAQJQGlYgT3B0aW9uYWwuIERlc2NyaWJlcyB0
aGUgbmVzdGVkIHNjaGVtYSBmaWVsZHMgaWYgdGhlIHR5cGUgcHJvcGVydHkgaXMgc2V0CiB0
byBSRUNPUkQuCgoNCgUEBAIDBBIEzAECCgoNCgUEBAIDBhIEzAELGwoNCgUEBAIDARIEzAEc
IgoNCgUEBAIDAxIEzAElJgoNCgUEBAIDCBIEzAEnTwoQCggEBAIDCJwIABIEzAEoTgpaCgQE
BAIEEgbPAQLQAS8aSiBPcHRpb25hbC4gVGhlIGZpZWxkIGRlc2NyaXB0aW9uLiBUaGUgbWF4
aW11bSBsZW5ndGggaXMgMSwwMjQgY2hhcmFjdGVycy4KCg0KBQQEAgQGEgTPAQIdCg0KBQQE
AgQBEgTPAR4pCg0KBQQEAgQDEgTPASwtCg0KBQQEAgQIEgTQAQYuChAKCAQEAgQInAgAEgTQ
AQctCpMBCgQEBAIFEgTUAQJJGoQBIE9wdGlvbmFsLiBUaGUgcG9saWN5IHRhZ3MgYXR0YWNo
ZWQgdG8gdGhpcyBmaWVsZCwgdXNlZCBmb3IgZmllbGQtbGV2ZWwKIGFjY2VzcyBjb250cm9s
LiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBlbXB0eSBwb2xpY3lfdGFncy4KCg0KBQQEAgUG
EgTUAQIPCg0KBQQEAgUBEgTUARAbCg0KBQQEAgUDEgTUAR4fCg0KBQQEAgUIEgTUASBIChAK
CAQEAgUInAgAEgTUASFHCrIHCgQEBAIGEgbmAQLnAS8aoQcgT3B0aW9uYWwuIFNwZWNpZmll
cyB0aGUgZGF0YSBnb3Zlcm5hbmNlIHRhZ3Mgb24gdGhpcyBmaWVsZC4gVGhpcyBmaWVsZAog
d29ya3Mgd2l0aCBvdGhlciBjb2x1bW4tbGV2ZWwgc2VjdXJpdHkgZmllbGRzIGFzIGZvbGxv
d3M6CgogKiAgICoqUHJlY2VkZW5jZSoqOiBJZiBhIGRhdGEgZ292ZXJuYW5jZSB0YWcgaXMg
YXR0YWNoZWQgdG8gYSBjb2x1bW4sIGl0CiAgICAgdGFrZXMgcHJlY2VkZW5jZSBvdmVyIHRo
ZSBwb2xpY3kgdGFnIGF0dGFjaGVkIHRvIHRoZSBjb2x1bW4uIEhvd2V2ZXIsCiAgICAgaWYg
YSBkYXRhIHBvbGljeSBpcyBhdHRhY2hlZCB0byBhIGNvbHVtbiwgaXQgdGFrZXMgcHJlY2Vk
ZW5jZSBvdmVyIHRoZQogICAgIGRhdGEgZ292ZXJuYW5jZSB0YWcuCiAqICAgKipQYXRjaGlu
ZyBiZWhhdmlvcioqOiBEZXNjcmliZXMgaG93IHRoaXMgZmllbGQgYmVoYXZlcyBkdXJpbmcg
YQogICAgIGBUYWJsZS5wYXRjaGAgc2NoZW1hIHVwZGF0ZToKICAgICAqICAgKipVbnNldCoq
OiBJZiB0aGUgYGRhdGFfZ292ZXJuYW5jZV90YWdzX2luZm9gIGZpZWxkIGlzIG9taXR0ZWQg
ZnJvbQogICAgICAgICB0aGUgdXBkYXRlIHJlcXVlc3QsIHRoZSBleGlzdGluZyB0YWdzIG9u
IHRoZSBjb2x1bW4gYXJlIHByZXNlcnZlZC4KICAgICAqICAgKipFbXB0eSBGaWVsZCoqOiBU
byBjbGVhciBkYXRhIGdvdmVybmFuY2UgdGFncyBmcm9tIGEgY29sdW1uLCBzZW5kCiAgICAg
ICAgIHRoZSBgZGF0YV9nb3Zlcm5hbmNlX3RhZ3NfaW5mb2AgZmllbGQgYXMgYW4gZW1wdHkg
b2JqZWN0LiBUaGlzCiAgICAgICAgIHJlbW92ZXMgYWxsIHRhZ3MgZnJvbSB0aGUgY29sdW1u
LgogICAgICogICAqKlVwZGF0aW5nIHRhZ3MqKjogVG8gcmVwbGFjZSBhbiBleGlzdGluZyB0
YWcsIHNlbmQgdGhlIGZpZWxkIHdpdGgKICAgICAgICAgdGhlIG5ldyB0YWcuCgoNCgUEBAIG
BhIE5gECGAoNCgUEBAIGARIE5gEZMgoNCgUEBAIGAxIE5gE1NwoNCgUEBAIGCBIE5wEGLgoQ
CggEBAIGCJwIABIE5wEHLQpnCgQEBAIHEgbrAQLsAS8aVyBPcHRpb25hbC4gRGF0YSBwb2xp
Y2llcyBhdHRhY2hlZCB0byB0aGlzIGZpZWxkLCB1c2VkIGZvciBmaWVsZC1sZXZlbCBhY2Nl
c3MKIGNvbnRyb2wuCgoNCgUEBAIHBBIE6wECCgoNCgUEBAIHBhIE6wELGwoNCgUEBAIHARIE
6wEcKQoNCgUEBAIHAxIE6wEsLgoNCgUEBAIHCBIE7AEGLgoQCggEBAIHCJwIABIE7AEHLQq5
AQoEBAQCCBIE8QECUBqqASBPcHRpb25hbC4gU3BlY2lmaWVzIGRhdGEgcG9saWNpZXMgYXR0
YWNoZWQgdG8gdGhpcyBmaWVsZCwgdXNlZCBmb3IKIGZpZWxkLWxldmVsIGFjY2VzcyBjb250
cm9sLiBXaGVuIHNldCwgdGhpcyB3aWxsIGJlIHRoZSBzb3VyY2Ugb2YgdHJ1dGggZm9yCiBk
YXRhIHBvbGljeSBpbmZvcm1hdGlvbi4KCg0KBQQEAggGEgTxAQIQCg0KBQQEAggBEgTxAREh
Cg0KBQQEAggDEgTxASQmCg0KBQQEAggIEgTxASdPChAKCAQEAggInAgAEgTxAShOCrwDCgQE
BAIJEgT/AQJBGq0DIE9wdGlvbmFsLiBNYXhpbXVtIGxlbmd0aCBvZiB2YWx1ZXMgb2YgdGhp
cyBmaWVsZCBmb3IgU1RSSU5HUyBvciBCWVRFUy4KCiBJZiBtYXhfbGVuZ3RoIGlzIG5vdCBz
cGVjaWZpZWQsIG5vIG1heGltdW0gbGVuZ3RoIGNvbnN0cmFpbnQgaXMgaW1wb3NlZAogb24g
dGhpcyBmaWVsZC4KCiBJZiB0eXBlID0gIlNUUklORyIsIHRoZW4gbWF4X2xlbmd0aCByZXBy
ZXNlbnRzIHRoZSBtYXhpbXVtIFVURi04CiBsZW5ndGggb2Ygc3RyaW5ncyBpbiB0aGlzIGZp
ZWxkLgoKIElmIHR5cGUgPSAiQllURVMiLCB0aGVuIG1heF9sZW5ndGggcmVwcmVzZW50cyB0
aGUgbWF4aW11bSBudW1iZXIgb2YKIGJ5dGVzIGluIHRoaXMgZmllbGQuCgogSXQgaXMgaW52
YWxpZCB0byBzZXQgdGhpcyBmaWVsZCBpZiB0eXBlICZuZTsgIlNUUklORyIgYW5kICZuZTsg
IkJZVEVTIi4KCg0KBQQEAgkFEgT/AQIHCg0KBQQEAgkBEgT/AQgSCg0KBQQEAgkDEgT/ARUX
Cg0KBQQEAgkIEgT/ARhAChAKCAQEAgkInAgAEgT/ARk/CrELCgQEBAIKEgSiAgJAGqILIE9w
dGlvbmFsLiBQcmVjaXNpb24gKG1heGltdW0gbnVtYmVyIG9mIHRvdGFsIGRpZ2l0cyBpbiBi
YXNlIDEwKSBhbmQgc2NhbGUKIChtYXhpbXVtIG51bWJlciBvZiBkaWdpdHMgaW4gdGhlIGZy
YWN0aW9uYWwgcGFydCBpbiBiYXNlIDEwKSBjb25zdHJhaW50cwogZm9yIHZhbHVlcyBvZiB0
aGlzIGZpZWxkIGZvciBOVU1FUklDIG9yIEJJR05VTUVSSUMuCgogSXQgaXMgaW52YWxpZCB0
byBzZXQgcHJlY2lzaW9uIG9yIHNjYWxlIGlmIHR5cGUgJm5lOyAiTlVNRVJJQyIgYW5kICZu
ZTsKICJCSUdOVU1FUklDIi4KCiBJZiBwcmVjaXNpb24gYW5kIHNjYWxlIGFyZSBub3Qgc3Bl
Y2lmaWVkLCBubyB2YWx1ZSByYW5nZSBjb25zdHJhaW50IGlzCiBpbXBvc2VkIG9uIHRoaXMg
ZmllbGQgaW5zb2ZhciBhcyB2YWx1ZXMgYXJlIHBlcm1pdHRlZCBieSB0aGUgdHlwZS4KCiBW
YWx1ZXMgb2YgdGhpcyBOVU1FUklDIG9yIEJJR05VTUVSSUMgZmllbGQgbXVzdCBiZSBpbiB0
aGlzIHJhbmdlIHdoZW46CgogKiBQcmVjaXNpb24gKDx2YXI+UDwvdmFyPikgYW5kIHNjYWxl
ICg8dmFyPlM8L3Zhcj4pIGFyZSBzcGVjaWZpZWQ6CiAgIFstMTA8c3VwPjx2YXI+UDwvdmFy
Pi08dmFyPlM8L3Zhcj48L3N1cD4gKyAxMDxzdXA+LTx2YXI+UzwvdmFyPjwvc3VwPiwKICAg
IDEwPHN1cD48dmFyPlA8L3Zhcj4tPHZhcj5TPC92YXI+PC9zdXA+IC0gMTA8c3VwPi08dmFy
PlM8L3Zhcj48L3N1cD5dCiAqIFByZWNpc2lvbiAoPHZhcj5QPC92YXI+KSBpcyBzcGVjaWZp
ZWQgYnV0IG5vdCBzY2FsZSAoYW5kIHRodXMgc2NhbGUgaXMKICAgaW50ZXJwcmV0ZWQgdG8g
YmUgZXF1YWwgdG8gemVybyk6CiAgIFstMTA8c3VwPjx2YXI+UDwvdmFyPjwvc3VwPiArIDEs
IDEwPHN1cD48dmFyPlA8L3Zhcj48L3N1cD4gLSAxXS4KCiBBY2NlcHRhYmxlIHZhbHVlcyBm
b3IgcHJlY2lzaW9uIGFuZCBzY2FsZSBpZiBib3RoIGFyZSBzcGVjaWZpZWQ6CgogKiBJZiB0
eXBlID0gIk5VTUVSSUMiOgogICAxICZsZTsgcHJlY2lzaW9uIC0gc2NhbGUgJmxlOyAyOSBh
bmQgMCAmbGU7IHNjYWxlICZsZTsgOS4KICogSWYgdHlwZSA9ICJCSUdOVU1FUklDIjoKICAg
MSAmbGU7IHByZWNpc2lvbiAtIHNjYWxlICZsZTsgMzggYW5kIDAgJmxlOyBzY2FsZSAmbGU7
IDM4LgoKIEFjY2VwdGFibGUgdmFsdWVzIGZvciBwcmVjaXNpb24gaWYgb25seSBwcmVjaXNp
b24gaXMgc3BlY2lmaWVkIGJ1dCBub3QKIHNjYWxlIChhbmQgdGh1cyBzY2FsZSBpcyBpbnRl
cnByZXRlZCB0byBiZSBlcXVhbCB0byB6ZXJvKToKCiAqIElmIHR5cGUgPSAiTlVNRVJJQyI6
IDEgJmxlOyBwcmVjaXNpb24gJmxlOyAyOS4KICogSWYgdHlwZSA9ICJCSUdOVU1FUklDIjog
MSAmbGU7IHByZWNpc2lvbiAmbGU7IDM4LgoKIElmIHNjYWxlIGlzIHNwZWNpZmllZCBidXQg
bm90IHByZWNpc2lvbiwgdGhlbiBpdCBpcyBpbnZhbGlkLgoKDQoFBAQCCgUSBKICAgcKDQoF
BAQCCgESBKICCBEKDQoFBAQCCgMSBKICFBYKDQoFBAQCCggSBKICFz8KEAoIBAQCCgicCAAS
BKICGD4KOgoEBAQCCxIEpQICPBosIE9wdGlvbmFsLiBTZWUgZG9jdW1lbnRhdGlvbiBmb3Ig
cHJlY2lzaW9uLgoKDQoFBAQCCwUSBKUCAgcKDQoFBAQCCwESBKUCCA0KDQoFBAQCCwMSBKUC
EBIKDQoFBAQCCwgSBKUCEzsKEAoIBAQCCwicCAASBKUCFDoKgAIKBAQEAgwSBq0CAq4CLxrv
ASBPcHRpb25hbC4gUHJlY2lzaW9uIChtYXhpbXVtIG51bWJlciBvZiB0b3RhbCBkaWdpdHMg
aW4gYmFzZSAxMCkgZm9yIHNlY29uZHMKIG9mIFRJTUVTVEFNUCB0eXBlLgoKIFBvc3NpYmxl
IHZhbHVlcyBpbmNsdWRlOgogKiA2IChEZWZhdWx0LCBmb3IgVElNRVNUQU1QIHR5cGUgd2l0
aCBtaWNyb3NlY29uZCBwcmVjaXNpb24pCiAqIDEyIChGb3IgVElNRVNUQU1QIHR5cGUgd2l0
aCBwaWNvc2Vjb25kIHByZWNpc2lvbikKCg0KBQQEAgwGEgStAgIcCg0KBQQEAgwBEgStAh0w
Cg0KBQQEAgwDEgStAjM1Cg0KBQQEAgwIEgSuAgYuChAKCAQEAgwInAgAEgSuAgctCnUKBAQE
Ag0SBLICAksaZyBPcHRpb25hbC4gU3BlY2lmaWVzIHRoZSByb3VuZGluZyBtb2RlIHRvIGJl
IHVzZWQgd2hlbiBzdG9yaW5nIHZhbHVlcyBvZgogTlVNRVJJQyBhbmQgQklHTlVNRVJJQyB0
eXBlLgoKDQoFBAQCDQYSBLICAg4KDQoFBAQCDQESBLICDxwKDQoFBAQCDQMSBLICHyEKDQoF
BAQCDQgSBLICIkoKEAoIBAQCDQicCAASBLICI0kK8QEKBAQEAg4SBrkCAroCLxrgASBPcHRp
b25hbC4gRmllbGQgY29sbGF0aW9uIGNhbiBiZSBzZXQgb25seSB3aGVuIHRoZSB0eXBlIG9m
IGZpZWxkIGlzIFNUUklORy4KIFRoZSBmb2xsb3dpbmcgdmFsdWVzIGFyZSBzdXBwb3J0ZWQ6
CgogKiAndW5kOmNpJzogdW5kZXRlcm1pbmVkIGxvY2FsZSwgY2FzZSBpbnNlbnNpdGl2ZS4K
ICogJyc6IGVtcHR5IHN0cmluZy4gRGVmYXVsdCB0byBjYXNlLXNlbnNpdGl2ZSBiZWhhdmlv
ci4KCg0KBQQEAg4GEgS5AgIdCg0KBQQEAg4BEgS5Ah4nCg0KBQQEAg4DEgS5AiosCg0KBQQE
Ag4IEgS6AgYuChAKCAQEAg4InAgAEgS6AgctCpUBCgQEBAIPEga+AgK/Ai8ahAEgT3B0aW9u
YWwuIEEgU1FMIGV4cHJlc3Npb24gdG8gc3BlY2lmeSB0aGUgW2RlZmF1bHQgdmFsdWVdCiAo
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvZGVmYXVsdC12YWx1ZXMp
IGZvciB0aGlzIGZpZWxkLgoKDQoFBAQCDwYSBL4CAh0KDQoFBAQCDwESBL4CHjYKDQoFBAQC
DwMSBL4COTsKDQoFBAQCDwgSBL8CBi4KEAoIBAQCDwicCAASBL8CBy0K5AEKBAQEAhASBsgC
AskCLxrTASBPcHRpb25hbC4gVGhlIHN1YnR5cGUgb2YgdGhlIFJBTkdFLCBpZiB0aGUgdHlw
ZSBvZiB0aGlzIGZpZWxkIGlzIFJBTkdFLiBJZgogdGhlIHR5cGUgaXMgUkFOR0UsIHRoaXMg
ZmllbGQgaXMgcmVxdWlyZWQuIFZhbHVlcyBmb3IgdGhlIGZpZWxkIGVsZW1lbnQKIHR5cGUg
Y2FuIGJlIHRoZSBmb2xsb3dpbmc6CgogKiBEQVRFCiAqIERBVEVUSU1FCiAqIFRJTUVTVEFN
UAoKDQoFBAQCEAYSBMgCAhIKDQoFBAQCEAESBMgCEyUKDQoFBAQCEAMSBMgCKCoKDQoFBAQC
EAgSBMkCBi4KEAoIBAQCEAicCAASBMkCBy0KrQEKBAQEAhESBM4CAk8angEgT3B0aW9uYWwu
IERlZmluaXRpb24gb2YgdGhlIGZvcmVpZ24gZGF0YSB0eXBlLgogT25seSB2YWxpZCBmb3Ig
dG9wLWxldmVsIHNjaGVtYSBmaWVsZHMgKG5vdCBuZXN0ZWQgZmllbGRzKS4KIElmIHRoZSB0
eXBlIGlzIEZPUkVJR04sIHRoaXMgZmllbGQgaXMgcmVxdWlyZWQuCgoNCgUEBAIRBRIEzgIC
CAoNCgUEBAIRARIEzgIJIAoNCgUEBAIRAxIEzgIjJQoNCgUEBAIRCBIEzgImTgoQCggEBAIR
CJwIABIEzgInTQqOAQoEBAQCEhIG0gIC0wIvGn4gT3B0aW9uYWwuIERlZmluaXRpb24gb2Yg
aG93IHZhbHVlcyBhcmUgZ2VuZXJhdGVkIGZvciB0aGUgZmllbGQuCiBPbmx5IHZhbGlkIGZv
ciB0b3AtbGV2ZWwgc2NoZW1hIGZpZWxkcyAobm90IG5lc3RlZCBmaWVsZHMpLgoKDQoFBAQC
EgYSBNICAhEKDQoFBAQCEgESBNICEiIKDQoFBAQCEgMSBNICJScKDQoFBAQCEggSBNMCBi4K
EAoIBAQCEgicCAASBNMCBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::TableSchema::TableSchema ===
    # Fields for TableSchema
    # Field: fields Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema)
    # Field: foreign_type_info Type: 11 (.google.cloud.bigquery.v2.ForeignTypeInfo)

# === Message: Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo ===
    # Fields for ForeignTypeInfo
    # Field: type_system Type: 14 (.google.cloud.bigquery.v2.ForeignTypeInfo.TypeSystem)

# Enum: ForeignTypeInfo::TypeSystem
our $ForeignTypeInfo_TYPE_SYSTEM_UNSPECIFIED = 0;
our $ForeignTypeInfo_HIVE = 1;

# === Message: Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption ===
    # Fields for DataPolicyOption
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList ===
    # Fields for DataPolicyList
    # Field: data_policies Type: 11 (.google.cloud.bigquery.v2.DataPolicyOption)

# === Message: Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema ===
    # Fields for TableFieldSchema
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: mode Type: 9 ()
    # Field: fields Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema)
    # Field: description Type: 11 (.google.protobuf.StringValue)
    # Field: policy_tags Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema.PolicyTagList)
    # Field: data_governance_tags_info Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema.DataGovernanceTagsInfo)
    # Field: data_policies Type: 11 (.google.cloud.bigquery.v2.DataPolicyOption)
    # Field: data_policy_list Type: 11 (.google.cloud.bigquery.v2.DataPolicyList)
    # Field: max_length Type: 3 ()
    # Field: precision Type: 3 ()
    # Field: scale Type: 3 ()
    # Field: timestamp_precision Type: 11 (.google.protobuf.Int64Value)
    # Field: rounding_mode Type: 14 (.google.cloud.bigquery.v2.TableFieldSchema.RoundingMode)
    # Field: collation Type: 11 (.google.protobuf.StringValue)
    # Field: default_value_expression Type: 11 (.google.protobuf.StringValue)
    # Field: range_element_type Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema.FieldElementType)
    # Field: foreign_type_definition Type: 9 ()
    # Field: generated_column Type: 11 (.google.cloud.bigquery.v2.TableFieldSchema.GeneratedColumn)

# Enum: TableFieldSchema::RoundingMode
our $TableFieldSchema_ROUNDING_MODE_UNSPECIFIED = 0;
our $TableFieldSchema_ROUND_HALF_AWAY_FROM_ZERO = 1;
our $TableFieldSchema_ROUND_HALF_EVEN = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::TableSchema - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/table_schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::TableSchema;

    my $msg = Google::Cloud::Bigquery::V2::TableSchema::TableSchema->new({
        fields => $fields,
        foreign_type_info => $foreign_type_info,
    });

    # Read or update a field
    my $val = $msg->fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::TableSchema::TableSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/table_schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::TableSchema::TableSchema

Schema of a table

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema>)

Describes the fields in a table.

=item * C<< $msg->foreign_type_info() >> / C<< $msg->foreign_type_info($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo>)

Optional. Specifies metadata of the foreign data type definition in field
schema
([TableFieldSchema.foreign_type_definition][google.cloud.bigquery.v2.TableFieldSchema.foreign_type_definition]).

=back

=head2 Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo

Metadata about the foreign data type definition such as the system
in which the type is defined.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type_system() >> / C<< $msg->type_system($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::ForeignTypeInfo::TypeSystem>)

Required. Specifies the system which defines the foreign data type.

=back

=head3 Enum: ForeignTypeInfo::TypeSystem

=over 4

=item * C<TYPE_SYSTEM_UNSPECIFIED> => C<0>

=item * C<HIVE> => C<1>

=back

=head2 Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption

Data policy option. For more information, see
[Mask data by applying data policies to a
column](https://docs.cloud.google.com/bigquery/docs/column-data-masking#data-policies-on-column).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Data policy resource name in the form of
projects/project_id/locations/location_id/dataPolicies/data_policy_id.

=back

=head2 Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList

A list of data policy options. For more information, see
[Mask data by applying data policies to a
column](https://docs.cloud.google.com/bigquery/docs/column-data-masking#data-policies-on-column).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption>)

Contains a list of data policy options. At most 9 data policies are
allowed per field.

=back

=head2 Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema

A field in TableSchema

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The field name. The name must contain only letters (a-z, A-Z),
numbers (0-9), or underscores (_), and must start with a letter or
underscore. The maximum length is 300 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The field data type. Possible values include:

* STRING
* BYTES
* INTEGER (or INT64)
* FLOAT (or FLOAT64)
* BOOLEAN (or BOOL)
* TIMESTAMP
* DATE
* TIME
* DATETIME
* GEOGRAPHY
* NUMERIC
* BIGNUMERIC
* JSON
* RECORD (or STRUCT)
* RANGE

Use of RECORD/STRUCT indicates that the field contains a nested schema.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

Optional. The field mode. Possible values include NULLABLE, REQUIRED and
REPEATED. The default value is NULLABLE.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema>)

Optional. Describes the nested schema fields if the type property is set
to RECORD.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

Optional. The field description. The maximum length is 1,024 characters.

=item * C<< $msg->policy_tags() >> / C<< $msg->policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::PolicyTagList>)

Optional. The policy tags attached to this field, used for field-level
access control. If not set, defaults to empty policy_tags.

=item * C<< $msg->data_governance_tags_info() >> / C<< $msg->data_governance_tags_info($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo>)

Optional. Specifies the data governance tags on this field. This field
works with other column-level security fields as follows:

*   B<Precedence>: If a data governance tag is attached to a column, it
    takes precedence over the policy tag attached to the column. However,
    if a data policy is attached to a column, it takes precedence over the
    data governance tag.
*   B<Patching behavior>: Describes how this field behaves during a
    `Table.patch` schema update:
    *   B<Unset>: If the `data_governance_tags_info` field is omitted from
        the update request, the existing tags on the column are preserved.
    *   B<Empty Field>: To clear data governance tags from a column, send
        the `data_governance_tags_info` field as an empty object. This
        removes all tags from the column.
    *   B<Updating tags>: To replace an existing tag, send the field with
        the new tag.

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption>)

Optional. Data policies attached to this field, used for field-level access
control.

=item * C<< $msg->data_policy_list() >> / C<< $msg->data_policy_list($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList>)

Optional. Specifies data policies attached to this field, used for
field-level access control. When set, this will be the source of truth for
data policy information.

=item * C<< $msg->max_length() >> / C<< $msg->max_length($value) >>

Type: C<Int64>

Optional. Maximum length of values of this field for STRINGS or BYTES.

If max_length is not specified, no maximum length constraint is imposed
on this field.

If type = "STRING", then max_length represents the maximum UTF-8
length of strings in this field.

If type = "BYTES", then max_length represents the maximum number of
bytes in this field.

It is invalid to set this field if type &ne; "STRING" and &ne; "BYTES".

=item * C<< $msg->precision() >> / C<< $msg->precision($value) >>

Type: C<Int64>

Optional. Precision (maximum number of total digits in base 10) and scale
(maximum number of digits in the fractional part in base 10) constraints
for values of this field for NUMERIC or BIGNUMERIC.

It is invalid to set precision or scale if type &ne; "NUMERIC" and &ne;
"BIGNUMERIC".

If precision and scale are not specified, no value range constraint is
imposed on this field insofar as values are permitted by the type.

Values of this NUMERIC or BIGNUMERIC field must be in this range when:

* Precision (<var>P</var>) and scale (<var>S</var>) are specified:
  [-10<sup><var>P</var>-<var>S</var></sup> + 10<sup>-<var>S</var></sup>,
   10<sup><var>P</var>-<var>S</var></sup> - 10<sup>-<var>S</var></sup>]
* Precision (<var>P</var>) is specified but not scale (and thus scale is
  interpreted to be equal to zero):
  [-10<sup><var>P</var></sup> + 1, 10<sup><var>P</var></sup> - 1].

Acceptable values for precision and scale if both are specified:

* If type = "NUMERIC":
  1 &le; precision - scale &le; 29 and 0 &le; scale &le; 9.
* If type = "BIGNUMERIC":
  1 &le; precision - scale &le; 38 and 0 &le; scale &le; 38.

Acceptable values for precision if only precision is specified but not
scale (and thus scale is interpreted to be equal to zero):

* If type = "NUMERIC": 1 &le; precision &le; 29.
* If type = "BIGNUMERIC": 1 &le; precision &le; 38.

If scale is specified but not precision, then it is invalid.

=item * C<< $msg->scale() >> / C<< $msg->scale($value) >>

Type: C<Int64>

Optional. See documentation for precision.

=item * C<< $msg->timestamp_precision() >> / C<< $msg->timestamp_precision($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int64Value>)

Optional. Precision (maximum number of total digits in base 10) for seconds
of TIMESTAMP type.

Possible values include:
* 6 (Default, for TIMESTAMP type with microsecond precision)
* 12 (For TIMESTAMP type with picosecond precision)

=item * C<< $msg->rounding_mode() >> / C<< $msg->rounding_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::TableFieldSchema::RoundingMode>)

Optional. Specifies the rounding mode to be used when storing values of
NUMERIC and BIGNUMERIC type.

=item * C<< $msg->collation() >> / C<< $msg->collation($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

Optional. Field collation can be set only when the type of field is STRING.
The following values are supported:

* 'und:ci': undetermined locale, case insensitive.
* '': empty string. Default to case-sensitive behavior.

=item * C<< $msg->default_value_expression() >> / C<< $msg->default_value_expression($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

Optional. A SQL expression to specify the [default value]
(https://cloud.google.com/bigquery/docs/default-values) for this field.

=item * C<< $msg->range_element_type() >> / C<< $msg->range_element_type($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::FieldElementType>)

Optional. The subtype of the RANGE, if the type of this field is RANGE. If
the type is RANGE, this field is required. Values for the field element
type can be the following:

* DATE
* DATETIME
* TIMESTAMP

=item * C<< $msg->foreign_type_definition() >> / C<< $msg->foreign_type_definition($value) >>

Type: C<String>

Optional. Definition of the foreign data type.
Only valid for top-level schema fields (not nested fields).
If the type is FOREIGN, this field is required.

=item * C<< $msg->generated_column() >> / C<< $msg->generated_column($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedColumn>)

Optional. Definition of how values are generated for the field.
Only valid for top-level schema fields (not nested fields).

=back

=head3 Enum: TableFieldSchema::RoundingMode

=over 4

=item * C<ROUNDING_MODE_UNSPECIFIED> => C<0>

=item * C<ROUND_HALF_AWAY_FROM_ZERO> => C<1>

=item * C<ROUND_HALF_EVEN> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::TableSchema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
