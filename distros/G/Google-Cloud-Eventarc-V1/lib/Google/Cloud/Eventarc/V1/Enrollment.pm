package Google::Cloud::Eventarc::V1::Enrollment;

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
Cilnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvZW5yb2xsbWVudC5wcm90bxIYZ29vZ2xlLmNs
b3VkLmV2ZW50YXJjLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IscGCgpFbnJvbGxtZW50EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIVCgN1aWQYAiABKAlC
A+BBA1IDdWlkEhcKBGV0YWcYAyABKAlCA+BBA1IEZXRhZxJACgtjcmVhdGVfdGltZRgEIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJNCgZsYWJlbHMYBiADKAsyMC5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuRW5yb2xs
bWVudC5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSXAoLYW5ub3RhdGlvbnMYByADKAsyNS5n
b29nbGUuY2xvdWQuZXZlbnRhcmMudjEuRW5yb2xsbWVudC5Bbm5vdGF0aW9uc0VudHJ5QgPg
QQFSC2Fubm90YXRpb25zEiYKDGRpc3BsYXlfbmFtZRgIIAEoCUID4EEBUgtkaXNwbGF5TmFt
ZRIgCgljZWxfbWF0Y2gYCSABKAlCA+BBAlIIY2VsTWF0Y2gSTgoLbWVzc2FnZV9idXMYCiAB
KAlCLeBBAuBBBfpBJAoiZXZlbnRhcmMuZ29vZ2xlYXBpcy5jb20vTWVzc2FnZUJ1c1IKbWVz
c2FnZUJ1cxIlCgtkZXN0aW5hdGlvbhgLIAEoCUID4EECUgtkZXN0aW5hdGlvbho5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4K
EEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZh
bHVlOgI4ATqCAepBfwoiZXZlbnRhcmMuZ29vZ2xlYXBpcy5jb20vRW5yb2xsbWVudBJAcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Vucm9sbG1lbnRzL3tlbnJv
bGxtZW50fSoLZW5yb2xsbWVudHMyCmVucm9sbG1lbnRCvwEKHGNvbS5nb29nbGUuY2xvdWQu
ZXZlbnRhcmMudjFCD0Vucm9sbG1lbnRQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2V2
ZW50YXJjL2FwaXYxL2V2ZW50YXJjcGI7ZXZlbnRhcmNwYqoCGEdvb2dsZS5DbG91ZC5FdmVu
dGFyYy5WMcoCGEdvb2dsZVxDbG91ZFxFdmVudGFyY1xWMeoCG0dvb2dsZTo6Q2xvdWQ6OkV2
ZW50YXJjOjpWMUrqGAoGEgQOAFsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYA
NQoJCgIIJRIDFgA1CggKAQgSAxcATwoJCgIICxIDFwBPCggKAQgSAxgAIgoJCgIIChIDGAAi
CggKAQgSAxkAMAoJCgIICBIDGQAwCggKAQgSAxoANQoJCgIIARIDGgA1CggKAQgSAxsANQoJ
CgIIKRIDGwA1CggKAQgSAxwANAoJCgIILRIDHAA0CuEBCgIEABIEIQBbARrUASBBbiBlbnJv
bGxtZW50IHJlcHJlc2VudHMgYSBzdWJzY3JpcHRpb24gZm9yIG1lc3NhZ2VzIG9uIGEgcGFy
dGljdWxhciBtZXNzYWdlCiBidXMuIEl0IGRlZmluZXMgYSBtYXRjaGluZyBjcml0ZXJpYSBm
b3IgbWVzc2FnZXMgb24gdGhlIGJ1cyBhbmQgdGhlCiBzdWJzY3JpYmVyIGVuZHBvaW50IHdo
ZXJlIG1hdGNoZWQgbWVzc2FnZXMgc2hvdWxkIGJlIGRlbGl2ZXJlZC4KCgoKAwQAARIDIQgS
CgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBAp2CgQEAAIAEgMrAj0aaSBJZGVudGlmaWVy
LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBmb3JtCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZW5yb2xsbWVudHMve2Vucm9sbG1lbnR9CgoMCgUEAAIABRIDKwII
CgwKBQQAAgABEgMrCQ0KDAoFBAACAAMSAysQEQoMCgUEAAIACBIDKxI8Cg8KCAQAAgAInAgA
EgMrEzsKrwEKBAQAAgESAzACPRqhASBPdXRwdXQgb25seS4gU2VydmVyIGFzc2lnbmVkIHVu
aXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgY2hhbm5lbC4gVGhlIHZhbHVlCiBpcyBhIFVVSUQ0
IHN0cmluZyBhbmQgZ3VhcmFudGVlZCB0byByZW1haW4gdW5jaGFuZ2VkIHVudGlsIHRoZSBy
ZXNvdXJjZSBpcwogZGVsZXRlZC4KCgwKBQQAAgEFEgMwAggKDAoFBAACAQESAzAJDAoMCgUE
AAIBAxIDMA8QCgwKBQQAAgEIEgMwETwKDwoIBAACAQicCAASAzASOwrkAQoEBAACAhIDNQI+
GtYBIE91dHB1dCBvbmx5LiBUaGlzIGNoZWNrc3VtIGlzIGNvbXB1dGVkIGJ5IHRoZSBzZXJ2
ZXIgYmFzZWQgb24gdGhlIHZhbHVlIG9mCiBvdGhlciBmaWVsZHMsIGFuZCBtaWdodCBiZSBz
ZW50IG9ubHkgb24gdXBkYXRlIGFuZCBkZWxldGUgcmVxdWVzdHMgdG8KIGVuc3VyZSB0aGF0
IHRoZSBjbGllbnQgaGFzIGFuIHVwLXRvLWRhdGUgdmFsdWUgYmVmb3JlIHByb2NlZWRpbmcu
CgoMCgUEAAICBRIDNQIICgwKBQQAAgIBEgM1CQ0KDAoFBAACAgMSAzUQEQoMCgUEAAICCBID
NRI9Cg8KCAQAAgIInAgAEgM1EzwKLwoEBAACAxIEOAI5MhohIE91dHB1dCBvbmx5LiBUaGUg
Y3JlYXRpb24gdGltZS4KCgwKBQQAAgMGEgM4AhsKDAoFBAACAwESAzgcJwoMCgUEAAIDAxID
OCorCgwKBQQAAgMIEgM5BjEKDwoIBAACAwicCAASAzkHMAo0CgQEAAIEEgQ8Aj0yGiYgT3V0
cHV0IG9ubHkuIFRoZSBsYXN0LW1vZGlmaWVkIHRpbWUuCgoMCgUEAAIEBhIDPAIbCgwKBQQA
AgQBEgM8HCcKDAoFBAACBAMSAzwqKwoMCgUEAAIECBIDPQYxCg8KCAQAAgQInAgAEgM9BzAK
KQoEBAACBRIDQAJKGhwgT3B0aW9uYWwuIFJlc291cmNlIGxhYmVscy4KCgwKBQQAAgUGEgNA
AhUKDAoFBAACBQESA0AWHAoMCgUEAAIFAxIDQB8gCgwKBQQAAgUIEgNAIUkKDwoIBAACBQic
CAASA0AiSAouCgQEAAIGEgNDAk8aISBPcHRpb25hbC4gUmVzb3VyY2UgYW5ub3RhdGlvbnMu
CgoMCgUEAAIGBhIDQwIVCgwKBQQAAgYBEgNDFiEKDAoFBAACBgMSA0MkJQoMCgUEAAIGCBID
QyZOCg8KCAQAAgYInAgAEgNDJ00KLwoEBAACBxIDRgJDGiIgT3B0aW9uYWwuIFJlc291cmNl
IGRpc3BsYXkgbmFtZS4KCgwKBQQAAgcFEgNGAggKDAoFBAACBwESA0YJFQoMCgUEAAIHAxID
RhgZCgwKBQQAAgcIEgNGGkIKDwoIBAACBwicCAASA0YbQQphCgQEAAIIEgNKAkAaVCBSZXF1
aXJlZC4gQSBDRUwgZXhwcmVzc2lvbiBpZGVudGlmeWluZyB3aGljaCBtZXNzYWdlcyB0aGlz
IGVucm9sbG1lbnQKIGFwcGxpZXMgdG8uCgoMCgUEAAIIBRIDSgIICgwKBQQAAggBEgNKCRIK
DAoFBAACCAMSA0oVFgoMCgUEAAIICBIDShc/Cg8KCAQAAggInAgAEgNKGD4KxwEKBAQAAgkS
BE8CVQQauAEgUmVxdWlyZWQuIEltbXV0YWJsZS4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgbWVz
c2FnZSBidXMgaWRlbnRpZnlpbmcgdGhlCiBzb3VyY2Ugb2YgdGhlIG1lc3NhZ2VzLiBJdCBt
YXRjaGVzIHRoZSBmb3JtCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vbWVzc2FnZUJ1c2VzL3ttZXNzYWdlQnVzfS4KCgwKBQQAAgkFEgNPAggKDAoFBAACCQES
A08JFAoMCgUEAAIJAxIDTxcZCg0KBQQAAgkIEgRPGlUDCg8KCAQAAgkInAgAEgNQBCoKDwoI
BAACCQicCAESA1EEKwoPCgcEAAIJCJ8IEgRSBFQFCt8BCgQEAAIKEgNaAkMa0QEgUmVxdWly
ZWQuIERlc3RpbmF0aW9uIGlzIHRoZSBQaXBlbGluZSB0aGF0IHRoZSBFbnJvbGxtZW50IGlz
IGRlbGl2ZXJpbmcgdG8uCiBJdCBtdXN0IHBvaW50IHRvIHRoZSBmdWxsIHJlc291cmNlIG5h
bWUgb2YgYSBQaXBlbGluZS4gRm9ybWF0OgogInByb2plY3RzL3tQUk9KRUNUX0lEfS9sb2Nh
dGlvbnMve3JlZ2lvbn0vcGlwZWxpbmVzL3tQSVBFTElORV9JRCkiCgoMCgUEAAIKBRIDWgII
CgwKBQQAAgoBEgNaCRQKDAoFBAACCgMSA1oXGQoMCgUEAAIKCBIDWhpCCg8KCAQAAgoInAgA
EgNaG0FiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::Enrollment::Enrollment ===
    # Fields for Enrollment
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.Enrollment.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.eventarc.v1.Enrollment.AnnotationsEntry)
    # Field: display_name Type: 9 ()
    # Field: cel_match Type: 9 ()
    # Field: message_bus Type: 9 ()
    # Field: destination Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::Enrollment - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/enrollment.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::Enrollment;

    my $msg = Google::Cloud::Eventarc::V1::Enrollment::Enrollment->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::Enrollment::Enrollment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/enrollment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::Enrollment::Enrollment

