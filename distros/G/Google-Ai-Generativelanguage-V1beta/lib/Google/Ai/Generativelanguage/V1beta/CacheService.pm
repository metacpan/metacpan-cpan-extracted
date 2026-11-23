package Google::Ai::Generativelanguage::V1beta::CacheService;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::CachedContent };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9jYWNoZV9zZXJ2aWNlLnBy
b3RvEiNnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YRo4Z29vZ2xlL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS92MWJldGEvY2FjaGVkX2NvbnRlbnQucHJvdG8aHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtn
b29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNr
LnByb3RvImEKGUxpc3RDYWNoZWRDb250ZW50c1JlcXVlc3QSIAoJcGFnZV9zaXplGAEgASgF
QgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2VuIqEB
ChpMaXN0Q2FjaGVkQ29udGVudHNSZXNwb25zZRJbCg9jYWNoZWRfY29udGVudHMYASADKAsy
Mi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DYWNoZWRDb250ZW50Ug5j
YWNoZWRDb250ZW50cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i
fAoaQ3JlYXRlQ2FjaGVkQ29udGVudFJlcXVlc3QSXgoOY2FjaGVkX2NvbnRlbnQYASABKAsy
Mi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DYWNoZWRDb250ZW50QgPg
QQJSDWNhY2hlZENvbnRlbnQiZgoXR2V0Q2FjaGVkQ29udGVudFJlcXVlc3QSSwoEbmFtZRgB
IAEoCUI34EEC+kExCi9nZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vQ2FjaGVk
Q29udGVudFIEbmFtZSK5AQoaVXBkYXRlQ2FjaGVkQ29udGVudFJlcXVlc3QSXgoOY2FjaGVk
X2NvbnRlbnQYASABKAsyMi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5D
YWNoZWRDb250ZW50QgPgQQJSDWNhY2hlZENvbnRlbnQSOwoLdXBkYXRlX21hc2sYAiABKAsy
Gi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrImkKGkRlbGV0ZUNhY2hl
ZENvbnRlbnRSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovZ2VuZXJhdGl2ZWxhbmd1
YWdlLmdvb2dsZWFwaXMuY29tL0NhY2hlZENvbnRlbnRSBG5hbWUyhwgKDENhY2hlU2Vydmlj
ZRK4AQoSTGlzdENhY2hlZENvbnRlbnRzEj4uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWJldGEuTGlzdENhY2hlZENvbnRlbnRzUmVxdWVzdBo/Lmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFiZXRhLkxpc3RDYWNoZWRDb250ZW50c1Jlc3BvbnNlIiGC0+STAhgS
Fi92MWJldGEvY2FjaGVkQ29udGVudHPaQQASywEKE0NyZWF0ZUNhY2hlZENvbnRlbnQSPy5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DcmVhdGVDYWNoZWRDb250ZW50
UmVxdWVzdBoyLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNhY2hlZENv
bnRlbnQiP4LT5JMCKCIWL3YxYmV0YS9jYWNoZWRDb250ZW50czoOY2FjaGVkX2NvbnRlbnTa
QQ5jYWNoZWRfY29udGVudBK0AQoQR2V0Q2FjaGVkQ29udGVudBI8Lmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkdldENhY2hlZENvbnRlbnRSZXF1ZXN0GjIuZ29vZ2xl
LmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ2FjaGVkQ29udGVudCIugtPkkwIhEh8v
djFiZXRhL3tuYW1lPWNhY2hlZENvbnRlbnRzLyp92kEEbmFtZRLvAQoTVXBkYXRlQ2FjaGVk
Q29udGVudBI/Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlVwZGF0ZUNh
Y2hlZENvbnRlbnRSZXF1ZXN0GjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJl
dGEuQ2FjaGVkQ29udGVudCJjgtPkkwJAMi4vdjFiZXRhL3tjYWNoZWRfY29udGVudC5uYW1l
PWNhY2hlZENvbnRlbnRzLyp9Og5jYWNoZWRfY29udGVudNpBGmNhY2hlZF9jb250ZW50LHVw
ZGF0ZV9tYXNrEp4BChNEZWxldGVDYWNoZWRDb250ZW50Ej8uZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEuRGVsZXRlQ2FjaGVkQ29udGVudFJlcXVlc3QaFi5nb29nbGUu
cHJvdG9idWYuRW1wdHkiLoLT5JMCISofL3YxYmV0YS97bmFtZT1jYWNoZWRDb250ZW50cy8q
fdpBBG5hbWUaJMpBIWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbUKdAQonY29t
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhQhFDYWNoZVNlcnZpY2VQcm90
b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWJl
dGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKsR8KBxIFDgCS
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwAS
AxIAQgoJCgIDARIDEwAmCgkKAgMCEgMUACEKCQoCAwMSAxUAKQoJCgIDBBIDFgAjCgkKAgMF
EgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAHQKCQoCCAsSAxoAdAoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcADIKCQoCCAgSAxwAMgoICgEIEgMdAEAKCQoCCAESAx0AQAqzAgoCBgAS
BCMAUQEapgIgQVBJIGZvciBtYW5hZ2luZyBjYWNoZSBvZiBjb250ZW50IChDYWNoZWRDb250
ZW50IHJlc291cmNlcykgdGhhdCBjYW4gYmUgdXNlZAogaW4gR2VuZXJhdGl2ZVNlcnZpY2Ug
cmVxdWVzdHMuIFRoaXMgd2F5IGdlbmVyYXRlIGNvbnRlbnQgcmVxdWVzdHMgY2FuIGJlbmVm
aXQKIGZyb20gcHJlcHJvY2Vzc2luZyB3b3JrIGJlaW5nIGRvbmUgZWFybGllciwgcG9zc2li
bHkgbG93ZXJpbmcgdGhlaXIKIGNvbXB1dGF0aW9uYWwgY29zdC4gSXQgaXMgaW50ZW5kZWQg
dG8gYmUgdXNlZCB3aXRoIGxhcmdlIGNvbnRleHRzLgoKCgoDBgABEgMjCBQKCgoDBgADEgMk
AkkKDAoFBgADmQgSAyQCSQolCgQGAAIAEgQnAi0DGhcgTGlzdHMgQ2FjaGVkQ29udGVudHMu
CgoMCgUGAAIAARIDJwYYCgwKBQYAAgACEgMnGTIKDAoFBgACAAMSAygPKQoNCgUGAAIABBIE
KQQrBgoRCgkGAAIABLDKvCISBCkEKwYKDAoFBgACAAQSAywELgoPCggGAAIABJsIABIDLAQu
Ci8KBAYAAgESBDACNgMaISBDcmVhdGVzIENhY2hlZENvbnRlbnQgcmVzb3VyY2UuCgoMCgUG
AAIBARIDMAYZCgwKBQYAAgECEgMwGjQKDAoFBgACAQMSAzA/TAoNCgUGAAIBBBIEMQQ0BgoR
CgkGAAIBBLDKvCISBDEENAYKDAoFBgACAQQSAzUEPAoPCggGAAIBBJsIABIDNQQ8Ci0KBAYA
AgISBDkCPgMaHyBSZWFkcyBDYWNoZWRDb250ZW50IHJlc291cmNlLgoKDAoFBgACAgESAzkG
FgoMCgUGAAICAhIDORcuCgwKBQYAAgIDEgM5OUYKDQoFBgACAgQSBDoEPAYKEQoJBgACAgSw
yrwiEgQ6BDwGCgwKBQYAAgIEEgM9BDIKDwoIBgACAgSbCAASAz0EMgpOCgQGAAIDEgRBAkcD
GkAgVXBkYXRlcyBDYWNoZWRDb250ZW50IHJlc291cmNlIChvbmx5IGV4cGlyYXRpb24gaXMg
dXBkYXRhYmxlKS4KCgwKBQYAAgMBEgNBBhkKDAoFBgACAwISA0EaNAoMCgUGAAIDAxIDQT9M
Cg0KBQYAAgMEEgRCBEUGChEKCQYAAgMEsMq8IhIEQgRFBgoMCgUGAAIDBBIDRgRICg8KCAYA
AgMEmwgAEgNGBEgKLwoEBgACBBIESgJQAxohIERlbGV0ZXMgQ2FjaGVkQ29udGVudCByZXNv
dXJjZS4KCgwKBQYAAgQBEgNKBhkKDAoFBgACBAISA0oaNAoMCgUGAAIEAxIDSw8kCg0KBQYA
AgQEEgRMBE4GChEKCQYAAgQEsMq8IhIETAROBgoMCgUGAAIEBBIDTwQyCg8KCAYAAgQEmwgA
EgNPBDIKLQoCBAASBFQAYQEaISBSZXF1ZXN0IHRvIGxpc3QgQ2FjaGVkQ29udGVudHMuCgoK
CgMEAAESA1QIIQqQAgoEBAACABIDWQI/GoICIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1i
ZXIgb2YgY2FjaGVkIGNvbnRlbnRzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5CiByZXR1
cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgc29tZSBkZWZhdWx0
ICh1bmRlciBtYXhpbXVtKQogbnVtYmVyIG9mIGl0ZW1zIHdpbGwgYmUgcmV0dXJuZWQuIFRo
ZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZQogMTAwMCB3aWxsIGJlIGNv
ZXJjZWQgdG8gMTAwMC4KCgwKBQQAAgAFEgNZAgcKDAoFBAACAAESA1kIEQoMCgUEAAIAAxID
WRQVCgwKBQQAAgAIEgNZFj4KDwoIBAACAAicCAASA1kXPQqGAgoEBAACARIDYAJBGvgBIE9w
dGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdENh
Y2hlZENvbnRlbnRzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJz
ZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBw
cm92aWRlZCB0byBgTGlzdENhY2hlZENvbnRlbnRzYCBtdXN0CiBtYXRjaCB0aGUgY2FsbCB0
aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDAoFBAACAQUSA2ACCAoMCgUEAAIBARID
YAkTCgwKBQQAAgEDEgNgFhcKDAoFBAACAQgSA2AYQAoPCggEAAIBCJwIABIDYBk/CjAKAgQB
EgRkAGsBGiQgUmVzcG9uc2Ugd2l0aCBDYWNoZWRDb250ZW50cyBsaXN0LgoKCgoDBAEBEgNk
CCIKJwoEBAECABIDZgItGhogTGlzdCBvZiBjYWNoZWQgY29udGVudHMuCgoMCgUEAQIABBID
ZgIKCgwKBQQBAgAGEgNmCxgKDAoFBAECAAESA2YZKAoMCgUEAQIAAxIDZissCo8BCgQEAQIB
EgNqAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRv
IHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRo
ZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDAoFBAECAQUSA2oCCAoMCgUEAQIBARID
agkYCgwKBQQBAgEDEgNqGxwKLgoCBAISBG4AcQEaIiBSZXF1ZXN0IHRvIGNyZWF0ZSBDYWNo
ZWRDb250ZW50LgoKCgoDBAIBEgNuCCIKNgoEBAICABIDcAJMGikgUmVxdWlyZWQuIFRoZSBj
YWNoZWQgY29udGVudCB0byBjcmVhdGUuCgoMCgUEAgIABhIDcAIPCgwKBQQCAgABEgNwEB4K
DAoFBAICAAMSA3AhIgoMCgUEAgIACBIDcCNLCg8KCAQCAgAInAgAEgNwJEoKLAoCBAMSBHQA
fQEaICBSZXF1ZXN0IHRvIHJlYWQgQ2FjaGVkQ29udGVudC4KCgoKAwQDARIDdAgfCnAKBAQD
AgASBHcCfAQaYiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgcmVmZXJyaW5nIHRvIHRo
ZSBjb250ZW50IGNhY2hlIGVudHJ5LgogRm9ybWF0OiBgY2FjaGVkQ29udGVudHMve2lkfWAK
CgwKBQQDAgAFEgN3AggKDAoFBAMCAAESA3cJDQoMCgUEAwIAAxIDdxARCg0KBQQDAgAIEgR3
EnwDCg8KCAQDAgAInAgAEgN4BCoKDwoHBAMCAAifCBIEeQR7BQowCgIEBBIGgAEAhgEBGiIg
UmVxdWVzdCB0byB1cGRhdGUgQ2FjaGVkQ29udGVudC4KCgsKAwQEARIEgAEIIgo7CgQEBAIA
EgSCAQJMGi0gUmVxdWlyZWQuIFRoZSBjb250ZW50IGNhY2hlIGVudHJ5IHRvIHVwZGF0ZQoK
DQoFBAQCAAYSBIIBAg8KDQoFBAQCAAESBIIBEB4KDQoFBAQCAAMSBIIBISIKDQoFBAQCAAgS
BIIBI0sKEAoIBAQCAAicCAASBIIBJEoKLQoEBAQCARIEhQECLBofIFRoZSBsaXN0IG9mIGZp
ZWxkcyB0byB1cGRhdGUuCgoNCgUEBAIBBhIEhQECGwoNCgUEBAIBARIEhQEcJwoNCgUEBAIB
AxIEhQEqKwowCgIEBRIGiQEAkgEBGiIgUmVxdWVzdCB0byBkZWxldGUgQ2FjaGVkQ29udGVu
dC4KCgsKAwQFARIEiQEIIgpxCgQEBQIAEgaMAQKRAQQaYSBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgcmVmZXJyaW5nIHRvIHRoZSBjb250ZW50IGNhY2hlIGVudHJ5CiBGb3JtYXQ6
IGBjYWNoZWRDb250ZW50cy97aWR9YAoKDQoFBAUCAAUSBIwBAggKDQoFBAUCAAESBIwBCQ0K
DQoFBAUCAAMSBIwBEBEKDwoFBAUCAAgSBowBEpEBAwoQCggEBQIACJwIABIEjQEEKgoRCgcE
BQIACJ8IEgaOAQSQAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest ===
    # Fields for ListCachedContentsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest->new(
        page_size => $value,
    );

