package Google::Cloud::Translation::V3::Common;

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
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvdHJhbnNsYXRlL3YzL2NvbW1vbi5wcm90bxIbZ29vZ2xlLmNsb3Vk
LnRyYW5zbGF0aW9uLnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvIjIKDkdjc0lucHV0U291cmNlEiAKCWlucHV0X3VyaRgB
IAEoCUID4EECUghpbnB1dFVyaSJ6Cg9GaWxlSW5wdXRTb3VyY2USIAoJbWltZV90eXBlGAEg
ASgJQgPgQQJSCG1pbWVUeXBlEh0KB2NvbnRlbnQYAiABKAxCA+BBAlIHY29udGVudBImCgxk
aXNwbGF5X25hbWUYAyABKAlCA+BBAlILZGlzcGxheU5hbWUiRwoUR2NzT3V0cHV0RGVzdGlu
YXRpb24SLwoRb3V0cHV0X3VyaV9wcmVmaXgYASABKAlCA+BBAlIPb3V0cHV0VXJpUHJlZml4
Ir8FCg1HbG9zc2FyeUVudHJ5EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJdCgp0ZXJtc19w
YWlyGAIgASgLMjwuZ29vZ2xlLmNsb3VkLnRyYW5zbGF0aW9uLnYzLkdsb3NzYXJ5RW50cnku
R2xvc3NhcnlUZXJtc1BhaXJIAFIJdGVybXNQYWlyEloKCXRlcm1zX3NldBgDIAEoCzI7Lmdv
b2dsZS5jbG91ZC50cmFuc2xhdGlvbi52My5HbG9zc2FyeUVudHJ5Lkdsb3NzYXJ5VGVybXNT
ZXRIAFIIdGVybXNTZXQSIAoLZGVzY3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9uGqsBChFH
bG9zc2FyeVRlcm1zUGFpchJKCgtzb3VyY2VfdGVybRgBIAEoCzIpLmdvb2dsZS5jbG91ZC50
cmFuc2xhdGlvbi52My5HbG9zc2FyeVRlcm1SCnNvdXJjZVRlcm0SSgoLdGFyZ2V0X3Rlcm0Y
AiABKAsyKS5nb29nbGUuY2xvdWQudHJhbnNsYXRpb24udjMuR2xvc3NhcnlUZXJtUgp0YXJn
ZXRUZXJtGlMKEEdsb3NzYXJ5VGVybXNTZXQSPwoFdGVybXMYASADKAsyKS5nb29nbGUuY2xv
dWQudHJhbnNsYXRpb24udjMuR2xvc3NhcnlUZXJtUgV0ZXJtczqsAepBqAEKJnRyYW5zbGF0
ZS5nb29nbGVhcGlzLmNvbS9HbG9zc2FyeUVudHJ5El5wcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vZ2xvc3Nhcmllcy97Z2xvc3Nhcnl9L2dsb3NzYXJ5RW50cmll
cy97Z2xvc3NhcnlfZW50cnl9Kg9nbG9zc2FyeUVudHJpZXMyDWdsb3NzYXJ5RW50cnlCBgoE
ZGF0YSJHCgxHbG9zc2FyeVRlcm0SIwoNbGFuZ3VhZ2VfY29kZRgBIAEoCVIMbGFuZ3VhZ2VD
b2RlEhIKBHRleHQYAiABKAlSBHRleHQqyAEKDk9wZXJhdGlvblN0YXRlEh8KG09QRVJBVElP
Tl9TVEFURV9VTlNQRUNJRklFRBAAEhsKF09QRVJBVElPTl9TVEFURV9SVU5OSU5HEAESHQoZ
T1BFUkFUSU9OX1NUQVRFX1NVQ0NFRURFRBACEhoKFk9QRVJBVElPTl9TVEFURV9GQUlMRUQQ
AxIeChpPUEVSQVRJT05fU1RBVEVfQ0FOQ0VMTElORxAEEh0KGU9QRVJBVElPTl9TVEFURV9D
QU5DRUxMRUQQBULCAQodY29tLmdvb2dsZS5jbG91ZC50cmFuc2xhdGUudjNCC0NvbW1vblBy
b3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vdHJhbnNsYXRlL2FwaXYzL3RyYW5zbGF0ZXBi
O3RyYW5zbGF0ZXBiqgIZR29vZ2xlLkNsb3VkLlRyYW5zbGF0ZS5WM8oCGUdvb2dsZVxDbG91
ZFxUcmFuc2xhdGVcVjPqAhxHb29nbGU6OkNsb3VkOjpUcmFuc2xhdGU6OlYzStAfCgcSBQ4A
ggEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoICgEIEgMVADYKCQoCCCUSAxUANgoICgEIEgMWAFIKCQoCCAsS
AxYAUgoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYACwKCQoCCAgSAxgALAoICgEIEgMZ
ADYKCQoCCAESAxkANgoICgEIEgMaADYKCQoCCCkSAxoANgoICgEIEgMbADUKCQoCCC0SAxsA
NQpGCgIEABIEHgAhARo6IFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiBmb3Ig
dGhlIGlucHV0IGNvbnRlbnQuCgoKCgMEAAESAx4IFgpSCgQEAAIAEgMgAkAaRSBSZXF1aXJl
ZC4gU291cmNlIGRhdGEgVVJJLiBGb3IgZXhhbXBsZSwgYGdzOi8vbXlfYnVja2V0L215X29i
amVjdGAuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCRIKDAoFBAACAAMSAyAVFgoMCgUE
AAIACBIDIBc/Cg8KCAQAAgAInAgAEgMgGD4KHgoCBAESBCQALQEaEiBBbiBpbmxpbmVkIGZp
bGUuCgoKCgMEAQESAyQIFwouCgQEAQIAEgMmAkAaISBSZXF1aXJlZC4gVGhlIGZpbGUncyBt
aW1lIHR5cGUuCgoMCgUEAQIABRIDJgIICgwKBQQBAgABEgMmCRIKDAoFBAECAAMSAyYVFgoM
CgUEAQIACBIDJhc/Cg8KCAQBAgAInAgAEgMmGD4KMgoEBAECARIDKQI9GiUgUmVxdWlyZWQu
IFRoZSBmaWxlJ3MgYnl0ZSBjb250ZW50cy4KCgwKBQQBAgEFEgMpAgcKDAoFBAECAQESAykI
DwoMCgUEAQIBAxIDKRITCgwKBQQBAgEIEgMpFDwKDwoIBAECAQicCAASAykVOwoxCgQEAQIC
EgMsAkMaJCBSZXF1aXJlZC4gVGhlIGZpbGUncyBkaXNwbGF5IG5hbWUuCgoMCgUEAQICBRID
LAIICgwKBQQBAgIBEgMsCRUKDAoFBAECAgMSAywYGQoMCgUEAQICCBIDLBpCCg8KCAQBAgII
nAgAEgMsG0EKRwoCBAISBDAANQEaOyBUaGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRp
b24gZm9yIHRoZSBvdXRwdXQgY29udGVudC4KCgoKAwQCARIDMAgcCuABCgQEAgIAEgM0Akga
0gEgUmVxdWlyZWQuIEdvb2dsZSBDbG91ZCBTdG9yYWdlIFVSSSB0byBvdXRwdXQgZGlyZWN0
b3J5LiBGb3IgZXhhbXBsZSwKIGBnczovL2J1Y2tldC9kaXJlY3RvcnlgLiBUaGUgcmVxdWVz
dGluZyB1c2VyIG11c3QgaGF2ZSB3cml0ZSBwZXJtaXNzaW9uIHRvCiB0aGUgYnVja2V0LiBU
aGUgZGlyZWN0b3J5IHdpbGwgYmUgY3JlYXRlZCBpZiBpdCBkb2Vzbid0IGV4aXN0LgoKDAoF
BAICAAUSAzQCCAoMCgUEAgIAARIDNAkaCgwKBQQCAgADEgM0HR4KDAoFBAICAAgSAzQfRwoP
CggEAgIACJwIABIDNCBGCjkKAgUAEgQ4AEsBGi0gUG9zc2libGUgc3RhdGVzIG9mIGxvbmcg
cnVubmluZyBvcGVyYXRpb25zLgoKCgoDBQABEgM4BRMKFwoEBQACABIDOgIiGgogSW52YWxp
ZC4KCgwKBQUAAgABEgM6Ah0KDAoFBQACAAISAzogIQoqCgQFAAIBEgM9Ah4aHSBSZXF1ZXN0
IGlzIGJlaW5nIHByb2Nlc3NlZC4KCgwKBQUAAgEBEgM9AhkKDAoFBQACAQISAz0cHQosCgQF
AAICEgNAAiAaHyBUaGUgb3BlcmF0aW9uIHdhcyBzdWNjZXNzZnVsLgoKDAoFBQACAgESA0AC
GwoMCgUFAAICAhIDQB4fCisKBAUAAgMSA0MCHRoeIEZhaWxlZCB0byBwcm9jZXNzIG9wZXJh
dGlvbi4KCgwKBQUAAgMBEgNDAhgKDAoFBQACAwISA0MbHAqKAQoEBQACBBIDRwIhGn0gUmVx
dWVzdCBpcyBpbiB0aGUgcHJvY2VzcyBvZiBiZWluZyBjYW5jZWxlZCBhZnRlciBjYWxsZXIg
aW52b2tlZAogbG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5DYW5jZWxPcGVyYXRpb24gb24gdGhl
IHJlcXVlc3QgaWQuCgoMCgUFAAIEARIDRwIcCgwKBQUAAgQCEgNHHyAKPwoEBQACBRIDSgIg
GjIgVGhlIG9wZXJhdGlvbiByZXF1ZXN0IHdhcyBzdWNjZXNzZnVsbHkgY2FuY2VsZWQuCgoM
CgUFAAIFARIDSgIbCgwKBQUAAgUCEgNKHh8KNgoCBAMSBE4AeQEaKiBSZXByZXNlbnRzIGEg
c2luZ2xlIGVudHJ5IGluIGEgZ2xvc3NhcnkuCgoKCgMEAwESA04IFQoLCgMEAwcSBE8CVAQK
DQoFBAMHnQgSBE8CVAQKSQoEBAMDABIEVwJdAxo7IFJlcHJlc2VudHMgYSBzaW5nbGUgZW50
cnkgZm9yIGFuIHVuaWRpcmVjdGlvbmFsIGdsb3NzYXJ5LgoKDAoFBAMDAAESA1cKGwpNCgYE
AwMAAgASA1kEIRo+IFRoZSBzb3VyY2UgdGVybSBpcyB0aGUgdGVybSB0aGF0IHdpbGwgZ2V0
IG1hdGNoIGluIHRoZSB0ZXh0LAoKDgoHBAMDAAIABhIDWQQQCg4KBwQDAwACAAESA1kRHAoO
CgcEAwMAAgADEgNZHyAKQgoGBAMDAAIBEgNcBCEaMyBUaGUgdGVybSB0aGF0IHdpbGwgcmVw
bGFjZSB0aGUgbWF0Y2ggc291cmNlIHRlcm0uCgoOCgcEAwMAAgEGEgNcBBAKDgoHBAMDAAIB
ARIDXBEcCg4KBwQDAwACAQMSA1wfIAq2AQoEBAMDARIEYgJmAxqnASBSZXByZXNlbnRzIGEg
c2luZ2xlIGVudHJ5IGZvciBhbiBlcXVpdmFsZW50IHRlcm0gc2V0IGdsb3NzYXJ5LiBUaGlz
IGlzIHVzZWQKIGZvciBlcXVpdmFsZW50IHRlcm0gc2V0cyB3aGVyZSBlYWNoIHRlcm0gY2Fu
IGJlIHJlcGxhY2VkIGJ5IHRoZSBvdGhlciB0ZXJtcwogaW4gdGhlIHNldC4KCgwKBQQDAwEB
EgNiChoKYQoGBAMDAQIAEgNlBCQaUiBFYWNoIHRlcm0gaW4gdGhlIHNldCByZXByZXNlbnRz
IGEgdGVybSB0aGF0IGNhbiBiZSByZXBsYWNlZCBieSB0aGUgb3RoZXIKIHRlcm1zLgoKDgoH
BAMDAQIABBIDZQQMCg4KBwQDAwECAAYSA2UNGQoOCgcEAwMBAgABEgNlGh8KDgoHBAMDAQIA
AxIDZSIjCn4KBAQDAgASA2sCPRpxIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBlbnRyeS4KIEZvcm1hdDoKICAgYHByb2plY3RzLyovbG9jYXRpb25zLyovZ2xvc3Nh
cmllcy8qL2dsb3NzYXJ5RW50cmllcy8qYAoKDAoFBAMCAAUSA2sCCAoMCgUEAwIAARIDawkN
CgwKBQQDAgADEgNrEBEKDAoFBAMCAAgSA2sSPAoPCggEAwIACJwIABIDaxM7CmIKBAQDCAAS
BG8CdQMaVCBUaGUgZGlmZmVyZW50IGRhdGEgZm9yIHRoZSBnbG9zc2FyeSB0eXBlcyAoVW5p
ZGlyZWN0aW9uYWwsIEVxdWl2YWxlbnQgdGVybQogc2V0cykuCgoMCgUEAwgAARIDbwgMCjMK
BAQDAgESA3EEJRomIFVzZWQgZm9yIGFuIHVuaWRpcmVjdGlvbmFsIGdsb3NzYXJ5LgoKDAoF
BAMCAQYSA3EEFQoMCgUEAwIBARIDcRYgCgwKBQQDAgEDEgNxIyQKOQoEBAMCAhIDdAQjGiwg
VXNlZCBmb3IgYW4gZXF1aXZhbGVudCB0ZXJtIHNldHMgZ2xvc3NhcnkuCgoMCgUEAwICBhID
dAQUCgwKBQQDAgIBEgN0FR4KDAoFBAMCAgMSA3QhIgosCgQEAwIDEgN4AhkaHyBEZXNjcmli
ZXMgdGhlIGdsb3NzYXJ5IGVudHJ5LgoKDAoFBAMCAwUSA3gCCAoMCgUEAwIDARIDeAkUCgwK
BQQDAgMDEgN4FxgKMAoCBAQSBXwAggEBGiMgUmVwcmVzZW50cyBhIHNpbmdsZSBnbG9zc2Fy
eSB0ZXJtCgoKCgMEBAESA3wIFAozCgQEBAIAEgN+AhsaJiBUaGUgbGFuZ3VhZ2UgZm9yIHRo
aXMgZ2xvc3NhcnkgdGVybS4KCgwKBQQEAgAFEgN+AggKDAoFBAQCAAESA34JFgoMCgUEBAIA
AxIDfhkaCi8KBAQEAgESBIEBAhIaISBUaGUgdGV4dCBmb3IgdGhlIGdsb3NzYXJ5IHRlcm0u
CgoNCgUEBAIBBRIEgQECCAoNCgUEBAIBARIEgQEJDQoNCgUEBAIBAxIEgQEQEWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Translation::V3::Common::GcsInputSource ===
    # Fields for GcsInputSource
    # Field: input_uri Type: 9 ()