An enrollment represents a subscription for messages on a particular message
bus. It defines a matching criteria for messages on the bus and the
subscriber endpoint where matched messages should be delivered.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the form
projects/{project}/locations/{location}/enrollments/{enrollment}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the channel. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. This checksum is computed by the server based on the value of
other fields, and might be sent only on update and delete requests to
ensure that the client has an up-to-date value before proceeding.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Enrollment::Enrollment::LabelsEntry>)

Optional. Resource labels.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Enrollment::Enrollment::AnnotationsEntry>)

Optional. Resource annotations.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Resource display name.

=item * C<< $msg->cel_match() >> / C<< $msg->cel_match($value) >>

Type: C<String>

Required. A CEL expression identifying which messages this enrollment
applies to.

=item * C<< $msg->message_bus() >> / C<< $msg->message_bus($value) >>

Type: C<String>

Required. Immutable. Resource name of the message bus identifying the
source of the messages. It matches the form
projects/{project}/locations/{location}/messageBuses/{messageBus}.

=item * C<< $msg->destination() >> / C<< $msg->destination($value) >>

Type: C<String>

Required. Destination is the Pipeline that the Enrollment is delivering to.
It must point to the full resource name of a Pipeline. Format:
"projects/{PROJECT_ID}/locations/{region}/pipelines/{PIPELINE_ID)"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::Enrollment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
