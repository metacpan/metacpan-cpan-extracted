package Google::Cloud::Discoveryengine::V1beta::SampleQuerySet;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYW1wbGVfcXVlcnlfc2V0
LnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK1AgoOU2FtcGxlUXVlcnlTZXQSFwoEbmFt
ZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5
TmFtZRJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRpb246fupB
ewotZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5U2V0Ekpwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2FtcGxlUXVlcnlTZXRzL3tz
YW1wbGVfcXVlcnlfc2V0fUKaAgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhQhNTYW1wbGVRdWVyeVNldFByb3RvUAFaUWNsb3VkLmdvb2dsZS5jb20vZ28vZGlz
Y292ZXJ5ZW5naW5lL2FwaXYxYmV0YS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3Zlcnllbmdp
bmVwYqICD0RJU0NPVkVSWUVOR0lORaoCI0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUu
VjFCZXRhygIjR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWJldGHqAiZHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYmV0YUqSDwoGEgQOAD8BCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAApCggKAQgSAxYAQAoJCgIIJRIDFgBACggKAQgSAxcAaAoJCgIICxIDFwBo
CggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANAoJCgIICBIDGQA0CggKAQgSAxoAQAoJ
CgIIARIDGgBACggKAQgSAxsALQoJCgIIJBIDGwAtCggKAQgSAxwAQAoJCgIIKRIDHABACggK
AQgSAx0APwoJCgIILRIDHQA/CooBCgIEABIEIQA/ARp+IEEgU2FtcGxlUXVlcnlTZXQgaXMg
dGhlIHBhcmVudCByZXNvdXJjZSBvZiBTYW1wbGVRdWVyeSwgYW5kIGNvbnRhaW5zIHRoZQog
Y29uZmlndXJhdGlvbnMgc2hhcmVkIGJ5IGFsbCBTYW1wbGVRdWVyeSB1bmRlciBpdC4KCgoK
AwQAARIDIQgWCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAq2AgoEBAACABIDLgI9GqgC
IElkZW50aWZpZXIuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlCiBbU2FtcGxlUXVl
cnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5
U2V0XSwgaW4KIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2FtcGxlUXVlcnlTZXRzL3tzYW1wbGVfcXVlcnlfc2V0fWAuCgogVGhp
cyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBs
aW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAy4CCAoMCgUEAAIAARIDLgkN
CgwKBQQAAgADEgMuEBEKDAoFBAACAAgSAy4SPAoPCggEAAIACJwIABIDLhM7CpABCgQEAAIB
EgM0AkMaggEgUmVxdWlyZWQuIFRoZSBzYW1wbGUgcXVlcnkgc2V0IGRpc3BsYXkgbmFtZS4K
CiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVu
Z3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4KCgwKBQQAAgEFEgM0AggKDAoFBAACAQES
AzQJFQoMCgUEAAIBAxIDNBgZCgwKBQQAAgEIEgM0GkIKDwoIBAACAQicCAASAzQbQQqBAQoE
BAACAhIEOQI6MhpzIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgdGhlCiBbU2FtcGxlUXVlcnlT
ZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0
XSB3YXMKIGNyZWF0ZWQgYXQuCgoMCgUEAAICBhIDOQIbCgwKBQQAAgIBEgM5HCcKDAoFBAAC
AgMSAzkqKwoMCgUEAAICCBIDOgYxCg8KCAQAAgIInAgAEgM6BzAKbAoEBAACAxIDPgIZGl8g
VGhlIGRlc2NyaXB0aW9uIG9mIHRoZQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNldF0uCgoMCgUEAAIDBRIDPgII
CgwKBQQAAgMBEgM+CRQKDAoFBAACAwMSAz4XGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet ===
    # Fields for SampleQuerySet
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SampleQuerySet - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/sample_query_set.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SampleQuerySet;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/sample_query_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet

A SampleQuerySet is the parent resource of SampleQuery, and contains the
configurations shared by all SampleQuery under it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full resource name of the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet], in
the format of
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The sample query set display name.

This field must be a UTF-8 encoded string with a length limit of 128
characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet] was
created at.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
