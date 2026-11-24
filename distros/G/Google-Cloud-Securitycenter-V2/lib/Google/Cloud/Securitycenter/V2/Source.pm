package Google::Cloud::Securitycenter::V2::Source;

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
Citnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvc291cmNlLnByb3RvEh5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8irAIK
BlNvdXJjZRISCgRuYW1lGAEgASgJUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlz
cGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEiUKDmNhbm9uaWNh
bF9uYW1lGAQgASgJUg1jYW5vbmljYWxOYW1lOqEB6kGdAQokc2VjdXJpdHljZW50ZXIuZ29v
Z2xlYXBpcy5jb20vU291cmNlEi1vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJj
ZXMve3NvdXJjZX0SIWZvbGRlcnMve2ZvbGRlcn0vc291cmNlcy97c291cmNlfRIjcHJvamVj
dHMve3Byb2plY3R9L3NvdXJjZXMve3NvdXJjZX1C5QEKImNvbS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjJCC1NvdXJjZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIe
R29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5
Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySr4SCgYSBA4A
RQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwAS
AxIAIwoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcALAoICgEIEgMYADsKCQoCCAESAxgA
OwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgruAQoCBAASBCAA
RQEa4QEgU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIgZmluZGluZyBzb3VyY2UuIEEgZmluZGlu
ZyBzb3VyY2UKIGlzIGFuIGVudGl0eSBvciBhIG1lY2hhbmlzbSB0aGF0IGNhbiBwcm9kdWNl
IGEgZmluZGluZy4gQSBzb3VyY2UgaXMgbGlrZSBhCiBjb250YWluZXIgb2YgZmluZGluZ3Mg
dGhhdCBjb21lIGZyb20gdGhlIHNhbWUgc2Nhbm5lciwgbG9nZ2VyLCBtb25pdG9yLCBhbmQK
IG90aGVyIHRvb2xzLgoKCgoDBAABEgMgCA4KCwoDBAAHEgQhAiYECg0KBQQAB50IEgQhAiYE
CswBCgQEAAIAEgMsAhIavgEgVGhlIHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhpcyBz
b3VyY2UuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9yZXNv
dXJjZV9uYW1lcyNyZWxhdGl2ZV9yZXNvdXJjZV9uYW1lCiBFeGFtcGxlOgogIm9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbl9pZH0vc291cmNlcy97c291cmNlX2lkfSIKCgwKBQQAAgAF
EgMsAggKDAoFBAACAAESAywJDQoMCgUEAAIAAxIDLBARCokCCgQEAAIBEgMzAhoa+wEgVGhl
IHNvdXJjZSdzIGRpc3BsYXkgbmFtZS4KIEEgc291cmNlJ3MgZGlzcGxheSBuYW1lIG11c3Qg
YmUgdW5pcXVlIGFtb25nc3QgaXRzIHNpYmxpbmdzLCBmb3IgZXhhbXBsZSwKIHR3byBzb3Vy
Y2VzIHdpdGggdGhlIHNhbWUgcGFyZW50IGNhbid0IHNoYXJlIHRoZSBzYW1lIGRpc3BsYXkg
bmFtZS4KIFRoZSBkaXNwbGF5IG5hbWUgbXVzdCBoYXZlIGEgbGVuZ3RoIGJldHdlZW4gMSBh
bmQgNjQgY2hhcmFjdGVycwogKGluY2x1c2l2ZSkuCgoMCgUEAAIBBRIDMwIICgwKBQQAAgEB
EgMzCRUKDAoFBAACAQMSAzMYGQr6AgoEBAACAhIDPAIZGuwCIFRoZSBkZXNjcmlwdGlvbiBv
ZiB0aGUgc291cmNlIChtYXggb2YgMTAyNCBjaGFyYWN0ZXJzKS4KIEV4YW1wbGU6CiAiV2Vi
IFNlY3VyaXR5IFNjYW5uZXIgaXMgYSB3ZWIgc2VjdXJpdHkgc2Nhbm5lciBmb3IgY29tbW9u
CiB2dWxuZXJhYmlsaXRpZXMgaW4gQXBwIEVuZ2luZSBhcHBsaWNhdGlvbnMuIEl0IGNhbiBh
dXRvbWF0aWNhbGx5CiBzY2FuIGFuZCBkZXRlY3QgZm91ciBjb21tb24gdnVsbmVyYWJpbGl0
aWVzLCBpbmNsdWRpbmcgY3Jvc3Mtc2l0ZS1zY3JpcHRpbmcKIChYU1MpLCBGbGFzaCBpbmpl
Y3Rpb24sIG1peGVkIGNvbnRlbnQgKEhUVFAgaW4gSFRUUFMpLCBhbmQKIG91dGRhdGVkIG9y
IGluc2VjdXJlIGxpYnJhcmllcy4iCgoMCgUEAAICBRIDPAIICgwKBQQAAgIBEgM8CRQKDAoF
BAACAgMSAzwXGAqzAgoEBAACAxIDRAIcGqUCIFRoZSBjYW5vbmljYWwgbmFtZSBvZiB0aGUg
ZmluZGluZyBzb3VyY2UuIEl0J3MgZWl0aGVyCiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0
aW9uX2lkfS9zb3VyY2VzL3tzb3VyY2VfaWR9IiwKICJmb2xkZXJzL3tmb2xkZXJfaWR9L3Nv
dXJjZXMve3NvdXJjZV9pZH0iLCBvcgogInByb2plY3RzL3twcm9qZWN0X251bWJlcn0vc291
cmNlcy97c291cmNlX2lkfSIsCiBkZXBlbmRpbmcgb24gdGhlIGNsb3Nlc3QgQ1JNIGFuY2Vz
dG9yIG9mIHRoZSByZXNvdXJjZSBhc3NvY2lhdGVkIHdpdGggdGhlCiBmaW5kaW5nLgoKDAoF
BAACAwUSA0QCCAoMCgUEAAIDARIDRAkXCgwKBQQAAgMDEgNEGhtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Source::Source ===
    # Fields for Source
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: canonical_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Source - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/source.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Source;

    my $msg = Google::Cloud::Securitycenter::V2::Source::Source->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        canonical_name => $canonical_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Source::Source->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/source.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Source::Source

Security Command Center finding source. A finding source
is an entity or a mechanism that can produce a finding. A source is like a
container of findings that come from the same scanner, logger, monitor, and
other tools.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this source. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/sources/{source_id}"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The source's display name.
A source's display name must be unique amongst its siblings, for example,
two sources with the same parent can't share the same display name.
The display name must have a length between 1 and 64 characters
(inclusive).

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the source (max of 1024 characters).
Example:
"Web Security Scanner is a web security scanner for common
vulnerabilities in App Engine applications. It can automatically
scan and detect four common vulnerabilities, including cross-site-scripting
(XSS), Flash injection, mixed content (HTTP in HTTPS), and
outdated or insecure libraries."

=item * C<< $msg->canonical_name() >> / C<< $msg->canonical_name($value) >>

Type: C<String>

The canonical name of the finding source. It's either
"organizations/{organization_id}/sources/{source_id}",
"folders/{folder_id}/sources/{source_id}", or
"projects/{project_number}/sources/{source_id}",
depending on the closest CRM ancestor of the resource associated with the
finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Source::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
