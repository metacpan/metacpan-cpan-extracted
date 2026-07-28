package Google::Longrunning::Operations;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Descriptor };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxISZ29vZ2xlLmxvbmdydW5u
aW5nGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5w
cm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL3Byb3RvYnVm
L2FueS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2Rlc2NyaXB0b3IucHJvdG8aHmdvb2dsZS9w
cm90b2J1Zi9kdXJhdGlvbi5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGhdn
b29nbGUvcnBjL3N0YXR1cy5wcm90byLPAQoJT3BlcmF0aW9uEhIKBG5hbWUYASABKAlSBG5h
bWUSMAoIbWV0YWRhdGEYAiABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UghtZXRhZGF0YRIS
CgRkb25lGAMgASgIUgRkb25lEioKBWVycm9yGAQgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNI
AFIFZXJyb3ISMgoIcmVzcG9uc2UYBSABKAsyFC5nb29nbGUucHJvdG9idWYuQW55SABSCHJl
c3BvbnNlQggKBnJlc3VsdCIpChNHZXRPcGVyYXRpb25SZXF1ZXN0EhIKBG5hbWUYASABKAlS
BG5hbWUitQEKFUxpc3RPcGVyYXRpb25zUmVxdWVzdBISCgRuYW1lGAQgASgJUgRuYW1lEhYK
BmZpbHRlchgBIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEjQKFnJldHVybl9wYXJ0aWFsX3N1Y2Nlc3MY
BSABKAhSFHJldHVyblBhcnRpYWxTdWNjZXNzIqYBChZMaXN0T3BlcmF0aW9uc1Jlc3BvbnNl
Ej0KCm9wZXJhdGlvbnMYASADKAsyHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uUgpv
cGVyYXRpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIlCgt1
bnJlYWNoYWJsZRgDIAMoCUID4EEGUgt1bnJlYWNoYWJsZSIsChZDYW5jZWxPcGVyYXRpb25S
ZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUiLAoWRGVsZXRlT3BlcmF0aW9uUmVxdWVzdBIS
CgRuYW1lGAEgASgJUgRuYW1lIl8KFFdhaXRPcGVyYXRpb25SZXF1ZXN0EhIKBG5hbWUYASAB
KAlSBG5hbWUSMwoHdGltZW91dBgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIH
dGltZW91dCJZCg1PcGVyYXRpb25JbmZvEiMKDXJlc3BvbnNlX3R5cGUYASABKAlSDHJlc3Bv
bnNlVHlwZRIjCg1tZXRhZGF0YV90eXBlGAIgASgJUgxtZXRhZGF0YVR5cGUyqgUKCk9wZXJh
dGlvbnMSlAEKDkxpc3RPcGVyYXRpb25zEikuZ29vZ2xlLmxvbmdydW5uaW5nLkxpc3RPcGVy
YXRpb25zUmVxdWVzdBoqLmdvb2dsZS5sb25ncnVubmluZy5MaXN0T3BlcmF0aW9uc1Jlc3Bv
bnNlIiuC0+STAhcSFS92MS97bmFtZT1vcGVyYXRpb25zfdpBC25hbWUsZmlsdGVyEn8KDEdl
dE9wZXJhdGlvbhInLmdvb2dsZS5sb25ncnVubmluZy5HZXRPcGVyYXRpb25SZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiIngtPkkwIaEhgvdjEve25hbWU9b3BlcmF0
aW9ucy8qKn3aQQRuYW1lEn4KD0RlbGV0ZU9wZXJhdGlvbhIqLmdvb2dsZS5sb25ncnVubmlu
Zy5EZWxldGVPcGVyYXRpb25SZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IieC0+ST
AhoqGC92MS97bmFtZT1vcGVyYXRpb25zLyoqfdpBBG5hbWUSiAEKD0NhbmNlbE9wZXJhdGlv
bhIqLmdvb2dsZS5sb25ncnVubmluZy5DYW5jZWxPcGVyYXRpb25SZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IjGC0+STAiQiHy92MS97bmFtZT1vcGVyYXRpb25zLyoqfTpjYW5j
ZWw6ASraQQRuYW1lEloKDVdhaXRPcGVyYXRpb24SKC5nb29nbGUubG9uZ3J1bm5pbmcuV2Fp
dE9wZXJhdGlvblJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIgAaHcpB
GmxvbmdydW5uaW5nLmdvb2dsZWFwaXMuY29tOmkKDm9wZXJhdGlvbl9pbmZvEh4uZ29vZ2xl
LnByb3RvYnVmLk1ldGhvZE9wdGlvbnMYmQggASgLMiEuZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbkluZm9SDW9wZXJhdGlvbkluZm9CogEKFmNvbS5nb29nbGUubG9uZ3J1bm5pbmdC
D09wZXJhdGlvbnNQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2xvbmdydW5uaW5nL2F1
dG9nZW4vbG9uZ3J1bm5pbmdwYjtsb25ncnVubmluZ3BiogIFR0xSVU6qAhJHb29nbGUuTG9u
Z1J1bm5pbmfKAhJHb29nbGVcTG9uZ1J1bm5pbmdK7E8KBxIFDgCIAgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABsKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAqCgkKAgMFEgMXACgKCQoCAwYSAxgA
JQoJCgIDBxIDGQAhCggKAQgSAxsALwoJCgIIJRIDGwAvCggKAQgSAxwAWgoJCgIICxIDHABa
CggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AMAoJCgIICBIDHgAwCggKAQgSAx8ALwoJ
CgIIARIDHwAvCggKAQgSAyAAIwoJCgIIJBIDIAAjCggKAQgSAyEALQoJCgIIKRIDIQAtCgkK
AQcSBCMAKwEK+AEKAgcAEgMqAjka7AEgQWRkaXRpb25hbCBpbmZvcm1hdGlvbiByZWdhcmRp
bmcgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbnMuCiBJbiBwYXJ0aWN1bGFyLCB0aGlzIHNwZWNp
ZmllcyB0aGUgdHlwZXMgdGhhdCBhcmUgcmV0dXJuZWQgZnJvbQogbG9uZy1ydW5uaW5nIG9w
ZXJhdGlvbnMuCgogUmVxdWlyZWQgZm9yIG1ldGhvZHMgdGhhdCByZXR1cm4gYGdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25gOyBpbnZhbGlkCiBvdGhlcndpc2UuCgoKCgMHAAISAyMH
JAoKCgMHAAYSAyoCIgoKCgMHAAESAyojMQoKCgMHAAMSAyo0OArFBAoCBgASBDYAdAEauAQg
TWFuYWdlcyBsb25nLXJ1bm5pbmcgb3BlcmF0aW9ucyB3aXRoIGFuIEFQSSBzZXJ2aWNlLgoK
IFdoZW4gYW4gQVBJIG1ldGhvZCBub3JtYWxseSB0YWtlcyBsb25nIHRpbWUgdG8gY29tcGxl
dGUsIGl0IGNhbiBiZSBkZXNpZ25lZAogdG8gcmV0dXJuIFtPcGVyYXRpb25dW2dvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25dIHRvIHRoZSBjbGllbnQsIGFuZCB0aGUKIGNsaWVudCBj
YW4gdXNlIHRoaXMgaW50ZXJmYWNlIHRvIHJlY2VpdmUgdGhlIHJlYWwgcmVzcG9uc2UgYXN5
bmNocm9ub3VzbHkgYnkKIHBvbGxpbmcgdGhlIG9wZXJhdGlvbiByZXNvdXJjZSwgb3IgcGFz
cyB0aGUgb3BlcmF0aW9uIHJlc291cmNlIHRvIGFub3RoZXIgQVBJCiAoc3VjaCBhcyBQdWIv
U3ViIEFQSSkgdG8gcmVjZWl2ZSB0aGUgcmVzcG9uc2UuICBBbnkgQVBJIHNlcnZpY2UgdGhh
dCByZXR1cm5zCiBsb25nLXJ1bm5pbmcgb3BlcmF0aW9ucyBzaG91bGQgaW1wbGVtZW50IHRo
ZSBgT3BlcmF0aW9uc2AgaW50ZXJmYWNlIHNvCiBkZXZlbG9wZXJzIGNhbiBoYXZlIGEgY29u
c2lzdGVudCBjbGllbnQgZXhwZXJpZW5jZS4KCgoKAwYAARIDNggSCgoKAwYAAxIDNwJCCgwK
BQYAA5kIEgM3AkIKmQEKBAYAAgASBDsCQAMaigEgTGlzdHMgb3BlcmF0aW9ucyB0aGF0IG1h
dGNoIHRoZSBzcGVjaWZpZWQgZmlsdGVyIGluIHRoZSByZXF1ZXN0LiBJZiB0aGUKIHNlcnZl
ciBkb2Vzbid0IHN1cHBvcnQgdGhpcyBtZXRob2QsIGl0IHJldHVybnMgYFVOSU1QTEVNRU5U
RURgLgoKDAoFBgACAAESAzsGFAoMCgUGAAIAAhIDOxUqCgwKBQYAAgADEgM7NUsKDQoFBgAC
AAQSBDwEPgYKEQoJBgACAASwyrwiEgQ8BD4GCgwKBQYAAgAEEgM/BDkKDwoIBgACAASbCAAS
Az8EOQqvAQoEBgACARIERQJKAxqgASBHZXRzIHRoZSBsYXRlc3Qgc3RhdGUgb2YgYSBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uLiAgQ2xpZW50cyBjYW4gdXNlIHRoaXMKIG1ldGhvZCB0byBw
b2xsIHRoZSBvcGVyYXRpb24gcmVzdWx0IGF0IGludGVydmFscyBhcyByZWNvbW1lbmRlZCBi
eSB0aGUgQVBJCiBzZXJ2aWNlLgoKDAoFBgACAQESA0UGEgoMCgUGAAIBAhIDRRMmCgwKBQYA
AgEDEgNFMToKDQoFBgACAQQSBEYESAYKEQoJBgACAQSwyrwiEgRGBEgGCgwKBQYAAgEEEgNJ
BDIKDwoIBgACAQSbCAASA0kEMgqFAgoEBgACAhIEUAJVAxr2ASBEZWxldGVzIGEgbG9uZy1y
dW5uaW5nIG9wZXJhdGlvbi4gVGhpcyBtZXRob2QgaW5kaWNhdGVzIHRoYXQgdGhlIGNsaWVu
dCBpcwogbm8gbG9uZ2VyIGludGVyZXN0ZWQgaW4gdGhlIG9wZXJhdGlvbiByZXN1bHQuIEl0
IGRvZXMgbm90IGNhbmNlbCB0aGUKIG9wZXJhdGlvbi4gSWYgdGhlIHNlcnZlciBkb2Vzbid0
IHN1cHBvcnQgdGhpcyBtZXRob2QsIGl0IHJldHVybnMKIGBnb29nbGUucnBjLkNvZGUuVU5J
TVBMRU1FTlRFRGAuCgoMCgUGAAICARIDUAYVCgwKBQYAAgICEgNQFiwKDAoFBgACAgMSA1A3
TAoNCgUGAAICBBIEUQRTBgoRCgkGAAICBLDKvCISBFEEUwYKDAoFBgACAgQSA1QEMgoPCggG
AAICBJsIABIDVAQyCtcFCgQGAAIDEgRiAmgDGsgFIFN0YXJ0cyBhc3luY2hyb25vdXMgY2Fu
Y2VsbGF0aW9uIG9uIGEgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4gIFRoZSBzZXJ2ZXIKIG1h
a2VzIGEgYmVzdCBlZmZvcnQgdG8gY2FuY2VsIHRoZSBvcGVyYXRpb24sIGJ1dCBzdWNjZXNz
IGlzIG5vdAogZ3VhcmFudGVlZC4gIElmIHRoZSBzZXJ2ZXIgZG9lc24ndCBzdXBwb3J0IHRo
aXMgbWV0aG9kLCBpdCByZXR1cm5zCiBgZ29vZ2xlLnJwYy5Db2RlLlVOSU1QTEVNRU5URURg
LiAgQ2xpZW50cyBjYW4gdXNlCiBbT3BlcmF0aW9ucy5HZXRPcGVyYXRpb25dW2dvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25zLkdldE9wZXJhdGlvbl0gb3IKIG90aGVyIG1ldGhvZHMg
dG8gY2hlY2sgd2hldGhlciB0aGUgY2FuY2VsbGF0aW9uIHN1Y2NlZWRlZCBvciB3aGV0aGVy
IHRoZQogb3BlcmF0aW9uIGNvbXBsZXRlZCBkZXNwaXRlIGNhbmNlbGxhdGlvbi4gT24gc3Vj
Y2Vzc2Z1bCBjYW5jZWxsYXRpb24sCiB0aGUgb3BlcmF0aW9uIGlzIG5vdCBkZWxldGVkOyBp
bnN0ZWFkLCBpdCBiZWNvbWVzIGFuIG9wZXJhdGlvbiB3aXRoCiBhbiBbT3BlcmF0aW9uLmVy
cm9yXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXSB2YWx1ZSB3aXRoIGEK
IFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiBg
MWAsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoMCgUGAAIDARIDYgYV
CgwKBQYAAgMCEgNiFiwKDAoFBgACAwMSA2I3TAoNCgUGAAIDBBIEYwRmBgoRCgkGAAIDBLDK
vCISBGMEZgYKDAoFBgACAwQSA2cEMgoPCggGAAIDBJsIABIDZwQyCvYECgQGAAIEEgNzAkAa
6AQgV2FpdHMgdW50aWwgdGhlIHNwZWNpZmllZCBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uIGlz
IGRvbmUgb3IgcmVhY2hlcyBhdCBtb3N0CiBhIHNwZWNpZmllZCB0aW1lb3V0LCByZXR1cm5p
bmcgdGhlIGxhdGVzdCBzdGF0ZS4gIElmIHRoZSBvcGVyYXRpb24gaXMKIGFscmVhZHkgZG9u
ZSwgdGhlIGxhdGVzdCBzdGF0ZSBpcyBpbW1lZGlhdGVseSByZXR1cm5lZC4gIElmIHRoZSB0
aW1lb3V0CiBzcGVjaWZpZWQgaXMgZ3JlYXRlciB0aGFuIHRoZSBkZWZhdWx0IEhUVFAvUlBD
IHRpbWVvdXQsIHRoZSBIVFRQL1JQQwogdGltZW91dCBpcyB1c2VkLiAgSWYgdGhlIHNlcnZl
ciBkb2VzIG5vdCBzdXBwb3J0IHRoaXMgbWV0aG9kLCBpdCByZXR1cm5zCiBgZ29vZ2xlLnJw
Yy5Db2RlLlVOSU1QTEVNRU5URURgLgogTm90ZSB0aGF0IHRoaXMgbWV0aG9kIGlzIG9uIGEg
YmVzdC1lZmZvcnQgYmFzaXMuICBJdCBtYXkgcmV0dXJuIHRoZSBsYXRlc3QKIHN0YXRlIGJl
Zm9yZSB0aGUgc3BlY2lmaWVkIHRpbWVvdXQgKGluY2x1ZGluZyBpbW1lZGlhdGVseSksIG1l
YW5pbmcgZXZlbiBhbgogaW1tZWRpYXRlIHJlc3BvbnNlIGlzIG5vIGd1YXJhbnRlZSB0aGF0
IHRoZSBvcGVyYXRpb24gaXMgZG9uZS4KCgwKBQYAAgQBEgNzBhMKDAoFBgACBAISA3MUKAoM
CgUGAAIEAxIDczM8CmsKAgQAEgV4AJsBARpeIFRoaXMgcmVzb3VyY2UgcmVwcmVzZW50cyBh
IGxvbmctcnVubmluZyBvcGVyYXRpb24gdGhhdCBpcyB0aGUgcmVzdWx0IG9mIGEKIG5ldHdv
cmsgQVBJIGNhbGwuCgoKCgMEAAESA3gIEQrkAQoEBAACABIDfAISGtYBIFRoZSBzZXJ2ZXIt
YXNzaWduZWQgbmFtZSwgd2hpY2ggaXMgb25seSB1bmlxdWUgd2l0aGluIHRoZSBzYW1lIHNl
cnZpY2UgdGhhdAogb3JpZ2luYWxseSByZXR1cm5zIGl0LiBJZiB5b3UgdXNlIHRoZSBkZWZh
dWx0IEhUVFAgbWFwcGluZywgdGhlCiBgbmFtZWAgc2hvdWxkIGJlIGEgcmVzb3VyY2UgbmFt
ZSBlbmRpbmcgd2l0aCBgb3BlcmF0aW9ucy97dW5pcXVlX2lkfWAuCgoMCgUEAAIABRIDfAII
CgwKBQQAAgABEgN8CQ0KDAoFBAACAAMSA3wQEQqtAgoEBAACARIEggECIxqeAiBTZXJ2aWNl
LXNwZWNpZmljIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgb3BlcmF0aW9uLiAgSXQg
dHlwaWNhbGx5CiBjb250YWlucyBwcm9ncmVzcyBpbmZvcm1hdGlvbiBhbmQgY29tbW9uIG1l
dGFkYXRhIHN1Y2ggYXMgY3JlYXRlIHRpbWUuCiBTb21lIHNlcnZpY2VzIG1pZ2h0IG5vdCBw
cm92aWRlIHN1Y2ggbWV0YWRhdGEuICBBbnkgbWV0aG9kIHRoYXQgcmV0dXJucyBhCiBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uIHNob3VsZCBkb2N1bWVudCB0aGUgbWV0YWRhdGEgdHlwZSwg
aWYgYW55LgoKDQoFBAACAQYSBIIBAhUKDQoFBAACAQESBIIBFh4KDQoFBAACAQMSBIIBISIK
rgEKBAQAAgISBIcBAhAanwEgSWYgdGhlIHZhbHVlIGlzIGBmYWxzZWAsIGl0IG1lYW5zIHRo
ZSBvcGVyYXRpb24gaXMgc3RpbGwgaW4gcHJvZ3Jlc3MuCiBJZiBgdHJ1ZWAsIHRoZSBvcGVy
YXRpb24gaXMgY29tcGxldGVkLCBhbmQgZWl0aGVyIGBlcnJvcmAgb3IgYHJlc3BvbnNlYCBp
cwogYXZhaWxhYmxlLgoKDQoFBAACAgUSBIcBAgYKDQoFBAACAgESBIcBBwsKDQoFBAACAgMS
BIcBDg8KkAIKBAQACAASBo0BApoBAxr/ASBUaGUgb3BlcmF0aW9uIHJlc3VsdCwgd2hpY2gg
Y2FuIGJlIGVpdGhlciBhbiBgZXJyb3JgIG9yIGEgdmFsaWQgYHJlc3BvbnNlYC4KIElmIGBk
b25lYCA9PSBgZmFsc2VgLCBuZWl0aGVyIGBlcnJvcmAgbm9yIGByZXNwb25zZWAgaXMgc2V0
LgogSWYgYGRvbmVgID09IGB0cnVlYCwgZXhhY3RseSBvbmUgb2YgYGVycm9yYCBvciBgcmVz
cG9uc2VgIGNhbiBiZSBzZXQuCiBTb21lIHNlcnZpY2VzIG1pZ2h0IG5vdCBwcm92aWRlIHRo
ZSByZXN1bHQuCgoNCgUEAAgAARIEjQEIDgpVCgQEAAIDEgSPAQQgGkcgVGhlIGVycm9yIHJl
c3VsdCBvZiB0aGUgb3BlcmF0aW9uIGluIGNhc2Ugb2YgZmFpbHVyZSBvciBjYW5jZWxsYXRp
b24uCgoNCgUEAAIDBhIEjwEEFQoNCgUEAAIDARIEjwEWGwoNCgUEAAIDAxIEjwEeHwr9AwoE
BAACBBIEmQEEJRruAyBUaGUgbm9ybWFsLCBzdWNjZXNzZnVsIHJlc3BvbnNlIG9mIHRoZSBv
cGVyYXRpb24uICBJZiB0aGUgb3JpZ2luYWwKIG1ldGhvZCByZXR1cm5zIG5vIGRhdGEgb24g
c3VjY2Vzcywgc3VjaCBhcyBgRGVsZXRlYCwgdGhlIHJlc3BvbnNlIGlzCiBgZ29vZ2xlLnBy
b3RvYnVmLkVtcHR5YC4gIElmIHRoZSBvcmlnaW5hbCBtZXRob2QgaXMgc3RhbmRhcmQKIGBH
ZXRgL2BDcmVhdGVgL2BVcGRhdGVgLCB0aGUgcmVzcG9uc2Ugc2hvdWxkIGJlIHRoZSByZXNv
dXJjZS4gIEZvciBvdGhlcgogbWV0aG9kcywgdGhlIHJlc3BvbnNlIHNob3VsZCBoYXZlIHRo
ZSB0eXBlIGBYeHhSZXNwb25zZWAsIHdoZXJlIGBYeHhgCiBpcyB0aGUgb3JpZ2luYWwgbWV0
aG9kIG5hbWUuICBGb3IgZXhhbXBsZSwgaWYgdGhlIG9yaWdpbmFsIG1ldGhvZCBuYW1lCiBp
cyBgVGFrZVNuYXBzaG90KClgLCB0aGUgaW5mZXJyZWQgcmVzcG9uc2UgdHlwZSBpcwogYFRh
a2VTbmFwc2hvdFJlc3BvbnNlYC4KCg0KBQQAAgQGEgSZAQQXCg0KBQQAAgQBEgSZARggCg0K
BQQAAgQDEgSZASMkCm8KAgQBEgafAQCiAQEaYSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgog
W09wZXJhdGlvbnMuR2V0T3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
cy5HZXRPcGVyYXRpb25dLgoKCwoDBAEBEgSfAQgbCjMKBAQBAgASBKEBAhIaJSBUaGUgbmFt
ZSBvZiB0aGUgb3BlcmF0aW9uIHJlc291cmNlLgoKDQoFBAECAAUSBKEBAggKDQoFBAECAAES
BKEBCQ0KDQoFBAECAAMSBKEBEBEKcwoCBAISBqYBAL4BARplIFRoZSByZXF1ZXN0IG1lc3Nh
Z2UgZm9yCiBbT3BlcmF0aW9ucy5MaXN0T3BlcmF0aW9uc11bZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbnMuTGlzdE9wZXJhdGlvbnNdLgoKCwoDBAIBEgSmAQgdCjwKBAQCAgASBKgB
AhIaLiBUaGUgbmFtZSBvZiB0aGUgb3BlcmF0aW9uJ3MgcGFyZW50IHJlc291cmNlLgoKDQoF
BAICAAUSBKgBAggKDQoFBAICAAESBKgBCQ0KDQoFBAICAAMSBKgBEBEKKQoEBAICARIEqwEC
FBobIFRoZSBzdGFuZGFyZCBsaXN0IGZpbHRlci4KCg0KBQQCAgEFEgSrAQIICg0KBQQCAgEB
EgSrAQkPCg0KBQQCAgEDEgSrARITCiwKBAQCAgISBK4BAhYaHiBUaGUgc3RhbmRhcmQgbGlz
dCBwYWdlIHNpemUuCgoNCgUEAgICBRIErgECBwoNCgUEAgICARIErgEIEQoNCgUEAgICAxIE
rgEUFQotCgQEAgIDEgSxAQIYGh8gVGhlIHN0YW5kYXJkIGxpc3QgcGFnZSB0b2tlbi4KCg0K
BQQCAgMFEgSxAQIICg0KBQQCAgMBEgSxAQkTCg0KBQQCAgMDEgSxARYXCugDCgQEAgIEEgS9
AQIiGtkDIFdoZW4gc2V0IHRvIGB0cnVlYCwgb3BlcmF0aW9ucyB0aGF0IGFyZSByZWFjaGFi
bGUgYXJlIHJldHVybmVkIGFzIG5vcm1hbCwKIGFuZCB0aG9zZSB0aGF0IGFyZSB1bnJlYWNo
YWJsZSBhcmUgcmV0dXJuZWQgaW4gdGhlCiBbTGlzdE9wZXJhdGlvbnNSZXNwb25zZS51bnJl
YWNoYWJsZV0gZmllbGQuCgogVGhpcyBjYW4gb25seSBiZSBgdHJ1ZWAgd2hlbiByZWFkaW5n
IGFjcm9zcyBjb2xsZWN0aW9ucyBlLmcuIHdoZW4gYHBhcmVudGAKIGlzIHNldCB0byBgInBy
b2plY3RzL2V4YW1wbGUvbG9jYXRpb25zLy0iYC4KCiBUaGlzIGZpZWxkIGlzIG5vdCBieSBk
ZWZhdWx0IHN1cHBvcnRlZCBhbmQgd2lsbCByZXN1bHQgaW4gYW4KIGBVTklNUExFTUVOVEVE
YCBlcnJvciBpZiBzZXQgdW5sZXNzIGV4cGxpY2l0bHkgZG9jdW1lbnRlZCBvdGhlcndpc2Ug
aW4KIHNlcnZpY2Ugb3IgcHJvZHVjdCBzcGVjaWZpYyBkb2N1bWVudGF0aW9uLgoKDQoFBAIC
BAUSBL0BAgYKDQoFBAICBAESBL0BBx0KDQoFBAICBAMSBL0BICEKdAoCBAMSBsIBAM8BARpm
IFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgogW09wZXJhdGlvbnMuTGlzdE9wZXJhdGlvbnNd
W2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLkxpc3RPcGVyYXRpb25zXS4KCgsKAwQD
ARIEwgEIHgpWCgQEAwIAEgTEAQIkGkggQSBsaXN0IG9mIG9wZXJhdGlvbnMgdGhhdCBtYXRj
aGVzIHRoZSBzcGVjaWZpZWQgZmlsdGVyIGluIHRoZSByZXF1ZXN0LgoKDQoFBAMCAAQSBMQB
AgoKDQoFBAMCAAYSBMQBCxQKDQoFBAMCAAESBMQBFR8KDQoFBAMCAAMSBMQBIiMKMgoEBAMC
ARIExwECHRokIFRoZSBzdGFuZGFyZCBMaXN0IG5leHQtcGFnZSB0b2tlbi4KCg0KBQQDAgEF
EgTHAQIICg0KBQQDAgEBEgTHAQkYCg0KBQQDAgEDEgTHARscCvMBCgQEAwICEgbNAQLOATUa
4gEgVW5vcmRlcmVkIGxpc3QuIFVucmVhY2hhYmxlIHJlc291cmNlcy4gUG9wdWxhdGVkIHdo
ZW4gdGhlIHJlcXVlc3Qgc2V0cwogYExpc3RPcGVyYXRpb25zUmVxdWVzdC5yZXR1cm5fcGFy
dGlhbF9zdWNjZXNzYCBhbmQgcmVhZHMgYWNyb3NzCiBjb2xsZWN0aW9ucyBlLmcuIHdoZW4g
YXR0ZW1wdGluZyB0byBsaXN0IGFsbCByZXNvdXJjZXMgYWNyb3NzIGFsbCBzdXBwb3J0ZWQK
IGxvY2F0aW9ucy4KCg0KBQQDAgIEEgTNAQIKCg0KBQQDAgIFEgTNAQsRCg0KBQQDAgIBEgTN
ARIdCg0KBQQDAgIDEgTNASAhCg0KBQQDAgIIEgTOAQY0ChAKCAQDAgIInAgAEgTOAQczCnUK
AgQEEgbTAQDWAQEaZyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW09wZXJhdGlvbnMuQ2Fu
Y2VsT3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5DYW5jZWxPcGVy
YXRpb25dLgoKCwoDBAQBEgTTAQgeCkMKBAQEAgASBNUBAhIaNSBUaGUgbmFtZSBvZiB0aGUg
b3BlcmF0aW9uIHJlc291cmNlIHRvIGJlIGNhbmNlbGxlZC4KCg0KBQQEAgAFEgTVAQIICg0K
BQQEAgABEgTVAQkNCg0KBQQEAgADEgTVARARCnUKAgQFEgbaAQDdAQEaZyBUaGUgcmVxdWVz
dCBtZXNzYWdlIGZvcgogW09wZXJhdGlvbnMuRGVsZXRlT3BlcmF0aW9uXVtnb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9ucy5EZWxldGVPcGVyYXRpb25dLgoKCwoDBAUBEgTaAQgeCkEK
BAQFAgASBNwBAhIaMyBUaGUgbmFtZSBvZiB0aGUgb3BlcmF0aW9uIHJlc291cmNlIHRvIGJl
IGRlbGV0ZWQuCgoNCgUEBQIABRIE3AECCAoNCgUEBQIAARIE3AEJDQoNCgUEBQIAAxIE3AEQ
EQpxCgIEBhIG4QEA6QEBGmMgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtPcGVyYXRpb25z
LldhaXRPcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLldhaXRPcGVy
YXRpb25dLgoKCwoDBAYBEgThAQgcCj4KBAQGAgASBOMBAhIaMCBUaGUgbmFtZSBvZiB0aGUg
b3BlcmF0aW9uIHJlc291cmNlIHRvIHdhaXQgb24uCgoNCgUEBgIABRIE4wECCAoNCgUEBgIA
ARIE4wEJDQoNCgUEBgIAAxIE4wEQEQrrAQoEBAYCARIE6AECJxrcASBUaGUgbWF4aW11bSBk
dXJhdGlvbiB0byB3YWl0IGJlZm9yZSB0aW1pbmcgb3V0LiBJZiBsZWZ0IGJsYW5rLCB0aGUg
d2FpdAogd2lsbCBiZSBhdCBtb3N0IHRoZSB0aW1lIHBlcm1pdHRlZCBieSB0aGUgdW5kZXJs
eWluZyBIVFRQL1JQQyBwcm90b2NvbC4KIElmIFJQQyBjb250ZXh0IGRlYWRsaW5lIGlzIGFs
c28gc3BlY2lmaWVkLCB0aGUgc2hvcnRlciBvbmUgd2lsbCBiZSB1c2VkLgoKDQoFBAYCAQYS
BOgBAhoKDQoFBAYCAQESBOgBGyIKDQoFBAYCAQMSBOgBJSYKyAIKAgQHEgb1AQCIAgEauQIg
QSBtZXNzYWdlIHJlcHJlc2VudGluZyB0aGUgbWVzc2FnZSB0eXBlcyB1c2VkIGJ5IGEgbG9u
Zy1ydW5uaW5nIG9wZXJhdGlvbi4KCiBFeGFtcGxlOgoKICAgICBycGMgRXhwb3J0KEV4cG9y
dFJlcXVlc3QpIHJldHVybnMgKGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24pIHsKICAg
ICAgIG9wdGlvbiAoZ29vZ2xlLmxvbmdydW5uaW5nLm9wZXJhdGlvbl9pbmZvKSA9IHsKICAg
ICAgICAgcmVzcG9uc2VfdHlwZTogIkV4cG9ydFJlc3BvbnNlIgogICAgICAgICBtZXRhZGF0
YV90eXBlOiAiRXhwb3J0TWV0YWRhdGEiCiAgICAgICB9OwogICAgIH0KCgsKAwQHARIE9QEI
FQrmAgoEBAcCABIE/gECGxrXAiBSZXF1aXJlZC4gVGhlIG1lc3NhZ2UgbmFtZSBvZiB0aGUg
cHJpbWFyeSByZXR1cm4gdHlwZSBmb3IgdGhpcwogbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4K
IFRoaXMgdHlwZSB3aWxsIGJlIHVzZWQgdG8gZGVzZXJpYWxpemUgdGhlIExSTydzIHJlc3Bv
bnNlLgoKIElmIHRoZSByZXNwb25zZSBpcyBpbiBhIGRpZmZlcmVudCBwYWNrYWdlIGZyb20g
dGhlIHJwYywgYSBmdWxseS1xdWFsaWZpZWQKIG1lc3NhZ2UgbmFtZSBtdXN0IGJlIHVzZWQg
KGUuZy4gYGdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RgKS4KCiBOb3RlOiBBbHRlcmluZyB0aGlz
IHZhbHVlIGNvbnN0aXR1dGVzIGEgYnJlYWtpbmcgY2hhbmdlLgoKDQoFBAcCAAUSBP4BAggK
DQoFBAcCAAESBP4BCRYKDQoFBAcCAAMSBP4BGRoKpQIKBAQHAgESBIcCAhsalgIgUmVxdWly
ZWQuIFRoZSBtZXNzYWdlIG5hbWUgb2YgdGhlIG1ldGFkYXRhIHR5cGUgZm9yIHRoaXMgbG9u
Zy1ydW5uaW5nCiBvcGVyYXRpb24uCgogSWYgdGhlIHJlc3BvbnNlIGlzIGluIGEgZGlmZmVy
ZW50IHBhY2thZ2UgZnJvbSB0aGUgcnBjLCBhIGZ1bGx5LXF1YWxpZmllZAogbWVzc2FnZSBu
YW1lIG11c3QgYmUgdXNlZCAoZS5nLiBgZ29vZ2xlLnByb3RvYnVmLlN0cnVjdGApLgoKIE5v
dGU6IEFsdGVyaW5nIHRoaXMgdmFsdWUgY29uc3RpdHV0ZXMgYSBicmVha2luZyBjaGFuZ2Uu
CgoNCgUEBwIBBRIEhwICCAoNCgUEBwIBARIEhwIJFgoNCgUEBwIBAxIEhwIZGmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Longrunning::Operations::Operation ===
    # Fields for Operation
    # Field: name Type: 9 ()
    # Field: metadata Type: 11 (.google.protobuf.Any)
    # Field: done Type: 8 ()
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: response Type: 11 (.google.protobuf.Any)

