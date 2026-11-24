package Google::Cloud::Securitycenter::V2::SecurityMarks;

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
CjNnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvc2VjdXJpdHlfbWFya3MucHJvdG8S
Hmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90byKWBwoNU2VjdXJpdHlNYXJrcxISCgRuYW1lGAEgASgJUgRuYW1lEk4KBW1hcmtzGAIg
AygLMjguZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlNlY3VyaXR5TWFya3MuTWFy
a3NFbnRyeVIFbWFya3MSJQoOY2Fub25pY2FsX25hbWUYAyABKAlSDWNhbm9uaWNhbE5hbWUa
OAoKTWFya3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBOr8F6kG7BQorc2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlNYXJr
cxI5b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9hc3NldHMve2Fzc2V0fS9zZWN1cml0
eU1hcmtzEk5vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0v
ZmluZGluZ3Mve2ZpbmRpbmd9L3NlY3VyaXR5TWFya3MSY29yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbn0vc291cmNlcy97c291cmNlfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9maW5kaW5n
cy97ZmluZGluZ30vc2VjdXJpdHlNYXJrcxItZm9sZGVycy97Zm9sZGVyfS9hc3NldHMve2Fz
c2V0fS9zZWN1cml0eU1hcmtzEkJmb2xkZXJzL3tmb2xkZXJ9L3NvdXJjZXMve3NvdXJjZX0v
ZmluZGluZ3Mve2ZpbmRpbmd9L3NlY3VyaXR5TWFya3MSV2ZvbGRlcnMve2ZvbGRlcn0vc291
cmNlcy97c291cmNlfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9maW5kaW5ncy97ZmluZGluZ30v
c2VjdXJpdHlNYXJrcxIvcHJvamVjdHMve3Byb2plY3R9L2Fzc2V0cy97YXNzZXR9L3NlY3Vy
aXR5TWFya3MSRHByb2plY3RzL3twcm9qZWN0fS9zb3VyY2VzL3tzb3VyY2V9L2ZpbmRpbmdz
L3tmaW5kaW5nfS9zZWN1cml0eU1hcmtzEllwcm9qZWN0cy97cHJvamVjdH0vc291cmNlcy97
c291cmNlfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9maW5kaW5ncy97ZmluZGluZ30vc2VjdXJp
dHlNYXJrc0LsAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkISU2VjdXJp
dHlNYXJrc1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBp
djIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNl
Y3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29v
Z2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySpMXCgYSBA4AVQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoICgEIEgMUADsK
CQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXADMKCQoCCAgSAxcAMwoICgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoC
CCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgqaAgoCBAASBCAAVQEajQIgVXNlciBzcGVj
aWZpZWQgc2VjdXJpdHkgbWFya3MgdGhhdCBhcmUgYXR0YWNoZWQgdG8gdGhlIHBhcmVudCBT
ZWN1cml0eQogQ29tbWFuZCBDZW50ZXIgcmVzb3VyY2UuIFNlY3VyaXR5IG1hcmtzIGFyZSBz
Y29wZWQgd2l0aGluIGEgU2VjdXJpdHkgQ29tbWFuZAogQ2VudGVyIG9yZ2FuaXphdGlvbiAt
LSB0aGV5IGNhbiBiZSBtb2RpZmllZCBhbmQgdmlld2VkIGJ5IGFsbCB1c2VycyB3aG8gaGF2
ZQogcHJvcGVyIHBlcm1pc3Npb25zIG9uIHRoZSBvcmdhbml6YXRpb24uCgoKCgMEAAESAyAI
FQoLCgMEAAcSBCECLAQKDQoFBAAHnQgSBCECLAQK0QMKBAQAAgASAzcCEhrDAyBUaGUgcmVs
YXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2VjdXJpdHlNYXJrcy4gU2VlOgogaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI3JlbGF0aXZl
X3Jlc291cmNlX25hbWUKIFRoZSBmb2xsb3dpbmcgbGlzdCBzaG93cyBzb21lIGV4YW1wbGVz
OgoKICsgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vYXNzZXRzL3thc3NldF9p
ZH0vc2VjdXJpdHlNYXJrc2AKICsKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9
L3NvdXJjZXMve3NvdXJjZV9pZH0vZmluZGluZ3Mve2ZpbmRpbmdfaWR9L3NlY3VyaXR5TWFy
a3NgCiArCiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9zb3VyY2VzL3tzb3Vy
Y2VfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2ZpbmRpbmdzL3tmaW5kaW5nX2lkfS9zZWN1
cml0eU1hcmtzYAoKDAoFBAACAAUSAzcCCAoMCgUEAAIAARIDNwkNCgwKBQQAAgADEgM3EBEK
ogMKBAQAAgESA0ECIBqUAyBNdXRhYmxlIHVzZXIgc3BlY2lmaWVkIHNlY3VyaXR5IG1hcmtz
IGJlbG9uZ2luZyB0byB0aGUgcGFyZW50IHJlc291cmNlLgogQ29uc3RyYWludHMgYXJlIGFz
IGZvbGxvd3M6CgogICAqIEtleXMgYW5kIHZhbHVlcyBhcmUgdHJlYXRlZCBhcyBjYXNlIGlu
c2Vuc2l0aXZlCiAgICogS2V5cyBtdXN0IGJlIGJldHdlZW4gMSAtIDI1NiBjaGFyYWN0ZXJz
IChpbmNsdXNpdmUpCiAgICogS2V5cyBtdXN0IGJlIGxldHRlcnMsIG51bWJlcnMsIHVuZGVy
c2NvcmVzLCBvciBkYXNoZXMKICAgKiBWYWx1ZXMgaGF2ZSBsZWFkaW5nIGFuZCB0cmFpbGlu
ZyB3aGl0ZXNwYWNlIHRyaW1tZWQsIHJlbWFpbmluZwogICAgIGNoYXJhY3RlcnMgbXVzdCBi
ZSBiZXR3ZWVuIDEgLSA0MDk2IGNoYXJhY3RlcnMgKGluY2x1c2l2ZSkKCgwKBQQAAgEGEgNB
AhUKDAoFBAACAQESA0EWGwoMCgUEAAIBAxIDQR4fCuUGCgQEAAICEgNUAhwa1wYgVGhlIGNh
bm9uaWNhbCBuYW1lIG9mIHRoZSBtYXJrcy4gVGhlIGZvbGxvd2luZyBsaXN0IHNob3dzIHNv
bWUgZXhhbXBsZXM6CgogKyBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9hc3Nl
dHMve2Fzc2V0X2lkfS9zZWN1cml0eU1hcmtzYAogKwogYG9yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbl9pZH0vc291cmNlcy97c291cmNlX2lkfS9maW5kaW5ncy97ZmluZGluZ19pZH0v
c2VjdXJpdHlNYXJrc2AKICsKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L3Nv
dXJjZXMve3NvdXJjZV9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZmluZGluZ3Mve2ZpbmRp
bmdfaWR9L3NlY3VyaXR5TWFya3NgCiArIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2Fzc2V0cy97
YXNzZXRfaWR9L3NlY3VyaXR5TWFya3NgCiArCiBgZm9sZGVycy97Zm9sZGVyX2lkfS9zb3Vy
Y2VzL3tzb3VyY2VfaWR9L2ZpbmRpbmdzL3tmaW5kaW5nX2lkfS9zZWN1cml0eU1hcmtzYAog
KwogYGZvbGRlcnMve2ZvbGRlcl9pZH0vc291cmNlcy97c291cmNlX2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9maW5kaW5ncy97ZmluZGluZ19pZH0vc2VjdXJpdHlNYXJrc2AKICsgYHBy
b2plY3RzL3twcm9qZWN0X251bWJlcn0vYXNzZXRzL3thc3NldF9pZH0vc2VjdXJpdHlNYXJr
c2AKICsKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L3NvdXJjZXMve3NvdXJjZV9pZH0v
ZmluZGluZ3Mve2ZpbmRpbmdfaWR9L3NlY3VyaXR5TWFya3NgCiArCiBgcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9zb3VyY2VzL3tzb3VyY2VfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259
L2ZpbmRpbmdzL3tmaW5kaW5nX2lkfS9zZWN1cml0eU1hcmtzYAoKDAoFBAACAgUSA1QCCAoM
CgUEAAICARIDVAkXCgwKBQQAAgIDEgNUGhtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks ===
    # Fields for SecurityMarks
    # Field: name Type: 9 ()
    # Field: marks Type: 11 (.google.cloud.securitycenter.v2.SecurityMarks.MarksEntry)
    # Field: canonical_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::SecurityMarks - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/security_marks.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::SecurityMarks;

    my $msg = Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks->new({
        name => $name,
        marks => $marks,
        canonical_name => $canonical_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/security_marks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks

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
The following list shows some examples:

+ `organizations/{organization_id}/assets/{asset_id}/securityMarks`
+
`organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks`
+
`organizations/{organization_id}/sources/{source_id}/locations/{location}/findings/{finding_id}/securityMarks`

=item * C<< $msg->marks() >> / C<< $msg->marks($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks::MarksEntry>)

Mutable user specified security marks belonging to the parent resource.
Constraints are as follows:

  * Keys and values are treated as case insensitive
  * Keys must be between 1 - 256 characters (inclusive)
  * Keys must be letters, numbers, underscores, or dashes
  * Values have leading and trailing whitespace trimmed, remaining
    characters must be between 1 - 4096 characters (inclusive)

=item * C<< $msg->canonical_name() >> / C<< $msg->canonical_name($value) >>

Type: C<String>

The canonical name of the marks. The following list shows some examples:

+ `organizations/{organization_id}/assets/{asset_id}/securityMarks`
+
`organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks`
+
`organizations/{organization_id}/sources/{source_id}/locations/{location}/findings/{finding_id}/securityMarks`
+ `folders/{folder_id}/assets/{asset_id}/securityMarks`
+
`folders/{folder_id}/sources/{source_id}/findings/{finding_id}/securityMarks`
+
`folders/{folder_id}/sources/{source_id}/locations/{location}/findings/{finding_id}/securityMarks`
+ `projects/{project_number}/assets/{asset_id}/securityMarks`
+
`projects/{project_number}/sources/{source_id}/findings/{finding_id}/securityMarks`
+
`projects/{project_number}/sources/{source_id}/locations/{location}/findings/{finding_id}/securityMarks`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::SecurityMarks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
