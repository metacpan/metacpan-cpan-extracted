package Google::Cloud::Discoveryengine::V1beta::SampleQuery;

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
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYW1wbGVfcXVlcnkucHJv
dG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvItsECgtTYW1wbGVRdWVyeRJeCgtxdWVyeV9lbnRy
eRgCIAEoCzI7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1
ZXJ5LlF1ZXJ5RW50cnlIAFIKcXVlcnlFbnRyeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUS
QAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUa6QEKClF1ZXJ5RW50cnkSGQoFcXVlcnkYASABKAlCA+BBAlIFcXVlcnkS
XAoHdGFyZ2V0cxgDIAMoCzJCLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNhbXBsZVF1ZXJ5LlF1ZXJ5RW50cnkuVGFyZ2V0Ugd0YXJnZXRzGmIKBlRhcmdldBIQCgN1
cmkYASABKAlSA3VyaRIhCgxwYWdlX251bWJlcnMYAiADKAVSC3BhZ2VOdW1iZXJzEhkKBXNj
b3JlGAMgASgBSABSBXNjb3JliAEBQggKBl9zY29yZTqZAepBlQEKKmRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9TYW1wbGVRdWVyeRJncHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxlX3F1ZXJ5X3NldH0vc2Ft
cGxlUXVlcmllcy97c2FtcGxlX3F1ZXJ5fUIJCgdjb250ZW50QpcCCidjb20uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCEFNhbXBsZVF1ZXJ5UHJvdG9QAVpRY2xvdWQu
Z29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2lu
ZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3Vk
LkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5l
XFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSpoUCgYS
BA4AVQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoC
AwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBACgkKAgglEgMWAEAKCAoB
CBIDFwBoCgkKAggLEgMXAGgKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAxCgkKAggI
EgMZADEKCAoBCBIDGgBACgkKAggBEgMaAEAKCAoBCBIDGwAtCgkKAggkEgMbAC0KCAoBCBID
HABACgkKAggpEgMcAEAKCAoBCBIDHQA/CgkKAggtEgMdAD8KRwoCBAASBCAAVQEaOyBTYW1w
bGUgUXVlcnkgY2FwdHVyZXMgbWV0YWRhdGEgdG8gYmUgdXNlZCBmb3IgZXZhbHVhdGlvbi4K
CgoKAwQAARIDIAgTCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBApPCgQEAAMAEgQnAkED
GkEgUXVlcnkgRW50cnkgY2FwdHVyZXMgbWV0YWRhdGEgdG8gYmUgdXNlZCBmb3Igc2VhcmNo
IGV2YWx1YXRpb24uCgoMCgUEAAMAARIDJwoUCkkKBgQAAwADABIEKQQ6BRo5IERlZmluZXMg
dGhlIHBhcmFtZXRlcnMgb2YgdGhlIHF1ZXJ5J3MgZXhwZWN0ZWQgb3V0Y29tZS4KCg4KBwQA
AwADAAESAykMEgrWAQoIBAADAAMAAgASAzEGFRrEASBFeHBlY3RlZCB1cmkgb2YgdGhlIHRh
cmdldC4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRo
IGEgbGVuZ3RoIGxpbWl0IG9mIDIwNDgKIGNoYXJhY3RlcnMuCgogRXhhbXBsZSBvZiB2YWxp
ZCB1cmlzOiBgaHR0cHM6Ly9leGFtcGxlLmNvbS9hYmNgLAogYGdjczovL2V4YW1wbGUvZXhh
bXBsZS5wZGZgLgoKEAoJBAADAAMAAgAFEgMxBgwKEAoJBAADAAMAAgABEgMxDRAKEAoJBAAD
AAMAAgADEgMxExQKYAoIBAADAAMAAgESAzYGJhpPIEV4cGVjdGVkIHBhZ2UgbnVtYmVycyBv
ZiB0aGUgdGFyZ2V0LgoKIEVhY2ggcGFnZSBudW1iZXIgbXVzdCBiZSBub24gbmVnYXRpdmUu
CgoQCgkEAAMAAwACAQQSAzYGDgoQCgkEAAMAAwACAQUSAzYPFAoQCgkEAAMAAwACAQESAzYV
IQoQCgkEAAMAAwACAQMSAzYkJQoxCggEAAMAAwACAhIDOQYgGiAgUmVsZXZhbmNlIHNjb3Jl
IG9mIHRoZSB0YXJnZXQuCgoQCgkEAAMAAwACAgQSAzkGDgoQCgkEAAMAAwACAgUSAzkPFQoQ
CgkEAAMAAwACAgESAzkWGwoQCgkEAAMAAwACAgMSAzkeHwolCgYEAAMAAgASAz0EPhoWIFJl
cXVpcmVkLiBUaGUgcXVlcnkuCgoOCgcEAAMAAgAFEgM9BAoKDgoHBAADAAIAARIDPQsQCg4K
BwQAAwACAAMSAz0TFAoOCgcEAAMAAgAIEgM9FT0KEQoKBAADAAIACJwIABIDPRY8Ci8KBgQA
AwACARIDQAQgGiAgTGlzdCBvZiB0YXJnZXRzIGZvciB0aGUgcXVlcnkuCgoOCgcEAAMAAgEE
EgNABAwKDgoHBAADAAIBBhIDQA0TCg4KBwQAAwACAQESA0AUGwoOCgcEAAMAAgEDEgNAHh8K
MAoEBAAIABIERAJHAxoiIFRoZSBjb250ZW50IG9mIHRoZSBzYW1wbGUgcXVlcnkuCgoMCgUE
AAgAARIDRAgPCh8KBAQAAgASA0YEHxoSIFRoZSBxdWVyeSBlbnRyeS4KCgwKBQQAAgAGEgNG
BA4KDAoFBAACAAESA0YPGgoMCgUEAAIAAxIDRh0eCpkCCgQEAAIBEgNOAj0aiwIgSWRlbnRp
Zmllci4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc2FtcGxlIHF1ZXJ5LCBpbiB0
aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxlX3F1ZXJ5X3NldH0vc2FtcGxlUXVlcmllcy97c2Ft
cGxlX3F1ZXJ5fWAuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJp
bmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAQUS
A04CCAoMCgUEAAIBARIDTgkNCgwKBQQAAgEDEgNOEBEKDAoFBAACAQgSA04SPAoPCggEAAIB
CJwIABIDThM7CnsKBAQAAgISBFMCVDIabSBPdXRwdXQgb25seS4gVGltZXN0YW1wIHRoZQog
W1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1w
bGVRdWVyeV0gd2FzIGNyZWF0ZWQKIGF0LgoKDAoFBAACAgYSA1MCGwoMCgUEAAICARIDUxwn
CgwKBQQAAgIDEgNTKisKDAoFBAACAggSA1QGMQoPCggEAAICCJwIABIDVAcwYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery ===
    # Fields for SampleQuery
    # Field: query_entry Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuery.QueryEntry)
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SampleQuery - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/sample_query.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SampleQuery;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery->new({
        query_entry => $query_entry,
        name => $name,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->query_entry();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/sample_query.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery

Sample Query captures metadata to be used for evaluation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_entry() >> / C<< $msg->query_entry($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry>)

The query entry.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full resource name of the sample query, in the format of
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}/sampleQueries/{sample_query}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery] was created
at.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
