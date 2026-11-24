package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cltnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfY29sbGVjdGlvbl9icm93c2VfcHJvbXB0LnByb3RvEi1nb29nbGUuYWN0aW9u
cy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQaT2dvb2dsZS9hY3Rpb25zL3Nkay92
Mi9pbnRlcmFjdGlvbm1vZGVsL3Byb21wdC9jb250ZW50L3N0YXRpY19pbWFnZV9wcm9tcHQu
cHJvdG8aTmdvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3Byb21wdC9j
b250ZW50L3N0YXRpY19saW5rX3Byb21wdC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90byKsBAocU3RhdGljQ29sbGVjdGlvbkJyb3dzZVByb21wdBJ2CgVpdGVtcxgB
IAMoCzJgLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdC5T
dGF0aWNDb2xsZWN0aW9uQnJvd3NlUHJvbXB0LkNvbGxlY3Rpb25Ccm93c2VJdGVtUgVpdGVt
cxJpCgppbWFnZV9maWxsGAIgASgOMkouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0
aW9ubW9kZWwucHJvbXB0LlN0YXRpY0ltYWdlUHJvbXB0LkltYWdlRmlsbFIJaW1hZ2VGaWxs
GqgCChRDb2xsZWN0aW9uQnJvd3NlSXRlbRIZCgV0aXRsZRgBIAEoCUID4EECUgV0aXRsZRIg
CgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SFgoGZm9vdGVyGAMgASgJUgZmb290
ZXISVgoFaW1hZ2UYBCABKAsyQC5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25t
b2RlbC5wcm9tcHQuU3RhdGljSW1hZ2VQcm9tcHRSBWltYWdlEmMKD29wZW5fdXJpX2FjdGlv
bhgFIAEoCzI2Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21w
dC5PcGVuVXJsQgPgQQJSDW9wZW5VcmlBY3Rpb25CrQEKMWNvbS5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHRCIVN0YXRpY0NvbGxlY3Rpb25Ccm93c2VQ
cm9tcHRQcm90b1ABWlNnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2Fj
dGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0O3Byb21wdErTDgoGEgQOADcB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA2CgkKAgMAEgMS
AFkKCQoCAwESAxMAWAoJCgIDAhIDFAApCggKAQgSAxYAagoJCgIICxIDFgBqCggKAQgSAxcA
IgoJCgIIChIDFwAiCggKAQgSAxgAQgoJCgIICBIDGABCCggKAQgSAxkASgoJCgIIARIDGQBK
CqMBCgIEABIEHQA3ARqWASBQcmVzZW50cyBhIHNldCBvZiB3ZWIgZG9jdW1lbnRzIGFzIGEg
Y29sbGVjdGlvbiBvZiBsYXJnZS10aWxlIGl0ZW1zLiBJdGVtcwogbWF5IGJlIHNlbGVjdGVk
IHRvIGxhdW5jaCB0aGVpciBhc3NvY2lhdGVkIHdlYiBkb2N1bWVudCBpbiBhIHdlYiB2aWV3
ZXIuCgoKCgMEAAESAx0IJAonCgQEAAMAEgQfAi8DGhkgSXRlbSBpbiB0aGUgY29sbGVjdGlv
bi4KCgwKBQQAAwABEgMfCh4KOAoGBAADAAIAEgMhBD4aKSBSZXF1aXJlZC4gVGl0bGUgb2Yg
dGhlIGNvbGxlY3Rpb24gaXRlbS4KCg4KBwQAAwACAAUSAyEECgoOCgcEAAMAAgABEgMhCxAK
DgoHBAADAAIAAxIDIRMUCg4KBwQAAwACAAgSAyEVPQoRCgoEAAMAAgAInAgAEgMhFjwKNAoG
BAADAAIBEgMkBBsaJSBEZXNjcmlwdGlvbiBvZiB0aGUgY29sbGVjdGlvbiBpdGVtLgoKDgoH
BAADAAIBBRIDJAQKCg4KBwQAAwACAQESAyQLFgoOCgcEAAMAAgEDEgMkGRoKiAEKBgQAAwAC
AhIDKAQWGnkgRm9vdGVyIHRleHQgZm9yIHRoZSBjb2xsZWN0aW9uIGl0ZW0sIGRpc3BsYXll
ZCBiZWxvdyB0aGUgZGVzY3JpcHRpb24uCiBTaW5nbGUgbGluZSBvZiB0ZXh0LCB0cnVuY2F0
ZWQgd2l0aCBhbiBlbGxpcHNpcy4KCg4KBwQAAwACAgUSAygECgoOCgcEAAMAAgIBEgMoCxEK
DgoHBAADAAICAxIDKBQVCi8KBgQAAwACAxIDKwQgGiAgSW1hZ2UgZm9yIHRoZSBjb2xsZWN0
aW9uIGl0ZW0uCgoOCgcEAAMAAgMGEgMrBBUKDgoHBAADAAIDARIDKxYbCg4KBwQAAwACAwMS
AyseHwo8CgYEAAMAAgQSAy4ESRotIFJlcXVpcmVkLiBVUkkgdG8gb3BlbiBpZiB0aGUgaXRl
bSBzZWxlY3RlZC4KCg4KBwQAAwACBAYSAy4ECwoOCgcEAAMAAgQBEgMuDBsKDgoHBAADAAIE
AxIDLh4fCg4KBwQAAwACBAgSAy4gSAoRCgoEAAMAAgQInAgAEgMuIUcKXQoEBAACABIDMwIq
GlAgSXRlbXMgaW4gdGhlIGJyb3dzZSBjb2xsZWN0aW9uLiBUaGUgbGlzdCBzaXplIHNob3Vs
ZCBiZSBpbiB0aGUgcmFuZ2UgWzIsCiAxMF0uCgoMCgUEAAIABBIDMwIKCgwKBQQAAgAGEgMz
Cx8KDAoFBAACAAESAzMgJQoMCgUEAAIAAxIDMygpCkEKBAQAAgESAzYCLRo0IEltYWdlIGRp
c3BsYXkgb3B0aW9uIGZvciBpbWFnZXMgaW4gdGhlIGNvbGxlY3Rpb24uCgoMCgUEAAIBBhID
NgIdCgwKBQQAAgEBEgM2HigKDAoFBAACAQMSAzYrLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt ===
    # Fields for StaticCollectionBrowsePrompt
    # Field: items Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticCollectionBrowsePrompt.CollectionBrowseItem)
    # Field: image_fill Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt.ImageFill)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_browse_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt->new({
        items => $items,
        image_fill => $image_fill,
    });

    # Read or update a field
    my $val = $msg->items();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_collection_browse_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt

Presents a set of web documents as a collection of large-tile items. Items
may be selected to launch their associated web document in a web viewer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt::CollectionBrowseItem>)

Items in the browse collection. The list size should be in the range [2,
10].

=item * C<< $msg->image_fill() >> / C<< $msg->image_fill($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::ImageFill>)

Image display option for images in the collection.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