# === Message: Google::Cloud::Translation::V3::Common::FileInputSource ===
    # Fields for FileInputSource
    # Field: mime_type Type: 9 ()
    # Field: content Type: 12 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Translation::V3::Common::GcsOutputDestination ===
    # Fields for GcsOutputDestination
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Cloud::Translation::V3::Common::GlossaryEntry ===
    # Fields for GlossaryEntry
    # Field: name Type: 9 ()
    # Field: terms_pair Type: 11 (.google.cloud.translation.v3.GlossaryEntry.GlossaryTermsPair)
    # Field: terms_set Type: 11 (.google.cloud.translation.v3.GlossaryEntry.GlossaryTermsSet)
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Translation::V3::Common::GlossaryTerm ===
    # Fields for GlossaryTerm
    # Field: language_code Type: 9 ()
    # Field: text Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Translation::V3::Common - Compiled Protocol Buffers messages for google/cloud/translate/v3/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Translation::V3::Common;

    my $msg = Google::Cloud::Translation::V3::Common::GcsInputSource->new({
        input_uri => $input_uri,
    });

    # Read or update a field
    my $val = $msg->input_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Translation::V3::Common::GcsInputSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/translate/v3/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Translation::V3::Common::GcsInputSource

The Google Cloud Storage location for the input content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_uri() >> / C<< $msg->input_uri($value) >>

