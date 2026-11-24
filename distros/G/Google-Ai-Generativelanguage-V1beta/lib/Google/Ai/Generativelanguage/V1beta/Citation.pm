package Google::Ai::Generativelanguage::V1beta::Citation;

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
CjJnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9jaXRhdGlvbi5wcm90bxIj
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8icgoQQ2l0YXRpb25NZXRhZGF0YRJeChBjaXRhdGlvbl9zb3VyY2Vz
GAEgAygLMjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ2l0YXRpb25T
b3VyY2VSD2NpdGF0aW9uU291cmNlcyLUAQoOQ2l0YXRpb25Tb3VyY2USKQoLc3RhcnRfaW5k
ZXgYASABKAVCA+BBAUgAUgpzdGFydEluZGV4iAEBEiUKCWVuZF9pbmRleBgCIAEoBUID4EEB
SAFSCGVuZEluZGV4iAEBEhoKA3VyaRgDIAEoCUID4EEBSAJSA3VyaYgBARIiCgdsaWNlbnNl
GAQgASgJQgPgQQFIA1IHbGljZW5zZYgBAUIOCgxfc3RhcnRfaW5kZXhCDAoKX2VuZF9pbmRl
eEIGCgRfdXJpQgoKCF9saWNlbnNlQpkBCidjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWJldGFCDUNpdGF0aW9uUHJvdG9QAVpdY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9n
ZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVy
YXRpdmVsYW5ndWFnZXBiSoQOCgYSBA4AMgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoICgEIEgMUAHQKCQoCCAsSAxQAdAoICgEI
EgMVACIKCQoCCAoSAxUAIgoICgEIEgMWAC4KCQoCCAgSAxYALgoICgEIEgMXAEAKCQoCCAES
AxcAQApJCgIEABIEGgAdARo9IEEgY29sbGVjdGlvbiBvZiBzb3VyY2UgYXR0cmlidXRpb25z
IGZvciBhIHBpZWNlIG9mIGNvbnRlbnQuCgoKCgMEAAESAxoIGAo8CgQEAAIAEgMcAi8aLyBD
aXRhdGlvbnMgdG8gc291cmNlcyBmb3IgYSBzcGVjaWZpYyByZXNwb25zZS4KCgwKBQQAAgAE
EgMcAgoKDAoFBAACAAYSAxwLGQoMCgUEAAIAARIDHBoqCgwKBQQAAgADEgMcLS4KSgoCBAES
BCAAMgEaPiBBIGNpdGF0aW9uIHRvIGEgc291cmNlIGZvciBhIHBvcnRpb24gb2YgYSBzcGVj
aWZpYyByZXNwb25zZS4KCgoKAwQBARIDIAgWCp0BCgQEAQIAEgMlAkoajwEgT3B0aW9uYWwu
IFN0YXJ0IG9mIHNlZ21lbnQgb2YgdGhlIHJlc3BvbnNlIHRoYXQgaXMgYXR0cmlidXRlZCB0
byB0aGlzCiBzb3VyY2UuCgogSW5kZXggaW5kaWNhdGVzIHRoZSBzdGFydCBvZiB0aGUgc2Vn
bWVudCwgbWVhc3VyZWQgaW4gYnl0ZXMuCgoMCgUEAQIABBIDJQIKCgwKBQQBAgAFEgMlCxAK
DAoFBAECAAESAyURHAoMCgUEAQIAAxIDJR8gCgwKBQQBAgAIEgMlIUkKDwoIBAECAAicCAAS
AyUiSApCCgQEAQIBEgMoAkgaNSBPcHRpb25hbC4gRW5kIG9mIHRoZSBhdHRyaWJ1dGVkIHNl
Z21lbnQsIGV4Y2x1c2l2ZS4KCgwKBQQBAgEEEgMoAgoKDAoFBAECAQUSAygLEAoMCgUEAQIB
ARIDKBEaCgwKBQQBAgEDEgMoHR4KDAoFBAECAQgSAygfRwoPCggEAQIBCJwIABIDKCBGClYK
BAQBAgISAysCQxpJIE9wdGlvbmFsLiBVUkkgdGhhdCBpcyBhdHRyaWJ1dGVkIGFzIGEgc291
cmNlIGZvciBhIHBvcnRpb24gb2YgdGhlIHRleHQuCgoMCgUEAQICBBIDKwIKCgwKBQQBAgIF
EgMrCxEKDAoFBAECAgESAysSFQoMCgUEAQICAxIDKxgZCgwKBQQBAgIIEgMrGkIKDwoIBAEC
AgicCAASAysbQQqUAQoEBAECAxIDMQJHGoYBIE9wdGlvbmFsLiBMaWNlbnNlIGZvciB0aGUg
R2l0SHViIHByb2plY3QgdGhhdCBpcyBhdHRyaWJ1dGVkIGFzIGEgc291cmNlIGZvcgogc2Vn
bWVudC4KCiBMaWNlbnNlIGluZm8gaXMgcmVxdWlyZWQgZm9yIGNvZGUgY2l0YXRpb25zLgoK
DAoFBAECAwQSAzECCgoMCgUEAQIDBRIDMQsRCgwKBQQBAgMBEgMxEhkKDAoFBAECAwMSAzEc
HQoMCgUEAQIDCBIDMR5GCg8KCAQBAgMInAgAEgMxH0ViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::Citation::CitationMetadata ===
    # Fields for CitationMetadata
    # Field: citation_sources Type: 11 (.google.ai.generativelanguage.v1beta.CitationSource)

# === Message: Google::Ai::Generativelanguage::V1beta::Citation::CitationSource ===
    # Fields for CitationSource
    # Field: start_index Type: 5 ()
    # Field: end_index Type: 5 ()
    # Field: uri Type: 9 ()
    # Field: license Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Citation - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/citation.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Citation;

    my $msg = Google::Ai::Generativelanguage::V1beta::Citation::CitationMetadata->new({
        citation_sources => $citation_sources,
    });

    # Read or update a field
    my $val = $msg->citation_sources();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::Citation::CitationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/citation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::Citation::CitationMetadata

A collection of source attributions for a piece of content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->citation_sources() >> / C<< $msg->citation_sources($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Citation::CitationSource>)

Citations to sources for a specific response.

=back

=head2 Google::Ai::Generativelanguage::V1beta::Citation::CitationSource

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::Citation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