=pod

=head1 NAME

Google::Longrunning::Operations::Operation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::Operation->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<metadata>

Type: Message (.google.protobuf.Any)

=item * B<done>

Type: Bool

=item * B<error>

Type: Message (.google.rpc.Status)

=item * B<response>

Type: Message (.google.protobuf.Any)

=back

=cut

# === Message: Google::Longrunning::Operations::GetOperationRequest ===
    # Fields for GetOperationRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Longrunning::Operations::GetOperationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::GetOperationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Longrunning::Operations::ListOperationsRequest ===
    # Fields for ListOperationsRequest
    # Field: name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_partial_success Type: 8 ()

=pod

=head1 NAME

Google::Longrunning::Operations::ListOperationsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::ListOperationsRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<filter>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<return_partial_success>

Type: Bool

=back

=cut

# === Message: Google::Longrunning::Operations::ListOperationsResponse ===
    # Fields for ListOperationsResponse
    # Field: operations Type: 11 (.google.longrunning.Operation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Longrunning::Operations::ListOperationsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::ListOperationsResponse->new(
        operations => $value,
    );

=head1 FIELDS

=over 4

=item * B<operations>

Type: Message (.google.longrunning.Operation)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Longrunning::Operations::CancelOperationRequest ===
    # Fields for CancelOperationRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Longrunning::Operations::CancelOperationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::CancelOperationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Longrunning::Operations::DeleteOperationRequest ===
    # Fields for DeleteOperationRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Longrunning::Operations::DeleteOperationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::DeleteOperationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Longrunning::Operations::WaitOperationRequest ===
    # Fields for WaitOperationRequest
    # Field: name Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)

