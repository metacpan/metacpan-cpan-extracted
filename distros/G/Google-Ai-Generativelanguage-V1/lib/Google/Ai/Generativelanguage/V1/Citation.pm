package Google::Ai::Generativelanguage::V1::Citation;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxL2NpdGF0aW9uLnByb3RvEh9nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvIm4KEENpdGF0aW9uTWV0YWRhdGESWgoQY2l0YXRpb25fc291cmNlcxgBIAMoCzIv
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjEuQ2l0YXRpb25Tb3VyY2VSD2NpdGF0
aW9uU291cmNlcyLUAQoOQ2l0YXRpb25Tb3VyY2USKQoLc3RhcnRfaW5kZXgYASABKAVCA+BB
AUgAUgpzdGFydEluZGV4iAEBEiUKCWVuZF9pbmRleBgCIAEoBUID4EEBSAFSCGVuZEluZGV4
iAEBEhoKA3VyaRgDIAEoCUID4EEBSAJSA3VyaYgBARIiCgdsaWNlbnNlGAQgASgJQgPgQQFI
A1IHbGljZW5zZYgBAUIOCgxfc3RhcnRfaW5kZXhCDAoKX2VuZF9pbmRleEIGCgRfdXJpQgoK
CF9saWNlbnNlQpEBCiNjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MUINQ2l0
YXRpb25Qcm90b1ABWlljbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFn
ZS9hcGl2MS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqEDgoG
EgQOADIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkK
AgMAEgMSACkKCAoBCBIDFABwCgkKAggLEgMUAHAKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoB
CBIDFgAuCgkKAggIEgMWAC4KCAoBCBIDFwA8CgkKAggBEgMXADwKSQoCBAASBBoAHQEaPSBB
IGNvbGxlY3Rpb24gb2Ygc291cmNlIGF0dHJpYnV0aW9ucyBmb3IgYSBwaWVjZSBvZiBjb250
ZW50LgoKCgoDBAABEgMaCBgKPAoEBAACABIDHAIvGi8gQ2l0YXRpb25zIHRvIHNvdXJjZXMg
Zm9yIGEgc3BlY2lmaWMgcmVzcG9uc2UuCgoMCgUEAAIABBIDHAIKCgwKBQQAAgAGEgMcCxkK
DAoFBAACAAESAxwaKgoMCgUEAAIAAxIDHC0uCkoKAgQBEgQgADIBGj4gQSBjaXRhdGlvbiB0
byBhIHNvdXJjZSBmb3IgYSBwb3J0aW9uIG9mIGEgc3BlY2lmaWMgcmVzcG9uc2UuCgoKCgME
AQESAyAIFgqdAQoEBAECABIDJQJKGo8BIE9wdGlvbmFsLiBTdGFydCBvZiBzZWdtZW50IG9m
IHRoZSByZXNwb25zZSB0aGF0IGlzIGF0dHJpYnV0ZWQgdG8gdGhpcwogc291cmNlLgoKIElu
ZGV4IGluZGljYXRlcyB0aGUgc3RhcnQgb2YgdGhlIHNlZ21lbnQsIG1lYXN1cmVkIGluIGJ5
dGVzLgoKDAoFBAECAAQSAyUCCgoMCgUEAQIABRIDJQsQCgwKBQQBAgABEgMlERwKDAoFBAEC
AAMSAyUfIAoMCgUEAQIACBIDJSFJCg8KCAQBAgAInAgAEgMlIkgKQgoEBAECARIDKAJIGjUg
T3B0aW9uYWwuIEVuZCBvZiB0aGUgYXR0cmlidXRlZCBzZWdtZW50LCBleGNsdXNpdmUuCgoM
CgUEAQIBBBIDKAIKCgwKBQQBAgEFEgMoCxAKDAoFBAECAQESAygRGgoMCgUEAQIBAxIDKB0e
CgwKBQQBAgEIEgMoH0cKDwoIBAECAQicCAASAyggRgpWCgQEAQICEgMrAkMaSSBPcHRpb25h
bC4gVVJJIHRoYXQgaXMgYXR0cmlidXRlZCBhcyBhIHNvdXJjZSBmb3IgYSBwb3J0aW9uIG9m
IHRoZSB0ZXh0LgoKDAoFBAECAgQSAysCCgoMCgUEAQICBRIDKwsRCgwKBQQBAgIBEgMrEhUK
DAoFBAECAgMSAysYGQoMCgUEAQICCBIDKxpCCg8KCAQBAgIInAgAEgMrG0EKlAEKBAQBAgMS
AzECRxqGASBPcHRpb25hbC4gTGljZW5zZSBmb3IgdGhlIEdpdEh1YiBwcm9qZWN0IHRoYXQg
aXMgYXR0cmlidXRlZCBhcyBhIHNvdXJjZSBmb3IKIHNlZ21lbnQuCgogTGljZW5zZSBpbmZv
IGlzIHJlcXVpcmVkIGZvciBjb2RlIGNpdGF0aW9ucy4KCgwKBQQBAgMEEgMxAgoKDAoFBAEC
AwUSAzELEQoMCgUEAQIDARIDMRIZCgwKBQQBAgMDEgMxHB0KDAoFBAECAwgSAzEeRgoPCggE
AQIDCJwIABIDMR9FYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1::Citation::CitationMetadata ===
    # Fields for CitationMetadata
    # Field: citation_sources Type: 11 (.google.ai.generativelanguage.v1.CitationSource)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::Citation::CitationMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::Citation;

    my $msg = Google::Ai::Generativelanguage::V1::Citation::CitationMetadata->new(
        citation_sources => $value,
    );

=head1 FIELDS

=over 4

=item * B<citation_sources>

Type: Message (.google.ai.generativelanguage.v1.CitationSource)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1::Citation::CitationSource ===
    # Fields for CitationSource
    # Field: start_index Type: 5 ()
    # Field: end_index Type: 5 ()
    # Field: uri Type: 9 ()
    # Field: license Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::Citation::CitationSource - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::Citation;

    my $msg = Google::Ai::Generativelanguage::V1::Citation::CitationSource->new(
        start_index => $value,
    );

=head1 FIELDS

=over 4

=item * B<start_index>

Type: Int32

=item * B<end_index>

Type: Int32

=item * B<uri>

Type: String

=item * B<license>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::Citation - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