Type: C<String>

Required. Source data URI. For example, `gs://my_bucket/my_object`.

=back

=head2 Google::Cloud::Translation::V3::Common::FileInputSource

An inlined file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The file's mime type.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

Required. The file's byte contents.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The file's display name.

=back

=head2 Google::Cloud::Translation::V3::Common::GcsOutputDestination

The Google Cloud Storage location for the output content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Required. Google Cloud Storage URI to output directory. For example,
`gs://bucket/directory`. The requesting user must have write permission to
the bucket. The directory will be created if it doesn't exist.

=back

=head2 Google::Cloud::Translation::V3::Common::GlossaryEntry

Represents a single entry in a glossary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the entry.
Format:
  `projects/*/locations/*/glossaries/*/glossaryEntries/*`

=item * C<< $msg->terms_pair() >> / C<< $msg->terms_pair($value) >>

Type: C<Message> (L<Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsPair>)

Used for an unidirectional glossary.

=item * C<< $msg->terms_set() >> / C<< $msg->terms_set($value) >>

Type: C<Message> (L<Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsSet>)

Used for an equivalent term sets glossary.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Describes the glossary entry.

=back

=head2 Google::Cloud::Translation::V3::Common::GlossaryTerm

Represents a single glossary term

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language for this glossary term.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

The text for the glossary term.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Translation::V3::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