=pod

=head1 NAME

Google::Longrunning::Operations::WaitOperationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::WaitOperationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<timeout>

Type: Message (.google.protobuf.Duration)

=back

=cut

# === Message: Google::Longrunning::Operations::OperationInfo ===
    # Fields for OperationInfo
    # Field: response_type Type: 9 ()
    # Field: metadata_type Type: 9 ()

=pod

=head1 NAME

Google::Longrunning::Operations::OperationInfo - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Longrunning::Operations;

    my $msg = Google::Longrunning::Operations::OperationInfo->new(
        response_type => $value,
    );

=head1 FIELDS

=over 4

=item * B<response_type>

Type: String

=item * B<metadata_type>

Type: String

=back

=cut

# === Service Client: Google::Longrunning::Operations::OperationsClient ===
package Google::Longrunning::Operations::OperationsClient;

=pod

=head1 NAME

Google::Longrunning::Operations::OperationsClient - Client stub representing the remote Operations service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<localhost:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'localhost:443' );

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

sub list_operations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Longrunning::Operations::ListOperationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.longrunning.Operations',
        method         => 'ListOperations',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::ListOperationsResponse',
    });
}

sub get_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Longrunning::Operations::GetOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.longrunning.Operations',
        method         => 'GetOperation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Longrunning::Operations::DeleteOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.longrunning.Operations',
        method         => 'DeleteOperation',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub cancel_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Longrunning::Operations::CancelOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.longrunning.Operations',
        method         => 'CancelOperation',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub wait_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Longrunning::Operations::WaitOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.longrunning.Operations',
        method         => 'WaitOperation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Longrunning::Operations - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
