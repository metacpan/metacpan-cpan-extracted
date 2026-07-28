package Google::Iam::V1::IamPolicy;

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
    eval { require Google::Api::Resource };
    eval { require Google::Iam::V1::Options };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvaWFtL3YxL2lhbV9wb2xpY3kucHJvdG8SDWdvb2dsZS5pYW0udjEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Ghtnb29nbGUvaWFtL3YxL29wdGlvbnMucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnBy
b3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKtAQoTU2V0SWFtUG9saWN5
UmVxdWVzdBIlCghyZXNvdXJjZRgBIAEoCUIJ4EEC+kEDCgEqUghyZXNvdXJjZRIyCgZwb2xp
Y3kYAiABKAsyFS5nb29nbGUuaWFtLnYxLlBvbGljeUID4EECUgZwb2xpY3kSOwoLdXBkYXRl
X21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIncK
E0dldElhbVBvbGljeVJlcXVlc3QSJQoIcmVzb3VyY2UYASABKAlCCeBBAvpBAwoBKlIIcmVz
b3VyY2USOQoHb3B0aW9ucxgCIAEoCzIfLmdvb2dsZS5pYW0udjEuR2V0UG9saWN5T3B0aW9u
c1IHb3B0aW9ucyJpChlUZXN0SWFtUGVybWlzc2lvbnNSZXF1ZXN0EiUKCHJlc291cmNlGAEg
ASgJQgngQQL6QQMKASpSCHJlc291cmNlEiUKC3Blcm1pc3Npb25zGAIgAygJQgPgQQJSC3Bl
cm1pc3Npb25zIj4KGlRlc3RJYW1QZXJtaXNzaW9uc1Jlc3BvbnNlEiAKC3Blcm1pc3Npb25z
GAEgAygJUgtwZXJtaXNzaW9uczK0AwoJSUFNUG9saWN5EnQKDFNldElhbVBvbGljeRIiLmdv
b2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5
IimC0+STAiMiHi92MS97cmVzb3VyY2U9Kip9OnNldElhbVBvbGljeToBKhJ0CgxHZXRJYW1Q
b2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFt
LnYxLlBvbGljeSIpgtPkkwIjIh4vdjEve3Jlc291cmNlPSoqfTpnZXRJYW1Qb2xpY3k6ASoS
mgEKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Np
b25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9uc2Ui
L4LT5JMCKSIkL3YxL3tyZXNvdXJjZT0qKn06dGVzdElhbVBlcm1pc3Npb25zOgEqGh7KQRtp
YW0tbWV0YS1hcGkuZ29vZ2xlYXBpcy5jb21CfAoRY29tLmdvb2dsZS5pYW0udjFCDklhbVBv
bGljeVByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vaWFtL2FwaXYxL2lhbXBiO2lhbXBi
qgITR29vZ2xlLkNsb3VkLklhbS5WMcoCE0dvb2dsZVxDbG91ZFxJYW1cVjFKlCcKBxIFDgCc
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
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABYKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAlCgkKAgMF
EgMXACQKCQoCAwYSAxgAKgoICgEIEgMaADAKCQoCCCUSAxoAMAoICgEIEgMbAEAKCQoCCAsS
AxsAQAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdAC8KCQoCCAgSAx0ALwoICgEIEgMe
ACoKCQoCCAESAx4AKgoICgEIEgMfADAKCQoCCCkSAx8AMAq4BwoCBgASBDoAYAEaqwcgQVBJ
IE92ZXJ2aWV3CgogTWFuYWdlcyBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1lbnQgKElB
TSkgcG9saWNpZXMuCgogQW55IGltcGxlbWVudGF0aW9uIG9mIGFuIEFQSSB0aGF0IG9mZmVy
cyBhY2Nlc3MgY29udHJvbCBmZWF0dXJlcwogaW1wbGVtZW50cyB0aGUgZ29vZ2xlLmlhbS52
MS5JQU1Qb2xpY3kgaW50ZXJmYWNlLgoKICMjIERhdGEgbW9kZWwKCiBBY2Nlc3MgY29udHJv
bCBpcyBhcHBsaWVkIHdoZW4gYSBwcmluY2lwYWwgKHVzZXIgb3Igc2VydmljZSBhY2NvdW50
KSwgdGFrZXMKIHNvbWUgYWN0aW9uIG9uIGEgcmVzb3VyY2UgZXhwb3NlZCBieSBhIHNlcnZp
Y2UuIFJlc291cmNlcywgaWRlbnRpZmllZCBieQogVVJJLWxpa2UgbmFtZXMsIGFyZSB0aGUg
dW5pdCBvZiBhY2Nlc3MgY29udHJvbCBzcGVjaWZpY2F0aW9uLiBTZXJ2aWNlCiBpbXBsZW1l
bnRhdGlvbnMgY2FuIGNob29zZSB0aGUgZ3JhbnVsYXJpdHkgb2YgYWNjZXNzIGNvbnRyb2wg
YW5kIHRoZQogc3VwcG9ydGVkIHBlcm1pc3Npb25zIGZvciB0aGVpciByZXNvdXJjZXMuCiBG
b3IgZXhhbXBsZSBvbmUgZGF0YWJhc2Ugc2VydmljZSBtYXkgYWxsb3cgYWNjZXNzIGNvbnRy
b2wgdG8gYmUKIHNwZWNpZmllZCBvbmx5IGF0IHRoZSBUYWJsZSBsZXZlbCwgd2hlcmVhcyBh
bm90aGVyIG1pZ2h0IGFsbG93IGFjY2VzcyBjb250cm9sCiB0byBhbHNvIGJlIHNwZWNpZmll
ZCBhdCB0aGUgQ29sdW1uIGxldmVsLgoKICMjIFBvbGljeSBTdHJ1Y3R1cmUKCiBTZWUgZ29v
Z2xlLmlhbS52MS5Qb2xpY3kKCiBUaGlzIGlzIGludGVudGlvbmFsbHkgbm90IGEgQ1JVRCBz
dHlsZSBBUEkgYmVjYXVzZSBhY2Nlc3MgY29udHJvbCBwb2xpY2llcwogYXJlIGNyZWF0ZWQg
YW5kIGRlbGV0ZWQgaW1wbGljaXRseSB3aXRoIHRoZSByZXNvdXJjZXMgdG8gd2hpY2ggdGhl
eSBhcmUKIGF0dGFjaGVkLgoKCgoDBgABEgM6CBEKCgoDBgADEgM7AkMKDAoFBgADmQgSAzsC
Qwq3AQoEBgACABIEQQJGAxqoASBTZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgb24g
dGhlIHNwZWNpZmllZCByZXNvdXJjZS4gUmVwbGFjZXMgYW55CiBleGlzdGluZyBwb2xpY3ku
CgogQ2FuIHJldHVybiBgTk9UX0ZPVU5EYCwgYElOVkFMSURfQVJHVU1FTlRgLCBhbmQgYFBF
Uk1JU1NJT05fREVOSUVEYCBlcnJvcnMuCgoMCgUGAAIAARIDQQYSCgwKBQYAAgACEgNBEyYK
DAoFBgACAAMSA0ExNwoNCgUGAAIABBIEQgRFBgoRCgkGAAIABLDKvCISBEIERQYKkAEKBAYA
AgESBEsCUAMagQEgR2V0cyB0aGUgYWNjZXNzIGNvbnRyb2wgcG9saWN5IGZvciBhIHJlc291
cmNlLgogUmV0dXJucyBhbiBlbXB0eSBwb2xpY3kgaWYgdGhlIHJlc291cmNlIGV4aXN0cyBh
bmQgZG9lcyBub3QgaGF2ZSBhIHBvbGljeQogc2V0LgoKDAoFBgACAQESA0sGEgoMCgUGAAIB
AhIDSxMmCgwKBQYAAgEDEgNLMTcKDQoFBgACAQQSBEwETwYKEQoJBgACAQSwyrwiEgRMBE8G
CvQCCgQGAAICEgRZAl8DGuUCIFJldHVybnMgcGVybWlzc2lvbnMgdGhhdCBhIGNhbGxlciBo
YXMgb24gdGhlIHNwZWNpZmllZCByZXNvdXJjZS4KIElmIHRoZSByZXNvdXJjZSBkb2VzIG5v
dCBleGlzdCwgdGhpcyB3aWxsIHJldHVybiBhbiBlbXB0eSBzZXQgb2YKIHBlcm1pc3Npb25z
LCBub3QgYSBgTk9UX0ZPVU5EYCBlcnJvci4KCiBOb3RlOiBUaGlzIG9wZXJhdGlvbiBpcyBk
ZXNpZ25lZCB0byBiZSB1c2VkIGZvciBidWlsZGluZyBwZXJtaXNzaW9uLWF3YXJlCiBVSXMg
YW5kIGNvbW1hbmQtbGluZSB0b29scywgbm90IGZvciBhdXRob3JpemF0aW9uIGNoZWNraW5n
LiBUaGlzIG9wZXJhdGlvbgogbWF5ICJmYWlsIG9wZW4iIHdpdGhvdXQgd2FybmluZy4KCgwK
BQYAAgIBEgNZBhgKDAoFBgACAgISA1kZMgoMCgUGAAICAxIDWg8pCg0KBQYAAgIEEgRbBF4G
ChEKCQYAAgIEsMq8IhIEWwReBgo4CgIEABIEYwB3ARosIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
YFNldElhbVBvbGljeWAgbWV0aG9kLgoKCgoDBAABEgNjCBsKmwEKBAQAAgASBGYCaQQajAEg
UkVRVUlSRUQ6IFRoZSByZXNvdXJjZSBmb3Igd2hpY2ggdGhlIHBvbGljeSBpcyBiZWluZyBz
cGVjaWZpZWQuCiBTZWUgdGhlIG9wZXJhdGlvbiBkb2N1bWVudGF0aW9uIGZvciB0aGUgYXBw
cm9wcmlhdGUgdmFsdWUgZm9yIHRoaXMgZmllbGQuCgoMCgUEAAIABRIDZgIICgwKBQQAAgAB
EgNmCREKDAoFBAACAAMSA2YUFQoNCgUEAAIACBIEZhZpAwoPCggEAAIACJwIABIDZwQqCg8K
CAQAAgAInwgBEgNoBC4K8wEKBAQAAgESA28CPRrlASBSRVFVSVJFRDogVGhlIGNvbXBsZXRl
IHBvbGljeSB0byBiZSBhcHBsaWVkIHRvIHRoZSBgcmVzb3VyY2VgLiBUaGUgc2l6ZSBvZgog
dGhlIHBvbGljeSBpcyBsaW1pdGVkIHRvIGEgZmV3IDEwcyBvZiBLQi4gQW4gZW1wdHkgcG9s
aWN5IGlzIGEKIHZhbGlkIHBvbGljeSBidXQgY2VydGFpbiBDbG91ZCBQbGF0Zm9ybSBzZXJ2
aWNlcyAoc3VjaCBhcyBQcm9qZWN0cykKIG1pZ2h0IHJlamVjdCB0aGVtLgoKDAoFBAACAQYS
A28CCAoMCgUEAAIBARIDbwkPCgwKBQQAAgEDEgNvEhMKDAoFBAACAQgSA28UPAoPCggEAAIB
CJwIABIDbxU7Ct4BCgQEAAICEgN2Aiwa0AEgT1BUSU9OQUw6IEEgRmllbGRNYXNrIHNwZWNp
Znlpbmcgd2hpY2ggZmllbGRzIG9mIHRoZSBwb2xpY3kgdG8gbW9kaWZ5LiBPbmx5CiB0aGUg
ZmllbGRzIGluIHRoZSBtYXNrIHdpbGwgYmUgbW9kaWZpZWQuIElmIG5vIG1hc2sgaXMgcHJv
dmlkZWQsIHRoZQogZm9sbG93aW5nIGRlZmF1bHQgbWFzayBpcyB1c2VkOgoKIGBwYXRoczog
ImJpbmRpbmdzLCBldGFnImAKCgwKBQQAAgIGEgN2AhsKDAoFBAACAgESA3YcJwoMCgUEAAIC
AxIDdiorCjkKAgQBEgV6AIUBARosIFJlcXVlc3QgbWVzc2FnZSBmb3IgYEdldElhbVBvbGlj
eWAgbWV0aG9kLgoKCgoDBAEBEgN6CBsKnAEKBAQBAgASBX0CgAEEGowBIFJFUVVJUkVEOiBU
aGUgcmVzb3VyY2UgZm9yIHdoaWNoIHRoZSBwb2xpY3kgaXMgYmVpbmcgcmVxdWVzdGVkLgog
U2VlIHRoZSBvcGVyYXRpb24gZG9jdW1lbnRhdGlvbiBmb3IgdGhlIGFwcHJvcHJpYXRlIHZh
bHVlIGZvciB0aGlzIGZpZWxkLgoKDAoFBAECAAUSA30CCAoMCgUEAQIAARIDfQkRCgwKBQQB
AgADEgN9FBUKDgoFBAECAAgSBX0WgAEDCg8KCAQBAgAInAgAEgN+BCoKDwoIBAECAAifCAES
A38ELgpgCgQEAQIBEgSEAQIfGlIgT1BUSU9OQUw6IEEgYEdldFBvbGljeU9wdGlvbnNgIG9i
amVjdCBmb3Igc3BlY2lmeWluZyBvcHRpb25zIHRvCiBgR2V0SWFtUG9saWN5YC4KCg0KBQQB
AgEGEgSEAQISCg0KBQQBAgEBEgSEARMaCg0KBQQBAgEDEgSEAR0eCkAKAgQCEgaIAQCVAQEa
MiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBUZXN0SWFtUGVybWlzc2lvbnNgIG1ldGhvZC4KCgsK
AwQCARIEiAEIIQqkAQoEBAICABIGiwECjgEEGpMBIFJFUVVJUkVEOiBUaGUgcmVzb3VyY2Ug
Zm9yIHdoaWNoIHRoZSBwb2xpY3kgZGV0YWlsIGlzIGJlaW5nIHJlcXVlc3RlZC4KIFNlZSB0
aGUgb3BlcmF0aW9uIGRvY3VtZW50YXRpb24gZm9yIHRoZSBhcHByb3ByaWF0ZSB2YWx1ZSBm
b3IgdGhpcyBmaWVsZC4KCg0KBQQCAgAFEgSLAQIICg0KBQQCAgABEgSLAQkRCg0KBQQCAgAD
EgSLARQVCg8KBQQCAgAIEgaLARaOAQMKEAoIBAICAAicCAASBIwBBCoKEAoIBAICAAifCAES
BI0BBC4K8QEKBAQCAgESBJQBAksa4gEgVGhlIHNldCBvZiBwZXJtaXNzaW9ucyB0byBjaGVj
ayBmb3IgdGhlIGByZXNvdXJjZWAuIFBlcm1pc3Npb25zIHdpdGgKIHdpbGRjYXJkcyAoc3Vj
aCBhcyAnKicgb3IgJ3N0b3JhZ2UuKicpIGFyZSBub3QgYWxsb3dlZC4gRm9yIG1vcmUKIGlu
Zm9ybWF0aW9uIHNlZQogW0lBTSBPdmVydmlld10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2lhbS9kb2NzL292ZXJ2aWV3I3Blcm1pc3Npb25zKS4KCg0KBQQCAgEEEgSUAQIKCg0KBQQC
AgEFEgSUAQsRCg0KBQQCAgEBEgSUARIdCg0KBQQCAgEDEgSUASAhCg0KBQQCAgEIEgSUASJK
ChAKCAQCAgEInAgAEgSUASNJCkEKAgQDEgaYAQCcAQEaMyBSZXNwb25zZSBtZXNzYWdlIGZv
ciBgVGVzdElhbVBlcm1pc3Npb25zYCBtZXRob2QuCgoLCgMEAwESBJgBCCIKXQoEBAMCABIE
mwECIhpPIEEgc3Vic2V0IG9mIGBUZXN0UGVybWlzc2lvbnNSZXF1ZXN0LnBlcm1pc3Npb25z
YCB0aGF0IHRoZSBjYWxsZXIgaXMKIGFsbG93ZWQuCgoNCgUEAwIABBIEmwECCgoNCgUEAwIA
BRIEmwELEQoNCgUEAwIAARIEmwESHQoNCgUEAwIAAxIEmwEgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V1::IamPolicy::SetIamPolicyRequest ===
    # Fields for SetIamPolicyRequest
    # Field: resource Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Iam::V1::IamPolicy::SetIamPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Iam::V1::IamPolicy;

    my $msg = Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new(
        resource => $value,
    );

