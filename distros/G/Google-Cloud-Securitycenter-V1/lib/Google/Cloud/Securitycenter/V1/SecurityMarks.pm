package Google::Cloud::Securitycenter::V1::SecurityMarks;

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
CjNnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2VjdXJpdHlfbWFya3MucHJvdG8S
Hmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90byL9BAoNU2VjdXJpdHlNYXJrcxISCgRuYW1lGAEgASgJUgRuYW1lEk4KBW1hcmtzGAIg
AygLMjguZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLlNlY3VyaXR5TWFya3MuTWFy
a3NFbnRyeVIFbWFya3MSJQoOY2Fub25pY2FsX25hbWUYAyABKAlSDWNhbm9uaWNhbE5hbWUa
OAoKTWFya3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBOqYD6kGiAworc2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlNYXJr
cxI5b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9hc3NldHMve2Fzc2V0fS9zZWN1cml0
eU1hcmtzEk5vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0v
ZmluZGluZ3Mve2ZpbmRpbmd9L3NlY3VyaXR5TWFya3MSLWZvbGRlcnMve2ZvbGRlcn0vYXNz
ZXRzL3thc3NldH0vc2VjdXJpdHlNYXJrcxIvcHJvamVjdHMve3Byb2plY3R9L2Fzc2V0cy97
YXNzZXR9L3NlY3VyaXR5TWFya3MSQmZvbGRlcnMve2ZvbGRlcn0vc291cmNlcy97c291cmNl
fS9maW5kaW5ncy97ZmluZGluZ30vc2VjdXJpdHlNYXJrcxJEcHJvamVjdHMve3Byb2plY3R9
L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRpbmd9L3NlY3VyaXR5TWFya3NC2AEK
ImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFQAVpKY2xvdWQuZ29vZ2xlLmNv
bS9nby9zZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2Vu
dGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRc
U2VjdXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK
9BIKBhIEDgBEAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JwoJCgIDABIDEgAjCggKAQgSAxQAOwoJCgIIJRIDFAA7CggKAQgSAxUAYQoJCgIICxIDFQBh
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOwoJCgIIARIDFwA7CggKAQgSAxgAOwoJ
CgIIKRIDGAA7CggKAQgSAxkAOgoJCgIILRIDGQA6CpoCCgIEABIEHwBEARqNAiBVc2VyIHNw
ZWNpZmllZCBzZWN1cml0eSBtYXJrcyB0aGF0IGFyZSBhdHRhY2hlZCB0byB0aGUgcGFyZW50
IFNlY3VyaXR5CiBDb21tYW5kIENlbnRlciByZXNvdXJjZS4gU2VjdXJpdHkgbWFya3MgYXJl
IHNjb3BlZCB3aXRoaW4gYSBTZWN1cml0eSBDb21tYW5kCiBDZW50ZXIgb3JnYW5pemF0aW9u
IC0tIHRoZXkgY2FuIGJlIG1vZGlmaWVkIGFuZCB2aWV3ZWQgYnkgYWxsIHVzZXJzIHdobyBo
YXZlCiBwcm9wZXIgcGVybWlzc2lvbnMgb24gdGhlIG9yZ2FuaXphdGlvbi4KCgoKAwQAARID
HwgVCgsKAwQABxIEIAIoBAoNCgUEAAedCBIEIAIoBAq7AgoEBAACABIDLwISGq0CIFRoZSBy
ZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTZWN1cml0eU1hcmtzLiBTZWU6CiBodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjcmVsYXRp
dmVfcmVzb3VyY2VfbmFtZQogRXhhbXBsZXM6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0
aW9uX2lkfS9hc3NldHMve2Fzc2V0X2lkfS9zZWN1cml0eU1hcmtzIgogIm9yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbl9pZH0vc291cmNlcy97c291cmNlX2lkfS9maW5kaW5ncy97Zmlu
ZGluZ19pZH0vc2VjdXJpdHlNYXJrcyIuCgoMCgUEAAIABRIDLwIICgwKBQQAAgABEgMvCQ0K
DAoFBAACAAMSAy8QEQqiAwoEBAACARIDOQIgGpQDIE11dGFibGUgdXNlciBzcGVjaWZpZWQg
c2VjdXJpdHkgbWFya3MgYmVsb25naW5nIHRvIHRoZSBwYXJlbnQgcmVzb3VyY2UuCiBDb25z
dHJhaW50cyBhcmUgYXMgZm9sbG93czoKCiAgICogS2V5cyBhbmQgdmFsdWVzIGFyZSB0cmVh
dGVkIGFzIGNhc2UgaW5zZW5zaXRpdmUKICAgKiBLZXlzIG11c3QgYmUgYmV0d2VlbiAxIC0g
MjU2IGNoYXJhY3RlcnMgKGluY2x1c2l2ZSkKICAgKiBLZXlzIG11c3QgYmUgbGV0dGVycywg
bnVtYmVycywgdW5kZXJzY29yZXMsIG9yIGRhc2hlcwogICAqIFZhbHVlcyBoYXZlIGxlYWRp
bmcgYW5kIHRyYWlsaW5nIHdoaXRlc3BhY2UgdHJpbW1lZCwgcmVtYWluaW5nCiAgICAgY2hh
cmFjdGVycyBtdXN0IGJlIGJldHdlZW4gMSAtIDQwOTYgY2hhcmFjdGVycyAoaW5jbHVzaXZl
KQoKDAoFBAACAQYSAzkCFQoMCgUEAAIBARIDORYbCgwKBQQAAgEDEgM5Hh8K8QMKBAQAAgIS
A0MCHBrjAyBUaGUgY2Fub25pY2FsIG5hbWUgb2YgdGhlIG1hcmtzLgogRXhhbXBsZXM6CiAi
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9hc3NldHMve2Fzc2V0X2lkfS9zZWN1
cml0eU1hcmtzIgogImZvbGRlcnMve2ZvbGRlcl9pZH0vYXNzZXRzL3thc3NldF9pZH0vc2Vj
dXJpdHlNYXJrcyIKICJwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2Fzc2V0cy97YXNzZXRf
aWR9L3NlY3VyaXR5TWFya3MiCiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9z
b3VyY2VzL3tzb3VyY2VfaWR9L2ZpbmRpbmdzL3tmaW5kaW5nX2lkfS9zZWN1cml0eU1hcmtz
IgogImZvbGRlcnMve2ZvbGRlcl9pZH0vc291cmNlcy97c291cmNlX2lkfS9maW5kaW5ncy97
ZmluZGluZ19pZH0vc2VjdXJpdHlNYXJrcyIKICJwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L3NvdXJjZXMve3NvdXJjZV9pZH0vZmluZGluZ3Mve2ZpbmRpbmdfaWR9L3NlY3VyaXR5TWFy
a3MiCgoMCgUEAAICBRIDQwIICgwKBQQAAgIBEgNDCRcKDAoFBAACAgMSA0MaG2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks ===
    # Fields for SecurityMarks
    # Field: name Type: 9 ()
    # Field: marks Type: 11 (.google.cloud.securitycenter.v1.SecurityMarks.MarksEntry)
    # Field: canonical_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::SecurityMarks - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/security_marks.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::SecurityMarks;

    my $msg = Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks->new({
        name => $name,
        marks => $marks,
        canonical_name => $canonical_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/security_marks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks::MarksEntry>)

Mutable user specified security marks belonging to the parent resource.
Constraints are as follows:

  * Keys and values are treated as case insensitive
  * Keys must be between 1 - 256 characters (inclusive)
  * Keys must be letters, numbers, underscores, or dashes
  * Values have leading and trailing whitespace trimmed, remaining
    characters must be between 1 - 4096 characters (inclusive)

=item * C<< $msg->canonical_name() >> / C<< $msg->canonical_name($value) >>

Type: C<String>

The canonical name of the marks.
Examples:
"organizations/{organization_id}/assets/{asset_id}/securityMarks"
"folders/{folder_id}/assets/{asset_id}/securityMarks"
"projects/{project_number}/assets/{asset_id}/securityMarks"
"organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
"folders/{folder_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
"projects/{project_number}/sources/{source_id}/findings/{finding_id}/securityMarks"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::SecurityMarks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
