package Google::Cloud::Securitycenter::V1beta1::SecurityMarks;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9zZWN1cml0eV9tYXJrcy5w
cm90bxIjZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxYmV0YTEaGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8i8QIKDVNlY3VyaXR5TWFya3MSEgoEbmFtZRgBIAEoCVIEbmFtZRJT
CgVtYXJrcxgCIAMoCzI9Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExLlNl
Y3VyaXR5TWFya3MuTWFya3NFbnRyeVIFbWFya3MaOAoKTWFya3NFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOrwB6kG4AQorc2VjdXJpdHljZW50
ZXIuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlNYXJrcxI5b3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9ufS9hc3NldHMve2Fzc2V0fS9zZWN1cml0eU1hcmtzEk5vcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRpbmd9L3NlY3Vy
aXR5TWFya3NCfAonY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExUAFa
T2Nsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjFiZXRhMS9zZWN1cml0
eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGJKlw4KBhIEDgAzAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgAjCggKAQgSAxQAZgoJCgII
CxIDFABmCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAQAoJCgIIARIDFgBACpoCCgIE
ABIEHAAzARqNAiBVc2VyIHNwZWNpZmllZCBzZWN1cml0eSBtYXJrcyB0aGF0IGFyZSBhdHRh
Y2hlZCB0byB0aGUgcGFyZW50IFNlY3VyaXR5CiBDb21tYW5kIENlbnRlciByZXNvdXJjZS4g
U2VjdXJpdHkgbWFya3MgYXJlIHNjb3BlZCB3aXRoaW4gYSBTZWN1cml0eSBDb21tYW5kCiBD
ZW50ZXIgb3JnYW5pemF0aW9uIC0tIHRoZXkgY2FuIGJlIG1vZGlmaWVkIGFuZCB2aWV3ZWQg
YnkgYWxsIHVzZXJzIHdobyBoYXZlCiBwcm9wZXIgcGVybWlzc2lvbnMgb24gdGhlIG9yZ2Fu
aXphdGlvbi4KCgoKAwQAARIDHAgVCgsKAwQABxIEHQIhBAoNCgUEAAedCBIEHQIhBAq7AgoE
BAACABIDKAISGq0CIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTZWN1cml0
eU1hcmtzLiBTZWU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVz
b3VyY2VfbmFtZXMjcmVsYXRpdmVfcmVzb3VyY2VfbmFtZQogRXhhbXBsZXM6CiAib3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9hc3NldHMve2Fzc2V0X2lkfS9zZWN1cml0eU1h
cmtzIgogIm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vc291cmNlcy97c291cmNl
X2lkfS9maW5kaW5ncy97ZmluZGluZ19pZH0vc2VjdXJpdHlNYXJrcyIuCgoMCgUEAAIABRID
KAIICgwKBQQAAgABEgMoCQ0KDAoFBAACAAMSAygQEQqiAwoEBAACARIDMgIgGpQDIE11dGFi
bGUgdXNlciBzcGVjaWZpZWQgc2VjdXJpdHkgbWFya3MgYmVsb25naW5nIHRvIHRoZSBwYXJl
bnQgcmVzb3VyY2UuCiBDb25zdHJhaW50cyBhcmUgYXMgZm9sbG93czoKCiAgICogS2V5cyBh
bmQgdmFsdWVzIGFyZSB0cmVhdGVkIGFzIGNhc2UgaW5zZW5zaXRpdmUKICAgKiBLZXlzIG11
c3QgYmUgYmV0d2VlbiAxIC0gMjU2IGNoYXJhY3RlcnMgKGluY2x1c2l2ZSkKICAgKiBLZXlz
IG11c3QgYmUgbGV0dGVycywgbnVtYmVycywgdW5kZXJzY29yZXMsIG9yIGRhc2hlcwogICAq
IFZhbHVlcyBoYXZlIGxlYWRpbmcgYW5kIHRyYWlsaW5nIHdoaXRlc3BhY2UgdHJpbW1lZCwg
cmVtYWluaW5nCiAgICAgY2hhcmFjdGVycyBtdXN0IGJlIGJldHdlZW4gMSAtIDQwOTYgY2hh
cmFjdGVycyAoaW5jbHVzaXZlKQoKDAoFBAACAQYSAzICFQoMCgUEAAIBARIDMhYbCgwKBQQA
AgEDEgMyHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks ===
    # Fields for SecurityMarks
    # Field: name Type: 9 ()
    # Field: marks Type: 11 (.google.cloud.securitycenter.v1beta1.SecurityMarks.MarksEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::SecurityMarks - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/security_marks.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::SecurityMarks;

    my $msg = Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks->new({
        name => $name,
        marks => $marks,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/security_marks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks

User specified security marks that are attached to the parent Security
Command Center resource. Security marks are scoped within a Security Command
Center organization -- they can be modified and viewed by all users who have
proper permissions on the organization.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of the SecurityMarks. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Examples:
"organizations/{organization_id}/assets/{asset_id}/securityMarks"
"organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".

=item * C<< $msg->marks() >> / C<< $msg->marks($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks::MarksEntry>)

Mutable user specified security marks belonging to the parent resource.
Constraints are as follows:

  * Keys and values are treated as case insensitive
  * Keys must be between 1 - 256 characters (inclusive)
  * Keys must be letters, numbers, underscores, or dashes
  * Values have leading and trailing whitespace trimmed, remaining
    characters must be between 1 - 4096 characters (inclusive)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::SecurityMarks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
