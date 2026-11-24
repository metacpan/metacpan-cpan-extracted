package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
ClRnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfY29sbGVjdGlvbl9wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52
Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdBpPZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVy
YWN0aW9ubW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGljX2ltYWdlX3Byb21wdC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byL+AwoWU3RhdGljQ29sbGVjdGlvblBy
b21wdBIZCgV0aXRsZRgBIAEoCUID4EEBUgV0aXRsZRIfCghzdWJ0aXRsZRgCIAEoCUID4EEB
UghzdWJ0aXRsZRJvCgVpdGVtcxgDIAMoCzJULmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRl
cmFjdGlvbm1vZGVsLnByb21wdC5TdGF0aWNDb2xsZWN0aW9uUHJvbXB0LkNvbGxlY3Rpb25J
dGVtQgPgQQJSBWl0ZW1zEm4KCmltYWdlX2ZpbGwYBCABKA4ySi5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3RhdGljSW1hZ2VQcm9tcHQuSW1hZ2VG
aWxsQgPgQQFSCWltYWdlRmlsbBrGAQoOQ29sbGVjdGlvbkl0ZW0SFQoDa2V5GAEgASgJQgPg
QQJSA2tleRIZCgV0aXRsZRgCIAEoCUID4EECUgV0aXRsZRIlCgtkZXNjcmlwdGlvbhgDIAEo
CUID4EEBUgtkZXNjcmlwdGlvbhJbCgVpbWFnZRgEIAEoCzJALmdvb2dsZS5hY3Rpb25zLnNk
ay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdC5TdGF0aWNJbWFnZVByb21wdEID4EEBUgVp
bWFnZUKnAQoxY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnBy
b21wdEIbU3RhdGljQ29sbGVjdGlvblByb21wdFByb3RvUAFaU2dvb2dsZS5nb2xhbmcub3Jn
L2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9w
cm9tcHQ7cHJvbXB0Su8QCgYSBA4AOgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQADYKCQoCAwASAxIAWQoJCgIDARIDEwApCggKAQgSAxUAagoJCgIICxID
FQBqCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAPAoJCgIICBIDFwA8CggKAQgSAxgA
SgoJCgIIARIDGABKCksKAgQAEgQbADoBGj8gQSBjYXJkIGZvciBwcmVzZW50aW5nIGEgY29s
bGVjdGlvbiBvZiBvcHRpb25zIHRvIHNlbGVjdCBmcm9tLgoKCgoDBAABEgMbCB4KKgoEBAAD
ABIEHQItAxocIEFuIGl0ZW0gaW4gdGhlIGNvbGxlY3Rpb24uCgoMCgUEAAMAARIDHQoYCq4B
CgYEAAMAAgASAyEEPBqeASBSZXF1aXJlZC4gVGhlIE5MVSBrZXkgdGhhdCBtYXRjaGVzIHRo
ZSBlbnRyeSBrZXkgbmFtZSBpbiB0aGUgYXNzb2NpYXRlZAogVHlwZS4gV2hlbiBpdGVtIHRh
cHBlZCwgdGhpcyBrZXkgd2lsbCBiZSBwb3N0ZWQgYmFjayBhcyBhIHNlbGVjdCBvcHRpb24K
IHBhcmFtZXRlci4KCg4KBwQAAwACAAUSAyEECgoOCgcEAAMAAgABEgMhCw4KDgoHBAADAAIA
AxIDIRESCg4KBwQAAwACAAgSAyETOwoRCgoEAAMAAgAInAgAEgMhFDoKxwEKBgQAAwACARID
JgQ+GrcBIFJlcXVpcmVkLiBUaXRsZSBvZiB0aGUgaXRlbS4gV2hlbiB0YXBwZWQsIHRoaXMg
dGV4dCB3aWxsIGJlCiBwb3N0ZWQgYmFjayB0byB0aGUgY29udmVyc2F0aW9uIHZlcmJhdGlt
IGFzIGlmIHRoZSB1c2VyIGhhZCB0eXBlZCBpdC4KIEVhY2ggdGl0bGUgbXVzdCBiZSB1bmlx
dWUgYW1vbmcgdGhlIHNldCBvZiBpdGVtcy4KCg4KBwQAAwACAQUSAyYECgoOCgcEAAMAAgEB
EgMmCxAKDgoHBAADAAIBAxIDJhMUCg4KBwQAAwACAQgSAyYVPQoRCgoEAAMAAgEInAgAEgMm
FjwKMQoGBAADAAICEgMpBEQaIiBPcHRpb25hbC4gQm9keSB0ZXh0IG9mIHRoZSBpdGVtLgoK
DgoHBAADAAICBRIDKQQKCg4KBwQAAwACAgESAykLFgoOCgcEAAMAAgIDEgMpGRoKDgoHBAAD
AAICCBIDKRtDChEKCgQAAwACAgicCAASAykcQgomCgYEAAMAAgMSAywESRoXIE9wdGlvbmFs
LiBJdGVtIGltYWdlLgoKDgoHBAADAAIDBhIDLAQVCg4KBwQAAwACAwESAywWGwoOCgcEAAMA
AgMDEgMsHh8KDgoHBAADAAIDCBIDLCBIChEKCgQAAwACAwicCAASAywhRwoxCgQEAAIAEgMw
AjwaJCBPcHRpb25hbC4gVGl0bGUgb2YgdGhlIGNvbGxlY3Rpb24uCgoMCgUEAAIABRIDMAII
CgwKBQQAAgABEgMwCQ4KDAoFBAACAAMSAzAREgoMCgUEAAIACBIDMBM7Cg8KCAQAAgAInAgA
EgMwFDoKNAoEBAACARIDMwI/GicgT3B0aW9uYWwuIFN1YnRpdGxlIG9mIHRoZSBjb2xsZWN0
aW9uLgoKDAoFBAACAQUSAzMCCAoMCgUEAAIBARIDMwkRCgwKBQQAAgEDEgMzFBUKDAoFBAAC
AQgSAzMWPgoPCggEAAIBCJwIABIDMxc9CioKBAQAAgISAzYCTRodIFJlcXVpcmVkLiBDb2xs
ZWN0aW9uIGl0ZW1zLgoKDAoFBAACAgQSAzYCCgoMCgUEAAICBhIDNgsZCgwKBQQAAgIBEgM2
Gh8KDAoFBAACAgMSAzYiIwoMCgUEAAICCBIDNiRMCg8KCAQAAgIInAgAEgM2JUsKNgoEBAAC
AxIDOQJWGikgT3B0aW9uYWwuIFR5cGUgb2YgaW1hZ2UgZGlzcGxheSBvcHRpb24uCgoMCgUE
AAIDBhIDOQIdCgwKBQQAAgMBEgM5HigKDAoFBAACAwMSAzkrLAoMCgUEAAIDCBIDOS1VCg8K
CAQAAgMInAgAEgM5LlRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt ===
    # Fields for StaticCollectionPrompt
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: items Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticCollectionPrompt.CollectionItem)
    # Field: image_fill Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt.ImageFill)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt->new({
        title => $title,
        subtitle => $subtitle,
        items => $items,
        image_fill => $image_fill,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt

A card for presenting a collection of options to select from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. Title of the collection.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Optional. Subtitle of the collection.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt::CollectionItem>)

Required. Collection items.

=item * C<< $msg->image_fill() >> / C<< $msg->image_fill($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::ImageFill>)

Optional. Type of image display option.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
