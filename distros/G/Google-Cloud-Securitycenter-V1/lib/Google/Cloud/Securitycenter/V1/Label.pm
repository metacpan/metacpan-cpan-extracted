package Google::Cloud::Securitycenter::V1::Label;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvbGFiZWwucHJvdG8SHmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MSIxCgVMYWJlbBISCgRuYW1lGAEgASgJUgRuYW1lEhQK
BXZhbHVlGAIgASgJUgV2YWx1ZULkAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRl
ci52MUIKTGFiZWxQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVy
L2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91
ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoC
IUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUrjCQoGEgQOACQBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRID
EgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUA
KwoJCgIICBIDFQArCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7
CggKAQgSAxgAOgoJCgIILRIDGAA6Cr0CCgIEABIEHgAkARqwAiBSZXByZXNlbnRzIGEgZ2Vu
ZXJpYyBuYW1lLXZhbHVlIGxhYmVsLiBBIGxhYmVsIGhhcyBzZXBhcmF0ZSBuYW1lIGFuZCB2
YWx1ZQogZmllbGRzIHRvIHN1cHBvcnQgZmlsdGVyaW5nIHdpdGggdGhlIGBjb250YWlucygp
YCBmdW5jdGlvbi4gRm9yIG1vcmUKIGluZm9ybWF0aW9uLCBzZWUgW0ZpbHRlcmluZyBvbiBh
cnJheS10eXBlCiBmaWVsZHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zZWN1cml0eS1j
b21tYW5kLWNlbnRlci9kb2NzL2hvdy10by1hcGktbGlzdC1maW5kaW5ncyNhcnJheS1jb250
YWlucy1maWx0ZXJpbmcpLgoKCgoDBAABEgMeCA0KIQoEBAACABIDIAISGhQgTmFtZSBvZiB0
aGUgbGFiZWwuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCQ0KDAoFBAACAAMSAyAQEQo6
CgQEAAIBEgMjAhMaLSBWYWx1ZSB0aGF0IGNvcnJlc3BvbmRzIHRvIHRoZSBsYWJlbCdzIG5h
bWUuCgoMCgUEAAIBBRIDIwIICgwKBQQAAgEBEgMjCQ4KDAoFBAACAQMSAyMREmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Label::Label ===
    # Fields for Label
    # Field: name Type: 9 ()
    # Field: value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Label - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/label.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Label;

    my $msg = Google::Cloud::Securitycenter::V1::Label::Label->new({
        name => $name,
        value => $value,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Label::Label->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/label.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Label::Label

Represents a generic name-value label. A label has separate name and value
fields to support filtering with the `contains()` function. For more
information, see [Filtering on array-type
fields](https://cloud.google.com/security-command-center/docs/how-to-api-list-findings#array-contains-filtering).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the label.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Value that corresponds to the label's name.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Label::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
