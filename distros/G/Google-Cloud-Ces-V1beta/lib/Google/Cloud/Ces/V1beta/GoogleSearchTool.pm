package Google::Cloud::Ces::V1beta::GoogleSearchTool;

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
CjBnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9nb29nbGVfc2VhcmNoX3Rvb2wucHJvdG8SF2dv
b2dsZS5jbG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
IpoDChBHb29nbGVTZWFyY2hUb29sEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIlCgtkZXNj
cmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhImCgxjb250ZXh0X3VybHMYAyADKAlC
A+BBAVILY29udGV4dFVybHMSMAoRcHJlZmVycmVkX2RvbWFpbnMYBiADKAlCA+BBAVIQcHJl
ZmVycmVkRG9tYWlucxIsCg9leGNsdWRlX2RvbWFpbnMYBCADKAlCA+BBAVIOZXhjbHVkZURv
bWFpbnMSYAoNcHJvbXB0X2NvbmZpZxgFIAEoCzI2Lmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
Lkdvb2dsZVNlYXJjaFRvb2wuUHJvbXB0Q29uZmlnQgPgQQFSDHByb21wdENvbmZpZxpcCgxQ
cm9tcHRDb25maWcSJAoLdGV4dF9wcm9tcHQYASABKAlCA+BBAVIKdGV4dFByb21wdBImCgx2
b2ljZV9wcm9tcHQYAiABKAlCA+BBAVILdm9pY2VQcm9tcHRCZQobY29tLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhQhVHb29nbGVTZWFyY2hUb29sUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNv
bS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSr0VCgYSBA4ARAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoICgEIEgMUAEQK
CQoCCAsSAxQARAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADYKCQoCCAgSAxYANgoI
CgEIEgMXADQKCQoCCAESAxcANAqxAQoCBAASBBwARAEapAEgUmVwcmVzZW50cyBhIHRvb2wg
dG8gcGVyZm9ybSBHb29nbGUgd2ViIHNlYXJjaGVzIGZvciBncm91bmRpbmcuCiBTZWUKIGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jdXN0b21lci1lbmdhZ2VtZW50LWFpL2NvbnZlcnNh
dGlvbmFsLWFnZW50cy9wcy90b29sI2dvb2dsZS1zZWFyY2guCgoKCgMEAAESAxwIGApsCgQE
AAMAEgQfAikDGl4gUHJvbXB0IHNldHRpbmdzIHVzZWQgYnkgdGhlIG1vZGVsIHdoZW4gcHJv
Y2Vzc2luZyBvciBzdW1tYXJpemluZyB0aGUKIGdvb2dsZSBzZWFyY2ggcmVzdWx0cy4KCgwK
BQQAAwABEgMfChYKsQEKBgQAAwACABIDIwREGqEBIE9wdGlvbmFsLiBEZWZpbmVzIHRoZSBw
cm9tcHQgdXNlZCBmb3IgdGhlIHN5c3RlbSBpbnN0cnVjdGlvbnMgd2hlbgogaW50ZXJhY3Rp
bmcgd2l0aCB0aGUgYWdlbnQgaW4gY2hhdCBjb252ZXJzYXRpb25zLiBJZiBub3Qgc2V0LCBk
ZWZhdWx0CiBwcm9tcHQgd2lsbCBiZSB1c2VkLgoKDgoHBAADAAIABRIDIwQKCg4KBwQAAwAC
AAESAyMLFgoOCgcEAAMAAgADEgMjGRoKDgoHBAADAAIACBIDIxtDChEKCgQAAwACAAicCAAS
AyMcQgqyAQoGBAADAAIBEgMoBEUaogEgT3B0aW9uYWwuIERlZmluZXMgdGhlIHByb21wdCB1
c2VkIGZvciB0aGUgc3lzdGVtIGluc3RydWN0aW9ucyB3aGVuCiBpbnRlcmFjdGluZyB3aXRo
IHRoZSBhZ2VudCBpbiB2b2ljZSBjb252ZXJzYXRpb25zLiBJZiBub3Qgc2V0LCBkZWZhdWx0
CiBwcm9tcHQgd2lsbCBiZSB1c2VkLgoKDgoHBAADAAIBBRIDKAQKCg4KBwQAAwACAQESAygL
FwoOCgcEAAMAAgEDEgMoGhsKDgoHBAADAAIBCBIDKBxEChEKCgQAAwACAQicCAASAygdQwou
CgQEAAIAEgMsAjsaISBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wuCgoMCgUEAAIA
BRIDLAIICgwKBQQAAgABEgMsCQ0KDAoFBAACAAMSAywQEQoMCgUEAAIACBIDLBI6Cg8KCAQA
AgAInAgAEgMsEzkKOwoEBAACARIDLwJCGi4gT3B0aW9uYWwuIERlc2NyaXB0aW9uIG9mIHRo
ZSB0b29sJ3MgcHVycG9zZS4KCgwKBQQAAgEFEgMvAggKDAoFBAACAQESAy8JFAoMCgUEAAIB
AxIDLxcYCgwKBQQAAgEIEgMvGUEKDwoIBAACAQicCAASAy8aQAqzAQoEBAACAhIDNAJMGqUB
IE9wdGlvbmFsLiBDb250ZW50IHdpbGwgYmUgZmV0Y2hlZCBkaXJlY3RseSBmcm9tIHRoZXNl
IFVSTHMgZm9yIGNvbnRleHQgYW5kCiBncm91bmRpbmcuIEV4YW1wbGU6ICJodHRwczovL2V4
YW1wbGUuY29tL3BhdGguaHRtbCIuIEEgbWF4aW11bSBvZiAyMCBVUkxzCiBhcmUgYWxsb3dl
ZC4KCgwKBQQAAgIEEgM0AgoKDAoFBAACAgUSAzQLEQoMCgUEAAICARIDNBIeCgwKBQQAAgID
EgM0ISIKDAoFBAACAggSAzQjSwoPCggEAAICCJwIABIDNCRKCp8BCgQEAAIDEgQ5AjovGpAB
IE9wdGlvbmFsLiBTcGVjaWZpZXMgZG9tYWlucyB0byByZXN0cmljdCBzZWFyY2ggcmVzdWx0
cyB0by4KIEV4YW1wbGU6ICJleGFtcGxlLmNvbSIsICJhbm90aGVyLnNpdGUiLiBBIG1heGlt
dW0gb2YgMjAgZG9tYWlucyBjYW4gYmUKIHNwZWNpZmllZC4KCgwKBQQAAgMEEgM5AgoKDAoF
BAACAwUSAzkLEQoMCgUEAAIDARIDORIjCgwKBQQAAgMDEgM5JicKDAoFBAACAwgSAzoGLgoP
CggEAAIDCJwIABIDOgctCpYBCgQEAAIEEgM/Ak8aiAEgT3B0aW9uYWwuIExpc3Qgb2YgZG9t
YWlucyB0byBiZSBleGNsdWRlZCBmcm9tIHRoZSBzZWFyY2ggcmVzdWx0cy4KIEV4YW1wbGU6
ICJleGFtcGxlLmNvbSIuCiBBIG1heGltdW0gb2YgMjAwMCBkb21haW5zIGNhbiBiZSBleGNs
dWRlZC4KCgwKBQQAAgQEEgM/AgoKDAoFBAACBAUSAz8LEQoMCgUEAAIEARIDPxIhCgwKBQQA
AgQDEgM/JCUKDAoFBAACBAgSAz8mTgoPCggEAAIECJwIABIDPydNCoEBCgQEAAIFEgNDAkoa
dCBPcHRpb25hbC4gUHJvbXB0IGluc3RydWN0aW9ucyBwYXNzZWQgdG8gcGxhbm5lciBvbiBo
b3cgdGhlIHNlYXJjaCByZXN1bHRzCiBzaG91bGQgYmUgcHJvY2Vzc2VkIGZvciB0ZXh0IGFu
ZCB2b2ljZS4KCgwKBQQAAgUGEgNDAg4KDAoFBAACBQESA0MPHAoMCgUEAAIFAxIDQx8gCgwK
BQQAAgUIEgNDIUkKDwoIBAACBQicCAASA0MiSGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool ===
    # Fields for GoogleSearchTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: context_urls Type: 9 ()
    # Field: preferred_domains Type: 9 ()
    # Field: exclude_domains Type: 9 ()
    # Field: prompt_config Type: 11 (.google.cloud.ces.v1beta.GoogleSearchTool.PromptConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::GoogleSearchTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/google_search_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::GoogleSearchTool;

    my $msg = Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool->new({
        name => $name,
        description => $description,
        context_urls => $context_urls,
        preferred_domains => $preferred_domains,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/google_search_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool::PromptConfig>)

Optional. Prompt instructions passed to planner on how the search results
should be processed for text and voice.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::GoogleSearchTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
