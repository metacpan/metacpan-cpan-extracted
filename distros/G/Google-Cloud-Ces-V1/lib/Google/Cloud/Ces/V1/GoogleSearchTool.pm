package Google::Cloud::Ces::V1::GoogleSearchTool;

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
Cixnb29nbGUvY2xvdWQvY2VzL3YxL2dvb2dsZV9zZWFyY2hfdG9vbC5wcm90bxITZ29vZ2xl
LmNsb3VkLmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKWAwoQR29v
Z2xlU2VhcmNoVG9vbBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSJQoLZGVzY3JpcHRpb24Y
AiABKAlCA+BBAVILZGVzY3JpcHRpb24SJgoMY29udGV4dF91cmxzGAMgAygJQgPgQQFSC2Nv
bnRleHRVcmxzEjAKEXByZWZlcnJlZF9kb21haW5zGAYgAygJQgPgQQFSEHByZWZlcnJlZERv
bWFpbnMSLAoPZXhjbHVkZV9kb21haW5zGAQgAygJQgPgQQFSDmV4Y2x1ZGVEb21haW5zElwK
DXByb21wdF9jb25maWcYBSABKAsyMi5nb29nbGUuY2xvdWQuY2VzLnYxLkdvb2dsZVNlYXJj
aFRvb2wuUHJvbXB0Q29uZmlnQgPgQQFSDHByb21wdENvbmZpZxpcCgxQcm9tcHRDb25maWcS
JAoLdGV4dF9wcm9tcHQYASABKAlCA+BBAVIKdGV4dFByb21wdBImCgx2b2ljZV9wcm9tcHQY
AiABKAlCA+BBAVILdm9pY2VQcm9tcHRCXQoXY29tLmdvb2dsZS5jbG91ZC5jZXMudjFCFUdv
b2dsZVNlYXJjaFRvb2xQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MS9j
ZXNwYjtjZXNwYkq9FQoGEgQOAEQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCAoBCBIDFABACgkKAggLEgMUAEAKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgA2CgkKAggIEgMWADYKCAoBCBIDFwAwCgkKAggBEgMXADAK
sQEKAgQAEgQcAEQBGqQBIFJlcHJlc2VudHMgYSB0b29sIHRvIHBlcmZvcm0gR29vZ2xlIHdl
YiBzZWFyY2hlcyBmb3IgZ3JvdW5kaW5nLgogU2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vY3VzdG9tZXItZW5nYWdlbWVudC1haS9jb252ZXJzYXRpb25hbC1hZ2VudHMvcHMvdG9v
bCNnb29nbGUtc2VhcmNoLgoKCgoDBAABEgMcCBgKbAoEBAADABIEHwIpAxpeIFByb21wdCBz
ZXR0aW5ncyB1c2VkIGJ5IHRoZSBtb2RlbCB3aGVuIHByb2Nlc3Npbmcgb3Igc3VtbWFyaXpp
bmcgdGhlCiBnb29nbGUgc2VhcmNoIHJlc3VsdHMuCgoMCgUEAAMAARIDHwoWCrEBCgYEAAMA
AgASAyMERBqhASBPcHRpb25hbC4gRGVmaW5lcyB0aGUgcHJvbXB0IHVzZWQgZm9yIHRoZSBz
eXN0ZW0gaW5zdHJ1Y3Rpb25zIHdoZW4KIGludGVyYWN0aW5nIHdpdGggdGhlIGFnZW50IGlu
IGNoYXQgY29udmVyc2F0aW9ucy4gSWYgbm90IHNldCwgZGVmYXVsdAogcHJvbXB0IHdpbGwg
YmUgdXNlZC4KCg4KBwQAAwACAAUSAyMECgoOCgcEAAMAAgABEgMjCxYKDgoHBAADAAIAAxID
IxkaCg4KBwQAAwACAAgSAyMbQwoRCgoEAAMAAgAInAgAEgMjHEIKsgEKBgQAAwACARIDKARF
GqIBIE9wdGlvbmFsLiBEZWZpbmVzIHRoZSBwcm9tcHQgdXNlZCBmb3IgdGhlIHN5c3RlbSBp
bnN0cnVjdGlvbnMgd2hlbgogaW50ZXJhY3Rpbmcgd2l0aCB0aGUgYWdlbnQgaW4gdm9pY2Ug
Y29udmVyc2F0aW9ucy4gSWYgbm90IHNldCwgZGVmYXVsdAogcHJvbXB0IHdpbGwgYmUgdXNl
ZC4KCg4KBwQAAwACAQUSAygECgoOCgcEAAMAAgEBEgMoCxcKDgoHBAADAAIBAxIDKBobCg4K
BwQAAwACAQgSAygcRAoRCgoEAAMAAgEInAgAEgMoHUMKLgoEBAACABIDLAI7GiEgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSB0b29sLgoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkN
CgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSOgoPCggEAAIACJwIABIDLBM5CjsKBAQAAgES
Ay8CQhouIE9wdGlvbmFsLiBEZXNjcmlwdGlvbiBvZiB0aGUgdG9vbCdzIHB1cnBvc2UuCgoM
CgUEAAIBBRIDLwIICgwKBQQAAgEBEgMvCRQKDAoFBAACAQMSAy8XGAoMCgUEAAIBCBIDLxlB
Cg8KCAQAAgEInAgAEgMvGkAKswEKBAQAAgISAzQCTBqlASBPcHRpb25hbC4gQ29udGVudCB3
aWxsIGJlIGZldGNoZWQgZGlyZWN0bHkgZnJvbSB0aGVzZSBVUkxzIGZvciBjb250ZXh0IGFu
ZAogZ3JvdW5kaW5nLiBFeGFtcGxlOiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9wYXRoLmh0bWwi
LiBBIG1heGltdW0gb2YgMjAgVVJMcwogYXJlIGFsbG93ZWQuCgoMCgUEAAICBBIDNAIKCgwK
BQQAAgIFEgM0CxEKDAoFBAACAgESAzQSHgoMCgUEAAICAxIDNCEiCgwKBQQAAgIIEgM0I0sK
DwoIBAACAgicCAASAzQkSgqfAQoEBAACAxIEOQI6LxqQASBPcHRpb25hbC4gU3BlY2lmaWVz
IGRvbWFpbnMgdG8gcmVzdHJpY3Qgc2VhcmNoIHJlc3VsdHMgdG8uCiBFeGFtcGxlOiAiZXhh
bXBsZS5jb20iLCAiYW5vdGhlci5zaXRlIi4gQSBtYXhpbXVtIG9mIDIwIGRvbWFpbnMgY2Fu
IGJlCiBzcGVjaWZpZWQuCgoMCgUEAAIDBBIDOQIKCgwKBQQAAgMFEgM5CxEKDAoFBAACAwES
AzkSIwoMCgUEAAIDAxIDOSYnCgwKBQQAAgMIEgM6Bi4KDwoIBAACAwicCAASAzoHLQqWAQoE
BAACBBIDPwJPGogBIE9wdGlvbmFsLiBMaXN0IG9mIGRvbWFpbnMgdG8gYmUgZXhjbHVkZWQg
ZnJvbSB0aGUgc2VhcmNoIHJlc3VsdHMuCiBFeGFtcGxlOiAiZXhhbXBsZS5jb20iLgogQSBt
YXhpbXVtIG9mIDIwMDAgZG9tYWlucyBjYW4gYmUgZXhjbHVkZWQuCgoMCgUEAAIEBBIDPwIK
CgwKBQQAAgQFEgM/CxEKDAoFBAACBAESAz8SIQoMCgUEAAIEAxIDPyQlCgwKBQQAAgQIEgM/
Jk4KDwoIBAACBAicCAASAz8nTQqBAQoEBAACBRIDQwJKGnQgT3B0aW9uYWwuIFByb21wdCBp
bnN0cnVjdGlvbnMgcGFzc2VkIHRvIHBsYW5uZXIgb24gaG93IHRoZSBzZWFyY2ggcmVzdWx0
cwogc2hvdWxkIGJlIHByb2Nlc3NlZCBmb3IgdGV4dCBhbmQgdm9pY2UuCgoMCgUEAAIFBhID
QwIOCgwKBQQAAgUBEgNDDxwKDAoFBAACBQMSA0MfIAoMCgUEAAIFCBIDQyFJCg8KCAQAAgUI
nAgAEgNDIkhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool ===
    # Fields for GoogleSearchTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: context_urls Type: 9 ()
    # Field: preferred_domains Type: 9 ()
    # Field: exclude_domains Type: 9 ()
    # Field: prompt_config Type: 11 (.google.cloud.ces.v1.GoogleSearchTool.PromptConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::GoogleSearchTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/google_search_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::GoogleSearchTool;

    my $msg = Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool->new({
        name => $name,
        description => $description,
        context_urls => $context_urls,
        preferred_domains => $preferred_domains,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/google_search_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool

Represents a tool to perform Google web searches for grounding.
See
https://cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool#google-search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the tool's purpose.

=item * C<< $msg->context_urls() >> / C<< $msg->context_urls($value) >>

Type: C<String>

Optional. Content will be fetched directly from these URLs for context and
grounding. Example: "https://example.com/path.html". A maximum of 20 URLs
are allowed.

=item * C<< $msg->preferred_domains() >> / C<< $msg->preferred_domains($value) >>

Type: C<String>

Optional. Specifies domains to restrict search results to.
Example: "example.com", "another.site". A maximum of 20 domains can be
specified.

=item * C<< $msg->exclude_domains() >> / C<< $msg->exclude_domains($value) >>

Type: C<String>

Optional. List of domains to be excluded from the search results.
Example: "example.com".
A maximum of 2000 domains can be excluded.

=item * C<< $msg->prompt_config() >> / C<< $msg->prompt_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool::PromptConfig>)

Optional. Prompt instructions passed to planner on how the search results
should be processed for text and voice.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::GoogleSearchTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
