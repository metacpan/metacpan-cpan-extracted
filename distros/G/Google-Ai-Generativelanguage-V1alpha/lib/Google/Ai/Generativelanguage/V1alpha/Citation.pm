package Google::Ai::Generativelanguage::V1alpha::Citation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvY2l0YXRpb24ucHJvdG8S
JGdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90byJzChBDaXRhdGlvbk1ldGFkYXRhEl8KEGNpdGF0aW9uX3NvdXJj
ZXMYASADKAsyNC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ2l0YXRp
b25Tb3VyY2VSD2NpdGF0aW9uU291cmNlcyLUAQoOQ2l0YXRpb25Tb3VyY2USKQoLc3RhcnRf
aW5kZXgYASABKAVCA+BBAUgAUgpzdGFydEluZGV4iAEBEiUKCWVuZF9pbmRleBgCIAEoBUID
4EEBSAFSCGVuZEluZGV4iAEBEhoKA3VyaRgDIAEoCUID4EEBSAJSA3VyaYgBARIiCgdsaWNl
bnNlGAQgASgJQgPgQQFIA1IHbGljZW5zZYgBAUIOCgxfc3RhcnRfaW5kZXhCDAoKX2VuZF9p
bmRleEIGCgRfdXJpQgoKCF9saWNlbnNlQpsBCihjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWFscGhhQg1DaXRhdGlvblByb3RvUAFaXmNsb3VkLmdvb2dsZS5jb20vZ28v
YWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYWxwaGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7
Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKhA4KBhIEDgAyAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCggKAQgSAxQAdQoJCgIICxIDFAB1
CggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYALgoJCgIICBIDFgAuCggKAQgSAxcAQQoJ
CgIIARIDFwBBCkkKAgQAEgQaAB0BGj0gQSBjb2xsZWN0aW9uIG9mIHNvdXJjZSBhdHRyaWJ1
dGlvbnMgZm9yIGEgcGllY2Ugb2YgY29udGVudC4KCgoKAwQAARIDGggYCjwKBAQAAgASAxwC
LxovIENpdGF0aW9ucyB0byBzb3VyY2VzIGZvciBhIHNwZWNpZmljIHJlc3BvbnNlLgoKDAoF
BAACAAQSAxwCCgoMCgUEAAIABhIDHAsZCgwKBQQAAgABEgMcGioKDAoFBAACAAMSAxwtLgpK
CgIEARIEIAAyARo+IEEgY2l0YXRpb24gdG8gYSBzb3VyY2UgZm9yIGEgcG9ydGlvbiBvZiBh
IHNwZWNpZmljIHJlc3BvbnNlLgoKCgoDBAEBEgMgCBYKnQEKBAQBAgASAyUCShqPASBPcHRp
b25hbC4gU3RhcnQgb2Ygc2VnbWVudCBvZiB0aGUgcmVzcG9uc2UgdGhhdCBpcyBhdHRyaWJ1
dGVkIHRvIHRoaXMKIHNvdXJjZS4KCiBJbmRleCBpbmRpY2F0ZXMgdGhlIHN0YXJ0IG9mIHRo
ZSBzZWdtZW50LCBtZWFzdXJlZCBpbiBieXRlcy4KCgwKBQQBAgAEEgMlAgoKDAoFBAECAAUS
AyULEAoMCgUEAQIAARIDJREcCgwKBQQBAgADEgMlHyAKDAoFBAECAAgSAyUhSQoPCggEAQIA
CJwIABIDJSJICkIKBAQBAgESAygCSBo1IE9wdGlvbmFsLiBFbmQgb2YgdGhlIGF0dHJpYnV0
ZWQgc2VnbWVudCwgZXhjbHVzaXZlLgoKDAoFBAECAQQSAygCCgoMCgUEAQIBBRIDKAsQCgwK
BQQBAgEBEgMoERoKDAoFBAECAQMSAygdHgoMCgUEAQIBCBIDKB9HCg8KCAQBAgEInAgAEgMo
IEYKVgoEBAECAhIDKwJDGkkgT3B0aW9uYWwuIFVSSSB0aGF0IGlzIGF0dHJpYnV0ZWQgYXMg
YSBzb3VyY2UgZm9yIGEgcG9ydGlvbiBvZiB0aGUgdGV4dC4KCgwKBQQBAgIEEgMrAgoKDAoF
BAECAgUSAysLEQoMCgUEAQICARIDKxIVCgwKBQQBAgIDEgMrGBkKDAoFBAECAggSAysaQgoP
CggEAQICCJwIABIDKxtBCpQBCgQEAQIDEgMxAkcahgEgT3B0aW9uYWwuIExpY2Vuc2UgZm9y
IHRoZSBHaXRIdWIgcHJvamVjdCB0aGF0IGlzIGF0dHJpYnV0ZWQgYXMgYSBzb3VyY2UgZm9y
CiBzZWdtZW50LgoKIExpY2Vuc2UgaW5mbyBpcyByZXF1aXJlZCBmb3IgY29kZSBjaXRhdGlv
bnMuCgoMCgUEAQIDBBIDMQIKCgwKBQQBAgMFEgMxCxEKDAoFBAECAwESAzESGQoMCgUEAQID
AxIDMRwdCgwKBQQBAgMIEgMxHkYKDwoIBAECAwicCAASAzEfRWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata ===
    # Fields for CitationMetadata
    # Field: citation_sources Type: 11 (.google.ai.generativelanguage.v1alpha.CitationSource)

# === Message: Google::Ai::Generativelanguage::V1alpha::Citation::CitationSource ===
    # Fields for CitationSource
    # Field: start_index Type: 5 ()
    # Field: end_index Type: 5 ()
    # Field: uri Type: 9 ()
    # Field: license Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Citation - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/citation.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::Citation;

    my $msg = Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata->new({
        citation_sources => $citation_sources,
    });

    # Read or update a field
    my $val = $msg->citation_sources();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/citation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata

A collection of source attributions for a piece of content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->citation_sources() >> / C<< $msg->citation_sources($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Citation::CitationSource>)

Citations to sources for a specific response.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Citation::CitationSource

A citation to a source for a portion of a specific response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_index() >> / C<< $msg->start_index($value) >>

Type: C<Int32>

Optional. Start of segment of the response that is attributed to this
source.

Index indicates the start of the segment, measured in bytes.

=item * C<< $msg->end_index() >> / C<< $msg->end_index($value) >>

Type: C<Int32>

Optional. End of the attributed segment, exclusive.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Optional. URI that is attributed as a source for a portion of the text.

=item * C<< $msg->license() >> / C<< $msg->license($value) >>

Type: C<String>

Optional. License for the GitHub project that is attributed as a source for
segment.

License info is required for code citations.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::Citation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
