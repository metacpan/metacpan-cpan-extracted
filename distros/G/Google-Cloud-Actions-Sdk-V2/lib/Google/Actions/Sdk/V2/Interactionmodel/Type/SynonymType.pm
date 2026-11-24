package Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL3N5bm9ueW1f
dHlwZS5wcm90bxIrZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwudHlw
ZRpAZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlwZS9lbnRpdHlf
ZGlzcGxheS5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byLcBAoLU3lu
b255bVR5cGUSZgoKbWF0Y2hfdHlwZRgBIAEoDjJCLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5p
bnRlcmFjdGlvbm1vZGVsLnR5cGUuU3lub255bVR5cGUuTWF0Y2hUeXBlQgPgQQFSCW1hdGNo
VHlwZRI3ChVhY2NlcHRfdW5rbm93bl92YWx1ZXMYAyABKAhCA+BBAVITYWNjZXB0VW5rbm93
blZhbHVlcxJnCghlbnRpdGllcxgCIAMoCzJGLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRl
cmFjdGlvbm1vZGVsLnR5cGUuU3lub255bVR5cGUuRW50aXRpZXNFbnRyeUID4EECUghlbnRp
dGllcxqEAQoGRW50aXR5ElkKB2Rpc3BsYXkYASABKAsyOi5nb29nbGUuYWN0aW9ucy5zZGsu
djIuaW50ZXJhY3Rpb25tb2RlbC50eXBlLkVudGl0eURpc3BsYXlCA+BBAVIHZGlzcGxheRIf
CghzeW5vbnltcxgCIAMoCUID4EEBUghzeW5vbnltcxp8Cg1FbnRpdGllc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5ElUKBXZhbHVlGAIgASgLMj8uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwudHlwZS5TeW5vbnltVHlwZS5FbnRpdHlSBXZhbHVlOgI4ASI+CglN
YXRjaFR5cGUSDwoLVU5TUEVDSUZJRUQQABIPCgtFWEFDVF9NQVRDSBABEg8KC0ZVWlpZX01B
VENIEAJCkQEKL2NvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50
eXBlQhBTeW5vbnltVHlwZVByb3RvUAFaSmdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dv
b2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlSsISCgYSBA4A
QQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADQKCQoCAwAS
AxIASgoJCgIDARIDEwApCggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgASAoJCgIIARIDGABICjgKAgQAEgQb
AEEBGiwgVHlwZSB0aGF0IG1hdGNoZXMgdGV4dCBieSBzZXQgb2Ygc3lub255bXMuCgoKCgME
AAESAxsIEwpvCgQEAAMAEgQeAiUDGmEgUmVwcmVzZW50cyBhIHN5bm9ueW0gZW50aXR5IGZp
ZWxkIHRoYXQgY29udGFpbnMgdGhlIGRldGFpbHMgb2YgYSBzaW5nbGUKIGVudHJ5IGluc2lk
ZSB0aGUgdHlwZS4KCgwKBQQAAwABEgMeChAKNgoGBAADAAIAEgMgBEcaJyBPcHRpb25hbC4g
VGhlIGVudGl0eSBkaXNwbGF5IGRldGFpbHMuCgoOCgcEAAMAAgAGEgMgBBEKDgoHBAADAAIA
ARIDIBIZCg4KBwQAAwACAAMSAyAcHQoOCgcEAAMAAgAIEgMgHkYKEQoKBAADAAIACJwIABID
IB9FCl8KBgQAAwACARIDJARKGlAgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIHN5bm9ueW1zIGZv
ciB0aGUgZW50aXR5LgogKipUaGlzIGZpZWxkIGlzIGxvY2FsaXphYmxlLioqCgoOCgcEAAMA
AgEEEgMkBAwKDgoHBAADAAIBBRIDJA0TCg4KBwQAAwACAQESAyQUHAoOCgcEAAMAAgEDEgMk
HyAKDgoHBAADAAIBCBIDJCFJChEKCgQAAwACAQicCAASAyQiSAqgAgoEBAAEABIEKwI1AxqR
AiBUaGUgdHlwZSBvZiBtYXRjaGluZyB0aGF0IGVudHJpZXMgaW4gdGhpcyB0eXBlIHdpbGwg
dXNlLiBUaGlzIHdpbGwgZW5zdXJlCiBhbGwgb2YgdGhlIHR5cGVzIHVzZSB0aGUgc2FtZSBt
YXRjaGluZyBtZXRob2QgYW5kIGFsbG93IHZhcmlhdGlvbiBvZgogbWF0Y2hpbmcgZm9yIHN5
bm9ueW0gbWF0Y2hpbmcgKGkuZS4gZnV6enkgdmVyc3VzIGV4YWN0KS4gSWYgdGhlIHZhbHVl
IGlzCiBgVU5TUEVDSUZJRURgIGl0IHdpbGwgYmUgZGVmYXVsdGVkIHRvIGBFWEFDVF9NQVRD
SGAuCgoMCgUEAAQAARIDKwcQCisKBgQABAACABIDLQQUGhwgRGVmYXVsdHMgdG8gYEVYQUNU
X01BVENIYC4KCg4KBwQABAACAAESAy0EDwoOCgcEAAQAAgACEgMtEhMKQQoGBAAEAAIBEgMw
BBQaMiBMb29rcyBmb3IgYW4gZXhhY3QgbWF0Y2ggb2YgdGhlIHN5bm9ueW0gb3IgbmFtZS4K
Cg4KBwQABAACAQESAzAEDwoOCgcEAAQAAgECEgMwEhMKYAoGBAAEAAICEgM0BBQaUSBMb29z
ZXIgdGhhbiBgRVhBQ1RfTUFUQ0hgLiBMb29rcyBmb3Igc2ltaWxhciBtYXRjaGVzIGFzIHdl
bGwgYXMgZXhhY3QKIG1hdGNoZXMuCgoOCgcEAAQAAgIBEgM0BA8KDgoHBAAEAAICAhIDNBIT
CjgKBAQAAgASAzgCRBorIE9wdGlvbmFsLiBUaGUgbWF0Y2ggdHlwZSBmb3IgdGhlIHN5bm9u
eW0uCgoMCgUEAAIABhIDOAILCgwKBQQAAgABEgM4DBYKDAoFBAACAAMSAzgZGgoMCgUEAAIA
CBIDOBtDCg8KCAQAAgAInAgAEgM4HEIKvwEKBAQAAgESAz0CShqxASBPcHRpb25hbC4gV2hl
biBzZXQgdG8gdHJ1ZSB0aGlzIHdpbGwgbWF0Y2ggdW5rbm93biB3b3JkcyBvciBwaHJhc2Vz
IGJhc2VkIG9uCiBzdXJyb3VuZGluZyBpbnB1dCBhbmQgaW50ZW50IHRyYWluaW5nIGRhdGEs
IHN1Y2ggYXMgaXRlbXMgdGhhdCBtaWdodCBiZQogYWRkZWQgdG8gYSBncm9jZXJ5IGxpc3Qu
CgoMCgUEAAIBBRIDPQIGCgwKBQQAAgEBEgM9BxwKDAoFBAACAQMSAz0fIAoMCgUEAAIBCBID
PSFJCg8KCAQAAgEInAgAEgM9IkgKNwoEBAACAhIDQAJMGiogUmVxdWlyZWQuIE5hbWVkIG1h
cCBvZiBzeW5vbnltIGVudGl0aWVzLgoKDAoFBAACAgYSA0ACFQoMCgUEAAICARIDQBYeCgwK
BQQAAgIDEgNAISIKDAoFBAACAggSA0AjSwoPCggEAAICCJwIABIDQCRKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType ===
    # Fields for SynonymType
    # Field: match_type Type: 14 (.google.actions.sdk.v2.interactionmodel.type.SynonymType.MatchType)
    # Field: accept_unknown_values Type: 8 ()
    # Field: entities Type: 11 (.google.actions.sdk.v2.interactionmodel.type.SynonymType.EntitiesEntry)

# Enum: SynonymType::MatchType
our $SynonymType_UNSPECIFIED = 0;
our $SynonymType_EXACT_MATCH = 1;
our $SynonymType_FUZZY_MATCH = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/synonym_type.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType->new({
        match_type => $match_type,
        accept_unknown_values => $accept_unknown_values,
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->match_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/synonym_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType

Type that matches text by set of synonyms.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->match_type() >> / C<< $msg->match_type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::MatchType>)

Optional. The match type for the synonym.

=item * C<< $msg->accept_unknown_values() >> / C<< $msg->accept_unknown_values($value) >>

Type: C<Bool>

Optional. When set to true this will match unknown words or phrases based on
surrounding input and intent training data, such as items that might be
added to a grocery list.

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::EntitiesEntry>)

Required. Named map of synonym entities.

=back

=head3 Enum: SynonymType::MatchType

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<EXACT_MATCH> => C<1>

=item * C<FUZZY_MATCH> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
