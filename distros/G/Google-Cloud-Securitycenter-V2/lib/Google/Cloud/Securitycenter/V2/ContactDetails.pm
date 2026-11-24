package Google::Cloud::Securitycenter::V2::ContactDetails;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvY29udGFjdF9kZXRhaWxzLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIiVQoOQ29udGFjdERldGFpbHMSQwoI
Y29udGFjdHMYASADKAsyJy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQ29udGFj
dFIIY29udGFjdHMiHwoHQ29udGFjdBIUCgVlbWFpbBgBIAEoCVIFZW1haWxC7QEKImNvbS5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCE0NvbnRhY3REZXRhaWxzUHJvdG9QAVpK
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRl
cnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLK
Ah5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1
cml0eUNlbnRlcjo6VjJKqQgKBhIEDgAkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAJwoICgEIEgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsS
AxMAYQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADQKCQoCCAgSAxUANAoICgEIEgMW
ADsKCQoCCAESAxYAOwoICgEIEgMXADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgA
OgotCgIEABIEGwAeARohIERldGFpbHMgYWJvdXQgc3BlY2lmaWMgY29udGFjdHMKCgoKAwQA
ARIDGwgWCiEKBAQAAgASAx0CIBoUIEEgbGlzdCBvZiBjb250YWN0cwoKDAoFBAACAAQSAx0C
CgoMCgUEAAIABhIDHQsSCgwKBQQAAgABEgMdExsKDAoFBAACAAMSAx0eHwotCgIEARIEIQAk
ARohIFRoZSBlbWFpbCBhZGRyZXNzIG9mIGEgY29udGFjdC4KCgoKAwQBARIDIQgPCkgKBAQB
AgASAyMCExo7IEFuIGVtYWlsIGFkZHJlc3MuIEZvciBleGFtcGxlLCAiYHBlcnNvbjEyM0Bj
b21wYW55LmNvbWAiLgoKDAoFBAECAAUSAyMCCAoMCgUEAQIAARIDIwkOCgwKBQQBAgADEgMj
ERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::ContactDetails::ContactDetails ===
    # Fields for ContactDetails
    # Field: contacts Type: 11 (.google.cloud.securitycenter.v2.Contact)

# === Message: Google::Cloud::Securitycenter::V2::ContactDetails::Contact ===
    # Fields for Contact
    # Field: email Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::ContactDetails - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/contact_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::ContactDetails;

    my $msg = Google::Cloud::Securitycenter::V2::ContactDetails::ContactDetails->new({
        contacts => $contacts,
    });

    # Read or update a field
    my $val = $msg->contacts();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::ContactDetails::ContactDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/contact_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::ContactDetails::ContactDetails

Details about specific contacts

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contacts() >> / C<< $msg->contacts($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ContactDetails::Contact>)

A list of contacts

=back

=head2 Google::Cloud::Securitycenter::V2::ContactDetails::Contact

The email address of a contact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

An email address. For example, "`person123@company.com`".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::ContactDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