=head1 FIELDS

=over 4

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse ===
    # Fields for ListCachedContentsResponse
    # Field: cached_contents Type: 11 (.google.ai.generativelanguage.v1beta.CachedContent)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse->new(
        cached_contents => $value,
    );

=head1 FIELDS

=over 4

=item * B<cached_contents>

Type: Message (.google.ai.generativelanguage.v1beta.CachedContent)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest ===
    # Fields for CreateCachedContentRequest
    # Field: cached_content Type: 11 (.google.ai.generativelanguage.v1beta.CachedContent)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest->new(
        cached_content => $value,
    );

=head1 FIELDS

=over 4

=item * B<cached_content>

Type: Message (.google.ai.generativelanguage.v1beta.CachedContent)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest ===
    # Fields for GetCachedContentRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest ===
    # Fields for UpdateCachedContentRequest
    # Field: cached_content Type: 11 (.google.ai.generativelanguage.v1beta.CachedContent)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest->new(
        cached_content => $value,
    );

=head1 FIELDS

=over 4

=item * B<cached_content>

Type: Message (.google.ai.generativelanguage.v1beta.CachedContent)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest ===
    # Fields for DeleteCachedContentRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Service Client: Google::Ai::Generativelanguage::V1beta::CacheService::CacheServiceClient ===
package Google::Ai::Generativelanguage::V1beta::CacheService::CacheServiceClient;

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::CacheServiceClient - Client stub representing the remote CacheService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub list_cached_contents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'ListCachedContents',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse',
    });
}

sub create_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'CreateCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent',
    });
}

sub get_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'GetCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent',
    });
}

sub update_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'UpdateCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent',
    });
}

sub delete_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'DeleteCachedContent',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
