package Google::Cloud::Discoveryengine::V1alpha::SampleQuery;

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
Cjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1ZXJ5LnBy
b3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3QQKC1NhbXBsZVF1ZXJ5El8KC3F1ZXJ5X2Vu
dHJ5GAIgASgLMjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBs
ZVF1ZXJ5LlF1ZXJ5RW50cnlIAFIKcXVlcnlFbnRyeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5h
bWUSQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCmNyZWF0ZVRpbWUa6gEKClF1ZXJ5RW50cnkSGQoFcXVlcnkYASABKAlCA+BBAlIFcXVl
cnkSXQoHdGFyZ2V0cxgDIAMoCzJDLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TYW1wbGVRdWVyeS5RdWVyeUVudHJ5LlRhcmdldFIHdGFyZ2V0cxpiCgZUYXJnZXQS
EAoDdXJpGAEgASgJUgN1cmkSIQoMcGFnZV9udW1iZXJzGAIgAygFUgtwYWdlTnVtYmVycxIZ
CgVzY29yZRgDIAEoAUgAUgVzY29yZYgBAUIICgZfc2NvcmU6mQHqQZUBCipkaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnkSZ3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMve3NhbXBsZV9xdWVyeV9zZXR9
L3NhbXBsZVF1ZXJpZXMve3NhbXBsZV9xdWVyeX1CCQoHY29udGVudEKcAgooY29tLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIQU2FtcGxlUXVlcnlQcm90b1ABWlJj
bG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVy
eWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xl
LkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVy
eUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFs
cGhhSpsUCgYSBA4AVQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBBCgkKAggl
EgMWAEEKCAoBCBIDFwBpCgkKAggLEgMXAGkKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQAxCgkKAggIEgMZADEKCAoBCBIDGgBBCgkKAggBEgMaAEEKCAoBCBIDGwAtCgkKAggkEgMb
AC0KCAoBCBIDHABBCgkKAggpEgMcAEEKCAoBCBIDHQBACgkKAggtEgMdAEAKRwoCBAASBCAA
VQEaOyBTYW1wbGUgUXVlcnkgY2FwdHVyZXMgbWV0YWRhdGEgdG8gYmUgdXNlZCBmb3IgZXZh
bHVhdGlvbi4KCgoKAwQAARIDIAgTCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBApPCgQE
AAMAEgQnAkEDGkEgUXVlcnkgRW50cnkgY2FwdHVyZXMgbWV0YWRhdGEgdG8gYmUgdXNlZCBm
b3Igc2VhcmNoIGV2YWx1YXRpb24uCgoMCgUEAAMAARIDJwoUCkkKBgQAAwADABIEKQQ6BRo5
IERlZmluZXMgdGhlIHBhcmFtZXRlcnMgb2YgdGhlIHF1ZXJ5J3MgZXhwZWN0ZWQgb3V0Y29t
ZS4KCg4KBwQAAwADAAESAykMEgrWAQoIBAADAAMAAgASAzEGFRrEASBFeHBlY3RlZCB1cmkg
b2YgdGhlIHRhcmdldC4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0
cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDIwNDgKIGNoYXJhY3RlcnMuCgogRXhhbXBs
ZSBvZiB2YWxpZCB1cmlzOiBgaHR0cHM6Ly9leGFtcGxlLmNvbS9hYmNgLAogYGdjczovL2V4
YW1wbGUvZXhhbXBsZS5wZGZgLgoKEAoJBAADAAMAAgAFEgMxBgwKEAoJBAADAAMAAgABEgMx
DRAKEAoJBAADAAMAAgADEgMxExQKYAoIBAADAAMAAgESAzYGJhpPIEV4cGVjdGVkIHBhZ2Ug
bnVtYmVycyBvZiB0aGUgdGFyZ2V0LgoKIEVhY2ggcGFnZSBudW1iZXIgbXVzdCBiZSBub24g
bmVnYXRpdmUuCgoQCgkEAAMAAwACAQQSAzYGDgoQCgkEAAMAAwACAQUSAzYPFAoQCgkEAAMA
AwACAQESAzYVIQoQCgkEAAMAAwACAQMSAzYkJQoxCggEAAMAAwACAhIDOQYgGiAgUmVsZXZh
bmNlIHNjb3JlIG9mIHRoZSB0YXJnZXQuCgoQCgkEAAMAAwACAgQSAzkGDgoQCgkEAAMAAwAC
AgUSAzkPFQoQCgkEAAMAAwACAgESAzkWGwoQCgkEAAMAAwACAgMSAzkeHwolCgYEAAMAAgAS
Az0EPhoWIFJlcXVpcmVkLiBUaGUgcXVlcnkuCgoOCgcEAAMAAgAFEgM9BAoKDgoHBAADAAIA
ARIDPQsQCg4KBwQAAwACAAMSAz0TFAoOCgcEAAMAAgAIEgM9FT0KEQoKBAADAAIACJwIABID
PRY8Ci8KBgQAAwACARIDQAQgGiAgTGlzdCBvZiB0YXJnZXRzIGZvciB0aGUgcXVlcnkuCgoO
CgcEAAMAAgEEEgNABAwKDgoHBAADAAIBBhIDQA0TCg4KBwQAAwACAQESA0AUGwoOCgcEAAMA
AgEDEgNAHh8KMAoEBAAIABIERAJHAxoiIFRoZSBjb250ZW50IG9mIHRoZSBzYW1wbGUgcXVl
cnkuCgoMCgUEAAgAARIDRAgPCh8KBAQAAgASA0YEHxoSIFRoZSBxdWVyeSBlbnRyeS4KCgwK
BQQAAgAGEgNGBA4KDAoFBAACAAESA0YPGgoMCgUEAAIAAxIDRh0eCpkCCgQEAAIBEgNOAj0a
iwIgSWRlbnRpZmllci4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc2FtcGxlIHF1
ZXJ5LCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxlX3F1ZXJ5X3NldH0vc2FtcGxlUXVl
cmllcy97c2FtcGxlX3F1ZXJ5fWAuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5j
b2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoK
DAoFBAACAQUSA04CCAoMCgUEAAIBARIDTgkNCgwKBQQAAgEDEgNOEBEKDAoFBAACAQgSA04S
PAoPCggEAAIBCJwIABIDThM7CnwKBAQAAgISBFMCVDIabiBPdXRwdXQgb25seS4gVGltZXN0
YW1wIHRoZQogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuU2FtcGxlUXVlcnldIHdhcyBjcmVhdGVkCiBhdC4KCgwKBQQAAgIGEgNTAhsKDAoF
BAACAgESA1McJwoMCgUEAAICAxIDUyorCgwKBQQAAgIIEgNUBjEKDwoIBAACAgicCAASA1QH
MGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery ===
    # Fields for SampleQuery
    # Field: query_entry Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuery.QueryEntry)
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQuery - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/sample_query.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SampleQuery;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery->new({
        query_entry => $query_entry,
        name => $name,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->query_entry();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/sample_query.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery

Sample Query captures metadata to be used for evaluation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_entry() >> / C<< $msg->query_entry($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery::QueryEntry>)

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
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery] was created
at.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
