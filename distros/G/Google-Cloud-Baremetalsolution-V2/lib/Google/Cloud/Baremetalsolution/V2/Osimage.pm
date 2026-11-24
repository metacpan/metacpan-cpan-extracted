package Google::Cloud::Baremetalsolution::V2::Osimage;

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
Ci9nb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvb3NpbWFnZS5wcm90bxIhZ29v
Z2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvItMCCgdPU0ltYWdlEhcKBG5h
bWUYASABKAlCA+BBA1IEbmFtZRISCgRjb2RlGAIgASgJUgRjb2RlEiAKC2Rlc2NyaXB0aW9u
GAMgASgJUgtkZXNjcmlwdGlvbhI6ChlhcHBsaWNhYmxlX2luc3RhbmNlX3R5cGVzGAQgAygJ
UhdhcHBsaWNhYmxlSW5zdGFuY2VUeXBlcxI+ChtzdXBwb3J0ZWRfbmV0d29ya190ZW1wbGF0
ZXMYBSADKAlSGXN1cHBvcnRlZE5ldHdvcmtUZW1wbGF0ZXM6fepBegooYmFyZW1ldGFsc29s
dXRpb24uZ29vZ2xlYXBpcy5jb20vT3NJbWFnZRI7cHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L29zSW1hZ2VzL3tvc19pbWFnZX0qCG9zSW1hZ2VzMgdvc0ltYWdl
IpQBChNMaXN0T1NJbWFnZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2Nh
dGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiAB
KAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKHAQoUTGlzdE9T
SW1hZ2VzUmVzcG9uc2USRwoJb3NfaW1hZ2VzGAEgAygLMiouZ29vZ2xlLmNsb3VkLmJhcmVt
ZXRhbHNvbHV0aW9uLnYyLk9TSW1hZ2VSCG9zSW1hZ2VzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbkL7AQolY29tLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1
dGlvbi52MkIMT3NJbWFnZVByb3RvUAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vYmFyZW1ldGFs
c29sdXRpb24vYXBpdjIvYmFyZW1ldGFsc29sdXRpb25wYjtiYXJlbWV0YWxzb2x1dGlvbnBi
qgIhR29vZ2xlLkNsb3VkLkJhcmVNZXRhbFNvbHV0aW9uLlYyygIhR29vZ2xlXENsb3VkXEJh
cmVNZXRhbFNvbHV0aW9uXFYy6gIkR29vZ2xlOjpDbG91ZDo6QmFyZU1ldGFsU29sdXRpb246
OlYySqcTCgYSBA4AVAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
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
EgMQACoKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAPgoJCgIIJRIDFQA+CggKAQgS
AxYAagoJCgIICxIDFgBqCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALQoJCgIICBID
GAAtCggKAQgSAxkAPgoJCgIIARIDGQA+CggKAQgSAxoAPgoJCgIIKRIDGgA+CggKAQgSAxsA
PQoJCgIILRIDGwA9CiUKAgQAEgQeADYBGhkgT3BlcmF0aW9uIFN5c3RlbSBpbWFnZS4KCgoK
AwQAARIDHggPCgsKAwQABxIEHwIkBAoNCgUEAAedCBIEHwIkBAozCgQEAAIAEgMnAj4aJiBP
dXRwdXQgb25seS4gT1MgSW1hZ2UncyB1bmlxdWUgbmFtZS4KCgwKBQQAAgAFEgMnAggKDAoF
BAACAAESAycJDQoMCgUEAAIAAxIDJxARCgwKBQQAAgAIEgMnEj0KDwoIBAACAAicCAASAycT
PAodCgQEAAIBEgMqAhIaECBPUyBJbWFnZSBjb2RlLgoKDAoFBAACAQUSAyoCCAoMCgUEAAIB
ARIDKgkNCgwKBQQAAgEDEgMqEBEKJAoEBAACAhIDLQIZGhcgT1MgSW1hZ2UgZGVzY3JpcHRp
b24uCgoMCgUEAAICBRIDLQIICgwKBQQAAgIBEgMtCRQKDAoFBAACAgMSAy0XGAqcAQoEBAAC
AxIDMgIwGo4BIEluc3RhbmNlIHR5cGVzIHRoaXMgaW1hZ2UgaXMgYXBwbGljYWJsZSB0by4K
IFtBdmFpbGFibGUKIHR5cGVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmFyZS1tZXRh
bC9kb2NzL2Jtcy1wbGFubmluZyNzZXJ2ZXJfY29uZmlndXJhdGlvbnMpCgoMCgUEAAIDBBID
MgIKCgwKBQQAAgMFEgMyCxEKDAoFBAACAwESAzISKwoMCgUEAAIDAxIDMi4vCkUKBAQAAgQS
AzUCMho4IE5ldHdvcmsgdGVtcGxhdGVzIHRoYXQgY2FuIGJlIHVzZWQgd2l0aCB0aGlzIE9T
IEltYWdlLgoKDAoFBAACBAQSAzUCCgoMCgUEAAIEBRIDNQsRCgwKBQQAAgQBEgM1Ei0KDAoF
BAACBAMSAzUwMQo6CgIEARIEOQBKARouIFJlcXVlc3QgZm9yIGdldHRpbmcgYWxsIGF2YWls
YWJsZSBPUyBpbWFnZXMuCgoKCgMEAQESAzkIGwpJCgQEAQIAEgQ7AkAEGjsgUmVxdWlyZWQu
IFBhcmVudCB2YWx1ZSBmb3IgTGlzdFByb3Zpc2lvbmluZ1F1b3Rhc1JlcXVlc3QuCgoMCgUE
AQIABRIDOwIICgwKBQQBAgABEgM7CQ8KDAoFBAECAAMSAzsSEwoNCgUEAQIACBIEOxRAAwoP
CggEAQIACJwIABIDPAQqCg8KBwQBAgAInwgSBD0EPwUKogIKBAQBAgESA0YCFhqUAiBSZXF1
ZXN0ZWQgcGFnZSBzaXplLiBUaGUgc2VydmVyIG1pZ2h0IHJldHVybiBmZXdlciBpdGVtcyB0
aGFuIHJlcXVlc3RlZC4KIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGFuIGFw
cHJvcHJpYXRlIGRlZmF1bHQuCiBOb3RpY2UgdGhhdCBwYWdlX3NpemUgZmllbGQgaXMgbm90
IHN1cHBvcnRlZCBhbmQgd29uJ3QgYmUgcmVzcGVjdGVkIGluCiB0aGUgQVBJIHJlcXVlc3Qg
Zm9yIG5vdywgd2lsbCBiZSB1cGRhdGVkIHdoZW4gcGFnaW5hdGlvbiBpcyBzdXBwb3J0ZWQu
CgoMCgUEAQIBBRIDRgIHCgwKBQQBAgEBEgNGCBEKDAoFBAECAQMSA0YUFQpFCgQEAQICEgNJ
AhgaOCBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIGZyb20gdGhlIHNl
cnZlci4KCgwKBQQBAgIFEgNJAggKDAoFBAECAgESA0kJEwoMCgUEAQICAxIDSRYXCjoKAgQC
EgRNAFQBGi4gUmVxdWVzdCBmb3IgZ2V0dGluZyBhbGwgYXZhaWxhYmxlIE9TIGltYWdlcy4K
CgoKAwQCARIDTQgcCicKBAQCAgASA08CIRoaIFRoZSBPUyBpbWFnZXMgYXZhaWxhYmxlLgoK
DAoFBAICAAQSA08CCgoMCgUEAgIABhIDTwsSCgwKBQQCAgABEgNPExwKDAoFBAICAAMSA08f
IApuCgQEAgIBEgNTAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlCiByZXN1bHRzIGluIHRoZSBs
aXN0LgoKDAoFBAICAQUSA1MCCAoMCgUEAgIBARIDUwkYCgwKBQQCAgEDEgNTGxxiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::Osimage::OSImage ===
    # Fields for OSImage
    # Field: name Type: 9 ()
    # Field: code Type: 9 ()
    # Field: description Type: 9 ()
    # Field: applicable_instance_types Type: 9 ()
    # Field: supported_network_templates Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesRequest ===
    # Fields for ListOSImagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesResponse ===
    # Fields for ListOSImagesResponse
    # Field: os_images Type: 11 (.google.cloud.baremetalsolution.v2.OSImage)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Osimage - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/osimage.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::Osimage;

    my $msg = Google::Cloud::Baremetalsolution::V2::Osimage::OSImage->new({
        name => $name,
        code => $code,
        description => $description,
        applicable_instance_types => $applicable_instance_types,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::Osimage::OSImage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/osimage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::Osimage::OSImage

Operation System image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. OS Image's unique name.

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

OS Image code.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

OS Image description.

=item * C<< $msg->applicable_instance_types() >> / C<< $msg->applicable_instance_types($value) >>

Type: C<String>

Instance types this image is applicable to.
[Available
types](https://cloud.google.com/bare-metal/docs/bms-planning#server_configurations)

=item * C<< $msg->supported_network_templates() >> / C<< $msg->supported_network_templates($value) >>

Type: C<String>

Network templates that can be used with this OS Image.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesRequest

Request for getting all available OS images.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListProvisioningQuotasRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.
Notice that page_size field is not supported and won't be respected in
the API request for now, will be updated when pagination is supported.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesResponse

Request for getting all available OS images.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_images() >> / C<< $msg->os_images($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Osimage::OSImage>)

The OS images available.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::Osimage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
