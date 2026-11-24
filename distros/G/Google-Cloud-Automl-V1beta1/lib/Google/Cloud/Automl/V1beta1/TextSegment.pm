package Google::Cloud::Automl::V1beta1::TextSegment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dF9zZWdtZW50LnByb3RvEhtnb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEiaQoLVGV4dFNlZ21lbnQSGAoHY29udGVudBgDIAEo
CVIHY29udGVudBIhCgxzdGFydF9vZmZzZXQYASABKANSC3N0YXJ0T2Zmc2V0Eh0KCmVuZF9v
ZmZzZXQYAiABKANSCWVuZE9mZnNldEKtAQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFi
ZXRhMUIQVGV4dFNlZ21lbnRQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9h
cGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJl
dGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSvYKCgYSBA4AJwEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCAoBCBIDEwBOCgkKAggL
EgMTAE4KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAxCgkKAggIEgMVADEKCAoBCBID
FgA4CgkKAggBEgMWADgKCAoBCBIDFwA4CgkKAggpEgMXADgKCAoBCBIDGAA3CgkKAggtEgMY
ADcKWgoCBAASBBsAJwEaTiBBIGNvbnRpZ3VvdXMgcGFydCBvZiBhIHRleHQgKHN0cmluZyks
IGFzc3VtaW5nIGl0IGhhcyBhbiBVVEYtOCBORkMgZW5jb2RpbmcuCgoKCgMEAAESAxsIEwo7
CgQEAAIAEgMdAhUaLiBPdXRwdXQgb25seS4gVGhlIGNvbnRlbnQgb2YgdGhlIFRleHRTZWdt
ZW50LgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkQCgwKBQQAAgADEgMdExQKlgEKBAQA
AgESAyECGRqIASBSZXF1aXJlZC4gWmVyby1iYXNlZCBjaGFyYWN0ZXIgaW5kZXggb2YgdGhl
IGZpcnN0IGNoYXJhY3RlciBvZiB0aGUgdGV4dAogc2VnbWVudCAoY291bnRpbmcgY2hhcmFj
dGVycyBmcm9tIHRoZSBiZWdpbm5pbmcgb2YgdGhlIHRleHQpLgoKDAoFBAACAQUSAyECBwoM
CgUEAAIBARIDIQgUCgwKBQQAAgEDEgMhFxgK6AEKBAQAAgISAyYCFxraASBSZXF1aXJlZC4g
WmVyby1iYXNlZCBjaGFyYWN0ZXIgaW5kZXggb2YgdGhlIGZpcnN0IGNoYXJhY3RlciBwYXN0
IHRoZSBlbmQgb2YKIHRoZSB0ZXh0IHNlZ21lbnQgKGNvdW50aW5nIGNoYXJhY3RlciBmcm9t
IHRoZSBiZWdpbm5pbmcgb2YgdGhlIHRleHQpLgogVGhlIGNoYXJhY3RlciBhdCB0aGUgZW5k
X29mZnNldCBpcyBOT1QgaW5jbHVkZWQgaW4gdGhlIHRleHQgc2VnbWVudC4KCgwKBQQAAgIF
EgMmAgcKDAoFBAACAgESAyYIEgoMCgUEAAICAxIDJhUWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::TextSegment::TextSegment ===
    # Fields for TextSegment
    # Field: content Type: 9 ()
    # Field: start_offset Type: 3 ()
    # Field: end_offset Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::TextSegment - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/text_segment.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::TextSegment;

    my $msg = Google::Cloud::Automl::V1beta1::TextSegment::TextSegment->new({
        content => $content,
        start_offset => $start_offset,
        end_offset => $end_offset,
    });

    # Read or update a field
    my $val = $msg->content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::TextSegment::TextSegment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/text_segment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::TextSegment::TextSegment

A contiguous part of a text (string), assuming it has an UTF-8 NFC encoding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Output only. The content of the TextSegment.

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Int64>

Required. Zero-based character index of the first character of the text
segment (counting characters from the beginning of the text).

=item * C<< $msg->end_offset() >> / C<< $msg->end_offset($value) >>

Type: C<Int64>

Required. Zero-based character index of the first character past the end of
the text segment (counting character from the beginning of the text).
The character at the end_offset is NOT included in the text segment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::TextSegment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
