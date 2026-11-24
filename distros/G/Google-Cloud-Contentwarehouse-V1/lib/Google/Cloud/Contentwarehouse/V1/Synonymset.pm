package Google::Cloud::Contentwarehouse::V1::Synonymset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9zeW5vbnltc2V0LnByb3RvEiBn
b29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90byKdAgoKU3lub255bVNldBISCgRuYW1lGAEgASgJUgRuYW1lEhgKB2NvbnRleHQYAiAB
KAlSB2NvbnRleHQSUAoIc3lub255bXMYAyADKAsyNC5nb29nbGUuY2xvdWQuY29udGVudHdh
cmVob3VzZS52MS5TeW5vbnltU2V0LlN5bm9ueW1SCHN5bm9ueW1zGh8KB1N5bm9ueW0SFAoF
d29yZHMYASADKAlSBXdvcmRzOm7qQWsKKmNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5j
b20vU3lub255bVNldBI9cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3N5bm9ueW1TZXRzL3tjb250ZXh0fUL3AQokY29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2Fy
ZWhvdXNlLnYxQg9TeW5vbnltU2V0UHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9jb250
ZW50d2FyZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJlaG91c2VwYjtjb250ZW50d2FyZWhvdXNl
cGKqAiBHb29nbGUuQ2xvdWQuQ29udGVudFdhcmVob3VzZS5WMcoCIEdvb2dsZVxDbG91ZFxD
b250ZW50V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpDbG91ZDo6Q29udGVudFdhcmVob3VzZTo6
VjFKxQ4KBhIEDgA8AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAKQoJCgIDABIDEgAjCggKAQgSAxQAPQoJCgIIJRIDFAA9CggKAQgSAxUAZwoJCgIICxID
FQBnCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgA
PQoJCgIIARIDGAA9CggKAQgSAxkAPQoJCgIIKRIDGQA9CggKAQgSAxoAPAoJCgIILRIDGgA8
CpACCgIEABIEIgA8ARqDAiBSZXByZXNlbnRzIGEgbGlzdCBvZiBzeW5vbnltcyBmb3IgYSBn
aXZlbiBjb250ZXh0LgogRm9yIGV4YW1wbGUgYSBjb250ZXh0ICJzYWxlcyIgY291bGQgY29u
dGFpbjoKIFN5bm9ueW0gMTogc2FsZSwgaW52b2ljZSwgYmlsbCwgb3JkZXIKIFN5bm9ueW0g
MjogbW9uZXksIGNyZWRpdCwgZmluYW5jZSwgcGF5bWVudAogU3lub255bSAzOiBzaGlwcGlu
ZywgZnJlaWdodCwgdHJhbnNwb3J0CiBFYWNoIFN5bm9ueW1TZXRzIHNob3VsZCBiZSBkaXNq
b2ludAoKCgoDBAABEgMiCBIKCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECm0KBAQAAwAS
BCoCLQMaXyBSZXByZXNlbnRzIGEgbGlzdCBvZiB3b3JkcyBnaXZlbiBieSB0aGUgY3VzdG9t
ZXIKIEFsbCB0aGVzZSB3b3JkcyBhcmUgc3lub255bXMgb2YgZWFjaCBvdGhlci4KCgwKBQQA
AwABEgMqChEKOAoGBAADAAIAEgMsBB4aKSBGb3IgZXhhbXBsZTogc2FsZSwgaW52b2ljZSwg
YmlsbCwgb3JkZXIKCg4KBwQAAwACAAQSAywEDAoOCgcEAAMAAgAFEgMsDRMKDgoHBAADAAIA
ARIDLBQZCg4KBwQAAwACAAMSAywcHQqvAQoEBAACABIDMwISGqEBIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBTeW5vbnltU2V0CiBUaGlzIGlzIG1hbmRhdG9yeSBmb3IgZ29vZ2xlLmFw
aS5yZXNvdXJjZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vc3lub255bVNldHMve2NvbnRleHR9LgoKDAoFBAACAAUSAzMCCAoM
CgUEAAIAARIDMwkNCgwKBQQAAgADEgMzEBEKsQEKBAQAAgESAzgCFRqjASBUaGlzIGlzIGEg
ZnJlZWZvcm0gZmllbGQuIEV4YW1wbGUgY29udGV4dHMgY2FuIGJlICJzYWxlcywiICJlbmdp
bmVlcmluZywiCiAicmVhbCBlc3RhdGUsIiAiYWNjb3VudGluZywiIGV0Yy4KIFRoZSBjb250
ZXh0IGNhbiBiZSBzdXBwbGllZCBkdXJpbmcgc2VhcmNoIHJlcXVlc3RzLgoKDAoFBAACAQUS
AzgCCAoMCgUEAAIBARIDOAkQCgwKBQQAAgEDEgM4ExQKMAoEBAACAhIDOwIgGiMgTGlzdCBv
ZiBTeW5vbnltcyBmb3IgdGhlIGNvbnRleHQuCgoMCgUEAAICBBIDOwIKCgwKBQQAAgIGEgM7
CxIKDAoFBAACAgESAzsTGwoMCgUEAAICAxIDOx4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet ===
    # Fields for SynonymSet
    # Field: name Type: 9 ()
    # Field: context Type: 9 ()
    # Field: synonyms Type: 11 (.google.cloud.contentwarehouse.v1.SynonymSet.Synonym)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Synonymset - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/synonymset.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Synonymset;

    my $msg = Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet->new({
        name => $name,
        context => $context,
        synonyms => $synonyms,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/synonymset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet

Represents a list of synonyms for a given context.
For example a context "sales" could contain:
Synonym 1: sale, invoice, bill, order
Synonym 2: money, credit, finance, payment
Synonym 3: shipping, freight, transport
Each SynonymSets should be disjoint

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the SynonymSet
This is mandatory for google.api.resource.
Format:
projects/{project_number}/locations/{location}/synonymSets/{context}.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<String>

This is a freeform field. Example contexts can be "sales," "engineering,"
"real estate," "accounting," etc.
The context can be supplied during search requests.

=item * C<< $msg->synonyms() >> / C<< $msg->synonyms($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet::Synonym>)

List of Synonyms for the context.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Synonymset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