=head1 FIELDS

=over 4

=item * B<resource>

Type: String

=item * B<policy>

Type: Message (.google.iam.v1.Policy)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Iam::V1::IamPolicy::GetIamPolicyRequest ===
    # Fields for GetIamPolicyRequest
    # Field: resource Type: 9 ()
    # Field: options Type: 11 (.google.iam.v1.GetPolicyOptions)

=pod

=head1 NAME

Google::Iam::V1::IamPolicy::GetIamPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Iam::V1::IamPolicy;

    my $msg = Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new(
        resource => $value,
    );

=head1 FIELDS

=over 4

=item * B<resource>

Type: String

=item * B<options>

Type: Message (.google.iam.v1.GetPolicyOptions)

=back

=cut

# === Message: Google::Iam::V1::IamPolicy::TestIamPermissionsRequest ===
    # Fields for TestIamPermissionsRequest
    # Field: resource Type: 9 ()
    # Field: permissions Type: 9 ()

=pod

=head1 NAME

Google::Iam::V1::IamPolicy::TestIamPermissionsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Iam::V1::IamPolicy;

    my $msg = Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new(
        resource => $value,
    );

=head1 FIELDS

=over 4

=item * B<resource>

Type: String

=item * B<permissions>

Type: String

=back

=cut

# === Message: Google::Iam::V1::IamPolicy::TestIamPermissionsResponse ===
    # Fields for TestIamPermissionsResponse
    # Field: permissions Type: 9 ()

=pod

=head1 NAME

Google::Iam::V1::IamPolicy::TestIamPermissionsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Iam::V1::IamPolicy;

    my $msg = Google::Iam::V1::IamPolicy::TestIamPermissionsResponse->new(
        permissions => $value,
    );

=head1 FIELDS

=over 4

=item * B<permissions>

Type: String

=back

=cut

# === Service Client: Google::Iam::V1::IamPolicy::IamPolicyClient ===
package Google::Iam::V1::IamPolicy::IamPolicyClient;

=pod

=head1 NAME

Google::Iam::V1::IamPolicy::IamPolicyClient - Client stub representing the remote IAMPolicy service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=head1 NAME

Google::Iam::V1::IamPolicy - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
